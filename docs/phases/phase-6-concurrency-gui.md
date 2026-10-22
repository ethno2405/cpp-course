# Phase 6: Concurrency and User Interfaces

**Time:** 4–5 weeks.
**Prerequisites:** Phase 5.
**Code:** `labs/phase-6-concurrency/` and `labs/chess/`

## Goal

At the end of this phase, you can:

- Explain the difference between concurrency and parallelism, and select one for a problem.
- Start, stop, and join threads with `std::jthread` and stop tokens, and never detach a thread.
- Explain the C++ memory model at the level that you need: data races, happens-before, and why a data race is undefined behavior.
- Protect shared state with mutexes and condition variables, and prevent deadlocks.
- Use atomics for simple shared values, and explain the cost of false sharing.
- Design with message passing: bounded queues, worker pools, and backpressure.
- Cancel long work cooperatively, and shut down all threads cleanly.
- Build a desktop user interface with an event loop that never blocks, and connect it to work on other threads.
- Test concurrent code, and find data races with ThreadSanitizer.

## Reading

| Source | Part |
|---|---|
| Anthony Williams, *C++ Concurrency in Action*, 2nd edition | Chapters about managing threads, sharing data, synchronizing operations, and the memory model. It is the main book of this phase. |
| Bjarne Stroustrup, *A Tour of C++*, 3rd edition | "Concurrency" |
| cppreference.com | "Concurrency support library": `std::jthread`, `std::stop_token`, `std::mutex`, `std::scoped_lock`, `std::condition_variable_any`, `std::atomic`, `std::latch` |
| The C++ Core Guidelines | Section "CP: Concurrency and parallelism" |
| Dear ImGui wiki and `imgui_demo.cpp`; the example `examples/example_sdl3_sdlrenderer3` in the Dear ImGui repository | The frame loop and the widgets (if you selected Dear ImGui) |
| SDL3 wiki (wiki.libsdl.org/SDL3) | `SDL_Init`, windows, events, the renderer |
| Qt documentation, "Threads and QObjects" and "Signals and Slots" | Only if you selected Qt |
| Chess Programming Wiki | "Iterative Deepening", "Time Management", "Transposition Table", "Lazy SMP", "Shared Hash Table" |

## Topics

### 6.1 Concurrency and parallelism

- **Concurrency:** several tasks make progress in the same time period. The tasks can wait for each other, for I/O, or for the user. Example: the GUI reacts to clicks while the engine thinks.
- **Parallelism:** several computations run at the same time on several CPU cores, to finish faster. Example: four search threads.
- **Use threads for CPU-bound work** (the search, perft, a large import). Use asynchronous I/O for many slow I/O operations (phase 7: thousands of network connections need no thousand threads).
- **Amdahl's law:** if 10 % of the work is sequential, the speedup can never be more than 10 times, with any number of cores. Measure the sequential part.
- Concurrency adds a new kind of defect: the result depends on the timing. These defects are rare, hard to reproduce, and hard to find with tests. Keep the concurrent part of a design small, and keep shared state to a minimum.

### 6.2 Threads

```cpp
#include <thread>

std::jthread worker([](std::stop_token stop) {
    while (!stop.stop_requested()) {
        do_one_step();
    }
});
// ...
worker.request_stop();   // ask the thread to stop
// The destructor of std::jthread requests a stop and then joins.
```

- **`std::jthread`** (C++20) joins automatically in its destructor, and supports cooperative cancellation with a `std::stop_token`. Prefer it to `std::thread`.
- A `std::thread` that is still joinable in its destructor calls `std::terminate`. You must call `join()` (wait for the end) or `detach()`.
- **Never detach a thread.** A detached thread can still run when `main` returns and the objects that it uses are destroyed.
- **Arguments are copied** into the thread. To pass a reference, use `std::ref(x)`, and make sure that `x` lives longer than the thread. A lambda that captures by reference has the same risk.
- **An exception that leaves the thread function calls `std::terminate`.** Catch exceptions in the thread, and send them to the waiting thread (for example with `std::promise::set_exception`, topic 6.7).
- `std::thread::hardware_concurrency()` gives the number of hardware threads (it can return 0 if unknown).
- **The `std::jthread` destructor requests a stop before it joins.** If the thread checks the stop token, the result of a short-lived `std::jthread` depends on the timing:

  ```cpp
  int result = 0;
  {
      std::jthread worker([&result](std::stop_token stop) {
          if (!stop.stop_requested()) {
              result = 42;
          }
      });
  }   // here: request_stop(), then join()
  // result can be 0 or 42
  ```

  The course found this defect in its own toolchain check program. Call `join()` explicitly when you need the result, or do not check the token for work that must complete.

