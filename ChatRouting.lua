local QA = QuestAnnounce
local routes = {say="SAY", party="PARTY", instance="INSTANCE_CHAT", raid="RAID",
    emote="EMOTE", guild="GUILD", officer="OFFICER", whisper="WHISPER", focus="WHISPER", channel="CHANNEL"}
local TTL, INTERVAL = 10, 1
local routeOrder={"say", "party", "instance", "raid", "emote", "guild", "officer", "focus", "whisper", "channel"}

-- DE: Geheime Werte vor Typ-, Vergleichs- oder Stringoperationen aussortieren.
-- EN: Reject secret values before type checks, comparisons or string operations.
function QA:IsReadable(value)
    return not (issecretvalue and issecretvalue(value))
end
function QA:ReadChatAPI(fn, ...)
    if type(fn) ~= "function" then return nil, "unavailable" end
    local ok, value = pcall(fn, ...)
    if not ok then return nil, "query error" end
    if not self:IsReadable(value) then return nil, "secret" end
    return value
end
function QA:GetRestrictionState(name)
    local types = Enum and Enum.AddOnRestrictionType
    if not types or types[name] == nil then return nil, "unavailable" end
    local value, reason=self:ReadChatAPI(C_RestrictedActions and C_RestrictedActions.GetAddOnRestrictionState, types[name])
    if value == nil and not reason then return nil,"nil restriction result" end
    return value,reason
end
function QA:HasMeasuredRetailChatPolicy()
    -- DE: Nur Retail mit moderner API ist gemessen; andere Clients behalten den Kampffallback.
    -- EN: Only Retail with the modern API was measured; other clients retain the combat fallback.
    return WOW_PROJECT_MAINLINE ~= nil and WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
        and C_ChatInfo and type(C_ChatInfo.InChatMessagingLockdown) == "function"
end
function QA:IsPublicChatType(chatType)
    return chatType == "SAY" or chatType == "YELL" or chatType == "EMOTE" or chatType == "CHANNEL"
end
function QA:IsPublicChatAllowed(chatType)
    if self:HasMeasuredRetailChatPolicy() then
        if chatType == "CHANNEL" then return false, "automatic custom channel blocked" end
        if chatType == "EMOTE" then return true end
    end
    local inside = self:ReadChatAPI(IsInInstance)
    local ok, _, instanceType = pcall(IsInInstance)
    if inside == true and ok and self:IsReadable(instanceType)
        and instanceType ~= "pvp" and instanceType ~= "arena" then return true end
    return false, "automatic public chat restriction"
end

-- DE: Gemeinsame Sperren und Kanalregeln; fehlende/unsichere Abfragen geben keine Freigabe.
-- EN: Shared restrictions and channel rules; missing/unsafe queries never grant permission.
function QA:IsChatSendRestricted(chatType)
    local locked, err = self:ReadChatAPI(C_ChatInfo and C_ChatInfo.InChatMessagingLockdown)
    if locked == true then return true, "chat messaging lockdown", true end
    if locked == nil and not err then return true,"nil chat lockdown result",true end
    if err and err ~= "unavailable" then return true, err, true end
    for _, name in ipairs({"Chat", "Encounter"}) do
        local state, stateError = self:GetRestrictionState(name)
        if stateError and stateError ~= "unavailable" then return true, stateError, true end
        if state ~= nil and state ~= 0 then return true, name .. " restriction", true end
        local types = Enum and Enum.AddOnRestrictionType
        if types and types[name] ~= nil and self.restrictionTransition
            and self.restrictionTransition[types[name]] then return true, name .. " activating", true end
    end
    local encounter, encounterError = self:ReadChatAPI(IsEncounterInProgress)
    if encounter == true then return true, "encounter in progress", true end
    if encounterError and encounterError ~= "unavailable" then return true, encounterError, true end
    local combat, combatError = self:ReadChatAPI(InCombatLockdown)
    if combatError then return true, "combat status " .. combatError, true end
    if combat and not self:HasMeasuredRetailChatPolicy() then
        return true, "unverified client combat fallback", true
    end
    if self:HasMeasuredRetailChatPolicy() and chatType == "GUILD" then
        local map, mapError = self:GetRestrictionState("Map")
        local types = Enum and Enum.AddOnRestrictionType
        if mapError or map ~= 0 or (types and self.restrictionTransition and self.restrictionTransition[types.Map]) then
            return true, "map restriction or unavailable map status", true
        end
    end
    if self:IsPublicChatType(chatType) then
        local allowed, reason = self:IsPublicChatAllowed(chatType)
        if not allowed then return true, reason, false end
    end
    return false
