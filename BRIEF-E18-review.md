# Brief: the independent review of E18, the collector's lines (copies, session C4, 11-16)

**For an Opus 5.5 reviewer at high effort. You did not write this code and you are not told what its author
concluded. Find what is wrong with it; a review that finds nothing must say what it tried.**

## What you review
Branch `wip/copies-18` in `C:\Users\trabi\Claude\Projects\Telegram\wt-copies-18`, at the head named in the message
that started you, against its base (the main branch commit it was cut from, or the main head merged into it: `git
merge-base`). The piece switches on two merged systems in the collector, each behind a flag that is off by default:
the fingerprint worker (`-fingerprints`) and the frame check (`-frame-check`). Its brief is
`C:\Users\trabi\Claude\Projects\Telegram\BRIEF-E18-collector-lines.md`: **read it in full, and review the brief's
own rules as hard as the code** (in this track's last pieces the brief's rules were the commonest defects: a wait
with no bound, a rule that made a file final too early, an order taken without thinking who can write where).
The coder's report is `archiver/docs/progress/copies-collector-lines-REPORT.md` on the branch: read it last, after
your own read of the difference, so that its account does not become yours.

It is download-path code. The owner's rules that bind it:
- Only exact evidence (the same Telegram file, the same SHA-256, every part hash) may skip a file. A probable copy
  is held, never skipped. A frame check's "no match" never releases a held file by itself.
- Nothing may make a lane, a download slot, a finish or the copier wait on ffmpeg, the judge or the part store.
  Never slow downloads to spare staging.
- Nothing in the background reads the library folder (it is on a NAS over Wi-Fi).
- Every wait has a bound.
- Logs, tests and reports carry counts, sizes, timings and fixed words only: never a path, a name, an id, a link
  or an error text that may hold one. Constant format strings.
- Nothing in product code depends on this PC's absolute paths, the start folder, PATH or the start scripts.

## How you work
- **Read-only on the branch.** Never commit, push, merge, stash or edit in `wt-copies-18`. For probes make your own
  copy: from `C:\Users\trabi\Claude\Projects\Telegram\repo-archiver` run `git worktree add --detach
  ../wt-copies-review18-scratch <the head>`; write probe tests there (files named `zz_probe_*_test.go`), never
  commit them, and leave the copy as it is at the end (say in the review what is in it).
- Go: `. /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`, then the copy's `archiver`. ffmpeg for
  tests: `FFMPEG_PATH` set to the second line of `where.exe ffmpeg`.
- Run only named tests (`-run`, `-count=1`); never the whole `internal/collector`, `internal/catalog` or
  `internal/supply`; no `go vet` over packages. The race detector only on `internal/parts`, in Docker, if you need
  it for question 3: `bash /c/Users/trabi/Claude/Projects/Telegram/ix-tools/race-archiver.sh <your scratch copy's
  path> ./internal/parts 2 4g 20m` (read the script's header first). Before any run look at the PC: with less
  than 2 GB of memory free or the CPU above 80% over a few seconds, wait a minute and look again, at most 10
  times; then run with `GOMAXPROCS=2`.
- Invented data only. Nothing runs against Telegram. Never open the owner's folders, catalogue or media.
- A finding counts as confirmed only with a probe that fails (or a line-by-line trace you write out); otherwise
  mark it "plausible, not probed".

## The questions (answer each; add your own)

1. **Flags off as today.** List every line the piece changed in `collector.go`, `staging.go`, `account.go` and
   `command.go`, and for each say whether a run with both flags off can reach it and what it does then. Is the
   `supply.Config` literal the same value? The writer's `Kick` closure, the copier's config? Is any folder made,
   any task started, any timer armed? The one intended new call is `ProbeCloseAll` at a start: does it write
   anything, take the writer for long, or delay the start when no check is open; what does its retry do while the
   catalogue fails; can a stop end it? Probe: a digest or a request count of an existing end-to-end case before
   and after, if one exists.
2. **The stop's order in `Run`.** Trace a stop from `<-ctx.Done()` to `closeStore()` with the frame check on:
   which goroutine can still write to the catalogue or the part store at each line? Do the judge's task and the
   kept parts' task return within the store's stop grace, also in the middle of an ffmpeg process, a sweep, a
   `ProbeCloseLeft` chunk? If one does not, what closes under it and what happens (an error, a panic, a hang)?
   Is `Shut` called after the last engine's `Wait` on every path (an account added during the run, an engine
   restarted in `startEngine`, a stop during the start-up before the tasks exist, the early returns of `Run`)?
   Does any early return leak the store, its folder's mark or a goroutine?
