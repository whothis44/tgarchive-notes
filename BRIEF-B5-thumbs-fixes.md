# Brief B5-T2: the fix round for `wip/b-thumbsbulk` after its independent look (viewer session B5, 11-15)

Same coder, same copy (`wt-b-faces`), same branch (`wip/b-thumbsbulk`, on top of e6fcb3ac), all earlier rules
(`BRIEF-B5-thumbs-bulk.md`: privacy, load, named tests, commits). **New rule: never prune or clear Docker's
caches, images or containers other than ones you made in this round by name** (the first round's
`docker builder prune -f` cleared the whole PC's build cache; other sessions use Docker here).
The review is `C:\Users\trabi\Claude\Projects\Telegram\wt-b5-review-T-scratch\REVIEW.md`: read it in full
first; its probes are beside it (read-only: take each as a test of your own that fails before your fix).
It found the split of `make`, two programs on one folder and stop and resume sound. The main session's
decisions, by its numbers:

- **1 (the one that matters most): the library-health rule when nearly every thumbnail is already
  there.** A thumbnail taken from a folder says nothing about the library, so the only library reads left
  are the files that could not be made, back to back, and 20 scattered missing files mark the whole
  library "files missing": the viewer's makers stop (asked tiles too) and the bulk run ends with a false
  sentence. Fix as the review proposes, in the one rule both use: when the streak or the window trips, do
  not stop at once; look at once at a few spread files that are known to be there (in the viewer,
  `recheck`'s own sample; in the bulk, files whose thumbnails exist). The library answers: the pending
  files are really missing, they get their `read` marks and the work goes on. The sample fails too: stop
  (bulk) or pause (viewer) as today. Bound the sample (a handful of opens, each with the library's usual
  bound), never on a request's path, and count it. This rewrites a reviewed rule: keep every existing
  health test passing by name and add: the viewer with the second folder full and 25 scattered missing
  files stays "ok" and marks them; a library that is really gone still pauses the viewer and stops the
  bulk run with no mark written; the bulk run a day later (marks aged) reaches the end.
- **2:** `CatalogueItems` takes only files whose location is the library (check the oldest schema the
  read-only door lets through has the column; if one has not, say what happens there). A file not found
  counts once towards the streak, not once per size. With 1 fixed, a cluster of the newest files missing
  no longer stops every run at the same place: the reviewer's probe as a test.
- **3:** `-write-list` refuses a target that is the catalogue, its `-wal` or `-shm`, and any existing file
  whose first line is not the list's own head; fixed sentences; nothing is replaced.
- **4:** the writer leaves out an item whose path the reader would refuse and says how many in its one
  printed line; the reader keeps refusing a list it did not write.
- **5 (the NAS limits):** in the bulk run, pictures over about 20 megapixels are decoded one at a time
  whatever the workers; a flag `-max-megapixels N` (default: the makers' own bound) leaves larger pictures
  alone with no mark and a count of their own ("left for another machine"), so the PC's viewer makes them
  later. The compose file sets it and `mem_limit` so that one decode at that bound fits with room (state
  the arithmetic in a comment from the reviewer's measured bytes a pixel); `pids_limit` 256. Measure peak
  memory of one such decode on this PC if a test can (Go's own numbers, not a container). The README says
  what exit code 137 means and the one setting to change. A `noframe` mark from the NAS stays as it is
  (it counts for a day by its own date, then the PC tries the file itself): say so in the README.
- **6:** `adoptOwn` opens the file and reads its header (a JPEG, at least 1 by 1, inside the box) before
  taking it; the same in `put`'s take-the-other-program's-file path.
- **7:** `-out` is refused when it holds the library as well as when it is inside it; the cache's start-up
  walk never deletes or lists anything outside a thumbnail folder's own layout. Check `Config.ThumbsFrom`
  against the library the same way (refused when either holds the other).
- **8:** `wholeJPEG` counts the scans before decoding and refuses more than 32.
- **9:** flag errors of `tgarchive thumbs` are fixed sentences naming the flag only; nothing typed is
  printed back (the flag set's own output discarded). The leak scan gets cases with a path typed as a
  number, as an unknown flag and as a stray argument.
- **10:** the README is split in two: "For whoever builds the image" (a session on this PC, any shell,
  placeholders for the folders, no claim that Go is on PATH) and "The owner's steps" (start from the image
  file and the three placeholders, in the NAS's Docker app; no command that depends on the folder it is
  started in; no volume or share name of any real NAS).
- **11:** the counts add up and each says what it counts: `done` equals the sum of the outcome counts; a
  skipped duplicate is its own count, not "already there"; `-limit`'s help says what it bounds, and the
  late `read` marks do not push it over; no doubled prefix on the list-changed line; in the viewer's
  numbers a thumbnail taken from a folder and a mark taken from the second folder each get a count of
  their own and are not counted as the viewer's own work or failure.
- **12:** the second folder's reachability look is done outside the lock by one looker (the others take
  the last answer), and an open error there that is not "does not exist" means "unreachable until the
  next look": a hanging share costs one maker one wait, not every maker one per file.
- **Also:** one bulk test in which ffmpeg makes the frame (a real invented clip with no poster,
  `FFMPEG_PATH` set; skipped with a fixed reason where there is no ffmpeg).

## At the end, once
`gofmt -l`; `go vet ./internal/viewer ./cmd/...`; your named tests, the reviewer's cases as tests, and every
existing health, paced, thumbnail and blip test by name; `go test ./cmd/tgarchive ./cmd/tgarchive-window
-p 1`; `CGO_ENABLED=0 go build ./...` and the Linux build. No Docker run is needed this round. Hand back: the
commits (pushed) and the head; what was done for each of 1 to 12 and any difference with its reason; the
health rule as it now reads, in a few lines; the owner's command lines again where they changed; what you
ran and what it printed; what you did not test; doubts. Commit-ready, nothing left running, the copy clean.
