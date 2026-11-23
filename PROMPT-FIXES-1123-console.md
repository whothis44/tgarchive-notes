# The owner's fixes of 11-23, the fallback run (on the owner's Console credit, through the Agent SDK script)

**The owner is not watching: do it all in ONE go.** Read `CLAUDE.md` and `START-INTEGRATOR.md` first and follow their
rules (privacy, never touch the owner's folder `C:\Users\trabi\tgarchive-app` except as read-only for counts, nothing
against Telegram, commits as written there). Give ONE report at the end.

## What the integrator of 11-23 found (do not search again)
- The "empty archive" and every sign-in try of 11-23 were in the second folder `C:\Users\trabi\tgarchive-app-next`
  (its own empty catalogue), not in the owner's app: nothing was lost.
- Four pieces were built on main `01510923`, each on its own branch (worktrees `wt-fix-*` in the project folder):
  1. `wip/fix-setsearch` (43b8b9c7): a search box on Settings (and the viewer's Library display); the setup wizard
     comes back on a folder box's step (choose.go afterBox sets sv.Step).
  2. `wip/fix-vpn` (14047573): the launcher never takes the VPN's exit as the home address (home.go: kept home
     addresses, learnt only from a request that did not leave through the VPN adapter; otherwise the kept ones,
     or `-public-home unknown`, which refuses); plain words for every VPN refusal (collector/connection.go
     GateWords); the Settings section "Connection to Telegram" (`connection`, GET /api/connection, POST
     /api/connection/check; "Change the VPN adapter…" through the launcher's own change flow).
  3. `wip/fix-signin` (60074c6d, then a fix round): "Send a new code" (auth.resendCode, the owner's click),
     "Cancel the sign-in" (sends nothing), "Start again" at once, the held stop 3 minutes with an always-visible bar.
     Its independent review found one logic error (a cancel could drop a stated wait whose record write failed) and
     four minor points; they went back to the same coder.
- Not yet done by anyone: the bare words "The VPN check refuses (%s): nothing can be typed or sent." in
  `internal/collector/signin_pages.go` and `signin.go` still to be replaced by `c.GateWordsOf(v)` (the VPN piece's
  plain words, with a link to `#/settings?s=connection`).

**State at the integrator's hand-over (11-23 04:02 local):** all four pieces (setsearch, vpn, signin with both
reviews' fixes, and the sign-in's plain VPN words) are MERGED on main `0722ac08` and built into the second folder.
Steps 2 and 3 are done. What is left: Steps 3b and 3c, then Step 4 for them only.

## Step 1: what is already merged
`git -C repo-archiver fetch private`, `git -C repo-archiver log --oneline 01510923..private/claude/charming-feynman-vm2xia`,
and the heading "Fixes of 11-23" in `SESSION-11-PROGRESS.md`. Whatever is merged there is done: skip it.

## Step 2: the sign-in piece, if not merged
Check that the branch's head has the review's five fixes (`git log wip/fix-signin`; the review's points: cancel keeps
or re-saves a stated wait; ResendCode holds beginMu's read side; no resend when Telegram gave no next way; account 0
cancels only during a held stop; resend_after 0 when unknown). Make any missing one (with a faketg test), then ONE
independent Opus review of only the fix (CLAUDE.md: a second pass only of the fix).

## Step 3: the VPN refusal words in the sign-in
On top of the merged or combined tree: replace the bare refusal words in signin_pages.go / signin.go with
`GateWordsOf`, linked to `#/settings?s=connection`. Tests by name.

## Step 3b: the second review's follow-ups (the NAS's sign-in and the stop; not in the merged pieces)
From the second review of the sign-in fix (11-23), each with a faketg test, then ONE independent Opus review:
1. `internal/nasdl/signin.go` ~180-185: the NAS's StepCancel ends a sign-in without saving its stated wait
   (each sign-in keeps its own record in memory, telegram/signin.go ~216): call `RecordWait` first as the PC's
   cancel now does; if the save fails, keep the sign-in and refuse the cancel.
2. `internal/collector/signin.go` closeSignIns (~289, the stop and "Quit now"): save each sign-in's stated wait
   with `RecordWait` before ending it (best effort; log a fixed line when a save fails).
3. `internal/nasdl/signin.go` ~224 and `internal/server/web/assets/js/pages/nas.js` ~246-248: no resend when
   Telegram gave no next way (the PC's `ErrSignInNoNextWay` and its resendView rule).

## Step 3c: a collector test failing on main (found 11-23, before these fixes)
`internal/collector` `TestNASGiveBackRefusedWhileReachable` (nas_fix_test.go ~352: "the give-back during the NAS's
stop: 0 <nil>", ErrNASWorking expected): 3/3 ok at 2c5d21a0, FAIL at a531f8df (NA5), 3/3 ok at 8694e6a9, 5/5 FAIL
at 01510923, all under load. Find whether the code (NA5's moved/lock checks around the NAS's stop and NASGiveBack)
or the test's timing is wrong; fix the one that is, with the test run `-count=10` passing on a quiet PC and under
a whole run.

## Step 4: merge and ship
The pieces not yet merged, as one batch, as `START-INTEGRATOR.md` "Each batch" says: `ix-tools/batch-tree.sh` with
the whole `collector catalog server launcher telegram appshell viewer nasdl` (and `collector/livepages` by path),
named `server:TestAssets|Security` and `viewer:TestWall|TestHomeDevice|Security`; then `ix-tools/merge-batch.sh`;
then `bash runs-int-i6/folder-next.sh`. Three lines under "Fixes of 11-23" in `SESSION-11-PROGRESS.md`, the notes
commit, `bash ix-tools/notes-backup/backup.sh`.

## The report (end with these, exactly)
- What merged (heads), what was left and why.
- "Run only `C:\Users\trabi\tgarchive-app\tgarchive.exe`, never the one in `tgarchive-app-next`."
- "Windscribe's inclusive split tunnelling list holds only `C:\Users\trabi\tgarchive-app\programs\tgarchive-collector.exe`;
  `tgarchive.exe`, `tgarchive-viewer.exe` and `tgarchive-window.exe` must NOT be in it."
- The update, after quitting the app: `powershell -ExecutionPolicy Bypass -File "C:\Users\trabi\tgarchive-app-next\update-folder.ps1" -Into "C:\Users\trabi\tgarchive-app"`
