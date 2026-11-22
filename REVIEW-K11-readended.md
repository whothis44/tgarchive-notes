MAY BE LISTED AFTER THE MUST-FIXES

# Review K11: a mirror's ended read is not read on (`wip/core-readended` at 7e768280, base dbc2f7d5)

Independent, adversarial review, 2026-11-16. Read: the brief, the whole diff, `internal/collector/reader.go` in full
around every changed line, the other writers and readers of the record (`mirror_auto.go`, `mirror_cmd.go`,
`mirror_settle_cmd.go`, `approve_cmd.go`, `chosen.go`, `pages.go`, `internal/mirror/read.go`), `catalog.SaveGap` and
`OpenGaps`. Probes: one `go test -overlay` run (63 s) of the package's named tests with a probe copy of `reader.go`
(each skip site behind a switch) and a probe test file; nothing in the tree changed.

Count: 1 MUST FIX, 2 SHOULD FIX, 4 MINOR.

## Findings

### 1. MUST FIX, CONFIRMED: a chat WITHOUT the field loses its common-box gap read when another chat ends mid-gap
`internal/collector/reader.go:679` (with `:684-693`). The common box's list is now filtered by `skipEnded`, but the
resume index `gapNext[g.ID]` is an index into that list, which is rebuilt every turn. When a chat at an index
already passed ends between two turns of one common-box gap, the list shrinks by one before the index, and the next
chat (one without the field) is never read for that gap; the gap is then closed (`GapDone`), so the messages of the
gap's window in that chat are not fetched again. This breaks "change nothing for a chat without the field".
Probe `TestProbeCommonShift`: 9 private chats and basic groups of account 1 with cursors, all on mirror records,
`CommonGapPerMinute` 1, a common-box gap; the field is written on list[0] after its gap read: list[1] (no field)
got 0 history requests, list[2..8] one each; the gap was closed. (The coder's report names the shift and calls it
"as a new cursor does today"; a new cursor shifts the list the other way, reading one chat twice; this piece adds
the direction that drops a chat.)
Smallest fix: keep the list unfiltered (`ch.ref.Kind != telegram.ChatChannel && ch.cursor` as before) and skip
inside the loop, after `st.gapNext[g.ID] = i` and before the per-minute check:
`if s.skipEnded(ch) { continue }`. The index then means the same chat whatever ends or resumes; the ended chat
sends nothing and costs no slot of the minute. A test: the probe above (end list[0] after its read, every other
chat gets one read).

### 2. SHOULD FIX, CONFIRMED: two of the four skip sites are untested
`internal/collector/readended_test.go`. With the probe switch removing one site at a time,
`TestReadEndedStopsUntilOwnersYes` FAILS without the history-loop skip (`reader.go:597`) and without the channel-gap
skip (`:730`), and still PASSES without the topic-list skip (`:514`) and without the common-box skip (`:679`): the
story has only supergroups (channels), none a forum. Add to the test (or a second one) a mirror-approved forum (a
topic list after the end must not be asked: count `ListTopics` at the fake across a chat-list turn) and a mirror's
basic group with a cursor and an open common-box gap (no `Newer` read of it after its end) — the second one together
with finding 1's check.

