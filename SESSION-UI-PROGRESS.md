# UI track: the whole front end (newest state only; older text is in `SESSION-UI-LOG.md`)

Owns: `internal/server/web`, `internal/viewer/web`, `internal/appshell`, the launcher's `ui.go`/`look.go`/`page.go`, the
window's shell and navigation (with the viewer track for `internal/window`'s native parts). Pages (P7) and the viewer (B9) keep
their Go handlers and data and add the doors U-1 asks for; lent lines in their files are one commit each, read by them. The
design: `DESIGN-ONE-WINDOW.md` (decided 11-16), its picture `design-options/app-look-options.html` ("The combination").

## STATE FOR A TAKE-OVER (U-1 stops here, 11-22; usage 92%, context 93%; the integrator is I-7, session local_78ac6953)
- **Merged into main 2b38b2a (the owner's second folder is built from it):** everything up to F16: the one frame and list, the
  Overview with links, the library (toggle, details panel, hide by right-click, days), chats as conversations, Choose chats as a
  list with sheets, the Mirrors place, Settings rebuilt (controls, modules, copy checks, backup, new chats, alerts, alerts away),
  Accounts/NAS, Queue, Staging, Import, Report, the copy review, alerts and rename, the icon and "TG Archive", the words pass.
- **The owner's whole-app look: SENT** (7 pictures from 2b38b2a, `ui-owner-look/`). Their answer so far: "Good" to the batch idea;
  no other critique of the pictures yet.
- **Listed, waiting for I-7's next batch:**
  - **F17** `wip/ui-clutter` 1e682d3b: the owner's priorities 3 (chats grouped under suggested names: Keep / Not a group / Rename /
    Join / Split / Undo / Hide the group) and 4 (clutter: hide chat/group/post with Undo, the Hidden place, the detector's
    suggestions OFF by default, only marked, Hide / Not clutter, Hide all N behind a question). Holds F17a `wip/ui-groups` 045a0790,
    B9's `wip/b-chatgroups` 88407b14 and `wip/b-clutter` 17fa5d53 (with copies' C34). **SCHEMA chain in catalog.go: alerts-away →
    clutter → chat groups (`chatGroupAfter = clutterSchema`): I-7 sets the numbers.** Lent: pages 63cc50f0, b9246c3a, 290a4b54 (P7
    yes); viewer 88777194 (B9 yes).
  - Pages' QC (`wip/pages-queuecount2`, P7 re-cut): the list's Queue count on viewer pages.
- **With coders (their reports arrive in this session; a fresh UI session should check the branches):**
  - **F18 LISTED** `wip/ui-startscreen` e81357b5 (lent pages f2580505, viewer 7be9d76e: P7/B9 to read; `BRIEF-F18-start-screen.md`): open on the Overview by default,
    never straight onto media (the launcher passed `-first viewer` in `present.go`); a "Start on: Overview / The library / The last
    place" setting in Settings › General (launcher prefs); the solo window opens on the launcher's page; every other way in
    checked; PLUS the library's "Albums / Files" switch (flips the viewer's pref `album_tiles`). Lent commits to pages (launcher)
    and the viewer (window) expected. To list for the batch with F17 when its coder hands back.
  - **F19** `wip/ui-batch` (copy `wt-ui-f19`, from F17 1e682d3b; `BRIEF-F19-batch.md`): batch with search like the old app
    (`wt-v12.32/.../chat-select.js`): select mode + Select all over the search on Choose chats (Group as / Take out / Hide / Show /
    Collect), the group picker with ticks, the library's Select mode, AND the main left list's select mode with an action bar
    (the owner: "also from the main screen, like your mockup"; batch Hide everywhere).
  - **F19 STOPPED (usage), UNLISTED, UNTESTED:** `wip/ui-batch` f74c7cc2 (WIP commit): all four parts written (Choose chats'
    select mode `chatbatch.js`, the group picker with ticks, the library's `libselect.js`, the left list's select mode in
    shell.js/groups.js); NOT done: the viewer's reader of the `as-h` hand-off (planned `carryhide.js` + a hook in viewer `main.js`),
    so Hide / Show again started from the PAGES lead nowhere yet; no named tests written or run, no gofmt/vet, no pictures.
- **Next:** list F18 and F19 when they hand back (check their tests and pictures first: the owner's rule `ui-show-whole-app-only`:
  never send pictures of single pieces; show the whole app once after a batch lands); after F17+F18+F19 merge, rebuild the whole-app
  look in a real window and send it once.
- **Rules learnt:** before every UI listing run by name server `-run 'TestAssets|Security|Mutations|TestEmptyCatalogue'` and viewer
  `-run 'TestWall|TestHomeDevice|TestLAN|Security'`; every asset under 600 lines; never a host or port in an asset; the viewer's
  outbound reads are pinned (pagescounts.go, shelllive.go: B9's wall); timing tests only on the integrator's quiet PC; the
  integrator squash-merges, so check "carried" by content (merge-tree), not ancestry. Pictures only of own try windows
  (`runs-ui-1/shot.ps1`, `uiclick.ps1`, `try-final.sh`, `try-preview.sh`); the owner's real window is open.
- **Open, not started:** B9's one-client follow-up (theirs); pages' Go-side words pass (theirs); a "Read it now" for Saved Messages
  was declined (a new kind of Telegram request needs its cost measured and the owner's OK); the viewer's act.js is 799 lines (no
  size test there; split when next touched).
