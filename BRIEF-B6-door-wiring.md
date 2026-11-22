# Brief B6-D4: the wiring: the viewer's pass-through meets the real door (viewer session B6, 11-16 afternoon)

You are an Opus coder for the viewer track of the new archiver, taking over a branch others built. Work only
in the copy `C:\Users\trabi\Claude\Projects\Telegram\wt-b-viewer` (Go module in `archiver/`), on the branch
`wip/b-door` (head bb5454ce, pushed; check the copy is clean and on that head first; if not, stop and say
so). Go: `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh` in Git Bash.

**Hard rules, first (each was broken once on this project today):**
- **No search over a whole drive** (`find /`, a recursive listing from a drive's root): look only inside the
  copy, a scratch folder of your own and the Go toolchain's folders.
- **Tests and probes name addresses, never host names.** Their only connections are to listeners they open
  on 127.0.0.1. Nothing reaches Telegram or another machine: the collector's side in a test is its fake
  Telegram (`internal/collector/faketg`), nothing else.
- **Invented data only.** Never open the owner's catalogues, library or any real media (nothing under
  `%LOCALAPPDATA%\Packages\Claude_pzs8sxrjxfjjc\LocalCache\Local\tgarchive-b`, `%LOCALAPPDATA%\tgarchive`,
  `C:\Users\trabi\tgarchive-app`, `E:\T`, the NAS); never start the collector, the launcher, a viewer or a
  window on anything but a scratch folder of your own; stop no process you did not start.
- **The PC is short of memory today (about 1.3 GB free of 31).** One go command at a time,
  `GOGC=50 GOMAXPROCS=2 GOFLAGS=-p=1 GOMEMLIMIT=900MiB`, named tests only (`-run`); before each go command
  `powershell -NoProfile -Command "(Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB; (Get-CimInstance Win32_Processor).LoadPercentage"`
  and wait (look again every minute, at most 20 minutes, then go on and say so) while free memory is under
  1.2 GB or the CPU is over 85%. No whole run of a package, no race detector, no Docker, never any cache
  clean-up.
- Words: every string a page, a console or the counts file can show is fixed words in the one place they
  live; nothing of a message, a key, the secret, a path or an id in a log line, an error or a test message.
