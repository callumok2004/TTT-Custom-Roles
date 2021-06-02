-- Game report

include("cl_awards.lua")

local table = table
local string = string
local vgui = vgui
local pairs = pairs

CLSCORE = {}
CLSCORE.Events = {}
CLSCORE.Scores = {}
CLSCORE.TraitorIDs = {}
CLSCORE.DetectiveIDs = {}
CLSCORE.JesterIDs = {}
CLSCORE.SwapperIDs = {}
CLSCORE.GlitchIDs = {}
CLSCORE.PhantomIDs = {}
CLSCORE.HypnotistIDs = {}
CLSCORE.RevengerIDs = {}
CLSCORE.DrunkIDs = {}
CLSCORE.ClownIDs = {}
CLSCORE.DeputyIDs = {}
CLSCORE.ImpersonatorIDs = {}
CLSCORE.BeggarIDs = {}
CLSCORE.OldManIDs = {}
CLSCORE.Players = {}
CLSCORE.StartTime = 0
CLSCORE.Panel = nil

CLSCORE.EventDisplay = {}

include("scoring_shd.lua")

local skull_icon = Material("HUD/killicons/default")

surface.CreateFont("WinHuge", {
    font = "Trebuchet24",
    size = 72,
    weight = 1000,
    shadow = true,
    extended = true
})

surface.CreateFont("WinSmall", {
    font = "Trebuchet24",
    size = 32,
    weight = 1000,
    shadow = true,
    extended = true
})

surface.CreateFont("ScoreNicks", {
    font = "Trebuchet24",
    size = 32,
    weight = 100
})

local spawnedPlayers = {}

net.Receive("TTT_SpawnedPlayers", function(len)
    local ply = net.ReadString()
    table.insert(spawnedPlayers, ply)
end)

net.Receive("TTT_ResetScoreboard", function(len)
    spawnedPlayers = {}
end)

-- so much text here I'm using shorter names than usual
local T = LANG.GetTranslation
local PT = LANG.GetParamTranslation

function CLSCORE:GetDisplay(key, event)
    local displayfns = self.EventDisplay[event.id]
    if not displayfns then return end
    local keyfn = displayfns[key]
    if not keyfn then return end

    return keyfn(event)
end

function CLSCORE:TextForEvent(e)
    return self:GetDisplay("text", e)
end

function CLSCORE:IconForEvent(e)
    return self:GetDisplay("icon", e)
end

function CLSCORE:TimeForEvent(e)
    local t = e.t - self.StartTime
    if t >= 0 then
        return util.SimpleTime(t, "%02i:%02i")
    else
        return "     "
    end
end

-- Tell CLSCORE how to display an event. See cl_scoring_events for examples.
-- Pass an empty table to keep an event from showing up.
function CLSCORE.DeclareEventDisplay(event_id, event_fns)
    -- basic input vetting, can't check returned value types because the
    -- functions may be impure
    if not tonumber(event_id) then
        error("Event ??? display: invalid event id", 2)
    end
    if not istable(event_fns) then
        error(string.format("Event %d display: no display functions found.", event_id), 2)
    end
    if not event_fns.text then
        error(string.format("Event %d display: no text display function found.", event_id), 2)
    end
    if not event_fns.icon then
        error(string.format("Event %d display: no icon and tooltip display function found.", event_id), 2)
    end

    CLSCORE.EventDisplay[event_id] = event_fns
end

local wintitle = {
    [WIN_INNOCENT] = { txt = "hilite_win_innocent", c = COLOR_INNOCENT },
    [WIN_TRAITOR] = { txt = "hilite_win_traitors", c = COLOR_TRAITOR },
    [WIN_JESTER] = { txt = "hilite_win_jester", c = COLOR_JESTER },
    [WIN_CLOWN] = { txt = "hilite_win_clown", c = COLOR_JESTER }
}
local old_man_wins = false
net.Receive("TTT_UpdateOldManWins", function() old_man_wins = net.ReadBool() end)

