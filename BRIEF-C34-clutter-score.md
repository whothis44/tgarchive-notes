# Brief C34: a clutter score per Telegram media, for the viewer to hide memes and the like

For ONE coder (Opus 5.5, high effort), start to finish. Written by the copies session C7, 2026-11-22, for the owner's
priority ("memes can take over"). The seam is agreed with the viewer (B9): `DESIGN-B9-groups-clutter.md` section 4 in
the project folder, plus a `why` column. No review by the lean rule: it never holds, skips, deletes or releases a file,
and nothing on the download path reads it (a test shows that).

## Where and how (these bind)
- Copy `C:\Users\trabi\Claude\Projects\Telegram\wt-copies-39`, branch `wip/copies-39` from f0323f5b. Go commands only
  through `bash /c/Users/trabi/Claude/Projects/Telegram/runs-copies-c34/go1.sh <log> <go args...>`. Named tests only in
  `internal/catalog`; NEVER the whole `internal/catalog` or `internal/collector`.
- Files: `internal/catalog` (a new `clutter.go` and `schema_clutter.go`, the schema places of `catalog.go`, one call in
  `ladder.go`'s attach), tests, `archiver/docs/FEATURES.md` (one row in section 7 beside the clutter line, about line
  169: "A clutter score per media (copies; the viewer hides at its threshold, the owner's marks win; never a hold, skip
  or delete)"), the report `archiver/docs/progress/copies-clutter-score-REPORT.md`. Schema step: after the newest step
  on your base (`clutterAfter = alertAwaySchema` on f0323f5b, `clutterSchema = clutterAfter + 1`); the step test
  compares the constants, not a number (it is numbered at the merge).
- Commits as usual (`git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, ending `Co-Authored-By:
  Claude Opus 5.5 <noreply@anthropic.com>`), push `wip/copies-39` to `private`. Invented data only. Never check out
  anything in the main `repo-archiver` tree.

## The change
1. **The table:** `c_clutter_score(tg_media_id INTEGER PRIMARY KEY REFERENCES tg_media(id) ON DELETE CASCADE, score
   INTEGER NOT NULL CHECK (score BETWEEN 0 AND 100), why INTEGER NOT NULL, version INTEGER NOT NULL, at INTEGER NOT
   NULL)`. Each write logs the media's own change in the change log (the kind the viewer's index already follows: read
   `changelog.go` and how C19's removed edge logs both media).
2. **The signals** (each a named, exported bit of `why`; weights and the score as named constants, `ClutterVersion`
   = 1): seen in many distinct spaces (the strongest: the count of distinct spaces whose messages carry this Telegram
   file); a sticker, GIF or animation kind; a small file; a small long side; a very short video; a square or
   near-square picture; text in the picture (a fingerprint row of kind `ocr` exists: the old archive's). Every signal
   from what the catalogue already holds; no request, no file read. Read the viewer's four rule-based kinds
   (`internal/viewer`, decisions' clutter settings: small pictures, short videos, stickers, "many") and keep the
   detector consistent with them; say in the report how the score relates to them.
3. **When:** at the attach of every new media (one row, scored once, in the attach's transaction, cheap: say its µs);
   again when its count of distinct spaces grows (an attachment in a new space); a chunked fill at the step's first
   read-write Open for the media already catalogued (as C27's `fillVideoLen`: chunks, a marker, resumable); a
   `version` change rescored the same way.
4. **Doors:** `ClutterOf(ctx, ids)` and `ClutterCounts(ctx)` (rows by score band), for the viewer and the pages.
5. **Never anything else:** a test that the table's presence and contents change nothing in `c_want`, `c_supply`,
   `copy_edge`, `c_probe` (the same world with and without scores, row for row), and that no download-path statement
   reads it (grep in the test of the SQL constants of `lane.go`, `state.go`, `probe.go`, `exactcheck.go`).

## Tests (invented)
Each signal's bit; the score on a meme-like world (a picture seen in 12 chats, square, small) and a plain one; a new
space raising the score; the fill in chunks and its resume; the change-log rows; the cost of an attach with the score
at the unified size (rung-6-sized worlds are enough).

## Done
All of it, the named runs (`-run 'TestClutter|TestSchema|TestChangeLog|TestLadder'`), gofmt and vet, committed and
pushed, the report with the score's weights and the constants' names for the viewer. Hand back with the head. Stop at
the first thing not as written.
