# Build Systems

**Phase:** 0, then all phases
**Related:** [phase 0](../phases/phase-0-tools.md), [software setup](../software-setup.md), [external libraries](external-libraries.md), [toolchain selection](../mentor/toolchain-selection.md)

## Summary

A C++ compiler compiles one translation unit at a time. A build system knows all the files of a project, the dependencies between them, and the options for each target. It runs only the steps that are necessary after a change. C++ has no single standard build system. CMake is the most common, so the course documents use it. This topic compares the alternatives and translates the main commands.

## Explanation

### Two kinds of tools

| Kind | What it does | Examples |
|---|---|---|
| Build tool | Runs the compile and link commands in the correct order, in parallel, and only when an input changed | Ninja, Make, MSBuild |
| Build system generator, or meta build system | Reads a high-level description of the project (targets, sources, options) and writes the files for a build tool | CMake, Meson, Premake |
| Integrated build system | Does both, often with a package manager | xmake, Bazel, Buck2 |

CMake with Ninja is the default of the course. Ninja is fast, and it works the same way on all operating systems. On Windows, CMake can also generate Visual Studio solutions, but the Visual Studio generator does not write `compile_commands.json`.

### Concepts that all build systems share

| Concept | Meaning |
|---|---|
| Target | A thing to build: a static library, a shared library, an executable, a test executable |
| Sources and headers | The files of a target |
| Usage requirements | What a target gives to the targets that use it: include directories, compile definitions, link libraries. In CMake: `PUBLIC`, `PRIVATE`, `INTERFACE`. |
| Build type or configuration | Debug, Release, RelWithDebInfo: the optimization level and the debug information |
| Out-of-source build | The build output goes to a separate directory (`build/`), never into the source tree |
| Compilation database | `compile_commands.json`: the exact compile command for each file. clangd and clang-tidy read it. |
| Test registration | The build system knows the test executables and runs them (`ctest`, `meson test`) |

### Comparison

| | CMake | Meson | xmake | Bazel | Make (hand-written) |
|---|---|---|---|---|---|
| Language of the build file | CMake language | Meson language (Python-like, not Turing-complete) | Lua | Starlark (Python-like) | Make rules |
| Use in industry | Very high | Medium (GNOME, systemd, many Linux projects) | Small, growing | High in large companies | High in old and small projects |
| Learning curve | Medium; many old tutorials show outdated forms | Low | Low | High | Low for small projects, high for large ones |
| IDE support | Best (all IDEs) | Good (VS Code, CLion with a plugin, Qt Creator) | Good (VS Code plugin) | Medium | Low |
| Package management | No built-in manager; `FetchContent`, vcpkg, Conan | WrapDB and wrap files | Built-in (`add_requires`) | Bazel Central Registry (`MODULE.bazel`) | None |
| `compile_commands.json` | `CMAKE_EXPORT_COMPILE_COMMANDS` | Always written | `xmake project -k compile_commands` | An extra tool (for example hedron compile commands extractor) | Bear (`bear -- make`) |
| Windows with MSVC | Yes | Yes | Yes | Yes | Only with extra work |

**Recommendation:** use CMake if you want the most common tool, or if a future job uses C++. Use Meson if you want a cleaner build language and use mainly Linux. Use xmake if you want a simple tool with a built-in package manager. Use Bazel only if you already know it or your company uses it. Use Make only to learn what a build system does (phase 0, exercise 0.2).

### Command translation

| Task | CMake (presets) | Meson | xmake | Bazel |
|---|---|---|---|---|
| Configure a debug build | `cmake --preset dev` | `meson setup build/dev --buildtype=debug` | `xmake f -m debug` | (not needed) |
| Build | `cmake --build --preset dev` | `meson compile -C build/dev` | `xmake` | `bazel build //...` |
| Run the tests | `ctest --preset dev` | `meson test -C build/dev` | `xmake test` | `bazel test //...` |
| Release build | `cmake --preset release` then build | `meson setup build/release --buildtype=release` | `xmake f -m release` then `xmake` | `bazel build -c opt //...` |
| Select the compiler | `-DCMAKE_CXX_COMPILER=clang++` (first configure only) | `CXX=clang++ meson setup ...` | `xmake f --toolchain=clang` | `CC=clang bazel build ...` |
| Sanitizers | A cache variable and target options (phase 0, exercise 0.7) | `-Db_sanitize=address,undefined` | `set_policy("build.sanitizer.address", true)` | `--copt=-fsanitize=address --linkopt=-fsanitize=address` |
| Clean generated outputs | `cmake --build --preset dev --target clean` | `meson compile -C build/dev --clean` | `xmake clean` | `bazel clean` |

