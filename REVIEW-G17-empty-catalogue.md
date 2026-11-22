# Review G17: the pages on an empty catalogue (wip/pages-empty 4bc6a229, base 78739d59)

Independent review (Opus), read-only on `wt-pages-empty` (`git status` there clean after; head still 4bc6a229).
Probes, dumps and screenshots in `wt-pages-review-g17-scratch` (overlays `overlay-filled.json`,
`overlay-plant.json`; `probe/`, `plant/`, `out/`, `shots/`, `compare.py`). Every go command went through the
track's lock (go1.sh); named tests only, each under a minute of run time; no race run. Edge headless only, with
its profile folder in the scratch folder (removed after each load; none left, no Edge process with that profile
left), the test's own flags (`--proxy-server=http://127.0.0.1:9` and the rest), servers on 127.0.0.1:0 only.
Invented data only; nothing to Telegram; the owner's app, its folder and its ports were not touched.

## Question 1: do the rewritten scripts still draw a FILLED archive? Yes: confirmed, identical to the base.

What I loaded (156 page loads, all dumped and kept in `out/`): 13 addresses (`#/overview`, `#/chats`,
`#/chats?mirror=blocked`, `#/chats?mirror=mirrored`, `#/queue`, `#/queue?dc=1`, `#/queue?dc=2`, `#/queue?dc=7`,
`#/accounts`, `#/import`, `#/settings` with its mirror and clicks regions, `#/report`, `#/staging`) x 2 widths
(1280x900 at scale 1; 390x844 at scale 2, as the coder's test) x 3 filled archives x 2 script sets:
- **program**: the package's fixture (`newEnv`) plus `fillQueue(3000)` (four servers: wanted, 40 in transfer,
  set aside under two reasons, held, gone, saves) plus invented files on server 7 in transfer, set aside (one a
  probable copy), held, gone and wanted (one big); the program's fakes filled: `fakeProgram` with two accounts
  running and five lanes (unlimited, limited with a wait and sleepers, storm, starved), a verdict; `fakeStaging`
  with 3 of 4 copiers busy, a written speed, a rate, wanting-again held, 8 staged files of which 3 stuck (three
  reasons); `newDemoMirrors` (every mirror state); `fakeSignIns`; `newFakeClicks`; Reads and Quit.
- **alone**: the same filled catalogue without the program, on the fixture's clock (so the 48 hours have figures
  and the chart is drawn).
- **demo**: the demo exactly as `newDemoEnv` builds it (read-only copy of the fixture, `NewDemoLive`, its own
  invented mirrors).
- **head** = the branch's embedded assets; **base** = 78739d59's `web/assets` (from `git archive`) served in
  place of the embedded ones by the probe's handler (the same head Go server: on filled data the Go changes are
  no-ops, every list is already non-nil).

