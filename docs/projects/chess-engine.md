# Project: Chess Engine

The chess engine is the main project of the course. It starts as a few types and a text parser in phase 1. It ends in phase 8 as a tested, documented, and optimized application with three user interfaces: a command line with the UCI protocol, a desktop GUI, and an HTTP server with REST, Server-Sent Events (SSE), and WebSocket. Each stage adds features to the code from the previous stage. Do not start again from zero.

If your profile names a different project domain, the mentor translates this document (see [../mentor/project-selection.md](../mentor/project-selection.md)).

**The goal is good C++ and good design, not a strong engine.** Chess programming has no end: there is always a better search or evaluation. Each stage gives a fixed engine scope. Do only that scope. Phase 9 is the place for engine strength.

## Final system

```
Users            Driving adapters              Core                           Driven adapters
-----            ----------------              ----                           ---------------
Chess GUI   -->  chess-cli (UCI) ---+
Terminal    -->  chess-cli (play) --+
                                    +------->  chess_core                <--  chess_eval        (evaluators)
Window      -->  chess-gui ---------+          types, rules, FEN, SAN,   <--  chess_book        (opening book file)
                                    |          move generation, search,  <--  chess_store_pgn   (PGN files)
Browser,    -->  chess-server ------+          use cases, ports          <--  chess_store_sqlite (SQLite)
curl,            (REST, SSE, WS)                                         <--  system clock, random source
websocat                                                                 
                 chess-gui --> remote engine adapter --> WebSocket --> chess-server

All library dependencies point to chess_core. Each executable (chess-cli, chess-gui, chess-server)
is a composition root: only its main function connects the concrete adapters.
```

## Domain

| Concept | Description |
|---|---|
| `Color` | White or black |
| `PieceType`, `Piece` | Pawn, knight, bishop, rook, queen, king; a piece is a type and a color |
| `Square` | One of the 64 squares, `a1` to `h8`. A `Square` cannot hold an invalid value. |
| `Move` | A from square, a to square, and an optional promotion piece type. Special moves (castling, en passant) are recognized from the position. |
| `CastlingRights` | Which of the four castling moves are still permitted |
| `Position` | The board, the side to move, the castling rights, the en passant square, the halfmove clock (for the fifty-move rule), and the fullmove number. A `Position` always satisfies its invariants: exactly one king of each color, no pawns on the first or last rank, and the side that is not to move is not in check. |
| `Game` | A start position, the list of moves, and the result. It detects threefold repetition. |
| `Score` | A score in centipawns (1/100 of a pawn), or "mate in N" |
| `SearchLimits` | Depth, nodes, move time, or the clock times of both sides |
| `SearchInfo` | The progress of a search: depth, score, nodes, time, principal variation |

### Chess rules that you need

You do not need to play chess well. You need the exact rules. Read the FIDE Laws of Chess (handbook.fide.com), articles 1–5 and 9, and the Chess Programming Wiki pages "Castling", "En passant", and "Promotions". The rules that cause most defects in move generators:

- **Castling:** the king and the rook did not move; the squares between them are empty; the king is not in check; the king does not pass through or land on an attacked square. The rook can be attacked.
- **En passant:** only on the move directly after a pawn advanced two squares. An en passant capture can expose the king to a check along the rank, because two pawns leave the rank at the same time.
- **Promotion:** a pawn that reaches the last rank becomes a knight, a bishop, a rook, or a queen. Four different moves.
- **Pins and checks:** a legal move never leaves the own king in check.
- **Draws:** stalemate, the fifty-move rule (100 halfmoves without a capture or a pawn move), threefold repetition, insufficient material.

### Notation

| Notation | Example | Use |
|---|---|---|
| FEN (Forsyth–Edwards Notation) | `rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1` | One position in one line |
| UCI move (long algebraic) | `e2e4`, `e7e8q`, `e1g1` (castling) | The UCI protocol |
| SAN (Standard Algebraic Notation) | `e4`, `Nf3`, `exd5`, `O-O`, `e8=Q+`, `Qxf7#` | PGN files and the GUI move list |
| PGN (Portable Game Notation) | Tag pairs and SAN moves | Game files |

### Reference positions and perft values

Perft counts all legal move sequences of a given depth from a position. Correct counts prove that the move generator is correct (with very high probability). These values come from the "Perft Results" page of the Chess Programming Wiki. Put the positions in `labs/chess/tests/data/perft.txt` and use them in your tests.

