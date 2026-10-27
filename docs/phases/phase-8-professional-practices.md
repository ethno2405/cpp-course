# Phase 8: Professional Practices

**Time:** 3–4 weeks.
**Prerequisites:** Phase 7.
**Code:** `labs/8-practices/`, `labs/chess/`, and `.github/workflows/`

## Goal

At the end of this phase, you can:

- Write a test strategy, and select the correct kind of test for each risk.
- Write property-based tests, fuzz tests, and snapshot tests, and measure the quality of your tests with coverage and mutation tests.
- Measure performance correctly, find the slow parts with a profiler, and optimize behind a stable interface.
- Use static analysis, and keep your dependencies under control.
- Build a CI pipeline that builds and tests on three operating systems with several compilers and the sanitizers.
- Version and release C++ software: semantic versioning, the ABI, packages, and a container image.
- Review code, and work safely with existing code.

## Reading

| Source | Part |
|---|---|
| Titus Winters, Tom Manshreck, and Hyrum Wright, *Software Engineering at Google* | The chapters about testing, code review, dependency management, and continuous integration |
| Michael Feathers, *Working Effectively with Legacy Code* | The parts about seams and characterization tests. Many examples are in C++. |
| Denis Bakhvalov, *Performance Analysis and Tuning on Modern CPUs* | The parts about measurement and profilers |
| RapidCheck documentation | "User guide" |
| LLVM libFuzzer documentation | All |
| CMake documentation | "install", "CPack", "Importing and Exporting Guide" |
| GitHub Actions documentation | "Understanding GitHub Actions", "Using a matrix for your jobs" |
| Keep a Changelog (keepachangelog.com), Semantic Versioning (semver.org) | All |
| [../topics/code-review-checklist.md](../topics/code-review-checklist.md) | All |

## Topics

### 8.1 Test strategy

- A **test strategy** says which risks you test, with which kind of test, and where the tests run. Write it in `docs/testing.md`.
- Most tests are fast unit tests of the core. Fewer tests check the adapters (contract tests, handler tests). A few end-to-end tests check the whole system. Slow tests have a label, and run in CI or before a release.
- **Oracles:** a test needs a way to know the correct result. Known values (perft), a reference implementation (the mailbox board for the bitboard board), properties (make and unmake restore the position), or a recorded result (snapshots).
- **Determinism:** no real time, no network, no unseeded random values. A test that fails sometimes is a defect.
- **Sanitizers are part of the strategy:** all tests run under ASan and UBSan; concurrent tests also run under TSan.

### 8.2 More kinds of tests

**Property-based tests** generate many inputs and check a property for each one. When a property fails, the library makes the input smaller ("shrinking") to show a minimal case.

```cpp
#include <rapidcheck.h>

// A property: the FEN of any reachable position parses back to the same position.
rc::check("FEN round trip", [](std::vector<std::uint8_t> choices) {
    Position pos = play_random_moves(Position::start(), choices);   // your helper
    RC_ASSERT(parse_fen(to_fen(pos)) == pos);
});
```

- Good properties: round trips (parse and print), invariants (one king of each color), equal results of two implementations, idempotence, inverse operations (make and unmake).
- Use a fixed seed in CI, and print the seed of a failure, so that you can reproduce it.

**Fuzz tests** give a function many mutated inputs and look for crashes, sanitizer reports, and timeouts. libFuzzer comes with Clang (and with MSVC with `/fsanitize=fuzzer`):

```cpp
extern "C" int LLVMFuzzerTestOneInput(const std::uint8_t* data, std::size_t size) {
    // libFuzzer gives raw bytes. A char can refer to any byte, so this view is correct.
    const std::string_view text{reinterpret_cast<const char*>(data), size};  // NOLINT(cppcoreguidelines-pro-type-reinterpret-cast)
    (void)parse_fen(text);   // must never crash, never show UB, never throw
    return 0;
}
```

- Build with `-fsanitize=fuzzer,address,undefined` (Clang). Run with a corpus directory of valid inputs (the reference FEN strings) and a time limit.
- Fuzz every parser of untrusted input: FEN, SAN, PGN, UCI commands, JSON bodies, configuration.
- Keep the inputs that found defects as normal regression tests.

