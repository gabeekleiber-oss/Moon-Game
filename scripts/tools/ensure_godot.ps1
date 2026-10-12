[CmdletBinding()]
param([string]$RequestedVersion = "4.3-stable")
$ErrorActionPreference = "Stop"
function Find-Godot {
    if ($env:GODOT_EXE -and (Test-Path -LiteralPath $env:GODOT_EXE)) { return (Resolve-Path -LiteralPath $env:GODOT_EXE).Path }
    foreach ($name in @("godot_console.exe", "godot.exe", "godot")) {
        $cmd = Get-Command $name -ErrorAction SilentlyContinue
        if ($cmd -and $cmd.Source) { return $cmd.Source }
    }
    foreach ($candidate in @("$env:LOCALAPPDATA\Programs\Godot\godot.exe", "$env:LOCALAPPDATA\Godot\godot.exe", "C:\Godot\godot.exe")) {
        if (Test-Path -LiteralPath $candidate) { return $candidate }
    }
    return $null
}
$installed = Find-Godot
if ($installed) {
    $versionOutput = (& $installed --version 2>&1 | Out-String).Trim()
    if ($LASTEXITCODE -eq 0 -and $versionOutput -match '^4\.(\d+)') {
        if ([int]$Matches[1] -ge 3) { Write-Output $installed; exit 0 }
        Write-Warning "Found Godot $versionOutput, but this project requires 4.3 or newer."
    }
}
$cacheRoot = Join-Path $env:LOCALAPPDATA "MoonGame\Godot\$RequestedVersion"
$exe = Join-Path $cacheRoot "Godot_v4.3-stable_win64_console.exe"
if (-not (Test-Path -LiteralPath $exe)) {
    New-Item -ItemType Directory -Path $cacheRoot -Force | Out-Null
    $zip = Join-Path $cacheRoot "godot-windows-console.zip"
    $url = "https://github.com/godotengine/godot/releases/download/4.3-stable/Godot_v4.3-stable_win64_console.exe.zip"
    Write-Host "Downloading official Godot 4.3 stable console build into the user cache..."
    Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing
    Expand-Archive -LiteralPath $zip -DestinationPath $cacheRoot -Force
    Remove-Item -LiteralPath $zip -Force
}
if (-not (Test-Path -LiteralPath $exe)) { throw "Godot bootstrap did not produce expected executable: $exe" }
$hash = (Get-FileHash -LiteralPath $exe -Algorithm SHA256).Hash
Write-Host "Godot executable SHA-256 (record only; not independently checksum-verified): $hash"
Write-Output $exe
