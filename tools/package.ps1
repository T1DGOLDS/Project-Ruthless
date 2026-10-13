param(
    [string]$Version = "0.14.0-beta.72",
    [string]$RepositoryRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = "Stop"
$releaseRoot = Join-Path $RepositoryRoot "release"
$packageRoot = Join-Path $releaseRoot "ProjectRuthless"
$zipPath = Join-Path $releaseRoot ("ProjectRuthless-{0}.zip" -f $Version)

$resolvedRepository = [System.IO.Path]::GetFullPath($RepositoryRoot).TrimEnd([char]92)
$resolvedRelease = [System.IO.Path]::GetFullPath($releaseRoot)
if ($resolvedRelease -ne (Join-Path $resolvedRepository "release")) { throw "Unsafe release directory" }
if (Test-Path -LiteralPath $releaseRoot) {
    Remove-Item -LiteralPath $releaseRoot -Recurse -Force
}
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

$optionsRoot = Join-Path $releaseRoot "ProjectRuthless_Options"
Copy-Item -LiteralPath (Join-Path $RepositoryRoot "ProjectRuthless_Options") -Destination $optionsRoot -Recurse
$dungeonRoot = Join-Path $releaseRoot "ProjectRuthless_DungeonData"
Copy-Item -LiteralPath (Join-Path $RepositoryRoot "ProjectRuthless_DungeonData") -Destination $dungeonRoot -Recurse
Compress-Archive -LiteralPath @($packageRoot, $optionsRoot, $dungeonRoot) -DestinationPath $zipPath -CompressionLevel Optimal
Write-Output $zipPath
