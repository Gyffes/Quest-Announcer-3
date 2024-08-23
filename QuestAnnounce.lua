-- Laden erforderlicher Bibliotheken und Lokalisierung
local QuestAnnounce = LibStub("AceAddon-3.0"):NewAddon("QuestAnnounce", "AceEvent-3.0", "AceConsole-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("QuestAnnounce")

-- Standardkonfigurationen für einen neuen Benutzer
local defaults = {
    profile = {
        settings = {
            enable = true,          -- Addon aktiviert
            every = 1,              -- Benachrichtigungsfrequenz
            sound = true,           -- Soundbenachrichtigungen aktiviert
            debug = false           -- Debug-Modus deaktiviert
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
            channelName = nil      -- Name des benutzerdefinierten Channels
        }
    }
}
-- Chanel betreten
function QuestAnnounce:JoinChannel(channelName)
    local id, name = GetChannelName(channelName)
    if not id or id == 0 then
        JoinTemporaryChannel(channelName)
        self:Print("Beigetreten zum Kanal: " .. channelName)
    else
        self:Print("Bereits im Kanal: " .. channelName)
    end
end

-- Chanel verlassen 
function QuestAnnounce:LeaveChannel(channelName)
    local id, name = GetChannelName(channelName)
    if id and id > 0 then
        LeaveChannelByName(channelName)
        self:Print("Verlassen des Kanals: " .. channelName)
    end
end

-- ToggleChannelLeave-Methode 
function QuestAnnounce:ToggleChannelLeave(enable, channelName)
    if not enable then
        StaticPopup_Show("CONFIRM_LEAVE_CHANNEL", channelName)
    end
end



--[[ Initialisierung des Addons ]]--
function QuestAnnounce:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("QuestAnnounceDB", defaults, true) -- Einrichten der Datenbank mit den Standardwerten
    
	-- Registrieren von Callbacks für Profiländerungen
	self.db.RegisterCallback(self, "OnProfileChanged", "OnProfileChanged")
    self.db.RegisterCallback(self, "OnProfileCopied", "OnProfileChanged")
    self.db.RegisterCallback(self, "OnProfileReset", "OnProfileReset")
    self.db.RegisterCallback(self, "OnNewProfile", "OnNewProfile")
    
    self:SetupOptions() -- Einrichten der Optionen
end

-- Aktivierung des Addons
function QuestAnnounce:OnEnable()
    --[[ We're looking at the UI_INFO_MESSAGE for quest messages ]]--
    self:RegisterEvent("UI_INFO_MESSAGE") -- Event für UI-Nachrichten registrieren
    self:SendDebugMsg("Addon Enabled :: "..tostring(QuestAnnounce.db.profile.settings.enable))
end

--[[ QuestAnnounce ZeichenTabelle Chinese / Regex zum Erfassen von Questinformationen, abhängig von der Spielregion]]--
local QUEST_INFO_REGEX = "(.*):%s*([-%d]+)%s*/%s*([-%d]+)%s*$"
	if (GetLocale() == "zhCN") then
		QUEST_INFO_REGEX = "(.*)：%s*([-%d]+)%s*/%s*([-%d]+)%s*$"
end

--[[ Event handlers für UI-Nachrichten]]--
function QuestAnnounce:UI_INFO_MESSAGE(event, id, msg)
    local settings = self.db.profile.settings
    
	-- Verarbeitung der Nachricht, wenn das Addon aktiviert ist
    if (msg ~= nil) then
        if (settings.enable) then
            local questText = gsub(msg, QUEST_INFO_REGEX, "%1", 1)
            QuestAnnounce:SendDebugMsg("Quest Text: "..questText)
            
            -- Prüfen, ob die Nachricht Quest-Details enthält
			if (questText ~= msg) then
                local ii, jj, strItemName, iNumItems, iNumNeeded = string.find(msg, QUEST_INFO_REGEX)
                local stillNeeded = iNumNeeded - iNumItems
                
                QuestAnnounce:SendDebugMsg("Item Name: "..strItemName.." :: Num Items: "..iNumItems.." :: Num Needed: "..iNumNeeded.." :: Still Need: "..stillNeeded)

                if(stillNeeded == 0 and settings.every == 0) then
                    QuestAnnounce:SendMsg(L["Completed: "]..msg)
                elseif(QuestAnnounce.db.profile.settings.every > 0) then
                    local every = math.fmod(iNumItems, settings.every)
                    QuestAnnounce:SendDebugMsg("Every fMod: "..every)
                
                    if(every == 0 and stillNeeded > 0) then
                        QuestAnnounce:SendMsg(L["Progress: "]..msg)
                    elseif(stillNeeded == 0) then
                        QuestAnnounce:SendMsg(L["Completed: "]..msg)
                    end
                end
            end
        end
    end
end

-- Profiländerungs-Callbacks
function QuestAnnounce:OnProfileChanged(event, db)
    self.db.profile = db.profile
end

function QuestAnnounce:OnProfileReset(event, db)
    for k, v in pairs(defaults) do
        db.profile[k] = v
    end
    self.db.profile = db.profile
end

function QuestAnnounce:OnNewProfile(event, db)
    for k, v in pairs(defaults) do
        db.profile[k] = v
    end
end

--[[ Sends a debugging message if debug is enabled and we have a message to send ]]--
function QuestAnnounce:SendDebugMsg(msg)
    if(msg ~= nil and self.db.profile.settings.debug) then
        QuestAnnounce:Print("DEBUG :: "..msg)
    end
end

--[[ Sends a chat message to the selected chat channels and frames where applicable,
    if we have a message to send; will also send a debugging message if debug is enabled ]]--
function QuestAnnounce:SendMsg(msg)    
    local announceIn = self.db.profile.announceIn
    local announceTo = self.db.profile.announceTo

    if (msg ~= nil and self.db.profile.settings.enable) then -- Nachrichten an die konfigurierten Kanäle senden
        if(announceTo.chatFrame) then
            if(announceIn.say) then
                SendChatMessage(msg, "SAY")
                QuestAnnounce:SendDebugMsg("QuestAnnounce:SendMsg(SAY) :: "..msg)
            end
        
		--[[ GetNumGroupMembers is group-wide; GetNumSubgroupMembers is confined to your group of 5 ]]--
		--[[ Ref: http://www.wowpedia.org/API_GetNumSubgroupMembers or http://www.wowpedia.org/API_GetNumGroupMembers ]]--
            if(announceIn.party) then
                if(IsInGroup() and GetNumSubgroupMembers(LE_PARTY_CATEGORY_HOME) > 0) then
                    SendChatMessage(msg, "PARTY")
                end
                
                QuestAnnounce:SendDebugMsg("QuestAnnounce:SendMsg(PARTY) :: "..msg)
            end                
        
            if(announceIn.instance) then
                if (IsInInstance() and GetNumSubgroupMembers(LE_PARTY_CATEGORY_INSTANCE) > 0) then
                    SendChatMessage(msg, "INSTANCE_CHAT")
                end
                
                QuestAnnounce:SendDebugMsg("QuestAnnounce:SendMsg(INSTANCE) :: "..msg)
            end                
        
            if(announceIn.guild) then
                if(IsInGuild()) then
                    SendChatMessage(msg, "GUILD")
                end
                
                QuestAnnounce:SendDebugMsg("QuestAnnounce:SendMsg(GUILD) :: "..msg)
            end
            
            if(announceIn.officer) then
                if(IsInGuild()) then
                    SendChatMessage(msg, "OFFICER")
                end
                
                QuestAnnounce:SendDebugMsg("QuestAnnounce:SendMsg(OFFICER) :: "..msg)
            end            
            
            if(announceIn.whisper) then
                local who = announceIn.whisperWho
                if(who ~= nil and who ~= "") then
                    SendChatMessage(msg, "WHISPER", nil, who)
                    QuestAnnounce:SendDebugMsg("QuestAnnounce:SendMsg(WHISPER) :: "..who.."-"..msg)
                end
            end

            -- Unterstützung für benutzerdefinierte Kanäle erweitern
            if announceIn.channel then
                if not announceIn.channelName or announceIn.channelName == "" then
                    QuestAnnounce:Print("Bitte tragen Sie einen Kanalnamen ein.")
                else
                    local id, name = GetChannelName(announceIn.channelName)
                    if not id or id == 0 then
                        JoinTemporaryChannel(announceIn.channelName)
                        QuestAnnounce:Print("Beigetreten zum Kanal: " .. announceIn.channelName)
                    end
                    if id and id > 0 then
                        SendChatMessage(msg, "CHANNEL", nil, id)
                        QuestAnnounce:SendDebugMsg("QuestAnnounce:SendMsg(CHANNEL) :: " .. name .. "-" .. msg)
                    end
				end
            end
        end
        function QuestAnnounce:ToggleChannelLeave(enable, channelName)
			if not enable then
				local dialog = StaticPopup_Show("CONFIRM_LEAVE_CHANNEL", channelName)
				if dialog then
					dialog.data = channelName
				end
			end
		end

		StaticPopupDialogs["CONFIRM_LEAVE_CHANNEL"] = {
			text = "%s Kanal verlassen?",
			button1 = "Ja",
			button2 = "Nein",
			OnAccept = function(self, channelName)
				LeaveChannelByName(channelName)
				QuestAnnounce:Print("Verlassen des Kanals: " .. channelName)
		end,
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
			preferredIndex = 3,
			}

		
        if(announceTo.raidWarningFrame) then
            RaidNotice_AddMessage(RaidWarningFrame, msg, ChatTypeInfo["RAID_WARNING"])
        end
        
        if(announceTo.uiErrorsFrame) then
            UIErrorsFrame:AddMessage(msg, 1.0, 1.0, 0.0, 7)
        end
        
        if(self.db.profile.settings.sound) then
            PlaySound(PlaySoundKitID and "RAID_WARNING" or 8959)
        end
    end
    
    QuestAnnounce:SendDebugMsg("QuestAnnounce:SendMsg - "..msg)
end
