# Handoff: ix.12.4–12.6 done, ix.12.7 and after to build (2026-11-06, ~07:30 local)

Self-contained. Then read `HANDOFF-ix12.md` (standing rules, still valid) and the project memory
(`C:\Users\trabi\.claude\projects\C--Users-trabi-Claude-Projects-Telegram\memory\`). Repo:
`C:\Users\trabi\Claude\Projects\Telegram\repo` (main checkout) and worktree `...\Telegram\repo-v12.5` (branches
ix/v12.5, ix/v12.6). Live install `E:\T\tg-dl`: **read it only; never stop, restart, replace or edit it.**
Account: non-Premium, frozen since 10-31, deletion 2026-11-30.

## Rules that matter most (learned the hard way)

- **Publishing installs on the user's archive.** "Install updates automatically" is on and the launcher restarts
  the app: a newer release is picked up at the app's hourly check, files of 8 MB+ stop at a checkpoint, small ones
  finish, the app restarts on the new version. Publish only with the user's explicit OK for that version.
- Never merge a PR or push `main` (still `93b7dd6`; a push to main also runs "Notify Telegram"). PRs #15–#18 are
  draft, CI-only.
- **Privacy:** media, names, chats are private. Read the live DB only with `file:E:/T/tg-dl/data/db.sqlite?mode=ro`,
  print counts and categories only; mask anything from `error`/`note` columns. The diagnostics report must never
  show a name (the user found leaks on 11-06; see 12.6). Do not quote leaked fragments back.
- **Claims:** no speed claim without measurement; say "looks like", not "is", for one night's evidence.
- **Copies design** (probable copies held at the back) is deliberate: act on evidence it ignores, don't redesign.
- The user dislikes repeated hour-long CI waits: batch changes, run tests locally first. The release workflow runs
  `go test ./...` itself before building; full CI is the extra check (race, ffmpeg, browser).
- GitHub's anonymous API limit (60/h per IP) once made the launcher's `ix-update.ps1` fail with 403 on this PC; check
  `https://api.github.com/rate_limit` when an update "could not check". Your own scripts use the token from
  `git credential fill` (5,000/h).
- On Windows, heredocs mangle backslashes (`\\n`, `\s`): write edit scripts to files (`python -I -X utf8 file.py`),
  or use the Edit tool. Python text mode writes CRLF unless `newline=''`.

## State

| Version | Tag / commit | State |
|---|---|---|
| ix.12.3 | `v3.4.18-ix.12.3` / dccc8a5 | replaced 11-06 00:24 |
| ix.12.4 | `v3.4.18-ix.12.4` / cf885c2 (branch ix/v12.4, PR #16) | was live 00:24–01:27 |
| ix.12.5 | `v3.4.18-ix.12.5` / 5bfbeb8 (branch ix/v12.5, PR #17) | **live since 11-06 01:28**, no crash; all CI green |
| ix.12.6 | c0015d0 on branch ix/v12.6 (PR #18) | **built, CI running at handoff, NOT tagged.** Publish only with the user's OK (they asked for its contents) |

Check before anything: `E:\T\tg-dl\core-service\tgdl-server.exe version`, `data\crashes\history.jsonl` (each run
ends "clean"; a crash adds an entry), `data\crashes\running`.

### What 12.4–12.6 changed (all in CHANGELOG.md)
- 12.4: FLOOD_PREMIUM_WAIT held only by its own request (was: every file on every server stopped, and no claim could
  start); fallback to the shared gate 2 h on a plain FLOOD_WAIT on a file part or mostly-refused parts
  (`internal/telegram/floodguard.go`). 2 parts per server under the limit. `tgdl_work.dc` (server per queued file,
  filled at start before workers claim); claims skip servers whose 5 small / 2 large slots are full
  (`engine/work.go` ClaimAvoiding, `engine/controller.go` claimNext). Report: wait mode, per-server asked seconds and
  same-file waits, `[memory]`. CI split into 4 jobs.
- 12.5: held videos whose sampled frames match no saved video go back; partial matches (3–4 of 8) stay as
  `sampled-partial`; holds with no `ix_copy_hold` row forgotten; one check in three for held videos;
  `sampleBig` switch; "matched by sampled frames"; finish-estimate "ahead of held copies" line; claims take turns
  (`running.claimMu`); CI ffmpeg from a static build (`scripts/ci-install-ffmpeg.sh`).
- 12.6: a full staging folder no longer blocks downloads (new files go straight to the library; files with kept
  progress stay where their bytes are: `app/ix_staging.go` ixStagePlace, `download/staging.go` StageRoom,
  WithoutStaging); report redaction hides whole paths and every `#number` (`app/ix_diag.go` ixReUnix/ixReFile/
  ixReMsgNum, test `ix125_redact_test.go`); 2 parts per server at all times except 10 min after a cut on that
  server; plain FLOOD_WAITs per server in the hour record.

### Measured live (11-05/06, counts only)
- 12.3 under the speed limit: ~1.2 GB/h: DC1 held 24 of 25 downloads at 1 part; each speed-limit wait (~15 s)
  stopped everything.
- 12.4/12.5 under the limit: 4.3–7.4 GB/h (00:00–01:00). **Every server gets its own ~15 s waits and brings
  0.3–0.5 MB/s: the limit looks per server** (one night).
- Unlimited from 02:00: 28 GB at 02:00, then ~12 GB/h: staging filled (copies to the NAS ~2 MB/s: copy + sync +
  full read-back over WiFi, shared with integrity and frame reads) and downloads waited for room 03:40–07:40 (fixed
  in 12.6). DC2/DC4 stuck at 1 part (fixed in 12.6). 30–50 plain FLOOD_WAITs an hour in unlimited hours.
- The plain-FLOOD_WAIT fallback was taken 3 times by 07:37 (report: "every file waits for each … until 08:02").
- The app reads ~530 MB/s from disk (mostly cache) and used 134 % of one core on 11-05 at 22:40: not investigated.

## ix.12.7: what the user asked for

1. **Media browser: a file not downloaded shows its duplicate but does not link to it.** The browser
   (`internal/app/ixassets/browse.html`, model `app/ix_browse.go`, API `app/ix_browse_api.go`) folds copies into
   clusters (`m.Clusters`, items with `Key` = saved). A missing item whose cluster has a saved copy must link to
   that copy (open it in the lightbox / jump to its post). Look at the lightbox info block around
   `data-keeper` (browse.html ~line 566) and how a missing item's card is built. Add a Playwright check in
   `tests/ui/` (they run against invented data; see `archive_layout.py` for the pattern).
2. **Groups with folders (forum topics): filter by topic.** Messages carry `topic_id` (model `ixMPost.Topic`, the
   messages API already filters `?topic=` at `ix_browse_api.go` ~line 755, `topic==1` = General incl. 0), but the
   browser has no topic selector. Add one for forum groups (topic names: see `internal/telegram/forum_topics.go`
   and where topics are stored; find it, don't guess), wired through the feed's query params. Test it.
3. **Diagnostics clean and sufficient to find the next issues** (the user's words). Privacy first:
   - Add a test that feeds **every** `ixLog`/`a.output` format string in the app (grep them) with adversarial
     invented names (other scripts, `$&,;`, emoji, dots, spaces, long numbers) through `ixRedactor.clean` and fails
     on any leak; keep it as the guard for new log lines.
   - Staging: copy rate (MB/s over the last hour), last move time, backlog, bypasses (12.6 counts bypasses only).
   - NAS/disk: bytes read by integrity checks and frame reads per hour (they share the WiFi with the copies).
   - Per server and hour: cuts (plain waits and slow answers), tries up/down, time at the 2-part floor, files
     claimed, slots full; the plain-wait fallback's start/end times (not only a count).
   - The "download state: speed-limited" label showed while the last hour had 0 speed-limit waits (only plain
     waits): make the state say which.
   - CPU and the 530 MB/s reads: a `[process]` line (CPU %, read/write bytes per hour), so a cause can be found.
4. **Files moved out of the staging folder by hand (11-06 ~07:00).** The user moved part of `data\tgdl-staging`
   to the library on the NAS (same relative paths) while 12.5 ran, then cancelled half way (Explorer does not undo a
   move). The mover treats a staged file missing from the staging folder as lost unless the catalogue has it
   (`download/staging.go` stagedArrived checks `downloads`, not the disk), so their messages went back in the queue
   and download again under new random names (`destinationName` adds 16 random bytes): the moved copies stay on the
   NAS as exact, uncatalogued duplicates. Nothing is lost.
   - **Adoption is done in 12.6** (`download/library.go` orphansFor/adoptOrphan + `app/ix_subst.go` ixAdopt, and the
     mover's stagedInLibrary): from 12.6 on, such copies are catalogued instead of downloaded. Files re-downloaded
     before 12.6 installed left their hand-moved copy behind as a duplicate.
   - **To build: a duplicate clean-up plan** (counts first, then the user's OK): uncatalogued library files whose bytes equal a
     catalogued file (use the existing "Plan: move extra copies to _trash" flow, never delete outright).
5. **Decide with the user after a day of 12.6 figures:**
   - The plain-FLOOD_WAIT fallback (2 h of the shared gate) is taken several times a night in unlimited hours, and
     can then still be on when the speed limit returns. Options: shorter (30 min), or only when speed-limit waits
     are also present. Measure first (12.6's per-server plain waits).
   - `paceByAnswers` (Settings → Downloads, off): shadow counts 02:00–05:00 favoured it (7 climbs bytes refused that
     answer time would have kept, 3 drops the other way), but plain floods are 30–50/h. User decides.
   - Large-file slots stay 2 per server (Telegram's own config); never raise them.

## Seen live at 08:03 on 11-06 (12.6, limit off)
- Every claimable file was over 20 MB (DC1 547, DC4 207, DC2 1, DC5 0), so only 2 large-file slots per server ran:
  6 downloads, DC5 idle. The rest of the queue is held copies (14,551) or set aside by the deadline order (13,603),
  and rescans add nothing while the queue is over its cap (812 of 500). Consider: when a server has free slots and
  nothing claimable, release set-aside (not held) files on that server first, ranked order kept; and let small files
  of the set-aside bands fill free small slots. Measure the effect; propose to the user before building.
- The 07:00 hour brought 29.3 GB; plain FLOOD_WAITs were DC2 13, DC4 16 (the 2-part floor is suspended 10 min after
  each, so DC4 sat at 1 part).

## Reliability fixes for 12.7
- `TestFTPLowRateDoesNotExpireNetworkDeadlines` (`internal/backup`, 100 ms timeout) failed the 12.6 release build
  ("pacing mistaken for timeout") and was re-run; it has flaked before. Make it robust (wider margins or a fake clock).
- GitHub's anonymous API allowance (60/h per IP) was used up twice on 11-06 (07:07–07:15: 60 in 8 minutes). A watch of
  connections saw only Chrome talking to GitHub; the launcher's `ix-update.ps1` shares that allowance and fails with 403.
  Make `ix-update.ps1` fall back to the non-API release page (`https://github.com/<repo>/releases/latest` redirects to
  the tag) and the download URLs, which have no such limit. Also: the dashboard's update check
  (`app/public_api.go`, `updateCheckTTL`) caches its answer only when an update exists (line ~148), so with no update
  every dashboard request asks GitHub: cache it always.

## Known, not urgent
- 86 partial matches (45 GB) held; 9,352 look-alike holds never checked (~459 GB): checks run at their existing pace.
- Priorities places 10, 14, 19, 21: "files missing but not queued: add it to the rescan" (user action, or automate).
- Previews of files not downloaded: ~72,000 to fetch, paused while busy; they will not all arrive.
- Windows test baseline failures (not regressions): backup, config, dbread, faststart, fsx, hash.

## Tools (copy what you need; old scratchpads stay)
- Go: `source C:/Users/trabi/AppData/Local/Temp/claude/71f159c3a9e5d4b9/63fc91bc-a626-41aa-a92f-6717bf517e6d/scratchpad/env.sh`.
- Playwright: `PYTHONPATH=<that scratchpad>/pw PLAYWRIGHT_BROWSERS_PATH=<that scratchpad>/pw/browsers PYTHONUTF8=1 python tests/ui/<x>.py`.
- In `C:\Users\trabi\AppData\Local\Temp\claude\71f159c3a9e5d4b9\eef581aa-d583-4754-a37b-3b2c8cd5a29d\scratchpad\`:
  `wait-ci.py <sha> <n>` (CI watch, every 3 min), `runs.py <sha>` (runs and failing jobs/steps), `ci-log.py <run id>
  <prefix>` (each failed job's log), `wait-rel125.py` (release watch; edit the tag), `open_pr126.py` (draft PR
  template), `ph2.py` (hour records, counts), `live125.py`, `stage.py`/`stage2.py` (staging, counts), `dccount/`
  (Go: queued files per server, read-only), `watch-live125.ps1` (restart/version watch), `wgsample.ps1` (VPN tunnel
  rate; only the downloader uses the tunnel), `verify-rel125\` (scratch updater check: copy `E:\T\tg-dl\ix-update.ps1`
  and the live exe into a scratch folder and run it there; then start the exe on a throwaway data folder with
  `PORT`, `TGDL_DATA_DIR`, `TGDL_CRASH_CAPTURE=1` and read `/metrics`).
- Shared notes for this group of sessions:
  `C:\Users\trabi\AppData\Local\Claude-Data\claude_pzs8sxrjxfjjc\side-session-notes\local_8efb4fe8-c838-426f-aa85-4623d70af36e\ix12.4-session.md` (full log of the night).
- Commits: `git -c user.name="Claude" -c user.email="noreply@anthropic.com"`, ending with the Co-Authored-By line.
  Release tags are lightweight; deleting a pushed tag needs the user's permission.
