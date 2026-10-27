# Phase 9: Beyond

**Time:** Open-ended. Each module takes 1–4 weeks.
**Prerequisites:** Phase 8 (for most modules, phases 1–6 are enough).
**Code:** `labs/9-<module>/` and `labs/chess/`

## Goal

This phase has independent modules. Select the modules that match your goals. With a mentor, the mentor suggests modules from the goal in your profile.

At the end of each module, you can use the subject in a real project, and you know where to learn more.

## Modules

### 9.1 Engine strength

For learners who want a stronger chess engine. Read the Chess Programming Wiki for each subject.

- **Test method first:** a change is better only if a match proves it. Use self-play with a tool such as fastchess or cutechess-cli, and the sequential probability ratio test (SPRT) to decide when a result is significant. Without this, most "improvements" are noise.
- **Move generation:** magic bitboards for sliding pieces; pseudo-legal generation with a legality check.
- **Search:** better move ordering (the transposition table move, MVV-LVA (most valuable victim, least valuable attacker) for captures, killer moves, the history heuristic), principal variation search, null-move pruning, late move reductions, aspiration windows, check extensions.
- **Evaluation:** tapered evaluation (middle game and end game), pawn structure, king safety, mobility; tuning of the parameters with a large set of positions (Texel tuning).
- **Neural network evaluation:** NNUE (efficiently updatable neural network) is the evaluation of most strong engines today. Start with the documents of the Stockfish project and of smaller open-source engines.
- **Exercise:** add three search improvements, one at a time. Prove each one with SPRT. Record the results in `docs/strength.md`.

### 9.2 Advanced templates and metaprogramming

- Variadic templates and fold expressions; type traits (`<type_traits>`); `if constexpr` in depth; tag dispatch; SFINAE and `std::enable_if` (read them in older code; write concepts in new code).
- Compile-time containers and algorithms: `constexpr` `std::vector` and `std::string` (C++20) inside constant evaluation.
- Expression templates (a technique of linear algebra libraries).
- The cost: compile time, error messages, and readability. Measure the compile time (`-ftime-trace` with Clang, `/d1reportTime` and Build Insights with MSVC).
- **Exercise:** write a small type-safe units library (meters, seconds, meters per second) where wrong combinations do not compile. Compare it with an existing library such as mp-units.

### 9.3 New standards: C++26 and later

- The C++ committee approved these major features for C++26 (check the current status and the compiler support on cppreference.com before you use them):
  - **Static reflection:** inspect types, members, and enumerators at compile time, and generate code from them (for example a JSON serializer without macros).
  - **Contracts:** `pre`, `post`, and `contract_assert` with defined behavior for violations.
  - **`std::execution`** (senders and receivers): a standard model for asynchronous and parallel work.
  - More: `#embed` for binary files, pack indexing, `std::inplace_vector`, saturation arithmetic, `std::hive`, linear algebra (`<linalg>`), `std::simd`.
- **How to follow the standard:** cppreference.com marks new features; isocpp.org publishes trip reports of the committee meetings; the papers are on open-std.org.
- **Exercise:** when your compiler supports it, rewrite the FEN parser preconditions with contracts, or write an enum-to-string function with reflection. Compare with the C++23 version.

### 9.4 Modules in depth

- Module interface units, implementation units, partitions, the global module fragment, header units, `import std;`.
- The build system support (CMake `FILE_SET CXX_MODULES`), the compile time, and the editor support in your toolchain.
- How to move a library to modules step by step, and how to support users who still use headers.
- **Exercise:** convert `chess_core` to a module on a separate branch. Measure the clean and the incremental build times before and after. Write an ADR: use modules now or later?

### 9.5 WebAssembly and web front ends

- **Emscripten** compiles C++ to WebAssembly that runs in a browser. `embind` connects C++ functions and classes to JavaScript.
- Limits: threads need special browser settings (cross-origin isolation); file and network access work differently.
- **A web front end for the chess server:** an HTML and JavaScript (or TypeScript) page with a board that uses the REST API, the SSE analysis stream, and the WebSocket game session of stage 5. This is a different language, but it shows the server API from the side of a client.
- **Exercise (stage 7, option B or C):** build `chess_core` with Emscripten and show the legal moves of a position in a web page, or write the web front end for the server.

### 9.6 Interoperability

- **C interfaces:** `extern "C"` functions, opaque handles, error codes, and ownership rules at the boundary. A C interface is the most portable way to call C++ from other languages.
- **Python:** nanobind or pybind11 make Python modules from C++ classes and functions. Release the Python global interpreter lock for long computations.
- **Other languages:** Rust (the `cxx` crate), C# (P/Invoke through a C interface), Java (JNI or the Foreign Function and Memory API).
- Exceptions must not cross a language boundary. Convert them to error values at the boundary.
- **Exercise (stage 7, option D):** make a Python module with `perft`, `legal_moves`, and `best_move`. Write a Python script that analyzes a PGN file.

### 9.7 Advanced desktop GUI: Qt

- Qt Widgets and QML; signals and slots; the model/view classes; threads in Qt (`QThread`, worker objects, queued connections); resources and translations; deployment (`windeployqt`, `macdeployqt`) and the LGPL rules.
- Compare the design with the Dear ImGui GUI: where is the state, and how do the engine events reach the UI?
- **Exercise (stage 7, option E):** write a Qt version of the chess GUI that uses the same engine port and use cases. The core and the engine adapters do not change.

### 9.8 Low-level performance

- **SIMD:** intrinsics (SSE, AVX, NEON), auto-vectorization reports, and `std::simd` (C++26). Keep a portable fallback.
- **Memory:** custom allocators, polymorphic memory resources (`std::pmr`), arenas, object pools; the cost of `std::shared_ptr` and of heap allocations in hot paths.
- **Data-oriented design:** structures of arrays, hot and cold data, cache lines, prefetching.
- **Tools:** hardware performance counters (`perf stat`, VTune), Compiler Explorer to read the generated code, `llvm-mca` for the throughput of small loops.
- **Exercise:** profile the search with hardware counters. Find the largest source of cache misses or branch mispredictions, and reduce it. Prove the result with a benchmark and with SPRT if the change can affect the search.

### 9.9 Embedded C++

- C++ on microcontrollers: freestanding implementations, no heap or a fixed heap, no exceptions and no RTTI (`-fno-exceptions -fno-rtti`), `constexpr` for tables in flash memory, `std::array` and `std::span` in place of dynamic containers.
- Cross-compilation with CMake toolchain files; debuggers (OpenOCD, probe-rs); unit tests on the host computer.
- **Exercise:** build `chess_core` (the move generator and perft) for a microcontroller board (for example a Raspberry Pi Pico) or for its emulator, without exceptions and without the heap. Measure perft at depth 4.

### 9.10 Open source

- Find a C++ project that you use (a library from this course, a chess engine, a tool). Read its contribution guide.
- Start with a small change: a documentation fix, a test, a compiler warning on your platform, an issue marked "good first issue".
- Follow the code style and the review process of the project. Be patient with the review.
- **Exercise:** make one contribution that the maintainers merge.

## Project: Chess engine, stage 7 (optional)

See [../projects/chess-engine.md](../projects/chess-engine.md), stage 7.

## Done criteria

For each module that you select:

- [ ] I completed the exercise of the module.
- [ ] I can explain the main ideas of the module to a different developer.
- [ ] I wrote what I learned and the next sources in my engineering notebook.

## Next

You completed the course. Keep your engineering notebook, keep building, and read good code. Consider a contribution to this course: see [../../CONTRIBUTING.md](../../CONTRIBUTING.md).
