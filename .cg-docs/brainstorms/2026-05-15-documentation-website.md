---
date: 2026-05-15
title: "Documentation website for do2screen (pkgdown-style)"
status: decided
scope: "Standard"
chosen-approach: "Quarto Website in docs/site/"
tags: [documentation, website, quarto, github-pages, github-actions]
---

# Documentation Website for do2screen

## Context

The package lacks a user-facing website. The `.sthlp` file and `supported-syntax.md` contain all the information, but there's no discoverable, browsable web presence. A pkgdown-style site would serve new users discovering the package and existing users needing a reference.

## Requirements

- **Audience**: All users — new users discovering the package + existing users needing reference
- **Content**: Installation (SSC + `github` package), full feature reference, worked examples with pre-captured console output, caveats/limitations, changelog, contributing guide
- **Technology**: Quarto website rendered via GitHub Actions, deployed to GitHub Pages (`randrescastaneda.github.io/do2screen`)
- **Maintainability**: AI agent regenerates pages when package changes; human-readable `.qmd` source
- **SSC**: Package is on SSC (outdated); site should document both SSC and GitHub installation
- **Out of scope**: Internal `_do2screen_*` program documentation (developer-only)

## Approaches Considered

### Approach 1: Quarto Website in `docs/site/` (CHOSEN)

Quarto website project in `docs/site/` with `.qmd` source files. GitHub Actions workflow renders on push to `master` and deploys to `gh-pages` branch.

Structure:
```
docs/site/
  _quarto.yml
  index.qmd
  get-started.qmd
  reference.qmd
  articles/
    variable-tracing.qmd
    find-and-range.qmd
    caveats.qmd
  changelog.qmd
  contributing.qmd
.github/workflows/
  quarto-site.yml
```

- Pros: Clean separation from package source. Human-readable. Quarto gives sidebar nav, search, callouts, tabsets, code highlighting. Standard GH Actions workflow. AI-maintainable.
- Cons: Adds `docs/site/` directory. Contributors need Quarto for local preview (GH Actions handles production).
- Effort: Medium (2–3 days)

### Approach 2: Quarto at project root

- Pros: Simpler paths.
- Cons: Pollutes package root. Packaging friction with SSC/`net install`.

### Approach 3: Quarto flat in `docs/`

- Pros: Simple.
- Cons: Mixes internal developer docs with user-facing site.

## Decision

Approach 1 — Quarto Website in `docs/site/`. Clean separation, standard tooling, AI-maintainable source.

## Next Steps

1. Create `docs/site/_quarto.yml` with site config, navigation, and theme
2. Create landing page (`index.qmd`) with tagline, description, install snippet
3. Create `get-started.qmd` with full installation instructions and first example
4. Create `reference.qmd` with complete option table, return values, requirements
5. Create article pages: variable tracing, find & range, caveats
6. Create `changelog.qmd` and `contributing.qmd`
7. Add `.github/workflows/quarto-site.yml` for GitHub Actions deployment
8. Pre-capture representative console output for examples
9. Test local render