| Name | FEN | Depth 1 | 2 | 3 | 4 | 5 |
|---|---|---|---|---|---|---|
| Start | `rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1` | 20 | 400 | 8 902 | 197 281 | 4 865 609 |
| Kiwipete | `r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1` | 48 | 2 039 | 97 862 | 4 085 603 | 193 690 690 |
| Position 3 | `8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 0 1` | 14 | 191 | 2 812 | 43 238 | 674 624 |
| Position 4 | `r3k2r/Pppp1ppp/1b3nbN/nP6/BBP1P3/q4N2/Pp1P2PP/R2Q1RK1 w kq - 0 1` | 6 | 264 | 9 467 | 422 333 | 15 833 292 |
| Position 5 | `rnbq1k1r/pp1Pbppp/2p5/8/2B5/8/PPP1NnPP/RNBQK2R w KQ - 1 8` | 44 | 1 486 | 62 379 | 2 103 487 | 89 941 194 |
| Position 6 | `r4rk1/1pp1qppp/p1np1n2/2b1p1B1/2B1P1b1/P1NP1N2/1PP1QPPP/R4RK1 w - - 0 10` | 46 | 2 079 | 89 890 | 3 894 594 | 164 075 551 |

Check the values against the wiki before you use them. If your count is wrong, use **perft divide**: print the perft count of each first move. Compare it with the divide output of a reference engine (for example Stockfish with `go perft <depth>`). Go into the first move with a wrong count, and repeat with one depth less. After a few steps you find the position and the move that your generator handles incorrectly.

## Stage 0: Domain model and FEN (phase 1)

**Code:** `labs/chess/` as one CMake project with a library target `chess_core`, an executable `chess`, and a test executable.

**Features**

- `Color`, `PieceType`, and `Piece` as `enum class` or small classes.
- `Square` as a class with a private index (0–63). Make it from a file and a rank, or from a text like `"e4"` (the text version returns `std::optional<Square>` or `std::expected`). Functions for the file, the rank, and the text.
- `Move` as a value type with `==`.
- `Position` with a mailbox board (`std::array` of 64 optional pieces), and the other fields from the domain table.
- **FEN parser:** `parse_fen(std::string_view)` returns a `Position` or an error that says what is wrong and where (the field and the character). Reject:
  - a wrong number of fields, ranks, or files;
  - an unknown piece character;
  - a number of kings that is not one for each color;
  - a pawn on the first or last rank;
  - a side to move that is not `w` or `b`;
  - castling rights that do not match the positions of the kings and rooks;
  - an en passant square that is not possible (for example on rank 4 when white is to move);
  - counters that are not numbers, or out of range.
- **FEN writer:** `to_fen(const Position&)`.
- **Board display:** an ASCII board with the files and the ranks, for example:

  ```text
    +-----------------+
  8 | r n b q k b n r |
  7 | p p p p p p p p |
  6 | . . . . . . . . |
  ...
  1 | R N B Q K B N R |
    +-----------------+
      a b c d e f g h
  ```

- `main` reads a FEN from the first argument (or uses the start position), and prints the board and the FEN. A wrong FEN prints the error on stderr and returns a non-zero exit code.

**Acceptance criteria**

- [ ] The FEN round trip (`to_fen(parse_fen(x)) == x`) works for all six reference positions.
- [ ] Each rejection rule has a test with a name that describes the rule.
- [ ] A `Square` cannot hold an invalid value: there is no public constructor from an unchecked integer.
- [ ] No `new`, `delete`, or raw array in the code.
- [ ] The build has no warnings. The tests pass under AddressSanitizer and UndefinedBehaviorSanitizer (or AddressSanitizer only with MSVC).

## Stage 1: Move generation and perft (phase 3)

**Code:** `labs/chess/`. The `chess_core` library grows.

**Features**

- **Attack tables:** compute the knight and king attacks for each square at compile time with `constexpr` functions. Sliding pieces (bishop, rook, queen) walk along the rays.
- **Move list:** a fixed-capacity container (for example a class with `std::array<Move, 256>` and a size) that satisfies the range concepts, so that range-based `for` loops and range algorithms work on it. The maximum number of legal moves in a chess position is 218.
- **Legal move generation** for all pieces, with castling, en passant, and the four promotions.
- **Make and unmake a move** (or copy-make: make a new position for each move; write the decision and its reason in your notebook; phase 5 asks for an ADR).
- `is_in_check`, and the game state: checkmate, stalemate, the fifty-move rule, and insufficient material (king against king, king and one minor piece against king).
- **Perft** and **perft divide**.
- New command: `chess perft <depth> [--fen <fen>] [--divide]` (parse the arguments by hand in this stage; phase 4 adds a library).

