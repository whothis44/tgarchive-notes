# Brief E22, the independent review: the copy checks' switches as stored settings (copies, session C5, 11-16)

**For an Opus 5.5 reviewer at high effort who has not seen the coder's work. One pass. Read the difference and
what it calls, not the repository.**

- The piece: branch `wip/copies-22`, head 536d656e, in the copy
  `C:\Users\trabi\Claude\Projects\Telegram\wt-copies-22`, against the main head it was cut from (69a9c439):
  `git -C <copy> diff 69a9c439 HEAD`. Its brief: `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-E22-copy-settings.md`
  (read it first); the coder's report: `archiver/docs/progress/copies-copyset-REPORT.md` on the branch (read it
  last: a claim, not evidence).
- **You change nothing in that copy.** Probes go into a scratch copy you make yourself:
  `git -C /c/Users/trabi/Claude/Projects/Telegram/repo-archiver worktree add --detach /c/Users/trabi/Claude/Projects/Telegram/wt-copies-review22-scratch 536d656e`
  as untracked files named `zz_probe_*_test.go`; leave them there, uncommitted. Go:
  `. /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`, then the scratch copy's `archiver`.
  Only named tests (`-run`, `-count=1`), one go command at a time with `GOMAXPROCS=2 GOMEMLIMIT=1GiB GOFLAGS=-p=1`;
  before each: free memory at least 1.2 GB
  (`powershell -NoProfile -Command "[math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB,1)"`;
  under it wait 2 minutes and look again, at most 5 times, then skip that probe and say so) and the track's lock:
  `mkdir /c/Users/trabi/Claude/Projects/Telegram/runs-copies-golock` (if it exists wait 30 seconds and try again,
  20 minutes at most), `rmdir` right after the command. Never the whole collector, no race detector, no vet
  over packages.
- Invented data only; nothing runs against Telegram; never open anything under `E:\T`, a real catalogue or a
  folder of the owner's. A text with a Windows path is written with the Write tool, never through a shell string.

## The questions, in the order of their weight
1. **Can a stored setting keep the collector from starting, with no way back from the app?** The setters are
   doors of a RUNNING collector. With a flag, the owner takes the flag away; with a stored row there is nothing
   to take away. Trace every way the start can be refused or stopped because of a value that came from a row:
   the frame check stored "on" where its part store cannot be set up (the staging folder a drive's root with no
   `-parts-dir`, the folder overlapping, claimed by another catalogue, not writable, the catalogue's claim
   failing: `startFrameCheck`, `claimPartsDir`, `partsDirOf`), ffmpeg not found, a stored decoder word ffmpeg
   does not know, a stored cap below what is kept, a stored workers number. For each: does the start go on, and
   in what state? **A start refused because of a stored row is a finding of the highest rank**; the smallest fix
   (the main session's proposal, to judge: when the switch's value came from the row and not from the flag, a
   set-up that fails leaves the check off for this run, said once in fixed words and shown by the door, and the
   start goes on).
2. **With no row stored and no flag given a run is the main head's**: six reads of the settings table before
   the staging is made, and nothing else: no line, no field changed, no flag's meaning changed. Trace
   `frameFlags.apply`, `ignoredOf`, `copySettingsAtStart` and every changed line of `framecheck.go` and
   `fingerprints.go` for that case, and for "only flags given, no row" (must be the head's but for the new
   "for this run" lines).
3. **A stored value that cannot be read is never taken as its default silently, and never switches a check
   on**: every malformed form you can think of for each key (case, spaces, a number with a plus sign or leading
   zero, an empty string, a word with a path or an option in it, a very long value); what reaches ffmpeg's
   command line from a stored decoder word (it must be one plain word by the same check the flag has: could a
   stored row put an argument or a path there?).
4. **One source for defaults and bounds**: the flags' defaults, help and refusals and the package's are the
   same values; nothing was changed in what the flags accept (the coder's doubt: the stored decoders refuse an
   empty word while the flags take it as the CPU: is anything now refused or accepted that was not?).
5. **The doors**: the facts are true in each state (nothing stored; stored and equal to the run; stored and
   different: `Pending`; unreadable; by the run's flag; a `Config` made by code and not by the flags); a setter
   refuses in fixed words and writes nothing on a refusal; nothing is started, made or asked of Telegram by a
   door; what a door answers while no run is up; **data races**: the fields the start writes and the doors
   read (the coder argues it from the code, no race run was made: check the argument).
6. **The `Config` made by code** (the coder's choice: such a `Config` is taken as given, no row read): can any
   product path build a collector `Config` without the run command's flags and so skip the rows silently?
7. The package `internal/copyset` imports `vfp`, `probejudge`, `parts` and `footage/ffmpeg` for their constants:
   does that pull anything into a program that should not have it (a goroutine at init, a Windows-only file),
   and is there a smaller way to keep one source?
8. Privacy of the new lines: constant formats, no path, no value of a row printed raw.

## Probes to write (say which you ran and its result)
- Question 1: a start with `copies.frame_check` stored "on" and a part store that cannot be set up (take C12's
  rig for a refused part store folder); the same with the flag.
- Question 3: the malformed values per key through the collector's start, not only the package.
- One of your own choosing, where the difference made you least sure.

## What to hand back
A file `C:\Users\trabi\Claude\Projects\Telegram\REVIEW-E22-copy-settings.md` (write it with the Write tool):
the head you read; findings numbered, each with its rank (high: a start refused by a stored row, a check
switched on by a bad row, anything of a stored row reaching a command line unchecked, a run with no row and no
flag that is not the head's; medium; low), the lines, what happens, the smallest fix, whether a probe shows it;
what you did not look at; then one last line, exactly one of: "may be listed", "may be listed after these
fixes: <numbers>", "not yet". Your last message: that last line, the findings by rank with one line each for
high and medium, the probes run with their results.
