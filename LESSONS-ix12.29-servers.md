# Lessons from the fork, 2026-11-13: what limits each Telegram server (DC), and a window that never grows

Written for any assistant building a downloader on **gotd** (the new app in `repo-archiver`, or the fork itself).
Source: the fork's hourly reports (numbers only), its database (read-only, counts only) and its code at 12.29
(`repo-v12.16`, commit 34d051e). The account has no Premium and has been frozen since 2026-10-31. "Unlimited hour" means
an hour without Telegram's speed limit for non-Premium accounts (FLOOD_PREMIUM_WAIT). Times are local (EST).

The fork's code is the reference for every rule quoted here: `core-service/internal/telegram/pacer.go` (per-server window),
`floodguard.go` (Telegram's waits), `internal/app/ix_topup.go` (feeding idle servers).

---

## 1. A server can run out of files. Measure supply per server before tuning anything

**Finding (11-13):** in unlimited hours DC2 sat 100% idle and DC5 56–96% idle. That was not a feeding bug. They have
almost no unique files left.

- Saved messages whose file is neither downloaded nor queued, counting only files that are **not the same Telegram file**
  (same document or photo id) as one already saved or queued:

  | Server | Unique files left | Size |
  |---|---|---|
  | DC1 | 14,354 | 182 GB |
  | DC4 | 6,407 | 106 GB |
  | DC5 | 329 | 22 GB |
  | DC2 | 208 | 8.7 GB |

- All 162 groups have had their messages read. Reading history again would not find files for DC2 or DC5.
- **How it was measured (no Telegram requests):** the fork stores each message's raw TL (`ix_messages.tl`). Decode it with
  gotd (`var m tg.Message; m.Decode(&bin.Buffer{Buf: tl})`) and take `Document.DCID` or `Photo.DCID`, the size, and the id.
  Count copies by Telegram file id, not by message: more than half the candidates were the same file as one already saved.
  The whole read (about 32,000 messages decoded) took 2 s.
- **For the new app:** keep a per-server count of unique files not yet downloaded and show it. When a server's supply is
  near zero, its idle time is the end of its supply. A smarter scheduler can't recover it. Only discovering new chats or
  messages can.

## 2. Under the speed limit, the bytes are set by Telegram, per server

- Since about 11-10 16:00, each server brings about **190 MB an hour** under the limit (DC1 and DC4 ~170–200, DC5 7–150,
  DC2 ~0 because it has no files). Each FLOOD_PREMIUM_WAIT asks about 15–16 s.
- More parts in flight do not bring more bytes under the limit. They only bring more waits (the fork caps each server at
  2 parts while limited, from 12.21).
- Whether one wait holds only its own request or every file waits for it made **no measurable difference** in bytes
  (11-11). It only changed the number of refusals.
- Quick check of which conditions an hour was in: **MB per speed-limit wait**. Before 11-10 16:00 it was ~0.9; after, ~0.45
  with per-request waits.
- Volume comes almost entirely from unlimited hours: 60–100 GB an hour, against ~0.4–0.8 GB an hour under the limit. In
  the last 2 days, 12 of 47 hours had no limit.

## 3. In unlimited hours, a part is answered in about 0.3 s. Bytes then follow the parts in flight, up to a point

- Parts are 1 MiB. One part in flight brings about **3.5–4 MB/s** ("KB per slot-second": DC4 3.4–4.6 MB/s in all 22
  unlimited hours since 11-08, steady).
- **DC4 sat at 2 parts in flight in nearly every unlimited hour**, at the 2-part floor 70–100% of the time with 5–18 parts
  waiting for room. So it brought 2 × ~3.7 MB/s ≈ 7–8 MB/s, or 20–30 GB an hour.
- **DC1 climbed to 3–4 parts but did not bring more bytes than at 2:** 42.6 GB at 2.0 parts (11-08 17:00, 6.3 MB/s per
  part) and 33–41 GB at 3–4 parts on other days (2.7–3.8 MB/s per part). So more parts per server may only split a
  per-server ceiling of about 11–12 MB/s. This comes from different days, so treat it as "looks like", not proof.
- **Unknown, and the next thing to measure:** whether DC4 would bring more with 3–4 parts. If it reached DC1's ~11 MB/s,
  that would add about 14 GB in each unlimited hour (~20%). That is an upper bound, not a forecast.

## 4. The trap: a 1-second FLOOD_WAIT stops a server growing for 2 hours

The fork's pacer (`pacer.go` `tick`) reacts to any plain FLOOD_WAIT on a server's file parts like this:

1. It cuts the window ×0.6. Since 12.19, a wait shorter than 10 s (`plainEscalateWait`) never cuts below 2.
2. It sets a **ceiling** at `max(3, window)` for 10 minutes. No try may reach the ceiling (`window+1 >= ceiling` blocks the
   climb).
3. Two such cuts within an hour make the ceiling last **2 hours** (`paceFallbackCuts`, `paceFallbackFor`).

At 2 parts the ceiling is 3, so **any plain wait at the floor forbids a third part**: for 10 minutes after one wait, and for
2 hours after two within an hour. DC4's plain waits are tiny:

| Hour | DC4 plain waits | Seconds asked in all |
|---|---|---|
| 11-13 04:00 | 116 | 158 (~1.4 s each) |
| other hours | 1–9 | 1–13 (about 1 s each) |

**The evidence across 22 unlimited hours since 11-08:**
- Every unlimited hour that followed one with **two or more DC4 cuts at 2 parts** had **no try at all** and sat at the floor
  97–100% of the time: 11-08 17:00 and 19:00, 11-09 05:00 and 15:00, 11-10 14:00, 11-12 01:00, 11-13 05:00. That is 7 of 7.
- The two hours after cuts that came while DC4 was **above** 2 (ceiling 4) did try (11-11 21:00: 4 tries; 11-11 23:00: 8).
  That fits the rule too.
- The fork's notes from 12.17 say DC4 was asked to wait as often at ~1.1 parts as at 2 (58–76 an hour). So **its waits do
  not come from its window**, and the ceiling punishes it for something more parts did not cause.

**Lesson for any pacer:** scale the reaction to the wait.
- A wait of about 1 s at the floor says nothing about the window. It should not set a ceiling, and it should not count
  towards a long penalty.
- Keep ceilings for longer waits, or waits that grow, or waits that came right after a climb.
- Record each reaction (cuts, ceilings, tries, share of time at the floor) per server per hour. Without those counters
  this cost would have stayed invisible. The report showed it only as "at the 2-part floor 100%".
- **Two traps found by the fork's review of its own fix (12.30, 11-13):**
  - **Judge the parts in flight when the wait came, not the window afterwards.** A try from 2 to 3 that is taken back
    leaves 3 parts in flight for a moment. A wait answering one of them belongs to the try, so it should still set the
    ceiling.
  - **Check the server's own speed-limit waits from the last minutes, not only the "capped" flag.** A server already at 2
    parts is never capped, but it is still under the limit.
- An exemption should never shorten a longer hold already running, such as the 2 minutes after a try taken back.

## 5. Judging a bigger window by bytes over one minute is noisy

- When DC4 was allowed to try 3 parts, bytes kept **15 of 37 tries**. Judging by answer time would have kept most of the
  other 22.
- The rule needs +25% speed over six 10-second samples to keep a step from 2 to 3. Those samples move with Telegram's
  load, the other servers and the VPN.
- A kept climb rarely lasted: the next tiny wait cut it and set the ceiling (section 4).
- **For the new app:** judge a climb over a longer stretch, or by time per part (parts a second = parts in flight ÷ time
  per part). Then check it against bytes a few minutes later, as the fork's `paceCheckAfter` does. The user has chosen to
  keep judging by answer time off in the fork. Do not reverse it there.

## 6. Method lessons (cost the most time when ignored)

1. **Compare like with like:** unlimited hours against unlimited hours, close in time. On 11-11 a slowdown was blamed on
   the fork's own fallback. It was Telegram halving its allowance at the same time.
2. **A feeder that works exposes the next limit.** 12.29 fixed feeding idle servers in seconds. Within hours DC2 ran out
   of unique files.
3. **Measure "unfed" directly.** "Room unused" counts any 10 s sample with spare window. Count files per server and why
   each server got nothing ("no files left", "-503 storm", "plain wait", "speed limit").
4. **Decode what you already stored before asking Telegram again.** The saved TL answered which server each file is on,
   and whether it is a copy, with zero requests.
5. **Count every wait, its length and its reaction, per server per hour.** The DC4 trap was found only by putting "cuts",
   "tries up", "at the floor %", "plain waits asked N s" side by side, hour by hour.

## 7. More lessons (added 2026-11-13 afternoon)

### Finding content is a job of its own, and it should run by itself
- **On 11-13, 56 channels the account could already read had never been added to the archive.** They held about 33,500
  photos and 18,700 videos, roughly 0.5 TB before copies. Counting them needed a click per chat, so for two weeks nobody
  did it.
- **Counting is cheap.** One `messages.getSearchCounters` request per chat returns photos, videos, files and audio.
  - The frozen account had all 86 counts answered in under 2 minutes, none refused as frozen.
  - 6 answered CHANNEL_PRIVATE: access had been lost.
- **For the new app:** at start, and every half hour, compare the chats the account can see with the chats being
  archived. Count each new chat once, then add the ones worth it, biggest first, without waiting for a person.
  - The fork's 12.30 does this. It skips chats with fewer than 20 media items.
  - Keep refusals and never ask for them again.
  - A Telegram wait ends the step, and the next step comes after the wait in full.
- **Respect the owner's removals.** Never add back a chat the owner took out. The fork knows one by the messages it
  kept from it, plus a list of the chats it added by itself.

### Plan by server, not by account
- Adding up all servers' GB per hour hides the bottleneck. On 11-13 the account brought ~65 GB per unlimited hour, but:
  - DC2 had nothing left to download and DC5 almost nothing;
  - DC1 alone needs ~17 unlimited hours for its unique files, and ~44 with its held probable copies.

  The account-wide view gave 11–12 hours for all unique files, which was wrong.
- New sources are worth most when their files sit on idle servers. Every stored message record names its file's server:
  325,671 of 325,671 in the fork, read with gotd in 1.5 s. So per-server supply can be planned with no request at all.
  **Keep the raw message record.**

### Copies dominate. Find them before downloading
- Of the 89,323 files the fork has seen but not downloaded, about 72% are the same Telegram file as another (19,150) or
  held as probable copies (45,517).
- Sampled-frame checks of big videos: 20,850 done, 5,590 matched. They read 171 GB of parts instead of 3,031 GB.
- **Keep the parts a check reads:** downloads later reused 8.9 GB of them in 1,129 files, with none refused.
- Checks run 150–950 an hour without the speed limit and about 5–16 an hour under it.
- For a first size estimate, use the archive's own averages: 27.5 MB per video and about 0.1 MB per photo in the fork.

### Waits are mostly short
- Plain FLOOD_WAITs on file parts in unlimited hours since 11-08 averaged 1.3 s on DC1, DC2 and DC4 (74, 55 and 154
  waits). DC5 had only 3, but they averaged 39 s.
- So any rule that reacts to "a wait" should look at its length first (section 4).

### Count what you will be asked about
- The fork could not say, per Telegram method, how many requests and waits it had: getHistory, getDifference,
  getMessages and so on. It also kept no split of wait lengths.
- **Record from day one, per method and per hour:** requests, waits, seconds asked (smallest, median, largest) and
  refusals by error code.

### Working on a live machine
- **Query a live database in one pass.** A query with a correlated `EXISTS` on an unindexed column ran over 5 minutes
  and had to be stopped. Reading the one table once and joining in memory took 3 s.
- **Cap test containers** (`docker run --cpus 1.5`) and never overlap them with other test runs. An uncapped race run
  took 6 of the 12 logical cores and the PC to 99% next to the live archive.
- **Have an independent reviewer check every pacing change before release.** For 12.30 the review found two traps that
  the tests had missed (section 4).

### Automating an owner's action: what the fork's review caught (12.30, 11-13)
The fork's first automatic count-and-add of chats looked right and passed its tests. An independent review then found
ten problems, five of them confirmed by probe tests. Build these in from the start:

1. **Never undo a person's pause.** The automatic add copied the UI button's "start the rescan" rule, which restarted a
   rescan the owner had paused. Start only work that is already running or has finished, and keep "paused by a person"
   as its own state.
2. **Judge "the owner took this out" from every trace, not one.** Checking only "messages kept" missed chats taken out
   before their first history read, chats with only files, chats with a rank or a queue entry, and a migrated group's
   successor. Keep a durable record of everything that was ever in scope, and treat leaving it as a decision.
3. **Give the owner a per-item "never" switch** (the fork's "Never add"), not only a global off. Check it again before
   every request and every action, so a click during a run counts at once.
4. **Persist Telegram's waits.** A FLOOD_WAIT kept in memory is forgotten at a restart, and the app asks again too early.
   Store "not before" and check it at the top of every step.
5. **Sort errors into permanent and passing.** Make only "this account can't read it" refusals permanent: CHANNEL_PRIVATE,
   CHAT_FORBIDDEN, CHANNEL_INVALID, PEER_ID_INVALID and FROZEN_METHOD_INVALID. A wait, a lost connection or a
   timeout passes. Retry those later, a few times at most.
6. **Bound costly failures.** Resolving a chat whose access hash isn't cached can mean listing the account's whole chat
   list (getDialogs). Let one such failure end the step instead of hitting it 40 times in a row.
7. **Act one item at a time.** A batch call that fails half-way leaves items half-done that later rules then treat as
   finished. Do one item per call, record each success, and move on past a failure.
8. **Release shared flags with `defer`.** A "busy" flag set without `defer` stayed set after a panic and blocked the
   owner's own button until the next restart.
9. **Don't spend requests on items you will never act on.** The first version counted chats it would never add.
10. **Cap each step** (the fork adds at most 10 chats per half hour), so a backlog doesn't arrive all at once.
11. **Lock read-modify-write of a stored set.** The fork stores its "Never add" marks as one JSON list. In the third
    review's probe, two clicks at once lost 81 of 150 marks, and every request still answered 200. Use one lock for all
    writers, or one row per item.
12. **A person's mark must follow the item across identity changes.** A basic group marked "never" that becomes a
    supergroup has a new id. Apply the mark through the migration link.
13. **Fail closed.** If the marks can't be read, stop the automatic step rather than act as if nothing were marked. A
    corrupt stored value must not read as "empty", or the next click overwrites it and every mark is gone.

Also: **re-run tests only after the code has stopped changing.** A race run started while the feature was half-written
reported a build error that meant nothing.

### Stored file references go stale, so refresh in batches
- The fork refreshes a file's message right before downloading it. In the first 9.6 h of the run that started
  11-12 23:44 it made 3,317 refreshes, and **every one came back with a changed file reference** (0 the same). The 12.23 measurement found the same
  (129 of 129). A reference stored at reading time is never usable later.
- So each file costs at least one extra request before its first part. The fork asks once per file.
- **For the new app:** don't plan on stored references. Refresh just before downloading, and **in batches**:
  `channels.getMessages` and `messages.getMessages` take a list of ids, so the files about to start from one chat can
  share one request. The same request then serves as the check that the message still exists.

### On a deadline, switch measured-safe improvements on by default and judge them against recorded hours
- The fork first built its 12.30 pacing fix as a switch, off by default, to be tried by flipping it in unlimited
  hours. The owner asked why it wasn't on. With unlimited hours coming a few times a day and 16 days left, a switch
  nobody flips in time helps nothing, and flipping it on and off for an A/B test isn't practical.
- What made switching it on safe:
  - every wait is still slept in full;
  - a bigger window that brings nothing is taken back within a minute;
  - **22 unlimited hours of per-server numbers were already on record**, so the new hours can be compared with them
    instead of with a parallel test.
- **Build the measurement into the change.** 12.30 counts every wait it lets through ("short waits at 2 parts or fewer
  with no ceiling"), so the report shows whether the new rule fired, and how often.

### Let reviewers prove their findings without touching the code
- The fork's reviewers wrote their probe tests in a scratch folder and loaded them with `go test -overlay`, so the
  working tree was never edited and every finding came marked CONFIRMED or PLAUSIBLE.
- Across three reviews of 12.30 this confirmed: a paused rescan restarted, chats taken out added back, marks lost to
  two clicks at once, and a busy flag stuck after a panic. All the tests had passed before each review.
- Give each reviewer a CPU budget, no Docker and no whole-package runs, so a review can run next to the live app.

### Forecasts must count what isn't queued yet, server by server
- The fork's own report said the files that go first need "5 h" of unlimited hours. That counted only files already
  queued and left out about 21,000 unique files sitting in saved messages.
- Counted per server and including those files, DC1 alone needs about 17 unlimited hours. Any forecast that drives a
  decision should state what it leaves out.

### Make checks fail fast and say why
- One browser check waits up to 10 minutes for a viewer server that only CI starts. Run locally, it looked like a
  hang, then a failure.
- A check that needs a server should start it itself, or fail within seconds saying what is missing.

## 8. Not known yet
- Whether DC4 (or any server) brings more bytes at 3–4 parts than at 2 in an unlimited hour.
  - The fork's 12.30 (built locally 11-13, not yet released) stops a wait under 10 s at 2 parts or fewer from setting a
    ceiling. It is on by default, with a setting to switch it off.
  - It will be judged on DC4's GB per hour, plain waits per hour and share of time at 2 parts across several unlimited
    hours, against the 22 hours on record from 11-08 to 11-13.
  - Every wait is still slept in full.
- Why DC4 gets ~1 s FLOOD_WAITs at all (116 in one hour on 11-13, 0–9 in most). Half of DC4's parts go to its media
  address. Whether the waits come from one route was not checked.
- Why DC1's bytes do not scale above 2 parts (a per-server ceiling, the VPN, or the day's conditions).
