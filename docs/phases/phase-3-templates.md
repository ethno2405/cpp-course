# Phase 3: Templates, Concepts, Lambdas, and Ranges

**Time:** 3–4 weeks.
**Prerequisites:** Phase 2.
**Code:** `labs/phase-3-templates/`

## Goal

At the end of this phase, you can:

- Write function templates and class templates, and constrain them with concepts.
- Select between static polymorphism (templates, concepts), dynamic polymorphism (virtual functions), and closed polymorphism (`std::variant`).
- Write classes with operators and comparisons that keep their normal meaning.
- Write lambdas with correct captures, and find dangling captures.
- Use the standard algorithms and ranges, and write your own range that works with them.
- Compute tables at compile time with `constexpr`, and check them with `static_assert`.
- Read a long template error and find its cause.

## Reading

| Source | Part |
|---|---|
| Bjarne Stroustrup, *A Tour of C++*, 3rd edition | "Templates", "Concepts and Generic Programming", "Algorithms", "Ranges" |
| learncpp.com | The chapters about function templates, class templates, lambdas, iterators, and algorithms |
| cppreference.com | "Constraints and concepts", "Ranges library", "Algorithms library", "Lambda expressions" |
| Nicolai Josuttis, *C++20: The Complete Guide* | The chapters about concepts and ranges (optional, for depth) |
| The C++ Core Guidelines | Section "T: Templates and generic programming": the rules T.10–T.26 about concepts |
| Chess Programming Wiki | "Board Representation", "Mailbox", "Move Generation", "Perft" |

## Topics

### 3.1 Function templates

```cpp
template <typename T>
T largest(const std::vector<T>& values) {
    T result = values.front();
    for (const T& v : values) {
        if (result < v) {
            result = v;
        }
    }
    return result;
}

int a = largest(std::vector{3, 1, 4});            // T is int
std::string b = largest(std::vector<std::string>{"x", "y"});
```

- A template is not code. The compiler makes code (an **instantiation**) for each set of template arguments that the program uses.
- The compiler deduces the template arguments from the function arguments. You can also give them: `largest<double>(...)`.
- Templates are usually defined completely in headers: the compiler needs the definition to make an instantiation in each translation unit.
- An error in a template often shows only when the compiler instantiates it with a type that does not fit. Concepts (topic 3.3) move the error to the call.

### 3.2 Class templates

```cpp
template <typename T, std::size_t Capacity>
class FixedVector {
public:
    void push_back(const T& value);
    [[nodiscard]] std::size_t size() const { return size_; }
    // ...
private:
    std::array<T, Capacity> items_{};
    std::size_t size_ = 0;
};

FixedVector<Move, 256> moves;
```

- Template parameters can be types (`typename T`) or values (`std::size_t Capacity`).
- **Class template argument deduction (CTAD):** `std::vector v{1, 2, 3};` deduces `std::vector<int>`. `std::pair p{1, 2.0};` deduces `std::pair<int, double>`.
- Member functions of a class template are instantiated only when the program uses them.

### 3.3 Concepts

A **concept** is a named set of requirements on a template parameter, checked at compile time.

```cpp
#include <concepts>

template <typename T>
concept Scorable = requires(const T& t) {
    { t.score() } -> std::convertible_to<int>;
};

// Three equivalent forms:
template <Scorable T> int total(const std::vector<T>& items);
template <typename T> requires Scorable<T> int total(const std::vector<T>& items);
int total(const std::vector<Scorable auto>& items);   // abbreviated form
```

- The standard library has many concepts: `std::integral`, `std::floating_point`, `std::same_as`, `std::convertible_to`, `std::equality_comparable`, `std::totally_ordered`, `std::invocable`, `std::predicate`, and the range concepts (`std::ranges::range`, `std::ranges::random_access_range`).
- A type satisfies a concept if it has the required operations. The type does not declare it (unlike a Java interface or a Rust trait).
- When a type does not satisfy a concept, the error says which requirement failed, at the call.
- Concepts also select overloads: the most constrained overload wins.
- Test your concepts with `static_assert(Scorable<MyType>);` and `static_assert(!Scorable<int>);`.

### 3.4 Static, dynamic, and closed polymorphism

