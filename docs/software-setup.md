# Software Setup

This document tells you which tools to install, how to select between the alternatives, and how to do a check of each tool. All tools work natively on Windows, macOS, and Linux. You can use a different tool from the defaults. The [toolchain selection document](mentor/toolchain-selection.md) explains the choices, and your mentor translates the commands for you.

The course code is portable C++23. It does not use any API that only one operating system has.

## 1. Select your toolchain

You need five things:

| Item | What it does | Default |
|---|---|---|
| A compiler and its standard library | Translates C++ to machine code | The native compiler of your operating system (see the table below) |
| A build system | Knows which files to compile and link, with which options | CMake 3.28+ with Ninja |
| An editor or IDE with a language server | Completion, errors while you type, go to definition, refactoring | VS Code with clangd |
| A debugger | Stops the program and shows the variables | The debugger of your toolchain |
| Format and lint tools | Format the code, and find common mistakes | clang-format and clang-tidy |

| Operating system | Default compiler | Other options |
|---|---|---|
| Windows | MSVC (Visual Studio 2022 17.10 or newer, or Visual Studio 2026) | clang-cl (Clang with an MSVC-compatible interface), MinGW-w64 GCC through MSYS2, GCC or Clang in WSL2 |
| macOS | Apple Clang from the Xcode command-line tools | LLVM Clang from Homebrew, GCC from Homebrew |
| Linux | GCC 14 or newer | Clang 18 or newer with libstdc++ 14, or Clang 20 or newer with libc++ |

If you do not know what to select, use the defaults. You can change the compiler and the editor later at a low cost. A change of the build system costs more after phase 4.

## 2. Install the tools

### Windows

1. Install **Visual Studio Community** (free for individuals, students, and open-source work; check the current license terms), or the **Build Tools for Visual Studio** if you do not want the IDE. In the installer, select the workload **"Desktop development with C++"**. Keep these components selected: "MSVC ... build tools", "C++ CMake tools for Windows", "C++ AddressSanitizer", and a Windows SDK. Optional: "C++ Clang tools for Windows" (for clang-cl).
2. Install the other tools with `winget` in PowerShell:

   ```powershell
   winget install --id Git.Git
   winget install --id Kitware.CMake
   winget install --id Ninja-build.Ninja
   winget install --id LLVM.LLVM
   ```

   The LLVM package gives `clangd`, `clang-format`, and `clang-tidy`.
3. Open the **"Developer PowerShell for VS"** (or "x64 Native Tools Command Prompt") from the Start menu when you build from a terminal. It sets the `PATH` and the environment variables that MSVC needs. Make sure that it uses the x64 (or arm64) tools, not x86.

**MinGW-w64 alternative:** install MSYS2 (msys2.org). In the "MSYS2 UCRT64" shell, run `pacman -S mingw-w64-ucrt-x86_64-gcc mingw-w64-ucrt-x86_64-cmake mingw-w64-ucrt-x86_64-ninja mingw-w64-ucrt-x86_64-gdb mingw-w64-ucrt-x86_64-clang-tools-extra`. AddressSanitizer is not available with MinGW-w64 GCC.

**WSL2 alternative:** install a Linux distribution with `wsl --install`, then follow the Linux steps. WSL2 gives you all sanitizers, including ThreadSanitizer (phase 6).

### macOS

```sh
xcode-select --install
brew install cmake ninja llvm git
```

- `xcode-select` installs Apple Clang, LLDB, and the system headers.
- The Homebrew `llvm` package gives `clangd`, `clang-format`, `clang-tidy`, and a newer Clang. Homebrew does not put it on the `PATH` by default: `brew info llvm` tells you the path. Add only the tools that you need to the `PATH`, or call them with the full path.
- If the check program in section 4 fails with Apple Clang, use the Homebrew Clang (version 20 or newer) as the compiler: `cmake --preset dev -DCMAKE_CXX_COMPILER="$(brew --prefix llvm)/bin/clang++"`.

### Linux

