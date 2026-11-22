# Brief G2b: the Queue page's fix round (pages track, session P3; 2026-11-15 21:45)

For one Opus coder. The piece: `wip/pages-g2` at da993b39 in the copy
`C:\Users\trabi\Claude\Projects\Telegram\wt-pages-g2` (Go module in `archiver/`). What it built:
`C:\Users\trabi\Claude\Projects\Telegram\BRIEF-G2-queue-now.md` and `archiver/docs/progress/pages-g2-REPORT.md` on
the branch. **Read the independent review in full first: `C:\Users\trabi\Claude\Projects\Telegram\REVIEW-G2-queue.md`**
(2 must fix, 4 should, 8 minor; its probes are in `C:\Users\trabi\Claude\Projects\Telegram\wt-pages-review-g2-scratch`,
`zz_review_g2_test.go` with `overlay.json`: read them, they are the measurements you must not make worse).
Every finding is accepted. This brief says how each is closed; where it and the review's "smallest change"
differ, this brief wins; where you find either wrong, say so in the report rather than build around it.

## What is on record (why these are not matters of taste)
- The catalogue cuts its own requeue into 500 rows a transaction because one UPDATE of 33,334 due rows held the
  single writer 3.4 s (`internal/catalog/state.go`, above `requeueChunk`). The reviewer measured this piece's
  one-statement retry at 628 to 665 ms for a group of 100,000 and 374 to 650 ms for 33,334 beside 100,000 of
  another reason, and the supply's requeue after it at 14.3 s for 100,000 (inside a lane's `Next`: freed slots
  stay empty meanwhile). The old app's batch pause scanned the whole queue per file and timed out half done.
- Retrying is mostly futile on a server that is timing out (the old app: second retries answered 0 of about
  404), so a retry of thousands at once buys nothing a retry of a bounded number does not.
