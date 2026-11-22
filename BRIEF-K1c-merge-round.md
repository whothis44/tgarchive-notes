# Brief K1c: "files only from chats the owner chose", the merge round (Core, 2026-11-15)

For one Opus coder. K1 (`BRIEF-K1-chosen-chats.md`) and its review's fixes (`BRIEF-K1b-fixes.md`) are built and
pushed as `wip/core-chosen` 52108cf (copy `wt-core-chosen`: read there, change nothing there). That branch sits
on an old state of the mirror's branch (c599ac5) and on a main branch from before `c_want.released`. This round
puts K1 on today's main head, closes what the review left for the merge, and hands back something the
integrator can merge at once: **G1 (the app's pages in one program) waits for it.**

**The head to work from is 9dd5a21** (the main branch with the mirror's piece merged as be429e1, pushed 11-15 18:20; the catalogue is at schema step 18 there). The mirror's branch moved a long way after K1's base: its settle was rewritten, a table `c_mirror_again` came, `ForwardItem.Attempt`, `SettleRead`. The copies track's rule for a set of files (its E12) is NOT on this head: section 3's second case applies. You work in the
copy `C:\Users\trabi\Claude\Projects\Telegram\wt-core-chosen-c`, branch `wip/core-chosen-c` (made for you from
that head), Go module in `archiver/`.

## Read first, in full

`BRIEF-K1-chosen-chats.md`, `BRIEF-K1b-fixes.md`, the review `wt-core-review-scratch\REVIEW.md` (P3 and P6 are
this round's), and the coder's report `wt-core-chosen\archiver\docs\progress\core-chosen-REPORT.md` (its last
section, "Left for K1c"). All under `C:\Users\trabi\Claude\Projects\Telegram`. Then the code as it stands in
`wt-core-chosen`: `internal/catalog/chosen.go` whole, `state.go` (`Release`, `releaseSQL`, `asideBackSQL`, the
requeue), `internal/collector/chosen.go`, `reader.go` (`approveRead`), `choose_cmd.go`.

## What the old app already knows (why this piece exists; numbers from `TRIED-BEFORE.md` 24 to 26, answers 7)

The old app's 12.30 added 30 channels by itself: the queue of unique files went from about 319 GB to about
2 TB, nearly all on the server that was already the limit; the owner switched off 24 of the 30 by hand as
"downloading trash" after they had brought 17,613 files (34 GB). Rule since: find, count, read and propose;
download only what the owner chose. And the owner's standing rule for copies: a probable copy is held, never
skipped, and never goes before unique files; a file the owner released is never held or marked again.

## 1. K1 onto the head

- Apply K1's own change (the difference `c599ac5..52108cf` of `wip/core-chosen`, nothing of the old mirror
  branch under it) onto your branch as one three-way application, for example
  `git diff c599ac5 52108cf -- archiver | git apply --3way` (both commits are in this repository), and resolve
  what conflicts. Commit it as one commit ("K1 on the main head: applied"), before any change of this round,
  so the round's own changes read apart. Do not rebase or merge `wip/core-chosen` itself and never push to it.
- **Where the head differs from K1's base, the head wins and K1 is fitted to it:** the mirror's files
  (`mirror_auto.go`, `mirror_cmd.go`, `mirror_marks.go`, `mirror_settle_cmd.go`, `schema_mirrorauto.go`,
  `schema13.go`, `mirrorsettle.go`, the fake Telegram) were reworked by the mirror track after K1's base: keep
  theirs whole and re-make only K1's lines in them (the setting asked first in `newChatPolicy`;
  `autoApproveFor`; the corrected words; the counts' words). `internal/server/chats.go` and `server.go` were
  changed by the pages track: keep theirs and add K1's door (`POST /api/chats/collect`, the effect in the
  kinds' answer). `state.go`, `ladder.go`, `settle.go`, `rows.go`, `catalog.go` carry the copies track's steps
  (`released`, the step at save, "check first"): keep theirs; K1's `Release` and requeue change is re-made on
  the head's own statements (keep every column and case the head's statements have; add only the "held as not
  collected" case).
- K1 has no schema step and gets none. The catalogue's version is the head's.
- Say in the report, file by file, what conflicted and how each was settled.

## 2. The `released` column is real now

`c_want.released` exists on the head (schema step 17: the owner released this held file; nothing holds or
marks it again).
- `chatHoldSQL` takes `AND released = 0` as plain text; `releasedGuard` and its read of the table's columns at
  every chunk go.
- `Release` and the requeue of a set-aside (`notCollectedBack`): a released file is never held as not
  collected; it goes back where the head's statements put it.
- The chat settle also calls the topics' `topicHoldSQL` (pages' statement), which has no such guard on the
  head: a released file whose reason a claim cleared can be held by it. Add the guard there (the same two
  words), with a named test for a topic action as well as for the chat settle, and say so in the report: the
  Core session tells the pages track.
- Tests with the real column: `TestChooseChatSettlesFiles`'s "released (the column)" case loses its own
  `ALTER TABLE`; new cases: a released file in transfer whose chat is switched off comes back wanted from
  `Release`; a released set-aside comes back wanted from the requeue; a released file is not held by a topic
  action. Each guard shown failing its test when removed.

## 3. Review P3: a video chosen after its read is judged before it is wanted

The gap: a video catalogued in a chat nobody chose is held as "not collected"; a better copy of it is saved
meanwhile through another chat (the head's step at save judges wanted files only); the first chat is chosen;
`judgeChat` makes the video plainly wanted through `wantedAsMainIn`: a probable copy goes out as a unique file.
- **Do not write a second copy of the look-alike rule.** The copies track is putting "hold, or mark for the
  exact check first" for a set of files inside `wantedAsMainIn` (`ladder.go`; its piece E12, board message
  36). Look at the head's `wantedAsMainIn`:
  - if it already judges the set that way: add the named test `TestChosenLaterVideoIsJudged` (a video
    catalogued in an unchosen chat; a better copy saved through a chosen chat; the first chat chosen: the
    video is held as a probable copy, or marked for the exact check first when the saved file has its byte
    size; a released one stays wanted; a video with no saved look-alike is wanted) and one for the same
    through the owner's `choose`;
  - if it does not yet: build nothing for it. Write the scenario and the exact call path (`judgeChat` to
    `wantedAsMainIn`, with the arguments it passes) in the report under "P3, for the copies track", and
    write the test in a file of its own, `chosen_p3_test.go`, **not committed**: paste it in the report.
    The Core session decides with the integrator and the copies track where it lands.

## 4. Review P6: a door for the other read-only openers

The app (`cmd/tgarchive/app.go`) and the viewer (`internal/viewer/viewer.go`) open the catalogue read-only
with no schema check: on an older or newer file they fail with an SQL error. Their files are other tracks'.
Give them a door and change neither: an exported function in `internal/catalog` (a new small file) that
reads a file's schema read-only and answers the version and one of three fixed states (this build's, older,
newer), with the two fixed sentences now in `internal/collector/chosen.go` (`roOlder`, `roNewer`) built from
it, so every program says the same words; the collector's `readOnlySchema` calls it. A named test on an
older and a newer invented file (the file's hash unchanged). The Core session tells the two tracks.

## 5. Small things from the Core session's read of the second round

- `imported.go`: `SetChatCollect`'s comment still speaks of "the chat's switch (`chatSwitchPrefix`)": those
  rows are gone since K1b; say what is true (a program's switch: no owner's record).
- `reader.go` `approveRead`: the choice is made only `if !c.cfg.autoHooksOff`, a test switch of the automatic
  mirror's hooks inherited from the old `ownerChose`. The owner's choice is not the mirror's hook: find which
  tests set the switch, and take the choice out from under it unless a named test needs it there (say which
  and why).
- Every sentence K1 prints is still true on the head (the mirror track changed its commands' words and its
  settle since): `TestWordsTellTheTruth` is the place; correct what is not.

## Rules (hard)

- Touch only what K1 and K1b touched, plus: `internal/catalog/topics.go` for the one guard of section 2, the
  new file of section 4, tests, and `archiver/docs/progress/core-chosen-REPORT.md` (append a section "K1c, the
  merge round"). Not the engine, the supply's claim path, the reader's requests, the mirror's run or its
  settle, the store, the viewer, the pages' scripts.
- No request to Telegram is added, moved or removed. No goroutine, timer or lock is added (say so plainly in
  the report, or say what you added: it decides whether a race run is due). No schema step.
- New log, error and count text is constant words with numbers: never a chat's name, id or text. Invented
  data only. Read nothing under `E:\`, no `start.bat`, no log of a real run; never touch the folder `a3`.
- Shell: Git Bash. `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`, then in
  `wt-core-chosen-c/archiver`: `GOPROXY=off GOGC=25 GOMAXPROCS=2 go test -p 1 -run '<names>' ./internal/<package>/`,
  named tests only, one go command at a time. No whole-package run of the catalogue or the collector, no
  `./...`, no race detector, no Docker: the whole runs are the Core session's, once, after its read. The
  collector's test program links the Telegram library (minutes and about 3 GB for its first build): look at
  free memory before every go command (PowerShell: `(Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB`,
  GB) and do not start one under 4 GB free.
- **Run, by name, every test K1 and K1b added or changed** (the lists in the report's "Tests run" sections)
  **plus this round's, on the head, and paste their `ok` lines.** A test that fails only because the head
  changed what it relies on is fitted and named in the report with the reason; a test that shows K1 broken
  on the head is a finding: say it first.
- Commit as you go on `wip/core-chosen-c` and push it to the remote `private` after each commit that builds
  (`git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, messages starting `WIP core: `, ending
  with a blank line and `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`). Never another branch, never
  a merge into the main branch, never a tag, never a force-push.
- `gofmt -l` clean and `go vet` of `./internal/catalog/ ./internal/collector/ ./internal/server/` clean before
  the hand-back.

## Hand back (your last message, and the report's new section)

The branch's head; conflicts file by file and how settled; sections 2 to 5 each with its tests and the
mutation that fails them; P3's state (built on the head's rule, or the scenario and the uncommitted test);
whether any goroutine, timer or lock was added; every existing test changed and why; the `ok` lines; what was
NOT verified; a drafted final commit message for the squashed piece.
