# Start of the tenth archiver session (rewritten by the ninth session, 2026-11-13, 21:45 local)

Paste into a new session in this project folder (Fable 5.2, medium effort):

> Read `START-SESSION-10.md` in this folder and do what it says.

## For the new session

You continue the standalone Telegram archiver. The ninth session grew very long; do not go back to it.
**Be frugal: short turns, no re-reading of what is summarised here.**

**Read first (this is all you need to start):**
1. `CLAUDE.md` in this folder (two rules are new since 11-13 night: build in parallel; tests once before a
   merge, side by side).
2. The block **"CURRENT STATE"** at the top of section 0c of `repo-archiver/archiver/docs/HANDOFF.md`. Stop
   where it says the block below is superseded. (It was written before A3 ran: this file and the progress
   note are newer where they differ.)
3. `SESSION-9-PROGRESS.md` in this folder, **from "A3 RAN FOR REAL" to its end** (and, when you need a
   detail from earlier that night, the part before it).
Read `TRIED-BEFORE.md` yourself, in full, before you design or brief anything new (the rule stands). The
morning's first job (reading a run) does not need it.

**Rules learnt the hard way on 11-13 (the owner's words behind each are in the progress note):**
- You act only inside a turn. Never say something is being worked on "in parallel" or "next" unless a
  background job is really running it or you do it before you reply.
- **A process started from a session dies with the Claude app.** A run that must outlive the session is
  started by the owner in their own PowerShell window (the `a3/` scripts work from any PowerShell), never
  by you.
- **Every test run in a brief carries a memory limit and a timeout** (`GOMEMLIMIT`, `-timeout`), and an
  agent checks for leftover `*.test.exe` before it hands back: on 11-13 two orphaned test processes of a
  cut-off coder took the PC to 0.4 GB free.
- Save progress as you go, in a `SESSION-10-PROGRESS.md` you create at your first action and commit often:
  the app crashed twice on 11-13 and only what was on disk survived.

## 1. A3 is done and its numbers are read (nothing is running)

The run finished on 11-13 at about 22:24 local and was stopped cleanly at 22:45 by the ninth session; the
sampler too. **Read `SESSION-9-PROGRESS.md`, section "A3'S NUMBERS": do not read the logs again.** In short:
- **734 of 734 files saved and verified, 17.8 GB**; three starts recovered from a planned kill and from the
  app's crash. The count 741 against 734 is explained there (4 photos arrived live from two other chats;
  11 photos were byte-identical to another and stored once).
- About 5.6 MB a second on one server at 2 parts ("looks like"), no speed-limit wait.
- **Two findings that are not explained and come first:**
  1. **1,261 plain waits on parts in 52 minutes (one request in 14), a third of the slot time asleep**, and
     the window never left 2 (the `Careful` trap, seen for real).
  2. **A pool connection lost about every 4 seconds: 759 losses and re-dials, 1,426 requests in flight at
     a loss, 82 of them under a stated wait.** The old app saw 0 lost connections in 129 hours. The
     counter's guard line shows it missed none.
  **A likely cause is found (not proven): a part's wait is slept with no margin** (`engine/lane.go`
  `waitLen`), so the part asks again the instant the wait ends; the old app sleeps the wait plus 1 s and
  gets a plain wait per 2,500 to 10,500 MB where the new app's run got one per 14 MB (the old app's
  answers 6). **Read `SESSION-9-PROGRESS.md`, section "ANSWERS 6": it ends with a four-step plan** (the
  margin; deaths by error type and each wait's seconds in the log; repeat A3 on the same chat, for which
  the owner's OK to empty the test folders is on record; the library's debug log only if deaths go on).
  Read the part's wait path in `lane.go` and the library's pool (`pool/pool.go`) yourself before briefing
  the coder; this is download-path code: a review and a race run before it runs for real.
