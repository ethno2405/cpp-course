# Phase 5: Software Design and SOLID

**Time:** 4 weeks. Plan 5 weeks if design principles are new to you.
**Prerequisites:** Phase 4.
**Code:** `labs/phase-5-design/` and `labs/chess/`

## Goal

At the end of this phase, you can:

- Explain why design matters: the cost of a change, coupling, and cohesion.
- Explain each SOLID principle, show how it maps to C++, and name its costs.
- Apply other principles: DRY, KISS, YAGNI, the Law of Demeter, tell-don't-ask, command-query separation, and composition over inheritance.
- Model a domain with types: value objects, entities, identifiers, states, and invariants.
- Design a hexagonal architecture with library targets, and keep the dependencies in the correct direction.
- Use the common design patterns in their modern C++ form, and recognize anti-patterns and code smells.
- Refactor code in small, safe steps with tests.
- Use test-driven development (TDD) and test doubles.
- Write an architecture decision record (ADR).

## Reading

| Source | Part |
|---|---|
| Klaus Iglberger, *C++ Software Design* | All, if you can. It is the main book of this phase: design principles and patterns in modern C++, with value semantics and type erasure. |
| Robert C. Martin, *Clean Architecture* | The parts about design principles (SOLID), component principles, and architecture. The examples use Java. |
| John Ousterhout, *A Philosophy of Software Design*, 2nd edition | All. It is short. It gives a different view from Martin: deep modules, and complexity as the main enemy. |
| David Thomas and Andrew Hunt, *The Pragmatic Programmer*, 20th anniversary edition | The topics "The Essence of Good Design", "DRY—The Evils of Duplication", "Orthogonality", "Decoupling", and "Refactoring" |
| Martin Fowler, *Refactoring*, 2nd edition | The first chapters (the example and the principles), and "Bad Smells in Code". Use the catalog as a reference. |
| Scott Wlaschin, *Domain Modeling Made Functional* | The parts about domain modeling with types. The examples use F#; they map to C++ classes and `std::variant`. |
| Alistair Cockburn, "Hexagonal Architecture" (alistair.cockburn.us) | The original article about ports and adapters |
| Sandi Metz, "The Wrong Abstraction" (sandimetz.com) | A short article about the cost of DRY |
| Sean Parent, "Inheritance Is The Base Class of Evil" (a talk) | Value semantics and type erasure |
| Kent Beck, *Test-Driven Development: By Example* | Part I (the example) |

If design principles are new to you, read *The Pragmatic Programmer* topics first.

## Topics

### 5.1 Why design matters

- Most of the cost of software comes after the first version: every change, defect fix, and new feature. **Good design makes changes cheap.** It is not about beauty.
- **Coupling:** how much one part must know about another part. When two parts are tightly coupled, a change in one part forces a change in the other part. In C++, coupling also costs build time: a change to a header compiles every file that includes it.
- **Cohesion:** how much the parts inside a module belong together. A module with high cohesion has one purpose. All its parts change for the same reason.
- The goal: **low coupling between modules, high cohesion inside modules.**
- **Complexity** (Ousterhout) shows in three ways: a simple change needs changes in many places, a developer must know much to make a change, and it is not clear which code to change.
- **Principles are heuristics.** They describe forces, not laws. Each principle has a cost: more types, more indirection, more files, sometimes less speed. A design is a set of trade-offs. A 200-line tool does not need the architecture of a large service, and the inner loop of a chess search does not need a virtual call for each square.

### 5.2 S: the single responsibility principle (SRP)

> A module should have one, and only one, reason to change. (Robert C. Martin)

Martin later made it more exact: a module should be responsible to one **actor**, one group of people who request changes.

**Example.** One function reads a PGN file, checks the moves, computes statistics, and prints an HTML report. Three reasons can force a change: the file format, the statistics that the user wants, and the layout of the report. Each change touches the same function, and can break the other parts.

**In C++:**

- Split the work into functions, classes, and library targets by reason to change: `pgn` (the file format), `rules` (the legal moves), `stats` (the calculation), `report` (the presentation).
- Separate **calculation from I/O.** A function that computes statistics takes data and returns data. A different function reads the file and prints the result. The calculation is then easy to test.
- A class is one unit of responsibility, but not the only one. A namespace with free functions, or a library target, can also have one responsibility. Do not put every function in a class: a free function in a namespace is often the better design.