Debian or Ubuntu (24.04 or newer):

```sh
sudo apt install build-essential g++-14 cmake ninja-build gdb git clangd clang-format clang-tidy
```

Fedora:

```sh
sudo dnf install gcc-c++ cmake ninja-build gdb git clang-tools-extra
```

Arch Linux:

```sh
sudo pacman -S base-devel cmake ninja gdb git clang
```

If your distribution has a GCC older than 14 or a CMake older than 3.28, install a newer version: from the distribution's newer package (for example `g++-14`), from the Kitware APT repository (apt.kitware.com) for CMake, or with `pipx install cmake`. Do not replace the system compiler; select the compiler for the course with `CMAKE_CXX_COMPILER` or the `CXX` environment variable.

### Other build systems (optional)

| Build system | Install | Notes |
|---|---|---|
| Meson | `pipx install meson` (and Ninja) | See [topics/build-systems.md](topics/build-systems.md) |
| xmake | xmake.io | Has its own package manager |
| Bazel | Bazelisk (github.com/bazelbuild/bazelisk) | For large projects. More setup work. |
| Make | Included in most Linux and macOS systems | Only for the learning exercises in phases 0 and 1 |

### Package managers (optional)

| Tool | Install | When the course uses it |
|---|---|---|
| vcpkg | Clone github.com/microsoft/vcpkg, run its bootstrap script. Visual Studio 2022 and newer also includes a copy. | Optional, from phase 4. See [topics/external-libraries.md](topics/external-libraries.md). |
| Conan 2 | `pipx install conan` | Optional, from phase 4 |

The course teaches manual library management first. You do not need a package manager to complete the course.

## 3. Set up the editor

Use `labs/` as the default editor workspace for course code. Open this directory with the folder or workspace command of your editor. Keep editor settings under `labs/`. Each phase directory is a separate build project, for example `labs/0-tools/`. The editor workspace and the build project root do not need to be the same directory.

State the working directory before each terminal command. With `labs/` open, an integrated terminal can start in `labs/`, while an exercise can require `labs/0-tools/`. Check the current directory before you run the command. If you use another workspace layout, adapt the paths explicitly.

The standalone toolchain check in section 4 uses a separate scratch directory. Open that directory for the check. Use `labs/` when you start the course labs.

Select the compiler and the C++23 language mode in your editor or project settings. The editor must use the same include paths and preprocessor definitions as the build.

If the editor has its own C++ analysis, use its project or toolchain settings. For example, Visual Studio can read its MSBuild project, and CLion can read its CMake project. A separate clangd configuration is necessary only when you use clangd.

### Editors that use clangd

#### Check the language server

The compiler and clangd are separate programs. A successful build does not check the editor configuration. clangd uses the Clang parser. It needs the language standard, the include paths, and the preprocessor definitions of the build. Selecting a compiler in a separate build extension does not configure clangd by itself.

Open the language server log in your editor. Check the executable path and the version in the startup log. The editor plugin can use its own clangd. Thus `clangd --version` in the terminal can show a different version. Select the intended executable in the language server settings of your editor. Restart the language server after you change this setting.

For a remote environment such as WSL, run clangd in the same environment as the compiler. Use compiler paths from that environment.

Use workspace settings for the course. Do not change the settings of other projects to fix a course project.

#### Configure the standalone check

The check program in section 4 has no build system yet. Configure clangd before you check that program in the editor.

For GCC 14 on Linux or WSL, create a `.clangd` file beside `check.cpp`:

```yaml
CompileFlags:
  Compiler: /usr/bin/g++-14
  Add: [-std=c++23]
```

This is one example. Select the settings for your toolchain:

| Build compiler | Compiler setting for clangd | Standard option for clangd |
|---|---|---|
| GCC | The absolute path to the selected `g++` executable | `-std=c++23` |
| LLVM Clang or Apple Clang | The absolute path to the selected `clang++` executable | `-std=c++23` |
| MSVC | The `clang-cl` driver spelling, so clangd reads MSVC-style options | `/std:c++latest` |