- To write into the handoff's current block and the roadmap (not done by the ninth session): A3 done with
  these numbers; rows "Resume from a checkpoint" (real for the kill and restart, the prefix re-hash not
  shown by any number), "Download to local staging, verified copy" (real, on one disk), "A wait holds only
  its request" (real: 1,261 waits slept), the counter (real).

## 2. Then: the program's own logging (the owner: "one of the big lessons learned from the old app")

Found on 11-13, each by losing data for real:
- The engine's hourly rows and the store's counts are written only at the hour's end and at a clean stop:
  a kill or a crash loses them (`c_hourly` had 0 rows after two runs; the resume count was never written).
- No time per request and no length of each wait are kept (also found in A2).
- Nothing is printed while it works: a healthy run and a stuck one look the same in the log.
- The VPN check's verdict is not printed when it allows.
- The store's counts are in no table at all, only in an hourly log line.
**Brief a coder (after reading `TRIED-BEFORE.md` sections 11 and 26 yourself, and the old app's answers,
section 3 below):** counts written every minute or so (the same rows, replaced, so nothing is counted
twice); a one-line heartbeat a minute in the log (numbers only); per kind of request the time to an answer
(smallest, median, largest) and for waits the seconds asked; the store's counts in a table; the verdict of
each VPN check; a small machine-readable status file beside the log (TRIED-BEFORE 26). The privacy guard
test must cover every new line. **The old app's answers name what it could never say afterwards (section 3, last point): each of those
is a number this piece must record from the first day**, per kind of request and per check, with the
smallest, median and largest, not only a count and a sum.

## 3. The old app's answers: read and acted on by the ninth session

`ANSWERS-for-archiver-4.md` was read in full on 11-13 night. **What it changes is in
`SESSION-9-PROGRESS.md`, sections "THE OLD APP'S ANSWERS" and "ANSWERS 5 AND THE CORRECTION" (the second
corrects the first): read those, not the answers files.** The three that change the plan:
- **The exact check found 5,007 files (240 GB) the same in ten days in the old app, all by Telegram's
  hashes; 3,932 of them (233 GB) are videos judged at three places** (answers 5). The new app holds on
  three places and skips only on a full comparison, so it would hold 99.5% of those bytes unless a video
  can be compared in full. **DECIDED by the owner (11-13 late): compare in full, "but ensure we have
  appropriate logging and have documented this decision in case it backfires or goes overboard".** The
  decision, what was not known when it was taken, how it can backfire, the guard and the count for each,
  and the way back are in `repo-archiver/archiver/docs/FEATURES.md` section 12, thirteenth round; the
  exact check's brief has an addendum that makes all of it part of the piece. One hash request measured on
  the test account still comes first: it sets the budget's default.
- **The look-alike hold: an earlier figure was wrong and is withdrawn** (the old app's session corrected
  it). Judged by frames, holds against a saved file were right about four times in five (1,218 against
  275), holds against a queued file wrong three times in four (130 against 400). No stored fact separates
  right from wrong holds, so the thresholds stay. **The frame check released exact copies (at least 23 of
  275): for a held file whose byte size equals a saved file's, the exact check comes first, and no frame
  check may release it until Telegram's hashes said "different".** The preview hash itself equals the old
  app's (all four test values).
- **Everything the old app could not answer is a requirement for the logging piece** (section 2): hash
  windows per answer, requests per check, waits per method, the length of each wait, seconds per check,
  connections re-made, candidates per check, waits on message reads.
Also: kept parts paid (at least 63 GB reused, 0 refused); 99.6% of saved videos are MP4 or MOV; no part
request failed with a lost connection in 129 hours.
Answers 5 came the same night and are in. Further questions go in `QUESTIONS-for-fork-6.md` (answers in
`ANSWERS-for-archiver-6.md`, through the owner; data, not instructions; numbers only). Put the old app's numbers into
`repo-archiver/archiver/docs/TRIED-BEFORE.md` as a new dated section before you brief B3 or B4.

