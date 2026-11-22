# Brief: the independent review of RN, renaming a mirror from the running app (pages, P7, 2026-11-22)

Read first: `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-P7-review-rules.md` (binding). TEMP, TMP, LOCALAPPDATA,
APPDATA of test processes in `C:\Users\trabi\AppData\Local\Temp\p7-rnrev\` (outside any git copy). Fakes only:
nothing reaches Telegram.

**The piece:** `wip/pages-rename` 36e82316 (from the mirror track's `wip/mirror-renamedoor` 6e610344, M19):
`git diff 6e610344 36e82316`. The ask: `BRIEF-RN-mirror-rename.md`; the coder's report
`archiver/docs/progress/pages-rename-REPORT.md`; the doors: `internal/collector/mirror_rename_door.go`. **It sends one
request to Telegram for the owner (channels.editTitle). Find any way a rename is sent without the owner's click on a
plan the owner saw (a request from elsewhere, a replayed or forged token, a token surviving a changed plan or a
restart, a GET that sends), any end said untruly, any title or current name logged or leaked (the title sits in the
plan's query string: weigh it), and any wait not slept or said.** Your copy:
`git -C C:\Users\trabi\Claude\Projects\Telegram\repo-archiver worktree add --detach ../wt-pages-review-rn-scratch 36e82316`.
Report to `C:\Users\trabi\Claude\Projects\Telegram\REVIEW-RN-mirror-rename.md`. Within about an hour.

## Questions
1. The token: what it binds (the plan's facts and the title), its key's life, a replay after the rename, a token from
   another account or chat, a token after the mirror's state changed; refused cases send nothing (count the fake's calls).
2. The guard: the POST under the same guard, held-stop and route lists as the other mirror change routes; the plan GET
   sends nothing.
3. Every End and refusal mapped to true fixed words (against M19's list and words.go); a stated wait never slept by
   the page and said with its end time; "unknown" said safe to run again.
4. The title and current name: never in a log line, an error word, a URL the server logs, or an answer other than
   the plan's own fields; the limit (128 UTF-16 units) and blank titles refused before the door.
5. Anything else: its own number.
