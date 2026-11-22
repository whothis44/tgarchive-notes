# Brief K7: the fake Telegram hands one object to two encodes at once (a data race in the test rig) (Core, 2026-11-15)

For one Opus coder. A small fix in test scaffolding, asked for by the integrator (board message 52 (a) of
20:50 and message 53). You work in the copy `C:\Users\trabi\Claude\Projects\Telegram\wt-core-faketg`, branch
`wip/core-faketg` (cut from the main head 2625aa0), Go module in `archiver/`.

## What happened (read by the Core session in the log and the code)

`C:\Users\trabi\Claude\Projects\Telegram\runs-pages-g1\race-collector.log`: one DATA RACE report in a whole
race run of `internal/collector` (82 minutes), met in `TestTelegramHoursAcrossRestart`, which failed only by
"race detected during execution of test". Both sides are the same line:

- `internal/collector/faketg/conn.go`, `invoker.Invoke`: `ans.Encode(&b)`.
- The library's `Encode` WRITES the object it encodes: `tg.(*Document).EncodeBare` calls `SetFlags`
  (`bin.Fields.Set`). So encoding is not a read.
- Two goroutines of the library's `channelState.getDifference` (two channels of one account) each got an
  `*tg.UpdatesChannelDifference` whose `*tg.Message` holds the SAME `*tg.Document` (the fake's world keeps
  one object per media and puts it in every answer), and encoded at the same moment.

It is on the main branch already and can fail any whole race run of the collector by chance. It is the
test rig's defect, not the collector's.

A second way to the same race, by reading (not seen in a log; confirm or refute it): the fake pushes live
updates as objects, not bytes (`faketg/server.go` near line 1200 and `join.go` line 40:
`conn.handler.Handle(ctx, &tg.Updates{...})`), and the pushed `msg` is the same object the event list keeps
and a later difference answer encodes. The product then reads that message (the library's getters read
the flags field) while an `Invoke` on another goroutine may be writing its flags in `Encode`.

## The fix

**Nothing the fake hands out is shared with anything else.**
1. `invoker.Invoke`: the encode of an answer runs under one lock of the `Server` (a mutex of its own for
   encoding: do not hold the server's state lock `mu` through it unless you have checked that nothing
   under `mu` waits on an invoke). Two answers that share an object are then encoded one after the other.
   The decode into `output` needs no lock (it reads the buffer).
2. Every update the fake pushes to a handler is a private copy: encoded (under the same lock) and decoded
   into a fresh object before `Handle` is called, so the product never holds a pointer into the fake's
   world. Find every such push in the package (`grep` for `.Handle(`), not only the two named above.
3. Look for any other place where the package encodes, or lets code outside it read, an object of its
   world while another goroutine may encode it (`mirror.go`, `remote.go`, `preview.go`, `world.go`), and
   either close it the same way or say in the report why it is safe.

No change to what any answer or update contains: the existing tests of the collector, the mirror and the
Telegram package must see the same bytes as before. Edit only files in
`archiver/internal/collector/faketg/`. Nothing else, no product code.

## The test

A named test in the `faketg` package (for example `TestAnswersSharingADocumentEncodeApart`): a small world
in which two channels of one account carry messages with the same document; many goroutines call the
difference (or history) request for both channels at once through `Conn.Main()`, for a few hundred rounds,
while live updates carrying the same message are pushed and read by a handler. No sleep, no bound on real
seconds: the detector is the judge. It must:
- **fail under the detector on the tree before your fix** (show the report's first lines in your report:
  run it once before you change `conn.go`), and
- pass under the detector after it, three runs in a row.

The detector runs in a Linux container (this PC's Windows build has none). One container at a time, 2 CPUs,
3 GB, from Git Bash:

    bash /c/Users/trabi/Claude/Projects/Telegram/ix-tools/race-archiver.sh /c/Users/trabi/Claude/Projects/Telegram/wt-core-faketg ./internal/collector/faketg 2 3g 20m

(the whole small `faketg` package; its first run compiles for some minutes: run it in the background and
wait). Measure the PC before each container (free memory, CPU; keep about 2 GB free, never pin the CPU;
another session's container and coders are running). On Windows, the package's tests by name without the
detector: `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`, then from
`wt-core-faketg/archiver`: `GOGC=25 GOMAXPROCS=1 go test -p 1 -count=1 ./internal/collector/faketg/`.
**Not yours to run:** the whole `internal/collector` (6 minutes, over 80 under the detector), `go vet ./...`,
anything else.

## How you work

- Commit to `wip/core-faketg` as you go (`git -c user.name=Claude -c user.email=noreply@anthropic.com
  commit`, ending with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`) and push with
  `git push private wip/core-faketg`. Never the main branch, never `origin`; never stash, reset or switch
  branches.
- `gofmt -l internal/collector/faketg` prints nothing before you hand back.
- Invented data only; nothing touches Telegram, the network or any real archive folder.
- Write `archiver/docs/progress/core-faketg-REPORT.md` on the branch: the race's two sides in your words,
  what you changed, every push and encode site you found and what you did with each, the test and its
  output before and after (the report's first lines, then the three passes), what you doubt.
- Hand back commit-ready: committed, pushed, the copy clean; say the head's short hash.
