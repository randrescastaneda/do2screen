// make.do is maintained manually and checked into version control.
// Execute this script to regenerate do2screen.pkg and stata.toc.
// DO NOT FORGET to update the version number when it changes.
// For more information visit http://github.com/haghish/github

version 16.1
*##s

cap program drop getfiles
program define getfiles, rclass

	args mask

	local f2add: dir . files "`mask'", respectcase

	foreach a of local f2add {
		local as "`as' `a'"
	}
	local as = trim("`as'")
	local as: subinstr local as " " ";", all

	return local files = "`as'"
end


* Working directory is set by the caller (rundo.exe uses the script's location).
* If running interactively, cd to the project root first.

if ("`c(username)'" == "wb384996") {
    cd "C:\Users\wb384996\OneDrive - WBG\ado\myados\do2screen"
}

getfiles "*.ado"
local as = "`r(files)'"

getfiles "*.sthlp"
local hs = "`r(files)'"

getfiles "*.mata"
local ms = "`r(files)'"


getfiles "*.dlg"
local ds = "`r(files)'"

getfiles "*.dta"
local dtas = "`r(files)'"


local toins  "`as';`hs';`ms';`ds';`dtas'"
disp "`toins'"


make do2screen, replace toc pkg                                  ///  readme
	version(0.5.0)                                                  ///
    license("MIT")                                                         ///
    author(`""R.Andres Castaneda" "Santiago Garriga""')                       ///
    affiliation(`" "The World Bank" "Universidad de La Plata""')                                                         ///
    email(`" "acastanedaa@worldbank.org" "garrigasantiago@gmail.com""')                     ///
    url("")                                                ///
    title("do2screen") ///
    description("Stata package that allows the user to review specific sections of a particular do-file, or set of do-files, directly in the Stata console.")        ///
    install("`toins'")                                     ///
    ancillary("")                                                         

*##e


exit

