---- Help screen

local GetTranslation = LANG.GetTranslation
local GetPTranslation = LANG.GetParamTranslation

CreateConVar("ttt_spectator_mode", "0", FCVAR_ARCHIVE)
CreateConVar("ttt_mute_team_check", "0")
CreateConVar("ttt_show_raw_karma_value", "0")
CreateConVar("ttt_color_mode", "default", FCVAR_ARCHIVE)

CreateConVar("ttt_custom_inn_color_r", "25", FCVAR_ARCHIVE)
CreateConVar("ttt_custom_inn_color_g", "200", FCVAR_ARCHIVE)
CreateConVar("ttt_custom_inn_color_b", "25", FCVAR_ARCHIVE)

CreateConVar("ttt_custom_spec_inn_color_r", "245", FCVAR_ARCHIVE)
CreateConVar("ttt_custom_spec_inn_color_g", "200", FCVAR_ARCHIVE)
CreateConVar("ttt_custom_spec_inn_color_b", "0", FCVAR_ARCHIVE)

CreateConVar("ttt_custom_tra_color_r", "200", FCVAR_ARCHIVE)
CreateConVar("ttt_custom_tra_color_g", "25", FCVAR_ARCHIVE)
CreateConVar("ttt_custom_tra_color_b", "25", FCVAR_ARCHIVE)

CreateConVar("ttt_custom_spec_tra_color_r", "245", FCVAR_ARCHIVE)
CreateConVar("ttt_custom_spec_tra_color_g", "106", FCVAR_ARCHIVE)
CreateConVar("ttt_custom_spec_tra_color_b", "0", FCVAR_ARCHIVE)

CreateConVar("ttt_custom_det_color_r", "25", FCVAR_ARCHIVE)
CreateConVar("ttt_custom_det_color_g", "25", FCVAR_ARCHIVE)
CreateConVar("ttt_custom_det_color_b", "200", FCVAR_ARCHIVE)

CreateConVar("ttt_custom_jes_color_r", "180", FCVAR_ARCHIVE)
CreateConVar("ttt_custom_jes_color_g", "23", FCVAR_ARCHIVE)
CreateConVar("ttt_custom_jes_color_b", "253", FCVAR_ARCHIVE)

CreateConVar("ttt_custom_ind_color_r", "112", FCVAR_ARCHIVE)
CreateConVar("ttt_custom_ind_color_g", "50", FCVAR_ARCHIVE)
CreateConVar("ttt_custom_ind_color_b", "0", FCVAR_ARCHIVE)

CreateConVar("ttt_custom_mon_color_r", "69", FCVAR_ARCHIVE)
CreateConVar("ttt_custom_mon_color_g", "97", FCVAR_ARCHIVE)
CreateConVar("ttt_custom_mon_color_b", "0", FCVAR_ARCHIVE)
UpdateRoleColours()

CreateClientConVar("ttt_avoid_detective", "0", true, true)
CreateClientConVar("ttt_hide_role", "0", true, true)

HELPSCRN = {}

