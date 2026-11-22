MAY BE LISTED AFTER THE MUST-FIXES

# Independent review of K14, what the door guarantees to the page (`wip/core-door` 44519537 against d6415255)

Reviewer: one independent reviewer, 2026-11-16. Read-only on the tree; nothing committed. Probes are in the
scratch folder `wt-core-door-review-scratch` and load into the packages through `go test -overlay`:
`zz_review_k14_catalog_test.go` (output `run1-catalog.txt`), `zz_review_k14_telegram_test.go` (`run2-telegram.txt`)
and `zz_review_k14_collector_test.go` (`run3-collector.txt`). Requests were counted at the fake (`CountByKind`).
Free memory was 5,550 MB or more before each go command. The race detector was not run. All data is invented.
Lines are relative to `archiver/`.

Counts: **2 MUST FIX** (both CONFIRMED by probe), **1 SHOULD FIX** (CONFIRMED by probe and by reading),
**7 MINOR** (1 measured, the rest by reading).

## Findings, most serious first

### 1. MUST FIX, CONFIRMED: an account with a keyed click can never be deleted, and its intent blocks the catalogue's settle

- **Where:** `internal/catalog/schema_actkey.go:45` (`act_id INT NOT NULL REFERENCES c_act(id)`, no ON DELETE, foreign
  keys on in the writer's DSN) with `internal/catalog/settle.go:497`. The settle's account delete removes `c_act_msg`
  and `c_act` rows but no `c_act_key` rows.
- **What happens to the owner:** once the page has queued even one click for an account (every page click carries a
  key), removing that account fails each time with `FOREIGN KEY constraint failed`. The settle runs its intents from
  the lowest id, so every later owner action stored in `c_settle` (another account's delete, re-ranks, unskips, space
  deletes) is starved too. Nothing is sent to Telegram, but a whole class of the owner's catalogue actions stops
  silently.
- **Probe `TestReviewK14DeleteAccountWithKey`** (`run1-catalog.txt`): without a key, everything is deleted and the
  settle is clean. With a key: "Settle err=catalog: settle delete account 2: constraint failed: FOREIGN KEY
  constraint failed (787); account 2 rows left=1, its clicks left=1, intents left=1". A later `DeleteAccount(1)`, for
  an account with no keyed click, then fails with the same error, "account 1 rows left=1".
- **Smallest fix:** add `DELETE FROM c_act_key WHERE account_id = ?` before the `c_act` delete in `settle.go:497`.
  This is one line in a shared file, so list it at the merge. The other way is `ON DELETE CASCADE` on `act_id`; the
  step is not merged yet, so its text can still change. Add a test: a keyed click, `DeleteAccount`, then a clean
  `Settle`.

### 2. MUST FIX, CONFIRMED (interleaving forced): `queuedFor` tells the page "not running" for a click that is already being sent

- **Where:** `internal/collector/click_api.go:439-447`, called at `:668` and `:755`. When the session's end has begun,
  `queuedFor` runs `ClickNotSent` and then returns `ErrNotRunning` whatever that call answered. If the reader took the
  click between the commit and this check (its `NextClick` and `Begin` in a step that is already running, then
  `close()` setting `ending` at `account.go:1174`), `ClickNotSent` fails with `ErrActState`. The page is still told
  "not running".
- **What happens to the owner:** the seam (`SEAM-B5-viewer-act.md`, "Two kinds of failure") treats "not running" as
  a sure refusal: nothing is queued and the viewer forgets the key. The click is in fact "sending", and its one
  request is out or about to leave. The page keeps the text, and the owner's next Send uses a new key, so **the
  message goes to the chat twice**. The window is narrow: the commit to the `ending` check, plus `preparePending` after
  the commit, a few milliseconds while the reader is mid-step. The cost is the worst one the brief names.
- **Probe `TestReviewK14QueuedForTaken`** (`run3-collector.txt`): the `clickWriteFault` hook does exactly what the
  reader and `close()` can do in that window. Result: "QueueClick answered ref=0 err=collector: not running ... while
  its row 1 is in state "sending"; the same key again: ref=1". This is the probe `TestClickQueueRaceAtSessionEnd` was
  meant to be. The natural race was not reproduced on the fake: it needs microsecond timing.
- **Smallest fix:** in `queuedFor`, answer `ErrNotRunning` only when `ClickNotSent` succeeded. When it returns
  `ErrActState` (the click left "queued"), return nil so that the caller answers the ref; the page then reads the
  row. For any other error the row stays queued, and the next session's `StopClicksBefore` stops it, so
  `ErrNotRunning` is true there. A test, with the hook as in the probe.

### 3. SHOULD FIX, CONFIRMED: a text message with a link preview counts as "with media"; an honest edit of it is refused as too long

- **Where:** `internal/catalog/schema_act.go:1349-1351` (`Media` is "an `attachment` row exists"), with
  `internal/telegram/record.go:387-393` (a web page's document, or else its photo, is recorded as an attachment).
  The flag is then used at the queue (`internal/collector/click_api.go:576`, `615-626`) and at the turn
  (`internal/collector/click.go:580-593`, `internal/telegram/act.go:953`).
- **What happens to the owner:** an edit of their own text message that shows a link preview with a picture or a
  file is held to the caption limit (1,024) instead of the text limit (4,096). An edit between 1,025 and 4,096 units is
  refused at the queue and again at the turn as "too long", with no way round, though Telegram would take it. No
  request is wasted, but the page is told something that is not so.
- **The reverse case:** a photo with a self-destruct timer has no attachment row (`record.go:226-229`), so an edit of
  its caption is judged by the text limit, and a too-long caption costs one request that Telegram refuses (the
  behaviour before this piece).
- **The report is wrong here:** its departure 7 says "a page preview ... is judged as a text message".
- **Probe `TestReviewK14WebPageCountsAsMedia`** (`run2-telegram.txt`): "a text message with a link preview's photo:
  1 attachments recorded"; "a photo with a timer and a caption: 0 attachments recorded".
- **Smallest fix:** judge "caption" by the message's media kind (photo or document; never a web page). The catalogue
  cannot tell this today (no column, and web-page attachments also have the main role). If no cheap source exists,
  judge an edit by the text limit at the queue and in `limited`, and let Telegram's `MEDIA_CAPTION_TOO_LONG` stand
  for the rare long caption. That is one counted request, and it never refuses an honest edit. The architect's choice.

### 4. MINOR, measured: while the config ask fails, an open page costs 3 config requests a minute, without end

- **Where:** `internal/collector/click_state.go:229-251` and `click.go:836-866`.
- **Measured** (`TestReviewK14PollCounts`, 10 minutes of the clock, a state call every 3 s, `help.getConfig`
  answering 500):
  - Without polls: no request of any kind.
  - With 185 polls: `config=30`. That is one ask a minute, and each ask is 3 requests because of the Forwarder's own
    retries.
  - The same with the reader inside FLOOD_WAIT 20 on history: `history=28` with and without polls. No history request
    was added.
- **Within the brief** (60 s hold), but nothing bounds it per session, and each ask is more than one request.
- **Suggested:** double the hold after each failed ask (60, 120, 240 s ... up to about 30 minutes), or stop after a
  few failed asks a session until a click asks.

### 5. MINOR, by reading: a "not sent (stopped)" row survives a "not running" answer

- **Where:** `queuedFor` (`click_api.go:439-447`).
- **What happens:** with finding 2 fixed, a click that `queuedFor` does mark "not sent" still answers `ErrNotRunning`,
  and the viewer forgets the key. Its row stays in the chat's clicks as "not sent", with a "Send again" button, beside
  the click the owner sends next under a new key. This is truthful, but an owner who presses both sends twice.
- **Suggested:** the viewer hides rows that were refused at the door, or the door answers the ref (the row says
  "not sent"). For the seam's owners.

### 6. MINOR, by reading: the state and the turn disagree in small ways

- **Where:** `click_state.go`.
- **Stricter than the turn:** a "mark as read" setting that cannot be read gives "setting" for every kind
  (`:163-171`), while sends would go.
- **Looser than the turn:**
  - When the clicks' Actor cannot be made (the forward secret cannot be read), the state says `Write` and every click
    ends "not sent". `wantedLimits` then returns before it sets `limitsFailed` (`click.go:908-913`), so the limits stay
    unknown and every poll nudges the reader for the whole session. No request is made.
  - A method refused as frozen (`memoActFrozen`) is not in the state.
  - A chat with no access hash ("not addressable") is not in the state.
- No request comes from any of these.

### 7. MINOR, by reading: "send again" does not judge its targets again

- **Where:** `click_api.go:712-760`.
- **What happens:** "send again" of an edit, a reaction or a reply whose message was deleted since sends one request,
  which Telegram refuses (rule 9). The brief is silent on this. It is the owner's explicit click, so it is minor.

### 8. MINOR, PLAUSIBLE: a service message is accepted as a reaction's or a reply's target

- **Where:** `heldMessage`, `click_api.go:396-408`.
- **What happens:** one request that Telegram probably refuses. Reading whether the catalogue keeps service messages
  as `message` rows would settle it.

### 9. MINOR, PLAUSIBLE: the keyed early path depends on the chat as it is now

- **Where:** `click_api.go:516-531`. `resolve()` runs before the key is read, and the digest uses the resolved
  Telegram chat (kind and id), not the catalogue's chat number.
- **What happens:** if the chat left `ReadableChats`, or a basic group migrated, between the first try and an honest
  retry, the retry is answered "not found" or "key" for a click that is queued. The viewer then forgets the key, and
  the owner may send again.
- **Suggested:** read the key first, by (account, key), and compare the form with the input's catalogue chat number.

### 10. MINOR: tests

- No test deletes an account with a keyed click (finding 1).
- `TestClickStateNudgeKeepsPause` allows one more history request with polls (`with > without+1`).
- `TestClickQueueRaceAtSessionEnd` proves nothing on this PC, as the coder said.
- The report's departure 7 is wrong (finding 3).

## Checked and found sound (not to be checked again)

- **One click per key in the catalogue.**
  - The key lookup, the bound and the insert run in one write transaction. `Batch`'s handle reads through the
    transaction (`tc.r`), and the writer has a single connection with `_txlock=immediate`.
  - `TestReviewK14KeyTogetherCatalog`: 32 calls at once with one key gave 1 answer as the first call, 1 `c_act` row and
    1 key row.
  - In the collector, an early-path miss in two calls is settled by the transaction: the second call gets `again`.
  - A read-only handle gets `ErrReadOnly` and writes nothing.
  - The digest: 17 forms differing in every field, field boundary, message order, empty against absent, and kind gave
    17 digests. Random id, time and key are not in it. Nothing in it changes between honest tries
    (`TestReviewK14FormDistinct`).
  - The key is answered before the bound, and the bound is per account (`TestReviewK14BoundPerAccount`). The bound is
    counted inside the transaction, in `sendClickAgain` too.
- **The write's own context.**
  - The checks run on the caller's context. `beforeWrite` is the last look.
  - The write, `queuedFor` and the wake run on `WithoutCancel` with 10 s. A write error with a key re-reads the key
    (3 s).
  - A commit that failed is rolled back by `database/sql`, so "not found" then means nothing was queued.
  - Cancel, verdict and not-arrived are one compare-and-set each, on the same kind of context. The page's next read
    shows the truth.
  - `clickWriteFault` and `clickBeforeWrite` are unexported fields of `Config`, set only in `_test.go` files.
- **`TextFits(text, 0)`.** Its only caller is `QueueClick` (`click_api.go:624`), where 0 means "not known". `limited`
  still refuses with `ErrNoLimits` when `textMax <= 0` (`act.go:948`). The queue and the layer use the same count and
  the same limit choice.
- **The state call makes no request and waits on no request.**
  - Its reads go through the catalogue's reader pool, `a.mu`, `c.mu`, the memo's and the Forwarder's short locks, and
    atomics. The Actor is never touched.
  - Measured: 50 calls while a click's request was held at the fake took a median of 517 us and at worst 1,049 us
    (`TestReviewK14StateWhileRequestOut`).
  - It does not nudge for a frozen account, a refused account or an account that is not running (`accountOK`).
    Measured: 185 polls in those states made no request.
  - `NewForwarder` and `NewActor` send nothing.
- **The nudge and the reader.**
  - A wake comes at most once a session and once per failed minute; it cuts only a stated wait outside a retry chain.
    Other polls only end the reader's idle, and `readTurn` re-runs without a request: backoffs, `waitUntil` and the
    mirror's own `writeAt`/`needAt` are kept.
  - History counts were equal with and without polls in the FLOOD_WAIT schedule (28 and 28), as were the coder's
    counts.
  - A wake can delay the automatic mirror's turn by one round (`readTurn`, `clickPending`); it never brings it forward.
- **The cap's arithmetic.** It is one function for both (`CapSpan`, `CapUntil`), with the same `ReadEvery` (the
  collector passes none, so 30 s), the same ledger read and the same capped settings.
- **The waits.** They are read from the Actor's own memo (`f.cl.memo`, shared) and the store, capped as the layer
  caps them, and none once over.
- **The schema step.** It applies only on `actKeyAfter`, uses `IF NOT EXISTS`, and the merge lines are as the report
  says. A read-only handle on an older file reads "no key" (`hasActKey`). No other reader touches `c_act_key`.
- **Privacy.** The new log lines are constant formats with numbers and words only. Errors are fixed words, and
  `ErrBadActLedger` carries a type name only. The new counts are names only.
- **The only new request path** is `help.getConfig` through `wantedLimits` and `clickLimits`.
- **The four adapted tests** are each the test's own need: the bound now holds repeats and floods; the reaction needs
  a held target. The function counts are unchanged in all four files (14, 23, 15, 20).

## The coder's departures, judged

1. Accepted.
2. Accepted.
3. Accepted. "Limits unknown" is told truthfully. The hold starts only at a failed ask, so polls cannot move it, and
   it cannot keep texts from going for more than a minute while Telegram answers.
4. Accepted.
5. Accepted: shown safe by the probe's counts. See finding 4 for the cost of failed asks.
6. Accepted, with findings 2, 5 and 9.
7. Wrong as written: finding 3.
8. Fine.

## What I could not check

- **The race detector** (not on this PC). It should run, in the container, on:
  - `internal/collector`, the click tests and `TestClickState*`: the atomics `limitsWokeMs`, `limitsNextMs` and
    `pubFw`, `pubMu`, the write context, the wake from the page's goroutine;
  - `internal/telegram`, the act tests: `ReadActWaits` reading `f.cl.memo` and `RefusalHeld` from another goroutine.

  By reading I found no field read across goroutines without its lock.
- **A real `help.getConfig`'s `caption_length_max`.**
- **Whether Telegram refuses a reaction to a service message** (finding 8).
- **The natural (unforced) race of finding 2.**

## Where the brief or the design is wrong or silent

- **Part 1** says `c_act` is untouched, but a new table that references `c_act` changes the account delete in
  `settle.go`. Neither the brief nor the report lists that file (finding 1).
- **Part 4** assumes the catalogue's attachment rows mean "has a caption"; they do not (finding 3).
- **Part 3** bounds failed asks only by 60 s, with no bound per session, and does not say that one ask can be several
  requests (finding 4).
- **Part 5** is silent on "send again" of an old click whose target is gone (finding 7).
- **The seam** treats "not running" from the door as certain ("nothing queued"), which this door cannot always promise
  (finding 2). Neither the seam nor the brief says what the page shows for a ledger row the door wrote and then
  answered with a refusal (finding 5).

---

# Second pass (905922ce)

MAY BE LISTED

I read `git diff 44519537 905922ce`, `BRIEF-K14b-fixes.md` and section 8 of the coder's report. Two runs, both on
905922ce:
- `run4-collector-second.txt` (overlay of `zz_review_k14_collector_test.go` and the new `zz_review_k14b_collector_test.go`,
  plus the coder's new tests by name);
- `run5-catalog-second.txt` (the coder's catalogue tests for F1, F8 and F9, by name).

Free memory was 5,500 MB or more before each go command. Nothing in the tree was changed.

Counts for this pass: both must-fixes closed. New: **1 SHOULD FIX** (CONFIRMED) and **2 MINOR** (by reading).

## The ten findings

1. **CLOSED.** `settle.go:498` deletes the account's key rows before its click rows.
   - `TestActKeyAccountDelete` passes, and a second account with a keyed click is then deleted too.
   - No other code deletes or re-creates `c_act` rows (grep of the tree: one statement list; the start's sweep deletes
     only key rows, by age).
   - An older file stepped to 24 gets an empty `c_act_key`. A backup (`VACUUM INTO`) copies both tables together.
     After an account's delete, the ids its clicks free can be taken again, but their key rows are gone with them.
2. **CLOSED.** After the commit, `QueueClick` and `SendClickAgain` answer the number in every case (`click_api.go:705-708`,
   `793-796`). My old probe now reads "ref=1 err=<nil> ... row 1 is in state "sending"; the same key again: ref=1".
   `TestClickQueuedForTaken` and `TestClickQueuedForStopped` pass.
   - No path answers a number with no row.
   - An error with a row written: only when the write itself errors after a commit (the unkeyed case, as before).
     With a key, the error is "failed", never a refusal word, and the same key then gives the number.
   - Nothing else in this tree calls `QueueClick` or `SendClickAgain` (the pages' routes and the pass-through are not
     on this branch), so nothing here relies on "a number means queued". The seam's owners must now read the row:
     a number can name a "sending" row or a "not sent (stopped)" row (see N3).
3. **CLOSED, by the architect's decision.** Every edit is judged by the text limit, at the queue (`click_api.go:655-663`)
   and in `limited` (`telegram/act.go:948-951`).
   - Nothing is left half-removed: no read of `Media`, no `capMax`, no `media_unreadable` count, no `clickLineMediaCant`.
     `ActLimits.CaptionMax` is still logged and published, as decided.
   - `TestClickCaptionRefusedByTelegram` passes for the right reason: an edit of 2,000 units is sent once and ends
     "refused" with `MEDIA_CAPTION_TOO_LONG`.
4. **CLOSED as briefed:** 4 asks in 10 minutes, where the first pass measured 10. **But see N1:** the doubled hold works
   against the seam.
5. **CLOSED**, by finding 2's change. A refusal is no longer answered for a row that was written.
6. **PARTLY CLOSED, as decided.**
   - (a) `MarkBad`: matches `oneClick`, which reads that setting for a read mark only.
   - (b) `noActor` → "clicks off", with no poll wake or nudge. `TestClickStateNoActor` passes.
   - Not taken, by decision: a method refused as frozen, a chat with no access hash.
   - New: N2 (`noActor` stays set).
7. **OPEN, not taken by decision.** Accepted: it is the owner's explicit click, and Telegram's refusal is shown.
8. **CLOSED.** `message.service` (schema v7) is read in `ActMessages`, and `heldMessage` refuses a service message.
   `TestActMessageService` passes. An edit or a delete aimed at a service message is left to the own-message rule and
   to Telegram, as the brief says.
9. **CLOSED.** The key is read first, with `clickForm` taken over the page's own input
   (`click_api.go:462-501`, `544-560`).
   - The encoding has a version string; every number has a fixed width; the kind, emoji and text are length-prefixed;
     the message list is count-prefixed and kept in order. Two different inputs cannot share an encoding.
   - Everything the request depends on is fixed by these fields. The resolved Telegram chat and the random ids follow
     from them or are made once for the click.
   - The catalogue requires a 32-byte digest with a key and refuses one without a key (`checkClick`,
     `TestActKeyDigestHanded`). The re-read after a failed write compares the same `form`.
   - `TestClickKeyChatGone` passes.
10. **CLOSED.**
    - `TestClickStateNudgeKeepsPause` now asks for equal counts (5 and 5 in my run).
    - Removed: `TestClickQueueRaceAtSessionEnd` (replaced by the forced tests; the property "a click queued at a
      session's end is never sent by the next one" stays covered by `TestClickQueuedBetweenSessions` and
      `TestClickQueuedForStopped`).
    - Removed: `TestClickCaptionAtTurn` and `TestActMessageMedia` (their rule was taken out).
    - Moved: `TestActFormFields` (now `TestClickFormFields`, 19 forms, 19 digests).
    - Left without a test: the branch of `queuedFor` where the "not sent" mark fails for a reason other than the state
      (N3, by reading).

## New findings

### N1. SHOULD FIX, CONFIRMED: after an outage, the doubled poll hold keeps every text from going for up to 30 minutes after Telegram answers again

- **Where:** `internal/collector/click.go:198-214` (`pollHold`) and `:913`, with the seam (`SEAM-B5-viewer-act.md`:
  "`MaxText` ... 0 means not known, and then no text goes").
- **Why the brief's guard does not help:** the brief protects a click's own ask (60 s). But the page sends no text while
  the state's `TextMax` is 0, so no click ever asks. The limits come only from the polls' ask, which waits out the
  doubled hold.
- **What happens to the owner:** after a short config outage, the compose box says the limits are unknown and holds
  every text for many minutes after Telegram works again. Truthful, but up to 30 minutes of nothing sent.
- **Probe `TestReviewK14bLimitsAfterRecovery`** (`run4-collector-second.txt`; config failing until a set time, then
  answering; only state calls):
  - an outage of 90 s: `TextMax` known 101 s after Telegram answered again (7 config requests);
  - an outage of 7 min 30 s: known **470 s** after (13 config requests).
  - By the arithmetic, an outage of 30 minutes or more gives up to 30 minutes.
- **Smallest fix, one of:**
  - (a) the seam: the page lets a text go when `TextMax` is 0 and `LimitsWanted` is set. The door then asks within
    60 s, as the brief meant, and answers "limits unknown" truthfully when it cannot.
  - (b) cap the poll hold low: about 5 minutes. That is at most 12 asks, 36 requests, an hour while Telegram
    refuses.
  - (c) a flag on the state call, "a text is waiting", that uses the click's 60 s hold.
  - (a) costs no request; the architect's choice.

### N2. MINOR, by reading: `noActor` stays set for the whole session

- **Where:** `click.go:806-836` and `click_state.go:145`.
- **How it happens:** it is set when the Forwarder or the Actor cannot be made, and cleared only by a later successful
  `clickActor`. Nothing calls `clickActor` again: the state answers "clicks off", so no limits are wanted and
  `wantedLimits` never runs, and the page sends no click. The mirror's turn making the Forwarder later
  (`forwarder()`, shared) does not clear it either.
- **What happens to the owner:** a transient failure to read the forward secret file shows "clicks off" until the
  session ends. No request is made.
- **Fix:** clear `noActor` when `forwarder()` succeeds, and let the clicks' step retry `clickActor` at most once a
  minute while it is set.

### N3. MINOR, by reading: a click whose "not sent" mark failed shows "queued" until a later session or start

- **Where:** `queuedFor`, `click_api.go:449-458`.
- **What happens:** when the session is ending and `ClickNotSent` fails for a reason other than the state, the row stays
  "queued" and nothing is woken.
- **What keeps it from going out:**
  - the ending session's `clicksStopped`, when the reader has not ended yet;
  - else the next session's first step (`StopClicksBefore`, `clicked_ms` < `began`), before anything is taken;
  - else the next start's sweep.

  It is never sent by a later session.
- **What the page sees:** it reads "queued" for as long as the account stays without a session (possibly hours). The
  state call says "not running" meanwhile, which is the true context.
- **Suggested:** the pages show a "queued" row of an account that is not running as "waiting for the account", or
  retry the mark once. No test covers this branch.

## Checked and found sound in this pass

- `noActor` is an atomic, written on the reader's goroutine and read by the state call. It cannot stay set once the
  Actor exists: every successful `clickActor` clears it, and with an Actor `clickActor` returns before anything can
  set it.
- `limitsFails` and `limitsFailed` are touched on the reader's goroutine only. The published `limitsNextMs` is
  cleared on success.
- Polls alone cannot keep the hold from clearing: an ask goes after each hold, and a success clears the hold and the
  count.
- A click's own ask is held 60 s only. `TestClickLimitsPollHold` passes: 4 asks, and with a click 4 asks in all.
- `TestClickStateReadMarkSettingBad`, `TestClickKeyChatGone` and `TestClickCaptionRefusedByTelegram` pass.
- The catalogue's `TestActFix3DeletedAccount` still passes.

## Not checked in this pass

- The race detector. It should run on `internal/collector` for `noActor` and the published hold.
- The coder's whole named runs: I ran only the tests named above.
