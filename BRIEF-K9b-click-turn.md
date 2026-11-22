# Brief K9b: the client's acting side, piece 2, second half: the click's turn in the running program (Core, K-3, 2026-11-15 23:50)

For one Opus coder. The design the owner agreed to: `DESIGN-CORE-client-actions.md` (section 3, steps 2 to
5; section 4). What exists: the request layer (`BRIEF-K8-client-requests.md`, `BRIEF-K8b-fixes.md`;
`internal/telegram/act.go`, reviewed twice) and the ledger of clicks (`BRIEF-K9a-click-ledger.md`;
`internal/catalog/schema_act.go`, `internal/tgstore/act.go`; with its reviewer as you start). This piece
joins them inside the collector: a queued click is taken up in the account's own loop, sent through the
`Actor`, and its outcome written. **It is the first code that would really send the owner's clicks, so
it is download-path-grade work: every test on the collector's fake Telegram; nothing runs against
Telegram; an independent review with probes follows your hand-back.** No route, no page, no HTTP: the
door and the compose box are pieces 3 and 4.

- Copy: `C:\Users\trabi\Claude\Projects\Telegram\wt-core-turn`, branch `wip/core-turn`, cut from
  `wip/core-ledger` at 726844a7. Go module in its `archiver` folder.
- Pushed to `private` as `wip/core-turn` as you go. Never the branch `claude/charming-feynman-vm2xia`.

## 1. What the old app already knows

