# Phase 2: Object Lifetime and Ownership

**Time:** 3 weeks. 2 weeks if you know modern C++ or Rust well.
**Prerequisites:** Phase 1.
**Code:** `labs/2-ownership/`

## Goal

At the end of this phase, you can:

- Explain where an object lives (stack, heap, static storage) and when its lifetime ends.
- Use RAII for every resource, and explain why C++ needs no garbage collector.
- Explain value semantics, copies, and moves, and predict which special member function runs.
- Apply the rule of zero, and write the five special member functions correctly when a class manages a resource.
- Select between `std::unique_ptr`, `std::shared_ptr`, `std::weak_ptr`, references, and raw pointers.
- Select the correct parameter and return types for ownership.
- Find dangling references, iterator invalidation, and leaks, with the sanitizers and the compiler warnings.
- Explain the memory layout of a class: size, alignment, and padding.

## Reading

| Source | Part |
|---|---|
| learncpp.com | The chapters about references and pointers, dynamic allocation, move semantics and smart pointers, and the chapter "Object relationships" |
| Bjarne Stroustrup, *A Tour of C++*, 3rd edition | "Essential Operations", "Resource management" (in "Utilities") |
| Scott Meyers, *Effective Modern C++* | The chapters "Rvalue References, Move Semantics, and Perfect Forwarding" and "Smart Pointers" |
| The C++ Core Guidelines | Sections "R: Resource management", "C.ctor: Constructors, assignments, and destructors", and "F.call: Parameter passing" |
| Nicolai Josuttis, *C++ Move Semantics: The Complete Guide* | Optional, for depth |

## Topics

### 2.0 Memory basics (only if you need them)

Skip this topic if you know the stack and the heap from C, C++, or Rust.

- **The stack** holds the local variables of the functions that run now. Each call adds a frame; each return removes it. It is fast. The size of each variable is fixed at compile time.
- **The heap** (free store) holds data whose size or lifetime is not known at compile time: the buffer of a `std::vector`, the characters of a long `std::string`. A heap allocation is slower than a stack allocation.
- **Static storage** holds global variables and `static` variables. They live for the whole program.

```text
Stack (main)                       Heap
+--------------------------+       +---+---+---+
| v: std::vector<int>      |       | 1 | 2 | 3 |
|    data  ----------------+-----> +---+---+---+
|    size = 3              |
|    capacity = 3          |
+--------------------------+
```

The `std::vector` object is on the stack. Its elements are on the heap. When `v` ends, its destructor frees the heap buffer.

### 2.1 Object lifetime and storage duration

| Storage duration | Example | The lifetime ends |
|---|---|---|
| Automatic | A local variable | At the end of its block |
| Static | A global, or a `static` local | At the end of the program |
| Dynamic | An object that `std::make_unique` makes | When its owner deletes it (for a smart pointer: when the smart pointer ends) |
| Thread | A `thread_local` variable | At the end of the thread |

- **Temporaries** end at the end of the full expression: `std::string_view sv = std::string{"abc"};` makes a view to a string that ends at the semicolon. `sv` dangles.
- A temporary that is bound directly to a `const T&` (or `T&&`) local variable lives as long as the reference. This **lifetime extension** works only directly: it does not work through a function that returns a reference.
- Members are constructed in the order of their declaration, and destroyed in the reverse order. Local variables are destroyed in the reverse order of their construction.
- **Using an object after its lifetime ended is undefined behavior,** also if the memory still contains the old value.

### 2.2 RAII and destructors

**Resource acquisition is initialization (RAII):** an object takes a resource in its constructor and releases it in its destructor. The destructor runs automatically at the end of the lifetime, also when an exception leaves the scope.

```cpp
void save(const std::string& path, std::string_view text) {
    std::ofstream file{path};          // opens the file
    file << text;
    std::lock_guard lock{log_mutex};   // locks the mutex
    log("saved");
}                                      // unlocks the mutex, then closes the file
```

