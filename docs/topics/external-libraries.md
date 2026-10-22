# External Libraries

**Phase:** 0, then all phases
**Related:** [phase 0](../phases/phase-0-tools.md), [phase 4](../phases/phase-4-errors-apis.md), [phase 8](../phases/phase-8-professional-practices.md), [build systems](build-systems.md), [toolchain selection](../mentor/toolchain-selection.md)

## Summary

C++ has no single standard package manager. Many C++ projects manage their third-party libraries by hand, and many teams use a package manager only for some libraries. This topic teaches the manual methods first, because they show what every package manager does for you: get the source at an exact version, check it, build it with the correct options, and make it available to your targets. Then it shows vcpkg and Conan, and when to use them.

## Explanation

### What a C++ library is

A C++ library has two parts:

- **Headers:** the declarations that your code includes. The compiler needs them.
- **Compiled code:** a static library (`.a`, `.lib`) or a shared library (`.so`, `.dylib`, `.dll` with an import `.lib`). The linker needs it. A **header-only** library has no compiled part: all the code is in the headers.

Compiled code has an **ABI** (application binary interface). Two pieces of compiled code work together only if their ABIs match: the same architecture, a compatible compiler, the same standard library, compatible runtime settings, and the same preprocessor definitions that change the layout of types. This is the main reason why C++ library management is harder than in other languages. The safest method is to **build every dependency from source, with the same compiler and options as your project**.

### Methods

| Method | How | Good | Bad | Course use |
|---|---|---|---|---|
| Header-only file | Copy the header(s) into `third_party/` | Simplest. No build step. | Longer compile times for large libraries | doctest, CLI11, nlohmann/json, nanobench |
| Vendored source | Copy a released source tree into `third_party/`, build it as part of your project | Full control. Works offline. Same compiler and options. | Larger repository. You must update by hand. | SQLite amalgamation, Dear ImGui |
| Git submodule | `git submodule add <url> third_party/<name>`, pinned to a commit | The repository stays small. The commit is pinned. | Every clone needs `git submodule update --init --recursive`. Easy to forget. | Optional |
| Git subtree | `git subtree add --prefix third_party/<name> <url> <tag> --squash` | Code is in the repository; no extra command for users | Updates and the history are harder to read | Optional |
| `FetchContent` (CMake) or the equivalent | The build system downloads a pinned archive or commit at configure time | Small repository. Pinned and checked with a hash. Same compiler and options. | Needs the network at the first configure. Large libraries make the configure slow. | SDL3, Boost (Asio and Beast), spdlog, RapidCheck, Google Benchmark |
| Build and install to a local prefix | Build the library one time, install it to a directory, find it with `find_package` | Fast configure of your project. One build for many projects. | You must build it again for each compiler and configuration | Optional; good for Boost or Qt |
| Prebuilt binaries | Download compiled files from the library website | No build time | ABI risk (see below). Hard to reproduce. | Avoid, except Qt from the official installer |
| System package manager | `apt`, `dnf`, `brew`, `pacman` (MSYS2) | Easy | The version depends on the operating system and changes with updates. Not available on Windows (except MSYS2). | Tools only (CMake, Ninja), not libraries |
| vcpkg | A manifest `vcpkg.json` with a baseline | Many libraries. Builds from source. Good Windows support. | Another tool to learn. The first build of large libraries is slow. | Optional, from phase 4 |
| Conan 2 | A `conanfile` and a lock file | Many libraries. Binary packages for many configurations. Profiles. | Another tool (Python) to learn. More concepts. | Optional, from phase 4 |

### Best practices for manual management

1. **Get the code from the official source.** Use the release page of the project, its official website, or its official repository. Check the exact name: attackers publish packages and repositories with names that are similar to popular ones.
2. **Pin an exact version.** Use a release tag and its archive, or a full commit hash. Never use a branch name like `master` or `main`: the content can change without notice.
3. **Check the integrity.** Compute the SHA-256 hash of each downloaded archive or file, and write it in the dependency list. With `FetchContent`, put the hash in `URL_HASH`, so that CMake checks it at each download. If the project publishes hashes or signatures (SQLite publishes SHA3-256 hashes on its download page), compare them.
4. **Keep one dependency list.** Write each library in `third_party/README.md`: name, version, source URL, hash, license, method, and patches. A reviewer must see every dependency in one file. Example of one row:

   | Library | Version | Source | SHA-256 | License | Method | Patches |
   |---|---|---|---|---|---|---|
   | doctest | 2.4.11 | github.com/doctest/doctest, tag `v2.4.11`, file `doctest/doctest.h` | `<the hash that you computed>` | MIT (`third_party/doctest/LICENSE.txt`) | Vendored header | None |
