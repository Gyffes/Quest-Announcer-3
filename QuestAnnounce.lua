-- Laden erforderlicher Bibliotheken und Lokalisierung
local QuestAnnounce = LibStub("AceAddon-3.0"):NewAddon("QuestAnnounce", "AceEvent-3.0", "AceConsole-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("QuestAnnounce")
local LSM = LibStub("LibSharedMedia-3.0") -- Stelle sicher, dass LibSharedMedia geladen ist

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
	    -- Überprüfe, ob die Funktion verfügbar ist
    if self.InitializeMinimapButton then
        print("InitializeMinimapButton ist verfügbar.")
        self:InitializeMinimapButton()
    else
        print("Fehler: InitializeMinimapButton ist nicht verfügbar.")
    end
	
	
end

function QuestAnnounce:CreateCustomTooltip()
    if not self.customTooltip then
        self.customTooltip = CreateFrame("GameTooltip", "QuestAnnounceTooltip", UIParent, "GameTooltipTemplate")
        self.customTooltip:SetFrameStrata("TOOLTIP")
        self.customTooltip:SetClampedToScreen(true)

        -- Entferne alle standardmäßigen Texturen und Regionen, die Teil des Tooltips sein könnten
        for _, region in ipairs({self.customTooltip:GetRegions()}) do
            if region:GetObjectType() == "Texture" then
                region:SetTexture(nil)
                region:Hide()
            elseif region:GetObjectType() == "FontString" then
                -- Lassen Sie die FontStrings sichtbar, wenn benötigt
            end
        end

        -- Erstelle benutzerdefinierte Hintergrund- und Rahmentexturen
        self.customTooltip.bgTexture = self.customTooltip:CreateTexture(nil, "BACKGROUND")
        self.customTooltip.bgTexture:SetAllPoints(self.customTooltip)
      --  self.customTooltip.bgTexture:SetColorTexture(0, 0, 0, 0) -- Standard: komplett transparent

     --   self.customTooltip.borderTexture = self.customTooltip:CreateTexture(nil, "BORDER")
     --   self.customTooltip.borderTexture:SetPoint("TOPLEFT", self.customTooltip, "TOPLEFT", -2, 2)
     --   self.customTooltip.borderTexture:SetPoint("BOTTOMRIGHT", self.customTooltip, "BOTTOMRIGHT", 2, -2)
     --   self.customTooltip.borderTexture:SetColorTexture(0, 0, 0, 0) -- Standard: komplett transparent
    end
end

-- Registrierung um den Tooltip zu Updaten ohne Reload
function QuestAnnounce:UpdateTooltipBackground()
   -- if not self.customTooltip or not self.customTooltip.bgTexture or not self.customTooltip.borderTexture then return end
	if not self.customTooltip then return end

    local bgColor = QuestAnnounce.db.profile.tooltip.bgColor or {0, 0, 0, 0.8}
    local borderColor = QuestAnnounce.db.profile.tooltip.borderColor or {1, 1, 1, 1}

    -- Setze die Hintergrundfarbe und den Alpha-Wert
    self.customTooltip.bgTexture:SetColorTexture(bgColor[1], bgColor[2], bgColor[3], bgColor[4])
    
    -- Setze die Rahmenfarbe und den Alpha-Wert
   -- self.customTooltip.borderTexture:SetColorTexture(borderColor[1], borderColor[2], borderColor[3], borderColor[4])
	    -- Aktualisiert die Schriftart und -größe
    local font = LSM:Fetch("font", QuestAnnounce.db.profile.tooltip.font)
    local fontSize = QuestAnnounce.db.profile.tooltip.fontSize
    local fontColor = QuestAnnounce.db.profile.tooltip.fontColor

end


--function QuestAnnounce:GetTooltipColors()
--    local bgColor = QuestAnnounce.db.profile.tooltip.bgColor or {0, 0, 0, 0.8}
--    local borderColor = QuestAnnounce.db.profile.tooltip.borderColor or {1, 1, 1}
--    
--    return bgColor, borderColor
--end



   function QuestAnnounce:InitializeMinimapButton()
    print("Initialisiere Minimap-Button...")  -- Debugging-Ausgabe

    local MinimapButton = CreateFrame("Button", "QuestAnnounceMinimapButton", Minimap)
    MinimapButton:SetSize(32, 32)  -- Größe des Buttons
    MinimapButton:SetFrameStrata("MEDIUM")
    MinimapButton:SetFrameLevel(8)

    local icon = MinimapButton:CreateTexture(nil, "BACKGROUND")
    icon:SetTexture("Interface\\AddOns\\QuestAnnounce\\Media\\QA3Icon")  -- Pfad zur gespeicherten Grafik
    icon:SetSize(28, 28)
    icon:SetPoint("CENTER")

    MinimapButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

	--Anpassung des Minimap-Button Tooltips
    MinimapButton:SetScript("OnEnter", function(self)
		-- Sicherstellen, dass LSM verfügbar ist
        if not LSM then
            print("LibSharedMedia nicht geladen")
            return
        end
		
		QuestAnnounce:CreateCustomTooltip()
		
		local font = LSM:Fetch("font", QuestAnnounce.db.profile.tooltip.font)
        local fontSize = QuestAnnounce.db.profile.tooltip.fontSize
        local fontColor = QuestAnnounce.db.profile.tooltip.fontColor
		local tooltip = QuestAnnounce.customTooltip
		
		tooltip:SetOwner(self, "ANCHOR_LEFT")
		tooltip:ClearLines()  -- Wichtig, um sicherzustellen, dass alte Zeilen entfernt werden
	    tooltip:AddLine("Quest Announce 3", fontColor[1], fontColor[2], fontColor[3])
		tooltip:AddLine(L["Tooltip LeftClick Aktivate/deactivated"], fontColor[1], fontColor[2], fontColor[3])
        tooltip:AddLine(L["Tooltip Right-click: Open options"], fontColor[1], fontColor[2], fontColor[3])

        -- Schriftart und -größe setzen
        for i = 1, tooltip:NumLines() do
            local leftLine = _G["QuestAnnounceTooltipTextLeft" .. i]
            if leftLine then
                leftLine:SetFont(font, fontSize)
				leftLine:SetTextColor(fontColor[1], fontColor[2], fontColor[3])
            end
            rightLine = _G["QuestAnnounceTooltipTextRight" .. i]
            if rightLine then
                rightLine:SetFont(font, fontSize)
				rightLine:SetTextColor(fontColor[1], fontColor[2], fontColor[3])
            end
        end
		QuestAnnounce:UpdateTooltipBackground()
		tooltip:Show()
    end)

    MinimapButton:SetScript("OnLeave", function(self)
        QuestAnnounce.customTooltip:Hide()
    end)

MinimapButton:RegisterForClicks("AnyUp")

MinimapButton:SetScript("OnClick", function(self, button)
    if button == "RightButton" then
        print("Rechtsklick erkannt auf QuestAnnounceMinimapButton")  -- Debugging-Ausgabe
        Settings.OpenToCategory("QuestAnnounce")
    else
        print("Linksklick erkannt auf QuestAnnounceMinimapButton")  -- Debugging-Ausgabe
        if QuestAnnounce.db.profile.settings.enable then
            QuestAnnounce.db.profile.settings.enable = false
            QuestAnnounce:OnDisable()
        else
            QuestAnnounce.db.profile.settings.enable = true
            QuestAnnounce:OnEnable()
        end
    end
end)

    MinimapButton:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 0, 0)

    print("Minimap-Button erfolgreich erstellt und positioniert.")  -- Debugging-Ausgabe

    MinimapButton:Show()  -- Sicherstellen, dass der Button angezeigt wird
	
	
	
end

-- Aktivierung des Addons
function QuestAnnounce:OnEnable()
    --[[ We're looking at the UI_INFO_MESSAGE for quest messages ]]--
    self:RegisterEvent("UI_INFO_MESSAGE") -- Event für UI-Nachrichten registrieren
    self:SendDebugMsg("Addon Enabled :: "..tostring(QuestAnnounce.db.profile.settings.enable))

    -- Chat- und Bildschirmmitte-Meldung beim Aktivieren
    print(L["QuestAnnounce activated!"])
    UIErrorsFrame:AddMessage(L["QuestAnnounce activated!"])
end

-- Deaktivierung des Addons
function QuestAnnounce:OnDisable()
    -- Hier kann der Code eingefügt werden, der ausgeführt werden soll, wenn das Addon deaktiviert wird
    self:UnregisterEvent("UI_INFO_MESSAGE")  -- Beispiel: Event abmelden
    self:SendDebugMsg("Addon deactivated :: "..tostring(self.db.profile.settings.enable))
	
	-- Chat- und Bildschirmmitte-Meldung beim Deaktivieren
    print(L["QuestAnnounce deactivated!"])
    UIErrorsFrame:AddMessage(L["QuestAnnounce deactivated!"])
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
