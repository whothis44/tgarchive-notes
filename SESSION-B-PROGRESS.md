# Viewer and bring-in track: current state (session B9; older text in `SESSION-B-LOG.md`, nobody needs to read it)

## STATE FOR A TAKE-OVER (B9, 11-22, usage 92%: everything listed or carried; nothing runs)
A successor starts from this block alone. Nothing of this track runs: no agent, no script, no window.
- **Owns since 11-21:** `internal/viewer` Go (handlers, index, data; NOT `web`: the UI track U-1 owns the front end,
  `appshell` and `internal/viewer/web`), `internal/window` native parts (with U-1), `internal/bringin`,
  `cmd/tgarchive-bringin`, `cmd/tgarchive-window`, `cmd/tgarchive/viewer.go`. Doors for U-1 by its message.
- **MERGED:** the bring-in U1 with K24 (main 9cb4edc, 11-22), W1v (the one list: appshell on the viewer's pages) and U2 (old archive or new, as data: `old`,
  `old_checked`, `old_seen`, `old=` filter, `/api/oldnew`, list counts lib:new/first/oldnew).
- **LISTED in `MERGE-QUEUE.md`:**
  - **U1** `wip/b-unified2` 9bf12326: the bring-in into the app's OWN catalogue (`-into-app`), merge RIGHT AFTER Core's
    K24 `wip/core-oldroot` cd91afa9 (it holds it). Commands `plan` (exact-evidence totals), `run`, `counts`, `state`;
    the launcher's contract in `internal/bringin/intoexit.go` (exit 0-5, `@ progress/count/result`); lock taken with
    `catlock.Acquire` before the catalogue is opened; `-old-library`, `-staging`. One independent review and a second
    pass, all fixed (`REVIEW-B9-U1-bringin-unified.md`). Never run on a real catalogue.
  - **MCv** `wip/b-mirrorcount` f1ee3d3d: list counts `mirrors` (from the pages' `/api/counts`, one pinned file
    `pagescounts.go`), `lib:all`, `lib:copies`; after pages' MC.
  - **ACv** `wip/b-alertclicks` b4d22edc: `made_by: "alerts"` in the chat's click data, no send-again or verdict
    offers on an alert; carried by U-1's F16 (`wip/ui-alertsaway`), no separate merge.
