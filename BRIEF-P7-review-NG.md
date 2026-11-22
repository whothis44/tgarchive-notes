# Brief: the independent review of NG, the NAS give-back and its state on the pages (pages, P7, 2026-11-22)

Read first: `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-P7-review-rules.md` (binding). TEMP, TMP, LOCALAPPDATA,
APPDATA of test processes in `C:\Users\trabi\AppData\Local\Temp\p7-ngrev\` (outside any git copy). Fakes only.

**The piece:** `wip/pages-nasgive` a43fbd91 (from the NAS track's `wip/nas-pcside` 58abd9d7): `git diff 58abd9d7 a43fbd91`.
The ask: `BRIEF-NG-nas-giveback.md`; the report: the "NG" section of `archiver/docs/progress/pages-nas-REPORT.md`;
the door: `NASGiveBack` in `internal/collector/nas_doors.go` (read it and what it does to the files' states).
**The give-back sends the NAS's held files back to this PC's queue: find any way it is offered or runs when it should
not (the NAS working, the NAS answering, nothing held, a request from elsewhere, a replayed click, a held stop), any
word that hides the double-download risk, and any way the pages' answers can block on a slow NAS (the report says
NASStatus reads a linked NAS with a 10 s bound; the Overview carries the NAS's state per account).**
Your copy: `git -C C:\Users\trabi\Claude\Projects\Telegram\repo-archiver worktree add --detach ../wt-pages-review-ng-scratch a43fbd91`.
Report to `C:\Users\trabi\Claude\Projects\Telegram\REVIEW-NG-nas-giveback.md`. Within about an hour.

## Questions
1. When the give-back is offered and when the route runs: against the door's own refusal and the pages' gate; the
   `yes` flag; the guard and held-stop; a removed account.
2. The words before and after: the held count, "may download twice if that NAS still runs", "each starts again from 0
   here"; true of the door's code?
3. Blocking: every pages answer that calls NASStatus (facts, Overview, Accounts): can one take 10 s? With two accounts
   on the NAS, 20 s? What the 5 s keep does under a slow NAS (one ask at a time, or one per request?).
4. The five new fields: fixed words, no path or id, unreadable state said.
5. The lent commit a43fbd91 in collector/pages.go: only what it says.
6. Anything else: its own number.
