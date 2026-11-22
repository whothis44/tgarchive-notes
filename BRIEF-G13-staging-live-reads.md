# Brief G13: the Staging page reads the store's state of the moment (pages track, session P4; 2026-11-16 09:16)

For one Opus coder. A small piece. The Staging page (G5, merged) asked three things of the store when it was
built (board message 94 a of the pages track); Core built them as K15 (merged 11-16 07:42, a8dfefd): two reads
from memory. This piece makes the page use them. Nothing new is shown that the page did not already try to
show; what changes is that the numbers are of the moment and cost no statement.

**The routine-steps rule of this project (`CLAUDE.md`, the archiver section, second point) binds you too:**
you run named tests only; the whole runs are not yours.

**Read first, in full:** `internal/store/copier.go` (`Load`, `CopierLoad`) and `internal/store/writer.go`
(`StagingNow`, the type and what each field means, `probeAway`) on the main head, with
`archiver/docs/progress/core-store-REPORT.md`; `internal/server/staging.go`, `stagingread.go`,
`stagingverdict.go`, `stagingview.go` and the script `web/assets/js/pages/staging.js`;
`internal/collector/livepages/staging.go` and `internal/collector/pagesstaging.go`;
`C:\Users\trabi\Claude\Projects\Telegram\REVIEW-G5-staging.md` (what the review of the page found: build to
it).

## What is known already (read by the main session)
- **What Core gives** (its entry "K15"): `func (c *Copier) Load() CopierLoad` (`Now`, `Copiers` allowed now,
  `Pinned`, `Busy`, `LimitedNow`, `Written`): memory only, no ledger read, no file system call; `Written` is
  the bytes the copiers have written to the library since the copier was made, counted as each write
  returns, never reset: **written, not verified; a failed or repeated copy's bytes count each time.**
  `func (w *Writer) StagingNow() StagingNow` (`Now`, `Away`, `AwaySince`, `Resting`, `RestSince`,
  `RestUntil`). "Staging away" now ends by itself within one probe period of the folder answering again.
  **Neither may be called with the collector's own lock held** (both reach `speedLimited`, which takes it).
- **What the page does today:** the copiers' busy and allowed numbers come through `StagingGauges`, which
  reads the whole queue summary a second time on every reading: more than half of a reading's 139 to 202 ms
  at 100,000 ledger rows (measured at G5). The copy speed is "copied and verified", counted when a file
  ends, so it shows nothing for minutes while a large file is copied. For "staging away" the page shows the
  mark's time and its own "readable now" read, because the mark used to clear only at the next download's
  open.
- **The old app's lessons for this page** (TRIED-BEFORE 8, 16; answers 7 and 8): staging and the copy to the
  library were where the old app stalled without saying so; every number says what it counts and when it
  was read; a speed shown as 0 while work is going on is the worst sentence a page can show; nothing in the
  background reads the library on the NAS while copies wait.

## What to build (`internal/server`, its scripts, `internal/collector/livepages/staging.go`, and the hand-over in `internal/collector/pagesstaging.go`)
1. **The copiers of the moment from `Load()`**, carried with the page's live reading (no statement):
   allowed now, busy, pinned, limited now. The gauges' second read of the queue summary goes from the
   reading's path where it was only there for these numbers; say exactly what `StagingGauges` is still asked
   for and when. **Measure a reading before and after** on an invented catalogue of 100,000 ledger rows (the
   way G5 measured: its test or report says how) and put both numbers in the report.
