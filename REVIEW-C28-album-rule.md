# Review of C28: the whole-album rule, counting only (head 9e31e1a2)

Independent review, 2026-11-22 01:15. Read: the diff 09e7b5a7..9e31e1a2 (`album_rule.go`, `schema_albumlike.go`, the
calls in `atsave.go` and `ladder.go`, `catalog.go`), the brief `BRIEF-C28-album-rule.md`, the coder's report, and the
old app's `wt-v12.31/core-service/internal/app/ix_album_copies.go` (with `ix_copies.go` and `ix_held.go` for
`ixCoversSaved`, `ixSameShape`, `holdable`). The copy `wt-copies-review33-scratch` was not changed (`git status`
clean). Every probe ran through `runs-copies-r28/go1.sh` with `-overlay` (logs `probe1`, `probe2`, `named1`). The
probe files are kept in `runs-copies-r28/probes-review/`: `atsave_probe.go` is the head's `atsave.go` plus a test
switch `probeOldAtSave` and 09e7b5a7's `atSave`, copied verbatim (the copy was checked against `git show` by `diff`),
and `zz_probe_c28_test.go` holds the probes. Invented data only. No real catalogue, no Telegram request. The branch's
own `-run TestAlbum` passes in this copy (named1: ok, 4.8 s).

## 1. The save path: identical to 09e7b5a7? NOT REAL (note)

- **The text.** `holdCoveredStep` is the old body after `if !ok`, line for line (checked by `diff`). The only
  change: `!ok` used to return nil and now goes on to `albumLikeAtSave(ctx, savedID, false)`. When `ok` is true, the
  save step's own error is returned before the rule runs, exactly as before. A failed facts read still returns
  `bumpCount(at_save_failed)` and never reaches the rule. The rule runs after `at_save` is RELEASEd, in its own
  savepoint, so it cannot undo the save step's work.
- **Probe `TestZZAtSaveDifferential`.** One world runs in three modes:
  - 09e7b5a7's `atSave`, with the attach rule off;
  - the head's `atSave`, with the rule off;
  - the head as it is.
  The world has:
  - holds at a save;
  - a file with the same byte size, there to be marked check-first;
  - a file held as not collected, which gets an edge only;
  - two saved albums, one of them saved after the queued album;
  - a save of a video without a preview, in an album;
  - a save of a photo, in an album;
  - the download of a counted file.
  The world runs twice: without a fault, and with `atSaveFault` failing the second hold, mark or edge of every save,
  so the old body is rolled back.

  The probe compares two things in all three modes:
  - every `Claim`/`Saved` result and error;
  - every table in rowid order, so the order of the writes also shows, with `sqlite_sequence` included and only
    `c_album_like` and the `album_like.*` keys left out.

  Result: equal in all three modes, both runs (278 and 271 dump lines). With the fault: `lookalike.at_save_failed` 2
  in every mode, and `album_like.failed` 0.
- The save path's holds, their errors, the rollback on failure and the order of the writes are the same as
  09e7b5a7's.

## 2. A failure undoes only the rule, inside the caller's transaction? NOT REAL (note)

- **Probe `TestZZAlbumFailInBatch`.** One `SaveMessages` page, so one Batch, carries two anchors, a candidate, a
  second candidate, a video in no album and a text message. A trigger lets the rule's first insert through and fails
  every later one with `RAISE(ABORT)`. Results:
  - `SaveMessages` returns no error, and all messages are catalogued;
  - the first candidate's row, written earlier in the same Batch, stays;
  - the second candidate's step is undone, and `album_like.failed` is 1;
  - every other table is equal, row for row, to the same page with the rule off.
- **Probe `TestZZAlbumFailAtSave`.** Saving the second anchor's twin holds one file (the hold at the save). The rule
  then writes one row and fails on the second. Results:
  - `Saved` returns nil, the file is saved, and the hold stays;
  - both of the rule's writes are undone (0 rows), and `album_like.failed` is 1;
  - every other table is equal to the run with the rule off.
