# Brief G19b: the review's fixes for G19, changing the folders (pages, P6, 11-16)

**NOT STARTED when written (19:57): the hour's usage goes to the shell (W1) and to Quit (G18) first;
whoever has the track next starts this with one fresh Opus coder.** Work only in the copy
`C:\Users\trabi\Claude\Projects\Telegram\wt-pages-folders`, branch `wip/pages-folders` (head a281c273,
pushed, clean). Read first, whole: `BRIEF-G19-change-folders.md` (its rules bind this round), the
coder's report `archiver/docs/progress/pages-folders-REPORT.md` on the branch, and the independent
review `REVIEW-G19-change-folders.md` in the project folder (its finding numbers are used here; its
probes are in `wt-pages-review-g19-scratch`: take them over as tests). ONE round.

## 0. First: take the head and G18 in
Merge the main head (at least f1d7127b; `git fetch private`, by its hash) into the branch. **If G18
(`wip/pages-quit`) is merged into the main head by then, that merge brings it and its conflict with
this branch in the launcher (`launcher.go`'s run loop, `start.go`'s `collectorArgs`, `words.go`) is
yours to resolve: keep BOTH pieces' behaviour (G18: the window's ends, the close box, the `/viewer`
route, the viewer started only from there; this piece: the setup's look and "Change the folders");
run both pieces' named tests after it.** If G18 is not merged yet, say so in the hand-back: the one
listed second takes the other in.

## To fix (all; each with the test that fails without it)
1. **Finding 1 (MUST): the second yes belongs to what the owner was SHOWN, not to the path alone.** A
   yes carries what the look had seen when it was given (empty / N things / cannot be looked at now).
   The save looks again: when it now sees something the owner was not shown (the yes was given on
   "cannot be looked at now" or on a smaller count, and the folder is now seen not empty or fuller),
   the save is refused, nothing is written, and the page shows what is seen now and asks again. A yes
   given on "cannot be looked at now" counts only while the save's look also cannot look. The
   reviewer's probe `TestReviewG19YesFromNoAnswer` becomes a test.
2. **Finding 2 (tests):** nesting refused BOTH ways (a test for each direction and for "the same
   folder"); the write check never runs before the look, the nesting check and the yes (a test that
   fails when it is moved up: for example the check's temporary file must not appear in a folder whose
   save was refused).
3. **Finding 3: folders saved by an earlier build were never looked at.** The settings file records
   that each folder was taken with the owner's eyes on it (one field per folder, written at a save of
   this build). A start with saved settings that lack it looks at the library and the staging folder
   first (the same bounded look): empty, or the staging folder carrying the collector's mark: the
   field is written and the start goes on; otherwise NOTHING is started and the launcher's page says
   what it sees ("The library folder saved earlier is not empty: N things ..."), with "Use it as it
   is" (the second yes, recorded) and "Change the folders". "Cancel" on the change's setup goes back
   under the same rule: it never starts against a folder this page has just said needs the yes.
4. **Finding 4: the data folder.** Not empty and holding no catalogue: the same second yes ("N things
   are in it, none of them an archive of this app"); a data folder that gives no answer is not made
   and not write-checked without a bound: "cannot be looked at now", and the second yes.
5. **Finding 5: "Change the folders" only when nothing of this folder can still run.** Not offered on
   a refusal where something may run (the review names them: the marker unreadable, a collector of an
   earlier watchdog); there the page keeps what it offers today ("Stop what is left"), and "Change the
   folders" appears once nothing runs. Before the setup is shown after a stop, the launcher makes the
   same check a start makes (the marker, a watchdog, a collector of this folder); a NEW data folder
   does not skip it for the OLD one.
6. **Finding 6: the "Stopping" view.** After 10 seconds without the end it says so and gives the way
   on: a link to the app's pages while they answer (a stop held for a sign-in's code is answered
   there: the code, or "Quit now") and "Stop it now" as the launcher has it elsewhere, if it has.
7. Minor, all: "1 thing" (no "1 things"); no yes box under a folder that is already refused; the
   staging sentence says the copier's limit too (read it in Core's code and quote the number from
   there: the reviewer read "20 re-downloads an hour, then held for the owner"); the owner's steps
   file gains the reviewer's three lines (the VPN adapter comes back preselected as the default; the
   Windscribe entry stays valid; the sign-in is kept because the data folder is the same).

## Then
- Look at the setup page at a narrow width too (the reviewer could not: Edge headless drew wider than
  the window; try `--window-size=390,844` with `--force-device-scale-factor=1`, or say that it could
  not be done) and at the app's Settings region "This program" and the header's "Program" link in a
  browser engine on the server's fixture with the flag set.
- Named tests only, through the lock script
  (`bash /c/Users/trabi/Claude/Projects/Telegram/runs-pages-p6/go1.sh /c/Users/trabi/Claude/Projects/Telegram/wt-pages-folders/archiver <command...>`),
  nothing over two minutes a command, no whole package, no race detector. The owner's real app, its
  folder and its ports are never touched; Windows profile folders redirected for every process you
  start; invented entries only; never a name of an entry in a page, a log or a test's output.
- No test function removed or renamed. Commit as you go (`git -c user.name=Claude -c
  user.email=noreply@anthropic.com commit`, the last line
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`), push `private wip/pages-folders` only.

## Hand back (at most 12 lines)
The pushed head and what it holds (the main head; G18 or not); each finding: done with its test's
name, or left and why; what you saw of the pages at both widths; test functions added and removed; the
named tests run; what is NOT verified. A section "The second round" in the report on the branch.

## After it (the track's session)
Read the round (finding 1's path and finding 3's start rule); no second review pass unless it rebuilt
more than this names; the full runs once:
`bash runs-pages-p6/run-listing.sh wt-pages-folders wip/pages-folders g19 "internal/launcher internal/server cmd/tgarchive-open" "internal/collector=LauncherURL|PagesRun|Pages"`
(set nothing else; about 12 minutes; no race detector unless the round changed code that runs
concurrently: the look's goroutine is the one place: if it changed, the launcher's tests by name under
the detector in a container, said on the row first); then the entry "G19".
