[CmdletBinding()]
param(
    [ValidateSet('release', 'debug')][string]$Mode = 'release',
    [string]$Output = 'builds/windows/MoonGame.exe'
)
# Native Windows equivalent of export_windows.sh; no Git Bash required.
$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
Set-Location $root
$godot = (& (Join-Path $PSScriptRoot 'ensure_godot.ps1') | Select-Object -Last 1).Trim()
if (-not (Test-Path -LiteralPath $godot)) { throw "Godot not found: $godot" }
if (-not $Output.EndsWith('.exe', [StringComparison]::OrdinalIgnoreCase)) { throw 'Output must end in .exe' }
$target = if ([IO.Path]::IsPathRooted($Output)) { $Output } else { Join-Path $root $Output }
$dir = Split-Path -Parent $target
New-Item -ItemType Directory -Force -Path $dir | Out-Null
& $godot --headless --path $root --import | Out-Null
if ($LASTEXITCODE -ne 0) { throw 'Godot resource import failed' }
$exportFlag = if ($Mode -eq 'release') { '--export-release' } else { '--export-debug' }
& $godot --headless --path $root $exportFlag 'Windows Desktop' $target
if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $target) -or (Get-Item $target).Length -eq 0) {
    throw 'Windows export failed. Install Godot export templates matching your editor version.'
}
$launcher = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'launch_windows_compat.cmd') -Raw
$launcher = $launcher.Replace('MoonGame.exe', (Split-Path -Leaf $target))
$launcherName = if ((Split-Path -Leaf $target) -eq 'MoonGame.exe') { 'Launch Compatibility.cmd' } else { 'Launch Compatibility - ' + [IO.Path]::GetFileNameWithoutExtension($target) + '.cmd' }
Set-Content -LiteralPath (Join-Path $dir $launcherName) -Value $launcher -Encoding ASCII
Write-Host "Windows export ready: $target"
