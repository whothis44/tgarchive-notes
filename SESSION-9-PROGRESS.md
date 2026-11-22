# Ninth archiver session: where it stands (written 2026-11-13 night, while the race run was going)

For whoever picks this up if the session is interrupted. The handoff in `repo-archiver` is NOT yet updated:
the clerk's step 5 needs that checkout clean, so nothing there may be edited until the clerk has finished.

## The piece: the "leave and count" counter

- **Brief:** `archiver/docs/LEAVECOUNT-BRIEF.md` (in `wt-leavecount`, and an identical untracked copy in
  `repo-archiver`).
- **Built** by an Opus coder in `wt-leavecount` (detached at 1011ad8), NOT committed when this was written.
  Report: `wt-leavecount/archiver/docs/progress/leavecount-REPORT.md`; progress file beside it.
- **Judged by the main session** (read: `inflight.go`, `tracer.go`, every send-site change in
  `internal/telegram`, the `ConnWatch` changes, `schema10.go`, the catalogue and `tgstore` changes):
  accepted. The main session added one line itself: `Counters: a.ctr` in `internal/collector/signin.go`
  (the sign-in's `SignInConfig`), which the coder could not (outside its files).
- **Commit message:** `wt-leavecount/archiver/docs/progress/leavecount-COMMIT-MSG.txt` (not to be committed
  itself).
- **Clerk (Sonnet), running:** gofmt and vet; the collector's tests on Windows; the race detector in Docker
  (container `tgarchive-race`, `--cpus 3`, four packages: telegram, tgstore, catalog, collector; compile
  step apart); then, only if all pass: commit in `wt-leavecount`, fast-forward
  `claude/charming-feynman-vm2xia` in `repo-archiver`, push to `private`. The race run covers the owed run
  for e8f6e04 too (the collector package).
- **If interrupted:** `docker ps` first. If `tgarchive-race` is gone and `wt-leavecount` is still at
  1011ad8 with uncommitted files, the race run must be done again before any commit. Never commit without
  it.

## What the counter is (for the handoff and the roadmap row)

- Per kind and hour in `c_tg_hourly`: `in_flight_at_loss`, `under_wait_at_loss`,
  `in_flight_at_new_session`, `under_wait_at_new_session`. Per server and hour in `c_conn_hourly`:
  `new_sessions`, `new_sessions_after_sends`. New kind row `auth_transfer`; the sign-in's go in `sign_in`.
- Catalogue schema 10 (columns added, default 0). **The real test catalogue is at 9: copy the file before
  the new program first opens it.**
- Upper bounds: a pool loss counts all of that server's parts and hashes in flight; on the home server the
  main connection and its pool are counted together.
- Not counted: resends after a bad message id, a salt change, a key re-made in place. Not seen: a new
  session announced inside a compressed message.
- Roadmap row "Count of requests in flight when a connection is lost": none -> **fake** once pushed.
- Coder's measures: tracer 3.4 to 8.6 ns a message, 0 allocations. Six mutations, each caught.
- Not verified: anything against Telegram; a pool loss on the loopback server (fakes only).

## Decided with the owner this session (11-13 night)

- **A3 downloads the whole test chat** (741 files, 17.8 GB), "as long as you can tell me when to stop it".
- **A3 is automated by the main session**, with the owner's permission, the owner present for the first
  start. The owner's A2 command (no secret in it):
  `run -db %LOCALAPPDATA%\tgarchive\test\catalog\catalog.sqlite -staging ...\test\staging -library
  ...\test\library -no-links -vpn-adapter WindscribeOpenVPN -public-forbid <the address api.ipify.org gives
  outside the tunnel>`; for A3 without `-no-downloads` and `-approve-read 4`. The owner does not mind this
  chat's privacy; numbers only all the same.
- **Disk:** the owner freed about 130 GB (was 64.3 GB free on the disk of staging and the test library;
  the default keeps 50 GB free). Measure again before the run.
- **The old app's code is the private `whothis44/tg1`** (12.30). For stage B (sampled-frame check, copy
  checks, kept and staged parts reused) read that code there, in full, before any brief (the owner:
  "a lot of useful stuff in there").
- The owner archived the sessions 4 to 8 and the orchestration handoff (memory was short; 6 to 7 GB free
  afterwards).

## Still to do in this piece

1. Clerk's report: check the pushed commit and the branch myself.
2. Handoff: fold into the current-state block (the tenth session starts there); roadmap row; this file's
   content; push.
3. `START-SESSION-10.md` in the project folder; commit the notes repository.
4. Remove `wt-leavecount` once pushed.

## The tenth session's piece: A3 (nothing of it is done)

Read first, not read by the ninth session: `internal/engine` (start, lanes, checkpoints), the collector's
`staging.go`, `supply.Recover` and the staging sweep, the `run` command's output lines (confirm they carry
no names), and whether the collector has a clean stop other than Ctrl-C. Then: rebuild the collector to its
fixed path with nothing running; copy the test catalogue; tell the owner what a downloading run sends, the
kill moment, the stop rule and what silence means; run it (start, hard kill mid-video, restart, about an
hour of numbers, stop); numbers from `c_hourly`, `c_tg_hourly`, `c_conn_hourly`, `status`.

## Added later the same night

**The owner changed the order of work** (in `CLAUDE.md` and memory `archiver-working-mode`): build in
parallel and as efficiently as possible; "real runs before more code" is dropped; the old account is not
expected to move before its cutoff; no separate 24-hour run (A3 runs on overnight until the chat is done:
that is A5); several coders at once; a session lands several pieces; never wait idle on agents.
**The old app's session can answer questions about waits** (the owner): write them in a QUESTIONS file for
the owner to pass on (memory `fork-session-contact`); none needed for A3 so far.