- **NEW 11-22 (the owner's priorities via I-7), `DESIGN-B9-groups-clutter.md`:** (3) chat groups: **G1v LISTED** (`wip/b-chatgroups` 88407b14, one schema step to renumber at the merge): the name rule, the overrides' table (one schema step), the doors, `/api/chats` data, a FEATURES row; the look and the write route: U-1 (asked). Store DECIDED: the catalogue (U-1 agreed); plus `DismissSuggestedGroup` and `why`/`by` per member. (4) clutter: seam agreed with C7 (`c_clutter(tg_media_id, score, why, at)`, the media's own change logged) and U-1 (the owner's word: "shown, never applied": a score never hides; `clutter_suggested`, threshold pref 60, switch OFF by default, `?clutter=suggested`, `/api/not-clutter`, `lib:clutter`): **CL1v LISTED** (`wip/b-clutter` 17fa5d53, after copies' C34).
- **Since 07:30 (the owner's priorities 3 and 4, `DESIGN-B9-groups-clutter.md`):**
  - **G1v** chat groups `wip/b-chatgroups` 88407b14 (the rule `catalog.GroupKey`, the owner's overrides in the
    catalogue `chat_group_word`: ONE schema step, numbered by I-7; doors for the pages' write route; `/api/chatgroups`)
    and **CL1v** clutter suggested `wip/b-clutter` 17fa5d53 (copies' `c_clutter_score` shown as a suggestion only,
    switch off by default, threshold 70, `/api/not-clutter`, `lib:clutter` = tiles of `clutter=suggested,show`):
    both CARRIED to I-7 inside U-1's F17 `wip/ui-clutter` with their front end.
  - The bring-in: I-7 applies `cd91afa9..9bf12326` itself after K24's `wip/core-oldroot-j`: leave `wip/b-unified2`.
  - Read and approved lent commits in this track's files: U-1's 4c038a20 (window probe), 3aae584c and 0cb09625
    (pages' counts keys and keep), 88777194 (test), 7be9d76e (F18: the window's last place). U-1 is archived: a fix
    to F18's window lines goes on a commit of ours on top of `wip/ui-startscreen` e81357b5.
- **F19 LISTED** (`wip/ui-batch` 57821cff, after the current UI batch). Was: (the UI track's batch selection, U-1 archived): with one coder of mine on `wip/ui-batch` (copy wt-ui-f19, from f74c7cc2; `BRIEF-B9-F19-finish.md`): the viewer's `as-h` reader (never acting on the address alone) and F19's tests; listed to I-7 when back; goes in the batch after the current UI batch.
- **R1v LISTED** (`wip/b-react` d5ab0b8b, after K30; overlaps `wip/b-chatconv-j` in chatconv_f5_test.go: keep both). Was: (reactions and service actions, Core's K30): with a coder on `wip/b-react` (copy wt-b-react, from K30 36e362e0; `BRIEF-B9-R1-reactions.md`): the data in the chat and post answers AND the drawing (I-7's word: counts under a message, one plain line per service action, nothing when absent); listed together.
- **`wip/b-chatconv-j` c73a29eb** (on I-7's join tip 2a8d04b5): the chat-page tests follow F17 (I-7's blocker; test file only).
- **W9 LISTED** (`wip/b-windowend` dd71bc83: the window's end logged on every path; the launcher's own kill reported at its next start).
- **Integrator: I-7** (`local_78ac6953-2e70-4c12-a371-4f255f71e85c`): listings and reports go there.
- **NEXT, in order, when the owner or the next integrator says so:**
  1. The bring-in's trial on a COPY of the owner's catalogue in a folder of our own (no sign-in, LOCALAPPDATA
     redirected), through pages' launcher step (`CONTRACT-bringin-step.md`); counts only to the integrator, then the
     owner. Then the real step is the owner's (the old app stopped for good on 11-21).
  2. One loopback client for the pages' reads after U-1's `wip/ui-qa2` and `wip/ui-viewercounts` merge:
     `pagesGet(ctx, path)` in `pagescounts.go` with fixed paths (api/counts, api/live), `shelllive.go` calling it, the
     wall back to one allowed file; keep `pagesCountKeys` (mirrors, alerts, queue). Agreed with U-1.
  3. DONE as A1V (`wip/b-a1viewer` 7855f795, listed). Was: when the client track's A1 (`wip/client-chat`) merges: the conversation's click data lists only message kinds
     (`look`, `join`, `leave`, `mute` go to the chat's state; `sendfile` is a message). A-1's message; the drawing is U-1's.
- **Copies on disk:** `wt-b-onelist` (merged), `wt-b-oldnew` (U2 merged; MCv's branch was made there),
  `wt-b-unified` (U1, listed), `wt-b-alertclicks` (ACv, in F16), `wt-b-chatgroups` (G1v), `wt-b-clutter` (CL1v), `wt-b9-review-W1v-scratch` and
  `wt-b9-review-U1-scratch` (reviewers', probes uncommitted: may go after their reviews are kept). Remove merged
  copies after a check that each is clean and equal to its pushed branch.
- **Tools:** `runs-b9/b9-scripts/save.sh` (progress, queue, board row and the notes commit); the go lock
  `runs-b7/shell/scripts/gorun.sh` (give it ABSOLUTE output paths: a relative `-o` lands inside the copy, and on
  11-22 a self-check ran an old exe for that reason); the window's joined self-check `runs-b9/look/selfcheck3.sh`.
- **Lessons:** run TestWall* by name in every hand-back that touches internal/viewer (G1v's first head failed it); messages go direct (board messages ended 11-21 22:24); a peer's head merged into a listed branch
  moves the entry: update it the same hour; a timing test on a loaded PC means nothing (11-22: the 40 ms was load).
