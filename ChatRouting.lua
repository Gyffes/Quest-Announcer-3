local QA = QuestAnnounce
local routes = {say="SAY", party="PARTY", instance="INSTANCE_CHAT", raid="RAID",
    emote="EMOTE", guild="GUILD", officer="OFFICER", whisper="WHISPER", focus="WHISPER", channel="CHANNEL"}
local TTL, INTERVAL = 10, 1
local routeOrder={"say", "party", "instance", "raid", "emote", "guild", "officer", "focus", "whisper", "channel", "group"}
local groupRoutes={party=true,raid=true,instance=true}
local groupPresets={
    INSTANCE_RAID_PARTY={"instance","raid","party"}, RAID_INSTANCE_PARTY={"raid","instance","party"},
    INSTANCE_PARTY_RAID={"instance","party","raid"}, RAID_PARTY_INSTANCE={"raid","party","instance"},
    PARTY_INSTANCE_RAID={"party","instance","raid"}, PARTY_RAID_INSTANCE={"party","raid","instance"},
}
local presetOrder={"INSTANCE_RAID_PARTY","RAID_INSTANCE_PARTY","INSTANCE_PARTY_RAID",
    "RAID_PARTY_INSTANCE","PARTY_INSTANCE_RAID","PARTY_RAID_INSTANCE"}

-- DE: Nur stabile Preset-IDs speichern; lokalisierte Namen dienen nur der Anzeige.
-- EN: Store stable preset IDs only; localized names are presentation, not profile data.
function QA:GetGroupPriorityID(value)
    return type(value)=="string" and groupPresets[value] and value or "INSTANCE_RAID_PARTY"
