# Independent review of K9a, the ledger of the owner's clicks (Core, K-3, 2026-11-15 23:45)

For one reviewer who has not seen the work. Read-only on the tree: you change no file of the copy and
commit nothing. Your one product is the file `C:\Users\trabi\Claude\Projects\Telegram\REVIEW-K9a-ledger.md`.

## What is reviewed

Branch `wip/core-ledger` at 726844a7, copy `C:\Users\trabi\Claude\Projects\Telegram\wt-core-ledger` (Go
module in its `archiver` folder), against the head it was built on, e7624d5d (the request layer, already
reviewed: not yours): `git diff e7624d5d 726844a7`. Six files: `internal/catalog/schema_act.go` (a schema
step, two tables, twelve doors), its test, three lines in `internal/catalog/catalog.go`,
`internal/tgstore/act.go` (the adapter that makes the tables the request layer's `telegram.ActLedger`),
its test, and the coder's report `docs/progress/core-ledger-REPORT.md`.

It is the write-ahead record of a feature that WRITES to Telegram on a real account for the owner (send,
reply, forward, edit, delete, react, mark as read). Every click is a row here before any request leaves.
The request layer relies on this record for four things, and a defect in any of them posts something
twice, posts hours late, hides that something was posted, or lets the app write faster than its own
cap: (1) a row can be marked "sending" exactly once; (2) nothing that was "queued" or "sending" when the
program stopped is ever sent by the program afterwards; (3) the list of what was sent recently is
complete; (4) an end state is never overwritten. It also holds the text of messages until they are sent:
the most private thing in the table. That is what you are looking for. Style is not.

## Read first

1. `C:\Users\trabi\Claude\Projects\Telegram\DESIGN-CORE-client-actions.md` (what the owner agreed to).
2. `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-K9a-click-ledger.md` (what the coder was given). The
   brief may itself be wrong: say so where it is.
3. In the copy: `archiver/docs/TRIED-BEFORE.md` sections 24 and 25 (thirteen rules for anything that acts
   for the owner; rules 11 and 13 bind this piece), `internal/telegram/act.go` (the `ActLedger`
   interface, `ActOutcome`, how `Do` calls `Begin`, `End`, `Sent`, `ChatRefusal`), the catalogue's own
   ways it follows (`internal/catalog/catalog.go` around the list of schema steps and `Batch`/`exec`,
   `schema_mirrorname.go`, `schema_mirrorauto.go`).
4. The code under review in full; the coder's report last, and with suspicion.

## What to try to break (questions, not conclusions)

- **Begin:** can two callers (two connections, two processes on one file, a retry after a "database is
  locked" or a timeout whose statement did commit) both get nil for one row? What does the caller get
  when the statement committed but its answer was lost (the request layer then sends nothing: is the row
  left "sending", and what does the next start make of it)? A ref that does not exist, 0, negative.
- **End:** from every state; twice; with an outcome kind the adapter does not know; with new ids for
  messages that are not the click's; when the per-message update fails halfway (one transaction?). Can any
  call move a row out of an end state, or from "queued" straight to an end without "sending"?
- **The sweeps:** is there any order of events in which a row that was "queued" or "sending" before a
  stop is "queued" again afterwards, or is returned by "the next click to send"? A crash in the middle of
  the start's sweep; the age sweep racing a `Begin` on the same row (which wins, and is the loser told?).
  A clock that steps back between the click and the sweep.
- **Send again:** two at once on one row; from every state; a repeat of a repeat; the random ids of a
  forward's messages (the same, in the same order, for every message?); can a repeat be made while an
  earlier repeat is still queued or sending; what happens to the old row's text and to the new one's.
  Can "send again" resurrect a click whose text was cleared, or one the owner said "left" to?
- **Sent since** (the cap's source): rows it can miss (a state, a NULL time, the boundary, rows begun by
  another connection inside an open transaction); its hard bound (an error past it: does the request
  layer then send nothing?); times in milliseconds against the layer's `time.Time` (rounding at the
  window's edge: can rounding let a 31st click through, or one a second early?).
- **The remembered refusal:** only `remember` rows; the newest; the boundary; the chat keyed by kind and
  id; the kind's word mapping (send and reply are one kind).
- **The text:** every statement that sets a state: does it clear or keep the text as the brief's section
  5 says? Any door, error text, log line, `%v` or test output that can carry a text, a name or an id from
  a row. The 7-day rule: by which time, and does it run only at a start (a program that runs for weeks)?
  After a row's text is cleared, is it gone from the file's free pages (`secure_delete`, the WAL) or only
  from the row: say what the catalogue's settings are, as a fact, not a demand.
- **The schema step:** applied on a file at the step before; refused at any other; a file older or newer
  opened read-only (the viewer and the pages open the catalogue read-only: do they still open, and what
  do they see?); `SchemaVersion` and the three changed lines of `catalog.go` against the pattern the
  other steps follow; what the integrator must change when the number becomes 22 (two constants only?).
  Foreign keys and what a deleted chat, account or message does to the rows.
- **The adapter:** every `ActOutcome` kind mapped to a state (list them all; any that falls through to a
  default?); `ErrClickSpent` exactly for "not queued"; `ErrNotFound` for a missing row and what the Actor
  does with it; `Sent`'s chat and kind mapping back; the clock it is given.
- **Rule 13, fail closed:** a row with a state word or kind word the code does not know, a NULL where a
  value must be: does every reader stop with an error, or can it read as "nothing queued", "nothing sent",
  "no refusal"?
- **The tests:** for each of the four guarantees above, would its test still pass with the guarantee
  broken in a way the coder's two overlay checks did not try? Tests that make rows by hand in a way the
  doors never would.
- **The viewer's wall:** does anything in `internal/catalog` now import `internal/telegram` or anything
  that does (directly or through a test helper)?

## How to work

- **Prove what you can without editing the tree:** probe tests in a scratch folder
  `C:\Users\trabi\Claude\Projects\Telegram\wt-core-ledger-review-scratch`, loaded with `go test -overlay`
  (an overlay JSON that adds your `_test.go` files into `internal/catalog` or `internal/tgstore`), each
  finding marked CONFIRMED (a probe shows it; keep the probe and its output) or PLAUSIBLE (by reading; say
  what would show it). No finding without the file and line.
- Go is not on PATH: in Git Bash, `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`,
  then `cd /c/Users/trabi/Claude/Projects/Telegram/wt-core-ledger/archiver`; prefix go commands with
  `GOGC=25 GOMAXPROCS=2`. Before each go command read free memory
  (`powershell -NoProfile -Command "[int]((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1024)"`)
  and wait if it is under 2,500 MB. Named tests only (`-run`), the two packages only. No whole-package
  run (the catalogue's takes minutes), no race detector, no Docker. Nothing contacts Telegram or the
  network. Anything over 2 minutes in the background.
- Invented data only. Any file with a Windows path in it is written with a file tool, never from inside
  an inline script string. No path of this PC inside the report's findings (it goes into pushed
  documents): name files relative to `archiver/`.

## The report (`REVIEW-K9a-ledger.md`)

First line: MAY BE LISTED, MAY BE LISTED AFTER THE MUST-FIXES, or NOT AS IT IS. Then the findings, the
most serious first, each with: a number, MUST FIX / SHOULD FIX / MINOR, CONFIRMED or PLAUSIBLE, file and
line, what happens to the owner in one sentence, the probe's name and output where there is one, and the
smallest fix you would accept. Then: what you checked and found sound (so that it is not checked again),
what you could not check, and each place where the brief or the design is wrong or silent. Your final
message to me: the first line, the count by class, and the three findings that matter most.
