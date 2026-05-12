*! assert_output_match.ado
*! Helper for do2screen regression tests.
*! Compares checksum of captured output against a golden reference file.
*!
*! Syntax:
*!   assert_output_match, outfile("path/outfile.txt") ///
*!       goldenfile("path/golden.txt") [testname("description")]
*!
*! Requires scalar `tests_failed` to be initialized in the caller.

program define assert_output_match
    syntax , outfile(string) goldenfile(string) [testname(string)]

    if "`testname'" == "" local testname "`outfile'"

    capture confirm file "`outfile'"
    if _rc != 0 {
        display as error "FAIL: `testname' -- output file not found: `outfile'"
        scalar tests_failed = tests_failed + 1
        exit
    }

    capture confirm file "`goldenfile'"
    if _rc != 0 {
        display as error "FAIL: `testname' -- golden file not found: `goldenfile'"
        scalar tests_failed = tests_failed + 1
        exit
    }

    quietly checksum "`outfile'"
    local new_cs = r(checksum)
    local new_sz = r(filelen)

    quietly checksum "`goldenfile'"
    local gold_cs = r(checksum)
    local gold_sz = r(filelen)

    if (`new_cs' == `gold_cs' & `new_sz' == `gold_sz') {
        display as text "PASS: `testname'"
    }
    else {
        display as error "FAIL: `testname'"
        display as error "  golden: checksum=`gold_cs' size=`gold_sz'"
        display as error "  actual: checksum=`new_cs' size=`new_sz'"
        scalar tests_failed = tests_failed + 1
    }
end
