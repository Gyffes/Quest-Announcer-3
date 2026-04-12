-- QuestAnnounce Addon Initialisierung und Lokalisierung
local QuestAnnounce = _G["QuestAnnounce"]
local L = QuestAnnounce_L[GetLocale()] or QuestAnnounce_L["enUS"]


-- Öffnet das Hauptfenster von QuestAnnounce in den Blizzard-Einstellungen.
-- Der doppelte Aufruf ist ein bekannter Workaround, damit das Panel zuverlässig angezeigt wird.
local function openConfig()
    local category = QuestAnnounce.optionsCategory
    if not category then
        return
    end

    Settings.OpenToCategory(category:GetID())
    Settings.OpenToCategory(category:GetID())
end

-- Erstellt und registriert die Blizzard-Optionsfenster für QuestAnnounce.
-- Die Funktion wird nur einmal ausgeführt und baut:
-- 1. das Hauptfenster "QuestAnnounce"
-- 2. das Unterfenster "Tooltip Settings"
function QuestAnnounce:SetupOptions()
    -- Abbruch, wenn die Optionsfenster bereits erstellt wurden
    if self.optionsCategory then
        return
    end

    -- Tabelle für spätere Referenzen auf Optionsfenster
    self.optionsFrames = {}

    -- Hilfsfunktion: Erstellt eine Checkbox an einer festen Position
    local function CreateCheckbox(parent, text, x, y, onClick)
        local cb = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
        cb:SetPoint("TOPLEFT", x, y)
        cb.Text:SetText(text)
        cb:SetScript("OnClick", onClick)
        return cb
    end

    -- Hilfsfunktion: Erstellt ein Eingabefeld für Texte
    local function CreateEditBox(parent, width, height, x, y)
        local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
        box:SetSize(width, height)
        box:SetPoint("TOPLEFT", x, y)
        box:SetAutoFocus(false)
        return box
    end

    -- Hilfsfunktion: Erstellt einen normalen Button
    local function CreateButton(parent, text, width, height, x, y, onClick)
        local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
        button:SetSize(width, height)
        button:SetPoint("TOPLEFT", x, y)
        button:SetText(text)
        button:SetScript("OnClick", onClick)
        return button
    end

    -- Hilfsfunktion: Erstellt ein Dropdown-Menü mit einer Liste von Einträgen
    local function CreateDropdown(parent, width, x, y, items, onSelect)
        local dropdown = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
        dropdown:SetPoint("TOPLEFT", x - 16, y + 10)
        UIDropDownMenu_SetWidth(dropdown, width)

        UIDropDownMenu_Initialize(dropdown, function(self, level)
            for _, item in ipairs(items) do
                local info = UIDropDownMenu_CreateInfo()
                info.text = item
                info.func = function()
                    UIDropDownMenu_SetSelectedName(dropdown, item)
                    onSelect(item)
                end
                UIDropDownMenu_AddButton(info)
            end
        end)

        return dropdown
    end

    -- Hilfsfunktion: Erstellt einen Button mit Farbvorschau.
    -- Beim Klick öffnet sich der Blizzard-Farbwähler.
    local function CreateColorButton(parent, text, x, y, onColorChanged)
        local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
        button:SetSize(180, 22)
        button:SetPoint("TOPLEFT", x, y)
        button:SetText(text)

        -- Kleine Farbvorschau rechts im Button
        button.swatch = button:CreateTexture(nil, "ARTWORK")
        button.swatch:SetSize(16, 16)
        button.swatch:SetPoint("RIGHT", button, "RIGHT", -6, 0)
        button.swatch:SetColorTexture(1, 1, 1, 1)

        button:SetScript("OnClick", function()
            local r = button.r or 1
            local g = button.g or 1
            local b = button.b or 1
            local a = button.a or 1

            local info = {}

            -- Aktuelle Farbe und Transparenz an den Farbpicker übergeben
            info.r = r
            info.g = g
            info.b = b
            info.opacity = 1 - a
            info.hasOpacity = true

            -- Wird ausgeführt, wenn Farbe oder Alpha geändert werden
            info.swatchFunc = function()
                local nr, ng, nb = ColorPickerFrame:GetColorRGB()
                local na = 1 - (ColorPickerFrame:GetColorAlpha() or 0)

                button.r, button.g, button.b, button.a = nr, ng, nb, na
                button.swatch:SetColorTexture(nr, ng, nb, na)

                if onColorChanged then
                    onColorChanged(nr, ng, nb, na)
                end
            end

            -- Für Transparenz-Änderungen dieselbe Funktion verwenden
            info.opacityFunc = info.swatchFunc

            -- Wird ausgeführt, wenn der Benutzer abbricht
            info.cancelFunc = function(previousValues)
                if not previousValues then
                    return
                end

                local pr = previousValues.r or 1
                local pg = previousValues.g or 1
                local pb = previousValues.b or 1
                local pa = 1 - (previousValues.opacity or 0)

                button.r, button.g, button.b, button.a = pr, pg, pb, pa
                button.swatch:SetColorTexture(pr, pg, pb, pa)

                if onColorChanged then
                    onColorChanged(pr, pg, pb, pa)
                end
            end

            ColorPickerFrame:SetupColorPickerAndShow(info)
        end)

        return button
    end

    -- =========================================================
    -- HAUPTPANEL: Allgemeine Einstellungen
    -- =========================================================
    local generalPanel = CreateFrame("Frame")
	
	-- Scrollbar für das gesamte Options-Panel
	local scrollFrame = CreateFrame("ScrollFrame", nil, generalPanel, "UIPanelScrollFrameTemplate")
	scrollFrame:SetPoint("TOPLEFT", generalPanel, "TOPLEFT", 16, -10)
	scrollFrame:SetPoint("BOTTOMRIGHT", generalPanel, "BOTTOMRIGHT", -32, 10)
	
	-- Content Frame erstellen
	local content = CreateFrame("Frame", nil, scrollFrame)
	content:SetSize(620, 1) -- feste Breite für saubere Ausrichtung
	scrollFrame:SetScrollChild(content)


	-- Haupttitel des Optionsfensters
	local title = content:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
	title:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -16)
	title:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -16)
	title:SetJustifyH("CENTER")
	title:SetText(L["Quest Announce 3"])

    --[[ Untertitel / Beschreibung
    local subtitle = generalPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    subtitle:SetWidth(700)
    subtitle:SetJustifyH("LEFT")--]]

    -- Überschrift für die allgemeinen Einstellungen
	local settingsHeader = content:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	settingsHeader:SetPoint("TOPLEFT", 16, -60)
	settingsHeader:SetText(L["Settings"])

    -- Addon aktivieren / deaktivieren
    local enableCheckbox = CreateCheckbox(content, L["Enable"], 16, -90, function(self)
        QuestAnnounce.db.profile.settings.enable = self:GetChecked() and true or false
        QuestAnnounce:SendDebugMsg("setSettings: enable :: " .. tostring(QuestAnnounce.db.profile.settings.enable))
    end)

    -- Sound aktivieren / deaktivieren
    local soundCheckbox = CreateCheckbox(content, L["Sound"], 220, -90, function(self)
        QuestAnnounce.db.profile.settings.sound = self:GetChecked() and true or false
        QuestAnnounce:SendDebugMsg("setSettings: sound :: " .. tostring(QuestAnnounce.db.profile.settings.sound))
    end)
	
    -- Quest-Links aktivieren / deaktivieren
    local linkQuestCheckbox = CreateCheckbox(content, L["Enable Quest Links"], 420, -90, function(self)
        QuestAnnounce.db.profile.settings.linkQuest = self:GetChecked() and true or false
        QuestAnnounce:SendDebugMsg("setSettings: linkQuest :: " .. tostring(QuestAnnounce.db.profile.settings.linkQuest))
    end)
    -- Debug-Modus aktivieren / deaktivieren
    local debugCheckbox = CreateCheckbox(content, L["Debug"], 130, -120, function(self)
        QuestAnnounce.db.profile.settings.debug = self:GetChecked() and true or false
        QuestAnnounce:SendDebugMsg("setSettings: debug :: " .. tostring(QuestAnnounce.db.profile.settings.debug))
    end)


