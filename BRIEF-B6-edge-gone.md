# Brief B6-E: a removed look-alike edge taken in place by the viewer's index (viewer session B6, 11-16 evening)

You are an Opus coder for the viewer track of the new archiver. Work only in the copy
`C:\Users\trabi\Claude\Projects\Telegram\wt-b-faces` (Go module in `archiver/`). First, there: check the copy
is clean (`git status --short` prints nothing; if not, stop and say so), `git fetch private`, and cut the
branch `wip/b-edgegone` from `private/wip/copies-24` (a584f184: the copies track's branch with the
catalogue's side of this piece; do not push to that branch, do not change its files in `internal/catalog`).
Go: `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh` in Git Bash.

**Hard rules, first (each was broken once on this project today):** no search over a whole drive (look only
inside the copy, a scratch folder of your own, the Go toolchain's folders); invented data only: never open
the owner's catalogues, library or any real media (nothing under
`%LOCALAPPDATA%\Packages\Claude_pzs8sxrjxfjjc\LocalCache\Local\tgarchive-b`, `%LOCALAPPDATA%\tgarchive`,
`C:\Users\trabi\tgarchive-app`, `E:\T`, the NAS), start nothing on the owner's folders, stop no process you
did not start; one go command at a time, `GOGC=50 GOMAXPROCS=2 GOFLAGS=-p=1`, **named tests only** (`-run`),
no whole run of `internal/viewer` or `internal/catalog`, no race detector, no Docker; before each go command
`powershell -NoProfile -Command "(Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB; (Get-CimInstance Win32_Processor).LoadPercentage"`
and wait (at most 20 minutes) while free memory is under 2.5 GB or the CPU over 85%; tests do not judge
real time. Only `internal/viewer` (and its tests) may change. Commits on `wip/b-edgegone`, pushed only with
`git push private wip/b-edgegone`: `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, the
message ending `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, no archive numbers. Never stash.

## Why
Since this morning the catalogue removes look-alike edges while an archive runs: the owner's "not the same"
on a pair, and a saved file found lost (its look-alikes are judged again). Until now a removed `copy_edge`
row reached the change log as kind 3, "a row went away" of any of six tables, and for kind 3 the viewer's
index writer can only read everything again in full (about 4 s at 600,000 messages, with the library's
listings, the marks and the verdicts started again): so every "not the same" the owner clicks in the viewer
rebuilds the whole index. **The copies track changed the log on this branch: a removed edge is now a kind of
its own, `catalog.ChangeEdgeGone = 6`, written once for each of the edge's two media.** Your piece is the
viewer's side: take that row in place.

**Read first, in full:** `archiver/docs/progress/copies-edgelog-REPORT.md` on the branch (above all "Every
way a copy_edge row is deleted" and "For the viewer track (three lines)");
`C:\Users\trabi\Claude\Projects\Telegram\REVIEW-E24-edge-removed-log.md` (the copies track's review: its two
findings are about YOUR package: they are this piece); in `internal/viewer`: `refresh.go` whole (`read`,
`readLog`, `unchanged`, `apply`, `finishSet`, what `edges`, `mfEdgeProb`, `probableFlag`, `probablePairs`,
`dirtySetsOf` and the stand-ins do), `check.go`, `fold.go`, `notsaved.go` (`keepStandIns`), `feed.go` (an
update that keeps the version); the lessons that bind this package (`LESSONS-viewer-ix12.32.md` in the project
folder, sections 3 and 4: a warm index updated in place, nothing proportional to the archive per update).

**What the main session read before this brief (build to it; check it as you go and say where it is wrong):**
- Today an incremental update only ever ADDS edges: `apply` appends to both media's edge lists, raises
  `probablePairs`, sets `mfEdgeProb`, marks the two media's sets dirty. Nothing takes an edge out.
- `readLog` sends every kind it does not know to a full read; kind 6 falls there today (right, and slow).
- **Two guards assume that edges never go away, and both must learn of kind 6:** (1) `read` asks
  `MAX(rowid)` of `copy_edge` and returns a full read when it is smaller than the last row id seen; (2) the
  count check (`check.go`, every few minutes) compares `COUNT(*) ... WHERE rowid <= lastEdge` with the
  writer's count of edges read (`edgeRows`) and asks for a full read on a difference.
- **A hazard nobody has handled yet, real since this morning: `copy_edge` is a plain rowid table, so a row
  id can be USED AGAIN.** When the row with the largest id is removed, the next edge inserted gets that id
  (or one below the viewer's last seen id), and "edges past the last id seen" never reads it. Your piece
  must not leave an index that misses such an edge.

## What to build
1. **Kind 6 in the log's reader:** the media ids it names (known ones; the same id may come thousands of
   times in one update: keep a set) are media whose EDGES are read again in this update, in the update's
   own read transaction, by the two indexes the table has (`copy_edge_pair` on a, `copy_edge_b` on b), in
   chunks; nothing else is read for them that a kind 1 row would not read.
2. **In `apply`: the named media's edges are set to what was read**, both directions (an edge that went
   leaves both media's lists; one that is new among them and was not yet seen is added once, not twice with
   the "edges past the last id" read of the same update), and everything the index derives from an edge is
   redone for exactly the media and sets touched: `probablePairs`, each media's probable flag and what
   hangs on it (the fold of probable copies under one tile, "+n probable", the probable-copies page's
   list), the sets (`dirtySetsOf` and whatever an "exact" or "related" edge joins: say which relations join
   sets and what a removed one must undo, even though only probable edges are removed by today's doors),
   the stand-ins (a file not saved that showed its saved copy THROUGH the removed edge must stop doing so:
   `keepStandIns`), the most-places list and the totals where they count edges. Find every reader of
   `ix.edges` and of the probable flags in the package and say for each whether a removal reaches it.
3. **The version.** An edge's removal changes what the library shows (a fold opens, a count falls), so such
   an update makes a new index version as an added edge does: say so; do not use the feed's "keeps the
   version" path for it.
4. **The two guards and the reused row id.** On an update whose log names kind 6: the `MAX(rowid)` guard
   does not ask for a full read by itself; the last seen row id is lowered to the largest one that exists
   when that is smaller; the writer's count of edges follows the removals; **and in that same update the
   writer proves that it now holds exactly the table's edges up to that id** (one count over the table's
   row ids, made only on updates that name kind 6, not on every update): if the numbers differ (an id used
   again between the removal and this read, or a removal the log did not name), THEN it reads in full.
   Without kind 6 in an update both guards stay exactly as they are. Say what each costs at 600,000
   messages and 100,000 edges.
5. **A media the log names that the index does not hold, or that is gone** (a `tg_media` cascade logs its
   edges' pairs before its own kind 3): the kind 3 that follows still asks for the full read; kind 6 rows
   for an unknown id are skipped.
6. **The three tests the copies track named are yours to set:** `TestChangeLogEachChangeFollowed` (the case
   "a copy edge went away": kind 6, NO full read, the index equal to a full read), `TestLostThroughIncrementalUpdate`
   (back to NO full read at the lost step: none anywhere in the test; its comment of this afternoon goes),
   `TestRandomUpdatesMatchFullRead` (and `TestChalRandomStrong` if it is the stronger one): edge removals
   join the random steps (through the catalogue's own doors where they exist: `SetPairWord` with
   "different", `WantAgain`; and by plain SQL on the writer for exact and related edges, which only a tool
   removes), the index compared with a full read after every step.

## Tests (named)
- Each way of `copies-edgelog-REPORT.md`'s list 1 to 6 that the catalogue's doors or plain SQL can make,
  followed by one update: no full read (but for the cascade's kind 3), the index equal to a full read
  (`compareFull` and the strong fingerprint), the fold, the probable page's list, the probable count and
  the stand-in right for the pair that ended.
- A removed edge added again in the next update; removed and added again within ONE update; two edges of
  one media, one removed; the lost media named 5,000 times in one update (count the work: the edges are
  read once per media, not once per row).
- **The reused row id:** the edge with the largest row id removed, then a NEW edge between two OTHER media
  inserted (it takes that id), (a) both before one update, (b) the insert one update later: after each
  update the index equals a full read (say for each whether it was taken in place or by a full read, and
  count the full reads: (b) must be in place).
- The guards without kind 6: an edge deleted with the log's trigger dropped (a tool): the full read still
  comes, as today.
- At size, by the package's timing rig (counts, not time, judged; milliseconds printed): an update that
  names 1 removed edge, and one that names 5,000 removed edges of one lost media, at 600,000 messages:
  statements, rows, entries moved; the library's next ask after it; against the same update on the base
  (a full read).
- The feed, the Changes page and the acting side untouched: `TestChanges|TestAct|TestWall|TestLAN|TestLive`
  still pass by name. `git diff a584f184 HEAD -- archiver/internal/viewer | grep '^-func Test'` prints
  nothing, or you account for each line.

## At the end, once
`gofmt -l internal cmd`; `go vet ./internal/viewer`; your named tests; `go build ./...`. Hand back, as your
last message: the head (pushed) and its base; each of the six points with what you did and any difference
and its reason; every reader of the edges and the probable flags and whether a removal reaches it; the
guards' rule as built and its cost; the numbers at size, with the base's beside them; the tests and what
each printed; what you did NOT test; anything in the copies track's report or review that does not fit the
code; your doubts, plainly. Commit-ready, nothing left running, the copy clean.
