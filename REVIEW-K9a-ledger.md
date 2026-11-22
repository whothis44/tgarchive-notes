MAY BE LISTED AFTER THE MUST-FIXES

# Independent review of K9a, the ledger of the owner's clicks (2026-11-15 23:55)

Reviewed: branch `wip/core-ledger` at 726844a7 against e7624d5d (`git diff e7624d5d 726844a7`, six files).
Read in full: the design note, brief K9a, `docs/TRIED-BEFORE.md` sections 24 and 25 (rules 11 and 13),
`internal/telegram/act.go` (the interface, `ActOutcome`, `Do`, `capped`, `outcome`, `request`), the catalogue's step
pattern (`catalog.go` `Open`, `dsn`, `Batch`, `exec`, `steps`, `migrate`; `schema_mirrorname.go`, `schema13.go`
`hasLedger`), `internal/collector/lock.go`, `settle.go` `deleteAccountChunk`, and all of `schema_act.go`,
`schema_act_test.go`, `tgstore/act.go`, `tgstore/act_test.go`, the coder's report. Nothing in the copy was changed
(`git status --short` empty at the end).

Probes: `wt-core-ledger-review-scratch/probe_act_review_test.go` (package `catalog`, loaded with
`go test -overlay overlay-probes.json -run TestProbeReview ./internal/catalog/`), output in `probes-catalog.out`;
a mutant of `schema_act.go` (`mutant_sentsince_schema_act.go`, `overlay-mutant-sentsince.json`), output in
`mutant-sentsince.out`. Invented rows only, temporary files from `t.TempDir()`. The coder's own tests
(`-run TestAct` in both packages) pass: catalogue 5.8 s, tgstore 1.1 s; `go vet` on both packages clean.

Count: 1 MUST FIX, 4 SHOULD FIX, 6 MINOR.

## Findings

### 1. MUST FIX, CONFIRMED: "send again" is guarded per row, not per click, so one click can be repeated after its repeat was carried out, and have two live repeats at once

`internal/catalog/schema_act.go:966-995` (`SendClickAgain`; the guard is the `NOT EXISTS` at line 976 and the
unique index `c_act_live_again` at line 90, both on `again_of = o.id` only).

What happens to the owner: a forward (or reaction, delete, read mark: any kind without text) whose first try was
"not known" stays "not known" with its "send again" offered after its repeat was recorded "done", and a second
"send again" there forwards the same messages again; whether Telegram refuses it as a repeat depends only on how
long it remembers the random ids of a request it carried out, which is not on record (the design's one
measurement is about ids it had NOT carried out).

Probe `TestProbeReviewAgainLineage`:
```
R1a: repeat of original err=<nil>, repeat of repeat err=<nil>, live queued repeats of one click=2
R1a: both live repeats carry the same random ids: true; both can be begun: true true
R1b: repeat of a click whose repeat is done: err=<nil> (nil means a new queued forward exists)
R1c: react, repeat of a click whose repeat is done: err=<nil>
```
A send or an edit is protected only by accident: its text moved to the first repeat, so the old row fails the
`o.text IS NOT NULL` test. Every kind without a text is not.

