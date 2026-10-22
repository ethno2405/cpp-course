# Phase 1: C++ Basics

**Time:** 1 week if you already wrote programs in modern C++. 2 weeks if you know C, Rust, or old C++. 3 weeks if you know C#, Java, Go, Swift, Kotlin, or TypeScript. 4–6 weeks if you know only dynamic languages.
**Prerequisites:** Phase 0.
**Code:** `labs/phase-1-basics/`

## Goal

At the end of this phase, you can:

- Write small C++ programs with functions, classes, `enum class`, and control flow.
- Initialize every variable, and use `const` and `constexpr`.
- Use `std::optional`, `std::variant`, and `std::expected` in place of null values, type codes, and error codes.
- Use the standard containers and strings: `std::vector`, `std::array`, `std::string`, `std::string_view`, `std::map`, `std::unordered_map`, `std::set`.
- Split a program into headers, source files, and namespaces.
- Write unit tests for each function that you write.
- Name the most common kinds of undefined behavior, and avoid them.

## Reading

| Source | Part |
|---|---|
| learncpp.com | Chapters 1–13 and the chapters about `std::vector`, `std::array`, and `std::string_view`. Skip what you know. Read the chapters about pointers and references quickly: phase 2 explains them in detail. |
| Bjarne Stroustrup, *A Tour of C++*, 3rd edition | "The Basics", "User-Defined Types", "Modularity", "Classes", "Strings and Regular Expressions" (without regular expressions), "Containers". For experienced programmers, this is faster than learncpp.com. |
| cppreference.com | The pages of each type in this phase. Read the examples. |
| The C++ Core Guidelines | Section "ES: Expressions and statements": the rules about initialization and narrowing |
| Exercism, C++ track (exercism.org/tracks/cpp) | Exercises with automatic tests, in parallel with the reading |

## Topics

### 1.0 Static types and compilation (only for learners of dynamic languages)

