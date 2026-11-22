# Review of C32: saved video pairs (a new fingerprint compared with the saved videos of about its length)

Independent review, 2026-11-22. Head 8373f1f2 (diff f0323f5b..8373f1f2), in the detached copy
`wt-copies-review37-scratch`. Invented data only; no Telegram request. Probes: the reviewer's uncommitted
`archiver/internal/catalog/zz_probe_c32_test.go` in that copy. Runs went through `runs-copies-r32/go1.sh`, named tests only
(logs `rv-probe1` to `rv-probe3`): all passed, 11 to 15 s each.

## What ran for real
Nothing. Five probe tests on a temporary catalogue.

## The question: who reads a C32 edge, and can it change a decision?
Every reader of `copy_edge` with `relation = 'probable'` in `internal/catalog` (none in `internal/supply` outside tests)
looks the edge up from a collector row: `e.a = c_want.tg_media_id`, or `e.a = ?` for a queued file. A saved media has
no `c_want` row (`Saved`, the exact check's link and the bring-in all delete it). `c_want` rows are only made by
attach (a new `tg_media`, never saved) and by `WantAgain`. So **while both files stay saved, no rule decides anything
from a C32 edge** (probe `TestZZProbeC32SavedNoRow`: no rows for X or Y). The edge matters from the moment its `a`
side gets a collector row, which happens only when that file's bytes are lost (`WantAgain`).

C32 always writes the edge from the file just fingerprinted to the older candidate, whichever is the better copy.

| Reader | For a file that stays saved | After the `a` file's bytes are lost (`WantAgain`) | Verdict |
|---|---|---|---|
| `WantAgain` facts and `wantRule` (`staging.go` 521, 522; check-first 597) | nothing (no row) | **held** "looks like a saved file", probable = 1, instead of wanted; with `held_wait` on (the default) no lane lists it, so it waits until the owner releases it. Check-first is never taken: the evidence does not start with rung 6's prefix | **real** (F1) |
| The owner's words (`pairword.go`: `pairWantSQL`, `pairEnded`, `pairEdgeLost`, `noProbableEdgeSQL`) | nothing | "different" on the pair removes the edge and makes X wanted again (released 1) | not real: works as for any hold |
| `atSave`'s covered step (`coveredWantSQL`, `atsave.go` 90) | nothing | X is held, not plainly wanted; after the owner's release, `released`/`ReasonOwner` keep it out anyway | not real (probe: 0 rows at every stage) |
| `heldReasonSQL` (`state.go` 289) | nothing | "looks like a saved file" (its ELSE branch) | not real (the words are rung 6's, the evidence says "same footage") |
| Rung 6 and `wantedAsMainSQL`'s `p` (`ladder.go` 1123) | nothing; rung 6 itself reads saved videos by preview hash, not edges | a held X stays a probable copy when collected again | not real beyond F1 |
| The twin rule (`twinPlainSQL`, `twin.go` 400) | nothing | X is held, so it is never "plainly wanted" | not real (probe: 0 rows) |
| The frame check's held-of (`lookAlikeFileSQL`, `probe.go` 1571; `VideoCandidatesOf`'s first) | nothing | Y comes first, the right file. A held X can now be probed from Telegram when `copies.probe_held` is on | not real (folded into F1's wording) |
| `lostLookAlike` (`pairword.go` 943) when the **candidate** Y is lost | removes the C32 edge X to Y for good; past `lostSettleMax`, writes the saved X into `c_pair_pending` and counts it in `lookalike.lost_pending` | (Y is wanted) | note (F3) |
| `related`: `partlySQL` and `sup_edge_ai` (partly = 1 only), stats, topics, chat reads (exact only) | nothing: C32's related edges are partly 0 | nothing | not real |
| The viewer (read-only) | "same" edges fold two saved videos into one appearance (setting `sameProb`), add review pairs; past 20 probable edges a file goes "wide" | the same | note (F5) |
| `CountsKey` (`chatreads.go` 165) | each written edge moves `MAX(rowid)`, so the counts are worked out again at the next ask | the same | note (cost) |

### Proof of F1 (`TestZZProbeC32WantAgainHeld`)
Three saved videos of 60 s: X (1920x1080, 90 MB), Y (640x360, 0.4 MB), Z (as X, no edge). The door writes X to Y
"same footage (85% of both)". Then the bytes of X and of Z are lost:
- `WantAgain(X)`: Media 1, Wanted 0, Held 1, HeldProbable 1. X is `held / "looks like a saved file" / probable`.
- `WantAgain(Z)`: Wanted 1. Z is `wanted`.
- `held_wait = true`; `NextWanted` lists [Z] only: X is never supplied without the owner.
- The frame check's held-of for X is Y's file; the owner's "different" on X, Y removes the edge and releases X.

So the 1080p copy the owner had downloaded waits for good behind a saved 360p one. Rung 6 never does this: it holds
a video only behind a saved one that covers it (`lookalike.Covers`: no more pixels, no more than ten ninths of the
bytes). Whether a held probable copy is the right outcome at all: yes, it IS a probable copy of a saved video, and the
rules say a probable copy is held, never skipped. The wrong part is the arbitrary direction. The bring-in already
carries the old app's "same" pairs the same way (key order, `run.go` videoMatch), so this is not new in kind. C32
makes it apply to every new pair.

## (2) Is an edge ever written to a media that is not saved, an exact edge, or against the owner?
- **Not saved: never.** Both ends are `MIN(tg_media.id)` of a file whose `location` is library or staging, read in
  the door's own transaction (`TestPutSavedVideoPair` covers lost bytes and no file).
- **Exact: never.** The vfp side passes only probable or related. The door refuses anything else
  (`ErrBadSavedPair`). An exact edge between any media of the two files makes the door answer "known".
- **Against the owner: not at the time it is written.** `not_copy` and `c_pair_word = 'different'` are checked on
  any media of either file, both ways. Two gaps, in F4: the viewer's verdicts reach `c_pair_word` only through the
  pair-words reader (when `-pair-words` is set); and a `related` edge written before the word arrives is never removed
  (`pairEnded` removes probable edges only). The viewer still honours its own verdict.
- No trigger fires on the insert (partly 0; the only insert trigger is for partly 1). `c_want`, `c_supply` and
  `tg_media` do not move.

## (3) The bound and the cost per file
- Candidates: one `VideoCandidates(length, 0, 301)`. That is two walks of at most 602 index entries each, plus a file
  seek per entry, then one statement that reads the frames of at most 301 fingerprints. Rows are 1 to 36 KB, so up
  to about 11 MB for hour-long videos, much less for short ones.
- Comparing: at most 300 `footage.Compare` calls, measured by the coder at 6 us (30 s) to 5.8 ms (60 min) each.
  That is at most about 1.7 s.
- Writes: at most one door transaction per match. Probe `TestZZProbeC32DoorCost`, temporary catalogue: 300 writes
  took 145 ms (0.48 ms each); 300 refusals took 76 ms (0.25 ms each).
- `PairsTime` (5 s, the read included) is checked before each pair. A stop ends it at the next pair.
- On Run's goroutine: the file just fingerprinted is let go first, but the next read waits. So the line's other held
  staged copies (`Holds`) wait up to 5 s more per compared file. "The copy never waits" is true for that one file
  only. Small next to an ffmpeg read; a note.
- The 20% band misses most clips and any overlap across lengths. The report says so and prices it.

## Findings
- **F1, should fix: a C32 "same" edge holds a lost file behind a worse copy.** If the `a` file's bytes are lost,
  `WantAgain` brings it back held (probable, under `held_wait` for good) instead of wanted. The `a` side is whichever
  file was fingerprinted last, so a 1080p original can wait behind a saved 360p copy. Proven above. Fix: write the
  probable edge from the lesser file to the better one, by `lookalike.Better`'s order (pixels, whole seconds, bytes,
  the lower id). Then a lost lesser copy is held behind a better saved one, and a lost better one comes back wanted
  (its edge is the one `lostLookAlike` removes), as rung 6 and the covered step decide. Related edges need no
  direction. Optional: let `wantAgainCheckFirst` take the C32 evidence too, so a lost copy with a saved file of its
  exact size is checked by Telegram's hashes before it is held.
- **F2, should fix: the report and the lean-rule claim are wrong.** "Nothing held, skipped or released; no review by
  the lean rule" holds only while both files stay saved. The report must say that a C32 "same" edge decides
  `WantAgain`'s outcome for a lost file. It must also say that such a held file can then be probed from Telegram (the
  frame check of held copies, when `copies.probe_held` is on).
