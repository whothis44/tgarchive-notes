# Independent review of N4, the NAS downloader's PC side (Core's files, lent by N-1; K-6, 2026-11-22)

You review `wip/nas-pcside` at 1348c3db against `wip/nas-program` 59388917 (two commits: 4ad50183 the shared dialer,
1348c3db the place, the doors and the tests) in `C:\Users\trabi\Claude\Projects\Telegram\repo-archiver\archiver`. You
did not write it; find what is wrong. Read: `NOTE-N4-collector-side.md` and `DESIGN-NAS-downloader.md` sections 1 to
3 and `DIGEST-LESSONS.md` in `C:\Users\trabi\Claude\Projects\Telegram`; then the whole difference; `internal/nasctl`
and `internal/nasproto` as far as the difference calls them (they are reviewed already: `REVIEW-N2-link.md`).

**Where:** a detached scratch copy: from `C:\Users\trabi\Claude\Projects\Telegram`,
`git -C repo-archiver worktree add --detach ../wt-nas-pcside-review 1348c3db`. Never edit the coder's copy
`wt-nas-pcside` or a branch; never commit or push. Probes by `go test -overlay` (or uncommitted in the scratch copy).
Every go command through `bash /c/Users/trabi/Claude/Projects/Telegram/runs-core-k5/go1.sh <folder> ...` (busy:
expect waits; 97/98 means try again). Named tests only; never the whole `internal/collector` or `internal/catalog`; no
race detector; no Docker. Invented data only; never touch a running program, `C:\Users\trabi\tgarchive-app`, `E:\` or
the NAS; nothing against Telegram (the fake and the in-process nasdl only).

**House rules it must keep:** every wait Telegram states is slept in full; a file is never downloaded twice at once;
nothing dials a NAS unless the owner set an account's place to it; a sign-in's phone number, code or password is never
logged or stored on the PC; a file is never lost or held for ever without a way back.

**Look hardest at:**
1. **Recover at start** (`collector.go`, `nasHeldAtStart`, `catalog.RecoverActiveExcept`, `supply.RecoverExcept`):
   the NAS's state file unreadable, corrupt, missing, or of another catalogue or NAS; the account's place switched
   back to "the PC" since; the NAS gone for good: is every file the state file names given back at some point, and
   never handed out twice while the NAS may still write it? What happens to the PC's own active files when the state
   file cannot be read (fail closed, but not stuck for ever)? The walk past kept files in chunks.
2. **The place switch** (`account.go`, `nas_place.go`): local engine and NAS link never both working for one account,
   at the switch in either direction mid-run; an unreadable place builds no lane (and is said); `-no-downloads`.
3. **Finished and Duplicate through the NAS** (`nasFinished`, `nasDuplicate`): a finish recorded once; a NAS's finish
   for a file the PC also has active; the catalogue's exact rules unchanged (only the same file or the same SHA-256
   ends a file).
4. **The doors** (`nas_doors.go`): `NASSignIn(ctx, acct, step, phone, value)` and `NASForgetLogin` write to
   Telegram through the NAS: one request per click, the phone and the code never logged, stored or answered back;
   sign-in refused without pairing and without the place; `NASStatus` with the NAS away; `SetNASPlace` rules.
5. **The shared dialer** (`collector/libclient`, `faketg/remote.go`): the one-client-per-session-file hold unchanged
   in behaviour (the collector's existing dialer tests); nothing of the dial path weakened.
6. **Waits and status:** the NAS task's pace (`NASEvery`, the redial doubling to `NASRetryMax`): no tight loop when
   the NAS refuses or is away; the PC never asks Telegram on the NAS's behalf.
7. Changes in copies' files (`catalog/state.go`, `supply/supply.go`): with keep empty, exactly the old behaviour.

**Report:** `C:\Users\trabi\Claude\Projects\Telegram\REVIEW-N4-pcside.md`: verdict first ("may be listed", "may be
listed after these fixes: ...", or "not to be listed"), then each finding with must / should / minor, CONFIRMED (a probe
shows it) or PLAUSIBLE, file and line, a one-sentence fix; the probes and their results. Your last message: the same,
short. Then remove your scratch copy (`git -C repo-archiver worktree remove --force ../wt-nas-pcside-review`).