- Every resource has an owner: memory, files, sockets, locks, threads, database connections, GPU handles. The owner is an object with a destructor.
- With RAII, there is no `finally`, no `goto cleanup`, and no `defer`. The cleanup is in one place: the destructor.
- A destructor must not throw. If it throws during the unwinding of another exception, the program ends with `std::terminate`. Destructors are `noexcept` by default.
- C++ has no garbage collector because RAII releases memory and every other resource at a known point.

### 2.3 Value semantics and copies

- C++ objects are values. `Position b = a;` makes a new, independent object. A change to `b` does not change `a`.
- The **copy constructor** `T(const T&)` makes a new object from an existing one. The **copy assignment operator** `T& operator=(const T&)` replaces the value of an existing object.
- The standard containers copy all their elements. A copy of a `std::vector<Position>` with a million elements is expensive. Pass it by `const&` when you only read it.
- Value semantics make code easy to understand: no other part of the program can change your object through a hidden reference. Many C++ designs prefer values to shared objects (phase 5).

### 2.4 Move semantics

A **move** transfers the resources of an object to a new object, in place of a copy. For a `std::vector`, a move copies three pointers and leaves the source empty. A copy allocates a new buffer and copies all elements.

```cpp
std::vector<int> make_big();

std::vector<int> a = make_big();        // no copy: the result is moved or constructed in place
std::vector<int> b = a;                 // copy: a is still used later
std::vector<int> c = std::move(a);      // move: a is in a valid but unspecified state
```

- An **lvalue** has a name and an address (`a`). An **rvalue** is a temporary or a value that is about to end (`make_big()`). A move happens from rvalues.
- `std::move(x)` does not move anything. It is a cast to an rvalue reference (`T&&`). It says: "I do not need the value of `x` any more." The move constructor or the move assignment then does the work.
- After a move, a standard library object is in a **valid but unspecified state**. You can assign a new value to it or destroy it. Do not read its value.
- **Copy elision:** when a function returns a local object or a temporary, the compiler often makes the object directly in the place of the caller (return value optimization). Since C++17, this is guaranteed for temporaries. Do not write `return std::move(local);`: it can prevent the optimization.
- Mark the move constructor and move assignment `noexcept`. `std::vector` moves its elements on reallocation only if the move constructor is `noexcept`; otherwise it copies them, to keep its strong exception guarantee.

### 2.5 The rule of zero, three, and five

The five special member functions are the destructor, the copy constructor, the copy assignment operator, the move constructor, and the move assignment operator.

- **The rule of zero:** a class that does not manage a resource directly declares none of them. Its members (`std::string`, `std::vector`, `std::unique_ptr`) manage their resources, and the compiler generates correct functions. This is the normal case.
- **The rule of five:** a class that manages one resource directly declares all five (or deletes some of them). If you write a destructor, the generated copy operations are probably wrong.
- A class that manages a resource that cannot be copied (a file, a socket) is **move-only**: it deletes the copy operations and implements the move operations.

```cpp
#include <cstdio>
#include <utility>

// Owns one C file handle. Move-only.
class File {
public:
    File(const char* path, const char* mode) : handle_{std::fopen(path, mode)} {}
    ~File() {
        if (handle_ != nullptr) {
            std::fclose(handle_);
        }
    }

    File(const File&) = delete;
    File& operator=(const File&) = delete;

    File(File&& other) noexcept : handle_{std::exchange(other.handle_, nullptr)} {}
    File& operator=(File&& other) noexcept {
        if (this != &other) {
            if (handle_ != nullptr) {
                std::fclose(handle_);
            }
            handle_ = std::exchange(other.handle_, nullptr);
        }
        return *this;
    }

    [[nodiscard]] bool is_open() const { return handle_ != nullptr; }
    [[nodiscard]] std::FILE* get() const { return handle_; }

private:
    std::FILE* handle_;
};
```

- `std::exchange(a, b)` sets `a` to `b` and returns the old value of `a`. It is the usual tool in move operations.
- Often, `std::unique_ptr` with a custom deleter does the same job with less code (topic 2.7). Write your own class when the resource needs more than one cleanup call, or when the class has more behavior.

### 2.6 References, pointers, and views

