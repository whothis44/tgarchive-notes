MAY BE LISTED AFTER THE MUST-FIXES

# Independent review of K8, the client's request layer (wip/core-act at 79debb9f against 4daa0309), 2026-11-15

Read in full: the design note, the brief K8, TRIED-BEFORE 24 and 25, TELEGRAM-FACTS 11, the whole of `act.go`,
the diff of `call.go`, `memo.go`, `counters.go`, the code it stands on (`once`, `call`, `held`, `stated`,
`takeWait`, `classify`, `refused`, `definite`, `safeErr`, `cleanRPC`, `terminal`, `answered`, `flush`,
`ForwardBatch`, `checkBatch`, `updatesOf`, `inputPeerOf`, `memo.check/save/remember/checkWait`, `order.go`),
both test files, the coder's report, and the generated request types of gotd v0.166.0 for every request built.

Probes: `C:\Users\trabi\Claude\Projects\Telegram\wt-core-act-review-scratch\zz_k8review_probe_test.go`, loaded
with `overlay.json` beside it; output in `probe-output-1.txt` there. Run:
`GOGC=25 GOMAXPROCS=2 go test -count=1 -overlay <scratch>/overlay.json -run 'TestProbeK8' -v ./internal/telegram/`
(7 s, all pass: each probe logs what happened). Also run, unchanged tree: `go vet ./internal/telegram/` clean,
`gofmt -l internal/telegram` empty, `go test -run TestAct ./internal/telegram/` ok (0.17 s). Tree untouched,
`git status --short` empty, HEAD 79debb9f.

Count: 1 MUST FIX, 4 SHOULD FIX, 7 MINOR.

## Findings, most serious first

