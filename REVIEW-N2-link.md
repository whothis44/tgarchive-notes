# Review N2: the PC-NAS link (nasproto, nasctl, nasdl), independent (Opus), 2026-11-21

Branch `wip/nas-link`, commits 9ce3b4d9 and f0abe449 over af4ca40e, read in `wt-nas-link` (nothing edited there).
I read the brief, sections 1, 2 and 6 of the design, all three packages and their tests, and the parts of
`engine/types.go`, `engine/lane.go`, `supply/supply.go`, `supply/pending.go`, `store/ledger.go` and
`collector/collector.go` that show what a lost or a double call does. Five probe tests are in
`C:\Users\trabi\AppData\Local\Temp\claude\71f159c3a9e5d4b9\eb2fe7b8-c207-44b6-ab26-9a345fd154a3\scratchpad\review-n2\probe_review_test.go`.
They were loaded with `-overlay` (overlay.json beside it) and run once through go1.sh: `-run TestProbe`, all
five reproduced, "go1: exit 0". Invented data only. CONFIRMED means a run showed it. PLAUSIBLE means I found it by
reading the code.

## Findings, ranked

### 1. HIGH, CONFIRMED: an error answer to a journal entry counts as acknowledged, so a failed effect is lost for good
- `nasctl/apply.go:38-55`: `apply` sets `c.st.LastSeq = f.Seq` and saves the state **whether or not `applyOne`
  failed**.
- `nasdl/node.go:583-594`: `answered` calls `n.j.ack(seq)` for any answer that is not "link down", errors
  included, and the ack is cumulative.
- `nasdl/remote.go:303-309`: `RemoteLedger.write` returns nil when the answer is late, so the writer thinks the
  write succeeded.
- Scenario P1 (`TestProbeLedgerErrorLost`): the PC's ledger fails `CopyDone` once with a transient error ("database
  is locked") after the NAS's FinishWait. The writer is told nil. The PC records seq 1, the NAS drops the entry, and
  a cut and restore resends nothing. Result: calls=1, the file stays in staging, the journal is empty.
- Scenario P2 (`TestProbePCCloseMidWriteLost`): the PC closes, as in a restart or update, while a ledger write is
  running. `Close` cancels `c.ctx` first (`nasctl.go:224`), and `ledgerWrite` uses that context
  (`apply.go:221`). The write fails, the seq is saved, and the next PC run takes the replay as a duplicate
  (dups=1). The write is never applied.
- The same path also swallows:
  - a panic in the PC's handler (code "other");
  - a journaled method that has a table entry but no case in `applyOne`/`ledgerWrite` (answered
    `ErrUnknownMethod`).
- What survives anyway: the real `supply.Supply` finishes do not fail outward (they retry inside the supply and
  keep their own finish log). So today the loss is in the **Ledger writes**: CopyDone, Verified, CopyCopied,
  WantAgain, LinkMade and the rest.
- Fix:
  - PC side, for an error that is not permanent: do not advance LastSeq, answer a retryable code (for example
    "busy"), and stop applying the rest of that stream. Refuse any `Seq > LastSeq+1` with busy. Today a gap is
    applied silently, and the cumulative ack would then drop the missing entry.
  - Give permanent results (`ErrNoQueueEntry`, `ErrUnknownFile`, bad args, not yours) inside the `Ack` (for example
    `Ack.Err`), so the NAS can tell "applied, with this answer" from "not applied".
  - NAS side: on a retryable code, keep the entry pending and end or redo the stream from it.
  - Do not let the controller's own cancellation fail an apply: close the connection first and refuse new entries
    with busy, or give ledger writes a context that is not cancelled mid-write.

### 2. HIGH, CONFIRMED (and a PLAUSIBLE worse case at integration): a PC restart forgets which files the NAS holds
- `nasctl/nasctl.go:107` and `serve.go:152`: the grants are in memory only.
- Scenario P4 (`TestProbePCRestartLosesGrants`): the NAS claims file 1, then the PC is closed and dialled again
  (grants=0). The NAS then crashes and restarts. `replayed` has no old-run grant to release, so file 1 stays active
  and held by nobody (released=0).
