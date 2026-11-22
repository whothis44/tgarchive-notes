# Handoff: ix.12.20 live, for the session that builds ix.12.21

**A new account or session: read `START-HERE.md` first**, then this file, then `PRE-PUSH-CHECKLIST.md` before any push.
`HANDOFF-ix12.20.md` holds the 11-08 evidence most of 12.20 was built on. Times: "local" is EST (UTC-5).
Written 2026-11-09 ~09:30 local after three independent challenger reviews: the live 12.20 numbers ("not worse"), this plan, and a
second look at fix 1 alone. Numbers marked "challenger" are its own read-only measurements.

**The user's instruction (11-09): every item in "12.21: essential items" is essential, including the ones that were "smaller".
Build all of them.** Push, tag and publish only with the user's explicit OK for 12.21.

**Published (11-09 ~15:00 local):** tag `v3.4.18-ix.12.21` = 99b22d4, draft CI-only PR #33 (CI, Archive features, Docker green),
release with 8 archives + SHA256SUMS, "latest". Not yet verified installed: check `data\crashes\running`, `history.jsonl` (12.20
ended "clean") and the report's update line; then DC5's MB and -503s under the limit, "capped at 2 parts" minutes, and "set aside
under the speed limit" counts. 12.20 (the exiting version) still drains by its own rule, whatever the limit.

**Build status (11-09 ~13:00 local):** 12.21 built on branch `ix/v12.21` in `repo-v12.16` (commits after 483bd73; version and
CHANGELOG done). The user said (11-09): challenger review at the end before the release build; "once satisfied, building and pushing
and publishing are authorized" (12.21 only). Items 1-15, 17 and 18 are built with tests. Item 16: the export side is built
(`data/already_archived.jsonl`: identity, SHA-256, size; no paths/names); the **import side in a new install is not built yet**: it is
needed only when a second account starts (after 11-30) and needs no Telegram, so it goes in a later version. Item 9: the stuck oldest
staged file went by itself after ~12 h (oldest 12h19m at 09:00, 5.8 h at 09:19); 12.21 adds its put-off reason and count to the
report, not a forced move. Item 13: migrated basic groups are listed first in "Not added yet" with Count media as the measurement;
adding their old history is left for the user's decision after seeing the counts.

## Where things stand
| Version | Tag / commit | State |
|---|---|---|
| ix.12.19 | `v3.4.18-ix.12.19` = cea1925 | ran 11-08 16:15:45 → 11-09 04:10:37; ended clean twice (see the update below) |
| **ix.12.20** | **`v3.4.18-ix.12.20` = 483bd73**, branch `ix/v12.20` (`repo-v12.16`), draft CI-only PR #32 | **live since 11-09 04:11:22 local**, 0 crashes, GitHub latest |
| ix.12.21 | not started | new branch `ix/v12.21` from the 12.20 tag |

### The 12.20 install took two drains
- 01:35 published. ~02:15 12.19 drained, made the pre-update copy, ended clean 02:35:53; **the launcher started 12.19 again** at
  02:36:36 instead of installing. Cause unknown: `ix-update.ps1` prints its reason only in the start.bat console. Challenger: the
  failed run took ~13 s after the 30 s pause and the good one (04:10:37 → 04:11:22) ~15 s, so it probably failed late (checksum,
  extract, copy or move): a locked exe fits, unproven.
- 02:37–02:57 the restarted 12.19 drained again and gave up after 20 min; the next try (~03:50) drained, ended clean, installed.
  Hours: 02:00 0.3 GB, 03:00 4.7 GB. GitHub's anonymous limit was fine (59/60), no pin.

## 12.20 verified live (11-09 04:11–07:25)
- **Unlimited hour 05:00: 91.9 GB, 1,725 files** vs 12.19's unlimited hours (11-08 17:00–19:00) mean 88.1 GB (74–103), 1,770 files:
  level; one hour only.
  - DC2 18.6 GB vs 5.0–8.3; unused room 76–80% → 25%. The top-up queued 230 files, all DC2.
  - DC5 11.8 GB (12.19: 3.6–21.3); 53% unused room; the top-up gave it nothing (item 2).
  - DC4 26.0 GB (23.2–30.3): same.
  - **DC1 36.1 GB vs 40.4–43.7.** Challenger: DC1's bytes do not grow with parts (43.7 GB at 2.0 parts, 6,294 KB per slot-second;
    36–40 GB at 2.4–2.7 parts, 4,020–4,787): looks like a DC1-side cap of ~10–12 MB/s that more parts slice thinner. 4 hours. Item 8.
