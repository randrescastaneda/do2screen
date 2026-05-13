---
date: 2026-05-13
title: "Golden-file testing for rc=0 guards when r() results are unreliable"
category: "testing-patterns"
language: "Stata"
tags: [golden-file, testing, overflow-guard, rclass, cap-noi, text-log, assert-output-match]
root-cause: "rclass results stored inside a qui block do not persist to the caller, making r() assertions vacuously true regardless of whether a guard fired."
severity: "P1"
---

# Golden-file testing for rc=0 guards when r() results are unreliable

## Problem

A lineage overflow guard in `_do2screen_vartrack.ado` was meant to fire when
the lineage chain exceeded 999 levels, aborting with `rc=0` (caught internally
by `cap noi`) and leaving `r(nlines)` missing. The test was:

```stata
capture noisily do2screen using "...", var(g_1001)
if (_rc == 0 & missing(r(nlines))) {
    display as text "PASS: overflow_guard"
    scalar tests_ok = tests_ok + 1
}
```

This test passed **unconditionally** — in both the overflow and the non-overflow
cases — because `r(nlines)` is set by `_do2screen_return` inside a `qui` block,
and rclass results stored inside a `qui` block do not persist to the calling
context. `missing(r(nlines))` was always true.

## Root Cause

In Stata, `rclass` results from a sub-program called inside a `quietly` block
are cleared when the `qui` block exits. From the caller's perspective,
`r(nlines)` is always `.` regardless of what `_do2screen_return` stored.

More generally: **any test that asserts `r()` values from a program that runs
inside a `qui` block will be vacuously true.**

## Solution

Switch from r()-value assertion to **golden-file content comparison** using the
`text()` option and `assert_output_match`:

```stata
capture noisily do2screen using "`expath'/ex_deep_chain.do", ///
    var(g_1001) text("`tmp'_var_overflow_guard") replace
if _rc != 0 {
    display as error "FAIL: overflow_guard raised rc=`_rc'"
    scalar tests_failed = tests_failed + 1
}
else {
    assert_output_match , outfile("`tmp'_var_overflow_guard.txt") ///
        goldenfile("`golden'/var_overflow_guard.txt") testname("var_overflow_guard")
}
```

The golden file contains the specific warning message emitted by the guard:

```
do2screen: variable lineage exceeds 1000 levels — tracing aborted
```

`capture noisily` (not plain `capture`) is required so that `do2screen` can
write its internal log to the `text()` file even when exceptions occur.

The golden file is created once via `capture_golden.do`:

```stata
capture noisily ///
    do2screen using "`expath'/ex_deep_chain.do", ///
        var(g_1001) text("`tmp'_var_overflow_guard") replace
shell copy "`tmp'_var_overflow_guard.txt" "`goldback'\var_overflow_guard.txt"
capture confirm file "`golden'/var_overflow_guard.txt"
if _rc == 0 local ++n_ok
else         local ++n_fail
```

## Prevention

When testing a Stata `rclass` program that is called inside a `qui` block:

1. **Never assert `r()` values directly** — they will be cleared by the `qui`
   block and `missing(r(...))` will be unconditionally true.
2. Use **`text()` + golden-file comparison** to verify warning/error messages
   that are emitted by guards.
3. Use **`capture noisily`** (not plain `capture`) when the program must write
   to a log/text file — plain `capture` suppresses secondary log writes,
   producing a 0-byte or missing file.
4. For rc-producing guards, branching on `_rc != 0` (FAIL) / `_rc == 0` (then
   golden-file check) is the correct pattern.
5. Document the expected runtime when the guard test is slow:
   ```stata
   *     Note: parsing a 1001-line file + tracing 999 lineage levels takes 10–30s. Normal.
   ```

## Numbering convention for rc-only tests in capture_golden.do

Tests that assert `_rc != 0` (error path tests) produce no `text()` output and
therefore have no entry in `capture_golden.do`. When a section has both
rc-only tests and golden-capture tests with non-contiguous numbers, add
placeholder comments to document the intentional gap:

```stata
* 4.6 — rc-only test (range start < 1): no file capture needed (see run_tests.do 4.6)
* 4.7 — rc-only test (range start > end): no file capture needed (see run_tests.do 4.7)

* 4.8 Lineage overflow guard — ...
```

## Related

- `tests/helpers/assert_output_match.ado` — helper used for golden-file comparison
- `tests/capture_golden.do` — captures golden reference files
- `tests/golden/var_overflow_guard.txt` — golden file for this specific test
- `_do2screen_vartrack.ado` — contains the overflow guard
- P1.1 in `.cg-docs/reviews/2026-05-12-tested-modular-baseline-v2-thorough-verify-review-4.md`
- `.cg-docs/solutions/bugs/2026-05-13-compound-quote-scalar-accumulation-r132.md`
