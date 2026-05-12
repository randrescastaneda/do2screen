*! _do2screen_parse -- read & comment-strip a do-file into _fr_do2screen_parsed
*! Part of do2screen v4.0 <12may2026>
*! Author: R.Andres Castaneda

version 16.1

program define _do2screen_parse

    syntax , dofile(string)           ///
        [lrep(string) rrep(string)    ///
        dblq(string) comments]

    * -------------------------------------------------------
    * 1. Default quote handles
    * -------------------------------------------------------
    if ("`lrep'" == "") local lrep "LlLl"
    if ("`rrep'" == "") local rrep "RrRr"
    if ("`dblq'" == "") local dblq "DQDQ"

    * -------------------------------------------------------
    * 2. Create fresh frame
    * -------------------------------------------------------
    cap frame drop _fr_do2screen_parsed
    frame create _fr_do2screen_parsed

    * -------------------------------------------------------
    * 3. Load file, initialise columns
    * -------------------------------------------------------
    frame _fr_do2screen_parsed {

        tempfile h
        * filefilter OUTSIDE qui so file-not-found errors propagate visibly
        filefilter "`dofile'" `h', ///
            from(\n) to(\n\BS\BS\RQ\RQ\BS\BS\BS) replace

        qui {
            import delimited using `h', clear ///
                delimiters("thisisadelimiter,itshouldworkfine", asstring)
            rename v1 oricode

            replace oricode = subinstr(oricode, `"\\''\\\"', "", .)
            gen long oriline  = _n
            gen double selection = .
            gen precode = oricode

            * ---------------------------------------------------
            * 4. Strip block comments (/* ... */)
            * ---------------------------------------------------
            if ("`comments'" == "") {

                tempvar o c open close open1 close1

                gen `o'     = 1 if (regexm(oricode, `"/\*"'))
                gen `c'     = 1 if (regexm(oricode, `"\*/"'))

                gen `open'  = sum(`o') if `o' == 1
                gen `close' = sum(`c') if `c' == 1

                clonevar `open1'  = `open'
                clonevar `close1' = `close'

                replace `open1'  = `open1'[_n-1]  if `open1'  == .
                replace `close1' = `close1'[_n-1] if `close1' == .
                replace `close'  = `close' - 1    if `close1' > `open1'

                * remove inline /* ... */ on a single line
                count if regexm(precode, `"/\*[^(/\*).]*\*/"')
                while r(N) > 0 {
                    replace precode = ///
                        regexr(precode, `"/\*[^(/\*).]*\*/"', " ")
                    count if regexm(precode, `"/\*[^(/\*).]*\*/"')
                }

                * blank out lines inside multi-line block comments
                levelsof `open' if (`open' != `close'), local(sections)
                foreach section of local sections {
                    sum oriline if ///
                        (`open' == `section' | `close' == `section'), meanonly
                    replace precode = "" ///
                        if inrange(oriline, r(min), r(max))
                }
            }

            * ---------------------------------------------------
            * 5. Normalise whitespace; replace quote characters
            *    with safe handles so macro interpolation works
            * ---------------------------------------------------
            replace precode = ltrim(rtrim(itrim(precode)))
            replace precode = subinstr(precode, "`=char(9)'", " ", .)

            replace precode = subinstr(precode, char(96), "`lrep'", .)  // `
            replace precode = subinstr(precode, char(39), "`rrep'", .)  // '
            replace precode = subinstr(precode, char(34), "`dblq'", .)  // "

            * placeholder columns filled by _do2screen_delimit
            gen long line    = .
            gen      code    = ""
            gen      origcode = ""
        }  // end qui
    }  // end frame

end
