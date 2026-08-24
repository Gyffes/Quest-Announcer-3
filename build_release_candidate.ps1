$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$releaseTag = 'V9.3.0.9-RC1-Multi'
$distRoot = Join-Path $repoRoot 'dist'
$stageRoot = Join-Path $distRoot 'QuestAnnounce'
$archivePath = Join-Path $distRoot "QuestAnnounce-3-$releaseTag.zip"
$checksumPath = "$archivePath.sha256"

$resolvedRepo = [System.IO.Path]::GetFullPath($repoRoot)
$resolvedDist = [System.IO.Path]::GetFullPath($distRoot)
$resolvedStage = [System.IO.Path]::GetFullPath($stageRoot)
if (-not $resolvedDist.StartsWith($resolvedRepo, [System.StringComparison]::OrdinalIgnoreCase) -or
    -not $resolvedStage.StartsWith($resolvedDist, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw 'Resolved release paths are outside the repository.'
}

if (Test-Path -LiteralPath $stageRoot) {
    Remove-Item -LiteralPath $stageRoot -Recurse -Force
}
if (Test-Path -LiteralPath $archivePath) {
    Remove-Item -LiteralPath $archivePath -Force
}
if (Test-Path -LiteralPath $checksumPath) {
    Remove-Item -LiteralPath $checksumPath -Force
}

New-Item -ItemType Directory -Path $stageRoot -Force | Out-Null

$packageFiles = @(
    'CHANGELOG.txt',
    'Config.lua',
    'Localization.lua',
    'Minimap.lua',
    'QuestAnnounce.lua',
    'README.md'
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

Write-Output "Release candidate package: $archivePath"
Write-Output "SHA256: $hash"
