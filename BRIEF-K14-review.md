# Independent review of K14, what the door guarantees to the page (Core, K-4, 2026-11-16)

For one reviewer who has not seen the work. Read-only on the tree: you change no file of the copy and
commit nothing. Your one product is the file `C:\Users\trabi\Claude\Projects\Telegram\REVIEW-K14-door.md`.

## What is reviewed

Branch `wip/core-door` at 44519537, copy `C:\Users\trabi\Claude\Projects\Telegram\wt-core-door` (Go module
in its `archiver` folder), against the head it was cut from, d6415255: `git diff d6415255 44519537`.

The app lets its owner send, reply, forward, edit, delete, react and mark as read in Telegram chats from a
page. A click travels page, viewer, pass-through, the collector's routes, then the entry points in
`internal/collector/click_api.go`, which write it into a ledger (`c_act`); the account's reader loop sends
it as ONE request. This piece changes the entry points and what stands behind them: a key per click so that
a repeated call cannot queue a second click (a new table, schema step 24), the queue's write on a context of
its own, one state call the page polls every few seconds, the caption's limit, targets judged at the queue,
a bound on the queue. **What a mistake costs here is real and outside the PC: a message of the owner's sent
twice to other people, a message the owner believes sent that never goes out, a text dropped in silence, or
requests to Telegram that nobody asked for (the account is the thing protected).** That is what you are
looking for. Style is not.

## Read first

1. `C:\Users\trabi\Claude\Projects\Telegram\DESIGN-CORE-client-actions.md` (what the owner agreed to).
2. `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-K14-door-guarantees.md` (what the coder was given; each part
   says what its rule is FOR; the brief may itself be wrong: say so where it is. Five sentences of earlier
   briefs of this track were wrong and only the reviews found them).