local dframe
function HELPSCRN:Show()
    if IsValid(dframe) then return end
    local margin = 15

    dframe = vgui.Create("DFrame")
    local w, h = 630, 470
    dframe:SetSize(w, h)
    dframe:Center()
    dframe:SetTitle(GetTranslation("help_title"))
    dframe:ShowCloseButton(true)

    local dbut = vgui.Create("DButton", dframe)
    local bw, bh = 50, 25
    dbut:SetSize(bw, bh)
    dbut:SetPos(w - bw - margin, h - bh - margin / 2)
    dbut:SetText(GetTranslation("close"))
    dbut.DoClick = function() dframe:Close() end

    local dtabs = vgui.Create("DPropertySheet", dframe)
    dtabs:SetPos(margin, margin * 2)
    dtabs:SetSize(w - margin * 2, h - margin * 3 - bh)

    local padding = dtabs:GetPadding()

    padding = padding * 2

    local tutparent = vgui.Create("DPanel", dtabs)
    tutparent:SetPaintBackground(false)
    tutparent:StretchToParent(margin, 0, 0, 0)

    self:CreateTutorial(tutparent)

    dtabs:AddSheet(GetTranslation("help_tut"), tutparent, "icon16/book_open.png", false, false, GetTranslation("help_tut_tip"))

    local dsettings = vgui.Create("DPanelList", dtabs)
    dsettings:StretchToParent(0, 0, padding, 0)
    dsettings:EnableVerticalScrollbar(true)
    dsettings:SetPadding(10)
    dsettings:SetSpacing(10)

    --- Interface area

    local dgui = vgui.Create("DForm", dsettings)
    dgui:SetName(GetTranslation("set_title_gui"))

    local cb = nil

    dgui:CheckBox(GetTranslation("set_tips"), "ttt_tips_enable")

    cb = dgui:NumSlider(GetTranslation("set_startpopup"), "ttt_startpopup_duration", 0, 60, 0)
    if cb.Label then
        cb.Label:SetWrap(true)
    end
    cb:SetTooltip(GetTranslation("set_startpopup_tip"))

    cb = dgui:NumSlider(GetTranslation("set_cross_opacity"), "ttt_ironsights_crosshair_opacity", 0, 1, 1)
    if cb.Label then
        cb.Label:SetWrap(true)
    end
    cb:SetTooltip(GetTranslation("set_cross_opacity"))

    cb = dgui:NumSlider(GetTranslation("set_cross_brightness"), "ttt_crosshair_brightness", 0, 1, 1)
    if cb.Label then
        cb.Label:SetWrap(true)
    end

    cb = dgui:NumSlider(GetTranslation("set_cross_size"), "ttt_crosshair_size", 0.1, 3, 1)
    if cb.Label then
        cb.Label:SetWrap(true)
    end

    dgui:CheckBox(GetTranslation("set_cross_disable"), "ttt_disable_crosshair")

    dgui:CheckBox(GetTranslation("set_minimal_id"), "ttt_minimal_targetid")

    dgui:CheckBox(GetTranslation("set_healthlabel"), "ttt_health_label")

    cb = dgui:CheckBox(GetTranslation("set_lowsights"), "ttt_ironsights_lowered")
    cb:SetTooltip(GetTranslation("set_lowsights_tip"))

    cb = dgui:CheckBox(GetTranslation("set_fastsw"), "ttt_weaponswitcher_fast")
    cb:SetTooltip(GetTranslation("set_fastsw_tip"))

    cb = dgui:CheckBox(GetTranslation("set_fastsw_menu"), "ttt_weaponswitcher_displayfast")
    cb:SetTooltip(GetTranslation("set_fastswmenu_tip"))

    cb = dgui:CheckBox(GetTranslation("set_wswitch"), "ttt_weaponswitcher_stay")
    cb:SetTooltip(GetTranslation("set_wswitch_tip"))

    cb = dgui:CheckBox(GetTranslation("set_cues"), "ttt_cl_soundcues")

    cb = dgui:CheckBox(GetTranslation("set_raw_karma"), "ttt_show_raw_karma_value")
    cb:SetTooltip(GetTranslation("set_raw_karma_tip"))

    cb = dgui:CheckBox(GetTranslation("set_hide_role"), "ttt_hide_role")
    cb:SetTooltip(GetTranslation("set_hide_role_tip"))

    dsettings:AddItem(dgui)

    local dcolor = vgui.Create("DForm", dsettings)
    dcolor:SetName(GetTranslation("set_color_mode"))
    dcolor:DoExpansion(false)

    local dcol = vgui.Create("DComboBox", dcolor)
    dcol:SetConVar("ttt_color_mode")
    dcol:SetSortItems(false)
    dcol:AddChoice("Default", "default")
    dcol:AddChoice("Simplified", "simple")
    dcol:AddChoice("Protanomaly", "protan")
    dcol:AddChoice("Deuteranomaly", "deutan")
    dcol:AddChoice("Tritanomaly", "tritan")
    dcol:AddChoice("Custom", "custom")

    dcol.OnSelect = function(idx, val, data)
        local mode = data -- For some reason it grabs the name and not the actual data so fix that here
        if mode == "Default" then mode = "default"
        elseif mode == "Simplified" then mode = "simple"
        elseif mode == "Protanomaly" then mode = "protan"
        elseif mode == "Deuteranomaly" then mode = "deutan"
        elseif mode == "Tritanomaly" then mode = "tritan"
        elseif mode == "Custom" then mode = "custom"
        end
        RunConsoleCommand("ttt_color_mode", mode)
        timer.Simple(0.5, function() UpdateRoleColours() end)
    end

    dcolor:AddItem(dcol)

    local dcolinn = vgui.Create("DColorMixer", dcolor)
    dcolinn:SetAlphaBar(false)
    dcolinn:SetWangs(false)
    dcolinn:SetPalette(false)
    dcolinn:SetLabel("Custom innocent color:")
    dcolinn:SetConVarR("ttt_custom_inn_color_r")
    dcolinn:SetConVarG("ttt_custom_inn_color_g")
    dcolinn:SetConVarB("ttt_custom_inn_color_b")
    dcolinn.ValueChanged = function(col)
        timer.Simple(0.5, function() UpdateRoleColours() end)
    end

    dcolor:AddItem(dcolinn)

    local dcolspecinn = vgui.Create("DColorMixer", dcolor)
    dcolspecinn:SetAlphaBar(false)
    dcolspecinn:SetWangs(false)
    dcolspecinn:SetPalette(false)
    dcolspecinn:SetLabel("Custom special innocent color:")
    dcolspecinn:SetConVarR("ttt_custom_spec_inn_color_r")
    dcolspecinn:SetConVarG("ttt_custom_spec_inn_color_g")
    dcolspecinn:SetConVarB("ttt_custom_spec_inn_color_b")
    dcolspecinn.ValueChanged = function(col)
        timer.Simple(0.5, function() UpdateRoleColours() end)
    end

    dcolor:AddItem(dcolspecinn)

    local dcoltra = vgui.Create("DColorMixer", dcolor)
    dcoltra:SetAlphaBar(false)
    dcoltra:SetWangs(false)
    dcoltra:SetPalette(false)
    dcoltra:SetLabel("Custom traitor color:")
    dcoltra:SetConVarR("ttt_custom_tra_color_r")
    dcoltra:SetConVarG("ttt_custom_tra_color_g")
    dcoltra:SetConVarB("ttt_custom_tra_color_b")
    dcoltra.ValueChanged = function(col)
        timer.Simple(0.5, function() UpdateRoleColours() end)
    end

    dcolor:AddItem(dcoltra)

    local dcolspectra = vgui.Create("DColorMixer", dcolor)
    dcolspectra:SetAlphaBar(false)
    dcolspectra:SetWangs(false)
    dcolspectra:SetPalette(false)
    dcolspectra:SetLabel("Custom special traitor color:")
    dcolspectra:SetConVarR("ttt_custom_spec_tra_color_r")
    dcolspectra:SetConVarG("ttt_custom_spec_tra_color_g")
    dcolspectra:SetConVarB("ttt_custom_spec_tra_color_b")
    dcolspectra.ValueChanged = function(col)
        timer.Simple(0.5, function() UpdateRoleColours() end)
    end

    dcolor:AddItem(dcolspectra)

    local dcoldet = vgui.Create("DColorMixer", dcolor)
    dcoldet:SetAlphaBar(false)
    dcoldet:SetWangs(false)
    dcoldet:SetPalette(false)
    dcoldet:SetLabel("Custom detective color:")
    dcoldet:SetConVarR("ttt_custom_det_color_r")
    dcoldet:SetConVarG("ttt_custom_det_color_g")
    dcoldet:SetConVarB("ttt_custom_det_color_b")
    dcoldet.ValueChanged = function(col)
        timer.Simple(0.5, function() UpdateRoleColours() end)
    end

    dcolor:AddItem(dcoldet)

    local dcoljes = vgui.Create("DColorMixer", dcolor)
    dcoljes:SetAlphaBar(false)
    dcoljes:SetWangs(false)
    dcoljes:SetPalette(false)
    dcoljes:SetLabel("Custom jester color:")
    dcoljes:SetConVarR("ttt_custom_jes_color_r")
    dcoljes:SetConVarG("ttt_custom_jes_color_g")
    dcoljes:SetConVarB("ttt_custom_jes_color_b")
    dcoljes.ValueChanged = function(col)
        timer.Simple(0.5, function() UpdateRoleColours() end)
    end

    dcolor:AddItem(dcoljes)

    local dcolind = vgui.Create("DColorMixer", dcolor)
    dcolind:SetAlphaBar(false)
    dcolind:SetWangs(false)
    dcolind:SetPalette(false)
    dcolind:SetLabel("Custom independent color:")
    dcolind:SetConVarR("ttt_custom_ind_color_r")
    dcolind:SetConVarG("ttt_custom_ind_color_g")
    dcolind:SetConVarB("ttt_custom_ind_color_b")
    dcolind.ValueChanged = function(col)
        timer.Simple(0.5, function() UpdateRoleColours() end)
    end

    dcolor:AddItem(dcolind)

    local dcolmon = vgui.Create("DColorMixer", dcolor)
    dcolmon:SetAlphaBar(false)
    dcolmon:SetWangs(false)
    dcolmon:SetPalette(false)
    dcolmon:SetLabel("Custom monster color:")
    dcolmon:SetConVarR("ttt_custom_mon_color_r")
    dcolmon:SetConVarG("ttt_custom_mon_color_g")
    dcolmon:SetConVarB("ttt_custom_mon_color_b")
    dcolmon.ValueChanged = function(col)
        timer.Simple(0.5, function() UpdateRoleColours() end)
    end

    dcolor:AddItem(dcolmon)

    dsettings:AddItem(dcolor)

    --- Gameplay area

    local dplay = vgui.Create("DForm", dsettings)
    dplay:SetName(GetTranslation("set_title_play"))

    cb = dplay:CheckBox(GetTranslation("set_avoid_det"), "ttt_avoid_detective")
    cb:SetTooltip(GetTranslation("set_avoid_det_tip"))

    cb = dplay:CheckBox(GetTranslation("set_specmode"), "ttt_spectator_mode")
    cb:SetTooltip(GetTranslation("set_specmode_tip"))

    -- For some reason this one defaulted to on, unlike other checkboxes, so
    -- force it to the actual value of the cvar (which defaults to off)
    local mute = dplay:CheckBox(GetTranslation("set_mute"), "ttt_mute_team_check")
    mute:SetValue(GetConVar("ttt_mute_team_check"):GetBool())
    mute:SetTooltip(GetTranslation("set_mute_tip"))

    dsettings:AddItem(dplay)

    --- Language area
    local dlanguage = vgui.Create("DForm", dsettings)
    dlanguage:SetName(GetTranslation("set_title_lang"))

    local dlang = vgui.Create("DComboBox", dlanguage)
    dlang:SetConVar("ttt_language")

    dlang:AddChoice("Server default", "auto")
    for _, lang in pairs(LANG.GetLanguages()) do
        dlang:AddChoice(string.Capitalize(lang), lang)
    end
    -- Why is DComboBox not updating the cvar by default?
    dlang.OnSelect = function(idx, val, data)
        RunConsoleCommand("ttt_language", data)
    end
    dlang.Think = dlang.ConVarStringThink

    dlanguage:Help(GetTranslation("set_lang"))
    dlanguage:AddItem(dlang)

    dsettings:AddItem(dlanguage)

    dtabs:AddSheet(GetTranslation("help_settings"), dsettings, "icon16/wrench.png", false, false, GetTranslation("help_settings_tip"))

    -- BEM settings

    padding = dtabs:GetPadding()
    padding = padding * 2

    dsettings = vgui.Create("DPanelList", dtabs)
    dsettings:StretchToParent(0, 0, padding, 0)
    dsettings:EnableVerticalScrollbar(true)
    dsettings:SetPadding(10)
    dsettings:SetSpacing(10)

    -- info text
    local dlabel = vgui.Create("DLabel", dsettings)
    dlabel:SetText("All changes made here are clientside and will only apply to your own menu!")
    dlabel:SetTextColor(Color(0, 0, 0, 255))
    dsettings:AddItem(dlabel)

    -- layout section
    local dlayout = vgui.Create("DForm", dsettings)
    dlayout:SetName("Item List Layout")

    dlayout:NumSlider("Number of columns (def. 4)", "ttt_bem_cols", 1, 20, 0)
    dlayout:NumSlider("Number of rows (def. 5)", "ttt_bem_rows", 1, 20, 0)
    dlayout:NumSlider("Icon size (def. 64)", "ttt_bem_size", 32, 128, 0)

    dsettings:AddItem(dlayout)

    -- marker section
    local dmarker = vgui.Create("DForm", dsettings)
    dmarker:SetName("Item Marker Settings")

    dmarker:CheckBox("Show slot marker", "ttt_bem_marker_slot")
    dmarker:CheckBox("Show custom item marker", "ttt_bem_marker_custom")
    dmarker:CheckBox("Show favourite item marker", "ttt_bem_marker_fav")

    dsettings:AddItem(dmarker)

    dtabs:AddSheet("BEM settings", dsettings, "icon16/cog.png", false, false, "Better Equipment Menu Settings")

    -- Hitmarkers Settings

    padding = dtabs:GetPadding()
    padding = padding * 2

    dsettings = vgui.Create("DPanelList", dtabs)
    dsettings:StretchToParent(0, 0, padding, 0)
    dsettings:EnableVerticalScrollbar(true)
    dsettings:SetPadding(10)
    dsettings:SetSpacing(10)

    dlabel = vgui.Create("DLabel", dsettings)
    dlabel:SetText("All changes made here are clientside and will only apply to your own menu!\nUse the !hmcolor command in chat to change the marker colors.\nUse the !hmcritcolor command in chat to change the color of critical hit markers.")
    dlabel:SetTextColor(Color(0, 0, 0, 255))
    dlabel:SizeToContents()
    dsettings:AddItem(dlabel)

    local dmarkers = vgui.Create("DForm", dsettings)
    dmarkers:SetName("Hitmarkers")

    dmarkers:CheckBox("Enabled", "hm_enabled")
    dmarkers:CheckBox("Show criticals", "hm_showcrits")
    dmarkers:CheckBox("Play hit sound", "hm_hitsound")

    dsettings:AddItem(dmarkers)

    dtabs:AddSheet("HM settings", dsettings, "icon16/cross.png", false, false, "Hitmarker settings")

    hook.Call("TTTSettingsTabs", GAMEMODE, dtabs)

    dframe:MakePopup()
