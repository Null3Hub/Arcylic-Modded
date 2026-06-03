$ErrorActionPreference = "Stop"

$projectRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")).Path

function Read-ProjectFile {
    param([string]$RelativePath)

    $path = Join-Path $projectRoot $RelativePath
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Expected file to exist: $RelativePath"
    }

    return [System.IO.File]::ReadAllText($path)
}

function Assert-Contains {
    param(
        [string]$Content,
        [string]$Needle,
        [string]$Message
    )

    if (-not $Content.Contains($Needle)) {
        throw $Message
    }
}

foreach ($prefix in @("src", "studio/AcrylicUI")) {
    $win = Read-ProjectFile "$prefix/Core/Window.luau"
    Assert-Contains $win "function Window:Unload()" "$prefix Window should define Unload method"
    Assert-Contains $win "self._components" "$prefix Unload should reference _components for cleanup"
    Assert-Contains $win "_sharedScreenGuiCount" "$prefix Window should track shared ScreenGui count"
    Assert-Contains $win "ConfigEncryption" "$prefix Window should require ConfigEncryption"
    Assert-Contains $win "RandomString" "$prefix Window should require RandomString"
    Assert-Contains $win "gethui" "$prefix Window should check gethui for GUI parent"
    Assert-Contains $win "get_hidden_gui" "$prefix Window should check get_hidden_gui for GUI parent"
    Assert-Contains $win "ProtectGui" "$prefix Window should call ProtectGui on ScreenGui"
}

Write-Host "Window Unload RED test passed" -ForegroundColor Green
