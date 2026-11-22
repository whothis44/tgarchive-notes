# K15, the fix round (Core, K-4, 2026-11-16)

The independent review is back: MAY BE LISTED; 0 must fix, 0 should fix, 5 minor. The report:
`C:\Users\trabi\Claude\Projects\Telegram\REVIEW-K15-store.md`; its probes are in
`C:\Users\trabi\Claude\Projects\Telegram\wt-core-store-review-scratch` (read both; take a probe over as a test
where it fits). Same copy, same branch (`wip/core-store`), same house rules as the first brief (named tests
only, one go command at a time, memory measured first, commit and push that branch only). Four small things:

1. **Finding 2 (my brief was wrong there: "set the next probe as `stagingAway` does").** When the loop's look
   fails, `awayLook` calls `stagingAway(now)` with the time AFTER the look, which pushes the next probe by
   however long the look took: a disk that came back stays unused for up to that much longer. **For:** the
   period was already claimed in `probeAway` (the probe time moved on from the claim); a failed look must
   leave the next probe at claim + `AwayProbe`, exactly where `place` or the loop would look next. Take the
   else branch out (a failed look changes nothing but `probing`). A test that fails with the branch in: after
   a slow failed look, the next look (the loop's or an open's) comes at claim + period, not later.
2. **Finding 3.** A panic inside the look's goroutine would end the whole program (the supervisor covers the
   "writer" task, not this goroutine). A deferred recover in `awayLook` that clears `probing` (under the lock)
   and changes nothing else; if the writer has a log function, one constant line without the panic's text,
   else none. A test with a fake `Free` that panics: the test process lives, `probing` is clear, a later
   period is probed again.
3. **Finding 1.** A look that never returns leaves `probing` set, so the loop never looks again in this run
   (also in a later "away"); downloads are not affected (an open's own look in `place` is as today). That is
   the intended limit (never a second goroutine piled on a disk that hangs): say it in `probeAway`'s comment
   and in the report, in those words. No code.
4. **Finding 4.** The "no second look" assertions read the count right after a tick and can pass when they
   should fail: make each wait for the look's end (the `probed` hook) or for a state that only the look's
   end produces, before it reads the count. No real time.

Not taken: finding 5 (a wall clock stepping back inside a rest: display only). **Not in this round, do not
touch:** the older hazard the reviewer confirmed (`place` calls `FS.Free` with `w.mu` held): it is a piece of
its own with its own review.

Then: the named tests of the package you touched or added (all of `TestK15*`, the staging and tuner tests you
ran before), `gofmt -l`, `go vet ./internal/store`. Update `archiver/docs/progress/core-store-REPORT.md` (what
changed in this round, the limit of point 3), commit, push. Hand back: the new head, pushed or not, per point
what was done and the test that shows it (seen failing first), the tests as run.
