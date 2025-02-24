---- VGUI panel version of the scoreboard, based on TEAM GARRY's sandbox mode
---- scoreboard.

local draw = draw
local ipairs = ipairs
local IsValid = IsValid
local pairs = pairs
local player = player
local surface = surface
local string = string
local table = table
local timer = timer
local vgui = vgui

local CallHook = hook.Call
local RunHook = hook.Run
local PlayerIterator = player.Iterator
local GetTranslation = LANG.GetTranslation
local GetPTranslation = LANG.GetParamTranslation
local StringFormat = string.format
local StringSub = string.sub
local StringUpper = string.upper

local clamp = math.Clamp
local max = math.max
local min = math.min
local floor = math.floor

include("sb_team.lua")

surface.CreateFont("cool_small", {
    font = "coolvetica",
    size = 20,
    weight = 400
})
surface.CreateFont("cool_large", {
    font = "coolvetica",
    size = 24,
    weight = 400
})
surface.CreateFont("treb_small", {
    font = "Trebuchet18",
    size = 14,
    weight = 700
})

CreateClientConVar("ttt_scoreboard_sorting", "name", true, false, "name | role | karma | score | deaths | ping")
CreateClientConVar("ttt_scoreboard_ascending", "1", true, false, "Should scoreboard ordering be in ascending order")

local logo = surface.GetTextureID("vgui/ttt/score_logo")

local PANEL = {}

local function UntilMapChange()
    local rounds_left = max(0, GetGlobalInt("ttt_rounds_left", 6))
    local time_left = floor(max(0, ((GetGlobalInt("ttt_time_limit_minutes") or 60) * 60) - CurTime()))

    local h = floor(time_left / 3600)
    time_left = time_left - floor(h * 3600)
    local m = floor(time_left / 60)
    time_left = time_left - floor(m * 60)
    local s = floor(time_left)

    return rounds_left, StringFormat("%02i:%02i:%02i", h, m, s)
end

GROUP_TERROR = 1
GROUP_NOTFOUND = 2
GROUP_FOUND = 3
GROUP_SEARCHED = 4
GROUP_SPEC = 5

GROUP_COUNT = 6

function AddScoreGroup(name)
    -- Utility function to register a score group
    if _G["GROUP_" .. name] then
        error("Group of name '" .. name .. "' already exists!")
        return
    end
    GROUP_COUNT = GROUP_COUNT + 1
    _G["GROUP_" .. name] = GROUP_COUNT
end

function ScoreGroup(p)
    if not IsValid(p) then return -1 end -- will not match any group panel

    local fake_dead = (p.IsFakeDead and p:IsFakeDead())
    local group = CallHook("TTTScoreGroup", nil, p)
    -- Ignore the Dead Ringer's scoreboard override because it doesn't work with custom roles
    -- Otherwise, if that hook gave us a group, use it
    if group and not fake_dead then
        return group
    end

    if DetectiveMode() and p:GetRole() ~= ROLE_NONE then
        -- Show players who used the Dead Ringer as "Dead"
        if fake_dead or (p:IsSpec() and not p:Alive()) then
            if p.search_result or p:GetNWBool("body_searched", false) then
                return GROUP_SEARCHED
            elseif p:GetNWBool("body_found", false) then
                return GROUP_FOUND
            else
                local client = LocalPlayer()
                -- To terrorists, missing players show as alive
                if client:IsSpec() or
                        client:IsActiveTraitorTeam() or client:IsActiveMonsterTeam() or
                        (client:IsActiveIndependentTeam() and cvars.Bool("ttt_" .. ROLE_STRINGS_RAW[client:GetRole()] .. "_update_scoreboard", false)) or
                        ((GAMEMODE.round_state ~= ROUND_ACTIVE) and client:IsTerror()) then
                    return GROUP_NOTFOUND
                else
                    return GROUP_TERROR
                end
            end
        end
    end

    return group or (p:IsTerror() and GROUP_TERROR or GROUP_SPEC)
end

