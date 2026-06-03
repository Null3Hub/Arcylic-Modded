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
    $base = Read-ProjectFile "$prefix/Core/BaseComponent.luau"
    Assert-Contains $base "local BaseComponent = {}" "$prefix BaseComponent should define the class table"
    Assert-Contains $base "BaseComponent.__index = BaseComponent" "$prefix BaseComponent should expose __index"
    Assert-Contains $base "function BaseComponent.new(classTable" "$prefix BaseComponent should accept a child class table"
    Assert-Contains $base "classTable.__index = classTable" "$prefix BaseComponent should make plain child class tables usable as instance metatables"
    Assert-Contains $base "getmetatable(classTable) == nil" "$prefix BaseComponent should detect child class tables without inheritance"
    Assert-Contains $base "setmetatable(classTable, { __index = BaseComponent })" "$prefix BaseComponent should chain child class tables to BaseComponent when missing"
    Assert-Contains $base "setmetatable({}, classTable or BaseComponent)" "$prefix BaseComponent should preserve child component method lookup"
    Assert-Contains $base "self._connections = {}" "$prefix BaseComponent should initialize connection tracking"
    Assert-Contains $base 'Name = RandomString.new()' "$prefix BaseComponent should use RandomString.new() for stealth naming"
    Assert-Contains $base "PreserveName = true" "$prefix BaseComponent should preserve the stealth null frame name"
    Assert-Contains $base "config.Properties or {}" "$prefix BaseComponent should support extra frame properties"
    Assert-Contains $base "if config.Corner ~= false then" "$prefix BaseComponent should allow disabling UICorner"
    Assert-Contains $base "if config.Stroke ~= false then" "$prefix BaseComponent should allow disabling UIStroke"
    Assert-Contains $base "if config.Blockable == true then" "$prefix BaseComponent should make Blockable opt-in"
    Assert-Contains $base "function BaseComponent:Connect" "$prefix BaseComponent should provide tracked event connection"
    Assert-Contains $base "function BaseComponent:DisconnectAll" "$prefix BaseComponent should provide bulk disconnect"
    Assert-Contains $base "function BaseComponent:Destroy" "$prefix BaseComponent should provide base destroy"
    Assert-Contains $base "UnregisterConfigElement" "$prefix BaseComponent destroy should unregister config elements when present"
    Assert-Contains $base "UnregisterKeybind" "$prefix BaseComponent destroy should unregister keybinds when present"

    $create = Read-ProjectFile "$prefix/Utils/Create.luau"
    Assert-Contains $create "local Tween = require(script.Parent.Tween)" "$prefix Create helpers should use the Tween utility"
    Assert-Contains $create "function Create.ComponentLabel" "$prefix Create should define ComponentLabel"
    Assert-Contains $create "function Create.HoverEffect" "$prefix Create should define HoverEffect"
    Assert-Contains $create "function Create.Configurable" "$prefix Create should define Configurable"
    Assert-Contains $create "function Create.ApplyIcon(imageLabel: ImageLabel, icon: string?, fallbackIcon: string?): boolean" "$prefix Create.ApplyIcon should keep the typed signature"
}

$bundle = Read-ProjectFile "scripts/build-bundle.ps1"
Assert-Contains $bundle "Core.BaseComponent" "Bundle builder should map BaseComponent requires"
Assert-Contains $bundle "require(script.Parent.Tween)" "Bundle builder should map Create.luau Tween require"

"BaseComponent core test passed"
