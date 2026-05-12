*! _do2screen_find v4.0 <12may2026>  R.Andres Castaneda
*! find() mode output for do2screen

version 16.1

program define _do2screen_find

    syntax , find(string)               ///
        [lines(integer 5)               ///
        SCALARname(string)]

    if ("`scalarname'" == "") local scalarname "s_varcode"

    * NOTE: crlf intentionally NOT defined in find mode.
    *       The scalar accumulates code lines without embedded newlines.
    *       To fix: add crlf, switch display to per-line noi disp (like vartrack),
    *       and regenerate golden files. Tracked as P0.1 [manual].

    frame _fr_do2screen_parsed {

        * escape residual backticks for macro safety during display
        qui replace code = subinstr(code, "`=char(96)'", ///
            "`=char(92)'`=char(96)'", .)

        local t = 0
        foreach tofind of local find {

            local ++t
            qui replace selection = .

            noi di as text _new ///
                "Line {c |}                {cmd: Writing code for:}  {result: `tofind'}"
            noi di as text "{hline 5}{c +}{hline 90}"

            qui replace selection = -1 if strpos(code, `"`tofind'"') != 0
            qui count if selection == -1
            local count_found = r(N)

            if (`count_found' >= 1) {

                qui levelsof line if selection == -1, local(nlines)
                local section = 0

                foreach fline of local nlines {

                    scalar `scalarname' = ""
                    local ++section

                    foreach i of numlist 0/`lines' {
                        local space: disp _dup(`=4 - length("`=`fline' + `i''")') " "
                        local lcode: disp code[`=`fline' + `i'']
                        scalar `scalarname' = `scalarname' + ///
                            `"`crlf'`space'`=`fline' + `i'': `lcode'"'
                    }

                    noi disp in y `scalarname'
                    noi di as text _column(35) "{hline 10}" ///
                        " (end of section `section' for `tofind') " ///
                        "{hline 10}" _newline
                }

            }
            else {
                noi disp in red "nothing found for " in y " `tofind'"
            }

            noi di as text _column(60) "{hline 10}" ///
                " (end of analysis of `tofind')" _newline

        }  // end foreach tofind

    }  // end frame

end
