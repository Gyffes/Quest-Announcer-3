local QA = QuestAnnounce
local L = QuestAnnounce_L[GetLocale()] or QuestAnnounce_L.enUS
local PREFIX, TTL, LIMIT = "QADiag1", 600, 100
local statuses={waiting=true,pending=true,received=true,manual=true,skipped=true,blocked=true,error=true,
    unconfirmed=true,cancelled=true,["local"]=true}
local queue, registered, receiverSession = {}, false, nil
local eventChannels = {CHAT_MSG_SAY="SAY", CHAT_MSG_YELL="YELL", CHAT_MSG_EMOTE="EMOTE",
    CHAT_MSG_PARTY="PARTY", CHAT_MSG_PARTY_LEADER="PARTY", CHAT_MSG_RAID="RAID",
    CHAT_MSG_RAID_LEADER="RAID", CHAT_MSG_RAID_WARNING="RAID_WARNING", CHAT_MSG_GUILD="GUILD",
    CHAT_MSG_OFFICER="OFFICER", CHAT_MSG_WHISPER="WHISPER", CHAT_MSG_INSTANCE_CHAT="INSTANCE_CHAT",
    CHAT_MSG_INSTANCE_CHAT_LEADER="INSTANCE_CHAT", CHAT_MSG_CHANNEL="CHANNEL"}
local function safeString(value, limit)
    return QA:IsReadable(value) and type(value)=="string" and #value>0 and #value<=(limit or 120)
        and not value:find("[%z\r\n|]")
end
local function validID(id)
    return safeString(id,120) and id:match("^[%w%.%-]+$") ~= nil
end
function QA:NormalizeDiagnosticPlayer(name)
    if not safeString(name) then return nil end
    name=name:gsub("%s", "")
    if not name:find("-",1,true) then
        local realm=self:ReadChatAPI(GetNormalizedRealmName) or self:ReadChatAPI(GetRealmName)
        if not safeString(realm) then return nil end
        name=name .. "-" .. realm:gsub("%s", "")
    end
    return name:lower()
end
function QA:IsOwnDiagnosticSender(sender, guid)
    local mine=self:ReadChatAPI(UnitGUID,"player")
    if safeString(guid) and safeString(mine) then return guid==mine end
    local player=self:ReadChatAPI(GetUnitName,"player",true)
    local normalized=self:NormalizeDiagnosticPlayer(sender)
    return normalized ~= nil and normalized==self:NormalizeDiagnosticPlayer(player)
end
local function peerMatches(sender)
    local db=QuestAnnounceDiagnosticsDB
    local expected=db and QA:NormalizeDiagnosticPlayer(db.settings.partner)
    return expected ~= nil and expected==QA:NormalizeDiagnosticPlayer(sender)
end
local function refresh()
    if QA.RefreshDiagnosticResults then QA:RefreshDiagnosticResults() end
end
-- DE: Aufbau, Sperrwartezeit und Testlauf getrennt anzeigen; keine Partnernamen im Statuslog.
-- EN: Show setup, restriction waiting and execution separately; no peer names in status logs.
function QA:SetDiagnosticPhase(phase, reason)
    local pair=self.diagnosticPair
    local previous=self.diagnosticProgress
    local prepared,total=0,0
    if pair then
        total=#pair.run.tests
        for _,test in ipairs(pair.run.tests) do if test.prepared then prepared=prepared+1 end end
    elseif previous and (phase=="finished" or phase=="cancelled") then
        prepared,total=previous.prepared,previous.total
    end
    if previous and previous.phase==phase and previous.reason==reason and previous.prepared==prepared and previous.total==total then return end
    self.diagnosticProgress={phase=phase,reason=reason,prepared=prepared,total=total}
    self:RecordChatDiagnostic("PEER_PHASE",{phase=phase,reason=reason,prepared=prepared,total=total})
    refresh()
end
function QA:GetDiagnosticReason(reason)
    local key="Diagnostic reason " .. tostring(reason or "unknown")
    return L[key] or L["Diagnostic reason unknown"]
end
local function findResult(id)
    for _, result in ipairs(QuestAnnounceDiagnosticsDB.results) do
        if result.test==id then return result end
    end
end
local function findExpected(id)
    for _, item in ipairs(QuestAnnounceDiagnosticsDB.expectations) do
        if item.test==id then return item end
    end