**Cost:** more classes and functions. If you split too much, a reader must jump between many small pieces to understand one feature ("shallow modules", Ousterhout). Split by reason to change, not by line count.

### 5.3 O: the open/closed principle (OCP)

> Software entities should be open for extension, but closed for modification. (Bertrand Meyer; this form from Robert C. Martin)

You can add new behavior without a change to existing, tested code.

**In C++**, an abstract class gives the extension point at run time:

```cpp
class Evaluator {
public:
    virtual ~Evaluator() = default;
    [[nodiscard]] virtual int evaluate(const Position& pos) const = 0;
};

class Search {
public:
    explicit Search(const Evaluator& evaluator) : evaluator_{&evaluator} {}
    Move best_move(const Position& pos, int depth);
private:
    const Evaluator* evaluator_;   // not owned; the composition root keeps it alive
};
```

A new evaluation is a new class that derives from `Evaluator`. The `Search` does not change. A template parameter (`template <EvaluatorConcept E> class Search`) gives the same extension point at compile time.

**`std::variant` and virtual functions: the expression problem.** C++ gives you tools that are open in different directions:

| | Add a new **type** | Add a new **operation** |
|---|---|---|
| `std::variant` and `std::visit` | Change every `std::visit` (the compiler finds them all) | Add one function. No other change. |
| Abstract class and derived classes | Add one class. No other change. | Change the base class and every derived class |

- Use a **`std::variant`** when the set of types is closed and under your control, and you often add operations. Examples: the commands of a protocol, the states of a state machine, the messages of the WebSocket API.
- Use an **abstract class** (or a concept with templates) when other code (other libraries, plugins, tests) must add types, or when you often add types. Examples: evaluators, game stores, opening books.
- A `std::variant` is not a violation of OCP. When you add a type, the compiler shows every place to change.

**Cost:** an extension point is an abstraction. If you never add a second implementation, it only adds indirection. Add the abstraction when the second implementation appears, or when a test needs a different implementation (topic 5.14).

### 5.4 L: the Liskov substitution principle (LSP)

> Objects of a subtype must be usable through the interface of the supertype, without a change of the correct behavior. (Barbara Liskov, 1987; Liskov and Wing, 1994)

C++ has inheritance, so this principle applies directly to derived classes. It also applies to types that satisfy a concept, and to every implementation of an interface.

- The compiler checks the signatures. It cannot check the behavior. Write the contract in the comment of the base class or the concept.
- **Examples from the standard library:** `operator<` for `std::sort` and `std::map` must be a strict weak ordering. `std::hash<T>` must agree with `operator==` (equal values have equal hashes). If your type breaks these contracts, `std::sort` can even have undefined behavior, and `std::unordered_set` gives wrong results.
- **The classic violation:** `class Square : public Rectangle`, where `set_width` also changes the height. Code that works with a `Rectangle` (set the width to 2 and the height to 3, expect the area 6) fails with a `Square`.
- **Example from the chess engine:** the port `GameStore` says "after `save(game)` succeeds, `load(id)` returns the game". A `CachedStore` that keeps only the last 10 games and drops older ones silently compiles, but code that uses a `GameStore` now fails in a way that the caller cannot see.
- Rules for a derived class: it must not require more from the caller (stronger preconditions), it must not give less (weaker postconditions), and it must not throw or fail in situations where the contract does not permit it.

**Contract tests:** write the tests of the contract one time, and run them for every implementation. With doctest, use a function template, or `TEST_CASE_TEMPLATE`:

```cpp
template <typename Store>
void check_store_contract(Store& store) {
    const Game game = sample_game();
    const auto id = store.save(game);
    REQUIRE(id.has_value());
    const auto loaded = store.load(*id);
    REQUIRE(loaded.has_value());
    CHECK(*loaded == game);
}

TEST_CASE("the memory store keeps the GameStore contract") {
    MemoryGameStore store;
    check_store_contract(store);
}
```

### 5.5 I: the interface segregation principle (ISP)

