# Mirror track: current state (older text in `SESSION-MIRROR-LOG.md`, which nobody needs to read)

## STATE FOR A TAKE-OVER (session M-7, 11-22 11:48): nothing of the track runs; M-7 is archived
- **Integrator:** I-7 (`local_78ac6953-2e70-4c12-a371-4f255f71e85c`): listings and reports go there.
- **Merged** (head 09aeba54 and later): M14 deleted posts never block, singles 5-20 s, exact repeats skipped (step 29);
  M15 forums as forums (31); M19 rename a mirror from a page; M20 older-file test; M16+M17 the mirror settles every
  unknown outcome by itself, adaptive forward pace 3 s down to 1 s, topic creates 3-5 s, titles from Core's K26 (33).
  The race run of internal/mirror on 09aeba54: ok, 9423 s, 0 races.
- **In I-7's batch now finishing:** M21 (`wip/mirror-newchats` 70aa1b1d + the join fix `wip/mirror-newchats-j` ffc12e77:
  the new-chats rule removed only by the run's flag; the stored setting through each turn's approval) and MF
  (`wip/mirror-facts-night` 40ab52a1: the night's numbers on the M15 build). Their copies `wt-mirror-newchats`,
  `wt-mirror-newchats-j`, `wt-mirror-facts` are removed once merged (check "merge-tree of head and branch = the head's
  tree", since the integrator joins by hand).
- **Owed, in order:**
  1. After the owner's switch to the M16+M17 build: the numbers into TELEGRAM-FACTS 11 (counts only, catalogue
     read-only `file:C:/Users/trabi/tgarchive-app/data/catalog/catalog.sqlite?mode=ro`): forwards per minute and per
     hour, stated waits and lengths (c_tg_hourly by kind), the pace in force (settings `mirror.auto.forward_pace`,
     the account's pace state), topic creates per minute, renames of the 32 "Topic N" topics, set-asides
     (c_mirror_aside), put-backs (c_mirror_putback), the 02:00:44 block cleared. Before it: `PRAGMA user_version` is 33
     or more (the old build is 31).
  2. For pages: a door for `mirror -pause-reset`; the held/set-aside/put-back-old facts and the paces on the pages.
  3. The first real adoption (`PLAN-MIRROR-first-adoption.md`; its line is on the owner's list).
  4. Clean-up: `mirror.WhyForum` / `ErrWantForum` (deprecated) once nothing names them.
- **Lessons:** the owner wants the mirror to go on by itself while away: turn every block a retry, hold or set-aside can
  settle into one, and ask each reviewer "which blocks are left and why"; an older-file test uses its own step's
  constant, never SchemaVersion-1; Python on Windows writes CRLF in text mode (write sources in binary).
