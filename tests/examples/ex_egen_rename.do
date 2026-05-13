* Example do-file: rename (single and grouped), encode/destring with gen()
* Used for: do2screen variables() mode — rename, encode/destring tracking
* Target variables: sex, educ_code, edlev, wage_num

use "${datadir}/survey.dta", clear

* ---- Single rename ----
rename gender sex
rename education educ_code

* ---- Grouped rename (Stata 15+) ----
rename (inc1 inc2 inc3) (wage_a wage_b wage_c)

* ---- encode with gen() option ----
encode educ_code, gen(edlev)
label variable edlev "Education level (encoded)"

* ---- destring with gen() option ----
destring wage_str, gen(wage_num) force
replace wage_num = 0 if missing(wage_num)
label variable wage_num "Numeric wage (destrung)"

* ---- rename back to canonical ----
rename educ_code education_cat
rename sex gender_clean

save "${outdir}/renamed_vars.dta", replace
