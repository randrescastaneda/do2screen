---
date: 2026-05-12
depth: light
parent-review: .cg-docs/reviews/2026-05-12-tested-modular-baseline-v2-review.md
type: verification
findings:
  P2.1: fixed
  P3.1: fixed
  P3.2: fixed
---

## Review Report

**Review depth**: light (mode:verify)
**Files reviewed**: 3 primary code files (tests/run_tests.do, tests/helpers/assert_output_match.ado, tests/capture_golden.do) + .gitattributes
**Findings**: 3 (P0: 0, P1: 0, P2: 1, P3: 2)

---

### P2 — IMPORTANT (should fix)

- **[P2.1]** [cg-testing] tests/run_tests.do:87, tests/run_tests.do:219, tests/run_tests.do:257 — Bare `assert _rc == 0` for scalarname behavioural checks (tests 1.6, 2.8, 3.5) bypasses `tests_failed` accounting
  **Why**: If the scalarname scalar is not set, the bare unguarded `assert` halts `run_tests.do` with rc=9, skipping the final summary and leaving `tests_failed` at an incorrect value. Rather than a controlled FAIL message, the runner crashes mid-suite. New issue, outside scope of 9 fixed findings.
  **Fix**: Remove the bare `assert _rc == 0` lines; route failures through the scalar counter already used by error tests 4.2/4.3. Pattern:
  ```stata
  capture confirm scalar s_varcode
  if _rc != 0 {
      display as error "FAIL: s_varcode not set -- scalarname inconsistency broken"
      scalar tests_failed = tests_failed + 1
  }
  ```

### P3 — MINOR (nice to have)

- **[P3.1]** [cg-code-quality] tests/capture_golden.do:18 — Missing `set varabbrev off`
  **Why**: `run_tests.do` has `set varabbrev off` (fixed under prior P2.4) but `capture_golden.do` does not. Typos in variable names could silently match wrong variables during golden capture.
  **Fix**: Add `set varabbrev off` after `set more off` on line 18.

- **[P3.2]** [cg-testing] tests/run_tests.do — No pre-flight check for missing golden files
  **Why**: On a fresh clone where `capture_golden.do` has not been run, all 30 file-comparison tests fail with "golden file not found" with no upfront diagnostic. Advisory.
  **Fix**: Add at setup: `capture confirm file "\`golden'/var_income.txt"` with error message directing user to run `tests/capture_golden.do` first.

### Passed

- cg-code-quality: P1.1 fix (portable c(pwd) path + sentinel) correct; no regressions.
- cg-code-quality: P2.1 (.gitattributes binary for golden txt) correct.
- cg-code-quality: P2.2 (tests_ok scalar) now consistent across assert_output_match and error tests.
- cg-testing: 32-test suite structure verified; all modes exercised; no new coverage gaps.
