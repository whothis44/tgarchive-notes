# Review of L1: the launcher's bring-in step and door F2 (pages, P7, 2026-11-22)

Read: `BRIEF-P7-review-L1.md`, `BRIEF-P7-review-rules.md`, `BRIEF-L1-bringin-step.md`, `CONTRACT-bringin-step.md`, the coder's
report, and the whole diff `d46aa8f6..72117787` (`bringin.go`, `bringinpage.go`, `bringwords.go`, `apistate.go`,
`bringlock_*.go`, the changes in `launcher.go`, `present.go`, `ui.go`, `page.go`, `make-folder.sh`); beside it the
launcher's `change.go`, `follow`, `waitOwner`, `rescope`/`endProc`/`stopViewer`, `ownJob`, `another`, the
collector's `lock_windows.go`, and B9's listed program `wip/b-unified` 152fc6bd (`cmd/tgarchive-bringin/main.go`,
`internal/bringin/intoexit.go`, `run.go`, `into.go`). Ran, in the scratch copy `wt-pages-review-l1-scratch` at 72117787,
through `runs-pages-p6/go1.sh` with TEMP/TMP/LOCALAPPDATA/APPDATA in `%TEMP%\p7-l1rev\`: one probe
(`zz_probe_l1_test.go`, `TestZZProbeYesAfterInputsChanged`, uncommitted) and the piece's named tests
(`TestBringin.*|TestAPIState.*|TestSoloWindow.*`). Stand-ins only; no window; nothing of the owner's touched.
Line numbers are on 72117787 (the piece is not on af4ca40e: `git merge-base --is-ancestor` says not merged).

## Findings

1. **MUST FIX: the yes does not belong to the inputs the run uses; no dry run of the same inputs comes before the
   run.** Confirmed by `TestZZProbeYesAfterInputsChanged`: dry run on catalogue A (counted, a fingerprint); the old
   database's bytes changed; "Change the folders" to another data folder (catalogue B); the start again; the page
   still in `counted` with the same `yes`; the old page's yes POSTed: HTTP 303, the app stopped, and the run started
   with `-new` = catalogue B (`-new` = A: false; plan runs: 1). Cause: `fingerprint` (bringin.go:545) hashes the
   paths and counts, but `bringYes` (bringin.go:663) only compares the posted value with the stored one, which was
   made from the same old inputs; `bringRun` takes the catalogue from `l.cur()` at the run (bringin.go:782, 808),
   not the one the dry run read (startPlan's `lay`, bringin.go:565/582); nothing records or checks the old
   database's identity (size, time, a `-wal` beside it), and the counted page has no age. How the owner meets it:
   (a) after a "Change the folders" while the counts page stands (or while the dry run runs), the yes brings the old
   archive into a catalogue whose counts were never shown; (b) every day as it is now: the dry run counts while the
   collector writes the catalogue and the old app (running until 11-29) writes its database; the yes can come hours
   later, and the run reads other inputs than the counts were made of; only the program's own guard (exit 4) stands
   between. Smallest cure: keep with the counts what they were made of (the catalogue path; the old database's path,
   size, modification time and whether a `-wal` is beside it) and check it in `bringRun` after the stop, before the
   run: anything different ends the step with fixed words ("the counts are of other files: count again") and the
   start again; also clear `counted` (back to choose) on any change of the settings or folders. Better (the brief's
   "a dry run of the same inputs just before"): after the stop and the lock, run `plan` once more with the run's exact
   arguments, and run only when its counts equal the fingerprinted ones; otherwise show the new counts, app stopped,
   and ask the yes again (with "start the app without it").

2. **SHOULD FIX: the bring-in's programs are not in a job; a run outlives a launcher that is killed or crashes, and
   the next launcher does not see it.** By reading. `runBring` starts the program with `l.env.Start` (bringin.go:476);
   `ownJob` (proc_windows.go:207) is used only for the window and the close box ("nothing else is ever put in the
   job"). `bringEndAll` (bringin.go:326) covers the orderly end only, and only for a dry run (the run is on the run's
   goroutine, which cannot end while it runs). How the owner meets it: the launcher is ended from Task Manager, by a
   crash or by a sign-out during the 15-minute run; the run goes on writing; the owner opens tgarchive.exe again;
   `findLeft` knows only the collector and the watchdog, so the start runs the watchdog and the collector, which
   refuses on the lock (if K24's lock is the same file) and the page says the collector refused; the step is offered
   again; a yes then waits 60 s and says "The collector did not let the catalogue go" (untrue: the bring-in holds
   it); the F2(a) window opens the viewer on a catalogue under a bulk write. Cure: `ownJob` for every bring-in
   command (kill on the job's close is safe by the contract: Ctrl-C or a kill half way is resumable), and let the
   start's look (`findLeft` or the gate) count a `tgarchive-bringin.exe` of this folder that runs, with its own words.

3. **SHOULD FIX: the old library the owner chooses goes nowhere, and the step can be done for good without it.** By
   reading. The library is in the fingerprint and in `bringin-step.json` (bringin.go:801, 910) but on no command
   line (bringin.go:582, 808) and read by no code. Once a run ends `done`, the step is never offered again
   (bringin.go:425), so a later launcher that learns K24's setting (or B9's `-old-library`, said to come on
   `wip/b-unified`) has no moment to hand it over. How the owner meets it: K24 and B9's `state` land before the
   launcher passes the library; the owner chooses the library in Windows' folder box (the intro says the archive
   "its database and its library" is brought in), runs the step to done, and the old files are not resolved by the
   app; nothing says so. Cure: until the hand-over exists, do not offer the step (a `state` count for the second
   root's door, or the launcher's own flag), or say on the counts page that the library is kept for later and add a
   one-time hand-over that does not depend on the step being offered.

4. **SHOULD FIX: a reader that did not end is not a stop; the run goes on.** By reading. `stopViewer`
   (launcher.go:1105-1124) and `endProc` (present.go:1157-1176) wait a bound after the Ctrl-C and after the kill and
   then return whatever happened; `bringRun` (bringin.go:780-787) goes on to the lock and the run without asking
   whether the window's process or the viewer has ended. Readers the launcher did not start (a viewer or a backup of
   this folder started by hand) are not looked for at all, though `make-folder.sh` already finds them by path. How
   the owner meets it: a window or viewer that hangs in its close (a share that does not answer) keeps the catalogue
   open as a reader through the whole bulk write (Core's 1a: the WAL cannot checkpoint; it grows by the run's size).
   Cure: after `setSolo(false)/rescope(false)/stopViewer`, check that each handle has ended and that no
   `tgarchive-viewer*`/`tgarchive-window*`/`tgarchive-backup*` of this folder runs (make-folder's rule); otherwise end
   the step with fixed words and start the app again.

5. **MINOR: "Cancelled" is said even when the run ended otherwise after the Cancel.** By reading: bringin.go:830-839
   puts `cancelled` before the outcome, so a run that finished `done`, `would-change` or `failed` within its chunk
   after a Cancel is said as "Cancelled: what was written stays ..." (the gate then says complete, or the real
   reason is lost). Cure: when the outcome is known and is not `failed`, say the outcome; "Cancelled" only for
   `failed` (or an unknown end) after a Cancel.

6. **MINOR: two of the run's ends say "nothing was written" where the program may have written, and skip the long
   start.** By reading against 152fc6bd: `busy` is any SQLite busy at any chunk (`IsBusy`, intoexit.go), and
   `door-missing` is checked per stage after the start mark and earlier stages are written (run.go, the stage loop);
   yet `wordBringBusyRun` (bringwords.go:110) says "the bring-in wrote nothing", `wordBringDoorMissing` says "Nothing
   was written", and bringin.go:844-848 gives these the plain start bound. Cure: for the run, words without "nothing
   was written" for these two (the contract promises "before any write" only for refused), and the long bound after
   every started run.

7. **MINOR: a dry run that ends `done` with no counts at all offers the yes.** By reading: bringin.go:602 takes any
   `done` with `wouldStop()==0`; a missing `would.stop...` key counts as 0, and every row may be "not given". Cure:
   require the fixed keys the page shows (at least `messages.carried` and the would-stop key) before `counted`; else
   the unknown-end words.

8. **MINOR: the viewer's origin is trusted by a flag, not by a running window.** By reading: apistate.go:167 answers
   CORS for `http://<viewer address>` whenever `joined` or `solo` is set, including after the window has fallen or
   before it is started (`setSolo` only records the decision). What another program on that port could read is
   fixed words, numbers and the fingerprint (the yes still needs the page's token), so nothing private leaks. Cure:
   also require that the window process runs (`procRuns(w.proc)`).

9. **MINOR: two unbounded looks on the run's goroutine while the app is stopped.** By reading: bringin.go:793-799
   (`isFile` of the program, the old database and the catalogue) run unbounded after the stop; an old database on a
   share that does not answer holds the step on "waiting for the collector to let the catalogue go" with the app
   stopped and no way out but the launcher's end. Cure: `boundedIs` (already in bringinpage.go) for these three.

## Checked and sound

- Every gate condition of the contract is looked at in `gateRead` (program, no update, catalogue there, `state`'s
  complete/schema/chosen_only/doors), fails closed on a missing or out-of-range count, an unknown end, a hang past
  the bound (`TestBringinOfferedOrNot`); never offered once complete; a second start's page never offers it.
- A yes from an older dry run, a second tab after the first tab's yes (the step page's number), and a yes on a view
  that is not the running or stopped view are refused (read; `TestBringinStepFromRunning`).