- **F3, note: a lost candidate erases the pair.** `lostLookAlike` deletes every probable edge to the lost media, C32's
  between two saved files included, and nothing compares them again (a fingerprint is compared once, when stored).
  Past `lostSettleMax` (200) the saved `a` media is written to `c_pair_pending` and counted in
  `lookalike.lost_pending` (probe: 1 row, count 1). The settle then drops it as "no row". The bring-in's edges already
  do the same.
- **F4, note: related edges outlive the owner's word.** A related edge written before the owner's "different"
  reaches `c_pair_word` stays after it, because `pairEnded` removes probable edges only, though the door would refuse
  it now. It decides nothing (partly 0); only the viewer and the queue page show it.
- **F5, note: the viewer folds more.** With `sameProb`, "same" edges fold two saved videos into one appearance and add
  pairs to the review page. A file with more than 20 probable edges goes "wide", which stops folding through it and
  can split groups folded before. Read-only; expected of ix_vdup, worth one line in the report.
- **F6, note: the cost is bounded and small.** It is as given in (3). The line's other held copies wait up to
  `PairsTime` more per compared file, and every edge written makes the chat counts be worked out again at the next ask.

may be listed after these fixes: F1 (direct the probable edge from the lesser to the better file by `lookalike.Better`,
with a test that a lost better copy comes back wanted and a lost lesser one held) and F2 (the report says what a C32
edge decides once bytes are lost)

