param(
    [string]$SourceDir = "src",
    [string]$OutputFile = "src.lua.txt"
)

$ErrorActionPreference = "Stop"

$projectRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")).Path
$sourceRoot = Join-Path $projectRoot $SourceDir
$outputPath = Join-Path $projectRoot $OutputFile

if (-not (Test-Path -LiteralPath $sourceRoot)) {
    throw "Source directory not found: $sourceRoot"
}

$requireReplacements = [ordered]@{
    'require(script.Core.Window)' = '__require("Core.Window")'
    'require(script.Core.BaseComponent)' = '__require("Core.BaseComponent")'
    'require(script.Constants.Colors)' = '__require("Constants.Colors")'
    'require(script.Constants.Sizes)' = '__require("Constants.Sizes")'
    'require(script.Constants.Fonts)' = '__require("Constants.Fonts")'
    'require(script.Constants.Animation)' = '__require("Constants.Animation")'
    'require(script.Constants.Defaults)' = '__require("Constants.Defaults")'
    'require(script.Constants.Icons)' = '__require("Constants.Icons")'
    'require(script.Constants.Layers)' = '__require("Constants.Layers")'
    'require(script.Utils.Create)' = '__require("Utils.Create")'
    'require(script.Utils.Tween)' = '__require("Utils.Tween")'
    'require(script.Utils.Draggable)' = '__require("Utils.Draggable")'
    'require(script.Utils.Device)' = '__require("Utils.Device")'
    'require(script.Utils.Services)' = '__require("Utils.Services")'
    'require(script.Utils.IconResolver)' = '__require("Utils.IconResolver")'
    'require(script.Parent.Parent.Utils.Create)' = '__require("Utils.Create")'
    'require(script.Parent.Parent.Utils.Tween)' = '__require("Utils.Tween")'
    'require(script.Parent.Parent.Core.BaseComponent)' = '__require("Core.BaseComponent")'
    'require(script.Parent.Parent.Utils.Draggable)' = '__require("Utils.Draggable")'
    'require(script.Parent.Parent.Utils.Device)' = '__require("Utils.Device")'
    'require(script.Parent.Parent.Utils.Services)' = '__require("Utils.Services")'
    'require(script.Parent.Parent.Utils.IconResolver)' = '__require("Utils.IconResolver")'
    'require(script.Parent.IconResolver)' = '__require("Utils.IconResolver")'
    'require(script.Parent.Tween)' = '__require("Utils.Tween")'
    'require(script.Parent.Parent.Constants.Colors)' = '__require("Constants.Colors")'
    'require(script.Parent.Parent.Constants.Sizes)' = '__require("Constants.Sizes")'
    'require(script.Parent.Parent.Constants.Fonts)' = '__require("Constants.Fonts")'
    'require(script.Parent.Parent.Constants.Animation)' = '__require("Constants.Animation")'
    'require(script.Parent.Parent.Constants.Defaults)' = '__require("Constants.Defaults")'
    'require(script.Parent.Parent.Constants.Icons)' = '__require("Constants.Icons")'
    'require(script.Parent.Parent.Constants.Layers)' = '__require("Constants.Layers")'
    'require(script.Parent.Parent.Components.Section)' = '__require("Components.Section")'
    'require(script.Parent.AcrylicBlur)' = '__require("Core.AcrylicBlur")'
    'require(script.Parent.Notification)' = '__require("Core.Notification")'
    'require(script.Parent.Button)' = '__require("Components.Button")'
    'require(script.Parent.Toggle)' = '__require("Components.Toggle")'
    'require(script.Parent.Slider)' = '__require("Components.Slider")'
    'require(script.Parent.Dropdown)' = '__require("Components.Dropdown")'
    'require(script.Parent.TextBox)' = '__require("Components.TextBox")'
    'require(script.Parent.Paragraph)' = '__require("Components.Paragraph")'
    'require(script.Parent.Keybind)' = '__require("Components.Keybind")'
    'require(script.Parent.ColorPicker)' = '__require("Components.ColorPicker")'
    'require(script.Parent.Tab)' = '__require("Components.Tab")'
    'require(script.Parent.ContentSection)' = '__require("Components.ContentSection")'
    'require(script.Parent.Services)' = '__require("Utils.Services")'
}

function Get-ModuleName {
    param([string]$FilePath)

    $rootForUri = $sourceRoot
    if (-not $rootForUri.EndsWith([System.IO.Path]::DirectorySeparatorChar)) {
        $rootForUri += [System.IO.Path]::DirectorySeparatorChar
    }

    $rootUri = [System.Uri]::new($rootForUri)
    $fileUri = [System.Uri]::new($FilePath)
    $relative = [System.Uri]::UnescapeDataString($rootUri.MakeRelativeUri($fileUri).ToString())
    $withoutExtension = [System.IO.Path]::ChangeExtension($relative, $null)
    $moduleName = ($withoutExtension -replace '[\\/]', '.').TrimEnd('.')

    if ($moduleName -eq "init") {
        return "init"
    }

    return $moduleName
}

