# Make the GitHub repo public, enable GitHub Pages, and deploy the site.
#
# Usage:
#   .\scripts\go-public.ps1                  # make public, enable Pages, deploy, watch
#   .\scripts\go-public.ps1 -Message "Update reel"   # also commit pending changes first
#
# Requires: git and GitHub CLI (gh) authenticated via `gh auth login`.

param(
    [string]$Message = "",
    [string]$Branch = "main"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$repoSlug = gh repo view --json nameWithOwner -q .nameWithOwner
if (-not $repoSlug) { throw "Could not resolve the GitHub repo. Is 'origin' set and gh authenticated?" }

# 1. Make the repo public (Pages on the free plan requires a public repo).
Write-Host "Making $repoSlug public..."
gh repo edit $repoSlug --visibility public --accept-visibility-change-consequences
if (-not $?) { throw "Failed to change visibility to public." }

# 2. Optionally commit and push pending changes.
if ($Message) {
    git add -A
    if (git status --porcelain) {
        git commit -m $Message
        if (-not $?) { throw "git commit failed." }
    }
    git push -u origin $Branch
    if (-not $?) { throw "git push failed." }
}

# 3. Enable GitHub Pages with the Actions build type (idempotent).
Write-Host "Ensuring GitHub Pages is enabled (build type: workflow)..."
gh api -X POST "repos/$repoSlug/pages" -f build_type=workflow 2>$null | Out-Null
if (-not $?) {
    # POST fails with 409 if Pages already exists; switch it to workflow mode instead.
    gh api -X PUT "repos/$repoSlug/pages" -f build_type=workflow | Out-Null
}

# 4. Trigger the deploy workflow and watch it.
Write-Host "Triggering the deploy workflow..."
gh workflow run deploy.yml --ref $Branch
if (-not $?) { throw "Failed to trigger deploy.yml." }
Start-Sleep -Seconds 6
$runId = gh run list --workflow deploy.yml --branch $Branch --limit 1 --json databaseId -q ".[0].databaseId"
if ($runId) {
    gh run watch $runId --exit-status
    if ($?) {
        $url = gh api "repos/$repoSlug/pages" -q .html_url
        Write-Host "`nDeployed! Site URL: $url"
    }
} else {
    Write-Host "No workflow run found yet; check https://github.com/$repoSlug/actions"
}