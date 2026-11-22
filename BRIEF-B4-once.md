# Brief B4-5: in the whole library each file once; in a chat's view every post (session B4, 11-15)

Same coder as B4-3 (you know `library.go`), the copy `wt-b-faces`. First: `git fetch private wip/b-viewer4 &&
git checkout -B wip/b-once private/wip/b-viewer4` (d4269cc: your branch joined with `wip/b-open` and the main
head; listed to merge as it is, so this piece goes on top). Package `archiver/internal/viewer` only. All rules
of `BRIEF-B4-notsaved.md` hold (Go through `env-archiver.sh`; named tests while working; `-p 1`,
`GOMAXPROCS=2 GOGC=50`; memory checked before runs; no test judging real time; invented data only; push to
`private` as `wip/b-once`; commits by `Claude` ending with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`).

## What the owner said (11-15 17:02)
Asked whether a file saved from one chat and posted again in another should stay two tiles with one picture:
**"In that chat it can show, but in a unified stream it should be folder[ed] under one."**

## What exists (read first)
`appear.go`: "Only where it first appeared" (`first=1`): each file once, at its earliest place, a file's group
being the file, its exact copies and (unless `prob=apart`) one probable step; decided per listing
(`decideFirst`), with the caption "also in N chats". It is a filter in the sidebar, off by default, kept in
the address only. `fold.go` folds probable copies and says why exact ones are left to `first=1`. The
not-downloaded rule of B4-3 judges a tile by what it shows, after `first` and after the fold.

## What to build
1. **A remembered preference** `library_each_once` (default **on**): **in the unified stream, that is a
   library query that names no chat and no topic, the listing is built as with `first=1`** (each file once,
   at its earliest place, with its group as `appear.go` defines it). In a chat's or a topic's view (the query
   names one or more) nothing changes: every post shows, as today. An address that says `first=1` or
   `first=0` wins over the preference for that query (so `first=0` shows every post in the unified stream,
   and `first=1` in a chat's view keeps today's meaning). The kept listing's key carries the effective
   value, never shared between the two.
2. **Which post stays, said plainly:** `decideFirst`'s order is not changed (the earliest place). When that
   post's file is not downloaded and a later post's is, B4-3's rule already shows the saved copy on it with
   "Saved copy from <chat>". Check this combination on purpose (test) and say in the hand-back what the
   owner sees for: the same file posted in three chats and saved from the second; an exact copy saved
   elsewhere; a probable copy.
3. **The page** (`library.js`): the sidebar's existing switch shows the effective state (on in the unified
   stream by default); a chip in the existing style, "Each file once: N other posts left out", whose click
   shows every post for this view (`first=0`) and then reads "Showing every post" with a way back; the
   heading's "X of Y" and all chips still add up, each post under exactly one chip (with hidden chats,
   clutter, the not-downloaded rule, the fold). The tile's "also in N chats" caption stays.
4. **Settings** (`settings.js`): one switch in the library's group, "In the whole library, show each file
   once" with one plain sentence ("A file posted in several chats, or saved again as an exact copy, gets one
   tile, at its earliest post; a chat's own view still shows every post."). A device on the home network
   that may not change preferences still gets the chip's way back.
5. **Cost:** the default library's first load now builds a first-appearance listing. Run
   `TestTimingOnBigCatalogue` by name before and after with the PC's load noted; the 200 ms budget is not
   loosened; if the default's first load grows by more than a few ms on the invented catalogue, find out
   where (the groups come from the overlap table, built once per index version) and say so.

## Tests (named)
The unified stream by default: one tile per file's group, the caption's count right; a chat's view and a
topic's view: every post; `first=0` and `first=1` in the address win; the preference off: as before this
piece; the counts add up (extend `TestNotSavedCountsAddUpEverywhere`'s queries with the new default and
`first=0`); the three cases of point 2; the arrows on the post page walk the same listing; the listing's key.
The existing tests that count the unified library's tiles run with the preference off through the test
helpers (as `shownPrefs` did for the not-downloaded rule), except the new ones. `TestPageScriptsParseAsModules`,
`TestLANPageDrawsNoRefusedControls`. At the end, once: `gofmt -l`, `go vet ./internal/viewer`,
`go test ./internal/viewer -p 1` in the background.

## Hand back (short)
The commits (pushed); what the owner sees in the three cases of point 2; the timing test's numbers before
and after; differences from this brief and why; the whole-package result on the exact commit; doubts.