function Convert-SourceForBundle {
    param([string]$Source)

    $sourceLines = $Source -split "`r?`n"
    $keptLines = [System.Collections.Generic.List[string]]::new()
    $skippingType = $false
    $braceDepth = 0

    foreach ($line in $sourceLines) {
        if (-not $skippingType -and $line -match '^\s*export\s+type\s+') {
            $openCount = ([regex]::Matches($line, '\{')).Count
            $closeCount = ([regex]::Matches($line, '\}')).Count
            $braceDepth = $openCount - $closeCount
            $skippingType = $braceDepth -gt 0
            continue
        }

        if ($skippingType) {
            $openCount = ([regex]::Matches($line, '\{')).Count
            $closeCount = ([regex]::Matches($line, '\}')).Count
            $braceDepth += $openCount - $closeCount

            if ($braceDepth -le 0) {
                $skippingType = $false
            }

            continue
        }

        $keptLines.Add($line)
    }

    $result = $keptLines -join "`n"

    foreach ($entry in $requireReplacements.GetEnumerator()) {
        $result = $result.Replace($entry.Key, $entry.Value)
    }

    $lines = $result -split "`r?`n"
    $inBlockComment = $false
    $trimmedLines = foreach ($line in $lines) {
        $stripped = $line.TrimEnd()

        if ($stripped -match '--\[\[') {
            $inBlockComment = $true
        }

        if (-not $inBlockComment -and $stripped -notmatch '^\s*--') {
            if ($stripped -match '^\s*(local\s+)?function\s+') {
                $stripped = $stripped -replace '\)\s*:\s+.*$', ')'
            }

            if ($stripped -match '^\s*\)\s*:\s+') {
                $stripped = $stripped -replace '^\s*\)\s*:\s+.*$', ')'
            }

            $stripped = $stripped -replace '::\s*[A-Za-z_][A-Za-z0-9_.]*\??', ''
            $stripped = $stripped -replace '(\(|,\s*)([A-Za-z_][A-Za-z0-9_]*)\s*:\s+\([^\)]*\)\s*->\s*\([^\)]*\)', '$1$2'
            $stripped = $stripped -replace '(\(|,\s*)([A-Za-z_][A-Za-z0-9_]*)\s*:\s+\{[^\}]*\}\??', '$1$2'
            $stripped = $stripped -replace '(\(|,\s*)([A-Za-z_][A-Za-z0-9_]*)\s*:\s+\([^\)]*\)\??', '$1$2'
            $stripped = $stripped -replace '(\(|,\s*)([A-Za-z_][A-Za-z0-9_]*)\s*:\s+[^,\)]+', '$1$2'
            $stripped = $stripped -replace '^(\s*[A-Za-z_][A-Za-z0-9_]*)\s*:\s+[^,]+(,?)$', '$1$2'
            $stripped = $stripped -replace '^(\s*local\s+[A-Za-z_][A-Za-z0-9_]*)\s*:\s+[^=]+(\s*=.*)?$', '$1$2'
        }

        if ($stripped -match '\]\]') {
            $inBlockComment = $false
        }

        $stripped.TrimEnd()
    }

    return ($trimmedLines -join "`n").TrimEnd()
}

$files = Get-ChildItem -LiteralPath $sourceRoot -Recurse -Filter "*.luau" |
    Where-Object { $_.Name -ne "Types.luau" } |
    Sort-Object FullName

$builder = [System.Text.StringBuilder]::new()
[void]$builder.AppendLine("-- Generated by scripts/build-bundle.ps1 from src/. Do not edit manually.")
[void]$builder.AppendLine("local __modules = {}")
[void]$builder.AppendLine("local __cache = {}")
[void]$builder.AppendLine("")
[void]$builder.AppendLine("local function __require(name)")
[void]$builder.AppendLine("    if __cache[name] ~= nil then")
[void]$builder.AppendLine("        return __cache[name]")
[void]$builder.AppendLine("    end")
[void]$builder.AppendLine("")
[void]$builder.AppendLine("    local loader = __modules[name]")
[void]$builder.AppendLine("    if not loader then")
[void]$builder.AppendLine('        error("AcrylicUI bundle missing module: " .. tostring(name), 2)')
[void]$builder.AppendLine("    end")
[void]$builder.AppendLine("")
[void]$builder.AppendLine("    local value = loader()")
[void]$builder.AppendLine("    __cache[name] = value")
[void]$builder.AppendLine("    return value")
[void]$builder.AppendLine("end")
[void]$builder.AppendLine("")

foreach ($file in $files) {
    $moduleName = Get-ModuleName -FilePath $file.FullName
    $source = Get-Content -LiteralPath $file.FullName -Raw
    $converted = Convert-SourceForBundle -Source $source

    [void]$builder.AppendLine(("__modules[{0}] = function()" -f ($moduleName | ConvertTo-Json -Compress)))
    [void]$builder.AppendLine($converted)
    [void]$builder.AppendLine("end")
    [void]$builder.AppendLine("")
}

[void]$builder.AppendLine('return __require("init")')

$bundle = $builder.ToString() -replace "`r`n", "`n"
[System.IO.File]::WriteAllText($outputPath, $bundle, [System.Text.UTF8Encoding]::new($false))
"Generated $OutputFile from $SourceDir"
