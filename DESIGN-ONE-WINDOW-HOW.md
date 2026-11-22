# The one window: how it is built (the joint note under `DESIGN-ONE-WINDOW.md`)

**Written by pages (session P6), 11-16 18:30, as the integrator's messages 152 and 153 ask. State: a
PROPOSAL of the pages track, complete enough to brief from on the pages' side; the viewer's side has four
questions at the end that only the viewer's code answers (B6 or its successor: a few lines each). Nothing
is briefed from it before the first start's faults (board message 150 a to e) are listed.**

Read by me for it: `DESIGN-ONE-WINDOW.md`; `cmd/tgarchive-window/main.go`'s head and exit codes; the
launcher's `start.go` (`viewerSpec`, `collectorArgs`) and `present.go` (the window's start and end);
`internal/server/server.go` and `internal/viewer/server.go` (both answer `frame-ancestors 'none'` and
`X-Frame-Options: DENY`); the viewer's board messages 113, 116, 117, 121 (the window's contract).
NOT read: `internal/window` beyond its file list, the viewer's page scripts, the picture's HTML.

## 1. What exists, in one paragraph
Two servers, on purpose: the collector serves the app's pages (it is in the VPN's list, holds the
sign-in, writes the catalogue; its pages carry a page token), and the viewer serves the library and the
chats read-only from the same catalogue (no Telegram code, never in the VPN's list, works with no
collector at all: the old archive). Two windows today, both `tgarchive-window.exe`: the viewer's (the
viewer in-process on a free port, mpv kept for every video) and the pages' (`-pages`, any named
127.0.0.1 address, no viewer, no mpv). The launcher starts both. **The two servers stay** (the VPN rule
and the import wall need them); what becomes one is the window, the navigation and the look.

## 2. Who owns what (decided here unless the viewer says a point cannot hold)
| Part | Owner | Where |
|---|---|---|
| **The window program** (the one window, its gate, mpv, the app's own title bar, no reload / back / zoom / frame selection, the exit code that says "the person closed it") | **viewer** | `internal/window`, `cmd/tgarchive-window` |
| **The shell: the left list, the state pill, the frame's look, the empty-state piece every page uses** | **pages** | a NEW small package `internal/appshell` (assets and one Go builder; imports the catalogue only), mounted by BOTH servers |
| The places on the right: Overview, Queue, Staging, Mirrors, Accounts, Settings | pages | `internal/server` (their content as it is) |
| The places on the right: Saved Messages and every chat as a conversation, the library's views, the details panel, Changes, the review | viewer | `internal/viewer` (their content as it is) |
| Starting and ending: ONE window, the close that asks, the icon in the notification area, the folders in Settings | pages | `internal/launcher` |

## 3. One navigation over two servers: the same list on every page, plain links between them
**No frame inside a frame, no proxy, no merged server.** Every page of either server is drawn as: the
shell (list on the left, the pill above) and its own content on the right. The shell is the SAME code
and the same look on both servers, because both embed `internal/appshell`:
- its assets (one stylesheet, one script, served by each server from its own address: `script-src 'self'`
  stays true on both);
- one Go builder, `appshell.List(ctx, catalogue, options)`, that reads the list from the catalogue both
  servers already have open: Overview; Saved Messages (the account's own chat); the library's views;
  the chats by newest activity, each with its state in a few words (collecting, mirrored, not
  collected, waiting: from the chat's and the mirror's rows); Settings and Accounts at the foot. Each
  server answers it at the same path (`/api/shell`), so the list is identical whichever server drew
  the page, and neither server asks the other for it;
- every entry is a plain link to the server that owns that place. A click on a place of the other
  server is an ordinary navigation of the window to the other address. **No address shows** (the window
  has no address bar; the gate already lets the window show every address it was started with), and
  in the browser fallback the same links simply work as two local addresses.
- The script paints the list from what it kept of the last answer (per address) before it asks again,
  and keeps the list's scroll place and the selected entry across a navigation, so that a change of
  server does not look like a page load. (If, once built, the change of server is still visible to the
  owner, the list can move into a frame of the window later without touching any place's content: that
  is the fallback, not the plan.)
- **What each server must know of the other:** the pages get the viewer's address as today
  (`-viewer-url`); the viewer gets the pages' address from the door file it already reads (the door's
  address IS the collector's listener), and the launcher's page from one start flag. A place whose
  server does not answer is shown in the list as what it is ("The collector is not running", with the
  way to start it), never as a dead link.
- **The counts beside the library's views** (New, Deleted on Telegram, First seen here, Probable
  copies) are the viewer's (its index has them in memory): the viewer's `/api/shell` carries them; the
  pages' `/api/shell` asks the viewer's small counts read once on the server's side (this PC only, a
  bound of 200 ms, kept for some seconds) and shows the views without counts when it does not answer.
  **The pill** (collecting, the speed, how many wait, the VPN) is the collector's: the pages have it;
  the viewer asks the collector's state read the same way. Nothing reads the library on the NAS for
  either.
