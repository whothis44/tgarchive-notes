# Notes for the archiver, 7 (fork session, 2026-11-14 ~09:30 local; not asked, written at the owner's request)

Nothing asked these; the owner asked for what would help the new app, given questions 4–6. Read-only:
- the hourly reports (`latest.txt` at 08:36 and the hourly copies), with `ix-tools/report_q6.py`;
- the database opened `mode=ro` (the rescan state and the stored media counts).

No Telegram request. Numbers only. MB = MiB; GB = 10⁹ bytes. Local time.

## 1. The overnight spell without the speed limit (extends answers 6, A.1)

The speed limit lifted at about midnight. The app counts the spell from 01:00: 8 hours, 458 GB by 08:36. The one
before was on 11-13 at 04:00: 2 hours, 137 GB.

| Hour | MB | Files | Plain waits | Speed-limit waits | Parts allowed (account) |
|---|---|---|---|---|---|
| 00:00 | 59,147 | 4,113 | 11 | 87 | 10.9 |
| 01:00 | 61,904 | 4,523 | 2 | 0 | 10.0 |
| 02:00 | 62,845 | 5,691 | 8 | 0 | 9.6 |
| 03:00 | 60,175 | 4,510 | 6 | 0 | 8.6 |
| 04:00 | 36,875 | 7,408 | 0 | 0 | 7.4 |
| 05:00 | 45,095 | 4,883 | 12 | 0 | 6.7 |
| 06:00 | 45,711 | 2,947 | 4 | 0 | 6.3 |
| 07:00 | 59,798 | 4,868 | 4 | 0 | 10.0 |
| 08:00 (36 min) | 52,174 | 2,108 | 4 | 0 | 12.1 |

- Speed at 08:36: 27.6 MB/s over 5 minutes. Today to 08:36: 41,043 files, 483,617 MB, the most of any day this
  week (11-09 had 593 GB in a whole day).
- **Per server, the complete hours of 11-14 without its own speed-limit waits** (≥ 1,000 MB that hour):

  | Server | Hours | MB | Plain waits | MB per wait | Parts in flight (median) | MB an hour (median) | Connection lost | Failed as cancelled |
  |---|---|---|---|---|---|---|---|---|
  | DC1 | 7 | 257,547 | 19 | 13,555 | 2.7 | 37,544 | 0 | 19 |
  | DC4 | 7 | 88,702 | 14 | 6,336 | 1.6 | 13,250 | 0 | 0 |
  | DC2 | 2 | 13,897 | 2 | 6,948 | 2.2 | 8,283 | 0 | 8 |
  | DC5 | 4 | 17,414 | 0 | no waits | 3.4 | 4,645 | 0 | 189 |

  "Connection lost" and "failed as cancelled" are summed over all 8 complete hours of 11-14.
- **All hours on record without the limit (11-08 to now), per server: MB per plain wait** DC1 11,169 (29 hours),
  DC4 3,350 (30), DC2 2,633 (22), DC5 66,685 (26). These replace answers 6's figures, which stopped at 11-13. The order
  of size is unchanged: **thousands of MB per plain wait, against the new app's 14.**
- **DC5's "cancelled" count is high:** 189 in 8 hours, 12–42 an hour, with no plain wait. Answers 6 explained that a
  connection dying after Telegram's acknowledgement shows here as "cancelled". The cause of these 189 was not checked.
  DC5 has no media address and has had -503 storms, so they may be something else. Treat it as an upper bound on
  deaths, not a count of them.
- **Errors in the last 24 hours:** other 12, timeout 5, file reference 1. The recent error list shows 21 -503 answers
  on the media route and 8 "context deadline exceeded".

## 2. Where the old app's files come from now (finding work, not reading more)

The owner asked how to feed the old app more. The answer, from the numbers, is that reading is done and the limit is
elsewhere. That holds for the new app too.

- **Every chat in the old app has had its history read:** 192 groups in the rescan, all past the "messages" pass.
  - 161 are fully done.
  - 26 are read but waiting for, or in, their "files" pass (one at a time). Those passes hold 135,948 messages
    and 34,423 files not yet queued, before copies are removed.
- **The files not yet queued from stored messages, unique by Telegram file, by server:** DC1 21,604 (18,751 small,
  2,853 large), DC4 2,526 (all large), DC5 257 (all large), **DC2 0**. DC2 has no files left anywhere. DC4 and DC5
  have no small ones.
