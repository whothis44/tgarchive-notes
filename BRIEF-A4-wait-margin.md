# Brief: a margin on a part's wait, and the lines the next run must show (tenth session, 2026-11-14)

For one Opus coder, in the copy `C:\Users\trabi\Claude\Projects\Telegram\wt-margin` (detached at 8761d5c of
`claude/charming-feynman-vm2xia`; Go module in `archiver/`). Small piece. Download-path code: it gets an
independent review and a race run before it runs for real; neither is yours.

## Why (read `archiver/docs/TRIED-BEFORE.md` section 27 first, then sections 1, 2 and 23)

The first real run got one plain wait per 14 MB on parts (the old app: one per 2,500 to 10,500 MB) and a
pool connection lost about every 4 seconds. Likely cause, not proven: `internal/engine/lane.go` sleeps a
part's wait for exactly the stated seconds and asks again the instant it ends. The old app sleeps the wait
plus 1 s. The next run on the same chat must show whether the margin alone changes this, so **one change of
behaviour only**, plus the log lines that make the comparison possible after a kill.

## Part 1: the margin (engine)

Read by the main session (line numbers at 8761d5c):
- `lane.go` `waitLen` (1467) returns the stated seconds. `keepPartWait` (1493) notes `now+d` on the part and
  the file and returns the record. In `fetch`, case `isWait` (1772), the request sleeps `sleepHeld(d, saves)`
  (1810) and the loop sends again as soon as `p.waitUntil` is not after now (1603). `late` (1885) keeps a
  wait that came after the local deadline through the same `keepPartWait`.
- `guard.go`: gates and held refreshes already add `gateMargin` (1 s). The part path adds none.

Build:
1. `Config.PartWaitMargin time.Duration` in `engine.go`, default 1 s; a negative value means no margin (for
   tests and for a comparison run). Say so in its comment, with the reason (TRIED-BEFORE 27).
2. A part that Telegram answered with a wait (plain or speed-limit, in time or late, **not** `Recorded`) is
   not asked again before the stated wait plus the margin: one `until = now + d + margin` in `keepPartWait`
   (the part, the file, the record), and the sleeping request in `fetch` sleeps to that same time.
3. **Everything else keeps the stated `d`:** the counters (`PlainWaits`, `LimitWaits`, `LateWaits`),
   `pol.OnWait`, `plainWait`'s thresholds (its gate keeps its own margin), the `HoldMin` test, the hand-over
   test, `waitLen` itself. No change to the window policy, gates, refresh waits, or `holdRecorded`.
4. Early retry (`Config.EarlyRetry`, off by default): the one early ask keeps its meaning (it goes before
   the stated end on purpose); after a refused early ask the rest is slept in full plus the margin. Change
   no more of it than that needs; say in the report what you did.
