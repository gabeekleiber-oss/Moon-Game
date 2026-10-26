[CmdletBinding()]
param([string]$Exe = 'builds/windows/MoonGame.exe', [int]$TimeoutSeconds = 45)
# Smoke an exported Windows binary under Forward+ and Compatibility.
# Redirect to files, not unread pipes: debug exports may fill stdout before exiting.
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
    $outFile = [IO.Path]::GetTempFileName()
    $errFile = [IO.Path]::GetTempFileName()
    try {
        $process = Start-Process -FilePath $target -ArgumentList $arguments -WorkingDirectory (Split-Path -Parent $target) -PassThru -NoNewWindow -RedirectStandardOutput $outFile -RedirectStandardError $errFile
        if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
            $process.Kill()
            throw "$mode smoke test timed out"
        }
        $process.WaitForExit()
        $process.Refresh()
        $output = (Get-Content -LiteralPath $outFile -Raw -ErrorAction SilentlyContinue) + (Get-Content -LiteralPath $errFile -Raw -ErrorAction SilentlyContinue)
        if (($null -ne $process.ExitCode -and $process.ExitCode -ne 0) -or $output -match 'SCRIPT ERROR:|Parse Error:|Failed to load script') {
            throw "$mode smoke test failed (exit $($process.ExitCode)):`n$output"
        }
        Write-Host "PASS exported Windows game ($mode renderer)"
    } finally {
        Remove-Item -LiteralPath $outFile, $errFile -Force -ErrorAction SilentlyContinue
    }
}
