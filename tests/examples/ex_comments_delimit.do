* Example do-file: block comments, inline comments, and #delimit ; / cr
* Used for: do2screen delimiter and comment stripping tests
* This file exercises nested /* */ comments, #delimit switching, trailcode
* accumulation, and continuation lines

use "${datadir}/base.dta", clear

/* ==========================================================
   Section 1: Simple variable creation
   ========================================================== */

gen y = x + 1   // inline comment should be ignored in output
gen z = y * 2   /* mid-line block comment */ + 3

/* This variable is created in a multi-line block comment scope:
   gen dropped_var = 999
   The line above should NOT appear as a variable creation.
*/

gen realvar = z + 5

/* Nested-style comment block:
   /* inner comment */
   Still in outer block
*/

gen aftercomment = realvar / 10

* ---- Switch to semicolon delimiter ----
#delimit ;

replace aftercomment = 0
  if aftercomment < 0 ;

gen longvar =
  aftercomment +
  realvar +
  y ;

replace longvar = . if missing(realvar) ;

#delimit cr

* Back to carriage return delimiter
gen finalvar = longvar * 100
replace finalvar = 0 if finalvar < 0  // trailing inline comment

* ---- Second delimit block ----
#delimit ;

gen twostmt_a = finalvar / 2 ; gen twostmt_b = finalvar / 3 ;

#delimit cr

save "${outdir}/delimit_test.dta", replace
