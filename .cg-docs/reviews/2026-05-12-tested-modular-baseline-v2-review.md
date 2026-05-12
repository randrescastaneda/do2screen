---
date: 2026-05-12
plan: .cg-docs/plans/2026-05-12-tested-modular-baseline-v2.md
depth: standard
mode: autofix
findings:
  P1.1: open
  P2.1: fixed
  P2.2: fixed
  P2.3: open
  P2.4: fixed
  P2.5: fixed
  P3.1: fixed
  P3.2: open
  P3.3: open
---

## Review Report

**Review depth**: standard (mode:autofix)
**Files reviewed**: 12 source files (tests/run_tests.do, tests/capture_golden.do, tests/helpers/assert_output_match.ado, 8 tests/examples/*.do, docs/supported-syntax.md)
**Findings**: 9 (P0: 0, P1: 1, P2: 5, P3: 3)

---

### P1 — CRITICAL (must fix before merge)

- **[P1.1]** [cg-reproducibility] tests/run_tests.do:22, tests/capture_golden.do:25 — Hardcoded absolute user path `c:/Users/wb384996/OneDrive - WBG/...`
  **Why**: Test suite is completely non-functional on any other machine. `[manual]`
  **Fix**: Use `c(sysdir_personal)`, `reproot`, or detect the path dynamically via a project root sentinel file.

### P2 — IMPORTANT (should fix)

- **[P2.1]** [cg-version-control] .gitattributes — No `.gitattributes` file. Git warned at commit time that all `tests/golden/*.txt` files will have LF→CRLF applied on Windows checkout.
  **Why**: `checksum` is byte-exact — a CRLF conversion silently breaks all 32 golden comparisons on any fresh clone or cross-OS checkout. `[safe_auto]` ✅ **FIXED**

- **[P2.2]** [cg-testing] tests/run_tests.do — `tests_ok` counter was broken: tracked as local, not incremented inside `assert_output_match`, so the final "Passed:" count was always wrong.
  **Why**: Misleading summary conceals which tests passed after a failure. `[safe_auto]` ✅ **FIXED** (`tests_ok` promoted to scalar, incremented in `assert_output_match`; `capture program drop` added for reliable ado reload)

- **[P2.3]** [cg-version-control] tests/golden/shell_test.txt, tests/golden/test_write.txt — Two debugging artifact files committed to `tests/golden/`. Not referenced by any test.
  **Why**: Pollutes the golden directory; `capture_golden.do` lists them as test outputs. `[manual]`
  **Fix**: Delete both files (`git rm tests/golden/shell_test.txt tests/golden/test_write.txt`).

- **[P2.4]** [cg-code-quality] tests/run_tests.do:16 — Missing `set more off` and `set varabbrev off`.
  **Why**: Without `set more off`, runner pauses for `--more--` in batch. Without `set varabbrev off`, variable abbreviation could silently match wrong variables. `[safe_auto]` ✅ **FIXED**

- **[P2.5]** [cg-code-quality] tests/helpers/assert_output_match.ado:10 — Missing `version` statement.
  **Why**: Per best practices, every ado-file must declare a version for reproducible parsing. `[safe_auto]` ✅ **FIXED** (`version 16.1` added)

### P3 — MINOR (nice to have)

- **[P3.1]** [cg-code-quality] tests/capture_golden.do — Missing `set more off`.
  **Why**: Same batch-mode concern as P2.4. `[safe_auto]` ✅ **FIXED**

- **[P3.2]** [cg-documentation] tests/run_tests.do — No documentation on how to add new test cases or extend the suite.
  **Why**: Onboarding friction. `[advisory]`
  **Fix**: Add a comment block in header describing the 3-step process (add example do-file, run `capture_golden.do`, add assertion call).

- **[P3.3]** [cg-reproducibility] tests/run_tests.do:29 — `adopath +` is additive; running the suite twice in a session accumulates duplicate entries.
  **Why**: Harmless in practice but clutters `adopath` output. `[advisory]`
  **Fix**: Use `adopath ++ path` (no-duplicate form).

### ✅ Passed

- cg-architecture: Test structure (examples/, golden/, helpers/) is sound and mirrors the plan.
- cg-data-quality: Golden files are text output — no welfare/calculation risk. Checksum comparison is byte-exact.
- cg-performance: 32 sequential do2screen + checksum calls is appropriate for the scope.

---

## Autofix Summary

Applied 5 safe_auto fixes (commit `a453a6e`):

| Finding | Fix | Files changed |
|---------|-----|---------------|
| P2.1 | Created `.gitattributes` with LF enforcement | `.gitattributes` |
| P2.2 | Promoted `tests_ok` to scalar; incremented in `assert_output_match` | `run_tests.do`, `assert_output_match.ado` |
| P2.4 | Added `set more off` + `set varabbrev off` + `capture program drop` | `run_tests.do` |
| P2.5 | Added `version 16.1` | `assert_output_match.ado` |
| P3.1 | Added `set more off` | `capture_golden.do` |

Post-fix test result: **32/32 pass**.
