# Clerk's steps: C16's full runs, once (copies, session C5, 11-16)

You are a clerk. You decide nothing, fix nothing and edit no file. Do the numbered steps in order, exactly as
written. **At the first thing that is not as written, stop and report what you saw.** Report numbers, exit codes,
commit hashes, Go source file names and test names only. Never open anything under `E:\T`; start no program but
the commands below.

All commands are for the Bash tool (Git Bash). The copy is `/c/Users/trabi/Claude/Projects/Telegram/wt-copies-22`.
**Other agents of this track run go commands too. Before every step marked LOCK take the track's lock:**
`mkdir /c/Users/trabi/Claude/Projects/Telegram/runs-copies-golock`; if it fails because the folder exists, wait
30 seconds (`sleep 30`) and try again, at most 60 times; a lock that never comes: stop and report. **Right after
the step's command ends, whatever its result:** `rmdir /c/Users/trabi/Claude/Projects/Telegram/runs-copies-golock`.
Before each LOCK step also measure free memory:
`powershell -NoProfile -Command "[math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB,1)"`
Under 1.2: give the lock back, wait 2 minutes, take it again and measure again, at most 8 times; still under:
stop and report the figures.

1. **The copy is clean and at the expected head.** Run:
   `cd /c/Users/trabi/Claude/Projects/Telegram/wt-copies-22 && git status --short | wc -l && git rev-parse --short=8 HEAD && git rev-parse --abbrev-ref HEAD`
   Expected: `0`, then the head named in your start message, then `wip/copies-22`. Anything else: stop and report.

2. **Merge the main head in by its hash.** Run:
   `cd /c/Users/trabi/Claude/Projects/Telegram/wt-copies-22 && git rev-parse --short=8 claude/charming-feynman-vm2xia`
   Note the hash as MAIN. Then, with that hash in place of MAIN:
   `cd /c/Users/trabi/Claude/Projects/Telegram/wt-copies-22 && git -c user.name=Claude -c user.email=noreply@anthropic.com merge --no-edit MAIN; echo "merge exit $?"; git status --short | wc -l; git rev-parse --short=8 HEAD`
   Expected: `merge exit 0`, `0`, a hash (note it as TREE; it equals the head of step 1 only if MAIN was already
   in it). **If `merge exit` is not 0: run `git diff --name-only --diff-filter=U`, then `git merge --abort`,
   then stop and report the file names.**

3. **LOCK. Build, vet, format and the named tests on Windows** (a Bash timeout of 10 minutes; if it is cut, run
   it again with `run_in_background: true` and wait for its notice):
   `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh && cd /c/Users/trabi/Claude/Projects/Telegram/wt-copies-22/archiver && export GOMAXPROCS=2 GOMEMLIMIT=1GiB GOFLAGS=-p=1 && go build ./... ; echo "build exit $?"; gofmt -l internal cmd; echo "gofmt done"; go vet ./internal/collector/ ./internal/copyset/; echo "vet exit $?"; go test ./internal/copyset -count=1 2>&1 | tail -n 1 | cut -c1-90; echo "copyset exit ${PIPESTATUS[0]}"; s=$(date +%s); go test ./internal/collector -count=1 -timeout 20m -run 'TestCopySet|TestFlags|TestFrameCheck|TestPairWords|TestPartsDir|TestKeptParts' 2>&1 | tail -n 2 | cut -c1-100; echo "collector exit ${PIPESTATUS[0]} seconds $(( $(date +%s) - s ))"; go test ./internal/viewer -count=1 -run TestWall 2>&1 | tail -n 1 | cut -c1-80`
   Expected: `build exit 0`; nothing between it and `gofmt done`; `vet exit 0`; a line starting `ok` and
   `copyset exit 0`; a line starting `ok` and `collector exit 0`; a line starting `ok` for the viewer. Give the
   lock back. Else stop and report the lines (Go identifiers, test names and the words ok or FAIL only); for
   failing tests also run the same `go test` with `-v 2>&1 | grep '^--- FAIL' | cut -c1-100` (under the lock)
   and report those names.

4. **Push the merged tree.** Run:
   `cd /c/Users/trabi/Claude/Projects/Telegram/wt-copies-22 && git push -q private wip/copies-22 && git rev-parse --short=8 private/wip/copies-22 && git status --short | wc -l`
   Expected: the hash TREE, then `0`.

5. **LOCK. The race detector on the piece's collector tests by name** (measure first as above, but here the
   free memory must be at least 1.5; start with the Bash tool's `run_in_background: true`; about 10 to 15
   minutes; wait for its notice, do not poll; give the lock back when it has ended):
   `bash /c/Users/trabi/Claude/Projects/Telegram/ix-tools/copies-runs.sh wt-copies-22 runs-copies-c16r "" "collector=TestCopySet@2"`
   **If the memory never reaches 1.5 after 8 measurements: skip this step, give the lock back, and say in the
   report that step 5 was not run and the last figure.**

6. **Read the results.** Run:
   `cd /c/Users/trabi/Claude/Projects/Telegram && for f in runs-copies-c16r/*.log; do echo "$f: $(grep -c 'WARNING: DATA RACE' $f) races; $(grep -c '^--- FAIL' $f) failed; $(grep '^ok \|^FAIL\s' $f | tail -1 | cut -c1-80); $(tail -n 1 $f)"; done; git -C wt-copies-22 status --short | wc -l; git -C wt-copies-22 rev-parse --short=8 HEAD`
   and, for any log whose last line is not `exit 0`:
   `grep -h '^--- FAIL\|^FAIL\|^panic:' <that log> | cut -c1-120 | head -20`

7. **Report**, and nothing else: the hashes MAIN and TREE; each expected line of step 3 as seen (with the
   seconds); the memory figures; every line of step 6; whether step 5 ran; the two lines of step 4. If you
   stopped early: at which step and what you saw.
