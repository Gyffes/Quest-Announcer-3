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

    -- ---------------------------------------------------------
    -- Tooltip-Helfer
    -- ---------------------------------------------------------

    -- Liefert die aktuell konfigurierten Tooltip-Einstellungen mit Fallbacks
    local function GetTooltipSettings()
        local tooltipDB = QuestAnnounce
            and QuestAnnounce.db
            and QuestAnnounce.db.profile
            and QuestAnnounce.db.profile.tooltip

        if not tooltipDB then
            return {
                font = "Friz Quadrata TT",
                fontSize = 12,
                fontColor = {0.11, 1, 0.3},
                bgColor = {0, 0, 0, 0.8},
                borderColor = {0, 0, 0, 0.8},
            }
        end

        return {
            font = tooltipDB.font or "Friz Quadrata TT",
            fontSize = tooltipDB.fontSize or 12,
            fontColor = tooltipDB.fontColor or {0.11, 1, 0.3},
            bgColor = tooltipDB.bgColor or {0, 0, 0, 0.8},
            borderColor = tooltipDB.borderColor or {0, 0, 0, 0.8},
        }
    end

    -- Wendet die gespeicherten Tooltip-Stile auf ein Tooltip-Frame an
    local function ApplyConfiguredTooltipStyle(tooltip)
        if not tooltip then
            return
        end

        local settings = GetTooltipSettings()

        local font = settings.font
        local fontSize = settings.fontSize
        local fontColor = settings.fontColor
        local bgColor = settings.bgColor
        local borderColor = settings.borderColor

        -- Hintergrund / Rahmen
        if tooltip.SetBackdropColor then
            tooltip:SetBackdropColor(
                bgColor[1] or 0,
                bgColor[2] or 0,
                bgColor[3] or 0,
                bgColor[4] or 0.8
            )
        end

        if tooltip.SetBackdropBorderColor then
            tooltip:SetBackdropBorderColor(
                borderColor[1] or 0,
                borderColor[2] or 0,
                borderColor[3] or 0,
                borderColor[4] or 0.8
            )
        end

        -- FontObject für die Tooltip-Zeilen aktualisieren
        local name = tooltip:GetName()
        if name then
            for i = 1, 30 do
                local left = _G[name .. "TextLeft" .. i]
                local right = _G[name .. "TextRight" .. i]

                if left then
                    left:SetFont(font, fontSize)
                    left:SetTextColor(
                        fontColor[1] or 1,
                        fontColor[2] or 1,
                        fontColor[3] or 1
                    )
                end

                if right then
                    right:SetFont(font, fontSize)
                    right:SetTextColor(
                        fontColor[1] or 1,
                        fontColor[2] or 1,
                        fontColor[3] or 1
                    )
                end
            end
        end
    end

    -- Fügt einem UI-Element einen Hover-Tooltip hinzu
    local function AttachTooltip(widget, title, text)
        if not widget then
            return
        end

        widget:HookScript("OnEnter", function(self)
            ApplyConfiguredTooltipStyle(GameTooltip)

            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")

            local settings = GetTooltipSettings()
            local fontColor = settings.fontColor or {1, 1, 1}

            GameTooltip:ClearLines()
            GameTooltip:SetText(
                title or "",
                fontColor[1] or 1,
                fontColor[2] or 1,
                fontColor[3] or 1
            )

            if text and text ~= "" then
                GameTooltip:AddLine(
                    text,
                    fontColor[1] or 1,
                    fontColor[2] or 1,
                    fontColor[3] or 1,
                    true
                )
            end

            ApplyConfiguredTooltipStyle(GameTooltip)
            GameTooltip:Show()
        end)

        widget:HookScript("OnLeave", function()
            GameTooltip:Hide()
        end)
    end

    -- ---------------------------------------------------------
    -- UI-Helfer
    -- ---------------------------------------------------------

    -- Hilfsfunktion: Erstellt eine Checkbox an einer festen Position
    local function CreateCheckbox(parent, text, x, y, onClick, tooltipTitle, tooltipText)
        local cb = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
        cb:SetPoint("TOPLEFT", x, y)
        cb.Text:SetText(text)
        cb:SetScript("OnClick", onClick)

        AttachTooltip(cb, tooltipTitle or text, tooltipText)
        if cb.Text then
            AttachTooltip(cb.Text, tooltipTitle or text, tooltipText)
        end

        return cb
    end

    -- Hilfsfunktion: Erstellt ein Eingabefeld für Texte
    local function CreateEditBox(parent, width, height, x, y, tooltipTitle, tooltipText)
        local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
        box:SetSize(width, height)
        box:SetPoint("TOPLEFT", x, y)
        box:SetAutoFocus(false)

        AttachTooltip(box, tooltipTitle, tooltipText)

        return box
    end