-- Trennlinie zwischen Quest-Link-Einstellung und Fortschritts-Einstellung
	local separator = content:CreateTexture(nil, "ARTWORK")
	separator:SetColorTexture(0.5, 0.5, 0.5, 0.6)
	separator:SetHeight(1)
	separator:SetPoint("TOPLEFT", content, "TOPLEFT", 16, -160)
	separator:SetPoint("TOPRIGHT", content, "TOPRIGHT", -16, -160)


	-- Slider für die Anzahl der Fortschrittsmeldungen
	-- Der Slider sitzt etwas weiter mittig im Fenster
	local everySlider = CreateFrame("Slider", nil, content, "OptionsSliderTemplate")
	everySlider:SetPoint("TOPLEFT", content, "TOPLEFT", 60, -202)
	everySlider:SetMinMaxValues(0, 100)
	everySlider:SetValueStep(1)
	everySlider:SetObeyStepOnDrag(true)
	everySlider:SetWidth(260)
	everySlider.Low:SetText("0")
	everySlider.High:SetText("100")
	

	-- Eingabefeld für numerische Eingabe der Fortschritts-Ankündigung
	-- Das Feld sitzt rechts neben dem Slider mit etwas Abstand
	local everyInput = CreateEditBox(content, 60, 20, 0, 0)
	everyInput:ClearAllPoints()
	everyInput:SetPoint("LEFT", everySlider, "RIGHT", 28, 0)
	everyInput:SetSize(70, 20)
	everyInput:SetNumeric(true)
	everyInput:SetMaxLetters(3)

	-- Beschriftung für das Eingabefeld
	local everyInputLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	everyInputLabel:SetPoint("BOTTOM", everyInput, "TOP", 0, 6)
	everyInputLabel:SetText("Wert")
	
	-- Beschriftung für die Fortschritts-Ankündigung
    -- Der Text wird exakt mittig über dem Slider ausgerichtet
    local everyLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    everyLabel:SetPoint("BOTTOM", everySlider, "TOP", 0, 14)
    everyLabel:SetText(L["Announce Every"])

	-- Slider und Eingabefeld miteinander synchronisieren
	everySlider:SetScript("OnValueChanged", function(self, value)
	local rounded = math.floor(value + 0.5)

		if self:GetValue() ~= rounded then
			self:SetValue(rounded)
        return
    end

    if QuestAnnounce.db.profile.settings.every ~= rounded then
       QuestAnnounce.db.profile.settings.every = rounded
       QuestAnnounce:SendDebugMsg("setSettings: every :: " .. tostring(rounded))
    end

    if everyInput:GetText() ~= tostring(rounded) then
        everyInput:SetText(tostring(rounded))
    end
end)

	-- Übernimmt den Wert aus dem Eingabefeld beim Drücken von Enter
	everyInput:SetScript("OnEnterPressed", function(self)
		local value = tonumber(self:GetText()) or 0

		if value < 0 then
			value = 0
		elseif value > 100 then
			value = 100
    end

    QuestAnnounce.db.profile.settings.every = value
    everySlider:SetValue(value)
    self:SetText(tostring(value))
    self:ClearFocus()

    QuestAnnounce:SendDebugMsg("setSettings: every :: " .. tostring(value))
	end)

	-- Übernimmt den Wert auch, wenn das Feld den Fokus verliert
	everyInput:SetScript("OnEditFocusLost", function(self)
		local value = tonumber(self:GetText()) or 0

		if value < 0 then
			value = 0
		elseif value > 100 then
			value = 100
		end

    QuestAnnounce.db.profile.settings.every = value
    everySlider:SetValue(value)
    self:SetText(tostring(value))

    QuestAnnounce:SendDebugMsg("setSettings: every :: " .. tostring(value))
	end)

	-- Trennlinie über dem Announce-Bereich
	local separator2 = content:CreateTexture(nil, "ARTWORK")
	separator2:SetColorTexture(0.5, 0.5, 0.5, 0.6)
	separator2:SetHeight(1)
	separator2:SetPoint("TOPLEFT", content, "TOPLEFT", 16, -250)
	separator2:SetPoint("TOPRIGHT", content, "TOPRIGHT", -16, -250)

    -- Überschrift für die Ziele der Ausgabe
        -- Überschrift für die Ziele der Ausgabe
    local announceToHeader = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    announceToHeader:SetPoint("TOPLEFT", content, "TOPLEFT", 16, -266)
    announceToHeader:SetText(L["Where do you want to make the announcements?"])

    -- Chatfenster-Ausgabe
    local chatFrameCheckbox = CreateCheckbox(content, L["Chat Frame"], 16, -300, function(self)
        QuestAnnounce.db.profile.announceTo.chatFrame = self:GetChecked() and true or false
        QuestAnnounce:SendDebugMsg("setAnnounceTo: chatFrame :: " .. tostring(QuestAnnounce.db.profile.announceTo.chatFrame))
    end)

    -- Raid-Warning-Ausgabe
    local raidWarningCheckbox = CreateCheckbox(content, L["Raid Warning Frame"], 220, -300, function(self)
        QuestAnnounce.db.profile.announceTo.raidWarningFrame = self:GetChecked() and true or false
        QuestAnnounce:SendDebugMsg("setAnnounceTo: raidWarningFrame :: " .. tostring(QuestAnnounce.db.profile.announceTo.raidWarningFrame))
    end)

    -- UIErrorsFrame-Ausgabe
    local uiErrorsCheckbox = CreateCheckbox(content, L["UI Errors Frame"], 440, -300, function(self)
        QuestAnnounce.db.profile.announceTo.uiErrorsFrame = self:GetChecked() and true or false
        QuestAnnounce:SendDebugMsg("setAnnounceTo: uiErrorsFrame :: " .. tostring(QuestAnnounce.db.profile.announceTo.uiErrorsFrame))
    end)

	-- Trennlinie zwischen Ausgabezielen und Chatkanälen
	-- Etwas mehr Abstand unter den Ausgabe-Checkboxen
	local separator3 = content:CreateTexture(nil, "ARTWORK")
	separator3:SetColorTexture(0.5, 0.5, 0.5, 0.6)
	separator3:SetHeight(1)
	separator3:SetPoint("TOPLEFT", content, "TOPLEFT", 16, -348)
	separator3:SetPoint("TOPRIGHT", content, "TOPRIGHT", -16, -348)
	
        -- Überschrift für die Chatkanäle linksbündig und näher an den Checkboxen
    local announceInHeader = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    announceInHeader:SetPoint("TOPLEFT", content, "TOPLEFT", 16, -374)
    announceInHeader:SetText(L["What channels do you want to make the announcements?"])

    -- Linke Spalte: Say / Party / Instance
    local sayCheckbox = CreateCheckbox(content, L["Say"], 16, -404, function(self)
        QuestAnnounce.db.profile.announceIn.say = self:GetChecked() and true or false
        QuestAnnounce:SendDebugMsg("setAnnounceIn: say :: " .. tostring(QuestAnnounce.db.profile.announceIn.say))
    end)

    local partyCheckbox = CreateCheckbox(content, L["Party"], 16, -434, function(self)
        QuestAnnounce.db.profile.announceIn.party = self:GetChecked() and true or false
        QuestAnnounce:SendDebugMsg("setAnnounceIn: party :: " .. tostring(QuestAnnounce.db.profile.announceIn.party))
    end)

    local instanceCheckbox = CreateCheckbox(content, L["Instance"], 16, -464, function(self)
        QuestAnnounce.db.profile.announceIn.instance = self:GetChecked() and true or false
        QuestAnnounce:SendDebugMsg("setAnnounceIn: instance :: " .. tostring(QuestAnnounce.db.profile.announceIn.instance))
    end)

    -- Mittlere Spalte: Officer / Focus / Gilde
    local officerCheckbox = CreateCheckbox(content, L["Officer"], 220, -404, function(self)
        QuestAnnounce.db.profile.announceIn.officer = self:GetChecked() and true or false
        QuestAnnounce:SendDebugMsg("setAnnounceIn: officer :: " .. tostring(QuestAnnounce.db.profile.announceIn.officer))
    end)

    local focusCheckbox = CreateCheckbox(content, L["Focus"], 220, -434, function(self)
        QuestAnnounce.db.profile.announceIn.focus = self:GetChecked() and true or false
        QuestAnnounce:SendDebugMsg("setAnnounceIn: focus :: " .. tostring(QuestAnnounce.db.profile.announceIn.focus))
    end)

    local guildCheckbox = CreateCheckbox(content, L["Guild"], 220, -464, function(self)
        QuestAnnounce.db.profile.announceIn.guild = self:GetChecked() and true or false
        QuestAnnounce:SendDebugMsg("setAnnounceIn: guild :: " .. tostring(QuestAnnounce.db.profile.announceIn.guild))
    end)

    -- Zeile 4: Flüstern + An wen flüstern + Eingabefeld
    local whisperCheckbox = CreateCheckbox(content, L["Whisper"], 16, -514, function(self)
        QuestAnnounce.db.profile.announceIn.whisper = self:GetChecked() and true or false
        QuestAnnounce:SendDebugMsg("setAnnounceIn: whisper :: " .. tostring(QuestAnnounce.db.profile.announceIn.whisper))
    end)

    local whisperWhoLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    whisperWhoLabel:SetPoint("LEFT", whisperCheckbox, "RIGHT", 180, 0)
    whisperWhoLabel:SetText(L["Whisper Who"])

    local whisperWhoBox = CreateEditBox(content, 150, 20, 0, 0)
    whisperWhoBox:ClearAllPoints()
    whisperWhoBox:SetPoint("LEFT", whisperWhoLabel, "RIGHT", 12, -2)
    whisperWhoBox:SetScript("OnEnterPressed", function(self)
        QuestAnnounce.db.profile.announceIn.whisperWho = self:GetText()
        QuestAnnounce:SendDebugMsg("setAnnounceIn: whisperWho :: " .. tostring(QuestAnnounce.db.profile.announceIn.whisperWho))
        self:ClearFocus()
    end)
    whisperWhoBox:SetScript("OnEditFocusLost", function(self)
        QuestAnnounce.db.profile.announceIn.whisperWho = self:GetText()
        QuestAnnounce:SendDebugMsg("setAnnounceIn: whisperWho :: " .. tostring(QuestAnnounce.db.profile.announceIn.whisperWho))
    end)

    -- Zeile 5: Kanal + Kanalname + Eingabefeld
    local channelCheckbox = CreateCheckbox(content, L["Channel"], 16, -544, function(self)
        local value = self:GetChecked() and true or false
        QuestAnnounce.db.profile.announceIn.channel = value
        QuestAnnounce:SendDebugMsg("setAnnounceIn: channel :: " .. tostring(value))

        if value then
            if QuestAnnounce.db.profile.announceIn.channelName == "" or not QuestAnnounce.db.profile.announceIn.channelName then
                StaticPopup_Show("MISSING_CHANNEL_NAME")
            else
                QuestAnnounce:JoinChannel(QuestAnnounce.db.profile.announceIn.channelName)
            end
        else
            if QuestAnnounce.db.profile.announceIn.channelName and QuestAnnounce.db.profile.announceIn.channelName ~= "" then
                QuestAnnounce:ToggleChannelLeave(false, QuestAnnounce.db.profile.announceIn.channelName)
            end
        end
    end)

    local channelNameLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    channelNameLabel:SetPoint("LEFT", channelCheckbox, "RIGHT", 180, 0)
    channelNameLabel:SetText(L["Channel Name"])

    local channelNameBox = CreateEditBox(content, 150, 20, 0, 0)
    channelNameBox:ClearAllPoints()
    channelNameBox:SetPoint("LEFT", channelNameLabel, "RIGHT", 12, -2)
    channelNameBox:SetScript("OnEnterPressed", function(self)
        QuestAnnounce.db.profile.announceIn.channelName = self:GetText()
        QuestAnnounce:SendDebugMsg("setAnnounceIn: channelName :: " .. tostring(QuestAnnounce.db.profile.announceIn.channelName))
        self:ClearFocus()
    end)
    channelNameBox:SetScript("OnEditFocusLost", function(self)
        QuestAnnounce.db.profile.announceIn.channelName = self:GetText()
        QuestAnnounce:SendDebugMsg("setAnnounceIn: channelName :: " .. tostring(QuestAnnounce.db.profile.announceIn.channelName))
    end)

    -- Testbutton zum Senden einer Testnachricht
    local testButton = CreateButton(content, L["Test Frame Messages"], 180, 24, 340, -120, function()
        QuestAnnounce:SendMsg(L["QuestAnnounce Test Message"])
    end)

    -- Aktualisiert alle Werte im Hauptpanel beim Öffnen
