# K14, a last small round (Core, K-4, 2026-11-16)

The reviewer's second pass says MAY BE LISTED: both must-fixes closed, findings 1 to 5 and 8 to 10 closed.
Three new points, in the section "Second pass (905922ce)" at the end of
`C:\Users\trabi\Claude\Projects\Telegram\REVIEW-K14-door.md` (read it; its probes are
`run4-collector-second.txt` and the probe test files beside it in the scratch folder). Same copy, branch and
house rules. Small: aim for well under an hour.

**N1 (my F4 decision was wrong: it assumed a click's own ask would come; the page sends no text while the
state's `TextMax` is 0, so no click comes and only the polls' hold decides).** Measured by the reviewer: after
a config outage of 7 min 30 s the limits stayed unknown for 470 s after Telegram answered again; by the
arithmetic up to 30 minutes. **For:** a page with the compose box open must get the limits back soon after
Telegram answers again, at a small, bounded cost while it does not. **The poll's hold doubles from 60 s and
stops at 5 minutes** (60, 120, 240, 300, 300 ...), not 30. A click's own ask keeps its 60 s. Change the
constant, its comment and the tests' numbers (the 10-minute count becomes what the new arithmetic gives: say
the number), and take the reviewer's `TestReviewK14bLimitsAfterRecovery` over as a test with the bound that
follows from the cap (after any outage the limits are known within 5 minutes plus one loop round of the
reader after Telegram answers again).

**N2. `noActor` stays set for the whole session**, because once the state says "clicks off" no click comes
and nothing tries to make the Actor again. **For:** a passing failure (the forward secret unreadable for a
moment, the store not up yet) must not close the clicks until the session ends. While `noActor` is set, the
clicks' step tries to make the Actor again at most once every 60 s of the clock (no request is involved: say
if making it can cause one, and then stop and hand back instead); success clears the flag. A test: the
secret unreadable at first and readable later: the state says "clicks off", then within about a minute
`Write` again, and no request was made for it.

**N3, a test only.** The session is ending and the "not sent" mark fails for another reason than the state:
the row stays queued, no wake. Show by a test what the review read: the caller gets the number, nothing is
sent, and the session's end (or the next session's first step) marks it "not sent"; no request at the fake.

Then: the named tests you touched and the collector's `TestClick` once, `gofmt -l`, `go vet` on the collector's
package. Update the report (a short section for this round; section 2 where a number or word changed),
commit, push. Hand back: the new head, pushed or not; per point what was done and the test (seen failing
first); anything that changed against your last list.
