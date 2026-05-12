* Example do-file: gen, replace, and egen expressions
* Used for: do2screen variables() mode testing
* Target variables: income, wages, transfers, hhincome

* ---- Step 1: Load base data ----
use "${datadir}/household.dta", clear

* ---- Step 2: Basic gen ----
gen wages = labourinc * 12
gen transfers = nonlabourinc + govtransfer

* ---- Step 3: Compound expression ----
gen income = wages + transfers
replace income = 0 if income < 0
replace income = . if missing(wages) | missing(transfers)

* ---- Step 4: Household aggregation ----
egen hhincome = sum(income), by(hhid)

* ---- Step 5: Per-capita ----
gen pchincome = hhincome / hhsize
replace pchincome = . if hhsize == 0

* ---- Labels ----
label variable income    "Individual total income"
label variable hhincome  "Household total income"
label variable pchincome "Per-capita household income"

* ---- Drop intermediate ----
drop wages transfers govtransfer

* ---- Done ----
save "${outdir}/income_vars.dta", replace