- Commits on `wip/b-door` only, pushed only with `git push private wip/b-door`:
  `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, the message ending
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, no archive numbers. Never stash, never touch
  another branch or copy. Any file that holds a Windows path is written with the file-writing tool.

## What exists
`wip/b-door` holds the viewer's pass-through to the collector's door, built against a fake door, reviewed
twice by an independent reviewer and fixed (`SEAM-B5-viewer-act.md` in the project folder has the seam and
every round's changes; the reviews are `wt-b6-review-D-scratch/REVIEW.md` and `REVIEW-2.md` there). The seam
is nil in both programs. **Since then the two things it waited for are on the main branch:** the door
(`internal/server/clicks.go`, the adapter `internal/collector/livepages/clicks.go`, the door file's package
`internal/actdoor`) and the collector's key memory with its one state call (`internal/collector`:
`click_api.go`, `click_state.go`; `internal/catalog/schema_actkey.go`). **Read first, in full:**
`archiver/docs/progress/pages-door-REPORT.md` section 2 and `archiver/docs/progress/core-door-REPORT.md`
sections 2 and 10 (after the merge below they are in your tree): they are the contract.

## The steps, in this order
**1. The main head merged in.** `git fetch private`, then merge `private/claude/charming-feynman-vm2xia`
(e9b8c540 or newer) into the branch (`merge --no-ff`, the message "Merge the main head into wip/b-door" with
the co-author line). **It conflicts in eleven files; the main session looked at each:**
- Seven files show as added on both sides, because the compose box reached the main branch as ONE commit:
  `act.go`, `act_keys.go`, `act_ledger.go`, `act_fix_test.go`, `act_fix2_test.go`, `web/js/act.js`: the main
  head's copy of each equals the branch's base 31362d5d (check each: `git diff 31362d5d MERGE_HEAD -- <file>`
  prints nothing), so **the branch's side is the newer and is taken whole**. `act_test.go` differs on the
  main head by ONE line (in `TestActNilDrawsNothing`'s list of scripts, `deleted.js` became `changes.js`):
  take the branch's side and make that one change in it.
- Four files have lines of both sides that plainly stay (the Changes page's and the compose box's, side by
  side): `server.go`, `viewer.go`, `web/app.css`, `web/js/chat.js`: keep both.
- **Anything else, or a check above that does not print nothing: stop, leave the merge in progress, report.**
After it: `go build ./...`; by name `TestAct|TestWall|TestLAN|TestChanges|TestDeleted|TestLive`.

**2. The number is believed by its key (in place of the stopgap).** After a 200 from the queue with a number,
the viewer reads `catalog.ActKey(ctx, account, key)` on its read-only handle: the answer is believed only
when a key row exists for this account and this key and names exactly the answered click; the row itself is
then read through `catalog.Click` as now (account, chat, kind). **The click-time rule of the last round
(`actClickedSince`) is REMOVED for the queue:** with the collector's key memory a second try under a known
key is answered with the FIRST try's click, which is older than the second request, and that answer is
right. For "send again" (no key): the new row must be the one repeat of the row asked (`again_of`), as now;
the click-time rule goes there too (the catalogue allows one repeat per row). A catalogue with no key table
(an older file): the answer is not believed, in the existing words. One read again after 250 ms when the key
row is not there yet, never a loop, as now.

**3. The state read learns of a click by its key.** The viewer's state route answers `key_ref` for a key the
viewer's own memory does not hold by asking `catalog.ActKey` (so a page that holds an uncertain key learns
that its click was queued also after the viewer forgot the key on a failure, or was started again). Bounded:
one read per state ask that carries a key.

**4. The state's new fields, used for what the page already says.** The door's state answer now carries a
wait's end per kind, the chat's slow mode's end, the cap's opening, a read mark's next time, the caption's and
the forward's limits, "limits wanted", "mark as read cannot be read", the collector's clock. Build exactly
this on them, nothing more: (a) **a caption is judged by the viewer** (Core's decision: the door judges
every edit by the text's limit; the viewer knows whether the message it edits has media): an edit of a
message with media is refused before the door when its text is longer than the caption's limit, in the
existing "too long" words; (b) while a wait, the slow mode or the cap is running for the kind the box would
send, the box shows the existing sentence for it with the time (the collector's clock decides "running":
compare the times with the answer's own "now", never with this PC's clock read at another moment) instead
of letting the click go and come back refused; the click is still possible once the time is reached; (c)
"limits wanted" with a largest text of 0 keeps the existing "limits unknown" sentence. Everything else in
the answer stays unused; list what you left. The words "empty" and "too long" now also come from the door:
they are in the set already.

**5. The two programs hand the door in.** `cmd/tgarchive/viewer.go` and `cmd/tgarchive-window/main.go` set
`viewer.Config.Act` to `viewer.NewActDoor(find)`, where `find` is a small function of the command over
`actdoor.ReadDoorFile` **on the folder of the very catalogue file the viewer opened**: it looks whether the
file's name (`actdoor.FileName`) is there first and calls the reader only then (the reader reads again for
about 100 ms when the name is missing; the old archive has no door file ever, and the look happens at every
call of the seam); it answers "no door" for EVERY error; it is safe for calls at once and never panics. The
viewer package itself imports nothing new (its wall tests stay as they are; say what the commands' own
tests check). With `-lan` nothing changes: the routes are this PC's only. The About page's sentence and the
window's gate need nothing (the pass-through is this program's own Go client to 127.0.0.1, not the
browser engine's).

**6. One end-to-end test of the real two ends** in a new test-only package `internal/acttest` (test files
and one `doc.go`; it may import the collector, its fake Telegram, the server's door and the viewer; nothing
imports it; the integrator agreed to the place). **At least:** the viewer's routes (a real `viewer` on an
invented catalogue, its pass-through handed a door file written by `actdoor.Write`) against the REAL door
routes of `internal/server` over a seam that records calls: every one of the six door routes reached with
the body the door takes, each refusal word of the door's closed set shown by the viewer as its own word, the
guard's 403 and the 404 "no door" read as the pass-through reads them, a wrong secret reaching nothing. **And,
if the collector's rig with the fake Telegram can be built from what the packages export without editing a
file of another track:** the whole chain: one click in the viewer's route leads to exactly one request at
the fake Telegram and a row "done" that the viewer's state read then shows; the same click sent again under
its key after a lost answer (the door's answer dropped by a listener in between) leads to no second request
and is believed by its key; a wrong secret leads to none. **If the rig is not exported, do NOT edit the
collector's or the server's files:** build the first part, and say exactly which small export would make
the second possible (the main session asks its owner).

## Not yours
Nothing in `internal/catalog`, `internal/collector`, `internal/server`, `internal/actdoor`,
`internal/launcher`, `internal/window`. No schema step, no `go.mod` change. No real click anywhere: the first
real one is the owner's.

## At the end, once
`gofmt -l internal cmd`; `go vet ./internal/viewer ./internal/acttest ./cmd/tgarchive ./cmd/tgarchive-window`;
`go build ./...`; by name: every test you added, `TestAct|TestWall|TestLAN|TestChanges|TestDeleted|TestLive`
of the viewer, the two commands' tests; `node --check` on each changed script;
`git diff bb5454ce HEAD -- archiver/internal/viewer | grep '^-func Test'` prints nothing or you account for
each line (the stopgap's test changes its meaning: say how). Bring `SEAM-B5-viewer-act.md` (the project
folder; the file-writing tool; no Windows path) up to date: a section "Changed by the wiring". Hand back, as
your last message: the head (pushed) and the main head it holds; the merge, file by file; each of steps 2 to
6 with what you did and any difference and its reason; for step 6 what is tested end to end and what is not,
and the export you would need if any; every new or changed string; what you did NOT test (no real collector,
no browser unless you say how); anything in the two reports that does not fit what the code does; your
doubts, plainly. Commit-ready, nothing left running, the copy clean.
