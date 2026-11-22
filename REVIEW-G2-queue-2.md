# Second review of G2 (the Queue page) after its fix round G2b

Independent, read-only review of `wip/pages-g2-main` at 2fc8f622 (base 2580f291) in `wt-pages-g2m`; the fix round read
as `da993b39..563a9126` in `wt-pages-g2`. Tree untouched (`git status` clean, HEAD 2fc8f622 after the review).
Probes: `wt-pages-review-g2b-scratch/zz_review_g2b_test.go` with `overlay.json` (named tests, `GOGC=25 GOMAXPROCS=2
-p 1`, no race detector, invented data only); logs `walks.log` and `rest.log` beside them. 2026-11-15 late evening;
the PC at 55-65 % CPU and 8.5-10 GB free before each run (other sessions' work going): every time is "looks like".

Count: **0 must-fix, 3 should-fix, 6 minor.** The first review's 14 findings: 12 closed, 2 partly (M2, S3), 0 not.

---

## The first review's 14 findings

| # | Finding | Now | Evidence |
|---|---|---|---|
| M1 | a file's retry put the keyboard on a group's button | **closed** | Keys of distinct kinds (`queuelists.js` 88-90: `file-retry-`, `group-retry-`), focus by the clicked row's key (`focusAfter` 116-128, `queue.js` 189), no prefix selector in `queue.js`. `TestQueueFocusAndGroupKeys` run: passes. |
| M2 | one click, any size, held the writer up to 0.65 s | **partly** | The cap works: 20 clicks took a group of 100,000 at 65-104 ms each; 7 clicks a group of 33,334 beside 100,000 of another reason at 76-167 ms; no probable copy taken while a unique one was left (0 of 27 clicks), none taken twice (sum of rows = due at the end = group), the other reason untouched. 95,000 of the group already due cost little (94-101 ms: rejected on the index alone). **But a group with fewer than 5,000 not due walks the server's whole set-aside range with a table lookup per row: 246-314 ms for 500 beside 200,000** (new finding 1). |
| S1 | groups unbounded | **closed** | `failedSQL`/`goneSQL` `LIMIT 50`, totals by one count when cut (`queuenow.go` 301-341), `groupsCutWords`. Probe with 1,000 reasons over 200,000 set-aside files: 50 shown of 1,000, totals 200,000 files. The engine still writes numbers into reasons (core track's; not this branch). |
| S2 | lists of now said "now" | **closed** | `nowFresh` (`queue.go` 310-316) rereads after 5 s whatever the key; `now_as_of` is the reading's time; the costly part's `as_of` its own. The price: the lists are read every 5 s an open page, 120 ms at 100,000 set aside on the server, 242-276 ms at 200,000 (new finding 3). |
| S3 | numbers did not add up for 30 s | **partly** | The counts block now comes from the lists of now (`withNowCounts`), and a disagreement rereads the costly part. **One answer can still show "Set aside 0" and "Failed 0" beside three file-by-file rows with "Try again now"** (probe, new finding 2); it heals at the next request. |
| S4 | the retry's sentence false in several states | **closed** (two minor words left, finding 6) | `retryWhen` (`queuenow.go` 406-427): pages alone, downloads off, an account running (the Supply's `RequeueAside` is global, `supply.go` 480, so any running lane brings every server's due files back), paused or stopped by you, none running; "for longer" gone. `TestRetryWordsTrueInEachState` read. |
| minor 1 | group keys by place, order by count | **closed** | `groupKeyer` (reason to number for the page's life), `ORDER BY w.reason`. |
| minor 2 | no click gate | **closed** | `clickGate`, button disabled from the click (`queue.js` 172-174) and rebuilt enabled after the answer or the error. |
| minor 3 | place words | **closed** | `placeOf` checks lost, then stuck (any step, staging or straight), then staging (`queuenow.go` 88-104); no "so it is wanted again". |
| minor 4 | `collectWords` | **closed** | `chatwords.js` 13-20: pending, then the effect's parts, then `c.files`. |
| minor 5 | "Just finished" rows rebuilt under the pointer | **closed** | `finishedRows` `ctl`, row marked `data-ctl-row` (`queue.js` 331-332). |
| minor 6 | a poll painted after a click | **closed** | `seq` on every queue GET, `requestGate.take` drops older answers; `again()` paints nothing while a click is in flight. |
| minor 7 | size tests under the race detector | **closed** | `raceOn` skips beside `-short` in `TestQueueCostAtSize`, `TestRetryGroupIsOneStatement`. |
| minor 8 | rig test on real time | **closed** | Every wait in `TestPagesRetryGroupDownloads` is an upper bound; the one judgement is "saved before its own `retry_at`" on the rig's clock. Under the race detector the longest wait (300 s real, 15 min of the rig's clock) is still inside the about 20 min set-aside, so the judgement stays meaningful. Not run here. |

## New findings, in order of harm

### 1. SHOULD (borderline must). A click on a small group holds the writer for as long as the server's whole set-aside range takes to walk (CONFIRMED, probe)
- `queuenow.go` 395-398: the pick is `c_want_aside_lane (dc=?)`, whose columns are (dc, probable, retry_at); `reason`
  is not in it, so every set-aside row of the server is looked up in the table until 5,000 of the group are found.
  When the group has fewer than 5,000 not due (every group under 5,000, and the last click of every larger one),
  the whole range is walked, inside the write statement.
- Measured at 300,000 files: a group of 500 beside 200,000 unique files of another reason, not due: **246-314 ms,
  and a checkpoint write started 2 ms in waited 294-312 ms**; the same with the 500 all probable copies 246-314 ms;
  the 7th click of 33,334 beside 100,000 (3,334 rows): 167 ms. It is linear in the server's set-aside count (the
  first review: 90 ms at 100,000), so 0.6 s at 400,000. The catalogue's own bound is 500 rows, about 70 ms. The
  `probable IN (0, 1)` form (retry_at as a range) does not help here (237-274 ms); it only spares due rows, which
  are cheap already.
- Sequence: a storm on server 2 sets aside 200,000 files under "the server does not answer for this file"; a few
  hundred under another reason; the owner clicks "Try these 500 again now": every lane's claim, save and
  checkpoint waits about 0.3 s on the one writer. Rare (a click), bounded by one server's set-aside count, no data
  harm: hence "should".
- Smallest change, still one write a click: do the pick on the reader pool (the same `SELECT ... ORDER BY probable,
  retry_at LIMIT 5000`, no writer held), then write by id with the conditions checked again:
  `UPDATE c_want SET retry_at = 0 WHERE tg_media_id IN (SELECT value FROM json_each(?4)) AND state = 'aside' AND dc
  = ?1 AND reason = ?2 AND reason <> 'by the owner' AND retry_at > ?3` (a row that changed meanwhile is simply not
  taken; the write is at most 5,000 key lookups, about 60-100 ms measured above). Keep `TestRetryGroupIsOneStatement`
  as "one write statement"; add the 500-beside-200,000 case with the write's rows counted.

### 2. SHOULD. One answer can still show none set aside beside file-by-file rows that offer "Try again now" (CONFIRMED, probe `TestRvbS3OneAnswer`)
- `queue.go` 241-295: when both parts are read in the same answer, the costly part (its own statements, no
  snapshot) is read first and the lists of now second. A change between them (the Supply's requeue, 10
  transactions over about 0.7 s for 5,000) leaves them different; `sameAside` is false, but both are fresh in this
  answer, so neither is read again (`!costlyFresh`, `!listsFresh`).
- Probe: three due set-aside files, the requeue run after the costly part's reading and before the lists':
  the answer said counts "Set aside 0", failed total 0 in 0 groups, **3 file-by-file rows**, wanted small 1 (the
  truth is 4). The next request, 4 s later, read the costly part again and agreed.
- When it happens: both parts are read together after every change through the pages (`qDirty`), that is in the
  answer to the owner's own click, which is exactly when a requeue is about to run. The owner then sees "Set aside 0"
  beside rows offering "Try again now" for up to 5 s; a click on one is refused ("changed state meanwhile"). The
  brief's test for S3 ("one answer never shows ... a file-by-file row for a file that is no longer set aside") does
  not cover the ordering inside one answer.
- Smallest change: read the file-by-file set-aside list inside the lists of now's read transaction (`nowLists`),
  so the counts block, the groups and the rows offering "Try again now" are one snapshot. Measured: that statement
  alone (`stateList` aside, limit 15) costs 39 ms at 100,000 set aside on the server, 70-77 ms at 200,000, every 5 s
  an open page; or read it there only in an answer that also reads the costly part.

### 3. SHOULD. In a storm the costly part is worked out every poll, and the lists of now cost up to a quarter second every 5 s whatever changes (CONFIRMED, probe `TestRvbOpenPageMinute`, `TestRvbNowListsAtSize`)
- `queue.go` 283-289 (S3's reread) and 272-277 (S2's floor). A minute of one open page at 300,000 files, polled
  every 5 s:

  | The minute | Costly part worked out | Statements | Time in the 12 answers |
  |---|---|---|---|
  | nothing changes | 0 | 225 | 0.44 s |
  | a file held and back every second (key moves, set-aside total does not) | 2 | 392 | 1.5 s |
  | **a file set aside every second (a storm)** | **12** | **1,116** | **5.3 s** |

  And the lists of now alone, read every 5 s even when nothing changes: 120 ms at 100,000 set aside on the server,
  242 ms at 200,000, 276 ms at 200,000 under 1,000 reasons (cut at 50: the total count adds a second walk).
- `queueFloor`'s own comment says 30 s was chosen because one working-out is over a quarter second at 300,000; in a
  storm (the moment the page is most likely open) S3's rule turns it into 5 s. These are reader connections, not the
  writer, so no lane waits; it is about 9 % of one core per open page, a second tab doubles it. No test bounds it:
  `TestOpenPageStatementsBounded`'s "change every second" toggles a held file (the set-aside total never moves) and
  allows 13 workings-out a minute anyway.
- Smallest change: with finding 2's fix the rows that carry a click agree with the counts by construction, so the
  costly part need not be reread on a set-aside change at all (its "Wanted" and "Held" lag up to 30 s under their own
  "As of"); if the reread stays, give it its own floor (say 15 s). Add a storm minute to
  `TestOpenPageStatementsBounded` with a bound.

### 4. MINOR. `TestOpenPageStatementsBounded`'s new bound is not a bound (CONFIRMED, by reading)
- `program_test.go` 321, 337: `stmts > 12*2*8 + nowN*nowOne`, with `nowOne` measured in the same run. A lists of now
  that cost 1,000 statements would raise the bound to match and pass. Only `nowN <= 12` is checked. Smallest change:
  a constant for one reading (today 15-20 statements: say `nowOne <= 25`) and the bound from that constant.

### 5. MINOR. The words after a retry can say "0 files of this group still set aside" for a group that has files (PLAUSIBLE: needs more than 50 reasons)
- `queuelists.js` 160-165: `left` is 0 when the group is not among the 50 groups in the reading after the click.
  With groups ordered by reason, a new reason that sorts before it pushes it out of the first 50 between the click
  and the reload. Smallest change: when the group is not in the answer, leave out the "still set aside" half.

### 6. MINOR. Two sentences still promise what is not always so (CONFIRMED, by reading)
- `RetryWhenPaused` (`queuenow.go` 168): "They come back when you resume or press Start". A pause with an end comes
  back by itself at that end (`PauseState.Until`), and Start does not end a pause (`pausedl.go` header: "not the
  owner's Start after a Stop"). Say "when the pause ends or you resume it, or when you press Start for an account you
  stopped".
- `RetryWhatWords` (162): "they go back in line by rank" is not true of a file whose chat no longer collects it
  (`asideBackSQL` holds it as not collected). Add "or held, if its chat no longer collects it".

### 7. MINOR. A refused click's words follow its reason to another server (CONFIRMED, by reading)
- Group keys are per reason for the page's life and shared by every server (`queuelists.js` 98-105); `st.msg` is
  cleared only by the next click (`queue.js` 176), not by a server tab change (246-255). A refusal under
  "the server does not answer for this file" on server 2 shows under the same reason's group on server 4 after
  switching. Clear `st.msg` on a tab or account change (or key groups by server and reason).

### 8. MINOR. A click whose write succeeded but whose reload failed is reported as refused (CONFIRMED, by reading)
- `queue.js` 180-202: the POST and the reload GET share one `try`; if the GET fails, the GET's error ("The app does
  not answer...") is shown beside the control as the click's refusal, though the files were made due. A second
  click then takes the next 5,000. Say "Done; the page could not be read again" when the POST answered.

### 9. MINOR. After a poll rebuilds a region, the keyboard on a control whose row left goes to the server tab (CONFIRMED, by reading)
- `queue.js` 231-236 (`place`, the build path): it puts focus back on the same key or the tab, never on the next
  control of its kind (`focusAfter` is used only after clicks). Use `focusAfter` there too.

## Measurements

300,000 invented files (`fillRetryGroups`, `fillQueue`); times are "looks like".

| What | Result | CPU before |
|---|---|---|
| Capped clicks, group 100,000 | 20 clicks of 5,000; 65-104 ms each, rising as due rows accumulate; 0 probable before unique; 100,000 due at the end | 56 % |
| Capped clicks, 33,334 beside 100,000 of another reason | 7 clicks; 76-167 ms (last click 3,334 rows: 167 ms); other reason untouched | 56 % |
| One click, 95,000 of the group already due | 5,000 rows, 94-101 ms; checkpoint write waited 98 ms | 55 % |
| One click, 5,000 not due beside 200,000 due of another reason | 68-69 ms; waited 66 ms | 55 % |
| **One click, 500 not due beside 200,000 not due of another reason** | **268-314 ms; waited 312 ms** | 55 % |
| Same, the 500 all probable copies | 246-314 ms; waited 294 ms | 55 % |
| `probable IN (0,1)` form, same four cases | 85-87, 40-43, 211-274, 237-257 ms | 55 % |
| `nowLists`, 100,000 / 200,000 / 200,000 under 1,000 reasons set aside on the server | 120 / 242 / 276 ms; 15-16 statements | 56 % |
| `stateList` aside (limit 15), same | 39 / 77 / 70 ms | 56 % |
| An open page, a minute (see finding 3) | 0 / 2 / 12 costly workings-out; 225 / 392 / 1,116 statements; 0.44 / 1.5 / 5.3 s | 56 % |
| S3 in one answer (small fixture) | Set aside 0, failed 0, 3 file-by-file rows; agreed at the next request | 65 % |

## Checked and found sound
- **The capped statement**: one write; the plan uses `c_want_aside_lane (dc=?)` with no temporary b-tree; the IN
  subquery is materialised before the update (no row seen twice); `retry_at > now` takes none twice and leaves due
  rows to the Supply; unique before probable and other reasons untouched (probe over 27 clicks); `by the owner`
  excluded twice. `now` is the collector's own clock (`collector/pages.go` 305 hands `c.cfg.Clock.Now` to the pages;
  the Supply uses the same clock). A click during the Supply's requeue: both run on the one writer connection, so
  the click waits at most one 500-row transaction; rows already requeued are no longer `aside` and are not taken;
  rows made due mid-requeue are picked by its next chunk. Cancelled mid-statement: all or nothing (one statement).
- **No reread loop**: each answer reads the costly part and the lists at most twice in all; two tabs on the same
  question share both kept answers; two tabs on different questions each pay one costly reading per change of the
  set-aside total, no more. `nowLists` is one deferred read transaction on the `mode=ro` pool (no write lock).
- **Groups add up**: shown groups plus the "other K groups hold F files · B" line equal `failed_total`, which is
  the counts block's set-aside number (`withNowCounts`); exactly 50 groups reads the total and says no cut; an empty
  reason is a group of its own; a NULL reason cannot exist (`NOT NULL DEFAULT ''`); the owner's own reason is counted
  and shown without a button.
- **Order of controls and answers**: the click gate refuses a second request per control; a failed request
  rebuilds the region with the control enabled; an answer older than the last painted is dropped; a POST is always
  followed by a reload GET numbered after it, so a POST's answer cannot overwrite a newer GET; `focusAfter` skips
  disabled controls and never crosses kinds; a region under the pointer is patched in place, its departed controls
  disabled with fixed words, and rebuilt on `pointerleave` or the next poll.
- **Words**: `retryWhen` checked against every state of the live answer; frozen, signed out or starting accounts
  give "No account downloads now"; one paused and one running give "within seconds" (the requeue is global).
- **Tests of the fix round**: `TestRetryGroupIsOneStatement` checks the exact first 5,000 by (probable, retry_at),
  so dropping `probable` from the order or the cap fails it. `TestE2EPages` after fix 13 still proves exactly one
  estimate request on both paths, and the 202 path cannot pass on an older estimate: the chat is the one
  `approveAll` skips, so none is on record before, and the count is read after the record appears.
  `TestQueueNumbersAddUp` and `TestQueueFocusAndGroupKeys` run here: pass.
- Logs: no new log line; route errors go through `fail` with constant words. Security: both routes in `mutating`
  of `security_test.go`.

## Not looked at
- The pages in a browser, phone width, CSS; the race detector, Docker, whole-package runs.
- The rig tests (`TestPagesRetryGroupDownloads`, `TestE2EPages`, `TestPagesHold`) were read, not run; the author's
  mutations were not re-applied; `TestOpenPageStatementsBounded` and `TestQueueCostAtSize` not run (my own minute
  probe stands in).
- The requeue with several lanes calling `Next` at once; how often a server really holds 200,000 set-aside files.
- A request that hangs (no `fetch` timeout: the page stops polling while a click waits on the server's lock): this
  is older than G2 and was not measured.
