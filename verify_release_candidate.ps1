param([string]$PythonPath = 'python')
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

foreach ($script in Get-ChildItem -LiteralPath $repoRoot -Filter '*.ps1') {
    $tokens = $null
    $parseErrors = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile($script.FullName, [ref]$tokens, [ref]$parseErrors)
    if ($parseErrors.Count -gt 0) { throw "PowerShell syntax errors in $($script.Name): $parseErrors" }
}

foreach ($scriptName in @(
    'verify_chat_lockdown.ps1',
    'verify_cinematic_taint_isolation.ps1',
    'verify_functionality_preservation.ps1',
    'verify_localizations.ps1'
)) {
    & (Join-Path $repoRoot $scriptName)
}

& (Join-Path $repoRoot 'verify_tooltip_fonts.ps1') -PythonPath $PythonPath

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

$core = Get-Content -LiteralPath (Join-Path $repoRoot 'QuestAnnounce.lua') -Raw
foreach ($helper in @('GetTooltipFontPath', 'GetTooltipFontSelection', 'GetTooltipFontChoices', 'ApplyTooltipLineFont')) {
    if ([regex]::Matches($core, "function QuestAnnounce:$helper\(").Count -ne 1) {
        throw "Shared tooltip font helper is missing or duplicated: $helper"
    }
}
foreach ($caller in @('Config.lua', 'Minimap.lua')) {
    $source = Get-Content -LiteralPath (Join-Path $repoRoot $caller) -Raw
    if ($source -match 'ResolveTooltipFontPath|ResolveTooltipFontLabel|Fonts\\\\|STANDARD_TEXT_FONT' -or
        $source -notmatch ':ApplyTooltipLineFont\(') {
        throw "Tooltip caller bypasses the shared font policy: $caller"
    }
}

$readme = Get-Content -LiteralPath (Join-Path $repoRoot 'README.md') -Raw
$changelog = Get-Content -LiteralPath (Join-Path $repoRoot 'CHANGELOG.txt') -Raw
$matrix = Get-Content -LiteralPath (Join-Path $repoRoot 'tests/client_matrix.json') -Raw | ConvertFrom-Json
if ($readme -notmatch [regex]::Escape($matrix.releaseTag)) {
    throw 'README does not identify the RC tag.'
}
if ($changelog -notmatch "(?m)^v$([regex]::Escape($matrix.addonVersion)) Multi \(RC1\) - 03-10-2026\r?$") {
    throw 'CHANGELOG does not identify the RC date and stage.'
}

Write-Output 'Release-candidate verification passed: source safety contracts, Lua runtime mocks, localization, shared font policy and full client metadata. Real-client acceptance remains separate.'
