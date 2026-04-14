-- Minimap.lua
-- Referenz auf das Haupt-Addon und die Lokalisierung
local QuestAnnounce = _G["QuestAnnounce"]
local L = QuestAnnounce_L[GetLocale()] or QuestAnnounce_L["enUS"]


-- Funktion zur Erstellung des Minimap-Buttons
function QuestAnnounce:InitializeMinimapButton()
    -- Verhindert, dass der Minimap-Button mehrfach erstellt wird
    if self.minimapButton then
        return
    end

    QuestAnnounce:SendDebugMsg("Initialisiere Minimap-Button...") -- Debugging-Ausgabe

	local MinimapButton = CreateFrame("Button", "QuestAnnounceMinimapButton", Minimap)
	self.minimapButton = MinimapButton
    MinimapButton:SetSize(32, 32)  -- Größe des Buttons
    MinimapButton:SetFrameStrata("MEDIUM")
    MinimapButton:SetFrameLevel(8)

    local icon = MinimapButton:CreateTexture(nil, "BACKGROUND")
    icon:SetTexture("Interface\\AddOns\\QuestAnnounce\\Media\\QA3Icon")  -- Pfad zur gespeicherten Grafik
    icon:SetSize(28, 28)
    icon:SetPoint("CENTER")
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    -- Rundes Masking, damit kein eckiger Hintergrund sichtbar ist
    local iconMask = MinimapButton:CreateMaskTexture()
    iconMask:SetTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    iconMask:SetPoint("CENTER", icon, "CENTER")
    iconMask:SetSize(28, 28)
    icon:AddMaskTexture(iconMask)

    MinimapButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

	-- Mach das Frame beweglich
	MinimapButton:SetMovable(true)
	MinimapButton:EnableMouse(true)

	-- Dragging functionality
	MinimapButton:RegisterForDrag("LeftButton")
	MinimapButton:SetScript("OnDragStart", function(self)
		if self:IsMovable() then
			self:StartMoving()
		end
	end)

	-- Beendet das Ziehen des Buttons und speichert die neue Position
    MinimapButton:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()

        -- Aktuelle Position des Buttons auslesen
        local point, relativeTo, relativePoint, xOfs, yOfs = self:GetPoint(1)

        -- Position in der Datenbank speichern
        QuestAnnounce.db.profile.minimapButtonPosition = {
            point = point,
            relativeTo = relativeTo and relativeTo.GetName and relativeTo:GetName() or "Minimap",
            relativePoint = relativePoint,
            x = xOfs,
            y = yOfs,
        }
    end)

    -- Gespeicherte Position des Buttons wiederherstellen
    if QuestAnnounce.db.profile.minimapButtonPosition then
        MinimapButton:ClearAllPoints()

        local pos = QuestAnnounce.db.profile.minimapButtonPosition
        local relativeTo = pos.relativeTo

        if not relativeTo or not _G[relativeTo] then
            relativeTo = "Minimap"
        end

        MinimapButton:SetPoint(
            pos.point or "TOPLEFT",
            _G[relativeTo] or Minimap,
            pos.relativePoint or "TOPLEFT",
            pos.x or 0,
            pos.y or 0
        )
    else
        -- Standardposition, falls noch nichts gespeichert wurde
        MinimapButton:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 0, 0)
    end

    -- Anpassung des Minimap-Button-Tooltips
    MinimapButton:SetScript("OnEnter", function(self)	
		-- Eigenen Tooltip erzeugen oder wiederverwenden
        QuestAnnounce:CreateCustomTooltip()

        local font = QuestAnnounce:GetTooltipFontPath(QuestAnnounce.db.profile.tooltip.font)
        local fontSize = QuestAnnounce.db.profile.tooltip.fontSize
        local fontColor = QuestAnnounce.db.profile.tooltip.fontColor
        local tooltip = QuestAnnounce.customTooltip

		tooltip:SetOwner(self, "ANCHOR_LEFT")
		tooltip:ClearLines()  -- Wichtig, um sicherzustellen, dass alte Zeilen entfernt werden

        
    -- Überschrift hinzufügen
        tooltip:AddLine(L["Quest Announce 3"], fontColor[1], fontColor[2], fontColor[3])

       tooltip:AddLine(" ")  -- Leere Zeile für Abstand

        -- Hier werden die Einstellungen aus den General Options hinzugefügt
   
        local enableAddon = QuestAnnounce.db.profile.settings and QuestAnnounce.db.profile.settings.enable -- Überprüfe, ob das Addon aktiviert oder deaktiviert ist
        local addonStatus = enableAddon and L["Enable"] or L["Disable"]
        tooltip:AddLine(L["Addon Status:"] .. addonStatus, fontColor[1], fontColor[2], fontColor[3])


        -- Zeigt vereinfacht an, dass die Kanalwahl über die Einstellungen erfolgt
        tooltip:AddLine(L["Announcement Channel"] .. ": " .. L["Settings"], fontColor[1], fontColor[2], fontColor[3])

        local soundEnabled = QuestAnnounce.db.profile.settings.sound and L["On"] or L["Off"]
        tooltip:AddLine(L["Sound"] .. ": " .. soundEnabled, fontColor[1], fontColor[2], fontColor[3])

        local tooltipFont = QuestAnnounce.db.profile.tooltip.font or "Friz Quadrata TT"
        tooltip:AddLine(L["Tooltip Font"] .. ": " .. tooltipFont, fontColor[1], fontColor[2], fontColor[3])

        local tooltipFontSize = QuestAnnounce.db.profile.tooltip.fontSize or 12
        tooltip:AddLine(L["Tooltip Font Size"] .. ": " .. tooltipFontSize, fontColor[1], fontColor[2], fontColor[3])


        -- Schriftart und -größe setzen
        for i = 1, tooltip:NumLines() do
            local leftLine = _G["QuestAnnounceTooltipTextLeft" .. i]
            if leftLine then
                if i == 1 then  -- Spezifische Anpassungen für die erste Zeile (Überschrift)
                    leftLine:SetFont(font, fontSize + 4)  -- Feste Schriftgröße: 2 Punkte größer
                    leftLine:SetTextColor(fontColor[1], fontColor[2], fontColor[3])
                else
                    leftLine:SetFont(font, fontSize)
                    leftLine:SetTextColor(fontColor[1], fontColor[2], fontColor[3])
                end
            end
            local rightLine = _G["QuestAnnounceTooltipTextRight" .. i]
            if rightLine then
                rightLine:SetFont(font, fontSize)
				rightLine:SetTextColor(fontColor[1], fontColor[2], fontColor[3])
            end
        end
		QuestAnnounce:UpdateTooltipBackground()
		tooltip:Show()
    end)

        -- Versteckt den Tooltip beim Verlassen des Buttons
    MinimapButton:SetScript("OnLeave", function(self)
        if QuestAnnounce.customTooltip then
            QuestAnnounce.customTooltip:Hide()
        end
    end)

