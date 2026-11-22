# Review: `wip/b-open` (head 6eb54d8) against `f0e3f0c`: the viewer's library opens (session B4, 11-15)

An independent, read-only review. Nothing in `wt-b-viewer` or anywhere else in the project was edited, checked
out or committed. The probes are in a scratch folder outside the project
(`C:\Users\trabi\AppData\Local\Temp\claude\71f159c3a9e5d4b9\08e0726b-fa56-4719-8490-c6d0ae9663c1\scratchpad\b4review\zz_probe_b4_test.go`,
loaded with `go test -overlay`, run by name, `-p 1`, `GOMAXPROCS=2 GOGC=50`, one at a time, memory checked first:
3.7 to 5.8 GB free). All clips and hostile files were made in that folder by ffmpeg's test sources or written as
text. Both ffmpeg builds on this PC were used: **7.1.1** (`WhisperJAV\Library\bin`) and **9.0.2** (Gyan
full build, WinGet). No viewer was started on real data, nothing was read from the owner's folders, nothing ran
against Telegram.

Counts: **4 CONFIRMED** (2 wrong result for the owner, 2 wrong number), **4 PLAUSIBLE** (1 wrong number,
3 cosmetic).

---

## Findings, most severe first

### F1. A stale root after a network blip marks a file failed for a day and answers a person's click with 404. CONFIRMED, wrong result for the owner
- **Where:** `media.go` 421-470 (`library.open`: every failure becomes `errNotFound`; the kept root is used
  without a check), with `maker.go` 598-601 (`make`: `case !m.v.lib.check()` then `case errors.Is(err, errNotFound): m.outcome(key, true)`).
- **The behaviour change:** before, `handle()` did a `Stat(".")` of the root on every open and, when it failed,
  opened the folder again inline (gap permitting), so a dead root handle was replaced *before* the open and the
  open succeeded. Now an open takes the kept root as it is. After a Wi-Fi blip (TRIED-BEFORE 15, 16: this PC's
  network drops now and then; an SMB directory handle does not survive the session's reconnect), the folder is
  back but the kept handle is dead. Every open between the blip and the next check fails.
- **Interleaving (probe `TestProbeStaleRootMarksFileFailed`, on the shared invented archive):** the kept root is
  replaced by a stand-in whose `Open` and `Stat` fail with a non-"not exist" error; the folder itself is fine;
  the injected clock is an hour past the start's try. Then:
  1. `maker.make(photo A)`: the open fails (`errNotFound`); `check()` finds the root dead, retires it, opens the
     folder again and returns **true**, so `make` takes the "file not found" branch: A goes pending.
  2. `maker.make(photo B)`: found, so every pending file is marked failed. **A's grid thumbnail carries the
     `read` failure mark** (no thumbnail for a day), though A was never missing.
  3. A person's `GET /media/{id}/file` with a stale root: **404**, while the library is there.
- The window is short when the open's error is not "does not exist" (`askCheck` wakes the watcher), but it is up
  to `libraryEvery` (15 s) when Windows answers `ERROR_BAD_NETPATH`, which Go's `syscall.Errno.Is` counts as
  `fs.ErrNotExist` (then no early check is asked). Three makers at about 2.5 opens a second can mark several
  files per blip. With more than `missingStreak` such failures in a row the library would also be marked "files
  missing" (by reading; not probed).
- **Smallest fix I would accept:** a root generation (a counter bumped each time `check`/`reopen` swaps or
  retires the root); `open` returns the generation it used (or the maker reads it before the open), and `make`
  takes the "library went away, not the file's fault" branch when the generation changed between its open and
  its `check()`. For a person, either accept the 404 (the page says "cannot be reached"; a second click works)
  or, on a non-"not exist" failure, wait for the early check to finish (bounded by the request's context) and
  try once more through the new root.
- **No test would have caught it:** the named tests drive `library` alone; none runs `maker.make` with a
  stand-in root.

### F2. The format whitelist drops RealMedia, DV, MXF, NUT, raw H.264 and GIF: no thumbnail and no converted copy for those. CONFIRMED, wrong result for the owner
- **Where:** `ffmpeg.go` 254, `mediaContainers = "mov,matroska,avi,asf,flv,mpeg,mpegts,ogg"`, used by
  `videoFrame` and `playArgs`.
- **Probe (`TestProbeFormatsOffTheWhitelist`, both builds, the viewer's own `videoFrame` and
  `startConversion`):** clips made with ffmpeg's test sources. MP4, MOV, MKV, WebM, AVI, WMV, FLV, MPEG-TS,
  MPEG-PS (.mpg, .vob), 3GP and OGV all give a frame and a converted copy on both builds (also checked with the
  exact command lines by hand). **RealMedia (.rm), DV, MXF, NUT, a raw H.264 stream and a GIF give no frame and
  a converted copy of 0 bytes** ("Format not on whitelist"). Before this branch all of them worked.
- Consequences: the frame's word is `noframe` (the error line matches none of `stderrWord`'s phrases), so the
  mark is one of those `dropStaleVideoMarks` drops at every start when ffmpeg is found: each such video is tried
  again, and fails again, at every start (a small read from the NAS each time). The play route answers 422
  "ffmpeg could not convert this video". RealMedia (.rm/.rmvb) is the case most likely in an archive of chats;
  the others are rare.
- **Smallest fix:** add the single-file demuxers that read no other file: `rm,dv,mxf,nut,h264,hevc,m4v,gif,ivf`
  (none of them opens another file or URL; the concat, HLS, image-sequence and ffmetadata demuxers stay out).
  Optionally map "not on whitelist" to `decode` so it is not retried at every start.
- **What holds:** a concat file under a video's name is refused on both builds ("Format not on whitelist" for
  `concat`); an HLS playlist under a video's name is refused before the whitelist ("Not detecting m3u8/hls with
  non standard extension"); every option passed (`-format_whitelist`, `-protocol_whitelist`, `-progress pipe:2`,
  `-nostats`, `-fps_mode vfr`) is accepted by both builds.

