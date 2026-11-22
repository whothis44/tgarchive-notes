# Review of C33: saved pictures' PDQ hashes and probable edges between saved pictures

Independent review, 2026-11-22. Head e6951200 on `wip/copies-38` (diff f0323f5b..e6951200), checked out detached in
`wt-copies-review37-scratch`. Invented data only; no Telegram request. Probes are the reviewer's uncommitted
`archiver/internal/catalog/zz_probe_c33_test.go` and `archiver/internal/pdq/zz_probe_c33_test.go`. The C32 probes were
moved aside for this head, because it lacks C32's door. Runs went through `runs-copies-r32/go1.sh`, named tests only
(logs `rv33-probe1` to `rv33-probe3`); all probes pass.

## What ran for real
Nothing. Probe tests on a temporary catalogue and an in-memory index.

## (1) `AddPicturePair`, and what its edges decide

Probe `TestZZProbeC33WantAgain` used three pairs of saved photos. Each pair was tried with either file hashed last,
and with either file then lost:

| Pair | Door's answer, either order | Edge | Lost better / A | Lost lesser / B |
|---|---|---|---|---|
| A 1280x960 900 KB, B 640x480 100 KB | "added" | B to A, probable | wanted, listed by the lanes | held "looks like a saved file", probable, not listed (`held_wait`) |
| Neither covers: A 1280x960 100 KB, B 640x480 900 KB | "written as related" | newer to older, related, partly 0 | wanted, listed | wanted, listed |
| Equal facts | "added" | 2 to 1 (the tie: lower id is the better) | wanted | held |

- **The direction: right.** Probable runs from the lesser to the better by `lookalike.Better` (pixels, then bytes,
  then the lower id, since length and date are 0). It is written only when `Covers(better, lesser)`, whichever file
  was hashed last.
- **Neither covers: related, deciding nothing.** Partly 0, so no trigger fires and no rule reads it.
- **Every other table is unchanged by the door.** `dumpTables` was compared before and after each of the 12 calls.
- **No second edge.** The second call either way answers "an edge between them already".
- **Never exact.** An existing exact edge makes the door answer "an edge already"; the door writes probable or related
  only.
- **Bits outside 0 to 31, or ids not above 0, are refused** with `ErrBadPicturePair`.
- **Never to an unsaved media.** A lost file answers "a file no saved media points at": `WantAgain` sets its media's
  `file_id` to NULL, and the door takes `MIN(tg_media.id)` of media pointing at the file.
- **Never against the owner.** The owner's "different" answers "the owner said not the same" in both orders. The keys
  are `min`/`max`, matching `c_pair_word`'s `CHECK (a < b)` and `not_copy`'s order.
- **WantAgain: as for C32.** A lost better picture comes back wanted; a lost lesser one comes back held behind the
  better saved one. This is not a defect: it is the rule's outcome.

The other readers listed for C32 decide nothing new for pictures (probe `TestZZProbeC33Refusals`, then the code):
- `heldReasonSQL` gives "looks like a saved file".
- `lookAlikeFileSQL` (the held-of) gives the better file.
- The owner's "different" on a held lesser picture removes the edge and releases it (Released 1, wanted).
- `wantAgainCheckFirst` is video-only, so a held picture is never marked for the exact check.
- Rung 6, `atSave`'s covered step and the twin rule judge videos only.
- The frame check of held copies takes only videos (`probeheld.go` `videoSQL`), so **a held picture is never probed
  from Telegram**. The report and the door's comment say it may be: that is an overstatement only (F3).
- The viewer may fold two saved pictures into one appearance. Read-only, as C32's F5.

## (2) What moves, and whether a copy waits
- **Only fingerprint rows of kind `pdq` and `copy_edge` rows move.**
  - `PutPictureHash` writes one row through `PutFingerprints`. The only triggers on `fingerprint` are for kind
    `video`, so none fires.
  - The video worker's reads all filter on kind `video`, and the bring-in's "files without a fingerprint" read takes
    a kind. So a `pdq` row hides nothing from them.
  - Failure rows are rows of kind `pdq` with an empty value. Read errors are retried 3 times in memory and get no row.
  - No `c_want` row is read or written.
