# Projects and Tasks

This directory contains project specifications and task documents. A task document describes one piece of work: its goal, its steps, and its acceptance criteria. Use [../templates/task-template.md](../templates/task-template.md) for new tasks.

## File names

- Main project: `chess-engine.md`
- A different main project domain: `<domain>.md`, for example `ledger.md` or `key-value-store.md` (see [../mentor/project-selection.md](../mentor/project-selection.md))
- Side project: `<short-name>.md`, for example `chat-server.md`
- Task: `task-<phase>-<number>-<short-name>.md`, for example `task-4-01-uci-loop.md`

## Main project

| Project | Phases | Document |
|---|---|---|
| Chess engine with a CLI, a desktop GUI, and an HTTP interface (REST, SSE, WebSocket) | 1–9 | [chess-engine.md](chess-engine.md) |

Alternative domains for the main project (the ledger, the key-value store, the order book) are described in [../mentor/project-selection.md](../mentor/project-selection.md).

## Side projects

Side projects give more practice. Do them when you want more practice in a phase, or between phases. Make a separate document here when you start a side project.

| Project | Phase | Content |
|---|---|---|
| Text adventure | 1 | Rooms and items as classes, `std::variant` for commands, a state machine |
| A small string and vector class | 2 | RAII, the rule of five, move semantics, exception safety, tests under AddressSanitizer |
| Markdown to HTML converter | 2–3 | `std::string_view`, ranges, a parser that does not copy its input |
| A small JSON parser | 3–4 | `std::variant` for the values, recursion, `std::expected` errors with positions |
| `wc`, `head`, and `grep` clones | 4 | Command-line tools, `std::filesystem`, errors, CLI tests |
| Static site generator | 4–5 | Templates, a file tree, the open/closed principle for output formats |
| Thread pool with a work queue | 6 | `std::jthread`, condition variables, stop tokens, ThreadSanitizer |
| Conway's Game of Life with a GUI | 6 | Dear ImGui, a simulation thread, the UI thread rule |
| Multi-user chat server over TCP | 7 | Asio, coroutines, broadcast, graceful shutdown |
| URL shortener service | 7 | Beast, SQLite, configuration, rate limits |
| A small header-only library with a release | 8 | API design, documentation, semantic versioning, CI, packaging for `find_package` |
| Python extension | 9 | nanobind or pybind11, the C++ and Python boundary, a performance comparison |

## Tasks

| Task | Phase | Status |
|---|---|---|
| *(no tasks yet)* | | |