> Clients should not be forced to depend on methods that they do not use. (Robert C. Martin)

**In C++:** prefer small, focused interfaces.

- A large `Repository` class with 12 pure virtual functions forces every implementation (and every test double) to implement all 12. A report generator needs only "list the games". Give it a `GameSource` interface with one function.
- A class can implement several small interfaces with multiple inheritance of abstract classes: `class SqliteStore final : public GameSource, public GameSink`. Multiple inheritance of interfaces (abstract classes without data) is safe and common. Avoid multiple inheritance of classes with data.
- A concept states only what a template needs: a function that only iterates takes a `std::ranges::input_range`, not a container.
- A callable is the smallest possible interface. A function that needs only one operation can take a `std::function<Score(const Position&)>` or a template parameter that satisfies `std::invocable`.

**Cost:** many small interfaces can make the code harder to navigate. Split an interface when different clients use different parts of it.

### 5.6 D: the dependency inversion principle (DIP)

> High-level modules should not depend on low-level modules. Both should depend on abstractions. Abstractions should not depend on details. Details should depend on abstractions. (Robert C. Martin)

The important word is **inversion**: the high-level code (the rules and the search) **owns** the abstraction. The low-level code (the database, the file format, the network) implements it.

```text
Without DIP:   chess_core ──depends on──► sqlite3, std::fstream, Boost.Beast

With DIP:      chess_core  defines  class GameStore, class OpeningBook
                    ▲                        ▲
                    │ implements             │ implements
          chess_store_sqlite          chess_book
```

**In C++:**

- The core library defines the abstract classes or concepts (the **ports**). Adapter libraries link the core and implement the ports. The core does not link SQLite or Beast. The build files enforce this: a target cannot include the headers of a library that it does not link (if the include directories are set per target, not globally).
- **Virtual functions or templates?**

  ```cpp
  // Template: static dispatch. The evaluator type is part of the Search type.
  template <EvaluatorConcept E>
  class Search { E evaluator_; /* ... */ };

  // Abstract class: dynamic dispatch. One Search type. Easy to select at run time.
  class Search { const Evaluator* evaluator_; /* ... */ };
  ```

  Use templates in the hot path and in generic libraries. Use abstract classes to connect the parts of an application (stores, books, clocks, user interfaces). The cost of one virtual call is small compared with a file access, but it can be important if the search calls it millions of times per second. Measure it (stage 3 asks for this).

- **Composition root:** connect the concrete adapters in one place, the `main` function of each executable. Only `main` knows that the store is SQLite.
- **Dependency injection is only passing objects.** You do not need a framework. Pass the dependencies to the constructor (by reference, or as `std::unique_ptr` if the object takes ownership).
- **Where to invert:** at the boundaries of the system: storage, network, files, time, random numbers, the user interface, and the environment. Do not make an interface for every class.

### 5.7 Composition over inheritance

C++ has inheritance of implementation, and it is easy to misuse it.

- **Inheritance couples the derived class to the details of the base class.** A change in the base class can break all derived classes ("fragile base class"). Deep hierarchies are hard to understand.
- **Use public inheritance only for "is-a" with the Liskov principle:** to implement an interface. Prefer abstract base classes without data as interfaces.
- **Reuse behavior with composition:** a class contains other objects and forwards calls to them. Reuse algorithms with free functions and templates.
- **Value semantics with type erasure** (Sean Parent, Klaus Iglberger): hide a set of types behind a value type that copies and moves like an `int`, with a hidden virtual interface inside. `std::function` is an example. Then the users work with values, not with pointers to base classes.
- **Decorator:** a wrapper that implements the same interface and adds behavior:

  ```cpp
  class LoggedStore final : public GameStore {
  public:
      LoggedStore(GameStore& inner, Logger& log) : inner_{&inner}, log_{&log} {}
      std::expected<GameId, StoreError> save(const Game& game) override {
          log_->info("save game");
          return inner_->save(game);
      }
      // ... forward the other functions.
  private:
      GameStore* inner_;
      Logger* log_;
  };
  ```

### 5.8 Other principles

