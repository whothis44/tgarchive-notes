# Brief B3-7: the viewer review's fixes (session B3, 11-15)

You are an Opus coder. Work only in the copy `C:\Users\trabi\Claude\Projects\Telegram\wt-b-faces`. First:
`git fetch private wip/b-viewer && git checkout -B wip/b-reviewfix private/wip/b-viewer` (fa3c002). Go module:
`archiver/`. Go: `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh` in each Bash call.
Package: `archiver/internal/viewer` only (Go and `web/`). Commit after each numbered fix and
`git push private wip/b-reviewfix` (`git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, ending
with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; no archive numbers).

Read first, in full: `C:\Users\trabi\Claude\Projects\Telegram\REVIEW-B3-viewer.md` (an independent read-only
review of a46139f; its line numbers are at that commit, fa3c002 adds only the marks piece) and
`LESSONS-viewer-ix12.32.md` section 6 in the same folder. The main session has read the review and decided
what follows. Where a fix below differs from the review's "smallest fix", this brief wins.

## The fixes, in this order
1. **C1 and C5: the library must not jump to the top, and a block must come from the listing its shape was
   built on.** The shape carries the listing's identity (the index version's number and the decisions'
   version; take the number from a value kept on the index, not from a map entry removed at the swap, so it
   is never 0). `tiles` passes it back and is answered from that kept listing while `listCache` holds it
   (keep a listing reachable by its identity as well as by its filter key). Only when it is gone: the page
   reloads the shape **keeping its place** (re-anchor on the first visible tile's cursor; no
   `scrollTo(0, 0)` on a forced reload, on the faces-done reload, or on a prefs reload that does not change
   the listing). Hiding a post reloads the library in place. A named Go test: a shape, then an index update
   that adds a newer post, then a block by the old identity returns exactly the old listing's tiles; and by
   an evicted identity says so.
2. **P2: one build per listing.** Requests for the same key wait for one run (an in-flight entry per key).
   A named test with parallel requests counting builds.
3. **C2: `tz` is carried in the post's context** (the tile's link and `neighbours`), so previous / next use
   the grid's own listing (the same key: no second build). A named test with a date filter in a zone west of
   UTC: the newest tile in range has a next, and the last steps nowhere outside the range.
4. **C3: first appearance decided in first-place order.** With `first=1`: walk the candidate files by their
   own earliest counting place, ascending `(date, message id)`; a file is shown unless a file of its group
   was already shown. So a file is hidden only by an earlier file of its own group that is itself shown;
   nothing vanishes behind a chain. And: **a file with more than 20 probable links pulls in no probable
   neighbours and is nobody's probable neighbour** (as rule B's "a file in more than 20 posts pulls in
   nothing"; the real catalogue has one file with about 4,462). "Also in N chats" and `only=1` use the same
   group. Keep the cost of one listing: no SQL, bounded groups. A named test: the review's chain t~x~y
   (t and y shown, x hidden), a hub of 25 probable links (all shown), both tile modes.
5. **P3 (decided by the main session):** with `first=1` a tile's date is its post's date (the first place's
   post), so one post's tiles stay one run; and when the post page is opened from a per-file listing with
   `first=1`, the arrows walk only the files that listing shows for that run (send them with the post), not
   the whole set. The post page still shows the whole set in its strip; files outside the run are reachable
   by click, not by the arrows' walk across posts. A named test for the run and for no alternation between
   two posts.
6. **C4 and P1: the stand-in signal.** On the post page, when the plain address was loaded before the record
   knew the thumbnail was made, always swap to the `&m=1` address on `made`. The grid's consumers (library
   tiles, the filmstrip, the chat mosaic, copies rows) are told "grid made" (`has(grid)`), not "any size
   exists", and use `whenThumb` otherwise.
7. **P4, the small ones:** a failed library block is asked again by itself (bounded: 3 tries, spaced); the
   chat and Deleted pages load more when the sentinel stays in view after a short page or an error
   (bounded the same way); the chat page's topic is carried into the post's context; the copies tabs ignore
   a late answer for the other tab. **Not to change:** the catalogue pool of 4 connections (say in the
   hand-back whether a request can really wait on it in asked-only mode, from the code).

## Tests
The named tests above while working (`-run`). Then once at the end: `go test ./internal/viewer -p 1` (about
3 minutes, in the background), `gofmt -l`, `go vet ./internal/viewer`, and the scripts must parse (`node
--check` as modules). No race detector, no mutation checks, one go command at a time.

## One count on the real catalogue (allowed, strictly bounded)
After fix 4, once: a throwaway Go test **kept out of the commit** that opens
`C:\Users\trabi\AppData\Local\Packages\Claude_pzs8sxrjxfjjc\LocalCache\Local\tgarchive-b\old-archive-2\catalog.sqlite`
read-only, builds the index, and prints **only counts and milliseconds**: entries and build time of
`first=1`, `first=1&sameprob=0`, `only=1` in both tile modes, the largest group, and how many files the old
rule hid whose group had no shown file (if cheap to count). Never start the server on it; never touch a
library or media file; print no id, title, text or path.

## Rules
- Never open the viewer on real data or any real file; nothing against Telegram; do not touch
  `repo-archiver`, other `wt-*` folders or other packages. Do not merge into or push
  `claude/charming-feynman-vm2xia` or `wip/b-viewer`.
- Another coder builds a chat overlap table on `wip/b-overlap` in another copy (new files `overlap.go`,
  `web/js/overlap.js`, a library filter `with=` in `library.go`, and it calls `appear.go`'s group): keep the
  group's function signature in `appear.go` if you can, and say in the hand-back if you changed it.
- Concurrent code: say exactly what changed in what requests share (the listing cache, the in-flight entry).

## Hand back (short)
Commits per fix, differences from this brief and why, named tests, whole-package time and result, the real
catalogue's counts and milliseconds, what requests share and how it is guarded, doubts, and anything in
the review you found to be wrong.
