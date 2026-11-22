# Brief E24 (merge entry "C19"): a removed copy edge is logged as a change of its two media, not as "something went away" (copies, session C5, 11-16)

**For an Opus 5.5 coder at high effort. One schema step that replaces one trigger, and its tests. You write code
and run only the named tests of what you changed; whole packages, vet and the merge of the head are done once,
later, by a clerk of the main session. Read only what section 1 names.**

- Copy: make it first, from the Bash tool, from the main head named in your start message:
  `git -C /c/Users/trabi/Claude/Projects/Telegram/repo-archiver worktree add -b wip/copies-24 /c/Users/trabi/Claude/Projects/Telegram/wt-copies-24 <the head>`
  (if the branch or the folder exists already, stop and say so). Work only in that copy. Go:
  `. /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`, then the copy's `archiver`.
- **Go commands: one at a time, each with `GOMAXPROCS=2 GOMEMLIMIT=1GiB GOFLAGS=-p=1`; free memory at least 1.2 GB
  before each (`powershell -NoProfile -Command "[math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB,1)"`;
  under it wait 2 minutes and look again); and the track's lock around each: `mkdir /c/Users/trabi/Claude/Projects/Telegram/runs-copies-golock`
  (if it exists wait 30 seconds and try again, 20 minutes at most; a lock older than 30 minutes may be removed and
  taken), `rmdir` right after the command ends, also when it fails. Write the code first, then test.**
- Commit as you go: `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, the message ending with
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; `git push private wip/copies-24` after each commit.
  Never another branch; never merge; never tag.
- Invented data only. Nothing runs against Telegram. No log line, test, comment or report carries a real name,
  text, path, id or link.
- You touch `internal/catalog` only: a new file for the step, `catalog.go`'s three schema places, the comment
  in `changelog.go`, and tests. **Not `internal/viewer` (the viewer track builds its own side), not `lane.go`,
  not `state.go`, no other package.** The change log is Core's part of the catalogue: this step is taken with a
  line on the board (the copies message of 11-16 about 16:35), because Core has no session today.

## 0. What was found, and what is decided
- The viewer track, on the board (message 135, 11-16 16:08; read it: it is the request): since C13 (merged
  today) the catalogue REMOVES `copy_edge` rows while it runs: the owner's "not the same" on a pair
  (`pairword.go`, the two `DELETE FROM copy_edge` near line 550) and a held copy whose saved look-alike is lost
  (near line 948). The change log's trigger `cl_edge_ad` (schema v3, `changelog.go`) writes such a removal as
  kind 3, `ChangeGone`, with the edge's rowid: "a message, a media, an edge, a chat, a topic or an account went
  away", which does not say which. For kind 3 the viewer's index writer has one answer: read everything again
  in full: **about 4 s at 600,000 messages on this PC, with the listings, marks and verdicts all started again,
  after every "not the same" the owner clicks.** Before C13 nothing in a running archive removed a row.
- The old app has nothing to compare: its viewer rebuilt on a timer (`LESSONS-viewer-ix12.32.md`: the slow
  viewer was the owner's first complaint about it); the new viewer's rule is "an update is incremental".
- **Decided (the viewer track's own second proposal, 135 d): no new kind. A removed edge is logged as kind 1,
  `ChangeMedia`, once for each of its two media (`OLD.a`, `OLD.b`).** Kind 1 is what a reader already gets when
  a hold is made or ended, and the viewer redoes that media's sets in place. Kind 3 stays for every other row
  that goes away.

## 1. Read first (in the copy; no more than this)
- `internal/catalog/changelog.go` in full (the log, its kinds, the v3 triggers; `cl_edge_ad`).
- `internal/catalog/schema_pairword.go` and `schema_actkey.go`: how a schema step is written today (its "after"
  constant, its number in one place, the refusal on any other version, idempotent SQL), and `catalog.go`'s
  three places for a step (`SchemaVersion`, the `steps` list, the switch): **your step is "the step after the
  head's newest"; its number lives in two constants so that the integrator can move it at the merge** (the
  mirror track has claimed 26 for a piece in flight; this one is claimed as 27 on the board and takes whatever
  number its merge order gives).
- The schema's own tests (search the catalogue's tests for `TestSchema` and for `actKeySchema`): the tests a
  new step must extend, and how a file at the step before is made.
- In `pairword.go` only the three `DELETE FROM copy_edge` statements and what else those functions write for
  the same media (does a `c_want` change already log kind 1 for one of them?).

## 2. What to build
- One schema step (a new file `internal/catalog/schema_edgelog.go`): `DROP TRIGGER IF EXISTS cl_edge_ad;` and
  the trigger made again `AFTER DELETE ON copy_edge` writing `change_log(kind, id)` twice: `(1, OLD.a)` and
  `(1, OLD.b)`. Nothing else. Idempotent; refused on any version but its "after"; a catalogue made new runs it
  like every other step.
- `changelog.go`: `ChangeGone`'s comment no longer lists the edge; `ChangeMedia`'s says "or a copy edge of it
  was removed"; the file's comment "every trigger a single insert" says the one exception. The v3 text itself
  is NOT edited (it is history: a file at v3 has that trigger until this step).
- **Say in the report, from the code, every way a `copy_edge` row can be deleted** (the three statements; a
  cascade when a `tg_media` row is deleted, if the table has one: then the trigger fires for rows whose media
  is gone: is a kind 1 for a media that no longer exists harmless to a reader that looks the id up? the media's
  own kind 3 is logged by `cl_media_ad` in the same statement: say the order of the rows), and how many log
  rows the largest such removal can write (the lost look-alike removes every probable edge to one media: is
  that bounded by its 200-a-transaction rule?).
- Nothing in the viewer; nothing that reads the log is changed.

## 3. Tests (in `internal/catalog`; every new name starts with `TestEdgeLog`; invented data)
1. `TestEdgeLogRemovedEdgeIsTwoMediaChanges`: an edge removed by each of the three statements' doors (the
   owner's "not the same" through `SetPairWord`/`ApplyPairWords`; the lost look-alike through `WantAgain`): the
   log's new rows hold kind 1 for both media and NO kind 3; the head's code fails this test (seen once).
2. `TestEdgeLogOtherRowsStillGone`: a message, a media, a chat removed: kind 3 as before.
3. `TestEdgeLogStep`: a file at the version before takes the step once (the trigger's text is the new one, read
   from `sqlite_master`), a second open changes nothing, a file at another version is refused in the step's
   fixed words; a catalogue made new has the new trigger.
4. The schema's existing tests are extended where they count steps or name the newest (as the last step's
   author did): no test function removed; say each line changed.
Run while working: `go test ./internal/catalog -run 'TestEdgeLog|TestSchema|TestPair' -count=1` (say its
seconds), `go build ./...`, `gofmt -l internal/catalog`. **Not** the whole catalogue (9 minutes), no race
detector, no vet over packages.

## 4. Hand-back
A report `archiver/docs/progress/copies-edgelog-REPORT.md`: the step as built; `catalog.go`'s lines; every way
an edge row is deleted and what each now logs; the largest removal's log rows; each test and what breaks it;
**what the viewer's side can now rely on, in three lines for the viewer track** (which ids arrive, in which
order relative to the `c_want` change of the same statement, and that a full read is no longer asked for by an
edge's removal); test functions removed (none); what you could not verify; every doubt. Everything committed
and pushed on `wip/copies-24`; the copy clean. Your last message: the head's short hash, the tests run with
their seconds, the three lines for the viewer track, the doubts in a few lines.
