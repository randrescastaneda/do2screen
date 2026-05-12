*! _do2screen_vartrack -- variable-lineage tracer for do2screen variables() mode
*! Part of do2screen v4.0 <12may2026>
*! Author: R.Andres Castaneda

version 16.1

program define _do2screen_vartrack

    syntax , VARiables(string)        ///
        [lrep(string) rrep(string)    ///
        dblq(string)                  ///
        noprevious                    ///
        labels                        ///
        varout(string)                ///
        nolinenumbers]

    if ("`lrep'" == "") local lrep "LlLl"
    if ("`rrep'" == "") local rrep "RrRr"
    if ("`dblq'" == "") local dblq "DQDQ"

    local crlf "`=char(10)'`=char(13)'"

    *------------------------------------------------------------------
    * Entire frame block is wrapped in qui {} so data operations
    * do not produce output. noi disp statements work inside qui.
    *------------------------------------------------------------------
    frame _fr_do2screen_parsed {

        qui {

        foreach var of local variables {

            replace code      = origcode   // reset anchor for each variable
            replace selection = .

            *----------------------------------------------------------
            * Initialise recursion state
            *----------------------------------------------------------
            tempname D
            matrix `D' = J(1, 1000, 1)
            local i = 1

            local mainvar "`var'"
            local doughter`var' "nope"
            local prevars`var' "`var'"

            local stay = 1

            tempvar content
            gen `content' = ""
            local cc = 0

            qui while (`stay' == 1) {

                if ("`previous'" == "noprevious") local stay = 0
                local j = `D'[1, `i']

                if (`"`: word `j' of `prevars`var'''"' != `""') {

                    local var : word `j' of `prevars`var''

                    * ---- circular reference check -------------------------
                    if ("`var'" == "`doughter`var''") {
                        disp in red "variable `var' presents circular creation [i.e, x = f(X)]"
                        matrix `D'[1, `i'] = `D'[1, `i'] + 1
                        continue
                    }

                    * ---- varout exclusion ----------------------------------
                    if ("`var'" == "`varout'") {
                        matrix `D'[1, `i'] = `D'[1, `i'] + 1
                        continue
                    }

                    * ---- visited check ------------------------------------
                    count if `content' == "`var'"
                    if r(N) == 0 {
                        local ++cc
                        replace `content' = "`var'" in `cc'
                    }
                    else {
                        matrix `D'[1, `i'] = `D'[1, `i'] + 1
                        continue
                    }

                    * ---- identify creation lines --------------------------
                    local way1 = 0
                    local fline ""

                    tempvar a
                    gen `a' = ""

                    * gen, replace, egen
                    replace `a' = regexs(2) if ///
                        regexm(code, ///
                        `"^(.*[:]?[ ]*[a-z]+ `var'[ ]*=)([ a-z0-9\.\("]+.*)$"')

                    * rename
                    replace `a' = regexs(1) if ///
                        regexm(code, ///
                        `"[ ]*ren[ame]*[ ]+\(?([a-zA-Z_]*[a-zA-Z0-9_ ]*)\)?[ ]+\(?([a-zA-Z_]*[a-zA-Z0-9_ ]*`var'[a-zA-Z_]*[a-zA-Z0-9_ ]*)\)?"')

                    * encode, destring, and similar
                    replace `a' = regexs(1) if ///
                        regexm(code, ///
                        `"(^.*),.*[a-z]+\(([a-zA-Z0-9_ ]*[ ]+`var'|[ ]*`var')([ ]*\)|[ ]+[a-zA-Z0-9_ ]*\))"')

                    replace `a' = "" if regexm(code, `"^[ ]*(egen|gen).*,.*`var'"')

                    sum line if `a' != "", meanonly
                    if r(N) != 0 {
                        levelsof line if (`a' != ""), local(tlines)
                        foreach tline of local tlines {
                            local fline "`fline' `: disp `a'[`tline']'"
                        }
                    }

                    if (`"`fline'"' != `""') local way1 = 1

                    * ---- variable not created → skip ----------------------
                    if (`way1' == 0) {
                        matrix `D'[1, `i'] = `D'[1, `i'] + 1
                        local var "`doughter`var''"
                        continue
                    }

                    * ---- post-creation tracking (drop, label, loops) ------
                    if ("`mainvar'" == "`var'") {
                        sum line if `a' != "", meanonly
                        local bfrlines = r(max)
                        _do2screen_aftervar `var', `labels'
                    }
                    else {
                        _do2screen_aftervar `var', `labels' maxline(`bfrlines')
                    }
                    replace selection = 1 if (`a' != "" & line <= `bfrlines')

                    * ---- extract parent variable names --------------------
                    local tofind = `"`fline'"'

                    * replace lstrfun with ustrregexra():
                    local tofind = ustrregexra(`"`tofind'"', "[a-zA-Z]+\(", "")
                    foreach symb in ")" "+" "-" "/" "*" ">=" "<=" ">" "<" "==" "!=" ///
                        "~=" " if " " . " " ." "|" "(" "&" "#" "%" "^" {
                        local tofind: subinstr local tofind "`symb'" "  ", all
                    }
                    local tofind = ustrregexra(`"`tofind'"', ///
                        " \[[ ]*[a-z]+[ ]*=[ ]*[a-zA-Z0-9]+[ ]*\]", "")
                    local tofind = ustrregexra(`"`tofind'"', "^.*=", "")
                    local tofind = ustrregexra(`"`tofind'"', ",.*", "")

                    * drop decimal numbers
                    local b ""
                    foreach x of local tofind {
                        if !regexm(`"`x'"', `"[0-9]+\.[0-9]+"') local b "`b' `x'"
                    }
                    local tofind `"`b'"'

                    * drop plain integers
                    local c ""
                    foreach x of local tofind {
                        if !regexm(`"`x'"', `"^[0-9]+"') local c "`c' `x'"
                    }
                    local tofind `"`c'"'

                    local tofind = ltrim(rtrim(itrim(`"`tofind'"')))
                    local tofind: list uniq tofind

                    if (`"`tofind'"' != `""') {
                        local eqvars = 0
                        local d ""
                        foreach nvar of local tofind {
                            if ("`nvar'" != "`var'") local d "`d' `nvar'"
                            else local eqvars = 1
                        }
                        local tofind `"`d'"'
                        local tofind = ltrim(rtrim(itrim(`"`tofind'"')))
                        local tofind: list uniq tofind

                        if (`"`tofind'"' != `""') {
                            local prevars`var' "`tofind'"
                            foreach nvar of local tofind {
                                local doughter`nvar' "`var'"
                            }
                            local ++i
                        }
                        else {
                            matrix `D'[1, `i'] = `D'[1, `i'] + 1
                            local var "`doughter`var''"
                        }
                    }
                    else {
                        matrix `D'[1, `i'] = `D'[1, `i'] + 1
                        local var "`doughter`var''"
                    }

                }
                else {
                    matrix `D'[1, `i'] = 1
                    local i = `i' - 1
                    if (`i' == 0) continue, break
                    matrix `D'[1, `i'] = `D'[1, `i'] + 1
                    local var "`doughter`var''"
                }

            }  // end while stay == 1

            *----------------------------------------------------------
            * Restore display-safe code (undo quote handles)
            *----------------------------------------------------------
            replace code = subinstr(code, "`lrep'", char(96), .)   // `
            replace code = subinstr(code, "`rrep'", char(39), .)   // '
            replace code = subinstr(code, "`dblq'", char(34), .)   // "
            replace code = subinstr(code, "`=char(96)'", ///
                "`=char(92)'`=char(96)'", .)

            *----------------------------------------------------------
            * Accumulate scalar s_varcode and display
            *----------------------------------------------------------
            scalar s_varcode = ""
            levelsof line if selection == 1, local(lines)

            noi disp as text _new ///
                "Line   {c |}" _col(20) ///
                "{cmd: Writing code for:} {result: `mainvar'}"
            noi disp as text "{hline 7}{c +}{hline 90}"

            local linenumber ""
            foreach displine of local lines {
                if ("`linenumbers'" == "") {
                    local space: disp _dup(`=6 - length("`displine'")') " "
                    local linenumber "`space'`displine': "
                }
                local lcode: disp code[`displine']
                scalar s_varcode = s_varcode + ///
                    `"`crlf'`linenumber'`lcode'"'
                noi disp in g `"`linenumber'"' in y `" `lcode'"'
            }

            noi disp as text _col(60) "{hline 10}" ///
                " (end of analysis of `mainvar')" _newline

        }  // end foreach var

        }  // end qui

    }  // end frame _fr_do2screen_parsed

end
