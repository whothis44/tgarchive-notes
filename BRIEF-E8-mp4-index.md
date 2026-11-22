# Brief E8: an MP4 index reader, and the second round on key frames the first did not read (copies track, 2026-11-15)

For one Opus coder, in the copy `C:\Users\trabi\Claude\Projects\Telegram\wt-copies-footage` on branch
`wip/copies-8` (create it there from the main branch's 6f17c7f with `git switch -c wip/copies-8 6f17c7f`; the
only branch change allowed). Go module in `archiver/`. Commit work in progress as you go (`git -c user.name=Claude
-c user.email=noreply@anthropic.com commit`, messages starting `WIP copies: `, ending with a blank line and
`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, no number of any real archive) and push with
`git push private wip/copies-8`; never `origin`, never the main branch, never a force-push.

## What the old app already knows (its numbers; read before the code)
- Its frame check read 8 points between 5% and 95% of the length, ffmpeg taking the key frame before each
  (`-noaccurate_seek`), and never looked twice. ffmpeg found the file's index by itself through the range
  server; an index at the file's end cost the tail parts. The old app has no index reader of its own.
- Its "copy" was right in 184 of 188 judged after download. Its "no match" against a named file was wrong
  about 3 times in 4 (882 of 1,140). The fork's own conclusion: "a fuller frame sample before calling a pair
  distinct".
- A check cost 8 parts at the median, 32 at most (its cap); "parts cap" was its most frequent final failure
  (22 of 66 failed checks). 99.6% of its saved videos are MP4 or MOV: an MP4-only reader covers nearly all.
- The new app's own measurement (brief E6's report, `archiver/docs/progress/copies-cusp-REPORT.md`, read it):
  the second round's midpoints bring 8, 6, 0 and 0 new frames of 8 with a key frame every 0.2, 1, 2 and 5 s
  on a 14 s clip, because ffmpeg takes the key frame before each point. So on sparse key frames the second
  round costs processes and brings nothing. Its proposal P2 is this brief.
- COPY-CHECKS-STUDY E.7 (b) (`archiver/docs`): "a small Go MP4 index reader (top-level boxes, then moov's
  stts/stss/stsc/stsz/stco) plans the key-frame byte ranges ... the part count is known before most parts are
  asked for". The reader built here is also what the later probe plans its parts with.

## What to build

### 1. A pure package `internal/footage/mp4index` (no ffmpeg, no goroutine, no file or network access)
- Input: a file of which only some 1 MiB parts are local. Define a small `Source` interface there whose
  methods are a subset of `ffmpeg.Source` (`Size() int64`, `Part(index int64) ([]byte, bool)`), so the ffmpeg
  package's sources can be passed as they are; the part size is the ffmpeg package's (do not import that
  package: a constant of the same value with a test in the ffmpeg package that the two are equal).
- `Read(src) (Index, error)`: walks the top-level boxes (32-bit and 64-bit sizes, a size of 0 meaning "to the
  end"), finds `moov` at the front or the end, reads the first video track's `mdhd`, `stts`, `ctts`, `stss`,
  `stsc`, `stsz`/`stz2`, `stco`/`co64` and `elst`, and returns:
  - the track's length in seconds; where `moov` lies (offset, size, whether it is after the media data);
  - every key frame in time order: its moment in seconds **as ffmpeg reports it** (`pts_time` under `-copyts`:
    the test below is the definition), its byte offset and size in the file, its sample number. No `stss` box
    means every sample is a key frame.
- Errors, each a typed value with fixed words (no path, no name, no byte of the file in any error):
  `*NeedError` (the parts it must have to go on, sorted, each once: the caller fetches and calls again; a
  file with `moov` at the end takes part 0, then the part with the box header after the media data, then
  `moov`'s parts), `ErrNotMP4`, `ErrFragmented` (`moof`/`mvex`: no sample table to read), `ErrNoVideo`,
  `ErrBadIndex`.
- The input is untrusted: no panic on any bytes, no allocation sized by a count from the file beyond a stated
  cap, every offset and size checked against the file's size, a bound on boxes walked. `FuzzRead` with a seed
  corpus of the invented files, run for 30 s by you (say the count of executions in the report).
- `Index.PartsFor(moments []float64) []int64`: the parts a read of the key frame at or before each moment is
  expected to ask for (part 0, `moov`'s parts, the parts of each key frame's bytes and whatever follows that
  ffmpeg turns out to read). This is a prediction for the later probe; nothing acts on it here. Find the rule
  by measuring against what ffmpeg really asked for (the range server's `Used`) on the invented clips, and
  report predicted against used per clip: missed parts and surplus parts. Do not tune it beyond what the
  clips show; say plainly that real videos are not measured.

### 2. Pure, in `internal/footage` (additions only; no existing function's behaviour changes)
- `KeyRound(durationSeconds float64, keys []float64, read []float64) []float64`: the second round's moments
  when the key frames are known: at most 8 key frames that round 0 did not read (`read` are the moments of
  every frame round 0 read; a key frame within a small stated tolerance of one of them is read), chosen to
  spread over the length: for each of round 1's present midpoints (`SampleTimesRound(d, 1)`, in its visiting
  order) the nearest unread key frame not yet chosen (ties: the earlier). Fewer than 8 when fewer are unread;
  none when none is. Deterministic. The moments returned are the key frames' own.

### 3. In `internal/footage/ffmpeg` (`Check`'s second round; `Sample` and round 0 stay bit for bit)
- The reading loop keeps the moment of every frame round 0 read, whether or not the frame says something.
- When `Check` starts a second round and `mp4index.Read` succeeds on the parts already local (after round 0
  on an MP4 ffmpeg has read the index, so its parts are local: assert it in a test for an index at the front
  and at the end; **never ask for a part only for the index**), the round reads `KeyRound`'s moments instead of
  the midpoints. Each read must return the chosen key frame itself: the frame's reported moment equals the
  key frame's. How far after the key frame's moment `-ss` must point is for you to measure (I believe ffmpeg
  moves an input seek back by about 0.13 s when the stream has B-frames: verify, do not trust me), with
  enough decimals; round 0's arguments do not change.
- No unread key frame: no second round is read; the result says so with a fixed word (a new value beside
  `Why`, or a field: your choice, counted like the others). Index not readable for any reason (not MP4,
  fragmented, bad, a part missing): the midpoints, as today.
- `Result` says which way round 1's points were chosen (key frames, midpoints, none possible), for the
  caller's counts per hour.
- The early stop, `Together`, `Verdict`, the two-round cap and the three modes are unchanged. With `ModeOff`
  every result equals today's, call for call.

## Tests (invented data and invented clips only; named; ffmpeg tests skip without ffmpeg, as now)
- `TestReadFront`, `TestReadEnd` (`moov` before and after the media data; the end case through `NeedError`
  step by step, counting calls), `TestReadB` (B-frames and an edit list, as ffmpeg writes by default),
  `TestRead64` (a 64-bit box size and `co64`, hand-built), `TestReadErrors` (each typed error from a hand-built
  file: fragmented, no video, a size past the end, a count over the cap, a truncated box), `FuzzRead`.
- `TestKeyTimesMatchFFmpeg` (ffmpeg package): for invented clips with key frames every 0.2, 1, 2 and 5 s, with
  and without B-frames, MP4 and MOV, the index's key-frame moments equal the moments ffmpeg reports for its
  key frames (state the tolerance; it should be far under a frame).
- `TestKeyRound` (pure: unread only; spread; fewer than 8; none; the tolerance's edges; deterministic).
- `TestCheckKeyRound` (ffmpeg): the E6 report's table again: 14 s clips with a key frame every 0.2, 1, 2 and
  5 s; new frames in round 1 with key-frame points against the midpoints' 8, 6, 0, 0; every frame read is the
  chosen key frame; no part asked that round 0 had not made local except the chosen frames' own; a clip with
  one key frame takes no second round and says why; a non-MP4 (Matroska) clip takes the midpoints.
- `TestPartsForAgainstFFmpeg`: predicted against used, the numbers printed and written into the report.
- The existing tests pass; list every one whose expectation you had to change, with the reason.
- Mutations, each shown failing a named test, then undone: a read key frame returned by `KeyRound`; the same
  key frame chosen twice; `-ss` at the key frame's own moment with B-frames (the frame read is the one
  before); a part asked for the index alone; `ModeOff` reading a round; a count from the file trusted past
  the cap; the edit list ignored.

## Rules (hard)
- Touch only `archiver/internal/footage/mp4index` (new), `archiver/internal/footage` (additions),
  `archiver/internal/footage/ffmpeg`, and `archiver/docs/progress/`. Nothing else, no schema, no catalogue.
- Thresholds stay (Hamming 8, slack 2.5 s, 60% and at least 3, partial at 3). A frame check never gives
  "exact"; nothing here holds or releases a file: it returns outcomes and counts.
- The ffmpeg part keeps brief E5's rules: every process and goroutine ended before a call returns; no package
  state; invented media only; never a path the test did not create; no names or paths in errors or logs; new
  log or error text is constant words with numbers.
- Load: Git Bash, `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`, set `FFMPEG_PATH`
  as `archiver/docs/progress/copies-ffmpeg-REPORT.md` says (Go does not find ffmpeg on this PC's PATH),
  `GOMAXPROCS=2 go test -p 1 ./internal/footage/...` and named tests while working. Tiny clips; no test over
  20 s; no race detector, no Docker, no whole run of any other package. Other sessions' runs may be going:
  leave them alone. Never touch `E:\T\tg-dl` or any real media.
- Keep `archiver/docs/progress/copies-index-PROGRESS.md` current and commit it with each step; at the end
  `archiver/docs/progress/copies-index-REPORT.md`: what was built; the exact rule of `KeyRound` and of the
  seek offset with the measurement behind it; the table of new frames per key-frame spacing; predicted
  against used parts; every test with its mutation; what was NOT verified; anything in this brief you found
  wrong or contradictory (say so rather than build around it); the changed files; a drafted final commit
  message. Hand back commit-ready: everything committed and pushed, the tree clean, gofmt clean.
