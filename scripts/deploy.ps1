# Deploy the site to GitHub Pages.
#
# Usage:
#   .\scripts\deploy.ps1                       # commit pending changes, push, and watch the workflow
#   .\scripts\deploy.ps1 -Repo my-portfolio    # also create/link the GitHub repo on first run
#   .\scripts\deploy.ps1 -Message "Update reel"
#
# Requires: git and GitHub CLI (gh) authenticated via `gh auth login`.

param(
    [string]$Repo = "",
    [string]$Message = "Update portfolio site",
    [string]$Branch = "main"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

# 1. Ensure we have a GitHub remote; create the repo if requested.
$remoteUrl = git remote get-url origin 2>$null
if (-not $remoteUrl) {
    if (-not $Repo) {
        throw "No 'origin' remote. Re-run with -Repo <name> to create the GitHub repository."
    }
    Write-Host "Creating GitHub repository '$Repo' and setting origin..."
    gh repo create $Repo --public --source . --remote origin
    if (-not $?) { throw "gh repo create failed." }
}

# 2. Commit any pending changes.
git add -A
$pending = git status --porcelain
if ($pending) {
    git commit -m $Message
    if (-not $?) { throw "git commit failed." }
} else {
    Write-Host "Nothing new to commit."
}

# 3. Push to the deployment branch.
git push -u origin $Branch
if (-not $?) { throw "git push failed." }

# 4. Enable GitHub Pages with the Actions build type (idempotent).
$repoSlug = gh repo view --json nameWithOwner -q .nameWithOwner
Write-Host "Ensuring GitHub Pages is enabled (build type: workflow)..."
gh api -X POST "repos/$repoSlug/pages" -f build_type=workflow 2>$null | Out-Null
if (-not $?) {
    # POST fails with 409 if Pages already exists; switch it to workflow mode instead.
    gh api -X PUT "repos/$repoSlug/pages" -f build_type=workflow | Out-Null
}

# 5. Watch the deploy workflow triggered by the push.
Write-Host "Waiting for the deploy workflow..."
Start-Sleep -Seconds 5
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