# Review of W1, the app's own pages in the new look (pages, P7, 2026-11-21)

Independent review, Opus, read-only on the code, with probes. Read on the head af4ca40e: `git diff e9413e4e aa69cd81`
whole, the later changes to `internal/appshell` and `internal/server` up to af4ca40e, the coder's report
`archiver/docs/progress/pages-shell-REPORT.md`, `DESIGN-ONE-WINDOW-HOW.md` sections 3 and 9, and the parts of
`internal/launcher` (ui.go, viewerpage.go, start.go, present.go) and `internal/window` (pages.go, allowed.go, joined.go)
that decide where the list's links go. Ran, all through `runs-pages-p6/go1.sh` with named tests only, `LOCALAPPDATA`,
`APPDATA`, `TEMP` and `TMP` redirected into the scratch copy, invented data only, Edge headless only: uncommitted probes
`internal/server/zz_probe_w1_test.go` (`TestZZW1Inject`, `TestZZW1Routes`, `TestZZW1Scale`, `TestZZW1States`,
`TestZZW1ShellFails`, `TestZZW1LauncherViewerLinks`, `TestZZW1Shots`, `TestZZW1Viewport`),
`internal/server/zz_probe_w1_cdp_test.go` (`TestZZW1CDP`: Edge headless driven over its DevTools protocol, so that
the page really is 390 CSS px wide) and `internal/launcher/zz_probe_w1_test.go` (`TestZZW1LauncherPaths`). All
passed as probes (what they show is below). Screenshots in
`C:\Users\trabi\Claude\Projects\Telegram\wt-pages-review-w1-scratch\zz_probe_env\shots`.

## Findings

1. **SHOULD FIX: with the viewer as "a window of its own" (not joined), every chat in the list and Saved Messages
   lead to a plain "not found" page; the library's views lead to the launcher's "Show the viewer" page, not to the
   view.** Confirmed: `TestZZW1LauncherViewerLinks` (the pages with `-viewer-url http://127.0.0.1:L/viewer`, as
   `internal/launcher/start.go:166-168` passes it) gives the entries `L/viewer/chat/N` (all 17 chats of the
   fixture) and `L/viewer/?deleted=1` etc.; `TestZZW1LauncherPaths` sends `/viewer/chat/12` to the real
   `(*ui).ServeHTTP`: **404 "not found"** (`internal/launcher/ui.go:378`, `isViewerPath` takes only `/viewer` and
   `/viewer/`). Where: `internal/server/shell.go:35` passes the run's viewer address, launcher path included, as the
   viewer's base, and `internal/appshell/shell.go:176` appends the viewer's paths to it. The viewer "answers" (the
   look at `viewerNow` dials the launcher's port), so the links are drawn live. How a person meets it: viewer set to
   "a window of its own" with the pages in the browser (or the joined window not usable): click any chat in the
   list: a blank page with "not found" in the same tab/window. The design says such a place is "never a dead link".
   Smallest cure: in `shellOptions`, when the viewer's address ends in the launcher's viewer path, give the viewer's
   places no path (each leads to the launcher's page itself), or mark them dead with words of their own ("The viewer
   is a window of its own: Show the viewer on the launcher's page"); a test with that address.

2. **SHOULD FIX: when `/api/shell` fails on a page with no kept list, the page has no way to any other page.**
   Confirmed: `TestZZW1ShellFails` (the route answering 500, a fresh browser profile): the list has 0 entries, only
   the word "PLACES" (screenshot `shellfails-queue-1400.png`); the old tabs are gone; the only links left in the page
   are the Overview's own to Settings and Staging. Where: `internal/appshell/shell.go:189,199,233` (any read error of
   accounts, Saved Messages or the chats fails the whole answer, the fixed places with it),
   `internal/appshell/assets/shell.js:83-86` (no answer: nothing drawn) and `:161` (no second ask). How a person
   meets it: a catalogue read fails at the first open of the pages (or of a new window data folder): in the app's
   own window there is no address bar, so Queue, Accounts, Import, Report and Choose chats cannot be reached until
   a reload succeeds. Smallest cure: the fixed places (Overview, Collecting, Settings, Accounts) do not need the
   catalogue: `List` answers them even when the chat reads fail (with one entry saying the chats could not be read),
   and `shell.js` draws a built-in set of the pages' places when it has no answer, and asks again after a failure.

3. **SHOULD FIX: the list is asked once per page load and never again, so it goes stale and contradicts the
   head.** By reading: `shell.js` calls `ask()` only from `mount()` (`shell.js:241`); `main.js` never calls
   `AppShell.refresh` (only `onNavigate`, `select`, `setPill`: `main.js:362,383,389`), and the pages change place by
   the hash, without a reload. The head's viewer link is painted from `/api/live` every 2 s (`main.js:293`); the
   list's viewer places keep the state of the load. How a person meets it: the window opens the pages before the
   viewer answers: the head soon says "Open viewer" while every library entry and chat in the list still answers
   "The viewer is not open: nothing answers at its address. Start it with the app's starter"; the reverse after the
   viewer ends (live links to a dead address). Equally, new chats, a chat's state ("waiting for its read" to
   "collecting"), and Saved Messages appearing after the first chat-list read show only after a reload, which the
   window offers no button for. Smallest cure: `main.js` calls `AppShell.refresh()` when `/api/live`'s viewer state
   changes and on a slow timer (for example 60 s, the answer costs about 0.18 s on a large catalogue: point 3 below).

