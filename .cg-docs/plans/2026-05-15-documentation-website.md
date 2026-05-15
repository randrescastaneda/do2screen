---
date: 2026-05-15
title: "Quarto documentation website for do2screen"
status: active
scope: "Standard"
brainstorm: ".cg-docs/brainstorms/2026-05-15-documentation-website.md"
language: "Stata"
estimated-effort: "medium"
tags: [documentation, quarto, website, github-pages, github-actions]
phases: 2
---

# Plan: Quarto Documentation Website for do2screen

## Objective

Build a pkgdown-style documentation website for the `do2screen` Stata package using Quarto, deployed automatically to GitHub Pages via GitHub Actions. The site will serve both new users discovering the package and existing users looking for reference material.

## Context

- The package has a comprehensive `.sthlp` help file and a `docs/supported-syntax.md` developer reference, but no web presence.
- Pre-captured console output already exists in `tests/golden/` — these serve as source material for example output.
- The package is on SSC (outdated) and installable via `github install`.
- Branch: `feat/documentation-site`. Target URL: `randrescastaneda.github.io/do2screen`.

## Requirements

| ID  | Requirement                                              | Source      |
|-----|----------------------------------------------------------|-------------|
| R1  | Quarto website in `docs/site/` with `_quarto.yml`        | brainstorm  |
| R2  | Landing page with tagline, description, install snippet   | brainstorm  |
| R3  | Get Started page: SSC + GitHub install, first example     | brainstorm  |
| R4  | Reference page: all options, return values, requirements  | brainstorm  |
| R5  | Article: Variable tracing with pre-captured output        | brainstorm  |
| R6  | Article: Find & Range modes with examples                 | brainstorm  |
| R7  | Article: Caveats, limitations, quote/delimiter handling   | brainstorm  |
| R8  | Changelog page                                            | user        |
| R9  | Contributing page                                         | user        |
| R10 | GitHub Actions workflow: render + deploy to gh-pages       | brainstorm  |
| R11 | Human-readable source maintainable by AI agent            | brainstorm  |

## Implementation Steps

## Phase 1: Site infrastructure and content

### 1. Create Quarto project skeleton
- **Requirements**: R1, R11
- **Files**: `docs/site/_quarto.yml`, `docs/site/.nojekyll`
- **Details**: Configure `_quarto.yml` with:
  - `project: type: website`
  - `website: title`, `navbar` with nav items, `sidebar` for articles
  - `format: html` with a clean theme (`cosmo` or `lumen`)
  - `output-dir: ../../_site` (keeps rendered output at project root `_site/`, gitignored)
  - Search enabled
  - Footer with license and author info
  - Repo URL link in navbar
- **Acceptance criteria**: `quarto render docs/site` produces a navigable site skeleton locally

### 2. Create landing page (index.qmd)
- **Requirements**: R2
- **Files**: `docs/site/index.qmd`
- **Details**:
  - Hero section: package name, one-line description, version badge
  - "What it does" — three feature cards (Variable tracing, Find, Range)
  - Quick install code block (SSC + GitHub)
  - Link to Get Started
- **Acceptance criteria**: Landing page renders with proper styling and all links work

### 3. Create Get Started page
- **Requirements**: R3
- **Files**: `docs/site/get-started.qmd`
- **Details**:
  - Installation from SSC: `ssc install do2screen`
  - Installation from GitHub: `github install randrescastaneda/do2screen`
  - Direct `net install` fallback
  - Requirements: Stata 16.1+
  - First example: trace a variable in a sample do-file, show pre-captured output
  - First example: find a string, show output
- **Test Scenarios**:
  - ✅ All code blocks use `stata` syntax highlighting
  - ✅ Pre-captured output renders in styled code block
  - 🛑 No broken internal links
- **Acceptance criteria**: A new user can follow the page from install to first successful use

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
    - Basic: `find("Poverty")` — show output from `find_poverty_l5.txt`
    - With lines: `find("Poverty") lines(2)` — show `find_poverty_l2.txt`
    - Compound search: `find(`" "phrase" word "')` syntax explained
  - **Range mode**:
    - Two-number: `range(13 18)` — show output from `range_13.txt`
    - One-number + lines: `range(10) lines(10)`
  - Tabbed examples using Quarto tabsets
- **Acceptance criteria**: Both modes demonstrated with input command and output

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
  - Version 0.5.0 (current): initial structure
  - Placeholder for future versions
  - Note: "See GitHub releases for detailed history"
- **Acceptance criteria**: Page exists and renders

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
  - Trigger: push to `master` (paths: `docs/site/**`, `.github/workflows/quarto-site.yml`)
  - Job: checkout → setup Quarto → render `docs/site` → deploy to `gh-pages` branch
  - Use `quarto-dev/quarto-actions/setup@v2` and `quarto-dev/quarto-actions/render@v2`
  - Use `peaceiris/actions-gh-pages@v3` for deployment (or `actions/deploy-pages`)
  - Permissions: `pages: write`, `id-token: write`
- **Test Scenarios**:
  - ✅ Pushes to `docs/site/` trigger rendering
  - 🛑 Pushes to `.ado` files do NOT trigger rendering (unless `docs/site/` also changed)
  - ❌ Build failure does not leave gh-pages in broken state
- **Acceptance criteria**: After merge to master, site is live at `randrescastaneda.github.io/do2screen`

### 11. Add `.gitignore` entries and local preview instructions
- **Requirements**: R11
- **Files**: `.gitignore` (add `_site/`, `docs/site/.quarto/`), `docs/site/README.md`
- **Details**:
  - Gitignore rendered output and Quarto cache
  - Add a small `docs/site/README.md` explaining how to preview locally: `quarto preview docs/site`
  - Add `_site/` and `.quarto/` to `.gitignore`
- **Acceptance criteria**: `git status` is clean after a local render; preview instructions work

## Testing Strategy

- **Local render**: `quarto render docs/site` must complete without errors
- **Link validation**: All internal links between pages resolve (Quarto warns on broken links)
- **Content accuracy**: Pre-captured output matches current golden files (manual spot-check)
- **GH Actions**: Workflow YAML passes `actionlint` (if available) or at minimum follows the documented Quarto GH Actions pattern

## Documentation Checklist
- [x] Function documentation — content derived from existing `.sthlp`
- [ ] README updates — add link to website once live
- [ ] Inline comments — in `_quarto.yml` explaining nav structure
- [ ] Usage examples — all three modes demonstrated with output

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Golden file output contains `DQDQ` placeholders | High | Low | Clean up when quoting in articles (replace `DQDQ` → `"`) |
| GitHub Pages not enabled on repo | Medium | Medium | Document in README: user must enable Pages (Source: GitHub Actions) in repo settings |
| Quarto version mismatch between local and GH Actions | Low | Medium | Pin Quarto version in workflow (`version: '1.6'`) |

## Out of Scope

- Internal `_do2screen_*` program documentation (developer-only)
- Auto-generating content from `.sthlp` at build time (manual content for now, AI agent updates when needed)
- Custom domain setup
- Multilingual content
- Interactive Stata execution in the browser
