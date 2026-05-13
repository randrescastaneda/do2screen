---
date: 2026-05-12
title: "Tested Modular Baseline Implementation"
status: archived
archived-reason: "Superseded by 2026-05-12-tested-modular-baseline-v2.md after /cg-plan-review surfaced 11 P1/P2/P3 findings"
scope: "Standard"
brainstorm: ".cg-docs/brainstorms/2026-05-12-tested-modular-baseline.md"
language: "Stata"
estimated-effort: "large"
phases: 2
tags: [modularization, testing, refactor, do2screen, golden-output]
---

# Plan: Tested Modular Baseline Implementation

## Objective

Rewrite do2screen.ado into a 6-program modular architecture with full regression test coverage. Use a golden-output testing strategy: first capture current behavior as reference, then rewrite and validate the new implementation produces identical output.

## Context

The current do2screen.ado is a ~450-line monolith (version 3.0, 2017) with three modes (variables, find, range). The brainstorm decided on "Clean rewrite with golden-output tests first" (Approach 2). Minimum Stata version: 16.1. The new version adds structured returns (frame, matrix, scalars) alongside the legacy scalar interface.

## Requirements

| ID  | Requirement                                                                 | Source     |
|-----|-----------------------------------------------------------------------------|------------|
| R1  | Create canonical example do-files exercising all three modes and edge cases | brainstorm |
| R2  | Capture golden reference output from existing do2screen against examples    | brainstorm |
| R3  | Build test harness comparing output against golden files                    | brainstorm |
| R4  | Decompose into 6 internal programs (_parse, _vartrack, _find, _range, _display, _return) | brainstorm |
| R5  | Main do2screen.ado is a thin dispatcher                                     | brainstorm |
| R6  | Preserve legacy return interface (s_varcode scalar, display output)          | brainstorm |
| R7  | Add structured returns: r(lines) matrix, r(nlines), r(dofile), fr_do2screen frame | brainstorm |
| R8  | Minimum Stata version 16.1                                                  | brainstorm |
| R9  | Document supported and unsupported syntax patterns                          | brainstorm |

## Phase 1: Test Infrastructure and Examples

### 1. Create canonical example do-files

- **Requirements**: R1
- **Files**: `tests/examples/ex_gen_replace.do`, `tests/examples/ex_egen_rename.do`, `tests/examples/ex_comments_delimit.do`, `tests/examples/ex_foreach_loops.do`, `tests/examples/ex_find_targets.do`, `tests/examples/ex_multivar.do`
- **Details**: Write synthetic do-files that exercise:
  - `gen`, `replace`, `egen` with simple and compound expressions
  - `rename` (single and grouped)
  - `encode`/`destring` with `gen()` option
  - Block comments (`/* */`), inline comments (`//`), `#delimit ;`/`cr`
  - `foreach` loops containing variable creation
  - Multiple variables with shared lineage (a = b + c, b = d * e)
  - String search targets (known strings at known line numbers)
  - Line ranges with known start/end content
  - Compound quotes, nested macros, continuation lines (`///`)
- **Test Scenarios**:
  - ✅ Happy path: each example produces deterministic, verifiable output
  - 🛑 Edge case: empty do-file, do-file with only comments, single-line do-file
  - ❌ Error path: do-file that doesn't exist (for error message capture)
- **Tests**: Run existing do2screen against each example; visually verify output is correct
- **Acceptance criteria**: Each example do-file runs without error and produces distinct, meaningful output for its target mode

### 2. Capture golden reference output

- **Requirements**: R2
- **Files**: `tests/golden/`, `tests/capture_golden.do`
- **Details**: Write a do-file (`tests/capture_golden.do`) that:
  - Runs current do2screen against each example with `text()` option to log output
  - Also captures `s_varcode` scalar content to a file
  - Stores golden output in `tests/golden/<example>_<mode>.txt`
  - Captures error messages for invalid inputs
- **Test Scenarios**:
  - ✅ Happy path: golden files created for all example × mode combinations
  - 🛑 Edge case: output contains SMCL markup — must strip or preserve consistently
  - ❌ Error path: capture_golden.do itself fails — use `capture noisily` with rc check
- **Tests**: Verify golden files exist and are non-empty after running capture_golden.do
- **Acceptance criteria**: `tests/golden/` contains one reference file per test case, deterministic across re-runs

### 3. Build regression test harness

