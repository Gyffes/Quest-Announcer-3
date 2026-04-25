-- Laden erforderlicher Bibliotheken und Lokalisierung
QuestAnnounce = CreateFrame("Frame")
QuestAnnounce.events = {}
QuestAnnounce.questCache = {}
QuestAnnounce.objectiveCache = {}
QuestAnnounce.lastMessage = nil
QuestAnnounce.lastManualTurnInIntent = nil
QuestAnnounce.manualTurnInHooksInstalled = false

local L = QuestAnnounce_L[GetLocale()] or QuestAnnounce_L["enUS"]

-- ---------------------------------------------------------
-- QuestLog-API-Kompatibilität (Retail + Classic/TBC/Wrath)
-- ---------------------------------------------------------
-- DE: Manche Clients (z. B. TBC 2.5.5) haben kein C_QuestLog.
-- EN: Some clients (e.g. TBC 2.5.5) do not provide C_QuestLog.
C_QuestLog = C_QuestLog or {}

local function GetQuestIDFromLink(link)
    if type(link) ~= "string" then
        return nil
    end
    return tonumber(link:match("quest:(%d+)"))
end

local function LegacyGetQuestLogIndexByQuestID(questID)
    if not questID or not GetNumQuestLogEntries or not GetQuestLogTitle then
        return nil
    end

    local numEntries = GetNumQuestLogEntries() or 0
    for i = 1, numEntries do
        local title, _, _, isHeader = GetQuestLogTitle(i)
        if not isHeader and title then
            local link = GetQuestLink and GetQuestLink(i) or nil
            if GetQuestIDFromLink(link) == questID then
                return i
            end
        end
    end
end

if not C_QuestLog.GetNumQuestLogEntries and GetNumQuestLogEntries then
    C_QuestLog.GetNumQuestLogEntries = function()
        return GetNumQuestLogEntries() or 0
    end
end

if not C_QuestLog.GetInfo and GetQuestLogTitle then
    C_QuestLog.GetInfo = function(index)
        if not index then
            return nil
        end

        local title, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID = GetQuestLogTitle(index)
        local link = GetQuestLink and GetQuestLink(index) or nil
        questID = questID or GetQuestIDFromLink(link)

        return {
            title = title,
            level = level,
            suggestedGroup = suggestedGroup,
            isHeader = isHeader and true or false,
            isCollapsed = isCollapsed and true or false,
            isComplete = isComplete and true or false,
            frequency = frequency,
            questID = questID,
            questLogIndex = index,
        }
    end
end

if not C_QuestLog.GetQuestObjectives and GetNumQuestLeaderBoards and GetQuestLogLeaderBoard then
    C_QuestLog.GetQuestObjectives = function(questID)
        local index = LegacyGetQuestLogIndexByQuestID(questID)
        if not index then
            return {}
        end

        local objectives = {}
        local numObjectives = GetNumQuestLeaderBoards(index) or 0
        for j = 1, numObjectives do
            local text, objectiveType, finished = GetQuestLogLeaderBoard(j, index)
            local fulfilled, required = text and text:match("(%d+)%s*/%s*(%d+)")
            table.insert(objectives, {
                text = text,
                type = objectiveType,
                finished = finished and true or false,
                numFulfilled = tonumber(fulfilled),
                numRequired = tonumber(required),
            })
        end
        return objectives
    end
end

if not C_QuestLog.GetQuestLink and GetQuestLink then
    C_QuestLog.GetQuestLink = function(questID)
        local index = LegacyGetQuestLogIndexByQuestID(questID)
        if index then
            return GetQuestLink(index)
        end
    end
end

if not C_QuestLog.SetSelectedQuest and SelectQuestLogEntry then
    C_QuestLog.SetSelectedQuest = function(questID)
        local index = LegacyGetQuestLogIndexByQuestID(questID)
        if index then
            SelectQuestLogEntry(index)
        end
    end
end

if not C_QuestLog.IsComplete then
    C_QuestLog.IsComplete = function(questIDOrIndex)
        local numeric = tonumber(questIDOrIndex)
        if not numeric then
            return false
        end

        local questID = numeric
        local index = nil
        if GetQuestLogTitle then
            local title = GetQuestLogTitle(numeric)
            if title then
                index = numeric
                local link = GetQuestLink and GetQuestLink(index) or nil
                questID = GetQuestIDFromLink(link) or questID
            else
                index = LegacyGetQuestLogIndexByQuestID(questID)
            end
        end

        if IsQuestFlaggedCompleted then
            return IsQuestFlaggedCompleted(questID) and true or false
        end

        index = index or LegacyGetQuestLogIndexByQuestID(questID) or numeric
        if GetQuestLogTitle and index then
            local _, _, _, _, _, isComplete = GetQuestLogTitle(index)
            return isComplete and true or false
        end

        return false
    end
end

