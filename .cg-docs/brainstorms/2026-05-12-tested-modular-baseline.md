---
date: 2026-05-12
title: "Tested Modular Baseline — Architecture and Approach"
status: decided
scope: "Standard"
chosen-approach: "Clean rewrite with golden-output tests first"
tags: [modularization, testing, refactor, do2screen]
---
<!-- Valid status values: decided, in-progress, abandoned -->

# Tested Modular Baseline — Architecture and Approach

## Context

The do2screen.ado is a ~450-line monolith (version 3.0, last updated 2017) with three modes (variables, find, range), two helper programs (do2screen_display, do2screen_aftervar), and inline parsing logic. The Tested Modular Baseline milestone aims to preserve current behavior while making the codebase testable, auditable, and easier to extend.

## Requirements

- Solo maintainer — optimize for correctness and extensibility, be aggressive.
- Minimum Stata version: 16.1 (enables frames).
- Preserve legacy return interface (s_varcode scalar, display output) for current users.
- Add new structured returns alongside legacy: r(lines) matrix, r(nlines) scalar, r(dofile) string, and a frame (fr_do2screen) with columns line, code, variable, action.
- Decompose into 6 internal programs:
  1. `_do2screen_parse` — read do-file(s), strip comments, handle #delimit, produce cleaned code in a frame
  2. `_do2screen_vartrack` — recursive variable-lineage tracer
  3. `_do2screen_find` — string search mode
  4. `_do2screen_range` — line range mode
  5. `_do2screen_display` — output formatting and display
  6. `_do2screen_return` — populate r() results, scalar, and frame
- Main do2screen.ado becomes a thin dispatcher: parse syntax → call _parse → route to mode → call _return and _display.

## Approaches Considered

### Approach 1: Rewrite-in-place (incremental extraction)

Extract internal programs one at a time from the existing do2screen.ado, testing each extraction against current behavior before moving to the next. Low risk per step but slower, and intermediate states are partially-modular.

### Approach 2: Clean rewrite with golden-output tests first

Build example do-files and capture current output as golden reference files first. Then rewrite from scratch into the 6-program architecture, validating each program against golden outputs. Legacy .ado stays untouched until the new version passes all tests.

### Approach 3: Parallel new implementation with adapter

Write the new modular version as a separate command (do2screen2) alongside the existing one, then swap names once validated. Unnecessary complexity for a solo-maintained package.

## Decision

Approach 2 selected. Rationale: tests-first gives maximum confidence in correctness for a solo maintainer. The old .ado serves as a spec during rewrite. Clean architecture from day one with no legacy debt carried forward.

## Next Steps

1. Create canonical example do-files exercising all three modes (variables, find, range) and edge cases (comments, #delimit, compound quotes, nested loops, rename, egen, foreach).
2. Run existing do2screen against examples, capture golden output files.
3. Build test harness that compares do2screen output against golden files.
4. Rewrite do2screen.ado as thin dispatcher + 6 internal programs.
5. Validate new implementation passes all golden-output tests.
6. Add structured returns (matrix, scalars, frame) alongside legacy interface.
7. Document supported and unsupported syntax patterns.
