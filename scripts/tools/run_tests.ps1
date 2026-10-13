[CmdletBinding()]
param([string]$NameFilter = "", [int]$TimeoutSeconds = 30)
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
    Invoke-CheckedCommand $python.Source @("-3", "scripts/tools/check_asset_licenses.py") "Asset license preflight"
} else {
    $python = Get-Command python -ErrorAction SilentlyContinue
    if (-not $python) { throw "Python 3 is required. Install Python 3.10+ from https://www.python.org/downloads/windows/." }
    Invoke-CheckedCommand $python.Source @("scripts/tools/validate_project_contract.py") "Project contract preflight"
    Invoke-CheckedCommand $python.Source @("scripts/tools/check_asset_licenses.py") "Asset license preflight"
}
$godotPath = (& (Join-Path $PSScriptRoot "ensure_godot.ps1") | Select-Object -Last 1).Trim()
if (-not $godotPath -or -not (Test-Path -LiteralPath $godotPath)) { throw "Could not locate Godot. Set GODOT_EXE to your Godot 4.3+ executable." }
Write-Host "Using Godot: $godotPath"
# Fresh CI checkouts have no imported resources or editor class cache. Import resources first, then
# scan the project in editor mode so global class_name scripts are registered before tests compile.
Invoke-CheckedCommand $godotPath @("--headless", "--path", ".", "--import") "Godot import check"
# Give the editor scan enough frames to index all global script classes on slower Windows CI workers.
Invoke-CheckedCommand $godotPath @("--headless", "--editor", "--path", ".", "--quit-after", "10") "Godot editor scan (global script classes)"
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
    $finished = $false
    $startupError = $false
    # The act smoke test now constructs real data-driven blockouts for several rooms; allow more startup time on Windows.
    $testTimeout = if ($test.Name -eq "test_acts.tscn") { [Math]::Max($TimeoutSeconds, 60) } else { $TimeoutSeconds }
    $deadline = [DateTime]::UtcNow.AddSeconds($testTimeout)
    while (-not $finished -and [DateTime]::UtcNow -lt $deadline) {
        $finished = $process.WaitForExit(500)
        $liveLog = ((Get-Content -LiteralPath $stdout -Raw -ErrorAction SilentlyContinue) + [Environment]::NewLine + (Get-Content -LiteralPath $stderr -Raw -ErrorAction SilentlyContinue))
        # Parse/load failures commonly leave Godot running without executing the test's quit().
        # Stop immediately rather than burning the full per-test timeout.
        if ($liveLog -match 'SCRIPT ERROR:|Parse Error:|Failed to load script|Failed to instantiate an autoload') {
            $startupError = $true
            if (-not $finished) { try { $process.Kill() } catch {} }
            $process.WaitForExit()
            $finished = $true
            break
        }
    }
    $log = ((Get-Content -LiteralPath $stdout -Raw -ErrorAction SilentlyContinue) + [Environment]::NewLine + (Get-Content -LiteralPath $stderr -Raw -ErrorAction SilentlyContinue))
    if ($startupError) {
        $reason = "script/load error (stopped early)"
    } elseif (-not $finished) {
        try { $process.Kill() } catch {}
        $reason = "timeout after $($testTimeout)s"
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