**A3 reading, done so far by the ninth session** (`engine.go` in full; `collector.go` `Run`;
`command.go` `RunCommand`; `staging.go` to line 275):
- A start prints: `collector: start-up: N active files given back; M finished downloads replayed`
  (`supply.Recover`), then `collector: start-up sweep: K parts kept, P published, R removed, ...`
  (the writer's sweep), then `collector: running: A accounts, S signed in`. Those three lines are what the
  restart after the kill must show (N and K above 0).
- Engine defaults: checkpoint every 8 MiB or 30 s for files of 8 MiB or more; a smaller file starts over;
  a part with no answer for 2 minutes is a timeout; stop grace 5 s. Holds (waits) of an earlier run are
  loaded before any lane starts.
- **No clean stop other than a signal** (Ctrl-C or SIGTERM; a second one forces). Go on Windows takes
  CTRL_BREAK as an interrupt too, so the main session can stop it cleanly with a console control event
  sent to the process group: to be tried at the first stop, with a hard kill as the fallback.
- Without `-nas-helper` and without `-read-back-now`, a copy's read-back is put off to speed-limited
  hours: for A3 add `-read-back-now` so that "files verified" is a number of the run (to tell the owner).
- `-keep-free-gb` exists (0 means 50).
- `run`'s own lines are fixed words and numbers (help text says so; the lines read so far are).
- NOT read yet: `lane.go` (claim, checkpoint, resume, the refresh at claim), the `fetch` table's resume
  columns (to pick the kill moment from the catalogue read-only), `internal/store` (writer, sweep, copier),
  `account.go`'s session start (which lanes and pools a run opens).

**More A3 reading (lane.go: open, ckptDue, checkpoint; account.go: lanesOf, startEngine):**
- A checkpoint syncs the file, then writes one row in `c_progress` (tg_media_id, account_id, offset,
  prefix_sha256, updated_at): one row per file with a checkpoint. **The kill moment is read from there,
  read-only: kill when a row's offset is 16 MiB or more** (two checkpoints in), so the restart has a
  prefix to re-hash. On restart `lane.open` loads the row and the writer says where it starts.
- The engine gets one lane per server the account has wanted files on (`lanesOf`): for the test chat
  servers 2, 1 and 4, so three file pools; the two that are not the home server (1) make an authorisation
  transfer each unless the session file already holds their key.
- Race run at the time of writing: about 55 minutes in, on the catalog package, the collector package
  still to come.
- Still NOT read: the claim and the refresh at claim in `lane.go`, `internal/store` (writer, sweep,
  copier), `supply.Policy` (the window the engine really gets).

**A3 reading, third part (`supply.Policy`, `engine.NewCareful`, `store/writer.go` Open/resume/place,
the sweep's doc):**
- Window the engine starts with: 2 parts a server, floor 2, ceiling the setting (default 4); grows only
  after 2 minutes with no wait; any plain wait steps down and holds 10 minutes (the trap of
  TRIED-BEFORE 23); 2 fixed under the speed limit. Report its steps; no comparison with the old app.
- Resume: the part file is `.tga-<random>.part` in the staging root; the token in `c_progress` carries
  the prefix's SHA-256; on restart the prefix is read and hashed again and must match, else the file
  starts over (counted `ResumeRestarted`; a good resume: `Resumed`, `ResumeBytes` in the store's hourly
  counts). A resumed part in staging also needs room for the rest above the keep-free floor.
- Sweep at start: a part a resume token names is kept; a part no row knows is removed (so a video killed
  before its first checkpoint is fetched again from zero: expected, not a fault).
- **A3 plan:** (1) copy the test catalogue; rebuild the collector at the pushed commit; free space
  measured. (2) Start with the owner's A2 command less `-no-downloads` and `-approve-read 4`, plus
  `-read-back-now`; output to a log file. First lines to check: VPN verdict allowed, the two start-up
  lines, "running". (3) Photos go first (smaller first). Watch `c_progress` read-only; when a row's
  offset is 16 MiB or more: hard kill (`Stop-Process -Force`). (4) Count what the kill left: part files
  in staging, `c_progress` rows, active files. (5) Restart: "N active files given back", "K parts kept",
  then the store's `Resumed`/`ResumeBytes`. (6) Leave it running; stop cleanly (console break event;
  fallback hard kill) when the chat is done or in the morning. (7) Numbers from `c_hourly`,
  `c_tg_hourly`, `c_conn_hourly`, the store's hourly counts, `status`.
- NOT read: the claim and the refresh at claim in `lane.go`; the copier's steps; the store's hourly
  table name.

**A3 reading, fourth part (`lane.go` claim 300-457, refreshLoop 2000-2130):**
- A lane claims files for its free file slots (5 small, 2 large per server), opens each (resume checked
  there), then marks each claimed file stale: its reference is refreshed in a batch (up to 200 files, one
  request per chat per 200 ids, on the main connection) before its first part is asked. With 7 file slots
  a batch is small: expect roughly one refresh request per claim round, a few hundred for 741 files.
  A wait on a refresh holds the account's refreshes only; parts with a fresh reference go on.
- **What a downloading run sends (for the owner):** per connection its first request (the main one and
  each connection of a server's pool: up to ceiling + 2 = 6 per server); the chat list (2 requests), the
  live updates' state or difference, the account's own user once; for servers 2 and 4 one authorisation
  transfer each (2 requests) unless the session holds their keys; refreshes as above; file parts of 1 MiB
  (about 17,900 for the whole chat), 2 in flight per server at the start, up to 4.
- Not seen in the download path as read: any part-hash request (`Hashes`/`Verify` have no caller read
  so far; to confirm with a grep before the run).
- **Started in parallel (really): an Explore agent maps where the four stage B features live in the old
  app's 12.30 code (`wt-v12.30`, e18f80a, local): exact re-upload check, look-alike hold, sampled-frame
  check, kept parts.** Its map is for the main session's own reading, not a substitute for it.

## Stage B: where the old app's code is (map by an Explore agent, 11-13 night; `wt-v12.30`, e18f80a)

Short names: A = core-service/internal/app, T = .../telegram, D = .../download, E = .../engine.
Order of steps in a download: `D/library.go` `Ingest` :250 (identity reuse :278, adopt orphan :292,
same-size wait :296, **Substitute :309** (B1), **Check :331** (B3, skipped on a resumed attempt),
staged :336, resume :341, transfer :378). Hooks wired in `A/app.go` :248-252.
- **B1 exact re-upload check:** `A/ix_subst.go` (504 lines: plan :82, byHashes :146, sampleOffsets :192,
  bySamples :230, `ixSubstitute` :304, candidates :473; floor 256 KiB, hash chunk 131072, at most 64 hash
  calls, up to 5 saved files of the same size, a 10-minute memo), `T/ix_parts.go` (148: `MediaFileHashes`
  :56), tables `ix_subst`, `ix_subst_block` (`A/ix_schema.go` :161, :171), setting `substExact`.
- **B2 look-alike hold:** `A/ix_held.go` (1105: `ixHeldStep` :207, `ixHeldTriage` :524, `ixHoldWork` :629,
  `ixHeldRecheck` :760, `ixLetGo` :957, floor 256 KiB :364), `A/ix_copies.go` (625: `ixCheapSame` :179,
  `ixCoversSaved` :211, `ixSavedCopyOf` :532), `A/ix_media.go` :36 (shape slack 0.02); tables `ix_held`,
  `ix_copy_hold`. A background task, not in the transfer path. Old single-query rule `ixLikelyCopy` is
  used only by lower-quality-first.
- **B3 sampled-frame check:** `A/ix_dl_check.go` (632: `ixDlCheck` :288, the live in-download hook),
  `A/ix_copies_sample.go` (1372: `ixRangeFile` :235, `ixSampleFrame` :475, `ixSampleCheck` :609,
  `ixSampleRecord` :1215; 8 points, 3 hits, 32 parts at most), `A/ix_sample_recheck.go`,
  `A/ix_check_from.go` (floor 20 MB), `A/ix_vdup.go` (saved fingerprints, `ix_vfp`); tables
  `ix_copy_sample`, `ix_check_putback`.
- **B4 kept parts:** `A/ix_part_store.go` (500: `ixPartsKeep` :114, `ixKeptPartsFor` :260; cap 100 GiB,
  free floor 60 GiB), `T/kept_parts.go` (104), `T/parallel_download.go` :99-119, `T/attachment.go`
  :611-651; in-memory parts for one attempt in `A/ix_dl_check.go` :570-627; table `ix_part_store`.
  Resume (separate): `D/resume.go`, `D/manager.go`, `D/staging.go` `ingestStaged` :416, `followStaged`
  :514 (a file staged for another message is reused).
- No design document for these: the design text is each file's header comment; history in
  `CHANGELOG.md` (ix.12.5, 12.10 to 12.13, 12.25, 12.26).
The main session reads these files itself before each brief.

**Stage B1 (exact re-upload check): the main session read the old app's `ix_subst.go` and `ix_parts.go`
(12.30) in full and `COPY-CHECKS-STUDY.md` section E, and wrote the brief: `BRIEF-B1-exact.md` in the
project folder** (to move into `archiver/docs` and start an Opus coder from the branch AFTER the counter's
commit: it needs schema 11 on top of 10). Not read for it: the old app's `library.go` (the coder's brief
names it), the new app's `ladder.go` past line 90, `state.go`.
**Questions for the old app's session: `QUESTIONS-for-fork-4.md`** (hash windows per answer, dedup counts,
holds by evidence, sampled-check outcomes, kept parts, waits). The owner passes it on.

