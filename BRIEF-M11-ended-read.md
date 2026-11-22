# Brief M11 (FINAL, 11-16 03:04, the mirror session M4): when a want ends, the read the mirror asked for ends too

**Your copy: `C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-endread`, branch `wip/mirror-endread`, cut from
`wip/mirror-door` f0d54ad6** (M9, listed and in its merge run: it holds the main head d10e3bd9 with Core's K11).
Do NOT merge the main head into it: when M9 is on the main head, your commits are applied onto that head by
a clerk. The Go module is `archiver/` in the copy. House rules: those of `BRIEF-M9-mirror-door.md` (read its
first two paragraphs and `BRIEF-M7-auto-timing.md`'s "Running things" and "Report and hand-back"; one copy;
commit and push only `wip/mirror-endread` to `private` as you go; nothing against Telegram; invented data, the
fakes and the injected clock; no name, text, id or link in any log, error, printed line, test name or commit
message; constant format strings; named tests only while working; one go command at a time, the PC measured
before each: under 2 GB free or the CPU over 80%: wait). No schema step; no goroutine, lock or channel; no
file of `internal/telegram`, `internal/reader`, `internal/server`; in `internal/collector` only `mirror_auto.go`,
`mirror_door.go` and their tests (Core's `reader.go` is read, never edited).

**Checked by me on f0d54ad6 (so you need not search):** `ReadApproval.MirrorEndedAt` is in `collector/reader.go`
(line 34); `readChats` (86 to 92) marks a chat "ended" when the record's `By` is not empty and the field is
not 0, whatever the `By` word (`mirror_auto` and `mirror_command` both), and "ownerEnded" (ignored, said once)
when `By` is empty; `EstimateRead` (151 to 158) keeps a mirror's approval and its end across a new estimate;
`approveRead` (188 to 192) makes the record the owner's and drops the field. A record that does not parse is
"no record" to the reader (`approval`, 108 to 118).

## Why (the reviews of M8 and M9; board messages 79 b, 81, 84 e, 86 a, 87)
A want that ends for good (the source protects its content, the owner's never mark, the source left, the mirror
chat removed, the owner's stop from a page) kept the approval of its chat's read that the mirror's task had
written, so the reader went on reading that chat's history for a mirror that will never be made: requests
for an item that will never be acted on (TRIED-BEFORE 24, rule 9). The owner's page says "Stop mirroring:
nothing more for that chat"; pages keeps a mark on that line until this piece is merged.

## What exists (Core's K11, merged as 3ced3c09: check on your head)
`collector.ReadApproval` has `MirrorEndedAt int64` (`mirror_ended_at`, omitted when 0; `reader.go`). The reader
sends no history page, gap read or topic list for a chat whose approval is the mirror's own (`By` not empty)
and carries it; the cursor is kept; the owner's own yes writes a record without `By` and without the field
and the read resumes from the cursor (`reader.go` about 150 to 191: read how an existing record is carried
over and when the field is dropped). Core writes the field only in tests: **this piece writes it for real.**
The mirror's approval is written by `autoApprove` in `mirror_auto.go` (in the want's transaction; it leaves
any record already on file exactly as it is) and by `Want` through `AutoDeps.Approve`.

## What to build
1. **A closure beside `Approve`: `AutoDeps.EndRead func(tc *catalog.Catalog, account, chat int64, at time.Time)
   error`** (the collector's, in `mirror_auto.go`): reads the chat's approval record; when it parses, its `By`
   is the mirror's (`mirror.AutoApprovedBy`; check whether the command's own mark `mirror_command` counts:
   read `reader.go` and say) and `MirrorEndedAt` is 0, it rewrites the same record with the time; a record
   of the owner's (no `By`) is never touched; no record: nothing; a record that cannot be parsed: left as it
   is and counted (a number in the task's numbers, said once a session in fixed words), never rewritten.
2. **Every end of a want calls it in the end's own transaction.** `EndMirror` gains what it needs for that
   (an `also func(tc *Catalog) error`, as `AddMirrorWant` has), and each caller passes it: the task's ends
   in `auto.go` (`autoCheck`'s three, the mirror row "protected", the mirror chat removed, the account's
   own refusal if it ends wants: check), and `mirror.Stop`. A failure of the closure fails the end (nothing
   half done).
3. **Every new beginning clears it in its own transaction:** `autoApprove` (the look's take and `Want`): when
   the record on file is the mirror's and carries the field, the field is cleared (the read resumes from
   its cursor); `MirrorAllow` when it brings a want back to life (an end cleared): the same, through the
   door's transaction. The owner's stop is ended only by a new want (M9): that want's `Approve` clears it.
   Core's note (message 87): without this a new want for a chat whose record still carries the field would
   never be read.
4. **The never mark ends the read at once, in the mark's own transaction.** Today the `Never` door only writes
   the mark and the task ends the want at its next turn; in a run without the switch an automatic want is
   never visited, so its chat would be read on under a never mark. So: `Never` (the door) and the command's
   `-never` call the closure for the marked chat and the chats its migration links it to, in the mark's
   transaction, when a want or a mirror row of the account is on record for it; `Allow` clears the field
   again when it removes the mark and a want that is not ended remains (and never when the want stays
   ended or stopped). The command runs with the collector stopped and has the catalogue's handle: give it
   the same closure (find how the command already writes its own approval, `mirror_command`).
5. **The page's state:** a want whose chat's read is ended is not "wanted" or "kept": no change expected
   (an ended want is already `StateEnded`); say so with a test. An automatic want that waits for the switch
   (`StateWaiting`) is alive: its read is NOT ended (said in a comment and held by a test).

## Tests (named; each rule's line undone once and seen to fail)
In the collector, on the fake Telegram and the rig's clock: a want whose source becomes protected at page 2
of 5 of its read: no third page (count the fake's history requests for that chat); the same for a never mark
and for `MirrorStop`; then the owner's `MirrorAllow` (for the mark) or a new `MirrorWant` (for the stop): pages
3 to 5 are read and the mirror is made; a chat the owner approved by hand is read on whatever the mirror
does; a record that cannot be parsed is left byte for byte and counted; the automatic take of a chat whose
old record carries the field clears it. In `internal/mirror`: each end passes the closure; a closure that
fails leaves the want not ended.

## End
Named tests while working; at the end once: whole `internal/mirror`, `internal/collector -run
'Mirror|Reader.*Ended'` (check Core's test names), gofmt, vet; no race detector. Report
`archiver/docs/progress/mirror-endread-REPORT.md`; the branch pushed; the copy clean. After it: one
independent read-only review (short), its fixes, the full runs by a clerk, an entry, and a line under board
message 83 (pages, 00:10) that the sentence "nothing more for that chat" is now true for the reader too.
