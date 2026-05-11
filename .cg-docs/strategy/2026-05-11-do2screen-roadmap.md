---
date: 2026-05-11
title: "do2screen roadmap"
trigger: "new-project"
outcome: "roadmap-updated"
---

# Strategy Session: do2screen roadmap

## Context at Session Start

The project is do2screen, a Stata package that helps users inspect do-files directly in the Stata screen. The current implementation identifies how a variable is derived, generated, or modified by collecting relevant lines of code, and also supports string search and selected line ranges.

At session start, the roadmap was empty and the charter current focus was:

> Improving code quality and modularity of the existing do2screen.ado implementation.

## Discussion Summary

The user identified eight strategic gaps:

1. Add support for Stata frames.
2. Fully test and audit the identification logic.
3. Provide examples and example do-files for users.
4. Unit test the logic.
5. Allow multi-do-file tracing where a variable can be created in one do-file and modified in another.
6. Improve documentation.
7. Make the code more modular because the main ado-file currently does too much.
8. Improve efficiency so the command is very fast.

The user did not see a fixed dependency order and deferred sequencing. We agreed that the first milestone should be a tested, modular baseline that preserves current behavior while creating a safe foundation for future frames and multi-file tracing.

## Proposed Changes

The approved roadmap has four milestones:

1. Tested Modular Baseline — preserve current behavior while making the codebase testable, auditable, and easier to extend.
2. Identification Logic Audit — strengthen the variable-derivation algorithm so it handles more Stata syntax reliably.
3. Multi-file and Frame-aware Tracing — extend tracing from a single do-file and default frame to realistic multi-file Stata workflows.
4. Performance and User Documentation — make the command fast, well documented, and easy for users to learn.

## Decision

The user approved the proposed roadmap structure. The roadmap was updated with 4 milestones and 16 idea-stage features.

## Charter Updates

The charter Current Focus was updated to:

> Preserve current behavior while making the codebase testable, auditable, and easier to extend.

The replaced Current Focus was archived in `.cg-docs/archive/charter-history.md`.
