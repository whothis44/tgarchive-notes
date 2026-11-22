# Brief E1: the old app's look-alike rule in the ladder (session C, 2026-11-14 night)

For one Opus coder, in the copy `C:\Users\trabi\Claude\Projects\Telegram\wt-copies-lookalike` (branch
`wip/copies-lookalike`, cut from `claude/charming-feynman-vm2xia` at 8c0335e). Go module in `archiver/`.
Work only in that copy. Hand back commit-ready; do not commit, push, merge or switch branches.

## Why (the old app's numbers; do not re-derive, do not tune)

The ladder's rung 6 (`internal/catalog/ladder.go` `lookAlike`) holds a file as a probable copy when a SAVED
file has the same type and pixel size, a size within 1% and a length within 1 s. That misses re-encoded
copies, which were the old app's measured waste (byte-identical waste was 93 files, 0.4 GB in a day). The old
app's rule held 39,798 files (1,990 GB) against saved files on 11-13. Its thresholds were measured (preview
hashes at 6 bits or fewer were the same video 95% of the time, 76% at 7 to 12 bits) and no stored fact
separates its wrong holds from its right ones, so **the thresholds stay exactly as they are**. A hold against
a file that is only queued was right in 130 of 530 judged cases, so that one is **counted, not held**.

The rule is already written and tested as a pure package, `internal/lookalike` (nothing calls it). Read it
first, and the old app's code it was taken from, read-only: `C:\Users\trabi\Claude\Projects\Telegram\wt-v12.31\
core-service\internal\app\ix_copies.go` lines 123-213 and 496-540, `ix_held.go` lines 141-183 and 299-367.

## Ported from (the owner, 11-14 night: the old app's code is ours to take from; port, do not write anew)
- `ix_held.go` `ixInflateStripped`, `ixPreviewHash` and `ix_vdup.go` `ixPHash`: already ported, as
  `internal/lookalike/preview.go`.
- `ix_copies.go` `ixCopyFacts`, `ixSameShape`, `ixCheapSame`, `ixCoversSaved`, `ixBetterCopy`, `ixGroupCopies`:
  already ported, as `internal/lookalike/lookalike.go`.
- `ix_copies.go` `ixSavedVideoFacts` and `ixSavedCopyOf` (which saved videos are candidates, the 500 ms range
  by length, the saved file first in both tests) and `ix_held.go` `ixQueuedVideos` and `ixHeldTriage` step 1
  (videos only, from 256 KiB, every one looked at, no cap): ported here, as rung 6's read and test.
- Changed from the old app, each for a recorded reason: the check runs once when a file is catalogued, by an
  index, not every 2 minutes over the whole queue (TRIED-BEFORE 22: a pass over the queue per round starved
  the servers); a hold against a queued file (`ixHeldTriage` step 2) is counted and not made (130 right of
  530 judged).

## What to build

### 1. A schema step (`internal/catalog/schema_lookalike.go`, in the manner of `schema12.go`)
- **Its number.** Another session's step 13 is not merged yet and this one is 14 on the board. In this copy it is
  built as 13 on top of 12, with the number written in exactly one place: two constants, `lookalikeSchema = 13`
  and `lookalikeAfter = 12` (as `loggingSchema` and `loggingAfter`), used by the steps table, `migrate`,
  `SchemaVersion` and the tests, so that the merge changes two numbers and nothing else. No file, function or
  test name carries the number (`schemaLookalikeFor`, `TestSchemaLookalike`).
- `tg_media.phash INT NULL`: the 64-bit hash of the stripped preview (`lookalike.PreviewHash`), stored as the
  same bits in a signed integer; NULL when there is none. Filled for videos only (`type = 'video'`).
- Two partial covering indexes on `(duration_ms, width, height, size, phash)`, both `WHERE type = 'video' AND
  phash IS NOT NULL`: one with `AND file_id IS NOT NULL` (saved videos, for rung 6), one with `AND file_id IS
  NULL` (videos not saved, for the count in 3). The queries must repeat those conditions as literals so the
  planner can use a partial index (see the note on bound values in `attach`).
- Rows already there: the step fills `phash` for every video row with a `thumb`, in the step's own
  transaction, in Go (as the `schemaV..For` functions run Go in the step). State in the report how many rows a
  second it does on invented previews, so the upgrade time of a large catalogue can be said beforehand.
- The step refuses a file that is not at `lookalikeAfter` (as `schema12.go` refuses a wrong base).
  `SchemaVersion` becomes `lookalikeSchema`.
- Every insert into `tg_media` fills `phash` for a video: `attach` in `ladder.go` and `importOne` in
  `internal/catalog/bringin.go` (the old archive's saved videos come in through it: without their hashes
  rung 6 would never match them). One small helper; a package variable for the hash function so tests can put
  a fake in its place (previews with a chosen hash distance are hard to invent).

### 2. Rung 6 for videos: the old rule
For a new attachment with `type = 'video'`, size at least `lookalike.Floor` (256 KiB), a length above 0,
width and height above 0, and a preview hash:
- Read the saved videos whose length is within 500 ms (`lookalike.DurSlack`), by the saved index, **with no
  LIMIT** (the old app's cap of 20,000 let about 450 copies a day through). Order: the index's own.
- A saved video matches when `lookalike.CheapSame(saved, wanted) && lookalike.Covers(saved, wanted)`: the
  saved file first in both, as the old app (`ixSavedCopyOf`). The test is the package's, in Go; SQL may only
  narrow first, and only loosely (for instance pixels and bytes as integers a little wider than the rule), so
  that no row the Go test would pass is left out.
- A matching saved file whose `file` row is lost (see how `exactcheck.go` reads `file.location`) is not a
  match. Look that up only for rows that passed the Go test.
- Of several matches: one with exactly the wanted file's byte size first (the next piece sends those to the
  exact check); else the first found.
