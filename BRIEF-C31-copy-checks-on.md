# Brief C31: the fingerprint worker and the frame check ON by default (the parts' reuse comes with it)

For ONE coder (Opus 5.5, high effort), start to finish; ONE independent review follows (it decides holds and is on
the download path). Written by the copies session C7, 2026-11-22, at the integrator's word on the owner's question
of 02:20 ("Is the deduplication built-in, the smart/adaptive sampling of videos and the reuse of the samples?").

## What stands on the head e34f4f64 (read it yourself; check each before relying on it)
- The switches are stored settings (`internal/copyset`, brief E22/C16; the collector's `copyset.go` reads them once at
  the start, a given flag wins "for this run"). With NOTHING stored, each falls back to its flag's default, which is
  OFF (`framecheck.go` ~909/911: `-fingerprints`, `-frame-check` default false). The owner's app passes no flag and
  stores no row (counted read-only 11-22: 0 rows), so the fingerprint worker and the frame check never run there.
- The kept-parts store IS handed to the engine whenever the frame check runs (`framecheck.go` `enginePartStore`): a
  probe's parts are reused by the download through `engine.Config.Parts`. Verify that path end to end in a test of
  your own; if any link is missing, say exactly which.
- With the frame check on and its part store not settable (a folder problem), the start goes on with the check off for
  that run, said once (`frameCheckOffForRun`); with no ffmpeg, say what happens today and make it the same: off for
  the run, said once, never a refused start.

## Where and how (these bind)
- Copy `C:\Users\trabi\Claude\Projects\Telegram\wt-copies-36`, branch `wip/copies-36` from e34f4f64. Go commands only
  through `bash /c/Users/trabi/Claude/Projects/Telegram/runs-copies-c31/go1.sh <log> <go args...>`. Named tests and
  the whole of `internal/copyset`; in `internal/collector` ONLY named tests (`-run` the copy-set, frame-check,
  fingerprint and kept-parts tests: list them); NEVER the whole `internal/collector` or `internal/catalog`.
- Files: `internal/copyset`, the collector's `copyset.go`, `copyset_door.go`, `framecheck.go`, `fingerprints.go`
  (copies' files), their tests, the report `archiver/docs/progress/copies-checks-on-REPORT.md`. Any other collector
  file is Core's: stop and say what line, I lend it.
- Commits `git -C <copy> -c user.name=Claude -c user.email=noreply@anthropic.com commit`, ending with
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; push `wip/copies-36` to `private`. Invented data only.
  Never check out anything in `C:\Users\trabi\Claude\Projects\Telegram\repo-archiver` itself.

## The change
1. **Nothing stored means ON** for the fingerprint worker and the frame check; a stored "off" stays off (the owner's
   word survives builds); an unreadable stored value: say what it does today and keep it fail-closed for the frame
   check's holds (off), and say why. The GPU decoder's default: `auto` (its self-test picks the card or the CPU).
   Every other copy-set value keeps its default. The flags stay as per-run overrides (`-fingerprints=false`,
   `-frame-check=false` turn them off for one run).
2. **The doors** (`copyset_door.go`) answer on / off and "stored or default" so the Settings page (U-1 draws, pages
   wires) can show "(default)".
3. **The start line** says once, in fixed words, which copy checks run and why ("on by default", "off by your
   setting", "off for this run: no ffmpeg / its part store cannot be set up").
4. **The rules stand** and each has its test on the default: a frame check's "no match" never releases a file; only
   exact evidence skips; a probe's parts go through the lane's own request path (waits slept in full, counted as kind
   probe); a probe's kept parts are reused by the transfer with no second request for them.
5. **Cost words for the owner** (in the report, numbers from the record): a probe reads about 8 parts (8 MB) at the
   median for a video of 20 MB or more that has a saved look-alike candidate, once; the parts are reused if the video
   is downloaded; the old app's checks cost about 14% of the bytes downloaded in a fast spell, and part of that came
   back as reuse (answers 7 §5). Today the owner's catalogue has 0 video fingerprints, so the frame check finds no
   candidate until the worker has fingerprinted saved videos (new saves from staging; C29 for those already in the
   library; the old archive's 136,000 at the bring-in).

## Done
All of it, the tests, the named runs, `gofmt -l`, `go vet` of the packages changed, committed and pushed, the
report. Hand back with the head. Stop at the first thing not as written.
