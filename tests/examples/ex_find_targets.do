* Example do-file: string search targets at known line numbers
* Used for: do2screen find() mode testing -- single and multi-match
* Search targets: Poverty (3x), WELFARE (1x), normalize (2x), deflate (1x)

* ---- Section A: Poverty measurement ----
* Poverty line threshold (1.90 USD PPP per day, annualized)
gen pline = 1.90 * 365
label variable pline "Annual poverty line"

* Poverty indicator for primary line
gen poor = (welfare < pline) if !missing(welfare)
label variable poor "Binary poverty indicator"

* Poverty gap index
gen povgap = max(0, (pline - welfare) / pline) if !missing(welfare)
label variable povgap "Poverty gap"

* Moderate poverty line (3.20 USD PPP per day)
gen poor_mod = (welfare < 3.20 * 365) if !missing(welfare)
label variable poor_mod "Moderate poverty indicator"

* ---- Section B: WELFARE variable construction ----
* WELFARE aggregate is real per-capita consumption
gen WELFARE = pccons_def / cpi
replace WELFARE = . if missing(pccons_def) | cpi == 0
label variable WELFARE "Real per-capita welfare aggregate"

* ---- Section C: normalize inputs ----
* normalize consumption before aggregation
gen cons_norm = pccons / mean_cons if mean_cons > 0

* Also normalize income
gen inc_norm = labor_inc / mean_inc if mean_inc > 0
label variable cons_norm "Normalized consumption"
label variable inc_norm  "Normalized income"

* ---- Section D: deflate variables ----
* deflate wages by regional CPI
gen wage_real = nominal_wage / regional_cpi
replace wage_real = . if regional_cpi == 0 | missing(nominal_wage)

* deflate pensions by national CPI
gen pension_real = nominal_pension / national_cpi
label variable wage_real    "Real wage (deflated)"
label variable pension_real "Real pension (deflated)"

save "${outdir}/welfare_vars.dta", replace
