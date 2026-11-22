# Independent review of K18, the small asks (Core, K-6, 2026-11-21)

You review `wip/core-asks` at 7528e205 against its base 0942a7dc (K21's branch, listed, not merged) in the
private Go project `C:\Users\trabi\Claude\Projects\Telegram\repo-archiver\archiver`. You did not write it; find
what is wrong. The brief it was built from: `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-K18-small-asks.md`;
the coder's report: `archiver/docs/progress/core-asks-REPORT.md` on the branch (two rounds). Read both, then
the whole difference (`git diff 0942a7dc 7528e205`).

**Where:** make a scratch copy yourself, detached: from `C:\Users\trabi\Claude\Projects\Telegram`,
`git -C repo-archiver worktree add --detach ../wt-core-asks-review 7528e205`. Never edit the coder's copy
`wt-core-asks` or any branch; never commit or push. Prove findings with probe tests written in a folder of
yours and loaded with `go test -overlay` (or in the scratch copy, uncommitted). **Every go command through the
lock:** `bash /c/Users/trabi/Claude/Projects/Telegram/runs-core-k5/go1.sh <folder> go test -p 1 -run '<names>' -timeout 20m ./internal/<pkg>/`.
Named tests only; no whole-package run of `internal/collector` or `internal/catalog`; no race detector; no
Docker. Invented data only; never touch a running program, `C:\Users\trabi\tgarchive-app` or `E:\`.

**Look hardest at:**
1. `deleteAccountChunk` (`internal/catalog/settle.go`, `collectorkeys.go`): does it delete exactly the
   deleted account's rows and nothing of another account (1 against 10, 11, 100; keys that only begin with
   the same digits; chat-numbered keys)? Is any per-account key still missed (grep every `SetSetting` and key
   builder in the tree, mirror and copies included)? Is anything deleted that must outlive the account? Does a
   later account given the same number start clean (signed in, method frozen, owner stop, download pause, the
   mirror's pause and baseline)? Does a delete interrupted between chunks leave a state a restart mishandles?
2. The store's `Copier.Load` (`internal/store/copier.go`, `guard.go`): is the in-memory "wanted again held"
   state right at every change of the record, including a failed read after a good one, a release, and
   before the first read? Can `Load` block on anything the copier holds for long? Data races by reading
   (no race run: say what you would run).
3. The reader's held / ended judgement (`internal/collector/reader.go` `endedKindOf`, `approve_cmd.go`):
   does it match how the automatic mirror writes and clears a hold (`mirror_auto.go` `autoReads`)? Do the
   extra catalogue reads at a skip stay bounded (once a chat, then at most hourly), and does a failed read
   never change what is read or skipped?
4. The watchdog's folder to its child (`internal/watchdog/childenv.go`, `exec.go`,
   `cmd/tgarchive-watchdog`): one value in the child's environment, the inherited one dropped (case on
   Windows), an absolute path; the collector's `WatchdogDir` with unset, empty and relative values.
5. Anything that changes behaviour beyond the six asks, or a privacy slip (a log line with a name, path or id).

**Report:** `C:\Users\trabi\Claude\Projects\Telegram\REVIEW-K18-asks.md`: a verdict first ("may be listed",
"may be listed after these fixes: ...", or "not to be listed"), then each finding with must / should / minor,
CONFIRMED (a probe shows it) or PLAUSIBLE, the file and line, and a fix in one sentence; the probes you ran
and their results. Your last message: the same, short. Then remove your scratch copy
(`git -C repo-archiver worktree remove --force ../wt-core-asks-review`) only after the report is written,
keeping your probe files in your report's folder if they matter.
