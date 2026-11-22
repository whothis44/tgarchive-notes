# Telegram archive fork: read START-HERE.md first

**A new session starts with `NEXT-SESSION.md` (current tasks, in order).** **The fork is private since 11-13.** The working repository is `whothis44/tg1`. The old fork
`whothis44/telegram-media-downloader` is detached, private and an archive: never push to it. Releases are installed by
hand by the owner. Details: `HANDOFF-go-private.md`. 12.30 has been live since 11-13 14:42. **No archive numbers in
commit messages, PR bodies or CHANGELOG entries.**

Before doing anything in this folder, read `START-HERE.md` (rules, tools, code map, build/test/release flow), then
`HANDOFF-ix12.28.md` (current state: 12.28 live, the speed-limit findings and what to do next; `HANDOFF-ix12.24.md` holds 12.23–12.27), then `PRE-PUSH-CHECKLIST.md` before
any push.

Hard rules, in short (details in START-HERE.md §2):
- **Privacy:**
  - Never open the live dashboard, the real media viewer, or any real media or file.
  - `E:\T\tg-dl` is read-only: the report `data\ixreports\latest.txt`, `data\crashes\running` and `history.jsonl`, and the
    DB only as `file:E:/T/tg-dl/data/db.sqlite?mode=ro`.
  - Print counts, sizes, timings and versions only: never names, text, paths, IDs or links. Never print report lines with
    "same bytes as".
  - Never commit or print `start.bat`. Invented data only in tests, fixtures and screenshots.
  - New `ixLog` calls use constant format strings.
- **Never stop, restart, replace or reconfigure the running app.** Never bypass Telegram's waits, add sessions, or test outside
  the VPN.
- **No new Telegram requests without measuring them,** and none from a user's ranking or click without their OK and the cost.
  Probable copies are held, never skipped, and never go before unique files.
- **Push a branch, and tag or publish a version, only with the user's explicit OK for that version.** Publishing installs on
  the user's archive. Draft CI-only PRs; never merge, never push `main`.
