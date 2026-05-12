---
date: 2026-05-12
title: "Tested Modular Baseline Implementation (revised)"
status: active
scope: "Standard"
brainstorm: ".cg-docs/brainstorms/2026-05-12-tested-modular-baseline.md"
language: "Stata"
estimated-effort: "large"
phases: 2
completed-phases: [1]
current-phase: 2
tags: [modularization, testing, refactor, do2screen, golden-output]
revision-of: ".cg-docs/plans/2026-05-12-tested-modular-baseline.md"
revision-reason: "Address 8 P1/P2 + 3 P3 findings from /cg-plan-review"
---

# Plan: Tested Modular Baseline Implementation (revised)

## Objective

Rewrite do2screen.ado into a 7-program modular architecture with full regression test coverage. Use a golden-output testing strategy: capture current behavior as reference, then rewrite and validate the new implementation produces identical output. Eliminate the `lstrfun` community dependency by replacing with native `ustrregexra()`.

## Context

The current do2screen.ado is a ~450-line file (version 3.0, 2017) containing three defined programs: `do2screen` (dispatcher + validation), `do2screen_display` (parsing + all three modes), and `do2screen_aftervar` (post-creation tracking for drops, labels, loops). The brainstorm decided on "Clean rewrite with golden-output tests first" (Approach 2). Minimum Stata version: 16.1 (bumped from 14 — breaking change for Stata 14/15 users). The new version adds structured returns (frame, matrix, scalars) alongside the legacy scalar interface.

**Known behavioral inconsistency** (preserved, not fixed): In `variables()` mode, the scalar is hardcoded as `s_varcode` regardless of the `scalarname()` option. In `find()` and `range()` modes, the scalar respects the `scalarname()` option. This inconsistency is preserved in the rewrite and tested separately.

## Requirements

| ID  | Requirement                                                                 | Source          |
|-----|-----------------------------------------------------------------------------|-----------------|
| R1  | Create canonical example do-files exercising all three modes and edge cases | brainstorm      |
| R2  | Capture golden reference output from existing do2screen against examples    | brainstorm      |
| R3  | Build test harness comparing output against golden files                    | brainstorm      |
| R4  | Decompose into 7 internal programs (_parse, _delimit, _vartrack, _aftervar, _find, _range, _display, _return) | brainstorm + P2.1 + P2.4 |
| R5  | Main do2screen.ado is a thin dispatcher                                     | brainstorm      |
| R6  | Preserve legacy return interface (s_varcode scalar, display output), including scalarname inconsistency | brainstorm + P1.4 |
| R7  | Add structured returns: r(lines) matrix, r(nlines), r(dofile), _fr_do2screen frame (line, code, variable columns — no action column) | brainstorm + P1.3 + P2.3 |
| R8  | Minimum Stata version 16.1 — document breaking change                       | brainstorm + P2.2 |
| R9  | Document supported and unsupported syntax patterns                          | brainstorm      |
| R10 | Replace all `lstrfun` calls with native `ustrregexra()`                     | P1.1            |
| R11 | All tests executable via Stata MCP connection for validation                | user            |

## Phase 1: Test Infrastructure, Examples, and Syntax Documentation

### 1. Create canonical example do-files

- **Requirements**: R1, R9
- **Files**: `tests/examples/ex_gen_replace.do`, `tests/examples/ex_egen_rename.do`, `tests/examples/ex_comments_delimit.do`, `tests/examples/ex_foreach_loops.do`, `tests/examples/ex_find_targets.do`, `tests/examples/ex_multivar.do`, `tests/examples/ex_empty.do`, `tests/examples/ex_comments_only.do`
- **Details**: Write synthetic do-files that exercise:
  - `gen`, `replace`, `egen` with simple and compound expressions
  - `rename` (single and grouped)
  - `encode`/`destring` with `gen()` option
  - Block comments (`/* */`), inline comments (`//`), `*`-at-line-start comments
  - `#delimit ;`/`cr` with multi-line statements, mid-line semicolons, and trailcode accumulation across iterations
  - `foreach` loops containing variable creation
  - Multiple variables with shared lineage (a = b + c, b = d * e)
  - Circular variable reference (a = f(a)) to test the circular-creation detection
  - String search targets (known strings at known line numbers, including multi-match with at least 3 occurrences of the same string)
  - Line ranges with known start/end content
  - Compound quotes, continuation lines (`///`)
  - Edge cases: empty do-file, do-file with only comments, single-line do-file
