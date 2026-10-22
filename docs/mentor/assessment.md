# Assessment

This document tells the AI mentor how to assess the knowledge of a learner. The result is the learner profile, `learner/profile.md`. The mentor uses the profile in every session.

## When to assess

| Situation | Action |
|---|---|
| `learner/profile.md` does not exist | Do a full assessment: mode selection, part A, part B, project selection, toolchain selection, result |
| `learner/profile.md` does not exist, but `learner/progress.md` exists | Rebuild the profile. Recommend the quick mode. Keep the progress file and the current position. |
| The learner asks to re-assess one area ("Re-assess my design knowledge") | Do part B for that area only. Update the level after the learner agrees. |
| The learner completes a phase | Do the phase review (last section of this document) |

## Rules for the assessment

- Tell the learner that the assessment is not a test. Its only purpose is to select the correct start point and the correct explanation level.
- Ask **one question at a time**. Wait for the answer.
- Tell the learner that "I do not know" is a good answer. A guess gives a wrong level.
- Ask the learner not to look up answers and not to run the code.
- Do not explain the correct answer during part B, unless the learner asks. Give all corrections at the end, in the result summary.
- Keep a short record of each question and the result. You write it into the profile as evidence.

## Step 1: Mode selection

Show the three modes to the learner and ask them to select one:

| Mode | Time | Content | Accuracy |
|---|---|---|---|
| **Quick** | ~5 minutes | Part A only (self-report) | Low. The mentor trusts the answers and corrects the levels later from the learner's work. |
| **Standard** | ~15–20 minutes | Part A, then 2–4 adaptive questions for each area in part B | Good for most learners |
| **Full** | ~45 minutes | Part A, then 5–8 questions for each area in part B, with the practical items | High. Use it if the learner wants an exact start point. |

If the learner does not select a mode, use **standard**.

## Step 2: Part A, self-report (all modes)

Ask these questions. You can ask related questions together in one message.

1. Which programming languages do you know? For how many years? Which one do you know best?
2. How much C++ do you know? (none / I read some C++ code / I wrote small programs / I use it at work) Which standard did you use? (C++98, C++11/14, C++17, C++20 or newer, I do not know)
3. Do you know how memory works in a program: the stack, the heap, pointers, object lifetime, garbage collection? (no / a little / yes)
4. Did you write programs with threads, locks, atomics, or async code? (no / a little / yes, often)
5. Do you know design principles and patterns: SOLID, design patterns, layered architecture, unit tests with test doubles? (no / I know the names / I use some of them / I use them at work and can explain the trade-offs)
6. Which tools do you use: git, a terminal, a debugger with breakpoints, a build system (CMake, Make, MSBuild, Gradle, ...), a package manager, a CI pipeline?
7. Which operating system and which editor or IDE do you use?
8. Do you know which compiler and build system you want to use? (If not, the mentor helps in step 5.)
9. How many hours per week can you work on the course?
10. What is your goal? (for example: game or engine development, systems programming, high-performance code, a job that uses C++, better design skills in general, a specific project)
11. How do you want the mentor to help when you are blocked? (hints first, and a solution only when I ask / a full solution with an explanation)
12. How detailed must the explanations be? (short / normal / very detailed)

In **quick** mode, set the levels from the self-report with the rubric below, and mark them "self-reported". Then go to step 4.

## Step 3: Part B, knowledge check (standard and full modes)

### Adaptive rule

For each area:

1. Use the self-report to select the first question. Self-report "none" or "no" → start at level 1. Self-report "a little" or "I know the names" → start at level 2. Self-report "I use it at work" or "yes, often" → start at level 3.
2. A correct answer → ask the next question at a higher level (or another question at level 3).
3. A wrong answer or "I do not know" → ask the next question at a lower level.
4. Stop when the level is clear. Standard mode: 2–4 questions for each area. Full mode: 5–8 questions for each area, including the practical items.
5. A partly correct answer counts as half. Ask one more question at the same level to decide.

You can change the wording of a question. You can make new questions at the same level. The expected answers below are the minimum for "correct".

If the learner has C++ level 0 in the self-report, ask only the level 1 questions of area C. Do not make a learner with no C++ read C++ code in the other areas: use pseudocode or the language that the learner knows best.

**Learners who know only old C++** (C++98 or C++03): they often answer level 1 and 2 questions correctly but do not know move semantics, smart pointers, or `auto`. Ask at least one level 3 question about modern C++. Record "old C++ habits" in the observations if you see them.

### Area C: C++ language

