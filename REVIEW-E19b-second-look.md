# Review E19b: the second look at E19's fix rounds (independent, Opus 5.5, 11-16)

**Reviewed:** `4bb0ba2c..865681c1` on `wip/copies-19` (22 commits: E19b, then E19c). I read the first review, the fix
brief, the whole difference, and sections 7 and 8 of `copies-pairword-REPORT.md`. `wt-copies-19` was not touched.

**Scratch copy:** `C:\Users\trabi\Claude\Projects\Telegram\wt-copies-review19b-scratch`, detached at `865681c1`. It is
not committed and was left in place. It holds two untracked probe files:
- `archiver/internal/catalog/zz_probe_e19b_test.go`
- `archiver/internal/pairwords/zz_probe_e19b_test.go`

Two code breaks were made there and undone with `git checkout`. The first reviewer's three failing probes exist on the
branch as named tests, adapted to the new `SetPairWord`, and I ran those. `TestProbeBatchPanic` was not run.

**How it ran:**
- Invented data only. Nothing ran against Telegram, and no folder of the owner's was opened.
- Named tests only (`-run`, `-count=1`, `GOMAXPROCS=2`), one run at a time.
- The PC had 3.6-3.8 GB free, with the CPU at 39-63%.
- Not run: the whole `internal/catalog` or `internal/supply`, `go vet`, the race detector.

**Download path:** `git diff dbca91d4 865681c1` of `lane.go`, `state.go`, `schema6.go` and `chosen.go` is empty. Only
`catalog.go` changed (the step's three places).

---

## Findings

### 1. HIGH (confirmed). A copy held while its chat or topic was off, whose hold the word or a loss ends, is held for good with no evidence once the chat or topic is collected again

**How it happens.** When a chat is switched off, `chatHoldSQL`'s second statement makes a held probable copy
`probable = 0`, and its reason stays "looks like a saved file". `topicHoldSQL` does the same. Then:
1. "different" (or the loss of the saved file, for the first 200 look-alikes) removes the copy's only edge.
2. `pairEdgeLost` judges only `held AND probable = 1` or wanted-and-marked. This copy falls to "held for another
   reason" and is left: held, `probable = 0`, look-alike reason, no edge, not in `c_pair_pending`.
3. When the chat or topic is collected again, `judgeChat` runs:
   - `markCheckFirst` needs an edge, so it does nothing;
   - `wantedAsMainSQL`'s third statement sets `probable = 1` by the reason alone (`probableReasonSQL`, with no edge
     check).

The file is now a held probable copy of nothing. With `HeldWait` on (the default) it is never supplied. With
`HeldWait` off it waits in tier 5. For the word this is the opposite of what the owner said.

**Probes:**
- `TestZZProbeHeldChatOffThenOn`, the word: ends `held/"looks like a saved file"/ptrue`, edges 0. **FAILS.**
- `TestZZProbeHeldChatOffThenOn`, the saved file lost: the same. **FAILS.**
- `TestZZProbeHeldTopicOffThenOn`, both entries: `{held, looks like a saved file, probable true}`, edges 0. **FAIL.**
- A kind no longer collected while held: the same statement (`chatHoldSQL`), so the same result. Traced, not probed.

**Why the tests miss it.** The branch's `TestPairEndedHoldAsksTheRule`, case "while held", asserts only "held, not
probable", which this state is. Neither it nor any other test undoes the change.

