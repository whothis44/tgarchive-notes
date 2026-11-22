# Review W1v: the app's one list on the viewer's pages (independent, Opus, 11-21 22:21)

Branch `wip/b-onelist` dad8caa1 against main af4ca40, read as `git diff af4ca40e..dad8caa1` (19 files). Probes ran in
the scratch worktree `wt-b9-review-W1v-scratch` (detached at dad8caa1; nothing committed; the probe file was removed
afterwards). Invented fixtures only. Every `go` command went through `runs-b7/shell/scripts/gorun.sh`.

## Tests and probes run
- `go test ./internal/server -run 'TestEmptyCatalogue|TestShell|TestLauncher'`: **FAIL**:
  TestShellProgramOnlyWithLauncherURL fails (finding 1). TestEmptyCatalogueAnswersWhole PASS (3.0 s),
  TestEmptyCatalogueRoutesListed PASS, TestLauncherLinkOnlyWhenGiven PASS (2.4 s).
- `go test ./internal/appshell` (whole): ok, 5.8 s.
- `go test ./internal/viewer -run` with TestShellRoutesThisPCOnly, TestShellOptions, TestShellPageWiring,
  TestShellOlderCatalogue, TestAppURL, TestWall*, TestShellIsOnlyTheWindowsOwn, TestHomeDeviceGetsNoWindowBehaviour,
  TestLANRouteClassesAndSecondLocks, and my probe: all PASS, 11.9 s.
- My probe (a scratch test on the actFix fixture with a door set and no AppURL):
  - probe 1: `actOn=true`, `NoCollector=true` (finding 2);
  - probe 2: `GET /api/shell` with `Sec-Fetch-Site: cross-site`: 403; same-site with a foreign `Origin`: 403;
    plain from this PC: 200;
  - probe 3: the list's catalogue handle (`actCatalogue`): `Writer()` is nil, a `CREATE TABLE` through its reader
    is refused.

## Findings

**1. Must fix: a test of the pages' own server fails.** `internal/server/launcherlink_test.go:69`
(TestShellProgramOnlyWithLauncherURL) expects "program" to be the **last** entry of the foot. The lent part now puts
About after it (`internal/appshell/shell.go`, `launcherFoot` then `about`, about lines 341-343). The run printed:
`the foot: [settings, viewer-settings, accounts, program, about]`. Pages (P7, message 221) confirmed the new foot
order for appshell's own test (`TestListProgramOnlyWithLauncher`). Nobody changed this test of `internal/server`, so
the full runs at merge will fail on it. The cure is pages' to make: one line in that test (look for the "program"
entry by its key, not by its place), as a lent change with P7's yes or inside W1b. Or keep Program last, if pages
prefers that.

**2. Must fix: "Old archive: nothing collects this archive" shows in two launcher modes where a collector runs.**
`internal/viewer/shellmount.go:80` sets `NoCollector: v.cfg.AppURL == ""`. Only the joined window sets AppURL
(`cmd/tgarchive-window/main.go:400-409`). Two of the launcher's viewer settings start the viewer with no pages
address on the app's own catalogue while its collector runs:
- "a window of its own" (`internal/launcher/start.go:207-214`: `tgarchive-window -db -library -staging`, no `-pages`);
- the viewer in the browser (`start.go:216`; `cmd/tgarchive/viewer.go:104-109` gives no AppURL).

Both also hand the viewer the collector's door (`Act: viewer.NewActDoor(...)`). The list then says "Old archive /
nothing collects this archive", and clicking that entry gives "This archive is only viewed: no collector runs on
it." That is untrue there. The same lists also leave out Overview, the Collecting group, Settings, Accounts and
"N more". Probe 1 shows it: with the door set and no AppURL, `actOn=true` and `NoCollector=true`. Message 204
defined the mode as "started without a pages address **and with no door file**". The piece built only the first
half.

Cure: set NoCollector only when there is no AppURL **and** no door was ever seen (for example `!v.actOn()`, or the
door file is absent beside the catalogue). In every other case without AppURL, draw the pages' places as dead
entries with a true reason (`Options.PagesOff`, such as "The app's pages are not in this window").

**3. Should fix: nothing in the list leads to the viewer's own Chats page.** On this PC the top bar, with its Chats
tab, is hidden (`internal/viewer/web/app.css:1045`, `body.as-on #top { display: none; }`). The list has no entry for
`/chats`. The brief asked for that ("/chats has no entry of its own"), but the old list had "All chats". The page
can now be reached only through a chat page's back link (`web/js/chat.js:222`). Three cases suffer:
- Every chat hidden: the line `allHiddenDead` (`shell.go`) sends the owner to "the viewer's Chats page", which
  nothing in the list leads to.
- Hidden chats: these are shown again only from that page.
- The old archive's window: "N more" is left out with NoCollector (`shell.go`, around line 292), so chats beyond
  `MaxChats` (200) cannot be reached from the list at all.

Cure: a Viewer-owned "All chats" entry (`/chats`) in the Chats group, or let the "Every chat is hidden" entry and the
NoCollector "N more" lead to `/chats`.

