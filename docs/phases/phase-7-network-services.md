# Phase 7: Network Services and Persistence

**Time:** 4 weeks.
**Prerequisites:** Phase 6.
**Code:** `labs/7-services/` and `labs/chess/`

## Goal

At the end of this phase, you can:

- Design an HTTP API with resources, methods, status codes, and error bodies.
- Select between polling, Server-Sent Events (SSE), and WebSocket for real-time data, and explain the trade-offs.
- Write asynchronous network code with Asio and C++20 coroutines, and explain executors, strands, and the lifetime of asynchronous operations.
- Build an HTTP server with Boost.Beast that serves REST, SSE, and WebSocket.
- Connect the I/O threads of a server to the work threads of the core without data races or blocked I/O.
- Use SQLite through its C API with RAII wrappers, prepared statements, transactions, and migrations.
- Configure a service, write structured logs, and protect its boundary.
- Test a service at the level of the handlers and end to end.

## Reading

| Source | Part |
|---|---|
| Boost.Asio documentation | "Overview" (the basic model, strands, buffers), "C++20 Coroutines Support", and the examples for TCP servers with coroutines |
| Boost.Beast documentation | "Introduction", "Networking" (the parts about streams and timeouts), "HTTP", "WebSocket", and the examples `advanced_server` and `websocket_server_coro` (or the examples for coroutines of your Beast version) |
| MDN Web Docs (developer.mozilla.org) | "HTTP" (overview, methods, status codes), "Using server-sent events", "The WebSocket API" |
| WHATWG HTML Living Standard, "Server-sent events" | The event stream format |
| RFC 6455, "The WebSocket Protocol" | Sections about the opening handshake and the closing handshake |
| RFC 9457, "Problem Details for HTTP APIs" | All |
| SQLite documentation | "An Introduction to the SQLite C/C++ Interface", "Result and Error Codes", "Write-Ahead Logging", "Using SQLite In Multi-Threaded Applications" |
| nlohmann/json README | "Arbitrary types conversions", "Exceptions" |
| OWASP Top 10 (owasp.org) | All, quickly |

## Topics

### 7.1 HTTP API design

- **Resources** are nouns: `/games`, `/games/{id}`, `/games/{id}/moves`. **Methods** are the verbs:

  | Method | Meaning | Safe | Idempotent |
  |---|---|---|---|
  | `GET` | Read a resource | Yes | Yes |
  | `POST` | Make a resource, or start an action | No | No |
  | `PUT` | Replace a resource | No | Yes |
  | `PATCH` | Change part of a resource | No | No |
  | `DELETE` | Remove a resource | No | Yes |

- **Status codes:** `200 OK`, `201 Created` (with a `Location` header), `204 No Content`, `400 Bad Request` (the request is malformed), `401 Unauthorized` (no or wrong credentials), `403 Forbidden`, `404 Not Found`, `409 Conflict` (the state does not permit the request), `422 Unprocessable Content` (the request is well formed, but the content is not valid, for example an illegal move), `429 Too Many Requests`, `500 Internal Server Error`, `503 Service Unavailable`.
- **Error bodies** as Problem Details (RFC 9457), with `Content-Type: application/problem+json`:

  ```json
  {"type": "https://example.org/problems/illegal-move", "title": "Illegal move",
   "status": 422, "detail": "e2e5 is not legal in this position"}
  ```

- **Pagination** for lists: `?limit=50&after=<last id>` (cursor-based) is stable when data changes; `?offset=` is simpler but can skip or repeat items.
- **Validation at the boundary:** parse the request into domain types (phase 4, "parse, don't validate"). An invalid request never reaches the core.
- **DTOs:** the JSON shape of the API is a contract with the clients. Map it to domain types in the adapter. A change of a domain type must not change the API by accident.

### 7.2 Real-time: polling, SSE, and WebSocket

