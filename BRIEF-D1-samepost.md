# Brief D1: the "same post" hold acts only on an origin that names one post (2026-11-14)

Copy: `wt-samepost` (branch `wip/samepost-2026-11-14`, cut from 5315ceb). Work only there. Commit-ready
work on that branch; do not push, merge, or touch any other copy.

## What is wrong (read by the integrator, with numbers)
- `archiver/internal/telegram/record.go` `forwardOrigin` returns `<peer>:<post>` when Telegram gives a
  post number, and the bare `<peer>` when it does not (a forward from a person, or from a channel that
  hides its posts).
- `archiver/internal/catalog/ladder.go` `samePost` (rung 4) runs `samePostForwardsSQL` for any non-empty
  origin: it finds another message with the same origin whose attachment at the same position has a
  saved file of the same type, and the new file is then HELD as "same post as a saved file".
- With a bare origin every forward from one sender shares the key, so a file is held against an
  unrelated saved file from the same sender. Counted read-only on a real brought-in catalogue: 311,091
  messages with an origin, 305,112 of them bare; 19,812 files held as "same post", all 19,812 from a
  bare origin. On the four test catalogues: 0 such holds (they hold almost no forwards).
- The old app has no such rung: its holds come from the look-alike rule, frames, albums (docs
  `COPY-CHECKS-STUDY.md` section A). Its rule (`TRIED-BEFORE.md` section 6): every hold carries
  evidence. A bare sender is not evidence of the same post. The viewer already has this rule
  (`internal/viewer/refresh.go` `soundOrigin`): do not edit the viewer, another session owns it.
- The owner decided on 11-14 that a held copy on a live account waits for good unless released. So a
  wrong hold now means a unique file that is never downloaded.

## The change
1. In `internal/catalog`: a small unexported predicate (an origin names one post: `<x>:<n>` with n a
   whole number above 0, taken after the last colon), and `samePost` returns false at once when the
   origin does not pass it. Nothing else in the ladder changes: the look-alike rung and the others then
   judge the file as they would any other. The origin is still stored on the message as it is.
2. Look at every other place in `internal/catalog` (not tests) that reads `fwd_origin` or the
   "same post (" evidence (`staging.go`, `state.go`, the evidence rewrite near `ladder.go:620`) and say
   in your report whether any of them can act on a bare origin. Change one only if it can make or keep
   a hold from a bare origin; say what you changed and why.
3. Existing wrong holds: do NOT write a repair or a schema step. Report only: is there an existing pass
   (`Settle` or another) that would judge those files again, yes or no, by reading. The integrator
   decides what follows.

## Tests (named; nothing more)
New tests in `internal/catalog`, invented data only:
- a file forwarded with a bare-sender origin, while another message with the same bare origin has a
  saved file of the same type at the same position: the new file is wanted (or whatever the later rungs
  say), not held as "same post", and no "same post" edge is written;
- the same with an origin that names a post: still held as "same post", evidence unchanged;
- origins `"123:0"`, `"123:"`, `":5"`, `"123:abc"`: treated as not naming a post.
Run only: `go test ./internal/catalog -run '<your new tests and any existing test whose name has SamePost>' -count=1`,
then `gofmt -l internal/catalog` and `go vet ./internal/catalog`. If an existing test relied on a bare
origin holding, change it to the rule and list it in the report. **No whole-package run** (the package
takes about 3.5 minutes; the integrator runs it once before the merge), no race detector, no Docker.

## Rules
- Go: `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`, then in
  `wt-samepost/archiver`. The PC is short of memory: one go command at a time, each with
  `GOGC=25 GOMAXPROCS=1` and `-p 1`.
- Privacy: invented data only in tests; never open the real catalogue, the old app's folder
  (`E:\T\tg-dl`), or any media. Print counts, sizes and timings only.
- Nothing is run against Telegram. No new dependency. Comments say why, in plain words.
- Commit with `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, message ending
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. One commit.
- Report: `archiver/docs/progress/samepost-REPORT.md` in the commit: what changed, the answers to
  items 2 and 3, the tests run with their times, anything you doubt.
