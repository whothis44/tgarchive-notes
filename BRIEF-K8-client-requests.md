# Brief K8: the client's acting side, piece 1 of 4: the request layer (Core, K-3, 2026-11-15 night)

For one Opus coder. The design the owner agreed to is `DESIGN-CORE-client-actions.md` in this folder
(board item 28: "yes, recommended", all six choices). This piece is its section 7, point 1, with one change
of the split, said below. **It writes to Telegram for the owner. Nothing of it runs against Telegram: every
test is on the package's own fake.** After your hand-back it gets an independent read-only review with
probes before any full run; the first real use is the owner's own, later, in Saved Messages on the test
account.

- Copy: `C:\Users\trabi\Claude\Projects\Telegram\wt-core-act`, branch `wip/core-act`, cut from the main head
  4daa0309. Go module in its `archiver` folder. Work only there.
- You hand back commit-ready work, pushed to `private` as `wip/core-act` (work in progress pushed as you go:
  a session can stop at any moment). Never the branch `claude/charming-feynman-vm2xia`, never `origin`.

## 1. What the old app already knows (the note every brief starts with)

- The old app (`wt-v12.31`) sends no text, reply, edit, delete of one message, reaction or read mark. Its
  "auto-forward" uploads the file again with a new random id at every try and takes a lost answer for
  "failed" (a later try posts a second copy). So there is **no number from the old app for any of these
  requests** and nothing of it to port.
- The numbers on record are the new app's own, from the mirror on the test account (`TELEGRAM-FACTS.md`
  section 11, five runs, "looks like"): a stated wait meant nothing was done; a server error meant "partly
  done" (64 of 99 forwarded); messages Telegram did not carry out could be sent again under the same random
  ids six hours later; 200 forwards in 13 s brought a 9 s wait, 352 at 20 s apart did not.
- **So this piece is built on the mirror's request layer, not anew:** `internal/telegram/call.go` (`once`,
  the record of waits) and `forward.go` (the account's refusal, the protected source). What worked there is
  the default; nothing here changes how the mirror behaves.

## 2. Read first, yourself, in full

`DESIGN-CORE-client-actions.md`; `archiver/docs/TRIED-BEFORE.md` sections 24 and 25 (the thirteen rules for
anything that acts for the owner); `archiver/docs/TELEGRAM-FACTS.md` section 11; in `internal/telegram`:
`call.go`, `forward.go`, `memo.go`, `errors.go`, `counters.go`, the frozen record in `dialogs.go` (about
line 128), and the tests `forward_test.go`, `fix_forward_test.go`, `privacy_test.go`, `fake_test.go`. The
library's generated request types are in the module cache: read each type you use there (its fields and
flags); never assume a field.

## 3. Scope

**In:** a new type `Actor` in `internal/telegram` (new files `act.go`, and tests `act_test.go`,
`act_privacy_test.go`; more files if it reads better), the seven actions as six request kinds, their rules,
their counters, a variant of `once` that does not sleep. Small additions in `call.go`, `counters.go`,
`memo.go` and `errors.go` where the Actor needs them.

**Not in (later pieces; do not build them):** the catalogue's ledger table and its doors, the click's turn
in the account loop, any route or page, the collector's fake (`internal/collector/faketg`: its answers for
these requests move to piece 2, where they are first used; this is the one change from the design's split),
the collector itself. No schema step. No `go.mod` change. No goroutine.

**`forward.go` is the mirror track's file: do not edit it.** `act.go` is in the same package and may use
its unexported parts (`terminal`, `answered`, `storeErr`, `flush`, the `restricted` maps under `f.mu`,
`checkBatch`, `updatesOf`, `peersOf`, `inputPeerOf`, `saveCtx`). If you find that a block inside one of its
functions must be split out to be shared, stop at the smallest mechanical move, say so in the report, and I
tell the mirror track.

## 4. The seven actions

One call of the Actor is at most ONE request to Telegram. No request for typing, online, drafts or a link
preview. Text is sent as typed: no entities, no formatting read.