end
function QA:GetChannelNameSafe(name)
    if not self:IsReadable(name) or type(name) ~= "string" or name == "" then return nil end
    local id = self:ReadChatAPI(GetChannelName, name)
    if type(id) == "number" and id > 0 then return id end
end
function QA:JoinTemporaryChannelSafe(name)
    if type(name) ~= "string" or name == "" then return false end
    local restricted, reason = self:IsChatSendRestricted("CHANNEL")
    if restricted then return false, reason end
    if type(JoinTemporaryChannel) ~= "function" then return false, "unavailable" end
    return pcall(JoinTemporaryChannel, name)
end
function QA:ChatRecord(kind, data)
    if self.RecordChatDiagnostic then self:RecordChatDiagnostic(kind, data) end
    -- DE: Den bestehenden Debugschalter weiterhin mit Versandentscheidungen bedienen.
    -- EN: Keep exposing send decisions through the existing debug switch.
    if self.db and self.db.profile and self.db.profile.settings.debug then
        self:SendDebugMsg("Chat " .. kind .. " :: " .. tostring(data and data.channel or "-")
            .. " :: " .. tostring(data and data.reason or "-"))
    end
end
function QA:ValidChatText(text)
    if not self:IsReadable(text) or type(text) ~= "string" then return false end
    -- DE: Keine Links/UTF-8 abschneiden; überlange oder mehrzeilige Texte verwerfen.
    -- EN: Never truncate links/UTF-8; reject oversized or multiline messages.
    return #text > 0 and #text <= 255 and not text:find("[%z\r\n]")
end

-- DE: Ein gemeinsamer Zeitabstand für echte Meldungen und ausdrücklich gestartete Tests.
-- EN: One shared send interval for real announcements and explicitly started tests.
function QA:SendChatMessageSafe(msg, chatType, languageID, target, diagnosticID)
    if not self:ValidChatText(msg) or (target ~= nil and not self:IsReadable(target)) then
        return false, "invalid or secret message/target", false
    end
    if not diagnosticID then
        local restricted, reason, retry = self:IsChatSendRestricted(chatType)
        if restricted then return false, reason, retry end
    end
    local now = GetTime()
    if now < (self.nextChatSendAt or 0) then return false, "send spacing", true end
    local sender = C_ChatInfo and C_ChatInfo.SendChatMessage or SendChatMessage
    if type(sender) ~= "function" then return false, "chat API unavailable", false end
    self.nextChatSendAt = now + INTERVAL
    local attempt = {channel=chatType, test=diagnosticID}
    self.currentChatAttempt = attempt
    self:ChatRecord("ATTEMPT", attempt)
    local ok, result = pcall(sender, msg, chatType, languageID, target)
    self.currentChatAttempt = nil
    self:ChatRecord(ok and "CALL_RETURNED" or "LUA_ERROR",
        {channel=chatType, test=diagnosticID, result=not ok and "Lua error (message omitted)" or (self:IsReadable(result) and tostring(result) or "secret"),
        blocked=attempt.blocked == true})
    if attempt.blocked then return false, "blocked action", false end
    if not ok then return false, "Lua send error", false end
    return true
end

function QA:HasConfiguredChatDestination(options)
    if not options then return false end
    for key in pairs(routes) do if options[key] then return true end end
    return false
end
function QA:GetFocusWhisperTarget()
    if self:ReadChatAPI(UnitIsPlayer, "focus") ~= true then return nil end
    if type(GetUnitName) == "function" then
        local full = self:ReadChatAPI(GetUnitName, "focus", true)
        if type(full) == "string" and full ~= "" then return full end
    end
    if type(UnitFullName) == "function" then
        local ok, name, realm = pcall(UnitFullName, "focus")
        if ok and self:IsReadable(name) and self:IsReadable(realm) and type(name) == "string" then
            return realm and realm ~= "" and (name .. "-" .. realm) or name
        end
    end
