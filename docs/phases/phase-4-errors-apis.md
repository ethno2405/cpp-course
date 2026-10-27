# Phase 4: Errors, Libraries, and API Design

**Time:** 3–4 weeks.
**Prerequisites:** Phase 3.
**Code:** `labs/4-errors-apis/`

## Goal

At the end of this phase, you can:

- Separate bugs, expected errors, and exceptional errors, and select the correct mechanism for each: `assert`, `std::expected`, or exceptions.
- Write exception-safe code, and give the exception guarantee of each function.
- Design error types with context, for users and for developers.
- Split a project into library targets with clean public headers, and explain static and shared libraries, the ABI, and the pimpl idiom.
- Explain what C++20 modules are, and the current state of their support.
- Design types that cannot hold invalid values ("parse, don't validate").
- Write a command-line application with good error messages and exit codes, and test it.
- Read and write files safely.

## Reading

| Source | Part |
|---|---|
| Bjarne Stroustrup, *A Tour of C++*, 3rd edition | "Error Handling", "Modularity" |
| The C++ Core Guidelines | Sections "E: Error handling", "I: Interfaces", and "F: Functions" |
| cppreference.com | `std::expected`, "Exceptions", `noexcept`, "Modules", `std::filesystem` |
| Alexis King, "Parse, don't validate" (lexi-lambda.github.io) | All. The examples use Haskell; the idea is for every language. |
| [../topics/external-libraries.md](../topics/external-libraries.md) | "With a package manager" (optional in this phase) |
| CLI11 README (github.com/CLIUtils/CLI11) | The examples for options, flags, and subcommands |

## Topics

### 4.1 Three kinds of errors

| Kind | Example | Who handles it | Mechanism |
|---|---|---|---|
| A bug (a broken precondition or invariant) | An index out of range; a `Square` with the value 64; a null pointer where none is permitted | Nobody at run time. Fix the code. | `assert`, a contract check, or a stop of the program. Tests and sanitizers find it. |
| An expected error | Invalid user input; a file that does not exist; an illegal move in a protocol | The direct caller, in normal operation | `std::expected<T, E>` (or `std::optional<T>` if the reason is not important) |
| An exceptional error | Out of memory; a broken network in the middle of an operation; a failure deep inside a call chain that only a high level can handle | A caller several levels up | An exception |

- Decide the kind from the point of view of the caller: can the direct caller do something useful with this error? If yes, return it. If no, throw it, or treat it as a bug.
- A function documents its preconditions. Calling it with a broken precondition is a bug of the caller.

### 4.2 Exceptions

```cpp
#include <stdexcept>

void load(const std::filesystem::path& path) {
    std::ifstream in{path};
    if (!in) {
        throw std::runtime_error{std::format("cannot open {}", path.string())};
    }
    // ...
}

try {
    load("games.pgn");
} catch (const std::exception& e) {
    std::println(stderr, "error: {}", e.what());
}
```

- Throw by value, catch by `const&`. Derive your exception types from `std::exception` (usually from `std::runtime_error` or `std::logic_error`).
- When an exception leaves a scope, the destructors of all local objects run (stack unwinding). This is why RAII makes exceptions safe.
- **Exception safety guarantees** of a function:

  | Guarantee | Meaning |
  |---|---|
  | No-throw (`noexcept`) | The function never throws. Destructors, move operations, `swap`. |
  | Strong | If the function throws, the state is the same as before the call. ("Commit or roll back.") |
  | Basic | If the function throws, no resource leaks, and all objects are in a valid (but maybe changed) state. |
  | None | Avoid. |

- `noexcept` is a promise. If a `noexcept` function throws, the program ends with `std::terminate`. Mark a function `noexcept` only when it cannot throw.
- Do not let exceptions leave a destructor, a thread function (`std::terminate`), a C callback, or a function that a C library calls.
- Exceptions have no cost on the path without a throw in most implementations. A throw is slow (microseconds). Do not use exceptions for normal control flow, and do not throw in the hot path of the search.
- Some projects disable exceptions (`-fno-exceptions`), for example in games and embedded systems. The course uses exceptions at the boundaries, and `std::expected` inside.

### 4.3 `std::expected` in depth

```cpp
enum class FenErrorKind { wrong_field_count, invalid_piece, invalid_side, /* ... */ };

struct FenError {
    FenErrorKind kind;
    std::size_t position;   // the character position in the text
    std::string detail;
};

std::expected<Position, FenError> parse_fen(std::string_view text);
```