5. **Keep the license.** Copy the license file of each library next to its code. Check that the license is compatible with your use before you add the library (see "Licenses").
6. **Do not change vendored code.** If you must change it, put the change in a patch file in `third_party/patches/`, apply it in the build or with a script, and list it in the dependency list. Then an update does not lose your change.
7. **Build dependencies with your toolchain.** Use the same compiler, C++ standard, standard library, build type, and runtime library as your project. Add the library as a subdirectory, or build it from source with the same toolchain.
8. **Isolate the warnings.** Add the include directories of third-party code as `SYSTEM` include directories. Then the warnings of the library do not stop your build with `-Werror`. Do not apply your warning set to third-party targets.
9. **Do not commit build outputs or downloaded archives.** Commit the extracted, pinned sources (for vendoring) or the pinned declaration (for `FetchContent`). The `.gitignore` of the course ignores `third_party/_downloads/` and all build directories.
10. **Make it work offline.** With `FetchContent`, a user can set `FETCHCONTENT_SOURCE_DIR_<NAME>` to a local copy, or `FETCHCONTENT_FULLY_DISCONNECTED=ON` after the first download.
11. **Update on purpose.** Update one library at a time, in its own commit. Read the release notes for breaking changes. Update the version, the hash, and the license file. Build and run all tests, also under the sanitizers.
12. **Watch for security advisories.** Check the libraries in your list from time to time (the GitHub security advisories, OSV.dev, the release notes). Phase 8 automates part of this.
13. **Keep the number of dependencies small.** Each library adds build time, risk, and update work. Before you add a library, ask whether a small piece of your own code is enough.

### ABI problems with prebuilt binaries

If you must use a prebuilt library, check each item:

| Item | Problem | Example |
|---|---|---|
| Compiler family | GCC and MSVC binaries cannot be mixed. Clang is compatible with GCC on Linux and with MSVC as clang-cl on Windows. | A MinGW `.a` file with an MSVC project |
| MSVC runtime library | `/MD` (DLL runtime) and `/MT` (static runtime) cannot be mixed. CMake selects it with `CMAKE_MSVC_RUNTIME_LIBRARY`. | Link error `LNK2038: mismatch detected for 'RuntimeLibrary'` |
| Debug and release on MSVC | Debug and release builds use different runtimes and different layouts of standard containers | Link error `LNK2038: mismatch detected for '_ITERATOR_DEBUG_LEVEL'` |
| Standard library | libstdc++ and libc++ are not compatible | A library built with `-stdlib=libc++`, used with libstdc++ |
| libstdc++ ABI macro | `_GLIBCXX_USE_CXX11_ABI` changes `std::string` and `std::list` | Undefined references to `std::__cxx11::basic_string` |
| Architecture | x86-64 and arm64 cannot be mixed | An x64 library on an Apple silicon build |
| macOS deployment target | A library built for a newer macOS version | Linker warnings, crashes on older systems |
| Preprocessor options that change types | For example a library option that changes the size of a structure | Crashes at run time, not at link time |

### Recipes without a package manager

These recipes use CMake. The [build systems topic](build-systems.md) shows the equivalent forms for other build systems.

**A header-only library (doctest):**

```cmake
add_library(doctest INTERFACE)
add_library(doctest::doctest ALIAS doctest)
target_include_directories(doctest SYSTEM INTERFACE "${PROJECT_SOURCE_DIR}/third_party/doctest")
```

**A vendored C library (the SQLite amalgamation):** download the "amalgamation" archive from sqlite.org. It contains `sqlite3.c`, `sqlite3.h`, and `sqlite3ext.h`. SQLite is in the public domain.

```cmake
project(chess LANGUAGES C CXX)   # SQLite is C code

find_package(Threads REQUIRED)
add_library(sqlite3 STATIC third_party/sqlite/sqlite3.c)
add_library(SQLite::SQLite3 ALIAS sqlite3)
target_include_directories(sqlite3 SYSTEM PUBLIC "${PROJECT_SOURCE_DIR}/third_party/sqlite")
target_compile_definitions(sqlite3 PRIVATE SQLITE_DQS=0 SQLITE_OMIT_LOAD_EXTENSION)
target_link_libraries(sqlite3 PRIVATE Threads::Threads)
```

**A vendored library without a build file (Dear ImGui with the SDL3 backend):** Dear ImGui has no CMake file. You write the target yourself.

