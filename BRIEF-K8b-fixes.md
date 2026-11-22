# Brief K8b: the request layer's fix round (Core, K-3, 2026-11-15 23:25)

For one Opus coder. The piece is K8 (`BRIEF-K8-client-requests.md`), on `wip/core-act` at 79debb9f in the
copy `C:\Users\trabi\Claude\Projects\Telegram\wt-core-act`. Its independent review is
`C:\Users\trabi\Claude\Projects\Telegram\REVIEW-K8-requests.md` (verdict: may be listed after the
must-fixes; 12 findings; its probes are in `wt-core-act-review-scratch`: `zz_k8review_probe_test.go`,
`overlay.json`, `probe-output-1.txt`). **Read the review in full first, and the probes.** Every finding is
accepted; what to do for each is below, in my words where I chose between the reviewer's options. Where a
probe exists, turn it into a test of the tree (in the package's own test files, in the coder's style) and
see it fail before your fix.

Same ground rules as K8: work only in that copy; nothing contacts Telegram; `forward.go` is not edited;
no schema step, no `go.mod` change, no goroutine; commit often and push `private wip/core-act`.

## 0. First: take the main head in

`git -c user.name=Claude -c user.email=noreply@anthropic.com merge --no-edit claude/charming-feynman-vm2xia`
(27a7d4d or later). A clean merge is expected (nobody else changed `internal/telegram` tonight). If it
conflicts outside your files, stop and report. Then `go build ./...`.

## 1. Finding 1 (must fix): the collector's list of kinds that are not counted

`internal/collector/status_file.go`, `notCounted`: add the six lines `repeat_waits.act_send`,
`act_forward`, `act_edit`, `act_delete`, `act_react`, `act_read`, in the list's own style and order (the
file is Core's: this edit is allowed, and it is the only collector line you touch). Then
`go test -count=1 -run 'TestNotCountedRepeatWaitsDerived|TestStatus' ./internal/collector/`.

## 2. Finding 2: nothing leaves when a refusal or a wait landed while `Begin` ran

Fix (a) of the review, and the contract as well:
- In `report`, right after `begin()` returned nil and before the request: check again, as the first
  checks do (memory and store): the wait of the kind's method, the chat's slow mode where `chatKey` is
  set, and the account's refusal (give `report` a second callback for it, so that `call.go` stays
  ignorant of the Forwarder; the Actor passes `terminal`). When one holds, or one of these reads fails:
  **no request**, and a typed error that says which.
- `Do` records that through `End` as a new outcome, "not sent" (`Requests` 0, the reason as a small
  constant: a wait, with its end; the account's refusal; the record could not be read), so that the row
  does not stay "sending". This is the one exception to "a local no writes nothing through `Begin` or
  `End`": say so in `Do`'s doc and in the `ActLedger` doc (piece 2 shows such a row as "not sent", and the
  cap still counts it, since `Sent` lists what `Begin` accepted).
