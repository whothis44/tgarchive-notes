# Brief B4-5b: the fix round for `wip/b-once` after its independent review (session B4, 11-15)

Same coder, same copy (`wt-b-faces`), same branch (`wip/b-once`, on top of 18725db), same rules as before.
The review is `REVIEW-B4-once.md` in the project folder: read findings 1 to 7, its cost section and its list
of untested guarantees in full first; its probes are in the scratch folder it names (read-only: take the
cases, write your own tests in the package).

## Findings 1, 2 and 3 have one cause, and the fix is a simpler rule (the main session's decision)
"Each file once" was built on first appearance (`first=1`): a file's place is decided over the whole
archive, before the query, with a probable step in the group. So a hidden post, a search, a type filter or a
date range that takes the earliest post away takes the file away (findings 1 and 2), and the probable step,
which is not transitive, needed the placement that finding 3 breaks. The owner asked for something
narrower: **"In that chat it can show, but in a unified stream it should be folded under one"**, about a
file saved in one chat and posted again in another. So:

**The rule, as it must be now. In the whole library (the preference on, a query naming no chat and no topic,
not a hiding chip's own view), among the posts the query would list, each file is listed once.**
1. **A file's group is the file and its exact copies only** (the same Telegram file's other posts, and files
   linked by exact copy edges, taken transitively up to the existing bound). **No probable step:** probable
   copies stay with the fold, exactly as before this piece (its faces, its "+n probable", its chip,
   `prob=apart`, the owner's verdicts). A group is then a true class: one number per file, worked out once
   per index version (not per verdict, not per query) and kept beside the overlap table or in a cache of
   its own; nothing new in the index and no upkeep in `refresh.go`.
2. **The place is decided among what the query lists:** the candidates are the group's places in posts that
   pass the query's own filters (search, caption, account, deleted, type, state, the date range in its plain
   meaning, everything `postOK` and `mediaOK` judge) and the three hiding rules (hidden chats, hidden posts,
   clutter). Of those the group keeps one: the earliest place (date, then message id) **whose tile the
   not-downloaded rule keeps** (a saved file; under `copy` also a file with its own direct saved copy);
   when no candidate has such a tile, the earliest candidate (the not-downloaded rule then leaves it out
   and counts it, once). `placeOnce` and its "free" check go.
3. **A post's tile** shows the files that hold their group's place there; a post none of whose files holds
   one is left out and counted under the chip "Each file once: N other posts left out". Order of the
   counts: hidden chats, hidden posts, clutter, each file once, not downloaded, folded; each post under
   exactly one chip; X plus the chips equals Y in every combination.
4. **The address:** the rule's own parameter is `once=0` (show every post in this view; the chip's way
   back). **`first=1` is again exactly what it was before this piece, everywhere** (the filter "Only where
   it first appeared", with its probable step and its "new between" date meaning), and where it is asked
   for the rule is off (it already lists each file once). The sidebar's switch is wired as before this
   piece (finding 4 goes with that); the page offers the rule through its chip and Settings only.
5. **"also in N chats"** on a default tile counts the other chats, not hidden, where the group has a post
   (finding 7), and is right whichever post holds the place.
6. **Cost:** one pass over the listing's candidates with the kept group numbers; no decision per file by
   walking edges or places at listing time. Measure on the timing test's catalogue, by a throwaway probe as
   the reviewer did (not a test that judges time), the default listing cold with the rule on and off, with
   no chat hidden and with one hidden, and a search: say the four numbers with the PC's load. The rule
   should cost a few ms, not the 15 to 20 ms the per-listing first appearance cost.

## Finding 5 (two snapshot writers): fix
One lock around the write; once the stop snapshot was asked for (`Stopping`, or `Close`), nothing writes any
reason but `stop`, and the last file on disk says `stop` with the newest numbers. Also close the review's
untested points with an injected clock: the early write happens only when the numbers changed, and the 10 s
gap holds inside the running writer.

## Finding 6 (the video click): fix
A press on the control strip, or a drag of more than a few pixels, never toggles (judge it at `pointerdown`,
not only at `click`); a double click whose second click comes after the 250 ms wait undoes the toggle before
the browser goes full screen; the "Opening the file from the library…" line takes no clicks
(`pointer-events: none`).

## Tests (named; the review's probes with the right answers)
The earliest post hidden by the owner: the file's other post has its tile. A search that matches only a
later post's caption: found, one tile per group. A type filter across a document and a photo linked by a
probable edge: the photo's tile is there (and the fold decides the rest, as before the piece). A date range
that covers only a later post: its tile is there. The chain t ~ c ~ y with only c saved, under `copy`,
`hide` and `show`: c's own tile is there once, and nothing shows c's picture twice in the default library.
The same file in three chats, the earliest hidden as clutter. An album whose files belong to two groups.
`first=1` gives exactly what it gave on d1af260 (compare with the listing's old answers on a fixture).
`once=0`. The sidebar switch has one handler. `TestNotSavedCountsAddUpEverywhere` and the arrows test over
the new rule. The existing `TestEachOnce*` tests are rewritten to this rule, not loosened.

## At the end, once
Merge the main branch's head if it moved; `gofmt -l`; `go vet ./internal/viewer ./cmd/tgarchive`;
`TestTimingOnBigCatalogue` by name; `go test ./internal/viewer -p 1` in the background and
`go test ./cmd/tgarchive`. Hand back: the commits (pushed); the rule as built in five lines; the four cost
numbers; what was done for each finding; differences from this brief and why; the whole-package result on
the exact commit; doubts.
