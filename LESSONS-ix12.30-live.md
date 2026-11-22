# Lessons from the fork's 12.30 rollout (live notes, 2026-11-13 from 14:50 local)

For the new app's assistant. A companion to `LESSONS-ix12.29-servers.md`. Numbers only, read-only, from the fork's
reports and database. A **draft that grows** as 12.30 runs. The finished version follows after a few more hours.

---

## Added 11-14: the day's lessons, in short (details in §6b–6d and §7, items 11–15)
1. **Download only what the owner chose.** The 30 chats 12.30 added by itself were mostly junk to the owner (24 of
   30 switched off). Find and propose; never queue on the app's judgment. (§6b)
2. **Plan for the chosen content running out.** In a 14-hour unlimited spell the owner's groups were finished by
   mid-morning; the rest of the spell can only go to probable copies, so order those by how likely each is
   distinct. (§6c)
3. **A frozen account sees nothing posted after the freeze.** Read each chat once; plan no rescans. (§6c, answers 8)
4. **The frame check's "copy" is reliable; its "no match" often is not** (answers 8). Never let a "no match" release
   or pass a file on its own.
5. **Per-group and bulk queue actions must be single, indexed statements.** On 11-14 pausing 1,000 files timed out
   because each one walked the whole queue. (§6b)
6. **Things outside the app share the copy link.** Measure it alone once, and show the copy speed live. (§6d)

## Ranked: what the new app most needs to know (my judgment, 11-13 evening)

Ranked by how much each one changes **the amount of distinct content saved before the deadline**, with the evidence
behind it. "§" points to sections below; "29-§" to `LESSONS-ix12.29-servers.md`.

1. **Plan, pace and order per Telegram server, not per account.**
   - The account's total hides the bottleneck. Today DC1 needs about 65 unlimited hours for its unique files, while
     DC2/DC4/DC5 need 4–15.
   - DC1 brings about 11–12 MB/s whatever its window. Each server's allowance under the speed limit is about
     190 MB/h, and these allowances are separate.
   - So what finishes is decided by **the order of the bottleneck server's queue.** That is where ranking matters,
     and where the owner's choices should be asked for.
   - Keep the other servers fed so their allowance isn't wasted: DC2 sat idle for a day, empty of files.
   - Evidence: §4, 29-§1–3, 29-§7 "Plan by server".
2. **Read every chat's history early. Counts and averages mislead.**
   - Reading is cheap (about one request per 100 messages) and gives the truth: each file's size, its server and
     its Telegram id.
   - Counted media times the archive's average said about 0.5 TB. Reading 6 of 30 channels found about 1.7 TB more
     unique content, mostly on DC1.
   - Store every message record: the server of every file comes from it, and so does the free first copy check.
   - Evidence: §1.
3. **Find copies before downloading.**
   - About 72% of the files the fork has seen but not downloaded are the same Telegram file as another, or held as
     probable copies.
   - Same-id matches are free. Sampled-frame checks read 171 GB instead of 3,031 GB, and the parts they read get
     reused by the downloads (8.9 GB so far).
   - At this deadline the bandwidth saved is worth more than almost any speed tuning.
   - Evidence: 29-§7 "Copies dominate".
4. **The speed limit sets the pace most hours. Unlimited hours bring the volume, so be ready for them.**
   - Under the limit: about 0.4–0.7 GB/h for the whole account. Without it: 60–100 GB/h.
   - Unlimited hours come in irregular spells, about 6 a day on average (a 10-hour spell, then none for 24 hours).
   - When one starts, every server must already have work queued.
   - Under the limit, more parts in flight only bring more waits (the fork caps each server at 2).
   - Evidence: 29-§2–3, 29-§6.
5. **React to a Telegram wait by its length. Never bypass one, and persist it.**
   - Plain FLOOD_WAITs on file parts average about 1.3 s on DC1, DC2 and DC4.
   - A rule that treats every wait as a reason to cap a server for 2 hours kept DC4 at 2 parts in nearly every
     unlimited hour.
   - Whether removing that cap helps DC4 is not yet measured: §"Still to come".
   - Keep waits across restarts.
   - Evidence: 29-§4, 29-§5.
