# C++ Application Development Course

This course teaches application development with modern C++ (C++23). It also teaches how to design software that is easy to understand, to test, and to change. It starts at zero for C++. It does not start at zero for programming.

## Who this course is for

- **Required:** you can write programs in at least one programming language. You know variables, functions, loops, and data structures, and you can use git and a terminal.
- **Not required:** knowledge of C++, memory management, build systems, concurrency, or design principles. The course teaches these topics.
- **Your background changes the time for phase 1:**

  | Your background | Phase 1 time |
  |---|---|
  | You already wrote programs in modern C++ (C++11 or newer) | 1 week |
  | You know C, Rust, or old C++ (C++98) | 2 weeks |
  | You know C#, Java, Go, Swift, Kotlin, or TypeScript | 3 weeks |
  | You know only dynamic languages (Python, JavaScript, Ruby, PHP, and similar) | 4–6 weeks |

The AI mentor assesses your background in the first session and saves it in `learner/profile.md`. See the [main README](../README.md) for how to start. Without an AI mentor, use the table above to plan phase 1.

The course has ten phases. Each phase has topics, reading, exercises, and a part of the main project. One main project, the **chess engine**, grows from phase 1 to phase 9. Side projects give more practice.

## How to use this course

You can use the course with an AI mentor or alone. With an AI mentor, the mentor follows [mentor/](mentor/) and tracks your progress in `learner/progress.md`. Alone, follow these steps:

1. Read [software-setup.md](software-setup.md) and select your toolchain. If you do not know what to select, use the defaults.
2. Read the phase document from top to bottom before you start the phase.
3. Do the reading and the exercises in the given order.
4. Do the project stage for the phase.
5. Do a check of the "Done criteria" list at the end of the phase. Go to the next phase only when all items are complete.
6. Write your notes, compiler errors that you did not understand, and design decisions in your engineering notebook.
7. Record your progress in `learner/progress.md`. Copy it from [templates/progress-template.md](templates/progress-template.md).

The times assume 6–8 hours of work per week.

## Your toolchain

C++ has many compilers, build systems, editors, and methods to get libraries. The course does not force one. It shows a default, and it explains the alternatives.

| Item | Default in the documents | Alternatives |
|---|---|---|
| Standard | C++23 | — |
| Compiler | GCC 14+, Clang 18+, or MSVC 19.40+ (the native compiler of your operating system) | clang-cl, MinGW-w64 |
| Build system | CMake with presets | Meson, xmake, Bazel, Make. See [topics/build-systems.md](topics/build-systems.md). |
| Libraries | Manual management: vendored sources and pinned downloads | vcpkg, Conan. See [topics/external-libraries.md](topics/external-libraries.md). |
| Tests | doctest | Catch2, GoogleTest |
| Editor | VS Code with clangd | CLion, Visual Studio, Qt Creator, Neovim, Emacs, Zed |
| GUI (phase 6) | Dear ImGui with SDL3 | Qt 6 |

All course code is portable. It builds on Windows, macOS, and Linux.

## Roadmap

| Phase | Document | Time | Main result |
|---|---|---|---|
| 0 | [Tools, build, and environment](phases/phase-0-tools.md) | 1–2 weeks | You can build, test, lint, debug, and sanitize a C++ project, and add a third-party library with and without a package manager. |
| 1 | [C++ basics](phases/phase-1-cpp-basics.md) | 1–6 weeks, depends on your background | You can write small C++ programs with classes, `enum class`, `std::variant`, `std::optional`, containers, and tests. |
| 2 | [Object lifetime and ownership](phases/phase-2-ownership.md) | 3 weeks | You can explain RAII, value and move semantics, and smart pointers, and you can find lifetime errors with the sanitizers. |
| 3 | [Templates, concepts, lambdas, and ranges](phases/phase-3-templates.md) | 3–4 weeks | You can write generic code with concepts, and data pipelines with ranges. A correct chess move generator. |
| 4 | [Errors, libraries, and API design](phases/phase-4-errors-apis.md) | 3–4 weeks | A command-line chess engine with UCI, PGN, good error messages, and documentation. |
| 5 | [Software design and SOLID](phases/phase-5-software-design.md) | 4 weeks | An engine with a hexagonal architecture that is easy to test and to extend. |
| 6 | [Concurrency and user interfaces](phases/phase-6-concurrency-gui.md) | 4–5 weeks | A multi-threaded search with time control and cancellation, and a desktop GUI that stays responsive. |
| 7 | [Network services and persistence](phases/phase-7-network-services.md) | 4 weeks | An HTTP interface with REST, Server-Sent Events, and WebSocket, and a SQLite database. |
| 8 | [Professional practices](phases/phase-8-professional-practices.md) | 3–4 weeks | Property tests, fuzzing, benchmarks, an optimized board, a CI pipeline, and a release. |
| 9 | [Beyond](phases/phase-9-beyond.md) | Open-ended | Engine strength, C++26, interoperability, WebAssembly, and more. |