Nothing of this: the old app sends no text, edit, delete, reaction or read mark, and its auto-forward
has no turn or record (a new random id at every try). The model on record is the new app's own
automatic mirror, which ran for real on 11-15 and which this piece sits beside: one writing request a
turn in the reader's goroutine, never beside another call (`internal/collector/mirror_auto.go`,
`autoTurn`), an owner's call taken between the reader's turns (`reader.go`, `onReader` and the top of
`readerTask`'s loop), every wait kept, a settle from what the chat shows. Numbers on record for writes
are in `TELEGRAM-FACTS.md` section 11. One number of the collector's own matters here: a call handed to
the reader from a page waited 62 s of the test clock behind the reader's current call and its retries
(board message 58 b); a click must not.

## 2. Read first, yourself, in full

The design note; the three briefs named above; `archiver/docs/TRIED-BEFORE.md` sections 24 and 25;
`internal/telegram/act.go` and the fix round's section 9 of `docs/progress/core-act-REPORT.md`;
`internal/catalog/schema_act.go` and `docs/progress/core-ledger-REPORT.md`; `internal/tgstore/act.go`;
in `internal/collector`: `reader.go` (all of `readerTask`, `onReader`, `readTurn`, `methodFrozen`),
`mirror_auto.go` (all), `account.go` (`loop`, `runSession`, where `cat.Frozen` is asked),
`collector.go` (`Run`, `Config`), `pausedl*.go` and `pages.go` as examples of an owner's setting read
by the running program, `status_file.go` and where hourly counts are written; `internal/mirror/pause.go`
and `auto.go` (the pause since the account's last write); the collector's fake: `faketg/server.go`
(the two request switches), `faketg/mirror.go` (its forward and create answers, `Trouble`).

## 3. What to build

### 3.1 One Forwarder and one Actor per signed-in session

Today `autoTurn` makes the session's `Forwarder` itself, lazily, only when the automatic mirror is on
(`mirror_auto.go` about line 398). The Actor must be made from THAT Forwarder (one memory of the
account's refusal, of protected sources and of waits; the request layer's door is keyed by it). So: one
helper on the session that makes the Forwarder once, with exactly today's configuration, used by
`autoTurn` and by the click's turn; `autoTurn`'s behaviour otherwise unchanged, bit for bit (its tests
pass unchanged). Read where `AutoMirrorSecret` comes from: the Forwarder needs the same 32 bytes for the
account always. If the secret exists only when the automatic mirror is switched on, load it the same
way for the Actor (never a different or a fresh one when one is on record); say in the report what
happens on a catalogue where no mirror was ever made.

The Actor's callbacks: `Frozen` from the catalogue's own answer (`cat.Frozen`, as `account.go` asks
it); `IsMirror` from the mirror's ledger in the catalogue (find the door that says a chat is one of the
app's mirrors; the chat row has `mirror_of`); the ledger `tgstore.NewActLedger`. `Limits` is asked once
per session before the first click that needs it (one `help.getConfig`, counted), not at the start.

**Saved Messages:** give the Actor the account's own Telegram user id (a new `ActConfig` field) and
address a user chat with that id as the library's "self" peer, so that a click there does not depend on
an access hash for the account's own user. This is the one change you make in `internal/telegram/act.go`
(with its test: the request the fake received carries the self peer).

### 3.2 The turn

In `readerTask`'s loop, where the owner's calls are drained "between turns" and before `readTurn` (so
before the reader's next page and before `autoTurn`): the clicks' step.
1. The age sweep for the account (`SweepOldClicks`, bound 2 minutes: a click that could not go out in
   time becomes "not sent", it never goes out late).
2. While there is a next queued click (`NextClick`): build the `telegram.Action` from the row, call
   `Actor.Do` through the reader task's `pass` (the watchdog's), and handle the result:
   - an error before `Begin` (the request layer's local "no": frozen, a mirror, the cap, a wait running,
     the chat's remembered refusal, a bad action, a text over the limit, no access hash, no limits, the
     account refused, a store that cannot be read): `ClickNotSent` with the fixed reason word that fits
     (map every sentinel; an unknown error maps to one word of its own, never to "sent") and the wait's or
     the cap's end where there is one. `ErrClickSpent`: nothing (another turn has it), counted.
   - after `Begin` the Actor has written the outcome itself (`End`): nothing more to write.
   - signed out: the session ends as the reader's `final` does it.
   The step takes at most a bounded number of clicks per loop round (the cap already bounds requests;
   give the loop its own bound of 5 a round so that a queue can never starve the reader), one at a time.
3. **A click must not wait behind a sleeping reader.** When a click is queued while the reader's current
   call is sleeping a wait Telegram stated or a pause before a retry, that call is cancelled through the
   pass's cancel (as the watchdog does), so that the loop comes round to the clicks' step at once; the
   wait itself is on record and is slept again by the reader afterwards (nothing is asked early). A call
   that is out waiting for an answer is NOT cancelled (it would only waste a request). Find how the
   reader says it is sleeping (the caller's `waiting` and `pausing` hooks in `call.go`); if the Reader
   has no door for it, add a small one in `internal/telegram/reader.go` and say so. Test: on the fake,
   with the reader inside a stated wait of 60 s, a queued click is begun within 2 s of the clock, and the
   reader's next request of that kind still leaves no sooner than the wait's end.
4. **The automatic mirror gives way to the person:** a click whose request went out counts as "the
   account's last write" for the automatic mirror's pause. Read `internal/mirror/pause.go`: if it has a
   door for recording a write of the account, call it; if the pause is derived from the mirror's own
   rows only, do NOT edit the mirror's package: write down exactly what is missing in the report (I ask
   the mirror track for the door) and leave a clearly marked gap.

Entry points on the Collector for piece 3 (plain Go functions, no HTTP; each returns fixed-word errors):
- **Queue a click** for an account: the catalogue-only checks, then `QueueClick`, then a nudge of the
  reader (as `onReader` does). The checks, all without a request: the account is signed in and its
  session runs (else nothing is queued: a click must never sit waiting for a sign-in); the kind's
  shape; **an edit or a delete only of the account's own message, judged from the catalogue**: in a
  private chat or basic group by the message's own "outgoing" mark, in a supergroup by the sender being
  the account's own user, and **in a broadcast channel: refused in this step** in fixed words (the
  catalogue cannot tell whose post it is, and an admin's delete would remove anyone's); a message the
  catalogue does not hold: refused. A random id is made here (the request layer's helper) for a send
  and for each message of a forward.
- **Cancel** a queued click (to "not sent", the owner's cancel); **send again** (`SendClickAgain`, then
  a nudge); **the owner's verdict** on a "not known" row; **a chat's clicks** and **one click** to read.

### 3.3 The start, the settings, the counts

- **At a program start, before any account's loop runs:** `SweepClicksAtStart`, once, its three counts
  in one constant log line. A failure of it stops every click for the run (fail closed: the turn's step
  does nothing and says so once), never the collector.
- **Settings, read by the running program at each click's turn** (so a page's change holds at the next
  click), each with a read, a check and a set door for the pages in the collector's own style (look at
  how `pausedl` or the mirror's `ReadGather`/`CheckGather`/`SetGather` do it): the cap's three numbers
  and "off" (defaults 1 a second, 30 in 5 minutes; bounds: per second 1 to 5, per window 1 to 300, the
  window 1 to 60 minutes); "mark as read" (off by default; the turn refuses a read-mark click with a
  fixed word when it is off, whatever queued it). A stored value that cannot be read: clicks stop with a
  fixed word until it is written anew; it never reads as the default.
- **Counted per hour** the way the collector's other counts are: clicks queued, begun, each end state,
  each "not sent" reason, the start's sweep's numbers, the times a sleeping reader was woken for a
  click, and the delay from a click's queueing to its `Begin` (count, shortest, median, longest, in
  ms). The request layer's six kinds reach the hourly table by themselves; check it in a test.
