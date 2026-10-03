param([string]$PythonPath = 'python')
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$matrix = Get-Content -LiteralPath (Join-Path $repoRoot 'tests/client_matrix.json') -Raw | ConvertFrom-Json
$releaseTag = $matrix.releaseTag
& (Join-Path $repoRoot 'verify_release_candidate.ps1') -PythonPath $PythonPath
$distRoot = Join-Path $repoRoot 'dist'
$stageRoot = Join-Path (Join-Path $distRoot $releaseTag) 'QuestAnnounce'
$archivePath = Join-Path $distRoot "QuestAnnounce-3-$releaseTag.zip"
$checksumPath = "$archivePath.sha256"

$resolvedRepo = [System.IO.Path]::GetFullPath($repoRoot)
$resolvedDist = [System.IO.Path]::GetFullPath($distRoot)
$resolvedStage = [System.IO.Path]::GetFullPath($stageRoot)
if (-not $resolvedDist.StartsWith($resolvedRepo + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase) -or
    -not $resolvedStage.StartsWith($resolvedDist + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw 'Resolved release paths are outside the repository.'
}

foreach ($existingPath in @($stageRoot, $archivePath, $checksumPath)) {
    if (Test-Path -LiteralPath $existingPath) {
        throw "Release output already exists; it will not be overwritten: $existingPath"
    }
}

New-Item -ItemType Directory -Path $stageRoot -Force | Out-Null

$packageFiles = @(
    'CHANGELOG.txt',
    'Config.lua',
    'Localization.lua',
    'Minimap.lua',
    'QuestAnnounce.lua',
    'README.md',
    'CLIENT_VERSIONS.md',
    'COMMUNITY_FIX_PLAN.md',
    'RELEASE_NOTES_V9.3.0.10-RC1.md'
)
$packageFiles += @(Get-ChildItem -LiteralPath $repoRoot -Filter '*.toc' | Sort-Object Name | ForEach-Object Name)

foreach ($relativePath in $packageFiles) {
    $sourcePath = Join-Path $repoRoot $relativePath
    if (-not (Test-Path -LiteralPath $sourcePath)) {
        throw "Required package file is missing: $relativePath"
    }
    Copy-Item -LiteralPath $sourcePath -Destination (Join-Path $stageRoot $relativePath)
}

Copy-Item -LiteralPath (Join-Path $repoRoot 'Media') -Destination $stageRoot -Recurse
Compress-Archive -LiteralPath $stageRoot -DestinationPath $archivePath -CompressionLevel Optimal

$hash = (Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash.ToLowerInvariant()
"$hash  $(Split-Path -Leaf $archivePath)" | Set-Content -LiteralPath $checksumPath -Encoding ascii

& (Join-Path $repoRoot 'verify_release_archive.ps1') -ArchivePath $archivePath

Write-Output "Release candidate package: $archivePath"
Write-Output "SHA256: $hash"
