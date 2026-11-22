# Brief G9: four small things on the app's pages (pages track, session P4; 2026-11-16 07:10)

For one Opus coder. Four small pieces the pages owe since the night of 11-15, none of them new depth: they
make what the owner sees on the first real runs say the same thing in the same form everywhere. Each is its
own commit. **If one of them turns out to need more than this brief says (a new seam into another track's
package beyond a few lent lines, a schema step, a request), do not build that one: write what it needs in your
report and go on with the others.**

**The routine-steps rule of this project (`CLAUDE.md`, the archiver section, second point) binds you too:**
you run named tests only; the whole runs are not yours.

## What is known already (read by the main session)
- **The old app's interface lessons** (TRIED-BEFORE 10, 15, 19): one vocabulary in one place; every number
  says what it counts; a reading says when it was read; a state says why in plain words. The old viewer's
  worst hour was a page that showed stale numbers with no age.
- **Times on the pages today have three forms:** `toLocaleTimeString()` in eleven places (Overview, Queue,
  Staging, the mirror's row, the live line), a full `toLocaleString()` on the sign-in's wait, and relative
  words from `ago` in `web/assets/js/format.js`. A time of yesterday shown as hours and minutes alone reads
  as today's.
- **The watchdog's status file can be missing or refused for an instant under any reader** (Core's K12,
  board message 92): the one door that reads it right is `watchdog.ReadStatus` (it reads again for about
  100 ms). The launcher uses it since G7 (`wip/pages-launcher2`, listed, not on the main head yet).
- **The mirror track gave a new count, `mirror.AutoNumbers.ReadRecordsBad`** (records of a mirror's read that
  could not be read): "a count for the Overview if wanted" (its message 98).
- **A catalogue newer than the build:** the viewer refuses it with `catalog.SchemaWords`'s sentence after
  asking `catalog.ReadOnlySchema` (`cmd/tgarchive/viewer.go`); `tgarchive app` has no such door.

## What to build
1. **One form for a time, used everywhere on the pages.** One exported helper in
   `web/assets/js/format.js` (and one for "until"): a time of today in this computer's time as hours and
   minutes (seconds only where a page counts seconds: say which you kept and why); a time of another day
   with its date in front; never a bare clock time for another day. Every `toLocaleTimeString()` and
   `toLocaleString()` in `web/assets/js` goes through it; the local `clock` helpers in the page scripts go.
   No sentence on a page changes otherwise. A test that fails when a script calls `toLocaleTimeString` or
   `toLocaleString` outside `format.js`.
   **Leave the Settings page's scripts alone unless a time is shown there** (another coder adds rows to it on
   `wip/pages-door`): say in the report whether you touched them.
2. **The Overview's Mirrors region shows the bad-record count** when it is not zero, with what it counts in
   plain words ("N records of a mirrored chat's read could not be read; they are counted, not skipped
   silently" or truer words once you have read what the count is in `internal/collector/mirror_auto.go` and
   `internal/mirror/auto.go`), through the mirror seam's existing way to the page (`internal/server/mirrors.go`,
   `internal/collector/livepages/mirrors.go`). If the number already reaches the adapter, it is a field and a
   sentence; if it needs a line in the mirror track's door, that is a lent line in a commit of its own.
3. **The watchdog's state on the Overview**, one line in the program's own region: whether this collector
   runs under its watchdog and, if so, how often the watchdog has started it again in this run and when
   last, read through `watchdog.ReadStatus` and nothing else, at most once every few seconds whatever the
   page asks, with the reading's time. A file that is not there says "not started by the watchdog" only when
   the collector itself knows no watchdog started it; a read that fails says "cannot be read", never "no
   watchdog". **Find first how the collector can know its status file's place without a path of this PC, a
   flag of a script or a guess** (what the watchdog hands its child, if anything). If it cannot know today,
   build nothing for this point and write exactly what Core would have to hand over.
4. **`tgarchive app` and a catalogue newer than the build** (`cmd/tgarchive/app.go`): before it opens the
   catalogue, the same door as the viewer's: `catalog.ReadOnlySchema`, and a newer catalogue is refused with
   `catalog.SchemaWords`'s sentence and nothing is written. An older catalogue: `app` opens read-write today
   and would step the schema; read what the collector's `run` does about it and do the same or say why not:
   never step a catalogue silently from a command whose job is to show pages. `-demo` (read-only) too.
