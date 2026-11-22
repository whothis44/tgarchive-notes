# Brief B3-14: a second independent, read-only review of the viewer: what was added after the first (session B3, 11-15)

You are an independent reviewer. You did not write this code. **Read only:** change no file in any copy,
commit nothing, run no test suite. Your one output file is
`C:\Users\trabi\Claude\Projects\Telegram\REVIEW-B3-viewer-2.md`.

## What to review
`C:\Users\trabi\Claude\Projects\Telegram\wt-b-faces` at a713cfc (branch `wip/b-nofaces`): the package
`archiver/internal/viewer` (Go and `web/`). A first review read it at a46139f
(`C:\Users\trabi\Claude\Projects\Telegram\REVIEW-B3-viewer.md`: read it in full first, with
`LESSONS-viewer-ix12.32.md` section 6 in the same folder) and its nine findings were fixed (d954088 to
e593adf). A security review read the home-network mode
(`REVIEW-B3-lan.md`; its findings fixed, 6668298 to 83924a9): do not review that mode again, except where a
later piece touches it. **No independent reviewer has read these pieces**, each built by a different coder
and merged one on another, none seen in a browser by its author:
1. the first review's fixes themselves (`library.go` `listCache`, `listingFor`, the listing identity; the
   page's reload in place, re-anchored by cursor, in `web/js/library.js`; `appear.go` `decideFirst`; the
   post's run in `post.go` `neighbours` and `web/js/item.js`);
2. the Overlap page and the album strip (`overlap.go`, `strip.go`, `web/js/overlap.js`, `strip.js`; filters
   `with`, `without`, `elsewhere`);
3. a converted copy while it plays and "Open in the player" (`play.go`, `launch*.go`, `ffmpeg*.go`,
   `web/js/play.js`);
4. filter chips with counts and clutter per chat (`library.go` counts, the `chat_clutter` table in
   `decisions.go` / `marks.go`, `web/js/library.js`, `chats.js`, `settings.js`);
5. probable copies folded under one tile, verdicts and the review page (`fold.go`, `review.go`,
   `verdicts.go`, `appear.go`, `copies.go`, `web/js/copies.js`, `item.js`);
6. "No faces" (`faces.go`, the flag bit, `library.go`).
`git log --oneline 4f5be66..a713cfc -- archiver/internal/viewer` shows the order.

## What to look for, in this order of weight
1. **What the owner would see go wrong.** A page that does not load or throws (the scripts were checked only
   by a module parse test and two short looks on an invented archive: read each script for a name used and
   not defined or imported, a function called with the wrong shape of answer, an element looked up that the
   page never makes, a listener added twice on a reload); a number on a page that does not equal what its
   link shows (chips' counts, "N of M", the Overlap table's cells, "+n probable", the review page's tabs,
   "N of M were looked at"); a filter that silently drops or doubles tiles when combined with another
   (`first`, `only`, `with`, `without`, `elsewhere`, `prob=apart`, `faces=none`, `clutter=show`, `deleted`,
   `topic`, hidden, a date range, both tile modes): pick the combinations the tests do not cover and reason
   them through.
2. **The 12.32 three again, on the new code:** paging stable when the index or the decisions change between
   pages (the reload in place: can it loop, lose its place, or re-anchor on a tile the new listing folded or
   filtered away? the review page's and the Overlap page's own paging and cursors); the arrow keys following
   paging (the post's run with `first=1`, folded files in the strip, the S / N keys on the review page while
   a verdict request is in flight); the made-or-stand-in signal after the grid/any-size split.
3. **Kept tables and versions.** The overlap table, the fold, the review counts, the clutter bits, the
   totals for "N of M", the hidden-items snapshot: each is keyed by what? Can a request be answered from a
   table of another index version, another verdict generation or another decisions version than its listing?
   Can a hide, a verdict or a per-chat clutter choice leave a kept listing or table stale under the same
   key? What grows without bound in a long-running viewer?
4. **Cost.** Anything proportional to the archive per request (not per index version); the default library's
   first build per index version was measured at 150 to 190 ms on the real catalogue (budget 200): what in it
   could be kept instead of recomputed; what a collector writing every 2 s would make it rebuild.
5. **The child processes.** `play.go`: a conversion's process always ends (request gone, idle, the server
   stopping, a panic in the handler); the slots cannot leak; a HEAD starts nothing. `launch.go`: the path is
   always inside the library, one argument, never a shell.
6. **The owner's marks.** A hide, a verdict or a clutter choice is never lost by a restart, a fresh
   bring-in (row numbers change) or "unhide all"; nothing in `decisions.sqlite` is keyed by a catalogue row
   number; two requests changing marks at once.

## How
Read the code; reason from it. You may write and run small throwaway Go tests **in a scratch directory outside
every copy** only if a finding cannot be settled by reading (say so; one go command at a time; `source
/c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`). Never start the viewer on real data,
never open a real file, the real catalogue or the owner's decisions file; nothing against Telegram; do not
touch `repo-archiver`.

## The report (`REVIEW-B3-viewer-2.md`)
Findings ranked: **confirmed** (the exact sequence, file and line) before **probable**, each with what the
owner would see, the smallest fix, and how sure you are. Then what you checked and found sound, in a few
lines. No praise, no summary of the code. Your final message: the count of confirmed and probable findings
and the three worst in one line each.