- **Test Scenarios**:
  - ✅ Happy path: each example produces deterministic, verifiable output
  - 🛑 Edge case: `ex_comments_delimit.do` exercises nested `/* /* */ */` and `#delimit` switching within same file
  - ❌ Error path: nonexistent do-file (for error message capture)
- **Tests**: Run existing do2screen against each example via Stata MCP; visually verify output is correct
- **Acceptance criteria**: Each example do-file runs without error through current do2screen and produces distinct, meaningful output for its target mode

### 2. Document supported syntax patterns

- **Requirements**: R9
- **Files**: `docs/supported-syntax.md`
- **Details**: Document (from reading the existing code — no rewrite dependency):
  - Supported variable-creation commands: gen, replace, egen, rename, encode, destring
  - Supported modification tracking: drop, label variable, label values, foreach loops (via `do2screen_aftervar`)
  - Comment handling: `/* */` block comments, `//` inline (stripped via `precode`), `*`-at-line-start
  - Delimiter support: `#delimit ;` / `#delimit cr` with trailcode accumulation
  - Quote handling: backtick/single-quote/double-quote replaced with handles (lrep/rrep/dblq) during processing, restored before display
  - Lineage depth cap: recursive tracing uses a 1000-element matrix (`J(1,1000,1)`)
  - Known limitations: `mata:` blocks, `program define` within analyzed do-files, `include` directives, macros that generate code at runtime, nested `/* */` comments partially handled
  - `lstrfun` dependency: currently required, will be replaced with `ustrregexra()` in rewrite
- **Test Scenarios**: N/A (documentation)
- **Tests**: Cross-check document against example do-files — every documented pattern should have a corresponding test example
- **Acceptance criteria**: A developer can determine what do2screen will and won't detect by reading this file; every documented pattern is covered by at least one example do-file from Step 1

### 3. Capture golden reference output

- **Requirements**: R2, R6, R11
- **Files**: `tests/golden/`, `tests/capture_golden.do`
- **Details**: Write a do-file (`tests/capture_golden.do`) that:
  - Runs current do2screen against each example with `text()` option to log output to `tests/golden/<example>_<mode>.txt`
  - For `variables()` mode: captures both `s_varcode` scalar AND tests with `scalarname(custom_name)` to verify the inconsistency (variables mode ignores scalarname, find/range respect it)
  - For `find()` mode: captures output with default `lines(5)` and with `lines(10)`; includes multi-match cases testing section numbering
  - For `range()` mode: captures both single-number and two-number range syntax
  - Captures error output for: nonexistent do-file, mutually exclusive options, noprevious without variables
  - Uses `capture noisily` with rc check so capture_golden.do itself cannot crash
  - Strips SMCL tags from captured output using `filefilter` for deterministic comparison
- **Test Scenarios**:
  - ✅ Happy path: golden files created for all example × mode combinations
  - 🛑 Edge case: SMCL markup stripped consistently; output deterministic across re-runs
  - ❌ Error path: capture_golden.do handles its own failures via `capture noisily`
- **Tests**: Run `capture_golden.do` via Stata MCP; verify golden files exist and are non-empty; run twice and diff to confirm determinism
- **Acceptance criteria**: `tests/golden/` contains one reference file per test case; re-running produces byte-identical files

### 4. Build regression test harness

- **Requirements**: R3, R11
- **Files**: `tests/run_tests.do`, `tests/helpers/assert_output_match.ado`
- **Details**:
  - `run_tests.do` begins with `adopath + "tests/helpers"` to make helper ado-files findable (addresses P1.2)
  - `assert_output_match.ado`: helper program that:
    - Runs do2screen with given arguments
    - Captures output to a tempfile via `text()` option
    - Strips SMCL tags from tempfile (same logic as capture_golden.do)
    - Compares against golden file line-by-line with whitespace normalization
    - Returns pass/fail via `_rc`
  - `run_tests.do`: master test runner using pass/fail counter pattern
  - Tests organized by mode: variables tests, find tests (including multi-match section numbering), range tests, error tests
  - Scalarname tests: separate test verifying variables mode uses `s_varcode` while find/range respect `scalarname()` option
  - Report format: `PASS: <test_name>` / `FAIL: <test_name>` with final `assert tests_failed == 0`