local function CreateButton(parent, text, width, height, x, y, onClick, tooltipTitle, tooltipText)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetPoint("TOPLEFT", x, y)
    button:SetText(text)
    button:SetScript("OnClick", onClick)

    -- 🔥 AUTO WIDTH
    local padding = 20
    local textWidth = button.Text:GetStringWidth()
    local finalWidth = math.max(width or 80, textWidth + padding)

    button:SetSize(finalWidth, height or 22)

    AttachTooltip(button, tooltipTitle or text, tooltipText)

    return button
end

    -- Hilfsfunktion: Erstellt ein Dropdown-Menü mit einer Liste von Einträgen
    local function CreateDropdown(parent, width, x, y, items, onSelect, tooltipTitle, tooltipText)
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

        AttachTooltip(dropdown, tooltipTitle, tooltipText)

        return dropdown
    end

    -- Hilfsfunktion: Erstellt einen Button mit Farbvorschau.
    -- Beim Klick öffnet sich der Blizzard-Farbwähler.
    local function CreateColorButton(parent, text, x, y, onColorChanged, tooltipTitle, tooltipText)
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

        AttachTooltip(button, tooltipTitle or text, tooltipText)

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
	    AttachTooltip(
        settingsHeader,
        L["Settings"],
        L["General settings for QuestAnnounce."]
    )

    -- Addon aktivieren / deaktivieren
    local enableCheckbox = CreateCheckbox(
        content,
        L["Enable"],
        16,
        -90,
        function(self)
            QuestAnnounce.db.profile.settings.enable = self:GetChecked() and true or false
            QuestAnnounce:SendDebugMsg("setSettings: enable :: " .. tostring(QuestAnnounce.db.profile.settings.enable))
        end,
        L["Enable"],
        L["Enable or disable the addon."]
    )

	
    -- Quest-Links aktivieren / deaktivieren
    local linkQuestCheckbox = CreateCheckbox(
        content,
        L["Enable Quest Links"],
        420,
        -90,
        function(self)
            QuestAnnounce.db.profile.settings.linkQuest = self:GetChecked() and true or false
            QuestAnnounce:SendDebugMsg("setSettings: linkQuest :: " .. tostring(QuestAnnounce.db.profile.settings.linkQuest))
        end,
        L["Enable Quest Links"],
        L["Show quest titles as clickable quest links in announcements."]
    )
	
    -- Debug-Modus aktivieren / deaktivieren
    local debugCheckbox = CreateCheckbox(
        content,
        L["Debug"],
        220,
        -90,
        function(self)
            QuestAnnounce.db.profile.settings.debug = self:GetChecked() and true or false
            QuestAnnounce:SendDebugMsg("setSettings: debug :: " .. tostring(QuestAnnounce.db.profile.settings.debug))
        end,
        L["Debug"],
        L["Enable debug messages in the chat frame."]
    )



-- Trennlinie zwischen Haupt-Einstellung und Sound Settings 
	local separator = content:CreateTexture(nil, "ARTWORK")
	separator:SetColorTexture(0.5, 0.5, 0.5, 0.6)
	separator:SetHeight(1)
	separator:SetPoint("TOPLEFT", content, "TOPLEFT", 16, -160)
	separator:SetPoint("TOPRIGHT", content, "TOPRIGHT", -16, -160)

-- ==============================
-- Sound Settings Bereich
-- ==============================

local soundHeader = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
soundHeader:SetPoint("TOPLEFT", content, "TOPLEFT", 16, -180)
soundHeader:SetText(L["Sound Settings"])

AttachTooltip(
    soundHeader,
    L["Sound Settings"],
    L["Configure quest progress and completion sounds."]
)

