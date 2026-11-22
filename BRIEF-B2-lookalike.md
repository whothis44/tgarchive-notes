# Brief B2: the old app's look-alike rule (ninth session, 11-14 early)

Replaces the new app's rung 6 ("same type and dimensions, size within 1%, duration within 1 s",
`internal/catalog/ladder.go` `lookAlike`), which misses re-encoded copies: the measured waste (TRIED-BEFORE
6, 20, 21; `docs/COPY-CHECKS-STUDY.md` E.2). In two parts so that the first can be built now, beside the
exact-check coder who is in the catalogue.

Source, read by the main session in the old app's 12.30 code (`wt-v12.30/core-service/internal/app`):
`ix_held.go` 23-183 (design, the stripped preview, the old single-query rule), 520-655 (triage and hold),
756-912 (recheck); `ix_copies.go` 123-213 (the facts, `ixSameShape`, `ixCheapSame`, `ixBetterCopy`,
`ixCoversSaved`), 498-540 (`ixSavedCopyOf`); `ix_vdup.go` 78-127 (`ixPHash`); `ix_media.go` 36.

## The rule, exactly as the old app has it (do not tune; these are what was measured)

- **Preview hash:** Telegram's stripped preview (first byte 1; bytes 1 and 2 are the height and width
  put at offsets 164 and 166 of a fixed 623-byte JPEG header; the rest follows; `ff d9` appended) decoded as
  JPEG, sampled to 32 x 32 grey (0.299 R + 0.587 G + 0.114 B, nearest point `x*W/32`, `y*H/32`), then a
  64-bit DCT hash: rows then columns, the first 8 x 8 coefficients, a bit set where a coefficient is above
  the median of the 63 non-DC ones. A nearly flat picture (standard deviation under 6) has no hash. A
  picture under 4 pixels a side has none.
- **Alike (`cheap same`):** both have a duration above 0 and a preview hash; durations within 500 ms; the
  same shape (aspect ratios within 2% of the first's); preview hashes at most 6 bits apart.
- **The saved copy covers the wanted one:** no fewer pixels and at least 90% of the bytes.
- **Which copy is the best of several:** most pixels; then the longer (by whole seconds); then most bytes;
  then the earliest post (a forward's original date when it is earlier); then the lower id.
- **Grouping queued look-alikes:** files joined when alike (transitively), searched within a duration
  window of 500 ms over a list sorted by duration; groups of two or more, best first.
- Floor: 256 KiB (below it nothing is held). Videos only by this rule; stills keep the new app's present
  rule (same size or the same preview bytes) until a picture rule is measured.
- A hold is never a skip: held files go when their lane has nothing unique left.

## Part a (start now): a pure package, no catalogue, no Telegram

New package `internal/lookalike`, standard library only. For one Opus agent in its own copy
(`wt-lookalike`), touching nothing outside that package.

- `Inflate(stripped []byte) []byte`, `PreviewHash(stripped []byte) (uint64, bool)`, `PHash(px []byte)
  (uint64, bool)`: bit-for-bit the old app's (`ixInflateStripped`, `ixPreviewHash`, `ixPHash` with its DCT
  table). The 64-bit values must equal the old app's for the same input, because fingerprints and holds
  brought in from the old archive are compared with them: prove it with golden values computed by a small
  test-only copy of the old functions' arithmetic on invented previews (make the previews with
  `image/jpeg` from invented pictures, strip the header the way Telegram does: the test builds a stripped
  preview from a JPEG whose header equals the fixed one, or constructs the bytes directly).
- `Facts` (duration ms, width, height, size, preview hash and whether it has one, first-post date, id),
  `SameShape`, `CheapSame`, `Covers`, `Better`, `Group` (the old `ixGroupCopies` with a duration window).
- Tests on invented data: each threshold at its edge on both sides (500 and 501 ms; 2% shape; 6 and 7
  bits; 90% of bytes; equal pixels); a flat preview; a broken preview; grouping that joins A-B and B-C
  when A-C are not alike; the order of `Better` at every tie; a benchmark of `PreviewHash` and of `Group`
  on 10,000 invented files (state ns and allocations; no speed claim).
- Mutations, each shown failing: 7 bits allowed; 600 ms; the 90% rule dropped; the DC coefficient
  included in the median.

## Part b (after the exact check has landed: it is in the catalogue): the wiring

Schema step after the exact check's. To be briefed in detail then; the outline:
- `tg_media.phash INT NULL`, filled when a message is catalogued (and for rows already there, in chunks
  that never hold the writer for seconds); an index for the lookup by type and duration.
- Rung 6 becomes: a wanted video of 256 KiB or more, alike to a SAVED video that covers it: held, probable
  edge, evidence "same length, shape and preview (n bits)". An indexed range on duration, never a walk
  (TRIED-BEFORE 22: a per-file check is an index lookup; no pass over the queue per new file).
- Rung 6b, queued twins: of wanted videos alike, the best stays wanted, the rest held with an edge to it;
  run for each newly wanted video against the index, not on a timer. When the best is saved: the held
  ones are tested against the saved file (still alike and covered: stay held as copies of a saved file;
  otherwise released). When the best is gone, skipped or failed for good, or held by the owner: the best
  of the rest is promoted.
- "Paused by a person" is its own state and is never undone by any of this (TRIED-BEFORE 24, rule 1).
- A file still only in staging counts as saved for this rule (the old app had to wait for the library).
- Counts per hour: held by rung 6, by 6b, released, promoted; "would hold" for stills stays off.

## Rules (hard), part a

- At most 2 cores: `GOMAXPROCS=2 go test -p 1 ./internal/lookalike/`. No Docker, no race detector, no busy
  loops. Git Bash; `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env.sh`. A container named
  `tgarchive-race` and another agent's test runs may be going: leave them alone.
- Invented data only. Never read under `E:\T\` or `%LOCALAPPDATA%\tgarchive\`. The old app's code under
  `wt-v12.30` is read-only reference: never build or run it, and copy no real preview bytes from anywhere.
- `docs/progress/lookalike-PROGRESS.md` after every step; no commit, no push.
- Hand back commit-ready: gofmt and vet clean, tests passing, `docs/progress/lookalike-REPORT.md` (what
  was built, the proof that the hash equals the old app's, every test with its mutation, the benchmark,
  what was NOT verified, the changed files, a drafted commit message with no number of any real archive).
