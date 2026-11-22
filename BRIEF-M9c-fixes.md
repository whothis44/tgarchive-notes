# Brief M9c (11-16 00:33, the mirror session M4): the review's fixes on the mirror's doors

The independent review of `wip/mirror-door` e57adb3f is back: "may be listed after these fixes"; high 0, medium
1, low 7. Its report: `C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-review11-scratch\REVIEW.md`; its probes
beside it (`zz_m9r_test.go`, `zz_m9base_test.go`, `zz_m9rc_test.go`: read-only for you; take them over as tests
of yours where named below). Same copy (`wt-mirror-door`), same branch, on top of your M9b round, same house
rules. Every finding is accepted:

1. **F1 (medium, confirmed): a stop, a never mark or the protected flag written during a turn does not stop
   that turn's request.** The end is read at the turn's start and `autoCheck` before the request, but the
   intent rows (`BeginMirrorBatch` in `schema13.go`, `BeginMirrorCreateBy`) check none of the three, so a door's
   write that lands in between is followed by one more request (the probe `TestZZM9rWindow`: 6 of 6 cases).
   **Fix: the check moves into the intent's own transaction.** In the transaction that writes a create's or a
   batch's intent row, read: the account's want of that source (if one is on record) is neither ended nor
   blocked; no "never" mark on the chat or on a chat its migration links it to; `chat.protected` is not 1
   (through the existing door; on a file where the flag is not known: as not known, not as protected). If any
   holds: no intent row is written, a sentinel of its own is returned (not `ErrWrongState` if that word means
   something else to a caller: read its callers), and **nothing is sent**. The catalogue has one writer: a
   door's write is then either before the intent (the request never starts) or after it (the request was
   already under way: what the pages say). Callers: the task ends the turn for that want with no request, no
   block and no failure counted (the next turn's `autoCheck` ends it in the usual words); the owner's command
   (`step.go`) ends as it does for `runHeld`, in the same fixed words. A mirror made by the command with no
   want is checked for the mark and the flag only. The settle's read of the mirror chat and `help.getConfig`
   are not writes to a source and are left as they are. Tests: the reviewer's `TestZZM9rWindow` as yours (all
   6 cases: 0 requests in that turn and after); the command's run with a mark written between `runHeld` and
   the intent: 0 requests; a run in which nothing changes keeps its requests and their moments (compare the
   fake's requests before and after this change); **`TestMirrorDoorRunNever` made exact: no write at all
   after the mark's write returned** (today it lets one through).
2. **F3 and the offers (with M9b's item 2): the door refuses a word the state does not offer.** `SettleWord`
   accepts a word only when it is in `Offers` for the block on record now (one function, used by the page's
   state, the door and the task), so "create-not-made" is refused while the create's row is under way and
   not offered. Test: the reviewer's `TestZZM9rNotMadeYoung` as yours, refused.
3. **F2: `Kept` says what will happen.** An automatic want in a run without the switch is not kept: `States`
   takes whether automatic wants are served (the collector knows), and such a want shows a state of its own
   in fixed words ("waits for the automatic mirror to be switched on"), `Kept` false. Test from
   `TestZZM9rKeptOwnerOnly`.
4. **F4: the data race.** `mirror_door.go` reads `account.signedIn` from an HTTP goroutine: use the atomic
   the account already has for it (the reviewer names `a.owner.signedIn.Load()`: check it is the right one).
   Look for any other plain field of `account`, `session` or `Collector` read in `mirror_door.go`.
5. **F5:** the early returns of `autoTurn` (no owner's want, no secret) clear `autoSession.unreadable` under
   its lock when the read that failed before now succeeds. A test through `MirrorTask`.
6. **F6 (with M9b's item 5): an account the catalogue does not have** is refused by every door in fixed
   words, and nothing is written (`MirrorNever` wrote a mark row for it). The end of `TestZZM9rStorm` as a
   test of yours.
7. **F8: the plan and the want agree on a twin.** `PagePlan` for a chat whose migration links it to a chat
   that has a mirror or a want is blocked in fixed words of its own; `Want` refuses with the same words (not
   "the mirror is in a state that is not settled"). `TestZZM9rFamily` as yours: 0 wants, 0 creates.
8. **F7: five rule lines no test holds.** A named test for each, seen to fail with its line undone: the
   mirror-row id compare and `found != 0` in `auto_word.go`; **the twin-by-migration refusal in
   `AddOwnerMirrorWant` (undone, a second mirror chat is created: this is the rule "never a second mirror
   chat")**; the word-time compare in `schema_mirrorwant.go`; the download switch-off in `door.go`.
9. **One more test, for the race run that follows (I start it, not you):** a collector test in which
   `MirrorTask` and `MirrorStates` are called in a loop from another goroutine while a want's history is
   forwarded (name it `TestMirrorDoorRunRead...` so that `-run 'TestMirrorDoorRun'` takes it).

Named tests only while working. **At the end, once, one at a time, full output kept in files:** whole
`internal/mirror`; `internal/catalog -run 'Mirror|Schema|Protected'`; `internal/collector -run 'Mirror'`;
`cmd/tgarchive-collector`; gofmt and vet on the three packages. No race detector from you. A section "M9c" in
the report (per finding what changed; each new rule's line undone and its test; the runs), with the final
list of exported names and collector methods AS BUILT at the top of the report; commit, push, the copy clean;
the final commit in your last message with anything not done.
