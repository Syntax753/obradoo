#!/usr/bin/env pwsh
# Runs headless validation: imports the project, then runs the validate.gd
# script which loads every Memory resource, builds every timeline, and verifies
# every scene PackedScene loads.

$ErrorActionPreference = "Stop"
$proj = Split-Path -Parent $PSScriptRoot

$candidates = @(
  "$env:LOCALAPPDATA\Programs\Godot\Godot_*.exe"
  "$env:LOCALAPPDATA\Godot\Godot_*.exe"
  "$env:USERPROFILE\Tools\Godot\Godot_*.exe"
  "$env:USERPROFILE\Apps\Godot\Godot_*.exe"
  "$env:ProgramFiles\Godot\Godot_*.exe"
  "${env:ProgramFiles(x86)}\Godot\Godot_*.exe"
  "$env:TEMP\*_Godot_*_win64.exe.zip.*\Godot_*.exe"
)

$godot = $null
foreach ($pat in $candidates) {
  $found = Get-ChildItem -Path $pat -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
  if ($found) { $godot = $found.FullName; break }
}

if (-not $godot) {
  Write-Error "Could not find a Godot binary."
  exit 1
}

Write-Host "[1/2] Editor import (catches scene/script parse errors)..."
& $godot --headless --editor --quit --path $proj | Out-Null
if ($LASTEXITCODE -ne 0) { Write-Error "Editor import failed."; exit $LASTEXITCODE }

Write-Host "[2/2] Data validation (loads memories, builds timelines)..."
# NOTE: --script mode does not register autoloads, so the validation script
# only checks data resources and timeline builders, not full scene runtime.
& $godot --headless --path $proj --script res://tools/validate.gd
exit $LASTEXITCODE