end
-- DE: Keine Texte/Namen im Ergebnislog; Partneradressen bleiben in den Diagnoseeinstellungen.
-- EN: No text/names in result logs; peer addresses remain in diagnostic settings.
function QA:InitializeDiagnosticPeer(id)
    local db=QuestAnnounceDiagnosticsDB
    receiverSession=id
    db.settings.receive=db.settings.receive==true
    if not safeString(db.settings.partner) then db.settings.partner=nil end
    db.settings.channels=type(db.settings.channels)=="table" and db.settings.channels or {}
    for _, channel in ipairs(self:GetDiagnosticChannels()) do
        if db.settings.channels[channel]==nil then db.settings.channels[channel]=true end
    end
    for _, key in ipairs({"results","expectations","receipts"}) do
        local clean={}
        for _, item in ipairs(type(db[key])=="table" and db[key] or {}) do
            if type(item)=="table" and validID(item.test) and (eventChannels["CHAT_MSG_" .. tostring(item.channel)]
                or key=="results" and (item.channel=="UIErrorsFrame" or item.channel=="AddonRaidNoticeFrame"))
                and type(item.expires)=="number" and item.expires<=time()+TTL then
                if key=="results" and statuses[item.status] or key~="results" and validID(item.remote) and validID(item.token) then
                    if key=="results" and item.status=="waiting" then item.status="cancelled" end
                    clean[#clean+1]=item
                end
            end
        end
        while #clean>LIMIT do table.remove(clean,1) end
        db[key]=clean
    end
    local register=C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix or RegisterAddonMessagePrefix
    local ok, result=false,nil
    if type(register)=="function" then ok,result=pcall(register,PREFIX) end
    -- DE: Alte APIs geben bool/nil zurück, moderne APIs Enum 0/1 (bereits registriert).
    -- EN: Old APIs return bool/nil; modern APIs return enum 0/1 (already registered).
    registered=ok and self:IsReadable(result) and (result==nil or result==true or result==0 or result==1)
    self:RecordChatDiagnostic("PREFIX_REGISTERED",{registered=registered,
        result=ok and self:IsReadable(result) and tostring(result) or "unavailable"})
    if db.enabled then self:WakeDiagnosticPeer() end
end
function QA:CreateDiagnosticResult(id, channel, status, reason)
    local db=QuestAnnounceDiagnosticsDB
    local result={test=id,channel=channel,status=status or "waiting",reason=reason,expires=time()+TTL}
    db.results[#db.results+1]=result
    if #db.results>LIMIT then table.remove(db.results,1) end
    refresh()
    return result
end
function QA:RecordDiagnosticControlState()
    self:RecordChatDiagnostic("CONTROL_STATE",{registered=registered,blocked=self.diagnosticControlBlocked==true,
        receive=QuestAnnounceDiagnosticsDB.settings.receive,partnerConfigured=QuestAnnounceDiagnosticsDB.settings.partner~=nil,
        diagnosticBuild=QA.DIAGNOSTIC_REVISION})
end
function QA:UpdateDiagnosticResult(kind, detail)
    if not detail.test then return end
    local r=findResult(detail.test)
    if not r then return end
    if kind=="ATTEMPT" and detail.channel==r.channel then r.attempted=true
    elseif kind=="LOCAL_ECHO" then r.echo=true
    elseif kind=="REMOTE_RECEIPT" then r.status="received"
    elseif kind=="MANUAL_RECEIPT" then r.status="manual"
    elseif kind=="SKIPPED" then r.status="skipped"; r.reason=detail.reason
    elseif kind=="LUA_ERROR" and detail.channel==r.channel then r.status="error"
    elseif (kind=="ADDON_ACTION_BLOCKED" or kind=="ADDON_ACTION_FORBIDDEN") and detail.channel==r.channel then r.status="blocked"
    elseif kind=="LOCAL_RETURNED" then r.status=detail.blocked and "blocked" or (detail.success and "local" or "error")
    elseif kind=="CALL_RETURNED" then
        r.attempted=true
        if detail.blocked then r.status="blocked" elseif r.status~="received" then r.status="pending" end
    end
    refresh()
end
local function enqueue(kind, fields, test, expires)
    local db=QuestAnnounceDiagnosticsDB
    local destination=QA:NormalizeDiagnosticPlayer(db.settings.partner)
    local function failed(reason)
        QA:RecordChatDiagnostic("CONTROL_QUEUE_REJECTED",{control=kind,reason=reason,test=test})
        return false
    end
    if not destination then return failed("invalid partner") end
    local parts={"1",kind,destination}
    for _, value in ipairs(fields) do
        value=tostring(value)
        if not safeString(value,120) then return failed("invalid control field") end
        parts[#parts+1]=value
    end
    local payload=table.concat(parts,"|")
    if #payload>255 then return failed("control packet too large") end
    for _, item in ipairs(queue) do if item.payload==payload then return true end end
    if #queue>=64 then return failed("control queue full") end
    queue[#queue+1]={payload=payload,test=test,kind=kind,expires=expires or time()+TTL}
    QA:WakeDiagnosticPeer()
    return true
end
local function transport()
    -- DE: Gruppenkanal nur wenn der gewählte Partner tatsächlich im eigenen Roster steht.
    -- EN: Use a group transport only if the selected peer is actually in our roster.
    local function inRoster(prefix, count)
        for index=1,count do
            if peerMatches(QA:ReadChatAPI(GetUnitName,prefix .. index,true)) then return true end
        end
    end
    if QA:ReadChatAPI(IsInRaid)==true and inRoster("raid",40) then
        return QA:ReadChatAPI(IsInGroup,LE_PARTY_CATEGORY_INSTANCE)==true and "INSTANCE_CHAT" or "RAID"
    end
    if inRoster("party",4) then
        return QA:ReadChatAPI(IsInGroup,LE_PARTY_CATEGORY_INSTANCE)==true and "INSTANCE_CHAT" or "PARTY"
    end
    return "WHISPER",QuestAnnounceDiagnosticsDB.settings.partner
end
local function communicationRestricted()
    local locked, err=QA:ReadChatAPI(C_ChatInfo and C_ChatInfo.InChatMessagingLockdown)
    if locked==true or (locked==nil and not err) or (err and err~="unavailable") then return true end
    local state, reason=QA:GetRestrictionState("Chat")
    if (state~=nil and state~=0) or (reason and reason~="unavailable") then return true end
    local types=Enum and Enum.AddOnRestrictionType
    return types and QA.restrictionTransition and QA.restrictionTransition[types.Chat]
end
function QA:CancelDiagnosticPartnerSetup(run)
    if self.diagnosticPair and self.diagnosticPair.run==run then
        self.diagnosticPair=nil
        for index=#queue,1,-1 do
            if queue[index].kind=="HELLO" or queue[index].kind=="EXPECT" or queue[index].kind=="BUILD" then table.remove(queue,index) end
        end
    end
end
local function removeReceipt(test)
    local receipts=QuestAnnounceDiagnosticsDB.receipts
    for index=#receipts,1,-1 do if receipts[index].test==test then table.remove(receipts,index) end end
end
function QA:PumpDiagnosticPeer()
    local db=QuestAnnounceDiagnosticsDB
    if not db or not db.enabled then return end
    local active=false
    for _, r in ipairs(db.results) do
        if r.status=="pending" and r.expires<=time() then
            r.status="unconfirmed"; self:RecordChatDiagnostic("RECEIPT_TIMEOUT",{test=r.test,channel=r.channel})
        elseif r.status=="pending" then active=true end
    end
    for index=#db.expectations,1,-1 do
        if db.expectations[index].expires<=time() then table.remove(db.expectations,index) else active=true end
    end
    -- DE: Nur bestätigte Empfangsdaten über Reload retten; aktive Testserien nie fortsetzen.
    -- EN: Preserve only actual receipt data over reload; never resume active test suites.
    for index=#db.receipts,1,-1 do
        local r=db.receipts[index]
        if r.expires<=time() then
            self:RecordChatDiagnostic("ACK_EXPIRED",{test=r.test,channel=r.channel}); table.remove(db.receipts,index)
        elseif db.settings.receive and validID(r.remote) and validID(r.token) then
            enqueue("ACK",{r.remote,r.test,r.channel,r.token,tostring(r.receivedAt or time())},r.test,r.expires)
        end
    end
    local item=queue[1]
    if item and item.expires<=time() then
        self:RecordChatDiagnostic("CONTROL_EXPIRED",{control=item.kind,test=item.test})
        table.remove(queue,1); item=queue[1]
    end
    if item and registered and not self.diagnosticControlBlocked and GetTime()>=(self.nextDiagnosticControlAt or 0) and not communicationRestricted() then
        local sender=C_ChatInfo and C_ChatInfo.SendAddonMessage or SendAddonMessage
        if type(sender)=="function" then
            local channel,target=transport()
            self.nextDiagnosticControlAt=GetTime()+2
            local previous=self.currentChatAttempt
            local attempt={channel="ADDON_" .. channel,test=item.test,transport=true}
            self.currentChatAttempt=attempt
            local ok, result=pcall(sender,PREFIX,item.payload,channel,target)
            self.currentChatAttempt=previous
            local success=ok and self:IsReadable(result) and (result==nil or result==true or result==0)
            local retry=ok and self:IsReadable(result) and (result==3 or result==8 or result==11)
            self:RecordChatDiagnostic("CONTROL_SENT",{control=item.kind,test=item.test,transport=channel,
                result=ok and self:IsReadable(result) and tostring(result) or "unavailable",blocked=attempt.blocked==true,queued=#queue})
            if success and not attempt.blocked then
                table.remove(queue,1)
                if item.kind=="ACK" then removeReceipt(item.test) end
            elseif not retry or attempt.blocked then
                self:RecordChatDiagnostic("CONTROL_FAILED",{test=item.test,transport=channel,blocked=attempt.blocked==true})
                if attempt.blocked then self.diagnosticControlBlocked=true end
                if self.diagnosticPair and (item.kind=="HELLO" or item.kind=="EXPECT") then
                    self.diagnosticPair.failure=attempt.blocked and "protected control action" or "transport failed"
                end
                table.remove(queue,1)
                if item.kind=="ACK" then removeReceipt(item.test) end
            end
        end
    end
    refresh()
    if not active and #queue==0 and #db.receipts==0 and not self.diagnosticSuite and self.diagnosticPeerTicker then
        self.diagnosticPeerTicker:Cancel(); self.diagnosticPeerTicker=nil
    end
end
function QA:WakeDiagnosticPeer()
    if self.diagnosticPeerTicker or not C_Timer or type(C_Timer.NewTicker)~="function" then return end
    self.diagnosticPeerTicker=C_Timer.NewTicker(.5,function() self:PumpDiagnosticPeer() end)
end
function QA:ResetDiagnosticPeer()
    queue={}; self.diagnosticPair=nil; self.diagnosticInbound=nil
    local db=QuestAnnounceDiagnosticsDB
    db.expectations={}; db.receipts={}
    for _, r in ipairs(db.results) do
        if r.status=="pending" or r.status=="waiting" then r.status="unconfirmed"; r.token=nil end
    end
    if self.diagnosticPeerTicker then self.diagnosticPeerTicker:Cancel(); self.diagnosticPeerTicker=nil end
    self:SetDiagnosticPhase("idle")
    refresh()
end
function QA:SetDiagnosticReceiver(enabled)
    self:InitializeDiagnostics()
    if enabled and (not registered or not (C_ChatInfo and type(C_ChatInfo.SendAddonMessage)=="function" or type(SendAddonMessage)=="function")) then
        self:NotifySelf(L["Diagnostic partner unavailable"],false); return false
    end
    if not self:NormalizeDiagnosticPlayer(QuestAnnounceDiagnosticsDB.settings.partner) and enabled then
        self:NotifySelf(L["Diagnostic partner required"],false); return false
    end
    QuestAnnounceDiagnosticsDB.settings.receive=enabled==true
    if enabled then self:SetChatDiagnosticsEnabled(true); self:WakeDiagnosticPeer()
    else
        -- DE: Empfang abstellen, ohne eigene ausstehende Versandbestätigungen zu verlieren.
        -- EN: Stop receiving without discarding acknowledgements for our own pending sends.
        self.diagnosticInbound=nil
        QuestAnnounceDiagnosticsDB.expectations={}; QuestAnnounceDiagnosticsDB.receipts={}
        for index=#queue,1,-1 do
            if queue[index].kind=="WELCOME" or queue[index].kind=="ARMED" or queue[index].kind=="ACK" then table.remove(queue,index) end
        end
    end
    refresh()
    return true
end
function QA:PrepareDiagnosticPartner(run)
    if self.diagnosticControlBlocked or not registered or not (C_ChatInfo and type(C_ChatInfo.SendAddonMessage)=="function" or type(SendAddonMessage)=="function") then
        self:RecordDiagnosticControlState()
        self:NotifySelf(string.format(L["Diagnostic setup failed"],self:GetDiagnosticReason(
            self.diagnosticControlBlocked and "protected control action" or "transport failed")),false); return false
    end
    local partner=QuestAnnounceDiagnosticsDB.settings.partner
    if not self:NormalizeDiagnosticPlayer(partner) or self:IsOwnDiagnosticSender(partner) then
        self:NotifySelf(L["Diagnostic partner required"],false); return false
    end
    local now=GetTime()
    self.diagnosticPair={session=receiverSession,run=run,hardDeadline=now+180,
        lastAt=now,used=0,waited=0,nextRetry=now+12,retries=0}
    return enqueue("HELLO",{receiverSession},nil,time()+180)
end
-- DE: Nur nutzbare Aufbauzeit zählen, zusätzlich harte Grenze; fehlende Antworten begrenzt erneut anfragen.
-- EN: Count usable setup time with an additional hard limit; request missing replies with bounded retries.
function QA:AdvanceDiagnosticPartnerSetup(run,now)
    local pair=self.diagnosticPair
    if not pair or pair.run~=run then return end
    local locked=communicationRestricted()
    local delta=math.max(0,now-pair.lastAt); pair.lastAt=now
    if locked or pair.lastLocked then pair.waited=pair.waited+delta else pair.used=pair.used+delta end
    pair.lastLocked=locked
    local reason=pair.failure or (self.diagnosticControlBlocked and "protected control action")
    if not reason and (pair.used>=60 or now>=pair.hardDeadline) then
        reason=pair.waited>0 and "chat restriction setup timeout"
            or (pair.token and "channel preparation timeout" or "partner response timeout")
    end
    if reason then
        self:RecordChatDiagnostic((pair.failure or self.diagnosticControlBlocked) and "PEER_SETUP_FAILED" or "PEER_SETUP_TIMEOUT",
            {reason=reason,used=pair.used,waited=pair.waited})
        self:CancelChatDiagnosticSuite(reason)
        self:NotifySelf(string.format(L["Diagnostic setup failed"],self:GetDiagnosticReason(reason)),false)
        return
    end
    self:SetDiagnosticPhase(locked and "restricted" or (pair.token and "preparing" or "searching"))
    if not locked and now>=pair.nextRetry and pair.retries<3 then
        pair.retries=pair.retries+1; pair.nextRetry=now+12
        local expires=time()+math.max(1,math.floor(pair.hardDeadline-now))
        if not pair.token then enqueue("HELLO",{pair.session},nil,expires)
        else
            for _,test in ipairs(run.tests) do
                if not test.prepared then
                    enqueue("EXPECT",{pair.session,test.id,test.channel,pair.token,
                        test.channel=="CHANNEL" and (QuestAnnounceDiagnosticsDB.settings.channel or "-") or "-"},test.id,expires)
                end
            end
        end
        self:RecordChatDiagnostic("CONTROL_RETRY",{phase=pair.token and "preparing" or "searching",retry=pair.retries})
    end
end
-- DE: Protokoll ist versionsgebunden, adressiert und auf den ausdrücklich gewählten Partner begrenzt.
-- EN: The versioned protocol is addressed and limited to the explicitly selected peer.
function QA:OnDiagnosticControl(prefix, payload, distribution, sender)
    local db=QuestAnnounceDiagnosticsDB
    if not db or not db.enabled or not registered or not safeString(prefix,16) or prefix~=PREFIX
        or not self:IsReadable(distribution) or not peerMatches(sender) or self:IsOwnDiagnosticSender(sender) then return end
    if not self:IsReadable(payload) or type(payload)~="string" or #payload>255 or payload:find("[%z\r\n]")
        or payload:find("||",1,true) or payload:sub(1,1)=="|" or payload:sub(-1)=="|" then
        self:RecordChatDiagnostic("CONTROL_REJECTED",{reason="invalid control packet"}); return
    end
    if distribution~="WHISPER" and distribution~="PARTY" and distribution~="RAID" and distribution~="INSTANCE_CHAT" then return end
    local parts={}
    for part in payload:gmatch("[^|]+") do parts[#parts+1]=part end
    if parts[3]~=self:NormalizeDiagnosticPlayer(self:ReadChatAPI(GetUnitName,"player",true)) then return end
    if parts[1]~="1" then
        self:RecordChatDiagnostic("CONTROL_REJECTED",{reason="protocol mismatch"})
        if self.diagnosticPair then self.diagnosticPair.failure="protocol mismatch" end
        return
    end
    local kind, remote=parts[2],parts[4]
    if not validID(remote) then return end
    self:RecordChatDiagnostic("CONTROL_RECEIVED",{control=kind,transport=distribution})
    if self.diagnosticControlBlocked then return end
    if kind=="HELLO" and #parts==4 and db.settings.receive then
        self.diagnosticInbound={remote=remote,expires=time()+180}
        local _, build=GetBuildInfo()
        local trial=self:ReadChatAPI(IsTrialAccount)
        local veteran=self:ReadChatAPI(IsVeteranTrialAccount)
        local meta=(C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata)
        local version=self:ReadChatAPI(meta,"QuestAnnounce","Version") or "unknown"
        enqueue("WELCOME",{remote,receiverSession,version,tostring(build),GetLocale(),tostring(trial),tostring(veteran)})
        -- DE: Zusatzpaket hält das bestehende Protokoll kompatibel; alte Partner ignorieren BUILD.
        -- EN: A separate packet preserves protocol compatibility; old peers ignore BUILD.
        enqueue("BUILD",{remote,receiverSession,QA.DIAGNOSTIC_REVISION})
    elseif kind=="HELLO" and #parts==4 then
        self:RecordChatDiagnostic("CONTROL_REJECTED",{reason="receiver disabled"})
        enqueue("DECLINE",{remote,"receiver disabled"})
    elseif kind=="DECLINE" and #parts==5 then
        if self.diagnosticPair and self.diagnosticPair.session==remote and parts[5]=="receiver disabled" then
            self.diagnosticPair.failure="receiver disabled"
        end
    elseif kind=="BUILD" and #parts==6 and validID(parts[5]) and safeString(parts[6],40) then
        local pair=self.diagnosticPair
        if pair and pair.session==remote and pair.token==parts[5] then
            pair.peerRevision=parts[6]
            self:RecordChatDiagnostic("PEER_BUILD",{diagnosticBuild=parts[6],matches=parts[6]==QA.DIAGNOSTIC_REVISION})
        elseif self.diagnosticInbound and remote==receiverSession and self.diagnosticInbound.remote==parts[5] then
            self:RecordChatDiagnostic("PEER_BUILD",{diagnosticBuild=parts[6],matches=parts[6]==QA.DIAGNOSTIC_REVISION})
        end
    elseif kind=="WELCOME" and #parts==10 then
        local pair=self.diagnosticPair
        if not pair or pair.session~=remote or self.diagnosticSuite~=pair.run or not validID(parts[5]) then return end
        if pair.token then return end
        pair.token=parts[5]
        pair.retries=0; pair.nextRetry=GetTime()+12
        self:SetDiagnosticPhase("preparing")
        self:RecordChatDiagnostic("PEER_CONNECTED",{protocol=1,peerVersion=parts[6],peerBuild=parts[7],peerLocale=parts[8],
            peerTrial=parts[9],peerVeteranTrial=parts[10]})
        enqueue("BUILD",{pair.token,pair.session,QA.DIAGNOSTIC_REVISION})
        for _, test in ipairs(pair.run.tests) do
            test.token=pair.token
            local r=findResult(test.id); r.token=pair.token
            if parts[9]=="true" and (test.channel=="GUILD" or test.channel=="OFFICER") then
                r.eligibility="starter guild recipient"
                self:RecordChatDiagnostic("PEER_ELIGIBILITY",{test=test.id,channel=test.channel,reason=r.eligibility})
            end
            enqueue("EXPECT",{remote,test.id,test.channel,pair.token,
                test.channel=="CHANNEL" and (db.settings.channel or "-") or "-"},test.id,time()+math.max(1,math.floor(pair.hardDeadline-GetTime())))
        end
    elseif kind=="EXPECT" and #parts==8 and db.settings.receive and parts[7]==receiverSession
        and self.diagnosticInbound and self.diagnosticInbound.remote==remote and self.diagnosticInbound.expires>time()
        and validID(parts[5]) and parts[5]:sub(1,#remote+1)==remote .. "-" and eventChannels["CHAT_MSG_" .. parts[6]] then
        local old=findExpected(parts[5])
        if not old then
            if #db.expectations>=LIMIT then return end
            old={test=parts[5],channel=parts[6],remote=remote,token=parts[7],custom=parts[8],expires=time()+TTL}
            db.expectations[#db.expectations+1]=old
        end
        if old.remote==remote and old.channel==parts[6] and old.token==parts[7] then enqueue("ARMED",{remote,old.test,old.channel,old.token},old.test) end
    elseif kind=="ARMED" and #parts==7 then
        local pair=self.diagnosticPair
        if not pair or pair.session~=remote or pair.token~=parts[7] or self.diagnosticSuite~=pair.run then return end
        -- DE: Verspätete/doppelte Bereitschaft darf einen laufenden Test nicht zurückstufen.
        -- EN: Late/duplicate readiness must not downgrade a running test's phase.
        if pair.run.prepared then return end
        for _, test in ipairs(pair.run.tests) do
            if test.id==parts[5] and test.channel==parts[6] then test.prepared=true end
        end
        self:SetDiagnosticPhase("preparing")
        local ready=true
        for _, test in ipairs(pair.run.tests) do if not test.prepared then ready=false end end
        if ready and not pair.run.prepared then
            pair.run.prepared=true; pair.run.nextAt=GetTime()+5; pair.run.deadline=GetTime()+300
            self:SetDiagnosticPhase("ready")
            self:RecordChatDiagnostic("PEER_READY",{}); self:NotifySelf(L["Diagnostic partner ready"],false)
        end
    elseif kind=="ACK" and #parts==8 then
        local r=findResult(parts[5])
        local receivedAt=tonumber(parts[8])
        if not r or not r.attempted or r.channel~=parts[6] or r.token~=parts[7] or r.test:sub(1,#remote+1)~=remote .. "-"
            or r.expires<=time() or r.received or not receivedAt or receivedAt<=0 or receivedAt>1e12 then return end
        r.received=true
        self:RecordChatDiagnostic("REMOTE_RECEIPT",{test=r.test,channel=r.channel,peerSession=parts[7],receivedAt=receivedAt})
    else self:RecordChatDiagnostic("CONTROL_REJECTED",{control=kind,reason="unexpected control state"}) end
end
function QA:ObserveDiagnosticReceipt(event, id, sender, guid, channelName)
    local db=QuestAnnounceDiagnosticsDB
    local channel=eventChannels[event]
    if not db.settings.receive or not channel or not peerMatches(sender) or self:IsOwnDiagnosticSender(sender,guid) then return end
    local expected=findExpected(id)
    if not expected or expected.received or expected.expires<=time() or expected.channel~=channel then return end
    if channel=="CHANNEL" then
        if not safeString(channelName) or not safeString(expected.custom) or channelName:lower()~=expected.custom:lower() then return end
    end
    expected.received=true
    self:RecordChatDiagnostic("PEER_CHAT_RECEIVED",{test=id,channel=channel,sourceSession=expected.remote})
    if #db.receipts<LIMIT then
        db.receipts[#db.receipts+1]={test=id,channel=channel,remote=expected.remote,token=expected.token,receivedAt=time(),expires=time()+TTL}
        self:WakeDiagnosticPeer()
    end
end
function QA:GetDiagnosticResultText()
    local db=QuestAnnounceDiagnosticsDB
    if not db then return "" end
    local lines={L[db.settings.receive and "Diagnostic receiver on" or "Diagnostic receiver off"],
        string.format(L["Diagnostic build label"],QA.DIAGNOSTIC_REVISION)}
    local progress=self.diagnosticProgress
    if progress then
        lines[#lines+1]=(progress.phase=="ready" and not self.diagnosticPair)
            and L["Diagnostic status waiting"] or L["Diagnostic phase " .. progress.phase]
        if progress.total>0 then lines[#lines+1]=string.format(L["Diagnostic preparation progress"],progress.prepared,progress.total) end
        if progress.reason then lines[#lines+1]=self:GetDiagnosticReason(progress.reason) end
    end
    if self.diagnosticPair and self.diagnosticPair.peerRevision and self.diagnosticPair.peerRevision~=QA.DIAGNOSTIC_REVISION then
        lines[#lines+1]=L["Diagnostic build mismatch"]
    end
    for index=math.max(1,#db.results-21),#db.results do
        local r=db.results[index]
        lines[#lines+1]=r.channel .. " · " .. L["Diagnostic status " .. r.status] .. " · " .. r.test
        if r.eligibility then lines[#lines+1]=L["Diagnostic starter guild recipient"] end
        if r.echo and r.status~="received" then lines[#lines+1]=L["Diagnostic echo only"] end
        if r.reason then lines[#lines+1]=self:GetDiagnosticReason(r.reason) end
    end
    return table.concat(lines,"\n")
end
