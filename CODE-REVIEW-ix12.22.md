# Code review: ix.12.22 (commit 77a7bda, branch `ix/v12.22`)

Written 2026-11-09 by a read-only review session. The code is the fork `whothis44/telegram-media-downloader` as checked
out in `repo-v12.16` (the same commit as the published tag `v3.4.18-ix.12.22`). Nothing was changed, built, pushed or
restarted. No media, dashboard page or viewer page was opened; live numbers are counts, sizes and timings only.

**How to read this.** Findings are ranked by what they could cost the archive before 2026-11-30. Each one says where it
is, what the evidence is, what to do, and whether it was measured or only read from the code. "12.23" marks a finding
small enough for the next release; none of those adds a Telegram request. Everything touching the download path needs
the usual challenger review before release.

## 1. What was and was not reviewed

| Area | Coverage |
|---|---|
| `internal/download` (staging copier, resume, manager) | Read in full where the bytes move: `staging.go` 400-1150, `manager.go`, `resume.go` |
| `internal/telegram` (parts, waits, set-aside) | Read in full: `parallel_download.go`, `floodguard.go`, `timeout_aside.go`. **Not read:** `pacer.go` (1,079 lines), `pacer_hours.go`, `attachment.go`, routes |
| `internal/engine` | Read: the worker loop (`controller.go` 1152-1365) and claims and finishes (`work.go` 190-615). Not read: start-up, live updates |
| `internal/store` | Read: how the database is opened. Not read: the migrations |
| `internal/app`, the fork's `ix_*.go` (116 files, 44,700 lines) | Read in full: update, pre-update copy, after-the-account-goes, top-up, viewer start and pass-through, upstream's `integrity.go`. Sampled by search only: everything else (copies and holds, ranking, ML and faces, browse API, backup) |
| Viewer (`viewer*.go`, 4,365 lines) | Read: guard, routes, start command, side database, file handler. Sampled: index, queries, people |
| Pages (`ix.html`, `browse.html`, `viewerassets/app.js`) | Searched for text put into the page without escaping; not read line by line |
| `ix-update.ps1`, release workflow | Read in full |
| Tests | Counted and sampled; **none were run** in this review |
| Upstream code outside the above (about 60,000 lines: cluster, cloud backup, sidecars, sharing, front proxy) | Not reviewed, except to note what is unused |

Size, for scale: `internal/app` has 73,700 lines of code and 37,300 of tests in one Go package; the fork added 37,800
lines over upstream across 291 files; the live database has 134 tables, of which about 45 are empty (features this
archive does not use).

## 2. Summary of findings

| # | Finding | Risk | Status | When |
|---|---|---|---|---|
| A1 | The "last index and backup" after the account goes runs once and is never retried, even if it failed or staging was not empty | Could leave the final index and backup incomplete | Read from code | 12.23 |
| A2 | Upstream's hourly integrity sweep removes catalogue rows by itself and crowds the NAS | Rows lost on a NAS hiccup; competes with copies | Code plus live profile | 12.23 |
| A3 | One failed database statement in a worker stops every download in progress | Lost progress on small files; a restart of the Telegram run | Read from code; frequency unknown | 12.23 (count it), fix after |
| A4 | Anything published as a release installs itself within about 1.5 h; the checksum comes from the same place as the program | The archive's Telegram session depends on the GitHub account and two third-party build actions | Read from code | Decide; partial fix is small |
| A5 | No automatic step back when a new version crashes at start | A broken release loops every 30 s until someone writes the pin | Read from code | 12.23 or 12.24 |
| B1 | The database is re-read about 25,000 times a second (no cache size set) | CPU only | **Measured** | 12.23 |
| B2 | One message-refresh request to Telegram per file, even when the stored reference may still be good | About one request per file (28,300 files in the last 24 h) | Read from code; saving unmeasured | Measure in 12.23; change needs the user's OK |
| B3 | A part that times out locally (2 min, no answer) is retried up to 20 times with no pause and is never set aside | One of a server's part slots held up to about 40 min | Read from code; rare in the report (4 timeouts in 24 h) | Later |
| B4 | Every staged byte crosses the Wi-Fi link twice (write, then read back) | Halves the copy rate on this link | **Measured** (one sample) | User's decision |
| B5 | The copier's "copies running" figure undercounts | Misleads tuning | Read from code | 12.23 |
| B6 | A crash spends one attempt for every file that was downloading | Only matters if a retry limit is set | Read from code | Later |
| C1 | Upstream pages load fonts, styles and scripts from Google, jsDelivr and cdnjs, without integrity checks | Third parties see each dashboard visit; their script runs with the admin login | Read from code | After 11-30, or vendor the files |
| C2 | Viewer: a failed start is retried on every request (the one-minute back-off is skipped on one path) | Minor | Read from code | 12.23 |
| C3 | Viewer token cookie is sent to every local web server on 127.0.0.1 | Minor (local only) | Read from code | Later |
| C4 | A plain wait after three speed-limit waits fails the part at once in the fallback modes | Minor; fallback modes only | Read from code | Later |
| C5 | Control flow decided by matching words in error text | Fragile | Read from code | Later |
| D1-D6 | Structure, tests and tooling (section 6) | Slows every change; source of the CI-only races | Counted | After 11-30 |