- The check number passed with `withCheck` must be the one of the LAST check of the kind's wait before
  the request (the re-check's), not the first.
- Doc of `NewActor` and `Do`: one Forwarder per account per process, and the Actor made from it; requests
  of one account are meant to go one at a time (piece 2's loop), and this re-check is the guard when they
  do not.
- Test: the probe P4's two cases (a refusal recorded during `Begin`; a wait on "forward" recorded during
  `Begin`): 0 requests, the outcome "not sent" recorded through `End` exactly once.

## 3. Findings 3 and 4: what is remembered as a chat's refusal

My brief's R7 was wrong: it had every definite answer remembered for a day. New rule:
- `ActOutcome` gains `Remember bool`. `End` receives it; the `ActLedger` doc says `ChatRefusal` returns
  only refusals recorded with `Remember` true. The fake ledger in the tests follows that.
- `Remember` is true only for a refusal that is about the account's standing in the chat written to
  (the click's `Chat`), from a fixed allow-list in `act.go`: the words of `refused()` that apply, and
  `CHAT_WRITE_FORBIDDEN`, `CHAT_SEND_PLAIN_FORBIDDEN`, `CHAT_RESTRICTED`, `CHAT_ADMIN_REQUIRED`,
  `USER_IS_BLOCKED`, `YOU_BLOCKED_USER`, `ALLOW_PAYMENT_REQUIRED`, `PRIVACY_PREMIUM_REQUIRED`,
  `CHAT_GUEST_SEND_FORBIDDEN`, `SLOWMODE_MULTI_MSGS_DISABLED`. Look each up in the library's error list
  and say in the report which are constants there and which are compared as plain words.
- **For a forward**, an answer that can be about the SOURCE is never remembered under the destination:
  `CHAT_FORWARDS_RESTRICTED` (it keeps its own per-source record), and every word of `refused()` (a
  private or invalid channel, an invalid peer: the answer does not say which side). So for a forward only
  the words that can only be about writing to the destination are remembered (`CHAT_WRITE_FORBIDDEN`,
  `CHAT_SEND_PLAIN_FORBIDDEN`, `CHAT_RESTRICTED`, `CHAT_ADMIN_REQUIRED`, `USER_IS_BLOCKED`,
  `YOU_BLOCKED_USER`).
- Everything else (a message too old to edit, a reply to a deleted message, a text Telegram finds too
  long, an invalid reaction, a closed topic, a delete that is not allowed) is reported with its word and
  not remembered: the owner's next click of that kind in that chat makes its request.
- Tests: the probes P1 and P2 as tests (each word: the next click of the kind in the chat makes 1
  request); one word of the allow-list still held for the day and released by `TryAgain`; the coder's
  test at `act_test.go` 902 to 905 put right (the same destination, no `TryAgain`).

## 4. Findings 5 and 6: "sent before"

- `ActOutcome` gains `Partly bool`: true when the outcome is "sent before" for a forward of more than
  one message. Doc: Telegram refused the repeat, so at least one of the messages arrived earlier; which
  ones is not known here (64 of 99 on record for a first attempt answered with a server error); the caller
  looks in the chat for each. For a send (one random id) "sent before" stays whole.
- `RANDOM_ID_DUPLICATE` is recognised on the raw answer in `report`, before the mapping by code, whatever
  its code (Telegram's public list gives 500 for it; today a 500 becomes "not known"). Keep the type
  reachable the way `newDefiniteError` does. Tests with code 400 and code 500, send and forward.
- The mirror's `ForwardBatch` has the same gap through `once` (pre-existing, the mirror's file): do not
  change it; I tell the mirror track.

## 5. The minor findings

- 7: the door (the lock from the cap's check to `Begin`) is shared by every Actor made from the same
  Forwarder: a small registry in `act.go` keyed by the `*Forwarder` (not a field in `forward.go`). Test:
  probe P5 with two Actors of one Forwarder: 1 request and one cap refusal.
- 8: a click the ledger dates ahead of the clock counts as dated now (and is counted in a counter of its
  own); the hold never exceeds the window. Test: probe P6.
- 9: the span asked of `Sent` is at least one second whatever `Window` is; a `Window` below a second, a
  `PerSecond` or `PerWindow` below 1 take the defaults in `NewActor` (say so in `ActConfig`'s doc). Test:
  probe P7.
- 10: a `Topic` is accepted only when the chat is a forum (`ChatRef.Forum`); otherwise `ErrActBadAction`,
  no request. Put the coder's test at `act_test.go` 1101 right (a forum chat).
- 11: the chat is handed to `IsMirror`, `ChatRefusal` and compared with `Sent`'s clicks as
  `ChatRef{Kind, ID}` only; the `ActLedger` and `ActConfig` docs say implementations key on kind and id.
  Test: a refusal recorded without the flag is found by a click whose chat carries it, and the reverse.
- 12: `TestActR8CapTwoAtOnce` made deterministic (a ledger that holds the first click's `Begin` until the
  second has read `Sent`, as the probe does); see it fail with the door removed.

## 6. Said in the docs, no code

In `Do`'s or the package's doc for piece 2: the cap counts a forward as one request (the count of its
messages against the mirror's hourly bound is the caller's); a read mark counts against the cap like any
click; "one's own message" for an edit or a delete cannot be judged here (the caller checks it from the
catalogue before the click is queued; in a channel where the account is an admin a delete would remove
anyone's message).

## 7. Runs, report, hand-back

- While working: named tests only, as in K8 (`go test -count=1 -run 'TestAct' ./internal/telegram/`), the
  memory check before each go command, `GOGC=25 GOMAXPROCS=2`.
- Once at the end: `go build ./...`; `gofmt -l internal/telegram internal/collector`;
  `go vet ./internal/telegram/ ./internal/collector/`; `TestAct` by name; the forwarder's and the record's
  tests by name (`-run 'Forward|Mirror|Rename|Memo|Wait|Privacy'`); the collector's two named above. No
  whole package, no race detector, no Docker: mine.
- Add a section "The fix round (11-15 night)" to `archiver/docs/progress/core-act-REPORT.md`: each
  finding's number, what changed (file, function), its test's name and whether you saw it fail first; the
  API as it is now where it changed (`ActOutcome`, `ActLedger`'s contract, the new outcome).
- Commits as before (`git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, the message
  ending with a blank line and `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`), pushed;
  `git status --short` empty.
- Your final message: the head's full hash, the merge's result, each finding with its test and "seen
  failing first: yes or no", the commands with results and seconds, and anything of the review you
  disagree with after reading the code (say it; do not silently skip a finding).
