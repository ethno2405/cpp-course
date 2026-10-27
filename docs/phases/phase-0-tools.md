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
main.cpp ─────────> preprocessor ─> compiler ─> main.o ─────┼─> linker ─> greeting (executable)
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
- **Build sequence:** identify which tool reads the project description, determines dependencies, selects the required steps, and runs the compiler and linker. A generator has a configuration step before the build tool runs. Other build systems combine these operations. Explain the sequence for your selected tools.
- **Dependencies:** the build system needs to know which outputs depend on each source file and header. Explain how your selected tools discover header dependencies. Cover the first build, when no dependency records exist, and later builds, which can use records from an earlier compilation. Explain what happens when a header is removed or renamed. A missing header that the source still includes remains an error. Use the dependency handling that your tools provide; handwritten dependency rules are optional learning work.
- **Reusable settings:** use the selected tool's settings, variables, or functions for shared compiler options and output paths. Before using them, explain when their values are evaluated and which tool interprets each expression. Explain the path and quoting rules where a command passes from the build tool to a shell. Do not assume that shell quoting also applies to the build description.
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
- **Out-of-source builds:** keep generated files in a separate build directory from the first build. Identify object files, executables, generated build files, and dependency records. Explain which files can be regenerated and which files belong in git. Ignore the build directory before the first build. If the tool manages its own output directories, use that layout and explain it.
- **Clean and parallel builds:** a clean operation removes generated outputs. Use the tool's existing operation when available. Explain its deletion scope before running it; a clean operation can preserve configuration and dependency records. A build from a new build directory also checks that the project does not need old generated files. In a parallel build, every required input and output directory must exist before the dependent command runs. Use the tool's automatic handling where available. See [Build checks](../topics/build-systems.md#build-checks) for the checks and tool-specific commands.
- **Presets:** `CMakePresets.json` gives names to configurations, so that every developer and the CI use the same settings. A minimal file with one configure preset:

  ```json
  {
    "version": 6,
    "configurePresets": [
      {
        "name": "dev",
        "generator": "Ninja",
        "binaryDir": "${sourceDir}/build/${presetName}",
        "cacheVariables": { "CMAKE_BUILD_TYPE": "Debug" }
      }
    ]
  }
  ```

  Exercise 0.9 extends it with more presets, build presets, and test presets. Read "cmake-presets(7)" in the CMake documentation for all fields.

### 0.4 The editor and the language server

- **clangd** is the default language server of the course. If your editor uses clangd, configure it as follows. It parses your code with the Clang parser. Give it the standard, include paths, and definitions of the build through `compile_commands.json` (CMake with Ninja: `CMAKE_EXPORT_COMPILE_COMMANDS=ON`). Before a build system exists, configure the standalone file as [software-setup.md](../software-setup.md#configure-the-standalone-check) describes. Without these settings, clangd can show errors for code that the compiler accepts.
- IDEs like CLion and Visual Studio can read the project settings directly. If you use their own C++ analysis, select the compiler and C++23 in those settings. You do not need a separate clangd configuration.
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
- Compilers enable only a few warnings by default. Enable the warning set of the course ([../software-setup.md](../software-setup.md), "Warnings"), and treat warnings as errors (`-Werror`, `/WX`). In exercise 0.5, you write the build code that applies the warning set to your targets.
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

- In exercise 0.7, you add a build option that enables both (MSVC: only ASan). In exercise 0.9, the `dev` preset uses it. Use it for your daily work.
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

In this phase, you build the project setup of the course yourself, one part in each exercise: the build file, the library layout, the C++23 settings, the warning set, format and lint, the sanitizers, a test framework, and presets. At the end (exercise 0.9), your phase 0 project is your template. You copy its setup to each new project of the course, and you improve it when you learn more.

Make the project `labs/phase-0-tools/` with one root build file (CMake: `CMakeLists.txt`) and one subdirectory for each exercise:

- The **root build file** holds the settings for all exercises: `project()`, the C++ standard, the includes of your `cmake/` modules, and `enable_testing()`. It adds each exercise with `add_subdirectory(ex-0-03-first-project)`.
- The build file of an **exercise subdirectory** holds only the targets of that exercise.
- You configure, build, and test from the root, into one build directory.
- Two exercises are not in the root build file: exercise 0.2 (it has no build file), and exercise 0.8b (a separate small project, so that you can configure it alone).

The commands below use CMake. If you use a different build system, the [build systems topic](../topics/build-systems.md) and your mentor translate them.

The project setup is complete when it meets these requirements. Exercise 0.9 checks them.

| Requirement | Exercise |
|---|---|
| Out-of-source builds; the build directory is not in git | 0.3 |
| Automatic header dependency tracking; checked incremental and clean parallel builds | 0.3 |
| A clean operation with a known deletion scope | 0.3 |
| A library target with public headers in `include/<project>/`, sources in `src/`, and a thin executable in `app/` | 0.3 |
| C++23 without compiler extensions | 0.3 |
| `compile_commands.json` for clangd and clang-tidy | 0.3 |
| The warning set of the course on your own targets, as errors; not on third-party targets | 0.5 |
| A `.clang-format` file and a `.clang-tidy` file, with a reason for each disabled check | 0.5 |
| A build option for the sanitizers (address and undefined, or thread) | 0.7 |
| A test executable with doctest (or your framework), registered with the test runner | 0.8 |
| A dependency list in `third_party/README.md` | 0.8 |
| Presets (or the equivalent) for daily work with sanitizers, debugging, release, and ThreadSanitizer | 0.9 |
| A `README.md` with the commands to configure, build, test, format, and lint | 0.9 |

### Exercise 0.1: Select and install the toolchain

1. Read [../software-setup.md](../software-setup.md), sections 1–3. Select your compiler, build system, and editor. If you do not know, use the defaults. With a mentor, the mentor records your selection in your profile.
2. Install the tools.
3. Do the checks in section 4: the versions, the check program, the editor diagnostics, and the debugger. Check both the build and the editor before you complete this exercise. Write the versions in your engineering notebook.

### Exercise 0.2: Build by hand (core)

Do this exercise without a build system, so that you see what a build system does for you.

**Mentor preparation:** follow [Explain prerequisites before use](../mentor/mentoring.md#explain-prerequisites-before-use) and [Explain commands](../mentor/mentoring.md#explain-commands). Before the exercise, explain:

- Repeated header inclusion and protection with `#pragma once` or include guards. Explain that the protection applies within each translation unit.
- The header search rules for quoted and angle-bracket includes in the selected toolchain.
- Direct and transitive includes. Show how to find the documented header for a standard library name.
- Each new option in the compilation and linking commands, including the warning options that the learner uses.

During the linker error checks, follow [Teach diagnostic reading](../mentor/mentoring.md#teach-diagnostic-reading). After the learner's attempt, explain the reported symbol and location. For GCC with libstdc++, this can include expanded type aliases, application binary interface (ABI) tags such as `[abi:cxx11]`, and section offsets such as `.text+0x45`. Explain only the notation that appears in the actual output. Let the learner discover each result before you validate it.

1. In `ex-0-02-by-hand/`, write `greeting.hpp` with the declaration `std::string make_greeting(std::string_view name);`, `greeting.cpp` with the definition, and `main.cpp` that calls it.
2. Compile each source file to an object file. GCC or Clang: `g++ -std=c++23 -c greeting.cpp`. MSVC: `cl /std:c++latest /EHsc /c greeting.cpp`. Find the object files.
3. Link the object files to an executable. GCC or Clang: `g++ greeting.o main.o -o greeting`. MSVC: `cl greeting.obj main.obj`. Run it.
4. Change only `greeting.cpp`. Which steps must you repeat? Change only `greeting.hpp`. Which steps must you repeat now?
5. Link without `greeting.o`. Read the linker error. Then add a second definition of `make_greeting` in `main.cpp`, and link again. Read the error.
6. Optional: write a `Makefile` for the three files (see [../topics/build-systems.md](../topics/build-systems.md)). Does it rebuild `main.o` when `greeting.hpp` changes? Why or why not?

### Exercise 0.3: The first project with a build system (core)

Do each step, and do its check before you continue.

Use your selected build system. The CMake names below show the default implementation. Before the first build, explain the build sequence, the output locations, and the files that git must ignore. Before each later step, explain the new settings and when the tools evaluate them. Use [Build checks](../topics/build-systems.md#build-checks) to translate the checks. Do not write custom dependency, directory-creation, or clean rules when the selected tools already provide them.

1. **One executable.** Write the root build file with `cmake_minimum_required` and `project()`. In `ex-0-03-first-project/`, write a build file with one executable target from `main.cpp`, and add the subdirectory to the root build file. Configure the root into a separate build directory, build, and run the executable.
   - Check: `git status` shows no generated file. All generated files are in the build directory.
2. **A library and an executable.** Move `make_greeting` into a library target `greeting`: the header in `include/greeting/greeting.hpp`, the source in `src/greeting.cpp`. The executable in `app/main.cpp` links the library and includes `<greeting/greeting.hpp>`. The include directory is a usage requirement of the library (`target_include_directories(greeting PUBLIC include)`), not a global setting.
   - Check: the executable compiles without its own include directory setting.
3. **C++23 without extensions.** In the root build file, set the standard to C++23, make it required, and turn off the compiler extensions (CMake: `CMAKE_CXX_STANDARD`, `CMAKE_CXX_STANDARD_REQUIRED`, `CMAKE_CXX_EXTENSIONS`). Set them before `add_subdirectory`, so that all exercises get them.
   - Check: change `make_greeting` to return `std::expected<std::string, GreetingError>` (an empty name is an error). It compiles.
4. **The compilation database.** In the root build file, make the build write `compile_commands.json` (CMake: `CMAKE_EXPORT_COMPILE_COMMANDS`, with the Ninja or Makefile generator). Configure clangd or your IDE to use it.
   - Check: in the editor, go to definition from `app/main.cpp` goes into `src/greeting.cpp`, and the editor shows no false errors.
5. **Use it.** Read a name from the first command-line argument, and print a usage message to stderr and return a non-zero exit code if the argument is missing or the name is not valid.
6. **Build types.** Build a `Debug` and a `Release` configuration of the root project in two build directories. Compare the size of the executables.
7. **Incremental builds.** Before each check, predict which translation units need compilation and which libraries or executables need an update. Build after each change and explain the selected steps. Do not require identical output or command counts across tools.
   - Check: build again without changing any input. No compilation or linking is needed.
   - Check: change only the implementation in one source file. Unaffected translation units do not need compilation.
   - Check: change the shared project header. Translation units that include it, directly or indirectly, need compilation. Explain how the tools discover those dependencies.
8. **Clean and parallel builds.** Identify the tool's clean operation and its deletion scope. Keep only generated files in that scope. Run the clean operation, rebuild, and run the program. Then configure and build in a new build directory with parallel execution enabled. Use the selected tool's output layout if it manages the directories itself.
   - Check: the build succeeds without old generated files. Directories and generated inputs exist before commands need them. The program runs. A subsequent unchanged build needs no compilation or linking.

Before completing the exercise, explain the first build and one later rebuild. A successful command alone does not verify that you understand the dependencies.

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
- The last fragment compiles, maybe without a warning. Run it. What happens? Why does the compiler not stop this error? You come back to it in exercise 0.7.

### Exercise 0.5: Warnings, format, and lint (core)

1. **The warning set.** Write a reusable piece of build code that applies the warning set of the course ([../software-setup.md](../software-setup.md), "Warnings") to one target. In CMake, write a function `course_set_warnings(target)` in `cmake/CompilerWarnings.cmake`. It selects the options by compiler: `if(MSVC)` (this is also true for clang-cl), `CMAKE_CXX_COMPILER_ID` for GCC and Clang. Add the options with `target_compile_options(<target> PRIVATE ...)`. Add an option `COURSE_WARNINGS_AS_ERRORS` (default `ON`) for `-Werror` and `/WX`. For MSVC, also define `_CRT_SECURE_NO_WARNINGS` (see the setup document).
2. Apply the function to the library and the executable of exercise 0.3, and to every target that you make from now on. Do not apply it to third-party targets.
   - Check: add this function to the library. The build must fail with at least three different warnings. Read each one, then remove the function.

     ```cpp
     int sum_until(const std::vector<int>& values, int limit) {
         int total = 0;
         for (int i = 0; i < values.size(); i++) {
             int total = total + values[i];
             if (total > limit) return limit;
         }
     }
     ```

3. Copy this function into `ex-0-05-lint/`, and call it from `main`. Build it, and read every warning. **Do not fix it yet:** step 5 runs clang-tidy on the same code.

   To see all warnings without a stop of the build, configure a second build directory with `-DCOURSE_WARNINGS_AS_ERRORS=OFF`.

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

4. **Format.** Write a `.clang-format` file in the project root. Start from a predefined style (`BasedOnStyle: LLVM`, `Google`, `Microsoft`, or another one), and change only what you have a reason for (for example `IndentWidth` and `ColumnLimit`). Read the "Clang-Format Style Options" page for each option that you set. Configure your editor to format on save.
   - Check: `clang-format --dry-run --Werror` on a file with a wrong indentation fails. After `clang-format -i`, it passes.
5. **Lint.** Write a `.clang-tidy` file. Enable the check groups `bugprone-*`, `cppcoreguidelines-*`, `modernize-*`, `performance-*`, and `readability-*` (and more if you want). Run clang-tidy with the compilation database (`clang-tidy -p <build directory> <file>`). For each check that you disable, write the reason in a comment in the file. Limit the analysis to your own headers with `HeaderFilterRegex`.
   - Check: run clang-tidy on the `average` function from step 3. It must report at least `performance-unnecessary-value-param` and a `modernize-` or `readability-` check. Read the documentation of each check that it reports.
6. **Fix.** Fix every warning and every clang-tidy finding in `average`. Build again with warnings as errors, and run clang-tidy again. Both must report nothing.

### Exercise 0.6: Debugger

1. In `ex-0-06-debugger/`, write a function `int factorial(int n)` that computes the factorial in a loop. Call it in `main` with 10, and print the result.
2. Set a breakpoint in the loop. Start the debugger. Step through three iterations and watch the variables. Use a conditional breakpoint that stops when the loop variable is 7.
3. Call the function with 20. Run the debug build, then the release build. Explain the results. (Hint: signed integer overflow.) Exercise 0.7 shows a tool that finds this error.
4. Change the function so that it cannot overflow for its input: return `std::optional<std::int64_t>`, or reject inputs that are too large.

### Exercise 0.7: Sanitizers (core)

1. **The sanitizer option.** Add a build option that selects the sanitizers. In CMake, a cache variable `COURSE_SANITIZERS` (empty, `address;undefined`, or `thread`), and a function `course_enable_sanitizers(target)` in `cmake/Sanitizers.cmake`:
   - GCC and Clang: add `-fsanitize=<list>` and `-fno-omit-frame-pointer` to the compile options, and `-fsanitize=<list>` to the link options (`target_link_options`). Add `-fno-sanitize-recover=all`, so that the first error stops the program and a test fails.
   - MSVC: only `address` is available: `/fsanitize=address`. It does not work with the run-time checks `/RTC1`, which CMake adds to `CMAKE_CXX_FLAGS_DEBUG` by default: remove them for this build. Link with `/INCREMENTAL:NO`. Print a warning one time if the user selects `undefined` or `thread`.
   - Optional: the debug checks of the standard library (`_GLIBCXX_ASSERTIONS` for libstdc++ in debug builds).
2. Apply it to all your targets.
3. Write a small program in `ex-0-07-sanitizers/` for each error. Run each one in a debug build without sanitizers, and then with `address;undefined`. Write the result of each run in your notebook.
   1. Read the element after the end of a `std::vector` with `operator[]` (the last fragment of exercise 0.4).
   2. Keep a reference to an element of a `std::vector`, call `push_back` many times, then read through the reference.
   3. Return a reference to a local variable from a function, and read it in the caller. With GCC and Clang, AddressSanitizer finds this error only when you set the environment variable `ASAN_OPTIONS=detect_stack_use_after_return=1`. MSVC needs the extra compile option `/fsanitize-address-use-after-return` and the same environment variable.
   4. Shift `1` to the left in an `int`. Read the shift count from the command line, and run the program with 40.
   5. `factorial(20)` from exercise 0.6.

   These programs have defects on purpose. The warning set finds some of them at compile time (for example item 3, and item 4 if the shift count is a constant). That is a good result: write the warning in your notebook. To run such a program anyway, build it in a second build directory that you configure with `-DCOURSE_WARNINGS_AS_ERRORS=OFF` and the sanitizers (`-DCOURSE_SANITIZERS="address;undefined"`).
4. Which errors does the build without the sanitizers show? Which ones does each sanitizer show? Which ones does MSVC show (if you use it)?

### Exercise 0.8: Add a library without a package manager (core)

1. In `ex-0-08-libraries/`, make a library with one function (for example `int clamp_percent(int value)`), and a test executable in `tests/`.
2. **Add doctest by hand.**
   1. Open the release page of doctest on GitHub (github.com/doctest/doctest). Select a release tag. Download the single header `doctest/doctest.h` and the file `LICENSE.txt` of that tag, not of the `master` branch.
   2. Put them in `third_party/doctest/doctest/doctest.h` and `third_party/doctest/LICENSE.txt`.
   3. Compute the SHA-256 hash of the header (`sha256sum`, `shasum -a 256`, or `Get-FileHash -Algorithm SHA256`).
   4. Write `third_party/README.md` with the dependency list ([../topics/external-libraries.md](../topics/external-libraries.md), "Best practices for manual management", item 4).
   5. Make an `INTERFACE` target `doctest::doctest` with a `SYSTEM` include directory, so that warnings in the header do not stop your build.
   6. Write tests with doctest. Register the test executable with the test runner (CMake: `enable_testing()` and `add_test`). Run them with `ctest`.
   - Check: a test that fails makes `ctest` return a non-zero exit code.
3. **Add the same library with `FetchContent`** (or the equivalent of your build system) in `ex-0-08b-fetchcontent/`, pinned with `URL` and `URL_HASH`. This is a separate small project with its own `project()` and `enable_testing()`: do not add it to the root build file. Configure it alone. Change one character of the hash, and configure again in a new build directory. Read the error.
4. Write in your notebook: which method would you use in a team, and why? What does each method need when you work offline?
5. Optional: add the same library with vcpkg or Conan. Compare the steps.
6. Add tests with doctest to exercises 0.3 and 0.6 (the `factorial` limits: 0, 1, 20, 21).

### Exercise 0.9: Presets and the template (core)

1. **Presets.** Write a `CMakePresets.json` (or the equivalent of your build system) with these configurations. Use a hidden base preset for the common settings: the generator, `binaryDir` as `${sourceDir}/build/${presetName}`, and the compilation database.

   | Preset | Build type | Sanitizers | Use |
   |---|---|---|---|
   | `dev` | Debug | `address;undefined` | Daily work |
   | `debug` | Debug | none | The debugger, when the sanitizers make it slow |
   | `release` | RelWithDebInfo | none | Measurements |
   | `tsan` | Debug | `thread` | Concurrent code (phase 6). Only on Linux and macOS: use a `condition` on `${hostSystemName}`. |

   Add build presets and test presets for each one. In the test presets, show the output of failed tests (`"output": {"outputOnFailure": true}`), and fail if no test exists (`"execution": {"noTestsAction": "error"}`).
   - Check: delete all build directories. `cmake --preset dev`, `cmake --build --preset dev`, and `ctest --preset dev` build and test all exercises in the root build file. Change the clangd setting to the `dev` build directory.
2. **Local settings** (for example a compiler path or a local library prefix) go to `CMakeUserPresets.json`, which git ignores. Explain in your notebook why they do not go to `CMakePresets.json`.
3. **README.** Write `labs/phase-0-tools/README.md` with the commands to configure, build, test, format, and lint.
4. **Check the requirements** in the table at the start of the exercises. Ask the mentor for a review of your setup.
5. From phase 1, start each new project with a copy of this setup: the `cmake/` directory, the presets, `.clang-format`, `.clang-tidy`, and the root build file. When you improve the setup later (for example in phase 8), write the change in your notebook.

### Exercise 0.10: Evaluate libraries

1. Find three JSON libraries for C++ (for example nlohmann/json, Boost.JSON, and glaze or simdjson).
2. Compare them with the table in topic 0.11, and add two rows: the compile time of a small example, and the ease of use for your project.
3. Select one for phase 7. Write three sentences about why.

## Done criteria

- [ ] My compiler compiles and runs the check program. My editor shows errors and goes to definitions. My debugger stops at a breakpoint.
- [ ] I can explain the jobs of the preprocessor, the compiler, and the linker, and the difference between a declaration and a definition.
- [ ] I can explain a linker error and find its cause.
- [ ] I can explain the difference between the debug and the release build types, and why UB can give different results in each.
- [ ] I can explain the build sequence and header dependency discovery for my selected tools. I can predict the required steps after a source or header change. My clean parallel build and unchanged-build checks pass.
- [ ] I wrote the project setup myself: the build file, the warning set, the sanitizer option, the presets, and the format and lint files. It meets all requirements in the table of the exercises.
- [ ] My code has no warnings with the warning set of the course, is formatted with clang-format, and has no clang-tidy findings (or a written reason for each one).
- [ ] I can find an out-of-range access and a use after free with AddressSanitizer.
- [ ] I can add a library by hand, pinned to a version and checked with a hash, and record it in the dependency list.

## Next

[Phase 1: C++ basics](phase-1-cpp-basics.md)
