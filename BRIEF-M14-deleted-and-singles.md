# Brief M14: a message deleted at the source never blocks a mirror; single posts go 5 to 20 s after they appear

Mirror track, session M-7, 11-21. For one Opus 5.5 coder at high effort. Copy `C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-m14`
(branch `wip/mirror-m14`, cut from the main head af4ca40e; Go module in `archiver/`). Commit work in progress to
that branch as you go and push it to the remote `private` (`git push private wip/mirror-m14`); never any other
branch. Commits: `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, the message ending with
`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. No archive numbers in messages.

**Rules (CLAUDE.md in the project folder holds all of them):** nothing runs against Telegram; tests use the
fake Telegram and invented data only. Never open the owner's folder `C:\Users\trabi\tgarchive-app` or its
catalogue. **Tests: only named tests (`go test -run 'X|Y' ./internal/mirror/`) and the one small package you
change; no whole-package run of `internal/collector` or `internal/catalog`, no race detector, no `go vet` over
many packages.** The full runs happen once, later, by the session. Environment: `source
/c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh` before every `go` command in Git Bash (the
toolchain 1.27.3 with its added line). Keep the PC's load modest (`GOMAXPROCS=4` for tests, `GOGC=25` for builds).

## Why (the first real run, 11-21, counts from the owner's catalogue read by the session)

The owner's automatic mirror stopped by itself: "Blocked: batch refused: MESSAGE_ID_INVALID". Mirror 4 sent a
batch of 12 at 18:07:00: answered, 11 forwarded, 1 missing (deleted at the source; `ForwardResult.Missing`
handles that). Then a batch of 1 at 18:08:43: refused MESSAGE_ID_INVALID. The catalogue recorded that message as
deleted at 18:08:50, 7 s later (the live monitor). `internal/mirror/auto.go` `forward` blocks the want on ANY
refused batch (review M4-R findings 2 and 4, `docs/review/mirror-auto-2026-11-15.md`: before that fix a refused
batch was sent again every pause, forever). The chat stayed blocked until the owner clicked Allow about three
hours later. The source deletes each post minutes after posting the next one; 38 media messages were deleted
before they were saved. Their lifetimes: 3 lived 20 s or less, 11 lived 90 s or less, 26 over 120 s; median 196 s.
That chat posts about 25 posts an hour (61 singles, 17 albums in 3.1 hours); median gap between posts 69 s;
17 of 77 gaps under 30 s.

Evidence, one case each ("looks like"): a batch with SOME messages deleted is answered and the deleted ones come
back as missing; a batch whose EVERY message is deleted is refused MESSAGE_ID_INVALID.

The owner: "the whole point of the feature is that it functions when the owner is away from the computer, so
this should not occur." And on the wait, 11-21 21:05 amended 21:07: "make it a setting, but default to the
recommended times" (5 to 20 s for single posts).

## Part A: MESSAGE_ID_INVALID on a forward (auto path only)

Read first: `internal/mirror/auto.go` `forward` (line ~1462) and `mirrorTurn`, `step.go` `forwardOutcome` and
`rpcWord`, `internal/catalog/schema13.go` `FinishMirrorBatch`, `MirrorCandidates` and `candidateFilter` (a message
with `deleted_at` set is never a candidate; one with a ledger row of any state neither), `act_settle.go` (the
settle reads `deleted_at` too).

The design (the session's; ask on nothing, but say in the hand-back where you found it wrong):

1. **The refusal is told apart only by Telegram's error type** `MESSAGE_ID_INVALID` (tgerr type of `ferr`, not a
   string match on fixed words), on a batch whose state is `BatchRefused`. Every other refusal blocks exactly
   as today.
2. **Known deleted become missing.** On that refusal, read from the catalogue (no request) which of the batch's
   source messages have `deleted_at` set (a new read in the mirror's catalogue files, e.g.
   `MirrorDeletedAmong(ctx, sourceChat, ids) (map[int64]bool, error)`, one query per up to 200 ids as
   `MirrorMessageTimes` does). Record the batch's end as `refused`, reason `MESSAGE_ID_INVALID`, with those as
   `Missing`: `FinishMirrorBatch` is changed so that for `BatchRefused` the rows named in `e.Missing` are set to
   `missing` (each must be in the batch, as for done) and the others are deleted as before (candidates again);
   the batch row's `missing` column is their count. For every other state the function behaves as now; `Missing`
   on waited/unsent/unknown/already is `ErrBadLedger`. **No schema step** (the columns and CHECKs allow it).
   Check EVERY reader of `c_mirror_batch` rows in state `refused` and of `c_mirror_forward` rows in state
   `missing` (grep the whole module: the settle, `MirrorBlockingBatch`, the doors' and pages' counts, the
   `-list` and report lines, `MirrorNewestForwarded`, the candidate filter, the adoption code of M6 is NOT on
   this branch) and say in the hand-back what each does with a refused batch that now has missing rows.
