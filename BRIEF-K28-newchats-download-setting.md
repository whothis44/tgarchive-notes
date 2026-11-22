# Brief K28: "downloads for a chat joined while away" as a stored setting (Core, K-6, 2026-11-22)

**Why:** the owner's standing decision (CLAUDE.md, the mirror): downloads of a chat joined while away are a setting
with three values: off, only in hours without the speed limit, always. Today "off" and "always" exist only as start
flags for one run (`-new-chats-download`; the mirror's `-auto-mirror-download`), and the app's Settings page (pages,
P7; audit row 88) has nothing to set. "Only in unlimited hours" is K20, not built yet.

**Rules:** you are the one Opus coder. Named tests and small packages only; never the whole `internal/collector` or
`internal/catalog`; every go command through `bash /c/Users/trabi/Claude/Projects/Telegram/runs-core-k5/go2.sh <folder> ...`.
Invented data only; nothing against Telegram (the fake only); never touch a running program, the main copy,
`C:\Users\trabi\tgarchive-app` or `E:\`. Copy `wt-core-newdl`, branch `wip/core-newdl` from
`private/claude/charming-feynman-vm2xia` (the newest). Commit form as always; push only your branch.

## What to build
1. **The setting:** one catalogue key (name it; per catalogue, not per account, unless the code shows the flags are
   per account: say which), values `off` (default), `unlimited`, `always`. A check, a read that refuses a stored
   value it cannot read (fail closed: an unreadable value means `off`, said once), the form of
   `internal/mirror/autonew.go` `ListEveryKey`/`CheckListEvery`/`ReadListEvery`.
2. **Doors in the collector** for pages, in the form of `MirrorListEvery`/`SetMirrorListEvery`: read (the value,
   stored or default, unreadable, **and the list of values this build accepts**: `off` and `always` now); set (refuses
   a value not accepted, in fixed words, writes nothing). When K20 lands, it adds `unlimited` to the accepted list;
   leave one clear place for that.
3. **Its effect, read at the moment of use** (each turn, so a page's change holds without a restart): where the
   collector reads `-new-chats-download` (`internal/collector/chosen.go`, `internal/catalog/chosen.go`'s
   `SetNewChatsChosen` and the rows it makes) and, as a LENT line asked by the mirror (M-7), in
   `internal/collector/mirror_auto.go` where the task reads `*f.download` (`-auto-mirror-download`) into
   `mirror.AutoOptions.Download`: the stored setting decides; a flag given at the start counts as "for this run"
   over it. In the mirror's file keep the change to that one place and its test; M17 adds three flags in the same
   file at the same time (whoever merges second keeps both).
4. Nothing changes for a chat the owner chose or switched off by hand: the setting is only about chats joined while
   away.

## Tests (each seen failing first)
Default off: a newly joined chat is mirrored and nothing of it downloaded; set to always: its files are wanted; set
back to off mid-run: the next joined chat downloads nothing (no restart); `unlimited` refused with its words; an
unreadable stored value means off and is said once; a flag at the start wins for that run; the mirror's task reads it
each turn (its test by name). gofmt, build, vet the changed packages; the viewer's `TestWall`.

## Hand back
`archiver/docs/progress/core-newdl-REPORT.md` and your last message, short: head pushed; the key and the doors' exact
names (for pages and the mirror); the lent line in `mirror_auto.go` quoted; the tests as run.
