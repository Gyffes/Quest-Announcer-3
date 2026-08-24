$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$core = Get-Content -LiteralPath (Join-Path $repoRoot 'QuestAnnounce.lua') -Raw
$config = Get-Content -LiteralPath (Join-Path $repoRoot 'Config.lua') -Raw

function Assert-Match {
    param([string]$Text, [string]$Pattern, [string]$FailureMessage)
    if ($Text -notmatch ('(?s)' + $Pattern)) {
        throw $FailureMessage
    }
}

# Turn-in behavior contract.
Assert-Match $core 'function QuestAnnounce:IsRecentManualTurnInIntent\(questID\).*?age < 0 or age > 45' 'The 45-second manual intent window changed or is missing.'
Assert-Match $core 'intent\.questID ~= turnedInQuestID' 'The quest-ID match guard is missing.'
Assert-Match $core 'settings\.playTurnInOnAutoTurnIn' 'The auto-turn-in option is no longer honored.'
Assert-Match $core 'turnInSoundHistory\[questID\].*?< 10' 'The 10-second duplicate turn-in sound guard is missing.'
Assert-Match $core 'self:PlayConfiguredSound\("turnin"\)' 'Turn-in sound playback is missing.'
Assert-Match $core 'if hasManualIntent then.*?self\.lastManualTurnInIntent = nil' 'Matching manual intent is not consumed after use.'
Assert-Match $core 'function QuestAnnounce:ClearQuestCompletionState\(questID\).*?self\.questCompletionAnnounced\[questID\] = nil.*?self\.questCompletionAnnouncedAt\[questID\] = nil.*?self\.pendingCompletionRecheck\[questID\] = nil' 'Completion state cleanup changed or is missing.'

# Completion checks always use quest IDs and verify unresolved 1/1 events.
Assert-Match $core 'function QuestAnnounce:IsQuestCompleteByObjectives\(questID\).*?QA_QuestLog\.IsComplete\(questID\)' 'Quest completion no longer uses the quest ID consistently.'
if ($core -match 'QA_QuestLog\.IsComplete\(logIndex or questID\)') {
    throw 'Quest-log index can still be passed to C_QuestLog.IsComplete.'
}
Assert-Match $core 'if not logIndex then.*?announceAsComplete, completionReason = self:IsQuestCompleteByObjectives\(questID\)' 'The no-log-index completion path does not verify whole-quest completion.'

# Quest-link behavior contract: one common handler, three preserved actions.
Assert-Match $core 'function QuestAnnounce:HandleQuestLinkClick\(link, text, button, chatFrame\)' 'The common quest-link handler is missing.'
Assert-Match $core 'if IsShiftKeyDown\(\) then.*?ChatEdit_InsertLink\(questLink\)' 'Shift-click no longer inserts the official quest link.'
Assert-Match $core 'if button == "RightButton" then.*?self:ShowCopyDialog\(url, L\["Wowhead Quest URL"\]\)' 'Right-click no longer opens the Wowhead copy dialog.'
Assert-Match $core 'if button == "LeftButton" then.*?self:OpenQuestInLog\(questID\)' 'Left-click no longer opens the quest log.'

# The secure post-hook and all click actions are active.
Assert-Match $core 'function QuestAnnounce:InitializeLinkHandler\(\).*?hooksecurefunc\("SetItemRef".*?QuestAnnounce:HandleQuestLinkClick' 'The active SetItemRef integration is missing.'

# Addon-owned dialogs preserve warnings, channel confirmation, and Escape/Cancel behavior.
Assert-Match $core 'function QuestAnnounce:ShowAddonDialog\(message, options\)' 'The addon-owned dialog helper is missing.'
Assert-Match $core 'if key == "ESCAPE" then\s+dialog:Hide\(\)' 'Escape no longer closes addon dialogs.'
Assert-Match $core 'if options\.showCancel then.*?frame\.cancelButton:Show\(\)' 'Yes/No dialog mode is missing.'
Assert-Match $core 'function QuestAnnounce:ToggleChannelLeave\(enable, channelName\).*?acceptText = L\["Yes"\].*?cancelText = L\["No"\].*?QuestAnnounce:LeaveChannel\(name\)' 'Channel-leave confirmation behavior changed or is missing.'
Assert-Match $config 'ShowPublicChatRestrictionWarning.*?L\["Public chat restriction warning"\].*?QuestAnnounce:ShowAddonDialog' 'The public-chat warning is missing.'
Assert-Match $config 'QuestAnnounce:ShowAddonDialog\(L\["Please enter a channel name\."\]' 'The missing-channel-name warning is missing.'
Assert-Match $config 'SLASH_QUESTANNOUNCE1 = "/qa"\s+SlashCmdList\["QUESTANNOUNCE"\] = openConfig' 'The /qa settings command source is missing.'

# Full initialization and profile loading use one complete default migration.
Assert-Match $core 'function QuestAnnounce:ApplyProfileDefaults\(profile\).*?DeepMergeDefaults.*?defaults\.profile' 'Central profile default migration is missing.'
Assert-Match $core 'QuestAnnounceDB\.profile = self:ApplyProfileDefaults\(QuestAnnounceDB\.profile\).*?self\.db = QuestAnnounceDB.*?self:SetupOptions\(\).*?self:InitializeMinimapButton\(\).*?self:InitializeLinkHandler\(\)' 'Saved configuration, UI, minimap, or link initialization is missing.'
Assert-Match $config 'function EnsureProfileShape\(profile\).*?QuestAnnounce:ApplyProfileDefaults' 'Saved profiles do not use the central default migration.'
Assert-Match $config 'function LoadProfile\(profileName\).*?RefreshQuestTypePanel\(\).*?QuestAnnounce:UpdateMinimapButtonVisibility\(\)' 'Profile loading does not refresh quest filters and minimap visibility.'
if (($core + "`n" + $config) -match 'FOR_TAINT_TEST|diagnosticMode|linkHandlerMode|cinematic taint A/B test') {
    throw 'Temporary taint diagnostics remain in production code.'
}

$tocFiles = @(Get-ChildItem -LiteralPath $repoRoot -Filter '*.toc')
if ($tocFiles.Count -ne 10) {
    throw "Expected 10 TOC files, found $($tocFiles.Count)."
}
foreach ($tocFile in $tocFiles) {
    $toc = Get-Content -LiteralPath $tocFile.FullName -Raw
    Assert-Match $toc '(?m)^## Version: 9\.3\.0\.9$' "Unexpected version in $($tocFile.Name)."
}

Write-Output 'Functionality preservation passed: gameplay, saved settings, UI, links, /qa, and 10 TOCs are active.'