-- Aktualisiert alle Werte im Hauptfenster beim Öffnen
local function RefreshGeneralPanel()
	if not QuestAnnounce.db or not QuestAnnounce.db.profile then
		return
	end

    enableCheckbox:SetChecked(QuestAnnounce.db.profile.settings.enable)
    soundCheckbox:SetChecked(QuestAnnounce.db.profile.settings.sound)
    debugCheckbox:SetChecked(QuestAnnounce.db.profile.settings.debug)
    linkQuestCheckbox:SetChecked(QuestAnnounce.db.profile.settings.linkQuest)

    everySlider:SetValue(QuestAnnounce.db.profile.settings.every or 1)
    everyInput:SetText(tostring(QuestAnnounce.db.profile.settings.every or 1))

    chatFrameCheckbox:SetChecked(QuestAnnounce.db.profile.announceTo.chatFrame)
    raidWarningCheckbox:SetChecked(QuestAnnounce.db.profile.announceTo.raidWarningFrame)
    uiErrorsCheckbox:SetChecked(QuestAnnounce.db.profile.announceTo.uiErrorsFrame)

    sayCheckbox:SetChecked(QuestAnnounce.db.profile.announceIn.say)
    partyCheckbox:SetChecked(QuestAnnounce.db.profile.announceIn.party)
    instanceCheckbox:SetChecked(QuestAnnounce.db.profile.announceIn.instance)
    guildCheckbox:SetChecked(QuestAnnounce.db.profile.announceIn.guild)
    officerCheckbox:SetChecked(QuestAnnounce.db.profile.announceIn.officer)
    focusCheckbox:SetChecked(QuestAnnounce.db.profile.announceIn.focus)
    whisperCheckbox:SetChecked(QuestAnnounce.db.profile.announceIn.whisper)
    channelCheckbox:SetChecked(QuestAnnounce.db.profile.announceIn.channel)

    whisperWhoBox:SetText(QuestAnnounce.db.profile.announceIn.whisperWho or "")
    channelNameBox:SetText(QuestAnnounce.db.profile.announceIn.channelName or "")
