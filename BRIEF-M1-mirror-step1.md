# Brief M1: the `mirror` command, the first real step of mirror groups (2026-11-14)

Copy: `C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-step1` (branch `wip/mirror-step1`, cut from 8c0335e).
Work only there, in `archiver/`. Commit-ready work on that branch; do not push, merge, or touch any other copy.
**Nothing is run against Telegram**: tests use the fake only. This code will write to a real Telegram account
(creating a chat, forwarding messages), so a wrong repeat is the worst defect it can have.

Read first, in the copy: `archiver/internal/telegram/forward.go` (whole), `call.go` (`once`, `held`, `takeWait`),
`memo.go` (the header of `MemoStore`), `counters.go` (`KindStats`, `ForwardStats`), `timing.go`; the collector's
`command.go`, `signin_cmd.go` and `signin.go` (how a command that is not `run` takes the catalogue's lock, checks
the VPN gate, dials one account and writes its counts), `approve_cmd.go` (the "show the cost, ask for yes"
dialogue and how it reads the console beside a stop), `chats_cmd.go`; `internal/collector/faketg`;
`internal/catalog/schema12.go` (how a schema step is written and tested), `tgchats.go` (`SetMirrorOf`),
`imported.go:223` (the switch-off of a chat). And the owner's page: `C:\Users\trabi\Claude\Projects\Telegram\DESIGN-MIRROR-STEP1.md`
(what the owner was told the command does: the code must do exactly that).

## What exists and must be used, not rewritten
`telegram.Forwarder`: `ForwardLimits`, `CreateMirror`, `PlanBatches`, `ForwardBatch`. It sends each writing
request exactly once, records every stated wait in the `MemoStore` before sleeping it in full, checks a recorded
wait before every request (also after a restart), counts per method, derives stable random ids from
`ForwardConfig.Secret`, and remembers `USER_RESTRICTED`/`PEER_FLOOD` (account, for good) and
`CHAT_FORWARDS_RESTRICTED` (source chat). Do not change its behaviour. If you find a defect in it, stop and
report it rather than working around it. `CreateTopic` is not used in this step.

## What the old app has for this, and what is taken (added 11-14 23:15; the owner: its code is ours to take)
Read by the architect: `wt-v12.31/core-service/internal/telegram/floodguard.go` and `forward.go`, whole.
- **Waits (`floodguard.go` `invokeGate`, the branch for requests that are not file parts):** a `FLOOD_WAIT`
  closes the account's gate for the seconds asked plus 1 s; up to 60 s it is slept and the same request sent
  again, at most 3 times; a longer one goes back to the caller. It is kept in memory only: the old app's own
  review named that as a defect ("persist Telegram's waits"). The new app's `call.go` and `memo.go` already do
  the same with the same 1 s margin, and store the wait before sleeping it. **Nothing to port: the new code is
  the old rule plus the fix the old app's review asked for.** This command is stricter on a write (the batch
  once more after a slept wait, not three times), because a forward has never met the real Telegram.
- **Creating a channel (`forward.go` `storageChannel`):** it first looks for a channel of the wanted title in
  the chat list and creates one only when none is there, with `channels.createChannel`, broadcast, taking the
  channel and its access hash from the answer's chats. `CreateMirror` already reads the answer the same way.
  **The look-before-create is the part worth taking, and it is not in this step:** it is how a "create outcome
  unknown" is to be settled later (find a channel of the mirror's name in the stored chat list; adopt it; never
  create a second). In this step an unknown outcome stops and waits to be looked at. Do not build the adoption
  now; do keep the mirror's intended name recoverable from the ledger (base name and ordinal) so that it can be.