**Acceptance criteria**

- [ ] Perft is correct for the six reference positions to depth 4 in the normal test run, and to depth 5 in a slow test that runs only in the release preset (use a CTest label, for example `slow`).
- [ ] Each special rule (each castling side, en passant, the en passant pin on the rank, each promotion piece, castling through check) has a small test position with a test.
- [ ] The attack tables are `constexpr` and a `static_assert` checks one value of each table.
- [ ] The move list works with `std::ranges::count_if` and `std::ranges::find`.
- [ ] Perft at depth 5 from the start position takes less than 10 seconds in a release build. Write the time and the nodes per second in your notebook. Phase 8 makes it faster.

## Stage 2: Command-line engine, UCI, PGN, and search (phase 4)

**Code:** `labs/chess/`. The `chess` executable gets subcommands. New third-party library: CLI11.

**Features**

- **Commands,** with CLI11:

  | Command | Result |
  |---|---|
  | `chess show [--fen <fen>]` | Print the board and the FEN |
  | `chess perft <depth> [--fen <fen>] [--divide]` | Perft, with the time and the nodes per second |
  | `chess play [--fen <fen>] [--depth <n>] [--color white\|black] [--save <file.pgn>]` | Play against the engine in the terminal. The user types moves in SAN or in UCI notation. |
  | `chess pgn <file.pgn>` | Read all games in the file, check all moves, and print a summary: the tags, the number of moves, the result, and the final FEN |
  | `chess uci` | Run the UCI protocol on stdin and stdout |

- **SAN:** parse and write SAN moves, with disambiguation (`Nbd2`, `R1e1`), captures, castling (`O-O`, `O-O-O`), promotions (`e8=Q`), check (`+`), and checkmate (`#`).
- **PGN:** read and write games: the seven required tags (Event, Site, Date, Round, White, Black, Result), the move text with move numbers, comments in braces (skip them), and the result. Errors have a line and a column.
- **Zobrist hashing:** a 64-bit hash of each position, updated incrementally when a move is made. `Game` uses it to detect threefold repetition.
- **UCI protocol:** `uci`, `isready`, `ucinewgame`, `position startpos|fen <fen> [moves ...]`, `go depth <n>`, `go nodes <n>`, `go movetime <ms>`, `quit`. The engine answers `id name`, `id author`, `uciok`, `readyok`, `info ...`, and `bestmove`. Unknown commands are ignored, as the protocol requires. Write the protocol code for `std::istream` and `std::ostream`, so that tests can use string streams.
- **Search, version 1:** negamax with alpha-beta pruning, a fixed depth, a material evaluation (pawn 100, knight 320, bishop 330, rook 500, queen 900), mate scores, and a quiescence search over captures. Captures first in the move order. In this stage, `go movetime` checks the time inside the search (one thread).
- **Errors:** `std::expected` with error types for FEN, SAN, PGN, and UCI input (see phase 4). Exceptions only for programming errors at boundaries that you cannot handle locally.
- **Documentation:** each public type and function of `chess_core` has a comment. A `README.md` describes the commands.

**Acceptance criteria**

- [ ] No user input makes the program crash or show undefined behavior. Wrong input gives a clear message on stderr and an exit code that is not 0 (except in UCI mode, where the engine must continue).
- [ ] PGN and SAN errors show the line, the column, and the wrong text.
- [ ] The engine works in a real chess GUI (for example Cute Chess, En Croissant, or Arena): add it as a UCI engine and play one game. Write the GUI and the result in your notebook.
- [ ] UCI tests run with string streams, without a process.
- [ ] The engine finds the mate in the test positions "mate in 1" and "mate in 2" (make 3 positions of each kind, or take them from a puzzle collection with a free license).
- [ ] `main.cpp` has fewer than 60 lines.

## Stage 3: Hexagonal architecture (phase 5)

**Code:** `labs/chess/` with several library targets.

**Features**

- Split the project into these targets:

  | Target | Responsibility | Depends on |
  |---|---|---|
  | `chess_core` | Domain types, rules, FEN, SAN, PGN text, move generation, search, use cases, ports | The standard library only. No files, console, network, GUI, or database. |
  | `chess_eval` | Evaluator implementations | `chess_core` |
  | `chess_book` | The opening book adapter (reads a book file) | `chess_core` |
  | `chess_store_pgn` | The game store port for a directory of PGN files | `chess_core` |
  | `chess_uci` | The UCI protocol adapter on streams | `chess_core` |
  | `chess` (executable) | The commands. The composition root. | All targets above, CLI11 |

