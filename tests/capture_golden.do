*! capture_golden.do
*! Capture golden reference output for all do2screen regression tests.
*! Run this against the CURRENT do2screen.ado before rewriting.
*! Re-running should produce byte-identical files (determinism test).
*
* Usage: do "tests/capture_golden.do"
*
* Output: tests/golden/<testname>.txt — one file per test case.
*
* All test cases are wrapped in capture noisily with rc display
* so this file cannot crash even if individual tests fail.
*
* Implementation note: Stata (via MCP) cannot write directly to OneDrive
* paths. We capture do2screen output to Stata's tempdir, then use
* shell copy to move files to tests/golden/.

version 16.1
set more off

* ============================================================
* 0. Paths and setup
* ============================================================

* Derive project root from the Stata working directory.
* When run as: do "tests/capture_golden.do" from the project root, c(pwd) IS the root.
* When run via MCP or do-file runner, c(pwd) may be the tests/ subdirectory.
local projpath "`c(pwd)'"
capture confirm file "`projpath'/do2screen.ado"
if _rc != 0 local projpath "`c(pwd)'/.."
capture confirm file "`projpath'/do2screen.ado"
if _rc != 0 {
    display as error "ABORT: do2screen.ado not found in `c(pwd)' or `c(pwd)'/.."
    display as error "Run from the project root or the tests/ subdirectory."
    exit 601
}
local expath   "`projpath'/tests/examples"
local golden   "`projpath'/tests/golden"

* Add project to adopath so do2screen.ado is found
adopath ++ "`projpath'"

