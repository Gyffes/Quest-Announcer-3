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
            debug = false,          -- Debug-Modus deaktiviert
			linkQuest = true		-- Quest Link
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
        QuestAnnounce:Print(L["Exiting the Channel "] .. channelName)
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
    text = "%s Kanal verlassen?",
    button1 = "Ja",
    button2 = "Nein",
    OnAccept = function(_, channelName)
        LeaveChannelByName(channelName)
        QuestAnnounce:Print("Verlassen des Kanals: " .. channelName)
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

	-- Fehlende Standardwerte rekursiv ergänzen, vorhandene Werte behalten
	DeepMergeDefaults(QuestAnnounceDB.profile, defaults.profile)

    self.db = QuestAnnounceDB
	
	self:BuildQuestCache()
	self:SetupOptions() 																-- Einrichten der Optionen
	
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

end)

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

function QuestAnnounce:Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99QuestAnnounce|r: " .. msg)
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

    return string.format("|cffffff00|Haddon:QuestAnnounce:quest:%d|h[%s]|h|r", questID, title)
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

    -- Quest Parsing
    local questTitle = msg:match(QUEST_INFO_REGEX)

    if not questTitle then
        return
    end

	local questID, level, realQuestTitle, cachedIndex = QuestAnnounce:FindQuestByTitle(questTitle)

	self:SendDebugMsg("questTitle :: " .. tostring(questTitle))
	self:SendDebugMsg("realQuestTitle :: " .. tostring(realQuestTitle))
	self:SendDebugMsg("questID :: " .. tostring(questID))
	self:SendDebugMsg("questLink :: " .. tostring(questID and (C_QuestLog.GetQuestLink and C_QuestLog.GetQuestLink(questID) or GetQuestLink(questID)) or nil))

	local linkTitle = realQuestTitle or questTitle
	local displayTitle = QuestAnnounce:BuildQuestLink(questID, linkTitle, level)

	local escapedQuestTitle = questTitle:gsub("([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
	local newMsg = msg:gsub(escapedQuestTitle, displayTitle, 1)

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

    -- Send Logic
    if not logIndex then
        self:SendMsg(L["Progress: "] .. newMsg)
        return
    end

    local isComplete = C_QuestLog.IsComplete(logIndex)

    if isComplete then
        self:SendMsg(L["Completed: "] .. newMsg)
    else
        self:SendMsg(L["Progress: "] .. newMsg)
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
function QuestAnnounce:SendMsg(msg)
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

    -- Sound abspielen, wenn aktiviert
    if self.db.profile.settings.sound then
        PlaySound(SOUNDKIT.RAID_WARNING)
    end

    QuestAnnounce:SendDebugMsg("QuestAnnounce:SendMsg - " .. msg)
end
