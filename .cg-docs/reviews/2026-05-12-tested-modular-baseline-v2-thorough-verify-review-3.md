---
date: 2026-05-12
depth: light
parent-review: .cg-docs/reviews/2026-05-12-tested-modular-baseline-v2-thorough-review.md
type: verification
findings:
  P1.1: fixed
  P2.1: fixed
  P2.2: fixed
  P3.1: fixed
---

## Verify Review Report — do2screen

**Date**: 2026-05-12
**Mode**: verify (following thorough review + autofix)
**Prior review**: `.cg-docs/reviews/2026-05-12-tested-modular-baseline-v2-thorough-review.md`
**Depth**: light
**Agents**: @cg-code-quality, @cg-testing
**Files reviewed**: 13
**Findings**: 4 (P0: 0, P1: 1, P2: 2, P3: 1)

---

### ✅ Confirmed Fixes (all 20 prior fixed findings verified)

| Finding | File | Verdict |
|---------|------|---------|
| P1.1 | `do2screen.ado` | ✅ All five sub-command dispatch calls use `cap noi` |
| P1.6 | `_do2screen_vartrack.ado` | ✅ `if (\`i' > 999)` guard + `error 498` present |
| P1.7 | `do2screen.sthlp` | ✅ Version header updated; "lables" typo gone |
| P1.13 | `do2screen.ado` | ✅ `start < 1` and `start > end` both exit 198 |
| P1.16 | `do2screen.ado` | ✅ `variables(\`variables')` passed to `_do2screen_return` |
| P2.2 | `.gitattributes` | ✅ `* text=auto` present |
| P2.3 | `tests/run_tests.do` | ✅ `capture scalar drop s_varcode` precedes test 1.6 |
| P2.8 | `_do2screen_delimit.ado` | ✅ `syntax` (no arguments) is first executable line |
| P2.9 | `do2screen.ado` | ✅ `cap frame drop _fr_do2screen_parsed` at end of `qui` block |
| P2.13 | `_do2screen_range.ado` | ✅ `local end = min(\`end', r(max))` present after `sum oriline` |
| P2.15 | `_do2screen_vartrack.ado` | ✅ Order-preserving dedup loop present |
| P2.16 | `_do2screen_return.ado` | ✅ Frame create statement correct (3 columns) |
| P3.1 | `_do2screen_vartrack.ado` | ✅ All six `daughter` locals spelled correctly |
| P3.2 | `_do2screen_vartrack.ado` | ✅ No `local eqvars` anywhere in file |
| P3.3 | `_do2screen_vartrack.ado` | ✅ Sentinel is `"__no_parent__"` throughout |
| P3.5 | all 8 `_do2screen_*.ado` | ✅ All headers follow `*! _do2screen_xxx v4.0 <12may2026>` |
| P3.6 | `tests/run_tests.do` | ✅ `adopath ++` guarded for both helper and main ado paths |
| P3.7 | `do2screen.ado` | ✅ `local dofiles: list sort dofiles` present |
| P3.8 | `do2screen.sthlp` | ✅ Synopses include types: `(string)`, `(numlist min=1 max=2)`, etc. |
| P_NEW.1 | `_do2screen_return.ado` | ✅ All four `levelsof` calls prefixed with `quietly` |

---

### P1 — High

- **[P1.1]** [cg-testing] `do2screen.ado` / `_do2screen_range.ado` — `start > _N` not validated; passes silently with blank output
  **Why**: P1.13 was documented as "Range start/end validated ≥ 1 and ≤ _N". The `≥ 1` guard is present. But `start > _N` is not caught: if `range(500)` is called on a 30-line file, `start = 500` passes the `< 1` and `> end` guards, `_do2screen_range` caps `end = min(505, 30) = 30`, then the `numlist 500/30` is empty, and output is silently blank — no error, no message. This is a silent failure, not graceful handling.
  **Fix**: In `_do2screen_range.ado`, after `sum oriline, meanonly` and the `end` cap, add:
  ```stata
  local end = min(`end', r(max))
  if (`start' > r(max)) {
      noi disp as error "range(): start (`start') exceeds file length (`=r(max)')"
      exit 198
  }
  ```
  Then add a corresponding rc test in `tests/run_tests.do`.

---

### P2 — Important

- **[P2.1]** [cg-testing] `tests/run_tests.do` — No rc-assertion tests for the two P1.13 range validation error paths
  **Why**: P1.13 added `start < 1` and `start > end` guards. The test suite has rc-based tests for other bad-input cases but none verify that `range(0 5)` or `range(15 9)` return a non-zero rc. If either guard were accidentally removed, no test would catch it.
  **Fix**: Add to section 4 of `run_tests.do`:
  ```stata
  * 4.6 range start < 1 — must error
  capture do2screen using "`expath'/ex_gen_replace.do", range(0 5)
  if _rc != 0 { disp as text "PASS: range_start_lt1 (rc=`_rc')" ; scalar tests_ok = tests_ok + 1 }
  else         { disp as error "FAIL: range_start_lt1" ; scalar tests_failed = tests_failed + 1 }

  * 4.7 range start > end — must error
  capture do2screen using "`expath'/ex_gen_replace.do", range(15 9)
  if _rc != 0 { disp as text "PASS: range_start_gt_end (rc=`_rc')" ; scalar tests_ok = tests_ok + 1 }
  else         { disp as error "FAIL: range_start_gt_end" ; scalar tests_failed = tests_failed + 1 }
  ```

- **[P2.2]** [cg-testing] `tests/run_tests.do` — No test for the P1.6 `i > 999` overflow guard in `_do2screen_vartrack.ado`
  **Why**: The guard is the sole protection against infinite lineage recursion. The circular-reference test (1.14, `var(circ)`) exercises the *daughter* check — a different code path. Nothing forces `i` past 999. If the guard were broken or miscounted, no test would fail.
  **Fix**: Add a synthetic do-file `tests/examples/ex_deep_chain.do` with a 1001-level `gen` chain, then add an rc test:
  ```stata
  * 4.8 lineage depth > 999 — must error rc 498
  capture do2screen using "`expath'/ex_deep_chain.do", var(g_1001)
  if _rc == 498 { disp as text "PASS: overflow_guard (rc=498)" ; scalar tests_ok = tests_ok + 1 }
  else           { disp as error "FAIL: overflow_guard — expected rc=498, got rc=`_rc'" ; scalar tests_failed = tests_failed + 1 }
  ```

---

### P3 — Minor

- **[P3.1]** [cg-code-quality] `_do2screen_return.ado`:8 — Block comment still lists `action` as a fourth frame column
  **Why**: P2.16 fixed the `frame create` statement to 3 columns (`line`, `code`, `variable`), but the file-header comment above still reads `(columns: line, code, variable, action)`. The `action` column does not exist. Anyone reading the header to understand the frame schema is misled.
  **Fix**:
  ```stata
  *  frame _fr_do2screen  (columns: line, code, variable)
  ```

---

### ✅ Coverage confirmed (no new issues)

- P1.1 cap noi: all dispatch paths covered implicitly by the full test suite.
- P1.16 variables() passthrough: covered implicitly by all 17 golden-file comparisons.
- P2.8 syntax in delimit: not regressed (light pass).
- P2.9 frame drop on error exit: covered implicitly; cleanup line reached after cap-noi-wrapped dispatch.
- P2.13 end cap: test 4.5 (`range(1 9999)`) confirms.
- P2.15 dedup: tests 1.16 and 1.17 (`income income`, `income wages income`) confirm.
- P3.6 adopath guard: present in `run_tests.do` for both paths.
