# Brief M6d: the integrator's hand-back of M6 (session M-6, 11-16)

For the same coder, in `wt-mirror-adopt` on `wip/mirror-adopt` from 3b2f943a. **M6 was handed back by the
integrator at 18:33, not merged:** on the combined tree the whole collector failed on ONE test of Core's that
the piece breaks, `TestNotCountedRepeatWaitsDerived` (`internal/collector/countsfix_test.go`, about line 614:
"not_counted names repeat_waits.refresh, which is counted"). Everything else passed with the schema step. The
facts are in `MERGE-QUEUE.md`'s entry "M6" (its first lines) and the board's message 154 a, in the project
folder. The rules of the earlier briefs hold (every go command through `go1.sh`; named tests with `-timeout`;
privacy; stop and say so first when a file outside the list must change).

## 1. The cause
Since the last round `internal/telegram/mirror_ids.go` sends the id lists through the request loop under the
refresh's kind (`f.cl.call(ctx, account, refreshWhat, pickRefresh, ...)`), so that a wait Telegram states for
`channels.getMessages` is slept by the id lists and by the refresher alike (the second review pass's N1: that
must stay). But the same word is also the kind under which the loop counts repeat waits: the refresh kind's
repeat waits are now fed, while the status file's list `notCounted` (`internal/collector/status_file.go`,
Core's) says nothing counts them; Core's test derives that list from the telegram package's code
(`internal/telegram/repeatconfig_test.go` is its other half). My runs did not see it: this track ran the
collector's mirror tests by name, not the whole package.

## 2. The mend: decided
**The id lists are counted under a kind of their own while they keep the refresh's WAIT key.** That also
answers the review's N4 (the counts could not tell the id lists from Core's refreshes). Read first, in full:
the request loop's `call` (how one word is used for the wait's key, for the counting kind and for the repeat
waits), `TestNotCountedRepeatWaitsDerived` and `repeatconfig_test.go` (how the list is derived and what a new
kind must do to be consistent with it), `status_file.go` around `notCounted`. Then:
- If the loop can take the wait's key and the counting kind apart in the mirror's own code (the forwarder's
  side of it), do that: the id lists' requests, waits and repeat waits are counted under a kind of their own
  (a fixed word, e.g. "confirm"), and their wait is read and stored under the refresh's key exactly as now.
  Whatever lists of kinds exist (the counts file's kinds, the status file's `notCounted`, a test that
  derives one from the other) must stay true by their own rule: if a new kind has to be named somewhere in
  Core's files for that, it is ONE line there: name it in your report's first lines with the line and why.
- If that cannot be done without changing how Core's loop works, do NOT change the loop: the other mend is
  one line in Core's `status_file.go` (the list no longer names `repeat_waits.refresh`) with a comment that
  is true (that count then holds the id lists' repeat waits only, not the refresher's own): say which you
  did and why in the report's first lines.
- Either way: **the second pass's N1 must still hold** (`TestMirrorAdoptFixConfirmRefreshWait`: a refresh wait
  on record: 0 id lists before its end, 1 after; a wait over the bound: 0 requests, nothing written), Core's
  `TestNotCountedRepeatWaitsDerived` and the telegram package's `repeatconfig` test pass UNCHANGED unless the
  one-line mend is the honest one, and a new test of yours shows under which kind an id list's request and
  its wait are counted.
- The command's words and the report's "Known" say the kind the id lists are counted under.

## 3. Runs for this step (the merge comes after, when I say)
Your new test; `TestMirrorAdoptFixConfirm` by name; `TestNotCountedRepeatWaitsDerived` and every test of the
collector whose name holds `Counted|Counts|Status` by name; the telegram package whole (it took 43 s); gofmt
and vet on the packages you touched. **Do not merge the main head in this step:** copies' C19 is in its merge
run as schema step 26; when it is on the head I ask you for the merge (your step becomes 27: `mirrorAdoptAfter`
on C19's step, `SchemaVersion`, the entry in `steps`, the case in the switch, and your step test's
comparison), and the whole collector is run once on that tree.

## 4. The hand-back
One commit for the mend (two if a Core line is its own), the report's section "M6d", the branch pushed, the
copy clean. Final message, short: the head's 8-character hash; which mend and why, with any line outside the
mirror's files named; tests added and removed (0); every run's "go1: exit N" line; anything not as written.
