# Review G6, second pass: the fix round of the launcher (independent, read-only)

## What was reviewed and how
- **Reviewed:** `wip/pages-g6` at 19a64824 in the copy `wt-pages-g6`.
  - The fix round is `51d7656a..3a2981b5`. Then come the merge 1214ce26 and one test-only commit.
  - The copy was left untouched: `git status` was empty before and after.
- **Read:** every changed launcher file, `make-folder.sh`, the README, the one line in `internal/server/server.go`
  and the new tests. The report's "Fix round (G6b)" section was read last.
- **Probes:** `wt-pages-review-g6-scratch\probe2_test.go`, loaded with `go test -overlay`.
  - Every process a probe started was a stand-in in the test's own job.
  - No real program of the app was started, no real folder or port of the app was used, and nothing talked to
    Telegram.
- **The package's whole tests, once:** they passed in 33 s. The first pass's run had failed (M2).

**Count of new findings: 0 must-fix, 4 should-fix, 7 minor.** Of the 24 old findings: 20 closed, 3 partly closed,
1 not built (as decided).

## The 24 findings of the first pass

| finding | now | evidence |
|---|---|---|
| M1 viewer's window invisible | **closed** | Children are started with `CREATE_NO_WINDOW` and no hide flag (`proc_windows.go:115-118`). My probe now reports visible=1 for a window shown with `SW_SHOWNORMAL`. The test `TestViewerWindowShownAndStoppedCleanly` checks the same, plus the clean stop. |
| M2 bind while waiting | **closed** | `look` only connects (`probe.go:46-73`). The one `free` is before anything is started (`launcher.go:467`). My probe: 4204 binds, 0 refused while looking. The start flow at a 50 ms poll: 30 of 30 opened the pages (the first pass had 3 failures in 95). Its test guard is weaker than said: see minor 2. |
| S1 "already open" took any pages | **closed**, two open edges | The pages are taken for this folder's only when this folder's watchdog is held AND the pages answer with `X-Tgarchive-Pages: 1` (`launcher.go:433-443,285-291`). The open edges are new findings N1 (a junction) and N4 (answers without the mark). |
| S2 orphan by name only | **closed**, one open edge | The image path is compared with this folder's program, and the start time is checked (`status.go:43-139`). Probe: another folder's collector named by this folder's marker is not taken (kind 0). The open edge is a folder reached through a junction (N1). |
| S3 acts by number | **closed** | One handle (query, terminate, synchronise) is opened at the check and every act goes through it (`proc_windows.go:41-100`). Programs the launcher started are held from right after the start, while Go still holds its own handle (`start.go:76-80`). The helper gets the number and the exact creation time, checks them on its own held handle, and keeps that handle through `AttachConsole` (`proc_windows.go:138-162`), so the number cannot be reused in between. |
| S4 viewer closed at any end | **closed** | The viewer is stopped only on exit code 0 (`launcher.go:655-658`). Probe: after a crash the viewer still runs. A "Close the viewer" button is offered. |
| S5 running check before the build | **partly** | The script now checks right before the replace and before each move (`make-folder.sh:116,129,134-135`). New finding N3: a refusal in the middle of the moves leaves a half-replaced folder and says "nothing was changed"; a running `tgarchive.exe` is not checked. |
| S6 foreign and repository folders | **closed**, one edge | It refuses any git work tree, its own folder, a foreign `tgarchive.exe`, and a non-empty folder without `folder.version`; the folder is made only after these checks. The edge is minor 6 (an interrupted first build is refused for ever). |
| S7 second launcher did not follow | **closed** | It follows this folder's watchdog and opens the pages (`launcher.go:434-443`), tested. One false sentence at the end remains: minor 1. |
| S8 tests killed by number | **closed**, one edge | A job object per test; the clean-up ends that job only. No test looks for a process by name or number any more. The edge is minor 5 (a short window before a stand-in joins its job). |
| S9 only "End it now" | **closed** | "Wait longer" and "End it now" are both offered, with the seconds since the clean stop (`launcher.go:821-879`), tested. |
| minor 1 non-public addresses | **closed** | Probe: 0 of 7 non-public answers are taken. |
| minor 2 same port spelt twice | **closed** | Ports are compared as numbers; probe: refused. |
| minor 3 proxy, redirect, agent | **closed in the code**, test weak | The lookup has its own client with no proxy, no redirect and Go's own agent. The test cannot catch a proxy coming back: minor 3. |
| minor 4 data race on `l.s`/`l.lay` | **closed by reading** | Both are under a lock (`cur`, `setCur`). No race run was made. |
| minor 5 no idle end | accepted | Unchanged, as agreed. |
| minor 6 page opened once per life | **closed** | Opened again after the owner went to the pages; tested. |
| minor 7 "nothing runs" beside a refusal | **closed** | The new words name the living program and send the owner to Task Manager. With N1 those words also appear for this folder's own collector. |
| minor 8 the launcher's own crash | **closed** | `debug.SetCrashOutput` writes to `data\logs\launcher-crash.log`. |
| minor 9 README | **closed** | The README was checked against the code. Its line "only opens its pages" is not true while the collector is still starting (N4). |
| minor 10 weak "opened once" check | **closed** | It is now counted after the launcher has ended. |
| minor 11 data folder made on a refused form | **closed** | Tested. |
| minor 12 where the collector's words are | **closed** | Shown on the page. |
| minor 13 catalogue copy before a migration | not built | As decided: it belongs to the backup program and the core track. |
| minor 14 Ctrl-C reaches the whole console | **closed** | Said in `SendCtrlC`'s comment. |

