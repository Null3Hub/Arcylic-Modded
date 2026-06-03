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
    $enc = Read-ProjectFile "$prefix/Utils/ConfigEncryption.luau"
    Assert-Contains $enc "local ConfigEncryption = {}" "$prefix ConfigEncryption should define the module table"
    Assert-Contains $enc "function ConfigEncryption.Encrypt" "$prefix ConfigEncryption should define Encrypt function"
    Assert-Contains $enc "function ConfigEncryption.Decrypt" "$prefix ConfigEncryption should define Decrypt function"
    Assert-Contains $enc "function ConfigEncryption.Base64Encode" "$prefix ConfigEncryption should define Base64Encode"
    Assert-Contains $enc "function ConfigEncryption.Base64Decode" "$prefix ConfigEncryption should define Base64Decode"
    Assert-Contains $enc "encrypt_seed" "$prefix Encrypt should calculate seed from data length"
    Assert-Contains $enc "72667" "$prefix Encrypt should use Neverlose seed offset"
    Assert-Contains $enc "return ConfigEncryption" "$prefix ConfigEncryption should return the module"
}

Write-Host "ConfigEncryption RED test passed" -ForegroundColor Green