3. **Every message explained (missing count = batch's messages): no block.** An event with fixed words
   (e.g. `AutoEvDeletedAtSource` "a batch was refused because its messages were deleted at the source: recorded
   as missing; the mirror goes on"); the turn ends as it does after any batch; the task goes on. Not counted in
   `Numbers.Blocked`.
4. **Not every message explained: no block the first time.** The unexplained ones are candidates again (rows
   deleted, as for any refusal). **That chat sends nothing until the refusal's end plus `AutoRecheck` (60 s, a
   constant: the time for the live monitor to record a deletion; it recorded this one 7 s after the
   refusal),** read in `mirrorTurn` from the mirror's newest batch row (its state, reason, messages, missing,
   ended_at), so that it holds across a restart; `tr.wake` at that moment; other chats of the account are not
   held. An event with fixed words. At the next batch, the messages now known deleted are no longer candidates
   (the filter), so they are never sent again.
5. **Blocked only on evidence:** a MESSAGE_ID_INVALID refusal with unexplained messages blocks the want when
   (a) the mirror's previous batch (by id) was also a MESSAGE_ID_INVALID refusal with unexplained messages, or
   (b) it is the third such refusal of that mirror in 24 hours. Block words, fixed, that say what was seen, e.g.
   "batch refused twice in a row: MESSAGE_ID_INVALID for messages the catalogue does not know as deleted" and
   "batch refused 3 times in 24 hours: MESSAGE_ID_INVALID for messages the catalogue does not know as deleted"
   (no apostrophes: the ledger's words; `fixedOK`). So a refused batch can never be sent again every pause
   forever (the M4-R finding 2 stays fixed): at most one re-send after a refusal, at most 3 in a day.
6. **Requests:** no new kind of Telegram request. The one re-send is an ordinary forward, counted by the
   forwarder's stats as every forward is. The account's pause, its random part and Telegram's stated waits are
   untouched.
7. The manual `mirror` command (`step.go`'s run) is not changed, except as `FinishMirrorBatch` must keep working
   for it (it never passes Missing on a refusal).

## Part B: single posts wait 5 to 20 s, a stored setting

Read first: `internal/mirror/timing.go` (Vary, `spread`, `youngExtra`, `candKey`, gathering),
`autoBatch` in `auto.go` (the cut at the first young message, albums held whole), and the whole of M12's setting,
the pattern to copy exactly: `internal/mirror/newperday.go`, its run flag and lines in
`internal/collector/mirror_auto.go` (`-auto-mirror-new-per-day`, `autoLineNewPerDayBad`, `NewPerDayInForce` asked
at the moment of use), the doors `MirrorNewPerDayFacts` / `SetMirrorNewPerDay` in `internal/collector/mirror_door.go`,
and their tests.

1. **A single post** is a candidate with `Album == 0`. It goes once it is `low + r` seconds old on the clock
   (`MirrorMessageTimes`: the later of its Telegram date and the account's first sighting), `r` = a random whole
   number of seconds from 0 to `high - low` drawn with `spread` under a new label (e.g. `varySingle`), keyed by
   the message, so that repeated turns see the same time. With `Steady` (no Vary): `low`. **An album's members
   keep today's rule unchanged** (`AutoYoung` 90 s plus 0 to 30 s, keyed by the album): albums still wait until
   they are whole. The cut stays "everything from the first young candidate on waits" (oldest first; an album
   whole), and `youngAt` is that candidate's own moment plus a second. The gathering (`GatherKey`) is unchanged
   and still applies on top.
2. **The setting:** catalogue key `mirror.auto.single_wait`, one for the catalogue, stored as `LOW-HIGH` in
   whole seconds in decimal (e.g. `5-20`), exactly what the format function writes. **Default 5 to 20 s (the
   owner's).** Bounds: `0 <= low <= high`; **no upper bound of the app's own** (the owner, on another cap: "the
   maximum of 50 is dumb"); refuse only what cannot be a time (a value whose seconds overflow a `time.Duration`).
   Fixed-word range error fit for a page. A stored value that cannot be read: the default 5 to 20 s is in force,
   and it is SAID (an event, a log line once like `autoLineNewPerDayBad`, and the door's facts say "cannot be
   read"). Reason for the default rather than a careful slower value: the slower value is what lost posts on
   11-21, and the default is the owner's choice.
3. **Doors for the pages track** in `internal/collector/mirror_door.go`: `MirrorSingleWaitFacts` (in force low
   and high, stored or default, unreadable, set by the run's flag) and `SetMirrorSingleWait(low, high)` (refused
   while the run's flag holds it, as for the cap), following `MirrorNewPerDayFacts` / `SetMirrorNewPerDay`
   field by field. The Settings page's row is the pages track's (the session writes it on the board).
4. **The run's flag** `-auto-mirror-single-wait LOW-HIGH` on the collector's run (for this run, the stored
   setting then not read), with its start line, as `-auto-mirror-new-per-day`. Read at the moment of use each
   turn so a value set from a page holds from the next turn with no restart.

## Tests (named, in `internal/mirror` and the collector's door/flag tests by name)

At least: an all-deleted batch (fake answers MESSAGE_ID_INVALID; the catalogue knows them deleted) ends with
missing rows, no block, the next turn sends the next candidates; a refusal with one message not known as deleted
holds that chat for 60 s, then (deletion recorded meanwhile) sends the rest and never that one, no block; the
same refusal twice in a row blocks with the words; three in 24 hours with a done batch between blocks; any other
refusal type still blocks at once; across a restart (a fresh AutoState) the 60 s hold still holds; a single post
goes at 5 to 20 s, an album at 90 to 120 s, a single behind a young album waits for it; the setting's format,
read, bad value (default in force and said), set, run flag over stored, the door's facts. Check the fake
Telegram's forward answer (`internal/collector/faketg`, the mirror's answers): all-deleted batch → refused
MESSAGE_ID_INVALID, some deleted → answered with those missing; make it so if it is not.

## Hand back (in your final message; the session reads the risky part itself)

Commits on `wip/mirror-m14` pushed to `private` (the head's id); the files changed; for Part A the list of every
reader of refused batches and missing rows and what each does now; the named tests run with their result lines
(counts and times only); what you did not do or found wrong in this brief. gofmt your files. Do not run the full
packages.

## Part C (added 11-21 evening, the owner through the integrator): an exact repeat is not forwarded again

Why: the 38 "lost" posts were not unique. All 40 deleted media messages in mirror 4's source came from ONE
sender with ONE identical media set (a bot that posts a message and deletes it soon after); the same media is
already saved once. Mirror 3's source shows the same shape with text. The owner: "Is there a way to detect that
and avoid flooding our mirrored chat with it?" With Part B's 5 to 20 s wait, without Part C the bot's message
would be forwarded every time it is posted. **Part C must ship with Part B.**

1. **Exact repeat:** a candidate whose source message has the same sender (`message.sender`), exactly the same
   text (`message.text`, NULL and empty the same), and exactly the same SET of Telegram media (`attachment`'s
   `tg_media_id`, the catalogue's id of the Telegram file) as an earlier source message of the same source chat
   that has a ledger row of state `forwarded` in the SAME mirror. With no media: the same sender and the same
   non-empty text. A message with neither media nor text is never a repeat. `sent`, `missing` and other states
   do not count as "already forwarded". This is exact evidence (the rule "only exact evidence may skip"); the
   first instance is always forwarded.
2. **Albums:** an album is skipped only if EVERY one of its members is an exact repeat; else the whole album
   goes as today (never split).
3. **Recorded, counted, never a block:** a repeat is recorded in a new table (e.g. `c_mirror_repeat(mirror_id,
   src_msg, same_as, seen_at)`, `PRIMARY KEY(mirror_id, src_msg)`, WITHOUT ROWID; `same_as` the forwarded source
   message it repeats), written in the turn's catalogue work before the batch is cut, and the candidate filter
   (`candidateFilter`, `againSQL`, the count `filter`) leaves recorded repeats out, so they never fill the front
   of the candidates. A file without the table (a read-only handle on an older file) reads as having no
   repeats (as `hasLedger` / `hasAuto` do). **This is a schema step: the step after the head's (af4ca40 is at
   26 with `schema_edgelog.go`), a new file `schema_mirrorrepeat.go`, the number in two constants, as every
   branch does; the integrator sets the number at the merge** (the session writes it on the board's schema
   section). Only a new table and its use: no change to `c_mirror_forward`'s CHECK.
4. **Count:** repeats per turn in `TurnResult` (an event with fixed words and a number), the mirror's total
   in the doors' facts per mirror (a field the pages track can show: "N exact repeats not forwarded"), and in
   `-list`'s line for the mirror if there is one. No sender rule that holds or skips anything without exact
   evidence: the "sender whose messages are almost all deleted soon" idea is at most a count, and not built
   in M14.
5. **Cost:** catalogue reads only, no request. The lookup must use indexes (`attachment_media(tg_media_id,
   message_id)` for media: the messages that carry the candidate's first media id, then the whole set, sender
   and text compared; for text-only candidates, which only arise with "all messages", compare with the
   mirror's forwarded rows joined to `message`, bounded and said). Show `EXPLAIN QUERY PLAN` in the hand-back:
   no scan of `message` or `attachment` per turn.
6. **Tests:** the bot's case (the same media and caption posted five times by one sender, each deleted later:
   the first forwarded, the next four recorded as repeats, no block); a different sender with the same media
   goes; the same sender with a different caption goes; one media more or less goes; an album with one member
   new goes whole; a repeat of a message still `sent` (in flight) goes; across a restart the recorded repeat
   stays out; an older file without the table works read-only; the schema step on a file of the head's version.

## Fix round A2 (the session, after the hand-back of fa769c57): judge a refusal after the hold, not at it

The coder's own finding 1, confirmed by the session's read of `idRefused`: the block is decided at the moment
of the refusal, on what the catalogue knows then, and the refused batch's unexplained rows are deleted, so a
refusal can never be found explained later. This chat's bot deletes its message 30 to 49 s after posting
(mirror 3's chat, median); with single posts at 5 to 20 s, a forward can race a deletion, and two such races in
a row (two different posts, each refused before the live monitor records its deletion, which took 7 s once)
would block the chat: the very stop M14 exists to end. So:
1. **Keep the unexplained messages of a MESSAGE_ID_INVALID refusal on record** in a small table in the SAME
   schema step as `c_mirror_repeat` (e.g. `c_mirror_idrefused(mirror_id, batch_id, src_msg, PRIMARY
   KEY(batch_id, src_msg))` WITHOUT ROWID, with an index or key that reads a mirror's rows by message). The
   ledger rows are still deleted (the messages are candidates again, as now).
2. **Never block at the moment of the refusal.** Every message explained at once: as now (missing, no hold).
   Else: the 60 s hold, always, as now.
3. **Judge "unexplained" NOW, never from counts written at the refusal:** a refusal is unexplained only if one
   of its recorded messages is still not known as deleted when it is judged (read `deleted_at` at that moment).
4. **The block, on evidence:** (a) **the same message refused twice:** a MESSAGE_ID_INVALID refusal whose
   unexplained-now messages include one that an EARLIER refusal of the same mirror also recorded and that is
   still not known as deleted; or (b) **3 refusals of the mirror in 24 hours that are unexplained now.** Judged
   when a refusal comes back (its own messages may still be unknown: that alone never blocks) and again at the
   hold's end before the chat's next batch (in `mirrorTurn`), so that a deletion the monitor recorded in the
   meantime explains it. The block's words say which (fixed words, as now). Drop "the previous batch by id"
   ("twice in a row" of different messages): it is what raced.
5. A refusal found explained at the hold's end: counted as explained (the doors' facts and the event as for
   one explained at once); the batch row's `missing` count may stay as it was written (say what you chose).
6. Tests: two different posts each refused before their deletion is recorded, the deletions recorded within
   the hold: no block; the same post refused twice while not known deleted: blocked with the words; three
   different posts in 24 hours never recorded deleted: blocked; a restart between the refusal and the hold's
   end keeps the record. Also re-run `TestMirrorM14RepeatPlan` after the ORDER BY change (not run since).
Hand back as before (the new head, what changed, the tests by name with their lines).

## Fix round R1 (the independent review M14-R of 5ea2f7be; its file:
`C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-review17-scratch\archiver\docs\review\mirror-m14-2026-11-21.md`,
its probes `zz_probe_m14r_test.go` and `overlay.json` beside it). Read the review first. All ten are to be fixed:
1. **(CONFIRMED) An Allow is undone with nothing sent** (`idHold`, auto.go ~1598-1636): each refusal is judged
   for a block ONCE (mark it judged, durably, e.g. a column or row in the step's tables, or the batch row's state
   of judgement); after the owner's Allow the chat gets at least one more send, as before M14. The same for the
   3-in-24-hours block: a refusal that has already caused a block never counts toward another.
2. **(CONFIRMED) An album still arriving is split by the repeat check:** album members are judged for repeats
   only after the young cut (an album that is young or held is not looked at); an album is a repeat only when
   whole and every member a repeat.
3. **(CONFIRMED) A refusal whose message was later forwarded or answered missing still counts:** a later
   `forwarded` or `missing` forward row of the same mirror for that message explains it (with `deleted_at`).
4. **(CONFIRMED) The last read after the rounds of repeats is not checked:** check every read that can go, or
   send nothing this turn when the rounds run out (said by an event).
5. **(CONFIRMED) A MESSAGE_ID_INVALID refusal with no record in `c_mirror_idrefused` reads as explained** (every
   refusal before the step): no record means "cannot be judged": nothing rewritten, no "deleted at the source"
   event, no hold, no block from it (as before M14 such a refusal has already blocked the chat or been allowed).
   Fail closed means never claiming an explanation that is not on record.
6. The settle reads only `done` batches' `missing` rows as "the copy may be anywhere" (refused batches' missing
   rows have no copy).
7. Only the automatic task's refusals are recorded in `c_mirror_idrefused` (the manual command's own tries
   neither hold the automatic chat nor count toward its blocks): a field on `MirrorBatchEnd` the turn sets.
8. The doors' facts per mirror: refusals explained (at once and at the hold's end), held now (until when),
   repeats; a held chat shows as held, not as forwarding.
9. Wording: `mirror_timing_cmd.go` (~65, ~152, ~215) and the misplaced comment in auto.go ~510-526.
10. Cost: the media lookup reads only messages of the SAME source chat (the candidate's space), not every
    message in the catalogue carrying that media; keep it indexed (show the plan).
Tests: one per finding, each failing before the fix (the review's probes may be ported as tests). Named tests
only. Hand back the new head and the tests by name with their lines.

## Fix round R1b (the owner, 11-21, on reading the review: "why does the owner need to allow a mirror ... The
## owner will be away from the computer. Why wouldn't the mirror continue automatically? That's the whole point.")
Replace every block of a chat's automatic mirror that a retry or a skip of one message can settle. **A chat's
mirror never waits for the owner's Allow because of one message, and never stops for good on a refusal that may
pass.** In detail, on top of R1:
1. **A message that cannot be forwarded is set aside, the chat goes on.** Where R1 would block the want for
   MESSAGE_ID_INVALID (the same message refused twice while not known deleted, or 3 in 24 hours), and for any
   other refusal that names messages rather than the chat (e.g. MEDIA_EMPTY, MESSAGE_ID_INVALID of any kind, a
   media type the mirror cannot take): the refused batch's messages go once more ALONE (each its own batch, so
   one bad message does not hold good ones); a message refused again is recorded as "set aside" (a ledger
   state or a row of the step's table, with the refusal's type), never sent again by itself, counted and listed
   for the pages ("N messages set aside: Telegram refused them"); the chat's other messages go on. No block.
2. **A refusal of the mirror chat itself (writes refused, the mirror chat not reachable, rights removed:
   CHAT_WRITE_FORBIDDEN, CHAT_SEND_MEDIA_FORBIDDEN, CHANNEL_PRIVATE / CHANNEL_INVALID on the forward, and the
   like) holds the chat and tries again by itself** after 10 min, 30 min, 1 h, 3 h, 6 h, then every 6 h (each
   try one forward, counted, with the pause and its random part; the hold survives a restart, read from the
   ledger), and the page says "held: Telegram refuses writes to the mirror; tried again by itself". It ends when
   a forward is answered. Not every pause: at most about 9 tries in the first day, 4 a day after.
3. **Unchanged, because they are not the chat's:** the account's own end (signed out, frozen method, an account
   refusal, USER_RESTRICTED: stop, never retry), a protected source (CHAT_FORWARDS_RESTRICTED ends that mirror,
   as now), a batch of unknown outcome (the settle decides from the mirror's own messages; it blocks only when it
   cannot tell, as now: that is the one case left where sending again could forward twice), Telegram's stated
   waits (slept, as now). Say in the hand-back every block of the automatic mirror that is left and why each
   cannot settle itself.
4. Tests: one message refused twice is set aside and the next posts go; a batch with one bad message: the good
   ones arrive; a write refusal held and tried at the backoff times, ending on an answer; a restart in the hold.