| Level | Question | Expected answer |
|---|---|---|
| 1 | What is the difference between `int x = 5;` and `const int x = 5;`? | The `const` variable cannot change after its initialization. The compiler rejects a write. |
| 1 | What does `#include <vector>` do? | The preprocessor copies the content of the header into the source file before compilation. The header declares `std::vector`. |
| 1 | What is the difference between a declaration and a definition? | A declaration says that a name exists and gives its type. A definition also makes the entity (allocates the variable, gives the function body). |
| 2 | What is the difference between passing `std::string s` and `const std::string& s` to a function? | By value makes a copy (or a move) that the function owns. By `const` reference, the function reads the caller's object without a copy and cannot change it. |
| 2 | What happens at the end of this block? `{ std::vector<int> v(1000); }` | The destructor of `v` runs automatically and frees the memory. This is RAII. |
| 2 | What is a dangling reference? Give an example. | A reference to an object whose lifetime ended. Example: a function that returns a reference to a local variable, or a `std::string_view` to a temporary string. |
| 2 | What is the difference between a virtual function and a template for polymorphism? | A virtual function selects the implementation at run time through a vtable (dynamic dispatch). A template makes one copy of the code for each type at compile time (static dispatch). |
| 3 | What does `std::move` do? What is the state of the object after a move? | `std::move` only casts to an rvalue reference; it moves nothing by itself. The move constructor or move assignment then takes the resources. A moved-from standard library object is in a valid but unspecified state. |
| 3 | What is the rule of zero? When do you write a destructor? | A class that does not manage a resource directly declares no special member functions; members like `std::vector` and `std::unique_ptr` do the work. Write a destructor (and the copy and move operations, or delete them) only in a class that manages one resource directly. |
| 3 | Give two examples of undefined behavior. Why can a program with UB seem to work? | Examples: signed integer overflow, out-of-range access, use after free, a data race, dereference of a null pointer, reading an uninitialized variable. The compiler can assume that UB never happens, so the result can be anything, including the expected output. |
| 3 | What is the difference between `std::unique_ptr` and `std::shared_ptr`? What is the cost of `shared_ptr`? | `unique_ptr`: one owner, no overhead, move-only. `shared_ptr`: shared ownership with a reference count; costs a control block, atomic count changes, and the ownership becomes hard to follow. Cycles leak without `weak_ptr`. |
| 3 | What are concepts for? | They put named requirements on template parameters. The compiler checks them at the call site and gives clear errors. They also select overloads. |

### Area S: memory and concurrency

| Level | Question | Expected answer |
|---|---|---|
| 1 | What is the difference between the stack and the heap? | The stack holds local variables and function calls. It is fast and is freed automatically at the end of the scope. The heap holds data whose size or lifetime is not known at compile time. |
| 1 | What is a thread? | An independent sequence of execution in a process. Threads share the memory of the process. |
| 2 | What is a memory leak? What is a double free? | A leak is memory that the program does not free and cannot use. A double free frees the same memory two times, which is UB. |
| 2 | What is a race condition? | The result depends on the timing of two threads that use shared data. At least one of them writes, and there is no synchronization. |
| 2 | What is the difference between concurrency and parallelism? | Concurrency: many tasks make progress in the same time period, possibly on one CPU core. Parallelism: tasks run at the same time on many cores. |
| 3 | What is a deadlock? Give one method to prevent it. | Two or more threads wait for locks that the others hold. Always take locks in the same order, take them together (`std::scoped_lock`), use one lock, or use timeouts. |
| 3 | In C++, what is a data race, and what is the result? | Two threads access the same memory location without synchronization, and at least one access is a write. The result is undefined behavior, not only a wrong value. |
| 3 | What does `std::atomic<int>` guarantee? Is it enough for every shared-state problem? | Each operation on it is indivisible and has no data race. It is not enough when an invariant covers more than one variable; then you need a lock or a different design. |
| 3 | A user interface thread calls a function that takes 3 seconds. What is the problem? What do you do? | The UI cannot redraw or react to input for 3 seconds (it "freezes"). Run the work on a worker thread, and send the result back to the UI thread. |

### Area D: design and practices

| Level | Question | Expected answer |
|---|---|---|
| 1 | Why do developers write automated tests? | To find defects early, to change code safely (regression), and to document the behavior. |
| 1 | What is the difference between an interface and an implementation? | The interface says what an object or module does (its contract). The implementation says how it does it. |
| 2 | What is the difference between a unit test and an integration test? | A unit test checks one small unit alone, often with test doubles. An integration test checks that many parts work together. |
| 2 | Explain the dependency inversion principle. | High-level code does not depend on low-level details. Both depend on an abstraction (an abstract class, a concept, or a function type) that the high-level code owns. |
| 2 | Give an example of a "code smell". | Any valid example with a reason, for example: a long function, duplicate code, a long parameter list, a class that does too many things, primitive values for domain concepts. |
| 2 | What does "composition over inheritance" mean? | Build behavior from small objects that you combine, in place of deep class hierarchies. |
| 3 | Explain the Liskov substitution principle. Give an example of a violation. | A derived class (or an implementation of an interface) must keep the contract of the base. Example: a `Square` that derives from `Rectangle` and changes both sides in `set_width`; a read-only collection that throws in `add`. |
| 3 | When does "do not repeat yourself" (DRY) make a design worse? | When two pieces of code look the same but represent different knowledge, or change for different reasons. A shared abstraction then couples them. |
| 3 | What is a port and an adapter in a hexagonal architecture? | A port is an interface that the application core defines (for example a game store). An adapter implements the port for a specific technology (a database, HTTP, a file, a GUI). |
| 3 | How do you test code that uses the current time? | Inject a clock (an interface, a template parameter, or a function). Use a fixed or controllable clock in the test. |