-- Standardkonfigurationen für einen neuen Benutzer
local defaults = {
    profile = {
        settings = {
            enable = true,          -- Addon aktiviert
            showMinimapButton = true, -- DE: Minimap-Button sichtbar / EN: Minimap button visible
            selfMessages = true,    -- DE: Eigene Addon-Meldungen anzeigen / EN: Show addon self messages
            soloMuteSelfMessagesOnly = false, -- DE: Eigene Meldungen nur solo stummschalten / EN: Mute self messages only while solo
            showLocalProgressMessages = true, -- DE: Lokale Fortschrittstexte anzeigen / EN: Show local progress texts
            every = 1,              -- Benachrichtigungsfrequenz
            sound = true,           -- Soundbenachrichtigungen aktiviert
			progressSound = 8959,     -- Standard: UI Quest Progress
			completeSound = 6197,    -- Standard: Quest Complete
            acceptSound = 6192,      -- DE: Standard Quest angenommen / EN: Default quest accepted
            turnInSound = 6199,      -- DE: Standard Quest abgegeben / EN: Default quest turn-in
            soundChannel = "Master", -- DE: Standard-Audio-Kanal / EN: Default audio channel
            enableProgressSound = true, -- DE: Fortschrittssound aktiv / EN: Progress sound enabled
            enableCompleteSound = true, -- DE: Abschlusssound aktiv / EN: Completion sound enabled
            enableAcceptSound = true,   -- DE: Quest-angenommen-Sound aktiv / EN: Quest-accepted sound enabled
            enableTurnInSound = true,   -- DE: Quest-abgegeben-Sound aktiv / EN: Quest-turn-in sound enabled
            playTurnInOnAutoTurnIn = false, -- DE: Turn-In-Sound auch ohne manuellen Questdialog / EN: Play turn-in sound even without manual quest dialog
            debug = false,          -- Debug-Modus deaktiviert
			linkQuest = true,		-- Quest Link
            paused = false,         -- Temporäre Pause
        },
        announceTo = {
            chatFrame = true,      -- Benachrichtigungen im Chat-Fenster
            raidWarningFrame = false,  -- Benachrichtigungen im Raid-Warnungs-Fenster
            uiErrorsFrame = false,  -- Benachrichtigungen im UI-Fehler-Fenster
        },
        announceIn = {
            say = false,           -- Sprechen-Channel
            party = true,          -- Gruppen-Channel
            guild = false,         -- Gilden-Channel
            officer = false,       -- Offizier-Channel
            whisper = false,       -- Flüstern
            whisperWho = nil,      -- Ziel des Flüsterns
            channel = false,       -- Benutzerdefinierter Channel
            channelName = nil,     -- Name des benutzerdefinierten Channels
			instance = false,	   -- Instance Channel
			focus = false		   -- an Focus Schreiben	
        },
		tooltip = {
            font = "Friz Quadrata TT",
            fontSize = 12,
            fontColor = {0.11, 1, 0.3},
            bgColor = {0, 0, 0, 0.8}, -- Hintergrundfarbe mit Alpha
            borderColor = {0, 0, 0, 0.8}, -- Rahmenfarbe
        },
        questTypeFilters = {
            normal = true,      -- DE: Normale Quests aktiv / EN: Normal quests enabled
            world = true,       -- DE: Weltquests aktiv / EN: World quests enabled
            trivial = true,     -- DE: Triviale Quests aktiv / EN: Trivial quests enabled
            campaign = true,    -- DE: Kampagnen-Quests aktiv / EN: Campaign quests enabled
            story = true,       -- DE: Story-Quests aktiv / EN: Story quests enabled
        },
    }
}
-- Chanel betreten
function QuestAnnounce:JoinChannel(channelName)
    local id, name = GetChannelName(channelName)
    if not id or id == 0 then
        JoinTemporaryChannel(channelName)
        QuestAnnounce:Print(L["Joined Channel: "] .. channelName)
    else
        QuestAnnounce:Print(L["Already on the Channel: "] .. channelName)
    end
end

-- Chanel verlassen 
function QuestAnnounce:LeaveChannel(channelName)
    local id, name = GetChannelName(channelName)
    if id and id > 0 then
        LeaveChannelByName(channelName)
        QuestAnnounce:Print(L["Exiting the Channel: "] .. channelName)
    end
end


-- Zeigt beim Deaktivieren eines benutzerdefinierten Kanals einen Bestätigungsdialog an
function QuestAnnounce:ToggleChannelLeave(enable, channelName)
    if not enable then
        local dialog = StaticPopup_Show("CONFIRM_LEAVE_CHANNEL", channelName)
        if dialog then
            dialog.data = channelName
        end
    end
end

