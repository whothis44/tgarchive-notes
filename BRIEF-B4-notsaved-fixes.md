# Brief B4-3b: the fix round for `wip/b-notsaved` after its independent review (session B4, 11-15)

Same coder, same copy (`wt-b-faces`), same branch (`wip/b-notsaved`, on top of e4f1d53), same rules as
`BRIEF-B4-notsaved.md` (named tests only while working; no test judges a span of real time; the timing
budget untouched; push to `private` as you go). The review is `REVIEW-B4-notsaved.md` in the project
folder: read findings 1 to 11 in full first; its probe tests are in the file it names (read-only: take the
cases from them, write your own tests in the package). The main session's decisions:

## One principle behind findings 1, 2, 3 and 4: the rule judges what the tile shows, once, after the fold
A tile is judged by **the files it actually shows** (after the type filter, clutter, "each file once" and
the fold), and its copy, its mark and every count come from that one judgement:
- **1 (fix):** the copy on a tile comes only from a file the tile shows; the mark says "proven" only when
  that file's own copy is exact. The copy is worked out once while the listing is built and `tiles()` reads
  it (`ix.copyOf(e.media)` for set tiles too); no second search over the set's other files.
- **4 (fix; the brief's wording was wrong, not you):** "has a saved file" is judged over the files the tile
  shows, not the whole set. A tile that shows only a file not downloaded is such a tile even when the post
  has a saved file the tile does not show: under `copy` it shows that file's copy or is left out, under
  `hide` it is left out.
- **2 (fix):** when the fold changes what a tile shows, the tile is judged again: a new cover is a shown
  file that has a copy; if no shown file has one, the tile is left out and counted as not downloaded (or as
  shown by `nd=show`), not as folded.
- **3 (fix):** every count the chips show is taken after the fold: a post is under exactly one chip, and
  "Showing N not downloaded" is the number of such tiles on the page.
Tests: the review's probes A, A2, B, C and G as named tests with the right answers, and the existing
`TestNotSavedCountsAddUpEverywhere` extended with a case of each.

## 5 (a copy saved in a hidden chat): the main session decides, the owner is told
A copy's place is named by its oldest post **in a chat and post that are not hidden**, when there is one;
when every place of the copy is hidden, the tile still shows the copy's picture and the mark reads "Saved
copy (in a hidden chat)" / "Probably the same (saved in a hidden chat)" with no chat's name. The number
kept in the index stays as it is (hidden marks never go into the index): this is decided when the tile is
written. The post page's own line (`standInNote`) follows the same rule, through the same function. Test.

## 6 (the same saved picture on two tiles): not changed in this round
Tiles are posts, and a file posted in two chats already shows once per post. It is on the owner's list.

## 7 (cost per tile): fix
The copy's oldest post is worked out once per copy per `tiles()` call (a map, as the post page does).

## 8 (cost at update time): fix
`keepStandIns` redoes linked files only when the changed file's change can matter to them (it is saved
now, or was saved before this update), and works a file out only if it is not saved or its saved state
just changed. The reference comparison must still pass over its random walk (run the five-seed run of
`TestRandomUpdatesMatchFullRead` once, by name, and say its time).

## 9, 10, 11: fix
- 9: `nd=show` counts as a filter and stays in the address only while the server says the rule is on for
  this query; otherwise the page drops it.
- 10: the Settings sentence for `copy`: "the same file, or one that is probably the same, saved from
  another chat".
- 11: a tile that shows a copy's picture takes its shape from the copy.

## At the end, once
`gofmt -l`, `go vet ./internal/viewer`, `TestTimingOnBigCatalogue` by name (its numbers, with the PC's
load), and `go test ./internal/viewer -p 1` in the background with `GOMAXPROCS=2 GOGC=50`; check free
memory first. Hand back: the commits (pushed), what was done for each finding and any difference with the
reason, the named tests, the whole-package result on the exact commit handed back, doubts.
