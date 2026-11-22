# Independent review of K24, the brought-in account and the old library root (Core, K-6, 2026-11-22)

You review `wip/core-oldroot` at 75c22c19 against 6aa225fb in
`C:\Users\trabi\Claude\Projects\Telegram\repo-archiver\archiver`. You did not write it; find what is wrong. Read:
the brief `BRIEF-K24-broughtin-account-oldroot.md`, the design `DESIGN-UNIFIED-ARCHIVE.md` (sections 3 to 5) and
`DIGEST-LESSONS.md` in `C:\Users\trabi\Claude\Projects\Telegram`; the coder's report
`archiver/docs/progress/core-oldroot-REPORT.md` on the branch; then the whole difference.

**Where:** a detached scratch copy: from `C:\Users\trabi\Claude\Projects\Telegram`,
`git -C repo-archiver worktree add --detach ../wt-core-oldroot-review 75c22c19`. Never edit the coder's copy or a
branch; never commit or push. Probes in a folder of yours by `go test -overlay` (or uncommitted in the scratch copy).
Every go command through `bash /c/Users/trabi/Claude/Projects/Telegram/runs-core-k5/go1.sh <folder> ...`. The lock is
busy, so expect waits; 97 or 98 means try again. Named tests only; never the whole `internal/collector` or
`internal/catalog`; no race detector; no Docker. Invented data only; never touch a running program,
`C:\Users\trabi\tgarchive-app`, `E:\` or the NAS.

**The house rules this must keep** (CLAUDE.md "Files"): only exact evidence (the same Telegram file, the same
SHA-256) may skip a file; a probable copy is held, never skipped; never download from a source the owner did not
choose; nothing writes, moves or deletes in the old library.

**Look hardest at:**
1. **A live account's file lost or held wrongly:** any order of events in which a file a live account wants ends up
   parked (`ReasonBroughtIn`), skipped or never claimed. Cases: the old account catalogues it first, then a live
   account; both in one batch; a live chat switched off and on; an owner's release or "unskip"; the live account
   deleted (the coder's note); a file held as a probable copy that the trigger re-holds or releases; a file in
   transfer. And the reverse: anything the old account reaches becoming wanted for it, claimed, or counted as
   waiting anywhere (the Supply, lane counts, the Overview, the stall rule).
2. **The old bytes as exact evidence:** a live account's want of the same Telegram file, or a file whose SHA-256 the
   old archive holds, is still ended exactly as today's saved-file rungs end it (rung 2, the link at save); no gate
   hides them. A probe for each.
3. **The triggers and the rebuilt view** (`schema_broughtin.go`): their cost at scale. Measure on invented data the
   shape of a bring-in: 240,000 media rows and 300,000 reach rows for the old account written in the bring-in's
   chunks, then 10,000 rows for a live account, against the head without the step. Give time per thousand rows. The
   step itself: number in two constants, refusal of other versions, rollback; the view's other readers unchanged.
4. **The old root:** `libroot.Resolve`/`JoinUnder` against climbing paths in every spelling (`..`, `.\`, mixed
   slashes, `C:` relative, UNC `\\?\`, trailing dots and spaces Windows strips, device names, a symbolic link inside
   the old library that points out); `SetOldLibraryRoot`'s overlap check with the library and staging (case, trailing
   separator, `\\?\` forms, a junction); every writer (copier, linker, orphan sweep, backup) shown to refuse it.
5. **The lock:** `catlock` and `HoldCollectorLock` against the collector's own (the same file whatever the
   catalogue path's spelling? Say what happens if the bring-in spells the path differently); release on panic.
6. **Changes in other tracks' files** (the client's `schema_act.go`, the server's three files, the mirror's policy,
   `supply.HandOver`): correct, and nothing else changed there.

**Report:** `C:\Users\trabi\Claude\Projects\Telegram\REVIEW-K24-oldroot.md`: the verdict first ("may be listed",
"may be listed after these fixes: ...", or "not to be listed"), then each finding with must / should / minor,
CONFIRMED (a probe shows it) or PLAUSIBLE, file and line, a one-sentence fix; the probes run and their results; the
measured trigger cost. Your last message: the same, short. Then remove your scratch copy
(`git -C repo-archiver worktree remove --force ../wt-core-oldroot-review`).