---

## New findings: must fix before the owner opens it
None.

## Should be fixed

### N1. A folder reached through a junction is never "this folder's". CONFIRMED (probe)
Where: `status.go:43-54` (`samePath`), `folder.go` (`FindFolder`).

What the probe showed:
- A stand-in started through a junction to the folder reports its image path in the TARGET's form.
- `filepath.EvalSymlinks` on the junction's path fails, so `samePath` compares the junction's form against the
  target's form and answers "not ours".
- A launcher opened through the junction finds its folder in the junction's form. Its layout, and every
  "this folder's" check, then uses the junction's form.
- For comparison: 8.3 short names do resolve, and `samePath` is right for them (probe).

Sequence of events:
1. The owner opens the folder through a junction (a moved or redirected folder, a link).
2. Everything starts and runs.
3. The launcher is killed, or the owner closes it on a failure page, and the owner opens `tgarchive.exe` again.
4. `findLeft` takes neither this folder's watchdog nor its collector for "ours". What the owner then sees:
   - **The pages answer:** "Another tgarchive is using the pages' address ... Close it first". That is false.
   - **The watchdog is waiting to restart:** a second watchdog is started. It refuses (its lock), and the page says
     "The watchdog ended at once".
   - **A collector was left running without a watchdog:** it is never offered for "Stop what is left". The
     watchdog's refusal words then send the owner to Task Manager to end a downloading collector.

The same may hold for a mapped network drive or a `subst` drive; that was not tried.

Smallest change: compare file identity, not text. Open both files and compare the volume serial number and file
index (`GetFileInformationByHandle`), or compare their `GetFinalPathNameByHandle` forms. Make `FindFolder`
canonical the same way.

### N2. The launcher's reads of the status file make the watchdog's writes fail. CONFIRMED (probe)
Where: `proc_windows.go:191-206` (`openShared`), read by `ui.go` on every page refresh and by `followOther`.

The comment says the watchdog's rename "is never refused because of this reader". The probe shows the opposite: a
rename over the status file while the launcher's reader holds it was refused, even with delete sharing. The report
saw the same once in 13 tests.

Sequence of events:
1. The owner keeps the launcher's page open. It refreshes every 2 to 5 s while the launcher waits for the pages or
   follows the watchdog.
2. The watchdog's write lands while the page is reading. The write is lost; the watchdog counts it as
   `status_write_failures`.
3. If that lost write is the watchdog's last one ("ended", exit code 0, after a Quit), a launcher that is following a
   watchdog it did not start shows: "The watchdog has ended without saying why (it was ended from outside?)", with
   Try again. The launcher does not end.

The chance per end is small, but the words are false, and the comment states the opposite of what happens.

Smallest change:
- The watchdog retries its final write a few times (the report already asks Core for this).
- Meanwhile `followOther` re-reads the status for about 2 s before it calls an end "unsaid".
- Correct the comment.

### N3. `make-folder.sh`: a refusal between two moves leaves a half-replaced folder and says "nothing was changed". CONFIRMED by reading
Where: `make-folder.sh:128-136`, with `check_running` at lines 80-92.