| Form | Can be null | Can change what it refers to | Owns | Use |
|---|---|---|---|---|
| `T&` | No | No | No | A parameter that the function changes, or a member that refers to a longer-lived object |
| `const T&` | No | No | No | A read-only parameter of a large type |
| `T*` | Yes | Yes | **No** (in modern code) | An optional reference, or a reference that changes; a parent pointer in a tree |
| `std::unique_ptr<T>` | Yes | Yes | Yes, alone | A heap object with one owner |
| `std::shared_ptr<T>` | Yes | Yes | Yes, shared | A heap object with several owners |
| `std::string_view`, `std::span<T>` | (can be empty) | Yes | No | A read-only view (`span<const T>`) or a writable view of contiguous elements |

- In modern C++, a raw pointer `T*` never owns. If code has `new` and `delete`, change it to a smart pointer or a container.
- A reference, a pointer, an iterator, or a view **dangles** when the object that it refers to ends, or when the container moves its elements. Common causes:

  | Cause | Example |
  |---|---|
  | A reference to a local variable returned from a function | `const std::string& name() { std::string s = "x"; return s; }` |
  | A view of a temporary | `std::string_view sv = make_name();` (`make_name` returns `std::string`) |
  | Iterator invalidation | A reference to `v[0]`, then `v.push_back(x)` |
  | A lambda that captures a local by reference and runs later | A callback stored in an object that lives longer than the local (phase 3) |
  | A member reference or view to a constructor argument | A class that stores the `std::string_view` parameter of its constructor |

- Each container documents which operations invalidate which iterators and references. Look at the section "Iterator invalidation" on cppreference.com.

### 2.7 Smart pointers

- **`std::unique_ptr<T>`:** one owner. It deletes the object in its destructor. It is move-only, and it costs nothing compared with a raw pointer. Make it with `std::make_unique<T>(args...)`.
- **`std::shared_ptr<T>`:** several owners. A reference count in a control block counts the owners. The last owner deletes the object. Make it with `std::make_shared<T>(args...)`. It costs a control block and atomic operations on each copy. It also makes the program harder to understand: who keeps the object alive?
- **`std::weak_ptr<T>`:** refers to an object of a `std::shared_ptr` without ownership. `lock()` gives a `std::shared_ptr` if the object still exists. Use it to break cycles: two objects that own each other with `std::shared_ptr` never end (a leak).
- **Custom deleters:** `std::unique_ptr<std::FILE, decltype(&std::fclose)> f{std::fopen(path, "r"), &std::fclose};` manages a C resource.
- **Rules:**
  - Use a value or a container first. Use `std::unique_ptr` when you need a heap object (polymorphism, a large object, an object with a stable address, an optional member).
  - Use `std::shared_ptr` only when several parts of the program really share the lifetime, and no single owner is possible. Write the reason in a comment.
  - Pass a smart pointer to a function only when the function takes part in the ownership. If it only uses the object, pass `T&` or `T*`.

### 2.8 Ownership in function signatures

| Intent | Parameter type | Example |
|---|---|---|
| Read a small value | `T` | `void move_piece(Square from, Square to)` |
| Read a large value | `const T&` | `int evaluate(const Position& pos)` |
| Read a sequence of characters or elements | `std::string_view`, `std::span<const T>` | `parse_fen(std::string_view text)` |
| Change the caller's object | `T&` | `void make_move(Position& pos, Move m)` |
| Keep a copy (a "sink") | `T` and move it inside | `Game(std::string name) : name_{std::move(name)} {}` |
| Take over a heap object | `std::unique_ptr<T>` | `void set_evaluator(std::unique_ptr<Evaluator> e)` |
| Share the ownership | `std::shared_ptr<T>` | Rare |
| Maybe an object | `T*` (can be null) or `std::optional<T>` (a value) | `void draw(const Theme* theme)` |

| Intent | Return type |
|---|---|
| A new value | `T` (the compiler moves or elides) |
| Maybe a value | `std::optional<T>` |
| A value or an error | `std::expected<T, E>` |
| Access to a part of an object that lives longer than the call | `const T&` or a view; document the lifetime |
| A new heap object | `std::unique_ptr<T>` |

