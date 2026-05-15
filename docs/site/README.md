# do2screen — site source

This directory contains the Quarto source for the [do2screen documentation website](https://randrescastaneda.github.io/do2screen).

## Local preview

```bash
quarto preview docs/site
```

This starts a live-reloading local server. The rendered output goes to `docs/site/_site/` (gitignored).

## Full render (no server)

```bash
quarto render docs/site
```

## Structure

```
docs/site/
  _quarto.yml              # site config, nav, theme
  index.qmd                # landing page
  get-started.qmd          # installation + first example
  reference.qmd            # full option reference
  changelog.qmd            # version history
  contributing.qmd         # how to contribute
  articles/
    variable-tracing.qmd   # var() mode deep dive
    find-and-range.qmd     # find() and range() modes
    caveats.qmd            # known limitations
```

## Deployment

The site is built and deployed automatically by GitHub Actions (`.github/workflows/quarto-site.yml`) on every push to `master` that touches files under `docs/site/`.

**Required repository setting:** go to *Settings → Pages → Source* and select **"GitHub Actions"** (not "Deploy from a branch").