3. `C:\Users\trabi\Claude\Projects\Telegram\SEAM-B5-viewer-act.md` (what the page's side assumes of the door).
4. In the copy: `archiver/docs/TRIED-BEFORE.md` sections 24 and 25 (thirteen rules for anything that acts for
   the owner), `internal/catalog/schema_act.go` (the ledger: reviewed before, this piece's ground),
   `C:\Users\trabi\Claude\Projects\Telegram\REVIEW-K9b-turn.md` findings 1 and N1 (a click must never cut the
   reader's own pause before a retry nor reset its back-off).
5. The code under review in full; the coder's report (`archiver/docs/progress/core-door-REPORT.md`) last,
   and with suspicion.

## What to try to break (questions, not conclusions)

- **Two clicks from one.** Every way one key can end as two rows of `c_act`, or one row sent twice: two calls
  at once; a call whose context ends at each point of the write (before, inside the transaction, at the
  commit, after it); the write failing and the key read again; a restart between; the sweep that deletes
  old keys running between two calls; a key whose click was "sent again" by the owner; the same key for two
  accounts; a key row whose click row is gone. Is the lookup inside the same write transaction as the
  insert? Is the transaction the catalogue's one writer in every path (also a read-only handle, also the
  `tx` variants)?
- **One click from two (a text dropped).** Every way a key that comes with ANOTHER content is answered as
  the old click: go through the digest field by field: can two different clicks have the same encoding
  (field boundaries, an empty text against no text, a list of ids against a target, a topic 0 against none,
  the order of messages, the kinds)? Is anything the request depends on NOT in the digest (so that two
  contents count as one)? Is anything in it that changes between two honest tries of the same click (so that
  an honest retry is refused: the time of the click, a random id, the session)? What does the page get then,
  and is it true?
- **An answer that is not so.** For `QueueClick` and `SendClickAgain`: any path that answers an error with a
  click queued (it will be sent), or a number with nothing queued (never sent, the page shows it as on its
  way). `queuedFor` (the session began to end): what is answered, and what state is the row in, with and
  without a key, and what does the SAME key answer a second later? The other three calls (cancel, verdict,
  not arrived): can a cut-off call change the row and report an error, and does the page's next read then
  show the truth?
- **The state call makes requests, or waits for one.** Count config requests at the fake: 100 state calls,
  a failed ask and polls after it, two accounts, a session that ends and a new one, a state call for an
  account whose session is not running, clicks and state calls mixed. Any path from a poll to ANY other
  request? Does the call wait on a lock a request in flight holds (the request layer's door, the reader's
  pass, the catalogue's writer during a long write)? Start a slow request at the fake and time the call. Is
  anything read across goroutines without its lock (run your probes of this under `-race` by name only if
  the PC allows: see below)?
- **The nudge and the reader.** How does "limits wanted" reach the reader: through the click's wake or not?
  If through it: can a poll cut a wait Telegram stated for a history read, the reader's own pause before a
  retry, or reset its back-off (K9b's two findings, again with polls instead of clicks: count history
  requests at the fake with and without polls over the same simulated time)? Can the automatic mirror's
  turn be delayed by polls? If not through it: how long can the limits stay unknown, and what does the page
  do meanwhile?
- **What the state says against what the turn does.** For each word and number of the state: can the state
  say "can write" while every click is refused at the turn (frozen, the account's refusal, a wait, the cap,
  a mirror chat), or "cannot" while clicks go out? The cap's opening: is it truly one arithmetic for both
  (`capped` and the state), also for clicks dated ahead of the clock, the cap off, the read mark's bound? A
  wait per kind: read from where, and can a wait that has ended still be told (or a running one not)?
- **The limits.** The caption's limit: which messages count as "with media" by the catalogue's rows (a web
  page preview, a poll, a location, a message whose media row is missing), and what happens on each side of
  a wrong answer (a request Telegram refuses, or an honest edit refused at the queue with no way round)? A
  config answer without the caption field; limits known in one session and not in the next. A text refused
  at the queue: by exactly the same count as the request layer (`textFits`), or can the queue refuse what
  the layer would send?
- **Targets.** A reaction's target and a reply's target not held or marked deleted: refused in every path
  (also "send again" of an old click whose target was deleted since: what should happen, and what does)? A
  forum reply with topic 0; a reply to a message of another chat; an id that is a service message.
- **The bound.** 50 queued: counted inside the write transaction? Can clicks pile up in another state that
  is still sent later? Does a known key really answer before the bound? Does the bound hold across accounts
  separately?
- **The schema step.** Applied only on the step before it; `IF NOT EXISTS`; a catalogue at the older step
  opened read-only by the viewer or the pages (the readers of `c_act`): any reader that now fails or reads
  the new table without checking the step? `SchemaVersion` and the two constants as the report says the
  integrator must set them.
- **It sends nothing new:** grep the difference for any path to a Telegram request other than the one
  `help.getConfig`. **Privacy:** any text, name, id, key or digest in a log line, an error's text, a count,
  the status file.
- **The tests the coder changed or removed:** count test functions before and after (`git diff` on
  `_test.go`); is each change a test's own need, or does it hide something this piece broke? Does any new
  test judge on real time?

## From the hand-back and my own read (added at the hand-back; judge each)

The coder names seven departures from the brief in its report: judge each one, not only the code. Points I
want an answer on, each with a probe where one is possible:

- **A poll and the reader's loop.** While the limits are not known, EVERY state call ends in
  `s.wakeForClick()` (once a session, and once more per failed minute) or `s.nudgeReader()` (every other
  call; `click_state.go`, the end of `ClickState`). A page polls every 3 s per open chat. Count at the fake
  EVERY request of every kind over 10 simulated minutes with a poll every 3 s against the same time without
  polls, in three states in which the limits stay unknown: the config ask failing each time; a frozen
  account; an account with its refusal on record (the last two ask nothing by `wantedLimits`, so the flag
  stays set for the whole session: what do 200 nudges do to the reader's loop then: extra history requests,
  extra catalogue writes, the automatic mirror's turn delayed or brought forward, a stated wait cut more
  than once)? The coder's evidence for the wake is two fakes' counts (5 against 5, 11 against 11): try to
  find a schedule where they differ.
- **A known key is answered before every other check** (also with the session ended or the clicks off;
  departure 6). Is there a state of the earlier click for which answering its number misleads the page into
  showing a message as on its way that will never go (a click "not sent" because its session was ending when
  it was queued: `queuedFor` answered the FIRST call with an error, and the same key then answers a number)?
  What does the page read at that number, and can the owner still get the message sent (send again, or a new
  key)? Is a keyed call for a chat that is not the account's answered in words the seam knows?
- **`TextFits(text, 0)` now means "no length limit"** (`telegram/act.go`). Find every caller: can a limit of 0
  that means "not known" anywhere reach it and let a too-long text through to a request (the request layer's
  `limited` must still refuse with "limits not known")?
- **The 60 s hold after a failed limits ask now also holds a click's own ask** (departure 3): a click in that
  minute ends "not sent: limits not known" without a request. Is that told to the page truthfully, and can a
  failing ask and the hold together keep every text click from ever going while Telegram is in fact
  answering (the hold's start moved by each poll, or never cleared)?
- **`queuedFor` on the write's own context**, and the key read after a failed write: `clickWriteFault` and
  `clickBeforeWrite` are test hooks in the collector's config: can either be set outside a test?
- **Four older tests were adapted** (`TestActSendAgainTwoAtOnce`, `TestClickAccountRefused`,
  `TestClickQueueNoSpin`, `TestClickQueueRaceAtSessionEnd`; the last queues 0 clicks on this PC by the
  coder's own word, also on the base tree: it proves nothing): is each change the test's own need? Write
  the probe `TestClickQueueRaceAtSessionEnd` was meant to be, if you can make the race happen on the fake.

## How to work

- **Prove what you can without editing the tree:** probe tests in a scratch folder
  `C:\Users\trabi\Claude\Projects\Telegram\wt-core-door-review-scratch`, loaded with `go test -overlay` (your
  `_test.go` files added into the package), each finding marked CONFIRMED (a probe shows it; keep the probe
  and its output) or PLAUSIBLE (by reading; say what would show it). No finding without the file and line
  (relative to `archiver/`).
- Go is not on PATH: in Git Bash, `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`,
  then `cd /c/Users/trabi/Claude/Projects/Telegram/wt-core-door/archiver`; prefix go commands with
  `GOGC=25 GOMAXPROCS=2`. Before EVERY go command read free memory
  (`powershell -NoProfile -Command "[int]((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1024)"`)
  and wait 3 minutes and measure again while it is under 3,000 MB; never two go commands at once. Named
  tests only (`-run`); most probes belong in `internal/catalog` (it compiles fast); batch the collector's
  into one or two runs. No whole-package run, no Docker. The race detector only on your own named probes of
  the state call, and only if free memory is over 5,000 MB. Nothing contacts Telegram or the network; never
  start the collector. Anything over 2 minutes in the background.
- Invented data only. Any file with a Windows path in it is written with a file tool, never from inside an
  inline script string. No path of this PC inside the report's findings.

## The report (`REVIEW-K14-door.md`)

First line: MAY BE LISTED, MAY BE LISTED AFTER THE MUST-FIXES, or NOT AS IT IS. Then the findings, the most
serious first, each with: a number, MUST FIX / SHOULD FIX / MINOR, CONFIRMED or PLAUSIBLE, file and line, what
happens to the owner in one sentence, the probe's name and output where there is one, and the smallest fix
you would accept. Then: what you checked and found sound (so that it is not checked again), what you could
not check, and each place where the brief or the design is wrong or silent. Your final message to me: the
first line, the count by class, and the three findings that matter most.
