# Brief K22: alerts, the record and what raises one (Core, K-6, 2026-11-21)

**Why:** on 11-21 the automatic mirror blocked a chat at 18:08 (a batch refused MESSAGE_ID_INVALID, its
message deleted at the source) and nobody knew for about three hours; 38 posts were lost. Whatever needs a
person is to be raised, recorded and kept until the owner has seen it. The design is
`C:\Users\trabi\Claude\Projects\Telegram\DESIGN-CORE-alerts.md` (one page): read it first. **This piece is
sections 1 and 2 only: nothing leaves the PC.** Sending to the phone (section 3) waits for the owner's
choice and is a later piece; build nothing of it, but leave the record able to carry "sent" per channel later
without a second schema step if that is cheap (say what you chose).

**Rules of the house:** you are the Opus coder of this piece and hand back commit-ready work. Named tests
only while you work (`-run`, or a small package whole; the whole `internal/collector` takes about 30 minutes
and the whole `internal/catalog` about 8: not yours to run); no race detector; no `go vet` over many
packages. Invented data only; nothing of a name, text, path or id in any log line, error or commit message;
new log lines are constant format strings with numbers only. Nothing runs against Telegram: the collector's
fake Telegram only. Never touch a running program, the main copy `repo-archiver`, the owner's folder
`C:\Users\trabi\tgarchive-app` or anything under `E:\`. **Every `go`, `gofmt` or `vet` command goes through
the track's lock script:**
`bash /c/Users/trabi/Claude/Projects/Telegram/runs-core-k5/go1.sh <folder to run in> go test -p 1 -run '<names>' -timeout 20m ./internal/collector/`
(it prints "go1: exit N"; 97 or 98: nothing was run, wait and try again).

**Where:** make the copy yourself, one command, from `C:\Users\trabi\Claude\Projects\Telegram`:
`git -C repo-archiver worktree add ../wt-core-alerts -b wip/core-alerts af4ca40e`. Work only in
`C:\Users\trabi\Claude\Projects\Telegram\wt-core-alerts`. Commit with `git -c user.name=Claude -c
user.email=noreply@anthropic.com commit`, the message ending `Co-Authored-By: Claude Opus 5.5
<noreply@anthropic.com>`; push only `wip/core-alerts` to `private`, work in progress too, after each step
that builds. No `git stash`, no rebase.

## What exists (read these before writing)

- **The old app's alerts, to port the way of:** `C:\Users\trabi\Claude\Projects\Telegram\wt-v12.31\core-service\internal\app\ix_alerts.go`
  (269 lines; read whole): conditions looked at every minute, a key per condition, sent again after 24 h
  while it lasts or once ever, never message text. It kept only "sent at"; the new app keeps a record until
  seen.
- **TRIED-BEFORE sections 24 and 25** (`repo-archiver/archiver/docs/TRIED-BEFORE.md`; read both in full):
  the rules for anything that acts for the owner. Here: (10) a cap per step, (11) one row per item,
  (13) fail closed: a value or state that cannot be read is never "all is well".
- **The states to raise from (name each function you use in the report):**
  the account's state, `internal/collector/account.go` (`AccountState`: `StateFrozen`, `StateSignedOut`,
  `StateGateRefused`, `StateRetrying`; `setState` keeps no "since": add one, in memory, set only when the
  state changes); the library, `internal/store/copier.go` `Copier.Away()` and `LibraryFull()`; staging,
  `internal/store/writer.go` `Writer.StagingNow()` (Away, AwaySince, Resting, RestSince); the automatic
  mirror's blocked wants, `internal/catalog/schema_mirrorauto.go` and `schema_mirrorwant.go`
  (`c_mirror_want.block_at`, `block_why`: the mirror track's fixed words; the mirror track is changing the
  block itself in M14 at the same time, so READ its tables, change nothing of the mirror's); downloads
  finished and wanted, and the owner's pause of downloads (`internal/collector/pausedl.go`, the heartbeat and
  the counts task: find where "a file finished" is known).
- **The collector's tasks:** `internal/collector/collector.go` `Run` starts them with `c.supv.Go(tasks,
  "<name>", &mainWG, ...)` (settle, counts, gate watcher): the alerts task is one more of those.
- **A stored setting with its doors:** `internal/mirror/autonew.go` (`ListEveryKey`, `CheckListEvery`,
  `ReadListEvery`: a stored value that cannot be read is an error, never the default silently) and the
  collector's `MirrorListEvery`/`SetMirrorListEvery` for a page.
- **A schema step:** `internal/catalog/schema_edgelog.go` is the newest (26); copy its form: a new file
  `schema_alert.go`, the number in two constants (`alertSchema = alertAfter + 1`, `alertAfter =
  edgeLogSchema`), `SchemaVersion` pointing at it, the step refusing any other version. The integrator sets
  the number at the merge.

## What to build

1. **A pure package `internal/alert`** (no Telegram, no catalogue, no goroutine): the kinds as constants with
   their fixed words (`mirror.blocked`, `account.frozen`, `account.signed_out`, `account.vpn`,
   `account.retrying`, `library.away`, `library.full`, `staging.away`, `staging.full`, `downloads.stalled`,
   `backup.failed` reserved for later, `alert.unreadable`, `test`); the thresholds as settings with the
   defaults of the design's table (at once; 15 min; 30 min; 1 h), each a whole number of minutes, a check,
   a read that refuses a stored value it cannot read (rule 13), **no upper bound of the app's own** (the
   owner's rule on caps: the bound is only what makes sense, e.g. not negative); and one function that,
   given a snapshot of the states (with their "since"), the time and the settings, answers which keys are
   true now. Keys: kind plus account, plus the want for `mirror.blocked`. Its words: fixed, numbers only,
   fit for a page (the page puts the chat's name beside them from the catalogue; the words never hold one).
2. **The record, `internal/catalog`, one schema step:** table `c_alert`, one row per raised alert: id, key,
   kind, account (null if none), the mirror want (null if none), raised_at, last_at, ended_at, seen_at,
   times raised again, the fixed words. At most one row per key while not ended (a partial unique index).
   Doors, all by the catalogue's one writer: raise (idempotent: an open row for the key only moves last_at),
   end (sets ended_at; the row stays), see one, see all, the list (unseen or not ended, newest first; and a
   page of the history), a change number that a page can poll cheaply (one indexed read), and prune (seen and
   ended rows older than 90 days, at most 1,000 a call). **The list and the change number work on a
   read-only handle** (pages and the viewer open the catalogue read-only). An alert raised again after it
   ended is a NEW row (the owner sees it came back), and `times` counts returns within one open row.
3. **The alerts task in the collector:** every 30 s (a constant): build the snapshot from memory and ONE
   catalogue query for blocked wants, run the pure function, raise what is newly true, end what is no
   longer true; prune once an hour. No request to Telegram, no file system walk. A snapshot part that
   cannot be read (the catalogue query fails) raises `alert.unreadable` with a fixed word saying what could
   not be read, and ends nothing it could not judge (fail closed). The task stops with the others; a panic
   in it is the supervisor's, as for the other tasks. One log line when an alert is raised or ended:
   constant format, the kind as a fixed word and the account's number only.
4. **Doors for pages** in the collector, the form of `MirrorListEvery`: the list, the change number, see
   one, see all, the thresholds (read: value, stored or default, unreadable; set), and "send a test alert"
   (raises a `test` row, ended at once and unseen, so that the page and the Windows notification can be
   checked end to end without anything leaving the PC). Where the pages call the collector today (a local
   door, `internal/actdoor` or `livepages`: those are the pages track's packages) **do not edit them**:
   list in the report the exact Go names they can call, and what the route should do.

**Do not touch:** the download path, `internal/supply`, `internal/engine`, the mirror's files and tables
(read only), `internal/viewer`, `internal/server`, `internal/launcher`, `internal/appshell`, `internal/actdoor`,
`livepages`. If one line of another track's is needed, stop and say which.

## Tests (each seen FAILING first; the collector's fake Telegram where a run is needed)

1. The pure function: each kind true at its threshold and not one minute before; a state that ends ends the
   key; two accounts give two keys; a stored threshold that cannot be read is an error.
2. The record: raise twice: one row, last_at moved; end then raise: two rows; see; the list's order; the
   change number moves on raise, end and see and not otherwise; prune keeps unseen and open rows; the list
   and the change number on a read-only handle; the step on a catalogue at 26 and its refusal at 25.
3. The collector on the fake: an account made frozen raises `account.frozen` within one look and it ends
   when the account is no longer frozen; a blocked want (written as the mirror writes it) raises
   `mirror.blocked` at once and it ends when the want is unblocked; the library away 31 minutes (a fake
   clock or a short setting) raises `library.away` and 29 minutes does not; the catalogue's blocked-want
   query made to fail raises `alert.unreadable` and ends no open alert.
4. "Send a test alert" gives one ended, unseen `test` row.
5. No request to the fake Telegram is made by the alerts task (counted at the fake).
6. The existing tests of the account's states and the settle by name still pass; list what you ran.

`gofmt -l`, `go build ./...`, `go vet ./internal/alert ./internal/collector ./internal/catalog`, and the
viewer's `TestWall` by name (a new package under the catalogue has broken it before).

## Hand back

`archiver/docs/progress/core-alerts-REPORT.md` (committed) and your last message, the same content, short:
the head and that it is pushed; the schema step; each kind with the function it is read from; the doors for
pages with their exact names; the tests as run; what you could not test; anything in this brief the code
contradicts. Then stop: the review and the full runs are the Core session's.