### 1. MUST FIX (before the merge; outside this piece's files). PLAUSIBLE by reading (the coder's report says the same).
`internal/collector/status_file.go:55` (`notCounted`) and `internal/collector/countsfix_test.go:614`
(`TestNotCountedRepeatWaitsDerived`). The six new `KindStats` fields (`counters.go:105-110`) are kinds whose
requests do not go through a method named `call` (they go through `report`), so the test's reading of the
telegram package (`fedRepeatWaitKinds`, countsfix_test.go:534) wants `repeat_waits.act_send` ... `act_read` in
`notCounted`, which lacks them: the collector's test fails once this is merged, and the status file tells a
reader nothing about six counts it does not have. The integrator's full runs would not catch it (the collector
is not a changed package of this piece). Not run here (other packages are out of this review's bounds).
**For the owner:** a red test on the main branch and a status file that reads an absent count as 0.
**Smallest fix:** the six lines in `notCounted`, in the same merge (or the piece lists the collector as a
package whose whole tests run before the merge).

### 2. SHOULD FIX. CONFIRMED. The account's refusal, or a stated wait, that lands while `Begin` runs does not stop the request.
`act.go:526` (`terminal`, the only R6 check, at the top of `Do`), `call.go:423-446` (the wait checks, then
`begin()`, then the request at 451 with no check in between). `Begin` is a durable catalogue write (piece 2), so
the gap between the last check and the request is a database commit long, not nanoseconds as in `once`.
Probe `TestProbeK8RefusalDuringBegin` (a ledger whose `Begin` lets the mirror's answer land first):
- `P4 refusal recorded during Begin (record "PEER_FLOOD"): the click still made 1 request(s), outcome kind 1, err <nil>`
- `P4 a wait on forward recorded during Begin (until +31s): the click's forward made 1 request(s) inside it, outcome kind 1, err <nil>`
**For the owner:** one write after Telegram said PEER_FLOOD/USER_RESTRICTED (which may lengthen the
restriction), or one forward inside a wait the mirror was just told. Reachable only when the mirror's request (or
a second Actor's) runs at the same time as a click; the design (section 3.4) says one request at a time on the
account's connection, but nothing in piece 1 enforces it, and `ForwardBatch` and `Do` may be called together.
The check number is no help here: `report` passes the kind check's number (`call.go:451`), so a test built on
`CheckOrder`/`SetRecordHook` would judge such a request "passed its check before the record" and excuse it.
**Smallest fix (either):** (a) in `report`, right after `begin()` returned nil, read the account's refusal (in
memory: `f.refused`, `f.unsaved`) and the two wait keys again (memory and store, as `checkWait`/`check` do) and,
when either holds, send nothing and return a held error, which `Do` records through `End` as "not sent"
(`OutNone`, `Requests` 0); the brief's "every local no writes nothing through End" needs that one exception; or
(b) state it as a contract of `Do` in its doc and the brief of piece 2: never called while any other request of
the account (the Forwarder's included) is out, and piece 2's race run tests that.

### 3. SHOULD FIX. CONFIRMED. A refusal caused by a forward's SOURCE blocks every forward INTO the destination for a day.
`act.go:1148` (every definite answer becomes `OutRefused` of the click's `Chat`, which for a forward is the
destination), read back through `ChatRefusal(ctx, account, act.Chat, act.Kind, ...)` at `act.go:579`.
`CHAT_FORWARDS_RESTRICTED` (the source protects its content: `act.go:1151`), and equally `CHANNEL_PRIVATE` or
`MESSAGE_ID_INVALID` of the source, are recorded as the destination's refusal of "forward".
Probe `TestProbeK8SourceRefusalBlocksDestination`:
`P1 23 h later, another unprotected source into the same chat, no TryAgain: requests 0, outcome kind 0, earlier refusal true (... (CHAT_FORWARDS_RESTRICTED); nothing is sent)`.
**For the owner:** one try to forward from a protected chat into Saved Messages, and every forward into Saved
Messages from any chat is refused for 24 hours with a misleading word, until "try again" is clicked each time.
The coder's own test hides it: `act_test.go:902-905` sends the second forward to another destination with
`TryAgain`.
**Smallest fix:** for a forward, do not record source-caused refusals as the destination's: at least
`CHAT_FORWARDS_RESTRICTED` (it already has its own per-source record), and the answers that name the source
(`CHANNEL_PRIVATE`/`CHANNEL_INVALID`/`MESSAGE_ID_INVALID` cannot be told apart by chat, so either record them
under the source, or not at all). Concretely: a field in `ActOutcome` (say `Remember bool`, or `RefusedChat
ChatRef`) that piece 2's `ChatRefusal` reads, set only for refusals that are about the destination.

### 4. SHOULD FIX. CONFIRMED. Refusals about one message, one reaction or one text block the whole kind in that chat for a day. The brief asks for it (R7) and is wrong there.
`act.go:1144-1156` with `act.go:577-590`. Probe `TestProbeK8MessageRefusalBlocksChat`, each "the next one in
the same chat an hour later: requests 0, refused earlier true":
`MESSAGE_EDIT_TIME_EXPIRED` (an old message: every edit in the chat refused), `MESSAGE_AUTHOR_REQUIRED`,
`REPLY_MESSAGE_ID_INVALID` (a reply to a deleted message: every plain send to the chat refused),
`MESSAGE_TOO_LONG` (Telegram's own count of one text), `REACTION_INVALID` (one emoji: every reaction refused),
`MESSAGE_DELETE_FORBIDDEN`. By the same path, by reading: `TOPIC_CLOSED` (one topic closes every send to the
forum), `MEDIA_CAPTION_TOO_LONG` (an edit of a caption: the text limit used is `message_length_max`, not the
caption's), `MESSAGE_EMPTY` (a text of only U+200B passes `textFits`, act.go:760), a `Topic` on a forum's
General topic.
**For the owner:** after one ordinary mistake the chat looks broken for a day for that kind; "try again" must
be clicked for each later click. It never sends more (it fails safe), which is why it is not a must-fix.
**Smallest fix:** remember only refusals of the chat or the account's standing in it (a short allow-list:
`CHAT_WRITE_FORBIDDEN`, `CHAT_SEND_PLAIN_FORBIDDEN`, `CHAT_RESTRICTED`, `USER_BANNED_IN_CHANNEL`,
`CHANNEL_PRIVATE`, `CHAT_FORBIDDEN`, `CHAT_ADMIN_REQUIRED`, `USER_IS_BLOCKED`, `YOU_BLOCKED_USER`,
`ALLOW_PAYMENT_REQUIRED`, `PRIVACY_PREMIUM_REQUIRED`, `CHAT_GUEST_SEND_FORBIDDEN`, `SLOWMODE_MULTI_MSGS_DISABLED`;
`refused()`'s list); every other refusal is reported with its word and not remembered (same `ActOutcome` field
as finding 3).

### 5. SHOULD FIX. PLAUSIBLE (the outcome's shape CONFIRMED). "Sent before" on a forward of several messages claims the whole first attempt was carried out.
`act.go:1122-1126` and the doc of `OutSentBefore` (`act.go:471-473`: "the earlier request was carried out").
TELEGRAM-FACTS 11: a first attempt can be carried out in part (64 or 65 of 99), and the mirror's own doc
(`forward.go:45-51`) says "at least partly". Not on record: whether Telegram answers a repeat that way when
only some of the ids were used. Probe `TestProbeK8SentBefore`:
`P3 a forward of 2 answered as a repeat (code 400): outcome kind 8, err <nil>, NewIDs 0, Missing 0` (no
error, nothing missing, nothing said about a part).
**For the owner:** after "not known" and "send again", the page says it was sent; up to all but one of the
messages may be absent and nothing tells the owner to look.
**Smallest fix:** for a forward of more than one message, OutSentBefore carries a flag (or its doc and the
page's word) "at least one of them arrived earlier; look in the chat", and piece 2 runs the "is it in the chat"
match for every message of the click, as for an unknown outcome. For a send (one random id) "sent before" stays
as it is.

### 6. MINOR. CONFIRMED in the code; PLAUSIBLE for Telegram. `RANDOM_ID_DUPLICATE` with code 500 is "not known", never "sent before" (the mirror too).
`call.go:500` with `errors.go:156-159`: a code-500 answer is `kServerError`, and `report` returns
`&UnknownError{cause: mapped}` where `mapped` no longer holds the RPC error, so `tgerr.Is(err,
"RANDOM_ID_DUPLICATE")` at `act.go:1122` cannot see it. Telegram's public error list gives
`500 RANDOM_ID_DUPLICATE` for messages.sendMessage and messages.forwardMessages; the tests use 400
(`act_test.go:1227`, `act_privacy_test.go:86`). Probe `TestProbeK8SentBefore`:
`P3 code 500 RANDOM_ID_DUPLICATE on send: outcome kind 9 (... OutUnknown=9), unknown true` (same for forward),
and `P3 the mirror's ForwardBatch, the same answer: already forwarded false, unknown true` (pre-existing in
`ForwardBatch`, not this piece).
**For the owner:** "send again" after a lost answer can only ever say "not known" again; it never duplicates
(the random id is the same), so it fails safe.
**Smallest fix:** test `RANDOM_ID_DUPLICATE` on the raw error inside `report` (before the server-error
mapping), keeping the type reachable (as `newDefiniteError` does with `cleanRPC`); a test with code 500. Tell
the mirror track for `ForwardBatch`.

### 7. MINOR. CONFIRMED. The cap is per Actor: two Actors of one account pass it at the same instant.
`act.go:257` (`door` is the Actor's), `act.go:597-628`. Probe `TestProbeK8CapTwoActors`:
`P5 two Actors, one account, one instant, cap 1 a second: 2 requests; errors <nil> / <nil>`.
A fresh Actor after a restart is held (the ledger), as the coder's test shows.
**Smallest fix:** say in `NewActor`'s doc and piece 2's brief: one Actor per account per process (or put the
door on the Forwarder, which is already one per account).

### 8. MINOR. CONFIRMED. A click the ledger dates ahead of the clock holds every write that long.
`act.go:827` counts a click with `At` after now (the PC's clock stepped back) and the hold ends at its `At`
plus the span. Probe `TestProbeK8CapFutureClick`: `P6 a click 1 h ahead of the clock: every write held for 1h0m1s`.
Fails closed, so minor. **Smallest fix:** a click dated more than a few seconds ahead counts as dated now (and
is counted), or the hold is bounded by the window.

### 9. MINOR. CONFIRMED. A `Window` setting below one second defeats the per-second bound.
`act.go:797-807`: `Sent` is asked only since `now - Window`, and the per-second bound is judged on that list.
Probe `TestProbeK8WindowBelowSecond`: `P7 Window 500 ms, PerSecond 1: two sends 600 ms apart made 2 requests`.
**Smallest fix:** `span = max(Window, time.Second)` (or refuse a Window below a second in `NewActor`).

### 10. MINOR. CONFIRMED by the coder's own test. A `Topic` on a channel that is not a forum is sent as a reply.
`act.go:653` allows `Topic > 0` for any `ChatChannel`; `act.go:903-911` turns it into `reply_to_msg_id`. In a
plain supergroup that is a reply to that message, which the owner did not click. `act_test.go:1101` sends
`topic: 3` to `actChan`, whose `Forum` is false, and expects the reply header.
**Smallest fix:** `act.Topic > 0` only when `act.Chat.Forum` (ChatRef has the flag), else `ErrActBadAction`.

### 11. MINOR. PLAUSIBLE. The chat is handed to the callbacks and the ledger with its `Forum` flag.
`act.go:558` (`IsMirror`), `act.go:579` (`ChatRefusal`): `act.Chat` is passed as given, while `protected`,
`restrictSource` and the read mark's bound strip `Forum` (`act.go:770`, `1165`, `838`). A ledger or mirror
list keyed on the whole `ChatRef` (as the test's fake ledger is, `act_test.go:297`) misses a match when one
caller sets the flag and another does not: a remembered refusal or a mirror not seen.
**Smallest fix:** normalise to `ChatRef{Kind, ID}` before every callback and ledger call (or say in the
interface that implementations key on Kind and ID only).

### 12. MINOR. PLAUSIBLE. `TestActR8CapTwoAtOnce` catches a missing door only by timing.
`act_test.go:1003-1028`: two goroutines; without the door both must read `Sent` before either `Begin` for the
test to fail, which a scheduler may or may not do. The coder reports seeing it fail; it may also pass with the
door removed. **Smallest fix:** a deterministic version (a ledger whose `Sent` or `Begin` blocks the first
click until the second has read `Sent`, as probe P5 does with `Begin`).

## Checked and found sound (not to be checked again)

- **One request per call:** `report` sends exactly once, after `begin()` returned nil, never after it failed
  (`call.go:446-452`); no retry, no sleep (fake clock shows none). `Limits` uses `call` (retries) but is
  help.getConfig, a read.
- **`End`:** called exactly once on every path after a successful `Begin` (`act.go:630-648`), on `saveCtx`;
  never without a `Begin`. Only a panic in the library's encoder would skip it (the row then stays "sending",
  which is "not known": acceptable).
- **Outcome by class of `classify`:** FLOOD_WAIT/FLOOD_PREMIUM_WAIT: waited (memory first, then the record on
  its own context, also when the caller's context ended); SLOWMODE_WAIT on send/forward: waited, the chat's
  key only (`wait:slowmode:<marked id>`, under the 48 h cap), never the kind's; on the other four kinds it is a
  definite refusal; Timeout -503, network deadline, lost connection, code 500+, the caller's cancel, an answer
  of a kind not taken, and a code below 300: not known; FROZEN_METHOD_INVALID: OutFrozen, remembered per kind
  for FrozenFor (in memory first, so in this process it fails closed when the store cannot save; after a
  restart one request may ask again: acceptable, the `Frozen` callback is the first guard); lost login:
  OutSignedOut; PEER_FLOOD/USER_RESTRICTED: through the Forwarder's `answered`, reachable through
  `definiteError`'s sanitised RPC (probe of the coder's test and by reading); `refused()`'s list and every
  other 300-499: OutRefused. A successful answer naming no message (send or forward), another random id only,
  `updatesTooLong`, `updateShort`: not known. Edit, react, delete, read: done on any answer.
- **`report` against `once`, every class where they differ:** (a) a definite answer with a kind other than
  `kRefused` (FILE_REFERENCE_*, FILE_ID_INVALID, LOCATION_INVALID with a 4xx code): `once` returns the engine's
  sentinel, `report` a definite refusal; these are Telegram's answers to the request, so "not carried out" is
  true. (b) anything unlisted: `once` returns `mapped`, `report` "not known" (safer). (c) SLOWMODE as above.
  (d) waits not slept. No class turns "not known" into "refused": `definite()` needs an RPC code 300-499, and
  `kCancelled` is only ever given to an error that is no answer.
- **Waits:** recorded before the call returns on every path, including a cancelled caller (`keepWait` saves
  on `saveCtx`); a record that fails leaves it in memory and returns `*MemoError` with `Stated`; the next click
  of the kind is held without a request (also by a fresh Actor on the same Forwarder, and after a restart when
  the record was saved). The client's forward and the mirror share `wait:forward` (methodWhat); delete's and
  the read mark's two methods share one key each. No existing kind's key changes (`methodWhat` gained one case).
- **Slow mode:** cannot hold another chat (the key is the marked id); holds its own sends and forwards until its
  end. It is learnt only from an answer (a first send after a successful one may cost one refused request:
  Telegram's word, not ours).
- **R6 both ways and unsaved:** sound as tested (the coder's test runs all six kinds, both directions, and a
  store that cannot save). The only gap is finding 2.
- **R7 what is remembered:** only OutRefused; never a wait, frozen, signed out, unknown, sent before, not
  modified, or the account's refusal. `TryAgain` overrides only `ChatRefusal` (not R4, R5, R6, R8, R9, nor the
  protected-source record). Over-breadth is findings 3 and 4.
- **The cap's edges:** 1 a second and 30 in 5 minutes are half-open windows, correct at the edges; out-of-order
  clicks are sorted; two clicks at one instant on one Actor make one request; CapOff skips `Sent` for all but
  read marks; zero or negative settings take the defaults; `Sent` failing sends nothing.
- **Requests, field by field** (gotd v0.166.0): sendMessage flags exactly 0 or the reply bit; no entities,
  no_webpage, silent, background, clear_draft, noforwards, invert_media, schedule, send_as, quick reply,
  effect, allow_paid_stars, suggested post. forwardMessages: flags 0 or top_msg_id only. editMessage: only the
  message bit. deleteMessages: revoke as asked; channels.deleteMessages for every channel kind (and refuses a
  channel delete not for everyone). sendReaction: one `reactionEmoji` or none; no big, no add_to_recent, never
  the paid method. readHistory by chat kind. Text: UTF-16 units, the stricter count, a surrogate pair at the
  edge counted as two; not cut.
- **Privacy:** every new log line is a constant format with numbers, the kind word, and an error type;
  `ActRefusedError`, `ActCapError`, `WaitRunningError`, `StatedWaitError`, `MemoError`, `UnknownError` texts
  carry numbers and Telegram's constant word (or "rpc N") only; a remembered type from the ledger is checked by
  `constantName`. The coder's canary test covers done, waited, slow mode, refused, unknown, frozen, sent before,
  the account's refusal and each local "no", with store errors that carry names.
- **Concurrency inside one Actor:** state under `mu`, the door never held across a request; two callers with
  one click make one request through the ledger's compare-and-set. No goroutine started.
- **Code that already ran:** `once`, `call`, `held`, `stated`, `takeWait` unchanged; `forward.go` untouched;
  `MemoError` gains a field reachable by `errors.As` only; `Stats` gains six fields read by reflection in
  `tgstore.TgKinds` and `KindsOf` (names stay equal: `TestTimingKindNamesAreTheCatalogueKinds` keeps
  holding by construction); the only consumer that breaks is finding 1. No flood-wait or rate-limit middleware
  wraps the client (`connect.go:77` refuses any), so nothing below `report` repeats a request.

## What I could not check

- Telegram's real codes and behaviour: whether RANDOM_ID_DUPLICATE comes as 400 or 500 (finding 6), whether a
  repeat after a partial forward is refused whole (finding 5), whether the self user's access hash arrives in
  the chat list (the coder's Saved Messages note; `inputPeerSelf` would remove the question).
- The collector's test (finding 1) and any other package: out of bounds for this review.
- The race detector on `Do` with the Forwarder at once: out of bounds; finding 2 is the reason it matters.
- Whether the answers' updates (pts) dropped by `Do` (as `ForwardBatch` drops them) delay the live monitor's
  sight of the sent message (the design relies on it for the "not known" match).

## Where the brief or the design is wrong or silent

- **R7 is wrong** to list "an invalid reaction, an edit past its time" as refusals of the chat to remember for a
  day (finding 4); and silent that a forward has two chats (finding 3).
- **R2 makes the last check and the request a `Begin` apart** ("every local no decided BEFORE Begin and writes
  nothing through Begin or End") and is silent on checking again after it (finding 2).
- **R3 is silent on "sent before" for a forward of several messages** (finding 5).
- **R8 differs from the design:** the design says "a forward counted by its messages against the mirror's
  hourly bound", the brief "a forward is one". As built, 30 forwards of 100 messages (3,000 messages) fit in 5
  minutes, against the record's 200 in 13 s bringing a wait. Telegram's wait is still reported, so nothing
  worse than a wait follows; the owner should choose.
- **The design is silent whether a read mark is a "write" of the cap:** as built it uses the same 1-a-second
  and 30-in-5-minutes budget as sends (`act.go:818-836`), so opening many chats with the switch on can refuse
  a send.
- **"Delete one's own message" cannot be enforced here:** channels.deleteMessages deletes others' messages
  where the account is an admin, and messages.deleteMessages with revoke deletes the other side's messages in a
  private chat. Piece 2 must check the catalogue's "out" flag of every id before the click reaches `Do`
  (the design's section 6 puts "deleting other people's messages" out of this step).
- **One Actor per account** is assumed but not said (finding 7).

## Second pass (the fix round, e7624d5d)

MAY BE LISTED

Scope: `git diff 79debb9f e7624d5d -- archiver/internal/telegram archiver/internal/collector/status_file.go`
(act.go, call.go, act_test.go, act_fix_test.go, act_privacy_test.go, six lines of status_file.go), the fix
brief K8b, and section 9 of the coder's report, read last. The merge 7ddbdc60 changes no other file of
`internal/telegram`. Tree untouched: HEAD e7624d5d, `git status` empty.

Probes, all in the same scratch folder as the first pass:
- `zz_k8b_review_probe_test.go` with `overlay2.json`; output in `probe-output-2.txt`.
- `act_nodoor.go`, a copy of act.go with the door removed, with `overlay-nodoor.json`; output in
  `probe-output-nodoor.txt` and `probe-output-nodoor-4procs.txt`.
- The collector's named test; output in `collector-notcounted.txt`.

Runs:
- `go test -run TestAct ./internal/telegram/`: ok.
- `go vet ./internal/telegram/`: clean. `gofmt` lists nothing.
- The two door tests, 200 times each on the tree at GOMAXPROCS=4: ok.
- `go test -run TestNotCountedRepeatWaitsDerived ./internal/collector/`: ok (0.2 s).

Count of new findings: 0 MUST FIX, 0 SHOULD FIX, 5 MINOR (N1 to N5). N5 is part of finding 12, so it is not
counted again below.

### 1. The first pass's twelve findings

| # | Status | By code, and by a test that fails when the fix is undone |
|---|---|---|
| 1 | CLOSED | Six lines in `status_file.go:72-77`. `TestNotCountedRepeatWaitsDerived` passes here; the coder saw it fail before. |
| 2 | CLOSED | `call.go` `recheck`, called after `begin`. `TestActFixNotSentAfterBegin` covers the probe's two cases plus slow mode and an unreadable record: 0 requests, `End` once. It also checks the request carries the re-check's number. A narrower window remains: N1. |
| 3 | CLOSED | `rememberRefusal` returns false for every source-side word of a forward. `TestActFixRefusalsNotRemembered` and `TestActR7ProtectedSource` were put right: the same destination, no `TryAgain`. |
| 4 | CLOSED | The allow-list (`standingWords`, `standingOneChat`, `refused()`). `TestActFixRefusalsNotRemembered` tries 21 words; `TestActFixRefusalsRemembered` holds each listed word for the day and releases it with `TryAgain`. One word is questionable for a forward: N3. |
| 5 | CLOSED | `ActOutcome.Partly` for a forward of more than one message. `TestActFixSentBefore` asserts it. |
| 6 | CLOSED for the Actor | The repeat is read on the raw answer, codes 400 and 500 (`TestActFixSentBefore`). The mirror's `ForwardBatch` gap was left as the brief said. |
| 7 | CLOSED | The door belongs to the Forwarder. With one door per Actor, `TestActFixCapTwoActors` fails in 200 of 200 runs (overlay). The registry's key: N4. |
| 8 | PARTLY | The hold told is now one second, but the block lasts as long as before: N2. |
| 9 | CLOSED | The defaults and the one-second span. `TestActFixWindowBelowSecond`. |
| 10 | CLOSED | `shape` needs `Chat.Forum` (act.go, `shape`). `TestActFixTopicOnlyInForum`; `TestActFlags` now uses a forum chat. |
| 11 | CLOSED | The chat is handed over as `ChatRef{Kind, ID}` (act.go, `Do`). `TestActFixChatKindAndID`, both ways and a mirror. |
| 12 | PARTLY | `twoAtOnce` always passes with the door. With the door removed it fails in 200 of 200 runs at GOMAXPROCS=2 but in 299 of 300 at GOMAXPROCS=4: N5. |

### 2. The changed request path (`report`, `recheck`, `unread`, `Do`, `notSent`)

- **The re-check:** `recheck` runs only after `begin()` returned nil and before `*sent++`. Every path that
  fails it returns `*NotSentError` with no request (`call.go`, `recheck`).
- **The check number:** the request carries the number of the re-check's `checkWait`, the last check of the
  kind's wait. The slow-mode check comes before it and takes no number, which is harmless.
- **Recording through `End`:** in `Do` a `*NotSentError` becomes `notSent`: OutNotSent, `Requests` 0, `End`
  called once.
  - "Not sent" is recorded only when no request left, because `recheck` returns before the count and the
    send.
  - No row is left "sending" when nothing was sent, unless `End` itself fails (as before).
  - No `End` is missing or doubled: `!begun` returns before `End`, and every begun path reaches it exactly
    once.
- **A cancel between `Begin` and the request:** see N2a.

### 3. `RANDOM_ID_DUPLICATE` read on the raw answer

- It is recognised only on the exact type, whatever the code (`call.go`, `report`).
- On a send or forward it becomes "sent before", and for a forward of more than one message `Partly` is set.
- On the other four kinds it is "not known", never remembered. Probe Q5: edit, delete, react and read each
  give outcome 9 (OutUnknown), `Remember` false.
- It cannot turn a non-repeat into "sent before". It can turn a lost answer into "sent before" only when
  Telegram itself says the random id was used: for example, the library re-sent a request already carried
  out. That is true for a send, and `Partly` covers a forward.
- It is counted as `classify` maps it (400: NoRule; 500: ServerErrors). Sound.

### 4. The allow-lists

- Every word is about the account's standing in the chat written to, except one, `CHAT_SEND_PLAIN_FORBIDDEN`
  on a forward: N3.
- No source-side answer is remembered under a forward's destination: `refused()`'s words,
  `CHAT_FORWARDS_RESTRICTED` and `MESSAGE_ID_INVALID` are all false (the test's first eleven cases).
- `CHAT_ADMIN_REQUIRED` on a forward is most likely the destination (a broadcast channel where only admins
  post). It is PLAUSIBLE that it could be the source; that is not on record.

### 5. The door registry and `actDoorWaits`

- **The hook:** it is unexported, set only by `twoAtOnce` with a deferred reset, and nil in production.
  `lock` calls it only when `TryLock` fails, so production behaviour does not change.
- **Double locking and the door across requests:** a lock is never taken twice (the `open` guard). The door
  is released inside `begin`, before `recheck` and the request, so it is never held across a request.
- **Deadlock:** a deadlock happens only if a ledger's `Begin` calls `Do` for the same account (the first
  pass's probe did exactly that; no real ledger does).
- **New since the fix:** the door is shared by every Actor of the Forwarder and `lock` ignores the context.
  A `Begin` that hangs (bounded only by the catalogue's own context handling) holds every click of the
  account, and a cancelled click cannot leave the queue. A remark, not a finding: `Begin` receives the
  context.
- **`TestActR8CapTwoAtOnce`:** deterministic when the door is present, not quite when it is absent (N5).

### 6. The coder's four departures

- **A future-dated click held one span at a time:** not acceptable as it is (N2b). The owner is told "1 s"
  again and again for as long as the clock is behind.
- **A cancel after `Begin` recorded as "not sent" with the word "record unreadable":** the outcome is true,
  but the word is false and the click is counted as a store failure. Minor (N2a).
- **A forward not remembering the four one-chat words:** acceptable. The cost is one refused request per
  later click.
- **The registry's memory:** acceptable only if keyed by account (N4).

### 7. New findings (all MINOR)

**N1. MINOR. CONFIRMED. The re-check reads the account's refusal first, then the record of waits.**
- Where: `call.go`, `recheck`: `refusal()` is called first, then `memo.check` and `memo.checkWait`, each a
  store read.
- What happens: a PEER_FLOOD that lands during those reads is not seen.
- Probe Q3 (`TestProbeK8bRefusalDuringRecheckRead`): `PEER_FLOOD recorded during the re-check's read of the
  waits (record "PEER_FLOOD"): 1 request(s), outcome kind 1`.
- For the owner: the window of finding 2 is now two store reads long instead of a `Begin`. It is reachable
  only when requests of one account run at once, which piece 2 is meant to prevent.
- Smallest fix: after the store reads, look once more at both memories right before the request: the
  Forwarder's `refused` and `unsaved` (a memory-only callback) and the memo's local record (`memo.local`
  under `memo.mu`). Each answer is written to memory first, so nothing that landed before that last look is
  missed.

**N2a. MINOR. CONFIRMED. A cancel between `Begin` and the request.**
- Where: `call.go`, `recheck`, which never asks `ctx.Err()` itself.
- With stores that ignore the context, the request is still made on a cancelled context. Probe Q2,
  `ctx-aware store false`: the fake received 1 request. The fake ignores the context and answered, so the
  outcome was OutDone. The real library would most likely answer "not known" with `Requests` 1 for a request
  that may never have left.
- With a store that answers the context's end, the result is OutNotSent, reason "record unreadable",
  `StoreFailures` 1 (Q2, `ctx-aware store true`).
- For the owner: either a click abandoned before its request is still sent, or "not sent" is given a false
  reason and counted as a store failure.
- Smallest fix: `if ctx.Err() != nil` first in `recheck`, returning a fourth reason, `NotSentCancelled`
  ("cancelled"), not counted as a store failure.

**N2b. MINOR. CONFIRMED. A future-dated click blocks every write until the clock passes its date.**
- Where: act.go, `capped`, which re-dates such a click to "now" at every check.
- Probe Q1 (`TestProbeK8bFutureClickHoldsTheHour`) with a click dated one hour ahead: refused at +0 s, +2 s,
  +10 min and +59 min, told "1s more" each time; 0 requests in the hour.
- For the owner: after the PC's clock steps back an hour, nothing can be sent for that hour, while the page
  counts down one second again and again.
- Smallest fix: count a future-dated click in the window bound only (as dated now), never in the per-second
  bound, so one stale click never blocks. Or age it from the moment this process first saw it (a small map
  under `a.mu`).

**N3. MINOR. PLAUSIBLE. `CHAT_SEND_PLAIN_FORBIDDEN` is in the forward's remembered list.**
- Where: act.go, `standingWords`, which applies to forwards too.
- On a forward this word is about the content: a text message forwarded into a chat that allows media but
  not plain text.
- For the owner: after one text forward into such a chat, media forwards into it are refused for a day.
- Smallest fix: keep it for send and edit only (move it to `standingOneChat`).

**N4. MINOR. PLAUSIBLE. The door registry is keyed by `*Forwarder` and keeps it for the life of the process.**
- Where: act.go, `actDoors` and `doorOf`.
- The automatic mirror makes a Forwarder per session (`internal/collector/mirror_auto.go:403-411`, on
  `s.auto`). If piece 2 makes the click's Actor per session, every reconnection keeps an old Forwarder
  reachable through the map, and with it its invoker and memory.
- Two Forwarders of one account (the auto mirror's, and the settle command's at `mirror_settle_cmd.go:90`)
  also get two doors.
- Smallest fix: key the registry by the account id (`int64`). That is the "account's door" the docs
  describe, and it costs a few bytes per account.

**N5. MINOR. CONFIRMED (part of finding 12). `twoAtOnce` can miss a missing door.**
- Where: `act_fix_test.go`, `twoAtOnce` (lines 47-75): `holdLedger.Sent` calls `tell` before the inner
  `Sent`. With no door, the first click's `Begin` and the second click's `Sent` then race.
- Mutation with the door removed: the test failed 200 of 200 times at GOMAXPROCS=2 and 299 of 300 at
  GOMAXPROCS=4 (one false pass).
- Smallest fix: call `tell` after the inner `Sent` has returned (or hold the second click there until the
  first click's `Begin` has returned).

### Remarks for piece 2 (no change asked here)

- The click's Actor must be made from the same Forwarder as the automatic mirror of that account (or, after
  N4, simply the same account). Otherwise the memo cache and the refusal memory are separate objects, joined
  only through the stores.
- `ChatRefusal` must filter on `Remember`. The fake ledger does; the catalogue must too.
