# Review of E15 (the frame check's catalogue side, the part ledger, the supply's decision at Next)

Copy reviewed: wt-copies-15, branch wip/copies-15, head d0d91f7c, read only (the merge of the main head changes
nothing in internal/catalog, supply, engine, parts or partsledger, so the piece's code is d776b79b's). Probes are in
this folder and were compiled in with `go test -overlay` (overlay-*.json); their outputs are the out-*.txt files.
Invented data only; nothing ran against Telegram or the network; counts and fixed words only. Every go command was
one at a time, named tests only, `GOGC=25 GOMAXPROCS=2 -p 1`, free memory 7.5 GB or more before each.

Probe files: `cat/review15_cat_test.go`, `cat/review15_cat2_test.go` (package catalog), `sup/review15_sup_test.go`,
`sup/review15_digest_test.go` (package supply), `pl/review15_pl_test.go` (package partsledger), mutants in `mut/`.

## Count

| findings | severity | confirmed | plausible |
|---|---|---|---|
| 1 to 4 | medium | 3 (1, 2, 3) | 1 (4) |
| 5 to 10 | low-medium / low | 3 (5, 8, 9) | 3 (6, 7, 10) |
| test gaps | - | 3 mutants no test catches (m2, m4, s3) | - |

Severity says which of the brief's seven rules a finding touches. None breaks rule 1 (nothing skips a file or
writes an exact edge: confirmed by A, and by mutation r11 being caught) or rule 3 (no word releases a held file:
confirmed by A).

## Findings, ranked

### 1. A video fingerprint whose meta is not JSON can no longer be stored, and a catalogue holding one does not open (rule 5). CONFIRMED, medium.
Probe `cat/review15_cat2_test.go` TestReview15MetaWords (out-cat2.txt). The new index
`fingerprint_video_length` is on `json_extract(meta, '$.duration_s')` for every row of kind video, model '', seq 0
(schema_probe.go 64-65). SQLite evaluates it on every insert and update of such a row, and json_extract raises
"malformed JSON" on anything that is not JSON:
- `PutFingerprints` with meta "" or fixed words: not stored (2 of 2 refused); JSON meta: stored;
- the step on a file at the version before that holds one such row: the catalogue does not open.
`PutFingerprints`' own contract (imported.go 42) says a meta is "JSON or fixed words, never interpreted". Today's
two writers of video rows write JSON (vfp.go `videoMeta`, bringin/run2.go `jsonMeta`), so the owner's catalogue is
most likely fine, but I could not check it (privacy), and a later writer of fixed words (or a "" meta) would fail
the fingerprint worker's writes, or, if one is on record before the step, stop the app at its start.
Smallest fix: index and walk an expression that never raises, written the same in all four walks:
`CASE WHEN json_valid(meta) THEN json_extract(meta, '$.duration_s') END` (probeLenSQL and schemaProbe), and a
named test with a "" and a words meta, at the step and at a put.

### 2. A retry after an unknown is a claim and a reference refresh that asks Telegram for nothing (rule 6). CONFIRMED, medium.
Probe `sup/review15_sup_test.go` TestReview15B (out-sup-head.txt). One video with a candidate, a lane that claims
what Next hands it and keeps every part it fetches, 30 hours on a passed clock:
- judge never answers: 21 probe claims, 2 parts asked in all, 20 turns that asked no part; downloaded unchecked
  (no-answer) after 24.5 h;
- judge always answers unknown (timeout): 26 claims, 2 parts, 25 turns that asked no part; unchecked after 24.3 h;
- judge always answers unknown (ffmpeg): 4 claims, 3 that asked no part; unchecked after 2.3 h (3 failures).
By reading, each claim costs one reference refresh before any part is looked up (engine/lane.go 728-736: the claim
marks the file stale; kept parts are taken only in `fetch` through `takeKept`, after the refresh). So about 20 to 25
refresh requests per such file that buy nothing, and a file slot held meanwhile. Where: catalog/probe.go 850-852
(an unknown from phase judge stores plan `[]`), supply/probe.go 140-156 (an empty stored plan is handed out as
FirstPlan, whose two parts are kept).
Smallest fix: at Next, a row in phase fetch with plan `[]` whose FirstPlan parts both have c_part rows is not
handed out: a catalogue door (guarded on wanted, unclaimed, phase fetch, plan `[]`, one transaction) moves the row
to phase judge with `judge_by = now + JudgeWait` and sets the file aside with ReasonProbeJudging, no claim; Next
passes it over. If a part's row is missing (swept), hand it out as now.

