$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$matrix = Get-Content -LiteralPath (Join-Path $repoRoot 'tests/client_matrix.json') -Raw | ConvertFrom-Json
$expectedNames = @('QuestAnnounce.toc')
$coreFiles = @('Localization.lua', 'QuestAnnounce.lua', 'Config.lua', 'Minimap.lua')

foreach ($client in $matrix.clients) {
    $interfaces = if ($client.interfaces) { @($client.interfaces) } else { @($client.interface) }
    foreach ($name in @($client.toc) + @($client.aliases)) {
        $expectedNames += $name
        $source = Get-Content -LiteralPath (Join-Path $repoRoot $name) -Raw
        $actual = [regex]::Match($source, '(?m)^## Interface: (.+)\r?$').Groups[1].Value.Trim()
        if ($actual -ne ($interfaces -join ', ')) { throw "Wrong interface identifiers in $name" }
        if ($source -notmatch "(?m)^## X-Interface: $($client.interface)\r?$" -or
            $source -notmatch "(?m)^## Version: $([regex]::Escape($matrix.addonVersion))\r?$") {
            throw "Wrong current interface/addon version in $name"
        }
    }
}
$actualNames = @(Get-ChildItem -LiteralPath $repoRoot -Filter '*.toc' | ForEach-Object Name)
if (Compare-Object ($expectedNames | Sort-Object) ($actualNames | Sort-Object)) {
    throw 'TOC names differ from the explicit complete client matrix.'
}
foreach ($name in $expectedNames) {
    $lines = Get-Content -LiteralPath (Join-Path $repoRoot $name)
    $loaded = @($lines | Where-Object { $_.Trim() -and -not $_.StartsWith('#') })
    if (($loaded -join '|') -ne ($coreFiles -join '|')) { throw "Changed core load order in $name" }
    if ($lines -notcontains '## SavedVariables: QuestAnnounceDB') { throw "Changed SavedVariables in $name" }
    if ($lines -notcontains "## Version: $($matrix.addonVersion)") { throw "Changed version in $name" }
}
$base = Get-Content -LiteralPath (Join-Path $repoRoot 'QuestAnnounce.toc') -Raw
foreach ($client in $matrix.clients) {
    $interfaces = if ($client.interfaces) { @($client.interfaces) } else { @($client.interface) }
    $flavor = if ($client.id -eq 'Classic') { 'Vanilla' } else { $client.id }
    if ($base -notmatch "(?m)^## Interface-$($flavor): $([regex]::Escape($interfaces -join ', '))\r?$") {
        throw "Missing universal TOC flavor: $flavor"
    }
}
Write-Output "Client metadata verified: $($expectedNames.Count) TOCs, all existing aliases, canonical flavors, matching versions and core load order. In-game loading remains a separate test."
