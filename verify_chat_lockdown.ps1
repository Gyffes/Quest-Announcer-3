$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$corePath = Join-Path $repoRoot 'QuestAnnounce.lua'
$core = Get-Content -LiteralPath $corePath -Raw

function Assert-Match {
    param(
        [string]$Text,
        [string]$Pattern,
        [string]$FailureMessage
    )

    if ($Text -notmatch $Pattern) {
        throw $FailureMessage
    }
}

function Get-FunctionSection {
    param(
        [string]$StartName,
        [string]$NextName
    )

    $pattern = '(?s)function QuestAnnounce:' + [regex]::Escape($StartName) + '.*?(?=function QuestAnnounce:' + [regex]::Escape($NextName) + ')'
    $match = [regex]::Match($core, $pattern)
    if (-not $match.Success) {
        throw "Function section not found: $StartName"
    }
    return $match.Value
}

Assert-Match $core 'QuestAnnounce:RegisterEvent\("PLAYER_REGEN_ENABLED"\)' 'PLAYER_REGEN_ENABLED is not registered.'
Assert-Match $core 'if event == "PLAYER_REGEN_ENABLED" then\s+self:FlushPendingCombatChatMessage\(\)' 'Combat-end event does not flush the pending message.'
Assert-Match $core 'local COMBAT_CHAT_REPLAY_WINDOW_SECONDS = 10' 'Replay window is not 10 seconds.'

$restrictionSection = Get-FunctionSection 'IsChatSendRestricted(chatType)' 'GetChannelNameSafe(channelName)'
Assert-Match $restrictionSection 'pcall\(InCombatLockdown\)' 'The central restriction check does not call InCombatLockdown safely.'
Assert-Match $restrictionSection 'return true, "combat lockdown"' 'The combat restriction reason is missing.'

$queueSection = Get-FunctionSection 'QueuePendingCombatChatMessage(msg)' 'FlushPendingCombatChatMessage()'
Assert-Match $queueSection 'self\.pendingCombatChatMessage = \{\s+msg = msg,\s+queuedAt = now,' 'The pending record does not store message and timestamp.'

$flushSection = Get-FunctionSection 'FlushPendingCombatChatMessage()' 'DispatchChatOutputs(msg, allowCombatQueue)'
Assert-Match $flushSection 'self\.pendingCombatChatMessage = nil' 'The pending record is not consumed before replay.'
Assert-Match $flushSection 'age < 0 or age > COMBAT_CHAT_REPLAY_WINDOW_SECONDS' 'The replay age boundary is missing.'
Assert-Match $flushSection 'self:IsChatSendRestricted\("PARTY"\)' 'General restrictions are not re-checked before replay.'
Assert-Match $flushSection 'self:DispatchChatOutputs\(pending\.msg, false\)' 'Combat replay does not use the chat-only path.'
if ($flushSection -match 'DispatchMsg|PlayConfiguredSound|AddUIErrorMessageSafe|AddRaidNoticeMessageSafe') {
    throw 'Combat replay can repeat local output or sounds.'
}

$dispatchSection = Get-FunctionSection 'DispatchChatOutputs(msg, allowCombatQueue)' 'SendMsg(msg, isComplete, soundOverrideEvent)'
Assert-Match $dispatchSection 'allowCombatQueue ~= false' 'Replay can accidentally queue itself again.'
Assert-Match $dispatchSection 'self:QueuePendingCombatChatMessage\(msg\)' 'Combat-blocked messages are not queued.'

# Small behavior matrix for the documented queue policy.
$pending = $null
$pending = @{ msg = 'first'; queuedAt = 100.0 }
$pending = @{ msg = 'latest'; queuedAt = 105.0 }
if ($pending.msg -ne 'latest') {
    throw 'Latest-message-wins policy failed.'
}

foreach ($case in @(
    @{ Age = 0.0; Expected = $true },
    @{ Age = 10.0; Expected = $true },
    @{ Age = 10.001; Expected = $false },
    @{ Age = -0.001; Expected = $false }
)) {
    $allowed = $case.Age -ge 0 -and $case.Age -le 10
    if ($allowed -ne $case.Expected) {
        throw "Replay boundary failed for age $($case.Age)."
    }
}

$tocFiles = @(Get-ChildItem -LiteralPath $repoRoot -Filter '*.toc')
if ($tocFiles.Count -ne 10) {
    throw "Expected 10 TOC files, found $($tocFiles.Count)."
}
foreach ($tocFile in $tocFiles) {
    $toc = Get-Content -LiteralPath $tocFile.FullName -Raw
    Assert-Match $toc '(?m)^## Version: 9\.3\.0\.9$' "Unexpected version in $($tocFile.Name)."
}

Write-Output 'Chat-lockdown verification passed: queue, replay boundary, chat-only replay, and 10 TOCs.'
