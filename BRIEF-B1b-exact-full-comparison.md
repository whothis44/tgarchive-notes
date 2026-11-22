# Brief: the exact check compares a video in full, with its guards (tenth session, 2026-11-14)

For one Opus coder in `C:\Users\trabi\Claude\Projects\Telegram\wt-exact` (branch
`wip/exact-check-2026-11-13`, on top of 6eb8311: the exact check with its review's findings F1 to F10
fixed). This is the part of the exact check's brief that was never built: its ADDENDUM.

## Read first, in full

1. `C:\Users\trabi\Claude\Projects\Telegram\repo-archiver\archiver\docs\FEATURES.md`, section 12,
   **"Thirteenth round"** (line 468 on; this copy's `FEATURES.md` is older and does not have it). It is the
   owner's decision and the specification: every guard and count in it is part of this piece, none optional.
2. `wt-exact/archiver/docs/EXACT-CHECK-BRIEF.md` with its addendum, and
   `archiver/docs/progress/exact-REPORT.md` (what exists).
3. `C:\Users\trabi\Claude\Projects\Telegram\repo-archiver\archiver\docs\TRIED-BEFORE.md` sections 6, 8 and
   27 (this copy's file lacks 27).
4. The code as it is: `internal/exact`, `internal/engine/check.go`, the catalogue's and supply's exact
   files, `internal/telegram/parts.go` (hashes), `internal/store` (opening a saved copy).

## What to build

1. **The setting with three values** (the way back; no new build to change it): `full` (the default),
   `three-places` (what exists today: a full comparison within 64 calls, three places for a video over
   that, held), `off`. Kept in the catalogue's settings so the owner changes it without a build; read at
   each check.
2. **Full comparison.** In `full`, every window of the file is compared whatever its size: the bound of 64
   calls does not stop it. Same only when every window matched and the windows cover every byte
   (the coverage and gap rules of F4, F7 and F8 stay). The saved copy is read window by window, never
   whole into memory; memory per comparison stays bounded by one window.
3. **Budget per server and hour** (a config field): when the hour's hash requests on a server have
   reached it, no new full comparison starts there in that hour. The file is **held** with the fixed
   reason "same size, not compared yet": never skipped, never downloaded unchecked ahead of unique files;
   counted (`budget_held`). A comparison under way finishes. Default 1,000 requests, marked provisional in
   its comment: it is to be set from the first measured request on the test account, which the owner
   starts later.
4. **Three waits.** A wait on a hash request holds that server's checks only (built). New: three such
   waits on one server within an hour stop full comparisons on that server for the rest of the hour: files
   held as in 3, counted, one log line when it trips.
5. **Two hash requests in flight per server** (built, F2): confirm it also bounds a long comparison's own
   calls, and say so in the report.
6. **The record of each comparison** (catalogue, in the piece's own schema step 11, which has not merged:
   extend it, no new number): windows compared, bytes covered, requests, the candidate, the outcome,
   seconds taken, and the windows in each answer (so that smallest, usual and largest windows per answer
   become a number). **One log line per comparison:** server, size class, windows, requests, seconds,
   outcome; constant format, numbers and fixed words.
7. **Spot check.** One file in every hundred that the check called same (a config field; the count kept
   in the catalogue so a restart does not reset it) is downloaded all the same, and at its finish its
   whole-file SHA-256 is compared with the saved candidate's. Equal: counted, and it is linked as a same
   file is. Different: an alarm line in the log, counted, and **the setting goes to `off` and stays off
   until the owner switches it on again** (a fixed reason kept with it). Also a per-file "fetch for real"
   mark that makes the check step aside for that file.
8. **The library's turn.** Bytes read from saved copies are counted per hour. A comparison whose candidate
   is no longer in staging (it would read the library) does not start while copies to the library are
   waiting: the file waits its turn (not held, not downloaded; counted as waiting seconds). Find how the
   store tells "copies waiting" and use that; if there is no such signal, add the smallest one and say so.
9. **Hourly totals** per server in a table (requests, answered, waits, seconds asked, timeouts,
   comparisons by outcome, budget_held, wait-rule holds, spot checks and their results, bytes read),
   written by the existing flush.
10. **Found by the main session reading `engine/check.go`:**
    - `holdChecks` and `keepFileWait` keep `now + d` with no margin. The first real run showed what
      asking again the instant a wait ends does to parts (TRIED-BEFORE 27). Add the engine's `gateMargin`
      (1 s) to both ends. A test: a hash wait of 1 s at T, no hash call on that server and no part of that
      file before T+2 s.
    - Line 251: `cs := e.cfg.Supply.(CheckSupply)` is an unchecked assertion, while `expireChecks` uses
      the checked form. Show where a Checker without a CheckSupply is refused at construction (and test
      it), or use the checked form.
11. **The collector's fake Telegram answers hash calls**, so that an end-to-end test reaches same,
    probable (held) and different. One such test for each.
12. **Order of checks:** a held file whose byte size equals a saved file's goes to this check first when it
    is claimed; nothing else may release it until Telegram's hashes said "different". Show by a test that
    this is what happens today, or make it so.

Every item: a test that fails without it (a bounded mutation, restored and checked with `cmp`).

## Not in this piece

- No request against Telegram, so no measured default for the budget: leave the provisional one.
- Keeping window hashes of a file at save time (so a comparison needs no read of the library): note in
  the report what it would take; do not build it.
- The per-minute writing of counts (the logging piece does that for every table).
- No rebase onto the branch: the main session does that after the wait margin has merged.

## Bounds (the owner's rules; no exceptions)

- Nothing against Telegram; never start the collector or any program of the app; tests only. Never touch
  anything under `E:\T\` or any process you did not start.
- Work only in `wt-exact`. No push, no commit: leave commit-ready work in the working tree with a proposed
  commit message.
- Go: in Git Bash, `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh` (not
  `env.sh`: its toolchain was damaged by a clean-up; the `-overlay` stand-in is no longer needed).
- Every go command: `GOMEMLIMIT=1GiB GOMAXPROCS=2 GOFLAGS=-p=2`; tests with `-count=1 -timeout 300s` (90s
  for mutations) and `-run` naming tests, one package per command. No whole run of `internal/catalog` or
  `internal/collector`, no race detector, no Docker. At the end `gofmt -l` on changed files and `go vet`
  on changed packages, one each.
- Memory gate before every go command:
  `powershell -NoProfile -Command "[math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB,1)"`;
  under 3.0 do not run; write code meanwhile and try again minutes later.
- One go command of yours at a time. A mutation is never left in place.
- Before handing back: no `*.test.exe`, `go.exe` or `compile.exe` of yours left running.
- Update `archiver/docs/progress/exact-PROGRESS.md` after each item; bring `exact-REPORT.md` up to date at
  the end, with each of the thirteenth round's guards and counts listed as built (test, mutation) or not
  (why).
- Privacy: numbers and fixed words only in anything printed, logged or written; invented test data; the
  privacy guard test covers every new log line.
