# Brief K24: the brought-in account and the old library as a second read-only root (Core, K-6, 2026-11-21)

**Why:** the owner decided (board items 43 and 44, 11-21 about 23:05) that the old app has made its last write
and that the old archive is brought into the app's catalogue by a step the owner starts from the launcher (the
app stops, about 15 minutes, starts again; first on a copy). Read
`C:\Users\trabi\Claude\Projects\Telegram\DESIGN-UNIFIED-ARCHIVE.md` whole (section 5 "Core" is this piece; sections 3
and 4 say what the bring-in writes) and `DIGEST-LESSONS.md`. The viewer track (B9) builds the bring-in itself
and calls your door through its `Doors` interface (`internal/bringin`: read how it calls the catalogue today).

**Rules:** you are the one Opus coder, start to finish. Named tests and small packages only (never the whole
`internal/collector` or `internal/catalog`); gofmt, vet the changed packages; the viewer's `TestWall`. Every go
command through `bash /c/Users/trabi/Claude/Projects/Telegram/runs-core-k5/go1.sh <folder> ...`. Invented data
only; never touch a running program, the main copy, `C:\Users\trabi\tgarchive-app`, `E:\` or the NAS. Nothing
against Telegram. Copy `wt-core-oldroot`, branch `wip/core-oldroot` from `private/claude/charming-feynman-vm2xia`
(6aa225fb); commit form as always (`git -c user.name=Claude -c user.email=noreply@anthropic.com commit`,
`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`); push only your branch. This piece decides that some
files are never downloaded: **one independent review follows it.**

## What to build
1. **`MarkBroughtIn(ctx, account)`** in `internal/catalog` (the name B9 asked for; say if the code wants another):
   the account row marked as a brought-in archive (a column or a table: a schema step if needed; claim the
   number on the board's schema line before you take it; on the branch the step after the head's). Then, at
   every place, by test:
   - the collector never asks for its session, never signs it in, never reads, mirrors or downloads with it;
     its lanes are never built; the automatic mirror and the own-chat read (K21) pass it over; the alerts (K22,
     if merged) raise nothing for it;
   - its reach rows (the files it saw and never saved) are **not "waiting" in any count** (the Supply, the lane
     counts, the Overview's and pages' numbers, the stall rule) and are never claimed by any lane; they stay as
     facts for the viewer. A file reached by the brought-in account AND by a live account is wanted for the live
     account exactly as before (the mark removes nothing a live account wants).
   - idempotent; refuses an account that is signed in (a session file present, or `collector.signed_in.<n>`).
   - list every reader you changed and why (grep `account` and `removed_at` users: the mark must be seen
     wherever "removed" is).
2. **The old library as a second root, read only:** a stored setting (key, door to read and set, check that it
   is an absolute folder; no upper bound or guess); files whose place has source "old app" (`file_copy.source`,
   `internal/catalog/schema9.go`; read how `file.path` and `file_copy.path` are stored by the bring-in, relative
   or absolute) resolve under it through one function the viewer and the collector both use. **Nothing ever
   writes, moves, links or deletes under it**: find every writer of library files (the store's copier, linker,
   orphan sweep, the backup) and show by test that none takes a path under the old root. Its reads follow the
   NAS rule: nothing in the background reads it while copies wait (the exact check's fall-back already exists:
   check it covers this root).
3. **The step's stop and start (check only, no new code unless it fails):** the owner's clean stop of the app
   (the launcher's Quit, `internal/launcher`, pages' track) ends the collector and the watchdog, and the watchdog
   does not restart the collector after a clean stop (`internal/watchdog`: a restart only on proof of a crash).
   Name the existing tests that show both; if none does, add one in `internal/watchdog` (Core's). Say what the
   launcher's step must do (for pages and B9), in two lines.

**Not in this piece:** the settle when Telegram deletes the old account on 11-29 (its files stay, its reach rows
go): listed as next.

## Hand back
`archiver/docs/progress/core-oldroot-REPORT.md` and your last message, short: head pushed; the exact Go names for
B9 (the mark, the root's setting and its resolve function); schema step if any; every reader changed; the writers
shown never to touch the old root; the tests as run; what you could not test; what the code contradicts here.
