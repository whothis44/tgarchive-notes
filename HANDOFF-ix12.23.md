# Handoff: ix.12.22 live, for the session that builds ix.12.23

Read first: `START-HERE.md` (rules, tools, code map, build/test/release flow), `CLAUDE.md`, then this file, then
`PRE-PUSH-CHECKLIST.md` before any push. `HANDOFF-ix12.21.md` holds the history of 12.20-12.22 (its last sections say
what 12.22 built and why; read them for context, not for instructions).

Hard rules in short (details in START-HERE.md section 2): never open the live dashboard, the viewer on real data, or any
real media; `E:\T\tg-dl` read-only (report, crashes\running, history.jsonl, DB as `mode=ro`), counts/sizes/timings/versions
only; never stop/restart/reconfigure the running app; no new Telegram requests without measuring them; probable copies held,
never skipped, never before unique files; push, tag and publish only with the user's explicit OK for that version; draft
CI-only PRs, never merge, never push main; challenger reviews of download-path and UI changes before release.

## Where things stand (2026-11-09 21:26 report)

| Version | Tag = commit | Branch | State |
|---|---|---|---|
| ix.12.21 | `v3.4.18-ix.12.21` = 99b22d4 | `ix/v12.21` | ran 11-09 11:31-20:49:55, ended clean |
| **ix.12.22** | `v3.4.18-ix.12.22` = 77a7bda | **`ix/v12.22` in `repo-v12.16`** | **live since 11-09 20:50:30**; draft CI-only PR #34; CI green |

Next work: **ix.12.23**, from `ix/v12.22`: `git -C repo-v12.16 switch -c ix/v12.23 ix/v12.22`.

### 12.22 verified live
- Installed by 12.21's rule (drain only under the speed limit): the limit came back about 20:45; 12.21 ended clean.
- **Export retry worked:** last night's 03:30 copy had failed ("rename: Access is denied"); at 21:05 the retry ran and
  succeeded: `export: last 21m0s ago · error:  · tried again after a failure today: 1 of 3`.
- Report lines present: `after the account goes: not due`; fast hours: `10 of the last 47 measured (about 5.1 a day),
  median 84.1 GB/h · needed ... go first 7 h (626 GB), with not queued yet 16 h (1363 GB), with the probable copies held
  31 h (2614 GB) · about 102 such hours left`; spells 11-09 15:00 5 h 386 GB | 11-09 05:00 1 h 97 GB | 11-08 17:00 3 h
  279 GB | 11-08 06:00 1 h 57 GB.
- Not yet seen: the top-up's early re-reads in a fast spell (needs the limit off); the old browser's thumbnails (user's
  eyes only); the viewer on real data (user only: never open it yourself).

### Live facts (counts only)
- Queue 36,046 files / 2,373 GB. By size: under 10 MB 11,234 / 40 GB; 10-100 MB 19,023 / 561 GB; 100-500 MB 5,144 /
  776 GB; 500 MB-1 GB 405 / 234 GB; 1 GB+ 238 / 266 GB. By stage: go first 1,832 / 302 GB; set aside (smaller files and
  private chats first) 3,096 / 315 GB; probable copies held 28,588 / 805 GB; confirmed copies 2,516 / 446 GB. Not queued
  yet about 72,671 files / 737 GB. 69 groups still waiting for a files pass (all messages read).
- Under the limit (21:26): every server at window 2; DC1, DC4, DC5 about 0.1 MB/s each; **DC2 idle with nothing to start**
  (file slots: DC2 small 0/5, 0 could start; large 0/2, 0 could start). DC5 small 0/5 too.
- Staging: 10,766 files / 207 GB waiting (oldest 4 h); last hour 977 copied, 25.6 GB, 1.7 MB/s per copy, 15,189 s of
  copying summed (about 4.2 copies running on average) with **8 allowed (the user raised it from 6 on 11-09 evening)**.
  At 6 allowed (11-09 16:00-19:00): about 31 GB/h, 1.5 MB/s per copy, about 5.8 running. Earlier (11-08): 1.9-2.1 MB/s per
  copy at 3.3-4.4 running. The total stays near 7-9 MB/s whatever the count. Disk room about 1,063 GB more.
- Network (read-only check, no names): the PC has a 10 Gbps wired adapter (also Wi-Fi and a VPN adapter up). The NAS is
  a UGREEN DXP4800 Plus (user, 11-09): 10 GbE and 2.5 GbE ports. Which adapter the app's SMB traffic uses could not be
  seen from Claude's session (no SMB connections visible there).
- ffmpeg on the PC decodes on the GPU (`decoder cuda`, gpu→cpu fallbacks 0). Video index 82,586 / 84,867 done (114
  errors, mostly "invalid data"). Staged videos are fingerprinted locally before copying. Running ffmpeg on the NAS would
  be slower and save little (user asked 11-09; answered no).

