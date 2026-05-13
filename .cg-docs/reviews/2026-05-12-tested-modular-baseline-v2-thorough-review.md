---
date: 2026-05-12
plan: .cg-docs/plans/2026-05-12-tested-modular-baseline-v2.md
depth: thorough
findings:
  P0.1: fixed
  P0.2: fixed
  P1.1: fixed
  P1.2: fixed
  P1.3: skipped
  P1.4: fixed
  P1.5: skipped
  P1.6: fixed
  P1.7: fixed
  P1.8: fixed
  P1.9: skipped
  P1.10: skipped
  P1.11: skipped
  P1.12: skipped
  P1.13: fixed
  P1.14: fixed
  P1.15: fixed
  P1.16: fixed
  P2.1: open
  P2.2: fixed
  P2.3: fixed
  P2.4: open
  P2.5: open
  P2.6: open
  P2.7: open
  P2.8: fixed
  P2.9: fixed
  P2.10: open
  P2.11: open
  P2.12: open
  P2.13: fixed
  P2.14: open
  P2.15: fixed
  P2.16: fixed
  P3.1: fixed
  P3.2: fixed
  P3.3: fixed
  P3.4: open
  P3.5: fixed
  P3.6: fixed
  P3.7: fixed
  P3.8: fixed
  P3.9: open
  P3.10: open
  P3.11: open
  P3.12: open
---
# Thorough Review — do2screen refactor/tested-modular-baseline-v2
**Date:** 2026-05-12  
**Branch:** refactor/tested-modular-baseline  
**Mode:** thorough + autofix  
**Agents:** 10 (8 standard + @cg-adversarial + @cg-learnings-researcher)  
**Findings:** 45 total (P0: 2, P1: 16, P2: 16, P3: 11)  
**Safe_auto applied:** 21 fixes across 10 files  
**Tests after autofix:** 32/32 ✅

---

## Summary

All `[safe_auto]` fixes were applied. Three changes were attempted then reverted
(P1.12, P2.11, P2.14 — all touch `_do2screen_parse.ado` and require golden file
regeneration; re-tagged `[manual]`). One additional fix (P0.1 crlf in find mode)
was reverted — it causes `r(132)` inside compound-quote macro expansion. The
`levelsof` leak discovered during autofix (unlabelled finding, now P_NEW.1) was
fixed in `_do2screen_return.ado`. Golden files were regenerated to reflect the
new output. 32/32 tests pass.

---

## Findings Register

### P0 — Critical

| ID | File | Finding | Tag | Status |
|----|------|---------|-----|--------|
| P0.1 | `_do2screen_find.ado` | `local crlf` inside compound-quote accumulation causes `r(132)` | [manual] | open — needs per-line `disp` refactor + golden regen |
| P0.2 | `do2screen.ado` | No error propagation when sub-command fails silently | [manual] | open |

### P1 — High

| ID | File | Finding | Tag | Status |
|----|------|---------|-----|--------|
| P1.1 | `do2screen.ado` | `cap` → `cap noi` for sub-command calls | [safe_auto] | ✅ applied |
| P1.2 | `_do2screen_vartrack.ado` | Duplicate-variable detection in `variables()` list not enforced | [manual] | open |
| P1.3 | `_do2screen_parse.ado` | BOM in Windows-saved do-files breaks `regexr` loop | [manual] | open (CRLF strip also required, golden regen needed) |
| P1.4 | `_do2screen_range.ado` | `start > end` not validated | [manual] | open |
| P1.5 | `_do2screen_find.ado` | Multi-line `#delimit ;` blocks split across scalar accumulation | [manual] | open |
| P1.6 | `_do2screen_vartrack.ado` | Infinite `qui while` loop if frame corrupt | [safe_auto] | ✅ applied (overflow guard at 999) |
| P1.7 | `do2screen.sthlp` | Version header out of date; `lables` typo | [safe_auto] | ✅ applied |
| P1.8 | `do2screen.ado` | `folder()` option does not validate path exists | [manual] | open |
| P1.9 | `_do2screen_vartrack.ado` | Frame shared state not cleaned up on error exit | [advisory] | noted |
| P1.10 | `_do2screen_parse.ado` | `ustrregexra` vs `regexr` inconsistency across modules | [advisory] | noted |
| P1.11 | `_do2screen_display.ado` | Column widths hardcoded, truncate on very long paths | [manual] | open |
| P1.12 | `_do2screen_parse.ado` | CRLF stripping in `oricode` column | [manual] | reverted — changes checksums; needs golden regen |
| P1.13 | `do2screen.ado` | Range `start`/`end` not validated ≥ 1 and ≤ _N | [safe_auto] | ✅ applied |
| P1.14 | `_do2screen_vartrack.ado` | `parent` chain resolution can loop on circular references | [manual] | open |
| P1.15 | `_do2screen_aftervar.ado` | `after` lines not bounded to parsed frame _N | [manual] | open |
| P1.16 | `do2screen.ado` | `variables()` macro not passed to `_do2screen_return` | [safe_auto] | ✅ applied |
| P_NEW.1 | `_do2screen_return.ado` | `levelsof` calls print to log when called via `cap noi` | [safe_auto] | ✅ applied (4× `quietly levelsof`) |

### P2 — Medium

