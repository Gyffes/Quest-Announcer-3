-- Minimap.lua
---@class QuestAnnounce
local QuestAnnounce = LibStub("AceAddon-3.0"):GetAddon("QuestAnnounce")
-- Laden erforderlicher Bibliotheken und Lokalisierung
local L = LibStub("AceLocale-3.0"):GetLocale("QuestAnnounce")
local LSM = LibStub("LibSharedMedia-3.0") -- Sicherstellen, dass LibSharedMedia geladen ist


-- Funktion zur Erstellung des Minimap-Buttons
function QuestAnnounce:InitializeMinimapButton()
--local function CreateMinimapButton()  
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

	MinimapButton:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()

		-- Save the position
		local point, relativeTo, relativePoint, xOfs, yOfs = self:GetPoint(1)
		-- Speichere die Position, wobei relativeTo der Name des Frames oder "UIParent" sein kann
		QuestAnnounce.db.profile.minimapButtonPosition = {
			point,
			relativeTo and relativeTo.GetName and relativeTo:GetName() or "Minimap", -- Stelle sicher, dass relativeTo ein Name oder "Minimap" ist
			relativePoint,
			xOfs,
			yOfs
		}
	end)

	-- Load the position
	if QuestAnnounce.db.profile.minimapButtonPosition then
		MinimapButton:ClearAllPoints()
		local point, relativeTo, relativePoint, xOfs, yOfs = unpack(QuestAnnounce.db.profile.minimapButtonPosition)
		if not _G[relativeTo] then
			relativeTo = "Minimap"  -- Fallback auf Minimap, wenn das gespeicherte Frame nicht existiert
		end
	--	MinimapButton:SetPoint(point, _G[relativeTo] or Minimap, relativePoint, xOfs, yOfs) -- Verwende Minimap als Fallback
	    MinimapButton:SetPoint(point or "TOPLEFT", _G[relativeTo] or Minimap, relativePoint or "TOPLEFT", xOfs or 0, yOfs or 0)
	else
    -- Standardposition an der Minimap, falls keine Position gespeichert ist
		MinimapButton:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 0, 200)
	end

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

        
    -- Überschrift hinzufügen
        tooltip:AddLine(L["Quest Announce 3"], fontColor[1], fontColor[2], fontColor[3])

       tooltip:AddLine(" ")  -- Leere Zeile für Abstand

        -- Hier werden die Einstellungen aus den General Options hinzugefügt
   
        local enableAddon = QuestAnnounce.db.profile.settings and QuestAnnounce.db.profile.settings.enable -- Überprüfe, ob das Addon aktiviert oder deaktiviert ist
        local addonStatus = enableAddon and L["Enable"] or L["Disable"]
        tooltip:AddLine(L["Addon Status:"] .. addonStatus, fontColor[1], fontColor[2], fontColor[3])


        local announceChannel = QuestAnnounce.db.profile.announceChannel or "Standard"
        tooltip:AddLine(L["Announcement Channel"] .. announceChannel, fontColor[1], fontColor[2], fontColor[3])

        local soundOnComplete = QuestAnnounce.db.profile.settings.soundOnComplete and "Ja" or "Nein"
        tooltip:AddLine("Sound bei Abschluss: " .. soundOnComplete, fontColor[1], fontColor[2], fontColor[3])

        local tooltipFont = QuestAnnounce.db.profile.tooltip.font or "Standard"
        tooltip:AddLine(L["Sound"] .. tooltipFont, fontColor[1], fontColor[2], fontColor[3])

        local tooltipFontSize = QuestAnnounce.db.profile.tooltip.fontSize or 12
        tooltip:AddLine("Tooltip Schriftgröße: " .. tooltipFontSize, fontColor[1], fontColor[2], fontColor[3])

    --[[    local tooltipFontColor = QuestAnnounce.db.profile.tooltip.fontColor or {1, 1, 1}
        tooltip:AddLine("Tooltip Schriftfarbe: RGB(" .. table.concat(tooltipFontColor, ", ") .. ")", fontColor[1], fontColor[2], fontColor[3])

        local tooltipBgColor = QuestAnnounce.db.profile.tooltip.bgColor or {0, 0, 0, 0.8}
        tooltip:AddLine("Tooltip Hintergrundfarbe: RGBA(" .. table.concat(tooltipBgColor, ", ") .. ")", fontColor[1], fontColor[2], fontColor[3])

        tooltip:AddLine(L["Tooltip LeftClick Aktivate/deactivated"], fontColor[1], fontColor[2], fontColor[3])
        tooltip:AddLine(L["Tooltip Right-click: Open options"], fontColor[1], fontColor[2], fontColor[3])
]]
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

-- openConfig() definieren
local function openConfig()
    local frame = QuestAnnounce.optionsFrames.QuestAnnounce
    if not frame then return end
		Settings.OpenToCategory(frame.name)
        Settings.OpenToCategory(frame.name) -- Blizzard Bugfix: muss doppelt aufgerufen werden
end

MinimapButton:SetScript("OnClick", function(self, button)
    if button == "RightButton" then
        QuestAnnounce:SendDebugMsg(L["Right-click detected on QuestAnnounce MinimapButton Open Menu"])  -- Debugging-Ausgabe
		openConfig()
	   else
        QuestAnnounce:SendDebugMsg(L["Left-click detected on QuestAnnounce MinimapButton Toggle On / Off"])  -- Debugging-Ausgabe
        if QuestAnnounce.db.profile.settings.enable then
            QuestAnnounce.db.profile.settings.enable = false
            QuestAnnounce:OnDisable()
        else
            QuestAnnounce.db.profile.settings.enable = true
            QuestAnnounce:OnEnable()
        end
    end
end)

--    MinimapButton:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 0, 0)
QuestAnnounce:SendDebugMsg("Minimap button successfully created and positioned.")  -- Debugging-Ausgabe

    MinimapButton:Show()  -- Sicherstellen, dass der Button angezeigt wird
end

function QuestAnnounce:ResetMinimapButtonPosition()
    -- Setze die Position des MinimapButtonms auf die Standardeinstellungen zurück
    self.db.profile.minimapButtonPosition = { point = "TOPLEFT", relativePoint = "TOPLEFT", x = 0, y = 0 }
	QuestAnnounceMinimapButton:ClearAllPoints()
    QuestAnnounceMinimapButton:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 0, 0)
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