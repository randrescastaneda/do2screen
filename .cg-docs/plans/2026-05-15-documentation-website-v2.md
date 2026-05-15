---
date: 2026-05-15
title: "Quarto documentation website for do2screen"
status: completed
completed-date: 2026-05-15
completed-phases: [1, 2]
scope: "Standard"
brainstorm: ".cg-docs/brainstorms/2026-05-15-documentation-website.md"
language: "Stata"
estimated-effort: "medium"
tags: [documentation, quarto, website, github-pages, github-actions]
phases: 2
review-notes: "Revised after /cg-plan-review. Fixes: version 4.0 (not 0.5.0), actions/deploy-pages (not peaceiris), SSC demoted, DQDQ callout in find article, .gitignore moved to Step 1."
---

# Plan: Quarto Documentation Website for do2screen

## Objective

Build a pkgdown-style documentation website for the `do2screen` Stata package using Quarto, deployed automatically to GitHub Pages via GitHub Actions. The site will serve both new users discovering the package and existing users looking for reference material.

## Context

- The package has a comprehensive `.sthlp` help file and a `docs/supported-syntax.md` developer reference, but no web presence.
- Pre-captured console output already exists in `tests/golden/` — these serve as source material for example output.
- The package is on SSC (outdated — likely an older version) and installable via `github install`.
- Branch: `feat/documentation-site`. Target URL: `randrescastaneda.github.io/do2screen`.
- Current version: **4.0** (12 May 2026) per `do2screen.ado`.
- Default branch: `master`.

## Requirements

| ID  | Requirement                                              | Source      |
|-----|----------------------------------------------------------|-------------|
| R1  | Quarto website in `docs/site/` with `_quarto.yml`        | brainstorm  |
| R2  | Landing page with tagline, description, install snippet   | brainstorm  |
| R3  | Get Started page: GitHub install (primary) + SSC (legacy) | brainstorm + review |
| R4  | Reference page: all options, return values, requirements  | brainstorm  |
| R5  | Article: Variable tracing with pre-captured output        | brainstorm  |
| R6  | Article: Find & Range modes with examples                 | brainstorm  |
| R7  | Article: Caveats, limitations, quote/delimiter handling   | brainstorm  |
| R8  | Changelog page (starting at v4.0)                         | user + review |
| R9  | Contributing page                                         | user        |
| R10 | GitHub Actions workflow: render + deploy via `actions/deploy-pages` | brainstorm + review |
| R11 | Human-readable source maintainable by AI agent            | brainstorm  |

## Implementation Steps

## Phase 1: Site infrastructure and content

### 1. Create Quarto project skeleton and .gitignore
- **Requirements**: R1, R11
- **Files**: `docs/site/_quarto.yml`, `docs/site/.nojekyll`, `.gitignore` (append entries)
- **Details**: Configure `_quarto.yml` with:
  - `project: type: website`
  - `website: title`, `navbar` with nav items, `sidebar` for articles
  - `format: html` with a clean theme (`cosmo` or `lumen`)
  - `output-dir: ../../_site` (keeps rendered output at project root `_site/`, gitignored)
  - Search enabled
  - Footer with license and author info
  - Repo URL link in navbar
  - Add to `.gitignore` immediately (prevents accidental commits during Phase 1 dev):
    ```
    _site/
    docs/site/.quarto/
    ```
- **Acceptance criteria**: `quarto render docs/site` produces a navigable site skeleton locally; `git status` shows no `_site/` or `.quarto/` artifacts

### 2. Create landing page (index.qmd)
- **Requirements**: R2
- **Files**: `docs/site/index.qmd`
- **Details**:
  - Hero section: package name, one-line description, version badge (v4.0)
  - "What it does" — three feature cards (Variable tracing, Find, Range)
  - Quick install code block (`github install` as primary)
  - Link to Get Started
- **Acceptance criteria**: Landing page renders with proper styling and all links work

### 3. Create Get Started page
- **Requirements**: R3
- **Files**: `docs/site/get-started.qmd`
- **Details**:
  - **Primary**: Installation from GitHub: `github install randrescastaneda/do2screen`
  - **Alternative**: Direct `net install` fallback
  - **Legacy callout**: SSC install (`ssc install do2screen`) with warning that SSC version may be outdated
  - Requirements: Stata 16.1+
  - First example: trace a variable in a sample do-file, show pre-captured output
  - First example: find a string, show output
- **Test Scenarios**:
  - ✅ All code blocks use `stata` syntax highlighting
  - ✅ Pre-captured output renders in styled code block
  - 🛑 No broken internal links
- **Acceptance criteria**: A new user can follow the page from install to first successful use; SSC warning is prominent

### 4. Create Reference page
- **Requirements**: R4
- **Files**: `docs/site/reference.qmd`
- **Details**:
  - Syntax section: `do2screen [using/], [options]`
  - Options table (from `.sthlp`) organized by category: Display, Specification, Export, Advanced
  - Each option: name, modes it applies to, description
  - Return values: scalars, matrices, frames
  - Requirements section: Stata 16.1+
- **Acceptance criteria**: Every option from the `.sthlp` file is represented with accurate description

### 5. Create Variable Tracing article
- **Requirements**: R5
- **Files**: `docs/site/articles/variable-tracing.qmd`
- **Details**:
  - Explain the concept: "trace how a variable was built"
  - Show the example do-file (`ex_gen_replace.do` content)
  - Show command: `do2screen using "example.do", var(income)`
  - Show pre-captured output (from golden files, cleaned up — replace `DQDQ` with `"`)
  - Explain lineage: parent variable tracing, `noprevious` option
  - Show `labels` option example (golden: `var_avg_score_labels.txt`)
  - Show `foreach` loop handling example
  - Show `text()` export option
