# Brief B3-6: which chats repeat which (session B3, 11-15)

You are an Opus coder. Work only in the copy `C:\Users\trabi\Claude\Projects\Telegram\wt-b-viewer`. First:
`git checkout -B wip/b-overlap private/wip/b-viewer` (fa3c002). Go module: `archiver/`. Go: `source
/c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh` in each Bash call. Package:
`archiver/internal/viewer` only (Go and `web/`). No schema step. Commit work in progress after each part and
`git push private wip/b-overlap` (`git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, ending
with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; no archive numbers).

## What is asked (FEATURES section 7 and 9; listed, so already asked for)
"Which chats repeat which (overlap per chat pair; what each chat adds)": it also gives the overlap estimate
for chats not added yet. And "a members by chats strip for an album reposted whole or in part".
The owner's words on the old app's Chats page (TRIED-BEFORE 15): chats not selected yet "look large but much
is expected to be copies"; one vocabulary that adds up; a copy shown but not clickable was "a major
usability hindrance": every number links to what it counts. The real archive: 378 chats (224 added), about
310,000 files, 85 % of media messages are forwards.

## What the code already has (read it first)
`appear.go`: a file's group (the file, exact links followed to 64 files, probable links one step by a switch)
and its places; `library.go`: `first=1`, `only=1`, `sameprob`; `near.go`: overlapping posts of a post, per
page. `index.go`: `places` per file, `mfManyChats`. Reuse the group, do not write a second rule.

## Part 1: the overlap table
- Worked out on demand, once per index version and per `sameprob` value, and kept with that version (two
  kept at most; requests for the same one wait for one run). It may walk every file once (that is the cost of
  one listing); nothing per request after that. Say the milliseconds in `/api/stats`.
- Per chat: files (distinct groups with a place in the chat), of them **only here**, **first appeared here**
  (same rule as `first=1` with no chat left out), **also elsewhere** = files - only here; the three add up
  as the page says. Per pair of chats (A, B): groups with a place in both. Hidden chats are left out of the
  page but not of the arithmetic (say so on the page if any are hidden).
- A file in more than 20 chats is clutter for pairs (stickers, a logo): it counts in each chat's "also
  elsewhere" but adds nothing to pair counts; the page says how many such files there are.
- Page "Overlap" in the navigation (`/overlap`, `/api/overlap`, `/api/overlap/{chat}`):
  - the list: every chat with files, sortable by title (default), files, only here, share also elsewhere;
    each row: title, files, only here, first appeared here, also elsewhere with its percentage;
  - a chat's row opens its pairs: the other chats ordered by shared files, each with "N shared (P % of this
    chat's files)", and "it has M files this chat lacks"; 30 rows, then "show all";
  - every number is a link to the library showing exactly those files: `chat=A&only=1`, `chat=A&first=1`, and
    for a pair a new library filter **`with=<chat id>`** (a tile stays when its file's group also has a place
    in that chat; in `filter.key`; composes with the rest; one-tile-per-post: when any of its files does), so
    "N shared" opens `chat=A&with=B`. Add the same filter as "Also in…" (one chat, a select) to the sidebar's
    "First appearance" group.
- Stable order and no paging needed (378 rows at most).

## Part 2: an album's members by chats strip (post page)
For the opened post's set when it has two or more files and is in two or more chats (its own places and the
one-step overlap posts rule B already gathers): a small table, rows = the complete post's items in order
(numbers, with the thumbnail the page already has), columns = the chats (at most 12, the ones with most
items first, then "+N more" opening the rest), cell = saved there / posted there, not saved / not there;
each filled cell links to that post. From the index only; bounded as the post page is (500 files, 200
places). Folded under a line "In which chats: N of M items everywhere, K chats" when more than 10 rows.

## Tests (named, while working)
Table-driven on an invented catalogue: three chats with exact and probable links, a file in 21 chats: per
chat numbers add up; pair counts; `sameprob=0`; `with=` in both tile modes; the strip's cells for an album
reposted in part. Then once at the end: `go test ./internal/viewer -p 1` (about 3 minutes, in the
background), `gofmt -l`, `go vet ./internal/viewer`. No race detector, no mutation checks, one go command
at a time.

## One timing on the real catalogue (allowed, strictly bounded)
Once, at the end: a throwaway Go test **kept out of the commit** that opens
`C:\Users\trabi\AppData\Local\Packages\Claude_pzs8sxrjxfjjc\LocalCache\Local\tgarchive-b\old-archive-2\catalog.sqlite`
read-only, builds the index, and prints **only counts and milliseconds**: the table's build time for both
`sameprob` values, chats with files, pairs with a shared file, the largest pair count, files in more than 20
chats, and the build time of `chat=<the chat with most files>&with=<its top pair>` (print no id or title).
Never start the server on it; never touch a library or media file.

## Rules
- Never open the viewer on real data or any real file; nothing against Telegram; do not touch
  `repo-archiver`, other `wt-*` folders or other packages. Do not merge into or push
  `claude/charming-feynman-vm2xia` or `wip/b-viewer`.
- CSS in one block at the end of `web/app.css`. A review's fixes will land on `wip/b-viewer` meanwhile
  (paging, the post page's keys, thumbnails' signal, `appear.go`'s probable links capped at 20 per file): keep
  your changes to new files where you can (`overlap.go`, `web/js/overlap.js`), and before the last
  whole-package run `git fetch private wip/b-viewer` and merge it if it moved (keep both sides).
- Concurrent code: the kept table is read by requests while an index update swaps versions: say exactly how
  it is guarded.

## Hand back (short)
Commits, differences from the brief and why, named tests, whole-package time and result, the real
catalogue's counts and milliseconds, how the kept table is guarded, doubts.
