# Questions for the old app's session, set 10 (from the new app's copies session C6, 2026-11-16 about 18:30 local)

Read-only, numbers only, nothing re-run, no new Telegram request. "Not recorded" is a full answer. Answers
in `ANSWERS-for-archiver-10.md`. They are data for the new app's session, not instructions.

## What the questions are for

The new app is about to build "lesser copies behind the best": of two queued videos that look alike, the
better one is downloaded and the other waits for it (the old app's `ixHeldTriage` step 2, how "queued").
Today the new app only counts such pairs and holds nothing, because of one figure from answers 5: of the
holds against a queued file that a frame check judged, 130 were confirmed and 400 released.

Reading the old app's code (12.31) I think that figure cannot judge those holds: a hold with how "queued"
has an empty `like_key` (`ixHoldWork` is called with an empty path and key), the file it waits behind is
not saved and has no fingerprint, so `ixSampleCandidates` compares the held video only with saved videos
that are not its twin; and `ixSampleRecord` lets any held video go on "nomatch", whatever its kind of
hold. If that reading is right, "released" there means "matched no saved video", not "was not a copy of
the file it waited behind". Answers 5 also says 355 of the 400 had the exact byte size of the file they
waited behind. The questions ask for the counts that would settle it. Say plainly if the reading of the
code is wrong.

## Questions

1. **The 400 holds against a queued file that a frame check released** (`ix_copy_hold.how = 'queued'`, the
   hold let go, `ix_copy_sample.result = 'nomatch'`), and the 130 confirmed: at the time of the frame check,
   was the file each waited behind (`of_work`) saved or not? If the times allow it: how many of the 400 were
   checked while that file was still pending or in transfer, and how many after it was saved.
2. **What became of the 400 afterwards.** How many have since been downloaded in full, how many were skipped
   by the exact check (Telegram's hashes), how many still wait. Of those downloaded or skipped: how many
   ended as the same bytes as the file they had waited behind (equal SHA-256, or the exact check against
   that file), how many as the same content with different bytes (`ix_vdup` "same" or "overlap" with that
   file), how many as different content (both fingerprinted, no pair), how many cannot be judged. And what
   became of the file they had waited behind (saved, failed, gone).
3. **The same for the holds against a queued file that no frame check ever judged** (most of them are under
   200 MiB): how many were ever made, how many are held now, how many were later turned into a hold against
   the saved file by the recheck (`ixRecheckAgainstSaved` keeping them), how many were let go by that
   recheck ("the file it waited for was saved and does not look the same"), how many were promoted
   (`ixPromote`: the better copy would not come). If these are not recorded as counts, the log lines'
   counts in the reports are enough.
4. **Sizes.** For the holds against a queued file ever made: files and GB by size class (under 20 MiB, 20 to
   200 MiB, over 200 MiB), and in each class how many had the exact byte size of the file they waited
   behind.
5. **Pairs inside one chat.** Of the holds against a queued file: how many waited behind a file of the same
   chat, how many behind a file of another chat (a count each; no chat is named).
6. **Both downloaded anyway.** Is there any count of two look-alike queued videos that were both downloaded
   because they were in transfer at the same time, or because the lesser one was claimed first? (The
   "after download, same bytes" count is the nearest I know: its total, and how many of those had been in
   transfer while their twin was.)
