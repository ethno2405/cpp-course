# Phase 0: Tools, Build, and Environment

**Time:** 1–2 weeks. Plan 2 weeks if git, the terminal, or a compiled language is new to you.
**Prerequisites:** Programming experience in at least one language.
**Code:** `labs/phase-0-tools/`

## Goal

At the end of this phase, you can:

- Select, install, and check a C++23 toolchain: a compiler, a build system, an editor with a language server, a debugger, and the format and lint tools.
- Explain what the preprocessor, the compiler, and the linker do, and why C++ has headers.
- Build a project with a library, an executable, and tests with your build system.
- Read a compiler error and a linker error, also a long template error.
- Build with the warning set of the course, and fix the warnings.
- Format code with clang-format, and find problems with clang-tidy.
- Stop a program at a breakpoint and inspect its variables.
- Find undefined behavior with AddressSanitizer and UndefinedBehaviorSanitizer.
- Add a third-party library without a package manager, pinned to a version and checked with a hash.
- Evaluate a library before you add it.

## Reading

| Source | Part |
|---|---|
| [../software-setup.md](../software-setup.md) | All |
| [../topics/build-systems.md](../topics/build-systems.md) | All. Read the section of your build system carefully. |
| [../topics/external-libraries.md](../topics/external-libraries.md) | "What a C++ library is", "Methods", "Best practices for manual management" |
| learncpp.com | Chapter 0 ("Introduction / Getting Started"): the compilation process, the compiler, the linker, build configurations |
| CMake documentation, "CMake Tutorial" | Steps 1–3 (only if you use CMake) |
| cppreference.com | The main page and one page of a standard library type (for example `std::vector`). Learn how a page is organized. |
| Pro Git (git-scm.com/book) | "Git Basics" and "Git Branching" (only if git is new to you) |

## Topics

### 0.1 The C++ standard and the compilers

- C++ is defined by an ISO standard. A new version comes every three years: C++11, C++14, C++17, C++20, C++23, and C++26 is next. C++11 started "modern C++". C++98 and C++03 are "old C++".
- The standard defines the language and the **standard library** (`std::vector`, `std::string`, `std::thread`, and many more). Each compiler comes with a standard library implementation:

  | Compiler | Standard library | Platforms |
  |---|---|---|
  | GCC (`g++`) | libstdc++ | Linux, Windows (MinGW-w64), macOS |
  | Clang (`clang++`) | libc++ or libstdc++ | All. Apple Clang is the Apple version. |
  | MSVC (`cl`) | Microsoft STL | Windows |

- Compilers implement new features over several versions. A feature that one compiler has can be missing in another. The course uses only the C++23 features that all supported compilers have (see the "C++23 support" table in [../software-setup.md](../software-setup.md)). When you read about a feature on cppreference.com, look at the version mark (for example "(since C++23)"), and at the compiler support page.
- **Implementation-defined** and **undefined behavior:** the standard does not define everything. The size of `int` is implementation-defined: each compiler documents it. Undefined behavior (UB) has no rules at all. Topic 0.9 shows how to find UB.

### 0.2 The compilation model

A C++ program goes through these steps:

```text
greeting.hpp ─┐
greeting.cpp ─┴─> preprocessor ─> compiler ─> greeting.o ─┐
main.cpp ─────────> preprocessor ─> compiler ─> main.o ─────┼─> linker ─> starter (executable)
                                                 libstdc++ ─┘
```

1. **Preprocessor:** handles the lines that start with `#`. `#include <vector>` copies the content of the header into the file. `#define` and `#if` change the text. The result is one **translation unit**.
2. **Compiler:** translates one translation unit to an **object file** (`.o` or `.obj`) with machine code. It sees only this one translation unit. To call a function from a different file, it needs a **declaration** (`std::string make_greeting(std::string_view name);`), usually from a header.
3. **Linker:** joins the object files and the libraries. It connects each call to the **definition** of the function (the function with its body). If no definition exists, you get a linker error: "undefined reference" (GCC, Clang) or "unresolved external symbol" (MSVC). If two definitions exist, you get "multiple definition".

Rules that follow from this model:

- A header contains declarations, type definitions, templates, and `inline` functions. A source file (`.cpp`) contains the definitions of normal functions and variables.
- The **one definition rule (ODR):** each function and variable has exactly one definition in the program. Types, templates, and `inline` functions can be defined in many translation units, but all definitions must be the same.
- Use `#pragma once` (or include guards) at the top of each header, so that a second `#include` of the same header in one translation unit does nothing.
- A change to a header makes the build system compile every file that includes it. Keep headers small.
- **Static library** (`.a`, `.lib`): a collection of object files that the linker copies into the executable. **Shared library** (`.so`, `.dylib`, `.dll`): loaded at run time, shared by several programs.
- C++20 **modules** replace headers for some uses. Their support in compilers and build systems is still new. Phase 4 shows them. The course uses headers.

### 0.3 Build systems

- A build system knows the targets of a project (libraries, executables, tests), their source files, their options, and the dependencies between them. It compiles only what changed.
- **CMake** is the default in the course documents. CMake is a build system generator: it reads `CMakeLists.txt` and writes the files for a build tool (Ninja, Make, or a Visual Studio solution). Read [../topics/build-systems.md](../topics/build-systems.md) for the alternatives (Meson, xmake, Bazel, Make) and the command translation.
- A minimal CMake project:

  ```cmake
  cmake_minimum_required(VERSION 3.28)
  project(hello LANGUAGES CXX)

  set(CMAKE_CXX_STANDARD 23)
  set(CMAKE_CXX_STANDARD_REQUIRED ON)
  set(CMAKE_CXX_EXTENSIONS OFF)

  add_library(greeting src/greeting.cpp)
  target_include_directories(greeting PUBLIC include)

  add_executable(hello app/main.cpp)
  target_link_libraries(hello PRIVATE greeting)
  ```

- Commands:

  | Command | Result |
  |---|---|
  | `cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Debug` | Configure: write the build files to `build/` |
  | `cmake --build build` | Build all targets |
  | `cmake --build build --target hello` | Build one target |
  | `ctest --test-dir build` | Run the registered tests |
  | `cmake --preset dev` | Configure with the settings of the preset `dev` in `CMakePresets.json` |
  | `cmake --build --preset dev`, `ctest --preset dev` | Build and test with a preset |

- **Build types:** `Debug` (no optimization, debug information), `Release` (optimized, `NDEBUG` is defined, so `assert` does nothing), `RelWithDebInfo` (optimized, with debug information; good for profiling). Undefined behavior can give different results in different build types.
- **Out-of-source builds:** all generated files go into the build directory. Never commit the build directory. To start from zero, delete it.
- **Presets:** `CMakePresets.json` gives names to configurations, so that every developer and the CI use the same settings. Look at the [starter project](../templates/cpp-project/CMakePresets.json).

### 0.4 The editor and the language server

- **clangd** is the language server of the course. It compiles your code in the background with the same options as the build. It reads them from `compile_commands.json`, which the build system writes (CMake: `CMAKE_EXPORT_COMPILE_COMMANDS=ON`). Without this file, clangd guesses the options, and it shows wrong errors.
- IDEs like CLion and Visual Studio read the CMake project directly.
- Learn these functions in your editor: completion, errors while you type, go to definition, go to declaration, switch between the header and the source file, find all references, rename a symbol, show the documentation on hover, quick fixes, run and debug a single test.
- Configure the editor to run clang-format when you save a file.

### 0.5 Read compiler and linker errors

A GCC error:

```text
main.cpp: In function 'int main()':
main.cpp:5:11: error: assignment of read-only variable 'count'
    5 |     count += 1;
      |     ~~~~~~^~~~
```

| Part | Content |
|---|---|
| `main.cpp:5:11` | The file, the line, and the column |
| `error:` | The kind: `error`, `warning`, or `note` (more information about the previous message) |
| The text | What is wrong |
| The code line with `^` and `~` | The position of the problem |

MSVC shows the same information in a different form: `main.cpp(5): error C3892: 'count': you cannot assign to a variable that is const`. Each MSVC message has a code (C3892). Search for the code in the Microsoft documentation.

