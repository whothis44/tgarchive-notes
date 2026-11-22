# Review of E16 (the judge of the frame check), wip/copies-16 at c3dabe2c

Reviewer: independent, read-only. Scratch: this folder. Status: in progress (saved after each letter).

## Findings (ranked)

Counts: 7 confirmed (0 high, 2 medium, 1 low-medium, 4 low; one of the low is the door's, E15), 3 plausible
(low), 1 note on the tests; 4 mutations no test catches (K). No finding lets the judge write "exact", nor "copy", "partly" or "no match" from a limit,
a missing ffmpeg, a panic or a stop on the real runner.

1. **Confirmed, medium (rule 2 as the design states it; the brief's own rule).** A part the MP4 index reader
   named, which the lane then kept, and whose next read fails once (a ledger read that timed out in
   parts.Store.Kept, the part still listed; or a part refused and forgotten) makes the file **final no-index**
   on the next turn, with no check: a wanted file is downloaded unchecked, a held one stays held.
   Probe: probe_fake_test.go TestProbeIndexPartRefusedOnce printed, for both kinds, "named 1 parts; second
   word final no-index; checks 0". Lines: turn.go 256-260 (and fileMem.named kept for the whole run, 213-221).
   The brief's step 2 asks for exactly this; the design (and rule 2) say a part that could not be had is
   unknown. Smallest fix: on a part named again, write unknown parts-missing (a passing why: the door's 4
   rounds and 24 hours bound it) instead of final; keep final no-index for MaxCalls only.
2. **Confirmed, medium (rule 6 / liveness of every check).** A verdict the door keeps failing for one file
   (any error but ErrBadProbe and ErrNotFound, including the door's ErrWrongState) is retried for ever and
   nothing else is judged. Probe: TestProbePendingBlocks, 2 simulated hours: "tries for the failing file 125;
   checks 1; verdicts for the other file 0" (plain error and ErrWrongState alike). Every other file in phase
   judge then goes overdue, is put off, and after 24 hours is downloaded unchecked. Lines: turn.go 34-40,
   146-158. Smallest fix: drop a pending verdict after a bound (a few tries or 10 minutes), count it, and pass
   its file over as for ErrBadProbe; treat ErrWrongState as refused.
3. **Confirmed, low-medium (the brief: never a crash of the collector's task).** A Find or a SelfTest that
   panics leaves turn (TestProbeFindPanics: "panic escaped turn true" for both); under Run that ends the
   process. Only Check is recovered (turn.go 373-381). Lines: judge.go 353-398. Fix: a recover in haveRunner
   that counts it as "not found" / "self-test failed".
4. **Confirmed, low (H).** A "copy" the door settles as final no-candidate on a held file (the candidate's
   bytes lost meanwhile) comes back with fate held; the judge removes the file's parts although the door
   recorded "unchecked" and kept its part rows. Probe: probe_real_test.go TestProbeCopyRemoves: "state held,
   result unchecked no-candidate, parts in the store false, part rows 0, removed 1". Lines: turn.go 176.
   Fix: remove only when settled.Why is empty (the door's copy path returns no why), or let the door say so.
5. **Confirmed, low, for E15 (the door, not the judge).** A "copy" for a file the owner released (or wants as
   real bytes) is made wanted by the door, which also deletes its part rows (probe.go 775-782); the judge then
   removes the files. The download that follows fetches those parts again (up to 32 requests). Probe:
   TestProbeCopyRemoves: "state wanted, result copy, parts in the store false, part rows 0, removed 1". Fix
   (door): delete c_part only on the held path; the judge's condition then follows the fate held only.
6. **Confirmed on a fake, low (A; not reachable with the real runner).** A Check answering ErrNoFFmpeg
   together with a decided copy writes the copy and removes the parts (TestProbeErrNoFFmpegWithResult:
   "word copy; removed 1"); ErrBadInput or another error with the same answer is unknown ffmpeg. Lines:
   turn.go 302. The real runner pairs ErrNoFFmpeg only with Unknown no-ffmpeg (sample.go 306-309, check.go
   95). Fix: on ErrNoFFmpeg write unknown no-ffmpeg whatever the Result says.
7. **Confirmed, low (B).** The not-affordable answer writes round 0's Hits and Frames but packs every frame of
   the check, round 1's included (TestProbeNotAffordableFrames: "partly, hits 3 of samples 8, frames packed
   11"). Lines: turn.go 343. Fix: pack only round 0's frames (they come first in res.Frames: res.Frames[:After[0].Frames]).
8. **Plausible, low (F).** The list asks 1 + min(passed over, 64): with more than 64 passed-over files oldest
   in phase judge, newer files wait up to the pass-over time (turn.go 120).
9. **Note on the tests (B).** The e2e "partly" clip (real_test.go 429-437) is the original with 0.25 s
   windows replaced at 4 moments, about 93% the same pictures; its names "shares a third" / "shares half the
   moments" misdescribe it, and its auto-mode copy is right for it. Clips that really share a third, a half or
   two thirds were never called copies in off, auto or always (B table).
10. **Plausible, low (I).** The wall test stops only gotd, telegram, engine and tgstore at depth; a reached
    package that imported a network client would pass it (judge_test.go 586-593).
11. **Plausible, low (C).** The resume keeps round 0's outcome computed with the candidates' frames of the
    first call; equal ids are the only guard (turn.go 289), so a fingerprint replaced under the same file id
    and version mixes old and new frames.

## Per letter

### A. Ways out of decide and turn
Every exit, by reading turn.go (line numbers of c3dabe2c):

turn:
1. a pending verdict fails again (34-40): stop -> nothing; else a pause, nothing else judged.
2. a pending verdict written or refused (41): Retried counted in both cases (a refused one is counted Retried
   and Refused: a count only).
3. haveRunner then a stop (43-46): nothing.
4. the list fails (47-54): a pause. 5. nothing to judge (55-66): Idle, kickable.
6. not ready (68-76): unknown no-ffmpeg, written, no pause (each such file leaves phase judge: no spin).
7. decide, then a stop (81-84): nothing written, Stopped counted.
8. decide wrote nothing (97-99): a pause (candidates failed, a stop the context did not see).
9. record failed (100-105): pending kept, a pause. 10. d.failure (106-108): a pause. 11. else wait 0 (MinTurn floor).

decide:
- candidates fail (226-232): nothing, a pause. Empty frames (240-242): final no-candidate.
- index NeedError, a part named before (256-260): final no-index. More than MaxCalls (261-263): final no-index
  (the door's 4 rounds end it long before). Else more parts (267). An index: predicted parts not kept: more
  parts (280-282); none missing: the check. ErrNotMP4 / ErrBadIndex / ErrFragmented / ErrNoVideo: the check.
- check then a stop (299-301): nothing.
- an error other than ErrNoFFmpeg, whatever the status (302-314): unknown ffmpeg, failure, tool, forget. Sound.
- ErrNoFFmpeg: the error is ignored and the Result's status decides (302, 315-369). With the real runner it is
  always Unknown no-ffmpeg (sample.go 306-309, check.go 95), so unknown no-ffmpeg, runner dropped. With a
  Result that says Decided and ErrNoFFmpeg both, a copy is written (finding 6, plausible-only for the real
  runner, confirmed on a fake).
- Decided: Probable with a candidate -> copy; Probable naming none (Of out of range) -> unknown ffmpeg,
  failure, tool, and forget (set at 319): sound. Partial -> partly (OfFile 0 when Of is out of range: the door
  takes it, no edge). NoMatch -> no match. TooFew (or a zero Outcome) -> final few-frames.
- NeedsParts: every missing part kept by the store's word -> unknown parts-missing (332-334), no pause, not a
  tool unknown: the door puts the file off; sound (it happens on a ledger read that timed out in
  parts.Store.Kept: the part is not refused then, so Indexes still lists it). Within the bounds -> more parts.
  Over them with After[0] -> round 0's outcome (counted). Else final parts-cap.
- Final: finalWhy: no-index, cannot-seek, few-frames by name, everything else bad-data (format, and any
  category added later). A final is never a decisive word, so rule 2 holds; it downloads a wanted file
  unchecked (counted) and leaves a held one held.
- Unknown: CatStopped -> nothing written (a pause); timeout -> unknown timeout (no pause, not a tool unknown,
  as the brief says); ffmpeg-io -> tool; no-ffmpeg -> runner dropped, tool; anything else (ffmpeg, frame-times,
  "", an unknown status value) -> unknown ffmpeg, tool.

Against rule 2: no limit, missing ffmpeg, panic or stop reaches copy, partly or no match on the real runner.
Two departures, below: a part refused once on the index path becomes final no-index (finding 1, the brief's
own rule), and the ErrNoFFmpeg-with-a-result path trusts the Result (finding 6).

### B. A wrong "copy" (real ffmpeg 9.0.2, invented clips; probe_real_test.go TestProbeShares, 45.6 s)
Original: 20 s, key frame every 0.2 s, fingerprinted by the real runner. Queued: the original's own pictures for
the first third, half or two thirds of the length (same moments), other pictures after; re-encoded; 10 to 11
parts each. One judge per mode, each file judged from its first plan. Word written (hits of frames judged):

| shared | off | auto | always |
|---|---|---|---|
| first third, key every 0.2 s | no match 2 of 8 | partly 3 of 11 (round 1: 3 frames) | partly 3 of 11 |
| first half, key every 0.2 s | partly 3 of 8 | partly 4 of 11 | partly 4 of 11 |
| first two thirds, key every 0.2 s | partly 4 of 8 | partly 8 of 15 (need 9) | partly 8 of 15 |
| first half, key every 2 s | partly 3 of 8 | partly 3 of 8 (round 1 read 0 new) | partly 3 of 8 |
| first third, key every 2 s | no match 2 of 8 | no match 2 of 8 | no match 2 of 8 |

No "copy" in any of the 15; no "not affordable"; every file needed one "more parts" (the predicted parts) and
then one Check call, never resumed. The word written is exactly Check's final outcome (kind, Hits, Frames) and
the door recorded the same hits and samples: the judge does not change the arithmetic on this path.

The coder's "partly" clip is not a clip that shares a third or half: it is the original with 0.25 s windows
replaced around the 4 last-visited sample moments (real_test.go 429-437), i.e. about 93% of the original's
pictures. Its auto-mode "copy" (report, departure 3) is the right word for such a clip, not a wrong copy; the
test's names ("shares a third", "shares half the moments") misdescribe it (finding 9, test naming only).

By reading, what the judge does with Check that the arithmetic alone would not:
- The not-affordable path writes After[0] (round 0's outcome, never Probable: MoreRounds is not asked after a
  Probable) with After[0]'s Hits and Frames, but packs res.Frames, which holds round 1's frames read so far too
  (TestProbeNotAffordableFrames: partly, hits 3 of samples 8, 11 frames packed). Finding 7 (low).
- The resume (prev) keeps After[0], computed with the candidates' frames of the first call; ids equal is the
  only guard (decide 289), so a fingerprint replaced under the same file id at the same version is judged with
  old frames for round 0 and new for round 1 (plausible, low; Check itself guards length, size and count only).
- The candidates' order is VideoCandidates' (the hold's file first, then closest length, then lower id); Verdict
  takes the first candidate that reaches the need, as footage defines; the judge keeps that order (ids[] built
  in order, empty fingerprints dropped, 235-239). Sound.
- The look-alike evidence is set for any held job whose hold names candidate 0 (Held is "state held or
  probable", ProbeJobs), not only a hold by the preview rule. It can only bring a second round, never a copy by
  itself (Cusp WhyEvidence). Low, noted.

### C. The resume
- Keyed by the file's id; no two files' states can mix (memOf, 187-197). prev is used only with equal candidate
  ids in the same order (289). Check refuses another length, size or count with ErrBadInput: the judge then
  writes unknown ffmpeg as a tool failure (a pause, counts toward the re-test) although ffmpeg did nothing
  wrong. With the job's length and size from tg_media this cannot happen today (plausible only).
- The cap: confirmed, TestProbeCapsClear: a file in the middle of its check when the memory reaches 4,096
  files is not resumed (resumed false). Round 0 is then read again from kept parts. That costs no request only
  while round 0's parts are still kept: the store drops the oldest files over its cap and the sweep removes
  others, so after a restart, a cap clear or a long put-off, the re-read may need parts again, which become
  requests (bounded by the door's 32 parts and 4 rounds). Not a defect of the judge; the "costs no request"
  in the brief and the package comment is true only while the parts are kept.
- The named-parts memory survives a file's put-off (it is per run): if the store dropped a part the index
  reader named in an earlier round and the reader names it again, the file is final no-index (finding 1).

### D. The index path
- NeedError's parts are sorted and compacted by the reader; the predicted list is PartsFor's sorted list less
  kept parts: the door's sorted-plan rule holds. A part beyond the file cannot be named.
- A part named twice: final no-index. Confirmed with a part that was named, kept by the lane and then failed
  to read once (a ledger read that timed out, the store still listing it) and with one refused and forgotten:
  both final no-index on the next turn, no check (TestProbeIndexPartRefusedOnce). Finding 1.
- MaxCalls (130) never matters: the door's 4 rounds end a file first (final parts-cap, no round-0 answer).
- Not an MP4: ErrNotMP4 (and ErrFragmented, ErrNoVideo, ErrBadIndex): straight to the check. The empty MIME:
  the range server sets an empty Content-Type; 15 of 15 real checks in B and the coder's e2e decided, so
  ffmpeg 9.0.2 does not care.
- A hostile index: only Start and PartsFor are used; a NaN Start makes PartsFor stop at the moments (index
  parts only); a huge finite Start picks the last key frame. No panic path seen in the judge's own lines.
- Predicted parts over the door's cap: no check in the judge; the door settles final parts-cap. No round 0 has
  run then, so nothing is lost but the check (counted).
- A prediction ffmpeg still misses: the index branch only names parts not kept; once kept, it goes to the
  check; the check's NeedsParts asks for exactly what ffmpeg missed; the next turn's index branch finds all
  predicted parts kept and goes to the check again. No ping-pong; a part the store keeps refusing is asked
  again each round until the door's 4 rounds end it.

### E. The bounds
The judge's test (336) is the door's (824) negated, on the job's Rounds and PartsFetched, which ProbeJobs reads
from the same row. They can differ only when (a) the store's memory and c_part disagree about a part (the judge
subtracts store.Indexes, the door c_part rows), or (b) a "more parts" verdict is written late from the pending
slot after the row changed. In both the door may settle final parts-cap although round 0 had an answer.
Plausible only, low. On consistent data the "not affordable" rule is not missed (TestJudgeBounds covers both
edges; the coder's mutations 2a and 2b, rerun below).

### F. The pending verdict
- Confirmed, TestProbePendingBlocks: a door that fails for one file only, with a plain error or ErrWrongState
  (the door's own sentinel for "not where it acts"), over 2 simulated hours: 125 tries for that file, 1 check,
  0 verdicts for the second file in phase judge, 0 refused. The worker never moves on: every other file waits
  for its judge time, is settled "no-answer" by the supply, comes back, waits again, and after 24 hours is
  downloaded unchecked. Finding 2.
- A busy catalogue for a minute: pauses 1+2+4+8+16+32 s, then written; nothing lost (the coder's
  TestJudgeDoorFails). Not found or a bad record: dropped, counted, the file passed over 10 minutes. Sound.
- The skip map at 4,096: cleared, so passed-over files come back early (their verdict refused again: bounded).
  The list asks 1 + min(passed over, 64): with more than 64 passed-over files oldest in phase judge, the list
  holds only them, the judge finds nothing and idles 30 s while newer files wait up to 10 minutes (nextJob
  114-130; plausible, low).
- The mem map at 4,096: cleared (C above).

### G. The self-test and Ready
- No ffmpeg: Ready false, unknown no-ffmpeg only, looked for every Retry; found and failing: the same, re-tried
  every Retry; passing: Ready, checks; three tool unknowns in a row: Ready false at once (retest), self-test
  before the next check; found again after Retry. All by reading and the coder's TestJudgeSelfTest (its
  mutation 4 rerun below).
- While not ready, only unknown no-ffmpeg is written for new work; a pending verdict from an earlier tested
  check is still written first (correct: it came from a tested runner).
- Ready stays true after one or two tool unknowns and through any number of unknown timeouts (a hanging ffmpeg
  is timed out every check, files are put off, Ready true): as the brief says; never a verdict from them.
- Confirmed, TestProbeFindPanics: a Find that panics, and a SelfTest that panics, leave turn (panic escaped
  true): under Run that ends the collector's process. Only Check is recovered. Finding 3.
- A slow Find blocks the turn without a context; Ready is false meanwhile (stored before Find). Sound.

### H. After a copy
- Remove comes after the recorded verdict, for fates held and wanted; late and left remove nothing (the
  coder's TestJudgeRemove; mutations 3 and o5 below). A failed Remove is counted; the door has already deleted
  the rows, so the files are never read and the sweep removes them.
- Confirmed, TestProbeCopyRemoves (real catalogue doors, real part store, fake runner):
  (a) a held file judged "copy" whose candidate's bytes became lost during the check: the door settled it
  final no-candidate, result unchecked, the file held; the judge still removed its parts (removed 1, part
  rows 0). The door did not delete those rows (its no-candidate return comes before its DELETE). Finding 4.
  (b) a file the owner released, judged "copy": the door makes it wanted (to be downloaded) and deletes its
  part rows itself; the judge removes the files (state wanted, parts gone). Its download fetches those parts
  again from Telegram. This is the door's rule (E15, probe.go 775-782), followed by the judge. Finding 5,
  for the main session and E15's reviewer.

### I. Rules 4, 5, 7
- go list -deps of the package: no gotd, internal/telegram, internal/engine or tgstore. net/http and os/exec
  are reached through footage/ffmpeg (its range server on 127.0.0.1 and ffmpeg itself), as designed. The wall
  test follows every module package reached (7) through its imports and catches gotd, telegram, engine and
  tgstore at any depth; it does not look at net imports beyond the judge's own files, so a reached package
  that started to dial out would not be caught (plausible, low; finding 10).
- Rule 5: the judge reads only the part store's Source and Indexes and the catalogue. Sound.
- Logf: three constant formats, no arguments. Errors: New's text is constant; no catalogue, store or ffmpeg
  error text is printed or logged anywhere. Report: three lines of counts and fixed words; the map keys are the
  door's kind and why words; the State is a constant. Sound.

### J. Rule 8 (by reading)
Fields touched without a lock: runner, tested, lookedAt, found, selfBad, toolRow, fails, pend, mem, skip and
cfg. Only the Run goroutine reaches them; a second Run returns at once (CAS on running, judge.go 272), and a
Run after the first returned starts after its deferred stores. Kick: a buffered channel. Ready: two atomics.
Stats: under mu, maps cloned; every count, including the pointer increments in decide's more (213-216), runs
under mu. The runner's methods are called from Run only. Nothing found for the race detector to report.

### K. The tests (mutations through -overlay; each alone; files in mut\, results in run-mut.txt)
Baseline: the 13 fake tests pass on the head (0.2 s). Fake tests run for every mutation; TestJudgeIndexPath
(real ffmpeg) for r7.

| mutation | where | caught by |
|---|---|---|
| r1 timeout written as no match | decide | TestJudgeOutcomes, TestJudgeStopWritesNothing |
| r2a affordability dropped | decide | TestJudgeBounds |
| r2b `<` for `<=` on 32 parts | decide | TestJudgeBounds |
| r3 Remove before the verdict | record | TestJudgeOutcomes, TestJudgeRemove |
| r4 self-test skipped | haveRunner | TestJudgeSelfTest |
| r5 a failed write drops the verdict | record | TestJudgeDoorFails |
| r6 no pause after a failure | pause | TestJudgeOutcomes, TestJudgePanic, TestJudgeDoorFails |
| r7 the named-twice rule removed | decide | TestJudgeIndexPath |
| o1 parts-missing (ffmpeg missed kept parts) written as no match | decide | **none** |
| o2 CatStopped without a cancelled context written as no match | decide | **none** |
| o3 the guard "a copy naming no candidate" removed | outcome | **none** (the fake door refuses it; nothing asserts) |
| o4 a stop after decide still records | turn | **none** (decide's own guards hide it in the one stop test) |
| o5 Remove after a copy whatever the fate | record | TestJudgeRemove |

All seven of the report's mutations reproduce as reported. Rules with no test: rule 2 on the parts-missing
path and on a stopped category the context did not see (o1, o2); the copy-without-candidate guard (o3);
turn's own stop guard (o4); rule 6 for a door failing for one file only (finding 2); a panic outside Check
(finding 3); Remove after a copy the door settled as something else (finding 4).

### L. Anything else
- The brief's own rule, followed exactly, breaks the design's rule: "final no-index at a part named a second
  time" (BRIEF-E16 step 2) against the design's "unknown (a part that could not be had)". Finding 1.
- A refused pending verdict is counted Retried as well as Refused (turn 41; a count only).
- An unknown timeout neither pauses nor counts toward the re-test (as the brief says); a hanging ffmpeg costs
  up to 60 s a file, never a verdict.
- Rule 3 end to end: "no match" and "partly" on a held file stay held (the coder's e2e, held after each) and
  my B runs left every wanted file wanted with its parts kept. Sound.

## What I did not check
- internal/footage, footage/ffmpeg and the catalogue's doors themselves (only as the judge uses them).
- The race detector (the main session's), the whole package's real tests (TestJudgeRealEndToEnd was not
  rerun; my probes reuse its harness and ran green), real videos, MOV, a long video near the 32-part cap with
  the real runner (not-affordable on real ffmpeg was not reached in B), several candidates in one real check.
- The collector's wiring (not built).

## Files here
probe_fake_test.go, probe_real_test.go, overlay-probes.json (the probes); mut\<name>\ (mutated turn.go or
judge.go and its overlay); run-real.txt, run-mut.txt (outputs, counts and fixed words only).

Status: done. The copy wt-copies-16 was not changed (git status clean at the end).

# Second pass (ba3754e7)

Read: BRIEF-E16b-fixes.md in full (with its two added sections), the report's "The fix round", the whole
diff c3dabe2c..ba3754e7 of internal/probejudge (judge.go, turn.go, stats.go, every test file). Probes:
probe2_fake_test.go, probe2_real_test.go (overlay-probes2.json); mutations in mut2\ (results run-mut2.txt);
real-ffmpeg output run-real2.txt. Status: done.

## 1. First-pass findings and mutations
The first-pass probe files no longer compile against the new head (6 errors): the coder's tests now declare
`oneFails` and `panicSelfTest` themselves, `turn` takes a worker (`turn(ctx, w)`, tests use `turnOf`), and
`panicSelfTest` embeds a pointer. Adapted copies (names with 2, turnOf) are in probe2_*.go.

| first pass | now | probe (second pass) |
|---|---|---|
| 1 named part refused once -> final | fixed: unknown parts-missing (NamedAgain) | TestProbe2IndexPartRefusedOnce: both kinds "unknown parts-missing; checks 0" |
| 2 pending blocks every file | fixed (P2 timeline) | TestProbe2PendingTimeline: other file judged; see 3 below |
| 3 Find/SelfTest panic escapes | fixed (recovered, counted) | TestProbe2FindPanics: "escaped false; unknown no-ffmpeg; panics 1" both |
| 4 held copy settled no-candidate: parts removed | fixed | TestProbe2CopyRemoves: "held, unchecked, parts in the store true, rows 4, removed 0" |
| 5 released copy: parts removed | judge's half fixed | same probe: "wanted, copy, parts in the store true, part rows 0, removed 0": the door on this branch still deletes the rows (E15's fix), so the kept files are unreadable until it lands |
| 6 ErrNoFFmpeg + decided copy | fixed | TestProbe2Small: "unknown no-ffmpeg; removed 0" |
| 7 round-0 answer packs round-1 frames | fixed | TestProbe2Small: "partly, hits 3 of 8, frames packed 8" |
| 9 test naming | fixed (renamed, TestJudgeRealShares added) | see 4 below |
| 10 wall misses dial-out | fixed (by reading: judge_test.go TestJudgeWall walks an invented tree too) | not probed |
| 11 resume with a replaced fingerprint | fixed (SHA-256 of packed frames) | mutation f11 below |
| C memory cap clears a mid-check state | unchanged (as designed) | "resumed false" |

## 2. The workers (by reading, and probes where named)
- **One file in two hands:** no path found. nextJob reads the list without the lock, then under the lock skips
  files passed over, aside (j.pend) or in hand and takes the first other one into j.hand (turn.go 195-230);
  release is deferred in turn (70) and runs after write() has put an aside verdict into j.pend (291), so an
  aside file never leaves both sets. retryAside writes an aside verdict while its file is in neither hand nor
  list-taken: `trying` keeps a second worker off it (145, 157). Probe TestProbe2PendingTimeline: checks of
  the failing file begun while its verdict waited aside: 0, with 1 and 2 workers.
- **The lock across a call:** never held across ProbeJobs (203-204), ProbeVerdict (record 300-307, retryAside
  159), VideoCandidates, Check (check() 555-558 then unlocks), Find or SelfTest (haveRunner unlocks at 501
  before lookAt; lookAt's counts take it briefly). Logf is called after the lock in every place.
- **Shared fields without the lock:** none of the Judge's guarded fields. Unlocked by design: cfg (read only
  after New), the atomics running and ready, the kick channel, a worker's own `fails`, and a fileMem's fields
  (prev, cands, named, needs), touched only by the worker that has its file in hand; the hand-over to the next
  holder is ordered by mu (release, then nextJob/memOf). A fileMem orphaned by the cap's clear stays with its
  holder only. Stats() copies under mu, maps cloned.
- **Run's return:** after wg.Wait, so every worker has left turn; Check, SelfTest and the own-tries sleep all
  end on the context; a waiter for the shared look leaves on ctx.Done. The deferred clear of hand and pend
  runs after the workers. Sound.
- **A stop:** after decide (87-90), in the own tries (sleep, 278), before each aside retry (153) and in
  record (304: a cancelled context is wroteStopped). A word can still land when ProbeVerdict commits and then
  returns the context's error (the door's race, not the judge's). Sound otherwise.
- **The self-test once:** one looker at a time (probing channel); the others wait, then look again on the
  state it left (a passed test: no second self-test; a failed one: within Retry, no look). The coder's
  TestJudgeWorkersSelfTestOnce: 1 self-test for 4 workers.
- **Confirmed, low (new finding N2): a verdict from a check is written after another worker found ffmpeg
  failing.** TestProbe2CopyAfterGone: worker A's check runs; worker B's check returns ErrNoFFmpeg, the runner
  is dropped and Ready goes false; then A's check decides a copy: "ready before false; word copy; ready at its
  write [false]; removed 1". The brief's P1 says "while it has not passed no worker writes any word but
  unknown no-ffmpeg". The copy came from a check over a runner that had passed its self-test, so the word is
  probably sound; the letter is not kept. The same holds after three tool unknowns in a row (turn 94-101 bumps
  gen and clears tested, but a check already running keeps its runner). Smallest fix if the main session wants
  the letter: take j.gen with the runner in haveRunner and, when it changed before the write, write unknown
  ffmpeg (a passing why) instead of a decisive word.
- **Deadlocks:** none found. Two workers and the verdicts aside: no lock is held across a write; the waiters
  on the shared look hold no lock; Kick never blocks (buffered, non-blocking sends); Stats takes mu briefly
  and is never called with it held. A Logf that blocks would hold a worker only (called outside the lock).
- **What I expect the race detector to find:** nothing in the package's own code. In tests, nothing either:
  the fakes take their own locks, the rig's log is locked, fields read after Run are read after its return.
  The one thing to watch: TestJudgeWorkersOneFile and TestJudgeWorkersStop spin turns on a clock whose short
  waits pass at once; under the race detector they will be slow, not racy.

## 3. The timeline of a verdict the door does not take (passed clock, TestProbe2PendingTimeline)
One worker, a door that always fails one file, 30 simulated minutes: tries at 0, 1, 3, 7 s (its own: 4
writes), then aside at 1:07, 2:07, 3:07, 4:07 and 5:00 (its bound): dropped; the file passed over 10 minutes;
judged again at 15:00 (a second check, the same timeline: 18 tries, 2 checks, dropped 2 in 30 minutes). Two
workers: the same times shifted by the first turn's 250 ms floor. The other file is judged meanwhile. So it is
as the brief says, and the file is not lost: it comes back after PassOver (and the door's own overdue rule
settles it sooner when its judge time passes). "3 tries" as 3 after the first (4 writes in 7 s): it does not
matter; the file is held in hand 7 s either way, and the drop is measured from the first write.

## 4. TestJudgeRealShares and the lengths (real ffmpeg 9.0.2; the test's own recipe; TestProbe2SharesLengths, 40.6 s)
Automatic mode. Word (hits of frames judged, need); round 0 / after round 1:

| length | first third | first half | first two thirds |
|---|---|---|---|
| 10 s | partly 4 of 11 (need 7); r0 3 of 8 | partly 6 of 13 (need 8); r0 4 of 8 | **copy 5 of 8** (need 5) in round 0 |
| 14 s | partly 4 of 11 (need 7); r0 3 of 8 | partly 4 of 11 (need 7); r0 3 of 8 | partly 8 of 15 (need 9); r0 4 of 8 |
| 20 s | partly 3 of 11 (need 7); r0 2 of 8 | partly 4 of 11 (need 7); r0 3 of 8 | partly 8 of 15 (need 9); r0 4 of 8 |

In every case the word equals footage.Verdict over every frame the check read (logged beside it). The coder's
10 s copy reproduces. At 14 s (the test's length) the two-thirds clip is one hit short of a copy both after
round 0 (4 of 8, need 5) and after round 1 (8 of 15, need 9): **the test sits on the threshold** for two
thirds; any change in the encoder, the fingerprint, the sample points or ffmpeg's build that adds one hit
turns its "never copy" red although nothing in the judge is wrong. The third and the half have 2 to 3 hits
of margin at every length (closest: half at 10 s, 6 of 13, need 8). Your intent is right: assert "never copy"
for a third and a half only, and for two thirds assert that the word equals what footage.Verdict gives for the
frames read (Result.Frames against the candidates), whatever it is. Finding N1 (test, medium for its
stability, no defect in the judge).

## 5. The resets
- While not ready, every Retry is a full look: the runner dropped (lookAt 545), Find anew, the self-test; one
  per Retry for all workers (lookedAt is shared). TestProbe2Resets (2 workers, self-test failing for 10
  simulated minutes from the start): finds 10, self-tests 10 (failed 10), log lines 1 (the self-test line, once).
- **Confirmed, low (new finding N3): those resets are not counted.** Same probe: "resets 0 (passed 0)" after 10
  resets. `reset := l.found != 0` (lookAt 540), and found is set to 1 only when a self-test passes and to -1
  only when Find finds nothing: a runner found but failing its self-test from the start leaves found at 0, so
  every reset after it is counted as "the first look". Only a judge that was once ready (or found nothing)
  counts its resets (the coder's TestJudgeResets covers that case only). Smallest fix: count a reset whenever
  lookedAt is not zero (a look before this one), or set found to 1 when Find returns a found runner.
- Log lines: ready -> gone -> back in 12 turns: 3 lines (ready, not ready, ready); never one a turn. Sound.

## 6. Mutations (each alone, through -overlay; the fake tests, `^TestJudge`, real-ffmpeg tests skipped; 120 s limit)
Baseline on the head: ok (0.4 s). The fixes broken on purpose, one at a time:

| mutation | caught by |
|---|---|
| f1 a part named again -> final no-index | TestJudgeIndexNamedAgain |
| f2 ErrWrongState not refused | caught, but by a hang: the binary timed out at 2 minutes (a direct turn's own-try pause waits on a clock that never passes it). It fails, not cleanly: the refusal case should assert without a pause wait |
| f3 no recover in find | TestJudgeToolPanics |
| f4/5 remove on held or wanted, any why | TestJudgeRemove |
| f6 ErrNoFFmpeg ignored when the Result says decided | TestJudgeOutcomes |
| f7 the round-0 answer packs every frame | TestJudgeBounds |
| f11 resume by ids only | TestJudgeResume |
| o1 parts-missing written as no match | TestJudgeOutcomes |
| o2 a stopped category written as no match | TestJudgeGuards |
| o3 the copy-without-candidate guard removed | TestJudgeGuards |
| o4 turn's stop guard removed | TestJudgeStopAfterDecide |

All four first-pass gaps are now caught, and every fix has a test that fails without it.

My own mutations of the worker code:

| mutation | caught by |
|---|---|
| w1 nextJob does not skip files in hand | TestJudgeWorkersParallel, TestJudgeWorkersOneFile, TestJudgeWorkersStop |
| w2 nextJob does not skip files whose verdict waits aside | TestJudgeDoorFails, TestJudgePendingOneFile, TestJudgeWorkersStop |
| w3 the shared look removed (each worker looks at ffmpeg) | TestJudgeWorkersSelfTestOnce |
| w4 retryAside ignores `trying` (two workers may write one aside verdict at once) | **none** (finding N4) |
| w5 Run does not wait for its workers | TestJudgeDoorFails, TestJudgePendingOneFile, TestJudgeIdleAndKick, TestJudgeWorkersStop, TestJudgeWorkersSelfTestOnce |
| w6 a file never released from hand | 9 tests (ToolPanics, IndexNamedAgain, Resume, SelfTest, DoorFails, PendingOneFile, WorkersOneFile, CheckCounts, Resets) |

## Second-pass findings (ranked)
Counts: 2 confirmed (low), 1 test-stability finding (medium for the test), 1 gap (low), 1 note.
- **N1, test stability (medium for the test, no defect in the judge).** TestJudgeRealShares asserts "never copy"
  for a clip that shares two thirds, and at its 14 s that clip is one hit short of the copy rule after both
  rounds (4 of 8 need 5; 8 of 15 need 9); at 10 s the same recipe is a copy (5 of 8). Assert "never copy" for a
  third and a half only (2 to 3 hits of margin at 10, 14 and 20 s), and for two thirds assert the word equals
  footage.Verdict over the frames read. Lines: real_test.go 529-541.
- **N2, confirmed, low (P1's letter).** A check that started before another worker found ffmpeg gone (or
  before three tool unknowns forced a re-test) still writes its decisive word while Ready is false
  (TestProbe2CopyAfterGone: "word copy; ready at its write [false]; removed 1"). The word comes from a runner
  that passed its self-test. Fix if wanted: compare j.gen taken in haveRunner before writing a decisive word.
- **N3, confirmed, low (the owner's "Stats counts the resets").** A judge whose ffmpeg is found but fails its
  self-test from the start resets every Retry but counts 0 resets (TestProbe2Resets: finds 10, self-tests 10,
  "resets 0"). lookAt 540. Fix: count a reset when lookedAt is not zero.
- **N4, gap (low).** No test fails when retryAside ignores `trying` (w4). Without it two free workers could
  write the same aside verdict twice (the door then settles the second as left, or as a second "more
  parts"). A two-worker test with one due aside verdict and a gated door would hold it.
- **Note.** f2's test catches its mutation only by hanging the binary until the 2-minute limit (a direct turn
  whose own-try pause waits on a clock that never passes 1 s). Harmless now, slow when broken.

## Verdict
Every first-pass finding the brief accepted is fixed and has a test that fails without the fix; finding 5's
other half is the door's (E15), and the parts it leaves are unreadable until E15's fix round lands. The worker
design keeps a file in one hand, holds the lock across no call, waits for every worker on a stop, writes
nothing after a stop and runs one self-test for all workers; I expect the race detector to find nothing. In my
judgement the package may be listed after N1 is changed in the test (a small edit); N2 to N4 can follow or be
accepted as they are.

Status: second pass done; the copy wt-copies-16 unchanged at ba3754e7, git status clean.
