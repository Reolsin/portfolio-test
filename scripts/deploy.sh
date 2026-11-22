#!/usr/bin/env bash
# Deploy the site to GitHub Pages.
#
# Usage:
#   ./scripts/deploy.sh                        # commit pending changes, push, watch the workflow
#   ./scripts/deploy.sh -r my-portfolio        # also create/link the GitHub repo on first run
#   ./scripts/deploy.sh -m "Update reel"
#
# Requires: git and GitHub CLI (gh) authenticated via `gh auth login`.

set -euo pipefail
cd "$(dirname "$0")/.."

REPO=""
MESSAGE="Update portfolio site"
BRANCH="main"

while getopts "r:m:b:" opt; do
  case "$opt" in
    r) REPO="$OPTARG" ;;
    m) MESSAGE="$OPTARG" ;;
    b) BRANCH="$OPTARG" ;;
    *) echo "Usage: $0 [-r repo-name] [-m commit-message] [-b branch]"; exit 1 ;;
  esac
done

# 1. Ensure we have a GitHub remote; create the repo if requested.
if ! git remote get-url origin >/dev/null 2>&1; then
  if [ -z "$REPO" ]; then
    echo "No 'origin' remote. Re-run with -r <name> to create the GitHub repository." >&2
    exit 1
  fi
  echo "Creating GitHub repository '$REPO' and setting origin..."
  gh repo create "$REPO" --public --source . --remote origin
fi

# 2. Commit any pending changes.
git add -A
if [ -n "$(git status --porcelain)" ]; then
  git commit -m "$MESSAGE"
else
  echo "Nothing new to commit."
fi

# 3. Push to the deployment branch.
git push -u origin "$BRANCH"

# 4. Enable GitHub Pages with the Actions build type (idempotent).
REPO_SLUG=$(gh repo view --json nameWithOwner -q .nameWithOwner)
echo "Ensuring GitHub Pages is enabled (build type: workflow)..."
gh api -X POST "repos/$REPO_SLUG/pages" -f build_type=workflow >/dev/null 2>&1 || \
  gh api -X PUT "repos/$REPO_SLUG/pages" -f build_type=workflow >/dev/null

# 5. Watch the deploy workflow triggered by the push.
echo "Waiting for the deploy workflow..."
sleep 5
RUN_ID=$(gh run list --workflow deploy.yml --branch "$BRANCH" --limit 1 --json databaseId -q '.[0].databaseId')
if [ -n "$RUN_ID" ]; then
  gh run watch "$RUN_ID" --exit-status
  URL=$(gh api "repos/$REPO_SLUG/pages" -q .html_url)
  echo ""
  echo "Deployed! Site URL: $URL"
else
  echo "No workflow run found yet; check https://github.com/$REPO_SLUG/actions"
fi