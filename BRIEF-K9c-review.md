# Independent review of K9c, a "not known" click settled from what the chat shows (Core, K-3, 2026-11-16 02:33)

For one reviewer who has not seen the work. Read-only on the tree: you change no file of the copy and
commit nothing. Your one product is the file `C:\Users\trabi\Claude\Projects\Telegram\REVIEW-K9c-settle.md`.

## What is reviewed

Branch `wip/core-settle` at cee2e466, copy `C:\Users\trabi\Claude\Projects\Telegram\wt-core-settle` (Go
module in its `archiver` folder), against the head it sits on, 82d67475: `git diff 82d67475 cee2e466`.
Nine files: `internal/catalog/act_settle.go` (new: the match and three doors), its test, 25 lines in
`internal/catalog/schema_act.go`, `internal/collector/click.go` (+148) and `click_api.go` (+19), a new
`click_settle_test.go`, small changes to two older test files, the coder's report
`docs/progress/core-settle-REPORT.md`.

The app lets its owner send, reply, forward, edit and delete in Telegram chats. When the answer to such
a request is lost, the click's row says "not known": it may or may not have been carried out. This piece
looks in the app's OWN catalogue (what the live monitor stored of the chat) and, when it finds the
message, marks the click "arrived" BY ITSELF, and it stops a "send again" before it goes out when the
first try is found. It must send nothing at all. **The cost of a wrong "arrived" is real: the owner is
told a message was delivered that was not, and does not send it again. The cost of a wrong "the earlier
try is in the chat" is the same.** A wrong "still not known" costs only a click of the owner's. So the
piece must settle only on a match that is exact and alone, and leave everything else to the owner. That
is what you are looking for. Style is not.

## Read first

1. `C:\Users\trabi\Claude\Projects\Telegram\DESIGN-CORE-client-actions.md`, section 5 (what the owner
   agreed to).
2. `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-K9c-click-settle.md` (what the coder was given; it may
   itself be wrong: say so where it is).