local role_ranks = nil
local function GetRoleRank(role)
    if not role_ranks then
        local function SortByRoleName(rolea, roleb)
            return ROLE_STRINGS[rolea] < ROLE_STRINGS[roleb]
        end

        -- Build the rank table so roles are ordered like this:
        --   Vanilla Detective
        --   Special detectives
        --   Vanilla Innocent
        --   Special innocents
        --   Vanilla Traitor
        --   Special traitors
        --   Jesters
        --   Independents
        --   Monsters
        role_ranks = {}

        local rank = 1

        -- Detectives
        role_ranks[ROLE_DETECTIVE] = rank
        rank = rank + 1

        local detective_roles = GetTeamRoles(DETECTIVE_ROLES)
        table.sort(detective_roles, SortByRoleName)
        for _, r in ipairs(detective_roles) do
            if r == ROLE_DETECTIVE then continue end

            role_ranks[r] = rank
            rank = rank + 1
        end

        -- Innocents
        role_ranks[ROLE_INNOCENT] = rank
        rank = rank + 1

        local innocent_roles = GetTeamRoles(INNOCENT_ROLES)
        table.sort(innocent_roles, SortByRoleName)
        for _, r in ipairs(innocent_roles) do
            if r == ROLE_INNOCENT then continue end
            if DETECTIVE_ROLES[r] then continue end

            role_ranks[r] = rank
            rank = rank + 1
        end

        -- Traitors
        role_ranks[ROLE_TRAITOR] = rank
        rank = rank + 1

        local traitor_roles = GetTeamRoles(TRAITOR_ROLES)
        table.sort(traitor_roles, SortByRoleName)
        for _, r in ipairs(traitor_roles) do
            if r == ROLE_TRAITOR then continue end

            role_ranks[r] = rank
            rank = rank + 1
        end

        -- Jesters
        local jester_roles = GetTeamRoles(JESTER_ROLES)
        table.sort(jester_roles, SortByRoleName)
        for _, r in ipairs(jester_roles) do
            role_ranks[r] = rank
            rank = rank + 1
        end

        -- Independents
        local independent_roles = GetTeamRoles(INDEPENDENT_ROLES)
        table.sort(independent_roles, SortByRoleName)
        for _, r in ipairs(independent_roles) do
            role_ranks[r] = rank
            rank = rank + 1
        end

        -- Monsters
        local monster_roles = GetTeamRoles(MONSTER_ROLES)
        table.sort(monster_roles, SortByRoleName)
        for _, r in ipairs(monster_roles) do
            role_ranks[r] = rank
            rank = rank + 1
        end

        -- Put unknowns last
        role_ranks[ROLE_NONE] = rank * 2

        --for r, i in pairs(role_ranks) do
        --    print(i, ROLE_STRINGS[r])
        --end
    end

    return role_ranks[role]
end

-- Comparison functions used to sort scoreboard
_G.sboard_sort = {
    name = function(plya, plyb)
        -- Automatically sorts by name if this returns 0
        return 0
    end,
    ping = function(plya, plyb)
        return plya:Ping() - plyb:Ping()
    end,
    deaths = function(plya, plyb)
        return plya:Deaths() - plyb:Deaths()
    end,
    score = function(plya, plyb)
        return plya:Frags() - plyb:Frags()
    end,
    role = function(plya, plyb)
        local client = LocalPlayer()

        -- Use the scoreboard hook to determine whether the client knows the role of each player
        -- If the hook returns something that is not a number that means the role is unknown, so just use ROLE_NONE
        local rolea = plya == client and plya:GetRole() or RunHook("TTTScoreboardRowColorForPlayer", plya)
        if not isnumber(rolea) then
            rolea = ROLE_NONE
        end
        local roleaRank = GetRoleRank(rolea)

        local roleb = plyb == client and plyb:GetRole() or RunHook("TTTScoreboardRowColorForPlayer", plyb)
        if not isnumber(roleb) then
            roleb = ROLE_NONE
        end
        local rolebRank = GetRoleRank(roleb)

        -- Then sort by the role rank for each known role, translated
        -- to a c-style compare function
        if roleaRank > rolebRank then
            return 1
        elseif roleaRank < rolebRank then
            return -1
        end
        return 0
    end,
    karma = function(plya, plyb)
        return (plya:GetBaseKarma() or 0) - (plyb:GetBaseKarma() or 0)
    end
}

----- PANEL START

