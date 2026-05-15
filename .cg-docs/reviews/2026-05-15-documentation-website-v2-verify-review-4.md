---
date: 2026-05-15
depth: light
parent-review: .cg-docs/reviews/2026-05-15-documentation-website-v2-review.md
type: verification
findings:
  P2.1: skipped
  P2.2: fixed
  P3.1: skipped
  P3.2: fixed
---

## Review Report (Verification Pass 4)

**Review depth**: light  
**Files reviewed**: 2 (`do2screen.ado`, `do2screen.sthlp`)  
**Findings**: 4 (P0: 0, P1: 0, P2: 2, P3: 2)

### Previously Resolved (suppressed)
- All prior chain fixes (gitignore, SHA pins, favicon, nojekyll, branch topology) ✅ confirmed
- Verify-3 P2.1: `do2screen.ado:1` version header → `0.5.0 <15may2026>` ✅ confirmed
- Verify-3 P2.2: `do2screen.sthlp:3,274` version strings → `0.5.0` ✅ confirmed
- Verify-3 P2.3: `do2screen.sthlp:2` SMCL date → `15may2026` ✅ confirmed
- Verify-3 P3.1: `do2screen.ado:3` email → `garrigasantiago@gmail.com` ✅ confirmed
- Verify-3 P3.2: Quarto version pin — skipped (not fixed, not re-reported)

### P2 — IMPORTANT (should fix)

- **[P2.1]** [cg-code-quality] `_do2screen_aftervar.ado:1`, `_do2screen_delimit.ado:1`, `_do2screen_display.ado:1`, `_do2screen_find.ado:1`, `_do2screen_parse.ado:1`, `_do2screen_range.ado:1`, `_do2screen_return.ado:1`, `_do2screen_vartrack.ado:1` — all eight sub-command `*!` headers still read `v4.0 <12may2026>` after the main package was migrated to the 0.x scheme.  
  **Why**: `which _do2screen_*` returns old abandoned version strings; cross-file version mismatch breaks `which`-based auditing.  
  **Fix**: Update each sub-command header to `v0.4.0 <12may2026>` (authored at that revision, unchanged today) — or `v0.5.0 <15may2026>` if policy is to align all files to the release date.

- **[P2.2]** [cg-code-quality] `docs/site/get-started.qmd:37`, `docs/site/index.qmd:13`, `docs/site/reference.qmd:95`, `docs/site/changelog.qmd:31`, `docs/site/articles/caveats.qmd:94` — five Quarto pages still reference `v4.0` as the current public version.  
  **Why**: Users installing from GitHub will see `which do2screen` report `0.5.0` but all documentation pages say `4.0` — direct contradiction.  
  **Fix**: Replace `v4.0` → `v0.5.0` (and `v3.x` → `v0.3.x`) across all five pages.

### P3 — MINOR

- **[P3.1]** [cg-code-quality] `do2screen.ado:16` — internal block comment reads `-- v4.0 modular rewrite`; `v4.0` is no longer a recognized tag in the 0.x history.  
  **Why**: Stale label inconsistent with the 0.x scheme.  
  **Fix**: Change to `-- v0.4.0 modular rewrite`.

- **[P3.2]** [cg-code-quality] `do2screen.sthlp:275` — "Versions 3.x and earlier supported Stata 14+" references a version series that does not exist under the 0.x numbering.  
  **Why**: `v3.x` is a phantom label under the 0.x scheme.  
  **Fix**: Change to `v0.3.x and earlier`.

### ✅ Passed
- cg-testing: All five prior fixes confirmed in place. No issues found.
