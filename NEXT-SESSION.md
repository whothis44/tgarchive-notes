# Next session: start here (written 2026-11-13 evening; update it before you stop)

Read, in this order:
1. `CLAUDE.md`
2. `START-HERE.md`
3. `HANDOFF-go-private.md`
4. `LESSONS-ix12.30-live.md`
5. the memory index (`MEMORY.md` and the files it lists)

Follow every rule in `CLAUDE.md`, especially the privacy rules, read-only access to `E:\T\tg-dl`, and "never stop,
restart or reconfigure the running app".

## Current state (11-13 evening)
- Fork **12.30** is live on the archive, installed by hand at 14:42 on 11-13.
- The fork's working repository is private: **`whothis44/tg1`**. The old repository
  `whothis44/telegram-media-downloader` is private and archived: never push to it.
- Releases are tagged in tg1 and installed by hand by the owner. The updater can't sign in, so at every start the
  launcher says "Could not check for an update". That is expected.
- **Never put numbers from the archive (GB, file or chat counts, servers, hours) in commit messages, PR descriptions
  or changelogs.** Those numbers stay in local notes only.

## Update 11-14 afternoon: 12.31 built locally, waiting for the owner's OK to push and tag
- **Why:** the 30 channels 12.30 added by itself took the queue on 11-14. Their names showed as placeholders, 5 of
  them were ranked through the "Add them to the end of the ranking" banner, and pausing ~1,000 files timed out.
  - The owner stopped one big channel by switching off its photos, videos and files in the main app. The engine
    then dropped its 1,328 queued files as filtered.
  - The owner calls the others "trash".
- **12.31:** worktree `wt-v12.31`, branch `ix/v12.31`, commits `993f55f` and `b065246`.
  - **Pushed to tg1 on 11-14 with the owner's OK** ("Push, tag after CI").
  - CI-only PR: whothis44/tg1#1. Never merge. The owner un-drafted it.
  - **Actions had been off on tg1.** The owner enabled it on 11-14; CI then started with 3 runs.
  - **Tag `v3.4.18-ix.12.31` only once CI passes.**
  - **First CI run (b065246) failed in 5 app tests,** in both the Go and the archive jobs: 3 staging tests, the
    staging placement test and the pre-update copy test.
    - Cause: a private repo's runner has less free disk than staging keeps (50 GB) and the pre-update copy keeps
      (20 GB).
    - Fixed in `195d5c5`: the app's TestMain reports plenty of space via `download.SetStageFreeSpaceForTests`.
    - CI was re-run on it at about 21:30 UTC.
- **Go toolchain:** the one in the old 63fc91bc scratchpad lost files on 11-14 (`src/unsafe` emptied).
  `ix-tools/env.sh` now puts an intact go1.27.3 copy, in the 1d7d278f scratchpad, on PATH. A scratchpad can be
  cleaned at any time, so make a durable copy if this breaks again.
  - Queue actions use the unique index.
  - Groups tab "Added by the app": real names, and Stop for one or all.
  - Placeholder names repaired.
  - The ranking banner leaves out the app's chats.
  - The two release-runner tests hardened.
  - An independent review was done and its confirmed findings fixed.
- **Checks:**
  - engine, telegram and download passed in full;
  - app passed in full before the review fixes, and again after them (see that session's result).
  - Not run: the race detector (memory was tight, about 3 GB free).
- A local list of the app-added chats, with real names (owner only, never printed), is in the session scratchpad
  `app-added-chats.md`.
- Answers: `ANSWERS-for-archiver-7.md` (notes, §7b added) and `ANSWERS-for-archiver-8.md`. Lessons:
  `LESSONS-ix12.30-live.md` §6b.

## Tasks, in order
1. **Check the live state (read-only).**
   - `data\crashes\running` shows 12.30, and `history.jsonl` shows no unexpected endings.
   - Read the report's update, download-state and "chats not added" lines.
   - Report to the owner in a few lines, numbers first.
2. **DC4 under 12.30.** Find the first hours without the speed limit since 14:42 on 11-13. Compare DC4 against the 22
   unlimited hours from 11-08 to 11-13, by the method in `LESSONS-ix12.29-servers.md` §4:
   - share of time at 2 parts;
   - tries up and kept;
   - "short waits at 2 parts or fewer with no ceiling";
   - plain waits per hour;
   - GB per hour.

   Check where the bytes came from, per file, before crediting 12.30. Say "looks like" unless several hours agree. If
   no unlimited hour has come yet, say so and check again later. (The speed limit was on without a break from 14:42
   to at least 18:21 on 11-13.)
3. **The 30 channels 12.30 added automatically.** Once their history reads finish, or with what is there:
   - total unique size per server;
   - copies by Telegram file and by sampled frames;
   - updated per-server unlimited hours needed against the hours left before 2026-11-29 22:24.

   DC1 is the bottleneck. Tell the owner plainly what won't fit and what they should rank, with one recommendation.
4. **Finish `LESSONS-ix12.30-live.md` for the other app.**
   - Add the results of tasks 2 and 3.
   - Keep the ranked list at the top in your own judgment, not the owner's.
   - Keep the "how I worked" section.
   - Numbers only, no names.
5. **Only with the owner's OK:** a small 12.31 that hardens the two flaky release-runner tests
   (`TestAPartTelegramNeverAnswersIsAskedForAgain`, `TestIx1214CheckForUpdatesNowIsThrottled`), plus any confirmed fix
   from tasks 1–3.
   - Follow `PRE-PUSH-CHECKLIST.md`.
   - Run a challenger review for any download-path change.
   - Push and tag in tg1 only with the owner's OK.
   - Write change text without archive numbers.

## Working rules
- Use at most 2 CPU cores per test run or agent; more only after measuring that the PC has room.
- Cap Docker with `--cpus 1.5`. Never use `ix-tools/race.sh` as is: it has no CPU cap.
- Never overlap test runs.
- Query the live database read-only, in one pass.
- Short reports, numbers first, one recommendation. Say what you did not verify.
- Keep this file, `HANDOFF-go-private.md`, `LESSONS-ix12.30-live.md` and memory updated as you go, since usage can run
  out.
