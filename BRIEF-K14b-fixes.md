# K14, the fix round (Core, K-4, 2026-11-16)

The independent review is back: MAY BE LISTED AFTER THE MUST-FIXES; 2 must fix, 1 should fix, 7 minor. The
report: `C:\Users\trabi\Claude\Projects\Telegram\REVIEW-K14-door.md`; its probes and outputs are in
`C:\Users\trabi\Claude\Projects\Telegram\wt-core-door-review-scratch` (read both in full first; take a probe
over as a test where it fits). Same copy, same branch (`wip/core-door`), same house rules as the first brief
(named tests only, memory measured before each go command, one go command at a time, commit with the same
trailer, push only that branch to `private`). Every fix has a test you saw fail first. My decisions on each
finding follow; each says what it is FOR: where my words would break that purpose, the purpose wins and you
say so.

## Must fix

**F1. An account with a keyed click cannot be deleted** (`c_act_key` refers to `c_act`; the settle's account
delete in `internal/catalog/settle.go` removes the click rows and not the key rows, fails on the foreign key,
and the failed intent then holds every later owner action in the settle). **For:** nothing of this piece may
break the catalogue's own deletes. Delete the account's key rows before its click rows, in that same
statement list (one line in `settle.go`, a shared file: name the line in the report). Then look for every
other place that deletes or could delete a `c_act` row (grep the tree: sweeps, tools, the bring-in, tests'
helpers) and say what you found. The test: the reviewer's `TestReviewK14DeleteAccountWithKey`, and a second
account's delete after it also goes through.

**F2. The page told "not running" for a click that is being sent** (`queuedFor`). **For:** an answer that is
an error must mean "this click will not go out"; today it can be answered while the reader has the click.
My decision goes one step further than the reviewer's smallest fix, and covers its finding 5 too: **once the
ledger's write has committed, `QueueClick` and `SendClickAgain` always answer the click's number, never
`ErrNotRunning`.** When the session began to end: try to mark the click "not sent (stopped)" as now; whatever
that mark answers (done: the row says "not sent"; `ErrActState`: the reader took it, the row says what
became of it; another error: the row stays queued and the session's end or the next session's first step
stops it), the caller gets the number and reads the row. No wake in that case. So a number means "this
click's row exists: read it", and with or without a key the first answer and a second call with the same
key agree. Update the entry points' comments in those words. Tests: the reviewer's
`TestReviewK14QueuedForTaken` as a test of the tree (the forced interleaving through the hook), the plain
case (the mark succeeds: a number, the row "not sent", no request at the fake), and the same key again
answers the same number in both.

## Should fix

**F3. "With media" is wrong in both directions** (a link preview counts as media; a photo with a timer does
not), so an honest edit of a long text with a preview is refused with no way round. **For:** the door never
refuses what Telegram would take. The catalogue cannot tell a caption from a text today. My decision: **an
edit is judged by the text limit only**, at the queue and in the request layer's `limited`, as before this
piece; a caption that is too long costs the one request Telegram refuses (counted and shown, as before).
Take the plumbing out again: `catalog.ActMessage.Media`, `Action.Media`, the turn's read of it for an edit
(and with it the "a failed read means not sent" path), the queue's use of `CaptionMax`. **Keep:**
`ActLimits.CaptionMax` from the config answer and `ClickState.CaptionMax` (the page knows what it shows and
judges a caption itself), the fake's `caption_length_max` and its `MEDIA_CAPTION_TOO_LONG` answer. A test
that an edit between the caption limit and the text limit of a message with an attachment row is queued and
sent, and that the fake's refusal of a too-long caption ends the click "refused" with Telegram's word.
Correct departure 7 in the report.

## Minor, taken

**F4. A failing limits ask costs 3 config requests a minute for as long as a page is open.** **For:** a poll
must not become an endless trickle of requests at a server that is refusing. The hold for an ask that a
STATE CALL wanted doubles after each failed ask: 60 s, 120 s, 240 s ... up to 30 minutes; any successful ask
clears it. **A click's own ask is not held by the doubled time**, only by the 60 s since the last failed ask
as you built it (a text the owner sends must be able to go as soon as a minute after a failure, whatever
the polls did). The reviewer's count as a test: 10 minutes of the clock, a poll every 3 s, config failing:
at most 4 asks (12 requests) where it measured 10 asks; and a click queued in minute 5 asks once.

**F6, two of its three points.** (a) A "mark as read" setting that cannot be read must not close the whole
state: `Why` is "setting" only for a cap that cannot be read (what the turn itself refuses on: check
`oneClick` and match it exactly, and say what you found); for a bad read-mark setting `MarkAsRead` is false
and a new field says the setting is bad. (b) When the clicks' Actor cannot be made in this session (the
forward secret cannot be read), the state says `Write` while every click ends "not sent", and the limits
stay "wanted" so that every poll nudges the reader all session: publish that failure from the reader's
goroutine; the state then answers "clicks off" (no click is sent in this session), and no poll nudges or
wakes for limits while it holds. Not taken: a method refused as frozen and a chat with no access hash stay
out of the state (the click's row says them).

**F9. The known key's answer must not depend on the chat list as it is now.** **For:** an honest second call
with a key must find its click even if the chat left the account's readable chats or a group migrated in
between. The digest is taken over the page's own input, exactly the fields of `ClickInput` as handed in (the
catalogue's chat numbers for the chat and the source, the kind, reply, topic, target, the message ids in
order, emoji, revoke, try-again, the text), computed in the collector before any read; the catalogue stores
and compares the digest it is handed (with a key a digest of 32 bytes is required). The key is then read
FIRST, before the chat is resolved: known with the same digest: its number; another digest: `ErrClickKey`.
Keep the encoding length-prefixed and in fixed order, and keep the tests that show two different clicks
never share an encoding.

**F8, only if it is cheap.** If the catalogue's message row says a message is a service message (a column
or a kind you can read in `ActMessages` without decoding the raw message), a reaction's or a reply's target
that is one is refused as "no message". If it cannot tell, leave it and say so.

**F10, the tests.** `TestClickStateNudgeKeepsPause` allows one more history request with polls: make it
equal, or say exactly where the one comes from. `TestClickQueueRaceAtSessionEnd` proves nothing: replace it
by F2's forced test (remove it by name and say so: the integrator counts removed test functions).

## Not taken (say so in the report's list)

F7 ("send again" does not judge its target again: the owner's explicit click, Telegram's refusal is shown).
The two F6 points above.

## The head

Do NOT merge the main head in: your change over d6415255 applies on the main head (6af0c09a) with no
conflict as it stands (checked with `git merge-tree --merge-base=d6415255`), and the integrator applies it
so. The schema step stays "the one after `mirrorWantSchema`".

## Then

The named tests of what you touched (the catalogue's `TestAct|SchemaStep|Settle|Click`, the collector's
`TestClick`, the telegram tests you ran before, tgstore), `gofmt -l`, `go build ./...`, `go vet` on the four
packages. Update `archiver/docs/progress/core-door-REPORT.md` (a section for this round; the entry points and
fixed words as they are NOW, complete, because two other tracks build on that text; the lines for the merge),
commit, push. Hand back: the new head, pushed or not; per finding what was done and the test that shows it
(seen failing first); every signature, field or word that changed against your first hand-back, as a list;
the tests as run.