How it fails:
- The check before each move deletes the new build (`rm -rf "$new"`) and exits 3 with "nothing was changed".
- If that happens after some moves, the old programs are already under `programs\<commit>\` and part of the new ones
  are in place. Possible results:
  - `tgarchive.exe` missing;
  - a new watchdog beside an old collector;
  - the new build deleted.
- The launcher itself (`tgarchive.exe`) is not among the processes checked. A launcher left waiting on a failure page
  (it has no idle end) can be told Try again during the moves and start whatever programs are in place at that moment.
- A probe shows a running program's image path follows a rename. A collector started in that window and then moved
  under its commit's name is no longer "this folder's" (see N1's consequences): it is never offered for a stop.

Smallest change:
- Check `tgarchive.exe` too, in the checks before the build and right before the moves.
- Once the moves have begun, finish them without checking again (or roll back all of them).
- Say truthfully what state the folder is in.

### N4. The collector's starting, no-pages and stopping answers carry no mark. CONFIRMED by reading and probe
Where: `probe.go:61-72`; `internal/collector/pages.go:194-232` (outside this change). Probe: the starting page is not
taken for the pages.

What follows:
1. **A slow start.** While the collector opens and recovers a large catalogue, its starting page answers. After 90 s
   the launcher's page says "The pages did not answer within the time allowed" while they do answer.
2. **Pages that cannot be made.** The no-pages page (with its own Quit) is never opened. The launcher waits until the
   watchdog ends. Its page shows no link to the address and has no way to stop the watchdog.
3. **Opened again during a start.** `tgarchive.exe` opened again while this folder's collector is still starting
   follows the watchdog with `opened=false`. It never opens the pages when they do come up: `followOther` does not
   look for them again.

Smallest change:
- The pages track puts the same header on those three answers (the coder has asked).
- Meanwhile the running view shows the pages' address as a link, and `followOther` keeps looking for the mark and
  opens the pages once.

## Minor
1. **A false sentence after following.** A launcher that followed a watchdog says at Quit "The viewer the launcher
   opened was closed". It opened none, and the viewer of the earlier, killed launcher stays open (`launcher.go:719-721`
   with `words.go` `wordEndedClean`).
2. **The M2 guard covers `look` only.** `TestLookNeverBindsTheAddress` would not catch a bind put back into the wait
   loop of `begin` itself (for example `free` called when `look` says nothing answers).
   - `TestStartFlowRepeatedNeverBindsPages` catches that only by chance: about 3% per start at the 50 ms poll, so
     about 70% over its 40 starts. The coder's own mutation run shows it passing while the bind was in.
   - A firm guard: a stand-in collector act that binds and releases its pages address in a tight loop while the
     launcher waits, failing on any refused bind.
3. **The lookup's proxy test cannot fail.** Go never proxies a request to 127.0.0.1: the proxy rules leave out
   loopback. The `HTTPS_PROXY` part of `TestPublicLookupNoProxyNoRedirectNoName` therefore passes with
   `Proxy: http.ProxyFromEnvironment` put back. Check `publicClient`'s transport `Proxy == nil` directly instead.
4. **Handles kept for the launcher's life.** Every program the launcher starts keeps its handle until the launcher
   ends (`sysProc.Close` is a no-op), including one Ctrl-C helper per stop click. Small, but it has no bound.
5. **The job is joined late.** A stand-in joins its test's job itself, from `TestMain`, after its runtime has
   started (`standin_windows_test.go:24-39`). If the test binary is killed in those milliseconds, that stand-in is
   left outside the job. Start the stand-ins suspended and assign them to the job (or use the job attribute at
   creation).
6. **An interrupted first build is refused for ever.** `folder.version` is written last. A first build stopped in
   the middle leaves a non-empty folder without it, and the script then refuses it for ever. The same applies to a
   folder made by the first-round script. The refusal could say that deleting the folder (no settings or data in it
   yet) is the way out.
7. **Every look asks for the right to end the process.** A look opens with terminate rights. A collector of this
   folder running elevated is therefore not seen; the watchdog's refusal words cover it ("or it could not be
   checked"). Accepted by the coder; noted.

## The fix round's tests
- **Real time:** none of the new tests judges on real time. Waits are bounds; the 40-start test and the 2000-bind test
  are bounded by attempts. `TestOrphanWaitLongerAndEndNow` uses a 1 s stop bound against a stand-in that never ends
  by itself, so the result does not depend on timing.
- **Mutations:**
  - 1, 3a, 3b, 4a and 4b would be caught as described.
  - 2 is caught by the direct test only because the mutation was put into `look` (minor 2).
  - Minor 3's test would not catch its proxy mutation.

## Checked and found sound
- `CREATE_NO_WINDOW` cannot bring a console window onto the owner's screen through a child. The watchdog starts the
  collector on its own console with no window. ffmpeg is started with `CREATE_NO_WINDOW` (`internal/footage/ffmpeg`,
  `internal/viewer`), and mpv as a detached process. No program of the module starts a child with a new visible
  console.
- **The handles:**
  - the rights are query, terminate and synchronise;
  - the image path and the creation time are checked on the handle itself;
  - no act goes by number after a check;
  - a number cannot be reused while it is held.
- **The helper:** exact creation time, its own held handle across `AttachConsole`; the event reaches only that
  program's console.
- The launcher's page server lets answers in flight finish (2 s). Probe: its fixed address could be bound again at
  once after a shutdown with answers served (3 rounds).
- `internal/server` has a one-line, constant change with no concurrency: no race run is needed there.
- Following a watchdog the launcher did not start: it is held from the check; its end is read from its status file;
  a collector it left behind is offered for a stop. Two launchers cannot both follow it (`launcher_addr`).
- `make-folder.sh`: the git work-tree check, the own-folder check, the foreign-folder check, the folder made only
  after the checks, and the running check by both paths (resolved and as given).
- Tests: no test reaches a process it did not start. Stops go through the test's own handle or its job.
  `findLeft` only meets markers naming the test's own stand-ins.

## Not looked at / not verified
- A real window, collector, watchdog, viewer or VPN (none started).
- A mapped network drive, `subst` drive or directory symlink for N1 (only a junction and 8.3 names were tried).
- `make-folder.sh` was not run by me beyond its tests in the package's run.
- What Windscribe does with a renamed running collector.
- The Linux build (by reading only).
- `internal/server`'s other tests.
- The deploy/thumbs files that came in with the merge (not part of this round).

## The race detector
Only `internal/launcher`. Concurrent code there changed: the lock on the settings and layout, the page server's
handlers, the shutdown, and the held handles' lock. Run it on Windows if possible. `cmd/tgarchive-open` and
`internal/server` (one constant header line) need no race run.