local old_man_won_last_round = false
function CLSCORE:ShowPanel()
    if IsValid(self.Panel) then
        self:ClearPanel()
    end

    local margin = 15

    local dpanel = vgui.Create("DFrame")
    local w, h = 700, 502
    dpanel:SetSize(w, h)
    dpanel:Center()
    dpanel:SetTitle("Round Report")
    dpanel:SetVisible(true)
    dpanel:ShowCloseButton(true)
    dpanel:SetMouseInputEnabled(true)
    dpanel:SetKeyboardInputEnabled(true)
    dpanel.OnKeyCodePressed = util.BasicKeyHandler

    function dpanel:Think()
        self:MoveToFront()
    end

    -- keep it around so we can reopen easily
    dpanel:SetDeleteOnClose(false)
    self.Panel = dpanel

    local bg = vgui.Create("ColoredBox", dpanel)
    bg:SetColor(Color(97, 100, 102, 255))
    bg:SetSize(w - 4, h - 26)
    bg:SetPos(2, 24)

    local title = wintitle[WIN_INNOCENT]
    for i = #self.Events, 1, -1 do
        local e = self.Events[i]
        if e.id == EVENT_FINISH then
            local wintype = e.win
            if wintype == WIN_TIMELIMIT then wintype = WIN_INNOCENT end
            title = wintitle[wintype]
            break
        end
    end

    local winlbl = vgui.Create("DLabel", dpanel)
    winlbl:SetFont("WinHuge")
    winlbl:SetText(T(title.txt))
    winlbl:SetTextColor(COLOR_WHITE)
    winlbl:SizeToContents()
    local xwin = (w - winlbl:GetWide()) / 2
    local ywin = 37
    winlbl:SetPos(xwin, ywin)

    old_man_won_last_round = old_man_wins
    local exwinlbl = vgui.Create("DLabel", dpanel)
    if old_man_won_last_round then
        exwinlbl:SetFont("WinSmall")
        exwinlbl:SetText(T("hilite_win_old_man"))
        exwinlbl:SetTextColor(COLOR_WHITE)
        exwinlbl:SizeToContents()
        local xexwin = (w - exwinlbl:GetWide()) / 2
        local yexwin = 83
        exwinlbl:SetPos(xexwin, yexwin)
    else
        exwinlbl:SetText("")
    end

    bg.PaintOver = function()
        draw.RoundedBox(8, 8, 8, 680, winlbl:GetTall() + 10, title.c)
        if old_man_won_last_round then draw.RoundedBoxEx(8, 158, 63, 380, 28, COLOR_INDEPENDENT, true, true, false, false) end
        draw.RoundedBox(0, 8, ywin - 19 + winlbl:GetTall() + 8, 336, 329, Color(164, 164, 164, 255))
        draw.RoundedBox(0, 352, ywin - 19 + winlbl:GetTall() + 8, 336, 329, Color(164, 164, 164, 255))
        draw.RoundedBox(0, 8, ywin - 19 + winlbl:GetTall() + 345, 680, 32, Color(164, 164, 164, 255))
        for i = ywin - 19 + winlbl:GetTall() + 40, ywin - 19 + winlbl:GetTall() + 304, 33 do
            draw.RoundedBox(0, 8, i, 336, 1, Color(97, 100, 102, 255))
            draw.RoundedBox(0, 352, i, 336, 1, Color(97, 100, 102, 255))
        end
    end

    if old_man_wins then winlbl:SetPos(xwin, ywin - 15) end

    local scores = self.Scores
    local nicks = self.Players
    local countI = 0
    local countT = 0

    for id, s in pairs(scores) do
        if id ~= -1 then
            local foundPlayer = false
            for _, v in pairs(spawnedPlayers) do
                if v == nicks[id] then
                    foundPlayer = true
                    break
                end
            end

            if foundPlayer then
                -- The first bot's ID is 90071996842377216 whhich translates to "STEAM_0:0:0", an 11-character string
                -- A player's Steam ID cannot be that short, so if it is this must be a bot
                local isBot = string.len(util.SteamIDFrom64(id)) == 11
                local ply = nil
                -- Bots cannot be retrieved by SteamID on the client so search by name instead
                if isBot then
                    for _, p in pairs(player.GetAll()) do
                        if p:Nick() == nicks[id] then
                            ply = p
                            break
                        end
                    end
                else
                    ply = player.GetBySteamID64(id)
                end

                -- Backup in case people disconnect and we cant check their role at the end of the round
                local startingRole = ROLE_STRINGS_SHORT[ROLE_INNOCENT]
                if s.was_traitor then
                    startingRole = ROLE_STRINGS_SHORT[ROLE_TRAITOR]
                elseif s.was_detective then
                    startingRole = ROLE_STRINGS_SHORT[ROLE_DETECTIVE]
                elseif s.was_jester then
                    startingRole = ROLE_STRINGS_SHORT[ROLE_JESTER]
                elseif s.was_swapper then
                    startingRole = ROLE_STRINGS_SHORT[ROLE_SWAPPER]
                elseif s.was_glitch then
                    startingRole = ROLE_STRINGS_SHORT[ROLE_GLITCH]
                elseif s.was_phantom then
                    startingRole = ROLE_STRINGS_SHORT[ROLE_PHANTOM]
                elseif s.was_hypnotist then
                    startingRole = ROLE_STRINGS_SHORT[ROLE_HYPNOTIST]
                elseif s.was_revenger then
                    startingRole = ROLE_STRINGS_SHORT[ROLE_REVENGER]
                elseif s.was_drunk then
                    startingRole = ROLE_STRINGS_SHORT[ROLE_DRUNK]
                elseif s.was_clown then
                    startingRole = ROLE_STRINGS_SHORT[ROLE_CLOWN]
                elseif s.was_deputy then
                    startingRole = ROLE_STRINGS_SHORT[ROLE_DEPUTY]
                elseif s.was_impersonator then
                    startingRole = ROLE_STRINGS_SHORT[ROLE_IMPERSONATOR]
                elseif s.was_beggar then
                    startingRole = ROLE_STRINGS_SHORT[ROLE_BEGGAR]
                elseif s.was_old_man then
                    startingRole = ROLE_STRINGS_SHORT[ROLE_OLDMAN]
                end

                local hasDisconnected = false

                local finalRole = ROLE_STRINGS_SHORT[ROLE_INNOCENT]

                local swappedWith = ""
                local jesterKiller = ""

                local alive = false
                if IsValid(ply) then
                    alive = ply:Alive()
                    finalRole = ROLE_STRINGS_SHORT[ply:GetRole()]
                    if ply:IsInnocent() then
                        if ply:GetNWBool("WasDrunk", false) then
                            finalRole = ROLE_STRINGS_SHORT[ROLE_DRUNK] .. "_i"
                        elseif ply:GetNWBool("WasBeggar", false) then
                            finalRole = ROLE_STRINGS_SHORT[ROLE_BEGGAR] .. "_i"
                        end
                    elseif ply:IsTraitor() then
                        local wasHypnotised = ply:GetNWString("WasHypnotised", "")
                        if ply:GetNWBool("WasDrunk", false) then
                            finalRole = ROLE_STRINGS_SHORT[ROLE_DRUNK] .. "_t"
                        elseif ply:GetNWBool("WasBeggar", false) then
                            finalRole = ROLE_STRINGS_SHORT[ROLE_BEGGAR] .. "_t"
                        elseif wasHypnotised ~= "" then
                            finalRole = wasHypnotised .. "_t"
                        end
                    elseif ply:IsJester() then
                        jesterKiller = ply:GetNWString("JesterKiller", "")
                    elseif ply:IsSwapper() then
                        swappedWith = ply:GetNWString("SwappedWith", "")
                    end
                else
                    hasDisconnected = true
                end

                local roleFileName = ROLE_STRINGS_SHORT[ROLE_INNOCENT]
                if hasDisconnected then
                    roleFileName = startingRole
                else
                    roleFileName = finalRole
                end

                local roleIcon = vgui.Create("DImage", dpanel)
                roleIcon:SetSize(32, 32)
                roleIcon:SetImage("vgui/ttt/score_" .. roleFileName .. ".png")

                local nicklbl = vgui.Create("DLabel", dpanel)
                nicklbl:SetFont("ScoreNicks")
                nicklbl:SetText(nicks[id])
                nicklbl:SetTextColor(COLOR_WHITE)
                nicklbl:SizeToContents()

                if (string.sub(roleFileName, -2) == "_i"
                        or roleFileName == ROLE_STRINGS_SHORT[ROLE_INNOCENT]
                        or roleFileName == ROLE_STRINGS_SHORT[ROLE_DETECTIVE]
                        or roleFileName == ROLE_STRINGS_SHORT[ROLE_GLITCH]
                        or roleFileName == ROLE_STRINGS_SHORT[ROLE_PHANTOM]
                        or roleFileName == ROLE_STRINGS_SHORT[ROLE_REVENGER]
                        or roleFileName == ROLE_STRINGS_SHORT[ROLE_DEPUTY]) then
                    roleIcon:SetPos(10, 123 + 33 * countI)
                    nicklbl:SetPos(48, 121 + 33 * countI)

                    if hasDisconnected then
                        local disconIcon = vgui.Create("DImage", dpanel)
                        disconIcon:SetSize(32, 32)
                        disconIcon:SetPos(314, 123 + 33 * countI)
                        disconIcon:SetImage("vgui/ttt/score_disconicon.png")
                    elseif not alive then
                        local skullIcon = vgui.Create("DImage", dpanel)
                        skullIcon:SetSize(32, 32)
                        skullIcon:SetPos(314, 123 + 33 * countI)
                        skullIcon:SetImage("vgui/ttt/score_skullicon.png")
                    end

                    countI = countI + 1
                elseif (string.sub(roleFileName, -2) == "_t"
                        or roleFileName == ROLE_STRINGS_SHORT[ROLE_TRAITOR]
                        or roleFileName == ROLE_STRINGS_SHORT[ROLE_HYPNOTIST]
                        or roleFileName == ROLE_STRINGS_SHORT[ROLE_IMPERSONATOR]) then
                    roleIcon:SetPos(354, 123 + 33 * countT)
                    nicklbl:SetPos(392, 121 + 33 * countT)

                    if hasDisconnected then
                        local disconIcon = vgui.Create("DImage", dpanel)
                        disconIcon:SetSize(32, 32)
                        disconIcon:SetPos(658, 123 + 33 * countT)
                        disconIcon:SetImage("vgui/ttt/score_disconicon.png")
                    elseif not alive then
                        local skullIcon = vgui.Create("DImage", dpanel)
                        skullIcon:SetSize(32, 32)
                        skullIcon:SetPos(658, 123 + 33 * countT)
                        skullIcon:SetImage("vgui/ttt/score_skullicon.png")
                    end

                    countT = countT + 1
                elseif (roleFileName == ROLE_STRINGS_SHORT[ROLE_JESTER]
                        or roleFileName == ROLE_STRINGS_SHORT[ROLE_SWAPPER]
                        or roleFileName == ROLE_STRINGS_SHORT[ROLE_DRUNK]
                        or roleFileName == ROLE_STRINGS_SHORT[ROLE_CLOWN]
                        or roleFileName == ROLE_STRINGS_SHORT[ROLE_BEGGAR]
                        or roleFileName == ROLE_STRINGS_SHORT[ROLE_OLDMAN]) then
                    roleIcon:SetPos(10, 460)
                    nicklbl:SetPos(48, 458)

                    if roleFileName == ROLE_STRINGS_SHORT[ROLE_JESTER] and jesterKiller ~= "" then
                        nicklbl:SetText(nicks[id] .. " (Killed by " .. jesterKiller .. ")")
                        nicklbl:SizeToContents()
                    elseif roleFileName == ROLE_STRINGS_SHORT[ROLE_SWAPPER] and swappedWith ~= "" then
                        nicklbl:SetText(nicks[id] .. " (Swapped with " .. swappedWith .. ")")
                        nicklbl:SizeToContents()
                    end

                    if hasDisconnected then
                        local disconIcon = vgui.Create("DImage", dpanel)
                        disconIcon:SetSize(32, 32)
                        disconIcon:SetPos(658, 460)
                        disconIcon:SetImage("vgui/ttt/score_disconicon.png")
                    elseif not alive then
                        local skullIcon = vgui.Create("DImage", dpanel)
                        skullIcon:SetSize(32, 32)
                        skullIcon:SetPos(658, 460)
                        skullIcon:SetImage("vgui/ttt/score_skullicon.png")
                    end
                end
            end
        end
    end

    dpanel:MakePopup()

    -- makepopup grabs keyboard, whereas we only need mouse
    dpanel:SetKeyboardInputEnabled(false)
