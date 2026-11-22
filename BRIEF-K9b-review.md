# Independent review of K9b, the click's turn in the running program (Core, K-3, 2026-11-16 00:30)

For one reviewer who has not seen the work. Read-only on the tree: you change no file of the copy and
commit nothing. Your one product is the file `C:\Users\trabi\Claude\Projects\Telegram\REVIEW-K9b-turn.md`.

## What is reviewed

Branch `wip/core-turn`, copy `C:\Users\trabi\Claude\Projects\Telegram\wt-core-turn` (Go module in its
`archiver` folder), at the head the message that started you names, against the ledger's head it sits
on (`git merge-base HEAD private/wip/core-ledger`, or 51fc8160): only the collector's side and what it
needed: `internal/collector/click.go`, `click_api.go`, `click_test.go`, the changed lines of
`reader.go`, `account.go`, `collector.go`, `command.go`, `mirror_auto.go`, `words.go`; the collector's
fake Telegram (`internal/collector/faketg/act.go`, `server.go`, `mirror.go`, `world.go` and its tests);
in `internal/telegram/act.go` only the "self" peer and the cap's setter; in `internal/catalog` only a
new read door for a message's own marks and two reason words. The request layer (`internal/telegram`
otherwise) and the ledger (`internal/catalog/schema_act.go`, `internal/tgstore/act.go`) were each reviewed
twice: not yours, but read them, because this piece is their caller.

**This is the code that takes the owner's click and makes the one request to Telegram on a real
account** (send, reply, forward, edit, delete, react, mark as read). It runs inside the collector's
reader goroutine, beside the reader's own calls and the automatic mirror. A defect here can send a click
twice, send it after a restart or hours late, send it while Telegram's stated wait runs, cancel a click's
request half way and call it "not sent", starve the reader or the mirror, ask Telegram sooner than a
pause the reader was keeping, or let someone else's message be edited or deleted. That is what you are
looking for. Style is not.

## Read first

1. `C:\Users\trabi\Claude\Projects\Telegram\DESIGN-CORE-client-actions.md` (what the owner agreed to).
2. `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-K9b-click-turn.md` (what the coder was given; it may
   itself be wrong: say so where it is). The earlier pieces' briefs are beside it (`BRIEF-K8-*`,
   `BRIEF-K9a-*`).
3. In the copy: `archiver/docs/TRIED-BEFORE.md` sections 24 and 25, `archiver/docs/TELEGRAM-FACTS.md`
   section 11; `internal/collector/reader.go` (all of `readerTask`, `readTurn`, `onReader`),
   `mirror_auto.go` (all), `account.go` (`loop`, `runSession`), `internal/telegram/call.go` (`held`,
   `takeWait`, `call`, `once`, `report`), `internal/telegram/act.go` (`Do`), `internal/telegram/reader.go`
   (how a read sleeps and what `State()` says), `internal/catalog/schema_act.go` (the doors).
4. The code under review in full; the coder's report `archiver/docs/progress/core-turn-REPORT.md` last,
   and with suspicion.

## What to try to break (questions, not conclusions)