end

    -- Hauptpanel beim Anzeigen aktualisieren
    generalPanel:SetScript("OnShow", RefreshGeneralPanel)

    -- Hauptpanel in den Blizzard-Einstellungen registrieren
    local generalCategory = Settings.RegisterCanvasLayoutCategory(generalPanel, "QuestAnnounce")
    Settings.RegisterAddOnCategory(generalCategory)

    -- Diese Kategorie wird beim /qa-Befehl geöffnet
    self.optionsCategory = generalCategory

    -- =========================================================
    -- UNTERPANEL: Tooltip-Einstellungen
    -- =========================================================
    local tooltipPanel = CreateFrame("Frame")

       -- Titel des Tooltip-Unterfensters
    local tooltipTitle = tooltipPanel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    tooltipTitle:SetPoint("TOPLEFT", 16, -16)
    tooltipTitle:SetText(L["Tooltip Settings"])

    -- Beschreibung des Tooltip-Unterfensters
    local tooltipSubtitle = tooltipPanel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    tooltipSubtitle:SetPoint("TOPLEFT", tooltipTitle, "BOTTOMLEFT", 0, -8)
    tooltipSubtitle:SetWidth(700)
    tooltipSubtitle:SetJustifyH("LEFT")
    tooltipSubtitle:SetText(L["Settings to customize the tooltip appearance"])

    -- Beschriftung für Tooltip-Schriftart
    local tooltipFontLabel = tooltipPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    tooltipFontLabel:SetPoint("TOPLEFT", tooltipSubtitle, "BOTTOMLEFT", 4, -20)
    tooltipFontLabel:SetText(L["Tooltip Font"])

    -- Liste der auswählbaren Tooltip-Schriften
    local tooltipFonts = {
        "Friz Quadrata TT",
        "Arial Narrow",
        "Morpheus",
        "Skurri",
    }

    -- Dropdown zur Auswahl der Tooltip-Schriftart
    local tooltipFontDropdown = CreateDropdown(tooltipPanel, 180, 16, -90, tooltipFonts, function(value)
        QuestAnnounce.db.profile.tooltip.font = value
        if QuestAnnounce.UpdateTooltipBackground then
            QuestAnnounce:UpdateTooltipBackground()
        end
    end)

    -- Beschriftung für Tooltip-Schriftgröße
    local tooltipFontSizeLabel = tooltipPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    tooltipFontSizeLabel:SetPoint("TOPLEFT", tooltipSubtitle, "BOTTOMLEFT", 320, -20)
    tooltipFontSizeLabel:SetText(L["Tooltip Font Size"])

    -- Slider für Tooltip-Schriftgröße
    local tooltipFontSizeSlider = CreateFrame("Slider", nil, tooltipPanel, "OptionsSliderTemplate")
    tooltipFontSizeSlider:SetPoint("TOPLEFT", tooltipFontSizeLabel, "BOTTOMLEFT", 0, -8)
    tooltipFontSizeSlider:SetMinMaxValues(8, 20)
    tooltipFontSizeSlider:SetValueStep(1)
    tooltipFontSizeSlider:SetObeyStepOnDrag(true)
    tooltipFontSizeSlider:SetWidth(220)
    tooltipFontSizeSlider.Low:SetText("8")
    tooltipFontSizeSlider.High:SetText("20")
    tooltipFontSizeSlider.Text:SetText("")
    tooltipFontSizeSlider:SetScript("OnValueChanged", function(self, value)
        local rounded = math.floor(value + 0.5)
        if QuestAnnounce.db.profile.tooltip.fontSize ~= rounded then
            QuestAnnounce.db.profile.tooltip.fontSize = rounded
            if QuestAnnounce.UpdateTooltipBackground then
                QuestAnnounce:UpdateTooltipBackground()
            end
        end
    end)

    -- Einheitliche Breite für alle Tooltip-Buttons
    local tooltipButtonWidth = 260
    local tooltipButtonHeight = 24

    -- Button zum Ändern der Tooltip-Schriftfarbe
    local tooltipFontColorButton = CreateColorButton(tooltipPanel, L["Tooltip Font Color"], 16, -180, function(r, g, b)
        QuestAnnounce.db.profile.tooltip.fontColor = {r, g, b}
        if QuestAnnounce.UpdateTooltipBackground then
            QuestAnnounce:UpdateTooltipBackground()
        end
    end)
    tooltipFontColorButton:SetSize(tooltipButtonWidth, 22)

    -- Button zum Ändern der Tooltip-Hintergrundfarbe
    local tooltipBgColorButton = CreateColorButton(tooltipPanel, L["Tooltip Background Color"], 320, -180, function(r, g, b, a)
        QuestAnnounce.db.profile.tooltip.bgColor = {r, g, b, a}
        if QuestAnnounce.UpdateTooltipBackground then
            QuestAnnounce:UpdateTooltipBackground()
        end
    end)
    tooltipBgColorButton:SetSize(tooltipButtonWidth, 22)

    -- Button zum Zurücksetzen aller Tooltip-Einstellungen auf Standardwerte
    local tooltipResetButton = CreateButton(tooltipPanel, L["Reset Tooltip Settings"], tooltipButtonWidth, tooltipButtonHeight, 16, -220, function()
        QuestAnnounce.db.profile.tooltip.font = "Friz Quadrata TT"
        QuestAnnounce.db.profile.tooltip.fontSize = 12
        QuestAnnounce.db.profile.tooltip.fontColor = {0.11, 1, 0.3}
        QuestAnnounce.db.profile.tooltip.bgColor = {0, 0, 0, 0.8}
        QuestAnnounce.db.profile.tooltip.borderColor = {0, 0, 0, 0.8}

        if QuestAnnounce.UpdateTooltipBackground then
            QuestAnnounce:UpdateTooltipBackground()
        end

        local onShow = tooltipPanel:GetScript("OnShow")
        if onShow then
            onShow(tooltipPanel)
        end
    end)

    -- Button zum Zurücksetzen der Minimap-Button-Position
    local resetMinimapButton = CreateButton(tooltipPanel, L["Reset Minimap Button Position"], tooltipButtonWidth, tooltipButtonHeight, 320, -220, function()
        if QuestAnnounce.ResetMinimapButtonPosition then
            QuestAnnounce:ResetMinimapButtonPosition()
        end
    end)   
   
   
   

    -- Aktualisiert alle Werte im Tooltip-Panel beim Öffnen
    local function RefreshTooltipPanel()
        if not QuestAnnounce.db or not QuestAnnounce.db.profile then
            return
        end

        UIDropDownMenu_SetSelectedName(tooltipFontDropdown, QuestAnnounce.db.profile.tooltip.font or "Friz Quadrata TT")
        tooltipFontSizeSlider:SetValue(QuestAnnounce.db.profile.tooltip.fontSize or 12)

        local fontColor = QuestAnnounce.db.profile.tooltip.fontColor or {0.11, 1, 0.3}
        tooltipFontColorButton.r = fontColor[1]
        tooltipFontColorButton.g = fontColor[2]
        tooltipFontColorButton.b = fontColor[3]
        tooltipFontColorButton.a = 1
        tooltipFontColorButton.swatch:SetColorTexture(fontColor[1], fontColor[2], fontColor[3], 1)

        local bgColor = QuestAnnounce.db.profile.tooltip.bgColor or {0, 0, 0, 0.8}
        tooltipBgColorButton.r = bgColor[1]
        tooltipBgColorButton.g = bgColor[2]
        tooltipBgColorButton.b = bgColor[3]
        tooltipBgColorButton.a = bgColor[4] or 0.8
        tooltipBgColorButton.swatch:SetColorTexture(bgColor[1], bgColor[2], bgColor[3], bgColor[4] or 0.8)
    end

    -- Tooltip-Panel beim Anzeigen aktualisieren
    tooltipPanel:SetScript("OnShow", RefreshTooltipPanel)

	-- Tooltip-Unterfenster als echte Unterkategorie registrieren
	local tooltipCategory = Settings.RegisterCanvasLayoutSubcategory(generalCategory, tooltipPanel, L["Tooltip Settings"])
	Settings.RegisterAddOnCategory(tooltipCategory)
	
	-- Speichert optional auch die Tooltip-Kategorie für spätere Nutzung
    self.tooltipOptionsCategory = tooltipCategory

    -- Slash-Befehl /qa registrieren, um die Einstellungen zu öffnen
    SLASH_QUESTANNOUNCE1 = "/qa"
    SlashCmdList["QUESTANNOUNCE"] = openConfig
	
	-- Conten-Höhe
	content:SetHeight(760) -- ggf. anpassen!
	
	-- Scrollbar etwas nach innen:
	scrollFrame.ScrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", -16, -16)
	scrollFrame.ScrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", -16, 16)
	
end


-- Popup-Dialog, der angezeigt wird, wenn ein benutzerdefinierter Kanal aktiviert wird,
-- aber noch kein Kanalname eingetragen wurde.
StaticPopupDialogs["MISSING_CHANNEL_NAME"] = {
    text = L["Please enter a channel name."],
    button1 = OKAY,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