- **The Overview's numbers** are links like every other: each to the owning server's place with its
  filter in the address (`.../library?view=new`, `.../queue?show=waiting`, `.../review`). The viewer
  names its filter addresses once (question 3 below); a number with no such address is not a link.

## 4. One window: which program, and what the launcher starts
**The one window is the viewer's window** (it alone has mpv and the viewer in-process), started ONCE by
the launcher with the other two addresses named to its gate (the pages', the launcher's own page). So:
- a normal start: the launcher starts the watchdog and the collector as today, then the ONE window on
  the app's start place (the Overview when the collector's pages answer; the library when they do
  not: the library stays usable while the collector cannot start, with the reason in the list);
- the first start and "Change the folders": no catalogue exists yet, so the launcher shows its own
  setup page in the window's present pages mode, and starts the one window when the setup is saved and
  the catalogue is there (one change of window, once, at the setup);
- **the second window is gone**, and with it the fault class of the first real start (two windows of
  one program started seconds apart). The setting "viewer: window or browser" becomes "the app: window
  or browser".
- **Closing the window** ends with the window program's own code for "closed by the person"; the
  launcher then asks once ("keep collecting, or quit"; remembered; changed in Settings) and, when it
  keeps collecting, shows its icon in the notification area with Open and Quit. (G18 builds the
  question now, asked every time, in the present look.)
- **The old archive's window** is the same window started without a launcher (as `b-window.cmd` does):
  the same list from the same builder, with no Overview numbers, no pill and no text box; the list's
  head says in one line that nothing collects this archive.

## 5. The order of pieces: each lands something the owner can open
1. **The faults of the first real start, in the present look** (pages; with coders): G17 the pages on
   an empty catalogue, G18 the window that ended by itself and the close that asks, G19 changing the
   folders and a setup that says what it sees.
2. **"W1", the shell** (pages builds `internal/appshell` and mounts it on its own pages; the viewer
   mounts it on its pages: its own small piece, or lent lines if its session cannot): the list on the
   left on every page of both servers, the present top bars gone, an empty state on every place. The
   owner opens: one look, one list, both servers' places behind it. Still two windows if piece 3 is
   not in: the list already leads everywhere.
