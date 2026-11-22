# Good morning: what to do (written 11-22 02:15 by the integrator I-6; updated overnight, newest note at the end)

## 1. Start the next integrator (one line)
Open a **new session** in this folder (`C:\Users\trabi\Claude\Projects\Telegram`) and paste exactly:

> Read `START-INTEGRATOR.md` and do what it says.

It reads the board, the queue and `SESSION-11-PROGRESS.md`, checks the disk, tells you the state in about ten lines, and
keeps the track sessions going. Use Opus (the default). The old integrator (this session, I-6) can then be archived:
the new one does it, by the standing rule, once it has taken over.

## 2. Switch your app to the newest build (if a newer one is ready)
`SWITCH-TO-NEW-BUILD.md` says which build is in `C:\Users\trabi\tgarchive-app-next` and what it changes. The steps are
always the same: close the app's window and choose **"Quit the app"**, then run:

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\trabi\tgarchive-app-next\update-folder.ps1" -Into "C:\Users\trabi\tgarchive-app"
```

## 3. Things only you can do (each a few minutes; nothing is blocked on them except what they enable)
- **The alerts bot:** when Core's alerts piece is merged, make a bot once with @BotFather in Telegram, paste its token
  on the app's Settings page, and press Start in the bot. Then alerts reach your phone, and you can answer them.
- **Read the design notes waiting for you** on the board's "Waiting for the owner" list (the two-way bot's commands,
  and anything new a track put there overnight). Each has a recommendation; "as recommended" is a full answer.
- **The blocked mirror chat** (the batch of 44): it clears by itself once the mirror's M16 is merged and installed;
  nothing to click.

## 4. What was planned overnight
- Merge the UI build (the agreed frame, the app's icon and "TG Archive" title, the library views, chats as
  conversations), with the NAS link and the launcher's fixes. Then the second folder is rebuilt from it, and the
  tester on the second PC uses it and reports.
- Merge as they are listed: the mirror's M16 (no more blocks waiting for you), M17 (topic names, fast topic creates,
  the adaptive fast pace for ALL mirroring, newest posts first); Core's K18, K22 (alerts), K26 (topic names);
  the client's A1 and A2; the NAS program once its race is fixed; the Chats page rebuilt (F11a).

## Overnight notes (newest last)
- 02:15: usage 45% of the week (about 8% an hour with ten sessions). At 80% the tracks are told to finish and list
  what they have and start nothing new, so that some of the week is left for you.
- 02:22: you asked about the deduplication. The exact check, the look-alike hold and lesser copies behind the best RUN. The sampled-frame check and the fingerprints are BUILT BUT SWITCHED OFF, and the reuse of sampled parts was never connected to the downloader. Copies has it as its first piece (C29): connect the parts store, and switch both on by default as settings.
- 02:30: you asked what else we thought we had. Audit: `AUDIT-INACTIVE-FEATURES.md` (72 features: 27 run, 12 built but switched off, 7 built but not connected, 5 only on invented data, 21 not built). The ones that matter, each now with its track: the frame check and fingerprints (copies C31: on by default); your "same / not the same" verdicts read by nothing (the launcher never passes the switch: pages); hard links off by a default flag (pages); the nightly backup never runs (Core); settings with no control on a page (UI F10); the unified archive and alerts (merging over the day).
- 02:40: the UI build passed everything but one real slowdown (opening a post under heavy writes, 40 ms against a 30 ms limit; 15 ms before). It is held for a quick fix by the UI and viewer tracks, then merged; the NAS pieces merge meanwhile.
- 03:02: THE UI BUILD IS MERGED (32d48a4c) and in the second folder: switch with the same command (section 2). The timing failure was this PC's load (a quiet comparison on the second PC showed no slowdown). The NAS link and program are merged too. The tester is running on this build.
- 03:03: THE UI BUILD IS MERGED (32d48a4c) and in the second folder: switch with the same command (section 2). The timing failure was this PC load (a quiet comparison on the second PC showed no slowdown). The NAS link and program are merged too. The tester is running on this build.
- 03:40: the tester on the UI build (reports-qa/QA-32d48a4c.md): NEARLY THERE: usable for the archive; "shabby" no longer applies. Left: a fresh first start without Telegram keys, the browser-style Quit, no tray icon, the state pill disagreeing, numbers that disagree, the folder box sticking after Cancel. All with UI and pages. The Chats page and Settings rebuild (UI-2) goes in the next batch.
- 04:38: build 4bf224b3 is in the second folder (switch with the same command): the copy checks ON by default (frame check, fingerprints, sample reuse), mirror rename, Core fixes. HELD: the Chats/Settings rebuild (three security walls), the client actions (two real bugs). Usage 64%: at this pace 80% around 06:40, when the tracks are told to finish and list.
- 05:30: usage 70%. Testing now: alerts (K22), faster collector tests (K23), forum topic names (K26), and the UI with Chats/Settings rebuilt, alerts and mirror rename drawn (F13, which holds UI-3; three security walls fixed). Next: the mirror fixes M16+M17 (no more stops, the fast pace, topics in 2 minutes), the nightly backup (K27), downloads for chats joined while away (K28), the launcher fixes from the tester (L3). The client actions (A1, A2) are held for two bugs.
- 06:30: build be291417 is in the second folder: the Chats page and Settings rebuilt, alerts and mirror rename in the app, the tester's launcher fixes (tray icon, own Quit, a refused first start explained). Testing now: the mirror fixes M16+M17 (no more stops, the fast pace, topics in 2 min), the nightly backup, downloads for chats joined while away. Usage about 75%.
- 11-22 08:34: **THE MIRROR FIXES ARE MERGED (09aeba54) and in the second folder: switch now** (section 2). With them: the nightly backup, the Chats page and Settings rebuilt, alerts listed in the app, the launcher's fixes, the copy checks on. **Usage reached 80%**: every track was told to finish and list what it has and start nothing new. Waiting for the next integrator: K22b (alerts away: your bot), the client's actions (A1, A2), K24 with the bring-in (one unified archive), the UI's F15, F16a, F16. Owed: a full race run of the mirror package with a longer bound.
