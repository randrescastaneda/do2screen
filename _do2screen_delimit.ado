*! _do2screen_delimit v4.0 <12may2026>  R.Andres Castaneda
*! #delimit loop: populate line/code from precode

version 16.1

program define _do2screen_delimit

    syntax  // takes no arguments; operates on _fr_do2screen_parsed

    * Operates on frame _fr_do2screen_parsed, which must already exist
    * with at least: oriline, precode, line, code  (created by _do2screen_parse)

    frame _fr_do2screen_parsed {

        sum oriline, meanonly
        local maxline = r(max)
    }

    local i        = 0
    local u        = 1
    local delimit  = 0
    local trailcode ""

    qui while (`i' < `maxline') {

        local ++i
        frame _fr_do2screen_parsed: local line = precode[`i']

        * ------ empty / blank line ------------------------------------------
        if regexm(`"`macval(line)'"', `"^[ ]*$"') {
            frame _fr_do2screen_parsed {
                if (`u' > _N) set obs `u'
                replace line = `u' in `u'
                replace code = ""           in `u'
            }
            local ++u
            continue
        }

        * ------ delimiter switches ------------------------------------------
        if regexm(`"`macval(line)'"', "#[ ]?delimit[ ]?;") {
            local delimit = 1
            continue
        }
        if regexm(`"`macval(line)'"', "#[ ]?delimit[ ]?cr") {
            local delimit = 0
            continue
        }

        * ------ default delimiter (cr) --------------------------------------
        if (`delimit' == 0) {
            frame _fr_do2screen_parsed {
                if (`u' > _N) set obs `u'
                replace line = `u'                  in `u'
                replace code = `"`macval(line)'"'   in `u'
            }
            local ++u
            continue
        }

        * ------ semicolon delimiter -----------------------------------------
        if regexm(`"`macval(line)'"', ";") {

            tokenize `"`macval(line)'"', parse(;)
            local s = 1
            while (`"``s''"' != "") {
                if (`"``s''"' != ";" & `"``=`s'+1''"' != "") {
                    frame _fr_do2screen_parsed {
                        if (`u' > _N) set obs `u'
                        replace line = `u' in `u'
                        if (`s' == 1) {
                            replace code = `"`trailcode' ``s''"' in `u'
                        }
                        else {
                            replace code = `"``s''"' in `u'
                        }
                    }
                    local ++u
                }
                local ++s
            }
            * trail: last token is non-semicolon → carry forward
            local --s
            if (`"``s''"' != ";") local trailcode `"``s''"'
            else                   local trailcode ""
        }
        else {
            * line has no semicolon → accumulate into trailcode
            local start_i = `i'
            while !regexm(`"`macval(line)'"', ";") & `i' < `maxline' {
                local trailcode `"`trailcode' `macval(line)'"'
                local ++i
                frame _fr_do2screen_parsed: local line = precode[`i']
            }
            * Only step back if the inner loop advanced (i.e. found a ';').
            * If we reached maxline without finding ';', do not decrement —
            * that would cause the outer while to loop forever on the last line.
            if `i' > `start_i' local --i
        }

    }  // end while

    * ------ finalize frame --------------------------------------------------
    frame _fr_do2screen_parsed {
        replace code = subinstr(code, ";", "", .)
        cap drop origcode
        clonevar origcode = code          // anchor: reset per-variable iteration
        drop if line == .
        compress
    }

end
