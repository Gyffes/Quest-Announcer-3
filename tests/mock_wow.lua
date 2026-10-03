-- DE/EN: Minimaler UI/API-Testadapter; kein WoW-Client und kein Glyphenrenderer.
-- Minimal UI/API fixture, not a WoW client or glyph renderer.
local paths = { koKR = "Fonts\\2002.TTF", zhCN = "Fonts\\ARKai_T.ttf",
    zhTW = "Fonts\\blei00d.TTF", ruRU = "Fonts\\FRIZQT___CYR.TTF" }
TEST_FONT_PATH = paths[TEST_LOCALE] or "Fonts\\FRIZQT__.TTF"
TEST_FRAMES, TEST_TIMERS, TEST_SOUND_CALLS, TEST_CHAT_CALLS = {}, {}, {}, {}
TEST_TIME, TEST_COMBAT = 100, false
local frameMethods = {}
local newFrame
local children = { Text=true, Low=true, High=true, ScrollBar=true, ThumbTexture=true }
local frameMeta = { __index = function(self, key)
    if frameMethods[key] then return frameMethods[key] end
    if children[key] then
        local child = newFrame(nil)
        rawset(self, key, child)
        return child
    end
    if key:match("^Set") or key:match("^Enable") or key:match("^Register") or
       key:match("^Clear") or key:match("^AddMask") or key:match("^Stop") or
       key:match("^Start") or key=="HighlightText" then return function() end end
end }
newFrame = function(name)
    local frame = setmetatable({ name=name, scripts={}, shown=false, lines=0, path=TEST_FONT_PATH }, frameMeta)
    TEST_FRAMES[#TEST_FRAMES+1] = frame
    if name then _G[name] = frame end
    return frame
end
function frameMethods:GetName() return self.name end
function frameMethods:GetFont() return self.path, self.fontSize or 12, self.flags or "OUTLINE" end
function frameMethods:SetFont(path, size, flags)
    if self.reject and self.reject[path] then return false end
    if self.throwFont then error("invalid font file asset") end
    assert(type(path)=="string" and path~="", "invalid font path")
    self.path, self.fontSize, self.flags = path, size, flags
    return true
end
function frameMethods:SetText(text)
    self.text = text
    if self.kind=="GameTooltip" then self.lines=0; self:AddLine(text)
    else self.Text.text = text end
end
function frameMethods:GetText() return self.text or "" end
function frameMethods:SetSize(width,height) self.width,self.height=width,height end
function frameMethods:SetWidth(width) self.width=width end
function frameMethods:SetHeight(height) self.height=height end
function frameMethods:GetWidth() return self.width or 760 end
function frameMethods:GetHeight() return self.height or 300 end
function frameMethods:GetStringWidth() return #(self.text or "") * 6 end
function frameMethods:GetStringHeight() return 24 end
function frameMethods:SetScript(event,callback) self.scripts[event]=callback end
function frameMethods:HookScript(event,callback)
    local previous=self.scripts[event]
    self.scripts[event]=function(...) if previous then previous(...) end; callback(...) end
end
function frameMethods:GetScript(event) return self.scripts[event] end
function frameMethods:Show() self.shown=true end
function frameMethods:Hide() self.shown=false end
function frameMethods:IsShown() return self.shown end
function frameMethods:IsMovable() return true end
function frameMethods:GetPoint() return "TOPLEFT", Minimap, "TOPLEFT", 0, 0 end
function frameMethods:SetValue(value) self.value=value end
function frameMethods:GetValue() return self.value or 0 end
function frameMethods:SetChecked(value) self.checked=value end
function frameMethods:GetChecked() return self.checked end
function frameMethods:CreateFontString(name) return newFrame(name) end
function frameMethods:CreateTexture(name) return newFrame(name) end
function frameMethods:CreateMaskTexture(name) return newFrame(name) end
function frameMethods:GetID() return 1 end
function frameMethods:SetFontObject(object)
    if type(object)=="string" then object=_G[object] end
    self.path=object and object:GetFont() or TEST_FONT_PATH
end
function frameMethods:GetFontObject() return GameTooltipText end
function frameMethods:GetVerticalScroll() return 0 end
function frameMethods:GetVerticalScrollRange() return 0 end
function frameMethods:ClearLines() self.lines=0 end
function frameMethods:AddLine(text)
    self.lines=self.lines+1
    local line = _G[(self.name or "").."TextLeft"..self.lines] or newFrame((self.name or "").."TextLeft"..self.lines)
    line.text=text
end
function frameMethods:NumLines() return self.lines end
function frameMethods:SetOwner(owner) self.owner=owner end
function frameMethods:AddMessage(text) TEST_CHAT_CALLS[#TEST_CHAT_CALLS+1]=text end
function CreateFrame(kind,name)
    local frame=newFrame(name)
    frame.kind=kind
    if kind=="GameTooltip" and name then
        for i=1,30 do newFrame(name.."TextLeft"..i); newFrame(name.."TextRight"..i) end
    end
    return frame
end
UIParent, Minimap = newFrame("UIParent"), newFrame("Minimap")
GameTooltipText, GameFontNormal = newFrame("GameTooltipText"), newFrame("GameFontNormal")
GameFontNormalLarge, GameFontNormalHuge = GameFontNormal, GameFontNormal
DEFAULT_CHAT_FRAME = newFrame("DEFAULT_CHAT_FRAME")
SlashCmdList = {}
Settings = {
    RegisterCanvasLayoutCategory=function() return newFrame(nil) end,
    RegisterCanvasLayoutSubcategory=function() return newFrame(nil) end,
    RegisterAddOnCategory=function() end,
    OpenToCategory=function() end,
}
function GetLocale() return TEST_LOCALE end
function GetBuildInfo() return "test", "test", "test", TEST_INTERFACE end
WOW_PROJECT_ID=1 -- Forever must not be forced into legacy paths by its low TOC number.
function GetTime() return TEST_TIME end
function InCombatLockdown() return TEST_COMBAT end
function GetRealmName() return "Realm" end
function UnitName() return "Tester" end
function IsInGroup() return false end
function GetCVar() return "1" end
function GetCVarBool() return true end
function hooksecurefunc() end
C_Timer={ After=function(_,callback) TEST_TIMERS[#TEST_TIMERS+1]=callback end }
function TEST_FLUSH_TIMERS()
    local timers=TEST_TIMERS; TEST_TIMERS={}
    for _,callback in ipairs(timers) do callback() end
end
if TEST_CLIENT == "Wrath" or TEST_CLIENT == "Cata" then
    function GetNumQuestLogEntries() return 0 end
    function GetQuestLogTitle() return nil end
else
    C_QuestLog={GetNumQuestLogEntries=function() return 0 end}
end
