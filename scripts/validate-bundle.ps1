param(
    [string]$BundleFile = "src.lua.txt"
)

$ErrorActionPreference = "Stop"

$projectRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")).Path
$bundlePath = Join-Path $projectRoot $BundleFile

if (-not (Test-Path -LiteralPath $bundlePath)) {
    throw "Bundle not found: $bundlePath"
}

$content = [System.IO.File]::ReadAllText($bundlePath)
$errors = [System.Collections.Generic.List[string]]::new()

if ($content -match 'require\(script') {
    $errors.Add("Bundle still contains require(script...) calls")
}

if ($content -match '(?m)^\s*export\s+type\s+') {
    $errors.Add("Bundle still contains exported type declarations")
}

if ($content -match '::\s*[A-Za-z_]') {
    $errors.Add("Bundle still contains Luau cast syntax")
}

if ($content -match '(?m)^\s*(local\s+)?function\s+.*\)\s*:\s+') {
    $errors.Add("Bundle still contains function return type annotations")
}

if ($content -match '(?m)^\s*local\s+[A-Za-z_][A-Za-z0-9_]*\s*:\s+') {
    $errors.Add("Bundle still contains local variable type annotations")
}

$modules = [regex]::Matches($content, '__modules\["([^"]+)"\]') |
    ForEach-Object { $_.Groups[1].Value } |
    Sort-Object -Unique

$requires = [regex]::Matches($content, '__require\("([^"]+)"\)') |
    ForEach-Object { $_.Groups[1].Value } |
    Sort-Object -Unique

$missing = @($requires | Where-Object { $modules -notcontains $_ })
foreach ($module in $missing) {
    $errors.Add(('Missing module for __require("{0}")' -f $module))
}

if ($errors.Count -gt 0) {
    $errors | ForEach-Object { "ERROR: $_" }
    exit 1
}

"Bundle validation passed"
