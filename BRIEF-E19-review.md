# Brief: the independent review of E19, the owner's word on a probable pair (copies, session C4, 11-16)

**For an Opus 5.5 reviewer at high effort. You did not write this code and you are not told what its author
concluded beyond the deviations listed below. Find what is wrong with it; a review that finds nothing must say
what it tried.**

## What you review
Branch `wip/copies-19` in `C:\Users\trabi\Claude\Projects\Telegram\wt-copies-19`, head 4bb0ba2c, against dbca91d4
(`git diff dbca91d4..4bb0ba2c`). Its brief: `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-E19-owner-verdicts.md`:
**read it in full and review its rules as hard as the code** (in this track's last pieces the brief's own rules
were the commonest defects). The coder's report is `archiver/docs/progress/copies-pairword-REPORT.md` on the
branch: read it after your own read of the difference.

The piece: the owner's "same" or "not the same" on a probable pair (recorded by the viewer in its own
`decisions.sqlite`) acts on a held copy in the catalogue, per pair (`internal/catalog`: a schema step, the door in
`pairword.go`, seeks in rung 6, the step at a save, the frame check's candidates, the exact check); a held copy
whose saved look-alike is lost is judged again (one call in `WantAgain`); a reader (`internal/pairwords`) applies
the viewer's table. Nothing starts the reader yet.

The owner's rules that bind it:
- **Only exact evidence (the same Telegram file, the same SHA-256, every part hash) may skip a file.** No path of
  this piece may set a file to skipped or gone. "Same" never skips. A probable copy is held, never skipped.
- **Never download from a source the owner did not choose**: a file whose chat, kind or topic is not collected, or
  that is carried only as an alternative version, must not become wanted by a word.
- A claim or a finish must never fail because something holds the catalogue's single writer for seconds: long
  writes are chunked (`TRIED-BEFORE.md` section 21: one failed statement once cancelled every download).
- Nothing in the background reads the library folder. Every wait has a bound.
- Logs, tests and reports: counts, sizes, timings and fixed words only; never a path, name, id, link or an error
  text that may hold one.

## How you work
- **Read-only on the branch.** Never commit, push, merge, stash or edit in `wt-copies-19`. For probes: from
  `C:\Users\trabi\Claude\Projects\Telegram\repo-archiver` run `git worktree add --detach
  ../wt-copies-review19-scratch 4bb0ba2c`; probe tests there (`zz_probe_*_test.go`), never committed; leave the
  copy as it is and say what is in it.
- Go: `. /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`, then the copy's `archiver`.
- Named tests only (`-run`, `-count=1`); never the whole `internal/catalog`; no `go vet` over packages; no race
  detector. Before a run: with less than 2 GB of memory free or the CPU above 80% over a few seconds, wait a minute
  and look again, at most 10 times; then run with `GOMAXPROCS=2`.
- Invented data only. Never open the owner's folders, catalogue, decisions file or media.
- A finding is confirmed only with a probe that fails or a trace written out line by line; otherwise "plausible,
  not probed".

## What the coder changed against the brief (judge each)
1. The reader does not open the viewer's file while its `-wal` and `-shm` files are absent (it measured that a
   `mode=ro` open of a WAL-mode file creates both): a word given just before the viewer closes waits for the
   viewer's next session.
2. A file in transfer or set aside that loses its edge keeps its state but loses `probable` and `check_first`
   (an active file's reason too).
3. "different" changed to "same" first takes the "different" back (the released file may be held again).
4. The check-first mark is set only when rung 6 still finds a look-alike and a saved file of its size exists.
5. `internal/probejudge` was changed (three lines): it calls a new `VideoCandidatesOf`.
6. Left as gaps: a file judged again goes through rung 6 only (not rung 4); the bring-in's paths are not guarded;
   a rung 7 (SHA-256) duplicate of a "different" pair is not counted as a contradiction; an emptied or missing
   verdict table takes back every word.

## The questions (answer each; add your own)

1. **Can a word make wanted a file the owner did not choose?** `pairEdgeLost` releases a file that is `held`
   with `probable = 1` (and settles a wanted file marked for the exact check first) through `pairRejudge`, which
   runs rung 6 and otherwise writes `state = 'wanted'`. `WantAgain`'s own decision for a media asks more: carried
   only as an alternative, a kind no chat collects, a topic not chosen, a known list. Is "held and probable" a
   proof that the file is collected at this moment, in every path that writes those columns (`chosen.go`
   `chatHoldSQL` takes `probable` off when no carrier collects it; the topic rule; an edit that changes a role; a
   chat switched off while the file is in transfer; the bring-in)? Probe each: a chat switched off, a topic not
   chosen, an alternative version, then the word, then the state. The same for `ClearPairWord` and for
   `lostLookAlike`.
2. **No skip, no loss.** Trace every `UPDATE c_want`, every `DELETE` and every changed line of `exactcheck.go`,
   `ladder.go`, `atsave.go`, `probe.go`, `vfp.go`: can any path of this piece end a file as skipped or gone, or
   leave it held for good with no edge and no way out, or wanted and held in turns (a loop between the door and
   another rule)? A full exact match after "different" must still skip (exact outweighs the word) and be counted.
3. **Nothing changes for a pair without a word.** With `c_pair_word` empty, are rung 6, the stills rule (it now
   reads its rows in full first), the step at a save, `HoldLookAlike`, `HoldExact`, `LinkSame`, the frame check's
   candidates and its "copy" exactly as on the base, in result and in cost? What does each added read cost per
   new attachment while the table is empty and while it holds 10,000 words (the plans; one measured figure:
   attachments catalogued a second on the base and on the branch, by a named test or a probe of yours)? Does any
   new read run on the catalogue's read handle of a file older than the step (the viewer opens catalogues
   read-only)?
