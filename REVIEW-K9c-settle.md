MAY BE LISTED AFTER THE MUST-FIXES

# Independent review of K9c: a "not known" click settled from what the chat shows (2026-11-16)

Reviewed: `wip/core-settle` at cee2e466 against 82d67475 (`git diff 82d67475 cee2e466`), read in full, with the
design (section 5), the brief, `schema_act.go`, the store's write path (`tgrows.go` `SaveMessages`/`saveOne`,
`MarkDeleted`), the record (`internal/telegram/record.go`), the mirror's `sourceKeys`, and the collector's turn.
Nothing in the copy was changed. Probes are in the review scratch folder (`wt-core-settle-review-scratch`):
`probe_k9c_test.go` (package catalog, loaded with `-overlay overlay-catalog.json`), and `click_test_settle_on.go`
(the coder's `click_test.go` with the four `settleOff` lines removed, `-overlay overlay-collector.json`). Their
outputs: `probe-catalog-run3.txt`, `collector-settle-on-run.txt`, `collector-settle-run.txt`. All data invented.

Count: 2 MUST FIX, 3 SHOULD FIX, 6 MINOR. Every MUST and SHOULD is CONFIRMED by a probe.

The answer to the question that matters most: yes. The app says "arrived" (and stops a repeat as "the earlier try is
in the chat") for a click that was not carried out in at least these cases that are NOT the design's accepted
residual: a chain whose tries are hours apart (finding 1), a forwarded message taken for a send (finding 2), another
click's message missed by the content check when the PC's clock runs ahead (finding 3), a "delete for everyone"
(finding 4), a photo with that caption (finding 5).

## Findings

### 1. MUST FIX, CONFIRMED: the window is the hull of the whole chain, not the window of each try

`internal/catalog/act_settle.go:267-286` (`settleWindow`: `MIN(sending_ms)` to `MAX(sending_ms)` over the chain's
"not known" rows), used by `SettleClicks` (line 704) and `SettleRepeat` (line 823); candidates read over that one
range (line 375).

For the owner: a click sent, lost, and sent again hours later (the design's own case: "ids ... were free six hours
later") is marked "arrived", or its next repeat is stopped as "the earlier try is in the chat" and can no longer be
sent again, because of a message of the same text the owner wrote at any time between the tries, far outside every
try's 5 minutes. Short common texts ("ok", "thanks") make this likely; the hull can span up to the 7 days a text is
kept.

Probes (package catalog):
- `TestProbeK9cChainHullArrived`: try 1 "not known" at S, try 2 "not known" at S+2 h, the owner's own message of the
  text at S+1 h. Output: `tip: state "arrived" why "found in the chat by the app" new_msg 11`.
- `TestProbeK9cChainHullRepeat`: the same, then try 3 queued at S+3 h. Output: `repeat check: ended true; third
  try: state "not sent" why "the earlier try is in the chat" new_msg 21`; `send again of the third try: catalog: the
  click is not in a state this door takes`.

Smallest fix: a candidate is in the window when its date is within [m - 30 s, m + 5 min] of SOME "not known" mark m
of the chain (a union of windows, not their hull): return the marks, put one `date BETWEEN` range per mark (OR) in
`settleCands`, and give `settleOthers` the same per-mark spans. Edit and delete keep "at or after the earliest mark".
A test with two tries hours apart and a message between them.

### 2. MUST FIX, CONFIRMED: a forwarded message is taken as a send's message (also the app's own forward click's copy)

`internal/catalog/act_settle.go:407-408` (the send's candidate condition has no `fwd_origin` condition); the content
check compares only clicks of the same kind (line 514, `o.kind = ?`); `tiedSQL` (338-341) excludes a forward's copy
only once a tie is recorded.

For the owner: a send that never went out is "arrived" on a forwarded copy of a post whose text is the click's: the
owner's own forward from the phone, or the copy of the app's own forward click that is itself "not known". In the
second case the forward that DID arrive is then left "nothing found" (its copy is now tied to the send): two wrong
answers. A message carrying a forward header can never be a send's message, so this match is not exact.

Probes: `TestProbeK9cForwardedCopyForSend` (the owner's forward): `send: state "arrived" ... new_msg 31`.
`TestProbeK9cForwardClickCopyForSend` (a send click and a forward click of a post with that text, both "not known";
only the forward's copy stored): `send: "arrived" why "found in the chat by the app" new 51; forward: "not known"
copy 0`; the forward's candidates: `{Cands:[] Arrives:false Why:nothing found}`.

Smallest fix: `AND m.fwd_origin IS NULL` in the send's condition (line 407). A test with each case above.

### 3. SHOULD FIX, CONFIRMED: the content check's span ends 30 s after the window on the PC's clock; candidates are dated on Telegram's

`internal/catalog/act_settle.go:515-516` (`COALESCE(o.sending_ms, o.clicked_ms) BETWEEN lo - actOtherSpanMs AND
hi + ActSettleBeforeMs`), against candidate dates that are Telegram's `message.date` (line 353) while `lo`/`hi` are the
PC's marks (line 285).

For the owner: with the PC's clock ahead of Telegram's, another click of the same text marked a little after the
window carries a message dated inside it; that click is not counted, and the first click is "arrived" on the other's
message (the other is left "not known"). With the clock behind, the window reaches further back before the real
request (an earlier own message counts). Neither clock is mentioned in the brief or the report.

Probe `TestProbeK9cClockAheadOtherMissed` (clock 2 min ahead: B at S, A at S+6 min, only A's message, dated S+4 min):
`B: "arrived" new 91; A: "not known"`.

Smallest fix: make the span symmetric and wide on both sides (`hi + actOtherSpanMs`, as before the window), which only
leaves more rows to the owner. Better, later: estimate the Telegram-to-PC offset from the store (recent own messages'
`Seen` against `Date`) and shift the window by it; say in the report that sends and forwards compare two clocks.

### 4. SHOULD FIX, CONFIRMED: a "delete for everyone" in a private chat or basic group is settled on a deleted mark that cannot tell for whom

`internal/catalog/act_settle.go:450-464` (every message `deleted_at` at or after the mark; `Revoke` never read).

For the owner: a lost "delete for everyone" that was not carried out is "arrived" when the monitor sees the message
deleted for another reason: the owner's own "delete for me" on another device (Telegram reports it the same way in a
private chat or basic group). The owner believes the other side can no longer see it; they can. (An admin's delete in a
supergroup, the other side's delete for everyone, or an auto-delete timer have the same effect as the click: harmless.)

Probe `TestProbeK9cDeleteRevoke`: `delete (revoke true): "arrived" why "found in the chat by the app"`.

Smallest fix: no app verdict for a delete with `Revoke` in a chat whose catalogue kind is `user` or `group` (left to
the owner, "nothing in the catalogue tells this kind"). The brief is silent on revoke.

### 5. SHOULD FIX, CONFIRMED: a message with media is a candidate for a text send

`internal/catalog/act_settle.go:407` (no condition on attachments). For the owner: a photo the owner sent from the
phone with the click's text as its caption marks the lost text send "arrived". Probe `TestProbeK9cMediaCaption`:
`send: "arrived" why "found in the chat by the app" new 81`.

Smallest fix: `AND NOT EXISTS (SELECT 1 FROM attachment a WHERE a.message_id = m.id)`. A send whose text has a link
preview (an attachment of a web page) then waits for the owner: one click of theirs, never a wrong word.

### 6. MINOR, CONFIRMED: a message first written with another text and edited to the click's text is a candidate

`internal/catalog/act_settle.go:407`. Probe `TestProbeK9cEditedCandidate`: `send: "arrived" ... new 61`. Fix:
`AND NOT EXISTS (SELECT 1 FROM message_version v WHERE v.message_id = m.id AND v.text <> ?)` (the click's text).

### 7. MINOR, CONFIRMED: a forward's topic is not compared

`internal/catalog/act_settle.go:424` (the forward's condition is the origin only; the send's has the topic). Probe
`TestProbeK9cForwardOtherTopic` (a forward to topic 77; the only copy in topic 78): `"arrived" copy 201`. Fix: the
same topic condition as the send's (`COALESCE(m.topic_id, 0) = ?`, mapped through `topic`).

### 8. MINOR, PLAUSIBLE: the content check for forwards does not count another forward whose keys cannot be read

`internal/catalog/act_settle.go:479-480` (`forwardKeys` returns all-empty keys when the other click's source chat is
no longer in the catalogue) and 585-590 (an empty key is never "the same"). Less conservative than the cleared-text
rule (line 575: what cannot be compared counts). What would show it: a forward click whose source chat is removed from
the catalogue after it was queued, then a second forward of the same post. Fix: an other forward with an empty key on
an untied message counts as the same.

### 9. MINOR, PLAUSIBLE: the collector's pace forgets rows pending on earlier pages

`internal/collector/click.go:993` (`settlePending = res.Pending > 0` from the last page only; `settleNewest` likewise).
With more than 50 rows to look at, rows pending on the first page are not looked at again until a click of this
session ends "not known" or the next session starts. Cost: only "still not known". Fix: keep the pages' Pending and
NewestMs until the sweep's last page.

### 10. MINOR, by reading: a repeat stopped "the earlier try is in the chat" has no way back for the owner

`internal/catalog/schema_act.go:1161` refuses "send again" of it; `ClickVerdict` takes only "not known"; the earlier
rows are closed (they have a repeat). When the stop is wrong (finding 1, or the design's residual below) the owner can
only type the message again as a new click. Suggest: let "send again" with the owner's explicit "try again" pass this
guard, and show the matched message beside the stopped repeat. A decision for the owner.

### 11. MINOR, CONFIRMED: one of the four K9b tests did not need the settle off

`internal/collector/click_test.go:992` (`TestClickOutcomeLost`): it passes with the settle on (it never looks at the
row again after the clock passes). The other three fail exactly as the report says when the settle is on, each
because the fake carried the lost send out and the settle rightly finds it: `TestClickOutcomes` ("sent before" became
"not sent ... the earlier try is in the chat"), `TestClickKillAndRestart` ("arrived" after the restart),
`TestClickTipOnly` (same as the first). So the changes are the tests' own need and hide nothing; the one comment is
inaccurate. Run: `collector-settle-on-run.txt`.

## What I checked and found sound (not to be checked again)

- One transaction per row, and the judgement inside it: `Batch` takes the writer's one connection with
  `_txlock=immediate` (`catalog.go:136`, `:188-199`), so nothing can be written between the reads and the UPDATE,
  in this process or another. A failure rolls the row back whole (no "arrived" row with its copies untied, nor the
  reverse). `SettleRepeat` is one transaction too.
- The three writing statements name the state they leave: "arrived" only from "not known" with no repeat (line 717-718);
  ties only while the row is in the state judged (754-755); the repeat only from "queued" (831-832). The race with the
  owner's verdict is tested on two handles (`TestClickSettleRaceVerdict`).
- `judgeSettle` (181-262), branch by branch: no combination answers "arrive" when an entry has more than one candidate
  in the window or none (a tied entry counts as found, which is right); a "cannot tell whose" candidate, a key twice in
  one forward, or any content-check word blocks; a forward needs every message. The candidate reads are bounded at 21
  in the window, so "more than one" is never cut to one.
- A message tied to another click is excluded in every read (settle, repeat, the page's door): a send's `new_msg` in
  any state, a forward's copies, every row of another chain; the click's own chain is not excluded (right: its earlier
  try may be the one). Another click's message not on record blocks (`ActNoneOtherOut`), also when its text was cleared
  or it is a closed row of a chain (every row of the other chain is examined, not only the tip).
- Text: byte for byte. The request layer sends `act.Text` unchanged (only an empty/length check, `telegram/act.go:126`);
  the record takes `m.Message` as it is (`telegram/record.go:221`); `saveOne` stores it as it is; `message.text` has
  the default binary collation. No normalisation on either side; a text Telegram changes simply does not match. The
  text is present when needed: `TextKept` is checked (a cleared text: nothing found), the repeat carries it, and the
  7-day clearing is beyond the 24-hour span.
- The own-message rule matches the turn's: `outgoing` in private chats and basic groups (private spaces, one account
  each), the sender equal to the account's user in supergroups and forums (a second account's message there is not
  own), no candidate when the account's user id is unknown, "cannot tell whose" in a broadcast channel and any other
  kind. A message of another chat with the same number is in another space. A message dated before the window but
  stored later is judged by its date.
- The mirror's forwards cannot meet a click: a click into a mirror chat is refused before its request (`ActWhyMirror`).
- It sends nothing: `act_settle.go` imports only `context`, `database/sql`, `errors`, `fmt`, `strconv`, `strings`; the
  collector's `clickSettle` and `clickRepeatFound` call catalogue doors only, no pass, no Actor, no connection. Re-run:
  `go test -run TestClickSettle ./internal/collector/`: 4 pass in 2.8 s (one send at the fake in each).
- A failing settle never stops a click or the reader (`TestClickSettleFails` passes); a failing repeat check ends the
  repeat "not sent: a stored value cannot be read", which is true and leaves "send again" open.
- Cost: the send's candidates use `message_space_date`; the forward's the origin or the date index; the ledger's reads
  use `c_act_sent`, `c_act_chat`, `c_act_again`; no scan of the `message` table, except that the hull of finding 1 can
  make the date range days wide in a busy chat (fixed with it).
- Privacy: the four new log lines are constant formats with the account number, counts, the kind's word and a fixed
  error word; errors carry a click's ref at most; counts carry numbers. No text, chat or message number.
- `TestClickCancelRaceCounted` waiting for the chat list: a test-side need (the queue door takes only a chat of the
  catalogue); I could not show whether the race existed before this piece.

## What I could not check

- Telegram's real dates against the PC's clock, and what Telegram does to a text (trim) or to a delete "for me" in
  each chat kind: only by reading (findings 3 and 4 are built on the store's own writers, not on a real run).
- How the page shows "found in the chat by the app", the candidates and a stopped repeat (not in this piece).
- Cost on a large real catalogue (no large fixture run); the race detector; whole-package runs (not allowed here).

## Where the brief or the design is wrong or silent

- The design says the message is looked for "after the request"; the brief opened the window 30 s before the mark,
  so the owner's own identical message typed just before clicking counts. Keep it only if the clock offset is the
  reason, and then say so.
- The brief does not say which window a chain uses; its 3.2 ("the 'not known' rows of its chain") led to one hull
  (finding 1).
- "Same content" is defined per kind: the brief misses that a send's candidate can be a forward, a photo or an edited
  message (findings 2, 5, 6), and that the forward's topic matters (finding 7).
- Silent on a delete's revoke (finding 4) and on the two clocks (finding 3).
- The design's accepted residual, unchanged by any fix above: when the click did not go out and the owner sent the
  same text from another device within the 5 minutes, the app says "arrived" (and stops a repeat). Short common texts
  make it likely. A guard costing no request, for the owner to decide: no app verdict when the account's own messages
  of the same text already appear in that chat before the window (a text the owner repeats).

## Second pass (the fix round, 78b9c76c)

MAY BE LISTED AFTER THE MUST-FIXES

Reviewed: `git diff cee2e466 78b9c76c` only, with `BRIEF-K9c2-fixes.md`; the report's section 10 read last. Nothing in
the copy was changed. New probes in the scratch folder: `probe_k9c2_test.go` (P9 to P11), run together with the first
pass's `probe_k9c_test.go` on the new head (`overlay-catalog2.json`, output `probe2-catalog-run1.txt`). Fixes undone
by overlay: `act_settle_undo.go` (eight of the fixes undone in one copy, `overlay-undo.json`, output `undo-run.txt`) and
`click_undo9.go` (the pace, `overlay-undo9.json`, output `undo9-run.txt`). The collector's `TestClickSettle*` and
`TestClickOutcomeLost` on the new head: 7 pass, 4.6 s (`collector2-run.txt`).

Count: 1 new MUST FIX, 4 new SHOULD FIX, 3 new MINOR. The 11 first-pass findings: 8 CLOSED, 3 PARTLY.

### The 11 first-pass findings

| # | Status | By code | Test that fails with the fix undone | My probe on 78b9c76c |
|---|---|---|---|---|
| 1 | CLOSED | `settleWindow(mark)` per row (act_settle.go:299-305); `SettleRepeat` judges each "not known" row on its own mark (917-958) | `TestClickSettleFix1ChainTries`, `...Fix1ChainRepeat` (not undone by overlay: the window was rewritten; by reading, the old hull puts the message in the window and the 7-day guard reads only before the hull's start, so both would fail; the coder saw them fail on the old code) | P1: tip "not known"; P2: repeat not stopped, stays queued |
| 2 | PARTLY | `m.fwd_origin IS NULL` (426) | `TestClickSettleFix2ForwardedCopy`, `...Fix2ForwardClickCopy`: fail when undone | P3a, P3b: send "not known", forward found. Still open: a forward with no origin (new finding B) |
| 3 | CLOSED for clock offsets up to 5 min 10 s | span `hi + actOtherSpanMs` (601) | `TestClickSettleFix3ClockAhead`: fails when undone | P7: neither settled |
| 4 | CLOSED | `ActNoneRevoke` for user and group chats (479-484) | `TestClickSettleFix4DeleteRevoke`: fails when undone | P5: "not known" |
| 5 | CLOSED | no `attachment` row, `self_destruct`/`skipped_media`/`unusable_media` 0 (426-427) | `TestClickSettleFix5Media`: fails when undone | P6: "not known" |
| 6 | PARTLY | no `message_version` row (428) | `TestClickSettleFix6Edited`: fails when undone | P4: "not known". Still open: a message stored only after its edit (new finding C) |
| 7 | CLOSED | the forward's topic (452) | `TestClickSettleFix7ForwardTopic`: fails when undone | P8: "not known" |
| 8 | CLOSED | `forwardKeys` says which keys are not known; they count (672) | `TestClickSettleFix8OtherKeyUnknown`: fails when undone | none |
| 9 | CLOSED | `settleTook` adds the pages up (click.go:1000-1020) | `TestClickSettlePacePages`: fails when undone ("after the last page: pending false") | none |
| 10 | PARTLY | `ClickNotArrived`; `SendClickAgain` with "try again" over the stop | `TestClickSettleOwnerNotArrived`, `...OwnerSendsAgainOverStop`, `TestClickSettleOwnerWayBack` | the way back exists, but the owner's word is overridden through a sibling row (new finding A), and "try again" also lifts the chat's refusal (new finding D) |
| 11 | CLOSED | `settleOff` removed | `TestClickOutcomeLost` passes with the settle on | none |

### New findings

**A. MUST FIX, CONFIRMED: "it is not in the chat" does not reach the chain's other tries, and the next repeat is stopped on the very message the owner rejected.**
`internal/catalog/act_settle.go:972-986` (`ClickNotArrived` gives `ActOwnerSaidNot` to the tip only). The repeat's
check (917-918) then reads every other "not known" row of the chain on its own window. Two tries 30 s apart have
overlapping windows. For the owner: the app marked the tip "arrived"; the owner said "it is not in the chat" and sent
it again; the app ended that repeat with "the earlier try is in the chat", on the message the owner had just rejected.
That is the costly class: the message is never sent unless the owner notices and uses "try again". Probe
`TestProbeK9c2OwnerSaidNotSibling`: `repeat: "not sent" why "the earlier try is in the chat" new 71; first try: why ""`.
`SendClickAgain` over the app's stop already does the right thing (schema_act.go:1197).
Smallest fix: in `ClickNotArrived`, in the same transaction, give `ActOwnerSaidNot` to every "not known" row of the
chain (the statement at schema_act.go:1197). The probe becomes the test.

**B. SHOULD FIX, CONFIRMED: a forward whose header names no peer is read as "not forwarded" (the rest of finding 2).**
In `internal/telegram/record.go:281-297`, `forwardOrigin` returns "" when the forward header has no `from_id` and no
saved-from peer: an author who hides forwards, which is common for private users. `nullStr` then stores NULL
(`catalog/rows.go:175`), so `m.fwd_origin IS NULL` at `act_settle.go:426` passes it. The content check still compares
sends with sends only (`act_settle.go:599`, `o.kind = ?`).
For the owner: a send that never went out is "arrived" on the copy made by the app's own forward click. That click
forwarded a message of a private chat or group whose text equals the send's. The forward itself can never be found
there ("the forward names no post").
Probe `TestProbeK9c2HiddenAuthorForward`: `send: "arrived" ... new 51; forward: "not known"`.
Smallest fix: the content check for a send also counts the account's forward clicks into that chat, by the same time
rule: queued, sending or "not known", or gone out with a copy not on record. To also cover such a forward made by hand,
the forward header would have to be read from `message_raw`; until then that case is not plain text but sits with the
design's residual.

**C. SHOULD FIX, CONFIRMED: "never edited" misses a message first stored after its edit (the rest of finding 6).**
`act_settle.go:428` reads edits only from `message_version`. A message the store first sees already edited is
inserted once, with its `edit_date` and no version row (`catalog/ladder.go:261-266`). This happens when the owner edits
on another device before the monitor saves the message, or across a gap in the monitor.
Probe `TestProbeK9c2EditedBeforeStored`: `send: "arrived" ... new 61`.
Smallest fix: add `AND m.edit_date = 0` (keep the version condition).

**D. SHOULD FIX, CONFIRMED (the tree's own test plus reading): "send again" over the app's stop also lifts the chat's remembered refusal.**
`internal/catalog/schema_act.go:1162` writes the call's `tryAgain` into the new row's `try_again`. That one flag is
also the owner's "try again over the chat's remembered refusal": rule R7 is skipped when it is set
(`internal/telegram/act.go:745`). `act_settle_fix_test.go:316` asserts `TryAgain` on that repeat.
For the owner: undoing the app's stop silently also sends into a chat that refused this kind (for example
CHAT_WRITE_FORBIDDEN), and the refusal is not shown first. The cap, the age, the waits, the account's refusal, frozen
and the mirror rule still hold.
Smallest fix: when the old row is the app's stop, the new row takes the old row's `try_again`
(`CASE WHEN o.state = 'not sent' AND o.why = ? THEN o.try_again ELSE ? END`). "Not stopped again" already rests on the
previous row (act_settle.go:914) and on the chain's word.

**E. SHOULD FIX, PLAUSIBLE: the 7-day guard sees only what the catalogue holds.**
`act_settle.go:535-545` counts the account's own messages of that text in the 7 days before the window, in the
catalogue. If the chat's last 7 days are not stored (its history not read back, the account newly added, a gap in the
monitor), the guard finds nothing and the app's verdict goes ahead for a text the owner did send there before. That is
beyond the residual as accepted ("had not sent it in that chat in the 7 days before").
What would show it: a chat whose read cursor does not reach 7 days back.
Smallest fix: no app verdict unless the catalogue holds the chat back to the guard's start (the account's
`account_chat` read cursor reaches it, or the monitor ran with no gap since). Otherwise the candidate is shown with
`ActNoneRepeated` or a word of its own.

**F. MINOR, PLAUSIBLE: the guard's cost.**
`act_settle.go:540-541` walks `message_space_date` newest first and filters for the account's own messages after the
index. In a busy supergroup where the account rarely writes, it reads every message of the 7 days before reaching 2,000
own ones. It runs inside the write transaction, at every round while a click is young, even when the window has no
candidate. Fix: run the guard only when the window holds exactly one candidate.

**G. MINOR, by reading: a text with a link is mostly not findable.**
A web page preview with a photo or document is an attachment (`telegram/record.go:387-393`). A preview filled in after
the message arrives makes a version row. Either one excludes the message. This is the careful side, costing the owner
one click; say so in the report. If wanted later: allow an attachment whose raw media is a web page.

**H. MINOR, CONFIRMED: the previous-row check in `SettleRepeat` (act_settle.go:914) is not tested.**
With it undone, `TestClickSettleOwnerSendsAgainOverStop` still passes, because the chain's "not known" rows already
carry the owner's word. It is a second guard. Keep it with a test of its own (a chain whose earlier rows are not
"not known"), or drop it.

### The question again, on the new match

Yes, still. Outside the accepted residual, the app can still say "arrived" or "the earlier try is in the chat" for a
click not carried out:
- after the owner has said "not in the chat" (A);
- on the app's own forward copy of a message with no origin (B);
- on a message edited before it was stored (C);
- for a repeated text whose earlier sending is not in the catalogue (E);
- with the PC's clock more than 5 min 10 s ahead (finding 3's span then misses the other click again; very unlikely).

The new conditions hold otherwise:
- **Overlapping tries:** the tip takes a message in its own window. Only a repeat's check reads an earlier try's
  window, and one chain carries one random id. Two chains with overlapping windows block each other.
- **The plain-text columns:** NULL against empty is right for `fwd_origin`; the media counters are NOT NULL; service
  messages are excluded.
- **10 s before the mark:** fine.
- **The guard's bounds:** the 2,000 cap fails to the careful side. In a broadcast channel nothing settles anyway. In a
  supergroup with no known user id there are no candidates.

Beyond the coordinator's narrow sentence, the design also accepts the same post forwarded by hand inside the window,
with no 7-day guard for forwards. An edit made on another device, or a delete by someone else, has the same effect as
the click.

### The owner's way back (section 6)

- **`ClickNotArrived`:** one statement naming the state and the app's word, the copies untied, in one transaction.
  Nothing settles that row again: the listing, `settleOne` and the arrive statement's `why = ''` all exclude it. Only
  its siblings in the chain are still read (A).
- **Texts:** kept on an app-made "arrived" and on a stopped repeat. The 7-day rule still clears them (`clearOldTexts`
  does not look at the state). The read doors return them to the page by design; no log carries them.
- **`SendClickAgain` with "try again":** one transaction. Silencing every "not known" row of the chain only means a
  later repeat is not stopped by them; it then goes out under the same random id, which is the careful side. It is
  bound by everything except the chat's remembered refusal (D).
- **`ClickVerdict` resetting `why`:** a "not known" row can only carry "" or the owner's word, so nothing a page needs
  is lost beyond the history of a rejected match.
- **Doors out:** every state has one, except a row whose text the 7-day rule cleared, as before.

### The coder's readings (section 10)

1. A tip is judged on its own window only; the repeat's check stops on any try found: acceptable.
2. The guard counts any own message of the text (media, forwards) and also holds for the repeat's check: acceptable
   (the careful side).
3. Every "not known" row of the chain takes the owner's word on "try again": acceptable. `ClickNotArrived` must do the
   same (A).
4. Finding 8 also covers a source message not on record: acceptable (the careful side; the click's own key is
   unaffected).
5. `ClickVerdict` sets `why` back to "": acceptable.

## Third look (the second fix round, 97866e9f)

MAY BE LISTED

Reviewed: `git diff 78b9c76c 97866e9f` only; the report's section 11 read last. Nothing in the copy was changed. All
probes were re-run on 97866e9f together with three new ones (`probe_k9c3_test.go`, P12 to P14), using
`overlay-catalog3.json`; output in `probe3-catalog-run1.txt`. The coder's `TestClickSettleFix2*` tests: 8 pass
(`fix2-tests-run.txt`). There is no MUST FIX. The three new SHOULD FIXes are small and best taken in one more short
round before the owner relies on the app's own word.

### A to H

| | Status | Evidence |
|---|---|---|
| A | CLOSED | P11 on 97866e9f: `repeat check: ended false; repeat: "queued"; first try: why "the owner said it is not in the chat"`. `ClickNotArrived` gives the word to the whole chain (act_settle.go:1157-1178, `ownerSaidNotChain` schema_act.go:1229-1232); `TestClickSettleFix2AOwnerSaidNotChain` |
| B | CLOSED for the app's own clicks | P9: send "not known". The content check of a send counts any forward click of the account into the chat (act_settle.go:727-748). A hidden-author forward made by hand on another device stays with the residual; the report now says so |
| C | CLOSED | P10: "not known" (`m.edit_date = 0`, act_settle.go:435) |
| D | CLOSED | "try again" alone over the app's stop is refused; "not in the chat" alone leaves `try_again` 0 (schema_act.go:1156-1225); `TestClickSettleFix2DTwoWords`, `TestClickSettleOwnerSendsAgainOverStop` |
| E | PARTLY | the guard now needs the chat on record (act_settle.go:545-563), but it ignores open gaps (finding J) and takes one stored old message as proof (finding K) |
| F | CLOSED | the guard is read only for a send that would settle, outside the write transaction, and is bounded to 5,000 rows of any sender. Reaching 5,000 is "repeated" on its only path (act_settle.go:583) |
| G | CLOSED | stated in the report, section 11 |
| H | CLOSED | `TestClickSettleFix2HPreviousRow` |

First-pass probes P1 to P8 and second-pass probes P9 to P11 all give the careful answer on 97866e9f.

### Questions 2 to 5

- **A, rows in other states and later rows:**
  - Only "not known" rows are ever judged, so rows of the chain in other states cannot settle or stop anything.
  - A new try added by "send again" does not inherit the owner's word; it is judged afresh on its own window. That is
    right, because the new request may truly arrive.
  - But the message the owner rejected is untied and forgotten, so the new try can take it (finding I).
- **D:**
  - "Try again" alone cannot repeat a stopped row, and "not in the chat" alone cannot lift a chat's refusal.
  - "Not in the chat" on an ordinary "not known" tip gives the owner's word to the whole chain, including that tip.
    The only effect is that the new repeat is not stopped by those rows: it goes out under the same random id, and
    Telegram refuses it as a repeat where it remembers the id. That is the careful side, and acceptable.
- **E and F, the read before the transaction:**
  - The transaction gathers the candidates afresh and judges again; only the guard's word is carried over.
  - A row that would now settle without a guard having been read is left for the next look (`actGuardLater`).
  - The guard depends only on the text, the window's start and the chat, not on the candidates. Its answer can be stale
    only if an older own message of the same text is stored in the milliseconds between the read and the transaction
    (finding L, minor).
- **"The read is done" as a test of "the last 7 days are on record":** fair for a chat read to its end and followed
  live without a break. Not fair after the collector was off: the catalogue records such breaks in `tg_gap` (open while
  `done_at` is NULL, indexed by `tg_gap_open`), per chat and for the common box of private chats and basic groups, and
  the guard does not look at it (finding J).
- **The coder's three departures:**
  - D, two catalogue doors over one function: acceptable.
  - E, gaps not looked for: not acceptable (finding J).
  - B, every forward click counts: acceptable (the careful side).

### New findings

**I. SHOULD FIX, CONFIRMED: the message the owner rejected can be taken again by the next try's own window.**
`ClickNotArrived` (act_settle.go:1159-1168) and "not in the chat" over a stop (schema_act.go:1207-1210) set
`new_msg` to NULL, so nothing remembers which message was rejected. The next try is judged on its own window, which
starts 10 s before its mark. If the owner rejects and sends again within about 10 s of the message's date (more with a
PC clock behind Telegram's), the new try is "arrived" on that same message.
Probe `TestProbeK9c3RejectedMessageNewTip`: `new try: "arrived" why "found in the chat by the app" new 81`.
Smallest fix: keep the rejected message on the row instead of clearing it (`new_msg`, and a forward's `c_act_msg.new_msg`),
and let `tiedSQL` (act_settle.go:361-364) count a row carrying the owner's word, or a stop sent again "not in the
chat", as tied for every chain, its own included. The probe becomes the test.

**J. SHOULD FIX, CONFIRMED: an open gap of the live monitor does not block the guard.**
`settleGuard` (act_settle.go:552-563) checks only `account_chat.cur_done`, or a stored message older than the guard's
start. After the collector was off, or after a difference Telegram refused as too long, the catalogue records open gaps
in `tg_gap`, and the 7 days may be missing exactly there.
Probe `TestProbeK9c3OpenGap`: a gap open for the chat and one for the common box; the send settles: `"arrived" ... new
91`.
Smallest fix: `ActNoneUnrecorded` while the account has an open gap for that chat. For a private chat or basic group,
an open common-box gap (chat kind 0, chat 0) also counts. One read on `tg_gap_open`.

**K. SHOULD FIX, PLAUSIBLE: one stored old message makes the 7 days "on record".**
The fallback `SELECT MIN(date) FROM message WHERE space_id = ?` (act_settle.go:558-563) is true as soon as any message
older than the guard's start is stored, even with nothing read since. Isolated old messages are stored in ordinary use:
any edit of an old message comes from the monitor with the whole message, and `saveOne` stores a message it does not
hold as new (tgrows.go:280-290).
Probe `TestProbeK9c3OneOldMessage` (never read; one month-old message of someone else): the send settles.
What would show it in real use: an edit of an old message in a chat whose history is not read.
Smallest fix: drop the fallback, or use the read cursor instead: the pass's lowest message read (`cur_down_to`) dated
at or before the guard's start, together with J's check.

**L. MINOR, PLAUSIBLE: the guard's word is read before the transaction.**
`settlePreOf` (act_settle.go:905-920) reads the guard outside; the transaction (881) uses that word. An older own
message of the same text stored in between (the history read's page) is not seen this time. The window is
milliseconds. Fix if wanted: inside the transaction, re-run only the guard's cheap count when the outside read found
nothing.

### What remains accepted, in one sentence

When a send did not go out and, inside its own window, the owner sent the same plain text in that chat by hand from
another device, a text not sent there in the 7 days before (those days on record, with no open gap once J is fixed),
the app says "arrived" or stops a repeat. Also accepted: the same post forwarded by hand inside a forward's window, and
a hidden-author forward by hand inside a send's window. The owner undoes any of them with "it is not in the chat".
