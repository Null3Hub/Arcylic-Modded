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
    $rs = Read-ProjectFile "$prefix/Utils/RandomString.luau"
    Assert-Contains $rs "local RandomString = {}" "$prefix RandomString should define the module table"
    Assert-Contains $rs "function RandomString.new" "$prefix RandomString should define new function"
    Assert-Contains $rs "math.random(1, 7)" "$prefix RandomString should use chars 1-7 (control characters)"
    Assert-Contains $rs "return RandomString" "$prefix RandomString should return the module"
}

Write-Host "RandomString RED test passed" -ForegroundColor Green