- **When a failure does surface as an error.** Only in two cases, both of the same kind as the existing `at_save`
  step:
  - `SAVEPOINT`, `RELEASE`, `ROLLBACK TO` or the count itself fails;
  - SQLite rolls back the whole transaction (a full disk, an I/O error, out of memory, or an interrupt from a
    cancelled context). Then `ROLLBACK TO album_like` fails and the caller's transaction is lost anyway.

  The rule adds statements, so it adds exposure, but no new kind of failure. A failed read outside the savepoint
  (the album read at the attach, or the first two reads at a save) is counted and writes nothing.

## 3. Writes outside `c_album_like`? NOT REAL. Does the "nothing else moves" test cover the paths? PARTLY (note)

- **The writes.** The only writes in `album_rule.go` are:
  - the upsert and the delete on `c_album_like`;
  - `bumpCount(album_like.failed)` in `c_settings`;
  - the savepoint statements.

  Every other read goes through `queryW`/`rowW` and is a SELECT. No trigger exists on `c_album_like` or
  `c_settings`. The probes in 1 and 2 confirm it: every table, `sqlite_sequence` included, is equal with and without
  the rule.
- **The test.** `TestAlbumLikeNothingElseMoves` does run all three events: (a) at an attach, (b) at an attach and at
  a save (through the hold at a save), and (c) at a save (album 502, twin saved last). It has three gaps:
  - it compares 8 tables, not all of them (for example `message`, `attachment`, `c_reach`, `fetch`, the change logs
    and `sqlite_sequence`);
  - it sorts the rows, so the order of the writes does not show;
  - it has no failure, no check-first mark at a save, no edge-only file, no save of a video without a preview, no
    photo, and no bring-in save.

  The probe in 1 covers those gaps except bring-in (`importOne` calls the same `atSave`). Folding
  `zzDumpAll`/`zzScript` into the test would keep it covered; that is optional.

## 4. Faithful to the old app? ONE REAL difference (should fix), the rest notes

**REAL (should fix): targets come only from rung 6 edges.** The old app's `anchorsOf` marks every close twin (6 bits
or fewer) of every member of the album as a target, edge or no edge. Here `targets` holds only the saved media of
members that have a rung 6 edge. A member whose close saved twin has no edge to it has no target here. Examples:
- the member is the better copy (rung 6 refuses it: `Covers` fails);
- the member is saved itself (rung 2);
- the member's twin's bytes are lost.

In those cases that saved twin can then be counted for another member, which the brief's rule ("a saved video that is
already another member's close twin is not used") forbids.

- **Probe `TestZZAlbumTargetWithoutEdge`.** A saved album of 3. In the queued album, two anchors are held by rung 6.
  Then come:
  - a 1920x1080 copy, 2 bits from the saved third video (rung 6 refuses it: it is better), left plainly wanted with
    no edge;
  - a fourth video, 10 bits from that same saved video, smaller.

  Here the fourth gets a row `{of: saved third, bits 10, anchors 2}`. The old app makes the saved third a target, so
  it counts nothing. Confirmed: **REAL**.
- **Why it matters.** It only inflates the count, and no file is held. But the count is the evidence for ever
  turning the rule on, and the case is the one the target rule exists for: two clips in one album, as long as each
  other, one the better copy of the saved video.
- **Fix, bounded by the two albums' sizes.** In `anchorsOf`, for each anchored saved album, also mark as targets its
  saved videos that are close (as long, same shape, 6 bits or fewer) to any video of album k, read once per event
  as `savedOf` is. Add a test like the probe.