Compared per page and width (`compare.py`): the whole `<main>` text with digits folded, the regions (h2 titles,
each region's text length) and the error boxes. **All 78 head/base pairs are the same text, the same regions,
the same error boxes** (e.g. queue wide, program: 14,919 characters and 8 regions on both; staging: 5 regions;
settings: 10 regions). No script error in any console log (only an Edge component extension's own startup line,
on base and head alike). The only error box anywhere is the Overview's mirror note "2 blocked: they need you",
drawn with class `error-box` on purpose, on base and head alike. Screenshots looked at: program Queue (tabs,
counts, downloading now per account), Staging (verdict, three stuck rows with and without the button, the held
want-again, numbers, copiers, hours, folders), Overview (both accounts' lane tables, staging line, mirrors,
tiles, estimate), alone Overview (the 48-hour chart with an hour's table), Settings at both widths (head and
base).

## Findings

**1. should fix, confirmed: `TestEmptyCatalogueRoutesListed`'s pattern misses GET routes not written as one
plain literal without a wildcard.** The pattern `"GET (/api/[^"\s{]*)"` needs the closing quote right after the
path, so `"GET /api/zz/{id}"` (a path wildcard: the form the viewer package already uses, `GET /api/act/chat/{id}`),
a method-less `mux.HandleFunc("/api/zz", ...)` (answers GET too), `http.MethodGet+" /api/zz"` and a raw-string
literal are all not found, and the test passes with them unlisted. Probe `TestReviewRoutePattern` (the test's
own regexp over planted registrations): decisive lines `PATTERN handle("GET /api/zz/{id}", f) found=[]`,
`PATTERN mux.HandleFunc("/api/zznomethod", f) found=[]`. Today every GET route is a plain literal (mirrors and
clicks routes outside the main table included: `"GET /api/clicks/settings"` is a constant and is found), so
nothing is missed now. Fix: match `"GET /api/...` up to the closing quote including `{...}` segments and fail on
any wildcard route that `scriptGets` does not name with a filled value, and fail on any method-less `/api/`
pattern; or, sturdier, register through a recorder (wrap `mux`/`handle` in a test seam) instead of reading
source text. Note too that the test reads the files on disk, so it cannot be probed by an overlay; I applied its
regexp directly.

**2. should fix, confirmed: `askEmpty`'s "documented refusal" clause also excuses the state's REAL account and
chat.** The clause accepts 404 or 400 for any path containing `chat=1` or `account=1&`, meant for the placeholder
1 used when a state has no chat. But in the states one-chat and many-accounts the real account and chat ARE
number 1, so a regression that made `GET /api/chats/topics?chat=<real chat>` or
`GET /api/mirrors/plan?account=<real>&chat=<real>` answer 404 or 400 on a new catalogue would pass. Probe
`TestReviewRealIDs`: `REALID one-chat acct 1 chat 1: GET /api/chats/topics?chat=1 -> 200`,
`REALID many-accounts acct 1 chat 1: GET /api/mirrors/plan?account=1&chat=1 -> 200` (they answer 200 today, so
nothing is wrong now; the test simply could not tell). Fix: excuse a refusal only when `acct == 0` / `chat == 0`
for the state (the placeholder was used), e.g. by passing a flag into `askEmpty` instead of matching the text.

**3. minor, confirmed: the allow-list is right for the empty states but will need entries as states grow.** Its
one entry (`/api/accounts .accounts[].removed_at`) is right: null means "not removed" and accounts.js tests
`a.removed_at != null`. On the filled archives (probe `TestReviewFilledNulls`, every `scriptGets` route on
program, alone and demo) the only other null is `.aside[].best_rank` on `/api/queue` (a set-aside file whose
chats have no rank; the page draws it fine on base and head). Adding a state with a set-aside file (state (3)
has none) will fail the test on it; add it to `nullAllowed` with its reason then. No other null on any filled
answer.

**4. minor, confirmed: the console check sees uncaught errors only.** Probe `TestReviewConsole` (a page of my own
on 127.0.0.1): `Uncaught (in promise) Error` and `Uncaught TypeError` are reported by `pageFaults`, a plain
`console.error('zzconsole')` is not (Edge logs every console line as `INFO:CONSOLE`, so the level is lost; the
filter keys on the words "Uncaught"/"Error"). The pages call no `console.*` today, so nothing is missed. Also: an
Edge component extension writes its own `:CONSOLE` line into the same log on every load
(`[ProtocolLaunch] handler constructed...`); harmless now, but a line of its containing "Error" would fail the
test for a reason that is not the page's. Filtering console lines to `source: http://127.0.0.1` would close both.

**5. minor, plausible: on a `go test -timeout` panic the browser's profile folder is left in the system's temp
folder** (`browseOnce`'s deferred `removeProfile` does not run; the Edge child ends by itself after its 8 s
budget). On an ordinary failure (`t.Errorf`, or the 45 s context) the profile is removed; `removeProfile` gives up
silently after 5 s if a file stays locked. A profile under the test's `t.TempDir()` would be cleaned by the test
framework in the normal case and is no worse on a panic.

**6. minor, read: the Queue's "nothing yet" words are true of the code, but skip a step and fit a finished
archive badly.** "Files appear here once a chat is read: choose a chat on the Chats page (its row says how to add
it)": checked: in the program the Chats rows offer the read's estimate and approval (state.reads), on the pages
alone the page shows how to add a chat with the collector command; "ranked chats first" matches the next-list
order. But with no account at all the Chats page says "No chats yet... needs the Telegram connection", so the
sentence could say "add an account on the Accounts page first" when `d.accounts` is empty (the Overview already
does). And the same words show when every file is saved or skipped and nothing is left to want ("yet ... once a
chat is read" then reads oddly); the old words' "or import a list" (the Import page still exists) were dropped.
The Overview's new no-account words are true: the "Add an account" button exists on Accounts with the sign-in
seam (`state.sign_in`), and the pages-alone variant says to open the program; groups are per non-removed account,
so "No account yet" shows only when there is none.

**7. minor, read: `drawRegion`'s line says "reload the page to try again", while most regions try again by
themselves.** Checked the kept shapes: Queue's `safe` deletes `st.shapes[name]` on a failure, so the next paint
rebuilds the region (`placeAction` gives "build"; only while the pointer is over the region does it "hold" and
patch, and it rebuilds on pointer-leave); regions without a shape (counts, now, storm, gone) are mounted again at
every paint; Staging's needs region resets `st.shape`; Overview's lanes reset `shape` and are redrawn at every
live answer (2 s); Overview's hours and numbers are redrawn only when `as_of` moves. So a failure is never
swallowed silently (each shows an `error-box` with `role="alert"`, which `TestPagesInBrowser` also catches) and
is never drawn once and kept for good. The words could say "it is tried again at the next reading" for the
regions that are; not a defect.

## Question 2 in short: `whole` and "not known"
Read every `whole` call against the Go answer types: none of the fields made whole is absent or null on purpose.
`settings.library`, `accounts.slots`, `overview.estimate` and `totals` are values, never null; staging's `hours`
(absent on purpose without the store) and `folders` are left alone (`if (st.data.hours)`); the mirror answer
already gives `states: []` with `error` or `refused` set, and `cellOf` reads `acct.error` before the state, so an
unreadable account is not shown as "nothing"; Queue's `transfer` was already read with `|| []`. The only
null-on-purpose field (`removed_at`) is not touched. The `omitempty` lists (`changed`, `waits`, `offers`,
`evidence`, `outcomes`, `causes`, `times`) are all read with `|| []`.

## Question 3 in short: the Go tests
`TestEmptyCatalogueAnswersWhole` fails for a listed route that answers a nil list: planted by overlay
(`GET /api/zznil` answering `{"list": null}` in server.go and in `scriptGets`): decisive line
`empty_test.go:338: GET /api/zznil (ask 1): null at .list`, in all 8 state/mode subtests. A new route is forced
into `scriptGets` by `TestEmptyCatalogueRoutesListed` only when written as a plain literal (finding 1). Routes
registered outside the main table (mirrors, clicks) are found; no `/api/` GET route is registered outside
`internal/server`. The four states are made as the program makes a new catalogue: `catalog.Open` of a new file,
the account row with the collector's own statement (`account_add.go`), `SetAccountUserID`, the chat by
`SaveMessages` with no message; the seams are idle fakes, not the real adapters (said in the coder's report).

## Question 4 in short: `TestPagesInBrowser`
Skipped and says so without the variable (`browser_test.go:34: TGARCHIVE_BROWSER is not set`, `--- SKIP`).
A browser that dumps nothing twice fails (`no page was dumped`: the dump must hold `id="main"`); a page still on
its first "Loading…" fails; uncaught script errors fail (finding 4 for the rest); an error drawn after the 8 s
virtual budget is not seen (inherent, acceptable). Flags: everything but loopback goes to the dead proxy port
(Chromium never proxies 127.0.0.1); background networking, component update, sync and extensions off; I did not
measure the browser's connections (plausible, not confirmed). Profiles: finding 5.

## Question 5 in short: the Theme row's CSS
Confirmed by screenshots of the same filled Settings with the base's and the head's CSS: on the base, Theme,
"Most parts in flight per server" and "Big-file size" have their two help lines drawn over each other; on the
head each second line has its own row, at 1280 and at 390 (scale 2) widths. Rows with a wide input (Viewer
address) and the switch row, the fixed rows, and the mirror and clicks regions look the same as on the base; the
page's text is identical. A field with no second help gets an empty "more" row (2 px of row gap): invisible.

## Not checked
The real `livepages` adapters (only the fakes); clicks, dialogs and the sign-in dialogue (pages were loaded and
dumped, nothing clicked); the browser's actual network connections; the narrow header that does not wrap (known,
out of scope); the look (out of scope).

Counts: must fix 0; should fix 2 (1, 2); minor 5 (3, 4, 5, 6, 7).

may be listed after these fixes: 1, 2
