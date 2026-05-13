---
date: 2026-05-12
plan: .cg-docs/plans/2026-05-12-tested-modular-baseline-v2.md
depth: standard
findings:
  P0.1: open
  P0.2: open
  P1.1: open
  P1.2: open
  P1.3: open
  P1.4: open
  P1.5: open
  P1.6: open
  P1.7: open
  P1.8: open
  P2.1: open
  P2.2: open
  P2.3: open
  P2.4: open
  P2.5: open
  P2.6: open
  P2.7: open
  P2.8: open
  P2.9: open
  P2.10: open
  P2.11: open
  P2.12: open
  P3.1: open
  P3.2: open
  P3.3: open
  P3.4: open
  P3.5: open
  P3.6: open
  P3.7: open
  P3.8: open
---

## Review Report

**Review depth**: standard  
**Branch**: `refactor/tested-modular-baseline`  
**Files reviewed**: 19 source/test files (9 `.ado` files, `tests/run_tests.do`, `tests/capture_golden.do`, `tests/helpers/assert_output_match.ado`, 8 `tests/examples/*.do`, `docs/supported-syntax.md`, `README.md`, `.gitattributes`)  
**Findings**: 30 (P0: 2, P1: 8, P2: 12, P3: 8)

---

### P0 — BLOCKING (immediate remediation required)

- **[P0.1]** [cg-code-quality / cg-data-quality / cg-architecture] `_do2screen_find.ado`:12–13 — `crlf` is never defined; the NOTE comment rationalises a bug.  
  **Why**: Every scalar accumulation line is `` `"`crlf'`space'..." `` — when `crlf` is empty the scalar becomes one unbroken string with all lines concatenated without separators. The `noi disp` display looks correct only because Stata's display engine handles it differently from how callers read the scalar value. `_do2screen_vartrack` and `_do2screen_range` both define `local crlf` correctly; `_do2screen_find` is the only mode missing it.  
  **Fix**: Add `local crlf "`=char(10)'`=char(13)'"` immediately after the `scalarname` default on line 13. Remove the misleading NOTE comment.

- **[P0.2]** [cg-code-quality] `_do2screen_parse.ado`:~66 — single-pass forward-fill of `open1`/`close1` silently fails for multi-line block comments with 3+ lines.  
  **Why**: `replace `open1' = `open1'[_n-1] if `open1' == .` executes exactly once. If three or more consecutive lines fall inside a `/* ... */` block, only the first missing observation inherits the cumulative open-count; the rest stay `.`. The `inrange()` blanking step then misses those lines and comment text leaks into `precode`. Any do-file with a 3+-line block comment will have comment content incorrectly retained in parsing.  
  **Fix**: Wrap both forward-fill `replace` statements in a convergence loop:
  ```stata
  local changed = 1
  while `changed' {
      count if `open1' == . & _n > 1
      local changed = r(N)
      replace `open1' = `open1'[_n-1] if `open1' == .
  }
  ```
  Apply the same pattern to `close1`.

---

### P1 — CRITICAL (must fix before merge)

- **[P1.1]** [cg-code-quality / cg-architecture] `do2screen.ado`:~138 — `cap _do2screen_return` silently swallows all errors from the return program.  
  **Why**: If `_do2screen_return` fails (frame creation error, matrix overflow, missing column), the caller gets stale `r()` results from a prior call or silently empty results, with no diagnostic. All three mode call-sites use bare `cap`. The mode-dispatch calls use `cap noi` correctly; only the return calls do not.  
  **Fix**: Replace all three `cap _do2screen_return` with `cap noi _do2screen_return`. Optionally add `if _rc { noi disp as error "Warning: return phase failed (rc=`=_rc'). r() results unavailable." }`.

