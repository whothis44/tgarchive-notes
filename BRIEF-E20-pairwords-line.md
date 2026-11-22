# Brief E20 (merge entry "C14"): the collector's line that starts the reader of the owner's words (copies, session C5, 11-16)

**For an Opus 5.5 coder at high effort. It is a small piece: it wires existing parts and adds no rule. You write
code and run only the named tests of what you changed; whole packages, vet over packages, the race detector and
the merge of the head are done once, later, by a clerk of the main session. Usage is nearly spent: read only what
section 1 names.**

- Copy: make it first, from the Bash tool:
  `git -C /c/Users/trabi/Claude/Projects/Telegram/repo-archiver worktree add -b wip/copies-20 /c/Users/trabi/Claude/Projects/Telegram/wt-copies-20 bae71e5c`
  (the main head; if the branch or the folder exists already, stop and say so). Work only in that copy. Go:
  `. /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh` in the Bash tool, then the copy's `archiver`.
- Commit as you go: `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, the message ending with
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; `git push private wip/copies-20` after each commit.
  Never another branch; never merge; never tag.
- Invented data only. Nothing runs against Telegram. No log line, test, comment or report carries a real name,
  text, path, id or link; new log calls have constant format strings and print counts and fixed words only (a
  folder's path is never logged, also not in a refusal).
- Nothing in product code depends on this PC's absolute paths, the start folder, PATH or the start scripts.
- A text with a Windows path is written with the Write or Edit tool, never through a shell string.
- `collector.go` and `command.go` are Core's files, lent for this piece (the board's message 125): the fewest
  lines there, everything else in a new file of ours. Core's K14 adds test-only fields to `Config` at the same
  time: add yours as one block of their own. You touch no other Core file (`staging.go`, `account.go`,
  `words.go`: none), nothing in `internal/store`, `internal/engine`, `internal/catalog`, `internal/supply`,
  `internal/viewer` (read it, edit nothing), the pages or the mirror.

## 0. What the old app already knows, and what is decided
`BRIEF-E19-owner-verdicts.md` section 0 holds it (read it: 20 lines). Nothing new for this piece but this: the
old app never acted on the owner's word at all; the new app's catalogue does since C13 (merged, bae71e5: schema
step 24), and nothing starts its reader. The owner's decision (item 21, 11-15 20:37): "same" keeps the file held,
"not the same" ends the hold against that one file; **a word never skips a file.** All of that is built and
reviewed in `internal/catalog` (`pairword.go`) and `internal/pairwords`. **This piece decides nothing about what
is held or wanted: it starts the reader and shows its counts.**

## 1. Read first (in the copy; no more than this)
- `internal/pairwords/pairwords.go`: the package comment, `Config`, `New`, `Run`, `safeTurn`; `stats.go`
  (`Stats`, `Report`).
- `internal/collector/framecheck.go`: `partsDirOf`, `pathWithin`, `partsDirResolved`, `foldersOverlap` (the folder
  rules to reuse), `startFrameCheck`, `frameCheckTasks`, `logFrameCheckHour`, `addFrameCheckFlags`, `check`,
  `apply`, `ignored` (the pattern to follow: a group of flags, off by default, a task on the store's context).
- In `collector.go` only the places C12 touched: `Config`'s frame check block, and in `Run` the calls
  `startFrameCheck` (about line 723), the tasks on the store's context (about 813 to 815) and the stop's order
  (about 878). In `command.go` the lines about `ff` (about 516, 555, 652), the help and the exit switch.
- The tests C12 wrote for "off is as today" and for the folder refusals in `framecheck_test.go`: take their rig
  and their way, do not write a new one.

## 2. What to build

### 2.1 Two flags of `run`
- `-pair-words <folder>`: the viewer's data folder. Empty (the default): off. The reader's `Path` is
  `decisions.sqlite` in it (put the name as one exported constant into `internal/pairwords`, with a comment
  naming the viewer's file it mirrors; the collector never imports the viewer: the wall test stays green).
- `-pair-words-work <folder>`: the reader's own work folder (its private copy of the viewer's file while the
  viewer is closed). Default when `-pair-words` is set: a folder `pairwords-work` beside the catalogue file (the
  absolute folder of `Config.CatalogPath`).
- Given through one helper as the frame check's are (`addPairWordsFlags`, `check`, `apply`), in the new file.
  `-pair-words-work` given while `-pair-words` is empty changes nothing and is counted with the ignored flags
  (the start's one line; never its value).

### 2.2 The folders' rules (refusals in fixed words, before anything is made; an exit as `-parts-dir`'s refusal)
- Both folders absolute, else refused (never against the start folder).
- **The viewer's folder is never written to, made or listed by the collector.** It is not made when missing and
  a missing folder or file does not refuse the start (the reader says "no decisions file yet" and looks again;
  the folder may be on a disk that is away).
- The viewer's folder may not be the staging folder, the library folder or the part store's folder, nor inside
  one of them (the reader looks at the file every 30 s: nothing in the background reads the library).
- The work folder may not be the viewer's folder, the staging folder, the library folder or the part store's
  folder, nor inside one of them, nor hold one of them. (The default can break this rule when the viewer's data
  folder is the catalogue's own: then the start is refused with words that say to name `-pair-words-work`.)
- By names first (`pathWithin`), then once on the folders as the system sees them, bounded as
  `partsDirResolved` is (2 s; when they do not answer the names decide and it is counted): reuse that code, do
  not write a second walk. If `foldersOverlap` cannot answer "is or is inside" alone without a rewrite, say so
  in the report and take the smallest change in our own file.
- The work folder is made by the reader itself (`0o700`); the collector makes nothing else.

### 2.3 The task
- `pairwords.New(Config{Catalog: cat, Path, WorkDir, Clock, Logf, Every})` once at the start, at the place the
  frame check is set up; `Run` as one supervised task on the store's context beside the writer, the copier and
  the frame check's tasks (name it "pair-words"): it stops after every engine has returned and before the Supply
  and the catalogue close. `Run` returns within 5 s of its context's end by its own contract: add no second wait.
- The reader's clock from the collector's clock (a small adapter; in tests the rig's scaled clock: a test that
  waits on the rig's clock takes its bound from `testScale`). `Every`: the reader's default; one unexported
  test-only field in `Config` may shorten it.
- `Logf`: the collector's log with the prefix the other lines have; the reader's formats are constant already.
- One line at the start when it is on (fixed words, no path), and the reader's `Stats().Report()` lines in the
  hourly lines. **`staging.go` is not ours: call your hourly function from the first line of
  `logFrameCheckHour` (our file), before its `if fc == nil`,** and keep the reader where the hourly code can
  reach it without a data race (one field on the collector, set before the tasks start).
- With `-pair-words` empty: no reader is made, no task started, no folder looked at or made, no line logged, no
  count changed. **A run is the main head's, and a test keeps it so.**

### 2.4 What is NOT in this piece
No kick of the Supply, no new door, no change to what a word does, no change in `internal/pairwords` but the one
constant (and, if a collector test needs the viewer's table made, ONE exported name for the table's SQL instead
of a third copy of the text). No setting row, no page, nothing in the launcher. `safeTurn`'s recover stays as it
is: **Core's K16 (`Catalog.Batch` rolls back on a panic) is not on this head; do not work around it; write in the
report what a panic inside `ApplyPairWords` would leave open on this tree, from the code, in three lines.**

## 3. Tests (new file `internal/collector/pairwordsline_test.go`; every name starts with `TestPairWords`; invented data)
1. `TestPairWordsOffIsToday`: the flag empty: no task of that name, no folder made, no line, the hourly lines
   as the head's; `-pair-words-work` alone is counted as ignored and changes nothing.
2. `TestPairWordsFolders`: a table of the refusals of 2.2 (relative; each overlap by names; one by a link or a
   second name of the same folder through the `folderLook` stand-in; the default work folder; the default
   refused when the viewer's folder is the catalogue's own), each with its fixed words and no path in them.
3. `TestPairWordsRunApplies`: a run with the flag on a decisions file made by the viewer's own table text: a
   word reaches the catalogue (`PairWords`); **the viewer's folder holds the same file names and the same bytes
   after the run as before, in both states** (journal files there: the viewer open; not there: the viewer
   closed, read through the private copy); the hourly lines carry the reader's counts; after the stop the work
   folder holds no copy.
4. `TestPairWordsUnreadable`: a missing folder, a missing file, a file that is not a database, a database with
   no `verdict` table: the start is not refused, nothing reaches the catalogue, the failure is counted where the
   reader counts it, the run goes on and stops cleanly.
5. `TestPairWordsStops`: a stop while a turn is under way returns inside the stop's own bound; the task is not
   restarted after the stop.
For each test, say in the report what change in the code makes it fail (seen failing once, by hand).
Run while working: `go test ./internal/collector -run 'TestPairWords' -count=1` and the C12 tests whose helpers
you changed, by name; `go build ./...`; `gofmt -l` on your files. **Not** the whole collector (20 minutes), not
the race detector, not vet over packages.

## 4. Bounds
| What | Bound |
|---|---|
| The start's look at the folders as the system sees them | 2 s, then the names decide (counted) |
| The reader (turn, read, chunk, pause after a failure) | its own, unchanged (`internal/pairwords`' constants) |
| The task after the store's context ends | 5 s (the reader's contract) |
| New timers, waits or retries of this piece | none |

## 5. Hand-back
A report `archiver/docs/progress/copies-pairwords-line-REPORT.md` kept as you go: what was built per point; every
file touched, and for `collector.go` and `command.go` the added and removed line counts and each place by name;
**what a run with the flag empty does that the head's does not (expected: nothing; if anything, each thing by
name)**; test functions removed (none expected: "none" or the list); each named test and what breaks it; what
the launcher would have to pass (two flags, for the pages track); the three lines on a panic and K16; what you
could not verify; every doubt, **above all about a rule of this brief that looks wrong to you** (say so plainly
rather than build a rule you think is wrong; if a rule would let a file be skipped or lost, or the viewer's
folder be written to, do not build it and say why). Everything committed and pushed on `wip/copies-20`; the copy
clean. Your last message: the head's short hash, the tests run with their seconds, the doubts in a few lines.
