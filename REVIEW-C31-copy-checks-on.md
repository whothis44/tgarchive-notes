# Review C31: the fingerprint worker and the frame check ON by default

Independent review, 2026-11-22 (02:40 to 03:00 EST), of head bd116e1e (base e34f4f64) in the detached copy
`wt-copies-review36-scratch`. Brief `BRIEF-C31-copy-checks-on.md`, coder's report
`archiver/docs/progress/copies-checks-on-REPORT.md`. Invented data only. No Telegram request, no real catalogue. No
tracked file in the copy was changed (`git status` is clean). All probes went in through `go test -overlay`, from
`scratchpad/ov/` of this session. Every go command went through `runs-copies-r31/go1.sh`, with logs in `runs-copies-r31/`
and FFMPEG_PATH set by `env-archiver.sh` (ffmpeg 9.0.2). Only named tests were run: no whole `internal/collector` or
`internal/catalog`, and no race run.

**Verdict: may be listed as it is.** Nothing must be fixed. There are five notes and no "should fix".

## 1. Defaults, stored values, the flags, refused starts: NOT REAL (no defect)

Runs: `q1-copyset.log` (11 named tests, all pass, 13 s) and `q1-copyset-pkg.log` (`internal/copyset` as a whole, ok).
- **Nothing stored and no flag: both run, the decoder is auto.** `TestCopySetNothingStoredIsOn` passes. It checks six
  reads and no write, both fields on, "on by default", the tasks started, the `-parts` folder made, one start line, and
  the door showing Source "default" with `FrameDecoder.InForce` "auto". Probe P1 (`p1-on.log`) confirms the same
  through the real run command (`-approve-read` rig). The lines are: "the frame check: on, 2 judge workers, decoder
  auto" and "copy checks: the fingerprints are on by default; the frame check is on by default". The part store folder
  is made.
- **Stored "off" stays off:** `TestCopySetStoredOffStaysOff` passes (no task, no folder, "off by your setting",
  Source "stored").
- **Unreadable value:** `TestCopySetUnreadableIsOff` and `TestCopySetMalformedRows*` pass (off, said once per row,
  Source "unreadable"). **Failed read of the table:** `TestCopySetReadFailedIsOff` passes (off unless a flag names the
  switch). `copyset.TestCopySetSwitches` covers the package side: `item.read` now returns `bad`, which is off for a
  switch and the default for the four others. No caller outside the collector reads these switches (grep).
- **The per-run flag wins both ways:** `TestCopySetStoredSwitchesOn` passes (stored off with the flags given gives on;
  stored on with `=false` gives off). So do `TestCopySetStoredOffStaysOff`'s second half and `TestFrameCheckFlags`.
- **No new refused start (read of the code):** every error of `newFrameCheck` (folder, overlap, claim, open, judge) goes
  through `frameCheckOffForRun`. That function refuses only when `byRun(frame-check)` is true, meaning the flag was
  given or the Config was not made from flags. A Config that is not made from flags has `FrameCheck` false (the zero
  value), so it is unchanged. A failed `vfp.New` logs and goes on. `startPairWords` and `refuseStagingAsParts` are
  unchanged. `TestCopySetStoredOnNeverRefusesAStart/default` passes.
- *Note N5:* when the part store cannot be set up, the start can now take up to about 9 s longer by default before it
  goes on with the check off. That is 2 s for `partsDirAnswer` when the library is away, plus 1, 2 and 4 s of
  `openParts` retries. On the head this happened only with the check switched on. No refusal comes of it.

## 2. No ffmpeg: NOT REAL (shown); one note

`TestCopySetNoFFmpegOffForRun` passes (`q1-copyset.log`). It uses the real finder, with no `JudgeFind` and `-ffmpeg`
named at a file that does not exist. It shows:
- the start goes on;
- `copyLineFrameCheckNoFFmpeg` is said exactly once;
- the start line says "off for this run: no ffmpeg is found";
- no `frame-check` or `kept parts` task runs;
- **no `-parts` folder is made**: `frameCheckOffNoFFmpeg` runs before `newFrameCheck`, so `MkdirAll` is never reached;
- the door shows `FrameCheckNoFFmpeg`, in force off, next on, pending;
- with `-frame-check` given, the check stays on, as on the head.

