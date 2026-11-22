# Step 4, "real for days": the plan, the cost, and what the owner starts (Core session, 2026-11-15)

Three real steps, each started by the owner, each with its numbers written down before the next
(`ROADMAP.md`, step 4): a small copy to a test folder on the NAS; a day-long run on the test account; one
deletion seen for real. Nothing here touches the old app, its account or its library.

## A. A small copy to a test folder on the NAS

**What runs.** One test program on this PC (`a3\a3-nas-copytest.ps1`, being built: `BRIEF-K3-nas-copytest.md`):
the real collector on the fake Telegram (invented chats and files, nothing sent to Telegram, no VPN needed),
its library set to an empty test folder on the NAS. About 150 invented files, 1 GB. Two passes: copies
checked by the helper on the NAS, then copies checked by reading them back. Afterwards every file is read
back once more and compared, the second names (hard links) are checked, and the test removes exactly what
it wrote.

**What it shows** (beside the old app's numbers: 14 MB/s the link's ceiling, 1.5 to 2.1 MB/s per copy for
small files, every byte crossing twice, 42% of the time in per-file steps): MB/s in all, the seconds by
step, how each copy was verified, how many copies at once the app chose, whether the helper's hash and a
hard link work on this NAS at all. One reading of a shared link: "looks like".

**What the owner does, once (about 15 minutes, the NAS part untried):**
1. Makes an empty folder for the test on the NAS's share (not inside the old library).
2. Puts the helper on the NAS: the image file is ready, `nas-helper\tgarchive-nashelper-0.1.0.tar` (3 MB,
   built from the merged head; checked on this PC: it starts, answers its health question, hashed an
   invented 5 MB file to the same SHA-256 as the PC, refused a path outside its folder). Import it in the
   NAS's Docker app and start it with `nas-helper\compose.yaml`, its two placeholders set to the test folder
   and the NAS's address (`nas-helper\README.md` has the steps and one check of who can reach it). It sees
   only that folder, read-only.
3. Starts the script with the folder's path and the helper's address, and says when it has ended.
   Without step 2 the read-back pass alone can run; the helper's row then stays "fake".

**Cost.** No Telegram request. On the Wi-Fi link to the NAS about 5 GB in all (1 GB written per pass, 1 GB
read back in the second pass, 1 GB read by each final check): about 6 minutes of a link the old app's
copies use at its ceiling, so the old app's copying slows for those minutes. 1 GB of local disk for
staging, freed at the end. The NAS: one small container (128 MB at most).

## B. A day-long run on the test account

**What runs.** The installed collector as the one program with its pages (G1), under the watchdog (K2), on
the test account's own catalogue, started by the owner from the starter and left for 24 hours.
**It waits for:** M4, K1 and G1 merged and installed (the integrator's order), the watchdog merged and
installed, and, recommended, the one-line fix of `FINDING-CORE-crash-28.md` in the build.

**What it does to Telegram, by the collector's own defaults:** one sign-in session kept; the chat list read
at the start (2 requests on 11-13) and once every 24 hours; the live monitor's stream (state resumed from
the stored one, one difference at a start); the VPN check every 30 s on this PC (the route, and the
public-address service the scripts name); reads only of chats the owner approved; downloads only from
chats the owner chose (K1). The test account's two read chats are saved in full (756 of 756 files), so
**an idle day downloads nothing unless the owner gives it work.** Every request is counted per kind and
hour by the collector itself.

**To make the day worth its numbers, the owner chooses (each a choice, none needed to start):** one more
chat of the test account approved and chosen from the Chats page (its cost shown first), so lanes work for
hours and a speed-limit change can be met; a few messages with a picture posted into a chosen chat from
the phone during the day (live download and copy); and step C.

