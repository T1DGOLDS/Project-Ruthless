param(
    [string]$Version,
    [string]$RepositoryRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = "Stop"
if (-not $Version) { $Version = (Get-Content -Raw -LiteralPath (Join-Path $RepositoryRoot 'package.json') | ConvertFrom-Json).version }
if ($Version -notmatch '^\d+\.\d+\.\d+(?:-[A-Za-z0-9.-]+)?$') { throw 'Invalid package version' }
$declaredVersion = (Get-Content -Raw -LiteralPath (Join-Path $RepositoryRoot 'package.json') | ConvertFrom-Json).version
if ($Version -ne $declaredVersion) { throw 'Package filename version differs from source version' }
foreach ($manifest in @('ProjectRuthless.toc','ProjectRuthless_Camelot.toc','ProjectRuthless_Options/ProjectRuthless_Options.toc','ProjectRuthless_DungeonData/ProjectRuthless_DungeonData.toc')) {
    if ((Get-Content -Raw -LiteralPath (Join-Path $RepositoryRoot $manifest)) -notmatch ('(?m)^## Version: ' + [regex]::Escape($Version) + '\r?$')) { throw "Manifest version differs: $manifest" }
}
$releaseRoot = Join-Path $RepositoryRoot "release"
$stagingRoot = Join-Path $releaseRoot ('.staging-' + [guid]::NewGuid().ToString('N'))
$packageRoot = Join-Path $stagingRoot "ProjectRuthless"
$zipPath = Join-Path $releaseRoot ("ProjectRuthless-{0}.zip" -f $Version)

$resolvedRepository = [System.IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char]92)
$resolvedRelease = [System.IO.Path]::GetFullPath($releaseRoot)
if ($resolvedRelease -ne (Join-Path $resolvedRepository "release")) { throw "Unsafe release directory" }
if (Test-Path -LiteralPath $zipPath) { throw "Refusing to overwrite preserved release: $zipPath" }
New-Item -ItemType Directory -Path $packageRoot -Force | Out-Null

Copy-Item -LiteralPath (Join-Path $RepositoryRoot "Core.lua") -Destination $packageRoot
Copy-Item -LiteralPath (Join-Path $RepositoryRoot "ProjectRuthless.toc") -Destination $packageRoot
Copy-Item -LiteralPath (Join-Path $RepositoryRoot "ProjectRuthless_Camelot.toc") -Destination $packageRoot
Copy-Item -LiteralPath (Join-Path $RepositoryRoot "README.md") -Destination $packageRoot
Copy-Item -LiteralPath (Join-Path $RepositoryRoot "CHANGELOG.md") -Destination $packageRoot
Copy-Item -LiteralPath (Join-Path $RepositoryRoot "LICENSE") -Destination $packageRoot
Copy-Item -LiteralPath (Join-Path $RepositoryRoot "Modules") -Destination $packageRoot -Recurse

Copy-Item -LiteralPath (Join-Path $RepositoryRoot "Assets") -Destination $packageRoot -Recurse

Copy-Item -LiteralPath (Join-Path $RepositoryRoot "docs") -Destination $packageRoot -Recurse

$optionsRoot = Join-Path $stagingRoot "ProjectRuthless_Options"
Copy-Item -LiteralPath (Join-Path $RepositoryRoot "ProjectRuthless_Options") -Destination $optionsRoot -Recurse
$dungeonRoot = Join-Path $stagingRoot "ProjectRuthless_DungeonData"
Copy-Item -LiteralPath (Join-Path $RepositoryRoot "ProjectRuthless_DungeonData") -Destination $dungeonRoot -Recurse
Compress-Archive -LiteralPath @($packageRoot, $optionsRoot, $dungeonRoot) -DestinationPath $zipPath -CompressionLevel Optimal
$resolvedStaging = [System.IO.Path]::GetFullPath($stagingRoot)
if ((Split-Path -Parent $resolvedStaging) -ne $resolvedRelease -or (Split-Path -Leaf $resolvedStaging) -notmatch '^\.staging-[a-f0-9]{32}$') { throw 'Unsafe staging directory' }
Remove-Item -LiteralPath $resolvedStaging -Recurse -Force
Write-Output $zipPath