No way to read or change the archive without logging in was found, and no place where Telegram text reaches a page
unescaped was found in the sample (section 5).

## 3. Findings that could cost the archive (A)

### A1. The last index and backup after the account goes: one try, then never again
`internal/app/ix_after_gone.go`, lines 84-132.

What the code does: once the archive is read-only, it waits for the staging folder to empty, **at most 12 hours**
(`ixAfterGoneWait`), then writes the index and a "final" backup and sets `FinishedAt`. Line 93 then returns for ever
(`fr.FinishedAt > 0 || fr.Starts >= 2`).

Three ways this ends with an incomplete last copy:
1. **Staging not empty after 12 h.** Copies leave staging at about 50 GB an hour over Wi-Fi (13.7 MB/s in the last
   measured hour), so 12 h moves at most about 600 GB. Staging holds 180 GB now and may take about 1,090 GB more. If the
   account goes at the end of a long fast spell, the final index and backup are written while files are still staged.
   The files are still copied and catalogued afterwards, but the "final" index and backup never see them. The code
   records this (`StagedLeft`) and reports it, and then does nothing about it.
2. **The export or the backup fails.** `ixAfterTry` retries only errors whose text contains "already". Any other error
   (the 11-09 03:30 export failed with "rename: Access is denied"; the NAS is on Wi-Fi) is recorded, and `FinishedAt` is
   still set. 12.22 gave the nightly export three tries a day; this path has none.
3. **Two interrupted starts.** A restart during the run (an update, a crash, the PC) counts as a start; after two, it
   never runs again, finished or not.

Fix (small, no Telegram request):
- Set `FinishedAt` only when both the export and the backup succeeded **and** `StagedLeft` was 0. Otherwise keep a
  "needs another run" state and try again at the next account check, at most a few times a day (a counter per day, as
  the nightly export has), until it succeeds.
- When the 12 h run out with files still staged, run once then (as now), and once more when the backlog reaches 0.
- Do not count a start that a restart cut short.
- Replace the "already" text match with a sentinel error (finding C5).
- Rehearse it on invented data: a test that makes the archive read-only with files staged and a failing export, and
  checks that a later step completes the run.

### A2. Upstream's integrity sweep prunes rows on its own and crowds the NAS
`internal/app/integrity.go`: `runIntegritySweeper` (line 314), `sweepIntegrity` (124), `integrityCheck` (91).

What the code does: 30 s after start and then every `advanced.integrity.intervalMin` minutes (60 at least), it walks the
whole `downloads` table (129,184 rows today) in pages of 64 (configurable up to 1,024) and starts one goroutine per row
that stats the file in the library, which is the NAS. Rows whose file is missing or empty are **deleted from the
catalogue**; sizes that differ are overwritten. One guard: if more than half of at least 20 rows look missing, nothing
is pruned.

