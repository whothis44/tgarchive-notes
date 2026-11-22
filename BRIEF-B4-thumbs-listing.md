# Brief B4-8: a listing queues no thumbnails; only a tile that asks does (session B4, 11-15)

Same coder (the viewer), copy `wt-b-faces`. First: `git fetch private wip/b-window && git checkout -B
wip/b-thumbs2 private/wip/b-window` (1aa9ac4: everything of today, the full runs passed on it). Package
`archiver/internal/viewer` only; all earlier rules.

## What the owner's next use showed (the viewer's snapshot, a 24 s use of the window; counts only)
The owner dragged through the library: 43 blocks of tiles were listed, and **4,786 thumbnails were asked of the
makers in 24 s, 2,653 of them dropped unmade, 2,033 still waiting at the close**, while the page itself made
about 490 asks (61 answered made, 430 pending; 449 jobs moved to the front by a second ask). From first ask
to made: median 3.0 s, worst 7.4 s (83 thumbnails). The owner: "It's mostly good."

## The cause, read by the main session
`media.go` `mediaInfo` (about line 757): in every mode but "asked only", **each file a listing or a post
returns is queued as urgent** ("a page is showing them now"). A block is 120 tiles and a drag lists dozens of
blocks, so the queue fills with thousands of jobs for tiles that were never on screen; yesterday's piece
(a tile asks only when it stays 300 ms) cannot help, because the server queues them before any tile asks.

## What to build
1. **A listing or a post queues nothing, in any mode.** Only the page's own ask for a file it shows queues a
   thumbnail (`handleThumb`); the background walk makes the rest in its own time, as today. Say in the
   hand-back what the first screen of the library then looks like in time: the first tiles' thumbnails
   start being made about 300 ms plus one ask after they are drawn.
2. **The numbers say what they count:** `thumbs.asked` and `dropped` are the page's asks only after this;
   check every counter of the makers' queue in `/api/stats` and the snapshot against that and correct its
   comment or name where it no longer fits.
3. The queue's size: with only on-screen asks, say what bound fits (today 2,048) and set it.

## Tests (named)
A listing of many tiles and a post with many files queue nothing in the paced and ahead modes (the queue's
length and the counts); the page's ask still queues; the background walk still makes what nobody asked;
`TestPacedAskedFirst` and the other maker tests adjusted where they relied on listings queueing, not
loosened. At the end, once: `gofmt -l`, `go vet ./internal/viewer`, `go test ./internal/viewer -p 1` in the
background.

## Hand back (short)
The commits (pushed as `wip/b-thumbs2`); what changed; the whole-package result on the exact commit; doubts.
