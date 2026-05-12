---
date: 2026-05-12
depth: light
parent-review: .cg-docs/reviews/2026-05-12-tested-modular-baseline-v2-thorough-review.md
type: verification
findings:
  P1.1: fixed
  P2.1: fixed
  P2.2: fixed
  P2.3: fixed
  P2.4: fixed
  P3.1: fixed
  P3.2: fixed
---

## Review Report

**Review depth**: light (mode:verify)
**Parent review**: `.cg-docs/reviews/2026-05-12-tested-modular-baseline-v2-thorough-review.md`
**Prior verify review**: `.cg-docs/reviews/2026-05-12-tested-modular-baseline-v2-thorough-verify-review.md` (10 findings, all fixed/skipped)
**Files reviewed**: `_do2screen_find.ado`, `_do2screen_range.ado`, `_do2screen_return.ado`, `_do2screen_vartrack.ado`, `tests/run_tests.do`, `tests/capture_golden.do`
**Findings**: 7 (P0: 0, P1: 1, P2: 4, P3: 2)

---

### P1 — CRITICAL (must fix before merge)

- **[P1.1]** [cg-code-quality] `_do2screen_return.ado:~74` — Cross-file regression: dedup fix breaks `variable` column attribution for `var(x x)` calls.
  **Why**: `_do2screen_return` receives the raw *original* `variables` macro from `do2screen.ado` (`"income income"` when the user passes `var(income income)`). The attribution guard introduced in verify-P1.1 is `if wordcount(`"`variables'"') == 1`, which evaluates to `2` for duplicated inputs — so `_attrvar` stays `""` and `_fr_do2screen.variable` is all-empty. Text output matches the golden (test 1.16 passes), but the structured return frame silently loses variable attribution for any duplicated-input call. The interaction between the vartrack dedup (done internally, original string never normalised at the call site) and the return attribution is a cross-file regression.
  **Fix**: Normalise the variable list at the top of the `variables` block in `_do2screen_return.ado`, before the `wordcount` check:
  ```stata
  * normalise to post-dedup count for single-var detection
  local variables: list uniq variables
  ```
  `list uniq` is correct here (sorting is irrelevant since only the count and single-name extraction matter). Alternatively, normalise `variables` in `do2screen.ado` before both dispatches (vartrack and return).

---

### P2 — IMPORTANT (should fix)

- **[P2.1]** [cg-code-quality + cg-testing] `tests/run_tests.do:~332` + `tests/capture_golden.do` — Test 4.5 (`range_eof_cap`) checks only `_rc == 0`; content is never validated.
  **Why**: The cap may produce phantom line numbers in the section footer or an off-by-one on the reported end — both would go undetected. No golden file for this case exists in `capture_golden.do`.
  **Fix**: Add a golden capture in `capture_golden.do` and an `assert_output_match` in run_tests.do:
  ```stata
  * capture_golden.do — after section 4.4:
  capture noisily ///
      do2screen using "`expath'/ex_gen_replace.do", ///
          range(1 9999) text("`tmp'_range_eof_cap") replace
  local rc1 = _rc
  shell copy "`tmp'_range_eof_cap.txt" "`goldback'\range_eof_cap.txt"
  if `rc1' == 0 local ++n_ok
  else           local ++n_fail

  * run_tests.do — replace the existing rc-only block:
  capture do2screen using "`expath'/ex_gen_replace.do", ///
      range(1 9999) text("`tmp'_range_eof_cap") replace
  if _rc != 0 {
      display as error "FAIL: range_eof_cap raised rc=`_rc'"
      scalar tests_failed = tests_failed + 1
  }
  else {
      scalar tests_ok = tests_ok + 1
      assert_output_match , outfile("`tmp'_range_eof_cap.txt") ///
          goldenfile("`golden'/range_eof_cap.txt") testname("range_eof_cap")
  }
  ```

- **[P2.2]** [cg-testing] `_do2screen_find.ado:~43` — Find-mode scalar is reset (`scalar \`scalarname' = ""`) inside the `foreach fline of local nlines` loop. For any find term with multiple matches, the scalar is wiped at each match and holds only the last section. Golden tests encode this truncated-last-section behaviour.
  **Why**: A caller expecting `s_varcode` to hold the full search results gets only the final matched section. No test exercises a multi-match scalar accumulation check; the golden captures the bug as the baseline. If this is unintentional, it requires both a code fix and golden regeneration.
  **Fix (option A — fix the bug)**: Move scalar initialisation to before the `foreach fline` loop:
  ```stata
  scalar `scalarname' = ""    // ← here, before foreach fline
  foreach fline of local nlines {
      local ++section
      foreach i of numlist 0/`lines' {
          ...
          scalar `scalarname' = `scalarname' + `"..."'
      }
      noi disp in y `scalarname'
      ...
  }
  ```
  **Fix (option B — if last-section-only is intentional)**: Add a comment and a specific test asserting last-section semantics:
  ```stata
  * NOTE: scalar reset per section; holds last section only (by design).
  scalar `scalarname' = ""
  ```