Evidence: in the 21:55 profile, 59.7 threads a second were sampled waiting in system calls and `app.integrityCheck`
was 82% of them (about 49 threads waiting for the NAS at once); the staging copier was 9%. The fork's own monthly
check gives way to the staging copies (`ixFixityGivesWay`); this sweep does not.

Why it matters:
- **Rows can be lost.** A NAS that answers "not found" for less than half the library (a folder renamed, a share that
  comes back part-way, a path that changed) loses those rows, and their files are queued and downloaded again. The
  catalogue is the one thing that cannot be rebuilt once the account is gone, except from the files themselves.
- **It shares the Wi-Fi link** with the copies, with up to 64 requests at once, every hour. Whether it slows the copies
  is not measured.

Fix (no Telegram request):
- Make the automatic run **report-only**: count what it would prune and fix, put the counts in the report, and leave
  pruning to the manual "Verify files" button. At the least, do this until the account is gone.
- Give it the fixity check's give-way rule (staging backlog above 50 GB, or copies running), and cap its stats at once
  at 4-8.
- Add to the report: sweep duration, rows checked, rows it pruned or would prune, per run. Then compare copy MB/s in
  minutes with and without a sweep before claiming anything about speed.

### A3. One failed database statement stops every download in progress
`internal/engine/controller.go`, lines 1179-1183 and 1340-1363.

What the code does: a worker that gets any error from claiming work, or from recording how a file ended, calls
`run.cancel(...)`. That cancels the whole run: every file downloading on every server stops, the engine goes to the
"error" state, and `scheduleMonitorRestart` (`monitor_api.go` 258) starts it again 5 s later (30 s, 1 min, 5 min on
repeats). `Finish` has a 10-second budget (`finishCtx`, line 1340) and runs on the **only writer connection**
(`store/migrate.go` 42). Anything that holds the writer for more than 10 s (a large transaction in a background task,
the nightly `VACUUM INTO`, a busy disk) makes `Finish` fail, and the run is cancelled. The row is also left
"processing" until the next start (`Recover`).

Cost of each such event: files under 8 MiB lose their progress (larger ones carry on from a checkpoint), every file
that was downloading has spent an attempt, and Telegram sees a new login run.

What is not known: how often it happens. It may be never. The report has restarts of the app, but I found no count of
engine runs ended by "claim work" or "finish work".

Fix:
- 12.23: count them. A counter by cause where `run.cancel` is called, shown in the report's `[restarts]` section, with
  the longest time the writer was held in the hour.
- If the count is not zero: retry `Finish` and the claim with a short back-off (the row is this worker's alone, so a
  retry is safe) and cancel the run only after several failures in a row. Download-path change: challenger review.

### A4. Whatever is published as a release installs itself
`ix-update.ps1`; `.github/workflows/release-server.yml`; `internal/app/ix_update.go`.

How it works today: pushing any tag `v*` builds eight archives and `SHA256SUMS` and publishes a release. The running
app checks hourly, drains its downloads and exits; `start.bat` runs `ix-update.ps1`, which downloads the Windows
archive, checks it against `SHA256SUMS` **from the same release**, and installs it. The program it installs holds the
Telegram session and the key that opens it.

So the checksum protects against a damaged download, not against a wrong release. The trust chain is:
- the GitHub account `whothis44`, and the credential for it stored on this PC (the helper scripts use it);
- two build actions fetched by version tag, not by fixed commit: `softprops/action-gh-release@v3`, and
  `actions/checkout@v7` / `actions/setup-go@v7`. A changed tag upstream could alter what gets published;
- `dependabot-merge.yml`, which merges dependency updates into `main` by itself where Dependabot is on. `main` is not
  what releases are cut from, so this is a smaller concern.