end
function QA:IsChatRouteAvailable(key, target)
    if key == "party" then
        return self:ReadChatAPI(IsInGroup, LE_PARTY_CATEGORY_HOME) == true
            and self:ReadChatAPI(IsInRaid, LE_PARTY_CATEGORY_HOME) ~= true
    elseif key == "instance" then return self:ReadChatAPI(IsInGroup, LE_PARTY_CATEGORY_INSTANCE) == true
    elseif key == "raid" then return self:ReadChatAPI(IsInRaid) == true
    elseif key == "guild" or key == "officer" then
        if self:ReadChatAPI(IsInGuild) ~= true then return false end
        -- DE: CanEditOfficerNote ist keine Sprechberechtigung; nicht als solche benutzen.
        -- EN: CanEditOfficerNote is not permission to speak; do not treat it as such.
        return true
    elseif key == "whisper" or key == "focus" then
        return self:IsReadable(target) and type(target) == "string" and target ~= ""
    elseif key == "channel" then
        return self:IsReadable(target) and type(target) == "string" and target ~= ""
            and (self:GetChannelNameSafe(target) ~= nil or not self:HasMeasuredRetailChatPolicy())
    end
    return true
end
function QA:ClearPendingChat(reason)
    self.pendingChatRoutes = {}
    self.chatQueueGeneration = (self.chatQueueGeneration or 0) + 1
    self.chatWakeScheduled = nil
    self.chatWakeAt = nil
    self:ChatRecord("QUEUE_CLEARED", {reason=reason})
end
function QA:ScheduleChatWake(delay)
    if not C_Timer or not C_Timer.After then return end
    local at=GetTime()+delay
    if self.chatWakeAt and self.chatWakeAt <= at then return end
    self.chatWakeSerial=(self.chatWakeSerial or 0)+1
    local serial=self.chatWakeSerial
    self.chatWakeScheduled = true
    self.chatWakeAt=at
    local generation = self.chatQueueGeneration or 0
    C_Timer.After(delay, function()
        if generation ~= (self.chatQueueGeneration or 0) or serial ~= self.chatWakeSerial then return end
        self.chatWakeScheduled = nil
        self.chatWakeAt = nil
        self:FlushPendingCombatChatMessage()
    end)
end
function QA:FlushPendingCombatChatMessage()
    local profile = self.db and self.db.profile
    if not profile or not profile.settings.enable or profile.settings.paused then
        self:ClearPendingChat("disabled or paused") return
    end
    local now, nextWake = GetTime(), nil
    -- DE: Wechselnder Start verhindert, dass haeufige Meldungen spaetere Ziele verdraengen.
    -- EN: Rotate the start to prevent frequent announcements from starving later destinations.
    local start=self.nextChatRouteIndex or 1
    for offset=0,#routeOrder-1 do
        local index=(start+offset-1)%#routeOrder+1
        local key=routeOrder[index]
        local item = self.pendingChatRoutes and self.pendingChatRoutes[key]
        if item then
            local invalid = item.profile ~= profile or not profile.announceTo.chatFrame
                or not profile.announceIn[key] or not self:IsChatRouteAvailable(key, item.target)
                or (key == "whisper" and profile.announceIn.whisperWho ~= item.target)
                or (key == "channel" and profile.announceIn.channelName ~= item.target)
            if invalid or now >= item.expires then
                self.pendingChatRoutes[key] = nil
                self:ChatRecord(invalid and "SKIPPED" or "EXPIRED", {channel=routes[key], reason="route changed or expired"})
            else
                -- DE: Aktive Diagnose reserviert die Sendeschritte; normale Ziele warten begrenzt.
                -- EN: Active diagnostics reserve send slots; regular destinations wait within their TTL.
                local ok, reason, retry
                if self.diagnosticSuite then ok, reason, retry = false, "diagnostic suite", true
                else
                    local target=item.target
                    if key == "channel" then target=self:GetChannelNameSafe(item.target) end
                    if key == "channel" and not target then
                        -- DE: Alten Beitritt auf erlaubten Clients erhalten; hoechstens einmal je Meldung.
                        -- EN: Preserve joining on permitted clients; at most once per queued message.
                        local restricted, why, later=self:IsChatSendRestricted("CHANNEL")
                        if restricted then ok,reason,retry=false,why,later
                        else
                            if not item.joinAttempted then
                                item.joinAttempted=true
                                self:JoinTemporaryChannelSafe(item.target)
                            end
                            target=self:GetChannelNameSafe(item.target)
                            if not target then ok,reason,retry=false,"channel join pending",true end
                        end
                    end
                    if ok == nil then ok, reason, retry = self:SendChatMessageSafe(item.msg, routes[key], nil, target) end
                end
                if ok or not retry then self.pendingChatRoutes[key] = nil end
                if ok then self.nextChatRouteIndex=index%#routeOrder+1 end
                self:ChatRecord(ok and "ATTEMPT_COMPLETED" or (retry and "DEFERRED" or "SKIPPED"), {channel=routes[key], reason=reason})
                if not ok and retry then
                    local delay = item.expires - now
                    if reason == "send spacing" then delay = math.min(delay, math.max(.05, (self.nextChatSendAt or now) - now)) end
                    if reason == "channel join pending" then delay=math.min(delay,1) end
                    nextWake = math.min(nextWake or delay, delay)
                end
            end
        end
    end
    if nextWake then self:ScheduleChatWake(nextWake) end