### F3. The converted copy's "speed" and "slower than play" measure the reader, not ffmpeg. CONFIRMED, wrong number
- **Where:** `ffmpeg.go` 426-447 (`convProgress.line`: wall = time of the last progress line since the start),
  `stats.go` 322-341 (`conversion`: speed = video / wall; `convSlower` when below 1).
- **Mechanism:** the copy is piped to the browser. When the browser stops reading (its read-ahead is full, the
  person paused, for up to `pl.stall`), ffmpeg blocks on the pipe and writes no progress line; the next line,
  after reading resumes, carries the whole pause in its wall time.
- **Probe (`TestProbeSpeedCountsReaderPause`, both builds):** a real conversion of an invented 60 s 720p clip;
  read 64 KB, move the injected clock 100 s (the reader pauses), read the rest. Result: 59.92 s of video, wall
  100 s, **speed 0.599, counted in `slower_than_play`**, though ffmpeg converted the whole clip in about two
  real seconds. The time to the first video was also 100 s: `first` is stamped at the first progress line
  (every 0.5 s by default), so it is also late by up to the progress period even without a pause.
- Also by reading: a conversion stopped after a second by a seek (the bar asks again from a new point) records
  ffmpeg's start-up as most of its wall time, and lands under 1 the same way.
- **Smallest fix:** time only what ffmpeg does while it is not held by the reader: the route already wraps the
  writer (`newProgressWriter`); sum the time spent blocked in `pw.Write` and subtract it from the wall, or take
  the speed only from the progress lines before the first blocked write (and only count copies with at least
  a few seconds of video). Say "seconds to the first progress line with video" for `first_video_*`, or stamp it
  from the route's first byte instead.

### F4. `makers_gave_way` and `walk_gave_way_to_play` count worker-waits and sum worker time. CONFIRMED, wrong number (low)
- **Where:** `media.go` 325-352 (`yield`, one count per maker open that waited), `maker.go` 509-517
  (`giveWayToPlay`, one count per worker per wake).