**Not affected:** the rest beyond 200 (`c_pair_pending`'s door does judge a held file with `probable = 0`).

**Smallest fix:** in `pairEdgeLost`, judge a held file that is not kept held whose reason is a probable copy's
(`probableReasonSQL`'s set), whether or not it is probable, through `pairJudge`. The rule then writes
`ReasonChatPref` or `ReasonTopicPref`, and `judgeChat` or the topic settle brings the file back wanted. Add one test
per change (chat, kind, topic) × entry (word, loss): changed while held, hold ended, change undone, then wanted.

### 2. MEDIUM (plausible, computed from the house's figure). The bounds are counts, and a judged file's cost grows with the catalogue

**Measured here, on a near-empty catalogue:**

| What | Writer held |
|---|---|
| `WantAgain`, 5,000 look-alikes | 236-239 ms: edges 20-22, the 200 judged 148-149, the rest made not probable 53-56 |
| The door's slowest transaction | 70-73 ms |
| A reader chunk of 100 "different" | 207 ms |
| A reader chunk of 100 taken back | 74 ms |

Each judged file pays rung 6's read. At the owner's scale (`TestLookAlikeCostAtScale`), rung 6 costs about 1 ms per
file in a median second and 6-8 ms in the densest second. Look-alikes of one popular saved video share its length,
which is the case where many are held against one file. So at scale, by estimate:
- `WantAgain`'s 200: about 0.35 s to 1.6 s;
- a door chunk of 100: up to about 0.8 s;
- a reader chunk of 100 "different" (each can judge two files): up to about 1.6 s.

Each of these holds the single writer, and so every claim and finish (TRIED-BEFORE 21). The base's own chat settle
has the same shape. That is why it would be worth bounding by time.

**Smallest fix:** a time budget per transaction instead of a fixed count:
- `lostLookAlike` stops judging at about 100 ms and puts the rest into `c_pair_pending`, as it does now;
- `SettlePairPending` ends its chunk at about 100 ms;
- the reader's chunk counts the files that can be judged.

Or smaller counts (50 / 25 / 25), measured once on the scale world.

### 3. LOW (confirmed). The reader keeps the viewer's file open during the whole apply
`readAndApply` defers `db.Close()` until after `apply`, which runs the catalogue chunks with their checkpoint gaps:
seconds for a few hundred words, longer for many. If the viewer closes in that time, its `-wal` and `-shm` stay in
its folder. They go only at the viewer's next close. A rename or removal of its file is refused while the apply runs.
This is finding 4 of the first review, again, for the length of every apply. It is not just the narrow race the coder
names.
- `TestZZProbeViewerClosesDuringApply`: the listing after the turn is `decisions.sqlite`, `-shm` and `-wal`.
  **FAILS.**

**Fix (one line):** close the connection right after `read` (the words are already in memory), before `apply`.

### 4. LOW (confirmed). "The owner's release or fetch-for-real wins over the rule" has no test
Break E made `pairJudge` ask the rule for a released file too (`if !noHold` → `if true`). All of `TestPair*`,
`TestLostLookAlike*`, `TestWantAgain*`, `TestHoldExact*`, `TestHoldLookAlike*` and `TestRelease*` still **pass**.
The rule is right: it matches `notCollectedBack` and `chatHoldSQL`, which both spare `released` and `fetch_real`. It
needs a test.

### 5. LOW (traced). The settle's hooks
- **The collector's own settle does not see waiting files.** `collector.settleTask` ("also while no lane asks") asks
  only `SettlePending`. Waiting files are judged only from a lane's `Next`, or when an owner action waits. That is
  harmless while nothing downloads. One line there (`|| cat.PairPending`) would close it; that file is not this
  piece's.
- **An empty table still costs a little.** `Supply.Settle` always calls `SettlePairPending` at least once (`left`
  starts at 1). So every owner-action settle now also pays a checkpoint gap and an empty writer transaction, even with
  the table empty. Ask `PairPending` first.
- **The door's loop delays owner actions.** While it runs (up to 1,000 chunks), `settling` stays true, so a newly
  stored owner action waits behind it: seconds now, minutes after a very large loss at scale.
- **One file failing every time holds its chunk back.** It rolls the chunk back at every tick, so the 99 files behind
  it stay held and out of the lanes while that lasts. This is counted in `Errors`, and nothing is lost.

### 6. LOW. The schema step and its comments
- **A file at the step's version from the first form has only `c_pair_word`.** A file made by the first form of this
  branch (`4bb0ba2c`, one table) is at the same version, so the step never runs again on it. On it:
  - `PairPending` fails at every Supply tick (an error counted every `SettleEvery`, and no pair settle);
  - `WantAgain` of a file with more than 200 look-alikes fails.

  Such a file exists only if a program built from `4bb0ba2c` opened a catalogue. I found no sign of one. The
  integrator renumbers the step at the merge anyway.
- **Stale comments:**
  - the schema comment still says a waiting file is kept out by "lane.go's guard" and "state.go claimSQL";
  - `catalog.go`'s `steps` line names `c_pair_word` only.

### 7. LOW (traced). A file on another archive's saved list whose hold ended is held with no edge
`pairJudge` and `pairPendingJudge` leave it, or make it again, a held probable copy with no edge. It is supplied in
tier 5, or waits for good under `HeldWait`. It is narrow: `ImportKnown` skips held and wanted known files at once
(exact, by kind and Telegram id), so this needs a file that was in transfer at the import. It is the brief's rule ("this
door never skips"), so it can stay. The viewer shows a "probable copy" with no pair.

### 8. LOW (by design). A real single take-back can wait a day
While more than 10 words are absent (a replaced or emptied file waiting its day), any genuine take-back waits its own
day as well. A restart starts every day again, so a mass take-back can be delayed for good by daily restarts. It is
never hastened. This is as the brief asked; it should be said to the owner.

---

## Answers per question

**Q1. Every place that writes `wanted`.**

| Place | What it asks first | Verdict |
|---|---|---|
| `pairJudge`, reached from the word's end, a lost look-alike, the door (`pairPendingJudge`) and both hand-backs (`pairHandBack`) | `mediaNowOf` + `wantRule`, unless the owner released the file or set it to be fetched for real | Asks the rule |
| `pairRejudge` writes `wanted` only after `pairJudge` | The rule (above) | Asks the rule |
| `pairTakenBack` | `coveredWantSQL` (collected, own media) | Can only hold |
| A file in transfer or set aside | `pairBackRule` (the same read and rule, edges set aside): wanted clears the flags; held gets `pairBackHeldSQL` and a row in `c_pair_pending` | Asks the rule |
| `HoldLookAlike`'s "ended" branch | Gives back held, then `pairHandBack` | Asks the rule |
| `HoldExact`'s word branch | `backToSQL`, then `pairHandBack` | Asks the rule |

The reviewer's three probes pass as named tests: `TestPairWordChatOffInTransfer`, `TestPairWordAltInTransfer`, and
`TestWantAgainLookAlikeOfChatOffInTransfer`. So do the branch's 24-case `TestPairEndedHoldAsksTheRule` and
`TestPairHandBackAsksTheRule`.

My own probes for the cases the brief named:

| Case | Result |
|---|---|
| Set aside: chat off, kind no longer collected, alternative version × word and loss (`TestZZProbeAsideEntries`, 6 cases) | All held as the rule says. Never wanted, never probable. |
| A lost look-alike's rest in transfer, then `HoldLookAlike` (no word: not "ended") | Held probable with its row kept; the door then judges it (wanted) |
| Changed **while held** | The open case: finding 1 |

**`wantAgainMedia`'s move (84dc8a0b).** I read it line by line. The switch's cases are in the same order with the
same results. On the old path, a `checkFirst` error fell through to `case err != nil: return err`. On the new one,
`checkFirst` returns false, `wantRule` goes on to the `probEdge` case, and `if err != nil { return err }` follows: the
same outcome. The insert takes the same values from `m`. No existing `WantAgain` test changed: no `staging*_test.go`
is in the difference. The coder lists the tests that guard it (`TestWantAgain*`, `TestLostLookAlike*`,
`TestBP2RevivedRowIsNotVerified`, `TestCheckFirstLater`, and others), and I ran `TestWantAgain*` and
`TestLostLookAlike*`.

**"The release wins."** Yes, that is the catalogue's rule elsewhere:
- `notCollectedBack` requires `fetch_real = 0 AND released = 0`;
- `chatHoldSQL`'s first statement spares them;
- `wantedAsMainSQL`'s fourth makes them wanted.

So it can make wanted a released file from a chat switched off, exactly as the base keeps such a file wanted. It is
untested (finding 4).

**A file on another archive's saved list:** finding 7.

**Q2. The waiting files.**

| What can meet a waiting file | What happens |
|---|---|
| `judgeChat` and the topic settle | Can only take `probable` off, hold as not collected, or (third statement) make a waiting held copy probable again: tier 5, never wanted. The door then judges it (`TestPairPendingOtherRules`). |
| `markCheckFirst` | Needs an edge; there is none. |
| `roleChanged` | Holds it as an alternative version (the door only removes the row), or `wantedAsMain` (above). |
| `attach` meeting the same Telegram file again | `wantedAsMain` (above). |
| `Release`, `asideBackSQL` and `probeWantedSQL` for a file given back with `pairBackHeldSQL`'s columns | Held with the look-alike reason (the aside probes show it). |
| The owner's hand ("keep held", `ReasonOwner`) and the chat settle's reasons | `pairPendingJudge` leaves them. |
| Saved or gone | The row is only removed. |

Nothing writes `skipped` or `gone`, and no `c_want` row is deleted. Every row of `c_pair_pending` is deleted before its
file is judged, so the door always makes progress.

- **At a restart:** the table is in the catalogue. Waiting held files have `probable = 0` and are not supplied; the
  first `Next` after `SettleEvery` judges them.
- **When the door fails every time:** the files stay held and out of the lanes, with an error counted each tick. They
  are never lost (finding 5).
- **When the media's row is deleted:** the row goes with it (`ON DELETE CASCADE`).
- **Judged twice:** I found no way for a file to be judged twice to a different answer. A second loss or a word on a
  waiting file finds no edge (`pairLeftAs`). `pairHandBack` removes the row and judges once.

**The coder's window** (a file given back held, probable, with no edge, until the next settle):
- It lasts about `SettleEvery` (1 s) plus the settle's run. Only a tier-5 claim can take the file, so only with
  `HeldWait` off (it is on by default) and a lane with nothing else to do.
- The base's own window for a plain file in transfer whose topic is un-chosen, or that is made an alternative version,
  is permanent: `Release` gives it back wanted at its normal rank.
- So this is smaller than the base's.

The open defect in this area is finding 1, which is not about waiting files at all.

**Q3. The Supply's settle.**
- **Where it is called from:** a lane's `Next` → `settleDue` (synchronous, at most every `SettleEvery`). `PairPending`
  is read there only when `SettlePending` says no. The judging itself runs in the settle goroutine (`Settle`); the
  collector's `settleTask` calls `Settle` only when an owner action waits (finding 5).
- **Cost while the table is empty:** `PairPending` is `hasPairWords` (true at once on the writer handle) plus
  `pairPendingSQL LIMIT 1`. Its plan is `SCAN p` with a correlated `SEARCH w USING INTEGER PRIMARY KEY`. Measured
  1,000 calls in 32 ms, about 32 µs each, on the reader pool.
- **Can a lane wait on it?** A lane's `Next` waits on the door only as it waits on any writer transaction: 70 ms here,
  more at scale (finding 2).
- **A failing door:** it breaks the loop after `catalog.Settle` has run, so the chat settle's chunks still run.
- **With no word and no loss ever:** the path is the base's, plus one 32 µs read per `SettleEvery` and, in each
  owner-action settle, one checkpoint gap and an empty writer transaction (finding 5).

**Q4. The writer's time.** The table is under finding 2. The one statement that makes 4,800 rows `probable = 0` took
53-56 ms. Nothing measured here is over 250 ms; the largest is `WantAgain` at 236-239 ms. All of it grows with rung 6's
window. By the house's scale figure, several would pass 250 ms on the owner's catalogue (finding 2).

**Q5. The reader.**
- No kept connection: right, except during the apply (finding 3).
- The copy goes into `WorkDir` with mode 0600, and is removed after the read and at `Run`'s start.
- **The copy opened `immutable`:** safe. It is the reader's own file, and nobody else writes it. It is copied only when
  the viewer's file has no `-wal`/`-shm`, so the copy holds everything committed. It is looked at again after the copy,
  and checked with `quick_check`.
- **Change seen by the file's times alone:** probed (`TestZZProbeWALRestartSeen`). After a checkpoint, the viewer's
  next commit restarts the log at the same size (94,792 bytes before and after). Only the log's modification time
  changed, and Windows reported it at once through `os.Stat` while the viewer kept the file open. The word was applied
  at the first turn.
- **The narrow race the coder names stands;** finding 3 widens it to the whole apply.
- **The missing table** is a failure of the file (`TestReaderMissingTable`).
- **The 24 hours, case by case:**

| Case | What happens |
|---|---|
| Per word | Yes |
| A restart | Starts every day again (finding 8) |
| Rows that come back | Forgotten |
| Exactly 10 and 11 | Tested (`TestReaderTakeBackBound`) |
| A mix of new words and take-backs in one turn | New words at once; only the take-backs are bounded |
| A real single take-back | Held up while more than 10 others wait (finding 8) |

- **Nothing created in the viewer's folder:** listings asserted in `TestReaderKeepsNoConnection` and
  `TestReaderMissingAndIdleFile`. The exception is the apply-time close (finding 3), where the viewer's own journal
  files are left, not files the reader made.

**Q6.**

| Fix | What I checked |
|---|---|
| 6 | `backToSQL`, then `pairHandBack` (`TestHoldExactWordKeepsAnotherHold` passes) |
| 7 | The edges to the other file's twins, both ways; exact edges kept (`TestPairWordTwinEdge` passes) |
| 10 | `appliedAt` is a parameter of the door, given by the reader's clock |
| 11 | Rung 6 runs at `attach` only for a new `tg_media` row (the "seen again" path returns before it), so `words = false` there is right |

**With no word on record**, each path is the base's:
- `lookAlikeVideo` gets a nil `differ`, as on the base;
- the stills rule decides while reading, the first match ending the read, as on the base;
- the step at a save and the exact check's hand-backs are unchanged, apart from the word branch;
- the plans are unchanged (`TestPairWordPlans` passes).

**Q7. The schema step.** It makes two tables in one step, with `IF NOT EXISTS`, in the house's form. A file made by
the first form at the same version lacks `c_pair_pending`, and the step does not run again on it (finding 6). That is
only possible for a test copy, or for a program built from `4bb0ba2c`.

**Q8. Tests.**

Existing asserts that changed, each right:
- `TestReaderChunks`: chunks of 100, and the "all 600 taken back at once" removed, as fix 2 asks;
- `TestReaderMissingAndIdleFile`: now through the copy;
- `TestPairWordSchemaStep`: compares `c_pair_pending` too;
- `TestPairWordPlans`: two plans added;
- `TestPairPendingNeverSupplied`, `TestLostLookAlikePending` and `TestWantAgainManyLookAlikes`: rewritten for E19c's
  `probable = 0`;
- every call of `SetPairWord` takes `appliedAt`.

**Test functions removed: none** (compared per file against `4bb0ba2c`).

My two breaks:

| Break | Result |
|---|---|
| A: the door's read without its "not in transfer or set aside" filter | `TestLostLookAlikePending` fails: "in transfer: left 0, waiting []" |
| E: `pairJudge` asks the rule for a released file too | **nothing fails** (finding 4) |

**Rules with no test:**
- a change made while the file was held, undone after the hold ended (finding 1);
- the owner's release wins (finding 4);
- the collector's settle (finding 5);
- the apply-time close (finding 3).

---

## What I did not look at
- A run on the scale world: finding 2 is computed from `TestLookAlikeCostAtScale`'s recorded figure.
- The frame check's doors beyond `probeWantedSQL`, and `Transition` beyond the reasons `pairPendingJudge` leaves.
- The kind case of finding 1 (traced only).
- The supply test with the settle's loop removed: by reading, `TestSupplySettlesPairPendingFromItsTick` waits for the
  table to empty, so it would fail.
- The race detector; `go vet`; whole-package runs.
- File times on file systems other than this PC's NTFS.

**may be listed after these fixes: 1, 2** (3 is a one-line change worth taking in the same round; 4 and 5's collector
line strongly recommended).

---

## The check of E19d (e05e511c)

**How it ran.** The scratch copy was moved with `git checkout --detach e05e511c`. My two probe files are still there,
with three probes added (`TestZZProbeD1ClearThenOn`, `TestZZProbeD2TwoHolds`, `TestZZProbeD3MissedHold`). One break
was made and undone with `git checkout`. Only named tests ran (`GOMAXPROCS=2`, one run at a time), with 2.7 GB free and
the CPU at 27-30%. Invented data only; nothing ran against Telegram.

### 1. Finding 1: fixed

**My probes pass at this head:**
- `TestZZProbeHeldChatOffThenOn`, the word and the loss: the hold ends as held, "this chat does not collect this kind
  of file", not probable; with the chat on again, the file is wanted.
- `TestZZProbeHeldTopicOffThenOn`, both entries: held with the topic's reason, then wanted once the topic is chosen
  again.

**The orders I tried:**

| Order | Result |
|---|---|
| The word, then `ClearPairWord`, then the chat on (D1) | Held as not collected after the word and after the take-back; wanted once on (no edge) |
| Two holds on one file (D2): the word on A, chat on, chat off again, the word on C, chat on | After the first word: held, look-alike reason, edge to C kept; on: a probable copy *with* its edge; second word: held as not collected; on: wanted |
| Loss beyond the bound (the coder's new test) | Wanted after the undo |
| Change undone *before* the door runs (traced) | The third statement makes the waiting copy probable; the door then judges it (held, probable, no edge in the table → `pairJudge`) |
| A kept-held file | `keep` is checked first and left; the third statement excludes `keep_held` too |
| In transfer at the word | Unchanged from before (`Release` gives back `probable = 1`, then the rule) |
| Each hand-back | `pairHandBack` now takes `copyReason` too |

**Break:** `copyReason` taken out of `pairEdgeLost`. Two tests fail: `TestPairEndedHoldThenCollectedAgain` and
`TestPairReleaseWinsOverTheRule`.

**`noCopyOfNothing`'s exclusions:**
- Kept held: right. It is the owner's hold, and the third statement never makes it probable.
- Waiting files: right. The door judges them, and the tests assert `left == 0` beside it.
- On another archive's saved list: finding 7, as the brief says.

It looks only for `probable = 1`. So in the "while held" cases it sits where the defect is still latent (`probable = 0`)
and cannot catch it there. It catches it only after an undo, which `TestPairEndedHoldThenCollectedAgain` does (finding
11).

**Wanted without asking rung 6 again: a missed hold only, never a file lost or stuck.** `TestZZProbeD3MissedHold`
shows it: two saved look-alikes, A and B. The word on (x, A) while the chat is off; chat on: x is wanted, with no edge
to B. The control, with the chat on throughout, holds x against B. Not a wrong "wanted" by the owner's choice rule (the
chat collects it). It does bend "probable copies never go before unique files" for that one file (finding 9).

### 2. Finding 2: the budgets

**What I checked:**
- **Can an op answered `Later` be lost, applied twice or reordered?**
  - Lost: no. The reader goes on from the first op not applied, in the same turn. If the turn ends, the next read
    computes the difference again from the catalogue's words.
  - Applied twice: no. Ops are never stored, so no stale op is replayed, and an applied op is in the catalogue.
  - Reordered: no. A "different" cut by the budget and then taken back in the next read simply never reaches the
    catalogue, and the take-back finds nothing.
- **Progress:** every transaction does at least one file or op, so even a first file over the budget makes progress.
- **The Supply's stop rule** ("a chunk left as many as the one before"):
  - It can end a settle early: files coming back from transfer can make `left` stop shrinking.
  - It cannot end it for good: the next `Next` after `SettleEvery` asks `PairPending` again.
  - The 1,000-chunk cap works the same way.
- **The door and the reader:** the door's slowest transaction is 72-77 ms, and its budget is checked after each file,
  so it passes by at most one file's cost.

**Measured three times, `WantAgain` with 5,000 look-alikes:**

| Phase | Time |
|---|---|
| Edges | 17-22 ms |
| Judging, stopped at the budget | 100-101 ms (124-135 files) |
| The rest made not probable | 54-59 ms |
| Whole transaction | 184-196 ms |

The coder's 981 ms did **not** reproduce. The phases add up to about 180 ms, and nothing outside them took long here.
The outlier was most likely the PC or the checkpointer of the 5,000 posts just made: a guess, not shown.

The budget bounds only the judging. The edges' read and removal and the "rest" statement both grow with the number of
look-alikes, about 12 µs a row (finding 10).

### 3. Fixes 3, 4 and 5

| Fix | Verdict | Evidence |
|---|---|---|
| 3 | As asked | `db.Close()` before the apply; `TestZZProbeViewerClosesDuringApply` now leaves only `decisions.sqlite` |
| 4 | As asked | `TestPairReleaseWinsOverTheRule` covers fetch-for-real (held and in transfer) and fails under the break of `copyReason`. The test sets `fetch_real` only; `released` reaches `pairJudge` through the same `noHold` flag, so it is covered by construction |
| 5 | As asked | A failing file is rolled back to its savepoint, counted (`lookalike.lost_pending_failed`) and left waiting; the rest of the chunk is judged. It does not spin: once only failing files are left, `left` stops shrinking and the Supply's loop ends; it is tried again at the next tick, counted each time (finding 12) |

### 4. The download path
`git diff --stat dbca91d4 e05e511c -- archiver/internal/catalog/lane.go archiver/internal/catalog/state.go` prints
nothing. Confirmed.

### 5. Loosened assertions
- **`TestReaderChunks` and `TestReaderEmptiedTable`** now use `chunked`: every call at most the bound, the first call
  exactly the bound, and the sum at least the total. The exact list of calls is gone. That allows extra or re-sent
  calls, which a budget cut makes necessary. The applied counts (600 "same", 500 taken back after the day, the log
  said once) are still asserted. So they are still worth what they were, except that they no longer pin "no call
  smaller than needed". `judgeBudget` cannot be raised from `internal/pairwords`, so they could not be made exact.
- **The `[300]` assertion** is now "the first call is 300". That is fine.
- **`TestWantAgainManyLookAlikes`** only changed its log line.

### New findings

**9. LOW (confirmed).** A copy whose hold ends while it is not collected comes back wanted without rung 6
(`TestZZProbeD3MissedHold`). A saved look-alike that already exists is missed, so a probable copy is downloaded at its
normal rank. That is one download more, never a file lost or stuck. **Smallest fix:** in `pairJudge`'s not-collected
branch, ask rung 6 first, as `attach` does (rung 6 before the kind check). On a match: held, the look-alike's reason,
`probable = 0`, with the new edge. Otherwise as now.

**10. LOW (measured, plausible at scale).** `WantAgain`'s edge removal and its "rest made not probable" statement are
outside the budget and grow at about 12 µs a look-alike: about 0.25 s at 20,000 look-alikes of one file. **Smallest
fix:** none needed now. If ever needed, write the rest in chunks of the same budget, or leave all the rest to the
door.

**11. LOW (test).** `noCopyOfNothing` sees only `probable = 1`, so in tests without an undo it cannot catch the latent
state. **Smallest fix:** also count held rows with a probable copy's reason, `probable = 0`, no edge, not kept held,
not waiting.

**12. LOW (plausible).** The door's read takes the lowest ids first, so failing files come first in every chunk. With
100 or more of them failing every time, they fill each chunk and the files behind them are never reached while that
lasts. The failures are counted each tick. **Smallest fix:** order failed files last, for example a `failed_at` column
or a skip list in memory for the turn.

**may be listed** (9 to 12 are low; 9 is worth taking when `pairJudge` is next touched).
