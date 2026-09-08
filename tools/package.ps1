param(
    [string]$Version = "0.11.0",
    [string]$RepositoryRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = "Stop"
$releaseRoot = Join-Path $RepositoryRoot "release"
$packageRoot = Join-Path $releaseRoot "ProjectRuthless"
$zipPath = Join-Path $releaseRoot ("ProjectRuthless-{0}.zip" -f $Version)

if (Test-Path -LiteralPath $releaseRoot) {
    Remove-Item -LiteralPath $releaseRoot -Recurse -Force
}
New-Item -ItemType Directory -Path $packageRoot -Force | Out-Null

Copy-Item -LiteralPath (Join-Path $RepositoryRoot "Core.lua") -Destination $packageRoot
Copy-Item -LiteralPath (Join-Path $RepositoryRoot "ProjectRuthless.toc") -Destination $packageRoot
Copy-Item -LiteralPath (Join-Path $RepositoryRoot "README.md") -Destination $packageRoot
Copy-Item -LiteralPath (Join-Path $RepositoryRoot "CHANGELOG.md") -Destination $packageRoot
Copy-Item -LiteralPath (Join-Path $RepositoryRoot "LICENSE") -Destination $packageRoot
Copy-Item -LiteralPath (Join-Path $RepositoryRoot "Modules") -Destination $packageRoot -Recurse

Compress-Archive -LiteralPath $packageRoot -DestinationPath $zipPath -CompressionLevel Optimal
Write-Output $zipPath
