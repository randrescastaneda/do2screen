---
plan: .cg-docs/plans/2026-05-15-documentation-website-v2.md
findings:
  P3.1: fixed
  P3.2: fixed
  P3.3: fixed
---

## Review Report

**Review depth**: standard  
**Files reviewed**: 2 (`.gitignore`, `roadmap.json`)  
**Findings**: 3 (P0: 0, P1: 0, P2: 0, P3: 3)

### P3 — MINOR (nice to have)

- **[P3.1]** [cg-documentation] `.gitignore:12` — `_site/` was not root-anchored.  
  **Why**: Unanchored gitignore directory patterns match at any depth, not just the repo root, which is broader than intended for a Quarto output directory.  
  **Fix**: Changed `_site/` → `/_site/`. `[safe_auto]` ✅ **Applied**

- **[P3.2]** [cg-version-control] `.gitignore` — `docs/site/_freeze/` not excluded.  
  **Why**: Quarto's `_freeze/` directory stores computational cache for frozen executions; if freeze is ever enabled these outputs would be committed unintentionally.  
  **Fix**: Added `docs/site/_freeze/` alongside the `.quarto/` entry. `[safe_auto]` ✅ **Applied**

- **[P3.3]** [cg-version-control] `.github/workflows/quarto-site.yml` — GitHub Actions steps pinned by mutable major-version tags (`@v4`, `@v3`, `@v2`), not by commit SHA.  
  **Why**: Mutable tags can be moved by upstream; a compromised release could execute arbitrary code in CI. Affected: `actions/checkout@v4`, `actions/upload-pages-artifact@v3`, `actions/deploy-pages@v4`, `quarto-dev/quarto-actions` steps.  
  **Fix**: Replace each tag with its full commit SHA (lookup via `gh release view` or Actions Marketplace). `[manual]`

### ✅ Passed

- cg-code-quality: No issues found
- cg-testing: No issues found
- cg-reproducibility: No issues found
- cg-performance: No issues found
- cg-architecture: No issues found (confirmed `/_site/` anchoring was the clean fix)
- cg-data-quality: No issues found
