# Review E23: a settled frame-check row is not rewritten by a later word (independent, Opus 5.5 high, 11-16)

Head read: `wip/copies-23` 767769a9 (copy `wt-copies-23`), against b435266a. Read: the diff (probe.go +33/-1,
probe_settled_test.go, the report), `probeSettle` in full, `probeFile`/`free`/`held`/`left`, `writeProbeRow`,
`ProbeFetched`, `ProbeOverdue`/`ProbeNotReady`/`probeSettleOpen`, `ProbeUnchecked`, `ProbeWaitJudge`, `ProbeRejudge`,
`ProbeLaneRefused`, `ProbeCloseAll`/`ProbeCloseLeft`, `ProbeStats`; `probejudge/turn.go` (`turn`, `write`, `record`,
`nextJob`), `panics.go` (`markedCatalog`); `supply/probe.go` in full; `WantAgain` and `lostLookAlike` (only for
whether they touch `c_probe`). Probes in the scratch copy `wt-copies-review23-scratch` (detached at 767769a9),
untracked `archiver/internal/catalog/zz_probe_review23_test.go`; the guard was switched off by hand in the scratch
copy's probe.go for one run and put back.

## Q1. Does the guard change a file's fate, or anything but the record?

Who can send a word for a row already done `copy`/`partly`/`nomatch` (every caller of `probeSettle`/`ProbeVerdict`
outside tests):
- `ProbeFetched` (probe.go 635): only right after it wrote the row in phase `fetch` and re-read it: never done.
- `probeSettleOpen` for `ProbeOverdue` (guard `phase == judge`, 1084) and `ProbeNotReady` (no row, fetch or judge,
  1103): never done.
- `supply/probe.go` 258: `VerdictFinal` parts-cap for a row its look saw in phase `fetch`; done only if settled in
  between, and then a non-decisive word, which the head also answered `FateLeft`/`FateLate` (the head's line 851
  branch `done && !decisive`). `Supply.probeSettle` acts only on `FateUnchecked` and `FatePutOff`; any other fate is
  `probePass`. Identical.
