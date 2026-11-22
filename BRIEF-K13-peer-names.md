# Brief K13: the names of users and chats, written for a new account (Core, K-3, 2026-11-16 05:04)

For one Opus coder. Listed on the board ("Listed and unbuilt", the viewer's row of 11-15 21:52): the
viewer's chat page shows who wrote a message from the catalogue's table of names, `tg_peer_name`
(schema step 9). The old archive's bring-in fills it; **nothing fills it for a new account**: after the
owner's first real start it held 0 rows, so every sender shows as a number. This piece has the reader
and the live monitor write the names Telegram sends with every answer.

- Copy: `C:\Users\trabi\Claude\Projects\Telegram\wt-core-names`, branch `wip/core-names`, cut from the
  main head a37ed4c3. Go module in its `archiver` folder. Pushed to `private` as you go; never the branch
  `claude/charming-feynman-vm2xia`.

## 1. What the old app already knows

The old app kept every user's and chat's name in its own table (`ix_peers`), written whenever an answer
carried the object; the bring-in carries those rows into `tg_peer_name` (`internal/bringin`, and
`internal/catalog/imported.go` about lines 280 to 330: the kinds, the insert, the read). Its lesson for
this piece is in the viewer's notes (`LESSONS-viewer-ix12.32.md` in the project folder, and
`archiver/docs/LESSONS.md` sections 1 and 2): names are read on every page of the viewer, so the table
must stay one row per account and peer, and a writer must not hold the catalogue's single writer for
long. Read how the old rows look in `imported.go` and write new ones the same way, so that the viewer
reads both alike.

## 2. Read first, yourself

`internal/catalog/schema9.go` (the table and its comment), `imported.go` 280 to 330;
`internal/viewer/live.go` about 500 to 600 (how the viewer turns a message's sender into the table's kind
and id, and which columns it reads: the writer must produce exactly what that reader looks up; the viewer
is NOT yours to change); in `internal/telegram`: `peers.go` (`Peer`, `peersOf`, the `PeerStore`
interface) and every place `peersOf` is used (the reader's pages, the chat list, the monitor's updates
and differences, the forwarder); `internal/tgstore/store.go` (`SetPeer` and how the stores write through
the catalogue); the privacy tests of the package (`privacy_test.go`, `privacy_monitor_test.go`,
`privacy_reader_test.go`).

## 3. What to build

- **In `internal/telegram`:** beside `peersOf`, the names an answer carries: for a user the display name
  as a Telegram client shows it (first and last name joined; a deleted account's fixed mark as the
  library gives it: say what you chose) and the username; for a basic group, a channel or a supergroup
  its title and username. Taken from every answer that carries users and chats at the places `peersOf`
  is used today in the reader, the chat list and the monitor (NOT in `forward.go`: the mirror track's
  file; what the reader and the monitor see covers it). A peer with no access hash still has a name:
  names do not depend on the hash. An object that says it is partial ("min") gives a name only when no
  name is on record yet in this run's memory (it must never replace a full name with a partial one).
- **A store method for them,** offered as an optional interface so that existing fakes and other tracks'
  stores keep compiling (a type assertion on the store the reader and the monitor already have; no
  change to `PeerStore`'s method set). `internal/tgstore` implements it on the catalogue.
- **In `internal/catalog`:** one door that writes a batch of names for an account in ONE short
  transaction: an insert or an update per peer, **only when the name or the username differs from what
  is stored** (one statement per peer with the comparison in it, or one statement for the batch; no
  read-then-write), never replacing a stored name with an empty one, the time it was seen in the column
  the old rows use. Plain types; the catalogue must not import `internal/telegram` (the viewer's wall,
  `TestWallDependencies`).
- **Cheap by construction:** the same few names arrive with every page and update. Keep, per session, a
  small bounded memory of what was last written (the peer and a hash of its name and username): a name
  already written in this session costs no statement at all. Bounded (say 50,000 peers; when full it is
  simply cleared), under its own lock (the reader and the monitor call from different goroutines). Say in
  the report the statements per history page of 100 messages on a second read of the same chat (wanted: 0).
- **Failures:** a name that cannot be written never fails or delays the read or the update that carried
  it: counted, one constant log line said once per session, and the session's memory is not marked so
  that the next sighting tries again.
- **Privacy, the hard rule of this project:** a name, a username or a title never reaches a log line, an
  error's text, a count's name, the status file or a test's output; ids neither. Constant format strings
  with counts only. A privacy test in the manner of the package's own puts canary names and usernames
  through the reader's page, the chat list and the monitor's update and searches every log line and
  returned error.
- **Counted per hour** the way the collector's other counts are, where the stores' counts go today (say
  where): names written, names unchanged (skipped by the memory), write failures.
- **Not in this piece:** reactions and what a service message says (the same board row: they need a
  schema step and their own design); the viewer; any page.

## 4. Tests and runs

`internal/telegram`: named tests on the package's fakes: the names taken from a history page, a chat
list answer, a new-message update and a difference (users, a basic group, a channel, a supergroup, a
deleted account, a partial object that must not replace a full name); the optional interface absent (a
store without it: nothing breaks). `internal/catalog`: the door (insert; unchanged writes nothing: check
the row's time and the number of changes; a changed name updates; an empty name never replaces; two
accounts see one user under two names: two rows; the batch is one transaction). `internal/tgstore`: the
memory (a second sighting costs no statement; a failed write is tried again; the bound). One end-to-end
test in `internal/collector` on its fake Telegram (`TestNames...`): after a chat's read and one live
message, the table holds the sender's and the chat's names, and **the viewer's own lookup finds them**:
call the viewer's read of names the way `internal/viewer/live.go` does it from a test in the collector's
package only if that needs no new import across the viewer's wall; otherwise repeat its exact query in
the test and say so. The privacy test.

Run (the PC is shared and busy: before each go command read free memory with
`powershell -NoProfile -Command "[int]((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1024)"`
and wait if it is under 3,000 MB; `GOGC=25 GOMAXPROCS=2`; Go through
`source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`): `go build ./...`; `gofmt -l`
and `go vet` on the four packages; your tests by name; the existing tests by name of what you touched
(`-run 'Reader|Monitor|Dialogs|Privacy|Peer' ./internal/telegram/`; `-run 'Peer|Import' ./internal/catalog/`;
the whole small `internal/tgstore`); `-run TestWallDependencies ./internal/viewer/`. No whole run of
`internal/collector` or `internal/catalog`, no race detector, no Docker: mine, once (the memory is shared
between goroutines: the race detector runs on your named tests then).

## 5. Limits and hand-back

- Files: `internal/telegram` (`peers.go`, the call sites in the reader, the chat list and the monitor;
  NOT `forward.go`), `internal/tgstore/store.go` (or a new file beside it), a new file in
  `internal/catalog` for the door (not `imported.go`'s existing functions), tests, one test file in
  `internal/collector`, a report `archiver/docs/progress/core-names-REPORT.md` (no path of this PC in
  it). No schema step (the table exists), no `go.mod` change, no new request to Telegram of any kind:
  this piece only stores what answers already carry.
- Commits with `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, each message ending
  with a blank line and `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; pushed with
  `git push private wip/core-names`; `git status --short` empty at the end; work in progress pushed as
  you go.
- Your final message: the head's full hash; what the viewer looks up and how your rows match it (kind
  and id for each chat kind); the statements per page on a first and a second read; the commands with
  results and seconds; the files; anything in this brief you found wrong (check a door in the code
  before relying on my word for it).