- The stop is Change the folders' stop (the watchdog's Ctrl-C), a collector or watchdog of this folder found after
  it ends the step; the viewer the launcher started and the window's viewer (rescope to the launcher's page) are
  ended; the lock is waited for with the collector's own sharing rule (`lock_windows.go` share 0; `lockFree` fails
  closed) and bounded at 60 s.
- A second tgarchive.exe during the step starts nothing (`another`, `second`); the watchdog cannot restart a
  collector (it has ended); B9's run takes the collector's lock itself (run.go `HoldCollectorLock`, exit 5).
- Every exit code 0-5 with its `@ result` word maps to fixed words; a word not the code's, an unlisted code, no
  result, a line after it, a malformed or too-long `@` line: the unknown words with the exit code
  (`TestBringinOutputLines`, `TestBringinRunEnds`, `TestBringinDryRunEnds`).
- The app is started again after every end of the step (both run-loop paths fall through to `begin`); the long
  bound and words after a run that may have written, cleared once the pages answer.
- Cancel sends Ctrl-C (B9's program cancels its context on os.Interrupt), kills after 2 minutes; a Cancel that
  could not be sent ends it at once.
- B9's key names (152fc6bd `intoexit.go`) match the launcher's plan and after rows; its unknown `state` command ends
  `@ result refused`, exit 3: the step is not offered, in words, until B9's `state` lands.
- F2(b): GET/HEAD only (405 otherwise), `Vary: Origin` on every answer including refusals, no credentials header,
  `Access-Control-Allow-Origin` only for the pages' 127.0.0.1 origin while followed and the viewer's; null, localhost
  by name and other origins refused with no CORS header; no path in either answer (the chosen paths only as
  booleans; `why` is the page's first sentence, fixed words or a process number).
- F2(a): the solo window line is `-pages <launcher> -db ... -addr <viewer> -first viewer`, the pages left out; not
  for the browser's viewer, no catalogue, a fallen window, a viewer of the launcher's own running.
- The lent commit 8e58ec25 holds exactly the lines the report lists (its diff equals the whole piece's diff of
  `ui.go` and `page.go`); lock order st.mu then u.mu is never reversed in them.
- The named tests `TestBringin.*|TestAPIState.*|TestSoloWindow.*` on 72117787: 11 of 11 passed, none skipped
  (about 23 s, twice).

## Not verified

- Windows' file box in its file mode, the real window and WebView2's CORS behaviour: need a real window.
- B9's real program and Core's real lock door with the launcher (no `state` command and no K24 on the heads read).
- The probe's own end (its last Close came before the start again had settled; the launcher had not ended within
  the bound): a probe artefact, the run's line had been read by then; no process of the probe was left running.
- No race run (house rules); the new goroutines (gate, dry run, boxes) each use the step's lock.