local soundCheckbox = CreateCheckbox(
    content,
    "",
    16,
    -210,
    function(self)
        QuestAnnounce.db.profile.settings.sound = self:GetChecked() and true or false

        if self.Text then
            if QuestAnnounce.db.profile.settings.sound then
                self.Text:SetText(L["Sound On"])
            else
                self.Text:SetText(L["Sound Off"])
            end
        end

        QuestAnnounce:SendDebugMsg("setSettings: sound :: " .. tostring(QuestAnnounce.db.profile.settings.sound))
    end,
    L["Sound"],
    L["Enable or disable all quest announcement sounds."]
)

if soundCheckbox.Text then
    if QuestAnnounce.db.profile.settings.sound then
        soundCheckbox.Text:SetText(L["Sound On"])
    else
        soundCheckbox.Text:SetText(L["Sound Off"])
    end
end

AttachTooltip(
    soundCheckbox,
    L["Sound"],
    L["Enable or disable all quest announcement sounds."]
)

if soundCheckbox.Text then
    AttachTooltip(
        soundCheckbox.Text,
        L["Sound"],
        L["Enable or disable all quest announcement sounds."]
    )
end

local progressLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
progressLabel:SetPoint("TOPLEFT", content, "TOPLEFT", 16, -246)
progressLabel:SetText(L["Progress Sound ID"])
AttachTooltip(
    progressLabel,
    L["Progress Sound ID"],
    L["Sound ID played for quest progress updates."]
)

local progressBox = CreateEditBox(
    content,
    90,
    20,
    16,
    -268,
    L["Progress Sound ID"],
    L["Sound ID played for quest progress updates."]
)
progressBox:SetNumeric(true)
progressBox:SetMaxLetters(10)
progressBox:SetNumber(tonumber(QuestAnnounce.db.profile.settings.progressSound or 8959))
progressBox:SetScript("OnEnterPressed", function(self)
    local val = tonumber(self:GetText())
    if val then
        QuestAnnounce.db.profile.settings.progressSound = val
        self:SetText(tostring(val))
    else
        self:SetText(tostring(QuestAnnounce.db.profile.settings.progressSound or 8959))
    end
    self:ClearFocus()
end)
progressBox:SetScript("OnEditFocusLost", function(self)
    local val = tonumber(self:GetText())
    if val then
        QuestAnnounce.db.profile.settings.progressSound = val
        self:SetText(tostring(val))
    else
        self:SetText(tostring(QuestAnnounce.db.profile.settings.progressSound or 8959))
    end
end)

local resetProgress = CreateButton(
    content,
    L["Reset"],
    70,
    22,
    120,
    -268,
    function()
        QuestAnnounce.db.profile.settings.progressSound = 8959
        progressBox:SetNumber(8959)
    end,
    L["Reset Progress Sound"],
    L["Reset the progress sound ID to default."]
)
resetProgress:ClearAllPoints()
resetProgress:SetPoint("LEFT", progressBox, "RIGHT", 12, 0)

local testProgressSound = CreateButton(
    content,
    L["Test Progress Sound"],
    180,
    22,
    210,
    -268,
    function()
        local soundID = QuestAnnounce.db.profile.settings.progressSound or 8959
        PlaySound(soundID, "Master")
        QuestAnnounce:SendDebugMsg("Test Progress Sound :: " .. tostring(soundID))
    end,
    L["Test Progress Sound"],
    L["Play the current progress sound."]
)
testProgressSound:ClearAllPoints()
testProgressSound:SetPoint("LEFT", resetProgress, "RIGHT", 12, 0)

local completeLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
completeLabel:SetPoint("TOPLEFT", content, "TOPLEFT", 16, -304)
completeLabel:SetText(L["Completion Sound ID"])
AttachTooltip(
    completeLabel,
    L["Completion Sound ID"],
    L["Sound ID played when a quest is completed."]
)

local completeBox = CreateEditBox(
    content,
    90,
    20,
    16,
    -326,
    L["Completion Sound ID"],
    L["Sound ID played when a quest is completed."]
)
completeBox:SetNumeric(true)
completeBox:SetMaxLetters(10)
completeBox:SetNumber(tonumber(QuestAnnounce.db.profile.settings.completeSound or 6199))
completeBox:SetScript("OnEnterPressed", function(self)
    local val = tonumber(self:GetText())
    if val then
        QuestAnnounce.db.profile.settings.completeSound = val
        self:SetText(tostring(val))
    else
        self:SetText(tostring(QuestAnnounce.db.profile.settings.completeSound or 6199))
    end
    self:ClearFocus()
end)
completeBox:SetScript("OnEditFocusLost", function(self)
    local val = tonumber(self:GetText())
    if val then
        QuestAnnounce.db.profile.settings.completeSound = val
        self:SetText(tostring(val))
    else
        self:SetText(tostring(QuestAnnounce.db.profile.settings.completeSound or 6199))
    end
end)