function PANEL:Init()

    self.hostdesc = vgui.Create("DLabel", self)
    self.hostdesc:SetText(GetPTranslation("sb_playing", { version = GAMEMODE.Version, map = StringUpper(game.GetMap())}))
    self.hostdesc:SetContentAlignment(9)

    self.hostname = vgui.Create("DLabel", self)
    self.hostname:SetText(GetHostName())
    self.hostname:SetContentAlignment(6)

    self.mapchange = vgui.Create("DLabel", self)
    self.mapchange:SetText("Map changes in 00 rounds or in 00:00:00")
    self.mapchange:SetContentAlignment(9)

    self.mapchange.Think = function(sf)
        local r, t = UntilMapChange()

        sf:SetText(GetPTranslation("sb_mapchange",
                { num = r, time = t }))
        sf:SizeToContents()
    end

    self.ply_frame = vgui.Create("TTTPlayerFrame", self)

    self.ply_groups = {}

    local t = vgui.Create("TTTScoreGroup", self.ply_frame:GetCanvas())
    t:SetGroupInfo(GetTranslation("terrorists"), Color(0, 200, 0, 100), GROUP_TERROR)
    self.ply_groups[GROUP_TERROR] = t

    t = vgui.Create("TTTScoreGroup", self.ply_frame:GetCanvas())
    t:SetGroupInfo(GetTranslation("spectators"), Color(200, 200, 0, 100), GROUP_SPEC)
    self.ply_groups[GROUP_SPEC] = t

    if DetectiveMode() then
        t = vgui.Create("TTTScoreGroup", self.ply_frame:GetCanvas())
        t:SetGroupInfo(GetTranslation("sb_mia"), Color(130, 190, 130, 100), GROUP_NOTFOUND)
        self.ply_groups[GROUP_NOTFOUND] = t

        t = vgui.Create("TTTScoreGroup", self.ply_frame:GetCanvas())
        t:SetGroupInfo(GetTranslation("sb_confirmed"), Color(130, 170, 10, 100), GROUP_FOUND)
        self.ply_groups[GROUP_FOUND] = t

        t = vgui.Create("TTTScoreGroup", self.ply_frame:GetCanvas())
        t:SetGroupInfo(GetTranslation("sb_investigated"), Color(70, 70, 130, 100), GROUP_SEARCHED)
        self.ply_groups[GROUP_SEARCHED] = t
    end

    CallHook("TTTScoreGroups", nil, self.ply_frame:GetCanvas(), self.ply_groups)

    -- the various score column headers
    self.cols = {}
    self:AddColumn(GetTranslation("sb_ping"), nil, nil, "ping")
    if GetConVar("ttt_scoreboard_deaths"):GetBool() then
        self:AddColumn(GetTranslation("sb_deaths"), nil, nil, "deaths")
    end
    if GetConVar("ttt_scoreboard_score"):GetBool() then
        self:AddColumn(GetTranslation("sb_score"), nil, nil, "score")
    end

    if KARMA.IsEnabled() then
        self:AddColumn(GetTranslation("sb_karma"), nil, nil, "karma")
    end

    self.sort_headers = {}
    -- Reuse some translations
    -- Columns spaced out a bit to allow for more room for translations
    self:AddFakeColumn(GetTranslation("sb_sortby"), nil, 70, nil) -- "Sort by:"
    self:AddFakeColumn(GetTranslation("equip_spec_name"), nil, 70, "name")
    self:AddFakeColumn(GetTranslation("sb_role"), nil, 70, "role")

    -- Let hooks add their column headers (via AddColumn() or AddFakeColumn())
    CallHook("TTTScoreboardColumns", nil, self)

    self:UpdateScoreboard()
    self:StartUpdateTimer()
end

local function sort_header_handler(self_, lbl)
    return function()
        surface.PlaySound("ui/buttonclick.wav")

        local sorting = GetConVar("ttt_scoreboard_sorting")
        local ascending = GetConVar("ttt_scoreboard_ascending")

        if lbl.HeadingIdentifier == sorting:GetString() then
            ascending:SetBool(not ascending:GetBool())
        else
            sorting:SetString(lbl.HeadingIdentifier)
            ascending:SetBool(true)
        end

        for _, scoregroup in pairs(self_.ply_groups) do
            scoregroup:UpdateSortCache()
            scoregroup:InvalidateLayout()
        end

        self_:ApplySchemeSettings()
    end
end

