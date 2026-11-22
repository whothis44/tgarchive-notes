# Brief K4: a chat's "protected" flag, read from the chat list and stored (Core, 2026-11-15)

For one Opus coder. Listed on the board ("Listed and unbuilt"): "A chat's 'protected' flag recorded from the
chat list, so no mirror is made for a chat that cannot be forwarded" (FEATURES 12 round 1: "chats that block
forwarding reported, not retried"). You work in the copy `C:\Users\trabi\Claude\Projects\Telegram\wt-core-protected`,
branch `wip/core-protected` (cut from the main head d1af260), Go module in `archiver/`.

## What is already known

- Telegram marks a group or a channel whose owner switched forwarding off with the flag `noforwards` on the
  chat's own object; the chat list's answer carries those objects, so the flag costs **no request**
  (`TELEGRAM-FACTS.md`: only "does not allow forwarding" is documented). The old app never recorded it (it
  made no mirrors). The new app reads the chat list once at a start and once a day (2 requests on 11-13)
  and drops the flag today: `internal/telegram/dialogs.go` builds a `ChatEntry` from `tg.Channel` and
  `tg.Chat` and takes `Megagroup`, `Forum`, `Left`, `Restricted`, not `Noforwards`.
- Why it matters now: the automatic mirror (waiting to merge) makes a mirror for a chat joined while away.
  For a protected chat that would cost a created channel (one of the account's 500) and a refused forward
  before anything is known. With the flag stored, the mirror's plan can say so before any request. Lesson
  behind it (`TRIED-BEFORE.md` 24, rule 9): no request for an item that will never be acted on.
- This piece stores the fact and gives the catalogue two small questions to answer. **It changes no
  behaviour of the mirror, the reader or the pages**: those tracks use the answers later.

## What to build

1. `internal/telegram/dialogs.go`: `ChatEntry` gains `Protected bool` and `ProtectedKnown bool`. Known and
   set from `Noforwards` for a `*tg.Channel` that is not `Min` and for a `*tg.Chat`; not known for a
   forbidden object, a `Min` object, a user (a private chat has no such flag). Nothing else in that file
   changes. If the live monitor's `ChatFacts` (`internal/telegram/monitor.go`) carries a full chat object
   on a chat's update, take the flag there the same way; if it does not carry the object, leave it and
   say so.
2. `internal/tgstore/store.go`: the two places that make `catalog.ChatFacts` pass the two values on.
3. `internal/catalog`: `ChatFacts` gains `Protected bool`, `ProtectedKnown bool`; `SaveChatFacts`
   (`tgchats.go`) writes the column only when known, never back to "unknown", idempotent as the rest; a
   change of a known value goes to the change log the way a change of access does (find how kind 5 is
   written and follow it, with a fixed word).
4. **A schema step, in a NEW file `internal/catalog/schema_protected.go`,** written exactly as
   `schema_released.go` is (two constants, a step that refuses any other version, the column added only when
   missing): `ALTER TABLE chat ADD COLUMN protected INT` (NULL: not known; 0: forwarding allowed; 1:
   protected). **Its number: the board gives this piece 19, to follow the mirror track's 18, which is not
   merged yet. On this head the step applies after 17, so carry it as the step after the head:
   `protectedAfter = releasedSchema` and `protectedSchema = protectedAfter + 1`, the number written in
   those two constants only; the integrator sets the final numbers at the merge.** In `catalog.go` change
   only what a step needs: `SchemaVersion` and one line in the steps' table (two other branches change the
   same two places for their own steps: keep your change to those two lines, so the merge is one obvious
   conflict).
5. In the same new file, two read doors (the mirror track and the pages will call them; do not add the
   column to `rows.go`'s chat row or its SELECT lists: two waiting branches rewrite those):
   - `ChatProtected(ctx, chat int64) (protected, known bool, err error)` for the catalogue's chat number;
   - `ProtectedChats(ctx, account int64) ([]int64, error)`: the catalogue's chat numbers of that
     account's chat list that are known to be protected, in order.
   Both work on a read-only handle; on a catalogue older than the step they return the catalogue's usual
   error for an older file, never a wrong "not protected".
6. Tests (named; invented chats only): the chat list's parse (a protected channel, a protected basic
   group, an ordinary one, a `Min` channel, a forbidden one); `SaveChatFacts` (known yes, known no, then
   an unknown that changes nothing, a change logged once, the same facts again change nothing); the step
   on a file at the version before it, applied twice (the second finds the column), refused on another
   version; the two doors; the bring-in and the fabricated archive still pass their own tests that write
   chat facts (run those named tests, do not edit those packages).

Edit only: `internal/telegram/dialogs.go` (and `monitor.go` only under point 1's condition),
`internal/tgstore/store.go`, `internal/catalog/tgchats.go`, the two lines in `internal/catalog/catalog.go`,
plus your new files and tests. **Do not touch** `internal/collector/**` (the fake Telegram included),
`internal/catalog/rows.go`, `state.go`, `schema13.go`, `ladder.go`, `internal/mirror`, `internal/server`:
other branches are in them. If the fake Telegram would be needed to prove something, say so in the
hand-back instead.

## How to work

- Shell: Git Bash. First `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`, then
  work in `wt-core-protected/archiver`. Named tests only, one go command at a time:
  `GOPROXY=off GOGC=25 GOMAXPROCS=2 go test -p 1 -run '<names>' ./internal/telegram/` and the same for
  `./internal/tgstore/` and `./internal/catalog/`. Never a whole package (`internal/catalog` whole takes
  about 4 minutes; the Core session runs it once after its read), never `./...`, no race detector, no
  Docker. `internal/telegram`'s test program links the Telegram library: minutes and about 3 GB of memory
  for its first build. Before every go command look at free memory (PowerShell:
  `(Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB`, in GB) and do not start one under 4 GB
  free: wait a minute and look again. Other coders build on this PC at the same time.
- Read first, in the copy: `internal/telegram/dialogs.go` whole, `internal/tgstore/store.go` around the two
  places, `internal/catalog/tgchats.go` whole, `schema_released.go`, `catalog.go` around `SchemaVersion` and
  the steps' table, and one existing test of each kind you will write.
- Privacy: invented data only; read nothing under `E:\`, no `start.bat`, no log of a real run; a chat's
  title never goes into a log line or an error.
- Never work in `repo-archiver` itself or in another copy.
- Commit as you go on `wip/core-protected` and push it to the remote `private` after each commit that
  builds: `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, the message ending with
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Never another branch, never a merge, never a tag.
- `gofmt -l` clean on the files you touched before the hand-back.

## Hand back (your last message)

The branch's head; the files changed; the named tests run with their `ok` lines; whether the live monitor
carries the chat object (point 1); the exact lines changed in `catalog.go`; anything that could not be
built as briefed and why.
