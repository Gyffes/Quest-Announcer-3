$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$corePath = Join-Path $repoRoot 'QuestAnnounce.lua'
$core = Get-Content -LiteralPath $corePath -Raw
$config = Get-Content -LiteralPath (Join-Path $repoRoot 'Config.lua') -Raw
$allAddonCode = $core + "`n" + $config

function Assert-Match {
    param([string]$Text, [string]$Pattern, [string]$FailureMessage)
    if ($Text -notmatch ('(?s)' + $Pattern)) {
        throw $FailureMessage
    }
}

function Assert-NotMatch {
    param([string]$Text, [string]$Pattern, [string]$FailureMessage)
    if ($Text -match ('(?s)' + $Pattern)) {
        throw $FailureMessage
    }
}

Assert-Match $core 'QuestAnnounce:RegisterEvent\("QUEST_PROGRESS"\)' 'QUEST_PROGRESS is not registered.'
Assert-Match $core 'QuestAnnounce:RegisterEvent\("QUEST_COMPLETE"\)' 'QUEST_COMPLETE is not registered.'
Assert-Match $core 'if event == "QUEST_PROGRESS" or event == "QUEST_COMPLETE" then\s+self:RecordManualTurnInIntent\(event, self:GetCurrentQuestDialogQuestID\(\)\)' 'Event-only manual turn-in intent capture is missing.'
Assert-Match $core 'function QuestAnnounce:HandleQuestTurnedIn\(questID\)' 'Deferred turn-in handler is missing.'
Assert-Match $core 'function QuestAnnounce:DeferQuestTurnedIn\(questID\).*?C_Timer\.After\(0, function\(\).*?QuestAnnounce:HandleQuestTurnedIn\(questID\)' 'QUEST_TURNED_IN is not deferred to the next timer cycle.'
Assert-Match $core 'if event == "QUEST_TURNED_IN" then\s+local questID = tonumber\(arg1\)\s+self:DeferQuestTurnedIn\(questID\)' 'The event handler still performs synchronous turn-in work.'
Assert-Match $core 'Compatibility fallback for clients without C_Timer\.After\.\s+self:HandleQuestTurnedIn\(questID\)' 'The legacy timer fallback is missing.'

