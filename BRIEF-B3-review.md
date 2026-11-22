# Brief B3-5: one independent, read-only review of the whole viewer (session B3, 11-15)

You are an independent reviewer. You did not write this code. **Read only:** change no file in any copy,
commit nothing, run no test suite. Your one output file is
`C:\Users\trabi\Claude\Projects\Telegram\REVIEW-B3-viewer.md`.

## What to review
`C:\Users\trabi\Claude\Projects\Telegram\wt-b-faces` at a46139f (branch `wip/b-filters`, the same commit as
`wip/b-viewer`): the package `archiver/internal/viewer` (Go and `web/`), the whole of it, with most weight on
what changed since the main branch's 4f5be66 (`git log 4f5be66..a46139f -- archiver/internal/viewer`): set
rules A and B, the filter sidebar, a saved copy in place of a file not downloaded, faces read behind the
first index, the chat list's order, thumbnails made only when a page asks, the topic filter, the deleted
mark, first appearance.

## Why (the old app's lesson, `LESSONS-viewer-ix12.32.md` section 6: read that file in full first)
An independent read-only reviewer found two user-visible regressions in the old viewer's 12.32 after its
timings were already excellent. The same three things are to be checked here first, then anything else you
find:
1. **Paging stays right when the index changes between pages.** The library pages by a `(date, key, pos)`
   cursor over a kept listing (`library.go`, `listCache`, `handleShape`, `handleTiles`); the shape carries
   anchors for every block and a generation (`gen`). An index update between the shape and a later block
   builds a new listing: can a block repeat or skip tiles, can the page's layout (aspects and anchors from the
   old shape) disagree with the tiles it then gets, and what does `web/js/library.js` do when `gen` changes?
   The same for the Deleted page's `(deletedAt, lead)` cursor, the chat conversation's paging, the copies
   pages, and the post page's previous / next (`neighbours` in `post.go`), above all with `first=1`, where a
   set's tiles can stand apart and dates are first-appearance dates.
2. **The arrow keys follow paging.** On the post page (`web/js/item.js`), previous and next across posts: do
   they stop, loop or jump at the end of a loaded block, at a filter's edge, or when the listing was rebuilt?
   Inside a post: the filmstrip, the overlap posts of rule B (`near.go`), the "hide not downloaded" switch,
   bounded pages (500 files, 200 places).
3. **The made-or-stand-in signal** (`media.go` `handleThumb`, `maker.go`, `web/js/dom.js` `whenThumb`,
   `swapInThumb`, `warm`): can a stand-in be kept under the real thumbnail's address anywhere (browser cache,
   the page's own state); can a tile stay on a stand-in for good though its thumbnail is made (the coder's own
   doubts: a large picture made between the picture request and the first ask; a tile whose large size alone
   exists; `warm()`'s asks outside the two-ask limit); can asks fill the browser's about 6 connections or go
   on without end; does anything a request does wait on the library or on a maker?

Then, in this order of weight:
4. **The index update** (`refresh.go`, `faces.go`, `viewer.go`'s loop): anything proportional to the archive
   per update; a version shared between requests being changed in place; the deleted list and counts drifting
   from a full read; the lock order between the update, the faces read, the makers and the decisions file.
5. **Filters' correctness** (`library.go`, `appear.go`): a filter whose cache key lacks one of its inputs; the
   first-appearance group (exact links followed to 64 files, probable one step) giving a file twice or not at
   all; counts in the sidebar that disagree with what the listing shows; "every number says what it counts".
6. **Privacy and safety of the server** (`server.go`, `api.go`, `media.go` `handleFile`): loopback only; no
   path from a request reaching outside the library; headers; nothing written except the decisions file and
   the thumbnail cache; nothing logged but counts and fixed words.

## How
Read the code; reason from it. You may write and run small throwaway Go tests **in a scratch directory outside
every copy** only if a finding cannot be settled by reading (say so; one go command at a time; `source
/c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`). Never start the viewer on real data,
never open a real file, the real catalogue or the owner's decisions file; nothing against Telegram; do not
touch `repo-archiver`.

## The report (`REVIEW-B3-viewer.md`)
Findings ranked: **confirmed** (you can state the exact sequence that goes wrong, with file and line) before
**probable**, each with what the owner would see, the smallest fix, and how sure you are. Then what you
checked and found sound, in a few lines, so it is not checked twice. No praise, no summary of the code. Your
final message: the count of confirmed and probable findings and the three worst in one line each.