- **Not taken:** `SendFile` (the old app's "auto-forward" uploads every file again, so that protected chats
  work: every byte a second time, a new Telegram file id) and its random ids from `crypto/rand` (a repeat
  would make a second copy; the new forwarder's ids are derived, so a repeat is refused).

## What to build
### 1. Schema step 13: the mirror ledger (`internal/catalog/schema13.go`, with its test)
The number 13 is taken on the board for this. One row per item, never a stored list. Your design, with these
properties:
- **A mirror row** per (account, source chat, ordinal): its name's ordinal ("-1", "-2"), the mirror's chat row
  once known, a state, times. States at least: *creating* (written before `channels.createChannel` is sent),
  *created*, *create outcome unknown*, *source protected*.
- **A batch row** per forward request: state *sending* (written before the request), *done*, *outcome unknown*,
  *waited* (Telegram stated a wait; nothing was forwarded), *refused*; counts; times.
- **A forward row** per source message of a batch (key: mirror, source message id): its state (*sent*,
  *forwarded* with the mirror's message id, *missing*), its batch.
- Catalogue methods for: the open mirror of a source chat; begin/finish create; begin/finish batch with the
  per-message results in one transaction; the next candidates of a source chat (below).
- A value in the ledger that cannot be read (an unknown state word, a broken row) is an error, never "empty"
  (fail closed).
- Do not touch the catalogue's hold tables, the ladder, `staging.go`, `settle.go` (another session's).

**Candidates:** a query that returns the source chat's messages on record, oldest first (by message id), each
with its album id, that are not in the ledger for this mirror, not known deleted, and not carrying media left
out for a self-destruct timer (find how the catalogue records both; if either is not determinable from the
catalogue, say so in the report and leave that filter out rather than guess). It must use an index (test it
with `EXPLAIN QUERY PLAN` on a table of 300,000 invented messages: no full scan of `message`). Read enough rows
that the first batch `PlanBatches` cuts is whole: an album cut by the query's limit must not go out split.

### 2. Package `internal/mirror`: the step's logic, no flag parsing, no printing
Against small interfaces (the forwarder's four calls, the ledger, a clock), so it is tested without a
connection. One exported entry point each for:
- **Plan** (sends nothing, writes nothing): for an account and a source chat: is the chat one of the account's
  chats; its kind (a forum is refused in this step: "topics come later"; a chat that is itself one of the app's
  mirrors is refused); messages on record and candidates; the size of the first batch (with the maximum taken
  as 100 for the plan only, said as "at most"; the real maximum comes from `ForwardLimits` at the step);
  whether a mirror exists and its state; channels and supergroups of the account on record against 500 (count
  the account's chats of kind supergroup, channel and forum the account is a member of, plus the app's mirrors
  not yet in the chat list; say the time of the stored chat list); whether the account's forwarder is refused
  for good or the source is known protected; stated waits still running for the kinds "config", "create
  mirror", "forward" (read from the wait record) and their ends; the requests the step would send.
  A plan that would send nothing useful says why in fixed words (no candidates, mirror in an unknown state,
  account refused, source protected, at 500).
- **Step** (the owner said yes): in this order, stopping at the first thing that is not a clean success:
  1. read the ledger again (a state changed since the plan refuses the step);
  2. `ForwardLimits` (one request);
  3. if no mirror exists: write the mirror row *creating*, then `CreateMirror` (a private channel: `forum`
     false), then in one transaction: the mirror's chat row in the catalogue (with its title, kind channel),
     `mirror_of` set to the source, **downloads switched off for it** (`collect_off`), the mirror row
     *created*. `*UnknownError` or `ErrBadAnswer`: the row becomes *create outcome unknown* and the step ends;
     no later run creates a mirror for that source while a row is *creating* or *unknown* (a *creating* row
     found at start means the process died mid-request: treat it as unknown). `*WaitedError`: the row is
     removed or marked so that a later run may create (Telegram did not carry it out); the step ends (no
     second create in the same run). `ErrChannelsTooMuch`, `*AccountRefusedError`, `*LongWaitError`,
     `*MemoError`, `ErrMethodFrozen`: the step ends, the row says so, in fixed words.
     If `CreateMirror` returns the mirror together with an `ErrStore` error (the access hash was not stored):
     record the mirror as created (it exists at Telegram) and end the step saying the forward could not go.
  4. the first batch of candidates cut by `PlanBatches` with the real maximum; write the batch row *sending*
     and its forward rows *sent*; `ForwardBatch` once. Success: forward rows *forwarded* with the mirror ids,
     the rest *missing*, the batch *done*. `*WaitedError`: batch *waited*; **send the same batch once more**
     (a new batch row); a second `*WaitedError` ends the step. `*UnknownError`: batch *outcome unknown*; the
     step ends, and no later run forwards for that mirror while a batch is *sending* or *unknown*.
     `ErrAlreadyForwarded`: recorded as its own state, the step ends (not treated as success: the mirror ids are
     not known). `ErrForwardsRestricted`: the mirror row becomes *source protected*; ends.
  5. One mirror and one batch per step, never more (a cap, as a constant).
- **The name:** `X-<source title>-<ordinal>`, ordinal the lowest number above every ordinal the ledger has for
  mirrors of the same base name on this account (so a second source with the same title gets "-2"). The source
  title is cut (whole runes) so that the whole name is at most 128 UTF-16 units. The name goes to
  `CreateMirror` and into the catalogue's chat row and nowhere else: never into a log line, an error or the
  output.
- Every result is a struct of numbers and fixed words (the command prints it).
- `internal/mirror` starts no goroutine and has no package-level state.

### 3. The command (`internal/collector/mirror_cmd.go`, one `case "mirror"` in `cmd/tgarchive-collector/main.go`, a usage text)
`tgarchive-collector mirror -db <catalogue> -chat <catalogue chat number> [-account <n>] [-staging <folder> if
the collector's set-up needs it] [-api-file, -key-file, the VPN gate's flags as signin]`.
- It takes the catalogue's lock as `signin` does: beside a running collector it says so and sends nothing (two
  processes on one session would end the login).
- Without a VPN check configured (and without `-direct`) it refuses, as `signin`.
- Order: the plan (catalogue only: nothing dialled, nothing sent) is printed; if the plan can send nothing, it
  ends there. Else: "type yes and Enter" at the console (the `approve_cmd.go` pattern: only "yes" proceeds;
  anything else, the end of the input or Ctrl-C does not, and says nothing was sent). Then the VPN gate's
  verdict (printed, as signin does), the dial of that one account (no update handler, as a sign-in connection),
  the step, the numbers, the connection closed.
- Ctrl-C during the step: the request in flight is not abandoned silently: the context ends, the forwarder
  returns "outcome unknown" or the cancel, and the ledger says what was in flight. Check by a test that a
  cancel during `createChannel` leaves the mirror row *create outcome unknown* (or *creating*, which a later
  run treats the same) and that a later run sends no create.
- `MaxWait` for this command: 10 minutes (a longer wait ends the command and prints the local time it ends;
  the record keeps it).
- **The forward secret:** 32 random bytes in a file beside the session key file (same folder, its own name),
  made on first use with `crypto/rand`, with the session key file's permissions and handling as the pattern
  (read `telegram.KeyFile`). Never printed. A file of the wrong length is an error, nothing sent.
- **Output, numbers and fixed words only** (constant format strings; no title, no username, no Telegram id, no
  access hash): the plan; then per method (config, create mirror, forward): requests, answered, waits, seconds
  slept, timeouts, refusals by error type, and the time each request took in milliseconds; messages forwarded
  and missing; the count against 500; where the step ended. The catalogue's own chat numbers may be printed.
- The step's counts also go where the collector's counts by method and hour go, if the sign-in command's path
  for that (`writeTgHours`) can be reused without changing `run`; if not, say so in the report and print only.
- Keep edits to existing collector files to the minimum the command needs; `run` and `signin` must behave as
  before (no existing test changed, except to add the new command to a list).

### 4. The fake Telegram (`internal/collector/faketg`)
Add what the command needs, at the `tg.Invoker` level like the rest: `help.getConfig` if absent,
`channels.createChannel`, `messages.forwardMessages`, with switches a test sets: answer a `FLOOD_WAIT_n`,
never answer (timeout), `USER_RESTRICTED`, `CHANNELS_TOO_MUCH`, `CHAT_FORWARDS_RESTRICTED`,
`RANDOM_ID_DUPLICATE` for random ids seen before, some ids missing from the answer. It records every request
it got, so a test can assert "exactly one create, exactly one forward".

## Tests (invented data only; named runs)
In `internal/mirror`, `internal/catalog` (new files only) and `internal/collector` (new file):
1. Plan sends nothing and writes nothing (the fake saw 0 requests; the catalogue file's content hash is
   unchanged).
2. The clean step: exactly 1 config, 1 create, 1 forward; the ledger rows; the mirror's chat row has
   `mirror_of` and `collect_off`; a second run creates nothing and forwards the next batch.
3. An album straddling the 100th message is not split (it goes whole into the next batch or whole into this
   one, per `PlanBatches`).
4. A wait on create: slept in full on the fake clock, on record in the wait store, no second create in that
   run; a later run inside a long recorded wait sends nothing.
5. A wait on forward: slept, the batch sent once more, and a second wait ends the step: exactly 2 forwards.
6. No answer to create; no answer to forward: recorded unknown; a later run sends nothing for that source and
   says why.
7. A process "killed" between the intent row and the answer (simulate: write the intent, do not finish): the
   next run treats it as unknown and sends nothing.
8. `USER_RESTRICTED` on create: the account refused on record; a later run sends 0 requests.
9. `CHAT_FORWARDS_RESTRICTED`: the source remembered; a later run sends 0 requests for it.
10. The ledger unreadable (a corrupt state word): nothing sent.
11. Not "yes" at the console; Ctrl-C at the question: 0 requests, nothing dialled.
12. Privacy: with a source titled with a marker word, the marker appears in no output line and no log line of
    the command (the pattern of `fix_privacy_test.go`).
13. A collector holding the lock: the command refuses, 0 requests.
14. The name rule: the second source with the same title gets "-2"; a long title is cut to the limit.

Run while working only the named tests of what you changed, e.g.
`go test ./internal/mirror -count=1`, `go test ./internal/catalog -run 'Schema13|Mirror' -count=1`,
`go test ./internal/collector -run 'Mirror' -count=1`, `go test ./internal/collector/faketg -count=1`, then
`gofmt -l` and `go vet` on the packages you touched. **No whole-package run of `internal/catalog` or
`internal/collector`** (minutes each; they run once before the merge), no race detector, no Docker.

## Rules
- Go: `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`, then work in
  `wt-mirror-step1/archiver`. One go command at a time, each with `GOGC=25 GOMAXPROCS=2` and `-p 1`. Other
  sessions are compiling on this PC and the owner's old app runs on it: never pin the CPU.
- Privacy: invented data only; never open a real catalogue, the old app's folder (`E:\T\tg-dl`), a session
  file, the API settings file or any media. Print counts, sizes and timings only. Log and output lines use
  constant format strings.
- No new dependency. Comments say why, in plain words.
- Do not edit: `internal/viewer`, `internal/bringin`, `internal/engine`, `internal/lookalike`, `internal/exact`,
  `internal/supply`, the catalogue's hold tables and ladder, anything under `docs` except your report.
- Commit with `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, message ending
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. No archive numbers in the message.
- Report: `archiver/docs/progress/mirror-step1-REPORT.md` in the commit: what was built, file by file; each of
  the 14 tests with its name and time; **whether any code that runs concurrently was added or changed** (a
  goroutine, a lock, a shared flag), and where; every place you departed from this brief and why; anything you
  doubt; what is not verified. Lead with what ran. Your final message to me: the commit hash, the test results
  as counts and times, the departures and the doubts, in under 40 lines.
