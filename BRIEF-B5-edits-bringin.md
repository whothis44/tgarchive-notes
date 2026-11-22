# Brief B5-E: the old archive's earlier versions of edited messages are brought in (viewer session B5, 11-15)

You are an Opus coder for the viewer and bring-in track of the new archiver. Work only in the copy
`C:\Users\trabi\Claude\Projects\Telegram\wt-b-faces` (Go module in `archiver/`), on the branch `wip/b-edits`
(already cut from the main head; clean).
Go: `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh` in Git Bash (Go is not on PATH).

## Why
The new viewer's chat page shows "edited" on a message and, on a click, what it said before, from the
catalogue's `message_version` rows. The old archive, as the bring-in carries it, has none: the page says "No
earlier version of this message is kept". The old app did keep them, and the bring-in's own plan says so:
`internal/bringin/plan.go`: `"ix_message_edits": "no place: older texts without raw bytes (WANTED:
message_version import)"`. This piece gives them their place.

## What is already known (read it; do not rediscover)
- **The old app's side** (`C:\Users\trabi\Claude\Projects\Telegram\wt-v12.32\core-service\internal\app`, read
  only): `ix_schema.go` (`ix_message_edits(group_id, message_id, edit_date, text, recorded_at)`, no key, an
  index on group and message) and `ix_record.go` `ixWriteTx`: when a message is seen again with another
  text, the text it had and the edit date it had (0: as first sent) are written with the time it was
  replaced. So one row is one earlier version; a message can have several; the newest text is in
  `ix_messages`. Check the units of `recorded_at` and `edit_date` where they are written (seconds or
  milliseconds: other old tables use milliseconds), not only where they are read.
- **The new catalogue's side** (`internal/catalog/schema7.go`): `message_version(id, message_id, edit_date,
  text, media, layer, raw, auto_delete, replaced_at)`, read by message through its index; it has no unique
  key. `internal/catalog/tgrows.go` is where the live reader writes a version when an edit replaces one:
  read it for what each column means there (what `edit_date` and `replaced_at` hold, what `media` is when
  the files did not change), and write the old rows the same way, so that the viewer cannot tell them
  apart. `raw` stays NULL and `layer` 0: the old app kept no raw bytes of an earlier version.
- **The bring-in** (`internal/bringin`: `plan.go`, `layout.go`, `facts.go`, `run.go`, `run2.go`,
  `verify.go`; the command `cmd/tgarchive-bringin`): it reads the old database read-only, says a plan in
  numbers, carries each old table to its place through doors of the catalogue (`internal/catalog/
  imported.go`: `SavePeerNames` is the model for a small side table), and verifies with a count per line.
  Messages whose raw record does not decode are not carried: their earlier versions then have no message
  and are counted as not carried, never an error. A bring-in can be run again on the same catalogue: the
  same again must write nothing twice.
- **What the viewer reads:** `GET /api/post/{id}/versions` (on the branch `wip/b-viewer5`, not on yours:
  you do not need it; the catalogue's rows are the contract).

## What to build
1. **One door in `internal/catalog/imported.go`** (the bring-in's doors live there; add this one function
   and its test, touch nothing else in that package, no schema step): it stores a message's earlier
   versions as the old app kept them, in one transaction with the batch, and writes nothing for a version
   already there (the same message, edit date, text and replaced time). It returns how many it wrote.
2. **The bring-in carries `ix_message_edits`:** the plan's line for it says where it goes; the facts count
   the old rows; the run carries them after the messages are in (a version needs its message's id:
   resolve by the chat and the message number as the other side tables do, in bounded batches, never one
   query per row over the whole table if a join or a keyed read by batch does it); the verify has its line
   (old, expected, have) and its counts of what was not carried and why (no such message in the
   catalogue; an empty text equal to nothing). Memory stays bounded whatever the table's size.
3. **Order and marks:** a version brought in does not change the message's own row (its text and edit date
   are the newest and stay), does not create a change-log storm that makes a running viewer re-read the
   archive (look at the triggers of schema step 7 on `message_version`, if any, and say what a viewer
   open on the catalogue does while the bring-in runs), and never touches `message_raw`.
4. **Words and numbers:** every line the bring-in prints stays numbers and fixed words. A version's text is
   personal content: never printed, never in an error, never in a test's failure message from real data
   (tests use invented texts).

## Bounds
- Only these: `internal/bringin` (and its tests), `internal/catalog/imported.go` and one new test file
  beside it. No schema step, no `go.mod` change, no other package, nothing in `internal/viewer`.
- **Privacy, hard:** invented data only. Never open the owner's old database (`E:\T\...`), the owner's
  brought-in catalogues or library (`%LOCALAPPDATA%\Packages\Claude_pzs8sxrjxfjjc\LocalCache\Local\tgarchive-b`),
  never start the old app, the viewer or the window. The bring-in's own test fixtures build an invented
  old database: use and extend them. The real run on the owner's archive is the main session's, later.
- **Load:** `GOMAXPROCS=2`, `go test -p 1`, `GOGC=50`; before a test run check free memory
  (`powershell -NoProfile -Command "(Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB"`) and
  wait while under 2 GB. **Named tests only while working** (`internal/bringin` whole takes about a
  minute and may run once at the end; `internal/catalog` whole takes about five: never; its tests by name).
  No race detector (nothing here starts a goroutine). Tests do not judge real time.
- New tests, at least: several versions of one message carried in order with the right times; the same
  bring-in again writes none; a version of a message that was not carried is counted, not an error; the
  message's own text and edit date unchanged; units of the two times as the old app writes them; the
  verify line's three numbers; no printed line holds a version's text (scan the output against the
  fixture's texts).
- Commit as you go on `wip/b-edits` and push it to `private` (never another branch):
  `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, the message ending
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Use a scratch folder of your own with a unique
  name.

## At the end, once
`gofmt -l` on what you touched; `go vet ./internal/bringin ./internal/catalog ./cmd/tgarchive-bringin`; your
named tests; `go test ./internal/bringin -p 1`; `CGO_ENABLED=0 go build ./...`. Hand back, as your last
message: the commits (pushed) and the head; the mapping of each old column to each new one with the unit of
each time and where you checked it; what the plan, the run and the verify now print for it (invented
numbers); what a running viewer does while it runs; any difference from this brief with its reason; what
you ran and what it printed; what you did not test; doubts. Commit-ready, nothing left running, the copy
clean.