- A match: held, `RungLookAlike`, `ReasonLookAlike`, a probable edge to the saved file as now. Evidence, numbers
  and fixed words only: `same length, shape and preview (%d bits apart); length %.1f vs %.1f s; %dx%d vs
  %dx%d; size %d vs %d B`.
- A video under the floor, or without a length, pixel size or preview hash, is not held by rung 6 at all (as
  in the old app). **Everything that is not `type = 'video'` keeps the present rule unchanged** (stills, gifs,
  files): the old app measured no picture rule.
- Nothing else in `attach` changes: the order of the rungs, alternatives, chat preferences, `probable`.

### 3. A look-alike that is only queued: counted as "would hold"
For a video that passed the conditions of 2, was not held by any rung and ends `wanted`:
- look, by the not-saved index, for another video within 500 ms that `lookalike.CheapSame` calls alike and
  whose `c_want` row is `wanted`, `active` or `aside` (look the state up only for rows that passed the Go test);
- if there is one: add 1 to a count and, to a second count, the bytes of the lesser of the two
  (`lookalike.Better`). Keys in `c_settings` beside the rung counts: `lookalike.would_hold` and
  `lookalike.would_hold_bytes`. A reader `LookAlikeWouldHold(ctx) (files, bytes int64, err error)`.
- **Nothing is held, no edge is written, no state changes.** No page shows it yet.

## Cost (measure, report; do not redesign)
The old archive has 143,646 saved videos with the facts the rule needs. Of the saved videos whose length
falls in the same second as a given video: median 1,410, nine in ten under 4,318, the most 7,356. So one
lookup reads about that many index rows. Extend `TestLadderCostAtScale` (or add beside it) with 150,000 invented saved
videos at that density and state: microseconds per catalogued video for rung 6 at a median and at the
densest second, and the same for the count of 3 with 50,000 invented queued videos. If rung 6's median is
over 1 ms, stop and say so in the report: do not add a cap, a cache or a new index on your own.

## Tests (invented data only; named, so they can be run alone)
- `TestLookAlikeOldRule`: through `CatalogueMessage`, each threshold at its edge on both sides (500 and
  501 ms; aspect 2% and just over; 6 and 7 bits; equal pixels and one fewer; 90% of the bytes and just under;
  256 KiB and one byte under); a re-encode with other pixels and another size that is held (the case the old
  rule missed); no preview; no length; a lost saved file; a look-alike that is not saved (not held); the
  equal-size match preferred; the evidence's exact words.
- `TestLookAlikeStillsKeepRule`: a photo and a gif behave exactly as before.
- `TestLookAlikeWouldHoldQueued`: counted once per new video with a queued twin, bytes of the lesser one;
  state `wanted`, no edge; a twin that is held, skipped or saved is not counted here.
- `TestSchemaLookalike`: a v12 file with video, photo and no-preview rows becomes the new version with the right `phash` values
  and both indexes; a file at another version is refused; a second open changes nothing.
- `TestLookAlikeImportedSaved`: a saved video brought in through `ImportSaved` has its `phash`, and a new
  video alike to it is held.
- `TestLadderPlans`: the plans of the two new reads name the new indexes.
- Tests that relied on the 1% rule for videos (`catalog_test.go` near 359 and 410, `staging_test.go` near 464,
  `samepost_origin_test.go` 64, any other you find): changed to the new rule, each listed in the report with
  what it now asserts. Do not weaken what they prove about holds.
- Mutations, each shown failing a named test, then undone: 7 bits allowed; 600 ms; the 90% rule dropped; the
  arguments of `Covers` swapped; a LIMIT 16 on the saved read; the queued count turned into a hold.

## Rules (hard)
- Do not touch `internal/viewer`, `internal/bringin`, `internal/engine`, `internal/telegram`,
  `internal/collector`, or anything under `cmd/`. `internal/lookalike` is not to change either (its hash must
  stay equal to the old app's). If something outside `internal/catalog` must change to compile, stop and say so.
- No code that runs concurrently is added: no goroutine, no background pass, no timer.
- Privacy: invented data only. Never read under `E:\T\` or `%LOCALAPPDATA%\tgarchive\`. The old app's code is
  read-only reference: never build or run it. Evidence and log text: numbers and fixed words only.
- Load: `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh` in Git Bash, then
  `GOMAXPROCS=2 go test -p 1 ./internal/catalog -run '<names>'`. **Only named tests while working**; never the
  whole of `internal/catalog` (3.5 minutes; the main session runs it once after the review), no `go vet` over
  many packages, no race detector, no Docker. Other sessions' test runs may be going: leave them alone.
- Nothing against Telegram; never start the collector or any program of the app.
- Keep `docs/progress/copies-lookalike-PROGRESS.md` in the copy up to date after each step.

## Hand back
`gofmt -l` clean and `go vet ./internal/catalog` clean, the named tests passing, and
`docs/progress/copies-lookalike-REPORT.md`: what was built; every test with what it proves and its mutation;
the cost figures; the rows a second of the step's fill; every existing test changed and why; what was NOT
verified; the changed files; a drafted commit message (no number of any real archive in it: the figures
above stay out of the commit and out of code comments, which say "the old app's measured rule" instead).
