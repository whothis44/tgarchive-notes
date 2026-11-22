# Brief U1: the bring-in writes the old archive into the app's own catalogue (viewer and bring-in, B9, 11-21)

You are an Opus coder for the viewer and bring-in track of a private Go project (a Telegram archiver). Work
ONLY in the copy `C:\Users\trabi\Claude\Projects\Telegram\wt-b-unified` (branch `wip/b-unified`, cut from the
main head af4ca40). The Go module is in `archiver/`. Commit as you go with
`git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, each message ending with the line
`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, and push: `git push private wip/b-unified` (never
another branch, never `main`, no tag, no merge into another branch).

## Rules (binding)
- **Invented data only.** Never open the owner's real catalogue, the old app's real database, the folder
  `E:\T\tg-dl`, `%LOCALAPPDATA%\tgarchive-b` or any copy of them, not even read-only. Tests build their own
  invented old database (the package's `fake_test.go` and the oldgen helpers) and their own invented app
  catalogue. Print counts, sizes and timings only.
- Every `go` command goes through the track's lock script, one at a time:
  `bash /c/Users/trabi/Claude/Projects/Telegram/runs-b7/shell/scripts/gorun.sh <dir> go test ./internal/bringin -run 'Name' -count=1`
  (it measures the PC and sets the environment). Another coder of this track uses the same lock: wait for it.
- Tests while working: ONLY named tests (`-run`) of what you change. `internal/bringin`'s whole suite is
  slow (a scale test): never run it whole; never the race detector; never `go vet` over many packages.
- Do not touch `internal/catalog`, `internal/viewer`, `internal/appshell` or any package outside
  `internal/bringin` and `cmd/tgarchive-bringin`. What the catalogue lacks goes through the bring-in's own
  `Doors` interface (`internal/bringin/config.go`): a stage that needs a missing door stops with a
  `DoorError` before it writes (the package's existing pattern; read `BRINGIN-WANTED.md`).
- Text with a Windows path goes into files through the Write/Edit tools, never through a shell string.

## Read first, yourself
`C:\Users\trabi\Claude\Projects\Telegram\DESIGN-UNIFIED-ARCHIVE.md` (whole: sections 3 and 5 are this piece);
`repo-archiver/archiver/docs/BRINGIN-WANTED.md`; `internal/bringin/errors.go` (the package's doc),
`config.go`, `run.go` (`checkNew`/`start`'s refusal `ErrNotOurs`, `account`, the chats stage, the holds
stage), `run2.go`, `plan.go`, `old.go`; `cmd/tgarchive-bringin/main.go`; `internal/catalog/bringin.go`
(`ImportSaved`, `HoldProbable`, `MarkNotCopy`: read what they do when the file or media ALREADY exists in a
catalogue the bring-in did not make).

## The goal
Today the bring-in writes only into a NEW catalogue (it refuses one with accounts it did not make). The owner
wants ONE archive: the old app's archive brought into the app's own catalogue as an account of its own that is
never signed in, so that every copy check of the app runs against what the old app downloaded. Build the
bring-in's side: a mode of its own and the note's five rules. Nothing real is written by this piece.

## What to build
1. **A mode, named on the command: `-into-app`** (in `cmd/tgarchive-bringin` and `Config`), never the
   default. Without it everything is as today (a new catalogue only; `ErrNotOurs` as today). With it:
   - the target must be an existing catalogue of the app (not made by the bring-in): refused otherwise with
     a fixed sentence; one the bring-in started earlier in this mode is taken again (its own mark, a setting
     key of its own, distinct from the new-catalogue mark), so that a second run adds only what is new;
   - **rule 1:** the old account is written as an account row of its own (`UpsertAccount` as today) and then
     marked as a brought-in archive through a NEW door `MarkBroughtIn(ctx, account int64) error` in the
     bring-in's `Doors` (asked of Core on the board, message 211: it may not exist yet: the account stage
     stops with a `DoorError` naming it when it is missing; your fake implements it for the tests). Never an
     existing account of the app reused or changed;
   - **rule 2: no chat choice is written** in this mode: no `SetChatWants`, `SetChatKindsOff`,
     `SetChatCollect`, `SetChatRank`, `SetTopicRank` on any chat, whether the app has it already or the
     bring-in makes it. The chat's facts and topics' facts are written as today (`SaveChatFacts`,
     `SaveTopics`, `EnsureTopic`). What the old app chose per chat (collect on or off, kinds, rank, topic
     ranks) is counted in the report ("old choices not applied: N chats switched off, ...") and kept as the
     old app's record in ONE place of the bring-in's own (a setting key per chat under the bring-in's prefix,
     or a small JSON in one setting: your choice, numbers in the brief's hand-back), never read by the
     collector;
   - **rule 3: it only adds.** A media or file the catalogue already holds keeps its state: a file the app
     saved, held, released, linked or marked gone is not changed; a hold (`HoldProbable`) is NOT written for a
     media whose want row exists and was not made by this run, nor where the owner has spoken (`keep_held`, a
     release on record in `c_want.released`, a `not_copy` row, the owner's pair words in `c_pair_word`): read
     each in `internal/catalog` to name the columns right, and if a needed read has no exported door, add it
     to `Doors` as WANTED and stop that stage cleanly; `MarkNotCopy` only adds; a repeat run writes nothing
     (prove it with a test: run twice, the second writes 0 rows of every kind);
   - **rule 4:** small transactions, as the package's chunks already are (say the largest chunk's size and
     the longest hold of the writer measured in a test at a few thousand rows);
   - **rule 5:** every place of the old app's bytes is written with its source "old app" and its path
     relative to the old library's root, as `ImportSaved` already does: check it, and that a file the app
     already holds (same SHA-256) gets the old place as ANOTHER place of the same bytes, never a new file
     row and never a change of the app's own place.
2. **A dry run in this mode:** the existing `plan` command with `-into-app` prints the counts it WOULD write
   (accounts, chats new and already there, messages, media new and already there, files new and already
   held, places, holds written and holds left out by rule 3 with the reason counted, edges, not-copy rows,
   old choices not applied) and writes nothing; a test proves the catalogue is byte-identical after it.
3. **Tests** (each by name), on an invented app catalogue with TWO accounts of the app (made through the
   catalogue's API) holding: a channel also in the old database (shared space), a chat the owner switched off,
   a file the app saved that the old app saved too (same SHA-256), a file the app holds as probable that the
   owner then released, a pair the owner called not the same, and a media the old archive lacks. Show: the
   app's choices and states untouched after the run; the old account marked through the door; the old
   place added beside the app's; no hold over the owner's word; the second run writes nothing; without
   `-into-app` the refusal is as today; with the door missing the account stage stops before writing.

## Hand-back (your final message; short; numbers, no real data)
Commits (hash, subject), pushed; what each rule does in a few lines and where; every test run by name with
its result and seconds; the doors you added to `Doors` as WANTED (names, signatures, what each must keep) so
that Core can build them; anything in the design note or this brief that the code says is wrong or
impossible. Stop at the first thing that is not as written here and say it, rather than building round it.
