# Brief C30: frame-check held probable copies from an idle lane; a "copy" confirms, a "no match" only marks

For ONE coder (Opus 5.5, high effort), start to finish; ONE independent review follows (it changes what a lane
takes and asks of Telegram). Written by the copies session C7, 2026-11-22.

## What the old app knows (read: COPY-CHECKS-STUDY B and D; ANSWERS-for-archiver-5 B, -8 C.4, -10; DIGEST "Copies")
- The old app sent one check in three to a held video, and a "no match" RELEASED it: 675 look-alike holds released,
  at least 23 of them exact copies; against a named candidate "no match" was wrong about 3 in 4 (answers 8). Its
  "copy" verdict is reliable (184 of 186 judged). So here: **a "no match" never releases a file and never moves it
  out of held** (CLAUDE.md's file rules). It is a mark: "frames found no match", the evidence a person or a later
  order uses.
- Held files here wait for good unless the owner releases them (`held_wait`, on by default): with it on, a lane
  never takes a held file (`lane.go` tier 5 with `HeldWait`). So today held videos are never frame-checked, and the
  owner releases them blind. A lane with nothing to download wastes its server's allowance (TRIED-BEFORE 16).
- A check reads 8 parts at the median (10 to 32), 10 to 22 s in hours without the speed limit, 3 to 14 minutes under
  it, about half timing out (answers 4 C.8). The parts are kept and reused if the file is downloaded later (0 refused).

## Where and how (these bind)
- Copy `C:\Users\trabi\Claude\Projects\Telegram\wt-copies-35`, branch `wip/copies-35` from the main head e34f4f64.
  Go commands only through `bash /c/Users/trabi/Claude/Projects/Telegram/runs-copies-c30/go1.sh <log> <go args...>`.
  Named tests and the whole of the small packages you change; NEVER the whole `internal/catalog` or
  `internal/collector`; the race detector (`ix-tools/copies-runs.sh`, Docker) only on a package whose concurrent code
  you change, by test name.
- Files: `internal/catalog` (`probe.go`, `lane.go` tier 5 and the probe supply, `state.go` only where the probe path
  needs it), `internal/supply`, `internal/probejudge`, tests, the report
  `archiver/docs/progress/copies-probe-held-REPORT.md`. The engine and the collector are Core's: if a line is needed
  there, stop and say so. No change of the held tier's ORDER in this piece (Core's K24 rebuilds `c_supply_src`; the
  order "likely distinct first" is a later piece). A schema step only if a column is unavoidable: claim the board's
  next free number first, moving "Next free" on in the same edit.
- Commits `git -C <copy> -c user.name=Claude -c user.email=noreply@anthropic.com commit`, ending with
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; push `wip/copies-35` to `private`. Invented data only.

## The change
1. **A stored switch `copies.probe_held`, OFF by default** (a new automatic pattern of requests: the owner turns it
   on, with its cost words), doors to read and set it for the pages.
2. **When on:** a lane that has NO available file in tiers 1 to 4 (and, with `held_wait` on, none in tier 5) and is
   NOT speed-limited (the engine's own `limited` state, read as the lane reads it) may claim ONE held probable video
   for a PROBE ONLY: one with no settled frame-check row, of the probe's size floor or more, with a candidate within
   20% of its length (the existing `ProbeLook`), newest held first. Never a transfer: when the probe's parts are in,
   the file goes back to held at once, whatever the judge later says. At most N such probes per lane per hour (a
   stored setting, default 30; no upper bound of the app's own). Counted per hour as kind "probe" with the reason
   "held".
3. **The verdicts on a held file:** copy: it stays held, with the frames' evidence on its edge (a confirmed probable
   copy); partly: stays held, the related edge written; no match: stays held, marked "frames found no match" (a
   value the viewer and a later order can read); unknown or final: stays held, the row recorded so it is not tried
   again before the existing retry bounds. The owner's words (released, keep_held, fetch for real, "different") are
   read as today and win.
4. **Kept parts:** as for any probe (reused if the file is ever downloaded; the cap and floor as they are).

## Tests (invented)
A held video probed only from an idle lane, never with a unique file available, never under the limit, never more
than the hourly bound; never transferred; every verdict leaves it held (each named); "no match" never releases,
however the owner's words stand; a released or fetch-for-real file is not probed as held (it is not held); the
switch off: nothing changes (row for row against the head); a restart mid-probe gives the file back held with its
parts kept.

## Done
All of it, the named runs and the small packages whole, any race run needed, `gofmt -l`, `go vet` of the packages
changed, committed and pushed, the report with the requests a probe of a held file cost in the tests. Hand back with
the head. Stop at the first thing not as written.
