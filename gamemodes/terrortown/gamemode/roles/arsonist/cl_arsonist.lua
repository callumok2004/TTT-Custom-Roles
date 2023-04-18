local hook = hook

local client

------------------
-- TRANSLATIONS --
------------------

hook.Add("Initialize", "Arsonist_Translations_Initialize", function()
    -- Weapons
    LANG.AddToLanguage("english", "arsonistigniter_help_pri", "Press {primaryfire} to ignite doused players.")
    LANG.AddToLanguage("english", "arsonistigniter_help_sec", "Can only be used when all players are doused")

    -- Events
    LANG.AddToLanguage("english", "ev_arsonignite", "Everyone was ignited by the {arsonist}")

    -- Win conditions
    LANG.AddToLanguage("english", "win_arsonist", "The {role} has burnt everyone to a crisp!")
    LANG.AddToLanguage("english", "ev_win_arsonist", "The blazing {role} has won the round!")

    -- HUD
    LANG.AddToLanguage("english", "arsdouse_dousing", "DOUSING")
    LANG.AddToLanguage("english", "arsdouse_doused", "DOUSED")
    LANG.AddToLanguage("english", "arsdouse_failed", "DOUSING FAILED")
    LANG.AddToLanguage("english", "arsonist_hud", "Dousing complete. Igniter active.")

    -- Popup
    LANG.AddToLanguage("english", "info_popup_arsonist", [[You are {role}! Get close to other players
to douse them in gasoline.

Once every player has been doused you can use your igniter to set them
all ablaze. Be the last person standing to win!]])
end)

---------------
-- TARGET ID --
---------------

-- Show "DOUSED" label on players who have been doused
hook.Add("TTTTargetIDPlayerText", "Arsonist_TTTTargetIDPlayerText", function(ent, cli, text, col, secondaryText)
    if GetRoundState() < ROUND_ACTIVE then return end
    if not cli:IsArsonist() then return end
    if not IsPlayer(ent) then return end

    local state = ent:GetNWInt("TTTArsonistDouseStage", ARSONIST_UNDOUSED)
    if state ~= ARSONIST_DOUSED then return end

    local T = LANG.GetTranslation
    if text == nil then
        return T("arsdouse_doused"), ROLE_COLORS[ROLE_TRAITOR]
    end
    return text, col, T("arsdouse_doused"), ROLE_COLORS[ROLE_TRAITOR]
end)

-- NOTE: ROLE_IS_TARGETID_OVERRIDDEN is not required since only secondary text is being changed and that is not tracked there

----------------
-- SCOREBOARD --
----------------

-- Show "DOUSED" label on the players who have been doused
hook.Add("TTTScoreboardPlayerName", "Arsonist_TTTScoreboardPlayerName", function(ply, cli, text)
    if GetRoundState() < ROUND_ACTIVE then return end

    local state = ply:GetNWInt("TTTArsonistDouseStage", ARSONIST_UNDOUSED)
    if state ~= ARSONIST_DOUSED then return end

    local T = LANG.GetTranslation
    return text .. " (" .. T("arsdouse_doused") .. ")"
end)

ROLE_IS_SCOREBOARD_INFO_OVERRIDDEN[ROLE_ARSONIST] = function(ply, target)
    if not ply:IsArsonist() then return end
    if not IsPlayer(target) then return end

    local state = target:GetNWInt("TTTArsonistDouseStage", ARSONIST_UNDOUSED)
    if state ~= ARSONIST_DOUSED then return end

    ------ name, role
    return true, false
end

-------------
-- SCORING --
-------------

-- Register the scoring events for the arsonist
hook.Add("Initialize", "Arsonist_Scoring_Initialize", function()
    local arsonist_icon = Material("icon16/asterisk_orange.png")
    local Event = CLSCORE.DeclareEventDisplay
    local PT = LANG.GetParamTranslation

    Event(EVENT_ARSONISTIGNITED, {
        text = function(e)
            return PT("ev_arsonignite", {arsonist = ROLE_STRINGS[ROLE_ARSONIST]})
        end,
        icon = function(e)
            return arsonist_icon, "Ignited"
        end})
end)

