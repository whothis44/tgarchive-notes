# Brief M5: the mirror's name rule as a setting, renaming one mirror, and one small settle rule

Written 2026-11-15 (drafted 16:51, made final 18:21 after M4's merge) by the mirror session (M2).
Copy: `C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-name` (branch `wip/mirror-name`, cut from the main head
9dd5a21, clean). Work only there, in `archiver/`. Commit as you go and push the branch to the remote `private`
(`git push private wip/mirror-name`; never `origin`, never a tag, never another branch). Never touch another copy
(`repo-archiver`, `wt-mirror-auto`, any `wt-*`). Never stash, reset or switch branches. Nothing is run against
Telegram. Invented data and the injected clock only. Anything you write holds counts, sizes and timings only: a
chat's or a mirror's name never goes to a log line, an error, a test's output or a commit message; tests use
invented names. New log lines use constant format strings.

**Schema step: 21 on the board** (19 and 20 go to two other tracks). On the branch it is the step after its head
(18, `mirrorAutoSchema`), its number in two constants in one new file, as `schema_mirrorauto.go` does it, so the
integrator renumbers one place at the merge. The step must be idempotent (a column added only when missing).

## What the owner asked (11-15 12:36, after seeing the first real mirror)
"X-Football-1 ... is probably fine, but an option in the app would be good." Listed on the board: the source's
name in the middle, with a prefix and an auto-numbered suffix the owner sets once for every mirror; renaming one
mirror. **The setting applies to new mirrors only; existing ones are renamed by a separate action** (the owner).
Its place on a page is the pages track's; this piece gives it the setting's key and its check.

## What is there today (checked on 9dd5a21)
- `internal/mirror/mirror.go`: `namePrefix = "X-"`, `Base(title)` cuts the title so that prefix + base + "-" + up
  to 4 digits fits `NameLimit`; `Name(base, ordinal)`.
- The ledger stores `base` and `ordinal`, never the name, and rebuilds it in SQL in three places as
  `'X-' || lm.base || '-' || lm.ordinal`: `MirrorNameOnRecord` (`mirrorsettle.go`), `lostCreateSQL` and
  `lostChats` (`schema_mirrorauto.go`): they find the channel of a create whose answer was lost by its exact
  name. A second rule would break all three silently.
- `BeginMirrorCreate` numbers by base (`MirrorNameOrdinal`); the unique index is (account, base, ordinal).
- The request layer has create and forward (`internal/telegram/forward.go`, each through `once`: one request,
  never repeated, a wait slept in full, an unknown outcome said). No title edit exists.
- Settings: the mirror reads and writes through `Deps.Settings` (`GetSetting`, `SetSetting`), as the pause does
  (`pause.go`: one key per account, a stored value that cannot be read is an error, never a default).
- The old app has nothing here (it never made a chat). Real numbers: one create, 342 ms, no wait.

## Part A: the name is stored, not rebuilt
`c_mirror.name TEXT NOT NULL DEFAULT ''`: the name as it is sent to Telegram, written by `BeginMirrorCreate` (and
the task's `BeginMirrorCreateBy`) with the row. The step fills every existing row whose name is empty with
`'X-' || base || '-' || ordinal` (what was sent for it). The three SQL places compare with `lm.name`; nothing
rebuilds a name in SQL afterwards (a test reads the package's source for the old expression). `MirrorRow` gains
`Name`. A read-only handle on an older file (the plan before the owner's yes) rebuilds the name in Go with the
fixed old rule, as today.

## Part B: the rule is a setting, for new mirrors only
One settings row, key `mirror.name_rule` (catalogue-wide: the owner sets it once for every mirror): a prefix
(default "X-") and the text between the name and the number (default "-"). The number stays automatic, by base, as
today, so two rules never collide on a name. Checks, in ONE exported function the pages track can call
(`internal/mirror`): each part at most 16 UTF-16 units; no control characters, no line breaks; the separator not
empty (a number glued to a name that ends in a digit is ambiguous); the prefix may be empty; prefix + separator
leave at least 32 units for the base. `Base` cuts with the rule's real lengths. **A stored value that cannot be
read is NOT read as the default: no mirror is created** (the command says so in fixed words and sends nothing;
the automatic task blocks the want with fixed words until the owner looks): fail closed, as the marks.
The command (`mirror_cmd.go`): `mirror -name-rule` shows the rule (lengths, and an example built from the
invented title "Example"); `mirror -name-prefix P -name-sep S` sets it after a yes (catalogue only, nothing sent,
under the collector's lock as every mirror command). The plan of a create says the name's length and the rule in
force, never the name.

## Part C: renaming one mirror is a separate action of the owner's
`mirror -rename N -to "name"` (N: the source's chat number). The plan, read-only: the mirror exists and is
created and not ended; the new name passes the check (at most `NameLimit` UTF-16 units, no control characters,
not empty); one request: `channels.editTitle`. After a yes: exactly one request through `once`
(`Forwarder.RenameMirror(ctx, account, mirror ChatRef, title)` in `forward.go`, its own request kind and counter
as create has): a wait Telegram states is slept in full and said (the owner runs it again); Telegram's "not
modified" answer counts as done; a refusal is said in fixed words with the error type; on success
`c_mirror.name` and the mirror chat's title in the catalogue are written in one transaction. An unknown outcome
is said, and the command may simply be run again: setting the same title twice changes nothing (the one request
here that is safe to repeat: say so in its comment; nothing repeats it by itself). Never done by the automatic
task, never in bulk. The title goes to Telegram and the catalogue and nowhere else. A renamed mirror keeps its
base and number. The title edit leaves a service message in the mirror: the settle already leaves service
messages out (one test says so: a rename between a batch and its settle changes nothing).

## Part D: one small settle rule (the reviewer's third pass on M4, low)
`mirrorsettle.go` `weighBatch`: a batch message that is not on record at all (`sourceKeys` finds no message row:
the catalogue lost it after the batch was sent) cannot block another message's media match, because it has no
rows; under the owner's `-take` that other message's "found" is still written, though the copy might be the lost
message's. Rule: **while any message of the batch has no message row on record, no message is found by media**
(they are "cannot tell"; matches by a post-naming origin stay). Not for a message that is on record without
media (a text under `-all-messages`): that one is "cannot tell" itself, as today, and blocks nothing more. One
named test that fails first (a supergroup batch, one source message row deleted after the batch, the owner's
`-take arrived`: no row "forwarded" by media).

## Not in this piece
A bulk rename of existing mirrors to a new rule; the setting's page (pages); adopting an existing chat (M6);
refusing a chat known to be protected before any request (after Core's K4 merges).

## Files you may edit
`internal/mirror`; `internal/catalog`: a new `schema_mirrorname.go`, `schema13.go` (`BeginMirrorCreate`, the row),
`schema_mirrorauto.go` (the two queries, `BeginMirrorCreateBy`), `mirrorsettle.go` (`MirrorNameOnRecord`, part D),
`catalog.go` (`SchemaVersion` and the steps' table: one line each); `internal/telegram/forward.go` (not
`call.go`); `internal/collector/mirror_cmd.go` and a new `mirror_name_cmd.go`; the fakes (an answer for
`channels.editTitle`); the tests of these; `docs/progress/mirror-name-REPORT.md` (new). `reader.go`, `account.go`,
the engine: no change; if one seems needed, stop and say why. No goroutine, lock or channel is expected.

## Tests (named; invented names only; each main one seen to fail before its code, or its fix undone once)
The step fills old rows and is idempotent (run twice; a file already holding the column); a create under a
changed rule stores and sends the new name, and the next mirror of the same base takes the next number; a lost
create is found by its stored name under either rule; an unreadable rule creates nothing (command and task);
the checks' edges (16 units, a control character, an empty separator, a long title cut at whole runes under a
long prefix, an empty prefix); rename: done, a wait then run again, unknown then run again, "not modified", a
mirror not created or ended (refused, no request), the catalogue's two writes together; the service message left
out of a settle; no name in any log line or printed line (the package's privacy test pattern); part D's test.

## Running things
In Git Bash: `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`, then ONE go command at a
time with `GOGC=25 GOMAXPROCS=1` and `-p 1`. While working: named tests only (`-run`). Never: a whole run of
`internal/catalog` or `internal/collector`, the race detector, Docker, `go vet ./...`. Anything likely to take
over 2 minutes runs in the background and you wait for it; nothing is left running at the hand-back. Once, at the
end: `go test ./internal/mirror -count=1` (about 90 s); `go test ./internal/catalog -run
'Schema|Mirror|Settle' -count=1`; `go test ./internal/collector -run 'Mirror' -count=1` (about 3 minutes);
`go test ./internal/telegram -run 'Forward|Rename' -count=1`; `go test ./internal/collector/faketg -count=1`;
`go test ./cmd/tgarchive-collector -count=1`; `gofmt -l` on the changed files; `go vet` on the changed packages.

## Report and hand-back
`archiver/docs/progress/mirror-name-REPORT.md`: per part, what changed (file, function) and its tests; how each
main test was seen to fail; every line changed outside the files listed above; concurrent code (none expected);
departures from this brief; doubts; what was not verified. Commit with
`git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, the message ending
`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, no archive numbers, no names; push to `private`. The
copy clean at the end. Final message to the architect, under 40 lines: the pushed head; one line per part; tests
as counts and seconds; concurrent code; departures; doubts.