Assert-NotMatch $core 'function QuestAnnounce:EnsureManualTurnInHooks' 'Legacy manual turn-in hook installer still exists.'
Assert-NotMatch $core 'manualTurnInHooksInstalled' 'Legacy hook state still exists.'
Assert-NotMatch $core 'function QuestAnnounce:IsManualQuestTurnInContext' 'Unused Blizzard quest-frame context probing still exists.'
Assert-NotMatch $core 'hooksecurefunc\("QuestFrameCompleteQuest"' 'QuestFrameCompleteQuest is still post-hooked.'
Assert-NotMatch $core 'hooksecurefunc\("QuestRewardCompleteButton_OnClick"' 'QuestRewardCompleteButton_OnClick is still post-hooked.'
Assert-NotMatch $core 'QuestFrameCompleteQuestButton.*HookScript' 'A Blizzard quest completion button is still hooked.'
Assert-NotMatch $core 'QuestRewardCompleteButton.*HookScript' 'The Blizzard quest reward button is still hooked.'
Assert-NotMatch $allAddonCode 'EventRegistry:RegisterCallback\("SetItemRef"' 'Quest links still mutate Blizzard''s shared EventRegistry.'
Assert-Match $core 'hooksecurefunc\("SetItemRef".*?QuestAnnounce:HandleQuestLinkClick' 'The isolated SetItemRef post-hook is missing.'
Assert-NotMatch $allAddonCode 'StaticPopupDialogs\s*\[' 'QuestAnnounce still writes definitions into Blizzard''s shared popup table.'
Assert-NotMatch $allAddonCode 'StaticPopup_Show\s*\(' 'QuestAnnounce still invokes Blizzard''s shared popup dispatcher.'
Assert-Match $core 'CreateFrame\("Frame", nil, UIParent, "BasicFrameTemplateWithInset"\)' 'The anonymous addon-owned dialog frame is missing.'
Assert-Match $config 'SLASH_QUESTANNOUNCE1 = "/qa"\s+SlashCmdList\["QUESTANNOUNCE"\] = openConfig' 'The /qa settings command is not registered.'
Assert-Match $core 'function QuestAnnounce:Initialize\(\)\s+QuestAnnounceDB = QuestAnnounceDB or \{\}.*?QuestAnnounceDB\.profile = self:ApplyProfileDefaults\(QuestAnnounceDB\.profile\).*?self\.db = QuestAnnounceDB\s+self:BuildQuestCache\(\).*?self:SetupOptions\(\).*?self:InitializeMinimapButton\(\).*?self:InitializeLinkHandler\(\)' 'Full initialization does not preserve profile migration, cache, settings/minimap UI, and link integration.'
Assert-Match $core 'QuestAnnounce:RegisterEvent\("ADDON_LOADED"\).*?QuestAnnounce:RegisterEvent\("QUEST_LOG_UPDATE"\).*?QuestAnnounce:RegisterEvent\("QUEST_ACCEPTED"\).*?QuestAnnounce:RegisterEvent\("QUEST_TURNED_IN"\).*?QuestAnnounce:RegisterEvent\("QUEST_PROGRESS"\).*?QuestAnnounce:RegisterEvent\("QUEST_COMPLETE"\).*?QuestAnnounce:RegisterEvent\("UI_INFO_MESSAGE"\).*?QuestAnnounce:RegisterEvent\("PLAYER_REGEN_ENABLED"\)' 'The normal path does not register quest, UI_INFO_MESSAGE, and combat-replay events.'
Assert-NotMatch $allAddonCode 'FOR_TAINT_TEST|diagnosticMode|linkHandlerMode|cinematic taint A/B test' 'Temporary taint diagnostics remain in production code.'
Assert-Match $core 'function QuestAnnounce:SendDebugMsg\(msg\)\s+if msg ~= nil' 'User-controlled debug output is missing.'
Assert-Match $core 'function QuestAnnounce:NotifySelf\(msg, showUIError\).*?self:Print\(msg\)' 'Local quest messages no longer reach the addon-owned DEFAULT_CHAT_FRAME output helper.'
Assert-Match $core 'if showUIError then\s+self:AddUIErrorMessageSafe\(msg\)' 'NotifySelf does not reach UIErrorsFrame.'
Assert-Match $core 'function QuestAnnounce:InitializeAddonRaidNoticeFrame\(\).*?CreateFrame\("ScrollingMessageFrame", nil, UIParent\).*?self\.addonRaidNoticeFrame = frame.*?return frame\s+end' 'The addon-owned raid notice frame is missing or is not anonymous.'
Assert-Match $core 'function QuestAnnounce:AddRaidNoticeMessageSafe\(msg\).*?self:InitializeAddonRaidNoticeFrame\(\).*?pcall\(frame\.AddMessage, frame, msg' 'Raid notice messages are not routed through the addon-owned frame.'
Assert-NotMatch $core 'RaidNotice_AddMessage\s*\(' 'The shared Blizzard RaidNotice_AddMessage function is still called.'
Assert-NotMatch $core 'pcall\s*\(\s*RaidNotice_AddMessage' 'The shared Blizzard RaidNotice_AddMessage function is still called through pcall.'
Assert-NotMatch $core 'RaidWarningFrame\s*,' 'The shared Blizzard RaidWarningFrame is still passed to a function.'
Assert-Match $core 'function QuestAnnounce:DispatchMsg\(msg, isComplete, soundOverrideEvent\).*?self:DispatchChatOutputs\(msg, true\).*?if allowSelfOutput and announceTo\.raidWarningFrame then\s+self:AddRaidNoticeMessageSafe\(msg\).*?if allowSelfOutput and announceTo\.uiErrorsFrame then\s+self:AddUIErrorMessageSafe\(msg.*?self:PlayConfiguredSound\("complete"\).*?self:PlayConfiguredSound\("progress"\)' 'The UIErrorsFrame-output boundary does not preserve private raid notices, UIErrorsFrame messages, and sounds.'

Write-Output 'Full-functionality taint verification passed: gameplay, settings/minimap UI, SetItemRef post-hook, /qa, UIErrorsFrame, debug, and addon-owned raid notices are active; Blizzard RaidWarningFrame remains unused.'
