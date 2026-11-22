# Start of viewer session B7 (written by the integrator, 11-16 18:33; the owner pastes one line)

The owner pastes into a new session in this project folder:
"Read `START-VIEWER-B7.md` and do what it says."

You are session B7: take over the viewer track of the archiver from its progress file and carry on. The
owner's new shape for the app, ONE window, is this track's main work together with the pages track.

**Where this stands.** The owner's standalone archiver (a Go module in `repo-archiver/archiver`, a private
repository) is built by several sessions side by side, one per track (pages, viewer, copies, mirror, Core).
One session is the integrator: it merges into the main branch, keeps `BOARD.md` and the documents, and builds
nothing. Building sessions work in their own git copies (`wt-<track>-*` beside `repo-archiver`, branches
`wip/<track>-*` pushed to the remote `private`), report ONLY through the files (their row on `BOARD.md`,
their progress file, entries in `MERGE-QUEUE.md`, messages on the board), and never merge into or push the
main branch. The viewer track owns `internal/viewer`, `internal/window`, `internal/bringin`,
`cmd/tgarchive-bringin`, `cmd/tgarchive-window`, `cmd/tgarchive/viewer.go`. Its session B6 was at 94% of its
context and wrote its state for a take-over at 18:28 on 11-16; it is retired: do not message it.

**The first rule, the owner's (11-16 01:15): routine steps go to ONE Sonnet clerk call on an exact
instruction, or to a script; never call by call in your own context.** Routine: named tests, gofmt, vet, a
build, starting a full run and reading its "exit N" lines, a clean merge of the head, a commit with your
message, a push of a `wip` branch, removing a finished copy, measuring the PC. You brief, read the risky part,
judge and decide; Opus 5.5 at high effort codes and does the independent reviews. Every progress entry that
reports routine steps says "by a Sonnet clerk" or "by a script", or why not.

## Read first, in this order, yourself
1. `CLAUDE.md` in this folder: the section "The standalone archiver" in full.
2. `DESIGN-ONE-WINDOW.md` (the owner's decision, one page), and look at
   `design-options/app-look-options.html`, first button (the picture; invented data).
3. `BOARD.md`: the direction at its top, the viewer's row, the pages' row, the integrator's row, "Listed and
   unbuilt", "Waiting for the owner" (items 35 and 39), and messages 135 to 153 (150 to 153 are the owner's
   first real start and the choice). Not `BOARD-LOG.md`, except for a message a line names.
4. `SESSION-B-PROGRESS.md`: the block "STATE FOR A TAKE-OVER (B6, 11-16 18:28)" (search for it; it is written
   to be enough alone), then the entry of 18:13 it names. Carry on in that file under "SESSION B7".
5. `LESSONS-viewer-ix12.32.md` before you design anything in the viewer, and the first block of section 0c of
   `repo-archiver/archiver/docs/HANDOFF.md`.

## What happened on 11-16, in short
The owner started the app for real for the first time (18:05) and said: "Overall, it's a very ugly app, not
fully functional, doesn't quit properly, and still runs in a browser, just a standalone one?" The app's window
ended by itself after seconds at both normal starts; the owner looked for Saved Messages, the unified stream,
the deleted marks and "first seen" in the app's pages and found none: they live in the viewer's separate
window. The owner then chose from pictures (18:30, 18:27 by the clock for the last word): one window for the
pages and the viewer, a list on the left like a Telegram client, the library's views and toggles, a dashboard
whose numbers each open their filtered place: "Yeah, I think that's a great place to start. Go with it
please." On usage and staffing (18:33): "Keep all going".

## First, before any building (B6's block lists them as asked and not done)
1. **The investigation that is running:** an Opus investigator of B6's looks for why the app's window ended by
   itself (board message 150 e 2); its hand-back was to go into `REPORT-B6-window-ends.md` in this folder and
   onto the branch `wip/b-winfix` (copy `wt-b-join`). Take it over as B6's block says: read its cause and its
   mend, tell pages on the board exactly what the launcher must change, and list a mend only if it is still
   needed before the one window exists.
2. **Board message 151 a and b, never from memory:** is Saved Messages listed in the viewer on a NEW account's
   catalogue; are the unified stream with its kind filters, the deleted marks and "first seen here" as the
   roadmap's rows say. Check on an invented catalogue (the fabricate command, with the account's own chat)
   through the viewer's JSON or a headless look; write on your row what is there and what is not.
3. **The one window, your half of pages' joint note under `DESIGN-ONE-WINDOW.md`:** what the window's shell
   and the viewer's places (the library and its views, the chats, Changes, the review) need to sit under ONE
   navigation with the pages' places (Overview, Queue, Mirrors, Accounts, Settings); which program owns the
   shell and the left list; what the old archive's window shows. Pages (session P6) leads: read its row and
   answer on the board. Then build your pieces in the design's order: the shell and the list; the library's
   views in the list; the details panel. Each piece lands something the owner can open.

**Waiting, built and reviewed, not listed:** the viewer's side of the removed look-alike edge
(`wip/b-edgegone` 3bb6814f in `wt-b-faces`); its steps once copies' C19 is on the main head are in B6's entry
of 18:13. The integrator's row names the main head to cut from (M6 and C19, two schema steps, were merging on
the evening of 11-16).

## Rules that bind every piece of the viewer
- The viewer is a separate read-only program with no Telegram code (its import wall). Nothing in the window
  reaches anything but the app's own addresses on this PC (the window's gate: any new embedded browser starts
  behind it). Nothing in the background reads the library on the NAS while copies wait.
- Invented data only in tests, fixtures, pictures and screenshots. Never open the owner's real folder, real
  viewer or any real media: a try of a starter or a window runs on a scratch copy with `LOCALAPPDATA`
  redirected first, its output to a file. Never stop a program of the owner's.
- **The day's lesson: before anything is called ready for the owner, it has been opened as the owner opens
  it, on an EMPTY catalogue and on a filled one, every place clicked once.**
- Privacy: counts, sizes, timings and versions only. Times from `date` at the moment of writing. Text with a
  Windows path never goes through a shell string: the Write or Edit tool. Commands for the owner use full
  paths.
- The PC's memory is tight: one go command at a time, measure first. Usage was at 74% of all models' week at
  18:27 on 11-16: keep your take-over block current.

## How the track works
A brief starts with a short "what the old app already knows" note. A coder (one Opus 5.5 agent at a time while
memory is short) works in a copy `wt-b-<name>` on `wip/b-<name>`, cut from the head the integrator's row
names, and pushes as it goes. Then your read of the risky part, one independent review with probes (a security
look for anything the window may show or reach), its fixes, the full runs once (said on your row first: which
packages whole, which under the race detector and why, how many minutes: the viewer whole takes about 7
minutes, its race run about 46), then an entry at the end of `MERGE-QUEUE.md` and "LISTED, READY" on your row.
When `internal/catalog` changes beneath you, the viewer's change-log tests run by name.

## Save as you go
After every step that changes the state: a dated entry in the progress file; your board row brought up to
date (cut the row to its current state first: its older states go to the end of the progress file); the notes
committed on the `notes` branch of this folder (commit only the files you changed:
`git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, ending with the co-author line the
earlier commits carry). The owner has said the tracks may remove their finished copies of merged branches,
each checked clean and equal to its pushed branch first.

## Done for the first turn
You have read in; the viewer's row says "session B7 has the track" with its time and is cut to the current
state; the investigation's result is read and told to pages; 151 a and b are answered on your row from a look
at an invented catalogue; your half of the joint note is on the board; the notes are committed. Do not
message the integrator: it reads the files.
