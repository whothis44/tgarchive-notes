# Review C30: frame check of held copies from an idle lane (head 2ca9dd81)

Independent review, 2026-11-22. I read the diff e34f4f64..2ca9dd81, the brief and the coder's report, and the code
around the changes: the claim and heldGate, ProbeFetched and probeSettle, ProbeOpen and judgeBusy, the part store's
sweep and PartsNeeded, the judge's job pick, and the engine's probe turn and how it ends.

**What ran for real:** nothing against Telegram and no real catalogue. Every probe uses invented data in temporary
catalogues. The probes are in the uncommitted file
`wt-copies-review35-scratch/archiver/internal/supply/zz_probe_c30_test.go`. Every go command went through
`runs-copies-r30/go1.sh`, with the logs in `runs-copies-r30/zz1.log` to `zz8.log` (`zz5-head` and `zz6-list` are
the head run). There was no race run: the one concurrency question was answered by a plain concurrent probe.

## Findings in short

| # | Question | Finding | Real? | Severity |
|---|---|---|---|---|
| F1 | 4, 3 | The part store's sweep removes a held probe's kept parts. Retries then fetch them again, and they are not reused later | real | **must fix** |
| F2 | 4 | A held probe's hand-out is counted in the checks in flight that gate unique files, so a unique video is not offered | real | **must fix** |
| F3 | 3, 4 | A judge that never answers: once ProbeInFlight held rows are overdue, they are never settled and held probing stops | real | should fix |
| F4 | 3 | The owner's "keep held" and "release" are refused while a held probe's turn runs | real | should fix |
| F5 | 3 | An engine set-aside or "gone" at the end of a held probe's turn moves the file out of held | real | note |
| F6 | 5 | A copy whose look-alike edge names another Telegram file of the same saved file leaves that edge unchanged | real | note |
| F7 | 2 | A look in an empty size class holds the lane's one reservation, so the other class gets nothing that tick | real | note |
| F8 | 6 | Cost: the walk is about 75 ms at 68,000 held rows, at most about once a minute per lane and class | measured | note |
| Q1 | 1 | The switch off: row for row the head's | not real | (what the digest leaves out: below) |
| Q2 | 2 | No probe with an available unique file, under the limit, or over the bound; never two at once | not real | |
| Q5 | 5 | The copy verdict keeps "same post" and exact evidence, removes the parts, and never writes an exact edge or skips | not real | |

---

## Q1. Switch off: row for row the head's? **Not real.**

- **Head check:** I ran `TestSupplyProbeHeldOffDigest` on the head through `go test -overlay`. The overlay put back
  the head's `catalog/probe.go`, `catalog/state.go`, `supply/probe.go` and `supply/supply.go`, and removed every
  C30 file except the digest test. `go list -overlay` confirmed that only `probeheld_off_test.go` was left. The head
  gives `c1086b4b…40fe64`, the golden digest: it really was taken on the head (`zz5-head.log`, `zz6-list.log`).
- **Other values:** `TestZZC30OffValues` ran the same script with the row set to "true", "on", "2", " 1", "1 ", "01"
  and "yes". All seven give the golden digest (`zz7.log`). `ProbeHeld` is on only for the exact value "1", and
  `GetSetting` does not trim.
- **What the digest covers:**
  - the files handed out: id, plan, check, tier, held;
  - `ProbeJobs`' output once, for the two rows it lists;
  - `ProbeCloseLeft`'s count once;
  - the rows of c_want, c_probe, c_part, copy_edge and c_count_hourly;
  - c_settings without the switch's row.
