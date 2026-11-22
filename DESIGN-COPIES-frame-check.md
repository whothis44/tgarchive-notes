# The frame check as the first step of a file's turn, with kept parts: design (copies, session C2, 2026-11-15)

For the copies track's piece 3 (board step 2c) and what piece 4 (2d) stands on. Written after reading, myself and
in full: TRIED-BEFORE 6, 17, 20, 21, 27, 28; COPY-CHECKS-STUDY (all; section E is the adopted design this note
makes concrete); LESSONS; answers 4, 5, 8; the old app's `ix_part_store.go`, `ix_stage_process.go`,
`staging_process.go`; the new engine's `types.go` and the lane's part path (`pickFrom`, `deliver`, `fetch`'s
answer). Not yet read by me, and read before the brief that needs each: the old app's `ix_dl_check.go` and
`kept_parts.go` (again; the earlier session's notes on them are in the progress file, 11-15 08:35), the
supply's `Next` and `pending.go`, the lane's `open`, `do`, `finish` and stop paths.

## What the old app already knows (its numbers beside ours)
| | The old app | The new app today |
|---|---|---|
| A frame check's "copy" | right in 184 of 188 judged after download | not built |
| Its "no match" against a named file | wrong about 3 times in 4 (882 of 1,140) | so: never releases, never passes a file alone |
| Share of checked videos that are copies | 10 to 25% of videos nothing had held (copies average 360 MB) | unknown: counted from the first run |
| Parts a check | 8 at the median, cap 32 | `mp4index.PartsFor` predicted 201 of 201 on invented clips |
| Time a check | 10 to 22 s in unlimited hours; 3 to 14 minutes under the limit, about half timing out **because the check held a download slot while ffmpeg waited on Telegram** | by design ffmpeg never waits: it reads local parts only |
| Kept parts | at least 63 GB reused in 7,916 downloads, 0 refused; 2.06 GB fetched twice for 147 videos before they were kept | none |
| When the download follows | a median 23 to 55 h after a background check (so a 4 GB cap lost parts; 100 GB then) | right after the verdict, in the same file's turn: parts live minutes |
| Containers | 99.6% of saved videos MP4 or MOV | the index reader plans MP4 and MOV; others: ffmpeg says what it misses |

The trouble of 12.13 to 12.27 (every fix from 12.25 on) was a check waiting on Telegram while holding a
download's place; a timeout taken for "no copy" (7 big videos, 4.8 GB, "a critical error"); parts lost on a
timeout and on a drain. The rules R1 to R7 of the study are the answer and are kept as they stand.

## The shape (three turns of one file, one offset space)
1. **The Supply decides at `Next` whether a file is probed** (one index read, like the same-size lookup of the
   exact check): a video of 20 MB or more (the old in-download floor; a setting), with a length, not resumed
   from a checkpoint, when at least one saved video with a fingerprint lies within 20% of its length. **A file
   with no candidate is handed out exactly as today: nothing is added to its path but that one index read.**
2. **The probe turn.** The file is handed out with `File.Plan`: the indexes of the 1 MiB parts to fetch (from
   the MP4 index reader when parts 0 or the tail are already kept, else part 0 first; parts already kept are
   left out). The lane claims it and fetches exactly those parts **like any transfer's parts** (window, waits
   slept with the margin, timeouts and set-aside, reference refresh, the stop), each answered part going to
   the part store, not to a file writer. When the plan is in, the file leaves the lane: its claim ends, no
   attempt spent, its file slot free. **Real offsets everywhere: a probe is not a pretend file.**
