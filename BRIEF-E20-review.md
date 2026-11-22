# Brief E20, the independent review: the collector's line that starts the reader of the owner's words (copies, session C5, 11-16)

**For an Opus 5.5 reviewer at high effort who has not seen the coder's work. One pass. Usage is nearly spent:
read the difference and what it calls, not the repository.**

- The piece: branch `wip/copies-20` in the copy `C:\Users\trabi\Claude\Projects\Telegram\wt-copies-20`, against
  the main head it was cut from (bae71e5c): `git -C <copy> diff bae71e5c HEAD`. Its brief:
  `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-E20-pairwords-line.md`; the coder's report:
  `archiver/docs/progress/copies-pairwords-line-REPORT.md` on the branch (read it last, after your own read of
  the difference: it is a claim, not evidence).
- **You change nothing in that copy.** Probes go into a scratch copy you make yourself:
  `git -C /c/Users/trabi/Claude/Projects/Telegram/repo-archiver worktree add --detach /c/Users/trabi/Claude/Projects/Telegram/wt-copies-review20-scratch <the branch's head>`
  as untracked files named `zz_probe_*_test.go`; leave them there, uncommitted. Go:
  `. /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`, then the scratch copy's `archiver`. Run
  only named tests (`-run`, `-count=1`, `GOMAXPROCS=4`, one `go test` at a time); never the whole collector, no
  race detector, no vet over packages.
- Invented data only; nothing runs against Telegram; never open anything under `E:\T`, a real catalogue or the
  owner's viewer folder. A text with a Windows path is written with the Write tool, never through a shell string.

## What the piece must be (the rules; a break of one is a finding of the highest rank)
1. **With `-pair-words` empty a run is the main head's**: no reader made, no task, no folder looked at or made,
   no line, no count changed, no flag's meaning changed. Trace every changed line of `collector.go` and
   `command.go` with the flag empty, and every line the new file runs at a start.
2. **The viewer's folder is never written to, made or listed by the collector**, in every state: the folder
   missing; the file missing; the viewer open (journal files there); the viewer closed (read through a private
   copy in the work folder); the file replaced or cut short while it is read; a start refused; a stop in the
   middle of a read; a kill (what does the next start find and do?). The work folder is never the viewer's
   folder, the staging folder, the library or the part store, nor inside one, nor holding one; the viewer's
   folder is never the staging folder, the library or the part store nor inside one. Also by a link, a junction
   or a second spelling of one folder; and when the folders do not answer in time.
3. **A missing or unreadable verdict table sends nothing and applies nothing**: no word reaches the catalogue, no
   word is taken back, no file changes its state, the run goes on, the failure is counted where the hourly
   lines show it.
4. **The piece adds no rule**: nothing in it decides what is held, wanted, skipped or gone; no path sets a file
   to skipped; no kick, no door, no new write to the catalogue but through `pairwords`' three calls.
5. **Stop and restart:** the task ends inside its bound after the store's context ends and before the Supply and
   the catalogue close; it is not started again after the stop; a restart by the supervisor after a panic
   starts clean. **A panic raised inside `ApplyPairWords`' transaction:** on this tree Core's fix (K16:
   `Catalog.Batch` rolls back on a panic) may not be there: say from the code and, if cheap, by one probe what
   the writer is left in when the reader's `safeTurn` recovers it, and whether this piece makes that worse than
   the head (where nothing starts the reader).
6. **Privacy of the logs:** no path, name or key in any new log line or refusal; constant format strings.
7. Nothing depends on this PC's paths, the start folder or PATH; nothing in the background reads the library.

## Probes to write (each a small test that would fail if the rule were broken; say which you ran and its result)
- The flag off: a run's tasks, lines and folders beside the head's (rule 1).
- The viewer's folder's names and bytes before and after a run, for each state of rule 2 you can make cheaply;
  one link or second-name case through the folder look's stand-in.
- No table, not a database, a missing file, a missing folder: the catalogue's words before and after (rule 3).
- One of your own choosing, where your read of the difference made you least sure.

## What to hand back
A file `C:\Users\trabi\Claude\Projects\Telegram\REVIEW-E20-pairwords-line.md` (write it with the Write tool):
the head you read; findings numbered, each with its rank (high: a rule above broken, or a file could be skipped,
lost or wrongly released, or the viewer's folder written; medium; low), the lines, what happens, the smallest
fix, and whether a probe shows it; what you did not look at; then one last line, exactly one of: "may be
listed", "may be listed after these fixes: <numbers>", "not yet". Your last message: that last line, the count of
findings by rank, the probes run with their results, in a few lines.