4. **The writer's time.** One `SetPairWord`, one chunk of the reader (500 pairs), and `WantAgain` of a saved file
   with 10, 1,000 and 5,000 look-alikes held against it: how long is the writer held (measure on invented rows)?
   Where is a bound needed, and what is the smallest one (a cap per transaction with the rest left for a later
   turn, counted)?
5. **The words' order and repeats.** "different" then "same" then taken back; "same" then "different"; the same
   word twice; a word on a pair where one file is saved, both are saved, both are queued; two words that share a
   file (A-B different, A-C same); a word on a pair with edges both ways; a pair one of whose media is deleted
   afterwards (the cascade). Is `applied_at` or any other time taken from the wall clock where the catalogue's
   other doors take a given time?
6. **The step.** Its form against the other steps' (`schema_mirrorwant.go`): refuses a file at another version,
   leaves a relabelled file right, the three places in `catalog.go`; `STRICT` or `CHECK` as the house does; the
   index by `b`; the foreign keys with the catalogue's deletes of `tg_media` rows (do any exist?).
7. **The reader, `internal/pairwords`.** Is deviation 1 true (probe: a `mode=ro` open of a WAL-mode file with no
   journal files beside it; with `immutable=1`; of a private copy)? **Name the smallest safe way to read a file
   the viewer has closed without creating anything in the viewer's folder** (I intend to have one built: a word
   must not wait for the viewer's next session). A missing `verdict` table in an existing file: is it taken as
   "no words" (and every word taken back)? It should be a failure. An emptied table after 500 words. `PRAGMA
   data_version`: is it read on the same kept connection each time, and what if the file is replaced under that
   connection (a restore): is the stale handle ever noticed? The cap of 100,000 rows; memory at that size; the
   absent pairs' turns; the pause after failures; `Run` ending within 5 s inside a chunk, inside a busy wait, and
   called again after a panic; a panic in a turn (does it end the program?). Does it ever write, or create a
   file, in the viewer's folder (probe with a listing before and after, the viewer's file open and closed)?
8. **`WantAgain`'s one line** (the last commit): the order inside the transaction (the file marked lost before
   the look-alikes are judged again, so that rung 6 passes over it); `WantAgain`'s own media with an edge to
   another saved file; a lost file revived later (do the removed edges come back by rung 6 at the next covering
   save?); the commit dropped: does everything else still build and pass?
9. **The judge's three lines.** With no word on record is `VideoCandidatesOf` the same list in the same order as
   `VideoCandidates` (a probe comparing both on invented fingerprints)? Run `internal/probejudge` whole with
   `FFMPEG_PATH` set (the second line of `where.exe ffmpeg`) in your scratch copy.
10. **Words and privacy.** Errors such as "the pair %d, %d" carry catalogue row numbers: can any reach a log, a
    page or an exit message (the reader's `Logf`, its `Report()`)? Every new log line and count key: constant
    formats, fixed words.
11. **The gaps of deviation 6.** For each: can it lose or skip a file, download from a source not chosen, or
    only miss a hold or a count? Which must be closed before listing?
12. **The tests.** Break three rules of your choice in the scratch copy and say what failed. Which rule of the
    brief has no test? Was any existing test changed in what it asserts (`git diff` of `_test.go` files that are
    not new)?
13. **The brief.** Which of its rules is wrong, risky or unbounded in your judgement, whether or not the code
    follows it?

## What you hand back
`C:\Users\trabi\Claude\Projects\Telegram\REVIEW-E19-owner-verdicts.md` (the Write tool): the head reviewed; per
question an answer with its evidence (file and line, or the probe's name and result); the findings numbered, each
with a severity (high: a file can be skipped, lost, stuck for good, downloaded from a source not chosen, or
downloads can stall; medium: a wrong count, a bound passed, a leak, a rule of the owner's bent; low: the rest),
confirmed or plausible, and the smallest fix you would accept; what you did not look at; one closing line: "may be
listed", "may be listed after these fixes: n, m", or "not yet". Your last message: that line and the findings'
titles with their severities, in a few lines.
