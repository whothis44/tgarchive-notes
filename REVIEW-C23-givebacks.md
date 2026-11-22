# Review C23: the copies track's give-backs judged (`wip/copies-28`, 86ebd1d0..8942c6ef)

Reviewer: Opus 5.5 (high effort), 2026-11-21, independent. Read in the scratch copy
`wt-copies-review28-scratch` (detached at 8942c6ef). Nothing tracked was edited or committed; no branch or remote was
touched; invented data only; no Telegram request. Every go command went through `runs-copies-r23/go1.sh`, named tests
only, no race detector.

**Probes** (uncommitted, left in the copy): `archiver/internal/catalog/zz_probe_c23_test.go`.
**Overlays** (in this session's scratchpad, not in the copy): `ov-old.json` (86ebd1d0's `exactcheck.go`, `probe.go`,
`ladder.go`, `pairword.go`, `state.go` over the head) and three one-line mutations `ov-m1.json`, `ov-m2.json`,
`ov-m3.json` (question 8). Logs: `runs-copies-r23/rv-*.log`.

## Findings in one line each

| # | Finding | Real? | Severity |
|---|---|---|---|
| R1 | The frame check's verdict doors erase the owner's Retry (`ReasonOwner`) before they judge, so a file the settle spared is held | real (probe) | should fix |
| R2 | A copy verdict on a file fetched for real whose topic was un-chosen in transfer now answers held with no why, so the judge removes its kept parts | real (probe) | note |
| N1 | The extra read costs about 55 to 70 µs per give-back, not "a few µs" (10 to 15% of one door) | real (measured) | note |
| N2 | Go 1.27.3's `Rows.Scan` leaves `closemu` read-locked on a panic (the report's point f) | real (source and test); unreachable from catalogue code today | note |

Everything else asked is "not real" below.

## 1. Every statement that moves a file out of `active` or `aside`, or holds it

My own list, by reading both files and what they call:

| Where | Statement | Judged after C23? |
|---|---|---|
| `exactcheck.go` `CheckLater` | active → aside (`ReasonExactNotStarted`) | not a give-back: the requeue judges it (`requeueOne`, K17) |
| `LinkSame`, not linked | active → `backToSQL` | yes (`giveBack`) |
| `LinkSame`, linked | `DELETE FROM c_want` | not a hold: linked by exact evidence |
| `HoldExact`, saved file gone | active → `backToSQL` | yes (`giveBack`) |
| `HoldExact`, released | active → wanted | no, and needs none: all four statements of `givenBackHolds` require `released = 0` or `state = 'held'` |
| `HoldExact`, differs | active → `backToSQL`, `pairHandBack` | yes (`judgeGivenBack` after) |
| `HoldExact`, hold | active → held probable | yes |
| `HoldLookAlike`, all three branches | active → held probable, or wanted (fetch real / released), `pairHandBack` | yes |
| `markCheckFirst` | held → wanted marked | not a transfer door: called by the settle itself (`judgeChat`) and the ladder with the collected condition |
| `HoldCheckFirst` | wanted → held probable | a wanted file only (the settle judges wanted files); unchanged by C23 |
| `probe.go` `ProbeFetched` (both paths) | active → aside (`ReasonProbeJudging`) | not a give-back: requeue or a probe door judges it |
| `probeSettle` `wanted` | wanted/aside → wanted or held (`probeWantedSQL`) | yes (`probeGiveBack`) — but see R1 |
| `unknown`, held | aside → held | yes |
| `unknown`, not held | wanted/aside → aside (`probeAsideSQL`) | not a give-back: stays out of the lanes; the requeue judges it |
| copy verdict | wanted/aside → held probable (`probeHeldCopySQL`) | yes |
| `ProbeWaitJudge`, `ProbeRejudge` | wanted → aside | not a give-back |
| `ProbeLaneRefused` | `Release` | yes (K17) |
| `ProbeCloseAll` | aside → wanted/held | yes |
| `ProbeUnchecked` | no `c_want` change | — |

