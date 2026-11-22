# Brief G4f: take the main head (the mirror's "ended read", M11) into the mirror page's branch

Written 2026-11-16 by the pages session (P3). For one Opus coder. Small: one merge, about 20 lines of code,
two tests. **Routine rule of this project: you run named tests only; the whole runs afterwards are a clerk's.**

## Where
- Copy: `C:\Users\trabi\Claude\Projects\Telegram\wt-pages-g4` (Go module in `archiver/`), branch `wip/pages-g4`
  at 9b4e265a, clean. It holds the main head a37ed4c3.
- The main branch `claude/charming-feynman-vm2xia` is now at 6365a08a: one piece further, the mirror track's M11
  ("its read of a chat ends when its want ends"). Read its account before you touch anything:
  `archiver/docs/progress/mirror-endread-REPORT.md` and `archiver/docs/review/mirror-endread-2026-11-16.md` at
  6365a08a, and in `internal/collector/mirror_auto.go` there: `autoApproveNoted`, `setReadEnd`, `endReadFor`,
  `resumeReadFor`, `readNotes`, `noteReadBad`; in `internal/mirror/door.go` the comment on `Want` ("A mirror's
  end of the chat's read on record is cleared in the same transaction: by d.Approve for a source not read to
  its end, by d.ResumeRead for one that is").
- You never merge into or push the main branch. You push `wip/pages-g4` to the remote `private` only.

## What to do
1. **Merge 6365a08a into `wip/pages-g4`** (`git merge`, a merge commit; both sides stay). One file conflicts:
   `internal/collector/pages_mirror_test.go`. The overlap is spurious: main changed one line in
   `TestChatsPageWithAutoMirror` (`cat.SetMirrorNever(..., nil)`), the branch added
   `TestMirrorPagesWishOnFakeTelegram` and its helpers. Keep every line of both.
2. **Make it build:** `catalog.EndMirror`, `SetMirrorNever` and `MirrorAllow` take one more parameter (a
   closure; `nil` keeps the old behaviour); `doorDeps` and `accountDeps` take a `*readNotes`. Fix every call of
   the branch's own files (`mirror_door.go`'s lent lines, `pages_mirrors.go`, `pages_mirror_test.go`, the
   adapter and its tests, the server's fake if it calls any). Change nothing of the mirror track's code beyond
   the lent lines below.
3. **Bring the lent lines up to M11's rule.** `MirrorWantRead` and `wantApprove` in
   `internal/collector/mirror_door.go` (commit cf434aba) replace `d.Approve` for the page's want. Since M11,
   `d.Approve` is also what clears the mirror's end of a chat's read for a source not read to its end. As the
   lent lines stand they return `nil` for an approval on record and never clear it: **after "Stop mirroring"
   on a chat still being read, "Mirror this chat again" would write the want and the reader would never read
   the chat on** (the record still carries `mirror_ended_at`). So:
   - `MirrorWantRead` follows `MirrorWant` as M11 left it: `notes := &readNotes{}`, `accountDeps(ctx, account,
     notes)`, and `c.noteReadBad(account, notes.bad)` after the want and before the nudge.
   - `wantApprove(ctx, requests, n)`:
     - no record, `requests == 0`: `autoApproveNoted(ctx, n)` (as now through `autoApprove`);
     - no record, `requests != 0`: `ErrReadCostChanged` (unchanged);
     - a record that cannot be parsed: `ErrReadRecordUnreadable` (unchanged, fail closed: nothing written, so
       nothing to count);
     - **an approval on record: `n.done(tc)(setReadEnd(ctx, tc, account, chat, 0))`**: by `setReadEnd`'s own
       rules the owner's record is never touched, the mirror's own record loses only its end, every other
       field stays;
     - an estimate not approved whose count is the page's: approved as now (`ApprovedAt`, `By` the mirror's),
       with `MirrorEndedAt` 0 in what is written; a count that differs: `ErrReadCostChanged` (unchanged).
   - Keep the lent lines one reviewable unit: make this change its own commit after the merge commit, touching
     `mirror_door.go` and tests only, and say its hash in your report.
4. **Tests (named, bounded; no real time judged):**
   - In the unit test of the approval (`TestMirrorWantApproveRecord`): the mirror's approved record carrying an
     end loses the end and keeps every other field byte for value; the owner's approved record is byte for
     byte the same; an approved record of the mirror's with no end is byte for byte the same.
   - One rig test on the fake Telegram, modelled on the closest test in `mirror_endread_test.go` (use its
     helpers; do not build a second rig): a chat not read to its end, its size asked, wanted by
     `MirrorWantRead`, stopped by `MirrorStop` while its read is under way (hold the read with the rig's holds,
     never a sleep); the count of history requests stays where it is over the task's and the reader's next
     turns (allow the one reader turn M11's account names, if the rig can meet it: say what you did); then
     `MirrorWantRead` again with the plan's new token: the read goes on to its end and the mirror holds every
     message with a file once, in order. If the rig cannot hold a read mid-way without a new mechanism, stop
     and say so instead of building one: the unit test and a door-level test on a catalogue (stop, then the
     want: the record's end is gone) are then enough.
   - Undo the one new line (the clear) once and show that a test fails; put it back.
5. **Run, one go command at a time** (Git Bash; `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`;
   before each go command measure:
   `powershell -NoProfile -Command "(Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB; (Get-CimInstance Win32_Processor).LoadPercentage"`
   and wait while free memory is under 2.5 GB or the CPU over 85%): `go build ./...`; `gofmt -l` on what you
   touched; `go vet ./internal/collector/ ./internal/collector/livepages/ ./internal/server/`;
   `GOFLAGS=-p=1 GOGC=25 GOMAXPROCS=2 go test -count=1 -run '<your new tests>|TestMirrorWant|TestMirrorPagesWish|TestChatsPageWithAutoMirror|TestMirrorPages' ./internal/collector/`.
   No whole run of `internal/collector`, `internal/server` or `internal/catalog`, no race detector, no Docker.
6. **Write it down:** a short section "G4f" at the end of `archiver/docs/progress/pages-g4-REPORT.md` (what the
   merge needed, the lent lines' change and why, the tests and their counts, what you did not verify). Commit
   (`git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, the message ending with the line
   `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`), push `wip/pages-g4` to `private`.

## Rules
- Nothing runs against Telegram. Never touch `E:\T\tg-dl`, the folders `a3`, `b`, `app`, any real catalogue,
  media, session or account; start no installed program; leave every running process and container alone.
  Invented data only; print counts, sizes and timings only.
- New log lines use constant format strings (you should need none).
- Any file that holds a Windows path is written with the file-writing tool, never from inside a shell or script
  string.
- If anything is not as this brief says (another conflict, a test of the mirror track's that fails after the
  merge, a signature this brief does not name), stop at that point and report it; do not work round it.

## Hand back
Your final message, numbers and names only: the merge commit and the lent lines' commit; the head pushed; files
changed by you beyond the merge; each named test run with ok or FAIL and seconds; the mutation's result; what
you did not verify; anything you met that was not as written.
