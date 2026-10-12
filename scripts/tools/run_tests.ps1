[CmdletBinding()]
param([string]$NameFilter = "", [int]$TimeoutSeconds = 90)
$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
Set-Location $root
function Invoke-CheckedCommand([string]$Program, [string[]]$Arguments, [string]$Label) {
    Write-Host ""
    Write-Host "== $Label ==" -ForegroundColor Cyan
    & $Program @Arguments
    if ($LASTEXITCODE -ne 0) { throw "$Label failed with exit code $LASTEXITCODE" }
}
$python = Get-Command py -ErrorAction SilentlyContinue
if ($python) {
    Invoke-CheckedCommand $python.Source @("-3", "scripts/tools/validate_project_contract.py") "Project contract preflight"
} else {
    $python = Get-Command python -ErrorAction SilentlyContinue
    if (-not $python) { throw "Python 3 is required. Install Python 3.10+ from https://www.python.org/downloads/windows/." }
    Invoke-CheckedCommand $python.Source @("scripts/tools/validate_project_contract.py") "Project contract preflight"
}
$godotPath = (& (Join-Path $PSScriptRoot "ensure_godot.ps1") | Select-Object -Last 1).Trim()
if (-not $godotPath -or -not (Test-Path -LiteralPath $godotPath)) { throw "Could not locate Godot. Set GODOT_EXE to your Godot 4.3+ executable." }
Write-Host "Using Godot: $godotPath"
Invoke-CheckedCommand $godotPath @("--headless", "--path", ".", "--import") "Godot import check"
$tests = @(Get-ChildItem -Path (Join-Path $root "tests") -Filter "test_*.tscn" -File | Sort-Object Name)
if ($tests.Count -eq 0) { throw "No tests/test_*.tscn files found; refusing to report an empty suite as success." }
$passed = 0
$failed = 0
$failureNames = [System.Collections.Generic.List[string]]::new()
foreach ($test in $tests) {
    if ($NameFilter -and $test.Name -notlike "*$NameFilter*") { continue }
    $stdout = [System.IO.Path]::GetTempFileName()
    $stderr = [System.IO.Path]::GetTempFileName()
    $relative = "res://tests/$($test.Name)"
    $arguments = @("--headless", "--path", ".", $relative)
    $process = Start-Process -FilePath $godotPath -ArgumentList $arguments -WorkingDirectory $root -PassThru -NoNewWindow -RedirectStandardOutput $stdout -RedirectStandardError $stderr
    $finished = $process.WaitForExit($TimeoutSeconds * 1000)
    $log = ((Get-Content -LiteralPath $stdout -Raw -ErrorAction SilentlyContinue) + [Environment]::NewLine + (Get-Content -LiteralPath $stderr -Raw -ErrorAction SilentlyContinue))
    if (-not $finished) {
        try { $process.Kill() } catch {}
        $reason = "timeout after $($TimeoutSeconds)s"
    } elseif ($process.ExitCode -ne 0) {
        $reason = "exit code $($process.ExitCode)"
    } elseif ($log -match '(?m)^FAIL\b|SCRIPT ERROR|Parse Error|Failed to load') {
        $reason = "failure/error reported in log"
    } else { $reason = $null }
    if ($reason) {
        Write-Host "FAIL  $($test.Name) ($reason)" -ForegroundColor Red
        if ($log) { ($log -split '\r?\n' | Where-Object { $_ -match 'FAIL|ERROR|error|Parse Error' } | Select-Object -First 6) | ForEach-Object { Write-Host "      $_" } }
        $failed++
        $failureNames.Add($test.Name)
    } else {
        Write-Host "PASS  $($test.Name)" -ForegroundColor Green
        $passed++
    }
    Remove-Item $stdout, $stderr -Force -ErrorAction SilentlyContinue
}
Write-Host ""
Write-Host "Test result: $passed passed, $failed failed."
if ($NameFilter -and ($passed + $failed) -eq 0) { throw "No tests matched filter '$NameFilter'." }
if ($failed -gt 0) { throw ("Failed tests: " + ($failureNames -join ", ")) }
Write-Host "HEADLESS TESTS: PASS" -ForegroundColor Green
