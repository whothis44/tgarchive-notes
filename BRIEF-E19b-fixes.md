# Brief E19b: the fix round of the owner's word on a probable pair (copies, session C4, 11-16)

**For a fresh Opus 5.5 coder at high effort. You continue another coder's branch. Routine steps are not yours to
repeat: named tests of what you change only; the whole runs, vet over packages, the race detector and the merge of
the head come once, later, by a clerk.**

- Copy: `C:\Users\trabi\Claude\Projects\Telegram\wt-copies-19`, branch `wip/copies-19`, head 4bb0ba2c. Work only
  there. Go: `. /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`, then the copy's `archiver`.
- Read first: `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-E19-owner-verdicts.md` (the piece's brief: its rules
  on files, privacy, tests and the PC bind you too), `archiver/docs/progress/copies-pairword-REPORT.md` on the
  branch, and the review in full: `C:\Users\trabi\Claude\Projects\Telegram\REVIEW-E19-owner-verdicts.md`. The
  reviewer's probes are in `C:\Users\trabi\Claude\Projects\Telegram\wt-copies-review19-scratch` (three
  `zz_probe_*_test.go` files; **`TestProbeBatchPanic` hangs by design: never run it without `-timeout`**): read
  them and take them as tests under proper names; do not edit that copy.
