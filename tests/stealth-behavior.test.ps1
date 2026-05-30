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

$create = Read-ProjectFile "src/Utils/Create.luau"
Assert-Contains $create 'if property == "Name" then' "Create.Instance should special-case Name properties"
Assert-Contains $create 'instance[property] = "\0"' "Create.Instance should assign null names"

$window = Read-ProjectFile "src/Core/Window.luau"
Assert-Contains $window 'game:GetService("CoreGui")' "Window should request CoreGui for ScreenGui parenting"
Assert-Contains $window 'self._screenGui.Parent = coreGui' "Window should attempt CoreGui parenting after ScreenGui creation"
Assert-Contains $window 'if not parentedToCoreGui then' "Window should fall back if CoreGui parenting fails"
Assert-Contains $window 'player:WaitForChild("PlayerGui")' "Window should keep PlayerGui fallback for unavailable CoreGui"

"Stealth behavior test passed"
