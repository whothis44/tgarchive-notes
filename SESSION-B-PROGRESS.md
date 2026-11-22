# Viewer and bring-in track: current state (session B9; older text in `SESSION-B-LOG.md`, nobody needs to read it)

## STATE FOR A TAKE-OVER (B9, 11-22, the week's usage at 99%: everything merged or listed; nothing runs)
A successor starts from this block alone. No agent, script or window of this track runs.
- **Owns:** `internal/viewer` Go (handlers, index, data), `internal/window` native parts, `internal/bringin`,
  `cmd/tgarchive-bringin`, `cmd/tgarchive-window`, `cmd/tgarchive/viewer.go`. Since 11-22, with the UI and pages
  sessions archived, the integrator (I-7) has also given this track front-end and launcher pieces (F19, R1v's
  drawing, W9, V1).
- **MERGED (main 84e98ca, 11-22):** W1v (the one list), U2 (old archive or new, as data), the bring-in into the app's
  own catalogue (`-into-app`, with Core's K24), the list's counts (`lib:new`, `lib:first`, `lib:all`, `lib:copies`,
  `lib:oldnew`, `alerts`, `queue`), ACv (alert clicks), G1v chat groups (catalogue overrides, one step), CL1v clutter
  suggestions (copies' score, shown never applied), F19 batch selection with the `as-h` reader, R1v reactions and
  service actions (data and drawing), A1V (the chat box shows only message kinds), W9 (the window's end logged on
  every path; a killed launcher reported at the next start), V1 (version info and a manifest in every Windows
  program), and the test fixes `wip/b-chatconv-j`, `wip/b-react-j`.
- **Check whether merged:** MCv `wip/b-mirrorcount` f1ee3d3d (the `mirrors` count; after pages' MC): see `MERGE-QUEUE.md`.
- **NEXT, when the owner or the next integrator says so:**
  1. The bring-in's trial on a COPY of the owner's catalogue in a folder of our own (no sign-in, LOCALAPPDATA
     redirected), through the launcher's step (`CONTRACT-bringin-step.md`); counts only to the integrator, then the
     owner; the real step is the owner's (the old app stopped for good on 11-21).
  2. One loopback client for the pages' reads: `pagesGet(ctx, path)` in `pagescounts.go` with fixed paths
     (api/counts, api/live), `shelllive.go` calling it, the viewer's wall back to one allowed outbound file; keep
     `pagesCountKeys` (mirrors, alerts, queue).
  3. Look at the owner's window after the switch to the build with V1 (the launcher and window now declare
     PerMonitorV2 DPI in their manifest: nobody has seen the real window with it).
  4. Open with the client track: "send again" is still offered on a sendfile/upload whose caption was cleared.
- **Copies on disk (this track's; remove each after a check that it is clean and equal to its pushed branch):**
  wt-b-onelist, wt-b-oldnew, wt-b-unified, wt-b-alertclicks, wt-b-chatgroups, wt-b-clutter, wt-b-react, wt-b-react-j,
  wt-b-chatconv-j, wt-b-a1viewer, wt-b-windowend, wt-b-versioninfo, wt-ui-f19 (the UI track's, finished here), and the
  reviewers' scratch copies wt-b9-review-W1v-scratch, wt-b9-review-U1-scratch (probes uncommitted).
- **Tools:** `runs-b9/b9-scripts/save.sh` (progress, queue, board and the notes commit); the go lock
  `runs-b7/shell/scripts/gorun.sh` (ABSOLUTE output paths); the window's joined self-check `runs-b9/look/selfcheck3.sh`.
- **Lessons:** run `TestWall*` by name in every hand-back that touches internal/viewer; tests that fake an older
  catalogue label it with the exported step constant (`catalog.MadeBySchema`, `catalog.ReactSchema`), never
  `SchemaVersion-1`; a timing test on a loaded PC means nothing; give build commands absolute output paths; messages
  go direct (the board's message list ended 11-21).