- **Probe (`TestProbeGaveWayCountsPerWorker`):** one person's open of 2 s (injected clock) with three makers
  waiting: `makers_gave_way = 3`, `makers_gave_way_ms = 6000`. For the walk: each page ask while a copy plays
  wakes a waiting worker, which finds nothing for the walk and waits again: one more count per ask.
- The snapshot says "how often, and for how long in all"; a reader takes "3 times, 6 s" for three separate
  waits. **Fix:** say "maker waits, summed over workers" in the comment and key, or count once per busy period of
  the gate (the gate records when a waiter first arrived and adds once when it goes idle).

### F5. Two (then three) "Open in the player" buttons under a converted copy on this PC. PLAUSIBLE, cosmetic
- **Where:** `web/js/play.js` 148 (the play-actions row keeps its `openButton(f)` visible after the switch:
  only `btn.hidden = true`), 151-155 (the new hint adds a second `openButton(f)`); after 10 s of "Opening…"
  `openingLine` adds a third; a failure message adds a fourth. By reading only (no DOM run).
- **Fix:** hide the play-actions row (or its open button) when the copy takes over, or leave the hint without
  its own button.

### F6. Every failing open (not "does not exist") makes the watcher Stat the share at once, with no gap. PLAUSIBLE, cosmetic (cost)
- **Where:** `media.go` 459, 468 (`askCheck`), `viewer.go` 369 (`case <-v.lib.early:` then `check()`).
- A run of files that fail to open for their own reason (a file the collector holds open, access denied) makes
  one root `Stat` over the network per failure, back to back (bounded by the opens' own rate: about 2.5 a
  second from the makers). Not a hang; a cost on the Wi-Fi link the brief is about.
- **Fix:** in the watcher, take an early signal only if the last check is older than a few seconds.

### F7. `first_video_*` is quantized by ffmpeg's progress period. PLAUSIBLE, wrong number (small)
- Covered under F3: with the default `-stats_period` 0.5 s the first video is stamped up to 0.5 s late; a
  conversion's first bytes reach the browser before that. Fix with F3, or pass `-stats_period 0.1`.

### F8. `openRec.longest()` says `open` for an open that never reached its open step. PLAUSIBLE, cosmetic
- **Where:** `media.go` `longest`: with `root == open == st == 0` (a failed root step timed at 0 on a coarse
  clock) the answer is `open`. Only visible if such an open is the slowest, which needs a total of 0. Negligible.

### Outside this branch (seen while reading, not counted)
- `web/js/item.js` 464-467 (unchanged here): when a photo has no thumbnail yet and the person clicks
  "Original", the late `whenThumb` callback sets `img.src` back to the thumbnail, replacing the original. With
  this branch it also removes the "Opening…" line early (its `load` listener fires on the thumbnail).

---

## Checked and found sound

