*! _do2screen_aftervar v4.0 <12may2026>  R.Andres Castaneda
*! post-creation tracking: drop, label, foreach loops

version 16.1

program define _do2screen_aftervar, rclass

    syntax anything(name=var), [labels maxline(numlist)]

    if ("`maxline'" == "") local maxline = _N

    qui {

        *------------------------------------------------------------------
        * 4.1  drop <var>
        *------------------------------------------------------------------
        cap replace selection = 1 if ///
            (regexm(code, `"^[ ]*drop[ ]+[a-zA-Z0-9_ ]*`var'"')) ///
            & line < `maxline'

        *------------------------------------------------------------------
        * 4.2  label variable / label values
        *------------------------------------------------------------------
        if (!missing("`labels'")) {
            cap replace selection = 1 if ///
                (regexm(code, ///
                `"^[ ]*l(a|ab|abe|abel)[ ]+va(r|ri|ria|riab|riabl|riable)[ ]+`var'[ ]+.*"')) ///
                & line < `maxline'

            cap replace selection = 1 if ///
                (regexm(code, ///
                `"^[ ]*l(a|ab|abe|abel)[ ]+val(u|ue|ues)[ ]+.*`var'"')) ///
                & line < `maxline'
        }

        *------------------------------------------------------------------
        * 4.3  foreach loops that contain <var>
        *------------------------------------------------------------------
        cap replace selection = 2 if ///
            (regexm(code, ///
            `"^[ ]*foreach[ ]+[a-zA-Z0-9_]+[ ]+(in|of)[ ]+.*`var'.*{$"')) ///
            & line < `maxline'

        count if selection == 2
        if (r(N) >= 1) {
            levelsof line if selection == 2, local(nlines)
            foreach loopstart of local nlines {
                local inloop = 0
                local j = 0
                while (`inloop' == 0) {
                    local ++j
                    local loopline: disp code[`=`loopstart' + `j'']
                    if (regexm(`"`macval(loopline)'"', `"}"') == 1) ///
                        local inloop = 1
                    replace selection = 1 in `=`loopstart' + `j''
                }
            }
        }
        replace selection = 1 if selection == 2

    }

end
