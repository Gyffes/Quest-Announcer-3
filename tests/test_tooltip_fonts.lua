local QA, L = QuestAnnounce, QuestAnnounce_L[TEST_LOCALE]
local originalTooltipPath, originalNormalPath = GameTooltipText:GetFont(), GameFontNormal:GetFont()
QA.db={profile=QA:ApplyProfileDefaults({})}
QuestAnnounceDB=QA.db
assert(QA.db.profile.tooltip.font=="AUTO")
assert(QA:GetTooltipFontPath(nil)==TEST_FONT_PATH)
local nonLatin = TEST_LOCALE=="koKR" or TEST_LOCALE=="zhCN" or TEST_LOCALE=="zhTW" or TEST_LOCALE=="ruRU"
for _,value in ipairs({"Friz Quadrata TT", "Fonts/FRIZQT__.TTF", "fonts\\frizqt__.ttf"}) do
    assert(QA:GetTooltipFontPath(value)==(nonLatin and TEST_FONT_PATH or "Fonts\\FRIZQT__.TTF"))
end
for _,value in ipairs({false, 42, "", "unknown", "AUTO"}) do
    assert(QA:GetTooltipFontPath(value)==TEST_FONT_PATH)
end
assert(QA:GetTooltipFontPath("Interface\\AddOns\\Other\\Custom.ttf")=="Interface\\AddOns\\Other\\Custom.ttf")
for _,choice in ipairs(QA:GetTooltipFontChoices()) do
    local line=CreateFrame("FontString")
    assert(QA:ApplyTooltipLineFont(line,choice.value,17))
    assert(line.fontSize==17 and line.flags=="OUTLINE")
end
local choices=QA:GetTooltipFontChoices()
choices[1].value="changed"
assert(QA:GetTooltipFontChoices()[1].value=="AUTO")

-- Missing globals/methods, bad return types, and errors in GetFont.
STANDARD_TEXT_FONT=nil
local tooltipObject,normalObject=GameTooltipText,GameFontNormal
GameTooltipText=nil
assert(QA:GetClientDefaultFontPath()==TEST_FONT_PATH)
GameTooltipText={GetFont=function() error("missing asset") end}
assert(QA:GetClientDefaultFontPath()==TEST_FONT_PATH)
GameTooltipText={GetFont=function() return 42 end}
assert(QA:GetClientDefaultFontPath()==TEST_FONT_PATH)
GameTooltipText={GetFont=function() return "" end}
assert(QA:GetClientDefaultFontPath()==TEST_FONT_PATH)
GameTooltipText={}; GameFontNormal=nil
local inherited=CreateFrame("FontString")
assert(QA:GetClientDefaultFontPath()==nil)
assert(QA:ApplyTooltipLineFont(inherited,"AUTO",18) and inherited.path==TEST_FONT_PATH)
GameTooltipText,GameFontNormal=tooltipObject,normalObject

local line=CreateFrame("FontString")
line.reject={["Interface\\AddOns\\Other\\Custom.ttf"]=true}
assert(QA:ApplyTooltipLineFont(line,"Interface\\AddOns\\Other\\Custom.ttf",19))
assert(line.path==TEST_FONT_PATH and line.fontSize==19)
line.throwFont=true
assert(not QA:ApplyTooltipLineFont(line,"AUTO",19))
assert(line.path==TEST_FONT_PATH)
assert(GameTooltipText:GetFont()==originalTooltipPath and GameFontNormal:GetFont()==originalNormalPath)

-- Try the next client object when the first object's file cannot be loaded.
GameTooltipText={GetFont=function() return "Fonts\\Unavailable.ttf" end}
line=CreateFrame("FontString")
line.reject={["Fonts\\Unavailable.ttf"]=true}
assert(QA:ApplyTooltipLineFont(line,"AUTO",20) and line.path==TEST_FONT_PATH)
GameTooltipText=tooltipObject
if nonLatin and TEST_LOCALE~="koKR" then
    assert(QA:GetTooltipFontSelection("Fonts\\2002.TTF")=="AUTO")
end

local saved=QA:ApplyProfileDefaults({tooltip={font="Friz Quadrata TT",fontSize=21,fontColor={.2,.3,.4}},settings={sound=false}})
assert(saved.tooltip.font=="Friz Quadrata TT" and saved.tooltip.fontSize==21 and saved.settings.sound==false)
QA.db.profile=saved
QA.db.profiles={Legacy={tooltip={font="Fonts\\FRIZQT__.TTF",fontSize=22,fontColor={.4,.5,.6}},settings={sound=false}}}
QA:SetupOptions()
QA:InitializeMinimapButton()
QA.minimapButton.scripts.OnEnter(QA.minimapButton)
local first=_G.QuestAnnounceTooltipTextLeft1
assert(first.fontSize==25 and first.path==(nonLatin and TEST_FONT_PATH or "Fonts\\FRIZQT__.TTF"))
assert(QuestAnnounceTooltipTextRight1.fontSize==21)
assert(saved.tooltip.font=="Friz Quadrata TT")

local fontDropdown,resetButton
for _,frame in ipairs(TEST_FRAMES) do
    if frame.items and frame.items[1] and frame.items[1].value=="AUTO" then fontDropdown=frame end
    if frame.text==L["Reset Tooltip Settings"] and frame.scripts.OnClick then resetButton=frame end
end
assert(fontDropdown and resetButton)
assert(fontDropdown.selectedValue==(nonLatin and "AUTO" or "Friz Quadrata TT"))
fontDropdown.onSelect("AUTO")
assert(saved.tooltip.font=="AUTO" and first.path==TEST_FONT_PATH)
resetButton.scripts.OnClick(resetButton)
assert(saved.tooltip.font=="AUTO" and saved.tooltip.fontSize==12 and first.fontSize==16)
-- Exercise the actual local options-tooltip styling through its hover callback.
fontDropdown.scripts.OnEnter(fontDropdown)
assert(QuestAnnounceConfigTooltipTextLeft1.path==TEST_FONT_PATH)
assert(QuestAnnounceConfigTooltipTextLeft1.fontSize==12)
assert(QuestAnnounceConfigTooltipTextRight1.fontSize==12)
assert(GameTooltipText:GetFont()==originalTooltipPath and GameFontNormal:GetFont()==originalNormalPath)

-- Load an actual saved profile through the options panel callback.
local profileDropdown,loadButton
for _,frame in ipairs(TEST_FRAMES) do
    if frame.items and frame.items[1] and frame.items[1].value=="Legacy" then profileDropdown=frame end
    if frame.text==L["Load Profile"] and frame.scripts.OnClick then loadButton=frame end
end
assert(profileDropdown and loadButton)
profileDropdown.onSelect("Legacy")
loadButton.scripts.OnClick(loadButton)
assert(QA.db.profile.tooltip.font=="Fonts\\FRIZQT__.TTF" and QA.db.profile.tooltip.fontSize==22)
assert(QA.db.profiles.Legacy.tooltip.font=="Fonts\\FRIZQT__.TTF")
assert(first.fontSize==26 and first.path==(nonLatin and TEST_FONT_PATH or "Fonts\\FRIZQT__.TTF"))
assert(QA.db.profile.settings.sound==false)
