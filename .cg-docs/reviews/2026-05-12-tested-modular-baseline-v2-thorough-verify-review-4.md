---
date: 2026-05-12
depth: light
parent-review: .cg-docs/reviews/2026-05-12-tested-modular-baseline-v2-thorough-review.md
type: verification
findings:
  P1.1: fixed
  P2.1: fixed
---

## Verify Review Report — do2screen (verify-4)

**Date**: 2026-05-12
**Mode**: verify (pass 4 — following verify-3 fix-triage)
**Prior review**: `.cg-docs/reviews/2026-05-12-tested-modular-baseline-v2-thorough-review.md`
**Depth**: light
**Agents**: @cg-code-quality, @cg-testing
**Files reviewed**: 5
**Findings**: 2 (P0: 0, P1: 1, P2: 1) — both fixed in-session

---

### Issue Found and Fixed

**[P1.1]** [cg-testing] `tests/run_tests.do` — test 4.8 condition `missing(r(nlines))` was vacuously true in both normal and overflow cases

**Why**: `r(nlines)` is missing (`.`) after every `do2screen` call because it is set by `_do2screen_return` inside a `qui` block, and rclass results inside a calling `qui` program do not persist. The condition `missing(r(nlines))` passes regardless of whether the overflow guard fired.

**Fix applied**: Replaced the `missing(r(nlines))` assertion with a golden-file comparison on the `text()` output. The warning message `"do2screen: variable lineage exceeds 1000 levels"` is captured to a temp file and checksummed against `tests/golden/var_overflow_guard.txt`. Golden file created from a live run.

**[P2.1]** [cg-testing] `tests/capture_golden.do` — missing entry for overflow guard test

**Fix applied**: Added capture block for `var_overflow_guard` in section 4 of `capture_golden.do`, consistent with all other golden captures.

---

### ✅ All prior fixes confirmed correct

- `_do2screen_range.ado` start > _N guard: correct; `r(max)` still valid after `local end = min(...)` ✓
- `_do2screen_return.ado` frame comment: no "action" column ✓
- Tests 4.6 and 4.7: correct — `range(0 5)` and `range(15 9)` both trigger the guards in `do2screen.ado` before parsing and return rc≠0 ✓
- Test 4.8 (fixed this session): golden-file check on overflow warning message ✓

**Test result**: 39/39 ✅

---

### ℹ️ Advisory (no action required)

- Test 4.8 parses a 1001-line file and traces 999 lineage levels. Expected runtime 10–30 seconds. Cannot be shortened without reducing the guard threshold.
- `r(max)` of `oriline` in `_do2screen_range.ado` is a correct proxy for file length for the start-bounds check; gaps from stripped comment lines mean `start` values inside stripped ranges won't be caught, but the range `foreach` loop emits empty-string output in that case (cosmetic, not a crash). Below P1 threshold.