### 6.3 The memory model and data races

- **A data race:** two threads access the same memory location at the same time, at least one access is a write, and no synchronization orders them. **In C++, a data race is undefined behavior** for the whole program, not only a wrong value.
- **Synchronization** creates a **happens-before** relation: everything that a thread did before it released a mutex is visible to the thread that takes the mutex next. The same is true for a write and a read of an atomic variable with the default (sequentially consistent) or the acquire and release memory orders, and for the start and the join of a thread.
- Without synchronization, the compiler and the CPU can reorder memory operations. A thread can see the writes of another thread in a different order, or never.
- `volatile` is **not** for threads. It is for memory-mapped hardware.
- **ThreadSanitizer (TSan)** finds data races at run time: `-fsanitize=thread` with GCC or Clang on Linux and macOS (the `tsan` preset of the starter project). It is not available with MSVC; use WSL2 or a CI job on Linux. TSan finds only the races that happen in the run, so run the tests many times and with stress.

### 6.4 Shared state: mutexes and condition variables

```cpp
class Counter {
public:
    void increment() {
        std::lock_guard lock{mutex_};
        ++value_;
    }
    int value() const {
        std::lock_guard lock{mutex_};
        return value_;
    }
private:
    mutable std::mutex mutex_;   // mutable: value() is const, but it locks
    int value_ = 0;
};
```

- `std::mutex` protects data. Lock it with RAII: `std::lock_guard` (simple), `std::unique_lock` (can unlock, needed for condition variables), `std::scoped_lock` (several mutexes at the same time, without deadlock).
- **Keep the data and its mutex together** in one class, and never give out references to the protected data.
- **Hold a lock for a short time.** Do not do I/O, call unknown code (callbacks), or wait for another thread while you hold a lock.
- **Deadlock:** thread 1 holds lock A and waits for B; thread 2 holds B and waits for A. Prevent it: take several locks with one `std::scoped_lock`, always take locks in the same order, or design so that a thread needs only one lock.
- `std::shared_mutex` permits many readers or one writer. It is useful only when reads are many and long. Measure first.
- **Condition variables** let a thread wait until a condition is true:
  - Always wait with a **predicate**: `cv.wait(lock, [&] { return !queue_.empty(); });`. A wait can end without a notification (a "spurious wakeup"), and a notification before the wait is lost.
  - Change the condition while you hold the mutex, then notify.
  - `std::condition_variable_any` can wait with a `std::stop_token`: the wait ends when a stop is requested.

### 6.5 Atomics

- `std::atomic<T>` gives indivisible operations on one value: `load`, `store`, `fetch_add`, `exchange`, `compare_exchange_weak`. No data race is possible on the atomic itself.
- The default memory order is `std::memory_order_seq_cst`: the simplest and the safest. Use `memory_order_relaxed` only for values where the order does not matter (for example a statistics counter of nodes). Use acquire and release only when you can explain the happens-before relation that you need. Read the chapter "The C++ memory model and operations on atomic types" of *C++ Concurrency in Action* before you use other orders.
- An atomic is not enough when an invariant covers more than one variable. Two atomics cannot change together. Use a mutex.
- **False sharing:** two threads write different variables that are in the same cache line (usually 64 bytes). The CPU cores pass the line back and forth, and the program gets slow. Put data of each thread in its own cache line with `alignas(64)`. (`std::hardware_destructive_interference_size` gives the value, but not every compiler and standard library defines it.)
- **Lock-free programming** is very hard to do correctly. Use the standard library and well-tested libraries. In the chess engine, the transposition table is the only place where the course discusses a lock-free design, and a lock per group of entries is a correct alternative.

