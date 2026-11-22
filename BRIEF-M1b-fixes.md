# Brief M1b: the fix round of the `mirror` command (2026-11-15)

Copy: `C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-step1` (branch `wip/mirror-step1`, at 4fe8653). Work only
there, in `archiver/`. One commit on top; do not push, merge or touch another copy. Nothing is run against
Telegram. The rules of `BRIEF-M1-mirror-step1.md` hold (read its "Rules" section): invented data, named tests
only, one go command at a time with `GOGC=25 GOMAXPROCS=2 -p 1`, no whole-package run of `internal/catalog` or
`internal/collector`, no race detector, no Docker, the `Forwarder` in `internal/telegram/forward.go` unchanged.

Each fix gets a named test that fails without it. Read each place before changing it; if a finding is not
true as stated, say so in the report and change nothing for it.

The independent review's report is `C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-review-scratch\REVIEW.md`
(read it whole first; its probe tests are in that folder and may be taken as the start of your tests). The
numbers below are its finding numbers. The architect judged each: all of these are to be fixed.

## Fixes, most severe first
1. **A mirror Telegram created must never be recorded as "unknown" or lost** (finding 1, confirmed).
   `channels.createChannel` is answered and the stop (Ctrl-C) arrives with the answer: `CreateMirror` returns
   the mirror with the context's bare error (its `SetPeer` failed on the cancelled context; `storeErr` returns
   `ctx.Err()`, not `ErrStore`). Today the row becomes "unknown", with no mirror chat, no chat row and no access
   hash, while the channel exists. Fix in `internal/mirror/step.go`: in `createOutcome`, `m.Chat.ID != 0` is
   tested FIRST, whatever the error: the mirror is created (with an error: the end "created, its access hash
   could not be stored" unless the next step stores it). In `Step`, when the mirror came back with an error,
   store its access hash through the peer store on the record's own context (`recordCtx`) before
   `FinishMirrorCreate`; if that succeeds the step may go on only if its context has not ended, else it ends
   "created; stopped before the forward". Do not change `forward.go`.
2. **A stop during a create's stated wait ends "not created", not "unknown"** (finding 2, confirmed). After
   fix 1: read the forwarder's create waits (`Stats().Create.Waits + PremiumWaits`) before and after the call;
   one request sent, a wait counted for it, no mirror in hand: Telegram created nothing: the row ends
   "not created" (reason "a wait was stated"), whatever the error (the context's, a memo failure). A context
   error with a request sent and NO wait counted stays "unknown". Never "a context error means not created".
3. **An album over the server's maximum is refused before anything is created** (finding 3, confirmed). In
   `Step`, cut the first batch with `lim.ForwardMax` BEFORE `BeginMirrorCreate`; on `ErrAlbumTooLarge` end as
   "nothing sent" with fixed words of its own (not "the catalogue failed"), nothing created. The plan refuses
   the same with the plan's maximum. A run that ends this way must not send `help.getConfig` again on every
   later run for nothing: record nothing, but make the plan itself refuse when its own cut (at the plan's
   maximum) fails; the smaller-real-maximum case costs one config request per run and says so in its words.
4. **A mirror whose access hash is not on record blocks in the plan** (finding 4, confirmed): `MakePlan` checks
   the mirror's access hash as it checks the source's and says so in fixed words; no request is sent.
5. **A stop during a forward's stated wait is "waited", in the record and the words** (finding 5, confirmed):
   by the same reading of the forwarder's forward waits as in fix 2. The messages stay candidates.
6. **The plan and a "no" write nothing, not even the schema step** (finding 6, confirmed). The command opens
   the catalogue read-only for the plan; on a catalogue older than schema 13 the ledger is empty by
   construction (no mirror, no batch), which the plan must handle without the tables existing. The read-write
   open (which steps the schema), the lock held throughout, comes only after the yes; the plan is made again on
   the read-write handle inside `Step` as it is today. When the open will step the schema, the plan says so in
   one fixed line ("the catalogue is at schema N: saying yes steps it to M; a build older than this one then
   refuses it"). Test: a catalogue file at schema 12 (make one with the catalogue's own test helper for an
   older version, as `schema12_test.go` does), the command answered "no": the file's bytes are unchanged.
7. **True words at every end** (finding 7): a stop or a failure after the mirror was created never says
   "nothing was sent"; give each such point fixed words of its own that say what exists.
8. **The source's title is not a field of `Plan`** (finding 10): keep it out of any struct that could be
   printed; fetch it where the name is built.
9. **Each wait's stated seconds in the output** (the architect): `mirror_cmd.go` `timingInvoker` records
   "a wait"; record and print the seconds Telegram stated (the flood wait's argument) on that request's line,
   beside the total slept.
10. **Tests that fail without the code** (finding 9, confirmed by planted defects): add named tests for
    `ErrAlreadyForwarded` at the step (recorded, later forwards blocked, the plan says why), the
    hash-not-stored end, a stop arriving with the create's answer (fix 1), a stop during a create's wait and
    during a forward's wait (fixes 2 and 5), the album case (fix 3), the mirror without an access hash (fix 4),
    the "no" on an older catalogue (fix 6). For each of fixes 1 to 6 say in the report how you saw the test
    fail before the fix.

Not in this round (written down for later pieces, do not build): the ledger following a basic group that
became a supergroup (finding 8); the count against 500 from a stale chat list (finding 11); settling an
"unknown" by looking for the channel.

## Tests to run
`go test ./internal/mirror -count=1`; `go test ./internal/catalog -run 'Schema13|Mirror' -count=1`;
`go test ./internal/collector -run 'Mirror' -count=1`; `go test ./internal/collector/faketg -count=1`;
`go test ./cmd/tgarchive-collector -count=1`; `gofmt -l` and `go vet` on the packages touched.

## Report
Append a section "Fix round" to `archiver/docs/progress/mirror-step1-REPORT.md` in the commit: each fix with
its file and test, how the test was seen to fail first, whether any concurrent code was added or changed,
departures, doubts. Commit as the first brief says (message ends
`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`). Final message to the architect: the commit hash,
tests as counts and seconds, departures, doubts, under 30 lines.
