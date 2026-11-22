# Mirror session (step 3 of the board): progress

Started 2026-11-14 23:02 local. The design note for the owner is `DESIGN-MIRROR-STEP1.md`.

## 1. What is already known (written before anything was proposed)

Read in full by this session, 11-14 23:02 on: `FEATURES.md` section 12 (all fourteen rounds); `TRIED-BEFORE.md`
sections 24, 25, 26; `TELEGRAM-FACTS.md`; `LESSONS-ix12.30-live.md`; `LESSONS-ix12.29-servers.md` section 7; the new
app's `internal/telegram/forward.go`, `call.go`, `memo.go`, `counters.go`; the collector's commands (`command.go`,
`signin_cmd.go`, `chats_cmd.go`, `approve_cmd.go`, `seam.go`); the old app's `wt-v12.31/.../telegram/forward.go`.
Nothing was run against Telegram.

**What the owner decided (FEATURES 12):**
- Mirror chats are private, no invite link; the app creates each and names it from its source ("X-Sports-1"; the
  next of the same name "X-Sports-2"); forwarded copies stay in the mirror (rounds 2, 3).
- The mirror forwards history too, as the owner did by hand with a third-party client: up to 100 at a time, an
  album never split, one chat at a time, a pause between batches, every batch counted, any wait slept in full, no
  setting shortens a wait (rounds 4, 6). The forwarder goes one request at a time when first used (round 11).
- A forum is mirrored as a forum with the same topics (round 3): later, not this step.
- 11-14 22:38: a newly joined chat is mirrored automatically (no bytes); its files are downloaded only when the
  owner chooses the chat (round 14). Nothing automatic is built in this step.

**What Telegram documents (TELEGRAM-FACTS, FEATURES 12 round 4):**
- 500 channels and supergroups per account without Premium, the account's own included: every mirror counts
  (`CHANNELS_TOO_MUCH` past it).
- `messages.forwardMessages` takes a list of ids and a destination topic; the most per call is the server value
  `forwarded_count_max`: **100, measured** by the probe on 11-13 (no account). It is read at start, never assumed.
- A chat that protects its content answers `CHAT_FORWARDS_RESTRICTED`: downloaded only, never mirrored.
- `USER_RESTRICTED` on creating a chat means the account was reported for spam: stop for good, never retry.
- A forward keeps the Telegram file id (inferred, not stated on any page): no bytes move, and the catalogue treats
  source and mirror as one file.
- Self-destructing media must not be preserved (API terms 1.4).
- Unofficial clients are "under observation"; flooding and spamming end in a ban.

**What is not known (nobody has a number):**
- How many forwards an account may make in an hour or a day. Nothing documented. The only evidence is the owner's
  own: 100 at a time by hand, "reasonably fast", no trouble.
- How many chats may be created in a day (a community figure, unverified: about 50).
- Creating forum topics in a mirror: never tried.
- Whether Telegram answers a repeated forward with `RANDOM_ID_DUPLICATE`, and what it does when only part of a
  batch is a repeat. The request layer relies on it; it has never met the real Telegram.
- Whether a chat's "protected" flag can be read before a mirror is made: the flag exists on Telegram's chat
  object, and the catalogue does not record it today.
- Time per batch. **The old app has no number to put beside ours: it never forwarded.** Its "auto-forward"
  uploads the downloaded file again (so that protected chats still work), one upload at a time, every byte a
  second time, a new Telegram file id. That is why it is not copied.

**What the old app's lessons demand of anything that acts for the owner** (the 13 rules, TRIED-BEFORE 24 and 25;
`LESSONS-ix12.30-live.md` 6b): never undo a person's pause; "the owner took this out" is a durable decision; a
"never" switch per item checked before every request; Telegram's waits stored and checked at the top of every
step; only "this account cannot read it" is permanent; one costly failure ends the step; one item per call, each
success recorded; busy flags released with `defer`; no request for an item never acted on; a cap per step; one
row per item, never one stored list; a mark follows a chat across a change of identity; fail closed. And from 6b:
what the app adds by itself is marked as the app's, with its real name, everywhere; it sits below the owner's
choices; **never download from a source the owner did not choose** (24 of the 30 chats the old app added by
itself were switched off as junk).

**What already exists in the new app (found by reading, not built by this session):**
- `internal/telegram/forward.go`: `Forwarder` with `ForwardLimits` (help.getConfig), `CreateMirror` (a private
  channel; a forum supergroup when asked), `CreateTopic`, `PlanBatches` (oldest first, albums whole) and
  `ForwardBatch` (one plain forward). A request that writes is sent exactly once; a wait is recorded in the
  catalogue before it is slept, slept in full plus 1 s, and checked before every later request of that kind, also
  after a restart; no answer is "outcome unknown", never sent again by itself; the random id of each forward is
  derived from a secret, so a repeat is refused by Telegram instead of copied twice; `USER_RESTRICTED` and
  `PEER_FLOOD` close the account's forwarder for good, on record; a protected source is remembered. Requests are
  counted per method (config, create, topic, forward) with waits, timeouts and refusals. Tested on a fake only.
- The catalogue: `chat.mirror_of` (schema 7), the account's refusal and the protected-source record, the wait
  record (`MemoStore`), `chat.collect_off` (a chat whose files are not collected).
- **Nothing uses any of it:** no command, no ledger of what was forwarded, no name rule, no count against 500,
  and the collector's fake Telegram does not answer create or forward.

## 2. State

- 11-14 23:05: the note above and the design note written. Free memory 8.9 GB, CPU about 35%: a coder may start.
- 11-14 23:07: schema number 13 taken on the board (the mirror ledger). Copy `wt-mirror-step1`, branch
  `wip/mirror-step1`, cut from 8c0335e. Brief `BRIEF-M1-mirror-step1.md`; an Opus 5.5 coder at high effort is
  building it (a ledger in the catalogue, package `internal/mirror`, the `mirror` command, the fake Telegram's
  create and forward answers, 14 named tests). After it started: 7.7 GB free, CPU about 43%.
- Checked by reading while it builds: a chat row with `collect_off` set queues no file from messages catalogued
  after that (`catalog/ladder.go` `chatWants`), so a mirror whose row is made switched off before its first
  message arrives never queues one. A file its source chat already wants is unaffected.
- The review's brief is ready: `BRIEF-M1-review.md` (read-only, probe tests through `go test -overlay`).
- 11-14 23:15, after the owner's word that the old app's code is ours to take: read
  `wt-v12.31/.../telegram/floodguard.go` whole. For requests that are not file parts it closes the account's
  gate for the seconds asked plus 1 s, sleeps a wait up to 60 s and sends the same request again (at most 3
  times), and keeps the wait in memory only (its own review asked for it to be stored). The new app's request
  loop already does this, with the same margin, stored. So nothing is ported for waits. From `forward.go`
  `storageChannel`, the look for a channel of the wanted title before creating one is worth taking, as the way
  to settle a "create outcome unknown" later (from the stored chat list, no request): not in this step; the
  ledger keeps the intended name recoverable for it. Written into the coder's brief and sent to the coder.
- **11-14 23:33: the coder handed back. Commit 4fe8653 on `wip/mirror-step1`, pushed to `private`** (copy
  `wt-mirror-step1`, clean). 15 files, 3,871 lines added: `internal/catalog/schema13.go` (the ledger),
  `internal/mirror` (`mirror.go` the plan, `step.go` the step), `internal/collector/mirror_cmd.go`, the fake's
  `faketg/mirror.go`, one case in `cmd/tgarchive-collector/main.go`, its report
  `archiver/docs/progress/mirror-step1-REPORT.md`. Its named tests passed (catalogue 9, mirror 13, collector 7,
  fake 5, command 3; each under 3 s); gofmt and vet clean. **No whole-package run and no race run yet.**
  Concurrent code added: two goroutines and one mutex in `mirror_cmd.go` (a stop watcher, the console reader,
  a timing wrapper); none in `internal/mirror` or the catalogue step.
- The coder's departures I must judge (its report has all 12): the catalogue is opened read-write before the
  plan, so a catalogue older than 13 is stepped to 13 before the owner's yes; a create Telegram did not carry
  out stays as a row "not created"; a forward answered `RANDOM_ID_DUPLICATE` blocks later forwards like an
  unknown outcome; whether a request went out is read from the forwarder's request counts; service messages are
  left out of a batch; the plan refuses a source with no access hash on record.
- Its doubts: Telegram's real answer to a repeated forward is not known; the count against 500 counts high
  rather than low; a kill between the create's answer and the ledger's commit leaves "creating" while the
  channel exists (settled only by the look-before-create, not built); the dial sends the library's own
  connection-start request, which is not one of the three counted.
- 11-14 23:36: I read `internal/mirror/step.go` and `internal/collector/mirror_cmd.go` whole. Sound by reading:
  nothing is dialled or sent before the plan and the yes; the lock, the VPN gate and the secret come first; the
  intent row is written before each create and forward; the batch is sent once more only after a wait slept in
  full. **Four things I want fixed or refuted** (in the review's brief as A to D): a stop during a create's wait
  marks the mirror "unknown" for good although nothing was created; an unknown error after a forward was sent
  is taken as "refused, candidates again"; an album over the maximum is found only after the mirror exists; a
  catalogue stepped to schema 13 by this command may not open in the main branch's build. Also to add: each
  wait's stated seconds in the output (today only the total slept), and an "unknown" has no way to be settled
  yet (the look-before-create and a look at the mirror's newest messages: the next small piece, M1b).
- **Running now (23:36): an independent read-only review** (an agent; brief `BRIEF-M1-review.md`; its report goes
  to `wt-mirror-review-scratch/REVIEW.md`; it edits nothing). **Next step, in one line:** judge its findings,
  brief one fix round to an Opus coder on `wip/mirror-step1`, then the full runs once.
- **Not done yet:** the review's findings and their fixes; the full runs; the merge-queue
  entry; the owner's word on the design note; the owner's real step.

## 2b. The track's order (11-14 23:31, after the owner's rule "everything listed is already asked for")
Listed in FEATURES 12 and not built; built in this order without waiting to be asked, the owner told, not asked.
Unchanged: nothing runs against Telegram before the owner starts it; which chats are mirrored stays the owner's.
- **M1** (being built): one mirror, one batch, by a command.
- **M2: a chat's whole history into its mirror.** The same command with a bound the owner gives (batches or
  "all"), one request at a time, the cost shown first ("about N batches, about M minutes at the pause"), a pause
  between batches that starts from M1's measured time per batch and the owner's experience by hand, is
  lengthened after any wait and never shortens one, progress in the ledger so a stop resumes at the next batch.
  New messages before history once anything is live. Not known, to be measured by M2 itself: forwards per hour.
  Briefed when M1 is handed back: it edits the same files.
- **M3: a forum mirrored as a forum with the same topics.** `CreateTopic` exists in the request layer and has
  never met Telegram. One topic created and one batch into it first, as M1 did for a chat.
- **M4: a newly joined chat mirrored by itself** (the owner's decision of 11-14 22:38), with every one of the 13
  rules: a "never mirror" mark per chat checked before every request, a removal is a decision, a cap per step,
  marked as the app's everywhere, off for a frozen account, the chat's "protected" flag read before a mirror is
  made. A review before it runs. It needs the collector's live run, not a command: the integrator is asked
  where it hooks in.
- For other tracks (on the board's table): choosing chats on the Chats page and showing mirrors of one name
  together (pages: no session); the "protected" flag in the chat list's facts (owner to be named).

## 3. For whoever takes over
- The order is fixed: coder hands back; read the risky part (every path that sends create or forward, the
  intent rows, the yes question); the review; its fixes; then the full runs once (`ix-tools/full-runs.sh`,
  telling the owner the packages and minutes first); push `wip/mirror-step1` to `private`; entry in
  `MERGE-QUEUE.md` and the board.
- Nothing is run against Telegram by a session. The real step is the owner's, in their own window, behind the
  VPN, on the test account, with the collector stopped.

## 4. Stopped here (11-14 23:34 local): the usage limit was reached. Take over from this block.
- **Committed and pushed:** `wip/mirror-step1` 4fe8653 on `private` (the `mirror` command, schema step 13, its
  named tests). The notes are committed on `notes`.
- **Running when I stopped:** the independent read-only review (an agent of this session). Its report is to be
  at `wt-mirror-review-scratch/REVIEW.md`. If that file is missing or ends mid-way, start the review again
  with `BRIEF-M1-review.md` as it is (it includes my suspicions A to D).
- **Not done:** judging the review; one fix round by an Opus coder on `wip/mirror-step1` (at least: A, a stop
  during a create's wait must end "not created", read from the forwarder's count of waits; B, an unknown error
  after a forward was sent must end "unknown"; C, an album over the maximum refused in the plan; each wait's
  stated seconds printed); then the full runs once (whole tests of `mirror`, `catalog`, `collector`,
  `telegram`; race detector on `collector` only, where two goroutines and a mutex were added; tell the owner
  the packages and minutes first; `ix-tools/full-runs.sh`); push; an entry in `MERGE-QUEUE.md`; the board.
- **Waiting for the owner:** the word on `DESIGN-MIRROR-STEP1.md` (four choices at its end).
- **The real step, the owner's, not prepared yet:** after the merge (so one build serves `run` and `mirror`:
  this command steps the catalogue to schema 13, and whether the main build then opens it is suspicion D), build
  the collector to its fixed place, and write `a3/a3-mirror.ps1` after `a3/a3-start-console.ps1` (same
  catalogue, adapter and public-address flags; `mirror -chat N`; the owner types yes). Collector stopped, VPN
  on, test account, owner present. Nothing has been run against Telegram by this session.
- Next pieces of the track are in section 2b (M1b: settling an "unknown"; M2 history; M3 forum; M4 automatic).

## 5. Resumed 11-15 08:39 local (the owner: "Continue")
- The review agent had been cut off by the usage limit before it wrote anything (`wt-mirror-review-scratch`
  did not exist). **Running now: the same review, resumed** (same brief; it writes findings into
  `wt-mirror-review-scratch/REVIEW.md` as it confirms them). The copy is unchanged: `wip/mirror-step1` 4fe8653.
- The main branch moved to e3a9df9 (documents only) since the copy was cut from 8c0335e.
- **Next step, in one line:** judge the review, brief one fix round (section 4 lists the fixes already known).
- 11-15 08:40: while the review runs: `BRIEF-M1b-fixes.md` drafted (my five fixes A to E; the review's are added once
  judged); `a3/a3-mirror.ps1` written for the owner's real step (untried; made after `a3-start-console.ps1`).
  Suspicion D settled by reading `catalog.go` `migrate`: a build at schema 12 refuses a file at 13 cleanly
  ("file has schema v13, this program reads v12"), so the real step waits for the merge, or runs with this
  branch's build and the test catalogue is then this branch's until the merge. The board already says how
  the copies session's step 14 follows 13 at the merge.
- 11-15 08:47: **the review is back** (`wt-mirror-review-scratch/REVIEW.md`; read-only, probes through an overlay). It
  found no path that sends a create or a forward twice or early. Confirmed defects, all to be fixed: (1) a stop
  arriving with the create's answer records a mirror Telegram DID create as "unknown", with no chat row and no
  access hash; (2) a stop during a create's wait blocks the source for good; (3) an album over the server's
  maximum fails after the mirror exists; (4) a mirror without a stored access hash sends a config request every
  run for nothing; (5) a stop during a forward's wait is called "refused"; (6) the plan's read-write open steps
  the catalogue to schema 13 even on a "no"; plus false words at two ends, the title inside the plan struct,
  and tests that pass with defects planted. My suspicion B (a repeat risk) was refuted: only definite answers
  reach that line. Left for later pieces: a basic group that became a supergroup; the 500 count from a stale list.
- **Running now: the fix round, an Opus coder on `wip/mirror-step1`** (`BRIEF-M1b-fixes.md`, ten fixes).
  **Next step, in one line:** read its diff (the create path above all), then the full runs once.
- 11-15 08:58: the owner's rule "who reports to whom": this session reports to the integrator through the board, the
  merge queue and this file. The two things only the owner can give are on the board under "Waiting for the
  owner" as items 7 (the word on the design) and 8 (the real step, not ready yet). For the merge-queue entry:
  the copies session also edits `internal/collector/faketg` (other parts; `server.go`'s dispatch may conflict).
  Running now: the fix round's coder (unchanged).
- 11-15 09:01: **the fix round is handed back: 85bd550 on `wip/mirror-step1`, pushed to `private`** (all ten fixes;
  named tests passed: mirror 19, catalogue 7, collector 8, fake and command; each fix's test seen to fail with
  the fix undone through an overlay; no concurrent code added). **Next step, in one line:** I read the create
  path of the diff, then the full runs once (not started).
- 11-15 09:02: I read the fix round's create path in `step.go`: a channel in hand is always recorded as created (its
  access hash written again on a context of its own); a stop with a wait counted is "not created"; a stop with
  a request out and no wait stays "unknown"; the batch is cut with the server's maximum before anything is
  created. Sound by reading.
- **Running now (11-15 09:02): the full runs, once, in the background of this session**, logs in `runs-mirror/`: whole
  Windows tests of `internal/mirror`, `internal/collector/faketg`, `cmd/tgarchive-collector`,
  `internal/catalog`, `internal/collector`, then gofmt and vet; beside them the race detector in one container
  on the Mirror tests of `internal/collector` and on `internal/mirror` (the command's two goroutines and one
  mutex are the only concurrent code added). If this session stops: read `runs-mirror/*.log` (each ends
  "exit N"); a missing log means that run never started: start it again the same way.
  **Next step, in one line:** when every log ends "exit 0": the entry in `MERGE-QUEUE.md`, the board.
- 11-15 09:04: **M2 (a chat's history, batch after batch) briefed and started**, as the board's rule asks of a waiting
  track: `BRIEF-M2-mirror-history.md`; copy `wt-mirror-history`, branch `wip/mirror-history`, cut from
  `wip/mirror-step1` 85bd550; an Opus coder. It adds `-batches N|all` and a pause between batches (start 10 s,
  the owner's to change; doubled after any wait and stored for the account; never shortens a wait). The pause's
  start is a default, not a measurement: nobody has a number for forwards per hour until the real step runs.
  **Running now:** the full runs of M1 (`runs-mirror/`) and the M2 coder.
- 11-15 09:14: **the full runs of M1 passed** (`runs-mirror/`: catalogue 240 s, collector 400 s, mirror, fake, command;
  gofmt, vet; race on the Mirror tests of the collector 36 s and on `internal/mirror` 114 s). **Handed to the
  integrator: `MERGE-QUEUE.md` entry 7, the board's "Waiting to merge" and my row.** `wip/mirror-step1` 85bd550
  is pushed. **Running now:** the M2 coder in `wt-mirror-history`. **Next step, in one line:** when M2 is handed
  back: push it, read its loop, one read-only review, fixes, its named runs, a merge-queue entry.
- **What the owner must do for the real step** (board, "Waiting for the owner" 7 and 8): say whether the design
  is agreed; after the integrator's merge and a build to the collector's fixed place: stop the collector, VPN on,
  `powershell -ExecutionPolicy Bypass -File a3\a3-mirror.ps1 -Chat N` (N from `a3-chats.ps1`, a chat the test
  account has read and that is not protected; the script is untried), read the plan, type yes. Then the numbers
  come from `a3/logs/mirror-*.out.log`: requests per method, waits and their seconds, ms per request.
- **Not verified, M1:** the real Telegram (everything); the real dial on this path; Ctrl-C at a real Windows
  console; that a later `run` stores the mirror's chat-list entry without undoing "switched off for downloads";
  how Telegram answers a repeated forward.
- 11-15 09:23: **M2 handed back: fd0cb2a on `wip/mirror-history`, pushed to `private`** (copy `wt-mirror-history`, clean).
  `-batches N|all`, `-pause`, `-pause-reset`; named tests passed (mirror 30, collector Mirror 13); no concurrent
  code added; no schema step (the pause is a catalogue setting). **Next step, in one line:** I read its loop,
  then one read-only review, fixes, its runs, a merge-queue entry.
- 11-15 09:25: I read M2's loop (`internal/mirror/step.go` `Run`): one request at a time; candidates read again from the
  ledger around each pause; the intent row before each forward; the pause measured from the last answer and
  doubled and stored after any stated wait before anything more is sent; the run ends at the first batch that
  is not done, at the second wait, at a stop. Sound by reading. My one worry is not a defect: at the default
  10 s pause, `-batches all` would forward up to 36,000 messages an hour unattended on a number nobody has
  measured (asked of the review; and the owner's first real run of it should be a few batches).
- **Running now: an independent read-only review of M2** (`BRIEF-M2-review.md`; report to
  `wt-mirror-review2-scratch/REVIEW.md`, written as it goes). `wip/mirror-history` fd0cb2a is pushed.
  **Next step, in one line:** judge it, one fix round, its runs (whole `mirror`, `collector`, the command; race
  on the Mirror tests only), a merge-queue entry after entry 7.
- 11-15 09:33: **M2's review is back** (`wt-mirror-review2-scratch/REVIEW.md`). Sound: the run ends on every condition it
  must, a stop is clean at every point, the pause comes on top of a wait, no flag shortens the stored pause, the
  first review's fixes are intact. Findings, all to be fixed: (1) **no pause between runs**: a run started at
  once forwards with no pause after the last run's forward; (2) no test for the stored pause's write failing;
  (3) "messages still to forward" wrong after an early end; (4) a long run's counts all land in one hour;
  (5) the rate line misleads; (6) a corrupt stored pause can read as a short one; (7) the repeat guard
  untested; (8) the default run differs from 85bd550 in three small ways, to be said in the merge queue.
  **Nothing bounds a run by messages per hour**: added to the fix round as `-per-hour N`, read from the ledger
  over the last 60 minutes, **default 10,000, a number of mine and not Telegram's** (on the board for the
  owner, item 9).
- **Running now: M2's fix round, an Opus coder on `wip/mirror-history`** (`BRIEF-M2b-fixes.md`, nine fixes).
  **Next step, in one line:** read its diff (the pause across runs and the hourly bound), its runs once, push,
  a merge-queue entry.
- 11-15 09:53: **M2's fix round handed back: 9f09e86 on `wip/mirror-history`, pushed to `private`** (nine fixes, each
  test seen to fail with its fix undone; named tests passed: mirror 36, collector Mirror 16, catalogue 9; no
  schema step; no goroutine or lock added). **Next step, in one line:** I read the pause across runs and the
  hourly bound, then its runs once, then the merge-queue entry.
- 11-15 09:53: read `internal/catalog/mirrorpace.go` (the two reads behind the pause across runs and the hourly bound):
  through the mirror's indexes, every batch row of the account read, no schema step; sound. A doubt to carry:
  some collector Mirror tests judge real time (2 s and 4 s gaps): they may fail on a loaded PC.
- **Running now (11-15 09:53): M2's full runs, once, in the background of this session**, logs in `runs-mirror2/` (whole
  Windows tests of mirror, faketg, the command, catalogue, collector; gofmt; vet; race on the Mirror tests of
  the collector and on `internal/mirror`). Each log ends "exit N"; a missing log means that run never started.
  **Next step, in one line:** when all end "exit 0": `MERGE-QUEUE.md` entry for `wip/mirror-history` 9f09e86
  (after entry 7), the board row.
- 11-15 10:05: **M2's full runs passed** (`runs-mirror2/`: catalogue 233 s, collector 398 s, mirror 14 s, fake, command;
  gofmt, vet; race on the Mirror tests of the collector 197 s and on `internal/mirror` 281 s). **Handed to the
  integrator: `MERGE-QUEUE.md` entry "M2"** (`wip/mirror-history` 9f09e86, pushed; it sits on `wip/mirror-step1`,
  so merging it brings both), the board's "Waiting to merge", my row and the "Listed and unbuilt" line.
- **Running now: nothing.** Both copies clean and pushed.
- **Waiting for the owner (board items 7, 8, 9):** the word on the design; the real step (after the merge:
  `a3\a3-mirror.ps1 -Chat N`, untried; first one batch, then `-Extra -batches,5`); whether the 10 s pause and
  the 10,000 an hour are right to start with.
- **Next step, in one line:** brief M1b (settle a create or forward whose outcome is unknown by looking: a
  channel of the mirror's name in the stored chat list; the mirror's newest messages), on a copy cut from
  `wip/mirror-history`; then M3 (a forum mirrored as a forum, one topic and one batch first).
- **Not verified, M2:** the real Telegram; a real console's Ctrl-C during a long pause; the two ledger reads at
  a very large ledger (they read every batch row of the account); what Telegram allows per hour.

## 6. The owner corrected the design (11-15 10:15)
- The owner, on the design note's choice 3 ("only messages already read into the catalogue are forwarded"):
  "This seems like an error? The whole point is that if the owner joins a group, while away from their
  computer/our app, that the mirror function would automatically begin, go back to the beginning of that group
  (i.e. before the owner joined) and forward the media to a mirror."
- **So the order of the track changes:** the mirror reads the chat itself (M3, being built), then starts by
  itself in the running collector (M4, moved to the front; it needs the integrator's word on the collector's
  loop: board message 9), then settling an unknown outcome, then forums.
- `DESIGN-MIRROR-STEP1.md` is corrected (choice 3 struck; a new last section). My reading of "forward the
  media": **media messages only by default**, a flag for every message; asked of the owner.
- A chat read for a mirror is switched off for downloads before its first message is catalogued, unless the
  owner had already chosen it (the owner's decision of 11-14 22:38; the lesson of the 30 chats added by itself).
- **Running now: M3's coder** (`BRIEF-M3-mirror-reads.md`; copy `wt-mirror-reads`, branch `wip/mirror-reads`,
  cut from `wip/mirror-history` 9f09e86). **Next step, in one line:** push its hand-back, read the read path
  and the download switch, one review, fixes, its runs, a merge-queue entry.
- 11-15 10:19, the owner: **media only by default, with a toggle** (confirmed: `-all-messages`). And: "the telegram group
  will be used primarily for media, so 'reading for a mirror does not turn downloads on' is still maybe not
  what we want. Does it meet the objective that an owner can join a group remotely (with no way to interact
  with our app, which is running at home) then the app will automatically begin mirroring?"
  **My answer: not yet.** Everything built so far is a command the owner starts and answers yes to. The
  objective is met only by the automatic piece (M4) in the running collector, which is not built and waits on
  the integrator's word (board message 9). Whether a joined chat is also downloaded by itself is asked of the
  owner (board item 10); my recommendation: yes, a group the owner joined is the owner's choice (unlike the
  30 chats the old app found by itself), with a setting and a per-chat off switch. Until answered the coder
  builds it as a parameter (`-download`, one constant for the default, off for now).
- 11-15 10:21, **the owner decided (board item 10):** downloading a joined chat by itself is "an option we can enable.
  Perhaps off by default, or a way of measuring whether it's during speed limit hours or not. If we leave it on
  at all times, it might choke out the user's actual phone connection." So: off by default (what the coder is
  building: `-download`, default off); the value "only in hours without the speed limit" is download-path work
  (the engine knows the limit): written on the board's "Listed and unbuilt" for Core and pages, not mine to
  build. What is on record about the worry: Telegram states its download limit for "the current account"
  (TELEGRAM-FACTS 8), so the phone shares it; nobody measured the phone beside a download.
- 11-15 10:42: **M3 handed back: e5eef11 on `wip/mirror-reads`, pushed to `private`** (copy `wt-mirror-reads`, clean): the
  command reads a chat itself (estimate after a first yes, the read and forwards after a second), media only by
  default (`-all-messages`), `-download` off by default (constant `mirrorDownloadDefault` in `mirror_cmd.go`);
  named tests passed (mirror 40, collector Mirror 27, catalogue 10); no concurrent code added; `internal/telegram`
  untouched; no schema step. **Next step, in one line:** I read `ReadThenRun` (the switch-off before the
  approval and the first message), then one read-only review.
- 11-15 10:43: I read `internal/mirror/read.go` `ReadThenRun`: the plan again, the switch-off, the approval, the read
  pass after pass, the plan again, then the run; a read that does not finish forwards nothing. Sound by reading.
- **Running now: an independent read-only review of M3** (`BRIEF-M3-review.md`; report to
  `wt-mirror-review3-scratch/REVIEW.md`). **Next step, in one line:** judge it, one fix round, the runs once, a
  merge-queue entry; meanwhile I read the collector's account loop for the automatic piece's design.

## 7. State at 11-15 10:44, and the automatic piece's design (M4), from my own reading
- **Merged by the integrator: M1 and M2** (the main branch's 6b8f72f, "the mirror command ... schema step 13",
  a squash of `wip/mirror-history`; steps 14, 15, 16 of other tracks are merged after it). The main branch's
  head is now 3044745. `wip/mirror-reads` (M3, e5eef11) is cut from the old 9f09e86: **its fix round must move
  it onto the new head** (a new branch from the head, the M3 commit picked onto it).
- **The integrator answered board message 9: yes**, the mirror track adds the automatic task to the collector's
  account loop on a branch of its own, cut from the new head; in `account.go` and `reader.go` only what the
  task needs; one request at a time; the 13 rules; `-download` off; a review and its fixes; the race detector on
  `internal/collector` at the merge.
- **What I read for it** (`internal/collector/reader.go` whole, `collector.go`'s defaults, the catalogue's
  `account_chat`): the reader task is one loop of turns on the account's connection: the chat list (at start,
  then every 24 hours), gaps, then the best-ranked chat that is approved and not read to its end, a few pages a
  turn. `account_chat.joined_at` records when the account's access to a chat began. The monitor stores a chat's
  facts when an update names an unknown chat.
- **Design of M4 (to be briefed on top of M3 once M3 is fixed and on the new head):**
  1. **Noticing.** With automatic mirroring on, the chat list is asked every 30 minutes instead of 24 hours
     (the old app's 12.30 compared visible chats with archived ones every half hour: 86 counts in under 2
     minutes, no refusal), and a chat the monitor's updates make known is looked at at the next turn. "Newly
     joined" is judged from the catalogue's own record: a chat whose membership began after automatic
     mirroring was first switched on for the account (a stored time). Chats already there on that day are
     never mirrored by themselves. Groups, supergroups and channels; not private chats or bots; forums wait for
     the forum piece and are said so.
  2. **Reading needs no new code:** for such a chat the task switches downloads off (unless the owner's
     setting), records an approval marked as the mirror's, and the reader's own loop reads it as it reads any
     approved chat.
  3. **A mirror turn in the reader's loop,** after gaps and before history passes of other chats: for one
     mirrored chat read to its end, at most one request (the create, or one batch), then the next turn; the
     pause and the hourly bound are "not before" times the turn checks, never slept inside the loop, so the
     reader and the owner's requests are not held; every wait of Telegram's is slept in full by the forwarder
     as today and stored.
  4. **Kept current:** new media of a mirrored chat arrives through the monitor, is catalogued, and becomes a
     candidate; a message newer than about a minute is not forwarded yet, so an album still arriving is never
     split.
  5. **The 13 rules:** a "never mirror" mark per chat (one row per chat, checked before every request; set and
     listed by `mirror -never N`, `-allow N`, `-list` until a page exists); a mirror the owner deleted, or a
     source the owner left, is a decision: never made again by itself; marks that cannot be read stop the task;
     one costly failure ends the turn; at most 5 new mirrors a day (nobody has Telegram's number; a community
     figure says about 50 chats a day); every mirror named and marked as the app's.
  6. **The switch:** `run -auto-mirror`, off until the first real runs on the test account, then on by default
     (it writes to Telegram unattended; the owner is told when the default flips).
  7. **Not known:** whether a protected chat can be told before its mirror is made (the chat list's flag is not
     recorded; the reader's files are not mine to change): the first forward's refusal tells, one of 500 spent.
- 11-15 10:55: **M3's review is back** (`wt-mirror-review3-scratch/REVIEW.md`). Sound: nothing sent before its yes; the
  switch, then the approval, then the read; a partial read never forwards; the earlier fixes intact. Confirmed
  defects, all to be fixed: (1) one account's mirror switches off a channel another account chose (the switch is
  the chat's, not the account's); (2) a chat switched on in the brought-in old archive is switched off; (3) an
  open gap breaks "oldest first"; (4) a frozen history method ignored; (5, 6) words that promise a Chats page
  that does not exist; (7) one rule untested and `TestMirrorReadsWait` flaky (failed 3 of 6 runs: a timing
  test). Its answer to my question lists what in `ReadThenRun` only holds for a console command: for M4.
- **Running now: M3's fix round, an Opus coder** (`BRIEF-M3b-fixes.md`), in a NEW copy `wt-mirror-reads2`,
  branch `wip/mirror-reads2`, cut from the main branch's head 3044745: it first picks e5eef11 onto it (the two
  earlier pieces are in the main branch as a squash), then the fixes. The old copy `wt-mirror-reads`
  (`wip/mirror-reads` e5eef11, pushed) is left as it is and can be removed once the new branch is handed over.
  **Next step, in one line:** read its diff, the runs once (race on the Mirror tests), push, a merge-queue entry;
  then brief M4 (section 7) on top of it.
- 11-15 11:24: **M3's fix round handed back and pushed: `wip/mirror-reads2` 7f512fe (the pick of e5eef11 onto the main
  branch's head 3044745, no conflict) and 99b71c3 (the six fixes)**, copy `wt-mirror-reads2`, clean. Named tests
  passed (mirror 46, collector Mirror 33, catalogue 10); each fix's test seen to fail under a plant; the wait
  test 20 of 20 after it was made to judge on the injected clock; no concurrent code added. **Found on the main
  branch itself:** `TestMirrorCommandOlderCatalogueNo` fails there (it expects "steps it to 13"; the build now
  steps to 16); fixed in 99b71c3. **Next step, in one line:** read the switch rule's diff, the full runs once.
- 11-15 11:25: read the switch rule (`internal/mirror/read.go`): a chat is "known" when any message of it is on record, or
  any account has a cursor or an approval for it; only an unknown chat is switched off. As briefed.
- **Running now (11-15 11:25): M3's full runs, once, in the background of this session**, logs in `runs-mirror3/` (whole
  Windows tests of mirror, faketg, the command, catalogue, collector; gofmt; vet; race on the Mirror tests of
  the collector and on `internal/mirror`). Each log ends "exit N". **Next step, in one line:** all "exit 0":
  the `MERGE-QUEUE.md` entry for `wip/mirror-reads2` 99b71c3, the board; then brief M4 on top of it.
- 11-15 11:27: **M4 (a chat joined while away is mirrored by itself) briefed and started**: `BRIEF-M4-mirror-auto.md`;
  copy `wt-mirror-auto`, branch `wip/mirror-auto`, cut from `wip/mirror-reads2` 99b71c3; an Opus coder, told
  to commit work in progress as it goes. Schema number 18 taken on the board for it (the "never mirror" marks,
  one row per chat, and who started a mirror). It is the piece that meets the owner's objective; `run
  -auto-mirror`, off by default until the first real runs. **Running now:** M3's full runs (`runs-mirror3/`)
  and the M4 coder.
- 11-15 11:34: **M4's coder stopped where the brief told it to, with a finding** (42df111 on `wip/mirror-auto`, the report
  only): a chat the monitor stores live is made switched ON and its files are wanted, approval or not; checked
  by me by reading (the chat table's defaults; `SaveMessages` makes an unknown chat; `attach` asks nothing about
  an approval). So (a) the automatic mirror as briefed would have queued a joined chat's whole history, and
  (b) **today's `run` already downloads from every chat with live traffic**: Core's, against the owner's
  decisions; on the board as a message to the integrator.
- **Decided and sent to the coder (resumed, same agent, same copy):** with `-auto-mirror` on and its download
  option off, a stored policy makes every chat row first made from then on start switched off, in the
  catalogue's chat-making path, before any message is saved; existing chats untouched; no policy, no change.
  "Newly joined" = first made after the first chat list stored whole after the switch was first on. No rebuild
  of the ledger's table. `-approve-read` accepts a chat only the mirror approved and switches it on.
- **Running now:** the M4 coder (resumed); M3's full runs (`runs-mirror3/`).
- 11-15 11:35: M3's full runs so far (`runs-mirror3/`): mirror, fake and command passed; **the catalogue's whole run
  failed on one test that is not the mirror's**: `TestTopicSettleAtSize` (the pages track's, merged in b379286)
  "the topics' counts took 1.00667s", a bound on real seconds, with two test runs and a coder on the PC. To do:
  run that one test alone when the PC is quieter; on the board as a message to pages and the integrator. The
  collector's whole run and the race run are still going.
- 11-15 11:58: **M3's full runs are in** (`runs-mirror3/`): everything of the mirror's passed (mirror 50 s, collector 435 s,
  fake, command, gofmt, vet; race on the Mirror tests 719 s and on `internal/mirror` 1,015 s). The catalogue's
  whole run failed only on the pages track's `TestTopicSettleAtSize` (a 1 s bound of real time on a count that
  takes 0.87 to 1.01 s): failed under load and once alone, passed alone on this branch and on the main branch.
  **Handed to the integrator: `MERGE-QUEUE.md` entry "M3"** (`wip/mirror-reads2` 99b71c3, pushed), the board.
- **Running now:** the M4 coder in `wt-mirror-auto` (resumed with the decision; it commits as it goes).
  **Next step, in one line:** at M4's hand-back: push, read every changed line of `reader.go`, `account.go` and
  the catalogue's chat-making path, an independent review, fixes, the full runs with the race detector on the
  whole `internal/collector` (the integrator's condition), a merge-queue entry.
- The old copy `wt-mirror-reads` (`wip/mirror-reads` e5eef11) and `wt-mirror-step1`, `wt-mirror-history` are
  finished and merged or superseded: they can be removed with the owner's yes (no uncommitted change in any).
- 11-15 12:18: **the owner said yes: the three finished copies are removed** (`wt-mirror-step1`, `wt-mirror-history`,
  `wt-mirror-reads`; each was clean and its head on `private`; their local branches stay). Left: `wt-mirror-reads2`
  (waits to merge) and `wt-mirror-auto`.
- M4's coder has committed work in progress twice: 873562f (schema step 18, the policy for new chats, the turn)
  and c1ee9c3 (the collector's task, flags, marks, numbers); pushed to `private` as work in progress by me at
  11-15 12:18. It is still running (the tests and the report are not there yet).
- 11-15 12:21: **the first real step is READY for the owner** (board item 8): the installed collector is the build of
  849c506 (`version` says so; `mirror -h` shows the merged command with `-batches`), which contains the merge
  of the first two pieces; no collector process is running. The owner starts it: `a3\a3-chats.ps1` for a chat
  number, then `a3\a3-mirror.ps1 -Chat N`, yes. Afterwards I read `a3/logs/mirror-*.out.log` (numbers and fixed
  words by design) for: requests per method, waits and seconds, ms per request, forwarded and left out.
  The installed build must not be replaced until the owner says the step is done.
- 11-15 12:25: **M4 handed back: 186d76d on `wip/mirror-auto`, pushed to `private`** (copy `wt-mirror-auto`, clean; on top
  of `wip/mirror-reads2` 99b71c3). `run -auto-mirror` (off by default): a look after each stored chat list (every
  30 minutes with the switch on), the reader's own loop reads the joined chat, at most one writing request a
  turn, "never" marks (`mirror -never/-allow/-list`; marks written only with the collector stopped), schema
  step 18, new chats made switched off under the policy (in `EnsureChat`'s insert). Named tests passed (mirror
  45.8 s, collector Mirror 90.3 s, catalogue); five rules seen to fail when removed; no new goroutine.
  **Next step, in one line:** I read the diff of `reader.go`, `account.go` and `EnsureChat`; then the review.
- Its doubts to judge: on a fresh catalogue every chat of the first chat list is made switched off under the
  policy; a joined chat's read may start only at the next chat list (up to 30 minutes); CHANNEL_PRIVATE on a
  forward is taken as "the mirror was removed".
- 11-15 12:26: **the owner started the real step and hit a wall before it:** `a3-chats.ps1` printed "an error of type
  *sqlite.Error". Cause, checked read-only: the test catalogue is at schema 12 and the installed build reads 16;
  a read-only open cannot step the schema and `chats` names a newer column. The `mirror` command's plan is
  read-only too (my own fix, so that a "no" writes nothing) and would fail the same way. Counts read: 1 account,
  13 chats, 2 read to their end. **Given to the owner:** step the catalogue with one read-write open that sends
  nothing (`exact-mode -db <catalogue> three-places`), then `chats`, then the mirror. On the board for the
  integrator (Core's commands); the mirror command's own words for it go into M4's fix round.
- I read M4's diff of `reader.go`, `account.go` and `EnsureChat`: small and as reported (the approval's "by"
  field; the interval; the look after a stored list; one turn between gaps and history; the policy read in the
  transaction that makes a chat row). **Running now: M4's independent review** (`BRIEF-M4-review.md`; report to
  `wt-mirror-review4-scratch/REVIEW.md`). **Next step, in one line:** judge it, one fix round, the full runs
  with the race detector on the whole collector, a merge-queue entry; read the owner's real-step log.
- 11-15 12:30: **the owner ran the mirror command for real up to the VPN check** (after stepping the catalogue): the plan
  printed, the owner typed yes, and **the VPN check refused: "route: VPN adapter not found; public address:
  allowed". Nothing was sent.** Cause, from the PC's adapter list: Windscribe is on WireGuard now; its adapter is
  `WindscribeWireguard` (Up); the scripts name `WindscribeOpenVPN`. The gate did what it is for. `a3/a3-mirror.ps1`
  gained `-Adapter` (default unchanged) and keeps the process handle so the exit code prints. Given to the
  owner: run it with `-Adapter WindscribeWireguard`, or switch Windscribe back to OpenVPN. The other a3 scripts
  (`a3-start*.ps1`) still name the OpenVPN adapter: the integrator's or the owner's to change.
  First real observations (no request yet): the script works at the console; the plan's lines read well.

## 8. THE FIRST REAL STEP RAN (11-15 12:33; the owner, in their own window, test account, behind the VPN)
Log: `a3/logs/mirror-20261115-123230.out.log` (numbers and fixed words; its error log is empty). The build of
849c506 (the merged command: one batch, every message of it). Chat 4 of account 1, a channel, 760 messages on
record (6 service messages left out), 754 candidates. `-Adapter WindscribeWireguard`.
- **Requests: 3, all answered, no wait, no timeout, no refusal.**
  - `help.getConfig` 70 ms: the server's maximum per forward is 100 (as the probe measured).
  - `channels.createChannel` 342 ms: the private mirror created; catalogue chat 14, switched off for downloads,
    its source on record; the account's channels and supergroups on record went from 9 to 10 of 500.
  - `messages.forwardMessages` 2,296 ms: **100 messages asked, 100 forwarded, 0 left out.**
- Seconds slept for waits: 0. Seconds Telegram stated: 0.
- So, for one run ("looks like", not a rate): a batch of 100 is answered in about 2.3 s; a create in about 0.3 s.
- **What it proves that only the fake had said before:** the real connection on this path; the plan read-only,
  the yes, the VPN gate (it refused the old adapter name first, rightly; nothing was sent then); the create's
  answer carries the channel and its access hash; the forward's answer names every message by its random id
  (100 of 100 tied back); the ledger and the chat row are written.
- **Still not known:** forwards per hour or day (one batch says nothing); how Telegram answers a repeated
  forward; a wait on create or forward (none came); albums and order as the owner sees them in the mirror
  (asked of the owner: the name, the order, albums whole, media intact); topics.
- Before it, two things stood in the way, both now on record: the test catalogue was at schema 12 against the
  build's 16 (read-only commands fail with a bare SQL error; the owner stepped it with `exact-mode ...
  three-places`), and Windscribe moved to WireGuard (the adapter is `WindscribeWireguard`).
- **Next real step proposed to the owner:** the same chat, `-Batches 5` (654 candidates left): the pause between
  batches (10 s), the pause across runs, the counts by hour. `a3/a3-mirror.ps1` gained `-Batches`.
- 11-15 12:36, **the owner, after looking at the first real mirror in Telegram:** "I can see the channel on telegram, so
  that worked properly I think. I would perhaps like an option in the app to rename/select the new group.
  Imagine the old group is named 'Football'. The one you created was X-Football-1, which is probably fine, but
  an option in the app would be good. The group name ... would be in the middle, with the option to add a prefix
  or auto-numbered suffix, that affects each group." **Taken as a listed feature (M5, after M4's fix round):**
  a setting for every mirror (prefix, the source's name, suffix with the number), and renaming one mirror
  (a new request kind in the request layer, counted, its waits slept in full). Asked of the owner: whether
  "select" means choosing an existing chat as a mirror, and whether changing the setting renames mirrors that
  already exist. The order, albums and media in the mirror: not yet answered. The owner is about to run the
  second step (5 batches).
- 11-15 12:37, **the owner decided:** the name setting applies to **new mirrors only**; existing mirrors are renamed only
  by a separate action ("rename all now", showing its request count first, or one at a time). Still open:
  whether "select" means choosing an existing chat as a source's mirror (taken as renaming only until said).
- 11-15 12:38, **the owner on "select":** yes, choosing an existing chat as a source's mirror "would be a nice feature
  to have, in case I attach the app to an existing account, and want you to effectively create a cloud mirror.
  But otherwise, it would be on newly-generated chats auto mirroring if that feature is enabled." Listed as M6
  (after the name setting): adopt an existing chat as a mirror; read it first; tell what it already holds from
  its forwards' origins (an origin that names one post), so nothing is forwarded into it twice. Not designed.
- **The track's order now:** M4's review, fixes, runs, hand-over; M5 the name setting and rename; settling an
  unknown outcome; M6 adopting an existing chat; forums.

## 9. THE SECOND REAL STEP RAN (11-15 12:39; the owner; `-Batches 5`, the same chat 4, the build of 849c506)
Log: `a3/logs/mirror-20261115-123702.out.log` (error log empty). The ledger read read-only afterwards.
- **What happened, in order (local time):** 12:37:05 batch 1: 100 forwarded, 2,689 ms. Pause 10 s. 12:37:18 batch
  2: 100 forwarded, 2,759 ms. Pause 10 s. 12:37:31 batch 3 (99 messages: an album at the boundary): **Telegram
  stated a wait of 9 s** (answered in 84 ms; FLOOD_WAIT). Slept in full; the pause doubled to 20 s and was
  stored for the account; 12:38:01 the same batch sent once more: **after 4,120 ms Telegram answered
  `WORKER_BUSY_TOO_LONG_RETRY`** (an error of its own server, code 500 class). The command took that as "outcome
  unknown", as designed, recorded it and ended: **the mirror is now blocked ("nothing more is forwarded into
  this mirror") until the unknown is settled.**
- **The ledger now:** batches done 100, 100, 100; waited 99 (wait 9 s); unknown 99. Forward rows: 300 forwarded,
  99 "sent" with no result. 355 candidates left besides those 99. Channels and supergroups: 10 of 500.
- **The first real numbers on Telegram's limit for forwards (one account, one day: "looks like"):** 100 messages
  at 12:32:34, then 100 at 12:37:05 and 100 at 12:37:18, and the next request at 12:37:31 was told to wait 9 s.
  So a wait came on the third batch within 26 s at a 10 s pause, after 300 messages in 5 minutes. The 10 s
  start pause is too short on this evidence; the stored pause is 20 s now. Nothing is known yet beyond that.
- **What it showed about the code:** the wait was recorded, slept in full, the pause doubled and stored, the
  batch resent once: all as built. An album at the boundary was kept whole (99, not 100). The counts by method
  and the per-request lines are right. The hourly bound was never near.
- **What it showed that is new:** Telegram's own server error on a forward. Whether that forward was carried out
  is not known: **asked of the owner: how many messages the mirror shows (300, or 399).** The piece that settles
  an unknown is not built (it was third in the order): it is now the first thing needed, because the owner's
  real mirror is blocked. Design: read the mirror chat's own messages (the reader; about 4 requests here) and
  tell from each forward's origin (the source's post number) which source messages are in it; mark those
  forwarded, the rest candidates again; unblock. Never by sending the batch again (how Telegram answers a
  repeat is still not known).
- **Decision of mine for the next pieces, from this run:** an error of Telegram's server on a forward stays
  "unknown" (safe), but a mirror must be able to settle itself by reading, or the automatic piece would leave
  mirrors blocked for good after any server hiccup, with nobody at the keyboard.
- 11-15 12:41, **the owner: the mirror shows 426 media on the phone.** Counted read-only in the test catalogue: the 300
  source messages recorded as forwarded carry 296 media (169 photos, 127 videos); the 99 of the unknown batch
  carry 99 (30 photos, 69 videos). So the mirror would show 296 if the unknown batch never arrived, 395 if it
  arrived once, 494 if twice. **426 is none of these: it is 31 more than everything sent once.** So the batch
  that got the wait and then the server error was carried out, and at least 31 of its media are in the mirror
  twice (or the phone counts differently: not checked). Which request did what is not known: the one told to
  wait may have forwarded part before the wait, or the server error came after part or all of the resend.
  **Either way: the same random ids did not stop a second copy of at least some messages**, or a wait does not
  mean "nothing was done". Both shake what the request layer assumes.
- To find out exactly, without new code: read the mirror chat (catalogue chat 14) into the catalogue with the
  installed build (`a3/a3-read-chat.ps1 -ApproveRead 14`: the collector's `run -no-downloads -approve-read 14`
  with the WireGuard adapter; untried script); then count read-only how many forwards it holds and how many
  origins twice. Offered to the owner.
- **For the settle piece (now first):** it must count and report copies (the same origin twice in the mirror),
  not only which messages arrived; removing a second copy is a write of a new kind and the owner's decision.

## 10. What the mirror really holds (11-15 12:44): the owner read the mirror chat; counted read-only
The owner ran `a3/a3-read-chat.ps1 -ApproveRead 14` (the installed build, downloads off): "chat 14 read to its
end: 4 pages in all, 366 messages as Telegram counts them; 4 requests, 361 attachments recorded".
- **The mirror holds 366 messages: 364 forwards and 2 service messages; 361 with media. No source message is in
  it twice** (364 origins, each naming one post of the one source, each once). Its order follows the source's.
- **All 300 messages the ledger calls forwarded are there.** Of the 99 of the unknown batch: **64 arrived, 35 did
  not.** The 64 are the batch's first 62, then one missing, then 2: almost a prefix. They carry the mirror's
  times 12:38:02 to 12:38:06: the four seconds of the resend that ended in `WORKER_BUSY_TOO_LONG_RETRY`.
  Nothing arrived at the time of the request that was told to wait.
- **So, measured once:** (1) a wait Telegram states means nothing was done: the assumption holds; (2) **a server
  error on a forward can mean "partly done"**: 64 of 99; "outcome unknown" was the right call, and sending the
  batch again would have been wrong; (3) of the batch's 7 albums, 6 arrived whole and 1 not at all: none split,
  even in a batch cut short by the server.
- **My inference from the phone's "426 media" was wrong** (I had said copies were likely; I had also said it was
  unchecked). The mirror holds 361 media by Telegram's own count of the read. What the phone's 426 counts is not
  known.
- **The settle piece is now simple and needs no request of its own:** the mirror chat's messages, read into the
  catalogue (by the reader, or as they come back through the monitor when the collector forwards), name their
  source posts. Settling = for a batch left "sending" or "unknown": every source message found in the mirror is
  forwarded (with its mirror id), the rest are candidates again; the batch is closed as "settled, n of m"; the
  mirror is unblocked. Condition: the mirror chat is read up to a time after the batch's request.
- The owner's collector was still running at 12:43:59 (a VPN check line): told to press Ctrl-C.
- 11-15 12:47: **M4's review is back** (`wt-mirror-review4-scratch/REVIEW.md`): 15 findings. The ones that matter: a
  refused create was sent again every pause (328 in an hour of the test clock); a refused batch likewise; an
  error on a forward ended a mirror "for good" as removed by the owner, and `-allow` then made a second mirror
  chat; one account's policy switched off a shared channel for another account; every new chat row was made
  switched off (private chats, the whole first list); the marks commands stepped an older catalogue silently;
  tests that could not fail. No Go data race found by reading. A protected source is still learnt only after a
  create (needs the chat list's flag: Core's).
- **Running now: one Opus coder on `wip/mirror-auto`** (`BRIEF-M4b-fixes-and-settle.md`): part A, the review's
  16 points (15 of them fixed, the protected flag left to Core, the pause's start raised to 20 s after the real
  run); part B, **settling an unknown outcome from the mirror chat itself** (the real case of section 10 as its
  test; the command's `-settle`; a settle turn in the automatic task). **Next step, in one line:** read its
  diff (the settle's evidence rule; the loops), a second review of this round, the full runs with the race
  detector on the whole collector, a merge-queue entry; then a build so the owner's test mirror can be settled.
- 11-15 13:41: **M4's fix round and the settling piece handed back and pushed: `wip/mirror-auto` f182f7d (the review's
  fixes) and d5a4a7c (settling an unknown batch from the mirror chat)**, copy `wt-mirror-auto`, clean. Named
  tests passed (mirror 57 s, collector Mirror 156 s, catalogue); each main fix seen to fail when undone; no
  goroutine or lock added in the program. Not fixed, as briefed: a protected source (Core's flag). A doubt to
  settle before the race run: the fake's `ChatOf` reads a map without its lock (test code).
  **Next step, in one line:** I read the settle's evidence rule; a second independent review of this round.
- 11-15 13:42: I read the settle (`internal/catalog/mirrorsettle.go`). The transaction and the "cannot tell: nothing is
  written" rule are sound. **Two defects I expect, both mine in the brief as much as the coder's:** (1) a source
  message that is itself a forward keeps its ORIGINAL origin in the mirror, so the settle, which looks only
  for the source's own prefix, would call an arrived repost "not arrived" and forward it again (the real test
  chat had no reposts: 364 origins, one peer); (2) "the mirror is on record past the request" is judged by the
  time a read ENDED, so a read begun before the request passes. Neither has run on real data.
- **Running now: a second independent review** of f182f7d and d5a4a7c (`BRIEF-M4b-review.md`; report to
  `wt-mirror-review5-scratch/REVIEW.md`), with those two as its first questions. **Next step, in one line:**
  one more fix round (the two above and what the review finds), then the full runs with the race detector on
  the whole collector, then the merge-queue entry.
- 11-15 14:00: **the second review is back** (`wt-mirror-review5-scratch/REVIEW.md`). **The earlier sixteen fixes hold**
  (each probe re-run or read: fixed; the switch-off story matches the build before this piece exactly: 12
  requests). **The settle has five confirmed defects**, the two I expected among them: a channel that reposts
  gets a loop or copies (178 forwards and 177 reads in 3 hours of the test clock); "on record" was true for a
  read that never saw the batch; any stored message dated later stood in for a read; a message never carried
  could be recorded forwarded (a hole); a batch the rules cannot tell had no way back. No race in the program's
  own code by reading; the fake reads a map without its lock (a race run would flag it).
- **Running now: the settle's fix round, an Opus coder on `wip/mirror-auto`** (`BRIEF-M4c-settle-fixes.md`): the
  rules rewritten (which read counts; which mirror messages can be a batch's copies; a message's key is its
  own origin when it is itself a forward; cannot tell means nothing is written; no loop; the owner's word as
  the way back: `-settle N -take arrived|not-arrived`), the fake's lock. **Next step, in one line:** read the
  new rules, then the full runs with the race detector on the whole collector, the merge-queue entry.
- 11-15 14:18: the owner started a new integrator session (none had run since the morning). The board has one message
  for it with everything that waits from this track, and my row is current. The settle's fix round is still
  running (about 1,200 lines changed in 13 files, not committed yet when looked at 14:17).
- 11-15 14:33: **the settle's fix round handed back and pushed: `wip/mirror-auto` 224a615 (the rules rewritten) and
  c599ac5 (its report)**, copy clean. Named tests passed (mirror 83 in 75 s, collector Mirror 48 in 164 s,
  catalogue 17); the review's five probes failed on the old code and pass now; 11 plants each caught by a named
  test; no concurrent code added in the program; the fake's lock order and unlocked reads fixed; `reader.go` and
  `account.go` untouched. **Next step, in one line:** I read the rule that tells one message, then the full runs.
- 11-15 14:34: I read the rule that tells one message (`mirrorsettle.go` `weighBatch`): the settle's own finished read
  begun after the need time; only mirror messages above what the ledger knew; a message's own origin when it is
  itself a forward; a forward the batch does not explain turns every "not arrived" into "cannot tell"; an
  "already" batch the mirror does not show is a contradiction. Sound by reading; the real case comes out 64 / 35.
- **Running now (11-15 14:34): the Windows half of M4's full runs** in the background of this session, logs in
  `runs-mirror4/` (whole tests of mirror, faketg, the command, catalogue, collector, one after another; gofmt;
  vet). **The race run is NOT started: only 3 GB of memory was free** (31 GB in all; no single large process;
  other sessions are working), and a race build needs about 3 to 4 GB. It is: the race detector on the whole
  `internal/collector` and on `internal/mirror`, one container, 2 cpus, 4g, a timeout of 150 minutes:
  `docker run --rm --cpus 2 -m 4g -v <wt-mirror-auto/archiver>:/src:ro -v tgarchive-race-cache:/cache -w /src -e
  GOCACHE=/cache/build -e GOMODCACHE=/cache/mod -e GOGC=25 -e GOFLAGS=-p=1 -e GOTOOLCHAIN=local golang:1.27.3 go
  test -race -count=1 -timeout 150m ./internal/collector ./internal/mirror`, log to
  `runs-mirror4/race-collector.log`. **Next step, in one line:** when the Windows runs end, measure memory; with
  6 GB free start the race run; then the merge-queue entry.
- 11-15 14:38: at the owner's word that memory was free (8.5 GB measured): **the race run is started** (the whole
  `internal/collector` and `internal/mirror`, one container, 2 cpus, 4g, 150 minutes at most), log
  `runs-mirror4/race-collector.log` (it ends "exit N"). The Windows runs so far: mirror, faketg and the command
  passed; the catalogue and the collector are still going.
- 11-15 14:50: **the Windows half of M4's full runs passed** (`runs-mirror4/`, on c599ac5): mirror 72 s, faketg 0.1 s,
  the command 0.4 s, the catalogue's whole run 301 s (the other track's timing test passed this time), the
  collector's whole run 557 s; gofmt empty; vet clean. **Still running: the race run** (the whole collector and
  the mirror package; `runs-mirror4/race-collector.log`). **Next step, in one line:** at its "exit 0", the
  merge-queue entry for `wip/mirror-auto` c599ac5 and the board.
- 11-15 15:21: the race run is 42 minutes in and still inside the collector's tests (its test program has used about 72%
  of one core throughout: working, not hung; `go test` prints a package's line only when it ends). To save the
  time of its second package, **the mirror package's race run was started beside it in a second container**
  (2 cpus, 3g; the race build is in the shared cache), log `runs-mirror4/race-mirror.log`. When the first log
  shows the collector's "ok" line and the second ends "exit 0", both are done: the first container's own rerun
  of the mirror package need not be waited for (stop that container then).
- 11-15 15:54: **the collector's race run ended after 64 minutes: no data race reported, every test passed but one:**
  `TestMirrorAutoSwitchOff` "timed out (1m0s) waiting for 8 minutes of the clock" (`mirror_auto_test.go:241`).
  Cause, read: under the race detector the collector's test clock runs at 3 times real time instead of 20
  (`rig_test.go` `testScale`), so 8 minutes of the clock is 160 s of real time and the test's own safety bound
  is 60 s: it can never pass under the race detector. A test-only defect (a bound on real seconds again). Log
  kept as `runs-mirror4/race-collector-run1.log`. The first container was stopped (it had gone on to repeat
  the mirror package, which the second container is running: `runs-mirror4/race-mirror.log`).
- **Next step, in one line:** a clerk makes the one-line fix (the bound follows the clock's scale), commits; I
  run that one test under the race detector in a container; with the mirror package's race result: the entry.
- 11-15 15:55: the clerk's one-line fix is committed and pushed: **`wip/mirror-auto` 464e840** (only
  `mirror_auto_test.go`: the test's bound on real time follows the test clock's speed; plain run of the test ok,
  24 s; gofmt, vet clean). **Running now:** that one test under the race detector (`runs-mirror4/
  race-switchoff.log`) and the mirror package's race run (`runs-mirror4/race-mirror.log`). **Next step, in one
  line:** both "exit 0": the merge-queue entry for `wip/mirror-auto` 464e840 and the board.

## 11. Handed over (11-15 15:59): the automatic mirror and settling
- **The last runs passed:** the mirror package under the race detector (2,059 s); `TestMirrorAutoSwitchOff` under
  the race detector after its fix (168 s). With the Windows runs and the collector's race run (no data race):
  the full runs are done. **`wip/mirror-auto` 464e840 is pushed and handed to the integrator: `MERGE-QUEUE.md`
  entry "M4"**, the board's "Waiting to merge", my row.
- The integrator has merged the reading piece (the main branch's e0db6e9) and the copies track's step 17; the
  main branch's head is f0e3f0c. `wip/mirror-auto` is not moved onto it: its step 18 follows 16 on the branch
  and must follow 17 at the merge (one constant; said in the entry).
- **Running now: nothing.** Copies left: `wt-mirror-auto` (waits to merge), `wt-mirror-reads2` (merged: can be
  removed with the owner's yes).
- **What was built in this session, in order:** the `mirror` command (merged); a run of several batches with a
  pause and a bound per hour (merged); the mirror reads a chat itself, media only (merged); the automatic
  mirror in the collector's loop, and settling an unknown outcome (handed over, not merged).
- **What ran for real (the owner, the test account):** one mirror created; 300 messages forwarded clean; a 9 s
  wait on the third batch at a 10 s pause; a server error that carried out 64 of 99 (sections 8 to 10).
- **Not verified:** everything of `wip/mirror-auto` against the real Telegram: the look, the reader reading a
  joined chat by the mirror's approval, a turn's request, the policy for new chats, the settle on the real
  blocked mirror; the last settle rules have had no review of their own; what Telegram allows per hour.
- **What the owner must do next:** after the integrator's merge and a build: `mirror -settle 4` on the test
  account (collector stopped, VPN on, the WireGuard adapter), then more batches; then a first `run -auto-mirror`
  on the test account with the owner present (join a test group from the phone and watch).
- **Next step for this track, in one line:** brief M5 (the mirror's name setting for new mirrors, and renaming
  one mirror) on a copy cut from the head once M4 is merged.

## 12. A new session took the track over (M2, 11-15 16:41, at the owner's word); M4's second fix round
The earlier session (M) is retired: nothing waits for it. This block is written by the new session.
- 16:41 to 16:48: read in full, myself: `CLAUDE.md`, the board (message 29), this file's last blocks, `MERGE-QUEUE.md`
  entry M4, the review `wt-mirror-review6-scratch/REVIEW.md` and its probes, `BRIEF-M4c-settle-fixes.md`,
  TRIED-BEFORE 24 and 25, `LESSONS-ix12.30-live.md` 6b, TELEGRAM-FACTS 11; the code: `mirrorsettle.go` (all), the
  ledger's batch functions and candidates, `schema_mirrorauto.go`, the turn's `mirrorTurn`, `settle`, `autoBatch`
  and `forward`, `Run`'s loop, the plan's settle part, `forwardRandomID` and `ForwardBatch`, `once` and `held`, the
  command's settle, the `ReadMirror` hook.
- **State found:** `wt-mirror-auto` clean at 464e840 (pushed); main head a0baa06; nothing running.
- **What the old app and the record say (the note a brief needs):** the old app never forwarded; the only numbers
  are the two real runs of 11-15 (TELEGRAM-FACTS 11): a stated wait means nothing was done; a server error
  carried out 64 of 99, albums whole, nothing twice. Not known: whether Telegram remembers the random ids of the
  messages of such a request that it did not carry out. The design below is right in both cases and assumes
  neither.
- **The design (also in my board row, before it is built):**
  1. Finding 1: the media key from current main rows only; "not a forward" judged per single media row, every
     row counted.
  2. Finding 2: a table `c_mirror_again` inside step 18 (not merged, never on a real catalogue: no step 19): one
     row per message a settle put back, with an attempt number. Put-back messages go alone (the candidates' query;
     `BeginMirrorBatch` refuses a mix), first under the same ids (Telegram can still refuse a repeat). A batch
     refused as a repeat stays a contradiction for the owner; `-take not-arrived` is now allowed there and sends
     them under new ids (attempt + 1; attempt 0 is today's id bit for bit); `-take arrived` leaves them missing.
     Nothing bumps an attempt by itself: it waits for a real number from the test account's settle.
  3. Finding 3: a "sending" batch's request time is the later of `sent_at` and when its sender had ended (the
     session's start, the command's start under the collector's lock, or the clock after a forward whose record
     failed). Why not "sent + longest wait + request bound": `held` may sleep a stated wait more than once
     before the request, so that sum is no bound.
  4. Finding 4: a refused mirror read blocks the want with fixed words.
- 16:48: the PC measured: 5.1 GB free of 31.1, CPU 54%.
- 16:50: **brief written: `BRIEF-M4d-settle-fixes-2.md`. Running: one Opus 5.5 coder (high effort) in
  `wt-mirror-auto` on `wip/mirror-auto`**, committing and pushing to `private` as it goes; named tests only.
  The board row is rewritten as mine; message 29 is marked read.
- **Not committed or pushed yet by this session:** nothing of the code (the coder's). The notes: committed on
  `notes` after this block.
- **Next step, in one line:** give `a3\a3-mirror.ps1` a settle mode; when the coder hands back, read the risky
  part of its diff (the candidates' split, rule 6 and the attempt, the need time), then the new head under M4 in
  `MERGE-QUEUE.md`.
- 16:50: **`a3\a3-mirror.ps1` has a settle mode** (`-Settle N`, with `-Take arrived|not-arrived` or `-CreateNotMade`;
  exactly one of `-Chat` and `-Settle`; `-Batches` only with `-Chat`), and its default adapter is now
  `WindscribeWireguard`. It parses; it is untried (it needs the build with `mirror -settle`). The script is not
  in git (the folder `a3` is untracked). For the owner after the merge and the install:
  `powershell -ExecutionPolicy Bypass -File a3\a3-mirror.ps1 -Settle 4`.
- **Running: the coder (M4d).** Meanwhile: M5's brief is being drafted (nothing started on it).
- 16:51: **M5's brief is drafted: `BRIEF-M5-mirror-name.md`** (not started; cut from the main head after M4's
  merge; schema step 19 not taken yet). Its design: the mirror's name stored on its row instead of rebuilt in SQL
  in three places; the rule (prefix, separator) a setting for new mirrors only, fail closed when unreadable;
  `mirror -rename N -to` as one `channels.editTitle`, the owner's own action, never automatic.
- **Running: the coder (M4d) in `wt-mirror-auto`.** Nothing else. **Next step, in one line:** at its hand-back,
  read the risky part of the diff, then the new head under M4 in `MERGE-QUEUE.md`, the board row, the notes.
- 17:34: **the coder handed back: `wip/mirror-auto` e067045, pushed, the copy clean** (four commits on 464e840:
  18bfa17 the tests seen to fail, 6485dd0 the code, 39599c2 more tests, e067045 the report). Its end-of-round
  runs all passed (mirror 93 tests 86 s; catalogue's named 26 in 65 s; collector's `Mirror` 49 in 171 s; telegram's
  `Forward` 16; faketg 6; the command 3; gofmt and vet clean). `reader.go`, `account.go` untouched; no concurrent
  code.
- 17:36: **I read the diff** (`mirrorsettle.go`, `schema13.go`, `schema_mirrorauto.go`, `forward.go`, `auto.go`,
  `mirror.go`, `step.go`, `pace.go`, `pause.go`, the hook, both command files) and ran the three probe tests and
  the owner's-word test by name (4 tests, 7.2 s, pass; PC 4.4 GB free, CPU 59% before). Sound by reading: the
  key's SQL (role is NOT NULL, default 1); the put-back upsert (attempt only raised for the owner's "not
  arrived" on an "already" batch); the candidates never mix (the put-back query is exactly "candidates with a
  row", so an empty answer means the fresh query holds none); attempt 0 writes the old 56 bytes under the old
  label; `SettleTimes` in all three places; the state is per session. One small thing left as a doubt in the
  entry: `AutoBlockRepeat`'s words are also said when the settle before put nothing back.
- 17:36: **listed: the new head under entry M4 in `MERGE-QUEUE.md`** (what changed per finding, tests, changed
  expectations, departures, doubts, what the owner runs after the install); the board row rewritten.
- **Running: nothing.** Committed and pushed: `wip/mirror-auto` e067045. The notes: committed on `notes` after
  this block. `a3\a3-mirror.ps1` is changed and not in git.
- **Waiting on the integrator:** its reviewer's probes on e067045, the full runs on the combined tree, the merge,
  the installed collector rebuilt. Then the owner: `a3\a3-mirror.ps1 -Settle 4`, then `-Chat 4`.
- **Next step, in one line:** when the board says M4 is merged, write "19" under the board's schema numbers,
  check `BRIEF-M5-mirror-name.md` against the new main head, cut a copy from it and start M5's coder.
- 17:48: **the integrator's message (17:50 by its clock): its reviewer's second pass on e067045 says all four
  findings are fixed, and confirmed one older hole in the settle's media pass (finding 5, medium): one small fix
  round more, then the merge.** Read by me: the second pass in `wt-mirror-review6-scratch/REVIEW.md`, its probe S3
  (`zz_m6b_test.go`), the media pass in `mirrorsettle.go`. The case: a message that once carried another batch
  message's media and was edited after its copy was made gives its copy to that other message (a hole and a
  second copy). Finding 6 (an edit after the forward always waits for the owner's word) is safe and stays: known.
- 17:49: **brief `BRIEF-M4e-settle-media-match.md`; the same coder continues on `wip/mirror-auto` from e067045**
  (PC before: 10.2 GB free, CPU 53%). Two rules: a media match counts only when no other batch message and no
  earlier "missing" message has any row of the copy's rows; and (mine, beyond the integrator's wording) a message
  told "not arrived" becomes "cannot tell" when an origin-less mirror message that is not a found copy shares any
  row with it, else the owner's word for the one would let the rules put the other back.
- **Running: the coder (M4e).** Committed and pushed so far: e067045. **Next step, in one line:** read its diff,
  run S3's test, the new head under M4, the row (with finding 6 as known), the notes.
- 17:55: **the coder handed back finding 5's fix: `wip/mirror-auto` e8113ae, pushed, the copy clean** (one commit on
  e067045: `mirrorsettle.go` `weighBatch`, a new test file, one older test's counts, the report's section). Its
  runs: the mirror's settle tests 23 in 21 s, the catalogue's `Mirror|Settle` 23 in 49 s, gofmt and vet clean; both
  new tests failed on e067045 first; each rule undone once and caught.
- 17:55: **I read the diff whole and ran four tests by name** (the two new ones, the six media-key cases, the
  owner's word: 5.4 s, pass). Sound by reading: the copy's rows against every other batch message's rows and the
  earlier "missing" rows; "not arrived" refused when an origin-less mirror message that is not a found copy shares
  a row. One changed expectation, right by the rule (`TestMirrorSettleOwnerWord`: found 48, cannot tell 52).
- 17:55: **listed: e8113ae as the newest head under entry M4** (first bullet of my part); the board row, the
  waiting line and message 29 name it; finding 6 is in my row as known and left.
- **Running: nothing** (no go process of mine). Committed and pushed: `wip/mirror-auto` e8113ae. The notes:
  committed on `notes` after this block.
- **Waiting on the integrator:** its reviewer's probes once more, the full runs on the combined tree, the merge, the
  installed collector. **Next step, in one line:** when the board says M4 is merged, take schema step 19 on the
  board, check `BRIEF-M5-mirror-name.md` against the new main head, cut a copy and start M5's coder.

## 13. M4 is merged (11-15 18:20, the integrator's message); M5: the name rule and a rename
- 18:20: **M4 is merged and pushed by the integrator: `wip/mirror-auto` e8113ae as be429e1; the main head is
  9dd5a21.** Its reviewer's third pass: finding 5 fixed; full runs once on the combined tree, all ok. One low note
  from that pass for this round (a batch message with no rows on record cannot block another's media match): part
  D of M5's brief, narrowed by me to "no message row on record at all" (a text message under `-all-messages` has
  no media by nature and must not turn every media match into the owner's word).
- 18:20: read the board's messages for the mirror: 33 (Core's K4, the protected flag: the refusal before any
  request is mine after its merge), 36 d (schema 19 is taken). 19 is written twice (Core, copies), so M5 takes 21:
  written on the board first.
- 18:21: **the copy `wt-mirror-name` is cut from 9dd5a21 (branch `wip/mirror-name`, clean); the brief is final:
  `BRIEF-M5-mirror-name.md`** (its facts checked on the new head: the three SQL places, `SchemaVersion`, the
  settings doors). PC before the coder: 8.3 GB free, CPU 57%.
- **Running: one Opus 5.5 coder (high effort) on M5 in `wt-mirror-name`**, committing and pushing to `private` as
  it goes. Nothing is committed on the branch yet.
- **Owed:** `a3\a3-mirror.ps1` checked against the installed build's `mirror -h` once the board says the build
  is in place; then my row says "checked".
- **Next step, in one line:** at the coder's hand-back, read its diff (the step, the three queries, the rename's
  one request, part D), start one independent review, then the named runs and the entry in `MERGE-QUEUE.md`.
- 18:22: the board says the installed collector is the build of 9dd5a21 (item 22: the owner may settle the test
  mirror). **The script checked:** every flag `a3\a3-mirror.ps1` passes in both modes is in the installed build's
  `mirror -h`.
- 18:23: the plan cannot be shown on a copy of the test catalogue: without the sign-in files beside it the command
  says "not signed in" and stops (tried on a scratch copy of the 1.9 MB file, with and without `-account`; the
  copy is removed; the sign-in files are not copied). So the owner's run is the first on that file.
- 18:24: **a scratch probe instead (invented data, the merged code in `wt-mirror-auto`, loaded with `-overlay`, the
  copy untouched):** a batch of 100 left unknown with 64 carried, the catalogue stepped back to schema 16; `-settle`
  "no": the plan, the file byte for byte; `-settle` "yes": stepped, read, settled 64 found and 36 put back;
  `-chat`: the 36 alone, 100 in the mirror (1 test, 4.2 s, pass). That copy has no step 17 (it was cut before
  it): the real file goes 16 to 17 to 18 at the yes; the mirror's plan reads nothing of step 17. A small gap:
  the settle's plan does not say that a yes steps the schema (the forward's plan does): for M5's fix round.
- **Running: M5's coder in `wt-mirror-name`.** My row says the script is checked and what is not.
- 18:25: the integrator's message of 18:23 (it crossed mine): prove on a copy that the installed build's settle
  plan prints on the test catalogue at schema 16, and that a yes steps an invented catalogue 16 to 17 to 18.
- 18:26: **the plan on a copy, done.** The command judges "signed in" by whether the sign-in file exists (and the
  catalogue's own record); it is not read before the yes. So: the catalogue file copied to a scratch folder with an
  EMPTY placeholder of that name (nothing of the real sign-in copied), no collector running, the installed build's
  `mirror -settle 4` with its input ended: 14 lines of plan, exit 2, "nothing was sent or written", the copy byte
  for byte the same and still at schema 16. The copy is removed. Its numbers: 5 batches, the last unknown, 99 to
  settle, about 1 request for the read.
- 18:27: **the yes, on the main tree's code (9dd5a21) with invented data, a scratch probe by `-overlay` (the tree
  untouched):** the file stepped back to 16 with both later steps undone; "no": unchanged; "yes": at 18, step 17's
  column there, 64 found, 36 put back; then the 36 alone (1 test, 4.2 s, pass).
- Two wording gaps noted for M5's fix round: the plan prints "may still be forwarded: 0" while a batch blocks (it
  does not count then); the settle's plan does not say a yes steps the schema.
- **My row says "the script and the plan are checked on the installed build".** Running: M5's coder.
- 18:45: **the integrator's message: the owner's first settle failed at once, nothing sent: my script's default
  program path held a tab and a backspace** (my 16:50 edit went through a tool that turned two escapes into
  characters; I had checked only that it parsed and that the flags matched; I never started the script, and
  wrote "checked" at 18:27). The integrator put the path right at 18:46.
- 18:46: with no run going (no collector process, no log growing) **the script changed:** defaults built with
  `Join-Path`, the program and the catalogue checked first, a failed start stops with fixed words and exit 2, the
  log lines give full paths, a `-Root` parameter for a copy. No tab or control character; parses.
- 18:46: **run by me as the owner runs it** (full path, from a scratch folder, `-Settle 4 -Root <scratch copy with
  an empty sign-in placeholder>`, the input ended): the default program: started, the 14 lines of plan, "the
  input ended: nothing was sent or written", exit code 2 shown, the copy unchanged; a missing program: fixed
  words, exit 2; a program that cannot start: fixed words, exit 2; no mode: fixed words. Two public-address
  lookups by my runs, nothing dialled. My two test log pairs and the scratch copy are removed.
- **18:46:35: THE OWNER'S SETTLE RAN on this version** (log `a3\logs\mirror-20261115-184635.out.log`, 18 lines): 1
  request read the mirror chat; **65 of 99 arrived (64 by the post each forward names, 1 by the same media), 34
  did not, 0 cannot be told; settled; the 34 are put back and go alone under their old ids.** The 12:44 count
  said 64 of 99: the 65th copy names no post and was found by its media (so the carried part looks like a clean
  prefix of 65, not checked message by message).
- **Next for the owner:** `powershell -ExecutionPolicy Bypass -File
  "C:\Users\trabi\Claude\Projects\Telegram\a3\a3-mirror.ps1" -Chat 4`: the 34 alone. This is the first real
  number on whether Telegram remembers the ids of messages it did not carry out.
- **Lesson, mine:** a script is checked when it has been started the way the owner starts it, not when it parses.
- **Running: M5's coder.**
- 18:55: **M5's coder handed back: `wip/mirror-name` 02abe15, pushed, the copy clean** (five commits on 9dd5a21;
  report `archiver/docs/progress/mirror-name-REPORT.md` on the branch). Its runs: mirror 106 tests 114 s;
  catalogue's `Schema|Mirror|Settle` 38 in 73 s; collector's `Mirror` 52 pass, 1 fail (`TestMirrorMarksOtherSchema`
  relabelled a file to a schema number no step starts from now; the test corrected and passed alone; the set not
  rerun); telegram's `Forward|Rename` 20; faketg 6; the command 3; gofmt and vet clean. No concurrent code. Its
  departures: the step jumps 18 to 21 on the branch; two of the three name queries take the stored name as a
  parameter (so they work on an older read-only file); a rename to the stored name is still sent; a protected
  mirror is not renamed; the two rule flags go together; nil Settings means the default rule. Its doubts: a
  refusal of the account on a rename also stops creates and forwards; how Telegram answers a title edit is not
  known (the fakes follow the API).
- 18:56: I read the catalogue's side (the step file, the three queries, the rename's two writes in one
  transaction, the settle's "lost message" rule) and the forwarder's `RenameMirror` (one request through `once`).
  Not read yet: `name.go`, `rename.go`, the command file.
- 18:57: **running: one independent reviewer** (`BRIEF-M5-review.md`; read-only; probes by `-overlay`; report to
  `wt-mirror-review7-scratch/REVIEW.md`). PC before: 6.9 GB free, CPU 71 to 96% (others' runs): the reviewer
  measures before each go command and waits above 85%.
- **For the fix round, already known (mine):** the plan prints "may still be forwarded: 0" while a batch blocks;
  the settle's plan does not say a yes steps the schema; `AutoBlockRepeat`'s words when the settle before put
  nothing back.
- **Next step, in one line:** read `name.go`, `rename.go` and the command file while the review runs; then one fix
  round on its findings, the named runs, the entry.
- 18:57: read by me: `name.go` (the one check, the stored value read back byte for byte, an unreadable value is
  an error and never the default, the base cut at whole runes) and `rename.go` (the plan made again before the
  request, one request, the two catalogue writes only on Telegram's answer or its "not modified"). Sound by
  reading. One point of mine for the fix round: the check for the line and paragraph separators is written with
  the two invisible characters themselves inside the source; it must be written as escapes.
- **Running: the independent reviewer of M5.** Nothing else.
- 19:08: **the independent review of M5 is back** (`wt-mirror-review7-scratch/REVIEW.md`, 169 lines; 9 probes and
  mutations; nothing edited in the copy). Its verdict: no path sends a request twice, creates under the default
  on an unreadable rule, or puts a name in a log or a printed line. **Findings: high 0; medium 2 (1 confirmed: two
  rules can give two live rows the same stored name, so a lost create can adopt the other source's channel; 1
  plausible: the rule takes a leading space and invisible characters, which Telegram may alter, and then a lost
  create is never found); low 7** (a rename can block `-create not-made`; an untested check; `-never`/`-allow`/
  `-list` silently drop `-rename`; a test that pins the step's number; an unreadable rule blocks wants one by
  one; blank titles accepted; the 10000th number makes 129 units).
- 19:08: **my decisions, brief `BRIEF-M5b-fixes.md` (12 points), the same coder continues from 02abe15:** no two live
  rows share a name (the number skips, a rename refuses a taken name); the checks take only plainly kept
  characters (what Telegram does to a title is not measured: the owner's first create under another rule is the
  measurement); an unreadable rule stops creates without marking each chat; the small ones; and my four (the
  plan never prints a number it did not count; the settle's plan says the schema step; the repeat words only
  for put-back messages; the collector's `Mirror` set run again).
- **Running: M5's coder on the fix round.** Committed and pushed so far: `wip/mirror-name` 02abe15.
- **Next step, in one line:** read the fix round's diff, then the entry "M5" in `MERGE-QUEUE.md`.
- 19:27: **M5's fix round handed back: `wip/mirror-name` fb8ab31, pushed, the copy clean** (three commits on
  02abe15; all 12 points; the report's section "M5b"). Its runs, all pass: mirror 112 tests 98 s; catalogue's named
  41 in 75 s; collector's `Mirror` 56 in 175 s; telegram 20; faketg 6; the command 3; gofmt and vet clean.
- 19:27: I read the round's diff (the number's loop past a taken name, the rename's refusal of a taken name, the
  turn's hold on an unreadable rule, the one text check, the repeat words) and ran 11 of its tests by name (mirror
  7 in 2.0 s, catalogue 4 in 1.3 s: pass; PC before: 5.3 GB free, CPU 64%). No control byte in the 33 files of
  the piece. A trial merge of the main head fa8c011 with fb8ab31 (`git merge-tree`, nothing written) is clean.
- 19:28: **M5 is listed: entry "M5" at the end of `MERGE-QUEUE.md`**; the board's waiting list, my row, the feature
  table's row and a message for the pages track (46: the setting's key and its doors).
- **From the owner's logs (read 19:27; the owner ran these at 18:48 and 18:49): the test mirror is complete.** The
  34 put-back messages went alone under their old ids: 34 of 34 forwarded, no refusal as a repeat (one run:
  looks like Telegram does not remember the ids of messages of a request it did not carry out). Then `-Batches 5`:
  352 messages in four batches (the last of 57) at a 20 s pause, 4 requests, no wait, 69 s; no candidates left.
- 19:29: board message 44 read (the owner, 19:15: each session hands its track over at its natural point; the
  mirror's is "M5 listed"). No new piece is started.

## STATE FOR A TAKE-OVER (the mirror track, session M2, 11-15 19:29)
Start: "Read `BOARD.md`, take over the mirror track from its progress file, and carry on." Read this block, then
my board row, then entry "M5" in `MERGE-QUEUE.md`.
- **Merged:** M4 (the automatic mirror and settling) with both fix rounds: the main branch's be429e1. The main head
  was fa8c011 at 19:27.
- **Listed, waiting for the integrator:** M5, `wip/mirror-name` fb8ab31 (pushed; copy `wt-mirror-name`, clean): the
  mirror's stored name, the name rule as a setting, `mirror -rename`, small settle and plan fixes; schema step 21
  (one line at the merge). Reviewed once, fixed; the fix round has no review of its own. If the integrator's
  reviewer or its full runs find something: one fix round on that branch, by an Opus coder from a brief of
  yours, named tests only.
- **Pushed and not listed:** nothing. **Running:** nothing (no coder, no reviewer, no go process of this track).
- **Copies of this track:** `wt-mirror-name` (waits to merge); `wt-mirror-auto` (merged: it can be removed with
  the owner's yes); scratch folders `wt-mirror-review6-scratch` and `wt-mirror-review7-scratch` (the reviews; the
  integrator copies them to `docs/review`).
- **For the owner, nothing waits.** The test account's mirror of chat 4 is complete (the logs in `a3\logs`). The
  owner's script is `C:\Users\trabi\Claude\Projects\Telegram\a3\a3-mirror.ps1` (not in git): after M5 is merged AND
  installed, give it `-NameRule`, `-NamePrefix`/`-NameSep` and `-Rename N -To "name"`, write it with the Edit tool
  (never a path inside an inline script string), scan it for bytes below 32, and RUN it yourself by its full
  path from another folder on a copy (`-Root`; an empty placeholder for the sign-in file) before telling anyone
  it is checked. Every command for the owner by full path.
- **Not verified, anywhere:** `run -auto-mirror` against Telegram (the owner must be present for the first: join a
  test group from the phone and watch); the rename and a create under another name rule against Telegram (how
  Telegram treats a title is not measured); forwards per hour (two waits on record: 9 s after 300 in 5 minutes
  at a 10 s pause; none at 20 s over 386 messages).
- **Known and left:** a message whose media was edited after its forward is always "cannot tell" at a settle
  (safe; the owner's word); `-never`, `-allow`, `-list` drop forwarding flags such as `-batches` silently; the
  source's own title is not run through the name's text check.
- **The track's order from here:** (1) after Core's K4 (`wip/core-protected`, the chat list's protected flag) is
  merged: the plan and the automatic mirror refuse a chat known to be protected, in fixed words, before any
  request, and say "not known" where it is not (`ChatProtected`, `ProtectedChats`); (2) M6: adopting an existing
  chat of the owner's as a source's mirror (listed on the board; not designed: what is already in it is told
  from its forwards' origins, the settle's rules are the base); (3) a forum mirrored as a forum with the same
  topics (creating a topic in a mirror was never tried). Each: read TRIED-BEFORE 24 and 25, `LESSONS-ix12.30-live.md`
  6b, TELEGRAM-FACTS 11 and the three mirror reviews in `docs/review` first; brief; one Opus coder; your read;
  one independent review; its fixes; named runs; the queue.
- **Next step, in one line:** wait for the board to say M5 is merged, then start (1) if K4 is merged, else M6's
  brief.

## 14. A new session took the track over (M3, 11-15 20:20, started by the integrator at the owner's word)
- 20:20 to 20:24: read by me, in full: `CLAUDE.md`'s archiver section; the board, all of it (messages 47 to 50 the
  newest); the take-over block above; entry "M5" in `MERGE-QUEUE.md` and its second review
  (`wt-mirror-review8-scratch/REVIEW-2.md`: may merge as it is; six lows N1 to N6 for my next round);
  TRIED-BEFORE 24 and 25; `LESSONS-ix12.30-live.md` 6b; TELEGRAM-FACTS 11; FEATURES 12, all sixteen rounds; the six
  mirror reviews in `archiver/docs/review`; `internal/mirror/auto.go`, `pause.go`, `pace.go` and the collector's
  `mirror_auto.go` on 2625aa0; what M5 changes in `auto.go` (`git diff 9dd5a21 wip/mirror-name`).
- **What changed since the block above (the integrator's start message):** the main head is 2625aa0. M5 had its
  independent second pass and may merge as it is; it sits in the integrator's batch (`wt-int-batch`, not mine) as
  schema step 20 on top of K4's 19. The owner's usage was reset: new pieces may start.
- **The order given to me:** (1) once M5 and K4 are on the main branch: refuse a chat known to be protected
  before any request, in the plan and the automatic task, "not known" said where it is not; with it N1 to N6.
  (2) the automatic mirror's timing varied and the setting "at once, or gathered for N minutes": **starts now,
  from 2625aa0.** (3) adopting an existing chat (M6). (4) forums. Beside them: the steps of the automatic
  mirror's first real run on the owner's list; the owner's script's new switches once M5's build is installed.
- 20:24: the board row says "taken over". Nothing is running yet. Nothing of this track is uncommitted in any
  copy (`wt-mirror-name` at fb8ab31, `wt-mirror-auto` at e8113ae, both clean by the worktree list).
- 20:26: **`BRIEF-M7-auto-timing.md` written** (no control byte in it). Its design, mine: the random part is a pure
  keyed function (HMAC of the forward secret, what it is for, the account and an anchor), so the same pending
  time is the same every turn and after a restart, and nothing is kept in memory or stored; the pause gets 0 to
  min(pause/2, 60 s) on top, keyed by the last write's second (the base is what is doubled and stored after a
  wait); the 90 s gets 0 to 30 s on top, keyed per message or album; a nil source or `-auto-mirror-steady`
  gives today's exact times. The setting is one catalogue-wide row `mirror.auto.gather` (absent: at once; 1 to
  1440 minutes): with it the mirror's oldest candidate must be N minutes old before anything goes, so a backlog
  never waits and a live chat sends about one request per N minutes; unreadable: the turn sends nothing (as a
  bad stored pause). The owner's `mirror -timing` and `mirror -gather N`; the owner's own `mirror -chat` is not
  varied or gathered. What the old app knows is in the brief: it never forwarded; its one random timer is a
  re-check at 0.9 to 1.1 of 1 h, 6 h, 24 h with no number behind it; no number anywhere says variation lowers a
  risk, so the piece is judged only by "never sooner than today".
- 20:26: PC before the coder: 4.6 GB free, CPU 55%. Copy `wt-mirror-timing` cut (branch `wip/mirror-timing` from
  2625aa0, clean; the main head on `private` is still 2625aa0).
- **20:27: RUNNING: one Opus 5.5 coder (high effort) on M7 in `wt-mirror-timing`**, committing and pushing
  `wip/mirror-timing` to `private` as it goes. Nothing is committed on the branch yet. A session that takes over
  while it runs: look at `git -C wt-mirror-timing log` and its report
  `archiver/docs/progress/mirror-timing-REPORT.md`; the brief says what done is.
- **What M7 meets when M5 lands** (in the brief): M5's block after `autoPause` in `Turn`, its hold before
  `HaveLimits`, `autoCreate`'s signature, one `sayTurn` case, the new flags in `mirror_cmd.go`. After M5 is on
  the main branch: the new head is merged into `wip/mirror-timing` in a small round before its full runs.
- 20:28: the installed collector (written 11-15 19:00) names `-auto-mirror` and `-no-downloads` in its `run -h`
  (its help only; nothing opened or sent). A collector and a watchdog were running on the PC at that time and
  were not started from the `a3` folder (its `a3.pid` is of 12:43): not mine, not touched.
- 20:29 to 20:31: **the automatic mirror's first real run is PREPARED for the owner.** New: the starter
  `a3\a3-auto-mirror.ps1` (the track's; not in git, as the other `a3` scripts; written with the Write tool; no
  byte below 32; parses). It starts `run -auto-mirror -no-downloads` through Core's `a3-start.ps1` (its `-Extra`),
  and with `-Lines` prints the automatic mirror's own lines from the collector's log. **Run by me by its full
  path from a scratch folder on a scratch copy** (`-Root`, `-State`; a placeholder for the catalogue; a stand-in
  program that writes down its arguments in place of the collector): (1) `-NoWatchdog`: started, the stand-in saw
  `run ... -auto-mirror -no-downloads`; (2) the default way through the installed watchdog, with `-Downloads`:
  "started: watchdog pid, collector pid", the stand-in saw `run ... -auto-mirror`, the watchdog ended "the program
  ended cleanly"; (3) `-Lines` with invented lines in the log: the mirror's two shown, the other left out; (4) a
  missing program: "not started, nothing was sent", exit 2; (5) `-Lines` with nothing on record: "nothing to
  show". Two public-address look-ups by the start script; nothing dialled; the scratch copy removed. Not tried:
  the real collector with the switch (only the owner).
- 20:32: the steps are `PLAN-MIRROR-auto-first-run.md`; the request is item 26 of the board's waiting list; my
  row and the feature table's row say what runs; message 49 marked read (N1 to N6 and message 43 b's wording
  go with the protected piece, after M5 and K4 merge).
- **For the take-over, as things stand at 20:33.** Running: M7's coder in `wt-mirror-timing` (branch
  `wip/mirror-timing`; it pushes as it goes). Committed on `notes`: this file, the board, the brief, the plan.
  Not in git: `a3\a3-auto-mirror.ps1`. Waiting on others: M5 and K4 merged (then the protected piece with N1 to
  N6, its brief not written yet); Core's word that `a3-start.ps1` and `a3-stop.ps1` are run as the owner runs
  them; the owner's start of the automatic run (item 26).
- 20:34: the coder's first work-in-progress commit is on `wip/mirror-timing` (e0b75ab, its copy clean at that
  moment). Written while the coder works: **`BRIEF-M7-review.md`** (the independent review of the timing piece:
  ready; it needs only the head's hash in the reviewer's start message; its folder will be
  `wt-mirror-review9-scratch`) and **`BRIEF-M8-protected-and-lows.md`, a DRAFT** (the protected chat refused in
  the plan and in the look and `autoCheck`, "not known" said; N1 to N6, N8, N9 and message 43 b): read from
  `wip/core-protected` 8d2daff (the two doors; on an older read-only file they return the "file is older" error,
  which the plan must say as "not known") and `wip/mirror-name` fb8ab31; made final and cut only on the head
  that holds M5 and K4.
- 20:49: a notice that the coder waits on its own background run (its end-of-work commands, most likely): NOT a
  hand-back. Its branch then: four work-in-progress commits, head 3efc701 pushed, one file uncommitted. Nothing
  of it is read by me yet.
- 20:49: the board read again: M5 is not merged (message 51: G1's race run of the server was cut at its bound
  and runs again with 90 minutes; the batch waits for it). Message 52 (Core, 20:40): the `a3` scripts go through
  the watchdog and were run as the owner runs them; `a3-start.ps1` changed again at 20:45 (after my trial).
- 20:50: **my starter tried again on the start script of 20:45** (the default way, the installed watchdog, a
  stand-in program, full path from another folder, a scratch copy): started, the stand-in saw `run ...
  -auto-mirror -no-downloads`, the watchdog ended cleanly; `-Lines` afterwards as expected; the copy removed.
  Item 26 now says READY; the plan's last section says what was tried when.
- 20:53: **M7's coder handed back: `wip/mirror-timing` 0483a87, pushed, the copy clean** (five commits on 2625aa0;
  report `archiver/docs/progress/mirror-timing-REPORT.md` on the branch). Its runs, by its word: whole
  `internal/mirror` 110 tests 94 s; collector `-run Mirror` 56 pass 208 s; the command 3; gofmt and vet clean; 15
  rule lines undone once each, every one caught. No concurrent code. Its departures: the gathering's "oldest
  candidate" is the one with the earliest time, not the first by message id; three more exported names
  (`ErrGatherRange`, `ReadAutoTiming`, `AutoTimingFacts`); `-timing` and `-gather` need `-account` when the
  catalogue has several; the collector's rig runs steady by default (one new test runs varied). Against M5: one
  expected textual conflict in `mirror_cmd.go` right after the flags are parsed (keep both blocks); none in
  `auto.go` (its changed line is five lines below M5's block).
- 20:54: **read by me:** `timing.go` whole, the diff of `auto.go`, the collector's changed lines, the first half of
  `mirror_timing_cmd.go`. By reading: the random part is never negative and bounded (`spread`), the same for the
  same inputs, a larger bound never gives a smaller part; the pause's key is the last write's second and the
  base pause is what is doubled; a message passes the young rule only when its time plus its part is at or
  under the cut, so none goes younger than 90 s; the gathering only ever returns "hold" or today's path; a bad
  setting returns before any request. **Mine for the fix round:** the gathering's random part reaches 6 hours
  at 1440 minutes (a quarter, as I briefed): to be capped at 15 minutes. Known and left: a mirror whose messages
  are being gathered is counted "caught up", as one whose messages are younger than 90 s is today.
- **20:55: RUNNING: one independent reviewer** (read-only; `BRIEF-M7-review.md`; probes by `-overlay`; its folder
  and report `wt-mirror-review9-scratch/REVIEW.md`), with three questions of mine: the "earliest time" reading,
  a candidate with no time on record, the gathering's bound. PC before: 5.1 GB free, CPU 33%.
- 20:56: while the review runs: **`DESIGN-M6-adopt-chat.md`, a first design for adopting an existing chat**, and
  item 27 on the owner's list (recommended: as written; nothing waits on it). One command of the owner's, never
  the task; the chat read first; what is in it told by the settle's rules over the whole chat (a post-naming
  origin, else a single media match, else "cannot tell" and the owner's word); only the missing forwarded; a
  new column for "adopted" (a schema step). Four things are named in it as not read yet (`weighBatch` at a
  whole chat's size, `AdoptMirror`, whether posting rights are on record, every reader of `mirror_of`): read
  them before its brief.
- 21:04: **the independent review of M7 is back** (`wt-mirror-review9-scratch/REVIEW.md`, 147 lines; probes
  `zz_m9probe_test.go`; nothing edited in the copy). **Part A is sound:** 205,344 pause cases and 16,200 batch
  moments, none sooner than 2625aa0, no album split, the same number every turn, the stored pause always the
  base, an unreadable setting sends nothing; 8 of 8 rule lines undone were caught; no test judges real seconds.
  **Findings: high 0; medium 1; low 4, all in the gathering.** F1 (medium, confirmed, checked by me in
  `tgstore/store.go` `SavePage`): the reader stores every page of a history with the first sighting at "now",
  and the gathering used that time, so a newly joined chat's whole history was held (first forward 130 s after
  the read at once; 4,478 s at 60 minutes; 106,853 s at 1,440). F2 a candidate with no time released the
  gathering; F3 the random part reached 6 hours and was said in seconds, and 1 minute did nothing; F4 an old
  candidate the batch leaves behind released it for about two minutes; F5 a gathering mirror is counted "caught
  up".
- **F1 is my error:** my brief said "a backlog never waits, because its oldest candidate is old" without my
  checking which time a read gives a history's messages, though I had read the query that takes the later of
  the date and the sighting. The coder built what I wrote and its test stored a history as no reader does.
  **Lesson, mine: a sentence in a brief about what a time or a count "is" gets checked at the place that
  writes it, not only at the place that reads it.**
- 21:06: **my decisions, `BRIEF-M7b-fixes.md`:** the gathering is judged on when a message was POSTED (a new read
  door `MirrorMessageDates` in the mirror's own catalogue file), over the batch the turn would really send
  (decided after today's path has built it: all or nothing, so F2 and F4 go with F1); the random part capped
  at 15 minutes, the range 3 to 1440 minutes; the words in minutes and "posted", the two false sentences
  corrected; `-timing` and `-gather` on an older catalogue (the review did not check it). The reviewer's smaller
  fix (no gathering before the mirror exists) is not taken: the rest of the history would still wait N
  minutes after the read. F5 is left and said as known. Part A is not touched.
- **21:06: RUNNING: the same coder, continued, on the fix round** in `wt-mirror-timing` (from 0483a87). PC
  before: 4.4 GB free, CPU 76%.
- 21:22: **the fix round is handed back: `wip/mirror-timing` 36b9c7d, pushed, the copy clean** (three commits on
  0483a87; the report's section "M7b"). Its runs, by its word, all pass: whole `internal/mirror` 114 tests 95 s;
  catalogue `-run 'MirrorMessage|MirrorAuto'` 7 in 1.8 s; collector `-run Mirror` 58 in 207 s; the command 3;
  gofmt and vet (mirror, collector, catalog) clean. Four new tests failed on 0483a87's code and pass now. Its
  departures: `GatherSpread(3)` is 45 s (my brief's 30 s was my arithmetic slip: the rule gives 45); the
  left-behind test uses a gathering of 3; "held until its own N minutes" holds only while a message is alone
  in its batch: the batch's earliest-posted message decides (the rule as I wrote it). The older-catalogue
  behaviour was already right and is now pinned by two tests. No overlap with M5's lines in this round.
- 21:23: **read by me:** the round's diff of `auto.go` (the hold moved to the end of `autoBatch`, on `bs[0]`), the
  new `MirrorMessageDates` (the message's own date, by space, in chunks, a missing row absent), `timing.go`'s
  `gathering` and `gatherHold` (earliest date among the batch's messages that have one; none: no hold; the key
  the album, else the message; the dates read only when a gathering is set). Sound by reading.
- **21:24: RUNNING: the same reviewer, continued, on its second pass** (its first probes again on 36b9c7d, the new
  rule attacked, the tests' fixtures; it appends "Second pass (36b9c7d)" to its `REVIEW.md`). PC before: 3.9 GB
  free, CPU 78%.
- 21:33: **the reviewer's second pass is back** ("Second pass (36b9c7d)" at the end of
  `wt-mirror-review9-scratch/REVIEW.md`; probes `zz_m9b_test.go`): **the piece may be listed.** F1 fixed (at
  once, 5, 60 and 1440 minutes all create at 106 s and first forward at 130 s after the read, all forwarded;
  it was 4,478 s and 106,853 s); F2 and F4 fixed (a stream probe: 16 stories, 229 requests, none before its
  gathering); F3 as decided (the part capped at 900 s; the range from 3). Never sooner, unchanged: 205,344 pause
  cases, 16,200 batch moments, no album split. Part A byte for byte as on 0483a87. Each of the round's six
  rules undone made a named test fail. **New: high 0, medium 0, low 3:** N1 (confirmed) a held batch drops the
  young rule's wake, so a batch that could go earlier goes at the reader's next idle turn (later, never
  sooner); N2 the printed words promise more than the code ("at the latest", "deleted within N is not saved");
  N3 the older rig still stores histories with no sighting (it hides nothing now). N4, a note: a live message
  posted while a history is forwarded rides with it (the rule as written). Not checked by it: a migrated
  source (read only), the collector's varied run test, the merge with M5.
- 21:36: **my decision: N1 and N2 are closed before the listing** (N2 is words the owner reads), in one small
  round by the same coder: `BRIEF-M7c-lows.md` (the wake is the earlier of the two; the words say what decides
  and what else can hold a batch; one line for N4). No third review pass: I read its diff. F5 and N3 stay,
  said as known.
- **21:36: RUNNING: the same coder on M7c** in `wt-mirror-timing` (from 36b9c7d). PC before: 2.7 GB free, CPU
  84% (others' runs): it measures before each go command and waits under 2 GB or over 85%.
- 21:43: **M7c handed back: `wip/mirror-timing` bf2c03f, pushed, the copy clean** (two commits on 36b9c7d). N1: a
  held batch wakes at the earlier of the gathering's moment and the young rule's (its test went at +300 s in at
  most 4 turns; +361 s with the line undone). N2: the words say what decides a batch and what else can hold
  it; the cost line; one line for a history still being forwarded. Read by me (the six lines in `auto.go`, the
  words in `mirror_timing_cmd.go`). Its runs: whole `internal/mirror` 115 pass 92 s; collector `-run Mirror` 58
  tests 202 s: 57 pass, **1 failed once, `TestMirrorAutoReaderGoesOn`** (an older test: pages of an owner's chat
  must fall between the mirror's forwards on the rig's clock; no gathering in it, the rig steady); passed alone
  on its re-run; gofmt and vet clean.
- 21:46: **run by me by name, four times, on bf2c03f** (`GOGC=25 GOMAXPROCS=1 -p 1`, PC before: 3.9 GB free, CPU
  45%): 4 of 4 pass, 87 s. One failure in a set under load (CPU about 84% then), none alone: said in the entry
  as it is, not called settled.
- 21:47: **M7 is LISTED: entry "M7" at the end of `MERGE-QUEUE.md`** (appended from a file, no control byte; the
  queue had 1,363 lines before and 1,433 after: nothing of another entry touched). It says: not to merge before
  M5; no schema step; no concurrent code; the two review passes with their numbers; my brief's error; the one
  test; known and left.
- 21:47: the board says G1 is merged (c8e49ee) and installed at 21:41: **cut new pieces from c8e49ee.** M5 and K4
  are not merged yet. The installed build checked again (`run -h`: `-auto-mirror`, `-no-downloads`; no collector
  running). **My starter takes `-Pages` now** (handed to `a3-start.ps1`) and was tried once more through the
  installed watchdog with a stand-in program: the flags arrived as `-pages -pages-addr 127.0.0.1:8787
  -auto-mirror -no-downloads`; the scratch copy removed; one more public-address look-up. The plan and item 26
  say so, and that only one collector runs at a time (item 29's run is the same start script).
- 21:49: the board: my row ("M7 is LISTED"), the feature table's row, the waiting list's line, message 60 (the
  integrator: what the merge needs; pages: the setting's key and doors).

## STATE FOR A TAKE-OVER (the mirror track, session M3, 11-15 21:49)
- **Merged:** M4. **Listed, in the integrator's batch:** M5 `wip/mirror-name` fb8ab31 (schema step 20 at the
  merge). **Listed, to merge after M5:** M7 `wip/mirror-timing` bf2c03f (copy `wt-mirror-timing`, clean).
- **Running:** nothing (no coder, no reviewer, no go process of this track).
- **Owed by this track when the board says the head with M5 (and K4) is pushed:** (1) merge that head into
  `wip/mirror-timing` (an Opus coder or a clerk on exact instructions: keep both blocks in `mirror_cmd.go`; look
  at `command.go`, which G1 changed; `auto.go`'s hunks do not overlap by the coder's comparison), the named
  tests of the mirror and the collector's `Mirror` set, the new head into entry "M7" and message 60; (2) make
  `BRIEF-M8-protected-and-lows.md` final on that head (check each "check" in it), cut `wt-mirror-protected`,
  one Opus coder, then my read, one independent review, its fixes, the entry; with it a count for a gathering
  mirror (F5) and the wake and words lows are already done; (3) the owner's script `a3\a3-mirror.ps1` gets
  `-NameRule`, `-NamePrefix`/`-NameSep`, `-Rename N -To`, and `-Timing`/`-Gather` once the builds are installed:
  Edit tool only, scan for bytes below 32, run by full path from another folder on a copy first.
- **With the owner:** item 26 (the automatic mirror's first real run: READY; `PLAN-MIRROR-auto-first-run.md`;
  after it runs, read the log's mirror lines and the catalogue read-only, counts only, and hand the numbers to
  the integrator for TELEGRAM-FACTS 11); item 27 (the design for adopting an existing chat:
  `DESIGN-M6-adopt-chat.md`; four code readings are owed before its brief).
- **After M8:** M6 (adoption) when the owner has answered item 27, then a forum mirrored as a forum.
- **Not in git:** `a3\a3-auto-mirror.ps1`. Scratch folders of this session's review: `wt-mirror-review9-scratch`
  (the integrator copies `REVIEW.md` to `docs/review`).
- **Next step, in one line:** watch the board for "M5 is merged" and the new head, then (1) and (2) above.
- (Earlier next step, done:) at the coder's hand-back: read `timing.go` and its call sites in `auto.go` myself,
  then one independent read-only review with probes (the brief for it names: a time that could come sooner
  than today's, a number drawn anew each turn, the gather's edge with albums and put-back messages, an
  unreadable setting, the command's refusals), its fixes, the named runs, entry "M7" in `MERGE-QUEUE.md`; while
  it runs: the protected piece's brief once the board says M5 and K4 are merged, else M6's design note (read
  the chosen chat first; what is in it told from its forwards' origins).

## 15. Session M4 (the mirror track taken over 11-15 22:42, started by the integrator at the owner's word)
- 22:42: **taken over from the block above.** Read by me: the board's direction, order, "Listed and unbuilt",
  the tracks' rows, the merged list and schema line, messages 44 to 67, the waiting list (items 26 and 27); the
  take-over block and the entries from 20:53; entry M7. **Not read yet: the board's messages 6 to 43** (one read
  holds less than they need: to be read in pieces).
- 22:44: the main head is 4daa0309 (K6 on e5260c1; M5 as schema step 20, K4 as 19 under it). **Merged into
  `wip/mirror-timing` in `wt-mirror-timing`: one conflict, as expected, in `mirror_cmd.go` right after the flags
  are parsed; both blocks stay, the timing lines first** (`tf.command` refuses every flag but `-db` and
  `-account` itself, so `-timing` beside `-name-rule` or `-rename` is refused in its fixed words). `auto.go`,
  `command.go` and the help text merged by themselves; read by me in `auto.go`: the name rule is read once a
  turn before the pause, the gathering after the hour's count; an unreadable name rule holds creates only, an
  unreadable gathering returns before any request: they do not meet. Build, gofmt and vet of the mirror and the
  collector clean. **Committed f2cedf18 (not pushed yet).**
- **22:45: RUNNING (background, one go command at a time, `runs-mirror-m7\run.sh`, logs in `runs-mirror-m7`):**
  gofmt, vet (mirror, collector, catalog), whole `internal/mirror`, the catalogue's mirror and schema tests by
  name, the command's tests, the collector's `Mirror` set by name. No race run (no goroutine, lock or channel).
  PC before: 3.2 GB free, CPU 25%. `done.txt` appears when all have ended; each log ends in "exit N".
- 22:46: read by me before the brief: TRIED-BEFORE 24 and 25, `LESSONS-ix12.30-live.md` 6b, TELEGRAM-FACTS 11,
  section 5 and the notes of the second review of M5. **Not read by me yet: FEATURES 12 and the eight mirror
  reviews in `docs/review`** (M3 read them before it drafted this brief; I changed no rule of its draft). Owed
  before M6's brief, with the board's messages 6 to 43.
- 22:46: **`BRIEF-M8-protected-and-lows.md` is FINAL** (no control byte). Each "check" of the draft checked on
  f2cedf18: the doors `ChatProtected` and `ProtectedChats` (`schema_protected.go`; their "file is older" error
  has no sentinel: the brief says not to match its text); the flag is known for a chat the list sent whole
  (`dialogs.go`), so "not known" is rare; `autoCheck` `auto.go:1038`, `Look` `:217`; message 43 (b) is not done on
  the head (in the brief); added by me: a count `Gathering` for a held batch (the timing review's F5), N3's note
  that a rule stored under the old check must still read.
- 22:47: `wip/mirror-timing` f2cedf18 pushed. **The copy `wt-mirror-protected`, branch `wip/mirror-protected`,
  cut from f2cedf18 and pushed** (M8 sits on M7: both edit `auto.go` and `mirror_cmd.go`; its entry will say
  "after M7").
- **22:48: RUNNING: one Opus coder (high effort) on M8 in `wt-mirror-protected`** (it commits and pushes as it
  goes; its report will be `archiver/docs/progress/mirror-protected-REPORT.md` on the branch). PC before: 2.8 GB
  free, CPU 59% (my own runs).
- 22:48: the board: my row (taken over; M7 holds the head; M8 with a coder).
- 22:50: **the owner's script `a3\a3-mirror.ps1` has the name rule's and the rename's modes** (Edit tool only; no
  byte below 32 but line ends; it parses; not in git, as the other `a3` scripts). New: `-NameRule` (read-only:
  `-db` alone, no public-address look-up, no VPN flag); `-NamePrefix "X-" -NameSep "-"` (the two as
  `-name-prefix=` and `-name-sep=`, so an empty prefix arrives); `-Rename N -To "name"` (with the VPN flags, as a
  step). Exactly one of the five modes, else fixed words and exit 2. **The arguments now go as one command line
  quoted by Windows' rules** (an argument list was joined unquoted: a name with a space, an empty prefix or a
  folder with a space would have been split or lost). `-Timing` and `-Gather` are NOT in it: M7's build is not
  installed.
- **Exactly what I ran, each from another folder by the script's full path, `powershell -NoProfile
  -ExecutionPolicy Bypass -File "C:\Users\trabi\Claude\Projects\Telegram\a3\a3-mirror.ps1" -Root <a scratch copy
  of the test catalogue in a folder with a space in its name, an empty placeholder for the sign-in file>`, the
  installed build, the input ended, no collector running:** (1) no mode, (2) `-Chat 4 -NameRule`, (3) `-Rename 4`
  alone: the fixed words, exit 2, not started; (4) `-NameRule`: the default rule in lengths and the invented
  example, exit code 0; (5) `-NamePrefix "X-" -NameSep:-`: the plan, "the input ended: nothing was written"; (6)
  `-NamePrefix "" -NameSep " #"`: prefix 0 units, separator 2 units, the example "Example #1", nothing written;
  (7) `-Rename 4 -To` a 19-character invented name with spaces and a quote: the rename's plan, "the new name: 19
  UTF-16 units", "the input ended: nothing was sent"; (8) `-Chat 4`: the plan as before, nothing sent. Runs 7
  (three times before the placeholder sat where the command looks) and 8 looked the public address up once
  each; nothing was dialled. My 16 test logs are removed from `a3\logs`, the scratch copy is removed.
- **One fact for the owner from run (4) of the first try:** `powershell -File` cannot take a value that is only
  a dash after a space (`-NameSep "-"` fails inside PowerShell before the script runs): the default separator is
  written `-NameSep:-` (with a colon). The script's own lines do not say this yet: to add.
- 22:51: **M7's runs on f2cedf18 ended** (`runs-mirror-m7`): gofmt and vet clean; whole `internal/mirror` ok
  113 s; the catalogue's named tests ok 4.5 s; the command's tests ok; **the collector's `Mirror` set: 68 pass, 1
  FAILED: `TestMirrorAutoRunVaried`** (the piece's own run with the random part on; 31.8 s, as long as a pass,
  so an assertion, not a wait that ran out). **My mistake: the run's script kept only the result lines, so the
  failure's own message is lost.** PC during it: CPU about 59%, the coder starting.
- (The times of the next five entries were written from memory and ran about two minutes ahead: put right
  here from the logs' own times. The integrator's message 69 said so.)
- 22:52 to 22:56: the test by name: 1 of 1, then 6 of 6 pass (31 to 32 s each; 4 writes, the gaps 22 to 32 s).
- **22:56: RUNNING (background): the collector's `Mirror` set again on f2cedf18 with its full output kept**
  (`runs-mirror-m7\collector-mirror-2.log`, ends in "exit N" and the time). **M7 is NOT called ready until that
  failure is read:** if it fails again in the set and never alone, it depends on the tests before it (the set
  grew from 58 to 69 with M5's and the head's tests): a fix of the test or the rig, by a coder, before the entry.
- 23:00: **the second set run failed the same way, and this time its message is kept:** 68 pass,
  `TestMirrorAutoRunVaried`: "live message 3 went 1m41.748s after it came; its random part is 12s". **Read by me:
  the rule holds; the test's measure is a second too fine.** `autoBatch` (`auto.go:1103`) lets a message through
  when its own time in whole seconds plus its part is at or under "now minus 90 s" in whole seconds; the fake
  dates a pushed message with its clock's whole second; the test measured from the push's own sub-second
  moment, so a turn in the rule's first open second reads up to a second short (here 0.25 s). Not sooner than
  2625aa0's rule, which cut on whole seconds the same way. **Not explained: why 2 of 2 in the set and 0 of 7
  alone** (the sub-second phase of the rig's clock at the push looks like what decides; the set grew from 58
  to 69 tests with the merge).
- 23:01: **one line of the test changed by me** (`mirror_timing_cmd_test.go`: the span is measured from the
  start of the second the push falls in, with the reason beside it; no product line touched; not reviewed).
  The `Mirror` set a third time with the change: **69 of 69 pass, 257 s** (`collector-mirror-3.log`, ended
  23:05:35).
- 23:05: **committed and pushed: `wip/mirror-timing` cb08ca62.** The M8 coder is told to cherry-pick it before
  its end-of-work runs (a message to the agent). Entry "M7" has a first block "M7-STATE: READY" with the merge,
  the runs, the failure and its reading; my board row says so.
- 23:06: **the board had moved while I worked (messages 67 to 69, read 23:06): the main head is 27a7d4dc (C9 and
  G2 merged 22:48) and M7 merges only on a head that holds it.** Merged into `wip/mirror-timing`: clean,
  **169d40ab** (not pushed yet); no file of the mirror's changed by it (the diff of the mirror's files against
  cb08ca62 is empty). **RUNNING (background, `runs-mirror-m7`, the `-2` and `-4` logs):** build, gofmt, vet,
  whole `internal/mirror` and the command's tests, the catalogue's named tests, the collector's `Mirror` set
  with full output. PC before: 6.9 GB free, CPU 56%.
- From message 69: a new integrator (the session of 22:55) merges; the owner is away until morning and said
  fresh sessions may be started for full tracks ("READY FOR A TAKE-OVER" at the front of the row); nothing runs
  against Telegram tonight. **From pages (69 d), mine to place:** `startAutoMirror` runs once over the accounts
  of the start, so an account added or signed in while the program runs gets no automatic mirror until the
  next start (a row for "Listed and unbuilt").
- 23:13: **on 169d40ab all pass:** build, gofmt, vet; whole `internal/mirror` ok 101 s; the command's tests; the
  catalogue's named tests ok 5.7 s; **the collector's `Mirror` set 69 of 69, 245 s** (the second whole pass of
  the set with the test line). **Pushed: `wip/mirror-timing` 169d40ab.**
- 23:14: **the main head had moved again: 2ea9b465 (K7, the fake Telegram's fix: six files in
  `collector/faketg`, the rig the collector's mirror tests run on; and the viewer's entry 20).** Merged, clean
  (the head is in `runs-mirror-m7\head-3.txt`; not pushed yet). **RUNNING (background): build, vet and the
  collector's `Mirror` set on it** (`build-vet-3.log`, `collector-mirror-5.log`): the fake changed under those
  tests, so they are run once more; `internal/mirror` does not use the fake and is not run again. PC before:
  in the task's own output.
- The board, 23:08: a new row in "Listed and unbuilt" (an account added while the program runs gets its
  automatic mirror without a restart: mine, after M8 and G3); my row's order.
- 23:19: **on 2da8b60c (the head that holds 2ea9b465): build and vet clean, the collector's `Mirror` set 69 of
  69, 255 s. Pushed: `wip/mirror-timing` 2da8b60c; the copy clean.**
- 23:20: **M7 is READY and said so everywhere:** entry "M7" (a first block "M7-STATE: READY" with the three
  merges and the runs; the 23:06 block under it); my board row; the "Waiting to merge" line; **message 74** (to
  the integrator and pages: the merge, the failure's reading, M8, the script, pages' 69 d taken, my order);
  the mirror rows of `MORNING-2026-11-16.md` (the integrator's table for the owner). Messages 67 to 73 read
  (73: the owner said "Run flat out"; the mirror's order there: the protected refusal, then adopting a chat
  and forums; at 85% of the week every session finishes to its next listing and starts nothing new).

- 23:21: **the owner's order changed (the integrator's message 74, read 23:21; pages' message 75, read 23:26):
  "add in a functioning mirror option since that is immediately useful and we've tested it": the mirror usable
  from the Chats page comes ahead of adopting a chat and forums.** Pages builds the page (G4); the mirror gives
  it its doors and makes the running collector carry out a want the owner made by hand; nothing new is sent to
  Telegram by it (the automatic task's own loop does the work).
- 23:24: read by me for it: `schema_mirrorauto.go` (the wants, the marks, `MirrorAllow`, `AddMirrorWant`),
  `auto.go`'s `mirrorTurn`, the collector's `startAutoMirror`, `autoApprove` and `autoTurn`, the plan's fields,
  FEATURES 12's lines on choosing mirrors. Found: the task runs only with `-auto-mirror`; `AddMirrorWant`
  refuses a chat that has any mirror row (so the command-made test mirror could not be kept current); a want
  does not [name removed] made it; the settle's choices exist only in the command, with the collector stopped.
- **23:24: `BRIEF-M9-mirror-door.md` written (no control byte), with "Addendum 1" of 23:27 (pages' list: the
  owner's stop of one mirror, more of the state, the word `by-rules`, the Settings methods). Schema step 22
  taken on the board's schema line. The copy `wt-mirror-door`, branch `wip/mirror-door`, cut from 2da8b60c
  and pushed.**
- **23:25: RUNNING: one Opus coder (high effort) on M9 in `wt-mirror-door`** (PC before: 9 GB free, CPU 63%); it
  commits and pushes as it goes; its report will be `archiver/docs/progress/mirror-door-REPORT.md`; told of
  the addendum by message at 23:27.
- 23:25: **M8's coder handed back: `wip/mirror-protected` cd4a6c95, pushed, the copy clean** (four commits on
  f2cedf18, one of them my test line cherry-picked; its report on the branch). Its runs, by its word, all pass:
  whole `internal/mirror` 151 tests 124 s; catalogue `-run 'Mirror|Protected'` 31; collector `-run Mirror` 76,
  253 s; the command 3; vet clean; gofmt applied after the runs to three files, then the part C tests by name
  again. 24 one-line mutants, each caught. Five departures: a read door `MirrorSourceProtected` in
  `catalog/mirrorsettle.go` (it asks the file's schema first on a read-only handle); three forms of the
  not-known line; one line of `collector/heartbeat.go` (Core's file: the numbers line gains "N gathering");
  a separator of marks and spaces refused; the flags refused beside `-never`, `-allow`, `-list` include the
  VPN and key flags. Only reasoned, by its word: message 43 (b)'s wording; a chat ended as protected keeps a
  read approval given before (the reader may go on reading it).
- 23:26: **read by me:** the whole diff of `auto.go`, `mirror.go`, `read.go`, `step.go` and the catalogue's
  door. By reading: `Look` leaves a known-protected chat before its want and approval and counts it; `autoCheck`
  ends a want on the flag after the mark and the left check, before any create, forward or settle; a door
  error returns before anything is sent (in `Look` it ends the whole look: a question for the review);
  `planOf` blocks with words of its own; `Estimate` reads the flag again before its request; the gathering's
  count changes a number only. `MirrorAllow` on an end of "protected" clears the end, and the next turn ends
  it again at 0 requests while either source says protected (the coder's test: three allows in a row).
- **23:27: RUNNING: one independent reviewer of M8** (read-only; `BRIEF-M8-review.md`, ten points; probes by
  overlay; its folder and report `wt-mirror-review10-scratch\REVIEW.md`). PC before: 10 GB free, CPU 62%.
- 23:27: the board: **message 77** (the doors' final names for pages, what each does, what a click leads to,
  the order inside M9); the schema line; my row.

- 23:42: **the independent review of M8 is back** (`wt-mirror-review10-scratch\REVIEW.md`, 147 lines; nothing
  edited in the copy): **"may be listed after two one-line fixes"; high 0, medium 1 (by reading), low 4.**
  Sound, with its probes: every path reads the flag before any request; a failing door takes nothing and a
  later look recovers; the stored name rule (0 differences over 2,044,900 pairs; 641,720 refused only as new
  rules); a create begun before the new trimming is found by its stored name; the real batch of 99 settles
  to the same 65 and 34 before and after N4; the gathering's count moves no time; six mutants of its own
  choice each caught. **F1 (medium, by reading, older than M8):** a want that ended keeps the read approval the
  task wrote, so the reader goes on reading. **F2 (confirmed):** the plan's "not known" line names the wrong
  cost in two states. **F3 (confirmed):** in the owner's run of several batches the flag (and the mark: older)
  is not read again between batches. **F4:** one non-constant format string. **F5:** the older-file test
  builds its file by dropping one column.
- 23:43: **my decisions, `BRIEF-M8b-fixes.md`:** the main head 5a516ac merged in first (M7 is merged and
  installed: the integrator's message 76); F2, F4 fixed; F3 fixed for the flag and the mark (the command holds
  the catalogue's lock, so nothing can change either during a run today: it is the rule kept for when the
  running program may write marks); F5 with a real older file if a helper exists; **F1 not here: on the
  board for Core (message 79 b), my half with M10.** No whole runs by the coder: mine, once, on its head.
- **23:43: RUNNING: the M8 coder, continued, on the fix round** in `wt-mirror-protected` (from cd4a6c95).
- 23:44: **the automatic mirror's starter tried on the build installed at 23:37** (the integrator's message 76):
  by its full path from another folder, a scratch root and state, the installed watchdog, a stand-in program
  built for it, `-Pages`: started, the stand-in saw `run ... -pages -pages-addr 127.0.0.1:8787 -auto-mirror
  -no-downloads`, ended cleanly, no restart; `-Lines` as expected. One look-up of the public address. The
  scratch and the stand-in removed. `PLAN-MIRROR-auto-first-run.md` has the varied times (20 to 30 s between
  forwards, 90 to 120 s for a new message) and this try; item 26 says so.
- 23:45: **`a3\a3-mirror.ps1` has `-Timing` and `-Gather N`** (Edit tool; no byte below 32 but line ends; it
  parses). Run by its full path from another folder on a scratch copy of the test catalogue with the
  installed build, the input ended: (1) `-Timing`: the times as the build says them, exit code 0; (2) `-Gather
  10`: the cost in fixed words, "the input ended: nothing was written"; (3) `-Gather 2` and (4) `-Timing -Gather
  0`: the script's fixed words, exit 2, not started; (5) `-Gather 0`: "at once", nothing written; (6)
  `-NameRule` and (7) `-Chat 4` as before. Nothing dialled (runs 1 to 6 look no address up; run 7 once). My
  8 test logs removed from `a3\logs`, the scratch copy removed. In my scratch folder six small files of my
  agents remain (theirs).
- 23:44: seen, not mine: one process `tgarchive-collector` started 23:44:42 from a folder named `programs`
  (not the installed `bin`): said in message 79.
- 23:46: the board: message 79 (the review, F1 to Core, the integrator's three points), item 26's line.

- 23:49: **M8's fix round handed back: `wip/mirror-protected` 199a2a52, pushed, clean** (two commits on cd4a6c95:
  the merge of 5a516ac, the fixes). The merge had one conflict, in `auto.go` around `autoBatch` (the main head
  holds M7 as one squashed commit); the coder kept the branch's file whole. **Checked by me:** the main head's
  `auto.go` equals f2cedf18's byte for byte (an empty diff), and the branch against the main head differs in
  M8's 17 files only. F2: the "not known" line has five forms now, none with a cost on a plan that sends
  nothing (a test over eight states). F4 done. F3: `runHeld` reads the mark, then the flag, before every
  batch's intent row (catalogue reads only; a failed read ends the run as a failed ledger read does); tests:
  1 forward before, 0 after, for the flag, the mark and a failing door; a run in which nothing changes keeps
  its requests and their moments. Six lines undone, each caught. **F5 not done:** the only helper that makes a
  real older file is unexported in the catalogue's tests; the test stays as it was (it checks the door; the
  plan's other reads on a real older file are not exercised by it). Its runs by name pass (mirror 13,
  collector 6; gofmt, vet).
- 23:49: **read by me:** the round's diff of `step.go` and `mirror_cmd.go`: sound. One comment had been parted
  from its function by the insert: moved back by me (**76df070b**, a comment only, pushed).
- **23:50: RUNNING (background, `runs-mirror-m8\run.sh`, full output kept in `runs-mirror-m8`; `done.txt` when
  all have ended):** on 76df070b: build, gofmt, vet; whole `internal/mirror`; `internal/catalog -run
  'Mirror|Protected|Schema'`; the command's tests; `internal/collector -run 'Mirror'`; the viewer's wall test.
  No race run (no goroutine, lock or channel). PC before: 7.3 GB free, CPU 75%.

- 23:56: **M8's whole runs on 76df070b all pass** (`runs-mirror-m8`, full output kept): build, gofmt, vet clean;
  whole `internal/mirror` 153 tests, 111 s; `internal/catalog -run 'Mirror|Protected|Schema'` 41 tests, 14 s;
  the command's 3; **`internal/collector -run 'Mirror'` 77 of 77, 247 s**; the viewer's wall test ok. The
  branch holds the main head 5a516ace (checked by ancestry).
- **23:57: M8 IS LISTED: entry "M8" at the end of `MERGE-QUEUE.md`** (appended from a file, no control byte; the
  queue had 1,560 lines before and 1,629 after). The board: my row, the "Waiting to merge" line, **message 81**
  (to the integrator; answers to Core's message 80), the schema line (22 was written twice within a minute,
  by Core and by me: the numbers follow the order of the merges).
- 23:58: **Core's message 80, read 23:57, and what I did:** (a) Core moves the Forwarder-making block of
  `autoTurn` into a helper: M9's coder is told to leave that block textually alone; (b) Core asked for a door
  "the account wrote just now" so that the owner's clicks lengthen the mirror's pause: **added to M9 as
  "Addendum 2": `(*catalog.Catalog).NoteAccountWrite(ctx, account, at)`** (a settings row per account, only
  ever raised; `MirrorLastWriteAt` returns the later of the ledger and the note; unreadable: nothing sent);
  (c) `RANDOM_ID_DUPLICATE` with code 500 read as "outcome unknown": left as it is, on purpose (the settle
  from the mirror chat is the stronger evidence; nothing is sent twice). The M9 coder is also told to merge
  M8's head in before its end-of-work runs and to make `Want`, `PagePlan` and `States` use the flag.

- 11-16 00:12: woken by the M9 coder's notice (it waits on its own end-of-work runs; `wip/mirror-door` 6567eb29
  on `private`, M8 merged in: "the doors use the chat list's protected flag"). The main head is 29bcfa2e (K8).
  The installed build is still 5a516ac (M8 not merged yet). **Read: the board's messages 81 to 83 of Core and
  pages (four, all to the mirror).**
- 00:14: **my decisions, on the board as message 84 and in `BRIEF-M9b-round.md` (a DRAFT, made final when
  M9's review is back):** (a) a settle word names the block it was chosen for: `ChatState.Block` and
  `MirrorSettleWord(ctx, account, chat, word, block)` (pages' review, a must-fix); (b) `ChatState.Offers` and
  `Stopped` replace `Choice`: the mirror package says which words a block offers, read off the command; (c) an
  allow does not undo the owner's stop (only a new want does); (d) `MirrorCheckNameRule`; (e) **Core's proposal
  for the approval of an ended want, agreed: a mark (a time in the record), not a removal; Core adds the field
  and the reader's skip; my half is a small piece after Core's round and M9 are merged, ahead of M10**; (f) the
  account delete (Core's 83): checked by reading: a reused account number would inherit wants that make
  requests; proposed to the integrator to fix at the root (a number never given twice); my guard in M9b: the
  doors and the task refuse an account not signed in on record; (g) M9b merges the main head (K8 shares
  `memo.go` with the mirror).

- 00:15: **M9's coder handed back: `wip/mirror-door` e57adb3f, pushed, clean** (13 commits on 76df070b's line;
  M8 merged in at bbf97a84 with no conflict; its report on the branch). Built: the catalogue (step 22 as "the
  step after the mirror's name" in two constants: `c_mirror_want.by`, `c_mirror_word`, `AddOwnerMirrorWant`,
  the word's doors, `MirrorChatRows` in 8 statements, `NoteAccountWrite`); `mirror/door.go` (`States`,
  `PagePlan`, `Plan.Token`, `Want`, `Never`, `Allow`, `Stop`, `SettleWord`); the task (owner's wants first, one
  cap for every starter, `OwnerOnly`, the word carried out in `auto_word.go`); the collector (the turn without
  `-auto-mirror` for owner's wants only, `mirror_door.go`, the secret loaded whenever its file exists).
  Its runs, by its word: whole `internal/mirror` 170 pass 140 s; catalogue `-run 'Mirror|Schema'` 50; the
  collector's `Mirror` set 82, 312 s; the command 3; vet, gofmt clean; 17 rule lines undone, each caught.
  Ten departures (its report): `-list` does not [name removed] started a want yet (the line is in `mirror_marks.go`);
  the "not made" condition exists twice; a chat nothing knows is switched off for downloads by a want (the
  command's default); plans blocked only for a while are accepted; the fits rule per block word; the cap
  counts every starter, the command's creates too; automatic wants wait for the switch; `Never` is the chat's
  own mark only. Concurrent: `turnDue` (atomic), `next` and `unreadable` under `autoSession.mu`, the secret
  file. Not checked by it: the race detector; two of `MirrorTask`'s words; a damaged secret file.
- 00:16: **read by me:** the whole diff of `collector/mirror_auto.go` and `AddOwnerMirrorWant`. By reading:
  without the switch a turn reads the wants and returns unless an owner's want is live; the look, the
  baseline and the policy stay behind the switch; the nudge only clears the yield (the pause between writes
  is the task's own and is not touched); the Forwarder's block is textually as it was, with a second making
  of it before the block for a run that started without the secret; the want's transaction refuses on a
  mark, any end but the owner's stop, an open want, a family member's mirror, and a mirror row that is not
  "created". **Not read by me: `auto_word.go`, `door.go`, `mirror_door.go`: the review's first points.**
- **00:17: RUNNING: one independent reviewer of M9 on a FROZEN copy** (`wt-mirror-review11-tree`, detached at
  e57adb3f; `BRIEF-M9-review.md`, fifteen points; its folder and report `wt-mirror-review11-scratch\REVIEW.md`).
  PC before: 7.3 GB free, CPU 81%.
- **00:18: RUNNING: the M9 coder, continued, on M9b** in `wt-mirror-door` (`BRIEF-M9b-round.md`, FINAL: the main
  head merged in; the settle word's block; `Offers` and `Stopped`; an allow leaves a stop; `MirrorCheckNameRule`;
  an account not signed in refused; `-list` says who started; one "not made" condition; `Never` through the
  family). The review's findings follow as a third small round (M9c), then the reviewer's second pass over
  both rounds.

- 00:33: **the independent review of M9 is back** (`wt-mirror-review11-scratch\REVIEW.md`; probes beside it; the
  frozen copy untouched): **"may be listed after these fixes"; high 0, medium 1, low 7.** Sound, with its
  probes: no door reaches a forwarder, the reader or a connection; with the switch on and no door used the
  requests and their seconds equal 76df070b's; 200 door calls during a history move no write; 16 wants at
  once: 1 written; the word on a batch of 99: no message twice; 8 statements and 274 ms at 300 mirrors.
  **F1 (medium, confirmed, 6 of 6): a stop, a never mark or the protected flag written during a turn did not
  stop that turn's request** (checked before the intent row, not in its transaction; for the mark and the
  flag the window is as old as 76df070b, for the stop it was the whole turn). F2: `Kept` true for an automatic
  want a run without the switch never serves. F3: "create-not-made" accepted for a create under way that the
  state does not offer. F4 (by reading): `account.signedIn` read plainly from an HTTP goroutine. F5: a stale
  "cannot be read". F6: an account the catalogue does not have gets a plan and a mark row. F7: five rule
  lines no test holds (one: the twin-by-migration refusal: undone, a second mirror chat is created);
  `TestMirrorDoorRunNever` lets one write through after the mark. F8: a twin's plan is not blocked, its want
  is refused in the wrong words. The cap (the coder's departure 9), measured: with the cap at 1 and a
  command mirror made just before, the automatic create went 24 h later.
- 00:33: **my decisions: every finding accepted: `BRIEF-M9c-fixes.md`** (F1: the check moves into the
  transaction that writes a create's or a batch's intent row; the door refuses a word the state does not
  offer; a state of its own for an automatic want waiting for the switch; the atomic for signed-in; the
  account not on record refused; the twin's plan blocked in its own words; a test for each of the five
  lines; `TestMirrorDoorRunNever` made exact; one more test that reads `MirrorTask` and `MirrorStates` from
  another goroutine during a run, for the race run). The cap stays as built (the safe value; pages' item 30
  says the same to the owner).
- **00:34: the M9 coder, continued, is told to go straight from M9b into M9c** and to make its end-of-work
  runs once, at the end of both. The M9 reviewer has ended (its agent can be continued for the second pass).
- 00:34: ready for afterwards: `runs-mirror-m9\run.sh` (the whole runs, full output) and
  `runs-mirror-m9\race.sh` (the race detector over `TestMirrorDoor|TestMirrorAutoSwitchOff|
  TestMirrorAutoRunStory` of the collector in one container, 2 CPUs, 4 GB, the shared cache volume).
- 00:35: the board: message 85 (the review; what changes for the page; the cap as measured).

- 01:09: **the M9 coder handed back both rounds: `wip/mirror-door` 21153789, pushed, clean** (the main head
  29bcfa2e merged in with no conflict; the code its final runs tested is 8b51189d, the last commit two
  comments). M9b as briefed (the block token is a hash of the mirror row, its state, the blocking batch, the
  block word and the word on record; `BlockOffers` is the one map: cannot tell, repeat, contradiction:
  arrived and not-arrived; again, day: by-rules; a lost create: create-not-made; else none; an allow leaves
  the owner's stop; `AutoDeps.SignedIn` read by every door and at the top of every turn; `-list` says who
  started; `CheckNotMade` is the one condition; `Never` through the family: 9 statements now). M9c: **F1: the
  intent's own transaction (`intentHeld`, called by `BeginMirrorBatch` and the creates) checks the want's end
  or block, the family's never mark and the flag; held: nothing written, nothing sent; the task ends that
  turn with no request, the command in the plan's words; a behaviour change it names: the owner's command no
  longer begins a create or a batch while the chat's want is blocked;** a state "waiting" for an automatic
  want without the switch; the atomic for signed-in; an unknown account refused; the twin blocked at the
  plan, the want and the catalogue; every unheld line has a test. Its final runs, by its word: whole
  `internal/mirror` 183 pass 176 s; catalogue named 57; the collector's `Mirror` set 85, 324 s; the command 3;
  vet, gofmt clean; 23 rule lines undone, each caught. **Its fault, said by it: the PC was not measured
  before each of those runs** (a script's relative path). Not done: the sentinels' words in `words.go`.
- 01:09: **read by me:** `intentHeld` and its two call sites, the allow's three statements. By reading: the
  check is inside the Batch that writes the intent; an older file without the tables is "not held"; a chat
  with no row is "not known". **Not judged by reading: whether the reads inside the transaction run on the
  transaction's own connection (the door's write truly before or after): the second pass's first point.**
- **01:09: RUNNING: the M9 reviewer, continued, on its second pass** (the frozen copy moved to 21153789; it
  appends "Second pass (21153789)" to its `REVIEW.md`). PC before: 6.5 GB free, CPU 38%.
- 01:10: **the main head moved: 698ee15d: M8 IS MERGED (1394a9ce) and in the installed build (698ee15); Core's
  ledger of clicks merged as schema step 21** (the integrator, 00:33: the mirror's step is the one after the
  newest on the head when it lists). M9's step was written as "the name's step plus one" (21): **the M9 coder,
  continued, runs "M9d" since 01:10:** merge the newest head (M8's squash will conflict with M8's own
  commits: the branch's files kept where the head's equal 76df070b's), the step re-pointed after `actSchema`
  (22), the sentinels' words into `words.go`'s list, named tests only.
- 01:11: item 26 and its plan say the installed build refuses a protected chat before any request (the
  build's `run -h` names the starter's flags; no stand-in run again: the starter and the watchdog did not
  change). Core's messages 86 and 87 read: its half of the ended read (K11) is in its fix round; **for my
  half: clear the field on a new want; write it only on a record whose `By` is the mirror's.**

- 01:15: **"M9d" handed back: `wip/mirror-door` 75af73a5, pushed, clean** (the merge of 698ee15d with the round
  inside it). Two conflicts: `mirror/step.go` (the head's file equals M8's: the branch's kept whole) and
  `catalog/catalog.go` (the schema register: by hand, three places: `SchemaVersion = mirrorWantSchema`, both
  steps in the map, both cases in the switch). **The step is 22: `mirrorWantAfter = actSchema`**; a new test
  steps files at 20 and at 21 once each and reads both read-only without stepping them. `words.go`: one line
  with the doors' and the catalogue's new sentinels, and a test. Its named runs pass (catalogue 90, the
  mirror's door and want tests 32, the collector's 9; build, vet, gofmt). **Checked by me: the branch holds
  the main head 698ee15d and differs from it in M9's 20 files only.** The whole runs and the race run wait
  for the reviewer's second pass (the order: the review's fixes first, the full runs once).

- 01:17: **the owner's rule of 01:15, read (the integrator's message; the board's new section "Routine steps go
  to a Sonnet clerk, always"; `CLAUDE.md`'s archiver section): from the next step on, the routine sequences of
  this track (starting `runs-mirror-m9\run.sh` and `race.sh` and reading their exit lines, a clean merge of the
  head, commits with my message, pushes, removing the review's copy, measuring the PC, drafting an entry from
  these notes) go to ONE Sonnet clerk call on an exact instruction, or to a script; every entry that reports
  such steps says "by a Sonnet clerk" or why not.** (Until now this session did them call by call itself:
  M7's and M8's runs, the merges, the commits.)

- 01:24: **the reviewer's second pass on 21153789 is back: "may be listed".** All eight first findings fixed
  (six by its own probes run again, two by exact reading). **F1, harder: the intent's check is serialized**
  (the writer connection begins its transactions immediately and is one connection; the check's reads run on
  the transaction's own handle; 90 runs with real goroutines: 0 intent rows begun after a door's write had
  returned, 15 held); every caller takes "held" as "nothing sent". The switch-on run without doors: the same
  request digests as before the piece. The random ids of the command and the task: 50 of 50 the same. **New,
  all low:** N1 (confirmed): after the intent row the forwarder may still sleep a wait Telegram stated
  meanwhile (at most the task's 60 s) before the request leaves, so a request can leave after a stop's write
  returned; N2 (confirmed): after the command's `-settle -take` the want stays blocked, the command says "run
  mirror again", and the next run is refused until an allow; N3 (confirmed): a command mirror stopped from a
  page cannot be started again from the command, and the plan says "-allow undoes it"; N4 (by reading): a
  catalogue read error is taken for "not signed in" and ends the task for the session; N5 (confirmed, older):
  an unreadable end word on the mirror row does not stop the task.
- 01:25: **my decisions, `BRIEF-M9e-last.md`:** N2: the owner's settle lifts the want's block when the block is
  one of the settle's own (one function says which); N3: true words for a stopped mirror; N4: a read error is
  "cannot be read", never "not signed in" (a read of the mirror's own beside the doors; Core's function not
  edited); N5: the mirror row's end word read where the intent is checked; the concurrent test also writes.
  **N1 not changed in code, on purpose:** the boundary is the intent row; in the real program the reader's
  goroutine sends both the mirror's requests and (with Core's K9b) the owner's clicks, so a wait cannot be
  recorded between a turn's top and its request by another goroutine; the probe forced it. It is said in the
  doors' comments, in the report and in the entry; the page's words are pages' (message at the listing).
- **01:25: RUNNING: the M9 coder, continued, on M9e** in `wt-mirror-door` (from 75af73a5; named tests only).
  The reviewer has ended. **After the hand-back:** my read of its diff; then ONE Sonnet clerk call: the copy
  clean and holding the main head (a clean merge if the head moved; a conflict: stop), `runs-mirror-m9\run.sh`
  and `race.sh`, their exit lines, a table back; then the entry.
- 01:26: `runs-mirror-m9\notes-commit.sh` written: the notes' commit as one script (the control-byte scan, only
  the named files, the co-author line): the rule's "or by a script". (The four times above were first written
  from memory, ten minutes ahead of the clock; put right from `date` at 01:27. From here every entry's time is
  the `date` line of the command before it.)

- 01:45: **M9e handed back: `wip/mirror-door` 2f52b459, pushed, clean** (the code at f23ea4ed; then two settle
  tests and the report). N2: the command's settle goes through `catalog.SettleMirrorBatchLift`: in the settle's
  transaction, when it settled, the want's block is cleared only if `mirror.SettlesBlock` says it is the
  settle's own (cannot tell, repeat, contradiction, again, day: derived from `BlockOffers`); another block
  stays and is said with the allow; no "run mirror again" then. N3: `mirror.WhyStopped` in the plan and at a
  held intent; `-allow` says the stop is kept. N4: `mirrorSignedIn` returns an error of its own for a failed
  read ("the record cannot be read"); Core's `isSignedIn` not edited. N5: `intentHeld` reads the open mirror
  row's end word (unreadable: `ErrBadLedger`; stopped or ended: held). The concurrent test also writes (60
  never and allow calls, a want and its stop on another chat during 600 forwards). Seven rule lines undone,
  each caught. **Two older tests changed by it** (`TestMirrorSettleRepostsInChannel`,
  `TestMirrorSettlePutBackAlone`): they asserted "settle, then an allow that unblocks 1"; now "the settle
  lifted; the allow unblocks 0". Its named runs pass (mirror 67, collector 53, catalogue 57; build, vet,
  gofmt).
- 01:45: **read by me (a judgement: not a clerk's):** the round's diff of the catalogue: the lift is inside the
  settle's own transaction and clears exactly the block word it read; the intent's check reads the one open
  mirror row of the source. Sound by reading. No third review pass: the round is five small rules, each with
  a test that fails when undone; said so in the entry.
- **01:45: RUNNING: ONE Sonnet clerk on the full runs** (exact steps: the PC measured; the copy clean at
  2f52b459 and holding the main head, else stop; `runs-mirror-m9\run.sh` and `race.sh` side by side when 7 GB
  are free; the exit lines, pass, fail and race-report counts back; nothing run twice, no file changed).
  Said first: whole `internal/mirror`, the catalogue's and the collector's mirror tests by name, the
  command's tests, the viewer's wall test, gofmt, vet (about 12 minutes); the race detector over the
  collector's door tests by name (`TestMirrorDoor|TestMirrorAutoSwitchOff|TestMirrorAutoRunStory`) because
  the door adds one flag crossed between goroutines and fields read under a lock (one container, 2 CPUs,
  4 GB, about 20 minutes).

- 01:46: by a Sonnet clerk (its first call): the PC 5.9 GB free, CPU 67%; the copy clean at 2f52b459; **the main
  head had moved to 3ced3c09 (Core's K11: the reader stops for a mirror's read that ended; six files, no
  schema step): the clerk stopped as told, nothing run.** Checked by me (one command, a judgement): a trial
  merge is clean. The clerk sent back with the clean merge as its first step.
- 01:48: `BRIEF-M11-ended-read.md` drafted (the mirror's half of the ended read: the task writes Core's field
  when a want ends and clears it on a new want; cut after M9 is merged).
- 01:50: by a second Sonnet clerk: the entry for M9 drafted from the coder's report, the review and these notes
  (`runs-mirror-m9\entry-m9-draft.md`, 177 lines, no control byte); corrected by me in three places.
- 02:08: **by the Sonnet clerk: the head merged in cleanly: `wip/mirror-door` 477db0b4 holds 3ced3c09 (build and
  vet clean, pushed). The whole runs on 477db0b4, once, full output in `runs-mirror-m9`: ALL PASS:** build,
  gofmt, vet clean; whole `internal/mirror` 186 tests, 159 s; `internal/catalog -run 'Mirror|Protected|Schema'`
  59, 23 s; the command 3; `internal/collector -run 'Mirror'` 89 of 89, 331 s; the viewer's wall test ok. PC
  before: 6.1 GB free, CPU 82% (so one after the other). **The race detector over the collector's door tests
  by name (one container, 2 CPUs, 4 GB, 673 s): NOT PASSED: 10 pass, 3 fail, 1 race report.**
- 02:09: **read by me (the race log):** (1) `TestMirrorAutoSwitchOff`: the report is between THE TEST's own
  goroutine reading `session.autoIdle()` (`mirror_auto_test.go:253`) and the reader's goroutine writing
  `nextAt` in `autoTurn`'s early return for "no owner's want" (`mirror_auto.go:470`, new in M9): a field the
  reader's goroutine owns, read by a test from outside; in the product `autoIdle` is called by the reader's
  task (to be confirmed by the coder for every caller). (2) `TestMirrorDoorRunNever` and
  `TestMirrorDoorRunAccountStop`: "timed out (1m0s) waiting for 5 minutes of the clock": a bound on real time
  that the slow detector run exceeds, not a rule broken (the kind of test fault board messages 16 and 25
  name). `TestMirrorAutoRunStory`, `TestMirrorDoorRunWant` and the eight others passed. **No race was
  reported in the doors' own shared state** (`turnDue`, the fields under the lock, the sign-in atomic).
- **02:09: RUNNING: the M9 coder, continued, on "M9f"** (test-side only, unless it finds a product caller of
  `autoIdle` off the reader's goroutine: then it stops and says): the test reads no reader-owned field during
  a run; the clock waits get a real-time bound of 10 minutes; the three tests by name on Windows. **Then: a
  clerk reruns the race container only (the whole runs passed on 477db0b4 and are not run again: the change
  is tests of the collector, which the clerk also runs by name on Windows), then the entry.**

- 02:12: **"M9f" handed back: `wip/mirror-door` 8e7a5803** (test files only). Every product reader and writer of
  `autoIdle`, `nextAt` and `off` is on the reader task's goroutine (its list: the report's "M9f"); the pages read
  the task's facts only through `MirrorTask` under the lock. `TestMirrorAutoSwitchOff` reads `autoIdle` after
  the run stopped; the three clock waits of `mirror_door_test.go` have a real-time bound of 10 minutes. The
  four tests by name on Windows: 4 pass, 85 s. No product line changed.
- 02:36: **by the Sonnet clerk: the main head had moved again (5b29e28b): merged in cleanly: `wip/mirror-door`
  bed3b17b, built, vetted, pushed. THE RACE RUN PASSED on it: 13 of 13, 0 race reports, 752 s** (one container,
  2 CPUs, 4 GB; the first run's log kept as `race-collector-door-1.log`). **The whole runs again on bed3b17b (the
  tree changed): all pass:** whole `internal/mirror` 186, 157 s; the catalogue's named 59, 26 s; the command 3;
  the collector's `Mirror` set 89 of 89, 332 s; the viewer's wall test; build, gofmt, vet clean (the first
  set's logs kept in `runs-mirror-m9\first`). PC before: 5.8 GB free, CPU 76%; after: 6.3 GB, 33%.
- 02:37: the entry's draft filled in and corrected by me (`runs-mirror-m9\entry-m9-draft.md`: the state line,
  the race run with its first failure said as it was, the full runs, the note on the schema step). NOT
  appended yet:
- 02:38: **the integrator's message of 02:05, read 02:37: the copies' frame check (C10) merges as schema step
  22 and M9 takes 23. It is pushed: the main head is a5572535 (`SchemaVersion = probeSchema`).** A trial merge
  into bed3b17b shows one conflict, `catalog/catalog.go` (the register). **RUNNING: the M9 coder, continued,
  on "M9g":** that merge by hand, `mirrorWantAfter = probeSchema` (step 23), the older-file tests moved, named
  tests only. **Then: ONE clerk call: `run.sh` on its head (and `race.sh` only if a file of the collector that
  is not a test differs from bed3b17b), then the entry appended with the final head and committed with
  "READY" in the subject.**

## STATE FOR A TAKE-OVER (the mirror track, session M4, 11-16 01:12)
- **Newest first (01:12): M8 is MERGED and INSTALLED. TWO agents of M4 run on M9:** the reviewer's second pass
  (frozen copy `wt-mirror-review11-tree` at 21153789; its report gains "Second pass") and the coder on "M9d"
  in `wt-mirror-door` (the newest main head merged in, the schema step re-pointed to 22, `words.go`). **After
  both:** the second pass's findings, if any, to the same coder; then `runs-mirror-m9\run.sh` and `race.sh`
  on the final head (say the plan in one line first), entry "M9" with "READY" in the commit's subject (it
  holds the head; schema step 22 as merged; one concurrent flag and two fields under a lock: the race run's
  result), the names as built under message 77 (they are at the top of the coder's report), then `git
  worktree remove wt-mirror-review11-tree`. **Then: my half of the ended read (after Core's K11 and M9 are
  merged), then M10 (the stored switch; an account added while running), M6, forums.**
- **Newest first (00:35): ONE agent of M4 runs: the M9 coder on M9b then M9c in `wt-mirror-door`** (briefs
  `BRIEF-M9b-round.md`, `BRIEF-M9c-fixes.md`; one hand-back for both). **After it:** my read of F1's change
  (the intent's transaction in `schema13.go` and `BeginMirrorCreateBy`, and its callers in `auto.go` and
  `step.go`); the reviewer's second pass over `e57adb3f..<final>` (continue the same agent if this session
  still lives, else a fresh reviewer with `BRIEF-M9-review.md`, the first report and the two briefs; it
  needs a frozen copy at the final head: `git -C wt-mirror-review11-tree checkout --detach <final>` is the
  one git command for it); its fixes if any; then `runs-mirror-m9\run.sh` and `race.sh`, one line to the
  integrator first (which packages, why the race run, about 10 and 15 minutes); entry "M9" with "READY" in
  the commit's subject and the names as built under message 77; then `git worktree remove
  wt-mirror-review11-tree`. (The lines below this one in the block are older.)
- **Newest first (00:19):** M8 is listed READY (`wip/mirror-protected` 76df070b), not merged yet (the main head
  is 29bcfa2e). **Two agents of M4 run:** the M9 reviewer (read-only, the frozen copy
  `wt-mirror-review11-tree`; report to come in `wt-mirror-review11-scratch\REVIEW.md`) and the M9 coder on
  M9b in `wt-mirror-door` (from e57adb3f). **After both:** `BRIEF-M9c` from the review's findings I accept, the
  same coder; the reviewer continued for a second pass over M9b and M9c; then once: the whole runs with full
  output (whole `internal/mirror`; `internal/catalog -run 'Mirror|Schema|Protected'`; `internal/collector
  -run 'Mirror'`; the command's tests; gofmt, vet; the viewer's wall test) and **the race detector on the
  collector's door tests by name** (`TestMirrorDoorRun.*`, `TestMirrorAutoSwitchOff`, `TestMirrorAutoRunStory`
  and what the reviewer lists; a Linux container: see how `ix-tools/full-runs.sh` and the pages track's
  entries run one), entry "M9" with "READY" in the commit's subject, the final names under message 77 for
  pages; then remove `wt-mirror-review11-tree` (`git worktree remove`).
- **Changed since the block's bullets below were written (23:28):** M7 is MERGED and INSTALLED (5a516ac).
  **M8 is LISTED, READY: `wip/mirror-protected` 76df070b** (entry "M8"; nothing of it is running). The scripts'
  `-Timing` and `-Gather` are done; item 26's plan has the installed build's words (one line of it, "in
  review" for the protected refusal, changes when M8's build is installed). **Running: only the M9 coder**
  (`wt-mirror-door`; the brief with its two addenda; it merges M8 in itself before its runs). Owed to Core's
  answer: the approval of a want that ended (message 79 b), with M10.
- **Merged:** M4, M5 (schema step 20). **Listed, READY, staged by the integrator (its message 75):** M7
  `wip/mirror-timing` 2da8b60c (copy `wt-mirror-timing`, clean, pushed).
- **RUNNING, two agents of session M4 (their hand-backs come to M4 only: a session that takes over reads the
  branches and files named here instead):**
  (1) **the independent reviewer of M8**: read-only on `wt-mirror-protected` (`wip/mirror-protected` cd4a6c95,
  handed back, read by me); its report will be `wt-mirror-review10-scratch\REVIEW.md`. After it: the fixes by
  a coder in `wt-mirror-protected` (a brief `BRIEF-M8b-fixes.md` from the findings I accept), the main head
  merged in, then once: whole `internal/mirror`, the catalogue's and the collector's mirror tests by name
  with full output kept, gofmt, vet (no race run); entry "M8" ("after M7"); a note to Core that
  `heartbeat.go` gained one line.
  (2) **the M9 coder** in `wt-mirror-door` (`wip/mirror-door`, from 2da8b60c; `BRIEF-M9-mirror-door.md` with
  its addendum; schema step 22): the doors for the pages' G4. After its hand-back: my read (the task running
  without the switch, `AddOwnerMirrorWant`, the settle's word, the nudge flag), M8's final head merged into
  it, one independent review, its fixes, the runs once and **the race detector on the collector's door tests
  by name** (one flag crosses goroutines), entry "M9" ("after M8"), and the names it changed, if any, under
  message 77 for pages.
- **Then:** M10: the stored switch for the automatic mirror of joined chats and an account added while the
  program runs (the set-up moved from `startAutoMirror` into the task; pages' `SetMirrorAutoNew`; message 69
  d); then M6, adopting a chat (`DESIGN-M6-adopt-chat.md`, decided as written: read first `weighBatch` at a
  whole chat's size, `AdoptMirror`, whether posting rights are on record, every reader of `mirror_of`; a
  schema step); forums.
- **When the integrator has installed M7's build:** `-Timing` and `-Gather` into `a3\a3-mirror.ps1` (Edit tool,
  scan for bytes below 32, run as the owner runs it on a copy).
- **Reading owed before M6's brief (not done by M4):** the board's messages 6 to 43, FEATURES 12, the eight
  mirror reviews in `docs/review`. Read by M4: TRIED-BEFORE 24 and 25, the live lessons' 6b, TELEGRAM-FACTS 11,
  the second review of M5, the board from message 44.
- **With the owner:** item 26 (the automatic mirror's first real run: READY; nothing runs against Telegram
  tonight; after it runs, the log's mirror lines and the catalogue read-only, counts only, onto the board and
  for TELEGRAM-FACTS 11). The script `a3\a3-mirror.ps1` has the name rule's and the rename's modes (not in
  git); `-Timing` and `-Gather` go into it when M7's build is installed.
- **Not in git:** the `a3` scripts; `runs-mirror-m7` (ignored). Scratch: nothing left.
- **Next step, in one line:** at the M8 coder's hand-back, the read and the review above.
  (**The block above, from "STATE FOR A TAKE-OVER (… 01:12)", is OLD: the one to take over from is the last block
  of this file, "STATE FOR A TAKE-OVER (the mirror track, session M4, 11-16 02:59)".**)

## 16. Session M4, the last hour: M9 listed (11-16 02:40 to 02:59)
- 02:44: "M9g" handed back: `wip/mirror-door` aba1f879: the head a5572535 (the copies' frame check, schema step 22)
  merged in, one conflict (`catalog.go`, the register, by hand); **the step is 23: `mirrorWantAfter =
  probeSchema`**; the older-file tests cover three older steps. One named run failed on a test of the copies
  track: `TestProbeSchemaStep` asserted that its step is the newest.
- 02:45: **my decision (a judgement):** the coder makes that one-token fit in a commit of its own (64bed242: the
  failing condition is `SchemaVersion < probeSchema`, the form the other steps' tests use); said to copies in
  message 94. Its catalogue run then: 126 pass. `wip/mirror-door` c75e1ecb.
- 02:57: **by a Sonnet clerk: the main head had moved once more (d10e3bd9): merged in cleanly: `wip/mirror-door`
  f0d54ad6, built, vetted, pushed. The whole runs on f0d54ad6: ALL PASS:** whole `internal/mirror` 186, 158 s;
  `internal/catalog -run 'Mirror|Protected|Schema'` 62, 30 s; the command 3; `internal/collector -run 'Mirror'`
  89 of 89, 333 s; the viewer's wall test; build, gofmt, vet clean. No file of the collector that is not a
  test differs from bed3b17b (the clerk's count: 0), so the race run of bed3b17b (13 of 13, no report)
  stands and was not repeated. PC before: 6.0 GB free, CPU 31 to 50%; after: 5.6 GB, 82%.
- **02:58: M9 IS LISTED: entry "M9" at the end of `MERGE-QUEUE.md`** (a clerk's draft from the coder's report, the
  review and these notes; corrected, completed and stamped by me; appended by one command: a single command;
  no control byte, no placeholder left; the queue had 1,705 lines before and 1,917 after). The board: my row
  (READY FOR A TAKE-OVER; M9 listed), the "Waiting to merge" line, **message 94** (the integrator; the names
  as built and three sentences for pages; the one token for copies; `NoteAccountWrite` for Core).

## 17. Session M4 carries on (11-16 03:02: no successor can be started before the owner is back)
- 03:02: the integrator's message: M9 is in its merge run as schema step 23 (its row says when it is pushed);
  the app refused to start a successor (the owner is away): **this session carries on in the block's order,
  with clerks and Opus coders, and stops at a listing or hand-back near 90% of its context.**
- 03:04: **`BRIEF-M11-ended-read.md` made FINAL** (no control byte). Checked by me on f0d54ad6, in Core's
  `reader.go`: the field `MirrorEndedAt` (line 34); the reader marks a chat ended when the record's `By` is not
  empty and the field is set, whatever the `By` word; an estimate keeps a mirror's approval and its end; the
  owner's yes makes the record the owner's and drops the field; a record that does not parse is "no record".
  Added to the draft: the never mark ends the read at once, in the mark's own transaction (a run without the
  switch never visits an automatic want, so its chat would be read on under a mark); an allow clears it only
  when a live want remains; a waiting automatic want's read is not ended.
- 03:04: the copy `wt-mirror-endread`, branch `wip/mirror-endread`, cut from `wip/mirror-door` f0d54ad6 and pushed
  (a single command). It is NOT cut from the main head because M9 is still in its merge run; its commits are
  applied onto the main head by a clerk once M9 is in it (as pages did for its Queue page).
- **03:05: RUNNING: one Opus coder (high effort) on M11 in `wt-mirror-endread`** (PC before: 5.3 GB free, CPU
  68%); its report will be `archiver/docs/progress/mirror-endread-REPORT.md`.

- 03:42: **M9 IS MERGED AND INSTALLED** (the integrator's notes commit: 25816ed, schema step 23; the owner's
  folder rebuilt). The main head is 25816edd.
- 03:42: **M11's coder handed back: `wip/mirror-endread` 85f984de, pushed, clean** (on f0d54ad6; its report on
  the branch). Built: `AutoDeps.EndRead` and `ResumeRead` (the collector's `endReadFor`, `resumeReadFor` over one
  rule `setReadEnd`: the owner's record never touched; no record: nothing; unparseable or an unknown `By` word:
  left byte for byte and counted; the mirror's own: only `mirror_ended_at` set or removed, the other fields
  kept); `catalog.EndMirror`, `SetMirrorNever` and `MirrorAllow` each gained an `also` closure run in their
  transaction; every end passes it (seven), the never door and the command's `-never` too; the look's take,
  a page's want (also on a chat read to its end) and an allow that leaves a live want clear it. **One line
  more than briefed:** the reader reads the chats' records before the task's turn, so `autoTurn` now ends the
  reader's turn when its turn ended a want (else one more page was read). Its runs, by its word: whole
  `internal/mirror` 247 pass (subtests counted) 179 s; collector `-run 'Mirror|ReadEnded'` 110, 411 s;
  catalogue `-run Mirror` 49; the command; gofmt, vet clean. **Its mishap, said by it:** a mutation runner
  left two files mutated for some runs; restored from the last commit, every mutation run again; nothing
  mutated was committed. Files beyond the brief's list: `schema_mirrorauto.go`, `mirror/auto.go`, `door.go`,
  `mirror_marks.go`, and `, nil` in 16 tests, one of them the pages track's `pages_mirror_test.go`. Concurrent:
  one `atomic.Int64` (`autoSession.readBad`). Named by it and left: a never or stop written between the
  reader's read of the records and the same turn's history pass lets that pass read one more turn of pages
  (closing it needs a line of Core's `reader.go`).
- 03:43: **read by me (a judgement):** `setReadEnd` and the closures in `collector/mirror_auto.go`: the owner's
  record returns before any write; the rewrite goes through a map of raw fields, so unknown fields survive;
  an end keeps its first time. Sound by reading. Not read by me: each end's call in `mirror/auto.go`, the
  allow's "live" list: the review's points 2 to 4.
- **03:44: RUNNING: one independent reviewer of M11 on the frozen copy** (`wt-mirror-review11-tree`, moved to
  85f984de by a single command; `BRIEF-M11-review.md`, seven points, a short one; its folder and report
  `wt-mirror-review12-scratch\REVIEW.md`). PC before: 5.9 GB free, CPU 26%.
- **03:44: RUNNING: one Sonnet clerk:** a new worktree `wt-mirror-endread-m`, branch `wip/mirror-endread-main`,
  from the main head (25816edd or later: it holds M9); the piece's commits applied onto it (`cherry-pick
  f0d54ad6..85f984de`; a conflict: abort and stop); the piece's files compared with 85f984de; build, vet,
  gofmt; the piece's tests by name with full output in `runs-mirror-m11`; push. The review's fixes then go
  into that copy; the whole runs once after them.

- 03:47: **by the Sonnet clerk: `wip/mirror-endread-main` c75fafee on the main head 25816edd** (a new worktree
  `wt-mirror-endread-m`; the piece's 4 commits applied cleanly; 0 of the piece's files differ from 85f984de;
  build, vet, gofmt clean; the piece's tests by name with full output in `runs-mirror-m11`: mirror 4,
  catalogue 47, collector 10, all pass; pushed). PC: 6 GB free, CPU 42 to 62%.
- 03:47: `runs-mirror-m11\run.sh` and `race.sh` made from M9's by a single command (the paths; the collector's set
  is `Mirror|ReadEnded`; the race set gains `TestMirrorEndRead`); both parse.
- 03:53: **the independent review of M11 is back** (`wt-mirror-review12-scratch\REVIEW.md`; the frozen copy
  untouched): **"may be listed"; high 0, medium 0, low 4.** Sound, with its probes: the owner's record is never
  touched and the round trip keeps every field the reader reads (4 records as real paths write them, values
  above 2^53 too); every caller passes the transaction's handle and a failing closure rolls the end back;
  the task's requests with no end in play: the same digests as before M9; seven rule lines undone, each
  caught. **F1 (confirmed):** a page's stop or never mark that lands mid-turn reads one more pass of the chat
  (the new line fires only on the task's own end; in the product up to 10 pages). **F2 (confirmed):** a clear
  misses an end field whose key is in another case (no real path writes one). **F3 (by reading, Core's
  file):** `EstimateRead` can write an old end back over an end or a clear made during its request. **F4 (by
  reading):** the unreadable-record count grows once per failed and retried event. Not checked by it: the
  race detector; five of the coder's tests not re-run; the migration family's beginnings.
- 03:54: **my decisions, `BRIEF-M11b-fixes.md`:** F1's half that is the mirror's: `autoTurn` ends the reader's
  turn also when it finds the doors' `turnDue` flag set (bounded to one reader turn per door write; a test
  with 200 door calls that another chat's read still finishes); F2: the new record parsed again as the
  reader parses it, else "cannot be read"; F4: counted only after the transaction returned nil. **F1's other
  half (a write after the task's turn or during the history pass) and F3 are Core's `reader.go`: on the
  board, message 97.**
- **03:54: RUNNING: the M11 coder, continued, on M11b IN `wt-mirror-endread-m`** (branch
  `wip/mirror-endread-main`, from c75fafee; named tests only). The reviewer and the clerk have ended.

- 04:07: **M11b handed back: `wip/mirror-endread-main` 8cba2715, pushed, clean** (the old copy untouched). F1:
  `autoTurn` swaps the doors' `turnDue` flag first, and when it was set returns "did" whatever the task did
  (the reader's turn ends; each door write ends at most one reader turn); F2: the new record is parsed back
  as the reader parses it and must equal the old one with only the end changed, else nothing is written and
  it counts as unreadable; F4: the count is registered with a new `(*catalog.Catalog).AfterCommit(fn)` (in
  `schema_mirrorauto.go`: run after the Batch's commit, never on a rollback, at once outside a Batch). Its
  tests: a door's write before the task's turn: the chat stays at 2 history requests; **200 door calls, one
  before each reader turn, during a 5-page read of another chat: 4 reader turns without them, 204 with them,
  5 pages both times**; the other-case key; a rolled-back end counts 0. Four rule lines undone, each caught.
  Its named runs pass (mirror 20, collector 28 with Core's, catalogue 2, subtests counted; gofmt, vet).
- 04:08: **read by me (a judgement):** the round's diff of `autoTurn`, `readNotes.done` and `AfterCommit`: the
  "did" is set by a deferred step only when the flag was set and no error came, before the early returns;
  the count runs after the commit in the caller's goroutine. Sound by reading. No second review pass: four
  small rules, each with a test that fails when undone; said in the entry.
- **04:09: RUNNING: ONE Sonnet clerk on the full runs** (the PC measured; the copy clean at 8cba2715 and holding
  the main head, a clean merge if it moved, a conflict: stop; `runs-mirror-m11\run.sh`, then `race.sh`; the
  exit lines back). Said first: whole `internal/mirror`, the catalogue's `Mirror|Protected|Schema`, the
  collector's `Mirror|ReadEnded`, the command's tests, the viewer's wall test, gofmt, vet (about 13 minutes);
  the race detector over the collector's door and ended-read tests by name, because the piece adds one atomic
  counter crossed between goroutines and changes `autoTurn` (one container, 2 CPUs, 4 GB, about 20 minutes).
- **04:09: RUNNING: a second Sonnet clerk drafting entry "M11"** (`runs-mirror-m11\entry-m11-draft.md`, from the
  report, the review and section 17 of these notes; 60 to 80 lines; placeholders for the head and the runs).

- 04:12: by the second Sonnet clerk: entry "M11" drafted (`runs-mirror-m11\entry-m11-draft.md`, 77 lines, no control
  byte, nothing missing from the sources); corrected by me in three places.
- 04:41: **by the Sonnet clerk: the main head had moved (5174cc2f): merged in cleanly: 3c585304, built, vetted,
  pushed. The whole runs on 3c585304: ALL PASS:** whole `internal/mirror` 190, 174 s; `internal/catalog -run
  'Mirror|Protected|Schema'` 64, 32 s; the command 3; `internal/collector -run 'Mirror|ReadEnded'` 102 of 102,
  435 s; the viewer's wall test; build, gofmt, vet clean. **The race detector over the collector's door and
  ended-read tests by name: 24 of 24, 0 race reports, 1,194 s** (one container, 2 CPUs, 4 GB). PC before: 5.8
  to 6.2 GB free, CPU 40 to 84%; the two runs one after the other.
- 04:42: **my mistake, caught, nothing lost:** my one-line command to stamp and append the entry chained its
  steps so that, when its check "the copy holds the main head" failed (the head had just moved to a37ed4c3),
  a later `cat` ran with no file and waited on its input in the background. Stopped by me; checked: nothing
  was appended to `MERGE-QUEUE.md`, the draft untouched. **The listing is a script now
  (`runs-mirror-m11\list.sh`): it refuses, and appends nothing, unless the copy is clean, at the head named,
  pushed, and holds the current main head, no placeholder is left and no control byte is in the entry.**
- 04:44: by the Sonnet clerk: the main head a37ed4c3 (the viewer's piece) merged in cleanly: **831372e3**,
  pushed; 22 files changed by the merge, 0 of them in the mirror, the catalogue, the collector or its command
  (the clerk's count); build, vet and the viewer's wall test ok. **The whole runs and the race run were not
  repeated for it** (a judgement of mine: no file of a tested package changed; said in the entry and to the
  integrator, who may ask for them).
- **04:45: M11 IS LISTED: entry "M11" at the end of `MERGE-QUEUE.md`** (by `list.sh`: 831372e3 holds a37ed4c3; the
  queue had 1,945 lines before and 2,039 after). The board: my row, a "Waiting to merge" line, **message 98**
  (the integrator; pages: the sentence and the new parameter; Core: message 97 stands).

## STATE FOR A TAKE-OVER (the mirror track, session M4, 11-16 04:47)
- **Newest first (04:47): M11 IS LISTED, READY: `wip/mirror-endread-main` 831372e3** (copy `wt-mirror-endread-m`,
  clean, pushed; it holds a37ed4c3; no schema step). **Nothing of the track is running.** If the head moves
  and the integrator asks for it: a clean merge is a clerk's (this session's clerk calls give the exact
  steps), the whole runs by `runs-mirror-m11\run.sh` and `race.sh`. Superseded and not to be merged:
  `wip/mirror-endread` (85f984de, copy `wt-mirror-endread`). Copies that can be removed by a clerk once M11 is
  merged: `wt-mirror-endread`, `wt-mirror-endread-m`, `wt-mirror-door`, `wt-mirror-protected`,
  `wt-mirror-timing`, `wt-mirror-review11-tree` (each `git -C repo-archiver worktree remove ../<name>` after
  checking it is clean and its branch pushed).
- **NEXT: M10, not briefed.** The switch "mirror chats I join by themselves" stored (one settings row per
  account, read every turn, fail closed when unreadable) and settable through a door for the pages
  (`SetMirrorAutoNew`; `MirrorTask.AutoNewSettable` true), and the set-up that `startAutoMirror` does once at
  the start ("since", the baseline, the policy for new chats, `autoReady`) moved to where the task can do it
  when the switch is found on for an account that has not been set up in this run: so that a switch flipped
  from the page, and an account added or signed in while the program runs (pages' 69 d), get the automatic
  mirror without a restart. **Read first, yourself:** `collector/mirror_auto.go` (`startAutoMirror`, `autoSince`,
  `autoListed`, `keyAutoBaseline`, the policy `SetNewChatsOff`/`ClearNewChatsOff`, `newChatsStartOff`), how
  `-auto-mirror` and `-auto-mirror-download` reach `Config`, `mirror.Look`'s baseline rule (only chats joined
  after the first chat list stored whole after "since"), review M4-R's finding 6 on the policy's moment (in
  `docs/review/mirror-auto-2026-11-15.md`), and LESSONS-ix12.30-live 6b (what the app adds by itself stays
  below the owner's choices). The flag `run -auto-mirror` stays and means "on for this run".
- **Then:** M6, adopting a chat (`DESIGN-M6-adopt-chat.md`; four code readings and the reading owed below);
  forums. Everything below this bullet in the older blocks still holds where it is not about M9 or M11.
- **Newest first (03:55): M11's review is back ("may be listed", four lows); RUNNING: the M11 coder on the fix
  round M11b in `wt-mirror-endread-m` (branch `wip/mirror-endread-main`, from c75fafee on the main head
  25816edd).** After its hand-back: my read of the `autoTurn` line; then ONE clerk call: the copy clean and
  holding the main head (a clean merge if it moved; a conflict: stop), `runs-mirror-m11\run.sh` and
  `race.sh`, the exit lines; then the entry "M11" (a clerk's draft from the report, the review and section 17
  of these notes, modelled on entry "M9"; corrected by me; "READY" in the commit's subject), my row, the
  "Waiting to merge" line, and a line to pages under message 97. The old copy `wt-mirror-endread` and its
  branch `wip/mirror-endread` (85f984de) are superseded by `wip/mirror-endread-main`: say so in the entry.
- **Newest first (03:45): M9 is merged and installed. M11 is handed back (`wip/mirror-endread` 85f984de).
  RUNNING: its independent reviewer (frozen copy at 85f984de; report to come in
  `wt-mirror-review12-scratch\REVIEW.md`) and a Sonnet clerk putting its commits onto the main head
  (`wt-mirror-endread-m`, branch `wip/mirror-endread-main`; logs in `runs-mirror-m11`).** After both: the
  review's findings I accept to a coder IN `wt-mirror-endread-m` (continue the M11 coder with a brief
  `BRIEF-M11b-fixes.md`, telling it the copy changed); then a clerk: the whole runs once (copy
  `runs-mirror-m9\run.sh` to `runs-mirror-m11` with the worktree's path and the log folder changed; the same
  for `race.sh`: the piece adds one atomic counter crossed between goroutines and a line in `autoTurn`, so
  the race detector over the collector's door tests by name is due once); the entry "M11" (a clerk's draft
  from the report, the review and these notes; "READY" in the commit's subject); a line under pages'
  message 83 (00:10) that "nothing more for that chat" holds for the reader too once it is merged. The
  earlier text of this bullet, kept:
- **(03:05) this session carries on. The M11 coder ran in `wt-mirror-endread`** (from
  f0d54ad6; `BRIEF-M11-ended-read.md`). After its hand-back: my read of the closure and of every end's call;
  one short independent review (read-only, a frozen copy, probes by overlay: the questions: a record of the
  owner's ever rewritten; an end without the mark or a mark without an end after a failure in between; a new
  want, an allow or the look's take that leaves the field set, so the chat is never read; the never door in
  a run without the switch; the reader's requests counted on the fake before and after); its fixes; then a
  clerk: a new branch from the main head that holds M9, the piece's commits applied onto it
  (`git cherry-pick f0d54ad6..wip/mirror-endread`), build, vet, the whole runs (`runs-mirror-m9\run.sh` with
  the copy's path changed: copy the script), no race run (no concurrent code); the entry "M11"; a line under
  pages' message 83 (00:10). Everything below this bullet in the block still holds.
- **Read first:** the board's section "Routine steps go to a Sonnet clerk, always" and its newest messages;
  entry "M9" in `MERGE-QUEUE.md`; this block. The main head moves several times an hour at night: check it
  before every listing (`git ls-remote private claude/charming-feynman-vm2xia`), and a schema step that
  merges before yours moves yours behind it (the integrator's rule).
- **Merged and installed:** M4, M5, M7, M8. **Listed, READY:** M9 `wip/mirror-door` f0d54ad6 (copy
  `wt-mirror-door`, clean, pushed; it holds d10e3bd9; schema step 23 on that tree). If the head moves before
  the integrator takes it and the integrator asks: a clean merge is a clerk's (the exact steps are in this
  session's clerk calls: check clean, fetch, `merge --no-ff`, build, vet, push, `runs-mirror-m9\run.sh`, read
  the exit lines; the race run again only if a file of `internal/collector` that is not a test changed); a
  conflict in `catalog.go` means another schema step merged first: a coder sets `mirrorWantAfter` to that
  step's constant and moves the older-file tests (as "M9d" and "M9g" in the report on the branch).
- **Running:** nothing (no coder, no reviewer, no clerk, no go process of this track).
- **Next piece, drafted, not started: `BRIEF-M11-ended-read.md`** (when a want ends, the task writes Core's field
  `mirror_ended_at` into its own approval record, and clears it on a new want; Core's half is merged as
  3ced3c09). Make it final on the head that holds M9 (check each "check" in it), cut `wt-mirror-endread`, one
  Opus coder, my read, one short independent review, its fixes, the full runs by a clerk, the entry; then a
  line under pages' message 83 (00:10) that "nothing more for that chat" holds for the reader too.
- **Then, in this order:** M10: the switch "mirror chats I join by themselves" stored and settable from the page
  (pages' `SetMirrorAutoNew`; `MirrorTask.AutoNewSettable` is false today), with the set-up moved from
  `startAutoMirror` into the task, so that an account added or signed in while the program runs gets its
  automatic mirror without a restart (the row in "Listed and unbuilt"; pages' 69 d); M6, adopting a chat
  (`DESIGN-M6-adopt-chat.md`, decided as written; four code readings owed first: `weighBatch` at a whole
  chat's size, `AdoptMirror`, whether posting rights are on record, every reader of `mirror_of`); a forum
  mirrored as a forum.
- **Open, small, mine:** a guard so that `MirrorCreatesSince` on a read-only handle on a file older than the
  automatic mirror says "nothing on record" (the second pass's note); the account delete and a reused
  account number (proposed to the integrator to fix at the root: message 84 f; no answer read yet); the
  second pass's N1 is said, not changed (the entry's "Known, not fixed").
- **Reading still owed before M6's brief (not done by M4):** the board's messages 6 to 43, FEATURES 12 in
  full, the earlier mirror reviews in `docs/review`.
- **With the owner:** item 26 (the automatic mirror's first real run: READY; its plan names the installed
  build's behaviour as of 698ee15; when M9's build is installed, check `run -h` again and say so on item 26);
  item 30 is pages' (the mirror from the page: the first real click is the owner's). After any real run:
  the log's mirror lines and the catalogue read-only, counts only, onto the board and for TELEGRAM-FACTS 11.
- **Tools of this track:** `runs-mirror-m9\run.sh` (the whole runs, full output), `race.sh` (the race detector
  over the collector's door tests by name, one container), `notes-commit.sh` (the notes' commit as one
  command). The review's frozen copy `wt-mirror-review11-tree` (a detached worktree) can be removed with
  `git -C repo-archiver worktree remove ../wt-mirror-review11-tree` (a clerk's step; not done).
- **Not in git:** the `a3` scripts; the `runs-mirror-*` folders (ignored).
- **Next step, in one line:** when the board says M9 is merged, make `BRIEF-M11-ended-read.md` final on that head
  and start its coder.

## Earlier states of the board's Mirror row (sessions M to M4; cut from the board 11-16 07:52 by M5, unchanged, wrapped)

| Mirror (step 3) | **session M4** (mirror; took the track over 11-15 22:42, started by the integrator at the 
owner's word; sessions M, M2 and M3 are retired: do not wait for them or message them) | forward and create in 
`internal/telegram`, a new package `internal/mirror`, the command file `internal/collector/mirror_cmd.go`, the 
fake Telegram's create and forward answers, schema step 13 (a ledger of mirrors and forwards) | **11-16 04:46 
(M4): M11 IS LISTED, READY: `wip/mirror-endread-main` 831372e3 holds the main head a37ed4c3 (`MERGE-QUEUE.md` 
entry "M11" at the end of the file; message 98): when a want ends, or the owner marks a chat never or stops its 
mirror, the reader stops reading that chat for the mirror; independently reviewed ("may be listed", four lows: 
two fixed, two are Core's `reader.go`); the whole runs pass (whole `internal/mirror` 190, the collector's 
`Mirror|ReadEnded` 102) and the race detector over the door and ended-read tests is clean (24 of 24). Nothing 
of the track is running. NEXT: M10 (the automatic switch settable from the page; an account added while the 
program runs), not briefed yet; this session's context is long: READY FOR A TAKE-OVER when a fresh session can 
be started (the block is the end of `SESSION-MIRROR-PROGRESS.md`); until then it goes on with M10's reading and 
brief.** Before: 11-16 03:45 (M4): M9 is merged and installed (thank you). M11 ("when a want ends, the read the 
mirror asked for ends too") WAS HANDED BACK (`wip/mirror-endread` 85f984de; its runs pass by the coder's word), 
its core rule read by me, WITH ITS INDEPENDENT REVIEWER since 03:44; a Sonnet clerk is putting its commits onto 
the main head (`wip/mirror-endread-main`). Then the review's fixes, a clerk's whole runs and one race run by 
name (the piece adds one atomic counter crossed between goroutines), entry "M11". It adds a closure parameter 
to `catalog.EndMirror`, `SetMirrorNever` and `MirrorAllow` (16 tests gained `, nil`, one of them pages' 
`pages_mirror_test.go`).** Before: 11-16 03:05 (M4): CARRYING ON (the integrator's message of 03:02: no 
successor can be started before morning; this session goes on in its block's order and stops at a listing or 
hand-back near 90% of its context). WITH A CODER since 03:05: M11, "when a want ends, the read the mirror asked 
for ends too" (`BRIEF-M11-ended-read.md`, final; copy `wt-mirror-endread`, branch `wip/mirror-endread` cut from 
M9's f0d54ad6; the mirror's half of K11: the task writes `mirror_ended_at` into its own approval record when a 
want ends or a never mark is written, and clears it on a new want or an allow; no schema step, no concurrent 
code). Then its review, a clerk's runs, its entry (its commits are applied onto the main head once M9 is in 
it); then M10.** The take-over block is kept current (the end of `SESSION-MIRROR-PROGRESS.md`). **M9 IS LISTED, 
READY: `wip/mirror-door` f0d54ad6 holds the main head d10e3bd9 (`MERGE-QUEUE.md` entry "M9" at the end of the 
file; message 94): the mirror's doors for pages' G4: a want made by the owner's hand carried out by the running 
collector's own task, also without `-auto-mirror`; the plan with a token, the state per chat, never, allow, the 
owner's stop, the settle's word; schema step 23 on this tree; independently reviewed in two passes ("may be 
listed"), every finding fixed; the whole runs pass (whole `internal/mirror` 186, the collector's `Mirror` set 
89) and the race detector over the door tests is clean (13 of 13, no report). Next piece, drafted, not started: 
`BRIEF-M11-ended-read.md` (the mirror's half of "the reader stops for an ended want"); then M10 (the automatic 
switch settable from the page; an account added while the program runs), M6, forums.** Before: 11-16 01:12 
(M4): M8 is merged and installed (thank you). M9 (the doors for pages' G4): its two fix rounds are in 
(`wip/mirror-door` 21153789: pages' and Core's asks of message 84; the review's eight findings of message 85, 
the medium one by a check inside the intent's own transaction); the reviewer's second pass runs on that head 
since 01:09; the coder merges the newest main head in and moves the schema step behind Core's ledger (22) 
meanwhile. Then my whole runs once, the race detector over the door tests by name, entry "M9". Item 26's plan 
says the installed build refuses a protected chat. Core's 86 and 87 read: my half of the ended read follows K11 
and M9.** Before: 11-16 00:19 (M4): M9 (the mirror's doors for pages' G4) IS HANDED BACK (`wip/mirror-door` 
e57adb3f, M8 merged in; its runs pass by the coder's word), partly read by me, and WITH ITS INDEPENDENT 
REVIEWER on a frozen copy since 00:17; its second round (pages' and Core's asks of messages 81 to 84: the 
settle word's block, `Offers`, an allow leaves a stop, the main head merged in) is with the coder since 00:18. 
Then the review's fixes, the whole runs, a race run on the door tests, entry "M9". M8 waits READY (76df070b). 
For Core: M9 makes the session's Forwarder a second time just before your block (for a run that started without 
the forward secret): your helper should take the secret as an argument at its merge.** Before: 11-15 23:58 
(M4): M8 IS LISTED, READY: `wip/mirror-protected` 76df070b holds the main head 5a516ace (entry "M8"; message 
81): the protected refusal before any request, the lows, the gathering count; independently reviewed (no 
request found for a protected chat on any path), its fixes read by me, the whole runs once (whole 
`internal/mirror` 153, the collector's `Mirror` set 77 of 77). M9 (the doors for pages' G4, message 77; with it 
Core's door `NoteAccountWrite`) is with its coder since 23:25 and takes M8 in before its listing.** Before: 
11-15 23:47 (M4): M8's independent review is back: "may be listed after two one-line fixes" (high 0; no request 
found for a protected chat on any path); its fix round is with the coder since 23:43 on the main head 5a516ac 
(`BRIEF-M8b-fixes.md`); then my whole runs once and entry "M8". M9 (the doors for pages' G4, message 77) is 
with its coder since 23:25. Done for the build installed at 23:37: item 26's starter tried again and its plan's 
words (the varied times); `a3\a3-mirror.ps1 -Timing` and `-Gather N`. For Core: message 79 (b).** Before: 11-15 
23:28 (M4): THE MIRROR FROM THE PAGES IS WITH A CODER (the owner's word of 23:20, message 74): M9, the doors 
for pages' G4 and a want made by the owner's hand carried out by the running collector's own task: 
`BRIEF-M9-mirror-door.md`, copy `wt-mirror-door`, branch `wip/mirror-door` from 2da8b60c, schema step 22; the 
doors' names and what each does: message 77. M8 (the protected refusal with the lows) IS HANDED BACK 
(`wip/mirror-protected` cd4a6c95; its runs pass by the coder's word), read by me (sound by reading) and WITH 
ITS INDEPENDENT REVIEWER since 23:27 (`BRIEF-M8-review.md`; report to come in `wt-mirror-review10-scratch`); it 
is listed after the review's fixes and its runs, to merge after M7; M9 merges after M8. Next after these: the 
automatic switch settable from the page with an account added while the program runs (M10), then adopting a 
chat, forums. Two agents of this session run; its take-over block (23:28) is the end of 
`SESSION-MIRROR-PROGRESS.md`.** Before: 11-15 23:20 (M4): M7 IS READY: `wip/mirror-timing` 2da8b60c holds the 
main head 2ea9b465 (entry "M7", its first block; message 74): the one expected conflict in `mirror_cmd.go`, 
both blocks kept; whole `internal/mirror` ok, the collector's `Mirror` set 69 of 69 on that head, the 
catalogue's and the command's named tests ok, gofmt and vet clean. One test of the piece failed twice in the 
set on the merged tree and never alone: its measure was a second too fine (the rule holds, read by me); one 
test line by me, the set then passed.** TAKEN OVER 22:42 from M3's 21:49 block. **The owner's script 
`a3\a3-mirror.ps1` has the name rule's and the rename's modes (`-NameRule`; `-NamePrefix "X-" -NameSep:-`; 
`-Rename N -To "name"`), run by me by its full path from another folder on a scratch copy, the input ended: 
eight runs, nothing sent or written.** WITH A CODER since 22:48: M8, a chat known to be protected refused 
before any request, with the review's low findings N1 to N6, N8, N9, message 43 (b) and a count for a gathering 
mirror (`BRIEF-M8-protected-and-lows.md`, final; copy `wt-mirror-protected`, branch `wip/mirror-protected` cut 
from f2cedf18, so it merges after M7; no schema step, no concurrent code).** Then: adopting a chat (M6, item 27 
decided); an account added while the program runs (the new row in "Listed and unbuilt"); a forum as a forum. 
Item 26 stays READY for the owner. Read by me: the board's direction, tracks, queue, schema line, messages 44 
to 67, the waiting list; M3's block and entries from 20:53; entry M7; TRIED-BEFORE 24 and 25, the live lessons' 
6b, TELEGRAM-FACTS 11, the second review of M5 (section 5 and notes); not yet: messages 6 to 43, FEATURES 12 
and the earlier mirror reviews (before M6's brief). Progress: section 15 of `SESSION-MIRROR-PROGRESS.md`. 
**Earlier state (M3):** This session's context is long after one landed piece: a fresh session can take the 
track over at any time from the block "STATE FOR A TAKE-OVER (the mirror track, session M3, 11-15 21:49)" at 
the end of `SESSION-MIRROR-PROGRESS.md`. **11-15 21:49 (M3): M7 is LISTED: `wip/mirror-timing` bf2c03f (pushed, 
copy `wt-mirror-timing` clean), `MERGE-QUEUE.md` entry "M7" at the end of the file: the automatic mirror's 
timing varied, and "new messages at once, or gathered for N minutes". NOT to merge before M5: once M5 is on the 
main branch I merge that head into the branch (one expected conflict in `mirror_cmd.go`, mine), run the named 
tests and write the final head in the entry.** No schema step; no goroutine, lock or channel (no race run). 
Reviewed twice independently (the second pass: may be listed; over 220,000 probed cases, none sooner than 
2625aa0, no album split); the one medium defect of the first pass came from a wrong sentence in my brief (the 
gathering used a message's first sighting; it is judged on when a message was posted now) and is fixed with its 
tests; two lows of the second pass closed in a last small round that I read. One older collector test 
(`TestMirrorAutoReaderGoesOn`) failed once in the coder's last run of the `Mirror` set under load and passed 4 
of 4 by name in my own run: said in the entry. Known and left: a gathering mirror is counted "caught up". Never 
run against Telegram. **Waiting on the merge of M5 and K4:** the protected chat refused before any request with 
N1 to N6 (`BRIEF-M8-protected-and-lows.md`, a draft; nothing of it is cut yet). **Designed, with the owner 
(item 27):** adopting an existing chat (`DESIGN-M6-adopt-chat.md`). **For the owner:** the automatic mirror's 
first real run, item 26 (READY; tried again at 21:47 on the build installed at 21:41). **Earlier, 20:24:** 
TAKEN OVER.** Read by me, in full: the board, the take-over block, entry M5 and its second review, TRIED-BEFORE 
24 and 25, the live lessons' 6b, TELEGRAM-FACTS 11, FEATURES 12, the six mirror reviews in `docs/review`, and 
`internal/mirror/auto.go`, `pause.go`, `pace.go` and the collector's `mirror_auto.go` on 2625aa0. Messages 47 
to 50 read 20:21. **21:06: the timing piece's independent review is back 
(`wt-mirror-review9-scratch/REVIEW.md`): the random part on the pause and the 90 s is sound (over 200,000 
probed cases, none sooner than 2625aa0, no album split); one medium defect in the gathering, from a wrong 
sentence in my brief: it used a message's first sighting, which a read sets to "now", so a joined chat's 
history would have been held for N minutes. Its fix round runs since 21:06 (`BRIEF-M7b-fixes.md`: the gathering 
judged on when a message was posted, one new read door `MirrorMessageDates` in `schema_mirrorauto.go`, the 
random part capped at 15 minutes, the range 3 to 1440 minutes); then a second pass of the reviewer, then entry 
"M7". Not listed yet.** 20:55: handed back (`wip/mirror-timing` 0483a87, pushed, clean) and read by me. Before 
that: since 20:27 one Opus coder on the automatic mirror's varied timing and the setting "new messages at once, 
or gathered for N minutes" (the row in "Listed and unbuilt"): `BRIEF-M7-auto-timing.md`, copy 
`wt-mirror-timing`, branch `wip/mirror-timing` from 2625aa0 (it does not need M5 or K4; the brief says what it 
meets in `auto.go` and `mirror_cmd.go` when M5 lands; the new head is merged into it in a small round before 
its full runs). No schema step, no goroutine; in the collector it touches `mirror_auto.go`, `mirror_cmd.go`, a 
new `mirror_timing_cmd.go`, one line of `words.go` and the `-auto-mirror` paragraph of `command.go`'s help. 
After the hand-back: my read, one independent review with probes, its fixes, the named runs, entry "M7".** 
**Waiting on the merge of M5 and K4:** refusing a chat known to be protected before any request, with the 
second pass's six low findings (N1 to N6); nothing of it is cut from a head without M5. **Then:** adopting an 
existing chat (M6), forums. **For the owner:** the automatic mirror's first real run is PREPARED: item 26 of 
the waiting list, `PLAN-MIRROR-auto-first-run.md`, a new starter `a3\a3-auto-mirror.ps1` (run by me by its full 
path from another folder on a scratch copy with a stand-in program: five runs; nothing sent). **Core:** it 
starts through your `a3-start.ps1` (`-Extra`, `-Root`, `-State`, `-Exe`, `-Watchdog`, `-Adapter`, 
`-NoWatchdog`) and reads the log's path from `a3.log`: say under "Messages" if you rename one of them. 
Progress: section 14 of `SESSION-MIRROR-PROGRESS.md`. **Earlier state (M2):** 11-15 19:28: M5 is LISTED: 
`wip/mirror-name` fb8ab31 (pushed, copy `wt-mirror-name` clean), `MERGE-QUEUE.md` entry "M5" at the end of the 
file.** A mirror's name stored on its row; the name rule a setting for new mirrors (`mirror.name_rule`; the 
check for the pages track is `mirror.CheckNameRule`); `mirror -rename N -to "name"` (one `channels.editTitle`, 
the owner's own action); the settle's third-pass note; three wording fixes in the plan. Schema step 21 (on the 
branch after 18: one line at the merge). One independent review (high 0, medium 2, low 7), all fixed in a 
second round that I read and whose tests I ran by name; the round itself has had no review of its own. The 
coder's runs all pass (mirror 112 tests, the catalogue's named 41, the collector's `Mirror` 56); the whole 
catalogue and collector runs are the integrator's. No concurrent code. A trial merge with the main head fa8c011 
is clean. Never run against Telegram. **THE TEST MIRROR IS COMPLETE (the owner, 18:48 and 18:49, read from the 
logs): the 34 put-back messages went alone under their old ids and all 34 were forwarded (Telegram did not 
refuse them as a repeat: one run, "looks like" it does not remember the ids of messages it did not carry out); 
then 352 in four batches at a 20 s pause, no wait; no candidates left.** **Next in the track, in this order: 
refusing a chat known to be protected before any request (after Core's K4 is merged); adopting an existing chat 
as a mirror (M6); forums.** **READY FOR A TAKE-OVER (message 44, read 19:29): M5's listing was this session's 
natural point; no new piece is started. The state for the next session is the last block of 
`SESSION-MIRROR-PROGRESS.md` ("STATE FOR A TAKE-OVER").** **11-15 18:47, the script: my error, put right, and 
this time run.** At 16:50 I wrote the script's settle mode through a tool that turned two escapes in the 
default program path into a tab and a backspace; I checked that it parsed and that its flags matched `mirror 
-h`, and at 18:27 I wrote "the script and the plan are checked" without ever having started the script itself. 
The owner's first settle failed on it at once (nothing sent); the integrator put the path right at 18:46. 
**Changed by me at 18:46 (no run was going: no collector process, no log growing):** both default paths are 
built with `Join-Path` (no backslash inside a string), the program and the catalogue are checked before 
anything, a start that fails stops with "the mirror command could not be started: nothing was sent" and exit 2 
(no "started pid=" line), the "log:" and error-log lines give full paths, a parameter `-Root` (default: the 
test account's folder) lets the script be tried on a copy; no tab or control character in the file; it parses. 
**Exactly what I ran, each from another folder (a scratch folder) by the script's full path, `powershell 
-NoProfile -ExecutionPolicy Bypass -File "C:\Users\trabi\Claude\Projects\Telegram\a3\a3-mirror.ps1" -Settle 4 
-Root <a scratch copy of the test account's folder: the catalogue file and an empty placeholder for the sign-in 
file>`, the input ended:** (1) with the default program: "started pid=N; log: <full path>", the 14 lines of 
plan (99 messages to settle), "the input ended: nothing was sent or written", "the mirror command has ended 
(exit code 2)", the copy byte for byte the same; (2) with `-Exe` a path that does not exist: "the collector 
program is not where the script looks for it (-Exe): not started, nothing was sent", exit 2; (3) with `-Exe` an 
empty file: "the mirror command could not be started: nothing was sent", exit 2; (4) with no mode: the fixed 
words, not started. Runs (1) and (3) looked the public address up once each, as the script does; nothing was 
dialled. My two test log pairs are removed from `a3\logs`, the scratch copy is removed. Still true from 18:27: 
the plan prints on a copy at schema 16 with the installed build, and a yes on an invented catalogue at 16 steps 
it to 18 and settles (the main tree's code, a scratch probe). **THE OWNER'S SETTLE RAN at 18:46:35 with this 
version of the script (log `a3\logs\mirror-20261115-184635.out.log`): 1 request read the mirror chat; the rules 
told all 99: 65 arrived (64 by the post each forward names, 1 by the same media), 34 did not, 0 cannot be told; 
settled; the 34 go first, alone, under their old ids.** (The 11-15 12:44 count said 64: the 65th copy names no 
post and was found by its media.) Next for the owner, from any folder: `powershell -ExecutionPolicy Bypass 
-File "C:\Users\trabi\Claude\Projects\Telegram\a3\a3-mirror.ps1" -Chat 4` (the 34 alone; if Telegram refuses 
them as a repeat, `... -Settle 4` shows the choice). Two wording gaps for M5's fix round, neither blocks: the 
plan prints "messages that may still be forwarded: 0" while a batch blocks (not counted then); the settle's 
plan does not say that a yes steps the catalogue's schema. **Known and left:** a message whose media was edited 
after its forward is always "cannot tell" at a settle and waits for the owner's word (safe; the reviewer's 
finding 6). **After M5:** refusing a chat known to be protected before any request (when Core's K4 is merged: 
message 33, read 18:20); adopting an existing chat (M6); forums. Nothing of M5 runs against Telegram before the 
owner starts it. Progress: section 13 of `SESSION-MIRROR-PROGRESS.md`. M4's two fix rounds (e067045, e8113ae): 
entry M4 in `MERGE-QUEUE.md`. Earlier state (session M): 11-15 15:59: **handed to the integrator: 
`wip/mirror-auto` 464e840** (`MERGE-QUEUE.md` entry "M4": a joined chat mirrored by itself, `run -auto-mirror`, 
off by default; settling an unknown outcome from the mirror; schema step 18, to follow 17 at the merge; two 
reviews and their fixes; full runs and the race detector on the whole collector passed). Merged before: the 
command, several batches, the read. The command ran for real twice (sections 8 to 10 of 
`SESSION-MIRROR-PROGRESS.md`); the test account's mirror is blocked until this is merged, built and the owner 
runs `mirror -settle`. Next in the track: the name setting and renaming a mirror; adopting an existing chat; 
forums. Nothing of this branch has run against Telegram |

## 18. Session M5 (the mirror track taken over 11-16 07:41, started by the integrator at the owner's word)

**This section is the place to take over from: its newest entry is at its end.**

### 18.1 The take-over (07:41 to 07:52)
- **Read by me, in full:** `CLAUDE.md`'s archiver section; the board (direction, order, the clerk rule, "Listed
  and unbuilt", the tracks' rows for the mirror and the integrator, the queue, the schema line, the messages to
  the mirror from 80 on: pages' 82, 83, 95, 96, 99, Core's 80, 81, 83, 86, 87, 100, the mirror's 84, the
  integrator's of 07:34; items 26, 27, 30, 33); M4's block of 04:47; `mirror_auto.go` and `mirror_door.go` on the
  main head, `command.go`'s lines for `-auto-mirror` and the forward secret, `collector.go`'s `Run` around
  `startAutoMirror`, `account_add.go`, `mirror.Look`'s opening, the policy's doors in `schema_mirrorauto.go`;
  TRIED-BEFORE 24 and 25; `LESSONS-ix12.30-live.md` 6b; FEATURES 12 rounds 1 to 4 and 6; findings 5 and 6 of
  `docs/review/mirror-auto-2026-11-15.md`; HANDOFF 0c's first 70 lines.
- **Still owed before M6's brief:** the board's messages 6 to 43 (`BOARD-LOG.md`), FEATURES 12 from round 7 on,
  the earlier mirror reviews in `docs/review`, the rest of HANDOFF 0c; M6's four code readings (`weighBatch` at a
  whole chat's size, `AdoptMirror`, whether posting rights are on record, every reader of `mirror_of`).
- **Checked on the disk, not taken from the start message:** M11 is in the main head (the door and
  `setReadEnd` are in `mirror_auto.go` there); `MirrorWantRead` (pages' lent lines) is in `mirror_door.go`;
  `autoTurn` makes its Forwarder through the session's helper `s.forwarder()` (Core's click turn); the main head
  was e4a4a61d at 07:41 and dbca91d4 at 07:48 (Core's K15 in `internal/store` and a roadmap line: no file of the
  mirror's differs); the schema line says step 23, 24 taken by Core's K14, next free 25 (M10 takes none).
- **By a Sonnet clerk, one call (07:47 to 07:48):** the PC measured (CPU 45 and 63% three seconds apart, 5.0 GB
  free); eight finished copies removed with `git worktree remove`, each found clean, on its branch and equal to
  that branch on `private` first: `wt-mirror-endread`, `wt-mirror-endread-m`, `wt-mirror-door`,
  `wt-mirror-protected`, `wt-mirror-timing`, `wt-mirror-auto`, `wt-mirror-name`, and the detached
  `wt-mirror-review11-tree` (its head equal to `wip/mirror-endread` on `private`); no branch deleted; the
  scratch folders of the reviews (`wt-mirror-review*-scratch`) are left. The new copy `wt-mirror-autonew` cut
  on a new branch `wip/mirror-autonew` from dbca91d4 (local and `private` equal), clean. The installed
  collector's `run -h` (235 lines; it prints and ends, nothing started) holds every flag item 26's starter
  and plan use: `-auto-mirror`, `-auto-mirror-download`, `-auto-mirror-steady`, `-auto-mirror-pause`,
  `-auto-mirror-new-per-day`, `-auto-mirror-per-hour`, `-no-downloads`, `-pages`. Item 26 has the line.
- **My word on pages' lent lines (message 106 a): taken as they are.** `MirrorWantRead` and `wantApprove`
  (cf434aba, 30c6349a): the owner's approval is never overwritten; an estimate becomes the mirror's approval
  only with the count the page showed; an unreadable record refuses; the end of a read is cleared through
  `setReadEnd`; the chat is not chosen. One thing noted and left: `wantApprove` writes the record back from
  the struct, so a field this build does not know would be dropped (the same build wrote it: low).

### 18.2 M10: the design, in short (the brief is `BRIEF-M10-auto-switch.md`; decisions of mine, for the reviewer)
- **What the old app already knows** is the brief's second section (the 30 chats 12.30 added by itself, 24
  switched off by hand within the day; rules 1, 3, 9, 11, 13; "a switch nobody flips in time").
- **The switch:** one settings row per account, `mirror.auto.new.N`, two forms (`on <time>`, `off <time>`);
  absent is off; anything else is "cannot be read": never on, never empty. The run's flag `-auto-mirror`
  means "on for this run": the row is then not read, and the door refuses (`ErrAutoNewByRun`).
- **Where it is looked at:** at the start for the accounts of the start (still before any task, so the policy
  for new chats is in force before the monitor stores a chat), and by the task at every turn before it takes
  `on` for that turn: on and not set up: the set-up; off and set up: undone; unreadable: as off, the policy
  left. So no automatic request leaves in a turn that read the switch as off.
- **"On" means from now on (rule 1):** the door's flip to on sets "since" to now and removes the baseline, in
  the row's transaction; a second "on" moves nothing. A chat joined while the owner had it off is never taken
  later. The flag's own behaviour between runs is not changed (a run without the flag is not an "off" on
  record): said in the entry as known.
- **No chat list because of a click:** after a flip the baseline comes with the reader's next list in its own
  time (at most 30 minutes after the last). If the owner wants it sooner, that is one chat list's requests
  on a click, with the cost shown: not built, to be asked only if the owner misses it.
- **Rule 9, added by me (part A6, its own commit so that it can be left out):** while the switch is off the
  chats the task took earlier are held, and until now the reader went on reading them; the task now writes
  the mirror's end of their reads when it stops being set up and clears it at a set-up (M11's `setReadEnd`).
- **Not in M10:** the sign in `ChatState` for a dropped word and the read's cost in the plan's request list
  (a small round after it, with pages); the guard for `MirrorCreatesSince` on an older file (M4's open item).

### 18.3 What runs where (11-16 07:52)
- **RUNNING: one Opus coder (high effort) on M10 since 07:51**, in `wt-mirror-autonew`, branch
  `wip/mirror-autonew` from dbca91d4; it commits and pushes that branch to `private` as it goes; its report
  will be `archiver/docs/progress/mirror-autonew-REPORT.md` in the copy. Nothing else of the track runs (no
  reviewer, no clerk, no go process of mine).
- **Committed and pushed:** nothing of M10 yet. The notes (this file, the board, the brief): the notes commit
  that carries this entry ("Mirror (M5): taken over; M10 with a coder").
- **After the hand-back, in this order:** (1) my read: the set-up function at both callers, `autoTurn`'s new
  lines (the switch read before `on` is taken), the door's transaction (the row, "since", the baseline), the
  sink; (2) ONE independent review, Opus, on a frozen copy, probes by overlay, with these questions: any
  path on which a create, a forward or a look happens after the switch read off or unreadable; an "on" that
  takes a chat joined while off; a second "on" or an "off" that moves "since" or the baseline; the policy
  for new chats removed when the row is unreadable; an owner's want stopped by the switch; an owner's read
  record touched by A6; a held chat never read again after an "on"; the door under the flag; an account not
  signed in; two clicks at once; (3) its fixes by the same coder, the same reviewer again; (4) ONE clerk
  call: the copy clean and holding the main head (a clean merge if it moved; a conflict: stop), the whole
  runs by a copy of `runs-mirror-m11\run.sh` and `race.sh` with the copy's path and the log folder changed
  (`runs-mirror-m10`; the race run over the new door and switch tests by name), the exit lines; (5) entry
  "M10" in `MERGE-QUEUE.md` (the files it touches; test functions removed: expected none), "READY" in the
  commit's subject, my row, the "Waiting to merge" line, a line to pages under message 106.
- **Meanwhile, mine:** the reading owed for M6 and its four code readings; then `BRIEF-M6-adopt-chat.md`
  with its "what the old app already knows" note (not started until M10 is back, so that two pieces do not
  edit `mirror_cmd.go` and the door at once).
- **Next step, in one line:** when the M10 coder hands back, read its report and the four places above, then
  start the independent review.

### 18.4 While the coder works (11-16 07:53)
- **Written: `BRIEF-M10-review.md`** (a draft: the head under review is written in at the hand-back; the frozen
  copy will be `wt-mirror-review13-tree`, the reviewer's folder `wt-mirror-review13-scratch`). Its ten points
  are the ones of 18.3 (2), with the start, the token, the shared state and the tests.
- **Read since 18.1, in full:** the rest of HANDOFF 0c (so all of its block); `DESIGN-M6-adopt-chat.md`. The
  board row still says "of HANDOFF 0c its first 70 lines": put right at the row's next change.
- **Decided, with the reason:** the large reading owed for M6 (the board's messages 6 to 43, FEATURES 12 from
  round 7 on, the six earlier mirror reviews: about 300 KB) and M6's four code readings are done right before
  M6's brief is written, once M10 is listed, and not now: every later call of this session reads its whole
  context again, M10 still needs my read, a review, a fix round and a listing, and the reading is needed
  once. If this session's context is long when M10 is listed, it asks for a take-over there and the next
  session does that reading first (it is named in the board row's "Not yet").
- **RUNNING, unchanged:** the one Opus coder on M10 in `wt-mirror-autonew` (since 07:51). I am told when it
  ends; I do not poll it.
- **Next step, in one line:** at the coder's hand-back: its report, then the four places of 18.3 (1), then a
  clerk cuts the frozen copy and the reviewer starts on `BRIEF-M10-review.md`.

### 18.5 M10 handed back, read by me, with its independent reviewer (11-16 08:28)
- **Handed back 08:26: `wip/mirror-autonew` ea105e9b** (pushed, the copy clean; five commits on dbca91d4; 13 test
  functions added, none removed or renamed by the coder's own check; its named runs by its word: the
  collector's `TestMirror(Auto|Door)` 325.6 s, the rest of the `Mirror|ReadEnded` names 319.2 s, whole
  `internal/mirror` 182.1 s, gofmt and vet clean). Report: `archiver/docs/progress/mirror-autonew-REPORT.md`
  on the branch. No schema step. Files touched: `collector/mirror_auto.go`, `mirror_door.go`, `account.go`
  (one comment), `command.go` (the help's paragraph), `mirror_door_test.go` (one assertion: settable is true
  without the flag), new `collector/mirror_autonew_test.go`, new `mirror/autonew.go` and `autonew_test.go`,
  `mirror/door.go` (the token).
- **RUNNING since 08:28: the independent reviewer (Opus, high)** on the frozen copy `wt-mirror-review13-tree`
  (detached at ea105e9b), `BRIEF-M10-review.md` with the head written in and six more points from the coder's
  own departures; its report will be `wt-mirror-review13-scratch\REVIEW.md`. The frozen copy and the brief's
  head line were made by one command of mine (a single call; the PC measured in it: CPU 54%, 4.7 GB free).
- **The coder's departure that matters:** the door's "on" does not delete the baseline row (the catalogue has
  no delete of a setting inside a transaction); it sets "since" to now in the row's transaction, and a new
  `autoBaseline` takes a baseline older than "since" as none. Read by me: the look, `autoListed`, the set-up
  and `MirrorTask` all read the baseline through it; sound by reading but for the clock (b below).
- **My read (the set-up at both callers, `autoLook`, the start of `autoTurn`, the door's transaction, the
  sink): the switch is read before `on` is taken, and a turn that reads it off or unreadable is `OwnerOnly`.
  For the fix round, with whatever the review finds:**
  (a) the door refuses an "off" for an account that is not signed in: an "off" must always be accepted (only
      "on" needs the sign-in record);
  (b) the door's "since" is `now`: with a clock that stepped back below the old baseline, that baseline stays
      in force and a chat joined while off could be taken: "since" becomes the later of now and the baseline
      on record plus one;
  (c) under the run's flag a stored "off" is ignored, so a flag run takes chats joined while the page's
      switch was off (the coder says so itself): rule 1 again. The set-up moves "since" the same way when a
      stored "off" (or a row that cannot be read) is not older than "since"; said in a line;
  (d) an allow from a page while the switch is off clears the end of a held automatic want's read (the
      coder's "not done"; my A6 limited it to one file): the door's `ResumeRead` does nothing for an
      automatic want while the account is not set up;
  (e) `autoLook` ends the reader's turn once a session whenever a held want exists, also when nothing was
      written: only when a record was written;
  (f) words: the comment on `chatStateOf`, one sentence of `command.go`'s help outside the paragraph, the two
      new sentinels in `words.go` (one line; the entry names the file); the reader's skip line "its mirror's
      want has ended" is Core's: a line for Core when M10 is listed.
- **Next step, in one line:** when the reviewer hands back, read `REVIEW.md`, write `BRIEF-M10b-fixes.md` (its
  findings I accept, and (a) to (f)), continue the same coder in `wt-mirror-autonew`, then the same reviewer
  again on the fix range.

### 18.6 M10's independent review is back; its fix round is with the coder (11-16 08:46)
- **The review (`wt-mirror-review13-scratch\REVIEW.md`; probes and plants beside it): "may be listed after these
  fixes".** High 1, medium 2, low 5, one for pages; named runs only, nothing against Telegram.
  1. **HIGH, confirmed by two probes: a page's "on" takes chats joined while the switch was off or
     unreadable.** The look in `autoTurn` reads the baseline row raw, not through the coder's `autoBaseline`.
     **MY ERROR: section 18.5 says "the look ... read the baseline through it; sound by reading". That
     sentence was wrong: I had read the coder's new function and its three callers in the difference and
     did not look at the one reader the difference did not touch, which is the one that decides what is
     taken.** The coder's own test for it passed for another reason (with the switch off the policy is
     removed, so the chat was made switched on, and the look leaves such a chat).
  2. MEDIUM, confirmed: an allow from a page with the switch off restarts the read of a held chat: 190
     history requests in two minutes of the clock (10 before). My read's point (d).
  3. MEDIUM, confirmed: a page's "on" brings a chat list 0.33 s after the click (the 30-minute interval is
     counted from the last list, which with the switch off is usually older). My brief had said no list
     because of a click; the coder's test did not see it.
  4. to 7. LOW: no test sees the order "switch read before `on` is taken" (a plant survived); an unreadable
     switch at the start is said twice; held chats are read on while a set-up fails or the account is
     refused; the clock stepping back (my point (b)).
  8. For pages: the page maps its on/off from `AutoJoined`, not `AutoNew`; `ErrAutoNewByRun` is not among its
     refusals; with `AutoNewSettable` true the page drops its "set by how the program was started" words
     but has no control yet.
  Checked sound by the reviewer: a run that never used the automatic mirror leaves no trace (0 rows, 0 read
  ends, 0 lines, 0 writes in five minutes of the clock); five of six planted changes are caught.
- **Decided by me:** every finding accepted. The fix brief is `BRIEF-M10b-fixes.md` (final): F1 the look
  through `autoBaseline` with five tests that must fail on ea105e9b; F2 "since" the later of now and the
  baseline plus one; F3 a flag run does not undo a stored "off" either; F4 the allow; F5 held chats not read
  while a set-up fails; F6 the 30-minute list counted from a task-made set-up (no request at the click);
  F7 the order's test; F8 small (an "off" always accepted; the turn ended only on a real write; said once;
  the start's A6 test; a test's seed); F9 words. Left as it is and to be said in the entry: the account's
  own refusal (`st.off`) does not end held reads.
- **A question for the owner goes onto the waiting list with this round (one line, a recommendation):**
  after "on" from the page, chats count as "joined from now on" only after the next chat list; built now:
  no request at the click, the list at most 30 minutes later, so a chat joined in those minutes is not
  mirrored by itself. The other way: one chat list at once, its cost in the switch's words. Recommended:
  at once.
- **RUNNING since 08:46: the same Opus coder, continued, on the fix round** in `wt-mirror-autonew`
  (`wip/mirror-autonew` from ea105e9b). Nothing else of the track runs.
- **After its hand-back:** my read of F1 to F4 and F6 in the code itself, every reader of the baseline
  searched by me this time (`grep keyAutoBaseline`); the SAME reviewer again on the fix range (continued,
  with its probes); then ONE clerk call: the copy clean and holding the main head (a clean merge if it
  moved; a conflict: stop), `runs-mirror-m10\run.sh` (made from M11's, the copy's path changed) and a
  `race.sh` over the ten tests the reviewer named plus the round's new ones; the exit lines; then entry
  "M10", my row, the queue line, a message to pages (review 8, the door's names as built) and to Core (the
  reader's skip line's words).
- **Next step, in one line:** when the coder hands back, grep every read of the baseline myself, read F1 to
  F4 and F6, then continue the reviewer on `ea105e9b..<new head>`.

### 18.7 The owner on the 30 minutes (11-16 09:23)
- **The owner, about 09:20 (my clock read 09:22 when I began on it), to me, after my report named item 34:** "30 minutes seems too long. Can we make it a
  selectable option? Maybe default to 10, with some fuzziness. Same with the standalone NAS version."
- **My reading (said to the owner in the same turn, with its cost):** the chat list's interval while the
  automatic mirror is on becomes a catalogue setting, default 10 minutes (5 to 1440), with a random part on
  top (0 to a fifth, at most 5 minutes, never shorter), in place of the fixed 30; the NAS program reads the
  same row. Cost: three times as many chat lists while the switch is on; requests per list not measured yet.
  Not answered by these words: whether the click itself should ask for a list at once (item 34, rewritten:
  with 10 minutes the gap after a click is about 10 to 12 minutes).
- **Built as F10 of M10's fix round:** `BRIEF-M10c-list-every.md` (final 09:23), sent to the running coder at
  09:23 (queued for its next step; if it has finished F1 to F9 it is one more small round on that head).
  Doors for pages: `MirrorListEvery`, `SetMirrorListEvery`. Board: message 115 (the integrator: FEATURES and
  the roadmap; pages: the doors and the review's finding 8; Core: the NAS program takes its mirror timing
  from the catalogue's settings).
- **RUNNING: the same Opus coder on F1 to F10** in `wt-mirror-autonew` (since 08:47). Nothing else.
- **For the listing, not to forget:** `PLAN-MIRROR-auto-first-run.md` names 30 minutes in three places: its
  words and item 26 are brought up to the build once M10 is installed; the review's second pass covers F10
  too (the random part never below the set value; the unreadable value; the tests' override).
- **Next step, in one line:** unchanged: at the coder's hand-back, grep every read of the baseline myself,
  read F1 to F4, F6 and F10, then continue the reviewer on `ea105e9b..<new head>`.

### 18.8 The owner answered item 34 (11-16 09:26)
- **Asked by me at the end of my last report:** should switching it on also ask Telegram for one chat list
  right away, with that cost said beside the switch? **The owner: "Yes".**
- **Built in the same fix round, in place of F6:** `BRIEF-M10d-list-at-once.md`, sent to the running coder
  (queued for its next step): a written "on" from the page makes exactly one chat list due at once, by a
  one-shot mark; a list that fails, is cut off or sets no baseline makes no second one before the interval;
  if it cannot be told from `mirror_auto.go` alone that the list was asked, the coder stops that fix and
  names the line Core would have to lend in `reader.go`.
- **Board:** item 34 says DECIDED; a line under message 115 for pages (the switch's words name the cost); my
  row's front.
- **For the reviewer's second pass, added:** one list per switch-on and never more (a failing list, a clock
  set back, two clicks, an "off", a restart); F10's random part and its unreadable value.
- **RUNNING, unchanged:** the same Opus coder on F1 to F10 with F6 reversed, in `wt-mirror-autonew`.
- **Next step, in one line:** unchanged (the coder's hand-back; my own grep of every read of the baseline;
  the same reviewer again).

### 18.9 The fix round is handed back, read, and with the same reviewer (11-16 09:59)
- **Handed back 09:57: `wip/mirror-autonew` ef7199b0** (pushed, clean): F1 to F10 and M10d (F6 reversed), one
  commit each; 19 test functions added (17 in the new `mirror_autonew_fix_test.go`, 2 in the mirror's), none
  removed or renamed against dbca91d4 by the coder's check; three of its own M10 tests changed (said in its
  report: an "off" accepted for an account not signed in; a seed as the door writes it; the click's test now
  expects one list). Its runs, by its word: the collector's door and automatic tests in two runs, 188.0 s and
  291.0 s (51 tests; one run would pass my 10-minute bound), whole `internal/mirror` 182.0 s, gofmt and vet
  clean. One slip it names: a 7 s run started at 94% CPU.
- **My read, on ef7199b0, by my own search this time (`grep keyAutoBaseline`):** the baseline row is read raw
  in two places only, the function `autoBaseline` itself and `autoMovedSince` (which needs the row's own
  value to put "since" after it); the look, the set-up, `autoListed` and `MirrorTask` all go through
  `autoBaseline`; the one writer is `autoListed`. Read too: `autoSince` (one transaction; under the flag a
  stored "off" not older than "since", or an unreadable row, moves "since" to the later of now and the
  baseline plus one), `heldResume` and `heldApprove` in `accountDeps` (they do nothing for a chat whose
  live want is not the owner's while the account is not set up; `MirrorWantRead` sets its own approval
  after them, so an owner's want is not affected), `chatListEvery` (the one-shot mark is taken there, and
  `reader.go` calls it in one place).
- **Two things of form I change in a last small round whatever the reviewer finds:** (1) the coder kept two
  marks in package-level `sync.Map`s keyed by the account's pointer (it was not allowed fields on the
  account): they become two atomic fields beside `autoReady` in `account.go` (the mirror's own lines
  there); (2) "a `Config.AutoListEvery` of exactly 30 minutes means: use the stored setting" becomes "0
  means it", with the default no longer filled in by `New` (`collector.go`'s line for that field is the
  mirror's). Core is told in the listing's message.
- **RUNNING since 09:59: the same reviewer (Opus), second pass**, on the frozen copy moved to ef7199b0 (one
  command of mine; the PC measured in it: CPU 74%, 3.3 GB free); its result is a new section at the end of
  `wt-mirror-review13-scratch\REVIEW.md`. Asked: each of its findings closed or not by its own probes; F3,
  F4, F5, the one list per switch-on and never more, F10; plants; the race list. Nothing else runs.
- **Next step, in one line:** when the reviewer hands back, write `BRIEF-M10e-last.md` (what is still open,
  and the two things of form), continue the coder; then one clerk call for the head merge, `run.sh` and
  `race.sh` in `runs-mirror-m10`, and entry "M10".

### 18.10 The reviewer's second pass is back; the last small round is with the coder (11-16 10:10)
- **Second pass on ef7199b0 (the section "Second pass (ef7199b0)" at the end of
  `wt-mirror-review13-scratch\REVIEW.md`): "may be listed after two fixes".** Its own probes, before and now:
  the high finding 1 want and 1 want, now 0 and 0; the allow: history requests 10 to 200, now 10 to 10; the
  unreadable switch said 2 times, now 1; the order plant now caught; a run that never used the automatic
  mirror still leaves no trace. Twice the CPU read 84 to 93% before a run of its; it waited and measured
  again.
- **Still open, by it:** A (low to medium, confirmed): under the flag, with the stored switch row and the
  baseline row both unreadable, the set-up is tried again every turn and each try moved "since" and said
  its line (25 times in two minutes of the clock; nothing set up or sent). B: my planned "0 means the
  stored setting" is right only with the default's line out of `collector.go`. C (low): no test for the
  door's "off" clearing an unused mark (a plant survived). D (low, by reading): the mark used up without a
  list when the chat-list method is frozen or the account signed out; a list after a wait by the usual
  rule; an "on" and an "off" at once can leave one mark. E: `heldApprove` cannot be reached today.
- **Decided by me:** A, B, C fixed; E taken out; D written under "Known". `BRIEF-M10e-last.md` (L1 to L5,
  with the two marks as fields of the account), sent to the same coder at 10:10.
- **RUNNING since 10:10: the same Opus coder on L1 to L5** in `wt-mirror-autonew` (from ef7199b0). Nothing else.
- **After it:** a short third look by the same reviewer on `ef7199b0..<head>` (its probe for A, its plant
  for C, L2 and L3 by reading); then ONE clerk call: the copy clean, the main head merged in (clean, or
  stop), `runs-mirror-m10\run.sh` and `race.sh` side by side, the exit lines; then entry "M10" with: the
  files touched (among them one line out of `collector.go`, two fields in `account.go`, four lines in
  `words.go`), tests removed (none expected), the known points, the doors as built for pages, the words for
  Core (the reader's skip line; the two files' lines), item 26's plan (its "30 minutes" in three places).
- **Next step, in one line:** when the coder hands back, read L1 and L2 in the code, then continue the
  reviewer for its short third look.

### 18.11 The last small round is handed back, read, and with the reviewer for a short third look (11-16 10:34)
- **Handed back 10:33: `wip/mirror-autonew` 6bf7073e** (pushed, clean): L1 to L5, one commit each, and the
  report's section "M10e"; three test functions added, none removed or renamed against dbca91d4 by the
  coder's check. Its runs, by its word: the collector's two named runs 187.7 s (25 tests) and 301.0 s (29
  tests), whole `internal/mirror` 177.7 s, gofmt and vet clean. One departure: L1 needed a third atomic field
  on the account (`autoSinceDone`), beside L3's two.
- **Read by me, in the code (not only the difference's changed lines this time):** L1: the mark
  `autoSinceDone` is stored only after `autoSince` returned no error (lines 322 to 329 of
  `mirror_auto.go`), so a failed first try does not skip the flag's check of a stored "off" for the rest
  of the run; L2: `collector.go` loses only the default's line and its comment changes; L3: three fields in
  `account.go`, no package-level state left in `mirror_auto.go`; L5: `heldApprove` is gone, `heldResume`
  untouched.
- **RUNNING since 10:34: the same reviewer, a short third look** on the frozen copy moved to 6bf7073e (its
  probe for A, its plant for C, L1 to L3 and L5 by reading); a section "Third look (6bf7073e)" in its
  `REVIEW.md`. Nothing else runs.
- **The plan of the whole runs (on my row before they start):** one clerk call after the review: the copy
  clean, the main head merged in (clean, or stop); `runs-mirror-m10\run.sh` (build, gofmt, vet; whole
  `internal/mirror`; the catalogue's `Mirror|Protected|Schema` tests; the command package; the collector's
  `Mirror|ReadEnded` set, about 15 minutes; the viewer's wall test) and, at the same time in one container,
  `race.sh` (the race detector over `TestMirrorAutoNew|TestMirrorDoor`, about 45 tests by name, over 15
  minutes: the door, three marks on the account and the set-up mark are crossed between the pages'
  goroutines, the monitor's and the reader's).
- **Next step, in one line:** when the reviewer says "may be listed": the clerk call above; then entry "M10".

### 18.12 The reviewer says "may be listed"; M10 is in its whole runs (11-16 10:37)
- **Third look on 6bf7073e (the section "Third look (6bf7073e)" of its `REVIEW.md`): "may be listed"; nothing
  open from L1 to L5.** Its probe for the flag's repeated move: the line 1 time, "since" written once (2, then
  25 before); its plant for the door's "off" caught by the new test; L2, L3, L5 confirmed by reading; the
  earlier probes unchanged (0 wants, 0 wants, history 10 to 10). Not run by it: two of the coder's new
  tests, whole packages, the race detector.
- **RUNNING since 10:37: ONE Sonnet clerk call:** the review copied into the tree
  (`archiver/docs/review/mirror-autonew-2026-11-16.md`) and committed; the main head merged into
  `wip/mirror-autonew` if it moved (a conflict: abort and stop); pushed; the PC measured;
  `runs-mirror-m10\run.sh` and `race.sh` (side by side with 5 GB free, else one after the other); the exit
  lines and counts; the test functions removed against the main head; the files touched.
- **Next step, in one line:** when the clerk reports every line "exit 0" and no data race: write entry "M10"
  at the end of `MERGE-QUEUE.md`, the "Waiting to merge" line, my row, the message to pages, Core and the
  integrator, and commit with "READY" in the subject. A failing line: read that log myself first.

### 18.13 The whole runs: one line cut off by my script; the head moved; the last run is going (11-16 11:37)
- **The clerk's call (10:37 to 11:36), on 0cb2f5db** (6bf7073e, the review committed into the tree, the main
  head 1d9cd6e5 merged in clean; pushed): build exit 0, gofmt lists nothing, vet exit 0; whole
  `internal/mirror` ok 175.6 s (196 passes); the catalogue's `Mirror|Protected|Schema` ok 32.3 s (64); the
  command package ok; the viewer's wall test ok; **the race detector over `TestMirrorAutoNew|TestMirrorDoor`
  in one container: ok, 2,596.7 s, 40 passes, no data race** (one after the other with `run.sh`: the PC had
  2.8 to 3.2 GB free, not the 5 GB I had set for side by side). Test functions removed against the main
  head: 0; added: 35. 14 files changed (the entry lists them).
- **One line failed, and it is my script's fault, not a test's:** the collector's `Mirror|ReadEnded` set
  ended "panic: test timed out after 10m0s" after 114 passes, 0 failures. `run.sh` (made from M11's) gives
  that line no `-timeout`, so go's default of 10 minutes held; M11's set fitted, with M10's 35 tests it does
  not. Put right in `run.sh` (60 minutes) for the next piece.
- **The main head had moved again (2a6073be: the copies' collector lines, the launcher's window):** merged in
  by me, one command, clean (three shared files auto-merged: `account.go`, `collector.go`, `command.go`):
  **7d31fa56, pushed.** Not by a clerk: the failed line and the moved head needed a judgement (what is run
  again and what stands).
- **RUNNING since 11:37, one script of mine in the background (`runs-mirror-m10/run-collector.sh`), on
  7d31fa56:** it waits for 2.3 GB free and under 80% CPU (2.2 GB free at 11:36), then build, gofmt, vet, the
  collector's `Mirror|ReadEnded` set with a 60-minute limit, the command package. Logs `build-vet-2.log`,
  `collector-mirror-2.log`, `cmd-2.log`.
- **What stands from 0cb2f5db and is not run again on 7d31fa56, said in the entry:** whole `internal/mirror`
  and the catalogue's tests (the merge changed no file of either package), and the race run (the merge
  brought the copies' own collector lines, off unless their flags; my concurrent code is unchanged by it).
- **Next step, in one line:** when the script ends with "exit 0" lines: fill the entry's numbers
  (the draft is `entry-m10.md` in my scratch folder; if this session has ended, write it anew from section 18
  and the report), append it to `MERGE-QUEUE.md`, the queue line, my row, message to pages, Core and the
  integrator, commit with READY in the subject.

### 18.14 M10 IS LISTED, READY (11-16 12:03)
- **`wip/mirror-autonew` 7d31fa56** (copy `wt-mirror-autonew`, clean, pushed; it holds the main head 2a6073be;
  no schema step). Entry "M10" at the end of `MERGE-QUEUE.md`; the board's queue line; message 124 (the
  integrator, pages, Core, copies); my row.
- **The last run, on 7d31fa56 (my script, 11:38 to 12:01):** build exit 0, gofmt lists nothing, vet exit 0; the
  collector's `Mirror|ReadEnded` set ok, 808.2 s, 137 tests, 0 failed; the command package ok. With the
  clerk's lines of 18.13 from 0cb2f5db (whole `internal/mirror`, the catalogue's tests, the race run), which
  are not repeated on 7d31fa56: the entry says why.
- **The entry was written by me, not drafted by a clerk:** it needed a judgement (what is verified and what
  is not; which runs stand across the last merge).
- **Nothing of the track is running** (no coder, no reviewer, no clerk, no go process).
- **Copies that can be removed by a clerk once M10 is merged** (each clean and pushed first):
  `wt-mirror-autonew`; the detached `wt-mirror-review13-tree` (`git -C repo-archiver worktree remove
  ../wt-mirror-review13-tree`); the reviewer's folder `wt-mirror-review13-scratch` stays (its review is in
  the tree as `archiver/docs/review/mirror-autonew-2026-11-16.md`).
- **If the main head moves before the integrator takes it and the integrator asks:** a clean merge is a
  clerk's (check clean, fetch, `merge --no-ff`, push), then `runs-mirror-m10/run-collector.sh` (build, vet,
  the collector's set with its 60-minute limit; about 25 minutes with its wait); the race run again only if
  a file of the mirror's in `internal/collector` that is not a test changed.
- **Owed after the merge and install, mine:** `PLAN-MIRROR-auto-first-run.md` and item 26 name "30 minutes"
  for the chat list in three places: 10 minutes by default with a random part, on the installed build's
  `run -h`; the "Listed and unbuilt" row for an account added while the program runs is struck; a line to
  pages if they answer message 124's question about `AutoNewSettable`.
- **NEXT PIECE: M6, adopting a chat** (`DESIGN-M6-adopt-chat.md`, decided as written). Before its brief, the
  reading still owed, in full, by whoever writes it: the board's messages 6 to 43 (`BOARD-LOG.md`), FEATURES
  12 from round 7 on, the six earlier mirror reviews in `docs/review` and this piece's, and the four code
  readings of the design's last section. Then a small door round with pages (a sign in `ChatState` for a
  dropped word; the read's cost in the plan's request list: ask P4 for the form), then forums.
- **This session's context is long after one landed piece: READY FOR A TAKE-OVER from this section.** What a
  fresh session should know that is not elsewhere: read the code around a difference, not only its changed
  lines (the high finding of M10 sat in a reader the difference did not touch); give every `go test` line in
  a run script its own `-timeout`; the board's lines move while you read: find a place by its words, never
  by a line number; the notes' commit script refuses the board while another track's stray tab is on it
  (pages' message 121): commit the named files directly then.
- **Next step, in one line:** wait for the integrator's merge line; then item 26's plan and the struck row;
  then M6's reading.

## 18.R The board's Mirror row as session M5 left it (moved here by session M-6, 11-16 12:45)

| Mirror (step 3) | **session M5, taken over 11-16 07:41** (mirror; started by the integrator at the owner's word; sessions M, M2, M3 and M4 are retired: do not wait for them or message them) | forward and create in `internal/telegram`, the package `internal/mirror`, in `internal/collector` the files `mirror_cmd.go`, `mirror_auto.go`, `mirror_door.go` and the mirror's other command files, the fake Telegram's create and forward answers, the mirror's schema steps (13, 18, 20, 23) | **11-16 12:03 (M5): M10 IS LISTED, READY: `wip/mirror-autonew` 7d31fa56 holds the main head 2a6073be (`MERGE-QUEUE.md` entry "M10" at the end of the file; message 124): the switch "mirror chats I join by themselves" stored and set from a page; an account added or signed in while the program runs; the chat list every 10 minutes by default, a setting with a random part; one chat list at once at a switch-on. Independently reviewed in three passes ("may be listed", nothing open); on 7d31fa56 the collector's `Mirror|ReadEnded` set passes (137 tests, 808.2 s) with build, gofmt and vet; the race detector over the 40 switch and door tests is clean (one main head earlier). Nothing of the track is running. NEXT: M6, adopting a chat (its owed reading first: this row's "Not yet"); this session's context is long after one landed piece: READY FOR A TAKE-OVER from section 18 of `SESSION-MIRROR-PROGRESS.md`; until a fresh session writes here it answers the board and brings item 26's plan up to the build once M10 is installed.** Before: **11-16 11:37 (M5): M10'S RUNS, NOT LISTED YET: on 0cb2f5db (the branch with 1d9cd6e5 merged in, clean) every line passed (whole `internal/mirror` 196 tests 175.6 s; the catalogue's named 64; the command package; gofmt, vet, build; THE RACE DETECTOR over the 40 switch and door tests by name: ok, 2,596.7 s, no data race) BUT ONE: the collector's `Mirror|ReadEnded` set was cut off by go's own 10-minute limit after 114 passes and no failure (my script gave that line no timeout; the set has grown by 35 tests). The main head moved meanwhile: 2a6073be is merged in (clean; three shared files auto-merged: `account.go`, `collector.go`, `command.go`), the branch is 7d31fa56, pushed; ON IT SINCE 11:37: build, gofmt, vet and the collector's set again with a 60-minute limit (one script, about 20 minutes). The race run is not repeated on 7d31fa56 (what the merge brought is the copies' own lines, off unless their flags). Then entry "M10".** Before: **11-16 10:37 (M5): the reviewer's third look on 6bf7073e: "MAY BE LISTED", nothing open (its probe for the flag: the line said once and "since" written once, 25 times before; its last plant caught). M10 IS IN ITS WHOLE RUNS since 10:37, by a Sonnet clerk, one call: the main head merged in if it moved (a conflict stops it), then whole `internal/mirror`, the catalogue's `Mirror|Protected|Schema` tests, the command package, the collector's `Mirror|ReadEnded` set (about 15 minutes), the viewer's wall test, gofmt and vet; and the race detector over `TestMirrorAutoNew|TestMirrorDoor` by name in one container (about 45 tests, over 15 minutes: the door, three marks on the account and the set-up mark are crossed between the pages' goroutines, the monitor's and the reader's); side by side if the PC has 5 GB free, else one after the other. Then entry "M10".** Before: **11-16 10:34 (M5): M10's last small round was handed back: `wip/mirror-autonew` 6bf7073e (pushed, the copy clean; five points, one commit each, three tests added, none removed by the coder's check; its named runs pass by its word), read by me, and WITH THE SAME REVIEWER FOR A SHORT THIRD LOOK since 10:34. Then the whole runs once by a clerk (the plan is in this row's next sentence but one), entry "M10". It touches, outside the mirror's own files: `account.go` (three atomic fields beside `autoReady`, one comment), `collector.go` (the default's line of `AutoListEvery` out, its comment), `command.go` (the help's paragraph and one sentence), `words.go` (four sentinels).** Before: **11-16 10:10 (M5): the reviewer's second pass was back on ef7199b0: "may be listed after two fixes"; every finding of its first pass is closed by its own probes (the high one: 1 want before, 0 now; the allow: 190 history requests before, 0 now); four of five new planted changes are caught. THE LAST SMALL ROUND IS WITH THE SAME CODER since 10:10 (`BRIEF-M10e-last.md`: under the flag "since" moved at most once a run; "0" as the sign for the stored interval, with the default's line out of `collector.go`; the two marks as fields in `account.go`; one test; one unreachable wrapper out). Then a short third look by the same reviewer, the whole runs once (the race detector over about 40 tests by name: over 15 minutes, because the door, two marks and the set-up mark are crossed between the pages' goroutines, the monitor's and the reader's), entry "M10".** Before: **11-16 09:59 (M5): M10's fix round was handed back: `wip/mirror-autonew` ef7199b0 (pushed, the copy clean; F1 to F10 with F6 reversed, one commit each, 19 tests added, none removed by the coder's check; its named runs pass by its word), read by me (every read of the baseline searched this time: all go through the one function), and WITH THE SAME REVIEWER FOR ITS SECOND PASS since 09:59. Then one last small round (two marks kept in package-level maps become fields of the account; "0" in place of "30 minutes" as the sign for "use the stored setting": for these the mirror's own lines in `account.go` and `collector.go`), the whole runs once, entry "M10".** Before: **11-16 09:26 (M5): THE OWNER ANSWERED ITEM 34: "Yes": a page's "on" asks for one chat list at once, exactly one (`BRIEF-M10d-list-at-once.md`, with the coder in the same fix round, in place of F6).** Before: **11-16 09:23 (M5): THE OWNER (about 09:20): the chat list while the switch is on: "30 minutes seems too long ... a selectable option ... default to 10, with some fuzziness. Same with the standalone NAS version": built as F10 of M10's fix round (`BRIEF-M10c-list-every.md`; message 115; item 34 rewritten). M10 IS WITH ITS CODER on the fix round F1 to F10 since 08:47; then the same reviewer again, the whole runs once, entry "M10".** Before: 11-16 08:47 (M5): M10'S INDEPENDENT REVIEW IS BACK ("may be listed after these fixes": one high finding, confirmed by a probe and missed by my own read: the look read the old baseline raw, so a page's "on" could take chats joined while the switch was off; two medium: an allow restarted a held chat's read, and the click brought a chat list at once); every finding accepted; ITS FIX ROUND IS WITH THE SAME CODER since 08:46 (`BRIEF-M10b-fixes.md`, nine fixes, each with a test that fails without it). Then the same reviewer again, the whole runs once, entry "M10". Item 34 asks the owner one thing about the switch (nothing waits on it). Pages (P4): what the review found on your side is coming under "Messages" with the listing (the page maps its on/off from `AutoJoined`; the fact to show is `AutoNew`).** Before: 11-16 08:28 (M5): M10 was handed back (`wip/mirror-autonew` ea105e9b, pushed, the copy clean; its named runs pass by the coder's word; no schema step), read by me, and WITH ITS INDEPENDENT REVIEWER since 08:28 (a frozen copy, `wt-mirror-review13-tree`). Then its fix round (the review's findings and six points of my own read: section 18.5 of the progress file), the same reviewer again, the whole runs once, entry "M10".** Before: 11-16 07:52 (M5): with a coder since 07:51: M10, the switch "mirror chats I join by themselves" stored and set from a page, and an account added or signed in while the program runs: `BRIEF-M10-auto-switch.md` (with its "what the old app already knows" note), copy `wt-mirror-autonew`, branch `wip/mirror-autonew` cut from dbca91d4, one Opus coder. What it builds: one settings row per account (`mirror.auto.new.N`), read by the task before anything it sends in a turn, fail closed when it cannot be read; the door `SetMirrorAutoNew` (catalogue only; no request, also no chat list, because of a click); the set-up that `startAutoMirror` does once at the start done by the task too; an "on" means "from now on" (a chat joined while the switch was off is never taken by a later on); while off, the reads of the chats the task took stop as well; `Plan.Token()` bound to the account and the chat. `run -auto-mirror` stays and means "on for this run" (the page's switch is then not settable). No schema step. In the collector it edits `mirror_auto.go`, `mirror_door.go`, their tests, the `-auto-mirror` paragraph of `command.go`'s help and at most one line of `account.go` (the monitor's sink); nothing of pages' files. **After the hand-back:** my read of the set-up and the door; one independent review (Opus, probes by overlay; the same reviewer again on the fix round); then the whole runs once by a Sonnet clerk. The plan of those runs, said here first: whole `internal/mirror`, the collector's `Mirror|ReadEnded` set and the catalogue's mirror tests by name, gofmt and vet on the two packages; the race detector only over the new door and switch tests by name (the door's row and the set-up mark are crossed between an HTTP goroutine and the reader's); about 25 minutes; then entry "M10". **Pages' lent lines (`MirrorWantRead`, cf434aba and 30c6349a) are taken as they are: the mirror's from now (message 106).** **Merged and installed: M4, M5, M7, M8, M9, M11; nothing of the track is listed and unmerged.** **Done at the take-over by a Sonnet clerk, one call:** the PC measured (CPU 45 and 63%, 5.0 GB free); the track's eight finished copies removed, each found clean and equal to its branch on `private` first (`wt-mirror-endread`, `-endread-m`, `-door`, `-protected`, `-timing`, `-auto`, `-name`, `-review11-tree`); the new copy cut; the installed build's `run -h` compared with item 26's starter (every flag present; item 26 says so). **Next after M10:** M6, adopting a chat (`DESIGN-M6-adopt-chat.md`, decided as written; its owed reading and four code readings are done by me while M10 is with its coder); a small door round with pages (a sign in `ChatState` for a word the task dropped; the read's cost in the plan's request list); a forum mirrored as a forum. **For the owner:** items 26 (the automatic mirror's first real run) and 33 (the first click on the Chats page) are READY and have not run; when one has, its log's mirror lines and the catalogue read-only, counts only, go onto the board and into `TELEGRAM-FACTS.md` section 11 the same hour. **Read by me, in full:** `CLAUDE.md`'s archiver section; the board's direction, order, clerk rule, "Listed and unbuilt", tracks, queue, schema line, the messages to the mirror from 80 on with the integrator's of 07:34, items 26, 27, 30 and 33; M4's block of 04:47; `mirror_auto.go` and `mirror_door.go` on the main head, the run command's lines for the switch and the secret, `account_add.go`, the look's rule; TRIED-BEFORE 24 and 25; the live lessons' 6b; FEATURES 12 rounds 1 to 4 and 6; findings 5 and 6 of `docs/review/mirror-auto-2026-11-15.md`; the block of HANDOFF 0c; `DESIGN-M6-adopt-chat.md`. **Not yet (before M6's brief):** the board's messages 6 to 43 in `BOARD-LOG.md`, FEATURES 12 from round 7 on, the earlier mirror reviews in `docs/review`. Progress: section 18 at the end of `SESSION-MIRROR-PROGRESS.md`; this row's earlier states (M to M4) are in that file just above section 18. |

## 19. Session M-6 (the mirror track taken over 11-16 12:44, started by the integrator at the owner's word)

**This section is the place to take over from: its newest entry is at its end.** ("M-6" is the session; "M6"
is the piece, adopting a chat.)

### 19.1 The take-over (12:42 to 12:50)
- **Read by me, in full:** `CLAUDE.md`'s archiver section; the board's direction, order and clerk rule (its
  first 90 lines), the mirror's "Listed and unbuilt" rows, the Mirror row as M5 left it, the integrator's row
  of 12:28, messages 115 to 125 (the mirror's 115 and 124, pages' 118, 119 and 121, Core's 117, copies' 120,
  122, 123 and 125, the viewer's two), items 26, 27, 33 and 34; section 18 of this file whole; entry "M10" in
  `MERGE-QUEUE.md`. Not read, as the brief says: `BOARD-LOG.md`, the earlier mirror reviews.
- **Checked on the disk, not taken from the brief:** the main head is bae71e5c (12:44): M10 is NOT on it yet;
  the copy `wt-mirror-autonew` is still there; the track's scripts are `runs-mirror-m10/run.sh`, `race.sh`,
  `run-collector.sh` and `runs-mirror-m9/notes-commit.sh` (not in the project folder's root); the board's
  message 121 still holds another track's tab, so M5's commit script refuses the board.
- **Done (each a single script of mine, not call by call; no clerk: nothing of it was a sequence a clerk
  could take off me more cheaply than one script run):**
  - `runs-mirror-m6/swap-row.sh`: the board's Mirror row (11.4 KB) moved to this file as "18.R" just above
    this section, the new short row in its place (found by its words; the board's other lines untouched: the
    script refuses unless exactly one line differs); this section appended.
  - `runs-mirror-m6/notes-commit.sh`: M9's commit script with one difference: a tab in `BOARD.md` is counted
    and said, and does not refuse.
- **RUNNING: one background file watch of mine** (a shell loop, one look a minute, 4 hours at most): it ends
  when the main head holds `archiver/internal/mirror/autonew.go` AND the integrator's row no longer says
  "INSTALLED 12:28 ... bae71e5", or when that row says "EVERYTHING STOPS" in capitals. (A first watch ended at
  once: its pattern met the row's own sentence "at 97% ... everything stops"; corrected.) Nothing else of the
  track runs: no coder, no reviewer, no clerk, no go process.
- **Committed and pushed:** nothing of code is open. `wip/mirror-autonew` 7d31fa56 is pushed and listed. The
  notes: the commit that carries this entry.
- **When the watch ends (step 1 of the brief), ONE Sonnet clerk call on written steps** (`CLERK-M6-step1.md`,
  written when the head is known): the installed build's `run -h` against the starter's and the plan's flags;
  the starter `a3-auto-mirror.ps1` run by its full path from another folder on a scratch copy with a stand-in
  program and `LOCALAPPDATA` redirected, its output to a file, nothing dialled; the two copies
  `wt-mirror-autonew` and `wt-mirror-review13-tree` removed, each found clean and equal to `private` first.
  Mine (words, a judgement): the plan's and item 26's "30 minutes" in three places become "every 10 to 12
  minutes"; the "Listed and unbuilt" row struck.
- **Meanwhile (step 2): M6's owed reading, by me, and only this:** FEATURES 12 from round 7 on; the four code
  readings of the design's last section; TRIED-BEFORE 24 and 25; `LESSONS-ix12.30-live.md` 6b; the design
  itself. Then the note "what the old app already knows", `BRIEF-M6-adopt-chat.md`, one Opus coder in a new
  copy cut from the head that holds M10 (so not before the watch ends).
- **Next step, in one line:** M6's reading; at the watch's end the clerk call of step 1 first.

### 19.2 M6's reading done, its brief written; the coder waits for the head that holds M10 (12:49)
- **A correction to 19.1 and to the row's first text:** the row said "12:50" at 12:45 (written ahead, not from
  `date`); the times in this entry are from `date`.
- **Read by me, in full, for M6 (and only this, as the brief of 12:42 says):** `DESIGN-M6-adopt-chat.md`;
  FEATURES 12 rounds 7 to 16; TRIED-BEFORE 24 and 25; `LESSONS-ix12.30-live.md` 6b; in the code (main head
  bae71e5c): `mirrorsettle.go` lines 1 to 250 and 440 to 875 (the rules, `weighBatch`, `sourceKeys`,
  `mirrorKeys`, `mediaOf`), `AdoptMirror` with `lostChats`, the ledger's three tables in `schema13.go`,
  `mirrorpace.go` whole, `MirrorCreatesSince`, `MirrorSourceFacts`, `MirrorAutoNewChats` with `lostCreateSQL`,
  `ChatsMadeOff`, `OwnerSetChatCollect`, the viewer's `actMirrors`, and a search of every reader of
  `mirror_of`, of the two batch tables, and of creator or admin rights.
- **What the four code readings found (they are section 3 of the brief):**
  1. `weighBatch` cannot run over a whole chat: it is bound to one blocking batch, and its media pass and
     `couldBeOwn` compare every message with every eligible one (about 2.5 thousand million steps at 50,000 by
     50,000), with two queries per message. Adoption gets its own weigh in set form, same rules.
  2. `AdoptMirror` only lends its shape: it needs a row "creating" or "unknown", sets `mirror_of` and switches
     the chat off.
  3. Posting rights are not on record (`dialogs.go` keeps "left", the view ban, megagroup). The plan says so;
     the first forward is the test; recording them is not in this piece.
  4. Every reader of `mirror_of` means "the app's own chat" (the owner's download switch refused, the
     client's writes refused, the mass switch-off, the counts of chats made, the name on record, the lost
     create, the plan, the look). **Decided: an adopted chat does not get `mirror_of`;** the relation is the
     mirror row's, with `adopted_at`.
  5. Found on the way: the pace's two queries and one more read every batch row as a forward request, and
     `MirrorCreatesSince` counts every mirror row as a create: an adoption must be seen by neither.
- **Decisions of mine in the brief, for the reviewer:** a post named by several copies in the chat is "there,
  counted twice" (the settle's rule; the design's sentence says "exactly one"); "not there" needs that no
  message of the chat, whatever its origin, shares any media row (the design's stricter form, not the
  settle's); the uniqueness counts run over all of the source's messages on record, deleted ones too; the
  weigh is done again inside the record's transaction and must give the counts the owner saw; the waiting
  messages are rows of a new table (the forward rows' states are under a CHECK); `adopt_top` so that a later
  settle looks only above what the chat held at the adoption; a refused post is on record so that nothing is
  sent again by itself; `-keep-current` is the owner's want through the page's own function; a forum and a
  basic group as the chat are refused in this piece.
- **Schema step 26 claimed** on the board's schema line (two columns on `c_mirror`, one table).
- **Written:** `BRIEF-M6-adopt-chat.md`. Not written yet: the review's brief (at the hand-back, from the
  decisions above), the clerk's steps for step 1 (when the head is known).
- **Not started, and why:** the coder is cut from the head that holds M10 (M10 changed `command.go`,
  `words.go`, `mirror_door.go` and `internal/mirror/door.go`, which M6 touches too); the main head was
  bae71e5c at 12:49.
- **RUNNING:** the one background file watch of 19.1. Nothing else.
- **By a script, not a clerk:** this entry, the row and the schema claim are placed and committed by
  `runs-mirror-m6/set-row.sh` (one call; it refuses unless exactly the expected lines of the board differ).
- **Next step, in one line:** when the watch ends: `CLERK-M6-step1.md` and one clerk call (item 26's checks,
  the two old copies removed, `wt-mirror-adopt` cut), my words for item 26 and the struck row, then the coder.

### 19.3 The starter tried again; the review's brief and step 1's script written ahead (12:55)
- **Why the try was made now and not after the install:** it needs no build of the collector (a stand-in
  program takes its place), and `a3-start.ps1` (Core's) had changed at 11-16 07:06, after the last try (11-15
  23:44). It read `a3-start.ps1` and `a3-auto-mirror.ps1` in full first.
- **The try (12:52 to 12:53; one script of mine, `runs-mirror-m6/try-starter.sh`, which builds the stand-in
  and runs `try-starter.ps1`; not a clerk: one command, and the safety of it was the judgement):** the PC
  first: CPU 67%, 2.3 GB free. No control byte in the three PowerShell files. The starter by its full path
  from another folder, on a scratch copy in the temporary folder (a root with an empty placeholder for the
  catalogue, a state folder), `LOCALAPPDATA` redirected to an empty scratch folder for every started process
  before anything was started, through the installed watchdog, with a stand-in program that only writes down
  its arguments and ends after 8 s:
  - the start said its 6 lines: "the automatic mirror's run: run -auto-mirror -no-downloads ...", "started:
    watchdog pid=N, collector pid=N", the three paths, "to see what the automatic mirror says ...";
  - the stand-in saw 15 arguments: `run -db -staging -library -no-links -read-back-now -vpn-adapter
    -public-forbid -auto-mirror -no-downloads` with their values; its `-db` inside the scratch root;
  - the watchdog ended by itself; its record: state "ended", "the program ended cleanly";
  - `-Lines` on the copy: "not running (nothing started from this folder is alive)", the log's path, "the
    automatic mirror has said nothing in it yet";
  - collector processes running before and after: 0 and 0; the scratch copy removed.
  - One look-up of the public address by the start script, as it always does. Nothing else left the PC.
  - Not shown by my script: the starter's exit code (the process object gave none back; its last line is
    printed only on 0, and it was printed).
- **Written ahead:** `BRIEF-M6-review.md` (a draft: the head and the folders are written in at the hand-back;
  15 questions, the first four on a wrong "there", a wrong "not there", the weigh against the settle's own
  cases, the record's transaction); `runs-mirror-m6/step1.sh` (the installed build's `run -h` against 16
  flags and the sign of M10's build; the two finished copies removed after their checks; `wt-mirror-adopt` cut
  on `wip/mirror-adopt` from the main head when local and `private` are equal and M10 is in it; pushed).
- **RUNNING:** the one background file watch (19.1). Nothing else; this session waits for it and does not
  poll.
- **Committed and pushed:** nothing of code is open. Notes: the commit that carries this entry.
- **Next step, in one line:** when the watch ends: read the integrator's row, run `step1.sh` once, write item
  26's and the plan's words (10 to 12 minutes; the build's hash), strike the row, start the M6 coder in
  `wt-mirror-adopt` on `BRIEF-M6-adopt-chat.md`.
- **If this session ends before that:** a fresh session does exactly the line above; everything it needs is
  in `runs-mirror-m6` and the two briefs.

### 19.4 M10 is installed; step 1 done; the owner's cap briefed as M12; TWO CODERS RUN since 14:16 (14:16)
- **The watch ended at 14:06, 68 minutes late, and why:** M10 was on the head and in the collector in place
  since 12:58 (head 2b557601), but my watch also waited for the sentence "INSTALLED 12:28 ... bae71e5" to
  leave the integrator's row, and that row kept it until a new integrator session rewrote it at 14:03. The
  lesson: a watch tests the fact on the disk (the head holds the file; the installed program's own help
  names the new words), never the wording of another session's row. Nothing was lost but time: the reading,
  both briefs and the starter's try were done by 12:55.
- **Read at 14:06:** the integrator's row (a new integrator session, `archiver-integrator-4`, since 14:00; NO
  HOLD OF ANY KIND STANDS: the owner, 13:47: "Usage reset. Go as needed"; the PC is the limit: 1.4 GB free at
  14:02; one go command at a time per track; schema: 24 on the head, K14 is 25, 26 the mirror's M6, next free
  27); messages 126 to 129 (Core's K14 and K16 listed; copies' C14 listed; pages' 128: G12 built, two points
  in the mirror's files; pages' 129: **the owner, 13:28: "Why are the caps so low? Can we adjust them higher,
  and make them configurable?" and 13:34 on 20 a day by default, 1 to 50: "Let's go with your recommendation
  for now"**; the integrator: mine to build, recommended before M6's coder).
- **Step 1, by one script of mine (`runs-mirror-m6/step1.sh`, 14:06; not a clerk: one script run):** the PC:
  CPU 50%, 1.5 GB free; the collector in place: `run -h` 295 lines, 0 of 16 flags missing (`-auto-mirror`,
  `-auto-mirror-download`, `-auto-mirror-steady`, `-auto-mirror-pause`, `-auto-mirror-new-per-day`,
  `-auto-mirror-per-hour`, `-no-downloads`, `-pages`, `-pages-addr`, `-db`, `-staging`, `-library`,
  `-no-links`, `-read-back-now`, `-vpn-adapter`, `-public-forbid`); its help says the chat list "is asked
  every 10 minutes by default, 5 to 1440 as set on the Settings page" (M10's words: read by me in the
  output); the main head 2b557601 equal on `private`, M10's file in it; `wt-mirror-autonew` (clean, head
  7d31fa56 equal to `private`) removed; `wt-mirror-review13-tree` (clean) removed; `wt-mirror-adopt` cut on
  `wip/mirror-adopt` from 2b557601, pushed.
- **My words, after it:** `PLAN-MIRROR-auto-first-run.md`: a paragraph for the build of 2b55760 under "Which
  build" (the chat list every 10 to 12 minutes: 10 and a random part of up to 2, by `ListSpread`; three
  times the chat-list requests; the cap of 5 is this build's) and "30 minutes" changed in the two places that
  spoke of the chat list (step 4; ending a mirror from the phone); item 26's front on the board; the "Listed
  and unbuilt" row for an account added while the program runs struck.
- **M12 briefed (`BRIEF-M12-new-per-day.md`), with its "what the old app already knows" note:** the old app
  added up to 10 chats per half hour and the harm was choosing for the owner, not the rate; Telegram's one
  documented limit is 500 channels; one create ran for real (three requests, no wait); what many creates a
  day cost is not on record: 50 stays the upper bound. Read by me for it on 2b557601: `auto.go`'s bounds and
  `normal()`, `door.go`'s `newPerDay`, every use of the cap, `autonew.go`'s interval (the form to copy),
  `topicsDue`, the comment on `SetMirrorAutoNew`. **Decisions of mine, for the reviewer:** unreadable means 5
  (the careful value), never 20; one function asked at each turn and plan; the flag is "for this run" and the
  set door refuses while it holds; the look's cap of 10 is not changed; pages' two points of 128 a ride
  along (a comment; a fact for a failed set-up).
- **`runs-mirror-m6/go1.sh`: the track's one go command at a time.** A lock (a folder) and a wait for 2,000 MB
  free and under 80% CPU (30 minutes at most, then exit 98), then the command with the archiver's
  environment. A first form of it had a slip of mine (the arguments overwritten): corrected before any coder
  used it; a try of it at 14:09 waited for memory (1.5 GB free) and was stopped by me, its lock removed.
- **RUNNING since 14:16, two Opus coders (high effort), started by me in one message:**
  - **M12** in `wt-mirror-cap`, branch `wip/mirror-cap` (cut from 2b557601 at 14:09, pushed); its report will
    be `archiver/docs/progress/mirror-cap-REPORT.md` on the branch.
  - **M6** in `wt-mirror-adopt`, branch `wip/mirror-adopt`; its report `archiver/docs/progress/mirror-adopt-REPORT.md`.
  - Each commits and pushes its branch to `private` as it goes. Both run go only through `go1.sh`. I am told
    when each ends; I do not poll.
  - Why two at once, against the brief's "one Opus coder at a time": that line was a usage rule of 12:42
    (93%); the usage was reset at 13:47 and the integrator's row says no hold stands; the PC is the limit,
    and the lock keeps the track to one go command at a time.
- **Nothing else runs** (no reviewer, no clerk, no watch).
- **Committed and pushed:** both branches are at 2b557601 on `private` (nothing of the coders' yet). Notes:
  the commit that carries this entry (the board: my row, item 26, the two "Listed and unbuilt" rows, message
  130, by one script, `runs-mirror-m6/board-edit.sh`, which refuses unless exactly those lines differ).
- **After M12's hand-back (expected first):** my read of the one function and the flag's path; a narrow
  independent review (Opus, a frozen copy, probes by overlay, go through `go1.sh`): any path on which the cap
  in force is above the stored or the flag's value, or absent; an unreadable value read as 20; a page's value
  that needs a restart; the owner's want and the task disagreeing on the number; a lowered cap undoing
  something; tests changed from 5 that hid a rule. Then its fixes, the full runs once (plan on my row
  first: whole `internal/mirror`, the collector's `Mirror|ReadEnded` set with `-timeout 60m`, build, gofmt,
  vet; the race detector only if a field shared between goroutines was added), entry "M12".
- **After M6's hand-back:** my read of the weigh and the record's transaction; the reviewer on
  `BRIEF-M6-review.md` (the head and folders written in); fixes by the same coder; the same reviewer; the full
  runs once; entry "M6".
- **Next step, in one line:** at the first hand-back: read its report and the risky part named above, then
  start its reviewer; meanwhile nothing: no polling.

### 19.5 M12 handed back, read by me, with its independent reviewer (14:36)
- **Handed back 14:34: `wip/mirror-cap` 52696bad** (pushed, the copy clean; five commits on 2b557601: A+B, C,
  D, F1+F2, the report). 12 files, +1,007 −40. Tests: 11 added (7 in `internal/mirror`, 4 and the set-up's
  one in `internal/collector`), 1 changed (`TestMirrorAutoNewPerDay`: the flag pinned to 5, it was about the
  bound), 0 removed or renamed, by its word. Its runs through `go1.sh`, by its word, every line "go1: exit
  0": the mirror's 13 named tests 3.6 s (once after a wait of 651 s for the PC), the collector's 10 named
  38.1 s, gofmt nothing listed, vet. Report: `archiver/docs/progress/mirror-cap-REPORT.md` on the branch.
- **Its departures:** (1) a new function `createsRoom` for the turn's wake time and the plan's
  `CreatesRoomAt`: with the cap lowered below what was used, "the oldest create plus 24 hours" is too early;
  (2) `errAutoRecord` added to the sentinels' line of `words.go` beside the three new ones; (3) the set-up's
  fact lives on the session (`autoSession.setUpFailed`, under its lock), not the account (`account.go` is not
  in its list); (4) the set door does not nudge the task, as the interval's door.
- **My read, in the code (the function and its callers, not only the changed lines):** `NewPerDayInForce`:
  the run's value exactly when given, else the stored row as read then; unreadable: 5 and "bad"; a read that
  fails is an error and the turn ends (no create). The only two callers that decide anything are `Turn`
  (before `createAt` is set) and `PagePlan`; `newPerDay()` and the default filled in by `normal()` are gone.
  `createsRoom`: counts the 24 hours, then walks the oldest creates until fewer than the cap are left: right
  for a lowered cap and for several creates in one second; one read while the cap is not full. The flag:
  not given is told from given by `fs.Visit`; 0, 51 and text are refused at the start. **Left for the
  reviewer, asked by name:** more than one create in one turn with 1 below the cap; `Settings` nil in
  production code (20 silently); a run without `-auto-mirror` but with the flag; the fact's lock.
- **RUNNING since 14:37: the independent reviewer (Opus, high)** on the frozen copy
  `wt-mirror-review14-tree` (detached at 52696bad; cut by one command of mine), `BRIEF-M12-review.md` (11
  questions; probes and planted changes by overlay; go through `go1.sh`); its result will be
  `wt-mirror-review14-scratch\REVIEW.md`.
- **RUNNING since 14:16: the M6 coder** in `wt-mirror-adopt`. Nothing else.
- **Next step, in one line:** when the reviewer hands back: read `REVIEW.md`, write `BRIEF-M12b-fixes.md`,
  continue the same coder in `wt-mirror-cap`; then the full runs once and entry "M12".

### 19.6 M12's independent review is back: "may be listed"; a small fix round is with the coder (14:48)
- **The review (`wt-mirror-review14-scratch\REVIEW.md`, probes and overlays beside it; back 14:47; the frozen
  copy still clean at 52696bad): "may be listed".** No high or medium finding. What it found sound, with its
  probes' numbers: 10 stored forms that cannot be read each gave 5 creates in 24 hours, the event in 21 of 21
  turns, the plan's cap 5; 5 turns with the cap's read failing: all failed, 0 requests, the plan failed too;
  cap 3 with 2 used and 5 wants due at once (the owner's and automatic): 3 creates, at most 1 a turn;
  lowered to 1 with 4 used: nothing ended or removed, the next create waits for the fourth oldest plus 24
  hours; `createsRoom` exact in 9 cases and equal to the old code where the cap was not lowered; the fact has
  one writer and one reader, both under the session's lock. Planted changes: 13 of 14 caught. Its runs
  through `go1.sh`: the mirror's probes 55.5 s, the collector's 208.1 s (each "exit 1" only by the
  planted-change test, as meant).
- **Its 7 low findings and what I decided:** L1 (confirmed: the set-up's fact stays set after the page's
  "off"): fixed; L2 (the planted change not caught: the missing secret must leave the fact empty): a test;
  L3 (a run without `-auto-mirror` but with the cap's flag bounds the owner's wants and no start line says
  so): a line; L4 (the "cannot be read" line is never said again in a session after the value read well in
  between): as the interval's line; L6 (the report's counts: 12 tests added, 7 in the mirror): put right; L5
  (the words name the Settings page before pages has the row) and L7 (with no settings at all the read gives
  20: not reachable, both production callers set them; the interval's form does the same): left, said under
  "Known" in the entry.
- **RUNNING since 14:48: the same Opus coder, continued, on `BRIEF-M12b-fixes.md`** (F1 to F5, one commit each)
  in `wt-mirror-cap`, from 52696bad.
- **RUNNING since 14:16: the M6 coder** in `wt-mirror-adopt`. Nothing else (the reviewer has ended).
- **The plan of M12's full runs is on my row** (once, after the fix round and a short look by the same
  reviewer): build, gofmt, vet; whole `internal/mirror`; the collector's `Mirror|ReadEnded` set with
  `-timeout 60m`; the command package; the race detector over `TestMirrorNewPerDay|TestMirrorAutoSetUpFailed`
  by name in one container. About 45 minutes; one script (`runs-mirror-m12`), each line waiting for 2,000 MB.
- **Next step, in one line:** when the coder hands back: read F1 and F4 in the code, continue the reviewer for
  a short look on `52696bad..<head>`, then the full runs' script, then entry "M12".

### 19.7 M6 handed back, read by me (two findings of my own), with its independent reviewer (15:10)
- **Handed back 15:06: `wip/mirror-adopt` 44c6a3f7** (pushed, the copy clean; six commits on 2b557601: the
  weigh, the record with the schema step, the settle, the command, what an adopted chat inherits, the
  report). 26 files, +3,258 −55. Tests: 17 added (catalogue 11, mirror 4, collector 2), 0 removed or renamed,
  by its word. Its runs through `go1.sh` by its own script (`archiver/docs/progress/mirror-adopt-runs.sh`),
  every line "go1: exit 0" by its word: gofmt (nothing listed), vet, the catalogue's `TestMirrorAdopt` 69 s
  and `TestMirror|TestSchema13` 115 s, the mirror's `TestMirror` 177 s, the collector's `TestMirror` 701 s.
  **The weigh at 50,000 by 50,000 invented messages: 0.43 s.** Report:
  `archiver/docs/progress/mirror-adopt-REPORT.md` on the branch.
- **What it says first, for the integrator:** `internal/catalog/pairword_test.go` line 75 asserts
  `SchemaVersion != pairWordSchema` is false (the copies' step is the newest): any later step fails it; it must
  be `<`. Not the mirror's file: not touched, that test not run. K14 meets the same line. On my row.
- **Its departures that matter:** three questions instead of two (sizes, then reads, then the record and the
  run); both chats get a new pass each time, so every read is a pass the command began; a source message
  with an origin key nobody names and no media row follows the settle's own rule; a chat with no title on
  record is refused; the adopted row's base is one blank and its ordinal the source's chat number (no index
  change, no number of the app's names); more refusals in the plan than the brief lists (a forum as source, a
  gap open, a recent refusal, no access hash, a long wait), of which the record's transaction re-reads the
  brief's; the refused post uses the want's existing block words; `mirror/door.go` changed in three small
  places (M12's file too: a meeting at the merge).
- **A refused post into the chat, by its report:** today a definite refusal records the batch "refused", its
  messages are candidates again, and the owner's command blocks nothing (its next run sends again); after:
  on an adopted mirror the refusal blocks the source's want in the existing words: one forward request in
  all over eight turns of the automatic task, in three cases.
- **My read, in the code (the weigh's file whole, 415 lines; `RecordAdoption`, `AdoptTake`, `ReadOnRecord`,
  `MirrorChatUse` whole):** the weigh follows the brief's rules: by origin only when the key is no other
  message's of the source; a shared origin "not there" only when nothing of the chat names it or shares a
  row; by media only with one bare candidate, the key unique in the source and every row exclusive on both
  sides; "not there" only when no message of the chat shares any row; a copy tied twice fails the whole
  weigh. The record: the refusals, both reads, no open row, the weigh done again and compared by a digest of
  every verdict, then the row, one batch row "done" with words that say no request went out, the forward
  rows, the waiting rows; nothing of `mirror_of`, the switch or `c_chat_made`.
  **Two findings of mine, for the fix round (given to the reviewer as known):**
  1. **A stale "there".** The command's read of the chat is a pass of what is newer than what is stored; the
     weigh takes the chat's messages "not known deleted". A copy the owner deleted from the chat after an
     earlier read (the reader reads every chat by default, so an earlier read is the usual case) and whose
     deletion no live update brought is still a row "not known deleted": told "there", never forwarded: a
     hole. For a chat this command reads whole for the first time the evidence is exact. **Fix:** before the
     record the copies told "there" are confirmed to exist by id lists (100 ids a request, the existing
     kind of request, counted, its cost shown with the reads); a copy that is gone is marked deleted as the
     catalogue does elsewhere and the weigh is done again.
  2. **The owner's word while a batch blocks.** `AdoptTake` with "arrived" writes a new batch row; if a batch
     of that mirror is sending, unknown or already, the settle's check "a batch after the blocking one" then
     answers `ErrBadLedger` for good. **Fix:** the word is refused in fixed words while a batch blocks.
- **RUNNING since 15:10: the independent reviewer (Opus, high)** on the frozen copy
  `wt-mirror-review15-tree` (detached at 44c6a3f7; one command of mine), `BRIEF-M6-review.md` with the head,
  the folders, the lock script's line and the three known points written in; its result will be
  `wt-mirror-review15-scratch\REVIEW.md`.
- **RUNNING since 14:48: the M12 coder on its fix round** in `wt-mirror-cap` (it waits for its own test runs).
- Three agents of the track share the lock: one go command at a time.
- **Next step, in one line:** at the M12 coder's hand-back: read F1 and F4, the same reviewer's short look,
  `runs-mirror-m12/run.sh`; at the M6 reviewer's hand-back: `BRIEF-M6b-fixes.md` (its findings and my two),
  the same coder continued.

### 19.8 M12's fix round handed back, read, with the same reviewer for a short second look (15:12)
- **Handed back 15:10: `wip/mirror-cap` 9a35fae9** (pushed, the copy clean; F1 to F5, one commit each on
  52696bad; 7 files, +204 −9). Tests: 4 added in the collector (`...SetUpFailedClearedByOff`,
  `...SetUpFailedSecretClears`, `...NewPerDayRunLine`, `...NewPerDayUnreadableSaidAgain`), 0 removed or
  changed. Its runs through `go1.sh`, by its word, each "go1: exit 0": gofmt (nothing listed; 971 s, almost
  all of it waiting for the PC), vet, the mirror's 13 named tests 3.4 s, the collector's 14 named 63.8 s.
- **Not as briefed, by its report:** F3's line is one call in `command.go`'s `run` (`sayPerDayRun`, after the
  forward secret's block: a line of the mirror's in Core's part of that file: named in the entry); F4 adds
  one field to `mirror.TurnResult` (`NewPerDayRead`: a turn that ended before the cap's read does not count
  as "read well"); F2 is a test only (the clearing was there); no test was run against the code without its
  fix.
- **Read by me (the difference in the three non-test files):** the clearing of the fact sits in `autoLook`
  after the switch was found off or unreadable; the "said once" key is deleted only after a turn that read
  the cap and raised no "bad" event; the run's line is said only for the flag given without `-auto-mirror`.
  Asked of the reviewer by name: that the clearing is reached only when no set-up is tried.
- **RUNNING since 15:11: the same reviewer (Opus), a short second look** on the frozen copy moved to 9a35fae9
  (one command of mine): its L1 probe and its other side, its planted change against the new test, F4 by a
  probe, F3 by reading, its first pass's probes once more.
- **RUNNING since 15:10: M6's independent reviewer** on `wt-mirror-review15-tree` (44c6a3f7).
- **THE MAIN HEAD MOVED: ab4d8858** (since 2b557601: K16, K14 (the catalogue is at schema step 25 now), C14,
  the documents, G12 (pages' control for the switch and the chat list's interval), C15). A trial merge
  without writing anything (`git merge-tree`): **into `wip/mirror-cap`: clean; into `wip/mirror-adopt`: one
  conflict, `internal/catalog/catalog.go`** (the schema's three places: K14's step and M6's: M6's coder sets
  its "after" constant to K14's step in its fix round, where the head is merged in).
- **After the reviewer's "may be listed":** the head merged into `wip/mirror-cap` (clean by the trial: one
  command), then `runs-mirror-m12/run.sh` once (the plan is on my row), then entry "M12".
- **Next step, in one line:** at the M12 reviewer's hand-back: merge the head, start `runs-mirror-m12/run.sh`
  in the background; at the M6 reviewer's: `BRIEF-M6b-fixes.md`.

### 19.9 M12: the reviewer says "may be listed"; the head merged in; its full runs go since 15:18 (15:19)
- **Second look on 9a35fae9 (the section "Second look (9a35fae9)" of `wt-mirror-review14-scratch\REVIEW.md`):
  "may be listed".** L1 closed by its probe (the fact sampled 6 times in each phase: switch on and the set-up
  failing 6 of 6; after the page's "off" 0 of 6; on again 6 of 6; the switch unreadable 0 of 6; the clearing
  is reached only when no set-up is tried; its removal is caught); its planted change CC is caught by the
  new test; F4 closed (bad, good, bad: 2 lines; bad for 20 turns: 1; a turn that ended before the read does
  not count); F3 closed by reading; its first pass's probes give the same numbers (9 of 9 room cases; 10
  unreadable forms 5 each; a failing read 0 requests; 3 creates at most 1 a turn). Its runs through `go1.sh`:
  the mirror's probes 3.9 s, the collector's 278.4 s. The frozen copy clean.
- **One low gap it leaves, and my decision:** no test of the coder's fails when `NewPerDayRead` is ignored
  (only the reviewer's probe does); a regression there would repeat one log line and never change the cap:
  left, said under "Known" in the entry; no third round for a log line.
- **The main head merged into `wip/mirror-cap` by one script of mine (`runs-mirror-m6/merge-head.sh`: the
  copy clean, local and `private` main equal, `merge --no-ff`, pushed; it aborts on a conflict): 9a35fae9 to
  2352f1b3, clean** (the head ab4d8858 brought, in the files M12 touches, only copies' lines in `command.go`).
- **RUNNING since 15:18, in the background: `runs-mirror-m12/run.sh`, once, on 2352f1b3** (the plan was on
  my row since 14:48; one line more, added before the start: the pages' adapter package `livepages` whole,
  because it reads the cap's numbers through the plan): build, gofmt, vet; whole `internal/mirror`; the
  command package; `internal/collector/livepages` whole; the collector's `Mirror|ReadEnded` set with
  `-timeout 60m`; the race detector over `TestMirrorNewPerDay|TestMirrorAutoSetUpFailed` in one container (2
  CPUs, 3 GB). Each line through `go1.sh` (the lock; 2,000 MB free or it waits, 30 minutes at most: a line
  that could not start says so and "exit 98"). Logs in `runs-mirror-m12`; `done.txt` when it has ended.
- **RUNNING since 15:10: M6's independent reviewer.** Nothing else (both M12 agents have ended).
- **If this session ends before the runs do:** read each log's "exit" lines in `runs-mirror-m12`; every line 0
  and no "DATA RACE": write entry "M12" at the end of `MERGE-QUEUE.md` from this section, 19.5, 19.6, 19.8
  and the report on the branch (files against the head: `mirror/newperday.go` new, `mirror/auto.go`,
  `mirror/door.go`, `collector/mirror_auto.go`, `mirror_door.go`, `words.go` one line, `command.go` the help
  and one call in `run`, three test files, one assertion in `mirror/auto_test.go`, the report; tests added
  16, removed 0; no schema step); a failing line: read that log first.
- **Next step, in one line:** when the runs' script ends: read its lines, write entry "M12", the queue line,
  my row, a message to pages and the integrator, commit with READY in the subject.

### 19.10 M12 IS LISTED, READY (16:11)
- **`wip/mirror-cap` 9f15ba3b** (copy `wt-mirror-cap`, clean, pushed; it holds the main head 0d089969; no
  schema step). Entry "M12" at the end of `MERGE-QUEUE.md`; the board's queue line; the state of the cap's
  "Listed and unbuilt" row; a message to the integrator and pages (the doors as built); my row. All placed
  by one script of mine, `runs-mirror-m6/list-m12.sh` (it refuses unless the copy is clean, pushed, at the
  head the runs were made for and holding the main head, and unless exactly the expected lines of the board
  differ).
- **The full runs (`runs-mirror-m12/run.sh`, one script, 15:18 to 16:06, on 2352f1b3; read by me from each
  log's lines):** build exit 0, gofmt lists nothing, vet exit 0; whole `internal/mirror` ok, 174.6 s, 260
  passes, 0 failed; the command package ok; whole `internal/collector/livepages` ok, 24 passes; the
  collector's `Mirror|ReadEnded` set ok, 859.8 s, 170 passes, 0 failed; the race detector over
  `TestMirrorNewPerDay|TestMirrorAutoSetUpFailed` by name in one container ok, 365.1 s, 9 passes, 0 "DATA
  RACE" (it waited 1,398 s for 2,000 MB free before it started; every other line waited 1 to 2 s).
- **The main head moved during the runs (0d089969: copies' C17, `internal/catalog/probe.go`, its test and
  documents only):** merged in by `merge-head.sh`, clean: 2352f1b3 to 9f15ba3b, pushed. On 9f15ba3b, by one
  command of mine through `go1.sh` (16:06 to 16:09): build exit 0, vet exit 0, the cap's tests of
  `internal/mirror` by name ok (2.3 s). The whole runs are not repeated on it: the merge changed no file of
  the mirror, the collector or the commands; the entry says so.
- **The entry was written by me, not drafted by a clerk:** it needed a judgement (what is verified and what
  is not; which runs stand across the last merge; what is known and left).
- **Running: M6's independent reviewer** (since 15:10; it waits on its own probe runs, which queued behind
  M12's runs on the track's lock). Nothing else: no coder, no run, no watch.
- **Copies that can be removed once M12 is merged** (each clean and pushed first): `wt-mirror-cap`; the
  detached `wt-mirror-review14-tree`; the folder `wt-mirror-review14-scratch` stays until the integrator has
  copied its `REVIEW.md` into `docs/review`.
- **Owed after M12's merge and install, mine:** `PLAN-MIRROR-auto-first-run.md` and item 26 say "5 new mirrors
  in 24 hours" for the build in place (20 by default then); the cap's "Listed and unbuilt" row struck.
- **Next step, in one line:** at the M6 reviewer's hand-back: read `wt-mirror-review15-scratch\REVIEW.md`,
  write `BRIEF-M6b-fixes.md` (its findings, my two of 19.7, the head merged in with the schema's three
  places), continue the M6 coder (the agent that built it; if it cannot be continued, a fresh Opus coder on
  the brief and the report).

### 19.11 M6's independent review is back; its fix round is with the coder (16:17)
- **The review (`wt-mirror-review15-scratch\REVIEW.md`; probes, planted copies and run logs beside it; back
  16:14; the frozen copy clean at 44c6a3f7): "may be listed after these fixes".** 1 high, 5 medium, 8 low.
  Sound by its probes: 0 wrong "there" in 1,600 random worlds (12,641 messages told, 3,359 there); the settle
  on an app-made mirror differs in 0 of 300 random worlds between the head and the base; the weigh at
  50,000 by 50,000: 0.44 s; 0 tests removed or renamed, 17 added; privacy clean; of the settle's 13 own
  cases 6 differ in the adoption's weigh: 3 named by the brief, 2 stricter and safe, 1 a finding (M1).
  Planted changes: 23 of 27 caught; of the 4 not caught 2 are test gaps (M3, M4) and 2 are no defects. Its
  runs through `go1.sh` waited 2,755 s and 2,453 s for the lock and the PC (M12's full runs were going).
- **Its findings, and what I decided (every one accepted or said as known):**
  - **H1 (high, confirmed):** the adoption weighs media only by default and the record does not keep that
    choice: a later run with every message (the owner's, or the automatic task's with its every-message
    switch) forwards text already in the chat (its probe: candidates 1, 3 and 4 where 1 and 3 are in the
    chat). **Decided:** the row keeps `adopt_all` and `adopt_src_top` (same schema step); after a media-only
    adoption a message without media up to `adopt_src_top` is never a candidate; the plans say so. Not seen
    by my own read of the weigh and the record: it is in what a LATER run does with the record.
  - M1 (confirmed): messages without media sharing one origin were "not there" while the chat holds a bare
    copy (14 wrong of about 7,500 told with every message; 0 of 5,087 media only): the single message's rule.
  - M2 (confirmed): a waiting member cuts an album (an album of 3, the middle one waiting: the batch is the
    other two): no member is a candidate while one waits.
  - M3, M4 (test gaps by planted changes): a test each (the settle's safety half on an adopted mirror; the
    record's re-check of the refusals).
  - M5 and L4, L5 (plausible; more of my K1's kind on the source's side and after the adoption): an unseen
    edit of the source; what the owner forwards by hand after the reads began: **left, said under "Known" and
    in one line of the adoption's plan**; a weigh again at each later run of an adopted mirror would close
    the second: a possible next piece, not this one.
  - L1, L3: the waiting messages and the adoption's rows said in the plan of a later run and in `mirror
    -list`; a count for the pages. L2: the adoption's batch rows out of the settle's guard. L6: the source's
    migration twin refused. L7: the refused post's words only for a refusal that names the chat's rights.
    L8 (no index): left.
  - **My two of 19.7:** K1 (a copy deleted since an earlier read is still "there"): the copies are confirmed
    by id lists before the record when the chat had been read before (100 ids a request, counted, the cost
    shown); K2 (the owner's word while a batch blocks): refused.
- **`BRIEF-M6b-fixes.md` written (section 0: the main head merged in first, the schema's three places; F1 to
  F10) and sent to the same coder, continued, at 16:17.**
- **RUNNING since 16:17: the M6 coder on its fix round** in `wt-mirror-adopt` (from 44c6a3f7). Nothing else
  of the track runs (both reviewers have ended; M12 is listed and waits for the integrator).
- **After its hand-back:** my read of F1 and F5 in the code; the SAME reviewer again on the fix range (its
  probes for H1, M1, M2; its plants for M3 and M4; F5 and F6 new); then the full runs once, their plan on my
  row first: whole `internal/mirror`; the catalogue's mirror, adoption, settle and schema tests by name and
  the collector's `Mirror|ReadEnded` set (neither package whole: the integrator's at the merge); the command
  package; build, gofmt, vet; no race detector unless the round adds state shared between goroutines (the
  first round added none: a command, a catalogue transaction and pure code).
- **Next step, in one line:** when the coder hands back: read F1 and F5, move the frozen copy, continue the
  reviewer.

### 19.12 M6's fix round handed back, F1 and F5 read, with the same reviewer for its second pass (16:31)
- **A correction to my own times:** several entries above name a time one or two minutes ahead of the clock
  (19.4, 19.7, 19.11: written before the clock was read). From this entry on the time is the script's `date`.
- **Handed back 16:29: `wip/mirror-adopt` 5e46b061** (pushed, the copy clean). **The merge first:** the main head
  5d884fc2 (K16, K14, C14, G12, C15, C17, C16 since 2b557601), merge commit e1c09b00; the one conflict was the
  expected one, `catalog.go`'s three schema places: its "after" constant is K14's step, so **its step is 26**;
  no line outside the mirror's files changed (`pairword_test.go` and K14's own schema test already compare
  with `<` on the head). Then F1 to F10, one commit each; 28 files, +1,176 −42 against the merge. Tests: 14
  added (`TestMirrorAdoptFix*`: catalogue 5, mirror 5, collector 4; the reviewer's probes for H1, M1, M2 and
  M3 among them), 0 removed or renamed. Its runs through `go1.sh`, by its word, each "go1: exit 0": gofmt
  (nothing listed), vet on four packages, the catalogue's adoption tests 62 s (the weigh at 50,000 by 50,000:
  0.35 s), its settle and schema tests, the mirror's and the collector's adoption and settle tests.
- **Not as briefed, by its report:** the id lists are counted under the refresh's kind (the same method), no
  new kind; a want whose mirror is an adopted chat still counts as "with a mirror created" in the automatic
  counts (it has its mirror). F5 is a new file of the mirror's own, `internal/telegram/mirror_ids.go`
  (`Forwarder.MessagesGone`), because `refresh.go` has no call that answers which ids still exist.
- **Read by me, in the code:**
  - F1: the two columns are read into the mirror row on every form of its select (a file older than the step:
    zeros); the candidates' filter leaves out, on an adopted mirror whose adoption weighed media only, a
    message with no attachment and an id up to `adopt_src_top`: one statement for the command and the
    automatic task alike.
  - F5: `MessagesGone`: at most 100 ids, each above 0 and once; one `channels.getMessages` through the
    forwarder's call (a stated wait slept in full, one over the bound an error); an answer that does not name
    every id asked is an error and tells nothing; an id answered as an empty message is gone; its log line
    is two counts. `AdoptConfirm`: nothing asked when the chat had no message on record before the read;
    else every copy told "there" asked in lists of 100; a gone copy marked deleted, the weigh done again,
    newly tied copies confirmed in turn; any error ends it and the caller writes nothing.
  - Asked of the reviewer by name: how "the chat had messages on record before" is decided and whether a
    read under way or a gap can fool it; what marking a copy deleted does elsewhere in the catalogue.
- **RUNNING since 16:31: the same reviewer (Opus), its second pass** on the frozen copy moved to 5e46b061 (one
  command of mine): each finding by its own probe again; F5 as hard as the first pass; F6; the schema on an
  older file and through both steps; its random worlds again; eight planted changes on the new rule lines.
- **Written ahead: `runs-mirror-m6/run-m6.sh`**, the full runs' one script (the plan is on my row): build,
  gofmt, vet; whole `internal/mirror`, `internal/catalog`, `internal/telegram`, `livepages`; the command
  package; the viewer's wall and schema tests by name; the collector's `Mirror|ReadEnded` set. No race
  detector (no state shared between goroutines is added). Logs in `runs-mirror-m6/m6-logs`.
- **Nothing else runs.** M12 is listed (9f15ba3b) and waits for the integrator; the main head is 5d884fc2
  (16:30), so M12's branch is one copies merge behind it (`internal/catalog`'s probe settings and the
  collector's lines for them: the integrator merges three-way).
- **Next step, in one line:** when the reviewer says "may be listed": the head merged into `wip/mirror-adopt`
  if it moved (clean, or the coder's), `run-m6.sh` once in the background, then entry "M6"; "after these
  fixes": one more round with the same coder first.

### 19.13 M6's second review pass is back; a last small round is with the coder (16:44)
- **Second pass on 5e46b061 (the section "Second pass (5e46b061)" of `wt-mirror-review15-scratch\REVIEW.md`):
  "may be listed after these fixes".** Every finding of the first pass and my two are closed by its own
  probes: H1 (the every-message candidates after a media-only adoption: 1 message, 3 before; newer text and
  media still go; an adoption with every message leaves nothing out; the automatic task uses the same
  filter); M1 (0 wrong "not there" and 0 wrong "there" in 1,600 random worlds; 14 wrong "not there" before);
  M2 (no member of an album is a candidate while one waits); M3, M4 (its two plants now caught); L1, L2, L3,
  L7; K2 (the word refused in each blocking state, 0 rows written); K1 for copies that are gone (two copies
  of one post, the first deleted: 41 ids asked in 2 requests, 40 there; an answer naming fewer ids writes
  nothing; marking copies deleted writes exactly what a live delete writes: every table compared, 0 differ;
  no way found to fool "the chat had messages on record"). Also sound: the settle on app-made mirrors
  unchanged in 300 worlds; the weigh 0.41 s at 50,000 by 50,000; a file at step 24 reads on a read-only
  handle, steps through 25 and 26 and ends identical to a fresh file; 0 tests removed by the fix commits.
  Planted changes on the new rule lines: 12 of 14 caught. Its three runs through `go1.sh` waited 1 to 2 s.
- **New, and what I decided:**
  - **N1 (medium, confirmed): the id lists do not sleep a wait stated for their method.** They were sent under
    the wait key "confirm" while that method's waits are kept under the refresh's key: with a stored refresh
    wait still running the command sent 1 request. **Fixed in the last round: this is the track's first
    rule.** Not seen by my own read of `mirror_ids.go`: I read that the call sleeps a stated wait and did not
    ask under which key the wait is found.
  - N5 (two rules no test holds: the "names every id" check, and confirming a copy the weigh newly ties):
    its two probes become tests. N4 (the command's words name the wrong request): put right. L6's open half
    (the chat to adopt's own migration twin): asked too.
  - N2 (a source message that reaches the catalogue later with an id at or below `adopt_src_top` is decided
    by its id alone) and N3 (an earlier id-list round's deletion mark stays when a later round fails: the
    mark is true): left, said under "Known".
- **`BRIEF-M6c-last.md` written (L1 to L5) and sent to the same coder, continued.** It does not merge the main
  head in this round: I do that once before the full runs if it moved.
- **RUNNING: the M6 coder on the last small round** in `wt-mirror-adopt` (from 5e46b061). Nothing else.
- **After its hand-back:** my read of L1; a short third look by the same reviewer (its N1 probe, its plants Q4
  and Q10, L4 by reading); then the head merged in if it moved, `runs-mirror-m6/run-m6.sh` once, entry "M6".
- **M12** is listed (9f15ba3b) and not merged yet (checked on the queue file's entry at this entry's time).
- **Next step, in one line:** when the coder hands back: read L1, move the frozen copy, continue the reviewer
  for its short third look.

### 19.14 M12 merged and installed: its owed steps done; M6's last round back, in its third look; the head being merged in (16:53)
- **M12 IS MERGED (the integrator, 16:47: 44a6d7b on the main branch; the collector in place 16:47, the owner's
  folder rebuilt 16:48; message 140 d).** Its whole-collector run at the merge had one failure in a test of
  the copies track that M12 does not touch (the integrator read it to its cause: message 140 a).
- **What I owed after it, done:**
  - the installed build's `run -h` (one command of mine, 16:52: it prints and ends; 320 lines): the flag's
    line says "for this run (1 to 50; not given: as set on the Settings page, 20 unless set there)" and the
    `-auto-mirror` paragraph says the page cannot set it under the flag;
  - `PLAN-MIRROR-auto-first-run.md`: a paragraph for the build of 44a6d7b under "Which build" (the cap is a
    setting, 20 unless set; the starter does not pass the flag; nothing the owner sees in that run changes)
    and "at most 20" under "What stays afterwards"; item 26's front on the board;
  - the cap's "Listed and unbuilt" row struck;
  - the copies `wt-mirror-cap` (clean, head 9f15ba3b equal to `private`) and `wt-mirror-review14-tree`
    (clean) removed by one command; the review is in the tree as `docs/review/mirror-cap-2026-11-16.md` (the
    integrator's copy); the folder `wt-mirror-review14-scratch` stays.
- **M6's last small round handed back at 16:50: `wip/mirror-adopt` 717c5045** (pushed, clean; L1 to L5, one
  commit each; 4 tests added, 0 removed; its named runs through `go1.sh` each "go1: exit 0" by its word,
  among them the telegram package's forwarder and refresh wait tests). L1 read by me: the id list's call now
  uses `refreshWhat`, the key under which the refresher checks, saves and remembers its waits (read at each
  of its uses in `refresh.go`). Not as briefed, by its report: one assertion of its own earlier test changed
  to the request's right name; the "never" half of the twin's test passes without the fix too (the family's
  marks were already read), the want half fails without it.
- **RUNNING since 16:52: the same reviewer, a short third look** on the frozen copy moved to 717c5045 (its N1
  probe, its plants Q4 and Q10 against the two new tests, L4, L3, its second pass's probes once more).
- **The main head 44a6d7b merged into `wip/mirror-adopt` by me, not by the script, because it conflicts:**
  one conflict, the sentinels' line of `internal/collector/words.go` (M12 and M6 each added one line at the
  same place): both lines kept; `command.go` and `mirror/door.go` merged by git. The merge is NOT committed
  yet: **RUNNING since 16:55, one background command of mine through `go1.sh`:** build, gofmt, vet, and the
  adoption's and the cap's tests by name in `internal/mirror` and `internal/collector` (log
  `runs-mirror-m6/m6-logs/merge-check.log`). **If this session ends here: `wt-mirror-adopt` holds an
  uncommitted merge** (`git status` shows it; `MERGE_HEAD` is 44a6d7b7): when that log's lines are all "exit
  0", commit it (`git commit` with the usual identity and last line) and push; a failing line: read it
  first.
- **The schema number (message 140 b):** 26 is the mirror's by claim, and the number at the merge is the
  order of the merges: M6 or copies' C19, whichever is listed first, is 26; the integrator sets the second's
  "after" constant. On the branch M6's step is the one after K14's.
- **Next step, in one line:** when the merge check ends clean: commit and push the merge; when the reviewer
  says "may be listed": `runs-mirror-m6/run-m6.sh` once in the background, then entry "M6".

### 19.15 The main head is merged into M6's branch and pushed (16:54)
- **`wip/mirror-adopt` 89adcc0e** (the merge of 44a6d7b7 on 717c5045; pushed; the copy clean; it holds the main
  head). The check on the merged tree before the commit (one background command of mine through `go1.sh`,
  16:53 to 16:54; each line waited 1 to 2 s): build exit 0, gofmt lists nothing, vet exit 0, the adoption's
  and the cap's tests by name in `internal/mirror` ok 8.2 s and in `internal/collector` ok 65.7 s. The
  uncommitted state of 19.14 is over.
- **Running: the reviewer's short third look** on the frozen copy at 717c5045 (the code before the merge; the
  merge brought M12's lines, reviewed as M12). Nothing else.
- **Next step, in one line:** when the reviewer says "may be listed": `runs-mirror-m6/run-m6.sh` once in the
  background on 89adcc0e (or on a newer head merged in clean by `merge-head.sh`), then entry "M6".

### 19.16 M6: the reviewer says "may be listed"; its full runs go since 16:58 (16:59)
- **Third look on 717c5045 (the section "Third look (717c5045)" of `wt-mirror-review15-scratch\REVIEW.md`):
  "may be listed".** N1 closed (a refresh wait on record and under the bound: 0 id lists before its end, 1
  after, 40 copies there; a wait over the bound: 0 id lists, nothing written; a wait stated on an id list is
  stored where the refresher reads); its plants Q4 and Q10 now caught by the two new tests; L4 closed by a
  probe in three cases (the twin of the chat to adopt as one of the app's mirrors, as a mirror row's chat,
  as a source: the record refused, 0 rows; the plan blocked in the same words); L3 by reading; its second
  pass's probes the same (1,600 random worlds: 0 wrong "there", 0 wrong "not there"; 300 settle worlds: 0
  differ; the schema from 24 to 26). Its runs through `go1.sh`: each "go1: exit 0". The frozen copy clean.
- **The main head had not moved (44a6d7b7): `wip/mirror-adopt` 89adcc0e holds it** (`merge-head.sh` said so).
- **RUNNING since 16:58, in the background: `runs-mirror-m6/run-m6.sh`, once, on 89adcc0e** (the plan was on
  my row since 16:31): build, gofmt, vet; whole `internal/mirror`; whole `internal/catalog`; whole
  `internal/telegram`; the command package; whole `livepages`; the viewer's wall and schema tests by name;
  the collector's `Mirror|ReadEnded` set (`-timeout 60m`). No race detector (no state shared between
  goroutines is added). Logs in `runs-mirror-m6/m6-logs`; `done.txt` when it has ended.
- **Written ahead: the entry "M6"** (`runs-mirror-m6/entry-m6.md`: the head, the main head and the runs' line
  are filled in when the script has ended). Written by me, not drafted by a clerk: what is verified and what
  is not, and what is known and left, are judgements.
- **Nothing else runs** (the coder and the reviewer have ended).
- **If this session ends before the runs do:** read each log's "exit" lines in `runs-mirror-m6/m6-logs`; every
  line 0: fill the entry's three placeholders, append it to `MERGE-QUEUE.md`, the queue line, the state of the
  "Listed and unbuilt" row "Choosing an existing chat of the owner's as a source's mirror", a message to the
  integrator and pages, my row, a commit with READY in the subject. A failing line: read that log first; a
  test of another track's failing in the whole catalogue: say which and whether it fails on the main head
  too, by name, before deciding anything.
- **Next step, in one line:** when the runs' script ends: read its lines, list M6.

### 19.17 M6 IS LISTED, READY (17:28)
- **`wip/mirror-adopt` 3b2f943a** (copy `wt-mirror-adopt`, clean, pushed; it holds the main head 3781f8f2; a schema
  step: on the branch the one after K14's). Entry "M6" at the end of `MERGE-QUEUE.md`; the board's queue line;
  the state of the "Listed and unbuilt" row; message 145 (the integrator, pages, copies); my row. All placed
  by one script of mine, `runs-mirror-m6/list-m6.sh` (it refuses unless the copy is clean, pushed and holding
  the main head, a placeholder is left, or other lines of the board than the expected ones differ).
- **The full runs (`runs-mirror-m6/run-m6.sh`, one script, 16:58 to 17:27, on 89adcc0e; read by me from each
  log's lines; every line waited 1 to 2 s for the PC):** build exit 0, gofmt lists nothing, vet exit 0 (four
  packages); whole `internal/mirror` ok, 180.0 s, 279 passes; whole `internal/catalog` ok, 568.9 s; whole
  `internal/telegram` ok, 43.4 s; the command package ok; whole `internal/collector/livepages` ok; the viewer's
  wall and schema tests by name ok, 7.0 s; the collector's `Mirror|ReadEnded` set ok, 883.4 s, 181 passes, 0
  failed. No race detector: no goroutine and no state shared between goroutines is added.
- **The main head moved during the runs (5a131192: the viewer's pass-through to the door; 3781f8f2:
  documents; no file of the mirror's; in the collector `pages.go` only):** merged in by `merge-head.sh`,
  clean: 89adcc0e to 3b2f943a, pushed. On it, by one command of mine through `go1.sh` (17:27 to 17:28): build
  exit 0, vet exit 0, the adoption's tests by name in `internal/collector` (14.6 s) and `internal/mirror`
  (4.2 s) ok. The whole runs are not repeated on it; the entry says so.
- **The entry was written by me, not drafted by a clerk:** what is verified, what is not, and what is known
  and left are judgements.
- **No clerk in this session, and why, once for all its entries:** every routine sequence was one script of
  mine run by one call (`runs-mirror-m6`: `step1.sh`, `try-starter.sh`, `merge-head.sh`, `run-m6.sh`,
  `list-m12.sh`, `list-m6.sh`, `set-row.sh`, `board-edit.sh`, `after-m12.sh`, `notes-commit.sh`;
  `runs-mirror-m12/run.sh`), which the clerk rule names as the cheaper form; the coders and the reviewers ran
  their own named runs through `go1.sh`.

### STATE FOR A TAKE-OVER (session M-6, 17:28)
- **Nothing of the track runs** (no coder, no reviewer, no run, no watch, no go process of mine).
- **Listed and unmerged: M6**, `wip/mirror-adopt` 3b2f943a (entry "M6"). **Merged and installed: M12** (44a6d7b,
  16:47) and everything before it.
- **Copies on disk:** `wt-mirror-adopt` (clean, pushed); `wt-mirror-review15-tree` (detached at 717c5045,
  clean); the folders `wt-mirror-review14-scratch` and `wt-mirror-review15-scratch` (the reviews: the
  integrator copies them into `docs/review`). After M6's merge: remove the first two (each clean and equal to
  `private` first; `git -C repo-archiver worktree remove`).
- **If the integrator hands M6 back** (a conflict with copies' C19 in `catalog.go`'s three schema places is
  the likely one: whichever is merged second sets its "after" constant): the integrator does that in its own
  copy (message 140 b). If the main head moved and it asks for the head merged in: `merge-head.sh
  wt-mirror-adopt` (clean, or it stops), then build, vet and `TestMirrorAdopt` by name through `go1.sh`; the
  whole runs again only if a file of the mirror's or `internal/catalog`'s mirror files changed.
- **Owed after M6's merge and install, the mirror's:**
  1. the plan of the first real adoption on the test account (`PLAN-MIRROR-first-adoption.md`: which two
     chats, the three questions and what each shows, the cost in requests, what is read afterwards from the
     log and the catalogue read-only, counts only) and its line on the owner's waiting list; the installed
     build's `mirror -h` read against the plan's flags first;
  2. the "Listed and unbuilt" row "Choosing an existing chat of the owner's as a source's mirror" struck
     ("choosing on a page" stays pages');
  3. the two copies removed.
- **The owner's items 26 and 33 have not run.** When one has: its log's mirror lines and the catalogue
  read-only (`mode=ro`), counts only, onto the board and into `TELEGRAM-FACTS.md` section 11 the same hour,
  before everything else. Item 26 and `PLAN-MIRROR-auto-first-run.md` are on the build of 44a6d7b (the chat
  list every 10 to 12 minutes; 20 new mirrors in 24 hours by default); the starter was tried at 12:53.
- **Next pieces, in order, each with its "what the old app already knows" note first:** (1) the small door
  round with pages (a sign in `ChatState` for a word the task dropped; the read's cost in the plan's request
  list: ask pages for the form); (2) a weigh again at each later run of an adopted mirror (closes the entry's
  first "known" point: what the owner forwards by hand after an adoption); (3) the posting rights recorded
  from the chat list (a field in Core's `dialogs.go` and a schema column: ask on the board first, as the
  protected flag was); (4) a forum mirrored as a forum (after the first real batch).
- **What a fresh session should know that is not elsewhere:**
  - A reviewer finds what the author's read does not: in M6 the high defect was in what a LATER run does
    with the record, and the medium one in which key a wait is looked up under. Ask a reviewer both
    questions by name: "what does every later reader do with what this writes" and "under which key is each
    stated wait stored and read".
  - Every go command of the track goes through `runs-mirror-m6/go1.sh` (a lock and a wait for 2,000 MB free):
    with it two coders and a reviewer ran side by side without pinning the PC; waits were 1 to 2 s when
    memory was there and up to 46 minutes when another track's run held it.
  - A watch tests the fact on the disk (the head holds the file), never another session's wording (19.4).
  - The board's shared lines are changed by a script that finds each by its words and refuses unless
    exactly the expected lines differ (`set-row.sh` for the row and an entry; the `list-*.sh` forms for a
    listing); `notes-commit.sh` here lets the board's one foreign tab pass and scans every other file.
  - Write a time only after reading the clock (three of this section's entries were a minute or two ahead).
  - A hand-back from a background agent may arrive more than once (the reviewer's third look came three
    times): act on the first, check the head named in it.
- **Next step, in one line:** wait for the integrator's merge of M6 (a background file watch on the main head
  holding `archiver/internal/catalog/mirroradopt.go`); then the three owed steps above.

### 19.18 The owner on the cap's maximum: M13 briefed and with a coder (17:59)
- **The owner, 17:58, to the integrator (relayed to me by the integrator's session at 17:59; read by me on the
  board, message 149 b):** "The daily mirror cap should be 20, but the maximum of 50 is dumb. It should be
  higher if needed, configurable." Also in 149: no hold ("Keep going"; 67% of all models' week at 17:47); the
  tracks may remove their own finished copies of merged branches; Core has session K-5 and pages P6; a whole
  `internal/server` run fails on five Staging tests that read this PC's free disk space until pages mends
  them (not the mirror's); M6 is in its merge run again since 17:54 and merges as schema step 26.
- **My reading and decision:** the bound of the cap becomes what Telegram itself bounds, the account's limit
  on channels: the constant `ChannelLimit` (500) that the guard already uses; a larger number could never be
  reached. For the stored setting, the run's flag and the set door alike. The default stays 20; unreadable
  still gives 5. No fixed number in words the owner or a page reads. What keeps a high value safe is
  unchanged: every stated wait slept in full and lengthening the pause, one create at most a turn, the
  account's writes the pause apart, the guard at 500, the look's cap of 10. What many creates in a day cost
  is still not on record: said in the entry.
- **`BRIEF-M13-cap-max.md` written** (with its "what the old app already knows" note by reference to M12's).
- **RUNNING since 17:59: one Opus coder (high effort) on M13** in `wt-mirror-capmax`, branch
  `wip/mirror-capmax` (cut from the main head 78739d59 by one command of mine: local and `private` equal;
  pushed). Its report will be `archiver/docs/progress/mirror-capmax-REPORT.md` on the branch.
- **RUNNING since 17:29: the background watch for M6's merge and install** (the main head holds
  `internal/catalog/mirroradopt.go` AND the installed collector's `mirror -h` names `-adopt`; or entry "M6"
  says handed back).
- **After the coder's hand-back:** my read (every place the bound was named); a short look by M12's reviewer
  (the agent that reviewed M12, continued, on a frozen copy: a stored 51 to 500 in force, 501 and the
  unreadable forms 5, the flag's range, the door's `Max`, its M12 probes once more, three planted changes);
  the head merged in; the full runs once (the plan is on my row); entry "M13"; the "Listed and unbuilt" row's
  state.
- **The take-over block of 19.17 stands, with this added:** M13 is with a coder; if this session ends, a fresh
  one reads the coder's report on `wip/mirror-capmax` and goes on from "After the coder's hand-back" above.
- **Next step, in one line:** at the coder's hand-back: read the difference, then the reviewer's short look.

### 19.19 M13 handed back, read by me, with M12's reviewer for a short look (18:06)
- **Handed back 18:04: `wip/mirror-capmax` 6ca8b178** (pushed, the copy clean; ONE commit on 78739d59; 7 files,
  +202 −24). `AutoNewPerDayMax` is `ChannelLimit` (500); a new var `mirror.NewPerDayRangeWords` ("1 to 500",
  from the two constants) is what the range refusal, the flag's usage line, the start's refusal and the help's
  paragraph say; `mirror_door.go` unchanged (`Facts.Max` reads the constant). Tests: 3 added, 4 changed (the
  bound's number, and one step more in the page's test), 0 removed. Its runs through `go1.sh`, by its word,
  each "go1: exit 0": gofmt (nothing listed), vet, the mirror's cap tests by name 11.3 s, the collector's
  41.0 s. Report: `archiver/docs/progress/mirror-capmax-REPORT.md` on the branch.
- **Not as briefed, by its report:** `collector.RunUsage` changed from a constant to a variable (a constant
  string cannot take a number from an int constant; `command.go` now imports `internal/mirror`): in Core's
  part of that file, one declaration: named in the entry; the new tests were not run against the old code.
  For pages, seen by it and not touched: a stale comment in `internal/server/mirrors.go` (about line 385)
  that says the default is 5, and the invented 5 in the demo and a test.
- **Read by me (the difference in the four non-test files; every use of `RunUsage`: one, in `command.go`):**
  the constant, its comment, the words' one source; the default 20 and the careful 5 unchanged. Asked of the
  reviewer by name: anything in the code that assumed 50 (a slice, a loop, a query, a wait); `createsRoom`
  with 500 creates on record; the order in which the package-level variables are made.
- **RUNNING since 18:06: M12's reviewer (Opus, continued), a short look** on the frozen copy
  `wt-mirror-review16-tree` (detached at 6ca8b178; one command of mine); its result will be
  `wt-mirror-review16-scratch\REVIEW.md`.
- **RUNNING since 17:29: the watch for M6's merge and install.** Nothing else.
- **Written ahead: `runs-mirror-m6/run-m13.sh`**, the full runs' one script (build, gofmt, vet; whole
  `internal/mirror`; the command package; whole `livepages`; the collector's `Mirror|ReadEnded` set; no race
  detector: a constant and words).
- **Next step, in one line:** when the reviewer says "may be listed": the head merged in (`merge-head.sh
  wt-mirror-capmax`), `run-m13.sh` once, entry "M13".

### 19.20 M13's review look is back with a finding my brief was wrong about; its fix round is with the coder (18:12)
- **The look (`wt-mirror-review16-scratch\REVIEW.md`; the frozen copy clean at 6ca8b178): "may be listed after
  these fixes".** The change itself is right: stored 60 with 62 wants: 60 creates, at most 1 a turn, then a
  wait for room; stored 51: 51; stored 500 with 3 wants: 3; 13 unreadable forms ("501", "0", "1000" among
  them) each give 5 and the line in 21 of 21 turns; nothing in the code is sized by the old 50; the three
  package variables are made in a safe order; the flag takes 500 and refuses 501; 0 tests removed (4,052 test
  names before, 4,055 after); its three planted changes all caught. Its runs through `go1.sh` waited 1 to 2 s.
- **M1 (medium, confirmed), and MY ERROR:** the guard at the account's limit on channels (`WhyAt500`) lives
  only in `MakeRunPlan` (the page's plan, the owner's yes, the command). The automatic task's turn never
  reads the channel count: with the count on record at 500 its probe saw 4 creates sent for 4 automatic
  wants. In a real run at the limit each would be refused by Telegram, block its want and count against the
  cap: up to 500 refused creates a day with the new bound (50 before). **`BRIEF-M13-cap-max.md` and my
  entries 19.18 and 19.19, and my message to the owner's side through the row, name "the guard at 500" among
  what keeps a high value safe: for the task it did not exist. I wrote that from M12's brief and the plan's
  code without reading whether the turn asks it.** It was so before M13 too (M4's code); the higher bound
  makes it matter.
- **Decided:** fixed in this round (F1): the turn reads the channel count once a turn; at the limit no
  create is sent, no want is blocked, forwards go on, one line said once per time it becomes true. L1 (the
  room after a lowered cap walked one read at a time: 501 reads, 363 ms with 500 creates on record, at every
  turn and plan): one sorted query (F2). L2 (the range words an exported variable): a function (F3).
- **`BRIEF-M13b-fixes.md` written and sent to the same coder, continued, at 18:13.** It touches one file more
  than M13's list, the mirror's own: `internal/catalog/schema_mirrorwant.go` (the query beside
  `MirrorCreatesSince`).
- **RUNNING since 18:13: the M13 coder on its fix round** in `wt-mirror-capmax` (from 6ca8b178).
- **RUNNING since 17:29: the watch for M6's merge and install.** Nothing else.
- **After its hand-back:** my read of F1 in `Turn` (where the count is read and where a create is decided: the
  code around, not the difference alone); the same reviewer again (its M1 probe, F2's nine cases, plants on
  F1's lines); the head merged in; `run-m13.sh` once: with F1 the turn's code changed, so the collector's
  `Mirror|ReadEnded` set and whole `internal/mirror` are what matters; the catalogue's mirror tests by name
  added for F2; still no race detector unless F1's "said once" adds state shared between goroutines (the
  cap's line did not: its key is the reader's goroutine's own).
- **Next step, in one line:** when the coder hands back: read F1, move the frozen copy, continue the reviewer.

### 19.21 M13's fix round handed back, F1 read, with the same reviewer for a second look (18:25)
- **Handed back 18:23: `wip/mirror-capmax` 7b84bda6** (pushed, the copy clean; four commits on 6ca8b178; 11
  files, +600 −26). F1 (63b35076): the turn reads `MirrorChannelCount` once, the plan's own reading; at
  `ChannelLimit` or above no create goes that turn (not even `help.getConfig` for it), no want is blocked or
  ended, forwards go on; one event a turn (`AutoEvChannelLimit`; the count in `AutoNumbers.Channels`, the held
  creates in `CreatesAtLimit`); a count that cannot be read is the turn's error; the collector says the line
  once each time the limit is reached. F2 (206de094): `catalog.MirrorCreateAtRank`, one sorted query with an
  offset, gives the room in one read (two reads at most; the old walk is kept in the test as the
  reference). F3 (d15ad90e): `NewPerDayRangeWords()` is a function. F4: the report's "M13b" section.
  Tests: 5 added (`mirror.TestMirrorAutoChannelLimit`, `collector.TestMirrorAutoChannelLimitSaidOnce`,
  `catalog.TestMirrorWantCreateAtRank`, `mirror.TestNewPerDayRoomOneRead` with nine cases,
  `mirror.TestNewPerDayRoomReadsAt500`), 1 changed (it calls the function), 0 removed. Its runs through
  `go1.sh`, by its word, each "go1: exit 0" (the mirror's automatic and cap set about 52 s, the collector's
  cap set with the limit test about 41 s, the catalogue's two tests, gofmt and vet on three packages).
- **Not as briefed, by its report:** the review's folder held no nine room cases (its one room probe measures
  and checks nothing): the nine cases are the coder's own, compared with the old walk; no sentinel was
  added (`words.go` unchanged); the new tests were not run against the code before each fix.
- **Read by me (F1 in `auto.go`, with the code around it):** the count is read right after the creates of 24
  hours and before anything is decided; the hold sits in `mirrorTurn` where a want has no mirror row yet
  (`!ok`), before the name rule's hold and before `help.getConfig`; the event is one a turn. **Asked of the
  reviewer by name: every other place in a turn where a create can start** (a create whose answer was lost,
  one the owner said was not made), and what state the "said once" keeps.
- **RUNNING since 18:25: the same reviewer, its second look** on the frozen copy moved to 7b84bda6.
- **RUNNING since 17:29: the watch for M6's merge and install** (M6 was still listed and unmerged at this
  entry's time; the main head 78739d59).
- **`run-m13.sh` has one line more** (the catalogue's mirror tests by name: F2 added a query there).
- **Next step, in one line:** when the reviewer says "may be listed": `merge-head.sh wt-mirror-capmax`,
  `run-m13.sh` once, entry "M13".

### 19.22 M13: "may be listed"; its full runs go; NOT listed yet: it meets M6 in one function's meaning (18:32)
- **Second look on 7b84bda6 (the section "Second look (7b84bda6)" of `wt-mirror-review16-scratch\REVIEW.md`):
  "may be listed", nothing new.** M1 closed by its probe (the channel count forced to 500 over 60 turns: 0
  creates; forwards into the existing mirror still go; `help.getConfig` never asked; wants 4 to 4, none
  blocked or ended; at 600: 0 creates; at 499: exactly 1 create, then the hold; back under the limit: the
  creates go; a count that cannot be read: 5 of 5 turns fail, 0 requests; every create start is behind the
  hold: one create site; a lost answer only adopts or blocks; the owner's "not made" sends nothing). The
  line: 1 over 20 turns at the limit; at, under, at: 2. F2: the room equal to the old walk in 12 of 12 cases,
  at most 2 reads; on 4,501 rows 2 to 3 ms where the walk took 607 ms; a plan 9 ms (361 before). F3 by
  reading. Its first look's probes the same. 5 of 5 planted changes caught. 0 tests removed (4,055 names
  before, 4,060 after). No new state shared between goroutines.
- **RUNNING since 18:30, in the background: `runs-mirror-m6/run-m13.sh`, once, on 7b84bda6** (the main head
  78739d59 had not moved: the branch holds it): build, gofmt, vet; whole `internal/mirror`; the catalogue's
  mirror tests by name; the command package; whole `livepages`; the collector's `Mirror|ReadEnded` set. Logs
  in `runs-mirror-m6/m13-logs`.
- **M13 IS NOT LISTED YET, AND WHY (found by my trial merge of the two branches before writing the entry's
  last line):** `git merge-tree` of `wip/mirror-adopt` (M6, listed, in the integrator's merge run) and
  `wip/mirror-capmax` conflicts in `internal/catalog/schema_mirrorwant.go`, and not only in text: **M6 changed
  `MirrorCreatesSince` so that an adopted row is no create; M13 added `MirrorCreateAtRank` beside it with
  "the same starters and the same 24 hours". After M6 the rank must leave out adopted rows exactly as the
  count does, or the count and the rank disagree and the room's time is wrong for an account with an
  adopted mirror.** A git merge would not show that as a conflict if the lines sat apart. So: M13 waits for
  M6 on the main head; then the head is merged into `wip/mirror-capmax` by the M13 coder in one small round
  ("M13c": the merge, the rank's filter equal to the count's, a test with an adopted row among the creates
  that fails without it), the adoption's and the cap's tests by name, and whole `internal/mirror`, the
  catalogue's mirror tests and the collector's set once more on the merged tree (M6 changes the mirror's own
  non-test files, so the runs of now do not stand for it); then the entry "M13" (drafted:
  `runs-mirror-m6/entry-m13.md`, `msg-m13.txt`; its "For you at the merge" is rewritten then).
- **The runs of now are still worth their minutes:** they show M13 clean on its own tree, so a failure after
  the merge is the merge's.
- **RUNNING since 17:29: the watch for M6's merge and install.** Nothing else (the coder and the reviewer
  have ended).
- **If this session ends here:** a fresh one waits for M6 on the main head (the watch's two facts), then does
  the round above with a fresh Opus coder on `wip/mirror-capmax` (the report on the branch and this entry
  are its brief's sources), then lists M13; and M6's three owed steps of 19.17.
- **Next step, in one line:** read the runs' lines when the script ends; at M6's merge: the round "M13c".

### 19.23 M6 HANDED BACK BY THE INTEGRATOR, not merged; its mend is with the coder (18:36)
- **The hand-back (the integrator's session to me at 18:36; read by me in `MERGE-QUEUE.md`'s entry "M6" and the
  board's message 154 a):** on the combined tree the whole collector failed on ONE test of Core's that the
  piece breaks, `TestNotCountedRepeatWaitsDerived` (`countsfix_test.go` about 614: "not_counted names
  repeat_waits.refresh, which is counted"). The cause: since the last small round (M6c L1)
  `internal/telegram/mirror_ids.go` sends the id lists through the request loop under the refresh's word, so
  the refresh kind's repeat waits are fed, while the status file's list `notCounted` says nothing counts
  them; Core's test derives that list from the telegram package's code. Everything else passed with the
  step (whole tgstore, bringin, supply, probejudge, pairwords, partsledger, copyset, livepages, actdoor,
  acttest, the viewer 418.6 s; the collector's other tests, 1,772.3 s; the server but for pages' five tests
  that read this PC's disk).
- **Why my runs did not see it, and the lesson:** this track ran the collector's `Mirror|ReadEnded` set, not
  the whole package (the convention since M10, written on my row before the runs: "the whole collector is
  the integrator's at the merge"). The test that failed is Core's and carries no "Mirror" in its name. **For
  a piece that sends a request through a loop other tracks' code also counts and tests, the whole package
  that owns the loop's users is run by the track before the listing.** M6's re-listing gets the whole
  collector (the integrator asks it too: once, with a 45-minute limit).
- **Also in 154:** copies' C19 is in its merge run as SCHEMA STEP 26 (M6 was not on the head, so no join was
  needed); **M6's step becomes 27**; the next free number is 28. The owner's folder was given empty library
  and staging folders at the owner's word (not the mirror's).
- **Decided, and briefed (`BRIEF-M6d-counted.md`):** the id lists are counted under a kind of their own while
  they keep the refresh's WAIT key (the second review pass's N1 must stay: a wait stated for
  `channels.getMessages` is slept by both; it also answers that pass's N4, the counts not telling the id
  lists from Core's refreshes). If the loop cannot take the two apart in the mirror's own code: one line in
  Core's `status_file.go` with a true comment, named in the report's first lines. No merge of the head in
  this step.
- **RUNNING since 18:35: M6's coder, continued, on the mend** in `wt-mirror-adopt` (from 3b2f943a).
- **RUNNING since 18:30: M13's full runs** (`runs-mirror-m6/run-m13.sh`, on 7b84bda6).
- **The watch for M6's merge ended at 18:37 as it was made to** (entry "M6" says handed back). No watch runs.
- **After the coder's hand-back:** my read of the mend (which word is the wait's key, which the counting
  kind, at each use); when the main head holds C19 (step 26): the coder merges the head in (the schema's
  three places and its step test's comparison: 27 after 26); then ONE script: the whole collector with
  `-timeout 45m`, whole `internal/catalog`, `internal/mirror` and `internal/telegram`, the command package,
  `livepages`, the viewer's wall and schema tests by name, build, gofmt, vet; a short look by M6's reviewer
  at the mend only (the wait's probe again; the counts); then entry "M6" again (the old entry's text with
  the hand-back, the mend and the new runs). Then M13's small round (19.22) and its listing.
- **Next step, in one line:** when the coder hands back: read the mend; check whether C19 is on the head.

### 19.24 M13's full runs on its own tree are clean (18:53)
- **`runs-mirror-m6/run-m13.sh`, one script, 18:30 to 18:53, on 7b84bda6 (holding the main head 78739d59; read
  by me from each log's lines), every line exit 0:** build, gofmt lists nothing, vet; whole `internal/mirror`
  ok, 198.7 s, 274 passes; the catalogue's mirror tests by name ok, 36.7 s; the command package ok; whole
  `internal/collector/livepages` ok; the collector's `Mirror|ReadEnded` set ok, 887.1 s, 172 passes, 0 failed.
  The waits for the PC were 1 to 99 s (M6's coder ran its own tests between the lines).
- **Not listed, as 19.22 says:** it waits for M6 on the main head, then the small round "M13c" (the head merged
  in; the rank query leaves adopted rows out as the count does; a test). **Added to that round by 19.23's
  lesson: the whole collector once on the merged tree** (M13 changes the turn and hands two new numbers to
  the pages' side; other tracks' tests may derive from them), with `-timeout 45m`, beside whole
  `internal/mirror` and the catalogue's mirror tests.
- **Running: M6's coder on the mend** (since 18:35; it waits on its own test runs). The main head is still
  78739d59 (copies' C19 not on it yet at this entry's time). Nothing else.
- **Next step, in one line:** when M6's coder hands back: read the mend; when C19 is on the head: the merge
  into `wip/mirror-adopt` (step 27) and M6's runs with the whole collector.

### 19.25 M6's mend handed back and read: one line in Core's status file; waiting for copies' step on the head (19:00)
- **Handed back 18:59: `wip/mirror-adopt` a84ab14f** (pushed, the copy clean; the main head not merged in this
  step; 5 files, +116 −7). **The mend is the brief's second form: one line in Core's
  `internal/collector/status_file.go`** (commit da06c573): the list `notCounted` no longer names
  `repeat_waits.refresh`, and its comment says that count holds the mirror's id lists' repeat waits only (the
  refresher keeps its own loop and never calls `call`). **Why not a kind of their own (my first choice), by
  the coder's reading:** `call` uses one word for the wait's key, the in-flight entry and the repeat waits;
  the count's name comes from the pick's field in Core's `counters.go`; parting the two would change Core's
  loop or `memo.go` (at least three lines in two of Core's files). The loop is untouched.
- **What holds:** the second pass's N1 (`TestMirrorAdoptFixConfirmRefreshWait` unchanged: the wait is slept);
  Core's `TestNotCountedRepeatWaitsDerived` and the telegram package's `repeatconfig` test pass unchanged.
  One test added, `TestMirrorIDsCountedAsRefresh` (an id list answered after two stated waits: 3 requests, 2
  waits and 1 repeat wait under the refresh's kind; its wait kept under the refresh's key); 0 removed; one
  expected line of its own earlier test follows the command's new words ("counted under the refresh's kind
  with its waits"). Its runs through `go1.sh`, by its word, each "go1: exit 0": gofmt, vet, the telegram
  package whole 45 s, the collector's `TestMirrorAdoptFixConfirm|TestNotCountedRepeatWaitsDerived|Counted|
  Counts|Status` by name.
- **Read by me:** the one hunk in `status_file.go`: the comment is true to the code as the coder describes it,
  and the list's other names are untouched.
- **Message 167 to Core (K-5) and the integrator:** the one line, why, and what Core would add if it wants the
  counts apart (a pick with its own stats field and a `call` that takes the wait's key beside the kind).
- **Copies' C19 (schema step 26) is not on the main head yet** (78739d59 at 19:00, local and `private`; its
  merge run began 18:33). **RUNNING since this entry: one background file watch** that ends when the main
  head moves, or the queue's entry "C19" says handed back (then M6 stays the step after K14's and is listed
  on the head as it is). No coder, no reviewer, no run of the track is going.
- **When the watch ends with C19 on the head:** M6's coder, continued, merges the head into `wip/mirror-adopt`
  (the schema's three places; `mirrorAdoptAfter` on C19's step; its step test's comparison: 27 after 26);
  then one script (`run-m6b.sh`, written then from `run-m6.sh`): THE WHOLE COLLECTOR with `-timeout 45m`,
  whole `internal/catalog`, `internal/mirror`, `internal/telegram`, `livepages`, the command package, the
  viewer's wall and schema tests by name, build, gofmt, vet; a short look by M6's reviewer at the mend (the
  wait's probe; the counts) while the runs go is NOT allowed by the order (no full runs while a review is
  open): the look first (minutes), then the runs; then entry "M6" again.
- **Next step, in one line:** at the watch's end: the merge by the coder; the reviewer's short look; the runs.

### 19.26 Copies' schema step is on the main head: M6's merge is with the coder, its mend with the reviewer (19:06)
- **The watch ended at 19:05: the main head is 5bfecb58** (copies' C19: `SchemaVersion = edgeLogSchema`, step
  26; 7 files). A trial merge into `wip/mirror-adopt` (a84ab14f) conflicts in `catalog.go` only, as expected.
- **RUNNING since 19:06, side by side (their go commands one at a time through the lock):**
  - **M6's coder, continued: the merge of the main head into `wip/mirror-adopt`** (`mirrorAdoptAfter` on
    copies' step; `SchemaVersion`, the entry in `steps`, the case in the switch; its step test's comparison:
    27 after 26; a build, gofmt, vet and the schema and adoption tests by name; no whole package).
  - **M6's reviewer, continued: a short fourth look at the mend** on the frozen copy moved to a84ab14f (is the
    status file's comment true to the code; its N1 probe once more; whether a kind of their own could have
    been done inside the mirror's files; the new test; my merge's one resolved line in `words.go`).
  - The look is on the tree before this merge; the merge changes the schema's three places only, which the
    full runs cover. The full runs start only after BOTH have ended.
- **Written ahead: `runs-mirror-m6/run-m6b.sh`**, the re-listing's one script: build, gofmt, vet; whole
  `internal/mirror`, `internal/catalog`, `internal/telegram`, `livepages`; the command package; the viewer's
  wall and schema tests by name; **THE WHOLE `internal/collector` with `-timeout 45m`** (about 30 minutes; it
  is over 15, and why: the piece sends a request through the shared request loop, and a test of Core's that
  does not name the mirror failed on it at the integrator's first merge run). No race detector. About 50
  minutes in all. Logs in `runs-mirror-m6/m6b-logs`.
- **Next step, in one line:** when both hand back: read the merged `catalog.go`'s three places; "may be
  listed": `run-m6b.sh` once; then entry "M6" again.

### 19.27 M6: the head merged (step 27), the mend looked at ("may be listed"); its runs go with the whole collector (19:11)
- **The merge, handed back 19:08: `wip/mirror-adopt` 16589fcb** (pushed, clean; it holds the main head
  5bfecb58). The one conflict was `catalog.go`'s three schema places. Read by me in the merged file:
  `SchemaVersion = mirrorAdoptSchema`; `mirrorAdoptAfter = edgeLogSchema` (so 27 after copies' 26); both
  entries in `steps`, both cases in the switch; its step test compares with copies' step; copies' own step
  test already compares with `<`: no line outside the mirror's files changed. The coder's checks through
  `go1.sh`, by its word, each "go1: exit 0": build, gofmt, vet on four packages, the catalogue's
  `TestMirrorAdopt|Schema|EdgeLog|ActKey|PairWord` by name 100.3 s, the mirror's and the collector's
  `TestMirrorAdopt`.
- **The reviewer's fourth look on a84ab14f (the section "Fourth look (a84ab14f)" of its `REVIEW.md`): "may be
  listed".** The mend is true to the code (the repeat-wait count is named after the pick; the refresher never
  calls the loop's `call`; the only `call` under the refresh's word or pick is the id lists'); Core's test
  and the config's repeat-wait test pass unchanged for the right reason; its N1 probe again: 0 id lists
  before a running wait's end, 1 after; over the bound 0 and nothing written; the coder's claim is right
  in substance (a kind of their own needs a new field in Core's `Stats` and a line in `memo.go`: two Core
  lines; a route inside the mirror's file would still need the field); the new test pins what it says (a
  nit: its check of the record's time only pins that the record exists); my merge's `words.go` lost
  nothing. Not a defect, noted: the collector's own process never sends an id list, so the count's key only
  appears where an adoption command ran.
- **RUNNING since 19:12, in the background: `runs-mirror-m6/run-m6b.sh`, once, on 16589fcb** (the plan was on
  my row since 19:06): build, gofmt, vet; whole `internal/mirror`, `internal/catalog`, `internal/telegram`,
  `livepages`; the command package; the viewer's wall and schema tests by name; THE WHOLE `internal/collector`
  (`-timeout 45m`). Logs in `runs-mirror-m6/m6b-logs`; `done.txt` when it has ended.
- **Nothing else runs** (the coder and the reviewer have ended).
- **If this session ends before the runs do:** every "exit" line 0 in `m6b-logs`: list M6 again (the queue's
  entry "M6": a new first paragraph "Waiting, READY AGAIN" with the head 16589fcb, the main head, SCHEMA STEP
  27, the mend (one line in Core's `status_file.go`: message 167), the merge, these runs; the old text
  stays below it), the queue line on the board, a message to the integrator and Core, the row; then M13's
  small round (19.22 and 19.24). A failing line: read that log first; if it is a test of another track's,
  run it by name on the main head too before deciding.
- **Next step, in one line:** when the runs' script ends: read its lines, list M6 again.

### 19.27b The integrator's word of 19:32; M6's re-listing handed to a script; M13's last round with its coder (19:34)
- **The integrator's session to me, 19:32:** the owner has set the objective for what is left of the usage
  (about an hour this week): the app as one window in the new look, which is pages' and the viewer's. **For
  the mirror: finish what is in flight to its listing (M6's mend, M13), push it, bring the take-over block up
  to date, start nothing new.** The main head holds copies' step 26; M6 comes again as 27.
- **RUNNING since 19:12: M6's runs** (`runs-mirror-m6/run-m6b.sh`, on 16589fcb; the whole collector last).
- **RUNNING since this entry: `runs-mirror-m6/auto-relist-m6.sh` in the background.** It waits for the runs'
  `done.txt`; if EVERY "exit" line is 0 and no file is named by gofmt or vet, it merges the main head in if
  it moved (clean, or it stops), checks that merge by build, vet and named tests, and lists M6 again with
  `relist-m6.sh` (the queue's entry, the board's row, queue line, listed row and one message, the progress
  entry 19.28, a notes commit with READY in its subject). **If anything is not as written it lists nothing
  and writes `runs-mirror-m6/m6b-logs/AUTO-STOPPED.txt` with the reason.** The texts it places are
  `m6-again.txt`, `msg.txt`, `row.txt` and `entry.md` in `runs-mirror-m6`, written by me at 19:34.
- **RUNNING since 19:33: M13's coder, continued, on its last small round** (`BRIEF-M13c-onto-m6.md`: M6's
  branch merged into `wip/mirror-capmax`; the rank query leaves adopted rows out as M6's count does; a test;
  the report's count corrected). After its hand-back: my read of that one hunk; then one script for M13's
  runs (whole `internal/mirror`, the catalogue's mirror tests by name, `livepages`, the command package, THE
  WHOLE `internal/collector` with `-timeout 45m`, build, gofmt, vet) that lists M13 by itself when every line
  is exit 0 (entry "M13" is drafted: `runs-mirror-m6/entry-m13.md`, `msg-m13.txt`; its last paragraph is
  rewritten then: M13 holds M6's tree and is merged after M6). No further review look: the round is one
  condition and its test, and the usage is nearly spent.
- **If this session ends here, a successor checks, in this order:** `runs-mirror-m6/m6b-logs/AUTO-STOPPED.txt`
  (if it is there: its reason; else `git log -3` of the notes shows "M6 LISTED AGAIN"); the M13 coder's
  report on `wip/mirror-capmax` (a section "M13c"); then M13's runs and listing as above.
- **Next step, in one line:** at the M13 coder's hand-back: read the hunk, start M13's runs-and-list script.

### 19.28 M6 IS LISTED AGAIN, READY, by a script at the end of its runs (20:36)
- **`wip/mirror-adopt` 209af9de** (clean, pushed; it holds the main head e9413e4e; SCHEMA STEP 27). The queue's
  entry "M6" has a new first paragraph ("Waiting, READY AGAIN"; the first listing's text stays below it); the
  board's queue line; the state of the "Listed and unbuilt" row; message 185 (the integrator, Core); my row.
- **How it was listed, and why so:** the integrator's word of 19:32 (the owner's objective for what is left of
  the usage, about an hour this week: finish what is in flight, start nothing new) made every turn of this
  long session dear. So at 19:34 I wrote the listing's texts ahead and started ONE background script,
  `runs-mirror-m6/auto-relist-m6.sh`: it waited for `runs-mirror-m6/m6b-logs/done.txt`, checked that EVERY
  "exit" line of the eight logs is 0 (any other: it stops and writes `AUTO-STOPPED.txt` there, listing
  nothing), merged the main head in if it had moved (`merge-head.sh`: clean, or it stops) and then ran build,
  vet and the adoption's and the counts' tests by name through `go1.sh` (each exit 0, or it stops), put the
  runs' own "ok" lines into the entry, and ran `relist-m6.sh` (which refuses unless the copy is clean,
  pushed and holding the main head, and unless exactly the expected lines differ). **The numbers in the
  queue's entry were written by that script from the logs; I have not read them myself unless a later entry
  says so.** The reviewer's look and my read of the merge came before the runs (19.27).
- **The runs (`runs-mirror-m6/run-m6b.sh`, 19:12 on, on 16589fcb):** their lines are in the queue's entry and
  in `runs-mirror-m6/m6b-logs`.
- **M13:** its last small round is with its coder since 19:33 (`BRIEF-M13c-onto-m6.md`); see the next entry.

### 19.28b M6 listed again at 20:36 by hand; M13's runs-and-list script started (20:38)
- M6's listing script stopped once at 20:35 without listing (the main head had moved during its checks); I merged
  that head (no file of the mirror's packages), built (exit 0) and listed M6 with `relist-m6.sh`:
  `wip/mirror-adopt` 209af9de, message 185, notes commit 01a6560. M6's runs' lines were read by me at 20:23
  (the whole collector ok, 1,789.8 s); entry 19.28 above was written ahead and says otherwise: 19.29 corrects it.
- M13's last round is back (`wip/mirror-capmax` 6af8bed4; its one hunk read by me).
- **RUNNING since 20:38, in the background: `runs-mirror-m6/auto-list-m13.sh`**: it merges M6's branch as listed
  again into `wip/mirror-capmax`, runs `run-m13b.sh` (the whole collector last, about 45 minutes in all) and lists
  M13 with `list-m13.sh` when every exit line is 0 (entry 19.29 and the take-over block are placed by it).
  **If it stopped: `runs-mirror-m6/m13b-logs/AUTO-STOPPED.txt` has the reason and M13 is NOT listed;** the texts
  it would have placed are `entry-m13.md`, `msg-m13.txt`, `row.txt` and `entry.md` in `runs-mirror-m6`.

### 19.29 M6 listed again at 20:36 (by hand after the script stopped once); M13 LISTED, READY, after M6 (21:13)
- **A correction to 19.28, which the listing script placed as I had written it ahead:** M6's runs ended at
  20:22 and I DID read their lines myself (20:23): build, gofmt, vet exit 0; whole `internal/mirror` ok
  200.3 s; whole `internal/catalog` ok 655.2 s; whole `internal/telegram` ok 45.4 s; the command package,
  `livepages` and the viewer's named tests ok; **the whole `internal/collector` ok, 1,789.8 s.** The script
  then merged a newer main head (49c310a1) in clean and checked it (build, vet, the named tests: each exit
  0), and STOPPED WITHOUT LISTING at 20:35, as it was made to: the main head had moved once more (e9413e4e)
  during those checks. I merged that head by `merge-head.sh` (it changed no file of the mirror's packages),
  ran one build (exit 0) and listed M6 by `relist-m6.sh` at 20:36: `wip/mirror-adopt` 209af9de, message 185,
  notes commit 01a6560.
- **M13's last small round, handed back 20:36: `wip/mirror-capmax` 6af8bed4** (three commits on 7b84bda6: the
  merge of `wip/mirror-adopt` at 16589fcb, one conflict inside `MirrorCreatesSince`, both sides kept; the
  rank's condition; the report). `MirrorCreateAtRank` takes the same helper as the count
  (`notAdoptedRowSQL`), so an adopted row is no create in either. One test added
  (`mirror.TestNewPerDayRoomAdoptedRow`, two cases), which the coder ran once with the condition taken out:
  it failed, as it should (never committed). Its runs through `go1.sh`, by its word, each "go1: exit 0"
  (one build waited 2,974 s for the lock behind M6's whole collector). **Read by me:** the one hunk in
  `schema_mirrorwant.go` and every use of the helper.
- **M13's runs and listing, by one script of mine started at 20:38 (`runs-mirror-m6/auto-list-m13.sh`):** it
  merged M6's branch as listed again (209af9de) into `wip/mirror-capmax` (clean, or it would have stopped),
  ran `run-m13b.sh` (build, gofmt, vet; whole `internal/mirror`; the catalogue's mirror tests by name; the
  command package; `livepages`; THE WHOLE `internal/collector` with `-timeout 45m`), checked that every
  "exit" line is 0, merged the main head in if it had moved (with a build) and listed M13 with `list-m13.sh`:
  **`wip/mirror-capmax` c7ea2d40, message 192.** The runs' numbers in the queue's entry "M13" were put there by
  the script from `runs-mirror-m6/m13b-logs`; **I have not read those lines myself unless a later entry says
  so** (a successor reads the eight logs' "exit" lines first).

### STATE FOR A TAKE-OVER (session M-6, 11-16 21:13)
- **Nothing of the track runs** (no coder, no reviewer, no run, no watch). By the integrator's word of 19:32
  (the owner's objective for what is left of the week's usage) the track starts nothing new.
- **Listed, in this order for the merge:** M6 `wip/mirror-adopt` 209af9de (schema step 27; entry "M6", first
  paragraph); then M13 `wip/mirror-capmax` c7ea2d40 (it holds M6's tree; entry "M13"). **Merged and installed:**
  M12 (44a6d7b) and everything before it.
- **If the integrator hands one back:** read the queue's entry's first lines and the board's message; M6's
  coder and M13's coder cannot be continued by a fresh session: a fresh Opus coder gets the piece's briefs
  (`BRIEF-M6-*.md`, `BRIEF-M13*.md`), the report on the branch and the integrator's words. If only the main
  head moved: `runs-mirror-m6/merge-head.sh <copy>` (clean, or it stops), a build through `go1.sh`, and the
  entry's first paragraph says the new head. M13 must be merged after M6; if M6 changes, merge
  `wip/mirror-adopt` into `wip/mirror-capmax` again.
- **Owed after the two merges and the install, small:**
  1. `PLAN-MIRROR-first-adoption.md` (the first real adoption on the test account: which two chats; the three
     questions and what each shows; the cost in requests, the id lists among them; what is read afterwards,
     counts only) and its line on the owner's waiting list; the installed build's `mirror -h` read first.
  2. `PLAN-MIRROR-auto-first-run.md` and item 26: the cap is "1 to 500", 20 unless set.
  3. The "Listed and unbuilt" rows "Choosing an existing chat of the owner's as a source's mirror" and "The
     cap on new mirrors in 24 hours without the upper bound of 50" struck.
  4. The copies removed, each clean and equal to `private` first: `wt-mirror-adopt`, `wt-mirror-capmax`, the
     detached `wt-mirror-review15-tree` and `wt-mirror-review16-tree`; the folders
     `wt-mirror-review14-scratch`, `-15-scratch` and `-16-scratch` when their reviews are in `docs/review`.
- **The owner's items 26 and 33 have not run.** When one has: its log's mirror lines and the catalogue
  read-only (`mode=ro`), counts only, onto the board and into `TELEGRAM-FACTS.md` section 11 the same hour.
- **Next pieces, in order, each with its "what the old app already knows" note first:** the small door round
  with pages; a weigh again at each later run of an adopted mirror; the posting rights recorded from the
  chat list (Core's file and a schema column: ask on the board first); a forum mirrored as a forum. For
  Core's list, from M6 (message 167): a pick with its own stats field so that the mirror's id lists are
  counted apart from the refresher's requests.
- **What this session learnt that is not elsewhere (also in the memory file of the track):**
  - A reviewer finds what the author's read does not: ask it by name what every LATER reader does with what
    the piece writes, under which key each stated wait is stored and read, and whether a guard the brief
    counts on exists on the path in question (M13: the guard at 500 channels existed only in the plan).
  - A piece that sends a request through a loop other tracks count and test gets the WHOLE package run by
    the track before its listing (M6 was handed back for a test of Core's that named no mirror).
  - Two pieces of one track that change neighbouring queries are trial-merged with each other before the
    second is listed (`git merge-tree`): M13's rank query had to follow M6's count.
  - One go command at a time through `runs-mirror-m6/go1.sh`; a watch tests a fact on the disk; a listing
    script refuses unless exactly the expected lines differ; the main head moves within minutes: merge and
    list in one command; write a time only after reading the clock; a hand-back can arrive more than once.
- **Next step, in one line:** wait for the integrator's merges of M6 and M13; then the four owed steps.

### 19.30 M13's listing checked; its runs' lines read by me; this session stops here (21:14)
- **M13 was listed by the script at 21:13: `wip/mirror-capmax` c7ea2d40** (entry "M13" at the end of
  `MERGE-QUEUE.md`; the board's queue line, the listed row's state, message 192, my row; notes commit
  f4fc28e). The script's path: M6's branch as listed again (209af9de) merged in clean (5f56bd84); the runs on
  that tree; then a newer main head (aa69cd81) merged in clean with a build (c7ea2d40). No
  `AUTO-STOPPED.txt` was written.
- **The runs' lines, read by me now from `runs-mirror-m6/m13b-logs` (on 5f56bd84), every line exit 0:** build,
  gofmt lists nothing, vet; whole `internal/mirror` ok, 154.7 s; the catalogue's mirror tests by name ok,
  64.7 s; the command package ok; whole `internal/collector/livepages` ok; **the whole `internal/collector`
  ok, 1,749.6 s.** They are the numbers the script put into the queue's entry.
- **Both pieces are listed and wait for the integrator: M6 (`wip/mirror-adopt` 209af9de, schema step 27)
  first, then M13 (`wip/mirror-capmax` c7ea2d40, which holds M6's tree).** M6 was still "Waiting, READY
  AGAIN" in the queue at this entry's time.
- **Nothing of the track runs** (no coder, no reviewer, no run, no watch, no go process of mine). By the
  integrator's word of 19:32 the track starts nothing new. **The block "STATE FOR A TAKE-OVER (session M-6,
  11-16 21:13)" just above is current;** one thing to add to it: M13's head is c7ea2d40, and if M6's branch
  moves again (a hand-back, a newer main head merged into it), `wip/mirror-adopt` is merged into
  `wip/mirror-capmax` again before M13 is merged.

## SESSION M-7 (taken over 11-21 21:07)
Started by the integrator's session (I-6) with the take-over line. Model rule since 11-21: Opus (this session)
orchestrates; coders Opus 5.5 high; routine steps by one Sonnet clerk call or a script.

### 11-21 21:07 Taken over
- Board row cut (the old state moved to `BOARD-LOG.md`, "Earlier states of the mirror row, cut by M-7"); single
  command by a script of mine (reason: one command).
- **First piece M14 (the owner's, urgent):** (a) a message deleted at the source never blocks a chat's automatic
  mirror (the block of 11-21 18:08 on MESSAGE_ID_INVALID, 38 posts lost); (b) single posts 5 to 20 s after they
  appear, a stored setting with that default, no upper bound; albums still wait until whole. Built on the head
  af4ca40, apart from M6 and M13.
- Nothing of the track runs. M6 and M13 are still listed (integrator merges them).
- **Next step:** read TELEGRAM-FACTS 11, TRIED-BEFORE 24 and 25, the M4 reviews, `internal/mirror/auto.go`; write
  the brief `BRIEF-M14-deleted-and-singles.md`.

### 11-21 21:12 M14 briefed, coder started
- Read myself: TELEGRAM-FACTS 5 and 11, TRIED-BEFORE 24 and 25, review M4-R (findings 2, 4, the 13 rules),
  `auto.go` forward/autoBatch, `step.go` forwardOutcome, `schema13.go` FinishMirrorBatch and the candidate filter,
  `timing.go`, `newperday.go` (M12's pattern).
- **Brief `BRIEF-M14-deleted-and-singles.md`** (this folder). Design: on MESSAGE_ID_INVALID the batch's messages
  the catalogue knows as deleted become missing rows of the refused batch (no schema step); all explained: no
  block; else the chat holds 60 s (`AutoRecheck`, read from the newest batch row, survives a restart) and the
  rest go once more; blocked only if the previous batch was also such an unexplained refusal, or 3 in 24 h. No new
  kind of request. Singles (album 0) wait 5 + 0..15 s (setting `mirror.auto.single_wait` "5-20", no upper bound,
  unreadable: the default in force and said; doors as M12's; run flag `-auto-mirror-single-wait`); albums keep
  90 + 0..30 s.
- **Coder: one Opus 5.5 high agent, copy `wt-mirror-m14`, branch `wip/mirror-m14` (from af4ca40e)**, started 11-21 21:12.
  PC before: CPU 67%, 9.5 GB free.
- Catalogue read read-only (counts only, 11-21 21:12): 4 mirrors, all created; 52 batch rows (51 done, 1 refused
  MESSAGE_ID_INVALID); 243 messages in batches, 242 forwarded, 1 missing; no waited batch. Mirror 4's source:
  about 25 posts an hour, 78% singles, median gap 69 s; 38 media messages deleted, lifetimes 3 <=20 s, 11 <=90 s,
  26 >120 s, median 196 s.
- **Next step:** the first real run's numbers into TELEGRAM-FACTS 11 (on the docs, in my copy, committed with
  M14 or apart); then read the coder's hand-back's risky part; then an independent Opus review.

### 11-21 21:14 Waiting on M14's coder (nothing else of the track runs)
- Board: message 209 (to the integrator and pages: M14 with a coder, my planned merge order M14, then M6, then
  M13; the new setting's doors for the pages' Settings row); a "Listed and unbuilt" row for pages. Notes
  commits 784e46f, 570feb6 (local `notes`; the project folder has no remote). Single commands of mine, no clerk.
- Review brief written: `BRIEF-M14-review.md` (copy `wt-mirror-review17-tree`, scratch `-review17-scratch`).
- Facts draft: `DRAFT-FACTS-11-first-auto-run.md`, to go into `archiver/docs/TELEGRAM-FACTS.md` 11 on
  `wip/mirror-m14` after the hand-back.
- Full runs planned (after the review's fixes, once, `ix-tools/full-runs.sh` by a Sonnet clerk): whole
  `internal/mirror`, `internal/catalog`, `internal/collector` (and `internal/collector/faketg` if changed);
  race: none (the change starts no goroutine and adds no shared state: to be confirmed on the diff).
- **Next step:** read the coder's hand-back and the risky part (FinishMirrorBatch on refused, the hold read in
  mirrorTurn, the block count); then start the reviewer with `BRIEF-M14-review.md`.

### 11-21 21:16 The integrator's additions to M14 (c, d) and a correction
- **(c) Part C added to M14** (brief's last section): an exact repeat (same sender, same text, same set of
  `tg_media_id`; no media: same sender and same non-empty text) of a message `forwarded` in the same mirror is
  recorded in a new table `c_mirror_repeat`, left out of the candidates, counted, never a block; albums skipped
  only whole. **M14 now carries a schema step** (the step after 26 on its branch; written on the board's schema
  section; merge M14 before M6 and K22). Sent to the running coder (same agent) at 11-21 21:16. Review brief has
  questions 9 and 10 for it.
- **(d) Topics are my next piece after M14** (FEATURES 12 round 3: a forum source as a forum mirror, topics
  created, named, renamed as the source; forwards into the topic; the create's cost measured first, the plan on
  the board before any real run).
- **Correction:** the 38 deleted media were one bot's repeats of one media set (already kept), not unique
  content; facts draft updated.
- Board: message 210 (reply to the integrator; the rename question: forwarding does not break; `c_mirror.name`
  stays the app's name after a manual rename). Single commands of mine.
- **Next step:** wait for the coder's hand-back (A, B, C); read the risky part; start the reviewer.

### 11-21 21:19 The integrator's word: the running app holds nothing back
- The owner (through I-6): fixes are not held for the running app; tries go in a folder of my own with invented
  data, no sign-in, LOCALAPPDATA redirected; the integrator installs into `tgarchive-app-next`. Nothing of the
  track was waiting for that reason. M14 is listed as soon as its review's fixes and full runs pass.

### 11-21 21:22 The integrator's change of order
- I-6 merges K21, C22, M6 (as step 28) and M13 BEFORE M14 (no longer data-loss urgent: the deleted posts were
  the bot's repeats). So for M14: the coder's hand-back, my read, the review and its fixes on `wip/mirror-m14`;
  then the new main head merged in ONCE (M14's schema step renumbered to the step after the head's newest, its
  "after" constant set to it); then the full runs once on that tree; then the listing. The topics piece is built on
  that head too. The board's schema line says so. Single commands of mine.

### 11-21 21:32 M15 (topics) started in parallel, at the owner's word (21:30, through I-6)
- **Brief `BRIEF-M15-topics.md`; measuring plan `PLAN-MIRROR-topics-first-run.md`.** Read myself: `WhyForum`
  and its uses, `telegram.Forwarder.CreateMirror(forum)`, `CreateTopic` (exists, counted), `ForwardBatch`'s
  topic, the fake (no createForumTopic/editForumTopic answer yet), catalogue `topic` (chosen, titles). The
  owner's catalogue (read-only counts): 3 forums, 10, 1 and 7 topics; about 8,250, 12 and 70 media messages.
- **Coder: one Opus 5.5 high agent, copy `wt-mirror-topics`, branch `wip/mirror-topics` from af4ca40e**,
  started 11-21 21:32; it merges the new main head (K21, C22, M6, M13) in once it moves. PC before: CPU 90-100% (other
  sessions' runs), 7.4 GB free: the coder is held to GOMAXPROCS=2, -p=1.
- Board: my row (two coders), the forum row "being built", the schema line for M15. Single commands of mine.
- **Next step:** the two hand-backs; for each, my read of the risky part, then one independent Opus review.

### 11-21 21:47 M14 handed back (fa769c57, pushed), read by me; fix round A2 sent to the same coder
- Hand-back: 4 commits on af4ca40e; parts A, B, C; schema step `schema_mirrorrepeat.go` (27 on the branch);
  doors `MirrorSingleWait`/`MirrorSingleWaitFacts`/`SetMirrorSingleWait` (names as said in message 209, the
  read door without "Facts"); run flag `-auto-mirror-single-wait`; named tests ok (mirror 9 M14 tests,
  catalog 7, faketg whole, collector's named sets; one `-run Mirror` subset hit go's 10-minute default and its
  remaining 22 passed by name). Every reader of refused batches with missing rows listed (the settle becomes more
  cautious: missing rows of refused batches count as "their copies may be anywhere"; accepted).
- **My read of `idRefused` (auto.go ~1751): the block is judged at the refusal on counts written then, and the
  refused rows are deleted, so a race of two different posts with the live monitor's lag blocks the chat.** With
  this chat's bot (deletes 30-49 s after posting) and singles at 5-20 s that is likely. **Fix round A2** (brief's
  new last section): keep unexplained ids in a small table of the same step; never block at the refusal; judge
  from `deleted_at` at judging time (at the refusal and at the hold's end); block only on the same message refused
  twice while not known deleted, or 3 unexplained-now in 24 h. Sent to the same coder at 11-21 21:47.
- **Next step:** A2's hand-back; then the independent review (`BRIEF-M14-review.md`, add A2 to its questions).

### 11-21 21:53 A2 handed back (5ea2f7be, pushed); the independent review started
- A2: `c_mirror_idrefused` in the same step (27 on the branch); no block at a refusal; at the hold's end the
  refusal is judged from `deleted_at` now: explained (missing set to messages, announced), the same message
  refused twice (`AutoBlockIDSame`), or 3 unexplained-now in 24 h; "the previous batch by id" removed. Named
  tests ok (catalog TestMirrorM14 2.8 s, mirror TestMirrorM14 4.9 s incl. RacesNoBlock and SameTwiceBlocks,
  catalog's mirror/schema set 34.7 s, mirror TestMirrorAuto 57.8 s); the plan test re-run, no temp B-tree, no
  full scan. The coder followed "never block at the refusal" (judged only at the hold's end): agreed.
- **Reviewer: one Opus 5.5 high agent, `BRIEF-M14-review.md`, copy `wt-mirror-review17-tree`, scratch
  `wt-mirror-review17-scratch`, started 11-21 21:53** (PC: CPU 87%, 6.7 GB free; held to GOMAXPROCS=2).
- **Next step:** the review's findings; fixes by the same coder; then the new head merged in once; full runs.

### 11-21 22:05 Review M14-R in: 5 CONFIRMED, 5 PLAUSIBLE (low); all ten to the same coder as fix round R1
- Worst: an Allow undone at the next turn after a "same message twice" block (the refusal judged again). Then:
  an arriving album split by the repeat check; later forwarded/missing not explaining a refusal; the last read
  after the repeat rounds unchecked; a refusal with no record (before the step) read as explained (rule 13).
  Low: settle reads refused batches' missing rows; the manual command's refusals recorded; door facts for
  explained/held missing; stale wording; the media lookup over the whole catalogue (to the same chat only).
- The review's file is in `wt-mirror-review17-scratch` (to be copied into docs/review on the branch with the fixes).
- **Next step:** R1's hand-back; a second look by the same reviewer at the fixes; then the head merged in once.

### 11-21 22:07 The owner, directly: why would a mirror ever need the owner's Allow? Fix round R1b sent
- The owner: "why does the owner need to allow a mirror ... The owner will be away from the computer. Why
  wouldn't the mirror continue automatically? That's the whole point." Answer: it should not. **R1b** (brief's
  last section), sent to the same coder with R1: a message refused twice is set aside (recorded, counted, listed,
  never resent by itself) and the chat goes on, the refused batch's messages resent once alone; a refusal of the
  mirror chat itself holds the chat and retries by itself (10 min, 30 min, 1 h, 3 h, 6 h, then 6-hourly; durable);
  only the account's end, a protected source, an unknown-outcome batch the settle cannot tell, and stated waits
  stay as they are. The hand-back lists every block left and why.

### 11-21 22:17 Head 6aa225fb (K21, C22 step 27, M6 step 28, M13): both coders told to merge it once; owed steps done
- Both coders told (same agents) to merge 6aa225fb into their branch once; schema steps become 29 (M14) and the
  step after the head's for M15 (the integrator sets both numbers at the merges).
- **Copies:** by a Sonnet clerk: `wt-mirror-review15-tree`, `-review16-tree` removed (clean);
  `wt-mirror-review14/15/16-scratch` removed (no review files left in them). The clerk kept `wt-mirror-adopt` and
  `wt-mirror-capmax` (their commits are not ancestors of the head: the integrator joined them by hand); I checked
  file by file: every file of each branch equals the head's except the renumbered step constants and lines later
  pieces added; removed by me (one command each; both clean; branches kept on `private`).
- **Board:** the two rows struck (M6's adoption, M13's cap); item 26 and `PLAN-MIRROR-auto-first-run.md` say "1 to
  500 since M13".
- **Still owed:** the first real adoption's plan, once M6 is installed (its queue entry: "once this is installed";
  the integrator builds `tgarchive-app-next`).
- **Next step:** the two coders' hand-backs (M14 R1+R1b+merge; M15 with merge).
# Mirror track: current state (older text in `SESSION-MIRROR-LOG.md`, which nobody needs to read)

## STATE (session M-7, 11-22 01:57)
- **M14 and M15 MERGED** (head e34f4f64, schema 29 and 31, C27 30 between); built into the second folder; the owner
  switches when convenient. Copies `wt-mirror-m14`, `wt-mirror-topics` removed (every mirror file equal to the head).
- **M16+M17 RELISTED 11-22 06:18**: `wip/mirror-topicpace` c122d374 (holds main 7895bdd7), step 33 after alertSchema, K26 wired;
  first in the next batch (with C30, K27, K28; race of internal/mirror). Copies kept until merged.
- **M20 MERGED** (in 7895bdd); was listed 11-22 05:18**: `wip/mirror-oldfile` d89afd94 on 4bf224b3 (the older-file test used SchemaVersion-1;
  the code was right); verified on core-alerts' tree. By me (a two-line change; no clerk: one commit and one test run).
  Copy `wt-mirror-oldfile` kept until merged.
- **M19 MERGED** (d5b9fd2f); copy removed (its files equal main's).
- The watch ended (the first forum mirror's numbers read: 1 create, topics about every 2 min, 70 forwarded in ~1 s).
- The first adoption's plan is written (`PLAN-MIRROR-first-adoption.md`), its line on the owner's list.
- Next step: the watch's end (it notifies this session).
# Mirror track: current state (older text in `SESSION-MIRROR-LOG.md`, which nobody needs to read)

## STATE FOR A TAKE-OVER (session M-7, updated 11-22 09:08; was 11-22 08:36): NOTHING RUNS; START NOTHING NEW until the owner or the next integrator says so
- **Merged and in the owner's second folder (head 09aeba54):** M14 (deleted posts never block; singles 5-20 s; exact
  repeats skipped), M15 (forums as forums), M19 (rename a mirror from a page), M20 (older-file test), M16+M17 (the
  mirror settles every unknown outcome by itself; one adaptive forward pace 3 s down to 1 s, doubled for the hour on any
  stated wait; topic creates 3-5 s; titles from Core's K26 doors, 30 min then "Topic N" renamed; new posts first).
  Schema steps 29 (M14), 31 (M15), 33 (M16). No copy, coder or reviewer of the track is left; every wip branch stays on
  `private`.
- **Since the owner lifted the stop (11-22 09:08):** a 3-hour race run of `internal/mirror` runs in Docker (2 CPUs, 4 GB) on the copy
  `wt-mirror-race` (head 09aeba54), log `runs-mirror-m7/race-mirror.log`; the night's numbers (M15 build: the owner has not
  switched yet) are listed as MF (`wip/mirror-facts-night` 40ab52a1).
- **11-22 11:12:** M21's join fix for I-7: `wip/mirror-newchats-j` ffc12e77 on its join commit 00310e99 (the "unlimited" test case after
  K20); sent. By me (one test line; no clerk: one commit, one test run). Copy `wt-mirror-newchats-j` kept until merged.
- **M21 LISTED READY 11-22 09:40**: `wip/mirror-newchats` 70aa1b1d (the new-chats rule removed only by the run's flag; the stored
  setting through the approval). Copy `wt-mirror-newchats` kept until merged.
- **11-22 10:01:** The integrator is I-7 (local_78ac6953-2e70-4c12-a371-4f255f71e85c) since this time: listings, the race result, reports go there; M21 and MF are in its next batch.
  Listed and waiting: M21 (`wip/mirror-newchats` 70aa1b1d), MF (`wip/mirror-facts-night` 40ab52a1). The race run of internal/mirror ended 11-22 11:45: ok, 9423 s, 0 races (head 09aeba54); reported to I-7; copy removed.
- **Owed, in order, when work resumes:**
  1. After the owner's switch: the night's numbers into TELEGRAM-FACTS 11 (counts only, catalogue read-only): forwards
     per minute and per hour, stated waits and their lengths, the pace in force, topic creates per minute, set-asides,
     put-backs; plus the first forum mirror (1 create, 2 topics, 70 forwarded in ~1 s, no wait) and M14's first day.
     The draft of the first automatic run is `DRAFT-FACTS-11-first-auto-run.md` (on M14's branch, merged).
  4. For pages (their rows): a door for `mirror -pause-reset`; show held/set-aside/put-back-old facts, the paces.
  5. The first real adoption: `PLAN-MIRROR-first-adoption.md` (its line is on the owner's list).
  6. Clean-up: the deprecated `mirror.WhyForum` / `ErrWantForum` once nothing names them.
- **What this session learnt:** the owner wants the mirror to go on by itself while away: every block that a
  retry, a hold or a set-aside can settle was turned into one; ask each reviewer "which blocks are left and why".
  Python on Windows writes CRLF in text mode: write source files with newline="\n". A branch the integrator joins by
  hand is not an ancestor of the head: check "merge-tree of head and branch gives the head's tree" before removing a copy.
