# 12.29 live: first results, and how to reach the fork session (2026-11-12, 09:30 local)

For the session building the new app (and any later session on the fork). Read first, in this order:
`FINDINGS-ix12.29.md` (the diagnosis and its method), `ANSWERS-ix12.29.md` (your questions, the challenger review and
what changed after it), then this file (live results). Numbers only, read-only, from `E:\T\tg-dl\data\ixreports\latest.txt`
(report of 09:28 local, up 8h49m).

## 1. Status

- **Live:** 12.29 since 2026-11-12 00:38:36. The owner installed it by hand. 12.28 ended "clean" 34 s earlier, and
  those 34 s include building the new index.
- **Crashes:** 0 since. No "program error" in the top-up.
- **Hours without the speed limit on 12.29:** 01:00, 02:00 and 03:00. The 00:00 hour mixes 12.28 and 12.29. The
  limit came back during the 04:00 hour and has been on since.

## 2. What the top-up does now (measured, since start)

| | 12.28 (11-11) | 12.29 |
|---|---|---|
| A minute's step queueing its files | ~26 s (lookup walked every row) | 16 files in 1.9 s (first hour) |
| Copy check of the step's videos | ~28 s, blocking the step and quick looks | 12.9-17.7 s, running beside the quick looks |
| Read of the saved messages | 22.1 s | 2.6 s (cause not established: fewer rows to decode, or a warm cache) |
| Files queued by the top-up | 4,175 in 18 h (DC2 1,984, DC4 988, DC5 1,203) | 6,560 in 8.8 h, nearly all in 3 unlimited hours (DC2 756, DC4 2,787, DC5 3,017) |

- **Steps:** 312 minute steps and 998 quick looks. The quick looks queued 2,285 files (DC2 337, DC4 971, DC5 977).
- **Refused, by why (counted for the first time):**
  - 3,438 had the same Telegram file saved or queued: copies by Telegram file, the bulk;
  - 2,267 were saved, queued or deleted meanwhile;
  - 270 were refused by the group's filters.
  
  This answers question C of the stopgap: most refusals are copies by Telegram file, which the read of the saved
  messages does not exclude (it excludes by message only).

## 3. Speed, in hours without the speed limit only (GB an hour)

| Hour | All | DC1 | DC2 | DC4 | DC5 |
|---|---|---|---|---|---|
| 11-11 18:00 (12.28) | 65.2 | 28.3 | 5.9 | 17.9 | 13.6 |
| 11-11 19:00 (12.28) | 72.3 | 33.0 | 12.5 | 22.4 | 7.2 |
| 11-11 20:00 (12.28) | 74.6 | 40.4 | 9.7 | 22.0 | 3.9 |
| **11-12 01:00 (12.29)** | **72.9** | 32.1 | 1.1 | 23.7 | 18.7 |
| **11-12 02:00 (12.29)** | **70.2** | 38.7 | 0.0 | 24.0 | 7.5 |
| **11-12 03:00 (12.29)** | **71.4** | 41.9 | 0.0 | 26.6 | 4.0 |

Read it as "looks like", three hours against three:
- **DC4 is up**, about 24-27 GB against 18-22. Its room unused ("nothing in the way") is 10% at 01:00 and 02:00,
  against 17-23%.
- **DC5 got fed:** 18.7 GB at 01:00, its best hour in these tables. It is still mostly a -503 server (F), and fell
  back as its list emptied.
- **DC2 ran out of files.** This is the important new fact. Its list from the saved messages had 1,798 small and 446
  large files. The top-up queued 756 of them and refused the rest, mostly as copies by Telegram file. 84 small and
  120 large are left that it cannot take now: band, big-file lane, or waiting on a better-ranked video. The report
  counts "DC2 no files left" in 369 minute steps. DC2 brought 10 MB at 02:00 and 0 at 03:00. The early re-read never
  fired (0): it needs new messages saved since the last read, and none were.
- **The total is about the same** (70-73 GB). DC1, with 1,470 large files that could start, is window-bound, not
  feed-bound, and DC4 and DC5 gained what DC2 lost.