2. **A speed of the moment: bytes written to the library**, from two of the page's own readings of
   `Written` (the difference over the time between them; never across a restart of the store: a `Written`
   that went down, or a store that was not running in between, shows no speed for that reading). Shown
   BESIDE the existing "copied and verified" speed, each with what it counts in plain words ("written to the
   library now, before its check" and "copied and verified, counted when a file ends"); with copiers busy
   and no reading pair yet the page says "measuring", never 0.
3. **Staging away and resting from `StagingNow()`**: away and since when; resting (a full disk met: new
   files go straight to the library) since when and until when. The page's own "readable now" read stays
   only if it still tells the owner something the store does not; if you remove it, say what replaced each
   sentence. Every time through the page's one form (`timeAt`, `timeUntil` in `format.js`).
4. **The lock rule:** prove by reading, and say in the report, on which goroutine and under which locks the
   adapter calls `Load()` and `StagingNow()`; neither under the collector's own lock. If the live poll's path
   holds it, the call moves; do not take a new lock around them.
5. Nothing else on the page changes. No route is added. With no store (the pages alone, the demo) the page
   says what it says today; the demo may invent these numbers as it invents the others.

## Tests (named; invented data; no test judges on real time)
- The copiers' numbers reach the page from the seam's memory reading; a reading makes no statement more
  than before for them (count statements, as the page's cost tests do), and the gauges are not asked where
  they were asked only for these numbers.
- The written speed: two readings give a speed; one gives "measuring"; a `Written` that went down or a
  store not running in between gives none; busy copiers and an equal `Written` twice is a true 0 said as
  "nothing written in the last N s", not "0.0".
- Away, away ended by the store itself, resting with its two times, a rest moved by a second full error.
- One mutation each for the restart rule of point 2 and for point 1's "no statement" (which test fails).

## Rules (hard)
- Copy and branch: `git -C C:/Users/trabi/Claude/Projects/Telegram/repo-archiver fetch private`, then
  `git -C C:/Users/trabi/Claude/Projects/Telegram/repo-archiver worktree add -b wip/pages-staging2 ../wt-pages-staging2 <the head of private/claude/charming-feynman-vm2xia>`
  (efac56ff at 09:15; write the exact commit into your progress file). Work only in
  `C:\Users\trabi\Claude\Projects\Telegram\wt-pages-staging2`. Do not touch the main checkout's working tree.
- Product code in `internal/server` (Go, `web`), `internal/collector/livepages/staging.go`, and the hand-over
  in `internal/collector/pagesstaging.go` (as few lines as it takes, a commit of its own). Nothing in
  `internal/store` (Core's: if a field you need is missing, say so and build without it), the catalogue, the
  launcher, the viewer, `internal/actdoor`, `clicks.go`.
- **Nothing runs against Telegram.** Invented data only; never touch `E:\T\tg-dl`, the folders `a3`, `b`,
  `app`, `C:\Users\trabi\tgarchive-app`, any real catalogue, media, session or account; start no installed
  program and stop no process you did not start; send no input to the desktop and open no window.
- New log, error and state text is constant words with numbers: never a path, a name or a folder (the two
  folders shown on the owner's page stay on the page only).
- `TestAssetsStaySmall` holds every script under 600 lines. After any change under `web/assets/js`:
  `TestScriptsNoDuplicateOrMissingNames`, `TestAssetsStaySmall`, `TestScriptsTimeOnlyThroughFormat` and
  `node --input-type=module --check < file` for each changed script.
- Go: Git Bash, `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`, one go command at a
  time, `GOGC=25 GOMAXPROCS=2 go test -p 1 -run '<names>' ./internal/<package>`, named tests only: no whole run
  of `internal/server`, `internal/collector`, `internal/store` or `internal/catalog`, no race detector, no
  Docker. Before each go command:
  `powershell -NoProfile -Command "(Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB; (Get-CimInstance Win32_Processor).LoadPercentage"`;
  wait when free memory is under 2.5 GB or the CPU is over 85% (and really wait: another coder and other
  sessions share this PC). Every wait in a test has a bound.
- **Open it before handing back:** the Staging page in the built-in browser (the way G5's coder did: its
  report says how; an invented catalogue, a fake seam, 127.0.0.1:8799), desktop and 375 wide: copiers busy
  with a written speed, "measuring", staging away, resting. Say exactly what you saw and what you did not.
- Before handing back, list the test functions your difference removes against your base
  (`git diff <base> HEAD | grep '^-func Test'`) and account for each: the expected count is none.
- Any file that holds a Windows path is written with the file-writing tool, never from inside a shell or
  script string.
- Commits: `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, the message ending with
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; commit work in progress as you go and push only
  `git push private wip/pages-staging2`. Never push, merge into, rebase or switch any other branch; never stash.
- Keep `archiver/docs/progress/pages-staging2-PROGRESS.md` current from your first action and commit it with
  each step.

## Hand back
Commit-ready: everything committed and pushed, the tree clean, `gofmt -l` clean, `go vet` on the packages you
changed. `archiver/docs/progress/pages-staging2-REPORT.md`: what was built against each numbered point; the
two measured readings (before and after) and how they were measured; where and under which locks the two
reads are called; every sentence on the page that changed, old and new; every test and mutation with its
result; what you saw in the browser and what you did not; what was NOT verified; anything in this brief or
in Core's two reads you found wrong; the changed files; a drafted final commit message. Your final message:
the head commit and the base it sits on, what is built and tested, the two numbers, every departure, and
your doubts, plainly.
