-- QuestAnnounce Addon Initialisierung und Lokalisierung
local QuestAnnounce = LibStub("AceAddon-3.0"):GetAddon("QuestAnnounce")
local L = LibStub("AceLocale-3.0"):GetLocale("QuestAnnounce")
local LSM = LibStub("LibSharedMedia-3.0")

-- Optionen und Konfigurationsoptionen
local options, configOptions = nil, {}

--[[ Diese Options-Tabelle wird in der GUI-Konfiguration verwendet. ]]-- 
--[[ This options table is used in the GUI config. ]]-- 
local function getOptions() 
    if not options then
        options = {
            type = "group",
            name = "QuestAnnounce",
            args = {
                general = {
                    order = 1,
                    type = "group",
                    name = L["General"],
                    args = {
                        settings = {
                            order = 1,
                            type = "group",
                            inline = true,
                            name = L["Settings"],
                            -- Abrufen und Festlegen der Einstellungen
                            -- Retrieving and setting the settings
                            get = function(info)
                                local key = info.arg or info[#info]
                                QuestAnnounce:SendDebugMsg("getSettings: "..key.." :: "..tostring(QuestAnnounce.db.profile.settings[key]))
                                return QuestAnnounce.db.profile.settings[key]
                            end,
                            set = function(info, value)
                                local key = info.arg or info[#info]
                                QuestAnnounce.db.profile.settings[key] = value
                                QuestAnnounce:SendDebugMsg("setSettings: "..key.." :: "..tostring(QuestAnnounce.db.profile.settings[key]))
                            end,
                            args = {
                                enabledesc = {
                                    order = 1,
                                    type = "description",
                                    fontSize = "medium",
                                    name = L["Enable/Disable QuestAnnounce"]
                                },
                                enable = {
                                    order = 2,
                                    type = "toggle",
                                    name = L["Enable"]
                                },
                                everydesc = {
                                    order = 3,
                                    type = "description",
                                    fontSize = "medium",
                                    name = L["Announce progression every x number of steps (0 will announce on quest objective completion only)"]
                                },
                                every = {
                                    order = 4,
                                    type = "range",
                                    name = L["Announce Every"],
                                    min = 0,
                                    max = 10,
                                    step = 1
                                },
                                sounddesc = {
                                    order = 5,
                                    type = "description",
                                    fontSize = "medium",
                                    name = L["Enable/Disable QuestAnnounce Sounds"]
                                },
                                sound = {
                                    order = 6,
                                    type = "toggle",
                                    name = L["Sound"]
                                },
                                debugdesc = {
                                    order = 100,
                                    type = "description",
                                    fontSize = "medium",
                                    name = L["Enable/Disable QuestAnnounce Debug Mode"]
                                },
                                debug = {
                                    order = 101,
                                    type = "toggle",
                                    name = L["Debug"]
                                },
                                test = {
                                    order = 102,
                                    type = "execute",
                                    name = L["Test Frame Messages"],
                                    func = function() QuestAnnounce:SendMsg(L["QuestAnnounce Test Message"]) end
                                }
                            }
                        },
                        announceTo = {
                            order = 6,
                            type = "group",
                            inline = true,
                            name = L["Where do you want to make the announcements?"],
                            get = function(info)
                                local key = info.arg or info[#info]
                                QuestAnnounce:SendDebugMsg("getAnnounceTo: "..key.." :: "..tostring(QuestAnnounce.db.profile.announceTo[key]))
                                return QuestAnnounce.db.profile.announceTo[key]
                            end,
                            set = function(info, value)
                                local key = info.arg or info[#info]
                                QuestAnnounce.db.profile.announceTo[key] = value
                                QuestAnnounce:SendDebugMsg("setAnnounceTo: "..key.." :: "..tostring(QuestAnnounce.db.profile.announceTo[key]))
                            end,
                            args = {
                                chatFrame = {
                                    order = 1,
                                    type = "toggle",
                                    name = L["Chat Frame"]
                                },
                                raidWarningFrame = {
                                    order = 2,
                                    type = "toggle",
                                    name = L["Raid Warning Frame"]
                                },
                                uiErrorsFrame = {
                                    order = 3,
                                    type = "toggle",
                                    name = L["UI Errors Frame"]
                                }
                            }
                        },
                        announceIn = {
                            order = 7,
                            type = "group",
                            inline = true,
                            name = L["What channels do you want to make the announcements?"],
                            get = function(info)
                                local key = info.arg or info[#info]
                                QuestAnnounce:SendDebugMsg("getAnnounceIn: "..key.." :: "..tostring(QuestAnnounce.db.profile.announceIn[key]))
                                return QuestAnnounce.db.profile.announceIn[key]
                            end,
                            set = function(info, value)
                                local key = info.arg or info[#info]
                                QuestAnnounce.db.profile.announceIn[key] = value
                                QuestAnnounce:SendDebugMsg("setAnnounceIn: "..key.." :: "..tostring(QuestAnnounce.db.profile.announceIn[key]))
                            end,
                            args = {
                                say = {
                                    order = 1,
                                    type = "toggle",
                                    name = L["Say"]
                                },
                                party = {
                                    order = 2,
                                    type = "toggle",
                                    name = L["Party"]
                                },
                                instance = {
                                    order = 3,
                                    type = "toggle",
                                    name = L["Instance"],
                                    confirm = function(info, value)
                                        return (value and L["Are you sure you want to announce to this channel?"] or false)
                                    end                                    
                                },                                
                                guild = {
                                    order = 4,
                                    type = "toggle",
                                    name = L["Guild"],
                                    confirm = function(info, value)
                                        return (value and L["Are you sure you want to announce to this channel?"] or false)
                                    end                                    
                                },
                                officer = {
                                    order = 5,
                                    type = "toggle",
                                    name = L["Officer"],
                                    confirm = function(info, value)
                                        return (value and L["Are you sure you want to announce to this channel?"] or false)
                                    end
                                }
                            }
                        },
                        whisperAndChannelOptions = {
                            order = 8,
                            type = "group",
                            inline = true,
                            name = L["Whisper and Channel Options"],
                            get = function(info)
                                local key = info.arg or info[#info]
                                QuestAnnounce:SendDebugMsg("getWhisperAndChannelOptions: "..key.." :: "..tostring(QuestAnnounce.db.profile.announceIn[key]))
                                return QuestAnnounce.db.profile.announceIn[key]
                            end,
                            set = function(info, value)
                                local key = info.arg or info[#info]
                                QuestAnnounce.db.profile.announceIn[key] = value
                                QuestAnnounce:SendDebugMsg("setWhisperAndChannelOptions: "..key.." :: "..tostring(QuestAnnounce.db.profile.announceIn[key]))
                            end,
                            args = {
                                whisper = {
                                    order = 1,
                                    type = "toggle",
                                    name = L["Whisper"],
                                    width = 'half',
                                    confirm = function(info, value)
                                        return (value and L["Are you sure you want to announce to this channel?"] or false)
                                    end
                                },
                                whisperWho = {
                                    order = 2,
                                    type = "input",
                                    width = 'half',
                                    name = L["Whisper Who"]
                                },
                                channel = {
                                    order = 3,
                                    type = "toggle",
                                    name = L["Channel"],
                                    width = 'half',
                                    set = function(info, value)
                                        local key = info.arg or info[#info]
                                        QuestAnnounce.db.profile.announceIn[key] = value
                                        QuestAnnounce:SendDebugMsg("setWhisperAndChannelOptions: "..key.." :: "..tostring(QuestAnnounce.db.profile.announceIn[key]))

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
                                    get = function(info)
                                        local key = info.arg or info[#info]
                                        return QuestAnnounce.db.profile.announceIn[key]
                                    end,
                                    confirm = function(info, value)
                                        return (value and L["Are you sure you want to announce to this channel?"] or false)
                                    end
                                },
                                channelName = {
                                    order = 4,
                                    type = "input",
                                    width = 'half',
                                    name = L["Channel Name"]
                                }
                            }
                        }
                    }
                }
            }
        }

        -- Tooltip customization options
        options.args.tooltip = {
            type = "group",
            name = L["Tooltip Settings"],
            desc = L["Settings to customize the tooltip appearance"],
            order = 2, -- Dieser Bereich ist der zweite nach "general"
            args = {
                tooltipFont = {
                   -- width = "full", -- Setzt die Breite auf die gesamte verfügbare Breite Half, Full, normal
					order = 1,  
					type = "select",
                    name = L["Tooltip Font"],
                    desc = L["Choose the font for the tooltip text"],
                    values = LSM:HashTable("font"),
                    get = function() return QuestAnnounce.db.profile.tooltip.font end,
                    set = function(_, value) 
                        QuestAnnounce.db.profile.tooltip.font = value 
                        QuestAnnounce:UpdateTooltipBackground()
                    end,
                },
				Spacer = { --Absatz erzwingen
					order = 2,
					type = "description",
					name = " ", -- Leerer Name, um einen visuellen Abstand zu schaffen
				},
                tooltipFontSize = {
                    order = 3,
					type = "range",
                    name = L["Tooltip Font Size"],
                    desc = L["Set the font size for the tooltip text"],
                    min = 8,
                    max = 20,
                    step = 1,
                    get = function() return QuestAnnounce.db.profile.tooltip.fontSize end,
                    set = function(_, value) 
                        QuestAnnounce.db.profile.tooltip.fontSize = value 
                        QuestAnnounce:UpdateTooltipBackground()
                    end,
                },
				Spacer2 = { --Absatz erzwingen
					order = 4,
					type = "description",
					name = " ", -- Leerer Name, um einen visuellen Abstand zu schaffen
				},
                tooltipFontColor = {
                    order = 5,
					type = "color",
                    name = L["Tooltip Font Color"],
                    desc = L["Choose the color of the tooltip text"],
                    get = function() return unpack(QuestAnnounce.db.profile.tooltip.fontColor) end,
                    set = function(_, r, g, b) 
                        QuestAnnounce.db.profile.tooltip.fontColor = {r, g, b} 
                        QuestAnnounce:UpdateTooltipBackground()
                    end,
                },
				separator = {
					order = 5.5,  -- Setze die Reihenfolge zwischen den beiden Optionen
					type = "header",
					name = "",  -- Leere Zeichenkette sorgt für einen einfachen Trennstrich ohne Text
				},
                tooltipBgColor = {
					width = "full", -- Setzt die Breite auf die gesamte verfügbare Breite
					order = 6,
                    type = "color",
                    name = L["Tooltip Background Color"],
                    desc = L["Choose the background color for the tooltip"],
                    hasAlpha = true, -- Aktiviert den Alpha-Wert im Farb-Dialog
                    get = function()
                        local bgColor = QuestAnnounce.db.profile.tooltip.bgColor or {0, 0, 0, 0.8}
                        return unpack(bgColor)
                    end,
                    set = function(_, r, g, b, a)
                        QuestAnnounce.db.profile.tooltip.bgColor = {r, g, b, a}
                        QuestAnnounce:UpdateTooltipBackground()
                    end,
                },
               -- tooltipBorderColor = {
               --     order = 7,
				--	type = "color",
				--	name = L["Tooltip Background Color"],
                --    desc = L["Choose the background color for the tooltip"],
                 --   name = L["Tooltip Border Color"],
                 --   desc = L["Choose the color of the tooltip border"],
                 --   hasAlpha = true, -- Aktiviert den Alpha-Wert im Farb-Dialog
                --    get = function()
                 --       local borderColor = QuestAnnounce.db.profile.tooltip.borderColor or {0, 0, 0, 0.8}
                  --      return unpack(borderColor)
                 --   end,
                --    set = function(_, r, g, b, a)
                 --       QuestAnnounce.db.profile.tooltip.borderColor = {r, g, b, a}
                 --       QuestAnnounce:UpdateTooltipBackground()
                 --   end,
                --},
				separator = {
					order = 7.5,  -- Setze die Reihenfolge zwischen den beiden Optionen
					type = "header",
					name = "",  -- Leere Zeichenkette sorgt für einen einfachen Trennstrich ohne Text
				},
                tooltipReset = {
                    order = 8,
					type = "execute",
                    name = L["Reset Tooltip Settings"],
                    desc = L["Reset tooltip settings to default values"],
                    func = function()
                        -- Setze die Tooltip-Einstellungen auf die Standardwerte zurück
                        QuestAnnounce.db.profile.tooltip.font = "Friz Quadrata TT"
                        QuestAnnounce.db.profile.tooltip.fontSize = 12
                        QuestAnnounce.db.profile.tooltip.fontColor = {0.11, 1, 0.3}
                        QuestAnnounce.db.profile.tooltip.bgColor = {0, 0, 0, 0.8}
                        QuestAnnounce.db.profile.tooltip.borderColor = {1, 1, 1, 1}

                        -- Aktualisiere den Tooltip sofort
                        QuestAnnounce:UpdateTooltipBackground()
                    end,
                    confirm = function() return L["Are you sure you want to reset the tooltip settings to default?"] end,
                },
            },
        }

        -- Hinzufügen von benutzerdefinierten Konfigurationsoptionen
        for k, v in pairs(configOptions) do
            options.args[k] = (type(v) == "function") and v() or v
        end
    end
    
    return options
end

-- Öffnen der Konfigurations-GUI
local function openConfig() 
    Settings.OpenToCategory("QuestAnnounce")
end

-- Setup der Optionen und Registrierung der Kommandos
function QuestAnnounce:SetupOptions()
    self.optionsFrames = {}

    -- Registrierung der allgemeinen Optionen
    LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable("QuestAnnounce", getOptions)
    self.optionsFrames.QuestAnnounce = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("QuestAnnounce", nil, nil, "general")

    -- Registrierung der Tooltip-Optionen als eigener Reiter
    LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable("QuestAnnounce_Tooltip", {
        type = "group",
        name = L["Tooltip Settings"],
        args = getOptions().args.tooltip.args,
    })
    self.optionsFrames.Tooltip = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("QuestAnnounce_Tooltip", L["Tooltip Settings"], "QuestAnnounce")

    configOptions["Profiles"] = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)

    self.optionsFrames["Profiles"] = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("QuestAnnounce", "Profiles", "QuestAnnounce", "Profiles")

    LibStub("AceConsole-3.0"):RegisterChatCommand("qa", openConfig)
end

-- Verwaltung des Kanalverlassens
-- Managing channel leaving
function QuestAnnounce:ToggleChannelLeave(enable, channelName)
    if not enable then
        local dialog = StaticPopup_Show("CONFIRM_LEAVE_CHANNEL", channelName)
        if dialog then
            dialog.data = channelName
        end
    end
end

-- Definition des Popup-Dialogs für fehlende Kanalnamen
-- Defining the popup dialog for missing channel name
StaticPopupDialogs["MISSING_CHANNEL_NAME"] = {
    text = L["Please enter a channel name."],
    button1 = OKAY,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}
