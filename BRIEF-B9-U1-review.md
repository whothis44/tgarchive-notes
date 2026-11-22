# Independent review: U1, the bring-in into the app's own catalogue (session B9, 11-21)

You are an independent Opus reviewer. Review the branch `wip/b-unified` (head 04000899) against the main head
af4ca40: `git -C C:\Users\trabi\Claude\Projects\Telegram\wt-b-unified diff af4ca40e..04000899`. Do not edit that
copy. For probes, make your own scratch worktree from 04000899
(`git -C C:\Users\trabi\Claude\Projects\Telegram\repo-archiver worktree add --detach C:\Users\trabi\Claude\Projects\Telegram\wt-b9-review-U1-scratch 04000899`)
and work only there; commit nothing, push nothing.

## Rules
- **Invented data only.** Never open the owner's real catalogue, the old app's database, `E:\T\tg-dl`,
  `%LOCALAPPDATA%\tgarchive*` or any copy of them, not even read-only. Print counts and timings only.
- Every `go` command through the lock, one at a time:
  `bash /c/Users/trabi/Claude/Projects/Telegram/runs-b7/shell/scripts/gorun.sh <dir> go test ./internal/bringin -run 'Name' -count=1`.
  Named tests only; never `internal/bringin` whole (a slow scale test), no race detector. Another reviewer
  shares the lock: wait your turn.

## What the piece is meant to do (the goal, not its author's claims)
The owner wants ONE archive: the old app's archive brought into the app's own live catalogue as an account of
its own that is never signed in, so that the app's copy checks run against what the old app downloaded. The
design note is `C:\Users\trabi\Claude\Projects\Telegram\DESIGN-UNIFIED-ARCHIVE.md` (sections 3 and 5 are this
piece); the brief the coder worked from is `BRIEF-B9-U1-bringin-unified.md` in the same folder. The bring-in
will one day run against the owner's real catalogue, where the app has made its own decisions and the owner
has given words. **The worst outcome is that it changes something the app or the owner decided, switches a
chat's collecting off or on for the app's accounts, or makes the app download, skip or release a file it
would not have.** The copy rules bind it: only exact evidence (the same Telegram file, the same SHA-256,
every part hash) may skip a file; a probable copy is held, never skipped; nothing is downloaded from a source
the owner did not choose. One decision was made by the session on purpose: a plainly WANTED file of the app
becomes SAVED by the old app's bytes when it is the same Telegram file; judge whether its conditions are tight.

## Look hardest at
1. Every path by which the mode writes to a catalogue it did not make: the five rules, and anything that can
   change the app's chats, wants, holds, edges, files, places, accounts or settings. Prove or disprove "it
   only adds" with probes on invented catalogues (the package's test helpers make both databases).
2. The guard that stops a chunk if a state of the app changed (`ErrWouldChange`): can a change slip past it
   (a state it does not read, a change after its second read, a trigger's side effect such as the change
   log, the lane table, the chat counters)?
3. The refusals: the schema check (opening an older or newer app catalogue read-write would migrate it), a
   catalogue made by the bring-in's other mode, an account number that no longer names the bring-in's
   account, an app account with the same Telegram user.
4. The dry run: does it really write nothing (and what it leaves beside the file)?
5. Cutting a run at any point and running again; a second run writing nothing.
6. Privacy of its output (counts and fixed words only; the package has a printer guard).
7. Anything else: correctness first.

## Output
Write the review to `C:\Users\trabi\Claude\Projects\Telegram\REVIEW-B9-U1-bringin-unified.md`: findings
numbered, each with its weight (must fix / should fix / minor), the file and line, what goes wrong and how you
know (a probe with its numbers, or the lines read); then one line: "may be listed", "may be listed after these
fixes: N, M", or "not to be listed". Your final message: that line and the count of findings by weight.
