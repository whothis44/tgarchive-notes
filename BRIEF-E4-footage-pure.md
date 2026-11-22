# Brief E4: the old app's video fingerprint and frame-match arithmetic as a pure package (session C, 2026-11-15)

For one Opus coder, in the copy `C:\Users\trabi\Claude\Projects\Telegram\wt-copies-footage` (branch
`wip/copies-footage`, cut from 8c0335e). Go module in `archiver/`. Work only in that copy. Commit work in
progress to the branch as you go (`git -c user.name=Claude -c user.email=noreply@anthropic.com commit`,
messages starting `WIP copies: `, ending with a blank line and `Co-Authored-By: Claude Opus 5.5
<noreply@anthropic.com>`, no number of any real archive) and push with `git push private wip/copies-footage`;
never `origin`, never the main branch, never a force-push.

## Why
The next copy layer is the sampled-frame check: a few frames of a queued video compared with the
fingerprints of saved videos. The old app's numbers: when it says "copy" it is right (184 of 188 judged after
download); it found copies the preview rule cannot see (about 3 in 10 of its finds were more than 6 preview
bits apart). Its "no match" is not to be trusted and never releases a file alone. The fingerprints of the old
archive's saved videos (made for nearly all of them) will be brought in and must be compared bit for bit with
frames the new app samples, so the arithmetic must equal the old app's exactly. This piece is only that
arithmetic: pure, no ffmpeg, no catalogue, no Telegram, as `internal/lookalike` was for the preview rule.

## Ported from (the owner: port the old app's code, do not write it anew)
Read-only reference, `C:\Users\trabi\Claude\Projects\Telegram\wt-v12.31\core-service\internal\app`:
- `ix_vdup.go` lines 45-454: the constants, `ixVFrame`, `ixPackFrames`, `ixUnpackFrames` (20 bytes a frame,
  little endian: the time as float32, the hash, the mirror's hash), `ixThin`, `ixTrimBorders`, `ixResample32`,
  `ixFrameHashes`, `ixGridStep`, `ixOnGrid`, `ixVInterval`, `ixVLength`, `ixVRun`, `ixVCompare`. `ixPHash` and
  its table are already ported as `lookalike.PHash`: use that, do not copy it again.
- `ix_copies_sample.go`: the constants at lines 67-88 (`ixSamplePoints` 8, `ixSampleMinHit` 3, `ixSampleShare`
  0.6, `ixSamplePartialHit` 3, `ixSampleSlack` 2.5, `ixSampleOrder`, `ixSampleMissAfter` 5), `ixSampledFrame`,
  `ixSampleMatch` (lines 538-572), `ixSampleDecided` (587-606), the sample times (line 723: 5% to 95% of the
  length), and the verdict at the end of `ixSampleCheck` (lines 794-810: the need of max(3, ceil(0.6 x frames
  read)), "confirmed" with the offset, else "no match" with the best count and the closest file); and
  `ixPackSampled` and its reader wherever they are defined (grep), the packing of sampled frames kept to compare
  again.
- Change nothing: not a threshold, not the order of floating-point operations, not a rounding, not the bit or
  byte order. Names become Go-exported and plain (`footage.Frame`, `Pack`, `Unpack`, `FrameHashes`, `Compare`,
  `SampleMatch`, `Decided`, `Verdict`...). One deliberate difference in wording only: the old app stored a
  sampled match as "confirmed"; the verdict [name removed] has `Probable`, `Partial` (no candidate reaches the need
  but the best has `ixSamplePartialHit` or more), `NoMatch`, and **no value that means exact** (rule R3 of
  `archiver/docs/COPY-CHECKS-STUDY.md` section E: a frame check can never produce "exact").

## What to build
New package `archiver/internal/footage`, standard library plus `internal/lookalike` only:
- frames and packing; borders, resampling, frame hashes; the grid; `Compare` (same, clip, overlap, none) with
  its match record; the sampled side: `Sampled`, `SampleTimes(durationSeconds)` in the old visiting order,
  `SampleMatch`, `Decided`, and `Verdict(samples, candidates)` returning the kind, the candidate's index, hits,
  frames read and the offset;
- doc comments that say what each does and that it is the old app's arithmetic, without any figure of a real
  archive.

## Tests (invented data only; named)
- Golden equality: a test-only copy of the old functions' arithmetic (in a `_test.go` file, as
  `internal/lookalike/oldcopy_test.go` does) run against the package on many invented inputs: grey frames
  with and without dark borders, flat frames, mirrored frames, packed blobs, fingerprints of invented
  "videos" (sequences of hashes with times), sampled frames at offsets. Every output equal, bit for bit.
- Behaviour, each threshold at its edge on both sides: Hamming 8 and 9 (5 and 6 for three samples or fewer);
  the 2.5 s slack; 3 hits and 60%; partial at 3; the stop after 5 frames with no hit; "cannot reach 3 any
  more"; same at 80% of both, clip at 90% of the shorter; the 5 s run or half of a short video; a mirrored
  copy found through the mirror hash; a trimmed copy (a new intro) found at one offset; an unrelated video of
  the same length not found; the gap a run may skip.
- `TestVerdictHasNoExact`: the verdict kinds are exactly the three named (a compile-time or reflection check).
- Mutations, each shown failing a named test, then undone: Hamming 9; slack 3.5; need 2; the mirror hash
  ignored; little endian turned big; the border cut limit changed; the grid step for long videos changed.
- A benchmark of `SampleMatch` for 8 samples against 300 candidates of 3,600 frames (state ns and
  allocations; no speed claim).

## Rules (hard)
- Touch nothing outside `archiver/internal/footage` and `archiver/docs/progress/`. `internal/lookalike` is not
  to change.
- Pure: no goroutine, no file or network access, no ffmpeg, no catalogue.
- Privacy: invented data only; never read under `E:\T\` or `%LOCALAPPDATA%\tgarchive\`; the old app's code is
  read-only reference, never built or run; no real frame, preview or fingerprint bytes from anywhere.
- Load: Git Bash, `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`, then
  `GOMAXPROCS=2 go test -p 1 ./internal/footage/` (this small package may be run whole). No race detector, no
  Docker. Other agents' tests may be running: leave them alone. If Go or its caches are missing, stop and say so.
- Keep `archiver/docs/progress/copies-footage-PROGRESS.md` current and commit it with each step; at the end
  `archiver/docs/progress/copies-footage-REPORT.md`: what was ported from which lines, the proof of equality,
  every test with its mutation, the benchmark, what was NOT verified, the changed files, a drafted final commit
  message.