**Snapshot tests** (approval tests) compare an output with a stored, reviewed file: a UCI transcript, a JSON response, a rendered board. When the output changes, the test fails and shows the difference; you approve the new output or fix the code. Write a small helper, or use a library such as ApprovalTests.cpp.

**Mocks:** GoogleMock and trompeloeil check calls against expectations. Prefer fakes (phase 5). Use a mock when the interaction is the behavior that you test, for example "the server stops the search when the last client leaves".

**Coverage** shows which lines the tests run: `gcovr` or `lcov` with GCC (`--coverage`), `llvm-cov` with Clang (`-fprofile-instr-generate -fcoverage-mapping`), OpenCppCoverage or the Visual Studio tools on Windows. High coverage does not prove good tests; low coverage proves missing tests.

**Mutation tests** change the code in small ways (a `<` to `<=`, a `+` to `-`) and check that a test fails. A change that no test finds ("a surviving mutant") shows a weak test. Mull (Clang, Linux and macOS) is a mutation testing tool for C++. It is optional in the course.

### 8.3 Performance

- **Measure first.** Do not optimize what you did not measure. Most of the time goes into a small part of the code.
- **Benchmarks:** use a library that runs the code many times and computes statistics: nanobench (one header) or Google Benchmark. Prevent the compiler from removing the measured code (`ankerl::nanobench::doNotOptimizeAway`, `benchmark::DoNotOptimize`). Measure release builds. Close other programs. The CPU frequency changes with the temperature and the power settings: repeat the measurement.
- **Profilers** show where the time goes:

  | Profiler | Platform | Kind |
  |---|---|---|
  | `perf` and flame graphs | Linux | Sampling |
  | Instruments ("Time Profiler") | macOS | Sampling |
  | Visual Studio profiler, Intel VTune | Windows (VTune also Linux) | Sampling, hardware counters |
  | Tracy | All | Instrumentation (you mark zones in the code); good for frames in the GUI |
  | Valgrind (Callgrind, Cachegrind) | Linux | Simulation; slow but exact counts |

  Build with optimization and debug information (`RelWithDebInfo`) for profiling.
- **Common costs in C++:** heap allocations in a loop (use `reserve`, reuse buffers, fixed-capacity containers), copies of large objects, cache misses (pointers to scattered objects; prefer contiguous data), branch mispredictions, virtual calls and `std::function` in the innermost loop, exceptions on a hot path, locks with contention.
- **Optimize behind a stable interface.** The bitboard version of the chess board in stage 6 changes the inside of `Position`, not its public functions. The tests (perft and the property tests against the mailbox reference) prove that the behavior did not change.
- **Compiler options:** `-O2` (or `/O2`) is the normal optimization level. Link-time optimization (`CMAKE_INTERPROCEDURAL_OPTIMIZATION`) can help. `-march=native` makes code for your CPU only: do not use it for programs that you distribute. Profile-guided optimization (PGO) is optional.
- Write each measurement in `docs/performance.md`: the date, the computer, the compiler, the build options, the result, and the change.

### 8.4 Static analysis and dependency hygiene

- **Static analysis** finds defects without running the code: clang-tidy (all phases), the GCC analyzer (`-fanalyzer`, mainly for C-style code), MSVC code analysis (`/analyze`), cppcheck. Run at least clang-tidy in CI.
- **Include what you use:** the tool include-what-you-use (IWYU) and the clang-tidy check `misc-include-cleaner` find missing and unused includes.
- **Dependency hygiene** (see [../topics/external-libraries.md](../topics/external-libraries.md)): review the dependency list in each release. Check each library for new versions and security advisories. Check the licenses. Remove dependencies that you do not need.
- **A software bill of materials (SBOM)** lists all components of a release in a standard format (CycloneDX or SPDX). It is optional in the course; the `THIRD_PARTY_LICENSES` file is required.

### 8.5 Continuous integration