- `probejudge` `Judge.record` (turn.go 297, through `markedCatalog`), for a turn's word and for a pending word's
  retry. The judge lists only phase `judge` rows (`ProbeJobs`), one worker per file (`hand`, `pend` keep it), one
  judge per catalogue (`collector/lock.go`, `ErrLocked`). The only writers of a done row with a decisive result are
  decisive words, which only the judge sends; so a decisive word on a done-decisive row needs a second decisive
  word for the same file from the same judge: not produced by any path I found (a write that committed but was
  reported failed is the one theoretical case; SQLite's commit error means rollback).

What the head did with that word, and what now (only reachable in that double-word case):
- Non-decisive word (unknown, final, more parts): head recorded `at`, frames (if any) on the row, fate `FateLeft`
  or `FateLate`; now nothing written, same fate. No difference in fate.
- Decisive word, file in a lane: head rewrote hits/samples/offset/of_file/frames/at, kept result, `FateLate`, late
  counted; now nothing written, `FateLate`, late counted plus the new counter. Same fate.
- Decisive word, file held: head `FateHeld` (a "copy": a second `AddCopyEdge` (INSERT OR IGNORE), `DELETE c_part`,
  then `record` called `Parts.Remove`; a "no match"/"partly": stays held, `MarkPartlySame` edge for partly); now
  `FateLeft`, nothing. The file's state is the same (held). The judge then does not call `Parts.Remove`: the parts
  of a held copy were already removed after the first "copy" (its fate held), and a held file gets no further probe
  turn (`supply/probe.go` 156, `TierHeld`), so no part is left that the head would have swept and the guard leaves.
- Decisive word, file free (wanted, or aside for the frame check): **here the fate differs.** Probe P1: row done
  `nomatch`, file wanted, then a "copy": head `FateHeld`, held, one probable edge, kept parts' rows deleted (and the
  store's files removed by the judge); guard `FateLeft`, wanted, no edge, the part's row kept. The file is then
  downloaded, its kept parts reused, exactly as after its first ("no match") word. The direction is the safe one
  (downloaded, nothing lost; the first word's record stands, as the brief rules), and it is reachable only through
  the double word above. Finding 3 (low, no fix).
- Checks in flight: `ProbeOpen` counts rows in fetch/judge; the guard writes no row and no phase, so the count is
  unchanged. No retry for ever: `record` treats every fate as `wroteOK` and deletes the pending entry (turn.go 315);
  `FateLeft`/`FateLate` were already answered by the head for done rows. Log lines: none per word in the catalogue;
  the judge counts `Left`/`Late` in its Stats only.
- Put off, released, re-listed for ever, parts nobody sweeps: none found. A file aside `probe_judging` with a done
  row (ProbeFetched's default branch) is not moved by the guard and comes back at its time: P3, after
  `RequeueAside` the file is `wanted`, `ProbeLook` says phase `done`, and the Supply hands a done row out with no
  plan (`supply/probe.go` 225).

## Q2. Is "final as a record" right in every state the row can be in?

A file is checked at most once in its life: no door puts a done row back to `fetch` or `judge`.
- `c_probe` is written only in probe.go (grep over `internal`: no other writer; the only other removal is the
  foreign-key cascade when the `tg_media` row goes). Every writer there either needs an open row or no row
  (`ProbeRejudge` fetch, `ProbeWaitJudge` judge, `probeSettleOpen`, `ProbeUnchecked` refuses a done row at 1127,
  `ProbeCloseAll`/`ProbeCloseLeft` pick fetch/judge only), writes phase done (`ProbeLaneRefused`), or keeps the
  phase (`ProbeFetched`'s default branch 592-607: phase and result as they are).
- `pairword.go` (the owner's release / "not the same"), `WantAgain` and `lostLookAlike` touch no `c_probe` row;
  "judged again" in `lostLookAlike` is the hold ladder (`pairEdgeLost`), not the frame check. A released or
  re-judged file with a done row is handed out with no plan (`ProbeLook` phase done -> `probeHand`); P2: a row done
  `copy`, the file released to wanted: `ProbeLook` phase `done`; a later word `FateLeft`, row still `copy`.
- So the guard never stands in the way of a fresh check, because there is no fresh check: the row is never reset,
  and the head behaves the same way (it too never re-opens a done row). The record of a released copy keeps "copy
  of X" after the owner said otherwise; the owner's word is kept in `c_pair_word`, not on this row. As the report
  says, a re-judge of done rows, if ever built, needs its own door that resets the row first.

## Q3. FateLate and both counters

Head: a word on a done row while a lane holds the file went through the late branch (851-872) and counted
`probe_late_verdicts`. Now the guard counts `probe_late_verdicts` and `probe_settled_row_words`. P3: head late 1,
settled 0; guard late 1, settled 1. So `ProbeStats.Late` (probe.go 1507) and the judge's `Stats.Late` (turn.go 326,
on `FateLate`) count the same events as on the head: verdicts that came while a lane held the file. The only
drift is the comment on `ProbeStats.Late` ("recorded on the row only"): for a settled row it is now recorded
nowhere. The new counter has no reader outside the tests (not in `ProbeStats`, no line): finding 2.

## Q4. The tests

- Guard switched off in the scratch copy: `TestProbeSettledRowKeepsCopy` FAIL at the first later word
  ("no match: fate {held 0 }"); `TestProbeSettledRowKeepsNoMatchAndPartly` FAIL in all four subtests
  ("wanted no match: fate {wanted 0 }"); `TestProbeSettledRowUncheckedStillTakesAWord` PASS. Guard on: all three
  PASS. They fail on the head, first on the fate check (it is asserted before the row comparison); the row's
  rewrite itself would be caught too: P3 under the head shows the late word rewrote `hits` 0 -> 8 and `at`.
- Comparison: `SELECT *` of the `c_probe` row (every column, `at` and frames in hex included), `SELECT *` of
  `c_want`, every `copy_edge` with the file at either end, every `c_part` row, the state, both counters. A mutant
  that answers the right fate but rewrites any column fails `settledSame`.
- Not covered by the new tests: a file aside `probe_judging` with a settled row (P3 covers it by hand); a held file
  with a row settled `nomatch`/`partly`. Neither changes the guard's code path (the guard does not look at the
  file's state). No existing test was changed.

## Q5. ProbeFetched rewrites a done row

Yes. P3 (guard on): row done `nomatch`, settled at 500; a lane's turn ending with a plan that is not the row's: the
row's `at` 500 -> 700, `parts_fetched` 2 -> 3, `last_new_parts` 2 -> 1; result, why, of_file, hits, samples,
frames kept; file set aside `probe_judging` until 700. It is the one column the brief says must stay ("its `at`
stays as well: it is when it was settled"), so it is a rewrite of the record, but of its time and part counts, not
of its verdict or named file. Reached only when a row is settled while a lane holds the file (a late word, after an
overdue judge row went back to fetch and was handed out). Finding 1 (low).

## Findings

1. **Low.** `ProbeFetched`'s default branch (probe.go 592-607) rewrites a done row's `at`, `parts_fetched`,
   `last_new_parts` (P3). Smallest fix, in the same function: in that branch, when `f.r.phase == ProbePhaseDone`,
   give the file back as now and skip `writeProbeRow` (the kept parts are counted in `c_part` already); or keep
   `r.at = f.r.at`. Shown by probe P3. Not blocking.
2. **Low.** `probe_settled_row_words` has no reader (only the tests), and the comment on `ProbeStats.Late` says
   "recorded on the row only", which is no longer true for a settled row. Smallest fix: one field in
   `catalog.ProbeStats` read as `Late` is, and the comment's three words. Not blocking.
3. **Low (no fix).** The guard changes a fate in one case only: a decisive word on a done-decisive row of a free
   file (P1: head held the file on a "copy" after "no match", with a probable edge and its parts' rows deleted; now
   `FateLeft`, wanted, downloaded, parts reused). Reachable only through a second decisive word for one file, which
   no path produces (one judge per catalogue, one worker per file). Toward the safe side, and what the brief rules.

No finding of high rank: no file is put off, released, re-listed for ever, or left with parts nobody sweeps; the
checks in flight, the judge's retries and the Supply's reactions are unchanged.

## Probes run (scratch copy, invented data; `GOMAXPROCS=2 GOMEMLIMIT=1GiB GOFLAGS=-p=1`, the track's lock, free memory 2.7 GB before each)

- `-run 'TestZZReview23|TestProbeSettledRow'`, guard as built: ok, 2.0 s. P1: copy after no match -> fate left,
  wanted, result nomatch, 0 probable edges, 1 part row. P2: released copy -> look phase done; later word fate
  left, wanted, result copy. P3: late word fate late, late 1, settled 1, row unchanged; ProbeFetched default
  branch -> row changed (`at` 500 -> 700, parts_fetched 2 -> 3, last_new_parts 2 -> 1), file aside probe_judging
  retry 700; a word then fate left, file still aside; after RequeueAside wanted, look phase done.
- Same, guard switched off (`if false && ...`, put back after): KeepsCopy FAIL, KeepsNoMatchAndPartly FAIL (4/4),
  UncheckedStillTakesAWord PASS. P1: fate held, held, result copy, 1 probable edge, 0 part rows. P2: fate wanted,
  result rewritten to nomatch. P3: late word rewrote hits 0 -> 8, settled 0; the copy word on the aside file held
  it (fate held).

## Not looked at

`tools/probe-misses` (another branch); the probejudge and supply tests (not run: not asked, and they use the fake
catalogue, which has no guard); whole packages, vet, race (the clerk's at the merge); the fake `fakeCat` in
`probejudge/fake_test.go` (it does not model the guard; no probejudge test depends on a second word on a settled
row as far as the callers show).

may be listed
