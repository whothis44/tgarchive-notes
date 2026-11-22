# Brief E8b: the review's fixes in the footage packages (copies track, 2026-11-15)

Same copy and branch as E8 (`wt-copies-footage`, `wip/copies-8`, head 9b0e3b1), same rules, same commit and
push form. The independent review is `C:\Users\trabi\Claude\Projects\Telegram\wt-copies-review10-scratch\REVIEW.md`
(read sections A and "the existing ffmpeg part" in full; its probes and mutations are in that folder: take each
as a named test of the package, renamed, never by overlay). Section B is another branch: not yours.

The ffmpeg part reads files that come from Telegram: **the input is hostile**. The review proved several ways
a crafted file misleads it. Nothing calls this package for real yet; all of this is fixed before anything does.

## The existing ffmpeg part (as merged; fix on this branch)
1. **F1, F4: ffmpeg must read only what it is given, as a real container.** The range server always answers
   `application/octet-stream`, whatever the Source's mime says. Both commands (`Sample`'s and `Fingerprint`'s)
   get a `-format_whitelist` of real media containers only (no playlist, concat, image-sequence or text
   formats: list them in one place, with a comment saying why each family is in). Tests: the review's probes
   (a file that names a URL on a second local listener gets no connection on ffmpeg 9.0.2 and 7.1.1; an
   `ffconcat` text file is refused and no other file is read). Say in the report which containers are allowed
   and what share of the old archive's kinds that covers by the documents' own numbers (MP4 and MOV are
   99.6%).
2. **F2, F3: a title in the file is never read as a time or a length.** Parse a frame's moment only from
   showinfo's own lines and the length only from ffmpeg's own input line; a file whose metadata holds
   `pts_time:` or `Duration:` text changes nothing (the review's two probes).
3. **F5: a bound on frames.** Two frames far apart must not make `fps=2` fill hours of duplicates: a cap that
   bounds a fingerprint's frames, time and bytes read from the pipe whatever the file claims (say the bound
   and why it never cuts a real video the old app would have fingerprinted: its limit was 60 minutes of ffmpeg
   and 3,600 kept frames). The review's 21,865-byte file must end in under 2 s.
4. **F6: ffmpeg that cannot be started is its own error**, told apart from "cannot read the video", in
   `Fingerprint` as `Sample` already does, so a caller never records a file as unreadable because the tool is
   broken.
5. **F7: frames and their times are paired safely.** When the counts of frames and parsed times differ, the
   result is an error of the read (a fixed category), never times shifted onto the wrong frames, and never
   "no frames" for a video that had frames.

## Brief E8's own code
6. **A1: four of `Check`'s new lines can be reverted with every test passing.** Add the review's four tests
   (a 24000/1001 clip through `Check`; a key round of 2 to 6 points read to its end; a black key frame; a
   resume where the index becomes readable between two calls) so that each of the four mutations in the
   review's `mut/` folder fails a named test.
7. **A2: a 465-byte index must not cost 221 MiB.** Allocate once, from a count checked against what the
   file's own bytes can describe, and lower the cap on key frames to what a check can use (131,072; more is
   `ErrBadIndex`, and the check takes the midpoints). State the worst memory of one `Read` in the doc comment
   and test it (allocation measured, not timed).
8. **A3: `KeyRound` and the second round never use a moment outside the video.** Key frames before 0 or after
   the length, and moments that are not finite, are dropped before choosing; none left: the midpoints.
9. **A4: `NeedError` cannot be asked for without end.** A part that is present with the wrong length is
   `ErrBadIndex`, not named again; the cap on top-level boxes comes down to what a real file has (state it);
   the doc comment says a caller must stop at a part named twice and after a stated number of calls.
10. **A5** needs no code: write both points into the report's "not verified".

Rules as E8's: touch only `archiver/internal/footage`, `footage/mp4index`, `footage/ffmpeg` and
`archiver/docs/progress/`; round 0 and `ModeOff` stay bit for bit; thresholds stay; invented media only; no
path, name, token or ffmpeg text in any error or log. Named tests while working, then the three footage
packages whole once at the end (they are small: about 2.5 minutes) on ffmpeg 9.0.2, and the ffmpeg-backed new
tests on 7.1.1 by name; one go command at a time (the PC is near its limit); no race detector, no Docker. Each
fix shown failing its test when undone. Append a section "Review fixes" to
`archiver/docs/progress/copies-index-REPORT.md` (each item: what changed, its test, its mutation; the format
whitelist; the frame bound; anything done differently and why). Hand back commit-ready and pushed.
