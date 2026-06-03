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
    Assert-Contains $win "function Window:_FindGuiParent" "$prefix Window should define _FindGuiParent method"
    Assert-Contains $win "gethui" "$prefix _FindGuiParent should check gethui"
    Assert-Contains $win "get_hidden_gui" "$prefix _FindGuiParent should check get_hidden_gui"
    Assert-Contains $win "CoreGui" "$prefix _FindGuiParent should fall back to CoreGui"
    Assert-Contains $win "PlayerGui" "$prefix _FindGuiParent should fall back to PlayerGui"
}

Write-Host "GUI parent fallback test passed" -ForegroundColor Green