end
function QA:DispatchChatOutputs(msg)
    local p = self.db and self.db.profile
    if not p or not p.settings.enable or p.settings.paused or not p.announceTo.chatFrame then
        self:ClearPendingChat("chat disabled") return false
    end
    if not self:ValidChatText(msg) then self:ChatRecord("SKIPPED", {reason="invalid message"}) return false end
    self.pendingChatRoutes = self.pendingChatRoutes or {}
    for key in pairs(routes) do
        if p.announceIn[key] then
            local target
            if key == "whisper" then target=p.announceIn.whisperWho
            elseif key == "focus" then target=self:GetFocusWhisperTarget()
            elseif key == "channel" then target=p.announceIn.channelName end
            if self:IsChatRouteAvailable(key, target) then
                -- DE: Gleicher Empfaenger bei Fokus und Whisper bekommt nur eine Meldung.
                -- EN: A recipient selected by both Focus and Whisper receives only one message.
                if key ~= "focus" or not p.announceIn.whisper or p.announceIn.whisperWho ~= target then
                    self.pendingChatRoutes[key] = {msg=msg, target=target, profile=p, expires=GetTime()+TTL}
                else self.pendingChatRoutes[key]=nil end
            else
                self:ChatRecord("SKIPPED", {channel=routes[key], reason="missing destination prerequisites"})
                if key == "focus" then
                    self:NotifySelf((QuestAnnounce_L[GetLocale()] or QuestAnnounce_L.enUS)["No focus set, message not sent."],false)
                elseif key == "channel" and (not target or target == "") then
                    self:NotifySelf((QuestAnnounce_L[GetLocale()] or QuestAnnounce_L.enUS)["No channel set."],false)
                end
            end
        end
    end
    self:FlushPendingCombatChatMessage()
    return true
end

-- DE: Eigenes Ereignisframe; keine Hooks in Blizzards globale Chatfunktionen.
-- EN: Owned event frame; no hooks into Blizzard's global chat functions.
local frame = CreateFrame("Frame")
for _, event in ipairs({"ADDON_RESTRICTION_STATE_CHANGED", "ENCOUNTER_END", "PLAYER_ENTERING_WORLD",
    "GROUP_ROSTER_UPDATE", "PLAYER_DEAD", "ADDON_ACTION_BLOCKED", "ADDON_ACTION_FORBIDDEN"}) do
    pcall(frame.RegisterEvent, frame, event)
end
frame:SetScript("OnEvent", function(_, event, arg1, arg2)
    if event == "PLAYER_DEAD" then
        -- DE: Nach dem Tod keine alten Fortschrittsmeldungen oder aktiven Tests nachholen.
        -- EN: Do not replay old progress or resume active tests after death.
        QA:ClearPendingChat("player died")
        if QA.CancelChatDiagnosticSuite then QA:CancelChatDiagnosticSuite("player died") end
        return
    end
    if event == "ADDON_ACTION_BLOCKED" or event == "ADDON_ACTION_FORBIDDEN" then
        if QA:IsReadable(arg1) and arg1 == "QuestAnnounce" and QA.currentChatAttempt then
            QA.currentChatAttempt.blocked = true
        end
        return
    end
    if event == "ADDON_RESTRICTION_STATE_CHANGED" and QA:IsReadable(arg1) and QA:IsReadable(arg2) then
        QA.restrictionTransition = QA.restrictionTransition or {}
        QA.restrictionTransition[arg1] = arg2 ~= 0
    end
    if C_Timer and C_Timer.After then C_Timer.After(0, function()
        if event == "ADDON_RESTRICTION_STATE_CHANGED" then QA.restrictionTransition = {} end
        QA:FlushPendingCombatChatMessage()
    end) end
end)
