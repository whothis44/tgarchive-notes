# Review E27 (the queue's "C22"): lesser copies wait behind the best

One independent reviewer (Opus 5.5), 11-16, 19:15 to 19:30 by `date`. Head reviewed: `7c5161e2` on
`wip/copies-27`, against `78739d59...7c5161e2 -- archiver`. Nothing on any branch was changed. Probes are
`zz_probe_*_test.go` in the frozen copy `wt-copies-review27-scratch` only (never committed); the off-is-head
probe was also placed in a second frozen copy `wt-copies-review27-base` at 78739d59. Logs and the runner:
`runs-copies-review27\` (`go1.sh`, `p1.log` to `p7.log`, `dump-*.txt`). Invented data only; nothing under
`E:\T`, no real catalogue, nothing against Telegram. One go command at a time under `runs-copies-golock`,
`GOMAXPROCS=2 GOMEMLIMIT=1GiB GOFLAGS=-p=1`, free memory 8.3 to 8.6 GB before each; named tests only.

## Findings

### 1. HIGH: a file waits for good behind a better copy that no live account can reach (suspect 1: real)

The rule calls a candidate "coming" by its `c_want.state` alone. An account removed (`RemoveAccount`: only
`removed_at`, its `c_reach` rows stay) or deleted (`DeleteAccount`: its `c_reach` rows go, the better copy's
row stays `wanted`) leaves the better copy wanted and unclaimable; no trigger fires (no `c_want` row moves),
so the lesser copy, reachable by the live account, waits behind it for good. On the head it is downloaded.

Probe `TestZZProbeReachGone` (zz_probe_reach_test.go), both ways: before, best `wanted` reach 1, low waiting
reach 1; after `RemoveAccount` and after `DeleteAccount` plus 50 settles and the door drained: best `wanted`,
live reach 0, `Claim` by the live account false; low still waiting, `c_supply` rows 0. The random worlds
(below) never removed an account, so they did not see it.

Smallest fix I would accept: "coming" also asks a `c_reach` row of an account with `removed_at IS NULL`
(in `twinRowSQL` / `twinRule`, so the rule never makes a file wait behind such a file), and two triggers in
`schema_twin.go` that write the followers to `c_pair_pending` (`twin = 1`): `AFTER DELETE ON c_reach` when the
media has no live reach left, and `AFTER UPDATE OF removed_at ON account` for the followers of files whose
live reach is now none. A test of each.

Related, not a finding of its own (design, for the session): the rank guard looks at `best_rank` only; a
file may also wait behind a file of a lane that comes much later (another account's lane, a server under a
long wait, `wanted_first` on the not-saved list against a file without it). Finding 1 is the case where
that lane never comes.

### 2. HIGH: a stale `twin = 1` pending row strands a file the head's door would have judged

When the better copy stops coming, T2 writes the follower with `twin = 1`. If, before the door runs, another
door moves that file off waiting and it later becomes a lost look-alike that `lostLookAlike` puts on its
rest list (`INSERT OR IGNORE`: the row keeps `twin = 1`; `probable` set to 0), the door sends it to
`twinPendingJudge`, which finds it "no longer waiting" and leaves it ("elsewhere"). It is then held, not
probable, with no edge, no wait and nothing pending: never supplied and never judged again.

Probe `TestZZProbeStaleTwinRow` (zz_probe_pending_test.go; `lostSettleMax = 0` stands for the 200 and
`judgeBudget` overflow): the better copy saved (x pending `twin=1`); the bring-in's `HoldProbable` on x and
`AddCopyEvidence` to a saved s (x held probable, 1 edge, c_twin 0, still `twin=1`); `WantAgain` of s's file
(x held, `probable` 0, 0 edges, still `twin=1`); after the door: x held `probable copy (old app)...`,
`probable` 0, 0 edges, 0 supplied, twin counts `Elsewhere 1`, `lost_pending` 0 to 1 and
`lost_pending_judged` 0. Printed: `STRANDED`. The same file on the head's door
(`TestZZProbeStaleTwinRowHeadDoor`, switch off): ends `wanted`, 0 edges. Rare (two doors between a save and
the next drain, or between the switch going off and its 50 chunks), but the state is permanent.

Smallest fix: the pending row's kind follows the file, not the first writer (finding 3 is the other side):
`lostLookAlike`'s and `pairEdgeLost`'s inserts become `INSERT ... ON CONFLICT(tg_media_id) DO UPDATE SET
twin = 0 WHERE NOT EXISTS (SELECT 1 FROM c_twin WHERE tg_media_id = excluded.tg_media_id)`; a test with the
probe's sequence.

### 3. MEDIUM: a waiting file gets a probable edge, and a lost edge then ends its wait as a lost look-alike

`probeSettle`'s "copy" on a file whose state is `held` writes the probable edge and skips
`probeHeldCopySQL` (`if f.state != StateHeld`), so the reason stays `ReasonTwin` and the `c_twin` row stays.
The report's doors row 24 ("held as a probable copy ... T1 removes its c_twin") and `twinPendingJudge`'s
comment ("none of today's doors writes one to a waiting file") are therefore wrong. A waiting file reaches the
judge when it was wanted in phase judge (its set-aside requeued) and then made to wait. The door itself copes
(`mediaNow.probEdge`: held as a probable copy), but when that edge's bytes are lost and the file lands on
`lostLookAlike`'s rest list, a `twin = 0` row sits on a file that still waits; the door judges it as a lost
look-alike and makes it wanted while its better copy is still wanted: both are downloaded, and the lost
counts move for a waiting file (suspect 2's other direction).

Probe `TestZZProbeWaitingGetsEdgeThenLost`: x claimed, `ProbeFetched` (aside, phase judge), requeued
(`wanted`), the better copy posted (x waits); `ProbeVerdict` copy: fate held, x still waiting, 1 probable
edge; `WantAgain` of the edge's file: x pending `twin=0` while waiting; after the door: x `wanted`, not
waiting, the better copy `wanted`; `lost_released` 0 to 1, `lost_pending_judged` 0 to 1.

Smallest fix: `SettlePairPending` judges a file by `twinPendingJudge` when it has a `c_twin` row, whatever the
column says (one `EXISTS` beside the `RETURNING`); the doors row 24 and the comment corrected; a test.

### 4. MEDIUM: the writer's time grows with the number of queued look-alikes, with no bound

With the switch on, `twinRule` reads every alike candidate's collector row (`twinRowOf`, one statement each,
about 0.14 ms with `collectedAsMainSQL`), where the head stops at the first counted one; at the door each
waiting file judged wanted weighs all the others again and re-points them, so a group costs the door O(n^2).

Probe `TestZZProbeManyAlike` (zz_probe_cost_test.go), medians of the last 50 attaches:

| alike queued | attach, switch off | attach, switch on | the better copy's end | the door after it |
|---|---|---|---|---|
| 100 | 1.0 ms | 11.1 ms | saved: 2 chunks, longest 102 ms, 118 ms in all | gone: 18 chunks, longest 126 ms, 1.9 s in all, `Pointed` 4,851 |
| 400 | 1.0 ms | 49.3 ms | | gone: 223 chunks, longest 208 ms, 31.4 s in all, `Pointed` 79,401 |
| 1,000 | 1.6 ms | 139.9 ms | saved: `Saved` 173 ms (not separated from the head's own step at save, which reads the same 1,000 rows), door 11 chunks, longest 107 ms, 0.9 s | not run |

A page of messages carries several attaches in one transaction, so a reposted video with hundreds of queued
copies holds the writer for tenths of a second per attach, and the door's chunk overruns `judgeBudget` by one
file's whole weighing (208 ms at 400). Smallest fix: one read of the candidates' rows (a single statement over
the ids, the plain test only on wanted rows, a waiting row's `behind` read before its own facts), and a cap on
the candidates weighed per event (as `lostSettleMax`), the rest left as they are and counted; the figures
again at 400 and 1,000.

### 5. LOW: a chain ends differently by order of arrival

A like B, B like C, A not like C (previews 4 + 4 bits apart). `TestZZProbeOrders` "chain": in 4 of 6 orders
`A wanted, B and C behind A`; in the 2 orders A, C, B and C, A, B: `A wanted, B behind A, C wanted`. When the
new file is not the best, the other plainly wanted members are not made to wait behind the best (only the
new file is). The old app's group (`ixGroupCopies`, transitive) holds C in every order. Fix if wanted: in the
branch best != x, the same loop as the other branch for the plain members (rank guard kept).

### 6. LOW: the rank guard's refusal leaves the new file behind nobody; the result depends on the order

`TestZZProbeOrders` "ranks" (best unranked, mid and low ranked 1): orders where the ranked ones come first end
`low behind mid` (2 of 6); the others end all three wanted (4 of 6). On refusal the rule does not try the best
member the guard allows. "ranks 2" (best ranked) is the same in all 6 orders. Fix if wanted: on refusal,
weigh again without the refused members.

### 7. LOW: counts that count events, not files

At the door with the better copy gone and 100 behind it: `twin_held` 199 and `twin_held_bytes` about twice the
100 files' bytes (a file that waits again is counted again), `twin_judged_wanted` 100 of which 99 then wait
again, `twin_pointed` 4,851 for 99 files. The struct's words ("made to wait", "wanted again") read as files.
Either say "times" in `TwinCounts`' comments and the report, or count a file's first wait only. Also: when
T2's upsert takes over a lost look-alike's row, `lost_pending` has moved and `lost_pending_judged` never will
(suspect 2: the file is judged by the right rule, `twinPendingJudge` does the ladder and rung 6 too).

### 8. LOW: words

- The doors table row 24 and `twinPendingJudge`'s comment (finding 3).
- Section 7 of the report misses `internal/viewer/media.go` and `post.go`: a post's detail carries the stored
  reason as it is (`Reason`, json `reason`): the fixed words; nothing breaks on a held row with no edge
  (`stateOf`, `heldAsCopy` go by the reason's prefix: "held back by the archiver").
- `savedVideoFacts` is used for not-saved files (`twinRule`, `twinRepoint`, `twinPendingJudge`): the read is
  right (it reads `tg_media` whatever `file_id` is: suspect 5 is not real); the name misleads, a comment at
  the calls would do.

## What I tried that held

- **Off is the head** (`TestZZProbeOffHead`, the same file in both copies): 12 seeded worlds of 60 steps
  (arrivals in two chats, claims, saves with repeated bytes, give-backs, the owner's releases, a chat off and
  on, "different" words, door chunks): the dumps of `c_want` (11 columns), `copy_edge`, `c_supply`, the
  `lookalike.`/`pair.`/`exact.` counts, `c_pair_pending` and `tg_media.file_id` are byte-identical on 78739d59
  and on the branch with the switch absent and with "0" (1,146 lines each; 201 held rows, 12 would-hold rows).
- **Random worlds** (`TestZZProbeRandomWorlds`, 300 worlds, 40 to 99 steps; one world in five never turns
  the switch on; `lostSettleMax` 0 to 2): 6,775 arrivals, 3,057 claims, 1,448 saves, 542 give-backs, 245
  set-asides, 645 requeues, 226 gone, 1,029 releases and 598 holds by the owner, 404 kept held, 853 chat
  switches, 787 words, 800 losses, 319 flips of the switch, 2,566 door chunks; 1,564 waits made, 249
  re-points, 795 rank refusals, 478 sent by the switch going off. After every step: no `c_twin` row without
  its file held with `ReasonTwin` and the reverse; no waiting file supplied, claimed, probable, marked or
  kept; no file skipped; gone only by `Gone`; every file waiting behind a file not coming has its pending row.
  After the last drain: none behind a file not coming, none behind a file that waits, none waiting with the
  switch off, none behind a file with no reach row; 0 held copies with no evidence, nothing pending and
  collected, in both kinds of world. No violation.
- **Suspect 3** (`TestZZProbeTwiceInOneTx`): in one transaction active to wanted to held; active to held to
  held with another reason; wanted to held to wanted; active to wanted to active to deleted; a waiting row's
  reason changed twice: after the drain, every invariant above holds (the files behind are pointed or judged
  as the last state says).
- **Suspect 4**: no state reached in which a file waits behind a waiting file once the door has drained (the
  random worlds, and the rule's two branches read); during the window the follower always has its pending
  row. The refusal's narrowness is finding 6.
- **Suspect 6** (`TestZZProbeOrders`): two and three files equal in pixels, whole seconds and bytes: the
  first to arrive (the lower id) is wanted and the others wait behind it in every order (2 of 2, 6 of 6);
  four alike: one outcome in all 24 orders.
- **The "known" path** (`TestZZProbeKnownWaiting`): a waiting file named on a saved list, its better copy
  gone: wanted, supplied, never skipped; `Known` 1 (0 with an always-download carrier): as the report says.
- **Suspect 7, the timings** (`TestTwinTriggerCost`, `CAT9_TWIN=1`, once; the PC's CPU read 100% at the start,
  so noisier than the report's): the claim's statement 46.9 µs with the four triggers against 32.3 µs without
  (rounds 33.1 to 75.3 and 28.9 to 44.9; minima 33.1 and 28.9), a save's delete 16.4 against 10.2 µs (minima
  12.1 and 9.5); two triggers 39.0 / 17.6, folded into the change log 35.6 / 17.6. The report's: 31.8 and
  32.2 against 26.5 and 25.1; 13.3 and 13.7 against 9.8 and 8.9. Same order: a few microseconds a statement.
  `TestTwinSwitchOffCost`: the switch off with 5,000 waiting 5.7 ms (report 6.3 ms); the door after it 50
  chunks, the longest 77.5 ms, 2.53 s in all (report 51, 132 ms, 2.9 s).
- **Files and shape**: the difference touches `catalog.go` (three schema places), `ladder.go` (the count's
  call and one call after the insert: departure 4, declared), `pairword.go`, two new files, tests and the
  report; no goroutine, timer, ticker or log line added; tests' data invented.
- **The step**: a new catalogue and a stepped one run the same steps from 0 (`fileAtVersion`, `migrate`);
  `TestTwinStep` (the coder's) covers refusal and a second run; not repeated.

## What I did NOT check

- The exact check's doors one by one (`LinkSame`, `HoldExact`, `HoldLookAlike`, `HoldCheckFirst`), the
  topic settle, a role change by an edit, a message deleted, a chat removed, the bring-in's `importOne` of a
  better copy, `chosen.go`'s statements beyond `OwnerSetChatCollect`: covered only by the triggers' shape,
  the direct statements of suspect 3 and the random worlds' doors, not called by name.
- The frame check's verdicts other than "copy" on a waiting file (read: they leave a held file held).
- `TestTwinCostAtScale` (a `Claim` and a `Saved` at scale) was not repeated; the scale rig's catalogue was not
  used for my own timings (findings 4 and 7 use small invented catalogues).
- The branch merged onto the moved main head (another schema step is there now); the race detector; the
  whole packages; `go vet`; pages and viewer at run time.
- The coder's 41-row doors table beyond rows 24 and the ones the random worlds drive.

may be listed after these fixes: 1, 2, 3, 4