- **[P1.2]** [cg-code-quality] `_do2screen_aftervar.ado`:~42 — foreach loop-close scanner stops at the first `}` regardless of nesting depth; no upper-bound guard against unclosed braces.  
  **Why**: `while (`inloop' == 0)` sets `inloop = 1` on the very first `}` encountered. A nested `foreach` body (outer loop iterating variables, inner loop summing scores) terminates at the inner `}`, excluding lines between inner and outer closing braces. Also: no `_N` bound guard — a do-file with an unclosed `{` causes an infinite loop.  
  **Fix**: Use a depth counter and an upper-bound guard:
  ```stata
  local depth = 1
  while (`depth' > 0) {
      local ++j
      if (`loopstart' + `j' > _N) continue, break  // guard: unclosed {
      local loopline: disp code[`=`loopstart' + `j'']
      if regexm(`"`macval(loopline)'"', `"^[ ]*foreach.*{$"') local ++depth
      if regexm(`"`macval(loopline)'"', `"}"') local --depth
      replace selection = 1 in `=`loopstart' + `j''
  }
  ```

- **[P1.3]** [cg-testing] `do2screen.ado`:~164 and `_do2screen_find.ado`/`_do2screen_range.ado` — `nolinenumbers` option is forwarded only to `_do2screen_vartrack`; never passed to find or range modes, which do not accept it.  
  **Why**: `do2screen … find(…) nolinenumbers` silently ignores the option. Neither code nor tests catch this gap.  
  **Fix**: (a) Add `[nolinenumbers]` to the `syntax` of `_do2screen_find` and `_do2screen_range`, implement the suppression, and pass `` `linenumbers' `` from the dispatcher. (b) Add at least one golden-file test per mode using `nolinenumbers`.

- **[P1.4]** [cg-architecture / cg-code-quality] `_do2screen_vartrack.ado`:~135 — `scalarname()` option silently ignored in variables mode; always writes to hardcoded `scalar s_varcode`.  
  **Why**: `do2screen.ado` resolves `scalarname` and correctly passes it to `_do2screen_find` and `_do2screen_range`, but never forwards it to `_do2screen_vartrack`. `do2screen …, variables(x) scalarname(myresult)` writes to `s_varcode`, not `myresult`. This silent contract violation is undocumented in `do2screen.sthlp`.  
  **Fix**: Add `[SCALARname(string)]` to `_do2screen_vartrack`'s `syntax`, default to `s_varcode`, pass `scalarname(`scalarname')` from the dispatcher, and replace both `scalar s_varcode` references in the program with `scalar `scalarname'`.

- **[P1.5]** [cg-reproducibility] `do2screen.ado`:~83–202 — `cd` to `folder` is not restored if `_do2screen_display` or `_do2screen_delimit` errors.  
  **Why**: `cd "`folder'"` runs at line ~83. The restore `cd "`cdir'"` only runs if execution reaches the end of the `qui` block. `_do2screen_display` and `_do2screen_delimit` run without `cap`; any error in either abandons the restore, permanently changing the caller's working directory.  
  **Fix**: Wrap `_do2screen_display` and `_do2screen_delimit` in `cap noi` (matching the pattern for `_do2screen_vartrack`/`find`/`range`), and move the `cd "`cdir'"` restore to execute unconditionally using a final `if ("`folder'" != "") { cap cd "`cdir'" }` block placed both after the foreach loop and inside each early-exit path.

- **[P1.6]** [cg-data-quality / cg-performance] `_do2screen_vartrack.ado`:~24 — the 1000-column recursion matrix `D` is an unguarded hard cap.  
  **Why**: `local ++i` is unbounded. When `i` reaches 1001, `D[1, `i']` silently returns `.` (Stata does not throw on out-of-bounds matrix reads). `word . of `prevars`var''` produces undefined behavior — silent wrong traversal rather than a clear error.  
  **Fix**: Add a guard at the top of the while loop body: `if (`i' > 999) { noi disp as error "do2screen: variable lineage exceeds 1000 levels. Use varout() to exclude an intermediate variable."; error 498 }`. Document the limit in `do2screen.sthlp`.

