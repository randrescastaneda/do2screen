# do2screen: Supported Syntax Patterns

This document describes what do2screen can and cannot detect when tracing variables
through a do-file. Use it to understand what output to expect and how to structure
do-files for best results.

---

## Modes of Operation

do2screen has three mutually exclusive modes:

| Mode | Option | Description |
|------|--------|-------------|
| Variables | `var(varname [varname ...])` | Traces how a variable is created and modified, following lineage through parent variables |
| Find | `find("search string")` | Shows all lines containing the search string, plus N surrounding lines |
| Range | `range(start [end])` | Shows lines between `start` and `end` (default end = start + 5) |

---

## Variables Mode: Supported Creation Commands

do2screen identifies a variable as *created* on a line if the line matches one
of these patterns:

### `gen` / `generate` / `replace`

```stata
gen income = wages + transfers
replace income = 0 if income < 0
```

Pattern: `^(.*[:]?[ ]*[a-z]+ varname[ ]*=)([ a-z0-9\.("+.*)$`

Captures any command of the form `<cmd> varname = <expression>`, including
prefixed commands (e.g., `quietly gen`, `bysort id: gen`).

### `rename`

```stata
rename gender sex
rename (inc1 inc2 inc3) (wage_a wage_b wage_c)
```

Pattern: `[ ]*ren[ame]*[ ]+\(?old_names\)?[ ]+\(?new_names\)?`

Matches both single rename and grouped rename syntax. do2screen shows the
line where the target variable name appears as the new name.

### `encode` and `destring` (gen() option)

```stata
encode educ_str, gen(edlev)
destring wage_str, gen(wage_num) force
```

Pattern: `(^.*),.*[a-z]+\(([a-zA-Z0-9_ ]*[ ]+varname|[ ]*varname)([ ]*\)|[ ]+[a-zA-Z0-9_ ]*\))`

Matches commands that create a new variable via the `gen()` option. Also
applies to other commands using `generate()` as an option name.

### `egen`

Detected by the same `gen varname =` pattern as `gen`. The `gen()` option
exception (to avoid matching `gen()` sub-option containing the variable name)
is applied: lines matching `^[ ]*(egen|gen).*,.*varname` are excluded from
gen-option detection, ensuring `egen` creation is captured correctly.

---

## Variables Mode: Lineage Tracing

After finding the line where a variable is created, do2screen extracts the
right-hand side of the expression and identifies *parent variables* — the
variables whose values feed into the target variable. It then recursively
traces those parents.

### What is extracted from the RHS

From `gen income = wages + transfers`:

1. Strip function names: `wages + transfers` (removes `func(` patterns)
2. Strip operators: `wages  transfers` (removes `+`, `-`, `*`, `/`, `>=`, etc.)
3. Strip subscripts: (removes `[varname == value]` weight expressions)
4. Strip everything before `=`: (removes LHS)
5. Strip everything after `,`: (removes if/in and options)
6. Remove decimal number tokens (e.g., `1.90`)
7. Remove pure integer tokens (e.g., `365`)
8. Remove duplicates

The result is the list of parent variable names.

### Lineage depth cap

Tracing stops after visiting 1,000 parent variables (a `J(1,1000,1)` matrix
is used as a counter). In practice no normal do-file reaches this limit.

### Circular reference detection

If variable `x` is found to both create and depend on itself (`x = f(x)`), 
do2screen displays a warning:

```
variable x presents circular creation [i.e, x = f(X)]
```

Tracing continues for other branches; the circular edge is skipped.

### Already-visited variable detection

Each variable is traced at most once per call. If a parent variable has already
been traced in the current call, the second visit is skipped silently.

---

## Variables Mode: Post-Creation Tracking

After identifying the creation line, do2screen also marks lines where the
variable is modified or referenced *after* creation:

### Drop

```stata
drop income
```

Any `drop` command matching `^[ ]*drop[ ]+[a-zA-Z0-9_ ]*varname` is shown.

### Label variable (requires `labels` option)

```stata
label variable income "Total income"
```

Pattern: `^[ ]*l(a|ab|abe|abel)[ ]+va(r|ri|ria|riab|riabl|riable)[ ]+varname[ ]+.*`

### Label values (requires `labels` option)

```stata
label values income income_lbl
```

Pattern: `^[ ]*l(a|ab|abe|abel)[ ]+val(u|ue|ues)[ ]+.*varname`

### foreach loop body expansion

```stata
foreach v of varlist income wages {
    replace `v' = `v' / cpi
}
```

If a `foreach` loop header references the variable, do2screen marks the entire
loop body (from the header `{` to the matching `}`) as selected.

---

## Variables Mode: Known Limitations

| Limitation | Notes |
|------------|-------|
| **`mata:` blocks** | Not recognized; variable creation inside Mata is not detected |
| **`program define` inside the analyzed do-file** | Not recognized as a context boundary; may produce false matches |
| **`include` directives** | do2screen reads the file literally; `include`d files are not followed |
| **Macro-generated variable names** | If a variable name is constructed dynamically (e.g., `` `prefix'`i' ``), do2screen will not resolve the macro and may miss the creation line |
| **`gen` inside `frames`** | do2screen reads the do-file as text; frame context is not tracked |
| **Comment lines containing variable names** | Star-comments (`* text`) are included in the code checked for pattern matches. Real occurrence: `* total = a + b` may match as a creation line for `total` |
| **`destring` / `tostring` without `gen()`** | In-place transformations are not detected (no new variable name on LHS) |
| **Nested `/* */` comments** | Partially handled. Single-line nested blocks (` /* inner */ `) are stripped. Multi-line nesting may not be stripped correctly |

