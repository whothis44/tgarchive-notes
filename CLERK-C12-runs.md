# Clerk's steps: merge the main head into `wip/copies-18` and run C12's full runs (copies, session C4, 11-16)

You are a clerk. You decide nothing, fix nothing and edit no file. Do the numbered steps in order, exactly as
written. **At the first thing that is not as written, stop and report what you saw.** Report numbers, exit codes,
commit hashes and test names only: never a path of the owner's, a name, a text or an id from any data.

All commands are for the Bash tool (Git Bash). The project folder is `/c/Users/trabi/Claude/Projects/Telegram`.

1. **The copy is as expected.** Run:
   `cd /c/Users/trabi/Claude/Projects/Telegram/wt-copies-18 && git status --short | wc -l && git rev-parse --short HEAD && git branch --show-current`
   Expected: `0`, `928c1d17`, `wip/copies-18`. Anything else: stop and report.

2. **Merge the main head in.** Run:
   `cd /c/Users/trabi/Claude/Projects/Telegram/wt-copies-18 && git fetch private && git rev-parse --short private/claude/charming-feynman-vm2xia`
   Note the hash it prints (the main head). Then run:
   `cd /c/Users/trabi/Claude/Projects/Telegram/wt-copies-18 && git -c user.name=Claude -c user.email=noreply@anthropic.com merge --no-ff private/claude/charming-feynman-vm2xia -m "Merge the main head into wip/copies-18 before its full runs" -m "Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"`
   - If it says "Already up to date": go on.
   - If it reports a conflict: run `git diff --name-only --diff-filter=U`, then `git merge --abort`, then stop and
     report the conflicting file names.
   - Otherwise run `git status --short | wc -l` (expected `0`) and `git rev-parse --short HEAD` (note it: the
     merged head), then `git push private wip/copies-18`.

3. **Measure the PC.** Run:
   `powershell -NoProfile -Command "\$o=Get-CimInstance Win32_OperatingSystem; [math]::Round(\$o.FreePhysicalMemory/1MB,1); (Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 2 -MaxSamples 3).CounterSamples | ForEach-Object { [math]::Round(\$_.CookedValue) }"`
   The first number is free memory in GB; the next three are CPU per cent. **Go on only when free memory is at
   least 3.0 and every CPU figure is under 80.** Otherwise wait 2 minutes (a background `sleep 120` is not allowed
   in the foreground: use the Bash tool's `run_in_background` with `sleep 120` and wait for its notice) and
   measure again, at most 10 times; if it is still not so, stop and report the last figures.

4. **Run A (whole packages on Windows, two small race runs).** Start with the Bash tool's `run_in_background: true`
   (it takes about 25 to 35 minutes; do not poll it, wait for its notice):
   `bash /c/Users/trabi/Claude/Projects/Telegram/ix-tools/copies-runs.sh wt-copies-18 runs-copies-c12 "parts partsledger probejudge supply collector" "parts@1 probejudge@1" "collector supply parts probejudge"`

5. When run A has ended, **measure the PC again as in step 3** (the same rule), then **run B (the Supply's tests by
   name under the race detector)**, in the background, about 10 to 20 minutes:
   `bash /c/Users/trabi/Claude/Projects/Telegram/ix-tools/copies-runs.sh wt-copies-18 runs-copies-c12b "" "supply=TestSupplySaved|TestSupplyReplay|TestC2@2"`

6. When run B has ended, **measure the PC again as in step 3**, then **run C (the collector's tests of the new
   tasks by name under the race detector)**, in the background, about 20 to 40 minutes:
   `bash /c/Users/trabi/Claude/Projects/Telegram/ix-tools/copies-runs.sh wt-copies-18 runs-copies-c12c "" "collector=TestRunStartsFingerprintWorker|TestFingerprintsOff|TestFlagsOffAsToday|TestFrameCheck|TestKeptParts|TestStopShutsPartStore|TestJudgeStops|TestJudgeRunAgain|TestEngineOtherPartSize|TestPartsDir|TestPartsOpen|TestCloseProbes|TestFlagsWords|TestKillRestart|TestStopWithCopyInFlight@2"`

7. **Read the results.** Run:
   `cd /c/Users/trabi/Claude/Projects/Telegram && for d in runs-copies-c12 runs-copies-c12b runs-copies-c12c; do for f in $d/*.log; do echo "$f: $(grep -c 'WARNING: DATA RACE' $f) races; $(grep -c '^--- FAIL' $f) failed; $(grep '^seconds ' $f | tail -1); $(grep '^ok \|^FAIL\s' $f | tail -1 | cut -c1-80); $(tail -n 1 $f)"; done; done`
   and, for any log whose last line is not `exit 0`, also:
   `grep -h '^--- FAIL\|^FAIL\|^panic:' <that log> | cut -c1-120 | head -20`
   (test names and the words FAIL or panic only; do not print other lines of a failing log.)
   Also run `cat /c/Users/trabi/Claude/Projects/Telegram/runs-copies-c12/win-gofmt.log | head -5` (it should hold
   only `exit 0`).

8. **Report**, and nothing else: the main head's hash and the merged head's hash from step 2 (or "already up to
   date"); whether the push went; the PC's figures of each measurement; for every log of the three runs its line
   from step 7; the names of failing tests if any; the wall-clock minutes of runs A, B and C. If you stopped
   early: at which step and what you saw.
