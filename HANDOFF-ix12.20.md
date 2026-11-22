# Handoff: after ix.12.19 (published 2026-11-08), for the session that verifies it and builds ix.12.20

**A new account or session: read `START-HERE.md` first.** It holds every standing rule (privacy above all), the tools,
the code map, the build, test and release flow, and how to read the live report. This file is the current state. The project
memory (`C:\Users\trabi\.claude\projects\C--Users-trabi-Claude-Projects-Telegram\memory\`), if present, repeats it in short.
Times: "local" is EST (UTC-5).

## Where things stand
| Version | Tag / commit | State |
|---|---|---|
| ix.12.18 | `v3.4.18-ix.12.18` = 69562a5 | live since 11-08 10:59 local, 0 crashes |
| **ix.12.19** | **`v3.4.18-ix.12.19` = cea1925**, branch `ix/v12.19` (worktree `repo-v12.16`), draft CI-only PR #31 | **PUBLISHED 11-08 with the user's OK**; CI and the release workflow both green; GitHub latest. **Install not verified** (the hourly update check installs it). |

## Facts found on 12.18 (11-08)
- The home server is **DC1** (confirmed).
- Telegram's config gives **no media address for DC1 or DC5**, so media routes run only on DC2/DC4. There they match the
  main route (no -503s on either, 78–105 KB per slot-second under the speed limit). The second login client never starts.
- Retries after a -503 almost never got data under the speed limit: DC1 0 of 84, DC5 2 of 196 in the 11:00 hour.
- 12.18's "held by another server's wait" (31–38%) was a counting error. It was the server's own speed limit, and 12.19
  fixes the count.

## What 12.19 changed
- **-503 set-aside** (`telegram/timeout_aside.go`):
  - **When:** 3 -503s in a row on one part, while 2 other files of the same server were answered after the run began.
  - **What:** the file goes back to the queue for 20, then 40, then 80 min, with its attempt refunded (engine/controller.go, like FLOOD_WAIT).
  - **Limits:** after 3 set-asides the file gets its 20 retries again; at most 20 per server in 10 min; none within 2 min of a speed-limit wait; downloads only (`downloadPathKey`).
  - **Setting:** `timeoutAsideOff`.
- **2-part floor:** a plain wait under 10 s doesn't cut a server below 2 parts. It still does with classic waits or during the
  automatic fallback (`classicFallbackUntil`). A window cut to 1 comes back 10 min after the cut below the floor (`lowCut`).
- **Report:**
  - "held by another server's wait" fixed: each wait now reports its cause through `partHooks.held`;
  - the routes line now shows "files with a -503 N (also answered M), files answered K; -503 runs ended: answered /
    set aside / gave up / …; run lengths 1 / 2 / 3-5 / 6-19 / 20+".
- **Copy before every update** into `data\backups\pre-update-<ver>_<time>` (DB snapshot, sessions, `secret.key`; last 3 kept;
  skipped if under 20 GB would stay free). It adds about 1–2 min to each update.
- **Version pin** `data\ix-update.pin`: ix-update.ps1 installs the pinned version and doesn't replace itself while pinned;
  the app offers no update and the update line says "pinned to …".
- **UI:**
  - relations in both directions in the media browser (exact means the same bytes only);
  - a whole-album view across groups;
  - one Groups tab replacing Priorities, Rescan and Choose groups.

## After 12.19 installs: what to read (latest.txt, numbers only)
1. `[restarts]`: no crash; 12.18 ended clean; `crashes\running` = 12.19. A `data\backups\pre-update-3.4.18-ix.12.18_*`
   folder exists (its log line: "copy before the update made in …").
2. Routes line per hour:
   - set-aside runs vs gave-up runs;
   - run lengths;
   - files with a -503 vs files answered.
   The set-aside pays if most -503s are in runs of 3+ while the server answers other files. In unlimited hours, compare DC1/DC5's
   -503 seconds of slot time and GB/h with 12.17's (DC1 4,738 of 7,440 s at 20:00 and 2,171 of 6,890 s at 06:00).
3. **2-part floor risk:** in the first unlimited hour, read DC2/DC4's plain waits per hour, the average asked and the escalations. If DC4's
   average asked reaches about 5 s, or any escalation or automatic fallback shows, report it. The floor is in code, with no setting
   of its own; "Make every server wait when one is asked to wait" brings 12.17's cuts back.
4. Room and tries: "held by another server's wait" should now be about 0%, and "speed limit" correspondingly higher.
5. Login errors: none expected (the media second client never starts with DC1 having no media address).

## Last read on 12.18 before 12.19 installed (11-08 20:35Z report; compare 12.19 against these)
- **Install timing.** 12.19 was published at 15:16 local (20:16Z). At 15:37 local 12.18 was still running and its update line
  said "latest release 3.4.18-ix.12.18": it asks GitHub once an hour. Expected: noticed by about 16:15 local, then a drain
  of up to 20 min (large files stop at their next checkpoint), the pre-update copy, the exit, and the launcher installing it,
  so running by about 16:40 local. A session check was scheduled for 16:47 local. "Check for updates" in the app forces an
  immediate check; it is the user's to press (never open the live dashboard).
- **Speed limit on all day** since about 07:00 local: 1.2–2.5 GB per hour (11:00 1,954 MB, 12:00 2,495, 13:00 1,207, 14:00 1,810;
  15:00 2,101 MB in its first 35 min). Last unlimited hour: 06:00 (53.5 GB, 1,849 files). Last 24 h: 408 GB / 15,114 files,
  21 of 24 hours speed-limited at 6.8 GB/h on average (per server: DC1 2,621, DC2 1,079, DC4 1,784, DC5 1,336 MB/h).
- **Health.** 0 crashes, 0 login errors, 0 escalations, 0 automatic fallbacks to 12.17's waits, 0 plain waits in 12.18 hours.
  CPU 64–80% of one core per 10 min, reads 100–140 MB/s, 449 GB/h read, 29 GB/h written. Ready 3,363, downloading 19,
  retry later 1, set aside 28,089 (copies 21,269). Rescan: 45 done, 84 left (46 not read) of 129 groups.
- **Staging catching up.** The setting is now **6 copies at once** (the user raised it from 3). 45.6 GB / 959 files waiting,
  down from 160.5 GB / 6,428 at 11:00 local and 318 GB at 03:16Z. Last hour: 1,046 files / 26.4 GB copied at 1.9 MB/s per
  copy (14,258 s of copying, about 4 at once on average). Per copy is about the same as at 3 at once (2.1 MB/s), so more
  copies scaled almost linearly. Oldest waiting 8h54m.
- **-503 retries almost never answer, even under the speed limit.** Retries after a -503, mostly on DC5: 12:00 0 of 154 at
  try 3+, 13:00 1 of 27, 14:00 0 of 72, 15:00 0 of 70. DC5 -503 per 1,000 parts: 282 (12:00), 45 (13:00), 119 (14:00),
  189 (15:00). DC1: 33, 0, 0, 14.
- **DC5 loses bytes to them under the limit too.** DC5 vs the other servers per hour: 12:00 443 vs ~600 MB (181 -503s,
  954 s), 11:00 412 vs ~595 (208 -503s), 14:00 555 vs ~620 (76), 15:00 297 vs ~370 so far (74); 13:00, with only 29
  -503s, 597 vs ~609. That looks like 100–200 MB/h, about 2–3% of the speed-limited rate (one day; looks like, not proven).
  **12.19's set-aside does not act on it**: setAside refuses within 2 min of a speed-limit wait on the server
  (`asideLimitedWithin`, timeout_aside.go). The challenger's reason was "slot time is not what limits a server under the
  speed limit"; these numbers suggest it does a little on DC5. Candidate for 12.20: relax that guard (e.g. only when the
  server's other files are also being answered, as the 2-file rule already requires). Decide from 12.19's run counts.
- **Media route under the limit: no difference.** DC2/DC4 media 82–92 KB per slot-second vs main 81–92, 0 -503s on either.
  The router moved DC2 to 85% media at a 15-min judgement on that noise; harmless. The verdict needs unlimited hours.
- **Index errors, not yet looked into.** Video index: 89× ffmpeg "Invalid data found when processing input", 3× "Conversion
  failed", 2× killed (signal 15), 1× file not found, others single. Image recognition: 104× and faces/text: 88× "no frame could
  be read from the video". Picture index: 3× invalid JPEG. It could be damaged downloads or unusual formats; not compared with
  earlier days. Worth a code-only look (which files are counted, whether a fixity or hash check flags the same ones), with no
  file opened.

## First whole 12.19 hours, without the speed limit (11-08 23:49Z report, local hours)
| Hour | GB | Files | Plain waits | DC1 / DC2 / DC4 / DC5 GB | -503s (s): DC1 / DC5 |
|---|---|---|---|---|---|
| 17:00 | **103.0** | 2,004 | 0 | 43.7 / 8.3 / 30.3 / 21.3 | 12 (61) / 12 (63) |
| 18:00 (to 18:49) | 77.2 | 745 | 7 (DC1 4, DC4 3) | 36.4 / 4.2 / 25.3 / 13.0 | 161 (914) / 226 (1,212) |

- **17:00 is the best hour on record** (12.16/12.17: 50–72.6 GB). But it had 0 plain waits and almost no -503s, so Telegram's
  side was clean: the gain cannot be split between 12.19 and a good hour. Compare more hours, like with like.
- **Fix confirmed:** "held by another server's wait" is 0% on every server in both hours, and "speed limit" is 0%.
- **2-part floor, no harm so far:** DC4 sat at 2.0 parts all hour (12.17: about 1.1) with 0 and 3 plain waits; DC2/DC4 at the
  floor 98–100%, below it 0%. No escalations, no automatic fallbacks.
- **DC2 runs out of files (new lead, the strongest for 12.20):** room unused 76% (17:00) and 85% (18:00), all of it
  "nothing in the way"; 1.2–1.3 parts in flight of 2.0 allowed, 1.7–2.4 parts waiting. DC2 delivered 4.4–4.7 MB per
  slot-second when busy, so a full DC2 looks like roughly +8–15 GB/h (looks like). DC5 also has 13–19% room unused. This
  meets the condition set in HANDOFF-ix12.19 item 5 ("server-aware ordering only if some server shows room unused, nothing
  in the way, high in unlimited hours"). Next: count the queue's files by server (ix_messages.tl / tgdl_work.dc, no requests)
  and see whether DC2 files exist further back in the queue or not at all. If they exist, let claims reach past the ranked
  order for a server with idle slots (a server-aware claim, like 12.4's "claims skip servers whose slots are full", the other
  way round). If no DC2 files are queued, nothing can fill it.
- **The set-aside rule looks too strict for servers with few files at once:**
  - At 18:00 DC1 had 4 runs of 20+ -503s and DC5 4 runs of 20+ plus 4 of 6–19, but only 2 set-asides (DC5) and 0 on DC1.
  - DC5 holds about 2 large files at once (large 1.7–1.9 of 2) and DC1's -503s fell on 3 files. setAside needs **both**
    lastAnswers entries to be other files answered after the run began. When a server has only one other file going, or the
    timed-out file's own other parts answered recently, the second entry is often the same file, so the rule refuses.
  - Candidate 12.20 change: count distinct other files answered since the run began, needing 1 instead of 2 when the
    server holds fewer than 3 files. Or ignore this file's own entries. Keep the storm caps (20 per server per 10 min, 3 per
    file) and get a challenger review.
  - Runs that ended: 17:00 set aside 3 (DC1 2, DC5 1); 18:00 set aside 2, gave up 2, cancelled 13. Find out what cancels them
    (a stop at a checkpoint, a yield, or the file failing on another part).
- **-503 retries:** first retries are often answered (DC1 45 of 51 at 18:00; DC2/DC4 all), but retries 2 and 3+ almost
  never (DC1 0 of 103; DC5 0 of 149). That supports 3 as the threshold, perhaps 2.
- **Media vs main without the limit:** media slightly better and never worse. DC2 4,478 vs 4,360 and 4,666 vs 4,510 KB per
  slot-second (+3%); DC4 4,591 vs 4,217 and 4,639 vs 4,355 (+7–9%); 0 -503s on both routes. That is below the router's 20%
  threshold, so it stays 50/50. Possible 12.20 change: lower the threshold (e.g. 5% over 2 judgements) so DC4 goes mostly to media. Gain
  is small (a few % of DC4's 25–30 GB/h).
- **Climbs:** DC5 ran at 3.2–3.7 parts (tries 10 an hour, kept 2–4; answer time would have kept 1–3 more). DC1 climbed to 2.5 at
  18:00 (3 tried, 3 kept). DC1 is the biggest server (36–44 GB/h at 2.0–2.5 parts) and has 0–1% room unused: more DC1
  parts is lever 2 from the 12.19 review; watch DC1 climbs judged / kept / refused.
- **Staging is falling behind again:** 223.3 GB / 3,014 files waiting at 18:49 (45.6 GB at 15:36), against downloads of
  77–103 GB/h and a copier at 22.8 GB/h. The copier runs 313 files an hour at 1.9 MB/s per copy, but only about 3.3 copies at
  once on average (11,885 s of copying in an hour) although the setting is 6. Find out why 6 copies don't run (fingerprinting
  before the copy? waits for a file still in use?). Room left about 596 GB, so at +55–80 GB/h it fills in about 8–10 h. Check
  that full staging still sends new downloads straight to the library (12.6 behaviour) and that the copier does not slow
  downloads.
- **Load:** CPU 110–148% per 10 min, reads 176–220 MB/s, written 128 GB/h. Higher than under the limit, as expected.
- **Health:** 0 crashes, 0 login errors, no account refusals. File-reference refreshes 3–84 per server-hour (normal).

## Later on 11-08 (report 20:16 local; 12.19 up 4h0m, still no speed limit since about 16:00)
| Hour | GB | Files | Plain waits | DC1 / DC2 / DC4 / DC5 GB | -503s (s): DC1 / DC4 / DC5 |
|---|---|---|---|---|---|
| 18:00 (whole) | 87.0 | 844 | 12 (DC1 4, DC2 5, DC4 3) | 40.4 / 5.0 / 29.6 / 13.6 | 260 (1,533) / 1 / 267 (1,434) |
| 19:00 | 74.3 | 2,461 | 27 (DC2 25, DC1 2) | 40.5 / 6.8 / 23.2 / 3.6 | 232 (1,337) / 253 (1,350) / 143 (755) |
| 20:00 (to 20:16) | 16.4 | 226 | 0 | – | – |

- **Totals:** last 24 h 516 GB / 13,242 files (408 GB at 15:36 local). 0 crashes, 0 login errors, no account refusals,
  no escalations, no automatic fallbacks.
- **DC5 now runs out of files too:** at 19:00 its room was unused 80%, with 1.5 parts in flight of 2.8 and 1.0 waiting; it
  brought 3.6 GB. DC2 was again 78–80% unused (1.0–1.4 in flight of 2.0). DC1 and DC4 stay full (0–4% unused, 15–20 parts
  waiting). **Two of four servers idle for lack of queued files: the server-aware claim (idea 1) is the strongest lead.**
  First check, with no requests: how many queued and not-yet-queued files each server has, and where they sit in the order.
- **-503 storms moved:** DC4 had its first real one at 19:00 (253 -503s, 1,350 s; 2 set-asides there) while DC5's eased.
  DC1 keeps 230–260 an hour. The 12.20 report should show which files and servers they hit.
- **The set-aside fires, but late:**
  - The report's error list shows "server 5 timed out on this file 13 times in a row … tried again in 40m0s", plus 7× and 4×
    on DC5 and 3× and 5× on DC4.
  - The repeat waits are working: 40 min on a second set-aside, 1h20m on a third.
  - So the "2 other files answered after the run began" condition is often met only after many -503s (see idea 2). At 19:00,
    DC5 had 4 set-asides; 18:00 still had 8 runs of 20+ (DC1 4, DC5 4).
- **"Cancelled" runs are mostly side effects:** when one part of a file is set aside or gives up, the whole attempt is
  cancelled, so the other parts' -503 runs end as "cancelled" (DC5 12 at 18:00 and 19:00). Count the cancelled ones with the
  run that ended the file, not as separate failures.
- **New: part requests with no answer in time** (the 2-minute part timeout) at 18:00 on every server: DC1 3 (360 s), DC2 2,
  DC4 2, DC5 1 (120 s each), plus "other" 2 on DC1 and DC4 (50 s). They came at once on all servers, so it looks like a
  short network or VPN hiccup, not Telegram. None at 19:00. Watch whether it repeats.
- **DC2's plain waits:** 25 at 19:00, with 6 cuts, but it stayed at the 2-part floor 100% and never below; there was no
  escalation. That is within 12.17's 13–47 for DC2. Read the average asked when the 12.20 report shows it per server.
- **The media route is slightly ahead now** in unlimited hours: DC2 3,777 vs 3,381 KB per slot-second (18:00, +12%) and
  4,375 vs 4,080 (19:00, +7%); DC4 4,608 vs 4,054 (18:00, +14%). At 19:00 the router put DC4 at 74% media. In that hour's
  -503 storm, media had 12 per 1,000 against main's 5, and KB per slot-second 3,363 vs 3,196. Still small; no harm seen.
- **DC1** ran at 2.4–2.6 parts (3 of 3 climbs kept at 18:00) for 40 GB an hour both hours, with 1,279 files at 19:00
  (many small ones).
- **Staging:**
  - 285.0 GB / 5,385 files waiting (223 GB at 18:49), oldest 3h10m.
  - The copier is improving: 30.8 GB/h (247 files) at 1.9 MB/s per copy, about 4.4 copies at once (15,808 s in an hour),
    against 22.8 GB/h and 3.3 at once an hour before. It still falls behind 74–87 GB/h of downloads.
  - About 531 GB of room left, so at +45–55 GB/h net it fills in about 10 h if the limit stays off.
- **Load:** CPU 90–161% per 10 min, reads 158–281 MB/s, written 112–125 GB/h.

## Later still on 11-08 (21:10 report and read-only DB counts at 21:16–21:18 local; 12.19 up 4h54m)
- **The speed limit came back at about 20:30 local.**
  - The 20:00 hour brought 56.0 GB / 1,289 files, with 459 speed-limit waits (DC1 28.0, DC2 8.4, DC4 18.0, DC5 4.6 GB);
    21:00 had 55 MB in its first 10 min, with 314 speed-limit waits in 10 min.
  - The unlimited stretch, about 16:00–20:30 local, brought roughly 390 GB: 70.2 + 103.0 + 87.0 + 74.3 + part of 56.0.
  - Last 24 h: 499 GB / 11,509 files.
- **NAS outage, about 20:33–21:15 local (new):**
  - The staging line said "388 failing, since 36m0s ago". Every failing copy had one and the same error: the library folder
    gave Windows' "The network path was not found" (checked by phrase only; no path printed).
  - At 21:16: 287 failing (8.4 GB, 1–3 tries each), all from one staging folder, first failing 42–43 min before.
  - By 21:17:52, 242 failing, and the waiting total fell by 45 in 75 s. The copies are going through again: the share is back.
  - Nothing is lost. A network error is not a "needs a person" problem in `download/staging.go`: the copy keeps its local
    file and retries with a pause from 5 s, doubling to at most 10 min, for ever (`stageBackoff`). Only a damaged, missing or
    unreadable staged file becomes "stuck".
  - Downloads were not stopped: they go to the local staging disk.
  - **Likely the same local network trouble as the part timeouts:** "no answer in time" (2-min part timeouts) hit every
    server at once at 18:00 (DC1 3, DC2 2, DC4 2, DC5 1) and again at 20:00 (DC1 2, DC4 2, DC5 4), just before the NAS went
    away. Telegram (over the VPN) and the NAS (on the LAN) failing together points at this PC's network, not at Telegram.
    The user may want to check the PC's network or NAS at those times. Ask; never change network or VPN settings.
  - Ideas for 12.20, cheap and with no requests:
    - a report line naming the outage, e.g. "library unreachable since …, N copies waiting for it";
    - a single probe of the share before trying hundreds of copies each round (each failing copy retries on its own);
    - if the NAS is away for long, staging fills: 528 GB free at 21:10. When full, new downloads go straight to the
      library, which is the NAS. Check what happens to downloads then (they might fail while the NAS is away).
- **Staging after the outage:** 303.4 GB / 6,084 files waiting at 21:10 (oldest 3h54m). The last hour copied 358 files / 25.9 GB
  at 2.1 MB/s per copy, about 3.5 at once, despite the outage. Room about 514 GB.
- **Set-asides keep firing:** 20:00 had DC1 2, DC4 6 and DC5 1, against gave up DC4 1 and DC5 1. Under the returning speed
  limit, the guard (no set-aside within 2 min of a speed-limit wait) will stop them; check the 21:00+ hours.
- **Routes:** the live line now says DC2 media 85%, DC4 media 15%: the router moved DC4 back to main after the 19:00 -503 storm
  (media 12 vs main 5 -503s per 1,000 then). At 20:00: DC2 media 2,691 vs main 2,277 KB per slot-second, DC4 main 2,543 vs
  media 2,470. Under the limit these differences mean little.
- **DC2/DC5 idle again:** at 20:00 DC2 had 53% of its room unused and DC5 43%, while DC1 had 4% and DC4 0%.
- **24 h errors** now read "other 13, timeout 3" (other 7 at 20:16). They look tied to the network trouble above; the
  report's error list is the place to check their kinds.
- Health: 0 crashes, 0 login errors, no escalations, no automatic fallbacks. CPU 70–188% per 10 min; reads 116–205 MB/s;
  written 79 GB/h.

## What to watch for after 12.19 installs (all of it)
1. **Install.** `crashes\running` = 3.4.18-ix.12.19; history.jsonl: 12.18 ended "clean"; [restarts] 0 crashes. If it has not
   installed, read why from the update line (latest release seen, waiting for downloads, the auto note: an automatic drain
   gives up after 20 min and tries again an hour later).
2. **Pre-update copy.** The exiting version makes it, so the 12.18 → 12.19 update made none (checked 11-08 16:47 local:
   no `pre-update-*` folder, as expected). The first will be `data\backups\pre-update-3.4.18-ix.12.19_<time>\` at the
   12.19 → 12.20 update: db.sqlite, sessions\, secret.key, manifest.json; log line "copy before the update made in …"
   (or "not made: …" and why). Restart gap without the copy: 43 s (12.18 ended 16:15:02, 12.19 started 16:15:45);
   expect 1–2 min more with it.

**12.19 installed 11-08 16:15:45 local** (12.18 ended clean 16:15:02; 0 crashes in 7 days, 15 clean stops). The speed limit
lifted around 16:00 local: the 16:00 hour (12.18 until 16:15, then 12.19) had 70,248 MB in 868 files by 16:41, and
"Telegram waits in 10 min: 0 speed limit". It is a mixed hour, so compare whole 12.19 hours. First signs:
- set-aside fired: DC1 4 runs, DC5 2;
- DC2 -503s (182) were all answered on the first retry;
- DC2 room unused 60% (nothing in the way 58%): DC2 ran short of files, the first evidence for server-aware ordering
  (handoff 12.19 item 5);
- DC4 sat at 2.0 parts with 6 plain waits;
- DC5 3.2 parts allowed, 4 of 10 climbs kept;
- "held by another server's wait" 2–5%, part of it from the 12.18 minutes;
- 0 login errors.
3. **Set-aside.** Routes line per hour: runs "set aside" vs "gave up" vs "answered"; run lengths; "files with a -503 N (also
   answered M), files answered K". Expect few or none in speed-limited hours (the guard above). In unlimited hours: DC1/DC5
   -503 seconds of slot time and GB/h against 12.17's (DC1 4,738 of 7,440 s at 20:00 and 2,171 of 6,890 s at 06:00; DC5
   3,381 of 13,220 and 2,431 of 7,380). It pays if most -503s are in runs of 3+ while other files of the server answer.
   Watch for: a file coming back many times (cap 3 per run of the app), message-refresh load (each set-aside costs one
   refresh when the file returns), and "retry later" rising sharply in the download state line.
4. **2-part floor (the main risk).** In the first unlimited hour: DC2/DC4 plain waits per hour (12.17: DC4 58–76, DC2
   13–47), the average asked (12.17 about 1.5–2 s), escalations and automatic fallbacks. If DC4's average asked reaches about
   5 s, or any escalation or fallback appears, report it to the user; "Make every server wait when one is asked to wait"
   brings 12.17's cuts back. Also: DC2/DC4 parts allowed should sit at 2 (12.17: about 1.1), and their GB/h should rise.
5. **Room and tries.** "held by another server's wait" should be about 0% (12.18: 31–38%) and "speed limit" higher by the same
   amount.
6. **GB per unlimited hour** against 12.16/12.17's 50–72 GB/h (like with like; unlimited hours are episodic).
7. **Login errors** (AUTH_KEY_*, SESSION_*): none expected. DC1 has no media address, so the second login client never
   starts. If any appear on main, switch "Do not use Telegram's media servers" on and tell the user.
8. **CPU/reads.** Against 12.18's 64–80% CPU and 100–140 MB/s reads under the limit. The new Groups tab polls status and
   priorities every 10 s while it is open (priorities about 0.25 s of uncached reads, plus a 0.74–1.0 s coverage base cached for
   30 s). Watch whether reads rise while the user keeps it open.
9. **Staging.** Waiting GB and MB/s per copy at 6 at once (above). If per copy drops well below 1.9 MB/s, the NAS is
   saturated and fewer copies would do as well.
10. **DC5 under the limit.** Its MB/h against the other servers per hour, with its -503 count: the evidence for relaxing
    the set-aside's speed-limit guard.
11. **UI (user feedback, not report).** Does the user find the Groups tab, cross-references and album view right? Never open the
    live pages to check: ask, and reproduce anything with invented data (`ix-tools/ui.sh`).

## Ideas left (build only on evidence)
Ranked by the 11-08 evening evidence (each in the section above):
1. **Fill DC2's and DC5's idle slots** (DC2 76–85% room unused in every unlimited hour, DC5 80% at 19:00): count queued
   and not-yet-queued files by server first, then a server-aware claim.
2. **Make the set-aside fire on servers with few files** (8 runs of 20+ -503s at 18:00, 2 set-asides).
3. **Staging copier**: why about 3.3–4.4 copies run when 6 are allowed; the backlog grew 45 → 303 GB in 6 h. Also handle
   the library share being away: say so in the report, probe the share once instead of failing hundreds of copies, and
   check what downloads do if staging fills while the NAS is unreachable (see the 20:33–21:15 outage).
4. **More DC1 parts in unlimited hours** (its 36–44 GB/h is the largest share).
5. **Media router threshold** for DC4's +7–9%.
- **Relax the set-aside's speed-limit guard** for DC5-style -503 storms under the limit (see above).
- **Index errors**: a code-only look at the 89 unreadable videos (see above).
- More parts on DC1/DC5 in unlimited hours (challenger lever 2, maybe +13–21 GB/h). Check climbs judged / kept / refused
  in the first 12.18/12.19 unlimited hour first.
- From the UI review, not done:
  - typing a rank directly;
  - the album view's caps (60 files, 40 places);
  - filter-chip counts that ignore search;
  - the Overview's per-group table now only points to Groups.
- Known flaky test under load: `TestHistoryCapIgnoresItemsWaitingApart` (passed 40/40 alone).
