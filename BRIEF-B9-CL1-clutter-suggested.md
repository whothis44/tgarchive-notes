# Brief CL1v: clutter suggested by copies' detector, shown never applied (viewer session B9, 11-22)

You are an Opus coder for the viewer track of a private Go project (a Telegram archiver). Work ONLY in
`C:\Users\trabi\Claude\Projects\Telegram\wt-b-clutter` (branch `wip/b-clutter`, from main f0323f5b); module in
`archiver/`. Commit with `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, messages ending with
`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; push `git push private wip/b-clutter` only.

## Rules
- Invented data only; never open the owner's folders. Counts and timings only.
- Go only through the lock, ABSOLUTE output paths: `bash /c/Users/trabi/Claude/Projects/Telegram/runs-b7/shell/scripts/gorun.sh <dir> go test ./internal/viewer -run 'Name' -count=1`. Named tests only; never the whole viewer; no race detector.
- Touch only `internal/viewer` Go (NOT `web`: the UI track draws). Not `internal/catalog`: copies owns the table.

## The owner's word (binding)
"A detector's suggestion is shown, NEVER applied silently." The score never hides anything by itself, under any
switch. Hiding stays the viewer's existing hide of a post or a chat (undoable, the owner's click).

## The seam (agreed with copies, C7; its branch comes later)
Copies writes `c_clutter(tg_media_id INTEGER PRIMARY KEY, score INTEGER 0..100, why INTEGER (bits), at INTEGER)`,
and on each write logs the MEDIA's own change in the change log (the kind the viewer already follows for a media).
Until copies' step is on main the table does not exist: the viewer treats a missing table as "no scores". Your
tests create the table by hand with exactly that shape.

## Build
1. **Read it with the index:** one score per media in memory (fit it into an existing struct's padding if you can,
   as U2 did with its bit: say the struct's size before and after), read in the same SQL that reads a media's state
   (a LEFT JOIN or a keyed look-up), re-read when the media's change is logged. Only when the table exists (checked
   once per full read). Measure the full read at the 193k-file fixture with and without scores (ms, MB).
2. **The data (JSON), absent when no row:** per media on tiles and posts: `clutter_score` (0..100) and
   `clutter_suggested: true` when score >= the threshold and the owner has not said "not clutter" for it;
   `clutter_why`: the words for the bits (take copies' exported words when they exist; until then a local map of
   bit -> fixed words with a TODO naming copies' constant).
3. **The threshold:** a viewer pref `clutter_threshold` (0..100, default 60), read and set through the viewer's
   existing prefs route; and a switch `clutter_suggest` (default OFF): with it off, no media is `clutter_suggested`.
4. **The filter:** `?clutter=suggested` on the library (what `clutter_suggested` marks), combinable with the others;
   ignored while the switch is off or no table exists.
5. **"Not clutter":** `POST /api/not-clutter {media, not: true|false}` (class like `/api/hide`: the owner's mark,
   this PC), kept in the viewer's decisions file beside hidden posts, undoable (`not: false`), and listed by
   `GET /api/not-clutter` for the UI's "Hidden"/review place.
6. **Counts:** the list's Counts key `lib:clutter` = how many media are `clutter_suggested` (background, as the
   other counts in `shellcounts.go`, absent until built).
7. Tests by name: no table -> nothing; scores read and kept by a logged media change; threshold and switch; the
   filter; not-clutter kept and undone; NOTHING is hidden by a score (a test that hidden lists and every existing
   hide rule give the same answer with and without scores); TestWall*; gofmt; vet viewer.

## Hand back (short; numbers only)
Commits pushed; the JSON fields and routes exactly (names, values, when absent); the cost numbers; tests with seconds.
