$ErrorActionPreference = "Stop"

$projectRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")).Path
$windowPath = Join-Path $projectRoot "src/Core/Window.luau"
$window = [System.IO.File]::ReadAllText($windowPath)
$errors = [System.Collections.Generic.List[string]]::new()

if ($window -notmatch 'Parent:\s*Instance\?') {
    $errors.Add("WindowConfig should accept an explicit Parent Instance")
}

if ($window -notmatch 'self\._parent\s*=\s*config\.Parent') {
    $errors.Add("Window.new should store config.Parent for ScreenGui parenting")
}

if ($window -notmatch 'if\s+self\._parent\s+then') {
    $errors.Add("Window:_CreateGui should prefer an explicit parent when provided")
}

if ($window -notmatch 'self\._screenGui\.Parent\s*=\s*guiParent') {
    $errors.Add("Window:_CreateGui should parent ScreenGui to the resolved guiParent")
}

if ($errors.Count -gt 0) {
    $errors | ForEach-Object { "ERROR: $_" }
    exit 1
}

"Window parent config test passed"