- Read the **first** error first. Later errors are often results of the first one.
- **Template errors** can be very long, because the compiler shows each step of the template instantiation. Find the first `error:` line, then the line that points to your own code ("required from here"). With concepts (phase 3), the compiler says which requirement failed: look for "constraints not satisfied" and the "note:" lines below it.
- **Linker errors** have no line number in your code. They name a symbol, for example ``undefined reference to `make_greeting(std::basic_string_view<char> ...)'``. Ask: is the source file with the definition in the target? Is the library linked? Does the declaration match the definition exactly?

### 0.6 Warnings

- A warning says that the code is valid C++, but it is probably wrong. Many C++ bugs are visible as warnings: a narrowing conversion, a comparison between signed and unsigned values, a variable that hides another variable, a missing `return`.
- Compilers enable only a few warnings by default. Enable the warning set of the course ([../software-setup.md](../software-setup.md), "Warnings"), and treat warnings as errors (`-Werror`, `/WX`). The starter project does this in `cmake/CompilerWarnings.cmake`.
- Different compilers find different problems. If you can, build your code with two compilers from time to time (for example GCC and Clang on Linux, or MSVC and clang-cl on Windows). The CI pipeline in phase 8 does this.

### 0.7 Format and lint

- **clang-format** formats the code with the style in the `.clang-format` file. In a team, nobody discusses the format: the tool decides. Run it on save, and check it in CI with `clang-format --dry-run --Werror`.
- **clang-tidy** is a linter. It finds bugs (`bugprone-*`), style problems, and code that a newer C++ form can replace (`modernize-*`). The `.clang-tidy` file selects the checks. clangd can show clang-tidy findings in the editor.
- Run clang-tidy with the compilation database: `clang-tidy -p build/dev src/greeting.cpp`.
- Each finding has a check name in brackets, for example `[modernize-loop-convert]`. Read the documentation of the check (clang.llvm.org/extra/clang-tidy): it explains why the check exists.

### 0.8 Debugging

- Build a debug build for the debugger: optimized code is hard to follow, because the compiler removes and reorders code.
- A **debugger** stops the program at a breakpoint. You can step through the code, see the call stack, and look at the variables. In VS Code: the C/C++ extension (MSVC, gdb) or CodeLLDB (LLDB). CLion and Visual Studio have a built-in debugger.
- Learn: set a breakpoint, a conditional breakpoint ("stop when `i == 42`"), step over, step into, step out, continue, the call stack, the watch window.
- `assert(condition)` from `<cassert>` stops the program in a debug build when a condition that must be true is false. It does nothing when `NDEBUG` is defined (release builds). Use it for bugs, not for invalid user input.
- For a quick check, print to stderr: `std::println(stderr, "x = {}", x);`. Remove it before you commit.

### 0.9 Undefined behavior and the sanitizers

- If a program has undefined behavior, the C++ standard puts no requirements on it. It can crash, print a wrong value, print the expected value, or delete code that you think is necessary. The compiler can assume that UB never happens, and it optimizes based on this assumption.
- Common sources of UB: an index out of range, the use of an object after its lifetime ended, signed integer overflow, an uninitialized variable, a null pointer dereference, a data race (phase 6).
- **A test that passes does not prove that the code has no UB.** Run your tests with the sanitizers:

  | Sanitizer | Finds |
  |---|---|
  | AddressSanitizer (ASan) | Out-of-range access, use after free, use after return, double free, leaks |
  | UndefinedBehaviorSanitizer (UBSan) | Signed overflow, invalid shifts, misaligned access, null pointer use, invalid enum and `bool` values |

- The `dev` preset of the starter project enables both (MSVC: only ASan). Use it for your daily work.
- A sanitizer report shows the kind of error, the stack of the bad access, and, for ASan, where the memory was allocated and freed. Read it from the top.

### 0.10 Documentation

| Source | Content |
|---|---|
| cppreference.com | The language and the standard library. Each page shows the header, the standard version, the parameters, the return value, the complexity, the exceptions, and an example. |
| The C++ Core Guidelines | Rules with reasons. The course refers to them. |
| Compiler Explorer (godbolt.org) | Compile a small example with many compilers. See the errors, the warnings, and the generated machine code. |
| The documentation of your compiler | The options and the warnings (gcc.gnu.org/onlinedocs, clang.llvm.org/docs, learn.microsoft.com/cpp) |
| The documentation of each library, for the version that you use | APIs change between versions |

### 0.11 Third-party libraries

Read [../topics/external-libraries.md](../topics/external-libraries.md). The short version:

- C++ has no single standard package manager. The course teaches manual management first: header-only files, vendored sources, and pinned downloads. Package managers (vcpkg, Conan) are optional, from phase 4.
- Pin each library to an exact version. Check the hash. Keep the license. Write each library in `third_party/README.md`.
- Before you add a library, check:

  | Check | Where |
  |---|---|
  | The date of the last release, and the activity in the repository | The repository |
  | The license | The `LICENSE` file |
  | The quality of the documentation and the examples | The website or the README |
  | The supported compilers and C++ versions | The README, the CI configuration of the project |
  | How it is built and distributed: header-only, CMake support, `find_package` support | The build files |
  | Its own dependencies | The build files |
  | Known security problems | The release notes, the GitHub security advisories |

### 0.12 Git

Skip this topic if you use git every day.

- The three areas: the working tree, the index (staging area), and the repository. Commands: `git status`, `git add`, `git commit`, `git log --oneline`, `git diff`, `git diff --staged`, `git restore`.
- Make small commits. One commit = one logical change that builds and passes its tests.
- Write the commit message in the imperative, as one line: "Add the FEN parser", not "added stuff".
- A branch is a pointer to a commit. `git switch -c <name>` makes a branch and switches to it. `git merge` joins two branches. A **pull request** asks the team to review and merge a branch (phase 8).
- In this course, your work is on your track branch (see the main README). Do not commit build directories: the `.gitignore` of the course ignores `build/` and `out/`.

## Exercises

Make the project `labs/phase-0-tools/` with a root `CMakeLists.txt` (or the build file of your build system) that adds one subdirectory for each exercise (`add_subdirectory(ex-0-03-first-project)`). Copy `.clang-format`, `.clang-tidy`, `CMakePresets.json`, and the `cmake/` directory from the [starter project](../templates/cpp-project/) to `labs/phase-0-tools/`, and change the project name in the files. Ask the mentor if you do not know how.

### Exercise 0.1: Select and install the toolchain

1. Read [../software-setup.md](../software-setup.md), sections 1–3. Select your compiler, build system, and editor. If you do not know, use the defaults. With a mentor, the mentor records your selection in your profile.
2. Install the tools.
3. Do the checks in section 4: the versions, the check program, the starter project, and the debugger. Write the versions in your engineering notebook.

### Exercise 0.2: Build by hand (core)

Do this exercise without a build system, so that you see what a build system does for you.

1. In `ex-0-02-by-hand/`, write `greeting.hpp` with the declaration `std::string make_greeting(std::string_view name);`, `greeting.cpp` with the definition, and `main.cpp` that calls it.
2. Compile each source file to an object file. GCC or Clang: `g++ -std=c++23 -c greeting.cpp`. MSVC: `cl /std:c++latest /EHsc /c greeting.cpp`. Find the object files.
3. Link the object files to an executable. GCC or Clang: `g++ greeting.o main.o -o greeting`. MSVC: `cl greeting.obj main.obj`. Run it.
4. Change only `greeting.cpp`. Which steps must you repeat? Change only `greeting.hpp`. Which steps must you repeat now?
5. Link without `greeting.o`. Read the linker error. Then add a second definition of `make_greeting` in `main.cpp`, and link again. Read the error.
6. Optional: write a `Makefile` for the three files (see [../topics/build-systems.md](../topics/build-systems.md)). Does it rebuild `main.o` when `greeting.hpp` changes? Why or why not?

### Exercise 0.3: The first project with a build system (core)

1. In `ex-0-03-first-project/`, make a library target `greeting` (the files from exercise 0.2, with the header in `include/`), and an executable target that uses it.
2. Build with your preset or configuration. Run the program.
3. Change the program: read a name from the first command-line argument, and print a usage message to stderr and return a non-zero exit code if the argument is missing.
4. Build a release configuration. Compare the size of the debug and the release executables.
5. Open the project in your editor. Check that go to definition works from `main.cpp` into `greeting.cpp`. If it does not, find `compile_commands.json`, and check the clangd or IDE configuration.

### Exercise 0.4: Read compiler and linker errors (core)

Put each fragment into a `main` function (with the necessary `#include` lines). Before you compile it, predict the error. Compile it, read the full message, and fix it.