What they call (`AddCopyEdge`, `MarkPartlySame`, `recordCheck(With)`, `pairFileDiffers`, `savedMediaOf`, the
`c_part` delete) writes no `c_want` state; the triggers they fire (`sup_edge_*`, `cl_*`, `twin_*`) touch only the
supply bookkeeping, the change log and `c_twin`/`c_pair_pending`.

**Not real: no door is left unjudged.** But one judged door judges wrongly (R1).

### R1 (real, should fix): the owner's Retry is erased before the judgement

`probeWantedSQL` sets `reason = ''` for a file that is not a probable copy, and `probeGiveBack` runs
`judgeGivenBack` after it. Both settle statements that can hold a wanted file spare `reason = 'by the owner'`
(`chatHoldSQL`, `topicHoldSQL`). K17's own requeue keeps the reason until its judgement for exactly this reason
(`asideBackSQL`'s `?2`, then `asideClearSQL`); C23's door does not.

How a file gets there: it is set aside for its frame judge (`ProbeFetched`, phase judge); the owner presses Retry on the
Queue page (`handleRetry`: `Transition(aside → wanted, ReasonOwner)`, `released` stays 0); the owner switches its chat
off or un-chooses its topic; the settle spares it (wanted, "by the owner"); the judge's word arrives while it is still
wanted (`free()` takes a wanted file).

**Probe `TestZZProbeOwnerRetryJudged`** (both changes, verdicts no match and final), with a waiting twin the owner
sent back the same way: after the change both are wanted with "by the owner"; after the verdict the probed file is
**held** ("this chat does not collect this kind of file" / "this chat collects only chosen topics"), fate held, while
its twin stays wanted. On 86ebd1d0 (overlay `ov-old.json`) the same probe passes: the file stays wanted. So C23 makes
it worse; the reason was already lost before C23, but nothing held the file.

Bounded: it needs the owner's Retry on a file waiting for its judge, a chat or topic switched off before the judge
answers, and no claim in between. The file is held, not lost: the owner can release it. Fix: keep `ReasonOwner` in
`probeWantedSQL` (for example `reason = CASE WHEN probable = 1 THEN heldReasonSQL WHEN reason = 'by the owner' THEN
reason ELSE '' END`), which also ends the earlier loss of the reason; the probe then passes.

## 2. The read before, the judgement after

- **Can the write change what the read says?** Not real. `giveBackReadSQL` reads `attachment`, `message`, `chat`,
  `topic` and `tg_media`; every write between the read and `judgeGivenBack` is to `c_want`, `copy_edge`, `c_part`,
  `c_check*`, `c_pair_pending`, and no trigger on those writes any of the five tables read (I listed every
  `CREATE TRIGGER` on `c_want`, `copy_edge`, `c_probe`). `pairHandBack`, between them in `HoldExact`, writes `c_want`
  and edges only.
- **`keep_held`:** not moved: the two statements on a held file require `keep_held = 0`, the two on a wanted file
  require `state = 'wanted'` (a kept file is held). `pairHandBack` returns early on it too.
- **Released:** not moved: both holds of a wanted file require `released = 0`; a released file is never held probable.
- **Fetched for real:** `chatHoldSQL` spares it, `topicHoldSQL` does not. That is the settle's own rule (the waiting
  twin is held the same way: the coder's "HoldLookAlike, fetched for real" case), so the door agrees with the settle.
  Not real for C23; see R2 for one consequence.
- **Waiting behind a better copy (`ReasonTwin`, `c_twin`):** such a file is held with `probable = 0` and is never
  active or aside (twin.go: "A file in transfer or set aside is never made to wait"), so no door here reaches it, and
  the four statements do not touch a held file that is not probable. When a door holds a better copy, the
  `twin_stop_au` trigger sends the files waiting behind it to `c_pair_pending`, as for the settle. Not real.
- **An alternative version:** a file carried only as an alternative is left wanted (`collectedSQL` and
  `mainCarriedSQL` take main carriers only), K17's known open item (`TestGiveBackRoleKnownOpen`), unchanged. Not real.
- **The owner's Retry:** real, R1.

## 3. `FateHeld` where the doors answered unchecked, wanted or fetch

- **The Supply** (`supply/probe.go`): `ProbeOverdue` goes through `probeSettle` (`probeHand` on `FateUnchecked`
  only, `probePass` otherwise). A judged file now answers `FateHeld` → passed over, not handed. Before C23 the same
  file answered unchecked while still wanted, so nothing could hand a held file. `uncheckedNow` uses `ProbeUnchecked`,
  which changes no `c_want` row. The bad-plan `ProbeVerdict` call ignores the fate (`probePass`).
- **The engine:** the doors are not reached from it with a fate.
- **The judge** (`probejudge/turn.go`): it counts late and left only, and removes the kept parts for a copy verdict
  answered `FateHeld` with no why. For no match, partly, more parts and final it does nothing with the fate. See R2.
- **Lost from both lanes and the door:** not real. A judged file is held as not collected (or a probable copy not
  supplied), which the settle brings back when the chat or topic is on again (`wantedAsMain`; for the frames' copy
  since C23's list change, shown by `TestGiveBackC23FramesHeldNotStranded`). Its open probe row (more parts) is closed
  as left by `ProbeCloseLeft`, as for a waiting file the settle held.

### R2

Real, note. **Probe `TestZZProbeFetchRealCopyFate`:** a video the owner set to be fetched for real, claimed for its
probe turn, the change made, then the verdict "copy". With the chat switched off it stays wanted (`chatHoldSQL` spares
`fetch_real`), fate wanted, as before. With its topic un-chosen the topic rule holds it (as it holds its waiting twin:
the settle's own rule), and the door now answers `FateHeld` with no why; on 86ebd1d0 it answered wanted. `turn.go`
removes the kept parts for exactly "copy, held, no why", a branch meant for a file the frames held as a copy; here the
file has no edge, its parts were kept for the download the owner asked for, and they are thrown away (`parts.Store.
Remove`: rows and files together, so nothing is left inconsistent). If the topic is chosen again the file downloads in
full and those few parts are fetched twice. Bounded (fetch for real, a forum's topic un-chosen during one probe turn);
bytes only, nothing lost or wrongly held. Cure if wanted: give that answer a why (or answer the copy branch's own
"wanted" fate separately) so `turn.go` keeps the parts.

## 4. `heldReasonSQL`'s new branch

Not real. Every probable edge's evidence, by its writer: rung 4 "same post (", rung 6 `lookAlikeEvidenceOf`
"same length, shape and preview (", the exact check `EvidenceExactProbable`, the at-save hold (rung 6's text), the
bring-in "video fingerprints: the same footage (old app)" (`bringin/run.go`), and `AddCopyEvidence`, which only
appends "; ..." after the first text. The owner's words write no edge. None begins with "sampled frames " (LIKE is
case-blind for ASCII; the prefix has no wildcard). The old app's text "the same footage as a saved video (sampled
frames)" is a reason (`holdRules`), not edge evidence, and begins otherwise.

Order with several probable edges (same post, exact, frames, rung 6): every outcome is in `probableReasonSQL` and
`pairWantSQL`, so the supply and the settle treat them alike; the order only picks the words. Note only: a frames copy
of a saved file to which the file already has rung 6's edge keeps rung 6's evidence (`INSERT OR IGNORE`), so a requeue
gives it `ReasonLookAlike` while the door wrote `ReasonProbeCopy`; harmless.

## 5. `HoldExact`'s "differs" path

Not real. `pairExactNotHeldKey` is bumped once, before any branch; `pairHandBack` counts its own outcome through
`pairCounts`; `judgeGivenBack` counts nothing. A file `pairHandBack` leaves (another probable edge) is held,
`probable = 1`; the judgement then takes `probable` off (`keep_held = 0`), its reason and edge kept: what the settle's
second statement does to a waiting held copy, as `TestGiveBackC23ExactGiveBacks` "another edge left" pins against its
waiting twin. Note only: for a file `pairJudge` makes wanted because it is fetched for real (`noHold`), it counts
"released" and the topic rule may then hold it; this needs the mark set while the check ran (`HoldExact` does not read
`fetch_real` again, which predates C23).

## 6. Cost

`TestZZProbeCostGiveBack`: 100,000 collector rows (70% wanted, plain SQL, the account reaching each), the chat
collecting (the read says "no hold": the common case), 400 doors of each kind timed in one loop each (this PC's clock
moves in steps of about 0.5 ms, so single calls cannot be timed), two runs each on the head and on 86ebd1d0's files:

| | head | 86ebd1d0 |
|---|---|---|
| `LinkSame` give-back (setting off), mean | 355, 512 µs | 470, 481 µs |
| `ProbeVerdict` no match, mean | 412, 591 µs | 414, 412 µs |
| `giveBackRead` alone, inside one transaction (20,000 calls) | 56, 66 µs | 68, 57 µs |

The door totals vary by about ±100 µs between runs (the commit dominates), so the difference is read from the read
itself: **about 55 to 70 µs added per give-back, more than "a few µs"**, about 10 to 15% of one door. It is the same
read every `Release` already pays (K17), it is per check (one per frame verdict or exact check), and at thousands of
checks an hour it is well under a second an hour. Note only.

## 7. The panic inside a `Scan` (the report's point f)

Real, as the report says. In `ix-tools/goroot-1.27.3/src/database/sql/sql.go`, `Rows.Scan` (line 3394) takes
`rs.closemu.RLock()` and releases it with no defer after `scanLocked`; a panic in a `sql.Scanner` (through
`convertAssignRows`, or the driver's `ScanColumn`) leaves it held, and `Rows.close` (line 3491) waits on
`closemu.Lock()` for good, so `Close` never releases the connection; `Row.Scan`'s deferred `r.rows.Close()` (line
3553) the same. `TestDoorPanicInScanHoldsTheConnection` (`internal/probejudge/scanpanic_test.go`) shows it, bounded.
It leaves one goroutine blocked and one in-memory connection held in the test process (on purpose; harmless in a test
binary).

**No code in `internal` scans into a custom `sql.Scanner`:** the only `Scan(any) error` or `Value()` method in the
module is the test's own `panicScanner`. The catalogue scans into plain values and `sql.Null*`, whose `Scan` does not
panic. So the hang is not reachable from the catalogue today; keeping the mark as it is is right. Note.

## 8. The tests

**On 86ebd1d0** (overlay `ov-old.json`, log `rv-old.log`): 35 of the 41 new cases fail, each at its assertion line,
not in a setup (`giveback_c23_test.go` lines 230, 253, 265, 281, 370, 438, 451, 470); the 6 that pass are the ones the
report names (two K17 pins per change, "chat off / LinkSame, fetched for real", "chat off / HoldLookAlike, fetched for
real"). So each fails for the reason it names.

**One line undone each** (the rest of the head as it is):

| Mutation | Test | Result |
|---|---|---|
| `ov-m1`: `ReasonProbeCopy` out of `probableReasonSQL` only (`ladder.go`) | `TestGiveBackC23FramesHeldNotStranded` | fails, both "chat off and on" cases ("want a probable copy, supplied"); the two "chat off, then" cases still pass (they rest on `pairWantSQL`'s list) |
| `ov-m2`: the fate line in `probeSettle`'s `wanted` (`judgedHeld` ignored) | `TestGiveBackC23ProbeDoors` | fails, 8 cases ("the fate ... want held"): partly, no match, more parts, final, both changes |
| `ov-m3`: the new `WHEN` out of `heldReasonSQL` (`state.go`) | `TestGiveBackC23FramesHeldReasonBack` | fails ("want held with the frames' reason") |

The tests catch a defect undone in one place. Not real. No test pins R1 (the owner's Retry) or the cost.

## The line

may be listed after these fixes: R1 (keep `ReasonOwner` through `probeWantedSQL`, so the verdict doors spare the owner's Retry as the settle does, with `TestZZProbeOwnerRetryJudged` or its like as a test); R2, N1 and N2 are notes.
