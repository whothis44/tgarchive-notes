# Brief B4-1b: the fix round for `wip/b-open` after its independent review (session B4, 11-15)

Same coder, same copy (`wt-b-viewer`), same branch (`wip/b-open`, on top of 6eb54d8), same rules as
`BRIEF-B4-open.md` (named tests only while working; no test judges a span of real time; numbers and fixed
words only; push to `private` as you go). The review is `REVIEW-B4-open.md` in the project folder: read
F1 to F8 and its "Outside this branch" note in full first; its probe tests are in the file it names
(read-only: take cases from them, write your own tests in the package). The main session's decisions:

## F1 (a dead root after a network blip): fix, for the makers and for a person
The kept root is used as it is, so between a blip and the next check every open fails although the folder
is back; a maker then marks a file that was never missing, and a person's click gets a 404.
1. **A generation for the root** (`media.go`): a counter under `mu`, raised whenever the kept root is put,
   swapped or taken off. `open` reports the generation it used.
2. **Makers** (`maker.go` `make`, and wherever a maker's open failure decides a file's fate, `recheck` and
   `produce` included): after a failed open the maker's inline `check()` stays; **if the generation it used
   is no longer the library's after that check (or there is no root), the failure is the library's, not the
   file's**: the "library went away, try again later" branch, no pending mark, no failure mark, nothing
   counted towards "files missing". Only a failure under a root that the check then found alive is the
   file's own.
3. **A person** (`handleFile`, the play route's and "Open in the player"'s `abs`): when the open fails,
   whatever the error (Windows answers a dead network path as "does not exist"), run one check inline,
   bounded by the request's context and by 10 s, and **if the root's generation changed, try the open once
   more through the new root**. A file that is really missing costs one check of the root and still answers
   "not found". The makers give way for the whole of it (it is inside the person's mark already).
4. Tests, with the stand-in root: the review's interleaving (a dead kept root, the folder fine): the maker's
   file gets no mark and is made later; a person's request succeeds on its second try; a file truly missing
   under a live root is still "not found" and still marks as today; two go-away-and-back cycles in a row;
   more than `missingStreak` blip failures in a row do not set "files missing". Through `maker.make`
   itself, not `library` alone.

## F2 (the format list drops real formats): fix
`mediaContainers` gains the single-file demuxers the review names (`rm,dv,mxf,nut,h264,hevc,m4v,gif,ivf`);
check each name against both builds' `-demuxers` (a name a build does not have is harmless in the list,
but say which are missing where) and that none of them can read another file or a URL (say how you
checked). "Format not on whitelist" (and any refusal by the list) maps to the failure word `decode`, so
such a file is not tried again at every start. Extend `TestCraftedConcatFileReadsNoSibling`'s neighbour
test of real clips with RealMedia if this ffmpeg can write one, else with DV and NUT.

## F3 and F7 (the conversion's speed measures the reader): fix
The number must say how fast ffmpeg converted while it was free to. Time spent blocked in the route's
writes to the browser is summed (the route already wraps the writer) and taken out of the wall time;
a conversion counts towards the speed only when it wrote at least 5 s of video; the time to the first
video is taken from the route's first byte (the existing `play_ttfb`), and `first_video_*` goes. Rename
the snapshot's keys if their meaning changes and say in a comment exactly what each counts. Test: the
review's case (the reader pauses 100 s on the injected clock) gives the same speed as without the pause.

## F4 (the "gave way" numbers): fix
Each of the two pairs counts **once per busy period in which at least one maker waited**, and the time is
that period's length from the first waiter's arrival to the gate going idle (or the waiter giving up), not
a sum over workers. One comment line beside each key says so. Test: the review's case (one 2 s open, three
makers waiting) gives 1 and 2,000 ms.

## F5 (several "Open in the player" buttons): fix
Under a converted copy exactly one such button is visible at any time on this PC (the hint's); the
"Opening…" line and a failure message reuse it or leave theirs out while it shows. A script-reading test.

## F6 (a check per failed open): fix
The watcher takes an early signal only when the last check ended more than 2 s ago (injected clock);
otherwise the signal is dropped. F1's inline check for a person is not held by this.

## F8: fix in passing
An open that never reached its open step names `root` as its longest.

## Outside the branch, in this track's code: fix
`web/js/item.js` (about 464 to 467): after a click on "Original", a late `whenThumb` puts the thumbnail
back in place of the original, and with this branch also ends the "Opening…" line early. Once the original
was asked for, a late thumbnail does not replace it. A script-reading test.

## At the end, once
`gofmt -l`, `go vet ./internal/viewer`, and `go test ./internal/viewer -p 1` in the background with
`GOMAXPROCS=2 GOGC=50`; check free memory first. If `TestTimingUnderWriteLoad` alone fails again under
load, run it once by name afterwards and report both. Hand back: the commits (pushed), what was done for
each finding and any difference with the reason, the named tests, the whole-package result on the exact
commit handed back, doubts.
