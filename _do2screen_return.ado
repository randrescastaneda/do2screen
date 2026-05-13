*! _do2screen_return v4.0 <12may2026>  R.Andres Castaneda
*! populate r() scalars and _fr_do2screen frame
*
*  Returns
*  -------
*  r(nlines)   number of selected lines
*  r(dofile)   path of the analysed do-file
*  r(lines)    1 x r(nlines) row matrix of selected line numbers
*  frame _fr_do2screen  (columns: line, code, variable)

version 16.1

program define _do2screen_return, rclass

    syntax , dofile(string)         ///
        mode(string)                ///
        [start(integer 0)           ///
        end(integer 0)              ///
        variables(string)]

    * -------------------------------------------------------
    * 1. Collect selected line numbers from the parsed frame
    * -------------------------------------------------------
    local sellines ""

    if ("`mode'" == "variables") {
        frame _fr_do2screen_parsed: quietly ///
            levelsof line if selection == 1, local(sellines) missing
    }
    else if ("`mode'" == "find") {
        frame _fr_do2screen_parsed: quietly ///
            levelsof line if selection == -1, local(sellines) missing
    }
    else if ("`mode'" == "range") {
        frame _fr_do2screen_parsed: sum oriline, meanonly
        if !missing(r(max)) local end = min(`end', r(max))  // cap at actual frame size
        numlist "`start'/`end'"
        local sellines `r(numlist)'
    }

    local nlines: word count `sellines'

    * -------------------------------------------------------
    * 2. Build r(lines) matrix
    * -------------------------------------------------------
    if (`nlines' > 0) {
        matrix r_lines = J(1, `nlines', .)
        local k = 0
        foreach ln of local sellines {
            local ++k
            matrix r_lines[1, `k'] = `ln'
        }
        return matrix lines = r_lines
    }
    else {
        matrix r_lines = J(1, 1, .)
        return matrix lines = r_lines
    }

    return scalar nlines = `nlines'
    return local dofile "`dofile'"

    * -------------------------------------------------------
    * 3. Build frame _fr_do2screen (line, code, variable)
    * -------------------------------------------------------
    cap frame drop _fr_do2screen
    frame create _fr_do2screen long(line) str2045(code) str244(variable)

    if (`nlines' > 0) {
        frame _fr_do2screen_parsed {
            if ("`mode'" == "variables") {
                local rownum = 0
                quietly levelsof line if selection == 1, local(vlines)
                * normalise to post-dedup count for single-var detection
                local variables: list uniq variables
                * attribute lines to variable when single token in variables() option (normalised above)
                local _attrvar ""
                if wordcount(`"`variables'"') == 1 local _attrvar = strtrim(`"`variables'"')
                foreach vline of local vlines {
                    local ++rownum
                    local vcode: disp code[`vline']
                    frame post _fr_do2screen ///
                        (`vline') (`"`vcode'"') ("`_attrvar'")
                }
            }
            else if ("`mode'" == "find") {
                local rownum = 0
                quietly levelsof line if selection == -1, local(flines)
                foreach fline of local flines {
                    local ++rownum
                    local fcode: disp code[`fline']
                    frame post _fr_do2screen ///
                        (`fline') (`"`fcode'"') ("")
                }
            }
            else if ("`mode'" == "range") {
                foreach rline of numlist `start'/`end' {
                    local rcode: disp code[`rline']
                    frame post _fr_do2screen ///
                        (`rline') (`"`rcode'"') ("")
                }
            }
        }
    }

end
