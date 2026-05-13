---
date: 2026-05-13
title: "Compound-quote scalar accumulation causes r(132) in Stata"
category: "bugs"
language: "Stata"
tags: [compound-quotes, scalar, r(132), display, macro-expansion, find-mode]
root-cause: "Accumulating multi-line text into a scalar using compound-quote string concatenation causes r(132) when the scalar value is later expanded inside a macro or display context that re-parses quotes."
severity: "P0"
---

# Compound-quote scalar accumulation causes r(132)

## Problem

In `_do2screen_find.ado` (and similar output-accumulation programs), lines of
do-file code were appended into a scalar using compound-quote concatenation:

```stata
scalar `scalarname' = `scalarname' + `"`space'`=`fline' + `i'': `lcode'"'
noi disp in y `scalarname'   // r(132) here
```

The `noi disp` call — or any macro expansion that tries to expand the full
scalar value — throws **r(132): too many characters** as the scalar grows
beyond Stata's 67,784-character macro expansion limit, or fails earlier due to
unbalanced compound-quote delimiters created by the concatenated code lines.

Symptoms observed:
- Works for short files, fails silently on longer ones
- Truncated or missing output in find mode
- Occasional `r(132)` inside `cap noi` wrapper, masked as `_rc = 132`

## Root Cause

Stata scalars can hold strings up to ~244 KB, but compound-quote macro
expansion (`\`"..."'`) is subject to a much smaller limit (~64 KB after
internal escaping). More critically, code lines fetched from a frame may
themselves contain backticks, double quotes, or compound-quote delimiters — so
repeatedly concatenating them into a single compound-quoted context corrupts
the delimiter balance.

The pattern `scalar X = X + \`"...dynamic content..."'` is unsafe when
`dynamic content` is read from arbitrary user code.

## Solution

Replace batch scalar accumulation + single `disp` with **per-line display**,
using `local` for the display line computation (not scalar concatenation):

```stata
foreach i of numlist 0/`lines' {
    local displine = `fline' + `i'
    local space: disp _dup(`=4 - length("`displine'")') " "
    local lcode: disp code[`displine']
    scalar `scalarname' = `scalarname' + ///
        `"`space'`displine': `lcode'"'    // scalar still accumulated for r() return
    noi disp in g `"`space'`displine': "' in y `"`lcode'"'  // display per-line
}
* NO final `noi disp in y `scalarname'' here
```

Key changes:
- `local displine = \`fline' + \`i'` — evaluate arithmetic once into a local,
  avoiding `\`=expr'` double-expansion inside compound quotes
- `noi disp` called once per line, not once per section — avoids accumulation limit
- Scalar accumulation is kept for `r()` return consumers but never expanded
  for display

This pattern mirrors `_do2screen_vartrack.ado` which already used per-line
display correctly.

## Prevention

- Never use `noi disp \`scalar_holding_multiline_text'` for dynamic frame content.
- The safe display pattern for frame-sourced code is always per-line:
  `local line_content: disp frame_var[row]` then `noi disp ...`.
- Scalar accumulation for `r()` returns is fine; scalar expansion for display is not.
- When refactoring display logic, check that `noi disp` is not the final
  consumer of a concatenated scalar whose content includes user code.

## Related

- `_do2screen_vartrack.ado` — correct reference implementation of per-line display
- P0.1 in `.cg-docs/reviews/2026-05-12-tested-modular-baseline-v2-thorough-review.md`
- Stata documentation: compound double quotes, string limits (`help strings`)
