# Brief E15b: the fix round after the independent review of the frame check's catalogue side (copies track, session C3, 2026-11-15)

For one Opus coder at high effort, in the copy `C:\Users\trabi\Claude\Projects\Telegram\wt-copies-15` on branch
`wip/copies-15` (head d0d91f7c: the piece as its first coder handed it back, with the main head 10a9e3a8 merged
in; change no branch, merge nothing). Go module in `archiver/`. You are a fresh coder: the first one cannot be
resumed. Read, in this order and in full, before changing a line:
1. `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-E15-frame-check-catalogue.md` (what was asked; its rules bind you).
2. `archiver/docs/progress/copies-probe-catalogue-REPORT.md` in the copy (what was built; its departures).
3. `C:\Users\trabi\Claude\Projects\Telegram\wt-copies-review15-scratch\REVIEW.md` (the review: ten findings, the
   test gaps, the mutation table; its probe tests are in that folder: read them, **change nothing there**).
4. The code: `internal/catalog/probe.go`, `schema_probe.go`, `parts_ledger.go`, `vfp.go`; `internal/supply/probe.go`
   and the piece's lines in `supply.go`, `pending.go`, `hourly.go`; the tests beside them.

Commits and pushes as in the first brief (`git -c user.name=Claude -c user.email=noreply@anthropic.com commit`,
messages starting `WIP copies: `, ending with a blank line and `Co-Authored-By: Claude Opus 5.5
<noreply@anthropic.com>`; `git push private wip/copies-15`; never `origin`, never the main branch, never a
force-push). You change only the files the first brief allowed (`internal/catalog`'s `probe.go`,
`schema_probe.go`, `parts_ledger.go`, `vfp.go`, `stats.go`'s probe columns and their tests; `internal/partsledger`;
`internal/supply`), nothing else; `state.go`, `settle.go`, `atsave.go`, `chosen.go`, `ladder.go`, the engine, the
part store and the collector stay untouched. The schema step has opened no real catalogue: its statements may
be changed in place (keep it idempotent; its number is still written nowhere but its two constants).

## What the old app already knows, for this round
- "No ffmpeg" in the old app meant "download now", counted in its report; a check with no answer under the
  speed limit meant the same until 12.26, when 7 big videos (4.8 GB) had gone through and the owner called
  such a download "a critical error". Since then: put back, bounded by 24 hours. **The decision below (finding
  4) follows that rule of the owner's, not the older habit.**
- The old check asked Telegram for a part only when ffmpeg read it; parts once kept were never asked again
  (63 GB reused in 7,916 downloads). **A turn that asks Telegram for something it already has is new with
  this piece and goes** (findings 2 and 7).

## The decisions, finding by finding (the numbers are the review's)
**1 (accepted as written).** The index and all four walks use an expression that never raises:
`CASE WHEN json_valid(meta) THEN json_extract(meta, '$.duration_s') END`. Tests: a video fingerprint whose meta
is `''` and one whose meta is fixed words are stored by `PutFingerprints`, are never candidates, and a file at
the version before that holds both takes the step and opens.

**10 (accepted), in the same statement:** the fingerprint's version comes first in the index and is tested
inside the walk's bounded read, so rows of another version cost nothing of the bound. Show both walks' plans
again in the named test.

