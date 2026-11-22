# Handoff: ix.12.23 built, for the session after it

Read first: `START-HERE.md`, `CLAUDE.md`, then this file, then `PRE-PUSH-CHECKLIST.md` before any push.
`HANDOFF-ix12.23.md` holds what 12.23 was asked to build and the 11-09 measurements behind it.

## What 12.23 is (branch `ix/v12.23` in `repo-v12.16`, from `ix/v12.22`)
The changelog entry (CHANGELOG.md, 3.4.18-ix.12.23) is the user-facing list. In code:
- `ix_after_gone.go`: final index and backup retried until complete (both ok, nothing staged); 3 a day, 1 h apart;
  cut-short runs counted (max 5); busy errors are sentinels (`ixErrExportBusy`, `ixErrBackupBusy`).
- `integrity.go` + `ix_integrity_auto.go`: the automatic hourly sweep is report-only, 4 stats at once, gives way to a
  staging backlog above 50 GB; manual Verify files still prunes.
- `store/migrate.go`, `store/readonly.go`: cache_size 64 MB per server connection, 32 MB per viewer connection.
- `download/staging_clock.go`: copy step timings and copier occupancy, report line "staging copies, last hour".
- `engine/ix_counts.go`: run stops by claim/finish errors, longest Finish, refreshes with the same file reference
  ([restarts] section).
- `ix_topup.go`: under the speed limit, a server with nothing processing and nothing claimable gets at most 2 files
  (setting `topUpLimitedOff`); report: minutes idle under the limit per server, files queued then.
- `ix_data_export.go`: `not_saved.jsonl`, `telegram_user_ids` in the manifest.
- Viewer: `viewer_set.go` (album set), album tiles (`vGroup.AlbumPost`, setting `albumFiles`, query `albums`),
  `lightEval`, cached overlay (`ovGen`), faster related rows; `viewerassets/app.js`: album strip `#v-set`, Chats album
  merge, folded copies (`details.fold`, localStorage `v.copiesOpen`/`v.albumOpen`), prefetch.

