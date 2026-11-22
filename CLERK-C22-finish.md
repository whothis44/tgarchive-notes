# Clerk's steps: C22's full runs, once (copies, session C6, 11-16)

You are a clerk. You decide nothing, fix nothing and edit no file. Do the numbered steps in order, exactly as
written. **At the first thing that is not as written, stop and report what you saw.** Report numbers, exit
codes, commit hashes, Go source file names and test names only. Never open anything under `E:\T`; start no
program but the commands below. Keep no helper script: run the commands as they are.

All commands are for the Bash tool (Git Bash). The copy is `/c/Users/trabi/Claude/Projects/Telegram/wt-copies-27`.
**Other agents may run go commands too. Before every step marked LOCK take the track's lock:**
`mkdir /c/Users/trabi/Claude/Projects/Telegram/runs-copies-golock`; if it fails because the folder exists, wait
30 seconds (`sleep 30`) and try again, at most 60 times; a lock that never comes: stop and report. **Right after
the step's command ends, whatever its result:** `rmdir /c/Users/trabi/Claude/Projects/Telegram/runs-copies-golock`.
Before each LOCK step also measure free memory:
`powershell -NoProfile -Command "[math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB,1)"`
Under 1.2: give the lock back, wait 2 minutes, take it again and measure again, at most 8 times; still under:
stop and report the figures.

1. **The copy is clean and at the expected head.** Run:
   `cd /c/Users/trabi/Claude/Projects/Telegram/wt-copies-27 && git status --short | wc -l && git rev-parse --short=8 HEAD && git rev-parse --abbrev-ref HEAD`
   Expected: `0`, then the head named in your start message, then `wip/copies-27`. Anything else: stop and report.

2. **Merge the main head in by its hash** (a trial said it is clean: the main branch moved by one commit that
   touches no file of this piece). Run:
   `cd /c/Users/trabi/Claude/Projects/Telegram/wt-copies-27 && git rev-parse --short=8 claude/charming-feynman-vm2xia`
   Note the hash as MAIN. Then, with that hash in place of MAIN:
   `cd /c/Users/trabi/Claude/Projects/Telegram/wt-copies-27 && git -c user.name=Claude -c user.email=noreply@anthropic.com merge --no-edit MAIN; echo "merge exit $?"; git status --short | wc -l; git rev-parse --short=8 HEAD`
   Expected: `merge exit 0`, `0`, a hash (note it as TREE; it is the same as the head of step 1 only when
   nothing was to merge). **If `merge exit` is not 0: run `git diff --name-only --diff-filter=U`, then
   `git merge --abort`, then stop and report the file names.**

3. **LOCK. Build, vet, format and the catalogue's named tests** (a Bash timeout of 10 minutes):
   `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh && cd /c/Users/trabi/Claude/Projects/Telegram/wt-copies-27/archiver && export GOMAXPROCS=2 GOMEMLIMIT=1GiB GOFLAGS=-p=1 && go build ./... ; echo "build exit $?"; gofmt -l internal cmd tools; echo "gofmt done"; go vet ./internal/catalog/; echo "vet exit $?"; go test ./internal/catalog -count=1 -timeout 10m -run 'TestTwin|TestSchema|TestPair|TestEdgeLog|TestChangeLog|TestActKeySchemaStep|TestMigrateV2' 2>&1 | tail -n 1 | cut -c1-90; echo "named exit ${PIPESTATUS[0]}"`
   Expected: `build exit 0`; nothing between it and `gofmt done`; `vet exit 0`; a line starting `ok` and
   `named exit 0`. Give the lock back. Else stop and report (for failing tests the same `go test` with
   `-v 2>&1 | grep '^--- FAIL' | cut -c1-100`, under the lock).

4. **LOCK. The whole catalogue on Windows** (start with the Bash tool's `run_in_background: true`; about 9 to
   12 minutes; wait for its notice, do not poll; give the lock back when it has ended):
   `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh && cd /c/Users/trabi/Claude/Projects/Telegram/wt-copies-27/archiver && export GOMAXPROCS=2 GOMEMLIMIT=1GiB GOFLAGS=-p=1 && mkdir -p /c/Users/trabi/Claude/Projects/Telegram/runs-copies-c22 && s=$(date +%s); go test ./internal/catalog -count=1 -timeout 30m > /c/Users/trabi/Claude/Projects/Telegram/runs-copies-c22/win-catalog.log 2>&1; rc=$?; echo "seconds $(( $(date +%s) - s ))" >> /c/Users/trabi/Claude/Projects/Telegram/runs-copies-c22/win-catalog.log; echo "exit $rc" >> /c/Users/trabi/Claude/Projects/Telegram/runs-copies-c22/win-catalog.log; tail -n 3 /c/Users/trabi/Claude/Projects/Telegram/runs-copies-c22/win-catalog.log | cut -c1-100`
   Expected: a line starting `ok`, a `seconds` line, `exit 0`. Else report
   `grep -h '^--- FAIL\|^FAIL\|^panic:' /c/Users/trabi/Claude/Projects/Telegram/runs-copies-c22/win-catalog.log | cut -c1-120 | head -20`
   and stop.

5. **LOCK. The packages that drain the pending door and hold copies through the catalogue** (start with
   `run_in_background: true`; about 4 minutes; wait for its notice; give the lock back when it has ended):
   `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh && cd /c/Users/trabi/Claude/Projects/Telegram/wt-copies-27/archiver && export GOMAXPROCS=2 GOMEMLIMIT=1GiB GOFLAGS=-p=1 && go test ./internal/pairwords ./internal/supply -count=1 -timeout 20m 2>&1 | tail -n 3 | cut -c1-100; echo "callers exit ${PIPESTATUS[0]}"`
   Expected: two lines starting `ok` and `callers exit 0`. Else report the lines and stop.

6. **LOCK. The viewer's update tests by name** (about 2 minutes; give the lock back after):
   `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh && cd /c/Users/trabi/Claude/Projects/Telegram/wt-copies-27/archiver && export GOMAXPROCS=2 GOMEMLIMIT=1GiB GOFLAGS=-p=1 && go test ./internal/viewer -count=1 -timeout 15m -v -run 'TestLost|TestStaged|TestIncremental|TestRandomUpdates|TestChanges|TestChangeLog|TestWall' 2>&1 | grep '^--- FAIL\|^--- PASS\|^ok \|^FAIL' | cut -c1-100 | sort | uniq -c | sort -rn | head -40`
   Expected: one line with `ok`, no line with `FAIL`. Report the count of `--- PASS` lines. Any `--- FAIL`:
   report each test name and stop.

7. **The copy is still clean and pushed.** Run:
   `cd /c/Users/trabi/Claude/Projects/Telegram/wt-copies-27 && git status --short | wc -l && git push -q private wip/copies-27; echo "push exit $?"; git rev-parse --short=8 HEAD && git ls-remote private refs/heads/wip/copies-27 | cut -c1-8`
   Expected: `0`, `push exit 0`, then the same hash twice (TREE).

8. **Report**, and nothing else: the hashes MAIN and TREE; the lines of steps 3, 4, 5 and 6 as seen (with the
   seconds); the memory figures; the lines of step 7. If you stopped early: at which step and what you saw.