- Commits: `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, ending with
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- No speed claim without measurement ("looks like" for one day's numbers). Run independent challenger reviews of
  download-path and UI changes before release.
- Goal: fastest downloads of as much distinct content as possible before the account is deleted on 2026-11-29 at 22:24
  local (the user confirmed the time on 11-11; "11-30" in older notes is the UTC date).

## The standalone archiver (`repo-archiver`)

A new app, built from scratch, is being developed in `repo-archiver` (branch `claude/charming-feynman-vm2xia`, Go module
in `archiver/`). Since 11-11 it lives in the **private** repository `whothis44/tgarchive` (the remote named `private` in
that checkout, and its default push target). `origin` there is the public fork: do not push the new app to it.
For any work on it:
- **Read `BOARD.md` in this folder first** (since 11-14 night). It is the one page every archiver session shares: the
  order of work with the lessons to read for each step, who owns which packages, branches waiting to merge, messages
  between sessions, decisions waiting for the user. Change only your own rows. Then your start file, then the first
  block of `repo-archiver/archiver/docs/HANDOFF.md` section 0c. One session is the integrator (named on the board):
  it merges, keeps the board and the documents, and builds nothing itself; other sessions hand it branches and never
  merge into or push the main branch. Pushing that branch to `private` after each finished piece has the user's OK;
  never tag, release, merge or push `main`.
- **ROUTINE STEPS GO TO A SONNET CLERK, ALWAYS (the user, 11-16 01:15: "Commit that Sonnet rule somewhere it
  will be seen and respected"; first set 11-13, and not followed on the night of 11-15, when no session used
  one).** Usage is what limits this work, and every call of a main session re-reads its whole context: a
  mechanical sequence run call by call in a Fable session with a large context costs many times what the
  same steps cost a clerk.
  - **What is routine:** re-running named tests; `gofmt`, `go vet`, a build; starting a full run and reading
    its "exit N" lines; applying a named difference and comparing named trees; merging the head into a branch
    when the merge is clean; committing with the message you wrote; pushing a `wip` branch or `notes`;
    building and installing a program by the written steps; removing a finished copy; measuring the PC;
    copying a review or report through a script; drafting a progress or handoff entry from your notes.
  - **How:** ONE agent call with the model set to Sonnet and an exact instruction (the commands or the named
    steps, what "done" is, what to report: numbers only). The clerk decides nothing and stops at the first
    thing that is not as written. Where the steps never change, a script is cheaper still: write it once and
    let the clerk, or one call of yours, run it.
  - **What stays with Fable:** briefs and design, reading what was tried before and the risky part of each
    change, judging agents' reports, the run plan, the commit message's words, decisions, anything said to
    the user. **Opus 5.5 at high effort codes and does the independent reviews.**
  - **How it is kept:** every progress entry that reports routine steps says "by a Sonnet clerk", or gives
    one of the two reasons it was not (a single command; the step needed a judgement). The integrator's
    start-of-session review counts this per track and tells the user which track is not doing it. A brief
    for a fresh session names this rule in its first lines.
- **Who reports to whom (the user, 11-15): building sessions report to the integrator only, through the files.**
  A building session (viewer, copies, mirror, pages, core) writes its state on its `BOARD.md` row and in its progress
  file, lists finished branches in `MERGE-QUEUE.md`, and puts questions for other sessions under the board's
  "Messages". It does not report piece by piece to the session that started it or to the user. What only the user
  can decide goes on the board's "Waiting for the user" list in one line with a recommendation; a session asks the
  user directly only when it cannot go on without the answer (a real run to start, a design that writes to
  Telegram). The integrator reads all of it, reviews progress and tells the user.
- **Starting an integrator in a new usage window:** the user pastes into a new session in this folder
  "Read `START-INTEGRATOR.md` and do what it says." That one fixed file says what to read, how to review every
  track's progress against what is really on disk, and how to merge. A stopped building session is restarted by
  pasting "Read `BOARD.md`, take over the <track> track from its progress file, and carry on" into a new session.
  **Since 11-16 night that first line is the only command the user gives (the user: "why do I need to start
  multiple commands to resume when usage returns? ... It can certainly spawn the sessions it needs I would think,
  then detach them"): the integrator starts the building sessions itself in its first turn, each with its track's
  start line, and detaches them (`START-INTEGRATOR.md`, the first review's point 3). The second line is the
  integrator's to use, or the user's when they want one track alone.**
- **Direction (the user, 11-14 night): the old account does NOT move to the new app** ("the old app was able to
  basically mirror everything it needed to, so the switchover isn't needed, but the unified viewer still is"). The old
  account stays on the fork until Telegram deletes it. Nothing is planned or built whose only reason was the move (the
  11-20 checkpoint, deadline order and forecast for the old account, the read-only end state in the new app, the
  frozen account's sign-in). **The new app's objectives, in the user's words (11-14):** adaptive downloading, advanced
  and efficient deduplication in layers, automatic forwarding to groups it creates so items are saved quickly,
  automatic flagging of deleted items, and the rest of the roadmap; plus the unified viewer over the old archive and
  the new accounts. **Added 11-16 night, the user: "The whole point is to have a
  unified archive, so the new app we're building can run duplicate detection against the archive the old one
  downloaded to flag new media and the rest." ONE unified archive: the new app's copy checks run against what the
  old app downloaded; media the old archive does not hold is flagged as new; copies are recognised across both; the
  viewer shows one archive. It has a roadmap row ("ONE UNIFIED ARCHIVE"); copies leads, with Core and the viewer and
  bring-in. The copy rules below stand.** The order is on the board: unified viewer; copy layers; mirror groups on the test account; real
  runs for days. **The download path is finished: do not tune it** (its speed on the test account is inside the old
  app's range).
- **Everything in `FEATURES.md` and `ROADMAP.md` is already asked for (the user, 11-14 23:30, on a session that
  listed what was missing and then waited: "It knows what I want, but didn't build any of it, since I didn't
  explicitly ask it, despite it being in the list of features").** Never answer "that is not built; say if you want
  it". A listed feature found unbuilt in your own packages is briefed and built in your track's order, and the user
  is told that it is being built. One in another track's packages goes onto the board's "Listed and unbuilt" table
  for that track at once. One with no roadmap row or owner goes to the integrator, who gives it both the same day.
  A track that is waiting on a coder, a review or the user takes the next listed feature in its packages. Not
  changed by this: nothing runs against Telegram before the user starts it, pushes and tags keep their rules, and
  which chats are mirrored or downloaded stays the user's choice.
- **Save progress routinely: usage can run out in the middle of anything (the user, 11-14 night).** Each session
  keeps its progress file in this folder current from its first action and after every step that changes the state
  (a brief written, a coder started, a hand-back, a decision by the user, a run started), with the time from `date`:
  what is running and where (copy, branch, agent), what is committed and pushed, what is not, and the next step in
  one line, so that a fresh session can take over from the file alone. Coders commit work in progress to their own
  `wip/*` branch as they go and push it to `private`; the board row is brought up to date at the same moments; the
  notes in this folder are committed on the `notes` branch.
- **Read the history yourself, in full, before proposing or planning anything (the user, 11-14 night: "IN FULL,
  MANDATORY"; "To make a plan, we need to know what has been tried").** In `repo-archiver/archiver/docs`:
  `TRIED-BEFORE.md`, `LESSONS.md`, `WINDOW-EVIDENCE.md`, `COPY-CHECKS-STUDY.md`, `TELEGRAM-FACTS.md`; in this folder:
  `LESSONS-ix12.29-servers.md`, `LESSONS-ix12.30-live.md`, `LESSONS-viewer-ix12.32.md`, `ANSWERS-for-archiver-4.md`
  to `-9.md`; and for any download-path question the fork's own code and changelog. The board names the sections for
  each step. Do not hand that reading to an agent and work from its summary: on 11-11 that produced three wrong
  proposals and cost the user hours.
- **Put the old app's number beside yours before calling anything a defect (the user, 11-14: "There's literally
  a lessons learned document, and a what we tried that didn't work document. Why are we spinning in circles?").**
  On 11-14 a session read `TRIED-BEFORE.md` and `WINDOW-EVIDENCE.md` and still spent a day and three real runs
  rediscovering what they say (a server's speed has a ceiling; more parts bring more waits, not more bytes), while
  the speed it was chasing was inside the old app's own range for that server. Before proposing or briefing: write
  down what the lessons files and the old app's code (`wt-v12.31`) already say about it, with the old app's number
  for the same server and regime; default to the old app's way where it worked; change it only where a number
  already on record says the change pays. If the documents and your conclusion disagree, the documents win until
  a number says otherwise.
- **SINCE 11-21 (the owner): Opus is the main model for the orchestrator sessions (the integrator and every track's
  session), "with Fable only used in rare cases where Opus is fully stumped".** Wherever this file, the board or a
  start file says "Fable" for the architect, judge or orchestrator, read "Opus (the session's own model)". A track
  that is fully stuck says so on its row and asks the integrator before any Fable agent or session is used. Coders
  stay Opus 5.5 at high effort; the Sonnet clerk rule below is unchanged.
- Staffing (the user, 11-11): Fable reviews and orchestrates; **Opus 5.5 at high effort does the coding**, Sonnet only
  for plainly routine work.
  - **Added 11-13 (the user):** Fable is the architect and the judge, not the dispatcher: briefs and design, reading
    what was tried before and the risky part of each change, judging agents' reports, decisions with the user, reading
    the real runs. **A Sonnet "clerk" agent does the mechanical steps** on exact instructions (re-run named tests,
    format and vet, commit with the message Fable wrote, push to `private`, remove an agent's copy, measure the PC's
    load, draft the handoff entry); it decides nothing and stops on any failure. Coding agents hand back commit-ready
    work. **Sessions are short: a fresh one after each landed piece**, started from the handoff, whose dated entries
    are folded into one short current state first. Small decisions for the user go in one turn.
- **How the work goes (the user, 11-13 night): build in parallel, as efficiently as possible.** The earlier order
  "real runs before more code" (11-13) is dropped ("I don't really agree with it or think it's necessary"). So: the
  board's steps are built side by side, each track owning its packages; several Opus coders at once in separate
  copies when memory allows; the main session prepares the next step while agents and runs go; a session may land
  several pieces; real runs on the test account are driven by the main session and left running unattended (the user
  present for the first start, and starting any run that must outlive a session in their own window). Not relaxed:
  reading what was tried before yourself, Telegram's waits, a race run and an independent review before
  download-path code runs for real, the load budget per agent.
- **Build first, test once (the user, 11-14): "don't test needlessly. Get it done then test."** And: "don't reinvent
  the wheel unless it actually improves things": where the old app has a system that was iterated on, port it and
  improve only where a number shows it. "Done" means the user has opened it or run it. **Where the app adds value,
  in the user's words: "the advanced deduplication, media checks, reuse of downloaded data".**
- **Tests in the new app (the user, 11-14, after a race run of four packages one after another held a commit for
  over two hours):**
  - **While working, run only the tests of what was changed:** named tests (`-run`) or the one small package. An
    agent's brief says which. No whole-package run of a slow package (`internal/catalog` about 3.5 minutes,
    `internal/collector` about 6; under the race detector 58 minutes and over 30), no `go vet` over many packages
    and no race detector per step or per agent.
  - **The full runs happen once, right before a merge into the branch:** the changed packages' whole tests, `gofmt`
    and `go vet`, and the race detector **only on packages where code that runs concurrently changed**. A flag, a
    config value handed through, a one-line setting, a comment or a test does not count: that package gets no race
    run. A piece that is not download-path code and starts no goroutine (a pure package) needs no race run.
  - **The order is fixed (the user, 11-14, after the full runs were started before the review's fixes and had to run
    twice):** the coder hands back; the main session reads the risky part; the independent review; its fixes; then
    the full runs, once. Never start the full runs while a review or its fixes are still open.
  - **Before starting the full runs, tell the user in one line** which packages get whole tests, which get the race
    detector and why, and about how many minutes. If the race list is more than two packages, or any run is over 15
    minutes, say why it is needed. The runs are started with `ix-tools/full-runs.sh`, which takes the two package
    lists as arguments and has no default: the session names the packages.
  - **Run them side by side, not in a row:** one Docker container per package at the same time (each with its own
    `--cpus`, the compile step still limited: `GOGC=25 GOMAXPROCS=1`), tests of one package in parallel where they
    allow it, and the catalogue's scale test on its own. Windows test runs of different copies may go at the same
    time as well. The budget is the PC, not a fixed number: 12 logical cores, of which the running old app and
    Windows need about 4; measure CPU and free memory first, keep about 2 GB free, and never pin the CPU.
  - Nothing waits idle on such a run: the next piece is briefed and started on a local base meanwhile.
- **Rules from the lessons files that every step meets** (details and numbers there): only exact evidence (the same
  Telegram file, the same SHA-256, every part hash) may skip a file; a probable copy is held, never skipped, and a
  frame check's "no match" never releases a file by itself; never download from a source the user did not choose
  (find, count, read and propose); nothing in the background reads the library on the NAS while copies wait; anything
  that acts for the user follows the 13 rules of `TRIED-BEFORE.md` sections 24 and 25; reports lead with what ran for
  real.
- The privacy rules above apply to everything in it.
- **Waits in the new app (the user, 11-11): "We're not stuck to orthodoxy here. It's a new app."** For
  **download parts only**, the new app may ask again before a wait Telegram stated is over, as part of its
  adaptive engine: a switch, off by default, judged by measurement (speed per busy slot before, during and after;
  refusals counted). It was to be tried first on the old account, which no longer moves to the new app, and the
  record expects nothing from it: it stays off unless the user asks for the trial. Waits on everything else (reading
  messages, forwarding, creating chats, sign-in) are always slept in full. The rule "never bypass Telegram's waits"
  above still holds for the fork and its running app. Details: `repo-archiver/archiver/docs/FEATURES.md` section 12.
- **On the owner's NAS every Docker container runs in host network mode (the owner, 11-15: "For whatever reason, on
  this NAS, everything must be run in network host mode").** A published port (`ports:`) is not reachable from the PC.
  So every compose file for the NAS (the helper, the planned downloader, anything else) uses `network_mode: host`, the
  program listens on the NAS's own home-network address, and its health check asks that address. A container reads a
  shared folder only as the NAS user's own uid and gid, `user: "1000:10"` (never 0). Details: the memory `nas-docker-host-network`.
- The new app need not build on the fork: any existing engine or code may be used, whatever its licence (it
  is private). Takeout mode is not built.