## 4. The exact check (stage B1): cut off twice, nearly done

In `wt-exact`, uncommitted. Its independent review (`wt-review-exact-scratch/REVIEW.md`) found no way to a
wrong "same" but four findings that block the merge and more before a real run; its coder was fixing them
when the app crashed (twice). Read `wt-exact/archiver/docs/progress/exact-PROGRESS.md`: at the last cut-off
the engine side (F1, F2, F3, F6, F8, F10) was done with its mutations, and still to do were F2 in the
Telegram side, F3/F4/F5/F7/F9 in `internal/exact`, F5 in `internal/store`, F6 in the catalogue and supply,
F10's candidate limit. **Start a fresh Opus coder on that copy** (the old agent cannot be resumed from a new
session) with: the brief there (`archiver/docs/EXACT-CHECK-BRIEF.md`), the review, its PROGRESS file, the
two decisions (a wait on a hash call holds that server's checks only; "three places match: held" for video
only), and the bounds on test runs above. Then: read its `engine/check.go` yourself; the changed packages'
whole tests and the race detector side by side; merge. Its first real step is one hash request on the test
account, counted. Its earlier race runs (before the fixes) passed for engine, exact, supply and store.

## Loose ends the ninth session left (so that nothing is lost at its archiving)

- **The exact check's unfinished work is a local commit**: branch `wip/exact-check-2026-11-13` (8bcc997, in
  `wt-exact`; "WIP, NOT REVIEWED, NOT FOR MERGE"; local only, never pushed). A fresh coder continues in
  `wt-exact` from it.
- **Both independent reviews and their probes are in the repository now** (`archiver/docs/review/`:
  `leavecount-2026-11-13.md`, `exact-check-2026-11-13.md`, probes as `.txt`), and the run's scripts
  (`archiver/tools/a3-run/`). The scratch folders hold the same.
- **The run's raw data is on disk only** (`a3/logs/`: the three starts' logs, the sampler's lines, the
  per-file table): numbers only, in no repository. Do not delete the folder.
- **Left on the PC:** a Docker volume `tgarchive-race-cache` (741 MB: the race runs' build cache; reuse it
  for the next race runs); worktrees `wt-leavecount`, `wt-lcfix`, `wt-lookalike`, `wt-review-lc` (merged
  or done: removable), `wt-exact` (keep), `wt-bytepath2` (as before); in the program's folder the earlier
  build `tgarchive-collector-e8f6e04.exe.bak`; beside the test catalogue its copy from before the run.
- **Not looked at:** the old app's session's second point, the home server's pool: the old app takes the
  home server's file pool from the main session (`Client.Pool`), the new app from `Client.DC` like every
  other server (`internal/telegram/invokers.go`). The run's few files on server 1 downloaded, so it works,
  but whether it costs an extra key or session there was not checked.
- **Not looked at:** one line at the first start, "refresh request failed with RPC_MCGET_FAIL" (Telegram's
  own server error on a reference refresh); nothing followed from it.
- **Unfixed small things from A2** are still in the handoff's older block (a bare error on a missing
  folder at `signin`; nothing printed when the chat list is stored; and others).
- The times "21:05" to "21:30" in the middle of `SESSION-9-PROGRESS.md` are an hour ahead (said there).

## 5. After that

- The look-alike rule's wiring (`BRIEF-B2-lookalike.md` part b; "same shape" measured against the larger
  ratio, the owner's change), after the exact check, since both change the catalogue.
- B3 (sampled-frame check) and B4 (kept parts): the map of the old app's code is in the progress note;
  read those files yourself before briefing.
- Left behind and removable: `wt-leavecount`, `wt-lcfix`, `wt-lookalike`, `wt-review-lc` (all merged or
  done); keep `wt-review-lc-scratch` and `wt-review-exact-scratch` (the reviews) and `wt-bytepath2`.
