# Brief L3: the launcher's findings of the first real-window test (pages, P7, 2026-11-22)

Same coder and rules as L2 (`BRIEF-L2-launcher-asks.md`'s house rules), on a NEW branch `wip/pages-qa1` cut from your
L2 head (new copy `wt-pages-qa1`). Read `C:\Users\trabi\Claude\Projects\Telegram\reports-qa\QA-6aa225fb.md` whole
(a tester's report of the folder built at 6aa225fb on a second PC, pictures in `reports-qa\6aa225fb\`: look at
05, 09, 11, 03, 04, 08-empty-06). The front end of each finding is the UI track's (U-1, told); yours are the
launcher's logic, words, routes and the folder. A line in the launcher's look files only as ONE lent commit.

## What to fix (the report's numbers)
1. **Finding 1, the first start without the API settings file:** (a) check that L1 + SW already give what the
   tester expected on today's branch: the window opens viewer-first with the library reachable, and /api/state's
   why says "Not collecting: the Telegram API settings are missing" with the fix. Show it with a stand-in collector
   that refuses with the real refusal line. (b) **The window closed and opened three times during the start**
   (launcher log: starts 1 to 3, one ending 0xC000013A): find why (the joined window restarted by the launcher's
   retry while the collector refuses? the watchdog?) and make a refused start show ONE window that stays. Test.
   (c) The words for the missing file say where the file goes in fixed words (inside the folder or the app's own
   settings place, never a path of this PC printed by the program: say how, e.g. "in the app's settings folder,
   which Settings > Program opens").
2. **Finding 5, no notification-area icon:** "Keep it running" leaves the app running with nothing visible. Add a
   notification-area icon in the launcher (`Shell_NotifyIcon`, a Windows-only file; the menu: Open the app, Quit
   the app (the same quit as the close box's), and the tooltip "TG Archive · <state words>" from the launcher's own state words; its icon from the program's
   resource group 1, which U-1's F8 adds to tgarchive.exe: fall back to the system's default icon when it is absent);
   shown when the close question's answer is "Keep it running" (and while the launcher runs with no window). No window on the owner's screen in tests: test the menu's actions through the launcher's code
   paths with the icon's Windows calls behind an interface. **And the close box's words** say "still collecting"
   only when an account is signed in and collecting; otherwise "the app stays running in the notification area".
3. **Finding 7, Quit asks in a browser dialog:** a launcher route (POST, the same guard and token) that shows the
   native close box's Quit question (the box of closeask.go) and acts on its answer, so the pages' Quit button
   (U-1's) can call it. Say its shape.
4. **Finding 8 (logic part):** the setup never preselects a VPN adapter that is not on this PC now (choose none,
   and say why in the field's words); the two-window questions ("Viewer: own window / browser / None", "Where the
   app's pages open") are removed from the setup's DATA (U-1's F6 dropped them from the view only), the stored
   values kept for old files.
5. **Finding 9, the folder box:** owned by the app's window (centred over it, not a 1x1 hidden window at the
   screen's centre), and opening at the field's current value (or the app's folder) instead of Documents.
6. **Finding 4 (words only):** the launcher's page no longer says "Closing the window does not stop the program".
7. **Finding 16:** the folder's README.txt says the app opens in its own window.
8. **Finding 6: NOT yours** (U-1's F8 puts the app's icon into `tgarchive.exe` as resource group 1; the tray icon of point 2 loads that resource).

## Hand back
Branch pushed, copy clean; the whole `internal/launcher` and `cmd/tgarchive-open` once (TEMP outside a git copy),
gofmt, vet; the report (per finding: done, commit, test, what a person sees; what is the UI track's). Final message:
head, report path, one line not verified.