MinimapButton:RegisterForClicks("AnyUp")

-- Öffnet das Hauptfenster von QuestAnnounce in den Blizzard-Einstellungen
local function openConfig()
    local category = QuestAnnounce.optionsCategory
    if not category then
        return
    end

    Settings.OpenToCategory(category:GetID())
    Settings.OpenToCategory(category:GetID())
end

    -- Reaktion auf Klicks auf den Minimap-Button
    MinimapButton:SetScript("OnClick", function(self, button)
        if button == "RightButton" then
            -- Rechtsklick öffnet das Einstellungsfenster
            QuestAnnounce:SendDebugMsg(L["Right-click detected on QuestAnnounce MinimapButton Open Menu"])
            openConfig()
        else
            -- Linksklick schaltet das Addon nur im Profil an oder aus
            QuestAnnounce:SendDebugMsg(L["Left-click detected on QuestAnnounce MinimapButton Toggle On / Off"])

            QuestAnnounce.db.profile.settings.enable = not QuestAnnounce.db.profile.settings.enable

            if QuestAnnounce.db.profile.settings.enable then
                QuestAnnounce:Print(L["QuestAnnounce activated!"])
                UIErrorsFrame:AddMessage(L["QuestAnnounce activated!"])
            else
                QuestAnnounce:Print(L["QuestAnnounce deactivated!"])
                UIErrorsFrame:AddMessage(L["QuestAnnounce deactivated!"])
            end
        end
    end)