4. **SHOULD FIX (by reading; not verified: needs a real window): pages in the app's window with the viewer "in the
   browser": every viewer entry of the list does nothing when clicked.** The pages window is started with the
   launcher's and the pages' addresses only (`internal/launcher/present.go:244-250`), the viewer's browser address is
   not named, so the navigation is refused; `pagesView.offsite` (`internal/window/pages.go:326-329`) shows its line
   only for an address on the open web (`refusedKind` gives `KindLocal` for `http://127.0.0.1`), so nothing at all is
   shown. The launcher's settings allow this pair (`internal/launcher/settings.go:141-154`). How a person meets it:
   a click on a chat or "All media" in the list: nothing happens, no word. Smallest cure: in that mode give the
   pages `-viewer-url` as today but mark the list's viewer places as opening in the browser (`target=_blank`, which
   the window then has to hand to the system browser), or name the viewer's address to the window; at least the
   dead line "The viewer opens in the browser: use Open viewer".

5. **MINOR: the coder's narrow check does not run at 390 CSS px.** Confirmed: `TestZZW1Viewport` serves a page that
   writes its own width: Edge headless with `--window-size=390,800` gives a page 484 CSS px wide at a scale of 2 and
   492 at a scale of 1 (old and new headless alike). So `TestPagesInBrowser`'s "narrow" case
   (`internal/server/browser_test.go:95`) and its `data-as-overflow="0"` claim are about 484 px; its screenshots at
   "390" are the left 390 px of a 484 px page (they look cut off on the right: `filled-dark-queue-390.png`). At a true
   390 px (DevTools device metrics, `TestZZW1CDP`) the pages are sound: point 5 of "Checked and sound". Cure: drive
   the narrow case with device-metrics emulation, or say 484 in the test.

6. **MINOR: an account still waiting for its sign-in gets "Saved Messages · <label>: not read yet" and the words
   "appears once the account's chat list is read".** Confirmed: `TestZZW1States/one-signed-one-waiting`. Where:
   `internal/appshell/shell.go:216`. Cure: for `TgUserID == 0`, words "not signed in" and the dead line "Sign this
   account in on Accounts".

7. **MINOR: a chat whose history is being read but that has no chat-list date sorts last and falls outside the 200.**
   Confirmed: `TestZZW1States/under-way-without-date-beyond-bound` (260 chats, the one being read has `top_date` 0:
   not among the 200 shown). Where: `internal/appshell/shell.go:338,348` (newest activity is the chat list's date
   only). Cure: chats with a read under way first, or the newest stored message's date (one seek of
   `message_space_date` per chat) when the chat list's date is 0.

8. **MINOR: the "Mirrors' settings" entry promises "on Settings, under the mirrors" but lands at the top of
   Settings, and the list's selection then moves to "Settings".** By reading: the entry's link is `/#/settings`
   (`internal/appshell/shell.go:256`); `route()` selects by the page name (`main.js:389`). Cure: a hash the Settings
   page scrolls to (`#/settings?at=mirrors`) and keep the clicked key selected for it, or drop the entry's promise.

9. **MINOR: the page's title is shown twice, and differs: the head says "Choose chats", the page says "Chats"**
   (and "Queue"/"Queue", "Settings"/"Settings" one above the other). Confirmed in the screenshots
   (`cdp-filled-light-queue-390.png`, `cdp-filled-dark-settings-1400.png`, `cdp-empty-light-chats-390.png`). Cure:
   one of the two, or the same words.

10. **MINOR: the test aid `?as-try=KEY` ships in the owner's program.** By reading and probe: any address with
    `?as-try=chat:12` (a link from any site may open the pages: a navigation is let through by the guard) clicks that
    entry once; hostile values are harmless (`TestZZW1Inject`: quotes stripped, a newline or a broken escape only
    ends the aid; no console error) and every entry is a plain navigation. Cure: drop the aid or honour it only in
    the demo/test runs.

11. **MINOR (by reading): the "Skip to the page" link, when focused, sits under the strip.** `.skip` is placed at
    `top: 8px` with `z-index: 10` (`internal/server/web/assets/base.css:128-129`); the strip is fixed at the top with
    `z-index: 40` (`internal/appshell/assets/shell.css:50`), 40 px high. A keyboard user's first Tab focuses a link
    that cannot be seen. (A headless focus did not apply `:focus`, so not confirmed.) Cure: `.skip:focus { top:
    calc(var(--as-strip) + 8px); z-index: 50 }`.

## Checked and sound