-- Bestätigungsdialog zum Verlassen eines benutzerdefinierten Kanals
StaticPopupDialogs["CONFIRM_LEAVE_CHANNEL"] = {
    text = L["Leave channel confirmation"],
    button1 = L["Yes"],
    button2 = L["No"],
    OnAccept = function(_, channelName)
        LeaveChannelByName(channelName)
        QuestAnnounce:Print(L["Leaving Channel: "] .. channelName)
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

-- Führt einen rekursiven Merge von Standardwerten in eine vorhandene Tabelle durch.
-- Bereits vorhandene Werte bleiben erhalten.
local function DeepMergeDefaults(target, defaults)
    if type(target) ~= "table" then
        target = {}
    end

    for key, value in pairs(defaults) do
        if type(value) == "table" then
            if type(target[key]) ~= "table" then
                target[key] = {}
            end
            DeepMergeDefaults(target[key], value)
        elseif target[key] == nil then
            target[key] = value
        end
    end

    return target
end


--[[ Initialisierung des Addons ]]--
function QuestAnnounce:Initialize()
QuestAnnounceDB = QuestAnnounceDB or {} -- Gespeicherte Datenbank initialisieren

    if not QuestAnnounceDB.profile then
    QuestAnnounceDB.profile = {}
	end
    QuestAnnounceDB.profiles = QuestAnnounceDB.profiles or {}

	-- Fehlende Standardwerte rekursiv ergänzen, vorhandene Werte behalten
	DeepMergeDefaults(QuestAnnounceDB.profile, defaults.profile)

    self.db = QuestAnnounceDB
	
	self:BuildQuestCache()
	self:SetupOptions() 																-- Einrichten der Optionen
	self:InitializeLinkHandler()
	self:EnsureManualTurnInHooks()
	
	if self.InitializeMinimapButton then
		self:InitializeMinimapButton()
	end
	
	self:SendDebugMsg("Addon Enabled :: " .. tostring(self.db.profile.settings.enable))
    self:NotifySelf(L["QuestAnnounce activated!"], true)
end

QuestAnnounce:RegisterEvent("ADDON_LOADED")											-- Register Event Addon Laden
QuestAnnounce:RegisterEvent("UI_INFO_MESSAGE")										-- Register Event Ui Info Message
QuestAnnounce:RegisterEvent("QUEST_LOG_UPDATE")										-- Register Event Quest Log Update
QuestAnnounce:RegisterEvent("QUEST_ACCEPTED")                                         -- DE: Quest angenommen / EN: Quest accepted
QuestAnnounce:RegisterEvent("QUEST_TURNED_IN")                                        -- DE: Quest abgegeben / EN: Quest turned in

function QuestAnnounce:IsManualQuestTurnInContext()
    local visibleFrameReasons = {}

    local function IsFrameShown(frameName)
        local frame = _G[frameName]
        return frame and frame.IsShown and frame:IsShown()
    end

    local function AddVisibleReason(frameName, reason)
        if IsFrameShown(frameName) then
            table.insert(visibleFrameReasons, reason or frameName)
        end
    end

    AddVisibleReason("QuestFrame", "QuestFrame visible")
    AddVisibleReason("QuestGreetingFrame", "QuestGreetingFrame visible")
    AddVisibleReason("GossipFrame", "GossipFrame visible")

    if #visibleFrameReasons > 0 then
        return true, table.concat(visibleFrameReasons, ", ")
    end

    local hasNpcTarget = UnitExists and UnitExists("npc")
    if hasNpcTarget then
        local activeQuests = GetNumActiveQuests and (GetNumActiveQuests() or 0) or 0
        local availableQuests = GetNumAvailableQuests and (GetNumAvailableQuests() or 0) or 0
        if activeQuests > 0 or availableQuests > 0 then
            return true, string.format("npc exists with quest dialog entries (%d active / %d available)", activeQuests, availableQuests)
        end
        return true, "npc exists without visible quest dialog entries (fallback manual context)"
    end

    return false, "no visible quest dialog frame and UnitExists(\"npc\") is false"
end

function QuestAnnounce:GetCurrentQuestDialogQuestID()
    if GetQuestID then
        local questID = tonumber(GetQuestID())
        if questID and questID > 0 then
            return questID
        end
    end
    return nil
end

function QuestAnnounce:RecordManualTurnInIntent(source, questID)
    local intentQuestID = tonumber(questID) or self:GetCurrentQuestDialogQuestID()
    self.lastManualTurnInIntent = {
        time = GetTime and GetTime() or 0,
        questID = intentQuestID,
        source = source or "unknown",
    }
    self:SendDebugMsg("manual turn-in intent recorded :: source=" .. tostring(source) .. " :: questID=" .. tostring(intentQuestID))
end

function QuestAnnounce:IsRecentManualTurnInIntent(questID)
    local intent = self.lastManualTurnInIntent
    if not intent or not intent.time then
        return false, "no manual turn-in intent recorded"
    end

    local now = GetTime and GetTime() or 0
    local age = now - (intent.time or 0)
    if age < 0 or age > 4 then
        return false, string.format("manual intent too old (age=%.2fs)", age)
    end

    local turnedInQuestID = tonumber(questID)
    if turnedInQuestID then
        if not intent.questID then
            return false, "manual intent has no questID for turned-in quest " .. tostring(turnedInQuestID)
        end
        if intent.questID ~= turnedInQuestID then
            return false, "manual intent quest mismatch (intent=" .. tostring(intent.questID) .. ", turnedIn=" .. tostring(turnedInQuestID) .. ")"
        end
    end

    return true, "manual intent within " .. string.format("%.2f", age) .. "s via " .. tostring(intent.source)
end

function QuestAnnounce:EnsureManualTurnInHooks()
    if self.manualTurnInHooksInstalled then
        return
    end

    local installedAnyHook = false

    local function HookFunction(functionName, sourceName)
        if type(_G[functionName]) == "function" then
            hooksecurefunc(functionName, function(...)
                local qid = select(1, ...)
                QuestAnnounce:RecordManualTurnInIntent(sourceName or functionName, qid)
            end)
            installedAnyHook = true
        end
    end

    local function HookButton(buttonName, sourceName)
        local button = _G[buttonName]
        if button and button.HookScript then
            button:HookScript("OnClick", function()
                QuestAnnounce:RecordManualTurnInIntent(sourceName or buttonName)
            end)
            installedAnyHook = true
        end
    end

    -- DE: Explizite Abschluss-/Abgabe-Aktionen abfangen.
    -- EN: Capture explicit completion/turn-in actions.
    HookFunction("QuestFrameCompleteQuest", "QuestFrameCompleteQuest")
    HookFunction("QuestRewardCompleteButton_OnClick", "QuestRewardCompleteButton_OnClick")
    HookFunction("QuestFrameCompleteButton_OnClick", "QuestFrameCompleteButton_OnClick")

    HookButton("QuestFrameCompleteQuestButton", "QuestFrameCompleteQuestButton")
    HookButton("QuestFrameCompleteButton", "QuestFrameCompleteButton")
    HookButton("QuestFrameCompleteQuestButtonLeft", "QuestFrameCompleteQuestButtonLeft")
    HookButton("QuestRewardCompleteButton", "QuestRewardCompleteButton")

    if installedAnyHook then
        self.manualTurnInHooksInstalled = true
        self:SendDebugMsg("manual turn-in hooks installed")
    else
        self:SendDebugMsg("manual turn-in hooks not installed yet (UI elements unavailable)")
    end
end

QuestAnnounce:SetScript("OnEvent", function(self, event, arg1, arg2, arg3, arg4, arg5)
	-- Quest Log Update Event 
	if event == "QUEST_LOG_UPDATE" then
		self:BuildQuestCache()
		return
	end
    if event == "ADDON_LOADED" then
        if arg1 == "QuestAnnounce" then
            self:Initialize()
        end
        return
    end

    if event == "UI_INFO_MESSAGE" then
        self:UI_INFO_MESSAGE(event, arg1, arg2, arg3, arg4, arg5)
        return
    end
    if event == "QUEST_ACCEPTED" then
        self:PlayConfiguredSound("accept")
        return
    end
    if event == "QUEST_TURNED_IN" then
        self:EnsureManualTurnInHooks()
        local questID = tonumber(arg1)
        local manualContext, contextReason = self:IsManualQuestTurnInContext()
        local hasManualIntent, intentReason = self:IsRecentManualTurnInIntent(questID)
        local allowAutoTurnIn = self.db
            and self.db.profile
            and self.db.profile.settings
            and self.db.profile.settings.playTurnInOnAutoTurnIn

        local allowByManualIntent = hasManualIntent and true or false
        local allowByAutoSetting = allowAutoTurnIn and true or false
        local allowByContextFallback = manualContext and true or false

        if allowByManualIntent or allowByAutoSetting or allowByContextFallback then
            local decision = string.format(
                "turn-in sound allowed :: questID=%s :: byIntent=%s :: byAutoSetting=%s :: byContextFallback=%s :: context=%s :: intent=%s",
                tostring(questID),
                tostring(allowByManualIntent),
                tostring(allowByAutoSetting),
                tostring(allowByContextFallback),
                tostring(contextReason),
                tostring(intentReason)
            )
            self:SendDebugMsg(decision)
            self:PlayConfiguredSound("turnin")
        else
            local allowByManualIntent = hasManualIntent and true or false
            local allowByAutoSetting = allowAutoTurnIn and true or false
            local allowByContextFallback = manualContext and true or false
            self:SendDebugMsg(
                "suppressed turn-in sound :: questID="
                    .. tostring(questID)
                    .. " :: byIntent="
                    .. tostring(allowByManualIntent)
                    .. " :: byAutoSetting="
                    .. tostring(allowByAutoSetting)
                    .. " :: byContextFallback="
                    .. tostring(allowByContextFallback)
                    .. " :: context="
                    .. tostring(contextReason)
                    .. " :: intent="
                    .. tostring(intentReason)
            )
        end
        return
    end

end)

-- DE: Definierte Sound-Events und Priorität / EN: Defined sound events and priority.
QuestAnnounce.soundEventConfig = {
    progress = { idKey = "progressSound", enableKey = "enableProgressSound", defaultID = 8959, priority = 1 },
    complete = { idKey = "completeSound", enableKey = "enableCompleteSound", defaultID = 6197, priority = 2 },
    accept = { idKey = "acceptSound", enableKey = "enableAcceptSound", defaultID = 6192, priority = 3 },
    turnin = { idKey = "turnInSound", enableKey = "enableTurnInSound", defaultID = 6199, priority = 4 },
}

-- DE: Vereinheitlicht Soundkanäle aus Einstellungen/Localizations auf WoW-API-Werte.
-- EN: Normalizes setting/localized sound channels to WoW API channel values.
function QuestAnnounce:GetNormalizedSoundChannel(rawChannel)
    local channelMap = {
        ["Master"] = "Master",
        ["SFX"] = "SFX",
        ["Effects"] = "SFX",
        ["Effekte"] = "SFX",
        ["Ambience"] = "Ambience",
        ["Umgebung"] = "Ambience",
        ["Dialog"] = "Dialog",
        ["Dialoge"] = "Dialog",
        ["Music"] = "Music",
        ["Musik"] = "Music",
    }
    return channelMap[tostring(rawChannel or "Master")] or "Master"
end

-- DE: Bestimmte IDs (z. B. 8959/Raidwarnung) ignorieren Kanalwahl und sollen außerhalb von Master unterdrückt werden.
-- EN: Certain IDs (e.g. 8959/raid warning) ignore channel routing and should be suppressed outside Master.
function QuestAnnounce:ShouldSuppressSoundByChannel(soundID, channel)
    local id = tonumber(soundID)
    if not id then
        return false
    end

    -- DE: 8959 wird in manchen Clients wie Master behandelt.
    -- EN: 8959 is treated like Master on some clients.
    -- DE/EN: Nur unterdrücken, wenn der gewünschte Zielkanal effektiv stumm ist.
    if id == 8959 and channel ~= "Master" then
        local cvarByChannel = {
            Master = "Sound_MasterVolume",
            SFX = "Sound_SFXVolume",
            Ambience = "Sound_AmbienceVolume",
            Dialog = "Sound_DialogVolume",
            Music = "Sound_MusicVolume",
        }
        local cvar = cvarByChannel[channel]
        if cvar then
            local volume = tonumber(GetCVar(cvar) or "1") or 1
            if volume <= 0 then
                return true
            end
        end
    end

    return false
end

-- DE: Manche IDs (z. B. 8959) sind intern an Master gebunden.
-- EN: Some IDs (e.g. 8959) are internally tied to Master.
function QuestAnnounce:GetPlaybackChannelForSound(soundID, channel)
    local id = tonumber(soundID)
    if id == 8959 and channel ~= "Master" then
        return "Master"
    end
    return channel
end

-- DE: Direkter Sound-Test ohne Queue/Priorität, damit der Testbutton den gewählten Kanal sofort nutzt.
-- EN: Direct sound preview without queue/priority so the test button immediately uses the selected channel.
function QuestAnnounce:PlayTestSound(eventKey, explicitSoundID)
    local settings = self.db and self.db.profile and self.db.profile.settings
    local config = self.soundEventConfig and self.soundEventConfig[eventKey]
    if not settings or not config then
        return
    end

    local soundID = tonumber(explicitSoundID) or tonumber(settings[config.idKey]) or config.defaultID
    local channel = self:GetNormalizedSoundChannel(settings.soundChannel)
    settings.soundChannel = channel

    if self:ShouldSuppressSoundByChannel(soundID, channel) then
        self:SendDebugMsg("Test sound suppressed by channel rule :: " .. tostring(soundID) .. " @ " .. tostring(channel))
        return
    end

    local playbackChannel = self:GetPlaybackChannelForSound(soundID, channel)
    local willPlay = PlaySound(soundID, playbackChannel)
    if not willPlay then
        self:SendDebugMsg("Test sound failed :: " .. tostring(eventKey) .. " :: " .. tostring(soundID) .. " @ " .. tostring(playbackChannel))
    else
        self:SendDebugMsg("Test sound played :: " .. tostring(eventKey) .. " :: " .. tostring(soundID) .. " @ req:" .. tostring(channel) .. " play:" .. tostring(playbackChannel))
    end
end

-- DE: Spielt Sounds geordnet ab (ein aktiver Sound, optional eine wartende Anforderung).
-- EN: Plays sounds in an orderly way (one active sound, optional one queued request).
function QuestAnnounce:PlayConfiguredSound(eventKey)
    local settings = self.db and self.db.profile and self.db.profile.settings
    if not settings or not settings.sound then
        return
    end

    local config = self.soundEventConfig and self.soundEventConfig[eventKey]
    if not config then
        return
    end

    if settings[config.enableKey] == false then
        self:SendDebugMsg("Sound disabled for event :: " .. tostring(eventKey))
        return
    end

    local soundID = tonumber(settings[config.idKey]) or config.defaultID
    local channel = self:GetNormalizedSoundChannel(settings.soundChannel)
    settings.soundChannel = channel

    if self:ShouldSuppressSoundByChannel(soundID, channel) then
        self:SendDebugMsg("Sound suppressed by channel rule :: " .. tostring(eventKey) .. " :: " .. tostring(soundID) .. " @ " .. tostring(channel))
        return
    end
    local now = GetTime()
    local lockSeconds = 0.35

    self.soundState = self.soundState or { activeUntil = 0, activePriority = 0, activeHandle = nil, pending = nil }
    local state = self.soundState

    local function PlayNow()
        local playbackChannel = self:GetPlaybackChannelForSound(soundID, channel)
        local willPlay, handle = PlaySound(soundID, playbackChannel)
        if not willPlay then
            self:SendDebugMsg("Sound failed (no fallback) :: " .. tostring(soundID) .. " @ " .. tostring(playbackChannel))
            return
        end

        state.activeHandle = handle
        state.activePriority = config.priority or 0
        state.activeUntil = GetTime() + lockSeconds
        self:SendDebugMsg("Play sound :: " .. tostring(eventKey) .. " :: " .. tostring(soundID) .. " @ req:" .. tostring(channel) .. " play:" .. tostring(playbackChannel))
    end

    if now < (state.activeUntil or 0) then
        if (config.priority or 0) >= (state.activePriority or 0) then
            if state.activeHandle then
                StopSound(state.activeHandle, 0)
            end
            PlayNow()
        else
            state.pending = {
                eventKey = eventKey,
                priority = config.priority or 0,
                queuedAt = now,
            }
            if not state.pendingTimerActive then
                state.pendingTimerActive = true
                C_Timer.After(lockSeconds, function()
                    if not QuestAnnounce or not QuestAnnounce.soundState then
                        return
                    end
                    local pendingState = QuestAnnounce.soundState
                    pendingState.pendingTimerActive = false
                    local pending = pendingState.pending
                    pendingState.pending = nil
                    if pending and pending.eventKey then
                        QuestAnnounce:PlayConfiguredSound(pending.eventKey)
                    end
                end)
            end
            self:SendDebugMsg("Sound queued :: " .. tostring(eventKey))
        end
        return
    end

    PlayNow()
end

-- ==============================
-- Quest- und Objective-Cache Builder (ROBUST)
-- ==============================
function QuestAnnounce:BuildQuestCache()
    wipe(self.questCache)
    wipe(self.objectiveCache)

    local questCount = 0
    local objectiveCount = 0
    local numEntries = C_QuestLog.GetNumQuestLogEntries()

    for i = 1, numEntries do
        local info = C_QuestLog.GetInfo(i)

        if info and info.title and info.questID and not info.isHeader then
            local normalizedTitle = self:NormalizeQuestTitle(info.title)

            self.questCache[normalizedTitle] = {
                questID = info.questID,
                level = info.level,
                index = i,
                title = info.title,
            }
            questCount = questCount + 1

            local objectives = C_QuestLog.GetQuestObjectives(info.questID)
            if objectives then
                for _, objective in ipairs(objectives) do
                    if objective and objective.text and objective.text ~= "" then
                        local normalizedObjective = self:NormalizeQuestTitle(objective.text)

                        self.objectiveCache[normalizedObjective] = {
                            questID = info.questID,
                            level = info.level,
                            index = i,
                            title = info.title,
                            objectiveText = objective.text,
                        }
                        objectiveCount = objectiveCount + 1
                    end
                end
            end
        end
    end

    self:SendDebugMsg("QuestCache rebuilt. Quests: " .. tostring(questCount) .. " / Objectives: " .. tostring(objectiveCount))
end

-- Questtyp-Filter Defaults (defensiv, versionsfreundlich)
-- Quest type filter defaults (defensive, version-friendly)
local QUEST_TYPE_FILTER_DEFAULTS = {
    normal = true,
    world = true,
    trivial = true,
    campaign = true,
    story = true,
}

-- Liefert die Questtyp-Filter aus der DB und ergänzt fehlende Schlüssel mit Defaults.
-- Returns quest type filters from DB and backfills missing keys with defaults.
function QuestAnnounce:GetQuestTypeFilterSettings()
    if not self.db or not self.db.profile then
        return QUEST_TYPE_FILTER_DEFAULTS
    end

    local filters = self.db.profile.questTypeFilters
    if type(filters) ~= "table" then
        filters = {}
        self.db.profile.questTypeFilters = filters
    end

    for key, value in pairs(QUEST_TYPE_FILTER_DEFAULTS) do
        if filters[key] == nil then
            filters[key] = value
        end
    end

    return filters
end

-- Ermittelt zuverlässig unterscheidbare Questtypen auf Basis verfügbarer Blizzard-API-Felder.
-- Detects reliably distinguishable quest types based on available Blizzard API fields.
function QuestAnnounce:GetQuestTypeFlags(questID, logIndex)
    local flags = {
        world = false,
        trivial = false,
        campaign = false,
        story = false,
        normal = true,
    }

    local info
    if logIndex and C_QuestLog and C_QuestLog.GetInfo then
        info = C_QuestLog.GetInfo(logIndex)
    end

    if info then
        flags.world = info.isTask == true
        flags.campaign = info.isCampaign == true
        flags.story = info.isStory == true

        if type(info.isTrivial) == "boolean" then
            flags.trivial = info.isTrivial
        end
    end

    if not flags.trivial and questID and C_QuestLog and C_QuestLog.IsQuestTrivial then
        local isTrivial = C_QuestLog.IsQuestTrivial(questID)
        if type(isTrivial) == "boolean" then
            flags.trivial = isTrivial
        end
    end

    flags.normal = not (flags.world or flags.trivial or flags.campaign or flags.story)

    return flags
end

-- Prüft, ob ein Questtyp laut Nutzer-Filter angekündigt werden darf.
-- Checks whether a quest type is allowed by user filters.
function QuestAnnounce:IsQuestTypeAllowed(questID, logIndex)
    if not questID then
        return true
    end

    local filters = self:GetQuestTypeFilterSettings()
    local flags = self:GetQuestTypeFlags(questID, logIndex)

    if flags.world and not filters.world then return false, "world" end
    if flags.trivial and not filters.trivial then return false, "trivial" end
    if flags.campaign and not filters.campaign then return false, "campaign" end
    if flags.story and not filters.story then return false, "story" end
    if flags.normal and not filters.normal then return false, "normal" end

    return true
end

function QuestAnnounce:Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99QuestAnnounce|r: " .. msg)
end	

-- Prüft, ob ein Fortschrittsupdate anhand des "every"-Wertes gesendet werden soll.
-- Checks whether a progress update should be sent based on the "every" setting.
function QuestAnnounce:ShouldAnnounceProgressByEvery(currentAmount, requiredAmount)
    local settings = self.db and self.db.profile and self.db.profile.settings or nil
    local every = settings and tonumber(settings.every) or 1

    if not every then
        every = 1
    end

    every = math.max(0, math.floor(every))

    -- DE: 0 bedeutet nur Abschlussmeldungen.
    -- EN: 0 means completion-only announcements.
    if every == 0 then
        return false
    end

    -- DE: Ohne numerischen Fortschritt wird wie bisher angekündigt.
    -- EN: Without numeric progress, keep legacy behavior and announce.
    if currentAmount == nil then
        return true
    end

    if every <= 1 then
        return true
    end

    if requiredAmount and requiredAmount > 0 and currentAmount >= requiredAmount then
        return true
    end

    return currentAmount > 0 and (currentAmount % every == 0)
end

-- ==============================
-- Quest Link Helper Funktionen
-- ==============================

-- ==============================
-- Text-Normalisierung für Questtitel und Objectives
-- ==============================
function QuestAnnounce:NormalizeQuestTitle(title)
    if not title then
        return nil
    end

    title = tostring(title):lower()

    -- führende / nachgestellte Leerzeichen entfernen
    title = title:gsub("^%s*(.-)%s*$", "%1")

    -- mehrfache Leerzeichen vereinheitlichen
    title = title:gsub("%s+", " ")

    -- Objective-Zähler am Ende entfernen, z. B.:
    -- "Späher der Nordwacht getötet: 0/5"
    -- "Kaktusapfel 1/6"
    title = title:gsub("%s*:%s*[-%d]+%s*/%s*[-%d]+$", "")
    title = title:gsub("%s+[-%d]+%s*/%s*[-%d]+$", "")

    -- trailing Doppelpunkte / Leerzeichen entfernen
    title = title:gsub("%s*:%s*$", "")
    title = title:gsub("^%s*(.-)%s*$", "%1")

    return title
end

function QuestAnnounce:BuildLocalQuestAddonLink(questID, title)
    if not questID or not title or title == "" then
        return title or ""
    end

   -- einzigartiger Counter gegen WoW-Link-Cache
	self.linkCounter = (self.linkCounter or 0) + 1

	return string.format("|cffffff00|Haddon:QuestAnnounce:quest:%d:%d|h[%s]|h|r",
		questID,
		self.linkCounter,
		title
	)
end

function QuestAnnounce:GetOfficialQuestLink(questID, fallbackTitle)
    if not questID or questID == 0 then
        return fallbackTitle or ""
    end

    local questLink = C_QuestLog.GetQuestLink and C_QuestLog.GetQuestLink(questID) or GetQuestLink(questID)
    return questLink or fallbackTitle or ""
end

function QuestAnnounce:GetWowheadQuestURL(questID)
    if not questID or questID == 0 then
        return nil
    end

	-- Retail-/deDE-kompatibel genug; bei Bedarf später Region/Locale dynamisch machen
    return string.format("https://www.wowhead.com/quest=%d", questID)
end

-- ==============================
-- Quest im Questlog robust öffnen
-- ==============================
function QuestAnnounce:OpenQuestInLog(questID)
    if not questID or questID == 0 then
        return
    end

    -- DE: In CombatLockdown keine geschützten Map/Questlog-Toggles aufrufen.
    -- EN: Do not call protected map/quest log toggles during combat lockdown.
    if InCombatLockdown and InCombatLockdown() then
        self:NotifySelf(L["Cannot open settings in combat."], true)
        self:SendDebugMsg("OpenQuestInLog skipped in combat :: questID=" .. tostring(questID))
        return
    end

    -- Beste verfügbare Blizzard-Funktion zuerst benutzen
    if QuestMapFrame_OpenToQuestDetails then
        QuestMapFrame_OpenToQuestDetails(questID)
        return
    end

    -- Fallback
    if not QuestMapFrame or not QuestMapFrame:IsShown() then
        ToggleQuestLog()
    end

    -- Einen Tick später auswählen/anzeigen, damit das UI sicher da ist
    C_Timer.After(0, function()
        if C_QuestLog and C_QuestLog.SetSelectedQuest then
            C_QuestLog.SetSelectedQuest(questID)
        end

        if QuestMapFrame_SetFocusedQuest then
            QuestMapFrame_SetFocusedQuest(questID)
        end

        if QuestMapFrame_ShowQuestDetails then
            QuestMapFrame_ShowQuestDetails(questID)
        end
    end)
end

-- ==============================
-- Copy-Fenster für Wowhead-Links
-- ==============================
function QuestAnnounce:ShowCopyDialog(text, title)
    if not self.copyFrame then
        local frame = CreateFrame("Frame", "QuestAnnounceCopyFrame", UIParent, "BasicFrameTemplateWithInset")
        frame:SetSize(520, 140)
        frame:SetPoint("CENTER")
        frame:SetFrameStrata("DIALOG")
        frame:Hide()

        frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        frame.title:SetPoint("TOP", 0, -10)
        frame.title:SetText(L["QuestAnnounce Copy"])

        local editBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
        editBox:SetSize(460, 30)
        editBox:SetPoint("TOP", 0, -45)
        editBox:SetAutoFocus(true)
        editBox:SetFontObject("ChatFontNormal")
        editBox:SetScript("OnEscapePressed", function(self)
            self:ClearFocus()
            frame:Hide()
        end)
        editBox:SetScript("OnEditFocusGained", function(self)
            self:HighlightText()
        end)

        local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        hint:SetPoint("TOP", editBox, "BOTTOM", 0, -10)
        hint:SetText(L["Ctrl+C to copy, Esc to close"])

        frame.editBox = editBox
        self.copyFrame = frame
    end

    self.copyFrame.title:SetText(title or L["Copy"])
    self.copyFrame.editBox:SetText(text or "")
    self.copyFrame:Show()
    self.copyFrame.editBox:SetFocus()
    self.copyFrame.editBox:HighlightText()
end

-- ==============================
-- Eigener Link-Handler für lokale Addon-Links
-- ==============================
function QuestAnnounce:InitializeLinkHandler()
    if self.linkHandlerInitialized then
        return
    end
    self.linkHandlerInitialized = true

    hooksecurefunc("SetItemRef", function(link, text, button, chatFrame)
        local linkType, addonName, kind, questIDText = strsplit(":", link)

        if linkType ~= "addon" or addonName ~= "QuestAnnounce" or kind ~= "quest" then
            return
        end

        local questID = tonumber(questIDText)
        if not questID then
            return
        end

        -- ==============================
        -- SHIFT-Klick → in Chat einfügen
        -- ==============================
        if IsShiftKeyDown() then
            local questLink = QuestAnnounce:GetOfficialQuestLink(questID)
            if questLink and questLink ~= "" then
                ChatEdit_InsertLink(questLink)
            end
            return
        end

        -- ==============================
        -- Rechtsklick → Wowhead
        -- ==============================
        if button == "RightButton" then
            local url = QuestAnnounce:GetWowheadQuestURL(questID)
            if url then
                QuestAnnounce:ShowCopyDialog(url, L["Wowhead Quest URL"])
            end
            return
        end

        -- ==============================
        -- Linksklick → Quest öffnen
        -- ==============================
        if button == "LeftButton" then
            QuestAnnounce:OpenQuestInLog(questID)
            return
        end
    end)
end

--[[ QuestAnnounce ZeichenTabelle Chinese / Regex zum Erfassen von Questinformationen, abhängig von der Spielregion]]--
local QUEST_INFO_REGEX
if GetLocale() == "zhCN" then
    QUEST_INFO_REGEX = "^(.+)：%s*([-%d]+)%s*/%s*([-%d]+)%s*$"
else
    QUEST_INFO_REGEX = "^(.+):%s*([-%d]+)%s*/%s*([-%d]+)%s*$"
end

--[[ Event handlers für UI-Nachrichten]]--
function QuestAnnounce:UI_INFO_MESSAGE(event, id, msg)
    if not msg or msg == "" then
        return
    end

	if self.lastMessage == msg then
		return
	end

	self.lastMessage = msg

    if not self.db or not self.db.profile or not self.db.profile.settings or not self.db.profile.settings.enable then
        return
    end

    if self.db.profile.settings.paused then
        return
    end

    -- Quest Parsing
    local questTitle, currentAmountText, requiredAmountText = msg:match(QUEST_INFO_REGEX)

    if not questTitle then
        return
    end

	local questID, level, realQuestTitle, cachedIndex = QuestAnnounce:FindQuestByTitle(questTitle)

	self:SendDebugMsg("questTitle :: " .. tostring(questTitle))
	self:SendDebugMsg("realQuestTitle :: " .. tostring(realQuestTitle))
	self:SendDebugMsg("questID :: " .. tostring(questID))
	self:SendDebugMsg("questLink :: " .. tostring(questID and (C_QuestLog.GetQuestLink and C_QuestLog.GetQuestLink(questID) or GetQuestLink(questID)) or nil))

	local linkTitle = realQuestTitle or questTitle

	local localDisplayTitle = QuestAnnounce:BuildLocalQuestAddonLink(questID, linkTitle)
	local chatDisplayTitle = QuestAnnounce:BuildQuestLink(questID, linkTitle, level)

	local escapedQuestTitle = questTitle:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
	local localMsg = msg:gsub(escapedQuestTitle, localDisplayTitle, 1)
	local newMsg = msg:gsub(escapedQuestTitle, chatDisplayTitle, 1)

    -- QuestLog Lookup
    local logIndex = cachedIndex

    if not logIndex then
        local numEntries = C_QuestLog.GetNumQuestLogEntries()

        for i = 1, numEntries do
            local info = C_QuestLog.GetInfo(i)
            if info and info.questID == questID then
                logIndex = i
                break
            end
        end
    end

    local allowedByType, blockedType = self:IsQuestTypeAllowed(questID, logIndex)
    if not allowedByType then
        self:SendDebugMsg("Quest skipped by type filter :: " .. tostring(blockedType) .. " :: " .. tostring(questTitle))
        return
    end

    local currentAmount = tonumber(currentAmountText)
    local requiredAmount = tonumber(requiredAmountText)
    local objectiveLooksComplete = currentAmount
        and requiredAmount
        and requiredAmount > 0
        and currentAmount >= requiredAmount

    -- Send Logic
    if not logIndex then
        local announceAsComplete = (questID and objectiveLooksComplete) and true or false

        if objectiveLooksComplete and not questID then
            self:SendDebugMsg("objective looks complete but quest unresolved -> fallback to progress :: " .. tostring(questTitle))
        end

        if not announceAsComplete and not self:ShouldAnnounceProgressByEvery(currentAmount, requiredAmount) then
            self:SendDebugMsg("Progress skipped by every setting (no logIndex) :: " .. tostring(currentAmount) .. "/" .. tostring(requiredAmount))
            return
        end

        if questID and self:ShouldShowLocalProgressMessages() then
            if announceAsComplete then
                self:NotifySelf(L["Completed: "] .. localMsg, false)
            else
                self:NotifySelf(L["Progress: "] .. localMsg, false)
            end
        end
        if announceAsComplete then
            self:SendMsg(L["Completed: "] .. newMsg, true)
        else
            self:SendMsg(L["Progress: "] .. newMsg, false)
        end
        return
    end

    local isComplete = C_QuestLog.IsComplete(logIndex)

    if isComplete then
        if questID and self:ShouldShowLocalProgressMessages() then
            self:NotifySelf(L["Completed: "] .. localMsg, false)
        end
        self:SendMsg(L["Completed: "] .. newMsg, true)
    else
        if not self:ShouldAnnounceProgressByEvery(currentAmount, requiredAmount) then
            self:SendDebugMsg("Progress skipped by every setting :: " .. tostring(currentAmount) .. "/" .. tostring(requiredAmount))
            return
        end

        if questID and self:ShouldShowLocalProgressMessages() then
            self:NotifySelf(L["Progress: "] .. localMsg, false)
        end
        self:SendMsg(L["Progress: "] .. newMsg, false)
    end

    self:SendDebugMsg("Quest processed: " .. questTitle)

end



function QuestAnnounce:BuildQuestLink(questID, title, level)
    if not title or title == "" then
        return ""
    end

    if not self.db or not self.db.profile or not self.db.profile.settings or not self.db.profile.settings.linkQuest then
        return title
    end

    if not questID or questID == 0 then
        return title
    end

    local questLink = C_QuestLog.GetQuestLink and C_QuestLog.GetQuestLink(questID) or GetQuestLink(questID)

    if questLink and questLink ~= "" then
        return questLink
    end

    return title
end

-- ==============================
-- Questsuche über Titel und Objectives
-- ==============================
function QuestAnnounce:FindQuestByTitle(title)
    local normalizedTitle = self:NormalizeQuestTitle(title)
    if not normalizedTitle then
        return
    end

    -- 1. Exakter Titel-Treffer
    local questData = self.questCache[normalizedTitle]
    if questData then
        self:SendDebugMsg("Quest found by TITLE :: " .. tostring(title))
        return questData.questID, questData.level, questData.title, questData.index
    end

    -- 2. Exakter Objective-Treffer
    local objectiveData = self.objectiveCache[normalizedTitle]
    if objectiveData then
        self:SendDebugMsg("Quest found by OBJECTIVE :: " .. tostring(title) .. " -> " .. tostring(objectiveData.title))
        return objectiveData.questID, objectiveData.level, objectiveData.title, objectiveData.index
    end

    -- 3. Fallback: unscharfer Vergleich über Objectives
    for normalizedObjective, data in pairs(self.objectiveCache) do
        if normalizedObjective == normalizedTitle
            or normalizedObjective:find(normalizedTitle, 1, true)
            or normalizedTitle:find(normalizedObjective, 1, true) then
            self:SendDebugMsg("Quest found by OBJECTIVE FALLBACK :: " .. tostring(title) .. " -> " .. tostring(data.title))
            return data.questID, data.level, data.title, data.index
        end
    end

    self:SendDebugMsg("Quest NOT FOUND in title/objective cache :: " .. tostring(title))
end

--[[ Sends a debugging message if debug is enabled and we have a message to send ]]--
function QuestAnnounce:SendDebugMsg(msg)
    if msg ~= nil and self.db and self.db.profile and self.db.profile.settings and self.db.profile.settings.debug then
        QuestAnnounce:Print("DEBUG :: " .. msg)
    end
end

-- Prüft, ob addon-interne Meldungen für den Spieler erlaubt sind.
function QuestAnnounce:ShouldShowSelfMessages()
    local settings = self.db and self.db.profile and self.db.profile.settings
    if settings and settings.selfMessages == false then
        -- DE: Optional: Stummschaltung nur anwenden, wenn der Spieler solo ist.
        -- EN: Optional: Apply muting only while the player is solo.
        if settings.soloMuteSelfMessagesOnly then
            local inHomeGroup = IsInGroup and IsInGroup(LE_PARTY_CATEGORY_HOME)
            local inInstanceGroup = IsInGroup and IsInGroup(LE_PARTY_CATEGORY_INSTANCE)
            local inRaidGroup = IsInRaid and IsInRaid()
            if inHomeGroup or inInstanceGroup or inRaidGroup then
                return true
            end
        end
        return false
    end
    return true
end

-- Zeigt eine addon-interne Meldung im Chat und optional zusätzlich in UIErrorsFrame.
function QuestAnnounce:NotifySelf(msg, showUIError)
    if not msg or msg == "" then
        return
    end

    if not self:ShouldShowSelfMessages() then
        return
    end

    self:Print(msg)

    if showUIError and UIErrorsFrame and UIErrorsFrame.AddMessage then
        UIErrorsFrame:AddMessage(msg)
    end
end

-- Prüft, ob lokale Fortschritts-/Abschlussmeldungen im eigenen Chat gezeigt werden sollen.
function QuestAnnounce:ShouldShowLocalProgressMessages()
    local settings = self.db and self.db.profile and self.db.profile.settings
    if settings and settings.showLocalProgressMessages == false then
        return false
    end
    return true
end

--[[ Sends a chat message to the selected chat channels and frames where applicable,
    if we have a message to send; will also send a debugging message if debug is enabled ]]--
-- Sendet die Nachricht an die aktivierten Ausgabekanäle und Ausgabefenster
function QuestAnnounce:SendMsg(msg, isComplete)
    -- Sicherheitsabbruch, wenn keine Nachricht vorhanden ist
    if not msg then
        return
    end

    -- Sicherheitsabbruch, wenn Datenbank oder Einstellungen noch nicht geladen sind
    if not self.db or not self.db.profile or not self.db.profile.settings then
        return
    end

    -- Nur senden, wenn das Addon aktiviert ist
    if not self.db.profile.settings.enable then
        return
    end

    -- Temporäre Pause stummschaltet die Ausgabe, ohne das Addon zu deaktivieren
    if self.db.profile.settings.paused then
        return
    end

    local announceIn = self.db.profile.announceIn
    local announceTo = self.db.profile.announceTo
    local allowSelfOutput = self:ShouldShowSelfMessages()

    -- Nachricht an Chatkanäle senden
    if announceTo.chatFrame then
        -- SAY
        if announceIn.say then
            SendChatMessage(msg, "SAY")
            QuestAnnounce:SendDebugMsg("QuestAnnounce:SendMsg(SAY) :: " .. msg)
        end

        -- PARTY
        if announceIn.party then
            if IsInGroup(LE_PARTY_CATEGORY_HOME) then
                SendChatMessage(msg, "PARTY")
                QuestAnnounce:SendDebugMsg("QuestAnnounce:SendMsg(PARTY) :: " .. msg)
            end
        end

        -- INSTANCE_CHAT
        if announceIn.instance then
            if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
                SendChatMessage(msg, "INSTANCE_CHAT")
                QuestAnnounce:SendDebugMsg("QuestAnnounce:SendMsg(INSTANCE) :: " .. msg)
            end
        end

        -- GUILD
        if announceIn.guild then
            if IsInGuild() then
                SendChatMessage(msg, "GUILD")
                QuestAnnounce:SendDebugMsg("QuestAnnounce:SendMsg(GUILD) :: " .. msg)
            end
        end

        -- OFFICER
        if announceIn.officer then
            if IsInGuild() then
                SendChatMessage(msg, "OFFICER")
                QuestAnnounce:SendDebugMsg("QuestAnnounce:SendMsg(OFFICER) :: " .. msg)
            end
        end

        -- FOCUS wird als Whisper an das Fokusziel gesendet
        if announceIn.focus then
            if UnitExists("focus") then
                local name = UnitName("focus")
                if name then
                    SendChatMessage(msg, "WHISPER", nil, name)
                    QuestAnnounce:SendDebugMsg("QuestAnnounce:SendMsg(FOCUS->WHISPER) :: " .. msg)
                end
            else
                self:NotifySelf(L["No focus set, message not sent."], false)
            end
        end

        -- WHISPER
        if announceIn.whisper then
            local who = announceIn.whisperWho
            if who ~= nil and who ~= "" then
                SendChatMessage(msg, "WHISPER", nil, who)
                QuestAnnounce:SendDebugMsg("QuestAnnounce:SendMsg(WHISPER) :: " .. who .. "-" .. msg)
            end
        end

        -- Benutzerdefinierter CHANNEL
        if announceIn.channel then
            if announceIn.channelName and announceIn.channelName ~= "" then
                local id = GetChannelName(announceIn.channelName)

                if not id or id == 0 then
                    JoinTemporaryChannel(announceIn.channelName)
                    id = GetChannelName(announceIn.channelName)
                end

                if id and id > 0 then
                    SendChatMessage(msg, "CHANNEL", nil, id)
                    QuestAnnounce:SendDebugMsg("QuestAnnounce:SendMsg(CHANNEL) :: " .. msg)
                end
            else
                self:NotifySelf(L["No channel set."], false)
            end
        end
    end

    -- Nachricht zusätzlich im RaidWarningFrame anzeigen
    if allowSelfOutput and announceTo.raidWarningFrame then
        RaidNotice_AddMessage(RaidWarningFrame, msg, ChatTypeInfo["RAID_WARNING"])
    end

    -- Nachricht zusätzlich im UIErrorsFrame anzeigen
    if allowSelfOutput and announceTo.uiErrorsFrame then
        UIErrorsFrame:AddMessage(msg, 1.0, 1.0, 0.0, 7)
    end

    -- DE: Geordnete Sound-Ausgabe ohne Sound-Flut / EN: Ordered sound output without sound spam.
    if allowSelfOutput then
        if isComplete == true then
            self:PlayConfiguredSound("complete")
        else
            self:PlayConfiguredSound("progress")
        end
    end
    QuestAnnounce:SendDebugMsg("QuestAnnounce:SendMsg - " .. msg)
end
