# Independent review of K22, alerts: the record and what raises one (Core, K-6, 2026-11-21)

You review `wip/core-alerts` at aa6a5374 against af4ca40e in the private Go project
`C:\Users\trabi\Claude\Projects\Telegram\repo-archiver\archiver`. You did not write it; find what is wrong.
Read first: the design `C:\Users\trabi\Claude\Projects\Telegram\DESIGN-CORE-alerts.md` (sections 1 and 2),
the brief `BRIEF-K22-alerts-record.md` beside it, the coder's report `archiver/docs/progress/core-alerts-REPORT.md`
on the branch (its four "brief against code" choices), then the whole difference. The rules for anything that
acts for the owner: `archiver/docs/TRIED-BEFORE.md` sections 24 and 25 (here: 10, 11, 13).

**Where:** a detached scratch copy: from `C:\Users\trabi\Claude\Projects\Telegram`,
`git -C repo-archiver worktree add --detach ../wt-core-alerts-review aa6a5374`. Never edit the coder's copy
`wt-core-alerts` or any branch; never commit or push. Probes in a folder of yours by `go test -overlay` (or
uncommitted in the scratch copy). **Every go command through the lock:**
`bash /c/Users/trabi/Claude/Projects/Telegram/runs-core-k5/go1.sh <folder> go test -p 1 -run '<names>' -timeout 20m ./internal/<pkg>/`.
Named tests only; no whole-package run of `internal/collector` or `internal/catalog`; no race detector; no
Docker. Invented data only; never touch a running program, `C:\Users\trabi\tgarchive-app` or `E:\`.

**Look hardest at:**
1. **A false "all is well"** (rule 13): any path where a state that needs a person raises nothing or ends an
   open alert wrongly: a failed look, an unreadable threshold, a restart (open rows loaded again?), a state
   passing through "connecting" or "starting" (the coder keeps the earlier "since": is that right in every
   order of states, and can it make an alert fire too early?), an account removed, a mirror want unblocked and
   blocked again, the collector stopping (does it end alerts it can no longer judge? it must not).
2. **The record** (`internal/catalog/alert.go`, `schema_alert.go`): one open row per key under every order of
   raise, end and see; the change number moves on every change a page must see; prune keeps unseen and open
   rows; the doors on a read-only handle and on a catalogue older than the step; the step itself (number in two
   constants, refuses other versions, rollback on failure).
3. **Cost every 30 s** at size: `AlertLook` (an EXISTS over `c_supply` per account, the blocked wants) and the
   touch of open rows: measure on an invented catalogue with 100,000 supply rows and a few accounts (time per
   look; say whether an index serves the EXISTS). Writes: does an idle look write anything (it should not,
   beyond moving last_at if that is what it does: how often, and is that acceptable)?
4. **downloads.stalled**: no alert while the owner paused downloads, under the speed limit while files still
   finish, while only held or retry-later files wait, on a frozen account; and an alert when files truly wait
   and none finishes for the threshold. Where its counts come from and whether a restart resets them wrongly.
5. **Concurrency:** the task against account state changes, the store's reads, the doors called from a page
   while the task writes (data races by reading: say what you would run under the race detector).
6. Privacy: every new log line and stored word fixed, numbers only, no name, text, path or id.

**Report:** `C:\Users\trabi\Claude\Projects\Telegram\REVIEW-K22-alerts.md`: the verdict first ("may be listed",
"may be listed after these fixes: ...", or "not to be listed"), then each finding with must / should / minor,
CONFIRMED (a probe shows it) or PLAUSIBLE, file and line, a one-sentence fix; the probes and their results,
the measured look time. Your last message: the same, short. Then remove your scratch copy
(`git -C repo-archiver worktree remove --force ../wt-core-alerts-review`) after the report is written.
