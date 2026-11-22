# Independent review of K8, the client's request layer (Core, K-3, 2026-11-15 23:10)

For one reviewer who has not seen the work. Read-only on the tree: you change no file of the copy and
commit nothing. Your one product is the file `C:\Users\trabi\Claude\Projects\Telegram\REVIEW-K8-requests.md`.

## What is reviewed

Branch `wip/core-act` at 79debb9f, copy `C:\Users\trabi\Claude\Projects\Telegram\wt-core-act` (Go module in
its `archiver` folder), against its base 4daa0309: `git diff 4daa0309 79debb9f`. Seven files:
`internal/telegram/act.go` (new, the whole piece), `call.go` (a new method `report` and its errors),
`memo.go`, `counters.go`, two test files, the coder's report `docs/progress/core-act-REPORT.md`.

It is the layer through which the owner's clicks in the app will WRITE to Telegram on a real account:
send a text, reply, forward, edit, delete, react, mark as read. A defect here can post something twice, post
after the owner was told it was not sent, ignore a wait Telegram stated, or go on writing after Telegram
told the account to stop. That is what you are looking for. Style is not.

## Read first

1. `C:\Users\trabi\Claude\Projects\Telegram\DESIGN-CORE-client-actions.md` (what the owner agreed to).
2. `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-K8-client-requests.md` (the rules R1 to R12 the coder was
   given). The brief may itself be wrong: say so where it is.
3. In the copy: `archiver/docs/TRIED-BEFORE.md` sections 24 and 25 (thirteen rules for anything that acts
   for the owner) and `archiver/docs/TELEGRAM-FACTS.md` section 11 (what forwarding did for real).
4. The code under review in full, and what it stands on: `internal/telegram/call.go` (`once`, `held`,
   `stated`, `takeWait`), `forward.go` (`terminal`, `answered`, `flush`, `ForwardBatch`), `memo.go`,
   `errors.go` (`classify`, `refused`, `definite`), and the library's generated request types in the module
   cache for every request the piece builds.
5. The coder's report last, and with suspicion: its claims are to be checked, not trusted.

## What to try to break (questions, not conclusions)

- Is there any path on which more than one request leaves for one call, or one ledger click? Any path on
  which a request leaves before the ledger's `Begin` returned nil, or after it returned an error?
- After `Begin` succeeded, is there any path that returns without calling `End`, or calls it twice, or
  records an outcome that says more than is known (for example "done" or "not carried out" when the
  request may have been carried out)? Go through every class `classify` can return, one by one, and every
  shape of a successful answer (including ones that name no message, name another random id, or are a
  type the code does not expect).
- `report` differs from `once` in which answers it takes as a definite refusal. List every class of answer
  where the two differ and say for each whether the difference can turn "not known" into "refused" (a
  refusal tells the owner it is safe to send again).
- A wait: is it in memory and in the record before the call returns, on every path, also when the
  caller's context ended? Can a second click, or the mirror's forward, send inside a stated wait: between
  the check and the request, across two Actors of one account, after a restart (a fresh Actor on the same
  stores)? What does the check number passed with `withCheck` guard, and does `report` use it rightly,
  given that it makes two checks (the kind's and the chat's)? Slow mode: can it ever hold another chat, or
  fail to hold its own?
- The account's refusal (`PEER_FLOOD`, `USER_RESTRICTED`): on each of the six kinds, does it reach the
  shared record so that the mirror's four calls stop, and the other way round? With a store that cannot
  save? When the answer comes wrapped as each of the error types `report` returns?
- Frozen: the callback, its error, the answer `FROZEN_METHOD_INVALID` remembered (also when the record
  cannot be saved: does it then fail closed or ask again?).
- The cap and the read mark's bound: off-by-one at the window's edges, two clicks at one instant, a clock
  that steps back, a ledger that returns clicks out of order or from the future, `CapOff`, settings of 0
  or below. Can a caller get past the cap by using several Actors, or a fresh one?
- The remembered refusal of a chat: which outcomes are remembered that should not be (a wait, frozen,
  signed out, unknown, the account's refusal) and the reverse; what `TryAgain` can and cannot override.
- The requests themselves: decode what the fake received for each kind and compare every field and flag
  with the library's type: anything set that the owner did not click (silent, scheduled, protected, paid,
  a link preview choice, entities, "invert media", a quick-reply shortcut, an effect)? The right method by
  chat kind for delete and read mark? `Revoke` as asked? A reply in a forum topic? A reaction that is not
  one plain emoji? A text at the limit, counted in runes and in UTF-16 units, with a surrogate pair at the
  edge?
- Privacy: any path on which a text, a title, a name, a link, or a Telegram id (chat, user, message,
  random id, access hash) reaches a log line, an error's text, a counter's name, or a `%v` of a request or
  an answer. Check the error types' `Error()` texts and everything `logf` is given.
- "Sent before" (`RANDOM_ID_DUPLICATE`): for a forward of several messages a first attempt can have been
  carried out in part (64 of 99 on record). What does the outcome say then, and is that true?
- The tests: for each rule, would the test still pass with the rule broken in a way the coder's own
  mutation did not try? Tests that judge on the Actor's own counters instead of the fake's count of
  requests; tests whose fake ledger is kinder than a real table (always in order, never failing, no
  concurrency).
- Anything the piece changes for code that already ran for real: `once`, `call`, `held`, the mirror's
  `Forwarder`, `methodWhat` and the memo's keys (does the new mapping change the key any existing kind
  reads or writes?), `Stats` (does a new field break a consumer in another package: grep the module for
  users of `telegram.Stats` and of `KindStats` by reflection).

## How to work

- **Prove what you can without editing the tree:** probe tests in a scratch folder
  `C:\Users\trabi\Claude\Projects\Telegram\wt-core-act-review-scratch`, loaded with `go test -overlay`
  (an overlay JSON that adds your `_test.go` files into `internal/telegram`), each finding marked
  CONFIRMED (a probe shows it; keep the probe and its output) or PLAUSIBLE (by reading; say what would
  show it). No finding without the file and line.
- Go is not on PATH: in Git Bash, `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`,
  then `cd /c/Users/trabi/Claude/Projects/Telegram/wt-core-act/archiver`; prefix go commands with
  `GOGC=25 GOMAXPROCS=2`. Before each go command read free memory
  (`powershell -NoProfile -Command "[int]((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1024)"`)
  and wait if it is under 2,500 MB. Named tests only (`-run`), package `./internal/telegram/` only. No
  whole-package run, no race detector, no Docker, no other package's tests. Nothing may contact Telegram:
  the package's fakes only. Anything over 2 minutes in the background.
- Invented data only. Any file with a Windows path in it is written with a file tool, never from inside
  an inline script string.

## The report (`REVIEW-K8-requests.md`)

First line: MAY BE LISTED, MAY BE LISTED AFTER THE MUST-FIXES, or NOT AS IT IS. Then the findings, the
most serious first, each with: a number, MUST FIX / SHOULD FIX / MINOR, CONFIRMED or PLAUSIBLE, file and
line, what happens to the owner in one sentence, the probe's name and output where there is one, and the
smallest fix you would accept. Then: what you checked and found sound (so that it is not checked again),
what you could not check, and each place where the brief or the design is wrong or silent. Your final
message to me: the first line, the count by class, and the three findings that matter most.