```cpp
const int count = 0;
count += 1;
```

```cpp
int total = "42";
```

```cpp
std::list<int> values{3, 1, 2};
std::ranges::sort(values);
```

```cpp
int square(int x);   // declared, never defined
int main() { return square(3); }
```

```cpp
std::vector<int> numbers{1, 2, 3};
int first = numbers[3];
std::println("{}", first);
```

- For the `std::ranges::sort` fragment: find the line that says which concept the type does not satisfy. Why can `std::list` not be sorted with this algorithm? (Hint: look at the iterator category on cppreference.com.)
- The last fragment compiles, maybe without a warning. Run it. What happens? Run it again in the `dev` preset with the sanitizers. What happens now? Why does the compiler not stop this error?

### Exercise 0.5: Warnings and clang-tidy (core)

1. Copy this function into `ex-0-05-lint/`. Call it from `main`. Build it first without the warning set, then with the warning set of the course.

   ```cpp
   double average(std::vector<double> values) {
       double sum = 0;
       for (int i = 0; i < values.size(); i++) {
           sum = sum + values[i];
       }
       if (values.size() == 0) return 0;
       return sum / values.size();
   }
   ```

2. Read each warning. Fix each one.
3. Run clang-tidy on the file. Read the documentation of each check that it reports. Fix each finding, or write in your notebook why you do not agree with it.
4. Run clang-format. Look at the diff.