3. **`parts.Store.Shut`.** Can a `Put` that began before `Shut` write a row or a file after `Shut` returned 0?
   Is there a window between "is it shut?" and "count me in flight"? Does the new accounting add a lock held
   across disk or ledger work, or contention on `Kept` (a lane's request waits on `Kept`)? `Kept` after `Shut`;
   `Sweep`, `Remove` and the judge's reads after `Shut`; `Shut` twice; `Shut` while a sweep runs. Probe with a
   stress test (many puts against one `Shut`), under the race detector if the PC allows.
4. **`supply.Config.Saved`.** Is it called with a lock of the Supply held? Can the collector's closure block or
   panic a finish? Exactly once per fresh save, never for a duplicate, never twice through a retry or the finish
   log's replay? What does a revived video on the retry path get (the brief says: no call; is that true and is it
   counted somewhere)? With `Saved` nil is every finish as on the base?
5. **`startEngine`.** The part-size condition; the store read under `c.mu`; an engine restarted in the middle of a
   check; two accounts and one store; an account added later. With the frame check on and an engine without a part
   store: can a file be handed out and given back in a loop, and are its requests counted? Can an engine ever fail
   to start because of the frame check?
6. **The frame check's rules, end to end through the collector** (the rig's fake Telegram; a fake runner, and the
   real ffmpeg on invented clips if `FFMPEG_PATH` is set): a "copy" is held with its evidence and is never
   downloaded and never skipped; a file already held by a look-alike rule and judged "no match" is still held; no
   exact edge is ever written by this path; an unrelated video is downloaded with its kept parts taken in place of
   requests (count them); with the judge's ffmpeg missing for the whole run a video is let through only at the
   merged bounds and is counted. A kill in the middle of a fetch and one while a file waits for its judge: after
   the restart no part is fetched twice and no file is lost or stuck.
7. **Do the two tasks make anything wait?** With the judge slow (a runner that takes 60 s a check), the part
   store's disk slow (a hook), ffmpeg absent: do lanes go on downloading other files, does the copier go on, does
   a finish return as fast as on the base? Does the fingerprint worker's `NotYet` ever keep a staged file from the
   copier beyond the copier's own bound (2 minutes)? Does anything the piece starts read the library folder?
8. **The parts folder.** Each refusal of the brief's 3.2: is it right, is anything missing (a folder inside the
   data folder, the same folder for two collectors, a junction or another spelling of the same folder, a relative
   `-parts-dir` and the start folder, a staging folder given relative)? Can the sweep ever remove something the
   store did not write (read `sweep.go`: entries not named as the store names its own are left)? The mark: a
   folder of another catalogue, a folder with parts and no mark.
9. **Words and privacy.** Every new log line, flag help, refusal and report line: constant format, counts and fixed
   words only. Can `parts.Open`'s or `Sweep`'s error text (which may hold a path or a file's number) reach a log,
   a page or an exit message by any route? Are `-parts-dir` and `-ffmpeg` ever printed?
10. **The flags.** Each default against the brief (`-fingerprints` off, `-fingerprint-hwaccel` `auto`,
    `-frame-check` off, `-check-hwaccel` `cpu`, `-check-workers` 2, `-parts-cap-gb` 20, `-card-decoders`
    `cuda,d3d11va`); each refusal; a flag given with its group off (ignored, or refused: which, and is it said?).
    Does any existing flag's meaning or default change? Does `tgarchive-collector run` with today's arguments (the
    launcher's, the watchdog's, the `a3` scripts': read how they call it, do not run them) behave as before?
11. **The tests.** For each named test of the brief's section 4: does it fail when its rule is broken? Break three
    of your choice in your scratch copy and say what happened. Which rule of the brief has no test?
12. **The brief.** Which of its rules is wrong, risky or unbounded in your judgement, whether or not the code
    follows it? In particular: refusing the start when the parts folder cannot be set up; `Shut` instead of a fixed
    10 s; running an engine without a part store at another part size; no kick of the judge from the Supply; the
    retry of `ProbeCloseAll` without a count limit.

## What you hand back
`C:\Users\trabi\Claude\Projects\Telegram\REVIEW-E18-collector-lines.md` (written with the Write tool): the head you
reviewed; per question an answer with the evidence (file and line, or the probe's name and its result); the
findings numbered, each with severity (high: a file can be skipped, lost, stuck for good, or downloads can stall;
medium: a wrong count, a bound passed, a leak, a rule of the owner's bent; low: the rest), confirmed or plausible,
and the smallest fix you would accept; what you did not look at; and one closing line: "may be listed", "may be
listed after these fixes: n, m", or "not yet". Your last message: that closing line and the findings' titles with
their severities, in a few lines.
