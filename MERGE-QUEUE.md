# Merge queue (short entries; rebuilt 11-21 22:24; everything before is in `MERGE-QUEUE-LOG.md`)

One entry per branch that is ready, in merge order, at most 15 lines:

```
<ID>. READY (<track>, <time>): `wip/<branch>` at <head>, holds main <commit>
- What it does: <two or three lines>
- Files: <packages touched; anything in another track's files>
- Schema step: <none | N, claimed on the board>
- Review: <none (why: not Telegram, not skip/delete, not download path) | one independent review: findings and fixes>
- Tests run: <named tests and small packages, with times>; whole collector/catalog: left to the integrator
- Not verified: <one or two lines>
```

The integrator marks an entry "MERGED <time> as <commit>" and moves it to the log at the next batch.

## Ready

### In the batch now testing (i6e, started 00:20; merged when it passes)

### Mirror, listed after the batch (M-7)

### Next: the UI batch (F1 first, then U2, F5, F4; the viewer's bring-in U1)

### The client (A-1): acting in chats, step 3

### NAS (N-1, Console run 11-22 evening)
NA5. READY, HELD FOR THE OWNER'S OK (NAS, 11-22 ~20:30): `wip/nas-move` at e11fb3e5, holds main 2c5d21a0
- What it does: `tgarchive-nasmove out|in|back` (the archive and its login move PC to NAS and back as a checked bundle; moved mark; login files deleted only after the bundle verified whole, on a typed yes); every NAS container as the app's own regular NAS user (`.env`).
- Files: internal/nasmove, cmd/tgarchive-nasmove, deploy/nas-app, deploy/nasdl, backup README text; lent: collector (moved.go, lock.go, words.go, command.go, collector/signin/mirror/telegramway one check each), bringin/run.go.
- Schema step: none.
- Review: two independent (REVIEW-NA5-move.md 4 HIGH; REVIEW-NA5-move-2.md fix first, then "may be listed").
- Tests run: nasmove whole + race (310 s); combined tree e1ace724 / ba698d48: whole collector, catalog, store, launcher, backup, livepages, ./cmd, vet, gofmt ok; bringin 2 fails also on main (clutter).
- Merge: `bash ix-tools/merge-batch.sh 2c5d21a0 ba698d48682966d1d498505214aeda0576be5897 runs-nas-n1/na5-merge/pieces.txt`.
- Not verified: nothing on the NAS, no real move; README lacks the NAS lines a guard kept out (chown of the carried bundle, dated put-aside names, the back bundle's own deletes).
