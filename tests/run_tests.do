*! run_tests.do
*! do2screen regression test suite — Phase 1 gate.
*! Compares do2screen output against golden reference files.
*!
*! Usage:
*!   do "tests/run_tests.do"
*!
*! Requirements:
*!   - Golden files in tests/golden/ (created by tests/capture_golden.do)
*!   - do2screen.ado accessible via adopath
*!   - Stata 16.1+ (for frames)
*!
*! Implementation note: Stata (via MCP) cannot write directly to OneDrive paths.
*! Output is captured to c(tmpdir) and checksummed against golden files.

version 16.1
set more off
set varabbrev off

* ============================================================
* 0. Setup
* ============================================================

local projpath "c:/Users/wb384996/OneDrive - WBG/ado/myados/do2screen"
local expath   "`projpath'/tests/examples"
local golden   "`projpath'/tests/golden"

* Make helper ados (assert_output_match) findable
adopath + "`projpath'/tests/helpers"

* Force reload of helpers in case old version is cached in memory
capture program drop assert_output_match

* Make do2screen.ado findable
adopath + "`projpath'"

* Force reload of do2screen in case old version is cached
capture program drop do2screen

* Temp storage for comparison files (Stata can write here)
local tmpdir = subinstr("`c(tmpdir)'", "/", "\", .)
if substr("`tmpdir'", -1, 1) == "\" ///
    local tmpdir = substr("`tmpdir'", 1, length("`tmpdir'")-1)
local tmp "`tmpdir'\do2s_test"  // short prefix

* Counters (assert_output_match reads/writes both scalars)
scalar tests_failed = 0
scalar tests_ok = 0

* ============================================================
* 1. Variables mode tests
* ============================================================

display _newline as text "=== Variables mode tests ==="

* 1.1 income — compound lineage (wages + transfers)
do2screen using "`expath'/ex_gen_replace.do", ///
    var(income) text("`tmp'_var_income") replace
assert_output_match , outfile("`tmp'_var_income.txt") ///
    goldenfile("`golden'/var_income.txt") testname("var_income")

* 1.2 income — with labels
do2screen using "`expath'/ex_gen_replace.do", ///
    var(income) labels text("`tmp'_var_income_labels") replace
assert_output_match , outfile("`tmp'_var_income_labels.txt") ///
    goldenfile("`golden'/var_income_labels.txt") testname("var_income_labels")

* 1.3 hhincome — multi-level lineage
do2screen using "`expath'/ex_gen_replace.do", ///
    var(hhincome) text("`tmp'_var_hhincome") replace
assert_output_match , outfile("`tmp'_var_hhincome.txt") ///
    goldenfile("`golden'/var_hhincome.txt") testname("var_hhincome")

* 1.4 wages — single level
do2screen using "`expath'/ex_gen_replace.do", ///
    var(wages) text("`tmp'_var_wages") replace
assert_output_match , outfile("`tmp'_var_wages.txt") ///
    goldenfile("`golden'/var_wages.txt") testname("var_wages")

* 1.5 income with noprevious
do2screen using "`expath'/ex_gen_replace.do", ///
    var(income) noprevious text("`tmp'_var_income_noprevious") replace
assert_output_match , outfile("`tmp'_var_income_noprevious.txt") ///
    goldenfile("`golden'/var_income_noprevious.txt") testname("var_income_noprevious")

* 1.6 scalarname inconsistency — variables mode ignores scalarname()
do2screen using "`expath'/ex_gen_replace.do", ///
    var(income) scalarname(my_custom_sc) ///
    text("`tmp'_var_income_scalarname") replace
* Verify: s_varcode MUST be set (inconsistency preserved)
capture confirm scalar s_varcode
if _rc != 0 display as error "FAIL: s_varcode not set -- scalarname inconsistency broken"
assert _rc == 0
assert_output_match , outfile("`tmp'_var_income_scalarname.txt") ///
    goldenfile("`golden'/var_income_scalarname.txt") testname("var_income_scalarname")

* 1.7 edlev — encode gen()
do2screen using "`expath'/ex_egen_rename.do", ///
    var(edlev) text("`tmp'_var_edlev") replace
assert_output_match , outfile("`tmp'_var_edlev.txt") ///
    goldenfile("`golden'/var_edlev.txt") testname("var_edlev")

* 1.8 wage_num — destring gen()
do2screen using "`expath'/ex_egen_rename.do", ///
    var(wage_num) text("`tmp'_var_wage_num") replace
assert_output_match , outfile("`tmp'_var_wage_num.txt") ///
    goldenfile("`golden'/var_wage_num.txt") testname("var_wage_num")

* 1.9 sex — single rename
do2screen using "`expath'/ex_egen_rename.do", ///
    var(sex) text("`tmp'_var_sex") replace
assert_output_match , outfile("`tmp'_var_sex.txt") ///
    goldenfile("`golden'/var_sex.txt") testname("var_sex")

* 1.10 longvar — #delimit ; multi-line statement
do2screen using "`expath'/ex_comments_delimit.do", ///
    var(longvar) text("`tmp'_var_longvar") replace
assert_output_match , outfile("`tmp'_var_longvar.txt") ///
    goldenfile("`golden'/var_longvar.txt") testname("var_longvar_delimit")

* 1.11 avg_score — foreach loop + lineage tracing
do2screen using "`expath'/ex_foreach_loops.do", ///
    var(avg_score) text("`tmp'_var_avg_score") replace
assert_output_match , outfile("`tmp'_var_avg_score.txt") ///
    goldenfile("`golden'/var_avg_score.txt") testname("var_avg_score")

* 1.12 avg_score with labels
do2screen using "`expath'/ex_foreach_loops.do", ///
    var(avg_score) labels text("`tmp'_var_avg_score_labels") replace
assert_output_match , outfile("`tmp'_var_avg_score_labels.txt") ///
    goldenfile("`golden'/var_avg_score_labels.txt") testname("var_avg_score_labels")

* 1.13 total — shared-parent lineage (a+b, a=c*d, b=d*e)
do2screen using "`expath'/ex_multivar.do", ///
    var(total) text("`tmp'_var_total") replace
assert_output_match , outfile("`tmp'_var_total.txt") ///
    goldenfile("`golden'/var_total.txt") testname("var_total_lineage")

* 1.14 circ — circular reference detection
do2screen using "`expath'/ex_multivar.do", ///
    var(circ) text("`tmp'_var_circ") replace
assert_output_match , outfile("`tmp'_var_circ.txt") ///
    goldenfile("`golden'/var_circ.txt") testname("var_circ_circular")

* 1.15 simple — single-line creation
do2screen using "`expath'/ex_multivar.do", ///
    var(simple) text("`tmp'_var_simple") replace
assert_output_match , outfile("`tmp'_var_simple.txt") ///
    goldenfile("`golden'/var_simple.txt") testname("var_simple")

* ============================================================
* 2. Find mode tests
* ============================================================

display _newline as text "=== Find mode tests ==="

* 2.1 Poverty — multi-match with lines(2)
do2screen using "`expath'/ex_find_targets.do", ///
    find("Poverty") lines(2) text("`tmp'_find_poverty_l2") replace
assert_output_match , outfile("`tmp'_find_poverty_l2.txt") ///
    goldenfile("`golden'/find_poverty_l2.txt") testname("find_poverty_lines2")

* 2.2 Poverty — multi-match with lines(5)
do2screen using "`expath'/ex_find_targets.do", ///
    find("Poverty") lines(5) text("`tmp'_find_poverty_l5") replace
assert_output_match , outfile("`tmp'_find_poverty_l5.txt") ///
    goldenfile("`golden'/find_poverty_l5.txt") testname("find_poverty_lines5")

* 2.3 WELFARE — single match with lines(5)
do2screen using "`expath'/ex_find_targets.do", ///
    find("WELFARE") lines(5) text("`tmp'_find_welfare") replace
assert_output_match , outfile("`tmp'_find_welfare.txt") ///
    goldenfile("`golden'/find_welfare.txt") testname("find_welfare")

* 2.4 deflate — single match
do2screen using "`expath'/ex_find_targets.do", ///
    find("deflate") lines(5) text("`tmp'_find_deflate") replace
assert_output_match , outfile("`tmp'_find_deflate.txt") ///
    goldenfile("`golden'/find_deflate.txt") testname("find_deflate")

* 2.5 normalize — two matches
do2screen using "`expath'/ex_find_targets.do", ///
    find("normalize") lines(3) text("`tmp'_find_normalize") replace
assert_output_match , outfile("`tmp'_find_normalize.txt") ///
    goldenfile("`golden'/find_normalize.txt") testname("find_normalize")

* 2.6 comment — in comments-only file
do2screen using "`expath'/ex_comments_only.do", ///
    find("comment") lines(2) text("`tmp'_find_comments_only") replace
assert_output_match , outfile("`tmp'_find_comments_only.txt") ///
    goldenfile("`golden'/find_comments_only.txt") testname("find_comments_only")

* 2.7 not found — string absent from file
do2screen using "`expath'/ex_gen_replace.do", ///
    find("NOTPRESENT") text("`tmp'_find_not_found") replace
assert_output_match , outfile("`tmp'_find_not_found.txt") ///
    goldenfile("`golden'/find_not_found.txt") testname("find_not_found")

* 2.8 scalarname respected in find mode (contrast with variables mode)
do2screen using "`expath'/ex_find_targets.do", ///
    find("WELFARE") scalarname(my_find_sc) ///
    text("`tmp'_find_welfare_scalarname") replace
* Verify: custom scalar IS set in find mode (unlike variables mode)
capture confirm scalar my_find_sc
if _rc != 0 display as error "FAIL: my_find_sc not set -- scalarname not respected in find mode"
assert _rc == 0
assert_output_match , outfile("`tmp'_find_welfare_scalarname.txt") ///
    goldenfile("`golden'/find_welfare_scalarname.txt") testname("find_welfare_scalarname")

* ============================================================
* 3. Range mode tests
* ============================================================

display _newline as text "=== Range mode tests ==="

* 3.1 Two-number range
do2screen using "`expath'/ex_gen_replace.do", ///
    range(9 15) text("`tmp'_range_9_15") replace
assert_output_match , outfile("`tmp'_range_9_15.txt") ///
    goldenfile("`golden'/range_9_15.txt") testname("range_9_15")

* 3.2 Single-number range (uses default lines(5))
do2screen using "`expath'/ex_gen_replace.do", ///
    range(13) text("`tmp'_range_13") replace
assert_output_match , outfile("`tmp'_range_13.txt") ///
    goldenfile("`golden'/range_13.txt") testname("range_13_default")

* 3.3 Single-number range with custom lines
do2screen using "`expath'/ex_gen_replace.do", ///
    range(13) lines(2) text("`tmp'_range_13_l2") replace
assert_output_match , outfile("`tmp'_range_13_l2.txt") ///
    goldenfile("`golden'/range_13_l2.txt") testname("range_13_lines2")

* 3.4 Range across section border
do2screen using "`expath'/ex_find_targets.do", ///
    range(5 15) text("`tmp'_range_5_15_find") replace
assert_output_match , outfile("`tmp'_range_5_15_find.txt") ///
    goldenfile("`golden'/range_5_15_find.txt") testname("range_5_15_find")

* 3.5 scalarname respected in range mode
do2screen using "`expath'/ex_gen_replace.do", ///
    range(9 15) scalarname(my_range_sc) ///
    text("`tmp'_range_9_15_scalarname") replace
capture confirm scalar my_range_sc
if _rc != 0 display as error "FAIL: my_range_sc not set -- scalarname not respected in range mode"
assert _rc == 0
assert_output_match , outfile("`tmp'_range_9_15_scalarname.txt") ///
    goldenfile("`golden'/range_9_15_scalarname.txt") testname("range_9_15_scalarname")

* ============================================================
* 4. Error path tests (rc-based, no golden file comparison)
* ============================================================

display _newline as text "=== Error path tests ==="

* 4.1 Nonexistent file — should produce error message, not crash
do2screen using "`expath'/NOTEXIST.do", ///
    find("anything") text("`tmp'_error_nonexistent") replace
assert_output_match , outfile("`tmp'_error_nonexistent.txt") ///
    goldenfile("`golden'/error_nonexistent.txt") testname("error_nonexistent_file")

* 4.2 Mutually exclusive options — must error (rc != 0)
capture do2screen using "`expath'/ex_gen_replace.do", ///
    var(income) find("income")
if _rc != 0 {
    display as text "PASS: error_mutex_options (rc=`_rc')"
    scalar tests_ok = tests_ok + 1
}
else {
    display as error "FAIL: error_mutex_options — should have returned error"
    scalar tests_failed = tests_failed + 1
}

* 4.3 noprevious without variables — must error (rc != 0)
capture do2screen using "`expath'/ex_gen_replace.do", ///
    noprevious find("income")
if _rc != 0 {
    display as text "PASS: error_noprevious_without_var (rc=`_rc')"
    scalar tests_ok = tests_ok + 1
}
else {
    display as error "FAIL: error_noprevious_without_var — should have returned error"
    scalar tests_failed = tests_failed + 1
}

* 4.4 Empty file — graceful handling (note about no variables defined)
do2screen using "`expath'/ex_empty.do", ///
    find("anything") text("`tmp'_var_empty_find") replace
assert_output_match , outfile("`tmp'_var_empty_find.txt") ///
    goldenfile("`golden'/var_empty_find.txt") testname("var_empty_file_find")

* ============================================================
* 5. Final report
* ============================================================

display _newline as text "==================================================================="
local total_tests = tests_ok + tests_failed
display as text "Total tests: " as result `total_tests'
display as text "Passed:       " as result tests_ok
display as text "Failed:       " as result tests_failed
display as text "==================================================================="

if tests_failed > 0 display as error "`=tests_failed' test(s) failed. Review FAIL messages above."
assert tests_failed == 0
display as result "All tests passed."