### Build checks

Use these checks with your selected tools. Predict the required compilation and linking before each check. Then inspect the build output and explain the result. Library updates and configuration steps can add valid commands. Do not compare exact command counts between build systems.

| Check | What to verify |
|---|---|
| First build | The build succeeds without old generated files. Identify where the tools store outputs and dependency records. |
| Unchanged build | No compilation or linking is needed. The tool can still check or update its configuration. |
| One source change | Compile the changed translation unit and update dependent outputs. Unaffected translation units do not need compilation. |
| Shared-header change | Compile the translation units that include the header, directly or indirectly. Update dependent outputs. |
| Clean and rebuild | Explain what the clean operation removes and preserves. Rebuild and run the program. |
| Parallel build from a new build directory | Commands run only after their required inputs and output directories exist. The program builds and runs without files from an earlier build. |

Use a small implementation change for the source check. Use a valid header change for the header check. Do not change compiler options or unrelated files during these checks.

With CMake, use `cmake --build build --verbose` to inspect commands. Use `cmake --build build --parallel 2` to allow two concurrent build jobs. These commands apply to both the Makefile and Ninja generators. Select the generator when configuring a new build directory. Do not edit the generated Makefiles or `build.ninja`. For a generator with multiple configurations, also select the configuration with `--config Debug`.

With Meson, use `meson compile -C build -v` to inspect commands and `meson compile -C build -j 2` for two concurrent jobs. For other tools, use their documented verbose and parallel-build options. If the tool manages its own output directories or cache, use its documented way to check a build without old outputs.

Header dependency discovery depends on the compiler and build tools. CMake and Meson configure this handling for supported toolchains. Verify it with the header-change check; do not add handwritten dependency files to these projects. If you study a handwritten Makefile, explain how compiler-generated dependency files are created on the first compilation and read on later builds. Explain how stale records are handled after a header is removed or renamed. In every toolchain, a source file that still includes a missing header is an error.

A clean operation can preserve configuration files, dependency records, or cached results. It is not always the same as removing a build directory. Before any deletion, explain the exact scope and check that it contains only generated files. Prefer the selected tool's existing clean operation. Add a custom operation only if the project needs it.

### The same project in each build system

The example project has a library `greeting`, an executable `hello`, and a test executable `greeting_tests` that uses doctest from `third_party/`. The examples show only the structure. The warning set and the sanitizers are not in them: in phase 0, you add them yourself.

**CMake** (`CMakeLists.txt`):

```cmake
cmake_minimum_required(VERSION 3.28)
project(hello LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

add_library(greeting src/greeting.cpp)
target_include_directories(greeting PUBLIC include)

add_executable(hello app/main.cpp)
target_link_libraries(hello PRIVATE greeting)

add_library(doctest INTERFACE)
add_library(doctest::doctest ALIAS doctest)
target_include_directories(doctest SYSTEM INTERFACE third_party/doctest)

enable_testing()
add_executable(greeting_tests tests/greeting_tests.cpp)
target_link_libraries(greeting_tests PRIVATE greeting doctest::doctest)
add_test(NAME greeting_tests COMMAND greeting_tests)
```

**Meson** (`meson.build`, Meson 1.4 or newer):

```meson
project('hello', 'cpp',
  version: '0.1.0',
  default_options: ['cpp_std=c++23', 'warning_level=3', 'werror=true'])

inc = include_directories('include')
core = static_library('greeting', 'src/greeting.cpp', include_directories: inc)
core_dep = declare_dependency(link_with: core, include_directories: inc)

executable('hello', 'app/main.cpp', dependencies: core_dep)

doctest_dep = declare_dependency(
  include_directories: include_directories('third_party/doctest', is_system: true))
tests = executable('greeting_tests', 'tests/greeting_tests.cpp',
  dependencies: [core_dep, doctest_dep])
test('greeting_tests', tests)
```

With MSVC, set `cpp_std=c++latest` if your Meson version does not accept `c++23` for MSVC. `warning_level=3` gives `-Wall -Wextra -Wpedantic` or `/W4`. Add the other warnings of the course with `add_project_arguments`.

**xmake** (`xmake.lua`):

```lua
set_languages("c++23")
set_warnings("allextra", "error")
add_rules("mode.debug", "mode.release")

target("greeting")
    set_kind("static")
    add_files("src/*.cpp")
    add_includedirs("include", {public = true})

target("hello")
    set_kind("binary")
    add_files("app/main.cpp")
    add_deps("greeting")

target("greeting_tests")
    set_kind("binary")
    add_files("tests/*.cpp")
    add_deps("greeting")
    add_sysincludedirs("third_party/doctest")
    add_tests("default")
```