* Temp directory for intermediate files (Stata can write here)
local tmpdir = subinstr("`c(tmpdir)'", "/", "\", .)
if substr("`tmpdir'", -1, 1) == "\" ///
    local tmpdir = substr("`tmpdir'", 1, length("`tmpdir'")-1)
local tmp "`tmpdir'\do2s"  // short prefix to avoid path-length issues

* Golden destination with backslashes for shell copy
local goldback = subinstr("`golden'", "/", "\", .)

* Track how many tests succeeded and failed
local n_ok   = 0
local n_fail = 0

* ============================================================
* Helper macro: capture one test case
*   %capture <name> <do2screen options>
* Calls do2screen with text(tmp_<name>) replace,
* then shell copy to tests/golden/<name>.txt
* ============================================================
* (Implemented inline below since Stata macros can't take do2screen calls)

* ============================================================
* Capture helper: write to tmpdir then shell copy to golden/
* Note: Stata (via MCP) cannot write directly to OneDrive paths.
* We write to c(tmpdir) which is always accessible, then copy.
* ============================================================

* ============================================================
* 1. Variables mode tests
* ============================================================

* 1.1 income — compound lineage (wages + transfers)
capture noisily ///
    do2screen using "`expath'/ex_gen_replace.do", ///
        var(income) text("`tmp'_var_income") replace
local rc1 = _rc
shell copy "`tmp'_var_income.txt" "`goldback'\var_income.txt"
if `rc1' == 0 local ++n_ok
else           local ++n_fail

* 1.2 income — with labels option
capture noisily ///
    do2screen using "`expath'/ex_gen_replace.do", ///
        var(income) labels text("`tmp'_var_income_labels") replace
local rc1 = _rc
shell copy "`tmp'_var_income_labels.txt" "`goldback'\var_income_labels.txt"
if `rc1' == 0 local ++n_ok
else           local ++n_fail

* 1.3 hhincome — traces through income (nested lineage)
capture noisily ///
    do2screen using "`expath'/ex_gen_replace.do", ///
        var(hhincome) text("`tmp'_var_hhincome") replace
local rc1 = _rc
shell copy "`tmp'_var_hhincome.txt" "`goldback'\var_hhincome.txt"
if `rc1' == 0 local ++n_ok
else           local ++n_fail

* 1.4 wages — simple single-level
capture noisily ///
    do2screen using "`expath'/ex_gen_replace.do", ///
        var(wages) text("`tmp'_var_wages") replace
local rc1 = _rc
shell copy "`tmp'_var_wages.txt" "`goldback'\var_wages.txt"
if `rc1' == 0 local ++n_ok
else           local ++n_fail

* 1.5 income with noprevious — should show only direct creation
capture noisily ///
    do2screen using "`expath'/ex_gen_replace.do", ///
        var(income) noprevious text("`tmp'_var_income_noprevious") replace
local rc1 = _rc
shell copy "`tmp'_var_income_noprevious.txt" "`goldback'\var_income_noprevious.txt"
if `rc1' == 0 local ++n_ok
else           local ++n_fail

* 1.6 scalarname inconsistency — variables mode ignores scalarname()
capture noisily ///
    do2screen using "`expath'/ex_gen_replace.do", ///
        var(income) scalarname(my_custom_sc) ///
        text("`tmp'_var_income_scalarname") replace
local rc1 = _rc
shell copy "`tmp'_var_income_scalarname.txt" "`goldback'\var_income_scalarname.txt"
if `rc1' == 0 {
    capture confirm scalar s_varcode
    if _rc == 0 display as text "s_varcode set — scalarname inconsistency preserved"
    else         display as error "WARNING: s_varcode not set in variables mode"
    local ++n_ok
}
else local ++n_fail

* 1.7 encode — edlev created via encode gen()
capture noisily ///
    do2screen using "`expath'/ex_egen_rename.do", ///
        var(edlev) text("`tmp'_var_edlev") replace
local rc1 = _rc
shell copy "`tmp'_var_edlev.txt" "`goldback'\var_edlev.txt"
if `rc1' == 0 local ++n_ok
else           local ++n_fail

* 1.8 wage_num — destring gen()
capture noisily ///
    do2screen using "`expath'/ex_egen_rename.do", ///
        var(wage_num) text("`tmp'_var_wage_num") replace
local rc1 = _rc
shell copy "`tmp'_var_wage_num.txt" "`goldback'\var_wage_num.txt"
if `rc1' == 0 local ++n_ok
else           local ++n_fail

* 1.9 sex — single rename
capture noisily ///
    do2screen using "`expath'/ex_egen_rename.do", ///
        var(sex) text("`tmp'_var_sex") replace
local rc1 = _rc
shell copy "`tmp'_var_sex.txt" "`goldback'\var_sex.txt"
if `rc1' == 0 local ++n_ok
else           local ++n_fail

* 1.10 longvar — #delimit ; multi-line statement
capture noisily ///
    do2screen using "`expath'/ex_comments_delimit.do", ///
        var(longvar) text("`tmp'_var_longvar") replace
local rc1 = _rc
shell copy "`tmp'_var_longvar.txt" "`goldback'\var_longvar.txt"
if `rc1' == 0 local ++n_ok
else           local ++n_fail

* 1.11 avg_score — via foreach loop (tracing total_score parent)
capture noisily ///
    do2screen using "`expath'/ex_foreach_loops.do", ///
        var(avg_score) text("`tmp'_var_avg_score") replace
local rc1 = _rc
shell copy "`tmp'_var_avg_score.txt" "`goldback'\var_avg_score.txt"
if `rc1' == 0 local ++n_ok
else           local ++n_fail

* 1.12 avg_score with labels
capture noisily ///
    do2screen using "`expath'/ex_foreach_loops.do", ///
        var(avg_score) labels text("`tmp'_var_avg_score_labels") replace
local rc1 = _rc
shell copy "`tmp'_var_avg_score_labels.txt" "`goldback'\var_avg_score_labels.txt"
if `rc1' == 0 local ++n_ok
else           local ++n_fail

* 1.13 total — lineage tracing (a+b, a=c*d, b=d*e, shared parent d)
capture noisily ///
    do2screen using "`expath'/ex_multivar.do", ///
        var(total) text("`tmp'_var_total") replace
local rc1 = _rc
shell copy "`tmp'_var_total.txt" "`goldback'\var_total.txt"
if `rc1' == 0 local ++n_ok
else           local ++n_fail

* 1.14 circ — circular reference detection
capture noisily ///
    do2screen using "`expath'/ex_multivar.do", ///
        var(circ) text("`tmp'_var_circ") replace
local rc1 = _rc
shell copy "`tmp'_var_circ.txt" "`goldback'\var_circ.txt"
if `rc1' == 0 local ++n_ok
else           local ++n_fail

* 1.15 simple — single-line creation
capture noisily ///
    do2screen using "`expath'/ex_multivar.do", ///
        var(simple) text("`tmp'_var_simple") replace
local rc1 = _rc
shell copy "`tmp'_var_simple.txt" "`goldback'\var_simple.txt"
if `rc1' == 0 local ++n_ok
else           local ++n_fail

* ============================================================
* 2. Find mode tests
* ============================================================

* 2.1 Poverty — multi-match (appears multiple times) with lines(2)
capture noisily ///
    do2screen using "`expath'/ex_find_targets.do", ///
        find("Poverty") lines(2) text("`tmp'_find_poverty_l2") replace
local rc1 = _rc
shell copy "`tmp'_find_poverty_l2.txt" "`goldback'\find_poverty_l2.txt"
if `rc1' == 0 local ++n_ok
else           local ++n_fail

* 2.2 Poverty — multi-match with lines(5)
capture noisily ///
    do2screen using "`expath'/ex_find_targets.do", ///
        find("Poverty") lines(5) text("`tmp'_find_poverty_l5") replace
local rc1 = _rc
shell copy "`tmp'_find_poverty_l5.txt" "`goldback'\find_poverty_l5.txt"
if `rc1' == 0 local ++n_ok
else           local ++n_fail

* 2.3 WELFARE — single match
capture noisily ///
    do2screen using "`expath'/ex_find_targets.do", ///
        find("WELFARE") lines(5) text("`tmp'_find_welfare") replace
local rc1 = _rc
shell copy "`tmp'_find_welfare.txt" "`goldback'\find_welfare.txt"
if `rc1' == 0 local ++n_ok
else           local ++n_fail

* 2.4 deflate — single match
capture noisily ///
    do2screen using "`expath'/ex_find_targets.do", ///
        find("deflate") lines(5) text("`tmp'_find_deflate") replace
local rc1 = _rc
shell copy "`tmp'_find_deflate.txt" "`goldback'\find_deflate.txt"
if `rc1' == 0 local ++n_ok
else           local ++n_fail

* 2.5 normalize — two matches
capture noisily ///
    do2screen using "`expath'/ex_find_targets.do", ///
        find("normalize") lines(3) text("`tmp'_find_normalize") replace
local rc1 = _rc
shell copy "`tmp'_find_normalize.txt" "`goldback'\find_normalize.txt"
if `rc1' == 0 local ++n_ok
else           local ++n_fail

* 2.6 comment — in comments-only file
capture noisily ///
    do2screen using "`expath'/ex_comments_only.do", ///
        find("comment") lines(2) text("`tmp'_find_comments_only") replace
local rc1 = _rc
shell copy "`tmp'_find_comments_only.txt" "`goldback'\find_comments_only.txt"
if `rc1' == 0 local ++n_ok
else           local ++n_fail

* 2.7 not found — search string absent
capture noisily ///
    do2screen using "`expath'/ex_gen_replace.do", ///
        find("NOTPRESENT") text("`tmp'_find_not_found") replace
local rc1 = _rc
shell copy "`tmp'_find_not_found.txt" "`goldback'\find_not_found.txt"
if `rc1' == 0 local ++n_ok
else           local ++n_fail

* 2.8 find with scalarname — should respect scalarname option
capture noisily ///
    do2screen using "`expath'/ex_find_targets.do", ///
        find("WELFARE") scalarname(my_find_sc) ///
        text("`tmp'_find_welfare_scalarname") replace
local rc1 = _rc
shell copy "`tmp'_find_welfare_scalarname.txt" "`goldback'\find_welfare_scalarname.txt"
if `rc1' == 0 {
    capture confirm scalar my_find_sc
    if _rc == 0 display as text "Scalarname respected in find mode (my_find_sc set)"
    else         display as error "WARNING: my_find_sc not set"
    local ++n_ok
}
else local ++n_fail

* ============================================================
* 3. Range mode tests
* ============================================================

* 3.1 Two-number range
capture noisily ///
    do2screen using "`expath'/ex_gen_replace.do", ///
        range(9 15) text("`tmp'_range_9_15") replace
local rc1 = _rc
shell copy "`tmp'_range_9_15.txt" "`goldback'\range_9_15.txt"
if `rc1' == 0 local ++n_ok
else           local ++n_fail

* 3.2 Single-number range (end = start + lines)
capture noisily ///
    do2screen using "`expath'/ex_gen_replace.do", ///
        range(13) text("`tmp'_range_13") replace
local rc1 = _rc
shell copy "`tmp'_range_13.txt" "`goldback'\range_13.txt"
if `rc1' == 0 local ++n_ok
else           local ++n_fail

* 3.3 Single-number range with custom lines
capture noisily ///
    do2screen using "`expath'/ex_gen_replace.do", ///
        range(13) lines(2) text("`tmp'_range_13_l2") replace
local rc1 = _rc
shell copy "`tmp'_range_13_l2.txt" "`goldback'\range_13_l2.txt"
if `rc1' == 0 local ++n_ok
else           local ++n_fail

* 3.4 Range across section border (in find targets file)
capture noisily ///
    do2screen using "`expath'/ex_find_targets.do", ///
        range(5 15) text("`tmp'_range_5_15_find") replace
local rc1 = _rc
shell copy "`tmp'_range_5_15_find.txt" "`goldback'\range_5_15_find.txt"
if `rc1' == 0 local ++n_ok
else           local ++n_fail

* 3.5 Range with scalarname — should respect scalarname option
capture noisily ///
    do2screen using "`expath'/ex_gen_replace.do", ///
        range(9 15) scalarname(my_range_sc) ///
        text("`tmp'_range_9_15_scalarname") replace
local rc1 = _rc
shell copy "`tmp'_range_9_15_scalarname.txt" "`goldback'\range_9_15_scalarname.txt"
if `rc1' == 0 {
    capture confirm scalar my_range_sc
    if _rc == 0 display as text "Scalarname respected in range mode (my_range_sc set)"
    else         display as error "WARNING: my_range_sc not set"
    local ++n_ok
}
else local ++n_fail

* ============================================================
* 4. Error path tests
* ============================================================

* For error tests, do2screen may fail (rc != 0) but the text file
* might not be created. We capture noisily, allow the error,
* and check if the shell copy succeeded.

* 4.1 Nonexistent file
capture noisily ///
    do2screen using "`expath'/NOTEXIST.do", ///
        find("anything") text("`tmp'_error_nonexistent") replace
shell copy "`tmp'_error_nonexistent.txt" "`goldback'\error_nonexistent.txt"
capture confirm file "`golden'/error_nonexistent.txt"
if _rc == 0 local ++n_ok
else         local ++n_fail

* 4.2 Mutually exclusive options
*     do2screen exits BEFORE opening text log, so no text file is created.
*     This case is tested by rc assertion in run_tests.do, not by file comparison.
capture noisily ///
    do2screen using "`expath'/ex_gen_replace.do", ///
        var(income) find("income")
if _rc != 0 {
    display as text "CAPTURE OK (expected error rc=`_rc'): error_mutex_options"
    local ++n_ok
}
else {
    display as error "CAPTURE FAIL: error_mutex_options should have errored"
    local ++n_fail
}

* 4.3 noprevious without variables  
*     do2screen exits BEFORE opening text log, so no text file is created.
*     This case is tested by rc assertion in run_tests.do, not by file comparison.
capture noisily ///
    do2screen using "`expath'/ex_gen_replace.do", ///
        noprevious find("income")
if _rc != 0 {
    display as text "CAPTURE OK (expected error rc=`_rc'): error_noprevious_without_var"
    local ++n_ok
}
else {
    display as error "CAPTURE FAIL: error_noprevious_without_var should have errored"
    local ++n_fail
}

* 4.4 Empty file — find mode (graceful error: "no variables defined")
capture noisily ///
    do2screen using "`expath'/ex_empty.do", ///
        find("anything") text("`tmp'_var_empty_find") replace
shell copy "`tmp'_var_empty_find.txt" "`goldback'\var_empty_find.txt"
capture confirm file "`golden'/var_empty_find.txt"
if _rc == 0 local ++n_ok
else         local ++n_fail

* ============================================================
* 5. Summary and determinism report
* ============================================================

display _newline as text "=== Golden output capture complete ==="
display as text "Tests OK:   " as result `n_ok'
display as text "Tests FAIL: " as result `n_fail'
display _newline

local goldfiles : dir "`golden'" files "*.txt"
local nfiles : word count `goldfiles'
display as text "Golden files in tests/golden/: " as result `nfiles'
foreach f of local goldfiles {
    display as text "  `f'"
}

display _newline
if `n_fail' == 0 {
    display as result "All `n_ok' golden files captured successfully."
}
else {
    display as error "`n_fail' capture(s) failed. Check output above."
    display as error "Golden files may be incomplete."
}