end
function QA:GetGroupPriorityChoices()
    local L=QuestAnnounce_L[GetLocale()] or QuestAnnounce_L.enUS
    local labels={instance=L["Instance"],raid=L["Raid"],party=L["Party"]}
    local choices={}
    for _,id in ipairs(presetOrder) do
        local p=groupPresets[id]
        choices[#choices+1]={value=id,text=labels[p[1]] .. " > " .. labels[p[2]] .. " > " .. labels[p[3]]}
    end
    return choices
end

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
-- DE: Globale und unklare Sperren betreffen jeden Kandidaten, nicht nur den ersten Kanal.
-- EN: Global/unknown restrictions affect every candidate, not just the first channel.
function QA:GetGlobalChatRestriction()
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
    return false
end

-- DE: Vierter Rückgabewert trennt Kanal- von globalen Sperren, ohne alte Aufrufer zu ändern.
-- EN: A fourth return value separates channel/global restrictions without changing old callers.
function QA:IsChatSendRestricted(chatType)
    -- DE: Nur ein tatsächlicher eigener Schutzfehler sperrt bis Reload, keine normale Vorab-Ablehnung.
    -- EN: Only an actual own protection failure latches until reload, not an ordinary preflight rejection.
    if self.chatBlockedChannels and self.chatBlockedChannels[chatType] then
        return true, "previous protected send", false, "channel"
    end
    local restricted,reason,retry=self:GetGlobalChatRestriction()
    if restricted then return true,reason,retry,"global" end
    if self:HasMeasuredRetailChatPolicy() and chatType == "GUILD" then
        -- DE: GUILD war auch bei Map=0/Chat=0 blockiert. Bis zur Klärung konservativ
        --     auslassen; Profilwahl erhalten. Dies ist keine allgemeine Blizzard-Regel.
        -- EN: GUILD was blocked even at Map=0/Chat=0. Conservatively skip it until
        --     resolved, preserving the profile choice. This is not a universal Blizzard rule.
        return true, "guild automatic sending unverified", false, "channel"
    end
    if self:IsPublicChatType(chatType) then
        local allowed, reason = self:IsPublicChatAllowed(chatType)
        if not allowed then return true, reason, false, "channel" end
    end
    return false
end

-- DE: Keine Probe senden. Nur aktivierte, passende und unabhängig erlaubte Kandidaten wählen.
-- EN: Never probe by sending. Choose only enabled, eligible and independently permitted routes.
function QA:SelectAutomaticGroupRoute(profile)
    local blocked,reason,retry=self:GetGlobalChatRestriction()
    if blocked then return nil,reason,retry end
    local order=groupPresets[self:GetGroupPriorityID(profile.settings.groupChannelPriority)]
    for _,key in ipairs(order) do
        local eligible=false
        if profile.announceIn[key] then
            if key=="raid" then eligible=self:ReadChatAPI(IsInRaid)==true
            elseif key=="instance" and LE_PARTY_CATEGORY_INSTANCE~=nil then
                eligible=self:ReadChatAPI(IsInGroup,LE_PARTY_CATEGORY_INSTANCE)==true
            elseif key=="party" and LE_PARTY_CATEGORY_HOME~=nil then
                eligible=self:ReadChatAPI(IsInGroup,LE_PARTY_CATEGORY_HOME)==true
                    and self:ReadChatAPI(IsInRaid,LE_PARTY_CATEGORY_HOME)==false
            end
        end
        if eligible then
            local restricted,why,later,scope=self:IsChatSendRestricted(routes[key])
            if not restricted then return key end
            if scope~="channel" then return nil,why,later end
            self:ChatRecord("GROUP_CANDIDATE_SKIPPED",{channel=routes[key],reason=why})
        end
    end
    return nil,"no eligible group route",false
end
function QA:GetGroupQueueSignature(profile)
    local p=profile.announceIn
    return self:GetGroupPriorityID(profile.settings.groupChannelPriority) .. ":"
        .. tostring(p.raid==true) .. tostring(p.instance==true) .. tostring(p.party==true)
end
-- DE/EN: Nur betroffene Gruppenaufträge verwerfen / invalidate group work, not unrelated routes.
function QA:InvalidateGroupChatQueue()
    for _,key in ipairs({"group","party","raid","instance"}) do
        if self.pendingChatRoutes then self.pendingChatRoutes[key]=nil end
        if self.chatEventQueues then self.chatEventQueues[key]=nil end
    end
end

-- DE: Abschlussereignisse begrenzt erhalten; normale Fortschritte bleiben Latest-wins.
-- EN: Retain bounded milestone events; ordinary progress remains latest-wins.
function QA:QueueChatRoute(key,item,metadata)
    if type(metadata)~="table" or not metadata.eventID then self.pendingChatRoutes[key]=item; return end
    self.chatEventQueues=self.chatEventQueues or {}
    self.chatEventSeen=self.chatEventSeen or {}
    local now=GetTime()
    for token,expires in pairs(self.chatEventSeen) do if expires<=now then self.chatEventSeen[token]=nil end end
    local token=key .. ":" .. tostring(metadata.eventID)
    if self.chatEventSeen[token] then return end
    local count=0
    for _,queue in pairs(self.chatEventQueues) do count=count+#queue end
    local queue=self.chatEventQueues[key] or {}
    if #queue>=8 or count>=64 then self:ChatRecord("SKIPPED",{channel=routes[key],reason="milestone queue full"}); return end
    item.metadata=metadata
    queue[#queue+1]=item
    self.chatEventQueues[key]=queue
    self.chatEventSeen[token]=item.expires
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
function QA:SendChatMessageSafe(msg, chatType, languageID, target, diagnosticID, respectPolicy)
    if not self:ValidChatText(msg) or (target ~= nil and not self:IsReadable(target)) then
        return false, "invalid or secret message/target", false
    end
    if not diagnosticID or respectPolicy then
        local restricted, reason, retry = self:IsChatSendRestricted(chatType)
        if restricted then
            if not diagnosticID and reason == "guild automatic sending unverified" and not self.guildPolicyNotice then
                self.guildPolicyNotice=true
                self:NotifySelf((QuestAnnounce_L[GetLocale()] or QuestAnnounce_L.enUS)["Guild sending safety notice"],false)
            end
            return false, reason, retry
        end
    end
    local now = GetTime()
    if now < (self.nextChatSendAt or 0) then return false, "send spacing", true end
    local sender = C_ChatInfo and C_ChatInfo.SendChatMessage or SendChatMessage
    if type(sender) ~= "function" then return false, "chat API unavailable", false end
    self.nextChatSendAt = now + INTERVAL
    local attempt = {channel=chatType, test=diagnosticID,
        source=diagnosticID and (respectPolicy and "diagnostic normal" or "diagnostic probe") or "normal"}
    self.currentChatAttempt = attempt
    self:ChatRecord("ATTEMPT", attempt)
    local ok, result = pcall(sender, msg, chatType, languageID, target)
    self.currentChatAttempt = nil
    self:ChatRecord(ok and "CALL_RETURNED" or "LUA_ERROR",
        {channel=chatType, test=diagnosticID, result=not ok and "Lua error (message omitted)" or (self:IsReadable(result) and tostring(result) or "secret"),
        blocked=attempt.blocked == true})
    if attempt.blocked then
        if not diagnosticID then
            self.chatBlockedChannels=self.chatBlockedChannels or {}
            self.chatBlockedChannels[chatType]=true
            self:NotifySelf(chatType .. ": " .. (QuestAnnounce_L[GetLocale()] or QuestAnnounce_L.enUS)
                ["Diagnostic reason previous protected send"],false)
        end
        return false, "blocked action", false
    end
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
    if reason=="pause changed" or reason=="enable changed" or reason=="profile changed" or reason=="player died" then
        self:ResetObjectiveAnnouncementBaseline()
    end
    self.pendingChatRoutes = {}
    self.chatEventQueues = {}
    self.chatEventSeen = {}
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
        local events=self.chatEventQueues and self.chatEventQueues[key]
        local isEvent=events and #events>0
        local item = isEvent and events[1] or self.pendingChatRoutes and self.pendingChatRoutes[key]
        local consumed=false
        local function consume()
            consumed=true
            if isEvent then table.remove(events,1) else self.pendingChatRoutes[key]=nil end
        end
        if item then
            local auto=profile.settings.autoGroupChannel==true
            local invalid = item.profile ~= profile or not profile.announceTo.chatFrame
                or (key~="group" and (not profile.announceIn[key] or not self:IsChatRouteAvailable(key, item.target)))
                or (groupRoutes[key] and auto)
                or (key=="group" and (not auto or item.groupSignature~=self:GetGroupQueueSignature(profile)
                    or item.rosterGeneration~=(self.groupRosterGeneration or 0)))
                or (item.metadata and self.IsObjectiveMessageCurrent and not self:IsObjectiveMessageCurrent(item.metadata))
                or (key == "whisper" and profile.announceIn.whisperWho ~= item.target)
                or (key == "channel" and profile.announceIn.channelName ~= item.target)
            if invalid or now >= item.expires then
                consume()
                self:ChatRecord(invalid and "SKIPPED" or "EXPIRED", {channel=routes[key], reason="route changed or expired"})
            else
                -- DE: Aktive Diagnose reserviert die Sendeschritte; normale Ziele warten begrenzt.
                -- EN: Active diagnostics reserve send slots; regular destinations wait within their TTL.
                local ok, reason, retry
                local chatType=routes[key]
                if self.diagnosticSuite and (not self.diagnosticSuite.paired or self.diagnosticSuite.prepared) then
                    ok, reason, retry = false, "diagnostic suite", true
                else
                    local target=item.target
                    if key=="group" then
                        local selected
                        selected,reason,retry=self:SelectAutomaticGroupRoute(profile)
                        if selected then chatType=routes[selected]
                        else ok=false end
                    end
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
                    if ok == nil then ok, reason, retry = self:SendChatMessageSafe(item.msg, chatType, nil, target) end
                end
                if ok or not retry then consume() end
                if ok then self.nextChatRouteIndex=index%#routeOrder+1 end
                self:ChatRecord(ok and "ATTEMPT_COMPLETED" or (retry and "DEFERRED" or "SKIPPED"), {channel=chatType, reason=reason})
                if not ok and retry then
                    local delay = item.expires - now
                    if reason == "send spacing" then delay = math.min(delay, math.max(.05, (self.nextChatSendAt or now) - now)) end
                    if reason == "channel join pending" then delay=math.min(delay,1) end
                    nextWake = math.min(nextWake or delay, delay)
                end
            end
            if isEvent and consumed and (#events>0 or (self.pendingChatRoutes and self.pendingChatRoutes[key])) then
                local delay=math.max(.05,(self.nextChatSendAt or now)-now)
                nextWake=math.min(nextWake or delay,delay)
            end
        end
    end
    if nextWake then self:ScheduleChatWake(nextWake) end
end
function QA:DispatchChatOutputs(msg,metadata)
    local p = self.db and self.db.profile
    if not p or not p.settings.enable or p.settings.paused or not p.announceTo.chatFrame then
        self:ClearPendingChat("chat disabled") return false
    end
    if not self:ValidChatText(msg) then self:ChatRecord("SKIPPED", {reason="invalid message"}) return false end
    self.pendingChatRoutes = self.pendingChatRoutes or {}
    if p.settings.autoGroupChannel==true then
        self:QueueChatRoute("group",{msg=msg,profile=p,expires=GetTime()+TTL,
            groupSignature=self:GetGroupQueueSignature(p),rosterGeneration=self.groupRosterGeneration or 0},metadata)
    end
    for key in pairs(routes) do
        if p.announceIn[key] and not (p.settings.autoGroupChannel==true and groupRoutes[key]) then
            local target
            if key == "whisper" then target=p.announceIn.whisperWho
            elseif key == "focus" then target=self:GetFocusWhisperTarget()
            elseif key == "channel" then target=p.announceIn.channelName end
            if self:IsChatRouteAvailable(key, target) then
                -- DE: Gleicher Empfaenger bei Fokus und Whisper bekommt nur eine Meldung.
                -- EN: A recipient selected by both Focus and Whisper receives only one message.
                if key ~= "focus" or not p.announceIn.whisper or p.announceIn.whisperWho ~= target then
                    self:QueueChatRoute(key,{msg=msg, target=target, profile=p, expires=GetTime()+TTL},metadata)
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
    if event=="GROUP_ROSTER_UPDATE" or event=="PLAYER_ENTERING_WORLD" then
        -- DE/EN: Alte automatische Aufträge nicht in neue Gruppen senden / never reroute old jobs into a new group.
        QA.groupRosterGeneration=(QA.groupRosterGeneration or 0)+1
    end
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