- **At 08:36:** DC1's 7 file slots were all busy, with 384 more ready. DC2's slots were all empty, DC4's small slots
  empty. So more work on DC1 cannot go faster, and the other servers need files the account has not seen.
- **A gap in queueing:** the old app queues at most 500 files per pass. From 03:00 to 06:00, a files pass waited
  24–46 minutes an hour for room in the queue. Meanwhile 370, 725, 787 and 639 slot-minutes an hour sat idle.
  - The report does not say whose slots were idle. It looks like mostly DC2's (no files anywhere), so a larger limit
    would not have filled them. Not proven.
  - **For the new app:** queue per server, and never let one server's backlog stop another server's files getting
    queued.
- The idle-server feeder (queues straight from stored messages, no history read, one message refresh per file)
  queued 28,667 files since 11-13 14:42: DC1 10,827, DC4 14,714, DC5 2,226, DC2 900.

## 3. Chats the account can see but has not added: what is left

| Kind | Chats | Readable? |
|---|---|---|
| Deleted (51 private chats with deleted accounts) | 51 | no |
| Restricted by Telegram (3 of them private chats) | 48 | most likely not |
| Basic groups that became supergroups | 10 | only the history from before the move is missing |
| Channels | 26 | 20 under 20 media items, left out by rule; 6 refused (access lost) |
| **Private chats** | **21** | yes |

- **The 21 private chats were all counted on 11-13** (one stored answer each, so recounting costs nothing). 6 have
  any media: **25 photos in all, no video, no file.** Not worth adding.
- So **the old account has no unread source of any size left** among the chats it can see. More content would need
  chats the account is not in.
- **For the new app:** store each count's answer and show it. That stored answer answered this question with no
  request.

## 4. Staging copies: the backlog grows fast in a spell

- **At 08:36: 15,282 files / 217.4 GB waiting** to be copied from the local staging disk to the library on the NAS
  (over Wi-Fi). The staging disk has room for about 1 TB more.
- **Last hour:** 6,511 files / 31,019 MB copied, 8 copies at once, about 1.1 MB/s per copy. Downloads ran at
  45–63 GB an hour, so the backlog grows by roughly 15–30 GB an hour in a spell.
- **Seconds by step, summed over 6,569 copies in the hour:**

  | Step | Seconds | Share |
  |---|---|---|
  | Write | 14,682 | 52% |
  | Catalogue | 5,411 | 19% |
  | Prepare | 4,422 | 16% |
  | Read back | 1,792 | 6% |
  | Publish | 1,611 | 6% |
  | Flush | 287 | 1% |

- The average file was about 4.8 MB, and the fixed steps (prepare, catalogue, publish, flush) take about 42% of the
  copy time. So the per-file overhead, not only the link, limits copying small files.
- **For the new app:**
  - plan local staging for at least one full spell (500 GB or more);
  - batch the catalogue work instead of paying it per file;
  - order copies so big files keep the link busy while small files wait.

## 5. Copies found during the spell

**Today to 08:36:**
- the same Telegram file as one saved or queued: 10,332 files, 132,447 MB, not downloaded;
- the exact re-upload check: 645 files, 29,156 MB, not downloaded;
- the same bytes after download: 734 files, but only 57 MB, so nearly all small.

**Sampled-frame checks of big videos:**
- last hour: 1,015 checks, 8,445 MB of parts read, 140 copies and 38 partly the same;
- last 24 hours: 4,799 checks, 41,015 MB, 1,049 copies, 120 partly the same;
- 2,608 videos of 200 MB or more are waiting for a check.

**Parts kept from checks:** reused by downloads, 30,026 MB in 3,778 downloads since 11-13 14:42, with 0 refused
(0 wrong length, 0 wrong bytes, 0 unreadable). Kept now: 44,424 MB in 5,042 files.

So in a spell the checks cost about 8.4 GB of parts an hour, about 14% of what was downloaded. Part of that comes back
as reused parts.

## 6. What remains for the old account (the old app's own estimate)

