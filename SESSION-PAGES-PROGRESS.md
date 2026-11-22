# Pages track: progress (the newest state only; history in `SESSION-PAGES-LOG.md`)

## SESSION P7 (Opus; took the track over 11-21 21:08 from P6). RESUMED 11-22 09:07 for owed work at the owner's word (stopped earlier 08:34 at the integrator's word (the week's usage at 80%))

### State for a take-over (11-22 11:52; P7's context is nearly full: a fresh session takes over from here)
- **Nothing of pages runs; no agent of P7 works.** Reports go to the integrator **I-7** (a direct message to "Integrator I-7").
  The front end is the UI track's (U-1, now archived); pages keeps the Go handlers and data, the launcher's logic,
  `deploy/folder`, the update command.
- **Listed, waiting for I-7's next batch** (`MERGE-QUEUE.md`): LT `wip/pages-lintest` 135d44f4 (two Linux race-run test fixes),
  QC2 `wip/pages-queuecount2` feb1cfe1, OS `wip/pages-oldsignin` 43e6eedb (after K24) ("queue" in /api/counts; replaces QC), WP `wip/pages-words` 69125bf6 (the words pass).
  All from the head 2b38b2a, merge-tree clean. Everything else of P7's night is merged or carried (the log lists the carried).
- **Lent commits read and agreed:** U-1's F17a chat groups (`wip/ui-groups` 045a0790: 63cc50f0, b9246c3a, 290a4b54) and F18's
  launcher commit f2580505 (`wip/ui-startscreen` e81357b5). U-1 is archived: a fix to either goes on a pages commit on top.
- **Owed:** nothing. The sign-in refusal of a brought-in account is built and listed as OS `wip/pages-oldsignin` 43e6eedb (after K24).
- **Contracts:** `CONTRACT-bringin-step.md` (the bring-in program, Core's stop/lock/mark, U-1's F2; the reference is
  `internal/bringin/intoexit.go`), `NOTE-N4-collector-side.md` (NAS doors).
- **Rules learnt here:** every time from `date`; a branch on another track's unsquashed branch conflicts after a squash: re-cut
  our own diff onto the new head; words about copies are read by the copies track first (a three-places match is linked, not
  downloaded); on 11-22 also: a piece touching assets runs `server -run 'TestAssets|Security'` (CLAUDE.md).
- Tools: `runs-pages-p6` (`go1.sh`, `run-listing.sh`); Linux race runs in Docker `golang:1.27.3` (no cgo on this PC).
- 11:58: resumed at the owner's word (I-7): the owed sign-in refusal built now on K24's branch + 2b38b2a (`wip/pages-oldsignin`, LT's coder),
  to merge after K24. QC2 and WP in I-7's next UI batch.
- 12:02: OS LISTED (43e6eedb, after K24). Every owed item is now built and listed. Nothing runs.
- 12:18: LT merged (head 9cb4edc, with K24 and the bring-in); OS, QC2, WP in I-7's UI batch now. PL's condition (B9's bring-in on the head) is met.
