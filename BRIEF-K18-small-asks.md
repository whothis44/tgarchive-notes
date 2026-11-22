# Brief K18: the small asks of other tracks, as one piece (Core, K-6, 2026-11-21)

Six small things other tracks asked of Core's packages over 11-15 and 11-16 (the board's log,
`C:\Users\trabi\Claude\Projects\Telegram\BOARD-LOG.md`, messages 103 a, 118 b, 120 c, 124 c, 127 b, 137 c;
read each where this brief names it). None changes what the app does for the owner except point 6; none
sends a request. **Cut from K21's branch** (`wip/core-self` 0942a7dc, listed, not merged yet), because point
6 deletes K21's own setting keys: this piece is merged after K21.

**Rules of the house:** you are the Opus coder of this piece and hand back commit-ready work. Named tests
only while you work (`-run`, or a small package whole; the whole `internal/collector` takes about 30 minutes
and the whole `internal/catalog` about 8: not yours to run); no race detector; no `go vet` over many
packages. Invented data only; nothing of a name, text, path or id in any log line, error or commit message;
new log lines are constant format strings with numbers only. Nothing runs against Telegram: the fake only.
Never touch a running program, the main copy `repo-archiver`, `C:\Users\trabi\tgarchive-app` or anything
under `E:\`. **Every `go`, `gofmt` or `vet` command goes through the track's lock script:**
`bash /c/Users/trabi/Claude/Projects/Telegram/runs-core-k5/go1.sh <folder to run in> go test -p 1 -run '<names>' -timeout 20m ./internal/collector/`
(it prints "go1: exit N"; 97 or 98: nothing was run, wait and try again). Another Core coder (K22, alerts,
`wt-core-alerts`) works at the same time and shares the lock: expect waits.

**Where:** from `C:\Users\trabi\Claude\Projects\Telegram`:
`git -C repo-archiver worktree add ../wt-core-asks -b wip/core-asks 0942a7dc`. Work only in
`C:\Users\trabi\Claude\Projects\Telegram\wt-core-asks`. Commit with `git -c user.name=Claude -c
user.email=noreply@anthropic.com commit`, the message ending `Co-Authored-By: Claude Opus 5.5
<noreply@anthropic.com>`; push only `wip/core-asks` to `private` as you go. No `git stash`, no rebase.
One commit per point is welcome.

## The six points

1. **Two sentinels** (copies' 120 c and 127 b): in `internal/collector/words.go`, `ErrPartsDir,` and
   `ErrPairWords,` among the sentinels after `ErrStagingLocked, ErrStagingOtherCatalogue, errNoIdentity,`
   (line 90 today). Find where each is defined (the copies track's files: read, do not edit) and check that
   `errWord` then answers its fixed words; a test by name for both.
2. **An exported name for the sign-in setting key** (the viewer's 137 c): `keySignedIn` in
   `internal/collector/account.go` (`"collector.signed_in." + n`). Export a function (e.g.
   `SignedInKey(account int64) string`) and keep `keySignedIn` calling it or replace its uses. The viewer's
   end-to-end test in `internal/acttest` copies the string today: list in the report the one line it can
   change to (do not edit `internal/acttest`; it is the viewer's).
3. **The watchdog's folder handed to its child** (pages' 103 a, read it whole in the log): (1) the watchdog
   (`internal/watchdog/exec.go`, `cmd/tgarchive-watchdog/main.go`) puts `TGARCHIVE_WATCHDOG_DIR=<its -dir,
   absolute>` into the child's environment, dropping an inherited value of that name first; (2) the
   collector reads it once at its start and offers one door, `WatchdogDir() (dir string, under bool)`: no
   variable (or an empty or relative one) means "not under a watchdog". Nothing else reads it. Tests: the
   child's environment as built (one value, the inherited one replaced), and the door with and without it.
4. **The reader's skip line for a held read** (the mirror's 124 c): `reader.go`'s `readEndedLine` says "its
   mirror's want has ended" also for a chat whose read is only held while the mirror's switch is off (the
   same field `mirror_ended_at` serves both). Tell the two apart from what is stored (say how; if the stored
   record cannot tell them, stop and say so: no schema step in this piece) and give the held case a line of
   its own, constant format, numbers only. A test for each line.
5. **Two Staging figures from memory** (pages' 118 b): whether making files wanted again is HELD, and how
   many staged copies a reader holds (`HeldNow`), read from memory as `Copier.Load()` is
   (`internal/store/copier.go` `Load`, `wantHeldNow`, `holdSince`), so the page never asks the gauges for
   them. Look at what `Load()` already returns first: if `CopierLoad` already carries both, say so and only
   add what is missing; no file system call, no catalogue read in the new read. A test, including under a
   concurrent hold (the store's own test style; no race detector run).
6. **A deleted account's own-chat mark and read records removed** (K21's follow-up): in
   `internal/catalog/settle.go` `deleteAccountChunk`, the account's settings rows `collector.read.<N>.*` and
   `collector.self_read.<N>` are deleted with the account (find K21's exact key functions on this branch and
   use them, not new strings). Beware LIKE's wildcards (`_` and `%` in a key): use a prefix comparison or
   escape them, and never touch the keys of account 1 when deleting account 10 or the other way round. A
   test: an account deleted, a later account given the same number: its own chat is read by itself again
   (K21's step acts), and another account's keys are untouched.

**Not in this piece:** the mirror's id lists counted under a kind of their own apart from the refresh (it
lives in the mirror's `internal/telegram/mirror_ids.go`, which comes with M6, not merged yet).
**Do not touch:** the download path, `internal/supply`, `internal/engine`, the mirror's files, copies'
files, `internal/viewer`, `internal/acttest`, `internal/server`, `internal/launcher`, `internal/actdoor`,
`livepages`.

`gofmt -l`, `go build ./...`, `go vet` on the packages you changed, and the viewer's `TestWall` by name.

## Hand back

`archiver/docs/progress/core-asks-REPORT.md` (committed) and your last message, the same content, short: the
head and that it is pushed; per point what changed and its test; for point 4 how the two cases are told
apart; the exact names other tracks can now use (and the line for `internal/acttest`); the tests as run;
anything in this brief the code contradicts. Then stop.