This is a known and deliberate trade (the user asked for automatic installs), so the question is how much to harden it
for the remaining three weeks:
- Small: pin the three actions to commit hashes; delete or disable `dependabot-merge.yml` and the unused release
  workflows in the fork; turn on GitHub's "immutable releases" and tag protection for `v*`.
- Medium: sign `SHA256SUMS` with a key that never touches GitHub (minisign or `ssh-keygen -Y sign`), with the public
  key written into `ix-update.ps1`. Then a release needs the GitHub account **and** the key.
- Or accept it as it is, and keep two-factor sign-in on the GitHub account. That is the user's call.

### A5. A version that crashes at start is installed for good
`ix-update.ps1` only moves forward; `start.bat` restarts the app 30 s after any exit. If a release crashes during
start-up, the loop restarts the same version for ever. Rolling back needs a person to write `data\ix-update.pin`. Every
version so far has installed clean (`history.jsonl`: the last three ended "clean"), so this has not happened; it is the
gap that turns a bad release from a nuisance into days lost if the user is away.

Fix: in `ix-update.ps1`, before checking for updates, read the tail of `data\crashes\history.jsonl`. If the installed
version has ended three times in a row within ten minutes of starting, by a crash, and `tgdl-server.exe.previous`
exists, put the previous program back and write the pin to its version, with a line in `ix-update.log`. The app's
report then shows "pinned after 3 crashes". `tests/ix_update_check.py` can cover it with invented history lines.

## 4. Findings that cost speed, requests or accuracy (B)

### B1. The database is re-read about 25,000 times a second (measured)
`internal/store/migrate.go` `sqliteDSN` (line 69), `internal/store/readonly.go` `sqliteReadOnlyDSN`.

Measured (20 s of Windows performance counters, 11-09 22:35): the app read 114.6 MB/s in 25,450 reads a second, 4.5 KB
each, while the drives delivered 15 MB/s (E:), 2.6 MB/s (C:) and 0 (D:). The hourly report says 244.6 MB/s over the
hour. So about nine reads in ten are answered from Windows' memory, not from a drive. All three drives are NVMe SSDs:
nothing is worn or thrashed. The cost is CPU.