- **Ports** (interfaces that `chess_core` defines):

  | Port | Purpose | Implementations |
  |---|---|---|
  | `Evaluator` | The static score of a position | Material (stage 2), piece-square tables (new), fakes in tests |
  | `OpeningBook` | Candidate moves for a position | Text book file, empty book, fakes |
  | `GameStore` | Save, load, and list games | PGN directory, in-memory store for tests |
  | `Clock` | The current time for the search | System clock, manual clock for tests |
  | `RandomSource` | Random numbers for the book move selection | Seeded generator, fixed sequence for tests |
  | `SearchObserver` | Receives `SearchInfo` during a search | UCI output, test recorder (the GUI comes in stage 4) |

- **A second evaluator:** piece-square tables (a bonus or penalty for each piece type on each square). Add it **without a change to `chess_core`**. Select it with the UCI option `setoption name Evaluator value pst`.
- **Opening book:** a text file with one line for each opening, as UCI moves from the start position, for example `e2e4 e7e5 g1f3 b8c6`. The book adapter builds a map from the Zobrist hash to the candidate moves. UCI option `OwnBook`.
- **Game store:** `chess games list`, `chess games show <id>`, and `chess play --save` uses the store.
- **Use cases** in the core, for example an `Engine` class (new game, set position, apply move, best move with limits) and a `GameService` (save the finished game). The adapters call only the use cases.
- **Test doubles:** an in-memory game store, a manual clock, and a fixed random source. **Contract tests** for the `GameStore` port run against the in-memory store and the PGN store.
- **ADRs** in `labs/chess/docs/adr/`: at least the target structure, the form of the `Evaluator` port (a virtual function or a template parameter; it is in the hot path, so measure), and copy-make or make/unmake.

**Acceptance criteria**

- [ ] `chess_core` links no third-party library and includes no header for files, streams, threads, or the console, except `<iosfwd>` if a port needs it. The build files and `cmake --graphviz` prove the dependency direction.
- [ ] The commit that adds the piece-square evaluator does not change `chess_core`.
- [ ] The use cases have tests that use only fakes. No core test touches the file system.
- [ ] The contract tests pass for both game stores.
- [ ] No test depends on the real time or on unseeded random numbers.
- [ ] The perft speed did not get worse by more than 10 % (measure before and after the change of the `Evaluator` form).

## Stage 4: Concurrent search and desktop GUI (phase 6)

**Code:** `labs/chess/`. New executable: `chess-gui`. New third-party libraries: Dear ImGui and SDL3 (or Qt 6, see the [toolchain selection](../mentor/toolchain-selection.md)).

**Search features**

- **Iterative deepening:** search depth 1, 2, 3, ... until a limit stops the search. Send a `SearchInfo` to the observer after each depth.
- **Time control:** `go wtime <ms> btime <ms> winc <ms> binc <ms> [movestogo <n>]`, `go movetime <ms>`, and `go infinite`. A simple rule is enough: use about 1/30 of the remaining time plus the increment.
- **Search on a worker thread:** the UCI loop stays responsive while the engine searches. `stop` ends the search within 50 ms, and the engine still sends `bestmove`. Use `std::jthread` and `std::stop_token`.
- **Transposition table:** a fixed-size hash table (UCI option `Hash` in MB) with entries for the Zobrist key, the depth, the score, the bound type, and the best move.
- **Lazy SMP:** UCI option `Threads`. All threads search the same position and share the transposition table. The table access must be free of data races (for example, store each entry as atomic words, and check the key; or use one lock for each group of entries; write the decision in an ADR).
- **Parallel perft:** split the first moves across threads. Measure the speedup.

**GUI features** (`chess-gui`)

- A board with the pieces (Unicode chess symbols first; a piece set with a free license later, recorded in the third-party list), and the coordinates.
- Move input by click or by drag. The legal target squares show when the user selects a piece. A dialog for the promotion piece.
- Buttons: new game, flip the board, take back a move, engine plays white or black or none, analyze, stop.
- A FEN field to load a position, and a field that shows the FEN of the current position.
- The move list in SAN.
- An analysis panel that updates while the engine searches: depth, score, nodes, nodes per second, and the principal variation in SAN.
- **The UI thread never waits for the engine.** The engine runs on its own threads. Search events go to the UI through a thread-safe queue that the UI reads in each frame (or through the event mechanism of Qt). Model and view are separate: the GUI calls the same use cases as the CLI.

