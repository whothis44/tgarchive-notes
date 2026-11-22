# Brief: the independent review of L1, the launcher's bring-in step and door F2 (pages, P7, 2026-11-22)

Read first: `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-P7-review-rules.md` (binding). TEMP, TMP, LOCALAPPDATA,
APPDATA of every test process in `C:\Users\trabi\AppData\Local\Temp\p7-l1rev\` (outside any git copy). No window on
the screen (stand-ins only). Invented data only; never the owner's folder, catalogue or `E:\`.

**The piece:** `wip/pages-bringin` 72117787 (from G18d d46aa8f6): `git diff d46aa8f6 72117787`. The ask:
`BRIEF-L1-bringin-step.md`; the contracts it is built against: `CONTRACT-bringin-step.md`; the coder's report:
`archiver/docs/progress/pages-bringin-REPORT.md`. **The step stops the owner's app and runs a program that writes
the owner's catalogue: find any way it runs the bring-in when it should not, writes while the collector or a reader
still holds the catalogue, loses the owner's yes's meaning, leaves the app stopped with nothing to see, or says
something untrue.** Your copy: `git -C C:\Users\trabi\Claude\Projects\Telegram\repo-archiver worktree add --detach ../wt-pages-review-l1-scratch 72117787`.
Report to `C:\Users\trabi\Claude\Projects\Telegram\REVIEW-L1-bringin-step.md`. Wanted within about an hour.

## Questions, in this order
1. **The gate and the yes:** every condition of "offered" against the contract; the yes tied to the counts the
   owner saw (an older page, a second tab, a changed old database or catalogue between the dry run and the run);
   is the run ever started without a dry run of the same inputs just before?
2. **The stop:** the collector, the watchdog, the window AND every read-only opener ended before the run; the
   lock file free; a collector started by the owner during the step (by `tgarchive.exe` a second time, by the
   watchdog's restart): refused or seen? The program's own lock (Core's 1b) is the safety net only.
3. **The run and its end:** every exit code and `@ result` of the contract to fixed words; an unknown one fails
   closed; Cancel sends Ctrl-C and the next run resumes; the app always started again (or the page says why not);
   the program never outlives the launcher (the job object); the longer bound for the first start after a run.
4. **Door F2** (`/api/state`, `/api/bringin`): the CORS rule exactly as the contract (only the launcher's own
   started origins, `Vary: Origin`, GET only), no path or name in any answer; the window started viewer-first when
   the collector cannot start.
5. **The lent commit 8e58ec25** in the UI track's files: only what it says.
6. Anything else: its own number.
