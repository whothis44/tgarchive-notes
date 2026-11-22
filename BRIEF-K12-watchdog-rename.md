# Brief K12: the watchdog's status file is put in place also while another program reads it (Core, K-3, 2026-11-16 01:52)

For one Opus coder. Small: `internal/watchdog` only.

- Copy: `C:\Users\trabi\Claude\Projects\Telegram\wt-core-wdrename`, branch `wip/core-wdrename`, cut from the
  main head (698ee15d or later). Go module in its `archiver` folder. Pushed to `private` as you go; never
  the branch `claude/charming-feynman-vm2xia`.

## 1. What is wrong (measured by the pages track, board message 86 a)

The watchdog writes its status file `watchdog-status.json` by a temporary file and `os.Rename`
(`internal/watchdog/status.go`, `writeStatusFile`). On Windows that rename is refused while another
program has the file open, even when that reader opened it with read, write and delete sharing: the
launcher's coder measured, with stand-ins, 1,579 refusals of 3,000 renames while a reader looped, and 0
of 3,000 with a rename of the POSIX kind (`os.Root.Rename`). A refused write is counted today
(`status_write_failures`) and lost; when the LAST write is the lost one, the file says "running" after
the watchdog has ended. The launcher of the program's own folder, the `a3` scripts and the pages all
read that file.

**What the old app knows:** nothing (it has no watchdog; its crash record is written once at a start
and once at an end by the app itself, with no reader beside it). The watchdog's own design and its two
reviews are in the copy: `archiver/docs/progress/` (search for the watchdog's report) and the package's
doc comment: read them first; the status file's meaning and its names do not change.

## 2. What to build

- **The status file and the marker file** (find every file the watchdog puts in place by a rename or
  rewrites in place while others may read it: the status file, the `running` marker, anything else in
  `internal/watchdog`; the rotation of the output log in `output.go` is NOT part of this unless a reader
  can break it the same way: say what you found) **are put in place with a rename that Windows carries
  out while a reader has the target open with delete sharing.** Verify the pages track's finding yourself
  before relying on it: a test that loops a reader (opened as Go's `os.Open` opens on Windows, and as
  PowerShell's `Get-Content` would: say which sharing each has) against 3,000 writes, counting refusals,
  first with today's rename (expected: many), then with yours (wanted: 0). If `os.Root.Rename` is the
  way, use it; if the measurement on this toolchain (the project's Go, `ix-tools/goroot-1.27.3`) says
  otherwise, say so and use what the measurement supports (the Windows call for a POSIX-semantics rename
  directly, through `golang.org/x/sys/windows`, is allowed: no new module).
- **A second net, bounded:** a rename that is still refused is tried again a few times with short pauses
  on the watchdog's own clock (a routine write: at most about 200 ms in all; **the final write at the
  watchdog's end: up to 2 s**, because a lost last write leaves "running" on disk). Never an unbounded
  loop; the watchdog's supervision of its child must not be held up by a status write (check where
  `writeStatus` is called from and that a slow write cannot delay a restart decision or a stop).
- **A reader must never see a half-written or missing file:** at every instant the name holds a whole
  earlier document or the whole new one (keep the temporary-file-then-rename shape; no delete-then-write).
- **Counted as today** (`status_write_failures` only for a write finally lost), plus one new count for
  renames that needed a retry; the counts are in the status document itself: adding a field must not
  break its readers (grep the module for readers of the document's fields: the launcher on
  `wip/pages-g6` is not on the main head; keep every existing field and name as it is and only add).
- Other platforms compile and behave as before (build tags as the package already uses them).

## 3. Tests and runs

Named tests in `internal/watchdog`: the reader-against-writer test above (Windows; skipped elsewhere),
with the counts of both ways printed; the final write retried longer than a routine one; a write finally
lost is counted and the temporary file removed; no half-written document is ever read (the reader parses
every read as JSON). No sleeps on real time beyond what the reader loop needs: bound the test to a few
seconds and say its seconds.

Run (the PC is shared: before each go command read free memory with
`powershell -NoProfile -Command "[int]((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1024)"`
and wait if it is under 2,500 MB; `GOGC=25 GOMAXPROCS=2`; Go through
`source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`): `go build ./...`;
`gofmt -l internal/watchdog`; `go vet ./internal/watchdog/ ./cmd/...` (the watchdog's command); the whole
small `internal/watchdog` package on Windows; `GOOS=linux go build ./...`. No Docker, no race detector
(mine, once: the package has goroutines). Never start the installed watchdog or collector; your tests use
the package's own stand-in child, as its existing tests do.

## 4. Limits and hand-back

- Files: `internal/watchdog/*` and its command only if a line there writes one of these files; a report
  `archiver/docs/progress/core-wdrename-REPORT.md` (no path of this PC in it). No other package.
- Commits with `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, each message ending
  with a blank line and `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; pushed with
  `git push private wip/core-wdrename`; `git status --short` empty at the end.
- Your final message: the head's full hash, the measured refusals of 3,000 with the old rename and with
  yours (and with which reader), every file the watchdog puts in place and what you did with each, the
  commands with results and seconds, anything in this brief you found wrong (check the door in the code
  before relying on my word for it).
