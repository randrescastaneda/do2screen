* This do-file contains only comments — no executable code.
* Used for: edge-case testing of comment stripping in do2screen

* Line 3: star-comment at column 1
*   Line 4: star-comment with leading spaces

/* Block comment spanning
   multiple lines — should be stripped entirely */

// Inline-style comment (Stata 11+)

/* Another block comment
   with /* no proper nesting */ but still valid syntax */

* Final comment line — nothing below
