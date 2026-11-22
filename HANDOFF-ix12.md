# Handoff: ix.12.1 live, ix.12.2 waiting, ix.12.3 planned (2026-11-05, 14:30 local)

Repo: `C:\Users\trabi\Claude\Projects\Telegram\repo` (`whothis44/telegram-media-downloader`), branch `main`.
Live install: `E:\T\tg-dl` (read it only; never stop, replace or edit it). Its `start.bat` loops and runs
`ix-update.ps1` before every start, and the updater installs any newer GitHub release. **So publishing a
release installs it on the user's archive at its next start: publish only with the user's OK.**
Account: non-Premium, frozen; deletion date 2026-11-30.

**Helper scripts** from the previous session (Go toolchain `env.sh`, `wait-ci.py`, `wait-rel.py`, `ci-now.py`,
`ci-log.py`, read-only `live_check*.py`) are in
`C:\Users\trabi\AppData\Local\Temp\claude\71f159c3a9e5d4b9\63fc91bc-a626-41aa-a92f-6717bf517e6d\scratchpad\`.
A new session has its own scratchpad: copy what you need from there.

**Two sessions at once:** the previous session is publishing ix.12.2 (tag `v3.4.18-ix.12.2` on `93b7dd6`). Do not
tag or publish ix.12.2 yourself. Branch ix.12.3 from `main` at `93b7dd6` (`git checkout -b ix/v12.3 93b7dd6`), and
publish ix.12.3 only after ix.12.2 is out and seen working live, with the user's OK.

## State

| Version | Commit | State |
|---|---|---|
| v3.4.18-ix.12.1 | `289768a` | Published and verified (checksum, real updater, crash-log start on a throwaway folder). **Live since 14:25.** |
| 3.4.18-ix.12.2 | `93b7dd6` on `main` and `ix/v12.2` | Pushed; CI was running. **Not tagged.** Publish only after ix.12.1 is confirmed on the live archive, and with the user's OK (they asked for it to be built). |

## Next steps, in order

1. **Confirm ix.12.1 live.** Ask the user for diagnostics about 20 minutes after 14:25. Look for:
   - no new crash: `[restarts]` should show the run up and no new `crash` entries;
   - big-video checks working: new `checked … from N MB of parts: confirmed/nomatch` lines, and the timeout count
     (23 at 14:16) no longer climbing. Some timeouts under heavy limiting are still possible.
2. **Publish ix.12.2** once CI is green and step 1 is fine: `git tag v3.4.18-ix.12.2 93b7dd6`, push the tag, wait for
   the "Release native server" workflow, then verify as for ix.12.1 (scratch copy of the live exe plus `ix-update.ps1`).
   Watch scripts are in the scratchpad (`wait-ci.py <sha>`, `wait-rel.py`); `gh` is not installed, the scripts use
   `git credential fill` against the GitHub API.
3. **Build ix.12.3** (user agreed; "be careful it doesn't break anything"):
   - resume in the local staging folder too (today staged downloads start over: tell the user **not** to turn staging
     on until this ships), with the real-process kill tests as for ix.12;
   - checkpoints every 8 MB or 30 s, and resume from 8 MB up (today 64 MB). Measure a checkpoint's cost on the NAS
     first, using a scratch file in a test folder, never the downloads; pick the smallest interval that does not slow
     unlimited downloading;
   - staging folder: a drive picker (local drives with free space, a suggested folder) instead of the text box, with a
     line saying what staging does;
   - **automatic updates with no progress lost** (the user's requirement): an on/off setting "Install updates
     automatically" that starts the drain by itself when a newer release appears (today the Archive banner needs a
     click). The drain: no new files start; files under the checkpoint size finish (seconds to minutes); larger files
     stop exactly after a checkpoint (nothing lost, they resume after the restart); nearly finished files get the
     bandwidth meanwhile; then the app exits and the launcher restarts it. The user's `start.bat` already loops, but
     it lacks `set TGDL_LAUNCHER_RESTARTS=1`, so today the app only says when it is safe to close: tell them to add
     that line, or detect the loop. Also offer "pause at next checkpoint" in the queue. Only a crash or power cut may
     still lose up to one checkpoint interval per file;
   - diagnostics: megabytes per Telegram server (DC) per hour, to settle whether the speed limit is per server. The
     30-hour history said **no**: four servers busy in limited hours still gave about 1.5 GB/h in all, but evening
     files were small;
   - cosmetic: the console line prints `·` as `Â·` (use ASCII), and a "no report" run ended within its first minute
     says "after 0s" (the marker is only touched once a minute).

## ix.12.3 also: one place for each Archive control (the user chose "merge into one place")

The user finds the Archive tabs duplicated or contradictory: mainly Overview and Downloads/Copies, besides
Priorities, Account safety and Rescan. They want **each control in one tab only**, with each saying what it
affects. Assess every tab yourself, independently: their list is a start, not the limit. Propose the new layout
to them before moving controls (a short list: control, where it is now, where it goes, why), and break nothing.
Every move must keep the same setting key and API, so saved settings and the dashboard keep working. Check the UI
with the Playwright tests in `tests/ui/` and add one for each moved control.

Facts already confirmed in the code (`internal/app/ixassets/ix.html`, `ix_queue.go`, `ix_sched.go`,
`ix_safety.go`, `ix_deadline.go`, `ix_copies_sample.go`):
- **Rescan's ★ First is the Priorities ranking**: `q-priority` calls `ixRankSet`, which appends to or removes from
  the ranked list. Lane order is place (rank) first, then ★, then the deletion-date triage (the `better` function in `ix_queue.go`, around line 345).
  Candidate: turn ★ into a link to Priorities or a "rank it" action.
- **Account safety → Pace** sets the rescan breaks and `backpressureCap` (500 normal, 200 gentle), the queue size
  at which rescans stop adding files ("queue 1075 of 500 · backfill paused by the queue limit"). It does not
  change order; ranking does.
- **Quiet hours** (Account safety) only stop new group passes and ranked takeovers (`hold` in `ixQueueDeps`);
  downloads go on. A second, separate quiet window exists for duplicate finding and fixity (`dupQuiet*`).
- **Deletion-date order** (Account safety) sets aside unranked files by size band; ranked files are never set aside
  and use the bands only within their rank.
- **Hold likely copies** (Account safety) also gates big-video sampling (`ixSampleRound` returns when it is off),
  while the other copy settings sit in the Copies card. Held copies go last whatever the rank.
- **Pause on freeze**: its warning used to sit two settings away (moved next to it in ix.12.1). "frozen false" in
  `[account]` and "freeze: since …" are two different notions on one screen; explain or merge.
- **Big files at once** (Big videos and the NAS card) is the ≥1 GB lane; the 20 MB file-slot split (2 large, 5
  small per server) is not a setting at all.
- ix.12.1 only added wording (Priorities' last paragraph, labels on Pace, Quiet hours, the deletion-date select,
  Hold likely copies, a tooltip on ★). ix.12.3 does the actual merge.

## Everything else still open (swept from the whole day; the user asked that nothing be left out)

Ranked by effect on downloading. Do your own sweep too: `HANDOFF-ix11.md`, the CHANGELOG's limitations, and
the user's diagnostics. Raise anything else you find; do not wait to be asked.

**Verify first (new code not yet seen live):**
1. ix.12.2 live: check that small files get parts at all, and that the ranked big files' speed holds. Parts are
   handed out by rank (`pacer.go`), so lower-ranked small files only get what the big ones leave; the gain may be
   modest. Correct the CHANGELOG's ix.12.2 line "the ranked big files share the speed": they keep priority, and
   small files of lower ranks get the leftovers. Also: small files should download alongside big ones (diagnostics' `file slots: small N/5` above 0, and
   rows under 20 MB in processing), and no `ix_lowq` rows for ranked files. A worker that makes room claims a small
   file next; there is no controller-level test of that loop yet: add one.
2. ix.12.1 live: checks succeed, no new crash in `[restarts]`, previews fetched (3 in the first minutes, against
   0 before).
3. Resume (ix.12): `partial downloads kept` counts grow and files carry on after a restart.

**Fixes worth making:**
4. **Ranked groups with missing files are not queued by themselves**: Priorities says "files missing but not
   queued: add it to the rescan" (places 10, 14 and 19, 39 files). The app should add such a ranked group to the
   rescan itself, or offer one click.
5. **Crash cause words go to the window only.** Go writes the `fatal error: …` line before it writes to the crash
   file, so the file names only the functions. Have `ix-update.ps1` run the app with stderr copied to a bounded
   `data/crashes/window.log` too, keeping the console as it is.
6. **Coverage counts**: rows held as lesser copies of queued files (`ix_held.like_key=''`, 3,943 live) are left out
   of the browser model's held map, so they count as "needed", not "probable"; the header's "probable 0" follows.
7. **Per-server "now" speed is quantised** (bytes in the last 5 s: three 1 MiB parts show as 0.63 MB/s), which
   made servers look identical. Show the 5-minute figure first, or a longer window.
8. **Connection turnover**: at one point all 9 Telegram connections were under 5 minutes old. Unexplained, never
   looked into; a reconnect loop would waste time under the limit.

9a. **The live queue list jumps** (user report). `engine/snapshot.go` sends the downloading rows plus the first
    1,000 pending rows by id (queue order), but since ix.11 files download in claim order (rank). A row from deep in
    the queue starts, pops into the middle of the list, then vanishes. The ix.11.1 "follow the live order at the
    top" re-render (`queue.js`, `FOLLOW_TOP_MS`) makes it visible every 1.5 s. Fix: send the next 1,000 in claim
    order (`claimOrderSQL`) and make that the Current tab's default order ("download order": downloading first,
    then what comes next), so rows move only when one finishes. ix.12.2's room-making adds churn (more starts and
    finishes), so do this in ix.12.3. Also: ix.12.2 sorts Done and Failed by finish time (newest first) when the
    sort menu says "Added time", so rename that default in those tabs, e.g. "Finished time" (mind the i18n key
    `queue.sort.added`, which replaces the HTML text).

**Measure before deciding:**
9. Whether Telegram's limit is per server (per-DC MB per hour, above). The 30-hour history said no.
10. Whether the limit is a volume allowance that recovers while idle. It lifted twice after quiet stretches; if so,
    updates and restarts are nearly free and could be timed for limited hours.
11. The 2 large / 5 small file slots per server (20 MB boundary) are fixed, not a setting. After ix.12.2, check
    whether more large slots would help unlimited hours.

**Known limits, not urgent:**
12. A running transfer keeps its place when a better-ranked file arrives; one group per rescan lane.
13. Overlap between groups is not predicted, and value is rank only. Checks vs downloads are not weighed by expected
    value, and lower-quality copies get no credit.
14. Previews: about 74,000 to fetch at one request per 1.5 s within a 30 s per 10 min turn under the limit. They
    will not all arrive before the deadline; fine unless the user wants otherwise.
15. **Fix first in ix.12.3:** `TestIxFFmpegFramesAtTheRightTimes` flakes (old code too). It failed ix.12.2's
    46-minute archive job ("frames: [4000 ms 160 px (asked 5 s) …]": a keyframe a second early), the only failure
    of 238, and cost a 45-minute re-run. Make it tolerate the keyframe the encoder chose, or generate the test video
    with a keyframe at every frame it asks for. Use `scratchpad/ci-log.py <run id> <file>` to fetch a job's log, and
    the GitHub API `rerun-failed-jobs` to re-run only what failed.

## What changed today (for context)

- ix.12 (update button, resume of files ≥64 MB) published at the user's request.
- The live app had been crashing every 2–3 hours since ix.10.2: `fatal error: stack overflow` from face grouping
  (`ixGroupFaceLocked` and `ixFaceJoinFirstLocked` sending each other round). Fixed in ix.12.1. The launcher hid it.
- ix.11's ranking left check and preview file parts unranked, so under the speed limit they got no part and timed out.
  ix.12.1 ranks them ahead (`telegram.WithFileCheckRank`).
- ix.12.1 also: crash log in `data/crashes` and a `[restarts]` diagnostics section (`internal/crashlog`), big-video
  checks answer once per Telegram file and stop early, and wording on how Priorities, Account safety and Rescan interact.
- ix.12.2: a large file parked on its slot makes room for small files (`telegram.ErrDownloadMakeRoom`,
  `WorkStore.ClaimSmaller`); lower-quality-first leaves ranked files alone; queue rows open the file saved for them;
  Done and Failed sort by finish time; a search that reads as a file name pins matching files first.
- Dropped on purpose: changing the finish estimate's speed. While the limit is on it deliberately uses the last 3
  hours (see `ixDeadlineRate`).

## Open observations

- Speed-limited hours give about 1–2 GB/h, unlimited hours 16–32 GB/h. Limits lifted 01:00–05:00 today and
  06:00–08:00 yesterday, both after quiet stretches; possibly a volume allowance, unproven.
- 28 ranked groups need about 290 GB, which fits; the unranked rest (about 2.8 TB) likely will not.
- Priorities places 10, 14 and 19 say "add it to the rescan" (39 files): the user's action.

## Tests and tools

- Go 1.27.3 portable: `source <scratchpad>/env.sh`. Windows baseline failures (not regressions): backup, config,
  dbread, faststart, fsx, hash. `TestIxFFmpegFramesAtTheRightTimes` flakes on old and new code.
- Live database reads: `sqlite3` with `file:E:/T/tg-dl/data/db.sqlite?mode=ro`, counts only. The user's media and
  names are private; tests use invented data.
- Commits: `git -c user.name="Claude" -c user.email="noreply@anthropic.com"`, ending with the Co-Authored-By line.
  Never force-push.