- Worse, by reading:
  - The collector runs `sup.Recover()` at every start (`collector/collector.go:780`). Per `supply.go:372-391` that
    makes every active file wanted again, **including the files the NAS's still-running engine is downloading**.
  - The NAS engine claims straight from Next (`engine/lane.go:544`), so it can claim the same file again: a second
    writer for one file.
  - The first copy's `Saved` then meets ErrWrongState. `saveOnce` finds it not saved, and it is dropped as
    `DropNotHolder` (`supply/pending.go:172-191, 203`), while the NAS's writer has already published the bytes.
- Fix:
  - Keep the grants (id, lane, run) in the PC's state file under applyMu.
  - Have the NAS say at the hello which files its engine holds, and rebuild the grants from that.
  - For N4, the collector must not `RecoverActive` a NAS account's files. It should ask the NAS first, and give back
    only what the NAS no longer holds. Say this in the N4 brief.

### 3. MEDIUM, CONFIRMED: a journal that cannot be written loses the finish, and work goes on
- `nasdl/node.go:653-658`: when the append fails, the call is "sent without it" with seq 0. With the link down it
  is simply gone.
- `node.go:741-744`: `journalFull` does not look at write failures, so `mayTake` stays true.
- `journal.go:236-240` and `245-249`: when compaction fails it leaves `j.f = nil`, which turns **every** later
  append into this case without any notice.
- Scenario P3 (`TestProbeJournalFailLosesFinish`): the journal is closed to stand for a full disk while the link is
  down. A `Release` then gives journalFails=1 and releasesAtPC=0; file 1 stays active, and mayTake is true.
- A seq-0 frame also skips the ordering and the de-duplication.
- Fix:
  - After a failed append, keep the entry in memory in order and retry the write.
  - Set a lasting "journal broken" state that makes `mayTake` nil (fail closed) and shows in the status.
  - Never send seq-0 frames.

### 4. MEDIUM, CONFIRMED: a replay larger than the PC's ordered queue makes the link drop and replay again
- `nasproto/conn.go:82` and `285-289`: the reader puts Seq frames into `ordered` (1024 slots) and blocks when it is
  full. While it is blocked it reads neither the NAS's pings nor the replies to the PC's own pings. Both sides' pings
  then time out and the link is cut.
- `nasdl/node.go:519-546`: `replay` sends every pending entry at once while holding `sendMu`. Every finish the
  engine makes meanwhile waits behind it, up to WriteTimeout (30 s) per frame.
- Scenario P5 (`TestProbeLongReplayFlaps`), with the test's 3 s idle timeout: 2,500 SaveProgress entries at about
  3 ms of apply each went out 7,016 times in all before the queue drained in 18 s. It converges, but by repeated
  cuts.
- In production the idle timeout is 45 s. Each entry costs an fsync of the state file plus a catalogue write. A
  backlog of a few thousand entries can reach that: checkpoints every 8 MiB of the files in hand, for up to the
  10 minutes away.
- Fix:
  - Send the replay in windows (at most K entries unanswered, for example 256), letting `sendMu` go between
    windows.
  - Keep the reader reading: an unbounded queue, or flow control that does not stop the reading.

### 5. MEDIUM, PLAUSIBLE: every journaled Supply call waits up to 30 s for the PC, although it is already synced
- `remote.go:107-237`: every finish is called with `wait=true`.
- `engine/lane.go:1272-1276`: `SaveProgress` runs on a file's checkpoint path.
- A slow PC stalls each file for FinishWait (30 s) at each checkpoint and finish. For example, applyMu held by a
  slow catalogue write, while the reader still answers pings, so the link looks alive.
- A section still running past StopGrace is abandoned by the engine's `Wait`.
- Fix: wait only for `HandOver`, which needs the answer, and for Ledger writes, which need the permanent errors.
  Return at once for the rest.

### 6. LOW, PLAUSIBLE: nothing locks the journal's folder (`journal.go:76`)
- Two NAS processes on one folder, for example an old container still stopping or N3's `check` command, give the
  same numbers to different entries. The PC applies one and takes the other as a duplicate, so it is lost.
- The second run's hello makes `replayed` (`serve.go:160-175`) release the first run's claims while that run is
  still writing their bytes.
- Fix: a lock file (flock or O_EXCL) held for the Node's whole life; refuse to start without it.