### 6.6 Message passing

- Threads that send messages to each other through a queue share less state than threads that lock shared objects. The design is easier to understand.
- **A bounded queue** blocks the producer when it is full. This is **backpressure**: a fast producer cannot fill the memory.

  ```cpp
  #include <condition_variable>
  #include <cstddef>
  #include <deque>
  #include <mutex>
  #include <optional>
  #include <stop_token>

  template <typename T>
  class BoundedQueue {
  public:
      explicit BoundedQueue(std::size_t capacity) : capacity_{capacity} {}

      // Waits while the queue is full. Returns false if a stop was requested.
      bool push(T value, std::stop_token stop) {
          std::unique_lock lock{mutex_};
          if (!not_full_.wait(lock, stop, [this] { return items_.size() < capacity_; })) {
              return false;
          }
          items_.push_back(std::move(value));
          not_empty_.notify_one();
          return true;
      }

      // Waits while the queue is empty. Returns nothing if a stop was requested.
      std::optional<T> pop(std::stop_token stop) {
          std::unique_lock lock{mutex_};
          if (!not_empty_.wait(lock, stop, [this] { return !items_.empty(); })) {
              return std::nullopt;
          }
          T value = std::move(items_.front());
          items_.pop_front();
          not_full_.notify_one();
          return value;
      }

      // Does not wait. For a UI thread that checks the queue in each frame.
      std::optional<T> try_pop() {
          std::lock_guard lock{mutex_};
          if (items_.empty()) {
              return std::nullopt;
          }
          T value = std::move(items_.front());
          items_.pop_front();
          not_full_.notify_one();
          return value;
      }

  private:
      std::mutex mutex_;
      std::condition_variable_any not_full_;
      std::condition_variable_any not_empty_;
      std::deque<T> items_;
      std::size_t capacity_;
  };
  ```

- **A worker pool:** N threads take tasks from one queue. The standard library has no thread pool. Write a small one (exercise 6.4), or use one from a library (for example `boost::asio::thread_pool`, phase 7).
- **The actor pattern:** one thread owns some state and handles messages from a queue, one at a time. Other threads never touch the state. The search manager of the chess engine can be an actor.

### 6.7 Tasks and futures

- `std::async(std::launch::async, f, args...)` runs `f` on a new thread and returns a `std::future`. `future.get()` waits and gives the result, or throws the exception of the task.
- **The destructor of a `std::future` from `std::async` waits for the task.** `std::async(...);` without a variable runs synchronously.
- `std::promise` and `std::future` send one value (or one exception) from one thread to another.
- **Parallel algorithms** (C++17): `std::sort(std::execution::par, ...)`. The support differs: MSVC supports them; GCC needs the Intel TBB library; libc++ support is partial. They are optional in the course.
- **Coroutines** (C++20) are functions that can suspend and continue later (`co_await`, `co_yield`, `co_return`). The standard library gives almost no support for them: you need a library such as Asio (phase 7). `std::generator` (C++23) makes lazy sequences with `co_yield`, but not all supported compilers have it yet.

### 6.8 Cancellation and shutdown

- **Cancellation in C++ is cooperative.** A thread cannot be killed safely. The work checks a stop token at regular points, and ends cleanly.
- `std::stop_source` requests the stop; `std::stop_token` checks it; `std::stop_callback` runs a function when the stop is requested (for example to wake a blocking wait).
- Check the token often enough for the required reaction time, but not so often that it costs speed. A chess search checks it every few thousand nodes.
- **Shutdown order:** stop the producers, then the consumers; request the stop of all threads; join all threads; then destroy the shared objects. A thread must never outlive the data that it uses. Owning the threads in the same object as the data, as the last members (so that they are destroyed first), is a simple way to get this order.
- Handle Ctrl+C: `std::signal` with a handler that only sets an atomic flag (a signal handler can do very little safely), or the signal support of your framework (Asio `signal_set` in phase 7, SDL quit events, Qt).

### 6.9 User interfaces: the event loop and the UI thread