## The user's question (11-09): many remaining files are smaller; would any setting help?
Answer given: no setting change is expected to help, from the numbers:
- Under the speed limit the cap is bytes per server (each server about 400 MB/h at window 2, whatever the file sizes;
  more parts never brought more bytes: 12.21 evidence). File count does not matter there.
- In fast hours, 27 hours over 20 GB (11-06..11-09, DB) showed no link between average file size and GB/h (14 MB average
  → 66 GB/h, 23 → 97, 56 → 136, 114 → 102).
- Copies at once: 6 → 8 did not raise the copy total (about 4.2 of 8 run). Keeping 8 is harmless.
What does matter for smaller files is per-file work in the staging copier (create, write, flush, read back, publish,
catalogue on the NAS for each file) — measure it (item 1).

## Measured 11-09 22:00-22:40 by a review session (read-only; rates and counts only)

### A. The NAS is reached over Wi-Fi (the user confirmed it, 11-09: it cannot be cabled now)
- 10 s sample of the adapters: wired 10 Gbps adapter 0.0 MB/s both ways; VPN adapter 0.2 MB/s in; **Wi-Fi (2.4 Gbps link)
  14.8 MB/s out, 14.5 MB/s in.** The report's last hour: 1,865 files / 49,355 MB copied = 13.7 MB/s.
- So the copy total (earlier "7-9 MB/s whatever the count", now about 14) is the Wi-Fi link shared by everything, and
  **each staged byte crosses it twice**: once written, once read back by `verifyCopy` (the inbound 14.5 MB/s). More
  copies at once cannot raise it. One sample: "looks like", but the user confirmed the Wi-Fi path.
- What this changes in item 1: a larger copy buffer or more copiers will not help while the link is the cap. What can:
  (a) nothing else using the link while copies wait (finding B); (b) with the user's OK only, a verification that does
  not send every byte back over the same link (for example trusting SMB's own signing plus a size and a sampled
  read-back, or the full read-back later in limited hours). **Do not change the verification without the user's OK.**
- The numbers for the deadline: at about 50 GB/h copied the 180 GB backlog is under 4 h; staging has room for about
  1,090 GB more; a fast spell brings 70-100 GB/h in and about 50 out, so the backlog grows about 20-50 GB/h in a spell
  and the room lasts 20-50 fast hours in a row. Not urgent.

### B. Upstream's hourly integrity sweep stats the whole library on the NAS, 64 files at once, and is not paused
- `internal/app/integrity.go`: `runIntegritySweeper` runs 30 s after start and every `advanced.integrity.intervalMin`
  (60 at least); `sweepIntegrity` pages the `downloads` table (batch 64 by default, up to 1,024) and starts one
  goroutine per row doing `os.Stat` on the library path (`integrityCheck`, line 91). About 128,000 rows.
- The 21:55 profile (30 s): 59.7 threads a second sampled in system calls; **`app.integrityCheck` 82% of them**
  (about 49 threads waiting on a NAS answer), `download.(*Library).moveStaged` 9% (about 5.4), everything else under 2%.
