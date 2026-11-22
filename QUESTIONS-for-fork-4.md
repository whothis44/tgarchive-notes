# Questions for the old app's session, 4 (from the archiver's ninth session, 2026-11-13 night)

For any session that has read access to the old app's data. Answer in `ANSWERS-for-archiver-4.md` in this
folder. Numbers only, as always: no names, text, paths, ids or links; never a report line with "same bytes
as". Read-only, no new request to Telegram. If a number is not recorded anywhere, say "not recorded" rather
than estimate. Say for each answer where it came from (report, database table, log counter) and over which
days.

The new app is about to build the exact re-upload check before download (the old app's `ix_subst.go`), then
the look-alike hold, the sampled-frame check and kept parts. These numbers decide the bounds.

## A. `upload.getFileHashes` (the exact check)

1. How many hash windows does one answer carry, and of what size each (bytes)? If it varies, the range and
   the usual value. (The code steps by the last window's end and bounds a file at 64 calls; no figure is in
   the notes.)
2. Per day, from the dedup counters (`ix_dedup`): checks made, checks where Telegram kept no hashes, checks
   that failed, files not downloaded because every hash matched ("telegram-hashes"), files not downloaded on
   sampled parts ("sampled-parts"), and the bytes downloaded for samples.
3. Of the checks made, how many had more than one saved candidate of the same size?
4. Any FLOOD_WAIT or timeout counted on `upload.getFileHashes` itself? Per hour if recorded.
5. Was a file that the exact check passed as "same" ever found later to differ (any "Fetch the real files"
   use, any `ix_subst_block` rows)? A count.

## B. The look-alike hold

6. Today: files held as probable copies by kind of evidence (`ix_copy_hold.how`: saved, queued, recognition,
   album, sampled, sampled-partial), count and GB each.
7. Of holds later checked by sampled frames: confirmed, released ("nomatch"), partial. Counts.

## C. The sampled-frame check and kept parts

8. Per day since 12.13: checks run in the download, by outcome (confirmed, nomatch, partial, failed by
   reason), the parts fetched per check (median, largest), and seconds per check with and without the speed
   limit.
9. Kept parts: bytes kept now, bytes reused by downloads in total (`KeptPartStats` or the report line),
   parts lost or refused on reuse (length or hash mismatch). Counts.
10. Share of videos whose container is MP4 or MOV among saved videos (by MIME type is enough).

## D. Waits, for the new app's first real download run

11. In the last three days, per server and hour: plain waits on parts (count; seconds asked: smallest,
    median, largest) and speed-limit waits (count). Only if the report already has them per hour.
12. Waits on reading messages for file references (`channels.getMessages`, `messages.getMessages`): count per
    day and the seconds asked, if counted at all.

## E. The preview hash: does the new app's equal the old app's? (added 11-14)

The new app's look-alike rule uses the old app's preview hash (`ixPreviewHash`, `ix_held.go`), copied from
the 12.30 source. It was proven equal to that source compiled here, not to the old app as built. Please
check it on INVENTED previews (made in code by the new app's tests: no real media), so nothing private is
involved.

13. In the old app's source tree (12.30), add a throwaway test in `core-service/internal/app` (do not
    commit it) that decodes each hex string below, calls `ixPreviewHash` on the bytes, and prints the
    64-bit value as 16 hex digits with whether it has a hash. Run only that test (`-run` its name; the
    package is large: mind the PC's load). Report the four values. Expected by the new app:

    - `pic1-40x40-q20`: expected `0xb56a912d5aa54af1`, stripped preview (hex):
      `012828a7451456464905253b637a534f4a762e2aeec213466928ad7951d2a9c47d3e31dea3a963e86b38ee72a1d4c9477a7d36404e140c927802adec510e28c54c96d316198a403fdd3537d91bfe793fe46a1cda3a21ccd6e54a0120e45145239d0ff37dbf5ab56a03344c40ceeeb8f7aa557acfa45fef7f5a1b291ab4514568667f`
    - `pic2-40x40-q20`: expected `0xf1080cf5a55197b7`, stripped preview (hex):
      `012828d6a4a29335031b2ffaa7ff0074d6745feb53fde15a12ff00a97ff74d67c5feb53fde148d21b3345982a963d00c9a8bed707f7ff434e9bfd4bffba6b2b15708296e612958da3494521a82c6cbfea9ff00dd35422ff5a9fef0abd2ff00aa7ff74d518bfd6a7fbc291a43665d9bfd4bff00ba7f9565f15a737faa7ff74d6656d47667354dcd83451487a5626a365ff54dfee9aa31ff00ac4ff7855d97fd5bfd0d528ffd627fbc29743486ccb92ffa97ff0074d6663e95a737faa7fa1acdad30f2ba673d4dcf`
    - `pic3-40x40-q20`: expected `0x47a55a952b2a956b`, stripped preview (hex):
      `0128287934d26826909ae21a404d349a09a6935452404d19a4ebdf14b8ff006855a8b7b03696e484d349a09a693500809a4268269a4e0669a43173cd2d572e49eb8a4dc7fbc7f3aeba71715a994a4996c9a6934a69a6b90d5084d275e3ae694d11ff00ad4ff7855229e8861824ec8df95279327fcf37fcab5692ba95ce0f6be47f`
    - `pic4-40x40-q50`: expected `0xb61346c8b976ca39`, stripped preview (hex):
      `0128288338fad07a519a4cfa562d9db2901a4fa5008fca93dcd64d98ca41dbad27f9e94e5193cfa53f68f41428b96a8c5cecc85a560481039f7057fc693cd7ff009f793f35ff001a90e31c53a100dc4608041700fbf34e52d0d9eaed7342cecd046af32e5d8676b7f0fb559682161b4c498e9f77a5577d46147652ae4a9c1c01fe34d1aa41fdd93f21fe35cef0b899fbdcacdd56a11d2e882eadbc89032f28c38e3a7b541f8568de307d3cc83b80467a8e4564ef3fdefd6aa956e58da4b538f111519e9b3169d1b84951c8e158134d1d0520e83e954c1b62dc106e6420e46f2411f5a600598000927b0ef48ddea7b1ff008fc8ff001fe55f514f482f43812e79dbbb3465567d396251f3945e0f18c63fc2b3fec773ff003c8fe62b58fde1f5a7d794f2ea4db777fd7c8f56a52536afd0`

14. Only if 13 is not practical: for 5 saved videos chosen at random, the old app's `ixPreviewHash` of
    their stored preview, each with the SHA-256 of the preview bytes (so the new app can find the same
    preview after the bring-in and compare). Hashes only: never the preview bytes, a name, a path or an id.
    (The owner said on 11-14 that a hash is fine to share.)

## F. Added after the independent review of the new app's exact check (11-13 late)

15. Hash requests and part requests on one server: does a wait on `upload.getFileHashes` come together with
    waits on parts of the same server (same minute), or by itself? If the old app cannot tell them apart in
    its counters, say "not recorded".
16. How many hash requests does the old app have in flight at once on one server, at most (by its code or
    its counters), and through which connections (the download pool's, or its own)?
17. Connections: per day, how many times a download connection was lost or re-made while requests were in
    flight, if any counter or log line records it. (The new app now counts this; a figure from the old app
    would say what to expect.)
