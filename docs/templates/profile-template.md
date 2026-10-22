# Learner Profile

The AI mentor writes this file after the assessment (`docs/mentor/assessment.md`). The file is in `learner/`. Commit it only on your track branch (`track/<YYYY-MM-DD>`), never on `master`.

**Assessment date:** <YYYY-MM-DD>
**Assessment mode:** Quick | Standard | Full

## Background

| Item | Answer |
|---|---|
| Programming languages (years) | |
| Best known language | |
| C++ experience and standard | |
| Memory and concurrency | |
| Design principles and patterns | |
| Tools (git, terminal, debugger, build system, package manager, CI) | |
| Hours per week | |
| Goal | |

## Environment

| Item | Value |
|---|---|
| Operating system | |
| Shell | Bash / Zsh / PowerShell |

## Toolchain

The mentor fills in this section with the learner (`docs/mentor/toolchain-selection.md`). Write the version of each tool.

| Item | Value | Version |
|---|---|---|
| Compiler and standard library | Default / <GCC, Clang, MSVC, clang-cl, MinGW-w64> | |
| Build system | CMake (default) / <Meson, xmake, Bazel, Make> | |
| Generator or backend | Ninja (default) / <Visual Studio, Make, Xcode> | |
| Library management | Manual (default) / <vcpkg, Conan, system package manager> | |
| Test framework | doctest (default) / <Catch2, GoogleTest> | |
| Editor or IDE | VS Code + clangd (default) / <other> | |
| Debugger | | |
| Sanitizers available | ASan / UBSan / TSan | |
| GUI library (phase 6) | Dear ImGui + SDL3 (default) / Qt 6 / not selected yet | |

## Project

The mentor fills in this section with the learner (`docs/mentor/project-selection.md`).

**Domain:** Chess engine (default) | <other domain>

| Element | Chess engine | Learner's domain |
|---|---|---|
| Value types with rules | `Square`, `Piece`, `Move` | |
| Aggregate with invariants | `Position` | |
| Text format 1 | FEN | |
| Known correct result | Perft | |
| Hot path | Move generation and search | |
| Text protocol with state | UCI | |
| Format 2 | PGN with SAN | |
| Variation points | Evaluators, opening books, game stores | |
| Long computation with stop | Search with a time limit | |
| Live view | Board and analysis in a window | |
| HTTP resources | Games, positions, analysis | |
| Server stream (SSE) | Analysis of a running search | |
| Two-way session (WebSocket) | A live game | |
| Persistence | Games and analysis cache in SQLite | |
| Properties for tests | Make/unmake, FEN round trip, perft equality | |

## Levels

Levels: 0 = none, 1 = basic, 2 = working, 3 = strong. Source: "assessed" or "self-reported".

| Area | Level | Source | Evidence |
|---|---|---|---|
| C++ language (C) | | | |
| Memory and concurrency (S) | | | |
| Design and practices (D) | | | |
| Tools (T) | | | |

## Learning path

<Decisions from the "Learning path" table in the assessment document. Example: "Phase 1: do all topics. Plan 3 weeks.">

-

## Preferences

| Item | Value |
|---|---|
| Help when blocked | Hints first / Full solution with an explanation |
| Explanation depth | Short / Normal / Very detailed |
| Language for comparisons | <the best known language> |
| C++ standard | C++23 (default). Change only if the learner asks. |
| Other | |

## Observations

The mentor updates this section after each session.

### Strengths

-

### Gaps

-

### Misconceptions (corrected or open)

-

## Assessment history

| Date | Type | Result |
|---|---|---|
| | Initial assessment | |
