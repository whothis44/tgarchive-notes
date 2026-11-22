# Brief: the independent review of K17 (a file given back from a transfer is judged as the settle would judge it now) (Core, K-5, 2026-11-16)

You are the independent reviewer of this piece: Opus, read-only on the branch, with probes. You did not write
it and you are not asked to like it. The coder's report is a claim, not evidence.

**Rules of the house:** invented data only; nothing of a name, text, path or id in any output or in your
report (numbers and code names only). Never touch a running program, the main copy `repo-archiver`, the
coder's copy `wt-core-giveback`, or anything under `E:\`. No push, no commit to any branch, no `git stash`.
**Every `go`, `gofmt` or `vet` command goes through the track's lock script** (one go command at a time for
the whole track; it waits for memory itself and sets the environment):
`bash /c/Users/trabi/Claude/Projects/Telegram/runs-core-k5/go1.sh <folder to run in> go test -run '<names>' -timeout 15m ./internal/catalog/`
Named tests only (`-run`); the whole `internal/catalog` (9 minutes) is not yours to run; no race detector.

**Where:** make a scratch copy yourself, one command, from the project folder:
`git -C repo-archiver worktree add --detach ../wt-core-giveback-review-scratch bd195424`. Probes are test
files named `zz_probe_k17_*_test.go` in that copy's `archiver/internal/catalog` (they stay there, uncommitted).
For "how was it before": `git -C repo-archiver worktree add --detach ../wt-core-giveback-review-base 78739d59`
(the main head the piece was cut from); b3c64668 is the coder's tests before the fix.

## Read first

1. `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-K17-give-back-judged.md` (what was asked, and why).
2. On the branch: `archiver/docs/progress/core-giveback-REPORT.md`, then the diff
   `git diff 78739d59 bd195424 -- archiver/internal/catalog/state.go archiver/internal/catalog/settle.go archiver/internal/catalog/ladder.go`.
3. The settle's own statements the piece calls and must not have changed: `chosen.go` (`chatHoldSQL`,
   `judgeChat`), `topics.go` (`collectedSQL`, `topicHoldSQL`), `ladder.go` (`roleChanged`, `wantedAsMain`).

## What the piece is for

Download only what the owner chose. The settle of a switch and an edit's role rule leave a file in transfer
alone; before this piece a file given back unsaved could come back wanted (or stay supplied as a probable
copy) although its chat was switched off, its topic un-chosen, or it was left only an alternative version:
at a restart after a kill, always. The rule built: a file that leaves "in transfer" or "set aside" unsaved
ends, in the same transaction, where the settle or the role rule would have put it had it been waiting.

## Questions, in this order (answer each; a probe where one can decide it)

1. **Nothing changes where nothing is to hold.** For files that a chat carrying them collects (the common
   case), is every row after `Release`, after `Aside` and the requeue, after `RecoverActive`, and after an
   account's removal equal on bd195424 and on 78739d59: `state`, `reason`, `probable`, `check_first`,
   `retry_at`, `attempts`, `asides`, `claimed_by`, `keep_held`, `released`, `fetch_real`, and the file's
   `c_supply` rows? Decide it by a differential probe over random worlds (the same seed built on both
   copies, the rows printed as counts or compared by a digest), not by reading. Include probable copies, a
   file marked `check_first`, a set-aside with each reason the engine and the owner's hand write, a file in
   several chats, a chat that collects only chosen topics.
2. **The twin rule.** Over random worlds (chats on and off, kinds, "only chosen topics" and topics chosen
   or not, several carriers, roles, replaced attachments, every flag on the want row), for each switch or
   edit made while one of two like files is in transfer and the other waits: after each of the four doors,
   do the two rows and their supply rows agree? List EVERY class of disagreement you find. The coder
   declares three (its report, "where the code contradicts the brief": the role rule spares a released, a
   `fetch_real` and a sent-back file; an alternative-only file is held at a give-back whatever made it so;
   `Aside` overwrites the reason, so an owner's send-back that the engine then sets aside, and a kept-held
   copy's reason, are as on the head). Is each of the three as described, and is there a fourth?
3. **Can the role column hold what the rules want downloaded?** Find, through the catalogue's own doors
   only (no direct SQL), every way a file carried only as an alternative version comes to be wanted and
   claimed without the owner's hand (released, `fetch_real`, a send-back): an edit that replaces the main
   attachment, a deleted message, "always download", a chat's settle, the exact check's or the frame
   check's doors, the owner's word on a pair. For each that exists: at a stop, the piece now holds that
   file as an alternative, and the next claim never comes. Say which exist (with the probe) and which
   cannot occur. One that exists is a must-fix.
4. **The requeue's reason.** `asideBackSQL` keeps the reason when the file is to be judged and
   `asideClearSQL` clears it after. Every combination of the set-aside's reason, `probable`, the three
   exemptions and "which hold applies": is the reason at the end what the head wrote for a file that is not
   held, and what the settle writes for one that is? A row left `wanted` with a stale reason, or `held`
   with an empty one, is a finding.
5. **`RecoverActive`.** A context that ends between two chunks; an error in the middle of a chunk; a Batch
   handle; 0 active rows (one read, no write: does any caller rely on the old write or its count:
   `internal/supply` `Recover`, `cmd/tgarchive/app.go`); 1 row; exactly `recoverChunk` rows; many rows all
   judged. Is the longest write within the settle's own bound on this PC by your own measure? Can the loop
   fail to end?
6. **The statement cache.** `prepareGiveBack` prepares on the plain handle before a run of chunks. Its
   interplay with `Batch`'s pending statements and K16's rollback (`catalog.go`), a statement that cannot be
   prepared, a read-only handle, a closed catalogue.
7. **The removed account's claims** (`settle.go`): judged after or before its chats' rows go, and is the
   result right when another account still reaches the file, and when none does?
8. **The claim path is untouched.** By the diff, and by one timing of `ClaimNext` at size on both copies
   (the existing at-size or benchmark tests: say which), three runs each.
9. **Triggers and the change log.** A held file is now written twice in one transaction (wanted, then
   held). Its `c_supply` rows after it; the change log's rows for it (how many, which kinds); anything that
   counts rows changed. The copies track plans triggers `AFTER UPDATE OF state` on `c_want` for a new table:
   say what such a trigger would see at each door.
10. **The tests.** Run three of the new tests by name on b3c64668 (they must fail) and on bd195424 (pass).
    Does any new test pass for the wrong reason (a twin compared with itself, a row set by direct SQL where
    a door exists, a time bound that is skipped)? Is anything the brief asked for not tested?
11. **`Release`'s cost** by your own measure at 100,000 want rows on both copies, three runs each, said as
    means with their spread; and the same for a file that IS held (the new path: how many statements, how
    long).

## Your report

`C:\Users\trabi\Claude\Projects\Telegram\REVIEW-K17-giveback.md` (write it with your file tool), and your last
message the same, short: an answer per question; the findings numbered, each with its severity (must fix,
should fix, minor), the probe that shows it (file and test name) and the smallest fix; what you did not look
at; and one last line, exactly one of: "may be listed", "may be listed after these fixes: <numbers>", "not
yet: <why>". Then stop.
