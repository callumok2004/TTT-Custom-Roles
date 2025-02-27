AddCSLuaFile()

DEFINE_BASECLASS "weapon_tttbase"

SWEP.HoldType               = "slam"

if CLIENT then
   SWEP.PrintName           = "binoc_name"
   SWEP.Slot                = 7

   SWEP.ViewModelFOV        = 10
   SWEP.ViewModelFlip       = false
   SWEP.DrawCrosshair       = false

   SWEP.EquipMenuData = {
      type  = "item_weapon",
      desc  = "binoc_desc"
   };

   SWEP.Icon                = "vgui/ttt/icon_binoc"
end

SWEP.Base                   = "weapon_tttbase"

SWEP.ViewModel		        = "models/weapons/v_binoculars.mdl"
SWEP.WorldModel		        = "models/weapons/w_binoculars.mdl"

SWEP.Primary.ClipSize       = -1
SWEP.Primary.DefaultClip    = -1
SWEP.Primary.Automatic      = false
SWEP.Primary.Ammo           = "none"
SWEP.Primary.Delay          = 1.0

SWEP.Secondary.ClipSize     = -1
SWEP.Secondary.DefaultClip  = -1
SWEP.Secondary.Automatic    = true
SWEP.Secondary.Ammo         = "none"
SWEP.Secondary.Delay        = 0.2

SWEP.Kind                   = WEAPON_EQUIP2
SWEP.CanBuy                 = {ROLE_DETECTIVE} -- only detectives can buy
SWEP.WeaponID               = AMMO_BINOCULARS

SWEP.AllowDrop              = true

SWEP.ZoomLevels = {
   0,
   30,
   20,
   10
};

SWEP.ProcessingDelay       = 5

SWEP.WorldModelAttachment  = "ValveBiped.Bip01_R_Hand"
SWEP.WorldModelVector      = Vector(5, -5, 0)
SWEP.WorldModelAngle       = Angle(180, 180, 0)
SWEP.ViewModelDistance     = 100

function SWEP:SetupDataTables()
    self:DTVar("Bool",  0, "processing")
    self:DTVar("Float", 0, "start_time")
    self:DTVar("Int",   1, "zoom")
    -- Zoom levels are 1-based
    self.dt.zoom = 1

    return self.BaseClass.SetupDataTables(self)
end

function SWEP:PrimaryAttack()
    self:SetNextPrimaryFire( CurTime() + 0.1 )

    if self:IsTargetingCorpse() and not self.dt.processing then
        self:SetNextPrimaryFire( CurTime() + self.Primary.Delay )

        if SERVER then
            self.dt.processing = true
            self.dt.start_time = CurTime()
        end
    end
end

local click = Sound("weapons/sniper/sniper_zoomin.wav")
function SWEP:SecondaryAttack()
    self:SetNextSecondaryFire( CurTime() + self.Secondary.Delay )

    if CLIENT and IsFirstTimePredicted() then
        LocalPlayer():EmitSound(click)
    end

    self:CycleZoom()

    self.dt.processing = false
    self.dt.start_time = 0
end

function SWEP:SetZoom(level)
    if SERVER then
        self.dt.zoom = level
        local owner = self:GetOwner()
        owner:SetFOV(self.ZoomLevels[level], 0.3)

        -- Only show the view model when we're not zoomed in
        if level <= 1 then
            timer.Simple(0.25, function()
                -- Don't use the cached owner because we need to make sure the binocs weren't dropped
                if IsValid(self:GetOwner()) then
                    owner:DrawViewModel(true)
                end
            end)
        else
            owner:DrawViewModel(false)
        end
    end
end

function SWEP:GetViewModelPosition(pos, ang)
	local forward = ang:Forward()
    -- Move the model away from the player camera so it doesn't take up half the screen
    local dist = Vector(-forward.x * self.ViewModelDistance, -forward.y * self.ViewModelDistance, -forward.z * self.ViewModelDistance)
	return pos - dist, ang
end

function SWEP:CycleZoom()
    self.dt.zoom = self.dt.zoom + 1
    if not self.ZoomLevels[self.dt.zoom] then
        self.dt.zoom = 1
    end

    self:SetZoom(self.dt.zoom)
end

function SWEP:PreDrop()
    self:SetZoom(1)
    self.dt.processing = false
    return self.BaseClass.PreDrop(self)
end

function SWEP:Holster()
    self:SetZoom(1)
    self.dt.processing = false
    return true
end

