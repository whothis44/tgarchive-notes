# C22, lesser copies behind the best: what the old app already knows

Written by the copies session C6 on 11-16, before any brief, from its own reading (no agent's summary).
Every number is the old app's unless it says otherwise. Counts, sizes and code references only.

**Read in full for it:** `repo-archiver/archiver/docs/TRIED-BEFORE.md` sections 6, 17, 21 and 27;
`COPY-CHECKS-STUDY.md` whole (A to F); `LESSONS.md` whole; `ANSWERS-for-archiver-4.md`, `-5.md` and `-8.md`
whole; this track's own section 0 in `SESSION-COPIES-PROGRESS.md` (session C1's record). The old app's code
(`wt-v12.31/core-service/internal/app`): `ix_copies.go` (the facts, `ixCheapSame`, `ixBetterCopy`,
`ixCoversSaved`, `ixGroupCopies`, `ixSavedVideoFacts`, `ixSavedCopyOf`), `ix_held.go` (`ixHeldStep`,
`ixQueuedVideos`, `ixHeldTriage`, `ixHoldWork`, `ixHeldOutweighed`, `ixUnhold`, `ixHeldRecheck`,
`ixRecheckAgainstSaved`, `ixPromote`, `ixLetGo`, `ixReleaseSome`), `ix_copies_sample.go` (`ixSampleCandidates`,
`ixSampleJobs`, `ixSampleTurns`, `ixSampleDueOf`, `ixSampleRecord`). The new app on 78739d59:
`internal/catalog/ladder.go` (the attach's rungs from the new file on, `lookAlikeVideo`, `countWouldHold`,
`LookAlikeWouldHold`) and the head comment of `atsave.go`.

**Not read yet, and owed before the brief** (the new app's side of the same thing): `atsave.go` whole;
`exactcheck.go` (`HoldLookAlike`); `pairword.go` (how a held copy is judged again); `internal/lookalike`
whole; `internal/supply` and tier 5 in `lane.go` and `state.go`; where a wanted file becomes not collected
and back (`wantedAsMainIn`); Core's K17 report when it is posted (what a file given back from a transfer
becomes).

## 1. What the old app does (its code, 12.31)

- **Which files.** Queued videos of 256 KiB or more, not self-destructing, with a length, pixel size and a
  preview hash; every one of them, every round of 2 minutes, with no cap since 12.16 (`ixQueuedVideos`,
  `ixHoldCheckMin`). A video held as a copy of a SAVED file is left out; so is one a person paused.
- **Alike** (`ixCheapSame`): lengths within 500 ms, aspect within 2%, preview hashes at most 6 bits apart.
  Groups are joined by that rule over videos sorted by length, each compared with the next ones up to
  max(500 ms, 2% of its length) longer (`ixGroupCopies`).
