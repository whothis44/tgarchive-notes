# Brief: the viewer's read timing under write load regressed on ui-all (UI track, session U-1, 11-22) — FIRST

You are an Opus coder for the UI track of a private Go project (a Telegram archiver; the viewer, `internal/viewer`, serves
the library read-only from a SQLite catalogue while the collector writes). Work ONLY in the copy
`C:\Users\trabi\Claude\Projects\Telegram\wt-ui-f6` on its branch `wip/ui-all` (head 3192de6f; nobody else works there
now). Commit with `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, each message ending with
`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; push only `git push private wip/ui-all`.

## Rules (binding)
Invented data only; never open or touch the owner's folders or programs; Go through
`source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`, ONE go command at a time (the PC also runs other
sessions' tests: timing tests are sensitive to load, so check the CPU is quiet before a timing run, e.g. with
`Get-Counter '\Processor(_Total)\% Processor Time'`, and say what it was); named tests only; no whole-package runs except
as said below; nothing against Telegram. For bisecting use `git worktree add --detach <a scratch dir outside the project
folder> <commit>` copies of your own and remove them afterwards; never switch the branch of another worktree.

## The failure (the integrator, 11-22)
`internal/viewer` `TestTimingUnderWriteLoad` fails 2 of 2 by name on the combined tree (main e34f4f64 + ui-all 3192de6f +
other branches) and passes on main e34f4f64 alone. The assertion at `timing_test.go:478` (target: a post's 95th < 30 ms, 99th
< 100 ms): combined: a post 95th 40.3 ms, 99th 100.7 ms, library first page worst 339.8 ms; main: a post 95th 14.7 ms, 99th
46.3 ms. ui-all holds, among others: the viewer track's U2 (old-or-new fields per file on tiles and posts, `shellcounts.go`'s
background counts build), F4/F4b (tiles carry `chat_id`, `post_files`; hiding), F2 (`shellmount.go`, `server.go`), F1
(appshell's list read), F8 (titles), F5 (chat JS only), S1 (the pages' read of the viewer's counts).

## The task
1. Reproduce: run `go test ./internal/viewer -run '^TestTimingUnderWriteLoad$' -count=1 -v` on 3192de6f and on e34f4f64
   (twice each, CPU quiet), note the numbers.
2. Bisect over ui-all's first-parent merges and its pieces' commits that touch `internal/viewer` Go or `internal/appshell`
   Go (`git log --first-parent e34f4f64..3192de6f`, then inside the culprit merge) to the commit that moves the numbers.
3. Find the cause in the code (a per-post or per-tile query added on the read path, a lock or long read transaction held by
   a background build under write load, the list's read running on every request, ...) and fix it so the read path does no
   new work per request: precompute in the index, read in the background off the request path, or batch. Keep every
   feature's behaviour and its tests. If the cause is in the viewer track's U2 code, tell U-1 the exact place before fixing
   (U-1 asks B9 to read the diff).
4. Verify: `TestTimingUnderWriteLoad` by name 3 times on the fixed tree (CPU quiet), all within target, with the numbers; the
   viewer's named sets `-run 'TestShell|TestLibraryF4|TestOldNew|TestChatConv|TestTiming'`; gofmt, vet.

## Report (under 20 lines)
The culprit commit and the cause in one line each, the fix, the numbers before/after (3 runs), the tests, the new head of
`wip/ui-all` (pushed).
