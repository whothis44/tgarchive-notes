MAY BE LISTED

# Review K12: the watchdog's status file put in place while another program reads it (2026-11-16)

Reviewed: `wip/core-wdrename` at 2282ec43 against 5b29e28b (7 files, `internal/watchdog` and the report).
Independent and adversarial; read-only on the tree. Probes: a stand-alone program built with the project's Go
1.27.3 in the review's scratch folder, invented documents only, temporary folders removed afterwards.

Count: 0 MUST FIX, 3 SHOULD FIX, 4 MINOR.

## The missing name (the finding that matters most)

**CONFIRMED: a reader with delete sharing (the launcher's way) can get ERROR_FILE_NOT_FOUND (2) on
`watchdog-status.json` while the writer is inside the rename call itself, under either rename; never at any
other moment, and the name is never gone once the call has returned.** The probe mirrors `writeStatusFile`
(the leftovers' listing and clean-up, `os.CreateTemp`, write, close, rename) with one writer and one reader
looping, and records the writer's phase at every "not found" plus an `Lstat` of the name after every rename:

| writer | runs with misses | misses in such a run | writer's phase at each miss | name gone after the call returned |
|---|---|---|---|---|
| `os.Root.Rename` (K12) | 4 of 16 (3,000 writes each) | 1,065 to 1,595 | all inside the rename step; in the run where it was split, all inside `Root.Rename` (none in `OpenRoot`, `Close`, the temporary file or the clean-up) | 0 of 48,000 |
| `os.Rename` (before K12) | 1 of 7 | 1,425 | (before the phase counter was added) | 0 |
| POSIX rename by hand, no fallback | 0 of 6 | - | - | 0 |
| legacy replace rename by hand | 0 of 4 | - | - | 0 |
| reader alone; temporary files only, no rename | 0 of 1 each | - | - | - |

It comes in episodes: once a run has its first miss, almost every later rename gives some (one run: first miss
at write 2,845 of 3,000, then 1,595 misses). Seen in the user's temporary folder and once in a plain folder
under the project, so not only a temp-folder filter. Not the package and not the test's harness: the probe has
no `t.TempDir`, one writer, and the clean-up matches `.watchdog-status-*.tmp` only (the leading dot means it can
never match `watchdog-status.json`: read and sound). Not a delete-then-rename in Go either: the toolchain's
`os.Root.Rename` goes to `internal/syscall/windows.Renameat` (`at_windows.go` 439-511): `NtOpenFile` of the
source with DELETE, `FileRenameInformationEx` with REPLACE_IF_EXISTS | POSIX_SEMANTICS, and on ANY failure a
second `FileRenameInformation` with ReplaceIfExists (the legacy replace); neither removes the name first. The
mechanism is in Windows' rename-over-a-target (NTFS or a filter driver) and is PLAUSIBLE only; what is CONFIRMED
is when it happens and that no writer can avoid it. So every reader must read again after a "not found".

## Findings

1. **SHOULD FIX, CONFIRMED (the launcher: pages track's packages), `internal/launcher/status.go` 78-89 and
   `findLeft` 105-124.** `readWatchdogStatus` reads once; a "not found" during one of the watchdog's renames at
   the launcher's start makes `docOK` false, the marker's watchdog cannot be confirmed, `openOurs(m.Child, ...)`
   finds the running collector and the launcher shows "a collector runs without its watchdog" with a Stop offer
   while the watchdog supervises it (launcher.go 447-452; the stop path's own `findLeft` at 925 re-reads, which
   makes a wrong stop unlikely but not the wrong screen). Smallest fix: in `readWatchdogStatus`, read again up
   to 3 times about 20 ms apart when the open says not found or the body does not parse. Not K12's to change;
   for the board's messages.
2. **SHOULD FIX, CONFIRMED, `internal/watchdog/status.go` 149-151 and the report's "Seen and not explained" and
   open point 2.** The comment "The name is never deleted before the new document is whole: it names the old
   document or the new" is true of the package's own steps but reads as a promise to readers that Windows does
   not keep; the report puts the cause on "a file-system filter on a busy PC" without evidence. Smallest fix:
   the package doc of `StatusName` says a reader on Windows may get "not found" (and, item 3, a sharing
   violation) for a moment during a rename and reads again; the report replaces its guess with the measurement
   above.
3. **SHOULD FIX, CONFIRMED, readers without delete sharing (`os.Open`/`os.ReadFile`, `crashlog.ReadMarker`,
   PowerShell `Get-Content`).** Right after each rename that goes through, the writer's own handle (DELETE
   access, held until the call returns) is on the file now named `watchdog-status.json`, so such a reader's open
   gets ERROR_SHARING_VIOLATION (32): probe 3,008 to 4,533 failed opens per 3,000 writes with `os.Root.Rename`,
   1,036 with `os.Rename` (fewer because most of those renames were refused). The package's own test logs these
   (`not opened (codes map[32:...])`) but the report does not mention them. Not a regression in kind, more
   frequent per write. Smallest fix: say it in the report and the doc (item 2); the a3 scripts read again on any
   open failure.
4. **MINOR, CONFIRMED by reading, `internal/watchdog/rename_windows_test.go` 66-85 and 141-143.** The test only
   logs a "not found" (right, given the above), so nothing would catch a regression that deletes the name
   before writing (it would show as misses outside the rename). Smallest fix: the test's writer sets an atomic
   "inside the rename" flag around `renames.rename` (a wrapper in the `renameOps` it passes), the reader counts
   misses while the flag is off, and the test fails on any; also `Lstat` the name after every write.
5. **MINOR, CONFIRMED by reading, `internal/watchdog/loop.go` 519-523 and 557-559.** A final write finally lost
   after the 2 s is counted only in `status_write_failures`, which lives in the document that was not written,
   and no line is printed: the file says "running" or "waiting" until `stale_after` (2 minutes) and nothing on
   disk or in the watchdog's lines says why. The launcher already copes (`ended` and `endedOther` treat a
   status not saying "ended"); the owner's scripts see stale only. Smallest fix: in `end`, one constant-format
   `w.printf` line when the last write is lost.
6. **MINOR, PLAUSIBLE, `internal/watchdog/rename_windows_test.go` 173-176.** The case "a delete-sharing reader
   refused N single POSIX renames" fails the test on any refusal. In 48,000 `os.Root.Rename` writes the probe saw
   none, but the hand-made POSIX rename without fallback was refused 2 of 18,000 with access denied beside the
   same reader, so something else holding the target for a moment (an antivirus scan) can fail the test on a
   busy PC. Smallest fix: log that case, keep the hard assertion on the K12 way (retried, 0 lost).
7. **MINOR, CONFIRMED by reading, `internal/watchdog/rename_windows.go` 35-37.** Access denied is retried
   whatever its cause, so a refusal that is not a reader's (a read-only attribute on the status file, a denying
   ACL) costs 200 ms of pauses plus about 7 tries at every write (about 0.35% of the loop's minute) and is then
   counted lost. Bounded and counted: acceptable; worth one sentence in the report. Disk full, a missing folder
   and an unwritable folder fail in `os.CreateTemp` or the write and are not retried (checked).

## Checked and sound

- **The loop is never held up beyond the bound.** `writeStatus` is called only from the loop goroutine (`watch`:
  after the start, a stop, each beat, the child's exit; `wait`: its start and beats; `end`); no other goroutine
  writes the file, so two renames cannot race. In every case the action comes before the write: a stop is passed
  to the child (`noteStop`) before it, the next beat and the drain grace are set before it, the end's time is
  taken before it, the exit and drained channels are buffered, and restart decisions use recorded times. A
  routine write blocks at most 200 ms of pauses plus its tries, and only while a reader refuses; a reader that
  refuses for minutes costs about 0.2 s per minute. The 2 s is spent only in `end`, reached before any child
  (marker broken, orphan, cannot start, stop pending) or after the child has ended and its streams drained; the
  lock is held during it, and the launcher waits for the process's exit, so no new watchdog collides.
- **The marker's retry.** `crashlog.WriteMarker` is idempotent (removes and rewrites `running.tmp`, removes it on
  a failed rename), so calling it again is safe; its trailing `Chtimes` needs only attribute access, which no
  reader's sharing refuses. `crashlog.End` (history line plus marker removal) is NOT wrapped: no doubled line.
  The retry runs before the copiers start, so the child's output waits in its pipes up to about 200 ms: as
  before K12 a marker write sat there too.
- **Temporary files and counts.** `writeStatusFile` removes its temporary file on every failure path (rename
  lost after the budget, other failure); `status_write_failures` counts only writes finally lost;
  `renames_retried` only writes that went in place at a later try (`putInPlace` returns `retried && err == nil`).
- **The status document.** Every existing JSON name unchanged; one field added (`renames_retried`). Readers in
  the module: the launcher (`json.Unmarshal` into `watchdog.StatusDoc`, no `DisallowUnknownFields`) and the
  watchdog's command (in-process observer); none strict. No PowerShell script in the project refers to the file
  by name.
- **Other platforms.** `rename_other.go` keeps `os.Rename` and retries nothing. `GOOS=linux go build ./...` and
  `GOOS=linux go vet ./internal/watchdog/` pass; Windows `go vet ./internal/watchdog/ ./cmd/tgarchive-watchdog/`
  passes; `gofmt -l internal/watchdog` is empty.
- **Tests.** `go test -count=1 ./internal/watchdog/`: ok, 4.1 s (the looping-reader test 1.6 s with 150 writes;
  my run: 0 missing, 0 not whole, codes 32 only for the `os.Open` reader). The retry tests use a fake pause, so
  they do not depend on real time; `withRenames` swaps a package variable, safe because no test in the package
  is parallel.

## Where the brief is wrong or silent

- It asks that a reader never see a missing file. No writer can promise that on this Windows: the name can be
  "not found" for a moment inside the rename call itself (above). The duty is the readers': read again.
- "0 of 3,000 with a rename of the POSIX kind" holds only for readers with delete sharing; readers without it
  (`os.Open`, `Get-Content`) still refuse it about 480 times in 3,000 (the coder measured and said so).
- It says the launcher is on `wip/pages-g6`, not on the main head: `internal/launcher` is in this base and
  reads the status file (`readWatchdogStatus`), which is where finding 1 lies.
- It is silent on the sharing violation a reader without delete sharing gets right after a rename (finding 3).
- It names a watchdog report in `docs/progress`; there is none (the coder found the reviews in `docs/review`).
