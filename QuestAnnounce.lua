-- Laden erforderlicher Bibliotheken und Lokalisierung
QuestAnnounce = CreateFrame("Frame")
QuestAnnounce.events = {}
QuestAnnounce.questCache = {}
QuestAnnounce.objectiveCache = {}
QuestAnnounce.lastMessage = nil

local L = QuestAnnounce_L[GetLocale()] or QuestAnnounce_L["enUS"]

-- Standardkonfigurationen für einen neuen Benutzer
local defaults = {
    profile = {
        settings = {
            enable = true,          -- Addon aktiviert
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
	
	if self.InitializeMinimapButton then
		self:InitializeMinimapButton()
	end
	
	self:SendDebugMsg("Addon Enabled :: " .. tostring(self.db.profile.settings.enable))
    QuestAnnounce:Print(L["QuestAnnounce activated!"])
    UIErrorsFrame:AddMessage(L["QuestAnnounce activated!"])
end

QuestAnnounce:RegisterEvent("ADDON_LOADED")											-- Register Event Addon Laden
QuestAnnounce:RegisterEvent("UI_INFO_MESSAGE")										-- Register Event Ui Info Message
QuestAnnounce:RegisterEvent("QUEST_LOG_UPDATE")										-- Register Event Quest Log Update
QuestAnnounce:RegisterEvent("QUEST_ACCEPTED")                                         -- DE: Quest angenommen / EN: Quest accepted
QuestAnnounce:RegisterEvent("QUEST_TURNED_IN")                                        -- DE: Quest abgegeben / EN: Quest turned in

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
        self:PlayConfiguredSound("turnin")
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
    local rawChannel = tostring(settings.soundChannel or "Master")
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
    local channel = channelMap[rawChannel] or "Master"
    settings.soundChannel = channel
    local now = GetTime()
    local lockSeconds = 0.35

    self.soundState = self.soundState or { activeUntil = 0, activePriority = 0, activeHandle = nil, pending = nil }
    local state = self.soundState

    local function PlayNow()
        local willPlay, handle = PlaySound(soundID, channel)
        if not willPlay then
            self:SendDebugMsg("Sound failed -> fallback RAID_WARNING on channel :: " .. tostring(channel))
            PlaySound(SOUNDKIT.RAID_WARNING, channel)
            return
        end

        state.activeHandle = handle
        state.activePriority = config.priority or 0
        state.activeUntil = GetTime() + lockSeconds
        self:SendDebugMsg("Play sound :: " .. tostring(eventKey) .. " :: " .. tostring(soundID) .. " @ " .. channel)
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
        local announceAsComplete = objectiveLooksComplete and true or false

        if not announceAsComplete and not self:ShouldAnnounceProgressByEvery(currentAmount, requiredAmount) then
            self:SendDebugMsg("Progress skipped by every setting (no logIndex) :: " .. tostring(currentAmount) .. "/" .. tostring(requiredAmount))
            return
        end

        if questID then
            if announceAsComplete then
                self:Print(L["Completed: "] .. localMsg)
            else
                self:Print(L["Progress: "] .. localMsg)
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
    if not isComplete and objectiveLooksComplete then
        isComplete = true
    end

    if isComplete then
        if questID then
            self:Print(L["Completed: "] .. localMsg)
        end
        self:SendMsg(L["Completed: "] .. newMsg, true)
    else
        if not self:ShouldAnnounceProgressByEvery(currentAmount, requiredAmount) then
            self:SendDebugMsg("Progress skipped by every setting :: " .. tostring(currentAmount) .. "/" .. tostring(requiredAmount))
            return
        end

        if questID then
            self:Print(L["Progress: "] .. localMsg)
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
                QuestAnnounce:Print(L["No focus set, message not sent."])
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
                QuestAnnounce:Print(L["No channel set."])
            end
        end
    end

    -- Nachricht zusätzlich im RaidWarningFrame anzeigen
    if announceTo.raidWarningFrame then
        RaidNotice_AddMessage(RaidWarningFrame, msg, ChatTypeInfo["RAID_WARNING"])
    end

    -- Nachricht zusätzlich im UIErrorsFrame anzeigen
    if announceTo.uiErrorsFrame then
        UIErrorsFrame:AddMessage(msg, 1.0, 1.0, 0.0, 7)
    end

    -- DE: Geordnete Sound-Ausgabe ohne Sound-Flut / EN: Ordered sound output without sound spam.
    if isComplete == true then
        self:PlayConfiguredSound("complete")
    else
        self:PlayConfiguredSound("progress")
    end
    QuestAnnounce:SendDebugMsg("QuestAnnounce:SendMsg - " .. msg)
end