end

function CLSCORE:ClearPanel()

    if IsValid(self.Panel) then
        -- move the mouse off any tooltips and then remove the panel next tick

        -- we need this hack as opposed to just calling Remove because gmod does
        -- not offer a means of killing the tooltip, and doesn't clean it up
        -- properly on Remove
        input.SetCursorPos(ScrW() / 2, ScrH() / 2)
        local pnl = self.Panel
        timer.Simple(0, function() if IsValid(pnl) then pnl:Remove() end end)
    end
end

function CLSCORE:SaveLog()
    local events = self.Events

    if events == nil or #events == 0 then
        chat.AddText(COLOR_WHITE, T("report_save_error"))
        return
    end

    local logdir = "ttt/logs"
    if not file.IsDir(logdir, "DATA") then
        file.CreateDir(logdir)
    end

    local logname = logdir .. "/ttt_events_" .. os.time() .. ".txt"
    local log = "Trouble in Terrorist Town - Round Events Log\n" .. string.rep("-", 50) .. "\n"

    log = log .. string.format("%s | %-25s | %s\n", " TIME", "TYPE", "WHAT HAPPENED") .. string.rep("-", 50) .. "\n"

    for i = 1, #events do
        local e = events[i]
        local etxt = self:TextForEvent(e)
        local etime = self:TimeForEvent(e)
        local _, etype = self:IconForEvent(e)
        if etxt then
            log = log .. string.format("%s | %-25s | %s\n", etime, etype, etxt)
        end
    end

    file.Write(logname, log)

    chat.AddText(COLOR_WHITE, T("report_save_result"), COLOR_GREEN, " /garrysmod/data/" .. logname)
