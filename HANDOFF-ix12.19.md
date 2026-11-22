# Handoff: after ix.12.18 (built 2026-11-08) — for the session that verifies it and builds ix.12.19

Self-contained. Read this, then the project memory (`C:\Users\trabi\.claude\projects\C--Users-trabi-Claude-Projects-Telegram\memory\`:
MEMORY.md and the files it points to). Rules and tools of `HANDOFF-ix12.17.md` all still apply (summary below).
Times: "local" is the user's EST (UTC-5); report timestamps are UTC (Z) unless marked local.

## FIRST: where things stand

| Version | Tag / commit | State (2026-11-08 ~16:00Z) |
|---|---|---|
| ix.12.16 | `v3.4.18-ix.12.16` = 83fc7d1 | ran 11-07 19:33 – 11-08 01:43 local, ended clean |
| **ix.12.17** | **`v3.4.18-ix.12.17` = 2176328**, PR #29 (draft, CI only) | **live since 11-08 01:44 local** (installed itself, 12.16 ended clean). Published with the user's OK ("go for launch of 12.17") |
| **ix.12.18** | **tag `v3.4.18-ix.12.18` = 69562a5**, branch `ix/v12.18` (worktree `repo-v12.16`), draft CI-only PR #30 | **PUBLISHED 2026-11-08 with the user's explicit OK** ("Push and publish"). Local checks all clean on 69562a5 (five packages, race on telegram/app, all 14 browser checks); CI green (runs 42488981820/-825/-866). Release workflow 42490983084 success; GitHub latest; 8 archives + SHA256SUMS. The user may install it by hand; otherwise the archive's hourly update check installs it. **Install not verified at handoff** |

## What 12.18 changes (and why)

### 1. Waits on file parts held per request (floodguard.go)
- Was (12.4–12.17): one plain FLOOD_WAIT on a file part (≈2 s, 40–64/h on DC2/DC4 on 11-07/08) closed the files gate of
  **every** server and started a 2-hour fallback in which every FLOOD_PREMIUM_WAIT also held every server. Evidence
  (challenger, hour by hour): DC1/DC5 had 0 waits of their own yet spent 418–912 part-seconds/h waiting; expected from
  the shared gate (closed ≈ asked + 1 s per wait × parts in flight) 400–750, matching 3 of 4 hours. Cost estimate
  2–4 GB per hour without the speed limit (3–7%). 06:00 had extra unexplained waiting (likely the account gate).
- Now (as TDLib `NetQueryDelayer` and Telegram Desktop `onErrorDefault`: delay the one request):
  - short plain wait: that request sleeps (asked + 1 s), pacer narrows that server's window, nothing else stops;
  - escalation per server: 3 waits ≥ 10 s within 60 s, or one ≥ 60 s → that server's own gate (`dcUntil`) for the
    time asked; a long wait is waited out, **never fails the file** (challenger showstopper 1);
  - 2 servers escalating within 60 s → every server's files gate;
  - **automatic fallback**: shared escalations twice within 1 h → 12.17's behaviour for 1 h (`classicUntil`);
  - file parts no longer wait for the **account** gate (waits on rescans etc.); classic mode restores that;
  - plain waits counted apart from speed-limit waits (`plainWaits`, cap `floodInlineRetries`).
- Setting: **Settings → Downloads → "Make every server wait when one is asked to wait"** (`classicWaits`) = 12.17 way.

### 2. Media-server routes (route.go, route_home.go, attachment.go)
- Telegram's files docs: file queries should go to a server's media address; TDLib download sessions do
  (`SessionMultiProxy` allow_media_only). We used main addresses only. -503 "Timeout" cost DC1 31–64% of its time
  in flight in two unlimited hours (20:00: 906 timeouts, 4,738 s of 7,440 s).
- Each server: media pool opened in the background after its main pool works.
  - Non-home servers: gotd `Client.MediaOnly` (auth export/import, as main DC pools already do).
  - **Home server** (the user believes **DC1**; not confirmed in any log yet): gotd can't (it would export the
    login to itself). A **second gotd client** for downloads only: in-memory copy of the session (disk never written),
    resolver `mediaFirst` (Primary dials MediaOnly), `NoUpdates`, `Pool(4)`, 1-minute start timeout. Same key, same
    IP: the main pool already uses the key on 12 connections. Challenger: low chance of harm; residual risk is a
    re-login; if login errors ever show on main, switch the setting off. The user can still log in on new devices.
- Router per server: 50/50 for the first hour (unless media is under half of main's bytes per slot-second after
  ≥ 100 parts → 15% at the first 15-min judgment), then every 15 min 85% to the route ≥ 20% better in **bytes per
  second of slot time** (failed and slept time included), else 50/50.
- Fallbacks: a media part with no Telegram answer (closed pool "DC is closed", dropped connection, part timeout)
  is asked again on main at once (never fails); login error, or 5 drops in 5 min → route off 1 h; after 3 failures
  off for the run; second client ending by itself → route off; the setting off closes open media pools.
- Setting: **Settings → Downloads → "Do not use Telegram's media servers"** (`mediaRoutesOff`).

### 3. Measurements (all counts only; checked for privacy)
- `PaceHour` (pacer_hours.go) per server/hour: `DCSeen`, `DCRoom`, `DCRoomFree`, `DCLimited`, `DCGateOther`,
  `DCClimbsJudged/Kept/Refused`, `DCPlainSleptMs`, `DCGateMs` ("<dc> <cause>"), `DCRouteParts/Timeouts/KB/Ms`
  ("<dc> main|media"), `DCRetryOK/Again` ("<dc> 1|2|3+"). `clonePaceHour` copies every map by reflection (12.18's
  first draft handed out shared maps: a crash the challenger reproduced; guarded by `TestIx1218HoursAreCopies` and
  `TestIx1218HoursReadWhileRecorded`). `TestIx1217EveryPaceHourCounterIsMerged` fails if a new map isn't merged.
- Queue-limit sampler (12.17, fixed in 12.18): idle slots only on servers with files in the queue (12.17 counted
  server 3, which has never held a file of this archive: ~420 of the 789–983 idle slot-min/h were that artifact).

## After 12.18 installs: what to read (report `latest.txt`, numbers only; never print "same bytes as" lines)

1. `[restarts]`: 0 crashes; `crashes\running` = 12.18; 12.17 ended "clean".
2. Live line **"file parts by route …"**: which server is `(home)` (confirms or refutes DC1), each server's state
   (`on (media N% of parts)`, `no media address`, `failed`, `off after failures`), "taken away after a failure N times",
   automatic fallbacks to 12.17's waits, escalations per server. **If any server shows repeated take-aways or the
   home route fails at once, read why before anything else.**
3. Per hour **"routes per server"**: per route `-503 per 1,000` and `KB per slot-second`; **the decision metric**
   is KB per slot-second in hours without the speed limit. Retries after a -503: "try 1 X of Y answered" etc. (if
   retries mostly time out again, a part is not worth re-asking soon → set-aside idea below).
4. Per hour **"held per server"**: `own server`, `all servers`, `account`, `plain waits slept alone` seconds.
   Expect `all servers` ≈ 0 and DC1/DC5 waiting far below 12.17's 418–912 part-s/h in unlimited hours.
5. Per hour **"room and tries per server"**: `room unused` and `nothing in the way` %, `speed limit` %,
   `held by another server's wait` % (should drop to ~0 with 12.18), bigger windows tried/kept.
6. **GB per unlimited hour** (hour lines with `speed limit 0`): 12.16/12.17 ran 50–72 GB/h. Compare like with like
   (unlimited hours are episodic: 3 of 24 on 11-08).
7. Plain waits per hour per server (12.17: DC4 58–64, DC2 13–47): must not rise sharply with 12.18. If they do,
   or escalations appear, the automatic fallback should show; consider the setting.
8. Login errors anywhere (recent errors: AUTH_KEY_*, SESSION_*): **if any appear on main after 12.18, switch
   "Do not use Telegram's media servers" on at once** and report to the user.
9. CPU/reads (12.17: 82–139% CPU, ~200 MB/s reads per 10 min): the second client adds a few connections, no more.

## Baseline on 12.17, last read before 12.18 (11-08 14:47Z report; compare 12.18 against these)

- Up since 01:44 local, 0 crashes. CPU 48–73% per 10 min, reads 98–135 MB/s (downloads slow under the limit).
- Speed limit on since ~07:00 local; the only unlimited hour since 12.17 installed was **06:00 local: 53.5 GB,
  1,849 files**. 24 h: 493 GB / 16,471 files; speed-limited hours 21 of 24 (10.9 GB/h average in them).
- Per server, seconds summed over parts (in flight / answered / failed (requests) / waits):

| Hour (local) | Limit waits | Plain waits | DC1 | DC5 |
|---|---|---|---|---|
| 20:00 (no limit, 56 GB) | 0 | DC2 45, DC4 40 | 7440 / 2197 / 4790 (920) / 446 | 13220 / 8992 / 3413 (626) / 794 |
| 06:00 (no limit, 53.5 GB) | 6 | DC2 13, DC4 62 | 6890 / 3989 / 2210 (412) / 723 | 7380 / 4043 / 2442 (470) / 912 |
| 01:00 (limit, 1.4 GB) | 1949 | – | 6620 / 43 / 1783 (775) / 4790 | 13230 / 157 / 1735 (1076) / 11246 |
| 08:00 (limit, 1.9 GB) | 1649 | – | 7200 / 107 / 1344 (726) / 5761 | 7200 / 1210 / 203 (446) / 5786 |

  **New observation:** DC1 and DC5 fail heavily (mostly -503s) **in speed-limited hours too** (01:00: DC1 1,783 s /
  775 failed requests; DC5 1,735 s / 1,076), not only in unlimited ones. The media-route comparison should therefore
  show on DC1/DC5 within hours even under the limit (per-route -503 per 1,000), well before an unlimited hour.
- Staging: 185.9 GB / 7,592 files waiting (falling from 318 GB), 22.9 GB/h at 2.9 MB/s per copy, 3 at once, oldest
  waiting 14h15m, ~638 GB room.
- Queue-limit sampler (12.17 version, server 3 still counted): idle 831 slot-min at 09:00 (speed limit on all hour).
  Ranked group's files pass waiting for its lane while unranked files downloaded: 44–56 min/h at 05:00–09:00 (up to
  16,555–20,060 files found missing): check the lane holder's rank in 12.19 (item 7 below).

