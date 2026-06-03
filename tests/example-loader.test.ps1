$ErrorActionPreference = "Stop"

$projectRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")).Path
$examplePath = Join-Path $projectRoot "Exemple.lua"
$content = [System.IO.File]::ReadAllText($examplePath)
$errors = [System.Collections.Generic.List[string]]::new()

if ($content -match 'loadstring\s*\(\s*game\s*\[\s*["'']HttpGet["'']\s*\]') {
    $errors.Add("Exemple.lua uses unguarded loadstring(game[HttpGet](...)) loader")
}

foreach ($required in @("fetchLibrary", "loadLibrary", "getRequestFunction")) {
    if ($content -notmatch ("function\s+" + [regex]::Escape($required) + "\s*\(")) {
        $errors.Add("Exemple.lua missing guarded loader helper: $required")
    }
}

foreach ($message in @("Falha ao compilar src.lua.txt", "Falha ao inicializar src.lua.txt")) {
    if ($content -notmatch [regex]::Escape($message)) {
        $errors.Add("Exemple.lua missing diagnostic message: $message")
    }
}

if ($errors.Count -gt 0) {
    $errors | ForEach-Object { "ERROR: $_" }
    exit 1
}

"Example loader test passed"