Cause: no `cache_size` is set, so each of the 9 connections (8 readers, 1 writer) keeps SQLite's default of about 2 MB
of a 1,916 MB database. The repeated scans by background work (`ixWaitingApartNow`, `ixSavedIdentities`,
`ixSchedMessageDemand`, `ixBuildAlbumIndex`, `PendingManual`, all in the report's CPU section) fetch the same pages
through Windows each time.

Fix: `q.Add("_pragma", "cache_size(-65536)")` (64 MB) on both connection strings: at most 576 MB if every connection
fills up. The PC has 31 GB with about 3.9 GB available and the app already holds 1.4 GB of heap (3.0 GB reserved), so
not 256 MB each. Leave `mmap_size` alone. Measure `[process]` read MB/h and CPU % before and after in the same kind of
hour. The saving is unmeasured; under the speed limit CPU is not what limits downloads, in fast hours it has run at
110-148%.

Second step, only if the first shows a gain: the report's CPU section names the callers; a scan that runs every minute
over 400,000 messages or 200,000 queue rows deserves an index or a cached result.

### B2. One Telegram request per file to refresh its message
`internal/engine/controller.go`, line 1233.

`needsRefresh` is true for any file queued more than a minute ago whose Telegram file is not saved yet, which is nearly
every file. So each file costs one message request (the reference to its file may have expired) before its first part.
In the last 24 hours that was about 28,300 files. The report counted 5 "file reference" errors in the same time.

Two ways to ask less, both of which **remove** requests but change the pattern, so they need the user's OK and a
measurement first:
- **Try the stored reference first, and refresh only when Telegram says it expired.** A fresh reference then costs no
  request; a stale one costs one refused part request and then the refresh.
- **Refresh in batches.** One request can carry up to 100 message IDs of the same chat, so the next files of a group
  could be refreshed together.

Measure first (no new request): count, per hour, the refreshes made and how many returned a reference identical to the
stored one. If most are identical, the first option saves nearly a request per file. If few are, neither is worth it.

### B3. A part that gets no answer is retried 20 times, back to back, and never set aside
`internal/telegram/parallel_download.go`, lines 256-291; `floodguard.go` line 530.

A part request that Telegram does not answer within 2 minutes (`filePartTimeout`) comes back as a deadline error.
`fetchPart` retries it at once, up to 20 times, with no pause. Only Telegram's own "-503 Timeout" answers count toward
12.19's set-aside (`timeouts` rises only inside `if tgerr.Is(err, tg.ErrTimeout)`), so a silent part can hold one of a
server's part slots for up to about 40 minutes (21 tries of 2 minutes), and under the speed limit a server has two.

Evidence: rare today (the report: "timeout 4" in 24 h), so it is not urgent. Fix when convenient: count a local
deadline like a -503 for the set-aside rule (the same "other files of this server were answered meanwhile" test), and
pause between tries as for -503s. Download-path change: challenger review.

### B4. Every staged byte crosses the Wi-Fi link twice
`internal/download/staging.go`, lines 958-979 (`io.Copy`, `out.Sync()`, `verifyCopy`).

Measured (10 s sample, 11-09 22:10): wired adapter 0.0 MB/s, Wi-Fi 14.8 MB/s out and 14.5 MB/s in; the app copied
13.7 MB/s in the last hour. The copy is written to the NAS, flushed, and then read back in full and hashed. With the
NAS reachable only over Wi-Fi (the user's set-up for now), the read-back takes about half of the link.

This verification is deliberate and it is what makes staging safe, so nothing changes without the user's OK. Options,
from least to most change:
1. Leave it. The backlog (180 GB) drains in limited hours, and there is room for about 1,090 GB more.
2. Keep the full read-back, but **defer it**: publish and catalogue after the write and flush, keep the local staged
   copy until a second pass has read the NAS copy back in limited hours. Staging room is then freed later, not sooner,
   so this helps only the "files visible in the library" time, not the backlog. Probably not worth it.
3. **Hash on the NAS.** The NAS model (UGREEN DXP4800 Plus) can run containers. A small helper there that returns the
   SHA-256 of a named file would verify the copy from the NAS's own disk without sending it back: about twice the copy
   rate on this link, and a stronger check (it reads the disk, not a cache). It needs a new program on the NAS and a
   port open to the PC: a real change, to weigh after 11-30 or if the backlog ever threatens the staging room.
4. Sample the read-back (first and last megabytes and a few in between). Weaker than today; not recommended.

### B5. The copier's "copies running" figure undercounts
`staging.go`, `noteMoved` (line 141): a copy is recorded only when it ends well, with its whole duration, in the hour
it ended. Long copies still running, failed or postponed tries, and time before the hour are missed. The handoff's
"4.2 of 8 running" and this evening's "29,165 s in the hour = 8.1 running" are therefore not comparable. Count busy
copier-seconds directly around `moveOneStaged`, and free-slot seconds while files wait. (Handoff item 1 needs this.)

### B6. A crash spends an attempt for every file that was downloading
`engine/work.go`: `claim` adds one to `attempts` (line 466); `Recover` (611) puts "processing" rows back to "pending"
without taking it off, while a clean stop does (`Finish` with cancelled). With "keep trying" (MaxAttempts 0) this costs
nothing; with a limit, crashes eat retries. One-line fix in `Recover`: `attempts=MAX(0,attempts-1)`.

## 5. Security and privacy review (C)

What was checked and found sound:
- **Logins and cross-site requests.** Session cookies are HttpOnly and SameSite=Strict (`gateway.go` 277); changing
  requests are checked against Origin or Referer (`originError`); `/viewer/` is behind `requireAdmin`.
- **The viewer** listens on 127.0.0.1 only, needs a 48-hex-character token compared in constant time, sets a strict
  content policy (`script-src 'self'`, no inline script), serves saved files with `Content-Security-Policy: sandbox` and
  as downloads unless they are photos or videos, and opens the archive's database read-only.
- **Paths.** Library and staging access goes through `os.Root` and `filepath.IsLocal`; the updater extracts only the
  two named members from the archive.
- **Escaping in pages.** The three archive pages build HTML from strings, with 482 calls to `esc()`. I listed the
  interpolations that do not go through `esc()` or a number formatter (the 45 most frequent in each page) and read the
  ones that could carry Telegram text (chat names, captions, forwarded-from names, links). Each was escaped, a number, or a fixed word.
  `linkify` escapes first and only links `http(s)://` and `t.me/`. This was a sample by search, not a proof: the
  dashboard's policy allows inline script (`http_policy.go` 56), so there escaping is the only defence. The viewer's
  stricter policy is the better pattern.
- **Report redaction** is enforced by a test (`ix127_redact_guard_test.go`).

Findings:

**C1. Upstream pages call third parties.** `webassets/public/index.html` line 59 loads an icon font from jsDelivr, the
login and main pages load Google Fonts, and `js/tgs.js` and `js/viewer-text.js` load lottie, highlight.js, marked and
DOMPurify from cdnjs on first use, with no `integrity=` attribute. Each visit to those pages tells those services that
this browser uses the app (from the browser's own address, not the VPN's), and a script from them runs with the admin
login. The fork's own pages (`ix.html`, `browse.html`, the viewer) do not. Fix: copy the files into the program and
drop the outside hosts from the policy; or accept it until the standalone app replaces those pages.

**C2. Viewer start: back-off skipped on one path.** `ix_viewer_open.go` line 166: when starting the viewer process
fails, `p.err` is set but `p.failed` is not, so the "tried again after a minute" rule (line 158) never applies and
every request tries again. One line: set `p.failed = time.Now()` there. Also `cmd.Stderr = nil` (line 74) throws away
the reason a start failed; keep its last line (no paths) for the error message.

**C3. The viewer's cookie is not tied to its port.** Browsers send a cookie for `127.0.0.1` to every port on that
address, so any other local web program the same browser visits receives the viewer's token. Local only, and only
when the viewer is opened directly rather than through the dashboard. Fix: put the token in the cookie's name with the
port (`tgdl_viewer_8791`), and accept only a cookie whose name matches the port.

**C4. Wait counting in the fallback modes.** `floodguard.go` `invokeGate`: `attempt` counts every loop, including
speed-limit waits. In the "shared gate" and "as in 12.17" fallback modes a plain FLOOD_WAIT that follows three or more
speed-limit waits on the same request reaches `attempt >= floodInlineRetries` (line 629) and fails the part at once
instead of waiting. The normal per-request mode counts plain waits separately (`plainWaits`) and is not affected.

**C5. Decisions made on error text.** `ix_after_gone.go` line 48 retries when the error text contains "already". A
reworded message silently changes behaviour. Use a sentinel error (`errors.Is`).

**C6. Secrets on the data disk.** The pre-update copy puts the database, the session files and `secret.key` together
in `data\backups\pre-update-*` (by design: it is what a rollback needs). Anyone who can read that folder can use the
Telegram session until 11-30. Worth knowing; nothing to change now. After the account is gone, delete the session
files and the key from the data folder and from those copies.

## 6. Structure, tests and tooling (D)

These do not threaten the archive. They are why each release costs so much checking, and they are the main input to
the standalone plan.

**D1. One package holds everything.** `internal/app` is 73,700 lines of code in a single Go package: upstream's API,
and the fork's scheduler, copies and holds, ranking, ML and faces, report, updater, viewer and pages. Anything can
reach anything, so a change anywhere needs the whole package's tests (2-3 minutes natively, about 25 minutes under the
race detector).

**D2. State hangs off global maps.** 45 package-level `sync.Map`s keyed by `*App` (for example `ixTopUpStates`,
`ixViewerState`, `ixAfterGoneBusy`) hold the fork's state, rather than fields on `App`. That kept merges with upstream
clean, which was the right call for a fork. It also means state outlives a test's app unless each map is cleaned, and
nothing lists what state exists.

**D3. 436 package-level tunables.** Timings and limits are package variables so tests can change them. PRE-PUSH-
CHECKLIST.md already names this as the source of every CI-only race so far: a test changes one while a background
loop reads it. A struct of tunables passed to each component at construction removes the whole class.

**D4. The test app runs every background loop.** `ixTestApp` starts the staging mover, held copies, previews and the
rest, so tests race the app's own loops (the checklist's second failure pattern, and most of the "known flaky" list).
Loops should be off by default in tests and switched on by the test that needs one.

