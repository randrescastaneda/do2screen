*! _do2screen_range v4.0 <12may2026>  R.Andres Castaneda
*! range() mode output for do2screen

version 16.1

program define _do2screen_range

    syntax , start(integer) end(integer) ///
        [SCALARname(string)]

    if ("`scalarname'" == "") local scalarname "s_varcode"

    local crlf "`=char(10)'`=char(13)'"

    frame _fr_do2screen_parsed {

        sum oriline, meanonly
        if r(N) == 0 {
            noi disp as text "(no lines to display)"
            exit
        }
        local end = min(`end', r(max))  // cap at actual frame size
        if (`start' > r(max)) {
            noi disp as error "range(): start (`start') exceeds file length (`=r(max)')"
            exit 198
        }

        noi di as text _new ///
            "Line {c |}                {cmd: Writing code between lines:}  {result: `start' & `end'}"
        noi di as text "{hline 5}{c +}{hline 90}"

        * escape residual backticks for macro safety during display
        qui replace code = subinstr(code, "`=char(96)'", ///
            "`=char(92)'`=char(96)'", .)

        scalar `scalarname' = ""

        foreach rline of numlist `start'/`end' {
            local space: disp _dup(`=4 - length("`rline'")') " "
            local lcode: disp code[`rline']
            scalar `scalarname' = `scalarname' + ///
                `"`crlf'`space'`rline': `lcode'"'
        }

        noi disp in y `scalarname'
        noi di as text _column(45) "{hline 10}" ///
            " (end of analysis of lines between `start' & `end')" _newline

    }  // end frame

end
