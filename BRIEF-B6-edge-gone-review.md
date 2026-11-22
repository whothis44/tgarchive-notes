# Review brief B6-E: an independent, read-only review of "a removed look-alike edge taken in place" (the viewer's index)

You are an independent reviewer (Opus) for the viewer track of the new archiver. You did not write this code
and you owe its coder nothing. The piece: branch `wip/b-edgegone`, head 25af0b2b, ONE commit on a584f184 (the
copies track's branch with the catalogue's side), in the copy
`C:\Users\trabi\Claude\Projects\Telegram\wt-b-faces` (Go module in `archiver/`). The difference is
`git diff a584f184 25af0b2b` (only `internal/viewer`: `refresh.go`, `check.go`, a new `edgegone_test.go`, three
changed test files). What it was asked to do: `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-B6-edge-gone.md`
(read it in full first). The catalogue's side it builds on: `archiver/docs/progress/copies-edgelog-REPORT.md`
in the copy, and the copies track's own review `C:\Users\trabi\Claude\Projects\Telegram\REVIEW-E24-edge-removed-log.md`
(its two findings are about the viewer: start by checking they are closed). The lessons that bind this
package: `C:\Users\trabi\Claude\Projects\Telegram\LESSONS-viewer-ix12.32.md` sections 3 and 4.
Go: `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh` in Git Bash (Go is not on PATH).

**Why this deserves a hard look:** the index writer (`refresh.go`) is what every page of the viewer reads.
Until today an update could only ADD copy edges; this piece is the first that takes one OUT in place. A wrong
removal is a wrong page everywhere and stays wrong until the next full read (which may be never): a file
still folded under another as a "probable copy" after the owner said "not the same", a file not saved still
showing a "saved copy" it no longer has, a count that is off. And the catalogue's edge table can use a row id
again, which the index's "edges past the last id seen" was never built for.

## How
- **Read-only on the copy and the branch:** change no tracked file, commit nothing, push nothing. Probes live
  in a new folder `C:\Users\trabi\Claude\Projects\Telegram\wt-b6-review-E-scratch` (lay a probe in with
  `go test -overlay`; the copy must be clean when you end: say so).
- **Hard rules:** no search over a whole drive (look only inside the copy, your scratch folder and the Go
  toolchain's folders); invented data only: never open the owner's catalogues, library or any real media
  (nothing under `%LOCALAPPDATA%\Packages\Claude_pzs8sxrjxfjjc\LocalCache\Local\tgarchive-b`,
  `%LOCALAPPDATA%\tgarchive`, `C:\Users\trabi\tgarchive-app`, `E:\T`, the NAS); start nothing on the owner's
  folders, stop no process you did not start; one go command at a time, `GOGC=50 GOMAXPROCS=2 GOFLAGS=-p=1`,
  named tests and your probes only, no whole run of `internal/viewer` or `internal/catalog`, no race
  detector, no Docker; before each go command
  `powershell -NoProfile -Command "(Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB; (Get-CimInstance Win32_Processor).LoadPercentage"`
  and wait (at most 20 minutes) while free memory is under 2.5 GB or the CPU over 85%.
- **Try to break it.** A finding is **confirmed** only with a probe that shows it or a line-by-line argument
  nobody could doubt; otherwise **plausible**, with what would settle it. Look hardest at:
  1. **The index against a full read after ANY mix of edge adds and removals.** The coder's random tests add
     removals by plain SQL, `SetPairWord` and `WantAgain`. Go further and wider: an edge of each relation
     (exact, probable, related) removed between files of every state the index tells apart (saved, staged,
     lost, held as a probable copy, not downloaded with a stand-in THROUGH the removed edge, hidden, in an
     album, in a set joined by a forward origin, in two chats); the same pair removed and added again within
     one update and across two; two edges between the same pair of different relations, one removed; an
     edge to a file the index does not hold yet (its id past the last media read) and one that arrives in
     the same update; a file named by kind 6 that also has a kind 1 row (its state changed) and whose
     message has a kind 2 or 4 row in the same update; a removed edge of a file whose row is deleted in the
     same transaction (the cascade: kind 6 then kind 3); removals while an update that keeps the version
     (the feed's path) would otherwise apply. After each: every part of the index equal to a full read, by
     the package's own strong comparison AND by the pages that read edges (the fold, the probable-copies
     page's list and counts, a post's copies with their evidence, a tile's "saved copy", the "each file
     once" groups, which pairs can be judged). The coder lists eight readers that "follow automatically"
     from the new version: check each really reads the new version's lists and no value kept from the old.
  2. **The reused row id and the proof by count.** `copy_edge` is a plain rowid table. Every interleaving of:
     the edge with the largest row id removed (one, several, all edges of the table); new edges inserted
     that take those ids, between named files, between unnamed files, between one of each, before the
     update, in the next, two updates later; a removal the log does not name (the trigger dropped: a tool)
     together with a reused id (the coder's own first doubt: the two cancel in the count); an insert and a
     removal that leave the count equal but the set different. For each: is the index equal to a full read
     after the update, and if not, when does it become so? The count's arithmetic itself: `edgeRows` counts
     every row ever read, the index's lists hold only edges between two known, different files: a row from
     a file to itself, an edge to a file the index skipped, rows read twice: can the two sides of the
     comparison drift so that every later kind 6 update reads in full for good, or (worse) so that a real
     difference is masked?
  3. **The two guards without kind 6** must be exactly what they were: say by reading and by a probe (an
     unlogged removal; the largest id falling with no kind 6; the count check racing an update that holds
     kind 6 rows: the `edgePending` skip: can it skip for ever, or skip a real loss?).
  4. **Cost.** Nothing proportional to the archive on an update that names kind 6 but the one count of the
     edge table (say its cost at 100,000 and at 1,000,000 edges); the re-read bounded by the named files'
     edges; a file named 5,000 times read once; an update that names 5,000 files: statements and rows; a
     hostile or huge log (100,000 kind 6 rows of 50,000 files in one update): time and memory; a new index
     version per such update: what the library's next ask costs (the coder: about 120 ms at 600,000
     messages, as after an added edge) and whether a run of "not the same" clicks piles versions up.
  5. **Concurrency by argument** (the race detector is not yours): what `apply` shares with the version that
     requests still read (lists copied before they are changed? the mirrored change in an unnamed file's
     list: "taken out of a new copy of the list": check every write path), the writer's own counters, the
     count check's reading of the writer under its lock.
  6. **The tests the hand-back leans on.** Which of the defects you looked for would its tests still pass
     with? Its random test "predicts the full-read count from the table and the log": is the prediction
     independent of the code it tests, or the same rule written twice? Do any tests judge real time?
- **Known and not a finding of this piece:** on this base (it predates today's last merges) the test
  `TestActClicksReadBounded` fails in its own set-up (the catalogue's cap of 50 queued clicks; refitted on
  the main head), and `TestLostThroughIncrementalUpdate` is the older form; both are set when the main
  head is merged in after your review.

## Hand back, as your last message
Write `REVIEW.md` in your scratch folder (**no path of this PC in it**) and give its content: a verdict in
three lines (ready for its full runs after these fixes, or not); the findings worst first, each with:
confirmed or plausible, the file and line, what happens and to whom, the probe (its file in the scratch
folder and what it printed), and the smallest fix you would accept; then "Checked and sound", "The numbers",
"The tests the hand-back leans on", and "Not run". No praise, no summary of what the code does.