**Bazel** (`BUILD.bazel`, with a `MODULE.bazel` file that declares the module and `rules_cc`):

```python
cc_library(
    name = "greeting",
    srcs = ["src/greeting.cpp"],
    hdrs = glob(["include/**/*.hpp"]),
    includes = ["include"],
)

cc_binary(
    name = "hello",
    srcs = ["app/main.cpp"],
    deps = [":greeting"],
)

cc_test(
    name = "greeting_tests",
    srcs = ["tests/greeting_tests.cpp"],
    deps = [":greeting", "//third_party/doctest"],
)
```

Put the standard and the warnings in `.bazelrc`, for example `build --cxxopt=-std=c++23` on Linux and macOS, and `build --cxxopt=/std:c++latest` on Windows.

**Make** (only for learning; GCC or Clang):

```make
CXX      ?= g++
CXXFLAGS := -std=c++23 -Wall -Wextra -Wpedantic -Werror -Iinclude -MMD -MP
OBJS     := build/greeting.o build/main.o

build/hello: $(OBJS)
	$(CXX) $(CXXFLAGS) $^ -o $@

build/%.o: src/%.cpp | build
	$(CXX) $(CXXFLAGS) -c $< -o $@

build/%.o: app/%.cpp | build
	$(CXX) $(CXXFLAGS) -c $< -o $@

build:
	mkdir -p build

-include $(OBJS:.o=.d)
```

`-MMD -MP` writes a `.d` file for each object file with the headers that it includes. Without them, Make does not rebuild a file when a header changes. This is one of the problems that a real build system solves for you.

### Modern CMake rules

Many CMake tutorials on the internet show old forms. Use these rules:

- Use targets and their usage requirements: `target_include_directories`, `target_compile_options`, `target_link_libraries`. Do not use the global commands `include_directories`, `add_definitions`, and `link_libraries`.
- Do not change `CMAKE_CXX_FLAGS` in a `CMakeLists.txt` file. Put options on targets, or in presets for the local machine.
- Use `PRIVATE` for what only the target needs, `PUBLIC` for what the users of the target also need, `INTERFACE` for what only the users need.
- Use `CMakePresets.json` for the configurations that the project shares. Use `CMakeUserPresets.json` (ignored by git) for your local settings.
- Do not use `file(GLOB ...)` for source files in large projects: CMake does not see new files until you configure again. List the files.
- Link dependencies through their namespaced targets (`doctest::doctest`, `SQLite::SQLite3`). A name with `::` must be a target, so a typing mistake gives an error, not a silent link flag.

## Example

A change to one header rebuilds only the files that include it:

```text
$ cmake --build --preset dev
[1/3] Building CXX object CMakeFiles/greeting.dir/src/greeting.cpp.o
[2/3] Linking CXX static library libgreeting.a
[3/3] Linking CXX executable hello
```

## Common mistakes

| Mistake | Result | Fix |
|---|---|---|
| Build in the source directory (`cmake .`) | Generated files mix with the source files and go into git | Always use a separate build directory. Presets do this. |
| Change the compiler in an existing build directory | CMake keeps the old compiler, or gives strange errors | Delete the build directory, and configure again |
| `include_directories` and `CMAKE_CXX_FLAGS` in place of target commands | Options go to all targets, also to third-party code | Use `target_*` commands |
| A header is not in any target | The IDE does not show it; clangd guesses the flags | List headers in the target, or in a `FILE_SET HEADERS` |
| Visual Studio generator with clangd | No `compile_commands.json`, so clangd shows wrong errors | Use the Ninja generator |
| A test executable that is not registered with `add_test` | `ctest` does not run it; a failure is not seen | Register every test executable. The test presets of the course fail if no test exists. |

## Sources

- CMake documentation: "CMake Tutorial", "cmake-buildsystem(7)", "cmake-presets(7)" (cmake.org)
- [CMake command-line reference](https://cmake.org/cmake/help/v3.28/manual/cmake.1.html): build, verbose output, parallel jobs, and clean targets
- [Ninja manual](https://ninja-build.org/manual.html): generated build files, header dependencies, and output directory creation
- [Meson commands](https://mesonbuild.com/Commands.html#compile): compile, verbose output, parallel jobs, and clean
- Henry Schreiner and others, "An Introduction to Modern CMake" (cliutils.gitlab.io/modern-cmake)
- Meson documentation, "Tutorial" and "Reference manual" (mesonbuild.com)
- xmake documentation (xmake.io)
- Bazel documentation, "C++ tutorial" (bazel.build)
