# Clerk's steps: C12's last checks after one test's wait was lengthened (copies, session C4, 11-16)

You are a clerk. You decide nothing, fix nothing and edit no file. Do the numbered steps in order, exactly as
written. **At the first thing that is not as written, stop and report what you saw.** Report numbers, exit codes,
commit hashes and test names only.

All commands are for the Bash tool (Git Bash).

1. **The copy has exactly one changed file.** Run:
   `cd /c/Users/trabi/Claude/Projects/Telegram/wt-copies-18 && git status --short && git rev-parse --short HEAD && git diff --numstat`
   Expected: one line ` M archiver/internal/collector/framecheck_test.go`, the head `3caa388f`, and the numstat
   line `4	1	archiver/internal/collector/framecheck_test.go`. Anything else: stop and report.

2. **It is formatted and the test passes on Windows.** Run:
   `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh && cd /c/Users/trabi/Claude/Projects/Telegram/wt-copies-18/archiver && gofmt -l internal/collector/framecheck_test.go; GOMAXPROCS=2 go test ./internal/collector -count=1 -run 'TestFrameCheckNoFFmpegWholeRun' -timeout 10m 2>&1 | tail -n 3; echo "exit ${PIPESTATUS[0]}"`
   Expected: no file name printed by gofmt, a line starting with `ok`, and `exit 0`. Else stop and report the
   last lines (test names and the words ok or FAIL only).

3. **Commit it.** Run:
   `cd /c/Users/trabi/Claude/Projects/Telegram/wt-copies-18 && git add archiver/internal/collector/framecheck_test.go && git -c user.name=Claude -c user.email=noreply@anthropic.com commit -q -m "The collector's frame check tests: the wait for the outage's bound follows the rig's clock (under the race detector the bound alone is over three minutes)" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>" && git status --short | wc -l && git rev-parse --short HEAD`
   Expected: `0` and a new hash (note it).

4. **Merge the main head in again (it moved since the first merge).** Run:
   `cd /c/Users/trabi/Claude/Projects/Telegram/wt-copies-18 && git fetch private && git rev-parse --short private/claude/charming-feynman-vm2xia`
   (note the hash), then:
   `cd /c/Users/trabi/Claude/Projects/Telegram/wt-copies-18 && git -c user.name=Claude -c user.email=noreply@anthropic.com merge --no-ff private/claude/charming-feynman-vm2xia -m "Merge the main head into wip/copies-18 again before its listing" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"`
   - "Already up to date": go on.
   - A conflict: run `git diff --name-only --diff-filter=U`, then `git merge --abort`, then stop and report the
     file names (the commit of step 3 stays; do not push).
   - Otherwise `git status --short | wc -l` (expected `0`) and `git rev-parse --short HEAD` (note it). Then list
     what the merge brought into the piece's packages:
     `git diff --name-only HEAD^1 HEAD -- archiver/internal/collector archiver/internal/supply archiver/internal/parts archiver/internal/partsledger archiver/internal/probejudge archiver/internal/catalog archiver/internal/engine archiver/internal/store | sed 's#archiver/internal/##'`
     (report those file names: they are Go source files of the program).

5. **It builds, and the piece's tests pass on the merged tree (on Windows, by name).** Run:
   `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh && cd /c/Users/trabi/Claude/Projects/Telegram/wt-copies-18/archiver && export FFMPEG_PATH="$(where.exe ffmpeg 2>/dev/null | sed -n 2p | tr -d '\r')" GOMAXPROCS=2 && go build ./... ; echo "build exit $?"; gofmt -l internal cmd; echo "gofmt done"; go vet ./internal/collector/ ./internal/supply/ ./internal/parts/ ./internal/probejudge/; echo "vet exit $?"; go test ./internal/collector -count=1 -timeout 20m -run 'TestRunStartsFingerprintWorker|TestFingerprintsOff|TestFlagsOffAsToday|TestFrameCheck|TestKeptParts|TestStopShutsPartStore|TestJudgeStops|TestJudgeRunAgain|TestEngineOtherPartSize|TestPartsDir|TestPartsOpen|TestCloseProbes|TestFlagsWords|TestKillRestart|TestStopWithCopyInFlight|TestE2EExact' 2>&1 | tail -n 3; echo "collector exit ${PIPESTATUS[0]}"; go test ./internal/parts ./internal/partsledger ./internal/probejudge -count=1 -timeout 10m 2>&1 | tail -n 4; echo "small exit ${PIPESTATUS[0]}"; go test ./internal/viewer -count=1 -run TestWall 2>&1 | tail -n 1`
   Expected: `build exit 0`, nothing between it and `gofmt done`, `vet exit 0`, an `ok` line and
   `collector exit 0`, three `ok` lines and `small exit 0`, an `ok` line for the viewer. Else stop and report the
   lines (test names and the words ok or FAIL only); do not push.

6. **Push.** `cd /c/Users/trabi/Claude/Projects/Telegram/wt-copies-18 && git push private wip/copies-18 && git rev-parse --short HEAD private/wip/copies-18`

7. **Measure the PC**, then the race detector on the collector's tests by name once more, on this tree:
   `powershell -NoProfile -Command "\$o=Get-CimInstance Win32_OperatingSystem; [math]::Round(\$o.FreePhysicalMemory/1MB,1); (Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 2 -MaxSamples 3).CounterSamples | ForEach-Object { [math]::Round(\$_.CookedValue) }"`
   Go on only when the first number (free GB) is at least 3.0 and each of the other three (CPU per cent) is under
   80; otherwise wait 2 minutes (the Bash tool's `run_in_background` with `sleep 120`, wait for its notice) and
   measure again, at most 20 times, then stop and report. Then start, with `run_in_background: true` (about 12
   to 20 minutes; wait for its notice, do not poll):
   `bash /c/Users/trabi/Claude/Projects/Telegram/ix-tools/copies-runs.sh wt-copies-18 runs-copies-c12d "" "collector=TestRunStartsFingerprintWorker|TestFingerprintsOff|TestFlagsOffAsToday|TestFrameCheck|TestKeptParts|TestStopShutsPartStore|TestJudgeStops|TestJudgeRunAgain|TestEngineOtherPartSize|TestPartsDir|TestPartsOpen|TestCloseProbes|TestFlagsWords|TestKillRestart|TestStopWithCopyInFlight@2"`

8. **Read it.** Run:
   `cd /c/Users/trabi/Claude/Projects/Telegram && for f in runs-copies-c12d/*.log; do echo "$f: $(grep -c 'WARNING: DATA RACE' $f) races; $(grep -c '^--- FAIL' $f) failed; $(grep '^ok \|^FAIL\s' $f | tail -1 | cut -c1-80); $(tail -n 1 $f)"; done; grep -h '^--- FAIL\|^panic:' runs-copies-c12d/race-collector.log | cut -c1-120 | head`

9. **Report**, and nothing else: the hashes of steps 1, 3, 4 and 6; the file names of step 4's list; each
   expected line of steps 2 and 5 as seen; the PC's figures; the lines of step 8; the names of failing tests if
   any. If you stopped early: at which step and what you saw.
