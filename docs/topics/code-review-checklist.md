# Code Review Checklist

**Phase:** 5–8. The mentor also uses it for every code review.
**Related:** [phase 5](../phases/phase-5-software-design.md), [phase 8, topic 8.7](../phases/phase-8-professional-practices.md), [mentoring](../mentor/mentoring.md)

## Summary

This checklist helps you review C++ code in a fixed order: from the problems that cost the most to the problems that cost the least. Use it for your own code before you ask for a review, and for the code of other people.

## Explanation

### Before the review

- [ ] The change has a clear purpose. The description says why it is necessary.
- [ ] The change is small enough to review (fewer than 400 changed lines). If it is not, ask the author to split it.
- [ ] The build has no warnings with the warning set of the course. clang-format and clang-tidy report nothing. The tests pass, also under the sanitizers. Do not review what a tool can check.

### 1. Correctness and undefined behavior

- [ ] The code does what the description says, also for the edge cases: empty input, one item, the maximum value, negative values, Unicode text.
- [ ] No dangling references, pointers, views, or iterators: no `std::string_view` or `std::span` to a temporary, no reference to a local returned from a function, no lambda that captures a local by reference and runs later.
- [ ] No iterator invalidation: no `push_back`, `insert`, or `erase` on a container while a loop iterates over it.
- [ ] Signed integer arithmetic cannot overflow. Conversions cannot lose data, or the loss is intended and explicit (`static_cast`).
- [ ] Every variable is initialized before its use.
- [ ] Index access is in range, or uses a checked access. No raw arrays where `std::array`, `std::vector`, or `std::span` works.
- [ ] Each `std::expected` and `std::optional` is checked before `*` or `.value()` in normal operation.
- [ ] No exception escapes a destructor, a `noexcept` function, or the function of a thread.
- [ ] **Concurrency:** shared data is protected by one mutex, or is atomic, or is not shared. Locks are taken in a fixed order, or together with `std::scoped_lock`. No lock is held during slow work or I/O. A condition variable is used with a predicate. Threads are joined or stopped before the data that they use ends.
- [ ] **User interface:** no slow work on the UI thread. UI objects are used only on the UI thread.
- [ ] **Network:** reads and writes have limits and timeouts. Asynchronous operations keep their buffers and objects alive until they complete.

### 2. Resources and ownership

- [ ] Every resource (memory, file, socket, lock, database handle) has an owner that releases it in its destructor (RAII).
- [ ] No `new` and `delete` in application code. `std::make_unique` in place of `new`.
- [ ] The rule of zero: a class that does not manage a resource directly declares no destructor, copy, or move operations. A class that does manage one declares all five, or deletes the copy operations.
- [ ] `std::shared_ptr` only when the ownership is really shared, with a comment that says why. No cycles of `std::shared_ptr`.
- [ ] Raw pointers and references do not own. A pointer parameter that can be null says so; else use a reference.
- [ ] Moved-from objects are not used, except to assign a new value or to destroy them.
- [ ] Exception safety: after an exception, no resource leaks, and the object is in a valid state.

### 3. Tests

- [ ] New behavior has tests. A fixed defect has a test that fails without the fix.
- [ ] Each test can fail: it checks the result, not only that the code runs.
- [ ] The test names describe the behavior.
- [ ] The tests do not depend on the real time, the network, random values without a fixed seed, or the order of other tests.
- [ ] The edge cases from section 1 are tested.

### 4. Design