--    MinimapButton:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 0, 0)
QuestAnnounce:SendDebugMsg("Minimap button successfully created and positioned.")  -- Debugging-Ausgabe

    MinimapButton:Show()  -- Sicherstellen, dass der Button angezeigt wird
end

-- Setzt die gespeicherte Position des Minimap-Buttons auf den Standard zurück
function QuestAnnounce:ResetMinimapButtonPosition()
    self.db.profile.minimapButtonPosition = {
        point = "TOPLEFT",
        relativeTo = "Minimap",
        relativePoint = "TOPLEFT",
        x = 0,
        y = 0,
    }

    if self.minimapButton then
        self.minimapButton:ClearAllPoints()
        self.minimapButton:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 0, 0)
    end
end

-- Liefert passend zum gespeicherten Schriftnamen den Font-Pfad zurück
function QuestAnnounce:GetTooltipFontPath(fontName)
    local fonts = {
        ["Friz Quadrata TT"] = "Fonts\\FRIZQT__.TTF",
        ["Arial Narrow"] = "Fonts\\ARIALN.TTF",
        ["Morpheus"] = "Fonts\\MORPHEUS.ttf",
        ["Skurri"] = "Fonts\\skurri.ttf",
    }

    return fonts[fontName] or "Fonts\\FRIZQT__.TTF"
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

-- Aktualisiert Hintergrund, Schriftart, Schriftgröße und Schriftfarbe des eigenen Tooltips
function QuestAnnounce:UpdateTooltipBackground()
    if not self.customTooltip or not self.customTooltip.bgTexture then
        return
    end

    local bgColor = self.db.profile.tooltip.bgColor or {0, 0, 0, 0.8}
    local font = self:GetTooltipFontPath(self.db.profile.tooltip.font)
    local fontSize = self.db.profile.tooltip.fontSize or 12
    local fontColor = self.db.profile.tooltip.fontColor or {1, 1, 1}

    -- Hintergrundfarbe aktualisieren
    self.customTooltip.bgTexture:SetColorTexture(bgColor[1], bgColor[2], bgColor[3], bgColor[4])

    -- Schriftart und Farbe aller Tooltip-Zeilen aktualisieren
    for i = 1, self.customTooltip:NumLines() do
        local leftLine = _G["QuestAnnounceTooltipTextLeft" .. i]
        local rightLine = _G["QuestAnnounceTooltipTextRight" .. i]

        if leftLine then
            if i == 1 then
                leftLine:SetFont(font, fontSize + 4)
            else
                leftLine:SetFont(font, fontSize)
            end
            leftLine:SetTextColor(fontColor[1], fontColor[2], fontColor[3])
        end

        if rightLine then
            rightLine:SetFont(font, fontSize)
            rightLine:SetTextColor(fontColor[1], fontColor[2], fontColor[3])
        end
    end
end


--function QuestAnnounce:GetTooltipColors()
--    local bgColor = QuestAnnounce.db.profile.tooltip.bgColor or {0, 0, 0, 0.8}
--    local borderColor = QuestAnnounce.db.profile.tooltip.borderColor or {1, 1, 1}
--    
--    return bgColor, borderColor
--end
