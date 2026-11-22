# Review C37: the held tier's order, likely distinct first

Independent review of head c596fa03 (`wip/copies-42`, base 9cb4edc9), in the detached copy
`wt-copies-review42-scratch`. Brief: `BRIEF-C37-held-order.md`. 2026-11-22. Invented data only; nothing ran
against Telegram; nothing tracked was edited or committed. Every go command went through
`runs-copies-r37/go1.sh` (logs there), named tests only.

Probes (uncommitted, in the copy's `archiver/internal/catalog`):
- `zz_probe_c37_common_test.go`: compiles on the head and on 9cb4edc9 (the base built with `go test -overlay`
  replacing `catalog.go` and `unl_test.go` with 9cb4edc9's and removing `schema_heldclass.go`,
  `heldclass_test.go` and the head-only probe). `TestZZC37Diff` (a deterministic run of 260 doors, 4 seeds,
  dumped), `TestZZC37Cost` (the API's hot paths at 100,000 collector rows and 100,000 probable edges).
- `zz_probe_c37_head_test.go`: head only. `TestZZC37ExactOnMarked`, `TestZZC37Micro` (each trigger-firing
  statement 1,000 times in a rolled-back transaction, with and without the C37 triggers, alternating, same
  rows), `TestZZC37CostSplit` (plans), `TestZZC37FillCut`. On the head `TestZZC37Diff` also runs
  `heldClassDrift` (c_supply = its view both ways, every class = `heldClassSQL`) after every door.

## 1. State or another tier's order changed? Class 1's key the head's? NOT REAL

Probe: `TestZZC37Diff`, 4 seeds x 260 doors on both trees (look-alike posts held or marked, unique posts,
claim and save, a marked file's exact check (three places or "different"), frame verdicts no match / copy /
partly, the owner's same / different / cleared, the owner's release, size and length changes of held and
saved files, probable edges added and removed, `WantAgain` of a saved base, a bring-in's `HoldProbable` with
`AddCopyEvidence`, claim and give back, `Settle`). The dumps were compared line by line:
- every `c_want` column but `held_class` (state, reason, probable, keep_held, check_first, released, ...),
  every edge, every `c_probe` row, the log of each door's result and error: identical on both trees;
- every `c_supply` row of tiers other than 5, whole, and tier 5's rows without k3: identical;
- `LaneNext` over both size classes: the sequence of every non-tier-5 file identical, the set of tier-5
  files handed out identical;
- tier 5's k3: head minus base = 0 for every class-1 row, -8 for every class-0 row, +8 for every class-2 row
  (75 rows of the three classes over the 4 seeds). Bands are 0..4, so the classes never interleave.
Readers of k3 (`lane.go` walks, `laneTierBackSQL`, `state.go`'s `laneLess`) only order by it; negatives are
fine. No code outside the view reads `held_class`. Severity: none.

## 2. COST on the hot paths: REAL, must fix (the held attach)

`TestZZC37Micro` (precise; median of 3 alternating blocks of 1,000, us per call, world of 100,000 collector
rows with 40,000 held, 100,000 probable edges, 20,000 saved media, 15,000 settled frame checks):

| statement a door runs | with C37 | without | added |
|---|---|---|---|
| attach, wanted: INSERT c_want + c_reach | 53.3 | 52.6 | +0.7 |
| **attach, held by rung 6: INSERT c_want (held) + c_reach + probable edge (other size)** | 105.7 | 62.1 | **+43.6** |
| claim: UPDATE c_want wanted to active | 35.7 | 33.0 | +2.7 (noise) |
| save: DELETE c_want + UPDATE tg_media.file_id (no edge) | 163.0 | 161.8 | +1.2 |
| save: UPDATE tg_media.file_id alone | 107.3 | 99.4 | +7.9 |
| release: UPDATE c_want held to wanted | 76.6 | 74.5 | +2.0 |
| frame verdict: UPDATE c_probe to done nomatch (class to 0) | 48.9 | 10.2 | +38.7 |
| AddCopyEdge: INSERT OR IGNORE probable edge (held file) | 30.8 | 11.2 | +19.6 |
| tg_media length update, a saved file with ~5 probable edges to it | 86.4 | 6.7 | +79.7 |
| tg_media size update, a held file | 70.9 | 51.6 | +19.3 |
| tg_media size update, a wanted file with no edge | 75.2 | 63.8 | +11.3 |

End to end through the API (`TestZZC37Cost`, toggle-free, prepared statements, 10 rounds, head vs base, run
twice each; Windows' clock is coarse so batches are timed): the same picture inside +-50 us of noise: held
attach about 1.10 ms (+14 and +140 us in the two pairs), wanted attach +28/+57, claim -21/+27, save +4/+37,
give back -33/-38, verdict +21/+24, the saved file's length update +102/+89 us.

- **Must fix: the held attach (rung 6) costs +43.6 us** (the caller's bound is about 20 us). Where it goes:
  `hc_edge_ai` works the class out (about 20 us: the AddCopyEdge row, where the class mostly does not move)
  and, as the class moves from 1 to 0 or 2, `sup_want_hc_au` rewrites the file's lane rows a second time
  (`refreshSupply`: DELETE and INSERT from the whole view, about 24 us), right after `sup_want_ai` wrote them.
  Suggested: in `sup_want_hc_au`, move the tier-5 row in place,
  `UPDATE c_supply SET k3 = k3 + 8 * (NEW.held_class - OLD.held_class) WHERE tg_media_id = NEW.tg_media_id AND tier = 5`
  (c_supply has no UPDATE trigger; `lc_supply_*` watch tiers 2 and 3 only), and measure again; if the
  class's own 20 us still puts it over, compute it with fewer seeks (the edge rows are read up to five times).
- Claim, save and release: not real (within noise, under 8 us).
- Should fix: the frame verdict +38.7 us (same second rewrite); `hc_probe_au` fires on every phase change
  (fetch to judge too) and works the same file out twice (OLD and NEW id are the same): guard it to rows
  where OLD or NEW is 'done' and run one `heldClassSet` when the id did not change (likewise `hc_edge_au`,
  `hc_word_au`).
- Note: a saved file's size, length or bytes changing costs about 16 us per probable edge naming it (+80 us
  at 5 edges): rare except at a save that held files point at; `hc_media_au` also costs 11 us on a file with
  no edge and no collector row (a WHEN on c_want or an edge would skip it).

## 3. Is the class right in every case? Stale after a door? REAL, must fix (one case)

- **Must fix: the exact check's three places on a marked look-alike are not class 2.** Probe
  `TestZZC37ExactOnMarked`: a same-size look-alike (rung 6 leaves it wanted, `check_first`, with rung 6's
  probable edge to the saved file), claimed, then `HoldExact` with three places matching that saved file
  (the path `supply/pending.go` takes for a marked file whose check says probable). Result: held,
  reason "Telegram's hashes at three places match a saved file", but **class 1 with an equal length and
  class 0 when the length differs by 200 ms**: a confirmed copy goes FIRST in tier 5. Cause: `HoldExact`
  writes its edge with `AddCopyEdge`, which is `INSERT OR IGNORE`; the pair already has rung 6's edge, so
  the evidence stays rung 6's and `heldClassSQL` never sees `EvidenceExactProbable`. The report's own case
  ("a same post's edge keeps its own evidence beside the verdict") was handled for the frames' copy
  (`c_probe.of_file`) but not for the exact check. Suggested: read the exact check's record, e.g. a branch of
  class 2 `EXISTS (SELECT 1 FROM c_check k CROSS JOIN copy_edge e ... CROSS JOIN tg_media o ON o.id = e.b
  WHERE k.tg_media_id = media AND k.outcome = 'probable' AND e.a = media AND e.relation = 'probable'
  AND o.file_id = k.file_id)`, with triggers on `c_check`, and add this case to `TestHeldClassDoors`.
- Staleness: NOT REAL. `TestZZC37Diff` on the head checks after every one of 1,040 doors that every class
  equals `heldClassSQL` and that `c_supply` equals its view both ways (`sup_want_hc_au` included): edges
  added (`AddCopyEdge`, `AddCopyEvidence`) and removed, frame verdicts, the owner's same / different /
  cleared, size and length changes of held and saved files, `WantAgain` (a lost saved file, 7 times),
  `HoldProbable`, releases, saves, give-backs, `Settle`: zero drift.
- Should fix: the exact check's "hashes differ" at the same size (`HoldLookAlike`, `ReasonLookAlikeDifferent`)
  is not read (the report says so); such a file is class 1, behind the size-differing look-alikes.
- Note: by the brief's definition almost every rung-6 hold is class 0 (a same-size look-alike goes to the
  exact check first, so the held ones differ in size), and a length different by 1 ms counts as different;
  the record's finer order ("no match" before look-alike; within each, size different before equal) is
  folded into one class 0. As the brief bound it; for the copies session to judge.
- Note (not probed): the owner's "same" is read only on the exact media pair of an edge, not on another
  media of the same bytes.

## 4. The step and its chunked fill: NOT REAL

- The fill runs inside `Open` (`migrate`), so the collector gets no handle, and walks no lane, before it ends.
  Another read-write `Open` meanwhile takes the same fill (the marker is read again inside each chunk's
  transaction; `_txlock=immediate` serialises them).
- Probe `TestZZC37FillCut` (30,000 collector rows, chunks of 5,000): at each chunk's commit, read through a
  second connection: `c_supply` equals its view both ways, the held count unchanged (22,500); after a cut at
  the second chunk (a panic at the hook) the file is at the new version with the marker at 10,000; the next
  `Open` resumed, dropped the marker, and every class and lane row was right (0: 15,000, 1: 5,000,
  2: 10,000). A half-filled class is class 1, the head's key: only an order difference. (The test's one
  failure is the temp folder's cleanup, held by the deliberately abandoned handle.)

## 5. C28, C26/C22's twin triggers, K20's unl, K24's parked files: NOT REAL

- C28 (`wip/copies-33`): counts only (`c_album_like`); no edge, no collector row written; no trigger on the
  class's tables.
- C22/C26 twins: held with probable = 0 (never tier 5); their triggers write `c_twin` and `c_pair_pending`
  only.
- K20: the view keeps `unl`; the walks per unl are unchanged (question 1's lane comparison).
- K24 parked files: parking keeps probable (a wanted file becomes held with probable 0: not tier 5); the class
  is kept for every state, so a revived file (`bi_reach_ai`) lands with a current class.
- None of the queued branches (`int/join22`, `wip/core-react`, `wip/copies-33`, `-39`, `-41`,
  `wip/b-chatgroups`, `wip/client-chat`) rebuilds `c_supply_src` or adds a trigger on `c_want`, `copy_edge`,
  `c_probe`, `c_pair_word` or `tg_media`.
- Merge note: the UI batch has 37 and 38, C28 39, then A1-A3; K30's reactions also follow K20. C37's
  `heldClassAfter` moves at the merge, and any later step that rebuilds the view must start from
  `supplySrcHeldClassSQL`. `int/join22` edits the same two lines of `unl_test.go` (a trivial conflict).

## Findings

1. Must fix: the held attach (rung 6) costs +43.6 us (the class, then the lane rows rewritten a second time).
2. Must fix: the exact check's three places on a marked look-alike is class 1 or 0, not 2 (the edge's
   evidence stays rung 6's): a confirmed copy can go first.
3. Should fix: the frame verdict +38.7 us; `hc_probe_au` on every phase change and the double work of the
   `*_au` triggers.
4. Should fix: "hashes differ" at the same size not read (class 1).
5. Note: a saved file's size, length or bytes change costs about 16 us per edge naming it; 11 us on a file
   with no edge.
6. Note: almost every rung-6 hold is class 0 by the brief's rule; the record's finer order is folded.
7. Note: the step number moves at the merge; later view rebuilds start from `supplySrcHeldClassSQL`.

may be listed after these fixes: 1 (the held attach under about 20 us, measured again at 100,000 rows) and
2 (the exact check's three places as class 2, with a test of the marked look-alike).

## Second pass: the fix round (head f5ce3930)

Diff c596fa03..f5ce3930 (`ladder.go`, `schema_heldclass.go`, `exactcheck_test.go`, tests, the report),
checked out detached in the scratch copy. The base for the differential is 9cb4edc9 through the overlay,
which now also replaces `ladder.go` and `exactcheck_test.go`. The coordinator accepted the held attach's
+16 to +29 us, so it was not measured again.

### (1) The edge before the collector row; `sup_want_ai` rebuilt: NOT REAL

- Code: in `attach` the two statements only swap places. Everything that decides happens before both and is
  unchanged: rung 4 and rung 6, check-first (`sameSizeSaved`), the park decision, and the "would hold" count
  (`countWouldHoldOf`, which reads unsaved look-alikes and writes `c_settings` before either insert). The twin
  rule (`twinAtAttach`) still runs after both.
- The insert triggers: on `copy_edge`, only `sup_edge_ai` (related edges only) and `hc_edge_ai` (needs the row,
  so now skipped at the attach). On `c_want`, the only body that reads edges is `sup_want_ai_derive`'s `partly`,
  which reads related edges with partly set, never probable ones. `bi_want_ai` (parking) and `unl_want_ai` read
  reach and chats. The rebuilt `sup_want_ai` keeps schema4's insert as its last statement, and no step between
  4 and 37 redefines it. If another insert trigger writes the lane rows first, `sup_want_hc_au` moves them in
  place.
- CatalogueMessage runs in one Batch, so a failed row insert takes its edge with it.
- Probe: `TestZZC37Diff`, the same 4 seeds x 260 doors, plus 4 new seeds (5 to 8) on an extended world:
  - the lesser copies' wait on;
  - the ranked chat in unlimited hours, and `SetChatDownloadWhen` switching back and forth;
  - a brought-in account with its own chat;
  - saved same-post origins.
- Doors hit in seeds 5 to 8:
  - 48 rung-4 same-post holds;
  - 33 parked posts and 21 parked rung-6 look-alikes;
  - 29 revivals by the live account (`bi_reach_ai`);
  - 8 twin holds, beside 9 rung-6 holds through the twin door.
- Result on all 8 seeds against 9cb4edc9: every `c_want` column but `held_class` identical, every edge and
  frame check identical, every door's result and error identical.
- Every lane row outside tier 5 is identical, as are tier 5's rows without k3, the lane sequences outside
  tier 5 and the tier-5 set. Tier 5's k3 moved by exactly -8, 0 or +8 for class 0, 1 or 2.
- On the head, after every door: zero drift (each class equals `heldClassSQL`; c_supply equals its view both
  ways).

### (2) The `c_check` reading: NOT REAL (fixed)

- `TestZZC37ExactOnMarked` (the first pass's failing probe) now passes. Three places on a marked look-alike give
  class 2, at an equal length (was 1) and at a 200 ms longer one (was 0).
- `TestZZC37HashesDiffer`: "hashes differ" (`HoldLookAlike`, c_check 'different') gives class 0 at an equal and
  at a different length. "Undecided" ('unknown') gives 1 at an equal length and 0 at a different one, which is
  right: an undecided check is not evidence.
- Deleting the c_check record by direct SQL returns the class to what its edges say (1, or 0 where the length
  differs), with no drift.
- No stale class: the 8-seed run takes 29 or more check-first holds and give-backs through `HoldExact` and
  `HoldLookAlike`, and checks the drift after each.

### (3) `TestMigrateV10ToV11`: NOT REAL

- The test passes and still checks what it meant:
  - the v11 objects are made;
  - the hold on record is kept;
  - the `checks` hold is taken;
  - the new column is filled;
  - a relabelled full file migrates.
- The new setup drops the triggers that read c_check (21 of them: the class's triggers and the rebuilt
  `sup_want_ai`) and puts back v10's `sup_want_ai`. That makes the faked v10 file closer to a real one,
  following the pattern it already used for `bi_reach_ai`.
- Probe `TestZZC37MigrateV10Triggers` (the same setup): after the migration, the 27 class and lane triggers are
  identical, name and text, to a fresh file's, and a post on the migrated file has no drift.

### (4) Anything new opened: NOT REAL (one note)

- Note, merge only: a later step that rebuilds `sup_want_ai` must keep its class statement; any later view
  rebuild starts from `supplySrcHeldClassSQL`. The report says both.

may be listed as it is
