# Brief: independent review of G1 (the collector serves the pages; the owner's Stop and Start) — read-only

You are an independent reviewer. You did not write this code and you owe its author nothing. Find what is
wrong with it before it runs on a real Telegram account. **You change nothing in the tree.**

## What to review
The branch `wip/pages-g1` at 023c048, in the copy `C:\Users\trabi\Claude\Projects\Telegram\wt-pages-g1` (Go
module in `archiver/`), against its base f0e3f0c: `git diff f0e3f0c..023c048`. What it was asked to do:
`C:\Users\trabi\Claude\Projects\Telegram\BRIEF-G1-one-program.md`. Its author's own account:
`archiver/docs/progress/pages-g1-REPORT.md` (read it last, and do not take its word for anything).
The pieces: `internal/collector/ownerstop.go`, `pages.go`, `pages_cmd.go`, the 23 lines in `account.go`, the
37 in `command.go`; `internal/collector/livepages`; in `internal/server`: `server.go`, `live.go`,
`liveroute.go`, `overviewcache.go`, `reads.go`, `settings_when.go`, `queue.go`, `accounts.go`, `settings.go`,
`importer.go`, `overview.go`; the page scripts under `internal/server/web/assets/js`.

Background you need: the collector (`internal/collector`, read `collector.go`'s package comment for the start
and stop order, and `account.go`'s `loop` and `runSession`) is one process holding every Telegram session and
is the one writer of the catalogue (SQLite). Until this branch its pages were another program on a catalogue
nothing else wrote. Now the pages' handlers run in the collector's process, on its catalogue handle, while
lanes claim files, the reader stores messages and the supply settles owner actions. The rules that bind it
(the project's `CLAUDE.md` and lessons): a wait Telegram states is never shortened; no request to Telegram
from a click without its cost shown; a person's Stop is never undone by the app and a stored mark that cannot
be read fails closed; nothing but exact evidence ends a file without bytes; a stop ends in seconds; long
writes are chunked (one failed statement on the single writer once cancelled every download); logs that other
sessions read hold constant words and numbers only, never a name, title, path, id or text; the pages listen on
127.0.0.1 only and every change route needs same origin and the run's token.

## Where to look hardest (not a limit)
1. **The owner's Stop and Start** against the account's loop and the session's start and stop: every
   interleaving (a Stop while dialling, while the session is being made, during its teardown, during the
   redial pause or a gate refusal; a Start during the stop; Stop with `ClearFrozen`, a sign-in or a lost gate
   at the same moment; two accounts; the record failing to write, read or delete). Can any request leave for
   a stopped account afterwards, by any path (a queued reader call, the refresher, the monitor, a sign-in's
   own connection)? Can a Stop be lost, or a Start? What does the new redial floor change for the existing
   endings (a lost connection, a lost gate, a freeze cleared)? Goroutine leaks; the watcher.
2. **The pages' life beside the collector's**: can a handler run on the catalogue after the collector began
   to close it; what bounds the stop when a request hangs or a client stops reading; `Run` failing before it
   is ready; `server.New` failing; Quit twice; Quit while a sign-in holds the stop; the order in which the
   listener, the two locks and the catalogue are let go; the package-level state.
3. **Every change route on a live collector**: the report has a table; check each row by reading the handler
   down into the catalogue. A rank change while lanes claim; "try again" and "release" racing the engine's own
   handling of that file; the topics' settle inside a request beside the supply's own settle; the settings'
   save that sorts files by size class at once (how long does it hold the writer at 300,000 files?); removing
   an account; anything the report calls "allowed; not exercised".
4. **Estimate and approve**: one request, on the owner's click, never twice; what happens to an estimate
   still queued when the owner presses Stop, when the page's request ended at 30 s, when the program stops;
   whether "approve" can approve a cost the owner was not shown.
5. **The guard**: the new routes behind it; what the starting page and the 503s answer to another origin;
   whether anything a page of another site can do reaches Telegram or the catalogue.
6. **The poll and the kept answers**: any table read on `/api/live`; anything a kept overview, queue or chat
   count can show as true when it is not (what does not move the change key?).
7. **Privacy of the log**: any path by which a title, a file name, a path, an id or an error's text reaches
   the collector's log or console.
8. **The scripts**: text put into the page as markup; words that are false when the program runs; a refresh
   that takes a control from under the pointer or the keyboard.
9. **The tests themselves**: a test that judges on real time; a mutation the author says was caught that the
   test would not catch; package-level variables shared by tests that may run in parallel.

## How to work
- Read the code yourself; read the old code it relies on. Prove a finding where you can with a probe test
  written in your own scratch folder and loaded with `go test -overlay` (the tree stays untouched), or by
  reasoning from quoted lines when a probe would cost too much. Mark each finding **CONFIRMED** (a probe or an
  unarguable reading) or **PLAUSIBLE** (say what would settle it).
- Load: Git Bash, `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`, one go command at a
  time, `GOGC=25 GOMAXPROCS=2 go test -p 1 -run '<names>' ./internal/<package>`: named tests only; no whole
  run of `internal/collector` or `internal/catalog`, no race detector, no Docker. Memory on this PC is short:
  look at free memory before each go command
  (`powershell -NoProfile -Command "(Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB"`) and wait
  when it is under 2.5 GB.
- Never touch `E:\T\tg-dl`, the folders `a3`, `b`, `app`, any real catalogue, media, session or account; start
  no installed program. Invented data only.

## What to hand back
Write `C:\Users\trabi\Claude\Projects\Telegram\REVIEW-G1-pages.md`: findings in order of harm, each with its
mark, the file and lines, what goes wrong in one concrete sequence of events, and the smallest change you would
ask for; first the ones that must be fixed before this is merged, then the ones that should be, then minor
ones; then what you checked and found sound (briefly, by name), and what you did not look at. Your final
message: the count by class and the must-fix findings in one line each.
