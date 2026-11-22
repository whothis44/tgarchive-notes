# Start file for the next copies session (C6), written by C5, 11-16 15:47

**How it is started (the owner, in the desktop app, a new session in this folder):** paste
"Read `START-COPIES-C6.md` and do what it says."

You are the new COPIES session of the owner's standalone archiver: call yourself C6. The session before you (C5)
handed over at 15:41 on 11-16 with its context long after four landed pieces; it is retired once you have written
on the board's Copies row. The owner, to C5 at 15:45: "Fresh one. Please start it" (C5 could not start a session
itself: the owner was on Remote Control). Earlier that afternoon the owner said "Build as needed" and "Not the
first run yet, trying to build features". No usage hold stands (the owner, 13:47: "Usage reset. Go as needed");
the PC's memory is the limit.

**Read `BOARD.md`, take over the copies track from its progress file, and carry on.**

## Two rules before anything else
1. **Routine steps go to ONE Sonnet clerk call or a script, never call by call in your own context** (named
   tests, gofmt, vet, a build, full runs and their "exit N" lines, a clean merge of the head, a commit with your
   message, a push of a `wip` branch, measuring the PC, drafting an entry from your notes). The track's patterns
   are on disk: the clerks' step files `CLERK-C14-finish.md` to `CLERK-C17-finish.md` (numbered steps, the
   expected output of each, "stop and report"), and `ix-tools/copies-runs.sh` for whole packages and named race
   runs. Every progress entry that reports routine steps says "by a Sonnet clerk" or why not.
2. **The PC's memory is the limit, not usage.** One go command at a time for the whole track: every agent of
   yours takes the lock folder `runs-copies-golock` (`mkdir` to take, `rmdir` to give back; older than 30
   minutes: may be removed) around each go command, with `GOMAXPROCS=2 GOMEMLIMIT=1GiB GOFLAGS=-p=1`. The owner
   lowered this track's bar on 11-16 14:33: go commands run from 1.2 GB free (measure before each; under it wait
   2 minutes and look again, bounded). Never pin the CPU; above 80% wait before starting a coder or a run.

## Read first, yourself, in this order
1. `CLAUDE.md`, the archiver section.
2. `BOARD.md`: the direction (the first 90 lines), the Copies row, the integrator's row (it names the main
   head: cut every new piece from the head it names), the copies lines of "Listed and unbuilt", the messages
   from 127 on that name copies (127, 131, 132, 133, 134 and any newer), and the owner's waiting list items 37
   and 38. Older messages are in `BOARD-LOG.md`: do not read them.
3. The newest block "STATE FOR A TAKE-OVER (session C5, 11-16 15:41" at the end of
   `SESSION-COPIES-PROGRESS.md`, with its lessons. Carry on writing in that file under a heading "SESSION C6".
4. The entries "C15", "C17" and "C16" at the end of `MERGE-QUEUE.md` (what is listed and what each leaves open).

## What stands (check each against the disk before acting)
**(Brought up to date by C5 at 18:20 on 11-16: C5 carried on after this file was first written.)** C12 to C18
are merged (C15 the read-only count `archiver/tools/probe-misses`; C16 the copy checks' switches as stored
settings; C17 a settled frame-check row is final; C18 small things in the frame check's start). Two pieces are
LISTED, READY and wait for the integrator: C19 `wip/copies-24` 761b88d6 (a schema step, 27 by the integrator's
order: a removed copy edge is logged as a kind of its own; the viewer's own entry follows it) and C20
`wip/copies-26` 7f8ad072 (the judge recovers a panic of the catalogue's or the part store's own code inside a
door call; a driver's panic is still raised again). Core has a session again (K-5) and has taken the finding of
C20's review as K19. Nothing of the track runs; every branch is pushed and every copy clean; the track's
finished copies are removed (left: `wt-copies-17`, `-24`, `-26` and two reviews' scratch copies). If the integrator asks for a change in one of them, or the head moves under one, the take-over block says
how (a fresh Opus coder from the branch, its brief, report and review; a Sonnet clerk on the piece's step file).

## The pieces, in this order (none is briefed)
1. **"C21", small, start with it:** `parts.Store.Kept` (`internal/parts`, this track's) recovers every panic,
   one raised inside `database/sql` among them, which leaves a reader or the writer's connection held
   (`REVIEW-E26-judge-recovers-doors.md`, finding 3): such a panic is raised again there too, as the judge does
   it (C20's `sqlPanicked`). Ask Core (K-5) first where K19 stands (the board's messages 151 and 153): if K19
   makes a driver's panic an ordinary error, this piece and the judge's last mark are both moot.
2. (Done by C5 as C18 and C20: the small things in the frame check's start, and the judge's exception.)
3. **Depth, the part the owner values most ("the advanced deduplication, media checks, reuse of downloaded
   data"): lesser copies behind the best; the whole-album rule (off, counting); fingerprints for videos already
   in the library.** Before ANY brief for these: read the history yourself, in full, never through an agent's
   summary: in `repo-archiver/archiver/docs`: `TRIED-BEFORE.md` sections 6, 17, 21, 27; `COPY-CHECKS-STUDY.md`
   section E; `LESSONS.md`; in this folder `ANSWERS-for-archiver-4.md`, `-5.md`, `-8.md`; then the old app's own
   code for the same thing (`wt-v12.31`). Each brief starts with a "what the old app already knows" note with
   the old app's number; default to the old app's way where it worked. Rules that bind every one: only exact
   evidence may skip a file; a probable copy is held, never skipped; a frame check's "no match" never releases a
   file by itself; nothing in the background reads the library on the NAS while copies wait; the download path
   (`lane.go`, `state.go`) is not changed without a number on record that says it pays.
4. Only if the owner asks: a live switch for the two copy checks (C16's report says what it needs); the reader
   of the owner's words on private copies only (the owner's item 38).

## Per piece, the fixed order
Your brief (a file in this folder); ONE Opus 5.5 coder at high effort in a new copy `wt-copies-NN` on
`wip/copies-NN` cut from the main head; your own read of the risky part; ONE independent Opus review with
probes; its fixes (a fresh small coder with an exact list is cheaper than continuing a coder with a large
context); then the full runs ONCE by one Sonnet clerk (say the plan in one line on your row first: which
packages whole, which under the race detector and why, about how many minutes; the race detector only where
concurrent code changed, by test name where it can be); then an entry in `MERGE-QUEUE.md` that lists the files
it touches and the test functions it removes, with "listed" or "READY" in the subject of the notes commit. While
working, agents run named tests only. Files of another track are borrowed only by a line under the board's
"Messages" first.

## When the owner has run item 37
(The frame check's first real run on the test account; `PLAN-C12-first-real-run-frame-check.md`.) Read the
collector's hourly lines beside the plan's table and run the count read-only as the take-over block says;
counts only.

## Reporting
To the integrator only, through your board row (change only your own row; put "session C6, taken over <time>"
at its front), your progress file after every step that changes the state, and the board's "Messages" for other
tracks; commit the notes on the `notes` branch each time
(`git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, ending with
`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`). Text with a Windows path never goes through the shell
tool: use the Write or Edit tool; the board's row, a message and a queue entry are cheapest written by one small
script from text files. Times from `date`. Ask the owner directly only when you cannot go on without the answer.

## Done for your first turn
The row with "session C6" at its front; the brief for C18 written to a file in this folder; one Opus coder
started on it (after measuring the PC and reading the integrator's row for the head); your progress file and a
notes commit saying exactly what runs where. Then begin the reading for the depth pieces while the coder works.
