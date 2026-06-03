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

$init = Read-ProjectFile "src/init.luau"
Assert-Contains $init 'AcrylicUI.Defaults = require(script.Constants.Defaults)' "AcrylicUI should expose Defaults"
Assert-Contains $init 'AcrylicUI.Icons = require(script.Constants.Icons)' "AcrylicUI should expose Icons"
Assert-Contains $init 'AcrylicUI.Layers = require(script.Constants.Layers)' "AcrylicUI should expose Layers"

$defaults = Read-ProjectFile "src/Constants/Defaults.luau"
foreach ($section in @("Window", "Notification", "Config", "Messages", "Device", "AcrylicBlur", "Components")) {
    Assert-Contains $defaults ("    {0} = {{" -f $section) ("Defaults should include {0}" -f $section)
}

$icons = Read-ProjectFile "src/Constants/Icons.luau"
foreach ($section in @("Window", "Components", "Notification")) {
    Assert-Contains $icons ("    {0} = {{" -f $section) ("Icons should include {0}" -f $section)
}

$layers = Read-ProjectFile "src/Constants/Layers.luau"
foreach ($section in @("Dropdown", "Blocker", "Window")) {
    Assert-Contains $layers ("    {0} = {{" -f $section) ("Layers should include {0}" -f $section)
}

$sizes = Read-ProjectFile "src/Constants/Sizes.luau"
foreach ($section in @("WindowChrome", "Dropdown", "ColorPicker", "Component")) {
    Assert-Contains $sizes ("    {0} = {{" -f $section) ("Sizes should include {0}" -f $section)
}


"Constants structure test passed"
