# Brief: the second look at E19's fix rounds (copies, session C4, 11-16)

**For an Opus 5.5 reviewer at high effort, fresh: you have seen neither the piece nor its first review's author.
A focused pass (aim at 30 minutes): the fixes of the first review, not the piece again.**

## What you review
Branch `wip/copies-19`, the fix rounds' commits `4bb0ba2c..865681c1` (22 commits: the round E19b, then a small
round E19c that took a guard out of the lane's SQL again). **Make your own detached copy** from
`C:\Users\trabi\Claude\Projects\Telegram\repo-archiver`: `git worktree add --detach ../wt-copies-review19b-scratch
865681c1`; read and probe there (`zz_probe_*_test.go`, never committed; leave the copy as it is). Never touch
`wt-copies-19`. Read first: `C:\Users\trabi\Claude\Projects\Telegram\REVIEW-E19-owner-verdicts.md` (the first
review: its findings), `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-E19b-fixes.md` (what was asked; E19c's task
is in the report's section 8), then the difference, then sections 7 and 8 of
`archiver/docs/progress/copies-pairword-REPORT.md` on the branch. The first reviewer's probes are three untracked
files in `C:\Users\trabi\Claude\Projects\Telegram\wt-copies-review19-scratch` (read-only for you; **its
`TestProbeBatchPanic` hangs by design: do not run it**): copy the others into your copy and run them at this head.

The piece: the owner's "same" or "not the same" on a probable pair acts on a held copy in the catalogue; a held
copy whose saved look-alike is lost is judged again; a reader applies the viewer's table. The owner's rules:
- **Only exact evidence may skip a file.** No path of this piece may set a file to skipped or gone.
- **Never download from a source the owner did not choose**: a file whose chat, kind or topic is not collected, or
  that is carried only as an alternative version, must not become wanted by a word or by a lost look-alike.
- **The download path is finished and is not changed**: `lane.go` and `state.go` must equal the base; a claim or a
  finish must never wait on something holding the catalogue's single writer for long (long writes are chunked).
- Every wait has a bound. Nothing in the background reads the library folder. Logs: counts and fixed words only.

Go: `. /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`, then your copy's `archiver`. Named tests
only (`-run`, `-count=1`); whole `internal/pairwords` is allowed; never the whole `internal/catalog` or
`internal/supply`; no `go vet` over packages; no race detector. Before a run: less than 2 GB of memory free or the
CPU above 80% over a few seconds: wait a minute, at most 10 times, then `GOMAXPROCS=2`. Invented data only;
nothing against Telegram; never open the owner's folders, catalogue, decisions file or media.

## The questions
1. **The high finding's fix.** Does every place of the piece that writes `state = 'wanted'` (the word, a word
   taken back, a lost look-alike, the door for waiting files, both hand-backs of the exact check, a file coming
   back from transfer) first ask the rule `WantAgain` asks (`mediaNowOf`, `wantRule`)? Run the first reviewer's
   three probes and write your own for the cases they do not cover: a kind no longer collected, a topic not
   chosen, an alternative version, each made while the file was held, in transfer and set aside, each entry.
   **Was `wantAgainMedia` moved without changing what it decides** (read the refactor commit line by line; which
   existing tests of `WantAgain` guard it; did any change)? "The owner's release or fetch-for-real wins over the
   rule": is that the catalogue's rule elsewhere (`notCollectedBack`), and can it make wanted a file from a chat
   switched off? A file on another archive's saved list is "left held as it is": can it be left held with
   `probable = 1`, no edge and no way out, or supplied in tier 5 for ever?
2. **The files that wait to be judged again (`c_pair_pending`).** A held file waits with `probable = 0`; a file
   in transfer or set aside waits with the columns that bring it back held. Trace every reader and writer of
   `probable`, `state`, `check_first` and `reason` that can meet such a file before the door has judged it
   (`judgeChat`, the topic settle, `wantedAsMainSQL`'s four statements, `roleChanged`, `attach` meeting the same
   Telegram file again, the chat settle, `Release`, `asideBack`, the exact check, the frame check's doors, the
   owner's hand: `Transition`, "retry now", "keep held"): can any make it wanted when the rule would say held,
   skip it, or leave its row in the table for good? What happens to the table at a restart, when the door fails
   every time, when the media's row is deleted? Is a file ever in the table and also judged twice in a way that
   changes the answer? The window the coder names (a file given back from transfer is a held probable copy until
   the Supply's next settle): how long at most, what can claim it, is it worse than the base's own window for a
   plain file in transfer whose chat is switched off?
3. **The Supply's settle (`internal/supply/supply.go`, the settle's lines).** Where is `Settle` called from: a
   lane's `Next`, a finish, a timer? What does the new call cost each time while the table is empty (name the
   read and its plan), and can it make a lane's `Next` or a finish wait while the door works or fails (the door:
   100 files a transaction)? Can a failing door keep the chat settle's own chunks from running? With no word and
   no lost file ever, is the Supply's path the base's?
4. **The writer's time.** Measure again on invented rows: `WantAgain` of a saved file with 5,000 look-alikes held
   against it (each transaction), the door's slowest transaction, a reader's chunk of 100 "different" and of 100
   taken back, the one statement that makes 4,800 rows `probable = 0`. Is any over 250 ms on this PC, and does any
   grow with the catalogue's size (rung 6's read per judged file: `TestLookAlikeCostAtScale` has the house's
   figure)?
5. **The reader.** Fix 4: no kept connection; the copy into `Config.WorkDir`; the copy opened `immutable` (safe
   for a private copy: yes or no, and why); the stat before and after; the two gaps the coder names (the viewer
   closing between the stat and the `mode=ro` open; change seen only by the file's times: does Windows update a
   WAL-mode database's times when the viewer commits to the `-wal` only? Probe it: a word written by a second
   connection that keeps the file open: is it seen within two turns?). Fix 2: the missing table; the 24 hours for
   more than 10 take-backs (per word; a restart starts them again; rows that come back; exactly 10 and 11; a mix
   of new words and take-backs in one turn; can a real single take-back ever be held up by it?). Does the reader
   still never create anything in the viewer's folder (a listing before and after, the viewer's file open and
   closed)?
6. **Fixes 6, 7, 10, 11:** each as asked; with no word on record are rung 6, the stills rule, the step at a save
   and the exact check's hand-backs the base's in result and in reads at `attach` (the plans' test)?
7. **The schema step** now makes two tables: its form against the house's other steps; a file at the step's
   version made by the first form of this branch (one table): can one exist outside test copies, and what happens
   to it?
8. **Tests.** Which existing tests changed in what they assert, and is each change right? Break two fixes of your
   choice and say which test failed. Which rule of the fix rounds has no test?

## What you hand back
`C:\Users\trabi\Claude\Projects\Telegram\REVIEW-E19b-second-look.md` (the Write tool): the head; per question an
answer with its evidence; findings numbered with severity (high: a file skipped, lost, stuck for good, downloaded
from a source not chosen, or downloads stalled; medium: a wrong count, a bound passed, a leak, a rule of the
owner's bent; low: the rest), confirmed or plausible, the smallest fix; what you did not look at; one closing
line: "may be listed", "may be listed after these fixes: n, m", or "not yet". Your last message: that line and the
findings' titles with severities.