- **Test Scenarios**:
  - ✅ Happy path: all tests pass against current (unmodified) do2screen.ado
  - 🛑 Edge case: golden files accidentally modified — detect via `checksum` before comparison
  - ❌ Error path: test harness itself crashes — each test wrapped in `capture`
- **Tests**: Run `run_tests.do` via Stata MCP against current do2screen — must produce 0 failures
- **Acceptance criteria**: `run_tests.do` passes with 0 failures on the current unchanged do2screen.ado; all tests executable via Stata MCP

## Phase 2: Modular Rewrite

### 5. Implement `_do2screen_parse.ado`

- **Requirements**: R4, R8
- **Files**: `_do2screen_parse.ado`
- **Details**:
  - Input: do-file path (or list of paths), comment-handling flag, quote replacement strings (lrep, rrep, dblq)
  - Process: read file via `filefilter` + `import delimited`, strip comments (block and inline), normalize whitespace, replace quotes with handles
  - Delegates delimiter handling to `_do2screen_delimit` (Step 6)
  - Output: creates frame `_fr_do2screen_parsed` with columns: `oriline`, `oricode`, `precode`, `line`, `code`, `origcode`
  - Uses `version 16.1` and frame operations
  - Port the comment-stripping logic (current timer 2 block: ~20 lines of gen/replace with regexr)
- **Test Scenarios**:
  - ✅ Happy path: `ex_gen_replace.do` parsed correctly, frame has expected row count and code content
  - 🛑 Edge case: nested `/* /* */ */` comments, file with only comments produces frame with empty code rows
  - ❌ Error path: file doesn't exist → clear error message and rc=601
- **Tests**: Unit test via Stata MCP comparing parsed frame content against hand-verified expected values for each example do-file
- **Acceptance criteria**: For each example do-file, `_do2screen_parse` produces a frame whose `code` column matches the cleaned code that the current monolith would generate

### 6. Implement `_do2screen_delimit.ado`

- **Requirements**: R4
- **Files**: `_do2screen_delimit.ado`
- **Details**:
  - Isolated from `_do2screen_parse` due to high complexity (P2.4)
  - Input: frame with `precode` column after comment stripping
  - Process: the stateful `while` loop that handles `#delimit ;`/`cr` switching, tokenizes on `;`, accumulates trailing code (`trailcode` local) across iterations, handles mid-line semicolons
  - Output: populates `line` and `code` columns in the frame; drops rows where `line == .`; creates `origcode` clone
  - This is a direct port of the current timer 3 block (~60 lines)
- **Test Scenarios**:
  - ✅ Happy path: `ex_comments_delimit.do` correctly merges multi-line semicolon-delimited statements
  - 🛑 Edge case: `trailcode` accumulation across 3+ lines before a `;` appears; `#delimit` switching mid-file multiple times; line with only `;`
  - ❌ Error path: file ends inside a `#delimit ;` block without closing `cr` — should still produce valid output for lines seen
- **Tests**: Dedicated delimiter tests via Stata MCP — compare frame output line-by-line against hand-verified expected values for `ex_comments_delimit.do`
- **Acceptance criteria**: Delimiter handling produces identical code to current implementation for all example do-files

### 7. Implement `_do2screen_vartrack.ado` and `_do2screen_aftervar.ado`

- **Requirements**: R4, R10
- **Files**: `_do2screen_vartrack.ado`, `_do2screen_aftervar.ado`
- **Details**:
  - `_do2screen_vartrack`: recursive variable-lineage tracer
    - Input: variable name(s), parsed frame name, options (noprevious, labels, varout)
    - Process: the `while (stay == 1)` loop with regex-based identification of gen/replace/egen/rename/encode/destring, circular-reference detection, visited-variable tracking
    - Calls `_do2screen_aftervar` for post-creation tracking
    - **Replace all 4 `lstrfun` calls with `ustrregexra()`** (P1.1):
      - `lstrfun tofind, regexr(..., "[a-zA-Z]+\(", "")` → `local tofind = ustrregexra("`tofind'", "[a-zA-Z]+\(", "")`
      - `lstrfun tofind, regexr(..., " \[...]", "")` → `local tofind = ustrregexra("`tofind'", " \[...\]", "")`
      - `lstrfun tofind, regexr(..., "^.*=", "")` → `local tofind = ustrregexra("`tofind'", "^.*=", "")`
      - `lstrfun tofind, regexr(..., ",.*", "")` → `local tofind = ustrregexra("`tofind'", ",.*", "")`
    - Lineage depth cap of 1000 preserved: `matrix D = J(1,1000,1)` (P3.1)
    - Output: marks `selection` column in the parsed frame; populates local macros with lineage chain
  - `_do2screen_aftervar`: separated as its own program (P2.1) — post-creation tracking
    - Input: variable name, options (labels, maxline)
    - Process: marks lines for `drop`, `label variable`, `label values`, and `foreach` loop body expansion
    - Direct port of current `do2screen_aftervar` (~50 lines)