## Findings this session (11-08), for reference

- **Server 3**: no file of this archive has ever been on DC3 (tgdl_work.dc: 0 old/unknown 78,591; DC1 37,279;
  DC2 7,802; DC4 19,182; DC5 5,916). Files live on the server they were uploaded to; nothing to fetch there.
- **Server-aware queue ordering**: in the one unlimited hour (06:00, 53.5 GB) every server had parts waiting
  (DC1 15.8, DC2 4.7, DC4 22.9, DC5 11.2); windows full 99%. No server ran short → ordering by server would not
  have helped then. The server of every archived file is known without requests (ix_messages.tl, all 206,465 media
  messages, ~385 bytes each). Per-group "files by server" on Priorities was offered; the user did not answer yet.
- **Queue limit (500)**: "nothing to start" 0 minutes all night; parts allowed in use 99% in the unlimited hour →
  raising the cap would not have added speed (one night; keep reading the sampler).
- **paceByAnswers**: keep OFF (challenger + me). It would have kept 4 extra one-part climbs of 11 tries in the 4
  hours with tries; 0 smaller tries ever; blind to -503s (a timed-out extra part looks like a gain); more parts can
  bring more plain waits. Reconsider only if per-server counts show answer-time-only climbs on servers with few -503s.
- **-503 timeouts**: episodic (DC1 0 at 19:00, 906 at 20:00), look server-side. Our retry matches the official
  apps (same server, growing pause; ours 1→16 s, 20 tries; tdesktop 1→64 s, no limit; TDLib 1→64 s). tdesktop drops a
  download session after 4 slow/timed-out requests (8 s+); parts 128 KB × 4–16 per session, 1–8 sessions per server.
  TDLib: ≤ 512 KB parts, 2 download sessions per server without Premium. Ours: 1 MiB parts, 2–8 per server.