- **Monadic operations** chain steps that can fail, without nested `if` statements:

  | Operation | Does |
  |---|---|
  | `r.transform(f)` | If `r` has a value, returns `expected` with `f(value)`. Else keeps the error. |
  | `r.and_then(f)` | If `r` has a value, returns `f(value)`, which is itself an `expected`. Else keeps the error. |
  | `r.or_else(f)` | If `r` has an error, returns `f(error)`. Use it to recover. |
  | `r.transform_error(f)` | Changes the error type, for example to add context or to convert to the error type of a higher layer. |

  ```cpp
  auto result = read_file(path)
                    .and_then(parse_pgn)
                    .transform([](const Game& g) { return g.moves().size(); });
  ```

- Mark functions that return `std::expected` `[[nodiscard]]`, so that a caller cannot ignore the error.
- **`std::error_code`** is the standard type for operating system errors. Many `std::filesystem` functions have an overload with a `std::error_code&` parameter that does not throw.
- At the boundary between the parts that use exceptions and the parts that use `std::expected`, convert in one place: catch and return an error, or check and throw.

### 4.4 Error design

- **One error type for each library or layer.** The FEN parser has `FenError`, the PGN parser `PgnError`. A higher layer converts or wraps them.
- **Context:** a user needs to know what went wrong and where: "line 12, column 5: unknown piece 'X'". Put the position and the wrong text in the error.
- **Messages for users and for developers are different.** The user gets a short message on stderr. The developer gets the details in a log or in the debugger.
- **Do not log an error and also return it.** The layer that handles the error decides to log it. Else every error appears several times in the log.
- **Exit codes:** `0` for success, a non-zero value for an error. Document the codes of your tool. Write the error message to stderr, and the normal output to stdout, so that a user can pipe the output.
- **Errors in a protocol** (for example UCI) are different: the program must continue. Ignore or report the bad command, and keep the state valid.

### 4.5 Libraries and targets

- Split a project into library targets with clear responsibilities, and thin executables that use them. Then tests can use the libraries directly.
- **Public headers** are in `include/<project>/`, for example `include/chess/position.hpp`. Users write `#include <chess/position.hpp>`. **Private headers** stay next to the source files in `src/`.
- In CMake, `target_include_directories(chess_core PUBLIC include PRIVATE src)`, and `target_link_libraries(app PRIVATE chess_core)`. A `PUBLIC` dependency of a library is visible to all its users; a `PRIVATE` dependency is not. Keep dependencies `PRIVATE` when the public headers do not need them.
- **Static libraries** are copied into each executable. **Shared libraries** are loaded at run time. Shared libraries need more work: symbol visibility (`__declspec(dllexport)` on Windows, `-fvisibility=hidden` and visibility attributes on other systems), a stable ABI, and a deployment of the library file. CMake's `GenerateExportHeader` module helps. The course uses static libraries.

### 4.6 Headers and modules

- C++20 **modules** replace the textual inclusion of headers for a library:

  ```cpp
  // chess.cppm
  export module chess;
  export namespace chess {
      int perft(int depth);
  }

  // main.cpp
  import chess;
  ```

- Modules compile faster, do not leak macros, and make the public interface explicit with `export`. `import std;` (C++23) imports the whole standard library.
- The support is still new and different in each toolchain: CMake 3.28 or newer with Ninja supports modules with GCC 14, Clang 16 or newer, and MSVC; `import std;` needs CMake 3.30 or newer and is experimental in CMake. clangd, clang-tidy, and some IDEs have limited support.
- The course uses headers. Exercise 4.6 lets you try modules. Use them in the project only if your whole toolchain supports them.

### 4.7 Encapsulation and the ABI

- The **ABI** of a library is the binary interface: the size and layout of its types, the names and signatures of its functions, its vtables. If a header changes a private data member, the size of the type changes, and every user must compile again.
- The **pimpl idiom** (pointer to implementation) hides the private data in a separate class in the source file:

  ```cpp
  // engine.hpp
  class Engine {
  public:
      Engine();
      ~Engine();                       // defined in engine.cpp, where Impl is complete
      Engine(Engine&&) noexcept;
      Engine& operator=(Engine&&) noexcept;
      Move best_move(const Position& pos);
  private:
      struct Impl;
      std::unique_ptr<Impl> impl_;
  };
  ```

