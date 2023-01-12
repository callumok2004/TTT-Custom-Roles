-- Defib v2 (revision 20170303)

-- This code is copyright (c) 2016-2017 all rights reserved - "Vadim" @ jmwparq@gmail.com
-- (Re)sale of this code and/or products containing part of this code is strictly prohibited
-- Exclusive rights to usage of this product in "Trouble in Terrorist Town" are given to:
-- - The Garry's Mod community

AddCSLuaFile()

local IsValid = IsValid
local math = math
local net = net
local string = string
local timer = timer
local util = util

if CLIENT then
    SWEP.PrintName          = "Deputy Badge"
    SWEP.Slot               = 8

    SWEP.ViewModelFOV       = 60
    SWEP.DrawCrosshair      = false
    SWEP.ViewModelFlip      = false
end

SWEP.ViewModel              = "models/weapons/v_slam.mdl"
SWEP.WorldModel             = "models/weapons/w_slam.mdl"
SWEP.Weight                 = 2

SWEP.Base                   = "weapon_tttbase"
SWEP.Category               = WEAPON_CATEGORY_ROLE

SWEP.Spawnable              = true
SWEP.AutoSpawnable          = false
SWEP.HoldType               = "slam"
SWEP.Kind                   = WEAPON_ROLE

SWEP.DeploySpeed            = 4
SWEP.AllowDrop              = false
SWEP.NoSights               = true
SWEP.UseHands               = true
SWEP.LimitedStock           = true
SWEP.AmmoEnt                = nil

SWEP.Primary.Delay          = 1
SWEP.Primary.Automatic      = false
SWEP.Primary.Cone           = 0
SWEP.Primary.Ammo           = nil
SWEP.Primary.ClipSize       = -1
SWEP.Primary.ClipMax        = -1
SWEP.Primary.DefaultClip    = -1
SWEP.Primary.Sound          = ""

SWEP.Secondary.Delay        = 1.25
SWEP.Secondary.Automatic    = false
SWEP.Secondary.Cone         = 0
SWEP.Secondary.Ammo         = nil
SWEP.Secondary.ClipSize     = -1
SWEP.Secondary.ClipMax      = -1
SWEP.Secondary.DefaultClip  = -1
SWEP.Secondary.Sound        = ""

SWEP.InLoadoutFor           = {ROLE_MARSHAL}
SWEP.InLoadoutForDefault    = {ROLE_MARSHAL}

-- settings
local maxdist = 96

local DEFIB_IDLE = 0
local DEFIB_BUSY = 1
local DEFIB_ERROR = 2

if SERVER then
    CreateConVar("ttt_marshal_badge_time", "8", FCVAR_NONE, "The amount of time (in seconds) the marshal's badge takes to use", 0, 60)
end

if CLIENT then
    function SWEP:GetPrintName()
        return ROLE_STRINGS[ROLE_DEPUTY] .. " Badge --TESTREMOVE"
    end
end

function SWEP:Initialize()
    self:SendWeaponAnim(ACT_SLAM_DETONATOR_DRAW)
    if CLIENT then
        self:AddHUDHelp("marshalbadge_help_pri", "marshalbadge_help_sec", true)
    end
    return self.BaseClass.Initialize(self)
end

function SWEP:SetupDataTables()
    self:NetworkVar("Int", 0, "State")
    self:NetworkVar("Int", 1, "ChargeTime")
    self:NetworkVar("Float", 0, "Begin")
    self:NetworkVar("String", 0, "Message")

    if SERVER then
        self:SetChargeTime(GetConVar("ttt_marshal_badge_time"):GetInt())
    end
end

function SWEP:OnDrop()
    self:Remove()
end

function SWEP:Deploy()
    self:SendWeaponAnim(ACT_SLAM_DETONATOR_DRAW)
    return true
end