| Principle | Meaning | In C++, and the trade-off |
|---|---|---|
| **DRY**: do not repeat yourself (Hunt and Thomas) | Every piece of **knowledge** has one representation in the system | DRY is about knowledge, not about text. Two functions that look the same but change for different reasons are not duplication. "Duplication is far cheaper than the wrong abstraction" (Sandi Metz). Wait for the third copy before you extract ("rule of three"). |
| **KISS**: keep it simple | Prefer the simplest design that works | A free function before a class. A `std::variant` before a class hierarchy. A `std::vector` before a custom data structure. A non-template before a template. |
| **YAGNI**: you are not going to need it | Do not build features or abstractions for a future that you only imagine | Do not add templates, interfaces, or configuration "for later". |
| **Law of Demeter** | A function talks only to its direct collaborators, not to the collaborators of its collaborators | `game.current_position().side_to_move()` is fine. `engine.search().table().entries()[3].move.from()` knows too much about the structure. |
| **Tell, don't ask** | Tell an object what to do. Do not ask for its data and decide outside it. | `game.play(move)` in place of `if (is_legal(game.position(), move)) { game.moves().push_back(move); ... }`. The rule stays inside the type that owns the data. |
| **Command-query separation (CQS)** (Bertrand Meyer) | A function either changes state (a command) or returns a value (a query), not both | `const` member functions for queries make this visible in C++. |
| **Separation of concerns** | Different concerns (rules, storage, presentation, transport) are in different modules | The base of the hexagonal architecture (topic 5.10) |
| **Fail fast** | Detect errors as early as possible | Validate at the boundary. Check the configuration at startup. Prefer compile errors (`static_assert`, concepts, strong types) to run-time errors. |
| **Principle of least surprise** | Code behaves as a reader expects | Operators with their normal meaning. A `const` function that does not change visible state. |
| **Deep modules** (Ousterhout) | A good module has a simple interface and hides much complexity | `legal_moves(pos)` hides attack tables, pins, and special rules behind one function. |

### 5.9 Domain modeling with types

- **Value object:** defined only by its value. Usually immutable. Two equal values are interchangeable. `Square`, `Move`, `Score`, `CastlingRights`. In C++: a small class with `operator==` (often `= default`), passed by value.
- **Entity:** has an identity that stays the same when its data changes. `Game` in the store: the moves change, the game identifier stays. Two entities are the same when their identifiers are equal.
- **Identifiers:** use strong types: `class GameId`, not `int` or `std::string`. Then the compiler rejects a `GameId` where an `AnalysisId` is expected.
- **Invariants:** rules that are always true for an object. Keep the data members private, and check the rules in the constructor or factory (phase 4, topic 4.8).
- **States:** use a `std::variant` of state types, not `bool` members or a `std::string status`. Each state type has only the data that is valid in that state:

  ```cpp
  struct InProgress { Color to_move; };
  struct Checkmate { Color winner; };
  struct Draw { DrawReason reason; };
  using GameStatus = std::variant<InProgress, Checkmate, Draw>;
  ```

- **Functional core, imperative shell** (Gary Bernhardt): the core is functions on domain types. It has no I/O. The shell reads input, calls the core, and writes the output. The core is easy to test without test doubles. Move generation and evaluation are a functional core.

### 5.10 Architecture

| Style | Idea | Dependency direction |
|---|---|---|
| **Layered** | Presentation → application → domain → infrastructure | Each layer depends on the layer below it. The domain depends on the database. |
| **Hexagonal** (ports and adapters, Alistair Cockburn) | The application core is in the center. It defines ports (interfaces). Adapters connect the core to the world: driving adapters (CLI, UCI, GUI, HTTP) call the core; driven adapters (database, files) implement ports. | All dependencies point to the core. |
| **Clean architecture** (Robert C. Martin) | The same idea with more rings: entities, use cases, interface adapters, frameworks. | The dependency rule: source code dependencies point only inward. |

**A hexagonal chess engine with library targets:**

```text
labs/chess/
  CMakeLists.txt                Adds the subdirectories
  core/                         chess_core: types, rules, search, use cases, ports. No I/O.
  eval/                         chess_eval: evaluators. Links chess_core.
  book/                         chess_book: opening book file adapter. Links chess_core.
  store-pgn/                    chess_store_pgn: game store for PGN files. Links chess_core.
  uci/                          chess_uci: the UCI protocol on streams. Links chess_core.
  app/                          The chess executable. The composition root. Links all.
```

