# Review brief: E15, the catalogue's side of the frame check (copies track, session C3, 2026-11-15)

You are an independent reviewer. **Read-only: you change nothing in the copy you review**
(`C:\Users\trabi\Claude\Projects\Telegram\wt-copies-15`, branch `wip/copies-15`, head d0d91f7c: the piece's five
commits 70be7acf to d776b79b on top of 567c8ca6, then the main head 10a9e3a8 merged in). You commit nothing,
push nothing, switch no branch. Your own files (probe tests, notes, your report) live only in
`C:\Users\trabi\Claude\Projects\Telegram\wt-copies-review15-scratch` (make it). A probe is a `_test.go` file in
that folder compiled into the package with `go test -overlay <a JSON file in the scratch folder>` (the overlay
maps a path inside the package to your file), so the copy stays untouched; check with `git status` in the copy
before you finish that it is clean.

What was asked of the coder: `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-E15-frame-check-catalogue.md` (read
it in full, with the three corrections marked by their time) and the design
`C:\Users\trabi\Claude\Projects\Telegram\DESIGN-COPIES-frame-check.md`. The coder's report:
`archiver/docs/progress/copies-probe-catalogue-REPORT.md` in the copy (its departures and doubts are part of
what you judge). The piece's diff: `git diff 567c8ca6 d776b79b` in the copy.

## What this code is for, and the rules it must hold
A video of 20 MB or more that may be a re-encoded copy of a saved one gets a "probe turn" before its
download: a lane fetches a few 1 MiB parts into a part store, a judge (not built yet) compares frames, and the
file is then held as a probable copy or downloaded with its parts reused. This piece is the catalogue's
tables and doors, the part store's ledger on the catalogue, and the supply's decision at `Next`. The supply is
download-path code that runs concurrently with every lane. The rules, each from an incident of the old app
(`archiver/docs/COPY-CHECKS-STUDY.md` B.1 and E.1; `archiver/docs/TRIED-BEFORE.md` section 6):
1. Nothing here may skip a file or write an exact edge. A probable copy is held, never skipped.
2. A check with no answer is never "download unchecked" outside the stated bounds (24 hours of unknowns with
   the 6 hour gap rule; 3 identical ffmpeg failures with no new part; a final why; a plan the lane refused;
   the frame check switched off through `ProbeCloseAll`), and every such file is counted with its why.
3. "No match", "partly", unknown and final never release a held file.
4. With `supply.Config.FrameCheck` nil, `Next` and every finish are exactly as on the base.
5. One finish per claim; a finish that cannot be recorded is retried, never lost; no file is left active or
   set aside for good by any path, a crash between two statements included.
6. No request to Telegram that buys nothing. **A lane's claim asks for a reference refresh** (`engine/lane.go`,
   the claim path), so every turn the supply hands out costs one.
7. Logs, errors and counts hold numbers and fixed words only.

## What I ask you to settle, by probes where a probe can show it (my reading; each may be wrong)
A. **A file the owner released.** `probeFile.held()` is true for a file that is free and has `probable = 1`,
   and `probeWantedSQL` sends a file with `probable = 1` to `held`. Is there any way a file that is WANTED
   (the owner released a held copy, or set it to be fetched for real; a held copy handed out because
   `held_wait` is off; a look-alike marked for the exact check first) carries `probable = 1` or gains it
   during its check, so that "no match", "partly", unknown or final sends it to `held`? Drive each through
   the real doors (`Release`, the owner's release, `HoldLookAlike`, `SetChatWants`) and say what happens.
B. **Turns that fetch nothing.** After an unknown the row goes to phase `fetch` with an empty plan, and the
   supply hands the file out with the first and last part, both kept already. Count, in a scripted run with a
   judge that never answers and with one that always answers unknown, how many claims and how many transport
   and refresh requests one file costs over its 24 hours. If a turn that needs no part can be avoided (the
   file set aside for its judge again by a door at `Next`, with no claim), say what the smallest change is.
C. **The bit-for-bit claim.** The coder did not run the comparison against the base. Run the supply's
   scripted lane on the base (567c8ca6, by overlay or `git worktree`-free means: `git show` the base's files
   into your scratch folder) and on the head with `FrameCheck` nil, with probe rows in every phase present,
   and compare what `Next` hands out and what is written.
D. **`Next` under load.** A file that `probeNext` passes over counts as "passed" and makes `Next` ask the
   catalogue again with pages 8 and 64 times larger. With the judge not ready and many eligible videos at the
   head of a lane, or `ProbeLook` failing, how many statements does one `Next` make, and does a lane with
   ordinary files behind them stay fed? And how many `ProbeLook`s does a file cost while it waits at the
   head of a lane whose slots are busy (one per tick?).
E. **The round count.** `ProbeFetched` takes a turn for a retry when the row is in phase `fetch` with a why
   on it. A "more parts" verdict followed by an unknown at `Next` (the judge not ready) leaves the judge's
   plan with a why: the turn that then fetches it is not counted as a round. Can rounds or parts pass their
   bounds (4, 32) by any order of verdicts and settlings?
F. **A row left open.** A file whose row is in phase `fetch` or `judge` and which becomes held by the
   ladder, marked for the exact check first, or not collected: `probeNext` no longer looks at it. Is it ever
   downloaded with its row still open (uncounted)? What does `ProbeStats` say then?
G. **The candidates.** `VideoCandidates` and `ProbeLook`'s walk on the new index: a lost file never a
   candidate; the file itself never its own candidate; the bound on entries read when most entries near the
   length are failure rows, lost files or another version; the closest-first order against a brute-force
   answer over a few thousand random lengths.
H. **The ledger.** `PutPart` for a number the catalogue does not hold; the cascade; `PartsNeeded` per state,
   and for a file set aside by the frame check; `ProbeCloseAll` in chunks with a failure in the middle; a
   "copy" verdict's deleted rows against a `parts.Store` that still has the file in memory (does `Kept` give
   a part whose row is gone?).
I. **The schema step:** on a file at the version before, twice, and refused elsewhere; the hourly columns;
   whether any statement of another track's tests or code names the version number.
J. **The tests themselves:** for each mutation the report lists, and five of your own choosing in
   `probeSettle` and `probeNext`, say whether a named test fails. The report says the "never plan" rule is
   held by one test only.
K. Anything else you find. The brief's own rules may be wrong too: say so where a rule of the brief, followed
   exactly, breaks one of the seven rules above.

## How to work
`source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`, then in the copy's `archiver/`:
`GOGC=25 GOMAXPROCS=2 go test -p 1 -count=1 -overlay <file> ./internal/<package>/ -run '<names>'`. Named tests
and your probes only: no whole run of `internal/catalog` or `internal/supply`, no race detector, nothing in
Docker, no `go vet` over the tree. Before each go command look at the free memory
(`(Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB` in PowerShell) and wait a minute when it is
under 2.5 GB; never two go commands at once. Nothing you run may contact Telegram or the network; invented
data in temp folders only; never open anything under `E:\T` or any real catalogue. Any file holding a
Windows path is written with the Write tool, never from an inline script string.

## Your report
`C:\Users\trabi\Claude\Projects\Telegram\wt-copies-review15-scratch\REVIEW.md`: findings ranked, each
**confirmed** (a probe shows it: name the probe file and what it printed, counts only) or **plausible** (by
reading: say exactly where), with its severity (which of the seven rules it breaks), the lines, and the
smallest fix you see; then what you checked and found sound, per letter A to K; then what you did not check.
No names, paths of real files, ids or texts of any archive. Your last message to me: the count of findings
by rank and severity, then at most 25 lines with the confirmed ones first.
