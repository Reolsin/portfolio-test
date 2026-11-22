# Make the GitHub repo private.
#
# Note: on the free plan, GitHub Pages is automatically disabled when the
# repo goes private, so the site will go offline.
#
# Usage:
#   .\scripts\go-private.ps1
#
# Requires: GitHub CLI (gh) authenticated via `gh auth login`.

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$repoSlug = gh repo view --json nameWithOwner -q .nameWithOwner
if (-not $repoSlug) { throw "Could not resolve the GitHub repo. Is 'origin' set and gh authenticated?" }

Write-Host "Making $repoSlug private..."
gh repo edit $repoSlug --visibility private --accept-visibility-change-consequences
if (-not $?) { throw "Failed to change visibility to private." }

$visibility = gh repo view $repoSlug --json visibility -q .visibility
Write-Host "Done. Visibility: $visibility"
Write-Host "Note: GitHub Pages is disabled while the repo is private; the site is offline."