### 3. The round bound (4) is passed when an unknown falls between a "more parts" and its fetch (rule 2's bounds). CONFIRMED, medium.
Probe `cat/review15_cat_test.go` TestReview15E (out-cat1.txt): the first round, then 8 times: the judge's "more
parts" (one new part), the judge not ready at Next (`ProbeNotReady`: unknown no-ffmpeg, plan kept), the turn
fetched. Result: 8 further judge trips accepted, `rounds` stays 1 (bound 4); parts fetched 10 (the parts bound
holds: it counts kept parts). Where: catalog/probe.go 499: a turn is taken for a retry (not a round) whenever the row
is in phase fetch with a why on it, so a "more parts" plan fetched after any passing unknown is never counted. The
24 hour bound still ends it, so it is bounded in time, not in trips.
Smallest fix: tell a retry by whether the stored plan was fetched before, not by the why: a column (or a field in
`plan`'s JSON) `plan_fetched`, set by ProbeFetched when it counts the round, cleared by "more parts"; a turn is a
retry exactly when it is set. (Counting every non-empty plan as a round would not do: a plan whose part keeps
failing would use the 4 rounds up by waiting, the coder's reason for the exemption.)

### 4. Videos with a candidate are downloaded unchecked while the judge is not ready, counted in memory only (rule 2; the brief's own rule). PLAUSIBLE (by reading), medium, a decision for the owner.
supply/probe.go 122-133: no row, a candidate, `FrameCheck()` false: handed out as today, `NotReady++` in the Supply's
in-memory counts (lost at a restart), nothing on c_probe. This is what the brief's 22:53 correction asks, but rule 2
says a check with no answer is never "download unchecked" outside the stated bounds (24 h, 3 failures, a final why,
a refused plan, `ProbeCloseAll`), each counted with its why: "ffmpeg not ready" for a new file is none of them, and
it is the very class of the 12.25 to 12.27 incidents (a missing or failing ffmpeg taken for "go"). A judge whose
self-test fails for a day lets every candidate video through.
Smallest fix, if the owner agrees: treat it as for an open row: write the row and put the file off as an unknown
`no-ffmpeg` (the 24 hour bound then applies and every file is on record), or switch the frame check off for the run
through `ProbeCloseAll` and a record; else at least record a row `unchecked / no-ffmpeg` for each such file.

### 5. A row left open when its file leaves the frame check's path: never closed, and in phase judge listed for the judge for good (rules 2, 5). CONFIRMED, low-medium.
- Probe TestReview15F (out-cat1.txt): a row in phase fetch (after "more parts") whose file is then marked for the
  exact check first, or held, by the statements atsave.go runs; claimed and downloaded (the exact check's path; a
  held copy with held_wait off). After the save: row phase fetch, result '', counted open by ProbeStats, nothing in
  Unchecked. A later `ProbeCloseAll` labels the long-saved file's row "unchecked / switched-off".
- Probe TestReview15Zombie (out-cat2.txt): a row in phase judge whose file is skipped by a known list while set
  aside for its judge (settle.go 402 skips 'aside' too), or downloaded with the frame check off (finding 6): the
  judge's words unknown, final and more parts are recorded on the row only (probe.go 724-738: not free, not held,
  not decisive), so the row stays in phase judge and `ProbeJobs` lists it again: 3 of 3 rounds, for each of the three
  words and both ways. A judge failing on such a file runs ffmpeg on it for good (no Telegram cost).
Smallest fix: in probeSettle's "not where the word acts" branch, settle a row whose file has no collector row or is
skipped or gone: phase done, result `unchecked` with a why of its own (`left`) for any word; and let `ProbeJobs`
join `c_want` and leave out rows whose file is not wanted, aside or held.

### 6. With FrameCheck nil, open rows' files are downloaded uncounted unless the collector calls ProbeCloseAll first (rules 2 and 4 against each other: the brief's own rule). PLAUSIBLE (by reading; the zombie probe shows the row left), low.
Rule 4 asks nil to be bit for bit the base (confirmed, letter C), so a file aside for its judge comes back and is
downloaded with its row open. The report says the collector must call `ProbeCloseAll(ProbeWhySwitchedOff)` once at a
start with the frame check off. That is a line in another track's code with no test here; until it exists, rule 2 is
broken for those files. Fix: put it on the board for the collector's lines with a named test, as the report asks.

### 7. Every retry after a part the store refused asks Telegram for that part again, for up to 24 hours (rule 6). PLAUSIBLE (by reading), low.
catalog/probe.go 533-541 and 854-857: a turn with `Refused` (the store would not keep a part: in practice ErrNoRoom,
free space under the floor) is an unknown `not-kept`, put off 15 minutes when a part was kept, else an hour; the
retry asks the parts not kept again, and the store refuses again while the disk stays under its floor. Every
candidate video would cost about 24 claims, refreshes and part requests before being downloaded unchecked anyway.
Fix: on a Probed with Refused, the Supply stops planning for a while (as after ReasonProbeNoStore), counted.

### 8. A "copy" for a file the owner released, or set to be fetched for real, deletes its kept parts first (rule 6). CONFIRMED, low.
Probes TestReview15A and TestReview15H (out-cat1.txt): fate wanted (right: never held again), kept part rows left 0.
The file is downloaded next and asks Telegram again for the parts it had. Where: catalog/probe.go 775 (the DELETE)
runs before 778 (the released / fetch-real branch). Fix: move the DELETE below that branch.

### 9. ProbeCloseAll answers rows that a failed chunk rolled back (rule 7: a count says what it counts). CONFIRMED, low.
Probe TestReview15H (out-cat1.txt): six open rows, chunks of 2, the fourth row's update fails: answered 3, rows done
2. Where: catalog/probe.go 1017 (`total += n` before the error check). Fix: add `n` only when `err == nil`.

### 10. The walks count rows of another fingerprint version against their bound. PLAUSIBLE, low.
The index is ordered by length, then version (schema_probe.go 64), and the version is tested outside the LIMIT
(vfp.go `candWalk`, probe.go `lookWalk`). Today nearly every row is version 2 (footage.Version, the brought-in
archive's), but after a version change every old row near a length is read and left out: ProbeLook (64 entries a
side) would find no candidate for most videos until the archive is fingerprinted again, and they would go as
"nothing to compare with". Fix: put `ver` first in the index and `q.ver = ?4` in the walk's WHERE.

## Test gaps (mutants no named test catches; letter J)
- m2: a "copy" on a file the owner released or set to fetch for real holds it anyway: all of TestProbe*,
  TestPartsNeeded*, TestPartsLedgerDoors pass. (The code is right: TestReview15A.)
- s3: held copies (tier 5) looked at and planned: all TestSupplyProbe* pass (TestSupplyProbeNoRead's held copy is
  never handed out with held_wait on, so the exclusion is not exercised; it needs held_wait off).
- m4: a decisive word on a done row ignored: passes (departure 5 of the report has no test).
- s1 (the report's own mutation 5): only TestSupplyProbeNoRead fails, and it fills `neverPlan` by hand; the real
  Requeue path is covered only by the row being done, as the report says.

## Per letter

### A. A file the owner released: sound
TestReview15A drove six paths through the real doors and gave each of the six words: released (aside, held, then
Transition held -> wanted), fetch for real (SetFetchReal), the owner's "retry now" (aside -> wanted), marked, held by
HoldCheckFirst, then released, skipped by a known list then made wanted by SetChatWants (always download), and a held
probable copy claimed (held_wait off, nothing else in its lane) then given a probe turn. Wanted files sent to held by
a non-copy word: 0 of 30. A released or fetch-real file stays wanted on "copy" too (no edge). Only the claimed held
copy is free with `probable = 1` (aside for its judge), and every word sends it back to held, which is right. By
reading: `probable = 1` is written only together with state held (atsave 208, HoldExact 800, HoldLookAlike 849,
HoldCheckFirst 996, ladder 1058, probeHeldCopySQL), each guarded by released = 0 and fetch_real = 0 (HoldExact,
HoldLookAlike by their own reads); Transition to wanted clears it; Next keeps check_first files and tier 5 out of the
probe. No way found for a wanted file to carry or gain `probable = 1` during its check.

### B. Turns that fetch nothing: finding 2.

### C. The bit-for-bit claim: sound
`sup/review15_digest_test.go` names nothing of E15 and ran on the base (overlay-sup-base.json: every changed catalog
and supply file replaced by its 567c8ca6 version from `git show`, the E15 files removed) and on the head with
FrameCheck nil (out-sup-base.txt, out-sup-head.txt). Scripted lane: two saved videos (one with a fingerprint, one of
an exact candidate's size), 10 candidate videos, an exact candidate, a marked file, a held copy, a non-video, a small
video, an aside file, a checkpoint; 8 rounds of Next in both size classes, claims, and Saved, Aside, Requeue with a
probe refusal, Release, Gone and a plain Requeue; ExactCheck off and on; on the head also with c_probe rows in every
phase (fetch with a plan, fetch after an unknown, judge before and after its time, done) and c_part rows. The four
digests (what was handed out: plan, check, hold-unless-same, tier, rank, wait; every c_want column that matters;
counts of saved files, checkpoints, edges, checks and fetches; the Supply's counts) are identical, base against head,
with and without rows (two sha256 values, one per ExactCheck setting); no row changed; no file carried a plan.

### D. Next under load
TestReview15D (out-sup-head.txt), n = 2:
- every ProbeLook failing, 300 eligible videos ahead of 10 ordinary files: 146 looks per Next (2, then the asks 8 and
  64 times larger), 0 files handed out, every Next: the ordinary files behind are not fed while the failure lasts (by
  design: never unchecked on a failed read). Plausible: on SQLITE_BUSY each failing look is tried 3 times with 50 and
  100 ms pauses (supply.go `do`), about 146 x 0.15 s = 22 s for one Next (not run).
- judge not ready, 300 open rows ahead: 146 settlings (each a write transaction) per Next, 71 to 78 ms; the lane gets
  nothing for two Next calls, then the ordinary files come.
- one video wanted in phase judge before its time at the head (the owner's "retry now"): passed over, one look per
  Next, the file behind handed out.
By reading (engine/lane.go startClaim 475-509): Next is not called while the lane's file slots are busy, so a file
waiting at the head costs no look then; when its claim is refused the lane asks again at its next tick (`dryUntil`),
one look per tick, as the exact check's lookup costs on the base.

### E. The round count: finding 3. The parts bound (32) held in every order tried (it counts kept parts); the 24 h
bound ends the loop of finding 3.

### F. A row left open: finding 5 (and 6).

### G. The candidates: sound within the bound
TestReview15G (out-cat2.txt), 3,000 invented fingerprints with random lengths (ms), 2,000 random asks with limits
1, 5, 50, 300 against a brute force (in range, version 2, frames, not lost; by distance then file id):
- 30% invalid rows (lost, older version, failure rows): 21 of 2,000 answers differ (7 with fewer candidates), all
  where a side's window of 2 x limit entries ran out; never an invalid file returned; ProbeLook's yes/no wrong 0.
- 90% invalid: 1,170 of 2,000 differ (1,161 fewer): the bound at work; invalid returned 0; ProbeLook wrong 0.
- dense: one valid candidate (66 s) behind 400 failure rows and lost files at 60.0 to 60.2 s: VideoCandidates finds
  it only at limit 300 (0 at 1 and 50); ProbeLook says no candidate (64 entries a side): such a video goes as
  "nothing to compare with".
A lost file is never a candidate (also the coder's mutation 8, caught). The file itself: a queued file has no
fingerprint of its own unless its bytes were lost, and lost files are left out.

### H. The ledger: sound but finding 8 and 9
PutPart for an unknown number: ErrNotFound, nothing written, no number in the text (TestReview15KErrWords; also
ProbeVerdict and ProbeFetched errors carry no number). Cascade: the coder's TestPartsLedgerDoors (passed in the
mutation runs). PartsNeeded per state including a file set aside by the frame check: the coder's tests (passed).
ProbeCloseAll with a failure in the middle: the committed chunk stays, the failed chunk is rolled back whole, a second
run finishes (6 done); the count is finding 9. A "copy" against a parts.Store that still has the file in memory
(`pl/review15_pl_test.go`, out-mut2.txt): the store's memory still says it has the file before a read (Has true),
but Kept gives no part (it reads the row, finds none), and the file then drops out of memory (Has false). So no part
whose row is gone is ever handed out: sound.

### I. The schema step: sound
TestProbeSchemaStep, TestProbeSchemaScale (0.16 s at 100,000 rows), TestV12ColumnLists, TestMirrorNameSchemaStep
pass (out-cat2.txt). The hourly columns have no default and every write goes through `COALESCE(col, 0) +` (stats.go
149-156), reads through COALESCE: old rows read 0, the same hour keeps counting. No code or test of another track
names 21; collector/mirror_name_cmd_test.go labels a file 18 and re-migrates through this step, which is idempotent
(not run: the collector package is heavy). The board says the core track took step 22: whichever of the two merges
second must re-point its "after" constant. The step fails on a non-JSON video meta: finding 1.

### J. The tests
I made the report's mutations again (out-mut2.txt), plus mine: five in probeSettle (m1, m2, m3, m4, m6), three in
probeNext (s2, s3, s4) and m5, m7, m8 in the other doors (out-mut.txt). See the mutation table at the end. All of the
report's mutations are caught; the "never plan" rule is held by one test only, as the report says. Gaps: the section
"Test gaps".

### K. Anything else
Findings 1, 4, 6, 7, 10. Also by reading, low: a "copy" on a held file adds a second probable edge and the file comes
back from a set-aside with "looks like a saved file" (heldReasonSQL knows no "sampled frames" evidence: the coder's
doubt 1, state.go not E15's). The Supply passes no plan to ProbeFetched; a late "more parts" landing between Next and
the claim would store a plan the turn did not run (window of milliseconds; a wasted round at worst). Logs and errors
of the E15 files hold fixed words and numbers only (no ixLog/Logf added; errors checked).

## Mutation table
Each mutant ran alone through an overlay of probe.go, with TestProbe*, TestPartsNeeded*, TestPartsLedgerDoors
(and TestVideoCandidates* for the r-series) in catalog, or TestSupplyProbe* in supply.

The report's mutations, made again by me (out-mut2.txt): every one is caught.
- r1 a held file released by no match: TestProbeVerdictOnHeld.
- r2 the 24 h bound removed: TestProbeUnknownBound24h.
- r3 the same-fails bound at 8: TestProbeUnknownSameFails, TestProbeVerdictOnHeld.
- r4 the 6 h gap removed: TestProbeUnknownGap6h.
- r5 = s1 "never plan" ignored: TestSupplyProbeNoRead only (TestSupplyProbeRefused stays green, as the report says).
- r6 parts bound 42: TestProbeMorePartsBound. r7 rounds `>`: TestProbeMorePartsBound.
- r8 a lost file a candidate (ProbeLook's walk): TestProbeLookCases, TestProbeLookBound.
- r9 a held file put off by an unknown: TestProbeVerdictOnHeld.
- r10 a failed look hands the file out: TestSupplyProbeLookFailed.
- r11 a copy's edge written exact: TestProbeVerdictOnWanted, TestProbeVerdictOnHeld.

Mine (out-mut.txt):
- m1 (probeSettle) an unknown always put off an hour: 4 tests fail (FetchedIncomplete, VerdictOnWanted,
  UnknownBound24h, OverdueClaimedMeanwhile).
- m2 (probeSettle) a copy holds a released or fetch-real file: NONE fails (gap).
- m3 (probeSettle) late verdicts not seen as late: TestProbeLateVerdict.
- m4 (probeSettle) decisive word on a done row ignored: NONE fails (gap).
- m5 (ProbeFetched) the retry exemption removed: TestProbeFetchedIncomplete.
- m6 (probeSettle) a copy keeps its parts: TestProbeVerdictOnWanted.
- m7 (ProbeOverdue) settles before its time: TestProbeOverdueClaimedMeanwhile.
- m8 (ProbeNotReady) takes done rows: none fails, but nothing changes either (probeSettle records a done row's
  unknown on the row only): not a gap.
- s2 (probeNext) phase judge handed out before its time: TestSupplyProbeJudgePhase.
- s3 (probeNext) held copies looked at: NONE fails (gap).
- s4 (probeNext) a stored plan that cannot run handed out: TestSupplyProbeStoredPlan.

## End state
`git status --short` in wt-copies-15 after the last run: empty (the copy is clean). Nothing committed or pushed.

## Not checked
- The race detector (not allowed here); concurrency read only: the new fields are under `mu` (neverPlan, probeOff,
  Probe counts) or `modeMu` (floor); `probeFloor` holds modeMu across one catalogue read, as `exactOff` does.
- The engine's side of a probe turn end to end with a real lane (only read: lane.go claim, open, probeTake,
  takeKept); the refresh per claim in finding 2 is by reading.
- The collector package's test that re-migrates through the step; `internal/vfp`'s TestWorkerRealClip (needs ffmpeg).
- The owner's catalogue (privacy): whether any video fingerprint there has a non-JSON meta (finding 1).
- Whole runs of internal/catalog and internal/supply (not allowed here).

# Second pass (9d6f52c0)

Read: BRIEF-E15b-fixes.md in full (with the owner's two added sections), the message "no hold during an outage"
(30d57b89) and TakeBackVideoFailure (06c0f2ac), the report's section "The fix round", and `git diff d0d91f7c
9d6f52c0 -- archiver/internal` (catalog/probe.go, schema_probe.go, vfp.go; supply/probe.go, supply.go, pending.go)
myself. Probes: `p2/` (the first pass's, adapted to `ProbeNotReady(ctx, id, why, now)`, and new ones:
`p2/review15_p2cat_test.go`, `p2/review15_p2sup_test.go`), overlays `overlay-p2-cat.json`, `overlay-p2-sup.json`;
mutants in `mut2/`. Outputs: out-p2-cat.txt, out-p2-sup.txt, out-p2-mut.txt, out-p2-mut2.txt. Same rules as the
first pass (one go command at a time, free memory 7 GB or more before each, named tests only).

STATUS: done. The copy is clean at 9d6f52c0 (`git status --short` empty after the last run).

## Second-pass findings, ranked

### P2-1. Open rows of held files count as checks in flight for good: at 16 the frame check makes no first plan again, and every new video with a candidate is passed over and never downloaded (rules 2 and 5; the owner's "no hold"). CONFIRMED, high.
- `p2/review15_p2sup_test.go` TestReview15P2StuckOpen (out-p2-sup.txt): 16 rows in phase fetch whose files are held,
  plus one new video with a candidate and one ordinary file, Next every minute for 6 hours: the candidate video was
  never handed out (0 claims, 360 "judge busy" passes); the ordinary file was handed out. `ProbeCloseLeft` closes 0
  of the 16 (held is not "left").
- `p2/review15_p2cat_test.go` TestReview15P2HeldUnknownOpen (out-p2-cat.txt): such rows come from the doors
  themselves. 16 held files in phase judge (on the judge's list) each get one unknown: the row goes to phase fetch
  and stays open (probe.go 891-897, the held branch of `unknown`). Afterwards: listed for the judge 0, closed by
  ProbeCloseLeft 0, counted open 16. Held files are never probed (tier 5), so nothing reopens or closes those rows.
  Other ways in: the at-save hold of a wanted file in phase fetch (first pass, F), HoldLookAlike after a mark, a
  put-off file whose chat is switched off (`asideBackSQL` holds it as not collected), and, until the collector calls
  `ProbeCloseLeft`, every row whose file left (saved another way, skipped, gone).
- Where: catalog/probe.go 1270-1280 (`probeOpenSQL` counts every open row, whatever its file's state), and
  supply/probe.go 190-195 (a busy pass has no time bound: nothing is written, the file stays wanted, and it is
  passed over again at every Next). Only an outage of the judge older than `OutageBound` gets around it (the
  outage test comes first).
- Smallest fix: count only rows whose file can still move on (`JOIN c_want ... state IN ('wanted', 'aside',
  'active')`, still on the two partial indexes), and/or give the busy pass the outage rule's bound: a video passed
  over as busy for longer than `OutageBound` goes as without the frame check, on record (`ProbeUnchecked` with a why
  `judge-busy`). Also let `ProbeCloseLeft` (or the held branch of `unknown`) close an open row whose file is held:
  phase done, result `left`.

### P2-2. A judge whose self-test flaps lets most videos through unchecked while it in fact works. CONFIRMED, low (by design; a note for the owner).
TestReview15P2Flap (out-p2-sup.txt): 40 videos with a candidate, `FrameCheck` true one call in ten, and a judge that
answers "no match" at once when it gets a job. Result: 10 judged, 30 unchecked (no-ffmpeg), the last out after 38
minutes. With true one call in two: 37 judged, 3 unchecked, the last out after 24 minutes. Nothing waits without
bound and everything is on record. This follows the owner's rule (each not-ready counts toward 3), but the record
cannot tell a flapping self-test from a dead ffmpeg. By reading: `notReadySince` is cleared only when a true is seen
at an eligible look, so a single false after a long stretch with no look counts as an outage as old as the first
false.

### P2-3. Test gap: the order "outage before busy" in probeNext. CONFIRMED (mutant n1 survives), low.
With the judge-busy test moved before the outage test (`mut2/sup_n1.go`), every TestSupplyProbe* passes. The
effect is bounded (the put-off rows of an outage close within about 10 minutes), but nothing pins the order.

## The first pass, finding by finding
| # | Fixed? | Evidence now |
|---|---|---|
| 1 meta not JSON | yes | TestReview15MetaWords: "" and words stored, a file holding one takes the step and opens; the coder's TestProbeSchemaMetaWords passes. The coder found an existing test of another piece (TestStagedVideosWithoutFingerprint) that stores an empty meta and failed at d0d91f7c: a real case of finding 1. |
| 2 empty turns | yes | TestReview15P2Timeline: 1 claim, 0 empty turns for every judge (was 21 and 26 claims). |
| 3 rounds | yes | TestReview15E: after 3 further trips rounds is 4, and the 4th "more parts" is settled parts-cap (was 9 trips, rounds 1). |
| 4 not ready | yes, as decided | the "not ready" timeline: row made, put off, unchecked no-ffmpeg after 10 minutes, 0 claims. |
| 5 rows left open | partly | TestReview15Zombie: never listed for the judge (0 of 3; was 3 of 3). The rows stay open (phase judge, result '') until `ProbeCloseLeft`, which the collector is still to call; meanwhile they count toward the 16 (P2-1). TestReview15F: ProbeCloseAll now writes `left`, not "switched-off". |
| 6 FrameCheck nil | documented | the two collector calls are in the report's paragraph; not built (collector). |
| 7 not-kept | yes | pause, trial, outage bound (the coder's TestSupplyProbeNotKeptPause, TestSupplyProbeOutage pass; mutants n2 and n6 caught). |
| 8 released copy's parts | yes | TestReview15H: 2 part rows left (was 0). |
| 9 CloseAll count | yes | TestReview15H: answered 2, 2 done (was 3 for 2). |
| 10 version in the walk | yes | TestProbeLookOtherVersion plans: `SEARCH q USING COVERING INDEX fingerprint_video_length (ver=? AND <expr>>? AND <expr><?)`, 0 or 1 entries read past 2,000 rows of another version. |
| D | yes | TestReview15D: 1 look per Next when looks fail (was 146); put-offs still pass (146 settlings, about 100 ms). |
| gaps m2, m4, s3, s1 | closed | mutants made again on the new code (out-p2-mut2.txt): m2 caught by TestProbeVerdictCopyReleased, m4 by TestProbeVerdictOnDone, s3 by TestSupplyProbeHeldCopyNoLook, s1 by TestSupplyProbeNoRead and TestSupplyProbeNeverPlanRequeue. |

## The seven rules
- Rule 4: the digest comparison ran again on the new head with FrameCheck nil. The four digests equal the base's
  (567c8ca6) from the first pass, byte for byte (the same two sha256 values, one per ExactCheck setting), with and
  without rows in every phase; no row changed. `record` now calls `planDone`, which returns at once with FrameCheck
  nil.
- Rule 3: TestReview15A again (out-p2-cat.txt): 0 of 30 wanted files sent to held by a non-copy word, and released
  or fetch-real files stay wanted on "copy". TestReview15P2HeldDoors: a held file with no row, with a fetch row and
  with a judge row, through ProbeNotReady (both whys), ProbeUnchecked, ProbeRejudge, ProbeOverdue, ProbeCloseLeft and
  the six words: released 0 times (the new doors answer left or "no" on a held file).
- Rule 1: no exact edge in any probe; `grep` finds no write of 'skipped' and no RelExact in the E15 files (the only
  'skipped' is ProbeCloseLeft's read).
- Rules 2, 5: P2-1 (a video passed over without bound). Rule 6: findings 2 and 7 are fixed. Rule 7: errors still
  carry no number (TestReview15KErrWords).

## Letter 3: the owner's timeline, on a passed clock (TestReview15P2Timeline, TestReview15P2Count)
One video with a candidate, a lane taking what Next hands it, and a judge answering its list each minute:
- unknown timeout, ffmpeg, ffmpeg-io, parts-missing, flood: downloaded 11 minutes after the first unknown;
  unchecked with that why, same_fails 3, 1 claim, 2 parts.
- judge never answers (a stuck verdict): downloaded 25 minutes after the turn, 20 after the first unknown;
  unchecked/no-answer.
- judge not ready: 10 minutes, 0 claims, unchecked/no-ffmpeg.
- a "more parts" with a new part between unknowns: 24 minutes, 4 claims, 5 parts, ended parts-cap at round 4
  (each new part restarts the count; rounds and parts bound it, and the 24 hours stay the outer bound).
- "more parts" naming only kept parts: an unknown parts-missing each time; 11 minutes.
Orders tried (TestReview15P2Count): unknown, rejudge, overdue, not ready; not ready three times from no row;
unknown, a late verdict on the claimed file, unknown, rejudge, unknown; overdue three times with rejudges between.
Every one ends at its third unknown (same 3, tries 3). A late verdict and a rejudge neither count nor reset. Only a
turn that kept a part restarts the count (at one). No order found ends a file at its first or second unknown or
keeps it going for good.

## Letter 4: the checks in flight
- At most 16 open, whether the judge answers or never answers (TestReview15P2InFlightRead: most open 0 and 16; 60
  of 60 downloaded in 3 h). The coder's fix for rows made by put-offs (`openAdd`) holds.
- The count sticks above the truth: P2-1. A failed finish: `giveUp` releases the file; a first plan's `openAdd`
  lives only until the next read (at most `ModeEvery`); a restart reads the count from the catalogue. `planOut`
  entries of a file handed out but claimed by another lane stay until that file's next finish here (small, bounded
  by distinct files).
- A failed count is taken as busy, read again at every call, with no time bound: while `ProbeOpen` fails, videos
  with a candidate and no row are passed over (one look and one failed count each), and ordinary files are still
  fed (a pass, not a stop). By reading; the same fix as P2-1 (a time bound on busy passes) covers it.

## Letter 5: the outage rule
`notReadySince` and `notKeptSince` are written and read under `mu` (probeNext 157-164, `outage`, `notKeptTurn`).
`ProbeUnchecked` is called only in the no-row branch, and its own guard refuses a file with any row, a claimed file
or a held one (TestReview15P2HeldDoors: "unchecked-no" on a held file; mutant n3 caught by TestProbeUncheckedDoor).
A failed door writes nothing (one transaction) and ends the batch (probeStop); the file is not handed out. Flapping:
P2-2.

## Letter 6: ProbeRejudge
TestReview15P2Rejudge (out-p2-cat.txt): a part swept after the look: the door re-reads inside its transaction and
does not send it (row stays fetch, file wanted); the next Next hands the plan out. All kept: sent, rounds 1 -> 1,
same_fails unchanged. With the judge answering unknown each time: put off, then unchecked at the third unknown. A
plan partly kept: PlanKept false, so the plan is handed out, and the lane takes the kept parts from the store. Its
guard (wanted, unclaimed, phase fetch, all kept): mutant n4 caught by TestProbeRejudge.

## Letter 7: the schema step as changed in place
TestProbeSchemaStep passes (step on the version before, twice, refused elsewhere); TestProbeSchemaScale 0.32 s at
100,000 rows; TestProbeSchemaMetaWords and TestProbeLookOtherVersion pass; all four walks plan as `SEARCH q USING
COVERING INDEX fingerprint_video_length (ver=? AND <expr>>? AND <expr><?)` with primary-key seeks after and no
sort. `plan_fetched` and the `left` result are in CREATE TABLE in place: right only because no catalogue took the
first form (the brief says none did).

## Letter 8: mutants of the fix round (out-p2-mut.txt)
- n1 busy tested before the outage: NOT caught (P2-3).
- n2 outage bound x4: TestSupplyProbeOutage.
- n3 ProbeUnchecked without its "no row" guard: TestProbeUncheckedDoor.
- n4 ProbeRejudge without its "all kept" guard: TestProbeRejudge.
- n5 the count after a new part restarts at 0, not 1: TestProbeUnknownSameFails.
- n6 judge-busy ignored: TestSupplyProbeOutage, TestSupplyProbeInFlight.
- n7 ProbeOpen without the judge rows: TestSupplyProbeInFlight, TestProbeStatsCounts.

## Letter 9: anything else
- The fix brief's T3 ("passed over, left wanted, nothing written") followed exactly is what makes P2-1 a hold
  without bound: the brief's rule breaks rule 5 and the owner's "no hold" once the count can stick.
- G is unchanged (14 of 2,000 answers differ at 30% invalid rows, all at the walk's bound; ProbeLook wrong 0).

## Not checked in the second pass
The race detector; whole package runs; the engine end to end; the collector's two calls (not built); a real
judge's self-test cadence (P2-2's numbers assume one answer per call).

# Third look (ce78bbe8)

Read: `git diff 9d6f52c0 ce78bbe8 -- archiver/internal` (catalog/probe.go, supply/probe.go, supply.go; 9 commits).
Probes: the second pass's (`p2/`) again, plus `p3/review15_p3sup_test.go`; overlay `overlay-p3-sup.json`; mutants
in `mut3/` (run by `mut3/run.sh`). Outputs: out-p3-sup.txt, out-p3.txt. One go command at a time; free memory
6 GB or more. The CPU was at 50 to 80% from other sessions, so every run kept GOMAXPROCS=2. The copy is clean at
ce78bbe8 (`git status --short` empty).

## Findings

### P3-1. A video can wait for a flapping judge with no bound. CONFIRMED, low-medium (rules 2 and 5; the owner's "no hold").
`p3/review15_p3sup_test.go` TestReview15P3TwoLanes (out-p3-sup.txt) uses two lanes: the other lane's Next always
hears "ready" and this lane's never. A video with a candidate in this lane was not handed out in 6 hours, with or
without an open row: 360 not-ready passes, 0 outages, nothing on record. The cause:
- The judge's word is asked once per Next of any lane (supply.go 609-616).
- Any "ready" clears the outage clock (`readyNote`), and so does a gap of more than `ReadyAskGap` between asks.
- A file is planned only when it is looked at during a "ready" Next.
- No-row files and open rows wait at supply/probe.go 191-198 and 222-242 with no bound of their own: nothing is
  written, so neither the 3 unknowns nor the 24 hours apply.
The alignment is constructed; with random flapping a coincidence comes in time (TestReview15P2Flap: 40 of 40
judged, the last after 100 minutes at one ready in ten, 20 minutes at one in two).
By reading: while every lane's slots are busy, Next is not called. Asks then come more than 2 minutes apart and
the clock restarts at each, so such videos wait while other files flow, until the lanes run dry and ask every tick.
Smallest fix: give the not-ready wait a per-file bound, as `busySince` does for "judge busy": a file passed over as
not ready for longer than a multiple of OutageBound (or the 24 hours) goes out unchecked, no-ffmpeg, on record.

## What was asked
1. P2-1 is fixed. TestReview15P2StuckOpen: the candidate is handed out (1 claim, 0 busy passes), and ProbeCloseLeft
   closes the 16 held rows. Rule 3 still holds:
   - TestReview15A: 0 of 30 wanted files sent to held.
   - TestReview15P2HeldDoors: no door or word releases a held file. The new closing turns a held file's row
     done (`left`, or the word's own result) and the file stays held.

   Every `probePass` in probeNext, and what ends it:
   - not ready, no row: the outage clock only (P3-1);
   - judge busy: OutageBound per file (`busyTooLong`; a memo of 4,096 files, and a dropped file waits one bound
     more);
   - not-kept pause: an unknown that counts (3), and the outage bound for no-row files;
   - not ready, open row: the outage clock only (P3-1); ProbeWaitJudge counts nothing;
   - a bad stored plan: settled final, handed out at the next Next;
   - plan all kept: rejudge, then the judge's word or overdue, which counts;
   - phase judge before its time: JudgeWait (5 minutes);
   - put off by a settling: 5 minutes, counts;
   - uncheckedNow refused (the file changed meanwhile);
   - probeStop on a failed read: nothing ends it but the read working again.
2. The flapping probe now gives 40 of 40 judged and 0 unchecked; the last waits 100 minutes (1 in 10) or 20
   (1 in 2). The longest constructed wait is unbounded (P3-1); only a "not ready" heard without a break for 10
   minutes ends it. An open row cannot be struck or let through for no-ffmpeg while the outage is young:
   - the supply no longer calls ProbeNotReady with no-ffmpeg;
   - `unknown` never counts no-ffmpeg;
   - ProbeOverdue is reached only when ready;
   - uncheckedNow(no-ffmpeg) runs only when `notReadyOld`.
   Restart: the clock lives in memory and starts again at the first "not ready" after the start, so an outage that
   spans a restart takes one more full OutageBound. That is the safe side: never early.
3. Rule 4 holds: the four digests with FrameCheck nil are the base's, byte for byte (the same two sha256 values),
   and no row changed. The word is asked only when FrameCheck is set.
4. Mutants (out-p3.txt):
   - t1, ProbeOpen counts every fetch row again: caught by TestSupplyProbeStuckOpen;
   - t2, a held file's word no longer closes its row: caught by TestProbeHeldRowClosed;
   - t3, the ReadyAskGap restart removed: caught by TestSupplyProbeOutageSeen;
   - t4, no-ffmpeg counted again: caught by TestProbeUnknownSameFails;
   - t5, the busy bound removed: caught by TestSupplyProbeStuckOpen.
   All five are caught.
