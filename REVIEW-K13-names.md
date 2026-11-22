MAY BE LISTED AFTER THE MUST-FIXES

# Review K13: the names of users and chats (wip/core-names at d9aaf8b9, base a37ed4c3)

Independent adversarial review, 2026-11-16. I read the brief, the whole diff, the call sites, the viewer's
lookup, the bring-in's rows, the old app's `ix_peers` writer (`wt-v12.31`) and the library's update dispatch
(gotd v0.166.0). The probes were loaded with `go test -overlay` from a scratch folder; no file in any
checkout was changed. Invented data only.

Count: 1 MUST FIX, 1 SHOULD FIX, 5 MINOR.

## Findings, most serious first

**1. MUST FIX, CONFIRMED.** `internal/telegram/peers.go:178` (with `internal/viewer/live.go:584`, unchanged).
For a deleted account, the new account writes the fixed text "Deleted Account" with `at` = now. The viewer
reads any account's row and takes the newest `at` (`ORDER BY 4`, last one wins). So once a new account reads
a chat that the old archive also holds, every deleted sender's real name from the old archive is hidden behind
"Deleted Account" across the unified viewer. The partial rule protects only the new account's own row, not
the other account's. A probe confirms it (an old-archive row with a real name at 100, then the new account's
deleted mark at 200: the viewer's query returns the mark). This hits the piece's main reader, the unified
viewer over the old archive and the new accounts.
*Smallest fix:* write nothing for a deleted account (`continue` at line 178). The viewer then shows any other
account's real name, or else the number. If the owner wants the mark kept, an alternative is to write it with
`at = 0`, so that any real name wins. Either way, add the probe as a test.

**2. SHOULD FIX, PLAUSIBLE (confirmed by reading; no contention probe).** `internal/telegram/peers.go:250-262`.
The write is synchronous on the reader's and the monitor's goroutines (`reader.go:398` via `learn`;
`monitor.go:570, 684, 687`). It waits without limit for the catalogue's single writer: `SetMaxOpenConns(1)`,
and `BeginTx` blocks until the connection is free. On the monitor, and on a history page, a catalogue write
follows straight away anyway (`MessageSeen`, `SavePage`), so the extra delay there is about one short
transaction. But `EstimateChat` (`reader.go:907`) used to do no write in the common case, and now it waits
for the writer whenever a page carries a new name. While another task holds the writer for seconds, the
estimate waits too. The brief says a name must "never fail or delay" a read.
*Smallest fix:* bound the store call with a short derived context, for example
`sctx, cancel := context.WithTimeout(ctx, 2*time.Second)`. On a timeout, count the names as failed (the next
sighting tries again). Keep the "own end" test on the parent `ctx`, not on `sctx`.

**3. MINOR, CONFIRMED.** `internal/catalog/seennames.go:36`. A row written with an empty name (a full object
that carries only a username) is never filled by a later partial name, because the partial statement is
`DO NOTHING` once any row exists. The viewer skips `name = ''` rows, so the sender stays a number. A probe
confirms it. This is rare: users always have a first name and chats a title.
*Fix:* `ON CONFLICT ... DO UPDATE SET name = excluded.name, at = excluded.at WHERE name = '' AND excluded.name <> ''`.