```cmake
set(IMGUI_DIR "${PROJECT_SOURCE_DIR}/third_party/imgui")
add_library(imgui STATIC
    ${IMGUI_DIR}/imgui.cpp
    ${IMGUI_DIR}/imgui_draw.cpp
    ${IMGUI_DIR}/imgui_tables.cpp
    ${IMGUI_DIR}/imgui_widgets.cpp
    ${IMGUI_DIR}/imgui_demo.cpp
    ${IMGUI_DIR}/backends/imgui_impl_sdl3.cpp
    ${IMGUI_DIR}/backends/imgui_impl_sdlrenderer3.cpp
)
target_include_directories(imgui SYSTEM PUBLIC ${IMGUI_DIR} ${IMGUI_DIR}/backends)
target_link_libraries(imgui PUBLIC SDL3::SDL3)
```

**A pinned download with `FetchContent` (SDL3):**

```cmake
include(FetchContent)
FetchContent_Declare(SDL3
    URL      https://github.com/libsdl-org/SDL/releases/download/release-<version>/SDL3-<version>.tar.gz
    URL_HASH SHA256=<the hash that you computed>
    FIND_PACKAGE_ARGS CONFIG   # use an installed SDL3 if one exists
)
set(SDL_SHARED OFF CACHE BOOL "" FORCE)
set(SDL_STATIC ON CACHE BOOL "" FORCE)
FetchContent_MakeAvailable(SDL3)
```

Replace `<version>` with the release that you selected. Check the URL on the release page. Compute the hash of the downloaded file yourself, and compare it with the hash on the release page if the project publishes one. To pin a git commit in place of an archive, use `GIT_REPOSITORY <url>` and `GIT_TAG <full commit hash>`, never a branch name.

**Only a part of Boost (Asio and Beast):** Boost is large. Asio and Beast are header-only, but they need the headers of many other Boost libraries. Select one method:

1. Download the official Boost release archive (boost.io), and extract only the `boost/` header directory to a local prefix outside the repository. Add that directory as a `SYSTEM` include directory. You do not need to build Boost for Asio and Beast.
2. Use `FetchContent` with the CMake release archive of Boost (the `boost-<version>-cmake.tar.xz` file on the release page of the `boostorg/boost` repository), and set `BOOST_INCLUDE_LIBRARIES` to `asio;beast` before `FetchContent_MakeAvailable`. Then CMake configures only these libraries and their dependencies. Link `Boost::asio` and `Boost::beast`.
3. Use a package manager for Boost (see below). Many teams use a package manager only for Boost and Qt.

On Windows, Asio needs the Windows socket libraries (`ws2_32`, `mswsock`) and a minimum Windows version (`_WIN32_WINNT`). The Boost CMake targets set them; with method 1, add them yourself.

**Build and install to a local prefix, then `find_package`:**

```sh
cmake -S path/to/library-source -B build-lib -G Ninja -DCMAKE_BUILD_TYPE=Debug -DCMAKE_INSTALL_PREFIX="$HOME/cpp-deps/debug"
cmake --build build-lib
cmake --install build-lib
cmake --preset dev -DCMAKE_PREFIX_PATH="$HOME/cpp-deps/debug"
```

In your `CMakeLists.txt`: `find_package(<Name> CONFIG REQUIRED)`. Keep a separate prefix for each compiler and build type. Write the prefix in `CMakeUserPresets.json`, not in the shared presets: it is a local path.

### With a package manager

**vcpkg (manifest mode):** a `vcpkg.json` file in the project root lists the dependencies. The `builtin-baseline` is a commit of the vcpkg registry: it pins the versions of all ports.

```json
{
  "dependencies": [ "sdl3", "boost-beast", "nlohmann-json" ],
  "builtin-baseline": "<a full commit hash of the vcpkg repository>",
  "overrides": [ { "name": "nlohmann-json", "version": "<exact version>" } ]
}
```

Configure with the vcpkg toolchain file: `-DCMAKE_TOOLCHAIN_FILE=<vcpkg root>/scripts/buildsystems/vcpkg.cmake` (put it in a preset). vcpkg builds the libraries from source with your compiler, and `find_package` finds them.

**Conan 2:** a `conanfile.txt` (or `conanfile.py`) lists the dependencies. A lock file pins the exact versions and revisions.

```ini
[requires]
sdl/<version>
nlohmann_json/<version>

[generators]
CMakeDeps
CMakeToolchain

[layout]
cmake_layout
```

Run `conan install . --build=missing -s build_type=Debug`, then use the presets that Conan generates. Create a lock file with `conan lock create .` and commit it.

