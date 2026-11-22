# Review K17: a file given back from a transfer is judged as the settle would judge it now (Core, 2026-11-16)

Independent review of `wip/core-giveback` at bd195424 (two commits on 78739d59), by brief `BRIEF-K17-review.md`.
Read-only on the branch; nothing committed or pushed. Probes are uncommitted test files in my scratch copies
(`wt-core-giveback-review-scratch` at bd195424, `wt-core-giveback-review-base` at 78739d59, and a third,
`wt-core-giveback-review-b3` at b3c64668, made for question 10 only). Every go command went through
`runs-core-k5/go1.sh` (named tests only, no race detector, no whole-package run). Invented data only; numbers below.

Probe files (in `archiver/internal/catalog` of the scratch copy; the ones marked * also in the base copy):
`zz_probe_k17_alt_test.go`*, `zz_probe_k17_diff_test.go`*, `zz_probe_k17_twin_test.go`, `zz_probe_k17_trig_test.go`*,
`zz_probe_k17_cost_test.go`*, `zz_probe_k17_recover_test.go`; base only: `zz_probe_k17_basehelp_test.go` (a copy of `gbRowOf`).

## Answers, in the brief's order

1. **Nothing changes where nothing is to hold: equal, except the shapes of finding 1.** Differential probe
   `TestZZK17Diff` (both copies, `K17_DUMP` set): 24 seeded worlds, 40 files each, every file collected by a carrier
   (two channels and a forum that collects only chosen topics, files in 1 to 3 chats seen by two accounts),
   plain files, probable copies (828 + 164 + 108 row-phases), check_first files (1,112 row-phases), the owner's
   release, fetch_real, keep_held, set-aside by hand and send-back, engine set-asides with five reasons (one of them
   the owner's reason word and one empty), then Release / Aside + requeue, restart, the second account's removal,
   requeue of all. 3,840 dumped rows (state, reason, probable, check_first, retry_at, attempts, asides,
   claimed_by, keep_held, released, fetch_real, every c_supply row): **0 lines differ** between 78739d59 and bd195424.
   Not equal: a file a chat carrying it collects by the settle's own reading (`collectedSQL` counts a replaced
   attachment) whose own-media attachment was replaced by an edit and which another message carries as an
   alternative: wanted on the head, held as an alternative on the branch (finding 1, path A).