### Exercise 0.6: Debugger

1. In `ex-0-06-debugger/`, write a function `int factorial(int n)` that computes the factorial in a loop. Call it in `main` with 10, and print the result.
2. Set a breakpoint in the loop. Start the debugger. Step through three iterations and watch the variables. Use a conditional breakpoint that stops when the loop variable is 7.
3. Call the function with 20. Run the `debug` build, then the `release` build, then the `dev` build with the sanitizers. Explain the results. (Hint: signed integer overflow.)
4. Change the function so that it cannot overflow for its input: return `std::optional<std::int64_t>`, or reject inputs that are too large. Write tests for 0, 1, 20, and 21.

### Exercise 0.7: Sanitizers (core)

Write a small program in `ex-0-07-sanitizers/` for each error. Run each one in the `debug` build, and then in the `dev` build. Write the result of each run in your notebook.

1. Read the element after the end of a `std::vector` with `operator[]`.
2. Keep a reference to an element of a `std::vector`, call `push_back` many times, then read through the reference.
3. Return a reference to a local variable from a function, and read it in the caller.
4. Shift `1` to the left by 40 bits in an `int`.

Which errors does the debug build show without the sanitizers? Which ones does each sanitizer show? Which ones does MSVC show (if you use it)?

### Exercise 0.8: Add a library without a package manager (core)

1. In `ex-0-08-libraries/`, make a library with one function (for example `int clamp_percent(int value)`), and a test executable.
2. Add **doctest** by hand: follow the [starter project](../templates/cpp-project/third_party/README.md). Download the header of a release tag, compute its hash, and write the dependency list. Make an `INTERFACE` target with a `SYSTEM` include directory. Register the test with your test runner. Run the tests.
3. Make a second version in `ex-0-08b-fetchcontent/` that gets doctest with `FetchContent` (or the equivalent of your build system), pinned with `URL` and `URL_HASH`. Configure it. Change one character of the hash, and configure again in a new build directory. Read the error.
4. Write in your notebook: which version would you use in a team, and why? What does each method need when you work offline?
5. Optional: add the same library with vcpkg or Conan. Compare the steps.

### Exercise 0.9: Evaluate libraries

1. Find three JSON libraries for C++ (for example nlohmann/json, Boost.JSON, and glaze or simdjson).
2. Compare them with the table in topic 0.11, and add two rows: the compile time of a small example, and the ease of use for your project.
3. Select one for phase 7. Write three sentences about why.

## Done criteria

- [ ] My compiler compiles and runs the check program. My build system builds and tests the starter project. My editor shows errors and goes to definitions. My debugger stops at a breakpoint.
- [ ] I can explain the jobs of the preprocessor, the compiler, and the linker, and the difference between a declaration and a definition.
- [ ] I can explain a linker error and find its cause.
- [ ] I can explain the difference between the debug and the release build types, and why UB can give different results in each.
- [ ] My code has no warnings with the warning set of the course, is formatted with clang-format, and has no clang-tidy findings (or a written reason for each one).
- [ ] I can find an out-of-range access and a use after free with AddressSanitizer.
- [ ] I can add a library by hand, pinned to a version and checked with a hash, and record it in the dependency list.

## Next

[Phase 1: C++ basics](phase-1-cpp-basics.md)