| | vcpkg | Conan 2 |
|---|---|---|
| Written in | C++ (the tool), CMake (the ports) | Python |
| Pinning | A baseline commit and overrides | Exact versions and a lock file |
| Binaries | Builds from source; binary caching is optional | Downloads binary packages when they match the profile, else builds |
| Build system support | Best with CMake and MSBuild | CMake, Meson, MSBuild, Autotools, and others |
| Private packages | Overlay ports, custom registries | A private server (for example Artifactory or the Conan server) |

Use the exact package names and versions from the vcpkg port list (vcpkg.io) or ConanCenter (conan.io/center). Do not guess them.

A package manager does not remove your responsibility: you still pin versions, check licenses, update on purpose, and watch for security advisories.

### Licenses

| License | Main condition for an application that you distribute |
|---|---|
| MIT, BSD (2- and 3-clause), Boost Software License 1.0, zlib | Keep the copyright notice and the license text. (zlib: do not misrepresent the origin.) |
| Apache 2.0 | Keep the notices, the license, and the `NOTICE` file. Has a patent clause. |
| Public domain (SQLite) | No conditions |
| LGPL (for example Qt under LGPL) | Users must be able to replace the library with a changed version: link dynamically, or give the object files. Keep the license. |
| GPL | Your whole application must be under the GPL when you distribute it |

This is not legal advice. For a commercial product, ask your company's legal team. In phase 8, the release contains a file with the licenses of all third-party code.

### The libraries of the course

| Library | Phase | License | Recommended method |
|---|---|---|---|
| doctest | 0 | MIT | Vendored single header |
| CLI11 | 4 | BSD-3-Clause | Vendored single header (`CLI11.hpp` from a release) |
| Dear ImGui | 6 | MIT | Vendored source, own CMake target |
| SDL3 | 6 | zlib | `FetchContent` with a hash, or a local prefix, or a package manager |
| Boost.Asio and Boost.Beast | 7 | Boost Software License 1.0 | Headers in a local prefix, or the Boost CMake archive with `BOOST_INCLUDE_LIBRARIES`, or a package manager |
| nlohmann/json | 7 | MIT | Vendored single header (`json.hpp` from a release) |
| SQLite | 7 | Public domain | Vendored amalgamation |
| spdlog | 7 | MIT | `FetchContent` with a hash |
| RapidCheck | 8 | BSD-2-Clause | `FetchContent` pinned to a full commit hash (the project has no release tags) |
| nanobench or Google Benchmark | 8 | MIT or Apache 2.0 | Vendored single header (nanobench), or `FetchContent` (Google Benchmark) |
| libFuzzer | 8 | Part of Clang (and of MSVC) | Comes with the compiler |
| Qt 6 (optional) | 6 | LGPL v3 or commercial | The official installer, or a package manager |

Check the license of the version that you download. Licenses can change between versions.

## Example

A `FetchContent` declaration with a wrong hash stops the configure:

```text
CMake Error at .../FetchContent.cmake: ...
  HASH mismatch
    for file: [.../SDL3-<version>.tar.gz]
      expected hash: [...]
        actual hash: [...]
```

This is the correct result. Do not replace the hash with the new value before you know why the file changed.

## Common mistakes

| Mistake | Result | Fix |
|---|---|---|
| `GIT_TAG main` | A different version in each new clone; builds break without a change in your code | Pin a tag with a hash, or a full commit hash |
| No hash for a downloaded archive | A changed or attacked download is not detected | `URL_HASH SHA256=...` |
| The warning set applies to third-party code | `-Werror` stops the build in code that you do not own | `SYSTEM` include directories; no warning options on third-party targets |
| A prebuilt Release library in a Debug MSVC build | `LNK2038` link errors, or crashes | Build the library from source in the same configuration |
| A change in a vendored file | The next update loses the change | A patch file, listed in the dependency list |
| Many large libraries for small tasks | Long builds, more risk, more updates | Write the small function yourself, or use the standard library |
| A library from a system package manager in a project that other people build | A different version on each computer | Vendor it, `FetchContent` with a pin, or a package manager with a lock |

## Sources

- CMake documentation: "Using Dependencies Guide", "FetchContent", "find_package" (cmake.org)
- vcpkg documentation, "Manifest mode" and "Versioning" (learn.microsoft.com/vcpkg)
- Conan 2 documentation, "Tutorial" and "Lockfiles" (docs.conan.io)
- SQLite documentation, "The SQLite Amalgamation" and "Compile-time Options" (sqlite.org)
- Titus Winters, Tom Manshreck, and Hyrum Wright, *Software Engineering at Google*, the chapter about dependency management
- OpenSSF, "Concise Guide for Evaluating Open Source Software" (openssf.org)