- The fork pauses its own monthly check for the staging copies (`ixFixityGivesWay`, "paused for the staging copies
  (backlog above 50 GB) 70 min since start") but nothing gates this one.
- It also **removes catalogue rows** whose file is missing or empty (`integrityPrune`), on its own, with one guard
  (more than half of the rows missing and at least 20 rows: nothing is pruned). A NAS that answers "not found" for a
  smaller share (a folder renamed, a share remounted half-way) loses those rows, and the files are downloaded again.
- Proposal (no Telegram request): give the automatic sweep the same give-way rule as the fixity check (staging backlog,
  or copies running), cap its stats at once at 4-8, and make the automatic run report-only until the account is gone
  (count what it would prune, into the report; the manual "Verify files" keeps pruning). Measure first: add the sweep's
  duration, rows checked and rows pruned to the report, and compare the copy MB/s in minutes with and without a sweep.
  Not measured yet: whether the sweep slows the copies at all.

### C. The app reads its database through Windows about 25,000 times a second
- 20 s sample (performance counters): the app 114.6 MB/s read in 25,450 reads a second (4.5 KB each: SQLite's 4 KB
  pages); physical drives: E: 15.2 MB/s in 530 reads a second (the staged files being copied), C: 2.6 MB/s, D: 0.
  The report's hour: 880,625 MB read (244.6 MB/s). So about 85-95% of the app's reads are answered from Windows' file
  cache, never from a drive. All three drives are NVMe SSDs; nothing is worn or thrashed. The cost is CPU (a system
  call and a 4 KB copy each), unmeasured.
- Cause: `internal/store/migrate.go` `sqliteDSN` and `store/readonly.go` set busy_timeout, foreign_keys and synchronous
  only. `cache_size` is SQLite's default (about 2 MB a connection) against a 1,916 MB database, and the reader pool has 8
  connections (`reader.SetMaxOpenConns(8)`), the writer 1. The scans that the background work makes (the [cpu] section:
  `_sqlite3VdbeExec`, `ixWaitingApartNow`, `ixSavedIdentities`, `ixSchedMessageDemand`, `ixBuildAlbumIndex`,
  `PendingManual`) fetch the same pages again and again.
- Proposal: `q.Add("_pragma", "cache_size(-65536)")` (64 MB) on both DSNs: at most 9 x 64 = 576 MB if every connection
  fills its cache. The PC has 31 GB with about 3.9 GB available and the app's heap is 1.4 GB in use (3.0 GB reserved),
  so do not go to 256 MB each. Leave `mmap_size` alone unless measured (modernc's Windows build; a mapped file and a
  WAL checkpoint need care). Measure: `[process]` read MB/h and CPU % before and after, same kind of hour.
- Second step, only if the first shows a gain: find which query repeats (the report's [cpu] names the callers) and
  cache its result or add the index it lacks; a scan that runs every minute over 170,000 messages is the kind.

### D. The "copies running" figure undercounts
`noteMoved` (staging.go ~141) records a copy only when it ends well, with its whole duration, in the hour it ended. A
long copy still running, a copy that failed or was put off, and time before the hour started are missed, so "29,165 s
summed = 8.1 running" and "4.2 running" are not comparable hour to hour. For item 1 count busy copier-seconds directly
(a counter raised around `moveOneStaged`), and free-slot seconds while files wait.

A full code review and a plan for a standalone app are in `CODE-REVIEW-ix12.22.md` and `STANDALONE-PLAN.md` (same
folder). Its findings marked "12.23" are candidates for this release; none adds a Telegram request.

## 12.23 items (in order; none adds a Telegram request)

### 0. From the measurements above (small, measured, no Telegram request)
- Gate and tame upstream's integrity sweep (finding B).
- SQLite cache size (finding C).
- Honest copier counters (finding D), which item 1 needs anyway.

### 1. Staging copier: measure where the time goes, then fix what the numbers show
Evidence above: the copier moves 7-9 MB/s in total over a 10 Gbps PC link whatever the number of copies, and only about
half the allowed copies run. In fast spells the backlog grows about 40-50 GB/h (70-84 GB/h in, about 30 out); it drains
in limited hours. It is not urgent (1 TB of room), but it caps a long fast spell and the end-of-deadline flush
(`ix_after_gone.go` waits up to 12 h for it).
- Measure per copy, summed per hour, in the staging report line (`download/staging.go`, `app/ix_staging.go`): seconds
  writing (the `io.Copy` at staging.go ~959, 32 KB chunks through a contextReader), flushing (`out.Sync()`), reading back
  to verify (`verifyCopy`), publishing/renaming and cataloguing; bytes; files; time a copy slot sat free while files were
  waiting (why only ~4 of 8 run: files put off? the mover's pick loop? a lock?). Counts and timings only.
- **Read finding A first: the cap is the Wi-Fi link, and every byte crosses it twice.** So measure, but expect the
  per-copy timings to show "writing" and "reading back" taking nearly all the time in equal parts.
- Then, only where the numbers point: a larger copy buffer (`io.CopyBuffer`, 1-4 MB: SMB round trips), fewer per-file
  round trips, or a different number of copies. **Do not weaken the verification (read-back, hash) without the user's OK:**
  it is what makes staging safe.
- Test with an invented library on a local folder; a slow-SMB stand-in can be a reader/writer that sleeps per call.

### 2. Idle servers under the speed limit
DC2 had nothing to start at 21:26 while the limit was on; the top-up does not run under the limit (`ixTopUpStep`:
"Not under Telegram's speed limit: more files at once bring no more bytes then, and they would take a share from the
files going first (review, 11-09)"). But the limit is per server: on 11-09 12:00 each server brought about 400 MB in the
hour on its own (DC1 367, DC2 348, DC4 402, DC5 396), and DC5's 0-136 MB/h nights did not give the others more. So an idle
server under the limit leaves its own ~400 MB/h unused. Proposal: under the limit, top up only a server with no file in
flight and nothing claimable, at most its window (2) files at once, same band and copy-check rules. Expected: up to ~400
MB/h per idle server in limited hours ("looks like" until measured: compare DC2 MB/h under the limit before and after).
Measure first in the report: minutes per hour each server was idle under the limit. Challenger review required (download
path).

### 3. Viewer follow-ups (after the user has used it; ask what bothers them first)
**The user has now said what bothers them (11-09), in their order of weight:**
- Speed: slow to open the item page after a click, and slower still to load or play a file.
- It is hard to see how things were actually posted: an album is not shown as one post.
- **Chats does not work at all**: every file shows as a standalone item.
- Some items list 20+ suspected copies: fold that into one collapsed line, and keep it collapsed by default for
  other items too.
- The aim: it is a media viewer, so the objective is viewing the media as the most complete set, sourced from
  everywhere it was posted (several groups and posts).
The user will ask for a separate privacy-conscious review of the viewer soon; wait for it before large viewer work.
`STANDALONE-PLAN.md` section 6.1 has a design answer for each point. Measure before changing: time the item request
and the first byte of a file on the invented fixture (`VIEWER_SCALE=1`), never on real data.

Earlier notes, from the 12.22 review:
Not done from the 12.22 review (plausible, not confirmed): chats set to "Hide all" still appear on person pages, related
rows and Copies; a month loads all its tiles and months never unload (fine at 127k invented files; watch memory); with
"one tile for probable copies" on, filters look at the lead copy only; a video face crop cut from the viewer's thumbnail
(a tenth of the video) may miss the face's frame; thumbnail requests wait up to 3 s each and can hold the browser's
connections. Code: `internal/app/viewer*.go`, `viewerassets/`. Fixture viewer: see Tools.

### 4. Deferred
Item 16 (import side for a second account) stays deferred until a new account starts after 11-30.

The user said on 11-09 that a new account **will** be created, that its groups will likely overlap with what is stored,
and that they want to choose per account between a shared archive and its own, and to run more than one account at a
time. `STANDALONE-PLAN.md` (revision 2) designs for that. Two things follow for the fork's remaining releases, neither
needing a Telegram request:
- **The fork's data folder still must not be shared with another account** (`downloads` is unique on chat + message
  with no account; 118,106 of 129,486 saved files are in chats whose message numbers are per account). Sharing waits
  for the new catalogue format.
- **The final index should carry** the account's own Telegram user ID, and the list of Telegram files known but not
  saved (ID, size, kind; about 117,000 today), so a later account can fetch those first.

Decisions the user made 11-09 (all in `STANDALONE-PLAN.md`, revision 3): the new account is not active yet and may
start around 11-30 or sooner; it will share the archive; between accounts, hand-over on a wait is ON by default with a
setting to turn it off; one account first. Because the new downloader is weeks away, the new account will most likely
start on a **separate install of the fork with the "already archived" import (item 16)**, so item 16 is no longer
simply deferred: ask the user whether to build it now. It is a download-path change (challenger review) and needs
their go-ahead.

Read-only catalogue checks run 11-09 (`ix-tools/live_q9.py`, `live_q10.py`; counts only): every chat has a finished
message pass, all 100 topics are titled, every saved file has a SHA-256 and a Telegram file ID, all 3,344 reply
targets are saved. Open: confirm chat names row by row (190 names for 190 chats, but the two tables write the ID
differently); 4 files "unreadable" in the integrity check; 15 failed queue rows.

## After 12.23 installs, read (latest.txt, numbers only)
Version line and history (previous ended clean); staging line (new timings; MB/s total; copies running); the idle-server
line under the limit; top-up line in a fast spell (left per server and size, early reads, skipped); export and backup
lines; fast-hours lines.

## Tools and pitfalls learned in 12.22
- **Go programs on this PC see PATH cut at 2046 characters**: ffmpeg is not found by tests. Set
  `FFMPEG_PATH=C:/Users/trabi/AppData/Local/WhisperJAV/Library/bin/ffmpeg.exe` when a test needs real videos. That ffmpeg
  has no WebP encoder and **reports failure when started without a console window after writing a good file** (why 12.22
  checks the picture, not the exit code).
- Fixture viewer on invented data: `cd repo-v12.16/core-service && VIEWER_SERVE=8799 go test -count=1 -run
  TestViewerFixture -timeout 0 ./internal/app/` (background; token `invented-token`), then
  `tests/ui/viewer_pages.py` with the local Playwright (`ix-tools/ui.sh repo-v12.16 tests/ui/viewer_pages.py`). Do not
  use Playwright `wait_for_function` on viewer pages (its CSP refuses eval).
- `VIEWER_SCALE=1 go test -run TestViewerScale ./internal/app/` times the viewer index on ~127k invented files.
- Python edits on Windows write CRLF unless `open(..., newline='\n')`; gofmt then lists the file. Bash heredocs that hold
  backticks or `${...}` may be refused by the shell checker: write the script to the scratchpad and run it.
- Known flaky (checklist): `TestIx127LibraryReadsByHour`, `TestIxMLParallelismSettlesNearTheService` under load.
