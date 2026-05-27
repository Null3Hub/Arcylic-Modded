param(
    [string]$SourceDir = "src",
    [string]$StudioSourceDir = "studio/AcrylicUI"
)

$ErrorActionPreference = "Stop"

$projectRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")).Path
$sourceRoot = Join-Path $projectRoot $SourceDir
$studioRoot = Join-Path $projectRoot $StudioSourceDir
$studioParent = Split-Path -Parent $studioRoot

if (-not (Test-Path -LiteralPath $sourceRoot)) {
    throw "Source directory not found: $sourceRoot"
}

if (-not (Test-Path -LiteralPath $studioParent)) {
    New-Item -ItemType Directory -Path $studioParent | Out-Null
}

if (Test-Path -LiteralPath $studioRoot) {
    Remove-Item -LiteralPath $studioRoot -Recurse -Force
}

Copy-Item -LiteralPath $sourceRoot -Destination $studioRoot -Recurse

"Synced $SourceDir to $StudioSourceDir"
