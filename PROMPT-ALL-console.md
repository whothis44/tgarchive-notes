# Everything that's left, in one run (on the owner's Console credit, through the Agent SDK script)

**The owner is not watching: do it all in ONE go, without stopping.** Merge each piece as it is finished, so a later
failure never undoes an earlier one. Where a step says "stop", skip that step, say why in the final report, and go on
with the next. Give ONE report at the end.

## Step A: merge NA5 (the owner approved it by starting this run, 11-22)
NA5 (the move to the NAS, `wip/nas-move` e11fb3e5) is finished and reviewed twice; the re-check says "may be listed"
(`REVIEW-NA5-move-2.md`). Its run stopped before the merge only to ask the owner. See the section "NA5 on Console
credits" in `SESSION-11-PROGRESS.md`. Its tested tree is `ba698d48682966d1d498505214aeda0576be5897`, on main 2c5d21a0.
1. Check that main is still `2c5d21a0` (`git -C repo-archiver rev-parse --short=8 HEAD`) and that the main tree is clean.
   If main has moved, do not use the prepared pieces: rebuild NA5's piece on the new head as `START-INTEGRATOR.md`
   says, and run its whole tests again.
2. Merge: `bash /c/Users/trabi/Claude/Projects/Telegram/ix-tools/merge-batch.sh 2c5d21a0 ba698d48682966d1d498505214aeda0576be5897 /c/Users/trabi/Claude/Projects/Telegram/runs-nas-n1/na5-merge/pieces.txt`
   (its last line must be "MERGE-BATCH: done ..."), then `bash /c/Users/trabi/Claude/Projects/Telegram/runs-int-i6/folder-next.sh`.
3. One line under "NA5 on Console credits" in `SESSION-11-PROGRESS.md`: merged, the head.
4. In the final report, repeat the owner's move steps from that section exactly, and remind them: nothing has moved;
   the move starts only when they run `tgarchive-nasmove out` themselves, after creating the app's regular NAS user.

## Step B: everything in `PROMPT-FOLLOWUPS-console.md`
Read it now and do all its items, in its order (00, 01, 02, 03, 0 to 0z, then 1 to 11), by its rules. An earlier
follow-ups run was stopped early: first check what it already merged (`git -C repo-archiver log --oneline 2c5d21a0..HEAD`,
the heading "Follow-ups on Console credits" in `SESSION-11-PROGRESS.md`, `runs-agent/`) and do only what is missing.

## At the end
`bash runs-int-i6/folder-next.sh` once more, the notes as the follow-ups prompt says, `bash ix-tools/notes-backup/backup.sh`,
and the one report: what merged (heads), what was left and why, the UI audit's summary, the owner's NAS steps.
