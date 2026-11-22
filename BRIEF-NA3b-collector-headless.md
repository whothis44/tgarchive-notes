# Brief NA3b: four small collector pieces for the headless NAS (NAS track, N-1, 2026-11-22; LENT to Core)

**Why:** the app is to run headless on the NAS (`C:\Users\trabi\Claude\Projects\Telegram\DESIGN-NAS-autonomous.md`).
NA3 (`deploy/nas-app`, merged) found what the collector lacks; Core asked for one refusal. **Core's package: a LENT
commit (messages beginning "Lent to Core (collector):"), Core reads it, then one independent review** (point 1 decides
who may sign in). **Rules:** you are the Opus coder. Named tests only in `internal/collector`; small packages whole.
Invented data only; numbers and fixed words in logs. Nothing against Telegram (fakes only), nothing on the NAS, never
the owner's running app or folders. Every go command through
`bash /c/Users/trabi/Claude/Projects/Telegram/runs-nas-n1/go1.sh <folder> go test -p 1 -run '<names>' -timeout 20m <pkgs>`.
**Where:** `git -C C:/Users/trabi/Claude/Projects/Telegram/repo-archiver worktree add ../wt-nas-headless -b wip/nas-headless private/claude/charming-feynman-vm2xia`
(head a0de4f1); commit with `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, ending
`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; push only `wip/nas-headless` to `private`.

## What to build
1. **The old archive's account never gets a NAS place or a NAS sign-in:** every NAS door of the collector
   (`internal/collector/nas_doors.go`: NASPlace, SetNASPlace, NASPair, NASStatus, NASSignIn, NASForgetLogin, NASGiveBack,
   NASHeld) refuses an account with `account.brought_in = 1` in the catalogue, with pages' fixed words "This is the old
   archive: it is never signed in." (a typed error the pages can map). Read-only doors (NASStatus, NASHeld) answer the
   refusal too, so no page offers anything for it. Test each door.
2. **A health check without a shell:** `tgarchive-collector check -status-file F -max-age D` exits 0 when the collector's
   status file was rewritten within D (default 3m), 1 otherwise, printing fixed words only; opens no network connection.
   Test it. (The compose file of `deploy/nas-app` uses it later; do not edit deploy files.)
3. **`-staging` optional:** with no staging folder the collector writes straight into the library (the writer already has
   that mode, `store.Writer` with no staging: find how it is chosen) and says so at start; with it, as today. Test a run
   on the fake with and without.
4. **`TestNASSwitchPlaces`'s wait** (failed twice under heavy load in a whole run: `rig_test.go:507` "unsaved reachable by
   1: 0, by 2: 0", a 60 s bound): make the wait follow the test's own clock or a bound that load cannot exceed; never
   weaken what it checks. Run it 5 times.

## Hand back
Ready for Core's read on `wip/nas-headless`, pushed. Report in at most 15 lines: commits, Core's files touched, each
point's test, then stop.
