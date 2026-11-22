# Start of an integrator session (one fixed file; replaces the numbered start files for the integrator)

The owner pastes into a new session in this project folder:
"Read `START-INTEGRATOR.md` and do what it says."

You are the integrator: you merge into `claude/charming-feynman-vm2xia`, keep the board and the
documents, review the other sessions' progress for the owner, and build nothing yourself. Every building
session reports to you through `BOARD.md` and `MERGE-QUEUE.md`, not to the owner piece by piece.

## Read first, in this order
1. `CLAUDE.md`, the archiver section.
2. `BOARD.md`, all of it.
3. The newest integrator progress file (`SESSION-11-PROGRESS.md` unless the board names another): its
   last "state for a take-over" block. Carry on writing in that same file.
4. `MERGE-QUEUE.md`, and the first block of section 0c of `repo-archiver/archiver/docs/HANDOFF.md`.

## First, every time you start: review progress and tell the owner (about ten lines, numbers first)
1. For each track on the board: read the end of its progress file (`SESSION-*-PROGRESS.md`) and check
   it against what is really there: `git -C repo-archiver worktree list`, each copy's `git status`, its
   branch against `private`, the main branch against `private`, anything staged and not committed.
2. Say per track: what is merged, what is pushed and waiting, what is uncommitted and where, what is
   stopped (a session's last entry older than its work needs), and what waits for the owner.
3. **Start the tracks yourself, in this first turn (the owner, 11-16 night: "why do I need to start multiple
   commands to resume when usage returns? Can't you simplify that? It can certainly spawn the sessions it
   needs I would think, then detach them").** The line the owner pasted is the only command they give. This
   turn is one the owner began, so the starts are allowed (a start from a turn the owner did not begin can be
   refused: do it now, before the merges). For each track that has work in the board's order and no running
   session: one fresh session (`start_session`, context "fresh"), its prompt the track's own start line (the
   start file its take-over block names, else "Read `BOARD.md`, take over the <track> track from its
   progress file, and carry on"), with two lines on what changed on the head since its block and what comes
   first for it; then detach it (`detach_session`), so that its turn notes do not wake you: it reports
   through the board and the queue. Measure the usage first (six sessions cost about 10% of this model's
   week an hour): start what the board's order needs first, the others when a piece of theirs is next. Say
   to the owner in one line which you started, which not and why. The owner can still say which tracks run.
4. Check that each session is saving as it goes (a progress entry and a notes commit per step). Say
   which is not. **And check that each is using a Sonnet clerk for its routine steps** (`CLAUDE.md`, the
   archiver section's second point: its progress entries say "by a Sonnet clerk" or why not): say which
   track is not, on the board and to the owner. The same holds for you: a merge's mechanical steps are one
   clerk call (see "Learnt on 11-15 night").
5. Write the review's time and result into your progress file and your board row.

## The job, each time a branch is on the queue or the board
1. Read the lessons the board names for that step, and the risky part of the diff, yourself.
2. Tell the owner the full-run plan in one line: which packages get whole tests, which the race
   detector (only where code that runs concurrently changed) and why, and about how many minutes.
3. Apply the branch's own diff to `repo-archiver`'s tree, staged; write in the progress file that it is
   staged and not committed; run `ix-tools/full-runs.sh repo-archiver <out folder> "<packages>" "<race packages>"`
   in the background (about 3 and 5.5 minutes for `internal/viewer`); then `go vet` on the changed packages.
4. All "ok": commit (`git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, ending with
   the co-author line the earlier commits carry), push to `private`. Never tag, never push `main`.
5. Bring up to date: the roadmap's rows, the handoff's one block (rewritten, not added to), the board,
   `MERGE-QUEUE.md`, the progress file; commit the notes on `notes`.
6. Download-path code, and anything that acts for the owner on Telegram, has an independent review and
   its fixes before the full runs. Rebuild the installed collector only when its code changed.

## Practical
- Go: `source ix-tools/env-archiver.sh`; measure memory first, keep about 2 GB free.
- Times from `date`, never from memory. Counts, sizes and timings only; no names, text, paths or ids.
- Nothing runs against Telegram unless the owner starts it.
- A listed feature with no owner gets a roadmap row and an owner track from you the same day.
- Decisions for the owner are collected on the board's "Waiting for the owner" list and asked together.
- Save your own progress after every step: usage can run out in the middle of anything.

## Learnt on 11-15 evening (the integrator session of 16:22 to 19:20)
- **A branch whose tested tree is the tree you merge needs no second full run.** When a branch holds the main
  head and its session ran the full runs on it, apply its diff, compare `git write-tree` (or the package's tree)
  with the branch's, then build, vet and run only the checks that cross packages (the viewer's wall tests,
  `internal/server`). When it does not hold the head, make the combined tree in a copy of your own and run there.
- **A schema step from two branches meets in `catalog.go`** (`SchemaVersion`, the steps' table, one `case` in
  `migrate`): keep both steps, the later number last, and set the later step's "after" constant.
- **Code that decides what is forwarded, skipped or downloaded gets its own independent review after every
  rewrite, and the same reviewer runs its probes again on each fix round** (continue the agent; three passes
  found one older hole after the four it was sent for). Read the report against the code before acting on it.
- **Before telling the owner a script is ready, it is run exactly as the owner runs it** (by its full path, from
  another folder, its own defaults). On 11-15 a start script's default program path held a tab and a backspace;
  "checked" had not gone through it. Every command for the owner works from any folder (board message 39).
- **Installing the collector:** no `tgarchive-collector*` process running; build from the clean main head to
  `...collector.new.exe` in the installed `bin`, copy the current one to `tgarchive-collector-<commit>.exe.bak`,
  move the new one in; check `-h` lists what the merge added. Say on the board what its first `run` will do.
- **The toolchain in `ix-tools` is yours:** it carries one added runtime line (board message 34 b);
  `env-archiver.sh` warns when it is missing; the difference is `ix-tools/goroot-1.27.3-keepalive.diff`.
- **Shared files change under you:** an edit that names another session's wording can fail; re-read the line
  and check your script printed "ok" before writing in the progress file that the board is updated.
- **After a real run by the owner, read the catalogue read-only (counts only) before believing the output,**
  and write the numbers into `TELEGRAM-FACTS.md` the same hour.
- Sessions fill up: `get_usage` on a session id says how full it is.

## Learnt on 11-15 night (the integrator session of 19:47 to about 23:00)
- **Batches: prepare the combined tree in a copy of your own while the runs you wait for go.** `git worktree add
  -b int/<name> ../wt-int-<name> <main head>`, each branch applied as its own difference from its base (`git diff
  --binary <base> <branch> | git apply --index --3way`), tentative commits never pushed; build and vet there;
  when the piece in front is merged, `git rebase --onto <new head> <its tentative commit>`; whole Windows runs
  once on that copy (`ix-tools/full-runs.sh wt-int-<name> runs-int-<name> "<packages>" ""`); then `git diff <main
  head> <batch head> | git apply --index` on the main tree and compare `git write-tree --prefix=archiver/internal/`
  with the batch's. Remove the copy afterwards.
- **A schema step's number is the order of its merge**, so that every installed build has every step up to its
  own. The steps are a chain keyed by "after": at the merge set the later step's "after" constant to the step
  before it and its number to that plus one; look for a test that names the old "after" (`TestSchemaProtected`
  did). Say the numbers on the board the same minute.
- **A race run that must outlive a turn is a detached, named container without `--rm`** (`docker run -d --name
  int-...`, the options of `ix-tools/race-archiver.sh`); read it with `docker logs` and `docker inspect
  --format '{{.State.ExitCode}}'`, then remove it. Watch for its end with the Monitor tool (30 minutes at most:
  re-arm). `internal/server` under the detector needs a 60-minute bound.
- **A run still going on the very head you would merge is waited for**, even when its entry says READY: on
  11-15 that run failed 20 minutes later. A failure in a branch that does not touch the failing code is read
  to its cause before it is called a flake (two of two were faults of the fake Telegram, found that way).
- **A track with no session leaves its runs unread.** After a session wraps up, look at its `runs-*` folder
  yourself and tell the owner the track has no session.
- **Text with a Windows path never goes through the shell tool** (a backslash before a letter arrived as a
  control byte six times in one day, twice from this session): the Write or Edit tool, or `chr(92)` in a
  script. After every scripted edit of the board, count bytes below 32 other than line ends and tabs.
- **Before installing:** count `tgarchive-collector*` and `tgarchive-watchdog*` processes (the owner may have the
  program open: ask the owner to quit, never stop it); keep the build before it as `...-<commit>.exe.bak`.
- **When usage runs low,** say the number, tell every session to finish to its listing and save, write a
  take-over block, and hold new sessions; when the owner says it is reset, lift that on the board.
- **Usage is the limit, more than the PC; and a wake costs the whole context (the owner, 11-15 23:20:
  "internalize [it] as a sensible rule where appropriate").** Measure the week's limits with `get_usage` at
  the start and before proposing a night's work, and say the percentages (never the plan's name: the tool's
  label is wrong). Six sessions cost about 10% of this model's week an hour. Wait for runs, branches and
  notes commits with a background command that ends on the condition, not by turns that poll and not through
  another session. When you take over, message the integrator before you once: it merges nothing more, says
  what is in flight, and detaches the sessions it started so that their turn notes stop waking it.
- **A merge's mechanical steps go to a Sonnet clerk in one instruction (the owner asked on 11-16 01:12 whether
  Sonnet was being used; that night's first eight merges were done call by call in the integrator's own
  context, which is the waste the staffing rule is there to stop).** You read the entry and the risky part,
  say the run plan, and write the commit message; the clerk applies the named difference, compares the named
  trees, starts the named runs and waits for their "exit N" lines, runs vet, build and the named tests, copies
  the review through the scrub script, commits with your message, pushes, and for a collector change builds
  and installs (the process count first); it reports numbers and stops on anything that is not "exit 0".
  You then write the board, the queue and the progress file. **Since 11-16 01:30 those steps are one
  script, `ix-tools/merge-as-tested.sh`** (its head says the ten arguments): edit the roadmap's row in the
  main tree and write the commit message to a file first, then start it as one background command (or
  give that one line to a clerk) and read its last line: "MERGE-AS-TESTED: done <commit>" or "STOPPED at
  <step>". A schema step, a batch of several branches or a conflict is still done by hand.
- **After a merge that changes what `internal/catalog` imports, run `go test ./internal/viewer -run TestWall`**
  on the combined tree (C9's merge broke the viewer's wall test on the main head for half an hour).
- **Review files copied into `docs/review` carry no path of this PC:** replace them by a neutral word with a
  script written by the Write tool, and count what is left.
- **Since 11-16 07:00 a batch is two scripts.** When several listed pieces share no file (compare `git diff
  --name-only <base> <head>` of each, and against what the main head changed since each base):
  `ix-tools/batch-tree.sh <name> "<base:head ...>" "<whole packages>" "<named tests>"` makes the combined tree
  in `wt-int-<name>` and runs the whole Windows tests once (one background command; its last line is
  "BATCH-TREE: ok <tree>"); write each piece's commit message and a pieces file meanwhile; then
  `ix-tools/merge-batch.sh <head> <tree> <pieces file>` makes one commit a piece through
  `merge-as-tested.sh`, pushes each, installs with the last and checks the merged tree against the tested
  one. The roadmap and the handoff go in as one more commit of yours afterwards (the main tree must be clean
  when the batch starts). Three pieces took 30 minutes this way instead of three whole collector runs.
- **Learnt on 11-16 by day (the integrator of 06:55; 15 merges):**
  - **Most merges need no whole run of yours.** Before choosing the runs, ask two things with `git`: is the
    branch's base the main head (`git merge-base HEAD <head>`)? If so the merged tree is the tested one: compare
    the trees (the script's "trees" argument) and run the cheap checks. If not: did the main head change, since
    that base, any file of the piece's packages or of what they import? If not, the same. Only what changed
    beneath a piece is run again (a package whose imports moved; the whole collector when its branch ran it
    before the last merge of the head). Say which case it is in the run plan.
  - **The whole collector takes 22 to 25 minutes on a busy PC: every whole run of it needs `-timeout 45m`**
    (`full-runs.sh` has it; `merge-as-tested.sh` has 30m: raise it when the package grows again). A run cut
    off by go's own limit says "test timed out"; look at how long the one running test had run before calling
    it a hang.
  - **Two schema steps listed close together: the first listed is the lower number, whatever each track
    claimed.** The second is joined by hand in a copy of yours (`git worktree add -b int/<name>`): its
    difference applied three-way, the three places of `catalog.go` resolved "keep both" with `SchemaVersion`
    at the later step, the later step's "after" constant and its own test's comparison set to the earlier
    step's constant, and the EARLIER step's test looked at (it may assert that it is the newest). Then every
    package that opens a catalogue whole, once, on that copy; then the commits there and the main branch
    fast-forwarded to them.
  - **Count the programs running from the owner's folder yourself before each rebuild** (by their path), and
    tell a track's short-lived test stand-ins in a temporary folder from the owner's programs before skipping.
  - **`ix-tools/trim-board-2.py` moves old messages and your row's older states to `BOARD-LOG.md`;** a session
    that takes a track over cuts its own row first (31 KB became 4 KB).
  - **A start of a session from a turn the owner did not begin can be refused:** start a successor in a turn
    the owner began, even if that is a little early, and finish what is in flight while it reads in.
- **Learnt on 11-16 afternoon (the integrator of 14:03):**
  - **Look for waits that cannot end, at the start review.** Two tracks stood still for over an hour with
    nothing failed: a watch that waited for a sentence to LEAVE the integrator's row (the row kept its older
    states: cut your row at the take-over, and wait for a fact such as the main head, never for another
    session's wording), and a listing script that waited 20 minutes for free memory before each of nine steps.
    For each track compare "what it waits for" with the disk; an idle session reads nothing: one short
    message wakes it.
  - **A listing whose full runs would be made again at the merge can be listed without them** (the head
    moved files of its packages): say so to the track and make the runs once on the combined tree.
  - **A piece that conflicts in one "keep both" place** is joined in a copy of yours with a tentative commit
    (`runs-int-i4/join-c14.sh` and `keep-both.py` are the pattern), and `merge-as-tested.sh` is then given
    the main head as base and that commit as head: one command does the rest.
  - **The merge script's checks cover `internal` and `cmd` on Windows only:** after it, the Linux build and
    vet where a piece asks for them, and gofmt and vet of `tools`. The folder: `runs-int-i4/folder.sh`.
  - **Where the memory is:** the Claude app's own processes (13.7 GB in 41 at 14:17) and Windows' kernel
    pools; archiving retired sessions is the lever, at the owner's word.
  - **A merge that changes `internal/catalog` runs the viewer's tests that read the change log, by name, on
    the combined tree** (about 100 s: add `viewer:TestLost|TestStaged|TestIncremental|TestRandomUpdates|TestChanges|TestWall`
    to the merge script's named tests). The wall test alone missed a viewer test that failed on the main head
    for four hours after a merge of the copies track (a removed edge logged as "gone").
  - **A track with no session cannot answer a request for lent lines:** say on your row that you read them
    at the merge in its stead, so that the asking track goes on.
- **Learnt on 11-16 night (the integrator of 19:33; 10 merges at 86 to 98% of the week's usage):**
  - **A watch for listings looks for an unmerged entry's own first line**, with "READY" as well as "LISTED, READY" (the tracks write both), and leaves out by name the entries you hold back: a watch that counted lines missed a listing for ten minutes when marking one entry merged took a line away as a new one came. One background command that ends on the fact; never a turn that polls.
  - **A long run never holds the main tree.** When a piece needs the whole catalogue or the whole collector on a combined tree, make it in a copy (`runs-int-i5/k17-tree.sh` is the pattern: `git worktree add -b int/<name>` at the head, the piece's own difference applied, a tentative commit never pushed, `full-runs.sh` on the copy), and merge other listings on the main tree meanwhile. When the runs end and the head has not moved in those packages, `merge-as-tested.sh` on the main tree takes minutes; compare `HEAD:archiver/internal` with the copy's tentative commit afterwards, then remove the copy and its branch.
  - **When the merge script stops on ONE failed test, read it to its cause before anything else.** Twice it was not the piece's: a guard that compares two packages' files (the launcher's `TestLauncherStyleMatchesAppTokens` against the pages' `base.css`: a merge that changes `internal/server/web/assets/base.css` runs that test by name), and a test that counts statements and met one made beside it under load (`TestChatsAskAgainOnKey`: run it by name ten times on the same tree). The remaining steps are then ONE script that first checks that the log holds exactly that one failed test and that the staged trees are the branch's (`runs-int-i5/finish-merge-30.sh`, `finish-merge-g18.sh`), and the commit message says the failed test and whose it is.
  - **The merge script's checks do not run every package:** `internal/fabricate` and the launcher are met only when a piece names them. After a batch of merges, one whole run of the packages no piece named is yours (a test of `internal/fabricate` failed on the head for hours unseen).
  - **Each merge is three files and two commands:** the commit message (`runs-int-i5/msg-*.txt`), a wrapper that calls `merge-as-tested.sh` and then the folder's script (`merge-*.sh`), and one script that marks the queue's entry, adds the board's line and edits the row's text (`finish-*.py`), followed by `rewrite-row.py`. At 300,000 tokens of context each call of yours costs more than the run it starts: write the files in one message, start one background command, read one result.
  - **Times in rows, messages and entries come from `date` in the script that writes them.** Written from an estimate they ran one to three minutes ahead of the clock all evening.
  - **What the owner can open is said after every merge that changes it, with what nobody has seen**, and a session's test window on the owner's screen is announced on its row first: the owner took one for the app itself and for the old version.
- **A fresh session for a track is started by you: at the start of a usage window (the first review's point 3),
  and when a track's session writes READY FOR A TAKE-OVER (the owner's word of 11-16 night covers both; before
  it, only at the owner's word)**, with a brief that names what to read,
  what changed since the track's take-over block, the order of work and what "done for the first turn" is. A track is handed over at a natural point
  (its piece listed on the queue), with a take-over block in its progress file.
- **Learnt on 11-21 (the integrator I-6, Opus):**
  - **`merge-batch.sh` compares its first argument with `git rev-parse --short=8 HEAD`:** give it exactly 8 characters, and the pieces file's bases the same way. `merge-as-tested.sh` changes into the repository first, so the commit message files in the pieces file are ABSOLUTE paths (the review sources stay relative to the project folder).
  - **`full-runs.sh` names its logs `win-<package>.log`: a package with a slash (`collector/livepages`, `exact/wire`) writes no log** and is silently not run: run those by their path in a command of your own.
  - **Two whole lists side by side on one PC with seven sessions' coders makes timing tests fail** (a 30 s gap bound, a chunk's writer bound): run each failure by name on the same tree (5 and 3 times here) before calling it load, and say the numbers in the progress file.
  - **A combined tree of several pieces is one whole run:** when more pieces become ready while a batch runs, stop the smaller batch and run the larger once (an agent joined two more in a copy in 9 minutes).