local resetComplete = CreateButton(
    content,
    L["Reset"],
    70,
    22,
    120,
    -326,
    function()
        QuestAnnounce.db.profile.settings.completeSound = 6199
        completeBox:SetNumber(6199)
    end,
    L["Reset Completion Sound"],
    L["Reset the completion sound ID to default."]
)
resetComplete:ClearAllPoints()
resetComplete:SetPoint("LEFT", completeBox, "RIGHT", 12, 0)

local testCompleteSound = CreateButton(
    content,
    L["Test Complete Sound"],
    180,
    22,
    210,
    -326,
    function()
        local soundID = QuestAnnounce.db.profile.settings.completeSound or 6199
        PlaySound(soundID, "Master")
        QuestAnnounce:SendDebugMsg("Test Complete Sound :: " .. tostring(soundID))
    end,
    L["Test Complete Sound"],
    L["Play the current completion sound."]
)
testCompleteSound:ClearAllPoints()
testCompleteSound:SetPoint("LEFT", resetComplete, "RIGHT", 12, 0)

local soundSeparator = content:CreateTexture(nil, "ARTWORK")
soundSeparator:SetColorTexture(0.5, 0.5, 0.5, 0.6)
soundSeparator:SetHeight(1)
soundSeparator:SetPoint("TOPLEFT", content, "TOPLEFT", 16, -365)
soundSeparator:SetPoint("TOPRIGHT", content, "TOPRIGHT", -16, -365)

	-- Slider für die Anzahl der Fortschrittsmeldungen
	local everySlider = CreateFrame("Slider", nil, content, "OptionsSliderTemplate")
	everySlider:SetPoint("TOPLEFT", content, "TOPLEFT", 60, -410)
	everySlider:SetMinMaxValues(0, 100)
	everySlider:SetValueStep(1)
	everySlider:SetObeyStepOnDrag(true)
	everySlider:SetWidth(260)
	everySlider.Low:SetText("0")
	everySlider.High:SetText("100")
	everySlider.Text:SetText("")

    AttachTooltip(
        everySlider,
        L["Announce Every"],
        L["Set how often progress updates should be announced. Value range: 0 to 100."]
    )

	-- Eingabefeld für numerische Eingabe der Fortschritts-Ankündigung
	local everyInput = CreateEditBox(
        content,
        60,
        20,
        0,
        0,
        L["Announce Every"],
        L["Set how often progress updates should be announced. Value range: 0 to 100."]
    )
	everyInput:ClearAllPoints()
	everyInput:SetPoint("LEFT", everySlider, "RIGHT", 28, 0)
	everyInput:SetSize(70, 20)
	everyInput:SetNumeric(true)
	everyInput:SetMaxLetters(3)
	everyInput:SetNumber(tonumber(QuestAnnounce.db.profile.settings.every or 1))

	-- Beschriftung für das Eingabefeld
	local everyInputLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	everyInputLabel:SetPoint("BOTTOM", everyInput, "TOP", 0, 6)
	everyInputLabel:SetText(L["Value"])

    AttachTooltip(
        everyInputLabel,
        L["Announce Every"],
        L["Set how often progress updates should be announced. Value range: 0 to 100."]
    )

	-- Beschriftung für die Fortschritts-Ankündigung
    local everyLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    everyLabel:SetPoint("BOTTOM", everySlider, "TOP", 0, 14)
    everyLabel:SetText(L["Announce Every"])

    AttachTooltip(
        everyLabel,
        L["Announce Every"],
        L["Set how often progress updates should be announced. Value range: 0 to 100."]
    )

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

		if tonumber(everyInput:GetText()) ~= rounded then
			everyInput:SetNumber(rounded)
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
		self:SetNumber(value)
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
		self:SetNumber(value)

		QuestAnnounce:SendDebugMsg("setSettings: every :: " .. tostring(value))
	end)

	-- Trennlinie über dem Announce-Bereich
	local separator2 = content:CreateTexture(nil, "ARTWORK")
	separator2:SetColorTexture(0.5, 0.5, 0.5, 0.6)
	separator2:SetHeight(1)
	separator2:SetPoint("TOPLEFT", content, "TOPLEFT", 16, -458)
	separator2:SetPoint("TOPRIGHT", content, "TOPRIGHT", -16, -458)

    -- Überschrift für die Ziele der Ausgabe
        -- Überschrift für die Ziele der Ausgabe
    local announceToHeader = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    announceToHeader:SetPoint("TOPLEFT", content, "TOPLEFT", 16, -480)
    announceToHeader:SetText(L["Where do you want to make the announcements?"])
    AttachTooltip(
        announceToHeader,
        L["Where do you want to make the announcements?"],
        L["Choose where QuestAnnounce should display messages."]
    )

    -- Chatfenster-Ausgabe
    local chatFrameCheckbox = CreateCheckbox(
        content,
        L["Chat Frame"],
        16,
        -514,
        function(self)
            QuestAnnounce.db.profile.announceTo.chatFrame = self:GetChecked() and true or false
            QuestAnnounce:SendDebugMsg("setAnnounceTo: chatFrame :: " .. tostring(QuestAnnounce.db.profile.announceTo.chatFrame))
        end,
        L["Chat Frame"],
        L["Send announcements to chat channels such as party, guild, whisper, or custom channel."]
    )

    -- Raid-Warning-Ausgabe
    local raidWarningCheckbox = CreateCheckbox(
        content,
        L["Raid Warning Frame"],
        220,
        -514,
        function(self)
            QuestAnnounce.db.profile.announceTo.raidWarningFrame = self:GetChecked() and true or false
            QuestAnnounce:SendDebugMsg("setAnnounceTo: raidWarningFrame :: " .. tostring(QuestAnnounce.db.profile.announceTo.raidWarningFrame))
        end,
        L["Raid Warning Frame"],
        L["Show announcements in the Raid Warning frame."]
    )

    -- UIErrorsFrame-Ausgabe
    local uiErrorsCheckbox = CreateCheckbox(
        content,
        L["UI Errors Frame"],
        440,
        -514,
        function(self)
            QuestAnnounce.db.profile.announceTo.uiErrorsFrame = self:GetChecked() and true or false
            QuestAnnounce:SendDebugMsg("setAnnounceTo: uiErrorsFrame :: " .. tostring(QuestAnnounce.db.profile.announceTo.uiErrorsFrame))
        end,
        L["UI Errors Frame"],
        L["Show announcements in the UI error message area."]
    )

	-- Trennlinie zwischen Ausgabezielen und Chatkanälen
	-- Etwas mehr Abstand unter den Ausgabe-Checkboxen
	local separator3 = content:CreateTexture(nil, "ARTWORK")
	separator3:SetColorTexture(0.5, 0.5, 0.5, 0.6)
	separator3:SetHeight(1)
	separator3:SetPoint("TOPLEFT", content, "TOPLEFT", 16, -562)
	separator3:SetPoint("TOPRIGHT", content, "TOPRIGHT", -16, -562)
	
        -- Überschrift für die Chatkanäle linksbündig und näher an den Checkboxen
    local announceInHeader = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    announceInHeader:SetPoint("TOPLEFT", content, "TOPLEFT", 16, -588)
    announceInHeader:SetText(L["What channels do you want to make the announcements?"])
    AttachTooltip(
        announceInHeader,
        L["What channels do you want to make the announcements?"],
        L["Choose which chat channels QuestAnnounce should use."]
    )

    -- Linke Spalte: Say / Party / Instance
    local sayCheckbox = CreateCheckbox(
        content,
        L["Say"],
        16,
        -618,
        function(self)
            QuestAnnounce.db.profile.announceIn.say = self:GetChecked() and true or false
            QuestAnnounce:SendDebugMsg("setAnnounceIn: say :: " .. tostring(QuestAnnounce.db.profile.announceIn.say))
        end,
        L["Say"],
        L["Send announcements to the /say channel."]
    )

    local partyCheckbox = CreateCheckbox(
        content,
        L["Party"],
        16,
        -648,
        function(self)
            QuestAnnounce.db.profile.announceIn.party = self:GetChecked() and true or false
            QuestAnnounce:SendDebugMsg("setAnnounceIn: party :: " .. tostring(QuestAnnounce.db.profile.announceIn.party))
        end,
        L["Party"],
        L["Send announcements to your party chat."]
    )

    local instanceCheckbox = CreateCheckbox(
        content,
        L["Instance"],
        16,
        -678,
        function(self)
            QuestAnnounce.db.profile.announceIn.instance = self:GetChecked() and true or false
            QuestAnnounce:SendDebugMsg("setAnnounceIn: instance :: " .. tostring(QuestAnnounce.db.profile.announceIn.instance))
        end,
        L["Instance"],
        L["Send announcements to the instance chat channel when available."]
    )

    -- Mittlere Spalte: Officer / Focus / Gilde
    local officerCheckbox = CreateCheckbox(
        content,
        L["Officer"],
        220,
        -618,
        function(self)
            QuestAnnounce.db.profile.announceIn.officer = self:GetChecked() and true or false
            QuestAnnounce:SendDebugMsg("setAnnounceIn: officer :: " .. tostring(QuestAnnounce.db.profile.announceIn.officer))
        end,
        L["Officer"],
        L["Send announcements to the guild officer chat."]
    )

    local focusCheckbox = CreateCheckbox(
        content,
        L["Focus"],
        220,
        -648,
        function(self)
            QuestAnnounce.db.profile.announceIn.focus = self:GetChecked() and true or false
            QuestAnnounce:SendDebugMsg("setAnnounceIn: focus :: " .. tostring(QuestAnnounce.db.profile.announceIn.focus))
        end,
        L["Focus"],
        L["Send announcements as whispers to your current focus target."]
    )

    local guildCheckbox = CreateCheckbox(
        content,
        L["Guild"],
        220,
        -678,
        function(self)
            QuestAnnounce.db.profile.announceIn.guild = self:GetChecked() and true or false
            QuestAnnounce:SendDebugMsg("setAnnounceIn: guild :: " .. tostring(QuestAnnounce.db.profile.announceIn.guild))
        end,
        L["Guild"],
        L["Send announcements to guild chat."]
    )

    -- Zeile 4: Flüstern + An wen flüstern + Eingabefeld
    local whisperCheckbox = CreateCheckbox(
        content,
        L["Whisper"],
        16,
        -728,
        function(self)
            QuestAnnounce.db.profile.announceIn.whisper = self:GetChecked() and true or false
            QuestAnnounce:SendDebugMsg("setAnnounceIn: whisper :: " .. tostring(QuestAnnounce.db.profile.announceIn.whisper))
        end,
        L["Whisper"],
        L["Send announcements as whispers to the character entered in Whisper Who."]
    )

    local whisperWhoLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    whisperWhoLabel:SetPoint("LEFT", whisperCheckbox, "RIGHT", 180, 0)
    whisperWhoLabel:SetText(L["Whisper Who"])

    AttachTooltip(
        whisperWhoLabel,
        L["Whisper Who"],
        L["Enter the name of the character that should receive whisper announcements."]
    )

    local whisperWhoBox = CreateEditBox(
        content,
        150,
        20,
        0,
        0,
        L["Whisper Who"],
        L["Enter the name of the character that should receive whisper announcements."]
    )
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
    local channelCheckbox = CreateCheckbox(
        content,
        L["Channel"],
        16,
        -758,
        function(self)
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
        end,
        L["Channel"],
        L["Send announcements to a custom chat channel."]
    )

    local channelNameLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    channelNameLabel:SetPoint("LEFT", channelCheckbox, "RIGHT", 180, 0)
    channelNameLabel:SetText(L["Channel Name"])

    AttachTooltip(
        channelNameLabel,
        L["Channel Name"],
        L["Enter the name of the custom channel used for announcements."]
    )

    local channelNameBox = CreateEditBox(
        content,
        150,
        20,
        0,
        0,
        L["Channel Name"],
        L["Enter the name of the custom channel used for announcements."]
    )
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
    local testButton = CreateButton(
        content,
        L["Test Frame Messages"],
        180,
        24,
        220,
        -120,
        function()
            QuestAnnounce:SendMsg(L["QuestAnnounce Test Message"])
        end,
        L["Test Frame Messages"],
        L["Send a test message using the currently selected output settings."]
    )

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

    if soundCheckbox.Text then
        if QuestAnnounce.db.profile.settings.sound then
            soundCheckbox.Text:SetText(L["Sound On"])
        else
            soundCheckbox.Text:SetText(L["Sound Off"])
        end
    end

	progressBox:SetNumber(tonumber(QuestAnnounce.db.profile.settings.progressSound or 8959))
	completeBox:SetNumber(tonumber(QuestAnnounce.db.profile.settings.completeSound or 6199))

	everySlider:SetValue(tonumber(QuestAnnounce.db.profile.settings.every or 1))
	everyInput:SetNumber(tonumber(QuestAnnounce.db.profile.settings.every or 1))

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
    generalPanel:HookScript("OnShow", RefreshGeneralPanel)

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

    -- Einheitliche Breite und Höhe für Tooltip-Buttons
    local tooltipButtonWidth = 260
    local tooltipButtonHeight = 24

    -- Beschriftung für Tooltip-Schriftart
    local tooltipFontLabel = tooltipPanel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    tooltipFontLabel:SetPoint("TOPLEFT", tooltipSubtitle, "BOTTOMLEFT", 4, -20)
    tooltipFontLabel:SetText(L["Tooltip Font"])
	
	AttachTooltip(
        tooltipFontLabel,
        L["Tooltip Font"],
        L["Select the font used for QuestAnnounce tooltips."]
    )

    -- Liste der auswählbaren Tooltip-Schriften
    local tooltipFonts = {
        "Friz Quadrata TT",
        "Arial Narrow",
        "Morpheus",
        "Skurri",
    }

    -- Dropdown zur Auswahl der Tooltip-Schriftart
    local tooltipFontDropdown = CreateDropdown(
        tooltipPanel,
        180,
        16,
        -90,
        tooltipFonts,
        function(value)
            QuestAnnounce.db.profile.tooltip.font = value
            if QuestAnnounce.UpdateTooltipBackground then
                QuestAnnounce:UpdateTooltipBackground()
            end
        end,
        L["Tooltip Font"],
        L["Select the font used for QuestAnnounce tooltips."]
    )

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
	
	    AttachTooltip(
        tooltipFontSizeSlider,
        L["Tooltip Font Size"],
        L["Set the font size used for QuestAnnounce tooltips."]
    )

    AttachTooltip(
        tooltipFontSizeLabel,
        L["Tooltip Font Size"],
        L["Set the font size used for QuestAnnounce tooltips."]
    )

    -- Button zum Ändern der Tooltip-Schriftfarbe
    local tooltipFontColorButton = CreateColorButton(
        tooltipPanel,
        L["Tooltip Font Color"],
        16,
        -180,
        function(r, g, b)
            QuestAnnounce.db.profile.tooltip.fontColor = {r, g, b}
            if QuestAnnounce.UpdateTooltipBackground then
                QuestAnnounce:UpdateTooltipBackground()
            end
        end,
        L["Tooltip Font Color"],
        L["Choose the font color used for QuestAnnounce tooltips."]
    )
    tooltipFontColorButton:SetSize(tooltipButtonWidth, tooltipButtonHeight)

    -- Button zum Ändern der Tooltip-Hintergrundfarbe
    local tooltipBgColorButton = CreateColorButton(
        tooltipPanel,
        L["Tooltip Background Color"],
        320,
        -180,
        function(r, g, b, a)
            QuestAnnounce.db.profile.tooltip.bgColor = {r, g, b, a}
            if QuestAnnounce.UpdateTooltipBackground then
                QuestAnnounce:UpdateTooltipBackground()
            end
        end,
        L["Tooltip Background Color"],
        L["Choose the background color and transparency used for QuestAnnounce tooltips."]
    )
    tooltipBgColorButton:SetSize(tooltipButtonWidth, tooltipButtonHeight)

    -- Vorwärtsdeklaration für spätere Nutzung im Reset-Button
    local RefreshTooltipPanel

    -- Aktualisiert alle Werte im Tooltip-Panel beim Öffnen
    -- Dadurch werden gespeicherte Schriftarten, Größen und Farben korrekt
    -- aus der Datenbank in die sichtbaren UI-Elemente übernommen.
    RefreshTooltipPanel = function()
        if not QuestAnnounce.db or not QuestAnnounce.db.profile or not QuestAnnounce.db.profile.tooltip then
            return
        end

        local tooltipDB = QuestAnnounce.db.profile.tooltip

        -- Gespeicherte Schriftart im Dropdown anzeigen
        UIDropDownMenu_SetSelectedName(tooltipFontDropdown, tooltipDB.font or "Friz Quadrata TT")

        -- Gespeicherte Schriftgröße im Slider anzeigen
        tooltipFontSizeSlider:SetValue(tooltipDB.fontSize or 12)

        -- Gespeicherte Schriftfarbe in den Farbbutton übernehmen
        local fontColor = tooltipDB.fontColor or {0.11, 1, 0.3}
        tooltipFontColorButton.r = fontColor[1] or 0.11
        tooltipFontColorButton.g = fontColor[2] or 1
        tooltipFontColorButton.b = fontColor[3] or 0.3
        tooltipFontColorButton.a = 1
        tooltipFontColorButton.swatch:SetColorTexture(
            tooltipFontColorButton.r,
            tooltipFontColorButton.g,
            tooltipFontColorButton.b,
            1
        )

        -- Gespeicherte Hintergrundfarbe in den Farbbutton übernehmen
        local bgColor = tooltipDB.bgColor or {0, 0, 0, 0.8}
        tooltipBgColorButton.r = bgColor[1] or 0
        tooltipBgColorButton.g = bgColor[2] or 0
        tooltipBgColorButton.b = bgColor[3] or 0
        tooltipBgColorButton.a = bgColor[4] or 0.8
        tooltipBgColorButton.swatch:SetColorTexture(
            tooltipBgColorButton.r,
            tooltipBgColorButton.g,
            tooltipBgColorButton.b,
            tooltipBgColorButton.a
        )
    end

    -- Button zum Zurücksetzen aller Tooltip-Einstellungen auf Standardwerte
    local tooltipResetButton = CreateButton(
        tooltipPanel,
        L["Reset Tooltip Settings"],
        tooltipButtonWidth,
        tooltipButtonHeight,
        16,
        -220,
        function()
            QuestAnnounce.db.profile.tooltip.font = "Friz Quadrata TT"
            QuestAnnounce.db.profile.tooltip.fontSize = 12
            QuestAnnounce.db.profile.tooltip.fontColor = {0.11, 1, 0.3}
            QuestAnnounce.db.profile.tooltip.bgColor = {0, 0, 0, 0.8}
            QuestAnnounce.db.profile.tooltip.borderColor = {0, 0, 0, 0.8}

            if QuestAnnounce.UpdateTooltipBackground then
                QuestAnnounce:UpdateTooltipBackground()
            end

            RefreshTooltipPanel()
        end,
        L["Reset Tooltip Settings"],
        L["Reset all tooltip appearance settings to their default values."]
    )

    -- Button zum Zurücksetzen der Minimap-Button-Position
    local resetMinimapButton = CreateButton(
        tooltipPanel,
        L["Reset Minimap Button Position"],
        tooltipButtonWidth,
        tooltipButtonHeight,
        320,
        -220,
        function()
            if QuestAnnounce.ResetMinimapButtonPosition then
                QuestAnnounce:ResetMinimapButtonPosition()
            end
        end,
        L["Reset Minimap Button Position"],
        L["Reset the minimap button to its default position."]
    )

    -- Tooltip-Panel beim Anzeigen aktualisieren
    tooltipPanel:HookScript("OnShow", RefreshTooltipPanel)

    -- Tooltip-Unterfenster als echte Unterkategorie registrieren
    local tooltipCategory = Settings.RegisterCanvasLayoutSubcategory(generalCategory, tooltipPanel, L["Tooltip Settings"])
    Settings.RegisterAddOnCategory(tooltipCategory)

    -- Speichert optional auch die Tooltip-Kategorie für spätere Nutzung
    self.tooltipOptionsCategory = tooltipCategory

    -- Slash-Befehl /qa registrieren, um die Einstellungen zu öffnen
    SLASH_QUESTANNOUNCE1 = "/qa"
    SlashCmdList["QUESTANNOUNCE"] = openConfig
	
	-- Conten-Höhe
	content:SetHeight(1080) -- ggf. anpassen!
	
	-- Scrollbar etwas nach innen:
	scrollFrame.ScrollBar:SetPoint("TOPLEFT", scrollFrame, "TOPRIGHT", -16, -16)
	scrollFrame.ScrollBar:SetPoint("BOTTOMLEFT", scrollFrame, "BOTTOMRIGHT", -16, 16)
	
	RefreshGeneralPanel()
	RefreshTooltipPanel()
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