**2 (accepted; this is the round's main change): no lane turn that fetches nothing.** At `Next`, for a row in
phase `fetch`: when every part of the plan it would hand out (the stored plan, or the first and last part for
an empty one) already has a `c_part` row, the file is **not handed out**: a door of the catalogue
(`ProbeRejudge(ctx, id, judgeBy, now)`, one transaction, guarded on the file wanted and unclaimed and the row in
phase `fetch`) moves the row to phase `judge` and sets the file aside for its judge (the same reason and
statement shape as `ProbeFetched`'s), no claim, no attempt, **not a round**; `Next` passes the file over.
`ProbeLook` says whether the plan is all kept (one read of the file's `c_part` keys, at most 32 rows), so the
supply makes no extra call for the usual case. A "more parts" verdict that names no part that is not kept
already is settled as an unknown with why `parts-missing` (never a round, never a loop without the 24 hour
bound). Tests: the review's probe B as a named test of yours: over 30 hours on a passed clock, a judge that
never answers and one that always answers unknown cost **1 claim each** (the first plan's), and the file is
downloaded unchecked at its bound, counted.

**3 (accepted as written).** A turn is a retry exactly when the stored plan was fetched before: a mark on the
row (`plan_fetched`), set by `ProbeFetched` when it counts the round, cleared by "more parts". The supply
remembers the plan it handed out per file (a small map under its lock, dropped at the finish) and passes it in
`ProbeFetchedIn.Plan`, so that a "more parts" landing between `Next` and the claim is not marked fetched
(the review's letter K). Test: the review's probe E as yours: rounds never pass `ProbeMaxRounds` in any order
of "more parts", unknowns at `Next` and fetches.

**4 (decided: the owner's rule applies; the brief's 22:53 correction was wrong).** With `FrameCheck` set and
answering false, an eligible video with a candidate and **no row** is no longer handed out as today: it gets
its row and is put off as an unknown with why `no-ffmpeg`, by the same door that settles an open row
(`ProbeNotReady`, which now makes the row when there is none). So every such file is on record, the 24 hour
bound applies, and a judge that is broken for a day delays the videos that have a candidate instead of
letting possible copies through. Nothing else changes for files without a candidate (as today, counted) or
with `FrameCheck` nil (bit for bit as the base: the review confirmed it; keep it so and keep that test).

**7 (accepted, by the same door).** When a probe turn ends with `Refused` (the part store would not keep a
part: in practice no room), the supply plans nothing and hands out no stored plan for 30 minutes (a field
under its lock, renewed by each further `Refused`, counted in `Stats.Probe`); during that time an eligible
video with a candidate or with an open row is put off as an unknown with why `not-kept` through the same
door as finding 4 (no claim, the bounds apply). After it, one file is tried again.

**5 (accepted, without touching `state.go`).** (a) In `probeSettle`, a word for a file that has no collector
row, or is skipped, gone or saved, closes the row whatever the word: phase `done`, result `left` (a new
result word: the file left the frame check's path; not "unchecked"). (b) `ProbeJobs` lists only rows whose
file is wanted, set aside or held (a join on `c_want`), so no file is judged for good. (c) A new door
`ProbeCloseLeft(ctx) (int64, error)`, in chunks as `ProbeCloseAll`: every open row whose file has left
(saved, gone, skipped, no collector row) becomes `done` / `left`; the collector calls it beside the part
store's sweep. (d) `ProbeCloseAll` closes as `switched-off` only rows whose file is still wanted, set aside
or held; the others as `left`. (e) `ProbeStats` counts `left` apart. Tests: the review's probes F and Zombie
as yours.

**6 (kept as designed; a line for the collector, not yours).** Say in your report, in one paragraph for the
main session's board message, the two calls the collector owes: `ProbeCloseAll` with `switched-off` at a start
with the frame check off, and `ProbeCloseLeft` on the sweep's timer.

**8 (accepted as written).** A "copy" for a file the owner released or set to be fetched for real keeps its
parts: the rows are deleted only where the file is held. **9 (accepted as written).** `ProbeCloseAll` counts a
chunk only when it committed.

**Letter D (one change).** A failed `ProbeLook` or settling ends that `Next`'s batch: what was gathered so far
is returned and the lane asks again at its next tick (as a failed lane read does today), instead of the
further asks 8 and 64 times larger. A file put off or sent to its judge by a door still counts as passed
over, as now.

**The test gaps (all four):** a test that fails when a "copy" holds a released or a fetch-real file (m2); when
a decisive word on a done row is ignored (m4); when held copies are looked at (s3: with `held_wait` off, a
held copy handed out carries no plan and costs no look); and the "never plan" rule through the real `Requeue`
path, not a set filled by hand (s1).

## Added 11-16 00:11, at the owner's word ("The stuck verdict seems like a weak spot. Can there be parallel checks, or perhaps a stricter timeline?")
The 24 hours came from the old app under Telegram's speed limit, where a check that had no answer might get
one hours later. **With the limit off the old app gave a failed check one more try and then downloaded** (its
`ix_dl_check.go` line 361), and a video that waited more than 2 minutes for a check slot downloaded. Here no
check waits on Telegram, and after finding 2 a retry costs no request, so a file whose own check keeps failing
gains nothing by waiting a day. The judge gets two workers in its own round; yours are these three:
- **T1. Two kinds of unknown.** *The file's own* (`timeout`, `ffmpeg`, `ffmpeg-io`, `parts-missing`,
  `no-answer`): the file is put off **5 minutes** (a named constant), and each one that brought no new part
  since the unknown before it counts toward the bound of 3 (`ProbeSameFailsMax`, until now for `ffmpeg` only),
  whatever its why among these five; at the third the file is downloaded unchecked, counted, the last why on
  its row. An unknown after a new part starts the count again. *The system's* (`no-ffmpeg`, `not-kept`,
  `flood`): unchanged: 15 minutes or an hour, the 24 hour bound with the 6 hour gap; they neither count toward
  the 3 nor clear it. The 24 hours stay the outer bound for both kinds. Tests, on a passed clock: three
  timeouts end a file in about 15 minutes; a stuck verdict (three `no-answer`) in about 30; a `no-ffmpeg`
  between two timeouts changes nothing in the count; a new part clears it; `no-ffmpeg` alone still takes 24
  hours.
- **T2. A file waits for its judge 5 minutes, not 15** (`DefaultJudgeWait`).
- **T3. At most 16 checks in flight** (`supply.Config.ProbeInFlight`, default 16; the old app ran 10 at once).
  While that many files have an open row (phase `fetch` or `judge`; one count read through an index, at most
  every `ModeEvery`, by a door `ProbeOpen(ctx) (int64, error)`), the supply makes **no first plan**: an
  eligible video with a candidate and no row is passed over for a later `Next` (it stays wanted; nothing is
  written; counted in `Stats.Probe` as "the judge is busy"), so that a lane with many such videos cannot fill
  the judge's list faster than it is judged and push innocent files past their 5 minutes. Files that already
  have an open row go on as before, and every other file is handed out as today. Tests: 40 eligible videos
  at the head of a lane with ordinary files behind: never more than 16 open rows, the ordinary files are
  handed out meanwhile, and the 40 are all planned as rows close; a failed count is taken as "busy" (fail
  closed) and counted.

## Not in this round
The reason text of a frames-held copy after a set-aside (`state.go`, noted for a later piece); "same facts" on
`ProbeJob`; a final why for ffmpeg's `format`; any change to the bounds' numbers.

## Tests and runs
As the first brief: `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`, then in
`archiver/`: `GOGC=25 GOMAXPROCS=2 go test -p 1 -count=1 ./internal/catalog/ -run '<names>'` (and supply,
partsledger). Named tests only for catalog and supply; no race detector, nothing in Docker, no `go vet` over
the tree. Before each go command look at the free memory and wait when under 2.5 GB; never two go commands at
once. At the end: gofmt on your files, `go build ./...` once, `go vet` on the three packages, every `TestProbe*`,
`TestParts*`, `TestVideoCandidates*`, `TestSupplyProbe*`, the two column tests and the schema tests by name once
more (the seconds in your report). For every fix say which test fails without it (break it on purpose once).
No test judges on real seconds.

## Hand-back
Commit after each finding's fix and its test (so that the reviewer's second pass can read them one by one),
pushed, the copy clean. Add to `archiver/docs/progress/copies-probe-catalogue-REPORT.md` a section "The fix
round" (per finding: what changed, where, the test; the doors' final list; departures and doubts; the
paragraph for the collector), and keep `copies-probe-catalogue-PROGRESS.md` current with times from `date`.
Your last message to the main session: the head commit, then at most 25 lines.

## Decided by the owner, 11-16 00:25, after T1 was built ("No to hold for 24 hours. Try again and reset ffmpeg or fallback to CPU."): T1 is revised (written 00:26)
Asked whether a system-wide failure (ffmpeg missing or failing its self-test, no room for kept parts) should
keep holding videos for up to 24 hours, the owner said no. So **there is one kind of unknown for the bound,
not two:**
- **Every passing unknown** (`no-ffmpeg`, `not-kept` and `flood` included) puts the file off the same 5
  minutes and counts toward `ProbeSameFailsMax` (3) when no new part came since the unknown before it,
  whatever the whys were; at the third the file is downloaded unchecked, counted, its last why on its row.
  An unknown after a new part starts the count again, as before. The split of commit e83361bc ("the file's
  own" against "the system's") goes: one list, one pause, one count.
- The 24 hours and the 6 hour gap stay only as the outer bound (a file whose unknowns keep bringing new parts).
- What this means with ffmpeg broken: a video with a candidate gets its row (finding 4, unchanged), waits
  about 15 minutes in all while the judge looks for ffmpeg and tests it again every minute and falls back to
  the CPU decoder, and is then downloaded as without the frame check, on record as unchecked `no-ffmpeg`.
  With no room for kept parts (finding 7, unchanged otherwise): the same through `not-kept`.
- Tests to change or add, on a passed clock: `no-ffmpeg` alone ends a file at the third, about 15 minutes;
  `not-kept` alone the same; whys mixed (a timeout, a `no-ffmpeg`, a `no-answer`) count together; a new
  part clears the count; the 24 hours as the outer bound (unknowns each after a new part, the parts bound
  not reached: ended at 24 hours). Say in the report which of e83361bc's tests changed.
