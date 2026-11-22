# Review M17-R: an independent challenger review of M17 (mirror track, M-7, 11-22)

For one Opus 5.5 reviewer at high effort. You did not write this code. The piece: `wip/mirror-topicpace` on
`private`, head 16b96510, cut from main e34f4f64: review `git diff e34f4f64..16b96510` in `archiver/`. What was
asked: `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-M17-topic-titles-pace.md` (all of it, points 1 to 14).
**This code sets how fast the app writes to Telegram for the owner, unattended:** an adaptive forward pace (3 s + 0-2 s,
a quarter shorter after 10 clean requests, floor 1 s, doubled and held for an hour on any stated wait) shared by
every forward path; topic creates on their own 3 to 5 s clock; mirror creates and ordinary renames keep 20 s; never
two writes in one second; mirrors take turns with new posts (under 24 h) first; topic titles held for Core's reader up
to a stored 30 min, then "Topic N" and renamed; the per-hour bound a setting (10,000 messages). On record
(`archiver/docs/TELEGRAM-FACTS.md` section 11): a 20 s pause brought no wait; a 10 s pause brought a 9 s wait after 200
messages in 13 s. The rules it must keep: every stated wait slept in full, no request before it ends; nothing sent
every turn forever; the account's other writes (the owner's clicks, creates) never starved.

## Where and how
Detached copy: `git -C C:\Users\trabi\Claude\Projects\Telegram\repo-archiver fetch private`; `git -C ... worktree add
--detach C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-review21-tree 16b96510`. Never edit it; probes in
`C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-review21-scratch` via `go test -overlay`. Git Bash; `source
/c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`; `GOMAXPROCS=2 GOGC=25 -p=1`; named tests only;
no whole `internal/collector` or `internal/catalog`; nothing against Telegram; never open `C:\Users\trabi\tgarchive-app`;
never push or commit. Findings CONFIRMED (probe) or PLAUSIBLE, file:line, smallest fix, most severe first. Remove your
worktree copy at the end; keep the review file in the scratch folder and say its path.

## Ask by name
1. **Waits:** can any write go before a stated wait ends (of its own kind, or another kind's on the same account);
   after a wait, is the pace really doubled and held for the hour across a restart; is the 1 s floor ever crossed;
   two writes in one second?
2. **Every forward path** (the task, the `mirror` command, "Mirror this chat", adopted chats, a settle's put-back
   batches) takes the shared pace from one place; `-pause` override exact; the stored `mirror.pause.N` (the old
   pause) unreadable: does it stop the automatic task (the hand-back says it still stops a command's run)?
3. **Starvation and order:** new posts first across mirrors; one forum's backlog never starves the others; the
   owner's clicks and mirror creates still get their turns; out-of-order counted.
4. **Topics:** the title hold (never for ever; the stored wait; "Topic N" then renamed at the topic pace); the
   mirror chat's topic rows; a held topic re-held once a minute (the hand-back's minor point: cost?).
5. **Settings:** each read at use, unreadable default said, no upper bound of the app's own, the per-hour bound's
   floor of 100 (is that the app's own bound?), doors and flags; `ChatState.MadeAt`.
6. **Requests in a day** for a big backlog at the floor (the bound per hour binding) and for a stated-wait storm.
7. **The 13 rules of TRIED-BEFORE 24 and 25**: a table.

## Hand back
One line per finding (CONFIRMED/PLAUSIBLE, file:line), "may be listed" or not, and the review file's path.