3. In the copy: `archiver/docs/TELEGRAM-FACTS.md` section 11 (what a lost answer did for real: a batch
   of 99 forwards, 65 arrived, 34 not), `internal/catalog/schema_act.go` (the ledger: states, the chain
   of repeats, the doors; reviewed twice: not yours, but this piece's ground), how the live monitor's
   messages reach the catalogue (`internal/tgstore`, the `message` table and `message_version`), the
   mirror's own settle and its source keys (`internal/mirror`, and the catalogue doors it uses).
4. The code under review in full; the coder's report last, and with suspicion.

## What to try to break (questions, not conclusions)

- **A wrong "arrived".** Build, on catalogue rows written the way the real writers write them, every
  case you can think of in which the click was NOT carried out and the app still says "arrived": the
  owner typed the same text on the phone a minute earlier or later (the account's own message, same
  chat, same text, in the window); the same text sent twice by two clicks, one lost and one done (does
  the done one's message get taken for the lost one: is a message already tied to another click
  excluded in every path, also when that other click's row has no id on record, or was cleared, or
  belongs to a chain); a reply target or topic that differs; a message edited to that text; a message
  from before the click that the monitor only stored later (its date against the window; whose clock is
  the window on: Telegram's date against this PC's time of the mark: a PC clock 2 minutes off); a
  message in another chat of the same number space; two accounts in one chat (the other account's own
  message); a deleted message; a forward whose origin names the same source post but was forwarded by
  the owner by hand, or by the app's mirror, or earlier by another click; an album; an edit that the
  owner also made on the phone; a delete that someone else (an admin) made; a broadcast channel.
- **Exact and alone:** go through `judgeSettle` branch by branch. Is there any combination of entries
  (tied, duplicate, in or out of the window, "cannot tell whose", another click waiting) for which it
  answers arrive when one of its messages has more than one candidate, or none? For a forward of several
  messages: all of them, or does one found message settle the row?
- **The content check on other clicks** (`settleOthers`): which other clicks block the app's verdict and
  which do not; can a blocking click be missed (another state, a chain, a cleared text, a different
  kind with the same effect: a reply and a send)? The coder says it is more conservative than the brief
  (a click the owner "left" blocks): is anything LESS conservative than the brief?
- **The statements that write** (`act_settle.go`: the three UPDATEs): each names the state it leaves and
  the chain's tip? The judgement is made first and the row moved afterwards: what can change in between
  (a second identical message stored, another click queued, the owner's verdict, a "send again") and can
  the app then settle on a match that is no longer alone? One transaction or not? What does a failure
  halfway leave (a row "arrived" with its forward's messages untied, or the reverse)?
- **The repeat stopped before it goes out** (`SettleRepeat`, `clickRepeatFound` in `oneClick`): can it
  stop a repeat whose first try did NOT arrive (the same questions as for "arrived"); what if the check
  itself fails (the coder says the repeat then ends "not sent": is that the safe side, and is it said to
  the owner truthfully); can the repeat still go out through another path (a second session, the row
  taken between the check and `Begin`)? `SendClickAgain` now refuses a repeat of such a row: any state
  from which the owner can no longer finish a click?
- **It sends nothing:** grep the difference and what it calls for any path to a Telegram request (the
  reader, the forwarder, the Actor, a connection). Count requests at the fake in the collector's tests.
- **The collector's side:** when the settle runs (every loop round while a "not known" click is younger
  than 10 minutes; once a minute up to 24 hours; at a session's first step): its cost on a large
  catalogue (the statements and their indexes: any scan of the `message` table without an index on the
  chat and date?), whether it can delay a queued click or the reader, whether a failing settle is said
  once and counted and never stops clicks; the hourly counts; the log lines (constant formats, no text,
  no chat or message number).
- **The text:** compared byte for byte as stored; the report says Telegram's own changes to a text
  (trimmed spaces) make no match: is there any normalisation on EITHER side in the code (the ledger's
  queue door, the request layer's text checks, the monitor's store) that could make two different texts
  equal, or cut both the same way? Is the click's text still in the row when the settle needs it (it is
  cleared in some states and after 7 days)?
- **The four older tests the coder changed** (it turned the settle off in four K9b tests and made one
  wait for the chat list): is each change a test's own need, or does it hide something this piece
  broke?
- **Privacy:** any text, name or id from a row or a message in a log line, an error's text or a count.

## How to work

- **Prove what you can without editing the tree:** probe tests in a scratch folder
  `C:\Users\trabi\Claude\Projects\Telegram\wt-core-settle-review-scratch`, loaded with `go test -overlay`
  (your `_test.go` files added into `internal/catalog` or `internal/collector`), each finding marked
  CONFIRMED (a probe shows it; keep the probe and its output) or PLAUSIBLE (by reading; say what would
  show it). No finding without the file and line (relative to `archiver/`).
- Go is not on PATH: in Git Bash, `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`,
  then `cd /c/Users/trabi/Claude/Projects/Telegram/wt-core-settle/archiver`; prefix go commands with
  `GOGC=25 GOMAXPROCS=2`. **The PC is very busy tonight (a long test run and a race-detector container
  in another copy): before EVERY go command read free memory
  (`powershell -NoProfile -Command "[int]((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1024)"`)
  and wait 3 minutes and measure again while it is under 3,000 MB; never two go commands at once.**
  Named tests only (`-run`); most of your probes belong in `internal/catalog` (it compiles fast); batch
  the collector's into one or two runs. No whole-package run, no race detector, no Docker. Nothing
  contacts Telegram or the network; never start the collector. Anything over 2 minutes in the background.
- Invented data only. Any file with a Windows path in it is written with a file tool, never from inside
  an inline script string. No path of this PC inside the report's findings.

## The report (`REVIEW-K9c-settle.md`)

First line: MAY BE LISTED, MAY BE LISTED AFTER THE MUST-FIXES, or NOT AS IT IS. Then the findings, the
most serious first, each with: a number, MUST FIX / SHOULD FIX / MINOR, CONFIRMED or PLAUSIBLE, file and
line, what happens to the owner in one sentence, the probe's name and output where there is one, and the
smallest fix you would accept. Then: what you checked and found sound (so that it is not checked again),
what you could not check, and each place where the brief or the design is wrong or silent. Your final
message to me: the first line, the count by class, and the three findings that matter most.