- **CDN**: both official apps support it; not worth building before 11-30 (decryption, hashes, re-uploads).
- **Topic ranks**: work as designed, moved 0 files on 11-08 (5 topics: saved 1,652, held 745, waiting 0, not
  queued 590, of which 585 / 36.3 GB in two groups never rescanned: 554 and 1,553 archived messages, enabled false,
  photos/videos/files on; ~44 requests to rescan both). The user decided against automatic lane [name removed] or rescan adds
  (memory topic-rank-no-requests). 12.17 shows the cost on the "Add its group to the rescan" button.
- **Staging**: backlog 318 GB (11-08 03:16Z) → 227 GB / 9,236 files (12:52Z); copier 18–25 GB/h at 2.1–2.7 MB/s per
  copy, 3 at once; oldest waiting 12h52m; ~600 GB room. 12.17 has "Copy N files at once" (1–8): the user may try 4–5;
  compare MB/s per copy an hour later.
- **CPU**: 12.15 205–250%, 12.16 114–150%, 12.17 82–139% (reads 514–716 → ~390 → ~200 MB/s).
- **Rescan lane**: a ranked group's files pass waited for its lane while unranked files downloaded 10–56 min/h
  (12.17 sampler, ~20,060 files found missing). Not yet checked whether the lane holder outranks it (then it is by
  design).

