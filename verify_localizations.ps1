$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$localizationPath = Join-Path $repoRoot 'Localization.lua'
$expectedLocales = @('enUS', 'deDE', 'esES', 'esMX', 'frFR', 'koKR', 'ptBR', 'ruRU', 'zhCN', 'zhTW')
$valuesByLocale = @{}
$countsByLocale = @{}
$currentLocale = $null

foreach ($line in Get-Content -LiteralPath $localizationPath) {
    if ($line -match '^QuestAnnounce_L\.([A-Za-z]{4})\s*=\s*\{') {
        $currentLocale = $Matches[1]
        $valuesByLocale[$currentLocale] = @{}
        $countsByLocale[$currentLocale] = @{}
        continue
    }

    if ($currentLocale -and $line -match '^\s*\["(.*)"\]\s*=\s*"(.*)"\s*,?\s*\}?\s*$') {
        $key = $Matches[1]
        $value = $Matches[2]
        $countsByLocale[$currentLocale][$key] = 1 + ($countsByLocale[$currentLocale][$key] -as [int])
        $valuesByLocale[$currentLocale][$key] = $value
    }
}

foreach ($locale in $expectedLocales) {
    if (-not $valuesByLocale.ContainsKey($locale)) {
        throw "Missing localization table: $locale"
    }
}
if ($valuesByLocale.Count -ne $expectedLocales.Count) {
    throw "Expected $($expectedLocales.Count) locale tables, found $($valuesByLocale.Count)."
}

foreach ($locale in $expectedLocales) {
    $duplicates = @($countsByLocale[$locale].GetEnumerator() | Where-Object Value -gt 1)
    if ($duplicates.Count -gt 0) {
        throw "Duplicate localization keys in ${locale}: $($duplicates.Name -join ', ')"
    }
}

$base = $valuesByLocale['enUS']
foreach ($locale in $expectedLocales | Where-Object { $_ -ne 'enUS' }) {
    $missing = @($base.Keys | Where-Object { -not $valuesByLocale[$locale].ContainsKey($_) } | Sort-Object)
    $extra = @($valuesByLocale[$locale].Keys | Where-Object { -not $base.ContainsKey($_) } | Sort-Object)
    if ($missing.Count -gt 0) {
        throw "Missing keys in ${locale}: $($missing -join ', ')"
    }
    if ($extra.Count -gt 0) {
        throw "Unexpected keys in ${locale}: $($extra -join ', ')"
    }
}

function Get-FormatTokens {
    param([string]$Text)
    return @([regex]::Matches($Text, '(?<!%)%(?:\d+\$)?[-+0 #]*\d*(?:\.\d+)?[cdeEfgGiouqsxX]') | ForEach-Object Value | Sort-Object)
}

foreach ($locale in $expectedLocales | Where-Object { $_ -ne 'enUS' }) {
    foreach ($key in $base.Keys) {
        $baseTokens = (Get-FormatTokens $base[$key]) -join '|'
        $localeTokens = (Get-FormatTokens $valuesByLocale[$locale][$key]) -join '|'
        if ($baseTokens -ne $localeTokens) {
            throw "Format placeholders differ for '$key' in ${locale}: '$baseTokens' vs '$localeTokens'."
        }
    }
}

$usedKeys = [System.Collections.Generic.HashSet[string]]::new()
foreach ($fileName in @('QuestAnnounce.lua', 'Config.lua', 'Minimap.lua')) {
    $source = Get-Content -LiteralPath (Join-Path $repoRoot $fileName) -Raw
    foreach ($match in [regex]::Matches($source, '(?<![A-Za-z0-9_])L\["([^"\r\n]+)"\]')) {
        [void]$usedKeys.Add($match.Groups[1].Value)
    }
}

$undefined = @($usedKeys | Where-Object { -not $base.ContainsKey($_) } | Sort-Object)
if ($undefined.Count -gt 0) {
    throw "Localization keys used by addon code but missing from enUS: $($undefined -join ', ')"
}

$localizationSource = Get-Content -LiteralPath $localizationPath -Raw
if ($localizationSource -notmatch 'setmetatable\(localeTable, \{ __index = fallback \}\)') {
    throw 'The enUS runtime fallback is missing.'
}

Write-Output "Localization verification passed: $($expectedLocales.Count) locales, $($base.Count) keys each, matching placeholders, and $($usedKeys.Count) referenced keys."