if SERVER then
    util.AddNetworkString("TTT_Deputized")

    function SWEP:Reset()
        self:SetState(DEFIB_IDLE)
        self:SetBegin(-1)
        self:SetMessage('')
        self.Target = nil
    end

    function SWEP:Error(msg)
        self:SetState(DEFIB_ERROR)
        self:SetBegin(CurTime())
        self:SetMessage(msg)

        self.Target = nil

        timer.Simple(3 * 0.75, function()
            if IsValid(self) then self:Reset() end
        end)
    end

    function SWEP:Deputize()
        if not IsFirstTimePredicted() then return end

        local ply = self.Target
        if not IsPlayer(ply) or not ply:Alive() or ply:IsSpec() then
            self:Error("INVALID TARGET")
            return
        end

        local role = ROLE_DEPUTY
        if ply:IsTraitorTeam() then
            role = ROLE_IMPERSONATOR
        end

        local marshal_monster_deputy_chance = GetConVar("ttt_marshal_monster_deputy_chance"):GetFloat()
        if ply:IsMonsterTeam() and marshal_monster_deputy_chance <= math.random() then
            role = ROLE_IMPERSONATOR
        end

        local marshal_jester_deputy_chance = GetConVar("ttt_marshal_jester_deputy_chance"):GetFloat()
        if ply:IsJesterTeam() and marshal_jester_deputy_chance <= math.random() then
            role = ROLE_IMPERSONATOR
        end

        local marshal_independent_deputy_chance = GetConVar("ttt_marshal_independent_deputy_chance"):GetFloat()
        if ply:IsIndependentTeam() and marshal_independent_deputy_chance <= math.random() then
            role = ROLE_IMPERSONATOR
        end

        ply:SetRole(role)
        SendFullStateUpdate()

        ply:StripRoleWeapons()
        if not ply:HasWeapon("weapon_ttt_unarmed") then
            ply:Give("weapon_ttt_unarmed")
        end
        if not ply:HasWeapon("weapon_zm_carry") then
            ply:Give("weapon_zm_carry")
        end
        if not ply:HasWeapon("weapon_zm_improvised") then
            ply:Give("weapon_zm_improvised")
        end

        local owner = self:GetOwner()
        hook.Call("TTTPlayerRoleChangedByItem", nil, owner, ply, self)

        -- Broadcast the event
        net.Start("TTT_Deputized")
        net.WriteString(owner:Nick())
        net.WriteString(ply:Nick())
        net.WriteString(ply:EnhancedSteamID64())
        net.Broadcast()

        owner:ConCommand("lastinv")
        self:Remove()
        self:Reset()
    end

    function SWEP:Begin(ply)
        if not ply or not IsPlayer(ply) then
            self:Error("INVALID TARGET")
            return
        end

        local marshal_monster_deputy_chance = GetConVar("ttt_marshal_monster_deputy_chance"):GetFloat()
        if ply:IsMonsterTeam() and marshal_monster_deputy_chance < 0 then
            self:Error("INVALID TARGET")
            return
        end

        local marshal_jester_deputy_chance = GetConVar("ttt_marshal_jester_deputy_chance"):GetFloat()
        if ply:IsJesterTeam() and marshal_jester_deputy_chance < 0 then
            self:Error("INVALID TARGET")
            return
        end

        local marshal_independent_deputy_chance = GetConVar("ttt_marshal_independent_deputy_chance"):GetFloat()
        if ply:IsIndependentTeam() and marshal_independent_deputy_chance < 0 then
            self:Error("INVALID TARGET")
            return
        end

        self:SetState(DEFIB_BUSY)
        self:SetBegin(CurTime())
        self:SetMessage("DEPUTIZING " .. string.upper(ply:Nick()))
        ply:PrintMessage(HUD_PRINTCENTER, "The " .. ROLE_STRINGS[ROLE_MARSHAL] .. " is promoting you.")

        self.Target = ply
    end

    function SWEP:Think()
        if self:GetState() == DEFIB_BUSY then
            if self:GetBegin() + self:GetChargeTime() <= CurTime() then
                self:Deputize()
            elseif not self:GetOwner():KeyDown(IN_ATTACK) or self:GetOwner():GetEyeTrace(MASK_SHOT_HULL).Entity ~= self.Target then
                self:Error("DEPUTIZING ABORTED")
            end
        end
    end

    function SWEP:PrimaryAttack()
        if self:GetState() ~= DEFIB_IDLE then return end

        local owner = self:GetOwner()
        local tr = owner:GetEyeTrace(MASK_SHOT_HULL)
        local pos = owner:GetPos()

        if tr.HitPos:Distance(pos) > maxdist then return end
        if GetRoundState() ~= ROUND_ACTIVE then return end

        local ent = tr.Entity
        if IsPlayer(ent) then
            self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
            self:Begin(ent)
        end
    end

    function SWEP:Holster()
        self:Reset()
        return true
    end
end

if CLIENT then
    function SWEP:DrawHUD()
        local state = self:GetState()
        self.BaseClass.DrawHUD(self)

        if state == DEFIB_IDLE then return end

        local charge = self:GetChargeTime()
        local time = self:GetBegin() + charge

        local x = ScrW() / 2.0
        local y = ScrH() / 2.0

        y = y + (y / 3)

        local w = 255

        if state == DEFIB_BUSY then
            if time < 0 then return end
            local progress = math.min(1, 1 - ((time - CurTime()) / charge))
            CRHUD:PaintProgressBar(x, y, w, Color(0, 255, 0, 155), self:GetMessage(), progress)
        elseif state == DEFIB_ERROR then
            CRHUD:PaintProgressBar(x, y, w, Color(200 + math.sin(CurTime() * 32) * 50, 0, 0, 155), self:GetMessage(), progress)
        end
    end

    function SWEP:PrimaryAttack() return false end
end

function SWEP:DryFire() return false end