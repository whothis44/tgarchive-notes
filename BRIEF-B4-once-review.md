# Brief: an independent, read-only review of `wip/b-once` (session B4, 11-15)

You are an independent reviewer. You did not write this code and you are not told what its author or the
main session think of it: read the code and try to break it.

## What to review
The branch `wip/b-once` in the git worktree `C:\Users\trabi\Claude\Projects\Telegram\wt-b-faces` against
`4f0fe17` (the main branch as merged; the main session's message gives the head). Package
`archiver/internal/viewer` (Go and `web/js`) and, if touched, `archiver/cmd/tgarchive`. Four things, asked in
`BRIEF-B4-once.md` and in three later messages the main session's message quotes:
1. **Each file once in the whole library** (`library.go`, `appear.go`, `overlap.go`, `library.js`,
   `settings.js`): a remembered preference, on by default; a query naming no chat and no topic lists each
   file's group once, at its earliest post; a chat's or topic's view shows every post; `first=0`/`first=1`
   in the address win; a chip with its count and a way back.
2. **No file may vanish:** with the not-downloaded rule (`copy` or `hide`), a group's tile is its earliest
   post whose tile that rule keeps; a group is left out only when none of its posts has such a tile, and is
   then counted once under the not-downloaded chip.
3. **A click on the main video plays or pauses it** (`item.js`, `play.js`), for the file's own `<video>` and
   for a converted copy.
4. **The numbers file survives a closed window** (`snapshot.go`, `viewer.go`, the command): the program ends
   cleanly on the console's close signal and writes its snapshot before anything slow; an early write a
   few seconds after a person's request, at most every 10 s.

## Where to look hardest (each finding: file and line, the inputs or the interleaving, what goes wrong)
- **A file missing from, or twice in, the whole library.** Build groups on purpose: one Telegram file in
  three chats; exact copies as a star and as a chain; a probable step; the earliest post not downloaded
  with a direct copy, with a copy only two steps away, with none; the earliest post in a hidden chat, a
  hidden post, clutter, another type than the filter's; a group split by the owner's "not the same"
  verdict; an album tile holding files of two groups. For each, under the not-downloaded rule's three
  values and with the fold on and apart: every file that has a showable tile somewhere is in the default
  library exactly once.
- **Counts:** the heading's X plus every chip equals Y, each post under exactly one chip, in every
  combination above and with `first=0`, `nd=show`, a date range, a search, hidden chats.
- **Paging and the arrows** over the default listing; the listing's key (two effective values never share
  a kept listing; a preference changed while a page is open).
- **Cost:** `TestTimingOnBigCatalogue` by name once, with the PC's load; with a chat hidden (the author says
  the decision is then made per listing build: measure that case with a probe on the timing test's
  catalogue if you can do it without judging real time in a test, and say the number as "looks like").
- **The click:** can one click toggle twice (the browser's own toggle plus the handler), swallow a click
  meant for the browser's control bar, break double-click full screen, or start a file when the page meant
  to do something else (a drag, a text selection, the zoom or swipe handlers); GIF-type clips untouched;
  listeners removed when the page moves on.
- **The snapshot's early write and the shutdown** (`snapshot.go`, `viewer.go`): a timer or goroutine that
  outlives `Close`; a write after `Close`; two writers at once on the temporary file; the debounce on an
  injected clock; which signal the program takes on Windows when its console window is closed and whether
  `Close` can finish inside the time Windows allows (read Go's `os/signal` and `runtime` sources in
  `ix-tools/goroot-1.27.3` rather than memory); nothing but numbers and fixed words in the file.
- **Tests:** which named guarantee has no test that would fail if it broke; any test judging real time.

## How to work (rules)
- **Read-only: do not edit, commit or check out anything in `wt-b-faces` or any other folder of the
  project.** Probes: your own `_test.go` files in a scratch folder under `%TEMP%`, loaded with
  `go test -overlay`, run by name, `-p 1`, `GOMAXPROCS=2 GOGC=50`; Go through
  `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`. One go command at a time; check
  free memory first and wait under 2.5 GB. No Docker, no whole-package run, no race detector.
- Never start the viewer on real data, never read the owner's viewer folder or library or anything under
  `tgarchive-b`, never open a real media file, nothing against Telegram. Invented data only.
- Mark each finding **CONFIRMED** or **PLAUSIBLE**, with a severity (a file missing or wrong for the owner;
  wrong number; cosmetic) and the smallest fix you would accept.

## Hand back
Write the review to `C:\Users\trabi\Claude\Projects\Telegram\REVIEW-B4-once.md` and give a ten-line summary
as your final message: the counts by mark and severity, and the two findings you would fix first.