- **What it leaves out** (none of these changes a row; all are read by code):
  - **Extra reads with the switch off.** `ProbeJobs`, `ProbeCloseLeft`, `probeSettle` (an unknown, final or "more
    parts" on a held file) and `heldCopyEvidence` (a copy on a held file) each read c_settings once more.
  - **The Supply's switch read.** It reads the switch at most every ModeEvery (5 s), and only from a Next whose lane
    had nothing, with the judge ready.
  - **A failed settings read** now makes `ProbeJobs` and `ProbeCloseLeft` fail, which they did not do at the head.
    This happens only when the database itself is failing.
  - **The judge's order with several rows.** `ProbeJobs`' order is the head's with the switch off, but the script
    checks it with only two rows.
  - **The Supply's counters** (`Stats().Probe.Held` is new) and the engine File's other fields.
  - **`ProbeStats.HeldByResult`.** It runs one more query whatever the switch says: 163 ms for the whole
    `ProbeStats` at 68,000 held rows. Only tests call `ProbeStats` today.

## Q2. A held probe while the lane has work, is limited, or is at its bound? **Not real** (F7 is a note)

- **Unique file available:** no probe. The coder's `TestSupplyHeldProbeIdleOnly` covers the same size class.
  `TestZZC30OtherClassSwitchOff` covers a unique file in the *other* size class: 0 handed out. `HeldProbeNext`
  checks tiers 1 to 5 of both size classes (huge files included), and the claim checks heldGate again. heldGate
  covers tiers 1 to 4 of both classes, a due tier 6 and due unique set-asides.
- **Speed-limited:** no probe; `hint.Unlimited` is the engine's `!l.limited`.
- **The hourly bound and the idle gate** are both checked in the claim's own immediate transaction. The switch is
  read fresh there, and the count is written in the same transaction. `TestZZC30BoundRace`: 8 claims racing for one
  lane with a bound of 3. Exactly 3 won and 3 were counted (`zz1.log`). Nothing lets one more through.
- **Two size classes at once:** never both. `TestZZC30TwoClasses`: in 40 rounds, both classes asked concurrently;
  two were handed out 0 times. The reservation is taken under `s.mu` before any read.
- **F7, note.** In 15 of the 40 rounds nothing was handed out. The empty small class took the reservation first, so
  the large class returned "busy", and the empty class then went quiet for a minute. It costs one tick (1 s) of
  delay, nothing more. With the default floor (20 MiB) and the large class starting at 20 MiB, the small class
  rarely holds a candidate anyway.
- **Note, by code (not probed):** `HeldProbeNext` counts the Supply's `neverPlan` files as "not available" in its
  idle check, but the claim's heldGate does not exclude them. So a unique file that is never planned can make
  `HeldProbeNext` call the lane idle. The claim then refuses: no request, the refusal counted, and the walk runs
  again at the next Next. The hard rule holds.

## Q3. Held file transferred, made wanted, released, set aside or skipped? **Real: F3, F4, F5**

Not real for the frame check's words:
- **The verdicts:**
  - "no match" only marks the file. `TestZZC30OwnerWordsMidTurn` and the coder's verdict tests: the file stays
    held, its edge and parts unchanged.
  - Every other word leaves it held.
  - A released file is wanted, and a "no match" after that changes nothing (`zz1.log`).
- **Never a transfer:** the file goes out with `File.Plan` and without `HoldUnlessSame`, so the engine runs a probe
  turn (no Sink.Open). A refused plan goes back by Requeue, and so back to held.
- **A restart mid-probe:** RecoverActive gives it back held.
- **The switch going off:**
  - between Next and the claim: the claim is refused, the file held, nothing counted;
  - during the turn: back held, and the next `ProbeCloseLeft` closes the row "left"
    (`TestZZC30OtherClassSwitchOff`, `zz8.log`).

**F3 (should fix): a judge that never answers.** `ProbeHeldOverdue` is the coder's cure for a silent judge. It runs
only inside the held walk (`heldLook`), and the walk comes after the gate
`openCount() + ProbeHeldJudging >= ProbeInFlight`. Overdue held rows stay in phase judge and keep counting in
`ProbeHeldJudging`. So once ProbeInFlight of them are overdue, the gate stops every look before the walk. They are
never settled, and no other held file is probed again in that run while the switch is on.
- **Probe:** `TestZZC30OverdueStuck`, with ProbeInFlight 2 and two held probes taken. At +2 h to +10 h nothing is
  handed out, both rows stay `judge`, Busy counts up, Overdue stays 0, and the third held file is never probed
  (`zz3.log`).
- **Effect:** unique files are not affected, because `ProbeOpen` does not count held rows. Only held probing stops.
- **Fix:** settle overdue held rows before the gate, for example a capped `ProbeHeldOverdue` sweep at the look, or
  leave overdue rows out of `ProbeHeldJudging`.

**F4 (should fix): the owner's words during the turn.** While the turn runs, the file is `active`.
- **Probe:** in `TestZZC30OwnerWordsMidTurn`, `KeepHeld` and `Transition(held→wanted)` both fail with
  ErrWrongState; `SetFetchReal` works. After the turn, the release works (`zz1.log`).
- **Effect:** nothing is lost or released wrongly, but at the head, with held_wait on, a held file was never active,
  so these words never failed. A turn lasts about 10 to 22 s, longer for later rounds. The words win only if the
  owner tries again.
- **Fix:** either the doors take the word for an active held probe (applied at the give-back), or the pages say
  "being checked, try again in a moment".

**F5 (note).** The engine can end a held probe's turn with Aside or Gone (`TestZZC30AsideGone`):
- **Aside** (a timeout, an unreachable chat): the file is `aside` until its time, with attempts +1 and asides +1,
  then back to `held` with probable 1.
- **Gone**: Telegram says the file no longer exists, and the file becomes `gone`.

Neither comes from the frame check, and both are what any probe turn does. But a held file now leaves held for a
while, or for good, where at the head (held_wait on) it never did. The report says that any other end of the turn
"brings it back held". That is true of Aside only after its pause, and not true of Gone.

## Q4. A held probe delaying or crowding out a unique file? **Real: F1, F2**

**F1 (must fix): the part store's sweep removes a held probe's kept parts.** The sweep's needs are
`catalog.PartsNeeded`: wanted, active or aside only (`parts_ledger.go`, unchanged by C30). The collector's
`keptPartsTask` runs `Store.Sweep(ctx, ledger.Needs)` at its start and every 10 minutes, and it removes the parts
and their rows for any file that is not needed. A unique file's probe is set aside while it waits for its judge, so
its parts are needed. A held probe goes back to `held` at once, so its parts are not.
- **Probe:** `TestZZC30PartsSwept`. After the turns, the file is held with its row in judge and 2 kept parts, and
  `PartsNeeded` gives false for both files. I then removed one file's parts as the sweep does (RemoveParts) and gave
  both an unknown. After ProbeRetry:
  - the file whose parts were kept was rejudged with no turn;
  - the swept file was handed out for a new turn, plan [0 41], which means new Telegram requests (`zz1.log`).
- **Effects:**
  - the judge may find the parts gone (judged after unique files, so it waits longer);
  - "more parts" rounds lose the earlier rounds' parts;
  - a retry over kept parts becomes a fetch, so the report's "0 requests on a retry" holds only in the test without
    a sweep;
  - the brief's item 4, "reused if the file is ever downloaded", does not hold.

  These are unmeasured requests. They are bounded by the 3-unknown rule, but they come back every hour.
- **Fix:** with the switch on, `PartsNeeded` also counts a held file whose c_probe row is open, and probably a held
  file with any row, for the reuse on download. That is a catalog line in `parts_ledger.go`, inside the track's files.

**F2 (must fix): a held probe takes a unique file's place at the gate for first plans.** `heldLook` calls
`s.openAdd()` when it hands a held file out, which raises the cached count that `judgeBusy` uses to gate unique
files' first plans until the next `ProbeOpen` read (ModeEvery, 5 s). `probeOpenSQL` also counts `active` files with
an open row, so a held probe's later rounds (row in phase fetch, file active) count against unique files for the
whole turn.
- **Probe:** `TestZZC30OpenAddUnique`, with ProbeInFlight 1. With no held probe out, a unique video with a candidate
  that arrives a second later is offered with its plan. With a held probe out, the same video is not offered at
  all, with JudgeBusy 1 (`zz4.log`).
- **Effect:** with the default of 16, this needs 15 unique checks already open, so it is rare. But it is the hard
  rule "never go before unique files", and the report says the opposite ("held probes never take a unique file's
  place").
- **Fix:** do not openAdd for a held probe, and keep held files' active rows out of `probeOpenSQL` (they are counted
  through `ProbeHeldJudging` already). A side effect of the same double count: in the same 5 s, a lane's second
  held probe is refused as Busy (seen while writing the F3 probe).

**Not real:** the judge's order. `ProbeJobs` lists held files after unique ones when the switch is on. **Note, by
code:** the judge has 2 workers and does not take back a job it already holds. A unique job that arrives while both
workers judge held files waits one judging, a matter of seconds.

## Q5. The copy verdict on a held file. **Not real** (F6 is a note)

- **The look-alike edge is rewritten**, and "same post (…" and the exact check's evidence are kept: the coder's
  `TestProbeHeldCopyEvidence`, and the SQL guards in `heldCopyEvidence`.
- **The reason** becomes the frames' through heldReasonSQL, unless the file is kept held.
- **The kept parts** are deleted.
- **No exact edge:** `AddCopyEdge` with RelProbable only, and the partly word writes a related edge. **No skip:**
  nothing sets skipped. `TestZZC30CopyOtherMedia`: 0 exact edges, the file held.

**F6 (note).** `savedMediaOf` names the saved file's *lowest* Telegram file. When the held file's look-alike edge
points at another Telegram file of the same saved bytes, the UPDATE matches nothing.
- **Probe:** `TestZZC30CopyOtherMedia`. A new probable edge to the lowest id gets "sampled frames 6 of 8". The old
  edge keeps "invented look-alike". The reason is right (the frames') because heldReasonSQL looks at every edge.
- **Effect:** two probable edges for one saved file, one of them still saying look-alike. Harmless to the rules, but
  untidy for the viewer.
- **Fix:** match on `b IN (SELECT id FROM tg_media WHERE file_id = OfFile)`.

## Q6. Cost. **F8, note**

**How often.** An idle lane calls Next every TickEvery (1 s) for each size class. What a Next reads depends on
where the lane stands:

| Where the lane stands | What each Next reads |
|---|---|
| A held probe is out | nothing |
| The bound is reached | nothing until the hour ends |
| Nothing found | nothing for 1 minute per class |
| Busy (the checks in flight are full) | `HeldProbesThisHour`, `judgeBusy` (cached) and `ProbeHeldJudging`, at every tick; the cache is not used for these, but they are cheap |
| Otherwise | the full look |

So the walk runs at most about once a minute per lane and class while nothing is eligible, and once per probe
(30 an hour per lane at most).

**Measured** in `TestZZC30Cost` (`zz7.log`): 68,000 held probable videos in the lane, all but 10 with a settled row
(the walk's worst case), and 136,000 saved videos with fingerprints. The timer's grain on this PC is about 0.5 ms.

| Read | Median | Max |
|---|---|---|
| `HeldProbeNext`, worst case: it sorts the lane's whole tier 5 by id | 75 ms | 458 ms, cold |
| `HeldProbeNext`, an empty class | 0.5 ms | |
| `ProbeHeldJudging` | under 0.5 ms | |
| `HeldProbesThisHour` | under 0.5 ms | |
| `ProbeLook`, with 136,000 fingerprints | under 0.5 ms | 1.5 ms |
| `Supply.Next`, idle, switch on, the whole look and a hand-out | 105 ms | |
| `Supply.Next`, the same, switch off | 0.5 ms | |
| `Supply.Next`, a quiet class | under 0.5 ms | |

In steady state that is under 10 s of reader time an hour per lane. Acceptable. If it is ever wanted, an index on
the held tier by id, or a remembered "lowest id looked at", would make it one seek.

---

May be listed after these fixes: F1 (with the switch on, PartsNeeded keeps a held probe's parts) and F2 (no openAdd
for a held probe; held files' active rows not counted in probeOpenSQL), each with a test. F3 and F4 should be fixed
in the same piece or put on the track's list; F5 to F8 are notes.

---

## Second pass (fix round)

**Scope:** commit 077af701; head 233b0cbf, which adds only the report's run table. I read
`git diff 2ca9dd81 233b0cbf` and section 7 of the report. I checked 233b0cbf out detached in the scratch copy; no
tracked file was changed.

**What ran:** the probes are in the uncommitted file
`wt-copies-review35-scratch/archiver/internal/supply/zz_probe_c30b_test.go`, with the logs in
`runs-copies-r30/zz9.log` and `zz10.log`. Invented data only, no Telegram request, named tests through `go1.sh`.

| # | Question | Finding | Real? | Severity |
|---|---|---|---|---|
| S1 | 1 | A held file's kept parts push an older unique file's parts out, under the cap and under the floor | real | **must fix** |
| S2 | 2 | A held probe's further round that ends in a set-aside is counted in `ProbeOpen` | real | **must fix** (one SQL term) |
| S3 | 3 | A late "unknown" from the judge after the overdue settle counts a second unknown | real | note |
| S4 | 4 | After a set-aside, a kept-held file's reason text goes back to the look-alike's (the flag stays) | real | note |
| S5 | 4 | An active probable file that is a real download takes "keep held", which the save then makes moot | real | note |
| S6 | 5 | "Same post" or exact evidence overwritten | not real | |

### (1) F1: PartsNeeded's states, the cap and the floor. **States right; crowding real (S1, must fix)**

- **The states.** By the SQL, each is right for its purpose:
  - kept: wanted, active, aside, and, with the switch on, held probable with no "copy" row (open, no match, partly,
    unchecked, left, no row);
  - removed: copy, held not probable, gone, skipped, saved, no collector row;
  - the switch off: as at the head.
- **Kept held files keep their parts for good.** This includes files the owner keeps held, and finals that are never
  tried again, until a release, a download or the switch goes off.
- **S1, real, must fix.** The cap's trim and the floor's removal take the oldest files first by their newest part's
  time. They do not know held from unique, and nothing before this round put held parts in the store for longer
  than the next sweep.
  - **Probe:** `TestZZC30bCapCrowd`, the real `parts.Store` and the real `partsledger` sweep. It has a unique wanted
    video with 2 parts from 3 hours ago, and a held file settled "no match" with 2 parts from 2 hours ago.
    - Cap 3 MiB: the unique file's parts are removed (0 left) and the held file's stay (2).
    - Under the free-space floor: the same, unique 0 and held 2 (`zz10.log`).
  - **Effect:** at 30 held probes an hour per lane, about 8 parts each, kept for good, held parts reach the 20 GiB
    cap in about a day across a few lanes. From then on every trim removes unique files' older parts first: a unique
    check waiting for its judge, or the parts a unique download would reuse. That is a held file going before a
    unique file. It also adds held bytes against the 60 GiB floor, and the floor then also takes unique parts first.
- **Fix:**
  - keep a held file's parts only while its row is open (phase fetch or judge: what the judge and a retry need);
  - let the cap and the floor take held files' parts before any unique file's, whatever their age. For example, the
    ledger's `Files` can give the sweep an order hint, or the trim can ask needs for a priority.
  - Test: the probe above, both modes, expecting the held file's parts to go first.

### (2) F2: never counted in a unique file's place? **Real once more (S2, must fix)**

- **Not real for the cases the fix covers:**
  - no `openAdd` for a held probe;
  - `probeOpenHeldOutSQL` leaves out an active probable file;
  - held probes have their own count (`heldOutCount` and `ProbeHeldJudging`);
  - in a further round the turn counts 0 (`TestZZC30bAsideFurther`: `ProbeOpen` in the turn is 0).
- **S2, real.** The same probe ends the further round in an engine set-aside (a timeout). The file is then `aside`
  with probable 1 and its row in phase fetch, and `ProbeOpen` becomes 1 (`zz9.log`). It stays counted against unique
  files' first plans until the set-aside's time, which can be hours for an unreachable chat.
- **Fix:** in `probeOpenHeldOutSQL`, `NOT (w.state IN ('active', 'aside') AND w.probable = 1)`. An aside file with
  probable 1 is never a unique check: a unique file set aside for its judge has probable 0.
- **The judge's workers:** not changed. Held jobs are listed last, and a held job already in a worker's hand is not
  taken back. That is a note from the first pass, accepted.

### (3) F3: settled twice, or while the judge still answers? **Not real as a defect (S3, note)**

`TestZZC30bOverdueLate`:
- **The overdue settle runs once.** `ProbeHeldOverdue` is guarded in its transaction (phase judge, time passed). The
  first call settles (an unknown, no answer, tries 1); the second does nothing.
- **A late decisive word still wins.** A late "copy" lands on the now-open row: it becomes "copy", and the file
  stays held.
- **S3, real, note.** A late "unknown" counts a second unknown (tries 2), so the bound of 3 comes sooner. Unique
  files do the same at the head (`ProbeOverdue`). Held jobs are judged last, so they are likelier to run past
  JudgeWait (5 min) and lose a try.
- **Possible improvement:** a held row's JudgeWait longer than a unique row's.

### (4) F4: the owner's word during the turn. **Not lost, not undone; two notes (S4, S5)**

`TestZZC30bWordEnds`, each word against each way the turn can end:

| Word | Ends | State after | The word's columns | Taken again |
|---|---|---|---|---|
| keep held | probed | held, "kept held by the owner" | keep 1 | never as a held probe |
| keep held | restart | held, "kept held by the owner" | keep 1 | never as a held probe |
| keep held | a late copy, then probed | held, "kept held by the owner" | keep 1 | never as a held probe |
| keep held | aside, then its time | held, keep 1, but the reason reads "looks like a saved file" (**S4**) | keep 1 | never as a held probe |
| keep held | gone | gone | keep 1 | no |
| release | probed | wanted | released 1, probable 0 | downloaded next |
| release | aside, then its time | wanted | released 1, probable 0 | downloaded next |
| release | restart | wanted | released 1, probable 0 | downloaded next |
| release | a late copy, then probed | wanted | released 1, probable 0 | downloaded next; the late copy changes nothing |
| release | gone | gone | released 1 | no |

- **Words:** no word is lost or applied to another file (one row by id).
- **S4, note:** after a set-aside and its time, `asideBackSQL` writes the ladder's reason. The keep-held flag is
  kept, but the page shows "looks like a saved file" instead of the owner's word. A fix:
  `reason = CASE WHEN keep_held = 1 THEN reason ...` in asideBackSQL, or rewrite ReasonKeptHeld at the give-back.
- **The switch off, or held_wait off:** both words are refused as at the head (`TestZZC30bWordRealDownload`).
- **S5, note:** `heldProbeTurnWord` takes "a file in its turn that is a probable copy" as "a held probe's turn". The
  owner's "different" on a file in transfer (`pairBackHeldSQL`, pairword.go) gives an active real download
  probable 1, so that its give-back holds it.
  - **Probe:** with the switch and held_wait on, "keep held" on such a file is accepted (keep 1). Its transfer then
    ends saved and the row goes, so the word is taken and then made moot by the download, where the head answered
    ErrWrongState.
  - **Effect:** this needs the owner to act on a file in a real transfer, so it is narrow.
  - **Fix:** accept only a file the Supply claimed as a held probe, for example a row in c_probe with no done result
    and check_first 0, or a mark written by the held claim.

### (5) F6: "same post" or exact evidence overwritten? **Not real (S6)**

`TestZZC30bEvidenceKinds`: a held file with three probable edges to three Telegram files of the same saved bytes,
one each of "same post (…", the exact check's three places, and look-alike. After a copy:
- only the look-alike edge gets "sampled frames 6 of 8";
- the other two keep their evidence;
- the reason stays the "same post" one (heldReasonSQL takes it first);
- there are 0 exact edges.

### Verdict of the second pass

May be listed after these fixes:
- **S1:** a held file's kept parts go before any unique file's under the cap and the floor, and are kept only while
  its row is open.
- **S2:** `probeOpenHeldOutSQL` leaves out an aside probable file too.

Each needs a test (the probes `TestZZC30bCapCrowd` and `TestZZC30bAsideFurther` show the cases). S3 to S5 are notes
for the track's list.

---

## Third look (S1, S2, S5)

**Scope:** code 552d183d; head 917cb786, which adds only the report. I read `git diff 233b0cbf 917cb786` and checked
917cb786 out detached in the scratch copy; no tracked file was changed.

**What ran:** the probes are in the uncommitted file
`wt-copies-review35-scratch/archiver/internal/supply/zz_probe_c30c_test.go`, with the log in
`runs-copies-r30/zz11.log`. They use the real `parts.Store` and `partsledger`, invented data only, named tests
through `go1.sh`.

| # | Question | Finding | Real? | Severity |
|---|---|---|---|---|
| T1 | 1 | Under the cap, a held file's fresh parts are kept and an older unique file's parts are removed | real | **must fix** (small) |
| T2 | 1 | With the switch off, a put's trim takes a held file's parts first, where the head went by age | real | note (better than the head) |
| T3 | 1 | A held probe's turn that ended in a set-aside is not spare | real | note |
| T4 | 3 | A real download with an open frame-check row, made probable mid-transfer, takes the owner's word | real | note (very narrow) |
| (2) | 2 | A unique file's set-aside still counted | yes, counted | not real |

### (1) S1: held parts first under the cap and the floor? **Mostly; one case real (T1)**

`TestZZC30cTrimOrder`:

| Case | Unique parts left | Held parts left |
|---|---|---|
| A held probe waiting for its judge, parts 40 min old; a unique file aside for its judge, parts 3 h old; cap | 2 | 0 |
| The same; floor | 2 | 0 |
| A held probe's parts fresh (2 min); a unique wanted file, parts 3 h old; **cap** | **0** | **2** |
| The same; floor | 2 | 0 |

- **T1, real, must fix (small).** `trimLocked` skips every fresh file (FreshFor, 10 min) in either group. When a
  fresh held file is what keeps the store over the cap, the loop goes on into the non-spare group and removes an
  older unique file's parts. For the 10 minutes after each held probe's turn, a held file's parts can stand before a
  unique file's.
  - **Fix:** in the cap's loop, count the bytes of fresh spare files as in flight before removing any non-spare
    file. For example, stop the non-spare part of the loop once `total - freshSpareBytes <= cap`. Fresh held parts
    then make the cap soft, as fresh files already do, instead of costing a unique file its parts.
  - Test: the case above.
- **The floor:** right in every case. Its order is spare older, spare fresh, others older, others fresh.
- **"Never a file's still being checked":**
  - a unique file in its check is active or aside, so never spare: right;
  - a held probe waiting for its judge is spare and goes first. That is the design (held after unique), and it
    costs only that held probe's check.
- **T3, note.** A held probe's turn that ended in a set-aside is `aside`, so it is not spare and is ordered with
  unique files until its time.
- **T2, note: the switch off.** `Spare` is `state = 'held'`, whatever the switch says.
  - **Probe:** last case of `TestZZC30cTrimOrder`. The switch is off, and a held file (not a probable copy, for
    example its chat switched off) still has parts between two sweeps. A sweep with no needs pass stands in for a
    put's trim. The held file's parts go first (unique 2 left, held 0). The head goes by age only, so it would have
    taken the older unique file's.
  - So the order is not exactly the head's. The difference touches only held files, whose parts are not needed with
    the switch off and go at the next sweep anyway, and it is in the unique file's favour. If "exactly the head's"
    is required, the fix is to set `Spare` only when the switch is on.
- **Anything else in the sweep:** nothing.
  - The needs pass, the folders' sweep and the fresh rule are unchanged.
  - `freeUpLocked` with no spare file gives the head's order (older, then fresh).
  - `PartFiles` adds one c_want key seek per file.
  - `PartsNeeded` now keeps a held probable copy's parts only while no row is done, and the held claim now writes an
    open row: both as the report says.

### (2) S2: is a unique file's set-aside still counted? **Yes, counted: not real**

`TestZZC30cOpenCount`: a unique video planned and probed, then set aside for its judge (probable 0). `ProbeOpen` is 1
with the switch on and 1 with it off. The new term leaves out only files with `probable = 1`. A unique file in its
check has probable 0. Where `pairBackHeldSQL` gives a set-aside file probable 1, the file is going back to held: it is
no longer a unique check.

### (3) S5: the word only for a held probe's turn? **Mostly; the remaining case real (T4, note)**

`TestZZC30cWordRow`:
- **A held probe's turn:** the claim now writes the open row (phase fetch), so "keep held" is accepted and wins at
  the turn's end (held, keep 1).
- **A real download made probable mid-transfer** (the columns `pairBackHeldSQL` writes):

| Its frame-check row | Keep held | Release |
|---|---|---|
| none | refused, as at the head | refused, as at the head |
| done | refused, as at the head | refused, as at the head |
| **fetch** | **accepted** | **accepted** (released 1) |
| **judge** | **accepted** | **accepted** (released 1) |

- **T4, real, note (very narrow).** These are the coder's remaining case.
  - **How it comes about:** a full transfer of a file with an open row is possible. A file with a resume checkpoint
    is handed out for a full transfer (`Resumed`) and its row is left open.
  - **What it needs:** all four of these at once:
    - a checkpointed file whose frame check is still open;
    - the exact check's mark on it;
    - the owner saying "different" on its pair during that transfer;
    - the owner then pressing keep held or release on that same file before the transfer ends.
  - **What it costs:** release is consistent: the file is downloaded and recorded as released. Keep held is taken
    and then made moot by the save. Nothing is lost or wrongly downloaded.
  - **A full cure** would be a mark that only the held claim writes, for example a column, or the c_probe row's own
    `plan = '[]' AND rounds = 0` together with c_count_hourly. Not needed for listing.

### Verdict of the third look

May be listed after this fix: **T1**, the cap's trim counting fresh spare (held) files' bytes as in flight, so that
it never removes a non-spare file's parts while a fresh held file keeps the store over the cap. It needs a test (the
case "held probe's parts fresh, cap" in `TestZZC30cTrimOrder`). T2 to T4 are notes.
