param(
    [string]$SourceDir = "src",
    [string]$StudioSourceDir = "studio/AcrylicUI",
    [string]$PatchesDir = "studio/AcrylicUI-patches"
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

# Apply studio-specific patches after sync
$patchesRoot = Join-Path $projectRoot $PatchesDir
if (Test-Path -LiteralPath $patchesRoot) {
    Get-ChildItem -LiteralPath $patchesRoot -Recurse -File | ForEach-Object {
        $relativePath = $_.FullName.Substring($patchesRoot.Length + 1)
        $targetPath = Join-Path $studioRoot $relativePath
        $targetDir = Split-Path -Parent $targetPath
        if (-not (Test-Path -LiteralPath $targetDir)) {
            New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        }
        Copy-Item -LiteralPath $_.FullName -Destination $targetPath -Force
        Write-Host "Patched: $relativePath"
    }
}

"Synced $SourceDir to $StudioSourceDir (with $(@(Get-ChildItem -LiteralPath $patchesRoot -Recurse -File).Count) patches)"
