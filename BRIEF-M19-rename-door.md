# Brief M19: a collector door to rename a mirror in the running app (mirror track, M-7, 11-22)

For one Opus 5.5 coder at high effort. Copy `C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-renamedoor`, branch
`wip/mirror-renamedoor`, cut from main e34f4f64. **Only NEW files** (e.g. `internal/collector/mirror_rename_door.go`
and its test), plus at most one line in `words.go` for new sentinels: two other coders change `mirror_door.go`,
`auto.go` and `topic.go` now. Push only your branch to `private`. Commits as in CLAUDE.md (`git -c user.name=Claude
-c user.email=noreply@anthropic.com commit`, ending `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`).
Invented data only; nothing against Telegram; never open `C:\Users\trabi\tgarchive-app`. Named tests only (no whole
`internal/collector`); Git Bash, `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`;
`GOMAXPROCS=2 GOGC=25 -p=1`; gofmt and vet.

**Why:** the pages track (P7, audit row 87): renaming a mirror exists only as `mirror -rename` with the collector
stopped; the owner needs it in the running app. (Gather already has doors: `MirrorGather` / `SetMirrorGather`.)

**What:** `func (c *Collector) MirrorRenamePlan(ctx, account, sourceChat int64, title string) (MirrorRenamePlan, error)`
(catalogue only: the mirror row, its current name, the new one checked as `mirror -rename` checks it, the cost "1
request: channels.editTitle", or a refusal) and `func (c *Collector) MirrorRename(ctx, account, sourceChat int64,
title string) (MirrorRenameResult, error)`: exactly what `mirror -rename` does through `internal/mirror/rename.go`
(the owner's own action; one `channels.editTitle` through the running collector's forwarder and its request loop; a
stated wait slept in full and said; "not modified" counted as done; an unknown outcome said, safe to run again; the
mirror's name on its ledger row and the mirror chat's title written together). Never by anything automatic; one
mirror per call; refused while the account's run holds a wait for that kind, or the account is signed out or
frozen. Fixed-word refusals as sentinels (on `words.go`'s list). Read `internal/mirror/rename.go` and the command's
`mirror -rename` path first and reuse them; do not duplicate their rules.

**Tests:** plan and rename on the fake (a title changed, not modified, a wait, no answer, a refusal, no mirror for
the chat, a forum mirror), the catalogue written together, the request counted once. **Hand back:** head, files, the
door names, results and refusals (for pages' words), the cost, tests by name.