-- For headings only the label parameter is relevant, second param is included for
-- parity with sb_row
local function column_label_work(self_, table_to_add, label, width, sort_identifier, sort_func)
    local lbl = vgui.Create("DLabel", self_)
    lbl:SetText(label)
    local can_sort = false
    lbl.IsHeading = true
    lbl.Width = width or 50 -- Retain compatibility with existing code

    if sort_identifier ~= nil then
        can_sort = true
        -- If we have an identifier and an existing sort function then it was a built-in
        -- Otherwise...
        if _G.sboard_sort[sort_identifier] == nil then
            if sort_func == nil then
                ErrorNoHalt("Sort ID provided without a sorting function, Label = ", label, " ; ID = ", sort_identifier)
                can_sort = false
            else
                _G.sboard_sort[sort_identifier] = sort_func
            end
        end
    end

    if can_sort then
        lbl:SetMouseInputEnabled(true)
        lbl:SetCursor("hand")
        lbl.HeadingIdentifier = sort_identifier
        lbl.DoClick = sort_header_handler(self_, lbl)
    end

    table.insert(table_to_add, lbl)
    return lbl
end

function PANEL:AddColumn(label, _, width, sort_id, sort_func)
    return column_label_work(self, self.cols, label, width, sort_id, sort_func)
end

-- Adds just column headers without player-specific data
-- Identical to PANEL:AddColumn except it adds to the sort_headers table instead
function PANEL:AddFakeColumn(label, _, width, sort_id, sort_func)
    return column_label_work(self, self.sort_headers, label, width, sort_id, sort_func)
end

local function UpdateScoreboard(force)
    local pnl = GAMEMODE:GetScoreboardPanel()
    if IsValid(pnl) then
        pnl:UpdateScoreboard(force)
    end
end

function PANEL:StartUpdateTimer()
    if not timer.Exists("TTTScoreboardUpdater") then
        timer.Create("TTTScoreboardUpdater", 0.3, 0, UpdateScoreboard)
    end
end

net.Receive("TTT_ScoreboardUpdate", function()
    local force = net.ReadBool()
    UpdateScoreboard(force)
end)

local colors = {
    bg = Color(30, 30, 30, 235),
    bar = Color(220, 180, 0, 255)
};

local y_logo_off = 72

function PANEL:Paint()
    -- Logo sticks out, so always offset bg
    draw.RoundedBox(8, 0, y_logo_off, self:GetWide(), self:GetTall() - y_logo_off, colors.bg)

    -- Server name is outlined by orange/gold area
    draw.RoundedBox(8, 0, y_logo_off + 25, self:GetWide(), 32, colors.bar)

    -- TTT Logo
    surface.SetTexture(logo)
    surface.SetDrawColor(255, 255, 255, 255)
    surface.DrawTexturedRect(5, 0, 256, 256)

end

function PANEL:PerformLayout()
    -- position groups and find their total size
    local gy = 0
    -- can't just use pairs (undefined ordering) or ipairs (group 2 and 3 might not exist)
    for i = 1, GROUP_COUNT do
        local group = self.ply_groups[i]
        if IsValid(group) then
            if group:HasRows() then
                group:SetVisible(true)
                group:SetPos(0, gy)
                group:SetSize(self.ply_frame:GetWide(), group:GetTall())
                group:InvalidateLayout()
                gy = gy + group:GetTall() + 5
            else
                group:SetVisible(false)
            end
        end
    end

    self.ply_frame:GetCanvas():SetSize(self.ply_frame:GetCanvas():GetWide(), gy)

    local h = y_logo_off + 110 + self.ply_frame:GetCanvas():GetTall()

    -- if we will have to clamp our height, enable the mouse so player can scroll
    local scrolling = h > ScrH() * 0.95
    --   gui.EnableScreenClicker(scrolling)
    self.ply_frame:SetScroll(scrolling)

    h = clamp(h, 110 + y_logo_off, ScrH() * 0.95)

    local w = max(ScrW() * 0.6, 640)

    self:SetSize(w, h)
    self:SetPos((ScrW() - w) / 2, min(72, (ScrH() - h) / 4))

    self.ply_frame:SetPos(8, y_logo_off + 109)
    self.ply_frame:SetSize(self:GetWide() - 16, self:GetTall() - 109 - y_logo_off - 5)

    -- server stuff
    self.hostdesc:SizeToContents()
    self.hostdesc:SetPos(w - self.hostdesc:GetWide() - 8, y_logo_off + 5)

    local hw = w - 180 - 8
    self.hostname:SetSize(hw, 32)
    self.hostname:SetPos(w - self.hostname:GetWide() - 8, y_logo_off + 27)

    surface.SetFont("cool_large")
    local hname = self.hostname:GetValue()
    local tw, _ = surface.GetTextSize(hname)
    while tw > hw do
        hname = StringSub(hname, 1, -6) .. "..."
        tw, _ = surface.GetTextSize(hname)
    end

    self.hostname:SetText(hname)

    self.mapchange:SizeToContents()
    self.mapchange:SetPos(w - self.mapchange:GetWide() - 8, y_logo_off + 60)

    -- score columns
    local cy = y_logo_off + 90
    local cx = w - 8 - (scrolling and 16 or 0)
    for k, v in ipairs(self.cols) do
        v:SizeToContents()
        cx = cx - v.Width
        v:SetPos(cx - v:GetWide() / 2, cy)
    end

    -- sort headers
    -- reuse cy
    -- cx = logo width + buffer space
    cx = 256 + 8
    for k, v in ipairs(self.sort_headers) do
        v:SizeToContents()
        cx = cx + v.Width
        v:SetPos(cx - v:GetWide() / 2, cy)
    end