- A desktop GUI runs an **event loop** on one thread, the **UI thread**: it reads input events (mouse, keyboard, window), updates the state, and draws the window, many times per second.
- **The UI thread rule:** never do slow work on the UI thread. If an event handler takes 3 seconds, the window does not redraw and does not react for 3 seconds. The operating system can mark it as "not responding". Run slow work on worker threads.
- **The second rule:** most GUI libraries are not thread-safe. Only the UI thread may touch UI objects. Worker threads send results to the UI thread: through a queue that the UI thread reads in each frame, or through a mechanism of the library (Qt: a signal with a queued connection; SDL: `SDL_PushEvent` with a user event).

**Two GUI models:**

| | Immediate mode (Dear ImGui) | Retained mode (Qt Widgets, QML) |
|---|---|---|
| How | In each frame, the code calls functions that describe the whole UI: `if (ImGui::Button("Stop")) { ... }` | The program makes widget objects one time. The library keeps them, and calls the program when an event occurs (signals and slots). |
| State | In your program. The UI has almost no state. | In the widgets and in your program. They must stay synchronized. |
| Redraw | The whole UI in each frame (usually 60 times per second) | Only when something changes |
| Good for | Tools, debug views, fast development | Applications with many forms, a native look, accessibility |

**A Dear ImGui frame loop with SDL3** has these parts (check the example `example_sdl3_sdlrenderer3/main.cpp` of your Dear ImGui version for the exact code):

1. Start: `SDL_Init`, make a window and a renderer, `ImGui::CreateContext`, and initialize the two backends (`ImGui_ImplSDL3_InitForSDLRenderer`, `ImGui_ImplSDLRenderer3_Init`).
2. In each frame:
   1. Read all SDL events with `SDL_PollEvent`. Give each event to `ImGui_ImplSDL3_ProcessEvent`. End the loop on a quit event.
   2. Read the results of the worker threads from the queue (`try_pop`, without a wait).
   3. Start a frame: `ImGui_ImplSDLRenderer3_NewFrame`, `ImGui_ImplSDL3_NewFrame`, `ImGui::NewFrame`.
   4. Describe the UI: windows, buttons, text, the board. Button clicks send commands to the worker threads.
   5. Render: `ImGui::Render`, clear the screen, `ImGui_ImplSDLRenderer3_RenderDrawData`, `SDL_RenderPresent`.
3. End: stop and join the workers, shut down the backends and the context, destroy the renderer and the window, `SDL_Quit`. Use RAII wrappers or `std::unique_ptr` with custom deleters for the SDL objects.

### 6.10 Model, view, and the observer pattern

- **Separate the model from the view.** The model is the state of the application (the game, the analysis) and its rules. The view draws the model and turns input into commands. With Dear ImGui, the view is the code in the frame loop. With Qt, the view is the widgets.
- The view does not contain rules: it asks the model (or the use cases of the core) for the legal moves, and sends a "play this move" command.
- **Observer:** the model tells its observers about changes. In a multi-threaded design, an observer that the engine calls on a search thread must not touch the UI. It puts an event into the queue, and returns at once.
- The chess GUI is a **driving adapter** of the hexagonal architecture (phase 5): it calls the same use cases as the CLI. The engine is behind a port, so that phase 7 can replace the local engine with a remote engine.

### 6.11 Test concurrent code

- **Make the concurrent part small,** and test the logic without threads. The search algorithm, the time management rule, and the queue logic can be tested in one thread.
- **Inject the time** (the clock from phase 5). Do not use `sleep` in tests: a test with sleeps is slow, and it fails on a slow CI computer.
- **Synchronize tests explicitly:** `std::latch` (C++20) waits until N threads arrive; a `std::promise` signals one event.
- **Stress tests:** run a concurrent operation many times with many threads, under ThreadSanitizer. Run them in a separate test label, because they are slow.
- A concurrent test that fails sometimes is a real defect, not a "flaky test". Do not ignore it.

## Exercises

Make the project `labs/phase-6-concurrency/`. Run the tests of each exercise under ThreadSanitizer (the `tsan` preset) if your platform supports it; else run them in WSL2 or in a Linux CI job later.

### Exercise 6.1: Parallel word count

