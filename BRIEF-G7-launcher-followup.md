# Brief G7: the launcher's small follow-up (the watchdog's door, the viewer's staging folder, the collector's own answers marked)

Written 2026-11-16 by the pages session (P3). For one Opus coder. Small: three changes, about 80 lines with
their tests. **You run named tests and the launcher's own package only; other whole runs are a clerk's.**

## Where
- Make a copy for yourself: in `C:\Users\trabi\Claude\Projects\Telegram\repo-archiver` run
  `git worktree add -b wip/pages-launcher2 ../wt-pages-l2 6365a08a` (6365a08a is the head of the main branch
  `claude/charming-feynman-vm2xia` today). Work only in `C:\Users\trabi\Claude\Projects\Telegram\wt-pages-l2`
  (Go module in `archiver/`). You never merge into or push the main branch; you push `wip/pages-launcher2` to
  the remote `private` only.
- Read first: `archiver/docs/progress/pages-g6-REPORT.md` (the launcher's own account), then
  `internal/launcher/status.go`, `probe.go`, `collectorwords.go`, `start.go`, `ui.go` (the function `status`),
  `internal/watchdog/readstatus.go` (Core's door, merged as K12), `internal/collector/pages.go` lines 200 to 315
  (the collector's three own answers), `internal/server/server.go` around `PagesMark`.

## The three changes
1. **The watchdog's status file is read through the watchdog's own door.** Core's board message 92: the
   watchdog now replaces its status file by a rename, a reader can miss the name for an instant or be refused,
   and `watchdog.ReadStatus(dir)` is "the way to read" it (delete sharing, up to about 100 ms of tries).
   `readWatchdogStatus` in `internal/launcher/status.go` becomes that call (`ok` is `err == nil`); the launcher's
   own open, limit and parse of that file go, and `openShared` in the launcher goes too if nothing else of the
   launcher uses it (say what you found). Two things to keep right:
   - `ui.status` re-reads at every call while the last read failed (it caches only a good one) and holds the
     page's lock during the read. With the door a failed read takes about 100 ms. Cache a failed read as well,
     for one second, so a page that polls while there is no status file yet cannot queue behind the lock. A
     test with a counted reader (inject the reader as the package already injects its other doors; no real
     time judged: hand the function a clock or a `now`).
   - `findLeft` runs before anything is started: about 100 ms more when there is no file is fine; say it in
     its comment. Its meaning must not change: a status that cannot be read is "not known", then the marker
     decides, as today.
2. **The viewer is started with the staging folder.** The window and the browser's viewer both take
   `-staging <folder>` since the viewer's staged-files piece ("the collector's local staging folder, only ever
   read"). `viewerSpec` in `start.go` adds `-staging`, the layout's staging folder (the one the collector's line
   gets), for both kinds. A test on the arguments for both kinds (the existing tests of `viewerSpec` show how).
3. **The collector's three own answers carry the pages' mark with a word of their own, and the launcher tells
   them by it.** Today `look` in `probe.go` knows the collector's starting page, its page when the pages could
   not be made, and its answer while it stops by their texts, copied into `collectorwords.go` and kept in step
   by a test that reads `pages.go`. Replace that:
   - In `internal/collector/pages.go` (**Core's file, lent: the fewest lines, in ONE commit of their own that
     touches only that file and its test**) the three answers set the header `X-Tgarchive-Pages` to `starting`,
     `no-pages` and `stopping` (the pages themselves keep `1`, set in `internal/server`). Put the three words
     and the header's use beside each other as constants in the collector with a comment naming the launcher;
     the collector may use `server.PagesMark` for the name (it imports the server already; check). Every path
     of the three: the HTML page and the JSON answer of each (`pagesUnavailable` serves both).
   - In the launcher: `look` reads the header's value: `1` the pages, `starting`, `no-pages`, `stopping`, and
     no body is read for those. The launcher's own page is still told by its meta mark. Anything else:
     `answerOther`, as today. `collectorwords.go` and `TestCollectorWordsMatchPagesGo` go; the stand-in
     collector of the launcher's tests (`standin_test.go`) sends the headers instead of the texts.
   - A test in the collector that each of the three answers carries its word (by name; model it on the tests
     that already ask the starting page and the stopping answer), and one in the launcher that `look` tells the
     five apart and takes an unknown word of that header as `answerOther`.
   - The folder's programs are always built together (`deploy/folder/make-folder.sh`), so no fallback to the
     old texts is kept. Say so in the report.

## Run, one go command at a time
Git Bash; `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`; before each go command:
`powershell -NoProfile -Command "(Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB; (Get-CimInstance Win32_Processor).LoadPercentage"`
and wait while free memory is under 2.5 GB or the CPU over 85%. Then: `go build ./...`; `gofmt -l` on what you
touched; `go vet ./internal/launcher/ ./internal/collector/ ./cmd/tgarchive-open/`;
`GOFLAGS=-p=1 GOGC=25 GOMAXPROCS=2 go test -count=1 ./internal/launcher/ ./cmd/tgarchive-open/` (the launcher's
whole tests: its package is small) and
`GOFLAGS=-p=1 GOGC=25 GOMAXPROCS=2 go test -count=1 -run '<the collector tests you added or that ask the three answers>|TestPagesStart|TestE2EPages' ./internal/collector/`
(name the real tests; no whole run of `internal/collector` or `internal/server`, no race detector, no Docker).
The launcher's tests that need Windows must still skip off Windows (a clerk runs them in a Linux container
afterwards).

## Rules
- Nothing runs against Telegram. No real collector, watchdog, viewer or window is started: the launcher's tests
  use their stand-ins only. Never touch `E:\T\tg-dl`, the folders `a3`, `b`, `app`, any real catalogue, media,
  session or account; leave every running process and container alone. Invented data only; print counts, sizes
  and timings only.
- No new log line is needed; if you add one, it has a constant format string and no path.
- Any file that holds a Windows path is written with the file-writing tool, never from inside a shell or script
  string.
- If anything is not as this brief says (a caller of the old texts elsewhere, a test of another track that
  fails, a program that does not take `-staging`), stop there and report it.

## Write it down and hand back
A report `archiver/docs/progress/pages-g7-REPORT.md` (what changed per point, the lent lines' commit, each
test and what it would catch, what you did not verify). Commits with
`git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, each message ending with the line
`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; push `wip/pages-launcher2` to `private`. Your final
message: the commits and the head pushed; files changed; each test run with ok or FAIL and seconds; what you
did not verify; anything not as written.
