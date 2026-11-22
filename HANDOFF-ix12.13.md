# Handoff: ix.12.13 (redaction fix), an evaluation of the logs, and a rescan-list filter (2026-11-06, ~20:30)

Self-contained. Read first: this file, then the standing rules in `HANDOFF-ix12.9.md` ("Rules that matter most",
"Tools") and the project memory (`C:\Users\trabi\.claude\projects\C--Users-trabi-Claude-Projects-Telegram\memory\`).
Background analyses (read-only reviews, worth reading): `C:\Users\trabi\AppData\Local\Claude-Data\claude_pzs8sxrjxfjjc\side-session-notes\local_46479689-1733-4e8d-ace2-cc62b72929b9\`
(`ix12.11-build.md`, `ix12.12-challenge.md`: the dropped NAS plan, the local-caching question, the slow no-limit hours).

**Goal (unchanged):** save as much distinct content as possible before the account is deleted on 2026-11-30. A crash or a
bad restart costs more than most improvements: small, tested changes. Publishing installs on the user's archive within
about an hour (it restarts the app): tag only with the user's explicit OK for that version.

## State

| Version | Tag / commit | State |
|---|---|---|
| ix.12.10 | `v3.4.18-ix.12.10` / 6612e6c | live 15:54–16:59 on 11-06, ended clean |
| ix.12.11 | `v3.4.18-ix.12.11` / e0afb2b, PR #23 | live since 11-06 17:00:00 |
| ix.12.12 | `v3.4.18-ix.12.12` / a61c8d4, PR #24 | **published 11-06 ~20:20**, GitHub "latest"; should install by ~21:30. Check `E:\T\tg-dl\data\crashes\running` and `history.jsonl` (12.11 should end "clean"). |

Repo worktree: `C:\Users\trabi\Claude\Projects\Telegram\repo-v12.11` (branch `ix/v12.12`; the previous session is done
editing it). Create **`ix/v12.13` from `ix/v12.12`** there (`git checkout -b ix/v12.13 ix/v12.12`). A local-only branch
`ix/v12.12-nas-draft` holds a dropped draft: leave it alone. `repo-v12.7` belongs to another, finished session: don't
switch its branch.

## What 12.11 and 12.12 changed (for reading the logs)
- 12.11: parts a big-video check fetched are kept (`app/ix_part_store.go`, table `ix_part_store`, `data\ixparts`) and
  downloads take them (`telegram/kept_parts.go`, `fetchParallelKept`); the check floor steps 200→100→50→20 MB only when
  nothing at or above the step waits (`app/ix_sample_floor.go`).
- 12.12: kept-parts cap 100 GB, nothing kept under 60 GB free, the sweep frees the oldest while under 60 GB; a log line
  per download that took kept parts ("a download took N MB of its M MB file from parts kept from its check, not from
  Telegram"); the hourly report line gains "time per server, seconds summed over parts: DCn in flight …, answered …,
  failed … (… requests), waits … (speed-limit sleeps …), rate limit …, other …, k plain waits asked s" (report only:
  `telegram/pacer_hours.go` DCOkMs/DCFailMs/DCFails/DCWaitedMs/DCSleptMs/DCLimitMs/DCWaitSecs, `app/ix_diag_hours.go`
  `ixDCTimes`). "in flight" is sampled every 10 s (DCInflight × 10); the others are summed per request.

## Task 1: fix the report's redaction gap (ix.12.13)

The shared report (`data\ixreports\latest.txt`, hourly copies) showed, in the 18:00–20:00 copies, a log line from
`app/ix_subst.go:435` ("not downloading %s #%d: same bytes as %s (%s)") whose path came out as
`G<n>/<name>/videos/document_<19-digit Telegram document id>_<4 digits>_<hex…>.m4v`. The folder name was hidden, the
generated file name with the document ID was not. Causes in `app/ix_diag.go` `ixRedactor.clean`:
1. `ixReLongNum` is `\b\d{6,}\b`: `_` is a word character, so no boundary before the digits of `document_123…`.
2. `ixReFile` lists media extensions without `m4v` (also missing: e.g. `3gp`, `flv`, `wmv`, `mpe?g`, `ts`? careful,
   `wav`, `flac`, `opus`, `aac`, `webp` is there, `tgs` is there).
3. `ixReUnix` needs a whitespace/quote/`(`/`=` before the path; after a chat name was replaced by `<name>` (which
   contains `<>`, excluded from the token), the rest `/videos/document_….m4v` follows a `>` and is not matched.

Fix all three (hiding too much is safe, too little is not), e.g. long digit runs anywhere (RE2 has no lookaround: match
`\d{6,}` without `\b`, or `(^|[^0-9])\d{6,}` and keep the lead), more extensions, and a path rule that also starts
after `>`. Then extend the guard `app/ix127_redact_guard_test.go` (it fills every ixLog format with invented values and
checks the leaks list) with values like `G1/<name>/videos/document_1234567890123456789_1234_ab12cd34ef.m4v`,
`document_5555555555555555555.mp4` alone, and a `.3gp`/`.flv` name; add `"1234567890123456789"`-style leaks. Check that
counts (%d) that matter still read sensibly (a 6+ digit count becoming `<n>` is acceptable). Also look for other
generated names that carry IDs (`photo_<id>.jpg`, `document_<id><ext>` in `telegram/attachment.go:197,229`).

Then: gofmt, `go vet ./...`, `go test ./internal/app ./internal/engine ./internal/telegram ./internal/download`, CHANGELOG
(both copies identical: `CHANGELOG.md`, `core-service/internal/webassets/public/CHANGELOG.md`), version
`3.4.18-ix.12.13` (`core-service/internal/version/app.go`, `docs/archive-data-sample/data/manifest.json`), commit,
push, draft CI-only PR (`IX_VER=12.13 python -I ix-tools/gh_pr.py open BODY.md`), `ci_wait.py`, fix until green.
**Ask the user before tagging.** Prefer batching anything from Task 2 into the same release if it is small and tested.

## Task 2: evaluate the logs, new and old

Read the reports in `E:\T\tg-dl\data\ixreports\` (`latest.txt` every 10 min, `YYYY-MM-DD_HH.txt` hourly, 48 kept) and
the live DB read-only (`file:E:/T/tg-dl/data/db.sqlite?mode=ro`, counts only). Report numbers, never names or paths.
Questions, in order of value:

1. **Kept-parts reuse (12.11/12.12).** At 20:01 26 checked videos had parts kept (235 MB), none downloaded yet; checked
   videos download a median 23 h after their check (25% within 2 h, 95% within 49 h; 240 "no match" ones still queued,
   median 55 h waited). Look for the first "a download took N MB … from parts kept" lines and the "parts kept from
   checks: reused by downloads N MB …, in N downloads (refused … wrong length, … wrong bytes, … unreadable)" line. Any
   refused part is worth a close look (it means a kept part did not match). Check `ix_part_store` growth vs the cap and
   the 60 GB floor, and that the sweep removes files once downloaded ("files removed").
2. **Where each server's time goes (12.12), in the next hours Telegram does not speed-limit.** On 11-06 the limit was off
   02:00–09:59 and 15:00–16:59 (about 30 GB/h, against about 3 GB/h limited). In 03:00–08:00 DC1 delivered only
   0.4–1.5 MB/s per part in flight against DC4's 4–4.8, while Telegram answered DC1's parts as fast (0.19–0.26 s):
   the time went somewhere between the pacer giving a part its room and the request. The new line splits it into
   answered / failed / waits / rate limit / other. Decide what holds DC1 (gate waits after plain FLOOD_WAITs on other
   servers? the 60/s account limiter? something unmeasured = "other"?) and whether a change is worth its risk. Under
   the speed limit the line is mostly "waits" (speed-limit sleeps): that's expected.
3. **The answer-time pacing setting** (`paceByAnswers`, off). In no-limit hours bytes-judging refused most climbs
   answer-time judging would have kept (08:00: 14 of 19; 16:00: 17 of 18). The user is hesitant to turn it on because a
   mistake would cost the best (overnight) hours. Only recommend it with evidence from task 2.2, and never change the
   live setting yourself.
4. **Staging and the NAS.** The NAS and the PC are both on WiFi. The copier moves about 9–10 GB/h at best (write plus
   full read-back); 11-06 brought 283 GB in 24 h, so on heavy days the backlog grows. E had about 390 GB free at 20:00
   (the user cleared space); staging overflows its 20 GB cap while 50 GB stays free. Track "local staging … waiting",
   "oldest waiting", and "downloads went straight to the library … because staging was full" over the next no-limit
   hours. If the backlog keeps growing over days, revisit (see `ix12.12-challenge.md`: making staged videos visible to
   the copy rules is the riskier option; local fingerprinting was judged not worth it).
5. **Big-video checks and the floor (12.10/12.11).** "big-video checks: last hour … waiting for a check N (videos of X
   MB or more: the floor in use)": about 9–11 checks an hour, 2,015 waiting at 200 MB+, so the floor stays at 200 MB
   for days. Kept frames compared again: 444 comparisons, 0 copies since 17:00 (plausible, but watch). Is the check
   turn (3 min in 10) paying off: copies found per check, MB of parts per copy?
6. **Everything else in the report**: errors (5× -503 Timeout, 3× FILE_REFERENCE_EXPIRED are the usual background),
   failed/given-up downloads, the forecast to the deadline, the video index errors (60 videos ffmpeg cannot open: all
   checked on 11-06, exactly Telegram's size with MP4 headers and no zero runs: broken uploads, not a download fault),
   memory/CPU at startup (about 970 MB/s disk reads in the first minutes on 12.11, higher than 12.10's 620; probably
   index rebuilds, unconfirmed). Note anything that looks like lost content, a stall, or a crash risk.

Write findings to a note in the shared notes folder above (numbers only) and give the user a short summary with any
recommendation; build only what the user approves.

**Baseline: 12.11's last report before 12.12 installed (21:03, up 4 h 3 min, 0 crashes in 7 days).** Compare 12.12
against it:
- **Downloads:** speed-limited all evening, 0.8–1.3 MB/s, about 2.7 GB/h. Last 24 h: 275 GB in 7,599 files.
- **Errors:** **FILE_REFERENCE_EXPIRED rose from 3 to 9** in the recent-errors list over the evening (watch it).
  Also 5 × -503 Timeout, failed 6 (given up 5).
- **Kept parts:** 37 files / 338 MB kept, **still 0 reused after 4 h** (expected: checked videos download a median
  23 h later). E had **457 GB free** (the user keeps clearing space).
- **Big-video checks:** 11 an hour, 1–4 copies an hour; 2,001 waiting at 200 MB+. Kept frames compared again: 675
  comparisons since 17:00, **0 copies** (worth asking whether the recheck can find anything: does it compare against
  newly fingerprinted saved videos only, and are there any?).
- **Video index:** at 21:03 it said **"decoder cpu"**; at 17:13 it said "decoder cuda". The GPU decoder failed 3 times
  in the run, so the index fell back to the CPU for the rest of it (`ixVdupHW`, `cpuOnly`). A restart resets it. Check
  whether 12.12 falls back again and why: the CPU was at about 290% of one core at 17:02.
- **Staging:** empty. 40 files / 2.9 GB copied in the last hour at 3.9 MB/s while copying.
- **Memory:** heap 824 MB (1.7 GB reserved), 272 goroutines: steady.
- **Forecast:** at the last 24 h's speed (13.7 GB/h) the whole queue fits before 11-30, with room for about 4.9 TB
  more. If the speed limit stays on (4.6 GB/h), 31,221 of 32,618 queued files (2,170 of 2,738 GB) finish. The files
  that miss are at the back: held copies and set-aside files.

## Task 4 (**approved by the user on 11-06 ~21:15: "Yes, include Task 4"**): partly-same videos of ranked groups

The Priorities page shows a few "still needed" files for each ranked group, with estimates like "about 13 min–64 min
from now", but the ranked groups have nothing ready in the queue. The report says "only files held back or set aside
are queued". What's left looks like the **partly-same videos** (`ix_copy_hold.how='sampled-partial'`: 3–4 of 8
sampled frames match a saved video), which have been held at the back since 12.5. Ranks 1–8 hold 8, 12, 4, 4, 9, 2, 2
and 3 of them (4.7, 5.8, 2.0, 1.4, 3.3, 0.8, 0.7 and 2.1 GB). All 38 ranked groups together hold 67 / about 35 GB.
The Priorities estimate assumes they come in rank order, so it is misleading for these files.

The previous session recommended (pending the user's decision): in ranked groups, let partly-same videos go in rank
order instead of at the back. They are mostly footage the archive does not have, in the groups the user values most,
and 35 GB is about 1.3% of the queue. Non-ranked groups keep the 12.5 rule.

The dashboard has only "release all held files", which would also release about 5,300 probable copies: never suggest
it. A change would be:
- in `ixSampleRecord` (`app/ix_copies_sample.go`, the `sampled-partial` branch), don't hold when the group is ranked
  (`tgdl_group_rank`);
- a one-time release of the existing sampled-partial holds in ranked groups (like `ix_unlinked.go`'s one-time repair,
  with a kv flag);
- the same when a group is ranked later (`ixRankChanged`).

Test it. The user approved this change; build it into 12.13 (publishing 12.13 still needs their OK).

## Task 5 (fix): the video index blames the GPU for broken files

`app/ix_vdup.go:822-831` (`ixVdupStep`) counts *any* failed GPU decode as a GPU failure (`box.gpuErrors++`), then
retries on the CPU. After 3, the index uses the CPU for the rest of the run (`cpuOnly`). The failures are mostly
files ffmpeg cannot open at all: 60 of 69 index errors are "Invalid data found when processing input", broken uploads
saved exactly as Telegram has them. So three broken files in a run switch the whole index to the CPU (the 21:03 report
said "decoder cpu"; CPU was about 290% of one core). **Fix:** count a GPU failure only when the CPU retry then
succeeds (the file is fine, the GPU path is not). A failure on both is the file's fault and doesn't count. Test it with
a fake `ixFingerprintVideo`.

## Task 6 (fix, user-visible): a ranked group whose files are never queued

The Priorities page keeps showing "1 ranked group(s) have files missing that nothing will queue until they are
rescanned (2,792 file(s) still needed). Add it to the rescan", and the user says clicking it does not stick. It's rank
33: a basic group (id without the -100 prefix; never print it). What the data shows (read-only):
- 3,342 media messages recorded (2,188 videos / about 54 GB, 1,151 photos, 3 GIFs) but only 180 files saved.
- One `tgdl_work` row in all (completed). Not in the rescan queue (`kv` `ix_queue` has no item for it), not finished
  (`ix_group_info.finished_at`).
- In config it is `enabled: false`, with photos/videos/files filters on.
- History jobs (`tgdl_history_jobs`): five old-style walks on 11-02/11-03 ending in "context canceled", then a
  messages-only pass done 11-03 05:44 (3,361 messages). **No files pass ever ran**, and no job since 11-03, so the
  button's `POST /api/ix/queue/add` (`ix_api.go` around 225-300, `ixassets/ix.html` `pr-rescan-missing` around 926)
  has not led to a walk.

Find why. Is the add refused (`handleAPIGroupSave` with `ensureFilters` returning an error the page shows as "Could not
add")? Is it added and dropped? Does the files pass skip basic groups, or groups with `enabled:false`, or decide
`ixMissingFiles` is 0 (`ix_downloads.go:31`, `ixLoadGroup`) because of how it looks the group up? Is the item cleared by
"clear-finished" after a messages pass that found "nothing missing"? Ask the user to click once and read what the page
says, and watch for a new `tgdl_history_jobs` row. 45.8 GB of a ranked group is at stake.

## Task 7 (**the user's decision, 11-06 ~22:15: every big video is checked before it downloads**)

The user rejected the "smaller version" below as the goal (keep its unblocking parts as steps). Their reasoning: more
groups will be added, many with heavy overlap (the same videos re-encoded, so hashes differ), so the queue and its
copies will grow beyond today's forecast. Under the user's design:
- a check of a video that turns out not to be a copy costs almost nothing, since 12.11 reuses its parts;
- a copy found saves its whole download.

So big videos should not download unchecked. Every saved video is already fingerprinted (51,843 / 51,843 at 21:33),
so the check compares against everything saved.

**Preferred shape (the user, 11-06 ~22:25): one pipeline, not two.** The check should be the first step of a big
video's download, not a separate background job that tries to keep ahead:
1. the download worker claims a big video;
2. it fetches the sample parts (the index plus the parts around 8 points), samples the frames and compares them with
   the saved videos' fingerprints;
3. a copy is held at the back and the worker takes its next file; otherwise the same worker downloads the file at once,
   reusing the sample parts (12.11's kept parts, or keep them in memory for the same attempt).

Then "every big video is checked before it downloads" holds by construction: no gate, no race between check and claim,
and the check uses the download's own server and slot.

There is a precedent: `download.Library` already makes a decision before transferring
(`Substitute`, `download/library.go:100` and `:301`, used for exact re-uploads by Telegram's hashes, `app/ix_subst.go`).
A sampled check needs a third outcome there, "defer: hold this queue row at the back", not just link or download.
Design that outcome carefully with the engine's claim/finish semantics, and in tests.

**Sanity check by the reviewer (11-06 ~22:35): build it, with these conditions.**
- **Blocker, "defer" must be an engine outcome.** During the hook the row is `processing`. `ixHoldWork`/`ixLetGo` only
  change `pending` rows (`ix_held.go:448`), and a yield-like error puts the row back as `pending, paused=0`
  (`engine/controller.go:1257`), so it is claimed again at once and loops. Add a finish path that sets it pending +
  paused and writes `ix_held`/`ix_copy_hold` in one transaction, with no attempt spent.
- **Check rank.** Inside a download, parts carry the row's rank (`controller.go:1229`). Wrap the check's reads in
  `WithFileCheckRank`, or under the limit each sample part queues behind every better-ranked download.
- **Time budget.** `newAttemptBudget` (`controller.go:1184`) counts the check's ffmpeg and answer time. Give the check
  its own hard limit (10 min as now). Any check failure (no ffmpeg, no index, the 32-part cap, a timeout, a panic: add
  `recover`) means "download now", never an error.
- **Reuse.** Write kept parts synchronously before the transfer (`keptPartsFor` is read at the start of
  `downloadMedia`). Below the 60 GB free floor nothing is kept, so pass the parts in memory as the fallback.
- **Skip the check when a part file exists** (resuming). Run the exact re-upload check (Substitute) first, then the
  sample check; staging comes after, unaffected.
- **Fine as is:** a worker idle about 150 s under the limit holds no file slot (about 0.2 of 25 workers); the local
  ffmpeg range server inside a download; the same-file race goes away (`claimFree`).
- **Expectation:** 10–25% of front checks are copies. Most big videos start about 3–5 s later in no-limit hours, about
  150 s later under the limit.

Keep the separate background checks only for videos held as probable copies (to confirm or release them).

**Before asking the user to publish 12.13:**
- **A switch:** the in-download check gets a dashboard setting (on by default), so it can be turned off without a
  release if it misbehaves overnight. Off, downloads behave exactly as in 12.12.
- **A code review of the actual diff** by a fresh agent (read-only), aimed at the engine "defer" path: no row lost,
  looping, stuck in `processing`, or double-held, and the attempt count untouched. A restart while a row is deferred or
  mid-check must also be safe. Fix what it finds first.
- **Report lines** for the first hours after install: big videos checked in the download, copies held, the seconds
  each check added, and checks that failed and downloaded anyway (by reason). Under the
speed limit the check's waits are the download's own waits on its first parts, so little time is lost. Measure it.

**Design to build (verify each step, keep it small; steps 1–2 below are the fallback if the in-download check proves
too invasive):**
1. **Big videos (at or above the check floor) are claimed only once checked.** A "no match", or a check that failed
   for a final reason, releases them to download in their place; a confirmed copy is held at the back as now. Don't
   idle slots: the claim skips unchecked big videos and takes the next claimable file, as slot fill already does for
   full servers (`ix_slotfill.go`). Under the speed limit, bandwidth, not slots, is the constraint, so small files and
   checked videos keep it busy. One possible mechanism: the existing hold machinery with a new reason "waiting for its
   check", paused in place and released by the check (`ix_held.go`; 12.5 already releases held videos whose frames
   match nothing back to their place). Or a claim condition in the engine. Pick whichever is smaller and safer, with
   tests.
2. **Checks must keep ahead of the downloads.** Use the unblocking steps from the review below:
   - after a plain FLOOD_WAIT, pause checks 1–2 min, not 10, while Telegram isn't speed-limiting;
   - no 3-in-10 turn then;
   - a check stream back to back;
   - checks ordered by the claim's own key, so the next videos to download are checked first;
   - fix the held-turn skip.

   Under the speed limit a check takes about 2–3 min. About 8 big videos an hour download then (3 GB/h at about
   370 MB each), and one continuous check stream (about 20 an hour) keeps ahead. In no-limit hours a check takes 2–7 s.
3. **Fail open, never stall the archive:**
   - a check that times out or fails for a passing reason may be retried once soon, then the video downloads;
   - if no checked big video is claimable and nothing else is either, let the next unchecked one go;
   - if checks fall behind for long (e.g. the oldest waiting big video at the front has waited over 2 h), let it go;
   - report how many went unchecked and why.
4. **Watch the cost:** check parts take download slots under the limit (they hold a slot through speed-limit waits).
   Keep one check stream, not one per server. Report the bytes of check parts against copies found (MB held back).
   Confirm kept parts are actually reused by downloads (0 so far at 21:03, 2 MB by the review): if they aren't, fix
   that first, because the design's economics depend on it.
5. **Report lines:**
   - big videos downloaded checked vs unchecked (and why);
   - videos waiting for their check;
   - checks an hour, by not-held vs held;
   - copies found among not-held videos;
   - MB held back.

**The review's numbers still matter** (`ix12.13-check-rate-challenge.md`):
- not-held checks confirmed 10–25% (39% overall was inflated by already-held videos);
- copies average about 360 MB;
- in no-limit hours the plain-wait rule blocked checks completely.

At 10–25%, with a no-match check costing near nothing, a check before every big download is still well worth it,
which is the user's point.

The review's smaller version, kept for reference (its unblocking steps are step 2 above):


Read the review first: `ix12.13-check-rate-challenge.md` in the shared notes folder (12 ranked findings, read-only,
11-06 ~22:00). The previous session's first plan (one check per server running continuously, a claim gate, lifting the
turn everywhere) was challenged and **replaced by the smaller version below**. Why:
- **What stops checks in no-limit hours is the plain-FLOOD_WAIT rule**, not the 3-in-10 turn: `ixSampleChecksBusy`
  (`app/ix_remote_budget.go:79`) blocks every check while downloads are busy and any plain FLOOD_WAIT came in the last
  10 min (`ixFloodedLately`, `Floods10m`). No-limit hours had 30–64 plain waits an hour, and checks were 0 at 03, 07,
  08 and 09. A check takes only 2–7 s when Telegram isn't limiting.
- **The 39% hit rate is inflated** by checks of already-held videos (66% confirmed, no gain: they are already at the
  back). Not-held checks confirm about 10–25%, and those copies average about 360 MB, not 800 MB.
- **Under the speed limit**, parallel checks would take about half the download slots (check parts hold their slot
  through 11–15 s speed-limit waits, and windows are 2 parts per server).
- **The forecast under the limit** loses only copies (159 GB), not distinct content. Checks pay most if no-limit hours
  stop, and then the current rate covers the 1,090 unheld unchecked big videos in about 4.5 days.
- **One check per server doesn't fit:** 166 of the 197 unchecked big videos at the front are on DC1.

**Build (about 30–60 lines):**
1. Only while there have been no FLOOD_PREMIUM_WAITs in the last 10 min (Telegram not limiting):
   - block checks only while the files gate is closed, or for 60–120 s after a plain wait (not 10 min);
   - skip the 3-in-10 turn;
   - let one round run up to about 40 checks back to back, still one at a time.

   Target: 70+ checks an hour in no-limit hours, at about 3% of the parts. Under the limit, keep everything as it is.
2. Order the checks by the claim's own key, so the videos about to download are checked first, unpaused rows first.
   The next 60 picks were found 39–113 GB into the queue.
3. Fix the held-turn skip: the top held rows share a Telegram file whose check failed and waits to retry, so
   `ixSampleFileWaits` skips them and the held turn is given away. No held video was checked for 6 h.
4. `-threads 1` for the check's ffmpeg.
5. Confirm that kept parts are actually reused (0 so far) before counting on it.

**Not now:** the claim gate (unless big videos still download unchecked after this) and parallel checks.

**Known concurrency risks, if parallel checks are ever built:**
- `ixRunCopies` and `ixRunHeld`'s hook can already check the same row at once;
- two rows of the same Telegram file can be checked at once;
- the shared turn;
- `recover` in any spawned goroutine.

**Measure** with the 12.10 rate line and the 12.12 per-server times in the next no-limit hours: checks an hour, copies
found among not-held videos, plain waits per server.

## Task 3 (low priority, the user's request): hide channels and supergroups in the rescan list

In the Archive tab, **Rescan → Choose groups** (`core-service/internal/app/ixassets/ix.html`, `viewRescan`, the pick
list), add a toggle to hide channels and supergroups (or a type filter: groups / supergroups / channels), so the list can
be narrowed before ticking. Ticks must survive the filter, as they survive the search ("ticks stay when you change or
clear the search"), and "Rescan N ticked" must still act on every ticked group, shown or not. Say in the UI how many
ticked groups the filter hides.
- Chats from "Show all my chats" already carry Telegram's type: `loadDialogs` (around line 906) keeps `d.type`, set in
  `telegram/dialogs.go:248-284` (`channel`, `supergroup`, `group`).
- The configured groups come from `state.status.groups` (`groups()`, line 102), which may not carry a type. Add it on the
  server side from what the app already knows (the dialogs listing, or `ix_group_info`, read once), not with a new
  Telegram request per group. A group whose type is unknown stays visible.
- Remember the toggle per viewer with localStorage, wrapped in try/catch (the page uses none yet; a private window or
  blocked storage must still work, just without remembering).
Batch it into 12.13 only if it is small and tested. Otherwise leave it for a later version and tell the user.

## Lessons from 11-06 (avoid repeating)
- **CI runs `gofmt -l .` first.** Run it locally before pushing.
- **The release workflow's app tests can flake**: `TestHistoryBackpressureHonorsConfiguredStallDeadline` failed once
  (pages=2, want 1) on 12.11 and passed 120 local runs; re-run only the failed job via the API
  (`POST /repos/whothis44/telegram-media-downloader/actions/runs/<id>/rerun-failed-jobs`, token from `git credential
  fill` as the ix-tools scripts do), then `gh_release.py wait` again.
- **No git identity on this PC**: commit with `git -c user.name=Claude -c user.email=noreply@anthropic.com commit …`
  and end messages with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- **Bash heredocs with Python containing `'''` broke once**; write edit scripts with the Write tool and run them with
  `python -I`. Python writes CRLF in text mode unless `newline=''`.
- `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env.sh` (absolute path) before `go`.
- SQLite cannot split `tgdl_work.identity` (NUL-separated): split in Go/Python, or match `ix_messages.media_key`.
- Reports: the by-hour table spans 24 h; hourly copies exist from 11-06 13:00; "last hour" counters in a report written
  right after a restart cover only the time since the restart.
- Tests pin report line counts (`ix_copies_test.go` expects 6 copies-diag lines since 12.11): update them on purpose.

## Tools (in `ix-tools`)
`env.sh`, `gh_pr.py` (`IX_VER=12.13 python -I gh_pr.py open BODY.md | runs | jobs RUN_ID`), `gh_release.py`
(`IX_VER=… wait | show`), `ci_wait.py SHA BRANCH` (background), `ci_log.py RUN_ID "JOB NAME" OUTFILE`.
Baseline test failures on Windows (not regressions): `internal/backup`, `dbread`, `faststart`, `fsx`, `hash`, `config`.