- A CI pipeline builds and tests every push and every pull request. A failure blocks the merge.
- A good pipeline for C++:

  | Job | Content |
  |---|---|
  | Format | `clang-format --dry-run --Werror` on all files |
  | Lint | clang-tidy with the compilation database |
  | Build and test matrix | Linux with GCC and Clang, Windows with MSVC, macOS with Apple Clang; Debug and Release |
  | Sanitizers | ASan and UBSan on Linux and macOS; TSan on Linux |
  | Fuzz | A short run (for example 60 seconds) of each fuzz target |
  | Benchmark signature | The `chess bench` node count must be the expected value |
  | Coverage | A report as an artifact |

- **GitHub Actions:** a workflow file in `.github/workflows/`. A `matrix` runs the same steps for several operating systems and compilers. Use `ilammy/msvc-dev-cmd` or the Developer environment on Windows runners for MSVC with Ninja (check the current recommendation in the GitHub Actions documentation).
- **Caching:** cache the downloads of `FetchContent` and the compiler cache (ccache or sccache) between runs, with a key that includes the dependency list. Never cache build directories across compiler changes.
- **Secrets:** use the secret store of the CI service. Never print secrets in a log.
- A fast pipeline is a used pipeline. Run the slow jobs (long fuzzing, deep perft, self-play) nightly or before a release.

### 8.6 Versions and releases

- **Semantic versioning:** `MAJOR.MINOR.PATCH`. For a C++ library, the version must consider both the **API** (does the source code of the users still compile?) and the **ABI** (do the compiled users still work without a rebuild?). A change of a private data member in a public class breaks the ABI, not the API.
- **Changelog:** `CHANGELOG.md` with a section for each version (Added, Changed, Fixed, Removed).
- **Tags:** an annotated git tag for each release: `git tag -a v1.0.0 -m "Release 1.0.0"`.
- **Install rules:** `install(TARGETS ...)` and `install(FILES ...)` in CMake. For a library that other CMake projects use, export a package configuration (`install(EXPORT ...)` and a `<Name>Config.cmake` file), so that `find_package` works.
- **Packages:** CPack makes archives (`.zip`, `.tar.gz`) and installers from the install rules. Build a package on each operating system in CI.
- **Container image** for the server: a multi-stage `Dockerfile` (a build stage with the compiler, a small run stage with only the executable and its run-time libraries), a user that is not root, and a health check.
- **Third-party licenses:** the release contains the license texts of all third-party code (`THIRD_PARTY_LICENSES`), from the dependency list.
- **Reproducible builds:** pinned dependencies, a pinned compiler version in CI, and no timestamps in the binary help to get the same binary from the same source.

### 8.7 Code review

Use [../topics/code-review-checklist.md](../topics/code-review-checklist.md).

- Review small changes. A large change gets a superficial review.
- Let tools check the format, the warnings, and the lint findings. The reviewer checks correctness, undefined behavior, ownership, tests, and design.
- Write comments about the code, with the reason, marked as blocking or suggestion.
- As an author: explain the purpose of the change, review your own diff first, and answer each comment.

### 8.8 Work with existing code

Most C++ work is on existing code, often with old C++ and few tests.

- **Characterization tests** first: record what the code does now (phase 5).
- **Seams** (Michael Feathers): places where you can change the behavior for a test without a change to the code: a virtual function, a template parameter, a constructor parameter, a link-time replacement, a preprocessor definition. Use the least invasive one that works.
- **Sprout method and sprout class:** write new behavior in a new, tested function or class, and call it from the old code. Do not add more code to a large untested function.
- **Modernize in steps:** enable warnings one group at a time; use clang-tidy `modernize-*` checks with automatic fixes on one directory at a time; replace `new` and `delete` with smart pointers where the ownership is clear.
- **Build two compilers.** Old code often depends on the behavior of one compiler. A second compiler finds non-portable code.

### 8.9 Documentation of a project

- `README.md`: what the project does, how to build it (all supported toolchains), how to use it, how to run the tests, how to contribute.
- An **architecture overview** (`docs/architecture.md`): the targets, their responsibilities, the dependency graph, the threads, and links to the ADRs.
- **Reference documentation:** the UCI options, the HTTP API (routes, bodies, errors, the SSE events, the WebSocket messages), the configuration settings.
- A **runbook** for the server: how to start, stop, configure, back up the database, read the logs, and what to do for common failures.