- **The copy never waits for the worker.** It takes no hold and has no NotYet; the kick is non-blocking and fires
  after the copier's. It opens the staged copy with the shared open, reads it whole (at most 40 MB) and closes it
  before decoding.
  - One Windows note: a copy removed while the worker has it open stays "delete pending" until the close,
    milliseconds later, so the same staged name cannot be made again during that time. That is harmless in practice.
- **Memory:** one decode stays under about 130 MB (pictures over 32 MP are refused first); the index takes about
  19 MB per 100,000 hashes.

## (3) The band lookup
- **Recall within 31 bits is complete: real (proven).** By pigeonhole, 31 differing bits over 16 bands leave some band
  with at most one, and every band is probed at its value and at the 16 values one bit away.
  - Probe `TestZZProbeC33Recall`, an index of about 110,000 random hashes: 9,616 placements at 0 to 31 bits, 300
    random ones per distance, plus the 16 worst placements (two bits in 15 bands and one in the last). Missed 0, and
    none returned over 31 bits.
- **The 50,000 cap: safe in that it is counted and never makes a wrong match.** Only distances of 31 or less are
  returned, and `Capped` is counted (`capped` in the hourly line).
  - It can miss a true match, though (probe `TestZZProbeC33Cap`). 60,000 far hashes sharing band 0 with the query use
    up the budget in band 0. A true match at 10 bits in the tail is then never looked at: "capped true, 50,000
    candidates, no matches". With no cap it is found.
  - Real hashes would need one band value shared by 50,000 pictures for this. That is unlikely at 85,000 rows, but the
    probes run in band order, not rarest bucket first. Also, once capped, the 16 returned are the nearest of those
    seen, not of all. Note (F4).

## Findings
- **F1, should fix: the worker's load each turn misses rows written for lower file ids.** Each turn reads
  `PictureHashes(after = the highest file id read)`. A PDQ row written later for a file with a lower id is not read
  until the hourly whole load. The bring-in's PDQ step writes exactly such rows, for files it imported before, while
  the collector makes higher ids. Probe `TestZZProbeC33IncrementalLoad`: a row for file 1, written after file 2's was
  read, is not returned by the next turn's load.
  - A new picture hashed in that hour is compared without those rows and never again, since each hash is compared
    once. The pair with the old archive's copy is lost for good.
  - The report says the bring-in's rows are "loaded every turn".
  - Fix: page the incremental load by the fingerprint row's rowid, or by `at`, instead of the file id. Otherwise the
    report must say it and the worker must reload the whole index when the PDQ row count moves by more than its own
    writes.
- **F2, note: unsaved files' hashes take pair slots.** The index holds every PDQ row with a value, including those of
  files that are now lost. Such rows take places among the 16 nearest; the door answers "not saved", and a saved
  17th match is dropped (counted in `over_pairs`). This is rare.
- **F3, note: the report and the door's comment overstate one effect.** They say a held lesser picture "can then be
  probed from Telegram by the frame check of held copies". It cannot: that check takes videos only. The words should
  be corrected; the behaviour is fine.
- **F4, note: the cap can miss a true match.** It is counted and never wrong, but under a pathological cluster it
  misses (probe above), because band order is fixed. Watch `capped`; if it ever moves, probe the rarest bands first.
- **F5, note: as C32's F3 to F5.** A lost better picture erases the pair for good. A related edge outlives a later
  "different". The viewer folds probable pairs.

may be listed after these fixes: F1 (the incremental load reads rows by fingerprint rowid or `at`, not by file id, with
a test where a row for a lower file id written between two turns is in the index at the next turn), and F3's two
sentences corrected
