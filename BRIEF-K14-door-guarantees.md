# Brief K14: what the door guarantees to the page (Core, session K-4, 2026-11-16)

**Rules of the house, first (the project folder's `CLAUDE.md`, the archiver section):** you are the Opus coder
of this piece; you code and hand back commit-ready work. Named tests only while you work (`-run`, one small
package); no whole run of `internal/catalog` or `internal/collector`, no `go vet` over many packages, no race
detector: the full runs happen once, after the independent review, by a Sonnet clerk. Privacy: invented data
only in tests; nothing of a text, a name, a link, a Telegram id or the page's key in any log line, error text,
status file or count; new log lines are constant format strings. Never start, stop or touch the running
programs; nothing of this piece talks to Telegram (tests use the collector's fake, `internal/collector/faketg`).
Before every `go` command: `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh` if it
exists, and keep the compile small (`GOGC=25 GOMAXPROCS=2`; `-p 1`).

**Where:** the copy `C:\Users\trabi\Claude\Projects\Telegram\wt-core-door`, branch `wip/core-door`, cut from
`wip/core-settle` d6415255 (K9c: listed, not merged yet). Commit as you go
(`git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, the message ending with
`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`) and push the branch to the remote `private` after
each finished part (`git push private wip/core-door`). Never push or merge any other branch.

## 0. What this is for

The owner uses the app like a Telegram client. A click on the viewer's page goes: page, the viewer's server,
a pass-through, the collector's routes (the pages track's), then the entry points in
`internal/collector/click_api.go`, which write the click into the ledger (`c_act`, `catalog/schema_act.go`);
the account's reader loop takes it up and sends ONE request (`collector/click.go`, `telegram/act.go`). All of
that is built (K8, K9a, K9b, K9c). The viewer's two independent reviews found what the entry points do not
guarantee yet (board messages 93 and 95; the seam `SEAM-B5-viewer-act.md` in the project folder). This piece
closes those. **The rule over all of it: one click of the owner's is at most one request to Telegram, and the
page is never told something that is not so.** Each part below says what its rule is FOR: if you find a case
where the words of this brief would break that purpose, the purpose wins: stop and say so in the hand-back.

**What the old app already knows (read by me; `DESIGN-CORE-client-actions.md` section 1):** it has nothing that
sends a text, edits, deletes one message, reacts or marks as read, so there is no number of its to put beside
ours. Its one writing path (the "auto-forward" re-upload) makes a NEW random id at every try and looks nowhere
first: a lost answer posts a second copy. That is the failure part 1 exists to prevent. The rules for anything
that acts for the owner (`archiver/docs/TRIED-BEFORE.md` sections 24 and 25; read them, 66 lines): one row per
item and one writer (11), fail closed: a stored value that cannot be read is never "empty" (13), waits checked
at the top of every step (4), no request for an item that will never be acted on (9), a cap per step (10).

**Read before you write:** `DESIGN-CORE-client-actions.md`; `SEAM-B5-viewer-act.md`; `click_api.go` whole;
`catalog/schema_act.go` lines 1 to 135 and 334 to 700; `collector/click.go` (`clickStep`, `clickActor`,
`clickLimits`, `wakeForClick`, `readerClock`); `telegram/act.go` (`Do`, `limited`, `capped`, `Limits`);
`REVIEW-K9b-turn.md` findings 1 and N1 (a click must never cut the reader's own pause before a retry nor reset
its back-off: part 3 touches the same wake).

## 1. The page's key: the same click is never queued twice

**For:** an answer lost between the ledger's commit and the page (a cut-off call, a viewer restarted, a page
reloaded with the click still in hand) must not become two messages; and a key that comes back with ANOTHER
content must not be answered as the old click (the owner's new text would be dropped in silence: the page
empties its box on that answer).

- `ClickInput` gains `Key string`: "" (no key: today's behaviour, for callers that have none), or 16 to 64
  lower-case hex digits; anything else is `ErrNotAClick`.
- **A schema step, number 24** (my decision after reading the ledger: `c_act` has no free column, and the
  text is cleared once a click is done, so "the same content" cannot be judged later without a stored
  digest). A NEW table, `c_act` itself untouched (the viewer reads `c_act` through `catalog.Click`; nothing of
  its scan changes): one row per key: the account, the key, the click's ref, a digest of the click's form,
  when it was made; the primary key is (account, key). Name and file: `schema_actkey.go`, written exactly as
  `schema_mirrorwant.go` and `schema_act.go` register theirs (`...After`, `...Schema = After + 1`, the map and
  the switch in `catalog.go`, `SchemaVersion`); its `After` is the newest step on this branch (23,
  `mirrorWantSchema`). The step's statements are `IF NOT EXISTS`. Say in the hand-back every line the
  integrator must set at the merge (the number is given at the merge; today the next free one is 24).
- **The digest ("form")**: SHA-256 over a canonical, unambiguous encoding (length-prefixed fields, fixed
  order) of: account, the chat (kind, id), kind, reply-to, topic, target, the source chat, every message id in
  order, emoji, revoke, try-again, the text. Stored as 32 bytes. Never logged, never in an error.
- **`catalog.QueueClick`, inside its one write transaction:** with a key: look the key up. Found with the
  same form: return that row's ref and write nothing (answer `again = true` to the caller, so that the
  collector neither counts `click.queued` again nor needs a second wake; a second wake is harmless).
  Found with another form: a new fixed error (`ErrActKey`), nothing written. Not found: insert the click and
  the key row together. Two calls at once with one key must give one click (the catalogue has one writer
  and the primary key; show it with a test that runs them together).
- The earlier click may be in ANY state (queued, done, not sent, refused, sent again by the owner): the key
  still answers its ref, never a new click. The page reads the row and its chain's tip itself.
- A click refused at the queue (any "no" before the write) records no key: the same key may come again and
  is judged afresh.
- The collector maps `ErrActKey` to a new fixed word of its own, `ErrClickKey` ("this key belongs to another
  click").
- Random ids stay as they are (`telegram.NewRandomID`, made once per click, kept in the row): with one row
  per key nothing more is needed. Do NOT derive them from the key.
- Key rows older than 30 days are deleted by the start's sweep (`SweepClicksAtStart`), one statement, its
  count added to the sweep's result and the start line. Nowhere else.
- A key table that cannot be read (a digest of the wrong length, a ref with no row) is `ErrBadActLedger`:
  nothing is queued (fail closed).

## 2. The queue's write finishes by itself

**For:** today `Collector.QueueClick` and `SendClickAgain` run on the caller's context from the first check to
the wake. A call cut off after the commit can answer an error while the click is queued and will be sent: the
page then shows "failed" for a message that goes out.

- The checks before the write stay on the caller's context: cancelled there, nothing is written.
- From the write on (the ledger's write, `queuedFor`, the wake) the work runs on a context that the caller's
  cancel does not end, with a bound of its own (10 s; a constant), and its result is the answer even if the
  caller has gone.
- When the write itself returns an error and a key was given: read the key once more on a short context of
  its own. Found: the click IS queued: answer its ref (and wake). Not found: the error, and nothing is
  queued. Without a key the write's error is the answer.
- The same for `SendClickAgain` (it makes a click too); it has no key: its guard stays the compare-and-set
  on the chain's tip. `CancelClick`, `ClickVerdict`, `ClickNotArrived`: one statement each, compare-and-set;
  run each on the same kind of context so that a statement never ends half-reported; nothing else changes.

## 3. One cheap state call

**For:** the page asks "can this account write here now, and what are the limits" for every open chat about
every 3 seconds, one account after another, inside one 20 s deadline. The answer must come from memory and
the catalogue, in well under a second, and **a poll must never become a request to Telegram**. Today no entry
point gives it, and the text limit is asked only at the first click that needs it, so a page that waits for
the limit before it lets a text go would wait for ever.

- A new entry point on the Collector, `ClickState(ctx, account, chat)` (chat 0: the account's part only),
  answering a struct of closed words and numbers, nothing of a chat's name or text:
  - whether the account can write now and, if not, ONE word of: not running (the collector or the account's
    session), not signed in, clicks off (the start's sweep failed), frozen, writes stopped (the account's
    refusal on record, the mirror's too), setting (a clicks' setting cannot be read);
  - for a chat: mirror (one of the app's own mirror chats), not found (not a chat of the account); and the
    end of the chat's slow mode where one is on record;
  - the end of a wait Telegram stated, per kind (six kinds), where one runs;
  - when the app's own cap opens again (0: open now), from the ledger's sent clicks and the cap in force,
    by the SAME arithmetic the request layer uses (`capped`): take that arithmetic out into one function both
    use; do not write it twice;
  - the server's limits as this session knows them: the text's, the caption's, the forward's (0: not known
    yet);
  - the settings: mark as read, the cap.
- It reads the catalogue and memory only. It takes no lock that a request holds (the request layer's door,
  the reader's pass): a click's request in flight must not make it wait. Where a value lives on the reader
  task's goroutine today (`clickSession`'s actor and its limits), publish what the state needs through a small
  guarded value (atomics or one mutex) written by the reader's goroutine: do not read the actor across
  goroutines without its lock, and do not make the state call create the actor.
- **The limits, when this session does not know them yet:** the state call marks "limits wanted" for the
  account and nudges the reader; the reader's clicks' step then asks them once (`clickLimits`, the same one
  counted `help.getConfig`, through the pass, bounded as now). Rules, each with a test on the fake that
  COUNTS config requests: at most one successful ask per session; after a failed ask no new one for 60 s,
  however often the page polls; no ask at all in a session where no state call and no click wanted them; the
  nudge never cuts the reader's own pause before a retry and never resets its back-off (the K9b findings: use
  the click's wake only if you can show that; otherwise let the next round of the loop take it and say how
  long that can be). 100 state calls in a row make at most that one request.
- Time it in a test at size (10,000 ledger rows of the account, 1,000 chats): the call's median and worst
  over 200 calls, printed; a bound in the test only if it cannot flake on a busy PC (the tests of this tree
  must not judge on real time: `onClock`, `clockPassed` in `click_test.go`). Say the numbers in the hand-back.

## 4. The caption's limit, and a text refused at the queue

**For:** an edit of a message with media has Telegram's caption limit, not the text limit; today a too-long
caption costs a request that Telegram refuses.

- `Actor.Limits` keeps `caption_length_max` beside the other two (the same `help.getConfig` answer; check
  the field in the library's `tg.Config`); the fake's config answers it. An answer without it: the caption
  limit is "not known" (0) and an edit of a media message is then judged by the text limit as today (do not
  fail the whole `Limits` for it).
- `catalog.ActMessage` gains whether the message carries media (from the catalogue's rows; no schema step).
  The turn hands it to the request layer (`Action` gains one flag for an edit) and `limited` judges an edit
  of a media message against the caption limit, by the same count (`textFits`).
- At the queue (`Collector.QueueClick`), when this session knows the limits: a send's or an edit's text that
  does not fit (empty, only spaces, not valid UTF-8, too long for its limit) is refused there with a fixed
  word (`ErrClickText`), nothing written. When the limits are not known yet the queue lets it through (the
  turn asks them and the request layer judges, as today) and marks "limits wanted".

## 5. Targets the catalogue does not hold, or holds as deleted

**For:** no request for something that cannot be acted on, and the page's "own, existing message" decided at
the door, not trusted from the page.

- Already so for an edit, a delete and a forward's sources (`ownMessage`, the forward's loop): add the tests
  that show it by name, one per kind, each with a message marked deleted and one the catalogue does not hold.
- New: a reaction's target and a send's reply-to must be messages the catalogue holds for that chat and not
  marked deleted (`ErrClickNoMessage`); tests as above. A read mark's target is not judged (it is "up to this
  id").

## 6. A bound on what may be queued

**For:** a fault in a page must not be able to queue thousands of clicks (a probe of K9b's review queued
1,070). Refused at the queue, inside the write's transaction: an account that has 50 clicks queued takes no
more (a constant; a new fixed word, `ErrClickQueueFull`, nothing written). A key that is already known is
answered before this bound is looked at (it queues nothing).

## 7. What is NOT in this piece

No route, no HTTP, nothing in `internal/server` or `internal/viewer` (pages and the viewer build on what you
hand back). No change to what a click's request is, to the cap's numbers, to the reader's reading, to the
settle (K9c). No new request kind; the only request this piece moves is the one `help.getConfig` of part 3.
`collector/mirror_auto.go`, `reader.go` and `catalog/schema_act.go`'s table are where tracks meet: touch them
only where a part above needs it, and list every such line in the hand-back.

## 8. Tests, and the hand-back

- Every rule above has a test that you saw FAIL before the code (say so per test). No test judges on real
  time. Tests that need a session use the collector's fake as `click_test.go` does.
- While working: the named tests of what you changed, in `internal/catalog`, `internal/collector`,
  `internal/telegram`, `internal/tgstore` (`-run` with the names; `-count=1`). `gofmt -l` on your files. Once
  at the end: `go build ./...` and `go vet` on the four packages only.
- Hand back, in `archiver/docs/progress/core-door-REPORT.md` (committed) and as your last message: the head's
  hash, pushed or not; per part what was built and where (file, function); the entry points as pages and the
  viewer need them (signatures, every fixed word and what it means, which carry a time): this text goes to
  two other tracks as it is; the schema step's lines for the merge; the named tests and their results as run
  (counts, seconds); the timing numbers of part 3; every place where you departed from this brief and why;
  what you could not test. Report numbers and words only: no text of any fixture is needed.
- Stop and hand back early, saying why, if: a part cannot be built without changing what a click's request
  is; the limits ask cannot be nudged without cutting a pause of the reader; the schema step needs a change
  to `c_act` after all.
