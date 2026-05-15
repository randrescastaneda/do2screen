---
date: 2026-05-15
depth: light
parent-review: .cg-docs/reviews/2026-05-15-documentation-website-v2-review.md
type: verification
findings:
  P2.1: fixed
  P2.2: fixed
  P2.3: fixed
  P3.1: fixed
  P3.2: skipped
---

## Review Report (Verification Pass 3)

**Review depth**: light  
**Files reviewed**: 26 (`do2screen.ado`, `do2screen.sthlp`, `README.md`, `LICENSE`, `do2screen.pkg`, `stata.toc`, `make.do`, `docs/site/`, `.github/workflows/quarto-site.yml`, `.gitignore`, `roadmap.json`, `.cg-docs/`)  
**Findings**: 5 (P0: 0, P1: 0, P2: 3, P3: 2)

### Previously Resolved (suppressed)
- P3.1 (`/_site/` root-anchored) ✅ confirmed
- P3.2 (`docs/site/_freeze/` in `.gitignore`) ✅ confirmed
- P3.3 (Actions steps SHA-pinned) ✅ confirmed
- Verify-1 P3.1 (`docs/site/.nojekyll` deleted) ✅ confirmed
- Verify-2 P2.1 (branch topology fixed — `master` reset to `origin/master`) ✅ confirmed
- Verify-2 P2.2 (stale favicon ref removed from `_quarto.yml`) ✅ confirmed

### P2 — IMPORTANT (should fix)

- **[P2.1]** [cg-code-quality / cg-testing] `do2screen.ado:1` — Canonical `*!` version header reads `*! Version 4.0 <12may2026>` while `make.do`, `stata.toc`, and the in-file history block all use semver `0.5.0` at `15may2026`. `which do2screen` and `ado describe` read the top-of-file magic comment — not the history block — so the user-visible version is wrong.  
  **Why**: The semver migration was applied to the history block but the canonical first-line `*!` header was not updated.  
  **Fix**: Change line 1 to `*! Version 0.5.0 <15may2026>`.

- **[P2.2]** [cg-code-quality] `do2screen.sthlp:3` and `do2screen.sthlp:274` — Help title banner displays `<v 4.0>` and the Requirements paragraph reads "version 4.0 requires Stata 16.1 or higher". If the public version is `0.5.0` these will display the wrong version to every `help do2screen` caller.  
  **Why**: `.sthlp` was updated for License and author affiliation but version strings were not touched.  
  **Fix**: Update to `<v 0.5.0>` at line 3 and `version 0.5.0 requires` at line 274 — or normalise consistently on `4.0` if that is the intended public version.

- **[P2.3]** [cg-testing] `do2screen.sthlp:2` — SMCL modification date `{* 12may2026 }` is stale; the file was modified on 15 May 2026 in this branch.  
  **Why**: `help do2screen` displays this date; it should match the version bump date.  
  **Fix**: Change to `{* 15may2026 }`.

### P3 — MINOR

- **[P3.1]** [cg-code-quality] `do2screen.ado:3` — Santiago Garriga's email in the `*!` author header is `santiago.garriga@psestudent.eu` (stale PSE-student address). Every other artefact in this PR (`do2screen.sthlp`, `make.do`, `_quarto.yml` footer) uses `garrigasantiago@gmail.com`.  
  **Why**: Cross-file inconsistency; stale email appears in `net describe do2screen` output.  
  **Fix**: Update to `garrigasantiago@gmail.com`.

- **[P3.2]** [cg-testing] `.github/workflows/quarto-site.yml:35` — Quarto pinned as `version: "1.6"` (major.minor only), not a full semver pin. All other Actions steps in the same file are SHA-pinned.  
  **Why**: Patch releases within `1.6.x` can silently alter rendering output; inconsistent with the SHA-pinning discipline applied elsewhere.  
  **Fix**: Pin to the full version string, e.g., `"1.6.42"` (check current https://github.com/quarto-dev/quarto-cli/releases for latest `1.6.x`).

### ✅ Passed
- cg-code-quality: Gitignore, workflow SHA pins, license addition, and favicon removal all verified clean.
- cg-testing: All prior resolved findings confirmed. No regressions in test-coverage scope.