## After 12.23 installs, read (latest.txt, numbers only)
- Version line; history.jsonl: 12.22 ended "clean".
- `[restarts]`: "download runs stopped by a database error" (if not 0: review A3's retry is worth building) and
  "message refreshes … same file reference" (if most are the same: B2, try the stored reference first; needs the
  user's OK, it changes the request pattern).
- "staging copies, last hour": expect write and read back to take nearly all the time (Wi-Fi, finding A).
- "hourly file check (report only …)": how many look missing (should be near 0; a large number means a share issue).
- Top-up line: "under the speed limit … DCx idle N min, queued M": compare that server's MB/h under the limit with
  11-09's (DC2 348 MB at 12:00, idle at 21:26). "Looks like" until several limited hours agree.
- `[process]` read MB/h and CPU % against 12.22's in the same kind of hour (cache size).
- Viewer: only the user can judge it on real data; ask whether the five complaints are better.

## Open
- Item 16 (the "already archived" import for a second install) still waits for the user's go-ahead.
- A5 (step back after three crashes at start) and A4 (pin build actions / sign checksums) not built.

## 11-10: after 12.23 installed
- 12.23 live since 11-10 01:58:31 (12.22 ended clean). First read: see memory/status; database-error stops 0, refreshes
  all changed (B2 not worth it), file check 0 missing. The user switched the limited-hours top-up ON that morning:
  compare DC2's MB/h in limited hours with 11-10 00:00-07:00 (0-255 MB/h, idle 155 of 346 min).
- Branch `ix/v12.24` (from `ix/v12.23`), commit 3274c8e, NOT pushed: the viewer's album across chats as one album to
  flip through (pinned set; arrows include files from other chats; "Flip through N" button; album tile opens on the
  album's first file). Viewer challenger review run, findings fixed. Needs a CHANGELOG entry, version bump, the
  pre-push checklist and the user's OK before any push or publish.
- 11-10 later: **12.24 PUBLISHED** (tag v3.4.18-ix.12.24 = 9907fe8, PR #36, CI green, release 42886350193, 8 archives
  plus SHA256SUMS, latest). Contents: the album flip-through (above) and the limited top-up kept at up to 3 files for a
  server with no work of its own, ranked first, private before public, largest under 512 MB. After install read: DC2's
  MB/h in limited hours against 11-10 08:00-12:00 (97-258 MB/h, idle ~2/3 of minutes, 97 refreshes/h); the top-up line
  "kept full" minutes; refreshes per hour (should fall with larger files).
- Next proposed (needs the user's OK): **12.25 per-server big-file lane.** engine/work.go's lane (2 for the account)
  dates from before per-server windows; 11-10 13:54 both places were DC1's while DC2/DC4 sat near-idle with 41/25 big
  files waiting. Change the claim statement's lane count to the candidate's server (and idx_tgdl_work_claim,
  TestClaimIndexMatchesTheLane), keep the "twice as many" rule per server.
- 11-10 evening: **12.24 LIVE since 16:18:23** (12.23 ended clean). Speed limit back ~16:00.
- **12.25 built, NOT pushed** (`ix/v12.25` = 6edc4bd, from ix/v12.24): per-server big-file lane (setting bigPerServer,
  default 1; new indexes idx_tgdl_work_big_server, idx_tgdl_work_ready_server, INDEXED BY in the claim); in-download copy
  check 30 min under the limit (and first 15 min after start), timed-out-on-slow-parts files put back 1 h (4 tries),
  parts kept after timeouts and reused, 10 checks at once; frozen chat details not asked again for 24 h. Challenger
  finding: 12.23/12.24 did not change the check; parts under today's limit ~60 s each. Reviews: lane challenger, check
  challenger, Fable 5.2 (medium): findings fixed. Needs the user's OK to push/publish.
  After install read: "big videos checked in their download" line (put back N, downloaded anyway N), copy-check timeouts
  per hour (ix_copy_sample reason='timeout', read-only), big files downloading per server, claim cost (no direct line).
- **12.25 PUBLISHED** 11-10 (tag v3.4.18-ix.12.25 = 6edc4bd, PR #37, CI green, release 42929390556, latest). Install not verified.
- 11-10 late: 12.25 LIVE since 21:49:41 (the user installed it by hand: the automatic install's 20-min drain fails under
  the speed limit; a fix is worth doing). **12.26 PUBLISHED** (tag v3.4.18-ix.12.26 = e027c8e, PR #38; the release job
  failed once on TestHistoryCapIgnoresItemsWaitingApart, flaky, 30/30 locally, re-run passed). 12.26: no big video
  downloaded unchecked under the limit while its check can answer (put back, ix_check_putback), two frames at once,
  checks before claim with the limit off (report counts them per hour: a request pattern to watch).
- Speed under the limit since 11-10 16:00: ~170-200 MB/h per server (was 300-400), ~200 limit waits/h per server (was
  ~420): Telegram's wait per part about doubled; our side unchanged (2 parts in flight per server). DC5 near 0 for hours.
- 11-11: **12.27 PUBLISHED** (tag v3.4.18-ix.12.27 = 66cdc26, PR #39): automatic updates install under the speed limit
  (a running in-download check stops and puts its file back when an update drains; no check starts during a drain;
  staging-room waits give way; 12 min into an automatic drain everything but self-destructing media stops at its last
  checkpoint; the give-up log names what was still going). After install: the next automatic update should finish
  without a manual install; read "automatic update" log lines and the check line's "put back for an update N".
- 11-11: 12.27 LIVE since 00:37:18 (12.26 ended clean; install path not shown: may have been by hand).
- **11-11 correction: the limited-hour drop since 11-10 16:00 is ours, not Telegram's.** floodguard.go's fallback
  ("most file requests refused": >=40 limit waits in 10 min and > 2 per answered part) put every file back behind
  the shared gate (pre-12.4 waits) for 2 h at 16:19, 18:26, ~20:30, 21:50, 23:28, 00:38: four of six one minute
  after a start (cold start: no answered parts on record yet). It never fired under 12.20-12.23. In those hours
  each server's parts sat ~97% of the time behind "all servers" (held ~7,000 part-s/h per server), unthrottled()
  is empty so no file can be claimed, and Telegram's asked wait stayed ~16 s (it did not double: we sent half the
  requests). DC1+DC4 (always busy): ~740-790 MB/h per-request (11-10 01:00-12:00) vs ~360-390 MB/h shared
  (17:00-00:00); all servers ~935 vs ~670 MB/h. One day each: "looks like". Proposed 12.28: no fallback without
  enough answered history (not in the first minutes after start), judged per server or off, plus a setting.
  Raised by an outside review (11-11) whose other points: unlimited hours 11-10 14-15:00 DC1 window ~3 of 8 full
  with ~14 parts waiting (growth slow), other servers' room unused for lack of files; the 1 s margin per wait.
- **12.28 built and pushed 11-11** with the user's OK ("Build and push it out"): branch `ix/v12.28` = 999a4af (from
  ix/v12.27), draft CI-only PR #40. floodguard.go: fallback needs 10 min of record (warm-up restarts at a start,
  after a quiet 10 min, and after its own 2 h: records cleared, filesSince = sharedUntil), and every busy server
  (>=10 parts+waits in the window) refusing on its own; setting `speedFallbackOff` (Settings → Downloads) never
  takes it and ends one in progress (period clipped in the report). Challenger reviewed twice: re-arm and idle
  findings fixed; no blockers. All six packages, race on telegram and the app tests touched: green.
  After install read: "back to every file waiting, since start" (expect none or rare), per-server MB/h in limited
  hours against 11-10 01:00-12:00 (~935 MB/h all, DC1/DC4 ~380 each), and "held per server … all servers" (~0).
  The 1 s margin per wait was left alone (unmeasured; would change the request pattern).
- **12.28 PUBLISHED 11-11** (tag v3.4.18-ix.12.28 = 999a4af, CI green 42974674282/-291/-506, release 42978971801,
  8 archives plus SHA256SUMS, latest). Install not verified: check crashesunning, history.jsonl (12.27 clean).
- **11-11 08:35 read of 12.28: the 11-11 diagnosis above was WRONG.** 12.28 live since 02:46:26 (12.27 ended clean
  02:45:52, 34 s gap at night under the limit: looks like 12.27's automatic install worked). Per-request hours under
  12.28 (03:00-05:00) brought DC1+DC2+DC4 561-581 MB/h, the same as the shared-gate hours before and after (530-588
  MB/h, 11-10 17:00 to 11-11 07:00). The 11-10 morning's 770-1030 MB/h was a different Telegram regime: per-request
  MB per speed-limit wait fell from ~0.9 (11-10 01-12h) to ~0.45 (11-11 03-05h); Telegram halved each server's
  allowance around 11-10 16:00, as the earlier note said. The mode makes no measurable difference now; the shared
  gate gets the same bytes with about half the refused requests. 12.28's rule still fired twice (06:04, 08:21),
  as designed: every busy server refusing more than 2 per part. 12.28's changelog states the wrong cause: correct
  it in the next release's notes. No action proposed on the fallback.