- **[P1.7]** [cg-documentation] `do2screen.sthlp` — version header and content still reflect v3.0.  
  **Why**: SMCL comment reads `{* 13dec2016 }`, title reads `{cmd:help for do2screen <v 3.0>}`. Users running `help do2screen` see v3.0 docs for a v4.0 package with a breaking Stata 16.1+ requirement, new `_fr_do2screen` frame return, and `scalarname()` inconsistency. Also: synopt entry `{synopt:{opt lables}}` has a typo (`lables` vs `labels`).  
  **Fix**: Update SMCL date comment to `{* 12may2026 }`, title to `{cmd:help for do2screen <v 4.0>}`, fix `lables` typo, add Stata 16.1+ requirement notice.

- **[P1.8]** [cg-documentation] `do2screen.sthlp` and `docs/supported-syntax.md` — v4.0 return values and frame absent from documentation.  
  **Why**: `_do2screen_return.ado` now populates `r(nlines)`, `r(dofile)`, `r(lines)` matrix, and creates frame `_fr_do2screen` (columns: `line`, `code`, `variable`). Neither document mentions any of these. `docs/supported-syntax.md` heading still reads "(current version 3.0)" and body describes only the scalar.  
  **Fix**: Add a `{title:Saved Results}` SMCL block to `do2screen.sthlp` documenting all three `r()` objects and the frame. Update `docs/supported-syntax.md` heading to "(version 4.0)" and add sub-sections for r-class returns and the frame.

---

### P2 — IMPORTANT (should fix)

- **[P2.1]** [cg-documentation / cg-architecture] `_do2screen_find.ado`:~33 — scalar is reset to `""` at the start of every match occurrence, so only the last match's context lines remain in the scalar after the loop.  
  **Why**: `scalar `scalarname' = ""` is inside the `foreach fline of local nlines` loop. For a search term with multiple matches, each iteration overwrites the prior. `docs/supported-syntax.md` implies the scalar holds all selected lines.  
  **Fix**: Move `scalar `scalarname' = ""` to before the `foreach fline` loop to accumulate across occurrences. Or explicitly document the per-occurrence behavior if intentional.

- **[P2.2]** [cg-version-control] `.gitattributes` — no `* text=auto` fallback rule.  
  **Why**: `.md`, `.json`, and other text files not explicitly listed receive no line-ending normalization. On Windows these can be committed with CRLF, causing cross-platform diff noise for non-Windows collaborators.  
  **Fix**: Add `* text=auto` as the first line, before all explicit overrides.

- **[P2.3]** [cg-testing] `tests/run_tests.do`:~112 — the `s_varcode` existence check in test 1.6 is permanently vacuous.  
  **Why**: `s_varcode` is set by every prior variables-mode call (tests 1.1–1.5). `confirm scalar s_varcode` always succeeds regardless of whether the scalarname inconsistency is broken or fixed.  
  **Fix**: Add `capture scalar drop s_varcode` immediately before the test 1.6 `do2screen` call to create a clean slate for that specific assertion.

- **[P2.4]** [cg-testing] `tests/run_tests.do` — `varout()` option has zero test coverage.  
  **Why**: The entire exclusion branch in `_do2screen_vartrack.ado` is unexercised; a regression would ship silently.  
  **Fix**: Add a test with `var(hhincome) varout(income)` on `ex_gen_replace.do` and a golden file confirming `income`'s lineage block is absent.

- **[P2.5]** [cg-testing] `tests/run_tests.do` — `comments` option has zero test coverage.  
  **Why**: The `comments` flag disables all block-comment stripping — a major code path in `_do2screen_parse.ado`. A regression would be undetected.  
  **Fix**: Add a test: `do2screen using ex_comments_delimit.do, var(longvar) comments text(...) replace` with a golden file whose output differs from the baseline `longvar` test.

- **[P2.6]** [cg-testing] `tests/run_tests.do` — multi-variable `var(v1 v2)` invocation has zero test coverage.  
  **Why**: The `foreach var of local variables` loop is never exercised with more than one variable; cross-variable deduplication and ordering are untested.  
  **Fix**: Add a test with `var(wages income)` on `ex_gen_replace.do` and a golden file.