**Race run, as read from the container at 00:52 UTC (11-14):** compile step 8 minutes; under the race
detector `telegram` ok in 41 s, `tgstore` ok in 175 s, `catalog` ok in 3,489 s (58 minutes, one core: its
scale test), `collector` started 00:51 UTC. Next time: one container per package side by side, and the
catalogue's scale test apart, so a race run does not gate everything for two hours.
**The B1 coder (Opus) was started at about 00:55 UTC in `wt-exact`**, on a temporary local base commit
bbf8ad7 (the counter as built, parent 1011ad8; made with a separate index so the clerk's checkout was not
touched; never pushed, on no branch). When the clerk's real commit exists, B1's work is moved onto it (the
trees are the same but for the commit-message file). Brief in that copy:
`archiver/docs/EXACT-CHECK-BRIEF.md`; its progress file `archiver/docs/progress/exact-PROGRESS.md`. It may
use 4 cores (the owner, tonight: run things faster, resources were freed).

**Stage B2 (look-alike rule):** the main session read the old app's rule in 12.30 (`ix_held.go` 23-183,
520-655, 756-912; `ix_copies.go` 123-213, 498-540; `ix_vdup.go` `ixPHash`) and the new app's present rung
6 (`ladder.go` `lookAlike`), and wrote `BRIEF-B2-lookalike.md` (project folder). Two parts: (a) a pure
package `internal/lookalike` (preview hash equal bit for bit to the old app's, the alike / covers / better
/ group rules), **started about 01:10 UTC with an Opus coder in `wt-lookalike` (from 1011ad8; it touches
only the new package, so it cannot collide with B1)**; (b) the catalogue wiring (a `phash` column, rung 6
replaced, queued twins, recheck and promote), to be briefed after B1 has landed because B1 is in the
catalogue.
**Memory at that moment: 1.66 GB free** (race container, two coders, the browser). Both coders are told to
check before each run. No fourth agent until the race run has ended.

**About 01:25 UTC: the owner freed memory (6.8 GB free).** Started the owed **independent challenger
review of the counter** (Opus, read-only on `wt-review-lc` at bbf8ad7, probe tests by overlay from
`wt-review-lc-scratch`, 3 cores; its review goes to `wt-review-lc-scratch/REVIEW.md`, progress beside it).
It must be read and its blocking findings fixed before A3 runs. Four background jobs now: the collector's
race run (clerk), the B1 coder (`wt-exact`), the B2a coder (`wt-lookalike`), the reviewer.

**B2a landed locally (about 01:40 UTC):** the look-alike package, judged by the main session (the rules
file read in full; the hash file's shape checked against the old source), committed in `wt-lookalike` on
top of 1011ad8 (see `git -C wt-lookalike log -1`). NOT on the branch and not pushed yet: cherry-pick it
onto the branch after the counter's commit, then push. The coder's findings to carry into part b: the
grouping window is 500 ms or 2% of the duration when that is more; "same shape" measures the 2% against
the first file's ratio (order matters at the edge); equality with the old app was proven against the old
source compiled here, not against a hash the old app stored (ask the old app's session for a few
hash values of invented previews, or compare at the bring-in). One briefed mutation (DC in the median)
cannot change any hash: proven in the report.

**11-14, the owner on B2:** "same shape" measured against the first file's ratio "seems like it could be
improved": make it symmetric in part b (measure against the larger ratio: every pair the old rule held in
either order is still held; the difference is at the 2% edge only), with a test that both orders agree and
a note that this is the one deliberate difference from the old app's rule. And: real hashes may be asked
of the old app's session (a hash is fine). `QUESTIONS-for-fork-4.md` now has section E: four invented
previews (hex) with the new app's hashes for the old app to compute too, and a fallback with real hashes.