- Injection (1): chat titles, account labels, state words and counts reach the page only as `textContent`; links are
  built by the server from a cleaned 127.0.0.1 address and constant paths. `TestZZW1Inject` (a chat titled with an
  `<img onerror>`, a closing quote, a `<b id>` and `javascript:` text; another titled `javascript:alert(3)`; both
  accounts labelled `<svg onload>`; Saved Messages chats with the hostile title), Edge headless: no injected element,
  no `<title>` change, no `javascript:` href, every href a page path or `http://127.0.0.1:`; the text shown escaped
  (3 and 10 times). `main.js`'s new lines (page title from a constant table, the pill from `#run-state`'s text, the
  selected key) set text only. `dataset.key` is the only attribute from the answer; the selector built by the aid
  strips quotes and backslashes.
- Routes (2), `TestZZW1Routes`: `/api/shell` and `/shell/*` go through the same `guard` as every other route: another
  `Host` (also a rebinding name) 421; `Sec-Fetch-Site` cross-site or same-site 403 (also a cross-site navigation to
  `/api/shell`, and a cross-site `<script>` of `/shell/shell.js`); POST, PUT, DELETE, OPTIONS on `/api/shell` 403;
  POST on `/shell/shell.js` 405; `/shell/` 404 (no listing); `/shell/../assets/base.css` a redirect to the real
  `/assets/base.css` (the mux's clean, nothing new); `%2e%2e`, `..%2f`, `..%5c`, `.%2f`, `%00`, wrong case, an unknown
  `.css`: 404. CSP and nosniff on every answer. The pages have no `-lan` case.
- The list's reads (3), `TestZZW1Scale` on an invented catalogue of 3 accounts, 5,017 chats and 2,000,768 messages
  (20 chats with a read under way, 100,000 messages each): `List` min 131 ms, median 133 ms, max 180 ms;
  `GET /api/shell` median 184 ms; answer 38 KB; of it `ListChatReads` 107 ms (the counts of the reads under way),
  `ListChats(0)` 7 ms. Plans: the chat table walked (it is the list), every other step a seek; the count a covering
  range of `message_space_date`; Saved Messages a seek of `space_key`. All on the reader pool (`cat.DB()`, WAL): a
  small write took max 0.7 ms alone and max 1.0 ms while two loops of `List` ran. Asked once per page load (no timer:
  finding 3). The bound: "N more" with the count, leading to Choose chats (`TestZZW1States`: 260 chats, 200 shown,
  "60 more").
- States (4): empty catalogue, signed-in account with no chat, a removed account's only chat ("no account
  reaches it"), Saved Messages read and not read, a chat with no messages: each drawn with words, no null, no script
  error (headless, all four pages, both themes, both states). A schema older than the build cannot reach the shell:
  the pages open the catalogue read-write, which migrates it. When the answer fails the rest of the page works; only
  the list is lost (finding 2).
- The look (5), `TestZZW1CDP` at true 1400x900 and 390x800, light and dark (`prefers-color-scheme`), Overview, Chats,
  Queue, Settings, empty and filled catalogue (32 screenshots `cdp-*.png`, plus the list unfolded at 390
  `cdp-*-listopen-390.png`): no page wider than the window (`scrollWidth` equal to or under the width), no element
  sticking out unclipped, no uncaught script error, no piece of the old header; at 390 the list folds behind the
  strip's button and opens over a dimmed page 300 px wide with its foot (Settings, Accounts) kept in view; text
  readable in both themes (muted on panel about 6:1 light, the dark set the picture's). The pill seen: "Stopped"
  (off) only; its other tones by reading (`shell.css` `.as-dot[data-tone]`). Headless with no stored theme
  follows this PC's dark setting, so the `TestZZW1Shots` "light" files are dark: the `cdp-*-light-*` files are the
  light ones.
- What the old pages had (6): the brand link (to the Overview: now the list's Overview and the strip's pill), the
  eight tabs (all in the list, Chats as "Choose chats"), the run pill (kept hidden, copied to the strip's pill), Start
  and Stop, the pause, "as of", "Open viewer" / "Viewer: set its address" / "The viewer is not running", Theme, Quit,
  the verdict line: all still in the content's head; the Overview's own links unchanged. Nothing is gone.
- The viewer's places (7), by reading: joined window (the default with the pages in the app's window): the viewer's
  address is the window's own, a click opens the place in the same window (`internal/window/joined.go:119`); pages in
  the browser with the viewer in the browser: the same tab leaves the pages (the head's "Open viewer" opens a new
  tab instead); viewer a window of its own: finding 1; pages in the window, viewer in the browser: finding 4. Without
  `-viewer-url` and nothing stored: each viewer place is a button that shows one line at the top of the content,
  "The viewer is not open: its address is not set here. Set it in Settings ...".

## Not verified

- The four modes of point 7 in a real window (findings 1 and 4 are read from the launcher's and the window's code;
  finding 1's 404 is the launcher's real handler).
- The pill's ok, warn and bad tones on screen, and the VPN pill (the pages never set it).
- The skip link's place when focused (finding 11): a headless focus did not apply `:focus`.
- The list's look inside the WebView2 window (fonts, the strip's empty slot for the window's buttons).