- **One click, one request.** `oneClick` can call `Actor.Do` a second time for the same click (after
  the server's limits were asked). Is there any answer of the first `Do` after which a second `Do` could
  send a second request, or any other path on which one ledger row leads to two requests at the fake
  (count them at the fake, not from the collector's counters)? Two sessions of one account at once (a
  reconnect while the old session's reader has not ended)? Two collectors on one catalogue?
- **A click's own request must never be cut and then called "not sent".** What can cancel the pass a
  click's `Do` runs in: the watchdog (`Stalled` while the reader is idle but the click's request is slow:
  give the fake a slow answer), the sleeping-reader cut (`readerClock`, `cancelPassForClick`: can it fire
  while a click's request is out: a click queued while another click is being sent), the session's end,
  the owner's Stop? For each: is the row's end state true ("not known" when a request left)?
- **The sleeping-reader cut** (`readerClock.Sleep`): it cuts a sleep of the reader while a click is
  queued and the reader's state is a history read. (a) Can it ever lead to a request of the READER
  leaving before a wait Telegram stated has ended (after the cut, on the reader's next call: is the wait
  on record and slept again, in full, from the record)? (b) It also cuts the pause before a RETRY (the
  reader's own back-off after a timeout or a lost connection): after the cut, how soon does the reader
  send that request again, compared with no click? Can a queue of clicks (or `more` staying set) make
  the reader retry in a tight loop, or spin without sleeping? Count the reader's requests at the fake
  with and without clicks, with the fake answering timeouts. (c) The lock and the two flags (`wake`,
  `more`, `sleeping`, `woken`): a lost wake-up, a wake-up for a sleep that is not the reader's, a sleep
  registered after the pass was cancelled. (d) What other sleeps of the reader are NOT cut, and how long
  can a click then wait (the report lists them: check the list is complete).
- **Starvation, both ways:** with clicks arriving steadily at the cap, does the reader still read and
  the automatic mirror still forward (the mirror's turn is skipped when a click was queued in that turn)?
  With the mirror forwarding batches back to back, how long does a click wait? Is there ever more than
  one writing request of the account out at once (click and mirror)?
- **Restart, stop, session end:** kill at every point of `oneClick` (before `Begin`, between `Begin` and
  the request, with the request out, after the answer before `End`); a session that ends (sign-out, VPN
  lost, the owner's Stop) with clicks queued or one out; the start's sweep failing, running twice, or
  running while an old session still sends; `ClickOutcomeLost`. After each: every row's state, and the
  count of requests at the fake.
- **The entry points** (`click_api.go`): queueing for an account that is not running, signed out,
  frozen, removed; the own-message rule by chat kind (a private chat, a basic group, a supergroup, a
  broadcast channel, a forum; a message not held; a deleted message; an album; someone else's message
  with the same number in another chat; a migrated group); a forward's source and destination the same,
  a mirror as destination, a protected source; random ids (made where, never 0, never reused across
  clicks, the same on "send again"); cancel, verdict and "send again" racing the turn; reads returning
  a text to a caller that should not get one.
- **Settings:** each value's bounds; unreadable or out-of-range stored values (do clicks stop, with a
  fixed word, and does nothing read as the default?); a change while a click is being sent; "mark as
  read" off with a read-mark click queued.
- **The shared Forwarder and the secret:** is `autoTurn` otherwise unchanged (compare its statements
  one by one with the base); what the Forwarder is built with when the automatic mirror is off; the
  secret on a catalogue where no mirror was ever made (a file created by a first click: where, with what
  rights, and is the same one then used by a later mirror command?); a secret that cannot be read.
- **The fake Telegram** (`faketg`): does each new answer do what Telegram's does as far as the code
  under test can tell (the two shapes of a send's answer, ids, the update pushed afterwards, a repeat of
  a random id, slow mode, a lost answer after the message exists)? A fake kinder than Telegram hides
  defects: where is it kinder? Every new answer encodable through a dialled connection?
- **Privacy and counts:** any text, name, link or Telegram id in a log line, an error's text, a count's
  name, the status file; the hourly counts' names fixed words.
- **What existing behaviour changed:** `readerTask`'s loop and `readTurn` for an account with no click
  ever queued: is every path bit for bit as before (one extra catalogue read per loop round: its cost)?
  The collector's existing tests the coder did not run.

## How to work

- **Prove what you can without editing the tree:** probe tests in a scratch folder
  `C:\Users\trabi\Claude\Projects\Telegram\wt-core-turn-review-scratch`, loaded with `go test -overlay`,
  each finding marked CONFIRMED (a probe shows it; keep the probe and its output) or PLAUSIBLE (by
  reading; say what would show it). No finding without the file and line (relative to `archiver/`).
- Go is not on PATH: in Git Bash, `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`,
  then `cd /c/Users/trabi/Claude/Projects/Telegram/wt-core-turn/archiver`; prefix go commands with
  `GOGC=25 GOMAXPROCS=2`. Before each go command read free memory
  (`powershell -NoProfile -Command "[int]((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1024)"`)
  and wait if it is under 2,500 MB. Named tests only (`-run`); the collector's package compiles slowly:
  batch your probes into few runs. No whole run of `internal/collector`, no race detector, no Docker.
  Nothing contacts Telegram or the network: the collector's fake only. Never start the collector or any
  program of the project. Anything over 2 minutes in the background.
- Invented data only. Any file with a Windows path in it is written with a file tool, never from inside
  an inline script string. No path of this PC inside the report's findings.

## The report (`REVIEW-K9b-turn.md`)

First line: MAY BE LISTED, MAY BE LISTED AFTER THE MUST-FIXES, or NOT AS IT IS. Then the findings, the
most serious first, each with: a number, MUST FIX / SHOULD FIX / MINOR, CONFIRMED or PLAUSIBLE, file and
line, what happens to the owner in one sentence, the probe's name and output where there is one, and the
smallest fix you would accept. Then: what you checked and found sound (so that it is not checked again),
what you could not check, and each place where the brief or the design is wrong or silent. Your final
message to me: the first line, the count by class, and the three findings that matter most.
