*! Version 4.0 <12may2026>
*! Author: R.Andres Castaneda -- acastanedaa@worldbank.org
*! Author: Santiago Garriga   -- santiago.garriga@psestudent.eu
*
*  BREAKING CHANGE: requires Stata 16.1+ (was: 14).
*  Frames are used for internal data handling; lstrfun is no longer required.
*
/* *==========================================================================
Do2screen: Program to display do-files in result's screen
--------------------------------------------------------------------------
Created:  06Feb2013  (Santiago Garriga & Andres Castaneda)
Modified: 29Dec2015  (Santiago Garriga & Andres Castaneda)
Modified: 26Apr2016  (Andres Castaneda)
Modified: 15aug2017  (Andres Castaneda)
Modified: 23sep2017  (Andres Castaneda)
Modified: 12may2026  (Andres Castaneda) -- v4.0 modular rewrite
Dependencies: THE WORLD BANK
*==========================================================================*/

version 16.1

program define do2screen, rclass

    syntax  [using/],                         ///
    [                                         ///
        VARiables(string)                     ///
        find(string)                          ///
        lines(integer 5)                      ///
        range(numlist min=1 max=2)            ///
        folder(string)                        ///
        text(string)                          ///
        replace                               ///
        labels timer                          ///
        noprevious   comments                 ///
        varout(string)   nolinenumbers        ///
        lrep(string)     rrep(string)         ///
        dblq(string)     SCALARname(string)   ///
    ]

    * =========================================================
    * 1. Validate options
    * =========================================================

    qui {
        timer clear

        local aux = 0
        cap confirm existence `variables'
        if (_rc == 0) local ++aux
        cap confirm existence `find'
        if (_rc == 0) local ++aux
        cap confirm existence `range'
        if (_rc == 0) local ++aux

        if (`aux' > 1) {
            noi disp in red ///
                "Options variable, find and range are mutually exclusive." ///
                " You must chose only one of them"
            error 198
        }

        if (`aux' == 0) {
            noi disp in red ///
                "You should choose at least one option: variable, find and range."
            error 198
        }

        if (!missing("`previous'") & missing("`variables'")) {
            noi disp in red ///
                "noprevious option must be specified with variables option"
            error 198
        }
        if (!missing("`previous'") & ///
            (!missing("`find'") | !missing("`range'"))) {
            noi disp in red ///
                "noprevious option cannot be specified with option find or range"
            error 198
        }

        * =====================================================
        * 2. Set defaults
        * =====================================================

        * quote handles
        if ("`lrep'" == "") local lrep "LlLl"
        if ("`rrep'" == "") local rrep "RrRr"
        if ("`dblq'" == "") local dblq "DQDQ"

        * scalar name (default: s_varcode)
        if ("`scalarname'" == "") local scalarname "s_varcode"

        * folder: normalise path and cd
        if (`"`folder'"' != `""') {
            if regexm(`"`folder'"', `"[\]$"') ///
                local folder = reverse(substr(reverse(`"`folder'"'), 2, .))
            if regexm(`"`folder'"', `"[a-zA-Z0-9]$"') ///
                local folder "`folder'/"
            local cdir "`c(pwd)'"
            capture cd "`folder'"
            if _rc {
                noi disp as error "folder(): directory not found: `folder'"
                error 601
            }
        }

        * range: resolve start / end
        if ("`range'" != "") {
            local start: word 1 of `range'
            if (wordcount("`range'") == 1) {
                local end = `start' + `lines'
            }
            else {
                local end: word 2 of `range'
                local lines = `end' - `start'
            }
            if (`start' < 1) {
                noi disp as error "range(): start must be >= 1"
                error 198
            }
            if (`start' > `end') {
                noi disp as error "range(): start (`start') must be <= end (`end')"
                error 198
            }
        }

        * text / log option
        if ("`text'" != "") {
            tempname textfile
            if (regexm("`text'", "^.*\.txt$") == 0) local text "`text'.txt"
            log using "`text'", text name(`textfile') `replace'
        }

        * resolve do-file list
        if (`"`using'"' == `""') {
            local dofiles: dir . files "*.do"
            local dofiles: list sort dofiles  // deterministic order across OSes
        }
        else {
            local dofiles `""`using'""'
            if (substr(reverse(`dofiles'), 1, 3) != "od.") {
                local dofiles `"`dofiles'.do"'
            }
        }

        * =====================================================
        * 3. Loop over do-files
        * =====================================================

        foreach dofile of local dofiles {

            * -- header --
            noi _do2screen_display, dofile(`dofile') folder(`"`folder'"')

            * -- parse: read file, strip comments, replace quote handles --
            timer on 2
            cap noi _do2screen_parse, dofile(`dofile')   ///
                lrep(`lrep') rrep(`rrep') dblq(`dblq')  ///
                `comments'
            local parserc = _rc
            timer off 2
            if `parserc' continue

            * -- delimiter loop: populate line / code columns --
            timer on 3
            _do2screen_delimit
            timer off 3

            * -- dispatch to mode program --
            timer on 4
            if ("`variables'" != "") {
                cap noi _do2screen_vartrack,        ///
                    variables(`variables')          ///
                    lrep(`lrep') rrep(`rrep')       ///
                    dblq(`dblq')                    ///
                    `previous' `labels'             ///
                    varout(`varout')                ///
                    `linenumbers'
            }
            else if (`"`find'"' != `""') {
                cap noi _do2screen_find,            ///
                    find(`"`find'"')                ///
                    lines(`lines')                  ///
                    scalarname(`scalarname')
            }
            else if ("`range'" != "") {
                cap noi _do2screen_range,           ///
                    start(`start') end(`end')       ///
                    scalarname(`scalarname')
            }
            timer off 4
            local moderc = _rc  // capture mode sub-command rc for error propagation

            * -- structured returns (r(), _fr_do2screen) --
            if `moderc' continue  // skip return if mode sub-command failed; cleanup runs after loop
            if ("`variables'" != "") {
                cap noi _do2screen_return,              ///
                    dofile(`dofile') mode(variables)    ///
                    variables(`variables')
            }
            else if (`"`find'"' != `""') {
                cap noi _do2screen_return,              ///
                    dofile(`dofile') mode(find)
            }
            else if ("`range'" != "") {
                cap noi _do2screen_return,              ///
                    dofile(`dofile') mode(range)    ///
                    start(`start') end(`end')
            }

        }  // end foreach dofile

        * -- close log --
        if ("`text'" != "") {
            log close `textfile'
            noi disp as text `"note: results saved to `text'"'
        }

        if ("`folder'" != "") cd "`cdir'"

        if ("`timer'" != "") noi timer list

        cap frame drop _fr_do2screen_parsed  // clean up internal working frame

    }  // end qui

end

exit

><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><

* =============================================================================
* History
* =============================================================================
*! Version 4.0    <12may2026>  modular rewrite; version 16.1; drop lstrfun
*! Version 3.0    <13dec2017>
*! Version 2.4    <20nov2017>
*! Version 2.3    <23sep2017>
*! Version 2.2    <15aug2017>
*! Version 2.1    <26Apr2016>
*! Version 2.0    <29Dec2015>
*! Version 1.1    <05Mar2015>
*! Version 0.0    <06Feb2015>
