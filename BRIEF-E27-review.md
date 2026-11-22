# Review brief E27 (the queue's "C22"): lesser copies wait behind the best

For ONE independent reviewer (Opus 5.5, high effort). Written by the copies session C6 on 11-16 while the
coder worked. You did not write this code and you have not seen the session's reasoning: that is the point.
You change nothing on the branch. Your start message names the head to review.

## What to read first

1. `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-E27-lesser-copies.md` (what was asked) and
   `NOTE-C22-lesser-copies-record.md` (the old app's rule and numbers).
2. The coder's report on the branch: `archiver/docs/progress/copies-twins-REPORT.md` (its doors table, its
   timings, where it departed from the brief, what it left).
3. The difference itself: `git -C <your copy> diff 78739d59...HEAD -- archiver` (or against the merge base the
   start message names).

## Where you work

A scratch copy of your own, frozen at the head: the start message gives the command
(`git -C <repo> worktree add --detach <project folder>\wt-copies-review27-scratch <head>`). Probes are test
files named `zz_probe_*_test.go` in that scratch copy only: never committed, never pushed. Your helper
scripts and logs: `<project folder>\runs-copies-review27\`. Go commands: one at a time for the whole track
under the lock folder `<project folder>\runs-copies-golock` (`mkdir` to take, `rmdir` to give back, always;
if it exists wait 30 s and try again), with `GOMAXPROCS=2 GOMEMLIMIT=1GiB GOFLAGS=-p=1`; measure free memory
first and wait while under 1.2 GB. Named tests and your probes only: never the whole `internal/catalog`, no
race detector. Invented data only; nothing under `E:\T`, no real catalogue, log or media is opened; nothing
runs against Telegram. Your review is a file: `<project folder>\REVIEW-E27-lesser-copies.md`, written with
the Write tool.

## What must be true (attack each with a probe, not with a reading alone)

1. **Off is the head.** With the switch off or absent: no row in `c_twin`, no row held with the new reason,
   the "would hold" count as before, and the attach of a new video with a queued look-alike writes what the
   head writes. Compare a catalogue driven by the same invented arrivals on 78739d59 and on the branch (the
   rows of `c_want`, `copy_edge`, `c_supply`, the counts).
2. **Nothing is ever skipped or made gone by this piece**, on any path: the attach, the pending door, the
   switch going off, the triggers. A waiting file whose ladder rule says "on another archive's saved list":
   what happens to it, and is that what the report says?
3. **No waiting file is stranded.** For every statement in the coder's doors table, and every statement you
   find that the table missed (search all of `archiver/internal` for writes of `c_want.state` and deletes of
   `c_want`, `tg_media` and `c_reach`, in every package): move the better copy through that door with a
   file waiting behind it; after the Supply's settle has drained `c_pair_pending`, no row of `c_twin` may
   point at a file that is not `wanted`, `active` or `aside`, and no file may be `held` with the new reason
   without a `c_twin` row. Doors to try by name at least: `Saved` (as new bytes, as a duplicate of saved
   bytes, as revived lost bytes), `WantAgain`, `Release` and the requeue of a set-aside file, `Transition`
   each way, `KeepHeld` and its undoing, the owner's release, the exact check's `LinkSame`, `HoldExact`,
   `HoldLookAlike` and `HoldCheckFirst`, the frame check's verdicts, the chat switched off and on, a topic
   un-chosen and chosen, a role change by an edit, a message deleted, a chat removed, an account removed,
   the bring-in's import of a file that is a waiting file's better copy, the owner's "different" on the pair
   and its taking back.
4. **A waiting file is never supplied and never claimed** (`c_supply`, the claim's own statement), with
   "held copies wait" on and off; and a file in transfer or set aside is never made to wait.
5. **The triggers.** Each fires where it must and nowhere else; none can loop (a trigger writing `c_want`
   from a trigger on `c_want`); none fails a statement of another track (a NOT NULL, a missing row); a
   catalogue stepped from 78739d59 and a catalogue made new end with the same tables, indexes and triggers;
   the step is refused on other versions and may run twice. Time a claim and a `Saved` yourself on the scale
   rig's catalogue, before and after, and compare with the report's figures.
6. **The rule itself against the old app's** (`ixGroupCopies`, `ixBetterCopy`): three and four files alike in
   every order of arrival end with the same one wanted; a chain (A like B, B like C, A not like C); two
   files equal in every fact (the lower id goes); the rank guard at equal ranks, a better rank waiting, no
   rank at all; the owner's "different" between two of three.
7. **The writer's time.** The switch going off with 5,000 files waiting; a better copy with 1,000 files
   behind it saved; the door's chunk under `judgeBudget`: how long is the writer held, in milliseconds?
8. **The counts say what they count** (each one traced to its increments; none moves for the wrong event;
   the lost-look-alike counts do not move for a waiting file).
9. **What a page and the viewer would show** for a waiting file: is the report's list of readers of
   `c_want.reason` complete (search `internal/server`, `internal/viewer`, `internal/collector`,
   `cmd`)? Does any of them break on a held row with no probable edge?
10. **The files.** Nothing outside the brief's section 2 is edited; no goroutine, timer or pass over the
    queue is added; log lines have constant format strings; tests use invented data only.

## How to report

`REVIEW-E27-lesser-copies.md`: findings numbered, each with its severity (high: wrong state, a stranded or
skipped file, another track's statement failed; medium: a wrong count, a writer held too long, a reader
broken; low: words, comments, a missing test), the probe that shows it (its name and what it printed, in
numbers), and the smallest fix you would accept. Then what you tried that held. Then what you did NOT check.
Its last line is exactly one of: "may be listed", "may be listed after these fixes: <numbers>", "not ready:
<why in one sentence>". Your final message to the session: that last line, the count of findings by
severity, and the names of your probe files. Numbers and code names only.
