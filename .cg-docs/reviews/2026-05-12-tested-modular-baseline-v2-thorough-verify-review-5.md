---
date: 2026-05-13
depth: light
parent-review: .cg-docs/reviews/2026-05-12-tested-modular-baseline-v2-thorough-review.md
type: verification
findings:
  P3.1: fixed
---

## Verify Review Report — do2screen (verify-5)

**Date**: 2026-05-13
**Mode**: verify (pass 5 — following verify-4 fix-triage)
**Prior review**: `.cg-docs/reviews/2026-05-12-tested-modular-baseline-v2-thorough-review.md`
**Depth**: light
**Agents**: @cg-code-quality, @cg-testing
**Files reviewed**: 5 (+7 golden .txt files)
**Findings**: 1 (P0: 0, P1: 0, P2: 0, P3: 1)

---

### Fixes verified this pass

| Finding | File | Description | Result |
|---------|------|-------------|--------|
| P0.1 | `_do2screen_find.ado` | Per-line `noi disp` refactor replacing compound-quote scalar accumulation | ✅ correct |
| P0.2 | `do2screen.ado` | `local moderc = _rc` + `if \`moderc' continue` skips return block on sub-command failure | ✅ correct |
| P1.8 | `do2screen.ado` | `capture cd \`folder'` + `error 601` on invalid path | ✅ correct |
| P1.15 | `_do2screen_aftervar.ado` | EOF guard: `if (\`loopstart' + \`j' > _N) { local inloop = 1; continue }` | ✅ correct |
| verify-4 P1.1 | `tests/run_tests.do` + `tests/capture_golden.do` | Test 4.8 switched to golden-file comparison; golden file committed | ✅ correct |

---

### P3 — MINOR (nice to have)

- **[P3.1]** ✅ **Fixed** — [cg-code-quality / cg-testing] `tests/capture_golden.do` — section 4 comment numbering jumps from `4.5` to `4.8`, skipping 4.6 and 4.7
  **Why**: Tests 4.6 and 4.7 (range validation rc-only tests) correctly produce no file output and need no golden capture, but the numbering gap will confuse contributors adding future section-4 tests who may wonder if 4.6/4.7 are missing.
  **Fix applied**: Inserted placeholder comments between blocks 4.5 and 4.8:
  ```stata
  * 4.6 — rc-only test (range start < 1): no file capture needed (see run_tests.do 4.6)
  * 4.7 — rc-only test (range start > end): no file capture needed (see run_tests.do 4.7)
  ```

---

### ✅ All prior fixes confirmed correct

- **P0.1** — `_do2screen_find.ado` per-line disp: `local displine = \`fline' + \`i'` correct numeric assign; `noi disp in g/in y` valid color abbreviations; `noi` propagates through inherited `qui`; out-of-bounds `displine > _N` returns empty string gracefully ✓
- **P0.2** — `do2screen.ado` error propagation: `moderc` captured immediately after `timer off 4` (no intervening commands); `continue` skips only `_do2screen_return`; log close, `cd` restore, and `frame drop` all run correctly after loop ✓
- **P1.8** — `do2screen.ado` folder validation: `cdir` set before `capture cd`; on failure `_fr_do2screen_parsed` not yet created; `error 601` exits cleanly ✓
- **P1.15** — `_do2screen_aftervar.ado` EOF bound: `continue` skips out-of-bounds `replace ... in N+k`; `inloop = 1` causes `while` exit; `continue` in `while` loops valid in Stata 14+ (project targets 16.1) ✓
- **Test 4.8** — golden-file approach correct; `capture noisily` allows `do2screen` text log write; branch on `_rc != 0` correct (overflow guard fires inside sub-command, outer rc stays 0) ✓
- **capture_golden.do** overflow entry — matches existing rc-path capture pattern (4.1/4.4 style) ✓
- **find-mode golden files** (7 regenerated) — consistent with P0.1 output format change ✓

---

### ℹ️ Notes

- P0.2 fix (error propagation) is a partial fix: `do2screen` still returns rc=0 when a mode sub-command fails. The fix prevents corrupted `r()` returns. Full rc propagation (making `do2screen` return non-zero on sub-command failure) remains an open design decision.
- The scalar accumulation in `_do2screen_find.ado` still populates blank entries for rows where `displine > _N` (out-of-bounds frame rows return empty string). This matches vartrack behavior and is below threshold for reporting.
- Open items from thorough review not in scope of this pass: P1.2, P1.3, P1.4, P1.5, P1.9, P1.10, P1.11, P1.12, P2.1, P2.4, P2.5, P2.6, P2.7, P2.10, P2.11, P2.12, P2.14, P3.4, P3.9–P3.12.

**Test result**: all R.T. tests expected to pass (39/39 ✓ from verify-4; no regressions introduced).