### Area T: tools

| Level | Question | Expected answer |
|---|---|---|
| 1 | What does `git commit` do? | It records the staged changes as a new version in the local repository. |
| 1 | What does a compiler do? What does a linker do? | The compiler translates each source file to an object file. The linker joins the object files and libraries into an executable and resolves the references between them. |
| 2 | What is a build system for? Name one. | It knows the dependencies between files and runs only the necessary compile and link steps, with the correct options. Examples: CMake (a generator), Meson, Make, Ninja, MSBuild, Bazel. |
| 2 | How do you find the value of a variable at a specific line with a debugger? | Set a breakpoint on the line, run, and inspect the variable when the program stops. |
| 2 | What does a version number like `2.4.1` mean in semantic versioning? | Major, minor, patch. A major change breaks compatibility. A minor change adds features compatibly. A patch fixes defects. |
| 3 | What does a typical CI pipeline do? | On each push or pull request: build, format check, lint, run tests, and sometimes sanitizers, security checks, and release steps. |
| 3 | What is the difference between a debug build and a release build in C++? | A debug build has no optimizations and has debug information, and often extra checks (assertions, checked iterators). A release build is optimized, often with `NDEBUG`, so `assert` does nothing. UB can show different results in each build. |
| 3 | What is an "undefined reference" (or "unresolved external symbol") error? Name two causes. | A linker error: a function or variable is declared but the linker finds no definition. Causes: a missing source file in the build, a missing library, a declaration that does not match the definition, a missing template definition in a header. |

### Practical items (full mode only)

Ask 1–2 items for each area, at the level of the learner.

**C, code reading.** Ask what is wrong with the code.

```cpp
#include <string>
#include <string_view>

std::string_view first_word(const std::string& text) {
    return std::string_view{text}.substr(0, text.find(' '));
}

int main() {
    std::string_view word = first_word(std::string{"hello world"});
    return static_cast<int>(word.size());   // uses word
}
```

Expected: `word` dangles. The temporary `std::string` ends at the end of the full expression in `main`, so `word` points to freed memory. Using it is undefined behavior. The compiler can accept the code; AddressSanitizer reports a use after free.

```cpp
std::vector<int> scores{10, 20, 30};
for (int s : scores) {
    if (s > 15) {
        scores.push_back(s * 2);
    }
}
```

Expected: undefined behavior. `push_back` can reallocate the buffer, and then the iterators of the range-based `for` loop dangle. Other languages report "modified during iteration" at run time; C++ gives no error.