## Exercises

Make the project `labs/8-practices/` for the exercises that do not use the chess engine. Do the other exercises in `labs/chess/`.

### Exercise 8.1: Test strategy

Write `labs/chess/docs/testing.md`: the risks of each target, the kind of test for each risk, the test labels, and where each test runs (local, CI on each push, nightly). Compare it with the tests that exist. Write the missing tests in a list.

### Exercise 8.2: Property-based tests (core)

Add RapidCheck to the chess engine (pin a full commit hash). Write the property tests of stage 6. Make one property fail on purpose (for example, a defect in the en passant code), and look at the shrunk input.

### Exercise 8.3: Fuzzing (core)

1. Write fuzz targets for the FEN, SAN, PGN, and UCI parsers. Build them with Clang and `-fsanitize=fuzzer,address,undefined` (on Windows: MSVC `/fsanitize=fuzzer` or clang-cl, or WSL2).
2. Make a corpus from the reference positions and some PGN games.
3. Run each target for 10 minutes. Fix each defect, and add the input as a regression test.

### Exercise 8.4: Snapshot tests

Write snapshot tests for a UCI transcript (a fixed position, `go depth 4`), and for the JSON responses of three API routes. Change the output format on purpose, and use the test to review and approve the change.

### Exercise 8.5: Coverage and mutation tests

1. Measure the coverage of `chess_core`. Find a function with low coverage, and decide whether it needs more tests.
2. Optional (Linux or macOS): run Mull on the rules code. Look at the surviving mutants, and add tests that kill them. Record the results in `docs/testing.md`.

### Exercise 8.6: Performance (core)

1. Write benchmarks for perft (the start position, depth 5) and for the search (a fixed set of positions with a fixed node count). Add the `chess bench` command.
2. Profile perft with the profiler of your operating system. Find the three most expensive functions.
3. Implement the bitboard board of stage 6 behind the same `Position` interface. Keep the mailbox version for the tests.
4. Measure again. Record each step in `docs/performance.md`.

### Exercise 8.7: CI pipeline (core)

Write the GitHub Actions workflow of topic 8.5 for the chess engine. Push the track branch to your private repository, and make the pipeline pass. Break a test on purpose, and check that the pipeline fails.

### Exercise 8.8: Release (core)

1. Add install rules and CPack. Make packages for your operating system locally.
2. Add a release job to the pipeline that runs on a tag `v*`, builds the packages on three operating systems, and attaches them to a GitHub release.
3. Write a multi-stage `Dockerfile` for `chess-server`. The container runs as a user that is not root, and binds to the address from the configuration.
4. Write `CHANGELOG.md` and `THIRD_PARTY_LICENSES`. Tag `v1.0.0`.

### Exercise 8.9: Code review

1. Review a pull request of a different learner, or an old commit of your own engine, with the checklist. Write the comments as blocking or suggestion.
2. Find a small open-source C++ project. Read its contribution guide, its CI configuration, and three merged pull requests with their reviews. Write what you learned.

## Project: Chess engine, stage 6

See [../projects/chess-engine.md](../projects/chess-engine.md), stage 6.

## Done criteria

- [ ] My project has a written test strategy, and the tests follow it.
- [ ] I have property-based tests and fuzz tests for all parsers of untrusted input.
- [ ] I can measure performance correctly, use a profiler, and show each optimization with numbers.
- [ ] My bitboard board is faster, and the tests prove that it behaves the same as the mailbox board.
- [ ] My CI pipeline builds and tests on three operating systems, with the sanitizers, the format check, and clang-tidy.
- [ ] I can explain the difference between API and ABI compatibility for semantic versioning.
- [ ] My release has packages, a container image, a changelog, and the third-party licenses.
- [ ] I can review code with the checklist, and work with existing code with seams and characterization tests.
- [ ] Chess engine stage 6 is complete.

## Next

[Phase 9: Beyond](phase-9-beyond.md)
