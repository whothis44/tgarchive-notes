# Brief E12: files made collected in bulk go to the exact check first, like any other look-alike (copies track, 2026-11-15)

For one Opus coder, in the copy `C:\Users\trabi\Claude\Projects\Telegram\wt-copies-1` on branch `wip/copies-12`
(made for you from the main branch's head d1af260; change no branch). Go module in `archiver/`. Commit work in
progress as you go (`git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, messages starting
`WIP copies: `, ending with a blank line and `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, no number
of any real archive) and push with `git push private wip/copies-12`; never `origin`, never the main branch, never
a force-push.

## What the old app already knows (its numbers)
- Of the look-alike holds a frame check later released, 203 of 275 had the saved file's exact byte size, pixels
  and length, and at least 23 were exact copies (18 skipped later by Telegram's hashes, 5 the same SHA-256
  after download); of the 1,218 confirmed, 975 had the same byte size. The exact check found 5,007 files
  (240 GB) the same in ten days, every one by Telegram's hashes, none ever undone. **So a look-alike of a
  saved file's byte size goes to the exact check first: it ends such a hold without bytes.**
- The owner's rule since 11-14: a held copy waits for good unless the owner releases it. So a look-alike
  that is held instead of marked never gets that exact answer: it just waits.
- The new app does this for a file met new (`attach`), for one that becomes wanted later one at a time
  (`wantedAsMain` calls `markCheckFirst`), and at a save (`atsave.go`). **The gap (board message 11): files
  made collected in bulk** by a topic action (`topics.go` `judgeTopics` calls `wantedAsMainIn` for a set) are
  held as probable copies and never marked; and `markCheckFirst` does not take a file whose reason is the
  topic's (`ReasonTopicPref`). Our number: none (never run for real); it is on the safe side today (held).

## Read first (all in `archiver/internal/catalog`)
`ladder.go` `attach`'s "check first" block and lines 973 to 1064 (`wantedAsMain`, `wantedAsMainIn`,
`wantedAsMainSQL`, `roleChanged`); `exactcheck.go` `markCheckFirst`, `HoldCheckFirst`, `sameSizeSaved`;
`atsave.go` (all: how a set of covered files is held or marked there, and its rules for released, kept-held
and fetch-real files); `topics.go` `topicRuleChunk`, `judgeTopics`, `rejudgeMessage`, `topicHoldSQL`,
`collectedSQL`; the tests `lookalike_rule_test.go`, `topics_test.go` and those of `atsave.go` for how the
package builds invented catalogues.

## What to build (in `internal/catalog` only: `ladder.go`, `exactcheck.go`, `topics.go`, new tests)
1. A set form of the mark, used by `wantedAsMainIn` before its three statements whenever the set is not the
   single-file path that `wantedAsMain` already marked: among the files of the set that the first two
   statements would take out of "not collected" (held, reason chat preference, alternative or topic
   preference, the condition `extra` true, not kept held), those that are look-alike videos by rung 6's own
   edge and have a saved file of exactly their byte size that the exact check would take (the same test
   `markCheckFirst` uses: `sameSizeSaved`) become **wanted and marked** (`check_first = 1`, `probable = 0`,
   `ReasonLookAlikeCheckFirst`), exactly as `markCheckFirst` leaves one. Everything else in the set goes
   through the three statements as today. Candidates are few (files with a rung 6 edge): select their ids
   with one statement over the set, then decide each with the existing per-file code; do not write a second
   copy of the rule in SQL.
2. `markCheckFirst` (and so the single-file path through `roleChanged` with `TopicsOnly`) also takes a file
   whose reason is `ReasonTopicPref`, when the caller's collected condition holds for it. Check `roleChanged`'s
   two branches: after this, both must mark the same file the same way.
3. The third statement's files (a probable copy held as a look-alike, now supplied again): one that has a
   saved file of its byte size and was never checked (no exact-check record says "different" for it) is
   marked the same way instead of only supplied. Read how `atsave.go` and `HoldLookAlike` treat a file whose
   check already said "different" (it must never be marked again: it would be checked for ever) and keep that
   rule; say in the report which column or row you read it from.
4. Never marked, in every path (as `markCheckFirst` and `atsave.go` already hold; a test for each): a file
   the owner released (`released`), one kept held (`keep_held`), one to be fetched for real (`fetch_real`), a
   file that is not a video, one with a file already (`file_id`), one in transfer, set aside, saved, skipped
   or gone, and a file in a topic that is still not collected (message 11: "a look-alike in a topic that is
   not collected is held, not marked").
5. The counts a topic action reports (`TopicEffect`: collected again, supplied again) must still add up: a
   file marked counts as collected again (it left "not collected"). Check `topics_test.go`'s expectations and
   the Chats page's use (`internal/server` reads the effect: do not edit that package; if a count's meaning
   would change for it, stop and say so in the hand-back).
6. Cost: the settle runs in chunks under the one writer. Measure, on an invented catalogue of the size the
   package's own cost tests use, a topic chunk with 0, 10 and 100 look-alike candidates before and after;
   the added work with 0 candidates must be one indexed statement (show its plan uses the set, never every
   held file: see the "+state" note in `wantedAsMainSQL`).

## Tests (named; invented data only)
One test per rule above, each failing before its fix; the topic path end to end (a topic switched on whose
files include: a look-alike with a saved file of its size, one without, a non-look-alike, a released one, a
kept-held one, one already checked "different", a photo): states, marks, reasons and the effect's counts.
Mutations you must show caught (revert, run the named tests, restore): the released guard; the "already
different" guard; the topic's collected condition; marking only for the same byte size.
Run only: `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`, then in `archiver/`:
`GOGC=25 GOMAXPROCS=2 go test -p 1 -count=1 ./internal/catalog/ -run '<names>'` (your tests, and by name the
existing tests of `markCheckFirst`, the topic settle and `atsave`). **Never the whole `internal/catalog`**
(3.5 minutes; the main session runs it once before the merge), no race detector, no `go vet ./...`. The first
go command compiles everything once (the toolchain changed today). Before each go command check memory
(`powershell -c "(Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB"`): under 2.5 GB free, wait a
minute and look again. No test judges real time.

## Rules (hard)
- Only exact evidence ends a file without bytes: this piece only chooses between "held" and "wanted, marked
  for the exact check first"; it never skips, never releases, never makes a probable copy plain wanted.
- A file the owner released is never held or marked again by anything here.
- No schema step, no new table or index, no file outside `internal/catalog`, nothing in `settle.go`,
  `state.go` or `chosen.go` beyond reading them (another branch is changing those three).
- No concurrent code. Logs and errors: numbers and fixed words. Invented data only. Never open anything under
  `E:\` or any real catalogue.

## Hand-back
Commit-ready on `wip/copies-12`, pushed, the copy clean. A report `archiver/docs/progress/copies-setmark-REPORT.md`:
what changed per point, each named test, the mutations, the measured cost, departures and doubts. Your final
message to the main session: the head commit, then at most 20 lines.
