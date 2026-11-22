# Independent review of K22, alerts: the record and what raises one (wip/core-alerts aa6a5374 against af4ca40e, 2026-11-21)

**Verdict: may be listed after these fixes: F1, F2, F3 (the musts and the first should).** The record is sound
(one open row per key held by the partial index, change number right, prune right, read-only and older-file
doors right, the step right) and the look is cheap. Its fault is in the task: a restart, and a since that
starts again, end alerts whose condition still holds, which is the false "all is well" that rule 13 forbids.

Read: the design (sections 1 and 2), the brief, the coder's report, the whole difference, the old app's
`ix_alerts.go`, and the code the snapshot reads (account loop, ownerstop, copier Away/LibraryFull, writer
StagingNow/place/stagingFull, engine counters, pausedl, Run's stop order). Probes ran by `-overlay` in a detached
copy through `runs-core-k5/go1.sh`, named tests only. Invented data only.

## Findings

**F1, must, CONFIRMED. A restart ends alerts whose condition still holds, and raises them again as new rows.**
`internal/collector/alerts.go:113-126` and `:178-195`, with `internal/alert/alert.go` `Judge` (`add`, line ~262).
At its first look a run loads the open keys from the record, then ends every judged key that Judge does not call
true. But Judge reports "true and past its threshold" only. A condition that holds but is under its threshold in
this run's memory counts as false. After a restart every since starts again: the account's since (memory,
`setState`), the copier's `awaySince`, the writer's, and the stall mark. So an open account.vpn (15 min),
account.retrying, library.away/full, staging.away (30 min) or downloads.stalled (60 min) is **ended at the first
look**. The owner reads "ended by itself" while nothing has changed. Then a new row is raised 15 to 60 minutes
later. Frozen and signed-out have a 0 threshold but lose a race: the first look runs at once, while the account is
still in its first state (`StateNotSignedIn`, then the loop's catalogue reads), so it ends them too.
- Probe P1 (library away through a restart; the new run's since starts at its own start, as the real copier's
  does): before the restart, 1 row, open; after the restart and 3 looks, 1 row, **open 0** (ended while still away).
- Probe P2 (two frozen accounts, three restarts): account 1 went from 1 row to 2, 3, 4 rows (ended and raised
  again at each restart); account 2 went to 2 rows once. The stop by itself ends nothing: 1 row, still open,
  after the stop.

Fix: Judge also returns the keys whose condition holds but is under its threshold ("pending"), and the task
never ends a pending key. The task also ends no key loaded from the record until this run has judged that key's
kind with settled states, that is, until the account has left its first and passing states, or after one
threshold of this run. The old app kept its stall time on record (LastAt), so a restart did not reset it. Keep
the stall mark's since in the record as well (or in last_at) so that a restart does not reset it.

**F2, must, CONFIRMED. A want blocked again within one look keeps the old row, seen, and the change number does
not move.** `alerts.go:152-158`: a key that is open in `live` is only touched. The block is "cleared only by the
owner's mirror -allow". The owner presses Seen, allows the want, and the mirror refuses the same batch again at
once (the 11-21 case: a deleted message). The task never sees the gap. Probe P3: after the see, the allow and a
new block, followed by 3 looks: 1 row, the same row, **seen kept, change number not moved**. No page and no Windows
notification learns that the block came back, and the owner believes it was cleared. The same holds for a freeze
cleared and frozen again within 30 s. Fix: keep the condition's since (block_at for mirror.blocked, the state's
since for an account) with each live key. When the since is newer than the one recorded, end the old row and
raise a new one (or raise with seen_at cleared and the change number moved).

**F3, should, PLAUSIBLE (by reading; no probe). staging.full can in practice never be raised.**
`internal/store/writer.go:666-672` and `place` (:465-497). "Resting" lasts `FullPause`, 1 minute by default.
After a rest has ended, the next one starts with a new `restSince`. A staging disk without room under `KeepFree`
sends downloads to the library and sets no state at all. So the 30-minute threshold is never reached, and
between rests the key is judged false and ended. Fix: give the writer a lasting "no room since" (set at the first
refusal for room or full error, cleared at the first staged download) and raise from that. Otherwise drop the
kind and say so; the lessons say staging full is not a stop: downloads go on to the library.

**F4, should, PLAUSIBLE. downloads.stalled counts only finished files.** `alerts.go:257-282` uses the sum of
`Bucket.Files`. Under the speed limit with every lane on huge files (a 4 GB file at about 1 MB/s takes over an
hour), no file finishes for an hour while bytes still arrive, and the alert fires. The engine replaced during a
run (`startEngine` when a lane is added) also loses the finishes made before the first look. Fix: count
`Bucket.Bytes` or `Parts` as progress (any growth moves the since), and compare against the old engine's last
total before it is swapped.

**F5, should, CONFIRMED by reading. A removed account's blocked wants keep an open alert for good.**
`internal/catalog/alert.go:369`: the blocked part of AlertLook does not filter removed accounts, though the
Waiting part does. A seen open row stays on the list, because the list is "unseen OR open", so it never leaves.
Fix: join `account ... removed_at IS NULL` in the first part of the UNION (its key's kind then ends as judged),
or document that it stays.

**F6, minor. A failed record leaves no trace a page can show.** `alerts.go:113-120`: when OpenAlertKeys or
every raise fails, the only trace is one log line. Fix: expose the failRun count through a door, so that a page
can say "the alerts' record cannot be written".

**F7, minor. An idle look writes nothing, but an open alert costs one write transaction every 30 s.** This
comes from TouchAlerts: 2,880 commits a day for each lasting alert, for example a frozen account left for days;
there are no other writes beyond the hourly prune transaction. Cheap (see below), but it shares the catalogue's
one writer with download finishes. Fix: touch last_at at most every 5 to 10 minutes.

**F8, minor. account.retrying's words are wrong for some causes.** `StateRetrying` is also set for "the
catalogue cannot say whether the account is frozen / marked removed" (`account.go:353`, `ownerstop.go:231`), but
the words say the connection to Telegram keeps failing. Fix: neutral words ("The account cannot start and keeps
retrying").

**F9, minor. The worst-case look is about 11 to 12 ms.** That case is an account whose supply rows are all held
or waiting: the EXISTS walks every row of that account, because `tier` comes after `dc, large` in the key. That
is acceptable at 30 s. At millions of held rows it would grow linearly. Fix if needed: a partial index
`c_supply(account_id) WHERE tier < 5`, measured against the cost of writes first.

The brief asked about these and nothing is wrong:
- The passing-state since (the coder's choice 2) is right in every order I traced: it cannot fire early, because
  any non-passing state other than the one it came from resets the since. Its only stretch is a dial that hangs
  in "connecting" (bounded by the dial).
- The stop ends nothing (P2), and the turn's writes on an ended context fail and are not noted.
- Removed or owner-stopped accounts end their account alerts: that is the owner's act, acceptable.
- The doors on a read-only handle and on an older file are right.
- The step: two constants, refuses other versions, migrate rolls back on error, idempotent; tests cover it.
- One open row per key under raise, see, end, raise: P4. A second open insert is refused by the index.
- Prune keeps unseen and open rows. The change number moves on raise, end and see only.
- Privacy: log lines are constant formats with the kind and account number only; the errors are errWord; the
  stored words are fixed and checked by form; no name, text, path or link.
- Concurrency by reading: lock order a.mu then s.mu, as flushAll has it; the task's memory is under its own mutex;
  the doors touch only the catalogue; pause and engine reads are under their locks. Run under the race detector:
  `go test -race -run 'TestAlerts|TestFrozenAccountStopsAlone|TestSignedOutStopsAlone|TestOwnerStop|TestPause' ./internal/collector/`
  (the collector only: the catalogue's new code adds no shared Go memory).

## Probes and results

All through go1.sh with `-overlay`, in the scratch copy, now removed.
- Catalogue (`TestReviewK22*`, 3.1 s):
  - Look with 100,000 supply rows over 3 accounts, all wanted: **31 µs a look**. The plan uses
    `SEARCH s EXISTS USING PRIMARY KEY (account_id=?)`: the key's prefix serves the EXISTS.
  - All rows held or waiting: **12.1 ms a look**, and 11.0 ms with one wanted row at the far end of each key.
  - Touch of 50 open rows: 269 µs; of 1: 26 µs.
  - Prune with nothing to prune: 121 µs.
  - Change-number read: 12 µs.
  - The list uses `c_alert_list`; the touch uses `c_alert_open (key=?)`.
  - P4 (orders): a raise on an open seen row keeps the row and its seen; seen and then ended leaves the list;
    end then raise gives a new row; ended_at never goes before last_at; a second open row is refused by the index.
- Collector on the fake (`TestReviewK22*`, 22.6 s): P1, P2 and P3 as above.

The measured look is 31 µs typical and 12 ms worst at 100,000 rows. Add the thresholds' reads (11 settings) and
one touch transaction while anything is open: well under 1% of a 30 s period.

# Second look: the fix round, F1 and F2 (wip/core-alerts 7233d6d1; fixes 79cb23b4, head merged in 4e02af7f; 2026-11-22)

**Verdict: may be listed after this fix: S1 (small, in alerts.go only).** F1 and F2 are fixed: my P1 to P4 now
pass, and so do two new probes (a restart with the library back, and an account removed while its alert is
open). The pending/settled rule and the since comparison end no true alert at a restart, raise no burst in the
cases traced, and leave nothing open for good when its condition is gone. One old path still ends a true
alert: S1.

## Findings

**S1, should, PLAUSIBLE (by reading). A reconnect ends a true downloads.stalled alert, and reconnects every hour
or less keep it from ever being raised.** `internal/collector/alerts.go` `alertAccounts`, the `case !eligible`
branch.
- Eligibility needs `StateRunning`. An account that passes through Retrying, GateRefused, Connecting or Starting
  (a lost connection, `endConnLost`, then the pause and a redial) is "not eligible".
- The mark is then cleared, "0,at" is written, and the account is still settled, so the open stall key is judged
  false and ended.
- When the account runs again, the stall counts from zero. So files can wait for hours with nothing answered, and
  the stall is never raised as long as the connection dies at least once an hour.
- The old app's rule had no state term: files waiting, not paused, nothing in the last hour. Its `LastAt` was not
  reset by a reconnect.
- Fix: while the account is in Retrying, GateRefused, Connecting or Starting, do not judge the stall: keep its
  mark and since and leave its key held (those states raise their own alerts). Clear the mark only on the owner's
  pause or stop, downloads off, frozen, signed out or removed, or no files waiting.

**S2, minor, PLAUSIBLE. downloads.stalled with a threshold of 0 is raised while downloads run.** `alert.Judge`,
the stall branch. With the threshold at 0, a stall is "true" whenever files wait, and every part answered gives
a newer since. So the task raises it again at every look: Returned (times one more, the change number moves every
30 s) and, after a Seen, Replaced (a new row). The words then say no file has finished while files finish. Fix:
the stall's threshold takes at least one minute (a bound that makes sense, not a cap), or Judge calls a stall
with a progress since the last look not true.

**S3, minor. A store key loaded at a start is ended after the guard if the store has not yet found it again.**
`alerts.go`, the `storeKind` guard. The copier marks the library away only when it tries a copy. If nothing is
copied during the first 30 minutes of a run while the library is still away, the loaded row ends at minute 30 and
is raised as a new row later. This is rare, and it is an end that is followed by a new raise. Fix only if wanted:
hold a loaded store key until the store has made one attempt in this run (a copy, or a probe).

**Not findings (checked):**
- A loaded key's since is taken, never compared (`liveKey.known` is false except for a mirror's block_at), so a
  restart gives no Returned or Replaced.
- The passing-state restore is now limited to the VPN refusal and the failed connection. Frozen, then
  connecting, then frozen gives a newer since, and the row is Replaced if seen: right.
- `WordReblock` moves block_at once per owner's word: no burst.
- An unsettled account holds its keys only while it is connecting or starting, which is bounded by the dial and
  the redial pause. `settled` is set for any non-passing state, even one that does not change (a NotSignedIn set
  again).
- An account no longer in the snapshot has its keys judged and ended. A removed account: ended (P6).
- An unreadable stall record raises alert.unreadable for one look, then the record is written again: a raise and
  an end, which leaves an unseen row (intended).
- Comparing seconds in the catalogue against nanoseconds in memory can at worst give Same for a return within one
  second: harmless.

## Probes (through go1.sh, by -overlay, in the scratch copy wt-core-alerts-review2, since removed)

The first catalogue run met the lock busy for 60 minutes (exit 97, nothing run) and was run again.

| Probe | First round | Second look |
|---|---|---|
| P1: restart, library still away | 1 row, ended | **1 row, open** |
| P1b (new): restart, library back | | open for 4 looks; **ended at 30 min of the clock** (the guard): not left open |
| P2: three restarts, two frozen accounts | rows grew to 4 and 2 | **1 row each, open, after every restart** |
| P3: seen, allowed and blocked again within a look | 1 row, seen kept, change number unmoved | **2 rows, 1 open, a new row, unseen, change number moved** |
| P4: catalogue orders | | a raise on an open seen row with no newer since is Same (seen kept, change number unmoved); seen then ended leaves the list; end then raise gives a new row; ended_at never before last_at; the index refuses a second open row |
| P6 (new): account removed while its frozen alert is open | | state "marked removed", **alert ended** |

The look's cost again (100,000 supply rows, 3 accounts):

| What | Time |
|---|---|
| Look, rows wanted | 42 µs |
| Look, all rows held or waiting | 5.7-6.8 ms |
| Touch, 50 open rows | 156 µs |
| Prune, nothing to prune | 78 µs |
| Change-number read | 5 µs |

Run under the race detector before the merge (collector only):
`-race -run 'TestAlerts|TestFrozenAccountStopsAlone|TestSignedOutStopsAlone|TestOwnerStop|TestPause'`.