On Linux and macOS, use `command -v` with the selected compiler name to check its path. For MSVC, start the editor from a Developer PowerShell so that clangd inherits the MSVC include paths. If the build selects a standard library with an option, give clangd that option too.

For GCC or Clang, let clangd read the system include paths and the target from the selected compiler. Add `--query-driver` with the exact trusted compiler path to the clangd startup arguments in your editor. For the GCC example, use `--query-driver=/usr/bin/g++-14`.

The compiler in `.clangd` and the path allowed by `--query-driver` must match. clangd runs this compiler to read its configuration. Allow only a compiler that you trust. This query does not make clangd use the GCC parser.

Restart clangd. In the language server log, check that the compile command uses the selected standard option and the intended compiler. Check that the system include paths are from the intended standard library. Do not add paths from a different compiler installation to make an error disappear.

An alternative for a small folder is `compile_flags.txt`, with one compiler option on each line. It does not select the compiler executable. See [clangd project setup](https://clangd.llvm.org/installation.html#project-setup), [configuration](https://clangd.llvm.org/config#compileflags), and [system headers](https://clangd.llvm.org/guides/system-headers).

#### Configure a project with a build system

From exercise 0.3, use the build system to generate `compile_commands.json`. With CMake and the Ninja or Unix Makefiles generator, enable `CMAKE_EXPORT_COMPILE_COMMANDS`. The database records the compiler and the options for each source file. Select the intended compiler when you first configure the build directory.

Select the database for each build project. For example, if `labs/0-tools/build/dev/compile_commands.json` exists, create `labs/0-tools/.clangd` with:

```yaml
CompileFlags:
  CompilationDatabase: build/dev
```

This path is relative to the directory that contains `.clangd`. Use `build` instead of `build/dev` before you add presets, if that is your build directory. Keep project-specific database paths in the project directory. A shared `.clangd` under `labs/` applies to all its subdirectories. See [clangd configuration](https://clangd.llvm.org/config#compilationdatabase).

When the database supplies the compiler and the standard option, remove the scratch overrides for those settings. Keep a version-specific clangd workaround only while the matching problem exists. Do not copy the scratch configuration into each lab. Do not edit the generated database by hand.

### VS Code (default)

For course code, open `labs/` with **File > Open Folder**. If the `code` command is available, run `code labs` from the repository root. Workspace settings are in `labs/.vscode/settings.json`. In those settings, `${workspaceFolder}` means `labs/`. VS Code does not load a nested `.vscode/settings.json` just because you open a file from that directory. See [VS Code workspace settings](https://code.visualstudio.com/docs/configure/settings).

Install VS Code (code.visualstudio.com) and these extensions:

- **clangd** (llvm-vs-code-extensions.vscode-clangd): the language server. It reads `compile_commands.json` from the build directory.
- **CMake Tools** (ms-vscode.cmake-tools): configure, build, test, and select presets from the editor.
- **A debugger extension:**
  - **C/C++** (ms-vscode.cpptools) for the Visual Studio debugger (MSVC) and for gdb. If you use clangd, disable the IntelliSense of this extension: set `"C_Cpp.intelliSenseEngine": "disabled"`.
  - **CodeLLDB** (vadimcn.vscode-lldb) for LLDB on macOS and Linux.

In VS Code, open **View > Output** and select **clangd** to read the language server log. Use `clangd.path` in the workspace settings to select a specific installed executable when necessary.

For WSL, open the folder in a WSL window. Install the extensions in that WSL distribution.

For the standalone GCC example above, add these workspace settings in the scratch directory's `.vscode/settings.json`:

```json
{
  "clangd.arguments": ["--query-driver=/usr/bin/g++-14"],
  "C_Cpp.intelliSenseEngine": "disabled"
}
```

Keep any other settings that the workspace needs. Use your selected compiler path in place of the example path. With a different editor, put the startup argument in that editor's language server settings.

For course code with clangd, these settings go in `labs/.vscode/settings.json`. Configure the database location in each build project's `.clangd`, as described above:

```json
{
  "editor.formatOnSave": true,
  "clangd.arguments": [
    "--clang-tidy",
    "--header-insertion=never"
  ],
  "C_Cpp.intelliSenseEngine": "disabled"
}
```

The selected database directory must contain `compile_commands.json`. Change the path for a different preset or build system. For GCC or Clang, also add `--query-driver` with the exact compiler path from the database when clangd needs it to find the system headers. Restart clangd and check the command in its Output log.

#### If you use the CMake Tools extension

Set `cmake.sourceDirectory` in `labs/.vscode/settings.json` to the selected build project. For phase 0, use:

```json
"cmake.sourceDirectory": "${workspaceFolder}/0-tools"
```

This is a settings entry, not a complete JSON file. Add it inside the existing settings object. It tells CMake Tools where the root `CMakeLists.txt` is. Update it when you select another phase or the main project. It does not select clangd's compilation database. Terminal CMake commands select the source directory with `-S` instead.

After exercise 0.9 creates the presets, set `cmake.useCMakePresets` to `"always"` if you use CMake Tools. These settings apply only to that extension. Other editors and build tools use their own project selection.

**Windows note:** with CMake and clangd, use the Ninja generator to export `compile_commands.json`. The Visual Studio generator does not export it. Visual Studio can use its own project analysis instead.

### Other editors and IDEs

| Editor | Setup |
|---|---|
| CLion | Opens `CMakePresets.json` directly. Has a debugger, a profiler integration, and clang-tidy. Free for non-commercial use; check the current license terms. Supports Meson and Bazel with plugins. |
| Visual Studio (Windows) | "Open a local folder" with a `CMakePresets.json` file, or use an MSBuild solution. Has the best MSVC debugger and a profiler. |
| Qt Creator | Opens CMake projects. Good choice if you select Qt for the GUI in phase 6. |
| Neovim, Emacs, Helix, Zed, Sublime Text | Use clangd as the language server. Use gdb, LLDB, or a Debug Adapter Protocol plugin (for example `nvim-dap`) to debug. |

For a project with a build system, give the editor a `compile_commands.json` file or a project format that it understands. With CMake and Ninja, set `CMAKE_EXPORT_COMPILE_COMMANDS` to `ON`. Before exercise 0.3, use the standalone settings of your editor. If the editor uses clangd, follow the standalone configuration above.

## 4. Do a check of the tools

Run these commands in a new terminal (on Windows, in the Developer PowerShell). Each command must print a version.

```sh
git --version
cmake --version
ninja --version
clangd --version
clang-format --version
clang-tidy --version
```

Then the compiler:

| Compiler | Command | Minimum |
|---|---|---|
| GCC | `g++ --version` | 14 |
| Clang | `clang++ --version` | 18 with libstdc++ 14; 20 with libc++ |
| MSVC | `cl` (without arguments) | 19.40 |
| Apple Clang | `clang++ --version` | The check program decides |

### The check program

Save this program as `check.cpp` in a scratch directory outside the course repository. It uses the C++23 features that the course uses.

```cpp
// Toolchain check for the C++ course. It uses the C++23 subset of the course.
#include <algorithm>
#include <bit>
#include <cstdint>
#include <expected>
#include <format>
#include <optional>
#include <print>
#include <ranges>
#include <stop_token>
#include <string>
#include <string_view>
#include <thread>
#include <utility>
#include <vector>

enum class Color : std::uint8_t { white, black };

struct Counter {
    int value = 0;
    // Deducing this (C++23).
    template <typename Self>
    auto&& get(this Self&& self) { return std::forward<Self>(self).value; }
};

std::expected<int, std::string> parse_digit(char c) {
    if (c < '0' || c > '9') {
        return std::unexpected(std::format("not a digit: '{}'", c));
    }
    return c - '0';
}

int main() {
    std::vector<int> squares = std::views::iota(1, 6)
                             | std::views::transform([](int n) { return n * n; })
                             | std::ranges::to<std::vector>();

    auto doubled = parse_digit('7').transform([](int d) { return d * 2; });
    auto bad = parse_digit('x');

    std::optional<int> maybe = 4;
    auto next = maybe.and_then([](int n) { return std::optional{n + 1}; });

    int result = 0;
    {
        std::jthread worker([&result](std::stop_token token) {
            // stop_possible() is true: the jthread owns a stop source.
            result = token.stop_possible() ? std::popcount(0b1011u) : -1;
        });
    }

    Counter counter{.value = 3};
    std::string_view text = "C++23 toolchain check";

    // Range formatting ("{}" for a vector) needs GCC 15. The course does not use it.
    std::println("squares: {} values, the last is {}", squares.size(), squares.back());
    std::println("doubled: {}, error: {}", doubled.value(), bad.error());
    std::println("next: {}, popcount: {}, counter: {}", next.value(), result, counter.get());
    std::println("color: {}, contains: {}", std::to_underlying(Color::black), text.contains("check"));
    std::println("OK");
}
```

Compile and run it:

| Compiler | Command |
|---|---|
| GCC | `g++ -std=c++23 -Wall -Wextra -Werror check.cpp -o check && ./check` |
| Clang | `clang++ -std=c++23 -Wall -Wextra -Werror check.cpp -o check && ./check` |
| MSVC (Developer PowerShell) | `cl /nologo /std:c++latest /W4 /permissive- /WX /EHsc /utf-8 check.cpp` then `.\check.exe` |

The last line of the output must be `OK`.

- MSVC: use `/std:c++latest`. Some versions also accept `/std:c++23preview`. CMake selects the correct flag for `CMAKE_CXX_STANDARD 23`.
- Clang on Linux uses libstdc++ by default. If the check fails, install a newer libstdc++ (the GCC 14 package), or use libc++ 20 or newer with `-stdlib=libc++`.
- If `<print>` or `std::jthread` is missing with Clang and libc++, the libc++ version is too old. libc++ 18 and 19 hide `std::jthread` and `<stop_token>` behind the flag `-fexperimental-library`. Use Clang and libc++ 20 or newer.

### The editor diagnostics

1. Open `check.cpp` in the configured editor.
2. Check that the editor uses the selected compiler configuration. With clangd, check the language server log for the executable, the compile command, and the standard library paths.
3. Check the diagnostics. The editor must accept the same course features as the compiler. Investigate each error. A successful run does not prove that the editor configuration is correct.

If compilation succeeds but the editor reports missing C++ features, first check the standard option and the header paths. For example, explicit object parameters need C++23, and `std::jthread` needs C++20 or newer.

If the settings are correct, check the clangd version and its compatibility with the standard library. clangd can have a parser defect even when GCC accepts the program. Two known cases are:

- With libstdc++, clangd 18 can report that `std::expected` is missing. Use clangd 19 or newer for this case. See the [Clang 19 release notes](https://releases.llvm.org/19.1.0/tools/clang/docs/ReleaseNotes.html#c-20-feature-support).
- With libstdc++ 14, clangd can report that `forward_like` with a deduced return type is used before its definition in a ranges expression. For this exact diagnostic, add `-fno-builtin-std-forward_like` to the `Add` list in the local `.clangd` file. This is a clangd workaround. Keep it out of the GCC build options. See [clangd issue 2575](https://github.com/clangd/clangd/issues/2575).

Use these workarounds only after you reproduce the matching problem. Keep real warnings visible. Do not change working course code to an older C++ form to satisfy an editor with the wrong configuration.

### The debugger

1. Compile the check program with debug information: add `-g` (GCC, Clang) or `/Zi` (MSVC) to the command above.
2. Open the scratch directory in your editor, and set a breakpoint on the first line of `main`.
3. Start the debugger on the executable (in VS Code: a launch configuration of the C/C++ or CodeLLDB extension; your mentor or the extension documentation shows how).
4. The program must stop on the breakpoint, and you must see the local variables.

You check the build system in phase 0, exercise 0.3, when you make your first project.

## 5. C++23 support

The course uses only the features that all supported compilers have. The minimum versions in this table come from the compiler documentation and the compiler support page of cppreference.com (en.cppreference.com/w/cpp/compiler_support). Check that page for your exact version.

| Feature | Standard | GCC | Clang with libc++ | MSVC | In the course subset |
|---|---|---|---|---|---|
| Concepts, ranges, `std::span`, `<=>`, designated initializers | C++20 | 10+ | 16+ | 19.29+ | Yes |
| `std::format` | C++20 | 13+ | 17+ | 19.29+ | Yes |
| `std::jthread`, `std::stop_token` | C++20 | 10+ | 20+ (18–19 only with `-fexperimental-library`) | 19.28+ | Yes |
| Floating-point `std::from_chars` | C++17 | 11+ | 20+ | 19.24+ | Yes |
| `<bit>`: `std::popcount`, `std::countr_zero` | C++20 | 10+ | 9+ | 19.25+ | Yes |
| `std::expected` | C++23 | 12+ | 16+ | 19.33+ | Yes |
| Monadic `std::optional` (`and_then`, `transform`, `or_else`) | C++23 | 12+ | 14+ | 19.32+ | Yes |
| `std::print`, `std::println` | C++23 | 14+ | 17+ | 19.37+ | Yes |
| `std::ranges::to` | C++23 | 14+ | 17+ | 19.34+ | Yes |
| Deducing `this` | C++23 | 14+ | 18+ | 19.32+ | Yes |
| `std::to_underlying`, `std::unreachable`, `string::contains` | C++23 | 12+ | 15+ | 19.32+ | Yes |
| Formatting of ranges (`std::println("{}", vector)`) | C++23 | 15+ | 16+ | 19.37+ | No. Format the elements yourself. |
| `std::views::zip`, `enumerate`, `chunk`, `slide` | C++23 | 13+ | Partial; check | 19.33+ | No. The course shows them as optional. |
| `std::move_only_function` | C++23 | 12+ | Check | 19.32+ | No. Use `std::function` or a hand-written wrapper. |
| `std::generator` | C++23 | 14+ | Check | Check | No. Optional in phase 6. |
| `std::flat_map`, `std::mdspan` | C++23 | Check | Check | Check | No |
| `std::stacktrace` | C++23 | 12+ (link `stdc++exp`) | Check | 19.34+ | No. Optional in phase 4. |
| `import std;` (standard library modules) | C++23 | 15+ | 18+ (with CMake 3.30+) | 19.35+ | No. Optional in phase 4. |
| Parallel algorithms (execution policies) | C++17 | 9+ (needs Intel TBB) | Check | 19.14+ | No. Optional in phase 6. |

"Check" means that support is new, partial, or different in each version. Read the compiler support page before you use the feature.

The column "Clang with libc++" gives the libc++ version. With Clang and libstdc++ (the default on Linux), the library features follow the GCC column, and the language features (deducing `this`) need Clang 18.

## 6. Warnings

The course treats warnings as errors. Use this warning set in every course project. In phase 0, exercise 0.5, you write the build code that applies it.

| Purpose | GCC and Clang | MSVC |
|---|---|---|
| The main warning sets | `-Wall -Wextra -Wpedantic` | `/W4 /permissive-` |
| Variables that hide other variables | `-Wshadow` | Included in `/W4` (C4456–C4459) |
| Conversions that can lose data or change the sign | `-Wconversion -Wsign-conversion` | Included in `/W4` (C4244, C4267) |
| A class with virtual functions and a non-virtual destructor | `-Wnon-virtual-dtor` | `/w14265` |
| A derived function that hides a virtual function | `-Woverloaded-virtual` | `/w14263` |
| C-style casts | `-Wold-style-cast` | (none; use clang-tidy) |
| A `switch` that does not handle an enumerator | `-Wswitch` (in `-Wall`) | `/w14062` |
| Missing `[[fallthrough]]` | `-Wimplicit-fallthrough` | `/w15262` |
| Treat warnings as errors | `-Werror` | `/WX` |

GCC only: `-Wduplicated-cond -Wduplicated-branches -Wlogical-op`. MSVC also needs `/utf-8` (source and execution character set) and `/Zc:__cplusplus` (a correct `__cplusplus` value).

MSVC marks some portable standard C functions (for example `std::fopen` and `std::getenv`) as deprecated with warning C4996, and recommends Microsoft-only replacements. The course code stays portable: define `_CRT_SECURE_NO_WARNINGS` for MSVC builds.

Do not disable a warning for the whole project. If a warning is wrong for one line, disable it for that line only, and write a comment that explains why.

## 7. Sanitizers

A sanitizer adds checks to the program at compile time. The checks find errors at run time that the compiler cannot find.

| Sanitizer | Finds | GCC and Clang (Linux, macOS) | MSVC | Phase |
|---|---|---|---|---|
| AddressSanitizer (ASan) | Out-of-range access, use after free, use after return, double free, memory leaks (Linux) | `-fsanitize=address -fno-omit-frame-pointer` | `/fsanitize=address` | 0 |
| UndefinedBehaviorSanitizer (UBSan) | Signed overflow, invalid shifts, null pointer use, misaligned access, invalid enum values | `-fsanitize=undefined` | Not available. Use clang-cl or WSL2. | 0 |
| ThreadSanitizer (TSan) | Data races, some deadlocks | `-fsanitize=thread` (not together with ASan) | Not available. Use WSL2, Linux, macOS, or CI. | 6 |

- Add the sanitizer flags to the compile and the link step. In phase 0, exercise 0.7, you write a build option for them.
- With MSVC, run the program from the Developer PowerShell (or from Visual Studio), so that the ASan runtime DLL is on the `PATH`. Do not combine `/fsanitize=address` with the run-time checks `/RTC1`, which CMake adds to debug builds by default. Link with `/INCREMENTAL:NO`.
- **Standard library checks:** in debug builds, enable the checks of the standard library. libstdc++: `-D_GLIBCXX_ASSERTIONS`. libc++ 18 or newer: `-D_LIBCPP_HARDENING_MODE=_LIBCPP_HARDENING_MODE_EXTENSIVE`. MSVC enables checked iterators in debug builds by default.

## 8. Other tools

| Tool | Source | Phase | Purpose |
|---|---|---|---|
| ccache or sccache (optional) | ccache.dev, github.com/mozilla/sccache | 0 | Faster rebuilds |
| Doxygen (optional) | doxygen.nl | 4 | Documentation from comments |
| SQLite command-line shell (`sqlite3`, optional) | sqlite.org | 7 | Look at the database |
| An HTTP client: `curl` (included in Windows 10 and newer, macOS, and most Linux systems), or a graphical client (for example Bruno) | | 7 | Send requests and read SSE streams (`curl -N`) |
| A WebSocket client: `websocat`, or the developer tools of a web browser | github.com/vi/websocat | 7 | Test the WebSocket endpoint |
| A profiler: `perf` (Linux), Instruments (macOS), the Visual Studio profiler or Intel VTune (Windows), Tracy (all) | | 8 | Find the slow parts of a program |
| Coverage: `gcovr` or `lcov` (GCC), `llvm-cov` (Clang), OpenCppCoverage or the Visual Studio coverage tool (Windows) | | 8 | Test coverage |
| `cppcheck` (optional) | cppcheck.sourceforge.io | 8 | A second static analyzer |
| GitHub CLI `gh` (optional) | cli.github.com | 8 | Pull requests from the terminal |
| Docker Desktop or Docker Engine | docker.com | 8 | Container images for the server |

## 9. Keep the tools up to date

At the start of each phase, update your tools with the method that you used to install them (Visual Studio Installer, `winget upgrade`, `brew upgrade`, or your distribution's package manager). After an update of the compiler, build all course projects again from a clean build directory, and fix the new warnings.
