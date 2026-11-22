# Review brief B6-D: an independent, read-only review of the viewer's pass-through to the collector's door

You are an independent reviewer (Opus) with a security eye, for the viewer track of the new archiver. You
did not write this code and you owe its coder nothing. The piece: branch `wip/b-door`, head d5dd4869, in the
copy `C:\Users\trabi\Claude\Projects\Telegram\wt-b-viewer` (Go module in `archiver/`). It was cut from
`wip/b-compose` 31362d5d and holds a merge of the main head (6060886a). Its own difference is
`git diff 31362d5d d5dd4869 -- archiver/internal/viewer` (the merge brought other tracks' packages: not yours
to review). What it was asked to do: `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-B6-door.md` (read it in
full first), built to the door's contract in `BRIEF-G8-clicks-door.md` (points 2, 3, 5) and to
`SEAM-B5-viewer-act.md` (its last section is this piece's), on the design
`DESIGN-CORE-client-actions.md` (sections 3 to 5), all in `C:\Users\trabi\Claude\Projects\Telegram`.
Go: `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh` in Git Bash (Go is not on PATH).

**Why this deserves a hard look:** this is the file that turns the viewer from a reader into something that
can make the owner's real Telegram account send, edit, delete, forward and react. The seam is still nil in
both programs; review it as what will be switched on next. The door itself (the pages track) and the
collector's key memory (Core) are being built now and are not yours; what this piece ASSUMES of them is.

**Also yours, because nobody but its coder has read it:** `web/js/act.js` as changed by the compose box's
second fix round (`git diff b1dc2f9f f361d35c -- archiver/internal/viewer/web/js/act.js`: the hold of Send
after a failure, the per-button keys) together with what this piece changed in it. The two earlier reviews
and their probes are in `C:\Users\trabi\Claude\Projects\Telegram\wt-b5-review-A-scratch` (`REVIEW.md`,
`REVIEW-2.md`): read them so that you do not spend time on what they settled, and check that this piece
reopened none of it.

## How
- **Read-only on the copy and the branch:** change no tracked file, commit nothing, push nothing. Probes live
  in a new folder `C:\Users\trabi\Claude\Projects\Telegram\wt-b6-review-D-scratch` (lay a probe in with
  `go test -overlay`; the copy must be clean when you end: say so).
- **Try to break it.** A finding is **confirmed** only with a probe that shows it or a line-by-line argument
  nobody could doubt; otherwise **plausible**, with what would settle it. Look hardest at:
  1. **One click, one request, end to end.** From a key press in the page to the bytes on the door's
     socket: is there any path on which one click of the owner becomes two requests at the door, or two
     different keys for one click, or one key for two different clicks? The Go client itself (a transport
     that retries a request on a fresh connection, a body sent twice, `Expect`, a redirect, a 1xx answer, a
     connection the door closes before, during or after it read the request); the state call asked "once
     more"; the page's hold and its timers; a page reload or a second tab in the middle; the viewer's own
     key memory against the door's. Where only the door's key memory guards, say so exactly.
  2. **"Nothing left this program" against "it left and no answer came".** The piece answers the first as a
     certain "not running" and forgets the key. Find any case where bytes of a changing request could have
     reached a listener and the piece still says "not running" (the dial flag and the context; a connection
     made and reset before the write; a deadline that ends between the dial and the write; a body larger
     than the socket's buffer), and any case where the reverse makes the page hold for nothing.
  3. **Where it can connect, and what goes there.** The address check against every form you can think of
     (the brief's list, plus unusual digits, signs, spaces, a newline, a NUL, a very long value, `127.1`,
     octal and hex forms); whether anything but the checked address can ever be dialled (the URL, the Host
     header, a redirect, a proxy variable in the environment, `NO_PROXY`, HTTP/2, a Unix socket); what
     happens when the door file names a port on which ANOTHER local program now listens (a stale file after
     an unclean stop): what that program receives (the old secret, the owner's text) and whether that is
     acceptable given what a local program can already read; whether a value from the door file or from the
     door's answer can reach a header, a log line, an error, the counts, a page (response splitting in the
     secret, a word that is not in the set, a huge or deeply nested body, a slow body, a body that never
     ends).
  4. **The secret.** Every place it is held, copied or compared; how long it stays in memory; whether it can
     reach the page, the home-network listener, a log, a panic message, a test's output, the timings page.
  5. **The door seen and not seen.** Until a door file was found once the viewer must be exactly the old
     reader. Is anything of the acting side reachable, drawn or asked before that (the live poll's new
     field, the page flag now built per page load, the routes)? On the home-network listener, in every
     class, before and after the door was seen? Can a request from another device, or a page of another
     site in the owner's browser, cause the door file to be looked for, or learn whether a collector runs?
     The cost of the look (a file read per call, per page load, per live poll: bounded how?).
  6. **The seam's new parts.** The second word on "send again" (when exactly does the page send
     `not_in_chat`, and can it send it for a click the app's own check should still guard?); "not arrived"
     (who can call it, on which rows, twice); the rows now kept open in `act_ledger.go` (an "arrived" the
     app made stays drawn for days: bounds, the 200 open tips, a chat with thousands of such rows); the
     candidates read from the catalogue as the hint (its cost per poll on a large chat, its cache keyed by
     what, a hint pointing at a message of another chat, account or click).
  7. **The words and the strict reading.** A 409 word of the viewer's own set or an unknown one; a 200 with
     extra fields on each route; the state answer's fields with wrong types or impossible values (write
     true with a why, a negative largest text, a huge one); the two new words on each route; every new
     string the page can show: fixed, and put into the page as text, never as markup.
  8. **The wall.** Can a later change to `act_door.go` or to another file open a second way out without a
     wall test failing (a client built in another function of that file, `http.DefaultClient` through a
     helper, `net.Dial` in a test-tagged file, a new import)? Does `TestWallDoorOneClient` pin behaviour or
     only text? Say what it would not catch.
  9. **The tests the hand-back leans on.** For each of the coder's thirteen mutations, is the test that
     caught it caught for the right reason? Which defects above would every one of its tests still pass
     with?
- **What you cannot check, say plainly:** no real door exists yet; the JSON names of the state answer and
  the `{"ok": true}` answers are the coder's choice until the door's report states them.
- **Privacy and load:** never start the owner's viewer, window, collector or old app; never open the owner's
  catalogues, library or any real media (nothing under
  `%LOCALAPPDATA%\Packages\Claude_pzs8sxrjxfjjc\LocalCache\Local\tgarchive-b`, `%LOCALAPPDATA%\tgarchive`,
  `C:\Users\trabi\tgarchive-app`, `E:\T`, the NAS); a viewer may be started only on a scratch folder of your
  own with invented files (`tgarchive fabricate -real-rows`), and nothing may reach Telegram or any machine
  but this one: your probes' only connections are to listeners you open yourself on this PC. `GOMAXPROCS=2`,
  `go test -p 1`, `GOGC=50`, named tests and your probes only; before each go command check free memory and
  load (`powershell -NoProfile -Command "(Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB; (Get-CimInstance Win32_Processor).LoadPercentage"`)
  and wait while free memory is under 2.5 GB or the CPU is over 85%; no whole run of `internal/viewer`, no
  race detector, no Docker, never any cache clean-up. Other copies (`wt-b-window`, `wt-pages-door`, any
  `wt-core-*`) are other people's: do not touch them. Any file that holds a Windows path is written with
  the file-writing tool, never from a shell string.

## Hand back, as your last message
Write `REVIEW.md` in your scratch folder (**no path of this PC in it**) and give its content: a verdict in
three lines (may the seam be wired to a real door after these fixes, or not); the findings worst first, each
with: confirmed or plausible, the file and line, what happens and to whom, the probe (its file in the scratch
folder and what it printed), and the smallest fix you would accept; then "Checked and sound", "The tests the
hand-back leans on", "What this piece assumes of the door and of the collector's key memory" (each as a
sentence the other tracks can test), and "Not run". No praise, no summary of what the code does.