- Each target has a clear responsibility. `cmake --graphviz=deps.dot` shows the dependency graph.
- **Use cases** (also "application services") are classes or functions in the core that do one task for a user: `new_game`, `play_move`, `best_move`, `save_game`. They call the ports. A driving adapter (the CLI, UCI, and later the GUI and the HTTP server) calls the use cases.
- **Do not leak adapter types into the core.** The core does not know `sqlite3*`, `nlohmann::json`, `boost::beast::http::request`, or ImGui types. Map them to domain types in the adapter.
- **When not to use it:** a small tool, a prototype, or code that is only a thin layer over a database. Start with namespaces in one library. Split into targets when the boundaries are clear.

### 5.11 Design patterns in modern C++

Many patterns from the book *Design Patterns* (Gamma, Helm, Johnson, Vlissides, 1994) used C++ of that time. Modern C++ has other forms for many of them.

| Pattern | Modern C++ form |
|---|---|
| Strategy | An abstract class with implementations, a template parameter with a concept, or a `std::function` |
| Command | A `std::variant` of command types, or a `std::function<void()>` |
| State | A `std::variant` of state types and `std::visit` |
| Visitor | `std::visit` on a `std::variant`. The classic double-dispatch visitor is needed only for open class hierarchies. |
| Observer | A list of callbacks with subscription objects (RAII unsubscribe), or a queue between threads (phase 6) |
| Factory | A function that returns `std::unique_ptr<Interface>`, or a value; a static `create` function that returns `std::expected` |
| Builder | A struct with designated initializers often replaces it. A builder class for complex construction. |
| Adapter | A class that implements the interface that a client expects and forwards to a different interface |
| Decorator | A class that implements the same interface and wraps another object (topic 5.7) |
| Template method | Prefer a strategy object or a callable. Non-virtual interface (NVI): a public non-virtual function that calls private virtual functions, to keep pre- and postconditions in the base. |
| Iterator | The iterator and range concepts (phase 3) |
| RAII | The C++ pattern for every resource (phase 2) |
| Pimpl | Hide implementation details behind a pointer (phase 4) |
| Type erasure | A value type with a hidden virtual interface (`std::function`, `std::any`, your own) |
| CRTP | Static polymorphism in older code; prefer concepts or deducing `this` |
| Singleton | Avoid it. Pass the object as a dependency. A global object makes tests depend on each other. |

### 5.12 Anti-patterns and code smells

A **code smell** (Kent Beck, Martin Fowler) is a sign that a design can have a problem. It is not always a problem. Look at the reason.

| Smell or anti-pattern | Sign | Better |
|---|---|---|
| `std::shared_ptr` everywhere | An object graph like in a garbage-collected language; nobody knows who owns what | One owner, references or identifiers for the others |
| Deep inheritance hierarchies | Five levels of base classes; protected data | Composition, interfaces without data |
| Base classes with data for code reuse | `class Bishop : public SlidingPiece : public Piece` | Free functions, composition, `std::variant` |
| Stringly typed code | `std::string status`, `std::string color` | `enum class`, `std::variant`, strong types |
| Primitive obsession | `int` for squares, moves, scores, and identifiers | Strong types |
| Boolean parameters | `search(pos, true, false)` | `enum class`, or a parameter struct |
| God class | One `Engine`, `Manager`, or `Utils` class that does everything | Split by responsibility |
| Long parameter list | 5 or more parameters | A parameter struct with designated initializers |
| Feature envy | A function uses more data from a different class than from its own | Move the function to that class |
| Shotgun surgery | One change needs edits in many files | Put the knowledge in one place |
| Speculative generality | Templates, interfaces, or configuration that only one case uses | Remove them (YAGNI) |
| Global mutable state | Global variables or singletons used everywhere | Pass the state as a dependency |
| Header that includes everything | A change to one detail compiles the whole project | Forward declarations, smaller headers, pimpl |
| Macros for code generation | Many macros that make functions | Templates, `constexpr`, lambdas |