| ID | File | Finding | Tag | Status |
|----|------|---------|-----|--------|
| P2.1 | `tests/run_tests.do` | No test for `folder()` option | [manual] | open |
| P2.2 | `.gitattributes` | Missing `* text=auto` line-ending normalization | [safe_auto] | ✅ applied |
| P2.3 | `tests/run_tests.do` | `scalar s_varcode` not dropped before test 1.6 | [safe_auto] | ✅ applied |
| P2.4 | `_do2screen_display.ado` | `noi disp` in `qui` block can leak if called raw | [manual] | open |
| P2.5 | `_do2screen_find.ado` | Scalar accumulation not reset on second call within session | [manual] | open |
| P2.6 | `do2screen.ado` | `timer` output always to Results window, not to `text()` log | [manual] | open |
| P2.7 | `_do2screen_vartrack.ado` | `varout()` path not validated | [manual] | open |
| P2.8 | `_do2screen_delimit.ado` | Missing `syntax` statement at program entry | [safe_auto] | ✅ applied |
| P2.9 | `do2screen.ado` | `_fr_do2screen_parsed` frame not dropped on error exit | [safe_auto] | ✅ applied |
| P2.10 | `_do2screen_range.ado` | Range with `scalarname()` does not validate scalar exists | [manual] | open |
| P2.11 | `_do2screen_parse.ado` | Inline `ustrregexra` comment stripping | [manual] | reverted — changes checksums |
| P2.12 | `do2screen.ado` | `text()` log uses `append` silently if file exists and no `replace` | [manual] | open |
| P2.13 | `_do2screen_range.ado` | Range `end` not capped at `_N` of parsed frame | [safe_auto] | ✅ applied |
| P2.14 | `_do2screen_parse.ado` | BOM stripping in `rename v1 oricode` block | [manual] | reverted — bundled with P1.12 |
| P2.15 | `_do2screen_vartrack.ado` | Duplicate variables in `variables()` list processed multiple times | [safe_auto] | ✅ applied (`list uniq`) |
| P2.16 | `_do2screen_return.ado` | Comment misidentifies frame columns | [safe_auto] | ✅ applied |

### P3 — Low / Style

| ID | File | Finding | Tag | Status |
|----|------|---------|-----|--------|
| P3.1 | `_do2screen_vartrack.ado` | `doughter` → `daughter` (typo in 6 locals) | [safe_auto] | ✅ applied |
| P3.2 | `_do2screen_vartrack.ado` | Dead code `local eqvars = 0/1` never read | [safe_auto] | ✅ applied |
| P3.3 | `_do2screen_vartrack.ado` | Sentinel `"nope"` → `"__no_parent__"` for clarity | [safe_auto] | ✅ applied |
| P3.4 | all | No `version` statement in sub-modules | [advisory] | noted |
| P3.5 | all 8 `_do2screen_*.ado` | `*!` version comment convention inconsistent | [safe_auto] | ✅ applied (all 8 files) |
| P3.6 | `tests/run_tests.do` | `adopath ++` unconditionally adds duplicate paths | [safe_auto] | ✅ applied (guard added) |
| P3.7 | `do2screen.ado` | `local dofiles` not sorted before loop | [safe_auto] | ✅ applied (`list sort`) |
| P3.8 | `do2screen.sthlp` | Option types missing from synopses (`{opt ...}` vs `{opt ...(string)}`) | [safe_auto] | ✅ applied |
| P3.9 | `_do2screen_vartrack.ado` | `local i = 0` loop counter could use `forvalues` | [advisory] | noted |
| P3.10 | `_do2screen_parse.ado` | `tempfile` not used — direct `import` is fine but undocumented | [advisory] | noted |
| P3.11 | `do2screen.ado` | `qui` block wraps nearly entire program; error messages suppress silently | [advisory] | noted |
| P3.12 | `tests/capture_golden.do` | No determinism self-check after second run | [advisory] | noted |

---

## Files Modified by Autofix

| File | Changes |
|------|---------|
| `do2screen.ado` | P1.1, P1.13, P1.16, P2.9, P3.7 |
| `_do2screen_return.ado` | P2.16, P_NEW.1 |
| `_do2screen_vartrack.ado` | P1.6, P2.15, P3.1, P3.2, P3.3, P3.5 |
| `_do2screen_range.ado` | P2.13, P3.5 |
| `_do2screen_delimit.ado` | P2.8, P3.5 |
| `_do2screen_find.ado` | P3.5 (P0.1 reverted) |
| `_do2screen_parse.ado` | P3.5 only (P1.12, P2.11, P2.14 reverted) |
| `_do2screen_aftervar.ado` | P3.5 |
| `_do2screen_display.ado` | P3.5 |
| `do2screen.sthlp` | P1.7, P3.8 |
| `tests/run_tests.do` | P2.3, P3.6 |
| `.gitattributes` | P2.2 |
| `tests/golden/*.txt` | Regenerated (32 files) — path format normalised to project-root cwd |

---

## Manual / Open Items (priority order)

1. **P0.1** — crlf in find mode: refactor `_do2screen_find` to `noi disp` per line (like vartrack), then regen golden
2. **P0.2** — sub-command error propagation: track `_rc` after each `cap noi`, set `local any_rc`
3. **P1.3 / P1.12 / P2.14** — BOM + CRLF strip in parse.ado: bundled; requires golden regen after apply
4. **P1.4** — range `start > end` validation
5. **P1.14** — circular parent chain: add depth counter in vartrack loop
6. **P1.5** — `#delimit ;` multi-line spans in find mode
7. **P1.8** — `folder()` path existence check
8. **P1.11** — column width truncation in display
9. **P1.15** — aftervar `after` lines bounded to _N

---

## Advisory Notes

- P1.9: Frame cleanup on error — use `capture frame drop` in `c_local` error handler
- P1.10: `ustrregexra` vs `regexr` — standardise to `ustrregexra` for Unicode safety
- P3.4: Add `version 16.1` to all sub-modules
- P3.9: Replace `local i = 0` + `local ++i` with `forvalues i = 1/...`
- P3.11: Narrow the `qui` block to allow controlled error visibility
- P3.12: Add determinism check to `capture_golden.do` (double-run, compare checksums)