2. **The twin rule.** `TestZZK17Twins`: 900 random configurations through the doors (pages saved, edits as pages,
   the owner's switches), 542 run (358 refused by a door: a mark or state the doors do not allow), compared after
   the door and again after the switch is undone. Every disagreement falls in one of these classes:
   - Declared 1 (the role rule spares released, fetch_real, sent back): as described; seen with every door. Its
     follow-ons: after the edit is undone the given-back file keeps reason "by the owner" where the waiting twin has
     ''; a fetch_real probable copy's waiting twin ends plain wanted after the edit and its undoing, while the
     given-back one stays held probable = 1 (supplied after unique files). Consequences of the declared choice.
   - Declared 2 (alternative-only held whatever made it so): as described, and it is not rare in kind: finding 1.
   - Declared 3 (Aside overwrites the reason): as described: a sent-back file set aside by the engine comes back
     held when its chat or kind is off (twin wanted, spared); released / sent-back files differ in reason only
     ("by the owner" against ''); a kept-held copy's reason is the ladder's or the hold's.
   - Declared 4 (kept-held in transfer only by SQL): my probe also made it by SQL; those rows differ in reason
     (and, for a kept-held plain file, in state, because `backToSQL` sends a non-probable kept-held file to wanted).
     Not reachable through the doors, as the coder says; I did not find a door that makes it.
   - **A fourth class, with no owner's mark at all:** "edit: replaced" with the file also carried as an alternative
     elsewhere: waiting twin wanted (or held probable and supplied), given back held as an alternative, no supply,
     by release, requeue, restart and the account's removal. Finding 1.
3. **Can the role column hold what the rules want downloaded? Yes: four paths exist** (`zz_probe_k17_alt_test.go`;
   every subtest fails on bd195424 and passes on 78739d59):
   - A, an edit replaces the message's own media (`TestZZK17AltEditReplaced`): the old file stays wanted and
     supplied (no rule looks at it), is carried elsewhere as an alternative; given back by any door it is held as
     an alternative, supply 0. A chat settle (off and on) wants it again; the next give-back holds it again.
   - B, the space of its own-media carrier is deleted (`TestZZK17AltSpaceDeleted`, `DeleteSpace`: "files stay").
   - B', the account removed had it in transfer and its own private chat was the own-media carrier
     (`TestZZK17AltAccountRemoved`): its own spaces' messages are deleted in the phase before the claims are given
     back; waiting twin wanted (supply 1), given back held (supply 0).
   - C, "always download" unskips a file the known list skipped, carried only as an alternative
     (`TestZZK17AltAlwaysDownload`).
   In B, B' and C nothing ever wants the file again (no carrier is collected), so it is never claimed again. Not
   found: a deleted message (`MarkDeleted` sets `deleted_at`; attachments stay, the read does not change); the exact
   check's, frame check's and pair-word doors (they need a claimable probable copy; an alternative-only file
   reaches them only through A to C first). Must fix (finding 1).
4. **The requeue's reason: right.** By reading every branch of `asideBackSQL`/`judgeGivenBack`/`asideClearSQL`
   (no hold writes "wanted", so a wanted row after the judgement can only carry the set-aside's own reason, which
   the clear empties; a probable copy gets `heldReasonSQL` either way; the owner's set-aside by hand keeps
   `ReasonOwner` until the holds have read it) and by both probes: the 3,840-row diff (five set-aside reasons, the
   owner's set-aside and send-back) equals the head, and no twin class shows a stale engine reason on a wanted row
   or an empty reason on a held one.
5. **`RecoverActive`** (`TestZZK17RecoverEdges`, `TestGiveBackRecoverMany` x3): 0 active: returns 0, no write
   (0 change-log rows); 1; exactly 250 (one traced chunk, then an empty transaction ends the loop); 251; 749: all
   right. A context ended after the first chunk: returns 250 and `context.Canceled`, 260 left active, a second call
   gives them back (the first chunk stays committed: no longer all-or-nothing, harmless at a start). A Batch handle:
   503 given back in the caller's transaction. The loop ends: each chunk reads active rows and moves every one it
   read out of active in the same transaction. Callers: `cmd/tgarchive/app.go` prints only when n > 0;
   `supply.Recover` passes n on; neither relies on the old write. A read-only handle with none active now returns
   nil (head: `ErrReadOnly`; finding 3). Longest chunk of 4,000 rows (half held): 55, 56, 54 ms on this PC (CPU 80
   to 88 % busy); inside the 150 ms p99 / 250 ms worst bounds the settle's at-size tests use, above the settle's
   own adaptive target `settleTarget` = 40 ms (finding 4).
6. **The statement cache: no defect found.** `prepareGiveBack` returns on a Batch handle and on a read-only one;
   it prepares on `wdb` before its caller's Batch, so it waits for another goroutine's transaction and holds
   nothing itself (no deadlock unless an outer-handle method is called inside a Batch callback, which is already
   forbidden). A statement that cannot be prepared runs unprepared, as `exec` already does. After `Close`, prepare
   fails and is ignored; the read before it returns the closed-database error. K16's rollback and
   `preparePending` are untouched by the piece. Decided by reading; no probe injects a prepare failure.
7. **The removed account's claims:** judged inside the "rest" phase, after its reach rows, sightings and own
   spaces' messages are gone and before `account_chat` goes (which the rule does not read). Another account still
   reaching the file: twins equal in every class except finding 1's (path B': the own-space deletion first leaves
   an alternative-only file). None reaching: given back wanted or held with no supply, as the waiting twin.
8. **The claim path is untouched.** By the diff: `state.go`'s hunks start at line 290; `claimSQL`, `claimSetSQL`,
   `heldGate`, `Claim`, `ClaimWith`, `ClaimNext` are unchanged; `lane.go` untouched. Timing,
   `BenchmarkClaimNext200k -benchtime=2000x -count=3`: head 1.773, 1.797, 1.735 ms/op (mean 1.768); branch 1.759,
   1.976, 1.750 (mean 1.828, median equal to the head's): noise.
9. **Triggers and the change log** (`TestZZK17Trigger`, both copies, each door, plain and probable, chat off and
   on): a file held at the give-back is now seen by an `AFTER UPDATE OF state` trigger as active->wanted then
   wanted->held (requeue: active->aside, aside->wanted, wanted->held); the head showed active->held. Change-log
   kind-1 rows: 2 (requeue 3) where the head wrote 1 (2). c_supply after: right in every case (`supplyDrift` 0;
   the interim insert is deleted again in the transaction). Cases not held (collected; probable copies) are as on
   the head. The copies track's planned trigger on `c_want` would see a spurious "became wanted" for every file a
   give-back holds (finding 2).
10. **The tests.** On b3c64668: `TestGiveBackProbeRestart`, `TestGiveBackProbeTopic`, `TestGiveBackProbeRole`
    fail, `TestGiveBackTwins` fails 20 of 20 subtests; on bd195424 all pass. The test file between the two commits
    changed only formatting and log lines (not weakened). No test passes by comparing a twin with itself; the
    RecoverMany time bound is skipped only under the race detector. Set by direct SQL where a door exists: the
    edit case's role (`setRole` updates `attachment.role` and calls `roleChanged`, not `SaveMessages`), probable
    copies put in transfer, the 4,000-row world. Not tested: a replaced attachment, a deleted carrier, an
    always-download unskip (finding 1 lived there); check_first files in the held path (the settle's statement
    gives `ReasonLookAlike` there; my diff probe covers check_first only where nothing holds).
11. **`Release`'s cost**, 100,000 wanted rows, 2,000 calls a run, three runs each (`TestZZK17Cost`, `K17_COST`
    set; the clock steps about 0.5 ms, so means only): common case (a collecting chat carries it): head 350, 336,
    312 us (mean 333, spread 312 to 350); branch 381, 376, 380 (mean 379, spread 376 to 381): about +46 us, +14 %,
    the spreads do not overlap (finding 5). Held case (2,000 files of a chat switched off in transfer, each
    released): head 223, 224, 221 us (mean 223); branch 426, 422, 424 (mean 424), 1.9 times: one read, the plain
    write, four hold statements (a fifth, the role hold, when that column is true) against the head's read and one
    write. Bounded by the transfers under way at a switch.

## Findings

1. **Must fix. The give-back's role column holds files the rules want downloaded, for good.** A file carried
   only as an alternative by `giveBackReadSQL`'s reading becomes wanted without the owner's hand by an edit that
   replaces its own-media attachment (A), a deleted space (B), an account removal whose private chat carried it
   (B'), and "always download" (C); at any give-back it is held as an alternative, supply 0, and in B, B' and C
   nothing wants it again. Probes: `zz_probe_k17_alt_test.go` (`TestZZK17AltEditReplaced`,
   `TestZZK17AltSpaceDeleted`, `TestZZK17AltAccountRemoved`, `TestZZK17AltAlwaysDownload`: fail on bd195424, pass
   on 78739d59) and the twin class "edit: replaced" in `zz_probe_k17_twin_test.go` `TestZZK17Twins`. The give-back
   cannot tell an edit during the transfer from these paths by the attachments alone. Smallest fix: drop the role
   column from the give-back (case 4 of the brief goes back to the head's behaviour: an open hole bounded by the
   transfers under way during an edit, to be written down). If case 4 must stay closed: a marker written when
   `roleChanged` meets the file in transfer (no column is free: the active row's reason is overwritten by `Aside`),
   which is a design choice for the Core session. Requiring "no own-media attachment at all, replaced or not"
   closes A only.
2. **Should fix (a message, not code, unless the Core session prefers one write).** A held give-back is written
   twice in one transaction; an `AFTER UPDATE OF state` trigger sees an interim "wanted", the change log gets one
   more kind-1 row, c_supply inserts and deletes. Probe `zz_probe_k17_trig_test.go` `TestZZK17Trigger`. Smallest
   fix: a board message to the copies track that a trigger on `c_want` state must not act on an interim wanted
   inside a give-back (or judge transitions from OLD to the row's state at the transaction's end).
3. **Minor.** `RecoverActive` on a read-only handle with no active row returns nil where the head returned
   `ErrReadOnly`; with none active it no longer touches the writer. No caller relies on either. Probe
   `TestZZK17RecoverEdges`. Fix: none, or a line in its comment.
4. **Minor.** The report calls 150 ms "the settle's own bound"; the settle's own target is 40 ms
   (`settleTarget`, adaptive chunks); 150 / 250 ms are its at-size tests' bounds. `recoverChunk` = 250 measured
   54 to 56 ms longest here. Fix: the report's wording (or 150 rows, if the 40 ms target is meant).
5. **Minor.** The report says Release's common-case change is "inside the load's spread"; three runs each on one
   build here show +46 us (+14 %) with spreads not overlapping. Small; the report's number should say so.
6. **Minor.** The edit case in the new tests sets the role by direct SQL; with finding 1's fix, add a twin through
   `SaveMessages` edits, including a replaced attachment with an alternative carrier elsewhere, a deleted space and
   an always-download unskip.

## Not looked at

The list for the copies track (not checked line by line); the whole package, the race detector, `go vet`, the
heavy tests behind their switches; `internal/supply`'s recovery tests (not re-run); an injected error inside a
chunk or a prepare failure (decided by reading); `RecoverActive` while claims are being made; check_first files in
the held path; `cmd/tgarchive`'s start; the declared kept-held-in-transfer state through any door other than the
ones I tried.

may be listed after these fixes: 1
