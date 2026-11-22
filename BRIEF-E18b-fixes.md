# Brief E18b: the fix round of the collector's lines (copies, session C4, 11-16)

**For a fresh Opus 5.5 coder at high effort. You continue another coder's branch. Routine steps are not yours to
repeat: named tests of what you change only; the whole runs, vet over packages, the race detector and the merge of
the head come once, later, by a clerk.**

- Copy: `C:\Users\trabi\Claude\Projects\Telegram\wt-copies-18`, branch `wip/copies-18`, head 56c5fc0d. Work only
  there. Go: `. /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`, then the copy's `archiver`.
  ffmpeg for tests: `FFMPEG_PATH` set to the second line of `where.exe ffmpeg`.
- Read first: `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-E18-collector-lines.md` (the piece's brief: its rules
  on files, privacy, tests and the PC bind you too), `archiver/docs/progress/copies-collector-lines-REPORT.md` on
  the branch, and the review in full: `C:\Users\trabi\Claude\Projects\Telegram\REVIEW-E18-collector-lines.md`.
  The reviewer's probes are in `C:\Users\trabi\Claude\Projects\Telegram\wt-copies-review18-scratch`
  (`zz_probe_e18_test.go` in `internal/probejudge`, `internal/parts`, `internal/collector`): read them, take what
  is useful as tests under proper names; do not edit that copy.
