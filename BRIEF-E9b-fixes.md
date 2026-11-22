# Brief E9b: the review's fixes for "a marked file is never downloaded unchecked" (copies track, 2026-11-15)

Same copy and branch as E9 (`wt-copies-1`, `wip/copies-9`, head dcd556c), same rules, same commit and push
form. The independent review is `C:\Users\trabi\Claude\Projects\Telegram\wt-copies-review9-scratch\REVIEW.md`
(read it in full; its probes are in that folder: take each as a named test of the package, renamed, never by
overlay). It found no path by which a flagged file gets a part unchecked, and an unflagged file's path equal
to the base. What it did find, and what to do with each:

1. **C1, a file given back "until the hold ends" comes back up to a second early and is then held for good.**
   The Supply cuts the time to whole seconds. Fix where the review says: round the time up in the record, so
   a file is never offered before the end the lane stated. Test: the review's two probes.
2. **C2, the send-back memory forgets the file at its second call.** For a flagged file the lane must look the
   id up without forgetting it, so a file held once is held again at once if it ever comes back flagged in
   the same run. The unflagged "check slots taken twice" path keeps its present behaviour exactly.
3. **C3, a marked file the owner set to be fetched for real is handed out flagged.** The owner wants its
   bytes: it is not a flagged file. Fix on the Supply's side where the flag is set (a file to be fetched for
   real does not carry it and is not handled as marked), or by taking the mark off when the owner sets
   "fetch for real": the smaller of the two; say which and why.
4. **C4, the count of files held undecided counts files that were given back wanted.** Count only what
   `HoldLookAlike` really held; correct the test that asserts the wrong number.
5. **C5, four mutants no test catches.** Add a named test for each: a flagged file whose `Check` is false; a
   flagged file meeting a wait on record (`Recorded`); a flagged file at an expired reference (it is refreshed
   and checked again once: count the checks); what the check compared is kept when the lane holds on "an
   answer the lane downloads on" (`Compared`). And **`TestUnflaggedUnchanged` must be able to fail on a change
   to the unflagged path**: compare with a digest recorded from the base (f0e3f0c's engine sources: the
   review did this; record how in the test's comment), not with a second run of the same code.
6. **P1, holds shorter than 30 s are not known to the Supply, so marked files keep reaching the lane during
   one.** At the claim, before the reference is refreshed, a flagged file that meets the lane's checks held is
   given back until the hold ends, at no request, and **this give-back does not use up its one send-back**
   (it cost nothing and is bounded by the hold's end, which C1 now keeps). The give-backs after a refresh (in
   `startChecks`, and after a wait on its own hash call) stay once a file and run, as built.
7. **P2:** where a flagged file is held the second time after a check that ran, pass that check's result
   through, so its asks and comparisons are kept.
8. **P3** needs no change: say in the report that the two unedited assertions on `LookAlikeUnchecked` can now
   fire only for a resumed file.

Rules as E9's: touch only the engine and the supply (and the one catalogue line if item 3 goes that way);
nothing for an unflagged file changes; named tests only, one go command at a time, no whole-package run, no
race detector; each fix shown failing its test when undone. Append to
`archiver/docs/progress/copies-holdunless-REPORT.md` a section "Review fixes" (each item: what changed, its
test, its mutation; anything you did differently and why). Hand back commit-ready and pushed.