**What is read afterwards (counts and times only, from the status files and the catalogue, read-only):**
did it live 24 hours (the watchdog's history: ends by class, restarts); memory and handles at the start
and the end; requests, waits (count, shortest, median, longest) and connection losses per kind and hour;
the monitor's gaps and how each was closed; files wanted, saved, verified; the log's size. The status
file's content is checked against the run for the first time (an open point of the handoff).

**Cost.** Telegram: an idle day is the monitor and one chat list; a chosen chat costs what its estimate
says (about one request per 100 messages to read, then its files at this account's about 5 MB/s on its
server, inside the old app's range: not tuned). The PC: the collector held 38 to 59 MB on 11-13; the
watchdog a few MB. The VPN line is shared with the old app, which was never bound by the line (28.6 MB/s
at its best). Local disk for what a chosen chat holds.

**Stopping it:** Quit on its page, or `a3\a3-stop.ps1`. Both are clean stops: the watchdog does not start
it again.

## C. One deletion seen for real

During B the owner deletes, on the phone, one message of their own with a picture in a chat the collector
follows. Afterwards the catalogue is asked (read-only, counts): one message marked deleted, its file still
saved. Cost: nothing beyond the monitor's stream.

## What Core hands over for these (state on the board row)

- K2, the watchdog: `wip/core-watchdog`.
- K3, the copy test and its script: `wip/core-nastest`.
- The start scripts in `a3` start the collector under the watchdog once K2 is installed (Core's); the app's
  starter is the pages track's.

## A, first real reading (the owner's run of 11-15 18:57; read from its log by Core at 19:02)

One pass (read-back; no helper yet), 150 invented files, 980 MB, average 6.5 MB. The log does not name the
folder; the speeds and the link counts say a network share (to be confirmed by the owner). One run on a
shared link: "looks like".

| | This run | The old app (its reports) |
|---|---|---|
| MB/s in all, copies checked by reading back | 22.6 (980 MB in 43.4 s, 4 copies at once for 36 of 44 s) | 9.6 median, 14.0 the best hour (8 at once) |
| The link while it ran | each byte out and back: about 45 MB/s both ways together | 14.8 out, 14.5 in (11-09) |
| The final read alone (one stream at a time) | 27.0 MB/s | not measured apart |
| MB/s per copy, busy time | 6.25 (files of 6.5 MB on average) | 1.5 to 2.1 (about 20 MB files), 3.6 to 4.3 (300 to 430 MB) |
| Seconds by step | write 32%, verify (read-back) 32%, publish 19%, prepare 8%, flush 5%, link 3%, catalogue 0% | write 52%, catalogue 19%, prepare 16%, read back 6%, publish 6%, flush 1% |
| Verified | 150 of 150 by a read-back at once; 0 mismatches, 0 failed tries, 0 "library away" | |
| Hard links | 22 made, 0 refused; every one the same file as its original (20 of 20 checked by file identity) | "tried once by hand" |
| Copies at once | 4 all through; the tuner tried nothing (the run is shorter than its 2-minute window) | 8 set by hand |

- **The test ended FAIL, for its own check, not for a copy:** for all 8 files with second names the link
  COUNT read through the share was lower than the names the file has, while every link is the same file by
  identity. So on this NAS a file's link count as Windows reads it over the share is not to be trusted;
  file identity is. Nothing in the store uses the count for the library (only for a staged part on the
  local disk). The test is being changed to report the counts and fail only on a link that is not the same
  file (`wip/core-nastest`, the same coder).
- **43 of 150 copies waited the store's 30 s "not published locally yet" pause** (board message 38): the
  first copy still started within about 2 s, so here the pause delayed single files, not the whole run.
- **Publish takes 19% of the copy time** (about 0.2 s a file: a rename on the share after the read-back):
  with files of 6.5 MB the per-file steps are about a third of the time, as the old app found (42%).
- The link looks about twice as fast as on 11-09 (the old app was not in an unlimited spell's copy backlog
  at that moment, or the link changed: not known). The helper would take the read-back's 32% and half the
  link's traffic away: that is what the helper pass measures.
- The first log came out in UTF-16 (Windows PowerShell's Tee-Object); the script writes UTF-8 from now on.

## A, the helper pass and a second read-back pass (the owner's run of 11-15 19:10 on `X:\nastest`; read by Core at 19:13)

The owner confirmed the 18:57 run was on `X:\nastest` too. The helper runs on the NAS in host network mode
as user 1000:10, listening on the NAS's address, port 8790. 150 invented files and about 1 GB each pass.

| | Helper pass | Read-back pass (19:12) | Read-back pass (18:57) |
|---|---|---|---|
| MB/s in all | 30.1 (43.1 over the 23 s a copy ran) | 23.7 | 22.6 |
| Seconds, first copy to last | 32.9 (10 of them with no copy running: the 30 s pause) | 42.1 | 43.4 |
| MB/s per copy, busy time | 11.0 | 6.0 | 6.25 |
| Verified | 150 by the helper, 0 fell back | 150 by a read-back at once | 150 by a read-back at once |
| Seconds by step | write 56%, publish 20%, prepare 10%, flush 7%, link 4%, verify 3% | write 33%, verify 30%, publish 18%, prepare 8%, flush 6%, link 6% | write 32%, verify 32%, publish 19% |
| The helper | 151 requests, all ok; it hashed 989 MB in 0.6 s of its own time | | |
| Failed tries, mismatches, "library away" | 0, 0, 0 | 0, 0, 0 | 0, 0, 0 |
| Links | 22 made, 0 refused, each the same file | 36 made, 0 refused | 22 made, 0 refused |
| Final read of every file | 150 equal, 26.1 MB/s | 150 equal, 26.8 MB/s; 33 links, each the same file | 150 equal, 27.0 MB/s |

- **The helper does what it was built for on this NAS:** the check went from about a third of the copy
  time to 3%, and the copy from about 23 to 30 MB/s in all (43 MB/s while copies ran), one run each: "looks
  like". With the read-back gone, the publish (a rename on the share, about 0.12 s a file) and the write are
  what is left.
- **Both passes still ended FAIL, for the test's rig, not for a copy:** the fake Telegram's own guard counted
  up to 57 reference refreshes within one real second at the start (it answers at once; the guard is made
  for the tests' fast clock). The test is being changed to report that as a number (`wip/core-nastest`).
- The link count read over the share is 1 for every linked file (13 of 13), as on the first run: identity
  is right, the count is not.
- The 30 s "not published locally yet" pause held 45 and 43 copies; in the helper pass it left 10 s with no
  copy running: it now costs a visible third of a short run (board message 38).

## Before B: one check the copy test could not make (the owner's constraint, 11-15 19:15)

The owner: local connections between the PC's app and whatever runs on the NAS must not go through the VPN
(speed). The installed collector runs under the VPN's per-program rule, and the copy test's program does
not: so the tests above do not show whether the collector's own request to the helper (10.0.0.42:8790, a
home-network address) leaves directly or is sent into the tunnel, where it could not reach a private
address at all (the collector would then fall back to reading every copy back, silently slower). To check
before the day-long run, with the owner's word (it starts the installed program once; nothing is sent to
Telegram): one request to the helper's health page from the installed collector's program, and the
helper's own count of requests before and after.

## B, prepared: the owner's steps by full path (Core, K-2, 11-15 20:47)

**It waits for one thing: G1's build installed as the collector** (the integrator writes that on the board;
the batch with K4, K3, C8 and M5 comes with it). Everything else is ready: the watchdog is installed, and
the start and stop scripts go through it and were run as the owner runs them (`SESSION-CORE-PROGRESS.md`,
20:38). The pages track's own starter (`app\tgarchive.cmd`) is a draft, untried, and that track has no
session: this run uses the `a3` scripts, which serve the same pages.

**Before the owner starts (a Core session, nothing dialled):** once the build is installed, the start
script is run once more on a scratch copy with `-Pages` (with today's build the collector refuses that
flag, as expected; with G1's build it must get as far as the accounts read), and the row says so.

**The owner, from any folder:**
1. The VPN on (WireGuard). Nothing of the app running: `powershell -ExecutionPolicy Bypass -File
   "C:\Users\trabi\Claude\Projects\Telegram\a3\a3-stop.ps1"` says "nothing to stop" when that is so.
2. Optional, the PC's numbers once a minute (it needs Python; it ends by itself after 48 hours):
   `powershell -ExecutionPolicy Bypass -File "C:\Users\trabi\Claude\Projects\Telegram\a3\a3-sampler-start.ps1"`
3. The start: `powershell -ExecutionPolicy Bypass -File
   "C:\Users\trabi\Claude\Projects\Telegram\a3\a3-start.ps1" -Pages`
   Within about 15 s it says "started: watchdog pid=..., collector pid=..." and where the logs are, or
   "not running: ..." with the reason (then nothing was sent). The pages: `http://127.0.0.1:8787/`.
4. Leave it for 24 hours. The window can be closed; the PC must stay on and the VPN connected.
5. The end: Quit on the page, or `powershell -ExecutionPolicy Bypass -File
   "C:\Users\trabi\Claude\Projects\Telegram\a3\a3-stop.ps1"` (it waits up to a minute and says "stopped:
   the collector and the watchdog have ended"). Then tell any session.

**What the first start does that no start did before:**
- **K1's one-time baseline** (no `run` of a build with K1 has opened the test catalogue yet): every chat
  that collects and shows no sign of the owner's hand (no approved read, no rank, no changed kinds or
  topics) is switched off once and its files held; the chats whose read the owner approved stay. One line
  before and one after in the collector's log, numbers only. Nothing is removed; the Chats page's switch
  turns a chat back on.
- **The catalogue is stepped** to the build's schema (19 and 20 with the batch) at that open; an older
  build then refuses it (the earlier builds are kept as `.bak` beside the installed one).
- **It collects at once** for the signed-in account (the owner's decision, board item 14): the chat list
  (2 requests on 11-13), the live monitor, reads only of approved chats, downloads only from chosen chats.
  The two read chats are saved in full, so an idle day downloads nothing.
- **Under the watchdog for the first time for real:** a crash is followed by a restart no sooner than 2
  minutes and never before a wait Telegram stated plus 60 s; a refusal (the VPN check, say) is not.

**To make the day worth its numbers (each the owner's choice, none needed):** one more chat approved and
chosen on the Chats page (its cost is shown first); a few pictures posted from the phone into a chosen
chat; one own message with a picture deleted on the phone (step C). Not in this run unless the owner
wants it: the automatic mirror (its own first real run is the mirror track's, board item 26).

**What is read afterwards (a session, read-only, counts and times only):**
- did it live 24 hours: `"%LOCALAPPDATA%\tgarchive\bin\tgarchive-watchdog.exe" history -dir
  "C:\Users\trabi\Claude\Projects\Telegram\a3\watchdog"` (ends by class, restarts) and
  `watchdog-status.json` there;
- the collector's log `a3\watchdog\collector.out.log` (the baseline's two lines; waits; connection
  losses; its size) and the status file beside the catalogue, checked against the run for the first time;
- the catalogue's own hourly counts: requests, waits (count, shortest, median, longest) and losses per
  kind and hour; the monitor's gaps and how each was closed; files wanted, saved, verified; one message
  marked deleted with its file still saved (step C);
- the sampler's file in `a3\logs` (memory, handles and threads of the collector, and of the watchdog, at
  the start and the end).

**Cost:** as written under B above. An idle day is the monitor's stream and one chat list.

## B, the first real start (the owner, 11-15 21:48; read out by Core, K-3, at 22:37)

Not the day-long run: the owner opened the one program with the command of step 3, looked at the pages and
quit. Read afterwards, read-only, counts only: the watchdog's folder, the collector's log, the status file,
the test catalogue opened `mode=ro`. One start is one reading: "looks like" for anything about Telegram.

| | Read |
|---|---|
| The run | 21:48:42 to 21:50:50 local, 2 m 8 s; the build `dev-c8e49ee` (G1); under the watchdog |
| The watchdog | 1 program started; the end "clean" (Quit from the pages), exit code 0; no restart; one line in its record |
| The stop | "Quit from the pages" to "stopped": the same second (11 ms) |
| The baseline (item 23) | both lines; 11 chats switched off, a record each; 0 files held anew; 2 chats left collecting; 0 s |
| The catalogue afterwards | 14 chats: 12 off for downloads, 2 collecting; 8 wanted files held (one fixed reason); 756 files; schema step 18 |
| Requests | 13 sent, 13 answered: channel difference 6, history 4, the chat list 2, difference 1 |
| Answers | median 97, 148, 72, 106 ms by kind; the slowest 207 ms |
| Waits, timeouts, refusals, server errors, connections lost | 0, 0, 0, 0, 0 |
| Connections | 1 dial, 1 new session, server 1; no lane (nothing to download) |
| The VPN check | 6 of 6 allowed; 312 to 1,361 ms |
| The live monitor | 1 gap found at the start ("channel difference too long"), closed in the run by the 4 history requests |
| Downloads and copies | none; every staging count 0 |
| Error lines | none; the collector's error log is 0 bytes |
| The status file | agrees with the log: written in the stop's second, "running: false", the build named |
| The pages | "the pages are ready" in the start's first second |

- **What it confirms of the plan above:** an idle start costs the chat list (2 requests, as on 11-13) and
  the monitor's catching up (here 11 requests for about two days away); the baseline did what item 23
  said; the watchdog saw a clean end and did not start the program again.
- **What it does not show:** anything over minutes (memory, handles, the hourly lines, the monitor's
  stream at rest), a download, a copy, a crash followed by a restart. The day-long run is still to make.
- **The schema:** the catalogue is at step 18. The installed collector is now a later build (2580f29 or
  newer): its first start steps the file to 20, and the builds kept as `.bak` then refuse it.
- **Open, Core's to read:** a second gap row from an earlier run has no "done" time; the watchdog's own
  record names the build "dev" without the commit.