end

function CLSCORE:Reset()
    self.Events = {}
    self.TraitorIDs = {}
    self.DetectiveIDs = {}
    self.JesterIDs = {}
    self.SwapperIDs = {}
    self.GlitchIDs = {}
    self.PhantomIDs = {}
    self.HypnotistIDs = {}
    self.RevengerIDs = {}
    self.DrunkIDs = {}
    self.ClownIDs = {}
    self.DeputyIDs = {}
    self.ImpersonatorIDs = {}
    self.BeggarIDs = {}
    self.OldManIDs = {}
    self.Scores = {}
    self.Players = {}
    self.RoundStarted = 0

    self:ClearPanel()
end

function CLSCORE:Init(events)
    -- Get start time, traitors, detectives, scores, and nicks
    local starttime = 0
    local traitors, detectives, jesters, swappers, glitches, phantoms, hypnotists, revengers, drunks, clowns, deputies, impersonators, beggars, oldmen
    local scores, nicks = {}, {}

    local game, selected, spawn = false, false, false
    for i = 1, #events do
        local e = events[i]
        if e.id == EVENT_GAME then
            if e.state == ROUND_ACTIVE then
                starttime = e.t

                if selected and spawn then
                    break
                end

                game = true
            end
        elseif e.id == EVENT_SELECTED then
            traitors = e.traitor_ids
            detectives = e.detective_ids
            jesters = e.jester_ids
            swappers = e.swapper_ids
            glitches = e.glitch_ids
            phantoms = e.phantom_ids
            hypnotists = e.hypnotist_ids
            revengers = e.revenger_ids
            drunks = e.drunk_ids
            clowns = e.clown_ids
            deputies = e.deputy_ids
            impersonators = e.impersonator_ids
            beggars = e.beggar_ids
            oldmen = e.old_man_ids

            if game and spawn then
                break
            end

            selected = true
        elseif e.id == EVENT_SPAWN then
            scores[e.sid64] = ScoreInit()
            nicks[e.sid64] = e.ni

            if game and selected then
                break
            end

            spawn = true
        end
    end

    if traitors == nil then traitors = {} end
    if detectives == nil then detectives = {} end

    scores = ScoreEventLog(events, scores, traitors, detectives, jesters, swappers, glitches, phantoms, hypnotists, revengers, drunks, clowns, deputies, impersonators, beggars, oldmen)

    self.Players = nicks
    self.Scores = scores
    self.TraitorIDs = traitors
    self.DetectiveIDs = detectives
    self.JesterIDs = jesters
    self.SwapperIDs = swappers
    self.GlitchIDs = glitches
    self.PhantomIDs = phantoms
    self.HypnotistIDs = hypnotists
    self.RevengerIDs = revengers
    self.DrunkIDs = drunks
    self.ClownIDs = clowns
    self.DeputyIDs = deputies
    self.ImpersonatorIDs = impersonators
    self.BeggarIDs = beggars
    self.OldManIDs = oldmen
    self.StartTime = starttime
    self.Events = events
end

function CLSCORE:ReportEvents(events)
    self:Reset()

    self:Init(events)
    self:ShowPanel()
end

function CLSCORE:Toggle()
    if IsValid(self.Panel) then
        self.Panel:ToggleVisible()
    end
end

local function SortEvents(a, b)
    return a.t < b.t
end

local buff = ""
net.Receive("TTT_ReportStream_Part", function()
    buff = buff .. net.ReadData(CLSCORE.MaxStreamLength)
end)

net.Receive("TTT_ReportStream", function()
    local events = util.Decompress(buff .. net.ReadData(net.ReadUInt(16)))
    buff = ""

    if events == "" then
        ErrorNoHalt("Round report decompression failed!\n")
    end

    events = util.JSONToTable(events)
    if events == nil then
        ErrorNoHalt("Round report decoding failed!\n")
    end

    table.sort(events, SortEvents)
    CLSCORE:ReportEvents(events)
end)

concommand.Add("ttt_save_events", function()
    CLSCORE:SaveLog()
end)