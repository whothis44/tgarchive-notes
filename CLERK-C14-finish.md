# Clerk's steps: C14's fix commit, the merge of the main head and the full runs, once (copies, session C5, 11-16)

You are a clerk. You decide nothing, fix nothing and edit no file. Do the numbered steps in order, exactly as
written. **At the first thing that is not as written, stop and report what you saw.** Report numbers, exit codes,
commit hashes, Go source file names and test names only. Never print a folder's contents outside the copy, never
open anything under `E:\T`, start no program but the commands below.

All commands are for the Bash tool (Git Bash). The copy is `/c/Users/trabi/Claude/Projects/Telegram/wt-copies-20`.

1. **The copy has exactly four changed files.** Run:
   `cd /c/Users/trabi/Claude/Projects/Telegram/wt-copies-20 && git status --short && git rev-parse --short=8 HEAD && git rev-parse --abbrev-ref HEAD`
   Expected: four lines, ` M archiver/internal/collector/collector.go`, ` M archiver/internal/collector/command.go`,
   ` M archiver/internal/collector/pairwordsline.go`, ` M archiver/internal/pairwords/pairwords.go`; then
   `4fde3acf`; then `wip/copies-20`. Anything else: stop and report.

2. **It builds and is formatted.** Run (a Bash timeout of 10 minutes):
   `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh && cd /c/Users/trabi/Claude/Projects/Telegram/wt-copies-20/archiver && export GOMAXPROCS=2 GOMEMLIMIT=1GiB && go build ./... ; echo "build exit $?"; gofmt -l internal cmd; echo "gofmt done"`
   Expected: `build exit 0`, then nothing before `gofmt done`. Else stop and report.

3. **Commit and push the fix.** Run:
   `cd /c/Users/trabi/Claude/Projects/Telegram/wt-copies-20 && git add archiver/internal/collector/collector.go archiver/internal/collector/command.go archiver/internal/collector/pairwordsline.go archiver/internal/pairwords/pairwords.go && git -c user.name=Claude -c user.email=noreply@anthropic.com commit -q -m "Copies: the owner's words' line says exactly what an in-place read touches in the viewer's folder, and when the file is read (review E20, findings 1 and 4; words only)" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>" && git status --short | wc -l && git rev-parse --short=8 HEAD && git push -q private wip/copies-20 && git rev-parse --short=8 private/wip/copies-20`
   Expected: `0`, a new hash (note it as FIX), and the same hash again.

4. **Merge the main head in by its hash.** Run:
   `cd /c/Users/trabi/Claude/Projects/Telegram/wt-copies-20 && git rev-parse --short=8 claude/charming-feynman-vm2xia`
   Note the hash as MAIN (2b557601 is expected; if it is another, use the one you read and say so in the
   report). Then, with that hash in place of MAIN:
   `cd /c/Users/trabi/Claude/Projects/Telegram/wt-copies-20 && git -c user.name=Claude -c user.email=noreply@anthropic.com merge --no-edit MAIN; echo "merge exit $?"; git status --short | wc -l; git rev-parse --short=8 HEAD`
   Expected: `merge exit 0`, `0`, a new hash (note it as TREE). **If `merge exit` is not 0: run
   `git diff --name-only --diff-filter=U`, then `git merge --abort`, then stop and report the file names.**

5. **The merged tree builds, vets and its named tests pass on Windows.** Run (a Bash timeout of 10 minutes; if
   it is cut, run it again with `run_in_background: true` and wait for its notice):
   `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh && cd /c/Users/trabi/Claude/Projects/Telegram/wt-copies-20/archiver && export GOMAXPROCS=2 GOMEMLIMIT=1GiB && go build ./... ; echo "build exit $?"; go vet ./internal/collector/ ./internal/pairwords/; echo "vet exit $?"; s=$(date +%s); go test ./internal/collector -count=1 -timeout 15m -run 'TestPairWords|TestPartsDir|TestFlags' 2>&1 | tail -n 2 | cut -c1-100; echo "collector exit ${PIPESTATUS[0]} seconds $(( $(date +%s) - s ))"`
   Expected: `build exit 0`, `vet exit 0`, a line starting `ok`, and `collector exit 0`. Else stop and report the
   lines (Go identifiers, test names and the words ok or FAIL only); for failing tests also run the same
   `go test` with `-v 2>&1 | grep '^--- FAIL' | cut -c1-100` and report those names.

6. **Push the merged tree.** Run:
   `cd /c/Users/trabi/Claude/Projects/Telegram/wt-copies-20 && git push -q private wip/copies-20 && git rev-parse --short=8 private/wip/copies-20`
   Expected: the hash TREE.

7. **The whole reader's package and the fixed checks, on Windows** (start with the Bash tool's
   `run_in_background: true`; a few minutes; wait for its notice, do not poll):
   `bash /c/Users/trabi/Claude/Projects/Telegram/ix-tools/copies-runs.sh wt-copies-20 runs-copies-c14 "pairwords" "" "collector pairwords"`

8. **Measure the PC**:
   `powershell -NoProfile -Command "\$o=Get-CimInstance Win32_OperatingSystem; [math]::Round(\$o.FreePhysicalMemory/1MB,1); (Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 2 -MaxSamples 3).CounterSamples | ForEach-Object { [math]::Round(\$_.CookedValue) }"`
   Go on to step 9 only when the first number (free GB) is at least 2.0 and each of the other three (CPU per
   cent) is under 80; otherwise wait 2 minutes (the Bash tool's `run_in_background` with `sleep 120`, wait for
   its notice) and measure again, at most 8 times. **If it is still not so after 8 times: skip step 9, go to
   step 10, and say in the report that step 9 was not run and the last figures.**

9. **The race detector on the piece's collector tests by name** (in the background, about 10 to 15 minutes; wait
   for its notice, do not poll):
   `bash /c/Users/trabi/Claude/Projects/Telegram/ix-tools/copies-runs.sh wt-copies-20 runs-copies-c14r "" "collector=TestPairWords|TestPartsDir@2"`

10. **Read the results.** Run:
    `cd /c/Users/trabi/Claude/Projects/Telegram && for d in runs-copies-c14 runs-copies-c14r; do [ -d $d ] && for f in $d/*.log; do echo "$f: $(grep -c 'WARNING: DATA RACE' $f) races; $(grep -c '^--- FAIL' $f) failed; $(grep '^seconds ' $f | tail -1); $(grep '^ok \|^FAIL\s' $f | tail -1 | cut -c1-80); $(tail -n 1 $f)"; done; done; git -C wt-copies-20 status --short | wc -l; git -C wt-copies-20 rev-parse --short=8 HEAD`
    and, for any log whose last line is not `exit 0`:
    `grep -h '^--- FAIL\|^FAIL\|^panic:' <that log> | cut -c1-120 | head -20`

11. **Report**, and nothing else: the hashes FIX, MAIN and TREE; each expected line of steps 2 and 5 as seen
    (with the seconds); the PC's figures of step 8; every line of step 10; the names of failing tests if any;
    whether step 9 ran. If you stopped early: at which step and what you saw.
