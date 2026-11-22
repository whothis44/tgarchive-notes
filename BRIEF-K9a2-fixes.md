# Brief K9a2: the ledger's fix round (Core, K-3, 2026-11-15 23:58)

For the coder of K9a, on `wip/core-ledger` (copy `wt-core-ledger`, at 726844a7). The independent review
is `REVIEW-K9a-ledger.md` in the project folder (verdict: may be listed after the must-fixes; 1 must fix,
4 should fix, 6 minor; its probes and outputs are in `wt-core-ledger-review-scratch`). **Read the review
in full first, and the probes.** Every finding is accepted; where the reviewer left a choice, mine is
below. Where a probe exists, turn it into a test of the tree and see it fail before your fix. Same ground
rules as K9a (only that copy; named tests only; no Docker, no race detector, no whole-package run; nothing
contacts Telegram; the memory check before go commands; commit often, push `private wip/core-ledger`).

## 0. First: take the request layer's final head in

`git fetch private wip/core-act` and merge it (53362793: K8 as listed; it changed `act.go`, `call.go`,
`memo.go` and tests since the e7624d5d you hold: a new reason "cancelled" for a click not sent, the cap's
door keyed by the account). A clean merge is expected. Then `go build ./...` and your adapter's tests: the
adapter must map the new reason (`NotSentCancelled`) to a reason word of the ledger's closed list (add
one: the caller was cancelled after the click was marked).

## 1. Finding 1 (must fix): one click, one chain of repeats

A click is the first row and its chain of repeats. A row may be repeated only while it has no repeat at
all (the chain's tip), and only from the states that allow it: the reviewer's fix as written (the
`NOT EXISTS` without the state condition; the index one repeat per row, ever). So a chain is linear, only
its tip can be live, and a click whose repeat ended "done" has no "send again" left anywhere in its chain.
Tests: the probes R1a and R1b expecting the state error; two "send again" at once on the tip (one new
row); a repeat of a repeat (allowed from the tip when its state allows).

## 2. Finding 2: the owner's verdict and "send again" act on the tip only

A row that has a repeat is closed for the owner: no verdict, no "send again", no cancel on it; the tip
carries the click. The page's read doors (door 12) say for each row whether it has a repeat and give the
chain's tip for a row (one indexed lookup), so that a page can show the old row as "sent again" and put
its buttons on the tip. A verdict "arrived" or "left" is taken only on a tip in "not known". Test: probe
R2 (a verdict on a row whose repeat is queued: refused; the repeat is unchanged).

## 3. Finding 3: a removed account

The account delete (`internal/catalog/settle.go`, the delete's last phase: this two-statement addition is
allowed) removes the account's rows of both tables before the account's own row. `SendClickAgain` and
`BeginClick` refuse a row whose account is not present or is marked removed (the same check `QueueClick`
makes), in the same statement. Tests: the reviewer's probe (a new account taking the old id sees no
click, no refusal, and nothing to send again).

## 4. Finding 4: the text's 7 days, and the three ends

- The 7-day clearing also runs in the age sweep (it runs at every turn), as one bounded statement on an
  index, and stays in the start's sweep.
- "Account refused" and "frozen": the text is cleared at that end (nothing can send it; the page still
  has what was typed). "Signed out": the text is kept and "send again" is allowed from it (the request
  was not carried out; the owner signs in again). Put these three into the state table of your report.

## 5. Findings 5 to 11

- 5: `TestActSentSince` begins one click per state reachable after `Begin` (every end, the start
  sweep's "not known", "arrived" and "left" after it) and expects every one listed; see it fail with
  the reviewer's mutant (ended rows left out).
- 6: the CHECK that no row is past "queued" or "not sent" without its `sending_ms` (the reviewer's line).
- 7: `LastChatRefusal` and `ClicksSentSince` fail closed on a row of the account with a state word
  outside the closed list: one guard (the reviewer's query, or folded into the door's own statement),
  the ledger's "bad row" error; the adapter passes it on as a store error (the request layer then sends
  nothing).
- 8: a repeat takes "try again" from the call's argument only.
- 9: `BeginClick` takes the age bound and refuses, in its one statement, a click older than the bound
  or dated ahead of the clock by more than 5 seconds; a click refused for its age is moved to "not
  sent" with the reason "not sent in time" in the same transaction, and the caller is told (the adapter
  maps it to `telegram.ErrClickSpent`: nothing is sent). The adapter is made with the bound (default 2
  minutes). Test: a click queued 3 minutes ago with no age sweep run: `Begin` refuses, the row is "not
  sent".
- 10: `partly` is allowed on "done" and set when a forward's answer left messages out; the row's
  message rows already say which got a new id.
- 11: a new door for the second half: a row still "sending" whose outcome could not be recorded goes to
  "not known" with a fixed type word of its own ("the outcome could not be recorded"), only from
  "sending". The turn (K9b) calls it when `End` failed. Test with the transitions' table.

## 6. One addition from the review's last section

`ClicksSentSince` also returns each click's count of messages (a forward's or a delete's rows; 1
otherwise), so that the second half can count a forward by its messages against the mirror's hourly
bound. The adapter ignores it (the request layer's `SentClick` has no field for it).

## 7. Not changed, said in the report as facts

The catalogue's `secure_delete` stays as it is (0): a cleared text can remain in the write-ahead file
until a checkpoint and on free pages after it, and a backup copies the texts still kept. Every message's
text is in the catalogue for good in any case (the `message` table), so the ledger's text is no more
exposed than what the archive already holds; write the three facts into the report's section on the text.

## 8. Runs, report, hand-back

- Once at the end: `go build ./...`; `gofmt -l` and `go vet` on `internal/catalog` and `internal/tgstore`;
  `TestAct` by name in the catalogue; `TestActLedger` in tgstore; the catalogue's schema tests by name
  (`-run 'Schema|Migrat|Step'`); the account-delete tests by name (find them: `-run 'DeleteAccount|Settle'`
  or what they are called); `TestWallDependencies` in the viewer. No whole package: mine.
- Add a section "The fix round" to `archiver/docs/progress/core-ledger-REPORT.md`: each finding's
  number, what changed (door, statement), its test and "seen failing first: yes or no"; the doors'
  signatures that changed (`BeginClick`, `ClicksSentSince`, `SendClickAgain`, the read doors, the new
  door of finding 11) so that the second half's coder can adapt in one read; the state table again.
- Commits as before, pushed; `git status --short` empty. Your final message: the head's full hash, the
  merge's result, each of the 11 findings with its test and "seen failing first", the changed
  signatures in one list, the commands with results and seconds, anything you disagree with.