- **Log lines:** constant format strings; the kind's word, an outcome's word, milliseconds, counts.
  Never a text, a name, a link, a chat's or message's number. A privacy test over the whole turn with a
  canary text and canary ids (the collector has such tests: follow them).

### 3.4 The collector's fake Telegram

`internal/collector/faketg`: answers for `messages.sendMessage` (the two answer shapes: a short "sent"
answer for a user chat or basic group, updates with the id for the random id elsewhere; the new message
then reaches the account through the fake's update push, as a real one does), `messages.forwardMessages`
to any chat the account can write to (today's answer serves a mirror: extend, do not fork),
`messages.editMessage`, `messages.deleteMessages` and `channels.deleteMessages`,
`messages.sendReaction`, `messages.readHistory` and `channels.readHistory`. The fake remembers every
random id it carried out and answers a repeat with `RANDOM_ID_DUPLICATE`. `Trouble` gains what the tests
need: a stated wait, a slow mode, `PEER_FLOOD`, a chat's refusal, no answer (carried out, the answer
lost: the message exists in the fake afterwards), a server error with a forward carried out in part.
Every answer the fake builds must be encodable (a required field left nil made every topics answer fail
until tonight: add one test per new answer that asks through a dialled connection, as
`faketg/topics_answer_test.go` does).

## 4. Rules that bind every line

One click, one request, never repeated by the program: not after a wait, a timeout, a restart, a
cancelled pass (a pass cancelled by the watchdog or by rule 3.2.3 while a click's request is out leaves
that click "not known": check that the cancel for a sleeping READER can never cancel a click's own
request). Nothing that was queued or sending before a stop is sent after it. Every wait Telegram states
is kept in full by everything. A refusal of the account stops the clicks and the mirror alike. Fail
closed on anything stored that cannot be read. Off for a frozen account. No request for an item that
will never be acted on. One writer per stored set: the ledger's rows only through its doors.

## 5. Tests and runs

End-to-end tests in `internal/collector` on the fake, named `TestClick...`, with the rig's clock (no
sleeps, no real-time bounds; hold the fake's answers where a test needs an order, as
`parthold_test.go` does): each kind done; each outcome (waited and then held without a request; slow
mode one chat; refused and remembered; the account refused, and the automatic mirror then stopped too;
not known after a lost answer, with the message present in the fake and exactly one request counted at
the fake; sent before on "send again"); a kill between `Begin` and the answer and a restart (the row is
"not known", nothing is sent, the count of requests at the fake stays 1); queued clicks at a stop are
"not sent" after the start; the age sweep; the cap across a restart; the sleeping reader woken; the
reader and the automatic mirror going on between clicks (neither starved: 20 clicks queued, the reader
still reads); own-message checks for edit and delete by chat kind; a click queued for an account that
is not running; settings changed while running, and unreadable; the privacy test; the hourly counts.

**Run while working, and only these** (the PC is shared: before each go command read free memory with
`powershell -NoProfile -Command "[int]((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1024)"`
and wait if it is under 2,500 MB; `GOGC=25 GOMAXPROCS=2`; Go through
`source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`): `go build ./...`; `gofmt -l`
and `go vet` on the packages you changed; your tests by name; the existing tests by name of what you
touched: `-run 'MirrorAuto|Reader|OnReader|Estimate|E2EPages|Status|NotCounted'` in the collector,
`-run 'TestAct'` in `internal/telegram`, the whole small `faketg` package. **No whole run of
`internal/collector` (10 minutes), no race detector, no Docker: those are mine, once, after the
review's fixes.**

## 6. Hand-back

- Commits with `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, each message ending
  with a blank line and `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; pushed with
  `git push private wip/core-turn`; `git status --short` empty at the end. Commit and push work in
  progress after each part of section 3 (the session can stop at any moment).
- A report on the branch, `archiver/docs/progress/core-turn-REPORT.md` (no path of this PC in it): what
  was built against each part of section 3; every existing function you changed and why its old
  behaviour is unchanged (`autoTurn`, `readerTask`); the secret's finding; the mirror's pause door or
  the gap; each rule of section 4 with its test's name; which collector tests gain or lose time; what
  you did not do; anything in this brief you found wrong, said plainly: check a door in the code before
  you rely on my word for it.
- Your final message: the head's full hash, the test commands with results and seconds, the files, the
  open points.