**Notes (no fix needed; the first is the brief's own design):**
- **Anchors come from rung 6 edges only** (brief, design 1). The old app counted any member with a close twin in
  that album, even an unsaved twin, and even when the member was better, saved, or held for another reason. Here
  there are fewer anchors, so the count is lower than the old app's. The coder's report names part of this ("saved,
  or held for another reason"). It does not name two cases: anchors whose twins are queued, not saved, and members
  rung 6 refused. The `anchors` column can therefore be lower than the old app's n.
- **The close-twin check is stricter.** It reads saved videos of any chat, in an album or not. The old app read only
  album videos of other chats. It also does not skip a close twin whose bytes are lost, or one the owner said
  differs; rung 6 skips both, so neither holds the file. In both cases the result is fewer counts, never wrong ones.
- **The 400 cap.** It counts only the anchored albums' saved videos that are as long and of the same shape. The old
  app counted every album video by length. Rarely reached.
- **Ties.** Equal bits go to the lower id, then to more anchors; the old app took the first in length order. This
  changes which `of_media` is recorded, not whether a file is counted.
- **Faithful:**
  - 2 anchors, with the judged video itself not counted;
  - other chats (a space is a chat here: topics share one space);
  - lengths within 500 ms, both ends included;
  - `SameShape(queued, saved)` in the old app's order;
  - 7 to 20 bits, or no preview sorted after any with one;
  - a close twin within 6 bits left to rung 6;
  - `Covers(saved, queued)`, the same as `ixCoversSaved`;
  - the floor and "with a length and pixels";
  - the constants, which are named.

## 5. `CAST(?1 AS INTEGER)`: can it change a result? NOT REAL (note)

- **Every call site binds int64:** media ids, `albumKey{space, album}` read from INTEGER columns, `accountID`,
  `messageID`. The columns compared (`message.space_id`, `message.album_id INT`, `attachment.tg_media_id`,
  `copy_edge.a/b`, `c_want.tg_media_id`, `tg_media.id`) all have integer affinity. A CAST of an int64 is the same
  value, so a key that is not an integer cannot occur.
- **Probe `TestZZAlbumCastSame`.** Each of the rule's ten reads ran in the world from 1, once as written and once
  with the CASTs removed. Bound values: every media id plus 0, -1 and 2^40, and every album key. 124 reads, 58 of
  them with rows: all equal.
- **The only value that tells them apart is a non-integer key.** A float such as album+0.25 matches the album
  through the CAST and matches nothing bare. No call site binds one. The plans are pinned by `TestAlbumLikePlans`.

## 6. Cost: are the reads bounded? YES, with one exception that rung 6 already pays (note)

- **Bounded by album and edge sizes.** The anchors, saved, members and into reads walk `message_album` for one album,
  then the attachments and edges of its members. The getters read walks `copy_edge_b` for one media. The judgement
  reads are three primary-key or pair seeks. The count is a scan of the rule's own rows.
- **The exception: `albumCloseSaved`.** It is rung 6's own read of the saved index by length (±500 ms, with no pixel
  or byte narrowing), so it is bounded by the saved videos in that length band, not by the album. It runs once per
  file that has found a twin. It is the same read rung 6 makes at every attach, and most of the 0.1 ms per video
  judged again that the coder measured.
- **At a save of a video in no album, two of the reads are more than a seek.** Both are bounded, but neither is a
  single seek:
  - `albumsOfVideoSQL` walks every attachment of the media (one message seek each);
  - `albumGettersSQL` walks every rung 6 edge into it, with each edge file's attachments.

  **Probe `TestZZAlbumCostNoAlbum`** timed `albumLikeAtSave` alone, 200 calls per Batch, the median of 11 Batches:

  | rung 6 edges into the saved media | time per call |
  |---|---|
  | 0 | 10 µs |
  | 30 | 28 µs |
  | 300 | 211 µs |

  About 0.7 µs per edge. That is small beside the hold at a save, which made those 300 holds in the same save, and it
  is never a pass over the archive.
- **The coder's stop at the 5 ms bound** (5.2 ms for an album of 90 judged again) is outside these six questions and
  is the integrator's call. Telegram albums hold at most 10 items, and the album of 10 adds 0.08 ms.

## Verdict

may be listed after these fixes: Q4's target set (the close saved twin of any member of the album, edge or not, is a
target and never used for another member), with a test like `TestZZAlbumTargetWithoutEdge`.
