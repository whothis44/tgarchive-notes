# Brief K9a: the client's acting side, piece 2, first half: the ledger of clicks (Core, K-3, 2026-11-15 23:25)

For one Opus coder. The design the owner agreed to: `DESIGN-CORE-client-actions.md` (section 3, steps 3
and 5; section 5). Piece 1, the request layer, is `BRIEF-K8-client-requests.md` with its fix round
`BRIEF-K8b-fixes.md` (branch `wip/core-act`; the fix round is with another coder as you start). This
piece is the record every click of the owner's is written into before a request leaves, and read from
afterwards: a table in the catalogue, its doors, and the small adapter that makes it the request layer's
`ActLedger`. **Nothing here sends anything: no request, no goroutine, no collector file.** The click's turn
in the account loop, the settings and the routes are the second half and piece 3; do not build them.

- Copy: `C:\Users\trabi\Claude\Projects\Telegram\wt-core-ledger`, branch `wip/core-ledger`, cut from
  `wip/core-act` at 79debb9f (so the request layer's types are there). Go module in its `archiver` folder.
- Pushed to `private` as `wip/core-ledger` as you go. Never the branch `claude/charming-feynman-vm2xia`.

## 1. What the old app already knows

Nothing: the old app (`wt-v12.31`) has no ledger of anything it sends (its auto-forward keeps no row per
try and takes a lost answer for "failed"). The model on record is the new app's own mirror ledger
(`internal/catalog`: `c_mirror_batch`, `c_mirror_forward`, `c_mirror_again`, the settle), which ran for
real on 11-15: an intent row written before the request, an outcome written after, an unknown outcome
never sent again by itself and settled from what the chat shows. Read how it does these three things
(`schema_mirrorauto.go`, the mirror's doors in the catalogue, `TELEGRAM-FACTS.md` section 11) and follow
it where it fits. Rules 11 and 13 of `TRIED-BEFORE.md` section 25 bind this piece directly: one row per
item, never a list kept in one value; a stored value that cannot be read stops the writes and never reads
as "empty".

## 2. Read first, yourself, in full

The design note; the two K8 briefs; in the copy `internal/telegram/act.go` (the `ActLedger` interface,
`ActOutcome`, `Action`, `ActKind`, `SentClick`) and the coder's report
`archiver/docs/progress/core-act-REPORT.md`; `archiver/docs/TRIED-BEFORE.md` sections 24 and 25;
`internal/catalog/catalog.go` around the list of schema steps (lines 500 to 600), `schema_protected.go`
and `schema_mirrorname.go` with its test (the pattern of a step: two constants, a function that refuses a
file at any other step, the change-log triggers where a table is one the viewer follows),
`schema_mirrorauto.go`; `internal/tgstore/store.go` (where the catalogue is made into the stores
`internal/telegram` asks for: `ForwardStore`, `MemoStore`, `PeerStore`).

## 3. The schema step

**Step 22 is taken for this on the board's schema line** (21 is the copies track's). On the branch it is
the step after the head's (20), with the number in two constants, as `schema_mirrorname.go` does it: the
integrator sets the final number at the merge. A new file `internal/catalog/schema_act.go` and its test.

Two tables (names are yours to fit the catalogue's; `c_` is the collector's prefix):

**The clicks, one row per click.** Its own number (the "ref"); the account; the chat written to (kind and
id); the kind (send, forward, edit, delete, react, read); what the request needs: the message replied to,
the topic, the target message (edit, react, the read mark's upper id), the forward's source chat, the
random id of a send, the emoji, "for everyone" of a delete, "try again"; **the text** (send, edit), kept
only as long as section 5 says; the state (section 4); the times (clicked, marked "sending", ended); the
end of a wait; Telegram's error type as a word; `remember`; `partly`; the new message's id; a delete's
count; a fixed word for why a click was not sent; the row this one is a "send again" of (same random ids),
if any.

**The click's messages, one row per message** (a forward's source messages and a delete's ids: never a
list in one column): the click, the position, the source message id, the album id of a forward's message,
its random id, and after the answer its new id in the destination. This is what lets a later piece ask
"which of these arrived" one by one after an unknown or a partly carried-out forward.

Indexes for exactly the reads in section 4 (the oldest queued click of an account; clicks marked
"sending" at or after a time, per account; the last remembered refusal of a chat and kind; a chat's rows
in order). No index nobody reads.

## 4. The states and the doors

States, as fixed words: **queued** (written by the page's door, nothing sent), **sending** (`Begin`), and
the ends: **done**, **not modified**, **sent before**, **waited** (with its end), **refused** (with
Telegram's word and `remember`), **account refused**, **frozen**, **signed out**, **not known**,
**not sent** (with a fixed reason word: a local "no" of the request layer, the owner's cancel, too old,
the program stopped before it went, a wait or refusal that arrived at the last moment); and two the owner
gives a "not known" row later: **arrived** (it is in the chat) and **left** (the owner's "leave it").

Every transition is ONE statement that names the state it leaves (a compare-and-set), in one transaction
with whatever goes with it, and reports whether it happened. No read-then-write.

Doors in `internal/catalog` (plain types of the catalogue's own: the catalogue must not import
`internal/telegram`; the viewer imports the catalogue and has an import wall, `TestWallDependencies`):

1. **Queue a click:** inserts the row and its message rows as "queued" in one transaction and returns
   the ref. It refuses, with fixed-word errors and nothing written: a kind it does not know, a text for a
   kind without one, a forward or delete without messages or with a repeated id, a random id of 0, an
   account or chat that is not in the catalogue.
2. **The next click to send** for an account: the oldest "queued" row with everything the request needs
   (the caller builds the request layer's `Action` from it). It does not change the row.
3. **Begin:** queued to sending, with the time. Not queued: the "spent" answer. This is the statement
   that makes "one click, one request" true: get it exactly right and test it with two connections at once.
4. **End:** sending to an end state with everything the outcome carries (per message the new ids of a
   forward), and the text cleared as section 5 says. A row that is not "sending": refused, nothing
   changed, said to the caller (an `End` must never overwrite an end state).
5. **Not sent:** queued to "not sent" with its reason word (and a wait's end where there is one): for the
   request layer's local "no", for the owner's cancel of a queued click, and for the two sweeps below.
6. **The start's sweep,** one call at a program start, before anything is sent: every "sending" row
   becomes "not known" with the type word "the program ended while it was out" (never queued again, never
   sent again by the program); every "queued" row becomes "not sent" with the reason "the program stopped
   before it was sent" (a click must not go out hours after it was made). It returns the two counts.
7. **The age sweep:** queued rows older than a bound the caller gives (the turn will pass 2 minutes)
   become "not sent" with the reason "not sent in time". Returns the count.
8. **Sent since:** per account, the clicks marked "sending" at or after a time, whatever became of them,
   each with kind, chat and that time, oldest first, bounded (the caller asks for a window; give a hard
   upper bound of rows and an error past it rather than a silent cut).
9. **The last remembered refusal** of a chat for a kind at or after a time: only rows in state "refused"
   with `remember` set; the word and the time.
10. **The owner's verdict on a "not known" row:** to "arrived" or to "left". Only from "not known".
11. **Send again:** from a row in "not known", "waited", "not sent" or "refused", a NEW queued row with
    the same content and **the same random ids** (so Telegram can refuse a repeat), pointing at the row
    it repeats; the old row is not changed by it. Refused from any other state, and when the old row's
    text was already cleared for a kind that needs one. One statement decides and inserts (no window in
    which two "send again" clicks of one row both pass: at most one live repeat of a row at a time, where
    "live" is queued or sending).
12. **A chat's rows, read-only,** for the page that draws them: by account and chat, newest first, a
    limit, each row's state, kind, times, the wait's end, Telegram's word, the target or new message id,
    `partly`, the reason word; with the text only where it is still kept. And one row by its ref.

The adapter in `internal/tgstore` (beside the `ForwardStore`): a small type that implements
`telegram.ActLedger` on doors 3, 4, 8 and 9, mapping `telegram.ActOutcome` to the row and the catalogue's
"spent" answer to `telegram.ErrClickSpent`. **Build it last, after merging `private/wip/core-act` into
your branch once its report has the section "The fix round"** (the fix round adds `Remember` and `Partly`
to `ActOutcome`, a new outcome "not sent" that `End` may now be given, and says the chat is keyed by kind
and id only). If that section is not there when you reach this point, build the adapter against
`BRIEF-K8b-fixes.md` sections 2 to 4, say so in the report, and leave the merge to me.

## 5. The text

A message's text is the most private thing this table holds. It is in the row from the click until the
row reaches a state in which the message exists at Telegram or the owner is finished with it: cleared (set
to NULL in the same statement) at "done", "not modified", "sent before", "arrived", "left"; kept at
"waited", "refused", "not sent" and "not known", because the page offers "send again" from those; and
cleared from those too when a "send again" row has been made from it (the new row carries it) or when the
row is older than 7 days (one bounded statement the start's sweep runs). No door returns a text except
door 2 (to build the request) and door 12 where it is still kept. No error text, log line or test output
of this piece holds a text, a name or an id from a row: fixed words and counts.

## 6. Tests

Named tests in `internal/catalog` (`TestAct...`) and `internal/tgstore` (`TestActLedger...`), on invented
rows, written the way the real writers write them (through the doors, never by hand-made rows, except
where a test needs an impossible state). At least: the step applies on a file at the step before and is
refused at any other; each transition from every state it must refuse; `Begin` from two connections at
once on one row (exactly one wins; run it 200 times in a loop in the test); `End` twice; the two sweeps
(and that a swept row can never be begun); "send again" twice at once on one row (exactly one new row);
the same random ids on the repeat; the text's life state by state, and after 7 days; "sent since" at the
window's edge and past its bound; the remembered refusal only with `remember`; door 12 never returning a
cleared text; the viewer's wall still holding (`go test -count=1 -run TestWallDependencies ./internal/viewer/`:
it may fail for a reason that is not yours, a known open point on the main branch tonight: if it fails,
check that the failure does not name your files and say so).

**Run while working, and only these** (the PC is shared: before each go command read free memory with
`powershell -NoProfile -Command "[int]((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1024)"`
and wait if it is under 2,500 MB; `GOGC=25 GOMAXPROCS=2` before go commands; Go through
`source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`): `go build ./...`; `gofmt -l`
and `go vet` on the two packages; your tests by name; the catalogue's existing schema tests by name
(`-run 'Schema|Migrat|Step'`: look at their names first). No whole-package run (the catalogue's takes
3.5 minutes and is mine, once), no race detector, no Docker.

## 7. Hand-back

- Commits with `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, each message ending
  with a blank line and `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; pushed with
  `git push private wip/core-ledger`; `git status --short` empty at the end.
- A report on the branch, `archiver/docs/progress/core-ledger-REPORT.md`: the tables as built (every
  column and index with one line of why); each door's name, its one statement, and its contract in a
  line; the state diagram as a table (from, to, by which door); how the catalogue tells an outgoing
  message of the account's own from someone else's (the second half must refuse an edit or a delete of a
  message that is not the account's own before a click is queued: say which column or rule gives that,
  or that nothing does today); whether the account's own user and Saved Messages are in the chat tables
  after a sign-in (the request layer addresses it as a user chat); anything in this brief you found
  wrong, said plainly: check a door in the code before you rely on my word for it.
- Your final message: the head's full hash, the test commands with results and seconds, the files, the
  open points. No path of this PC inside the report file (it goes into the pushed documents).