- One vocabulary that adds up, every number saying what it counts and when it was read (the owner's rule for
  these pages; the old app's "Downloading 14 vs 25" came from two readings shown as one).
- This track's last three failures under the race detector were all tests that depended on how fast real time
  passes. No test here judges on seconds; a wait in a test is an upper bound only.

## Step 0: take G1's head in
Merge `wip/pages-g1` at ee437a46 into `wip/pages-g2` (tests only since 541743d: the part hold for the rig's
tests, `raceOn` in `internal/server`). Expect small conflicts where you touched the floor fields in
`program_test.go` and `program_fix_test.go`: keep both sides. Then give `TestQueueCostAtSize`,
`TestRetryGroupIsOneStatement` and every new test of this round that fills 300,000 files the `raceOn` skip
(review, minor 7), beside their `-short` skip.

## The fixes
1. **M1, with minor 1: a group's button can never take a file's focus, and a group is known by its reason.**
   Group keys are made from the reason (a stable key per reason for the page's life: an index into a map kept in
   the page, never the group's place in the list) under a prefix no file selector can match; the groups are
   ordered by reason, not by a count that moves (change `failedSQL`'s and `goneSQL`'s order and say so in the
   heading: "by reason"). After a file's "Try again now" the focus goes to the next file row's button, found by
   the clicked row's key, never by "the first button whose key starts with retry-". A refused click's words stay
   with their own group. Tests in node: the per-file retry's focus with a group present; a group's key unchanged
   when another group appears before it.
2. **M2: one click makes at most 5,000 files due, in one statement, unique files first.** The statement is the
   review's capped form (the same index range, no sort: check the plan in the test):
   the group's set-aside rows with `retry_at > 0`, `ORDER BY probable, retry_at LIMIT 5000`, made due. The cap is
   one constant with the two measurements beside it in a comment. The button says "Try these N again now" when
   N is at most the cap and "Try 5,000 of these N again now" when it is larger; the answer says how many were
   made due and how many of the group are still set aside and not due; the group's line says how many are "due
   now" (already made due, waiting for the collector's next look) apart from the rest, so a second click's
   effect is visible before the files leave. `TestRetryGroupIsOneStatement` keeps its meaning (one statement per
   click through the counting wrapper) and gains: a group of 100,000 beside 100,000 of another reason at 300,000
   files, one click touches exactly 5,000 rows, all unique ones before any probable copy, none of the other
   reason; the time is logged, not judged. The owner's own files and every other state stay out, as now.
3. **My browser pass's fault: after the owner's own click the clicked region shows the result at once, also
   under the pointer.** Today the region waits for the pointer to leave, so the group kept reading "due now"
   with its button for as long as the pointer rested on it, though its file had been saved 15 s before: the
   click looks as if it did nothing. Rule: a region is still never REBUILT under the pointer by a poll; but its
   words and numbers are updated in place there too, and a control whose row is gone from the answer stays
   where it is, disabled, with the fixed words "no longer set aside" (or the list's equivalent) until the
   pointer leaves; the answer to the owner's own click is always painted. A node test for the shape rule with a
   row that disappears under the pointer.
4. **Minor 2 and 6: clicks and polls in order.** A button is disabled from its click until its answer is
   painted (every action button of the page, the switch too). Each request the page sends carries the page's
   own running number; an answer older than the last painted one is dropped. Node tests for both.
5. **S1: the groups are limited.** At most 50 groups of failed and 50 of gone a server, in the order
   of fix 1 (by reason), with "the first 50 of M groups" when cut, M from one count of distinct reasons over the
   same range taken only when cut, and the files and bytes of the groups not shown said in one line (so the
   numbers still add up to the server's set-aside total). A test with 120 invented reasons. Do NOT change the
   engine: that `park` writes an offset and a byte count into a reason is the core track's (it goes on the
   board from the main session).
6. **S2: a list of now says when it was read, never "now".** The lists of now (in transfer, just finished,
   failed, gone) are worked out again when older than their floor whatever the change key says, and every
   "As of" on the page is the time of the reading it shows. A test: a checkpoint, a copier's ledger step and a
   verification that do not move the change key are on the page after the floor has passed, and before it the
   page says the older time.
7. **S3: the numbers add up at every moment.** The counts block's set aside, gone and in transfer for the
   server, and the tab's numbers that depend on them, come from the same reading as the lists of now; and when
   that reading's set-aside total for the server differs from the costly part's, the costly part (the
   file-by-file set-aside list, held, next) is worked out again at once, not after its 30 s. A test: after a
   retry and the supply's requeue, one answer never shows "Failed: 0 files" beside "Set aside: N" or a
   file-by-file row for a file that is no longer set aside. Keep the costly part's 30 s floor otherwise; say in
   the report what a requeue of 5,000 then costs the page (statements, not seconds).
8. **S4: the retry's sentence is true in every state the page knows.** One sentence per state from the live
   answer: the account downloads on this server ("at the collector's next look, usually within seconds");
   downloads paused by you, or the account stopped by you ("when you resume or press Start: nothing is tried
   while it is paused or stopped"); no collector running ("at its next start"); and "a file that fails again is
   set aside again" without "for longer" (not true for every reason). With the cap: "5,000 at a click". The
   words are constants with a test of each state (`TestPageWordsTrueInBothModes` is the model).
9. **Minor 3: place words.** "its copy or its check is stopped until you look at it" for a stuck ledger row in
   either state, also for a file written straight to the library whose check is stuck; "lost: neither in
   staging nor in the library" without the promise "so it is wanted again". The test of each place follows.
10. **Minor 4:** `collectWords` looks at the effect's counts first and says "it has no files listed yet" only
    when the effect moved nothing and the chat lists none.
11. **Minor 5:** a "Just finished" row with a link is a control row (`data-ctl-row`): not rebuilt under the
    pointer.
12. **Minor 8:** the rig test's waits are upper bounds: give `TestPagesRetryGroupDownloads` room for the race
    detector's clock (the rig's clock runs 3 times real time there, 20 times without it), and hold parts with
    `rig.holdParts` wherever it needs "still in transfer". Note for you: in any rig with a forum the fake's
    topics answer fails today and the reader retries it with pauses (a fault of the fake, Core's, being fixed
    on another branch): a call handed to the reader can wait behind that; do not edit `faketg`.

## Rules (hard)
- Work only in `wt-pages-g2` on `wip/pages-g2`. Product code only in `internal/server` and its page scripts; no
  catalogue function, no schema step, nothing in the collector but its one rig test, nothing in the engine, the
  supply, the store, the viewer or `faketg`. Never edit another copy, `BOARD.md`, `MERGE-QUEUE.md` or the notes.
- Nothing runs against Telegram. Never touch `E:\T\tg-dl`, the folders `a3`, `b`, `app`, any real catalogue,
  media, session or account; start no installed program. Invented data only.
- New log, error and state text is constant words with numbers: never a name, title, path, id or text.
- Go: Git Bash, `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`, one go command at a
  time, `GOGC=25 GOMAXPROCS=2 go test -p 1 -run '<names>' ./internal/<package>`, named tests only: no whole run of
  `internal/server`, `internal/collector` or `internal/catalog`, no race detector, no Docker. Before each go
  command: `powershell -NoProfile -Command "(Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB; (Get-CimInstance Win32_Processor).LoadPercentage"`;
  wait when free memory is under 2.5 GB or the CPU is over 85%.
- After any change under `web/assets/js`: `TestScriptsNoDuplicateOrMissingNames` and a module parse of each
  script with node (`node --input-type=module --check < file`).
- **Open it before handing back:** `TestPagesHold` from your copy (`TGARCHIVE_PAGES_HOLD=127.0.0.1:8794`), the
  Queue page in the built-in browser if you have one: a per-file retry with the keyboard (where does the focus
  land), a group's retry with the pointer left on the button, a double click. Say exactly what you saw.
- Any file that holds a Windows path is written with the file-writing tool, never from inside a shell or script
  string.
- Commits: `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, the message ending with
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; commit work in progress as you go and push only
  `git push private wip/pages-g2`. Never push, merge into, rebase or switch any other branch; never stash.
- Keep `archiver/docs/progress/pages-g2-PROGRESS.md` current and commit it with each step.

## Hand back
Commit-ready: everything committed and pushed, the tree clean, `gofmt -l` clean, `go vet ./internal/server/`.
A new section "Fix round (G2b)" at the end of `archiver/docs/progress/pages-g2-REPORT.md`: each finding (M1, M2,
S1 to S4, minors 1 to 8, the browser fault) with what was changed and the test that now fails without it; the
capped statement's plan and the logged times at 300,000 files with the PC's CPU beside them; every existing
test whose expectation changed and why; mutations (the cap removed; the file selector matching a group's key
again; a list of now saying "now"; the counts taken from the older reading): each applied, its test failing,
undone; what you saw in the browser and what you did not; what was NOT verified; anything in this brief you
found wrong. Your final message: the head commit, what is fixed and tested, what is not, every departure, and
your doubts, plainly.