| | Polling | Server-Sent Events (SSE) | WebSocket |
|---|---|---|---|
| Direction | Client asks again and again | Server to client only | Both directions |
| Protocol | Normal HTTP requests | One long HTTP response with `Content-Type: text/event-stream` | An HTTP request with `Upgrade: websocket`, then a different protocol on the same connection |
| Data | Any | UTF-8 text events | Text or binary messages |
| Reconnection | Not needed | Built into the browser `EventSource` API, with `Last-Event-ID` | You write it |
| Proxies and tools | Work everywhere | Work with most proxies (turn off response buffering); `curl -N` shows the stream | Need proxy support for upgrades; special tools (`websocat`, browser developer tools) |
| Good for | Rare changes, simple clients | A stream of updates to many readers: analysis output, progress, notifications | Interactive sessions: games, chat, collaboration |

In the chess server, the analysis of a position is a one-way stream (SSE), and a live game is a two-way session (WebSocket).

**The SSE format:** UTF-8 text. Each event is one or more fields, then an empty line:

```text
event: info
id: 7
data: {"depth":12,"score":{"cp":34}}

: this is a comment, for example a keep-alive

```

- `data:` lines carry the content (several `data:` lines are joined with newlines). `event:` gives a type (the default is `message`). `id:` sets the last event identifier for reconnection. `retry:` gives the reconnection time in milliseconds.
- Browsers limit the number of HTTP/1.1 connections to one host (usually 6). Each open SSE stream uses one connection.

**WebSocket:**

- The client sends a `GET` with `Upgrade: websocket` and a `Sec-WebSocket-Key`. The server answers `101 Switching Protocols`. After that, both sides send **messages** (made of frames) in both directions.
- **Control frames:** ping and pong (keep the connection alive and detect dead peers), close (with a status code, for example 1000 for a normal close, 1008 for a policy violation).
- Check the `Origin` header in the upgrade request: a browser sends it, and a web page from a different site must not use your WebSocket with the cookies of the user. Use an explicit token for authentication.

### 7.3 Asynchronous I/O with Asio

- A server with one thread for each connection does not scale to many connections, and most connections wait most of the time. **Asynchronous I/O** starts an operation (read, write, accept, a timer) and continues with other work; a completion handler (or a coroutine) continues when the operation completes.
- **`io_context`** runs the completion handlers. Threads that call `io_context.run()` execute them. One `io_context` with several threads is a common server design.
- **C++20 coroutines** make asynchronous code look sequential:

  ```cpp
  boost::asio::awaitable<void> echo(boost::asio::ip::tcp::socket socket) {
      std::array<char, 1024> data{};
      for (;;) {
          const std::size_t n = co_await socket.async_read_some(
              boost::asio::buffer(data), boost::asio::use_awaitable);
          co_await boost::asio::async_write(
              socket, boost::asio::buffer(data, n), boost::asio::use_awaitable);
      }
  }
  // Start it: boost::asio::co_spawn(executor, echo(std::move(socket)), boost::asio::detached);
  ```

  When the client closes the connection, `async_read_some` throws a `boost::system::system_error` (with `use_awaitable`). Catch it at the top of the coroutine, or use `boost::asio::as_tuple(boost::asio::use_awaitable)` to get the error as a value. Check the exact form for your Boost version.
- **Lifetimes:** the buffers and the objects that an asynchronous operation uses must live until the operation completes. With coroutines, local variables of the coroutine live in the coroutine frame, which makes this easier. With callbacks, the usual method is `std::enable_shared_from_this` and a `shared_from_this()` capture.
- **Strands:** a strand executes its handlers one at a time, also when several threads run the `io_context`. Put all operations of one session on one strand (or use one thread), and the session state needs no mutex.
- **Timers and timeouts:** `boost::asio::steady_timer`. Beast streams (`beast::tcp_stream`) have `expires_after` for timeouts of each operation.
- **Cancellation:** close the socket, or use cancellation slots (newer Asio versions). A cancelled operation completes with `operation_aborted`.
- **Never block in a handler or a coroutine** (no long computation, no blocking file or database access, no `sleep`): it blocks every connection on that thread. Send the work to a different thread (topic 7.6).

### 7.4 HTTP with Boost.Beast