- **One commit per fix, each with a test that fails without it** (say per fix what you broke to see it fail).
  Commit with `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, the message ending with
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; `git push private wip/copies-18` after each.
- Files you may touch: those of the piece's brief, **and now `internal/probejudge`** (ours; fixes 1 and 2 only:
  another branch of this track changed three lines of `judge.go` and `turn.go` around the candidates' call, so
  keep your edits there to the recover and the defers and touch no other line). Still not: `words.go`,
  `stagingmark.go`, `click*.go`, `pages*.go`, `livepages`, `reader.go`, `internal/catalog`, `internal/engine`,
  `internal/store`.

## The fixes (the review's numbers)

**1. A panic in a judge worker must not end the program** (`internal/probejudge`; confirmed by the reviewer's
`TestProbeE18WorkerPanicEndsProcess`). A recover around each worker turn in `work`: the panic is counted
(`Stats`, a fixed JSON name; a line in `Report()`; one log line with a constant format and no panic text), the
worker pauses as after any failure (`pause(w)`, the doubling to a minute that exists) and goes on; the file it had
in hand is let go so that it is not left "in hand" for good (it comes back by its judge's time or the door's
bounds: say which). Go through `turn` and everything it calls: no lock of the judge may be held at a point that
can panic into the recover, or it is released by `defer`; `checking`, `hand`, `pend` and the probing channel must
be right after a panic at each step (a table in the report: step, what is held, what the recover leaves). A file
whose turn panics every time must not spin: after the pause it is passed over as a verdict the catalogue cannot
take is (`PassOver`), counted. Tests: a panicking door call, a panicking `Parts.Indexes`, a panic in the decide
code (through the seams that exist; add none to the product for it if a fake can do it), each showing the process
alive, the other worker still judging another file, the count, and no lock held; the first coder's
`TestJudgeRunAgainAfterPanic/worker_panic` in `internal/collector` switched on (no `E18_KNOWN_DEFECTS`).

**2. A panic in `Run`'s own goroutine** leaves `j.mu` held and `running` true: `defer` for `Run`'s start and end
(the lock released, `running` false, the state "stopped"), so that the supervisor's second `Run` starts clean and
`Stats()` never blocks. Test: a panicking clock, then `Run` again runs and judges; `Stats()` returns.

**3. `ensureReplayed` (`internal/supply/supply.go`):** a panic in `replay` leaves `replayMu` locked (the base's
`defer` unlocked it). Unlock in a deferred closure guarded by a flag; the `Saved` calls stay after the unlock,
with no lock held. Test: a panicking replay (through an existing seam), then `replayMu` is free.

**4. The parts folder: other spellings of the same folder.** In the overlap check also compare the folders with
links resolved: `filepath.EvalSymlinks` on the longest existing ancestor of each of the three folders (parts,
staging, library) and the lexical test again on the results, and `os.SameFile` of the parts folder (when it
exists) with the staging folder and the library. **No walk of the library and no listing of it: at most one
`Lstat`/`Stat` per path element, bounded by the path's depth; a library that does not answer (the NAS away) within
2 s is not a reason to refuse: the lexical test alone decides then, counted and said in one log line.** A relative
`-parts-dir` is refused (the reviewer's 9 c). Test: the reviewer's junction probe as a named test (skipped with a
fixed message where a junction cannot be made).

**5. The parts folder's own mark.** Not the staging folder's: a mark file of its own name with a first line of its
own, written and read by small functions in `framecheck.go` (use `catalogueID`; do not edit `stagingmark.go`).
Refused at the start with fixed words: a folder with another catalogue's parts mark; a folder with a staging mark
(the owner named a staging folder); **a folder that is not empty and has no parts mark** (it is not adopted). An
empty or missing folder is made and marked. Test each case; and that a staging folder is not taken for a parts
folder or the other way round.

**6. The part store's hourly line** "used by downloads" also counts the judge's reads: reword it in
`internal/parts` to what it counts (handed out to downloads and checks), and keep the engine's figure as the
"requests saved" one in the collector's hourly lines if it is not there already (say where it is printed).

**7. `ProbeCloseAll` at a start with the frame check off: a bound on the tries** (the brief's rule was wrong: with
both flags off it was a new way for a start to stall every download). Three tries (1 s, 2 s, 4 s apart, ended at
once by a stop); then one log line with fixed words and the start goes on; the rows are closed at the next start.
What that costs is a count, never a file: say in the report what a file set aside for its judge does in such a
run. Test: a catalogue that fails that call for good: the run starts, downloads go on, the line is logged once.

**8. The part store's open at the start.** When the context has ended, `Run` returns the context's error as a
stop, not a refusal. A failing open is tried three times (1 s, 2 s, 4 s apart, ended by a stop) before the start
is refused with the fixed words. Test both.

**9. The flags' words.** (a) A flag of a group given while the group is off: one log line at the start with fixed
words and the count of such flags (never their values); nothing else changes. (b) With `-card-decoders ""` the
start's decoder line says that no card is listed and `auto` is the CPU. (c) is in fix 4.

**10. Two tests the piece owes** (the review's 10): ffmpeg absent for the whole run (`fakeJudge.failST`): a video
with a candidate is let through only at the merged bound and is counted unchecked with its reason, never before;
and a video already held by a look-alike rule that the check judges "no match" **stays held**. If either shows a
defect, stop there and say so first.

**12. A revived save recorded by the look at `SavedAs`** is counted in `supply.Stats` (a fixed JSON name; a line
in the hourly report if the Supply has one) so that it is not silent.

**Not in this round:** 11 (`ErrPartsDir` among `words.go`'s sentinels: that file is Core's; write the one line
Core would add into the report).

## Hand-back
The report's new section "The fix round" (per fix: the commit, the test, what was broken to see it fail; the
table of fix 1; anything you could not fix as written and why; any rule of this brief you think is wrong).
Everything committed and pushed; the copy clean; `gofmt -l` on your files and `go build ./...` clean. Run only
named tests (`-run`, `-count=1`), never the whole `internal/collector`, `internal/catalog` or `internal/supply`,
no `go vet` over packages, no race detector; `internal/probejudge` and `internal/parts` whole are allowed once at
the end (seconds each). Look at the PC before each run (less than 2 GB free or the CPU above 80% over a few
seconds: wait a minute, at most 10 times, then `GOMAXPROCS=2`). Your last message: the head's short hash, each
fix with its commit and test in one line, test functions removed (none expected), your doubts.