**Acceptance criteria**

- [ ] ThreadSanitizer reports no data race in the tests and in a 30-second search with 4 threads (run on Linux, macOS, WSL2, or in CI).
- [ ] The GUI stays responsive during a 10-second search: it redraws, and the stop button works within 50 ms.
- [ ] Every thread ends cleanly when the user closes the window or sends `quit`. No thread is detached.
- [ ] With `Threads=4`, the search reaches a greater depth in the same time than with `Threads=1` on at least 4 of 6 test positions. The measurements are in `labs/chess/docs/performance.md`.
- [ ] In a 60-game match against the stage 3 version at 10 seconds plus 0.1 seconds per move (for example with the tool `fastchess` or `cutechess-cli`), the engine loses no game on time and plays no illegal move.
- [ ] `chess_core` does not include any GUI header. The GUI code is in its own target.

## Stage 5: HTTP, SSE, WebSocket, and database (phase 7)

**Code:** `labs/chess/`. New executable: `chess-server`. New targets: `chess_store_sqlite`, `chess_http`, and a remote engine adapter for the GUI. New third-party libraries: Boost.Asio, Boost.Beast, nlohmann/json, SQLite, spdlog.

**REST API**

| Method and path | Result |
|---|---|
| `GET /health` | 200 when the server and the database work |
| `POST /games` | Make a game. The body can give a start FEN, the engine color, and a time control. Returns 201 with the game. |
| `GET /games`, `GET /games/{id}` | List games (with pagination), or one game: the FEN, the moves in SAN, the status, and the clocks |
| `POST /games/{id}/moves` | Play a move (`{"move": "e2e4"}` or SAN). Returns 422 for an illegal move. |
| `GET /games/{id}/pgn` | The game as PGN (`application/x-chess-pgn`) |
| `POST /positions/legal-moves` | The legal moves of a FEN |
| `POST /analyses` | Start an analysis of a FEN with a depth or a move time. Returns 201 with the analysis identifier. |
| `DELETE /analyses/{id}` | Stop an analysis |

**Server-Sent Events**

- `GET /analyses/{id}/events` returns `Content-Type: text/event-stream` and keeps the response open.
- One event for each completed depth, and one at the end:

  ```text
  event: info
  data: {"depth":12,"score":{"cp":34},"nodes":1843322,"nps":2210000,"pv":["e4","e5","Nf3"]}

  event: bestmove
  data: {"move":"e4"}
  ```

- A comment line (`: keep-alive`) every 15 seconds when there is no event.
- When the client closes the connection, the server stops the analysis if no other client reads it.
- Optional: `GET /` serves a small HTML page that shows the analysis with the browser `EventSource` API.

**WebSocket**

- `GET /games/{id}/live` with an upgrade to WebSocket. Text messages in JSON.
- Client to server: `{"type":"move","move":"Nf3"}`, `{"type":"resign"}`, `{"type":"takeback"}`.
- Server to client: `{"type":"state","fen":...,"moves":[...],"status":...}`, `{"type":"engine_move","move":...}`, `{"type":"clock","white_ms":...,"black_ms":...}`, `{"type":"error","message":...}`.
- Many clients can watch one game. Only one client can play each side.
- The engine answers the moves of the player on the engine threads. The results go back to the I/O threads (see phase 7, "Threads and the hexagon").

**Persistence (SQLite)**

- Tables for games, moves, and an analysis cache (Zobrist key, depth, best move, score).
- Migrations with the `user_version` pragma. The server applies them at start.
- RAII wrappers for the SQLite connection and for prepared statements.
- A move and the update of the game status are one transaction.
- The game store contract tests from stage 3 run against the SQLite store.

**Operations**

- Configuration from the command line and environment variables: the listen address (default `127.0.0.1:8080`), the database path, the number of I/O threads, the number of search threads, the hash size, the maximum number of running analyses, and an API token. Commit `config.example.env` (or the equivalent) with dummy values.
- Authentication with a bearer token from the configuration for all write requests and for WebSocket. `GET /health` is public.
- Errors as Problem Details (RFC 9457) with `Content-Type: application/problem+json`.
- Structured logs with spdlog: a request identifier for each request; no tokens in the logs.
- Limits: the request body size, the WebSocket message size, the number of running analyses, idle timeouts.
- Graceful shutdown on Ctrl+C and SIGTERM: stop to accept connections, stop the searches, send a WebSocket close frame to each client, end the SSE streams, and wait for the I/O threads.