**About 02:00 UTC: the challenger's review of the counter is in:
`wt-review-lc-scratch/REVIEW.md`** (probes beside it). Verdict: it may run for real as it is (no change
of behaviour found: errors, contexts, locks, the hot path, the schema step, privacy all sound), **but the
counts come out too high**: F1 (confirmed) every failed or refused dial is an OnConnDead and counts every
request in flight again (one request counted 9 times in 6 s of refused dials); F2 (confirmed) several
connections of a pool dying together count the server's parts once per connection; F3 (the tracer's
reaction confirmed, Telegram's sending it plausible) a connection's first message re-sent after a bad
message id makes its first session look "after sends". Minor: F4/F5 known gaps, F6 no copy before the
schema step (copy the real catalogue by hand: already in the A3 plan), F7 doc.
**Decision of the main session:** A3 may run with the counter as it is; a fix coder (Opus, `wt-lcfix`
from bbf8ad7) makes F1-F3 right at once, to land as a second commit before the numbers are read:
a request is counted at most once per kind of event in its life; a dial that failed or was refused counts
nothing; "after sends" only once a request has completed in that session; the three probes become tests.

**11-14, the owner on test runs:** targeted tests while working; full suites and the race detector once,
right before a merge; side by side, using the cores. Written into `CLAUDE.md` ("Tests in the new app") and
memory `agent-load-limits`. Settings audited: no hooks anywhere; nothing forces re-testing but my own
briefs. For the next race run (B1, the counter's fix): one container per package at once.

**20:30 local (01:30 UTC): the clerk reported: all passed; the counter is c2da755 on the branch and on
`private`.** The main session then: cherry-picked the look-alike package (adc4f8f); copied the test
catalogue (`catalog-v9-before-A3.sqlite`); kept the old program (`-e8f6e04.exe.bak`) and built the
collector at adc4f8f to its fixed path; wrote the new current-state block at the top of the handoff's
section 0c and three roadmap rows; committed and pushed. 187 GB free on the test disk. **A3 is ready to
run** (the handoff has the steps). Still running: the B1 coder (`wt-exact`), the counter's fix coder
(`wt-lcfix`).

**About 20:50 local: the counter's fix came back** (`wt-lcfix`, uncommitted; report
`archiver/docs/progress/lcfix-REPORT.md`). Read by the main session (the changed lines of `inflight.go`,
`tracer.go`, `options.go`): accepted. Once per kind of event (a sequence number per request and a mark per
gauge); a loss counts in flight only when OnConnDead's error is the very value the tracer saw at the end of
a connection that had sent; "after sends" needs an answered request in the session. The probes now give
[1 1 0 0] (was [9 9 0 0]), 4 (was 16), no after-sends. **Sent back for three follow-ups:** the tgstore
test it could not edit; a guard against a silent undercount (two in-memory counts and one collector log
line: connections ended after sending, and how many were matched to a reported loss); a comment.
**Before it merges (the new test rule):** full tests of `telegram` and `tgstore`, the named collector
test, and the race detector on `telegram` and `tgstore` only, two containers side by side (41 s and 175 s
last time). Then rebuild the collector: A3 should run with the fix in.

**About 21:05 local: the A3 scripts exist and were tried** (project folder `a3/`):
- `a3-start.ps1`: starts the collector on the test catalogue with the owner's flags plus `-read-back-now`,
  hidden window, output to `a3/logs/run-<time>.out.log` and `.err.log`; writes `a3.pid`; prints the process
  id only (the public address is passed on, never printed).
- `a3-stop.ps1`: a clean stop (a helper process attaches to the collector's console and sends Ctrl-C);
  `-Hard` kills. **Tried on a harmless `ping -t` started the same way: it stopped cleanly on the Ctrl-C.**
  Not yet tried on the collector itself.
- `a3-watch.py`: read-only counts (wanted by state, `c_progress` offsets and ages, files saved and
  verified, part files in staging, files in the library; `hours` adds the last rows of `c_hourly`). Tried:
  schema 9, 741 wanted, nothing else yet.
**The owner is around tonight for the first start.** Waiting only for the counter's fix to merge and the
rebuild.

**About 21:20 local: B1 (the exact check) came back** (`wt-exact`, uncommitted; report
`archiver/docs/progress/exact-REPORT.md`). 11 files modified, new `internal/exact`, `engine/check.go`,
`catalog/exactcheck.go` and `schema11.go`, `store/saved.go`. The main session read `engine/check.go` in
full (the check runs on its own goroutine after the refresh, holds a file slot and no window slot; a wait
on a hash call is kept like a part's; Same and Probable retire the file through the writer; a late result
is dropped): accepted as a design. **Decisions still to send the coder, with the review's findings in one
go:** "three places match: held" applies to video only (the old app's measured rule); every other kind
over the bound is unknown and downloaded. **Started, side by side:** a clerk running the race detector on
its six packages (one compile, then five containers at once, `tgrace-*`; the catalogue with `-short`,
its scale test left out under the race detector), and an independent reviewer
(`wt-review-exact-scratch/REVIEW.md`). **B1 is NOT in the A3 build:** A3 runs the counter and its fix
only; the exact check's first real step comes after its review, with one hash request measured first.

**About 21:30 local: usage.** The owner: the plan is at 94% of the week, resetting on 11-14; saving
progress matters, and a new session when it helps, with no costly wake-ups overnight. So:
`START-SESSION-10.md` is written (short start, what is running, A3 tonight, what follows). The ninth
session answers its three jobs' notices in one line each and does no more reading.

**20:45 local by the PC's clock (the times "21:05" to "21:30" written above were my estimates and about
an hour ahead: the PC's clock is the truth).** For a run nobody watches: `a3/a3-sample.py` (one JSON line
a minute, numbers only; per-file sizes and times at the end) and `a3/a3-sampler-start.ps1`; tried once
(schema 9, 741 wanted, 186 GB free). `START-SESSION-10.md` now has the logging layers and the three cases
for the old app's answers. CPU was at 90% at that moment (five race containers, the fix's three runs, the
reviewer): the fix's runs end within minutes; nothing more is started until they have.

2026-11-13 (evening): The fix for the leave-and-count counter was tested and landed. Format and vet were clean. Three runs went at the same time and all passed: the collector package on Windows (368.7 s), and the telegram package (58.0 s) and the tgstore package (284.0 s) under the race detector in Docker. The work was committed in the side worktree (e0c9c24), brought onto the branch claude/charming-feynman-vm2xia as 92bb821, and pushed to the private repository. No collector process was running, so the program was rebuilt from 92bb821 (about 34.8 MB, 20:47).

