# Telegram archive: the new app (`repo-archiver`) and the old fork

**Rewritten 11-21 at the owner's word, to cut process overhead** ("it's another LLM that set the rules, so they could
very well be completely excessive and inappropriate"). The old text is in `CLAUDE-old-2026-11-21.md`, for reference
only; where it and this file differ, this file wins.

## Hard rules (unchanged, for both apps)
- **Privacy:** print and write counts, sizes, timings and versions only, never names, text, paths, ids or links of real
  data. Never open real media, the old app's dashboard or the real viewer on real media. Invented data only in tests,
  fixtures and screenshots. Never print report lines with "same bytes as". Never commit or print `start.bat`. New log
  calls use constant format strings.
- **The old app's data** (`E:\T\tg-dl`) is read-only: the DB only as `file:E:/T/tg-dl/data/db.sqlite?mode=ro`. **The new
  app's catalogue** (the owner's folder `C:\Users\trabi\tgarchive-app`) only as
  `file:C:/Users/trabi/tgarchive-app/data/catalog/catalog.sqlite?mode=ro`.
- **Never stop, restart, replace or reconfigure the owner's running app** (either one), and never write to the owner's
  folders. The running app is NOT a reason to hold work back (the owner, 11-21): build, test and try in folders of
  your own (no Telegram sign-in, LOCALAPPDATA redirected for the process); installs go through the second folder
  `C:\Users\trabi\tgarchive-app-next` and the owner's update command.
- **Telegram:** nothing runs against Telegram unless the owner starts it. Every wait Telegram states is slept in full
  (the new app's "ask again before a part's wait is over" switch stays off unless the owner asks). No new kind of
  request without measuring its cost; none from the owner's ranking or click without their OK and the cost. No added
  sign-ins without the owner's OK. Nothing that writes to Telegram is built before the owner has agreed its design.
- **Files:** only exact evidence may skip a file: the same Telegram file, the same SHA-256, or Telegram's part hashes
  matching (every part, or three places for a video of 2 MiB or more: the owner's choice of 11-14, FEATURES 12
  fourteenth round, setting `exact-mode`); a probable copy is held, never
  skipped; a frame check's "no match" never releases a file by itself; never download from a source the owner did not
  choose.
- **Git:** commits with `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, ending with
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. The new app lives in the private `whothis44/tgarchive`
  (the remote `private` in `repo-archiver`; never push it to `origin`). Only the integrator merges into and pushes
  `claude/charming-feynman-vm2xia`; tracks push `wip/*` branches. Never tag, release or push `main`. No archive
  numbers in commit messages. The old app (`whothis44/tg1`, `wt-v12.*`) is closed: no pushes unless the owner asks.
- **No speed claim without a measurement** ("looks like" for one run's numbers).

## How the work is run (lean, since 11-21)
- **Models:** Opus is the orchestrator (the integrator and every track's session) and the coder (Opus 5.5, high
  effort). Fable only when Opus is fully stuck, after asking the integrator. Mechanical sequences go in scripts.
- **Who does what:** one integrator session merges, runs the whole test suites once per batch, installs into the
  second folder, and keeps `BOARD.md`. Track sessions own their packages (the board's Tracks table), build, and list
  finished branches in `MERGE-QUEUE.md`. Tracks report through the board; they ask the owner directly only when they
  cannot go on without an answer (a design that writes to Telegram, a real run).
- **Before proposing a mechanism:** read `DIGEST-LESSONS.md` (one page) and the source sections it points to for your
  area. Do not re-propose what it lists as failed. Where the old app (`wt-v12.31`, `wt-v12.32`) solved something,
  port it rather than write anew. The download path is finished: do not tune it.
- **One coder per piece, start to finish:** the coder builds, writes the tests, runs gofmt, vet and the named tests of
  what it changed, and hands back a branch ready to list. Fix rounds go back to the same coder (continue the agent).
- **Review by risk, once:** one independent Opus review only for code that (a) writes to Telegram or acts for the
  owner, (b) decides that a file is skipped, deleted, held or released, or (c) changes the download path. Everything
  else: the coder's tests and the session's own read of the diff. A second review pass only if the first found a
  logic error, and then only of the fix.
- **Tests:** while working and before listing, a track runs the named tests and the whole of its small packages only.
  Never the whole `internal/collector` or `internal/catalog` from a track. The integrator runs the whole suites
  once, on the combined tree of a batch. **Two exceptions, learnt 11-22:** a piece with a schema step runs
  `internal/catalog -run 'Schema|Step'` whole (every step must be safe to run twice and on older files), and a piece
  that touches the pages' or the viewer's assets runs the security sets by name (`server -run 'TestAssets|Security'`,
  `viewer -run 'TestWall|TestHomeDevice|Security'`). Three listings failed on exactly these on 11-22. The race detector only where code that runs concurrently changed.
- **Paper, kept small:**
  - `BOARD.md` is one page of current state (at most about 12 KB): tracks, the queue's order, schema numbers, what
    waits for the owner. Messages between sessions go by direct message; history goes into git, not the board.
  - A progress entry is at most three lines: what changed, what runs where, the next step. Progress files keep only
    the newest state block; older text moves to a `*-LOG.md` file that nobody needs to read.
  - A `MERGE-QUEUE.md` entry is at most 15 lines: branch and head, what it does, files touched, review (if any) and
    test results, schema step, what is not verified.
  - Commit the notes on `notes` after each landed piece, not after every step.
- **Ship to the owner:** every merged batch is built into the second folder, and the owner gets the one-command update.
  What the owner sees and uses comes before new depth.
- **Usage is the limit:** the integrator measures it (`get_usage`) at each merge and tells the owner the percentage.
- **Archive finished sessions (the owner's standing rule, 11-22):** once a session has fully completed its tasks (its
  work merged or handed over, its state written), the integrator archives it to free memory, without asking again.

## The owner's standing decisions (still binding)
- **One unified archive:** the new app's copy checks run against what the old app downloaded; media the old archive
  lacks is flagged as new; copies are recognised across both; the viewer shows one archive. The old account stays on
  the old app until Telegram deletes it (2026-11-29 22:24 local); nothing is built only to move it.
- Everything in `FEATURES.md` and `ROADMAP.md` is already asked for: build it in its track's order, never report it
  missing and wait.
- The app is one standalone program with its own folder: no product code depends on this PC's paths, the start
  folder or scripts. It must feel native (its own window, Windows folder boxes).
- Caps and pacing intervals are stored settings with the agreed default, a random part, and no upper bound of the
  app's own invention.
- The mirror: newly joined chats are mirrored by themselves (no bytes); single posts wait a setting, default 5 to 20 s
  random; albums wait until whole; exact repeats of a message already in the mirror are not forwarded again; forums
  are mirrored as forums with the same topics. Downloads of a chat joined while away: a setting (off, unlimited hours
  only, always).
- **On the NAS every Docker container runs in `network_mode: host`** and as a **dedicated regular (non-admin) NAS
  user of the app's own**, never the owner's admin account and never root: its uid:gid come from the project's `.env`
  (the owner, 11-22: "Should probably be a regular user only for security"; it replaces the earlier `1000:10`, which on
  UGOS is often the admin account). That user gets read and write on the app's own folders and shares only.
- Commands given to the owner use full absolute paths and work from any folder; a script is run exactly as the owner
  will run it, on a scratch copy, before it is handed over.

## The old fork (closed)
The old app (`whothis44/tg1`, private) has fulfilled its purpose; nothing more is planned for it. Its rules and tools are
in `START-HERE.md` and `CLAUDE-old-2026-11-21.md` if it is ever touched again.