### 5.13 Refactoring

> Refactoring: a change to the internal structure of software to make it easier to understand and cheaper to modify, without a change to its observable behavior. (Martin Fowler)

- Refactor in **small steps.** After each step, the code compiles and the tests pass. Commit often.
- Do not refactor and change behavior in the same step. Do one, then the other.
- If the code has no tests, write **characterization tests** first: tests that record what the code does now, also if the behavior looks wrong.
- Common refactorings in C++:

  | Refactoring | Tool |
  |---|---|
  | Extract function, extract variable, rename | clangd code actions, or the IDE refactoring menu |
  | Move a function to a different file or library | Cut and paste. The compiler and the linker show what is missing. |
  | Replace a primitive with a strong type | Change the type. Follow the compiler errors. |
  | Replace `bool` parameters with an `enum class` | Change the signature. Follow the compiler errors. |
  | Introduce a parameter struct | Group the parameters in a struct |
  | Replace a type code with `std::variant`, or a hierarchy with `std::variant` | Topic 5.3 |
  | Extract an interface | Make an abstract class from the public functions that a client uses |

- **The compiler helps, but not as much as in some languages.** A refactoring that compiles can still have undefined behavior (for example a new dangling reference). Run the tests under the sanitizers after each step.

### 5.14 Testability and test-driven development

- **Test-driven development (TDD)** (Kent Beck): write a failing test (red), write the simplest code that passes it (green), then improve the design (refactor). Repeat in small cycles.
- TDD gives fast feedback, and it makes you design the interface from the side of the caller first.
- **Test doubles** replace a real dependency in a test:

  | Double | Behavior | C++ |
  |---|---|---|
  | Stub | Returns fixed values | A class that implements the port with constant results |
  | Fake | A simple, working implementation | `MemoryGameStore` with a `std::map` |
  | Spy | Records the calls for a later check | A class with a `std::vector` of the calls |
  | Mock | Checks the calls against expectations | GoogleMock, or trompeloeil (phase 8) |

- **Prefer fakes** for ports. A fake tests behavior. A mock tests the interaction, and a test with many mocks breaks when you refactor.
- **Seams:** the place where a test can replace a dependency. In C++: a constructor parameter (an interface), a template parameter, a `std::function` parameter, or the link step (link a fake implementation of a function in the test executable). Prefer the constructor and the template; link seams are hard to understand.
- **Inject time and other non-deterministic inputs:**

  ```cpp
  class Clock {
  public:
      virtual ~Clock() = default;
      [[nodiscard]] virtual std::chrono::steady_clock::time_point now() const = 0;
  };

  class ManualClock final : public Clock {
  public:
      [[nodiscard]] std::chrono::steady_clock::time_point now() const override { return now_; }
      void advance(std::chrono::milliseconds d) { now_ += d; }
  private:
      std::chrono::steady_clock::time_point now_{};
  };
  ```

  Often a parameter is simpler than an interface: `bool is_time_up(time_point now) const`. The caller gets the time from the clock.

### 5.15 Clean code

- **Names:** a name says what a value means and why it exists. Use the words of the domain (the "ubiquitous language" of domain-driven design). Long scopes need longer names.
- **Functions:** a function does one thing at one level of abstraction. A function that reads like a list of steps calls functions that each do one step.
- **Comments** explain **why**, not what. If a comment explains what the code does, improve the names. Document the contracts of public functions (phase 4).
- **Constants:** give names to magic values: `constexpr int max_moves = 256;`.
- **Error paths:** handle errors early and return. Keep the normal path at the lowest indentation.
- **Two views:** *Clean Code* (Martin) recommends very small functions. *A Philosophy of Software Design* (Ousterhout) warns that very small functions can make "shallow" modules that are harder to understand. Both books agree on the goal: code that is easy to read and to change. Use your judgment, and ask a reviewer.

### 5.16 Architecture decision records

- An **architecture decision record (ADR)** (Michael Nygard) records one important decision: its context, the decision, and its consequences.
- Keep ADRs in the repository, in `docs/adr/`, numbered: `0001-split-the-engine-into-library-targets.md`.
- Format: **Title**, **Status** (proposed, accepted, superseded by ADR n), **Context** (the forces and the options), **Decision**, **Consequences** (the good and the bad results).
- An ADR is never changed after it is accepted. A new ADR replaces it.

