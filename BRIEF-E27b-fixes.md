# Brief E27b: the fix round of "C22" (lesser copies wait behind the best)

For ONE fresh coder (Opus 5.5, high effort). Written by the copies session C6, 11-16 19:35, from the
independent review and its own read. You continue another coder's branch: `wip/copies-27` at 7c5161e2, copy
`C:\Users\trabi\Claude\Projects\Telegram\wt-copies-27` (clean). Same rules as the first brief
(`BRIEF-E27-lesser-copies.md`, sections 1, 2 and 8: read them; they bind): the track's go lock around every go
command, `GOMAXPROCS=2 GOMEMLIMIT=1GiB GOFLAGS=-p=1`, named tests only, the allowed files, commits with the
given identity and trailer, pushes of `wip/copies-27` to `private` only, invented data only, your scripts in
`runs-copies-c22b\` in the project folder.

**Read first:** `BRIEF-E27-lesser-copies.md`; the first coder's report on the branch
(`archiver/docs/progress/copies-twins-REPORT.md`); `REVIEW-E27-lesser-copies.md` in the project folder, whole;
then `schema_twin.go`, `twin.go` and the branch's changes in `pairword.go` and `ladder.go`. The reviewer's
probes are in `C:\Users\trabi\Claude\Projects\Telegram\wt-copies-review27-scratch\archiver\internal\catalog`
(`zz_probe_*_test.go`, never committed there): read them, and take from them what you need for your tests
(copy the code into the branch's own test files under names of the branch; change nothing in that folder).

## The list (each with its test; the review's numbers)

**1 (high). A better copy that no live account can reach is not coming.**
- The rule: a candidate counts as coming only when its collector row is `wanted`, `active` or `aside` AND a
  `c_reach` row of an account with `removed_at IS NULL` exists for it. A file is never made to wait behind a
  file without live reach.
- The events: when a file that others wait behind loses its last live reach, the files behind it go to the
  door (`c_pair_pending`, `twin = 1`). First list, in the report, EVERY statement in `archiver/internal`
  that deletes a `c_reach` row or sets or clears `account.removed_at` or deletes an `account` row (with what
  SQLite's cascade does and in which order it fires an `AFTER DELETE` trigger: show it by a test, do not
  assume). Then cover each: a trigger `AFTER DELETE ON c_reach` (its `WHEN` cheap: `Saved` deletes the reach
  rows of every saved file, after the collector row is gone), a trigger on `account` for `removed_at` set
  (one statement over the waiting files whose better copy has no live reach left; an account's removal is
  rare), and whatever the delete of an account needs. An account restored (`removed_at` cleared): nothing to
  do (say why in the report).
- Tests: the review's `TestZZProbeReachGone`, both ways, as `TestTwinReachGone`; one for each door you
  listed.
- **Measure** a `Saved` and the save's delete of the reach rows before and after the new trigger, beside the
  first coder's figures (`TestTwinTriggerCost`'s way).

**2 (high) and 3 (medium). The pending row's kind follows the file.**
- Every `INSERT` into `c_pair_pending` outside this piece (`lostLookAlike`'s rest list, `pairEdgeLost`,
  any other: list them) becomes an upsert that sets `twin = 0` when the file has no `c_twin` row
  (`... ON CONFLICT(tg_media_id) DO UPDATE SET twin = 0 WHERE NOT EXISTS (SELECT 1 FROM c_twin ...)`).
- `SettlePairPending` judges a file by `twinPendingJudge` whenever it has a `c_twin` row, whatever the column
  says; the column only says which counts move for a file without one.
- The doors table's row 24 and `twinPendingJudge`'s comment are corrected: the frame check's "copy" on a
  waiting file writes a probable edge and leaves the wait.
- Tests: the review's `TestZZProbeStaleTwinRow` (the file must end as on the head: wanted) and
  `TestZZProbeWaitingGetsEdgeThenLost` (the waiting file stays waiting behind its better copy; the lost
  look-alike counts do not move), under names of the branch.

**4 (medium). The writer's time is bounded, whatever the number of look-alikes.**
- **One read of the candidates' collector rows**: a single statement over the ids of the alike list (a JSON
  list, as `lostLookAlike` does), the "plainly wanted" test evaluated only for `wanted` rows, a waiting row's
  `behind` with it; coming candidates first, then waiting ones; **at most `twinWeighMax` rows (a variable for
  the tests; 32)**; when the list was cut, one count (`lookalike.twin_cut`).
- **`twinRepoint` goes.** A file that is made to wait sends the files behind it to the door by the trigger
  that exists; the door judges each (its chunks and its time budget bound the writer), and each ends waiting
  behind the new best by the rule. Remove the function, its count and its mentions; if a test shows a state
  this breaks, stop that change, keep the function with the same cap and say why.
- The door's overrun of `judgeBudget` by one file's weighing is then bounded by `twinWeighMax`.
- **Figures again, in the report, beside the review's table:** an attach with the switch on at 100, 400 and
  1,000 alike queued; the door after the better copy is gone at 400 (chunks, the longest, the whole).
  Wanted: an attach within a few times the switch-off attach at every size; the door's longest chunk near
  `judgeBudget`. If the figures say otherwise, report them and stop there.
- With a cut list a large group may end with more than one file wanted (each later arrival sees only part
  of the group). That is accepted: bounded cost first. Count it honestly and say it in the report.

**5 (low, taken). The same result in every order for a chain.** In the branch where the new file is not the
best, every other plainly wanted member of the weighing also waits behind the best, each by the rank guard
(one rule for both branches: every plainly wanted member that is not the best waits behind the best when the
guard allows; a member in transfer or set aside is left). Test: the review's "chain" in all six orders.

**6 (low, NOT taken).** The rank guard's refusal stays as it is. Say it under "known and left" with the
review's orders.

**7 and 8 (low, words).** `TwinCounts`' comments and the report say "times" where a count counts events;
`internal/viewer/media.go` and `post.go` join the report's list of readers; a comment at the calls of
`savedVideoFacts` says it reads a media's facts whether or not it is saved.

**The test the first coder did not write: `TestTwinNeverSkips`.** 300 random worlds (the first brief's
section 7 has the invariants), built from the reviewer's `zz_probe_random_test.go`, with what its worlds did
not have: an account removed, an account deleted, the frame check's "copy" on a waiting file, the bring-in's
hold on a file that left waiting. After every step and after the door is drained: no file `skipped` or `gone`
by this piece; no file held with the twin's reason and no `c_twin` row; no `c_twin` row whose file is not
held with that reason; no waiting file in `c_supply`; with the door drained, no file waits behind a file that
is not coming (the new meaning of coming); no file held, not probable, with no edge, no wait and nothing
pending that the head's door would have judged (the review's finding 2 as an invariant).

## Then: the main head merged in

The main branch has moved (another schema step is on it). After the list above is committed and green:
`git -C <your copy> rev-parse claude/charming-feynman-vm2xia`, then merge THAT HASH into `wip/copies-27`
(`git -c user.name=Claude -c user.email=noreply@anthropic.com merge --no-edit <hash>`). A conflict in
`catalog.go`'s three schema places is expected: keep both steps, yours last; set `twinAfter` to the constant
of the newest step on the merged head (read the version list there; do not guess a number) and the one
comparison in your step's test. Any other conflict: `git merge --abort`, stop and report the file names.
Then your named tests again, with the merged head's own step test (`TestEdgeLog`) and
`TestSchema|TestMigrateV2|TestChangeLog|TestPair` by name.

## Hand-back

Everything committed and pushed on `wip/copies-27`, the copy clean, `gofmt` clean on your files. The report
gets a section "The fix round" (what changed for each number of the list; the lists of statements asked for
in 1 and 2; the timings and figures; what is known and left; where you departed from this brief and why).
Your final message: the head's full hash; the main hash merged in and what `twinAfter` is now; the tests run
with pass/fail and seconds; the figures of 1 and 4; anything you stopped at. Say plainly what a test shows
and what you only read. Numbers and code names only.