6. **Know what the frozen account can still do.**
   - It reads history, counts media and downloads parts with no frozen refusals.
   - `channels.getFullChannel` is refused.
   - 6 of 86 visible channels answered CHANNEL_PRIVATE: access lost.
   - Stored file references are always stale: 3,317 of 3,317 had changed when refreshed. So refresh just before
     downloading, in batches.
   - Evidence: §1, 29-§7.
7. **Automate the owner's chores, but never against the owner, and never their choices.** On 11-14 the 30 chats the
   app added by itself filled the queue, and the owner switched off 24 of them as junk (§6b). Propose new sources;
   download only what the owner chose.
   **Original text (11-13):** Automate the owner's chores, but never against the owner.
   - Respect a pause.
   - Treat a removal as a decision: judge it from every trace, and keep a per-item "never".
   - Fail closed when the stored state can't be read.
   - Lock read-modify-writes.
   - Reuse what the owner already did.
   - Three reviews found all of these after the tests had passed.
   - Evidence: §2, 29-§7 "Automating an owner's action".
8. **Measure before believing, and attribute effects.**
   - Compare like with like (unlimited hours with unlimited hours, close in time).
   - Check per file where the bytes came from: §3 shows a convincing coincidence.
   - Count requests and waits per method from day one, and write a JSON status beside the human report.
   - Evidence: §3, §6, 29-§6.
9. **Engineering hygiene, which costs hours when ignored.**
   - Use injected clocks and stop background loops in tests.
   - Cap CPU for tests and reviews next to a live app.
   - Have reviewers prove findings with probe tests.
   - Ship the build CI already tested.
   - Evidence: §5, 29-§7.

Not ranked, as they mattered little to the outcome here: install downtime (33 s), memory and CPU (unchanged by 12.30).

---

## 1. Read every chat. Counting is not enough

**What happened:**
- 56 channels the account could already read had never been added to the archive.
- On 11-13 the owner counted them (one `messages.getSearchCounters` request each): about 33,500 photos and 18,700
  videos.
- Multiplied by the archive's average file size (27.5 MB a video), that looked like **about 0.5 TB before copies**.

**Then 12.30 added 30 of them to the rescan, and the app started reading their history.** By 15:58:
- 6 of the 30 had been read: 81,303 messages, 49,229 with media. No refusal: the **frozen account can read newly added
  channels' history**.
- The unique files found in saved messages but not yet queued grew from about 319 GB to about **2 TB**.
  "Unique" means not the same Telegram file as one already saved or queued.

| Server | Before (unique files / GB) | After |
|---|---|---|
| DC1 | 14,354 / 182 | 44,046 / 1,636 (large videos: 1,594 / 150 → 4,523 / 1,577) |
| DC4 | 6,407 / 106 | 17,475 / 291 |
| DC2 | 208 / 9 | 1,778 / 41 |
| DC5 | 329 / 22 | 1,667 / 62 |

24 of the 30 channels were still unread at that point.

**So the count-based estimate was off by a factor of 4 or more**, and the real size appeared only after reading. These
channels' big videos average about 350 MB, against 27.5 MB for the archive overall.

**For the new app:**
- **Read the history of every chat the account can see, as early as possible.** It is cheap: about one request per 100
  messages, and no file downloads.
- Treat media counts and size averages as a rough guide to which chats to read first, never as the plan.
- Find the real size, the server of each file, and the copies from the messages themselves, before deciding what to
  download.
- Store every message record. The server of each file comes from that record.
- Re-plan after each read, per server. Here almost all the new content sits on DC1, the server that was already the
  bottleneck: DC1's unique files alone now need about 65 unlimited hours, of the 90–100 expected before 11-29.
- Do this from the first day. The fork found these chats with 16 days left.

## 2. Automate the owner's chores, and reuse what the owner already did
- 12.30 counts and adds not-added chats by itself: one count per chat, at most 10 adds every 30 minutes, never a chat
  the owner took out or marked "Never add".
- **First three rounds (14:52–15:52):** 30 channels added, 0 refused, 0 Telegram waits, and **0 count requests**,
  because all 70 readable chats had already been counted by the owner's clicks and the automation read the same stored
  answers.