## Second pass: the fix, head 80ef29fe (diff 8373f1f2..80ef29fe)
A narrow pass over the fix only. 80ef29fe was checked out detached in the scratch copy. Probes are in the
reviewer's uncommitted `archiver/internal/catalog/zz_probe_c32b_test.go`, with the first pass's
`zz_probe_c32_test.go` run again. Runs went through `runs-copies-r32/go1.sh` (logs `rv2-probe1`, `rv2-named`). The
fix's named tests (`TestPutSavedVideoPair|TestSavedPair|TestPairs|TestWorkerReport`, catalog and vfp) pass. The first
pass's two probes that expected X to be held now fail, as they should: X comes back wanted.

The change: for a "same" match, `PutSavedVideoPair` reads both media's facts (`pairFacts`: length, pixels, bytes,
id; the date left 0). It picks the better copy by `lookalike.Better`. It writes the probable edge from the lesser copy
to the better one only when `lookalike.Covers(better, lesser)`; otherwise it writes a related edge (counted
`same_related`).

1. **The direction: fixed (probe `TestZZProbeC32bDirection`).** 1080p/360p, with either file fingerprinted last,
   always gives the edge 360p to 1080p, probable. With equal facts, either order gives the edge from media 2 to
   media 1, so the tie makes the lower id the better copy. All columns read are `NOT NULL`, so the scan cannot fail
   on a NULL.
2. **Neither covers: related, deciding nothing (probe `TestZZProbeC32bWantAgain`).** 1080p at 1 MB against 360p at
   9 MB: the door answers "written as related". Each side's loss brings it back wanted and listed by the lanes. A
   related edge with partly 0 fires no trigger and no rule reads it.
3. **WantAgain both ways: fixed (same probe).** Lost 1080p: wanted, listed by the lanes, and its edge is removed by
   `lostLookAlike`. Lost 360p: held, "looks like a saved file", probable, and not listed under `held_wait`. That is
   rung 6's outcome.
4. **Anything new opened: two notes, nothing to fix.**
   - **N1. A covering the code does not write.** `Better` ranks first by pixels, then whole seconds, then bytes;
     `Covers` asks only pixels and bytes. So with equal pixels, a copy longer by a whole second but under 90% of the
     other's bytes is "better", yet only the other covers it. The door then writes related, and its word "neither copy
     covers the other" is not exact for this case. Probe: A 61 s at 5 MB, B 60 s at 9 MB gives related; either loss
     comes back wanted. Rung 6 asks `Covers(saved, f)` alone, so it would hold A behind B. This is the safe side: no
     wrong hold, a held copy missed in a rare case. It is worth a line in the report, or a second branch (when
     `Covers(lesser, better)`, write the edge the other way).
   - **N2. Facts of 0.** Media whose pixels the catalogue holds as 0 (if a bring-in left them unknown) rank lowest,
     so an old-archive copy recorded as 0x0 counts as the lesser one. If its bytes are lost, it is held behind the new
     one. Not seen in data, only possible.
   - The first pass's notes F3 to F6 stand unchanged. F3 now touches only the lesser side: only a loss of the better
     copy removes the edge.

may be listed as it is
