# Brief K11: a mirror's read that has ended is not read on (Core, K-3, 2026-11-16 00:39)

For one Opus coder. Small: a few lines in the collector's reader and their tests. Agreed with the mirror
track on the board (messages 79 b, 81, 84 e).

- Copy: `C:\Users\trabi\Claude\Projects\Telegram\wt-core-readended`, branch `wip/core-readended`, cut from
  the main head dbc2f7d5. Go module in its `archiver` folder. Pushed to `private` as you go; never the
  branch `claude/charming-feynman-vm2xia`.

## 1. What is wrong today (read in the code; no run shows it)

The automatic mirror reads a chat's history so that it can forward it: its task writes a read approval
for the chat (`collector.read.<account>.<chat>`, a `ReadApproval` with `By` set to the mirror's word).
When a mirror's want ends for good (the chat is protected, marked "never", the source left, the owner's
stop), that approval stays, and the reader goes on reading the chat's history for a mirror that will
never be made: requests for an item that will never be acted on (`TRIED-BEFORE.md` section 24, rule 9).
Removing the approval would not stop a read that is under way: in `internal/collector/reader.go`
`readTurn` reads a chat when it is approved OR has a stored cursor
(`if ch.done || (!ch.approved && !ch.cursor) { continue }`), and `internal/telegram/reader.go` (about
line 590) asks for the approval only where no cursor is stored. Once the record is gone the reader could
not tell a mirror's cursor from the owner's own.

**What the old app knows:** nothing of this (it has no mirror and no approval record; its reads were
the owner's own choice per chat). The rule it learnt the hard way is the one above: no request for an
item that will never be acted on.

## 2. What to build

- `ReadApproval` (in `internal/collector/reader.go`) gains one field: `MirrorEndedAt int64`
  (`json:"mirror_ended_at,omitempty"`): the time the mirror's task ended the want this approval was
  written for. The mirror track writes it later, in a piece of its own, in the transaction that ends a
  want, only on a record that is the mirror's own (`By` not empty); you build the reader's side and
  write the field only in tests.
- **The reader skips a chat whose approval carries the field, cursor or not:** no history page, no gap
  read of that chat, no estimate made for it by the reader itself. The cursor stays as it is; nothing is
  deleted; a read in the middle of a call stops at the end of the call it is in (a call is at most
  `PagesPerTurn` pages; the approvals are read afresh at every turn: `readChats`).
- **Only a mirror's record can be ended:** a record with `By` empty (the owner's own yes) is never
  skipped for this field, whatever it holds (if the field were ever set on one, it is ignored and
  counted once in a log line with a constant format).
- **The owner's later yes resumes the read:** the owner's approval writes a new record (read the two
  writers at about lines 126 and 161: the estimate keeps a mirror's approval "until the owner's yes";
  the yes sets `By` to empty). Make sure that both writers drop `MirrorEndedAt` when the record becomes
  the owner's, and keep it when a mirror's record is merely rewritten with an estimate. The read then
  goes on from the stored cursor.
- **The settle's own read of a mirror chat** (`mirror_auto.go`, `readMirror`) reads the MIRROR chat, not
  the source: check that this change cannot stop it (its approval is the mirror chat's own record).
- **A record that cannot be parsed** stays what it is today (read how `approval` and `readChats` treat
  it and do not change that); say in the report what it is.
- The live monitor is not changed: new messages of that chat still arrive as updates. Only the reader's
  history requests stop.
- Counted: the times a chat was skipped as ended, per hour, the way the collector's other counts are
  written (one name); one constant log line when a chat is first seen ended in a run (the account's
  number and the catalogue's own chat number are what the reader's lines carry today: follow them; no
  title).

## 3. Tests (on the collector's fake Telegram, the rig's clock, no sleeps)

Named `TestReadEnded...` in `internal/collector`: a mirror-approved chat of 5 pages, the field written
after page 2: the fake gets no third page request (count history requests for that chat at the fake),
the cursor is unchanged, other approved chats go on being read; a gap of that chat is not read; the
owner's yes afterwards: pages 3 to 5 are read from the cursor and the record no longer has the field; a
record with `By` empty and the field set is read as before; the mirror chat's own settle read still
works with the source ended. See the first test fail before your change.

**Run while working, and only these** (the PC is shared: before each go command read free memory with
`powershell -NoProfile -Command "[int]((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1024)"`
and wait if it is under 2,500 MB; `GOGC=25 GOMAXPROCS=2`; Go through
`source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`): `go build ./...`;
`gofmt -l internal/collector`; `go vet ./internal/collector/`; your tests by name; the reader's and
the mirror's existing tests by name once at the end
(`-run 'Reader|OnReader|Estimate|Approv|MirrorAuto|Chosen|Gap' ./internal/collector/`). No whole run of
the collector, no race detector, no Docker. Nothing contacts Telegram.

## 4. Limits and hand-back

- Files: `internal/collector/reader.go` and, only if a writer of the record lives there, `chosen.go` or
  the approval's own file; new test files; a report `archiver/docs/progress/core-readended-REPORT.md`
  (no path of this PC in it). Not `mirror_auto.go`, not `internal/mirror`, not `internal/telegram`, not
  the catalogue. No schema step (the record is a settings row), no goroutine, no new request of any
  kind: this piece only ever sends fewer.
- Commits with `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, each message ending
  with a blank line and `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; pushed with
  `git push private wip/core-readended`; `git status --short` empty at the end.
- Your final message: the head's full hash, each test with "seen failing first: yes or no", the commands
  with results and seconds, every line of existing code you changed and why its behaviour is unchanged
  for a chat without the field, and anything in this brief you found wrong (check the door in the code
  before relying on my word for it).