- **Requirements**: R3
- **Files**: `tests/run_tests.do`, `tests/helpers/assert_output_match.ado`
- **Details**:
  - `assert_output_match.ado`: helper program that runs do2screen with given arguments, captures output to a tempfile, compares against a golden file byte-by-byte (or line-by-line with whitespace normalization)
  - `run_tests.do`: master test runner using pass/fail counter pattern (from skill reference)
  - Tests organized by mode: variables tests, find tests, range tests, error tests
  - Report format: `PASS: <test_name>` / `FAIL: <test_name>` with final assert
- **Test Scenarios**:
  - ✅ Happy path: all tests pass against current (unmodified) do2screen.ado
  - 🛑 Edge case: golden files accidentally modified — detect via checksum
  - ❌ Error path: test harness itself crashes — use `capture` around each test
- **Tests**: Run `run_tests.do` against current do2screen — must produce 0 failures
- **Acceptance criteria**: `run_tests.do` passes with 0 failures on the current unchanged do2screen.ado

## Phase 2: Modular Rewrite

### 4. Implement `_do2screen_parse.ado`

- **Requirements**: R4, R8
- **Files**: `_do2screen_parse.ado`
- **Details**:
  - Input: do-file path (or list of paths), comment-handling flag, quote replacement strings
  - Process: read file via `filefilter` + `import delimited`, strip comments (block and inline), handle `#delimit ;`/`cr`, normalize whitespace, replace quotes with handles
  - Output: creates frame `fr_do2screen_parsed` with columns: `oriline`, `oricode`, `precode`, `line`, `code`
  - Uses `version 16.1` and frame operations instead of `preserve`
  - Port the comment-stripping logic (current timer 2 block) and delimiter handling (current timer 3 block)
- **Test Scenarios**:
  - ✅ Happy path: `ex_gen_replace.do` parsed correctly, frame has expected row count and code content
  - 🛑 Edge case: nested `/* /* */ */` comments, `#delimit` switching mid-line
  - ❌ Error path: file doesn't exist → clear error message and rc=601
- **Tests**: Unit test comparing parsed frame content against hand-verified expected values for each example do-file
- **Acceptance criteria**: For each example do-file, `_do2screen_parse` produces a frame whose `code` column matches the cleaned code that the current monolith would generate

### 5. Implement `_do2screen_vartrack.ado`

- **Requirements**: R4
- **Files**: `_do2screen_vartrack.ado`
- **Details**:
  - Input: variable name(s), parsed frame name, options (noprevious, labels, varout)
  - Process: recursive lineage tracing — the `while (stay == 1)` loop with regex-based identification of gen/replace/egen/rename/encode/destring, circular-reference detection, `do2screen_aftervar` logic (drop, labels, foreach loops)
  - Output: marks `selection` column in the parsed frame; populates local macros with lineage chain
  - Must handle: multiple variables in one call, varout exclusion, circular references gracefully
- **Test Scenarios**:
  - ✅ Happy path: `var(income)` in `ex_gen_replace.do` identifies correct creation and modification lines
  - 🛑 Edge case: circular variable reference (a = f(a)), variable not found in file
  - ❌ Error path: variable name matches a Stata keyword — no crash, empty result
- **Tests**: Compare selected line numbers against golden output for each variable-mode test case
- **Acceptance criteria**: For all existing golden tests using `variables()`, the new tracker selects identical lines

### 6. Implement `_do2screen_find.ado` and `_do2screen_range.ado`

- **Requirements**: R4
- **Files**: `_do2screen_find.ado`, `_do2screen_range.ado`
- **Details**:
  - `_do2screen_find`: input is search string(s) + lines count + parsed frame. Marks matching lines and subsequent N lines in `selection`.
  - `_do2screen_range`: input is start/end line numbers + parsed frame. Marks range in `selection`.
  - Both are straightforward extractions of existing logic (~30 lines each)
- **Test Scenarios**:
  - ✅ Happy path: find("Poverty") with lines(5) in `ex_find_targets.do` matches golden
  - 🛑 Edge case: search string not found, range exceeds file length
  - ❌ Error path: empty find string, range with start > end
- **Tests**: Golden-output comparison for find and range test cases
- **Acceptance criteria**: Identical output to current implementation for all find/range golden tests

### 7. Implement `_do2screen_display.ado` and `_do2screen_return.ado`