- Pimpl gives a stable ABI and fewer includes in the header (faster builds), at the cost of a heap allocation and an indirection. Use it for large classes at library boundaries, not for small value types.

### 4.8 Make illegal states unrepresentable

- **Strong types:** wrap a primitive in a class with rules. A `Square` holds 0–63, a `Port` holds 1–65535, an `EmailAddress` holds a valid address. The constructor or a factory function checks the rules; after that, every function can trust the value.
- **Parse, don't validate:** convert untrusted input to a strong type once, at the boundary. A function `bool is_valid_fen(std::string_view)` gives you a `bool`, and the rest of the code still has a string. A function `std::expected<Position, FenError> parse_fen(std::string_view)` gives you a `Position` that is always valid.
- Use `enum class` in place of `bool` parameters and strings with a fixed set of values.
- Use `std::variant` in place of a class with a type code and fields that are valid only for some codes.
- Use `std::optional` in place of a special value (`-1`, an empty string).
- Make constructors `explicit` when they take one argument, so that a `Square` does not appear from an `int` by accident.

### 4.9 API guidelines

From the C++ Core Guidelines, section "I", and common practice:

- Make interfaces explicit and precise. A function name and its parameter types tell what it does.
- State the preconditions and postconditions in a comment, and check the preconditions with `assert` in debug builds. (C++26 adds contracts: `pre` and `post` specifiers. The course does not use them yet.)
- Keep the number of parameters small. Group related parameters in a struct, and use designated initializers: `search(pos, SearchLimits{.depth = 6, .nodes = 1'000'000});`.
- Do not use `bool` parameters: `make_move(pos, m, true)` is not readable.
- Return values, not output parameters.
- `[[nodiscard]]` on functions whose result must be used.
- A small interface is easier to use correctly. Add functions when there is a need, not before.

### 4.10 Documentation

- Each public type and function in a library has a comment: what it does, its preconditions, and how it reports errors. The course does not require a special syntax.
- **Doxygen** (doxygen.nl) generates HTML documentation from comments in a special syntax (`///` or `/** */` with `@param`, `@return`). It is optional in the course.
- A `README.md` for each executable: what it does, how to build it, how to use it, with examples.
- Comments explain why, not what. The code says what.

### 4.11 Files and I/O

- `std::filesystem::path` represents a path in a portable way. Use it in place of `std::string` for paths. Functions: `exists`, `is_regular_file`, `create_directories`, `directory_iterator`, `rename`, `remove`, `file_size`.
- `std::ifstream` and `std::ofstream` read and write files. Check the stream state after you open it and after each operation: `if (!in) { ... }`. Streams do not throw by default.
- **Save a file safely:** write to a temporary file in the same directory, close it, check for errors, then rename it to the final name. On Linux and macOS (POSIX), a rename in the same file system replaces the old file in one atomic step. If the program stops in the middle, the old file is still complete. On Windows, `std::filesystem::rename` also replaces the old file, but Windows does not guarantee the same atomic step; read the documentation of `MoveFileEx` and `ReplaceFile` if you need it.
- **Text and binary mode:** on Windows, text mode converts `\n` to `\r\n`. Use binary mode (`std::ios::binary`) for data that is not text, and when you need the exact bytes.
- **Parse numbers** with `std::from_chars` (fast, no exceptions, no locale): it returns a pointer to the first unused character and an error code. Avoid `std::stoi` for untrusted input (it throws) and `atoi` (no error reporting).

### 4.12 Command-line applications

- Use a library for the arguments. The course uses **CLI11** (one header, BSD license): options, flags, subcommands, validation, and help text. Add it as a vendored single header ([../topics/external-libraries.md](../topics/external-libraries.md)).
- Keep `main` small: parse the arguments, make the objects, call a function that does the work, convert the result to an exit code. Put the work in a function `int run(std::span<const std::string_view> args, std::ostream& out, std::ostream& err)` in a library, so that tests can call it without a process.
- Read configuration in this order (the later one wins): defaults, a configuration file, environment variables, command-line options.

### 4.13 Tests at the level of the library

- **Unit tests** check one function or class. **Integration tests** check the public interface of a library, as a user would use it.
- **CLI tests** call the `run` function with arguments and string streams, and check the output and the exit code. A few end-to-end tests start the real executable (CTest can do this with `add_test(NAME ... COMMAND chess show --fen ...)` and `PASS_REGULAR_EXPRESSION`).
- Put test data files in `tests/data/`. Give the path to the tests with a compile definition (`target_compile_definitions(tests PRIVATE TEST_DATA_DIR="${CMAKE_CURRENT_SOURCE_DIR}/data")`), not with a relative path that depends on the working directory.
- Use CTest **labels** for slow tests: `set_tests_properties(perft_deep PROPERTIES LABELS slow)`, then `ctest -LE slow` for the daily run.