end

function PANEL:ApplySchemeSettings()
    self.hostdesc:SetFont("cool_small")
    self.hostname:SetFont("cool_large")
    self.mapchange:SetFont("treb_small")

    self.hostdesc:SetTextColor(COLOR_WHITE)
    self.hostname:SetTextColor(COLOR_BLACK)
    self.mapchange:SetTextColor(COLOR_WHITE)

    local sorting = GetConVar("ttt_scoreboard_sorting"):GetString()

    local highlight_color = Color(175, 175, 175, 255)
    local default_color = COLOR_WHITE

    for k, v in pairs(self.cols) do
        v:SetFont("treb_small")
        if sorting == v.HeadingIdentifier then
            v:SetTextColor(highlight_color)
        else
            v:SetTextColor(default_color)
        end
    end

    for k, v in pairs(self.sort_headers) do
        v:SetFont("treb_small")
        if sorting == v.HeadingIdentifier then
            v:SetTextColor(highlight_color)
        else
            v:SetTextColor(default_color)
        end
    end
end

function PANEL:UpdateScoreboard(force)
    if not force and not self:IsVisible() then return end

    local layout = false

    -- Put players where they belong. Groups will dump them as soon as they don't
    -- anymore.
    for k, p in PlayerIterator() do
        if IsValid(p) then
            local group = ScoreGroup(p)
            if self.ply_groups[group] and not self.ply_groups[group]:HasPlayerRow(p) then
                self.ply_groups[group]:AddPlayerRow(p)
                layout = true
            end
        end
    end

    for k, group in pairs(self.ply_groups) do
        if IsValid(group) then
            group:SetVisible(group:HasRows())
            group:UpdatePlayerData(force)
        end
    end

    if layout then
        self:PerformLayout()
    else
        self:InvalidateLayout()
    end
end

vgui.Register("TTTScoreboard", PANEL, "Panel")

---- PlayerFrame is defined in sandbox and is basically a little scrolling
---- hack. Just putting it here (slightly modified) because it's tiny.

PANEL = {}
function PANEL:Init()
    self.pnlCanvas = vgui.Create("Panel", self)
    self.YOffset = 0

    self.scroll = vgui.Create("DVScrollBar", self)
end

function PANEL:GetCanvas() return self.pnlCanvas end

function PANEL:OnMouseWheeled(dlta)
    self.scroll:AddScroll(dlta * -2)

    self:InvalidateLayout()
end

function PANEL:SetScroll(st)
    self.scroll:SetEnabled(st)
end

function PANEL:PerformLayout()
    self.pnlCanvas:SetVisible(self:IsVisible())

    -- scrollbar
    self.scroll:SetPos(self:GetWide() - 16, 0)
    self.scroll:SetSize(16, self:GetTall())

    local was_on = self.scroll.Enabled
    self.scroll:SetUp(self:GetTall(), self.pnlCanvas:GetTall())
    self.scroll:SetEnabled(was_on) -- setup mangles enabled state

    self.YOffset = self.scroll:GetOffset()

    self.pnlCanvas:SetPos(0, self.YOffset)
    self.pnlCanvas:SetSize(self:GetWide() - (self.scroll.Enabled and 16 or 0), self.pnlCanvas:GetTall())
end
vgui.Register("TTTPlayerFrame", PANEL, "Panel")
