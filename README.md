# do2screen

`do2screen` is a Stata package for reviewing specific sections of a do-file directly in the Stata console. It helps you trace how variables were built, find relevant strings with context, and inspect selected line ranges without manually scrolling through long scripts.

- Documentation site: https://randrescastaneda.github.io/do2screen/
- Source code: https://github.com/randrescastaneda/do2screen
- License: MIT

## Main features

### 1. Variable tracing

Trace the lines where a variable is created, modified, or dropped.

By default, `do2screen` also follows parent variables recursively, so if `income` depends on `wages` and `transfers`, it will also show how those were built.

```stata
do2screen using "analysis.do", var(pchincome)
```

Useful for:

- auditing derived variables
- understanding long production scripts
- reconstructing variable lineage across a project

### 2. String search with context

Find a word or phrase in a do-file and show the matching lines plus surrounding context.

```stata
do2screen using "analysis.do", find("poverty line") lines(10)
```

Useful for:

- locating definitions or comments
- finding sections related to a topic
- reviewing logic around a known string

### 3. Line range display

Display any selected block of a do-file by line number.

```stata
do2screen using "analysis.do", range(253 263)
```

Useful for:

- inspecting a narrow region of code
- sharing exact segments with collaborators
- exporting specific sections to text output

## Installation

### Recommended: install from GitHub via `github`

First install E. F. Haghish's `github` package if needed:

```stata
net install github, from("https://haghish.github.io/github/")
```

Then install `do2screen`:

```stata
github install randrescastaneda/do2screen
```

### Alternative: direct `net install`

```stata
net install do2screen, ///
	from("https://raw.githubusercontent.com/randrescastaneda/do2screen/master/") ///
	replace
```

### SSC note

`do2screen` is also available on SSC, but the SSC copy may lag behind the GitHub version. For the latest release and documentation, install from GitHub.

## Requirements

- Stata 16.1 or higher

`do2screen` v5.0 uses Stata `frames` internally.

## Quick examples

### Trace one variable

```stata
do2screen using "analysis.do", var(income)
```

### Trace one variable without parent variables

```stata
do2screen using "analysis.do", var(income) noprevious
```

### Find a string

```stata
do2screen using "analysis.do", find("poverty")
```

### Show a range of lines

```stata
do2screen using "analysis.do", range(50 75)
```

### Save output to a text file

```stata
do2screen using "analysis.do", var(income) text("output/income_trace") replace
```

## Documentation

For full usage details, examples, and option reference, see:

- https://randrescastaneda.github.io/do2screen/
- [do2screen.sthlp](do2screen.sthlp)

The site includes:

- a getting started guide
- a full reference page
- articles on variable tracing, find/range, and caveats

## Development

Repository contents include:

- `do2screen.ado` and helper `_do2screen_*.ado` files
- `do2screen.sthlp`
- `tests/` golden-file regression tests
- `docs/site/` Quarto documentation source

To run the test suite from Stata:

```stata
do "tests/run_tests.do"
```

## Authors

- R. Andres Castaneda — The World Bank
- Santiago Garriga — Universidad Nacional de La Plata

## License

This package is licensed under the MIT License. See [LICENSE](LICENSE) for details.