**D5. 62 settings and 76 routes in the fork alone**, on two single-file pages of 163 KB and 117 KB with inline script.
`ARCHIVE-LAYOUT-PROPOSAL.md` already lists the duplicated and contradictory controls. Many settings exist to switch a
change off if it misbehaves; after 11-30 most can go.

**D6. Tooling is fragile.** The Go toolchain lives in an old session's temp folder; this Go has no cgo, so the race
detector needs Docker; there is no `gh`; `gofmt` is not on PATH; Go programs see PATH cut at 2,046 characters. Each is
documented, and each is a way to lose an hour. Moving Go to a permanent folder (with the user's OK for the download if
the temp copy is gone) is the cheapest fix. Also: the version lives in two files and the changelog in two identical
copies; a script that writes both from one source removes a checklist step.

**D7. Unused upstream surface.** About 45 of the 134 tables are empty: the cluster and peer features, cloud backup
providers, share links, the NSFW blocklist, upstream's people tables. Their routes are still registered and their
background tasks still start. It is attack surface and start-up work for nothing here, but removing it from the fork
now is risk without benefit. The standalone plan drops it instead.

## 7. What is good and should be kept

- **The byte path is careful.** A partial download is synced before its offset is recorded and re-hashed before it is
  reused (`manager.go`); a file never replaces another (`publishExclusiveAt`); a size that does not match Telegram's
  fails the transfer; the staging journal is written before the local file is published, and every restart path
  (copied but not catalogued, catalogued but not removed, moved by hand) is handled in `moveStaged`.