- **[P2.3]** [cg-testing] `tests/run_tests.do:~179` — Dedup test 1.16 only exercises adjacent duplicates (`var(income income)`). Non-adjacent duplicates (`var(income wages income)`) are not covered.
  **Why**: The dedup loop uses `: list _v in _vars_dedup'` which handles both adjacent and non-adjacent, but only the adjacent case is tested. A regression in non-adjacent handling would pass test 1.16 undetected.
  **Fix**: Add test 1.17 to `run_tests.do` and a corresponding capture in `capture_golden.do`. The golden for `var(income wages)` (two-variable, no duplicates) can serve as the reference:
  ```stata
  * 1.17 dedup -- var(income wages income) must equal var(income wages)
  do2screen using "`expath'/ex_gen_replace.do", ///
      var(income wages income) text("`tmp'_var_income_wages_dedup") replace
  assert_output_match , outfile("`tmp'_var_income_wages_dedup.txt") ///
      goldenfile("`golden'/var_wages.txt") testname("var_income_wages_dedup")
  ```
  Note: `var_wages.txt` was captured with `var(wages)` alone (single-var); the golden for `var(income wages)` is `var_income_wages.txt` and does not yet exist — it would need to be added to `capture_golden.do`.

- **[P2.4]** [cg-code-quality] `_do2screen_find.ado:13` — The TODO comment does not warn that resolving it requires regenerating all find-mode golden files.
  **Why**: When the TODO is eventually fixed (add `char(10)` separator, switch to per-line `noi disp`), all `find_*.txt` golden files must be regenerated. Without the warning, a developer fixing the TODO may not know to also run `capture_golden.do`, causing all find-mode tests to falsely fail against the stale-but-correct golden output.
  **Fix**: Extend the comment:
  ```stata
  * TODO: line separator for scalar output (same pattern as vartrack)
  *       When fixed: regenerate ALL find-mode golden files (find_*.txt).
  ```

---

### P3 — MINOR (nice to have)

- **[P3.1]** [cg-code-quality] `_do2screen_return.ado:~79` — Comment `"single variable was requested"` is inaccurate; the condition tests `wordcount` of the raw unparsed macro, not post-dedup count of variables actually processed.
  **Why**: After P1.1 is fixed the comment will be technically correct again, but currently it misleads a reader into thinking the check is about processing semantics.
  **Fix**: Update comment to `"single token in variables() option (normalised above)"` after applying P1.1.

- **[P3.2]** [cg-testing] `tests/capture_golden.do:17` / `tests/run_tests.do:22` — `set linesize 200` is set but not asserted; golden files silently diverge if a developer regenerates under a different linesize.
  **Why**: No guard prevents mismatched regeneration. A `200`-line capture file compared against a `120`-line session file will produce checksum mismatches that are hard to diagnose.
  **Fix**: Add an assertion immediately after the `set linesize 200` statement in both files:
  ```stata
  set linesize 200
  assert c(linesize) == 200
  ```

---

### ✅ Passed

- verify-P1.1: `variable` column populated for single-var mode — ✅ `_attrvar` logic present and correct for non-dedup case
- verify-P1.2: Range end cap in `_do2screen_return` — ✅ `min(\`end', r(max))` with `!missing` guard 
- verify-P1.3: Scalar drops before scalarname tests — ✅ `capture scalar drop my_find_sc` and `my_range_sc` present
- verify-P1.4: `crlf` removed from find scalar accumulation — ✅ no `crlf` reference; TODO present
- verify-P2.1: Order-preserving dedup in `_do2screen_vartrack` — ✅ `foreach` with `: list _v in _vars_dedup'`
- verify-P2.2: Empty-frame guard in `_do2screen_range` — ✅ `if r(N) == 0` early exit before `min()` cap
- verify-P2.4: Dedup test 1.16 — ✅ added; adjacent-duplicate case covered
- `set linesize 200` symmetry — ✅ both `capture_golden.do` and `run_tests.do` set identically; no masking risk
- P2.16: `set varabbrev off` — ✅ present in all changed test files
- P3.5: `*!` version comment convention — ✅ present in all changed `.ado` files