### 7. LOW, PLAUSIBLE: a corrupt record in the middle cuts everything after it
- `journal.go:120-128` and `85`: `load` stops at the first unreadable record and `Truncate(good)` silently drops
  the synced entries behind it.
- Fix: fail closed (refuse to open) unless the bad record is the last one, or add a checksum per record.

### 8. LOW, PLAUSIBLE: a state file that cannot be written is only counted
- `apply.go:48-50`: the entry is still acknowledged. After a PC restart with the old file, entries the NAS still
  holds (their answer lost) are applied a second time.
- Consider answering busy while the state cannot be written.

### 9. LOW, PLAUSIBLE: an unknown duplicate hand-over is taken as "handed"
- `remote.go:145` and `node.go:607`: `Dup && !Known` counts as handed. That happens when the apply failed, the
  answer was pruned beyond 256, or the state write failed.
- If the PC's real answer was false, the PC keeps the file claimed for this lane while the NAS engine has dropped
  it, and nothing in the same NAS run releases it.
- Fix: treat "unknown" as not handed and journal a Release. The account-scoped release does nothing to a file that
  was really handed.

### 10. LOW, PLAUSIBLE: a reply over MaxFrame ends the link instead of answering
- `conn.go:350-352` and `frame.go:439`: a reply larger than MaxFrame (4 MiB) ends the link instead of answering an
  error. For example `KeptTokens` with about 60,000 tokens, or a large `DueCopies` or `LinksDue`.
- The caller asks again, so the link drops each time.
- Fix: answer "too_large", and bound N in the calls that return lists.