3. **"W2", one window** (the viewer: the window takes the named addresses beside its own viewer, a
   fixed address for the viewer, the title bar, the close's exit code; pages: the launcher starts one
   window, the close's question remembered, the icon in the notification area). The owner opens: one
   program, one window, a close that asks.
4. **"W3", the Overview as the dashboard, every number a link** (pages; the viewer's filter addresses).
5. **"W4", the library's views in the list with their counts, and the details panel** (viewer).
Pieces 2 and 3 do not wait for each other; 4 and 5 need 2. **Before the owner is told any of them is
ready: opened as the owner opens it (the folder's program, built from one head), on a new empty
catalogue and on a filled invented one, every place of the list clicked once; who did it and what was
seen is written in the entry.**

## 6. What is reused as it is
The library's grid, chips and toggles; the chat page with its text box and the door behind it; the
Changes page and the review; the Queue, Staging, Mirrors, Accounts and Settings pages' content and
every route and guard under them; the window's gate; the launcher's start, stop and setup. What is
replaced: both servers' top bars (by the shell), the launcher's second window, the Chats page as a
SEPARATE list of chats (its switches, a chat's Collect, its topics, "ask how large", "Mirror this
chat", move to the chat's own place as its "collecting" panel; until W1 is in, it stays as it is).

## 7. Four questions only the viewer's code answers (B6 or its successor; a few lines each, on the board)
1. Can the viewer's window show, as places of its own navigation, the two other named addresses (the
   pages', the launcher's) through its gate, with the viewer in-process and mpv as today; and can it be
   given a fixed address for its own viewer (the pages link to it)? If the cheaper way is the reverse
   (the pages mode gaining the in-process viewer and mpv), say so: the launcher follows either.
2. Does anything in the viewer's page scripts assume it is the only top bar (a layout that would fight
   a list on the left), and which of its pages are a "place" in the list?
3. The filter addresses for the Overview's links: New, Deleted on Telegram, First seen here, Probable
   copies, the review; and the account's own chat (Saved Messages).
4. The exit code for "the person closed the window" (today 0 is also "already open, brought to the
   front"), and what the title bar can be made to carry (the pill).

## 8. One thing for Core
Saved Messages is the first entry of the list on a NEW catalogue: is the account's own chat a chat row
there, and is it read without the owner choosing it? (The owner looked for it at the first start and
did not find it.) The list shows it from the first minute if the row exists; if it does not, the
reader's first chat list must make it.

## 9. Answered by the viewer (session B7, board messages 161, 162 and 164 of 11-16; added by pages 18:56)
B7 agrees with sections 2 to 6 (who owns what, the order). Its answers, which bind the briefs:
- **Question 1: yes, as proposed.** The viewer's window gains the named addresses (`-pages` taken beside
  `-db`, 1 to 4 addresses; the gate and the navigation rule allow the viewer's own port and the named
  ports; the page-to-window channel stays the viewer's alone; one mutex, class and data folder; a flag
  for the place shown first). A fixed viewer address: `-addr 127.0.0.1:PORT`, the port picked by the
  launcher and handed to the collector (`-viewer-url`) and the window. Each address keeps its own
  storage in the engine: the shell keeps its list per address, nothing is shared.
- **Question 2, what the shell must respect on a viewer page:** the viewer is ONE page with a router: a
  click in the list on a viewer address must be handed to the page (one hook: "a same-origin link was
  clicked"), or every click reloads the index; **the list is a fixed column beside a document that
  scrolls as a whole (the grid scrolls the window): never two inner scrolling boxes;** the viewer's top
  bar is hidden by a switch the viewer builds with W1's part, its search box moves into the content's
  head; the library's own filter column (272 px) is narrowed or folded by the viewer with W4; a post's
  view covers the whole window, the list too. The viewer's places: `/`, `/chats`, `/chat/ID`,
  `/changes`, `/copies`, `/copies/probable`, `/overlap`, `/settings`, `/about`, `/post/ID`.
- **Question 3, the filter addresses (section 3's `library?view=new` form does not exist: use these):**
  all media `/`; by kind `/?type=photo` (`video`, `file`, `audio`); Deleted on Telegram `/?deleted=1`;
  First seen here `/?first=1`; Probable copies `/?copies=probable`, their review `/copies/probable`;
  Changes `/changes`; a chat `/chat/ID`; a chat's files `/?chat=ID`; New: `/?first=1&from=YYYY-MM-DD`
  until `/?view=new` exists (the viewer builds it with W4); Saved Messages: `/chat/ID` of the account's
  own chat until `/saved` exists (the viewer's piece "S1": the chat known by name, first in the list).
  **The counts** beside the views: two are kept in memory, three need a walk of the index after each
  change (not measured at the real archive's size): **the list draws without counts and takes them
  when they come.** The pages' server-side read of the viewer's counts passes the viewer's guard;
  `/api/meta` is the cheap read until the viewer has `/api/shell`.
- **Question 4:** with the window's flag `-tell-close`: exit code 4 = closed by the person, 6 = already
  open and brought to the front, 0 = every other clean end; the launcher asks its question on 4 and
  only on 4 and never takes 0 for the person's wish. The title bar: the caption's text and colour in
  W2; the pill as the first line of the shell until a later piece ("W2b") replaces Windows' caption by
  the shell's top strip (the strip's height and markup are fixed in `internal/appshell` from the
  start, so that W2b only switches the caption off).
- **Saved Messages on a new catalogue (section 8):** the chat list makes a row for the account's own
  chat as an ordinary person's chat under the account's name; its history is not read unless the owner
  chooses it; whether it should be read without that is Core's to answer and the owner's to decide.
- The viewer mounts `internal/appshell` on its pages as its own small piece, the hour the package's
  door exists on a branch that pages names on the board.