## Exercises

Make the project `labs/4-errors-apis/`.

### Exercise 4.1: Error type by hand (core)

1. Write a parser for a small configuration format: lines `key = value`, comments with `#`, empty lines.
2. Return `std::expected<Config, ParseError>`. `ParseError` has the line number, the column, a kind (`enum class`), and the wrong text.
3. Write a function that formats a `ParseError` for a user: `config.txt:3:7: missing '='`.
4. Write a test for each error kind.

### Exercise 4.2: Exceptions and `std::expected` (core)

1. Write the parser from exercise 4.1 a second time with exceptions. Compare the two versions: the code of the parser, the code of the caller, and the tests.
2. Write a function `void append_all(std::vector<Item>& target, const std::vector<Item>& source)` with the strong exception guarantee. Test it with a type `Item` whose copy constructor throws on the third copy. Check that `target` is unchanged after the exception.
3. Write in your notebook: when do you use each mechanism?

### Exercise 4.3: Strong types (core)

1. Write `Port` (1–65535), `Percentage` (0–100), and `NonEmptyString`. Each type has a factory function that returns `std::expected`, and no public constructor from an unchecked value.
2. Write a function `connect(Host host, Port port)`. Try to call it with the arguments in the wrong order. What happens?
3. Use `std::from_chars` to parse a `Port` from text. Test the limits, a negative value, an empty text, and a text with extra characters.

### Exercise 4.4: A command-line tool (core)

Write `wcx`, a clone of `wc` (count lines, words, and bytes), with CLI11.

1. Options: `-l`, `-w`, `-c`, and a list of files. Without files, read the standard input.
2. A missing file prints an error on stderr, continues with the other files, and gives the exit code 1 at the end.
3. Put the logic in a library with a `run` function. Test the output and the exit code without a process.
4. Add one end-to-end test that runs the executable with CTest.

### Exercise 4.5: Libraries and pimpl

1. Split exercise 4.4 into a library target with a public header in `include/wcx/` and an executable target.
2. Write a class `Counter` with pimpl. Change a private member in the `Impl` class. Which files does the build system compile again? Change a private member in a class without pimpl, in a public header. Which files compile again now?
3. Optional: build the library as a shared library. On Windows, make it work with `GenerateExportHeader`. On Linux, list the exported symbols with `nm -D`.

### Exercise 4.6: Modules (optional)

If your toolchain supports modules (see topic 4.6): convert the `wcx` library to a module with `export module wcx;`. Build it. Write what worked and what did not (the editor, clang-tidy, the build time) in your notebook.

### Exercise 4.7: Safe file save

1. Write `std::expected<void, std::error_code> save_atomically(const std::filesystem::path& path, std::string_view content)` with the temporary file and rename method.
2. Test it: a normal save, a save into a directory that does not exist, a save that fails in the middle (simulate it with a test hook that stops after the write). The old file must stay complete.

### Exercise 4.8: A package manager (optional)

Add CLI11 to a copy of exercise 4.4 with vcpkg (manifest mode with a baseline) or Conan (with a lock file). Compare with the vendored header: the number of steps, the configure time, and the files in the repository. Write the result in your notebook.

## Project: Chess engine, stage 2

See [../projects/chess-engine.md](../projects/chess-engine.md), stage 2.

## Done criteria

- [ ] I can say for each error in my code whether it is a bug, an expected error, or an exceptional error, and why I selected the mechanism.
- [ ] I can explain the three exception safety guarantees, and I have a test for the strong guarantee.
- [ ] I can use the monadic operations of `std::expected`.
- [ ] My error messages tell the user what is wrong and where.
- [ ] I can explain static and shared libraries, the ABI, and the cost and benefit of pimpl.
- [ ] I can explain what modules change, and why the course still uses headers.
- [ ] My strong types cannot hold invalid values.
- [ ] My command-line tools have tests for the output and the exit code, and they never crash on bad input.
- [ ] Chess engine stage 2 is complete, and the engine works in a real chess GUI.

## Next

[Phase 5: Software design and SOLID](phase-5-software-design.md)