### 11. LOW: a claim whose answer is lost at Close is never released
- `remote.go:94` leads to `node.go:649`: once `n.ctx` has ended, the `Unclaim` is not journaled.
- It is covered only while the PC lives (it releases the old run's grants), so with finding 2 it is one more file
  left claimed.

### 12. LOW: the connection cap is counted before the handshake
- `node.go:329-342`: four connections from any home device, held open through HandshakeTimeout and opened again,
  keep the PC out.
- After AwayStop the NAS then stops its work. Consider a cap per address.

### 13. Tests that prove less than they say
- `wire_test.go:44-52` (TestPairedKeysOnly): the stranger PC uses account 2, so the hello refuses it even if
  pinning were broken, and the refusal is counted either way. Only nasproto's `TestPinnedKeys` really proves the
  key check.
- No test restarts the PC (a Controller closed and dialled again on the same state file). The "once across a PC
  restart" claim is untested, and P2 and P4 break it.
- No test gives an error answer from the PC.
- The reflection test proves that the table covers the interfaces, but not that `nasctl`'s dispatch has a case for
  every journaled method. A missing case is lost silently (finding 1).

## Checked and found sound
- **TLS:**
  - The pin is an exact DER match, TLS 1.3 only, with `RequireAnyClientCert`.
  - The client has no session cache, so there is no resumption that would skip `VerifyPeerCertificate`.
  - The handshake proves the key is held.
  - TLS 1.2, a stranger's key both ways, and plain TCP are refused (nasproto test).
- **Allow-list:** checked on RemoteAddr before the handshake, with Unmap and the zone removed. Tailscale's
  100.64/10 is not in it.
- **Privacy:**
  - Errors cross as fixed-word codes (`fixedWord`), and the other side's own text never crosses.
  - Every log line is a constant format with numbers or constant words.
  - The NAS id, epoch, paths and locators are carried only in frames and in the local files (state file 0600,
    journal 0600). Nothing printed shows them.
- **Order:**
  - `sendMu` makes the journal's order the order on the wire.
  - The PC applies Seq frames one at a time on one goroutine per connection, under applyMu across connections.
  - Each connection's stream is a contiguous run of numbers, so the cumulative ack is right as long as the PC never
    advances on a failure (finding 1).
  - Replay comes before any new Next or Claim (`up` is set only after `Replayed` is answered, and only after every
    entry has been answered).
- **Claim races:**
  - A grant made on a connection already closed is released at once.
  - A lost claim's Unclaim is journaled and always reaches the PC before the file can be claimed again.
  - The PC dials anew only after the old connection is dead on its side.
- **Fail closed:** Next, Claim, Refresh (ErrLinkDown with 0 requests), Check (unknown, ReasonNoPC), Kept/Indexes and
  LoadHolds (HoldUnread) all need the replayed link.
  - Drain and Stop work, and so does AwayStop with the injected clock.
  - The journal's cap stops new work without dropping anything.
- **Hand-over:**
  - Nothing is journaled while the link is down.
  - A late "false" is settled by a journaled Release (in the same run).
- **Other points:**
  - LoadProgress reads the journal first.
  - No link I/O happens under applyMu.
  - Close waits for every goroutine (the tests' goroutine count agrees).
- **Calls applied twice in the PC-crash window, against the real supply:**
  - Saved: `saveOnce` looks up the same bytes, so it is safe.
  - Aside, Gone and Release: account-scoped, so the second one meets ErrWrongState and is dropped, unless the file
    was claimed again in between.
  - SaveProgress, SaveHold and SaveFileWait: safe.
  - CheckSame: "the record needs the claim", so safe.
  - Ledger writes: `CopyFailed` and `CopyBack` count the attempt twice. A second `WantAgain` after a revival would
    mark the file lost again.

## Second pass (fix 4a5d160c)

I reviewed only `git diff f0abe449..4a5d160c`. Eight probes are in
`C:\Users\trabi\AppData\Local\Temp\claude\71f159c3a9e5d4b9\eb2fe7b8-c207-44b6-ab26-9a345fd154a3\scratchpad\review-n2\probe2_review_test.go`
(`-overlay overlay2.json`, `-run TestRv2`, through go1.sh). Two of them failed:
- `TestRv2CorruptLengthInMiddle` failed because it shows the defect it looks for (point 7 below).
- `TestRv2JournalFail` failed because its own assertion was wrong. It expected no release at the PC while the
  journal was broken, but the new reconciliation releases the file at Replayed. That release is harmless for a
  Release entry; it turns into a lost finish for a Saved entry, which is new finding A.

### My findings 1 to 7, against the fix
1. **Fixed, CONFIRMED.**
   - A transient ledger error answered late is now sent again and applied (calls=2, the file reaches the library,
     retries=1).
   - A PC Close during a write: the write is not cut short, it is applied once, and the next PC run takes the replay
     as a duplicate (calls=1, dups=1).
   - A gap past memLast+1 and a state file that cannot be written are both answered "send again".
2. **Fixed, CONFIRMED.** The grants survive a PC restart (grants=1, Held=[1]), and the NAS's restart then releases
   them (state wanted). See A and B below for what the reconciliation brings.
3. **Fixed, CONFIRMED.** With the journal broken, no new work is taken (mayTake=false), nothing is sent without a
   number, the entry waits in memory and is written again, and a failed compaction opens the file again.
4. **Fixed, CONFIRMED.** 2,500 entries were sent 2,500 times with none sent again (before the fix: 7,016), in
   windows of 256, and the reader no longer waits on its queue.
5. **Fixed** for the Supply finishes. HandOver and the copy queue's writes still wait, at most FinishWait.
6. **Fixed.** The journal's folder is locked (flock on the NAS, an exclusive open on Windows).
7. **Half fixed, CONFIRMED.**
   - A corrupt payload in the middle is now refused (CRC).
   - A corrupt **length field** in the middle is still taken for a torn tail. The probe set record 2's length to run
     past the end: the journal opened with 0 of 3 synced entries and was cut from 289 to 52 bytes.
   - Fix: let the CRC cover the length too (or a fixed magic plus a CRC of the header). Or, before cutting a "torn
     tail" longer than a page, look for a valid record after it and refuse when one is there.

### New, from the fix
- **A. MEDIUM, CONFIRMED: a Saved still waiting unwritten loses its file at the reconnection**
  (`TestRv2UnwrittenSavedFileReleased`).
  - Where: `nasctl/serve.go` `replayed` releases every grant not in `cs.held`, which holds only the engine's
    holdings. `adopt` keeps `Pending`, but `replayed` drops it.
  - The finish of an entry left unwritten (journal broken) is not in the replay: `replayed` waits only up to
    `writtenLast`. So the PC frees the file while its Saved waits in the NAS's memory.
  - Result: state wanted, releasesAtPC=1. After the flush the Saved arrives as a stray (stray=1). The real supply
    would drop it as not the holder (`supply/pending.go` `final`): the NAS's bytes go unrecorded, and the file is
    downloaded again, possibly by another account's lane in the meantime.
  - Fix: in `replayed`, keep every id in the hello's `Pending` as well (store it on `connState` like `held`).
- **B. MEDIUM, PLAUSIBLE: the hello can miss a claim that is still in flight.**
  - Where: `nasdl/remote.go` `Claim` calls `hold()` on any OK answer, without checking that the answer came on the
    current, replayed link. `heldNow()` is taken right after `attach()`.
  - Scenario: the PC granted the claim on the old connection A (grant saved, answer written) and A then died on the
    PC's side. The NAS reads A's late answer after B's hello was built. `adopt` releases the file because it is not
    in Held, while the engine goes on to download it.
  - The reverse also exists: `adopt` takes in a file listed as held that the state lacks, without a catalogue claim,
    and only hides the inconsistency.
  - Fix:
    - Record a claim as "in flight" before the call and list in-flight claims in Held. Or, on an OK answer whose
      connection is no longer `n.link`/up, journal an Unclaim and return false.
    - For a file taken in at the hello, claim it in the catalogue (`Supply.Claim`), and count or log it when that
      fails.
- **C. LOW, CONFIRMED: Next waits up to CallTimeout (60 s by default) for every earlier entry, and returns nothing,
  while any entry is answered "send again"** (`TestRv2NextStallsOnRetry`: 0 files after 5 s, the rig's CallTimeout,
  retries=3).
  - This is fail-closed, not a loss: one entry the PC keeps refusing as transient halts all new work. Each lane's
    claim goroutine is held 60 s per try, and HandOver and copy writes add 30 s each.
  - Make it visible on the PC (Retries rising with a non-empty journal) and say it in the status. A read-only or
    full PC disk does this for as long as it lasts.
- **D. LOW, PLAUSIBLE: a frame-level error to a numbered entry is retried for ever.**
  - Where: `answered`, the `f.Err != nil` case. Examples: a journaled method unknown to an older PC (`Lookup` fails
    and gives ErrUnknownMethod), or a decode failure outside `apply`.
  - The stream stalls behind it: safe, but silent. Consider giving up after N tries with a counted "refused for
    good", as `apply` does for a permanent answer.
- **E. LOW, PLAUSIBLE: the permanent-error list.** The list is right for the catalogue's ledger (ErrNotFound means
  no file or no queue entry, ErrWrongState means not in the library, both stable). One caveat: the real supply's
  `Saved` is accepted into its own retry queue, so "applied" does not mean recorded. A ledger write that followed a
  Saved with no read between could meet ErrNotFound and be dropped for good. Today every copy-queue write follows a
  `DueCopies`/`DueChecks` read, which gates it. Keep it that way, and say it in the RemoteLedger doc.
- **F. LOW, PLAUSIBLE: a copy write answered late returns nil while the entry is still out.**
  - The copier's next `DueCopies`/`Queue` read is not held behind it (only Next calls `settled()`), so it can see
    the state before its own write and act on it again. A second CopyFailed counts the attempt twice.
  - Fix: let the copy queue's reads wait `settled()` too.
- **G. LOW: `Controller.Held()` exists only after a successful `Dial`.** If the NAS is down when the PC starts, the
  collector has no list to keep out of `Recover`. Offer a reader of the state file that needs no link (for N4).
- **H. LOW: a journaled Release, Requeue or Gone is applied without checking the grant** (an Unclaim is). Today the
  order is safe: Next waits `settled()`, and the catalogue's release is account-scoped. Checking the grant would
  keep it safe if that order ever changes.

### Checked and sound in the fix
- The send-again path: the rewind is taken once nothing is out, the pause doubles to 30 s and resets on the next
  answer that is not a retry, and every later entry in the window is answered "gap", so nothing is skipped.
- The cumulative ack is capped below the first unwritten entry.
- `put` cuts a failed write back to the good length.
- An unknown hand-over answer is now released.
- An answer over the frame cap gets `too_large` and the link stays.
- An Unclaim at Close is journaled.
- The handshake cap sheds the oldest connection, so stalled handshakes cannot keep the PC out.
- The PC's `Close` closes the connection before cancelling, and a ledger write is bounded at one minute.
- No lock is held across the sends.
