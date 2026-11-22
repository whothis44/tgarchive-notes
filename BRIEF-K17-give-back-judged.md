# Brief K17: a file that comes back from a transfer is judged as the settle would judge it now (Core, K-5, 2026-11-16)

**Rules of the house (the project folder's `CLAUDE.md`, the archiver section; the owner's first rule: routine
steps never call by call in a costly context, so keep your own steps few and exact):** you are the Opus coder
of this piece and hand back commit-ready work. Named tests only while you work (`-run`, this one package; the
whole `internal/catalog` takes 9 minutes and is not yours to run); no race detector; no `go vet` over many
packages. Invented data only; nothing of a name, text, path or id in any log line, error or commit message.
Never touch a running program, the main copy `repo-archiver` (the integrator's merge run is in it) or anything
under `E:\`. Before every `go` command: `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`,
prefix `GOGC=25 GOMAXPROCS=2` (`-p 1`), and read free memory first (`powershell -NoProfile -Command
"[int]((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1024)"`; under 2000: wait 2 minutes and
measure again; after 20 minutes of waiting in all, run and say so in the report). One go command at a time:
other tracks' coders work on this PC.

**Where:** make the copy yourself, one command, from the project folder:
`git -C repo-archiver worktree add ../wt-core-giveback -b wip/core-giveback 78739d59` (it writes nothing in the
main copy's files). Work only in `C:\Users\trabi\Claude\Projects\Telegram\wt-core-giveback`. Commit with
`git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, the message ending
`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; push only `wip/core-giveback` to `private`, and
push work in progress as you go. No `git stash`, no rebase.

## What the old app already knows

The old app (`wt-v12.32\core-service\internal\app\recovery_api.go`, the groups' "disable" and "delete"): the
moment a chat is switched off, every work row of that chat that is pending, IN TRANSFER ("processing") or
failed is marked skipped in the same transaction as the switch. Its later "stop an app-added chat"
(`ix_appadded.go`, `ixDropQueued`) takes pending and failed rows and lets a transfer under way finish. In both,
**nothing of a switched-off chat is ever back in the queue after the switch, restart or not.** The lessons'
rule for every source (TRIED-BEFORE sections 24 to 26; `LESSONS-ix12.30-live.md`): download only what the
owner chose. The new app holds instead of skipping (the same file may be carried by a chat that does collect
it), and by design lets a transfer under way finish (K1's brief; `chatHoldSQL`'s comment: "never a file in
transfer"). That design stays.

## What is wrong (read on the main head 78739d59 by the Core session; asked by the copies track, board message 113 b)

The settle of a switch (`internal/catalog/chosen.go` `judgeChat`: `topicHoldSQL`, `chatHoldSQL`) and an edit's
role change (`ladder.go` `roleChanged`) leave a file in transfer alone. What happens when that transfer does
not finish and the file is given back:

1. **A restart after a kill or a crash: `RecoverActive` (`state.go`, called by the Supply's `Recover` and by
   `cmd/tgarchive/app.go`) and the account removal's give-back (`settle.go`, the first statement of the
   list near line 491) write `backToSQL` with no look at the chats:** the file is wanted again (a probable
   copy held and still supplied), gets its supply rows and is downloaded, although its chat is switched off.
   Nothing holds it afterwards: the switch's intent is finished, and `SettleChats` at the start applies only
   stored intents. The clean stop is covered since K1b (review C3: `Release` and the requeue read
   `noneCollectsSQL` first), the restart is not.
2. **A probable copy (`probable = 1`) in transfer:** `releaseSQL` and `asideBackSQL` write it back held with
   `probable = 1`, so it stays supplied; the settle's second statement (`probable = 0`: "a probable copy is no
   longer supplied") never reaches it. With "a held copy waits" off it can be claimed when its server has no
   unique file.
3. **The topic rule:** `noneCollectsSQL` is `kindCollectedSQL`, "the topic rule aside". A file in transfer
   when its topic is un-chosen (or its chat set to "only chosen topics") comes back wanted; `topicHoldSQL`
   would have held it (reason `ReasonTopicPref`).
4. **The role change:** a file in transfer when an edit leaves it only an alternative version in every
   message comes back wanted (`mainCarriedSQL` is then false and "a file no message carries as its own media
   is left as it was"); `roleChanged` would have held it (`ReasonAlternative`, not probable).

Each is bounded by the handful of files in transfer at the moment of the switch or edit, and each downloads
bytes from a source the owner did not choose, or bytes the rules hold. Show each by a probe test FIRST (seen
failing on 78739d59), before you change anything; if one of the four does not fail as I say, stop on that
point and say what you found instead: my reading of the SQL is not a run.

## What to build

**The rule, one sentence:** a file that leaves "in transfer" or "set aside" without being saved (`Release`,
the requeue of a set-aside whose time has come, `RecoverActive`, the removed account's claims) ends, in that
same transaction, in exactly the state the settle or the role rule would have written had the file been
waiting (wanted, or held) when the switch or the edit happened.

- **One source of truth.** Do not write the settle's conditions a second time. After the plain give-back,
  apply the settle's own statements to that one file (`topicHoldSQL`, `chatHoldSQL` with the set `= ?1`, the
  hold statement of `roleChanged` made callable by itself), or prove another form equal by the twin test
  below. Every exemption stays exactly as each of those statements has it today (the owner's hand
  `ReasonOwner`, `fetch_real`, `released`, `keep_held`): a released file comes back wanted, as K1c's tests
  say. `topics.go`'s statements are the pages track's: use them, do not change them.
- **The common case stays one read.** `Release` today costs one indexed read (`noneCollectsSQL`) before its
  update; K1b measured it. Keep that shape: one read that says whether any of the three holds can apply to
  this file (not collected by any carrier under the full rule, kinds and topics; or carried only as an
  alternative version), and the further statements only when it says yes. Measure `Release` and the requeue
  of one set-aside before and after on a catalogue of at least 100,000 want rows (the existing at-size tests
  show how) and put both numbers in the report. The claim path (`Claim`, `ClaimNext`, their statements) is
  not touched: say so in the report with the diff's file list.
- **`RecoverActive`:** the active rows are read first (their ids), given back, and judged in the same
  transaction, in chunks if there are many (say the bound you chose and why; after a crash the count is the
  number of transfers that were under way). Its count returned stays "files given back". A catalogue with no
  active row does no more than one read more than today.
- **The removed account's claims** (`settle.go`): the same judgement for the files it gives back.
- **Do not touch:** `lane.go`; the settle's own statements and guards; `exactcheck.go`, `probe.go`,
  `pairword.go`, `vfp.go` (the copies track's); anything in `internal/supply`, `internal/engine`,
  `internal/collector`; no schema step; no new setting; no new log line. `MemSupply.RecoverActive` (the
  engine's test supply) has no chats and stays.
- **List for the copies track, do not fix:** every other statement in `internal/catalog` that moves a row
  out of `active` or `aside` back to `wanted` or `held` (I saw `exactcheck.go` near 392, 718, 793, 822, 834,
  845, 911; `probe.go` near 607, 625; `pairword.go` near 675, 1024): file, function, and one line each on
  whether the same hole is there (a row written wanted or supplied with no look at its chats) or why not.

## Tests (each new one seen FAILING on 78739d59 first; say so per test in the report)

1. **The twin test, for each of the four cases and each give-back door** (`Release`; `Aside` then the
   requeue; `RecoverActive`; the account's removal where another account still reaches the file): two files
   alike in everything, one waiting and one in transfer when the switch (chat off; kind off; topic un-chosen;
   the chat set to chosen topics only) or the edit (left only an alternative) happens. After the give-back
   the two `c_want` rows are equal in `state`, `reason`, `probable`, `check_first`, `retry_at`, and the two
   have the same supply rows (none). For a plain file and for a probable copy.
2. The exemptions, per door: an owner's set-aside or send-back, `fetch_real`, `released`, `keep_held` end as
   the settle would leave the waiting twin (for `released`: wanted).
3. A file carried also by a chat that collects it: comes back wanted (or held as the probable copy it is,
   still supplied), by every door.
4. The switch back on afterwards: the chat's settle makes the given-back file wanted again (or supplied
   again), exactly as its waiting twin.
5. `RecoverActive` with many active rows across chats on and off (at least 2,000): every row right, the
   longest write bounded (state the bound; the settle's chunk tests show how to judge by rows as well as by
   time).
6. Every existing test of `Release`, the requeue, `RecoverActive`, the settle, the baseline and the topics
   by name still passes unchanged (`TestChooseChat|TestChatSettle|TestBaseline|TestRelease|TestRequeue|
   TestRecover|TestTopic|TestRole|TestWantAgain|TestSettle` and whatever else names them: list what you ran).
   No test function removed or weakened; if one pins the old behaviour of the four cases, say which and why
   it changes.

`gofmt -l`, `go build ./...`, `go vet ./internal/catalog`.

## Hand back

`archiver/docs/progress/core-giveback-REPORT.md` (committed) and your last message, the same content, short:
the head and that it is pushed; the four probes' results on 78739d59 before the fix; what changed (file,
function, statement); the two timings before and after; the list for the copies track; the tests as run with
their results; what you could not test; anything in this brief that the code contradicts. Then stop: the
review and the full runs are the Core session's.