1. Generate 100 text files of 1 MB each.
2. Count the words of all files sequentially. Measure the time in a release build.
3. Count them with one `std::jthread` for each group of files, and merge the results. Measure with 2, 4, and 8 threads.
4. Explain the speedup. Where is the sequential part?

### Exercise 6.2: Data races (core)

1. Two threads increment a shared `int` 1 000 000 times each, without synchronization. Run it several times. Run it under ThreadSanitizer. Read the report.
2. Fix it with a `std::mutex`, then with a `std::atomic<int>`, then with a local counter in each thread and one addition at the end. Measure the three versions.
3. Explain why the third version is the fastest. Which design principle does it show?

### Exercise 6.3: Deadlock

1. Write a `transfer(Account& from, Account& to, int amount)` that locks the mutex of each account, one after the other. Start two threads that transfer in opposite directions many times. Observe the deadlock (attach the debugger, and look at the stack of each thread).
2. Fix it with `std::scoped_lock`. Explain why it cannot deadlock.

### Exercise 6.4: A worker pool with backpressure (core)

1. Write the `BoundedQueue` from topic 6.6 with tests (in one thread first).
2. Write a `WorkerPool` with N `std::jthread` workers that take tasks (`std::function<void()>` or a move-only alternative) from a bounded queue.
3. `submit` blocks when the queue is full. The destructor stops the workers cleanly.
4. Test: 10 000 tasks that each increment an atomic counter; the counter is 10 000 at the end. Test the shutdown while tasks wait. Run the tests under ThreadSanitizer.

### Exercise 6.5: Cancellation (core)

1. Write a function that computes prime numbers up to N, and checks a `std::stop_token` every 10 000 numbers. It returns the primes found so far and a flag "complete" or "stopped".
2. Start it on a `std::jthread`. Stop it after 100 ms (in the test, with a `std::latch` or a callback, not a sleep). Check that it stops quickly.
3. Write the defect from topic 6.2 (a short-lived `std::jthread` that checks the token). Show that the result changes between runs. Fix it.

### Exercise 6.6: Atomics and false sharing

1. Four threads each increment their own counter 100 000 000 times. Put the four counters in an array of `std::atomic<long long>`. Measure.
2. Put each counter in a struct with `alignas(64)`. Measure again. Explain the difference.

### Exercise 6.7: The first GUI (core)

Add the GUI library that you selected (see [../mentor/toolchain-selection.md](../mentor/toolchain-selection.md) and [../topics/external-libraries.md](../topics/external-libraries.md)).

1. Make a window with a button "Compute" and a text with a counter that increments in each frame (so that you can see when the UI freezes).
2. "Compute" calls the prime function from exercise 6.5 for a large N on the UI thread. Click it. What happens to the counter and the window?
3. Move the computation to a worker thread. Show a progress bar (the worker sends progress events through a queue) and a "Stop" button.
4. Close the window during a computation. The program must end cleanly, without a crash and without a leak (check with AddressSanitizer).

### Exercise 6.8: Test with a manual clock

1. Write a `Timer` class that calls a callback when a deadline passes, using an injected clock and a `check()` function that the loop calls.
2. Test it with the manual clock from phase 5: advance the time, call `check()`, and assert the callback. No test sleeps.
3. Use the same idea for the time management of the chess engine in stage 4.

## Project: Chess engine, stage 4

See [../projects/chess-engine.md](../projects/chess-engine.md), stage 4.

## Done criteria

- [ ] I can explain the difference between concurrency and parallelism, and Amdahl's law.
- [ ] I can explain why a data race is undefined behavior in C++, and find one with ThreadSanitizer.
- [ ] I can protect shared state with a mutex, wait with a condition variable and a predicate, and prevent deadlocks.
- [ ] I can say when an atomic is enough and when it is not, and explain false sharing.
- [ ] I can build a bounded queue and a worker pool with clean shutdown.
- [ ] I can cancel long work with a stop token, and I know the behavior of the `std::jthread` destructor.
- [ ] My GUI never blocks on slow work, and worker threads never touch UI objects.
- [ ] My concurrent tests use no sleeps and pass under ThreadSanitizer.
- [ ] Chess engine stage 4 is complete.

## Next

[Phase 7: Network services and persistence](phase-7-network-services.md)
