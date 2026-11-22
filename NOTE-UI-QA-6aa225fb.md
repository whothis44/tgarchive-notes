# The QA of 6aa225fb (`reports-qa/QA-6aa225fb.md`) against the UI pieces (U-1, 11-22)

| # | Finding | State |
|---|---|---|
| 1 | No keys: first start is a dead end | **F2** (window opens on the library, one-line notice) + pages' **SW** (the cause in words). Pages': the window closed and opened 3 times at start (launcher restarts on new addresses). |
| 2 | Overview numbers not links | **W3 + F3** (every number a link; tiles take the counts after F1's fix). |
| 3 | Two lists, two headers, two Settings | **F1** (one list, one strip, one Settings with "Library display"). |
| 4 | Program page: no list, raw link, stale words | Partly F2 (launcher page in the frame's strip, "Back to the library"). Owed: **F9** (the Program page inside the frame with the list); words "Closing the window does not stop the program" are pages'. |
| 5 | No notification-area icon | Owed: pages (launcher's tray logic, Open/Quit) using F8's icon resource; look mine. Asked of P7. |
| 6 | White title bar, no icon, "Archive viewer", no pill in title, "Stopped" vs "Running" | Icon and title: **F8**. Owed **F9**: dark title bar (DWM immersive dark mode, lent to the viewer's window); the pill's words (collecting / not collecting: why) agreeing with the launcher's state. |
| 7 | Quit asks in a browser dialog | Owed **F9**: the app's own dialog (or the window's task dialog), never `confirm()`. |
| 8 | Setup: error out of sight, two-window questions, long words | Partly **F6** (steps; error at its step). Owed **F9/F7**: the "viewer window/browser/none" and "pages open window/browser" questions out of the setup (into Settings › Program, advanced), words cut. |
| 9 | Folder box centred on a hidden 1x1 owner, opens in Documents | Owed: pages (folderbox: owner = the app's window, start at the field's folder). Asked of P7. |
| 10 | No counts in the list; no type toggle; grid by month | Counts: pages' **S1** + viewer's **U2**. Toggle: **F4**. Grid by day: owed (**F9**: day headers in the library, months as the jump list). |
| 11 | Numbers disagree (posts vs files, gone vs deleted); wrong empty state on Deleted | Owed **F7**: units said on every count ("files", "posts"), "Gone" vs "Deleted on Telegram" explained in one line; the Deleted view's own empty state. |
| 12 | Scrollbars in scrollbars | **F4** removed the filter column; F1's chat list scrolls inside the list by design. Owed **F9**: check the library's two right-edge bars on the combined tree; the chat list's scroller start. |
| 13 | Big blue Start first on every page | **ui-all** removes the old head bar (Start lives on the Overview's Now and the pill); owed F9: Start disabled with words when no account is signed in; "Open viewer" gone. |
| 14 | Duplicate chats look the same | Owed **F9**: the account's initials/label on a chat row when the archive has more than one account. |
| 15 | Wordy pages | Owed **F7** (the words pass). |
| 16 | README out of date | Pages' (deploy/folder). Asked of P7. |

Order: `wip/ui-all` (F6's coder, combining F1-F8 and SW) first; then **F9** (the frame's QA round) and **F7** (words) on it.
