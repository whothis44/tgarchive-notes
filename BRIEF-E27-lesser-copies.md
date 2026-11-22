# Brief E27 (the queue's "C22"): lesser copies wait behind the best

For ONE coder (Opus 5.5, high effort). Written by the copies session C6, 11-16, from its own reading.
You hand back commit-ready work on `wip/copies-27`; you decide nothing that this brief leaves to the session,
and you stop and say so when a premise of this brief turns out false (what to do then is in section 9).

## 0. What the old app already knows (read `NOTE-C22-lesser-copies-record.md` in the project folder first, whole)

In short: of queued videos that look alike (`ixCheapSame`: lengths within 500 ms, aspect within 2%, preview
hashes at most 6 bits apart) the old app let the best go (`ixBetterCopy`: most pixels, then the longer by
whole seconds, then most bytes, then the earliest post, then the lower id) and held the others behind it
(`ixHeldTriage` step 2); when the best was saved the others were compared with the saved file and stayed held
as its copies or were let go (`ixRecheckAgainstSaved`); when the best would not come the best of the rest
went (`ixPromote`). No request. On 11-13 it held 1,544 files, 150.1 GB, that way. The new app only counts
such pairs today (`countWouldHold` in `internal/catalog/ladder.go`: `lookalike.would_hold`), on a figure
("right in 130 of 530") that could not judge those holds (the note's section 3). The record still says
"count first", so: **this piece builds the hold behind a stored switch that is OFF by default; off, the
program does exactly what the main head does.**

One thing is NOT taken from the old app: its pass over the whole queue every 2 minutes. A pass every round
starved the servers (TRIED-BEFORE section 22), and `atsave.go` already chose "one index read at the event".
This piece judges at events only.

## 1. Where you work

- Repository `C:\Users\trabi\Claude\Projects\Telegram\repo-archiver` (do not touch its working tree: it may
  show another session's staged merge). Make your own copy and branch from the main head **78739d59**:
  `git -C <repo> worktree add <project folder>\wt-copies-27 -b wip/copies-27 78739d59`. The Go module is
  `archiver/` in it. Your helper scripts and logs go in `<project folder>\runs-copies-c22\` (yours alone).
- Commit as you go (`git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, the message ending
  with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`) and push `wip/copies-27` to the remote
  `private` (never `origin`, never the main branch, no tag).
- **One go command at a time for the whole track:** take the lock folder
  `<project folder>\runs-copies-golock` with `mkdir` before every go command and `rmdir` it after (if it is
  there, wait and try again; older than 30 minutes: it may be removed); run with
  `GOMAXPROCS=2 GOMEMLIMIT=1GiB GOFLAGS=-p=1`; measure free memory first and wait (2 minutes, at most 10
  times) while under 1.2 GB.
- **While working: named tests only** (`-run`), never the whole `internal/catalog` (9 minutes) or
  `internal/collector`, no race detector, no `go vet` over many packages. The full runs are the session's,
  once, after the review.
- Invented data only in tests. No names, text, paths or ids of anybody's real data anywhere. New log lines
  use constant format strings. Nothing runs against Telegram.

## 2. Files

Yours to change: in `internal/catalog`: `ladder.go` (rung 6's part only: the call that counts today, and new
functions beside `countWouldHold`), `atsave.go`, `pairword.go` (the pending door, section 5), a new
`schema_twin.go`, a new `twin.go`, `catalog.go` ONLY in the three schema places every step touches (see how
`wip/copies-24`'s `schema_edgelog.go` did it: copy `wt-copies-24`, constants `edgeLogAfter`, `edgeLogSchema`;
yours: "the step after `actKeySchema`" on this branch, two constants and one comparison in its test, so that
the integrator sets the number at the merge); tests beside them; `internal/supply` only if section 5 needs a
line there (say why). Your report: `archiver/docs/progress/copies-twins-REPORT.md`.

**Not yours, not to be edited:** `lane.go`, `state.go`, `settle.go`, `chosen.go`, `topics.go`, `catalog.go`
beyond the schema places, anything in `internal/engine`, `internal/collector`, `internal/server`,
`internal/viewer`. If the piece cannot be done without one of them, stop and say which line and why.

## 3. The record: what "waits behind" is

- A lesser copy that waits is a collector row with `state = 'held'`, `probable = 0`, `check_first = 0`, and a
  reason of its own, fixed words: `ReasonTwin = "looks like a better copy that is still queued"`.
  `probable = 0` is what keeps it out of every lane (`c_supply_src` takes a held file only with
  `probable = 1`): **a lesser copy is never supplied while it waits**, whatever "held copies wait" says.
- Which file it waits behind is a row of a new table, NOT a `copy_edge`: every reader of probable edges
  (`mediaNow.probEdge`, `wantRule`, `wantedAsMainSQL`, the viewer's tiles) takes one as "a probable copy of a
  saved file". `c_twin(tg_media_id INTEGER PRIMARY KEY REFERENCES tg_media(id) ON DELETE CASCADE,
  behind INT NOT NULL, evidence TEXT NOT NULL, at INT NOT NULL)` with an index on `behind`. No foreign key
  on `behind`: a better copy that goes away must be seen, not cascade silently.
- Evidence: numbers and fixed words only, in the form of `lookAlikeEvidenceOf` (bits apart, the two lengths,
  pixel sizes and byte sizes).
- **Triggers keep the table true whatever door moves a row** (as `c_supply`'s do, and for the same reason:
  the statements of other tracks' files are not edited). On `c_want`:
  1. a row leaves `held` (to any state), or is deleted: its own `c_twin` row goes;
  2. a row that others wait behind stops coming: it is deleted (that is also how a SAVE looks: `Saved`
     deletes the collector row), or its state becomes `held`, `skipped` or `gone`: every file waiting behind
     it is written to `c_pair_pending` (`INSERT OR IGNORE ... SELECT tg_media_id FROM c_twin WHERE behind =
     OLD.tg_media_id`). `wanted`, `active` and `aside` are "still coming".
  Write each trigger with a `WHEN` on the states so that a claim (`wanted` to `active`) and a requeue pay a
  comparison and nothing else. **Measure it** (section 7).
- In your report, from `state.go`: what ends a file that is set aside (`aside`), and whether any path leaves
  one aside for good. If one does, say so: the session decides the bound.

## 4. The rule, at the one place the count runs today (the attach of a new video)

Today: a new video that no rung held and that is wanted (`isVideo && ar.State == StateWanted &&
ar.Rung == RungNone`) calls `countWouldHold`. Keep that exactly when the switch is off. With the switch on,
instead (one function, in the attach's own transaction, after the collector row is written so that the
triggers see it):

- Candidates: the not-saved look-alikes by `lookAlikeUnsavedSQL` and `lookalike.CheapSame` (the shorter
  first, as `countWouldHold` compares them), whose collector row is `wanted`, `active` or `aside`, and those
  that already wait (`held` with a `c_twin` row: they stand for the file they wait behind).
- The best of the new file and the candidates that are coming, by `lookalike.Better`.
- **The new file is not the best:** it waits behind the best (section 3's record), unless the rank guard
  below says no.
- **The new file is the best:** each candidate that is plainly wanted (the conditions of `coveredWantSQL`:
  wanted, not probable, not kept held, not to be fetched for real, not marked for the exact check, not
  released by the owner, not sent back by the owner's hand, collected as some message's own media, no
  probable edge) waits behind the new file, and every file that waited behind such a candidate is pointed
  at the new file (`UPDATE c_twin SET behind = ...`). **A file in transfer or set aside is never held** (it
  is left as it is; files behind it stay behind it).
- **The rank guard (a deviation from the old app, with its number):** a file waits only behind a file that
  is not after it in its lane's order: the better copy's `best_rank` is not worse than the waiting file's
  (NULL is last; equal is fine). Otherwise nothing is held and the pair is counted
  (`lookalike.twin_rank_kept`). Why: in the old app 67 partly-same videos (35 GB) of ranked chats waited at
  the back until 12.13 let them keep their rank order (TRIED-BEFORE 17); a ranked chat's file must not wait
  for an unranked chat's turn.
- The owner's "different" on the pair (`c_pair_word`, by bytes: `pairDiffer`) ends it: no wait, no count.
- Nothing here writes `skipped` or `gone`, a probable edge, or an exact edge.
- The old "would hold" count goes on counting in both modes (it is the number the default hangs on).

## 5. When the better copy stops coming: the pending door judges the waiting files

`c_pair_pending` and its door exist (`pairword.go`: `SettlePairPending`, `pairPendingJudge`; drained at
every settle of the Supply, 100 a chunk, a time budget, a savepoint per file, counts). A waiting file
written there by section 3's trigger is, by the door's own rule, "held otherwise": `pairJudge` judges it as
a new attachment would be judged now: the ladder's rule first (an alternative version, or not collected:
held as that; on another archive's saved list: see below), then rung 6 against the SAVED files
(`pairRejudge`: held as a probable copy with its edge, or wanted and marked for the exact check first where
a saved file has its byte size), else wanted in its turn. That is the old app's `ixRecheckAgainstSaved` (the
better copy was saved) and the first half of `ixPromote` (it will not come) in one mechanism. What you add:

- **After a waiting file comes back plainly wanted, section 4's rule is applied to it** (as to a new file):
  of several that waited behind the same file, the best ends wanted and the others wait behind it (the
  second half of `ixPromote`), whatever order the door takes them in.
- The door's guards must hold for a row with `ReasonTwin`: kept held by the owner (left as it is; say what a
  kept-held waiting file means when its better copy is saved); `pairWantSQL`'s "a probable copy's reason"
  set and `pairPendingJudge`'s "judged" set: decide by reading them whether `ReasonTwin` belongs in either,
  and say why in the report.
- **The ladder says "skipped" (on another archive's saved list) for a waiting file:** `pairJudge` leaves
  such a file as it is, which for a waiting file would mean waiting behind nothing for good. This door
  never skips. Propose the least rule that does not strand it and does not skip it, and say it in the
  report; if you see no such rule, stop and say so.
- **Counts of their own** (`c_settings`, as the others): held behind a queued file
  (`lookalike.twin_held`, and their bytes), pointed at a new best, judged after the better copy stopped
  coming: held against a saved file, marked for the exact check, wanted again, held as not collected. The
  lost-look-alike counts must not move for a waiting file.
- A waiting file whose better copy went to `held` and came back `wanted` before the door ran is judged
  anyway and may end waiting behind it again: that is right.
- `PairPending` is gated on `hasPairWords`: check that a catalogue with the new step and no word still
  drains.

## 6. The switch and the doors (the catalogue's own; pages builds the controls later)

- The switch is one row in `c_settings`, `copies.twin_hold` ("1" on; absent, "0" or unreadable: off),
  read by the attach **only when a candidate exists** (never for every new file), and by the pending door.
  It takes effect at once, with no restart.
- `TwinHold(ctx) (on, stored bool, err error)` and `SetTwinHold(ctx, on bool) error`. **Switching off must
  leave nothing waiting:** every row of `c_twin` goes to `c_pair_pending` in the same transaction (the door
  then judges each, with the rule of section 4 off, so each ends wanted, or held by rung 6 or as not
  collected). Measure that statement at 5,000 waiting files; if it holds the writer for more than 100 ms,
  chunk it and say how.
- For a page: `TwinOf(ctx, id) (behind int64, ok bool, err error)` (which file a held file waits behind)
  and `LookAlikeTwins(ctx)` (the counts above, and how many wait now).
- In the report, without editing them: every place outside `internal/catalog` that reads `c_want.reason` or
  shows a held file's reason (the pages' Queue and report, the viewer), with one line each on what it would
  show for a waiting file.

## 7. Tests to write (named so they can be run alone; all on invented media)

`TestTwin...` in `internal/catalog`: the switch off equals the head (the count and nothing else; a test that
fails if any row is held or any `c_twin` row is written); the new file lesser, the new file better, three
alike in every order of arrival ending with the same one wanted and two waiting behind it; a file in
transfer never held; the rank guard both ways; the owner's "different"; the better copy saved and covering
(held against it with rung 6's edge), saved and not covering (wanted again), saved with the waiting file's
exact byte size (marked for the exact check first); the better copy deleted, skipped, gone, held as not
collected, held as a probable copy: the best of the rest wanted, the others behind it; a waiting file
released by the owner, kept held, its chat switched off and on (through the real doors of `chosen.go`:
call them, do not edit them); the switch turned off with files waiting; a restart in between (the tables
alone carry it); the schema step (refused on other versions, run twice, a new catalogue ends with the
tables and triggers; follow `TestEdgeLogStep`). `TestTwinNeverSkips`: 300 random worlds of arrivals, saves,
losses and switches: no file ever `skipped` or `gone` by this piece, no file `held` with `ReasonTwin` and no
`c_twin` row, no `c_twin` row whose file is not `held`, no waiting file supplied (`c_supply`), and with the
door drained no file waits behind a file that is not coming.

**Timings, in the report, before and after on the scale test's catalogue** (use the existing scale rig; do
not run the scale test whole): a claim, a `Saved`, an attach of a new video with no candidate, an attach
with one candidate.

## 8. Hard rules

Only exact evidence may skip a file: this piece skips nothing. A probable copy is held, never skipped. A
frame check's "no match" releases nothing here. Nothing in the background reads the library. No goroutine,
no timer, no pass over the queue. A long write never holds the writer for seconds (bounds as `pairword.go`'s:
counts and a time budget). The download path's files are not edited.

## 9. When a premise fails

- If the triggers cost a measurable share of a claim or a `Saved` (more than a few microseconds): stop,
  report the numbers; the alternative (explicit calls at this track's own doors and a sweep in the Supply's
  settle) is the session's to choose.
- If reusing `c_pair_pending` and its door bends their rule (a count that lies, a guard that must be
  special-cased in more than two places): say so and propose a table and door of the piece's own.
- If `chosen.go`'s or `topics.go`'s set-form statements do something wrong to a waiting row (make it
  wanted where it should wait, or probable): do not edit them; write the statement, the state before and
  after, and a failing test, and stop that path there.

## 10. Hand-back

Everything committed and pushed on `wip/copies-27`, the copy clean; `gofmt` clean on your files; your named
tests green (their names and times in the report). The report: what you built, file by file; the doors
table (every statement that changes `c_want.state` or deletes a row, in any file: what it does to a waiting
file and to files waiting behind the row it moves); the timings; every place where you departed from this
brief and why; what is known and left; what the reviewer should attack first. Your final message: the head's
hash, the tests run with their results, and anything you stopped at. Numbers and code names only.
