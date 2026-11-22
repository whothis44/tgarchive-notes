# REPORT-B7-viewer-151: the viewer against board message 151, the empty catalogue, and four facts for the one window

Written down by the main session (B7) from the investigator's hand-back, 11-16 (the investigator could not
write files). The look ran about 18:34 to 18:43. Code: `wt-b-faces` at `wip/b-edgegone` (clean, not changed).
Paths are under `archiver/` unless they start with `web/` (= `archiver/internal/viewer/web/`). **[run]** =
seen on invented data in `runs-b7/look151`; **[read]** = code only. Checked by B7 itself in the code: the
guard's rule (`server.go` 153 to 170, `crossSite`), no "Saved Messages" anywhere in `internal/viewer`, the
self dialog's title (`dialogs.go` 405 to 418), the header (`web/index.html` 16 to 46), `MessageSeen`.

## Part 1: the build and the two catalogues
- Build: one `go build`, exit 0, 4 s (warm cache), `tgarchive.exe` 25.0 MB. Free memory before: 4.3 GB. [run]
- `fabricate` flags (cmd/tgarchive/fabricate.go:20-94): `-db -library -seed -accounts(1|2) -chats -messages
  -files -videos -reads -real-rows`. `-chats` and `-messages` must be at least 1 (fabricate.go:53), so it
  cannot make an empty catalogue.
- **F**: `fabricate -chats 8 -messages 600 -real-rows -reads`, 1.9 s. Result: 1 account, 14 chats, 600
  messages, 401 Telegram files (218 saved, 126 wanted, 33 held, 11 aside, 6 skipped, 7 gone). [run]
- **fabricate has no Saved Messages chat.** User chats get ids 6.0e9-6.9e9
  (internal/fabricate/fabricate.go:223-226, 1085), while the account's `tg_user_id` is 7.1e9 plus a random
  part (fabricate.go:872). It also writes no `deleted_at` (only gaps in message ids, fabricate.go:391).
- **Hand edits on F** (sqlite3; the untouched copy is `F-before-hand-edits.sqlite`):
  - a Saved Messages chat, shaped as the reader would store it: `space(shared=0, tg_chat_id=<account
    tg_user_id>, account_id=1)` and `chat(kind='user', title=<account's own name>)`;
  - 3 outgoing messages (sender `''`), one with an attachment of a file already saved;
  - `deleted_at` on 6 messages (4 with files, 2 without).
  - After the edits the index read 603 messages, 457 posts and 401 files in 10 ms. [run]
