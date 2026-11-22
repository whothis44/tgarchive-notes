# Review of G2 (the Queue: downloading now, just finished, failed with reasons, "Try these N again now", the held-copy switch)

Independent, read-only review of `wip/pages-g2` at da993b39 against 541743d, in `wt-pages-g2` (tree untouched:
`git status` clean after the review). Probes: `wt-pages-review-g2-scratch/zz_review_g2_test.go`, loaded with
`go test -overlay` (named tests, `GOGC=25 GOMAXPROCS=2 -p 1`, no race detector, invented data only). 2026-11-15
evening; the PC at 47-87 % CPU before each run (other sessions' runs going), so every time below is "looks like".

Count: **2 must-fix, 4 should-fix, 8 minor.**

---

## Must be fixed before the merge

### M1. After a file's "Try again now", the keyboard lands on a whole group's "Try these N again now" (CONFIRMED, by reading)
- `web/assets/js/pages/queue.js` 346: the per-file retry puts the focus back with `'[data-key^="retry-"]'`. G2 gave
  the group buttons the keys `retry-group-<i>` (268, from `queuelists.js` 85 `key: group-<i>`), and the panel puts
  "Failed, with reasons" before "Set aside, file by file" (455). `main.querySelector` takes the first match in
  document order, so after the click the focus is on the first group's button, not on the next file's.
- Sequence: the owner works down the set-aside list with the keyboard (Tab to "Try again now", Enter). After the
  first Enter the page reloads and the focus is on "Try these 15,000 again now"; the next Enter makes the whole
  group due: 15,000 files back in line at once (and, at that size, M2's stall). Before G2 the same selector found
  the next file's button. There is no undo.
- Smallest change: give the group keys a prefix that the file selector cannot match (`group-retry-<i>`), or make
  the per-file selector `[data-key^="retry-"]:not([data-key^="retry-group-"])`; better, put the focus back on the
  next row's button by the clicked row's key.

### M2. One click on a large group holds the writer for up to two thirds of a second, then stalls every lane's next claim for seconds (CONFIRMED, probes)
- `queuenow.go` 295-296 and 321: one `UPDATE ... SET retry_at = 0` over the whole group, any size.
- Measured (table below): the UPDATE itself costs about 6 us a row because no trigger fires (only `retry_at`
  changes, state stays `aside`), so it is 5-17 times cheaper per row than the 3.4 s on record (that statement
  changed state through the triggers). But it is unbounded: **628-665 ms for a group of 100,000**, 187-212 ms for
  33,334, and **374-650 ms for 33,334 when the server also has 100,000 set-aside files of another reason** (the
  index has no reason column, so the range is the server's whole set-aside set; even a group of 500 costs 90 ms
  then). A checkpoint write (`SaveProgress`, the engine's) started 2 ms in waited 83, 192 and 628 ms: the whole
  statement. A claim (`ClaimWith`, a `Batch`) and a save wait the same, on the one writer connection.
- The larger cost comes after: the statement makes the group due, and the Supply's next look
  (`supply.go` 466-491, `asideDue` inside `Next`, synchronous in the lane's claim goroutine, `engine/lane.go` 457)
  runs `RequeueAside` over it in 500-row transactions: **14.3 s for 100,000 (201 transactions), 5.1 s for 33,334,
  2.7 s for 15,000**. The lane that called `Next` takes no file meanwhile; one second later (`AsideEvery`) the
  next lane that calls `Next` finds files still due and starts its own requeue beside it, and so on. Sequence:
  the owner clicks "Try these 100,000 again now" while 8 lanes download: the writer is held 0.63 s; then for
  about 15 s (longer on a busy PC) every lane whose slot frees blocks in `Next`; transfers already running go on,
  freed slots stay empty. The words say "within seconds".
- Before G2 a burst of that size could only come from set-aside times that fell together; the page now makes one
  on purpose. By the catalogue's own standard (`requeueChunk` 500: about 70 ms a transaction here) both the
  statement and the burst are too long.
- Smallest change that keeps "one statement per click, never a loop over files" (measured): cap each click at
  5,000 of the group, unique files first and only those not due yet:
  `UPDATE c_want SET retry_at = 0 WHERE tg_media_id IN (SELECT tg_media_id FROM c_want INDEXED BY c_want_aside_lane
  WHERE state = 'aside' AND dc = ?1 AND reason = ?2 AND reason <> 'by the owner' AND retry_at > 0
  ORDER BY probable, retry_at LIMIT 5000)` — plan: the same index range, no sort; **52-96 ms a statement** at
  100,000 (20 statements), **59-136 ms** with 100,000 of another reason beside; the requeue it causes is about
  0.7 s. The button then says "Try 5,000 of these N again now" when N is larger, and the answer says how many are
  left. (A keyset loop in bounded transactions with `CheckpointGap` between would also do, but it is a loop in
  the handler and needs `s.lasting(r)`; the cap is smaller.) Either way the sentence should give the time at
  size instead of "within seconds".

## Should be fixed

### S1. A reason that carries numbers makes one group per file, and the groups have no limit (CONFIRMED mechanism; how often: PLAUSIBLE)
- `engine/lane.go` 2032 builds `part at <offset>: got <n> bytes: part of the wrong length`; it reaches
  `transient` (2274) and, after `TransientMax`, `park(x, now, "keeps failing: "+err.Error())` (2762). The same for
  2648 (`"cannot refresh the file reference: "+err.Error()`, whose text is a type, so bounded). Every other
  set-aside reason is fixed words (listed under "sound").
- `queuenow.go` 240-242: `failedSQL` has no LIMIT and the page renders one row and one button per group
  (`queue.js` 267-282); the shape key holds every reason (`queuelists.js` 116).
- Sequence: a server answers short parts for many files (or the catalogue's sizes are wrong for an imported list):
  each file is set aside with its own offset and byte count in the reason, and "Failed" shows thousands of
  one-file groups, each with its own button, with no "the first N of M".
- Smallest change: LIMIT the groups (say 50) with their count and "the first 50 of M groups" (the rule for cut
  lists); and put on the board for the core track that `park` must take fixed words (the offset and bytes belong in
  a counter or the log's numbers, not in `c_want.reason`).

### S2. The lists of now say "As of <now>" when what they show may have moved without the change key (CONFIRMED, by reading)
- `queue.go` 237-238 with `overviewcache.go` 43-44: when the key did not move, `reuse` answers "now" and the page
  prints `As of <now>` (`queue.js` 230, 246, 265). The key (`countsKeySQL`: change log, copy edges, chats) does not
  move on a checkpoint (`c_progress`), a copier step that writes only the ledger (`CopyCopied`: copy to check,
  `CopyStuck`, `CopyLater`), or the verification of a file written straight to the library (`verified_at` only;
  `cl_file_au` watches location and path). G1 made the opposite rule for the overview for this very reason
  (`overviewcache.go` 69-72: "A kept answer says its own time, never 'now'").
- Sequence: downloads paused (or every lane in a long wait) while the copier works: "Just finished" keeps saying
  "in staging, waiting to be copied" for files whose copy is done and waiting for its check, or not "stopped until
  you look at it" for one just marked stuck, under "As of" the current time, for as long as nothing else changes.
- Smallest change: keep the lists of now by their floor alone (work them out again when older than `covFloor`,
  whatever the key; they cost 4 ms at 7,500 set-aside files, 74 ms at 100,000, 156 ms at 200,000, measured) and
  say `nk.at`, never now.

### S3. The page's numbers do not add up for up to 30 s after a retry (CONFIRMED, by reading)
- The counts block, the tab's "N wanted", "Set aside, file by file" and "Held" are the costly part, kept with
  `queueFloor` (30 s, `queue.go` 217); "Failed", "Downloading now" and "Just finished" with 5 s. After the click
  both are worked out at once, but the files leave `aside` only at the Supply's next look, a second or more later;
  that moves the key, and the next poll redoes only the lists of now.
- Sequence: "Try these 1,200 again now"; 2 s later the requeue runs; at the next poll "Failed" shows 0 files
  while the counts block still says "Set aside 1,200 · X GB" and the file-by-file list still offers "Try again
  now" for each of them (a click then is refused as "changed state meanwhile") for up to 30 s. Each region says its
  own time, but the rule is that the numbers add up.
- Smallest change: take the set-aside, gone and in-transfer counts per server for the counts block from the lists
  of now (`failedSQL` already sums the set-aside files and bytes; `goneSQL` the gone; `activeCountSQL` the active),
  or redo the costly part when the lists of now find the server's set-aside total changed.

### S4. The retry's sentence is false in several states (CONFIRMED, by reading)
- `RetryGroupWords` (`queuenow.go` 129): "within seconds while it downloads, at its next start otherwise". The
  requeue runs only inside `Next`, which only a lane that claims calls: while every account is paused or stopped
  by the owner the files come back at the resume or Start, not at "its next start"; at size it is not seconds
  (M2). "A file that times out twice is set aside again, for longer": true for the timeout reasons
  (`setAside`, `AsideAfter: 2`) and `park`, false for `CheckLater` (`ReasonExactNotStarted`, a fixed wait, `asides`
  not raised) and for an unreachable file (`UnreachableAside`, a fixed hour).
- Smallest change: one sentence per case the page knows from the live answer (downloading / paused / stopped /
  no collector), and "set aside again if it fails again" without "for longer".

## Minor

1. **Group keys are the group's place, not its reason** (CONFIRMED): `queuelists.js` 85 `group-<i>`; the groups are
   ordered by their count (`failedSQL` `ORDER BY 2 DESC`), which moves as files fail and come back. A refused
   retry's words (`msgFor`, key `retry-group-0`) then sit under whichever group is first; a rebuild while the
   pointer is between rows reorders the buttons. Key the groups by their reason (an index into a stable map) and
   order them by reason, not by a count that moves.
2. **Clicks are not refused while one is in flight** (CONFIRMED): no button is disabled; a double click on "Try
   these N again now" sends two statements (harmless twice, but at 100,000 two 0.6 s holds).
3. **Place words** (`queuenow.go` 82-98; PLAUSIBLE that they occur): a file written straight to the library whose
   check is stuck says "written straight to the library" (the stuck mark is read only for staging); a staged file
   whose *check* is stuck says "its copy is stopped"; "lost ..., so it is wanted again" is not always so
   (`WantAgain` may hold it, skip it on another archive's list, or leave a row as it was).
4. **`collectWords`** (`chats.js` 67): decides "it has no files listed yet" from `c.files`, which comes from the
   kept counts (up to their floor old) before looking at the effect: a chat whose files were listed since says
   "no files" while the effect moved some. Look at the effect first. (PLAUSIBLE)
5. **"Just finished" rows carry no `data-ctl-row`**, so the region is rebuilt under the pointer: with saves
   arriving, "Open its post" moves down a row under a pointer about to click it (a wrong post opens; harmless).
   (PLAUSIBLE)
6. **`act` sets `st.data` inside `load()` before any check**: a poll's GET started before a click and answered
   after it would paint the state before the click until the next poll; the server's `qMu` makes the order
   likely right, not certain. (PLAUSIBLE)
7. **Tests at size under the race detector**: `TestQueueCostAtSize` and `TestRetryGroupIsOneStatement` skip only
   under `-short`; once G1's ee437a46 (`raceOn`) is merged they should skip under it too (each fills 300,000 files,
   about 15 s here; several minutes under the race detector). Neither times the retry: the measurement this review
   made is not in the tests. (CONFIRMED by reading)
8. **The rig test** `TestPagesRetryGroupDownloads` waits on real time (`eventually` 120, 30 and 60 s) on a clock
   at 3x under the race detector: the 60 s for the download after the click may be short there. Its own "< 10
   minutes" check is on the rig's clock, so it is not a wall-time judgement. (PLAUSIBLE)

---

## Point 1: the measurements

300,000 invented files (catalogue fixture plus `rvFill`), the group on server 2 under one reason, the rest wanted
on servers 1-4; every file carried by one message, reached by account 1; each row 3 runs (best / worst), the WAL
checkpointed between runs. The probe's code: `wt-pages-review-g2-scratch/zz_review_g2_test.go`
(`TestReviewG2RetryCost`, `TestReviewG2RetryCapped`, `TestReviewG2NowListsAtSize`).

| Group made due | Other set-aside rows on the server | The one UPDATE (writer held) | A checkpoint write waited | WAL written | Requeue after (Supply's next look) | CPU before run |
|---|---|---|---|---|---|---|
| 500 | 0 | 2-3 ms | 0 ms (started after) | 76 KB | 0.38 s, 2 transactions | 77 % |
| 15,000 | 0 | 84-106 ms | 83 ms | 1.9 MB | 2.7 s, 31 transactions | 49 % |
| 33,334 | 0 | 187-212 ms | 192 ms | 4.3 MB | 5.1 s, 67 transactions | 49 % |
| 100,000 | 0 | **628-665 ms** | 628 ms | 13 MB | **14.3 s, 201 transactions** | 49 % |
| 500 | 100,000 | 90-92 ms | 88 ms | 2.8 MB | not run | 47 % |
| 33,334 | 100,000 | **374-650 ms** | 363 ms | 8-24 MB | not run | 47 % |
| capped form (M2), 5,000 a click, of 100,000 | 0 | 52-96 ms each (20 clicks) | | | about 0.7 s a click | 76 % |
| capped form, 5,000 a click, of 33,334 | 100,000 | 59-136 ms each (7 clicks) | | | | 76 % |

Beside the record: 3.4 s for 33,334 rows in one UPDATE (state changed, triggers fired). This statement fires no
trigger, so 33,334 rows cost 0.19-0.65 s; it is still unbounded, and 0.63 s at 100,000 is about nine times the
catalogue's own bound per transaction (500 rows, about 70 ms here).

**Context ending in the middle** (the page closed, the pages stopping): the statement cancelled at 20 ms of a
100,000 group returned with an error after 33 ms and **0 rows were made due**: one statement is all or nothing,
so nothing is half done; the handler logs `pages: POST /api/queue/retry-group failed (<class>)` and answers
nothing the page will see. A failing statement (a busy catalogue past 5 s from another process) is the same.

**The lists at size** (300,000 files, 300,000 saves on record): `failedSQL` 4 ms with 7,500 set-aside files on the
server, 75 ms with 100,000, 148 ms with 200,000 (two temporary b-trees, GROUP BY and the groups' order); `goneSQL`,
`activeSQL`, `finishedSQL` and `COUNT(*) FROM fetch` 0 ms at every size (the count is SQLite's b-tree count over
`fetch_media`); `nowLists` as a whole 4, 74 and 156 ms. At the old account's scale the 5 s floor of the lists of now
is fine (156 ms every 5 s at worst for one polling page).

## Checked and found sound

- **What the retry can take**: only `state = 'aside'` rows of the one server and reason (the partial index forces
  it; held, kept-held, active, gone, other servers and other reasons untouched: `TestRetryGroupLeavesHeldAndActive`
  read and agreed). Every writer of state `aside`: `Aside` (engine reasons: the two timeout sentences, "file
  reference keeps expiring", "Telegram gave no new file reference", the refresh's fixed phrases, `flagWords`, and
  the two `err.Error()` ones of S1) and `CheckLater` (`ReasonExactNotStarted`). **`by the owner` is never on a
  set-aside row**: no route sets aside by hand, `Transition` to aside has no caller, and `Aside` overwrites the
  reason, so the exclusion (statement, 409, no button) is correct and vacuous today. Reason empty: matched as
  stored (`NOT NULL DEFAULT ''`), shown as "no reason on record". A NULL reason cannot exist.
- **What "due now" does**: `retry_at = 0` on an aside row means only "due" (every reader of `retry_at` read:
  the lane's `waiting` and `c_want_waiting` are for wanted rows only). `asideBackSQL` then brings a probable copy
  back to held with the ladder's reason, a file whose chat no longer collects it held as not collected, keeps
  `check_first`, `attempts` and `asides`. A held copy cannot go first meanwhile: the claim's third check
  (`heldGate`) refuses it while a due unique set-aside of the server is not back. The supply has no other memory
  of set-aside times (`avoid` is hand-overs only; `AsideBook` only counts). With no collector, the files come back
  at its first `Next` (`nextAside` zero).
- No trigger fires on the retry (`sup_want_au`'s WHEN needs wanted or held; the change log watches state and
  reason); the page's own click still works both parts out again (`guard`'s `markDirty` before and after).
- **The held-copy switch**: `Batch(LoadSettings, SaveSettings)` under `s.mu`; every other writer of the settings
  row (the Settings page's `store`, the theme, start-up) loads and saves under the same lock and none carries
  `held_wait` (`settingsView` has no such field); the Supply reads it at most every `ModeEvery` (5 s, the collector
  sets none) in `Next` and the claim; `NextWanted` reads it, so the page's next lists follow at once.
- **Guard and log**: both routes are registered through `handle` inside `guard` (host, cross-site, origin and
  token, demo refused with 409: tested); the reason from the page reaches no log line, error or toast (`fail`
  logs the route and the class; the 409 is constant words); the scripts put names, titles and reasons in with
  `text`/`textContent` only (no HTML sink anywhere under `web/assets/js`); `toast` uses `textContent`.
- **Lists**: `activeSQL` in the index's order, no sort, the account from `claimed_by`, its count by the same range
  when cut; `finishedSQL` a backwards scan stopped at 20; `fetch` is only ever inserted (`state.go` 631), so the
  row order is the save order (a file saved twice shows twice, each its own row and key); the place words for
  staged, copied-not-verified, verified and lost match `staging.go`'s ledger and triggers (except minor 3).
- **The kept answers**: one `qMu` around the whole answer, so two requests at once do not work it out twice; the
  lists of now are kept per server only (at most 1,000 entries); the costly part per server, account and limit,
  emptied at every change through the pages (the account key is unbounded, as in G1).
- **Scripts**: every list mapped and filtered in the answer's order, never sorted; a region under the pointer is
  not rebuilt and is retried at the next poll (no update lost for good); "the first N of M" for the transfer,
  set-aside, held and finished lists; the viewer link only when the viewer's address is set and the live answer
  does not say it is down. The two Chats faults are fixed as asked (with minor 4).

## Not looked at

- The pages in a browser (the test server on 127.0.0.1:8793 was left alone), phone width, CSS.
- The race detector, Docker, whole-package runs, and the author's own tests: none run. The rig test
  `TestPagesRetryGroupDownloads` was read, not run. The author's four mutations were not re-applied.
- The requeue's cost with several lanes calling `Next` at once (M2's sequence is from reading `supply.go` and
  `engine/lane.go`, timed with one caller).
- How often a short part or a non-Telegram error happens for real (S1's frequency).
- The Chats page's estimate note path (needs a 202 answer) and `topics.js` beyond the one export.