- **One commit per fix, each with a test that fails without it** (say per fix what you broke to see it fail).
  `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, the message ending with
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; `git push private wip/copies-19` after each.
- **The one line in `staging.go`'s `WantAgain` must stay the branch's last commit** (Core may still say no to it):
  put your commits before it by making them now and, at the very end, moving that one commit to the top again
  with a revert and a fresh commit of the same change (no rebase, no force push: the branch only grows).
- Files: `internal/catalog` (the piece's files; `state.go` and `lane.go` only if fix 3 needs the Supply's settle
  to see the pending files, and then in a commit of its own), `internal/pairwords`, and, for fix 3's turn only,
  `internal/supply` (ours; **another branch of this track changed `supply.go` and `pending.go` around the saves:
  touch only the settle's lines**). Not: `bringin.go`, `chosen.go`, `catalog.go`'s `Batch`, `internal/collector`,
  `internal/store`, `internal/viewer`. If a fix needs one of those, write the line it needs into the report and
  build the rest.

## The fixes (the review's numbers)

**1. HIGH: a word, or a lost look-alike, must never make wanted a file the owner did not choose.** "Held and
`probable = 1`" is not a proof that the file is collected (a chat switched off, or an attachment made an
alternative version, while the file was in transfer: `Release` gives it back held with `probable = 1`). Wherever
this piece writes `state = 'wanted'` (`pairRejudge`'s release and its marked branch, `HoldLookAlike`'s new
"ended" branch, `HoldExact`'s word branch, `pairEdgeLost`'s branch for files in transfer or set aside as far as it
decides what the file comes back as), decide first as `wantAgainMedia` decides for a media at this moment,
**reusing its facts read and its rule, not writing the rule again**: carried only as an alternative version: held
as one (`ReasonAlternative`, not probable); no carrier collects its kind, or its topic is not chosen: held as not
collected (the reasons the chat settle and the topic rule write, not probable), so that it comes back by
`judgeChat` and the topic settle when it is collected again; otherwise wanted (or held against another saved
file, or marked, by rung 6 as now). Never skipped, never gone, also not by the known-list branch of
`wantAgainMedia` (a file on another archive's saved list is left held as it is, counted: this door never skips).
Tests, one per case and per entry (the word; `ClearPairWord`; `lostLookAlike`; the exact check's hand-backs): a
chat switched off, a kind no longer collected, a topic not chosen, an alternative version, each made while the
file was in transfer and each made while it was held; the reviewer's three failing probes pass.

**2. A missing or emptied `verdict` table must not take back the owner's words.**
- An existing decisions file with no `verdict` table is a failure of the file (counted, the pause as for any
  failure), never "no words".
- A read that would take back more than 10 words in one turn is not applied at once: it is counted and said once
  in fixed words, and applied (in chunks) only when the same words have been absent at every read for 24 hours by
  the reader's clock (a bound: a reset or replaced viewer file undoes nothing for a day; a real mass take-back is
  applied a day late). Up to 10 take-backs in a turn are applied at once, as now. New and changed words are
  always applied at once.
- Tests: the missing table; an emptied table after 500 words (nothing taken back at once; taken back after 24
  hours on a fake clock; not taken back when the rows come back before that); 10 and 11 take-backs.

**3. A bound on how long the catalogue's writer is held** (measured by the reviewer: `WantAgain` with 5,000
look-alikes held against the lost file 1.95 s in one transaction; a chunk of 500 take-backs 478 ms; TRIED-BEFORE
21's rule).
- `lostLookAlike` inside `WantAgain` removes the edges to the lost media (measure that statement at 5,000 edges
  and say the figure; if it is over 50 ms, bound it too) and settles **at most 200** files in that transaction.
  The rest are written to a small table of files waiting to be judged again (add it to this piece's schema step:
  `c_pair_pending(tg_media_id INTEGER PRIMARY KEY)` or the house's form), counted (`lookalike.lost_pending`).
- A door `SettlePairPending(ctx, limit)` judges up to `limit` (100) of them per transaction as `pairEdgeLost`
  does, and answers how many are left. **It must be driven by a turn that exists in the running program without
  any new flag: the Supply's settle** (read how `Catalog.SettlePending` and `Supply.Settle` carry the chat
  settle's chunks; hook the door in there with the fewest lines, with a gap between chunks as the others leave).
  A file in that table is never supplied to a lane before it is judged (it stays held meanwhile) and is never
  left there for good: say in the report what happens at a restart and when the settle fails. If the hook needs a
  line in a file you may not touch, write the line into the report, call the door from `internal/pairwords`'
  turn as well, and say plainly that the settle's line is owed.
- The reader's chunk: at most 100 operations per catalogue transaction when they can judge files again
  ("different" and take-backs); "same" may stay at 500.
- Tests: `WantAgain` with 5,000 look-alikes: at most 200 settled in its transaction, the rest pending, then
  settled by the door in chunks, none supplied before; the writer's time of each transaction asserted under a
  generous bound (say 500 ms on this PC, skipped under the race detector); `WantAgain`'s cost note made true.

**4. The reader keeps no connection to the viewer's file.** Each turn: `Stat` of the main file and of its `-wal`
(size and modification time); unchanged since the last applied read and nothing waiting: nothing is opened.
Changed: when the journal files exist (the viewer has it open): open `mode=ro`, read, close in the same turn.
When they are absent (the viewer is closed): copy the main file with a plain read-only open into the reader's own
work folder (`Config.WorkDir`, required when `Path` is set; never the viewer's folder, never the system's temp
folder: the file holds the owner's keys), stat the viewer's file again: if its size or time changed or a journal
file appeared, throw the copy away and try at the next turn; else `PRAGMA quick_check` and read the copy; the
copy is removed after the read and at the start of every `Run` (a copy a kill left). Nothing is ever created in
the viewer's folder, and the viewer's file can be renamed or removed while the reader runs (the reviewer's
`TestProbeQ7KeptConnection` as a named test, with a listing of the folder before and after). A replaced file is
seen by its stat.

**5. In the reader only** (the hang inside `Batch` after a panic is Core's and goes to Core on the board: do not
touch `Batch`): the pause doubles across repeated panics of a turn (today it stays at 30 s).

**6. `HoldExact`'s word branch** writes the state `backToSQL` writes (held while `probable = 1`, else wanted), so
that a file still held against another file is not made wanted with `probable = 1`. The reviewer's
`TestProbeQ2HoldExactKeepsProbable` as a named test. (Fix 1's decision applies on top.)

**7. The word goes by bytes.** `pairEnded` also removes the probable edges from each file of the pair to the other
media saved with the other file's bytes (`tg_media_file`), both ways, so that "different" on (x, A) does not leave
x held against a twin of A's bytes. The reviewer's `TestProbeQ2TwinEdge` as a named test; an exact edge is never
removed.

**9. Tests the piece owes:** an exact edge to a lost media survives `lostLookAlike` (the reviewer's break B2 must
fail a test); the rest are in fixes 1, 2 and 3.

**10. `applied_at`** is a parameter of the door, given by the caller (the reader's clock).

**11. No word is looked up for a media that is new at `attach`** (it cannot have one): the two seeks are skipped
there, and the stills rule decides while reading its rows as on the base when no word needs checking. Say the
plans and one measured figure before and after (the reviewer's `TestProbeQ3Rate`).

**Not in this round:** 8 (the bring-in's `holdOne` does not know the word: `bringin.go` is the viewer track's;
write the line it needs into the report) and 12 (a `keep_held` file is left held by a "different": counted as it
is; the report says what the viewer could show).

## Hand-back
The report's new section "The fix round" (per fix: the commit, the tests, what was broken to see each fail;
fix 3's figures; what the collector's later line for the reader needs now, `WorkDir` included; anything you could
not fix as written and why; any rule of this brief you think is wrong, **above all in fix 1 and fix 2**).
Everything committed and pushed, the `WantAgain` line the last commit again, the copy clean; `gofmt -l` on your
files and `go build ./...` clean. Named tests only (`-run`, `-count=1`); `internal/pairwords` whole is allowed;
never the whole `internal/catalog` or `internal/supply`; no `go vet` over packages; no race detector. Look at the
PC before each run (less than 2 GB free or the CPU above 80% over a few seconds: wait a minute, at most 10 times,
then `GOMAXPROCS=2`). Your last message: the head's short hash, each fix with its commit and tests in one line,
test functions removed (none expected), files touched outside the piece's own, your doubts.