- Do not use output parameters (`void parse(std::string_view text, Position& out)`). Return the value.

### 2.9 `const` correctness

- Mark every variable, parameter by reference, and member function `const` when it does not change.
- A `const` object can call only `const` member functions. If a function forgets `const`, the callers cannot use it with `const` objects.
- `const` in a signature is a promise to the caller and a check by the compiler.
- `mutable` permits a change of a member in a `const` function. Use it only for data that is not part of the visible value (a cache, a mutex).

### 2.10 Find lifetime errors

- **Compiler warnings:** GCC 13 and newer has `-Wdangling-reference`. Clang warns about some returns of references to locals, and has `[[clang::lifetimebound]]` to mark parameters whose lifetime the result depends on. MSVC has the lifetime checks of its code analysis (`/analyze`). They find some cases, not all.
- **AddressSanitizer:** finds the use of freed heap memory (`heap-use-after-free`), the use of a stack frame after the return (`stack-use-after-return`, when enabled with the option `detect_stack_use_after_return=1` in `ASAN_OPTIONS`), and out-of-range access.
- **LeakSanitizer** (part of ASan on Linux): finds memory that is never freed, for example a cycle of `std::shared_ptr`.
- **Debug containers:** the standard library checks of `_GLIBCXX_ASSERTIONS`, the libc++ hardening mode, and MSVC checked iterators find out-of-range indexes and some invalid iterators.
- **Review:** the checklist in [../topics/code-review-checklist.md](../topics/code-review-checklist.md), sections 1 and 2.

### 2.11 Memory layout

- `sizeof(T)` is the size of an object in bytes. `alignof(T)` is its alignment: its address must be a multiple of this number.
- The compiler adds **padding** between members to keep each member aligned. The order of the members changes the size:

  ```cpp
  struct A { char c; double d; char e; };   // usually 24 bytes
  struct B { double d; char c; char e; };   // usually 16 bytes
  ```

- Contiguous memory is fast: the CPU loads memory in cache lines (usually 64 bytes). A `std::vector` of values is usually much faster to iterate than a `std::list` or a vector of pointers, even when the theory says the same complexity.
- A chess position is copied, compared, and hashed millions of times per second in a search. Its size and layout matter (phase 8).

## Exercises

Make the project `labs/2-ownership/`. Run all exercises in the `dev` preset with the sanitizers.

### Exercise 2.1: Lifetime tracer (core)

1. Write a class `Tracer` that prints a line in each special member function and in its constructor from a name: `Tracer("a") constructed`, `copy of a`, `move of a`, `a destroyed`.
2. For each fragment, **predict the output first**, then run it. Explain each difference between your prediction and the output.
   - A local `Tracer` in a block.
   - Two locals and a member: the order of destruction.
   - `Tracer b = a;`, `Tracer c = std::move(a);`, `b = c;`.
   - A function that returns a local `Tracer`.
   - `std::vector<Tracer>` with three `push_back` calls (look at the moves or copies on reallocation). Then call `reserve(3)` first. Then use `emplace_back`.
   - Remove the `noexcept` from the move constructor. Run the vector fragment again. What changes, and why?

### Exercise 2.2: Find the dangling (core)

For each fragment, say whether it has undefined behavior and why. Then run it under the sanitizers. Fix each one.

```cpp
std::string_view first_word(std::string text) {
    return std::string_view{text}.substr(0, text.find(' '));
}
```

```cpp
std::vector<int> v{1, 2, 3};
int& first = v.front();
v.push_back(4);
first = 10;
```

```cpp
const std::string& longest(const std::string& a, const std::string& b) {
    return a.size() >= b.size() ? a : b;
}
const std::string& r = longest("short", std::string{"a longer text"});
std::println("{}", r);
```

```cpp
std::map<std::string, int> scores{{"ada", 3}};
const int* p = &scores["ada"];
scores["bob"] = 5;
std::println("{}", *p);
```

