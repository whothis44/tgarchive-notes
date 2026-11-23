# What is left after the fixes of 11-23, in one run (the owner's Console credit, through the Agent SDK script)

<!-- How the owner starts it (from any PowerShell window; runs by itself, Opus 5.5 at high effort, stops near $70):
python C:\Users\trabi\Claude\Projects\Telegram\ix-tools\agent-run\run_agent.py --auto --effort high --budget 70 C:\Users\trabi\Claude\Projects\Telegram\PROMPT-NEXT-1123-console.md
The log goes to runs-agent\PROMPT-NEXT-1123-console-<time>.log. Afterwards an interactive session reviews the run with
START-REVIEW-CONSOLE-1123.md. -->

**Models:** you run as Opus 5.5 at high effort; every coder and reviewer subagent you start is Opus 5.5 at high
effort too (`model: opus`). No other model.

**The owner is not watching: do it all in ONE go, without stopping.** Read `CLAUDE.md` and `START-INTEGRATOR.md`
first and follow their rules (privacy; never touch, start or write to `C:\Users\trabi\tgarchive-app` or
`C:\Users\trabi\tgarchive-app-next` except as the build script does; nothing against Telegram; commits as written
there; one coder per piece; review by risk). Merge each piece as it is finished (`START-INTEGRATOR.md` "Each batch",
`ix-tools/batch-tree.sh` then `ix-tools/merge-batch.sh`), so a later failure never undoes an earlier one. Where a step
cannot be done, skip it, say why in the final report, and go on. Give ONE report at the end.

## Start
`git -C repo-archiver fetch private`; the head of `claude/charming-feynman-vm2xia` is the base for every piece below
(the integrator of 11-23 merged the owner's fixes there: see "Fixes of 11-23" in `SESSION-11-PROGRESS.md`). The whole
`internal/collector` test `TestNASGiveBackRefusedWhileReachable` and nasdl `TestAllowListAndCap` were flaky before
11-23; the first is fixed now; a failure of either is run by name before it is called load.

## 1. Library pictures, with ONE shared read total (the owner's decision, 11-23)
Branch `wip/fix-libpics` (a WIP commit b59fd6d4 stopped half way, on 0722ac08: the earlier `wip/all-libpics`
07176168, built and reviewed on 11-22, brought over, plus unfinished wiring). Finish it: pictures already in the
library get their PDQ hash by C29's pass shape, edges only through C33's door, nothing held, skipped or released.
The owner's words: ONE total for all library reads of the copy checks, videos and pictures together, set by the
owner — keep the stored key `fingerprints.library_mb_per_hour` as that shared total (both passes draw from one hourly
budget; the sum never exceeds it; 0 = off for both); and its DEFAULT raised from 5,000 to 50,000 MB an hour ("during
the unlimited speed hours we could download around 100 GB or more; this will never catch up"). No upper bound of the
app's own. The Settings label and help say it covers videos and pictures. Tests for the shared budget and the default.
ONE independent Opus review of the diff (it decides copy edges).

## 2. The watchdog's own alerts: all three steps (the owner's yes, 11-23)
As `DESIGN-CORE-watchdog-alerts.md` says, on a fresh branch: (1) crash and restart raised once per crash as an alert
ended as raised (`watchdog.crashed`, K22's record and channels; a marker of the last crash reported); (2) the
window names the watchdog's give-up, and the next start records `watchdog.refused` until the first healthy hour;
(3) a hang noticed by the window (status not moving; the watchdog's status file older than its stale_after). The
watchdog keeps its wall (never opens the catalogue). A schema step only if needed (then `internal/catalog -run
'Schema|Step'` whole). Tests for each step.

## 3. Add an account while another account's sign-in waits (the owner's complaint, 11-23)
Today "Add an account" is refused while a new account waits for its sign-in: the catalogue's unique index on the
Telegram id (the sign-in coder's finding; see `internal/collector/signin_pages.go` AddAccount and the account table's
index). Make it possible with a schema step (safe twice and on older files), keeping every rule that one login is
never live twice and an account's number is never given twice. ONE independent Opus review (it acts for the owner's
accounts).

## 4. Small leftovers
- Mirror (`SESSION-MIRROR-PROGRESS.md` "Owed"): a pages door for `mirror -pause-reset`; the held / set-aside /
  put-back facts and the paces on the pages. (Its item 1, the real numbers, reads the owner's catalogue: skip it.)
- Copies (`SESSION-COPIES-PROGRESS.md` "Next small items"): C30's T4 mark; the review owed on C32's N1 door's FIRST
  branch (no length check). Anything that changes what is held, skipped or released gets ONE independent review.
- Viewer (`SESSION-B-PROGRESS.md` NEXT 2): one loopback client for the pages' reads.
- Two UI quirks the owner flagged (11-23): (a) DONE by I-8 (232fcef3: the pages' format.js writes AM/PM without dots); check only the viewer's own
  time format (`internal/viewer/web`) for the same "a.m.." and fix it the same way if it has it; (b) on the Overview during a held stop, the header's "Quit now" and
  the held bar's "Quit now" sit side by side: show one. Node or browser tests; `server -run 'TestAssets|Security'` and
  `viewer -run 'TestWall|TestHomeDevice|Security'` by name.

## 5. One list again
`ROADMAP.md` (last updated 11-16) and `FEATURES.md` (11-22) are behind. Bring both up to date against what is
merged (git log, the tracks' progress files' state blocks, `BOARD.md`), marking each row built / part / none as it
is now, and add a short "Open now" section at the top of `ROADMAP.md` in priority order. Words only.

## Not in this run (they need the owner or real data)
The bring-in's trial on a copy of the owner's catalogue (`SESSION-B-PROGRESS.md` NEXT 1), the NAS move, the
mirror's real numbers.

## At the end
`bash runs-int-i6/folder-next.sh` once (it marks the folder update-only), the notes (three lines under a heading
"Console run after 11-23" in `SESSION-11-PROGRESS.md`, the board's integrator row), one notes commit,
`bash ix-tools/notes-backup/backup.sh`, and the one report: what merged (heads), what was left and why, and exactly:
- "Quit TG Archive, then run: `powershell -ExecutionPolicy Bypass -File "C:\Users\trabi\tgarchive-app-next\update-folder.ps1" -Into "C:\Users\trabi\tgarchive-app"`"
- "Run only `C:\Users\trabi\tgarchive-app\tgarchive.exe`."
- "Windscribe's inclusive split tunnelling list holds only `C:\Users\trabi\tgarchive-app\programs\tgarchive-collector.exe`."