## Exercises

Make the project `labs/phase-5-design/`. If you know design principles well (D = 3 in your profile), do exercises 5.2, 5.5, 5.7, and 5.9.

### Exercise 5.1: Single responsibility

This function works, but it is hard to change and to test.

```cpp
std::string game_report(const char* path, bool html) {
    std::ifstream in(path);
    std::string line;
    std::map<std::string, double> wins;
    int count = 0;
    while (std::getline(in, line)) {
        if (line.rfind("[White ", 0) == 0 || line.rfind("[Black ", 0) == 0) {
            continue;
        }
        if (line.rfind("[Result \"", 0) == 0) {
            std::string r = line.substr(9, 3);
            if (r == "1-0") wins["white"] += 1;
            else if (r == "0-1") wins["black"] += 1;
            else wins["draw"] += 0.5;
            count++;
        }
    }
    std::string out;
    if (html) {
        out += "<table>";
        for (auto& [k, v] : wins) out += "<tr><td>" + k + "</td><td>" + std::to_string(v) + "</td></tr>";
        out += "</table>";
    } else {
        for (auto& [k, v] : wins) out += k + ": " + std::to_string(v) + "\n";
    }
    out += std::to_string(count) + " games";
    return out;
}
```

1. List all the reasons why this function can change. List all the defects and risks that you find (there are more than six).
2. Write characterization tests for the current behavior first. Write the test files to a temporary directory (`std::filesystem::temp_directory_path()`).
3. Refactor in small steps, with a commit after each step. Separate the reading, the parsing, the counting, and the rendering. The calculation must not do I/O.
4. Fix the defects only after the refactoring. Write a test for each defect first.

### Exercise 5.2: Open/closed and the expression problem (core)

1. Write a notification system with two channels: email and SMS (print to the standard output in place of a real send). Design it with an abstract class.
2. Add a third channel (a webhook). Count the files and functions that you changed.
3. Write the same system with a `std::variant`. Add the third channel. Count again.
4. Now add a new operation to both designs: "estimate the cost of a message". Count again.
5. Compare the results with exercise 1.4. Write a short rule in your engineering notebook: when do you use a `std::variant`, and when an abstract class?

### Exercise 5.3: Liskov and contract tests

1. Define an interface `KeyValueStore` with `get`, `put`, and `remove`. Write the contract in the comment of the interface.
2. Write a contract test function template (topic 5.4), with at least five checks.
3. Implement the interface with a `std::unordered_map`, and with a file. Run the contract tests on both.
4. Write a `LimitedStore` that keeps only 10 keys and drops the oldest key silently. Run the contract tests. Which check fails? Change the design so that `LimitedStore` keeps the contract (for example: return an error when the store is full).
5. Write a type whose `std::hash` specialization does not agree with its `operator==`. Show that a `std::unordered_set` then gives a wrong result.

### Exercise 5.4: Interface segregation

Look at this interface:

```cpp
class GameRepository {
public:
    virtual ~GameRepository() = default;
    virtual std::expected<GameId, RepoError> add(const Game& game) = 0;
    virtual std::expected<void, RepoError> update(GameId id, const Game& game) = 0;
    virtual std::expected<void, RepoError> remove(GameId id) = 0;
    virtual std::expected<std::vector<Game>, RepoError> find(const GameFilter& filter) const = 0;
    virtual std::expected<std::vector<Player>, RepoError> players() const = 0;
    virtual std::expected<void, RepoError> export_pgn(const std::filesystem::path& path) const = 0;
    virtual std::expected<void, RepoError> backup(const std::filesystem::path& dir) const = 0;
    virtual std::expected<void, RepoError> send_weekly_email(std::string_view to) const = 0;
};
```

1. A statistics generator needs only to read games. Write a test double for it with this interface. How many functions must the double implement?
2. Split the interface. Which functions are not about storage at all? Where do they belong?
3. Write the statistics generator again with the smaller interface, and with a `std::function` parameter. Compare.