3. **The judge** (one worker outside every lane, as the fingerprint worker; no Telegram access at all) runs
   `footage/ffmpeg.Check` over the kept parts and the candidates. Its answers: **copy** (held as a probable
   copy with the evidence "sampled frames k of n", an edge to the saved file; its kept parts dropped, its
   frames kept); **partly the same** (wanted, marked partly, parts kept); **no match** (wanted, parts kept);
   **more parts needed** (back to step 2 with those parts; at most 3 rounds and 32 parts in all, then
   "unknown"); **unknown** (ffmpeg missing, a limit hit, a part that could not be had): the file is not
   offered again for 15 minutes when the round brought new parts, an hour otherwise; after 24 hours of
   unknowns it is downloaded unchecked, **counted and with its reason on record** (R2's explicit bound). A
   held look-alike that is probed (piece 4) is confirmed by "copy" and **stays held on anything else**.
4. **The transfer.** The file's ordinary download, at its own rank. Before a part is asked of Telegram the
   lane looks in the part store (an in-memory "has this file any kept part" first: one map read for a file
   that has none); a kept part, verified by its stored length and SHA-256, is delivered without a request
   and counted apart (kept parts, kept bytes): it is no answer of Telegram's, so it feeds neither the speed
   measure, the window's rule nor the network's state.

## Why the engine is changed, and how little
Two ways were weighed for the probe turn. (a) No engine change: hand the lane a pretend file whose parts map
onto the planned parts through a wrapped transport and sink. Rejected: two offset spaces (pretend and real)
below a store whose bytes later go into downloads unverified by anything but our own hash; one confusion
between them writes wrong bytes into a saved file and nothing would notice. (b) **The probe is explicit in the
lane, in real offsets**: `File.Plan` non-empty makes the transfer a probe: its planned parts are put where the
lane keeps parts to ask again (`xfer.retry`), nothing sequential is asked (`next` at the end), `deliver` hands
each part to the store through the file's writer goroutine (a new writer op), and when all are kept the file
leaves by a new way out (`leaveProbed`, the Supply's `Probed`). No `Sink.Open`, no checkpoint. Everything
else is the lane's own code, unchanged. For the transfer: one lookup before a request is booked.
**With no part store configured and no plan, every path is bit for bit today's** (to be shown by the
reviewer the way E9's was: scripted lanes, equal digests on the head and on the base).

## The pieces, their files, their order
| Piece | Files | Needs | State |
|---|---|---|---|
| **E13 the part store** | a new package `internal/parts`: put (temp file, rename, then the row), read back verified, per-file "has any", remove, cap and free-space floor, sweep; its own ledger interface with an in-memory one; a `footage` source over kept parts | nothing | briefed: `BRIEF-E13-part-store.md` |
| **E14 the engine** | `internal/engine`: `File.Plan`, the probe transfer, `Config.Parts` (the lookup and the put), the counters, `ProbeSupply.Probed`; `memsupply.go` for its tests | E13's two small interfaces | brief after E13 is handed back and I have read `open`, `do`, `finish`, the stop |
| **E15 the catalogue and the supply** | schema step 19: `c_part`, `c_probe`, an index of saved videos by length for candidates (the review's B12); the catalogue's doors (the part ledger, plan and verdict records, candidates); `internal/supply`: the decision at `Next`, `Probed`, the "not before" of a file being judged | E12 merged (same files), E11 (candidates) | brief after E12 |
| **E16 the judge** | a new package `internal/probe`: the worker, the plan from `mp4index`, `ffmpeg.Check`, the verdict written | E11, E13, E15 | brief with E15 |
| **The collector's lines** | start the judge, give the engine its part store | G1 merged | written down with E16, built after G1 |

Independent review: one for E13 with E14 (byte path and engine: the race detector on `internal/engine` and
`internal/parts`), one for E15 with E16. Full runs once per merge entry, after the review's fixes.

## Decided here, with the reason
- **Where the parts live:** a folder of their own given to the store (never inside the staging folder, whose
  sweep removes files it does not know). Rows in the catalogue (the one writer; the sweep reads the file's
  state there). A part file with no row is never read.
- **Space:** cap 20 GB by default (a setting), nothing kept and the oldest dropped while the disk has less
  than the staging keep-free plus 10 GB (the old floor rule). 20 and not the old 100: there a checked video
  waited a day or two for its download; here it follows its verdict at once, and a copy's parts are dropped
  at the verdict. Counted: parts dropped for space, so the first run says if 20 is too small.
- **A failed write keeps nothing of that part** and the probe turn ends as a disk failure does for a
  transfer (given back, the lane's write pause), never as a verdict.
- **Trust:** as the old app, a kept part is trusted when its length and our SHA-256 match (0 refused in
  7,916 downloads). Telegram's own part hashes are not asked for it (requests; study F.9 stays open).
- **A probe's file slot:** the file's own class (a large file's probe takes one of the 2 large slots while
  its parts are fetched). Whether Telegram counts a few parts of a large file against its 2 is not known
  (study F.8): the careful choice until a number says otherwise.
- **No new `c_want` state:** a file being judged is "wanted, not offered before T" (the door E9 added for a
  file given back for later), with its phase in `c_probe`. So the lane's supply query and its triggers are
  not changed, and a judge that dies leaves no file stuck: it comes back at T and takes the unknown path.
- **Requests are counted:** each probe part is a part request like any other in the lane's counters, and
  again per hour as probe parts; kept bytes used are counted apart and are not requests (R5).

## Open, to settle in the briefs or with a number
- The floor of 20 MB and whether it should be higher under the speed limit (study F.4): start at 20, count.
- Partly-same files: wanted in place (the owner's rule for ranked chats, 12.13). The lane's tier 4 exists for
  an account with a deadline only; a live account keeps them in rank order.
- How many judges at once: one (ffmpeg at 2 threads), as the fingerprint worker; both share the CPU with
  the viewer's thumbnails. Measured on the first run.
