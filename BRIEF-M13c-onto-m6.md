# Brief M13c: M13 onto M6's tree (session M-6, 11-16)

For the same coder, in `wt-mirror-capmax` on `wip/mirror-capmax` from 7b84bda6. M13 is reviewed ("may be
listed") and clean on its own tree. It cannot be listed alone: it meets M6 (`wip/mirror-adopt`, the adoption
of an existing chat: reviewed, in its last runs, merged before M13) in
`internal/catalog/schema_mirrorwant.go`, in text and in meaning. One small round. The rules of the earlier
briefs hold (every go command through `go1.sh`, which may wait long now: another run holds the lock for up to
30 minutes at a time, so start each go command in the background and keep working; named tests with
`-timeout`; no whole package; privacy).

1. **Merge M6's branch into yours:** `git merge --no-ff wip/mirror-adopt` (its head is 16589fcb, or newer if I
   merged a main head into it since; it holds the main head with copies' schema step) with the usual identity
   and last line. Expected: one conflict, `internal/catalog/schema_mirrorwant.go`; `command.go` merges by
   itself. Read both sides of that file whole before resolving.
2. **The meaning:** M6 changed `MirrorCreatesSince` so that an ADOPTED mirror row is no create (an adoption
   makes no channel). Your `MirrorCreateAtRank` says "the same starters and the same 24 hours as
   `MirrorCreatesSince`": after the merge it must leave adopted rows out in exactly the same way (read how M6
   wrote that condition and how it behaves on a file older than the adoption's step, and use the same form),
   or the count and the rank disagree and `createsRoom` gives a wrong time for an account with an adopted
   mirror. A test that fails without it: among the creates of 24 hours one adopted row (older and newer than
   the others, two cases): the count, the rank and the room agree with a catalogue that has no such row.
3. **The turn's guard at the account's limit and an adopted chat:** nothing to change (an adopted chat is a
   channel of the account and is counted by `MirrorChannelCount` as any channel): say so in the report in
   one line after reading that the count does not depend on `mirror_of`.
4. **The report:** the first round's "tests added" is 5, not 6 (correct it); a section "M13c": the merge (what
   conflicted), the rank's condition, the test, the runs.
5. **Runs, through `go1.sh`:** `go build ./...`; gofmt and vet on catalog, mirror, collector; the catalogue's
   `TestMirrorWant|TestMirrorAdopt|Schema` by name; the mirror's
   `TestNewPerDay|TestMirrorNewPerDay|TestMirrorAutoChannelLimit|TestMirrorAdopt`; the collector's
   `TestMirrorNewPerDay|TestMirrorAutoChannelLimit|TestMirrorAdopt`. I run the whole packages after you.
6. Commit (the merge; the fix with its test; the report), push `wip/mirror-capmax` to `private`, the copy
   clean. Final message, short: the head's 8-character hash; what conflicted and how the rank's condition
   stands; tests added (names), removed (0); every run's "go1: exit N" line; anything not as written.
