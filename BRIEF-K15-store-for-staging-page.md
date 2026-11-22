# Brief K15: three things the store gives the Staging page (Core, session K-4, 2026-11-16)

**Rules of the house, first (the project folder's `CLAUDE.md`, the archiver section):** you are the Opus coder
of this piece; you code and hand back commit-ready work. Named tests only while you work (`-run`, this one
package); no whole run of any package, no race detector, no `go vet` over many packages: the full runs happen
once, after the independent review, by a Sonnet clerk. Invented data only in tests; nothing of a file's name
or path in any log line, error text or count; new log lines are constant format strings. Never start, stop or
touch a running program; never read anything under `E:\` or on the NAS. Before every `go` command:
`source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`, and prefix it with
`GOGC=25 GOMAXPROCS=2` (`-p 1`); another coder works on this PC: one go command at a time.

**Where:** the copy `C:\Users\trabi\Claude\Projects\Telegram\wt-core-store`, branch `wip/core-store`, cut from
the main head 788ebf77. Commit as you go (`git -c user.name=Claude -c user.email=noreply@anthropic.com commit`,
the message ending with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`) and push that branch to the
remote `private` (`git push private wip/core-store`). Never push or merge any other branch. No `git stash`.

## 0. What this is, and the one rule over it

The Staging page (merged, pages track: `internal/collector/livepages/staging.go`, read through
`internal/collector/pagesstaging.go`) shows the copy from the local staging folder to the library on the NAS.
Its review asked three things of `internal/store` (board message 94 a). They are small. **The package is on
the path of every download** (`Writer` is the engine's sink) **and of every copy to the library** (`Copier`).
What the old app learnt, at cost (`archiver/docs/TRIED-BEFORE.md` section 8, read it: 14 lines): a full
staging disk once blocked every download for 3 hours. **The rule: never block a download on staging, and
nothing new reads the library.** Nothing in this piece may make `Writer.Open`, a write of a download, or a
copy wait longer than today, and nothing in it touches the library's folder. If a part below cannot be built
without that, stop and say so.

Read first: `internal/store/copier.go` (the struct, `allowed`, `account`, `writeTagged`, `Gauges`, `Away`,
`LibraryFull`), `internal/store/writer.go` (the struct, `place`, `stagingAway`, `stagingBack`, `stagingFull`,
`StagingState`, `Run`), `internal/store/counters.go` (`Gauges`, `Hour`), and how the page reads them
(`internal/collector/pagesstaging.go`, `internal/collector/staging.go` near its `StagingState` call).

## 1. The copiers' numbers without a statement

**For:** the page reads "copiers allowed, busy, pinned, limited now" every few seconds. Today it gets them
through `Copier.Gauges`, which reads the whole copy queue's summary from the ledger a second time on every
reading (more than half of a reading's 139 to 202 ms at 100,000 ledger rows).

A new method on `Copier` (name it as the package names things; `Load` is my word) that answers from memory
only: allowed now, busy now, pinned, limited now, the time, and part 2's number. No ledger call, no context,
no file system call. It must hold `c.mu` no longer than `Away()` does. `Gauges` itself stays as it is (the
shared report uses it).

## 2. Bytes counted as they are written

**For:** the hour's `CopiedBytes` moves only when a file ends, so the page cannot show a copy speed while a
large file is on its way (it says "it moves when a file ends").

The copier already counts bytes as they are written, for the tuner (`writeTagged.Write` adds to `c.copied`).
Add a second count beside it that is never reset: bytes written to the library by copiers since this `Copier`
was made, read through part 1's method. Its comment says what it is and is not: written, not verified; the
bytes of a copy that later fails its check, or is tried again, are counted each time they are written. The
tuner's own count and everything the tuner does stay exactly as they are (show it: the tuner's tests by name
pass unchanged).

## 3. Staging: "resting since", and "away" that ends when the folder reads again

**For (a):** when the staging disk was full the writer rests it for `FullPause` and knows only until when
(`fullUntil`); the page wants since when. **For (b):** "staging away" is cleared only inside `place`, that is
when the next download opens. With no download opening (downloads paused, nothing queued, a quiet night) the
page says "staging away since ..." for ever after the disk is back.

- (a) Keep when the current rest began (set in `stagingFull` only when no rest is running; a second full
  error inside a rest moves the end, not the beginning). A new read method on `Writer` beside
  `StagingState` (which keeps its signature: two callers) that answers away, away since, resting now,
  resting since, resting until, in one struct. "Resting now" is judged against the writer's clock inside the
  method, so that a reader does not compare times of two clocks.
- (b) In `Writer.Run`'s loop: when staging is away and the time for the next probe has come, ask the staging
  folder's free space once (the same `FS.Free` call `place` makes) and, when it answers, end "away"
  (`stagingBack`); when it does not, set the next probe as `stagingAway` does. Rules: **the file system call
  is made WITHOUT `w.mu` held** (a disk that hangs must not hold the lock `Open` needs); after it, take the
  lock and act only if the state is still what the probe was made for (still away, the same probe time: a
  download's own probe in `place` may have run meanwhile); at most one probe per `AwayProbe`, shared with
  `place`'s (never two probes for one period); the staging folder only, never the library's. What a download
  sees is unchanged in effect: at its next open after the probe time it would have probed itself and got
  the same answer. Counters: the end of "away" is counted as today (`stagingBack`); a background probe that
  fails is not a download that met an unknown room: do not add it to `RoomUnknown`; if you think a count is
  needed, say so in the hand-back instead of adding one.
- Say in the hand-back whether `Writer.Run` is running in every way the collector starts the store, and what
  happens to (b) where it is not.

## 4. What is NOT in this piece

Nothing in `internal/collector/livepages` or `internal/server` (the page is the pages track's; it wires the
new reads itself). In `internal/collector/pagesstaging.go` nothing either. No change to where a download
goes, to the copier's feeding, the tuner, the checks, the sweep or the ledger. No schema step.

## 5. Tests, and the hand-back

- Each part has tests you saw FAIL before the code, on the package's own fakes (the fake clock, the fake file
  system): part 1: the numbers against a rig with copies running, and that no ledger call is made (count
  them at the rig's ledger); part 2: the count grows while a copy is held mid-file, is not reset by the
  tuner's period, and counts a failed copy's bytes; part 3 (a): since and until over two full errors; (b):
  away ends by the loop's probe with no download opening; a probe that hangs does not hold up an `Open`
  (the fake's `Free` blocked on a channel, an `Open` returns meanwhile); a probe overtaken by `place` changes
  nothing; never two probes in one period. No test judges on real time.
- Named tests only (`go test ./internal/store -run '<names>' -count=1 -p 1`); `gofmt -l` on your files; once at
  the end `go build ./...` and `go vet ./internal/store`.
- Hand back in `archiver/docs/progress/core-store-REPORT.md` (committed) and as your last message: the head's
  hash, pushed or not; per part what was built (file, function, signature: the pages track builds on this
  text as it is); the named tests and results as run; every departure from this brief and why; what you
  could not test.