end

local function ShowTTTHelp(ply, cmd, args)
    HELPSCRN:Show()
end
concommand.Add("ttt_helpscreen", ShowTTTHelp)

-- Some spectator mode bookkeeping

local function SpectateCallback(cv, old, new)
    local num = tonumber(new)
    if num and (num == 0 or num == 1) then
        RunConsoleCommand("ttt_spectate", num)
    end
end
cvars.AddChangeCallback("ttt_spectator_mode", SpectateCallback)

local function MuteTeamCallback(cv, old, new)
    local num = tonumber(new)
    if num and (num == 0 or num == 1) then
        RunConsoleCommand("ttt_mute_team", num)
    end
end
cvars.AddChangeCallback("ttt_mute_team_check", MuteTeamCallback)

--- Tutorial

local imgpath = "vgui/ttt/help/tut0%d"
local tutorial_pages = 6
function HELPSCRN:CreateTutorial(parent)
    local w, h = parent:GetSize()
    local m = 5

    local bg = vgui.Create("ColoredBox", parent)
    bg:StretchToParent(0, 0, 0, 0)
    bg:SetTall(330)
    bg:SetColor(COLOR_BLACK)

    local tut = vgui.Create("DImage", parent)
    tut:StretchToParent(0, 0, 0, 0)
    tut:SetVerticalScrollbarEnabled(false)

    tut:SetImage(Format(imgpath, 1))
    tut:SetWide(1024)
    tut:SetTall(512)

    tut.current = 1

    local bw, bh = 100, 30

    local bar = vgui.Create("TTTProgressBar", parent)
    bar:SetSize(200, bh)
    bar:MoveBelow(bg)
    bar:CenterHorizontal()
    bar:SetMin(1)
    bar:SetMax(tutorial_pages)
    bar:SetValue(1)
    bar:SetColor(Color(0, 200, 0))

    -- fixing your panels...
    bar.UpdateText = function(s)
        s.Label:SetText(Format("%i / %i", s.m_iValue, s.m_iMax))
    end

    bar:UpdateText()

    local bnext = vgui.Create("DButton", parent)
    bnext:SetFont("Trebuchet22")
    bnext:SetSize(bw, bh)
    bnext:SetText(GetTranslation("next"))
    bnext:CopyPos(bar)
    bnext:AlignRight(1)

    local bprev = vgui.Create("DButton", parent)
    bprev:SetFont("Trebuchet22")
    bprev:SetSize(bw, bh)
    bprev:SetText(GetTranslation("prev"))
    bprev:CopyPos(bar)
    bprev:AlignLeft()

    bnext.DoClick = function()
        if tut.current < tutorial_pages then
            tut.current = tut.current + 1
            tut:SetImage(Format(imgpath, tut.current))
            bar:SetValue(tut.current)
        end
    end

    bprev.DoClick = function()
        if tut.current > 1 then
            tut.current = tut.current - 1
            tut:SetImage(Format(imgpath, tut.current))
            bar:SetValue(tut.current)
        end
    end
end