The last fragment is correct. Why? (Hint: read "Iterator invalidation" for `std::map` on cppreference.com.)

### Exercise 2.3: RAII wrapper for a C API (core)

1. Write the class `File` from topic 2.5 with a function `std::optional<std::string> read_line()`.
2. Write tests: open, read, move to a second object, and check that the file is closed exactly once (count the closes with a test hook, or use a fake C function).
3. Write a second version with `std::unique_ptr` and a custom deleter. Compare the amount of code.
4. Make the constructor fail cleanly when the file does not exist. Use a factory function `static std::expected<File, std::error_code> open(...)` with a private constructor.

### Exercise 2.4: A small vector (core)

Write `IntBuffer`, a growable array of `int` that manages its own memory with `std::unique_ptr<int[]>` (no `std::vector` inside).

1. `push_back`, `size`, `capacity`, `operator[]`, and a checked `at`.
2. The copy constructor (a deep copy), the copy assignment, the move constructor, and the move assignment. Make the moves `noexcept`.
3. Tests for each special member function, also for self-assignment (`b = b;`) and for a move into itself.
4. Implement the copy assignment with the copy-and-swap idiom. Explain why it gives the strong exception guarantee.
5. All tests pass under AddressSanitizer with no leaks.

### Exercise 2.5: Trees and graphs

1. Write a tree where each node owns its children with `std::vector<std::unique_ptr<Node>>`, and has a raw pointer `Node* parent` to its parent. Write `path_to_root`. Why is a raw pointer correct for the parent?
2. Write a graph of `Person` objects where friends refer to each other with `std::shared_ptr`. Make two friends. Run the program under LeakSanitizer (Linux), or count the destructor calls. What happens?
3. Change the friend links to `std::weak_ptr`. Check that all objects end.

### Exercise 2.6: Signatures (core)

Rewrite the signatures of these functions with the table in topic 2.8. Use the `Tracer` from exercise 2.1 to count the copies before and after.

```cpp
int count_words(std::string text);
void add_tag(std::vector<std::string>* tags, std::string* tag);
std::vector<int>* make_scores();
void print_all(std::vector<Tracer> items);
class Player { public: Player(const std::string& name) : name_(name) {} private: std::string name_; };
```

### Exercise 2.7: Undo stack

Write a text editor buffer with `insert(position, text)`, `erase(position, length)`, and `undo()`. Store the commands as values in a `std::vector<std::variant<...>>`. Do not use pointers. Test a sequence of edits and undos.

### Exercise 2.8: Sizes

1. Print `sizeof` and `alignof` of `int`, `double`, `std::string`, `std::string_view`, `std::vector<int>`, `std::optional<int>`, `std::unique_ptr<int>`, `std::shared_ptr<int>`, and `std::variant<int, double>`. Compare the results on two compilers if you can.
2. Write a struct with five members of different types. Reorder the members to make it as small as possible. Add a `static_assert` for the size.
3. Explain the size of `std::optional<int>` and of `std::string` (search for "small string optimization").

## Project: Chess engine

No new stage in this phase. Review your stage 0 code with this phase:

- Are the parameters correct (topic 2.8)? Is `Position` passed by `const&` where a function only reads it?
- Is every member function that does not change the object `const`?
- Does any class store a `std::string_view` or a reference? What is the lifetime of the source?
- Is `Position` a value type with the rule of zero?

## Done criteria

- [ ] I can explain RAII, and why C++ needs no garbage collector.
- [ ] I can predict which special member function runs in a copy, a move, a return, and a `std::vector` reallocation.
- [ ] I can explain what `std::move` does and what it does not do.
- [ ] My classes follow the rule of zero, except one resource class that follows the rule of five and passes its tests under AddressSanitizer.
- [ ] I can select between a value, a reference, a raw pointer, `std::unique_ptr`, and `std::shared_ptr`, and give the reason.
- [ ] I can find five causes of dangling references, and the tool that finds each one.
- [ ] I can explain padding, and reduce the size of a struct.

## Next

[Phase 3: Templates, concepts, lambdas, and ranges](phase-3-templates.md)
