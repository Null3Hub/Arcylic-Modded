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

function Assert-NotContains {
    param(
        [string]$Content,
        [string]$Needle,
        [string]$Message
    )

    if ($Content.Contains($Needle)) {
        throw $Message
    }
}

function Assert-ComponentUsesBase {
    param(
        [string]$Prefix,
        [string]$Component,
        [bool]$ShouldUseComponentLabel,
        [bool]$AllowMouseLeave = $false
    )

    $path = "$Prefix/Components/$Component.luau"
    $content = Read-ProjectFile $path
    Assert-Contains $content "local BaseComponent = require(script.Parent.Parent.Core.BaseComponent)" "$path should require BaseComponent"
    Assert-Contains $content "setmetatable($Component, { __index = BaseComponent })" "$path should inherit BaseComponent methods"
    Assert-Contains $content "BaseComponent.new($Component," "$path should instantiate through BaseComponent"
    Assert-Contains $content "Blockable = true" "$path should opt into Blockable when replacing Create.Blockable"
    Assert-NotContains $content "self._connections = {}" "$path should use BaseComponent connection storage"

    if ($ShouldUseComponentLabel) {
        Assert-Contains $content "Create.ComponentLabel" "$path should use Create.ComponentLabel"
    }

    if (-not $AllowMouseLeave) {
        Assert-NotContains $content "MouseLeave:Connect" "$path should rely on Create.HoverEffect for hover leave handling"
        Assert-NotContains $content "self._button.MouseLeave" "$path should rely on Create.HoverEffect for hover leave handling"
    }
}

function Assert-ComponentUsesBaseWithoutBlockable {
    param(
        [string]$Prefix,
        [string]$Component
    )

    $path = "$Prefix/Components/$Component.luau"
    $content = Read-ProjectFile $path
    Assert-Contains $content "local BaseComponent = require(script.Parent.Parent.Core.BaseComponent)" "$path should require BaseComponent"
    Assert-Contains $content "setmetatable($Component, { __index = BaseComponent })" "$path should inherit BaseComponent methods"
    Assert-Contains $content "BaseComponent.new($Component," "$path should instantiate through BaseComponent"
    Assert-Contains $content "Blockable = false" "$path should explicitly avoid Blockable overlays"
}

function Assert-StandardControlConfigSemantics {
    param([string]$Prefix)

    $togglePath = "$Prefix/Components/Toggle.luau"
    $toggle = Read-ProjectFile $togglePath
    Assert-Contains $toggle "self:SetValue(value, true)" "$togglePath config load should update silently"

    $keybindPath = "$Prefix/Components/Keybind.luau"
    $keybind = Read-ProjectFile $keybindPath
    Assert-Contains $keybind "return self._currentKey.Name" "$keybindPath config save should store key name"
    Assert-Contains $keybind 'type(value) == "string"' "$keybindPath config load should accept string key names"
    Assert-Contains $keybind "Enum.KeyCode[value]" "$keybindPath config load should resolve key names through Enum.KeyCode"
    Assert-Contains $keybind 'elseif typeof(value) == "EnumItem" then' "$keybindPath config load should accept legacy EnumItem values"
    Assert-Contains $keybind "self:SetKey(value)" "$keybindPath config load should apply legacy EnumItem values"

    $colorPickerPath = "$Prefix/Components/ColorPicker.luau"
    $colorPicker = Read-ProjectFile $colorPickerPath
    Assert-Contains $colorPicker "R = self._color.R" "$colorPickerPath config save should store red channel"
    Assert-Contains $colorPicker "G = self._color.G" "$colorPickerPath config save should store green channel"
    Assert-Contains $colorPicker "B = self._color.B" "$colorPickerPath config save should store blue channel"
    Assert-Contains $colorPicker "Color3.new(value.R, value.G, value.B)" "$colorPickerPath config load should rebuild Color3 from RGB table"
    Assert-Contains $colorPicker 'elseif typeof(value) == "Color3" then' "$colorPickerPath config load should accept legacy Color3 values"
    Assert-Contains $colorPicker "self:SetColor(value)" "$colorPickerPath config load should apply legacy Color3 values"
}

foreach ($prefix in @("src", "studio/AcrylicUI")) {
    Assert-ComponentUsesBase $prefix "Button" $true
    Assert-ComponentUsesBase $prefix "Toggle" $true
    Assert-ComponentUsesBase $prefix "Slider" $true
    Assert-ComponentUsesBase $prefix "TextBox" $true
    Assert-ComponentUsesBase $prefix "Keybind" $true
    Assert-ComponentUsesBase $prefix "ColorPicker" $true
    Assert-ComponentUsesBase $prefix "Dropdown" $true $true
    Assert-ComponentUsesBaseWithoutBlockable $prefix "Paragraph"
    Assert-ComponentUsesBaseWithoutBlockable $prefix "ContentSection"
    Assert-ComponentUsesBaseWithoutBlockable $prefix "Section"
    Assert-ComponentUsesBaseWithoutBlockable $prefix "Tab"
    Assert-StandardControlConfigSemantics $prefix
}

"BaseComponent adoption test passed"
