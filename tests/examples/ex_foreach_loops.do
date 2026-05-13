* Example do-file: foreach loops containing variable creation
* Used for: do2screen aftervar() loop tracking
* Target variables: score1..score5, total_score, avg_score

use "${datadir}/scores.dta", clear

* ---- Individual score normalization ----
gen total_score = 0

foreach i of numlist 1/5 {
    replace score`i' = score`i' / 100
    replace total_score = total_score + score`i'
}

* ---- Average over items ----
gen avg_score = total_score / 5
replace avg_score = . if total_score == 0

* ---- Categorical score created inside loop ----
local cutoffs "40 60 80"
local k = 0
foreach cut of local cutoffs {
    local ++k
    gen pass_`k' = (avg_score >= `cut') if !missing(avg_score)
}

* ---- Label scores inside loop ----
label variable total_score "Sum of normalized scores"
label variable avg_score   "Average normalized score"

foreach i of numlist 1/5 {
    label variable score`i' "Normalized score item `i'"
}

* ---- Derived categorical ----
gen score_cat = .
replace score_cat = 1 if avg_score < 0.40
replace score_cat = 2 if avg_score >= 0.40 & avg_score < 0.60
replace score_cat = 3 if avg_score >= 0.60 & avg_score < 0.80
replace score_cat = 4 if avg_score >= 0.80

label variable score_cat "Score category (1=fail 4=excellent)"
drop pass_1 pass_2 pass_3

save "${outdir}/scores_processed.dta", replace