- **No file waits for a check that never comes.** With the check off, `frameCheckSupply` leaves `scfg.FrameCheck` nil.
  The Supply's probe code then does not run, so nothing is held for a judge. `closeProbesAtStart` (collector.go:806)
  runs after `startFrameCheck` (757), so it sees `FrameCheck` false and closes the checks an earlier run left open,
  with a count. The fingerprint worker with no ffmpeg stays on and idle. Its `NotYet` says no while it is not ready, so
  no staged file waits on it (the copier's NotYetMax of 2 minutes bounds it in any case).
- *Note N1:* **videos with a candidate then download unchecked, with no count per file.** The flag-on outage path, by
  contrast, records `ProbeUnchecked` after `OutageBound` (10 min). The start line and the door say it once for the
  run, which matches the brief ("off for the run, said once"). Today the owner's catalogue has 0 fingerprints, so there
  are 0 candidates. The app's folder ships ffmpeg, so this path needs a broken install.
- *Note N3:* with no ffmpeg, the start line still says the fingerprints are "on by default", while the worker idles. Its
  own line just above says "on, but no ffmpeg is found". This is accurate, but a page that shows only `FingerprintsWhy`
  would not show that the worker is idle.

## 3. The rules on the default: NOT REAL (each held); the coder's tests prove three of four by mutation

Baseline `q3-base.log`: `TestCopyChecksOnByDefaultEndToEnd` and `TestFrameCheckHeldStaysHeldOnNoMatchByDefault` pass.
The re-encode's probe asked 2 parts and met 1 FLOOD_WAIT. The unrelated video's 2 probe parts were all taken back by
its download.

| mutation (overlay, one change) | test | result |
|---|---|---|
| M1: on a "no match", the catalogue sets the file to wanted, not probable (`catalog/probe.go`, NoMatch case) | HeldStaysHeldOnNoMatchByDefault | **FAILS**: "after the no match: "", want held by the look-alike rule" (`q3-m1.log`) |
| M2: a frame-check copy is set to skipped instead of held (`probeHeldCopySQL`) | CopyChecksOnByDefaultEndToEnd | **FAILS**: c_want skipped 1; timed out waiting for the re-encode held (`q3-m2.log`) |
| M3: the engine never takes a kept part (`takeKept`: lookup gives nothing) | CopyChecksOnByDefaultEndToEnd | **FAILS**: "24 parts answered of 22 ... its probe fetched 2, its download took 0 kept parts" (`q3-m3b.log`) |
| M4: a probe part's early-retry park does not sleep (`parkWait`) | CopyChecksOnByDefaultEndToEnd | passes (`q3-m4.log`); that path is used only with EarlyRetry on |
| M4b: a probe part's wait is not kept on the part (`noteWait`) | same | passes (`q3-m4b.log`) |
| M4c: a probe part does not sleep out its wait in its slot (`sleep = 0`) | same | passes (`q3-m4c.log`) |
| M4b and M4c together | same | passes (`q3-m4bc.log`) |

- "No match never releases or moves a held file": proven (M1). "Only exact evidence skips": proven (M2): a frame copy
  is held with `ReasonProbeCopy`, never skipped. "Kept parts reused, no second request": proven (M3).
- "Probe parts go through the lane's request path, waits slept in full": the test shows that probe parts are counted
  by the fake's per-account part counter and get its FLOOD_WAIT, that they are counted as `ProbeParts`, and that the
  fake sees no request inside a stated wait. The rule holds in the product.
- *Note N2:* **the test does not isolate the engine's own sleep for probe parts.** Removing both of the engine's guards
  for probe parts (M4bc) still leaves no request inside the wait. Another layer holds the re-ask: most likely the lane
  or account gate set by `plainWait`, or the Telegram package's record of the wait (I did not pin which). This is
  defence in depth, so it is not a product defect. But a regression in the engine's probe-part sleep alone would not be
  caught by this test. The engine's own wait tests remain the guard for that.

## 4. Other tracks' RunCommand tests with both checks on: NOT REAL (none fails, hangs or slows)

Every `RunCommand` caller found by grep in `internal/collector/*_test.go` and `internal/acttest` was run by name in four
groups, each run twice:
- **on:** the head as it is;
- **off:** the same with an overlay that puts the two copyset defaults back to false, which is what e34f4f64 behaves
  like.

| group | tests | on (test time, all pass) | off |
|---|---|---|---|
| g1 | TestWordsTellTheTruth, TestNewChatsDownloadFlag, TestMirrorSingleWaitFlag, TestMirrorNewPerDayFlag, TestRunExactSpotFlags, TestRunPartWaitMarginFlagRange, TestRunCountsEveryFlagRange, TestRunLauncherURLRefused | 1.09 s | 1.24 s |
| g2 | TestApproveRead* (9: Yes, No, AlreadyApproved, UnknownChat, StopWhileAsking, NeedsAccount, CursorNoApproval, ChoosesWithMirrorHooksOff, SwitchesOn) | 13.4 s | 13.0 s |
| g3 | TestMirrorNewPerDayRunLine, TestMirrorAutoRunSteadyFlag, TestRunPagesWithAutoMirror, TestPagesAddressInUseSendsNothing, TestRunWithoutPagesUnchanged | 3.2 s | 3.3 s |
| g4 | acttest TestWholeChainOneClickOneRequest | 6.4 s | 5.2 s |

Logs: `q4-g{1..4}-{on,off}.log`. Probes P1 and P2 (`p1-*.log`, `p2-*.log`, the overlay logs the copy-check lines)
confirm that in "on" the checks really ran:
- the worker and the judge found ffmpeg through FFMPEG_PATH, with decoder auto;
- the `-parts` folder was made beside the temporary staging;
- in the acttest chain the judge reached "ready: ffmpeg found and self-tested (version 9.0.2)" about 3 s after start
  (the extra 1.2 s on g4);
- in "off" there was no folder and no check line other than the start line.

So none of these tests assumes the checks are off. Rig tests that build their Config directly (`newRig` without
`copyFlagsOn`) have `copySet.flags` false and `FrameCheck` false, so they are unchanged. `cmd/tgarchive-collector`'s
run test refuses at "no account signed in", before the staging folder is made. The launcher's tests use stand-ins, not
the collector. *Note N4:* the whole-package run before the merge will run every such test with real ffmpeg self-tests
and a `-parts` folder in its temporary folder. The ones above add about 0 to 1.2 s each.

## 5. The start line, `Source` and `Why`: NOT REAL

- `copyLineChecks` is a constant format whose two `%s` are always `copyWhy*` constants. They come from `switchWhy` or
  are assigned directly in `frameCheckOffForRun`, `frameCheckOffNoFFmpeg` and `sayCopyChecks`.
- `copyLineFrameCheckNoFFmpeg` has no argument.
- `copyLineReadFailed` carries `errWord(err)` and `copyLineFrameCheckSetUpFailed` carries `setUpCause(err)`. Both are
  fixed words and unchanged from the head; `TestCopySetReadFailedIsOff` checks that the invented error's text is not
  logged.
- `CopySetting.Source` is one of three constants. `FingerprintsWhy` and `FrameCheckWhy` are the same constants.
- `r.Where()` in the frame check's line is ffmpeg's fixed words (`FoundEnv` and the like), never a path.
- The judge's ready line names ffmpeg's version number only.

## Findings

- N1 (note): with no ffmpeg at the start, videos with a candidate download unchecked with no count per file. The flag-on
  outage path records `ProbeUnchecked`. Said once per run, as the brief asks; 0 candidates today.
- N2 (note): the probe-wait test catches no single engine mutation (M4, M4b, M4c, M4bc). Another layer holds the
  re-ask; the rule holds end to end.
- N3 (note): the start line says the fingerprints are "on by default" while the worker idles with no ffmpeg. Its own
  line says no ffmpeg is found.
- N4 (note): the other tracks' 23 RunCommand tests pass with both checks on and real ffmpeg, within about 0 to 1.2 s of
  the off baseline.
- N5 (note): when the part store cannot be set up, the default start is up to about 9 s longer before it goes on with
  the check off.

may be listed as it is
