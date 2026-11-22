# Brief M21: the automatic mirror's new-chats rule follows Core's stored download setting (mirror track, M-7, 11-22)

For one Opus 5.5 coder at high effort. Copy `C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-newchats`, branch
`wip/mirror-newchats`, cut from main 09aeba54. Push only it to `private`. Commits: `git -c user.name=Claude -c
user.email=noreply@anthropic.com commit`, ending `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Invented
data only; nothing against Telegram; never open `C:\Users\trabi\tgarchive-app`. Named tests only (no whole
`internal/collector`); Git Bash, `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`;
`GOMAXPROCS=2 GOGC=25 -p=1` (a race run uses 2 CPUs of the PC meanwhile); gofmt, vet.

**Why:** the owner's standing decision "downloads for a chat joined while away: off, only in unlimited hours, always"
is now a stored setting (Core's K28, merged: `internal/collector/newchats_download.go`, `c.mirrorDownload(ctx, cat)`
and `c.newChatsStored(ctx, cat)`); the run's `-auto-mirror-download` / `-new-chats-download` flags stay as "for this
run". K28 lent one line (autoTurn: `opts.Download = c.mirrorDownload(ctx, cat)`). The other places in
`internal/collector/mirror_auto.go` still read the flag only: about lines 279, 327, 355, 367 (`autoLineOn` with
`newChatsStartOff(c.cfg)`, line ~457) and 749 (`c.cfg.AutoMirrorOpts.Download`). Read K28's file and its report
(`archiver/docs/progress/` K28's report, if there) first.

**What:** each of those places takes the value in force now: the run's flag when it was given, else the stored setting
read at the moment of use (through Core's `mirrorDownload` / `newChatsStored`, never a copy of their rule); the start
line says which ("for this run" or "the stored setting"). Fail closed: a stored value that cannot be read is "off"
(no download for a chat the owner did not choose; Core's door already reads it so: check). "Unlimited hours only" is
Core's K20 and refused by Core's set door until then: treat it as Core's door says. Never start a download for a chat
the owner did not choose because of this change: the owner's setting is the choice. Say in the hand-back each place
and what it now reads.

**Tests (named):** the policy with the setting off / on and the flag given / not given; a value set from the door
between two turns holds at the next turn with no restart; the start line's words; an unreadable stored value is off.
**Hand back:** head, files, each place changed, tests by name with lines.
