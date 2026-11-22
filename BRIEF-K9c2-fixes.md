# Brief K9c2: the settle's fix round (Core, K-3, 2026-11-16 02:50)

For the coder of K9c, on `wip/core-settle` (copy `wt-core-settle`, at cee2e466). The independent review
is `REVIEW-K9c-settle.md` in the project folder (verdict: may be listed after the must-fixes; 2 must fix,
3 should fix, 6 minor; every must and should fix reproduced by a probe; its probes and outputs are in
`wt-core-settle-review-scratch`). **Read the review in full first, and the probes.** Every finding is
accepted. The piece decides by itself that a message was delivered, so every doubt is settled to the
careful side: a wrong "still not known" costs the owner one click; a wrong "arrived" costs a message
that was never sent. Turn each probe into a test of the tree and see it fail before your fix. Same
ground rules as K9c (only that copy; it sends nothing; named tests only; no Docker, no race detector, no
whole-package run; the memory check before every go command, waiting under 3,000 MB; Go code only in
`schema_act.go`, never the schema text; commit often, push `private wip/core-settle`; merge nothing).

## 1. Must fix: one window per try (finding 1)

My brief's 3.2 was [name removed] and led to one window over a whole chain. Each try is judged on ITS OWN mark:
a candidate counts for a row only inside that row's window; the check on other clicks uses the same
per-try windows; the repeat's check before it goes out looks at each "not known" row of the chain with
that row's own window. Tests: the reviewer's two probes (two tries two hours apart with the owner's own
message between them: nothing is settled, the third try goes out).

## 2. Must fix: what can be a send's message (findings 2, 5, 6)

A candidate for a send or reply is a plain text message of the account's own: **not forwarded** (no
forward origin), **no media** of any kind (the click sends text only), and **never edited** (no earlier
version on record: a message first written with another text is not this click's message). The app's
own forward clicks' copies and the mirror's forwards are excluded by the first of these. Tests: the
reviewer's four probes.

## 3. Should fix: the two clocks (finding 3) and the window's start

- The window is on Telegram's dates, the mark on this PC's clock. The start stays a little before the
  mark only for the clocks' offset: **10 s before the mark** (not 30) to 5 minutes after it; say in the
  code and the report that this is the reason. A PC clock further off than that makes the app find
  nothing and leave the row for the owner: the careful side.
- The check on other clicks is as wide on both sides as the window is: another click with the same
  content whose mark lies anywhere within [the window's start minus the window's length, the window's
  end plus the window's length] of this row blocks the app's verdict for both. Test: the reviewer's probe
  (the PC 2 minutes ahead: neither click is settled wrongly).

## 4. Should fix: a delete "for everyone" (finding 4)

The catalogue's deleted mark cannot say for whom a message was deleted. A delete click with "for
everyone" in a private chat or basic group is never settled by the app (it waits for the owner); in a
channel or supergroup a delete is for everyone by nature and is settled as built; a delete "only for me"
is settled on the mark as built.

## 5. A guard for the risk the design accepted (the review's last section; my decision)

The design accepts that an identical text the owner sends from another device inside the window is taken
for the click's message. One guard that costs no request: **the app gives no verdict of its own for a
send or reply when the account already sent the same text in that chat in the 7 days before the window**
(a text the owner repeats: "ok", "yes"): the candidate is shown with a fixed word for it and the owner
decides. One bounded, indexed read (say which index; if none serves, say so and bound the read by rows).
Test: a repeated text is not settled; a text sent once is.

## 6. The owner's way back (finding 10, and its twin; my decision)

The app's own verdict must never be the last word.
- **An "arrived" the app made** (its fixed word on the row): the text is NOT cleared at that moment
  (it is cleared by the 7-day rule like any kept text); the owner can say "it is not in the chat": a new
  door moves the row from that "arrived" back to "not known" in one statement that names both the state
  and the app's word, unties the matched message, and sets a fixed word on the row that the owner said
  so. **A row with that word is never settled by the app again** (the candidates are still shown). An
  "arrived" by the owner's own verdict is final as before.
- **A repeat the app stopped** ("the earlier try is in the chat"): the owner can send it again: `SendClickAgain`
  from that row is allowed when the call says "try again" (the owner's explicit word), and a repeat
  queued that way is not stopped by the repeat's check; the row the app had matched gets the same "the
  owner said it is not in the chat" word, so the settle does not mark it arrived afterwards. Without
  "try again" it stays refused, as you built it.
- The collector's entry points for both (plain functions in `click_api.go`, fixed-word errors); tests of
  each path, and that the request count at the fake is exactly one more when the owner sends again.

## 7. The minor findings

7 a forward's topic is compared; 8 another forward whose source keys cannot be read counts as "may be
the same content" (it blocks: the careful side); 9 the collector's pace does not forget rows pending on
earlier pages of a settle (page through, or keep the oldest pending mark); 11 `TestClickOutcomeLost`
runs with the settle on again.

## 8. Runs, report, hand-back

- Once at the end: `go build ./...`; `gofmt -l` and `go vet` on `internal/catalog` and
  `internal/collector`; `-run 'TestClickSettle|TestAct' ./internal/catalog/`;
  `-run 'TestClick' ./internal/collector/`; `-run TestWallDependencies ./internal/viewer/`.
- A section "The fix round" in `archiver/docs/progress/core-settle-REPORT.md`: each finding's number,
  what changed, its test and "seen failing first: yes or no"; the match per kind restated in full as it
  is now (one table: kind, what is a candidate, the window, what blocks the app's verdict); the new
  doors and words; what is still the design's accepted risk after the guard, in one honest sentence.
- Commits as before, pushed; `git status --short` empty. Your final message: the head's full hash, each
  finding and each of sections 5 and 6 with its test and "seen failing first", the commands with results
  and seconds, anything you disagree with.
