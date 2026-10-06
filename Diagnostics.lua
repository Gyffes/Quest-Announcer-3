local QA = QuestAnnounce
local L = QuestAnnounce_L[GetLocale()] or QuestAnnounce_L.enUS
local MAX_RECORDS, MAX_SESSIONS = 2000, 20
local channels = {"SAY", "YELL", "EMOTE", "PARTY", "RAID", "RAID_WARNING", "INSTANCE_CHAT", "GUILD", "OFFICER", "WHISPER", "CHANNEL"}
local frame = CreateFrame("Frame")
local session, sequence = nil, 0

-- DE: Diagnose getrennt von Profilen; begrenzte Daten und niemals automatische Testwiederaufnahme.
-- EN: Diagnostics are separate from profiles; bounded data and never automatic test resumption.
function QA:InitializeDiagnostics()
    if session then return end
    local old = QuestAnnounceDiagnosticsDB
    if type(old) ~= "table" or old.schema ~= 1 then old={schema=1} end
    old.records = type(old.records) == "table" and old.records or {}
    old.sessions = type(old.sessions) == "table" and old.sessions or {}
    old.settings = type(old.settings) == "table" and old.settings or {}
    for _, key in ipairs({"whisper", "channel"}) do
        if type(old.settings[key]) ~= "string" then old.settings[key]=nil
        else old.settings[key]=old.settings[key]:sub(1,120) end
    end
    old.enabled = old.enabled == true
    while #old.records > MAX_RECORDS do table.remove(old.records, 1) end
    while #old.sessions >= MAX_SESSIONS do table.remove(old.sessions, 1) end
    old.serial = (tonumber(old.serial) or 0) + 1
    session = tostring(time()) .. "-" .. old.serial .. "-" .. tostring(GetTime()) .. "-" .. math.random(100000,999999)
    local version, build, _, interface = GetBuildInfo()
    old.sessions[#old.sessions+1] = {id=session, version=version, build=build, interface=interface, locale=GetLocale(), project=WOW_PROJECT_ID}
    QuestAnnounceDiagnosticsDB = old
    self:RecordChatDiagnostic("SESSION", {})
end
function QA:GetChatDiagnosticState()
    local result = {}
    local queries = {combat=InCombatLockdown, chatLock=C_ChatInfo and C_ChatInfo.InChatMessagingLockdown,
        encounter=IsEncounterInProgress, zone=GetZoneText, subzone=GetSubZoneText, instance=IsInInstance}
    for key, fn in pairs(queries) do
        local value, reason = self:ReadChatAPI(fn)
        result[key] = value ~= nil and tostring(value) or reason or "nil"
    end
    for _, name in ipairs({"Combat", "Encounter", "ChallengeMode", "PvPMatch", "Map", "Chat"}) do
        local value, reason = self:GetRestrictionState(name)
        result[name] = value ~= nil and tostring(value) or reason or "nil"
    end
    return result
end
function QA:RecordChatDiagnostic(kind, detail)
    local db = QuestAnnounceDiagnosticsDB
    if not db or not db.enabled then return end
    local data = {}
    for key, value in pairs(detail or {}) do
        if not self:IsReadable(value) then data[key]="secret"
        elseif type(value) == "boolean" or type(value) == "number" then data[key]=value
        elseif type(value) == "string" then data[key]=value:sub(1,400) end
    end
    db.records[#db.records+1] = {session=session, time=date("%Y-%m-%d %H:%M:%S"), elapsed=GetTime(),
        kind=kind, data=data, state=self:GetChatDiagnosticState()}
    if #db.records > MAX_RECORDS then table.remove(db.records, 1) end
end
function QA:SetChatDiagnosticsEnabled(enabled)
    self:InitializeDiagnostics()
    QuestAnnounceDiagnosticsDB.enabled=enabled == true
    if not enabled then self:CancelChatDiagnosticSuite() end
    self:RecordChatDiagnostic("RECORDING_ENABLED", {})
    self:NotifySelf(L[enabled and "Diagnostics enabled" or "Diagnostics disabled"], false)
end
function QA:ClearChatDiagnosticLog()
    self:InitializeDiagnostics()
    QuestAnnounceDiagnosticsDB.records={}
    -- DE: Einstellungen/Sitzungszaehler erhalten; nur das Protokoll entfernen.
    -- EN: Preserve settings/session counters; clear only recorded data.
    self:NotifySelf(L["Diagnostic log cleared"], false)
end
function QA:CancelChatDiagnosticSuite(reason)
    self.diagnosticLocalGeneration=(self.diagnosticLocalGeneration or 0)+1
    self.diagnosticLocalPending=nil
    local run = self.diagnosticSuite
    if run then
        self:RecordChatDiagnostic("SUITE_CANCELLED", {mode=run.mode, reason=reason})
        self.diagnosticSuite=nil
        if run.ticker then run.ticker:Cancel() end
        self:ScheduleChatWake(0)
    end
end
local function flag(fn, ...)
    return QA:ReadChatAPI(fn, ...) == true
end
local function prerequisite(channel)
    local settings = QuestAnnounceDiagnosticsDB.settings
    if channel == "WHISPER" then
        if type(settings.whisper) ~= "string" or settings.whisper == "" then return nil, "missing test recipient" end
        return settings.whisper
    elseif channel == "CHANNEL" then
        local id = type(settings.channel) == "string" and QA:GetChannelNameSafe(settings.channel)
        if not id then return nil, "missing joined test channel" end
        return id
    elseif channel == "PARTY" then
        if not flag(IsInGroup, LE_PARTY_CATEGORY_HOME) or flag(IsInRaid, LE_PARTY_CATEGORY_HOME) then return nil, "no home party" end
    elseif channel == "RAID" or channel == "RAID_WARNING" then
        if not flag(IsInRaid) then return nil, "no raid" end
        if channel == "RAID_WARNING" and not flag(UnitIsGroupLeader, "player") and not flag(UnitIsGroupAssistant, "player") then
            return nil, "no raid warning permission"
        end
    elseif channel == "INSTANCE_CHAT" then
        if not flag(IsInGroup, LE_PARTY_CATEGORY_INSTANCE) then return nil, "no instance group" end
    elseif channel == "GUILD" or channel == "OFFICER" then
        if not flag(IsInGuild) then return nil, "no guild" end
    end
end
function QA:StartChatDiagnosticSuite(mode)
    self:InitializeDiagnostics()
    if self.diagnosticSuite or self.diagnosticLocalPending then self:NotifySelf(L["Diagnostic test already running"], false) return false end
    if mode ~= "out" and mode ~= "combat" and mode ~= "encounter" then return false end
    if not C_Timer or type(C_Timer.NewTicker) ~= "function" then self:NotifySelf(L["Diagnostic timer unavailable"], false) return false end
    if mode == "encounter" and type(IsEncounterInProgress) ~= "function" then
        self:NotifySelf(L["Diagnostic timer unavailable"], false) return false
    end
    self:SetChatDiagnosticsEnabled(true)
    local run = {mode=mode, index=1, nextAt=GetTime()+5, deadline=GetTime()+300}
    self.diagnosticSuite=run
    self:RecordChatDiagnostic("SUITE_START", {mode=mode})
    self:NotifySelf(L["Diagnostic suite started"], false)
    run.ticker = C_Timer.NewTicker(.5, function()
        if self.diagnosticSuite ~= run then return end
        local now=GetTime()
        if now >= run.deadline then
            self:RecordChatDiagnostic("SUITE_EXPIRED", {mode=mode, next=channels[run.index]})
            self:CancelChatDiagnosticSuite()
            self:NotifySelf(L["Diagnostic suite expired"], false) return
        end
        if now < run.nextAt or now < (self.nextChatSendAt or 0) then return end
        local combat, combatError = self:ReadChatAPI(InCombatLockdown)
        local encounter, encounterError = self:ReadChatAPI(IsEncounterInProgress)
        if combatError or (encounterError and encounterError ~= "unavailable") then return end
        if encounterError == "unavailable" then encounter=false end
        local matches = (mode == "out" and combat == false and encounter == false)
            or (mode == "combat" and combat == true and encounter == false)
            or (mode == "encounter" and encounter == true)
        if not matches then return end
        local channel=channels[run.index]
        local target, reason=prerequisite(channel)
        sequence=sequence+1
        local id=session .. "-" .. sequence
        if reason then self:RecordChatDiagnostic("SKIPPED", {channel=channel, reason=reason, test=id})
        else
            -- DE: Bewusster einmaliger Restriktionstest, keine Umgehung und kein Retry bei Blockierung.
            -- EN: Explicit one-shot restriction probe, no bypass and no retry when blocked.
            self:SendChatMessageSafe("[QA-DIAG " .. id .. "] " .. L["Diagnostic test message"], channel, nil, target, id)
        end
        run.index=run.index+1; run.nextAt=now+8
        if run.index > #channels then
            self:RecordChatDiagnostic("SUITE_END", {mode=mode})
            self.diagnosticSuite=nil; run.ticker:Cancel()
            self:ScheduleChatWake(0)
            self:NotifySelf(L["Diagnostic suite finished"], false)
        end
    end)
    return true
end
function QA:TestLocalDiagnosticFrames()
    if self.diagnosticSuite or self.diagnosticLocalPending then self:NotifySelf(L["Diagnostic test already running"], false) return end
    self:InitializeDiagnostics()
    self:SetChatDiagnosticsEnabled(true)
    -- DE: Timer trennt Test vom Hardwareklick; derselbe lokale Ausgabeweg wie echte Meldungen.
    -- EN: Timer separates the probe from the hardware click; use the real local output paths.
    if not C_Timer or not C_Timer.After then return end
    local generation=self.diagnosticLocalGeneration or 0
    self.diagnosticLocalPending=true
    C_Timer.After(5, function()
        if generation ~= (self.diagnosticLocalGeneration or 0) then return end
        self.diagnosticLocalPending=nil
        local function probe(name, fn)
            self.currentChatAttempt={channel=name}
            self:RecordChatDiagnostic("LOCAL_ATTEMPT", {channel=name})
            local ok, value=pcall(fn, self, L["Diagnostic test message"])
            local blocked=self.currentChatAttempt.blocked == true
            self.currentChatAttempt=nil
            self:RecordChatDiagnostic("LOCAL_RETURNED", {channel=name, success=ok and value == true, blocked=blocked})
        end
        probe("UIErrorsFrame", self.AddUIErrorMessageSafe)
        probe("AddonRaidNoticeFrame", self.AddRaidNoticeMessageSafe)
    end)
end
function QA:ChatDiagnosticCommand(input)
    self:InitializeDiagnostics()
    local command, rest=(input or ""):match("^%s*(%S*)%s*(.-)%s*$")
    command=command:lower()
    if command == "on" or command == "off" then self:SetChatDiagnosticsEnabled(command == "on")
    elseif command == "suite" then if not self:StartChatDiagnosticSuite(rest:lower()) then self:NotifySelf(L["Diagnostic command help"], false) end
    elseif command == "cancel" then self:CancelChatDiagnosticSuite(); self:NotifySelf(L["Diagnostic test cancelled"], false)
    elseif command == "clear" then self:ClearChatDiagnosticLog()
    elseif command == "frames" then self:TestLocalDiagnosticFrames()
    elseif command == "whisper" or command == "channel" then
        if self.diagnosticSuite then self:NotifySelf(L["Diagnostic test already running"], false) return end
        QuestAnnounceDiagnosticsDB.settings[command]=rest ~= "" and rest:sub(1,120) or nil
        self:NotifySelf(L["Diagnostic target saved"], false)
    elseif command == "received" then
        local id=rest:match("^([%w%.%-]+)$")
        if id then self:RecordChatDiagnostic("MANUAL_RECEIPT", {test=id}); self:NotifySelf(L["Diagnostic receipt saved"], false)
        else self:NotifySelf(L["Diagnostic command help"], false) end
    elseif command == "status" then
        self:NotifySelf(L[QuestAnnounceDiagnosticsDB.enabled and "Diagnostics enabled" or "Diagnostics disabled"]
            .. " (" .. #QuestAnnounceDiagnosticsDB.records .. ")", false)
    else self:NotifySelf(L["Diagnostic command help"], false) end
end

-- DE: Ereignisse nur beobachten, keine Chatfilter/secure Hooks installieren.
-- EN: Observe events only; install no chat filters or secure hooks.
for _, event in ipairs({"ADDON_ACTION_BLOCKED", "ADDON_ACTION_FORBIDDEN", "ADDON_RESTRICTION_STATE_CHANGED",
    "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "PLAYER_ENTERING_WORLD", "ENCOUNTER_START", "ENCOUNTER_END",
    "CHAT_MSG_SAY", "CHAT_MSG_YELL", "CHAT_MSG_EMOTE", "CHAT_MSG_PARTY", "CHAT_MSG_PARTY_LEADER", "CHAT_MSG_RAID",
    "CHAT_MSG_RAID_LEADER", "CHAT_MSG_RAID_WARNING", "CHAT_MSG_INSTANCE_CHAT", "CHAT_MSG_INSTANCE_CHAT_LEADER",
    "CHAT_MSG_GUILD", "CHAT_MSG_OFFICER", "CHAT_MSG_WHISPER", "CHAT_MSG_WHISPER_INFORM", "CHAT_MSG_CHANNEL"}) do
    pcall(frame.RegisterEvent, frame, event)
end
frame:SetScript("OnEvent", function(_, event, arg1, arg2)
    if not QuestAnnounceDiagnosticsDB or not QuestAnnounceDiagnosticsDB.enabled then return end
    if event:find("^CHAT_MSG_") then
        if QA:IsReadable(arg1) and type(arg1) == "string" then
            local id=arg1:match("^%[QA%-DIAG ([%w%.%-]+)%]")
            if id then
                local own=event == "CHAT_MSG_WHISPER_INFORM"
                if QA:IsReadable(arg2) and type(arg2) == "string" then
                    local player=QA:ReadChatAPI(GetUnitName, "player", true)
                    own=own or player == arg2
                end
                QA:RecordChatDiagnostic(own and "LOCAL_ECHO" or "OBSERVED_TEST_MESSAGE", {event=event, test=id})
            end
        end
    elseif event == "ADDON_ACTION_BLOCKED" or event == "ADDON_ACTION_FORBIDDEN" then
        local attempt
        if QA:IsReadable(arg1) and arg1 == "QuestAnnounce" then attempt=QA.currentChatAttempt end
        QA:RecordChatDiagnostic(event, {addon=arg1, func=arg2,
            test=attempt and attempt.test,
            channel=attempt and attempt.channel})
    else
        QA:RecordChatDiagnostic(event, {restriction=arg1, state=arg2})
        if event == "ADDON_RESTRICTION_STATE_CHANGED" and C_Timer and C_Timer.After then
            C_Timer.After(0, function() QA:RecordChatDiagnostic("STATE_AFTER_EVENT", {}) end)
        end
    end
end)
SLASH_QUESTANNOUNCEDIAGNOSTICS1="/qadiag"
SlashCmdList.QUESTANNOUNCEDIAGNOSTICS=function(input) QA:ChatDiagnosticCommand(input) end
