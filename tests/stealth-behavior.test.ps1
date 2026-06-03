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

$baseComponent = Read-ProjectFile "src/Core/BaseComponent.luau"
Assert-Contains $baseComponent 'local RandomString = require(script.Parent.Parent.Utils.RandomString)' "BaseComponent should require RandomString"
Assert-Contains $baseComponent 'Name = RandomString.new()' "BaseComponent should use RandomString.new() for stealth naming"
Assert-NotContains $baseComponent 'Name = "\0"' "BaseComponent must not use null character names"

$create = Read-ProjectFile "src/Utils/Create.luau"
Assert-NotContains $create '"\0"' "Create.Instance must not use plugin-gated null names"
Assert-Contains $create 'Name = true' "Create.Instance should treat Name as an internal policy field"
Assert-Contains $create 'PreserveName = true' "Create.Instance should expose an explicit preserve-name escape hatch"
Assert-Contains $create 'RandomizeName = true' "Create.Instance should expose an explicit randomized-name option"
Assert-Contains $create 'className == "ScreenGui"' "Create.Instance should randomize root ScreenGui names"
Assert-Contains $create 'if not INTERNAL_PROPERTIES[property] then' "Create.Instance should skip internal policy fields during property assignment"

$window = Read-ProjectFile "src/Core/Window.luau"
Assert-Contains $window 'function Window:_FindGuiParent' "Window should define a _FindGuiParent method"
Assert-Contains $window 'game:GetService("CoreGui")' "Window should request CoreGui as a fallback parent"
Assert-Contains $window 'self._screenGui.Parent = guiParent' "Window should parent ScreenGui to the resolved guiParent"
Assert-Contains $window 'LocalPlayer:WaitForChild("PlayerGui")' "Window should keep PlayerGui as final fallback"

$acrylicBlur = Read-ProjectFile "src/Core/AcrylicBlur.luau"
Assert-NotContains $acrylicBlur 'Locked = true,' "AcrylicBlur should not require plugin-only Locked in Create.Instance properties"
Assert-Contains $acrylicBlur 'self._root.Locked = true' "AcrylicBlur should only attempt Locked after root creation"

Assert-Contains $window 'pcall(AcrylicBlur.new, self._container)' "Window should guard AcrylicBlur creation"
Assert-Contains $window 'self._acrylicBlur = nil' "Window should keep UI alive when AcrylicBlur is unavailable"

"Stealth behavior test passed"
