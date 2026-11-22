# Review M14-R: an independent challenger review of M14 (mirror track, session M-7, 11-21)

For one Opus 5.5 reviewer at high effort. You did not write this code and have not seen its author's reasoning;
read the code, not a summary. The piece: `wip/mirror-m14` (remote `private`), the difference
`git diff af4ca40e..wip/mirror-m14` in the Go module `archiver/`. Its brief (what was asked):
`C:\Users\trabi\Claude\Projects\Telegram\BRIEF-M14-deleted-and-singles.md`: read it first.

**This code acts for the owner on Telegram, unattended** (the automatic mirror forwards new posts of chosen
chats into mirror channels while the owner is away). A wrong block stops saving posts that are deleted minutes
later; a wrong "no block" can send a refused batch again and again (review M4-R finding 2,
`archiver/docs/review/mirror-auto-2026-11-15.md`, read it and its 13 rules table).

## Where and how
- Make a detached copy for yourself: `git -C C:\Users\trabi\Claude\Projects\Telegram\repo-archiver worktree add
  --detach C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-review17-tree <head of wip/mirror-m14>` after
  `git fetch private`. Never edit it; prove findings with probe tests in a scratch folder
  `C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-review17-scratch` loaded with `go test -overlay`.
- Git Bash; `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh` before every `go` command;
  `GOMAXPROCS=4`. Named tests only (`-run`); no whole run of `internal/collector` or `internal/catalog`; no race
  detector; no Docker. Nothing runs against Telegram; never open `C:\Users\trabi\tgarchive-app`; invented data only.
- Mark each finding CONFIRMED (a probe shows it) or PLAUSIBLE (by reading), with file:line, a scenario and the
  smallest fix. Most severe first.

## Ask by name (the questions a reviewer found useful before on this track)
1. **Every later reader of what M14 writes:** a `refused` batch row that now has `missing` forward rows and a
   non-zero `missing` count. Grep the whole module: the settle (`act_settle.go`, `auto.go` settle), 
   `MirrorBlockingBatch`, the doors' and pages' counts, `-list` and report lines, `MirrorNewestForwarded`, the
   candidate filter, the again-table (`c_mirror_again`), the manual `mirror` command's run (`step.go`). Does any
   of them count, settle, block, or put back such a row wrongly?
2. **The hold and the block are read from the ledger:** which batch row is "the previous batch" (by id? per
   mirror?); what if the newest row is still `sending`, `unknown`, `already`, a settle's batch, or the hold's
   end has passed while the account is in a stated wait; what after a restart; whether two programs on one
   catalogue (the collector and the `mirror` command) can see different states.
3. **Can any refused batch now be sent again more than once, or forever?** Try MESSAGE_ID_INVALID with
   unexplained messages that alternate with done batches; the 3-in-24-hours count; a refusal of another type
   (it must block at once, as before); a batch of put-back messages (`Again`, a random id's `Attempt`) refused
   MESSAGE_ID_INVALID.
4. **Telling the error apart:** is it Telegram's error type only, never fixed words that another path writes;
   does a MESSAGE_ID_INVALID that is "outcome unknown" or wrapped differently go the right way.
5. **The singles' wait:** an album member never goes at the single's wait (album 0 only; a first part read
   before the rest has its album already?); the cut "everything from the first young candidate on waits" and
   `youngAt`; the gathering on top; the random part keyed so repeated turns see the same time; `Steady`.
6. **The setting:** format and read (exactly what the writer writes; spaces, signs, leading zeros, overflow);
   unreadable is the default in force and SAID (log once, event, door facts); the run's flag over the stored
   value; set from the door refused while the flag holds it; no upper bound of the app's own.
7. **The 13 rules of TRIED-BEFORE sections 24 and 25** (in `archiver/docs/TRIED-BEFORE.md`): a table, each met
   or broken, for this change.
8. Requests: no new kind of Telegram request; the one re-send counted as every forward is.

## Hand back
Write the review to `archiver/docs/review/mirror-m14-2026-11-21.md` IN YOUR SCRATCH FOLDER (not in the tree):
what ran, the findings, the 13-rules table, what was found sound, what was not checked. Your final message: the
findings in short (one line each, with CONFIRMED/PLAUSIBLE) and the path of the review file.

## Added: Part C (exact repeats; the brief's last section) and its schema step
9. **An exact repeat skips a message: the one place in M14 where a message is NOT forwarded by choice.** Is
   the evidence exact in every case (sender, text with NULL and empty, the media SET, the same mirror, only
   `forwarded` rows); can a first instance ever be skipped (two candidates of the same content in one turn, an
   earlier copy still `sent`, `unknown`, put back by a settle, or `missing`); an album skipped only whole; a
   message with no text and no media never a repeat.
10. The new table and step: the step on a file of the head's version; a read-only handle on an older file;
   every query that reads candidates or counts them (the filter in `candidateFilter`, `againSQL`, the count)
   leaves repeats out consistently; `EXPLAIN QUERY PLAN` of the lookups (no scan of `message` or `attachment`).
11. **Fix round A2 (the brief's last section):** a refusal is judged from `deleted_at` at the moment of judging,
   never at the refusal alone; the block only on the same message refused twice while still not known deleted,
   or 3 unexplained-now in 24 hours. Try the races: two different posts refused before their deletions are
   recorded; a deletion recorded during the hold; a restart in the hold; a message refused, then forwarded
   (it was not deleted after all), then never counted again.
