# Brief K9c: a "not known" click settled from what the chat shows (Core, K-3, 2026-11-16 02:02)

For one Opus coder. The design the owner agreed to: `DESIGN-CORE-client-actions.md` section 5. What
exists: the request layer (merged), the ledger of clicks (merged, schema step 21), the click's turn
(`wip/core-turn`, in its full runs). This piece adds the one thing the design still owes on Core's side:
when a click's outcome is "not known", the app looks in ITS OWN CATALOGUE for what the live monitor
brought, shows what it found, and marks the click "arrived" by itself only when the match is exact and
alone. **It sends nothing, ever: no request of any kind, not even a read.** ("Look in the chat", one read
request with its cost said, is a later piece and is not built here.)

- Copy: `C:\Users\trabi\Claude\Projects\Telegram\wt-core-settle`, branch `wip/core-settle`, cut from
  `wip/core-turn` at 82d67475. Go module in its `archiver` folder. Pushed to `private` as you go; never
  the branch `claude/charming-feynman-vm2xia`. `wip/core-turn` may still get a small change after its full
  runs: I merge it into your branch; you merge nothing.

## 1. What the old app and the record already know

- The old app has nothing of this (it sends no message and settles nothing).
- The model on record is the mirror's settle, which ran for real on 11-15 (`TELEGRAM-FACTS.md` section
  11; `internal/mirror`'s settle and its doors in the catalogue): after a batch of 99 forwards answered
  with a server error, one read of the mirror chat told all 99: 64 by the post each forward names, 1 by
  the same media, 34 not arrived, none [name removed], none twice. Its rules are the ones to follow here: what
  arrived is told from what the chat holds, never guessed; "cannot tell" is a state of its own that waits
  for the owner; nothing is sent again by the program. Read how it matches a forward to its source post
  (the columns a forwarded message carries in the catalogue) and reuse those doors where they fit.
- `TRIED-BEFORE.md` section 24, rule 2: a judgement is made from every trace, not from one sign.

## 2. Read first, yourself, in full