**About 21:00 local: the exact check's independent review is in:
`wt-review-exact-scratch/REVIEW.md`.** Verdict: merge after 4 fixes. No way to a wrong "same" found
(3000 hostile hash answers). Blocking: F1 a file checked again while its first check's record is written
(5 checks of one file in the probe); F2 hash calls not limited to the server's 2 hash connections; F3 no
deadline on a hash call or the local read; F4 "three places" recorded when the middle and end were never
compared. Before a real run: F5 on Windows a check's open handle stops the copier removing a staged copy;
F6 a hash wait closed the parts' gate (the main session's decision: it holds that server's checks only,
is counted, and does not touch the parts' gate, the speed-limit detector or the window). Minor: F7 to
F10; decision F9: "three places: held" for video only. **All of it was sent back to the B1 coder (resumed
in `wt-exact`); the race runs still going are of the code before these fixes, so the changed packages are
run again before the merge.**

**21:00 to 21:10 local (PC clock): the session's process restarted; its background jobs were cut off.**
Found on return: free memory 0.4 GB; two `engine.test.exe` left behind by the B1 coder's interrupted fix
work held about 10 GB (one reached 8.1 GB in a minute: a runaway in the half-finished engine change). The
permission check refused my kill; **the owner killed them**; 11.5 GB free afterwards. A stray `go.exe`
(24 MB) remains, harmless. Race containers of the pre-fix exact check: engine 326 s, exact 10 s, wire 22 s,
supply 680 s, store 178 s, all ok; collector stopped by the clerk's low-memory rule (exit 137); catalogue
stopped by me; all five removed. **The B1 coder was resumed** with: find the runaway by reading first;
every test run bounded (`GOMEMLIMIT`, `-timeout 90s`, memory watched, its own test stopped under 2 GB
free); no test process left behind. **Lesson for every brief from now on: test runs carry a memory limit
and a timeout, and an agent checks for leftover `*.test.exe` before it hands back.**
A3 has not started; program and catalogue are as prepared (92bb821, catalogue backed up).

## A3 RAN FOR REAL (11-13, 21:06 local = 02:06 UTC on 11-14), driven by the ninth session, the owner present

Program 92bb821 (the counter with its fix). Command: the owner's A2 command without `-no-downloads` and
`-approve-read`, plus `-read-back-now`. Logs in `a3/logs/`: first start `run-20261113-210639.out.log`, restart `run-20261113-210744.out.log`; sampler
`samples-20261113-210659.jsonl` (sampler process 15880, started 02:06:55 UTC, one line a minute, through the kill and the restart).
- **First start 02:06:39 UTC:** "0 active files given back", "0 parts kept"; running 1 s later; the VPN check
  allowed (no refusal line; it connected); "downloading on 3 servers". One line
  "refresh request failed with RPC_MCGET_FAIL" at 02:06:41 (Telegram's own server error on a reference
  refresh; nothing else followed it). The catalogue went to schema 10 at this start.
- **After about 40 s:** 85 files saved (74 MiB), 35 verified and in the library, 7 active, one checkpoint
  row at 33 MiB. Program memory 43 MB, 21 threads.
- **Hard kill at 02:07:32 UTC** (53 s after the start), with one checkpoint row at 49 MiB (age 2 s).
  **What the kill left:** 7 files active, 1 checkpoint row (49 MiB), 8 part files in staging (54 MiB),
  106 files saved (79 MiB) of which 48 verified and in the library.
- **Restart 02:07:44 UTC:** "7 active files given back; 0 finished downloads replayed"; "start-up sweep:
  1 parts kept, 1 published, 6 removed"; running 1 s later; "downloading on 1 servers" (the files of the
  other two servers were done). 20 s later: 170 files saved (98 MiB), 136 verified, the checkpoint row at
  89 MiB. Memory 44 MB, 22 threads.
- **About 2 minutes after the restart:** 192 files saved (198 MiB), 148 verified; 541 wanted, 7 active.
- **NOT yet proven: that the 49 MiB prefix was re-hashed and carried on** rather than started over. The
  sweep kept exactly the one part the checkpoint named, and the row was at 89 MiB 20 s later, which fits a
  resume but does not prove it. The proof is the store's hourly line (`Resumed`, `ResumeBytes`), which the
  collector logs at the hour's end (03:00 UTC) and at a clean stop; the store's counts are in no table.
- No wait, timeout or refusal line in either log so far. The hourly tables are written at 03:00 UTC.
- **Left running** (collector process 43644). To stop cleanly: `a3/a3-stop.ps1` (never yet tried on the
  collector); the sampler stops when the file `a3/stop-sampler` exists.

## A3 ENDED AT 21:12:07 LOCAL (02:12:07 UTC): the collector and the sampler died with the Claude app

Checked at 21:31 local after the Claude app had crashed and restarted: no collector process, no sampler
process. **Both had been started from this session (`Start-Process`), so they were children of the app's
process tree and were killed with it**, 4 minutes 23 seconds after the restart of the run. That was a
second, unplanned hard kill. **Lesson: a run that must outlive the session cannot be started by the
session. The owner starts it from their own PowerShell window (outside the app), or it is started through
a scheduled task; the scripts in `a3/` work from any PowerShell.**
- **State left:** 494 files saved (1,226 MiB), 493 verified and in the library; by server: server 2
  498 media / 1,210 MiB, server 1 6 / 18 MiB, server 4 1 / under 1 MiB; 228 still wanted, 7 active (to be
  given back at the next start), 2 checkpoint rows (32 and 8 MiB), 7 part files in staging (47 MiB),
  1 file set aside ("the server does not answer for this file": two timeouts in a row).
- **Speed, looks like (one run, one server, 260 seconds):** after the restart 388 files and 1,146 MiB in
  260 s, about 4.4 MiB a second, nearly all on server 2 at 2 parts in flight; photos first, then videos.
  No wait line and no refusal line in the log. Program memory stayed at 38 to 46 MB.
- **Lost with the kill:** the engine's hourly rows for this run (`c_hourly` has 0 rows: it is written at
  the hour's end and at a clean stop only) and the store's resume counts. So **requests, waits, timeouts
  and the window's steps of this run are not on record**, and the resume of the 49 MiB prefix is still
  unproven. The sampler has 5 lines (21:06:59 to 21:11:06). This is the logging gap the owner warned of:
  **the program must write its counts every minute or so, not hourly (a brief for a coder).**
- The exact check's coder was cut off again by the same crash; its progress file says the engine
  mutations were done and no test process was left (checked: none running).