**4. MINOR, PLAUSIBLE (the brief's own rule).** `internal/catalog/seennames.go:33-35`. The new rows' `at` means
"first seen as this name": it moves only on a change. The bring-in's rows mean "last seen": the old app sets
`updated_at` at every sighting (`ix_record.go`, `ix_peers` upsert). The viewer compares the two as if they
meant the same thing. Where two accounts legitimately show different names for one user (a contact name the
old account saved), the old archive's row wins for as long as its last sighting is later than the new
account's first sighting, even after the new account has seen the user many times.
*Fix if wanted:* also move `at` when it is older than a day (`OR at < excluded.at - 86400`). Because of the
memory, this costs at most one write per peer per process and day, and still none on a second read. Otherwise
document the difference beside the viewer's rule.

**5. MINOR, CONFIRMED by reading.** `internal/tgstore/names.go:114`, `peers.go:272`. "Written" counts the
statements sent, not the rows changed. After every start, each peer seen once counts as written even though
nothing changed, so the hourly `peer_names.written` overstates real changes.
*Fix:* return the door's changed-row count as well (for example a `changed` count), or rename the count
"sent".

**6. MINOR, CONFIRMED by reading.** `internal/telegram/peers.go:272-274`. All three tally counts are added on
every call, including zeros, so zero-valued keys are created each hour. *Fix:* add only when n > 0.

**7. MINOR, PLAUSIBLE.** `internal/catalog/seennames.go` with `tgstore/names.go:99`. A batch has no size
limit. A difference after a long time offline, or a chat-list page, can carry hundreds to thousands of users,
all in one transaction that holds the writer for that long (the first time in a process only).
*Fix:* split into batches of about 500 names in `SavePeerNames`, with the memory marked per committed batch.

## Probes run (overlays; each one checks that a test can fail)

- Privacy guard, the error text added to the failure line: `TestNamesPrivacyGuard` FAILS (the canary name,
  id, path and text come out). Good.
- Privacy guard, every name's id logged on each write: `TestNamesPrivacyGuard` FAILS. Good.
- (a) The "only when changed" condition removed from the door: `TestSeenNamesDoor` FAILS ("the same names
  changed 3 rows"). Good.
- (b) The partial rule removed (partial names use the full statement): `TestSeenNamesDoor` FAILS. Good.
- (c) The memory never consulted: `TestNamesMemory`, `TestNamesMemoryBound` and `TestNamesStatementsPerPage`
  FAIL (26 statements per page on the second read instead of 0). Good.
- Findings 1 and 3: new probe tests in `internal/catalog` both fail as described.
- Baseline on the branch: `-run TestNames ./internal/telegram/`, `-run TestSeenNames ./internal/catalog/` and
  the whole `./internal/tgstore/` (14 s) pass.

## Checked and sound

- **Privacy.** There is exactly one new log line, with a constant format and a count only. The error from
  the store is never formatted: `fail()` keeps only the operation and the Go type, and `nameWriter` drops the
  error. `PeerName` and `SeenName` have no `String`, `GoString` or `Error` method and are never printed outside
  tests. The count names are constants. `Stats.Names` holds counts only. Nothing new can panic: there are only
  type switches, and `w == nil` and `logf == nil` are guarded. The tests print only their own invented rows.
  The collector's test runs `privacyCheck` over its logs.
- **Kinds and ids against the viewer.** User: 1, the id. Channel or supergroup: 2, the unmarked id (the viewer
  marks it as -1000000000000 - id). Basic group: 3, the unmarked id (marked -id). These are the same as the
  bring-in's rows (`imported.go` and `bringin/run2.go`). Rows are per account (primary key account, kind, id),
  so a new account's row cannot overwrite another account's. A basic group that became a supergroup gives two
  rows (kinds 3 and 2), as the old app had them. The collector's end-to-end test repeats the viewer's query.
- **Order.** Names are written before the messages that carry them: in `learn` before `SavePage`, and in
  `handle` before `apply`. So a sender's name is already in the catalogue when the viewer first sees the
  message (the viewer caches misses per index version).
- **The door.** One transaction per batch, rolled back whole on any failure (tested with a trigger). The
  columns are NOT NULL, so `IS NOT` acts as `<>`. An empty name never replaces a stored one. A full object
  with no username clears the username, which is right for a full object. `at` moves only on a change. A full
  object after a partial one replaces it (tested). There is no read before the write.
- **The memory.** The key is (account, kind, id), so two accounts that see one user keep separate entries and
  rows. The hash is 64-bit FNV-1a with a separator, so a collision is negligible (about 2^-64 per change) and
  would last only until a restart or a clear. The lock is not held across the database write. A peer is marked
  only after the commit. A partial entry never stops a full name. The same peer twice in one answer gives one
  statement, with the full object winning. When the memory is full it is cleared, and each peer is then
  written once more as a no-op statement. Two goroutines that both miss for the same peer each send a
  statement; the second changes nothing.
- **Call sites.** Every `learn` use is covered: history page, estimate, chat list, topics. So are the
  monitor's `Updates` and `UpdatesCombined` (gotd v0.166.0 dispatches both the live updates and the
  differences as `*tg.Updates` with their users and chats; `min_backfill.go`) and the channel's too-long
  difference. `forward.go` and the refresher are left out, as briefed. No reader or monitor lock is held
  during the write: `handle` releases `m.mu` before it. The optional interface is found once, at construction.
  The collector passes its `*tgstore.Store` as `Peers` to the reader, the monitor and the mirror readers, so
  the type assertion succeeds in production (`collector/account.go:530,536`).
- **What names are taken.** First and last name, each trimmed, are joined and trimmed again, so a user with
  only a last name gets it alone and whitespace-only names become empty. The username is the user's own, else
  the first active one in the list of collectible usernames. Bots work like users. Min users and min channels
  are partial. Forbidden chats give their title. A contact's name is the name the account saved, which is what
  a Telegram client shows. Names made only of characters that are not Unicode white space (U+3164,
  zero-width) are kept as they are; this is harmless.
- **Failures.** A failure never changes what the reader or the monitor returns. It is counted, logged once
  per object, and tried again at the next sighting (tested on the reader; the monitor goes on to its gap and
  inaccessible events under a failing store in the guard).

## Not checked

- The race detector (not allowed here). Run it on: `-run 'TestNames' ./internal/tgstore/` (the memory is
  shared between goroutines), `-run 'TestNamesFromMonitor|TestNamesPrivacyGuard' ./internal/telegram/` (the
  monitor's per-channel goroutines call `nameWriter.write` at the same time), and the collector's
  `TestNamesWrittenForTheViewer`.
- Real writer contention (finding 2) and the size of a real difference's user list (finding 7): no
  measurements.
- The whole collector and catalogue packages (not allowed).

## Where the brief is wrong or silent

- It asks for "a deleted account's fixed mark" but does not consider the viewer's rule that the newest row of
  any account wins. Together they give finding 1.
- It asks that `at` move only on a change, "in the column the old rows use", but the old rows' `at` means last
  seen (finding 4).
- It says the write must never "delay" a read, but sets no bound on waiting for the single writer (finding 2).
- Its partial rule ("only when no name is on record in this run's memory") is weaker than what was built (only
  where no row exists in the catalogue). What was built is better, apart from the empty-name case (finding 3).
- It does not say how large one batch may be (finding 7), or whether "written" means statements or changed
  rows (finding 5).