- [ ] Each class, function, and library has one responsibility. The names say what it is.
- [ ] The dependencies point in the correct direction: the core does not depend on adapters, frameworks, or I/O. The build files prove it.
- [ ] The types make invalid states impossible: `enum class` in place of `bool` flags and strings, strong types in place of `int` and `std::string`, `std::variant` in place of a type code with unused fields.
- [ ] The public interface is as small as possible. Data members are private when the class has an invariant.
- [ ] The choice of polymorphism fits the problem: virtual functions for run-time variation, templates and concepts for compile-time variation, `std::variant` for a closed set of alternatives.
- [ ] No duplicated knowledge. But no abstraction with only one use and no test that needs it (YAGNI).
- [ ] Derived classes keep the contract of the base class (Liskov). A base class with virtual functions has a public virtual destructor, or a protected non-virtual one.
- [ ] Interfaces are small and focused (interface segregation).
- [ ] Errors use the course rules: `std::expected` for expected errors, exceptions for exceptional errors, `assert` for bugs. An error is not both logged and returned.
- [ ] In the hot path, an abstraction does not add a cost that a measurement shows to be important.

### 5. Idioms

- [ ] Parameters: by value for cheap types and for values that the function keeps (then move); `const&` for large types that the function only reads; `std::string_view` and `std::span` for read-only sequences; `&` only for output that cannot be a return value.
- [ ] `const` everywhere it is correct: variables, member functions, parameters by reference.
- [ ] Algorithms and ranges where they make the code clearer. Loops where the logic has many branches.
- [ ] `auto` where the type is clear from the right side or is not important. An explicit type where it documents the meaning.
- [ ] No C-style casts. No macros for constants or functions: `constexpr` and functions.
- [ ] `[[nodiscard]]` on functions whose result must not be ignored (for example a function that returns `std::expected`).
- [ ] Headers include what they use, and have no `using namespace`.

### 6. Security and data

- [ ] No secrets, tokens, or real personal data in the code, the tests, or the logs.
- [ ] Input from outside (files, the network, the command line, the UCI protocol) is validated at the boundary, with limits on sizes and lengths.
- [ ] SQL uses bound parameters, never string concatenation.
- [ ] New dependencies are listed in the dependency list, pinned, checked with a hash, and have a compatible license.
- [ ] Code with raw memory, `reinterpret_cast`, or intrinsics has a comment that explains why it is correct, and the tests run under the sanitizers.

### 7. Readability and documentation

- [ ] A reader understands the code without the author. Comments explain why, not what.
- [ ] Public functions and types have a comment: what they do, their preconditions, and how they report errors.
- [ ] The README, the ADRs, and the changelog are updated if the change affects them.

### How to write the comments

- Write about the code, not about the person: "This function has UB for an empty vector", not "You forgot the empty vector".
- Explain why: the problem that the code causes, not only the rule.
- Mark each comment as **blocking** (must change before the merge) or **suggestion** (the author decides).
- Name one or two things that are done well.
- Ask questions when you are not sure: "Can `moves` be empty here?"

## Example

A review comment:

> **Blocking.** `src/fen.cpp:42`: `parse_fen` stores the `std::string_view` argument in `Position::source_`. The caller in `uci.cpp:88` passes a temporary `std::string`, so the view dangles after the call. The tests pass by chance; AddressSanitizer reports `heap-use-after-free` with the test "parses the start position" when the string is longer than the small-string buffer. Store a `std::string`, or do not store the text at all.

## Common mistakes

| Mistake | Result | Fix |
|---|---|---|
| The reviewer discusses the format and the lint findings | Time is lost. The important problems are not found. | Let clang-format and clang-tidy do this in CI. |
| The review starts with names and style | The reviewer is tired before the correctness and design checks | Use the order of this checklist. |
| "It works on my computer, so it is correct" | Undefined behavior goes to production | Run the tests under the sanitizers, and check the rules in section 1. |
| The change is too large to review | The reviewer approves without real checks | Split the change into small pull requests. |
| All comments look equally important | The author does not know what must change | Mark comments as blocking or suggestion. |

## Sources

- Google, "Code Review Developer Guide" (google.github.io/eng-practices)
- Titus Winters, Tom Manshreck, and Hyrum Wright, *Software Engineering at Google*, the chapter about code review
- Bjarne Stroustrup and Herb Sutter, C++ Core Guidelines (isocpp.github.io/CppCoreGuidelines)
