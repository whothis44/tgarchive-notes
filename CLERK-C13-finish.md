# Clerk's steps: C13's last checks after the main head (with C12) was merged in (copies, session C4, 11-16)

You are a clerk. You decide nothing, fix nothing and edit no file. Do the numbered steps in order, exactly as
written. **At the first thing that is not as written, stop and report what you saw.** Report numbers, exit codes,
commit hashes, Go source file names and test names only.

All commands are for the Bash tool (Git Bash).

1. **The copy has exactly two changed files.** Run:
   `cd /c/Users/trabi/Claude/Projects/Telegram/wt-copies-19 && git status --short && git rev-parse --short HEAD && git diff --numstat`
   Expected: two lines, ` M archiver/internal/collector/framecheck_test.go` and
   ` M archiver/internal/probejudge/panics.go`, the head `95ed04fb`, and the numstat lines
   `1	1	archiver/internal/collector/framecheck_test.go` and `2	2	archiver/internal/probejudge/panics.go`.
   Anything else: stop and report.

2. **It builds and is formatted; the tests that meet the change pass on Windows.** Run (a Bash timeout of 10
   minutes; if it is cut, run it again with `run_in_background: true` and wait for its notice):
   `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh && cd /c/Users/trabi/Claude/Projects/Telegram/wt-copies-19/archiver && export FFMPEG_PATH="$(where.exe ffmpeg 2>/dev/null | sed -n 2p | tr -d '\r')" GOMAXPROCS=2 && go build ./... ; echo "build exit $?"; gofmt -l internal cmd; echo "gofmt done"; go vet ./internal/catalog/ ./internal/pairwords/ ./internal/probejudge/ ./internal/supply/ ./internal/exact/ ./internal/collector/; echo "vet exit $?"; go test ./internal/probejudge ./internal/pairwords ./internal/parts ./internal/partsledger ./internal/exact -count=1 -timeout 10m 2>&1 | tail -n 6; echo "small exit ${PIPESTATUS[0]}"; go test ./internal/collector -count=1 -timeout 15m -run 'TestFrameCheck|TestJudgeStops|TestJudgeRunAgain|TestKeptParts|TestFlagsOffAsToday' 2>&1 | tail -n 2; echo "collector exit ${PIPESTATUS[0]}"; go test ./internal/viewer -count=1 -run TestWall 2>&1 | tail -n 1`
   Expected: `build exit 0`, nothing between it and `gofmt done`, `vet exit 0`, five `ok` lines and
   `small exit 0`, an `ok` line and `collector exit 0`, an `ok` line for the viewer. Else stop and report the lines (Go identifiers, test names and
   the words ok or FAIL only).

3. **Commit and push.** Run:
   `cd /c/Users/trabi/Claude/Projects/Telegram/wt-copies-19 && git add archiver/internal/probejudge/panics.go archiver/internal/collector/framecheck_test.go && git -c user.name=Claude -c user.email=noreply@anthropic.com commit -q -m "The judge's marked catalogue takes the candidates' call by its new name (the meeting of this branch and the collector's lines)" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>" && git status --short | wc -l && git rev-parse --short HEAD && git push private wip/copies-19 && git rev-parse --short private/wip/copies-19`
   Expected: `0`, a new hash (note it), the push, and the same hash again.

4. **The whole package both branches changed, on Windows** (start with the Bash tool's
   `run_in_background: true`; about 5 minutes; wait for its notice, do not poll):
   `bash /c/Users/trabi/Claude/Projects/Telegram/ix-tools/copies-runs.sh wt-copies-19 runs-copies-c13c "supply" "" ""`

5. **Measure the PC**:
   `powershell -NoProfile -Command "\$o=Get-CimInstance Win32_OperatingSystem; [math]::Round(\$o.FreePhysicalMemory/1MB,1); (Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 2 -MaxSamples 3).CounterSamples | ForEach-Object { [math]::Round(\$_.CookedValue) }"`
   Go on to step 6 only when the first number (free GB) is at least 2.4 and each of the other three (CPU per
   cent) is under 80; otherwise wait 2 minutes (the Bash tool's `run_in_background` with `sleep 120`, wait for
   its notice) and measure again, at most 10 times. **If it is still not so after 10 times: skip step 6, go to
   step 7, and say in the report that step 6 was not run and the last figures.**

6. **The race detector on the Supply's settle tests and the judge's package** (in the background, about 10
   minutes; wait for its notice):
   `bash /c/Users/trabi/Claude/Projects/Telegram/ix-tools/copies-runs.sh wt-copies-19 runs-copies-c13d "" "supply=TestSupplySettles|TestSettle@1 probejudge@1"`

7. **Read the results.** Run:
   `cd /c/Users/trabi/Claude/Projects/Telegram && for d in runs-copies-c13c runs-copies-c13d; do [ -d $d ] && for f in $d/*.log; do echo "$f: $(grep -c 'WARNING: DATA RACE' $f) races; $(grep -c '^--- FAIL' $f) failed; $(grep '^seconds ' $f | tail -1); $(grep '^ok \|^FAIL\s' $f | tail -1 | cut -c1-80); $(tail -n 1 $f)"; done; done`
   and, for any log whose last line is not `exit 0`:
   `grep -h '^--- FAIL\|^FAIL\|^panic:' <that log> | cut -c1-120 | head -20`

8. **Report**, and nothing else: the hashes of steps 1 and 3; each expected line of step 2 as seen; the PC's
   figures; every line of step 7; the names of failing tests if any; whether step 6 ran. If you stopped early:
   at which step and what you saw.