**21:32:33 local (02:32:33 UTC): the owner started the run from their own PowerShell window** (outside
the Claude app, so it outlives the session): collector process 76840, log `run-20261113-213233.out.log`;
sampler process 7008. First lines: "7 active files given back; 0 finished downloads replayed"; "start-up
sweep: 2 parts kept, 0 published, 5 removed" (the two partial files with a checkpoint kept: a second real
recovery after an unplanned kill); running 1 s later; VPN check allowed; "downloading on 1 servers".
About a minute in: 496 files saved (1,323 MiB), all 496 verified; 227 wanted, 7 active; memory 41 MB.
**In the morning:** `a3/a3-stop.ps1` for a clean stop (it writes the hourly rows and the store's resume
counts; never yet tried on the collector: `-Hard` is the fallback), then create `a3/stop-sampler`, then
the numbers from the log, the hourly tables, the sampler's file and `a3/logs/files-*.csv`.

## THE OLD APP'S ANSWERS (`ANSWERS-for-archiver-4.md`, read in full by the ninth session, 11-13 22:40 local)

Numbers are the old app's own, read-only, 11-04 to 11-13; nothing re-run. What each changes:
1. **The preview hash is equal** (all four invented previews give the expected values on the 12.30 source).
   So the look-alike package may be wired in. One gap: compiled with Go 1.27.3, the release with 1.27.2.
2. **The exact check is worth far more than assumed: 5,007 files (240 GB) not downloaded in ten days, from
   9,046 checks, every one decided by Telegram's hashes; the byte fallback decided none** (18 checks had no
   hashes or a failed request; 2 failed). The files average about 48 MB, so most are videos of 2 MiB or
   more, **which the old app judged on the hashes at three places only.** In the new app three places is a
   held probable copy, not a skip. **So unless a whole file's hashes can be compared, the new app would
   hold what the old app skipped.** Consequence for B1: the bound of 64 hash requests must not be what
   stops a full comparison. A hash request carries no file bytes; comparing every window of a file costs
   about as many requests as downloading it would, but no bytes against the speed limit (not measured).
   **Decision to take with the owner after one measured request on the test account (windows per answer
   is "not recorded" in the old app): raise or drop the bound so that a video is compared in full.**
3. No "same" was ever undone (0 rows), **but nothing in the old app ever re-checks one**: its three-place
   verdicts are unverified. The new app's full comparison is the stronger rule; keep it.
4. 12% of checked files had more than one saved candidate of their size; a second candidate cost no new
   request (the answers are kept). Check that B1 keeps Telegram's answers across candidates.
5. **A hash wait in the old app closes the account's gate for requests that are not parts; parts do not
   wait on it.** That agrees with the ninth session's decision for B1 (a hash wait holds checks only).
   The old app ran up to 7 hash requests at once per server through the download pool; no trouble on
   record, but nothing was counted per method.
6. **No part request failed with a lost connection in 129 hours.** So the leave-and-count counter is
   expected to show losses near zero; a run with many would be news.