## Main project: chess engine

The full specification is in [projects/chess-engine.md](projects/chess-engine.md).

| Stage | Phase | Features |
|---|---|---|
| 0 | 1 | Domain model: squares, pieces, moves, positions. FEN input and output. Unit tests. |
| 1 | 3 | Legal move generation. Make and unmake a move. Perft tests against published values. |
| 2 | 4 | Command-line interface, the UCI protocol, PGN files, a first search (alpha-beta), error types, documentation. |
| 3 | 5 | A hexagonal architecture: core library, ports, and adapters. Two evaluators, an opening book, a game store. |
| 4 | 6 | Multi-threaded search, a transposition table, time control, cancellation. A desktop GUI with a board and live analysis. |
| 5 | 7 | An HTTP server: REST for games and positions, SSE for the analysis stream, WebSocket for live games. SQLite. The GUI can use a remote engine. |
| 6 | 8 | Bitboards behind the same interface, property tests, fuzzing, benchmarks, CI on three operating systems, release packages. |
| 7 | 9 | Optional: a stronger evaluation, a web front end, a WebAssembly build, or a different extension. |

You can select a different project domain with the same stages. See [mentor/project-selection.md](mentor/project-selection.md).

## Design principles in the course

The course teaches software design in every phase, not only in phase 5.

| Phase | Design content |
|---|---|
| 1 | Names, small functions, class invariants, tests from the first day |
| 2 | Ownership as a design tool: who owns the data, and how long does it live? Value semantics. |
| 3 | Static and dynamic polymorphism. Concepts as interfaces. Strategy with lambdas. |
| 4 | Error design, "parse, don't validate", strong types, library boundaries, API guidelines, documentation |
| 5 | SOLID, DRY, KISS, YAGNI, coupling and cohesion, domain modeling, hexagonal architecture, design patterns, refactoring, test-driven development |
| 6 | Message passing, the UI thread, the observer pattern, model-view separation, structured cancellation |
| 7 | Layers and boundaries in a service. Real-time protocols. Configuration. Observability. Security at the boundary. |
| 8 | Test strategy, optimization behind a stable interface, code review, versioning, dependency hygiene, architecture decision records |

## Documents

| Document | Content |
|---|---|
| [software-setup.md](software-setup.md) | Compilers, build systems, editors, debuggers, sanitizers, and tools on Windows, macOS, and Linux |
| [reading-list.md](reading-list.md) | Books, courses, and documentation |
| [glossary.md](glossary.md) | Terms and abbreviations |
| [phases/](phases/) | One document for each phase |
| [projects/](projects/) | Project specifications and task documents |
| [topics/](topics/) | Detailed explanations of specific topics |
| [mentor/](mentor/) | Instructions for the AI mentor: assessment, teaching, project selection, toolchain selection |
| [templates/](templates/) | Templates for new documents, the learner profile, and progress |

## General advice

1. **Read the first compiler error first.** Later errors are often results of the first one. In a long template error, find the first line that points to your own code.
2. **A program that runs is not a correct program.** C++ has undefined behavior: wrong code can print the expected result today and fail tomorrow. Build with warnings as errors, and run your tests under the sanitizers from the first day.
3. **Write tests from the first day.** A test is the fastest way to learn what code does, and the only safe way to change it later.
4. **Prefer values and the standard library.** Most code needs no `new`, no `delete`, no raw arrays, and no macros. When you think that you need them, ask why.
5. **Type the code yourself.** Do not copy and paste examples. The errors that you make teach you the language.
6. **Keep an engineering notebook.** Write down compiler errors that surprised you, sanitizer reports, design decisions and their reasons, and questions for later.
7. **Read good code.** Read the source of well-known libraries and engines, for example the standard library implementation of your compiler, `fmt`, and the chess engine Stockfish.
8. **Use principles as tools, not as laws.** Each design principle has a cost. A small program does not need the architecture of a large system. In a hot path, an abstraction can cost speed. Learn to see when a principle helps and when it adds only complexity.