- Left out: 20 chats under 20 media items, and 6 that answered CHANNEL_PRIVATE (access lost).
- Lesson: keep the results of manual actions in the store the automation reads, so no work or request is repeated.

## 3. Check where bytes came from before crediting a change
- At 15:00 the idle server DC2 brought 207 MB after a day at 0, and all servers together 668 MB, against the usual
  380–410 under the speed limit. It looked exactly like "the new channels fed the idle server".
- **That was wrong.** Checked file by file: all 4 DC2 files (718 MB) belonged to an older group that the rescan reached.
  The new channels had no queued files yet, and the idle-server feeder had queued nothing.
- Lesson: attribute bytes per file or work row before claiming an effect. Coincidences in the same hour are common.

## 4. Forecast per server, from what is read, not only what is queued
- The fork's own deadline line at 16:19, all servers together at 72.5 GB/h: unique files 26 h (1,917 GB), with the
  probable copies held 52 h (3,756 GB).
- Per server, the same files need **about 65 h on DC1 alone**. An account-wide forecast understated the bottleneck server
  by more than half.

## 5. Releases and installs
- **The release build re-tests on a fresh machine,** and two different old timing tests failed there in a row. They had
  passed in CI on the same commit an hour earlier, 200 of 200 and 100 of 100 locally. The third attempt passed, after
  about 25 minutes and two re-runs.
  - One test had a 30 ms timeout recorded as slightly less than 30 ms.
  - The other had a "check now" racing the test app's own background update check.
  - Lessons: use an injected clock, stop background loops in tests, and preferably ship the build CI already tested.
    A tag can't be moved, so a test fix found at release time costs a new version number.
- **Installs:** the hourly update check can take up to about 1.5 h to find a release. The owner installed by hand in
  minutes: 33 s from stop to start, and the old version ended clean. Lesson: offer "install now" and record each
  update's downtime.

## 6. Monitoring
- **The fork's report is prose only.** A watcher of mine mistook "in 10 min" for the count and raised a false "speed
  limit lifted". Lesson: write a small JSON status file beside the human report, and have scripts read that.
- **The report file is rewritten about every 10 minutes.** Wait for events (the speed limit lifting, a step finishing),
  not for file changes.
- **12.30's load matches 12.29's:**

  | | 12.30 | 12.29 |
  |---|---|---|
  | CPU, one core | 72–106% | about 97% |
  | Reads | 101–130 MB/s | about 135 MB/s |
  | Heap in use | 1.8–1.9 GB | 1.7–2.6 GB |

## 6b. What the app adds by itself must stay visibly the app's, and below the owner's choices (11-14)

**What happened, the morning after an 8-hour unlimited spell:**
- The owner saw the queue "filled with a group I never added", choking the groups they wanted. It was one of the 30
  channels 12.30 added by itself (§2).
- **The owner could not recognise them.**
  - Each was saved with a placeholder name, "Channel" and its number, although the archive knew the real names.
  - Each was created with its switch off ("monitored only" in the main app), so it was missing from the owner's
    archive list.
- **5 of the 30 were on the owner's ranking, at the very bottom (places 167–171 of 171).** Every ranked group goes
  before every unranked one.
  - The likely way in: the Priorities page offers "N group(s) in the rescan are not ranked … Add them to the end of
    the ranking". That counts the groups the app added. Not proven: the ranking is rewritten whole on each save, so
    when they were added is lost.
- **With the owner's own groups out of new files, those channels took nearly everything.**
  - At about 11:20: 1,571 of 1,575 files that could start (615 GB) were theirs, and 8 of 13 downloads came from two
    of them.
  - The owner's groups had 4 files that could start and 95 set aside. The rest, about 54,000, are held copies, which
    by rule wait for every new file.
- **Pausing failed.** The main app's batch Pause on about 1,000 files timed out.
  - Each queue action (pause, resume, cancel, retry, remove) matched `group_id||'_'||message_id = ?`. No index can
    serve that, so every file was a scan of the whole work table (361,378 rows).
  - 1,000 files meant 1,000 full scans.