Skip this topic if you know a statically typed language (C#, Java, Go, TypeScript, C, Rust).

- **Static types:** the compiler knows the type of every variable before the program runs. It rejects a program that uses a value with a wrong type. In Python or JavaScript, you find this error only when the line runs.
- **Type deduction:** with `auto`, the compiler finds the type from the initializer: `auto x = 5;` is an `int`. You must write the types of function parameters (or use templates, phase 3).
- **Compilation:** the build translates the whole program to machine code before it runs. Many errors that a dynamic language finds at run time (or never), the compiler finds at compile time.
- **The cost:** you must satisfy the compiler before the program runs. This feels slow at first. The benefit is that a program that compiles has fewer defects, and you can change large programs safely.
- **The C++ difference:** the compiler does not check everything. Some errors (undefined behavior, topic 1.11) compile and run. The tools from phase 0 (warnings, sanitizers) help.

### 1.1 C++ compared with other languages

| Feature in other languages | Examples | C++ |
|---|---|---|
| Classes with fields and methods | C#, Java, Python | `class` or `struct` with data members and member functions. Objects are values by default (topic 1.5). |
| Interfaces | C#, Java, Go, TypeScript | Abstract classes with pure virtual functions, or concepts with templates (phases 3 and 5) |
| Inheritance | C#, Java, Python | Yes, also multiple inheritance. Use it with care (phase 5). |
| `null`, `nil`, `None` | All | `std::optional<T>` for "maybe a value". Pointers can be null; avoid raw pointers for this purpose. |
| Exceptions | C#, Java, Python, JavaScript | Exceptions exist. `std::expected<T, E>` is an alternative for errors that the caller must handle (topic 1.7, phase 4). |
| Garbage collector | C#, Java, Python, Go, JavaScript | None. Objects end at a known point, and their destructor releases their resources (RAII, phase 2). |
| `switch` | C#, Java, Go | `switch` on integers and enumerations. `std::visit` on a `std::variant` (topic 1.6). |
| Enums with data (algebraic data types) | Rust, Swift, Kotlin, F# | `std::variant` of several types |
| Packages and namespaces | All | Namespaces for names; headers and libraries for code (topic 1.9). Modules exist (phase 4). |
| `private`, `public` | C#, Java, TypeScript | `private`, `protected`, `public` sections in a class. `struct` is public by default, `class` is private by default. |
| Lambdas | All | Lambdas with explicit captures (phase 3) |
| Generics | C#, Java, Go, TypeScript | Templates, checked with concepts (phase 3) |
| Reflection, annotations | C#, Java, Python | Almost none at run time. Attributes (`[[nodiscard]]`) give hints to the compiler. Compile-time reflection is planned for C++26. |

**Notes for programmers of managed languages (C#, Java, Go):**

- Objects are values. `Rectangle b = a;` makes a **copy**, not a second reference to the same object. To refer to an object, use a reference (`Rectangle& r = a;`) or a pointer.
- There is no garbage collector. An object ends at the end of its scope, or when its owner ends. Phase 2 explains this.
- A local variable of a built-in type without an initializer has an indeterminate value. Reading it is undefined behavior. Always initialize.

**Notes for programmers of dynamic languages (Python, JavaScript):**

- A `std::vector<T>` holds values of one type only. To hold different types, use a `std::variant` (topic 1.6).
- Integers have fixed sizes. Signed overflow is undefined behavior (topic 1.3).
- A `std::string` holds bytes, not characters. `s[3]` is the fourth byte (topic 1.8).

**Notes for Rust programmers:**

- The compiler does not check lifetimes and borrows. A dangling reference compiles. Use the sanitizers.
- Copy is the default for assignment, not move. `std::move` (phase 2) asks for a move, and a moved-from object is still usable (in a valid but unspecified state).
- `std::variant` with `std::visit` is the closest form of an `enum` with data and `match`. Exhaustiveness is checked, but the error messages are longer.

**Notes for C programmers:**

- Use `std::string`, `std::vector`, and `std::array` in place of `char*`, `malloc`, and raw arrays.
- Use `const` and `constexpr` in place of `#define` for constants, and functions or templates in place of function-like macros.
- Use references in place of pointers for parameters that cannot be null.

### 1.2 Variables, initialization, and `const`

- Initialize every variable. Prefer **brace initialization**: `int count{0};` or `int count = 0;`. Braces reject narrowing conversions: `int x{3.7};` does not compile, but `int x = 3.7;` compiles and gives 3.
- `auto` deduces the type: `auto total = 0.0;` is a `double`. Use `auto` when the type is clear from the right side or is not important.
- `const int max_items = 100;` cannot change after its initialization. Make a variable `const` when it does not change. This is most variables.
- `constexpr int board_size = 8;` is a constant that the compiler knows at compile time. Use it in place of `#define`.
- The **scope** of a variable is the block (`{ ... }`) where it is declared. The variable ends at the end of the block.

### 1.3 Types and conversions

| Type | Examples | Notes |
|---|---|---|
| Signed integers | `int`, `long`, `long long`, `std::int32_t`, `std::int64_t` | `int` has at least 16 bits (in practice 32). Use `<cstdint>` types when the size is important. |
| Unsigned integers | `unsigned`, `std::uint8_t`, `std::uint64_t`, `std::size_t` | `std::size_t` is for sizes and indexes. Unsigned arithmetic wraps around. |
| Floating point | `float`, `double` | Never use them for money or exact values. |
| Boolean | `bool` | `true`, `false` |
| Character | `char`, `char8_t`, `char32_t` | A `char` is one byte, not one Unicode character |
| Fixed-size array | `std::array<int, 4>` | Use it in place of `int[4]` |

- **Signed integer overflow is undefined behavior.** `INT_MAX + 1` can give any result, and the compiler can remove your overflow check. If overflow is possible, check before the operation, or use a larger type. Unsigned overflow is defined: it wraps around.
- **Implicit conversions:** C++ converts between number types silently. `int` to `double`, `double` to `int` (the fraction is lost), signed to unsigned (a negative value becomes a large positive value). The warning set of the course (`-Wconversion`, `-Wsign-conversion`, `/W4`) finds most of them.
- **Explicit conversions:** `static_cast<int>(x)` says that you want the conversion. Do not use C-style casts `(int)x`: they can do dangerous conversions without a warning.
- **Mixed signed and unsigned:** `v.size()` is unsigned. `if (i < v.size())` with a signed `i` compares after a conversion. Use `std::ssize(v)` (signed) or `std::size_t` for indexes, or better, a range-based `for` loop.

### 1.4 Functions, expressions, and control flow

- A function has a return type, a name, and parameters: `int add(int a, int b) { return a + b; }`.
- `void` means "returns nothing". A function that is not `void` must return a value on every path. A missing `return` is undefined behavior (the warning set finds it).
- Pass parameters **by value** for small types (`int`, `double`, `Square`). Pass large types that the function only reads **by `const` reference**: `void print(const std::vector<int>& values)`. Phase 2 gives the full rules.
- `if`, `else`, `while`, `do`, `for`, `break`, `continue`, `return` work as in C and Java.
- A **range-based `for` loop** iterates over a container: `for (const auto& item : items) { ... }`. Prefer it to a loop over indexes.
- `if` with an initializer: `if (auto it = m.find(key); it != m.end()) { ... }`. The variable `it` exists only in the `if` and `else` blocks.
- **Function overloading:** two functions can have the same name with different parameter types. Do not overload functions that do different things.
- **Default arguments:** `void draw(int width = 80);`. Use them rarely; a second function with a clear name is often better.
- `[[nodiscard]]` on a function makes the compiler warn when the caller ignores the result. Use it for functions whose result must be checked.

### 1.5 Classes

```cpp
#include <stdexcept>

class Rectangle {
public:
    // A constructor makes a valid object or throws.
    Rectangle(int width, int height) : width_{width}, height_{height} {
        if (width <= 0 || height <= 0) {
            throw std::invalid_argument{"the sides must be positive"};
        }
    }

    // A static member function. Call it with Rectangle::square(5).
    static Rectangle square(int size) { return Rectangle{size, size}; }

    // A const member function does not change the object.
    int area() const { return width_ * height_; }

    void scale(int factor) {
        width_ *= factor;
        height_ *= factor;
    }

    // Two rectangles are equal if all data members are equal.
    bool operator==(const Rectangle&) const = default;

private:
    int width_;
    int height_;
};
```

- **Data members** are private when the class has an **invariant** (a rule that is always true, for example "both sides are positive"). Only the member functions can change them, so they can keep the invariant.
- **Constructors** make a valid object. Initialize members in the member initializer list (`: width_{width}`), not in the body. A constructor cannot return an error; it throws an exception. A **factory function** that returns `std::optional` or `std::expected` (topic 1.7) is an alternative when invalid input is normal.
- **`const` member functions** can be called on `const` objects. Mark every member function that does not change the object as `const`.
- `struct` is a class with public members by default. Use `struct` for plain data without an invariant: `struct Point { int x = 0; int y = 0; };`. You can initialize it with **designated initializers**: `Point p{.x = 1, .y = 2};`.
- `operator==` with `= default` compares all members. `operator<=>` with `= default` gives all comparisons (phase 3).
- `this` is a pointer to the current object. You rarely need it.

### 1.6 `enum class`, `switch`, and `std::variant`

**`enum class`** is a type with a fixed set of named values:

```cpp
enum class Color { white, black };

Color opposite(Color c) {
    switch (c) {
    case Color::white: return Color::black;
    case Color::black: return Color::white;
    }
    std::unreachable();   // all enumerators return above
}
```

- Use `enum class`, not the old plain `enum`. A plain `enum` converts silently to `int`, and its names go into the surrounding scope.
- The compiler warns when a `switch` does not handle an enumerator (`-Wswitch`). Do not add a `default:` case: it hides the warning when you add an enumerator.
- `std::to_underlying(c)` (C++23) converts to the underlying integer when you need it.

**`std::variant<A, B, C>`** holds a value of exactly one of several types. It is the C++ form of an enum with data in other languages.

```cpp
#include <numbers>
#include <variant>

struct Circle { double radius; };
struct Rect { double width; double height; };
using Shape = std::variant<Circle, Rect>;

// Makes one callable type from several lambdas.
template <typename... Fs>
struct Overloaded : Fs... {
    using Fs::operator()...;
};

double area(const Shape& shape) {
    return std::visit(Overloaded{
        [](const Circle& c) { return std::numbers::pi * c.radius * c.radius; },
        [](const Rect& r) { return r.width * r.height; },
    }, shape);
}
```

- `std::visit` calls the lambda that matches the type in the variant. If a type has no matching lambda, the program does not compile. When you add a type to the variant, the compiler shows every `std::visit` that you must update.
- `std::holds_alternative<Circle>(shape)` checks the type. `std::get_if<Circle>(&shape)` returns a pointer or `nullptr`. `std::get<Circle>(shape)` throws `std::bad_variant_access` if the type is wrong.
- Do not read the `Overloaded` template in detail now. Phase 3 explains templates.

### 1.7 `std::optional` and `std::expected`

- `std::optional<T>` holds a `T` or nothing (`std::nullopt`). Use it for "maybe a value", in place of a special value like `-1` or a null pointer.

  ```cpp
  std::optional<int> parse_digit(char c) {
      if (c < '0' || c > '9') {
          return std::nullopt;
      }
      return c - '0';
  }
  ```

- `std::expected<T, E>` (C++23) holds a `T` (the value) or an `E` (the error). Use it when a function can fail and the caller must know why.

  ```cpp
  std::expected<int, std::string> parse_percent(std::string_view text);
  // On success: return 42;
  // On failure: return std::unexpected{"not a number"};
  ```

- Check before you use the value:

  | Expression | Result |
  |---|---|
  | `if (result)` or `result.has_value()` | `true` if there is a value |
  | `*result` | The value. **Undefined behavior if there is no value.** |
  | `result.value()` | The value, or an exception if there is no value |
  | `result.value_or(0)` | The value, or the default |
  | `result.error()` | The error (`std::expected` only). Undefined behavior if there is a value. |
  | `result.transform(f)`, `result.and_then(f)` | Change the value, or chain operations that can fail (phase 4) |

### 1.8 Strings and containers

| Type | Use |
|---|---|
| `std::string` | A growable, owned sequence of bytes (`char`). Usually UTF-8 text. |
| `std::string_view` | A read-only view of characters that another object owns. Use it for parameters that only read text. Never store it longer than the owner lives. |
| `std::vector<T>` | A growable array. The default container. |
| `std::array<T, N>` | A fixed-size array, with the size known at compile time |
| `std::map<K, V>` | Key-value pairs, sorted by key |
| `std::unordered_map<K, V>` | Key-value pairs, no order, usually faster |
| `std::set<T>`, `std::unordered_set<T>` | Unique values |
| `std::deque<T>` | A queue with fast insert and remove at both ends |

- **Formatting and printing (C++23):** `std::println("{} has {} moves", name, count);` prints a line to the standard output. `std::format(...)` returns a `std::string`. `std::println(stderr, ...)` prints to the standard error. Format options: `{:>8}` (align right, width 8), `{:.2f}` (2 decimal places), `{:08x}` (hexadecimal, 8 digits).
- `v[i]` does not check the index: an index out of range is undefined behavior. `v.at(i)` checks and throws `std::out_of_range`. Prefer range-based `for` loops and algorithms, which do not need an index.
- `std::string` stores bytes. `s.size()` is the number of bytes, not characters. A UTF-8 character can use 1–4 bytes.
- To update a map in one lookup: `++counts[word];` (makes a value with 0 if the key is missing), or `counts.try_emplace(key, value)`.
- `m.find(key)` returns an iterator, or `m.end()` if the key is missing. `m.contains(key)` (C++20) returns a `bool`.
- Adding elements to a `std::vector` can move all elements to a new buffer. Then all references, pointers, and iterators to its elements dangle. Phase 2 explains why.

### 1.9 Headers, source files, and namespaces

- Put declarations in a header (`library.hpp`), and definitions in a source file (`library.cpp`). The source file includes its own header first.
- A header starts with `#pragma once`.
- A **namespace** groups names: `namespace chess { class Position; }`. Use one namespace for each project or library. Use it as `chess::Position`.
- Never write `using namespace std;` in a header: it changes the names in every file that includes the header. In a source file, prefer explicit names (`std::vector`), or a `using` declaration for one name (`using std::string_view;`).
- **Include what you use:** each file includes the headers for the names that it uses. Do not depend on an include that comes indirectly through another header.
- An **anonymous namespace** in a source file makes its names private to that file: `namespace { int helper(); }`.
- Private data members protect the invariants of a class. Public functions are the interface.

### 1.10 Tests from the first day

The course uses doctest (or the framework that you selected in phase 0):

```cpp
#include <doctest/doctest.h>

#include "calculator.hpp"

TEST_CASE("adds two positive numbers") {
    CHECK(add(2, 3) == 5);
}

TEST_CASE("rejects a division by zero") {
    const auto result = divide(1, 0);
    REQUIRE_FALSE(result.has_value());
    CHECK(result.error() == CalcError::division_by_zero);
}
```

- `CHECK` records a failure and continues. `REQUIRE` stops the test case: use it when the next lines need the condition (for example before `result.error()`).
- One file of the test executable contains `#define DOCTEST_CONFIG_IMPLEMENT_WITH_MAIN` before the include. The other test files include only the header.
- A test name says what the code does, not the name of the function: "rejects a division by zero", not "test_divide".
- Run one test with a filter: `./tests --test-case="*division*"` (doctest), or `ctest -R <name>` for a whole test executable.
- Write the test first when you can. Then you know what the function must do before you write it.

### 1.11 Undefined behavior: the basic rules

You saw undefined behavior in phase 0. These rules prevent most of it in phase 1 code:

| Rule | Example of UB |
|---|---|
| Initialize every variable | `int count; ++count;` |
| Check indexes, or do not use indexes | `v[v.size()]` |
| Do not let signed integers overflow | `int x = INT_MAX; ++x;` |
| Check `std::optional` and `std::expected` before `*` | `*parse_digit('x')` |
| Do not keep references, pointers, iterators, or views to an object after it ends or changes its storage | A `std::string_view` to a temporary `std::string`; a reference to a vector element across `push_back` |
| Do not divide by zero | `x / 0` for integers |
| Return a value from every non-`void` function | A missing `return` on one path |

Run your tests in the `dev` preset with the sanitizers. Phase 2 explains the lifetime rules in detail.

### 1.12 Names and style

C++ has no single official style. The standard library uses `snake_case` for everything. Many projects use `CamelCase` for types. Select one style for a project, write it in `.clang-format` and `.clang-tidy`, and use it everywhere. The course uses this style:

| Item | Style | Example |
|---|---|---|
| Types, concepts | `CamelCase` | `Position`, `MoveList` |
| Functions, variables, namespaces | `snake_case` | `legal_moves`, `side_to_move`, `chess` |
| Enumerators, constants | `snake_case` | `Color::white`, `max_moves` |
| Private data members | `snake_case_` with a trailing underscore | `width_` |
| Macros (avoid them) | `SCREAMING_SNAKE_CASE` | `CHESS_ASSERT` |

- Good names are the first design tool. A name says what a value means in the domain, not its type: `legal_moves`, not `vec2`.
- A function that returns `bool` starts with `is_`, `has_`, or `can_`: `is_in_check()`.
- Do not use names that start with an underscore and a capital letter, or that contain two underscores: the standard reserves them.

## Exercises

Make the project `labs/phase-1-basics/`, with the same configuration files as in phase 0. Each exercise is a subdirectory with a library, an executable (if the exercise has one), and tests. Write tests for every function. The project must build with the warning set, pass clang-tidy, and pass the tests under the sanitizers.

### Exercise 1.1: Temperature converter

Write `celsius_to_fahrenheit` and `fahrenheit_to_celsius`. Write a program that reads a value and a unit from the command line, for example `convert 100 C`. Test the freezing point, the boiling point, and -40. Use `std::from_chars` to parse the number, and print an error for invalid input.

### Exercise 1.2: FizzBuzz with `switch`

Write `std::string fizzbuzz(int n)`. Compute a small integer from `n % 3 == 0` and `n % 5 == 0`, and use one `switch` on it. Then write a second version with an `enum class` for the four cases. Which version is easier to read?

### Exercise 1.3: Word frequency (core)

1. Read a text file whose path is the first argument (use `std::ifstream`).
2. Count each word. Ignore case and punctuation (ASCII only).
3. Print the 10 most frequent words with their counts, sorted by count and then by word.
4. Test the counting function with a short text. The counting function must not read files: give it a `std::string_view`.

### Exercise 1.4: Shapes with `std::variant` (core)

1. Define `Circle`, `Rectangle`, and `Triangle` as structs, and `using Shape = std::variant<Circle, Rectangle, Triangle>;`.
2. Write `area` and `perimeter` with `std::visit`.
3. Write `std::optional<Triangle> make_triangle(double a, double b, double c)` that returns `std::nullopt` if the sides cannot make a triangle.
4. Add a fourth shape. Read the compiler errors. Which functions must you change?
5. Write a second version with an abstract base class `Shape` and virtual functions `area` and `perimeter`. Add a fifth shape to both versions. Add a new operation (`bounding_box`) to both versions. Which version is easier to change for each kind of change? (Phase 5 calls this the "expression problem".)

### Exercise 1.5: Calculator (core)

Write `std::expected<std::int64_t, CalcError> evaluate(std::string_view input)` for expressions with two numbers and one operator: `"3 + 4"`, `"10 / 2"`, `"-7 * 6"`.

- `CalcError` is an `enum class`: a missing number, an invalid number, an unknown operator, a division by zero, and an overflow.
- Detect overflow before it happens (check the operands against the limits in `<limits>`), because signed overflow is undefined behavior.
- Write one test for each error case, and tests for the limits (`INT64_MAX`, `INT64_MIN`).
- Write a loop in `main` that reads lines from the standard input and prints the result or the error.

### Exercise 1.6: A library class (core)

1. Write a class `Library` and a class `Book` in the namespace `library`. The data members are private.
2. Write public member functions to add a book, to borrow a book by its title, to return a book, and to list the available books.
3. A book that is borrowed cannot be borrowed again. Return a `std::expected` with a clear error.
4. In `main`, try to change a data member of `Book` directly. Read the compiler error. Explain why private members protect the rules of the library.
5. Mark every member function that does not change the object as `const`. Make a `const Library&` and call each function on it. Which calls compile?

### Exercise 1.7: Exercism

Do 10 exercises of the Exercism C++ track (exercism.org/tracks/cpp), in the order of the track. Do them outside the course repository. Write the exercises that were hard in your engineering notebook.

### Exercise 1.8: Vending machine (core)

Model a vending machine as a state machine.

1. States: `Idle`, `HasMoney { int cents; }`, `Dispensing { Product product; }`. Use `std::variant` for the state.
2. Events: `InsertCoin { int cents; }`, `Select { Product product; }`, `Cancel`, `TakeProduct`. Use `std::variant` for the event.
3. Write `std::pair<State, std::optional<Output>> next(const State& state, const Event& event)`. The output can be "return change" or "show an error".
4. Test every transition, including the events that are not valid in a state.

Compare this design with a class that has several `bool` data members (`has_money`, `is_dispensing`) and an `int`. Which design permits impossible combinations?

## Project: Chess engine, stage 0

See [../projects/chess-engine.md](../projects/chess-engine.md), stage 0.

## Done criteria

- [ ] I initialize every variable, and I can explain why brace initialization rejects narrowing.
- [ ] I can write classes with private data members, constructors that make valid objects, and `const` member functions.
- [ ] I can use `enum class` with `switch`, and `std::variant` with `std::visit`, and I know which one to select.
- [ ] I can use `std::optional` and `std::expected`, and I check them before I use the value.
- [ ] I can explain the difference between `std::string` and `std::string_view`, and when a `std::string_view` dangles.
- [ ] I can name five kinds of undefined behavior, and I know which tool finds each one.
- [ ] Every function in my labs has a test with a name that describes its behavior.
- [ ] My vending machine cannot be in an impossible state.
- [ ] Chess engine stage 0 is complete.

## Next

[Phase 2: Object lifetime and ownership](phase-2-ownership.md)
