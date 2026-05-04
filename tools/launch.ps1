#!/usr/bin/env pwsh
# Launches the Godot editor on this project. Searches a few common locations
# for a Godot 4 binary.

$ErrorActionPreference = "Stop"
$proj = Split-Path -Parent $PSScriptRoot

$candidates = @(
  "$env:LOCALAPPDATA\Programs\Godot\Godot_*.exe"
  "$env:LOCALAPPDATA\Godot\Godot_*.exe"
  "$env:USERPROFILE\Tools\Godot\Godot_*.exe"
  "$env:USERPROFILE\Apps\Godot\Godot_*.exe"
  "$env:ProgramFiles\Godot\Godot_*.exe"
  "${env:ProgramFiles(x86)}\Godot\Godot_*.exe"
  # Fallback: temp-extracted binary (will be GC'd by Windows eventually)
  "$env:TEMP\*_Godot_*_win64.exe.zip.*\Godot_*.exe"
)

$godot = $null
foreach ($pat in $candidates) {
  $found = Get-ChildItem -Path $pat -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if ($found) { $godot = $found.FullName; break }
}

if (-not $godot) {
  Write-Error "Could not find a Godot binary. Place Godot_v4.x_win64.exe in %LOCALAPPDATA%\Programs\Godot\ or pass -GodotPath."
  exit 1
}

Write-Host "Launching: $godot"
Write-Host "Project:   $proj"
& $godot --editor --path $proj