function SWEP:Deploy()
    if SERVER and IsValid(self:GetOwner()) then
        self:GetOwner():DrawViewModel(false)
    end
    return true
end

function SWEP:Reload()
    return false
end

function SWEP:IsTargetingCorpse()
    local tr = self:GetOwner():GetEyeTrace(MASK_SHOT)
    local ent = tr.Entity

    return IsValid(ent) and ent:GetClass() == "prop_ragdoll" and
            CORPSE.GetPlayerNick(ent, false) ~= false
end

local confirm = Sound("npc/turret_floor/click1.wav")
function SWEP:IdentifyCorpse()
    if SERVER then
        local tr = self:GetOwner():GetEyeTrace(MASK_SHOT)
        CORPSE.ShowSearch(self:GetOwner(), tr.Entity, false, true)
    elseif IsFirstTimePredicted() then
        LocalPlayer():EmitSound(confirm)
    end
end

function SWEP:Think()
    BaseClass.Think(self)
    if self.dt.processing then
        if self:IsTargetingCorpse() then
            if CurTime() > (self.dt.start_time + self.ProcessingDelay) then
                self:IdentifyCorpse()

                self.dt.processing = false
                self.dt.start_time = 0
            end
        else
            self.dt.processing = false
            self.dt.start_time = 0
        end
    end
end

function SWEP:OnRemove()
    if CLIENT and IsValid(self:GetOwner()) and self:GetOwner() == LocalPlayer() and self:GetOwner():Alive() then
        RunConsoleCommand("lastinv")
    end
end

if CLIENT then
    function SWEP:Initialize()
        self:AddHUDHelp("binoc_help_pri", "binoc_help_sec", true)

        return self.BaseClass.Initialize(self)
    end

    local T = LANG.GetTranslation
    function SWEP:DrawHUD()
        self:DrawHelp()

        local length = 40
        local gap = 10

        local corpse = self:IsTargetingCorpse()

        if corpse then
            surface.SetDrawColor(0, 255, 0, 255)
            gap = 4
            length = 40
        else
            surface.SetDrawColor(0, 255, 0, 200)
        end

        local x = ScrW() / 2.0
        local y = ScrH() / 2.0

        surface.DrawLine( x - length, y, x - gap, y )
        surface.DrawLine( x + length, y, x + gap, y )
        surface.DrawLine( x, y - length, x, y - gap )
        surface.DrawLine( x, y + length, x, y + gap )


        surface.SetFont("DefaultFixedDropShadow")
        surface.SetTextColor(0, 255, 0, 200)
        surface.SetTextPos( x + length, y - length )
        surface.DrawText(T("binoc_zoom_level") .. " " .. self.dt.zoom)

        if corpse then
            surface.SetTextPos( x + length, y - length + 15)
            surface.DrawText(T("binoc_body"))
        end

        if self.dt.processing then
            y = y + (y / 2)

            local w, h = 200, 20

            surface.SetDrawColor(0, 255, 0, 255)
            surface.DrawOutlinedRect(x - w/2, y - h, w, h)

            surface.SetDrawColor(0, 255, 0, 180)
            local pct = math.Clamp((CurTime() - self.dt.start_time) / self.ProcessingDelay, 0, 1)
            surface.DrawRect(x - w/2, y - h, w * pct, h)
        end
    end

    function SWEP:DrawWorldModel()
       if not self.WorldModelEnt then
           self.WorldModelEnt = ClientsideModel(self.WorldModel)
           self.WorldModelEnt:SetNoDraw(true)
       end

       local owner = self:GetOwner()
       if IsValid(owner) then
           local boneid = owner:LookupBone(self.WorldModelAttachment)
           if not boneid or boneid <= 0 then return end

           local matrix = owner:GetBoneMatrix(boneid)
           if not matrix then return end

           local newPos, newAng = LocalToWorld(self.WorldModelVector, self.WorldModelAngle, matrix:GetTranslation(), matrix:GetAngles())

           self.WorldModelEnt:SetPos(newPos)
           self.WorldModelEnt:SetAngles(newAng)

           self.WorldModelEnt:SetupBones()
       else
           self.WorldModelEnt:SetPos(self:GetPos())
           self.WorldModelEnt:SetAngles(self:GetAngles())
       end

       self.WorldModelEnt:DrawModel()
    end

    function SWEP:AdjustMouseSensitivity()
        if self.dt.zoom > 0 then
            return 1 / self.dt.zoom
        end
        return -1
    end
end

