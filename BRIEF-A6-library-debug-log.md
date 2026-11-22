# Brief: the library's own connection log, for one diagnostic run (tenth session, 2026-11-14)

For one Opus coder in `C:\Users\trabi\Claude\Projects\Telegram\wt-libdebug` (branch
`wip/lib-debug-2026-11-14`, at ead8b6d; Go module in `archiver/`). Small piece. A short independent review
(privacy, blocking) follows; then one real run by the owner.

## Why

Two real runs on the test account (TRIED-BEFORE.md section 27; the second on 11-14 with the wait margin):
a connection of a server's file pool is ended by the server (end of stream) every few seconds while videos
download (3 to 4 a minute with the margin, about 15 a minute without), each on a connection that had sent;
and about one part request in 13 is told to wait 1 to 3 seconds. The old app (library v0.163.0, another
account) sees neither. The new app (v0.166.0) sets no logger on the library at all, so what the library
saw before each close is unknown: a bad message notification, a salt change, a new session, a
re-initialisation, a ping that timed out, a key re-made. **This piece makes the library's own log visible
for one run, without letting a single name, text, id or address into the log.**

## Read first

- `archiver/docs/TRIED-BEFORE.md` sections 11 and 27; `internal/telegram/options.go` (how the client's
  options are built; `ConnWatch`; the new `errClass` in `errors.go` and the death line).
- The library in the module cache (`source ix-tools/env-archiver.sh; go env GOMODCACHE`), v0.166.0:
  `github.com/gotd/log` (the logger interface and attributes), and every log call in `mtproto/`, `pool/`,
  `rpc/`, `telegram/internal/manager/`, `telegram/` (connection, session, key, salt, ping, ack, bad
  message, new session, migrate): list each message with its attribute keys and what each key carries.

## Build

1. **A logger given to the library** (`gotd.Options.Logger` or what v0.166.0 calls it), only when the
   collector's run has the new flag `-lib-debug` (off by default; nothing changes without it: with the
   flag off the client's options must be exactly what they are today, shown by a test).
2. **What a line may contain. This is the whole point; be strict.**
   - The library's message is a literal of its source code. It is written only when it is in **an
     allow-list of exact message strings** that you build from your reading of the library (connection
     lifecycle, session, salt, key, ping, ack, bad message, re-send, re-initialise, migrate, the pool's
     "connection died" and "retrying"). Any message not on the list is **never written**: it is counted
     under a fixed word "other" and the count is printed once a minute.
   - **Attributes by an allow-list of keys**, and only when the value is a number, a boolean or a
     duration: connection number in the pool, remaining connections, server number, error codes, attempt
     counts, sizes in bytes, durations. Never a string value, whatever the key. Never a key you have not
     read the meaning of. Keys whose number is an identifier of a person, chat, message of a chat, file,
     access hash, phone, address or port of the owner's side are **not** on the list; MTProto's own
     transport numbers (its message id, sequence number, session id, salt) are also left out except as
     "present" (a boolean), since they add nothing here.
   - **An error attribute** is written as `errClass(err)` (the fixed-word classifier that exists), never
     its text. For an RPC error inside, the type by `errType`'s rule and the code.
   - The logger's name or component, if the library gives one, only when it is one of a fixed list.
   - Each line starts with a fixed prefix, e.g. `telegram lib: `, then the level word, the message, then
     `key=number` pairs in a fixed order.
3. **Volume.** The per-request messages of the pool ("DC Invoke", "DC Invoke complete", "Re-using free
   connection", "Connection released", and any other that fires once per request or per received message)
   are not written singly: counted per minute, one summary line a minute per message. Everything about a
   connection's start, readiness, end, its session, salt, key, pings and bad messages is written singly.
4. **It must not slow or block the library.** The logger's method formats and hands the line to a bounded
   queue and returns; a writer goroutine drains it to the collector's log; a full queue drops the line and
   counts the drop (printed in the minute's summary). Stopped and drained at the client's close (within a
   bound), no goroutine left.
5. **The death line gains the pool's connection number** if the library's event carries it; if it does
   not, say so (then the debug log's "Connection died … conn_id" line is what ties a death to its
   connection's earlier lines).
6. **The collector:** the flag, the wiring, and one start-up line "the library's connection log is on"
   when it is.

## Tests (named; injected clock; no real network)

- **The privacy guard, the main test:** drive the logger directly with every allow-listed message and
  with invented messages, each with attributes of every type under allow-listed and other keys, string
  values holding hard invented names, paths, phone-like and id-like text, and errors whose text holds the
  same. Assert the output's every line matches a strict pattern built from the two allow-lists and
  numbers, and that none of the invented strings appears. A mutation (string values let through; a
  message outside the list let through; an error's text printed) must each fail it. Extend the existing
  privacy guard tests of `internal/telegram` and `internal/collector` so the new lines are in what they
  check.
- With the flag off, the options carry no logger and no line is written.
- Per-minute summaries: counts right on a fake clock; the queue's drop counted when full; close drains.
- One loopback test with the library's real client if the existing test helpers allow it (the package
  has loopback tests): the allow-listed lifecycle lines of a connection appear, in order.

## Bounds (the owner's rules; no exceptions)

- Nothing against Telegram; never start the collector or any program of the app. **A real run of the
  collector is going on this PC: do not touch its process, the folders under the user's local application
  data, or the `a3` folder.** Never touch anything under `E:\T\`.
- Work only in `wt-libdebug`. No push, no commit: commit-ready work in the tree, with a proposed message.
- Go through `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh` (not `env.sh`).
- Every go command: `GOMEMLIMIT=1GiB GOMAXPROCS=2 GOFLAGS=-p=2`, `-count=1 -timeout 300s`, `-run` naming
  tests, one package per command. No whole run of `internal/collector`; no race detector; no Docker.
  `gofmt -l` on changed files and `go vet` on changed packages at the end.
- Before every go command measure free memory as a separate command
  (`powershell -NoProfile -Command "[math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB,1)"`);
  under 3.0 GB do not run, try again minutes later.
- No test or compiler process of yours left running.
- `archiver/docs/progress/libdebug-PROGRESS.md` from the first edit; `libdebug-REPORT.md` at the end, with
  **the two allow-lists in full, each entry with where it is in the library and what it carries**, the
  messages and keys you left out and why, and what a reader of the run's log should look for before a
  connection's end.
- Privacy: numbers and fixed words only in anything you print or write; invented test data.
