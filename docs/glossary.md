# Glossary

Add a term to this list when you find it for the first time.

| Term | Meaning |
|---|---|
| ABI | Application binary interface. The rules for how compiled code calls other compiled code: the layout of types, the names of symbols, the calling convention. Two libraries with different ABIs cannot be linked together safely. |
| ADR | Architecture decision record. A short document that records one important design decision, its context, and its consequences. |
| Adapter | In a hexagonal architecture: code that connects the core to a technology. It implements a port (a database store) or calls the core (a CLI, an HTTP handler, a GUI). |
| Aggregate | In domain modeling: a group of objects with one root object that protects the invariants of the group. In the C++ standard, "aggregate" also means a class with no user-declared constructors, which you can initialize with braces. |
| Alpha-beta pruning | A search method for two-player games. It skips moves that cannot change the result of a minimax search. |
| API | Application programming interface. The functions and types that one piece of software gives to another. |
| ASan | AddressSanitizer. Finds out-of-range access, use after free, and other memory errors at run time. |
| Asio | A C++ library for asynchronous network and low-level I/O. Available as Boost.Asio and as a standalone library. |
| Atomic | An operation that other threads see as complete or not started, never in the middle. `std::atomic<T>` gives atomic operations on a value. |
| Backpressure | A slow consumer makes a fast producer wait, for example with a bounded queue. Prevents unlimited memory growth. |
| Beast | Boost.Beast. A C++ library for HTTP and WebSocket on top of Asio. |
| Bitboard | A 64-bit integer where each bit is one square of a chess board. One bitboard holds a set of squares, for example all white pawns. |
| Build system | A tool that knows the dependencies between files and runs only the necessary compile and link steps. Examples: CMake (generates files for Ninja or Make), Meson, Bazel. |
| CI | Continuous integration. An automatic build and test of every change, usually on a server. |
| CLI | Command-line interface. |
| clangd | The language server of the LLVM project for C and C++. Gives completion, errors, and navigation in editors. |
| clang-format | A tool that formats C and C++ code with a configured style. |
| clang-tidy | A linter for C++. Finds common mistakes and code that is not idiomatic, and can fix some of them. |
| Cohesion | How much the parts of one module belong together. High cohesion is good. |
| Composition root | The one place in a program that makes the concrete objects and connects them, usually `main`. |
| Concept | A named set of requirements on a template parameter, checked at compile time (C++20). |
| `constexpr` | A specifier that permits evaluation at compile time. A `constexpr` variable must have a value that is known at compile time. |
| Coroutine | A function that can suspend its execution and continue later (C++20 `co_await`, `co_yield`, `co_return`). |
| Coupling | How much one module depends on the details of another. Low coupling is good. |
| CQS | Command-query separation. A function either changes state or returns a value, not both. |
| CRTP | Curiously recurring template pattern. A class derives from a template that has the derived class as its argument. Gives static polymorphism. |
| CRUD | Create, read, update, delete. The four basic operations on stored data. |
| Dangling | A pointer, reference, view, or iterator that refers to an object whose lifetime ended. Its use is undefined behavior. |
| Data race | Two threads access the same memory location at the same time, at least one writes, and nothing synchronizes them. In C++, a data race is undefined behavior. |
| DDD | Domain-driven design. A design method that models the software on the concepts and the language of the business domain. |
| Deadlock | Two or more threads wait for each other forever, usually for locks. |
| Destructor | A special member function that runs when the lifetime of an object ends. It releases the resources of the object (RAII). |
| DIP | Dependency inversion principle. The "D" in SOLID. |
| DRY | Do not repeat yourself. Every piece of knowledge has one representation in the system. |
| DTO | Data transfer object. A type that only carries data across a boundary, for example a JSON request body. |
| Entity | A domain object with an identity that stays the same when its data changes. |
| Exception safety | The guarantee that a function gives when an exception occurs: no guarantee, basic (no leaks, valid state), strong (no change), or no-throw. |
| FEN | Forsyth–Edwards Notation. One line of text that describes a chess position. |
| FetchContent | A CMake module that downloads and adds a dependency at configure time. |
| FFI | Foreign function interface. Calls between C++ and other languages, usually through a C interface. |
| Fuzzing | A test method that gives a program many random or mutated inputs to find crashes and undefined behavior. |
| Header | A file that other files include with `#include`. It usually contains declarations. |
| Header-only library | A library that is completely in headers. You add it by adding its include directory. |
| Hexagonal architecture | An architecture where the core of the application defines ports, and adapters connect the ports to technologies. Also "ports and adapters". |
| Immediate mode GUI | A GUI model where the program describes the whole user interface again in each frame. Example: Dear ImGui. |
| Invariant | A condition that is always true for a correct object or system, for example "a position has exactly one king of each color". |
| ISP | Interface segregation principle. The "I" in SOLID. |
| `jthread` | `std::jthread` (C++20). A thread that joins automatically in its destructor and supports cooperative cancellation with a stop token. |
| KISS | Keep it simple. Prefer the simplest design that solves the problem. |
| Lazy SMP | A method for a parallel chess search: several threads search the same position and share a transposition table. |
| Linker | The tool that joins object files and libraries into an executable or a shared library, and resolves the references between them. |
| LSP | Liskov substitution principle. The "L" in SOLID. Also "language server protocol" in editor documents; the course writes "language server" for that meaning. |
| Minimax | A search method for two-player games. One player maximizes the score, the other player minimizes it. |
| Module | A C++20 language feature that replaces headers for a library: `export module name;` and `import name;`. |
| Move semantics | The transfer of resources from one object to another without a copy (C++11). |
| Mutex | Mutual exclusion. A lock that only one thread can hold at a time. |
| Newtype | Another name for a strong type. |
| ODR | One definition rule. Each entity has one definition in the whole program (with exceptions for inline functions, templates, and types). |
| OCP | Open/closed principle. The "O" in SOLID. |
| Perft | Performance test. A function that counts all legal move sequences from a position to a depth. The published values make it the standard correctness test for move generators. |
| PGN | Portable Game Notation. A text format for chess games with tags and moves in SAN. |
| Pimpl | Pointer to implementation. A class keeps its private data in a separate object behind a pointer, to hide the details and to reduce compile dependencies. |
| Port | In a hexagonal architecture: an interface that the core defines, for example a game store. |
| Preset | A named CMake configuration in `CMakePresets.json`: generator, build directory, and cache variables. |
| Principal variation (PV) | The sequence of best moves that a chess search found. |
| Property-based test | A test that checks a property for many generated inputs, for example "parse(print(x)) == x". |
| RAII | Resource acquisition is initialization. An object takes a resource in its constructor and releases it in its destructor. |
| REST | Representational state transfer. A style of HTTP API with resources, URLs, and standard methods. |
| Rule of zero, three, five | Rule of zero: a class that does not manage a resource declares no special member functions. Rule of five: a class that declares one of destructor, copy constructor, copy assignment, move constructor, move assignment declares all five. |
| SAN | Standard Algebraic Notation. The usual notation for chess moves, for example `Nf3`, `exd5`, `O-O`. |
| Sanitizer | A compiler feature that adds run-time checks to find a class of errors (ASan, UBSan, TSan). |
| SemVer | Semantic versioning. Version numbers `MAJOR.MINOR.PATCH`. |
| SOLID | Five design principles: single responsibility, open/closed, Liskov substitution, interface segregation, dependency inversion. |
| SRP | Single responsibility principle. The "S" in SOLID. |
| SSE | Server-Sent Events. A standard for a stream of text events from a server to a client over one HTTP response. |
| Strong type | A class that wraps a primitive value to give it a meaning and rules, for example `Square` in place of `int`. |
| Stop token | `std::stop_token` (C++20). An object that a thread checks to find out if a stop was requested. |
| Translation unit | One source file after preprocessing: the input of one compiler run. |
| Transposition table | A hash table in a chess engine that stores the results of positions that the search already examined. |
| TSan | ThreadSanitizer. Finds data races at run time. |
| Type erasure | A technique that hides different concrete types behind one non-template interface, for example `std::function`. |
| UB | Undefined behavior. Behavior for which the C++ standard gives no rules. The program can do anything, including the expected result. |
| UBSan | UndefinedBehaviorSanitizer. Finds some kinds of undefined behavior at run time. |
| UCI | Universal Chess Interface. A text protocol between a chess engine and a chess user interface. |
| Vendoring | Copying the source code of a dependency into your own repository, at a pinned version. |
| View | A range that refers to other data and does not own it, for example `std::string_view` or a `std::views::filter` result. |
| vtable | The table of virtual function pointers that most compilers use to implement virtual functions. |
| WebSocket | A protocol for a long-lived, two-way connection between a client and a server, started with an HTTP upgrade request. |
| YAGNI | You are not going to need it. Do not build features or abstractions before they are needed. |
| Zobrist hashing | A method to compute a hash of a chess position: XOR of one random number for each piece on each square, and for the side to move, castling rights, and en passant. |
