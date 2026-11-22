# Session B, continued (written 2026-11-14 evening by the first B session, which ran out of usage)

Paste into a new session in this project folder: "Read `START-SESSION-B2.md` and do what it says."

Read `START-SESSION-B.md` first (the rules and the order of work are unchanged), then all of
`SESSION-B-PROGRESS.md` (short: every number is there). Then carry on from "Next" below.

## Where things stand
- **A6 done for real.** A read-only copy of the old database: `%LOCALAPPDATA%\tgarchive-b\oldcopy\old.sqlite`
  (`VACUUM INTO` through `mode=ro`, passes `quick_check`; use this same copy for any resume). `plan`: 14 s.
  `run`: 8 min 52 s into `%LOCALAPPDATA%\tgarchive-b\old-archive\catalog.sqlite`. Reports beside them:
  `plan-1.txt`, `run-1.txt` (counts and fixed words only).
- **The bring-in's branch:** `wip/b-bringin` (copy `wt-b-bringin`, head 7d54abb, pushed to `private`), entry 1
  of `MERGE-QUEUE.md`. Its review: `archiver/docs/review/BRINGIN-RUN-REVIEW.md` there.
- **Verify exited 1** on small differences (119 completed work rows whose file is not saved, 13 video
  fingerprints, 8 open rows "wanted" instead of "not collected"); nothing a viewer shows. Not diagnosed. The
  "complete" mark is therefore not set. Left from the review for later: F1 (verify compares counts only),
  F3, F5, F6, F8.
- **The viewer on that catalogue** starts (index 2.0 s, 634 MB, pages 1 to 6 ms) but is **not fit for the
  owner yet**: one set held 78,956 posts, and its post pages failed ("too many SQL variables"). Cause: a
  forward from a user has an origin key of the sender alone, so all forwards from one person were one post
  (the owner, 11-14: most of the archive is messages the owner forwarded into other chats).
- **Rule A is built and committed** in `wt-b-viewer` (branch `wip/b-viewer`, head c09e83a, from 4f5be66, clean
  tree, pushed to `private`), package `internal/viewer` only: an origin joins only with a post number; files
  join two posts only when their file lists are identical; every list query in chunks of 400; a post page
  bounded at 500 files and 200 places with true totals; set sizes in `/api/stats`. **Its diff has NOT been
  read by a main session, and its numbers are the coder's own, not re-run:** on the real catalogue 143,294
  sets; the largest 332 posts (one sticker; it was 78,956); most files in a set 130; 7 sets over 100 posts;
  index 2.1 to 3.1 s (2.0 s before, not compared on the same runs); 200 post pages spread over the list:
  median 1.0 ms, worst 24.5 ms, 0 errors. `go test ./internal/viewer` passed (142.5 s); gofmt and vet clean.
  The coder's doubts: a change to a member post's file list rebuilds its set under a new set number; the
  "Showing N of M" lines on the post page were not seen in a browser; stickers still make sets of up to 332
  posts. Tests it changed to the new rule: all of `refresh_merge_test.go`, `TestNewPostMergesTwoOldSets`
  (renamed), `TestVariantWhyNamesTheRealLink`, the reference build in `reference_test.go`.
- **Rule B, asked for by the owner (11-14: "Add B at minimum"), not started:** on a post's page, gather the
  post plus the posts that directly share a file with it (one step, no chain), each file marked by where it
  came from, to flip through as one set; files in more than 20 posts (39 in the archive) pull in no
  neighbours; a step the owner clicks to go one further ("show what these overlap with"). The owner asked
  why not full merging (C): measured, it chains 5,082 posts across 168 chats; with "half of the smaller
  post" 2,341; with "subset" 1,720 (single-file posts bridge albums). Do not re-propose C. B is the next
  commit after A.
- **For the download session (not told yet):** `internal/telegram`'s forward-origin key without a post
  number is the bare sender: it is not a post's identity. Anything else that treats it as one (the
  catalogue's "same post" rung) should be checked.

## Next, in order
1. Read rule A's diff yourself (`git -C wt-b-viewer show c09e83a`: the set rule and its in-place update in
   `refresh.go`, the bounded page in `post.go`); no independent review needed for a page, per the start file.
   Its tests have run once already.
2. Build rule B the same way.
3. Rebuild the programs from `wt-b-viewer/archiver` (`go build -o` into `%LOCALAPPDATA%\tgarchive-b\bin\`,
   `./cmd/tgarchive`), then copy `tgarchive.exe` to `tgarchive-viewer.exe`: its own program name, off the VPN.
   Check it once with `-library` an empty folder (`%LOCALAPPDATA%\tgarchive-b\empty-library`),
   `-thumb-workers 0`, port 8799: timings and codes only, answers discarded, then stop it.
4. **The owner opens it:** `.\b\b-viewer.ps1 -Library '<the old library folder on the NAS>'` (port 8798, one
   thumbnail maker; the script is in the folder `b`, which git ignores). The owner says what is wrong.
5. Push `wip/b-viewer` to `private`, add it to `MERGE-QUEUE.md`.
6. Then the start file's items 2 and 3, and verify's 119 rows.