- **The best of a group** (`ixBetterCopy`): most pixels, then the longer (by whole seconds), then most
  bytes, then the earliest post (a forward's original date), then the lower queue id.
- **The hold** (`ixHeldTriage` step 2, `ixHoldWork`): every member but the best is paused with the reason
  "looks like a copy of a queued file", how "queued", and the best's queue id as what it waits for. A member
  already held behind another best is pointed at the new best. A group whose best is itself held is left to
  the recheck. A file in transfer, paused by a person, or let go before is never held.
- **When the best is saved** (`ixHeldRecheck`, `ixRecheckAgainstSaved`): once the best is in the library
  (not while it is only staged), each file that waited for it is compared with the SAVED file: still alike
  and covered (no fewer pixels, at least 90% of the bytes) means it stays held, now as a copy of a saved
  file; otherwise it is let go for good.
- **When the best will not come** (`ixPromote`): gone, skipped, failed for good, or paused by a person: the
  best of those that waited for it goes now and the others wait for it instead.
- **At the end of the queue** (`ixReleaseSome`): when held copies are let go a few at a time, a file whose
  best is still waiting or in transfer stays held.
- **Cost:** no request. The round read every queued video each 2 minutes.

## 2. Its numbers

- Held as lesser copies of a queued file on 11-13: **1,544 files, 150.1 GB** (answers 4, B.6); held against
  a saved file at the same moment: 39,798 files, 1,989.9 GB.
- The preview rule in general: right 95% at 6 bits or fewer on saved twins judged by fingerprints; about 5%
  of holds by it wrong among small files (PLAN-small-dedup, through TRIED-BEFORE 21 and the study).
- Byte-identical waste was small, the waste is re-encoded copies (93 files, 0.4 GB in a day).
- Holds against a queued file that a frame check judged, all over 200 MiB: **130 "confirmed", 400
  "released"** (answers 5). Of the 400 released, compared with the file they waited behind: 355 had its
  exact byte size, 347 its byte size, pixels and length within 500 ms; 93% of those with both previews were
  0 bits apart. 2 of them were later skipped by the exact check (how many of the 400 were downloaded and
  could be judged at all: not recorded in the answers).

## 3. The figure "right in 130 of 530" does not measure this rule (my reading of the code; not proven by a count)

The record (TRIED-BEFORE 27, this track's section 0, the comment at `ladder.go`'s `countWouldHold` call)
says the old app's holds against a queued file "were mostly wrong", and the new app therefore counts such a
pair as "would hold" and holds nothing. The figure behind it is the 130 against 400 above. By the old app's
code that comparison could not judge the pair:

- A frame check compares the checked video's frames with SAVED videos' fingerprints only: the file named
  by the hold's `like_key` first, then up to 300 saved fingerprints within 20% of its length
  (`ixSampleCandidates`).
- A hold against a queued file has an empty `like_key` (`ixHoldWork` is called with empty path and key for
  how "queued"), and the file it waits behind is not saved, so it has no fingerprint. The check therefore
  compares the held video with saved videos that are not its twin.
- Held videos are taken for a check whatever their kind of hold (`ixSampleDueOf`, `ixSampleJobs`), and a
  "no match" lets the file go for good whatever its kind (`ixSampleRecord`: held and "nomatch" calls
  `ixLetGo`; a file let go is never held again, `ixHoldWork`'s `released_at>0` guard).

So "released: 400" means "its frames matched no SAVED video", which is what a right hold behind a
not-yet-saved twin looks like; "confirmed: 130" means a saved video with the same footage existed as well.
The stored facts point the other way: 347 of the 400 had the twin's exact byte size, pixels and length.
And answers 8 found the frame check's "no match" unreliable even against a named saved file (of 79
released look-alike holds judged after download, 35 were the same bytes or content).

**What this is and is not.** It is a reading of three functions and of two answer files. It is not a
count: nobody has counted how many of the 400 ended as copies of their twin. By the project's rule the
documents win until a number says otherwise, so the piece is built to be right either way (section 5) and
the number is asked for (section 6).

## 4. What the new app has today (78739d59)

- Rung 6 at cataloguing: a new video is held against a SAVED video by the old app's rule
  (`lookAlikeVideo`: `lookalike.CheapSame` and `Covers`, a saved file of exactly its byte size first; such
  a file is marked "check first" and goes to the exact check before it is held).
- At a save: the wanted videos the saved one covers are held or marked, in the save's own transaction
  (`atsave.go`). Known gap in its own comment: a look-alike in transfer or set aside at that save is not
  judged again.
- A look-alike of a file that is only queued (wanted, in transfer or set aside): **counted**
  (`lookalike.would_hold`, and the bytes of the lesser of the pair), nothing held, no edge
  (`countWouldHold`). `internal/lookalike` already has the old app's `Better` and `Group`.
- So of two twins that are both wanted, whichever is claimed first downloads. If the better one is saved
  first, the other is held at that save, as the old app's recheck would leave it. What is lost today:
  (a) the two in transfer at the same time (both downloaded; the same bytes are found only by the SHA-256
  afterwards); (b) the lesser claimed first (a saved lesser copy does not cover the better one, so both are
  downloaded and the lesser's bytes were spent for nothing).
- The count on the test account's catalogue after its real runs: not read by me yet (one read-only number,
  section 6).

## 5. The shape the piece takes (the old app's way by default; the brief decides the details after the code is read)

- **Same rule, same order of "best", same floor**: `lookalike.CheapSame` between the two not-saved videos,
  `lookalike.Better`, from `lookalike.Floor`. No new threshold.
- **Where it runs: where the count runs today** (the attach, for a new wanted video with a queued twin),
  not as a pass every round: a pass over the queue every round starved the servers (TRIED-BEFORE 22), and
  `atsave.go` already chose "one index read at the event" for that reason. The events: a new video is
  catalogued (hold the lesser of the pair behind the better one; a file in transfer is never held); the
  best is saved (those behind it are judged against the saved file as rung 6 judges: held against it, or
  marked "check first" where the byte size is equal, or wanted again); the best will not come (gone,
  skipped, no longer collected, held by the owner's hand: the best of the rest is wanted, the others wait
  behind it).
- **Held, never skipped; with evidence**: a probable edge to the better file with fixed words and numbers,
  as rung 6 writes. Nothing here may set a file to skipped or gone.
- **Not supplied while its best is waiting or in transfer** (the old app's `ixReleaseSome` rule): a lesser
  copy does not go to the back of the lane as other probable copies may when "held copies wait" is off.
- **A stored switch, as the whole-album rule gets ("off, counting")**: with the switch off the piece does
  what the head does (the count); with it on, it holds. Its default follows the record until a number
  says otherwise: **off**. My recommendation, once section 6's number is in: on.
- **Counts of its own**: held behind a queued file; judged at the best's save (kept held, marked for the
  exact check, wanted again); promoted. So the first real run says how often each happens.
- **Bound by every rule of the track**: only exact evidence skips; a frame check's "no match" never
  releases a file by itself; nothing in the background reads the library; `lane.go` and `state.go` are not
  changed without a number on record (the piece should need neither: a held file is out of the supply by
  the tables' own triggers; to be confirmed by reading them).

## 6. Numbers asked for

1. **From the old archive (a fork session, read-only, counts only): `QUESTIONS-for-fork-10.md`.** Of the
   holds against a queued file: how many were let go by a frame check while the file they waited behind was
   not yet saved; of those let go, how many were downloaded, and how many of the downloaded ended as the
   same bytes or the same content as the file they had waited behind.
2. **From the test account's catalogue (read-only, the collector stopped or the file opened immutable):**
   `lookalike.would_hold` and `lookalike.would_hold_bytes` after its real runs: how many pairs, how many
   bytes of lesser copies.
