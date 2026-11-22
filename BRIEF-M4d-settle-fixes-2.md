# Brief M4d: the settle's second fix round (2026-11-15)

Copy: `C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-auto` (branch `wip/mirror-auto`, head 464e840, clean).
Work only there, in `archiver/`. Commit as you go (work-in-progress commits are fine) and push the branch to the
remote `private` (`git push private wip/mirror-auto`) after each commit that builds; never push anywhere else,
never merge another branch in, never touch another copy (`repo-archiver`, `wt-int-m4`, the review's scratch folder).
Nothing is run against Telegram. Invented data only; the injected clock only; counts, sizes and timings only in
anything you write (no names, text, paths of the owner's, ids or links). New log lines use constant format strings.

**The settle decides whether a message is forwarded again. A wrong "not arrived" puts a second copy in the owner's
mirror; a wrong "arrived" leaves a hole. When the evidence is not exact, it says so and stops.** An independent
review of the last round confirmed two high defects and found two smaller ones. This round fixes the four.

## Read first, whole
- The review: `C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-review6-scratch\REVIEW.md`, and its probes
  `zz_m6probe_test.go` in that folder (S1, S2, S2b: each becomes a named test in the copy, see "Tests").
- The rules the settle was last rewritten to: `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-M4c-settle-fixes.md`.
  They hold except where this brief changes them (rules 3, 6, and the need time of rule 1).
- The code: `internal/catalog/mirrorsettle.go` (all), `schema13.go` (the candidates, `BeginMirrorBatch`,
  `FinishMirrorBatch`), `schema_mirrorauto.go` (the step); `internal/mirror/auto.go` (`mirrorTurn`, `settle`,
  `autoBatch`, `forward`), `step.go` (`Run`'s loop, `nextBatch`), `mirror.go` (`planSettle`, `Settle`, `firstBatch`);
  `internal/telegram/forward.go` (`forwardRandomID`, `ForwardItem`, `checkBatch`, `ForwardBatch`) and `call.go`
  (`once`, `held`: read only); `internal/collector/mirror_settle_cmd.go`, `mirror_cmd.go` (the plan's printing),
  `mirror_auto.go` (the `ReadMirror` hook), `lock.go`.

What is known from the real runs (11-15, one account, "looks like"): a wait Telegram states means nothing was
forwarded; a server error on a forward carried out 64 of 99 (nearly a prefix, albums whole); nobody knows whether
Telegram remembers the random ids of the messages of such a request that it did NOT carry out. Both worlds must
come out right.

## Part 1 (finding 1, high): the media key, and "not a forward"
In `mirrorsettle.go`:
1. **The media key** of a message, source and mirror alike: its `attachment` rows with `replaced_at IS NULL` and
   the main role only (`RoleMain`; a row whose role is 0 counts as main, as the ladder does; not
   `RoleAlternative`, not `RoleLiveVideo`). Sorted Telegram media ids, as today.
2. **"Not a forward" is judged per single media row, every row counted:** a mirror message with no forward origin
   on record that shares ANY media row (replaced, alternative and live-video rows included, on either side) with
   ANY message of the batch is never `NotForward`: it is `Unexplained` (so the batch's "not arrived" messages
   become "cannot tell"). Only a mirror message with no origin on record and no media row in common with any
   batch message is taken as not a forward.
3. Rewrite the file's head comment where it describes the key and that judgment.
Expected for the review's six S1 cases (all 100 arrived, the copy of message 7 odd): edited before the forward:
settled, found 100; a copy with one alternative row more (supergroup, and the channel's hidden-sender repost):
settled, found 100; edited after the forward with a hidden sender (supergroup and channel): cannot tell, nothing
written; edited, a bare sender: cannot tell. Never "again 1".

## Part 2 (finding 2, high): messages put back go alone; what the owner can do when they are refused
Design (decided by the architect; say in the report if anything in the code argues against it):

**The ledger.** A new table inside this branch's own schema step (`schema_mirrorauto.go`, step 18: it is not
merged and no build of it has opened a real catalogue; `CREATE TABLE IF NOT EXISTS`, the step stays idempotent;
NO new schema number is taken):
`c_mirror_again(mirror_id, src_msg, attempt INT NOT NULL DEFAULT 0 CHECK (attempt >= 0), batch_id INT NOT NULL,
at INT NOT NULL, by_owner INT NOT NULL DEFAULT 0, PRIMARY KEY(mirror_id, src_msg)) WITHOUT ROWID`: one row per
source message that a settle made a candidate again (by the rules, or by the owner's "not arrived"): the batch it
was put back from, when, and its attempt number (0: it goes again under the same random id as before). The row
stays when the message is later forwarded (it is the record). A read-only handle on an older file has none (as
the step's other tables: `hasAuto`).

**The settle writes it.** `SettleMirrorBatch`, in its one transaction: every message it makes a candidate again
gets or keeps its row (batch and time updated; the attempt unchanged), except: messages taken "not arrived" by
the owner's word from a batch whose state was `already` get attempt + 1 (see rule 6 below).

**Batches never mix.** `MirrorCandidates` (and so `firstBatch`, `autoBatch`, `nextBatch`, the plan): when the
mirror has candidates with a `c_mirror_again` row (under the same filter: not deleted, media-only unless all), it
returns ONLY those (oldest first, up to the limit; an album is completed only among them), each marked put back
with its attempt; else the candidates without a row, as today. `MirrorCandidate` gains the two fields;
`telegram.ForwardItem` gains `Attempt`. `BeginMirrorBatch` checks it once more: a batch that holds both a message
with a row and one without is `ErrBadLedger`, nothing written. The count for the plan: a function that counts the
put-back candidates apart. The young-message cut in `autoBatch` applies as today.
`Run`'s guard against a repeat inside one run (`lastDone` in `nextBatch`) must keep its purpose (no message sent
twice in a run) without ending a run because a put-back batch carried higher ids than a later fresh candidate:
judge by the set of ids sent in this run's done batches, not by a high-water mark.

**The random id.** `forwardRandomID` takes the attempt: attempt 0 gives exactly today's id (pin it: before you
change the function, compute one value on 464e840 in a throwaway test and write it into a test as a constant);
attempt n > 0 hashes the attempt too under a different label line. `checkBatch` refuses a negative attempt.
`ForwardBatch` derives each item's id from its attempt. Update the comments that say "the same forward always
carries the same id".

**Rule 6, rewritten.** With batches never mixed, an `already` batch (Telegram refused the request as a repeat) is
either all put back or all first-time. In both cases a message of it that the rules do not find in the mirror is a
contradiction, as today (cannot tell; nothing by itself; the want is blocked for the owner). What changes: the
owner's `-take not-arrived` is no longer refused for it. It puts those messages back with attempt + 1, so they go
again, alone, under new ids that Telegram cannot refuse as a repeat. `-take arrived` is as today (rows "missing").
For a batch in any other state `-take not-arrived` puts back with the attempt unchanged (if they did arrive,
Telegram may still refuse the repeat, and then the owner is asked again with the choice above). No case is left
where the word is refused: remove `SettleTakeRefused` if nothing uses it. New fixed words for what "not arrived"
risks on an `already` batch: sent again under new ids, which Telegram cannot refuse as a repeat: any that did
arrive will be in the mirror twice. The batch's reason records the word as today.

**No loop (rule 7) stays as it is:** a put-back batch that ends unknown or as a repeat right after a settle blocks
the want (`AutoBlockAgain`); nothing is settled again by itself. Check that the block's words, the event and the
heartbeat tell the owner what to run (`mirror -settle N`): if `AutoBlockAgain`'s words do not, add fixed words for
"the messages a settle put back were refused as a repeat".

**The plan and the command say it** (`mirror.go` plan, `mirror_cmd.go` printing, `mirror_settle_cmd.go`):
- a plan whose next batch is a put-back batch says so with counts: N messages a settle put back go first, alone,
  never with messages not sent before; M of them under new ids by the owner's word; under the same ids, a batch
  Telegram already has is refused as a repeat and nothing is doubled; and what the owner can do then:
  `mirror -settle N -take arrived` (they stay out of the mirror, on record as missing) or `-take not-arrived`
  (sent again under new ids; any that did arrive will be in the mirror twice);
- the settle of a contradiction offers both words with their risks (today it refuses the second);
- "about N batches" and the per-hour arithmetic count the put-back batch.

**The fakes.** The mirror package's `fakeTG` remembers random ids by message; it must remember by message and
attempt. The collector's `faketg` answers on real random ids: check that a new attempt's id is not refused, and
that the same id is (where it emulates the refusal).

## Part 3 (finding 3, medium): a batch left "sending"
A batch row still `sending` when someone looks was begun by a sender that has ended (a killed process; or this
session's own forward whose record failed). `sent_at` is written before the forwarder sleeps a wait stated
earlier (`held`, which may sleep more than once) and before the request, so it says nothing about when the
request went out. No constant bounds that. What is exact: the request cannot have gone out after its sender
ended. So:
- One function in the catalogue gives a batch's request time and need time, used by all three places that
  compute it today (`weighBatch`, `planSettle`, the turn's `settle`): for `unknown` and `already`, as today (the
  later of sent and ended); for `sending`, the later of `sent_at` and **the caller's word for when the sender had
  ended** (`SettleRead` gains that field; 0 for a `sending` batch settles nothing: `SettleNotOnRecord`).
- The automatic turn's word: the clock at which this session's task began (kept in `AutoState`, set on the
  clock when the state is made or at its first turn; check where `AutoState` is created and that it does not
  outlive a session of the account, and say so), or, for a batch this session began whose `FinishMirrorBatch`
  failed, the clock right after its `ForwardBatch` returned (kept in the state when the record fails).
- The command's word: the clock when the command began, valid because the command holds the collector's lock
  (`lock.go`) on the catalogue, so no other sender is alive. Confirm by reading that the settle path holds that
  lock before it trusts this; say where in the report. The plan's "the settle's read starts at" follows.
So a restart seconds after a kill waits the full margin from its own start before the settle's read.

## Part 4 (finding 4, low): a mirror chat the reader refuses
`mirror_auto.go`'s `ReadMirror` hook returns "not done, no error" when the pass's outcome is `telegram.Refused`,
so the turn "reads" every turn and the owner is never told. Return a named error for it (in `internal/mirror`,
beside `ErrSettleWaits`); the turn blocks the want until the owner looks, with fixed words (the mirror chat
refuses the account's read: the settle cannot read it), an event and the heartbeat's count; later turns do not
call the reader for it.

## Tests (named; each seen to FAIL on 464e840 first: say how you saw it)
- The review's three probes as tests in the copy (same scenarios; adapt the assertions to the rules above):
  **S1** six cases with the expected outcomes of Part 1; **S2** both modes: "forgets": the batch after the settle
  holds exactly the 40 put back, then every one of the 400 is in the mirror once; "remembers": the 40 alone are
  refused, the want is blocked, none of the 360 others was in that request; then the owner: no word:
  contradiction, cannot tell 40; `-take not-arrived` and `-allow`: after 3 hours of the clock all 400 in the
  mirror once, none twice; and in a second branch `-take arrived`: 40 rows "missing", every one of the other 360
  in the mirror once; **S2b**: message 7 is found (Part 1), no repeat, all 400 once.
  Note for the report: the probe's own S2 assertion ("no message left out") cannot hold under `-take arrived` in
  the "remembers" mode: those 40 are out by the owner's own word; the high defect was the 60 never sent.
- A wrong "not arrived" by the owner's word on a message that did arrive: it goes alone, is refused as a repeat,
  the contradiction covers that one message only.
- `BeginMirrorBatch` refuses a mixed batch; `MirrorCandidates` never returns one (an album with one member put
  back and one never sent included).
- `forwardRandomID`: attempt 0 equals the pinned value; attempt 1 differs; the request's ids follow the attempts.
- A run of several batches: a put-back batch, then fresh ones, one fresh candidate with an id below the put-back
  ones: not ended as a repeat.
- Part 3: a batch left `sending` and a fresh session: no reader call before the session's start plus the margin;
  the catalogue refuses a read begun before that, and refuses with no sender's word; the record-failed case;
  the command's plan time.
- Part 4: one reader call, the want blocked with the words, no call on later turns.
- The plan's and the settle command's new lines (fixed words and counts).
- For each main fix, undo it once and name the test that catches it.
Tests of the last round that pin a changed rule (the refused `-take not-arrived` on a contradiction, any exact
`needAt` of a `sending` batch) are changed to the new rule: list each in the report.

## Running things
`source ix-tools/env-archiver.sh` (in the project folder), then one go command at a time with
`GOGC=25 GOMAXPROCS=1` and `-p 1`. While working: named tests only (`-run`). Never: a whole run of
`internal/catalog` or `internal/collector`, the race detector, Docker, `go vet ./...`. Once, at the end, in this
order: `go test ./internal/mirror -count=1` (about 80 s); `go test ./internal/catalog -run
'Schema13|Mirror|Settle|TopicSchemaStep' -count=1`; `go test ./internal/collector -run 'Mirror' -count=1` (about
3 minutes); `go test ./internal/telegram -run 'Forward' -count=1`; `go test ./internal/collector/faketg -count=1`;
`go test ./cmd/tgarchive-collector -count=1`; `gofmt -l` on the changed files; `go vet` on the changed packages
only. The PC is shared with other sessions' coders: if a go command is killed or memory is short, wait and run
it again; do not raise the limits.

## What you may edit
`internal/catalog/mirrorsettle.go`, `schema13.go`, `schema_mirrorauto.go`; `internal/mirror`;
`internal/telegram/forward.go` (not `call.go`); `internal/collector/mirror_cmd.go`, `mirror_settle_cmd.go`,
`mirror_auto.go`, the heartbeat's and words' lines for new words; the fakes' forward answers; the tests of all of
these; `docs/progress/mirror-auto-REPORT.md`. `reader.go` and `account.go`: no change expected; if one is needed,
stop and say why first. No new goroutine, lock or channel in the program is expected: if you add one, say it.

## Report and hand-back
A section "The second settle fix round (M4d)" in `archiver/docs/progress/mirror-auto-REPORT.md`: per finding,
what changed (file, function) and its tests with how each was seen to fail before; the changed expectations of
older tests; what stays "cannot tell" by design; every line changed in `reader.go` and `account.go` (none
expected); concurrent code added or changed; departures from this brief; doubts. Commit with
`git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, the message ending
`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, no archive numbers; push to `private`. The copy must
be clean at the end. Final message to the architect, under 40 lines: the head's hash (pushed), per finding one
line, the tests as counts and seconds, concurrent code, departures, doubts.