- Beast gives HTTP and WebSocket message types and algorithms on top of Asio. It is low level: it has no router, no JSON, and no middleware. You write them, which teaches you what web frameworks do.
- The main types: `http::request<http::string_body>`, `http::response<http::string_body>`, `beast::flat_buffer` (the read buffer), `beast::tcp_stream` (a socket with timeouts), `http::async_read`, `http::async_write`.
- A session loop: read a request with a size limit, route it to a handler, write the response, and continue if keep-alive is set. Close the connection after an error or a timeout.
- **A router** maps the method and the path to a handler. Write it as a pure function `Response handle(const Request&)` (plus the dependencies), so that tests can call it without a socket.
- **Limits:** set a body limit for each request (`http::request_parser::body_limit`), a timeout for each read and write, and a limit on the number of connections.

### 7.5 SSE and WebSocket with Beast

- **SSE:** for a request to an event stream, write the response header first (`Content-Type: text/event-stream`, `Cache-Control: no-cache`), with chunked transfer encoding or without a content length. Then write each event when it is ready. Read the Beast documentation about the serializer and chunked encoding for your version. When the write fails, the client is gone: stop the producer.
- **WebSocket:** `websocket::stream<beast::tcp_stream>`. Accept the upgrade with the request that the HTTP session already read (`async_accept(request)`). Then loop: `async_read` a message, handle it, and send answers.
- **Only one write at a time.** A WebSocket stream (and an SSE stream) must not have two writes in progress at the same time. When several sources send messages to one client (engine moves, clock updates, other players), put them in a **write queue** of the session, and write the next message when the previous write completes.
- **Settings:** `websocket::stream_base::timeout::suggested(beast::role_type::server)` for timeouts and pings, and `read_message_max` for the maximum message size.

### 7.6 Threads and the hexagon

A chess server has two kinds of threads:

```text
I/O threads (io_context)                  Engine threads (search)
+-----------------------------+           +----------------------------+
| HTTP, SSE, WebSocket        |  command  | Use cases of chess_core    |
| sessions (one strand each)  | --------> | search, time control       |
|                             | <-------- | SearchObserver events      |
+-----------------------------+   post    +----------------------------+
```

- **The core does not know Asio.** The server adapter calls the use cases of the core (the same ones that the CLI and the GUI call).
- **Never run a search on an I/O thread.** The adapter gives the search to the engine threads (for example through the bounded queue of phase 6, or a search manager actor).
- **Results go back with `post`.** A `SearchObserver` that the engine calls on a search thread does not touch the session. It calls `boost::asio::post(session_strand, [weak_session, info] { ... })`. The session then writes the event on its own strand.
- **The client can leave before the result arrives.** Hold the session with a `std::weak_ptr` in the callback. If the session is gone, drop the event. If no client reads an analysis any more, stop the search (stop token).
- **SQLite calls block.** Run them on a separate small thread pool, or accept short blocking for small queries and measure it. Write the decision in an ADR.

### 7.7 JSON

- nlohmann/json: `nlohmann::json j = nlohmann::json::parse(text);`, `j["move"].get<std::string>()`, and conversion functions `to_json` and `from_json` for your DTO types.
- `json::parse` throws `nlohmann::json::parse_error` for invalid JSON. Use `nlohmann::json::parse(text, nullptr, false)` and check `is_discarded()` to get no exception. Check each field: a missing field or a wrong type throws in `get<T>()` or `at()`.
- Convert the exceptions to a `400` or `422` response at the boundary. Do not let an exception from untrusted input reach the session loop.
- Limit the size of the input before you parse it.

### 7.8 Persistence with SQLite

