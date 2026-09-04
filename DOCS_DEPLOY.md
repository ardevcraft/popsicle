# Deploy Popsicle docs to GitHub Pages

This package contains a prebuilt static site in `docs/` and a GitHub Pages workflow in `.github/workflows/pages.yml`.

## Setup

1. Copy `docs/` and `.github/workflows/pages.yml` into the root of `ardevcraft/popsicle`.
2. Commit and push to `master`.
3. In GitHub, open **Settings → Pages**.
4. Under **Build and deployment → Source**, select **GitHub Actions**.
5. Run or re-run **Deploy Popsicle docs** if the first deployment did not start automatically.

The site is configured for:

`https://ardevcraft.github.io/popsicle/`

## Local preview

From the repository root:

```bash
python3 -m http.server 8080 --directory docs
```

Then open `http://localhost:8080`.

## Updating content

The generated site is dependency-free HTML/CSS/JS. Edit files under `docs/` directly or regenerate them from the project documentation before a release.
