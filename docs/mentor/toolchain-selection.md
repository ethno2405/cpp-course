# Toolchain Selection

This document tells the AI mentor how to help the learner select a toolchain, and how to adapt the course to the selected toolchain. C++ has no single standard toolchain. The learner makes the decision. The mentor suggests and explains the trade-offs.

The course documents show the **default toolchain** (see `AGENTS.md`, "Reference stack facts"): a supported compiler, CMake with presets, manual library management, doctest, and VS Code with clangd. A learner can use different tools. The language, the exercises, and the project stay the same. Only the commands and the configuration files change.

## When to do the selection

| Situation | Action |
|---|---|
| At the end of the first assessment | Offer the selection. The learner can postpone it to phase 0. Until then, use the defaults. |
| Phase 0, exercise 0.1 | Complete the selection. Each item must have a value before exercise 0.2. |
| Phase 6, start of the GUI stage | Select the GUI library (see "GUI library"). |
| The learner asks to change a tool | Explain the cost (see "Change a tool later"). Do the selection for that item again. |

## Items to select

| Item | Default | Alternatives |
|---|---|---|
| Compiler | The native compiler of the operating system (see "Defaults by operating system") | GCC, Clang, MSVC, clang-cl, MinGW-w64 |
| Build system | CMake 3.28+ with presets and Ninja | Meson, xmake, Bazel, a plain Makefile (only for phases 0–1) |
| Library management | Manual: vendored sources, header-only files, `FetchContent` with a hash | vcpkg (manifest mode), Conan 2, the system package manager (Linux, Homebrew, MSYS2) |
| Test framework | doctest | Catch2, GoogleTest |
| Editor or IDE | VS Code with clangd and CMake Tools | CLion, Visual Studio, Qt Creator, Neovim or Emacs with clangd, Zed |
| Debugger | The debugger of the toolchain | gdb, LLDB, Visual Studio debugger |
| GUI library (phase 6) | Dear ImGui with SDL3 | Qt 6 |

## Step 1: Ask

Ask these questions. Use the answers that are already in the profile, and do not ask them again.

1. Which operating system do you use for the course?
2. Which C++ tools do you already have or use at work (compiler, IDE, build system)?
3. Do you want to learn the tools that are most common in industry, or the tools that are easiest to start with?
4. Do you have a reason to use a specific tool (a job requirement, a team standard, a platform)?

## Step 2: Suggest

1. If the learner has no preference, suggest the defaults for their operating system (below).
2. If the learner names a tool, check it against the requirements below. If it does not meet a requirement, say which phase gets harder.
3. Explain each choice in one or two sentences. Do not give a long comparison unless the learner asks. Point to `docs/topics/build-systems.md` and `docs/topics/external-libraries.md` for the details.

### Requirements

| Requirement | Why |
|---|---|
| The compiler supports the C++23 subset of the course | The check program in `docs/software-setup.md` must compile and run. |
| The build system can build a library, executables, and tests, and run the tests | All phases |
| The build system can produce `compile_commands.json`, or the IDE understands the project directly | clangd and clang-tidy need it |
| The toolchain can build with AddressSanitizer | Phases 0–8 |
| A path to ThreadSanitizer (GCC or Clang on Linux or macOS, or WSL2 on Windows) | Phase 6. On native Windows, explain the alternative: WSL2, or a CI job on Linux. |
| The library management method can pin exact versions | All phases from phase 0 |

### Defaults by operating system

| Operating system | Compiler | Build | Editor | Notes |
|---|---|---|---|---|
| Windows | MSVC (Visual Studio 2022 17.10+ or Visual Studio 2026, or the Build Tools) | CMake + Ninja from a "Developer PowerShell", or the Visual Studio generator | VS Code + clangd, or Visual Studio | MSVC supports AddressSanitizer, but not UndefinedBehaviorSanitizer or ThreadSanitizer. Use clang-cl or WSL2 for them, or run them in CI on Linux. |
| macOS | Apple Clang (Xcode command-line tools). LLVM Clang 20 or newer from Homebrew if the check program fails: Apple Clang uses libc++, and a libc++ older than version 20 does not have `std::jthread` without a flag, or floating-point `std::from_chars`. | CMake + Ninja from Homebrew | VS Code + clangd, or CLion | Apple Clang does not include `clang-format` and `clang-tidy`. Install them with the Homebrew `llvm` package. |
| Linux | GCC 14+ (or Clang 18+ with libstdc++ 14) from the distribution | CMake + Ninja from the distribution (or from Kitware or `pip` if the version is older than 3.28) | VS Code + clangd, or CLion | All sanitizers work. |