- **Test Scenarios**:
  - ✅ Happy path: `var(income)` in `ex_gen_replace.do` identifies correct creation and modification lines
  - 🛑 Edge case: circular variable reference (a = f(a)) produces warning not crash; variable not found → empty selection; variables used as both creator and created
  - ❌ Error path: variable name matches a Stata keyword — no crash, empty result
- **Tests**: Compare selected line numbers against golden output for each variable-mode test case via Stata MCP; verify `lstrfun` replacement produces identical results by running examples through both old and new code
- **Acceptance criteria**: For all existing golden tests using `variables()`, the new tracker selects identical lines; `lstrfun` is not called anywhere in the new code

### 8. Implement `_do2screen_find.ado` and `_do2screen_range.ado`

- **Requirements**: R4
- **Files**: `_do2screen_find.ado`, `_do2screen_range.ado`
- **Details**:
  - `_do2screen_find`: input is search string(s) + lines count + parsed frame. Marks matching lines and subsequent N lines in `selection`. Handles the section counter for multi-match display.
  - `_do2screen_range`: input is start/end line numbers + parsed frame. Marks range in `selection`.
  - Port of existing find (~40 lines with section numbering) and range (~20 lines) logic
- **Test Scenarios**:
  - ✅ Happy path: find("Poverty") with lines(5) in `ex_find_targets.do` matches golden
  - 🛑 Edge case: search string not found → "nothing found" message; range exceeds file length; multi-match with 3+ occurrences verifying section numbering (P3.2); find with compound-quoted sentence search
  - ❌ Error path: empty find string, range with start > end
- **Tests**: Golden-output comparison for find and range test cases via Stata MCP
- **Acceptance criteria**: Identical output to current implementation for all find/range golden tests; section numbering verified for multi-match cases

### 9. Implement `_do2screen_display.ado` and `_do2screen_return.ado`

