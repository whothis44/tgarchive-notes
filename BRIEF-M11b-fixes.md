# Brief M11b (11-16 03:54, the mirror session M4): the review's low findings on the ended read

The independent review of 85f984de says "may be listed": high 0, medium 0, low 4
(`C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-review12-scratch\REVIEW.md`; its probes beside it, read-only
for you). Three are fixed here; the fourth is another track's.

**Your copy changed.** M9 is on the main head now, and a clerk applied your four commits onto it cleanly:
work from now on ONLY in `C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-endread-m`, branch
`wip/mirror-endread-main` (at c75fafee on the main head 25816edd; your files there are byte for byte those of
85f984de; pushed to `private`). Push only that branch. The old copy `wt-mirror-endread` is left as it is.
Same house rules as `BRIEF-M11-ended-read.md`; this time measure the PC by a command given with its full
path, and run each mutation with a runner that stops on a failed revert (as your second runner did).

1. **F1 (confirmed), the half that is ours:** a page's stop or never mark does not end the reader's turn,
   because the new line fires only on the task's own "ended" event. The doors already set the session's
   `turnDue` flag after their transaction (`nudgeMirror`). **When `autoTurn` finds that flag set at its start,
   the reader's turn ends after the task's turn (`autoTurn` returns "did") whether or not the task sent or
   ended anything**, so that the history pass of that turn does not run on the list read before the door's
   write; the next turn reads the records afresh. Check that this cannot stall the reader (a door call per
   turn would hold the history pass off for as long as the calls come: bound it: the flag ends at most one
   reader turn per door write, which it does if the flag is swapped to false once a turn) and say what you
   measured in a test: a stop written before the turn's `autoTurn`: no history request for that chat in that
   turn or after; 200 door calls during a read of another chat: that chat's read still finishes, and how
   many reader turns it took with and without them. **Not ours and not done here:** a write that lands after
   `autoTurn` returned, or during the history pass, still lets that pass run to its end (up to its pages per
   turn): closing that needs the reader to read the record again before `ReadChat`, in Core's `reader.go`; it
   is said on the board.
2. **F2 (confirmed): a clear misses an end field whose key is written in another case.** After `setReadEnd`
   has built the new record, it is parsed again as the reader parses it (`ReadApproval`): if a clear still
   shows an end, or an end still shows none, nothing is written and the record is "cannot be read" (left
   byte for byte, counted). The reviewer's `TestZZM11KeyCase` as a test of yours.
3. **F4 (by reading): the unreadable-record count grows once per failed and retried event.** A record is
   counted only after the transaction that met it has returned nil (collect the count in the call's
   `readNotes`, add it to the session's count and say the line only on success); a rolled-back end or take
   counts nothing. A test: a closure whose transaction is rolled back after it (the choice of the chat fails)
   counts 0; the retried, successful one counts 1.
4. **F3 is Core's** (`EstimateRead` reads the record, asks Telegram, then writes the old end back outside a
   transaction, so an end or a clear written meanwhile is lost): not touched; said on the board.

Named tests only; each new rule's line undone once and seen to fail. At the end, by name, PC measured first:
your `MirrorEndRead` tests in the mirror and the collector, Core's `ReadEnded` tests in the collector, gofmt
and vet of the mirror and the collector. **No whole package and no `-run Mirror` set: a clerk runs the whole
runs and the race run on your final head.** A section "M11b" in the report; commit, push, the copy clean;
final message: the final commit, what changed per point, each new rule's undone line and its test, the
named runs, anything not done.
