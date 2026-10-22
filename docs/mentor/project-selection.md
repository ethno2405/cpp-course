# Project Selection

This document tells the AI mentor how to help the learner select the domain of the main project, and how to adapt the course to the selected domain. The learner makes the decision. The mentor suggests.

The course documents use the reference project: a chess engine with a command-line interface, a desktop user interface, and an HTTP interface (`docs/projects/chess-engine.md`). A learner can build a different application with the same stages, if the domain motivates them more. The language features, the design principles, and the practices stay the same. Only the domain changes.

## When to do the selection

| Situation | Action |
|---|---|
| At the end of the first assessment | Offer the selection. The learner can postpone it. Until then, use the chess engine. |
| The learner asks ("I want to build something different") | Do the selection. |
| The learner wants to change the domain after stage 0 | Do the selection again. Tell the learner the cost: they rewrite the earlier stages for the new domain, or continue the old code and change only the new stages. Record the old domain in the notes. |

Recommend that the learner keeps the domain after stage 1. A change after stage 3 costs much time.

## Step 1: Ask

Ask these questions. Use the answers that are already in the profile, and do not ask them again.

1. Do you want the easiest path through the documents (the chess engine), or an application that is closer to your interests?
2. Is there an application that you want to use yourself?
3. Is there a domain from your work that you know well? (A known domain lets you focus on the code. Do not use confidential data or code from your employer.)
4. Do you know the rules of chess? (The learner does not need to play well. The rules are in `docs/projects/chess-engine.md`. A learner who does not like chess can select a different domain.)

## Step 2: Suggest

1. Put the chess engine first, unless the answers give a clear reason for a different domain.
2. Suggest 1–2 alternatives from the table below, or a domain that the learner proposes.
3. Check a proposed domain against the requirements below. If it does not meet a requirement, tell the learner which stage gets harder, and suggest a change to the domain.

### Requirements for a domain

The domain must give the learner the same problems as the chess engine. Each stage needs these elements:

| Element | Stage | Chess engine | Why the course needs it |
|---|---|---|---|
| Value types with rules | 0 | `Square` (64 values), `Piece`, `Move` (from, to, promotion piece) | Strong types, `enum class`, invariants, "make illegal states unrepresentable" |
| An aggregate with invariants | 0 | `Position`: one king of each color, a side to move, castling rights, an en passant square | Class design, private members, validation at construction |
| A text format to parse and write | 0 | FEN (Forsyth–Edwards Notation) | Parsing, `std::string_view`, errors with a position in the text |
| A computation with a known correct result | 1 | Perft: the number of legal move sequences to a depth, with published values | Tests against an oracle, debugging by division of the problem |
| A hot path | 1, 6 | Move generation and search | Templates, `constexpr`, value semantics, later measurement and optimization |
| A text protocol with state | 2 | UCI (Universal Chess Interface) | Input and output, a state machine, robust handling of bad input |
| A second, more complex text format | 2 | PGN (Portable Game Notation) with SAN (Standard Algebraic Notation) moves | Error design, `std::expected`, files |
| Variation points | 3 | Evaluation functions, opening books, game stores | The open/closed principle, strategy, dependency inversion |
| A long computation that the user can stop | 4 | A search with a time limit and progress information | Threads, stop tokens, progress events, cancellation |
| A live view | 4 | A board in a window, with the analysis of the engine while it searches | The UI thread, an event loop, the observer pattern |
| Resources for an HTTP API | 5 | Games, positions, moves, analysis | REST design, JSON |
| A stream from the server to the client | 5 | The analysis of a running search (SSE) | Server-Sent Events, backpressure |
| A two-way session | 5 | A live game against the engine (WebSocket) | WebSocket, session state, concurrency between I/O and work threads |
| Persistence | 5 | Finished games and an analysis cache in SQLite | SQL, transactions, migrations, RAII for a C API |
| Properties for tests | 6 | Make and unmake of a move restores the position; the FEN round trip; perft is the same for two board representations | Property-based tests, fuzzing |

### Alternative domains

| Element | Personal finance ledger | Key-value store | Order book (market simulator) |
|---|---|---|---|
| Value types with rules | `Money` (minor units and a currency; no addition of different currencies), `AccountName` | `Key` (not empty, maximum length), `Ttl` (no negative values) | `Price` (in ticks, no floating point), `Quantity`, `OrderId` |
| Aggregate with invariants | `Ledger`: unique account names; a transaction only for a known account in its currency | `Store`: an expired key is not visible | `OrderBook`: after matching, the best bid is lower than the best ask |
| Text format 1 | CSV bank statement | The command syntax: `SET key value EX 10` | A CSV file of orders |
| Known correct result | Hand-computed balances; the sum of transactions equals the sum of balances | A model test against `std::map` | Hand-computed matching scenarios |
| Hot path | Import and reports for one million transactions | `GET` and `SET` throughput | Matching throughput and latency |
| Text protocol with state | A line-based command mode (`ledger shell`) | The command protocol on stdin, later on TCP | A simple order entry protocol (FIX-like key=value messages) |
| Format 2 | A second bank format (semicolons, `DD.MM.YYYY`, decimal comma) | A snapshot file format | A market data replay format |
| Variation points | Import formats, categorization rules, stores | Storage engines (in memory, append-only log), eviction policies (LRU, LFU) | Matching algorithms (price-time, pro-rata), order types |
| Long computation with stop | A large import or report with progress | Compaction of the log | Replay of a large market data file |
| Live view | A transaction table with filters and import progress | A key browser with live statistics | A price ladder that updates live |
| HTTP resources | Accounts, transactions, reports | Keys, statistics | Orders, book snapshots, trades |
| Server stream (SSE) | Import progress, balance changes | Key change notifications ("watch") | Market data (book changes and trades) |
| Two-way session (WebSocket) | A live session that sends new transactions and receives the changes of other clients | Publish and subscribe | An order entry session with execution reports |
| Persistence | SQLite | The append-only log and snapshots (SQLite for statistics) | Orders and trades in SQLite |
| Properties for tests | `Money` round trip, import idempotence | A replay of the log gives the same state | Matching keeps the total quantity; the book is never crossed |

Do not invent API or protocol details of a real service. If the learner wants data from an external service (for example exchange rates or market data), ask them to check its documentation: the URL, the limits, the terms of use, and whether it needs a key. In tests, always use a fake server, not the real service.

## Step 3: Record

When the learner selects a domain, fill in the "Project" section of `learner/profile.md`:

- The domain and a short description of the application
- The mapping of each element in the table "Requirements for a domain" to the learner's domain

## Adapt the course to the domain

In every session, if the domain in the profile is not the chess engine:

1. Read the phase document and `docs/projects/chess-engine.md` as usual.
2. Before you give the learner a project-specific detail (a type name, a command, a file format, an acceptance criterion), translate it to the learner's domain with the mapping in the profile.
3. Keep the difficulty the same. If a translated feature is easier than the chess feature, add a rule that gives the same problem. Example: a key-value store has no published perft numbers, so use a model-based test against `std::map` with a fixed random seed and 100 000 operations as the oracle.
4. The exercises in the phase documents stay as they are. Only the project stages change.
5. If many learners use the same domain, suggest a project document for it in `docs/projects/` (for example `ledger.md`).

For the chess engine, use the documents as they are.
