# Review of E17 (the card as the decoder, the CPU as the fallback; ffmpeg beside the program)

Copy reviewed: wt-copies-17, branch wip/copies-17, head 036e3cde, against 29bcfa2e. Read-only; probes in this
folder only (`probe/*_test.go` through `-overlay`, a stand-in for ffmpeg `wrap/ffwrap.exe` that passes every call
to the real ffmpeg 9.0.2 and can make card calls hang or fail, mutations in `mut/`). Saved letter by letter.

## Findings (ranked; filled as the letters are done)

### F1 (medium; rule 7 concurrency, and the stop): the decoder self-tests run under the runner's one lock, which no context can leave: callers wait up to 60 s. CONFIRMED
- Probe `probe/a_probe_test.go` TestProbeA6LockWait (ffwrap mode "hang": every card call hangs to its limit):
  "auto resolved in 40.4 s; a Sample with a 3 s context returned after 38.9 s (unknown stopped); Counts waited
  38.9 s; tests 2 passed 0".
- Where: `decoder.go` `Decoder` 105-106 and `auto` 152-153 take `r.dec.mu` and hold it across `makeTestClip`
  (up to `DecoderTestLimit` 20 s) and each `tryDecoder` (20 s each); `Counts` 371 takes the same lock.
  `sample.go` 211 calls `r.Decoder` before the call's own limit: a judge worker's stop, or its 60 s check, waits
  for another goroutine's self-tests (up to 20 + 20 x len(Decoders) s: 60 s with the default list), and a page
  or log line that reads `Counts()` hangs as long. The report's "calls wanting the decoder at that moment wait
  once" is true; that the wait ignores the caller's context and blocks `Counts` is not said.
- Fix: run each self-test once through a small once-per-word gate whose waiters `select` on their own
  `ctx.Done()` (a done channel per word or a singleflight), never holding `dec.mu` across ffmpeg; `Counts` reads
  a snapshot under a lock held only for copying.

### F2 (medium; rule 1, a decoder must never change an outcome): a card process that hangs spends the call's own limit; with no switch the call ends "unknown timeout" where the CPU decides. CONFIRMED (mechanism), default limits plausible only on a narrow path
- Probe TestProbeA1Tight (ffwrap "hangsample": card frame processes hang; the card passed its self-test;
  `SampleLimit` 25 s, the blame counter held below 3): CPU "decided, 5 frames, 0.3 s"; the hanging card
  "unknown timeout, 3 frames, 8 processes (5 card, 3 again), 25.0 s".
- With the defaults (60 s, 10 s a process) TestProbeA1Hang: the first call on a runner costs 20.3 to 20.5 s
  (two batches hang, 3 frames blamed, then the CPU) and decides as the CPU does (same frames, same status, the
  same for `Check`). So the default path survives because the blame switch comes after 3 frames. It does not
  when the CPU's run-again reads no frame (a broken file: no blame), when frames are blamed but spread over
  runners made anew, or when the CPU's own reads are slow: each batch then costs `ProcessLimit` (10 s) on the
  card plus the CPU's read; 5 batches of round 0 alone reach 50 s of the 60 s.
- Where: `sample.go` `readFramesDec` 397-416 (the card's time and the CPU's run-again both inside the call's
  `ctx` from `readRound` 217).
- Fix (smallest): a card process that times out switches this runner's sampling to the CPU at once (a hang is
  the card's, never the file's: no need to count three), and/or the run-again gets the time the card spent
  added back to the call's deadline.

### F3 (low; TRIED-BEFORE section 6, the 12.13 rule): one file can switch a runner's sampling to the CPU for the runner's life. CONFIRMED
- The 12.13 rule counts *files* the CPU read after the card failed (three files). The sampling counts
  *frames*: one file whose stream the card refuses and the CPU reads gives 3 blamed frames in its first two
  batches. Probe TestProbeA2FailParts ("have 3 parts": blamed 3, cpu only true after one call of one file); the
  coder's own TestSampleCardFailure shows the same (one clip, 3 blamed, CPU only).
- `sampleBlamed` is never reset; the judge's runner is made anew only while ffmpeg fails, so in practice the
  switch lasts until the program restarts.
