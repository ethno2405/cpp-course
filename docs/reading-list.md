# Reading List

Each phase document tells you what to read and when. This document lists all sources in one place. Free sources are marked "(free)". Book editions change; use the newest edition that covers C++20 or newer, unless the table says something different.

## C++: core sources

| Source | Use it for | Phase |
|---|---|---|
| cppreference.com (free) | The reference for the language and the standard library. Each page shows the standard version of each feature. | All |
| The C++ Core Guidelines, by Bjarne Stroustrup and Herb Sutter (isocpp.github.io/CppCoreGuidelines) (free) | Rules for modern C++, with reasons. The course refers to them in every phase. | 1–8 |
| learncpp.com (free) | A complete tutorial from the beginning. Good for learners of dynamic languages. | 1–3 |
| Bjarne Stroustrup, *A Tour of C++*, 3rd edition | A short overview of modern C++ (C++20) for experienced programmers | 1–4 |
| Bjarne Stroustrup, *Programming: Principles and Practice Using C++*, 3rd edition | A longer introduction to programming with C++. Use it if you are new to static types. | 1–3 |
| Marc Gregoire, *Professional C++*, 6th edition | A complete book about the language and the standard library, up to C++23 | 1–6 |
| Scott Meyers, *Effective Modern C++* | Rules for C++11 and C++14: move semantics, smart pointers, lambdas, `auto`. Old, but the reasons are still correct. | 2–3 |
| Nicolai Josuttis, *C++ Move Semantics: The Complete Guide* | Move semantics in depth | 2 |
| Jason Turner, *C++ Best Practices* | Short rules about tools, warnings, and safe code | 0–4 |
| Rainer Grimm, *C++ Core Guidelines Explained* | The Core Guidelines with examples | 2–5 |
| hackingcpp.com (free) | Cheat sheets and diagrams for the standard library and modern C++ | 1–3 |
| The working draft of the C++ standard (eel.is/c++draft) (free) | The exact rules. Use it when cppreference.com is not enough. | 3, 9 |
| Compiler Explorer (godbolt.org) (free) | Compile small examples with many compilers, and see the generated code | All |

## C++: specific subjects

| Source | Subject | Phase |
|---|---|---|
| David Vandevoorde, Nicolai Josuttis, and Douglas Gregor, *C++ Templates: The Complete Guide*, 2nd edition | Templates in depth (C++17) | 3, 9 |
| Nicolai Josuttis, *C++20: The Complete Guide* | Concepts, ranges, coroutines, modules, `std::format`, `std::jthread` | 3, 4, 6 |
| Klaus Iglberger, *C++ Software Design* | Design principles and patterns in modern C++: type erasure, value semantics, strategy, visitor | 5 |
| Anthony Williams, *C++ Concurrency in Action*, 2nd edition | Threads, locks, atomics, the memory model, thread-safe data structures | 6 |
| Mara Bos, *Rust Atomics and Locks* (marabos.nl/atomics) (free online) | Atomics and memory ordering. The examples use Rust, but the memory model is the C++ memory model. | 6 (optional) |
| Kurt Guntheroth, *Optimized C++* | Measure and optimize C++ code | 8 |
| Björn Andrist and Viktor Sehr, *C++ High Performance*, 2nd edition | Performance, memory, concurrency, and coroutines | 6, 8 |
| Denis Bakhvalov, *Performance Analysis and Tuning on Modern CPUs* (easyperf.net) (free) | Profilers, CPU details, and measurement | 8 |
| Ulrich Drepper, "What Every Programmer Should Know About Memory" (free) | Caches and memory. Old, but the main ideas are still correct. | 2, 8 |
| Agner Fog, optimization manuals (agner.org/optimize) (free) | Low-level optimization | 9 |

## Build systems and libraries

| Source | Use it for | Phase |
|---|---|---|
| CMake documentation, "CMake Tutorial" and "cmake-presets(7)" (cmake.org/cmake/help/latest) (free) | CMake from the beginning, presets | 0 |
| Henry Schreiner and others, "An Introduction to Modern CMake" (cliutils.gitlab.io/modern-cmake) (free) | Target-based CMake | 0, 4 |
| Craig Scott, *Professional CMake: A Practical Guide* (crascit.com) | CMake in depth. Updated for each CMake version. | 0, 4, 8 |
| The Meson Build System manual (mesonbuild.com) (free) | Meson, if you select it | 0 |
| xmake documentation (xmake.io) (free) | xmake, if you select it | 0 |
| vcpkg documentation (learn.microsoft.com/vcpkg) (free) | vcpkg, manifest mode, baselines | 4 (optional) |
| Conan 2 documentation (docs.conan.io) (free) | Conan, lock files, profiles | 4 (optional) |
| CMake documentation, "FetchContent" and "Using Dependencies Guide" (free) | `FetchContent`, `find_package` | 0, 4 |

## Chess programming

| Source | Use it for | Phase |
|---|---|---|
| Chess Programming Wiki (chessprogramming.org) (free) | Board representations, move generation, perft results, search, evaluation | 1, 3–8 |
| FIDE Laws of Chess (handbook.fide.com) (free) | The exact rules: castling, en passant, promotion, draws | 1, 3 |
| Steven J. Edwards, "Portable Game Notation Specification and Implementation Guide" (free) | FEN, PGN, and SAN | 1, 4 |
| The UCI protocol description by Stefan Meyer-Kahlen (search for "UCI protocol" on the Shredder Chess website) (free) | The UCI commands | 4 |
| Stockfish source code (github.com/official-stockfish/Stockfish) (free) | A strong open-source engine. Read it after phase 6. | 6–9 |
| Sebastian Lague, "Coding Adventure: Chess" (a video, YouTube) (free) | A visual introduction to a chess program | 1 (optional) |

