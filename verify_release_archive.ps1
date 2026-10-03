param([string]$ArchivePath)
$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$matrix = Get-Content -LiteralPath (Join-Path $repoRoot 'tests/client_matrix.json') -Raw | ConvertFrom-Json
if (-not $ArchivePath) { $ArchivePath = Join-Path $repoRoot "dist/QuestAnnounce-3-$($matrix.releaseTag).zip" }
$expected = @('CHANGELOG.txt', 'Config.lua', 'Localization.lua', 'Minimap.lua', 'QuestAnnounce.lua',
    'README.md', 'CLIENT_VERSIONS.md', 'COMMUNITY_FIX_PLAN.md', 'RELEASE_NOTES_V9.3.0.10-RC1.md')
$expected += @(Get-ChildItem -LiteralPath $repoRoot -Filter '*.toc' | ForEach-Object Name)
$expected += @(Get-ChildItem -LiteralPath (Join-Path $repoRoot 'Media') -File -Recurse | ForEach-Object {
    $_.FullName.Substring($repoRoot.Length + 1).Replace('\', '/')
})
Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [System.IO.Compression.ZipFile]::OpenRead($ArchivePath)
try {
    $actual = @()
    foreach ($entry in $archive.Entries) {
        $name = $entry.FullName.Replace('\', '/')
        if (-not $name.StartsWith('QuestAnnounce/') -or $name -match '(^|/)\.\.(/|$)|:') {
            throw "Unsafe or wrong addon root in archive: $name"
        }
        if ($name.EndsWith('/')) { continue }
        $relative = $name.Substring('QuestAnnounce/'.Length)
        $actual += $relative
        if ($relative -notin $expected) { throw "Unexpected package entry: $relative" }
        $stream = $entry.Open()
        $sha = [System.Security.Cryptography.SHA256]::Create()
        try { $hash = [BitConverter]::ToString($sha.ComputeHash($stream)).Replace('-', '') }
        finally { $stream.Dispose(); $sha.Dispose() }
        $sourceHash = (Get-FileHash -LiteralPath (Join-Path $repoRoot $relative) -Algorithm SHA256).Hash
        if ($hash -ne $sourceHash) { throw "Archive differs from verified source: $relative" }
    }
    if (Compare-Object ($expected | Sort-Object) ($actual | Sort-Object)) { throw 'Incomplete archive contents.' }
} finally { $archive.Dispose() }
$checksum = Get-Content -LiteralPath "$ArchivePath.sha256" -Raw
$expectedChecksum = (Get-FileHash -LiteralPath $ArchivePath -Algorithm SHA256).Hash.ToLowerInvariant() + '  ' + (Split-Path -Leaf $ArchivePath)
if ($checksum.Trim() -cne $expectedChecksum) { throw 'Invalid release checksum file.' }
Write-Output "Release archive verified: $($expected.Count) files, correct QuestAnnounce root, byte-identical sources and matching SHA256; no tests or tools bundled."
