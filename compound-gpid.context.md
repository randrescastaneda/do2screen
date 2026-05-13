# Project Context

Additional context for Copilot and the Compound GPID plugin. Edit freely —
this file is committed to git and shared with the team.

## Data Sources
<!-- Where does data come from? File paths, databases, APIs, vintage conventions -->

## Domain Rules
<!-- Project-specific rules that Copilot should always follow -->
- `rclass` results from sub-programs called inside a `qui` block are cleared on exit. Never test `r()` values from do2screen sub-commands directly; use `text()` + golden-file comparison instead (see `.cg-docs/solutions/testing-patterns/2026-05-13-golden-file-testing-rc0-guards.md`).
- Never accumulate frame-sourced code lines into a scalar for display via `noi disp \`scalar'` — use per-line display (`noi disp in g ... in y ...` inside the loop) to avoid `r(132)` from compound-quote expansion limits (see `.cg-docs/solutions/bugs/2026-05-13-compound-quote-scalar-accumulation-r132.md`).

## Work in Progress
<!-- Modules, features, or migrations currently underway -->

## Workspace Notes
<!-- Related folders, dependencies on other projects in the VS Code workspace -->