- **Acceptance criteria**: All three variable-mode features (lineage, labels, loops) are demonstrated with output

### 6. Create Find & Range article
- **Requirements**: R6
- **Files**: `docs/site/articles/find-and-range.qmd`
- **Details**:
  - **Find mode**:
    - Basic: `find("Poverty")` — show output from `find_poverty_l5.txt` (no DQDQ tokens in this file — safe)
    - With lines: `find("Poverty") lines(2)` — show `find_poverty_l2.txt`
    - Compound search: `find(`" "phrase" word "')` syntax explained
    - **Inline callout**: note that when search strings contain double quotes, output may show `DQDQ` placeholder — link to [Caveats](caveats.qmd) for explanation
  - **Range mode**:
    - Two-number: `range(13 18)` — show output from `range_13.txt`
    - One-number + lines: `range(10) lines(10)`
  - Tabbed examples using Quarto tabsets
- **Acceptance criteria**: Both modes demonstrated with input command and output; DQDQ caveat is surfaced before the Caveats page

### 7. Create Caveats & Limitations article
- **Requirements**: R7
- **Files**: `docs/site/articles/caveats.qmd`
- **Details**:
  - Quote handling: explain `DQDQ`/`LlLl`/`RrRr` placeholders and why they exist
  - `#delimit ;` behavior
  - `///` continuation lines: appear as separate lines
  - Known limitations table (from `supported-syntax.md`): mata, program define, include, macros, frames, comments
  - Callout boxes for important warnings
- **Acceptance criteria**: All items from the "Known Limitations" table in `supported-syntax.md` are covered

### 8. Create Changelog page
- **Requirements**: R8
- **Files**: `docs/site/changelog.qmd`
- **Details**:
  - **Version 4.0** (12 May 2026): Breaking change — requires Stata 16.1+ (was 14). Frames used for internal data handling. Modularized internal programs.
  - Placeholder for future versions
  - Note: "See GitHub releases for detailed history"
- **Acceptance criteria**: Page exists, renders, and shows correct version (4.0)

### 9. Create Contributing page
- **Requirements**: R9
- **Files**: `docs/site/contributing.qmd`
- **Details**:
  - How to report bugs (GitHub Issues)
  - How to suggest features
  - Development setup: clone, run tests (`do tests/run_tests.do`)
  - Code style guidelines (brief)
  - License: MIT
- **Acceptance criteria**: Page exists with actionable instructions

## Phase 2: Deployment and polish

### 10. Create GitHub Actions workflow
- **Requirements**: R10
- **Files**: `.github/workflows/quarto-site.yml`
- **Details**:
  - Trigger: `push` to `master` (paths: `docs/site/**`, `.github/workflows/quarto-site.yml`)
  - Also add `workflow_dispatch` trigger for manual testing
  - Job steps:
    1. `actions/checkout@v4`
    2. `quarto-dev/quarto-actions/setup@v2` (pin version: `version: '1.6'`)
    3. `quarto-dev/quarto-actions/render@v2` with `path: docs/site`
    4. `actions/upload-pages-artifact@v3` with `path: _site`
    5. `actions/deploy-pages@v4`
  - Permissions: `pages: write`, `id-token: write`, `contents: read`
  - Environment: `github-pages`
  - **Required repo setting**: Pages source must be set to "GitHub Actions" (not "Deploy from a branch") — document this in acceptance criteria
- **Test Scenarios**:
  - ✅ Pushes to `docs/site/` trigger rendering
  - 🛑 Pushes to `.ado` files do NOT trigger rendering (unless `docs/site/` also changed)
  - ❌ Build failure does not leave gh-pages in broken state (deploy-pages is atomic)
- **Acceptance criteria**: After merge to master, site is live at `randrescastaneda.github.io/do2screen`. Repo Pages source is set to "GitHub Actions".

### 11. Add local preview instructions
- **Requirements**: R11
- **Files**: `docs/site/README.md`
- **Details**:
  - Add a small `docs/site/README.md` explaining how to preview locally: `quarto preview docs/site`
  - Note: `.gitignore` entries already added in Step 1
- **Acceptance criteria**: Preview instructions work; contributor can build site locally

## Testing Strategy

- **Local render**: `quarto render docs/site` must complete without errors
- **Link validation**: All internal links between pages resolve (Quarto warns on broken links)
- **Content accuracy**: Pre-captured output matches current golden files (manual spot-check); version number is 4.0 throughout
- **GH Actions**: Workflow YAML follows the documented Quarto + GitHub Pages pattern (`actions/deploy-pages`)

## Documentation Checklist
- [x] Function documentation — content derived from existing `.sthlp`
- [ ] README updates — add link to website once live
- [ ] Inline comments — in `_quarto.yml` explaining nav structure
- [ ] Usage examples — all three modes demonstrated with output

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Golden file output contains `DQDQ` placeholders in find/range modes | High | Low | Clean up when quoting in articles (replace `DQDQ` → `"`); add inline callout linking to Caveats page |
| GitHub Pages not enabled or source not set to "GitHub Actions" | Medium | Medium | Document in README and Step 10 acceptance criteria; `workflow_dispatch` allows manual testing |
| Quarto version mismatch between local and GH Actions | Low | Medium | Pin Quarto version in workflow (`version: '1.6'`) |
| SSC version stale — users install old version via SSC | Medium | Medium | SSC install demoted to "Legacy" callout with explicit warning |

## Out of Scope

- Internal `_do2screen_*` program documentation (developer-only)
- Auto-generating content from `.sthlp` at build time (manual content for now, AI agent updates when needed)
- Custom domain setup
- Multilingual content
- Interactive Stata execution in the browser