- **Waits are handled from evidence.** Each rule in `floodguard.go` and `timeout_aside.go` carries the numbers that
  led to it, a cap, a fallback and a setting to switch it off. That is rare, and it is why later changes were safe.
- **The hourly report.** A redacted, numbers-only report that explains why each server did what it did is the reason
  problems here get found from numbers instead of guesses. Keep it in any successor.
- **Guards for the things that hurt once:** background tasks restart after a panic (`ixBackground`) instead of taking
  the downloads with them; the stall watchdog; the pre-update copy and the pin; the redaction test.
- **The viewer's separation.** A second process, read-only on the archive, its own small database for decisions,
  strict content policy. It is the right seed for the standalone app.

## 8. Suggested order

For 12.23 (all small, none adds a Telegram request):
1. A1: the after-the-account-goes run retries until it is complete. This is the one that protects the end state.
2. A2: the automatic integrity sweep becomes report-only, gives way to copies, and is counted in the report.
3. B1: SQLite cache size, with before and after numbers.
4. A3 and B5: counters only (engine runs ended by a database error; honest copier-seconds).
5. B2: counter only (refreshes that returned the same reference).
6. C2: the viewer's back-off line.
7. Handoff item 2 (idle servers under the limit), with its challenger review.

Then, as numbers and the user decide: A5 (step back after three crashes), A4 (pin the build actions; sign the
checksums or not), A3's retry if the counter is not zero, B2's change if most references come back unchanged.

After 11-30: everything in section 6, by way of the standalone plan (`STANDALONE-PLAN.md`), and C1, C3, C6.
