# Starter Project

A small C++23 project with the default layout and settings of the course: a library, an executable, tests, the warning set, the sanitizers, and format and lint configuration. Use it as a reference when you make your own projects. Phase 0 tells you to build a project like this one step by step first.

## Layout

```
CMakeLists.txt              Targets: starter_core (library), starter (executable), starter_tests
CMakePresets.json           Presets: dev, debug, release, tsan
cmake/
  CompilerWarnings.cmake    The warning set of the course
  Sanitizers.cmake          AddressSanitizer, UndefinedBehaviorSanitizer, ThreadSanitizer
include/starter/            Public headers of the library
src/                        Source files of the library
app/                        The executable: main only
tests/                      The test executable
third_party/                Vendored libraries and the list of all third-party code
.clang-format               The code format
.clang-tidy                 The lint checks
```

## Build and test

1. Add doctest as `third_party/README.md` describes.
2. On Windows with MSVC, open the "Developer PowerShell for VS" first.
3. Configure, build, and test:

   ```sh
   cmake --preset dev
   cmake --build --preset dev
   ctest --preset dev
   ```

4. Run the program:

   ```sh
   ./build/dev/starter Ada
   ```

   ```powershell
   .\build\dev\starter.exe Ada
   ```

| Preset | Use |
|---|---|
| `dev` | Daily work. Debug build with AddressSanitizer and UndefinedBehaviorSanitizer (MSVC: only AddressSanitizer). |
| `debug` | Debug build without sanitizers. Use it with the debugger if the sanitizers make debugging slow. |
| `release` | Optimized build with debug information. Use it for measurements. |
| `tsan` | ThreadSanitizer. Only GCC or Clang, not on Windows. |

To use a different compiler, set it when you configure for the first time: `cmake --preset dev -DCMAKE_CXX_COMPILER=clang++`. To change it later, delete the build directory first.

## Format and lint

```sh
clang-format --dry-run --Werror include/starter/*.hpp src/*.cpp app/*.cpp tests/*.cpp
clang-tidy -p build/dev src/greeting.cpp app/main.cpp
```

Remove `--dry-run --Werror` and add `-i` to format the files in place.