**So the top-up is no longer the limit.** It now uses up, within hours, what the saved messages hold. What is left
for DC2 (and soon DC5) is either:
- copies already saved or queued, which are held at the back by design; or
- files in messages not read yet. Those come only from the rescan's files pass, which reads history from Telegram
  and waits on the 500 queue limit. Changing that adds Telegram requests and needs the owner's OK.

Measuring which of the two is next.

## 4. Other things in the same report

- **Staging (separate from 12.29):** copies to the library still fail in bulk: 5,667 failing "since 3h3m". But
  1,752 files (43 GB) were copied in the last hour, and the backlog fell from 198 GB (00:53) to 139 GB. The cause of
  the failures is not known. It started under 12.28 at about 22:20 on 11-11.
- **Under the speed limit since 04:00:** 0.02-1.3 GB an hour. That is Telegram's limit; 12.29 changes nothing there.

## 5. What was changed (where to read it)

- **Repository:** `whothis44/telegram-media-downloader` (the public fork), branch **`ix/v12.29`**, commit
  `34d051e`, tag `v3.4.18-ix.12.29`. Draft CI-only PR: https://github.com/whothis44/telegram-media-downloader/pull/41
  (never merge).
- **Local checkout:** worktree `C:\Users\trabi\Claude\Projects\Telegram\repo-v12.16`, which the fork session works in.
  Read it with `git -C ... show 34d051e` or `git -C ... diff 999a4af 34d051e`. **Do not switch its branch or commit
  there.** `repo-archiver/core-service` holds an older copy of the fork.
- **Files:**
  - `core-service/internal/app/ix_topup.go`: the loop (`ixTopUpLoop`, `ixRunTopUp`), the quick looks
    (`ixTopUpStepKind`, `ixTopUpRun`), the copy check handed off (`ixTopUpStepCheckLater`), refusal reasons
    (`ixTopUpOne`), and the report text (`ixTopUpQuickText`);
  - `core-service/internal/store/migrate.go`: index `idx_tgdl_work_identity_any`;
  - `core-service/internal/app/ix_safety.go` and `ixassets/ix.html`: the setting `topUpFastOff`;
  - tests: `core-service/internal/app/ix1229_topup_test.go` (eight cases, all with invented data).
- **Changelog:** the 12.29 entry in `CHANGELOG.md`. It also corrects 12.28's stated cause.

## 6. Lessons worth carrying into the new app

1. **Measure "unfed" directly.** The report's "room unused" counts any 10 s sample with spare window. Count a
   server's files in the queue over time from `created_at` and `updated_at`, and find the files queued but paused.
2. **Index every "do we already have this Telegram file?" lookup, for every status.** At 240,000 rows, a table walk
   cost 2-2.8 s per file and stretched each step to ~26 s.
3. **Never make freshly queued files wait for a whole-queue copy check while holding the locks the feeder or the
   slot fill need.** Run the check beside them, and exclude the feeder's own files awaiting the check from "set-aside
   files go first".
4. **List candidates by Telegram file, not by message.** More than half of the refusals were copies the list could
   have left out.
5. **A feeder that works exposes the next limit.** Here it is the supply of unique files per server: DC2 had about
   750 unique files left in what the archive had read. Plan for discovery (reading history) as the next bottleneck,
   with its Telegram cost counted.
6. **Compare like with like.** Hours without the limit against hours without the limit. Three against three is
   "looks like".

## 7. How to reach the fork session

- **This session:** named **`Telegram fork STOPGAP-ix12.29`** in `ListAgents` on this computer (its name has changed
  once; check `ListAgents` first). Send with `SendMessage({to: "Telegram fork STOPGAP-ix12.29", message: "..."})`.
  Put the question in the first line.
- **If it is not running:** write a file next to this one, for example `QUESTIONS-for-fork.md`, and ask the owner to
  point the fork session at it. Every answer goes back as a file in this folder.
- **The owner decides** pushes and releases of the fork. Questions are welcome. Instructions to change the fork go
  through the owner.
