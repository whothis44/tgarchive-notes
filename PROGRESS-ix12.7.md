# ix.12.7 build: progress (updated 2026-11-06 ~11:30 local)

Read first: `HANDOFF-ix12.7.md` (the plan), `HANDOFF-ix12.md` (standing rules), the project memory.
Worktree: `C:\Users\trabi\Claude\Projects\Telegram\repo-v12.7`, branch `ix/v12.7` (from the 12.6 tag 98021ae).
**Pushed 11-06 ~11:20 (head fa4e1c5), draft CI-only PR #19 (never merge); not tagged.** Live: 12.6 since 11-06 07:39 (installed itself). Publishing needs the user's OK.

## Built (all committed locally; version 3.4.18-ix.12.7; CHANGELOG written)
- Item 1: missing file → its saved copy (`ix_browse_api.go savedCopy`, lightbox links, "copy saved" tag).
- Item 2: forum topic menu in Browse (`ix_browse_topics.go`, feed `?topic=`).
- **Priority (user, 08:03 observation):** keep-busy counts by server slots and lets set-aside files fill free slots
  (`ix_slotfill.go`, `ixDeadlineKeepBusy`, `Controller.FileSlots`); a rescan held by the queue limit no longer
  reserves half the workers. Live 08:15: 5 downloading, small slots 1/20, DC5 idle, 11,075 band-1 files set aside.
- Item 3: report guard over all ixLog formats (+ topic names redacted); "speed-limited" says which waits;
  `[process]`; staging copy rate; library reads by hour; per-server hour figures; fallback start–end.
- Item 4: Organise → "Plan: move uncatalogued copies to _trash" (`ix_uncatalogued.go`, step `trash-uncatalogued`,
  skipped steps don't stop the plan).
- Reliability: FTP test margins; `ix-update.ps1` falls back to the release page (tested: redirect to the 12.6 tag,
  assets 200); dashboard update check cached always.
- Tests: app, engine, telegram, download pass on Windows; 8/8 Playwright UI checks pass.

- Updater self-update (fa4e1c5): the Windows release archive carries ix-update.ps1 (SHA256SUMS-checked); after installing a
  newer program the script replaces itself if the copy parses and differs (keeps .previous). tests/ix_update_check.py: 17/17.
- Live 11-06 ~10:10: Telegram's speed limit came back (328 speed-limit waits in the 10:00 hour, 0 since 03:00); ~2.3 GB per
  10 min after ~6 GB before. 12 downloading; small slots idle on DC2/4/5 while 14,720 files are set aside (12.7 fills those).

## Next
1. Read CI on PR #19 (no gh CLI on this PC: scratchpad pr.py runs/jobs uses the stored git credential).
2. Ask the user before tagging (a tag installs itself on the live archive within the hour).
3. One last hand copy of `ix-update.ps1` to E:\T	g-dl (user's OK needed; safe while the app runs). Later ones self-update.
4. After 12.7 runs live: read the new report lines (file slots by server, files let go into free slots) to see
   whether the slot fill raised throughput. No speed claim before that.
5. To decide with the user (not built): the queue cap counts claimable files whose server slots are full, so the
   rescans stay held for hours; the plain-FLOOD_WAIT fallback length; `paceByAnswers`.

## ix.12.8 (branch ix/v12.8 on top of 12.7, head bcaeeb9, draft CI-only PR #20; not tagged)
- User OK'd editing the live install (away from home): E:\T\tg-dl\ix-update.ps1 is now the 12.7 self-updating one
  (old kept as ix-update.ps1.before-ix12.7). The user said to go straight to 12.8 (12.7 need not be tagged).
- Queue limit: claimable files whose server has no free slot of their size wait apart (`ix_queuecap.go`,
  ixWaitingApart: big + blocked bounded at 2x the limit). Report line "not counted: N waiting for a free slot".
  Trade-off: rescans run again, so keep-busy keeps half the workers for the rescan's files (pre-12.7 behaviour).
- Report saved: data/ixreports/latest.txt every 10 min, hourly YYYY-MM-DD_HH.txt kept 48 (`ix_reportfile.go`).
  Read it live without the login once 12.8 runs.
- Local: app/engine/telegram/download tests pass, gofmt clean. Playwright not rerun (no UI change).
- Next: CI on #20, then the user's OK to tag v3.4.18-ix.12.8 (installs itself on the archive).
- **Published 11-06 ~12:00 with the user's explicit permission:** tag v3.4.18-ix.12.8 = bcaeeb9, release workflow ok,
  GitHub "latest" = 12.8; release note says it includes 12.7 (12.7 never tagged). Windows asset checked: SHA256 ok,
  version 3.4.18-ix.12.8, carries the same ix-update.ps1 as installed. Live was still 12.6 at 12:02.
  Follow-up check scheduled for 13:18 (trig_01QV6FYNQQVn3yApn1uChr4k).