- The brief asked for "three frames"; the history (one broken upload switched the old index to the CPU) says
  files. Speed only, never a verdict.
- Fix: count at most one blame per call (per file), e.g. `readRound` notes "the card failed and the CPU read"
  once per call and the runner counts calls.

### F4 (medium; rule 6, the brief's own order): an ffmpeg.exe dropped beside the program is run before the owner's setting; the program's folder may be a download folder. PLAUSIBLE (by reading)
- Where: `ffmpeg.go` `find` 266-274: the program's own folder is looked at first, ahead of `Config.Path` and
  `FFMPEG_PATH`, with no check. The product is "one .exe with its folder"; if the owner runs it from the
  Downloads folder or the desktop (a usual place for an unpacked program), a web page can make the browser save
  a file named `ffmpeg.exe` there without a question, and it then runs as the owner on the next start, even
  when a setting names the real ffmpeg. Before E17 nothing was run from the program's folder. The coder noticed
  that the setting cannot override (report, doubts) but not the planting.
- Fix (smallest): look only in the `tools` folder beside the program (a browser does not make sub-folders),
  and let an explicit `Config.Path` or `FFMPEG_PATH` come before both. (The brief's order, followed exactly, is
  what opens this: see H.)

### F5 (low; rule 6): PATH split by hand runs ffmpeg from a folder PATH does not name. CONFIRMED
- Probe `probe/e_probe_test.go` TestProbeEFinder: a quoted PATH entry holding the list separator (legal on
  Windows, one folder for Go's own reading: "1 entries") is read as two pieces with the quotes dropped, and
  ffmpeg is found in the prefix folder: "found true, the prefix folder's true".
- The same probe: quote characters are dropped anywhere in a setting, so a setting with a quote inside a name
  finds a different file ("found a different file true"); on Windows a quote cannot be in a file name, so this
  is cosmetic there.
- Where: `ffmpeg.go` `onPath` 300-301 and `find` 276.
- Fix: split on the separator only outside a pair of quotes (as Go does), and on a stray, unpaired quote fall
  back to dropping it; drop quotes only at the ends of a setting.

### F6 (low; the brief: "never claims the card was used"): `Counts.Report` says "processes on the card". CONFIRMED by reading the line; the probe shows it can be untrue to tell
- `decoder.go` 430: "sampled frames: %d processes on the card, ...". Every other report line says "asked for".
  Whether the card decoded is not known per process (the report's own doubt): in probe B even an H.264 4:4:4
  and a 10-bit H.264 clip gave frames 0 bits from the CPU's through `cuda`, counted as card processes; ffmpeg may
  well have decoded them in software. Fix: "processes with a card decoder asked for".

### F7 (low; informational for the probe turn): the parts a frame's process reads vary from run to run, and the card shifts them. CONFIRMED
- Probe TestProbeBStable (a 169-part noisy 720p clip, each of the 8 points read alone, 5 runs per decoder):
  on the CPU 8 to 10 parts a point, the same list in 2 to 4 of 5 runs; with `cuda` 4 to 10 parts, with
  `d3d11va` 3 to 10, rarely the same list twice. Of the 8 points, 6 (`cuda`) and 4 (`d3d11va`) asked for other
  parts than on the CPU; `Sample`'s `Used` was 24 (`cuda`) and 34 (`d3d11va`) against 42.
- What is read past the frame is ffmpeg's read-ahead, which depends on timing, so it is not new with E17; but
  "does a card make ffmpeg read other parts?": yes, in number and in which. With parts missing (the same clip,
  first and last part only) `Status`, `Missing` (8 against 8), `Points` and `Frames` were the same with both
  cards. A frame whose read-ahead touches a missing part is dropped as "missing" (`readFramesOnce` 480) even
  when it was decoded: that rule now meets more varied part lists. No change asked in this piece; worth a line
  for the probe turn's design.

### F8 (low; plain values): `GPUCounts` has no JSON names. By reading
- `fingerprint.go` `GPUCounts`: the only new count type without lower-case JSON names (the worker copies it into
  `Stats`, which has them). The owner asked every count to be plain data with fixed lower-case JSON names. Add
  the tags.

### F9 (low; rule 2 at a caller): a self-test bounded by its caller can end "stopped" because of the card. PLAUSIBLE
- `SelfTest` samples its clip through `Sample`, which first resolves `SampleHWAccel` (`sample.go` 211). With
  `auto` and a card that hangs its self-test, that resolution takes up to 60 s (F1); a caller that gives
  `SelfTest` a limit (the judge's runner check is not on this branch) gets `ErrStopped` and may count the runner
  as failing because of the card. The vfp worker gives its own context with no limit: not affected. Fixed by F1's
  fix, or by resolving the decoder outside `SelfTest`.

## Per letter

### A. The run-again of a sampled frame (`readFramesDec`)
Checked by probes through ffwrap (a real card self-test passes; then card frame processes hang or fail):
- A frame whose card process asked for a missing part is `missing`, not `failed` (`readFramesOnce` 480 comes
  before 482-503), so it is never run again; sound. When the card process fails before asking for anything,
  the CPU's run-again asks for the part and the frame ends `missing` as on the CPU: TestProbeA2FailParts, three
  part sets (1, 3 and 4 of 7 parts local): `Missing`, `Used`, `Points`, `Frames` and `Status` the same as the
  CPU's in all three; `CPUAgain` counts every card failure (8, 5, 5) and `SampleBlamed` only the frames the
  CPU read (1, 3, 3).
- A stop in the middle (TestProbeA3Stop, 2 s context while the card hangs): "unknown stopped", no run-again,
  processes 4 started 4 ended, nothing blamed. Sound.
- ffmpeg gone after the card passed (TestProbeA4Gone): "unknown no-ffmpeg", the error ErrNoFFmpeg, 0 processes,
  no run-again. Sound.
- A card hang to the 10 s limit: F2. Two batches hang on a fresh runner (20.3 to 20.5 s), then the CPU; the
  decision, frames and `Check`'s kind and rounds equal the CPU's.
- The blame count: only frames the CPU then read (`re[i].read`, 419); garbage never blames (the coder's test);
  shared by concurrent checks through atomics; never reset: F3.
- The `Result` counts sum correctly in `Check` (`check.go` 154-155).
- `CPUAgain` is documented as "frames whose card process failed or timed out" and is that; the frames the CPU
  then found missing are inside it (A2: 8 again, 1 blamed): a reader must not take `sample_again` for card
  faults.

### B. Rule 1 end to end with the card (FFMPEG_PATH: ffmpeg 9.0.2; `cuda` and `d3d11va` both passed)
Probe `probe/b_probe_test.go` TestProbeBCard, 8 invented 12 s clips: H.264 8-bit key frames 6 apart (index at
the front), H.264 8-bit key frames 250 apart (index at the end), H.264 10-bit, H.264 4:4:4, HEVC 8-bit, HEVC
10-bit (index at the end), H.264 in MKV, and a noisy 720p H.264 of 169 parts. Candidates: an unrelated clip's
fingerprint and the clip's own. For each clip and each card decoder against the CPU:
- fingerprints: same count of frames (24), same times, worst 0 bits apart, `sameFrames` true;
- the 8 points read alone: read and "says" the same, the same times, worst 0 bits; 8 card processes, 0 again;
- `Sample` with all parts: status and category the same, frames the same (0 bits);
- `Check`: status, category, outcome kind, candidate, rounds and change the same;
- `Sample` with only the first and last part local: status, `Missing`, `Points`, `Frames` the same;
- `Used`: the same on the 7 one-part clips; on the 169-part clip it differs (F7).
Rule 1 holds on every clip here for statuses, categories, outcomes, missing lists and frames. Whether the card
decoded the 4:4:4 and 10-bit H.264 clips or ffmpeg fell back to software cannot be told without ffmpeg's text
(F6).

### C. The self-test and `auto`
- Words on this PC (TestProbeCWords): `cuda`, `d3d11va`, `dxva2`, `d3d12va`, `vulkan` pass (0.6 to 1.3 s);
  `qsv` (a device this PC lacks: the NAS's case for `cuda`), `vaapi`, `opencl`, `vdpau` and an unknown word fail
  (0.4 to 1.7 s); no error in any case.
- Four goroutines asking `auto` at once (TestProbeCTwice): one answer, 1 self-test, 3 processes in all (clip,
  its CPU frames, the card's read). A resolution stopped by its context (300 ms) is not kept and gives the CPU
  that once; the next call resolves to `cuda`, 1 test.
- A self-test that hangs (TestProbeA6LockWait): each tried decoder ends at its 20 s limit as failed, `auto` ends
  on the CPU ("tests 2 passed 0 auto cpu"), processes 4 started 4 ended; but everyone waits (F1).
- ffmpeg's own software fallback inside a `-hwaccel` run is never detected; the package says "asked for"
  everywhere except `Counts.Report` (F6).
- A runner made anew starts with no answers (a new `decoders` value): sound. The per-file rule of the
  fingerprints (`GPU`, owned by the worker) is not reset by a new runner (the coder says so).
- `TestDecoder` returns `ErrSelfTest` and keeps nothing when the clip cannot be made, while `Decoder` keeps
  "failed" for the same cause: harmless, but the two disagree.

### D. Fingerprints (`fingerprint.go`, `vfp.go`)
- `auto` resolved once: `haveRunner` calls `Runner.Decoder` once per self-tested runner and hands the word to
  `GPU.Use`; `FingerprintWith` then asks `Decoder` with the resolved word (a map read). The coder's
  TestWorkerAutoDecoder (no second self-test for a third video) shows it.
- The 12.13 rule for a card that passed its self-test: the same condition as at 29bcfa2e (`hw != ""`, the
  caller's context on, not ErrNoFFmpeg or ErrBadInput; counted only when the CPU then reads; 3 files and the CPU
  for the run). New: a named card that fails its self-test is never tried on a file (the owner's decision).
- The thread bound: `fingerprintArgs` unchanged; `-threads` with every decoder, the self-test's reads too.
- Counts: card files, their video seconds and read seconds, fall-backs with the card's wasted seconds, CPU
  files; a fall-back counted under the CPU too, as documented. `Stats().Report()` line 4: numbers, decoder words
  and fixed words.
- `vfp.go` against the base: JSON names on `Config` and `Stats`, the `Runner` interface's `Decoder`, the
  decoder fields in `Stats`, `useDecoder` and the call in `haveRunner`, the fourth report line, one error text.
  Nothing in the holds, the watermark, the pauses, the line or the list reads moved. The decoder self-tests
  run in `haveRunner` after the runner's self-test, at a time when the worker holds nothing (a runner is tested
  only after `dropRunner` and `releaseAll`), so the up to 60 s there holds no staged copy.
- Minor: after the GPU rule switched the run to the CPU, `Stats.DecoderState` still says "a card decoder that
  passed its self-test is asked for" (line 3 of the report says "CPU only true").

### E. The finder (`ffmpeg.go`)
- Each step (TestFindOrder, and TestProbeEFinder): beside, tools, setting, `FFMPEG_PATH`, PATH in that order;
  the working folder and relative PATH entries ("", ".", a relative folder, a missing folder, a lone quote)
  are never taken: "found false"; a folder as the setting finds nothing and does not fall through; a blank
  setting or one of two quotes falls through to `FFMPEG_PATH`. A relative setting is taken against the
  program's folder (the coder's test).
- Links: a file link and a junction could not be made on this PC (refused), so the link case is not checked
  here either. By reading: `programDir` resolves links with `filepath.EvalSymlinks` and refuses a relative
  result.
- `Where()` returns only the fixed `Found*` words; nothing in the tree calls it but a test. No path reaches a
  log or error from the finder.
- Rule 6: F4 (the program's folder first) and F5 (the hand split). A relative entry in PATH is never used
  (sound; as Go's own lookup since 1.19).

### F. Rules 3, 4, 5
- `GOOS=linux GOARCH=amd64 go build ./internal/footage/... ./internal/vfp/`: clean. `go vet` of the two packages
  for Linux and for Windows: clean. `gofmt -l` on both: nothing.
- Arguments: `sampleArgs` and `fingerprintArgs` are fixed lists; the decoder word reaches `-hwaccel` only
  through `cardWord`/`hwaccelOK` (`^[a-z0-9_]{1,32}$`), from the setting, from `Config.Decoders` and from
  `Fingerprint`'s own argument; `auto`, `cpu`, `none` never reach ffmpeg. The test clip's arguments are fixed.
  No shell anywhere.
- Logs and errors: the new vfp lines use constant formats with decoder words (checked words) as arguments; no
  ffmpeg text or path in any new error, count or state; all `Counts`/`Stats` fields have lower-case JSON names
  except `GPUCounts` (F8). The wording of `Counts.Report`: F6.
- No new Windows-only call outside `hide_windows.go`.

### G. The tests
Each mutation applied alone through `-overlay` (copies in `mut/`), then the 8 E17-related tests
(TestFindOrder, TestDecoderWords, TestDecoderAutoNoCard, TestDecoderCardFrames, TestSampleCardFailure,
TestSelfTest, TestFinder, TestGPURule), with FFMPEG_PATH set. TestDecoderCardFrames ran with a card here
(it took 15 s and did not skip) in every run.

| Mutation | Test that failed |
|---|---|
| c1 no CPU run-again in `readFramesDec` (coder's) | TestSampleCardFailure |
| c2 `auto` returns the last word when none passes (coder's) | TestDecoderAutoNoCard |
| c3 the program's folder only without setting and env (coder's) | TestFindOrder |
| c4 the blame count 4 instead of 3 (coder's) | TestSampleCardFailure |
| c5 a named card that failed its self-test used anyway (coder's) | TestDecoderAutoNoCard |
| c6 PATH read with `filepath.SplitList` (coder's) | TestFindOrder |
| m1 a card process that **timed out** is not run again (only `failed`) | **none** |
| m2 a frame blamed even when the CPU's run-again read nothing | TestSampleCardFailure |
| m3 the decoder self-test ignores the frames' times | **none** |
| m4 `-hwaccel` placed after `-i` (an output option: every card process fails) | TestDecoderCardFrames |
| m6 `Check` does not sum `CardProcesses` | TestDecoderCardFrames |
| m5 relative PATH entries accepted | **none** |

All six of the coder's mutations are caught as the report says. Three of mine survive:

### F10 (low; tests): three rules have no test. CONFIRMED (mutations m1, m3, m5 survive)
- m1: no test makes a card process hang, so the run-again of a timed-out frame (and F2's cost) is untested.
  A stand-in like this review's `wrap/ffwrap.exe` (mode "hangsample"), built by the test, or a `ProcessLimit`
  of 1 s with a test hook, would cover it.
- m3: `sameFrames` comparing times is untested (a card that gives the CPU's pictures at other moments would
  pass the self-test). A unit test of `sameFrames` with one time changed.
- m5: no relative or "." PATH entry in TestFindOrder; add one holding an ffmpeg (as TestProbeEFinder does).
- Tests that skip without a card: TestDecoderCardFrames (ran here), TestDecoderSpeed (needs E17_MEASURE=1;
  not run by me), the link case of TestFindOrder (skipped here; a junction could not be made either).

### H. Anything else
- The brief's finder order (the program's own folder before the setting), followed exactly, is what opens F4.
- The owner's "every option a plain value": `Config.Decoders` `null` means the default list and `[]` means no
  card at all (`auto` on the CPU). Both are fine, but the NAS app handing an empty list will silently get the
  CPU; worth one line in the option table.
- `Result.CPUAgain` includes frames the CPU then found missing (A); the report's table could say so.
- Nothing in the piece writes outside temp folders; the self-test clip folder is removed on every path
  (`testClip.remove`, also on stop).

## What I did not check
- Linux at run time (no Docker by the rules): only the build and vet. The NAS's `-hwaccel cuda` with no NVIDIA
  device was stood in for by `qsv` on this PC (fails its self-test, no error).
- Links through `os.Executable` (this PC refused both a file link and a junction).
- The collector and the judge (not on this branch): F9 depends on how the judge bounds `SelfTest`.
- The coder's speed numbers (TestDecoderSpeed not run).
- Concurrency under the race detector (not allowed here); by reading: the new state is under `dec.mu`, atomics
  or `GPU.mu`, and no ffmpeg call re-enters `dec.mu` (`tryDecoder` and `makeTestClip` call `Fingerprint` with
  a card word or "", never "auto").

## Count
Confirmed: F1 (medium), F2 (medium), F3 (low), F5 (low), F6 (low), F7 (low), F10 (low).
Plausible: F4 (medium), F8 (low), F9 (low).
In all: 3 medium (2 confirmed, 1 plausible), 7 low (5 confirmed, 2 plausible). No finding against rule 1 on
the default limits, rule 3, rule 4 or rule 5's ban on ffmpeg's text and paths.
May be listed after F1, F2 and F4 are fixed (each a few lines) and F6, F8, F10 taken; F3, F5, F7, F9 can go to
the board as notes.

## Second look (6e1ad665)
The fix round `git diff 036e3cde 6e1ad665 -- archiver/internal` and the report's "The fix round" were read in full.
Probes: `probe/a_probe_test.go`, `e_probe_test.go`, `b_probe_test.go` again, and the new `probe/s_probe_test.go`
(the time given back, the gate). Mutations in `mut2/`. Each go command was run alone after a load check.

### 1. The findings
| Finding | Fixed? | What the probe prints now | Its test without the fix |
|---|---|---|---|
| F1 the lock | yes | TestProbeA6LockWait: the Sample with a 3 s context returned in 3.0 s ("unknown stopped"), `Counts` in 0.0 s (it was 38.9 s); the stalled test itself still ends at 40.4 s, kept "cpu", 2 tests, processes 4/4 | r1 (the waiter ignores its context): TestDecoderGateWaits fails |
| F2 the hang | yes | TestProbeA1Hang: 10.4 to 10.6 s (it was 20.5 s), 1 card process, then the CPU; frames, status and the Check's kind the same. TestProbeA1Tight (25 s limit): "decided, 5 frames" (it was "unknown timeout") | r2 (no time given back): TestSampleCardHang fails |
| F3 the blame | yes (one per call, as decided) | TestProbeA2FailParts: blamed 1 for each call, the CPU only after three calls; the rest of the call on the CPU (9 processes against 16 before) with `Missing`, `Used`, `Points`, `Frames`, `Status` the same | r3 (a blame per frame): TestSampleCardFailure fails |
| F4 the order | yes | the program's own folder is never looked in; the setting comes first, then `tools` | r4 (the program's folder first): TestFindOrder fails |
| F5 PATH | yes | TestProbeEFinder: a quoted entry with `;` is one folder ("the prefix folder's false"); a quote inside a setting stays ("a different file false") | the coder's mutations (lenient only; m5) fail TestFindPath; not run again by me |
| F6 the words | yes | `Counts.Report` and the vfp line say "with a card decoder asked for"; "on the card" no longer appears in a report | not run (the test checks the words, by reading) |
| F8 JSON | yes | `GPUCounts` has lower-case names | not run (TestGPURule looks for `"fell_back":3`, by reading) |
| F10 tests | yes for m1, m3, m5 | m1 is now covered by TestSampleCardHang; m3 by TestSameFrames; m5 by TestFindPath (the coder's own runs) | see 6 for my own |
| F7, F9 | F7 not asked; F9 gone with F1 | | |

### 2. Rule 1 once more (`cuda` and `d3d11va`, the same 8 clips as B)
TestProbeBCard on 6e1ad665: every clip, both decoders: fingerprints the same (0 bits); the 8 points the same
times, 0 bits; `Sample` and `Check`: status, category, kind, candidate, rounds and change the same; with parts
missing: status, `Missing`, `Points` and `Frames` the same. Only `Used` on the 169-part clip differs (24 and 35
against 43), as F7 says. The hanging-card probes above give the CPU's frames and outcomes too.

### 3. The time given back
- Bounded: one `callLimit` per round of a call (`readRound`), `giveBack` once, at most `ProcessLimit`, and only
  while the limit has not run out. A hang switches the runner to the CPU at once, so a second hang in the same
  runner, a second round of a `Check`, or a resumed check reads on the CPU and gives nothing back. Only calls
  already running at the moment of the switch can each have their own hang, and each gets its own one give-back.
- Probe TestProbeSGiveBack (`ProcessLimit` 3 s, `SampleLimit` 3.1 s, every card frame process hangs): one call
  3.5 s, decided as the CPU did; three calls at once on one runner: 3.5 s each, all decided; four `Check`s (two
  of them in two rounds) 3.4 to 3.9 s, kind, change, rounds and frames the same as the CPU's. So none ran past
  its limit by more than one process limit.
- A stop: 1.0 s with a 1 s context while the card hung, "unknown stopped", processes 4/4. The outer context
  still ends the call at once (the call's context is a child; the timer only cancels it).
- By reading: the call's context now ends by cancellation, never "deadline exceeded". `readFramesOnce` checks
  `ctx.Err()` before the process's own deadline and `readRound` tells a stop from a time-out by the outer
  context, so the categories do not change.

### 4. The gate
- TestProbeSGate (a): while the auto test ran (ffwrap "hang", the test limit 2 s), a waiter with a 0.5 s context
  left at 0.5 s with the CPU. `Counts` took 0.000 s and said "a card decoder's self-test is running". The test
  kept "cpu" after its 2 tests: the waiter spoiled nothing.
- (b) The caller running the test stopped at 1.0 s and kept nothing. A waiter then ran the test itself: "cpu" at
  5.4 s, 2 tests, 2 failed, processes 7 started 7 ended, nothing testing.
- (c) A named `cuda` and `auto` at once on the real card: both `cuda`, 1 test.
- A discarded runner: the test runs in its caller's goroutine with the caller's context, and no goroutine is
  started. Once the caller returns, nothing of it runs.

### 5. The stand-in (`standin_test.go`)
It is only in a `_test.go` file, so it is never in the program. `TestMain` acts as ffmpeg only when
`FOOTAGE_FFMPEG_STANDIN_REAL` is set. `t.Setenv` restores the value at the test's end and rules out parallel
tests, so the real-ffmpeg tests run with it unset. The real ffmpeg started meanwhile ignores the variable.
If someone runs `go test` with the variable left set, the binary hands the test flags to ffmpeg, which fails,
so the run fails loudly and does not pass silently. A killed stand-in in pass-through mode can leave its real
ffmpeg child for up to `WaitDelay` (5 s), as my ffwrap could. In the hang modes it has no child.

### 6. Mutations (each alone, the round's 11 named tests)
| Mutation | Test that failed |
|---|---|
| r1 a waiter ignores its context (F1 undone) | TestDecoderGateWaits |
| r2 no time given back (F2 undone) | TestSampleCardHang |
| r3 a blame per frame besides the call's (F3 undone) | TestSampleCardFailure |
| r4 the program's own folder first (F4 undone) | TestFindOrder |
| x1 the rest of a call not moved to the CPU after a failure the CPU read | TestSampleCardFailure |
| x3 `Check` never blames | TestSampleCardFailure |
| x2 the time given back is 3 x `ProcessLimit`, whatever was spent | **none** |

### New findings
- **N1 (low, tests; CONFIRMED by x2):** the bound "at most one `ProcessLimit`, and no more than was spent" in
  `callLimit.giveBack` (`sample.go` 446) has no test that fails. TestCallLimitGiveBack waits 500 ms and then
  allows 2 s, so a give-back of 1.2 s passes. Fix: in that test, check that the context has ended by about
  first limit + most + a margin (for example by 800 ms), and add one case where the time spent is under `most`.
- **N2 (low, as decided; by reading):** one blame per call means one file checked over three calls (a check
  resumed after its parts came) still switches the runner's sampling to the CPU. The coder's own
  TestSampleCardFailure does this: two `Sample`s and a `Check` on one clip. Under the 12.13 rule that is one
  file. Speed only. Note it on the board, or key the blame on the file.
- Nothing new against rule 1, rule 7 or the stop.

Verdict: F1 to F6, F8 and F10 are fixed as decided. The piece may be listed; N1 is a small test to add, and N2
is a note.