---

## Comment Handling (default behavior)

Unless the `comments` option is specified, do2screen strips block comments before
processing. The stripping logic:

1. **Inline block comments on a single line**: `/* text */` → replaced with space (iteratively until none remain)
2. **Multi-line block comments**: Lines between an opening `/*` and its matching `*/` have their `precode` cleared

`//` inline comments and `*`-at-line-start comments are **not** stripped from `precode`.
They remain in the code shown to the user but are excluded from variable-pattern
matching by the regex anchors (patterns are anchored to the start of line or
require a specific command keyword).

The `comments` option disables all block-comment stripping.

---

## Quote Handling

To prevent Stata macro expansion from corrupting code during analysis, do2screen
replaces quote characters in the code with placeholder strings before processing
and restores them before display:

| Character | Placeholder (default) |
|-----------|-----------------------|
| `` ` `` (backtick) | `LlLl` |
| `'` (single quote) | `RrRr` |
| `"` (double quote) | `DQDQ` |

Custom placeholders can be set via `lrep()`, `rrep()`, and `dblq()` options.

**Known behavior**: In `find()` and `range()` modes, double-quote restoration is
not applied before display — so double quotes appear as `DQDQ` in the output.
In `variables()` mode, all three are restored before display.

---

## Delimiter Handling (`#delimit ;`)

do2screen handles `#delimit ;` / `#delimit cr` switching:

- In `cr` mode (default): each line is one logical statement.
- In `;` mode: statements are tokenized on `;`. Multi-line statements with
  no `;` on the current line are accumulated via a `trailcode` local until a
  `;` is found.
- Switching between `;` and `cr` within the same file is supported; the
  `#delimit` lines themselves are consumed and not shown in output.

### Continuation lines (`///`)

Not explicitly handled by the delimiter logic. `///` continuation lines appear
as separate lines in the result, each with their own line number. The parse
(comment-stripping) step treats `///` as a regular character sequence.

---

## Return Values (current version 3.0)

### Variables mode

After each `var()` analysis:

```stata
scalar s_varcode  // contains all selected lines concatenated with CRLF
```

The scalar name `s_varcode` is **hardcoded** and is not affected by the
`scalarname()` option. This is a known inconsistency (see below).

### Find mode and Range mode

```stata
scalar <scalarname>  // default: s_varcode; overridden by scalarname() option
```

The `scalarname()` option is respected in `find()` and `range()` modes. The
scalar contains all selected lines concatenated with CRLF.

### Known inconsistency: `scalarname()` option

The `scalarname()` option is ignored in `variables()` mode — the scalar is
always named `s_varcode`. In `find()` and `range()` modes the option works
as documented. This inconsistency is preserved in version 4.0 for backward
compatibility.

---

## Supported Options

| Option | Modes | Description |
|--------|-------|-------------|
| `var(varlist)` | — | Variables to trace (mutually exclusive with `find`, `range`) |
| `find(string)` | — | String to search for |
| `range(# [#])` | — | Line range to display (one or two numbers) |
| `lines(#)` | find | Number of context lines after each match (default: 5) |
| `labels` | var | Include `label variable` and `label values` lines |
| `noprevious` | var | Do not trace parent variables (show only direct creation line) |
| `varout(varname)` | var | Exclude this variable from lineage tracing |
| `comments` | all | Disable block-comment stripping |
| `nolinenumbers` | all | Suppress line number column |
| `scalarname(name)` | find, range | Name for the returned scalar (see inconsistency note) |
| `lrep(string)` | all | Replacement for backtick characters (default: `LlLl`) |
| `rrep(string)` | all | Replacement for single-quote characters (default: `RrRr`) |
| `dblq(string)` | all | Replacement for double-quote characters (default: `DQDQ`) |
| `text(filename)` | all | Save output to a text log file |
| `replace` | all | Overwrite the text log file if it exists |
| `folder(path)` | all | Change working directory before searching for do-files |
| `timer` | all | Display Stata timer output after analysis |

---

## Example Coverage

Each documented pattern has a corresponding test example in `tests/examples/`:

| Pattern | Example file |
|---------|-------------|
| `gen`, `replace` | `ex_gen_replace.do` |
| `egen` | `ex_gen_replace.do` |
| `rename` (single and grouped) | `ex_egen_rename.do` |
| `encode` with `gen()` | `ex_egen_rename.do` |
| `destring` with `gen()` | `ex_egen_rename.do` |
| Block comments, inline comments | `ex_comments_delimit.do` |
| `#delimit ;`/`cr` | `ex_comments_delimit.do` |
| `foreach` loops with variables | `ex_foreach_loops.do` |
| String search (single and multi-match) | `ex_find_targets.do` |
| Lineage tracing (shared parents) | `ex_multivar.do` |
| Circular variable reference | `ex_multivar.do` |
| Empty do-file | `ex_empty.do` |
| Comments-only do-file | `ex_comments_only.do` |
