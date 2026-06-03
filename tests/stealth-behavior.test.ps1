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

$create = Read-ProjectFile "src/Utils/Create.luau"
Assert-Contains $create 'if property == "Name" then' "Create.Instance should special-case Name properties"
Assert-Contains $create 'instance[property] = "\0"' "Create.Instance should assign null names"

$window = Read-ProjectFile "src/Core/Window.luau"
Assert-Contains $window 'game:GetService("CoreGui")' "Window should request CoreGui for ScreenGui parenting"
Assert-Contains $window 'self._screenGui.Parent = coreGui' "Window should attempt CoreGui parenting after ScreenGui creation"
Assert-Contains $window 'if not parentedToCoreGui then' "Window should fall back if CoreGui parenting fails"
Assert-Contains $window 'player:WaitForChild("PlayerGui")' "Window should keep PlayerGui fallback for unavailable CoreGui"

$acrylicBlur = Read-ProjectFile "src/Core/AcrylicBlur.luau"
Assert-NotContains $acrylicBlur 'Locked = true,' "AcrylicBlur should not require plugin-only Locked in Create.Instance properties"
Assert-Contains $acrylicBlur 'self._root.Locked = true' "AcrylicBlur should only attempt Locked after root creation"

Assert-Contains $window 'pcall(AcrylicBlur.new, self._container)' "Window should guard AcrylicBlur creation"
Assert-Contains $window 'self._acrylicBlur = nil' "Window should keep UI alive when AcrylicBlur is unavailable"

"Stealth behavior test passed"
