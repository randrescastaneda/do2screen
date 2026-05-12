*! _do2screen_display -- display do-file header for do2screen
*! Part of do2screen v4.0 <12may2026>
*! Author: R.Andres Castaneda
*
*  Displays the do-file section header (filename + browse link + hline).
*  Called once per do-file by the main do2screen dispatcher.

version 16.1

program define _do2screen_display

    syntax , dofile(string) [folder(string)]

    noi dis as text _new "{p 4 4 2}{cmd:do-file:} " ///
        in y "  `dofile'" ///
        `"{browse "`folder'`dofile'":{space 10}Open }"' ///
        " {p_end}"
    noi dis as text "{hline 96}"

end
