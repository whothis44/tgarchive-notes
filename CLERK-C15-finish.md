# Clerk's steps: C15's listing runs, once (copies, session C5, 11-16)

You are a clerk. You decide nothing, fix nothing and edit no file. Do the numbered steps in order, exactly as
written. **At the first thing that is not as written, stop and report what you saw.** Report numbers, exit codes,
commit hashes, Go source file names and test names only. Never open anything under `E:\T`; start no program but
the commands below.

All commands are for the Bash tool (Git Bash). The copy is `/c/Users/trabi/Claude/Projects/Telegram/wt-copies-21`.
**Other agents of this track run go commands too. Before every step that runs `go` (steps 3 and 5) take the
track's lock:** `mkdir /c/Users/trabi/Claude/Projects/Telegram/runs-copies-golock`; if it fails because the
folder exists, wait 30 seconds (`sleep 30`) and try again, at most 40 times; a lock that never comes: stop and
report. **Right after the step's command ends, whatever its result:** `rmdir /c/Users/trabi/Claude/Projects/Telegram/runs-copies-golock`.

1. **The copy is clean and at the expected head.** Run:
   `cd /c/Users/trabi/Claude/Projects/Telegram/wt-copies-21 && git status --short | wc -l && git rev-parse --short=8 HEAD && git rev-parse --abbrev-ref HEAD`
   Expected: `0`, then the head named in your start message, then `wip/copies-21`. Anything else: stop and report.

2. **Merge the main head in by its hash.** Run:
   `cd /c/Users/trabi/Claude/Projects/Telegram/wt-copies-21 && git rev-parse --short=8 claude/charming-feynman-vm2xia`
   Note the hash as MAIN. Then, with that hash in place of MAIN:
   `cd /c/Users/trabi/Claude/Projects/Telegram/wt-copies-21 && git -c user.name=Claude -c user.email=noreply@anthropic.com merge --no-edit MAIN; echo "merge exit $?"; git status --short | wc -l; git rev-parse --short=8 HEAD`
   Expected: `merge exit 0`, `0`, a new hash (note it as TREE). **If `merge exit` is not 0: run
   `git diff --name-only --diff-filter=U`, then `git merge --abort`, then stop and report the file names.**

3. **Measure, then build, vet, format and the tool's tests on the merged tree** (take the lock first; a Bash
   timeout of 10 minutes). Measure:
   `powershell -NoProfile -Command "[math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB,1)"`
   Under 1.2: give the lock back, wait 2 minutes, take it again and measure again, at most 8 times; still under:
   stop and report the figures. Then run:
   `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh && cd /c/Users/trabi/Claude/Projects/Telegram/wt-copies-21/archiver && export GOMAXPROCS=2 GOMEMLIMIT=1GiB GOFLAGS=-p=1 && go build ./... ; echo "build exit $?"; gofmt -l internal cmd tools; echo "gofmt done"; go vet ./tools/probe-misses/; echo "vet exit $?"; s=$(date +%s); go test ./tools/probe-misses -count=1 -timeout 10m 2>&1 | tail -n 2 | cut -c1-100; echo "tool exit ${PIPESTATUS[0]} seconds $(( $(date +%s) - s ))"; go test ./tools/probe-misses -count=1 -v 2>&1 | grep -c '^--- PASS'; go test ./tools/probe-misses -count=1 -v 2>&1 | grep -c '^--- FAIL'`
   Expected: `build exit 0`; nothing between it and `gofmt done`; `vet exit 0`; a line starting `ok`; `tool exit 0`;
   a count of passed tests above 0; `0` failed. Give the lock back. Else stop and report the lines (Go
   identifiers, test names and the words ok or FAIL only).

4. **Push the merged tree.** Run:
   `cd /c/Users/trabi/Claude/Projects/Telegram/wt-copies-21 && git push -q private wip/copies-21 && git rev-parse --short=8 private/wip/copies-21 && git status --short | wc -l`
   Expected: the hash TREE, then `0`.

5. **The viewer's wall test** (no package may import across the wall; take the lock first, give it back after):
   `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh && cd /c/Users/trabi/Claude/Projects/Telegram/wt-copies-21/archiver && GOMAXPROCS=2 GOMEMLIMIT=1GiB GOFLAGS=-p=1 go test ./internal/viewer -count=1 -run TestWall 2>&1 | tail -n 1 | cut -c1-80`
   Expected: a line starting `ok`.

6. **Report**, and nothing else: the hashes MAIN and TREE; each expected line of step 3 as seen (with the
   seconds and the two counts); the free memory figure; the line of step 5; the two lines of step 4. If you
   stopped early: at which step and what you saw.
