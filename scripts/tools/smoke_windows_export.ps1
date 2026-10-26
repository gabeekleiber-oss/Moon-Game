[CmdletBinding()]
param([string]$Exe = 'builds/windows/MoonGame.exe', [int]$TimeoutSeconds = 45)
# Smoke an actual exported Windows binary in both Forward+ and Compatibility modes.
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$target = if ([IO.Path]::IsPathRooted($Exe)) { $Exe } else { Join-Path $root $Exe }
if (-not (Test-Path -LiteralPath $target)) { throw "Missing Windows export: $target" }
foreach ($mode in @('forward', 'compatibility')) {
    $arguments = if ($mode -eq 'forward') {
        '--headless --quit-after 60 -- --quality=medium'
    } else {
        '--headless --rendering-method gl_compatibility --quit-after 60 -- --quality=low'
    }
    $start = New-Object System.Diagnostics.ProcessStartInfo
    $start.FileName = $target
    $start.Arguments = $arguments
    $start.WorkingDirectory = Split-Path -Parent $target
    $start.UseShellExecute = $false
    $start.RedirectStandardOutput = $true
    $start.RedirectStandardError = $true
    $process = [System.Diagnostics.Process]::Start($start)
    if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
        $process.Kill()
        throw "$mode smoke test timed out"
    }
    $output = $process.StandardOutput.ReadToEnd() + $process.StandardError.ReadToEnd()
    if ($process.ExitCode -ne 0 -or $output -match 'SCRIPT ERROR:|Parse Error:|Failed to load script') {
        throw "$mode smoke test failed (exit $($process.ExitCode)):`n$output"
    }
    Write-Host "PASS exported Windows game ($mode renderer)"
}