- **Speed limit since ~06:00** (06:00 16.7 GB, then ~1.5 GB/h): ~400 MB/h per server on DC1/DC2/DC4. ~2,090 limit waits/h vs
  1,643–1,692 on 12.19; all the extra is DC5 at 4 parts (item 1), not 12.20 code.
- **Staging: 40.7–41 GB/h**, 6.1 copies at once at 1.9 MB/s (12.19's night: 14–16 GB/h at 1.0 MB/s); backlog 281 → 242 GB. The
  oldest staged file still ages ~1 h per hour (11h41m at 07:15; also on 12.19). Item 9.
- Probable copies: 66 completed files had been held, all released first; none downloaded while held.
- Slot fill: 446 set-aside files let into free slots; band 1 4,005 → 3,610. Given up: 1 (DC1).
- Deadline order: auto, active in every report (expected at the pessimistic median ~2.5 GB/h).
- CPU 99–134% of one core (12.19: 83–140%); system-call time is 86% integrity checks.
- The top-up waited for an hour with no speed-limit wait, so it first ran ~05:40 although 05:00 had none (item 3).
- **Export is failing live:** `export: … error: rename <path>: Access is denied.` (item 6).

## 12.21: essential items (build all; suggested order)

### 1. At most 2 parts per server while that server is speed-limited (double-checked 11-09)
History: 12.4 made 2 parts a *floor* under the limit (and proposed trying DC1 *above* 2); 12.6 made 2 a floor always; 12.19 kept
short plain waits from cutting below 2. Premium waits never change the window (`internal/telegram/pacer.go` tick(), branch
`case d.premium > 0 || d.gateWaiting > 0 || d.waitedGate:`), so a window learned in a fast hour (DC5: 4) stays all through the
limit. This item makes 2 the *maximum* while a server is limited; the floor stays.

Evidence (all 63 saved report hours, server-hours with ≥300 limit waits):
- At ≤2.1 parts: DC1 median 516 MB/h (n=31), DC2 622 (36), DC4 604 (37), DC5 626 (26), each ~400–410 waits/h.
- Above 2 parts, no hour brought more bytes than the servers at 2. Clean comparison (no -503s): 11-07 22:00/23:00 DC5 at 4.0 parts
  625/622 MB with 819/804 waits; DC2 at 2.0 611/612 MB with 422; DC5's own 2-part hours (11-07 12–15) 626–635 MB. Waits double, bytes
  flat: the limit looks like a byte allowance per server. DC1 at 3.0 parts (11-06 17:00) 762 MB, 636 waits vs others 805–830 at 2.
- Lower-bytes examples at 4 parts (11-09 07:00, 06:00; 11-08 00–02) are confounded by -503 storms or too few files (challenger); the
  claim is "fewer waits, same bytes", not more speed.
- Edges: limit waits come in solid blocks, not scattered (waits per limited 10 s interval 1.04–1.8 in mixed hours vs ~1.17 sustained;
  scattered would be ~0.4). Starts and lifts fall within one or two 5-minute buckets of download completions (lifted 11-08 05:55,
  16:15, 11-09 04:30; started 11-08 07:05, 20:40–20:50, 11-09 06:10). Starts are staggered 5–10 min between servers, lifts together.
- No evidence either way that fewer requests make the limit lift sooner (spells 5–9 h; one confounded comparison).

How (challenger's three changes included):
- **Per server, on that server's own premium waits only.** Trigger: **≥3 limit waits on that server within 60 s** (a sustained limit
  gives ~7/min at 2 parts, ~14/min at 4: ~15 s delay; filters stray waits, e.g. DC5's 2 on 11-07 10:00, 6 on 11-08 06:00, 8 in the
  11-09 03:00 drain hour). An interval with only `gateWaiting`/`waitedGate` never triggers.
- On trigger: put a running trial back (`window = trialFrom`), `limitSaved = max(limitSaved, window)`, `window = 2`
  (`paceLimitedFloor`). Windows of 2 or less are left alone.
- Restore when the server has had **no premium wait for 2 min** and no flood: straight to `limitSaved` (do not re-learn), then
  `holdUntil = now + pacePlateau`. While a plain wait's 10-minute ceiling is on, restore to `min(limitSaved, ceiling − 1)`.
- A plain-wait cut while a window is saved **cuts the saved window too** (×0.6, floor 2) instead of clearing it.
- `saveLocked` saves `max(window, limitSaved)`, so an update installed under the limit keeps the learned window (and is capped again
  at once).
- Report: say that "parts allowed" (~10 → ~8 under the limit) and "room unused" drop by design; add per server "minutes capped at 2".
- Expected: ~400 fewer limit waits/h when one server had 4 (~20% of the account's), same bytes. Cost at each lift ≤2 min at 2 parts
  (≤0.3 GB per lift, ~1.2 lifts/day). A -503 storm with no limit waits restores early and re-caps later: harmless churn. Fewer waits
  also lower the chance of the "most file requests refused" shared-gate fallback.
- Tests (fake clock, `pacer_test`): trigger needs 3 in 60 s; drop and restore; trial running when the limit starts; plain cut while
  saved (saved ×0.6); restore under a ceiling; persistence; ≤2 untouched; gate-only intervals. `ix-tools/race.sh ./internal/telegram`.

### 2. Top-up: one retrying file no longer closes a whole server
`internal/app/ix_topup.go` ixTopUpIdle removes a server+size key when any row has `retry_at > now`. A -503 set-aside already needs
another file on that server answered, so it marks a bad file, not a bad server, yet it closes the key for 20 min–3 h.
- `idle[k] = max(0, free − retryRows[k])`;
- skip a server only on direct signals: a plain FLOOD_WAIT on it in the last 10 min, or -503s ≥ answered parts over the last 5 min
  (a small per-server pacer counter);
- report per server the minutes skipped by reason (limit, retrying rows, set-aside rows, no candidates, lane full), files queued, and
  message refreshes per hour (the top-up's only requests).
- Test: 1 retrying row with 4 free slots → 3 idle; storm flag → 0.

### 3. Top-up and slot fill look back 10 min for the speed limit, not 1 h
Under the limit each busy server gets a wait every 8–9 s, so 10 min with none while parts are in flight means it lifted. One helper
for both; the deadline estimate keeps its 1 h `Premium1h`.

### 4. Set a file aside after 2 -503s in a row, not 3
`asideAfterTimeouts`, `internal/telegram/timeout_aside.go`; keep the "another file answered" guard. Challenger, all saved reports:
second retries after a -503 answered 0 of ~404 (DC1 0/101, DC4 0/46, DC5 0/257); first retries DC2 651/651, DC1 129/243, DC5 15/298.
Also catches item 1's "set-asides a little rarer at 2 parts". Adjust the aside tests.

### 5. Report label
`internal/app/ix_diag.go` ~line 360–366: the map lacks `"limited"` ("estimate at  speed"). Add it with the number of hours behind
the median; test that "at  speed" never appears.

### 6. Export swap on Windows
`internal/app/ix_site.go` ixExportTo: target → `.old` already falls back to copying; `.new` → target does not, and a just-written
folder is often held briefly by the virus scanner or indexer. Retry each rename (5 × 2 s), then copy over the target like the first
fallback. The offline index is what the user keeps after 11-30. Test with a held file in a temp dir (Windows only).

### 7. Updates: cheaper, and visible when they fail
- Start an automatic drain only while the speed limit is on (or after 6 h of waiting): an update costs the drain plus ~45 s of
  restart, worth ~2 GB/h under the limit vs 74–103 GB/h without. Test with an `ixDeadlinePremium`-style hook.
- Drains under the limit rarely finish in 20 min (small files at ~0.1 MB/s per server). Partial downloads are kept for resuming, so
  stop every file at its next part (not only large ones) and end the drain in seconds; first check `download/resume.go` covers small
  and staged files.
- `ix-update.ps1`: append to `data\ix-update.log` (time, from → to, step, exception type, HResult, message; ~500 lines; the report
  shows only step and HResult, since messages can hold paths); wait up to 60 s for any tgdl-server process running from `$Bin`;
  rename the old exe to `.previous` (Windows allows renaming a running image) instead of overwriting; retry the move 10 × 2 s on
  IOException; `$ProgressPreference='SilentlyContinue'` and `-TimeoutSec`. Test in `tests/ix_update_check.py` holding the exe open
  with FileShare.Read.

### 8. Measure the DC1 question (no requests)
In `pacer_hours`, per hour: p50/p95/max of the summed MB/s across servers per 10 s interval, and DC1's MB/s in intervals where the
others' sum is above vs below its median. Flat total p95 while the split moves = shared link (then DC1 does not climb above 2 while
the total is at p95); otherwise a DC1-side cap (then DC1 above 2 parts buys nothing; stop its climbs at the best-measured window).
No DC1-first priority yet: DC1 (1.12 TB at ~40 GB/h) and DC4 (641 GB at ~25 GB/h) are both critical paths. An unlimited hour with
`topUpOff` is the user's setting to change, only with their OK.

### 9. Staging: the oldest file never goes
The oldest staged file ages about an hour per hour. Find whether one file is retried forever (`dropStaged` / `stageLaterPause` in
`download/staging.go`) or the hand-out order favours new files; fix so every staged file reaches the library within a bounded time,
and report the oldest file's age and its retry count. 11-09 ~10:00: 3,652 files / 174 GB waiting, oldest 12h19m, 42 GB copied in
the last hour; 378 held lesser copies (16.5 GB) wait for a better copy still in staging (item 17).

### 10. Read-only mode, walked through before 11-30
`app/ix_gone.go` stops all Telegram work once the session is dead (USER_DEACTIVATED, AUTH_KEY_UNREGISTERED, SESSION_REVOKED…,
confirmed by a live call). Add an end-to-end test with invented errors: engine stops and stays stopped, rescans and checks stop,
staging copies, browser, search, export and backups keep working, the report says so. The last night must end cleanly.

### 11. Integrity checks give way to staging
Integrity checks are 86% of the system-call time and read 2–7 GB/h from the NAS while staging copies ~41 GB/h. Pause them while the
staging backlog is above a threshold (e.g. 50 GB) and resume after; report hours paused.

### 12. Groups tab: chats not added yet (user asked, 11-09)
The user wants every chat not in the downloader shown for consideration. Known now from the app's own tables (read-only, no
requests; `chat_access` 378 rows, `ix_peers`):
| Kind | Not added | Notes |
|---|---|---|
| Channels / supergroups, access ok | 58 | 9 others are archived |
| Basic groups, access ok | 2 | 181 are archived |
| **Basic groups that became supergroups** | **10** | **their pre-migration history was never read** (see 13); 9 of the 10 successors are archived |
| Private chats with users, access ok | 21 | media in private chats |
| Restricted by Telegram | 46 | 45 "terms", 1 other; likely unreadable on this account; show greyed with the reason |
| Users deleted | 51 | nothing to fetch |

What to build (Groups screen, `internal/app/ixassets/ix.html` around `loadDialogs`, `/api/dialogs`, `app/dialogs_api.go`):
- A **"Not added yet"** section (or filter chip) listing those chats with type, member count, access state, archived-folder flag
  and, for a migrated basic group, "older history of <successor>" linked to its successor row. Counts per kind at the top, so the
  user sees at a glance what is still missing. Sorted by what is known for free (type, members, last message date if the dialogs
  list has it).
- Check that archived-folder chats are included: the page asks `/api/dialogs?archived=false`; confirm whether the server honours
  the flag and list archived chats too.
- **"Count media" per chat, only on the user's click, with the cost shown**: one `messages.getSearchCounters` request per chat (photo,
  video, document, audio filters in one call), cached in the DB. A "count all N" button says "N requests" first. Must handle refusals
  on the frozen account (show "not available"). Measure the request's wait cost before offering "count all".