- **Requirements**: R4, R6, R7
- **Files**: `_do2screen_display.ado`, `_do2screen_return.ado`
- **Details**:
  - `_do2screen_display`: takes parsed frame with `selection` marks, mode (var/find/range), and display options (linenumbers, timer). Produces the formatted SMCL output to screen. Handles the header lines, separators, browse links. Format must be pixel-identical to current output.
  - `_do2screen_return`: populates:
    - Legacy: `scalar s_varcode` hardcoded in variables mode (preserving inconsistency — P1.4); `` scalar `scalarname' `` in find/range modes
    - New: `r(lines)` matrix of selected line numbers, `r(nlines)` scalar, `r(dofile)` string
    - New: frame `_fr_do2screen` (underscore-prefixed per P2.3) with columns `line`, `code`, `variable` — **no `action` column** (descoped to Milestone 3 per P1.3)
  - Frame `_fr_do2screen` is created fresh each call (`cap frame drop _fr_do2screen`)
- **Test Scenarios**:
  - ✅ Happy path: display output matches golden files; r() values accessible after call; frame queryable
  - 🛑 Edge case: empty selection (nothing found) → informative message, empty frame with 0 rows, r(nlines)=0
  - ❌ Error path: frame name collision with existing user frame → `cap frame drop` guard handles it
- **Tests**: Golden-output comparison for display via Stata MCP; programmatic check of r() values and frame contents; scalarname inconsistency test: verify `variables()` returns `s_varcode`, `find()` respects `scalarname(custom)`
- **Acceptance criteria**: Legacy display and scalar output identical to golden (including scalarname behavior); frame and matrix correctly populated

### 10. Rewrite `do2screen.ado` as thin dispatcher

- **Requirements**: R5, R6, R7, R8
- **Files**: `do2screen.ado` (overwrite existing)
- **Details**:
  - `version 16.1` (breaking change from version 14 — P2.2)
  - `program define do2screen, rclass`
  - Same `syntax` as current (backward compatible options)
  - Validation: mutual exclusivity of var/find/range, noprevious constraints — same error messages
  - Flow: `_do2screen_parse` → `_do2screen_delimit` → route to `_vartrack`/`_find`/`_range` → `_do2screen_return` → `_do2screen_display`
  - Folder handling, text-file logging, timer functionality preserved
  - Version header: `*! Version 4.0 <12may2026>`
  - Header comment documents the version 16.1 requirement and breaking change from version 14
  - Graceful failure when internal program is missing: `cap which _do2screen_parse` with informative error
- **Test Scenarios**:
  - ✅ Happy path: all golden-output tests pass with new dispatcher
  - 🛑 Edge case: all existing options still work (labels, comments, lrep/rrep/dblq, scalarname, nolinenumbers, timer, text, replace, folder)
  - ❌ Error path: missing internal program → clear error message naming the missing `.ado`
- **Tests**: Run full `tests/run_tests.do` via Stata MCP — must pass with 0 failures
- **Acceptance criteria**: Full golden-output regression suite passes; new structured returns verified; no `lstrfun` dependency

## Testing Strategy

- **Golden-output tests**: Primary strategy. Capture current behavior → validate new implementation reproduces it exactly.
- **Unit tests per module**: Each `_do2screen_*.ado` has standalone verification before integration.
- **Pass/fail counter pattern**: Standard Stata test harness with final `assert tests_failed == 0`.
- **Determinism**: All example do-files use synthetic content — no external data dependencies.
- **SMCL stripping**: Golden capture and test comparison both strip SMCL tags for environment-independent comparison.
- **Scalarname inconsistency**: Dedicated test verifying variables mode uses hardcoded `s_varcode` while find/range respect `scalarname()`.
- **Delimiter stress test**: Dedicated test for `#delimit ;` trailcode accumulation across multi-line blocks.
- **Regression guard**: `tests/run_tests.do` is the gate for merging the branch.
- **Stata MCP**: All tests run via Stata MCP connection for immediate validation during development.

## Documentation Checklist

- [ ] Version header in do2screen.ado (`*! Version 4.0`) with breaking-change note
- [ ] Internal program headers in each `_do2screen_*.ado`
- [ ] `docs/supported-syntax.md` for users and maintainer (Phase 1 — Step 2)
- [ ] Update `do2screen.sthlp` with new returned results section and version 16.1 requirement
- [ ] Update README.md with architecture overview

## Risks & Mitigations

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Golden output captures SMCL formatting that's environment-dependent | Medium | Test flakiness | Strip SMCL tags in both capture and comparison; compare semantic content only |
| Variable-tracing regex changes behavior subtly during port | Medium | Silent regression | Line-number-level comparison between old and new for all test cases |
| `ustrregexra()` behaves differently from `lstrfun regexr()` on edge-case patterns | Low | Incorrect variable identification | Test all 4 lstrfun replacement patterns against known inputs before full integration; verified in Stata 19 that `ustrregexra` works correctly |
| Frame name collision with user data | Low | User confusion | Use underscore-prefixed names (`_fr_do2screen`, `_fr_do2screen_parsed`) with `cap frame drop` guard |
| Version bump from 14 to 16.1 breaks users on Stata 14/15 | Medium | User breakage | Document in version header, .sthlp, and README; no fallback — frames require 16.1 |
| `#delimit ;` trailcode port introduces regression | Medium | Incorrect code reconstruction | Dedicated delimiter stress test; isolated `_do2screen_delimit` helper for focused testing |

## Out of Scope

- `action` column in result frame (deferred to Milestone 3 — requires new classification logic, not a port)
- Frames-aware tracing (Milestone 3)
- Multi-do-file tracing (Milestone 3)
- Performance optimization (Milestone 4)
- Expanded .sthlp rewrite (Milestone 4 — only add new Saved Results section here)
- Standardizing the scalarname inconsistency (would be a behavioral change — deferred)
- Any change to the external user-facing syntax/options