5. Look at how `x.waitUntil` is used (does a wait on one part hold the file's other parts in this run?) and
   at `holdRecorded` (a recorded wait ends with no margin). **Report both; change neither.**
6. The collector: a flag `-part-wait-margin` (a duration, default 1s) passed to the engine's config, in the
   style of its other flags.

## Part 2: lines in the log, one per event (no new table, no schema change)

The exact check's copy holds the next catalogue schema number; this piece adds **no column and no schema
step**. Per-minute counts in tables belong to the logging piece that follows. Here: one log line per event,
written when it happens, so a kill loses nothing.

1. **Each wait answered on a part** (engine): server number, plain or speed limit, stated seconds, the
   wait's number on this part since the part was last answered (1, 2, ...), milliseconds the request had
   been out, and the margin in milliseconds. If the engine has no log sink, add
   `Config.Logf func(format string, args ...any)` (as `telegram.PartsConfig.Logf`); it is never called with
   the lane's lock held. The collector wires it to its log.
2. **Each connection death** (`internal/telegram/options.go`, `ConnWatch.dead`): kind (main, pool, CDN) as
   a fixed word, server number, **the error's class as a fixed word**, whether the connection had sent
   (`takeDown`), and milliseconds since a wait was last stated on a part or hash of that server (-1: none
   in this run; keep the time a wait was stated per server next to `Counters.noteWait`). The callback must
   not block: hand the line off the library's goroutine the way the watch's saves are.
3. **The error's class**: a new small function, tested on invented errors. Never the error's text. Walk the
   chain with `errors.Is` / `errors.As` and give: `eof`, `unexpected-eof`, `cancelled`, `deadline`,
   `net-timeout`, `conn-dead` (the library's `pool.ErrConnDead`), `engine-closed` (`rpc.ErrEngineClosed`),
   `reset` and other socket errors as `errno N` (the number only), **the transport's protocol error with its
   code** (`codec.ProtocolErr`: `protocol -429`, `protocol -404`; a 429 there is Telegram closing the
   connection for too many requests, which is exactly what this run must be able to show), an RPC error by
   `errType`'s rule, else the innermost error's Go type name (`%T`: a word of the code, never data). Check
   in the library's source (module cache, v0.166.0: `pool/pool.go`, `mtproto/`, `proto/codec/`) which error
   values a dying connection really carries, and name them.
4. Every new format string is a constant; arguments are numbers, server numbers and fixed words only.
   **The privacy guard test must cover every new line** (find the existing guard test for log formats and
   extend it; if a new line is not reachable from it, say so and add the check).

## Tests (named, with an injected clock; no sleeping on the real clock)

- A part answered "wait 1 s" at T is not sent again before T+2 s and is sent at T+2 s; with a negative
  margin, at T+1 s. `PlainWaits` is 1 either way.
- The same for a late wait (after the local deadline) and for the file's record (`SaveFileWait`'s time).
- A second wait on the same part: its number is 2 in the line; an answered part resets it.
- Early retry on: the early ask still goes early; a refused one sleeps the rest plus the margin.
- The error classes, each from an invented error; a wrapped text with an invented name inside must not
  appear in any output.
- The death line: sent or not, and the milliseconds since a wait, on a fake clock.
- **Mutation:** take the margin out again and show the first test fails; put it back.

## Bounds (the owner's rules; no exceptions)

- **Nothing against Telegram. Do not start the collector or any program of the app.** Tests only.
- Work only inside `wt-margin`. No commit, no push, no branch, no delete outside it. Hand back
  commit-ready work with a proposed commit message.
- Go: `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env.sh` (Git Bash). Go is not on the PATH.
- **Every go command:** `GOMEMLIMIT=1GiB GOMAXPROCS=2 GOFLAGS=-p=2`, tests with `-timeout 300s -count=1`
  and `-run` naming the tests. No whole run of `internal/catalog` or `internal/collector`, no race detector,
  no Docker, no `go vet ./...`. `gofmt -l` on the files you changed and `go vet` on the two or three
  packages you changed, once, at the end.
- **Memory gate before every go command.** The PC had 1.3 GB free when this was written, and the owner's
  running app must not be disturbed. Measure:
  `powershell -NoProfile -Command "[math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB,1)"`.
  Under 3.0: do not run; write code and tests meanwhile, measure again later (a few times, minutes apart).
  If it never clears, hand back untested and say so plainly at the top of the report.
- **One go command on the PC at a time, across agents:** before one, `mkdir
  /c/Users/trabi/Claude/Projects/Telegram/.go-run.lock` (if it exists, another agent is running: wait and try
  again); `rmdir` it right after, also when the command fails.
- Before handing back: no `*.test.exe`, `go.exe` or `compile.exe` of yours left running (check; say what
  you found).
- Keep `archiver/docs/progress/waitmargin-PROGRESS.md` from your first edit (what is done, what is next,
  which tests passed), updated after each step: the app crashed twice on 11-13 and only files survived.
- At the end `archiver/docs/progress/waitmargin-REPORT.md`: what changed (files, lines), each test and its
  result, the mutation, what you found on points 4 and 5 and on the library's error values, anything you
  doubt. Privacy: numbers and fixed words only, anywhere.
