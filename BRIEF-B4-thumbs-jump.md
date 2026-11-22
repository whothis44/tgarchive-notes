# Brief B4-6: after a jump in the library the tiles on screen get their thumbnails (session B4, 11-15)

Same coder as B4-3 and B4-5 (the viewer), the copy `wt-b-faces`. First: `git fetch private wip/b-window &&
git checkout -B wip/b-thumbs private/wip/b-window` (65d20f2: the native window's branch, listed to merge as
entry 18; it holds everything of today). Package `archiver/internal/viewer` only. All earlier rules hold (Go
through `env-archiver.sh`; named tests while working; `-p 1`, `GOMAXPROCS=2 GOGC=50`; memory checked before
runs; no test judging real time; invented data only; never the owner's folders; push to `private` as
`wip/b-thumbs`; commits by `Claude` ending with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`).

## What the owner said (11-15 19:42, in the native window on the old archive)
"when I drag to a random month (for example, August 2026) it didn't create any thumbnails, until I scrolled
down then up again."

## What the numbers of that use say (the viewer's own snapshot, 3 minutes; counts only)
Thumbnail requests 1,056: 392 answered from the cache, 16 with the smaller size, 648 with none; thumbnails
asked to be made 607, made 851, dropped 0, waiting at the end 0; three makers, 428 ms a thumbnail at the
median (the library is on a NAS over Wi-Fi). So thumbnails were being made; the tiles on screen did not
get theirs.

## What the code does today (read by the main session; read it yourself: `web/js/dom.js` `whenThumb` to
## `settleThumb`, `maker.go` `urgent` and `nextOr`, `media.go` `handleThumb`)
- A tile whose thumbnail is not made shows the stored preview and, once the browser reports it on screen,
  asks with a HEAD request; the ask queues the job on the server; while the answer is "pending" it asks
  again after 0.5, 1, 2, 4, 8, 15, 30, 60 s, only while on screen.
- Dragging the scroll bar passes many blocks of tiles through the screen: every tile that is on screen for
  a moment asks, so a drag queues hundreds of jobs for tiles nobody looked at (607 asked in that use). The
  makers take the newest job first.
- **Two things then leave a tile without its thumbnail for a long time:** (1) on the server a job that is
  already waiting is moved to the front by a new ask only in the "asked only" mode; the owner's mode
  ("paced") leaves it where it is, behind everything asked since; (2) in the page a tile that asked early
  in the drag and comes on screen again is inside its growing pause (up to 60 s) and does nothing until
  the pause is over; scrolling away and back does not shorten it, time does.
  These follow from reading; prove each with a test before fixing it, and say in the hand-back if the
  owner's case has another cause as well.

## What the old app already knows
`LESSONS-viewer-ix12.32.md` 3.3, 4 and 5: a tile never waits; the thumbnail is made "newest asked first"
(at most 256 waiting); the page asks again; "pending needs a done signal". The old app's newest-asked-first
moved a re-asked job to the front (read `wt-v12.32/core-service/internal/app` for how its queue treats a
second ask and say what you found).

## What to build
1. **A tile asks only when it stays:** a place asks after it has been on screen for a short while (about
   300 ms, one constant), so tiles a drag passes over ask nothing. What is on screen when the scrolling
   stops asks at once after that wait, newest first.
2. **A new ask moves a waiting job to the front, in every mode** (`maker.urgent`), and the makers take the
   jobs of what is on screen now before older asks: the newest ask first, as today, with the re-ask
   counted as newest.
3. **A place seen again starts again quickly:** when a record's place comes on screen again while it waits,
   its pause is cut to at most 1 s and its tries start over (the growing pauses are for a tile that stays
   on screen while the server keeps saying "pending", not for one that left and came back).
4. **Old asks do not hold the makers:** a job whose asker went away is not worth a maker's 0.4 s on the NAS
   while tiles on screen wait: jobs asked more than a minute ago and not asked again go behind the
   background walk's turn or are dropped (say which you chose and why; a dropped job is asked again when
   its tile is seen). Count them.
5. **Numbers, in the snapshot (counts and ms only):** asks answered made, pending and none, apart (today's
   `none` mixes them); jobs moved to the front by a second ask; jobs let go as old; and the time from a
   job's first ask to its thumbnail being made, median and worst, so the next use says how long a tile
   waited.

## Tests (named)
- The queue (Go, no real time): a job asked again moves to the front in the paced and the ahead modes too;
  old jobs give way; the counts.
- The page's schedule: if the package's tests already run page code with Node (see how
  `TestPageScriptsParseAsModules` and the reviewers' replicas ran scripts), put the ask schedule's logic
  where a Node-run test can drive it with an injected clock and a stand-in for the observer, and test: a
  place on screen for less than the wait asks nothing; a place seen again inside a long pause asks within
  1 s; four asks at most at once. If Node cannot be used from the package's tests, script-reading tests and
  say so.
- `TestPageScriptsParseAsModules`, `TestLANPageDrawsNoRefusedControls`, the snapshot's fixed words.
- At the end, once: `gofmt -l`, `go vet ./internal/viewer`, `go test ./internal/viewer -p 1` in the
  background. The race detector is the main session's (the makers' queue is concurrent code).

## Hand back (short)
The commits (pushed); for each of the two causes: proven or not, and by which test; what was built for
points 1 to 5 and any difference with the reason; the whole-package result on the exact commit; doubts.