- **[P2.7]** [cg-testing] `tests/run_tests.do` — `folder()` option and the no-`using` directory-scan mode are entirely untested.  
  **Why**: The `cd "`folder'"` / `dir . files "*.do"` / `cd "`cdir'"` path is unexercised. A regression in path normalization or `cd` restore would be invisible.  
  **Fix**: Add an integration test calling `do2screen, folder("`expath'") find("income") text(...) replace` (no `using`) asserting at least one match across the example files.

- **[P2.8]** [cg-architecture] `_do2screen_delimit.ado` — no `syntax` statement.  
  **Why**: Without `syntax`, the program silently ignores accidentally passed arguments. The zero-argument contract and frame dependency are invisible to callers.  
  **Fix**: Add `syntax  // takes no arguments; operates on _fr_do2screen_parsed` at the top of the program.

- **[P2.9]** [cg-architecture] `do2screen.ado` — `_fr_do2screen_parsed` is never dropped after a successful run; persists in the user's session.  
  **Why**: The frame lingers with quote-handle-mangled code, is visible in `frame dir`, and consumes memory. This is undocumented. (It is cleaned up at the start of the next `do2screen` call, but not after the last one.)  
  **Fix**: At the end of `do2screen.ado`, after the `foreach dofile` loop completes, add `cap frame drop _fr_do2screen_parsed`. Or add a `keepframe` option and document the intentional keep for debugging.

- **[P2.10]** [cg-performance] `_do2screen_vartrack.ado` (inside the `while` loop) — `tempvar a` and `gen `a' = ""` declared inside the while loop body; K columns accumulate per variable invocation.  
  **Why**: Each iteration appends a new column to `_fr_do2screen_parsed`. At worst-case depth, the frame accumulates hundreds of columns O(N × depth), with increasing `replace` scan cost per iteration.  
  **Fix**: Hoist `tempvar a` and `gen `a' = ""` outside the while loop. Use `replace `a' = ""` at the top of each iteration (vectorized reset) instead of re-generating the column.

- **[P2.11]** [cg-performance] `_do2screen_parse.ado`:~75 — inline `/* */` stripping loop uses `regexr` (removes only the leftmost match per cell per call), creating O(N × K) passes.  
  **Why**: `regexr` removes one match per cell per iteration. A line with two inline block comments (e.g., `a /* x */ b /* y */ c`) requires two full-dataset passes. Files with dense annotation are slow.  
  **Fix**: Replace `regexr` with `ustrregexra` (replaces all matches globally per cell): `replace precode = ustrregexra(precode, "/\*[^*/]*\*/", " ")`. A single vectorized pass eliminates all inline `/* */` simultaneously, collapsing the while loop to at most one iteration.

- **[P2.12]** [cg-documentation] `README.md` — single-paragraph stub with no version requirements, no changelog, no v4.0 changes.  
  **Why**: No mention of Stata 16.1+ requirement (breaking from v3), no note that `lstrfun` was dropped, no reference to `_fr_do2screen` frame return, no link to `docs/supported-syntax.md`.  
  **Fix**: Add at minimum: a v4.0 changelog entry; "requires Stata 16.1+"; "lstrfun dependency removed"; brief description of `_fr_do2screen` frame; link to `docs/supported-syntax.md`.

---

### P3 — MINOR (nice to have)

- **[P3.1]** [cg-code-quality] `_do2screen_vartrack.ado` throughout — typo: `doughter` should be `daughter`.  
  **Why**: Used ~6 times for the local macro tracking parent-child variable relationships. Degrades readability and will propagate if copied.  
  **Fix**: Rename `doughter` → `daughter` (or `_daughter` to signal internal bookkeeping) throughout the file.

- **[P3.2]** [cg-data-quality] `_do2screen_vartrack.ado`:~155 — `eqvars` flag is dead code.  
  **Why**: `local eqvars = 0` is initialised and `local eqvars = 1` is set when a self-reference is detected, but `eqvars` is never read or acted upon.  
  **Fix**: Remove `eqvars` and its initialisation; or implement the intended behavior (e.g., emit a note that the variable is updated in-place).

- **[P3.3]** [cg-data-quality] `_do2screen_vartrack.ado`:~40 — `"nope"` used as a sentinel for "no parent variable" could collide with a real variable named `nope`.  
  **Why**: The circular-reference guard `if "`var'" == "`doughter`var''"` fires when `doughter`var'' == "nope"` — which is the initial state. A do-file that creates a variable named `nope` would incorrectly trigger the guard.  
  **Fix**: Replace with a sentinel that cannot be a valid Stata variable name, e.g., `"__no_parent__"`.

