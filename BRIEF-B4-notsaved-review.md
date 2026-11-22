# Brief: an independent, read-only review of `wip/b-notsaved` (files not downloaded, in the viewer's library) (session B4, 11-15)

You are an independent reviewer. You did not write this code and you are not told what its author or the
main session think of it: read the code and try to break it.

## What to review
The branch `wip/b-notsaved` against `f0e3f0c`, in the git worktree
`C:\Users\trabi\Claude\Projects\Telegram\wt-b-faces` (Go module `archiver/`, package
`archiver/internal/viewer`, Go files and `web/js`). See it with `git diff f0e3f0c...wip/b-notsaved --stat`,
then file by file. What it was asked to do is in `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-B4-notsaved.md`:
read it for the guarantees it names, then judge the code, not the brief.

## Where to look hardest (every finding needs the file and line, the inputs, and what goes wrong)
1. **The number kept per file and its upkeep** (`notsaved.go` `keepStandIns`, `pickStandIn`; `refresh.go`
   `apply`): an index updated step by step must hold, for every file, exactly what a fresh build holds.
   Try every cause that can change a file's answer: the file itself gets saved or stops being saved; a
   linked file does; a copy edge appears, **goes, or changes its kind** (exact, probable, related); a
   place of a linked file appears or goes (a message deleted, a post hidden or not, a chat removed); a
   linked file arrives in a later step than the file; the tie-breaks (exact first, more places, lower id)
   when two candidates swap order. Is any path in `apply` that changes those facts missing its note? Does
   the package's reference comparison (`reference_test.go`, `refresh_random_test.go`) really compare the
   new vector, and does its random walk produce these cases?
2. **What is listed and counted** (`library.go`): the three values of the rule against: hidden chats and
   posts, clutter, "each file once" (`first=1`), folded probable copies, chat and topic filters, search,
   one tile per album against one tile per file, albums with some files saved. The heading's "X of Y" and
   every chip must add up, each post once; a tile left out must be out of paging and of the keyboard's
   order too; `state=missing`/`state=held` and `nd=show` must win; two values of the rule must never share
   a kept listing (look at the key); a preference changed while a page is open.
3. **Cost**: nothing may walk copy edges per request or per tile; the default library's first load has a
   200 ms budget on a catalogue at the real size (`timing_test.go` `TestTimingOnBigCatalogue`): run it by
   name once and say its numbers; say whether any new work is proportional to the archive per request.
4. **The page** (`web/js/library.js`, `settings.js`): the tile's mark and title for an exact and for a
   probable copy say what is proven; the chip and its way back; nothing built with `innerHTML` from data;
   the home-network pages draw no control they would be refused (a device that may not change preferences
   still gets the chip's way back for its own view); the picture shown is the saved copy's and the tile
   still opens the post it stands for.
5. **Tests**: does any test judge a span of real time; which named guarantee has no test that would fail if
   it broke.
6. Anything that changed the behaviour of code outside the brief (the post page's `standInOf` was moved:
   is its answer unchanged).

## How to work (rules)
- **Read-only: do not edit, commit or check out anything in `wt-b-faces` or any other folder of the
  project.** Prove a finding with a probe test written in your own scratch folder and loaded with
  `go test -overlay` (an overlay JSON that adds your `_test.go` file to the package), run by name with
  `-run`, `-p 1`, `GOMAXPROCS=2 GOGC=50`. Go: `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`
  in each Bash call. No Docker, no whole-package run, no race detector, one go command at a time; before a
  run check free memory (`powershell -NoProfile -Command
  "[math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB,1)"`) and wait if it is under
  2.5 GB.
- Never start the viewer on real data, never read the owner's viewer folder or library, never open a real
  media file, nothing against Telegram. Invented data only.
- Mark each finding **CONFIRMED** (a probe shows it) or **PLAUSIBLE** (by reading only), with a severity
  (wrong result for the owner; wrong number; cosmetic) and the smallest fix you would accept.

## Hand back
Write the review to `C:\Users\trabi\Claude\Projects\Telegram\REVIEW-B4-notsaved.md` (findings most severe
first, then what you checked and found sound, then what you did not check) and give a ten-line summary as
your final message: the counts by mark and severity, and the two findings you would fix first.