7. **WITHDRAWN (the old app's session corrected its own figure; see the section below): "the look-alike
   hold alone is wrong more often than right" was built on 12,926 "released" items that had never been
   held.** The corrected figures and what follows from them are in "ANSWERS 5 AND THE CORRECTION".
8. Frame checks: 8 parts at the median (largest 196); about 10 to 22 s added per check in runs with
   unlimited hours, 3 to 14 minutes under the speed limit, where about half time out. Failures: 22 over the
   parts cap, 15 timeouts, the rest single figures.
9. **Kept parts: at least 63.4 GB reused in 7,916 downloads; 0 refused on reuse** (length, bytes,
   unreadable). 35.4 GB kept now.
10. **99.6% of saved videos are MP4 or MOV**: the small MP4 index reader (COPY-CHECKS-STUDY E.7 b) covers
    nearly everything; ffmpeg's own discovery is the fallback for 0.4%.
11. Plain waits on parts are almost all 1 to 2 s on three servers, rare and long (15 to 52 s) on the
    fourth, and come in unlimited hours; speed-limit waits are about 14 to 16 s each, thousands a day per
    server. A3 saw no wait of either kind in its first ten minutes.
12. **What the old app could not answer ("not recorded"), each a requirement for the new app's logging:**
    hash windows per answer; requests per check; waits per method; the length of each wait (only a count
    and a sum per hour); seconds per check; connections re-made; candidates per check; waits on message
    reads. See the start file, section 2.
New questions for the old app's session: `QUESTIONS-for-fork-5.md` (two, read-only).

## ANSWERS 5 AND THE CORRECTION TO ANSWERS 4 (read in full by the ninth session, 11-13 about 23:40 local)

`ANSWERS-for-archiver-5.md`, and the corrected B.7 of answers 4. The old app's own numbers, read-only;
"looks like" where it says so. **This replaces point 7 above and sharpens point 2.**
1. **The correction.** Real holds that got a frame check: 5,564 confirmed (4,204 of them held by the frame
   check itself), 678 released, 369 partial, 7 failed. **Look-alike holds judged by frames: 1,360 confirmed
   against 675 released** (held against a saved file: 1,218 against 275; against a queued file: 130 against
   400). So the hold against a saved file was right about four times in five; the hold against a queued
   file was wrong three times in four. Every one of these is over 200 MiB (the background check's floor).
2. **The exact check, by kind and size:** of the 5,007 files skipped, **3,932 (233 GB of the 240) are videos
   of 2 MiB or more judged at three places**; only 1,075 files (1.2 GB) were judged on every part. So the
   new app's rule (skip only on a full comparison) moves 99.5% of those bytes from "skipped" to "held"
   unless a video can be compared in full. Classes: 2 to 64 MiB 3,193 files / 41 GB; 64 to 256 MiB 511 /
   71 GB; 256 MiB to 1 GiB 201 / 88 GB; 1 GiB or more 27 / 38 GB. Not recorded: how many windows the
   three-place answers covered (some may have been compared in full).
3. **No stored fact separates a wrong hold from a right one**: preview distance (released holds are, if
   anything, closer: 82% at 0 bits against 76%), length (median difference 0 ms in both), size ratio
   (median 1.0000 in both), pixels. A tighter preview limit keeps most wrong holds and loses real copies
   (at 0 bits: keeps 182 of 221 wrong, loses 24% of the right). Only even distances occur (0, 2, 4, 6).
   The frame check finds copies the preview rule cannot: 31% of the copies it found by itself are 7 bits
   or more apart.
4. **The frame check released exact copies ("looks like", one read of the data):** at least 23 of the 275
   released "saved" holds were byte-identical to the saved file (18 skipped by the exact check when later
   downloaded, 5 with the same whole-file hash after download); 203 of the 275 had the saved file's exact
   byte size, pixels and length. 58 of the 369 "partial" ones likewise.
**What follows for the new app (the ninth session's reading; decisions for the owner where marked):**
- **Keep the look-alike rule's thresholds as they are** (6 bits, 500 ms, 2%): the data offers no better
  cut. The owner's symmetric "same shape" stays. Consider holding against a QUEUED file more cautiously
  than against a saved one (wrong three times in four): a count first, as "would hold", before it holds.
- **Order of the checks for a held file whose byte size equals a saved file's: the exact check first.** No
  frame check may release such a file until Telegram's hashes have said "different". (B1 already checks a
  held file when it is claimed; this asks for it early, and as a gate before B3's release.)
- **The full comparison of a video is where the value is (233 GB in ten days in the old app).** DECISION
  FOR THE OWNER after one measured hash request on the test account: (a) no bound on hash requests for a
  video, comparing every window (requests about the file's size over the bytes one answer covers; no file
  bytes; the saved file read once, or its window hashes kept at save time); or (b) accept three places
  for video as the old app did (never shown wrong, never checked either), against the rule that only a
  full comparison may skip. The ninth session recommends (a).
- B2 no longer has to wait for B3 on the grounds given in point 7; it should still come with the exact
  check as its first confirmer.
No further questions for the old app's session at this point (`QUESTIONS-for-fork-6.md` is the place).

**11-13 late night: the owner decided: the exact check compares a video in full** ("but ensure we have
appropriate logging and have documented this decision in case it backfires or goes overboard"). Written
as the thirteenth round of `FEATURES.md` section 12 (pushed): the decision, what was not known, five ways
it can backfire with a guard and a count for each (a budget per server and hour; three waits stop
comparisons for the hour; two hash requests in flight; a spot check of one skipped file in a hundred with
an alarm and a switch-off; the library's turn), the logging, the setting with three values as the way
back, and when to look again. The exact check's brief (both copies) has an addendum making it part of the
piece. **The A3 run finished about 22:50 local: 734 files saved, 17,842 MiB, all verified; nothing wanted
or active; the collector idles (process 76840) until the clean stop in the morning.** Not yet looked at:
why 734 files where 741 were wanted at the start.

## A3'S NUMBERS, READ BY THE NINTH SESSION (11-13, 22:45 to 23:00 local); THE RUN IS STOPPED

**Clean stop at 22:45:12 local (03:45:12 UTC): `a3/a3-stop.ps1` worked on the collector ("stopped in 11
ms"); the hourly rows and the staging lines were written. The sampler was told to stop (71 lines,
21:32:38 to 22:44:53). Nothing is running.** Third start to the end of the work: 21:32:33 to about
22:24 local (52 minutes); then idle.

**1. The count that did not add up: 741 wanted, 734 files saved. Explained.**
- 741 media were wanted at the start. **4 more photos (439 KiB) arrived during the run**, in 10 new
  messages of 2 OTHER chats (not the chat that was read): the live monitor records every new message of
  any chat and its media is wanted and downloaded by itself (as the handoff warned; the owner's twelfth
  round allows reading and following every chat). 2 of those messages carried a file another already had
  (the same Telegram file: linked, no download). So 745 media.
- **11 photos turned out to be byte-identical to another photo with a different Telegram id** (same size,
  same pixels): downloaded, then recognised by their SHA-256 and stored once (2.6 MiB downloaded for
  nothing). 745 less 11 is 734. **These 11 are exactly what the exact check (B1) is for: the first real
  evidence for it on the test account.**
- Every wanted file ended saved and verified: 734 of 734. The one file set aside in the second start
  ("the server does not answer") was fetched later. No file gone, none failed.

**2. Speed (one run, one server: "looks like").** Server 2 carried 17.38 GB of the run: 9.18 GB in 1,646
busy seconds in the first hour and 8.20 GB in about 1,459 in the second: **about 5.6 MB a second, at a
window of 2 parts the whole time** (the sampler: median 5.4 MiB a second per minute, largest 10.1). No
speed-limit wait at all. Servers 1 and 4 had one small file each. Program memory 38 to 59 MB, 18 to 20
threads, 410 to 441 handles: flat.

**3. FINDING, not explained: 1,261 plain waits on parts in 52 minutes, and none of them in the log.**
`c_hourly` server 2: plain waits 675 then 586; `c_tg_hourly` parts: waits 677 then 584 of 9,543 and 8,423
requests (about one request in 14). Slot time: answered 2,147 s, sleeping 1,018 s, failed 121 s in the
first hour: **about a third of the slot time was spent sleeping waits** (about 1.5 s a wait). The old app
on its account saw plain waits of 1 to 2 s too, but far fewer (at most 116 in an hour). The window never
left 2 (`Careful` steps down on every plain wait: the trap of TRIED-BEFORE 23, now seen for real: no
third part was ever tried). 2 timeouts. **The log printed not one line about any of it.**

**4. FINDING, not explained: a pool connection was lost about every 4 seconds.** `c_conn_hourly`: data
connections lost 390 then 369; dials to server 2: 392 then 367; new server sessions on server 2: 759.
**The counter (its first real numbers): requests in flight at a loss 731 then 695 (1,426), of them under
a stated wait 44 then 38 (82).** The guard line: "390 connections ended after sending; 390 were matched
to a reported loss", then 370 of 370: the counter missed none. So the library re-dialled 759 times (each
a new connection with its first request) and had up to 1,426 requests to send again, 82 of them possibly
inside a stated wait. **The old app recorded 0 lost connections on parts in 129 hours.** Not known: why
(the library's pool closing a connection after a wait or a cancelled request? Telegram closing it? about
23 MB went through a connection before it died, and there were about 0.6 losses per plain wait); whether
the losses cause the waits or the waits the losses; what it costs in speed. **This is the first thing to
look into: it is what the counter was built to show, and it showed a lot.**

**5. Reference refreshes:** 197 then 40 requests, all answered, 250 files refreshed: about one request per
file, as estimated. Chat list 2, differences 1 and 12 (channel). No wait on any of them.

**6. Staging (same disk as the test library):** 240 files / 17.4 GB staged and copied in this start, all
verified by reading back at once; seconds per step: write 7 to 8, flush 2 to 3, verify 5 to 7; 5 "file
busy" tries at prepare and 23 "not published locally yet" put-offs, none failed.

**7. Still not proven: the resume.** The staging lines do not print the resume counts at all, so even a
clean stop did not show them. Three starts each kept exactly the parts that had a checkpoint; that is the
evidence so far. (A gap for the logging piece: print `Resumed`, `ResumeBytes`, `ResumeRestarted`.)

**For the logging piece, found here:** waits are counted but never logged, nor their seconds; connection
losses and re-dials are counted but never logged; the resume counts are printed nowhere; a file set aside
is logged without what became of it later.

**23:10 local: `QUESTIONS-for-fork-6.md` written** (eight questions, read-only: plain waits per request in
the old app; what it does with a request, its neighbours and the connection on a wait; how its download
pool makes and drops connections; the library version; anything that would explain a connection lost
every 4 seconds). The owner passes it on while the old app's session is awake.
**To repeat A3 on the same chat (the owner asked):** the catalogue's copy from before the run
(`catalog-v9-before-A3.sqlite`, 741 wanted) can be put back and the test staging and library folders
emptied; that needs the owner's OK each time (it deletes the test library's files). A larger chat is not
needed for the next diagnostic run; it is needed later for a long run (the speed limit's onset) and, with
overlapping content, for the copy checks.

**The owner, 11-13 23:15 local: the test run's downloaded files may be deleted by a later run** ("This is
all testing. There's no value in them."). So, for repeating A3: emptying
`C:\Users\trabi\AppData\Local\tgarchive\test\library` and `...\test\staging` and putting the catalogue's
copy back (`...\test\catalog\catalog-v9-before-A3.sqlite` over `catalog.sqlite`, with its `-wal` and
`-shm` removed, no collector running) has the owner's OK. This covers the `test` folder only: never
`...\tgarchive\bin`, the session key, the `sessions` folder, or anything of the old app.

## ANSWERS 6 (read in full by the ninth session, 11-14 about 00:40 local): the waits and the lost connections

`ANSWERS-for-archiver-6.md`: from the old app's reports and code (and gotd v0.163.0, which it builds
with); nothing measured anew. **Second correction to answers 4: "0 lost connections in 129 hours" cannot
be read from its counters** (a death before the acknowledgement is retried by the library unseen; one
after it is filed as "cancelled"). Upper bound instead: at most 12 such failures on its server 4 in 23
unlimited hours (474 GB), against 759 deaths in the new app's 52 minutes.
- **Plain waits per work done:** the old app, in hours without the speed limit: one per 2,484 to 10,540 MB
  by server (its worst single hour: one per 222 MB), at 1.4 to 2.8 parts in flight. **The new app's run:
  one per 14 MB.** 16 times worse than the old app's worst hour; 180 to 750 times worse than its usual.
- **What the old app does on a plain wait, by its code:** the request that got it sleeps the stated wait
  PLUS 1 SECOND, then asks again through the server's gate and an account-wide limiter (60 requests a
  second); nothing in flight is cancelled; the connection is kept (the library puts it back on the free
  list). More than 3 waits on one request end the attempt. It never asks before a stated wait is over.
- **Its pools:** one per server for the app's life (12 connections; home server from `Client.Pool`, the
  others from `Client.DC`); never closed by the app; each part has a 2-minute deadline.
- **CHECKED IN THE NEW APP'S CODE BY THE NINTH SESSION, the likeliest cause:**
  `internal/engine/lane.go` `waitLen` (line 1467) returns exactly the stated seconds (at least 1): **a
  part's wait is slept with NO margin**, and the part is asked again the moment it ends. The new app's own
  request loop for everything that is not a part adds a margin (`caller.margin`); the part path does not.
  A request that arrives at the very end of a 1-second wait can be answered with another wait (that would
  explain one request in 14: waits breeding waits) and, by the old app's session's reading, Telegram may
  close a connection that asks too soon (0.6 losses per wait). **Not proven: no run has tested it.** Not
  the cause, checked: "ask early" is off by default; the run's server (2) is not the home server, so the
  home-pool difference does not apply to it (it does apply to server 1's files: to look at); the new app
  sets no ping or retry option of the library. Not compared: gotd v0.163.0 against v0.166.0 (pings every
  30 to 45 s in v0.166.0).
- **The plan this gives (for the tenth session; one coder, small):**
  1. A margin on every part's wait (a config field, default 1 s, as the old app), slept by the request
     that got it; counted as before. Nothing else changes.
  2. With it, the first of the logging piece, because this is what the next run must show: **each
     connection death counted by the type of its error** (`ConnWatch.dead` has the error: its type name, a
     fixed word, never its text), and whether a wait on that server was stated in the 2 seconds before it;
     **each wait's seconds** (smallest, median, largest per hour), and how many waits were the second or
     later on the same part.
  3. Repeat A3 on the same chat (the catalogue's copy put back, the test folders emptied: the owner's OK
     is on record) and compare: MB per plain wait (14 before), deaths (759), speed (5.6 MB a second).
     One change at a time: if the margin alone does it, stop there.
  4. If deaths go on: the library's own debug log for one run, kept to connection lines (fixed words and
     numbers; check that no line of it can carry a name or an id before it is written to a file).

**11-14 about 00:55 local: the owner asked whether the finding was documented "in critical locations".
It was not: it was only in the local notes.** Now also in the pushed repository (998ef69):
`TRIED-BEFORE.md` section 27 (the run, the wait without a margin and its rule, the logging rules, the old
app's corrected figures on the exact check, the hold, frame checks and kept parts), a new first block in
`HANDOFF.md` section 0c ("A3 RAN"), and the roadmap's rows for A3. And a memory file
(`archiver-first-real-run`) with the working rules of the night.

**11-14 about 01:10 local, before the session is archived: a last sweep for anything not saved.** Done:
both reviews and their probes and the run's scripts copied into the repository and pushed (8761d5c); the
exact check's unfinished work kept as a local commit and branch (`wip/exact-check-2026-11-13`, 8bcc997);
the start file has a section "Loose ends"; memory `archiver-session-start` updated. Nothing is running.

**11-14 about 01:20 local: a one-time scheduled task starts the tenth session on 11-14 at 15:02 local**
(task `archiver-session-10-start`, in the app's "Scheduled" list; file
`C:\Users\trabi\.claude\scheduled-tasks\archiver-session-10-start\SKILL.md`; saved in Auto mode). It reads
`CLAUDE.md` and `START-SESSION-10.md` and works unattended within limits: nothing against Telegram, no
collector start and no deleting until the owner is present and says so; it reads, briefs and starts the
coders for the wait margin and the exact check's fixes, then waits with a short report. The app must be
open at that time (otherwise it runs at the next launch).
