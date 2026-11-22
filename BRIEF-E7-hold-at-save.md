# Brief E7: when a video is saved, the wanted videos it covers are held (session C, 2026-11-15)

For one Opus coder, in the copy `C:\Users\trabi\Claude\Projects\Telegram\wt-copies-1` on branch `wip/copies-6`
(create it there from `wip/copies-2b`, head 344bf94, with `git switch -c wip/copies-6 wip/copies-2b`; the only
branch change allowed). Go module in `archiver/`. Commit work in progress as you go (`git -c user.name=Claude
-c user.email=noreply@anthropic.com commit`, messages starting `WIP copies: `, ending with a blank line and
`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, no number of any real archive) and push with
`git push private wip/copies-6`; never `origin`, never the main branch, never a force-push.

## Why
Rung 6 of the ladder (`internal/catalog/ladder.go` `lookAlikeVideo`, the old app's look-alike rule) judges a
video once, when its message is catalogued, against the videos SAVED at that moment. A new account reads its
history first and downloads afterwards, so most pairs of look-alikes are both only queued when judged, and
rung 6 never fires for them (they are only counted: `lookalike.would_hold`). The old app had no such gap: it
compared every queued video with the saved ones every 2 minutes (`ixHeldTriage` step 1: "every waiting file is
checked each round ... so files queued before ... their copy was saved are covered too"), which is how it came
to hold tens of thousands of files against saved ones. Its numbers for what such a hold is worth: of holds
against a SAVED file that a frame check judged, 1,218 were confirmed and 275 released; of holds against a file
that was only QUEUED, 130 confirmed and 400 released. So: hold against the saved file, at the moment it is
saved, by the same rule; never against a queued one.

## Ported from
`C:\Users\trabi\Claude\Projects\Telegram\wt-v12.31\core-service\internal\app` (read-only): `ix_held.go`
`ixHeldTriage` step 1 (lines 535-554) with `ix_copies.go` `ixSavedCopyOf` (530-540), and `ixRecheckAgainstSaved`
(`ix_held.go` 861-903: what the old app did when the better copy of a queued pair was saved: the lesser one is
then held as a copy of the saved file if it still looks like one). Changed, for the recorded reason in
`archiver/docs/TRIED-BEFORE.md` section 22 (a pass over the queue every round starved the servers): not a
timed pass over the queue but one index read at the save, for the saved file only.

## What to build (in `internal/catalog`; read the reports of pieces E1 and E2 under `archiver/docs/progress/` first)
1. A function `holdCoveredBy(ctx, savedMediaID)` run inside the transaction of every path that makes a video
   SAVED with bytes of its own: `Saved` (a finished download; also when its bytes turn out to be a duplicate
   by SHA-256 and it is linked: then the video it is linked to was saved earlier and nothing new is covered:
   say what you do there and why), and `ImportSaved`/`importOne` (a saved video brought in). `LinkSame` links
   a file to bytes that were saved before: nothing new, not called there. List every statement that sets
   `tg_media.file_id` and say for each why it calls the function or not.
2. It applies only when the saved media is a video the rule judges (`videoFacts`: the floor, a length, pixels,
   a preview hash). It reads the videos NOT saved within the rule's length range by the not-saved index (the
   read `countWouldHold` uses, with the byte narrowing and no LIMIT), and for each that passes
   `lookalike.CheapSame(saved, wanted) && lookalike.Covers(saved, wanted)` (the saved file first, as rung 6)
   and whose collector row is `wanted` with `probable = 0`, `keep_held = 0`, `fetch_real = 0`, no mark
   `check_first`, not an alternative-only file and in a chat that collects its kind (the conditions under
   which rung 6 itself would have held it at cataloguing: reuse its code, do not restate it):
   - with a saved file of exactly its byte size that the exact check would take (the E2 helper
     `sameSizeSaved`, the setting not off): it gets the mark `check_first` and stays wanted (E2's rule);
   - otherwise it is held exactly as rung 6 holds: `state = 'held'`, `probable = 1`, `reason =
     ReasonLookAlike`, a probable edge to the saved media with rung 6's evidence text.
   Rows that are `active` (being transferred), `aside`, `held`, `skipped`, `gone` are left alone, and the
   owner's release is never undone: a file the owner released (held to wanted) must not be held again by this.
   Find how the catalogue can know a release (if nothing records it, add the smallest record: say what; a
   schema step needs a number from the main session first: stop and ask).
3. Counted in `c_settings` beside the rung counts: `lookalike.held_at_save` (files) and
   `lookalike.marked_at_save`, with a reader. The `would_hold` count is unchanged.
4. Cost: one index range read per saved video the rule judges, inside the save's transaction. Measure it as E1
   did (the cost test at scale, the same invented density, 50,000 queued videos): microseconds added to `Saved`
   at the median and the densest second. If the median is over 1 ms, stop and say so.

## Tests (invented data only; named)
- `TestHoldAtSave`: two look-alike videos both queued (neither held; `would_hold` counted); the better one is
  saved: the other is held with the edge and evidence, or marked when it has the saved file's byte size; the
  worse one saved first: the better one is NOT held (the saved copy does not cover it); thresholds at their
  edges as rung 6's tests; a third look-alike that is active, aside, held by the owner, released by the owner,
  fetch-real, an alternative, or in a chat that does not collect videos: untouched.
- `TestHoldAtSaveImported`: a brought-in saved video holds a queued look-alike.
- `TestHoldAtSaveDuplicateBytes`: a download whose bytes equal a saved file's: what the brief's point 1 says.
- `TestHoldAtSaveSupply` (in `internal/supply`, with the real engine as E2's tests): a lane of look-alike
  pairs: after the first of a pair is saved the second is never downloaded (held, or linked through the
  check when it is the same bytes); nothing else changes for ordinary files.
- `TestHoldAtSavePlans`: the read names the not-saved index and is covering.
- Mutations, each shown failing a named test, then undone: `Covers` arguments swapped; an active file held;
  a released file held again; the mark not given; the import path not calling it; a LIMIT on the read.

## Rules (hard)
- `Saved` is the download's finish: nothing else in it changes; a failure of the new step fails the save's
  transaction exactly as any statement in it would (say whether that is right or whether the step should be
  kept from failing a save, and why: the old app's rule is "a claim or a finish that fails is retried by its
  own worker and never stops other downloads").
- Touch only `internal/catalog`, a test in `internal/supply`, and `archiver/docs/progress/`. Not
  `internal/engine`, `internal/exact`, `internal/collector`, `internal/viewer`, `internal/bringin`, `cmd/`.
- No goroutine, timer or background pass. Evidence and reasons: rung 6's fixed words and numbers.
- Privacy, load and named-tests-only as brief E1's "Rules" (`BRIEF-E1-lookalike-rule.md`): invented data only;
  `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`; `GOMAXPROCS=2 go test -p 1
  <package> -run '<names>'`; never a whole package, no race detector, no Docker.
- Keep `archiver/docs/progress/copies-atsave-PROGRESS.md` current and commit it with each step; at the end
  `archiver/docs/progress/copies-atsave-REPORT.md` (what was built, every `file_id` statement and the decision
  for it, every test with its mutation, the cost, what was NOT verified, a drafted final commit message).
