# Brief B7-W1v: the list on the left in the new look, on the viewer's page (the shortest path to ONE window the owner can open)

Written by the viewer session B7, 11-16 19:35. One Opus coder, high effort. **About 40 minutes of usage are
left this week for this: push work in progress after every step; a pushed half that works beats a finished
piece that is not pushed. Hand back commit-ready work; merge nothing into the main branch.**

## 1. What the owner asked for (today, in the owner's words)
After the first real start: "a very ugly app ... still runs in a browser, just a standalone one". The owner
then chose, from pictures: ONE window, **one list on the left** (Overview; Saved Messages; the library's
views; the chats; Settings at the foot), the content on the right, the app's name and state in a strip at
the top. The picture: `C:\Users\trabi\Claude\Projects\Telegram\design-options\app-look-options.html`, first
button ("The combination"): **read its markup and CSS first (the `.tb` strip, the list, the pills): that is
the look to match**, with the viewer's own theme variables (light and dark both exist in `web/app.css`).
19:31: "the objective should be to actually deliver something, meaning the features that work with the much
improved look."

## 2. What exists (do not rebuild)
- The viewer is ONE page with a client router (`archiver/internal/viewer/web/index.html`, `web/js/main.js`):
  every place is a route of the same document; links marked `data-nav` do not reload. Its top bar is
  `<header class="top">` in `index.html` (name, five tabs, search, Settings, About).
- Branch `wip/b-saved` (076eeab7): the account's own chat is "Saved Messages", at `/saved`; `/api/meta`'s
  accounts carry `saved` (its chat id or 0); chats in `/api/meta` come own-chat first, then newest first.
- Branch `wip/b-onewin` (3c504d2c): the joined window (`tgarchive-window -db ... -pages URL ... -addr ...`);
  the viewer's page gets the app's address as a page flag (`viewer.Config.AppURL`, see
  `internal/viewer/appurl.go`, `web/js/api.js`) and shows ONE link "The app" in the top bar.
- Facts about the page's layout you must respect (from a look at the code): the library's grid scrolls the
  WINDOW itself (`window.scrollY`, `scrollTo`): never put the content into an inner scrolling box; the
  height variable `--top-h` (56 px) positions sticky heads, the library's own filter column (272 px, left)
  and the date scrubber (fixed, right); the post view `.item` is `position: fixed; inset: 0` and covers the
  whole window (keep that); the video area's rectangle is measured against the engine's area (a list drawn
  inside the page changes nothing for mpv).
- The filter addresses (all in the query string): all media `/`; `/?type=photo`, `video`, `file`;
  `/?deleted=1`; `/?first=1`; `/?copies=probable`; `/changes`; `/copies/probable` (the review); a chat
  `/chat/ID`; `/saved`; `/chats`; `/settings`; `/about`; `/overlap`; `/copies`.

