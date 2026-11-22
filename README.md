# Video Editor Portfolio

A lightweight, dependency-free static portfolio template for a video editor,
deployed to GitHub Pages via GitHub Actions.

## Structure

```
index.html                 # Single-page site (hero, work, services, about, contact)
css/style.css              # Dark cinematic theme, responsive layout
js/main.js                 # Mobile nav + footer year
.github/workflows/deploy.yml  # GitHub Pages deployment workflow
scripts/deploy.ps1         # One-command deploy (Windows / PowerShell)
scripts/deploy.sh          # One-command deploy (macOS / Linux / Git Bash)
```

## Local preview

No build step is required. Either open `index.html` directly, or serve it:

```powershell
python -m http.server 8000
# then visit http://localhost:8000
```

## Deploying to GitHub Pages

Prerequisites: [git](https://git-scm.com/) and the
[GitHub CLI](https://cli.github.com/) authenticated with `gh auth login`.

### First deploy (creates the repository)

```powershell
.\scripts\deploy.ps1 -Repo my-portfolio
```

```bash
./scripts/deploy.sh -r my-portfolio
```

The script will:

1. Create a public GitHub repo and set it as `origin` (first run only).
2. Commit any pending changes and push to `main`.
3. Enable GitHub Pages with the **GitHub Actions** build type.
4. Watch the `deploy.yml` workflow run and print the live site URL
   (`https://<user>.github.io/<repo>/`).

### Subsequent deploys

```powershell
.\scripts\deploy.ps1 -Message "Add new showreel"
```

Every push to `main` also triggers the workflow automatically, so a plain
`git push` deploys too — the scripts just add repo setup, Pages enablement,
and run watching on top.

## Customizing

- Replace the placeholder name **Alex Cutter**, bio, stats, and email in
  `index.html`.
- Swap the `.work-thumb` placeholder divs for real thumbnails or embedded
  Vimeo/YouTube iframes.
- Adjust colors via the CSS variables at the top of `css/style.css`.