### 3. SHOULD FIX, PLAUSIBLE (outside this piece's files; for the board): the console's words for an ended chat are wrong
`internal/collector/approve_cmd.go:140`. `-approve-read` on an ended mirror record (By set, ApprovedAt set) says the
chat "is read for its mirror already ... its mirror goes on". Its yes does resume the read correctly (approveRead with
the mirror's estimate), but the words say the opposite of the state. The Chats page shows it as approved as well
(the coder's report says so). Route to the pages track / core: say "its mirror ended; a yes reads on from its
cursor". Not this piece's file (the brief allows only `reader.go`).

### 4. MINOR, PLAUSIBLE: `TestReadEndedMirrorSettleStillReads`'s check of the source is vacuous
`internal/collector/readended_test.go`, the last test. With the default `PagesPerTurn` (10) and a 150-message source,
the source is read to its end in its first call, before the first forward; the field is written after that forward,
so "the source: 0 history requests after its end" would hold without this piece. The test's real value (the settle
still reads the mirror chat) is sound. Either drop the source assertion or make the source longer than one call
(`PagesPerTurn` 1 and several pages) so that it means something.

### 5. MINOR: the count grows with the reader's turns, not with chats
`reader.go:299`. One count per call of `skipEnded` that returns true: per turn, one per ended chat the history loop
reaches (only when no better-ranked chat is read first) plus one per open channel gap of an ended chat (the gap loop
runs every turn and those gaps never close; bounded-range gaps of one chat are separate rows and accumulate). In an
idle hour with the default `ReaderIdle` of 1 minute: about 60 per ended chat plus 60 per open gap of it; with the
automatic mirror on, `autoIdle` can shorten the idle to its next turn (never under 1 s), so up to a few thousand an
hour per ended chat in the worst case. Bounded and cheap (no request, one map add), and "per skip" is what the brief
asked; but it reads as "turns", not "chats". If wanted: count once per chat per hour.

### 6. MINOR: the line is once per session, not once per run
`reader.go:302` (`endedSaid` lives in the session's `readerState`). A reconnect says each ended chat again. The brief
says "first seen ended in a run". Bounded by reconnects; the coder's report says so. Acceptable; a field on the
account (`account.go`) would make it once per run.

### 7. MINOR: an ended chat's share of a common-box gap is lost for good after the owner's yes
`reader.go:679`. The common-box gap is closed without the ended chat (before and after finding 1's fix), so after the
owner's yes the history read goes on from the cursor (older messages) but the gap's window of newer messages is not
read for that chat. A channel's gap, in contrast, stays open and is read after the yes (test 1 shows it). The brief is
silent; either accept it (say so in the report) or leave the common gap open while any ended chat with a cursor is in
it (that would hold the gap for every chat, so accepting it is likely the better choice).

## Checked and sound

- No history request for an ended mirror chat from the reader: the history loop (`:597`, after the `done`/approval
  check, before `refused`/`backoff`), the channel gap (`:730`, the gap stays open, `false, nil` returned, the gap loop
  goes on to the next gap), the common-box list, the topic list. A watchdog-fired pass returns and the next turn
  re-reads the records (`readChats` each turn), so a resumed pass is skipped too. Probe: test 1 fails when either of
  the two tested sites is removed (A read to 5 pages).
- `onReader` has one caller, `EstimateRead` (the owner's estimate, one request): unchanged and the owner's. The
  mirror command's own reads (`internal/mirror/read.go`) are the owner's command; its `ApproveRead`
  (`mirror_cmd.go:906`) writes a fresh record and so drops the field: that is an owner's action, acceptable.
- A chat without the field: `readChats` gives `approved` exactly as before (`ok && ApprovedAt != 0`), `ended` and
  `ownerEnded` false; `skipEnded` returns false and only deletes a map key; `EstimateRead`'s condition is the old one
  OR `MirrorEndedAt != 0`, identical without the field; `approveRead` sets a field that was 0 to 0. The only
  difference found is finding 1, which is a chat without the field hit by another chat's end.
- An owner's record with the field: never skipped (`ended` needs `By` not empty); said once (`readEndedOwnerLine`);
  test 1's C is read to its end with 3 requests.
- The writers: an estimate on an ended mirror record keeps `ApprovedAt`, `By`, `MirrorEndedAt`; on a mirror record
  with the field and `ApprovedAt` 0 it keeps `By` and the field (without the extension the estimate would have made
  it an owner's record with a cursor, which would resume the read without a yes: the extension is right). The owner's
  yes clears `By` and the field. Neither writer can put the field on an owner's record (the estimate starts a fresh
  record unless `By` is set; the yes zeroes it). `autoApprove` leaves any record alone, so the field cannot be dropped
  by the automatic mirror (see "brief silent" for the other side of that).
- An unparsable record: `approval` returns ok false; `approved`, `ended`, `ownerEnded` false; read only with a cursor,
  as before. Unchanged.
- The settle's `readMirror` reads the mirror chat's own record (`approvedRecord`, `ApprovedAt > 0`) and does its own
  `ReadChat`; the source's field cannot reach it. `autoTurn` sends no other history request.
- Two accounts: the record is per account and chat (`keyRead`), the cursor per account; one account's end does not
  touch the other's read. A migrated chat is a new catalogue chat with no record: unchanged.
- No spin: an ended chat or its gap gives `did` false, so the reader idles as before; an open ended gap does not hold
  up other gaps (`OpenGaps` has no limit; the loop continues).
- The lines: constant formats, the account's number and the catalogue's chat number only, as the reader's other lines.
  The count's name is constant; it is written to the collector's own tally, saved with the hourly rows like the VPN
  check's.
- Concurrency: `skipEnded` and its maps are used from the reader's goroutine only (`readTurn`, `readGap`, the topic
  list); no new goroutine.

## Where the brief is wrong or silent

- Silent on the common box's resume index (finding 1) and on the common gap's window being lost for an ended chat
  after the yes (finding 7).
- Silent on the topic list; the coder skipped it, rightly (a request for a chat that will not be read), but did not
  test it (finding 2).
- "Once in a run": the reader's state is per session; the brief's file limits (no `account.go`) make "per run" hard.
- The test the brief asks for on the settle cannot show anything about the source unless the source is read over
  several calls (finding 4).
- For the mirror track's writer (not this piece): `autoApprove` leaves any record on file, so a later new want for a
  chat whose record carries the field is never read unless that writer clears the field when it makes the new want.
  The coder's report says so; it should be on the board for the mirror track.