- **Still to download:** 43,280 distinct files, 3,394,242 MB, plus 10,698 copies that come free with them.
- **Queue:** 58,350 files, 3,735 GB, of which 30,099 files / 1,344 GB are held as probable copies.
- **Hours without the limit needed at the measured median of 67.7 GB/h:**
  - 25 hours for the files that go first (1,686 GB);
  - 55 hours with the held copies (3,735 GB).

  The app expects about 78 such hours before the deletion, at the 5.0 a day of the last 48 hours. That is an
  estimate from 10 hours, so "looks like it fits", not a promise. It sums all servers; per server, DC1 is still the
  bottleneck (lessons 12.30, §4). I did not recompute the per-server hours today.

## 7. Load during the spell

- **CPU** 272% of one core in the last hour (152% on average over 17.9 hours). Heap in use 2,277 MB, 5,444 MB
  reserved from the system, 243 goroutines.
- **Disk:** read 452 MB/s and wrote 139,643 MB an hour in the last hour, at downloads of about 17–28 MB/s. The reads
  are about 20 times the download speed. Where they come from was not checked (staging read-back, the checks and the
  database are candidates).
- **For the new app:** count its own reads by cause from the start. The old app cannot say where these reads come from.

## 7b. Added later (11-14 ~11:40): the channels the app added by itself took the queue

The owner found the queue "filled with a group I never added", and could neither recognise nor pause it. Read-only
findings:
- **It was one of the 30 channels 12.30 added by itself (§2–3).**
  - Each was saved under a placeholder name ("Channel" and its number), although the archive knew the real names.
  - Each was created with its switch off, so the owner's lists did not show it as theirs.
- **5 of the 30 were on the owner's ranking at the bottom (places 167–171 of 171),** and every ranked group goes
  before every unranked one. Likely way in: a Priorities-page banner, "Add them to the end of the ranking", that
  offers every unranked group in the rescan, the app's included. Not proven.
- **At about 11:20 they held almost every file that could start:** 1,571 of 1,575 (615 GB). 8 of 13 downloads came
  from two of them. The owner's groups had 4 files that could start; the rest of theirs (about 54,000) are held
  copies.
- **The main app's batch Pause of about 1,000 files timed out.**
  - Every queue action matched `group_id||'_'||message_id = ?`, which no index serves: a full scan of the 361,378-row
    work table per file.
  - The table has a unique index on `(group_id, message_id)` that this form cannot use.
- **Turning the channel's photos, videos and files off did work:** the engine re-checks filters when it takes a
  file, and dropped 1,328 queued files as filtered within minutes. That is a removal: the feeder never re-queues a
  message that already has a queue row.

**The outcome (11-14, 12:07):**
- The owner judged most of the 30 junk ("terrible/useless groups … downloading trash") and switched off the downloads
  of 24 by hand. 6 were kept.
- 4,035 queued files of the switched-off ones are dropped as each comes up.
- They had brought 17,613 files (34 GB) before that, almost all unwanted.
- **The biggest lesson: a chat's media count says nothing about whether the owner wants it.** Adding chats
  automatically, with their files queued at once, spent bandwidth and attention on content the owner rejected.

**For the new app ("looks like", from one morning):**
- **Never download from a source the owner did not choose.** The app may find, count and read new chats (reading is
  cheap and costs no download). It should then propose them, with real names, sizes and a few previews, and queue
  nothing until the owner says yes.
- Mark what the app adds by itself, with real names.
- Put app-added sources in a tier below the owner's own groups, whatever the ranking says.
- Never let a bulk action on the owner's choices sweep them in silently.
- Give each group one-statement pause, move-back and drop actions.
- Test every queue action against a queue of realistic size.

## 8. In short, for the new app ("looks like", from one night)

0. **Download only from sources the owner chose (§7b).** Chats found and added automatically were mostly junk to the
   owner. Propose them; never queue them on the app's own judgment.

1. **The old app's plain waits are rare at every load seen:** thousands of MB per wait, with "connection lost" 0 in
   every hour, and the deaths it might hide bounded as above. The new app's 14 MB per wait and 759 deaths in 52
   minutes are its own; answers 6 §C has the candidates.
2. **Reading is cheap and is done; the limit is how files are spread over servers.** The old account's remaining
   work is mostly DC1, which runs full at about 37 GB an hour. Feed every server from the first day, and queue per
   server.
3. **Plan the copy side for a spell:** 60 GB an hour in, about 31 GB an hour out to the NAS here.
