# Start of the eleventh archiver session (written by the tenth, 2026-11-14 about 17:55 local; kept current)

## BEFORE ANYTHING ELSE: read the old app's lessons and code, and write down what they say (the owner, 11-14 night)

The owner: "I need you to instruct the next session to actually read the old code and learn from it.
There's literally a lessons learned document, and a what we tried that didn't work document. Why are we
spinning in circles?"

**What went wrong in the tenth session, so you do not repeat it.** It read `TRIED-BEFORE.md` and
`WINDOW-EVIDENCE.md` in full and still spent a day and three real runs "finding" what both already say:
- "A server's speed is about min(parts in flight x 4 MB/s, a ceiling)"; "more parts, same bytes";
  "more parts under the limit bring only more waits" (4 parts: 810 waits for 622 MB; 2 parts: 422 for
  612). The third run showed exactly that: twice the waits, the same bytes.
- **The old account's server 2 brought 2.3 to 4.4 MB/s per part and 5.2 to 7.5 MB/s in its best hours.
  The test account's 4.85 to 5.6 MB/s on server 2 at 2 parts was inside the old app's normal range all
  along.** The tenth session never put the old app's number beside its own, treated a normal speed as a
  defect, and built a margin, a diagnostic log and a slot-freeing scheme to [name removed] it.
- Its own conclusion at 18:00 ("refusals are a fixed share of requests; freeing the slot recovers a
  third") contradicted the documents it had read. It did not check the conclusion against them.

**So, before you propose, brief or change anything in an area:**
1. Read, yourself and in full, for that area: `repo-archiver/archiver/docs/TRIED-BEFORE.md`,
   `LESSONS.md`, `WINDOW-EVIDENCE.md`, `COPY-CHECKS-STUDY.md`, `TELEGRAM-FACTS.md` (same folder), and in
   this folder `LESSONS-ix12.29-servers.md`, `LESSONS-ix12.30-live.md`, `LESSONS-viewer-ix12.32.md`,
   `ANSWERS-for-archiver-4.md` to `-9.md`.
2. Read the old app's code that does the same job (`wt-v12.31/core-service/internal/...`): downloads:
   `telegram/pacer.go`, `floodguard.go`, `attachment.go`, `parallel_download.go`, `download/library.go`,
   `engine/controller.go`; copies: `app/ix_subst.go`, `ix_held.go`, `ix_copies.go`, `ix_dl_check.go`,
   `ix_copies_sample.go`, `ix_part_store.go`; the viewer and pages: its `/browse` (fast) and `/viewer`
   (slow), with the viewer lessons file. Its changelog says why each thing is as it is.
3. **Write a short "what the old app already knows" note in your progress file before the proposal:**
   the old app's number for the same thing (per server, in the same regime), what it tried and what
   happened, and the rule that came out. A measured number is a defect only when it is worse than the old
   app's number for the same server and regime; say both numbers.
4. Default to the old app's way where it worked. Change it only where a number already on record says
   the change pays, and say which number. No new scheme to "see what happens".
5. If the documents and your conclusion disagree, the documents win until a number says otherwise.

**The download path after the third run:** it downloads, resumes, verifies, checks exact copies and logs.
Its speed on the test account is in the old app's range. **Stop tuning it.** One change is recommended
and waits for the owner's word: the default back to "a waiting part keeps its slot" (the old app's way:
the same bytes for half the refused requests). Then the documents commit, then breadth.

Paste into a new session in this project folder: "Read `START-SESSION-11.md` and do what it says."

## Read first
1. `CLAUDE.md` (its test rules were tightened on 11-14: race only where concurrent code changed; review and
   fixes before the full runs, once; the plan told to the owner first; `ix-tools/full-runs.sh`).
2. The first block of section 0c of `repo-archiver/archiver/docs/HANDOFF.md`.
3. `SESSION-10-PROGRESS.md`, **its last 60 lines** (the rest only when a detail is needed).

## Rules learnt the hard way on 11-14 (the owner's words are in the progress file)
- **The owner (17:50): "I want the downloader to work, and be good, so implement everything we discussed,
  but don't test needlessly. Get it done then test."** Coders get the tests named in their brief and no
  more, no mutation rituals, a package's tests once when its code is complete. One independent review and
  one full run for the download pieces together, at the end.
