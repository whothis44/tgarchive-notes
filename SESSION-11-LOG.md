# Eleventh archiver session: progress (started 2026-11-14 21:56 local)

## What the old app already knows: download parts, waits and the window (written before any proposal)

Read in full by this session, itself: `TRIED-BEFORE.md` (all 27 sections), `WINDOW-EVIDENCE.md`,
`LESSONS-ix12.29-servers.md`, `ANSWERS-for-archiver-6.md`, `-8.md`, `-9.md`, the last 90 lines of
`SESSION-10-PROGRESS.md`, and in the old app's code (`wt-v12.31/core-service/internal/telegram`)
`attachment.go` `Invoke` / `invokePart` and `floodguard.go` `invokeGate`.
**Not read yet by this session:** `LESSONS.md`, `TELEGRAM-FACTS.md`, `COPY-CHECKS-STUDY.md`,
`LESSONS-ix12.30-live.md`, `LESSONS-viewer-ix12.32.md`, answers 4, 5 and 7; the rest of `pacer.go`,
`parallel_download.go`, `download/library.go`, `engine/controller.go` and the copies files. They are
read before anything is proposed in their areas (copies, viewer, staging, the queue).

**The old app's numbers, server 2, hours without the speed limit (old account):**
- Speed per part 2.3 to 4.4 MB/s; one part brings 3.5 to 4 MB/s on any server; server 2's best hours
  5.2 to 7.5 MB/s in all (it was short of files most hours, 0.6 to 2.5 parts in flight).
- A server's speed is about min(parts x 4 MB/s, a ceiling). Server 1's ceiling about 12 MB/s at 2 to 3
  parts; more parts brought the same bytes. Server 2's ceiling on the old account was never seen (unfed).
- Plain waits: one per 2,484 MB on server 2 (worst hour one per 270 MB); 1 to 2 s each; they do not
  follow the window between 2 and 3 parts, nor files started.
- Under the speed limit: more than 2 parts brought only more waits (4 parts 810 waits for 622 MB; 2 parts
  422 for 612).

**The new app's numbers, server 2, test account, three runs of the same chat (17.8 GB):**
- 5.6 / 4.85 / about 4.9 to 5.0 MB/s at 2 parts: inside the old app's range for that server. Not a defect.
- Plain waits one request in 14 / 14.5 / 7.5. That rate is far above the old account's (one per 14 MB
  against one per 2,484 MB) and is not explained: another account, another library version, no per-file
  message re-read. The third run settled what it costs: with the slot freed and more requests out, the
  waits doubled and the bytes stayed. So on this account the server gives about 5 MB/s whatever is asked.

**What the old app does with a part that is told to wait (by its code, read here):**
`invokePart` takes a place in the server's window (`pacer.acquire`), calls `invokeGate`, and gives the
place back (`pacer.release`) only when `invokeGate` returns. `invokeGate` sleeps the stated wait plus 1 s
(`floodGateMargin`) inside that call and asks again, at most 3 plain waits on one request, then the file
is tried later. **So a waiting part keeps its place in the window**, nothing in flight is cancelled and
the connection is kept. The only case where a part gives its place back is a lost connection being
replaced.

**The rule that follows (no new scheme):** the new engine's default goes back to the old app's way, a
waiting part keeps its slot (`SleepKeepsSlot` true; the flag reversed so that freeing the slot is the
comparison switch). The number that pays for it: 2,940 waits against 1,261 to 1,359 for the same bytes.
The upward-only window rule stays: it tried a third part on server 2 once, saw speed per slot fall from
3,051 to 2,162 KB/s and waits double, and gave it back, which is what `WINDOW-EVIDENCE.md` asks of it.
Nothing else in the download path is changed.

## Log
- 21:56: read the hand-over. State found: `repo-archiver` clean on a28700f, equal to `private`; 15
  copies of the repository exist; nothing running against Telegram by the hand-over's word (not
  checked by process list).
- 22:14: **the owner said yes to both** (the default back to keeping the slot; the documents). Done in
  `repo-archiver`'s working tree, NOT committed: the run command's `-sleep-keeps-slot` is on by default
  (`internal/collector/command.go`; comments in `collector.go` and `engine/engine.go`; the engine's
  field and its tests untouched, so no concurrent code changed and no race run is due); a new test
  `TestSleepKeepsSlotFlagDefault` (`internal/collector/keepslot_flag_test.go`), **not run yet**;
  `FEATURES.md` fourteenth round, `TRIED-BEFORE.md` section 28, the handoff's first block, three roadmap
  rows. gofmt clean on collector and engine. **Held: the PC had 0.7 GB of memory available** (under the
  2 GB floor), so no go test, vet or build was started. When memory allows, one command at a time
  (`GOGC=25 GOMAXPROCS=1`, `-p 1`): `go test ./internal/collector -run TestSleepKeepsSlotFlagDefault`,
  `go vet ./internal/collector ./internal/engine`, commit (code, then documents), push to `private`,
  build the collector (keep the present one as `...-a28700f.exe.bak`).
- 22:14: a review session wrote `BOARD.md` (22:15) and messaged this session: the owner is said to have
  decided that the old account does not move to the new app, and this session is proposed as the
  integrator. Neither is taken from the message: asked of the owner. The documents written above do not
  mention it yet.
- 22:32: **committed, pushed, built.** The owner freed memory (4.3 GB available). The named test passed,
  `go vet` on collector and engine clean, gofmt clean. Two commits on the branch, pushed to `private`:
  64dcbc0 (the default) and 1010e11 (the documents). The installed collector is built from 1010e11 (the
  build of a28700f kept as `...-a28700f.exe.bak`); its help shows `-sleep-keeps-slot` default true.
  No real run was made with it. Open with the owner: the board's "no switchover" direction and who the
  integrator is (a peer session's word, to be confirmed first-hand); then the roadmap and the handoff
  rewritten for it, and the two waiting merges (`wip/b-bringin`, `wip/b-viewer`).
- 22:37: **the owner: this session is the integrator, and the old account does not move** (both said here,
  first-hand: "Yes to both"). Done and pushed: `ROADMAP.md`'s order rewritten for "no switchover" and
  `HANDOFF.md` 0c folded to one block, the dated blocks unchanged in `HANDOFF-LOG.md` (bc81601);
  `wip/b-bringin` merged as d08e9fa (its code diff read by me: sound; its two packages' tests, gofmt and
  vet passed on the merged tree; verify's fix still owed by B). `BOARD.md`: my rows brought up to date.
  `CLAUDE.md`'s archiver section was rewritten by the review session with the owner's yes: read again.
- 22:37: `wip/b-viewer`: `refresh.go`'s set rule read (posts join by the very same files or an origin that
  names one post; a set whose post's files changed is taken apart and regrouped; posts without files
  join nothing): sound by reading. It is squash-merged into `repo-archiver`'s tree, **staged and NOT
  committed**, and the full runs are going (`runs-11/`: whole Windows tests and the race detector on
  `internal/viewer`). If this session died: read `runs-11/*.log`; both "ok" and `win-gofmt.log` empty,
  then commit (message: session B's viewer piece, set rules A and B, 0e80f24) and push; otherwise
  `git -C repo-archiver reset --hard d08e9fa` is NOT to be run without looking: the staged merge is the
  only uncommitted thing there.
- 22:43: **the viewer is merged and pushed** (d60766a; `runs-11/`: whole tests 178 s, race 317 s, gofmt
  empty), then `FEATURES.md` with the newly-joined rule and "no switchover" (38842d2), then the handoff
  and roadmap brought up to date (5315ceb, the branch's head, equal to `private`). The checkout is clean.
  Found by reading and written on the board (message 1), the handoff and the roadmap: the catalogue's
  "same post" rung holds on a bare-sender origin. Asked of the owner: an Opus coder for that fix.
  Session B's `wip/b-viewer` has moved to de8f5c3 (not on the queue yet). Nothing is running.
- 22:47: **the owner: start the "same post" fix.** What the old app already knows (read by me:
  `COPY-CHECKS-STUDY.md` in full, `TRIED-BEFORE.md` 6; the old app's code searched for the origin's
  uses): the old app forms the same origin key (`attachment.go` `forwardOrigin`) and **makes no hold
  from it**; its holds come from the look-alike rule, frames and albums, each with evidence. The new
  app's rung 4 is its own. Numbers, read-only: on session B's brought-in catalogue 311,091 messages
  carry an origin, 305,112 of them the bare sender; 19,812 files are held as "same post", **all 19,812
  from a bare origin**; on the four test catalogues 0. Brief: `BRIEF-D1-samepost.md`; copy
  `wt-samepost` (branch `wip/samepost-2026-11-14`, from 5315ceb); an Opus coder at high effort.
  If this session died: `git -C wt-samepost log --oneline -2` and its
  `archiver/docs/progress/samepost-REPORT.md`; else a fresh Opus coder on the same brief.
- 22:55: **the "same post" fix is merged and pushed.** The coder handed back e611e5e (one guard in
  `samePost`, the predicate `namesPost`, four tests, a report); I read the diff; the catalogue's whole
  tests passed on the merged tree (226 s), gofmt and vet clean; no race run (no concurrent code). The
  handoff and roadmap say so. `wt-samepost` is removed (its branch stays). Left open: holds made before
  the fix stay held (no pass judges them again); B is asked on the board to run the bring-in afresh.
  The installed collector is rebuilt from 8c0335e (the build of 1010e11 kept as a `.bak`).
- 23:31: the board's new rule (the owner, 23:30: a listed feature is a standing request). Done as
  integrator: every roadmap row has an owner track (76 rows), a new row for "a chat collects only chosen
  topics", and a "core" track on the board with no session (sign-in, reader, engine, staging, operations:
  those rows had no owner). Pushed. Two tracks are the owner's to staff: core, pages and chats.
- 23:32: **STATE FOR A TAKE-OVER (kept current; the integrator's session).**
  - Running: nothing of mine (no agent, no test run, nothing against Telegram).
  - `repo-archiver`: branch `claude/charming-feynman-vm2xia` at e3a9df9, equal to `private`, 0 uncommitted
    files. Nothing half-merged. The installed collector is built from 8c0335e (same code as the head;
    later commits are documents).
  - Merged tonight: the slot default, the bring-in, the viewer's set rules, the "same post" hold fix.
    Documents current: `ROADMAP.md` (order for "no switchover", an owner track per row), `HANDOFF.md`
    0c (one block), `FEATURES.md` section 12 fourteenth round, `TRIED-BEFORE.md` 28.
  - Waiting to merge: nothing. Expected: verify's fix and newer viewer pieces from B2; the look-alike
    rule from session C; the mirror's first step from session M; a pages session is being started.
  - Next step: when a branch appears on the board or in `MERGE-QUEUE.md`: read its risky part, tell
    the owner the full-run plan (whole tests of changed packages; race only where concurrent code
    changed), run once, squash-merge, push, update board, roadmap rows and the handoff's block.
  - Read the board and `CLAUDE.md`'s archiver section first (both changed at 23:32).
- 11-15 08:38 (11-15, a fresh session took over as the integrator): read the board, this file, the merge queue, the
  viewer lessons file. `repo-archiver` was clean on e3a9df9, equal to `private`. **In hand: the merge of
  `wip/b-viewer` c4bb582** (merge queue entries 3 and 4; `internal/viewer` only, no schema step). Its risky
  part read by me (`refresh.go`, `viewer.go`, `faces.go`: the writer is touched only under the viewer's
  lock, the face progress is a copy behind an atomic pointer, a full read hands the faces on): sound by
  reading. The diff 0e80f24..c4bb582 is applied to `repo-archiver`'s tree, **staged and NOT committed**;
  the full runs go to `runs-11b/` (whole tests and the race detector on `internal/viewer`). If this
  session died: read `runs-11b/*.log`; both "ok", "exit 0" and `win-gofmt.log` empty, then commit
  (session B's viewer piece: sidebar, saved copy, faces, chat order; c4bb582) and push to `private`;
  the staged merge is the only uncommitted thing there.
- 11-15 08:44: **the viewer piece is merged and pushed** (1d905f9; `runs-11b/`: whole tests 163 s, race 312 s,
  gofmt empty, vet clean), then the handoff and the roadmap (4f1992e, the branch's head, equal to
  `private`; the handoff's schema line now says 13 and 14 are taken, next free 15). Board: message 4
  answered (session C hands the engine's "hold unless same" flag over as its own branch; review and a
  race run of the engine at its merge); the "protected" flag given to the mirror track; the waiting list
  emptied. The installed collector is NOT rebuilt (viewer code only; it is still 8c0335e's code).
- 11-15 08:44: **STATE FOR A TAKE-OVER.** Running: nothing of mine. `repo-archiver`: 4f1992e, equal to
  `private`, 0 uncommitted files. Waiting to merge: nothing. Expected next: the look-alike rule and
  "a held copy waits" from session C (running); the mirror's first step after its review and fixes
  (its session stopped 11-14 23:34, the review report was never written); thumbnails on request and the
  listed filters from B2 (stopped; `wip/b-thumbs` 255e82c is work in progress, `wip/b-filters` holds
  nothing yet); the pages session stopped before any brief. Next step: as in the block of 11-14 23:32.
- 11-15 08:58: the review session's message (the owner's rule, 08:56, read on the board and in `CLAUDE.md`):
  building sessions report to the integrator through the files; the integrator tells the owner how the
  tracks stand; one fixed start file `START-INTEGRATOR.md` (corrected: the full-runs arguments and
  `go vet`); `START-SESSION-12.md` removed. **Progress review, against the disk:** main branch 4f1992e,
  equal to `private`, clean. Viewer (B3): thumbnails `wip/b-thumbs` local 68e2ca4, `private` at 255e82c,
  3 files uncommitted; filters `wip/b-filters` c0b2009 pushed, 5 uncommitted; verify's fix `wip/b-verify`
  at the head, not pushed, 5 uncommitted: three coders at work. Copies (C): look-alike 97f7f55 pushed,
  clean, reviewed, its full runs going; held piece 94e0775 pushed, clean, reviewed; a combined copy
  `wt-copies-1` being put together (17 uncommitted, not pushed). Mirror (M): 4fe8653 pushed, reviewed
  (six defects), fix round's coder at work (7 uncommitted). Pages (P): `wip/pages-topics` 9a3da9e pushed,
  coder at work; schema step 16. Core: no session, the owner said to wait. Waiting for the owner: board
  items 7 (the mirror's design: recommended to agree as written) and 8 (the real step, not ready).
  To check at the look-alike merge: real-archive figures were in a test comment, two constants and a
  report on that branch (counts, said replaced in 97f7f55); a squash merge leaves the old commits out.
  Next step: wait for the first merge-queue entry.
- 11-15 10:25 (a fresh session took over as the integrator, started with `START-INTEGRATOR.md`): read the
  board, this file, the merge queue, the handoff's block. **Progress review, against the disk (10:26):**
  - Main branch 4f1992e, equal to `private`, 0 uncommitted, nothing staged. 13 copies. 8.8 GB free, CPU 41%.
  - **Seven branches wait to merge, every one pushed and equal to `private`, every copy clean:**
    `wip/mirror-history` 9f09e86 (brings `wip/mirror-step1` 85bd550; schema 13), `wip/copies-1` 42ea758
    (schema 14), `wip/copies-2b` 344bf94 (schema 15), `wip/copies-3` 3e7de63, `wip/pages-topics` 8fbb765
    (schema 16), `wip/b-viewer` 1f8b681 (34 commits; race run of the viewer due), `wip/b-verify` 0f7c44d.
  - Viewer (B3): last entry 10:17; two coders at work, 3 uncommitted files each (`wip/b-probable`,
    `wip/b-lan`: local only, not pushed yet, 10 minutes old). Copies (C): last entry 10:24; one coder
    (`wip/copies-5`, 6 commits local, not pushed; `wip/copies-4` af3bb5a pushed). Mirror (M): last entry
    10:21; one coder (`wip/mirror-reads`, 10 uncommitted, not pushed). Pages (P): last entry 10:26;
    `wip/pages-notadded` f350757 pushed, clean, its full runs next. Core: no session (the owner: wait).
  - Saving as they go: all four (a notes commit every 2 to 10 minutes since 08:44). Not pushed as work in
    progress yet: the four coders' branches named above.
  - **Found: the notes commit of 10:24 dropped four entries from `MERGE-QUEUE.md`** (5, 6, both 7s; a
    whole-file rewrite from an older copy). Restored at 10:28 from the commit before; entry 6
    (`wip/b-verify`) and the first 7 (`wip/mirror-step1`) are live.
  - Waiting for the owner: board items 7 (the mirror's design, corrected by the owner at 10:15), 8 (the
    real step: after the merge), 9 twice (delete two superseded branches; the mirror's pace), 10 (a
    native window for the viewer). For the integrator: board messages 6 (who builds the collector's side
    of a read approved from the page), 7 (the engine's "hold unless same"), 9 (the collector's loop for
    the automatic mirror), 5b (`internal/fabricate` has no owner); FEATURES lines owed (item 10's three
    values, the cusp sampling, the mirror reads the chat itself).
  - **Next step:** read each branch's risky part and the board's lessons for its step; put the seven on
    the main branch as local commits in the order mirror, C1, C2, C3, topics, viewer, verify (schema 13
    to 16 renumbered in the two constants each); the full runs once on the combined tree; push.
- 11-15 10:34: **the seven are on the main branch as LOCAL commits, NOT PUSHED** (`repo-archiver`, 0
  uncommitted; `private` is still 4f1992e): 6b8f72f mirror (schema 13; both reviews copied to
  `docs/review`), 2879bba C1 (schema 14), 117ac68 C2 (15), 8e284e9 C3, b379286 topics (16), 60f7712
  viewer (`REVIEW-B3-viewer.md` copied to `docs/review`), 3044745 verify. Read by me before each:
  the lessons the board names for steps 1 to 3 (in full), `internal/mirror/step.go`, rung 6 and
  `schema_lookalike.go`, C2's catalogue, Supply and Checker changes with `checkpen.go`, the topics
  branch's lines in the ladder, `tgrows.go` and `staging.go`, the viewer's `launch*.go` and
  `handleOpen`, verify's diff. Conflicts, resolved by hand: the steps table and `SchemaVersion` in
  `catalog.go` (three times), one test line in `schema12_test.go`, and `wantedAsMain` in
  `ladder.go` (copies' `markCheckFirst` kept in front of topics' `wantedAsMainIn`; one call of
  `chatWants` in C2's block given the topic argument). `go build ./...`, `go vet` on catalog,
  server and `cmd/tgarchive`, and gofmt are clean on the combined tree.
  **A gap left, to tell C and P:** files made collected in bulk by a topic action (`wantedAsMainIn`
  for a set) are held as probable copies, not marked for the exact check first; safe (held), not
  what C2 does for one file.
  **Next step:** the full runs once into `runs-11c/` (`ix-tools/full-runs.sh repo-archiver runs-11c
  "catalog collector supply viewer bringin mirror exact server fabricate footage lookalike" "viewer"`),
  then the small packages (`collector/faketg`, `exact/wire`, `cmd/...`) and `go vet`; all "ok" and
  "exit 0" and `win-gofmt.log` empty: `git push private claude/charming-feynman-vm2xia`. If this
  session died: read `runs-11c/*.log`; a failure is looked at before any push; nothing else is
  uncommitted.
- 11-15 10:38: **the full runs are going since 10:34** (`runs-11c/`, background command of this session;
  the race container of `internal/viewer` beside the Windows tests). Meanwhile, uncommitted in
  `repo-archiver` (documents only, to commit after the code is pushed): `ROADMAP.md` (the rows of what
  merged, new rows for the owner's requests of 11-15), `FEATURES.md` section 12 fifteenth round,
  `HANDOFF.md` 0c (the merged pieces, schema 16). Board: answers to messages 5 to 9 and new messages 10
  to 12 (notes commit 0b4660e). **A second batch waits:** `wip/pages-notadded` f350757 (merge queue
  entry 11, on top of topics; its catalogue file and the server's kept counts read by me from the
  branch): apply `git diff wip/pages-topics wip/pages-notadded` after the first push, then whole tests
  of catalog, server, fabricate and the race detector on server (the shared kept counts).
  After the push: rebuild the installed collector (no `tgarchive*` process is running; keep the present
  build as `tgarchive-collector-8c0335e.exe.bak`). Then ask the owner the four open decisions together
  (the mirror's first real step, its pace, deleting the superseded branches, a native viewer window).
- 11-15 11:02: **THE FIRST BATCH IS MERGED AND PUSHED: head a57a8fd, equal to `private`, 0 uncommitted.**
  The full runs (`runs-11c/`, 10:34 to 10:52): whole tests ok for catalog 285 s, supply 104 s, bringin
  41 s, fabricate 14 s, mirror 10 s, exact 8 s, server 7 s, footage, lookalike; gofmt empty. Three
  logs ended FAIL, each on one test whose expectation the combined tree made untrue, no other failure
  and no data race: the collector's `TestMirrorCommandOlderCatalogueNo` (expected "steps it to 13";
  the catalogue goes to 16) and the viewer's `TestWallDependencies` in the Windows run and in the race
  run (the catalogue now imports `internal/lookalike`). Fixed in 167e477 (test files only), both passed
  by name; the whole packages were not run a second time (every other test had passed in the same
  runs: collector 387 s, viewer 161 s, viewer under the race detector 472 s). Then `collector/faketg`,
  `exact/wire` and `cmd/...` tests ok; `go vet` clean on every changed package. Documents: a57a8fd.
  **The owner decided (asked together, between 10:39 and 11:00):** the mirror's first real step after
  this merge; keep the mirror's pace defaults for the first runs; delete the four superseded copies
  branches on `private` and the two local copies after the push; the viewer stays pages, a native
  window is decided later. Board: my row, the waiting list, the schema numbers and items 7 to 10.
  **Next, in this order:** (1) the second batch: `wip/pages-notadded` f350757 (entry 11) and
  `wip/copies-4b` (entry C4), applied as local commits, the full runs once, push; (2) rebuild the
  installed collector from the head (keep the present build as `tgarchive-collector-8c0335e.exe.bak`),
  then change board item 8 to READY; (3) delete the four branches on `private` after comparing their
  trees with what is merged, and remove `wt-copies-lookalike` and `wt-copies-heldwait`.
- 11-15 11:04: **the second batch is on the main branch as two LOCAL commits, NOT PUSHED** (`private` is
  a57a8fd): d4a50e2 chats not added yet (`git diff wip/pages-topics wip/pages-notadded`, applied clean)
  and 849c506 the frame check's ffmpeg part with the second round (`git diff wip/copies-3
  wip/copies-4b`, applied clean; read by me: `ffmpeg.go`, the range server's outline). **Its full runs
  are going since 11:03** into `runs-11d/` (whole tests of catalog, server, fabricate, footage; then
  `internal/footage/ffmpeg` with `FFMPEG_PATH` set to the 9.0.2 build, and `go vet`; no race run: the
  server's kept counts and the ffmpeg range server were raced by their sessions on this same code).
  All "ok" and "exit 0", gofmt empty: push. If this session died: read `runs-11d/*.log` first.
  **Done with the owner's yes:** the four superseded branches are deleted on `private` (their heads, for
  the record: `wip/copies-lookalike` 97f7f55, `wip/copies-heldwait` 94e0775, `wip/copies-2` 3536948,
  `wip/copies-footage` 1551cf2; compared first: three trees identical to the merged branches', the
  fourth's lines all in C2 but 2 of 479, changed by later fixes). The local branch names stay, not
  pushed. The copies `wt-copies-lookalike` and `wt-copies-heldwait` are removed (both were clean).
  **Still to do:** push the second batch; rebuild the installed collector from that head; board: item 8
  READY, the "Listed and unbuilt" rows of what merged struck, the waiting list.
- 11-15 11:14: **THE SECOND BATCH IS MERGED AND PUSHED: head e96f624, equal to `private`, 0 uncommitted.**
  `runs-11d/` (11:03 to 11:12): whole tests ok for catalog 343 s, server 8 s, fabricate 16 s, footage
  2 s, `footage/ffmpeg` 76 s (ffmpeg 9.0.2 named by `FFMPEG_PATH`, 0 tests skipped); gofmt empty, vet
  exit 0. Commits: d4a50e2 chats not added yet, 849c506 the frame check's ffmpeg part with the second
  round, bcb6df0 and e96f624 the roadmap and the handoff (its line on the installed collector had been
  garbled since an earlier session; rewritten).
  **The installed collector is rebuilt from 849c506 at 11:13** (no collector was running; the build of
  8c0335e kept as `tgarchive-collector-8c0335e.exe.bak`; its usage lists `mirror`, `mirror -h` shows
  `-batches`, `-pause`, `-per-hour`). A `tgarchive.exe` (the app or viewer, not the collector, not from
  the installed folder) was running since 11:12: another session's or the owner's, not touched.
  Board: my row, the waiting list, nine "Listed and unbuilt" rows marked merged, item 8 READY (the
  mirror session is to check `a3\a3-mirror.ps1` against this build before the owner runs it).
  **Running: nothing of mine. Listed since 11:14 and next:** `wip/b-viewer` 11385ab (the second entry
  11 of the merge queue: probable copies under one tile and a review page; four commits on the merged
  1f8b681; `internal/viewer` only; concurrent code changed: whole tests and the race detector on the
  viewer at the merge). How: `git diff 1f8b681 11385ab | git apply --3way --index` in `repo-archiver`,
  read `resolveVerdicts`/`setVerdict` and the fold in the overlap cache, then
  `ix-tools/full-runs.sh repo-archiver runs-11e "viewer" "viewer"` (about 3 and 8 minutes), commit, push.
- 11-15 11:16: the diff 1f8b681..11385ab of `wip/b-viewer` is applied to `repo-archiver`, **STAGED AND NOT
  COMMITTED** (22 files, `internal/viewer` only; its tree equals the branch's but for the wall test's
  line of 167e477). Read by me: `verdicts.go` (verdicts written to the viewer's own `decisions.sqlite`
  only, the catalogue read-only; one lock `vmu` for the update's resolution and a request's verdict).
  Its runs go to `runs-11e/`, one after the other because 4.9 GB is free: the viewer's whole tests,
  then the race detector on it. If this session died: read `runs-11e/win-viewer.log` and
  `runs-11e/race-viewer.log`; both "ok" and "exit 0", gofmt empty: commit (the viewer's probable
  copies under one tile and the review page; `wip/b-viewer` 11385ab) and push; the staged diff is the
  only uncommitted thing in `repo-archiver`.
- 11-15 11:28: **THE VIEWER'S PROBABLE COPIES ARE MERGED AND PUSHED: head 298cf1f, equal to `private`, 0
  uncommitted** (c3e9952 the code, 298cf1f the roadmap and the handoff). `runs-11e/`: the viewer's whole
  tests 198 s ok, the race detector 504 s ok, gofmt empty, vet exit 0. Nothing is staged.
  **Listed since 11:24 and next: `wip/b-viewer` 83924a9, the home-network mode** (merge queue entry 12;
  also `wip/b-lan`; it had its own security review). How: read the entry, the security review's report
  and the listener, sign-in and session code myself; `git diff 11385ab 83924a9 | git apply --3way
  --index`; the viewer's whole tests and race run into `runs-11f/`; commit; push; the roadmap's row
  "Use from other devices at home". Also on the board since 11:26: the mirror session took schema
  number 18 (check who has 17 before the next schema merge).
- 11-15 11:30: the diff 11385ab..83924a9 of `wip/b-viewer` (the home-network mode, merge queue entry 12) is
  applied to `repo-archiver`, **STAGED AND NOT COMMITTED** (33 files: `internal/viewer`, and
  `cmd/tgarchive`'s `viewer.go` with two echo files; the viewer's tree equals the branch's but for the
  wall test's lines of 167e477). Read by me: `REVIEW-B3-lan.md` in full (merge switched off: yes; 4
  confirmed and 3 probable findings, 12 design points, all fixed by the entry's word), `access.go`
  (a class per route, required at registration), the guard `lanServer.ServeHTTP` (private address, TLS,
  host, other-site rules, the session, then the class; `classLocal` refused: prefs, open in the player,
  unhide all, stats). Off unless the viewer is started with `-lan`. Its runs go to `runs-11f/`, one
  after the other (4.2 GB free, CPU 85%): the viewer's whole tests, the race detector on it, vet. If
  this session died: read `runs-11f/*.log`; all "ok" and "exit 0", gofmt empty: commit (the viewer
  from other devices at home, off by default; `wip/b-viewer` 83924a9) and push; then the roadmap's row
  "Use from other devices at home" and the board. Switching it on is the owner's, after B3 shows
  where its key and password files live (the review's F5).
- 11-15 11:46: **THE HOME-NETWORK MODE IS MERGED AND PUSHED: head 6f17c7f, equal to `private`, 0 uncommitted,
  nothing staged.** 67ed605 the code (off unless `-lan`), bfc3454 a test fix, 6f17c7f the roadmap, the
  handoff and the security review as `docs/review/viewer-lan-2026-11-15.md`. `runs-11f/`: the viewer's
  whole tests 209 s ok; under the race detector (492 s) one test failed, `TestLANStreamsGapsConnections`
  (it judged a gap of 300 ms of real time; no data race); with the test changed to move its clock it
  passed 3 of 3 on Windows and 3 of 3 under the race detector, by name; vet and build exit 0.
- 11-15 11:46: **STATE FOR A TAKE-OVER.** Running: nothing of mine (no agent, no test run, nothing against
  Telegram). `repo-archiver`: `claude/charming-feynman-vm2xia` at 6f17c7f, equal to `private`, clean.
  The catalogue is at schema step 16 (17 taken by copies, 18 by the mirror, on the board).
  Merged today, in four batches, each read by me and run once on the combined tree: the mirror command
  with history; the look-alike rule; held copies wait with same size to the exact check first;
  `internal/footage` and its ffmpeg part with the second round; topics on the chat's row; chats not
  added yet; the viewer's listed filters, probable copies and home-network mode; verify's fix.
  The installed collector is the build of 849c506 (8c0335e's kept as a `.bak`); later commits changed
  the viewer and documents only, so it is NOT rebuilt again.
  The owner decided (asked together): the mirror's first real step after the merge (board item 8 is
  READY; the mirror session checks `a3\a3-mirror.ps1` against the build first), the mirror's pace
  defaults kept, the four superseded copies branches deleted (done), a native viewer window later.
  Waiting to merge: nothing. Expected next from the tracks: the mirror's reading piece (its full runs
  going; `wip/mirror-reads2`), the automatic mirror in the collector's loop (schema 18; an independent
  review and the race detector on the collector at the merge), copies' step at save with schema 17
  (`wip/copies-7`) and the engine's "hold unless same" (review and the race detector on the engine),
  the viewer's "no faces".
  Open, known: board messages 10 to 12 and my two of this hour (the schema step and the owner's viewer
  catalogue; the bulk topic action's gap for copies; a test of pages that judges a real second).
  Next step: as `START-INTEGRATOR.md` says, when a branch appears on the queue.
- 11-15 14:20: **A NEW INTEGRATOR SESSION (session 12 by count; this file is carried on).** Started by the owner at
  14:18 with `START-INTEGRATOR.md`; the same message also carried the copies take-over line: asked of the
  owner, the integrator's job first. **The review, against the disk:** main branch 6f17c7f equal to `private`,
  clean, nothing staged. Waiting to merge, all pushed, their copies clean: `wip/mirror-reads2` 99b71c3 (M3),
  `wip/copies-7b` 40d570c (C5, schema 17), `wip/b-viewer3` 16376c9 (entry 15; the viewer's race run due).
  Mirror: the one running session; its settle fix round is 13 files uncommitted in `wt-mirror-auto` on the
  pushed d5a4a7c. Viewer (ended 13:32), copies (12:13), pages (10:32): no session, everything pushed,
  nothing running. Core: no session. PC: 3.7 GB free, CPU 40%.
  **Next step:** read the lessons the board names for steps 1 to 3 and the risky part of each diff; apply
  the three diffs to `repo-archiver`, staged; the full runs once on the combined tree; commit, push.
- 11-15 14:21: **THREE BRANCHES ARE APPLIED TO `repo-archiver`, STAGED AND NOT COMMITTED** (79 files): `git diff 3044745
  99b71c3` (M3, the mirror reads the chat itself), `git diff e96f624 40d570c` (C5, the step at save, schema 17),
  `git diff 6f17c7f 16376c9` (entry 15, the viewer). One conflict, resolved: `mirror_cmd_test.go`, both sides had
  fixed the same line to name `catalog.SchemaVersion` (the main branch's kept). The combined tree builds, gofmt
  empty. Read by me first: TRIED-BEFORE in full; `atsave.go` and every non-test line of C5; `read.go` and the
  command's changes of M3; the makers' diff of the viewer. **Full runs into `runs-12a/`:** whole tests of catalog,
  collector, supply, mirror, exact, server, viewer, bringin, one after another (memory: 3.7 GB free), then the
  race detector on the viewer only (its makers and a new goroutine changed; the supply's claim path was raced
  by session C on this same code, 878 s; M3 adds no concurrent code), then vet. If this session died: read
  `runs-12a/*.log`; all "ok" and "exit 0": commit as three commits (M3, C5, the viewer) and push.
- 11-15 14:37: **the owner decided (asked directly, since the start message carried both lines): this session is the
  integrator AND runs the copies track.** Its copies work is logged in `SESSION-COPIES-PROGRESS.md`; the reviews of
  copies' pieces stay independent agents. The full runs of the staged batch are going since 14:22 (`runs-12a/`).
  Document edits for the batch are made in `repo-archiver/archiver/docs` and NOT staged (`ROADMAP.md`,
  `HANDOFF.md`, `TELEGRAM-FACTS.md` section 11: the mirror's two real runs): they are committed after the code.
- 11-15 14:45: **the full runs of the staged batch (`runs-12a/`), so far.** Whole tests ok: catalog 351 s, supply 134 s,
  mirror 41 s, exact 8 s, exact/wire and the commands, server 7 s, viewer 191 s, bringin 68 s; gofmt empty; vet
  exit 0. **Two things of mine in the merge, both fixed in the staged tree:** (1) my resolution of the one
  conflict left `fmt` unused in `mirror_cmd_test.go` (the collector's tests did not build): the branch's line
  is taken instead; the collector's whole tests are running again (`runs-12a/win-collector.log`). Lesson: compile
  the tests (`go vet`) before the long runs, not after. (2) The viewer's race run (490 s): no data race; one
  test failed, `TestFrameFailureWords`: it gave the stand-in for ffmpeg (the test binary started again) one
  second, and under the race detector the start takes longer; now ten seconds; running 3 times by name under
  the race detector (`runs-12a/race-viewer-fix.log`). **Still staged, not committed.** If this session died:
  both logs "ok" and "exit 0": commit as three commits (M3, C5, the viewer with the test's change) and push.
- 11-15 14:50: **THE BATCH IS MERGED AND PUSHED: head f0e3f0c, equal to `private`, 0 uncommitted, nothing staged.** e0db6e9 the
  mirror reads the chat itself; 7ebed87 the step at save and the release on record (schema 17); ae87e10 the
  viewer's branch with the test's ten seconds; f0e3f0c the documents (roadmap, handoff, `TELEGRAM-FACTS.md`
  section 11, the mirror piece's review as `docs/review/mirror-reads-2026-11-15.md`). `runs-12a/`: collector
  450 s ok on the corrected tree; the changed viewer test 3 of 3 on Windows and 3 of 3 under the race detector
  by name. **The installed collector is rebuilt from ae87e10 at 14:48** (no `tgarchive*` process was running;
  849c506's build kept as a `.bak`; `mirror -h` lists `-all-messages` and `-download`). Board: my row, the
  waiting list, the schema line, three "Listed and unbuilt" rows, message 25 to every track; `MERGE-QUEUE.md`'s
  state line. **Running: nothing of the integrator's.** Of the copies track (same session): two Opus coders, E8
  in `wt-copies-footage` (`wip/copies-8`) and E9 in `wt-copies-1` (`wip/copies-9` from f0e3f0c);
  `wt-copies-vfp` (`wip/copies-10` from f0e3f0c) is made for E10, its coder not started (memory).
  **Next step:** when the mirror session lists `wip/mirror-auto`: read its settle and the collector's loop, the
  full runs with the race detector on the collector, merge, a new build for the owner's blocked test mirror.
- 11-15 14:51: **STATE FOR A TAKE-OVER.** `repo-archiver`: `claude/charming-feynman-vm2xia` at f0e3f0c, equal to `private`,
  clean. Schema step 17 merged; 18 is the mirror's; next free 19. The installed collector is the build of
  ae87e10. Nothing waits to merge. Expected next: `wip/mirror-auto` from the mirror session (its settle's fix
  round is committed, c599ac5; it must take f0e3f0c in first: board message 25), then a build for the owner's
  blocked test mirror. Also done: the VPN adapter's name in `a3\a3-start.ps1`, `a3-prep.ps1` and
  `a3-start-console.ps1` is `WindscribeWireguard` now (the owner confirmed the change to the mirror session;
  `run` was refused with the old name; the scripts are not tracked; they still parse; `a3-mirror.ps1` is the
  mirror session's and takes `-Adapter`). On the board for the owner: items 11 to 13 (a core point that
  contradicts two decisions and no core session; the superseded branches; 21 GB of earlier bring-in copies).
  **This session's copies work: three Opus coders running as background agents of this session** (E8
  `wip/copies-8` in `wt-copies-footage`; E9 `wip/copies-9` in `wt-copies-1`; E10 `wip/copies-10` in
  `wt-copies-vfp`); each pushes its own branch and keeps a progress file in `archiver/docs/progress/`
  (`copies-index-`, `copies-holdunless-`, `copies-vfp-PROGRESS.md`). If this session died, a new one takes
  them from those files and `SESSION-COPIES-PROGRESS.md`.
- 11-15 15:21: **the owner said yes to board items 11, 12 and 13; all three done or started.**
  (13) Deleted under `tgarchive-b`: `old-archive`, `old-archive-2`, `old-archive-3`, `oldcopy`, `oldcopy-2`,
  `oldcopy-3` (16.7 GB freed). Checked first: no archiver program running; the owner's starter picks
  `old-archive-4`; the only row of the owner's in them was one preference in the first viewer folder (the
  current one has its own and 2 marks). Kept: `old-archive-4`, `oldcopy-4`, `bin`, `empty-library`, the logs.
  (12) Deleted on `private`: 34 superseded `wip/*` branches (every pushed head is still held by a local
  branch of the same name). Left on `private`: the main branch, `wip/copies-8`, `-9`, `-10`, `wip/mirror-auto`,
  and one dependabot branch of the old code (not ours to judge here). Copies removed, all clean:
  `wt-pages-topics`, `wt-pages-notadded`, `wt-b-bringin`, `wt-mirror-reads2`.
  (11) **K1 briefed and its Opus coder started** (`BRIEF-K1-chosen-chats.md`; copy `wt-core-chosen`, branch
  `wip/core-chosen`, cut from `wip/mirror-auto` c599ac5 on purpose: that branch has the "new chats start off"
  mechanism, so K1 extends it and merges after it). K1: every chat the collector first meets starts switched
  off; choosing a chat settles its files already listed, both ways (today a chat chosen after its read
  downloads nothing of what was read); a one-time baseline for chats nobody chose; read-only commands say
  what to do on an older catalogue.
  **The owner, 15:15, mid-turn: "How are we doing with overall progress? Remember we want a functional app, with
  a GUI."** Answered plainly: the engine room is real, the viewer is the one GUI opened on real data, the app's
  own pages run on an invented archive only, there is no one program to open, and no session is on the GUI.
  Recommended: no further copies pieces after the three running; the next coders on one usable app.
- 11-15 15:23: **STATE FOR A TAKE-OVER.** `repo-archiver` main branch f0e3f0c, equal to `private`, clean; nothing waits to
  merge. Board: the owner's steer under "Direction" (a functional app with a GUI); message 26 gives the pages
  track its first piece, G1 (the collector fills the pages' `Live` seam and serves them: one program to open);
  items 11 to 13 marked decided and done. **A session for the pages track is proposed to the owner as a card
  (not started: the owner starts it).** Background agents of this session, each on its own pushed branch:
  E8's coder (`wip/copies-8`, `wt-copies-footage`), K1's coder (`wip/core-chosen`, `wt-core-chosen`), and an
  independent read-only reviewer of E9 (`wip/copies-9` dcd556c; its report goes to
  `wt-copies-review9-scratch/REVIEW.md`). I read E9's engine diff myself first: the eight paths, the pen and
  slot handling at the claim, the order in `runCheck`; nothing found by reading; questions given to the
  reviewer. E10 (`wip/copies-10` e24d390) waits to be read and is reviewed with E8.
  **Next steps, in order:** E9's review, its fixes, whole engine and supply with the race detector on the
  engine, merge; `wip/mirror-auto` when the mirror session lists it (the collector's race run on its tree),
  then a new installed build for the owner's blocked test mirror; K1 on top of it; E8 and E10 with one review.
- 11-15 15:37: **the owner asked what else can start with the rest going.** Measured: 4.3 GB free, CPU 79% (two reviewers
  and K1's coder of mine, the pages session the owner started at about 15:30, the mirror's race run): no
  further compiling coder now. Done instead, without load: (1) looked for the viewer's timings file
  (`stats-last.json` in the viewer's folder beside `old-archive-4`): **it does not exist**, so the owner has not
  run the build of 16376c9 yet and the slow first video cannot be diagnosed before that; (2) **a viewer
  session is proposed to the owner as a card** (the slow first video, then `PLAN-native-window.md`; told to
  read and plan first and start a coder only when the PC has room); (3) **read ahead of its merge, on
  `wip/mirror-auto` c599ac5: the automatic mirror's turn in the collector** (`mirror_auto.go`): it runs inside
  the reader's turn, in the reader's goroutine, at most one request and then it yields a turn to the reader's
  own work; no goroutine of its own; the monitor's sink only sets an atomic "look due" and nudges the reader;
  the settle reads a mirror chat through the reader task's own reader and its watchdog's pass; a failure to
  read a record stops the task for a minute and says so once. Nothing found by reading. **Still to read at
  its merge:** `internal/mirror`'s `Look` and `Turn`, the settle's evidence rules
  (`catalog/mirrorsettle.go`), `schema_mirrorauto.go`, and the second and third reviews' reports.
- 11-15 15:41: **the owner opened the viewer's new build (started 15:38) and said "The first video was slow again".** Read
  from its counts-only timings file after 67 s: the file route 7 range requests, time to first byte median
  113 ms, worst 18.1 s; opening a library file 188 times, median 107 ms, worst 23.6 s; a first read after an
  open at most 17.5 ms; nothing converted. So the wait is the OPEN of a file on the NAS at the viewer's
  start, and another reader stalled the same way. Sent to the viewer session (started by the owner about
  15:37) with what to measure before changing anything (opens over 1 s by seconds since start; one `Stat` of
  the library root at start). Two sessions started by the owner from this session's cards are working: pages
  (G1) and viewer.
- 11-15 15:49: **the owner on the viewer, second report:** "The second and third videos seem to play quickly. Some of the
  videos need to be converted, and that is very slow, with the length/progress bar filling slowly, so seeking
  is impossible." A second start's snapshot (uptime 64 s): file route worst 212 ms, library open worst 365 ms:
  no stall in that start, so the 18 s stall looks like the first touch of the NAS after it was left alone,
  not every start of the viewer. One conversion started, its first byte after 401 ms; "Open in the player"
  never used; the PC's CPU was at 88% from our own coders and runs at that moment. Sent to the viewer session
  with the owner's words: the native window with mpv removes converting, so it should not wait; measure the
  conversion's speed first; check "Open in the player" as the owner's starter runs it.
  **The pages session (P2) ended a turn:** G1 is briefed and one Opus coder is building it on `wip/pages-g1`
  (first commit in); Queue, sign-in and Staging pages briefed, not started; nothing reviewed or seen in a
  browser.
- 11-15 15:57: **K1 is handed back: `wip/core-chosen` 1a25071, pushed, clean (on `wip/mirror-auto` c599ac5; that branch has
  since moved to 464e840).** Built as briefed: a catalogue-wide setting makes every new chat row start
  switched off; `ApproveRead` chooses the chat and its listed files settle both ways in chunks (50,000 files:
  3.7 s off, 4.6 s on, longest write 101 ms); a one-time baseline; `chats` says why a chat does not collect;
  read-only commands say what to do on an older catalogue. Read by me: the chat-making place, the switch and
  the kinds now settling, the lines in the mirror's file. **My first doubt, given to the reviewer:**
  `SetChatCollect` records a per-chat "switch" row meant as the owner's hand, and the mirror's read and the
  bring-in call the same door. Also to settle in its fix round: a chat made under `-new-chats-download` is
  switched off by a later baseline (it should be on record as chosen); the coder's rig passes the flag in all
  62 existing uses, so the default path is exercised by the new tests only. **An independent reviewer is
  running** (`wt-core-review-scratch/REVIEW.md`). Board message 27 tells the mirror and pages sessions what K1
  changes in their files. After the review: fixes, the mirror branch's new head merged in, then whole catalog
  and collector once; no goroutine is added, so no race run.
  E9's full runs are queued behind the mirror's race runs (`runs-12b/`).
- 11-15 16:17: **E9's full runs (`runs-12b/`, on `wt-copies-1`, the main head f0e3f0c plus E9 c018322):** whole tests ok: engine
  31 s, supply 154 s, exact 10 s, exact/wire 5 s; the race detector ok: engine 281 s, supply 968 s; gofmt
  empty, vet exit 0. **The collector's whole run crashed after 379 s: not a test failure but an access
  violation (Windows exception 0xc0000005) inside the database library's own lock call** (the pure-Go SQLite's
  shared-memory lock through `LockFileEx`, reached from the monitor task opening a read), which ends the whole
  test program. E9 touches neither that library nor the collector. It is not in any lessons file. **A second
  whole run of the collector is going** (`runs-12b/win-collector-2.log`, started about 16:17). "ok" and
  "exit 0" there: E9 merges (`git -C repo-archiver apply --3way --index` of `git diff f0e3f0c c018322`,
  one commit, push, the roadmap's rows for copies, the handoff). **For Core and the documents either way: a
  crash of this kind would end the real collector; it needs its own look (the library's version, whether it
  repeats, a watchdog that restarts the collector).**
  **K1's independent review is back** (`wt-core-review-scratch/REVIEW.md`): 9 confirmed, 7 plausible. The worst:
  every program's switch was recorded as the owner's, so a chat the mirror read could never be switched on
  (C1); a stop during the baseline left files wanted and the baseline marked done (C2); set-aside files came
  back wanted in a switched-off chat (C3); the approval was written before the choice (C4); a chat with a
  read and no approval could not be chosen (C5); the baseline switched off chats the owner had ranked (C6).
  **Its fix round is briefed (`BRIEF-K1b-fixes.md`) and the same coder is on it**: only the owner's own doors
  write an owner's record; a `choose` command that needs no request; the baseline's mark after its settle;
  the default path tested for real. A last round (K1c) follows the mirror branch's merge: the new main head
  taken in, and a video chosen after its read judged by the look-alike rule before it is wanted (the review's
  P3: without it a probable copy would go before unique files).
  **On the merge queue since 15:59, not started by me: M4, `wip/mirror-auto` 464e840** (the automatic mirror
  and settling; schema 18, to sit on 17 at the merge; its last fix round, the settle's rewritten rules in
  `catalog/mirrorsettle.go`, has had no review of its own: the mirror session offers one). After it and a
  build the owner can settle the test account's blocked mirror.
- 11-15 16:17: **STATE FOR A TAKE-OVER (the owner: context is getting high; a fresh integrator session is proposed).**
  `repo-archiver`: main branch f0e3f0c, equal to `private`, clean, nothing staged. Installed collector: the
  build of ae87e10. **For the new integrator, in order:** (1) E9: read `runs-12b/win-collector-2.log`; if ok,
  merge `wip/copies-9` c018322 as above (its runs are done); (2) M4: read `mirrorsettle.go`, `internal/mirror`'s
  `Look` and `Turn`, `schema_mirrorauto.go` and the two reviews; I already read the collector's turn
  (`mirror_auto.go`: one request a turn in the reader's goroutine, no goroutine of its own, nothing found);
  decide on one more review of the settle; apply it on f0e3f0c with `mirrorAutoAfter` 17; whole catalog,
  collector, mirror once on the combined tree (its race runs were done by the mirror session on c599ac5:
  collector 64 minutes, no data race); push; rebuild the installed collector; tell the owner how to settle
  the test mirror; (3) then K1 (after its rounds), E8 (after its fix round: `wip/copies-8`), and what the
  viewer and pages sessions list (`wip/b-open` 6eb54d8 is in review there; `wip/pages-g1` is being built).
  **This session keeps only its own running coders and reports through the files, as a building session:**
  E8's fix round (`wip/copies-8`) and K1's (`wip/core-chosen`); it merges nothing further and does not touch
  `repo-archiver` once the new integrator has started.
- 11-15 16:22: **A NEW INTEGRATOR SESSION HAS TAKEN OVER (started by the earlier one at the owner's word; it writes here from now on).**
  It merges, keeps the board and the documents, and builds nothing; the earlier session is a building session
  (copies, K1) and reports through `SESSION-COPIES-PROGRESS.md`. Checked on disk at 16:21: `repo-archiver`
  f0e3f0c, equal to `private`, clean, nothing staged; every copy clean and its branch equal to `private`
  (`wt-b-window`: the spike, 1 file not committed, never pushed, as planned). PC: 3.7 GB free, CPU 70%, three
  collector test programs running. E9's second collector run (`runs-12b/win-collector-2.log`) is still going
  (the log is empty until it ends). Next: read it; meanwhile M4 is being read (the settle, `Look`, `Turn`, the
  schema step, the two reviews).
- 11-15 16:24: the collector's second whole run passed (475 s, `runs-12b/win-collector-2.log`; no crash). **E9's MERGE IS BEING
  DONE NOW BY THE EARLIER INTEGRATOR SESSION (not by a new one): do not apply it a second time.**
- 11-15 16:25: **E9 IS MERGED AND PUSHED: head 9d187d3, equal to `private`, 0 uncommitted, nothing staged.** fdf5b8f the code
  (the staged tree was identical to `wip/copies-9` c018322; vet on engine and supply exit 0), 9d187d3 the
  roadmap and the handoff. **The installed collector is NOT rebuilt** (still ae87e10): the mirror branch's
  merge rebuilds it. **For the new integrator: job 1 of its brief is done; start at M4.** Cut from 9d187d3;
  `wip/mirror-auto` 464e840 has neither f0e3f0c's nor this commit's changes in it.
- 11-15 16:25: **THE NEW INTEGRATOR SESSION HAS STARTED (the owner started the card at about 16:25; title "Archiver integrator:
  take over (fresh context)").** E9 was merged and pushed by me just before (9d187d3): told to it by message and
  by the entry above; its first job is M4. **From here this earlier session is a building session only**: it
  does not touch `repo-archiver`, the integrator's board row or the waiting list. Its two coders run: E8's fix
  round (`wip/copies-8`) and K1's (`wip/core-chosen`); their state is kept in `SESSION-COPIES-PROGRESS.md`.
  A second integrator card I had proposed by mistake of timing is withdrawn.
- 11-15 16:26: **E9's second whole run of the collector passed: `ok`, 474.8 s, exit 0** (`runs-12b/win-collector-2.log`;
  the PC at 38% CPU and 5.5 GB free at its end, against about 80% and 4.6 GB at the crash). So the crash inside
  the database library did not repeat in one further run: one of two (board message 28 stays open for Core).
  **E9 is being merged now.** M4: `mirrorsettle.go`, the command's settle, `Look`, `Turn` and the second review
  read by me. The settle's read rule holds in both callers by reading. **One plausible defect found by reading,
  so the rewritten settle gets its own independent review before the merge (decided):** a mirror message with
  no forward origin counts as "not a forward" unless a batch message has exactly its whole media key, and the
  key takes every attachment row, replaced ones too; a copy that shares a media row but not the whole set (an
  edited source, alternative-quality rows on one side) with a hidden sender would make an arrived message "not
  arrived" (a second copy in the mirror). Brief: `BRIEF-M4c-review.md`; **an Opus reviewer runs since 16:25**
  (read-only, scratch `wt-mirror-review6-scratch`, its report `REVIEW.md` there). M4's full runs wait for it and
  for its fixes (the fixed order). Still to read: `schema_mirrorauto.go`.
- 11-15 16:27 (the new integrator): **correction to my entry of 16:26: E9 was already merged and pushed by the earlier session
  at 16:24 (fdf5b8f the code, 9d187d3 the documents), seconds before I read the log.** Checked: fdf5b8f's code is
  identical to `wip/copies-9` c018322 (0 lines differ); `repo-archiver` is 9d187d3, equal to `private`, clean,
  nothing staged (my own apply of the same diff at 16:26 changed nothing: the staged tree equalled the head's).
  **Job 1 is done. The main head is 9d187d3: every new piece is cut from it.** M4 goes onto it as the ten
  commits after 99b71c3 (`git diff 99b71c3 <head of wip/mirror-auto>`), `mirrorAutoAfter` 17. Running: the
  settle's reviewer (since 16:25). Next: `schema_mirrorauto.go` read; the combined tree prepared in a copy of my
  own (`wt-int-m4`, branch `int/m4` from 9d187d3) to meet conflicts and compile early; the full runs only after
  the review's fixes.
- 11-15 16:29 (the new integrator): **M4 read in full by me; held for the settle's review; the combined tree is ready.**
  Read: `mirrorsettle.go`, `mirror_settle_cmd.go`, `auto.go` (`Look`, `Turn`, the settle turn), `schema_mirrorauto.go`,
  the reader's `Newer` pass, both reviews. Found sound by reading: the read rule in both callers (an empty
  newer pass still saves the cursor, so a settle with nothing new in the mirror is "on record"); one request a
  turn; fail closed on unreadable rows; the schema step idempotent. Found: the media-key suspicion (board
  message 29 a), the random-id question (29 b), the start script has no way to pass `-take` (29 c).
  **Combined tree: my copy `wt-int-m4`, branch `int/m4` from 9d187d3, the ten commits after 99b71c3 applied and
  staged, NOT committed** (37 files; one conflict, the schema ladder in `catalog.go`: both steps kept,
  `SchemaVersion` 18, `mirrorAutoAfter = releasedSchema`). `go build ./...`, `go vet` on catalog, mirror,
  collector, faketg and the command, gofmt: all clean (`runs-13/prep-compile.log`, 38 s). `repo-archiver`
  itself is untouched (9d187d3, clean). The board: my row, message 29 to the mirror session, the viewer's
  `go.mod` question answered yes in principle (message 28 a). **Running: the settle's reviewer (an agent of
  this session, since 16:25).** Next: its report; the mirror session's fix round (the owner wakes it: it is not
  linked to this session); the new head applied in `wt-int-m4` again; then the full runs once: whole
  `catalog` (about 5 min), `collector` (about 9 min), `mirror` (about 1 min), no race run (the mirror
  session raced the whole collector, 64 min, and `internal/mirror` on this code; the fix round is catalogue
  code that starts no goroutine); then the merge, the push, the installed collector rebuilt, the documents.
- 11-15 16:36 (the new integrator): **THE SETTLE'S REVIEW IS BACK: 2 confirmed (high), 2 plausible. M4 IS NOT MERGED; one fix round
  first (the mirror track's).** Report `wt-mirror-review6-scratch/REVIEW.md` (read by me against the code; the
  reviewed copy untouched, still 464e840, clean). (1) confirmed: the media-key suspicion: 5 of 6 probe cases
  settle "found 99, again 1" with all 100 arrived (a second copy). (2) confirmed: put-back messages carry the
  same random ids and ride with fresh ones; refused as a repeat the whole batch is a contradiction and the only
  word is "taken as arrived": 100 of 400 lost in the probe, 60 never sent; this is the test account's next step
  exactly. (3) plausible: a "sending" batch's need time counts from before the forwarder's waits. (4) low: a
  refused mirror chat is "read" every turn, nothing said. My third suspicion refuted; the earlier P2 to P5 fixed.
  All of it is under board message 29 with the fixes I accept. **The mirror session is not linked to this one:
  the owner is asked to paste "Read `BOARD.md` message 29 and carry on" into it.** After its round: the same
  reviewer (an agent of this session, it can be continued) runs its three probes on the new head; then the
  full runs once on `wt-int-m4` re-made from the new head; the merge. `wt-int-m4` stays as it is until then
  (staged, not committed). **New on the queue, independent of M4: C6, `wip/copies-8` a134a4b (E8 and the
  ffmpeg part's fixes), listed 16:34: being read now.** Also seen: pages handed G1 back to its own session
  (023c048, not listed yet).
- 11-15 16:36 (the new integrator): **C6 (`wip/copies-8` a134a4b: the MP4 index reader, the second round on key frames, the ffmpeg
  part's review fixes) is APPLIED TO `repo-archiver`, STAGED, NOT COMMITTED** (`git diff 6f17c7f a134a4b`, 23
  files; the main branch has not touched `internal/footage` since 6f17c7f). Read by me: the two ffmpeg command
  lines (`-format_whitelist`, the neutral type of the range server), the fingerprint's bound and its stop from
  the two copying goroutines (an atomic flag and a cancel), the times read only from ffmpeg's own lines. Full
  runs starting, by hand (nested packages), out folder `runs-13c/`: whole `footage`, `footage/mp4index`,
  `footage/ffmpeg` with `FFMPEG_PATH` on 9.0.2; the race detector on `footage/ffmpeg`; vet, gofmt. All ok:
  commit, push, the review to `docs/review`, the roadmap's copies rows, the handoff.
- 11-15 16:40 (the new integrator): **C6 IS MERGED AND PUSHED: head a0baa06, equal to `private`, clean, nothing staged.** 09fd59c the
  code (`wip/copies-8` a134a4b; the staged `internal/footage` tree was identical to the branch's), a0baa06
  the documents (the roadmap's two frame-check rows, the handoff's lines and its schema paragraph brought to
  step 17, the review as `docs/review/copies-index-ffmpeg-2026-11-15.md` without the parked branch's section).
  Full runs once (`runs-13c/`, 16:36 to 16:40, the PC at 57% CPU and 4.8 GB free before): whole `footage`
  2.9 s, `footage/mp4index` 5.7 s, `footage/ffmpeg` 179 s (ffmpeg 9.0.2, no test skipped), the race detector
  on `footage/ffmpeg` ok (1.5 s: the container has no ffmpeg), vet exit 0, gofmt empty. **The installed
  collector is not rebuilt** (still ae87e10: nothing calls these packages). The board's row and waiting list
  and the queue's entries C6 and M4 say the same. **The owner was asked (16:36, again 16:38 with the options)
  to wake the mirror session for M4's fix round** ("Archiver mirror groups on the test account": "Read
  `BOARD.md` message 29 and carry on"); no answer yet. **Waiting now:** M4's new head on the queue. `wt-int-m4`
  (branch `int/m4`, from 9d187d3, M4 at 464e840 staged, not committed) is stale by design: it is re-made from
  a0baa06 with the new head. The reviewer agent of this session can be continued for the re-probe.
- 11-15 16:41 (the new integrator): **the owner: the old mirror session's context is at 69%, "not worth it. Start a fresh session for
  it."** Started at once: a fresh session "Archiver mirror: take over, M4 settle fix round" (linked to this one;
  it takes the mirror track over from `SESSION-MIRROR-PROGRESS.md`; its first job is the one fix round of board
  message 29 on `wip/mirror-auto` in `wt-mirror-auto`, one Opus coder, named tests only; it lists the new head
  under M4). The old session "Archiver mirror groups on the test account" is retired: nobody wakes it.
  **Waiting now:** that session's new head. Then: the reviewer's probes on it, `wt-int-m4` re-made from a0baa06,
  the full runs once, the merge, the installed collector rebuilt.
- 11-15 16:52 (the new integrator): **the new mirror session (M2) ended its first turn: the track is taken over, M4's fix round
  (`BRIEF-M4d-settle-fixes-2.md`) is with one Opus coder in `wt-mirror-auto`; no new head yet** (`wip/mirror-auto`
  still 464e840; entry M4 unchanged). Its design is in its board row and read by me: accepted as written (my
  answer under message 29: a table inside step 18, no step 19; attempt 0 the same random id bit for bit; the
  margin after the sender's end). Also on disk, none of it listed to merge yet: K1's fix round handed back
  (`wip/core-chosen` 52108cf; its last round waits for M4's merge); the viewer's two pieces joined as
  `wip/b-viewer4` (d4269cc), its own full runs started; G1 (023c048) in the pages session's read.
  `repo-archiver`: a0baa06, equal to `private`, clean. **Waiting:** M4's new head.
- 11-15 17:09 (the new integrator): **queue entry 16 (`wip/b-viewer4` d4269cc, the viewer: the library's opens, files not downloaded,
  five smaller things) is APPLIED TO `repo-archiver`, STAGED, NOT COMMITTED.** It holds the main head a0baa06
  and touches only `internal/viewer`; the viewer session ran the full runs on that very tree (`runs-b4/`:
  whole viewer and the race detector), so they are not run a second time: my read of the lock change, vet,
  then commit and push.
- 11-15 17:11 (the new integrator): **ENTRY 16 IS MERGED AND PUSHED: head 4f0fe17, equal to `private`, clean, nothing staged.**
  9a51a92 the code (`wip/b-viewer4` d4269cc, viewer only; the staged tree identical to the branch's, which
  held a0baa06), 44b57b6 the roadmap and the handoff, 4f0fe17 the two reviews (a script error left them out
  of 44b57b6; folder names of this PC masked in the copies). Read by me: the library's lock and root lifetime
  in `media.go`. No second full run: the viewer session's (`runs-b4/`: whole 212 s, race 515 s, no data
  race) were on the tree merged; `go vet ./internal/viewer ./cmd/tgarchive` on the main tree exit 0. The
  installed collector is not rebuilt (viewer only; the viewer's program is the viewer session's build).
  **The owner asked (17:08): "How are we doing with overall progress?"** Answered in this turn.
  **Waiting:** M4's fix round (the mirror session M2's coder; `wip/mirror-auto` at 6485dd0, moving).
- 11-15 17:17 (the new integrator): **the owner asked for the questions that wait, with background and recommendations, and when
  to launch the viewer again.** Asked together in this turn: board item 14 (Start and Stop in the one program:
  recommended as written), item 17 (install G1's build as the installed collector once merged: recommended
  yes), item 18 (a Core session: recommended when G1 is in the owner's hands). The viewer: launch now with
  `b\b-viewer.cmd` (the build of d4269cc; the next slow start names the stalled step), and again when the
  viewer session says "each file once" (`wip/b-once`, in work) is built. No answer yet. Branches moving:
  `wip/mirror-auto` 39599c2 (17:10), `wip/pages-g1` 21e7b93 (17:11), `wip/b-once` 547fd1c (17:16).
- 11-15 17:25 (the new integrator): **the owner answered (17:21).** The viewer: "The video loaded quickly", and a click on the video
  should start and pause it (board message 31, sent to the viewer session). Item 14: Start and Stop as written,
  with a pause of downloads and "pause for X hours" (message 30, sent to the pages session; a row in the
  board's listed table and in the roadmap, d1af260 pushed). Item 17: yes, G1's build is installed after its
  merge. Item 18: usage is upgraded, Core "probably now if it's useful": **a Core session is started** (linked;
  first the crash of message 28, then a crash log and a watchdog outside the collector's files in flux, then
  the NAS copy and a day-long run; it starts `SESSION-CORE-PROGRESS.md`). The old app: the owner believes 12.32
  runs; its report and running marker say 12.30, `whothis44/tg1` has tags up to 12.31 and 12.32 as a branch
  only (message 32; nothing touched). **Main head d1af260, equal to `private`, clean.** Nothing waits to merge;
  M4's fix round, G1's fix round, the viewer's "each file once" and the native window's stage B are in work.
- 11-15 17:26 (the new integrator): **the owner on the old app: "barely running anymore. It fulfilled its purpose. I'm not concerned
  about it."** Closed on the board (message 32 and the old app's row): nothing is tagged or released for it and
  it is not raised again. Nothing else changed.
- 11-15 17:36: **the earlier integrator session (started 14:18) ends here: the owner archives it.** It has nothing running, no
  subagent, no background command; its four copies are clean and pushed (`wip/copies-8`, `-9` merged;
  `wip/copies-10` parked; `wip/core-chosen` 52108cf handed to Core by board message 33). The copies track has
  no session: its take-over block is the end of `SESSION-COPIES-PROGRESS.md`. The integrator role has been the
  new session's since about 16:22.
- 11-15 17:42 (the new integrator): **M4's fix round is handed back: `wip/mirror-auto` e067045 (pushed, the copy clean; entry M4,
  "THE NEW HEAD").** Read by me: the entry; `forward.go` (attempt 0 writes the same label and the same 56 bytes
  as before: the old id bit for bit), the candidates' queries and `BeginMirrorBatch`'s refusal of a mixed batch
  in `schema13.go` (a put-back message that is no longer a candidate is not returned, so it cannot hold fresh
  ones for good), the table inside step 18. **Running:** the same reviewer, a second pass on e067045 (its
  probes again, and what the round added), writing "Second pass" at the end of
  `wt-mirror-review6-scratch/REVIEW.md`. **`wt-int-m4` is re-made:** reset to d1af260, `git diff 99b71c3
  e067045` applied (43 files staged, NOT committed), the schema ladder's conflict resolved as before
  (`mirrorAutoAfter = releasedSchema`); build and vet running (`runs-13/prep-compile-2.log`). Next: the
  reviewer's verdict; if no fix is needed, the full runs once on `wt-int-m4` (whole catalog, collector,
  mirror, telegram's forward tests; no race run: no concurrent code changed in the round, the mirror session
  raced the collector and `internal/mirror` on the code before it), the merge, the installed collector.
- 11-15 17:44 (the new integrator): **the combined tree with e067045 builds and vets clean** (`runs-13/prep-compile-2.log`, 24 s).
  **The earlier integrator session is archived (17:36, the owner's word): the copies track has no session, and
  K1 (`wip/core-chosen` 52108cf) had nobody.** Decided and told to the Core session (board message 34): K1's
  last round is Core's, ahead of its watchdog; its coder starts from the main head once M4 is merged. **The
  Core session found the crash of message 28** (`FINDING-CORE-crash-28.md`, read by me against the runtime's
  source): a Windows call's argument array freed before the runtime copies it; **decided: one line
  (`KeepAlive(args)`) into the local toolchain's `runtime/syscall_windows.go` and a check in
  `env-archiver.sh`, applied by me after the reviewer's second pass and before M4's full runs** (not applied
  yet). Other tracks at 17:43: G1's fix round handed back (0b1d3ee) and in its session's browser pass, the
  pause's coder started; the viewer's `wip/b-once` (18725db) and the native window's stage B (d59160a) in
  their reviews. **The owner asked for overall progress and what else can run in parallel:** answered; proposed
  a fresh copies session (the owner's call: copies were paused at 15:15 for the GUI).
- 11-15 17:47 (the new integrator): **the owner freed memory: 10.5 GB free of 31, CPU 23% (17:47).** Board message 35 tells every
  session what that allows (a second coder where files differ; full runs side by side). Recommended to the
  owner: a fresh copies session now. The reviewer's second pass is still running (its section is begun).
- 11-15 17:49 (the new integrator): **THE REVIEWER'S SECOND PASS ON e067045: findings 1 to 4 fixed; one older hole confirmed
  (finding 5, medium). M4 IS NOT MERGED: one small fix round more (decided).** Checked by me at
  `mirrorsettle.go` line 624: a media match counts on main keys only, so another batch message's replaced
  row is not seen; in the probe a message is recorded as forwarded with another's copy (a hole for good) and
  the other is put back (a second copy). Why not merge with it open: the order is review, fixes, full runs
  once; the fix is small and stated; the session M2 is linked and was told directly at 17:50 (its turn
  started); K1c's preparation goes on in the Core session meanwhile. Board message 29's last paragraph and
  entry M4 say the same. `wt-int-m4` holds e067045 staged on d1af260 (not committed): re-made again from the
  next head.
  **THE TOOLCHAIN LINE IS APPLIED (17:49):** `runtime.KeepAlive(args)` in `syscall_syscalln`
  (`ix-tools/goroot-1.27.3/src/runtime/syscall_windows.go`; before 53518810c4557c36, after 83baf1927671a165;
  the original and the difference kept beside it in `ix-tools`; `env-archiver.sh` warns when it is missing).
  No go process was running when it was written. Checked: `go build ./...` on the main tree exit 0 (18 s),
  `internal/footage` and `footage/mp4index` ok, `runtime` not stale, and the compiler's liveness listing now
  shows the array live at the call. The installed collector does NOT carry it yet (still the build of
  ae87e10): M4's merge builds it. `repo-archiver`: d1af260, equal to `private`, clean.
  **The PC: 10.5 GB free of 31, CPU 23% (17:47), after the owner freed memory.** Recommended to the owner: a
  fresh copies session now (the box asks). **Waiting:** M2's head for finding 5.
- 11-15 17:51 (the new integrator): **the owner: "Yes, start it": a fresh copies session is started** ("Archiver copies: take over, the
  next copy layers", linked to this one; it takes the track from the last block of `SESSION-COPIES-PROGRESS.md`:
  the parked fingerprint at save with a copier-side wait first, the frame check in a file's turn with parts
  reused, confirm or release with the viewer's verdicts, message 11's gap; no line in `internal/collector`
  while M4, K1 and G1 are in it). The mirror session M2 ended a turn: finding 5's round is briefed and with the
  same coder on `wip/mirror-auto` from e067045; no new head yet. **Waiting:** that head.
- 11-15 18:08 (the new integrator): **M4's newest head: `wip/mirror-auto` e8113ae (pushed, the copy clean): one commit for finding 5.**
  Read by me: `mirrorsettle.go`'s two new rules (a copy is a message's by media only when no other batch
  message and no earlier "missing" one holds any of the copy's rows; "not arrived" becomes "cannot tell" when
  an unfound copy with no post origin shares any row with it): conservative both ways. **Running: the
  reviewer's third pass** (S3 and its other probes on e8113ae; "Third pass" at the end of its `REVIEW.md`).
  **`wt-int-m4` re-made:** reset to d1af260, `git diff 99b71c3 e8113ae` applied (44 files staged, NOT
  committed), the ladder resolved (`mirrorAutoAfter = releasedSchema`); build, vet (catalog, mirror,
  collector and faketg, telegram, the command) and gofmt clean with the patched toolchain
  (`runs-13/prep-compile-3.log`, 11 s). PC 18:08: 9.0 GB free, CPU 41%.
  **The full-run plan, once, when the third pass is clean (said to the owner):** whole `catalog` (about 5
  min), `collector` (about 9), `mirror` (about 1.5), `telegram`, `collector/faketg` and the command, side
  by side on `wt-int-m4`; no race detector (no goroutine, lock or channel changed in the three fix rounds;
  the mirror session raced the whole collector, 64 min, and `internal/mirror` on the code before them). Then:
  the same diff applied to `repo-archiver`, one commit, push; the documents; the installed collector rebuilt
  (no `tgarchive*` process running; the build of ae87e10 kept as a `.bak`); the owner's settle steps.
  Other sessions (their notes, 18:05): Core has K4 (the chat list's protected flag, `wip/core-protected`
  8d2daff) in its full runs and coders on the watchdog and a NAS test, K1c waiting for M4's head; copies has
  four coders building; nothing of theirs is on the queue yet.
- 11-15 18:10 (the new integrator): **the reviewer's third pass: finding 5 fixed on e8113ae, nothing broken; one new note (low,
  plausible, only under the owner's `-take` and with a catalogue row gone): not for this merge, written for
  the mirror track's next round (board message 29).** **M4's FULL RUNS ARE RUNNING since 18:10** (a background
  command of this session, out folder `runs-13m/`, on `wt-int-m4` = d1af260 plus `git diff 99b71c3 e8113ae`,
  staged, not committed): whole `internal/catalog`, `internal/collector`, and in a row `internal/mirror`,
  `internal/telegram`, `collector/faketg`, `cmd/tgarchive-collector`; then gofmt. PC before: 9.1 GB free,
  CPU 49%. All ok: apply the same diff to `repo-archiver` (resolve the ladder the same way), one commit,
  push, the documents, the installed collector. A failure of `TestTopicSettleAtSize` alone (board message 17)
  or of `TestGotdQ4ConcurrentLoadChangeSave` alone (the handoff's open list) is run once more by name.
- 11-15 18:20 (the new integrator): **M4 IS MERGED AND PUSHED: head 9dd5a21, equal to `private`, clean, nothing staged.** be429e1 the
  code (`wip/mirror-auto` e8113ae as `git diff 99b71c3 e8113ae` on d1af260; the staged tree was identical to
  the tested one; schema step 18 on 17), 9dd5a21 the documents (the roadmap's two mirror rows, the handoff's
  mirror and schema paragraphs and the installed collector's line, the three reviews in `docs/review`).
  **Full runs once on the combined tree (`runs-13m/`, 18:10 to 18:19, side by side, the patched toolchain,
  9.1 GB free and CPU 49% before):** whole `catalog` 383 s, `collector` 551 s, `mirror` 102 s, `telegram`
  41 s, `collector/faketg`, the command: all ok, no failure; gofmt empty; vet clean (prep-compile-3). No race
  run (said). **NOT DONE YET: the installed collector (still the build of ae87e10); the board and the queue;
  the head told to Core (K1c) and to the mirror session.** Next, in this order.
- 11-15 18:22 (the new integrator): **THE INSTALLED COLLECTOR IS THE BUILD OF 9dd5a21 (18:20).** No collector process was running;
  ae87e10's build kept as `tgarchive-collector-ae87e10.exe.bak`; built with the patched toolchain; `mirror -h`
  lists `-settle`, `-take`, `-never`, `-allow`, `run -h` the `-auto-mirror` flags. **The test catalogue,
  read read-only: schema step 16; batches: 3 done (300 messages), 1 waited, 1 unknown (99); 1 mirror.** The
  build reads 18 and plans read-only before the yes: the mirror session (M2) is asked to prove the plan on a
  copy at 16 and to say so in its row. The head told to Core (K1c starts from 9dd5a21) and to M2 (M5 from
  it). The board: my row, the waiting lines, the schema line (19 is K4's, next free 20), item 21 for the
  owner (the settle is READY, with the steps); the queue: M4 marked merged. **On the queue, not merged: K4
  (`wip/core-protected` 8d2daff, schema 19) and K3 (`wip/core-nastest` 96d7e69): after K1c and G1.**
  `repo-archiver`: 9dd5a21, equal to `private`, clean. `wt-int-m4` (branch `int/m4`) is finished with: its
  staged tree is the merged one; it can be removed.
- 11-15 18:22 (the new integrator): correction: the board's and the queue's update of the entry above failed at first (another
  session had reworded the waiting line) and is done now: my row, the waiting lines, entry M4 marked merged,
  **item 22 for the owner (the settle, READY)**. The schema line was already brought to "next free 20" by Core.
  New on the owner's list from others: item 20 (Core: the NAS copy test, READY), item 21 (copies: what "same /
  not the same" does to a held file).
- 11-15 18:27 (the new integrator): the mirror session checked the script and the settle's plan on the installed build (a copy of
  the test catalogue at 16: the plan prints and ends cleanly; a yes on invented data steps 16 to 18 and
  settles): item 22 says so; the owner needs no step first. Core: K1c's coder runs from 9dd5a21 on
  `wip/core-chosen-c` (the review's P3 stays open in it: the copies' set rule is not on that head). Copies:
  two pieces handed back, each with a reviewer; two coders building. Nothing new on the queue (K4, K3 wait).
- 11-15 18:43 (the new integrator): **the owner: "Give me the commands I can use from anywhere. Always."** Every command for the owner
  is given with full paths from now on (a memory note; a board message to every session; item 22 rewritten;
  Core asked to rewrite item 20). The `a3` scripts use `$PSScriptRoot`, so they work from any folder by
  their full path.
- 11-15 18:45 (the new integrator): **THE OWNER'S FIRST SETTLE FAILED AT ONCE, NOTHING SENT (18:44): the script's default program path
  was corrupt.** `a3\a3-mirror.ps1` line 25 held a real TAB and BACKSPACE where the path's backslash-t and
  backslash-b belong (written 16:50 with the settle mode), so `Start-Process` found no file. The mirror
  session's "checked on the installed build" (18:25) did not go through the script's default path, and I
  passed its word on to the owner without running the script as the owner does: my miss. **Fixed by me**
  (those bytes only; the file as it was is kept in my temp folder); checked without running it: 0 parse
  errors, the default program exists, no control character; no other `a3` script has one. Told to the
  mirror session (its to run the script itself by full path from another folder up to the plan, to make a
  failed start stop with fixed words, to print the log's full path). The owner is told to run the same
  command again.
- 11-15 18:45 (the new integrator): **the owner (18:47): "Relative paths for the viewer are fine, but remember we're going to roll
  this program into a standalone .exe with a folder as well."** Recorded as direction on the board, a message
  to every session with my reading (files relative to the program's own folder or a setting, tools looked for
  there first, no absolute path of this PC, the scripts are scaffolding), a roadmap row (owner of the
  packaging: pages, after G1) pushed with the main branch, and a memory note. Not asked yet: whether the
  folder also holds the catalogue and the data. My entry of 18:46 above was committed with another session's
  notes commit (ac81b88): it is saved.
- 11-15 18:47 (the new integrator): **THE FIRST REAL SETTLE RAN AND SETTLED (the owner, 18:46, the test account; the repaired script,
  the installed build of 9dd5a21).** 1 page and 1 request read the mirror chat; 65 of 99 arrived (64 by the
  post each forward names, 1 by the same media), 34 put back, 0 cannot be told, 0 unexplained, 0 twice; exit
  code 0. Read read-only afterwards: schema step 18 (stepped by this run from 16); 4 batches done (399
  messages, 365 forwarded), 1 waited; 365 forward rows; 34 put back at attempt 0; nothing blocks. On the
  board for the mirror session and the documents (the newest message) and on item 22. **Next, the owner's:
  `a3-mirror.ps1 -Chat 4` (the 34 alone, old ids): the first measurement of what Telegram remembers.**
  Owed by me after that run: `TELEGRAM-FACTS.md` section 11 (the settle's numbers and that outcome).
- 11-15 18:49 (the new integrator): **THE 34 PUT-BACK MESSAGES WERE FORWARDED (the owner, 18:48): not refused as a repeat.** One
  forward request, 908 ms, 34 forwarded, 0 left out, no wait. Read read-only: 5 batches done (399 forwarded
  of 433 asked), 399 forward rows, nothing blocks: the test mirror holds the source's first 399 media
  messages, each once; 348 are still to forward. In `TELEGRAM-FACTS.md` section 11 and the handoff's mirror
  paragraph (**main head 0e2d974, equal to `private`, clean**: 9dd5a21 plus two documents commits). On the
  board (the newest message; my row's head). **M4 is done in the owner's hands: merged, installed, settled,
  forwarded.** Open on the mirror side: the automatic mirror's first real run (the owner's, with M2's
  steps); M5 with its coder. On the GUI path: K1c in its full runs with Core, then G1.
- 11-15 18:52 (the new integrator): **the owner completed the test chat's mirror for real (18:49): 352 messages in four batches at a
  20 s pause, no wait, 69 s.** Read read-only: 751 forwarded, each once (747 with media and 4 album members
  with no media row); nothing left. In `TELEGRAM-FACTS.md` section 11 and the handoff (**main head 5302000,
  equal to `private`, clean**). **The owner's question (18:52): how often the automatic mirror fires, the
  last 20 messages, a variable timer.** Answered from the code; a row in the board's listed table for the
  mirror track (a bounded random part on the times; a setting for how soon new messages go) and a message to
  it with the plan's wording (4 album members counted and not said).
- 11-15 19:00 (the new integrator): **K1c AND THE VIEWER'S ENTRY 17 ARE MERGED AND PUSHED: head 0697f15, equal to `private`, clean.**
  0f1e319 the code of K1 (`wip/core-chosen-c` 144dab1 as `git diff 9dd5a21 144dab1` on 5302000: files only
  from chats the owner chose; no schema step); then the viewer's `wip/b-once` b2dfe5b (each file once, a
  click plays or pauses, the numbers file). Each branch's code on the main tree is identical to its tested
  tree (`runs-k1c/`: whole collector 593 s, mirror 105 s, catalog 415 s with the one real-time test run again
  alone, server; `runs-b5/`: whole viewer 267 s, the race detector 690 s, no data race), so no second full
  run; on the combined tree: build, vet, gofmt clean, the viewer's wall tests, whole `cmd/tgarchive` and
  `internal/server` ok. Read by me: K1c's own round (the released guards, the read-only door) and the
  baseline. **NOT DONE YET: the documents, the installed collector (still 9dd5a21's build), the board and the
  queue, the head told to the pages session (G1) and to Core.** Open by design: K1's review point P3 closes
  with the copies' E12; until then no real run on a chat read first and chosen later.
- 11-15 19:01 (the new integrator): **the documents and the installed collector are done: main head fa8c011 (equal to `private`,
  clean); the installed collector is the build of fa8c011 since 19:00** (no collector was running; 9dd5a21's
  build kept as a `.bak`; its help lists `choose` and `-new-chats-download`). fa8c011: the roadmap's two new
  rows, the handoff, the reviews of K1 and of the viewer's each-file-once in `docs/review`. The board (my
  row, the waiting line, a line on the owner's list about K1's one-time baseline at the first `run`), the
  queue (K1c and 17 marked merged). The pages session is told the head (G1 next); Core's K4 and K3 wait for G1.
  **Waiting:** G1's hand-over (its full runs with the race detector on the collector are the pages session's).
- 11-15 19:17: **STATE FOR A TAKE-OVER (the owner, 19:15: every session is long; a new integrator is to start). Written by the
  integrator session of 16:22; it merges nothing further once the next one has started.**
  **`repo-archiver`: main head fa8c011, equal to `private`, clean, nothing staged. Schema step 18 merged** (19 is
  Core's K4, on the queue; 21 the mirror's M5, on its branch). **Installed collector: the build of fa8c011
  (19:00)**, built with the patched toolchain; its first `run` on the test catalogue runs K1's one-time
  baseline (the owner is told: waiting list). My copy `wt-int-m4` and its branch are removed. No agent or
  background command of mine is running.
  **Merged by this session today:** C6 (09fd59c), the viewer's entries 16 (9a51a92) and 17 (0697f15), M4
  (be429e1, after three fix rounds and my reviewer's three passes: `wt-mirror-review6-scratch/REVIEW.md`), K1
  (0f1e319); documents after each. For real, by the owner, on the test account: the settle (65 of 99, 34 put
  back), the put-back forward (not refused as a repeat), the chat's mirror completed (751 messages, each once):
  `TELEGRAM-FACTS.md` section 11.
  **ON THE QUEUE, NOT MERGED:** K4 `wip/core-protected` 8d2daff (schema 19: the ladder in `catalog.go` meets
  step 18; set `protectedAfter` to the mirror's step; "after K1c and G1" by its entry, though nothing stops it
  going first) and K3 `wip/core-nastest` abb20c3 (one test file; check it compiles on the head: M4 and K1
  changed the rig and the fake).
  **COMING, in the order of need:** (1) **G1** `wip/pages-g1` (pages; head 8138f78 at 19:10, taking fa8c011 in;
  its full runs with the race detector on the whole collector are the pages session's; then merge, and
  install its build as the installed collector: the owner said yes, item 17). (2) copies: E12 (the set rule: it
  closes K1's open point P3; the failing test is `K1c-P3-test-for-copies.go.txt`), E13 (the part store,
  passed its runs), E14 (the engine's probe turn: download-path code, its race run is the copies session's),
  E11 (the fingerprint at save, in review). (3) Core: K2 the watchdog (in its last round). (4) mirror: M5
  `wip/mirror-name` (in its fix round; schema 21). (5) viewer: `wip/b-window` (the native window; it adds one
  pure-Go requirement to `go.mod`, agreed in principle: board message 28 a).
  **WAITING FOR THE OWNER (the board's list):** 19 (report the Windows call hazard upstream), 20 (the NAS copy
  test: run once at 18:57, all files verified; the helper pass ran at about 19:10 by Core's notes), 21 (what
  "same / not the same" does to a held file: recommended yes), 23 (K1's baseline at the first `run`: for
  information), 24 (the program's own folder, four choices: pages, `DESIGN-G6-one-folder.md`). Not yet run by
  the owner: the automatic mirror (`run -auto-mirror`), the viewer's build of b2dfe5b.
  **THE OWNER'S STANDING WORDS OF THIS SESSION:** commands that work from any folder, always (message 39); the
  app ends as one standalone .exe with its folder (message 40); a pause of downloads and "pause for X hours"
  (message 30); the automatic mirror's timing varied (listed, mirror); the old app is not a concern any more
  (message 32); on the NAS every Docker container in host network mode (Core, in `CLAUDE.md`).
  **HOW FULL (19:17):** Core 83%, viewer 79%, pages 75%, this session 64%, copies 62%, mirror 52%; the
  account's week: 63% of all models, 69% of this model, resetting in 5 days 19 hours. Board message 44 asks
  every track to hand over at its natural point (its piece listed) with a take-over block.
  **NEXT STEP FOR THE NEW INTEGRATOR, in one line:** review every track against the disk, then merge G1 when
  it is listed, then K4 and K3, then the copies pieces with E12 first.
- 11-15 19:50 (the integrator session started 19:47 with `START-INTEGRATOR.md`): **THE REVIEW OF EVERY TRACK AGAINST THE DISK.**
  Read: `CLAUDE.md`, the whole board, the take-over block above, the live entries of `MERGE-QUEUE.md` (K4, K3,
  18, M5, C8, K2, K5), the handoff's block, the end of each track's progress file. Checked: 19 copies; **the main
  branch fa8c011, equal to `private`, clean, nothing staged; every `wip` branch equal to its pushed head.**
  Uncommitted work in three copies only, each with a coder in it: `wt-b-window` (9 files, mpv's bar),
  `wt-b-faces` (4, thumbnails after a jump), `wt-pages-g2` (3, the Queue page).
  - **Pages (P2):** G1 `wip/pages-g1` 541743d holds fa8c011; its Windows full runs all ended "exit 0"
    (collector 681 s, server 75 s); **the race detector on the whole collector is still running** (started
    19:26, the pages session's); not listed yet. G2's coder runs. Last entry 19:27, saved.
  - **Core (K):** K2, K4, K3, K5 listed, all four copies clean and pushed; nothing running; a take-over block
    (19:46) and the owner's decision of 19:49 (a probe is fine) written. The session is long: a fresh one is due.
  - **Copies (C2):** C8 (E13 with E14) listed, clean. E12 03d846e passed its whole catalogue run; its
    dependents' run has three of four "exit 0", the collector still going; then entry C7. E11 490a727 with its
    reviewer (second pass). Last entry 19:38, saved.
  - **Mirror (M2):** M5 fb8ab31 listed, clean; ready for a take-over since 19:29; nothing running.
  - **Viewer (B4):** entry 18 (65d20f2) is listed, but its session wrote at 19:45 that the head will be
    replaced: the owner used the window and two fixes are with coders. **So 18 is not merged yet.**
  - **Saving:** every track has a progress entry and notes commits within the last half hour (since 18:30:
    copies 24 commits, Core 14, mirror 9, viewer 8, pages 6). None is behind.
  - **Sessions:** all five building sessions exist and are idle between turns; mirror and Core have said
    "ready for a take-over". **The account's week: 68% of all models, 74% of this model (63 and 69 at 19:17:
    five points in about half an hour), resetting in 5 days 19 hours.**
  - PC at 19:49: 4.2 GB free, CPU 75% (a collector test run and race containers of two tracks).
  **My order:** K2 and K5 now (new folders and two deploy files: they meet nothing and change no package G1's
  runs covered); then, when G1 is listed, G1 as tested; then K4, K3, M5 and C8 on one combined tree with one
  set of whole runs; C7 (E12) when listed. Entry 18 when its new head is listed.
- 11-15 19:51: **K2 and K5 are being STAGED on the main tree (fa8c011), NOT COMMITTED.** K2 `wip/core-watchdog` e83b22c: 31 new
  files in three new folders (`internal/crashlog`, `internal/watchdog`, `cmd/tgarchive-watchdog`); K5
  `wip/core-nasdeploy` 35ca912: two deploy files. Read by me: the watchdog's restart decision (`policy.go`
  `Decide`, `classify.go`, `loop.go` `after`): a restart only for a crash, never under 2 minutes, never before
  the status file's latest wait or gate plus 60 s; an unreadable status file is counted and leaves the delay
  alone (parts' waits are also kept in the catalogue: `PartWaits`). K5's difference: placeholders only.
  Plan said to the owner: the three packages' tests, gofmt, vet, a whole build; no race run (its packages are
  the tested tree's). If this session stops: `git -C repo-archiver status` shows the staged files; `git
  restore --staged --worktree` of those paths puts the tree back to fa8c011.
- 11-15 19:54: **K2 AND K5 ARE MERGED AND PUSHED: main head 2c5765f, equal to `private`, clean, nothing staged.** One commit: the
  watchdog's three folders (byte for byte the branch's tested tree: the three tree ids compared), the two
  deploy files, the roadmap's rows (crash log, watchdog, the copy to the NAS, the helper, hard links), the
  handoff (two new paragraphs; the installed build's line corrected to fa8c011), the watchdog's two reviews
  in `docs/review`. On the main tree: gofmt clean, `go build ./...` and vet exit 0, the three packages'
  tests ok (4.7 s, 2.4 s, 0.8 s). **`tgarchive-watchdog.exe` of 2c5765f is installed beside the collector**
  (no `tgarchive*` process was running; its help printed from another folder). The installed collector
  stays the build of fa8c011: no collector code changed.
  Notes: the queue's K2 and K5 entries and a current-state line; the board (my row, the merged line, message
  47: the schema numbers follow the order of the merges: K4 19, M5 20, the copies' tables the next free; my
  order; entry 18 waits for its new head); a BEL byte in the board's message 29 (c) put right.
  **Next step:** when the pages session lists G1 (its race run of the collector started 19:26): merge it as
  tested, install its build; then K4, K3, M5, C8 on one combined tree.
- 11-15 19:56: **RUNNING: an independent reviewer on M5's fix round** (a background agent of this session, Opus; brief
  `BRIEF-M5-review-2.md`; read-only on `wt-mirror-name` fb8ab31; its folder `wt-mirror-review8-scratch`, its
  report `REVIEW-2.md` there; named tests only). Why: the fix round (`02abe15..fb8ab31`: the number's loop,
  a rename's refusal, the automatic task's hold, the text check) decides which channel a lost create adopts
  and had no review of its own. M5 is not merged before its answer; a round, if one is needed, is the mirror
  track's. PC before: 4.0 GB free, CPU 68%. **If this session stops:** read that `REVIEW-2.md`; if it is not
  there, start the review again from the brief.
  Also waiting: G1's listing (the pages session's race run of the collector, started 19:26).
- 11-15 19:59: **THE NEXT BATCH IS PREPARED IN A COPY OF MY OWN, NOTHING OF IT ON THE MAIN BRANCH.** Copy `wt-int-batch`, branch
  `int/batch-1115` (local, never pushed), from 2c5765f, two tentative commits: (1) G1 as `git diff fa8c011
  541743d` (applies cleanly; its `internal/collector` and `internal/server` trees equal the branch's tested
  ones); (2) K4 `wip/core-protected` 8d2daff, K3 `wip/core-nastest` 9089f21 and C8 `wip/copies-14` 8565a46,
  each as its own difference from its base. One conflict, `catalog.go` (three places): both steps kept, the
  mirror's 18 first, `protectedAfter = mirrorAutoSchema` so the protected flag is step 19. On that tree:
  gofmt clean, `go build ./...` exit 0, `go vet` of catalog, collector, engine, parts, telegram, tgstore,
  server and the commands exit 0 (so K3's test file compiles against G1's rig). **No test has run on it.**
  Read by me for this batch: TRIED-BEFORE 6, 9, 10, 15, 17, 19, 21, 24, 25, 27; COPY-CHECKS-STUDY E; answers 4
  (section C) and 8 (section C); FEATURES 12 to its fourth round; the live lessons' 6b; K4's whole difference
  in existing files and its step; C8's `lane.go` difference (a kept part is taken where its request would be
  sent and is no answer of Telegram's; a probe turn's parts go by the lane's ordinary request path and are
  counted as parts and again apart; a failed put ends the probe with what was kept; no checkpoint, no
  hand-over); G1's lines in `account.go` and the design of `ownerstop.go` and `pausedl.go`.
  **Waiting for:** G1's listing (the pages session's race run of the collector, started 19:26; a background
  watcher of this session ends when its log does) and the reviewer's `REVIEW-2.md` on M5.
  **Then, in this order:** G1 onto the main tree as tested, pushed, its build installed (no collector running;
  the build before it kept); M5 onto the batch as step 20 if its review allows; one set of whole runs on the
  batch (catalog, collector, mirror, telegram, tgstore, engine, parts, supply, server; no race run: each
  branch raced its own concurrent code and none changes another's package), said to the owner first; merge.
  PC at 19:59: 3.6 GB free, CPU 82% (other tracks' runs): the whole runs wait until more is free.
- 11-15 20:03: **THE OWNER (20:00): the usage was reset in full ("we have options"); asked what is left, what I would do first, and
  whether the app can be used like a Telegram client ("interact with chats/messages? That should be added as
  well if not already here").** Checked: the viewer lists chats and pages a conversation from the catalogue;
  nothing acts in a chat. **Listed the same hour:** `FEATURES.md` section 12, sixteenth round; two roadmap
  rows (reading: viewer; acting: Core for the requests and the collector's door, the buttons the viewer's,
  the door's place pages'); **main head eb129cc, pushed, clean**; the board's "Listed and unbuilt" row, item
  25 on the owner's list (the scope and order: recommended reading first, then text actions, files last) and
  message 48 (also: message 44's "start no new piece" lifted for sessions with room).
  My order given to the owner: G1 into the owner's hands and the pages after it; the day-long real run with
  one deletion seen; the frame check end to end; the automatic mirror's first real run; the client's reading
  side, then the design of its acting side; operations (backup, alerts). Asked: fresh Core and mirror sessions.
  Still running: the reviewer on M5; the watch on G1's race run. Nothing staged anywhere.
- 11-15 20:09: **M5's second review pass is back: it may merge as it is** (`wt-mirror-review8-scratch/REVIEW-2.md`; 0 high, 0 medium,
  6 low for the mirror track's next round: board message 49; the first review's nine findings fixed, one in
  part). Read against the code by me: the number's loop inside `BeginMirrorCreate`'s transaction; K4's step
  19 is idempotent (column only when missing, trigger dropped and made) and its trigger fires only on the
  `protected` column, so M5's fill and a rename do not set it off.
  **The batch in `wt-int-batch` now holds M5 too (tentative commit 601cb9a, local only):** fb8ab31 as its
  difference from 9dd5a21; `catalog.go` resolved (all steps kept; version = the mirror name's);
  `mirrorNameAfter = protectedSchema`, `mirrorNameSchema = mirrorNameAfter + 1` (step 20). Two test fits:
  `chosen_test.go` (K1's call of `BeginMirrorCreate` gains the rule) and `protected_test.go` (the step it
  follows). gofmt, build, vet clean; by name: the catalogue's schema, protected and mirror-name tests ok
  (8.6 s), the collector's seven mirror-name and older-catalogue tests pass. **No whole run yet: they start
  after G1 is on the main branch, and not while its race run is going** (three race containers of other
  tracks run now; more load could fail their timing tests).
  G1: listed at 20:03 as "NOT READY UNTIL ITS RACE RUNS END"; the collector's race container is up about 40
  minutes; a 30-minute watch of this session is armed (re-arm at expiry).
- 11-15 20:10: **ENTRY 18 (the native window, `wip/b-window` 1aa9ac4, listed 20:08) IS BEING STAGED on the main tree (eb129cc), NOT
  COMMITTED.** It holds 2c5765f (the main head's code; eb129cc is documents only on top). Read by me:
  `LESSONS-viewer-ix12.32.md` whole, `LESSONS.md` 1 and 2; `internal/window/msg.go` (a page message is one of
  nine exact shapes with bounds; only a number names a file), `play.go` `playerProgram` and `handleOpen`; the
  `go.mod` lines (one pinned pure-Go requirement, one indirect). Plan said to the owner: build, gofmt, vet,
  the viewer's wall tests, the window package's tests; no whole or race run (the tested tree is the merged one).
  If this session stops: `git -C repo-archiver status`; `git restore --staged --worktree .` there puts it back.
- 11-15 20:12: **ENTRY 18 IS MERGED AND PUSHED: main head 2625aa0, equal to `private`, clean, nothing staged.** The native window
  with mpv and the thumbnails after a jump (`wip/b-window` 1aa9ac4 as `git diff 2c5765f 1aa9ac4`; the trees
  of `internal/viewer`, `internal/window`, both commands and `go.mod` equal the branch's, so its whole and
  race runs were not repeated). On the main tree: gofmt clean, `CGO_ENABLED=0 go build ./...` exit 0, vet of
  viewer, window and the commands exit 0, the window's and the commands' tests and every wall test ok. The
  roadmap's two rows, the handoff's paragraph, the two reviews in `docs/review`. Notes: the queue's entry and
  state line, the board (my row, the merged line, message 50). No install by me: the viewer's and the
  window's programs are the viewer track's own builds in its `bin`.
  A lesson of my own: a backslash followed by a letter, written through the shell tool inside a script's
  text, reached the board as a backspace byte twice (message 50's first writing); put right with chr(92).
  Any text with a Windows path goes through the Write or Edit tool, or chr(92).
  **Next step:** move `wt-int-batch` onto 2625aa0; wait for G1's race run; then G1, its install, the batch's runs.
- 11-15 20:20: **THE OWNER: "Start both". Two fresh sessions started by this one:** Core (its name among the linked sessions:
  archiver-core-2; brief: take over from the 19:46 block; the `a3` scripts through the watchdog, the
  day-long run's steps for the owner, `DESIGN-CORE-client-actions.md` for the client's acting side, then
  the store's put-off, the hours without the speed limit, the backup) and mirror (archiver-mirror-3; from
  the 19:29 block; the timing first, the protected refusal with the review's six low findings once M5 and K4
  are merged, M6, forums; the automatic mirror's first real run prepared for the owner). Both report through
  the files; their turn notes reach this session. On my board row. The batch is on 2625aa0 in `wt-int-batch`
  (65844f8, local), builds and vets. Still waiting: G1's race run (the watch is armed to about 20:35).
- 11-15 20:36: **G1 IS HELD: its race run of `internal/server` was cut at its 30-minute bound (20:10), and the pages session wrapped
  up at 20:04, so nobody acted.** The log: "test timed out after 30m0s", running `TestOverviewCostAtSize`
  (9 min 43 s in; runnable, not shown to hang), no data race report; `livepages` ok. The collector's race
  container (P2's, from 19:26, bound 150 min) is still up at low CPU; P2's background command is still alive,
  so its log will be written.
  **RUNNING, mine: the server package under the detector again, bound 90 minutes: the container
  `int-g1-race-server`** (detached, kept after its end; started 20:36; 2 CPUs, 3 GB; the copy `wt-pages-g1`
  read-only). A first start through a background shell command was stopped by me after a minute (such a
  command is ended after ten minutes) and its container removed. A watch of this session (30 minutes,
  re-arm) writes `runs-int-g1/race-server.log` with "exit N" when it ends.
  **If this session stops:** `docker ps -a` for `int-g1-race-server`; `docker logs int-g1-race-server` and
  `docker inspect int-g1-race-server --format '{{.State.ExitCode}}'`; then `docker rm int-g1-race-server`.
  For G1's collector run: `runs-pages-g1/race-collector.log` ends in "exit N".
  Board message 51. **Pages has no session:** asked of the owner.
  PC: 5.4 GB free, CPU 52% before the start.
- 11-15 20:50: **G1's RACE RUN OF THE WHOLE COLLECTOR ENDED 20:49: FAIL, 4,929 s, two tests** (`runs-pages-g1/race-collector.log`).
  (a) One data race report, in the fake Telegram's `invoker.Invoke` (two answers sharing one `*tg.Document`
  encoded at once; the library's `Encode` writes the flags field): on the main branch already, not G1's
  (`faketg` and that test are untouched by G1): Core's, board message 52 a. (b) G1's own
  `TestPauseEndsByItself` failed on its precondition under the slow run ("nothing to judge"): a test fault,
  the pages track's, on `wip/pages-g1`, a test file only (message 52 b). (c) No race reported in G1's product
  code. **G1 is NOT merged and not ready.** Pages has no session (asked of the owner at 20:37; no answer yet).
  Running: `int-g1-race-server` (the server package under the detector, 90-minute bound, since 20:36).
  The batch in `wt-int-batch` holds G1's 541743d: when G1's head moves by a test file, I replace it there.
- 11-15 21:09: **THE OWNER: "Start pages". A fresh pages session started by this one** (archiver-pages-3; brief: take over from P2's
  20:04 block; first G1's `TestPauseEndsByItself` on `wip/pages-g1`, a test file only, then by name under the
  detector five times and the new head in entry G1; it does not start the server race run again: that is
  mine, `int-g1-race-server`, 45 minutes in at 21:09; then the Queue page's read, browser pass, review and runs;
  then G3, G5, G4, G6). On my board row.
  Reported by the sessions I started, not checked by me: Core has K7 (the fake Telegram's race,
  `wip/core-faketg` c2f7232) in its whole collector run and K6 (the nightly backup) in review; the mirror has
  its timing piece (`wip/mirror-timing`) in a fix round after its review, the automatic mirror's first run
  on the owner's list as item 26 and a first design for adopting a chat as item 27.
  **Next step:** the server rerun's result onto the board; G1's new head into `wt-int-batch` in place of
  541743d; G1 onto the main tree, its build installed; then the batch's whole runs.
- 11-15 21:16: **G1's `internal/server` PASSED under the race detector (my rerun): ok, 2,382 s, exit 0, no data race report**
  (`runs-int-g1/race-server.log`; the container removed). The first run's cut at 30 minutes was its bound.
  Board message 53. **G1 now waits only for its one test** (`TestPauseEndsByItself`, the new pages session's
  first job). Nothing of mine is running.
- 11-15 21:23: **G1 IS MARKED READY at ee437a46 by the new pages session (21:22): 541743d plus nine test files and the report, no
  product code** (checked: `git diff --stat 541743d ee437a46`; pushed; the copy clean). `TestPauseEndsByItself`
  holds its files' parts until the pause holds (5 of 5 by name under the detector, 289 s; 3 of 3 on Windows);
  twelve more tests moved to held parts the same way; the server's two at-size tests skip under the detector
  by a build tag (read by me: `race_on_test.go`, the two skips; nothing else skipped).
  **NOT MERGED YET, my choice: two named detector runs on ee437a46 are still going** (the pages track's
  containers: the 13 changed collector tests, started 21:07; three server tests, started 21:16). They run
  on the very head I would merge, so I wait for them; a watch of this session is armed (30 minutes).
  `wt-int-batch` now holds ee437a46 (tentative commit 6a0cd66 on top; `internal/server`'s tree equals G1's;
  vet of collector and server exit 0). The batch's whole runs are not started: PC at 3.9 GB free, CPU 73%
  with three tracks' runs going.
  **Next step:** both named runs "ok" -> G1 onto the main tree as `git diff fa8c011 ee437a46`, build, vet,
  commit, push, install its build (item 17: the owner's yes); then the batch's whole Windows runs, said first.
- 11-15 21:24: **G1 STILL NOT MERGED: the named detector run of the changed collector tests on ee437a46 ended 21:23 with ONE failure,
  `TestE2EPages`** (`pages_e2e_test.go:202`: POST /api/chats/estimate, the client's timeout; 908 s; no data
  race report; `runs-pages-g1/race-collector-named-ee437a46.log`). Read by me: the test's client times out at
  30 s (`pages_test.go:54`) and the handler's own answer bound is the same 30 s (`server/reads.go`
  `estimateAnswerBound`): a test that depends on real time; unchanged since 541743d; it passed in the
  82-minute whole run. The product's handler is bounded and answers "asked". The pages session had already
  started the test again by itself (container `p3-g1-race-e2e`); told it what I read. **I hold G1 until its
  entry says what was decided** (the test fixed, or passed alone and named as still to fix: message 17).
  The server's three named tests are still running. PC: 3.9 GB free, CPU 70%.
- 11-15 21:38: **G1 IS READY AGAIN (the pages session, 21:38) AND IS BEING STAGED on the main tree (2625aa0), NOT COMMITTED.**
  `TestE2EPages`'s failure under the detector is explained with a probe by overlay: the fake Telegram's
  topics answer can never be encoded (a missing `FromID` in `faketg/server.go` `topics()`), the reader sends
  the request again five times with pauses, and the estimate waits behind it; with the field set the test
  passed 10 of 10 under the detector. Core's, for K7 (board message 58). Nothing in G1's product code.
  Staging `git diff fa8c011 ee437a46`. Plan said to the owner: build, gofmt, vet, whole `internal/server`
  and `cmd/tgarchive` on Windows, the wall tests; no further race run; then the install.
  If this session stops: `git -C repo-archiver status`; `git restore --staged --worktree .` there puts it back.
- 11-15 21:42: **G1 IS MERGED, PUSHED AND INSTALLED: main head c8e49ee, equal to `private`, clean, nothing staged.**
  `wip/pages-g1` ee437a46 as `git diff fa8c011 ee437a46` on 2625aa0 (the trees of `internal/collector` and
  `internal/server` equal the branch's). On the main tree: gofmt clean, `go build ./...` and vet exit 0,
  whole `internal/server` 63.6 s, `livepages`, `cmd/tgarchive`, `cmd/tgarchive-collector`, the wall tests,
  `TestTopicSettleAtSize` 38.7 s: ok. No race run by me (the branch's: collector whole 82 min with no race
  in G1's code, server whole 40 min ok, the changed tests by name). The roadmap's three rows, the handoff,
  the two reviews (the reviewer's scratch path masked).
  **Installed 21:41:** no `tgarchive-collector*` or watchdog process was running; built from the clean head
  to `.new.exe`, fa8c011's build kept as `tgarchive-collector-fa8c011.exe.bak`, the new one moved in; `run
  -h` from another folder lists `-pages` and `-pages-addr`. Its first `run` on the test catalogue runs K1's
  one-time baseline (item 23). **The owner cannot open it by a double-click yet: the starter is the pages
  track's and untried (board message 59 asks for it first).**
  Notes: the queue's entry and state line, the board (my row, the merged line, message 59).
  `wt-int-batch` moved onto c8e49ee (bfdcee0, local): K4, K3, C8 and M5 only now.
  **Next step:** the batch's whole Windows runs, the plan said to the owner first.
- 11-15 21:42: **RUNNING: the batch's whole Windows runs, once** (a background command of this session; `ix-tools/full-runs.sh
  wt-int-batch runs-int-batch "catalog collector mirror telegram tgstore engine parts supply server bringin"
  ""`; the tree `wt-int-batch` bfdcee0 on c8e49ee: K4 as step 19, K3, C8, M5 as step 20). Plan said to the
  owner: about 30 minutes; no race run. Each log in `runs-int-batch/` ends in "exit N"; `started.txt` gets
  an "ended" line. PC before: 4.2 GB free, CPU 39%, no test container.
  **If this session stops:** read `runs-int-batch/win-*.log`; all "exit 0" and `win-gofmt.log` empty: run
  `go test ./internal/collector/faketg ./cmd/...` and `go vet` of the changed packages in `wt-int-batch`,
  then apply `git diff c8e49ee bfdcee0` to `repo-archiver` staged, commit as four pieces or one, push, the
  documents (roadmap rows of K4, K3, C8, M5; the handoff's schema paragraph: step 20), the reviews of M5
  (`wt-mirror-review7-scratch/REVIEW.md`, `wt-mirror-review8-scratch/REVIEW-2.md`) and C8
  (`wt-copies-review13-scratch`, `-14-`) into `docs/review`, then install (a schema step: the test
  catalogue is stepped to 20 at its next read-write open).
- 11-15 21:51: **THE OWNER OPENED THE ONE PROGRAM** (item 29's command; at 21:50 one collector under one watchdog is running: the
  owner's real start on the test account; nobody stops it but the owner). The owner: "The app seems to
  work." A defect: a click on Chats or Overview leaves the page scrolled down a little, the top bar out of
  sight; Accounts and Import do not. And: "still the missing functionality of actually seeing/interacting
  with the chat, like the real telegram client." Board message 60 (pages: the jump; the viewer: the client's
  reading side to the front; Core: item 28 goes to the owner now). The owner asked which questions wait:
  given in this turn (items 19, 21, 24, 25, 27, 28, and the run of item 26).
  The batch's runs: catalog ok 279.8 s; the collector's whole run is going. **The batch's install must wait
  until the owner has quit the running program.** M7 (the mirror's timing, `wip/mirror-timing` bf2c03f) is
  listed, to merge after M5. On the queue for the next batch: 19 (viewer), K7, K6, C9, M7.
- 11-15 21:54: **THE OWNER ANSWERED SEVEN QUESTIONS (21:53): "No issues with any of your choices.. Yes to all."** On the board's
  items: 25 (the client: reading first, then text actions, files last), 28 (the acting side as designed, six
  choices as recommended), 21 (already decided to copies at 20:37: yes to both), 24 (the program's folder as
  designed), 27 (adopting a chat as designed), 19 (report the Windows call hazard: drafts first), and a
  fresh Core session (yes). Board message 61.
  **THEN THE OWNER: "usage is getting low, especially on Fable ... let's see what we can get out of the
  existing remaining usage."** Measured: this model 95% of its week, all models 85%, reset in 5 days 17
  hours; this session's context 56%. **My choices:** the Core session is NOT started (its first hour is
  reading; asked of the owner); every session told to finish to its listing and start nothing new (message
  62); I spend what is left on the batch's merge and install, then K7, 19, C9, K6, M7 as far as it goes.
  **OWED, not done:** the owner's seven decisions into `FEATURES.md` section 12 (sixteenth round) and the
  roadmap's two client rows (the board has them); the owner's list tidied (items 8, 20, 23, 29 are done).
  **STATE FOR A TAKE-OVER (if this session runs out):** main head c8e49ee, equal to `private`, clean; the
  installed collector is its build and is RUNNING (the owner's start, 21:45 or so: nobody stops it but the
  owner). `wt-int-batch` (branch `int/batch-1115`, bfdcee0, local only) holds K4 as step 19, K3, C8 and M5
  as step 20 on c8e49ee; its whole Windows runs go into `runs-int-batch/` (catalog ok 279.8 s; collector
  running at 21:55). When all end "exit 0": `go test ./internal/collector/faketg ./cmd/...` there, then
  `git diff c8e49ee bfdcee0 | git apply --index` in `repo-archiver`, the documents (roadmap rows for the
  protected flag, the part store and probe turn, the mirror's name; the handoff's schema paragraph: steps 19
  and 20), the reviews into `docs/review` (M5: `wt-mirror-review7-scratch/REVIEW.md` and
  `wt-mirror-review8-scratch/REVIEW-2.md`; C8: `wt-copies-review13-scratch`, `-14-`), commit, push; the
  queue's entries K4, K3, C8, M5 marked; **install only when no collector runs (ask the owner to Quit):
  that build steps the test catalogue to schema 20.** Then the queue: K7, 19, C9, K6, M7.
- 11-15 21:59: **THE OWNER QUIT THE PROGRAM (21:58: no collector or watchdog process).** The batch's runs: catalog ok 279.8 s,
  collector ok 665.5 s; mirror running, seven packages to go. **Prepared in `repo-archiver`'s working tree,
  NOT STAGED, NOT COMMITTED (the tree is not clean):** the roadmap's three rows (kept parts, the protected
  flag, the mirror's name), the handoff's schema lines (step 20, next free 21), four reviews copied into
  `docs/review` (`mirror-name-`, `mirror-name-2-`, `copies-parts-`, `copies-engine-probe-2026-11-15.md`).
  They are committed with the batch when its runs have all ended "exit 0"; if the batch is not merged,
  `git -C repo-archiver checkout -- archiver/docs` and removing those four files puts the tree back.
- 11-15 22:08: **THE BATCH AND THE PAGE-JUMP FIX ARE MERGED, PUSHED AND INSTALLED: main head 2580f29, equal to `private`, clean,
  nothing staged; the catalogue's schema step is 20.** 5be96a8: K4 (step 19), K3, C8, M5 (step 20) as
  `git diff c8e49ee bfdcee0` from `wt-int-batch` (the trees of `archiver/internal` and `archiver/cmd` equal
  the batch's tested ones), with the roadmap's three rows, the handoff's schema lines and four reviews.
  2580f29: `wip/pages-scroll` 7d47bdb (the owner's jump after a top-bar click; `internal/server`'s tree equals
  the branch's; its named tests ok). The batch's whole Windows runs, once, all "exit 0" (`runs-int-batch/`):
  catalog 279.8 s, collector 665.5 s, mirror 99.0 s, supply 141.9 s, server 70.6 s, bringin 65.0 s, telegram
  41.2 s, engine 37.6 s, tgstore 10.7 s, parts 1.5 s; `faketg` and the seven commands ok; gofmt and vet clean.
  **Installed 22:07:** no collector or watchdog was running (the owner quit at 21:58); c8e49ee's build kept as
  `tgarchive-collector-c8e49ee.exe.bak`; `mirror -h` lists the rename and the name rule, `run -h` the pages.
  Its next read-write open steps the test catalogue 18 to 20.
  Notes: the queue's five entries and state line; the board (my row, the merged line, message 63).
  `wt-int-batch` and its branch `int/batch-1115` are done with: to remove (`git -C repo-archiver worktree
  remove ../wt-int-batch`, then the local branch), not removed yet.
  **Next on the queue, as far as usage goes:** K7 (after the `FromID` line), 19 (viewer), C9, K6, M7.
  **Owed:** the owner's seven decisions into `FEATURES.md`; the owner's list tidied.
- 11-15 22:09: **THE VIEWER'S ENTRY 19 IS MERGED AND PUSHED: main head e5260c1, equal to `private`, clean.** `wip/b-window` 3244f0d as
  `git diff 2625aa0 3244f0d` (mpv's bar hides again, a listing queues no thumbnail, plays stopped counted,
  the read-only schema door); the trees of `internal/viewer` and `internal/window` equal the branch's; build
  without cgo, gofmt, vet, the window's and commands' tests, the viewer's wall and schema tests ok; the
  roadmap's row. No install by me (the viewer's programs are its track's builds). Board message 64.
  **On the queue still:** K7 (needs the `FromID` line first; Core has no session), C9, K6, M7.
  The installed collector is the build of 2580f29 (the viewer's change does not touch it).
- 11-15 22:27: **THE OWNER (22:24): "Carry on now."** **K6 (the backup program) IS MERGED AND PUSHED: main head 4daa030, clean**
  (`wip/core-backup` b9b8d9a: two new folders equal to the branch's; build, gofmt, vet, its two packages'
  tests ok; rotation read by me; the roadmap's row; the review's two passes in `docs/review`; not installed).
  **C9 (`wip/copies-11` 1301efb, the saved video's fingerprint) IS STAGED on the main tree, NOT COMMITTED**
  as `git diff 2625aa0 1301efb`. Read by me: the copier's whole difference (a bounded "not yet", nil by
  default, never past 2 minutes; a held staged copy passed over, not failed). Plan said to the owner: whole
  `catalog` and `collector` on Windows on the combined tree (`runs-int-c9/`, a background command), no race
  run (store and vfp equal the raced branch). If this session stops: `runs-int-c9/win-*.log` end in "exit
  N"; both 0 and gofmt empty: commit and push; else `git -C repo-archiver restore --staged --worktree .`.
- 11-15 22:32: **THE OWNER: "Started a new usage session. Back to 0%. Provide instructions for a new integrator if needed."**
  Measured: 0% of both weekly limits; this session's context 63%. Done: the fresh Core session started
  (archiver-core-3: K7's line, the first run's read-out, the client's acting side); board message 65 lifts
  the usage hold; `START-INTEGRATOR.md` has a new block "Learnt on 11-15 night"; the owner's seven decisions
  are in `FEATURES.md` section 12 (edited in the main tree, to be committed with C9). The Queue page (G2,
  `wip/pages-g2-main` 2fc8f62) is READY and read by me (the capped retry statement: set-aside files made
  due, never owner-set ones; Telegram's stated waits live in `c_hold`, untouched); its fix round had no
  second review pass: said in the record. C9's runs started 22:27.
- 11-15 22:42: **THE OWNER: "Both". Two more fresh sessions started by this one:** copies (archiver-copies-3: the frame check end
  to end with schema step 21, then confirm or release with the owner's verdicts) and mirror
  (archiver-mirror-4: M7's head merge first, the protected refusal with the review's six low findings,
  adopting a chat as designed, forums). Board message 66. Sessions started by this one tonight: Core twice
  (archiver-core-2 handed over; archiver-core-3 runs), mirror twice (archiver-mirror-3 handed over;
  archiver-mirror-4), pages (archiver-pages-3), copies (archiver-copies-3).
- 11-15 22:48: **C9 AND G2 ARE MERGED AND PUSHED; G2's BUILD IS INSTALLED. Main head 27a7d4d, equal to `private`, clean.**
  2fb8783: C9 (`wip/copies-11` 1301efb, the saved video's fingerprint; store, vfp and footage trees equal the
  branch's; combined whole runs once: catalog 375.4 s, collector 664.8 s, ok: `runs-int-c9/`), with the
  owner's decisions in `FEATURES.md`, the roadmap's row and the review. 27a7d4d: G2 (`wip/pages-g2-main`
  2fc8f62, the Queue page; server and collector trees equal the branch's; whole `internal/server` 108.6 s
  ok; the roadmap's row, the review; its fix round's second review pass is owed and said so).
  **Installed 22:48:** no collector or watchdog was running; 2580f29's build kept as a `.bak`.
  `wt-int-batch` and its branch are removed. Board message 67; the queue's two entries.

## STATE FOR A TAKE-OVER (the integrator session of 19:47; written 11-15 22:48)
A new integrator is started by the owner with "Read `START-INTEGRATOR.md` and do what it says" (that file
has a block "Learnt on 11-15 night"). Until it writes on the integrator's board row, this session merges.
- **`repo-archiver`: main head 27a7d4d, equal to `private`, clean, nothing staged. Schema step 20; next free
  21 (the copies' frame check).** No copy of mine exists; no agent, container or background command of mine
  is running.
- **Installed:** the collector is the build of 27a7d4d (22:48); `tgarchive-watchdog.exe` beside it is the
  build of 2c5765f (unchanged code). `tgarchive-backup` is merged and NOT installed. The viewer's and the
  window's programs are the viewer track's own builds in its `bin`.
- **Merged by this session tonight, in order:** K2 and K5 (2c5765f), entry 18 the native window (2625aa0), G1
  (c8e49ee), the batch K4 + K3 + C8 + M5 (5be96a8) with G1s the page-jump fix (2580f29), entry 19 (e5260c1),
  K6 the backup program (4daa030), C9 (2fb8783), G2 (27a7d4d). Documents after each.
- **ON THE QUEUE, NOT MERGED:**
  - C7 `wip/copies-12` 03d846e (the set mark and the edge at save; it closes K1's open point P3): it holds
    only fa8c011; asked of the copies session to merge the head in and run whole `internal/catalog` (message
    67). When its entry names the new head: read `ladder.go`, `exactcheck.go`, `atsave.go` (rules: a
    probable copy is held, never skipped), apply, whole catalog and collector once, merge.
  - M7 `wip/mirror-timing` bf2c03f (the varied timing): the new mirror session merges the head in first.
  - K7 `wip/core-faketg` c2f7232 (the fake Telegram's race): the new Core session adds the `FromID` line
    (message 58) first. Until it is merged a whole race run of the collector can fail on `TestE2EPages` or
    with a race report in `faketg`: neither counts against a branch that does not touch `faketg`.
  - Coming: pages G3 (the sign-in page: its review found 3 must-fix; a fix round), G5; the viewer's three
    pieces (the window as the only viewer `wip/b-winlan`, every thumbnail in the background, the chat page
    as a client shows it); Core's client request layer; the copies' frame check (schema step 21).
- **SESSIONS (all started tonight at the owner's word, all report through the files):** pages
  archiver-pages-3; Core archiver-core-3; copies archiver-copies-3; mirror archiver-mirror-4; the viewer's is
  B5 (not started by me). Their turn notes reach THIS session, not a new integrator: a new integrator reads
  the board and the queue instead.
- **THE OWNER TONIGHT:** opened the one program ("The app seems to work"), quit it at 21:58; it has not been
  started since the builds of 22:07 and 22:48. Answered seven questions "yes to all" (board message 61; in
  `FEATURES.md` section 12). Wants the chat usable like a Telegram client (reading: viewer; acting: Core, as
  designed). Usage was reset at about 22:30 (0%).
- **WAITING FOR THE OWNER:** item 26 (the automatic mirror's first real run, ready), item 29 (the program /
  the day-long run: ready; the next start steps the test catalogue 18 to 20), the page-jump fix and the
  Queue page to be seen in the installed build. The list itself needs tidying (items 8, 20, 23 are done).
- **OWED BY THE INTEGRATOR:** the handoff's block 0c rewritten as one current state (it has grown by
  paragraphs tonight); `MERGE-QUEUE.md`'s header state line (two lines start alike: edit the second by its
  time); `TELEGRAM-FACTS.md` gets the first real start's numbers once Core has read them out.
- **NEXT STEP, in one line:** review every track against the disk, then C7 when its entry names a head on
  27a7d4d, M7 and K7 when theirs do, each as tested.

## The integrator session of 11-15 22:55 (started by the owner with `START-INTEGRATOR.md`)
- 22:59: **TAKEN OVER. The review of every track against the disk (fetch of `private` at 22:56):**
  - **Read by me:** `START-INTEGRATOR.md`; the board's direction, order, "Listed and unbuilt", every track
    row, the merged and waiting lists, the schema line, messages 1 to 26 and 65 to 68, "Owed" and the whole
    owner's list; the take-over block above with the entries from 21:54; `MERGE-QUEUE.md` to entry M3 and
    entry K7. **Not read yet: board messages 27 to 64 in full (headings only), the queue's later entries
    but K7, the handoff's block 0c.** I read what a merge needs before that merge.
  - **Main:** 27a7d4d, equal to `private`, clean, nothing staged. No `tgarchive-collector*` or
    `tgarchive-watchdog*` process. The PC: 2.0 GB free of 31.1, CPU 68% (five sessions' runs and three
    coders): nothing heavy is started by me until memory is back over about 4 GB.
  - **30 copies; every branch equals its pushed head but one:** `wip/copies-12` is at 15ac7a3f locally
    (the head merged in), `private` has 03d846e: its whole catalogue run is going, the push follows it (the
    copies session's own entry says so). Uncommitted work only where a coder is: `wt-copies-15` (1 file),
    `wt-core-act` (1), `wt-mirror-protected` (7).
  - **Core (archiver-core-3, last turn 22:56):** K7 `wip/core-faketg` 8cca5d44 READY, pushed, clean; K8
    (the client's request layer) with a coder; item 19's two drafts on the owner's list. Saving: yes.
  - **Mirror (archiver-mirror-4, running):** M7 `wip/mirror-timing` f2cedf18 holds 4daa030, NOT ready:
    one test of its own (`TestMirrorAutoRunVaried`) failed once in the collector's `Mirror` set and passed
    7 of 7 by name; the set runs again with its output kept. M8 (protected refusal) with a coder. Saving:
    yes; its last entries are written but not committed, and their times run about two minutes ahead of
    the clock.
  - **Copies (archiver-copies-3, last turn 22:57):** C7's head merge in hand (above); E15 (the frame
    check's catalogue side, schema step 21) with a coder; E16 briefed. Saving: yes.
  - **Viewer (B5, running):** three pieces joined as `wip/b-viewer5` fa39dd4d (it holds 4daa030); its full
    runs ended 22:57: whole Windows viewer, window and commands exit 0, race window and commands exit 0,
    **race viewer exit 1: one test failed, `TestFFmpegOwnFolderFirst`, 0 data races** (965 s). Entry 20 is
    not listed. The session is running and will read it. Saving: yes (22:38).
  - **Pages (archiver-pages-3): IDLE since 22:28, with nothing running, so nothing wakes it.** Its last
    entry is from before message 65 lifted the usage hold (22:32). Waiting in its order: G3's fix round
    (3 must-fix), G6's brief (the owner's yes, item 24), G5's coder. Nothing lost: every copy clean and
    pushed.
  - **Waiting for the owner:** items 19 (two drafts to read), 26 (the automatic mirror's first real run),
    29 (the program / the day-long run; the next start steps the test catalogue 18 to 20); the page-jump
    fix and the Queue page to be seen in the installed build.
  - **Next, in one line:** K7 staged on the main tree and the collector's whole Windows run once when
    memory allows; then M7 and C7 when their entries name a ready head; entry 20 when listed.
- 23:00: **the pages session was woken by one message of mine** (delivered 22:58: read messages 65 to 68
  and carry on in its own order). **K7 (`wip/core-faketg` 8cca5d44) IS STAGED on the main tree, NOT
  COMMITTED** as `git diff 4daa0309 8cca5d44` (7 files: four of the fake's sources, two tests, the
  report); the staged tree of `internal/collector/faketg` equals the branch's. Read by me: the whole
  difference of the four sources (the encoding lock is taken alone; `msgObj` snapshots under the world's
  lock; a pushed update is a decoded copy; the `FromID` line). Plan said to the owner: whole
  `internal/collector` on Windows once on the combined tree (`runs-int-k7/`, a background command, about
  11 minutes), the fake's own package and vet beside it; no race run (the fake's package is the branch's
  tree, raced there; no product code changed). If this session stops: `runs-int-k7/win-collector.log`
  ends in "exit N"; 0 and gofmt empty: commit and push; else `git -C repo-archiver restore --staged
  --worktree .` and remove the three added files.
- 23:02: **THE OWNER (23:00): "It's almost time for bed ... give me a list of what you can work on
  overnight, by priority. We should hopefully be approaching a feature complete standalone app."** Given:
  (1) merges as listed; (2) the standalone app's pieces (pages: sign-in fixes, the program's own folder,
  Staging); (3) installs while no collector runs; (4) a "what is left to feature complete" table for the
  morning; (5) the owed documents; (6) depth behind the pages. **Asked: "May I start a fresh session for a
  track whose session fills up overnight?" THE OWNER: "Yes, restart them."** Also asked, NOT answered:
  whether I may archive the seven retired sessions (54 Claude processes hold 12.8 GB): not done without a
  yes. Board message 69 (the night's rules for every session). The fake's own package on the staged tree:
  vet clean, tests ok 0.2 s, gofmt empty. The collector's whole run is going (`runs-int-k7/`).
- 23:04: **THE OWNER (23:02): "Yes, archive them, once you're sure they're actually retired."** Checked per
  session: named retired or handed over on the board, a leaf (no session started by it), idle for over
  an hour, no copy of its own with uncommitted work, the project folder as its folder (no session
  worktree to clean). **Archived, 7:** M3, K-2, C2, P2, B4, K, B3. **Refused by the app, 4, left:** M2
  ("live work": an agent run or a queued message; not looked into), and the first M, C and P sessions
  ("Keep computer awake" is on in each: left on purpose, the night's runs need the PC awake). **Not
  touched:** the integrator sessions of 19:47 (the parent of four working sessions) and of 16:22
  (pinned), session 11 (it has a session worktree, which archiving cleans), session 10, the review
  session, the START-INTEGRATOR documentation session: not named retired on the board, or not safe.
  Claude processes 54 to 47; 3.3 GB free at 23:03. **C7 is READY at 15ac7a3f (its entry, 22:58).**
- 23:05: **C7's risky part read by me** (`git diff 27a7d4d 15ac7a3f`: `ladder.go`, `exactcheck.go`,
  `atsave.go`, the one line of `chosen.go`), beside TRIED-BEFORE 6: a file held for its chat's, kind's or
  topic's preference that has a probable edge is held as a probable copy or marked for the exact check
  first, never made plain wanted; only the owner's release or "fetch for real" makes a look-alike wanted;
  the step at save adds an edge and changes no state. Nothing in it skips a file or releases one by
  itself. **Plan for C7, after K7 is pushed:** apply `git diff 27a7d4d 15ac7a3f`, compare the catalogue's
  tree with the branch's (its whole catalogue run, 366.9 s, is then the merged tree's), and on the
  combined tree once: whole collector, supply, server, bringin on Windows (about 17 minutes); no race run
  (no concurrent code). **`MORNING-2026-11-16.md` written (first version): what is left to feature
  complete, by what the owner would see, and the owner's commands.** The roadmap's feature rows read in
  full for it. K7's collector run is still going (started 22:59).
- 23:09: **THE OWNER: "Carry on overnight. Did you check in with the other integrator session? It is still
  getting updates from the nested/ongoing agents/sessions."** I had not. One message to the session of
  19:47 (delivered 23:09): it merges, stages, installs and edits nothing from now; when a note of a
  session it started reaches it, it sends me one line if a piece is listed or ready, a session is ready
  for a take-over, a run failed or something waits for the integrator; it was asked to say what is in
  flight on its side beyond its take-over block. Its tree had not moved since 22:48 (checked).
- 23:10: **K7 IS MERGED AND PUSHED: main head 8d9858c.** The collector's whole Windows run on the combined
  tree: ok, 643.7 s, exit 0 (`runs-int-k7/`); the fake's package ok, vet and gofmt clean.
- 23:12: **THE VIEWER'S ENTRY 20 IS MERGED AND PUSHED: main head 2ea9b46, equal to `private`.**
  `wip/b-viewer5` 79bd84b0 as `git diff 27a7d4d 79bd84b0` (56 files); the trees of `internal/viewer`,
  `internal/window`, `cmd` and `deploy` equal the branch's, so its whole runs were not repeated; on the
  combined tree: build without cgo, vet, gofmt, the viewer's wall and schema tests (7.7 s),
  `internal/window` and the seven commands: ok. Read by me: the entry, the window command's difference
  (the home listener is off unless `-lan`; fixed words only). The roadmap's three rows; six reviews
  copied into `docs/review` as `viewer-b5-*` with 5 local paths replaced by a neutral word (a script in
  my scratch folder, checked: 0 left, 0 control bytes). **It also mends a wall test that failed on
  27a7d4d** (`TestWallDependencies` of the viewer, since C9: the catalogue imports `internal/footage`).
  Not installed by me: the viewer's programs are its track's builds.
- 23:12: **C7 (`wip/copies-12` 15ac7a3f) IS STAGED on the main tree, NOT COMMITTED** as `git diff 27a7d4d
  15ac7a3f` (12 files; the catalogue's tree equals the branch's). Its runs on the combined tree started
  23:12, two background lines side by side (8.8 GB free): whole `collector` (`runs-int-c7/`), and
  `supply`, `server`, `bringin` (`runs-int-c7b/`). If this session stops: every `win-*.log` there ends in
  "exit N"; all 0: commit and push; else `git -C repo-archiver restore --staged --worktree .` and remove
  the added files (`git status` names them).
- 23:15: board message 72 and my row (the two merges, the head), the queue's entries K7 and 20 and its
  state line: done and committed (23b1f88; my times there read 23:13 and 23:14 and were written at
  23:12: a minute ahead of the clock). **M7 IS LISTED READY (the mirror, 23:06): `wip/mirror-timing`, the
  piece at cb08ca62, with the main head 27a7d4d merged in as 169d40ab (pushed).** Read by me: the entry;
  TRIED-BEFORE 24 and 25 (the 13 rules); the piece's difference in `auto.go`, the collector's
  `mirror_auto.go` and `mirror_cmd.go`, and the catalogue's new read door: the random part is added on
  top of the pause and of a message's 90 s (never sooner than before), the gathering holds a whole batch
  or nothing, a gathering that cannot be read sends nothing (fail closed), no new write path. Two
  independent review passes are on record in its entry. **Plan for M7, after C7 is pushed:** apply `git
  diff 27a7d4d 169d40ab`; on the combined tree once, side by side: whole `catalog`, `collector` and
  `mirror` on Windows (about 12 minutes; the mirror track ran neither of the first two whole); no race
  run (no goroutine, lock or channel in it); its review into `docs/review`; the roadmap's row. Then the
  collector is rebuilt and installed (its code changed: M7's flags), no collector running.
  **The handoff's block 0c is drafted** (my scratch folder, `handoff-0c.md`: one current state, about
  half the length); it is spliced in and committed with C7 or M7. The PC at 23:14: 8.8 GB free, CPU 82%:
  no second set of runs is started beside C7's.
- 23:15: **the integrator of 19:47 answered:** nothing in flight on its side (no command, agent, container
  or unsaved edit; its copy and branch removed); it merges, stages, installs, starts and edits nothing
  shared from now and sends me one line per note that says listed, ready, take-over, a failed run or
  waiting. Its one miss, said by itself: C9 was merged without the viewer's wall test on that tree
  (`TestWallDependencies` failed on 27a7d4d). **That is mended by entry 20's merge (2ea9b46; the wall and
  schema tests passed on the combined tree at 23:11).** **From it, for every merge that touches
  `internal/catalog`: `go test ./internal/viewer -run TestWall` on the combined tree before the commit**
  (C7 and M7 next). C7's runs at 23:15: supply ok 135.0 s; server and collector going.
- 23:19: **THE OWNER (23:16): "Seems like some rapid progress, but how many things can you get done?
  Remember the objective please."** Answered with numbers: usage is the limit (measured 23:16 and 23:17:
  12% of the week's limit for this model, 8% of all models, 45 minutes after the reset; reset in 5 days
  15 hours; my own context 37%); about 25 pieces left to feature complete; 4 to 6 pieces under a cap of
  50%, 8 to 10 flat out; an order of spending (standalone first, acting in a chat, the frame check, then
  the rest). **THE OWNER (23:17): "It's not a pro plan, it's ultra"** (the usage tool's label is wrong; a
  memory saved: quote percentages, never the plan's name). **THE OWNER (23:18): "Run flat out."** Board
  message 73: the objective, the cost, the order of spending, and the rule at 85% of this model's week
  (finish to a listing, take-over blocks, nothing new). **The integrator of 19:47 was asked (23:18) to
  detach the four sessions it started and to stop forwarding notes** (each note woke a very full
  context); I watch the notes branch and the queue by a background file watch instead. C7's runs at
  23:18: supply 135.0 s, server 97.2 s, bringin 74.4 s, all ok; the collector going.
- 23:20: **THE OWNER (23:19): "Your list is acceptable. Also add in a functioning mirror option since that
  is immediately useful and we've tested it. Also, internalize [the saving: a full context woken by every
  note, replaced by a file watch] as a sensible rule where appropriate."** Done: board message 74 (the
  mirror usable from the pages is 1b in the night's order: pages builds G4 next, ahead of the Staging
  page; the mirror track gives its doors; nothing new is sent to Telegram, so it is not held for a design
  answer: one page of what a click sends goes on the owner's list; the first real click is the owner's;
  and the rule on wakes for every session); one pointer message each to pages and the mirror (a change
  of order at the owner's word; delivered); the morning file's row; `START-INTEGRATOR.md` has three new
  lines under "Learnt on 11-15 night" (usage and wakes, the wall test after a catalogue merge, review
  files without local paths); two memories saved (the plan's name and the cost per hour; cheap wakes).
  My times on the board for messages 72 to 74 run a minute ahead of the clock.
- 23:24: **C7 IS MERGED AND PUSHED: main head 10a9e3a, equal to `private`.** Its runs on the combined
  tree, once, all "exit 0" (`runs-int-c7/`, `runs-int-c7b/`): collector 633.5 s, supply 135.0 s, server
  97.2 s, bringin 74.4 s; gofmt empty; the viewer's wall test, vet of the catalogue and the build ok.
  With it: the roadmap's two rows (the set mark; "only chosen chats" real for one start), the review as
  `docs/review/copies-setmark-2026-11-15.md` (no local path in it), and **the handoff's block 0c
  rewritten as one current state (186 lines to 110)**.
- 23:26: **M7 IS STAGED on the main tree, NOT COMMITTED** as `git diff 27a7d4d 169d40ab` (15 files). Its
  branch has since taken the main head in twice (2da8b60c at 23:14, the entry's READY head): no file of
  the piece changed by that; the staged tree's `internal/mirror` and the piece's five collector and
  catalogue files equal the branch's. Runs on the combined tree started 23:26, two background lines
  (10 GB free; CPU 30 to 69% over 8 s): whole `collector` (`runs-int-m7/`); `catalog` then `mirror`
  (`runs-int-m7b/`). If this session stops: all three `win-*.log` end "exit 0": `go test
  ./internal/viewer -run TestWall`, copy `wt-mirror-review9-scratch/REVIEW.md` into `docs/review`
  through my scratch script (no local paths), the roadmap's row, commit, push; then build and install
  the collector (no collector or watchdog running; the build of 27a7d4d kept as a `.bak`; `mirror -h`
  must list `-timing` and `-gather`, `run -h` `-auto-mirror-steady`). Else `git -C repo-archiver
  restore --staged --worktree .` and remove the added files.
- 23:38: **M7 IS MERGED AND PUSHED: main head 5a516ac, equal to `private`, clean. THE COLLECTOR IS
  INSTALLED FROM IT (23:37).** Runs on the combined tree, once, all "exit 0" (`runs-int-m7/`,
  `runs-int-m7b/`): collector 674.6 s, catalog 403.3 s, mirror 114.9 s; gofmt empty; the viewer's wall
  test, vet of the three packages, the build and the collector command's tests ok. The review as
  `docs/review/mirror-timing-2026-11-15.md`; a roadmap row. **Install:** 0 collector or watchdog
  processes before the build and again before the move; built from the clean head with the local
  toolchain; the build of 27a7d4d kept as `tgarchive-collector-27a7d4d.exe.bak`; the new one says `dev
  5a516ac`; `mirror -h` lists `-timing` and `-gather`, `run -h` `-auto-mirror-steady` and `-pages`. My
  first build command failed harmlessly (the toolchain's script sourced through a pipe: no `go`).
  Board: my row, the merged line, message 76 (the mirror session is asked to bring item 26's plan and
  starter up to the new build's default timing); the queue's entry M7 and state line.
  **STATE NOW: nothing is listed and unmerged; no run, agent or container of mine; the main tree clean.
  Merged by this session tonight: K7 (8d9858c), entry 20 (2ea9b46), C7 (10a9e3a), M7 (5a516ac).**
  **NEXT, in one line:** a background file watch on the notes branch wakes me on a commit whose subject
  says listed or READY (fallback every 50 minutes: usage measured, the board's rows read, the 85% rule).
- 23:50: board message 78 read (the viewer session's error: a viewer window left open on the owner's
  desktop on the brought-in archive since 23:29; not touched by me; it leads the morning file). **THE
  OWNER (23:50): "I closed the viewer window. Anything else you need before I leave the computer?"**
  Checked: 0 window or mpv processes; 8.6 GB free. The watch fired once falsely at 23:49 (a note saying
  K8 "may be listed"); re-armed to fire only on a notes commit that changes `MERGE-QUEUE.md` or names a
  take-over, with the 50-minute fallback. Main head 5a516ac, clean; nothing listed and unmerged.
- 23:58: **the watch woke me at 23:56: K8 is LISTED READY (Core): `wip/core-act` 53362793** (the client's
  request layer; nothing calls it; it holds 2ea9b46). **STAGED on the main tree, NOT COMMITTED** as `git
  diff 2ea9b465 53362793` (9 files; `internal/telegram`'s tree and `status_file.go` equal the branch's).
  Read by me: the entry; the whole new request path in `call.go` (`report`, `keepWait`, `recheck` and
  its helpers): at most one request, the click written down first, everything checked again after that
  write and once more from memory, a wait Telegram states recorded and returned (never slept here, and
  nothing sent while one runs), log lines of fixed words and numbers. Not read by me: `act.go` (1,439
  lines; two independent review passes are on record, the second "may be listed"; its last small round
  had no third pass). Runs on the combined tree started 23:57, two background lines: whole `collector`
  (`runs-int-k8/`); `telegram` then `mirror` (`runs-int-k8b/`). No race run by me (the `TestAct` tests
  were raced on this very tree of the package; no goroutine). If this session stops: all three logs end
  "exit 0": the review into `docs/review` through my scratch script (the review file names this PC's
  folders: 1 line), two roadmap rows (the client's acting side: part), commit, push; no install (no
  collector code path changes). Else restore the tree. **Schema:** step 22 was written twice on the
  schema line (Core's K9a, the mirror's M9): said on the board: numbers are set by me at the merge, in
  the order of merging (21, 22, 23 for the three open steps).
- 00:10 (11-16): **K8 IS MERGED AND PUSHED: main head 29bcfa2, equal to `private`.** Runs on the combined
  tree, once, all "exit 0" (`runs-int-k8/`, `runs-int-k8b/`): collector 679.8 s, telegram 39.6 s, mirror
  97.9 s; gofmt empty; vet and build ok. The review as `docs/review/core-act-requests-2026-11-15.md` (1
  local path replaced); the roadmap's row (acting in a chat: part, piece 1 of 4). No install.
  **USAGE at 00:09: 22% of this model's week, 20% of all models** (23:16: 12 and 8): about 11 and 14% an
  hour; 85% of either at about 06:00. My context 45%.
  **M8 (`wip/mirror-protected` 76df070b, listed 23:57; it holds 5a516ac) IS STAGED, NOT COMMITTED** as
  `git diff 5a516ace 76df070b` (17 files; the trees of `internal/mirror` and `internal/catalog` equal
  the branch's). Read by me: the entry; the difference in `auto.go`, `step.go`, the collector's
  `mirror_auto.go` and `heartbeat.go`: it only adds refusals before a request (a chat the chat list says
  is protected gets no want, no read, no create or forward; the owner's never mark and the flag read
  again before every batch's intent row; a door that fails sends nothing). No schema step, no
  concurrent code. Runs on the combined tree started 00:09, two background lines: whole `collector`
  (`runs-int-m8/`); `catalog` then `mirror` (`runs-int-m8b/`). If this session stops: three logs "exit
  0": the wall test, `wt-mirror-review10-scratch/REVIEW.md` into `docs/review` through my scratch
  script, the roadmap's row for the protected flag, commit, push, then build and install the collector
  (none running; 5a516ac's build kept as a `.bak`). Else restore the tree.
  **Seen on the queue: G2c (`wip/pages-g2c` abda0d40, the Queue page's follow-up; its race run was
  going at 00:03): next, when its entry says the run ended ok.**
- 00:24: **M8 IS MERGED AND PUSHED (1394a9c), G2c IS MERGED AND PUSHED (dbc2f7d: the main head, equal to
  `private`, clean), THE COLLECTOR IS INSTALLED FROM dbc2f7d (00:23).** M8's runs on the combined tree,
  once, all "exit 0" (`runs-int-m8/`, `runs-int-m8b/`): collector 695.7 s, catalog 432.7 s, mirror
  131.5 s; the wall test, vet, build, the collector command's tests ok; its review and the roadmap's row.
  G2c (`wip/pages-g2c` abda0d40, READY 00:18 with its own race run of the server ok, 1,107 s): `git diff
  10a9e3a8 abda0d40`; `internal/server`'s tree equals the branch's, so no second whole or race run; read
  by me: the retry's pick on a reader and its one write by keys (set-aside files only, never the
  owner's own, unique before probable; it sets a time, never a state); on the combined tree the
  collector's three page tests by name, the seven commands, vet, build, gofmt ok; the second review pass
  into `docs/review`; the roadmap's row. Install: 0 collector or watchdog processes; built from the
  clean head; 5a516ac's build kept as a `.bak`; the new one says `dev dbc2f7d`.
  **Merged by this session so far: K7, entry 20, C7, M7, K8, M8, G2c. Nothing is listed and unmerged; no
  run, agent or container of mine; the main tree clean.**
- 00:32: **the watch woke me at 00:31: K9a is LISTED READY (Core): `wip/core-ledger` 51fc8160** (the
  ledger of the owner's clicks: a schema step, two tables, doors; an adapter in `internal/tgstore`;
  nothing calls it; no goroutine). **STAGED on the main tree, NOT COMMITTED** as `git diff 1394a9ce
  51fc8160` (8 files; the trees of `internal/catalog` and `internal/tgstore` equalled the branch's), plus
  ONE COMMENT LINE of mine in `schema_act.go` (the step's number). **SCHEMA: it is the first of the three
  open steps to merge, so it is step 21** (`actAfter = mirrorNameSchema`, as its branch has it: nothing
  renumbered); the copies' frame-check tables and the mirror's want-maker take 22 and 23 in the order
  they merge. Read by me: the entry; `BeginClick` (one compare-and-set from "queued" inside an age
  bound) and `SweepClicksAtStart` (at a start every "sending" becomes "not known", every "queued" "not
  sent": nothing goes out by itself after a stop); the three lines in `catalog.go` and `settle.go`. Two
  independent review passes on record (the second "may be listed"; its last small round had no third).
  **Runs on the combined tree started 00:32, ONE background line, one package after another (CPU 78 to
  89% from other tracks' runs: no second line): whole `catalog`, `tgstore`, `collector`, `server`,
  `supply`, `bringin`, `mirror`, then the viewer's wall and schema tests and the seven commands
  (`runs-int-k9a/`), about 28 minutes.** A schema step is what crosses packages, so every package that
  opens a catalogue runs whole. If this session stops: every `win-*.log` there ends "exit 0": the
  review (`REVIEW-K9a-ledger.md`) into `docs/review` through my scratch script, the handoff's schema
  paragraph (step 21, next free 22), the roadmap's acting row, commit, push, the board's schema line;
  then build and install the collector (its first read-write open steps a catalogue to 21). Else
  restore the tree. **For the owner's morning file (the review's facts, in the entry): a message's text
  the owner typed and that was never sent stays in the ledger for at most 7 days for "send again", and
  in any backup taken meanwhile.**
- 01:02: **K9a IS MERGED AND PUSHED: main head 698ee15, equal to `private`, clean. THE CATALOGUE IS AT
  SCHEMA STEP 21. THE COLLECTOR IS INSTALLED FROM IT (01:01).** Runs on the combined tree, once, all
  "exit 0" (`runs-int-k9a/`): catalog 436.7 s, tgstore 13.4 s, collector 688.0 s, server 156.1 s, supply
  143.9 s, bringin 74.1 s, mirror 148.1 s; the viewer's wall and schema tests 8.9 s; the seven commands;
  gofmt empty. The review as `docs/review/core-act-ledger-2026-11-16.md`; the roadmap's acting row; the
  handoff's schema paragraph (step 21; the two open steps take 22 and 23 at their merges). Install: 0
  collector or watchdog processes; built from the clean head; dbc2f7d's build kept as a `.bak`; the new
  one says `dev 698ee15`. Its next read-write open steps the test catalogue 18 to 21.
  **USAGE at 01:02: 29% of this model's week, 29% of all models** (00:09: 22 and 20): about 8 and 10% an
  hour; 85% at about 06:30. **My context: 51%** (505,000 tokens): I go on to about 75%, then write a
  take-over block and start a fresh integrator (the owner's yes of 23:00 covers a track whose session
  fills up; each wake of mine reads this whole context).
  **Merged by this session so far (8): K7, entry 20, C7, M7, K8, M8, G2c, K9a. Nothing is listed and
  unmerged; no run, agent or container of mine; the main tree clean.**
- 01:14: **THE OWNER (01:12): "How is it looking? Are we on track for an .exe with a GUI? Are you just
  using Fable and Opus? Are you using Sonnet as a clerk for routine tasks?"** Answered: the launcher and
  the program's own folder (G6) are past their second review pass with no must-fix and in a last small
  round; the sign-in page (G3) waits only for its race run of the whole collector; the mirror page (G4)
  waits for the mirror's doors (M9, with its reviewer). On Sonnet: no, not tonight, and not by me: the
  eight merges' mechanical steps were mine, call by call. **Changed from now:** my merges' mechanical
  steps go to a Sonnet clerk in one instruction (a new line in `START-INTEGRATOR.md`); a board message
  tells every session the same for its own routine steps.
- 01:21: **THE OWNER (01:15): "Commit that Sonnet rule somewhere it will be seen and respected."** Done and
  committed on `notes` (41772f7): **`CLAUDE.md`, the archiver section's second point** (what is routine,
  how: one Sonnet agent call on an exact instruction or a script, what stays with Fable and Opus, and how
  it is kept: every progress entry says "by a Sonnet clerk" or why not; the integrator counts it per
  track); **a section near the top of `BOARD.md`**; **a check in `START-INTEGRATOR.md`'s start-of-session
  review**; a memory for future sessions. Running sessions loaded the old `CLAUDE.md`: one short message
  each to pages, Core, copies, the mirror and the viewer (four delivered, the copies' queued), with the
  schema news for the three it concerns. **From my next merge: one Sonnet clerk call for the mechanical
  steps; this entry and the notes around it were written by me (judgement and the owner's words).**
- 01:32: the watch fired falsely at 01:21 (a note saying "may be listed": the match is case-sensitive
  now) and truly at 01:29: **K11 is LISTED READY (Core): `wip/core-readended` b4f0868a** (cut from
  dbc2f7d: a mirror's read that has ended is not read on; `internal/collector` only, 4 files; no schema
  step, no goroutine; the reader only sends fewer). Read by me: the entry and the whole non-test
  difference (`reader.go`, `approve_cmd.go`): the skip applies only to a record that is the mirror's own
  and carries the mark; an owner's record is never skipped; the owner's yes drops the mark. One
  independent review, its must-fix fixed, no second pass.
  **The mechanical steps are BY A SCRIPT from now: `ix-tools/merge-as-tested.sh`** (written 01:30 with the
  Write tool; it parses; no control byte; `ix-tools/scrub-copy.py` beside it): it checks the tree is
  clean outside `archiver/docs`, applies the piece's own difference staged, compares the named trees,
  runs the named whole packages one after another, the named tests, build, vet, gofmt and the commands,
  copies the review without local paths, commits with the message file I wrote, pushes, and installs
  the collector when asked (the process count first; the build before it kept as a `.bak`). It stops
  at the first thing that is not as written and says where. **Running for K11 since 01:31, one
  background command** (`runs-int-k11/`: whole `collector`, the viewer's wall test, install yes; about
  14 minutes). The roadmap's row for it is edited in the main tree and goes in with the commit. **If
  this session stops:** the command's last line is "MERGE-AS-TESTED: done <commit>" (then only the
  board, the queue and this file are owed) or "STOPPED at <step>" (the tree is as that step left it:
  staged and not committed before step 5; `git -C repo-archiver restore --staged --worktree .` puts it
  back, and `git status` names added files to remove).
- 01:47: **K11 IS MERGED, PUSHED AND INSTALLED BY THE SCRIPT: main head 3ced3c0** (its first real run,
  01:31 to 01:44; every line read by me and checked against the disk: the collector's tree equal to the
  branch's; whole collector ok 744.5 s; the viewer's wall test, build, vet, gofmt, the commands ok; the
  review copied, 0 local paths; committed, pushed, equal to `private`, clean; the collector says `dev
  3ced3c0`, 698ee15's build kept as a `.bak`).
  **G6 IS LISTED READY (pages, 01:41): `wip/pages-g6` 04b39389** (the program's own folder, stage A: the
  launcher built as `tgarchive.exe`, its setup page, `make-folder.sh`; new files and one header line in
  `server.go`; it holds dbc2f7d). Read by me: the entry and the whole of `start.go` (the collector's
  run line carries `-vpn-adapter` and `-public-forbid` with the address looked up once; no address: no
  start; every program started hidden with its output to files; a program is held by a handle and only
  such a program can be stopped). Not read by me: the other 5,800 lines (one independent reviewer in two
  passes, the second with no must-fix; its last small round had no pass of its own). **Its merge runs by
  the script since 01:46** (`runs-int-g6/`: whole `launcher` and `server`, the collector's three page
  tests and the viewer's wall test by name, install yes; about 6 minutes). The roadmap's row and the
  second review are in the main tree and go in with the commit. **After "done": build the folder for
  the owner** (`bash archiver/deploy/folder/make-folder.sh <an empty folder outside any repository>`
  from the clean main head) and write its path on the owner's item 31. If this session stops: the
  command's last line says "done <commit>" or "STOPPED at <step>", as for K11.
- 01:50: **G6 IS MERGED AND PUSHED BY THE SCRIPT: main head 5b29e28, equal to `private`, clean; the
  collector installed from it (01:49).** The script's lines, read by me: four trees equal to the
  branch's; whole launcher ok 44.0 s, server ok 154.0 s; the collector's three page tests and the
  viewer's wall test by name ok; build, vet, gofmt, the commands ok; the review copied (and the second
  one by me before the run), 0 local paths; committed, pushed, installed (3ced3c0's build kept).
  **THE OWNER'S FOLDER IS BUILT (01:49): `C:\Users\trabi\tgarchive-app`** (not inside any repository;
  `make-folder.sh` from the clean head with the toolchain's environment: exit 0, "6 programs; 7 files
  moved"): `tgarchive.exe`, `programs` (collector, watchdog, viewer, window, backup, `VERSION.txt`:
  5b29e28), `tools` (empty), `README.txt` (no path of this PC in it). Checked by me: the collector, the
  watchdog and the backup program in it each answer `version` with the commit; the collector's `run -h`
  lists `-pages`. **NOT done: `tgarchive.exe` was not opened** (it would open the owner's browser and,
  after the setup page, start real programs: the first double-click is the owner's, item 31, which now
  carries the path). Board: my row, the merged line, item 31; the queue's entry and state line.
  **Merged by this session so far (10): K7, entry 20, C7, M7, K8, M8, G2c, K9a, K11, G6.**
- 02:04: **the watch woke me at 02:02: C10 is LISTED READY (copies): `wip/copies-16` a52d2a62, THE FRAME
  CHECK END TO END** (the catalogue's step, doors and the part store's ledger; `internal/partsledger`;
  the supply's decision at `Next`; the judge `internal/probejudge`; it holds the main head 5b29e28, so
  the merged tree is the branch's; nothing calls it; no collector, engine or parts file). **SCHEMA: it
  is step 22** (`probeAfter = actSchema`, as its branch has it; nothing to renumber); the mirror's M9
  takes 23. Read by me: the entry (the owner's decisions of 11-16 are in it; the known point: a video
  sharing two thirds or more of a saved one's footage can be held as a copy: held, never skipped); the
  whole difference of the supply's existing files and of `catalog.go`; `probeNext`'s and
  `probeRefused`'s first lines: with `FrameCheck` nil both return at once, so the download path is the
  base's (the reviewers confirmed it by digests three times). Not read by me: the 3,900 new lines of
  `probe.go` (catalogue and supply) and the judge (independent reviews in three and two passes; the
  last two commits of each side had no reviewer). The track's full runs passed before the head was
  merged in, with the race detector on `supply` (1,241.9 s) and the judge.
  **Plan: because it is a schema step, every package that opens a catalogue runs whole on the merged
  tree, one after another: catalog, supply, probejudge (with the real ffmpeg: `FFMPEG_PATH` = the 9.0.2
  build), partsledger, parts, tgstore, collector, server, bringin, mirror; the viewer's wall and schema
  tests; about 32 minutes; no second race run (the supply's and the judge's trees are the raced ones).**
  The CPU was at 95 to 97% from other tracks' runs at 02:02 and at 39 to 45% at 02:03: started then.
  **RUNNING since 02:04: the script for C10, then (only after "done") `make-folder.sh` again on the
  owner's folder**, so that the folder's programs are of the same schema as the installed collector (a
  folder at step 21 would refuse a catalogue the installed build has stepped to 22). In the main tree
  for the commit: the roadmap's two rows, the handoff's schema paragraph (22; the open step 23), the
  judge's review. If this session stops: the background command's output ends with the script's "done
  <commit>" or "STOPPED at <step>", then the folder's line and its `VERSION.txt`.
- 02:37: **C10 IS MERGED AND PUSHED BY THE SCRIPT: main head a557253, equal to `private`. THE CATALOGUE
  IS AT SCHEMA STEP 22. THE COLLECTOR IS INSTALLED FROM IT AND THE OWNER'S FOLDER REBUILT (02:35).** The
  script's lines, read by me (02:04 to 02:35): four trees equal to the branch's; whole catalog 482.0 s,
  supply 159.6 s, probejudge 39.4 s, partsledger 1.7 s, parts 2.0 s, tgstore 15.0 s, collector 736.5 s,
  server 152.0 s, bringin 71.8 s, mirror 132.5 s, all "exit 0"; the viewer's wall and schema tests;
  build, vet, gofmt, the commands; the review copied (0 local paths); committed, pushed, installed
  (5b29e28's build kept). The folder: "built commit a557253: 6 programs; 14 files moved, the earlier
  ones kept in programs/5b29e28"; `VERSION.txt` says a557253. (Two of my read-back calls at 02:36 got no
  verdict from the permission check and went through on the next try; nothing was skipped.)
  **TWO MORE ARE LISTED READY (02:04, 02:05):**
  **C11 `wip/copies-17` d9f0dba0** (the card as ffmpeg's decoder with the CPU as the fallback; ffmpeg
  found beside the program; `internal/footage/ffmpeg` and `internal/vfp` only; it holds 5b29e28). Read
  by me: the entry only (not download path, sends nothing; one independent review in two passes; raced
  on both packages). **In its merge run by the script since 02:37** (`runs-int-c11/`: whole
  `footage/ffmpeg`, `footage`, `vfp` and `probejudge`, which calls the changed package, with the real
  ffmpeg; no install: the collector does not link it yet; about 7 minutes).
  **G3 `wip/pages-g3-main` 884c3ce3** (the sign-in page; it holds dbc2f7d; it changes `collector.go`,
  `account.go`, `signin.go`, `pages.go` and `server.go`, which the main head has moved elsewhere): next;
  it acts for the owner on Telegram (the sign-in's four requests, each on a click): I read its request
  path before it is applied; it needs whole collector and server on the combined tree.
- 02:44: **C11 IS MERGED AND PUSHED BY THE SCRIPT: main head d10e3bd, equal to `private`, clean** (02:37
  to 02:42: the trees of `internal/footage` and `internal/vfp` equal to the branch's; whole
  `footage/ffmpeg` 212.7 s, `footage` 1.7 s, `vfp` 32.5 s, `probejudge` 38.9 s with the real ffmpeg; the
  viewer's wall test; build, vet, gofmt, the commands; the review as
  `docs/review/copies-gpu-decoder-2026-11-16.md`; the roadmap's row; no install: the collector does not
  link it yet).
  **G3 (`wip/pages-g3-main` 884c3ce3) read by me:** the entry; `BeginSignIn` in `signin_pages.go` (the
  page's "Ask Telegram for a code": refused before any dial when a stop was asked, the account is
  removed or signed in, a sign-in awaits its code, or a wait stated earlier still runs; an unreadable
  record sends nothing; then the collector's own `BeginSignIn`, one request). Not read by me: the other
  5,700 lines (one independent reviewer, two passes; the second fix round had no third pass).
  **G3's merge runs by the script since 02:43** (`runs-int-g3/`): `git diff dbc2f7d5 884c3ce3` on
  d10e3bd; the main head has moved `collector.go`, `account.go`, `command.go`, `reader.go` and
  `server.go` since dbc2f7d (the mirror's, Core's and the launcher's pieces), so the apply is a
  three-way one and the script stops if it leaves a conflict; whole `collector`, `collector/livepages`
  and `server` on the combined tree (about 17 minutes), the viewer's wall test, install yes, then the
  owner's folder rebuilt. **No second race run of the whole collector** (93 minutes on its branch, no
  data race; what the main head added to the collector since starts no goroutine). The roadmap's row and
  the second review are in the main tree for the commit. If this session stops: the command's output
  ends with "done <commit>" and the folder's line, or "STOPPED at <step>" with the apply's log.
- 02:58: **G3 DID NOT MERGE. The script STOPPED at "whole collector" (02:43 to 02:56); nothing was
  committed.** The three-way apply left no conflict (32 files); the whole `internal/collector` on the
  combined tree failed on ONE test, the branch's own: `TestSignInRemovalCannotCrossCodeRequest`, subtest
  "request first" (788.8 s; every other test passed; `runs-int-g3/win-collector.log`): the removal was
  refused with a 4xx in the words of a sign-in awaiting its code, where the test wants "A sign-in step
  is under way now". By name on that tree: 20 runs, twice: 10 failure lines in the first 20, FAIL in the
  second. **Read to its cause before calling it anything:** the subtest holds the code request before
  its dial, starts the removal's request in a goroutine and lets the code request go at once; nothing
  holds the order, so the removal can meet either refusal. The account is not removed in either order:
  the product's answer looks right, the test's order is not held. It passed in the branch's own whole
  run. **Not merged with a known-flaky test: every later whole run of the collector, mine and every
  track's, would stop on it.** **The main tree is back at d10e3bd** (`git reset --hard HEAD`, `git clean
  -fd archiver`: 32 staged files and my two documents for it gone; equal to `private`, clean). Handed
  back: the queue's entry G3 says so first, with the cause; one message to the pages session
  (delivered). When it lists a new head on d10e3bd or later with its own whole collector and server
  run, it merges as tested. **The script did what it is for: it stopped and left the evidence.**
  The collector installed and the owner's folder are still the builds of a557253 (C11 changed neither).
- 03:00: **K12 is LISTED READY (Core, 02:40; I saw it at 02:58, after G3's run): `wip/core-wdrename`
  38a790bc** (the watchdog's status file put in place also under a reader, and the readers' door
  `watchdog.ReadStatus`; `internal/watchdog` only, 8 files; cut from 5b29e28; no schema step). It is the
  cure for the launcher's known point N2. Read by me: the entry; `loop.go`'s and `rename_windows.go`'s
  difference (a refused rename is tried again within 200 ms, 2 s only at the watchdog's end when
  nothing is supervised; nothing in the child's supervision waits longer). One independent review,
  "may be listed", its seven points done in a round with no second pass. **Its merge runs by the script
  since 02:59** (`runs-int-k12/`: whole `watchdog`, `crashlog`, `launcher`; the viewer's wall test; no
  collector install), **then, in the same background command and only after "done": the watchdog
  installed beside the collector** (no collector or watchdog running; the build of 2c5765f kept as a
  `.bak`) **and the owner's folder rebuilt.** The roadmap's row is in the main tree for the commit. If
  this session stops: the output ends with "done <commit>", "watchdog installed", the folder's line and
  its `VERSION.txt`, or "STOPPED at <step>" (then `git -C repo-archiver reset --hard HEAD` and `git -C
  repo-archiver clean -fd archiver` put the tree back).
- 03:01: **K12 IS MERGED AND PUSHED BY THE SCRIPT: main head 8aed433, equal to `private`, clean** (02:58 to
  03:00: the watchdog's tree equal to the branch's; whole watchdog 7.4 s, crashlog 3.4 s, launcher
  42.8 s; the viewer's wall test; build, vet, gofmt, the commands; the review copied). **The watchdog is
  installed from it (0 collector or watchdog processes; 2c5765f's build kept as a `.bak`; it answers
  `version` with "dev" and no commit: Core's known point) and the owner's folder is rebuilt (`VERSION.txt`
  8aed433; the programs of a557253 kept inside it).** The installed collector is still a557253's.
  **Merged by this session so far (13): K7, entry 20, C7, M7, K8, M8, G2c, K9a, K11, G6, C10, C11, K12.
  Handed back (1): G3. Nothing is listed and unmerged; no run of mine; the main tree clean.**
- 03:05: **USAGE at 03:01: 46% of this model's week, 48% of all models** (01:02: 29 and 29): about 8.5 and
  9.5% an hour; 85% of all models at about 07:00. **My context: 67%** (670,000 tokens).
  **The board trimmed (03:01): 424 KB to 282 KB.** Messages 1 to 64 and my row's earlier states are in a
  new file `BOARD-LOG.md`, unchanged (the script `ix-tools/trim-board.py`: it writes only when the board
  has not changed on disk meanwhile; 390 lines and 12,056 characters moved; 0 control bytes). Still
  long: the five track rows (16 to 23 KB each: asked of the tracks) and tonight's messages 65 to 94.
  **A FRESH SESSION CANNOT BE STARTED BY ME WHILE THE OWNER IS AWAY.** The mirror session listed M9 at
  02:59 and wrote "READY FOR A TAKE-OVER"; my `start_session` for its successor (a full brief) was
  refused at 03:02: "The user is working over Remote Control, and this turn can't start that session".
  So the owner's yes of 23:00 cannot be carried out at night: the mirror session (68% at 03:02) was told
  by one message to carry on itself until about 90%; the board says the same for every track; and **I
  do not hand over either: I stay the integrator** (the plan of 01:02 to start a fresh integrator at
  75% is dropped). For the morning file: the owner starts the fresh sessions.
  **M9 (`wip/mirror-door` f0d54ad6, listed 02:59; it holds d10e3bd) is in its merge run by the script
  since 03:03 as SCHEMA STEP 23** (`runs-int-m9/`). Read by me: the entry's head, its concurrency and
  race notes, and the whole difference of the collector's `mirror_auto.go`: without `run -auto-mirror`
  the task turns only for an owner's want on record and otherwise returns with no request and no line;
  the look for joined chats stays behind the switch. Not read by me: the doors themselves (`door.go`,
  `mirror_door.go`, the schema file: about 2,200 lines; one independent review in two passes, the last
  small round without a pass; the race detector over the doors' tests by name on the collector's tree,
  752 s, no race). Whole on the combined tree: catalog, mirror, collector, server, supply, bringin,
  tgstore, probejudge (with the real ffmpeg), partsledger; the viewer's wall and schema tests; about 32
  minutes; then install and the owner's folder. In the main tree for the commit: the roadmap's row, the
  handoff's schema paragraph (23; next free 24). If this session stops: the output ends "done <commit>"
  with the folder's line, or "STOPPED at <step>" with the failing test's name (then `git -C
  repo-archiver reset --hard HEAD` and `git -C repo-archiver clean -fd archiver`).
- 03:37: **M9 IS MERGED AND PUSHED BY THE SCRIPT: main head 25816ed, equal to `private`. THE CATALOGUE IS
  AT SCHEMA STEP 23 (next free 24). THE COLLECTOR IS INSTALLED FROM IT AND THE OWNER'S FOLDER REBUILT
  (03:35).** The script's lines (03:03 to 03:35): three trees equal to the branch's; whole catalog
  453.3 s, mirror 161.1 s, collector 799.8 s, server 145.7 s, supply 154.6 s, bringin 70.9 s, tgstore
  13.9 s, probejudge 37.0 s, partsledger 1.3 s, all "exit 0"; the viewer's wall and schema tests; build,
  vet, gofmt, the commands; the review copied; committed, pushed, installed (a557253's build kept); the
  folder "built commit 25816ed", `VERSION.txt` says so.
  **Listed meanwhile by pages: G3 again (03:18, `wip/pages-g3-main` f43f140b, holding d10e3bd: the
  test's order is held now, a test file only; that test 20 of 20 by name; whole collector 811.9 s and
  server on its tree: ok) and G5 (03:19, `wip/pages-g5-main` 7739148c, holding 8aed433: the Staging
  page).** **G3's merge runs by the script since 03:37** (`runs-int-g3b/`: `git diff d10e3bd9 f43f140b`
  on 25816ed, three-way where the mirror's doors moved the collector's files; whole collector,
  livepages and server on the combined tree; no install: G5 follows and installs). I did not measure
  the CPU before this start (an omission). The roadmap's row and the second review are in the main tree
  for its commit. **G5 read by me: its entry only** (pages and one read-only source in the collector;
  two actions on stuck copies through the store's own doors; one independent review, 2 must-fix fixed,
  no second pass). After G3's "done": the roadmap's Staging row, G5 by the script (whole server and
  livepages, the collector's page tests by name; install yes), the owner's folder.
- 03:54: **G3, THE SIGN-IN PAGE, IS MERGED AND PUSHED BY THE SCRIPT: main head 6556113, equal to
  `private`, clean** (03:36 to 03:53: a three-way apply, no conflict, 32 files; the server's tree equal
  to the branch's, the collector's not (the mirror's doors); whole collector 840.5 s, livepages 0.7 s,
  server 127.2 s, all "exit 0"; the viewer's wall test; build, vet, gofmt, the commands; both reviews
  in `docs/review`; the roadmap's row). Not installed yet: G5's run installs.
  **G5's merge runs by the script since 03:54** (the CPU measured first: 15 to 18%, 6.3 GB free;
  `runs-int-g5/`): `git diff 8aed433d 7739148c` on 6556113, three-way in the lists G3 also extended
  (`server.go`, `liveroute.go`, `main.js`, the collector's `pages.go`); whole `server` and
  `collector/livepages`; the collector's staging, page, sign-in and add-account tests by name (no whole
  collector: G5 adds one read-only source file and one line to the collector, and the whole collector
  just passed on the tree under it); the viewer's wall test; install yes; then the owner's folder. If
  this session stops: the output ends "done <commit>" with the folder's line, or "STOPPED at <step>"
  with what failed and the apply's last lines (a conflict in those shared lists is possible: then
  `git -C repo-archiver reset --hard HEAD`, `git -C repo-archiver clean -fd archiver`, and ask pages to
  merge 6556113 into `wip/pages-g5-main` and list the new head).
- 03:55: **G5 DID NOT APPLY: the script STOPPED at its first step (03:54), nothing committed.** Conflicts
  in five files where G3 and G5 both add lines at the same place (`internal/collector/pages.go`,
  `pages_e2e_test.go`; `internal/server/liveroute.go`, `security_test.go`, `server.go`). Both sides are
  the pages track's: **handed back for a merge of the head** (entry "G5" says so first; one message to
  the pages session, delivered): it merges 6556113 in, runs whole server, livepages and its named
  collector tests once, lists the new head, and it then merges as tested. The main tree put back
  (`git reset --hard HEAD`, `git clean -fd archiver`): 6556113, equal to `private`, clean. (My wrap-up
  line of 03:54 said G5 was "in its merge run": it had already stopped; put right in the next message
  to the owner.)
  **INSTALLED 03:54: the collector is the build of 6556113** (0 collector or watchdog processes;
  25816ed's build kept as a `.bak`), **and the owner's folder is rebuilt from 6556113** (`VERSION.txt`
  says so): both now have the sign-in page.
  **Merged by this session so far (15): K7, entry 20, C7, M7, K8, M8, G2c, K9a, K11, G6, C10, C11, K12,
  M9, G3. Handed back, waiting for a new head: G5. Nothing else is listed; no run of mine; the main
  tree clean.**
- 04:05: the watch woke me at 04:03: **G5 is LISTED AGAIN (pages, 04:03): `wip/pages-g5-main` 639ed1c0,
  holding 6556113** (the five conflicts settled with both sides kept; two fittings said in its entry: a
  helper both pieces had named alike is renamed in the Staging page's files; the page's two change
  routes are refused while a stop is held for a sign-in; whole server and its named collector tests
  passed on that tree). **Its merge runs by the script since 04:04** (`runs-int-g5b/`: `git diff
  6556113 639ed1c0`, so the merged tree is the branch's; whole server and livepages, the collector's
  staging, page, sign-in and add-account tests by name, the viewer's wall test; install yes; then the
  owner's folder). The roadmap's Staging row is in the main tree for its commit.
  **Also listed (viewer, 03:41): entry 21, `wip/b-staged` 15763352** (the viewer knows where a saved
  file's bytes are: a lost file is not saved, a staged file is read from the staging folder; the
  roadmap's known defect of 11-13; `internal/viewer` and two flag lists; it holds d10e3bd, and no viewer
  file has changed on the main branch since). Read by me: its entry; that `staging.go` opens a staged
  file only through a root opened read only, by the content name of a validated hash, as a regular file
  of the row's size, and writes, lists and removes nothing. Two independent looks; whole viewer 385 s
  and the race detector on the viewer 2,490 s on its tree, no race. **Next, after G5's "done":** its
  roadmap row, then the script (whole viewer once more on the combined tree, since the catalogue is two
  schema steps on; the wall and schema tests; no install by me: the viewer's programs are its track's
  builds, but the owner's folder is rebuilt, since it holds the viewer and the window). The viewer
  session wrote "ready for a take-over": no successor can be started before morning (the board's
  message of 03:05).
- 04:09: **G5, THE STAGING PAGE, IS MERGED AND PUSHED BY THE SCRIPT: main head 5174cc2, equal to
  `private`, clean; the collector installed from it and the owner's folder rebuilt (04:08)** (04:04 to
  04:08: both trees equal to the branch's; whole server 140.7 s, livepages 0.7 s, the collector's named
  tests 71.3 s, the viewer's wall test; build, vet, gofmt, the commands; the review copied; installed,
  6556113's build kept; the folder's `VERSION.txt` says 5174cc2).
  **Entry 21's merge runs by the script since 04:09** (the CPU measured first: 21 to 32%;
  `runs-int-e21/`: `git diff d10e3bd9 15763352` on 5174cc2; whole `viewer` (about 6.5 minutes) and
  `window` with the real ffmpeg named; no collector install; then the owner's folder rebuilt). The
  roadmap's row and the second review are in the main tree for its commit. If this session stops: the
  output ends "done <commit>" with the folder's line, or "STOPPED at <step>".
  **Merged by this session so far (16): K7, entry 20, C7, M7, K8, M8, G2c, K9a, K11, G6, C10, C11, K12,
  M9, G3, G5.**
- 04:17: **THE VIEWER'S ENTRY 21 IS MERGED AND PUSHED BY THE SCRIPT: main head a37ed4c, equal to
  `private`, clean; the owner's folder rebuilt from it (04:16)** (04:09 to 04:15: the viewer's tree
  equal to the branch's; whole viewer 372.3 s, window 1.0 s, "exit 0"; build, vet, gofmt, the commands;
  both looks in `docs/review`; the roadmap's row). The installed collector is 5174cc2's.
  **USAGE at 04:16: 52% of this model's week, 54% of all models** (03:01: 46 and 48): about 5% an hour
  over the last 75 minutes: slower than before; 85% not before mid-morning at this rate. **My context:
  76%** (757,000 tokens; it compacts by itself at 97%; this file holds everything a compacted or new
  integrator needs).
  **The owner's folder keeps every earlier set of programs: 772 MB in `programs` after eight rebuilds**
  (about 115 MB a rebuild; `make-folder.sh` keeps them by design). For the morning file: the older sets
  may be deleted.
  **Seen: K9b (Core, 04:10, `wip/core-turn` ac851e5c): Core's own note of 04:11 says it is not
  mergeable until its coder has merged the head in (one conflict in `mirror_auto.go`): not taken until
  its entry says READY on a37ed4c or later.**
  **Merged by this session so far (17): K7, entry 20, C7, M7, K8, M8, G2c, K9a, K11, G6, C10, C11, K12,
  M9, G3, G5, entry 21. Nothing is listed and mergeable; no run of mine; the main tree clean.**
- 04:48: the watch woke me at 04:46: **M11 is LISTED READY (mirror, 04:45): `wip/mirror-endread-main`
  831372e3, holding a37ed4c** (the mirror's half of K11: when a want ends, or the owner marks a chat
  never or stops its mirror, the mirror's read of that chat ends; no schema step; an atomic count, no
  new goroutine or lock). Read by me: the entry's head and the catalogue's part of the difference
  (`SetMirrorNever` and `MirrorAllow` take a function that runs in the mark's own transaction; a
  failure writes nothing): it only makes the reader send fewer, and an owner's approval is never
  touched. One independent review and a fix round; the race detector over the doors' tests by name on
  its tree, 1,194 s, no race. **Its merge runs by the script since 04:47** (`runs-int-m11/`: the merged
  tree is the branch's; whole `mirror` and `collector`, the catalogue's mirror tests by name, the
  viewer's wall test; install yes; then the owner's folder; about 18 minutes). The roadmap's clause is
  in the main tree for its commit. If this session stops: the output ends "done <commit>" with the
  folder's line, or "STOPPED at <step>".
  From the notes meanwhile: K9b waits for its head merge (Core); the mirror page (G4) had one must-fix
  in its second review and its whole server run failed on a rule of the demo (pages is on it).
- 05:06: **M11 IS MERGED AND PUSHED BY THE SCRIPT: main head 6365a08, equal to `private`, clean; the
  collector installed from it and the owner's folder rebuilt (05:06)** (04:46 to 05:06; the CPU measured
  first: 25 to 34%; three trees equal to the branch's; whole mirror 174.3 s, collector 912.0 s, the
  catalogue's mirror tests 18.4 s, the viewer's wall test; build, vet, gofmt, the commands; the review
  copied; 5174cc2's build kept). The whole collector's time on Windows grows with the night's pieces
  and the PC's load: 644 s at 23:10, 912 s now.
  **Merged by this session so far (18): K7, entry 20, C7, M7, K8, M8, G2c, K9a, K11, G6, C10, C11, K12,
  M9, G3, G5, entry 21, M11. Nothing is listed and mergeable (K9b and pages' G4 are with their tracks);
  no run of mine; the main tree clean.**
- 05:23: the watch woke me at 05:20: **K9b's entry names its head to merge: `wip/core-turn` 77cf3d7f**
  (the click's turn in the collector; it holds 5174cc2; the head has moved to 6365a08 since: `git
  merge-tree` of the two is clean, no conflict). Read by me: the entry's last block; `oneClick` in
  `click.go` (a click of an earlier session is never sent; the owner's cap and the read-mark switch are
  read at each click and an unreadable value stops the clicks; the request goes through the Actor,
  whose ledger mark comes first; the one second try is only after "the server's limits are not known
  yet", before any mark; every other path records why it was not sent; log lines carry the account's
  number, the kind's word and fixed words); and that `schema_act.go`'s difference adds two reason words
  and a read door and does not change the merged schema's text (0 CREATE or ALTER lines in it). Three
  independent review looks; the race detector on the whole collector on its branch (no data race), and
  on its final head on the click and automatic-mirror tests by name. Nothing can queue a click yet (no
  local door, no compose box).
  **Its merge runs by the script since 05:22** (`runs-int-k9b/`: `git diff 5174cc2f 77cf3d7f` on
  6365a08, three-way; whole `telegram`, `catalog` and `collector` on the combined tree; the viewer's
  wall and schema tests; install yes; then the owner's folder; about 25 minutes). The roadmap's row is
  in the main tree for its commit. If this session stops: the output ends "done <commit>" with the
  folder's line, or "STOPPED at <step>" (then `git -C repo-archiver reset --hard HEAD`, `git -C
  repo-archiver clean -fd archiver`, and Core merges the head in once more).
- 05:50: **K9b, THE CLICK'S TURN, IS MERGED AND PUSHED BY THE SCRIPT: main head d1ebd1a, equal to
  `private`, clean; the collector installed from it and the owner's folder rebuilt (05:48)** (05:21 to
  05:48; the CPU measured first: 10 to 19%; a three-way apply, no conflict, 23 files; whole telegram
  44.2 s, catalog 467.5 s, collector 994.8 s, "exit 0"; the viewer's wall and schema tests; build, vet,
  gofmt, the commands; the review copied; 6365a08's build kept).
  **USAGE at 05:48: 56% of this model's week, 58% of all models** (04:16: 52 and 54): under 3% an hour
  over the last 90 minutes. **My context: 80%** (797,000 tokens).
  **G4, THE MIRROR PAGE, is LISTED (pages, 05:44): `wip/pages-g4` 9b4e265a, holding a37ed4c.** Not
  applied: `git merge-tree` of the main head d1ebd1a and it leaves one conflict,
  `internal/collector/pages_mirror_test.go` (M11 changed it too; M11 also changed `mirror_door.go`,
  where the page's 69 lent lines sit). **Handed back for one more merge of the head** (entry "G4" says
  so first; one message to the pages session, delivered). **I hold every other merge until G4 is
  listed again**, so that the head does not move under it a third time: it is the piece the owner
  asked for at 23:19 ("a functioning mirror option"). Read by me so far: its entry (the page adds no
  request; a wish is one row through the mirror's door; one wish was carried out on the fake Telegram
  by the page's own path with exact request counts; two review passes, the last round without a pass;
  the lent method `MirrorWantRead` writes the mirror's approval onto the owner's estimate record only
  when the request count is the one the page showed, and fails closed).
  **Merged by this session so far (19): K7, entry 20, C7, M7, K8, M8, G2c, K9a, K11, G6, C10, C11, K12,
  M9, G3, G5, entry 21, M11, K9b. Handed back, waiting for a new head: G4. No run of mine; the main
  tree clean.**
- 06:06: the pages session had put G4 on hold itself at 05:48 with more than my check showed (the lent
  lines no longer compile on M11 and must now clear a mirror's ended read; as listed it would also have
  removed four of G1's tests): its coder handed back a1c5d5c8 holding d1ebd1a at 05:58 and the listing
  runs are going. **K9c is LISTED (Core, 06:04): `wip/core-settle` d6415255** (a not-known click settled
  from the chat; it sends nothing; it holds K9b's head 77cf3d7f). **HELD behind G4, as I told the
  tracks at 05:50: not applied, not read yet.** When G4 is listed again: G4 first (the owner's mirror
  option), then K9c on that head.
- 06:21: **G4, THE MIRROR PAGE, IS READY AGAIN (pages, 06:11): `wip/pages-g4` a1c5d5c8, holding d1ebd1a**
  (two merges of the head; G1's four tests restored: the first listing would have removed them, found
  by its coder at the merge, seen by neither review pass; the lent lines brought up to M11's rule).
  Read by me: the entry's head and the whole of the lent lines in `mirror_door.go` (`MirrorWantRead`
  and `wantApprove`): the approval of the read is written in the want's own transaction, only when the
  record's request count is the one the page showed, marked as the mirror's (the chat is not chosen for
  downloads); an approval on record is left but for the mirror's end of the read; a record that cannot
  be read writes nothing. **One point for the owner's page (item 30), not a blocker: with no estimate
  on record and no count shown, the want approves the read as the automatic mirror does; the page's
  own path asks the size first (the test on the fake counts 1 estimate request before the yes).**
  **Its merge runs by the script since 06:20** (`runs-int-g4/`: the merged tree is the branch's; whole
  `server`, `collector/livepages`, `mirror` and `collector` once more on it, the whole collector because
  the piece puts a want from a page onto the mirror's real path; the viewer's wall test; install yes;
  then the owner's folder; about 24 minutes). The roadmap's row and the second review are in the main
  tree for its commit.
  **Listed behind it: K9c (Core, 06:04, `wip/core-settle` d6415255) and G7 (pages, 06:19,
  `wip/pages-launcher2` 77b7fdf9, the launcher's follow-up, holding d1ebd1a).** After G4's "done": G7
  (it holds the same head; pages' own), then K9c.
- 06:41: **THE OWNER IS BACK (06:35): "Good morning ... How are we doing and what should I start? Time
  for a new integrator?"** Told: 19 merged, G4 in its last run, nothing run for real, usage 58% and 59%
  (06:35) with 5 days 8 hours to the reset, my context 83%; a new integrator now; pages, Core and the
  viewer asked for take-overs. **THE OWNER (06:39): "I'll do it. Give me the exact lines to copy
  please. More than 75% is fine. I have a fable reset that also gets back the overall usage it spent.
  So long as we're efficient with the clerks, etc."** So: no cap of mine for today; the rule on clerks
  and scripts is what the owner holds us to; the owner starts the sessions by pasting.

## STATE FOR A TAKE-OVER (the integrator session of 11-15 22:55; written 11-16 06:41)
A new integrator is started by the owner with "Read `START-INTEGRATOR.md` and do what it says". **Until it
writes on the integrator's board row, this session merges; once it has, this session merges nothing.**
- **`repo-archiver`: main head d1ebd1a, equal to `private`. G4 (`wip/pages-g4` a1c5d5c8, the mirror page)
  IS STAGED AND IN ITS MERGE RUN by `ix-tools/merge-as-tested.sh`, a background command of THIS session,
  since 06:20** (`runs-int-g4/`: server, livepages and mirror passed; the whole collector is going, about
  17 minutes; then the commit, the push, the collector's install and the owner's folder). **I finish it
  and write its lines; do not touch the main tree while `git -C repo-archiver status` shows staged files.**
  If this session is gone: its output ends "MERGE-AS-TESTED: done <commit>" (then only the notes are
  owed: the board's row and merged line, the queue's entry and state line, this file, the morning file)
  or "STOPPED at <step>" (then `git -C repo-archiver reset --hard HEAD` and `git -C repo-archiver clean
  -fd archiver`, and read what failed in `runs-int-g4/`).
- **Schema step 23; next free 24.** Installed: the collector is the build of d1ebd1a (G4's follows),
  the watchdog of 8aed433. **The owner's folder `C:\Users\trabi\tgarchive-app` is rebuilt by the
  integrator after every merge that changes a program** (`bash
  repo-archiver/archiver/deploy/folder/make-folder.sh /c/Users/trabi/tgarchive-app` with the
  toolchain's environment; it refuses while a program of the folder runs; its `programs` keeps every
  earlier set, 115 MB each: the owner may delete the older ones). It has never been opened.
- **Merged by this session (19, in order):** K7, the viewer's entry 20, C7, M7, K8, M8, G2c, K9a (schema
  21), K11, G6 (the launcher and the folder), C10 (the frame check end to end, schema 22), C11, K12, M9
  (schema 23), G3 (the sign-in page), G5 (the Staging page), the viewer's entry 21, M11, K9b. Each with
  its review in `docs/review`, its roadmap row, and its entry in `MERGE-QUEUE.md` marked MERGED.
- **LISTED, NOT MERGED, in this order after G4:** G7 `wip/pages-launcher2` 77b7fdf9 (the launcher's
  follow-up; it holds d1ebd1a); K9c `wip/core-settle` d6415255 (a not-known click settled from the
  chat; it holds K9b's head 77cf3d7f: its own difference is `git diff 77cf3d7f d6415255`); K13
  `wip/core-names` e911ad58 (the names of users and chats for a new account). None is read by me. Each
  will need the head merged in or a three-way apply once G4 is in: the script stops on a conflict, and
  a conflict goes back to its track.
- **HOW I MERGE (new since the start file's last block, and in it):** read the entry and the risky part;
  edit the roadmap's row in the main tree; write the commit message to a file; start
  `ix-tools/merge-as-tested.sh` as ONE background command (its head has the ten arguments; `FFMPEG_PATH`
  set to the second entry of `where.exe ffmpeg` when a package starts ffmpeg); read its last line; then
  the folder; then the notes in one message of edits. A schema step: every package that opens a
  catalogue runs whole (catalog, collector, server, supply, bringin, mirror, tgstore, probejudge,
  partsledger; the viewer's `TestWall|TestSchema`). Measure the CPU first; above 80%, wait.
- **THE TRACKS (06:35):** pages (P3), Core (K-3) and the viewer (B5) have written READY FOR A TAKE-OVER on
  their rows: the owner starts their successors this morning. The mirror (M4) asked at 02:59, was told
  to carry on (no session could be started at night) and is working; copies (C3) is working. The
  integrator of 19:47 merges nothing and was asked to detach its sessions.
- **A session cannot be started from a turn the owner did not begin while the owner is on Remote
  Control** (refused at 03:02): take-overs need the owner at the desktop app.
- **USAGE: 58% of this model's week, 59% of all models at 06:35; reset in 5 days 8 hours.** The owner
  (06:39): more than 75% is fine, a reset is at hand, "so long as we're efficient with the clerks".
  Message 73 (d) stands as a signal: at 85% say so to the owner and on the board.
- **FOR THE OWNER, nothing run for real yet:** `MORNING-2026-11-16.md` (section 0b: sessions to start;
  section 3: the folder's first double-click, the first sign-in from the page, the first mirror click,
  the automatic mirror's first run (item 26), the day-long run (item 29), the two drafts (item 19)).
  One point to raise when the owner reads the mirror page's note (item 30): a request for a chat whose
  size was never asked approves its read as the automatic mirror does.
- **OWED BY THE INTEGRATOR:** tonight's board messages 65 to 99 moved to `BOARD-LOG.md` once every track
  has a fresh session (`ix-tools/trim-board.py`); the tracks' rows cut to their current state (asked
  at 03:05; Core has done it); the finished copies (`wt-*` of merged branches) removed with the
  owner's yes; `TELEGRAM-FACTS.md` gets numbers after the owner's first real runs.
- **NEXT STEP, in one line:** G4's result and its notes (this session); then, by whichever integrator
  holds the row: G7, K9c, K13, each as tested.

## After the take-over block (the same session, still holding the row)
- 06:44: **G4, THE MIRROR PAGE, IS MERGED AND PUSHED BY THE SCRIPT: main head 788ebf7, equal to
  `private`, clean; the collector installed from it and the owner's folder rebuilt (06:43).** (06:20 to
  06:43; both trees equal to the branch's; whole server 140.8 s, livepages 0.7 s, mirror 163.8 s,
  collector 1,041.9 s, "exit 0"; the viewer's wall test; build, vet, gofmt, the commands; both reviews in
  `docs/review`; the roadmap's row; d1ebd1a's build kept; the folder's `VERSION.txt` says 788ebf7.)
  **The main tree is clean: nothing of mine is staged or running.** The hold on other merges is lifted
  (the board's row). **Merged by this session: 20** (the 19 of the block above and G4).
  No new integrator has written on the board's row yet (06:43). I wait 15 minutes for it by a file
  watch; if none has written by then, I take G7.
- 06:57 (the session of 22:55, its last entry): **HANDED OVER. A new integrator session wrote on the
  board's row at 06:55; from now this session merges, stages, installs and edits nothing shared.**
  Left as the take-over block says: main head 788ebf7, equal to `private`, clean, nothing staged; no
  background command, agent or container of mine (the last watch ended at 06:56); G7, K9c and K13
  listed and not taken by me. This session started no other session, so nothing wakes it but the
  owner.

## The integrator session of 11-16 06:55 (started by the owner with START-INTEGRATOR.md)
- 06:58: started 06:55. Read the start file and the last take-over block. Main head 788ebf7, equal to `private`, clean, nothing staged (checked on disk). **Wrote on the board row at 06:58: this session holds the row; the integrator of 22:55 merges nothing more.** Nothing of mine runs. Next: the board in full, the review of every track against the disk, then G7, K9c, K13.
- 07:02: **THE REVIEW OF EVERY TRACK AGAINST THE DISK (06:56 to 07:00; the row's "06:58" was two minutes ahead of the clock: the row was written 06:56).** Main head 788ebf7 equal to `private`, clean, nothing staged. 48 copies: every one clean and equal to its branch on `private` (one script call: a single command). Usage 59% of this model's week, 60% of all models, reset in 5 days 8 hours; this session's context 12% at 06:57. The integrator of 22:55 handed over (notes commit 17cdc54), nothing of its staged or running. **Pages:** P4 took over 06:57 (owner-started); G7 listed, READY. **Core:** K-4 took over 06:57; K9c and K13 listed, READY; K14 in hand. **Viewer:** a successor session runs since about 06:56 and has not written on the row yet (the row still says B5, READY FOR A TAKE-OVER 03:41); entry 21 merged; the compose box (`wip/b-compose` f361d35c) pushed, not listed. **Copies:** NO SESSION (C3's last entry 02:07: C10 and C11 merged; next the collector's lines, not briefed). **Mirror:** NO SESSION (M4's last entry 04:47: M11 merged; next M10, not briefed). Saving as they go: every track's last entry matches the disk. Sonnet clerk: every track's entries say it since about 01:20 (pages by a script). **The owner's folder: `tgarchive.exe` (the launcher) runs from it since 06:56: the owner's first real start (item 31); no collector, watchdog or viewer runs. I touch nothing of it; the folder is not rebuilt while it runs.**
- 07:03: **Read by me: the three listed entries and the risky part of each difference** (G7: the collector's three header lines and the launcher's probe, status and start; K9c: the settle's call in the click step, the check before a repeat, the judgement and both writing statements; K13: the names' writer, its call sites in the reader and the monitor, the store's memory, the catalogue's two statements). Nothing found that holds a merge. For the first real run, to watch: `peer_names.failed` (a monitor update waits up to 2 s for the catalogue's writer per answer while it is held). **The three share no file: ONE COMBINED TREE in a copy of mine (`wt-int-b1`, branch `int/b1`, from 788ebf7; `ix-tools/batch-tree.sh`, new, one background command of this session since 07:02; logs `runs-int-b1/`): whole launcher, tgstore, telegram, catalog, collector on Windows, the viewer's wall test, vet, gofmt, the commands; about 28 minutes; no race run (each track's by-name race runs were on these same files).** The main tree is untouched: nothing staged. Then three `merge-as-tested.sh` calls with no whole runs (G7, K9c, K13; install with the last), the roadmap and handoff as one more commit, the folder when the owner's launcher is closed.
- 07:30: **THE COMBINED TREE PASSED (07:01 to 07:29, `runs-int-b1/`, by the script):** whole launcher 48.1 s, tgstore 16.3 s, telegram 41.4 s, catalog 444.9 s, collector 1,060.9 s, the wall test of the viewer, vet, gofmt, the commands: every line "exit 0"; tree of `archiver/internal` 40731d0f. The integrator of 22:55 answered "nothing more" (07:05). **STARTED 07:30, one background command of this session: `ix-tools/merge-batch.sh` (new): G7, K9c, K13 as three commits through `merge-as-tested.sh`, each pushed, the collector installed with the last; it checks the merged tree against the tested one. THE MAIN TREE IS STAGED OR MOVING UNTIL ITS LAST LINE.** If this session is gone: its output ends "MERGE-BATCH: done <commit>" (then owed: the roadmap rows, the handoff block, the board, the queue entries, the folder) or "STOPPED at <where>" (read `runs-int-<name>.out`; commits already pushed stay; a staged rest: `git -C repo-archiver reset --hard HEAD`).
- 07:33: **G7, K9c AND K13 ARE MERGED AND PUSHED BY THE SCRIPT (07:29:16 to 07:30:47): 4562c4e, a294e8d, a29fe93; the merged tree of `archiver/internal` equals the tested one (40731d0f).** Both reviews copied through the scrub script (0 paths left, 0 control bytes). **INSTALLED 07:30: the collector is the build of a29fe93** (788ebf7's kept). **The owner (07:30): "I think I closed the launcher. If not, please close it yourself with my explicit permission": one launcher still ran from the owner's folder (since 06:56; no settings file: the setup was never saved; no other program): stopped by me 07:31. THE FOLDER REBUILT 07:31 from a29fe93** (6 programs; the earlier set kept; `programs` is about 1.2 GB). **The roadmap (three rows changed; two rows added and given to Core: the copy checks on the NAS with its control interface, an account's number never given twice) and the handoff's block 0c: e4a4a61, pushed: THE MAIN HEAD, clean.** My copy `wt-int-b1` and its branch removed. The board: my row, the merged line, a message to every track (the viewer's question answered: `internal/acttest`), item 31; the queue: the three entries marked MERGED. Routine steps: two scripts of mine (`ix-tools/batch-tree.sh`, `ix-tools/merge-batch.sh`), each one background command; the folder and the documents' commit a single command each. **Nothing of mine is staged or running. NEXT: whatever is listed next (the viewer's compose box as entry 22, pages' G9); the owner's answer on sessions for copies and the mirror; owed still: messages 65 to 99 to `BOARD-LOG.md` once every track has a fresh session.**
- 07:33: usage 65% of this model's week and 65% of all models (59% and 60% at 06:57: about 6 points in 38 minutes with four sessions starting and reading in; the signal to the owner is at 85%); this session's context 38%. `START-INTEGRATOR.md` has the batch scripts in its last block. A background file watch of this session waits for the next listing on the notes branch (it ends on a commit whose subject says listed or READY).
- 07:40: **K15 (`wip/core-store` 412a9f01, listed 07:38) IS STAGED AND IN ITS MERGE RUN by `ix-tools/merge-as-tested.sh`, one background command of this session** (out `runs-int-k15/`). Read by me: the entry, the whole difference of `writer.go` and `copier.go` (the probe claims its period under the lock, looks without it in one goroutine, acts only on an unchanged generation; nothing new on an open's or a write's path). The main head changed nothing in `internal/store`, so the package is the branch's tested tree (whole and race on the branch): no second race run; whole store once more, the collector's staging, away, store and copier tests by name, the wall test; then commit, push, install. The roadmap's Staging row is edited in the main tree and goes in with it. **Do not touch the main tree while it shows staged files.** If this session is gone: "MERGE-AS-TESTED: done <commit>" (then owed: the folder, the board, the queue) or "STOPPED at <step>" (`git -C repo-archiver reset --hard HEAD`, read `runs-int-k15/`).
- 07:42: **THE OWNER (07:40): start fresh sessions for copies and the mirror; and on the app: "Will it eventually be standalone (i.e. not in a browser), plus the setup screen is ugly and there's no folder selection boxes, just paths, which looks worse."** Done: **copies C4 (`archiver-copies-4`) and mirror M5 (`archiver-mirror-5`) started 07:40 with briefs (what to read, what changed since each take-over block, the order, what "done for the first turn" is; the clerk rule in the first lines) and DETACHED from me (they report through the files; their turn notes do not wake me).** The owner's three points are three new rows in the board's "Listed and unbuilt" for pages (the app in its own window with the window's door from the viewer; Windows' folder box on the setup page; the setup page's look) and a message to every track (07:44); two of the three were in the agreed `DESIGN-G6-one-folder.md` and built otherwise. Owed by me once K15's merge run has left the main tree: the roadmap's row for the one program says the same. K15's merge run is still going (the whole store passed its tree check at 07:40).
- 07:43: **K15 IS MERGED AND PUSHED BY THE SCRIPT (07:40:17 to 07:42:58): a8dfefd** (the store's tree equal to the branch's; whole store 100.0 s, the collector's named staging tests 26.8 s, the wall test, build, vet, gofmt, the commands; the review copied, 0 paths left). **INSTALLED 07:42 (a29fe93's kept); THE FOLDER REBUILT 07:43 from a8dfefd** (no program of it ran). **The roadmap's row for the one program has the owner's three points: dbca91d, pushed: THE MAIN HEAD, clean.** The board's row and merged line, the queue's entry: done. **Nothing of mine is staged or running but a file watch for the next listing. Merged by this session: 4 (G7, K9c, K13, K15).** NEXT: the next listing (the viewer's compose box as entry 22; pages' G9; Core's K14).
- 07:45: **THE VIEWER'S ENTRY 22 (`wip/b-compose` 31362d5d, listed 07:43: the compose box behind a nil seam) IS STAGED AND IN ITS MERGE RUN by `ix-tools/merge-as-tested.sh`, one background command of this session** (out `runs-int-e22/`). Read by me: the entry; the lines in `server.go`, `viewer.go`, `api.js`, `chat.js`; where `act.go` asks whether the seam is nil (the flag and the routes): with it nil nothing is mounted or drawn. Not read by me: `act.go` beyond that, `act.js` (the entry says who read what; the security review of the whole path comes before the seam is live). The main head changed nothing in `internal/viewer`; the catalogue moved under it (K9c, K13), so whole viewer once on the main tree (about 6.5 minutes, `FFMPEG_PATH` set), no race run (the package is the branch's raced tree), no install, **no folder rebuild (nothing a person can see or do changes; the next merge that does rebuilds it).** Both reviews go to `docs/review`; the roadmap's acting row is edited in the main tree and goes in with it. **Do not touch the main tree while it shows staged files.**
- 07:53: **THE VIEWER'S ENTRY 22 IS MERGED AND PUSHED BY THE SCRIPT (07:45:19 to 07:52:01): 53ee5bc** (the viewer's tree equal to the branch's; whole viewer 372.4 s; build, vet, gofmt, the commands; both reviews copied, 0 paths left); no install, no folder rebuild. The board's row and merged line and the queue's entry: done. **Merged by this session: 5.** Seen at 07:52 (my watch was not running during the merge): **G9 (`wip/pages-small` 150a8b33, listed 07:47, holding e4a4a61) read by me** (the entry; `app.go`, the lent line, the adapter, `server/mirrors.go`: sound, small) **and IN ITS MERGE RUN since this entry, one background command of this session (`runs-int-g9/`): whole server and livepages, the collector's `TestPagesMirror|TestE2EPages`, the commands; then commit, push, install, and the folder in the same command if no program of it runs.** The roadmap's mirror-page row is edited in the main tree and goes in with it. **Do not touch the main tree while it shows staged files.** Since 07:41 to 07:50 on the board: copies C4 took over (E18, the collector's lines, with a coder); pages briefed G10 (Windows' folder box and the look of the launcher's pages) and has it with a coder; Core's K14 is with its reviewer; the viewer briefed the what-changed feed.
- 07:56: **G9 IS MERGED AND PUSHED BY THE SCRIPT (07:53:12 to 07:56:14): 6af0c09** (both trees equal to the branch's; whole server 143.2 s, livepages, the collector's named tests, build, vet, gofmt, the commands). **INSTALLED 07:56 (a8dfefd's kept); THE FOLDER REBUILT 07:56 from 6af0c09** (no program of it ran). The board's row and merged line, the queue's entry: done. **Merged by this session: 6 (G7, K9c, K13, K15, entry 22, G9). The main head is 6af0c09, clean; nothing of mine is staged or running but the file watch for the next listing.** Coming, by the tracks' rows: G8 (in its second review pass), K14 (with its reviewer; schema step 24), G10 (the folder box and the look), E18 and E19 (copies; E19 takes schema step 25), M10.
- 08:25: **G8 (`wip/pages-door` 1decd1fb, listed 08:24, holding the main head 6af0c09 exactly: the door for the owner's clicks) read by me** (the entry; the server's guard hook and the door's own guard and routes; the lent lines in the collector's `pages.go`: the door file opened before the pages and closed at the stop; sound: no door path reaches the pages' token rule, no handler without the secret) **and IN ITS MERGE RUN, one background command of this session (`runs-int-g8/`): the trees of `internal` and `cmd` compared with the branch's, whole actdoor, the wall test, build, vet, gofmt, the commands; no whole run again (the branch ran them on this very tree); then commit, push, install, the folder.** The roadmap's acting row is edited in the main tree and goes in with it. **Do not touch the main tree while it shows staged files.** **USAGE at 08:25: 72% of this model's week, 73% of all models (65% and 65% at 07:34: about 8 points an hour with six sessions; 85% near 10:00 at this rate); this session's context 48%.**
- 08:26: **G8 IS MERGED AND PUSHED BY THE SCRIPT (08:25:13 to 08:25:51): efac56f** (the trees of `internal` and `cmd` equal to the branch's; whole actdoor, the wall test, build, vet, gofmt, the commands; the review copied; I counted paths of this PC in the six reviews copied today: 0 in each). **INSTALLED 08:25 (6af0c09's kept); THE FOLDER REBUILT 08:26 from efac56f.** The board's row (with the usage and K14 as the second of the two) and merged line, the queue's entry: done. **Merged by this session: 7 (G7, K9c, K13, K15, entry 22, G9, G8). The main head is efac56f, clean; nothing of mine is staged or running but the file watch for the next listing.**
- 09:16: **G10 (`wip/pages-setup` 835e2826, listed 09:15, holding the main head efac56f exactly: Windows' folder box on the setup page and the launcher's pages in the app's look; two of the owner's three words of 07:40) read by me** (the entry; the opener's new case, `launcher.go`, the helper's protocol and how it is started and ended: by a handle, nothing on a command line; sound) **and IN ITS MERGE RUN, one background command of this session (`runs-int-g10/`): the trees compared, whole launcher once, build, vet, gofmt, the commands; commit, push; no install (no collector code); the folder in the same command if no program of it runs.** The roadmap's row is edited in the main tree and goes in with it. For the owner, from the entry: the coder opened the real folder box on this PC four times for about a second each (closed by the box's own cancel), and in two trial runs of the first round (about 08:07 and 08:09) its trial code pressed and released ALT into the window in front; that code is removed and no built code sends input.
- 09:18: **G10 IS MERGED AND PUSHED BY THE SCRIPT (09:16:30 to 09:18:04): f7d6ca6** (the trees equal to the branch's; whole launcher 55.6 s; build, vet, gofmt, the commands; the review copied: 3 paths replaced, 0 left). No install. **THE FOLDER REBUILT 09:18 from f7d6ca6** (no program of it ran). The board's row, merged line and item 35 (READY), the queue's entry: done. **Merged by this session: 8 (G7, K9c, K13, K15, entry 22, G9, G8, G10). The main head is f7d6ca6, clean; the installed collector is efac56f's (the same collector code); nothing of mine is staged or running but the file watch for the next listing.** Coming: K14 (its full runs with a clerk), G11 (the app in its own window), E18, E19, M10 (each in a fix round), the viewer's feed and its pass-through's wiring.
- 10:17: **USAGE AT THE SIGNAL: 88% of all models' week, 83% of this model's (10:17; 73% and 72% at 08:25): said on the board (a message to every session, 10:19: finish to the next listing or hand-back, write the take-over block, start nothing new; I go on merging by script) and to the owner (asked about the reset).** This session's context 51%. G13 (`wip/pages-staging2` 2741af3a, listed 10:16, holding the main head f7d6ca6 exactly: the Staging page on the store's reads of the moment) is next: being read.
- 10:19: **G13 IS MERGED AND PUSHED BY THE SCRIPT (10:17:24 to 10:18:27): b8dd4ab** (read by me first: the entry, the lent two lines in `pagesstaging.go`, the adapter's written speed: display only, the store's memory read after the collector's lock is let go; the trees equal to the branch's; livepages whole, the named staging tests, the wall test, build, vet, gofmt, the commands; the review copied, 0 paths). **INSTALLED 10:18 (efac56f's kept); THE FOLDER REBUILT 10:18 from b8dd4ab.** The board's row (it leads with the usage signal) and merged line, the queue's entry: done. **Merged by this session: 9 (G7, K9c, K13, K15, entry 22, G9, G8, G10, G13). The main head is b8dd4ab, clean; nothing of mine is staged or running but the file watch for the next listing.** The usage hold stands until the owner answers on the reset. (My board message of the signal says 10:19 and was written at 10:17 by the clock.)
- 10:23: **THE VIEWER'S ENTRY 23 (`wip/b-changes` 209615f0, listed 10:21: the "Changes" page) IS MERGED AND PUSHED BY THE SCRIPT (10:22:16 to 10:22:59): 1d9cd6e** (read by me first: the entry and the index writer's difference in `refresh.go`, `index.go`, `viewer.go`: the feed kept beside the version in a box, an edit-only update keeps the version; the viewer's tree equal to the branch's, nothing it imports changed since its base; the named tests 18.0 s, build, vet, gofmt, the commands; both reviews copied, 0 paths). No install. **The folder's rebuild was skipped by my own check at 10:23:00 (three programs named tgarchive-* ran: stand-ins of a track's launcher tests in a temporary folder, gone seven seconds later; none from the owner's folder or the installed bin) and done right after: REBUILT 10:23 from 1d9cd6e.** The board's row and merged line, the queue's entry: done. **Merged by this session: 10. The main head is 1d9cd6e, clean; nothing of mine is staged or running but the file watch.** The usage hold stands; no answer from the owner yet on the reset.
- 10:43: **THE VIEWER'S ENTRY 24 (`wip/b-winpages` f0e49be5, listed 10:41: the window's gate in both modes and its pages mode) IS MERGED AND PUSHED BY THE SCRIPT (10:42:09 to 10:42:48): b6dd5e6** (read by me first: the entry and `gate.go` whole: forwarded only when plain http to an exact allowed 127.0.0.1 port, the dial checks again, nothing of a request logged; both trees equal to the branch's; whole window 5.4 s, the wall test, build, vet, gofmt, the commands; both reviews copied, 0 paths). No install. **THE FOLDER REBUILT 10:42 from b6dd5e6.** **Said to the owner in my message of 10:43:** the review's measurement that the window's browser engine has made requests of its own to its maker's services at every start since 11-15 (the PC's address only, by the review), closed by the gate; a coder's two-minute search over every drive; two engine crashes made on purpose (dumps of invented pages, deleted; not measured whether Windows sent them). The board's row and merged line, the queue's entry: done. **Merged by this session: 11. The main head is b6dd5e6, clean; nothing of mine is staged or running but the file watch.** The usage hold stands; no answer from the owner yet on the reset.
- 10:47: **G11 (`wip/pages-window` 232dd7cd, listed 10:44: the launcher's side of the app in its own window) IS MERGED AND PUSHED BY THE SCRIPT (10:45:17 to 10:47:16): 140fefa** (read by me first: the entry and the kill-on-close job in `proc_windows.go`: the window opened by its number and taken only when its creation time matches, nothing else put in the job; the launcher's tree equal to the branch's; whole launcher 94.3 s, build, vet, gofmt, the commands; the review copied, 3 paths replaced, 0 left). No install. **THE FOLDER REBUILT 10:47 from 140fefa after my own count of programs running from it (0): it now has all three of the owner's points of 07:40** (the window, the folder boxes, the look); item 35 says so. Owed by pages after the hold: the folder script's running check to count the window and the viewer (my row). The board's row, merged line and item 35, the queue's entry: done. **Merged by this session: 12 (G7, K9c, K13, K15, entry 22, G9, G8, G10, G13, entry 23, entry 24, G11). The main head is 140fefa, clean; the installed collector is b8dd4ab's (no collector code since); nothing of mine is staged or running but the file watch.**
- 10:48: usage 91% of all models' week, 86% of this model's (88% and 83% at 10:17: about 6 points an hour under the hold; all models used up near 12:15 at this rate). This session's context 59%. My error at 10:48: the morning file's line with a Windows path went through an inline script in the shell tool (the rule of the start file forbids it); the script failed on the path and wrote nothing; the line is in by the Edit tool now.

## STATE FOR A TAKE-OVER (the integrator session of 11-16 06:55; written 10:48; kept current below)
A new integrator is started by the owner with "Read `START-INTEGRATOR.md` and do what it says".
- **`repo-archiver`: main head 140fefa, equal to `private`, clean; nothing of mine is staged or running** but one background file watch of this session for the next listing on the notes branch (it ends by itself; a new session starts its own).
- **Installed: the collector is the build of b8dd4ab** (no collector code merged since; the builds before it are kept as `.bak`); the watchdog is 8aed433's. **The owner's folder (item 35 names it) is rebuilt from 140fefa (10:47)**: it has the app's own window, the folder boxes and the look: the owner's three points of 07:40; not opened by the owner since. Before each rebuild count the programs running from that folder yourself (the folder script does not count the window or the viewer: owed by pages).
- **Merged by this session (12, in order):** G7, K9c, K13 (one combined tree, 07:30), K15, the viewer's entry 22, G9, G8 (the door for the owner's clicks), G10, G13, the viewer's entries 23 and 24, G11. Each with its review in `docs/review` (no path of this PC in any), its roadmap row, its entry in `MERGE-QUEUE.md` marked MERGED.
- **Schema step 23 on the main head; 24 is taken by Core's K14, 25 by copies' E19; next free 26.**
- **NOTHING IS LISTED AND UNMERGED. Coming, by the tracks' rows:** K14 (Core: the door's guarantees, schema step 24; full runs clean, its round on the main head with the door's three wirings running), E18 with C12 (copies: the collector's lines; in its full runs) and E19 (copies: the owner's words on a held pair, schema step 25; its runs with a clerk), M10 (mirror: "may be listed" by its third look; whole runs and a race run with a clerk), the viewer's pass-through wiring (after K14), Core's K16.
- **THE USAGE HOLD (my board message of 10:19, on my row): every session finishes to its next listing or hand-back, writes its take-over block and starts nothing new, until the owner says the reset is done and the integrator lifts it on the board. Asked of the owner four times since 10:19; no answer yet.**
- **HOW I MERGE (the start file's last block has it):** read the entry and the risky part; say the run plan in one line; edit the roadmap's row in the main tree; write the commit message to a file (`runs-int-b1/msg-*.txt` are this session's); one background run of `ix-tools/merge-as-tested.sh` (or `batch-tree.sh` and `merge-batch.sh` for pieces that share no file); a branch that holds the main head, or whose packages and their imports did not change on the main head since its base, needs no whole run again: compare the trees and run the cheap checks. Then the folder, then the notes in one message of edits.
- **Sessions:** pages P4, Core K-4, the viewer B6 (owner-started 06:57); copies C4 and the mirror M5 (started by me at 07:40 at the owner's word, detached). All report through the files.
- **FOR THE OWNER, nothing run for real yet:** item 35 (open the folder: the window, the folder boxes, the look), then items 31 to 33 (the first start with a saved setup, the first sign-in from the page, the first mirror click), 26, 29, 19, 20, 34.
- **Said to the owner today, on record:** the window's browser engine made requests of its own to its maker's services at every start since 11-15 (closed by the gate in the folder's build and in the viewer track's builds); a coder's two-minute search over every drive; two engine crashes made on purpose; a coder's trial code pressed ALT into the window in front twice.
- **OWED BY THE INTEGRATOR:** the board's messages 65 to 99 moved to `BOARD-LOG.md` (`ix-tools/trim-board.py`; every track has a fresh session now) and the tracks told to cut their rows; the finished copies (`wt-*` of merged branches, 50 and more) removed with the owner's yes; `TELEGRAM-FACTS.md` after the owner's first real runs.
- **NEXT STEP, in one line:** merge whatever is listed next; lift the hold when the owner says the reset is done.
- 11:05: **C12 (`wip/copies-18` 86a7f2f8, listed 11:03, holding b6dd5e6: the collector's lines for the fingerprint worker and the frame check, each off unless its flag is set; download-path code) IS STAGED AND IN ITS MERGE RUN, one background command of this session (`runs-int-c12/`).** Read by me first: TRIED-BEFORE 6, 17, 21 and 27 (the lessons the board names for the copies step: only exact evidence skips; a copy is held, never skipped; the fingerprint from the staged copy, the library never read; an unknown never downloads unchecked outside stated bounds; a claim or finish that fails never stops other downloads); the entry; the whole difference of the four lent files (`collector.go`, `staging.go`, `account.go`, `command.go`): with both flags off the start gains one look at the staging folder and the closing of open checks, as the entry says. Not read by me: `framecheck.go` (856 lines) beyond its calls; two independent reviews traced it. The main head changed only the launcher since the branch's base. **Runs: whole collector once (about 19 minutes: its branch's whole run was before the last merge of the head), the wall test, build, vet, gofmt, the commands; no race run again (by name on this tree by the track: clean); then commit, push, install, the folder.** The roadmap's two rows are edited in the main tree and go in with it. **Do not touch the main tree while it shows staged files.**
- 11:25: **C12 IS MERGED AND PUSHED BY THE SCRIPT (11:05:17 to 11:25:13): 2a6073b** (the four packages' trees equal to the branch's; whole collector 1,156.3 s; the wall test, build, vet, gofmt, the commands; both reviews copied, 0 paths). **INSTALLED 11:25 (b8dd4ab's kept); THE FOLDER REBUILT 11:25 from 2a6073b** (0 programs ran from it). The board's row and merged line, the queue's entry: done. **Merged by this session: 13. The main head is 2a6073b, clean; nothing of mine is staged or running but the file watch.** In the take-over block above, read 2a6073b for the main head and the installed collector. The usage hold stands; no answer from the owner on the reset since 10:19.
- 11:25: usage 92% of all models' week, 88% of this model's (91% and 86% at 10:49: about 1.5 and 3 points an hour: the hold has slowed it); this session's context 63%.
- 11:31: **THE OWNER: "I haven't used the reset yet": THE HOLD STANDS** (every session finishes what is in flight to its listing or hand-back and starts nothing new; I merge what is listed). Lifted only at the owner's word that the reset is done.
- 12:00: **C13 (`wip/copies-19` ede30531, listed 11:59, holding the main head 2a6073b exactly: the owner's words on a probable pair, the lost look-alike; a schema step; code that decides held or wanted) IS STAGED AND IN ITS MERGE RUN, one background command of this session (`runs-int-c13/`).** Read by me first: the entry; the schema's constants (the step is "after the mirror's 23": 24 on this tree with no edit); every writing statement of `pairword.go` (a file's state is only ever set to held or wanted, each by a compare-and-set on the state read; none sets skipped or gone); `pairJudge` and `pairRejudge` whole (the ladder's own rule first; a file on another archive's saved list is left as it is; the same byte size as a saved file goes to the exact check first). Not read by me: the reader `internal/pairwords` (nothing starts it), the ladder's and the exact check's seeks line by line (two independent reviews and a closing check did). **IT MERGES AS SCHEMA STEP 24 (listed first); Core's K14 becomes 25: said on my row.** Runs: whole tgstore, bringin, mirror, server, collector once on this tree (about 27 minutes: the packages that open a catalogue and had not run whole with the step), the viewer's wall and schema tests, the catalogue's schema tests, build, vet, gofmt, the commands; then commit, push, install, the folder. The roadmap's row and the handoff's schema lines are edited in the main tree and go in with it. **Do not touch the main tree while it shows staged files.**
- 12:30: **C13 IS MERGED AND PUSHED BY THE SCRIPT (12:03 to 12:28): bae71e5, SCHEMA STEP 24** (the trees equal to the branch's; whole tgstore, bringin, mirror, server 158.7 s, collector 1,131.1 s; the schema tests; build, vet, gofmt, the commands; both reviews copied). **INSTALLED 12:28 (2a6073b's kept); THE FOLDER REBUILT 12:28 from bae71e5.** Merged by this session: 14. **THE OWNER (12:25): "We can get a bit more usage out before the reset is used. What's outstanding?" and that the pages session asks for a successor; then: "Also takeovers on SESSION-MIRROR-PROGRESS.md and SESSION-COPIES-PROGRESS.md perhaps, depending".** Usage 93% of all models' week, 90% of this model's (12:27). **Done: the hold loosened narrowly on my row** (pieces within one round of a listing; the chain that makes a click usable: K14, then the viewer's wiring; my merges; all else held; everything stops again at 97% of all models). **THE BOARD SHORTENED 12:28 by a new script `ix-tools/trim-board-2.py`: messages 65 to 99 and my row's older states moved to `BOARD-LOG.md` unchanged (414 KB to 278 KB; 0 control bytes).** My recommendation to the owner on the three take-overs (pages, copies, mirror; each track's session is full and none has anything in flight): not before the reset or the owner's first look at the folder; each read-in costs about a point; started at the owner's word.
- 12:30: **M10 (`wip/mirror-autonew` 7d31fa56, listed 12:03, on 2a6073b) read by me** (the entry; the mirror's lines in `account.go`, `collector.go`, `words.go`; `mirror/autonew.go`: the switch parses fail closed; "on" means from now on) **and IN ITS MERGE RUN, one background command of this session (`runs-int-m10/`):** three-way on bae71e5 (no file in common with C13); whole mirror and whole collector once (the track ran the collector's mirror set only; the catalogue moved under it), the catalogue's mirror, protected and schema tests by name, the wall test, build, vet, gofmt, the commands; then commit, push, install, the folder. Its review is on the branch (0 paths). The roadmap's row is edited in the main tree and goes in with it. **Do not touch the main tree while it shows staged files.**
- 12:36: **THE OWNER: "How far are we from having a usable app that I can actually launch? With a proper GUI and features? Please launch the copies task."** Done: **copies session C5 (`archiver-copies-5`) started with a brief** (take over from C4's block; ONE small piece: the collector's line that starts the reader of the owner's verdicts; read only what the brief names; cut the row first; stop at the integrator's word) **and detached.** Pages and the mirror: no successor started (not asked). **The owner's folder's `tools` now holds ffmpeg (9.0.2, 217 MB), mpv (0.42.0, 116 MB) and mpv's d3dcompiler library, copied by me from this PC's own installs as the folder's README asks (no program of the folder ran; both answer their version line):** so the first real start has thumbnails, the checks' frames and the window's player without a step of the owner's. An update of the folder never touches `tools`. Answered to the owner: what a launch does today, what has never run for real, and what is missing.
- 12:42: **THE OWNER: "Start the pages and mirrors please." Done: pages session P5 (`archiver-pages-5`: first G12, the control for the mirror's switch and the chat list's interval on the pages, when my row names the head with M10; then the folder script's running check; the owner's words on the folder first when they come) and the mirror's session M-6 (`archiver-mirror-6`: item 26 brought up to M10's build once it is installed; then M6, adopting a chat) started with briefs and detached.** P4 and M5 are retired. Every track has a running session now: pages P5, Core K-4, the viewer B6, copies C5, the mirror M-6. M10's merge run is still going (whole mirror passed 12:33; the whole collector runs).
- 12:58: **M10 IS MERGED AND PUSHED BY THE SCRIPT (12:30 to 12:58): 2b55760** (three-way on bae71e5, no conflict; whole mirror 172.2 s, whole collector, the named catalogue tests 31.7 s, the wall test, build, vet, gofmt, the commands). **INSTALLED 12:58 (bae71e5's kept); THE FOLDER REBUILT 12:58 from 2b55760** (its `tools` untouched: ffmpeg and mpv are there). The board's row (the head named for P5 and M-6, who wait for it by file watches), the merged line, the queue's entry: done. **Merged by this session: 15. The main head is 2b55760, clean; nothing of mine is staged or running.** Since 12:45 on the board: P5 took over (its row cut from 31 KB to 4 KB; G12 briefed); M-6 took over (M6's brief written; schema step 26 claimed); C5's piece C14 (`wip/copies-20`) is handed back and in its review.
- 12:59: usage 95% of all models' week, 93% of this model's (93% and 90% at 12:27: two points in half an hour with three sessions reading in; the stop at 97% is about half an hour away at this rate); this session's context 71%. The whole collector took 1,450 s in M10's run (1,131 s an hour earlier: the PC is busy).
- 13:06: **K14 (`wip/core-door-main` 772d8291: the door's guarantees, a schema step) and K16 (`wip/core-batch` baa84077: `Batch` rolls back on a panic) listed 13:02; both read by me (the entries; K16's whole change; K14's key table and its one-transaction write, the account delete's line). JOINED BY HAND IN A COPY OF MINE, `wt-int-b2` (branch `int/b2`, cut from the main head 2b55760; nothing pushed; THE MAIN TREE IS UNTOUCHED AND CLEAN):** K16's difference applied clean and committed there (its final message is `runs-int-b1/msg-k16.txt`: amend it in before it leaves the copy); K14's difference (`git diff 140fefaa 772d8291`) applied three-way: four conflicts, each "keep both" (`catalog.go`: `SchemaVersion = actKeySchema`, both entries of the steps' map, both cases of `migrate`; `collector.go`: both blocks of test fields), resolved by me; **K14's step chained after the copies' step: `actKeyAfter = pairWordSchema` (SCHEMA STEP 25), its test's comparison too; one comparison of the copies' `TestPairWordSchemaStep` changed from "is the newest" to "is not older than the head's"** (as the mirror did for the probe's step); build ok, gofmt clean, the schema tests and K16's panic tests ok; the tree of `archiver/internal` there is e0447b90, staged, K14 not committed yet. **IN ITS RUN since 13:06, one background command of this session (`runs-int-b2/`): every package that opens a catalogue whole on that tree (about 50 minutes on a busy PC), the viewer's wall and schema tests, vet, the commands.** Then, if every line is "exit 0": K14's commit in the copy (message `runs-int-b1/msg-k14.txt`, its review through the scrub script as `docs/review/core-k14-door-2026-11-16.md`, the roadmap's row and the handoff's schema lines), K16's message amended, the main branch fast-forwarded to the copy's head, pushed, the collector installed, the folder rebuilt, the copy removed. **If this session is gone: the copy holds everything; nothing of it is on the main branch.** Usage 96% of all models' week at 13:03.
- 13:28: **THE OWNER: "I will reset usage shortly. Don't send a stop command." So no stop is sent at 97%, and the hold of 10:19 is lifted in full on my row: every session carries on in its order.** The reset itself has not happened yet (usage 96% of all models at 13:03): take-over blocks stay current.
- 13:47: **THE OWNER: "Usage reset. Go as needed." Measured: 0% of this model's week, 50% of all models; reset in 5 days 1 hour. Every hold is off (my row).** This session's context is at 74%: a successor integrator is the owner's to start when it nears 90% (the take-over block above, with the entries after it, is the state). **K14 and K16's combined run in `wt-int-b2`: every package passed (catalog 521.7 s, server 159.8 s, mirror 178.0 s, supply 156.2 s, telegram 43.2 s, tgstore, bringin, probejudge, pairwords, partsledger, livepages, actdoor) BUT THE WHOLE COLLECTOR, which was cut off by go's own 20-minute limit of `ix-tools/full-runs.sh`** ("test timed out after 20m0s"; the one test running then had run 2 s: nothing hung, no test failed; the package took 1,303 s in Core's own run and 1,450 s in M10's merge). **Read to its cause, not a failure of the piece. The script's limit is 45 minutes now, and the whole collector runs again on the joined tree with 45 minutes, one background command of this session (`runs-int-b2/win-collector-2.log`).** Said on my row for every session that runs the whole collector.
- 14:00: **THE OWNER, on a successor integrator: "You start it for me when appropriate please."** Started now, in a turn the owner began (a start from a turn of a background event can be refused), while I finish K14 and K16; the block below is its state.

## STATE FOR A TAKE-OVER (the integrator session of 11-16 06:55; written 14:00; this block replaces the one of 10:49)
A new integrator was started by me at the owner's word at about 14:00. **Until it writes on the integrator's board row, this session merges; once it has, this session merges nothing more.**
- **`repo-archiver`: main head 2b55760, equal to `private`, clean, nothing staged.** The catalogue is at schema step 24 on it.
- **IN FLIGHT, MINE, AND I FINISH IT: K14 and K16, joined by hand in my copy `wt-int-b2` (branch `int/b2`, cut from 2b55760; nothing of it pushed).** There: K16's difference committed (its final message is `runs-int-b1/msg-k16.txt`, to be amended in); K14's difference staged with its four "keep both" conflicts resolved, its step chained as SCHEMA STEP 25 (`actKeyAfter = pairWordSchema`), one comparison of the copies' `TestPairWordSchemaStep` relaxed; tree of `archiver/internal` e0447b90. Its whole runs (`runs-int-b2/`): every package that opens a catalogue passed; the whole collector was cut off by a 20-minute limit and runs again with 45 minutes as a background command of THIS session (`runs-int-b2/win-collector-2.log`, its last line "exit N"). **If it says "exit 0" and this session is gone, the steps left are:** in the copy, copy K14's review through the scrub script (`python ix-tools/scrub-copy.py REVIEW-K14-door.md wt-int-b2/archiver/docs/review/core-k14-door-2026-11-16.md`), edit the roadmap's acting row and the handoff's schema lines (step 25: `c_act_key`; no step open; next free 26 is claimed by the mirror's M6, so 27), commit K14 with `runs-int-b1/msg-k14.txt`, amend K16's message; `git -C repo-archiver merge --ff-only int/b2`; push; build and install the collector (the steps of `merge-as-tested.sh`'s part 6); the folder; remove the copy and its branch. **If it does not say "exit 0": read the failing test to its cause; nothing is on the main branch.**
- **Installed: the collector is the build of 2b55760; the watchdog 8aed433's. The owner's folder is rebuilt from 2b55760 (12:58) and holds ffmpeg and mpv in its `tools` (12:35).** Not opened by the owner since 07:31.
- **Merged by this session (15, in order):** G7, K9c, K13, K15, the viewer's entry 22, G9, G8, G10, G13, the viewer's entries 23 and 24, G11, C12, C13 (schema step 24), M10. Each with its review in `docs/review`, its roadmap row, its queue entry marked MERGED.
- **Schema: 24 on the head; 25 is K14 (in flight); 26 is claimed by the mirror's M6 (adopting a chat); next free 27.**
- **USAGE: reset by the owner at about 13:45 (0% of this model's week, 50% of all models). No hold of any kind stands** (my row).
- **Sessions, all running:** pages P5 (G12: the mirror's switch as a control; in its listing runs at 13:32), Core K-4 (its context was full at 13:02: it wrote a state for a take-over; a successor is the owner's or yours to ask for), the viewer B6 (quiet since 10:46; it starts the pass-through's wiring when K14 is on the head), copies C5 (C14, the line that starts the reader of the owner's verdicts: handed back, in its review), the mirror M-6 (item 26's plan; M6 adopting a chat with a coder; the owner's new word: 20 new mirrors in 24 hours by default, 1 to 50, a setting: pages' message 129).
- **FOR THE OWNER, nothing run for real yet:** item 35 (open the folder: the window, the folder boxes, the look), 31 to 33, 26, 29, 37 (the frame check's first real run), 34, 19, 20. The owner asked at 12:40 how far a launchable app is: answered: it can be launched now; the launcher has never started the real programs; the first start is the test.
- **OWED BY THE INTEGRATOR:** the finished copies removed with the owner's yes (over 60 `wt-*` of merged branches; each track's block lists its own); `TELEGRAM-FACTS.md` after the owner's first real runs; pages owes the folder script's running check (the window, the viewer).
- **HOW I MERGE:** the start file's blocks "Learnt on 11-15 night" and "Learnt on 11-16 by day".
- **NEXT STEP, in one line:** K14 and K16 to the main branch when the collector's run says "exit 0"; then whatever is listed (G12, C14 next).
- 14:01: **A successor integrator is started (`archiver-integrator-4`, with "Read `START-INTEGRATOR.md` and do what it says" and four points of today) and detached. Until it writes on the board row I merge; I finish K14 and K16 and then merge nothing more.** The collector's second run on the joined tree is still going.

## THE INTEGRATOR SESSION OF 11-16 14:00 (`archiver-integrator-4`; entries marked "(I-4)")
- 14:03 (I-4): **started 14:00 by the session of 06:55 at the owner's word; I HOLD THE BOARD'S ROW FROM 14:03** (written there; the session of 06:55 messaged once: it finishes K14 and K16 in `wt-int-b2` and merges nothing after). Read in full so far: `START-INTEGRATOR.md`, `CLAUDE.md`'s archiver section, `BOARD.md` whole (not `BOARD-LOG.md`), the take-over block of 14:00 above with its entries. Usage 14:02: 50% of all models' week, 1% of this model's; this session's context 21%. **Nothing of mine is staged, running or started; I touch neither `wt-int-b2`, the main tree nor the installed programs until an entry above this block's successor line says K14 and K16 are on the main branch or that the session of 06:55 has stopped.** Next: the queue's unmerged entries, the handoff's block, the history files, then every track against the disk, then the report to the owner; then G12 and C14 (C14 after K16).
- 14:06 (I-4): **THE START-OF-SESSION REVIEW, every track against the disk (14:02; one read-only script of mine, `disk-review.sh` in this session's scratch folder: no fetch, no index write; a single command, so no clerk).** Also read: the queue's three unmerged entries (K14, K16, C14) whole; the handoff's block 0c; the ends of the mirror's and pages' progress files; Core's take-over block of 13:02.
  - **The repository:** the main branch 2b557601, equal to `private`, the main tree clean. 60 copies: 52 clean and equal to their pushed branch; 8 not on `private`, each by design (`wt-int-b2` with 27 changed files: the session of 06:55's joined tree; five reviewers' scratch copies of the copies track, 2 or 3 files each; `wt-mirror-review13-tree` and `wt-pages-g1-look`, both clean and detached). Running: one go command and one collector test program (the session of 06:55's whole collector, since 13:47); no container of ours. **The PC: 1.4 GB free of 31.1, CPU 48%; the 40 processes of the Claude app hold 6.9 GB.**
  - **Notes:** every track's progress file is committed (0 uncommitted); last entries: pages 13:34, copies 13:09, Core 13:02, the mirror 12:54, the viewer 10:46.
  - **Pages (P5):** merged up to G11 and G13; G12 (`wip/pages-autonew` edad0fe0, pushed, holds the head) reviewed and fixed, NOT LISTED: its listing script was started 13:32, waited 20 minutes for 2.5 GB, and since 13:52 waits again before its first step (it waits up to 20 minutes before each of nine steps: up to three hours at this memory). The session is idle and wakes when the script ends.
  - **Copies (C5):** C12 and C13 merged; C14 (`wip/copies-20` 783d0478) listed READY, after K16; nothing runs; idle since 13:10 with nothing that wakes it.
  - **The mirror (M-6):** M10 merged and in place; **STALLED SINCE 12:58 BY AN ACCIDENT: its one watch waited for a sentence ("INSTALLED 12:28 ... bae71e5") to leave the integrator's row, and the row kept its older states.** No copy `wt-mirror-adopt` exists; M6's coder never started. Cured 14:07 by cutting the row (below).
  - **Core (K-4):** K14 and K16 listed, in the session of 06:55's joined run; nothing runs; the session's context is full: the track has no session that can build. Owed first by a successor: copies' 113 (b).
  - **The viewer (B6):** entries 22 to 24 merged; the pass-through (`wip/b-door` bb5454ce, pushed, clean) waits for K14 on the head; quiet since 10:46 with nothing in the background: it must be told when K14 is on the head.
  - **The clerk rule:** all five rows say how their routine steps were done (a script or one Sonnet clerk call, or a single command with its reason); none is counted as not doing it.
  - **Waiting for the owner, nothing run for real yet:** items 35, 31 to 33, 26, 29, 37, 19, 20, 38.
- 14:07 (I-4): **THE BOARD: my row cut to its current state and messages 100 to 112 moved to `BOARD-LOG.md`, unchanged, by `ix-tools/trim-board-2.py` (one command; 268 KB to 192 KB; 0 control bytes; the row 3.2 KB, the sentence the mirror's watch looked for is gone).** On the row: the head, the schema numbers, what is in place, no hold, the PC's memory as the limit, a line each for the mirror, pages, the viewer, copies and Core. **A new row in "Listed and unbuilt", owed since message 129: the cap on new mirrors in 24 hours as a stored setting (the owner, 13:28 and 13:34), the mirror's.** Owed still, in the main tree, so not before K14 and K16 are in: the owner's words in `FEATURES.md` section 12 and the roadmap's mirror row. Nothing of mine is staged or running.
- 14:10 (I-4): **the report to the owner is given (the review above in eleven lines; two things asked: a Core successor, and whether the retired sessions may be archived to free memory).** Copies (C5) messaged once: no hold stands. The mirror's session woke by itself after the row's cut (the copy `wt-mirror-adopt` exists since 14:07). **PREPARED WHILE K14 AND K16 FINISH, nothing touched in the main tree:** read by me: `TRIED-BEFORE.md` sections 6, 17, 21, 24, 25 and 27 (the lessons the board names for the copies step and for what acts for the owner); C14's difference in the two lent files, its change to the frame check's folder walk (with the old mode every call is the same as before: `either` is symmetric when "holds" is true) and `pairwordsline.go` whole (off: one store of nil and a return; it decides nothing about held or wanted); C14's commit message is `runs-int-i4/msg-c14.txt`. Read ahead for G12 (not listed yet): the route `POST /api/mirrors/auto-new` (an explicit true or false, no default, one door call, no retry) and the adapter (the switch from `AutoNew`, the flag's refusal among the door's). `ix-tools/merge-as-tested.sh`: its whole-run limit is 45 minutes now (was 30). **THE RUN PLAN, said to the owner: C14 (and G12 with it if it is listed by then: they share no file) on the head with K14 and K16: the whole collector once on Windows (about 25 minutes: the head moved beneath it), whole server and livepages for G12 (about 3 minutes), the viewer's wall test, build, vet, gofmt; no race detector (the piece's own race run by name was clean on its branch and nothing of its concurrent code changes at the merge).** **RUNNING: one background watch of this session (it ends when the main head moves, when the session of 06:55 writes a new entry, or when "G12." stands in the queue; 55 minutes at most).** Next step in one line: when the watch ends, read the session of 06:55's entry; K14 and K16 in: tell the viewer (B6) once, then C14 (three-way on the new head) by `merge-as-tested.sh`, or C14 and G12 as one batch.
- 14:19 (I-4): **the session of 06:55 wrote at 14:16 that K14 and K16 are on the main branch (e9b8c54, schema step 25), in place and in the owner's folder, its copy removed, and that it has stopped merging: checked by me: the main branch equal to `private` at e9b8c540, the main tree clean, `wt-int-b2` gone. EVERYTHING FROM HERE IS MINE.** The viewer (B6) told once by a message (K14 on the head, no hold). **C14 IS STAGED ON THE MAIN TREE AND IN ITS MERGE RUN SINCE 14:18, one background command of this session (`ix-tools/merge-as-tested.sh c14 ...`; its lines in `runs-int-i4/merge-c14.out`, logs in `runs-int-c14/`).** How: C14's own difference (2b557601 to 783d0478) did not apply clean on e9b8c54: ONE conflict, the settings block of `collector.go` (K14's three test fields and C14's block): joined in a copy of mine, `wt-int-c14` (branch `int/c14`, one tentative commit 96fa0140, never pushed), by one script (`runs-int-i4/join-c14.sh`: three-way apply, "keep both" by `keep-both.py`, gofmt, a build of the collector and the commands: ok); the resolved block read by me. The merge script then takes the difference e9b8c540 to 96fa0140, so the staged trees equal the copy's (both said "equal"). Runs: whole pairwords and whole collector on Windows (45-minute limit), the viewer's wall test, build, vet, gofmt, the commands; then the review through the scrub script, the commit with `runs-int-i4/msg-c14.txt`, the push, the collector in place (collector code changed). The roadmap's row is edited in the main tree and goes in with it. **DO NOT TOUCH THE MAIN TREE WHILE IT SHOWS STAGED FILES.** If this session is gone: the last line of `merge-c14.out` says "done <commit>" or "STOPPED at <step>"; after "done": `bash runs-int-i4/folder.sh` (the owner's folder), remove `wt-int-c14` and `int/c14`, mark the queue's entry, the board's row and list. **Memory, measured 14:17: 1.3 GB available of 31; private memory: the Claude app's 41 processes 13.7 GB; Windows' kernel pools 13.7 GB (paged 9.1, nonpaged 4.6); commit 54.6 of 90.5 GB.** The mirror's message 130 read (M12, the cap as a setting, before M6: with a coder).
- 14:50 (I-4): **C14 IS MERGED AND PUSHED BY THE SCRIPT (14:17:55 to 14:47:01): 69a9c43** (both trees equal to the joined copy's; whole pairwords 7.5 s, whole collector 1,686.0 s, the viewer's wall test, build, vet, gofmt, the commands: ok; the review copied, 0 paths replaced, 0 left; the roadmap's row). **THE COLLECTOR IN PLACE since 14:47 (e9b8c54's kept as a `.bak`); THE OWNER'S FOLDER REBUILT 14:47 from 69a9c43 by `runs-int-i4/folder.sh` (0 programs ran from it; its `tools` untouched).** My copy `wt-int-c14` and its branch removed. The queue's entry marked MERGED, the board's row and merged line: done. **A DOCUMENTS COMMIT ON TOP, pushed 14:48: b435266** (no code): `FEATURES.md` section 12, seventeenth round (the owner's words of today, owed since the mirror's message 115 a: the folder's program, the chat list's interval, one list at a switch-on, how far the app is, the cap on new mirrors, the clerk rule); the handoff's block 0c brought up to this afternoon (the launcher's window, folder boxes and look; the door, its guarantees and the compose box; the collector's lines for the copies' three flags; the stored switch and the interval; the Changes page and the window's gate; the writer rolled back on a panic); the roadmap's mirror row has the cap. **Merged by this session: 1 (C14). The main head is b435266, equal to `private`, clean; nothing of mine is staged or running.** Routine steps: three scripts (`join-c14.sh`, `merge-as-tested.sh`, `folder.sh`), no model turn inside them; the documents' edits and the two commit messages are mine. **Seen on the notes branch: the owner, to copies at 14:38 and 14:40: "Not the first run yet, trying to build features"; "Build as needed and close the retired sessions that no longer provide any value": six archived by copies (my second question to the owner is answered by it); 1.8 GB available at 14:49.** **G12's listing script (pages) is stalled on its own memory wait: 20 minutes before each step, two of nine done at 14:49, the end near 17:00; P5 told once by a message (14:50): stop it and list G12; the full runs are mine at the merge, once, on the combined tree** (whole server, whole livepages, the four collector sets by name, the launcher's folder test, build and vet for both systems, gofmt). Next step in one line: one background watch for the next listing (G12, M12, C15, the viewer's wiring); then read its entry and risky part and merge.
- 14:54 (I-4): **G12 (`wip/pages-autonew` edad0fe0, listed 14:51 by pages at my proposal, its full runs left to me; cut from 2b557601) IS STAGED ON THE MAIN TREE AND IN ITS MERGE RUN SINCE 14:52, one background command of this session (`ix-tools/merge-as-tested.sh g12 ...`; its lines in `runs-int-i4/merge-g12.out`, logs in `runs-int-g12/`).** Read by me first: the entry whole; `TRIED-BEFORE.md` sections 24 and 25 (the 13 rules for what acts for the owner); the route `POST /api/mirrors/auto-new` and the interval's route, the adapter and the wrapper; `autoNewView`, where every button is decided (every fact an exact boolean, a contradiction offers nothing, unreadable never shown as on or off, an "off" also for a refused account, no "on" without the cost sentence); the folder script's change. Not read by me: the page scripts' DOM code (no test runs it either; said in the commit and the roadmap), the demo data, the tests. **The case: its base is not the main head, and the head changed files of its two packages since (K14's wirings), so on the main tree, once: whole server and whole livepages on Windows, the collector's `TestPagesMirrors|TestMirrorPages|TestMirrorAutoNew|TestMirrorDoor` and the launcher's `TestMakeFolder` by name, the viewer's wall test, build, vet, gofmt, the commands; no race detector (no goroutine, no lock added).** Then in the same command: the review through the scrub script (`docs/review/pages-g12-auto-switch-2026-11-16.md`), the commit with `runs-int-i4/msg-g12.txt`, the push, the collector in place (the pages are in it); after "done": a Linux build and a Linux vet of the two packages as a check after the merge (the script has none), and `runs-int-i4/folder.sh` (the owner's folder, with the folder script's wider running check). The roadmap's row is edited in the main tree and goes in with it. **DO NOT TOUCH THE MAIN TREE WHILE IT SHOWS STAGED FILES.** If this session is gone: the last lines of `merge-g12.out` say "done <commit>" or "STOPPED at <step>", then the two Linux lines and "FOLDER: ok"; then mark the queue's entry, the board's row and merged line. Pages (P5) wrote "ready for a take-over" at 14:52 (G12 listed, nothing runs): a successor for pages is the owner's to say.
- 15:06 (I-4): **G12 IS MERGED AND PUSHED BY THE SCRIPT (14:52:38 to 15:02:56): 527aed9** (no conflict on b435266; whole server 151.9 s, whole livepages 0.8 s, the collector's four sets by name 404.6 s, the launcher's folder tests 14.1 s, the viewer's wall test, build, vet, gofmt, the commands: ok; the review copied, 1 path replaced, 0 left; the roadmap's row). After it, in the same command: the Linux build exit 0, the Linux vet of server and livepages exit 0. **THE COLLECTOR IN PLACE since 15:02 (69a9c43's kept); THE OWNER'S FOLDER REBUILT 15:03 from 527aed9** (0 programs ran from it; the folder script now also refuses while a window, a viewer or a backup runs from it). **C15 (`wip/copies-21` de113d6b, listed 14:58: the read-only tool `tools/probe-misses`, four new files, no package of the product touched) IS MERGED AND PUSHED BY THE SCRIPT (15:04:25 to 15:04:52): ab4d885.** Read by me first: the entry; the tool's entry point; how it opens the catalogue (itself, never through the catalogue package: immutable with no log beside the file, read-only with one, a query-only pragma; a log without its index file refused); every print call (counts and words from fixed lists; a word outside the list is counted, not printed). The case: its base is the head before G12, which touched none of its files: the tool's tree equal to the branch's; the tool's tests 3.1 s, the wall test, build, the commands; by me after it, two single commands: gofmt over `tools` clean, vet of `tools` exit 0 (the script covers `internal` and `cmd` only). Nothing to put in place; no folder rebuild. **Merged by this session: 3 (C14, G12, C15) and one documents commit. The main head is ab4d885, equal to `private`, clean; nothing of mine is staged or running.** The queue's two entries marked MERGED; the board's row and two merged lines: done. **Ruled on my row, since Core has no session that can answer: the lines copies (131 a) and the viewer (129 b) ask to borrow in Core's files are read by me at the merge in Core's stead; both go on.** Read on the board: copies' 131 and 132, the viewer's 129 (14:55: the wiring looked at a third time, "it may be merged with the seam live"; its fix round runs; entry 25 after the viewer's whole and race runs, about 50 minutes). Seen there: the owner to copies, 14:33: "Push C15 to finish even with lower memory since it's on the cusp". Next step in one line: one background watch for the next listing (M12, C16, C17, entry 25).
- 15:32 (I-4): the afternoon's lessons are a block in `START-INTEGRATOR.md` (15:07: waits that cannot end; a listing without runs that the merge repeats anyway; a one-place "keep both" joined in a copy; what the merge script does not cover; where the memory is; lent lines of a track with no session). **C17 (`wip/copies-23` 9d67dbf4, listed 15:28, holding the main head ab4d885 exactly: a frame-check row settled with a decisive result is final as a record; code that touches what is held or wanted) IS MERGED AND PUSHED BY THE SCRIPT (15:29:30 to 15:31:03): 0d08996.** Read by me first: the entry; the whole change to `probe.go` (the guard at the top of `probeSettle`: a done row with copy, partly or no match returns "late" or "left" and writes nothing to the row or the file; `ProbeFetched` gives the file back as before and skips the row's rewrite for such a row; the new count read beside the late one). Against the rules read at 14:10 (`TRIED-BEFORE.md` 6, 21, 27): no path of it sets skipped or gone; a hold is never touched; the one fate that changes (a "copy" after a "no match" on a free file, which no path sends today) ends as wanted, never as skipped. **The case: its base is the main head, so the merged tree is the tested one** (whole catalogue 522.6 s, probejudge, supply, the collector's frame-check tests by name on that tree, by the track's clerk): the catalogue's tree compared ("equal"), `TestProbe` by name 36.6 s, the wall test, build, gofmt, the commands; no whole run of mine, no race run (no concurrent code changed). The review copied, 0 paths; the roadmap's row. **THE COLLECTOR IN PLACE 15:31 (527aed9's kept); THE OWNER'S FOLDER REBUILT 15:31 from 0d08996 (0 programs ran from it).** The queue's entry, the board's row and merged line: done. **Merged by this session: 4 (C14, G12, C15, C17) and one documents commit. The main head is 0d08996, equal to `private`, clean; nothing of mine is staged or running.** Routine steps: two scripts in one command. Next step in one line: one background watch for the next listing (M12, C16, M6, entry 25).
- 15:44 (I-4): **C16 (`wip/copies-22` 71754b5a, listed 15:41: the copy checks' switches as six stored settings read at the collector's start, doors for a page; cut from ab4d885) IS STAGED ON THE MAIN TREE AND IN ITS MERGE RUN SINCE 15:42, one background command of this session (`ix-tools/merge-as-tested.sh c16 ...`, then `folder.sh`; its lines in `runs-int-i4/merge-c16.out`, logs in `runs-int-c16/`).** Read by me first: the entry; Core's lent lines in `collector.go` (+4: one field, one call line in `Run` after the catalogue is open and before the staging is made; read in Core's stead, as my row says); the start's code `copyset.go` whole (a flag given wins for the run; no flag: the stored row; an unreadable row is off for a switch and the default for the others, said once; a read that fails leaves the flags' values; a check on by its stored setting whose set-up fails is off for the run and the start goes on, by the start flag the refusal stands); the flags' part of `framecheck.go` (defaults and bounds now from the new package, the same values). Not read by me: the doors' file, the new package's parsing (61 malformed values probed by the reviewer and kept as tests), the tests. **The case: its base is one merge behind the head (C17: one file of the catalogue, which the collector imports), and its branch ran the collector by name only: so on the main tree, once: the whole collector (about 28 minutes) and whole copyset on Windows, the viewer's wall test, build, vet, gofmt, the commands; no race detector (the track's race run by name on the settings' tests was clean on its tree; C17 changed no concurrent code).** Then the review through the scrub script, the commit with `runs-int-i4/msg-c16.txt`, the push, the collector in place, the owner's folder. The roadmap's two rows are edited in the main tree and go in with it. **DO NOT TOUCH THE MAIN TREE WHILE IT SHOWS STAGED FILES.** If this session is gone: the last lines of `merge-c16.out` say "done <commit>" or "STOPPED at <step>", then "FOLDER: ok"; then mark the queue's entry, the board's row and merged line. **Copies (C5) wrote at 15:41 that it hands the track over (every piece listed or merged): with Core and pages, three tracks ask for a fresh session; asked of the owner.**
- 16:18 (I-4): **C16 IS MERGED AND PUSHED BY THE SCRIPT (15:42:23 to 16:11:24): 5d884fc** (no conflict on 0d08996; whole copyset 0.4 s, whole collector 1,699.1 s, the viewer's wall test, build, vet, gofmt, the commands: ok; the review copied, 0 paths; the roadmap's two rows). **THE COLLECTOR IN PLACE 16:11 (0d08996's kept); THE OWNER'S FOLDER REBUILT 16:11 from 5d884fc (0 programs ran from it).** The queue's entry and the board's merged line: done. **Merged by this session: 5 (C14, G12, C15, C17, C16) and one documents commit.**
  - **A FINDING OF THE VIEWER'S (message 135, 16:08), CHECKED BY ME AT 16:13 ON THE MAIN HEAD 5d884fc: ONE VIEWER TEST FAILS SINCE C13's MERGE OF 12:28** (`TestLostThroughIncrementalUpdate`: "1 full reads: every update was to be incremental"; run by name: FAIL; the set `TestLost|TestStaged|TestIncremental|TestRandomUpdates|TestChanges|TestWall` by name, 100 s: that one failure and no other). Not a wrong result: a removed look-alike edge is logged as "gone", which names nothing, so an open viewer reads its whole index again. C13's merge ran the viewer's wall and schema tests, not this one; C17 and C16 of mine ran the wall test only. **Done about it: the remedy is a row in "Listed and unbuilt" (Core's change log with copies' removals; the viewer's side after); the viewer mends the test's words in entry 25; and from now on a merge of mine that changes `internal/catalog` runs those viewer tests by name on the combined tree (on my row; to go into the start file).**
  - **M12 (`wip/mirror-cap` 9f15ba3b, listed 16:11: the cap on new mirrors in any 24 hours as a stored setting, 20 by default; cut from 0d08996; code that bounds what is created on Telegram for the owner) IS STAGED ON THE MAIN TREE AND IN ITS MERGE RUN SINCE 16:14, one background command of this session (`ix-tools/merge-as-tested.sh m12 ...`, then `folder.sh`; its lines in `runs-int-i4/merge-m12.out`, logs in `runs-int-m12/`).** Read by me first: the entry whole; `TRIED-BEFORE.md` 24 and 25 (read 14:10: a cap per step, fail closed, a mark that cannot be read never reads as empty); `newperday.go` whole (unreadable: 5 in force, never 20, never "no cap"; a read that fails ends the turn; `createsRoom`'s loop ends because the ledger's count is of creates strictly after the time given: read in `MirrorCreatesSince`); the turn's and the plan's use of it; the run command's one call and help. Not read by me: the doors' file, the set-up fact, the tests (the reviewer's two passes with planted changes did). **The case: its base is one merge behind the head (C16 changed files of the collector), and its branch ran the collector's mirror set by name, never the package whole: so on the main tree, once: the whole collector (about 28 minutes) and whole livepages, the cap's mirror tests by name, the wall test, build, vet, gofmt, the commands; no race detector (its own race run by name was clean; C16 changed none of its concurrent code).** Then the review through the scrub script (`docs/review/mirror-cap-2026-11-16.md`), the commit with `runs-int-i4/msg-m12.txt`, the push, the collector in place (the default cap becomes 20 for every run without the flag), the owner's folder. The roadmap's row is edited in the main tree and goes in with it. **DO NOT TOUCH THE MAIN TREE WHILE IT SHOWS STAGED FILES.** If this session is gone: the last lines of `merge-m12.out` say "done <commit>" or "STOPPED at <step>", then "FOLDER: ok"; then mark the queue's entry, the board's row and merged line.
- 16:52 (I-4): **M12's FIRST MERGE RUN STOPPED AT THE WHOLE COLLECTOR (16:45): ONE TEST FAILED, `TestFrameCheckRestart/during_the_fetch` ("no part of the check was put", after its 90 s), in a package run of 1,835.3 s in which every other test passed. READ TO ITS CAUSE, NOT CALLED A FLAKE:** the test is the copies track's (C12's), and M12 touches nothing of the frame check. It arms its hold on a part's write only after it has seen the video's media row by a poll (20 ms plus a read-only open of the catalogue at each look), and its own comment says "a part put sooner is not held": on this busy PC the check's parts were all written before the hold was armed, so the test waited its 90 s for nothing. Shown: 4 of 4 by name on the same staged tree (4.7 s in all), and once more in the second run's named set. **A hole in the test, not in the product; told to copies in message 140 a (arm the hold before the video is pushed).** My judgement, said in the commit message: no second whole run of 28 minutes for a green line; the piece's difference taken back out of the main tree by the reverse of the same apply (the roadmap's edit kept), and the script run again without the whole package: whole livepages, the cap's mirror tests, the collector's `TestFrameCheckRestart|TestMirrorNewPerDay|TestMirrorAutoSetUpFailed|TestFlags` by name 56.2 s, the wall test, build, vet, gofmt, the commands: ok. **M12 IS MERGED AND PUSHED (16:46:27 to 16:47:59): 44a6d7b; THE COLLECTOR IN PLACE 16:47 (5d884fc's kept): the cap on new mirrors is 20 by default from any run's next start; THE OWNER'S FOLDER REBUILT 16:48 (0 programs ran from it).** The review copied (0 paths); the roadmap's row; the queue's entry, the board's row, merged line and message 140: done. **Merged by this session: 6 (C14, G12, C15, C17, C16, M12) and one documents commit. The main head is 44a6d7b, equal to `private`, clean; nothing of mine is staged or running.** Read on the board: the viewer's 137 (entry 25 listed 16:12: the pass-through wired; a lent commit in `actdoor` and `pages.go`; the mended test), copies' 138 and 139 (C19: a removed edge logged as its two media's change, with a coder; schema step 27 claimed; C18 small things). **Two schema steps are coming (the mirror's M6, copies' C19): the first listed is 26; said on my row and in 140 b.** Copies' session: the owner asked for a fresh one at 15:45 and said at 16:25 to carry on in C5 for now (copies' 138 f): so of my question to the owner, copies is answered; Core and pages are open. Next step in one line: entry 25: read the lent commit and the door's path, say the run plan, merge.
- 16:53 (I-4): **THE VIEWER'S ENTRY 25 (`wip/b-door` 9fec0938, listed 16:12: the pass-through to the collector's door, wired: THE SEAM GOES LIVE; cut from e9b8c540; it is on the path that writes to Telegram at the owner's click) IS STAGED ON THE MAIN TREE AND IN ITS MERGE RUN SINCE 16:50** (`ix-tools/merge-as-tested.sh e25 ...`, then `folder.sh`; started by me as a job inside one command, which I should have started as a background command: it runs on; a background watch of this session waits for its last lines in `runs-int-i4/merge-e25.out`; logs in `runs-int-e25/`). Read by me first: the entry whole; the board's 129 (14:55) and 137; **the lent commit f7a148b5 whole** (`actdoor/door.go`: one more field, the catalogue file's base name, checked as a plain file name; a file without it is "not whole" to the reader; `Write` takes it as one optional argument; one line of the collector's `pages.go` hands it in): additive and strict, taken as it is in Core's and pages' stead; **the first half of `act_door.go`, the one file of the viewer that connects** (the address must be exactly this PC's own with a port; the dial reaches that address whatever the URL says; no proxy, no kept connection, no redirect followed; a client of its own a call; the two kinds of failure kept apart). Not read by me: the click route's key logic in `act.go` and `act_keys.go`, the page script, the tests (three independent looks with probes, and the end-to-end test that asserts one click, exactly one send). **The case: its base is six merges behind the head, and the collector, the server and the catalogue moved beneath its test package since: so on the main tree, once: whole actdoor, acttest (the whole chain: a real viewer, the real door, the collector against its fake Telegram), server and viewer on Windows (about 10 minutes), the collector's `TestDoor|TestClickDoor|TestPages|TestE2EPages|TestRunPages|TestRunWithoutPages` by name; build, vet, gofmt, the commands. Not the whole collector: one line of `pages.go` is all it changes there, and the package ran whole on this head's code four times today. No second race run: no file of the viewer changes at the merge (its own: 2,503 s, no data race).** The three reviews go to `docs/review` (two copied by me through the scrub script, 0 paths each; the third by the merge script). The roadmap's acting row is edited in the main tree and goes in with it. Then the commit with `runs-int-i4/msg-25.txt`, the push, the collector in place, the owner's folder. **DO NOT TOUCH THE MAIN TREE WHILE IT SHOWS STAGED FILES.** If this session is gone: the last lines of `merge-e25.out` say "done <commit>" or "STOPPED at <step>", then "FOLDER: ok"; then the queue's entry, the board's row and merged line, and one line for the owner's list (the first real click; one catalogue file per folder until every program is of this build), which the viewer session writes.
- 17:04 (I-4): **ENTRY 25 IS MERGED AND PUSHED BY THE SCRIPT (16:50:08 to 17:00:37): 5a13119: THE SEAM IS LIVE ON THE MAIN HEAD** (no conflict on 44a6d7b; the viewer's, acttest's and actdoor's trees equal to the branch's; whole actdoor 0.7 s, acttest 7.7 s, server 144.0 s, **viewer 414.8 s with no failure: the test that failed on the head since 12:28 is put right**, the collector's door and pages tests by name 16.4 s, build, vet, gofmt, the commands: ok; three reviews in `docs/review`, 0 paths; the roadmap's acting row). **THE COLLECTOR IN PLACE 17:00 (44a6d7b's kept); THE OWNER'S FOLDER REBUILT 17:00 from 5a13119 (0 programs ran from it): its collector, viewer and window are of one build, as the door file's new form needs.** The viewer track's own `bin` is the viewer session's (its script waits for the head); the owner's line for the first real click is its to write. The queue's entry, the board's row and merged line: done. **Merged by this session: 7 (C14, G12, C15, C17, C16, M12, entry 25) and one documents commit. The main head is 5a13119, equal to `private`, clean; nothing of mine is staged or running.** Coming, by the notes: M6 (the mirror: adopting a chat; its third review look says "may be listed"; in its full runs since 16:58; a schema step), C18 (copies: in its fix round, with the restart test's hole), C19 (copies: the removed edge in the change log; a schema step; with the viewer's side). Next step in one line: one background watch for the next listing.
- 17:11 (I-4): a documents commit at 17:02, pushed: 3781f8f (the handoff's block after the afternoon's merges: the live seam, the copy checks' settings, the switch's control on a page, the cap; no code). **C18 (`wip/copies-25` 520c996f, listed 17:09: small things in the frame check's start and hourly lines, and the restart test's hole of my message 140 a closed; it holds 5a13119, the head's own code) IS STAGED ON THE MAIN TREE AND IN ITS MERGE RUN SINCE 17:09, one background command of this session (`ix-tools/merge-as-tested.sh c18 ...`, then `folder.sh`; its lines in `runs-int-i4/merge-c18.out`, logs in `runs-int-c18/`).** Read by me first: the entry; every changed line of code (the mark's removal: only of a file the same call made by an exclusive create, four tries, then a fixed line; the prefix said once; the new hourly line: two key lookups under a bound of 2 s, nothing read once the stop has begun; `ProbeWordCounts`). Nothing in it decides a file's fate. **The case: its base is the head's code (one documents commit on top), so the merged tree is the tested one; its branch ran the collector by name only, and the piece adds log lines, which other tests of the package may count: so the whole collector once on the main tree (about 30 minutes), the catalogue's `TestProbe` and the viewer's change-log tests by name (the catalogue changes), build, vet, gofmt, the commands; no race detector (its own by name was clean).** Then the review through the scrub script, the commit with `runs-int-i4/msg-c18.txt`, the push, the collector in place, the owner's folder. **DO NOT TOUCH THE MAIN TREE WHILE IT SHOWS STAGED FILES.** If this session is gone: the last lines of `merge-c18.out` say "done <commit>" or "STOPPED at <step>", then "FOLDER: ok"; then the queue's entry, the board's row and merged line. Read on the board: 141 to 143 (C19 was found by its reviewer to make the viewer wrong alone; it lands as one entry of the viewer's on copies' branch, with a kind of its own in the log) and the owner's item 39 (the first real click, written by the viewer session at 17:02).
- 17:47 (I-4): **C18 IS MERGED AND PUSHED BY THE SCRIPT (17:09:38 to 17:41:49): 78739d5** (the collector's and the catalogue's trees equal to the branch's; the whole collector 1,754.9 s, the catalogue's `TestProbe` 30.0 s, the viewer's change-log tests by name 100.9 s, build, vet, gofmt, the commands: ok; the review copied, 0 paths). **THE COLLECTOR IN PLACE 17:41 (5a13119's kept); THE OWNER'S FOLDER REBUILT 17:42 (0 programs ran from it).** The queue's entry and the board's merged line: done. **Merged by this session: 8 (C14, G12, C15, C17, C16, M12, entry 25, C18) and two documents commits.**
  - **M6 (`wip/mirror-adopt` 3b2f943a, listed 17:28: an existing chat of the owner's as a source's mirror, by the owner's command; 38 files; A SCHEMA STEP; code that decides what is forwarded; it holds 3781f8f, one merge behind the head) IS STAGED ON THE MAIN TREE AND IN ITS MERGE RUN SINCE 17:43** (`ix-tools/merge-as-tested.sh m6 ...`, then `folder.sh`, started detached by one command because the run is close to an hour; a background watch of this session waits for its last lines in `runs-int-i4/merge-m6.out`; logs in `runs-int-m6/`). Read by me first: the entry whole; the design `DESIGN-M6-adopt-chat.md` whole; the live lessons' 6b (what the app adds stays below the owner's choices; a person's choice is never undone) and `TRIED-BEFORE.md` 24 and 25 (read 14:10); **the weigh, `mirroradopt.go`, whole**: "there" only by a post-naming origin no other source message has, or by the same media with exactly one bare candidate, a media key unique in the source and every row exclusive on both sides; "not there" only when no message of the chat shares any media row; everything else "cannot tell"; a copy tied to two source messages refuses the whole weigh; never by text, date or position: as the design says. The schema's lines in `catalog.go`: the step follows K14's, so IT IS STEP 26 with no edit of mine (C19 is not merged; it becomes 27). Not read by me: the record's transaction, the id lists, the later runs' bounds, the command, the tests: the reviewer's three passes with 39 planted changes and 1,600 random worlds did. **The case: a schema step, and its base is one merge behind: every package that opens a catalogue and had not run with the step, whole, once on the main tree: tgstore, bringin, supply, probejudge, pairwords, partsledger, copyset, livepages, actdoor, acttest, server, viewer, collector (about 50 minutes, the collector 30 of them); the catalogue, the mirror and telegram ran whole with the step on its branch and nothing of theirs moved since but one read in `probe.go`: by name here (the catalogue's `TestSchema|TestMirror|TestProbe|TestProtected`, the mirror's and telegram's mirror tests); build, vet, gofmt, the commands; no race detector (no goroutine, no shared state added).** Then the review through the scrub script (`docs/review/mirror-adopt-2026-11-16.md`), the commit with `runs-int-i4/msg-m6.txt`, the push, the collector in place (its first read-write open steps a catalogue to 26), the owner's folder. **A roadmap row is given to the feature (it had none) and goes in with it.** **DO NOT TOUCH THE MAIN TREE WHILE IT SHOWS STAGED FILES.** If this session is gone: the last lines of `merge-m6.out` say "done <commit>" or "STOPPED at <step>", then "FOLDER: ok"; then the queue's entry, the board's row, merged line and schema line (26 on the head; C19 is 27), the handoff's schema lines in a documents commit, and tell the viewer session that its `bin` needs builds of this head (an older viewer refuses a catalogue at step 26).
- 17:48 (I-4): **usage, measured 17:47: 67% of all models' week, 21% of this model's** (50% and 1% at 14:02: about 4.5 points an hour of all models and 5.3 of this model, with five tracks building; at that rate all models' week is used up near 01:00 tonight; the reset is in 4 days 21 hours). This session's context: 59%. Said on my row and to the owner; no hold is mine to set without the owner's word (the owner at 13:47: "Go as needed").
- 18:01 (I-4): **M6's FIRST MERGE RUN STOPPED AT THE WHOLE SERVER (17:50): FIVE TESTS FAILED, all of the Staging page (`TestStagingWaitCauses`, `TestStagingCopiersFromMemory`, `TestStagingGaugesWhenNeeded`, `TestStagingHoldsUnread`, `TestStagingLiveReadsNoTable`), each with the page's verdict "no room". READ TO ITS CAUSE: their rig (`newStagingEnv`, `KeepFree: 50 << 30`) lets the page read the REAL free space of the temporary folder's disk (`freeBytes`), and this PC's system disk has 49.4 GiB free (measured: 49.4 of 1,862; the other disk 974.9).** Not M6's (the mirror touches nothing of it; the same package passed whole at 17:00 with the disk just above the floor). A fault of the pages track's tests AND a fact about the PC, both said (board message 149 d; the owner). Ten packages had passed whole with the step before the stop (tgstore, bringin, supply, probejudge, pairwords, partsledger, copyset, livepages, actdoor, acttest); the server's other tests passed. **The piece's difference taken back out by the reverse of the same apply, and the script started again at 17:54, detached, for what was still owed: whole viewer and whole collector, the server's `TestMirror|TestClick|TestMutations|TestAssets|TestSecurity` and the catalogue's, the mirror's and telegram's tests by name; `runs-int-i4/merge-m6b.out`, logs in `runs-int-m6b/`; a background watch of this session waits for it.** The commit message says the five tests and why.
  - **THE OWNER, 17:53, to my three questions: "1. Keep going 2. Start both 3. Yes":** no hold on usage; successors for Core and pages; the tracks may remove their finished copies of merged branches (each checked clean and pushed first). **Done 17:56: Core session K-5 (`archiver-core-5`) and pages session P6 (`archiver-pages-6`) started with briefs** (each: the clerk rule in its first lines; what to read; what changed since its take-over block; the order; what "done for the first turn" is; K-5's first: the answer owed to copies' 113 b, then downloads only in hours without the speed limit; P6's first: the five staging tests' mend, then the Settings rows for the mirror's cap and the copy checks) **and detached.**
  - **THE OWNER, 17:58: "How are things looking? The daily mirror cap should be 20, but the maximum of 50 is dumb. It should be higher if needed, configurable. If there's sessions that can be archived, please do so."** Done: the cap's bound is routed to the mirror (board message 149 b, a row in "Listed and unbuilt", one message to M-6); FEATURES 12's words follow after M6's merge (the main tree is staged). **Archived at the owner's word: K-4 (Core), P5 (pages), the integrator session of 06:55. Not archived, refused by the app: two older copies sessions ("live work") and two sessions with "keep awake" on (the tenth session of 11-14; the integrator of 11-15 22:55): the owner's to close from the sidebar.**
  - Read on the board: 144 to 148. **C19 (copies, `wip/copies-24` 761b88d6: a removed look-alike edge logged as a kind of its own; A SCHEMA STEP) is listed since 17:52, by itself: it is step 27, after M6's 26: joined by hand in a copy of mine when M6 is on the head.** Board message 149 says all of this to every session. My row is brought up to it.
  - A measurement of our own leftovers on the system disk (the go cache, the folder's kept program sets, the kept collector builds, the temporary folder) was started at 17:53 and had not answered after 3 minutes; it runs on in the background. Next step in one line: M6's result; then C19's join.
- 18:02 (I-4): **THE OWNER, 18:00: "I cleared a bunch of space". Measured 18:01: the system disk has 128.5 GiB free of 1,862 (49.4 at 17:52); the other disk 974.9.** So the server's five staging tests pass on this PC again; the fault in them (the real disk read against a floor of 50 GiB) stays until pages' G15 (P6, with a coder since about 18:00). My measurement of our own leftovers was stopped unanswered (no longer needed; it was slow on the go cache). On the notes branch since 17:56: P6 has the pages track and took the lent door lines as they are; the mirror has M13 (the cap's maximum) with a coder; the viewer's side of the removed edge is reviewed ("ready for its full runs"). M6's second run: the whole viewer is running.
- 18:06 (I-4): **THE OWNER, 18:03: "what do you want me to do now? Provide instructions with specific links ... we can start if needed, but don't stop building"; before it: "please check the board and features. Where are we at?"** Answered from the roadmap's rows (about 105 features: 16 have met the real thing, 61 are built and tested on invented data only, 14 partly built, 12 not built) and the board (40 listed rows, 14 struck, 26 open). **Given to the owner, by full paths: the first real start of the folder's program on the test account** (items 35, 31 and 39 in one sitting): stop anything of `a3`; the VPN on; open `tgarchive.exe` in the owner's folder; on the setup: the data folder is the test account's root under the Windows profile (it holds `catalog`, `library`, `staging`: checked by listing the folder's three names, nothing opened), the library and the staging its two folders; the collector's file of the folder into the VPN's split tunnelling list; Save and start; look at the pages; one line to Saved Messages from the viewer's window; Quit. Read by me for it: the folder's `README.txt`, `a3-start.ps1`'s defaults, the launcher's layout constants. **Said with it: while the folder's app runs, my rebuild of the folder and the replacing of the collector under the profile are refused by their own checks (as designed): merges go on and are pushed; the folder is rebuilt after the owner's Quit.** The folder is at 78739d5 (the build of 17:42). M6's second run: the whole viewer ok 418.6 s; the whole collector is running.
- 18:23 (I-4): **THE OWNER'S FIRST REAL START OF THE FOLDER'S PROGRAM, 18:05 to 18:15, AND THE OWNER'S WORDS (18:13, with two screenshots): "Well, deeply unsatisfying so far. I put in the wrong library folder (linked it to the library from the old app ...) and there's no way to change it. It says to quit/reopen the app, but quitting doesn't actually exit it? Also, clicking viewer set its address brings you to settings, but not clear what should happen next, and the text breaks. Overall, it's a very ugly app, not fully functional, doesn't quit properly, and still runs in a browser, just a standalone one?"** The screenshots: the Queue page with only "Cannot read properties of null (reading 'length')"; Settings' Theme row with two texts over each other and an empty "Viewer address" field.
  - **Read by me, read-only (two scripts written by the Write tool, `runs-int-i4/look-settings.py` and `look-folders.py`: counts, kinds and the app's own file names only; the launcher's and the collector's logs with every path cut out; nothing opened, nothing stopped; an inline script with a Windows path failed first, my error, and wrote nothing):** 4 programs of the app ran from the folder at 18:15 (the launcher, the watchdog, the collector, one window). The saved setup: the data folder left as offered (a NEW catalogue inside the app's folder, not the test account's); **staging: a folder under the old app's folder; library: the old app's library root (199 entries directly in it).** **In the library the app made or changed NOTHING; in the staging folder its mark (71 bytes, 18:07:27) and one more new file; no download and no copy: no chat is chosen.** The launcher's log: three folder boxes came up; the setup saved 18:07:26; the public address in 0.2 s; the pages answered in 0.5 to 0.8 s; Quit on the pages ended everything twice (18:07:53, 18:08:36: the collector in 30 and 49 ms); a new launcher started 1 s after the first Quit (cause not known); **at both starts with a saved setup the app's window ended by itself with exit code 0 after 8 s and 4 s, in the second the viewer was started**; the owner opened `tgarchive.exe` again each time. **The first real sign-in from the Accounts page, 18:11: a code, the two-step password, signed in; then 4 requests, 4 answered, no wait; idle since; every VPN check "behind the VPN".** Which account was signed in is not known to me: asked of the owner.
  - **Done:** board message 150 (the owner's words and the facts, by track: pages a to f, the viewer e and f, Core d); one message each to pages (P6) and the viewer (B6): these come first; no restyle before the owner says what "native" should mean. The memory of the owner's view of the app is brought up to this second look. **Told to the owner:** choose no chat and mirror none while the folders are wrong; Quit on the pages does end everything; the folders can be named anew by removing the folder's settings file after a Quit (the launcher then shows the setup: its log's "settings state 1"), or I set the two folders there at the owner's word.
  - **18:27: THE OWNER, 18:20: Saved Messages is not found in the app's Chats; asks whether the unified stream with a media toggle, the deleted highlight and "new / first seen" exist; "It was the test account I logged into. I've quit the app now, haven't deleted anything. Show me options for the app. You can do better, and you know what the old one and its base (the one we built off of) looked like."** Done: three looks as pictures on invented data, one file made by me with the Write tool (`design-options/app-look-options.html`: A like a Telegram client, B like a photo library, C like the old app's dashboard; what makes each an app and not a browser; my recommendation A), looked at once in the built-in browser (it draws), sent to the owner. For it I read the old app's page sources for their tabs and colours (code only; no page of the old app was opened). Answered from the roadmap: the three viewer features are merged and tested on invented data, never seen by the owner. Board message 151 (pages and the viewer: Saved Messages; no restyle before the owner chooses; the faults of 150 are mended in the present look). The owner's app has ended (0 programs from the folder at 18:21). On the notes branch: pages lists G15 (the Staging tests off this PC's disk) and took the owner's points first; the viewer has an investigator on the window that ended by itself; copies lists C20.
  - **18:38: THE OWNER CHOSE THE APP'S SHAPE (18:30): "A looks useful, and practical, but I would still want the library views and toggles from B, and the dashboard from C is also useful for consolidating the info so long as it links to the appropriate window/filter as well. Is that consistent with what you recommended?"** Yes. Done: a fourth picture, "The combination", added as the page's first button and sent (looked at in the built-in browser: it draws); **the decision written as one page, `DESIGN-ONE-WINDOW.md`** (the owner's words; the shape in five points; what makes it an app and not a browser; what is left for a joint note of pages and the viewer; the rules that bind it); board message 152 and a row in "Listed and unbuilt". Not briefed, not built: the two tracks write one joint note on "how" first; the faults of message 150 come first, in the present look. The memory of the owner's view of the app is brought up to it.
  - **18:31 by the clock (my entries of "18:23" to "18:38" above were written up to ten minutes ahead of it: times from `date` from here on): THE OWNER, 18:27, on the combined picture: "Yeah, I think that's a great place to start. Go with it please."** `DESIGN-ONE-WINDOW.md` says DECIDED, to be built; board message 153 (pages leads the joint note; the order of pieces; the usage); one message each to pages (P6) and the viewer (B6). **Measured 18:27: the viewer session B6 is at 94% of its context (it cannot take the one window: asked to write its take-over state; a fresh viewer session is asked of the owner); pages P6 at 42%. USAGE 18:27: 74% of all models' week, 31% of this model's (67% and 21% at 17:47): about 10 points an hour with seven sessions and their agents; at that rate all models' week ends near 21:00 tonight; the reset is 4 days 20 hours away. Asked of the owner: whether what is left goes to the one window and the first start's faults, the other tracks finishing to their listings and stopping.** This session's context: about 70%.
  - **18:38 (the clock): THE OWNER, 18:33: "Keep all going" (to my question whether the usage left should go to the one window only).** On my row for every track. The viewer's successor: my start of it was refused by the app (the owner had not asked for that session in words): `START-VIEWER-B7.md` is its start file; the owner pastes one line. B6 wrote its state for a take-over at 18:28 and was at 94% of its context.
  - **M6's SECOND MERGE RUN STOPPED AT THE WHOLE COLLECTOR (18:31): ONE TEST FAILED, Core's `TestNotCountedRepeatWaitsDerived`: "not_counted names repeat_waits.refresh, which is counted" (1,772.3 s; every other test of the package passed; whole viewer 418.6 s ok). READ TO ITS CAUSE: THE PIECE BREAKS IT:** `mirror_ids.go` sends the id lists through the request loop under the refresh's kind (`f.cl.call(..., refreshWhat, pickRefresh, ...)`), so that kind's repeat waits are counted now, while the status file's `notCounted` list (Core's `status_file.go`) still names them; the test derives the list from the telegram package's code. The mirror's branch had run the collector's mirror set by name only, so it never met this test. **M6 IS HANDED BACK (the queue's entry, board message 154 a, one message to M-6): the mend is the mirror's choice (the list's line with a true comment, or a kind of its own for the id lists); it merges the head in and becomes SCHEMA STEP 27.** Its difference is out of the main tree (the reverse of the same apply); my roadmap row for it is taken back and comes again at its merge.
  - **C19 (copies, `wip/copies-24` 761b88d6: a removed look-alike edge logged as a kind of its own; SCHEMA STEP 26 as its own constants have it; `internal/catalog` only, 6 files) IS STAGED ON THE MAIN TREE AND IN ITS MERGE RUN SINCE 18:33** (`ix-tools/merge-as-tested.sh c19 ...`, then `folder.sh`, detached; `runs-int-i4/merge-c19.out`, logs in `runs-int-c19/`; a background watch of this session waits for it). Read by me first: the entry whole (the trigger dropped and made again; two rows of kind 6 per removed edge; the viewer on the head takes an unknown kind as a full read, so no order of rebuilds makes an index wrong); copies' 138, 139, 141 and the viewer's 142 and 147 (its reviewer's high finding was against the first form, kind 1, and is answered by kind 6). Not read by me: the trigger's SQL line by line and the tests. **The case: a schema step whose change is one trigger: on the main tree, once: whole tgstore, bringin, pairwords, supply, catalog (about 9 minutes) and viewer (7); the collector's `TestPairWords|TestFrameCheck|TestDoor|TestPages|TestE2EPages|TestCopySet` by name (the collector does not read the change log: not the whole package); build, vet, gofmt, the commands; no race detector (a trigger's text and a constant).** Prepared and not needed now: `runs-int-i4/join-c19.sh` and `resolve-schema.py` (for a second schema step on top of a first: the pattern for M6's next listing if its branch does not hold the head). **Next free schema number: 28.**
  - **THE OWNER, 18:35: "Set them to empty folders please." DONE 18:33 to 18:35 by `runs-int-i4/set-folders.py` (written by the Write tool; it refuses while a program of the app runs: 0 ran): the folder's settings file names two new, empty folders on the other disk for the library and the staging; the 10 other settings unchanged; the file as it was is kept beside it.** Checked first, read-only (`look-catalogue-library.py`, the catalogue opened with mode=ro): the new catalogue names no library of its own (no settings row), so nothing else has to change; it holds 1 account, 14 chats, 0 messages, 0 files wanted, at schema step 25. Left as they are: the mark and one more file the collector put into the folder under the old app's folder at 18:07 (two small files; the owner's to remove).
  - **18:55 (the clock): C19's FIRST MERGE RUN STOPPED AT THE WHOLE CATALOGUE (18:49): ONE TEST FAILED, `TestTopicSettleAtSize`: "un-choose the busy topic: a chunk held the writer 292.0738ms" against its bound of 250 ms; the package took 601.4 s (486 to 570 on other runs today); whole tgstore, bringin 96.7 s, pairwords and supply 188.7 s had passed. READ TO ITS CAUSE: a timing bound at size on a busy PC (CPU 79% when I looked; five tracks' coders and runs): the piece replaces one trigger on the copy links and touches nothing a topic's settle runs. Shown: the same test 2 of 2 by name on the same staged tree (123.7 s).** Not a fault of C19; a load-sensitive bound in Core's test (said on the board for Core: the at-size test wants running alone, as `CLAUDE.md` says of the catalogue's scale test). The piece's difference taken back out and the script started again at 18:52, detached, for what was still owed: whole viewer; the catalogue's `TestEdgeLog|TestSchema|TestPair|TestChangeLog|TestActKeySchemaStep|TestMigrate|TestTopicSettleAtSize` and the collector's named set; `runs-int-i4/merge-c19b.out`; a background watch waits for it. The commit message says the one test and why.
  - **The owner started the viewer's fresh session at about 18:33 ("I started it. I think it's just being slow"): session B7 ("START-VIEWER-B7 task") runs; by 18:49 it had answered board message 151 from a look on an invented catalogue (Saved Messages is not named in the viewer; the stream, the deleted marks and "first seen" are as the roadmap says) and has a coder on "Saved Messages by name in the viewer". B6 wrote the owner's answer on the window: it was not closed by hand; windows flickered up several times.** Pages' joint note `DESIGN-ONE-WINDOW-HOW.md` read by me to its section 4: the two servers stay (the VPN rule and the viewer's import wall), one shell package of pages' mounted by both servers, plain links between them, the viewer's window as the one window, started once by the launcher.
  - **PREPARED for after C19: G15 (pages, `wip/pages-free` 7b6fddc0: the Staging tests off this PC's disk; a flag cleared in the right order) and C20 (copies, `wip/copies-26` 7f8ad072: the judge recovers a panic of our own code inside a door call) as one batch** (they share no file with each other or with C19; both hold 78739d5): read by me: both entries whole; G15's one product change (`freeBusy` cleared before the answer is sent; the seam for the free space); C20's `panics.go` (a panic is raised again only when a frame of the database's own package lies between it and the door call; a stack that cannot be walked counts as that: fail closed) and its comments on what cannot be cured there (a driver's panic inside the verdict's transaction hangs with the writer held: Core's, taken by copies' note as K19). The commit messages are `runs-int-i4/msg-g15.txt` and `msg-c20.txt`, the pieces file `pieces-b3.txt`. **Run plan: `ix-tools/batch-tree.sh b3` on the head with C19: whole server, probejudge and catalog on Windows (about 13 minutes), the collector's `TestFrameCheck|TestJudge|TestKeptParts` and the viewer's change-log tests by name; then `merge-batch.sh` (two commits, the collector in place with the second); no race detector (each track's own by name was clean).**
  - **19:08 (the clock): C19 IS MERGED AND PUSHED BY THE SCRIPT (18:52:07 to 19:05:02): 5bfecb5: SCHEMA STEP 26 IS ON THE MAIN HEAD** (whole viewer 490.3 s; the catalogue's edge-log, schema, pair, change-log, migrate and at-size tests by name 115.4 s; the collector's named set 104.2 s; build, vet, gofmt, the commands: ok; the review copied, 0 paths; with the first run's whole tgstore, bringin, pairwords, supply and catalogue). **THE COLLECTOR IN PLACE 19:05 (78739d5's kept): its first read-write open steps a catalogue to 26; THE OWNER'S FOLDER REBUILT 19:05 from 5bfecb5 (0 programs ran from it; its settings, with the two new folders, and its data untouched).** The queue's entry and the board's merged line: done. **Merged by this session: 9 (C14, G12, C15, C17, C16, M12, entry 25, C18, C19) and three documents commits.**
  - **THE BATCH OF G15 AND C20 IS RUNNING SINCE 19:05, detached, one command:** `ix-tools/batch-tree.sh b3` (the copy `wt-int-b3`, branch `int/b3`, cut from 5bfecb58; both pieces applied clean: 18 files staged; the tree of `archiver/internal` 4324f4ae; build ok; whole server, probejudge and catalog; the collector's and the viewer's named sets; lines in `runs-int-i4/batch-b3.out`), then, only on "BATCH-TREE: ok", `ix-tools/merge-batch.sh 5bfecb58 <tree> runs-int-i4/pieces-b3.txt` (two commits through `merge-as-tested.sh`, the collector in place with C20; lines in `runs-int-i4/merge-b3.out`), then `folder.sh`. A background watch of this session waits for its end. **DO NOT TOUCH THE MAIN TREE until it has ended.** If this session is gone: read the two `.out` files' last lines; after "MERGE-BATCH: done": remove `wt-int-b3` and `int/b3`, mark the queue's two entries, the board's row and merged lines.
  - **MY ERROR, 19:06, and its repair: an edit of my board row by an inline script scrambled the row's state (my indexes assumed an order the row did not have) and let ONE CONTROL BYTE into the board (a backslash and "b" of a file's name in a shell string: the start file's rule forbids exactly that).** Found by the count I run after every scripted edit (1 where it must be 0). Repaired at 19:07: the row's state cell written anew, whole, from a text file made by the Write tool (`runs-int-i4/row-now.txt`) by a script made by the Write tool (`runs-int-i4/rewrite-row.py`: it replaces the cell, appends the cell as it was to `BOARD-LOG.md` without control bytes, and refuses if the board changed meanwhile); 0 control bytes now; the row 4.8 KB (it had grown to 11.8 KB). **From here the row is only ever changed that way.** The row first said "19:12": written ahead of the clock again, put right to 19:07.
  - **19:27 (the clock): G15 AND C20 ARE MERGED AND PUSHED BY THE TWO BATCH SCRIPTS (the combined tree 19:05:38 to 19:21:50; the two commits 19:21:50 to 19:22:49): G15 is 2334c65, C20 is 4ce8eec** (on the combined tree, once: whole server 164.8 s with no failed test, probejudge 2.5 s, catalog 561.4 s; the collector's `TestFrameCheck|TestJudge|TestKeptParts` 52.5 s and the viewer's change-log tests 119.7 s by name; vet, gofmt, the commands: ok; each piece's own tree equal to its branch's; the merged tree of `archiver/internal` equal to the tested one, checked by me: the batch script's own check did not run). Both reviews copied (0 paths each). **The merge script's step that puts the collector in place was REFUSED at 19:22 ("a collector or watchdog is running"): looked at by me by path (`runs-int-i4/who-runs.ps1`): four programs named like the app's, all in a temporary folder, started 45 to 110 s before: a track's test stand-ins, none of the owner's. Put in place right after by `runs-int-i4/install.sh` (the same steps, counting by path): THE COLLECTOR IN PLACE 19:23 is 4ce8eec (5bfecb5's kept); THE OWNER'S FOLDER REBUILT 19:23 (0 programs ran from it).** My copy `wt-int-b3` and its branch removed. The queue's two entries, the board's merged line and my row (by `rewrite-row.py`): done. **Merged by this session: 11 (C14, G12, C15, C17, C16, M12, entry 25, C18, C19, G15, C20). NOTHING IS LISTED AND UNMERGED.**
  - **TWO DOCUMENTS COMMITS, pushed 19:25: 028d12f and 7fd9506 (no code): `FEATURES.md` section 12, seventeenth round, has the owner's words of the evening (the cap's maximum; the first real start; the app's shape chosen from pictures; "keep all going"); the handoff's block has the first real start, the decision of the one window and the schema lines (26 on the head; 27 listed and handed back; next free 28); `TELEGRAM-FACTS.md` section 8 has the first sign-in from the app's page (a code, the two-step password, a second login beside the scripts' one: no refusal; 4 requests, no wait); the roadmap has a row for the app as one window and the cap's sentence.** The first of the two names the roadmap's row in its message and did not carry it (an inline script of mine had not found its place and I did not read its error before committing): the second carries it and says so. **The main head is 7fd9506, equal to `private`, clean; nothing of mine is staged or running.** This session's context: about 80%: a successor integrator is the owner's to start when it nears 90%; the state for it is my board row, this file from "THE INTEGRATOR SESSION OF 11-16 14:00" on, and the start file's block "Learnt on 11-16 afternoon".
  - **19:29 (the clock): THE VIEWER'S ENTRY 26 (`wip/b-winfix` b0c1c970, listed 19:05 by B7: the window says how it ended; `-tell-close` and its exit codes) IS MERGED AND PUSHED BY THE SCRIPT (19:26:14 to 19:26:53): f1d7127** (read by me first: the entry whole; the window procedure's note of the end and the one call that hands on the right to come to the front, only at the person's own close and only with the flag; the command's exit codes: without the flag every code as before. The head changed neither package since its base: both trees equal to the branch's; whole window 5.5 s, build, vet, gofmt, the commands; the review copied, 0 paths). No collector change; **THE OWNER'S FOLDER REBUILT 19:27 from f1d7127.** The queue's entry, the board's merged line and my row: done. **Merged by this session: 12.**
  - **USAGE 19:27: 85% of all models' week, 42% of this model's (74% and 31% at 18:27: 11 points in the hour); at this rate it ends near 20:45 tonight; the reset is 4 days 19 hours away. Said to the owner and on my row (no hold: the owner's "Keep all going" stands; every session: take-over block and row current now, every `wip` branch pushed). This session's context: 85%.**

## STATE FOR A TAKE-OVER (the integrator session of 11-16 14:03, `archiver-integrator-4`; written 19:29)
A new integrator is started by the owner with "Read `START-INTEGRATOR.md` and do what it says". It reads my board row first (written whole at each change from `runs-int-i4/row-now.txt` by `runs-int-i4/rewrite-row.py`: change the row only that way).
- **`repo-archiver`: main head f1d7127, equal to `private`, clean, nothing staged; no copy of mine exists; nothing of mine runs** but, at most, one background watch for the next listing (it ends by itself).
- **In place: the collector is the build of 4ce8eec (19:23; no collector code since); the watchdog 8aed433's. The owner's folder (`tgarchive-app` in the owner's profile folder) is rebuilt from f1d7127 (19:27); its settings name two new empty folders for the library and the staging (set by me at the owner's word, 18:33); its catalogue is a new one with the test account signed in (14 chats, nothing chosen), at schema step 25 until a collector opens it.** The viewer track's own `bin` is at 5a13119 (step 25): the viewer session rebuilds it.
- **Schema: 26 on the head (C19). 27 is the mirror's M6 when it is listed again. Next free: 28.**
- **Merged by this session (12, in order):** C14, G12, C15, C17, C16, M12, the viewer's entry 25 (the seam is live), C18, C19 (schema step 26), G15, C20, the viewer's entry 26; five documents commits. Each with its review in `docs/review`, its queue entry marked MERGED, its roadmap row where it has one. Commit messages: `runs-int-i4/msg-*.txt`.
- **Handed back: M6** (the mirror's adopting of a chat: Core's `TestNotCountedRepeatWaitsDerived` fails with it; the queue's entry and board message 154 a say why; it comes again as schema step 27: if its branch then holds the head with step 26, it merges as tested; if not, `runs-int-i4/join-c19.sh` and `resolve-schema.py` are the pattern for joining a second schema step in a copy).
- **Listed and unmerged: nothing (19:29).** Coming, by the rows: the mirror's M13 (the cap without its maximum) and M6; pages' G16 (the cap's Settings row) and G18, G19 (the owner's launcher points: the window's end, Quit, the Viewer link; changing the folders); the viewer's S1 (Saved Messages by name), its side of the removed edge, W2 (the one window's shell); copies' C22; Core's first piece.
- **THE OWNER TODAY (all on record in `FEATURES.md` section 12, seventeenth round, and board messages 149 to 154):** the first real start of the folder's program (18:05): "a very ugly app, not fully functional, doesn't quit properly, and still runs in a browser, just a standalone one"; the app's shape chosen from pictures (18:30, 18:27): ONE window, `DESIGN-ONE-WINDOW.md` and pages' `DESIGN-ONE-WINDOW-HOW.md`, "Go with it please"; the cap on new mirrors: 20, no maximum of 50; "Keep all going"; the tracks may remove their finished copies. **What the owner has NOT done yet with the mended folder: a second start (the settings are right now); the first real click (item 39), which waits for Saved Messages to be findable (the viewer's S1).**
- **Sessions:** pages P6, Core K-5 (both started by me 17:56, detached), copies C6 and the viewer B7 (started by the owner), the mirror M-6. Retired and archived: K-4, P5, the integrator of 06:55. Four older sessions refused to be archived (the owner's to close).
- **HOW I MERGED (all in the start file's blocks "Learnt on 11-16 by day" and "afternoon"):** read the entry and the risky part; say the run plan; edit the roadmap's row in the main tree; write the commit message to `runs-int-i4/msg-<piece>.txt`; `ix-tools/merge-as-tested.sh` (detached with `nohup` when the run is long, a background watch on its `.out` file); a failing test is read to its cause before anything else: three times today it was not the piece (a test's own timing hole; five tests that read this PC's disk; a 250 ms bound at size on a busy PC), once it was (M6); then `runs-int-i4/folder.sh` (and `install.sh` when a track's test stand-in blocked the script's own step); the queue's entry, the board's merged line, the row, this file; the notes committed.
- **Two things this session got wrong, so that the next does not:** times written from memory ran up to ten minutes ahead of the clock (take them from `date` at the moment of writing); an inline script edited the board's row and scrambled it, with a control byte (the row and anything with a backslash go through files made by the Write tool).
- **NEXT STEP, in one line:** merge whatever is listed next; when the owner has started the folder again, read what they say first, for every track.
- **ADDED 19:34: THE OWNER, 19:31: "I'll start a new integrator session. I have no issue using up the usage, but the objective should be to actually deliver something, meaning the features that work with the much improved look."** My reading, on the board (message 155) and by one message to each of the five sessions: what is left of the usage (85% of all models' week at 19:27, 11 points an hour: about an hour) goes to the app as ONE window in the new look with the working features reachable in it; pages (P6) and the viewer (B7) are that delivery, in the order of 155 a (the first start's faults; the shell with the list; the Overview's links); the mirror, copies and Core finish what is in flight to its listing and start nothing new. **For the new integrator: merge pages' and the viewer's listings FIRST and at once (each is something the owner can open); rebuild the owner's folder after each; and before telling the owner a piece is ready, make sure someone has opened it as the owner does, on an empty catalogue and on a filled one. When the usage ends, everything stops where it is: the next thing the owner should be handed is one sentence on what to open and what works in it.** Until the new integrator writes on the board's row, I merge. (the first real sign-in from a page; the first real start by the launcher), `FEATURES.md` (the owner's words of 17:58 on the cap and of 18:13 on the app).
- 14:16: **K14 AND K16 ARE ON THE MAIN BRANCH: HEAD e9b8c54, pushed, equal to `private`, clean, nothing staged (14:15). K16 is 3eb9b11, K14 is e9b8c54: SCHEMA STEP 25. THE COLLECTOR IS INSTALLED FROM e9b8c54 (14:15; 2b55760's kept as a `.bak`). THE OWNER'S FOLDER IS REBUILT FROM e9b8c54 (14:16; no program ran from it; ffmpeg and mpv still in its `tools`). MY COPY `wt-int-b2` AND ITS BRANCH ARE REMOVED. THIS SESSION HAS STOPPED MERGING: the integrator of 14:03 holds the row and everything from here is its.** The runs on the joined tree (tree of `archiver/internal` e0447b90, the tree now on the main head): whole catalog 521.7 s, server 159.8 s, mirror 178.0 s, supply 156.2 s, telegram 43.2 s, tgstore, bringin, probejudge, pairwords, partsledger, livepages, actdoor: ok; the whole collector ok, 1,670.6 s, in its second run with a 45-minute limit (the first was cut off at 20 minutes with no test failed); the viewer's wall and schema tests, vet, gofmt, the commands: ok. K14's review copied (0 paths); the roadmap's acting row and the handoff's schema lines went in with K14's commit (step 25 on the head; 26 claimed by the mirror's M6; next free 27). The queue's entries K14 and K16 are marked MERGED and the board's "Waiting to merge" list has the line; the board's row is the new integrator's to write. **Merged by this session: 17 (G7, K9c, K13, K15, entry 22, G9, G8, G10, G13, entries 23 and 24, G11, C12, C13, M10, K16, K14). For the next merges: `merge-as-tested.sh`'s own limit for a whole package is 30 minutes: the whole collector took 27.8 minutes here; raise it to 45 before the next whole collector run through that script. Viewer (B6): K14 is on the head: the pass-through's wiring can start. Nothing of mine is staged or running.**

## THE INTEGRATOR SESSION OF 11-16 19:33 (session I-5; entries marked "(I-5)")
- 19:39 (I-5): **started 19:33 by the owner with `START-INTEGRATOR.md`; I HOLD THE BOARD'S ROW FROM 19:36** (written whole from `runs-int-i5/row-now.txt` by `runs-int-i5/rewrite-row.py`: change the row only that way; the row's own "19:38" is two minutes ahead of the clock). Read: the start file whole; `CLAUDE.md`'s archiver section; of the board, every track's row whole, messages 155 and 171, the newest lines of "Waiting to merge", item 41; I-4's take-over block of 19:29 and its addition of 19:34; the end of `MERGE-QUEUE.md`. **Not read whole: the board's older messages (227 KB) and the queue's older entries: usage decides (below).** One message to `archiver-integrator-4` was tried and not delivered (the session is idle and not reachable by name): the row says that it merges nothing more; I do not wake it.
- 19:39 (I-5): **THE START REVIEW, every track against the disk (19:35; `runs-int-i5/disk-review.sh`, read-only, one call, by a script):** main head f1d7127b, equal to `private`, 0 changed, 0 staged. 18 copies. Every `wip` branch equal to `private` except: `wip/pages-quit` (7 commits ahead, 1 file changed: G18's fix round with its coder), `wip/core-giveback` (4 ahead: K17, the head merged in, its full runs going), and `wt-mirror-capmax` (47 files changed, 46 staged, nothing committed: M13's round onto M6 under way). Per track: **pages (P6)**: on the head up to G15; G17 reviewed (`wip/pages-empty` 4bc6a229), G18 in its fix round, G19 in review (`wip/pages-folders` a281c273), G16 handed back and unread (`wip/pages-cap` e0fe666c), W1 the shell with a coder (`wip/pages-shell` 06b5e892, cut from the head). **The viewer (B7)**: entry 26 on the head; S1 in its look (`wip/b-saved` 076eeab7), W2 in its security review (`wip/b-onewin` 3c504d2c), the list with a coder (`wip/b-shell` d7e9391b, on the head), the removed edge in its runs (`wip/b-edgegone` 3c6ba693). **Copies (C6)**: C22's review back, its fix round briefed (`wip/copies-27` 7c5161e2). **The mirror (M-6)**: M6's re-listing runs go since 19:12 (`wip/mirror-adopt` 16589fcb; the whole collector), M13 after it. **Core (K-5)**: K17 in its full runs (3215cf4a), K19 in its review (`wip/core-guard` 6d2b9a03). **Nothing is listed and unmerged. Every track committed its notes between 19:30 and 19:35 and its row names a script or a Sonnet clerk for routine steps. No wait that cannot end. Every track has a session; four of the five rows say the session's context is long or a take-over block is ready.**
- 19:39 (I-5): **THE PC, 19:35: 97% CPU, 5,414 MB free, 2 containers** (a second sample 19:36: the virus scanner, one whole `catalog` test run, two browser test processes, the containers' machine). Said on my row: no track starts another whole run or race run until one of its own has ended; pages' and the viewer's go first.
- 19:39 (I-5): **USAGE 19:34: 86% of all models' week, 44% of this model's; the reset is 4 days 19 hours away. This session's context: 10%.** The order is the owner's of 19:31 (message 155): pages' and the viewer's listings merged first and at once, the folder rebuilt after each; when the usage ends, the owner gets one sentence on what to open and what works in it. **Waiting for the owner: item 41 (the account's own chat on a new archive: read by itself, or offered first with its cost; Core recommends offered).**
- **NEXT STEP, in one line:** a background watch on `MERGE-QUEUE.md` ends at the next listing; merge it with `ix-tools/merge-as-tested.sh`, rebuild the folder with `runs-int-i4/folder.sh`.
- 19:41 (I-5): **THE OWNER DECIDED ITEM 41 (19:39; asked once, then again at the owner's word with both ways explained and their cost): "By itself": on a new archive the app reads the account's own chat (Saved Messages) without a choice.** Against Core's recommendation, with the cost said (history requests not approved one by one, about 1 per 100 messages). On the board: item 41 struck with the decision; message 173 to Core, the viewer and pages (Core builds it as its next piece ahead of K18 and K19's fix round, one coder when one of its runs has ended, an independent review before its full runs; what it covers is the read of that one chat only: its files follow the download choice, no other chat is read unasked, nothing runs against Telegram before the owner starts the program; the viewer and pages build no offer for this chat and do not wait for Core). One short message woke Core (K-5, idle) to read 173. Both edits by one script (`runs-int-i5/post-41.py`: 0 control bytes). **OWED BY ME: the owner's word into `FEATURES.md` section 12 with the next documents commit.** (The entries above marked 19:39 were written at 19:37 by the clock.)
- **NEXT STEP, in one line (unchanged):** the background watch on `MERGE-QUEUE.md` ends at the next listing; merge it with `ix-tools/merge-as-tested.sh`, rebuild the folder with `runs-int-i4/folder.sh`.
- 19:42 (I-5): **G17 (`wip/pages-empty` 4bc6a229, listed 19:41 by pages; cut from 78739d59) IS STAGED ON THE MAIN TREE AND IN ITS MERGE RUN since 19:42, NOT COMMITTED** (one background command, `runs-int-i5/merge-g17.sh`: `ix-tools/merge-as-tested.sh` with the browser test switched on, then `runs-int-i4/folder.sh`; its lines in `runs-int-i5/merge-g17.out`, logs in `runs-int-i5-g17`). Read by me first: the entry whole and the four Go files' difference (nil lists made empty lists at their source: the queue's servers, the snapshot's accounts and lanes, the Overview's groups, the hourly figures); the page scripts not read line by line (the reviewer's 78 pairs of loads on filled pages are the same as the base's). The run plan, said to the owner: the head changed `internal/server` since the piece's base (G15), so the whole `internal/server` runs once on the merged tree, with the browser test on (about 7 to 10 minutes); no race detector (nothing concurrent changed); the collector put in place (its pages changed), the folder rebuilt. If this session stops here: `git -C repo-archiver status` shows the staged piece; read the last line of `merge-g17.out`.
- 19:51 (I-5): **G17 IS MERGED AND PUSHED BY THE SCRIPT (19:42:40 to 19:50:33): e78ef36** (17 files staged, no conflict; whole `internal/server` on the merged tree ok, 415.9 s: the browser test ran, by its time (the branch's own run with it on took 428.5 s; the package without it about 160 s; the log is not verbose and names no test); build, vet, gofmt, the commands ok; the review copied, 0 paths; pushed, equal to `private`, the tree clean). **THE COLLECTOR IS IN PLACE FROM e78ef36 (19:50; 4ce8eec's kept as a .bak). THE OWNER'S FOLDER IS REBUILT FROM e78ef36 (19:51; 0 programs ran from it; 6 programs, settings, data and tools untouched).** The queue's entry and the board's line say MERGED (`runs-int-i5/finish-g17.py`); my row is rewritten (head e78ef36; pages' G16, G18, G19, W1 take it in; item 41's decision; pages asked for one look at this build as the owner opens it and one line on what works, before the owner is told anything is ready). Routine steps: by scripts, one background command. **Merged by this session: 1. Nothing of mine is staged or running but the watch for the next listing.**
- 20:15 (I-5): **THE OWNER, 20:11: "I can see the app is testing the 'archive viewer', but it looks to be the older version? Not the new one we approved?" and 20:13: "It's whatever just opened now".** Found by the running programs (flags and folder words only, `runs-int-i5/who-window.ps1`): the viewer session's (B8) look of the one window on invented data from `runs-b8/look`, started 20:10:13 and again 20:13:06; its start line gives the app's pages as the first address, and those are in the old look. Told to the owner, with the track's picture of the new look on the viewer's side (invented data). **Board message 177 to the viewer and pages: the one window opens on the viewer's page first (`-first viewer`) until pages' shell is on the head; a row line before a test window comes up on the owner's screen.**
- 20:15 (I-5): **ENTRY 28 (`wip/b-saved` fb09df28, listed 20:02 by B7: the viewer calls the account's own chat "Saved Messages") IS MERGED AND PUSHED BY THE SCRIPT (20:13:17 to 20:14:04): 49c310a** (read by me first: the entry whole and `chats.go`'s rule, title function and order; the base is f1d7127 and the head since changed only `internal/server`, which the viewer does not import: the viewer's tree equal to the branch's, so no whole run of mine; `TestSaved|TestWall|TestPageScripts` by name ok, 10.0 s; build, gofmt, the commands ok; the review copied, 0 paths). No collector change. **THE OWNER'S FOLDER IS REBUILT FROM 49c310a (20:14; 0 programs ran from it).** **My watch missed this listing for ten minutes** (it counted lines with the listing words, and marking G17 merged took one away as entry 28 added one): the watch now looks for an unmerged entry's own first line. The queue's entry, the board's line and my row: done by `runs-int-i5/finish-28.py` and `rewrite-row.py`. Routine steps: by scripts, one background command. **Merged by this session: 2. Nothing of mine is staged or running but the watch.**
- 20:26 (I-5): **ENTRY 29 (`wip/b-shell` 73315e27, listed 20:23 by B8: THE APP'S ONE WINDOW AND THE LIST ON THE LEFT IN THE NEW LOOK, the viewer's side of the delivery) IS MERGED AND PUSHED BY THE SCRIPT (20:24:31 to 20:25:20): e9413e4** (read by me first: the entry whole; `internal/window/joined.go` whole (the gate's set, the navigation rule, the new-window rule with the viewer's first page exactly, the rule for the window's messages to the page, the download rule) and `internal/viewer/appurl.go` whole: right as written; the page code and the Windows side not read by me. The branch holds the head: the three trees equal to the branch's; the whole `internal/window` ok 5.6 s; the viewer's six named tests ok 9.0 s; build, vet, gofmt, the commands ok; two reviews copied, 0 paths; the roadmap's row for the one window edited by me and in the commit). No collector change. **THE OWNER'S FOLDER IS REBUILT FROM e9413e4 (20:25; 0 programs ran from it). NOTHING IN IT STARTS THE ONE WINDOW YET.** Board message 181 (20:25) and one short message to B8: my word for the start script for the owner's folder, tried on a copy as the owner runs it before I put it into the folder; pages' row is of 19:56 and its answer on the launcher's start is open. The queue's entry, the board's line, my row: by `runs-int-i5/finish-29.py` and `rewrite-row.py`. Routine steps: by scripts, one background command. **Merged by this session: 3 (G17, entries 28 and 29). Listed and unmerged: K17 (Core). Nothing of mine is staged or running.** (My watch looks for "LISTED, READY" and missed K17's "READY": the next watch takes both.)
- 20:29 (I-5): **THE VIEWER'S 182 (20:28): NO START SCRIPT** (a script cannot start what the launcher starts without being the launcher: the home address asked and given to the collector as its forbidden address, the folder's marks, the watchdog; B8 will not hand the owner that rule rewritten in a hurry: agreed by me). **What the owner can open tonight (182 c, checked by B8 on the listed head on an invented archive): the folder's program as before; the viewer's window has the list on the left in the new look; the app's pages are a second window in the old look.** Told to the owner in those words, with what was not checked (the folder's own start of both windows; Saved Messages filled). **MY WORD (board message 183, and one short message to B8): the launcher's three places that make it ONE window (182 b) are made by the viewer (B8) as a lent commit on e9413e4** (`internal/launcher` only; one small Opus round, one narrow independent look, the launcher's package whole, a look on a COPY of the folder started by the folder's own program; entry 30; pages has five minutes to say it does it itself, and reads it when it takes the head in: it meets G18 in two files). B8 also rebuilds its track's `bin` from the head. **K17 (Core, listed 20:20) and entry 27 wait behind the delivery: usage was 91% of all models' week at 20:26.** My row: rewritten. Routine steps: by scripts.
- 20:44 (I-5): **PAGES' 184 (20:35): pages had not read the board from 19:56 to 20:34 (its own lock script held its coders); it agreed to the viewer's lent launcher commit; G18 is listed after that commit is on the head.** **THE VIEWER'S ENTRY 27 (the removed edge, `wip/b-edgegone` bbb8afba, listed 20:39) AND CORE'S K17 (listed 20:20) ARE HELD BY ME BEHIND THE DELIVERY** (27 holds 49c310a and entry 29 changed the viewer since: the whole viewer once on the combined tree; K17: the whole catalogue and the whole collector; the main tree is kept free for the delivery's pieces; usage 91% at 20:26).
- 20:44 (I-5): **W1 (`wip/pages-shell` 9d685be1, listed 20:42 by pages: THE APP'S OWN PAGES IN THE NEW LOOK, the new package `internal/appshell`) IS MERGED AND PUSHED BY THE SCRIPT (20:43:18 to 20:43:54): aa69cd8** (read by me first: the entry whole; listed with NO independent review, said plainly by pages and owed first; so my own checks: no HTML sink in `shell.js` or the added lines of `main.js` (searched, and the link targets come from the server's builder), one read statement and no write in `appshell/shell.go` (searched, not read line by line), `server/shell.go` whole. The branch holds the head: both trees equal to the branch's; the whole `internal/appshell` ok 2.4 s; the server's shell and empty-catalogue tests by name ok; build, vet, gofmt, the commands ok; the roadmap's row edited by me and in the commit). **THE COLLECTOR IS IN PLACE FROM aa69cd8 (20:43; e78ef36's kept). THE OWNER'S FOLDER IS REBUILT FROM aa69cd8 (20:44; 0 programs ran from it).** The queue's entry, the board's line, my row: by `runs-int-i5/finish-w1.py` and `rewrite-row.py`. Routine steps: by scripts, one background command. **Merged by this session: 4 (G17, entries 28 and 29, W1). Coming for the delivery: the viewer's lent launcher commit (entry 30), then pages' G18. Nothing of mine is staged or running.**

## STATE FOR A TAKE-OVER (the integrator session of 11-16 19:33, I-5; written 21:05 at 95% of all models' week; kept current below)
A new integrator is started by the owner with "Read `START-INTEGRATOR.md` and do what it says". It reads my board row first (written whole from `runs-int-i5/row-now.txt` by `runs-int-i5/rewrite-row.py`: change the row only that way).
- **`repo-archiver`: main head aa69cd8, equal to `private`, clean, nothing staged; no copy of mine exists; nothing of mine runs** but one background watch for entry 30 (it ends by itself).
- **In place: the collector is the build of aa69cd8 (20:43; e78ef36's kept); the watchdog 8aed433's. The owner's folder is rebuilt from aa69cd8 (20:44; its settings, data and tools untouched; its catalogue is the new one with the test account signed in, nothing chosen).** Schema: 26 on the head; next free 27 (the first of C22 and the mirror's M6 to be merged takes it).
- **Merged by this session (4, in order):** G17 (e78ef36: the app's pages on a new, empty catalogue), the viewer's entry 28 (49c310a: Saved Messages by name), entry 29 (e9413e4: the one window's joined mode and the viewer's list in the new look), W1 (aa69cd8: the app's own pages in the new look, `internal/appshell`; NO independent review: pages owes it first). Commit messages: `runs-int-i5/msg-*.txt`; each merge's lines: `runs-int-i5/merge-*.out`.
- **THE DELIVERY, where it stands:** the owner's folder opens TWO windows, both in the new look (the viewer's with its list, the pages' with the shell's list). **Nobody has started the folder's own program on this build; the owner has been told so.** ONE window from the folder is the viewer's lent launcher commit (`wip/b-launch`, B8, at my word, board message 183; pages agreed in 184): its look on a copy of the folder ran about 20:48; it comes as ENTRY 30: merge it at once (`internal/launcher` only; read what the launcher gives the collector and starts; the launcher's package whole; no collector change; rebuild the folder), then tell the owner the one sentence: what to open and what works. After it: pages' G18 (Quit and the window's end; it takes the head in first).
- **LISTED, PUSHED, NOT MERGED AND NOT READ BY ME (held behind the delivery, then the usage ended), in this order:** K17 (Core, `wip/core-giveback` 3215cf4a, holds 4ce8eec: the whole catalogue and the whole collector once on the combined tree; two timing tests of the catalogue fail on a busy PC and are not the piece's); the viewer's entry 27 (`wip/b-edgegone` bbb8afba, holds 49c310a: the whole viewer once on the combined tree; the viewer's change-log tests by name); C22 (copies, `wip/copies-27` 964397c4, holds aa69cd8: a schema step; its numbers are set at the merge; every package that opens a catalogue whole, once).
- **THE OWNER TODAY (to this session):** 19:39 item 41: "By itself" (the account's own chat is read on a new archive without a choice; Core's K21, with a coder since 20:19; board message 173). 20:11 and 20:13: took the viewer's test window for the old version (it opened on the old-look pages): board message 177 (the one window opens on the viewer's page first; a row line before a test window comes up). **OWED BY ME AND NOT DONE: these words into `FEATURES.md` section 12 (an eighteenth round) and the handoff's block rewritten for the four merges: a documents commit.**
- **Sessions:** pages P6, the viewer B8 (since 20:03), Core K-5, copies C6, the mirror M-6. Retired: `archiver-integrator-4`, B7.
- **How I merged:** the start file's way; one wrapper script a piece (`runs-int-i5/merge-*.sh`: `ix-tools/merge-as-tested.sh`, then `runs-int-i4/folder.sh`) as one background command; then one script for the queue's entry, the board's line and the row (`runs-int-i5/finish-*.py`). The server's browser test runs only with `TGARCHIVE_BROWSER` set (see `merge-g17.sh`).
- **Two things this session got wrong, so that the next does not:** a watch that counted lines with the listing words missed a listing for ten minutes when a merge took one such line away as a new one came (look for an unmerged entry's own first line, and for "READY" as well as "LISTED, READY"); times written into messages from an estimate ran one to three minutes ahead of the clock (take them from `date` in the script that writes them).
- **NEXT STEP, in one line:** merge entry 30 when it is listed, rebuild the folder, tell the owner what to open; after the reset: K17, entry 27, C22, the documents commit.
- 21:18 (I-5): **ENTRY 30 (`wip/b-launch` 3b77f5ea, listed 21:13 by B8: THE LAUNCHER STARTS THE APP AS ONE WINDOW; a lent commit in pages' `internal/launcher`) IS MERGED AND PUSHED: 9980a21 (21:15); THE OWNER'S FOLDER IS REBUILT FROM IT (21:16; 0 programs ran from it). No collector change (the build of aa69cd8 stays in place).** Read by me first: the entry whole; the difference of `start.go`, `present.go`, `launcher.go`, `words.go` whole (one decision a start; the collector's line gains only `-viewer-url` with the viewer's loopback address, its VPN adapter and forbidden-address flags untouched; no separate viewer when joined; the joined window's line). The branch was cut from e9413e4 and the head since changed neither of its packages: both trees equal to the branch's. **THE MERGE SCRIPT STOPPED AT THE WHOLE LAUNCHER (21:13:08 to 21:14:52): ONE TEST FAILED, `TestLauncherStyleMatchesAppTokens`, AND IT IS THE HEAD'S OWN, NOT THE PIECE'S: read to its cause.** The test compares the launcher's page colours and font with the app's pages' `base.css`; W1 (aa69cd8, merged by me at 20:43) changed `base.css` and not the launcher's page; entry 30 touches neither file nor the test; the branch's own whole run passed on a base before W1. My merge of W1 ran the shell package and the server's named tests, not the launcher's: **a merge that changes `internal/server/web/assets/base.css` runs that launcher test by name** (for the start file's "Learnt" block). Every other launcher test passed (the log holds exactly one failed test; 101.3 s). **My decision: merged** (the piece is the delivery; the failing test is a guard on colours and its cause is known): the remaining steps by `runs-int-i5/finish-merge-30.sh`, which checks first that the log holds exactly that one failed test and that the staged launcher tree is the branch's; build, vet, gofmt, the commands ok; the review copied, 0 paths; the roadmap's row edited by me; the commit message says the failing test and whose it is. **Pages owes: the launcher's page brought to the new tokens (the test passes again), W1's independent review, G18 on this head.** The queue's entry, the board's line, message to pages, my row: `runs-int-i5/finish-30.py`, `post-msg.py`, `rewrite-row.py`. Routine steps: by scripts. **Merged by this session: 5 (G17, entries 28, 29, 30, W1). THE OWNER IS TOLD (21:17): the folder's program opens ONE window in the new look; what nobody has seen (the folder's own start with the real collector; the one window with the pages' new shell; the setup then "Save and start"); what is known and left.** The take-over block above (21:05) holds but for: the head is 9980a21; entry 30 is merged; one test fails on the head (above).
- 21:27 (I-5): **THE OWNER, 21:18: "Merge the fixes. These are basic, and if ready should go. Especially stuff like G18. Need a way to quit the app..."** So the hold of 21:05 is off: I merge what is listed and ready, G18 first the minute it is listed (one message to pages at 21:19: G18 first and now, on the head, `-tell-close` into the joined line; G19 after). Usage 21:18: 95% of all models' week, 56% of this model's.
- 21:27 (I-5): **ENTRY 27 (`wip/b-edgegone` bbb8afba, listed 20:39: the viewer takes a removed look-alike edge in place) IS MERGED AND PUSHED BY THE SCRIPT (21:19:24 to 21:26:36): c866927** (read by me: the entry whole; its 8 files share none with what the head changed in the viewer since its base, a trial merge clean; the update path's 441 changed lines NOT read by me: the independent review with probes and the branch's clean race run of 3,884 s stand for them. The whole `internal/viewer` on the merged tree ok 400.0 s; build, vet, gofmt, the commands ok; the review copied, 0 paths). **THE OWNER'S FOLDER IS REBUILT FROM c866927 (21:26; 0 programs ran from it).** **K17 (Core, `wip/core-giveback` 3215cf4a): read by me whole (`state.go`, `settle.go`: one read before every give-back, the plain give-back, then the settle's own four statements on that one file; it only ever holds, never wants more; the open hole written down); ITS RUNS GO IN MY COPY `wt-int-k17` (branch `int/k17`, 9980a21 with K17's difference, tentative commit 3834614a, never pushed; the catalogue's tree equal to the branch's) since 21:20: the whole catalogue, then the whole collector (`runs-int-i5/k17-tree.sh`, lines in `runs-int-i5/k17-tree.out`, logs in `runs-int-i5-k17`). When they end ok: `merge-as-tested.sh` with base 4ce8eec, head 3215cf4a, the catalogue's tree compared, the viewer's change-log tests by name, the review `REVIEW-K17-giveback.md`, install yes; then remove the copy and its branch.** The queue's entry, the board's line, my row: `runs-int-i5/finish-27.py`. Routine steps: by scripts. **Merged by this session: 6.**
- 21:42 (I-5): **G18 (`wip/pages-quit` 72bf7ff9, listed 21:33 by pages at the owner's word: A WAY TO QUIT THE APP) IS MERGED AND PUSHED: 18c1e2c (21:41); THE COLLECTOR IS IN PLACE FROM IT (aa69cd8's kept); THE OWNER'S FOLDER IS REBUILT FROM IT (21:41; 0 programs ran from it).** Read by me first: the entry whole and `closeask.go` whole (the box is the launcher's own program as a helper in a job of its own; "Quit the app" goes through the same channel as the pages' Quit; an answer after the run it asked about is not taken); the rest of its 2,601 lines not read by me. Only its first round had an independent review (3 must fix, fixed in the second with named tests); the second and third rounds had none: said in the commit message and to the owner. The branch holds 9980a21 and the head since changed only the viewer: the four trees equal to the branch's. **THE MERGE SCRIPT STOPPED AT THE WHOLE SERVER (21:34:23 to 21:40:05, beside K17's whole collector run): ONE test failed, `TestChatsAskAgainOnKey` (the statements counted while the Chats page's key is asked: 5, where the key alone makes 4; 0.03 s). Read to its cause as far as the usage allowed: G18's server lines are the Settings row and the viewer address's cleaning, nothing on that path; by name on the same staged tree it passed ten times of ten (1.9 s). Taken as the test's own count of a statement made beside it; merged by `runs-int-i5/finish-merge-g18.sh`** (it checks first that the log holds exactly that one failed test, that the four staged trees are the branch's and that the test passes ten times by name; then build, vet, gofmt, the commands, the review's copy, commit, push, the collector, the folder). Pages is told on my row to make that test count its own statements. The launcher's style test passes again (mended in G18). The queue's entry, the board's line, my row: `runs-int-i5/finish-g18.py`. Routine steps: by scripts. **Merged by this session: 7 (G17, entries 28, 29, 30, 27, W1, G18). K17's whole collector run still goes in `wt-int-k17` (its whole catalogue: ok, 518.7 s).**
- 22:02 (I-5): **K17 (`wip/core-giveback` 3215cf4a, listed 20:20 by Core) IS MERGED AND PUSHED BY THE SCRIPT (21:58:03 to 22:00:34): 91f1fb1; THE COLLECTOR IS IN PLACE FROM IT (18c1e2c's kept); THE OWNER'S FOLDER IS REBUILT FROM IT (22:00; 0 programs ran from it); MY COPY `wt-int-k17` AND ITS BRANCH ARE REMOVED.** Its whole runs, once, on a combined tree in that copy (9980a21 with K17's own difference; 21:20 to 21:57): the whole `internal/catalog` ok 518.7 s, the whole `internal/collector` ok 1,708.9 s, no failed test (the two real-time bounds passed). The head moved after that tree only in the viewer (entry 27), the launcher and the server's Settings row (G18): none of them is the catalogue, the collector, the supply or the engine, so no second whole run. At the merge: the catalogue's tree equal to the branch's; the viewer's `TestLost|TestStaged|TestIncremental|TestRandomUpdates|TestChanges|TestWall|TestEdgeGone` by name ok 112.7 s; build, vet, gofmt, the commands ok; the review copied, 0 paths. Read by me: the entry whole; `state.go` and `settle.go`'s difference whole. The queue's entry, the board's line, my row: `runs-int-i5/finish-k17.py`. Routine steps: by scripts. **USAGE 22:01: 97% of all models' week, 57% of this model's; this session's context 40%.**

## STATE FOR A TAKE-OVER (the integrator session of 11-16 19:33, I-5; written 22:02 at 97% of all models' week; this block replaces the one of 21:05)
A new integrator is started by the owner with "Read `START-INTEGRATOR.md` and do what it says". It reads my board row first (written whole from `runs-int-i5/row-now.txt` by `runs-int-i5/rewrite-row.py`: change the row only that way).
- **`repo-archiver`: main head 91f1fb1, equal to `private`, clean, nothing staged; no copy of mine exists; nothing of mine runs** but, at most, one background watch for the next listing (it ends by itself).
- **In place: the collector is the build of 91f1fb1 (22:00; 18c1e2c's kept); the watchdog 8aed433's. The owner's folder (`tgarchive-app` in the owner's profile folder) is rebuilt from 91f1fb1 (22:00; its settings, data and tools untouched; its catalogue is the new one with the test account signed in, nothing chosen).** Schema: 26 on the head; next free 27 (the first of C22 and the mirror's M6 to be merged takes it).
- **Merged by this session (8, in order):** G17 (e78ef36: the app's pages on a new, empty catalogue), the viewer's entry 28 (49c310a: Saved Messages by name), entry 29 (e9413e4: the one window's joined mode and the viewer's list in the new look), W1 (aa69cd8: the app's own pages in the new look, `internal/appshell`), entry 30 (9980a21: the launcher starts the app as ONE window), entry 27 (c866927: the viewer takes a removed edge in place), G18 (18c1e2c: a way to quit: the close box, the window's ends, the launcher's page in the new colours), K17 (91f1fb1: a file given back from a transfer is judged). Commit messages: `runs-int-i5/msg-*.txt`; each merge's lines: `runs-int-i5/merge-*.out` and `finish-merge-*.out`.
- **THE DELIVERY, where it stands: the owner's folder's program opens ONE window on the viewer's page with the list on the left in the new look; "Overview" leads to the app's pages in their new shell; closing the window asks "Keep it running" / "Quit the app". THE OWNER HAS BEEN TOLD (21:17, 21:43) AND HAS NOT SAID WHAT THEY SAW. Nobody has seen: the folder's own program starting the real collector and the window together; the close box at a real close; the setup page then "Save and start". When the owner says what they saw, that comes before everything else, for every track.**
- **REVIEWS OWED (merged without, at the owner's word to deliver and to merge the fixes):** W1 has no independent review; G18's second and third rounds have none; entry 30's fix round and entry 28's were read by their session only. Pages owes W1's and G18's.
- **TWO TESTS TO KNOW:** the server's `TestChatsAskAgainOnKey` failed once in my whole server run beside a whole collector run and passed ten times of ten by name (it counts a statement made beside it: pages'); a merge that changes `internal/server/web/assets/base.css` runs the launcher's `TestLauncherStyleMatchesAppTokens` by name (W1's merge broke it for 58 minutes; mended in G18).
- **LISTED AND NOT MERGED: C22** (copies, `wip/copies-27` 964397c4, holds aa69cd8: a schema step and a feature, off by default; NOT read by me). It meets K17 in `internal/catalog` (other files): every package that opens a catalogue whole, once, on the combined tree (copies is asked on my row to take the head in and run the catalogue and the collector whole, so that the merge is as tested); its two step constants are set at the merge. **Coming:** pages' G19 (changing the folders), G16 (the mirror cap's row); the mirror's M6 and M13; Core's K21 (the owner's "By itself" for the account's own chat) and K19; the two lists made one.
- **THE OWNER TODAY (to this session):** 19:39 item 41: "By itself"; 20:11 and 20:13: took a test window for the old version (board message 177); 21:18: "Merge the fixes. These are basic, and if ready should go. Especially stuff like G18. Need a way to quit the app...". **OWED BY ME AND NOT DONE: these words into `FEATURES.md` section 12 (an eighteenth round); the handoff's block rewritten for the eight merges; the three lessons below into the start file's "Learnt" block: one documents commit.**
- **Lessons for the start file (not written there yet):** (1) a watch for listings looks for an unmerged entry's own first line, with "READY" as well as "LISTED, READY", never for a count of lines; (2) a long run that would hold the main tree goes in a copy (`runs-int-i5/k17-tree.sh` is the pattern: a worktree at the head, the piece's difference, a tentative commit, `full-runs.sh`), and the merge script is then given the catalogue's tree to compare; (3) when the merge script stops on ONE failed test that reading shows is not the piece's, the remaining steps are one script that first checks the log holds exactly that test and the staged trees are the branch's (`runs-int-i5/finish-merge-30.sh`, `finish-merge-g18.sh`); (4) times in messages and entries from `date` in the script that writes them.
- **Sessions:** pages P6, the viewer B8, Core K-5, copies C6, the mirror M-6. Retired: `archiver-integrator-4`, B7.
- **NEXT STEP, in one line:** hear what the owner saw at the first start of the one window; merge G19 when it is listed; after the reset: C22 on a combined tree, the documents commit.
- 22:08 (I-5), AFTER THE TAKE-OVER BLOCK OF 22:02: **K19 (Core, `wip/core-guard` 2f45d61a, listed 22:07, holding aa69cd8: a panic inside the database driver ends the program; a new package `internal/sqlguard`, the catalogue's three opens name it) IS IN ITS WHOLE RUNS ON A COMBINED TREE IN MY COPY `wt-int-k19` (branch `int/k19`: 91f1fb1 with K19's difference, a tentative commit, never pushed) since 22:08: the whole `sqlguard`, `catalog`, `watchdog`, `collector`, about 40 minutes (`runs-int-i5/k19-tree.sh`; lines in `runs-int-i5/k19-tree.out`, logs in `runs-int-i5-k19`). THE MAIN TREE IS NOT TOUCHED: nothing is staged.** Needed because K17 changed `internal/catalog` after K19's base. Read by me: the entry whole; the guard's code NOT yet. If this session ends here: read `k19-tree.out`; with every line "exit 0": read `internal/sqlguard/sqlguard.go`'s end path, then `ix-tools/merge-as-tested.sh` with base aa69cd8, head 2f45d61a, trees "internal/sqlguard", named "viewer:TestWall", the review `REVIEW-K19-guard.md`, install yes; the roadmap's operations row gains its sentence; then remove the copy and its branch (`git worktree remove --force`, `git branch -D int/k19`). **ALSO FROM CORE'S ENTRY, NOT MINE TO LEAVE UNSAID: `internal/fabricate`'s `TestGenerateDeterministic` FAILS ON THE MAIN HEAD ALONE ("2nd ORDER BY term out of range"; seen by Core's clerk on a clean copy at 18c1e2c): no merge script of mine runs that package; whose merge brought it is not known: the next integrator finds it with `git bisect` over today's merges and gives it to its track.** Usage 22:01: 97%.
- 22:48 (I-5): **K19 (`wip/core-guard` 2f45d61a, listed 22:07 by Core) IS MERGED AND PUSHED BY THE SCRIPT (22:46:10 to 22:46:52): 3cfea81; THE COLLECTOR IS IN PLACE FROM IT (91f1fb1's kept); THE OWNER'S FOLDER IS REBUILT FROM IT (22:47; 0 programs ran from it); MY COPY `wt-int-k19` AND ITS BRANCH ARE REMOVED.** Its whole runs, once, on a combined tree in that copy (91f1fb1 with K19's difference; 22:08 to 22:45): the whole `sqlguard` ok 4.9 s, `catalog` ok 476.5 s, `watchdog` ok 14.9 s, `collector` ok 1,678.2 s, no failed test. The head had not moved: the merged `internal` tree is equal to that combined tree (checked by the script). At the merge: the guard package again, the viewer's wall test by name, build, vet, gofmt, the commands ok; the review copied, 0 paths; the roadmap's crash-log row edited by me. Read by me: the entry whole; `sqlguard.go`'s end path (the report holds the value's type, its text only for the runtime's own errors, the stack with argument lists elided; the write waited for at most 5 s; exit 2); the 29 wrapper methods not read (the reviewer's 8,260 steps stand for them). The queue's entry, the board's line, my row: `runs-int-i5/finish-k19.py`. Routine steps: by scripts. **Merged by this session: 9. Usage 22:47: 97% of all models' week, 58% of this model's.**
- 22:48 (I-5): **G19 (pages, `wip/pages-folders` 32c5d12e, listed 22:08, holding 18c1e2c: "Change the folders" and a setup that says what it sees) IS IN ITS WHOLE RUNS ON A COMBINED TREE IN MY COPY `wt-int-g19` (branch `int/g19`: 3cfea81 with G19's difference, a tentative commit, never pushed) since 22:48: the whole `launcher`, `appshell`, `server` (the browser test on), `collector`; about 45 minutes (`runs-int-i5/g19-tree.sh`; lines in `runs-int-i5/g19-tree.out`, logs in `runs-int-i5-g19`). THE MAIN TREE IS NOT TOUCHED.** Needed: pages did not run the whole server on its listed head; it lends lines to Core's collector (the start flag `-launcher-url`); K17 and K19 changed the catalogue beneath both since its base. Read by me: the entry whole; its code NOT yet (the lent collector lines and the save's second yes before the merge). Its settings file gains two fields: an older build then reads the owner's settings file as unreadable (said to the owner). If this session ends here: read `g19-tree.out`; with every line "exit 0": `ix-tools/merge-as-tested.sh` with base 18c1e2c, head 32c5d12e, trees "internal/launcher internal/server internal/appshell internal/collector", the review `REVIEW-G19-change-folders.md`, install yes; then remove the copy and its branch.
- 23:26 (I-5): **G19 (`wip/pages-folders` 32c5d12e, listed 22:08 by pages: "Change the folders" and a setup that says what it sees) IS MERGED AND PUSHED BY THE SCRIPT (23:24:28 to 23:24:57): 70b0c7e; THE COLLECTOR IS IN PLACE FROM IT (3cfea81's kept); THE OWNER'S FOLDER IS REBUILT FROM IT (23:25; 0 programs ran from it); MY COPY `wt-int-g19` AND ITS BRANCH ARE REMOVED.** Its whole runs, once, on a combined tree in that copy (3cfea81 with G19's difference; 22:48 to 23:23): the whole `launcher` ok 144.8 s, `appshell` ok 2.1 s, `server` with the browser test on ok 294.2 s, `collector` ok 1,677.1 s, no failed test. The head had not moved: the merged `internal` tree is equal to that combined tree; the four trees equal to the branch's; build, vet, gofmt, the commands ok; the review copied, 0 paths. Read by me: the entry whole; the lent collector lines (the flag `-launcher-url`: only with `-pages`, only a loopback address); `yesCovers` (the second yes counts only for what the page showed, or fewer entries); the rest of its 2,400 lines NOT read; its second round had no independent review (said in the commit message and to the owner). The queue's entry, the board's line, my row: `runs-int-i5/finish-g19.py`. Routine steps: by scripts.

## STATE FOR A TAKE-OVER (the integrator session of 11-16 19:33, I-5; written 23:26; THIS BLOCK REPLACES THOSE OF 21:05 AND 22:02, whose lessons and "owed" lists still hold)
- **`repo-archiver`: main head 70b0c7e, equal to `private`, clean, nothing staged; no copy of mine exists (`wt-int-k17`, `wt-int-k19`, `wt-int-g19` removed); nothing of mine runs.**
- **In place: the collector is the build of 70b0c7e (23:24; 3cfea81's kept); the watchdog 8aed433's. The owner's folder is rebuilt from 70b0c7e (23:25; settings, data and tools untouched). Once this build has saved the folder's settings file, an older build reads it as unreadable.** Schema: 26 on the head; next free 27.
- **Merged by this session (10, in order):** G17 (e78ef36), the viewer's entry 28 (49c310a), entry 29 (e9413e4), W1 (aa69cd8), entry 30 (9980a21), entry 27 (c866927), G18 (18c1e2c), K17 (91f1fb1), K19 (3cfea81), G19 (70b0c7e). Every fix the owner asked for at 21:18 is on the head and in the folder.
- **THE DELIVERY: the folder's program opens ONE window in the new look; closing it asks "Keep it running" / "Quit the app"; "Change the folders" is on the launcher's page. THE OWNER HAS NOT SAID WHAT THEY SAW: when they do, that comes before everything else. Nobody has seen the folder's own program start the real collector and the window together, the close box at a real close, or the new setup page.**
- **LISTED AND NOT MERGED, both unread by me:** K21 (Core, `wip/core-self` 0942a7dc, listed 22:50: the account's own chat read by itself, the owner's "By itself" of 19:39; it reads from Telegram for the owner: read its rule yourself, its independent review, the whole collector on the combined tree); C22 (copies, `wip/copies-27` 964397c4: a schema step and a feature, off by default; every package that opens a catalogue whole on the combined tree; step 27 if merged before the mirror's M6).
- **OPEN ON THE HEAD:** `internal/fabricate`'s `TestGenerateDeterministic` fails on the head alone (Core's entry K19; not traced: `git bisect` over today's merges). The server's `TestChatsAskAgainOnKey` failed once beside a whole collector run and passed ten times by name (pages').
- **REVIEWS OWED (merged at the owner's word):** W1 (none); G18's second and third rounds; G19's second round; entry 30's and entry 28's fix rounds were read by their session only.
- **OWED BY ME AND NOT DONE: one documents commit:** the owner's words of the evening into `FEATURES.md` section 12 (19:39 "By itself"; 20:11 the test window taken for the old version; 21:18 "Merge the fixes..."); the handoff's block rewritten for the ten merges; the lessons of the block of 22:02 into the start file's "Learnt" block.
- **Usage 22:47: 97% of all models' week, 58% of this model's; the reset is 11-21, about 15:00.**
- **NEXT STEP, in one line:** hear what the owner saw; then K21 and C22 as above, the fabricate test traced, the documents commit.
- 23:29 (I-5): **THE DOCUMENTS OWED ARE DONE (the owner, 23:30: "Anything you can spend 2% usage on? for example, the owed by you stuff"): one documents commit on the main branch, pushed (its hash: the main head now; no code): `FEATURES.md` section 12, eighteenth round (the owner's words of 19:31, 19:39, 20:11, 21:18 and the NAS question of 23:30 with my answer); `HANDOFF.md` 0c: a dated state ABOVE the block (an addition, not the rewrite: the fold is owed by the next integrator). `START-INTEGRATOR.md`: the block "Learnt on 11-16 night" (seven points). By one script (`runs-int-i5/docs-commit.py`).** The collector in place and the owner's folder are still 70b0c7e's (no code since). **The owner was told how to start the next integrator, how to open and try the app, and that the library must not be the old app's library on the NAS (a new empty folder there is possible).** The take-over block of 23:26 holds; the main head is the documents commit.
- 23:34 (I-5): **THE OWNER (23:36): (1) "clarify how I use the new viewer for the old archive, and if the new app can interface with it for duplicate detection"; (2) "why do I need to start multiple commands to resume when usage returns? Can't you simplify that? It can certainly spawn the sessions it needs I would think, then detach them".** Done: (2) `START-INTEGRATOR.md` (the first review's point 3 and its last point) and `CLAUDE.md` (the archiver section's point on starting an integrator): the owner pastes ONE line; the integrator starts the building sessions itself in its first turn, each with its track's start line, and detaches them; a memory of it is saved. (1) answered from the roadmap and item 36 of the owner's list (the viewer's window starter in the folder `b` of this project folder, on the catalogue of the bring-in of 11-15; the app's folder has its own catalogue, so today the collector checks nothing against the old archive); the board's newest message asks copies, Core and the viewer what crossing the two takes and where it stands; the next integrator gives it a roadmap row and an owner if it has none. **For the next integrator: start the tracks yourself; read that message's answers first.**
- 23:38 (I-5): **THE OWNER (23:45), A DIRECTION: "The whole point is to have a unified archive, so the new app we're building can run duplicate detection against the archive the old one downloaded to flag new media and the rest. Add that".** Added, by one script (`runs-int-i5/unified.py`) and two edits: the board's Direction (its first line) and message 199 (copies leads, with Core and the viewer and bring-in; the first step is a design note with numbers, `DESIGN-UNIFIED-ARCHIVE.md`, first thing after the usage returns; the copy rules stand); `CLAUDE.md`'s objectives; `FEATURES.md` section 12 (eighteenth round) and a ROADMAP ROW WITH AN OWNER ("ONE UNIFIED ARCHIVE"): one documents commit on the main branch, pushed (the main head now; no code); two memories (one unified archive; one command to resume). **For the next integrator: this is listed and asked for; put it into the board's order when copies' note is in; start copies' successor with it named first.**
- 23:46 (I-5): **CLEANING UP AT THE OWNER'S WORD (23:42: "Anything to clean up with 2% usage?"): THE BOARD AND THE QUEUE ARE CUT (23:45; `ix-tools/trim-board-2.py` and `runs-int-i5/trim-queue.py`): the board's messages up to 172 moved to `BOARD-LOG.md` (144 lines; the board 452,976 bytes to 223,933; 27 messages kept, 173 to 199), the queue's 70 entries marked MERGED at their head moved to the new `MERGE-QUEUE-LOG.md` (the queue 680,543 bytes to 159,456; 36 entries kept: the two listed ones and 34 older ones whose head does not say MERGED: not checked one by one, left), everything unchanged, 0 control bytes. MY ROW IS REWRITTEN SHORT as the state for the next integrator (12.8 KB to about 5).** A first try of the row's rewrite wrote the old text again (my tool call that was to replace the text failed and I ran the script all the same): seen in its own line ("12813 -> 12813") and done again; `BOARD-LOG.md` holds that old state twice. **THE TRACE OF THE FAILING FABRICATE TEST RUNS in a scratch copy `wt-int-bisect` (detached; `runs-int-i5/bisect-fabricate.sh`, its lines in `runs-int-i5/bisect-fabricate.out`; it removes its copy at its end; if it is still there after a stop: `git -C repo-archiver worktree remove --force` on it and `git bisect reset` is not needed, the copy is detached).** Every other track's row is theirs to cut at its take-over.
- 23:47 (I-5): **THE FAILING FABRICATE TEST IS TRACED (23:45:35 to 23:46:29, `git bisect` in a scratch copy, removed): `TestGenerateDeterministic` passes at 788ebf7 (11-16 06:43) and fails from bae71e5 on: C13, the copies track's schema step 24, merged 11-16 12:28 by the integrator of 06:55: a table with one column, and the test sorts every table by its first two.** Not a fault of the app; the test's own statement. Board message 200: copies mends it (a lent line if the package is not theirs); `internal/fabricate` has no owner on the Tracks table that I found: the next integrator gives it one. My row says it; no copy of mine exists; nothing of mine runs. **THIS SESSION ENDS HERE: the state for a take-over is the block of 23:26, the entries after it, and my board row.**
- 23:49 (I-5): **THE OWNER (23:48): "Archive the retired sessions as needed". ARCHIVED BY ME, FIVE: pages P6, the viewer B8, Core K-5, copies C6, the mirror M-6** (each checked first, 23:48: a take-over block or its newest entry at the end of its progress file (pages 21:36, the viewer 21:18, copies 21:02, the mirror's block of section 19, Core's newest entry under K-5 of 22:50); no uncommitted notes; `wip/core-self`, `wip/copies-27`, `wip/mirror-adopt`, `wip/mirror-capmax`, `wip/pages-cap`, `wip/b-shell` equal to `private`; none was running). They were the tracks' current sessions, not sessions retired earlier: taken as retired because the usage is at its end, every state is on disk, and the next integrator starts fresh sessions itself (the owner's word on one command). Archiving can be undone from the app's Archived list. **NOT ARCHIVED: the session "start the tenth session" of 11-15 ("Keep computer awake" is on: the owner's to clear).** The sessions retired before tonight were no longer listed. One container was running at 23:48 (0 go test processes): not looked into. **No track has a session now: said on my row.**
- 23:56 (I-5): **THE OWNER (23:51): "Still 2% left". Three things with it:** (1) **the one container running is the owner's own, not this project's (up 13 days): my note of 23:49 on the row is put right.** (2) **A BASELINE OF THE MAIN HEAD (3774e69) RUNS SINCE 23:53 in a scratch copy `wt-int-baseline` (detached; it removes itself): `go test ./...` once, the server's browser test on, two packages at a time (`runs-int-i5/baseline.sh`); its summary is `runs-int-i5/baseline.out`, the whole log `runs-int-i5-baseline/all.log`. If this session does not come back to it: read the summary first; a package that fails there fails on the head before any new piece (as `internal/fabricate` does, since bae71e5).** (3) **The working copies of the branches merged on 11-16 evening are removed** (`runs-int-i5/remove-merged-copies.sh`: each only if clean, on its branch, and its head equal to `private`; never forced; the local branches stay; the script's last line has the counts); the reviewers' scratch copies (probe files not committed), the detached looks and the copies of the unmerged pieces (`wt-copies-27`, `wt-core-self`, `wt-mirror-adopt`, `wt-mirror-capmax`, `wt-pages-cap`) stay.
- 00:00 (I-5, 11-17): **THE OWNER (11-16 23:57): "The Immich container was for the old app's fingerprinting. Anything you can learn from it? If not, kill the process." NOT STOPPED, AND WHY:** the old app's own code names this container (`immich-ml`), starts it by itself (a look every 30 minutes when its automatic start is on) and uses it for its copy checks by how alike previews look, look-alikes, search and faces: it is part of the running old app, which nobody stops or reconfigures. Looked at read-only (setup; counts and times of its log, no content): made 11-03, port 3003, the graphics card; 72,247 log lines in seven days, the last of 11-14 19:34 local; idle now (0.1% CPU, 251 MiB). What can be learnt is on the board (the newest message, for the unified-archive note): a likeness across the two archives needs vectors from the same model; the old app's document and code for it are named there. The owner is told, with the one command to stop it if they still want that. My row's sentence on the container stands (the owner's own, left alone).
- 00:04 (I-5, 11-17): **THE OWNER (00:03): "Stop it. There's been no update for a few days since I'm basically done running the old app." DONE: `docker stop immich-ml` (stopped, not removed; its restart policy is "unless-stopped", so it stays down until someone starts it; `docker start immich-ml` brings it back). No container runs now.** Asked first, because the old app's code starts and uses this container; the owner's answer settles it. **Also on record from that answer: the owner is basically done running the old app (said on my row: ask before assuming it still collects).**
- 00:31 (I-5, 11-17): **THE BASELINE OF THE MAIN HEAD 3774e69 ENDED (11-16 23:55:17 to 11-17 00:31:16; `go test ./...` once, the server's browser test on; the scratch copy removed): 47 packages ok, 2 failed, 3 without tests.** Failed: `internal/fabricate` (`TestGenerateDeterministic`: known, since bae71e5) and `internal/footage/ffmpeg` (`TestPartsForAgainstFFmpeg`, 17.1 s: new to me, not traced: whether the head's, this PC's ffmpeg or a bound; given to copies in board message 202; no merge of the night touched that package). Everything else passed in one run: the collector 1,705.8 s, the catalogue 456.9 s, the viewer 366.0 s, the server 287.2 s, the supply 150.9 s, the launcher 142.1 s. On my row. **Nothing of mine runs; no copy of mine exists; the main head is 3774e69, equal to `private`, clean. THIS SESSION ENDS HERE.**
- 01:07 (I-5, 11-17): **THE OWNER (00:50): "Still 2%. Try to track down the failing tests. Nothing to lose. Document". BOTH ARE TRACED (board message 203):** **(1) `internal/fabricate`, `TestGenerateDeterministic`: the test's dump sorted every table by two columns and `c_pair_pending` (schema step 24, bae71e5) has one. MENDED BY ME (a test file only: the dump asks the table's column count), on `wip/int-fabricate-order` 28edb68a (pushed), the whole package ok there; MERGED BY THE SCRIPT (01:05:27 to 01:06:25): af4ca40, pushed, the package ok on the merged tree (11.4 s), build, vet, gofmt, the commands ok. Not reviewed: said in its commit message. It is the one piece of code this integrator session wrote.** **(2) `internal/footage/ffmpeg`, `TestPartsForAgainstFFmpeg`: this PC has two ffmpeg programs: 7.1.1 on the PATH and 9.0.2 in the app folder's `tools`. By name on the head: with 7.1.1 it failed 4 of 4 (the same two reads on the clip with a key frame every 50 frames and no B-frames gave no frame); with 9.0.2 named by `FFMPEG_PATH` it passed 2 of 2 and the whole package passed (193.2 s). At the commit before d10e3bd9 the test "passes" in 0.9 s: it found no ffmpeg and skipped; from d10e3bd9 on it finds the PATH's and runs. The copies track's runs set `FFMPEG_PATH`; mine did not. DONE: `ix-tools/env-archiver.sh` names the app folder's ffmpeg when `FFMPEG_PATH` is not set (appended lines; `ix-tools` is not in the notes' repository: it is on disk only).** Open, for copies (203 c): what the app does with an owner's older ffmpeg. **The scratch copies `wt-int-fab` and `wt-int-ff` are removed; the main head is af4ca40, equal to `private`, clean; the collector in place and the owner's folder are still 70b0c7e's (a test file changed since, no program).** My row says it.

## SESSION I-6 (the integrator, Opus; started by the owner 11-21 21:05 with "Read START-INTEGRATOR.md and do what it says")
- **11-21 21:05, the start review.** Nothing changed on disk since I-5's state of 11-17 01:07: head af4ca40, equal to `private`, clean; notes d6eaebe; no session of any track runs (all archived 11-16 23:50). Week's usage 0% (all models, Fable), resets 11-28 15:00. The owner's word: **Opus is the main model for orchestrator sessions; Fable only when Opus is fully stumped** (written into CLAUDE.md).
- **The owner's app has run since 11-19 00:30** (the folder's program: launcher, watchdog, collector, window; the collector is 70b0c7e's). The automatic mirror made 4 mirrors (all "auto"), 54 batches.
- **THE MIRROR STOP (the owner, today): "Blocked: batch refused: MESSAGE_ID_INVALID".** Read-only, counts only: mirror 4 (begun 18:06) sent a batch of 12 at 18:07:00 (11 forwarded, 1 missing: deleted at the source), then a batch of 1 at 18:08:43, refused MESSAGE_ID_INVALID; the catalogue recorded that message deleted at 18:08:50. The source deletes each post minutes after the next one comes. `internal/mirror/auto.go` `forward` blocks the want on ANY refused batch (review M4-R 2 and 4), so the chat stood blocked until the owner's "Allow again" about 21:00 (then 86, 1, 1 forwarded). **Lost: 38 media posts deleted unsaved in that chat; 35 posted during the block; of the 38, 11 lived 90 s or less (the mirror's age rule is 90 to 120 s), 26 over 120 s.** Evidence on record now: a batch with SOME messages deleted is answered (the deleted ones "missing"); a batch whose EVERY message is deleted is refused MESSAGE_ID_INVALID (looks like: one case each).
- **The owner's decision, 11-21 21:05:** besides the fix, single posts (not albums) go 5 to 20 s after they appear, at a random point; albums wait until whole; the account's pause between writes and its random part unchanged; measured on the first day.
- Next: start the tracks' sessions (mirror first, with this as its first piece), then the merges listed (M6, M13, K21, C22; G16 unread).
- **11-21 21:05, the owner amends it: "make it a setting, but default to the recommended times".** So: a stored catalogue setting for a single post's wait, default 5 to 20 s random; albums still wait until whole; no upper bound of the app's own invention (the caps rule).
- **11-21 21:07: five track sessions started and detached** (fresh, Opus, in this folder): mirror M-7 (local_448ea8ea, M14 first), Core K-6 (local_427edf26, alerts first), pages P7 (local_b6590024), viewer B9 (local_34b12870), copies C7 (local_f9b8cc18, the unified archive's design note first). My board row cut (the old state in BOARD-LOG.md). Next: the merges of M6, M13, K21, C22 by the merge scripts; M14 first when listed, then install.
- **11-21 21:12, CORRECTION of my 21:05 numbers (the owner pointed at a bot that posts the same message and deletes it):** all 40 deleted media messages in mirror 4's chat are ONE sender's, ONE identical media set, and that media is in a kept message (saved once). So the "38 lost" were repeats of the bot's message, not unique content. Mirror 3's chat: 39 of one sender's 40 text messages deleted (3 distinct texts) plus 43 service messages. Sent to M-7 (session message, queued): (c) in M14, a message that exactly repeats one already in the mirror (same sender, text and media ids) is not forwarded again, recorded as a repeat; (d) forums: today a forum source is not mirrored at all (`WhyForum`); 3 forum chats in the owner's catalogue; the mirror track's next piece after M14. The rename question: the ledger finds a mirror by chat id, so a manual rename does not break forwarding.
- **11-21 21:14, the merges (the owner: "go ahead"):** K21 (own chat read by itself; its fix round read by me: the switch holds the read, nothing downloaded unless the chat is switched on) and C22 (schema step 27, off by default) share no file; their combined tree is being made and tested once by `ix-tools/batch-tree.sh i6a` (background; log `runs-int-i6a.out`, copy `wt-int-i6a`): whole catalog, collector, mirror, supply, pairwords, bringin, server, livepages, tgstore, storeledger, partsledger, probejudge, vfp, fabricate, exact/wire, appshell; the viewer's change-log tests by name; no race run (no concurrent code changed beyond K21's own race run). Commit messages and the pieces file in `runs-int-i6`. NOT INSTALLED: the owner's app runs the collector; the install waits for M14 and the owner's quit. M6 and M13 wait until after M14; M6's schema step becomes 28.
- **11-21 21:20, the owner: "The app is running, but no reason to not fix things ... Create a mirror in another folder if needed."** Put on the board (the newest message before "Owed") and sent to the five sessions (four delivered, copies queued): tries in a folder of the track's own outside the owner's, no sign-in, LOCALAPPDATA redirected; never wait because the app runs. THE INSTALL PLAN: `make-folder.sh` keeps `tgarchive.json` and `data/` inside the folder, so a second folder is a separate app with empty data: I build `C:/Users/trabi/tgarchive-app-next` from the merged head (to look at, on empty data), and for the real switch I give the owner ONE command that, once the app is quit, rebuilds the owner's folder (the earlier programs kept in `programs/<commit>/`) and starts it; tried as the owner runs it before I hand it over. The batch run `i6a` is going.
- **11-21 21:23, the owner: "What else can you run in parallel? We got lots to do."** Usage 3% of the week at 21:38 (about 30 minutes with five sessions). Started by me: (1) an Opus agent joining M6 and M13 onto K21+C22 in `wt-int-i6b` (M6 becomes schema step 28; tentative commits, named tests only; M-7 told that M6/M13 now go BEFORE M14 and that M14 merges the head in once); (2) an Opus agent answering `QUESTIONS-for-fork-10.md` read-only (`ANSWERS-for-archiver-10.md`: whether C22's switch can be on by default). **The owner chose two NEW tracks; started and detached:** the NAS downloader, N-1 (local_51d969f3: design note first, nothing deployed or run before the owner), and the client acting in chats, A-1 (local_fb1f7bda: design note to the owner before any brief). Seven track sessions run now.
- **11-21 21:32: the four pieces in one batch.** The agent joined M6 and M13 in `wt-int-i6b` (`int/i6b`, local): K21 6a733e75, C22 d4b4c13e, M6 25d7b6dd (one conflict in `catalog.go`'s three schema places, keep both; `mirrorAdoptAfter = twinSchema`, step 28; its step test's one comparison changed), M13 be053617 (only its own 12 files; five main-head files kept at the head's version); tree e0223e64; build, gofmt, vet, the named tests ok. The run `i6a` (K21+C22 alone) was stopped (its processes, mine only, by parent) and its copy removed: one whole run of everything on `i6b` instead (`runs-int-i6/i6b-runs.sh`, background: the collector in one list, catalog mirror telegram supply pairwords bringin server livepages tgstore storeledger partsledger probejudge vfp fabricate exact/wire appshell in the other, the viewer's change-log tests by name, vet and gofmt of internal and cmd). Then `merge-batch.sh af4ca40 e0223e64 runs-int-i6/pieces-i6b.txt`. The owner asked again for topics: M-7 starts them now, in parallel with M14.
- **11-21 21:32: ANSWERS-for-archiver-10.md written** (my read-only Opus agent; nothing written to the old app's folder). The old app's "400 released" holds were mostly right: of the twins that can be judged afterwards 97% the same content (80% of pairs of different Telegram files, 90% with the same file); 18 pairs downloaded twice with equal SHA-256, 11.1 GB; two old release paths not to port. Recommendation: `copies.twin_hold` on by default. Sent to C7 (its piece to make, or to say why not on the board).
- **11-21 22:11: the whole runs on i6b (21:31 to 22:07):** every package ok but two: `internal/collector` `TestSupervisorPanicRestartsAlone` (a gap of 34.8 s in part requests, limit 30 s) and `internal/catalog` `TestTopicSettleAtSize` (one chunk held the writer 639 ms), both timing under load (two whole lists side by side and other sessions' tests). By name on the same tree, 22:07 to 22:11: the supervisor test 5 of 5 ok; the topic test 3 of 3 ok, longest chunk 27 to 88 ms. livepages, exact/wire and every cmd package ok (my script's list had skipped the two with a slash in the name). Judged load, not the pieces. Merging the four with `merge-batch.sh`, no install.
- **11-21 22:16: MERGED AND PUSHED, main head 6aa225fb (equal to `private`, clean):** K21 6be7afcd, C22 3f492199 (schema 27), M6 ce841e58 (schema 28), M13 6aa225fb; `merge-batch.sh` checked the merged tree against the tested one (e0223e64). The copy `wt-int-i6b` and `int/i6b` removed. The queue's four entries marked MERGED, the board's schema line (next free 29) and a message to every track; C7 and M-7 told by message. NOT installed. The second folder `C:/Users/trabi/tgarchive-app-next` is being built from 6aa225fb (`runs-int-i6/folder-next.sh`, background).
- **11-21 22:17: the second folder built** (`C:/Users/trabi/tgarchive-app-next`, 6aa225fb, 6 programs, the tools copied from the owner's folder, empty data, no `tgarchive.json`). Asked pages (P7) for the owner's one-command update from it (catalogue copied aside first: the schema goes 26 to 28 and an older build then refuses it; the earlier programs kept; tried on a scratch folder only). Usage 11% of the week at 22:17 (from 0% at 21:04, seven sessions from about 21:40: about 9% an hour; about 10 hours left at that pace).