- SQLite is a database in one file, linked into your program as C code. The C API has a few main functions: `sqlite3_open_v2`, `sqlite3_prepare_v2`, `sqlite3_bind_*`, `sqlite3_step`, `sqlite3_column_*`, `sqlite3_finalize`, `sqlite3_close_v2`, `sqlite3_errmsg`.
- **Write RAII wrappers** (phase 2): a `Connection` class that owns a `sqlite3*`, and a `Statement` class that owns a `sqlite3_stmt*`. Return errors as `std::expected` with the SQLite result code and message.
- **Always bind parameters** (`?` placeholders and `sqlite3_bind_*`). Never build SQL with string concatenation from input: this is SQL injection.
- **Transactions:** a `Transaction` guard runs `BEGIN IMMEDIATE` in its constructor and `ROLLBACK` in its destructor, unless `commit()` was called. Then an exception or an early return never leaves a half-finished change.
- **Migrations:** a list of SQL scripts in order. `PRAGMA user_version` stores the number of the last applied script. At startup, apply the missing scripts in one transaction each.
- **Threads:** a SQLite connection must not be used by two threads at the same time. Use one connection for each thread, or a small pool, or one database thread. Enable the WAL journal mode (`PRAGMA journal_mode=WAL`) so that readers do not block the writer.
- **Store integers for exact values,** and store moves as text in UCI notation or as integers, not as floating-point values.

### 7.9 Configuration

- Read the configuration once at startup, validate it, and convert it to a typed `Config` struct. Fail fast with a clear message for a missing or invalid value.
- Sources, in order: defaults, a configuration file, environment variables, command-line options. Document each setting.
- **Secrets** (the API token) come from an environment variable or a file that git ignores. Commit an example file with dummy values. Never print a secret in a log.

### 7.10 Logging and observability

- Use a logging library (the course uses spdlog). Log levels: `trace`, `debug`, `info`, `warn`, `error`, `critical`.
- **Structured logs:** each line has fields: the time, the level, a request identifier, the method, the path, the status, the duration. A JSON log format is easy to search with tools.
- Give each request an identifier, and put it in every log line of the request and in a response header (`X-Request-Id`). Then you can find all the lines of one request.
- Do not log secrets, tokens, or full request bodies.
- Log an error where you handle it, not where it occurs (phase 4).

### 7.11 Security at the boundary

- **Bind to `127.0.0.1`** in development. A server on `0.0.0.0` is reachable from the network.
- **Limits** on everything that a client controls: the size of a request, a header, a body, and a WebSocket message; the number of connections, analyses, and messages per second; the time of each read and write.
- **Authentication:** a bearer token in the `Authorization` header. Compare tokens in constant time (compare all bytes, do not stop at the first difference).
- **Errors:** a `500` response says "internal error" and a request identifier. The details go to the log.
- **TLS:** Beast supports TLS with OpenSSL, but the course does not. In production, put the server behind a reverse proxy that terminates TLS (for example nginx or Caddy).
- **Dependencies:** keep Boost, SQLite, and the JSON library up to date (see [../topics/external-libraries.md](../topics/external-libraries.md)).

### 7.12 Test a service

- **Handler tests:** call the router function with a request object, and check the response. No socket, no threads. Most tests are of this kind.
- **Store tests:** the contract tests from phase 5 run against the SQLite store with a database in memory (`":memory:"`) or in a temporary file.
- **End-to-end tests:** start the server on port 0 (the operating system selects a free port), read the port, and send real requests with a Beast client: HTTP, an SSE stream (read the first events, then close), and a WebSocket session. Use timeouts in every test, so that a defect makes the test fail, not hang.
- Stop the server cleanly at the end of each end-to-end test, and run them under AddressSanitizer and ThreadSanitizer.

## Exercises

Make the project `labs/7-services/`. Add Boost (Asio and Beast), nlohmann/json, SQLite, and spdlog with the methods in [../topics/external-libraries.md](../topics/external-libraries.md), and record them in the dependency list.

### Exercise 7.1: Asio and coroutines (core)

1. Write a program that starts three timers (1, 2, and 3 seconds) with coroutines and prints a line when each one expires. It must take 3 seconds, not 6.
2. Write a TCP echo server with coroutines on `127.0.0.1`. Test it with `curl telnet://127.0.0.1:<port>`, `nc`, or a small client.
3. Add a timeout: a client that sends nothing for 10 seconds is disconnected.
4. Run the `io_context` on 4 threads. Is the echo server still correct? Why?