The design note (section 5); `BRIEF-K9a-click-ledger.md`, `BRIEF-K9a2-fixes.md` and
`archiver/docs/progress/core-ledger-REPORT.md` (the states, the chain of repeats, the text's life);
`BRIEF-K9b-click-turn.md` and `archiver/docs/progress/core-turn-REPORT.md` sections 8 to 11;
`internal/catalog/schema_act.go` in full; how a message of the live monitor is saved and what the
catalogue keeps of it (the `message` table's columns: the outgoing mark, the sender, the text, the reply
target, the topic, the date, the forward's origin, the deleted mark, the edit's versions:
`message_version`); the door `ActMessages`; the mirror's settle as said above.

## 3. What to build

### 3.1 The match, per kind (a pure function of catalogue rows; in `internal/catalog`)

For a click in state "not known" (and for a forward in "sent before" or "done" with `partly` set: to
fill in WHICH of its messages arrived; no state change for those):

- **Send or reply:** a candidate is a message in the click's chat that is the account's own (the same
  rule the turn uses for "one's own message": the outgoing mark in a private chat or basic group, the
  sender being the account's user in a supergroup), with exactly the click's text, the same reply target
  and topic, dated from 30 s before the click was marked "sending" to 5 minutes after it, and not already
  tied to another click. In a broadcast channel a post cannot be told as the account's own: a post with
  the same text in that window is a candidate there too, marked "cannot tell whose", and is never
  enough for the app's own verdict.
- **Forward:** per message of the click (the `c_act_msg` rows): a message in the destination that is the
  account's own by the same rule, whose forward origin names the click's source chat and that source
  message, dated in the same window, not tied to another click. Each found one is tied to its row (its
  new id recorded on the message row: check which column the schema allows for it without changing the
  schema text; if none does, stop and report: a schema step is not in this piece).
- **Edit:** the target message's current text is exactly the click's text and it has a version recorded
  after the click was marked "sending": arrived. **Delete:** every message of the click is marked
  deleted in the catalogue with a time after the mark: arrived. **React, read mark:** nothing in the
  catalogue tells: never settled by the app; the row waits for the owner.
- **Exact and alone, or not at all.** The app gives its own verdict only when: exactly one candidate
  fits (for a forward: every message of the click has exactly one), none is "cannot tell whose", and no
  OTHER click of the account for that chat with the same content (kind, text, reply target; for a
  forward the same source messages) is queued, sending or "not known" in the window. Otherwise nothing
  changes: the candidates are only shown, and the owner decides with the existing verdict door.
- The text comparison is exact (byte for byte as stored; say in the report what the catalogue does to a
  message's text when it saves it: trimming, entities, a link's preview: if the stored text can differ
  from what was sent for an ordinary message, say how and compare what can honestly be compared, never
  loosely).

### 3.2 The doors (in `internal/catalog`, plain types, no import of `internal/telegram`)

- **Settle:** for an account, look at its clicks in "not known" on a chain's tip that were marked
  "sending" in the last 24 hours (and the forwards with `partly`), and apply 3.1. A row the app settles
  goes from "not known" to "arrived" in ONE statement that names the state it leaves, with a fixed word
  saying it was found in the chat by the app (so that a page can tell it from the owner's own verdict),
  the matched message's id recorded, the text cleared as "arrived" already does. It returns counts only:
  looked at, arrived, left for the owner, candidates seen. Bounded (a cap on rows per call; the rest at
  the next call). No change-log or schema change.
- **Candidates for one click,** read-only, for the page: each candidate's message id and date, whether
  it is "cannot tell whose", whether the app would settle on it and, if not, the fixed word why not
  (more than one; another click with the same content waits; cannot tell whose; outside the window).
- **A repeat must not go out when its first try has arrived:** before the turn begins a queued click
  that is a repeat (it has `again_of`), the same match is made for the "not known" rows of its chain; if
  one of them is found arrived (exact and alone, as above), the repeat is ended "not sent" with a new
  fixed reason word in the ledger's Go list ("the earlier try is in the chat") and the matched row is
  recorded on it; the chain then has an end the page can show. (Telegram would refuse such a repeat as
  "sent before" where it still remembers the random id; this makes it certain and costs no request.)

### 3.3 The collector's side (`internal/collector`)

- The settle is called from the clicks' step of the reader's loop (no new goroutine): at each loop round
  while the account has a "not known" click younger than 10 minutes, and otherwise at most once a
  minute while any is younger than 24 hours; and once right after the start's sweep. A failure of it is
  one constant log line (said once) and a count: it never stops the clicks or the reader.
- The check for a repeat (3.2, last point) sits in `oneClick` before the request layer is called.
- Entry points beside the existing ones in `click_api.go`: the candidates of a click (read). The owner's
  verdict door exists.
- Counted per hour like the other click counts: settles run, rows arrived by the app, rows left for the
  owner, repeats ended because the first try arrived. Log lines: constant formats, counts and the kind's
  word only: never a text, a name, a chat's or message's number.

## 4. Rules that bind every line

Nothing is sent. Nothing is settled on a guess: two candidates, a doubt about whose message it is, or
another waiting click with the same content, and the row stays for the owner. An end state is never
overwritten; only "not known" on a chain's tip moves. Fail closed: a row or a message that cannot be read
leaves the click as it is. No text in any log, error or count. The schema text of `schema_act.go` is
frozen (merged as step 21): Go code only.

## 5. Tests and runs

In `internal/catalog` (`TestClickSettle...`), on rows written through the real doors and messages saved
the way the monitor's store saves them (find that store's own test helpers; never hand-made message
rows where a writer exists): each kind arrived; the window's two edges; two candidates; a candidate tied
to another click; another click with the same text waiting; a broadcast channel; a supergroup with
someone else's identical text; a reply target that differs; a forward found in full, in part (the row
stays "not known", its found messages tied), and with an album; an edit; a delete; a react (never); a
row that has a repeat (not settled: only the tip); the statement racing the owner's verdict (one wins,
both true). In `internal/collector` (`TestClickSettle...` on the fake): a send whose answer is lost and
whose message the fake then pushes: the row is "arrived" by the app within one loop round, exactly one
request at the fake; "send again" queued before the push arrives and the push arriving before the turn
takes it: the repeat ends "not sent: the earlier try is in the chat", still one request; the settle
failing does not stop a later click.

**Run while working, and only these** (the PC is shared and busy: before each go command read free
memory with
`powershell -NoProfile -Command "[int]((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1024)"`
and wait if it is under 2,500 MB; `GOGC=25 GOMAXPROCS=2`; Go through
`source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`): `go build ./...`; `gofmt -l`
and `go vet` on `internal/catalog` and `internal/collector`; your tests by name; `-run 'TestAct'
./internal/catalog/`; `-run 'TestClick' ./internal/collector/`; the viewer's
`-run TestWallDependencies ./internal/viewer/`. No whole-package run, no race detector, no Docker.

## 6. Hand-back

- Commits with `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, each message ending
  with a blank line and `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; pushed with
  `git push private wip/core-settle`; `git status --short` empty at the end; work in progress pushed as
  you go, with the report file kept current from the first commit.
- A report on the branch, `archiver/docs/progress/core-settle-REPORT.md` (no path of this PC in it): the
  match per kind as built, with the exact conditions; where the matched message's id is recorded; what
  the catalogue stores of a message's text against what was sent; each rule of section 4 with its test;
  what you did not do; anything in this brief you found wrong, said plainly (check a door in the code
  before relying on my word for it).
- Your final message: the head's full hash, the test commands with results and seconds, the files, the
  open points.