- **"Don't reinvent the wheel unless it actually improves things."** The old app's code is on this PC
  (`wt-v12.30`, `wt-v12.31`): read the part that does the same job before briefing.
- **"We're a week into development and we have basically nothing."** Depth went into the download path;
  the copy to the NAS, the viewer, the bring-in and the pages have never run for real. After the download
  pieces below land, the next work is breadth: things the owner can open and use.
- Never write a clock time from memory: take it from `date`.
- Go: `source ix-tools/env-archiver.sh` (toolchain `ix-tools/goroot-1.27.3`; the old `env.sh` is damaged).
- A run that must outlive the session is started by the owner in their own PowerShell window with
  `powershell -ExecutionPolicy Bypass -File <script>`.

## What is merged and pushed (branch `claude/charming-feynman-vm2xia` on `private`, head 4f5be66)
- The wait margin (default 1 s) with a log line per part wait and per connection death.
- The session file's read retry and its sweep fix.
- The library's own connection log behind `-lib-debug` (allow-lists only).
The collector in the program's folder is built from 4f5be66. The test folders are reset (741 wanted).

## What two real runs on the test account showed (one chat, 734 files, 17.8 GB, server 2)
| | 11-13, no margin | 11-14, margin 1 s |
|---|---|---|
| Plain waits on parts | 1,261 (one request in 14) | 1,359 (one in 14.5) |
| Pool connections lost | 759 | 261 |
| Slot time asleep | about 31% | 43% |
| Speed at 2 parts | about 5.6 MB/s | about 4.85 MB/s |
The margin is not the cause of the waits; it looks like it cut the losses to a third and cost 13% speed.
The speed goes to slots asleep under waits and a window that never leaves 2. The old app sees neither the
waits nor the losses (another account; library v0.163.0 against v0.166.0): `ANSWERS-for-archiver-9.md`.

## In flight (each in its own copy; read its report before anything else)
| Piece | Copy / branch | Brief | State when this was written |
|---|---|---|---|
| Exact check: three places decide (the owner, 11-14), review-2 fixes | `wt-exact`, `wip/exact-check-2026-11-13` | `BRIEF-B1c`, `BRIEF-B1d` | DONE (438855f), being integrated |
| Logging: review fixes | `wt-logging`, `wip/logging-2026-11-14` | `BRIEF-A5`, review in `wt-review-logging-scratch` | DONE (46176f5), ready for the integration |
| Window: a waiting part frees its slot; upward-only rule | `wt-window`, `wip/window-2026-11-14` | `BRIEF-C1-window.md` | DONE (87cb62c), being integrated |
Spot checks of the exact check are testing flags, off by default (the owner). If the session died, the
agents died with it: each copy's `docs/progress/*-PROGRESS.md` and `git log` say where it stood; start a
fresh Opus coder on the same brief.

## Then
1. **Integrate:** one Opus coder merges the three branches into one (`wip/downloader-2026-11-14`, from the
   branch's head): the exact check's schema step 11, then the logging's 12 (its report has the merge notes;
   its start-up guard flag goes away), `lane.go` and `engine.go` by hand.
2. **One independent review** of the integrated diff (download path: wrong "same", waits never shortened,
   nothing sent that was not sent before except hash requests, privacy), its fixes.