- **What worked:** turning off the channel's photos, videos and files in the main app. The engine checks the filters
  again when it takes a file, and dropped 1,328 of that channel's queued files as filtered within minutes.
  - That is a removal, not a pause.
  - The feeder never queues a message that already has a queue row, so getting them back needs a rescan of that
    channel. Not checked.

**The outcome:**
- By 12:07 the owner had switched off 24 of the 30 by hand, calling them "terrible/useless groups … downloading
  trash". 6 were kept.
- 4,035 of their queued files are dropped as each comes up.
- Before that they had brought 17,613 files (34 GB).
- **A chat's media count is no measure of whether the owner wants it.** §2's lesson ("automate the owner's chores")
  went too far: counting was the chore, choosing was not.

**For the new app:**
0. **Never download from a source the owner did not choose.** Find, count and read new chats freely. Then propose
   them, with real names, sizes and a few previews, and queue nothing until the owner says yes.
1. **Mark everything the app adds by itself as the app's, with its real name,** everywhere the owner looks.
2. **No bulk action on the owner's choices** (ranking, priority, keep) may sweep in what the app added without
   saying so and letting the owner leave those out.
3. **Per-group actions — pause, move to the back, drop — must be one statement each,** tested at the queue's real
   size (hundreds of thousands of rows).
4. **Every queue action must use an index.** Test with a realistic table; a lookup on a computed expression scans.
5. **A dashboard action on 1,000 items must finish in seconds,** or run as a background job that reports progress.
   A timeout that leaves half the items changed is the worst outcome.
6. **Auto-added sources need a tier below the owner's own groups.** It must not depend on whether the owner ranked
   anything.

## 7. How I worked: lessons for the assistant, not the app

These are my own mistakes and process lessons from 11-13. Each cost the owner time or attention.

1. **I made two wrong claims and had to correct them.**
   - I said 11–12 unlimited hours would cover all unique files. That was an account-wide sum; per server it is about 65
     on DC1.
   - I credited the new channels with DC2's bytes, when they came from an older group (§3).

   Before reporting an effect, check it per server and per file. When wrong, say so at once, plainly, with the
   corrected numbers.
2. **I re-measured something already measured.** This morning I decoded the saved messages to count DC2's remaining
   files and got 208, the same number a session had found the evening before (in memory and
   `ANSWERS-for-archiver.md`). Read the existing notes and answer files before measuring.
3. **I asked the owner to do a chore by hand.** I told them to click "Count media" 86 times. They asked, rightly, why
   the app couldn't do it. When an owner's action is needed per item, build the automation first and ask for the
   decision, not the clicks.
4. **I proposed "off by default" for a fix under a deadline.** The owner chose "on". A switch nobody flips in time helps
   nothing. Propose the default you would choose, with the reason, and the evidence that it's safe.
5. **I overloaded the owner's PC once.** I ran the race detector through a script that sets no CPU limit, next to the
   tests and a reviewer: about 6 cores, 99% CPU, with the live archive running. I stopped it. Cap every container
   (`--cpus 1.5`), give each agent a budget, and check the load after starting anything heavy.
6. **I invalidated my own test runs.** I edited code while a test and race run was compiling it, and got a meaningless
   build error. Then I started a slow query on the live database that had to be stopped. Freeze the code before a run;
   query live data in one pass.
7. **I trusted a fragile watcher.** It parsed prose and raised a false alarm (§6). Parse the exact line, or better, a
   machine-readable status.
8. **I kept notes where the owner couldn't find them** (my session scratchpad). Keep shared notes in the project
   folder from the start.
9. **Independent reviews were worth every minute.** Three reviews of 12.30 each found real bugs after all tests had
   passed: two pacing traps, ten automation issues, and lost marks under concurrent clicks. Budget a review for every
   download-path or automation change, and fix everything confirmed before pushing.
10. **What worked, and should be repeated:**
    - Numbers only, with ids mapped to row numbers, so nothing private was printed.
    - Small read-only tools (a gotd decoder over the stored records answered per-server questions in 2 s, with no
      Telegram request).
    - One recommendation per question.
    - Saving the owner's decisions (OKs, defaults) to memory as they were given.

