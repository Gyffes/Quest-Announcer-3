$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

foreach ($scriptName in @(
    'verify_chat_lockdown.ps1',
    'verify_cinematic_taint_isolation.ps1',
    'verify_functionality_preservation.ps1',
    'verify_localizations.ps1'
)) {
    & (Join-Path $repoRoot $scriptName)
}

$productionFiles = @('QuestAnnounce.lua', 'Config.lua', 'Localization.lua', 'Minimap.lua')
$productionSource = ($productionFiles | ForEach-Object {
    Get-Content -LiteralPath (Join-Path $repoRoot $_) -Raw
}) -join "`n"

if ($productionSource -match 'FOR_TAINT_TEST|diagnosticMode|linkHandlerMode|cinematic taint A/B test|(?m)^\s*--\s*(?:TODO|FIXME|HACK|XXX)\b') {
    throw 'Temporary diagnostics or unfinished maintenance comments remain in production code.'
}
if ($productionSource -match '(?m)^\s*--\s*(?:local\s+)?function\s+QuestAnnounce[:.]') {
    throw 'Commented-out QuestAnnounce function code remains in production files.'
}

$config = Get-Content -LiteralPath (Join-Path $repoRoot 'Config.lua') -Raw
if ([regex]::Matches($config, 'local\s+function\s+ResolveTooltipFontPath\(').Count -ne 1 -or
    [regex]::Matches($config, 'local\s+function\s+ResolveTooltipFontLabel\(').Count -ne 1) {
    throw 'Tooltip font helpers are missing or duplicated.'
}

$readme = Get-Content -LiteralPath (Join-Path $repoRoot 'README.md') -Raw
$changelog = Get-Content -LiteralPath (Join-Path $repoRoot 'CHANGELOG.txt') -Raw
if ($readme -notmatch 'V9\.3\.0\.9-RC1-Multi') {
    throw 'README does not identify the RC tag.'
}
if ($changelog -notmatch '(?m)^v9\.3\.0\.9 Multi \(RC1\) - 24-08-2026$') {
    throw 'CHANGELOG does not identify the RC date and stage.'
}

Write-Output 'Release-candidate verification passed: production cleanup, functionality, localization, comments, metadata, and 10-client version consistency.'