**GUI**

- A second implementation of the GUI's engine port: a **remote engine** that uses the WebSocket API of `chess-server`. A setting in the GUI selects "local engine" or "remote engine". The GUI code above the port does not change.

**Acceptance criteria**

- [ ] The diff of `chess_core` in this stage contains no HTTP, JSON, SQL, or Asio code.
- [ ] The game store contract tests pass for the SQLite store.
- [ ] The request handlers have tests that do not open a socket. 3–5 end-to-end tests start the server on port 0 and use real HTTP, SSE, and WebSocket clients.
- [ ] `curl -N` shows the SSE events of an analysis as they arrive. `websocat` can play a game.
- [ ] When an SSE client disconnects, the analysis stops within 100 ms (if no other client reads it).
- [ ] A 500 response contains no internal details. The logs contain no token.
- [ ] A move with a database error changes nothing in the database.
- [ ] The tests pass under AddressSanitizer and under ThreadSanitizer (where available).

## Stage 6: Production ready (phase 8)

**Features**

- **Bitboards:** a second board representation with one 64-bit integer for each piece type and color, behind the same `Position` interface. Keep the mailbox version as the reference in the tests. Use `<bit>` (`std::popcount`, `std::countr_zero`) for the bit operations. Sliding attacks with rays first; magic bitboards are optional (phase 9).
- **Benchmarks:** perft speed, search speed on a fixed set of positions with a fixed node count, and a `chess bench` command that prints the total node count as a signature. The signature changes only when the search behavior changes. Record all results in `docs/performance.md`, before and after each optimization, with the profiler output that guided it.
- **Property tests:** for random sequences of legal moves (fixed seed): unmake restores the position; the incremental Zobrist key equals a full computation; the FEN and SAN round trips; perft of the mailbox and the bitboard representation is equal.
- **Fuzz tests** with libFuzzer for the FEN, SAN, PGN, and UCI parsers, and for the JSON request bodies of the server. No crash, no sanitizer report, and no exception that escapes the parser.
- **Snapshot tests** for UCI transcripts and for the JSON responses of the API.
- **Mutation tests** on the rules code (optional; for example with Mull on Linux). Record the results in `docs/testing.md`.
- **A CI pipeline** in `.github/workflows/`: build and test on Linux (GCC and Clang), Windows (MSVC), and macOS (Apple Clang); ASan and UBSan on Linux and macOS; TSan on Linux; clang-format and clang-tidy checks; a short fuzz run (for example 60 seconds for each parser); the `bench` signature.
- **Release `1.0.0`:** `CHANGELOG.md`, a git tag, packages of `chess`, `chess-gui`, and `chess-server` for the three operating systems (CPack or a script), a container image of `chess-server` that runs as a user that is not root, and a `THIRD_PARTY_LICENSES` file with the licenses of all third-party code.
- **Documentation:** a `README.md` (install, use, develop), an architecture overview with links to the ADRs, the UCI options, the API description, and a runbook for the server.

**Acceptance criteria**

- [ ] The CI pipeline passes on the track branch in your private repository.
- [ ] The bitboard version is at least 3 times faster in perft than the mailbox version, and all perft values are still correct.
- [ ] Every property test and fuzz target runs in CI.
- [ ] The release has packages for three operating systems and a container image.
- [ ] A new developer can build, test, and run all three executables with only the README.

## Stage 7: Extension (phase 9, optional)

Select one option, or propose your own:

| Option | Module | Features |
|---|---|---|
| A | 9.1 | A stronger engine: magic bitboards, better move ordering (killer moves, history), null-move pruning, late move reductions, a tuned evaluation. Prove each change with a self-play test (SPRT). |
| B | 9.5 | A web front end that uses the REST, SSE, and WebSocket API |
| C | 9.5 | A WebAssembly build of `chess_core` with Emscripten, which runs in the browser |
| D | 9.6 | Python bindings (nanobind or pybind11) for analysis scripts |
| E | 9.7 | A Qt version of the GUI next to the Dear ImGui version, with the same model |

**Acceptance criteria**

- [ ] `chess_core` does not change for options B, D, and E. For option C, it changes only to make it compile with Emscripten. For option A, the changes are in the search and the evaluation, behind the existing ports.
- [ ] The extension has tests and runs in CI.