## User interfaces

| Source | Use it for | Phase |
|---|---|---|
| Dear ImGui wiki and `imgui_demo.cpp` (github.com/ocornut/imgui) (free) | Dear ImGui. The demo file shows every widget with code. | 6 |
| SDL3 wiki (wiki.libsdl.org/SDL3) (free) | SDL3: windows, events, rendering | 6 |
| Qt 6 documentation (doc.qt.io) (free) | Qt Widgets, signals and slots, threads in Qt | 6 (if you select Qt) |

## Network and persistence

| Source | Use it for | Phase |
|---|---|---|
| Boost.Asio documentation, and Christopher Kohlhoff's examples (free) | Asynchronous I/O, C++20 coroutines with Asio | 7 |
| Boost.Beast documentation and examples (free) | HTTP and WebSocket servers | 7 |
| WHATWG HTML Living Standard, "Server-sent events" (html.spec.whatwg.org) (free) | The SSE format | 7 |
| RFC 6455, "The WebSocket Protocol" (free) | WebSocket | 7 |
| RFC 9110, "HTTP Semantics" (free) | HTTP methods, status codes, headers | 7 |
| RFC 9457, "Problem Details for HTTP APIs" (free) | Error bodies | 7 |
| MDN Web Docs, "HTTP", "Server-sent events", "WebSockets" (developer.mozilla.org) (free) | Short explanations with examples | 7 |
| SQLite documentation, "An Introduction to the SQLite C/C++ Interface" (sqlite.org) (free) | The SQLite C API | 7 |
| nlohmann/json README (github.com/nlohmann/json) (free) | JSON in C++ | 7 |
| OWASP Top 10 (owasp.org) (free) | Web application security risks | 7 |

## Software design

| Source | Use it for | Phase |
|---|---|---|
| David Thomas and Andrew Hunt, *The Pragmatic Programmer*, 20th anniversary edition | General practices: DRY, orthogonality, decoupling, refactoring | 5 |
| Robert C. Martin, *Clean Architecture* | SOLID, component principles, architecture, the dependency rule | 5 |
| Robert C. Martin, *Clean Code* | Names, functions, comments. Read it together with Ousterhout for a balanced view. | 5 |
| John Ousterhout, *A Philosophy of Software Design*, 2nd edition | Complexity, deep modules, information hiding | 5 |
| Martin Fowler, *Refactoring*, 2nd edition | Refactoring steps and code smells | 5, 8 |
| Scott Wlaschin, *Domain Modeling Made Functional* | Domain modeling with types (the examples use F#) | 5 |
| Erich Gamma, Richard Helm, Ralph Johnson, and John Vlissides, *Design Patterns* | The classic pattern catalog (the examples use old C++). Read it with Iglberger for the modern forms. | 5 |
| Alistair Cockburn, "Hexagonal Architecture" (alistair.cockburn.us) (free) | Ports and adapters | 5 |
| Alexis King, "Parse, don't validate" (lexi-lambda.github.io) (free) | Type-driven validation | 4, 5 |
| Sandi Metz, "The Wrong Abstraction" (sandimetz.com) (free) | The cost of DRY | 5 |
| Michael Nygard, "Documenting Architecture Decisions" (cognitect.com) (free) | ADRs | 5 |
| Gary Bernhardt, "Boundaries" (a talk, destroyallsoftware.com) (free) | Functional core, imperative shell | 5 |
| Sean Parent, "Inheritance Is The Base Class of Evil" (a talk) (free) | Value semantics and type erasure | 5 |

## Testing and professional practices

| Source | Use it for | Phase |
|---|---|---|
| Kent Beck, *Test-Driven Development: By Example* | TDD | 5 |
| Michael Feathers, *Working Effectively with Legacy Code* | Change code without tests safely. Many examples are in C++. | 8 |
| Titus Winters, Tom Manshreck, and Hyrum Wright, *Software Engineering at Google* (abseil.io/resources/swe-book) (free online) | Code review, testing, dependency management, large teams | 8 |
| Google, "Code Review Developer Guide" (google.github.io/eng-practices) (free) | Code review | 8 |
| doctest, Catch2, and GoogleTest documentation (free) | Your test framework | 0–8 |
| RapidCheck documentation (github.com/emil-e/rapidcheck) (free) | Property-based tests | 8 |
| LLVM libFuzzer documentation (llvm.org/docs/LibFuzzer.html) (free) | Fuzzing | 8 |

## Videos and community

| Source | Use it for |
|---|---|
| CppCon, C++Now, Meeting C++ (talks on YouTube) (free) | Talks about every subject of the course. Search for "Back to Basics" talks first. |
| Jason Turner, "C++ Weekly" (YouTube) (free) | Short videos about one feature each |
| isocpp.org (free) | News, the C++ FAQ, and links to the standard committee papers |
| Exercism, C++ track (exercism.org/tracks/cpp) (free) | Exercises with optional reviews from human mentors |