11. **(11-14) I gave the owner steps I had not checked against the app.**
    - I told them to pause a channel's files on the queue page in chunks of about 200. That page lists at most 1,000
      files, and every pause walked the whole queue, so it timed out.
    - What worked was something they found themselves: switching the channel's downloads off.
    - Read the code path of every step before handing it to the owner, including its page limits and its cost per
      item. Say when a step is untested.
12. **(11-14) Read every handler you call internally.** 12.31's Stop and name repair called the group-save handler
    for chats not in the settings. That handler *creates* a group it doesn't know, so a removed chat would have come
    back. I found it by reading the handler before the review did. The review then found two more bugs after all
    tests had passed: a name the owner gave was overwritten, and Stop left the chat ranked. Reviews keep paying.
13. **(11-14) Budget memory, not only CPU.**
    - The race detector could not compile gotd's generated `tg` package in a container capped at 1.5 GB (the compiler
      was killed).
    - Free memory fell to 1.6 GB, with the live app holding 3.7 GB and the WSL VM 2.7 GB.
    - Plan about 3 GB for a race build of anything that imports gotd, or leave the race run to CI.
14. **(11-14) A quick CPU total misleads.** One reading said 97%; a per-process sample a moment later showed about 5
    of 12 cores busy. Sample per process over a few seconds before deciding there is no room.
15. **(11-14) Help the owner identify private items without printing them.** The owner needed the real names of
    the chats the app had added. I wrote them to a local file only the owner opens, and printed only counts in the
    conversation.

## 6c. When the chosen content runs out mid-spell (11-14)

- **The longest spell without the speed limit so far:** from 01:00 on 11-14, 14 hours and 733 GB by 14:48, still
  going. 11-14 alone brought 747 GB, the best day on record (the next best was 593 GB on 11-09).
- **By mid-morning the owner's chosen groups were nearly done.**
  - Hours went 74, 69, 47 and 31 GB, then 5 GB in the 13:00 hour. Only DC1 was busy, at about 12 MB/s.
  - Distinct files left: 4,049 (161 GB).
  - What remained in the queue: about 30,400 held probable copies (1.4 TB), 24,800 files already saved under the
    same Telegram file (they need no bytes), and 6,860 confirmed copies (1.4 TB).
- **The rest of the spell can only go to probable copies.** Answers 8 shows some of them are distinct: of the
  look-alike holds a frame check released and later downloaded, about half were different videos.
- **Rescanning for new posts would bring nothing on a frozen account.**
  - The newest message stored from any chat is from the eve of the freeze (10-30 23:23).
  - Reads made since (median 3.9 days ago) returned nothing newer, although 10 groups had posted about 195 messages
    a day before.
  - A rescan of the owner's 194 groups would cost about 8,200 requests for no files.

**For the new app:**
- **Rank probable copies by how likely each is distinct,** so a spell's spare hours go to the likeliest first:
  - "no match" from a frame check (often wrong, answers 8) before "look-alike", and confirmed copies last;
  - a different byte size or length before an equal one;
  - within each, the cheapest check first (Telegram's hashes before a download).
- **Know when the chosen content will run out, and say so before the spell starts,** so the owner can decide in
  time what the spare hours should go to.
- **On a frozen account, read each chat's history once.** Plan no rescans for new posts.

## 6d. Things outside the app can eat the copy link (11-14)
- **The owner found Syncthing running on the NAS.** Neither app uses it. If it watches or syncs the library folder,
  it re-reads each new file there and may send it over the same Wi-Fi again. That Wi-Fi is already at its ceiling of
  about 14 MB/s in busy copy hours (answers 8).
- The NAS maker's desktop client on the PC had also used more CPU time since start than the archive app.
- **For the new app:** measure the copy link's speed with nothing else on it once at setup, and show the copy speed
  live. A drop then points at something else using the link.

## Still to come (the next hours)
- Whether the held probable copies start going by themselves once the last set-aside files are done, and what share
  of them turn out distinct once downloaded.
- 12.31 (lists and stops the chats the app added; fast queue actions): CI on tg1, then the release, and the owner's
  install.