### Exercise 7.2: The first HTTP server (core)

1. Write an HTTP server with Beast with `GET /health` (returns `{"status":"ok"}`) and `POST /echo` (returns the body).
2. Write the router as a pure function, and test it without a socket.
3. Add a body limit of 1 MB, and a test that sends 2 MB.
4. Test with `curl -v`.

### Exercise 7.3: A REST API in memory

Write a URL shortener API (reuse the core of exercise 5.5): `POST /links` (body `{"url": ...}`, returns `201` with the code), `GET /links/{code}` (returns `302` with a `Location` header, or `404`), `GET /links?limit=&after=`. Errors as Problem Details. Handler tests for each route and each error.

### Exercise 7.4: Server-Sent Events (core)

1. Add `GET /time`: an SSE stream that sends the time every second as an event `tick`, and a comment every 15 seconds.
2. Watch it with `curl -N`. Watch it in a browser with a small HTML page that uses `EventSource` (serve the page from `GET /`).
3. Close the client. Check in the log that the server stops the stream for that client, and that no timer runs for it any more.
4. Open 100 streams with a small test client. Measure the memory and the threads of the server.

### Exercise 7.5: WebSocket (core)

1. Add `GET /chat` with a WebSocket upgrade. All connected clients receive every message that any client sends.
2. Implement the write queue of topic 7.5. Test with three `websocat` clients, and with a test client that sends 1 000 messages fast.
3. Limit the message size to 4 KB, and close the connection with the close code 1009 (message too big) when a client sends more.
4. Check the `Origin` header, and reject unknown origins.

### Exercise 7.6: SQLite (core)

1. Write the RAII wrappers `Connection`, `Statement`, and `Transaction` with `std::expected` errors.
2. Write migrations with `PRAGMA user_version`. Test: a new database gets all migrations; a database at version 1 gets only the later ones.
3. Implement the `LinkStore` of the URL shortener with SQLite. Write contract tests for the `LinkStore` port, as in exercise 5.3, and run them against the memory store of exercise 5.5 and the SQLite store.
4. Show SQL injection with a version that concatenates the input into the SQL. Fix it with bound parameters. Keep the test.
5. Write a test where an error in the middle of a transaction leaves the database unchanged.

### Exercise 7.7: Configuration, logs, and limits

1. Add a typed configuration (address, port, database path, token, log level, log format) from defaults, the environment, and the command line. Invalid values stop the server at startup with a clear message.
2. Add spdlog with a request identifier in each line, and a JSON format option.
3. Protect `POST` routes with a bearer token. Test a missing token, a wrong token, and a correct token.
4. Shut down cleanly on Ctrl+C with `boost::asio::signal_set`: stop to accept, close the WebSocket sessions with a close frame, end the SSE streams, and return from `main`.

### Exercise 7.8: End-to-end tests

Write 3–5 end-to-end tests that start the server on port 0 in the test, and use a Beast client for HTTP, SSE, and WebSocket. Each test has a timeout, and stops the server at the end. Run them under AddressSanitizer and ThreadSanitizer.

## Project: Chess engine, stage 5

See [../projects/chess-engine.md](../projects/chess-engine.md), stage 5.

## Done criteria

- [ ] I can design REST resources, select the methods and status codes, and return Problem Details.
- [ ] I can explain when to use polling, SSE, and WebSocket, and the format of each.
- [ ] I can write asynchronous code with Asio coroutines, and explain the lifetime of an asynchronous operation and the purpose of a strand.
- [ ] My server never blocks an I/O thread with a search or a slow operation.
- [ ] Each WebSocket and SSE session has only one write in progress at a time.
- [ ] My SQLite code uses RAII wrappers, bound parameters, transactions, and migrations.
- [ ] My service has a typed configuration, structured logs with request identifiers, limits, and a token check.
- [ ] My handler tests run without sockets, and my end-to-end tests start the server on port 0.
- [ ] Chess engine stage 5 is complete.

## Next

[Phase 8: Professional practices](phase-8-professional-practices.md)