5. **A protected chat on its row of the Chats page:** check what the row says today for a chat whose content
   is protected (the mirror's part of the row has `Protected` and `ProtectedKnown` since G4). If every such
   row already says in plain words that Telegram does not allow forwarding from it, build nothing and say so.
   If a protected chat with no mirror state shows nothing, add the one sentence in the mirror's part of the
   row from those two fields; "not known" is never shown as "not protected".

## Tests (named; invented data; no test judges on real time)
- The time helper: today, yesterday, another year, an "until" in the past, 0 or missing (shown as "not
  known", never as 1970); the script test of point 1.
- The count: zero shows nothing, a number shows the sentence; the adapter hands it through.
- The watchdog line: under a watchdog with restarts, under one with none, not under one, a read that fails;
  the read is bounded (many page loads, one read per interval).
- `app`: a newer catalogue is refused and its file is byte for byte as before; an older one as you decided.
- One mutation each for points 3 and 4 (the check removed: which test fails).

## Rules (hard)
- Copy and branch: `git -C C:/Users/trabi/Claude/Projects/Telegram/repo-archiver fetch private`, then
  `git -C C:/Users/trabi/Claude/Projects/Telegram/repo-archiver worktree add -b wip/pages-small ../wt-pages-small <the head of private/claude/charming-feynman-vm2xia>`
  (788ebf77 at 07:00; write the exact commit into your progress file). Work only in
  `C:\Users\trabi\Claude\Projects\Telegram\wt-pages-small`.
- Product code in `internal/server` (Go, `web`), `internal/collector/livepages`, `cmd/tgarchive/app.go`; lent
  lines elsewhere only as the points say, each in a commit of its own, as few as it takes. Nothing in
  `internal/telegram`, the catalogue (no schema step), the mirror's packages beyond a lent line for point 2,
  the viewer, the window, the launcher, `faketg`. Do not create or edit `internal/server/clicks.go`,
  `internal/collector/livepages/clicks.go` or anything under `/api/act/`: another coder is building them.
- **Nothing runs against Telegram.** Invented data only; never touch `E:\T\tg-dl`, the folders `a3`, `b`,
  `app`, `C:\Users\trabi\tgarchive-app`, any real catalogue, media, session or account; start no installed
  program and stop no process you did not start (the owner's own program may be running).
- New log, error and state text is constant words with numbers: never a chat's title, a name, a path, an id
  or a text.
- `TestAssetsStaySmall` holds every script under 600 lines. After any change under `web/assets/js`:
  `TestScriptsNoDuplicateOrMissingNames`, `TestAssetsStaySmall` and
  `node --input-type=module --check < file` for each changed script.
- Go: Git Bash, `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`, one go command at a
  time, `GOGC=25 GOMAXPROCS=2 go test -p 1 -run '<names>' ./internal/<package>`, named tests only: no whole run
  of `internal/server`, `internal/collector` or `internal/catalog`, no race detector, no Docker. Before each go
  command: `powershell -NoProfile -Command "(Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB; (Get-CimInstance Win32_Processor).LoadPercentage"`;
  wait when free memory is under 2.5 GB or the CPU is over 85% (another coder and other sessions share this
  PC). Every wait in a test has a bound.
- **Open it before handing back:** `tgarchive app -demo` built from your copy on `127.0.0.1:8799` (an address
  nothing of the owner's uses), the Overview, Queue, Staging and Chats pages in the built-in browser if you
  have one, at desktop and phone width. Say exactly what you saw and what you did not.
- Before handing back, list the test functions your difference removes against your base
  (`git diff <base> HEAD | grep '^-func Test'`) and account for each: the expected count is none.
- Any file that holds a Windows path is written with the file-writing tool, never from inside a shell or
  script string.
- Commits: `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, the message ending with
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; commit work in progress as you go and push only
  `git push private wip/pages-small`. Never push, merge into, rebase or switch any other branch; never stash.
- Keep `archiver/docs/progress/pages-small-PROGRESS.md` current from your first action and commit it with
  each step.

## Hand back
Commit-ready: everything committed and pushed, the tree clean, `gofmt -l` clean, `go vet` on the packages you
changed. `archiver/docs/progress/pages-small-REPORT.md`: for each of the five points what was built or why
nothing was; every lent line and whose it is; every test and mutation with its result; what you saw in the
browser and what you did not; what was NOT verified; anything in this brief you found wrong; the changed
files; a drafted final commit message. Your final message: the head commit and the base it sits on, point by
point what is built and tested and what is not, every departure, and your doubts, plainly.