- Adding a chat goes through the existing rescan add (its history reads are the cost: show the estimate from the counts, and the
  user's OK is the click). Never add chats automatically.

### 13. Pre-migration history of basic groups that became supergroups
No code handles a supergroup's `migrated_from` chat (grep finds none), and the 10 migrated basic groups in `chat_access` have no
saved messages, so their history before the move is not archived. Telegram keeps it in the old basic group (readable with
`messages.getHistory` on the old chat ID while the account is a member of the successor).
- Show it in item 12; let the user add the old chat like any other (its own group ID, files as usual, linked to the successor in the
  browser).
- Measure first: one history page on one old chat (count requests and waits), then report the cost per chat to the user before any
  rescan. Basic-group message IDs are per account (see the second-account section): fine here, same account.

### 14. Background video thumbnails (local only)
The browser's video thumbnails are made by ffmpeg from the NAS when a tile is viewed; 71k saved videos rely on that. Make them in the
background at low priority (local ffmpeg, no Telegram), paused while staging's backlog is above the threshold of item 11 and while
the browser is in use. The user said 11-09 that tiles now mostly show a low-quality preview (Telegram's small one): background
thumbnails replace those with real frames for saved videos. Report thumbnails made per hour and left.

### 15. Export and offline search, for after the account is gone
Make sure the exported offline index (item 6) covers every saved group (incl. items 12–13 once added), with a search page that works
from the files alone, and that the browser and search work with Telegram unreachable (item 10's test). No Telegram needed.

### 16. Second account: "already archived" import (before any new account starts)
See the next section. Build after 11-30 if time is short before; it needs no Telegram.

### 17. Viewer: a held copy whose better copy is also held (user's screenshot, 11-09)
The user opened a 134 MB video from a mostly complete group: "Preview only: Telegram's small preview is kept, the file is not
downloaded", held as a lesser copy (97% alike) of a second copy that is itself held, so neither is downloaded. Checked live
(read-only, counts only, 11-09 ~10:00): **no waiting loops** (0 held files whose chain of better copies comes back to them). The 1,709
lesser copies held for a queued better copy (121 GB) wait for one that is:
| Better copy | Lesser copies | GB |
|---|---|---|
| itself held as a probable copy of a **saved** file (sampled frames 284, preview 183, partial 14) | 481 | 44.7 |
| queued normally | 422 | 29.0 |
| set aside (deferred) | 417 | 30.8 |
| downloaded, still in local staging (not in the library yet; they wait for it, oldest 12 h) | 378 | 16.5 |
| downloading | 2 | 0.03 |

So the download order is as designed (probable copies go after every unique file; the order is global, so a nearly complete group
still has its held copies at the back). What is wrong is the viewer (`app/ixassets/browse.html` `openItem` ~617 and the relations
block ~650–672, `app/ix_relations.go`):
- "Preview only … the file is not downloaded" reads as final for a held file. For `status==='held'` without a saved look-alike say
  "Not downloaded yet: held as a probable copy; it downloads after every unique file" (keep "Preview only" for files never queued).
- The "This file is held as a probable copy of" heading says "open the saved file instead" even when that copy is only queued. For
  `held-queued`, say "it waits for this copy, which is queued (or held / set aside / in staging)" from the better copy's real state.
- The better copy's row shows *this* file's relation ("lesser copy: waits for a better copy still queued") as if it described that
  row; label it "the better copy this one waits for" and show that row's own state.
- Follow the chain one step, read-only: when the better copy is held as a copy of a saved file (481 files above), list that saved
  file too ("its better copy probably matches this saved file") with "Open the saved copy", and use it for the view instead of the
  320 px preview. A ≤ B ≤ saved by the hold rules (no larger in pixels or bytes), so the saved file most likely covers both.
- No change to holding or release order. Test with invented rows for each better-copy state in the table, and a two-step chain.

### 18. Timeout set-aside under the speed limit (found 11-09 ~10:00, build first)
Report hours 11-08 21:00 → 11-09 08:00, under the limit (per server: MB, -503s): DC5 94/298, –/416, 0/409, 18/394, 11/404,
30/328, 136/272, 2/419, against ~400 MB and 0 -503s on DC2 and DC4 in the same hours; DC1 138–195 MB in hours with 190–240
-503s, ~400 without. DC5's answered time those hours: 0–59 s an hour. Live DB: only 2–4 DC5 files carry a timeout error (one
given up after 10 attempts, one at 6). So a few dead files hold every DC5 slot, and 12.19's set-aside never fires: it needs
another file of the server answered within 30 s after the run began, and under the limit (2 parts, each waiting ~17 s for its
turn, the other part often dead too) that almost never happens. Earlier evidence: a part's second retry after a -503 was answered
0 of ~404 times. Fix: while the server is speed-limited, a part's run of -503s sets its file aside without the "other files
answered" condition (server cap 20 per 10 min and per-file repeats 3 unchanged). Outside the limit the rule stays. Cost: one
message refresh when a set-aside file is claimed again (≤20 per 10 min per server), against the up to 18 further -503 requests
each set-aside saves. Report: set-asides per server per hour, and how many were under the limit. Looks like it could give back
~400 MB/h on DC5 and ~200 MB/h on DC1 in such hours (one night's numbers).
Also seen: under the limit DC2/DC4 got ~600 MB/h on 11-08 day and ~400 MB/h since 11-08 21:00 with no -503s, so the per-server
allowance looks lower since then (Telegram's side; 12.19 was running then). Nothing to fix; watch it.

## A second account later (user's question, 11-09)
**Do not point a new account at this data folder.** Checked live (read-only): `downloads` is unique on (group, message) and neither
`downloads` nor `ix_messages` has an account column (`tgdl_work` has `account_id`). **103 of the 111 groups with downloads are basic
groups (98,456 of 108,886 downloads)**, and a basic group's message numbers are per account: the new account's message N in such a
group would match this archive's message N, and a different file could be skipped as "saved" (lost). Saved messages and queue rows
also carry this account's access hashes and file references. Several places assume one account (`ixTopUpRun` `len(ids) != 1`, the
engine's `ids[0]`).

How copies are recognised (works across accounts):
- Telegram file identity = kind + Telegram photo/document ID + size (`telegram/dedup.go`, no access hash). These IDs are global, so a
  forward of the same file matches from any account.
- Re-uploads (new ID): Telegram's part hashes (`upload.getFileHashes` at claim) against a saved file of the same size
  (`app/ix_subst.go`); after download, sha256.
- Big videos: sampled frames, "probable", held.

Recommended: **a separate install with its own data folder**, plus a read-only **"already archived" import** from this archive
(identities kind:id:size, sha256 + size, video fingerprints), consulted by the identity checks (`ixLinkedIdentity`, the top-up's
same-file query, the library's duplicate skip). Re-uploads are then checked against this library by part hash or sha256; frame
matches are held. Adding the account is the user's decision and only after this one is gone (no extra sessions). Joining many groups
at once on a new account draws long waits.

## What to read after 12.21 installs (latest.txt, numbers only)
1. `[restarts]` 0 crashes; `crashes\running` = 12.21; 12.20 ended clean; the updater's step/HResult line.
2. Under the limit: each server at 2 parts ("minutes capped"), ~420 limit waits/h per server, bytes per server unchanged; windows
   back within ~2 min of a lift.
3. The top-up line: per-server reasons; DC5 queued too; DC5 unused room in unlimited hours well below 53%.
4. -503 set-asides per hour vs gave-up runs.
5. The DC1 / total MB/s distribution line.
6. `export:` without an error; staging oldest-file age bounded; integrity hours paused.

## Live facts (counts only)
- Not saved or queued, distinct (11-08): DC1 67,093 (1.12 TB), DC4 32,210 (641 GB), DC2 8,047 (228 GB), DC5 8,797 (197 GB).
- 11-09 07:15: queue 29,586 files / 2.31 TB (incl. 23,314 probable copies); ~105k files / 1.44 TB not queued yet; 190 groups have
  saved messages, 111 have downloads; 74–75 rescan groups wait only for a files pass. Forecast: everything fits at the 24 h speed
  (25.8 GB/h) and under the limit (10.7 GB/h, 39 h).
- In the unlimited 05:00 hour files passes waited 48 min on the 500 queue limit while 581 slot-minutes sat idle: the top-up (items 2
  and 3) fills this with no history reads, so the queue limit stays.
- Limit spells on 11-07/09 lasted ~5–9 h; ~1.2 lifts a day.
- Saved videos by codec: h264 45,010, not given 25,949, hevc 339, mpeg4 49, av01 11, vp9 3, vp8 1. Photos: 33,729 of 33,732 have a
  thumbnail.
- Telegram's config has no media address for DC1 or DC5; media routes run on DC2/DC4 only.

## Ideas left (not yet essential)
- A files pass aimed at groups rich in idle servers' files (needs history reads: measure and ask the user first).
- Media router threshold for DC4's +7–9%.
- UI leftovers: typing a rank directly; album view caps; Overview's per-group table.

## 12.22 plan (user asked 11-09 13:40; plan only, nothing built; build needs the user's go)
Checked first (11-09 13:20 report, DB read-only, code):
- 12.21 installed 11:31, 12.20 ended clean. 12:00 (limit on all hour): DC5 396 MB at 35 -503/1000 (12.20 07–10h: 2–136 MB at
  616–976); all servers 1513 MB received vs 1182–1341. One hour: "looks like".
- Telegram's deletion date in `ix_freeze` is 2026-11-29 22:24 local (not 11-30). The day-before run (`ix_final.go`: export +
  "final" backup, never rotated) fires from 11-28 22:24. Read-only mode starts on Telegram's own errors, not on the date
  (`ix_gone.go` ixGoneWhy), so every hour Telegram still answers is used.
- Last night's 03:30 export failed: `rename <path>: Access is denied` (12.20; 12.21 adds ixRenameRetry). Check tonight's.
- Rescan: all 139 groups' messages are read (0 unread); 75 wait only for a files pass, which re-reads history
  (`history_runner.go`, ~1 request per 100 messages) and waits on the 500-row queue room. ~97k files / 1.13 TB not queued yet.
  Under the limit ~28 files/h finish, so these get queued almost only in unlimited hours.
- Measured (DB, completed rows by hour, 27 hours over 20 GB, 11-06..11-09): no link between average file size and GB/h
  (14 MB avg → 66 GB/h, 23 MB → 97, 56 MB → 136, 114 MB → 102). Dropped: ordering small files into limited hours.

Items, in order (no new Telegram requests in any):
1. **Last index and backup after the account goes.** The day-before run misses up to ~24 h of downloads, and staged files
   are catalogued only after their library copy (`download/staging.go`), so an export taken with a staging backlog misses
   them. On entering read-only mode (`ixEnterGone`, once, kept in kv like `ix_final_run`): wait until staging has 0 waiting
   (bounded, e.g. 12 h; report what was left), then `ixExport` + `ixBackup(ctx, "after", …)` (never rotated). Report line
   next to "day-before run". Test with an invented gone state and a fake staging backlog.
2. **Export retry.** If the nightly export fails, try again after 1 h, at most 3 times that day; Overview alert and report
   line say failed / retried / ok. Only if tonight's export (12.21's retries) still fails, or as cheap insurance anyway.
3. **Report: unlimited hours needed vs had.** One forecast line: hours at the last unlimited hours' median GB/h needed for
   (a) unique queued, (b) + not queued yet, (c) + probable copies; against unlimited hours per day over the last 7 days and
   the days left to 11-29 22:24. Plus per lift: start, length, GB. Counts and times only.
4. **Conditional, evidence first:** in the next unlimited window read the 12.21 top-up line, idle slot-minutes and "a files
   pass waiting for room". If slots still sit idle while passes wait on room, let the room grow while the limit is off
   (same history reads, earlier). Measure request counts before and after; ask the user before building.
Not planned: a rewrite (20 days left; the running app is the only downloader). A standalone offline viewer over the export
is the right new app for after 11-29, separate from this repo's download path.

## Media viewer plan (user asked 11-09; plan only)
User's goal: see everything related to a file even when downloaded separately, and categories, first a toggle that
separates one person from groups (2+ people in one picture or video frame, by face recognition).
Archive now (DB read-only, counts only):
- 113,739 downloads (35,528 photos, 78,133 videos, 78 documents); faces looked for in 96,777 distinct files
  (3 frames per video), 52,063 with a face.
- Most faces in one picture/frame: 1 face 47,576 files; 2: 3,528; 3: 534; 4+: 425. With faces of 40 px or more and
  sharpness 10 or more only: 44,688 / 2,545 / 319 / 206.
- 69,799 faces, 24,033 in a person; 3,244 people, none named, none hidden; 200 "same person?" questions unanswered;
  files per person median 5, 90th 14, max 123; 609 people in 10+ files.
- Files with 2+ named-or-not people (grouped faces): 674 only, so "group" must go by faces counted, not by people.
- Pairs of people seen together: 266; in 3+ files 137; in 10+ files 6.
Existing pieces to reuse (not rewrite): `ix_browse.go` read model (clusters, families), `ix_relations.go` (exact /
probable / partial copies), `ix_search_people.go` (person=1,7: all chosen in one post), `ix_faces*.go`.
Proposal: a standalone viewer (own exe and port, the archive DB opened read-only, its own small DB for names, merges,
collections), so it never restarts or slows the downloader and keeps working after 11-29; later the export ships it.
- Grid of distinct items (copies folded) with a filter rail: people (Anyone / One person / Groups 2+; pick people,
  "all of" or "any of"), photo/video, chat, date, size/length, saved / preview only / held, collections.
- Item page: one "Related" panel in the existing vocabulary: same file (every post and chat), probable copies, same
  album/post, same people, these people together, look-alike pictures, same video by fingerprints; each a click to pivot.
- People: grid by file count; person page split into alone / with others, "often with" (co-occurrence counts, click to
  see them together); name, merge, answer "same person?".
- Caveats to show: videos are judged on 3 frames; small or blurred faces left out of the toggle by default.
Built and tested with invented data only (never open the real viewer); challenger review of the UI before any release.
Viewer status (11-09, stopped at the usage limit): the user chose a separate program, with an "Open" button in the
existing app. Their complaints: hard to see the messages, hard to see what is duplicated, lots of noise, and previews
that did not work. They asked for deep research and a clean design, and repeated that the media DB must not be examined
(no more DB queries for viewer work). Research (4 topics: duplicates/stacks, people/faces, chat-archive viewers,
grids/filters/performance) was started and stopped part-way; any notes are in research_notes/Media archive viewer
design/. Next: redo or finish that research, write the report to reports/, then design. Current viewer screenshots
(invented data) come from UI_SHOTS=<dir> bash ix-tools/ui.sh repo-v12.16 tests/ui/browse_*.py.
Viewer research done (11-09): report `reports/Media archive viewer design.md`, notes in `research_notes/Media archive viewer design/`.
Build phases proposed (nothing built; each needs the user's go, invented data only, challenger review before use):
1. `tgdl-viewer` exe (own port, db.sqlite mode=ro, sidecar DB for names/merges/verdicts/mutes, derived index): Media grid
   (month buckets, justified rows, thumbhash), filter rail with the faces toggle and chips, viewer overlay with caption,
   context strip and Related rows. A fixture-DB generator with invented data for tests and screenshots. Separate exe so a
   running viewer never holds tgdl-server.exe during an update.
2. Chats transcript (paged by month, calendar jump), Posts density, Copies place (provenance table, album strip, chat x chat
   overlap, probable-pair queue).
3. People index, person page (Alone / With others / Often with), Same person? queue; thumbnail/preview/sprite pass at low
   priority, paused under a staging backlog.
4. "Open viewer" button in the app (an app release); the export ships the viewer after 11-29.

## 12.22 built (11-10; branch ix/v12.22 in repo-v12.16; not pushed, not published)
User asked (11-09): build all viewer phases plus the 12.22 items; keep the old browser as fallback; viewer a separate program
with an Open button; the viewer must NOT run as tgdl-server.exe (VPN per-app split tunnel names tgdl-server.exe; the viewer reads
the NAS and must stay off the VPN).
- Viewer: `tgdl-server viewer` subcommand (internal/app/viewer*.go, viewer_cmd.go, viewerassets/). The server's /viewer/ (behind
  its login) copies its own exe to core-service\tgdl-viewer.exe (same size+mtime check), starts it with a random token, proxies to
  127.0.0.1:8791+ with X-Viewer-Token (ix_viewer_open.go). Viewer: archive DB read-only (store.OpenReadOnly), own state in
  data\viewer (viewer.sqlite, thumbs/), JPEG thumbnails via ffmpeg (exit code not trusted: vIsPicture), background pass paused
  above 50 GB staged; stops after 30 min unused; ends with the server (stdin closes). Updater untouched (it matches tgdl-server by path).
- Faces: "one person / two or more" = max(faces in one picture/frame, distinct recognised people in the file); small/blurred faces
  only when counted. Archive Open viewer button in ix.html; old browser = "Open the media browser (old)".
- Downloader: top-up reads saved messages again when a server with free slots ran dry AND ix_messages grew (at most every 3 min),
  4/slot, 30 max per step, refused files remembered; report shows left per server and size and early reads. Export retried 1 h
  after a failure (3/day). After the account goes: last index + "final" backup once staging is empty (≤12 h), own goroutine,
  re-checks gone before the backup, retries "already" errors. Report: fast hours (count, median, spells, hours needed).
- Old browser thumbnails: WebP only as before, but a real WebP (VP8 chunk) counts even when ffmpeg's exit code says failure;
  uses FFMPEG_PATH. Likely reason "previews didn't work" (unverified on the live machine).
- Measured (invented, 127k files): viewer index 0.23 s, filters 1-16 ms. Not measured on the archive.
- Reviews: two challengers (downloader; viewer/UI). Fixed: negative cursor panic, stale posts scroll, token only on "/",
  alone/one-person counting small faces, merges by roots + Separate button, Back after close, ×N and ≈ badges, file responses
  sandboxed/attachment, failed thumbs retried after a day, JPEG fallback removed (other checks are WebP-only), viewer's own JPEG
  check (it remade thumbnails before), early re-read churn, after-gone in a goroutine, viewer idle stop, start backoff.
- Local env note: this PC's PATH is cut at 2046 chars for Go programs: set FFMPEG_PATH=C:/Users/trabi/AppData/Local/WhisperJAV/
  Library/bin/ffmpeg.exe for fixture videos. Fixture viewer: `VIEWER_SERVE=8799 go test -run TestViewerFixture -timeout 0
  ./internal/app/` (token invented-token); check: tests/ui/viewer_pages.py (also in CI browser-e2e).
After install, read: viewer start line "archive viewer: started on port" in the log only when opened; top-up line (left per
server, early reads) in a fast spell; export retries; backup line "after the account goes: not due"; fast-hours lines.
Published 12.22 (user's OK 11-09): tag v3.4.18-ix.12.22 = 77a7bda, draft PR #34 (CI only), CI green (CI, Archive features,
Docker), release: 8 archives + SHA256SUMS, latest. Installs by 12.21's rule: drain only under the speed limit or after 6 h of
waiting (the limit was off at 19:14). Verify: crashes\running = 12.21→12.22, history.jsonl 12.21 ended clean, report update
line; then in a fast spell the top-up line (left per server and size, early reads, skipped no longer climbing by thousands).
Viewer use is the user's (never open it on real data).