- **Requirements**: R4, R6, R7
- **Files**: `_do2screen_display.ado`, `_do2screen_return.ado`
- **Details**:
  - `_do2screen_display`: takes parsed frame with `selection` marks, mode (var/find/range), and display options (linenumbers, timer). Produces the formatted SMCL output to screen. Handles the header lines, separators, browse links.
  - `_do2screen_return`: populates:
    - Legacy: `scalar s_varcode` (or user-specified scalar name)
    - New: `r(lines)` matrix of selected line numbers, `r(nlines)` scalar, `r(dofile)` string
    - New: frame `fr_do2screen` with columns `line`, `code`, `variable`, `action` (gen/replace/drop/rename/find/range)
  - Frame `fr_do2screen` is created fresh each call (`cap frame drop fr_do2screen`)
- **Test Scenarios**:
  - ✅ Happy path: display output matches golden files; r() values accessible after call
  - 🛑 Edge case: very long lines (>244 char Stata string limit in older versions — not an issue at 16.1 with strL)
  - ❌ Error path: empty selection (nothing found) — display informative message, return empty frame
- **Tests**: Golden-output comparison for display; programmatic check of r() values and frame contents
- **Acceptance criteria**: Legacy display and scalar output identical to golden; frame and matrix correctly populated

### 8. Rewrite `do2screen.ado` as thin dispatcher

- **Requirements**: R5, R6, R7, R8
- **Files**: `do2screen.ado` (overwrite existing)
- **Details**:
  - `version 16.1`
  - `program define do2screen, rclass`
  - Same `syntax` as current (backward compatible options)
  - Validation: mutual exclusivity of var/find/range, noprevious constraints
  - Flow: `_do2screen_parse` → route to `_vartrack`/`_find`/`_range` → `_do2screen_return` → `_do2screen_display`
  - Folder handling, text-file logging, timer functionality preserved
  - Version header: `*! Version 4.0 <12may2026>`
- **Test Scenarios**:
  - ✅ Happy path: all golden-output tests pass with new dispatcher
  - 🛑 Edge case: all existing options still work (labels, comments, lrep/rrep/dblq, scalarname, nolinenumbers)
  - ❌ Error path: graceful failure when internal program is missing (clear error message)
- **Tests**: Run full `tests/run_tests.do` — must pass with 0 failures
- **Acceptance criteria**: Full golden-output regression suite passes; new structured returns verified

### 9. Document supported syntax patterns

- **Requirements**: R9
- **Files**: `docs/supported-syntax.md`
- **Details**: Document:
  - Supported variable-creation commands: gen, replace, egen, rename, encode, destring
  - Supported modification tracking: drop, label variable, label values, foreach loops
  - Comment handling: `/* */`, `//`, `*`-at-line-start
  - Delimiter support: `#delimit ;` / `#delimit cr`
  - Known limitations: `mata:` blocks, `program define` within analyzed do-files, `include` directives, macros that generate code at runtime
  - Quote handling: compound quotes, local macro expansion not supported
- **Test Scenarios**: N/A (documentation)
- **Tests**: N/A
- **Acceptance criteria**: A developer can determine what do2screen will and won't detect by reading this file

## Testing Strategy

- **Golden-output tests**: Primary strategy. Capture current behavior → validate new implementation reproduces it exactly.
- **Unit tests per module**: Each `_do2screen_*.ado` has standalone verification before integration.
- **Pass/fail counter pattern**: Standard Stata test harness with final `assert tests_failed == 0`.
- **Determinism**: All example do-files use synthetic content — no external data dependencies.
- **Regression guard**: `tests/run_tests.do` is the gate for merging the branch.

## Documentation Checklist

- [ ] Version header in do2screen.ado (`*! Version 4.0`)
- [ ] Internal program headers in each `_do2screen_*.ado`
- [ ] `docs/supported-syntax.md` for users and maintainer
- [ ] Update `do2screen.sthlp` with new returned results section
- [ ] Update README.md with architecture overview

## Risks & Mitigations

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Golden output captures SMCL formatting that's environment-dependent | Medium | Test flakiness | Strip SMCL tags before comparison; compare semantic content |
| Variable-tracing regex changes behavior subtly during port | Medium | Silent regression | Line-number-level comparison between old and new for all test cases |
| `lstrfun` dependency (community command) not portable | Low | Build failure on clean machine | Document dependency; consider replacing with native `ustrregexra` in 16.1+ |
| Frame name collision with user data | Low | User confusion | Use prefixed name `_fr_do2screen` with `cap frame drop` guard |

## Out of Scope

- Frames-aware tracing (Milestone 3)
- Multi-do-file tracing (Milestone 3)
- Performance optimization (Milestone 4)
- Expanded .sthlp rewrite (Milestone 4 — only add new Saved Results section here)
- Any change to the external user-facing syntax/options
