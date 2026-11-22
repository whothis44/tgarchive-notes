# Brief C28: the whole-album rule, counting only (FEATURES: "Whole-album rule, off, counting what it would hold")

For ONE coder (Opus 5.5, high effort), start to finish. Written by the copies session C7, 2026-11-22. Schema step
**36** (claimed on the board). One independent review follows (it touches the ladder), but nothing here holds,
skips or releases a file.

## What the old app knows (read it yourself: `C:\Users\trabi\Claude\Projects\Telegram\wt-v12.31\core-service\internal\app\ix_album_copies.go`)
- The look-alike rule (rung 6 here) is right about 95% of the time at 6 preview bits or fewer; 7-12 bits alone 76%,
  13-20 bits alone 3%. **Anchored** by its album it is right 89% at 7-12 bits and 67% at 13-20 (lengths alone 5%).
  An album is anchored to a saved album of another chat when at least 2 OTHER videos of the queued video's album
  have a close twin (6 bits or fewer) in that one saved album.
- Then a twin in that saved album (same length within 500 ms, same shape, the saved copy at least as good: as rung
  6's own cover test; preview 7 to 20 bits apart, or no preview) is what the rule would hold. A video with a close
  saved twin is left to rung 6; a saved video that is already another member's close twin is not used. Twins looked
  at per video: at most 400.
- **The old app only counted** ("would hold N files / M MB") while held copies waited for good, because a wrong hold
  would then lose a unique video. The new app has that same standing rule (held copies wait unless the owner
  releases them; `held_wait` on by default). So this piece COUNTS and records; it never holds.

## Where and how (these bind)
- Copy `C:\Users\trabi\Claude\Projects\Telegram\wt-copies-33`, branch `wip/copies-33` from the main head named in
  your start message. Go commands only through
  `bash /c/Users/trabi/Claude/Projects/Telegram/runs-copies-c28/go1.sh <log> <go args...>`. Named tests only; NEVER
  the whole `internal/catalog`; no race detector unless you add concurrent code (you should not).
- Files: `internal/catalog` (a new `album_rule.go`, a new `schema_albumlike.go`, the schema places of `catalog.go`
  as the other steps are wired, the one call in `ladder.go`'s attach and in `atsave.go` where named below), tests,
  the report `archiver/docs/progress/copies-album-rule-REPORT.md`. Anything else: stop and say why.
- Commits `git -C <copy> -c user.name=Claude -c user.email=noreply@anthropic.com commit`, ending with
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; push `wip/copies-33` to `private`. Invented data only.

## The design (port the rule unchanged; change only where and when it runs)
1. **Anchors come from edges that exist**, not from an index rebuilt on a timer: an album member held by rung 6
   (a probable edge with rung 6's evidence to a SAVED media) whose saved twin's message is in an album
   (`message.album_id`) of another space is an anchor of that saved album. Read by `message_album` and the
   attachment and edge indexes: bounded by the album's size, never by the archive.
2. **When it runs (events only):** (a) at the attach of a new video in an album (`ladder.go`, after rung 6 and
   C22's twin rule, for a file left plainly wanted): judge it against its album's anchored saved albums; (b) when a
   member of an album gets a rung 6 edge to a saved media (at its attach, or by the hold-at-save steps of
   `atsave.go` when a video is saved), judge the album's still-wanted videos again. Nothing per hour, no pass over
   the queue.
3. **What it writes (schema step 36):** a table `c_album_like(tg_media_id INT PRIMARY KEY REFERENCES
   tg_media(id) ON DELETE CASCADE, of_media INT NOT NULL, bits INT NULL, anchors INT NOT NULL, at INT NOT NULL)`:
   the file the rule would hold, the saved media it looks like, the preview distance (NULL: no preview), the
   anchors counted. Upsert at each judgement; a file that no longer matches loses its row. NO copy edge, no
   `c_want` change, no reason: every other rule reads `copy_edge` and `c_want`, and this rule must change nothing
   any of them do.
4. **Counts:** a door `catalog.AlbumLikeCounts(ctx)` returning files and bytes of rows whose file is still wanted
   (an indexed join: say its plan), for the pages and the collector's hourly line later (not yours to wire).
5. Constants as the old app's (2 anchors, 20 bits, 400 twins, 500 ms), named; the lookalike package's facts and
   cover test reused, not rewritten.

## Tests (invented, each against a world built by hand)
The anchored case (two anchors, a twin at 8 and at 18 bits: counted), each refusal (one anchor only; twin at 21
bits; twin within 6 bits left to rung 6; a target already another member's close twin; the saved copy not as good;
same chat), an album completed in two pages, an anchor that arrives after the candidate (event b), a saved album that
lands later (event b through `atsave.go`), and one test that nothing else moves: the same world with and without
the rule gives the same `c_want` and `copy_edge` rows, row for row. Cost: an attach in an album of 10 and of 90
videos against 10,000 saved albums: say the milliseconds; stop and report if one attach adds more than 5 ms.

## Done
All of it, the named runs (`-run 'TestAlbum|TestLookAlike|TestHold|TestSchema|TestTwin'`), `gofmt -l` clean,
`go vet ./internal/catalog`, committed and pushed, the report. Hand back with the head and the cost figures.
Stop at the first thing not as written.
