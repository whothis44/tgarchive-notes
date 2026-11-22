# Review M16-R: an independent challenger review of M16 (mirror track, M-7, 11-22)

For one Opus 5.5 reviewer at high effort. You did not write this code. The piece: `wip/mirror-settle` on `private`,
head 01dcfc82, cut from main e34f4f64: review `git diff e34f4f64..01dcfc82` in `archiver/`. What was asked:
`C:\Users\trabi\Claude\Projects\Telegram\BRIEF-M16-settle-by-itself.md` (read it; also the hand-back's design is
summarised below). **This code acts for the owner on Telegram unattended**: after a batch of unknown outcome the
automatic mirror now settles by itself instead of waiting for the owner. The two rules it must never break: **never
forward a message twice** (the settle's evidence from the mirror chat first), and **never send every pause or
turn forever** (review M4-R finding 2, `archiver/docs/review/mirror-auto-2026-11-15.md`).

Design as built: before a put-back message is sent again, one `channels.getMessages` id list asks the SOURCE (gone
ones marked deleted, never sent again); then a ladder: whole, halves, alone, set aside after 4 sends or 2 nameless
alone; the put-back messages' next send backs off (10 min ... 6 h) from a settle streak (`MirrorPutBackStreak`), while
NEW posts go meanwhile in their own batches (`MirrorCandidatesFresh`; never mixed); a repeat after a settle and
"cannot tell" messages set aside; a refused or failed mirror read held on a back-off (durable from the reader's
refusal record); a lost create with two or more channels of the name all made after the intent: the oldest adopted;
none found an hour after the create: recorded not made and created again after a back-off; the old blocks
(AutoBlockAgain and the others) cleared by themselves at the next turn; the settle reads the app's own mirror chat
past an owner's read estimate (`collector/mirror_auto.go`); a new table `c_mirror_putback` (schema step).

## Where and how
Detached copy: `git -C C:\Users\trabi\Claude\Projects\Telegram\repo-archiver fetch private`; `git -C ... worktree add
--detach C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-review20-tree 01dcfc82`. Never edit it; probes in
`C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-review20-scratch` via `go test -overlay`. Git Bash; `source
/c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`; `GOMAXPROCS=2 GOGC=25 -p=1`; named tests only;
no whole `internal/collector` or `internal/catalog`; no race detector unless CPU allows; nothing against Telegram;
never open `C:\Users\trabi\tgarchive-app`; never push or commit. Mark findings CONFIRMED (probe) or PLAUSIBLE, with
file:line and the smallest fix, most severe first. Remove your copy and scratch at the end.

## Ask by name
1. **Twice:** can any path forward a message that is already in the mirror (a settle read that missed it, a slow
   forward, the ladder's re-sends, a lost create adopted as the oldest of several, "created again" after a lost
   create none was found for, a restart between a send and its settle, the `mirror` command beside the task)?
2. **Forever:** count requests in 24 h and 7 days for the worst cases (every forward nameless; the source id list
   failing; the mirror read refused; a lost create never found); can any path send every turn or pause?
3. **Lost or wrongly set aside:** can a message that exists and was never forwarded be set aside or marked deleted
   wrongly (an id list answer that does not name every id, a basic group source, a source of another account,
   a message edited); can new posts be starved?
4. **The old blocks clearing themselves:** only the settle's own words, never a block the owner set or another
   track's; the owner's word on record respected.
5. **The read past an estimate:** what it costs at most for a mirror chat with a long history (an adopted chat);
   whether it can read a chat that is not the app's own mirror.
6. **The schema step and readers** of `c_mirror_putback`; a read-only older file.
7. **The 13 rules of TRIED-BEFORE 24 and 25** (`archiver/docs/TRIED-BEFORE.md`): a table.

## Hand back
The review file `wt-mirror-review20-scratch\archiver\docs\review\mirror-m16-2026-11-22.md` (keep it until the
session copies it: say its path), and in your final message one line per finding (CONFIRMED/PLAUSIBLE, file:line),
"may be listed" or not.
