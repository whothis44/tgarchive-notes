# Brief B5-A, fix round: the review's findings (viewer session B5, 11-16)

Same copy (`C:\Users\trabi\Claude\Projects\Telegram\wt-b-window`), same branch (`wip/b-compose`, head
42a1df11), same bounds, privacy and load rules as `BRIEF-B5-compose.md`. The independent review is
`C:\Users\trabi\Claude\Projects\Telegram\wt-b5-review-A-scratch\REVIEW.md` (read it in full; its probes are
in `probe_b5_test.go` beside it: take them into the package as its own tests where they fit). Verdict: safe
while the seam is nil; not ready for a live seam. **Every finding is accepted, as decided below.** Do not
merge the main head in.

## The findings, as decided
1. **An unfinished click drops off the page behind 200 newer rows.** No fixed window of rows. Per chat and
   account the viewer keeps, in memory, the highest ledger row it has read and the set of open tips (a row
   in a state that is drawn, with no repeat). A read takes only the rows above that number (by the index
   `c_act_chat`; the viewer's own read-only SQL may pick the row numbers and states, the row itself is
   always read through `catalog.Click`, which fails closed) and reads the open tips again (a finished row
   never opens again: a "send again" is a new row). The first read of a chat in a run passes over that
   chat's rows of the last `ActTextDays` once. Bounds, stated and tested: the rows read per poll, the open
   tips kept per chat (more than can be drawn: `more`, and the oldest unfinished ones are the ones kept
   and drawn first, since they are the ones the owner must not miss), the chats remembered. The reviewer's
   probe (a not-known send, then 200 read marks) must show the send still drawn.
2. **One click, one request, also after "failed".** (a) The page makes a key for each click (random, from
   the browser's own generator) and sends it; it keeps the same key for as long as the same text is being
   sent again after an answer that was not a refusal. `ActInput` gains `Key string` (for the door to
   de-duplicate on: Core is told). The viewer's server remembers the keys that got a click number (a
   bounded map, minutes) and answers the same number again without calling the seam. (b) After "failed" or
   a timeout the page reads the clicks' state at once and keeps Send disabled until that read is back; if
   a tip now carries the same text, the box is emptied. (c) Every call of the seam gets a deadline from
   the handler (20 s), and `ask` in the page a timeout (30 s) that shows a fixed line ("No answer; look at
   the chat before sending again") and then reads the state. The box is never silently dead.
3. **"Mark as read" only from the unfiltered view** (no topic, no media filter, opened at the newest
   message), and it posts without any note to the owner whatever the answer (finding 10).
4. **The clicks' state away from the newest end:** when no live ask runs and a tip is queued or sending,
   the act box asks on its own timer at the live poll's pause, only while the tab is visible; it stops
   when none is.
5. (With 2c.)
6. **Deleted messages:** a delete leaves out the post's messages already marked deleted, and is refused
   "no message" before the seam when none is left; an edit's or a reaction's target that is deleted is
   refused the same way.
7. **The server knows "own" and "channel" too:** before the seam, an edit or a delete in a broadcast
   channel is refused "channel", and an edit or a delete of a message the index does not hold as the
   acting account's own is refused "not own" (the rule the chat page already uses for mine and theirs,
   `mineOf`, on the server's side; where the index cannot tell, the click goes to the door, which
   decides). A test with a fake seam that answers the door's refusals shows each word reaching the page.
8. **Forward:** hidden chats are listed last in the chooser and marked "hidden" (hidden is the owner's
   tidying, not a ban). After a forward is queued the page shows a fixed note with a link to the
   destination chat's page ("Forwarding; its state shows in that chat").
9. **A text is refused, never changed:** the page refuses a text that is not well formed
   (`isWellFormed`), and the server refuses a text holding U+FFFD or a NUL, both with one new word of the
   closed set and its sentence ("The text holds a character that cannot be sent as it is").
10. (With 3.)
11. **The heart is sent as U+2764 alone** (shown as the page shows it now). Whether each emoji of the row
    is one Telegram takes is Core's to record; a refused reaction already shows as refused.
12. **Any program running on this PC as the owner can act through the viewer's routes:** no code; one
    sentence in `act.go`'s head comment, for the pass-through's security note.
13. **One unreadable row closes the box:** stays (fail closed); the line says so in fixed words that tell
    the owner it is the app's record that cannot be read, not the chat.
- **Also:** when Edit is chosen, a fixed line under the box: "Saving replaces the message with plain text"
  (the door sends text only; formatting is lost).

## Tests
One for each numbered decision that changes behaviour (1, 2a, 2b by the server's part, 2c by a clock or a
seam that never answers, 3, 6, 7, 8, 9), the reviewer's probes among them. The page's own behaviour (2b, 4,
the timeout) cannot be tested by a string check: open the page once in the browser pane on your invented
archive with the fake seam, as you did before (a temporary test server, removed, never committed), and say
for each what you saw: Send disabled while a POST is out and after "failed" until the state is back; the
timeout line; Edit and its line; Delete and its question; the account chooser with two accounts (make the
fixture have outgoing messages and a chat seen by two accounts).

## At the end, once
As in the first brief: gofmt, `go vet ./internal/viewer`, your named tests, `-run 'TestWall|TestLAN'`,
`CGO_ENABLED=0 go build ./...`. Commit and push `wip/b-compose` as before. Hand back, as your last message:
the commits and the head; each numbered decision with what was done and any difference with its reason; the
seam as it is now (what changed against `SEAM-B5-viewer-act.md`: `Key`, the new word); the bounds of 1 with
their numbers; what you saw in the browser pane; what you ran and what it printed; what you did not test;
doubts. The copy clean, nothing left running.
