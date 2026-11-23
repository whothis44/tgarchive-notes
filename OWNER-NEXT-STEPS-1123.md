# Your next steps (11-23, after the integrator I-8)

Everything of today is merged (head 3dd304d) and built into the update folder. Every whole test package passed; the
update script was tried on scratch copies exactly as you run it. Not seen yet: the new pages in the real app window,
and anything against your real VPN or Telegram.

## 1. Install the update
Quit TG Archive (Quit on its pages), then from any PowerShell window:

    powershell -ExecutionPolicy Bypass -File "C:\Users\trabi\tgarchive-app-next\update-folder.ps1" -Into "C:\Users\trabi\tgarchive-app"

To undo it (quit the app first):

    powershell -ExecutionPolicy Bypass -File "C:\Users\trabi\tgarchive-app\update-folder.ps1" -GoBack

## 2. The app to run
Only `C:\Users\trabi\tgarchive-app\tgarchive.exe`. The update folder's tgarchive.exe now only shows a page saying it
holds the next update.

## 3. Windscribe inclusive split tunnelling
Exactly one entry: `C:\Users\trabi\tgarchive-app\programs\tgarchive-collector.exe`.
Keep `tgarchive.exe`, `tgarchive-viewer.exe` and `tgarchive-window.exe` OUT of the list (tgarchive.exe must see your
home address outside the VPN). Settings › Connection to Telegram shows the path and why a check fails.

## 4. The Console run (Opus 5.5 high, by itself, stops near $70)

    python C:\Users\trabi\Claude\Projects\Telegram\ix-tools\agent-run\run_agent.py --auto --effort high --budget 70 C:\Users\trabi\Claude\Projects\Telegram\PROMPT-NEXT-1123-console.md

It does: library pictures with one shared read total (default 50,000 MB an hour), all three watchdog alerts, adding
an account while another's sign-in waits, the small mirror/copies/viewer leftovers, the double "Quit now" (and the
viewer's own "a.m.." if it has one), and an up-to-date ROADMAP/FEATURES.

## 5. After the Console run
A new Claude Code session in `C:\Users\trabi\Claude\Projects\Telegram`, pasting:

    Read START-REVIEW-CONSOLE-1123.md and do what it says.

It checks everything the run did, fixes what is wrong, builds the update and gives you the command.

## If an integrator session stops before finishing
A new session, pasting:

    Read START-INTEGRATOR.md and do what it says; take over from the newest "STATE FOR A TAKE-OVER" block in SESSION-11-PROGRESS.md.

## Still yours, whenever you want
The NAS move (`OWNER-NEXT-STEPS.html`); the bring-in of the old archive (the unified archive: a trial on a copy of
your catalogue first, then your own step from the launcher).
