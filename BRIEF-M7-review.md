# Brief: an independent review of M7 (the automatic mirror's varied timing; "at once, or gathered for N minutes")

You are a challenger, not the author. Read-only: **edit and commit nothing** in
`C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-timing` (branch `wip/mirror-timing`; the head is named in your
start message; the piece is `git diff 2625aa0..HEAD`, module in `archiver/`) or in any other copy. Your own folder:
`C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-review9-scratch` (make it). Your report goes there as
`REVIEW.md`; your probes go there as test files loaded with `go test -overlay` (an `overlay.json` mapping a path
inside the copy's package to your file), never written into the copy. Look at `wt-mirror-review8-scratch`
(`REVIEW-2.md`, `zz_m8probe_test.go`, `overlay-mirror.json`) for the form of an earlier review of the same packages.

## What the piece is (the author's brief, for what was asked: `BRIEF-M7-auto-timing.md` in the project folder)
A private Go program mirrors a Telegram chat into a private channel it creates; its automatic task
(`internal/mirror/auto.go` `Turn`, called from the collector's reader loop, `internal/collector/mirror_auto.go`)
sends at most one request a turn and never sleeps: every bound is a not-before time. Before this piece the next
write went a fixed pause after the account's last one (20 s, or a stored, lengthened one) and a message was
forwarded once it was 90 s old. This piece: (A) a bounded random part on both, a pure keyed function (the same
number every turn and after a restart; nothing stored or kept), never shorter than the fixed times, off with
`run -auto-mirror-steady` or a nil source; (B) one stored setting `mirror.auto.gather` (absent: at once; 1 to
1440 minutes): the mirror's oldest candidate must be that old before anything of it goes; its doors for a page,
the owner's `mirror -timing` (shows) and `mirror -gather N` (sets after a yes). The coder's own report:
`archiver/docs/progress/mirror-timing-REPORT.md` (its departures and doubts are claims to test, not facts).

**What a defect costs here.** This code acts for the owner on Telegram with nobody at the keyboard. The one
thing this piece must never do is send SOONER than the code before it would have: a write inside the pause, a
write inside or right at the end of a wait Telegram stated, a message forwarded younger than 90 s, an album
split because its halves got two different times. Next: a request repeated, a setting that silently falls back
to "at once" when it cannot be read, a mirror that never forwards again (a time that keeps moving away), a
create spent for a chat with nothing to forward, a name, text or id in a log or a printed line. The project's
rules for such code: one request a turn, never repeated by itself; every stated wait kept in full; the owner's
"never mirror" mark read before every request; fail closed on a stored value that cannot be read.

## Attack these, and anything else you find
1. **Never sooner.** For the pause and for the 90 s: is there any input (the last write's second, a clock that
   went back, a stored pause at its bounds, a pause just doubled, the rounding to whole seconds, an extra of
   exactly 0, an overflow, a negative or huge anchor) for which the varied not-before is earlier than the
   unvaried one of 2625aa0? Compare the two builds' decisions on the same invented stories (the copy at HEAD with
   a nil source must behave exactly as 2625aa0: the existing tests are the reference, and they must be unedited).
2. **The same number every turn.** Is anything drawn afresh per turn, per call or per process (a time that
   changes while it is waited for; `NextAt` jumping; the earliest of several draws winning)? What is the key
   made of: can two things that must differ share a time, or one thing get two times (an album's members; a
   message that changes album; the account's two mirrors; a chat that migrated)? Does a pause lengthened after
   a wait keep "larger pause, larger or equal extra"?
3. **Stated waits.** A wait recorded for create, forward or config that ends before, inside or after the varied
   pause; a wait stated on the turn's own request (the pause doubled and stored: is the STORED value the base,
   never the varied one; is it ever shortened); the forwarder's own `held` check; the per-hour bound and the
   per-day cap unchanged.
4. **Gathering.** The oldest candidate's time (`MirrorMessageTimes`: the later of the date and the first
   sighting): a backlog, messages put back by a settle (they go in batches of their own), a message that reached
   the catalogue late, the edge second, an album across the gather's edge and across the young cut (whole or
   absent, never split, also when its parts are not next to each other), a stream that never pauses (does
   anything starve or never go), a mirror not yet created (no create and no `help.getConfig` for nothing), a
   blocked mirror and its settle (unchanged?), a chat marked "never" or left while its messages are gathered.
   Does the wake time (`NextAt`) lead to a turn at the right moment, or to a turn every second (a busy loop in
   the reader), or to none?
5. **The setting.** Every way the stored value can be wrong (empty, spaces, a sign, a fraction, 0 stored, over
   the bound, another form, invalid UTF-8): is it ever read as "at once" or as another number; what the turn
   does then (nothing sent, nothing blocked or ended, said once, goes on by itself when it reads again); a nil
   `Settings`; a write that does not read back; the doors' fixed words; a setting changed while a batch waits.
6. **The command** (`mirror_cmd.go`, `mirror_timing_cmd.go`): `-timing` and `-gather` with every other mode's
   flags (`-chat`, `-settle`, `-take`, `-batches`, `-never`, `-allow`, `-list`): refused in fixed words, never
   dropped silently, never a request; anything written before a yes, on a "no" or on an ended input; the
   collector's lock; a catalogue older than the build (read-only before the yes); what `-timing` prints
   (numbers and fixed words only).
7. **The collector's side** (`mirror_auto.go`, the flags, the note line, the help's paragraph): does the switch
   off (`run` without `-auto-mirror`) still send, read and write exactly what 2625aa0 does; does `-auto-mirror`
   with `-auto-mirror-steady` equal 2625aa0's times; is the key the forward secret and is anything of it, or
   any number made from it, logged; is any new field read from two goroutines (the heartbeat reads the task's
   numbers under a lock: anything new there?).
8. **Tests that cannot fail.** For each rule the report claims (never sooner, the same every turn, under a
   wait, gather holds, unreadable sends nothing), undo the code in your overlay and say whether a named test
   notices. Tests that judge real seconds are a finding.

## How to work
- Prove with probes where you can: invented data and the tests' injected clock only; nothing is run against
  Telegram; never open real data, `E:\T`, any `start.bat`, or anything under `%LOCALAPPDATA%\tgarchive`.
- In Git Bash: `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`, then ONE go command at
  a time with `GOGC=25 GOMAXPROCS=1` and `-p 1`; named tests only (`-run`); compile a package's test binary once
  (`go test -c -overlay ...`) and run it with `-test.run` where that saves time. Before every go command measure
  the PC (free memory, CPU load): under 2 GB free or over 85% CPU, wait. Never a whole run of
  `internal/catalog` or `internal/collector`, never the race detector, never Docker. Leave nothing running.
- Mark every finding CONFIRMED (a probe or an exact reading shows it; give the probe's name and what it printed,
  as counts and fixed words) or PLAUSIBLE (by reading; say what would confirm it), with a severity (high: a
  request sent sooner than before, sent twice, or a mirror that stops for good; medium; low), the file and
  line, and the smallest fix you would accept. Say also what you found sound, and what you did not check.
- Anything you write holds counts, sizes and timings only; invented names in probes.

## Hand-back
`REVIEW.md` in your folder, findings most severe first. Final message, under 30 lines: the number of findings by
severity and verdict, one line each for the confirmed ones, what you did not check.
