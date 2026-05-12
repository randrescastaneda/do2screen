* Example do-file: multiple variables with shared lineage + circular reference
* Used for: do2screen variables() mode — lineage tracing across variables
* Lineage: total = a + b; a = c * d; b = d * e (d is shared parent)
* Circular: circ = circ + 1 (circular creation: circ = f(circ))

use "${datadir}/components.dta", clear

* ---- Leaf nodes: c, d, e ----
gen c = raw_c * 0.9
gen d = raw_d / deflator
gen e = raw_e + adjustment

* ---- Inner nodes ----
gen a = c * d
replace a = 0 if a < 0
label variable a "Component A (c x d)"

gen b = d * e
replace b = . if missing(d) | missing(e)
label variable b "Component B (d x e)"

* ---- Root node ----
gen total = a + b
replace total = 0 if missing(a) & !missing(b)
replace total = b if missing(a) & !missing(b)
replace total = a if !missing(a) & missing(b)
label variable total "Total (a + b)"

* ---- Circular reference (a = f(a)) ----
gen circ = 100
replace circ = circ + adjustfactor   /* this is circular: circ depends on circ */
label variable circ "Circularly updated variable"

* ---- Multivar: separate variable using same parents ----
gen alt_total = a / 2 + b / 2
label variable alt_total "Alternative total"

* ---- Single line var for simple test ----
gen simple = raw_c + raw_d
label variable simple "Simple sum of raw inputs"

drop raw_c raw_d raw_e

save "${outdir}/multivar.dta", replace