| Form | Mechanism | The set of types | Cost | Use |
|---|---|---|---|---|
| Dynamic: virtual functions | An abstract base class; a vtable call at run time | Open: new types can be added in other libraries | An indirect call, a heap object or a reference, no inlining | Plugins, ports in an architecture (phase 5), behavior that changes at run time |
| Static: templates and concepts | One instantiation for each type at compile time | Open at compile time | No call cost; inlining; more code and longer compile times; the type is part of the type of the user | Algorithms, containers, the hot path |
| Closed: `std::variant` and `std::visit` | A tag and a jump | Closed: fixed in one place | Small; no heap | A fixed set of alternatives with different data (messages, states, shapes) |
| Type erasure: `std::function`, your own wrapper | A hidden virtual call inside a value type | Open | Like virtual functions, often with a heap allocation | Callbacks; value semantics with run-time polymorphism |

Virtual functions:

```cpp
class Evaluator {
public:
    virtual ~Evaluator() = default;
    [[nodiscard]] virtual int evaluate(const Position& pos) const = 0;
};

class MaterialEvaluator final : public Evaluator {
public:
    [[nodiscard]] int evaluate(const Position& pos) const override;
};
```

- A class with virtual functions has a public virtual destructor (or a protected non-virtual one). Otherwise, the deletion through a base pointer is undefined behavior.
- Write `override` on every function that overrides. Then the compiler checks the signature. `final` prevents more overrides and helps the compiler to remove the virtual call.
- Do not call virtual functions in constructors and destructors: they call the version of the current class, not of the derived class.

### 3.5 Operators and comparisons

- Overload operators only when the meaning is the normal one: `+` adds, `==` compares, `[]` indexes. Do not use `+` to "add a player to a team".
- **The three-way comparison** `<=>` (C++20) gives `<`, `<=`, `>`, and `>=` from one function. With `= default`, it compares the members in the order of their declaration:

  ```cpp
  struct Version {
      int major = 0;
      int minor = 0;
      int patch = 0;
      auto operator<=>(const Version&) const = default;   // also gives ==
  };
  ```

- `operator<=>` returns `std::strong_ordering`, `std::weak_ordering`, or `std::partial_ordering`. `double` gives `std::partial_ordering`, because NaN is not ordered.
- To print your type with `std::format` and `std::println`, specialize `std::formatter` for it. Exercise 3.2 shows how.

### 3.6 Lambdas

```cpp
int limit = 10;
auto is_small = [limit](int x) { return x < limit; };      // capture by value
auto count_up = [&counter]() { ++counter; };               // capture by reference
auto make_id = [next = 0]() mutable { return next++; };     // init capture, own state
auto twice = [](auto x) { return x + x; };                  // generic lambda
```

- A lambda is an object of a class that the compiler makes, with an `operator()`. The captures are its data members.
- **Capture by value** copies the variable when the lambda is made. **Capture by reference** stores a reference: if the lambda runs after the variable ended, the reference dangles. This is a common error with callbacks and threads.
- Do not use `[&]` or `[=]` for lambdas that leave the scope (stored callbacks, threads). Name each capture.
- `[=]` in a member function captures `this` (a pointer), not a copy of the object. Write `[this]` or `[*this]` to say what you mean.
- `std::function<int(int)>` holds any callable object with the given signature. It costs an indirect call and maybe a heap allocation. Use a template parameter (`std::invocable<int> auto f`) when the callable is used only during the call.

### 3.7 Iterators and algorithms

- An **iterator** points to an element of a range. The iterator categories say what an iterator can do: input, forward, bidirectional, random access, contiguous. `std::vector` has contiguous iterators; `std::list` has bidirectional iterators.
- The `<algorithm>` and `<numeric>` headers have about 100 algorithms: `find`, `count_if`, `sort`, `stable_sort`, `partition`, `min_element`, `transform`, `accumulate`, `any_of`, and more. Prefer an algorithm with a clear name to a hand-written loop.
- Use the range versions in `std::ranges` (C++20): `std::ranges::sort(v);` in place of `std::sort(v.begin(), v.end());`. They check the concepts, and they support **projections**: `std::ranges::sort(players, {}, &Player::score);` sorts by the score.
- To remove elements from a container: `std::erase_if(v, predicate);` (C++20).

### 3.8 Ranges and views

```cpp
#include <ranges>

std::vector<int> scores{70, 95, 40, 88, 100};
auto passed = scores
            | std::views::filter([](int s) { return s >= 50; })
            | std::views::transform([](int s) { return s / 10; });
std::vector<int> grades = passed | std::ranges::to<std::vector>();   // C++23
```

