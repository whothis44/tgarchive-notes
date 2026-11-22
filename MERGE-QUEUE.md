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
