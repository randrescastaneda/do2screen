---
date: 2026-05-12
depth: light
parent-review: .cg-docs/reviews/2026-05-12-tested-modular-baseline-v2-thorough-review.md
type: verification
findings:
  P1.1: fixed
  P1.2: fixed
  P1.3: fixed
  P1.4: fixed
  P2.1: fixed
  P2.2: fixed
  P2.3: fixed
  P2.4: fixed
  P3.1: fixed
  P3.2: skipped
---

## Review Report

**Review depth**: light (mode:verify)
**Parent review**: `.cg-docs/reviews/2026-05-12-tested-modular-baseline-v2-thorough-review.md` (21 fixed findings)
**Files reviewed**: all 9 `.ado` files + `tests/run_tests.do`
**Findings**: 10 (P0: 0, P1: 4, P2: 4, P3: 2)

---

### P1 — CRITICAL (must fix before merge)

- **[P1.1]** [cg-code-quality + cg-testing] `_do2screen_return.ado:17,74-83` — `variables(string)` accepted in `syntax` (P1.16 fix) but **never used** — the `variable` column in `_fr_do2screen` is hard-coded to `("")` on every `frame post`.
  **Why**: P1.16 wired the argument at the call site in `do2screen.ado` but the program body never consults `` `variables' ``. Any consumer of `_fr_do2screen.variable` gets empty strings. The structured return is incomplete and misleading.
  **Fix**: In the `mode=="variables"` section-3 branch, post the owning variable name. Minimal approach: pass the per-iteration `mainvar` from the vartrack loop's `cap noi _do2screen_return` call into the `variable` column via `frame post _fr_do2screen (`vline') (`"`vcode'"') ("`var'")`.

- **[P1.2]** [cg-code-quality] `_do2screen_return.ado:32-33` — Range mode receives the **uncapped** `end` from the dispatcher; the `min(\`end', r(max))` cap in `_do2screen_range` is local and never propagated back.
  **Why**: With `range(9 15)` on a 12-line file, `_do2screen_range` displays lines 9–12 correctly, but `_do2screen_return` is called with `end(15)`, builds `numlist "9/15"`, sets `r(nlines)=7`, and posts rows 13–15 with `code[13..15]=""` (nonexistent rows expand to empty string). The structured return has inflated `r(nlines)` and ghost empty rows.
  **Fix**: Replicate the cap inside `_do2screen_return`'s range branch before the numlist:
  ```stata
  frame _fr_do2screen_parsed: sum oriline, meanonly
  if !missing(r(max)) local end = min(`end', r(max))
  ```

- **[P1.3]** [cg-testing] `tests/run_tests.do:211,261` — Tests 2.8 and 3.5 (scalarname verification) do not drop `my_find_sc` / `my_range_sc` before the invocation. On any re-run, `capture confirm scalar my_find_sc` passes even if the new call never wrote the scalar — masking a regression.
  **Why**: Test 1.6 was correctly hardened with `capture scalar drop s_varcode` (P2.3 fix) but the identical pattern was not applied to the two analogous tests.
  **Fix**:
  ```stata
  * Before test 2.8:
  capture scalar drop my_find_sc
  * Before test 3.5:
  capture scalar drop my_range_sc
  ```

- **[P1.4]** [cg-code-quality] `_do2screen_find.ado:~34` — `local crlf` is referenced but never defined; `crlf` expands to `""`, so find-mode scalar output is an undelimited blob with no line separators.
  **Why**: Pre-existing open finding P0.1 — not fixed. Reported per P0/P1 always-report policy.
  **Fix** (manual): Refactor scalar accumulation in `_do2screen_find` to use `noi disp` per line, then regenerate all `find_*` golden files.

---

### P2 — IMPORTANT (should fix)

- **[P2.1]** [cg-code-quality] `_do2screen_vartrack.ado:23` — `local variables: list uniq variables` sorts alphabetically in addition to deduplicating.
  **Why**: Stata's `list uniq` sorts. `variables(wages income)` silently becomes `income wages`, overriding user-specified order. P2.15 intended deduplication only.
  **Fix**: Replace with an order-preserving dedup:
  ```stata
  local vars_dedup ""
  foreach _v of local variables {
      if !`: list _v in vars_dedup' local vars_dedup "`vars_dedup' `_v'"
  }
  local variables = strtrim("`vars_dedup'")
  ```

- **[P2.2]** [cg-code-quality] `_do2screen_range.ado:13` — `min(\`end', r(max))` is a no-op when the frame is empty (`r(max) = .`).
  **Why**: Stata evaluates `.` as `+∞`, so `min(end, .) = end`. For empty files the foreach loop iterates the full user range, posting empty lines.
  **Fix**:
  ```stata
  if r(N) == 0 {
      noi disp as text "(no lines to display)"
      exit
  }
  local end = min(`end', r(max))
  ```

- **[P2.3]** [cg-testing] `tests/run_tests.do` — No test for range-end capping (P2.13 new code path, zero regression coverage).
  **Why**: If `r(max)` is mis-sourced the cap fails silently with no test to catch it.
  **Fix**: Add a test with `range(1 9999)` asserting `_rc == 0` and output matches a golden file.

- **[P2.4]** [cg-testing] `tests/run_tests.do` — No test for `list uniq` deduplication (P2.15 new behaviour, zero coverage).
  **Why**: `var(income income)` should produce identical output to `var(income)` after dedup.
  **Fix**: Add a test calling `var(income income)` and assert it matches `var_income` golden file.

---

### P3 — MINOR (nice to have)

- **[P3.1]** [cg-code-quality] `_do2screen_find.ado:~8` — Multi-line `NOTE:` block referencing `P0.1 [manual]` and `.cg-docs/` paths is a review-tracking artefact in production source.
  **Why**: Shipping `.ado` files should not embed internal review IDs.
  **Fix**: Replace with `* TODO: crlf separator not defined; scalar output is undelimited pending find-mode refactor`.

- **[P3.2]** [cg-testing] `tests/run_tests.do` — Overflow guard (P1.6, `error 498` at `i>999`) has no test.
  **Why**: Without a test, the guard threshold can silently detach from the matrix `D` dimension during future refactors.
  **Fix**: Add a synthetic test with a deeply nested chain asserting `_rc == 498`.

---

### ✅ Passed

- cg-code-quality: P1.1 cap→cap noi — correct; no excess output in error paths.
- cg-code-quality: P1.6 overflow guard — code correct; fires at i>999 before matrix bounds exceeded.
- cg-code-quality: P1.13 range validation — `start < 1` and `start > end` guards correct.
- cg-code-quality: P2.8 syntax statement — `_do2screen_delimit` correctly rejects arguments.
- cg-code-quality: P2.9 frame drop — `cap frame drop _fr_do2screen_parsed` in correct position.
- cg-code-quality: P3.1/P3.2/P3.3 vartrack renames — daughter/eqvars/sentinel changes are clean.
- cg-code-quality: P3.5 `*!` convention — all 8 modules consistent.
- cg-testing: 32/32 tests green after golden regen; test structure sound.
- cg-testing: P2.3 scalar drop (test 1.6) — correctly guards s_varcode residual state.
- cg-testing: P3.6 adopath guards — no duplicate path injection on re-run.
