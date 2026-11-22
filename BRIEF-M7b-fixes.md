# Brief M7b: the timing piece's fix round (after its independent review)

Written 2026-11-15 21:06 by the mirror session (M3). Same copy, same branch, same rules as `BRIEF-M7-auto-timing.md`
(`wt-mirror-timing`, `wip/mirror-timing`, from its head 0483a87; push only that branch to `private`; nothing
against Telegram; named tests; one go command at a time; the PC measured first). The review:
`C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-review9-scratch\REVIEW.md` (read it whole; its probes are
`zz_m9probe_test.go` there, loaded with `overlay-mirror.json`: take them as tests where this brief says so).

**Its verdict, which I accept:** part A (the random part on the pause and on the 90 s) is sound: 205,344 pause
cases and 16,200 batch moments, none sooner than 2625aa0, no album split, the same number every turn. **Do not
change part A's code in this round.** One medium and four low findings, all in the gathering.

## The error behind F1 is mine, not yours
My brief said a backlog never waits for a gathering "because its oldest candidate is old". It is not: the time
`MirrorMessageTimes` gives is the later of the Telegram date and the account's FIRST SIGHTING, and the reader
stores every page of a history with the sighting set to the moment the page is read
(`internal/tgstore/store.go` `SavePage`: `seen := s.now().Unix()`). So a chat joined and read now has every
message at "now", and the gathering held its whole history (the reviewer's probe: the first forward 130 s after
the read at once, 4,478 s at 60 minutes, 106,853 s at 1,440). The young rule needs that sighting time (an album
still arriving at a page's edge); the gathering must not use it.

## 1. The gathering is judged on when a message was POSTED, over the batch that would go (F1, F2, F4)
- **A new read door, the mirror's own, in `internal/catalog/schema_mirrorauto.go` right after
  `MirrorMessageTimes`:** `MirrorMessageDates(ctx, sourceChat int64, ids []int64) (map[int64]int64, error)`: the
  Telegram date of each message on record (`message.date`), in chunks as its neighbour reads; a message with no
  row is absent from the map. One line in `AutoLedger`, directly under `MirrorMessageTimes` (not at the
  interface's end: another branch adds a line there). This lifts the first brief's "the catalogue's SQL: no
  change" for this one function.
- **`autoBatch`:** first exactly today's path, unchanged: the candidates, their times, the young cut with its
  random part, the albums held whole, the maximum: the batch that would be sent (`bs[0]`). Only then, with a
  gathering of N minutes set and that batch not empty: among the batch's own messages take the one with the
  earliest DATE (a message absent from the dates map is passed over; when none has a date nothing is held); the
  batch goes when now is at or past that date + N minutes + the random part (keyed as now: the album, else the
  message); else nothing goes for this mirror this turn and the wake time is that moment (+ 1 s, as the young
  rule's). So the decision is all-or-nothing on what the turn would really send: it cannot split an album, a
  candidate the batch leaves behind cannot release it (F4), a missing row cannot release it (F2).
- What follows, and must be true in tests: a joined chat's history (old dates, sighted now) is never gathered:
  its create and its batches go exactly as with "at once"; messages put back by a settle and a gap read later
  (old dates) likewise; a live message waits N minutes from its post. Remove `autoTiming.gathering`'s use of the
  sighting time; the dates are read only when a gathering is set (one more catalogue read a turn per mirror
  with a batch, none at "at once").

## 2. The bounds (F3; my decision)
- The gathering's random part: 0 to a quarter of N, at least 30 s, **at most 15 minutes** (`GatherSpreadMax`).
- **The range starts at 3 minutes** (`GatherMin = 3`): 1 and 2 could never outlast the young rule's 90 to 120 s
  and would be a setting that does nothing. 0 stays "at once"; a stored 1 or 2 is then unreadable by the
  existing rule (nothing was ever stored by a build of this branch outside tests).

## 3. The words (F1's two sentences, F3)
- `mirror -gather`'s cost line and `mirror -timing`: the bound in minutes (hours and minutes from 120 minutes
  on), never only seconds, and the whole longest wait said once: a message is forwarded at the latest N minutes
  plus the random part's bound after it was POSTED, and never before the 90 s rule and the pause allow. The
  words "arrived" or "old" for the gathering become "posted".
- The two sentences about a backlog (`mirror_timing_cmd.go`, near lines 116 and 176) made true: "messages posted
  more than N minutes ago (a joined chat's history, messages put back by a settle, a gap read later) are not
  gathered". The same in `timing.go`'s head comment, the flags' help, `run -h`'s paragraph and the note line
  wherever they speak of it.

## 4. One thing the review did not check: a catalogue older than the build
`mirror -timing` and `mirror -gather` on a file at an older schema: `-timing` must work read-only or say in the
fixed words the other read-only mirror commands use that the catalogue is older; `-gather` must not step the
schema without saying so before the yes (look at how `-never` does it on this head: `mirror_marks.go`). Say in
the report what it did before and what it does now, with a named test for each.

## Left as it is, and said in the report as known
F5: a mirror whose batch is being gathered is counted "caught up" (as one whose messages are younger than 90 s
is today). A count of its own comes after M5 has landed (it adds to the same struct).

## Tests (named; the injected clock; each fix's test seen to fail once on 0483a87's code)
- The rig stores a history the way the reader does (the sighting at the clock's now) wherever a gathering is
  tested; `TestMirrorAutoGatherBacklog` is corrected to do so.
- `TestMirrorAutoGatherJoinedHistory` (the reviewer's `TestM9HistorySeenNow` as a test): old dates, sighted now,
  gatherings 5, 60 and 1440: the time from the read to the first forward equals at once's (within the young
  rule's random part), the create is not delayed, every message is forwarded with no hold.
- `TestMirrorAutoGatherMissingDate` (F2): a batch message with no row: the gathering still holds on the others.
- `TestMirrorAutoGatherLeftBehind` (F4): an album whose halves are about 100 s apart under a gathering of 5,
  a message posted in that window: it is held until its own N minutes.
- `TestMirrorAutoGatherPosted`: a message posted T ago but sighted now (a gap read late): held only while T is
  under N; its 90 s from the sighting still apply.
- `TestMirrorGatherSetting`: 1 and 2 refused, 3 and 1440 taken; `GatherSpread(1440)` is 900 s, `GatherSpread(3)`
  30 s. The earlier gather tests (holds, album, no create, unreadable, never mark) pass with reader-like
  sightings. The catalogue's new door: `TestMirrorMessageDates` in `internal/catalog` (dates, a missing row, more
  ids than one chunk).
- The collector's command tests follow the new words and bounds; the two older-schema tests of point 4.

## Running things, report, hand-back
As the first brief. Once at the end: `go test ./internal/mirror -count=1`; `go test ./internal/catalog -run
'MirrorMessage|MirrorAuto' -count=1`; `go test ./internal/collector -run 'Mirror' -count=1`;
`go test ./cmd/tgarchive-collector -count=1`; gofmt on the changed files; `go vet` on `./internal/mirror`,
`./internal/collector` and `./internal/catalog`. The report gains a section "M7b": per point what changed and its
test, how each was seen to fail, the report's earlier sentences about a backlog corrected, every new line that
touches a line M5 also touches, departures, doubts. Commit and push as before; the copy clean; nothing left
running. Final message under 30 lines: the pushed head, one line per point, tests as counts and seconds,
departures, doubts.