| Action | Request | Notes |
|---|---|---|
| Send a text | `messages.sendMessage`, the caller's random id | optional forum topic (the reply header's top message) |
| Reply | the same, naming the message replied to | |
| Forward to a chat | `messages.forwardMessages`, the caller's random ids, one per message | any destination kind; at most the server's maximum; an album never split (`checkBatch`); optional topic |
| Edit one's own message | `messages.editMessage` | "not modified" is its own outcome: done, nothing changed |
| Delete messages | `messages.deleteMessages` (with or without "for everyone"), `channels.deleteMessages` in a channel or supergroup | 1 to 100 ids; the answer's count is reported (0: already gone) |
| React | `messages.sendReaction`, one plain emoji, or none to take one's reaction back | never a paid or custom one |
| Mark as read | `messages.readHistory`, `channels.readHistory`, up to a message id | |

- **The random ids are the caller's:** made once per click and kept in the ledger (piece 2), handed in. The
  Actor never makes or changes one, and never derives one as the mirror does. Export one helper that makes a
  random id (crypto/rand, never 0) for the later pieces. The same call made again with the same random id
  (the owner's "send again" after an unknown outcome) is answered by Telegram, where it still remembers, as
  a repeat: that is its own outcome, "it was sent before", never an error to retry.
- **Never paid, never changed in kind:** no request sets a flag that spends Stars, sends silently,
  schedules, protects, or anything else the owner did not click. A test decodes the request the fake
  received and compares its flags with the exact expected bits.
- **Text:** empty is refused; longer than the server's maximum is refused, never cut. The maximum comes
  from `help.getConfig` (the Actor's own `Limits` call, one counted request of the kind "config", as
  `ForwardLimits` does it; it also takes the forward maximum); before it is known a send is refused with no
  request. It is not on record whether Telegram counts characters or UTF-16 units: refuse on the stricter
  count; Telegram's own "too long" is then a refusal like any other.
- **Answers:** a send to a user or a basic group can be answered with `updateShortSentMessage` (the id is
  in it), elsewhere with updates holding `updateMessageID` for the random id: take both. An answer that
  names no message for a send or a forward is "outcome unknown", as in `ForwardBatch`.
- **Saved Messages** is the account's chat with itself, addressed as any user chat through `inputPeerOf`.
  Check by reading where the reader stores peers that the account's own user gets its access hash stored;
  if it does not, do not add a special case silently: say in the report what is missing.

## 5. The rules, each kept by a test with its number

The Actor is made from the account's `*Forwarder` (so both share one memory of the account's refusal and of
protected sources, one record of waits, one set of counters) plus what is below. Settings come in as
config values with these defaults; reading them from the catalogue is piece 2.

**R1. One click, one request, never repeated by the program.** Every action goes out through a variant of
`once` (R4). After a timeout, a lost connection, a server error, a cancelled caller: exactly one request
was sent and the outcome is "not known". Not after a wait, not after anything, is a request sent again
inside the call.