- **E**: the program's own create, `tgarchive app -db E.sqlite -library libE -addr 127.0.0.1:28711` ("created
  if missing", app.go:30; read-write open at app.go:100), stopped once it served.
  - Schema `user_version` 26, the same as F. 0 accounts, chats, messages and files.
  - It differs from a real new account's catalogue in having no account row, no `account_chat` rows and no
    settings of a signed-in run (only the collector's sign-in writes those).
  - Lock files were left behind (`E.sqlite.lock`, `.collector.lock`). [run]
- Viewer start (all folder flags inside the scratch folder, `-addr 127.0.0.1:2872x`, `-thumb-workers 0`),
  time to the first 200 from `/api/meta`: F 780 ms (index 10 ms); E 716 ms (index 2 ms); F again 284 ms.
  GETs need no token; changes need `X-Viewer-Token` (server.go:31, 248-261). [run]

## Part 2: board message 151

### 151 a, Saved Messages
- **In the viewer** [run on F, hand-added row]: it appears in `/api/chats` and in `/api/meta` `chats` as
  `kind:"user"`, titled with the account's own name (invented). "Saved Messages" appears nowhere. Order is
  newest post first (chats.go:92, api.go:44); it was 2nd of 15. `/chat/15` serves the page; `/api/chat/15`
  answers `messages:3, files:1, seen_by:[]` (empty because the hand row has no `account_chat`);
  `/api/chat/15/posts` gives 3 posts; the library's `chat=15` view gives 1 tile.
- **The viewer has no notion of the account's own chat** [read]. `tg_user_id` is read at refresh.go:508 only
  as part of a chat's stable key for marks (index.go:195).
- **A new account gets a row for it** [read, not run]: the chat list is Telegram's dialog list
  (internal/telegram/dialogs.go:151); every `PeerUser` dialog becomes a user chat titled first + last name,
  with no check of `User.Self` (dialogs.go:405-418); `tgstore.SaveChats` (internal/tgstore/store.go:626)
  calls `catalog.SaveChatFacts`, which makes every unknown chat (internal/catalog/tgchats.go:68-69, 126).
  Whether Telegram lists the self dialog was not checked (believed: yes when Saved Messages holds messages).
- **Its history is not read without a choice** [read, not run]: the reader skips a chat that is neither
  approved nor under way (internal/collector/reader.go:649-653; gaps at :795-796); approval is a settings row
  (reader.go:87-88, 108-118), written by the owner or by the automatic mirror, which is off by default
  (mirror_auto.go:59).
- **But new messages are stored without a choice** [read, not run]: the live monitor's `MessageSeen`
  (internal/tgstore/store.go:472-479, called from internal/telegram/monitor.go:606 and 777) saves new
  messages of any chat with no approval check, while the collector runs.

### 151 b 1, the unified stream with a media toggle [run on F]
- The library (`GET /`, page web/js/library.js; JSON `/api/library/shape` at library.go:1705,
  `/api/library/tiles` at :1834) is one stream over all chats, newest first.
- The stored preference `library_each_once:true` (the default) gives a file and its exact copies one tile in
  any view naming no chat or topic (library.go:263-265; web/js/library.js:65-72).
- F counts: 169 of 280 posts shown; `hiding.once` 9; `hiding.folded` 2; `hiding.not_saved` 100; `once=0`
  shows 178.
- Kind filter: `type=photo|video|file|audio`, comma-separated; video includes GIFs (library.go:156-167;
  library.js:22). F: photo 95, video 47, file 24, audio 15.
- Other filters (library.js:17-18): `state`, `copies`, `chat`/`xchat`, `from`/`to`, `caption`, `deleted`,
  `first`, `only`, `elsewhere`, `with`, `prob=apart`.
- ROADMAP.md:204 "Each file once ... unified stream" (D5) and :186: **as the rows say**. Not drawn in a
  browser by this look.

### 151 b 2, highlight deleted messages
- The mark is `message.deleted_at`, written by `catalog.MarkDeleted` from the monitor
  (internal/tgstore/store.go:481-498). F's 6 marks are hand-written.
- **Badge** [run]: a tile carries `deleted` and `deleted_part` (library.go:1781-1782), drawn as "Deleted" or
  "Partly deleted" (web/js/library.js:1221, 1243-1244), and through `deletedMark` in a chat
  (web/js/chat.js:735) and on the post page (web/js/item.js:575).
- **Filter** [run]: `/?deleted=1` (library.go:245) gave 1 tile on F (4 posts with files, folded by "each file
  once"). `/api/meta` gives `deleted_posts:6, deleted_files:4` (api.go:66), shown beside the switch
  (library.js:463-468).
- **Changes page** [run]: `/changes` (web/js/changes.js; JSON changes.go:413). F: deleted 6, edited 20, media
  15, listed 26. `/changes?kind=deleted` gives 6 rows; `/deleted` is the same page with that kind
  (web/js/main.js:21; changes.js:90). `/api/deleted` (deleted.go:28) still answers, but no page reads it.
- ROADMAP :190 (D5) and :215 (E3): **as the rows say**, on hand-made marks only. Not seen with marks written
  by a real monitor.

### 151 b 3, new and first seen on media [run on F]
- Filters: `first=1`, `only=1`, `elsewhere=1`, `sameprob=0`, decided per listing from the index
  (appear.go:15-40; library.go:260-262; buttons at library.js:496-519).
- F counts: `first=1` 169, `only=1` 140, `elsewhere=1` 31, `first=1&chat=8` 16 of the chat's 23,
  `only=1&chat=8` 15.
- "New between dates" is `first=1&from=YYYY-MM-DD&to=YYYY-MM-DD`, in the page's `tz` (library.go:210-219).
  The last 30 days gave 5 tiles. A tile's `chats` field carries "also in N chats".
- **There is no "New" without dates** (no "since last look", no unseen marker), and FEATURES
  (docs/FEATURES.md:351-361) does not ask for one.
- ROADMAP :194 (D5): **as the row says**.

### The empty catalogue E [run for the answers; read for the scripts]
All page routes (`/ /chats /chat/{id} /copies /copies/probable /deleted /changes /overlap /settings /about
/post/{id}`, server.go:95-99) answered 200 with the same 5273-byte page.

| Route (handler) | E answer |
|---|---|
| `/api/meta` (api.go:30) | `accounts:[]`, `chats:[]`, counts 0 |
| `/api/library/shape` (library.go:1705) | `total:0, months:[], aspects:"", anchors:null`; `first` and `text_hits` absent |
| `/api/chats` (chats.go:65) | `chats:[]`, `accounts:0`, `total:0` |
| `/api/chat/{id}` and `/posts` (chats.go:120, 209) | 404 |
| `/api/copies/most` (copies.go:20) | `files:[]` |
| `/api/copies/probable` (review.go:149) | `items:[]`, counts 0 |
| `/api/changes` (changes.go:413) | `rows:[]` |
| `/api/overlap` (overlap.go:390) | `chats:[]` |
| `/api/about`, `/api/stats`, `/api/prefs`, `/api/lan` | 200, numbers 0, arrays `[]` |
| `/api/act/chat/{id}` | 404 `{refused, say}` |

- **The only `null` is `anchors`** (library.go:1629; filled per block at :1736). The script reads
  `anchors[b]` only for blocks that exist (library.js:290, 1172); with `total:0`, `layout()` makes no rows
  (:1042-1092) and `render()` asks for no block (:1131-1161); `months` is guarded (:1007), `atob("")` is fine
  (:231), `text_hits` is read with `|| []` (:1016). **By reading, no script fails on E. Not seen in a
  browser.**
- **Empty states** (by reading): library "No files in this archive yet" (library.js:254-255; the chat filter
  section is hidden, :443); Chats "No chats in this archive yet." (chats.js:63); a missing chat "No such
  chat" (chat.js:133); Copies copies.js:105 and :123; Changes changes.js:43; Overlap "No chat has files
  yet." (overlap.js:145). **None says what to do next; none is a blank area.**

## Part 3: four facts for the one window

### Q2: places, the header, and what fights a left list [read]
- **Places**: the routes in server.go:95-99. They all serve one page (server.go:74-94); a client router picks
  the module (web/js/main.js:16-25, 56-86).
- **The header is one shared piece**: `<header class="top">` in web/index.html:16-46 (brand, the tabs
  Library, Chats, Copies, Changes, Overlap, the search box, Settings, About, Sign out). main.js:67-70 only
  marks the current tab.
- **What is tied to the header or the full width** (web/app.css):
  - `--top-h: 56px` (:24; 104 px under 760 px, :671); `.top` is sticky (:100-102).
  - The library's own filter column is already 272 px on the left: `.lib-wrap` grid `272px minmax(0,1fr)`
    (:202). `.side` is sticky at `top: var(--top-h)`, height `calc(100vh - var(--top-h))` (:209-211).
  - The scrubber is fixed: `right: 0; top: calc(var(--top-h) + 8px)` (:331).
  - A chat's head is sticky at `top: var(--top-h)` (:386).
  - The post view `.item` is `position: fixed; inset: 0` (:497-498) and would cover a list drawn in the same
    page.
  - Breakpoints use the viewport width (:650; library.js:20).
  - The grid scrolls the window itself (`window.scrollY`, `innerHeight`, `scrollTo`: library.js:119,
    1119-1122, 1286). An inner scrolling box would break it; a fixed or sticky list beside a scrolling
    document would not.
- **The mpv rectangle**: the frame's `getBoundingClientRect` times `devicePixelRatio`, relative to the WebView
  (web/js/play.js:437-444; sent at :515 and :578-588). A native list outside the WebView would need the
  window to add the WebView's offset; a list inside the page needs nothing.
- **No switch hides the header.** The window is detected only for the player (play.js:346); the page flags
  are only `lan`, `mark` and `act` (api.js:8-18; server.go:75; act.go:323-328).

### Q3: addresses that open a place filtered [read; the JSON behind each run on F]

| Place | Address |
|---|---|
| All media | `/` |
| New | `/?first=1&from=YYYY-MM-DD&to=YYYY-MM-DD` (the linking side must write the dates) |
| Deleted on Telegram | `/?deleted=1` |
| First seen here | `/?first=1`, or `/?first=1&chat=ID` |
| Probable copies (tiles) | `/?copies=probable` |
| Probable copies review | `/copies/probable?tab=review|same|different&hub=ID` (copies.js:51-52) |
| Changes | `/changes?kind=deleted|edited|all&media=1&bare=1&chat=ID`; `/deleted` is kind deleted (changes.js:86-91, 216-223) |
| A chat | `/chat/ID?media=1&topic=&around=&at=` (chat.js:121-144) |
| The account's own chat | `/chat/ID`, where ID is the catalogue chat id |

- Every filter is in the query string (library.js:351-357; changes.js:172; chat.js:271; overlap.js:61). The
  only local storage is an old hide key being migrated (item.js:44-46). Nothing has to change for plain
  links.
- The account's own chat has no route of its own. The linking side must look up the `space` with `shared=0`,
  `account_id=A` and `tg_chat_id=account.tg_user_id`, then take its `chat.id`.

### Counts for the five views

| View | Source | Kept or walked |
|---|---|---|
| All media | `libraryTotals` (library.go:1683), or the shape's `total` | kept per index version |
| Deleted on Telegram | `feedState.deletedPosts` / `deletedFiles` (feed.go:135-139), in `/api/meta` | kept: no walk |
| Probable pairs | `reviewCounts` (review.go:100) | a walk over all media, cached per index and verdict version |
| First seen here / New / Probable tiles | `buildListing` (library.go:610) with appear.go | a walk per filter, cached in `listCache` (library.go:485) |

F timings (280 posts; too small to judge the real archive) [run]: the first shape after a start 31.5 ms; each
later filter 0.8-5.9 ms; `/api/meta` 0.6 ms; `/api/copies/probable` 2.2 ms; `/api/changes` 2.0 ms.

### Guards for another local origin [run with curl on F; the guard at server.go:153-261]

| Request | Status |
|---|---|
| page `/?deleted=1` or `/chat/15`: `Sec-Fetch-Site: same-site`, navigate, document, Referer another port | 200 |
| page `/`: cross-site, navigate, document | 200 |
| page `/`: same-site with `Dest: iframe` | 403 |
| page `/`: same-site with `Mode: cors` | 403 |
| `/api/meta`: same-site with an Origin from another port | 403 |
| `/api/meta`: only an Origin from another port | 403 |
| `/api/meta`: only a Referer from another port | 200 |
| `/api/meta`: same-site navigate | 403 |
| `/assets/app.css` and `/media/1/thumb`: same-site no-cors | 403 |
| `Host: localhost:28721` | 200 (viewer.go:663-676) |

- **The rule** (server.go:164): refused when `crossSite && (data || !navigation)`, or when `data &&
  foreignOrigin`. Another port counts as "same-site", which counts as cross-site (server.go:212-233).
- **Headers on every answer** (server.go:196-204): CSP `default-src 'self'; ... connect-src 'self'; ...
  frame-ancestors 'none'`; `X-Frame-Options: DENY`; `Cross-Origin-Opener-Policy: same-origin` and
  `Cross-Origin-Resource-Policy: same-origin`; `Referrer-Policy: no-referrer`.
- **The port** (of `tgarchive viewer`): the `-addr` flag, default `127.0.0.1:8788` (viewer.go:38), loopback
  only (viewer.go:74, 681-699). `-addr 127.0.0.1:0` was not tried. (The window program listens on a free
  port: `cmd/tgarchive-window/main.go` 352.)

## Not done, and why
- No browser was allowed, so nothing was drawn. "No script fails on E" and all empty states are by reading
  only.
- The Saved Messages row and the deleted marks were written by hand, not by the program: fabricate cannot
  make either.
- A real self dialog's title, and whether Telegram lists it, were not seen.
- E has no account row.
- The 151 a collector claims were not run against the fake Telegram.

## What was run
- Free memory 4.3 GB. One `go build` (GOMAXPROCS=2 GOGC=25 GOFLAGS=-p=1; env-archiver.sh sourced). No tests.
- Before every start, LOCALAPPDATA, APPDATA, TEMP and TMP were set to `runs-b7/look151/env`; all output went
  to files there.
- `fabricate` as above, then sqlite3 hand edits on F. `app` on E. The viewer on F, on E, on F again. All four
  programs were stopped by their PIDs; the end count of `tgarchive.exe` on the PC was 0.
- `node probe.mjs` (in the scratch folder; output in `probeF.txt` and `probeE.txt`), node one-liners for the
  counts and timings, and curl with Sec-Fetch, Origin, Referer and Host headers.