### Exercise 5.5: Dependency inversion and a hexagonal design (core)

Build the core of a URL shortener.

1. Make a project with the targets `shortener_core`, `shortener_store_memory`, `shortener_store_file`, and the executable `shortener`.
2. The core defines `ShortCode`, `Link`, the port `LinkStore`, the port `CodeGenerator`, and the use cases `shorten(url)` and `resolve(code)`. The core links nothing except the standard library, and does no I/O.
3. Implement both stores and a random code generator. Test the use cases with a fake store and a fixed code generator.
4. Make the dependency graph with `cmake --graphviz` (or read the build files). Draw it. Check that all arrows point to the core.
5. Change the executable to use the file store in place of the memory store. Which target changed?

### Exercise 5.6: Patterns in modern C++

1. **State:** model an expense claim: `Draft` → `Submitted` → `Approved` or `Rejected` → `Paid`, with a `std::variant` of state types. A function `pay` accepts only an `Approved` claim: make the wrong call a compile error, or return an error, and write why you selected that form.
2. **Decorator:** write `LoggedStore` and `CachedStore` for the `LinkStore` of exercise 5.5. Combine them. The core does not change.
3. **Strategy:** write a function that sorts games by a strategy. Implement it with an abstract class, with a template parameter, and with a lambda. Which one is simpler here?
4. **Type erasure:** write a value type `AnyShape` that holds any type with `area()` and `name()` functions, without a common base class. Store different shapes in a `std::vector<AnyShape>`, and copy the vector.

### Exercise 5.7: Test-driven development with a clock (core)

Build a chess clock module with TDD. Write each test before the code.

1. A clock has a time for each side, an increment, and the side whose clock runs.
2. Rules: `press()` stops the running clock, adds the increment to it, and starts the other clock; a side whose time is 0 or less has lost on time; the clock can pause and continue; a "delay" mode (the time starts to run only after a fixed delay) is optional.
3. Inject the time (topic 5.14). No test uses the real time or sleeps.
4. Commit after each green test and after each refactoring. Look at the git log: does it show the red-green-refactor cycle?

This clock is used again in the chess engine (stages 4 and 5).

### Exercise 5.8: Find the smells

Read this design and list the smells from topic 5.12. Then write a better design: only the types and the signatures, with no function bodies.

```cpp
class Manager {
public:
    std::vector<std::tuple<std::string, std::string, int, bool>> data;  // white, black, result, is_rated
    std::shared_ptr<Database> db;
    std::string mode;                                                  // "test" or "prod"

    std::string handle(const std::string& s, bool flag, bool flag2);
    // 150 lines: parse the command in s, change data,
    // write to the database, and format the answer as text or JSON.
};
```

### Exercise 5.9: Design review and ADRs (core)

1. Write ADRs for the important decisions of chess engine stage 3 (see the project document): at least the target structure, the form of the `Evaluator` port, and copy-make or make/unmake.
2. Ask the mentor (or a different person) for a design review of your engine. Answer the "what if" questions: a new evaluator, a SQLite game store, a GUI, an HTTP server. How many targets and files must change for each?

## Project: Chess engine, stage 3

See [../projects/chess-engine.md](../projects/chess-engine.md), stage 3.

## Done criteria

- [ ] I can explain coupling, cohesion, and why they matter for the cost of a change.
- [ ] I can explain each SOLID principle with a C++ example, and name one cost of each principle.
- [ ] I can decide between a `std::variant`, an abstract class, and a template for an extension point, and explain the expression problem.
- [ ] I can write contract tests for an interface.
- [ ] I can explain DRY, KISS, YAGNI, the Law of Demeter, and tell-don't-ask, and when they conflict.
- [ ] I can model a domain with value objects, entities, strong identifiers, and `std::variant` states.
- [ ] My chess engine has a hexagonal architecture: the core has no I/O dependencies, and the build files show that all dependencies point to the core.
- [ ] I can refactor in small steps with tests and commits.
- [ ] I used TDD for a module, and the git history shows it.
- [ ] I wrote ADRs for my main design decisions.
- [ ] Chess engine stage 3 is complete.

## Next

[Phase 6: Concurrency and user interfaces](phase-6-concurrency-gui.md)