3. **The full runs once** (`ix-tools/full-runs.sh`; tell the owner the packages and minutes first; race
   only where concurrent code changed: engine, telegram, exact, and the collector's new tests by name).
4. Merge, push to `private`, build, reset (`a3/a3-reset.ps1 -Go`), and the owner starts a run
   (`a3/a3-start-debug.ps1`; `-Margin` as wanted). Compare with the table above.
5. `FEATURES.md` section 12 gets a fourteenth round: three places decide (reverses the thirteenth's
   default); `TRIED-BEFORE.md` a section 28 with the table above and the old app's answers 9; the
   handoff's first block; the roadmap rows.
6. One hash request on the test account (the owner's go), then the exact check on in a run.
7. **Breadth:** the copy to a test folder on the NAS, the viewer opened by the owner, the bring-in's plan
   on a copy of the old database.

## Open with the owner
- The acceptance run: exact check on (the owner's OK for that run), the owner's new group of duplicates is catalogue chat 13: `a3/a3-start-console.ps1 -ApproveRead 13` in the owner's window (untried script).
- The old app on the test account (the owner will look at it): settles account against app for the waits.

## Added 18:15: the integration is under way
An Opus coder merges the three branches in `wt-downloader` (branch `wip/downloader-2026-11-14`; notes in
`archiver/docs/progress/downloader-INTEGRATION.md` there; it commits after each merge). If the session
died: look at that file and `git -C wt-downloader log --oneline -5`, then start a fresh Opus coder to
finish what is missing (the prompt's content is in `SESSION-10-PROGRESS.md`, "integration started").
The waits and drops on the test account are judged to be Telegram's throttle on the account (the
progress file, 18:00): no more runs to hunt their cause; one real run at the end as the acceptance.

## Added 18:44: integrated; two reviews running
All three pieces are on `wip/downloader-2026-11-14` (`wt-downloader`, head c39f6b2). Two independent
reviews run (their files: `wt-review-dl-A-scratch/REVIEW.md` the window and the lane;
`wt-review-dl-B-scratch/REVIEW.md` the exact check and the collector's seams). If the session died:
read both files (start a fresh reviewer for one that is missing or stops mid-way), have one Opus coder
fix what must be fixed before a real run, then steps 3 to 7 of "Then" above. A second session for
breadth may be running from `START-SESSION-B.md`: it must not touch any of this.

## Added 19:31: the state at the tenth session's hand-over (READ THIS BLOCK FIRST; it supersedes "In flight" and "Then" above)
All three pieces and both reviews' fixes are on `wip/downloader-2026-11-14` (`wt-downloader`, head
d462838, local only). The full runs' logs are in `runs-10c/`: every race run passed; every Windows
package passed except the last ones still to read (`win-collector.log`, `win-cmd.log`, `win-gofmt.log`,
`win-vet.log`). **Do the six numbered steps at the end of `SESSION-10-PROGRESS.md`** (merge, documents,
push, build, the owner's run with `-ApproveRead 13`, read the numbers). No agent is running; nothing is
running against Telegram. The owner's rules of 11-14 are in that file's last 80 lines and in `CLAUDE.md`.

## Added 19:33: merged, pushed, built (this supersedes the block above where they differ)
The downloader is a28700f on `private`; the installed collector is built from it. **Next: the owner's
acceptance run** (their window, VPN on: `powershell -ExecutionPolicy Bypass -File a3\a3-sampler-start.ps1`
then `powershell -ExecutionPolicy Bypass -File a3\a3-start-console.ps1 -ApproveRead 13`), then read its
numbers against the two earlier runs. Still owed: the documents commit (FEATURES fourteenth round,
TRIED-BEFORE 28, the handoff's first block, roadmap rows).

## Added 19:44: the acceptance run is running; the owner's direction
- 19:44: the owner typed yes; chat 13 is being read and downloaded. **The owner's standing direction for the downloader (again, 19:44): "don't reinvent the wheel if the other/older engine has a better system that we've iterated on there. Just improve on it the best you can, if you can."** For the next session: read the acceptance run's numbers first (server 2 in the video phase against 4.85 to 5.6 MB/s; waits per request; window level; the exact check's lines for chat 13). If freeing the slot and the upward rule do not clearly beat the earlier runs, do NOT invent a third scheme: port the old app's pacing as it stands at 12.31 (`wt-v12.31/core-service/internal/telegram/pacer.go` and `floodguard.go`: a waiting part keeps its slot, the flood guard's per-server and account gates, the 60-a-second limiter, the short-wait rule of 12.30), keep the new engine's switches (`-sleep-keeps-slot`, `-window-policy careful`) for the comparison, and improve only where a number shows it. The run is the owner's window; stop it with `a3/a3-stop.ps1` or Ctrl-C there when nothing is wanted, then `touch a3/stop-sampler`.

## Added 20:57: the acceptance run is done: read the last block of SESSION-10-PROGRESS.md first
Speed unchanged (about 5 MB/s on server 2), waits doubled, the third part not kept; the exact check worked (43 hash requests, no wait, 8 windows per answer). Recommended and awaiting the owner: default back to a waiting part keeping its slot. Owed: the documents commit. Then breadth (START-SESSION-B.md).