**R2. Written down before it is sent.** A required interface, defined in this package and implemented by
the catalogue in piece 2 (a fake in your tests). It carries no text and no title:
- `Begin(ctx, ref, at)`: marks the click `ref` (the ledger's own number, opaque here) as "sending",
  durably, and must refuse a click that is not waiting to be sent (a compare-and-set: its error for "spent"
  is a sentinel of this package). **No request leaves before `Begin` has returned nil; when it fails,
  nothing is sent.** So one ledger row can never produce two requests, also with two callers at once.
- `End(ctx, ref, outcome)`: the outcome (R3), on a context of its own as `saveCtx` gives it. When `End`
  fails the caller still gets the outcome, joined with `ErrStore`; nothing is sent again; the row stays
  "sending", which piece 2 shows as "not known" at the next start.
- `Sent(ctx, account, since)`: the clicks of the account whose request went out since then, each with its
  kind, chat and time (for R8 and the read mark's own bound).
- `ChatRefusal(ctx, account, chat, kind, since)`: the last refusal of that chat for that kind (R7).
Every local "no" below is decided BEFORE `Begin` and writes nothing through `Begin` or `End`: the caller
(piece 2) records those.

**R3. Outcomes, as one small value plus errors:** done (with the new message's id, or for a forward the
map of source id to new id and the ids the answer left out; for a delete the count); done, nothing changed
(an edit "not modified"); waited: not carried out, with the time sending is possible again; refused by the
chat, with Telegram's error type as the word; refused for the account (R6); sent before (the repeat); not
known. `Requests` is 0 or 1 and is always right.

**R4. A wait Telegram states is recorded and reported at once, never slept here, never shortened** (the
owner's choice 2: after a wait the owner sends again, the program does not). Add the variant beside `once`
in `call.go`: before the request, a wait still running for the kind is NOT slept: the call ends with a
typed error carrying its end, no request; a wait answered to the request goes into memory first (`stated`),
then into the record (`saveWait`, on its own context), and comes back at once as "waited" with its end
(the seconds plus the margin). A wait that cannot be recorded: `*MemoError`, as now. `once` and `call`
themselves do not change.
- **Keys:** a wait belongs to Telegram's method. The client's forward shares the mirror's key "forward", so
  a wait stated to either holds both (the mirror sleeps it, the client reports it); use `methodWhat` for
  that mapping. Delete's two methods share one key, the read mark's two share one, as `methodWhat`'s comment
  allows. Send and reply are one kind.
- **A chat's slow mode** (`SLOWMODE_WAIT_X`) is a wait of that chat only: recorded under a key of the chat
  (`chatMemoKey`; the chat's number never reaches a log line or an error text), reported as "waited" for
  that chat, and later sends to it before its end make no request. It never holds another chat. Read how
  `classify` maps it today and say so in the report.

**R5. Frozen: off.** A required callback says whether the account is known frozen (an error from it: no
request, `ErrStore`). Frozen: every action is refused in fixed words, no request. A request answered
`FROZEN_METHOD_INVALID` is remembered in the record as `dialogs.go` does for the chat list, and later calls
of that kind make no request until that record has passed.

**R6. A refusal of the account stops every write, the mirror's too.** `PEER_FLOOD` or `USER_RESTRICTED` on
any of the six kinds goes through the Forwarder's own `answered` (held in memory first, then the one shared
record; unsaved: every call refused until it is saved). Afterwards every Actor call and every Forwarder
call (`ForwardBatch`, `CreateMirror`, `CreateTopic`, `RenameMirror`) is refused without a request; and the
other way round: a refusal the mirror met stops the Actor. Checked at the top of every action (`terminal`).

**R7. A refusal of the chat** (no right to write, banned, a closed topic, a protected source, an invalid
reaction, an edit past its time: any definite answer that is not R6, a wait or frozen): reported with
Telegram's error type. Before a request, `ChatRefusal` is asked for the last day: when that chat refused
that kind within it, no request is made, unless the click says "try again" (the owner's click; it never
overrides R4, R5, R6, R8 or R9). A protected source (`CHAT_FORWARDS_RESTRICTED`) is also put into the
Forwarder's shared record as `ForwardBatch` does, so neither side asks that source again.

**R8. The cap, the app's own caution, a setting.** Per account: at most 1 request of these kinds a second
and 30 in any 5 minutes, judged from `Sent` (so it holds across a restart), every request that went out
counted whatever its answer; a forward is one. Over it: refused in fixed words with the time it opens
again, no request. The three numbers and "off" are config values. A read mark has its own bound as well: at
most one per chat in 30 s. `Sent` failing: no request.

**R9. The app's own mirror chats cannot be written to.** A required callback says whether a chat is one of
the app's mirrors (an error: no request). For a mirror: send, reply, forward INTO it, edit, delete, react
and read mark are refused in fixed words, no request. Forwarding FROM a mirror elsewhere is allowed.

**R10. Counted from the first call, per kind:** requests, answers, waits, refusals, unknown outcomes (the
existing `KindStats` per kind: new fields in `Stats` and their `pick` functions), and in a small struct of
the Actor's own: each local "no" by its reason (frozen, mirror, cap, waiting, the chat's remembered
refusal, spent, text, no access hash, no limits). Say in the report where the collector turns `Stats` into
its hourly rows, so piece 2 adds the new kinds there.

**R11. Nothing of a message anywhere but in the request.** No text, title, name, link or Telegram id in a
log line, an error's text, a counter's name or a call of the R2 interface. Every log line is a constant
format string with small numbers, milliseconds and Telegram's error type at most. A privacy test in the
manner of `privacy_test.go` puts a canary text and canary ids through every path (done, waited, refused,
unknown, each local "no") and searches every log line and every returned error's text.

**R12. Fail closed, one writer.** A stored value that cannot be read (the refusal record, the waits, the
frozen callback, the mirror callback, `Sent`, `ChatRefusal`) stops the action with no request; none of
them reads as "empty". The Actor's own state is under one lock; it starts no goroutine; two calls at once
with the same click make one request (R2), with different clicks each its own.

## 6. Tests

Write the tests for a rule before its code where that is natural, and for each rule see its test fail with
the rule's line undone (say in the report which you saw fail). Count requests at the fake invoker, never
from the Actor's own counters alone. No sleeps and no real-time bounds: the package's fake clock. At least:
R1 for each of the six kinds and each of timeout, lost connection, server error, cancel; R2 (Begin fails;
a spent click; two goroutines on one click; End fails); R4 (the clock did not advance; the record holds the
wait before the call returns; the next call makes no request; the mirror's `ForwardBatch` then sleeps the
same wait, and a wait the mirror got holds the client's forward; slow mode holds one chat only); R5; R6 both
ways and with a store that cannot save; R7 (a day, another kind, another chat, "try again"); R8 (the same
second, the 31st, the window passing, off, a restart simulated by a fresh Actor on the same fake ledger);
R9; the flags test; both answer shapes of a send; "sent before"; delete's and the read mark's two methods
by chat kind; R11.

**Run while working, and only these** (the PC is shared: before each go command read free memory with
`powershell -NoProfile -Command "[int]((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1024)"`
and wait if it is under 2,500 MB; prefix go commands with `GOGC=25 GOMAXPROCS=2`):
- Go is not on PATH: in Git Bash, `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`.
- `go build ./...`; `gofmt -l internal/telegram`; `go vet ./internal/telegram/`.
- Your tests by name: `go test -count=1 -run 'TestAct' ./internal/telegram/`.
- Once at the end, because `call.go`, `counters.go` and `memo.go` gained lines: the forwarder's and the
  record's existing tests by name, `go test -count=1 -run 'Forward|Mirror|Rename|Memo|Wait|Privacy' ./internal/telegram/`.
- No whole-package run, no other package, no race detector, no Docker: those are mine, once, after the
  review's fixes.

## 7. Hand-back

- Commits with `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, each message ending
  with a blank line and `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; pushed with
  `git push private wip/core-act`; `git status --short` empty at the end.
- A report on the branch, `archiver/docs/progress/core-act-REPORT.md`: the exported API as built (types,
  methods, errors, the interface of R2 with each method's contract in one line); each rule with its test's
  name and whether you saw it fail first; every existing line you changed outside the new files and why;
  what `classify` does with slow mode and with each refusal you met in the library's error list; the Saved
  Messages finding; where the collector lists the kinds; anything in this brief you found wrong or
  impossible, said plainly (a brief's wrong sentence has cost this project a day before: check a door in the
  code before you rely on my word for it); what you did not do.
- Your final message to me: the head's full hash, the test commands with their results and seconds, the
  list of files, and the open points. It is all I see before I read the code.
- Invented data only in tests. Any text that holds a Windows path is written with a file tool, never
  inside an inline script string.
