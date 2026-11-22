# Review M15-R: an independent challenger review of M15, forums mirrored as forums (mirror track, M-7, 11-21)

For one Opus 5.5 reviewer at high effort. You did not write this code. The piece: `wip/mirror-topics` on `private`,
head e54c7163; review `git diff 6aa225fb..e54c7163` (the main head 6aa225fb is merged into it) in the Go module
`archiver/`. What was asked: `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-M15-topics.md`, with its "Fix round T1"
at the end. **This code acts for the owner on Telegram unattended** and adds three kinds of request
(messages.createForumTopic, messages.editForumTopic, the mirror's messages.getForumTopics). The owner's rule: the
mirror goes on by itself while the owner is away; nothing may resend every pause forever (review M4-R finding 2,
`archiver/docs/review/mirror-auto-2026-11-15.md`).

## Where and how
- Your detached copy: `git -C C:\Users\trabi\Claude\Projects\Telegram\repo-archiver fetch private`, then `git -C
  ... worktree add --detach C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-review18-tree e54c7163`. Never edit
  it; prove findings with probe tests in `C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-review18-scratch` loaded
  with `go test -overlay`. Never look into `wt-mirror-m14` or `wt-mirror-topics`.
- Git Bash; `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh` before every `go`;
  `GOMAXPROCS=2 GOGC=25 -p=1`; named tests only; no whole `internal/collector` or `internal/catalog`; no race
  detector; nothing against Telegram; never open `C:\Users\trabi\tgarchive-app`; invented data only. Never push or
  commit.
- Each finding CONFIRMED (a probe shows it) or PLAUSIBLE, file:line, scenario, smallest fix; most severe first.

## Ask by name
1. **Requests:** can any topic create, rename or list read be sent again every turn or every pause (a held topic,
   a retry time in the past, a restart, the clock, the `mirror` command and the task on one catalogue)? Count the
   requests in a day for a refused topic and for a mirror that is not a forum.
2. **Lost creates:** a topic adopted from the list that was not ours (made before the intent, by the owner by hand,
   another topic of the same title); the spares; the 60 s allowance; a list read that fails or is paged.
3. **Forwards into the right topic:** `top_msg_id` per batch; General without one; a message whose topic is
   unknown to the catalogue or whose topic row came later; the per-topic cut with albums, held topics, chosen
   topics, settle put-backs (`c_mirror_again`), M6's adoption waits; oldest first within a topic; nothing starved.
4. **Every reader of `c_mirror_topic` and `c_mirror.forum`**, and of a forum mirror's chat row (kind "forum"): the
   settle, the look, the lost mirror create's search, the new-chats policy (it now covers forums: is a newly
   joined forum still mirrored when the owner's policy says so?), the doors, `-list`, the heartbeat.
5. **Renames:** one edit per change, never when a batch is ready, a refused rename not retried until the title
   changes; titles never in a log (privacy).
6. **The schema step** on a file of the head's version (28) and a read-only older file.
7. **The 13 rules of TRIED-BEFORE sections 24 and 25** (`archiver/docs/TRIED-BEFORE.md`): a table for this change.

## Hand back
The review file at `wt-mirror-review18-scratch\archiver\docs\review\mirror-m15-2026-11-21.md` (what ran, findings,
the 13-rules table, sound, not checked); your final message: one line per finding (CONFIRMED/PLAUSIBLE, file:line)
and the file's path.