**S, concurrency.** Explain what can go wrong (in pseudocode or the learner's language): two threads run `counter = counter + 1` 1000 times each on a shared integer without a lock. What values can `counter` have at the end? What is different in C++?

Expected: in most languages, a value from 2 to 2000, because the read-modify-write is not atomic. In C++, it is a data race, so the behavior of the whole program is undefined.

**D, design review.** Show this function and ask for the design problems:

```cpp
double process(const char* path, bool send_email, const std::string& format);
// 80 lines: read the file, parse CSV lines, compute the total
// of the orders, write a report in "html" or "text" format,
// and send an email when send_email is true.
```

Expected (2 or more): it does too many things (single responsibility); a `bool` parameter and a string `format` parameter (use `enum class`); hard to test because it reads files and sends email (inject the dependencies); `double` for money; the return value mixes calculation with I/O; `const char*` in place of `std::filesystem::path` or `std::string_view`.

**T, tools.** Explain the steps from a new idea to code on the `main` branch in a team.

Expected: a branch, small commits, tests and lints run locally, push, a pull request, CI runs, a code review, a merge.

## Level rubric

Give each area (C, S, D, T) a level from 0 to 3:

| Level | Name | Description |
|---|---|---|
| 0 | None | Cannot answer level 1 questions. |
| 1 | Basic | Answers most level 1 questions. Fails most level 2 questions. |
| 2 | Working | Answers most level 2 questions. Fails most level 3 questions. |
| 3 | Strong | Answers most level 3 questions. |

In quick mode, use the self-report: "none" / "no" → 0, "I read some C++ code" / "a little" / "I know the names" → 1, "I wrote small programs" / "I use some of them" → 2, "I use it at work" / "yes, often" / "I can explain the trade-offs" → 3. Mark these levels "self-reported". If the learner used only C++98 or C++03, set C to at most 2.

## Learning path

Use the levels to make the learning path. Write the decisions in the profile.

| Condition | Decision |
|---|---|
| C = 0 | Do all of phase 1. Plan the phase 1 time from the background table in `docs/README.md`. |
| C = 1 | Do all topics and exercises of phase 1. Plan 2–3 weeks. |
| C = 2 | Read phase 1 quickly. Do exercises 1.5, 1.6, and 1.8 and project stage 0. In phases 2 and 3, do all exercises. |
| C = 3 | Do project stage 0 only in phase 1. In phases 2 and 3, do the exercises marked "core" and project stage 1. Focus on phases 4–8. |
| Old C++ only (C++98/03) | Do phase 2 completely (move semantics, smart pointers, rule of zero), even if C = 2. Show the modern replacement each time that an old habit appears. |
| S = 0 or 1 | Do topic 2.0 before phase 2. Explain the stack and the heap with diagrams. In phase 6, do all exercises. |
| S = 3 | In phase 6, focus on the C++ memory model, `std::jthread` and stop tokens, and the UI thread rule. |
| D = 0 or 1 | Before phase 5, read the parts of *The Pragmatic Programmer* that phase 5 names. Plan 5 weeks for phase 5. Explain each principle with a small example before you name it. |
| D = 3 | In phase 5, focus on the mapping of the principles to C++ (abstract classes, concepts, type erasure, CMake targets) and on the trade-offs. Do exercises 5.2, 5.5, 5.7, and 5.9. |
| T = 0 or 1 | Spend extra time on phase 0, topics 0.2 (the compilation model) and 0.12 (git). Teach the terminal commands that the learner needs. Recommend the default toolchain. |
| A managed language is the best known language (C#, Java, Go, TypeScript) | Compare with references, the garbage collector, interfaces, and exceptions. Expect problems with object lifetime and value semantics in phase 2. |
| A dynamic language is the best known language (Python, JavaScript, Ruby) | Explain static types and compilation first (topic 1.0). Expect problems with types, the compilation model, and lifetime. |
| Rust is the best known language | Compare with ownership, borrowing, traits, and `Result`. Warn that the C++ compiler does not check lifetimes and data races: the sanitizers and the review take this role. |
| C is the best known language | Compare with manual memory management. Show RAII as the replacement for `goto cleanup`. Expect fast progress in phase 2, and problems with templates in phase 3. |
| Fewer than 4 hours per week | Tell the learner to double the phase times in `docs/README.md`. |

## Step 4: Project selection

Do the project selection in `docs/mentor/project-selection.md`. The learner can keep the reference project (the chess engine) or select a different domain. If the learner does not want to decide now, record "Chess engine (default)" in the profile.

## Step 5: Toolchain selection

Do the toolchain selection in `docs/mentor/toolchain-selection.md`. If the learner does not want to decide now, record "Default (to be confirmed in phase 0)" in the "Toolchain" section of the profile. Phase 0 completes the selection.

## Step 6: Result

1. Write `learner/profile.md` from `docs/templates/profile-template.md`. Fill in all sections. Put the evidence for each level (the questions and the results).
2. Show the learner a summary: the level of each area, the learning path, the project, the toolchain, and the corrections for the questions that they answered wrong.
3. Ask the learner whether the summary is correct. Change the profile if the learner disagrees with good reasons.
4. If `learner/progress.md` does not exist, create it from `docs/templates/progress-template.md`. Set the start date to today.
5. If `learner/progress.md` already existed before the assessment, do not change the current position. Tell the learner their next step from the progress file. Otherwise, tell the learner the first step of their learning path: phase 0, topic 0.1.

## Phase review

When the learner says that they completed a phase:

1. Ask 3–5 questions from the "Done criteria" list of the phase. Use questions that need an explanation, not a yes or no.
2. Ask for evidence of the practical criteria: code and test results in `labs/`, the build output with the warnings enabled, the clang-tidy output, the sanitizer test run, or a CI run.
3. Read the code of the project stage of the phase. Do a short design review with `docs/topics/code-review-checklist.md`.
4. If the learner meets all criteria, mark the phase "Done" in `learner/progress.md`.
5. If some criteria are not met, tell the learner which ones, and suggest the exercises to repeat.
6. If the results show that a level in the profile changed, propose the new level to the learner. Change it after the learner agrees. Add the review to the "Assessment history" in the profile.