- A **view** is a lazy range: it computes the elements when you iterate. It does not own the elements. A view of a container dangles when the container ends.
- Common views: `std::views::filter`, `transform`, `take`, `drop`, `reverse`, `iota` (a sequence of numbers), `split`, `keys`, `values`, `join`.
- `std::ranges::to<Container>()` (C++23) makes a container from a range.
- Some C++23 views (`zip`, `enumerate`, `chunk`, `slide`) are not in all supported compilers yet. Check the support table in [../software-setup.md](../software-setup.md) before you use them.
- Do not store a view of a temporary: `auto v = make_vector() | std::views::filter(f);` does not compile for a temporary in most cases (the library protects you), but views of `std::string_view` and other borrowed ranges can still dangle.

### 3.9 Compile-time computation

- A `constexpr` function can run at compile time when its arguments are constants, and at run time otherwise. A `consteval` function must run at compile time.
- A `constexpr` variable must be computed at compile time:

  ```cpp
  #include <array>
  #include <cstdint>

  constexpr std::array<std::uint64_t, 64> make_knight_attacks() {
      std::array<std::uint64_t, 64> table{};
      struct Jump { int file; int rank; };
      constexpr std::array<Jump, 8> jumps{{{1, 2}, {2, 1}, {2, -1}, {1, -2},
                                           {-1, -2}, {-2, -1}, {-2, 1}, {-1, 2}}};
      for (int sq = 0; sq < 64; ++sq) {
          for (const Jump& jump : jumps) {
              const int file = sq % 8 + jump.file;
              const int rank = sq / 8 + jump.rank;
              if (file >= 0 && file < 8 && rank >= 0 && rank < 8) {
                  table[static_cast<std::size_t>(sq)] |= std::uint64_t{1} << (rank * 8 + file);
              }
          }
      }
      return table;
  }

  constexpr auto knight_attacks = make_knight_attacks();
  static_assert(knight_attacks[0] == ((std::uint64_t{1} << 10) | (std::uint64_t{1} << 17)));  // a1: c2, b3
  ```

- `static_assert(condition, "message")` checks a condition at compile time. Undefined behavior in a constant expression is a compile error, so `constexpr` evaluation also finds bugs.
- `if constexpr (condition)` selects a branch at compile time. The other branch is not instantiated. Use it in templates.

### 3.10 Generic API design

- Make a function generic only when you have two or more real types for it, or when it is a general algorithm. A template with one use adds compile time and complexity.
- Constrain every template parameter with a concept. Use the standard concepts when they fit.
- Accept the weakest requirement that the function needs: a function that only iterates should take a `std::ranges::input_range`, not a `std::vector`.
- Put the template in a header, and keep the header small. Move the non-template parts into a source file.
- Templates in the hot path are fast, but each instantiation adds code. Measure before you make code generic for speed.

### 3.11 Deducing `this` and CRTP

- **Deducing `this`** (C++23) makes the object parameter explicit: `void f(this Self&& self)`. One function template then handles `const`, non-`const`, lvalue, and rvalue objects. It also replaces most uses of CRTP.
- **CRTP** (the curiously recurring template pattern): `class Derived : public Base<Derived>`. The base calls functions of the derived class at compile time. You see it in older code and libraries. Prefer concepts or deducing `this` in new code.

### 3.12 The preprocessor

- Use the preprocessor only for: `#include`, `#pragma once`, and conditional compilation for platforms (`#ifdef _WIN32`).
- Replace macros with language features: constants with `constexpr`, function macros with functions or templates, `__FILE__` and `__LINE__` with `std::source_location`.
- Macros do not respect namespaces or scopes, and they can evaluate an argument two times (`MAX(i++, j)`).

## Exercises

Make the project `labs/phase-3-templates/`.

### Exercise 3.1: Static and dynamic dispatch (core)

1. Write an abstract class `Shape` with `area()` and two implementations. Write `double total_area(const std::vector<std::unique_ptr<Shape>>& shapes)`.
2. Write a concept `HasArea` and a template `double total_area_of(const std::vector<T>& shapes)` for one concrete type.
3. Write a third version with `std::variant`.
4. Make 1 million shapes of each version. Measure the time of `total_area` in a release build (use `std::chrono::steady_clock`). Explain the differences. Can the template version hold different shape types in one vector?