Smallest fix I would accept: a row may be repeated only while it has no repeat at all (the chain's tip): the
`NOT EXISTS` without the state condition (`... WHERE l.again_of = o.id`), and the index `c_act_live_again` made
`UNIQUE (again_of) WHERE again_of IS NOT NULL` (one repeat per row, ever). Then a chain is linear, only its tip
can be live, and a tip that ended "done" has no "send again" left anywhere in its chain. A test that runs
R1a and R1b and expects `ErrActState`.

### 2. SHOULD FIX, CONFIRMED: the owner's verdict "arrived" is taken on a row whose repeat is still queued or sending; the repeat then goes out

`internal/catalog/schema_act.go:940-952` (`ClickVerdict`, statement at line 944).

What happens to the owner: the app or the owner marks the first try "it is in the chat" while the "send again"
of it waits in the queue (the cap, a turn behind the reader), and the queued repeat is still sent: a second
message unless Telegram refuses the same random id.

Probe `TestProbeReviewVerdictWithLiveRepeat`:
```
R2: verdict arrived while a repeat is queued: err=<nil>; the repeat begun afterwards: err=<nil>; repeat state sending
R2: forward: verdict err=<nil>, repeat begun err=<nil>
```
Smallest fix: with finding 1's fix, a verdict only on the chain's tip (a row with no repeat); or, in one
transaction with the verdict, the live repeat to "not sent" with the owner's cancel. Design section 5 already says
the app marks "arrived" only when "no other click waits with the same content": the ledger should hold that.

### 3. SHOULD FIX, CONFIRMED: an account deleted from the catalogue leaves its clicks (texts kept); a new account takes the same id and inherits them, including "send again"

`internal/catalog/settle.go:490-497` (`deleteAccountChunk`'s last phase does not touch `c_act`/`c_act_msg`);
`internal/catalog/catalog.go:325` (`account.id INTEGER PRIMARY KEY`, no AUTOINCREMENT, so the highest id is
given again); `internal/catalog/schema_act.go:47-50` (no foreign key to the account, on purpose) and 966-977
(`SendClickAgain` checks neither the account's `removed_at` nor that it still exists).

What happens to the owner: after deleting the newest account and adding another, the new account's page shows the
old account's clicks with their texts, the old account's remembered refusals block the new account, and "send
again" on an old row sends the old account's message from the new account (a different account, so Telegram
cannot refuse it as a repeat).

Probe `TestProbeReviewDeletedAccountRows`:
```
R9: old account row left 0; its click rows with text kept 2; new account id reused: true; its page shows 2 old
clicks (err <nil>); old refusal applies: true; send again of the old click: err <nil>, queued for the new account: true
```
Latent today: nothing outside the catalogue's tests calls `DeleteAccount` (searched). Smallest fix: the delete's
last phase deletes the account's `c_act_msg` and `c_act` rows (one statement each, before `DELETE FROM account`),
and `SendClickAgain` adds the `QueueClick` check (`account` present, `removed_at IS NULL`). The mirror ledger has
the same no-foreign-key choice and may have the same reuse hazard: not reviewed here.

### 4. SHOULD FIX, CONFIRMED: the 7-day rule runs only at a program start, and three end states keep a text no door can use

`internal/catalog/schema_act.go:844-845` (the only statement that clears an old text, inside
`SweepClicksAtStart`); `:857-860` (`SweepOldClicks` does not clear texts); `:267-273` (`actTextCleared`) with
`:276` (`actAgainFrom` excludes `account refused`, `frozen`, `signed out`).

What happens to the owner: a collector that runs for weeks keeps the text of every waited, refused, not sent or
not known click for weeks (the 7 days count only from the next start); and the texts of clicks ended
"account refused", "frozen" or "signed out" are kept up to 7 days although no door ever sends them again.

Probe `TestProbeReviewTextAgeOnlyAtStart`:
```
R3: 30 days later, the age sweep swept 0; waited text kept true; account-refused text kept true
R3: send again from account refused: catalog: the click is not in a state this door takes (the kept text has no door that uses it)
```
Also: the 7 days run from `clicked_ms`, and a repeat's `clicked_ms` is the repeat's time
(`schema_act.go:972`), so each "send again" restarts the 7 days for the same text (the owner's own clicks; said
for completeness). Smallest fix: the 7-day statement also in `SweepOldClicks` (it runs every turn) or a door of
its own that the turn calls; and either the three states added to `actTextCleared` or "send again" allowed from
them (the brief's section 5 does not name them: the owner's call, one line on the board).

### 5. SHOULD FIX, CONFIRMED (test gap): guarantee (3), "the list of what was sent is complete", has no test that fails when ended rows are dropped from it

`internal/catalog/schema_act_test.go:705-750` (`TestActSentSince`) and `internal/tgstore/act_test.go:166-209`
(`TestActLedgerSentAndRefusal`): the only ended row they list is one "waited"; no "not known", no "not sent"
reached through End (the cap counts both: `internal/telegram/act.go:207-209`).

What happens to the owner: a later change that makes "sent since" skip unknown outcomes or late "not sent" rows
would let the app write past its cap, and every test would still pass.

Probe: the mutant adds `AND state NOT IN ('not known','not sent')` to the query at `schema_act.go:881`;
`go test -run TestAct ./internal/catalog/ ./internal/tgstore/` with it:
```
ok  	tgarchive/internal/catalog	4.397s
ok  	tgarchive/internal/tgstore	0.927s
```
Smallest fix: `TestActSentSince` begins one click per end state reachable after Begin (every End state, the
start sweep's "not known", and "arrived"/"left" after it) and expects every one listed. The coder's two mutation
checks (Begin's compare-and-set, door 11's guard) were the right ones for guarantees 1 and 4; the other
guarantees' tests do fail when their statements are undone, by my reading of `TestActTransitions` (every door
from all 14 states, row unchanged) and `TestActSweeps`.

### 6. MINOR, CONFIRMED: the CHECKs let an end state be written without `sending_ms`, and such a row is missing from "sent since"

`internal/catalog/schema_act.go:83-85`. Only the doors keep it true: every state but `queued` and `not sent`
is reached only through Begin, but nothing in the table says so.

What happens to the owner: nothing today; a future door or a tool that writes an end without the Begin time
silently shrinks the cap's count.

Probe `TestProbeReviewSentSinceNullSending`:
```
R5: a done row with no sending_ms accepted by the CHECKs: true; listed by sent since: 0 rows, err <nil>
```
Smallest fix: `CHECK (state IN ('queued','not sent') OR sending_ms IS NOT NULL)` (holds for every door's write;
"not known" from the sweep and "arrived"/"left" all have it).

### 7. MINOR, CONFIRMED: a remembered refusal whose state word is damaged reads as "no refusal" (rule 13)

`internal/catalog/schema_act.go:920-922` (`LastChatRefusal` filters `state = 'refused' AND remember = 1` in SQL;
the row's words are never read). The same holds for `NextClick` (`:602`), which skips a row whose state word is
not `queued` without reading it (fail-safe there: nothing is sent).

What happens to the owner: only past the CHECKs (a tool, a damaged page): the chat's refusal is forgotten and
the next click there makes a request.

Probe `TestProbeReviewRefusalUnknownWord` (state rewritten to `Refused` with `ignore_check_constraints`):
```
R6: refusal with a damaged state word: ok=false err=<nil> (fail closed would be an error)
```
Smallest fix: none needed beyond the CHECKs if the reviewer of the second half agrees; otherwise one guard
query (`SELECT COUNT(*) ... WHERE account_id = ? AND chat ... AND state NOT IN (<the 14 words>)` > 0 is
`ErrBadActLedger`).

### 8. MINOR, CONFIRMED: a repeat inherits the old row's "try again"

`internal/catalog/schema_act.go:972` (`MAX(o.try_again, ?)`).

What happens to the owner: a click sent with "try again" over a remembered refusal, refused again (remembered),
then "send again" without "try again": the repeat still passes the remembered refusal and makes a request into a
chat that refused this kind seconds before. The report (section 6) calls it a choice; the design says "try
again" is the owner's click, so the repeat should carry only the caller's `tryAgain`.

Probe `TestProbeReviewTryAgainInherited`:
```
R7: repeat asked with tryAgain=false carries try_again=true
```
Smallest fix: `?` in place of `MAX(o.try_again, ?)`.

### 9. MINOR, CONFIRMED: "never hours late" depends on the turn calling the age sweep before every Begin, and on the clock

`internal/catalog/schema_act.go:633-642` (`BeginClick` does not look at `clicked_ms`); `:857-860` (the age sweep
compares `clicked_ms`, the page's clock, with the caller's `beforeMs`).

What happens to the owner: with the PC's clock stepped back an hour, a click queued behind a wait or the cap is not
swept and goes out up to an hour after it was made (and a turn that forgets the sweep sends any queued click
however old: guarantee (2) holds only through the start's sweep).

Probe `TestProbeReviewAgeSweepClockBack`:
```
R8: swept 0; Begin of the click made 50 minutes ago in real time: <nil>
```
Smallest fix: `BeginClick` takes the bound as well (`... AND state = 'queued' AND clicked_ms >= ? AND clicked_ms <= ?`,
the second being now plus a small margin), so a click older than the bound or dated ahead of the clock is
refused at the one statement that matters, whatever the turn does.

### 10. MINOR, CONFIRMED (by the coder's own test): a forward recorded "done" with messages the answer did not name says nothing on the row

`internal/tgstore/act.go:151-164` (`endOf` drops `out.Missing`); `internal/catalog/schema_act.go:707-708`
(`partly` only on "sent before"). Shown by `internal/tgstore/act_test.go:112-115`, which passes: a forward of two
with `Missing: [11]` is a plain "done", `partly` false.

What happens to the owner: the conversation's row (door 12 returns no message rows) shows the forward done
although one of its messages may not have arrived; only `Click` with its message rows' NULL `new_msg` tells.

Smallest fix: allow `partly` on "done" and set it when `Missing` is not empty (one CHECK word, one line in
`endOf`); the page then looks in the chat for those, as for "sent before".

### 11. MINOR, PLAUSIBLE: an End that fails leaves the row "sending" for as long as the program runs

`internal/telegram/act.go:772-779` (End once, on `saveCtx`, failure logged); no door moves a "sending" row
except End and the start's sweep (`schema_act.go:836`).

What happens to the owner: after a busy catalogue (5 s `busy_timeout`) or a failed write at End, the page shows
"sending" until the next start, then "not known" with the type "the program ended while it was out", although the
answer may have been "done". What would show it: a test of `Actor.Do` whose ledger fails End once.
Smallest fix: for the second half, not this piece: the turn retries the End once on a context of its own, or a
door "sending to not known now" with the type word "the outcome could not be recorded".

## Facts on the text's afterlife (asked as facts, not demands)

- `secure_delete` is 0 (probe R4); the writer's DSN (`internal/catalog/catalog.go:199-201`) sets no
  `secure_delete` and no `auto_vacuum`.
- A cleared short text: still in the WAL file until a checkpoint (R4: `true`); after a close and checkpoint, not
  found in the main file in this probe (R4, R4b: `false`; the page was rewritten).
- A cleared long text (overflow pages, about 9 KB here; a 4,096-character text in many scripts is over one 4 KB
  page): it stays on the free pages of the main file after the clear and the checkpoint. Probe
  `TestProbeReviewClearedLongText`: `R4c: copies of the marker in the main file before the clear: 298; after the
  clear and a checkpoint: 558; free pages 4`. It is gone only when SQLite reuses those pages.
- Backups (`internal/backup/sqlite.go:101`, `VACUUM INTO`) copy every text still kept at the backup's time;
  they do not copy free pages (SQLite's documented behaviour, not probed).

## Checked and found sound (not to be checked again)

- **Begin (guarantee 1):** one autocommit `UPDATE ... WHERE id = ? AND state = 'queued'` on the single writer
  connection; across processes SQLite serialises it. `TestActBeginTwoConnections` (two handles, 200 rounds)
  passes and fails when the compare-and-set is widened (the coder's mutation). A "database is locked" past the
  5 s busy wait commits nothing; the row stays queued; the Actor then sends nothing (`act.go:740-749`). A ref 0,
  negative or missing: `whyNot` gives `ErrNotFound`, the adapter a store error, not "spent". A commit whose answer
  is lost: by reading database/sql and the autocommit statement, the error comes back only when the statement was
  interrupted before it committed; I found no path where the change commits and the caller gets an error.
- **End (guarantee 4):** one Batch; the compare-and-set names "sending"; a forward's per-message updates in the
  same transaction, rolled back whole on an id not of the click (tested). No door moves a row out of an end
  state: `ClickNotSent` and both sweeps name `queued`/`sending`, the verdict names `not known`,
  `SendClickAgain` changes only the old row's text. `queued` straight to an end through End: refused
  (`TestActTransitions`, every door from all 14 states).
- **The start's sweep (guarantee 2):** one transaction (a crash in it rolls back); not scoped to an account, which
  is right because `internal/collector/lock.go` lets one collector hold a catalogue; other read-write programs must
  never call it (for the second half). A swept row can never be begun (tested). No door sets a row back to
  `queued`.
- **The age sweep against Begin:** both single statements on one writer: whichever runs first wins, the loser's
  compare-and-set changes nothing; Begin's loser is told (`ErrClickSpent`), the sweep's count leaves it out.
- **Times and the cap:** the adapter rounds a Begin time up and a lower bound down (`tgstore/act.go:40-54`), so a
  stored `sending_ms` is never earlier than the Actor's time and a window never starts later: `capped`'s
  `now.Sub(s.At) < span` can only hold a click longer, never let a 31st or one a second early through. Rows dated
  ahead are included (`sending_ms >= since`) and the Actor counts them as now. The hard bound: 1,001 rows read,
  more than 1,000 is `ErrActTooMany`, which the Actor treats as a failure with no request (`act.go:960-964`).
- **The remembered refusal:** only `state = 'refused' AND remember = 1`, newest by `ended_ms, id`, inclusive
  bound, chat keyed by kind and id (the adapter clears the forum flag), send and reply one kind (`send`).
- **The adapter's outcome map:** all eleven `ActOutcome` kinds that follow a Begin map to a state (`OutDone`,
  `OutNotModified`, `OutSentBefore`, `OutWaited`, `OutRefused`, `OutAccountRefused`, `OutFrozen`,
  `OutSignedOut`, `OutUnknown`, `OutNotSent` with its three reasons, a new reason falling to "a stored value
  cannot be read"); `OutNone` and anything unknown is `ErrBadAct` (row stays sending); `Do` never ends with
  `OutNone` (`act.go:766-771`, `outcome` always sets a kind). A type word that is not a word becomes
  "unclassified". `ErrActSpent` maps to `telegram.ErrClickSpent` and nothing else does.
- **Nothing of a row in an error or log:** every error is a fixed word, with at most the catalogue's own row
  number; SQLite's constraint errors name columns, not values; the tests print states and counts only.
- **The schema step:** refuses any version but `actAfter` (tested at the version before and its own); every
  statement `IF NOT EXISTS`; the three lines in `catalog.go` follow the other steps. A read-only handle on an
  older file opens and sees no clicks (tested, file unchanged). At the merge only `actAfter` changes (`actSchema`,
  `SchemaVersion`, the step's map entry and dispatch all follow the constant); `TestActSchemaStep`'s "other
  version" (`protectedSchema`) stays another version. No foreign key to chat or account; `c_act_msg` and
  `again_of` reference `c_act`, which no door deletes from.
- **The viewer's wall:** `schema_act.go` and its test import only the standard library; nothing in
  `internal/catalog` imports `internal/telegram` (searched the import lines).

## Not checked

- The viewer's `TestWallDependencies` (outside the two packages I may run); checked by the import lines only.
- The race detector, real Telegram, the second half (none exists yet).
- Whether the mirror ledger has finding 3's account-id reuse hazard.
- How long Telegram remembers the random ids of a request it carried out (finding 1's real exposure).

## Where the brief or the design is wrong or silent

- **Brief section 4, door 11:** "at most one live repeat of a row" is the wrong unit: it must be per click (the
  chain of repeats), and a click whose repeat arrived must not be repeatable (finding 1).
- **Brief section 4, door 10:** silent on a verdict while a repeat is live (finding 2).
- **Brief section 5:** "older than 7 days (one bounded statement the start's sweep runs)" leaves a long-running
  program without the rule (finding 4); silent on `account refused`, `frozen`, `signed out`.
- **Brief sections 3 and 4:** silent on what a deleted account does to the ledger (finding 3).
- **Design section 4:** "a forward counted by its messages against the mirror's hourly bound": door 8 returns no
  message count, so the second half has no door for it; the Actor counts a forward as one (`act.go:615-617`).
- **Design section 5:** "send again" under the same random id is safe only while Telegram still remembers the
  first; the one measurement on record is about ids it had not carried out.
- **Design section 4, "the text lives in the catalogue only":** true of the live tables, but a cleared long text
  survives on free pages and every backup copies the kept texts (facts above).
- **Brief section 5 on End failing:** the design accepts "sending" until the next start; for a program that runs
  for weeks that is a long "sending" (finding 11).

## Second pass (the fix round, e04a41bf)

MAY BE LISTED

Reviewed: `git diff 65c1989e e04a41bf` (seven files), brief `BRIEF-K9a2-fixes.md`, the report's section 9 (read
last). The copy is at e04a41bf6e634160ad6352b5e229dbc1d2c2cdef, `git status --short` empty, nothing in it changed.
The round's own tests pass (`-run TestAct` in the catalogue 8.7 s, `-run TestActLedger` in tgstore 1.7 s, six
tests); `go vet` on both packages clean; `gofmt -l` on both prints nothing.

Method: every fix undone in a copy of its file and loaded with `go test -overlay` (relative paths), then the
round's tests run by name: `wt-core-ledger-review-scratch/second/mutants.sh` and `mutants2.sh`, outputs
`mutants.out` and `mutants2.out`. New probes: `second/probe2_act_review_test.go`, output `second/probe2.out`.

Count: 0 MUST FIX, 0 SHOULD FIX, 5 MINOR (new). All eleven first-pass findings CLOSED.

### The eleven findings

| # | Status | The code | A test that fails with the fix undone (mutant: what failed) |
|---|---|---|---|
| 1 | CLOSED | `internal/catalog/schema_act.go:1112` (no repeat at all), `:95` (`c_act_again`, one repeat per row, ever) | `m1_chain_per_row`: `TestActFix1OneChain` ("R1a: a repeat of a row that has one: nil"), `TestActSendAgainTwoAtOnce`; the index alone undone (`m1b_index_live_only`): `TestActSendAgainTwoAtOnce` ("a second repeat of a row written by hand") |
| 2 | CLOSED | `schema_act.go:1076-1077` (verdict on the tip only) | `m2_verdict_any_row`: `TestActFix2VerdictOnTip`, `TestActFix2ReadDoorsShowTheTip` |
| 3 | CLOSED | `internal/catalog/settle.go:497`; `schema_act.go:687` (Begin), `:1113` (send again) | `m3a_delete_keeps_clicks`: `TestActFix3DeletedAccount` ("5 rows of the deleted account left"); `m3b`: "Begin for a removed account: nil"; door 11's check alone (`m3c`): "send again for a removed account" |
| 4 | CLOSED | `schema_act.go:959` (the age sweep clears), `:294` (cleared at account refused, frozen), `:305` (send again from signed out) | `m4a_age_sweep_keeps_texts`: `TestActFix4TextAge`; `m4b_three_ends_keep_text`: `TestActFix4TextAge`, `TestActTextLife` |
| 5 | CLOSED | `schema_act_test.go:711-753` | my first-pass mutant (`m5`): `TestActSentSince` ("a click past Begin not listed (not known)"), `TestActFixSentMessages` |
| 6 | CLOSED | `schema_act.go:89` | `m6_no_sending_check`: `TestActFix6SendingTimeChecked` |
| 7 | CLOSED | `schema_act.go:1038-1047` (door 9's guard), `:1012` (door 8's) | `m7a`: `TestActFix7DamagedWord` ("the refusal's read: ok false, nil"); `m7b`: the same test ("the window's read: nil") |
| 8 | CLOSED | `schema_act.go:1108` | `m8_try_again_inherited`: `TestActFix8TryAgainNotInherited` |
| 9 | CLOSED | `schema_act.go:680-706` | `m9_begin_no_age`: `TestActFix9BeginTooOld` ("a click queued 3 minutes ago was begun"); the "not sent" move alone undone (`m9b`): "the old click: queued" |
| 10 | CLOSED | `internal/tgstore/act.go:178` | `m10_no_partly_on_done`: `TestActLedgerFixPartlyAndCancelled` ("done, partly false") |
| 11 | CLOSED | `schema_act.go:860-877` (`ClickOutcomeLost`, only from sending) | `m11_outcome_lost_any_state`: `TestActFix11OutcomeLost`, `TestActTransitions` ("OutcomeLost from done: nil") |

### New findings (all MINOR)

**N1. MINOR, CONFIRMED: a queued click of an account marked removed is offered again by `NextClick` at every turn, and its refusal is counted as a store failure.**
`internal/catalog/schema_act.go:636-653` (`NextClick` has no account condition) with `:680-706` (Begin refuses it
with `ErrNotFound`, the row stays queued) and `internal/tgstore/act.go:133` (mapped to a store error; the Actor
logs "a stored value cannot be read" and counts `StoreFailures`). What happens to the owner: nothing is sent; if
a turn still runs for that account it picks the same click each time until the age sweep ends it (2 minutes),
and the counts call it a store fault. Probe `TestProbe2BeginBounds`: `removed account: Begin catalog: not found:
the account is not in the catalogue ...; state queued; NextClick still returns it: true`, then `the age sweep for
that account 3 minutes later: not sent 1`. Smallest fix: `NextClick` takes `actAccountLive` as well (one
condition), or the second half never runs a turn for a removed account (say it in its brief).

**N2. MINOR, CONFIRMED: `BeginClick` called on a Batch handle does not keep its "not sent in time" when the outer function returns the answer.**
`schema_act.go:697-705`: the comment says the move is committed, which holds only on a plain handle; inside an
outer `Batch` the move is rolled back with the outer transaction. Probe `TestProbe2BeginTooOldInsideBatch`:
`inside a Batch: catalog: the click is too old to be sent; it is not sent (too old true); the row after: queued`.
Nothing is sent either way, and the adapter calls it on the plain handle. Smallest fix: one sentence in the doc
comment ("call on the catalogue, not inside a Batch").

**N3. MINOR (doc), by reading: the report's and the brief's "every message's text is in the catalogue for good in any case, so the ledger's text is no more exposed" is wrong for the texts that matter most.**
`docs/progress/core-ledger-REPORT.md` section 9, "The text's afterlife", third bullet (and `BRIEF-K9a2-fixes.md`
section 7). A text that was never sent (waited, refused, not sent, signed out, or a "not known" that did not
arrive) is in no `message` row: the ledger and the backups made while it was kept are its only copies. Smallest
fix: that bullet says "for a text that was sent" and adds the case above.

**N4. MINOR, PLAUSIBLE: the schema text changed in place, so a file stepped to this number by an earlier build of the branch is accepted and then fails at every read.**
`schema_act.go:51-103`. A catalogue opened read-write by a build of 726844a7 is at `actSchema` with `c_act`
lacking `chain` and `c_act_again`; this build sees the version equal to `SchemaVersion`, migrates nothing, and
every door that names `chain` fails with "no such column" (fail closed: nothing is sent). A file relabelled to
`actAfter` that holds the old table fails the step itself (`CREATE INDEX c_act_chain`), so Open fails. What would
show it: a test that writes the old step's text on a file, labels it `actSchema`, and opens it. Harmless only if
no build of `wip/core-ledger` before e04a41bf ever opened a kept catalogue read-write: the integrator should
confirm that before the merge (the report says no real file).

**N5. MINOR (cosmetic): a doc comment lost its line break.**
`schema_act.go:46`: "newest row, carries it.//   - c_act_msg: one row per message ..." (the second bullet of
the schema comment is glued to the first).

### The questions asked

**2. `BeginClick`:**
- Two callers both getting nil is not possible. The CAS still names `queued` in one statement. `BeginTx` takes
  the write lock at BEGIN (`_txlock=immediate`), so two handles and two processes are serialised.
  `TestActBeginTwoConnections` still passes. Undoing the round's bound (`m9`) is caught.
- A row "sending" with the caller told anything but nil: none found. `fn` returns nil only after `n == 1`, and
  then `Commit`. An error before the commit rolls back, and the row stays queued. database/sql rolls back a
  transaction whose context ends before `Commit`.
- A click neither too old nor begun cannot end in a wrong state. The two statements' spans are exact complements:
  `>= at-age AND <= at+5 s` against `< at-age OR > at+5 s`. Probe S2: at the bound, begun; 1 ms past it, too old;
  5 s ahead, begun; 5 s + 1 ms ahead, too old.
- An account gone: when deleted, its rows go with it (point 4). When marked removed, its queued click stays queued
  (N1). It is ended by the age sweep, by the start's sweep, or by Begin once it is too old: the second statement
  has no account condition.
- The adapter's mapping, and what `Actor.Do` does with each answer:
  - nil: the request is sent.
  - `ErrActSpent` and `ErrActTooOld`: `telegram.ErrClickSpent`, so nothing is sent. The Actor counts it as
    "Spent", so a too-old click is counted as spent (a label only).
  - `ErrNotFound` (no row, or the account removed), `ErrBadAct` (an age of 0, which the adapter's default
    prevents), and busy or other errors: a `*StoreError`. `Actor.failed` then returns `ErrStore` and nothing is
    sent.
  - The context's end: returned as it is.
  - A too-old row has no `sending_ms`, so it never counts against the cap.

**3. The chain:**
- One click with two live rows: no order of doors gives it. A row can be repeated only while it has no repeat:
  door 11's `NOT EXISTS`, held up by the `c_act_again` index.
- Repeats are made only from end states, so the new row is the chain's only live row. Every door that could move
  an older row refuses it:
  - the verdict refuses a row that has a repeat;
  - cancel and both sweeps take only `queued` or `sending`, and an older row is never in either;
  - `EndClick` and `ClickOutcomeLost` take only `sending`.
  - So the rows behind the tip never change state again.
- A live repeat of a click already carried out: a "done", "sent before" or "not modified" tip offers no "send
  again".
- Two "send again" at once on a tip that is itself a repeat, from two handles: probe S3, 50 rounds, exactly one
  new row and one live row each time; every other answer was the state error.
- A tip stuck with no door out: one only after its text's 7 days. A "waited", "refused", "not sent" or
  "signed out" send or edit then takes no door at all (probe S7). These are ends at which nothing was carried out,
  so no door is owed.
- A "not known" tip always takes a verdict.
- The text moving along the chain and the 7 days restarting at each repeat: acceptable. Each restart is an
  owner's click, and the text moves rather than being copied: the old row's text is cleared in the same
  transaction.

**4. The account delete** (`internal/catalog/settle.go:497`):
- It runs in the delete's last phase, inside the same `Batch` transaction as the account's own row (`settle.go:155`
  runs `tc.applyChunk`).
- The order is the message rows, then the clicks, then the account. Message rows can never be left without their
  click.
- The self-references `again_of` and `chain` are deleted in one statement and checked at its end. Probe S1, with
  a chain of three repeats and forward messages in the deleted account: account row 0, click rows 0, orphan
  message rows 0, the other account's message rows kept, no settle intent left.
- Plans (S5): the delete of messages uses `c_act_msg`'s primary key and the `c_act_chat` index's prefix. The
  delete of clicks uses `c_act_chat`, and the foreign-key checks use `c_act_chain` and `c_act_again`.
- No other part of the delete changed.

**5. The 7-day statement every turn:**
- Plan: `SEARCH c_act USING INDEX c_act_text (clicked_ms<?)`. It reads only the rows that still hold a text and
  are older than the bound. That is near nothing on every turn, and there is no full scan.
- It cannot clear a text that a queued or sending click still needs. A queued click 7 days old is refused by
  Begin's 2-minute bound in any case. The request of a sending click was built from the text before Begin.
- If a future caller passes an age bound over 7 days, a send whose text was cleared reaches the Actor with an
  empty text and is refused locally (`ErrActText`): it fails safe.

**6. The fail-closed guards:**
- A healthy table does not trip them. The SQL list equals the 14 words (`TestActFixStateList`). Probe S4, every
  state in one chat and kind: the refusal read returns its row with no error, and "sent since" lists 12 rows with
  no error.
- Cost per click, from the plans:
  - The refusal guard is one indexed range over the account's rows of that chat (`c_act_chat` prefix), filtered
    on kind and state. It grows with the chat's history and is acceptable at a person's click rate.
  - "Sent since" reads the state in its own statement, plus one covering-index count per row for the messages.

**7. `ClickOutcomeLost` and `partly`:**
- `ClickOutcomeLost` takes only `sending` (`m11` caught). It keeps the text, as at "not known", and its type word
  is fixed. It cannot overwrite an end state. If End did commit and only its answer was lost, the door answers
  `ErrActState` and changes nothing.
- `partly` on "done" is set only when `Missing` is not empty, which only a forward fills.
  `checkEnd` (`schema_act.go:778`) would take `partly` on a "done" of any kind from another caller. That is a
  label only, and not counted as a finding.

**8. The schema step:**
- It applies on a file at the step before. `TestActSchemaStep` passes and checks the eight indexes. It is refused
  at any other version (the code is unchanged).
- Nothing depends on 21 against 22: the only number is the constant `actAfter`, and the comments name 22.
- The step changed in place: see N4.

**9. Anything new; the coder's choices:**
- New, beyond N1 to N5: door 5's added guard (`schema_act.go:895`) is unreachable, because a queued row is
  always a tip. Undoing it (`m2b_cancel_any_row`) fails no test: harmless, said so it is not counted on.
- The new read columns `RepeatedBy` and `Tip` cost two covering-index lookups per row (S5), and `scanAct`
  checks that they agree.
- The coder's choices:
  - The step's text changed in place, with no second step: acceptable if N4's condition holds.
  - A click dated ahead by more than 5 s gets the same word as one too old ("not sent in time"): acceptable. Its
    age cannot be known, and the page needs no second word.
  - Door 9's guard reads every row of the chat and kind, not only refusals: acceptable and right. A damaged word
    could be any state.
  - The 7-day clearing clears every account's texts at every account's turn: acceptable. It is one indexed
    statement, a no-op after the first, and an old text of any account has no use.
  - The 7 days restart at each repeat, and `secure_delete` stays 0: acceptable as stated. The one wrong sentence
    beside them is N3.
