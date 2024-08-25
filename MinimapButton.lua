-- MinimapButton.lua

-- Funktion, um zu überprüfen, ob QuestAnnounce initialisiert ist
local function InitializeMinimapButton()
    if not QuestAnnounce then
        print("QuestAnnounce ist noch nicht initialisiert.")
        return
    end
	
    print("Initialisiere Minimap-Button...")  -- Debugging-Ausgabe
	
    -- Minimap Button erstellen
    local MinimapButton = CreateFrame("Button", "QuestAnnounceMinimapButton", Minimap)
    MinimapButton:SetSize(32, 32)  -- Größe des Buttons
    MinimapButton:SetFrameStrata("MEDIUM")
    MinimapButton:SetFrameLevel(8)

    -- Setzen des Icons
    local icon = MinimapButton:CreateTexture(nil, "BACKGROUND")
    icon:SetTexture("Interface\\AddOns\\QuestAnnounce\\Media\\QA3Icon")  -- Pfad zur gespeicherten Grafik
    icon:SetSize(28, 28)
    icon:SetPoint("CENTER")

    MinimapButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    -- Tooltip anzeigen
    MinimapButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("Quest Announce 3", 1, 1, 1)
        GameTooltip:AddLine("Linksklick: Aktivieren/Deaktivieren", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("Rechtsklick: Optionen öffnen", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)

    MinimapButton:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    -- Linksklick und Rechtsklick Funktionen
    MinimapButton:SetScript("OnClick", function(self, button)
	    if not QuestAnnounce then
        print("QuestAnnounce ist noch nicht initialisiert.")
        return
    end
	
        if button == "LeftButton" then
            if QuestAnnounce.db.profile.settings.enable then
                QuestAnnounce.db.profile.settings.enable = false
                QuestAnnounce:OnDisable()
            else
                QuestAnnounce.db.profile.settings.enable = true
                QuestAnnounce:OnEnable()
            end
        elseif button == "RightButton" then
            InterfaceOptionsFrame_OpenToCategory("Quest Announce 3")
        end
    end)

    MinimapButton:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 0, 0)
    
    print("Minimap-Button erfolgreich erstellt und positioniert.")  -- Debugging-Ausgabe

    MinimapButton:Show()  -- Sicherstellen, dass der Button angezeigt wird
end

-- Sicherstellen, dass der Minimap-Button erst nach dem Laden von QuestAnnounce initialisiert wird
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function()
    C_Timer.After(1, InitializeMinimapButton)  -- Leichte Verzögerung, um sicherzustellen, dass alles geladen ist
end)