## Suggested tests / experiments for 12.19 (each with its measurement; build only on evidence)

1. **Media verdict** (12.18 data, ≥ 3 unlimited hours): per server KB per slot-second media vs main, -503 per
   1,000. If media is clearly better on DC1/DC5, consider defaulting the router to media and fewer exploration
   parts; if no difference, leave the router (it costs ≈ nothing).
2. **Set a part/file aside after N -503 in a row** — only if `retries after a -503` shows retries mostly timing out
   again AND -503s cluster on few files (add: distinct files with -503s, longest run per file).
3. **More parts on DC1 in unlimited hours** — only if `room and tries` shows DC1 `nothing in the way` room and
   climbs refused that answer time would have kept, with few -503s.
4. **Account gate**: confirm `account` gate seconds ≈ 0 for file parts now; if rescans' waits ever show on
   downloads again, investigate.
5. **Per-group files by server on Priorities** (if the user says yes; data from ix_messages.tl, no requests), and
   server-aware ordering only if some server shows `room unused (nothing in the way)` high in unlimited hours.
6. **Queue-limit sampler**: idle slots on servers with queued files while a pass waits for room, in unlimited hours;
   raise the cap only if that is substantial and "nothing to start" > 0.
7. **Ranked group waiting for its lane**: add the lane holder's rank vs the waiting group's to the sampler line.
8. **Staging copies**: after the user changes "copies at once", compare MB/s per copy and GB/h.
9. **Automatic backup before every update** (user asked, 11-08): while the app drains for an install, a
   consistent DB snapshot (SQLite backup API or `VACUUM INTO`, ~1.46 GB) plus `data\sessions\` and
   `data\secret.key` into `data\backups\pre-update-<version>\`, keep the last 3; no Telegram requests. Today:
   the nightly backup (ix_backup.go) copies DB + sessions to "<index folder> backups" on the NAS (4 kept) but by
   design not secret.key; `ix-update.ps1` keeps only `tgdl-server.exe.previous`.
10. **Version pin for rollbacks**: `ix-update.ps1` only moves forward, so swapping `tgdl-server.exe.previous` back
   is undone at the next launcher start. Add a pin (e.g. a file `data\ix-update.pin` naming the version to stay
   on, honoured by the script and the in-app update check). 12.18 has no DB schema change vs 12.17, so an exe swap
   back to 12.17 is safe; the Settings switches undo 12.18's new behaviour without any swap.
11. Nits left from reviews: topic counts treat every ix_subst row as saved; per-topic `Files` query uncached;
   GroupToQueue ignores the group's filters; `MediaRange` (ix_parts.go) retries -503 at once with no pause;
   `climbsKept` counts climbs later taken back by the 5-min check; hour of install has partial room shares.

## Rules (unchanged, abbreviated)
- Live install `E:\T\tg-dl`: read only; DB only `file:E:/T/tg-dl/data/db.sqlite?mode=ro`; print counts only.
- Never open the real media viewer or live dashboard pages; UI work with invented data (`ix-tools/ui.sh`).
- Publishing installs on the user's archive: tag/publish only with the user's explicit OK **for that version**.
  Pushing a branch for CI also needs the user's OK. Draft PRs only, never merge, never push `main`.
- No speed claim without measurement; one night's data is "looks like". Probable copies are held, never skipped;
  held copies never go before unique files. No new Telegram requests without measuring them; prefer removing
  work over adding delays.
- Every new ixLog: constant format string. Report lines: numbers only.
- Commit: `git -c user.name=Claude -c user.email=noreply@anthropic.com commit …` + `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

## Tools
- `ix-tools/env.sh` (Go), `ix-tools/race.sh WORKTREE PKGS [-- flags]` (Docker -race), `ix-tools/ui.sh WORKTREE
  [tests]` (Playwright, venv `ix-tools/pwvenv`, browsers `ix-tools/pw-browsers`), `ix-tools/gh_pr.py`,
  `ci_wait.py SHA BRANCH`, `ci_log.py RUN "JOB" OUT` (PYTHONUTF8=1), `gh_release.py wait|show` (IX_VER=…).
- Release flow used for 12.17: push branch → `gh_pr.py open BODY.md` → `ci_wait.py` → (green) `git tag
  v3.4.18-ix.<ver> <sha>` + `git push origin <tag>` → `gh_release.py wait` / `show`.
- Challenger reviews (independent agent, read-only) caught: a crash (shared maps), a media failure storm (closed
  pool), and two design showstoppers. Use one for every download-path change.