## 3. Where
- A NEW copy and branch, made by you first: fetch, then
  `git -C /c/Users/trabi/Claude/Projects/Telegram/wt-b-saved worktree add /c/Users/trabi/Claude/Projects/Telegram/wt-b-shell -b wip/b-shell private/claude/charming-feynman-vm2xia`
  (the newest main head; say which), then merge `private/wip/b-saved` and `private/wip/b-onewin` into it
  (small conflicts are expected in `internal/viewer`'s `server.go`, `web/index.html`, `web/js/main.js`,
  `web/js/api.js`: keep both sides' meaning; say what you resolved). Push `wip/b-shell` to `private` right
  after the merges, and after every step below. Never the main branch, never `origin`; touch no other copy
  (`wt-b-saved`, `wt-b-onewin`, `wt-b-faces`, `wt-b-join`, `repo-archiver` belong to others).
- Commits: `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, ending with
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- You may edit ONLY `archiver/internal/viewer` (Go, `web/`), and, for step 5's pictures only,
  `archiver/internal/window/joinedcheck_windows.go` and `archiver/cmd/tgarchive-window`.

## 4. What to build, in this order (push after each)
1. **The list.** A fixed column on the left of the viewer's page (about 240 px; `nav` with a label; the
   document beside it still scrolls as a whole: body padding, not an inner scroll box), in the picture's
   look. Top to bottom:
   - **Overview**: only when the app's address is set (the page flag from `AppURL`): a plain link to it (it
     leaves the viewer's page; NOT `data-nav`).
   - **Saved Messages**: `/saved` (per account when there are several: one entry each, with the label).
   - **Library**: All media; Photos; Videos; Files; Deleted on Telegram (with the count `/api/meta`
     already gives: `deleted_posts`); First seen here; Probable copies; Changes. No count is shown where
     the page has none without a new request (do not add requests for counts in this piece).
   - **Chats**: every chat of `/api/meta` that is not hidden, in its order (own chats are already first:
     leave Saved Messages out here), each to `/chat/ID`, its title as text, cut with an ellipsis; the
     list's chat part scrolls inside the column if it is long; a line "All chats" to `/chats` at its head.
   - **At the foot**: Copies, Overlap (the viewer's two other places, small), Settings, About.
   Every viewer entry is `data-nav` (the router's own in-page navigation); the entry of the current place is
   marked (extend what `main.js` does for tabs: by path AND by the filter for the library's views, so that
   "Deleted on Telegram" is marked on `/?deleted=1` and "All media" only on a plain `/`); keyboard focus and
   `aria-current` as the tabs have them. All text is drawn as text (the page scripts' rule: no markup from
   data; `TestPageScriptsUseTextOnly` must pass).
2. **The top strip.** With the list shown, the top bar becomes the picture's strip: the name on the left,
   the search box (it stays: it is a feature), no tabs (the list replaces them), Settings and About move to
   the list's foot. Its height stays `--top-h` so that nothing hung from it moves.
3. **The library's own filter column** stays as it is, beside the list. Under about 1,100 px of width the
   list narrows to icons or folds behind one button in the strip: choose the simpler; never let the grid
   fall under 2 columns at the window's usual size (1,280 px wide).
4. **When it shows.** Always in the viewer's page on this PC (the window and the browser alike: the old
   archive's window gets the same list, without "Overview"). NOT for other devices at home (the LAN mode's
   pages keep the top bar as it is: the page flags tell you; its tests must pass unchanged).
5. **Empty states that say what to do next** (the day's lesson: the owner met a broken page on a new, empty
   catalogue). On an empty catalogue the library says, in fixed words: "No files in this archive yet. Files
   appear here once the app has collected a chat: choose one under Overview." (the last clause only when
   the app's address is set); Chats: "No chats in this archive yet. They appear once an account is signed
   in in the app." Keep every other empty sentence.
6. **Pictures, as the owner would see it** (invented data only): extend the joined self-check
   (`joinedcheck_windows.go`; the package already has `capture` for the window's own content) with an
   optional folder for PNG pictures of the window: (a) the library on a filled invented archive, (b) the
   same with "Deleted on Telegram" chosen, (c) a chat, (d) `/saved`, (e) the library on an EMPTY catalogue.
   Run it on a scratch folder (`C:\Users\trabi\Claude\Projects\Telegram\runs-b7\shell`), with `LOCALAPPDATA`,
   `APPDATA`, `TEMP`, `TMP` set to folders inside it BEFORE anything starts, output to files, at most 6
   real window starts, each under 90 s; the invented archive from `tgarchive fabricate -real-rows` (build
   `tgarchive.exe` and `tgarchive-window.exe` once into the scratch folder), the empty one made by starting
   `tgarchive app -db <scratch>/E.sqlite -library <scratch>/libE -addr 127.0.0.1:<a port above 20000>` once
   and stopping it by its PID when it serves. Leave the PNG files in `runs-b7\shell\pictures` and name them
   in your hand-back: the session looks at them. If a picture shows something broken, fix it or say so.

## 5. Tests (by name; never the whole viewer package, never the race detector)
The page-script tests (`TestPageScriptsParseAsModules`, `TestPageScriptsUseTextOnly`), the wall tests
(`TestWall`), the headers and guards (`TestHeadersOnEveryAnswer`, `TestViewerCrossSiteRefusedOnEveryRoute`),
the LAN page tests (`TestLAN`, `TestHomeDeviceGetsNoWindowBehaviour`), `TestSaved`, `TestAppURL`, and a new
`TestShellList...` for what Go can check (the page's markup holds the list's entries; the LAN page does
not; the flags). `gofmt -l`, `go vet ./internal/viewer` at the end.
Each go command: `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`,
`GOMAXPROCS=2 GOFLAGS=-p=1`; ONE at a time on this PC through the lock (take:
`until mkdir /c/Users/trabi/Claude/Projects/Telegram/runs-b7/golock 2>/dev/null; do sleep 20; done`; release:
`rmdir` of that folder right after the command, also when it fails); before each, free memory at least
2.5 GB and CPU load under 90
(`powershell -NoProfile -Command "[math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB,1)"`,
`powershell -NoProfile -Command "(Get-CimInstance Win32_Processor).LoadPercentage"`); if not, release, wait
90 s, try again (at most 6 times, then say so and go on with what needs no go command).

## 6. Hard rules (the owner's)
- Invented data only, in every test, picture and look. Never open, list or read anything under `E:\`, any
  folder named `tgarchive-b` or `tgarchive-app`, the owner's app folder, any NAS path or any real
  catalogue. Do not search drives.
- Never stop, kill or signal a process you did not start; at the end none of yours is left (count them).
- The viewer's guards, its Content-Security-Policy and its import wall stay as they are: no inline script,
  no new origin, no new dependency, no request to anything but the viewer's own address.
- Text with a Windows path never goes through a shell string into a file: the Write or Edit tool. Put your
  scripts in a folder of your own (`runs-b7\shell\scripts`), not in a shared temp folder.

## 7. Hand back (your final message, at most 35 lines; you cannot write report files outside the copy)
The main head you cut from, the merges' conflicts and how resolved, your head (pushed); files and line
counts; what the list shows and what it does not yet; each named test's result; the pictures' file names
and what each shows, with anything that looks wrong; what was NOT done; doubts, most important first.