net.Receive("TTT_ArsonistIgnited", function(len)
    CLSCORE:AddEvent({
        id = EVENT_ARSONISTIGNITED
    })
end)

----------------
-- WIN CHECKS --
----------------

hook.Add("TTTScoringWinTitle", "Arsonist_TTTScoringWinTitle", function(wintype, wintitles, title, secondary_win_role)
    if wintype == WIN_ARSONIST then
        return { txt = "hilite_win_role_singular", params = { role = string.upper(ROLE_STRINGS[ROLE_ARSONIST]) }, c = ROLE_COLORS[ROLE_ARSONIST] }
    end
end)

------------
-- EVENTS --
------------

hook.Add("TTTEventFinishText", "Arsonist_TTTEventFinishText", function(e)
    if e.win == WIN_ARSONIST then
        return LANG.GetParamTranslation("ev_win_arsonist", { role = string.lower(ROLE_STRINGS[ROLE_ARSONIST]) })
    end
end)

hook.Add("TTTEventFinishIconText", "Arsonist_TTTEventFinishIconText", function(e, win_string, role_string)
    if e.win == WIN_ARSONIST then
        return win_string, ROLE_STRINGS[ROLE_ARSONIST]
    end
end)

-----------------
-- DOUSING HUD --
-----------------

hook.Add("HUDPaint", "Arsonist_HUDPaint", function()
    if not client then
        client = LocalPlayer()
    end

    if not IsValid(client) or client:IsSpec() or GetRoundState() ~= ROUND_ACTIVE then return end
    if not client:IsArsonist() then return end

    local target_sid64 = client:GetNWString("TTTArsonistDouseTarget", "")
    if not target_sid64 or #target_sid64 == 0 then return end

    local target = player.GetBySteamID64(target_sid64)
    if not IsPlayer(target) then return end

    local state = target:GetNWInt("TTTArsonistDouseStage", ARSONIST_UNDOUSED)
    if state == ARSONIST_UNDOUSED then return end

    local douse_time = GetGlobalInt("ttt_arsonist_douse_time", 8)
    local end_time = client:GetNWFloat("TTTArsonistDouseStartTime", -1) + douse_time

    local x = ScrW() / 2.0
    local y = ScrH() / 2.0

    y = y + (y / 3)

    local w = 300
    local T = LANG.GetTranslation

    if state == ARSONIST_DOUSING_LOST then
        local color = Color(200 + math.sin(CurTime() * 32) * 50, 0, 0, 155)
        CRHUD:PaintProgressBar(x, y, w, color, T("arsdouse_failed"), 1)
    elseif state >= ARSONIST_DOUSING then
        if end_time < 0 then return end

        local text = T("arsdouse_dousing")
        local color = Color(0, 255, 0, 155)
        if state == ARSONIST_DOUSING_LOSING then
            color = Color(255, 255, 0, 155)
        end

        local progress = math.min(1, 1 - ((end_time - CurTime()) / douse_time))
        CRHUD:PaintProgressBar(x, y, w, color, text .. " " .. target:Nick(), progress)
    end
end)

hook.Add("TTTHUDInfoPaint", "Arsonist_TTTHUDInfoPaint", function(cli, label_left, label_top, active_labels)
    local hide_role = false
    if ConVarExists("ttt_hide_role") then
        hide_role = GetConVar("ttt_hide_role"):GetBool()
    end

    if hide_role then return end

    if cli:IsArsonist() and cli:GetNWBool("TTTArsonistDouseComplete", false) then
        surface.SetFont("TabLarge")
        surface.SetTextColor(255, 255, 255, 230)

        local text = LANG.GetTranslation("arsonist_hud")
        local _, h = surface.GetTextSize(text)

        -- Move this up based on how many other labels here are
        label_top = label_top + (20 * #active_labels)

        surface.SetTextPos(label_left, ScrH() - label_top - h)
        surface.DrawText(text)

        -- Track that the label was added so others can position accurately
        table.insert(active_labels, "arsonist")
    end
end)

--------------
-- TUTORIAL --
--------------

hook.Add("TTTTutorialRoleText", "Arsonist_TTTTutorialRoleText", function(role, titleLabel)
    if role == ROLE_ARSONIST then
        -- TODO
        return "Burn, baby, burn"
    end
end)