**4. Minor: when the list's first answer fails, the page has no way to move between places.** `body.as-on #top`
hides the top bar as soon as the shell mounts, whether or not the list has an answer. On a first load with nothing
kept, a 503 (`shellmount.go`, the catalogue not opened) or a 500 (`APIHandler`, a real error of this build) leaves
only the word "Places" and no tabs. The failure is narrow, since the viewer opened the same file at `New`. Also,
`APIHandler` writes no log line on a `List` error, so such a 500 is silent. Cure: keep `#top` until the list has
drawn an answer (a class set by shell.js when `state.answer` exists), and log one constant line on a `List` error.

**5. Minor: the older-catalogue test is only a near copy of step 16, and the fallback treats every error as an older
file.** `shell_older_test.go` `toStep16` drops only `chat.protected` from a current file. A real step-16 file lacks
every table and column of the steps after 16, so `ListChatReads` and the others are not exercised as they would
fail there. The degrading is generic per part, so it should still hold. Also, on any older file `olderOK` takes
every error as "older": an I/O or busy error is drawn around silently, and `plainChats`'s failure returns
`nil, nil`, even on a cancelled request. Acceptable for a read-only view; worth one comment.

**6. Minor: in the old archive's window, Saved Messages points to a page the list does not have.** In NoCollector
with no account, the Saved Messages line is `savedNoAccount`, "No account is signed in yet: add one on Accounts.",
and Accounts is left out in that mode. P7's note (2) of message 221 found the same kind of thing for `chats:none`,
which was fixed; this one was not.

**7. Minor: an account's own chat is listed twice.** It shows in the head as Saved Messages and again in the Chats
group. Clicking its Chats-group row moves the mark to the head entry: `main.js` `placeKey` maps `/chat/ID` of an own
chat to `saved:ACCT`. The viewer's old list left own chats out of its chats part (old `shell.js`:
`c.self || own.has(c.id)`). Pages' list does the same, so this is a choice for pages.

**8. Minor: `/saved` with no account named can mark nothing.** `placeKey` takes the first account by id from
`store.meta.accounts`, and the viewer reads removed accounts too (`refresh.go:507`). The list draws only live ones
(`shell.go`, the `live` filter). When the lowest-id account is removed, no entry is marked.

**9. Minor: a modified click becomes an in-page move.** `shell.js` `clicked()` hands Ctrl-, Shift- and Alt-clicks
to the hook as well, and the hook makes them in-page navigations. The viewer's own link handler leaves those alone
(`main.js:62`). This is pages' code, so pages' list behaves the same.

## Found sound (read and, where said, probed)
- **The walls.** All three shell routes are of class local and each checks `thisPCOnly` again.
  - A device at home gets 403 on all three, and its page has no `/shell/` tag; the top bar stays
    (TestShellRoutesThisPCOnly).
  - Another web site cannot read the list (probe 2: cross-site 403, foreign origin 403). The file answers carry the
    page's CSP and CORP same-origin.
  - The CSP is unchanged (`script-src 'self'`). shell.js puts every catalogue text in by `textContent` and has no
    `innerHTML`. It sets styles through the CSSOM, which `style-src 'self'` allows.
  - The viewer imports `internal/appshell`, which imports the catalogue and the standard library only
    (TestWallDependencies and TestWallImports pass). No Telegram code, no `internal/server`.
- **The catalogue handle.**
  - It is read-only and cannot write (probe 3: `mode=ro`, `query_only`).
  - It is a WAL reader with no transaction held between statements, so it does not block the collector's writer.
  - It opens only after `New` has seen the file at a schema it reads: the window waits for it (`waitCatalogue`) and
    `ReadOnlySchema` checks the step. A file that is not there yet is not opened and not cached, so the next request
    tries again.
  - It is closed in `Close` before the side files are cleaned.
  - Cost: the same `List` as pages', whose median is 184 ms at 5,017 chats. The viewer adds an in-memory
    hidden-chats map lookup and one count read from memory. It is asked once per full page load, not per in-page
    move.
- **LauncherURL.** It is `pages[1]` of the joined line, which matches `present.go` `windowLine` (pages first,
  launcher second; P7 keeps that order, message 221). It is checked like AppURL in `New`.
- **The router.**
  - A list click on a viewer place makes one in-page navigation: shell.js calls `preventDefault`, and main.js's
    document handler then returns on `defaultPrevented`.
  - A pages place has another origin, so the browser follows it.
  - Back runs `route()` and then `select`. The keys match the package's for every viewer address in the brief.
  - The search box moves into `.lib-top`, which `LibraryPage` builds at once, so it is there on mount.
  - The post view (`.item`, z-index 50) covers the strip (40) and the list (30).
- **Pages' side.** P7 read and accepted the order of the Library group and the foot, `Counts(ctx)`, `SkipChat` and
  `NoCollector` (message 221). The `.as-pill[hidden]` rule changes what pages show: the empty VPN pill outline no
  longer shows. Pages called it its own defect.

Not verified: the layout at 900 px wide (no window opened). I read the CSS only. Between 761 and 900 px the content
is 491 to 630 px wide beside the list, and the library's filters fold at 900 px and below.

**may be listed after these fixes: 1, 2**