### Library management

Explain the order in which the course teaches the methods:

1. **Manual (default, phases 0–4):** the learner sees every step: the source, the version, the license, the build options. It works with every build system.
2. **`FetchContent` or the equivalent of the build system (phases 0–7):** the build system downloads a pinned version. Less manual work, same control.
3. **A package manager (optional, from phase 4):** vcpkg or Conan. Useful for large libraries with many dependencies (Boost, Qt, SDL3). The learner must still understand pinning, licenses, and ABI compatibility.

If the learner selects a package manager, the manual exercises in phase 0 (exercise 0.8) and phase 4 stay mandatory. They teach what the package manager does.

### GUI library

At the start of phase 6, explain the two options:

| | Dear ImGui with SDL3 | Qt 6 |
|---|---|---|
| Model | Immediate mode: the program draws the whole UI in each frame | Retained mode: widgets and signals and slots (or QML) |
| Size | Small. Add it by hand: copy the source files. | Large. Install it with the Qt online installer, a package manager, or the system package manager. |
| Build | Plain C++ files. SDL3 builds with CMake. | Needs the Qt tools (`moc`, and `rcc` or `uic` when used). Best support with CMake. |
| License | MIT (Dear ImGui), zlib (SDL3) | LGPL v3 or commercial. Dynamic linking and the LGPL rules apply. |
| Good for | Tools, debug views, fast start | Applications that look native, complex forms, industry experience |

Recommend Dear ImGui with SDL3, unless the learner wants Qt experience for work.

## Step 3: Record

Fill in the "Toolchain" section of `learner/profile.md` with the selected value of each item and its version (for example "GCC 14.2", "CMake 3.31", "doctest 2.4.12"). Update the versions at the start of each phase if the learner updates a tool.

## Adapt the course to the toolchain

In every session, if a toolchain item in the profile is not the default:

1. Read the phase document as usual.
2. Before you give the learner a command or a configuration file, translate it to their toolchain. Use the tables in `docs/topics/build-systems.md` (build systems), `docs/topics/external-libraries.md` (library management), and the table below (test frameworks).
3. Keep the result the same: a warning set that is equivalent, sanitizers where possible, the same layout of libraries, executables, and tests.
4. Check each translated command before you give it to the learner, if the tool is available. Do not guess option names.
5. If a feature of the course is not available in the learner's toolchain (for example ThreadSanitizer on MSVC), say so, and give the alternative.

### Test frameworks

| Concept | doctest | Catch2 v3 | GoogleTest |
|---|---|---|---|
| Header | `<doctest/doctest.h>` | `<catch2/catch_test_macros.hpp>` | `<gtest/gtest.h>` |
| A test | `TEST_CASE("name")` | `TEST_CASE("name")` | `TEST(Suite, Name)` |
| A check that continues | `CHECK(a == b)` | `CHECK(a == b)` | `EXPECT_EQ(a, b)` |
| A check that stops the test | `REQUIRE(a == b)` | `REQUIRE(a == b)` | `ASSERT_EQ(a, b)` |
| An expected exception | `CHECK_THROWS_AS(expr, Type)` | `CHECK_THROWS_AS(expr, Type)` | `EXPECT_THROW(expr, Type)` |
| Sections or fixtures | `SUBCASE("name")` | `SECTION("name")` | A fixture class with `TEST_F` |
| The `main` function | `#define DOCTEST_CONFIG_IMPLEMENT_WITH_MAIN` in one file | Link `Catch2::Catch2WithMain` | Link `GTest::gtest_main` |
| Distribution | One header | Library (compiled) | Library (compiled) |

## Change a tool later

| Change | Cost |
|---|---|
| Compiler | Low. Fix the new warnings. The code is portable. |
| Editor | Low. Configure clangd or the IDE again. |
| Test framework | Medium. Rewrite the test macros. A script can do most of it. |
| Library management method | Medium. Change the dependency declarations. The code does not change. |
| Build system | High after phase 4: all build files change. Recommend it only with a good reason. |
| GUI library | High after phase 6: the GUI adapter changes completely. The core does not change, if the design follows phase 5. |