### Exercise 3.2: A value type with comparisons and formatting (core)

1. Write a `Version` type for semantic versions (`MAJOR.MINOR.PATCH`) with a parse function that returns `std::expected`.
2. Use `operator<=>` with `= default`. Test that `1.2.10 > 1.2.9`.
3. Specialize `std::formatter<Version>` so that `std::println("{}", v)` prints `1.2.10`. (Inherit from `std::formatter<std::string_view>`, or write `parse` and `format`; see the `std::formatter` page on cppreference.com.)
4. Sort a list of versions with `std::ranges::sort`, and find the newest with `std::ranges::max`.

### Exercise 3.3: A fixed-capacity container (core)

This container becomes the move list of the chess engine.

1. Write `FixedVector<T, Capacity>` with `push_back`, `size`, `empty`, `operator[]`, `begin`, `end`, and `clear`. Use `std::array<T, Capacity>` for the storage. `push_back` on a full container is a bug: use `assert`.
2. Make it a range: `static_assert(std::ranges::random_access_range<FixedVector<int, 8>>);` and `static_assert(std::ranges::contiguous_range<FixedVector<int, 8>>);`.
3. Test it with a range-based `for` loop, `std::ranges::find`, `std::ranges::count_if`, and `std::ranges::sort`.
4. Constrain `T` with a concept: which operations must `T` have? (Hint: `std::array` default-constructs all elements.)

### Exercise 3.4: Log analysis with ranges (core)

Generate a log file with 10 000 lines in the format `2026-10-22T10:15:00 LEVEL component message`. Use ranges and algorithms, not raw loops:

1. Count the lines of each level.
2. Find the 5 components with the most errors.
3. Find the first error after a given time.
4. Write each function for a `std::ranges::input_range` of `std::string_view` lines, so that the tests do not need files.

### Exercise 3.5: Your own range (core)

A bitboard is a `std::uint64_t` where each bit is a square. Write a range `SetBits` that iterates over the indexes of the set bits of a `std::uint64_t`, from the lowest to the highest.

1. Write the iterator: `operator*` returns `std::countr_zero(bits)`, `operator++` clears the lowest set bit (`bits &= bits - 1`).
2. Use a sentinel for the end, or compare with an iterator for `bits == 0`.
3. `static_assert(std::ranges::forward_range<SetBits>);`
4. Test: `SetBits{0b1010'0001}` gives 0, 5, 7. Use it with `std::ranges::to<std::vector>()`.

### Exercise 3.6: Event dispatcher with lambdas

1. Write a `Dispatcher` that stores callbacks (`std::function<void(const Event&)>`) for each event type, and calls them on `publish`.
2. Register a lambda that captures a local by reference, end the scope of the local, and publish an event. Run it under AddressSanitizer. Read the report.
3. Fix it: capture by value, or return a subscription object that removes the callback in its destructor (RAII).

### Exercise 3.7: Compile-time tables (core)

1. Write the knight table from topic 3.9 and a king table with `constexpr` functions.
2. Add `static_assert` checks for the corner squares and one center square of each table.
3. Make a mistake in the table function (for example, forget the file check). What happens at compile time? Why does `constexpr` evaluation find it?

### Exercise 3.8: Read a template error

1. Write a function template `print_sorted(std::vector<T> v)` that sorts and prints. Call it with a `std::vector<std::complex<double>>`. Read the error.
2. Add a concept `std::totally_ordered<T>` to the template. Call it again. Compare the errors.
3. Write the steps that you use to read a long template error in your notebook.

## Project: Chess engine, stage 1

See [../projects/chess-engine.md](../projects/chess-engine.md), stage 1.

## Done criteria

- [ ] I can write function and class templates, and constrain them with standard and own concepts.
- [ ] I can select between virtual functions, templates, `std::variant`, and type erasure for a problem, and give the cost of each.
- [ ] I can write `operator<=>` and a `std::formatter` for my type.
- [ ] I can explain when a lambda capture dangles, and how to prevent it.
- [ ] I can write a pipeline with ranges, and my own type works with the range algorithms.
- [ ] I can compute a table at compile time and check it with `static_assert`.
- [ ] I can read a long template error and find the line in my code that causes it.
- [ ] Chess engine stage 1 is complete: perft is correct for the reference positions.

## Next

[Phase 4: Errors, libraries, and API design](phase-4-errors-apis.md)