**The root and its lock (part 2).** `mu` guards the pointer and counts only; no file system call under it
(`acquire`, `release`, `retire` close the root after unlocking). `check` and `reopen` are one at a time
(`checkMu`); `tried` is touched only under it. No open uses a closed root: a root is closed only when
`retired && users == 0`, once (`closed` flag), by `retire` or the last `release`. No leak on a flap: `check`
retires the old root before `reopen` puts a new one, and `reopen` closes what it opened when `close` came
first (`shut` re-read under `mu`). `close` with opens in flight: the root stays open until the last one
releases; later opens find no root and answer `errNotFound` at once. Two checks cannot both swap. A library
that goes away is reported by the next check (watcher, early signal, or a maker's check), opens then fail with
`errNotFound` without waiting on anything; one that comes back is used again (gap 10 s). `localPath` and
`os.Root` unchanged.

**A person first (part 3).** `gate` cannot go negative or stay held: `end` is once-only and deferred on every
route (`handleFile`, `handlePlay` twice, `handleOpen`), also on a panic; the window covers the lookup and the
open only (the encoder lookup and the conversion are outside it). The makers' wait ends with the person's last
open, the maker's context (Close: no deadlock, `TestMakerWaitIsBounded`), or `makerYieldMax`; a person's open
that never returns slows a maker to one open per 30 s, it does not stop it. Many people at once just keep the
gate held. Opens of makers already in flight are left alone.

**The numbers (parts 1, 6a).** The step rings, total, bands and `slowest` are right on the tests' known cases
(read and re-derived). Bands are by when the open began, since the stats' start. Snapshot: only numbers and the
fixed words `root/open/stat`, `person/maker`; nothing from ffmpeg's standard error but digits of exact
`out_time_us=`/`out_time_ms=` lines can reach a number (`TestProgressLineMustBeExact` covers signs, spaces,
prefixes, 19 digits). A path cannot put a newline in an error line on Windows.

**ffmpeg's standard error (6a).** It is drained for the process's whole life by exec's own copier into
`convProgress.Write`, which never blocks (a short lock) and keeps at most 256 bytes of an unfinished line; a
flood of errors costs only CPU. `conv.stop()` is deferred right after a successful start on every path (the
person leaves, the stall timer's cancel, an error), `Wait` waits for the copier, `WaitDelay` 5 s bounds a held
pipe: no goroutine or process left behind. A real ffmpeg's progress lines are read on both builds (probe: 1.8 s
and 2.0 s of video from 2 s clips). The frame command still keeps its 2 KB of error text for `failWord`;
unchanged.

**The walk gives way while a copy plays (6b).** The play gate is held from before `startConversion` to after
`conv.stop()` (defer order checked), released when the start fails; two overlapping copies keep it held until
the last ends; asked jobs are taken before the playing check in `nextOr`; the wait is on channels (copy ends,
a page asks, context), no busy loop; `askedOnly` is untouched.

**Gaps in time (7b).** A file with frames 1000 s apart: with `-fps_mode vfr` (and also by default with an MP4
output) 3 frames out; with `cfr` 2,999 frames. Both builds. The option is right and harmless.

**The page (part 4, 5).** The "Opening…" line is built with `h`/`textContent` only, no `innerHTML`, no request;
removed on `loadeddata`, `playing`, `error` (and `load`/`error` for "Original"), on `emptied` (a seek's new
stream, `stopVideo`), on `pause` for a stall line; its timers stop at the next tick once its element or line
has left the page (at most 1 s later), and nothing else is left running. On the home-network listener
`openButton` is `null` (`thisPC`), so neither the line nor the hint draws a refused control. `chat.js`: the
header's `append` leaves nulls out; `settings.js`: "1 post", "1 chat".

**Tests.** No test judges a span of real time: the clocks are injected (`fakeClock`, `stepClock`), order is
proven with channels and the stand-in root; the bounds (60 s) only stop a hang. `TestLibraryOpenAsksEarlyCheck`
polls `reachable()` with 5 ms sleeps up to the bound: a bounded poll, not a timing judgment.

## Guarantees without a test that would fail if they broke
- The makers' "library went away, not the file's fault" branch with the new root handling (F1 slipped through).
- Many flaps in a row (only one go-away-and-back cycle is tested; the code reads leak-free).
- A conversion that fails to *start* lets the walk go (only one that started and wrote nothing is tested).
- The page's line being removed: only script text is checked (no DOM); and the play-actions button staying
  visible beside the hint's (F5) is not looked at.
- The speed numbers under a reader that pauses (F3).

## Not checked
- The race detector, `go vet`, the whole package (not run, by the rules).
- The pages in a real browser (desktop and phone); event order is by reading the HTML media spec.
- Real SMB behaviour after a blip: which Windows error a dead directory handle gives is by reading Go's
  `syscall.Errno.Is` and Windows' usual codes, not measured.
- Linux or macOS.
- The old code's behaviour on the stale-root case was read (`handle()` at `f0e3f0c`), not run.