- **[P3.4]** [cg-documentation] `_do2screen_vartrack.ado` — no comment explaining the depth-first traversal state machine.  
  **Why**: The roles of matrix `D`, `prevars`var'`, and `doughter`var'' require careful reverse-engineering without documentation.  
  **Fix**: Add a ~6-line block comment above `local stay = 1` describing: `D[1,i]` = word-index at depth i; `prevars`var'' = candidate parent names at current level; `doughter`var'' = the child that introduced `var` as a parent.

- **[P3.5]** [cg-documentation] All 8 `_do2screen_*.ado` helper files — `*!` version line convention is wrong.  
  **Why**: Stata's `which` displays only the first `*!` line. Currently the description is on line 1 and version/date on line 2. `which _do2screen_parse` shows no version or date.  
  **Fix**: Merge version/date onto line 1: e.g., `*! _do2screen_parse v4.0 <12may2026>  R.Andres Castaneda`, and move the description to line 2.

- **[P3.6]** [cg-reproducibility] `tests/run_tests.do`:54,60 — `adopath ++` accumulates across repeated runs in the same Stata session.  
  **Why**: Each execution appends both `tests/helpers` and the project root to adopath again. After multiple runs both paths appear multiple times, degrading program-search performance.  
  **Fix**: Guard each `adopath ++` with a `capture which` check; only add the path if the target program is not yet findable.

- **[P3.7]** [cg-reproducibility] `do2screen.ado`:~108 — `dir . files "*.do"` file order is OS-dependent.  
  **Why**: Windows returns alphabetical order; macOS/Linux use filesystem-insertion order. Users processing a folder without `using` see non-reproducible output ordering across platforms.  
  **Fix**: Sort: `local dofiles: list sort dofiles` (available since Stata 10; lexicographically stable across platforms).

- **[P3.8]** [cg-documentation] `do2screen.sthlp`:~20 — `lrep`, `rrep`, `dblq` synopt entries lack `(string)` type annotation.  
  **Why**: `{synopt:{opt lrep}}` implies a switch option. Users cannot tell these take values.  
  **Fix**: Change to `{synopt:{opt lrep(string)}}`, `{synopt:{opt rrep(string)}}`, `{synopt:{opt dblq(string)}}`.

---

### ✅ Passed

- **cg-code-quality**: No `*` mid-line comments; no `global` macros; `tempvar`/`tempname`/`tempfile` used correctly; `version 16.1` present in all `.ado` files; `local` over `global` consistent; `syntax` (not `args`) used for argument parsing.
- **cg-version-control**: No secrets or credentials in changed files; `.cg-docs/` files correctly committed (institutional knowledge rule satisfied); `compound-gpid.local.md` correctly gitignored; golden `.txt` files correctly committed as test fixtures; branch naming follows `type/description`; all unpushed commits use `type(scope): description` format; no large binaries committed.
- **cg-reproducibility**: No external package dependencies — `repado` lockfile not required; no random processes — `set seed` not required; `version 16.1` present in all `.ado` files.
- **cg-performance**: Frame-level communication is appropriate for a single-threaded Stata package; typical do-file sizes (50–300 lines) keep all operations within acceptable bounds for interactive use; `_do2screen_return` row-by-row `frame post` is acceptable at typical selection sizes.
- **cg-data-quality**: `tempfile`/`tempvar` used correctly; `levelsof` / `strpos` vectorized operations are appropriate; `import delimited` with unique delimiter is sound for typical Stata source code.

