# Independent review of `wip/b-once` (head 18725db) against d1af260 (11-15)

Read-only. Worktree `wt-b-faces` left as it was (clean, at 18725db, before and after). Probes: one test file and a
Node replica in my scratch folder under `%TEMP%`, loaded with `go test -overlay`, run by name, `-p 1`,
`GOMAXPROCS=2 GOGC=50`. Invented data only. Free memory 10.3 GB at each run; CPU about 60 % busy before the runs
(another reviewer on the PC), so every time below is "looks like".

Counts: **4 CONFIRMED** (3 "a file missing for the owner", 1 "wrong for the owner": a broken switch), **3 PLAUSIBLE**
(1 "wrong number", 2 "cosmetic"), plus a cost note and test gaps. Every probe's counts added up
(`shown + chats + posts + clutter + once + not_saved + folded = filtered`): no count finding.

---

## 1. CONFIRMED, a file missing: a post hidden by the owner takes its file's other posts out of the whole library

- Where: `library.go:845-851` (first places leave out hidden chats and left-out chats only) and `appearFile`,
  `library.go:906-916` (the tile must be at the file's own first place, and that post must pass `postOK`);
  `evalSet` drops a set with a hidden post at `library.go:1096`.
- Inputs (probe `TestProbeHiddenEarliestPost`): two saved exact copies x1 (chat A, earlier) and x2 (chat B, later),
  each its own post; the owner hides x1's post. Rule `show`, `copy` and `hide` alike: each file once **off**, x2's
  tile shows; **on (the default)**, no tile for x2 anywhere. It is counted under "Each file once: … left out"
  (Once 28 incl. it), x1 under hidden posts, so the numbers add up and `first=0` brings it back, but the default
  view has lost a visible saved file.
- Same root cause, by reading only: a chat's own clutter choice ("hide clutter" in the chat of the earliest post,
  "show" in a later chat) drops the group the same way.
- Before this branch the default listing showed x2. Hiding a post now hides its file in the unified stream.
- Smallest fix I would accept: when choosing first places for the whole-library rule, skip places in hidden posts
  as hidden chats are skipped (a per-message `out`, `appear.fileFirst`), with the overlap table's decision used
  only when no post is hidden; or a second pass like `placeOnce` whose `pass` is "this file's first-place tile
  survives the three hiding rules", moving a dropped file to its own next place that survives, else to a group
  member's. Plus a named test with this fixture.

## 2. CONFIRMED, a file missing: a search or a type filter in the whole library misses files whose matching post is not their group's earliest

- Where: same as 1. With `firstRule`, `postOK` (search `q`, `caption`, `account`, `deleted`) and `mediaOK` (type)
  are judged only at the group's earliest place (`library.go:1100`, `906-916`).
- Inputs:
  - `TestProbeSearchLaterPost`: x1 (A, no caption) = x2 (B, caption "… zebraprobe"), and one Telegram file posted
    in A (no caption) and later in B (caption "… zebraprobe"). `q=zebraprobe`: each once off: 2 tiles; on (the
    default): **0 tiles**, `Once: 2`. The owner's search in the whole library finds nothing.
  - `TestProbeTypeFilterAcrossGroup`: a document (A, earlier) and a photo (B) linked by a probable edge (the same
    picture sent as a file and as a photo is the usual case). `type=photo`: off: the photo's tile; on: **none**,
    counted under Once.
  - `TestProbeDateRangeLaterPost`: x1 earlier, x2 thirty days later; a range covering only x2's day: off 1 tile, on 0
    (Once 1). This is first=1's documented "new between" meaning; whether the owner wants it as the unified
    stream's default is a decision for the owner, not a defect.
- Smallest fix I would accept: for the rule (not for an address's `first=1`), when any post filter, search or type
  filter is set, decide first places among the places/files that pass them (a per-listing decision, as with a
  hidden chat; the cost note below says what that costs on the invented catalogue), or turn the rule off for
  search queries and say so on the chip. Tests with the fixtures above.

## 3. CONFIRMED, a file missing (rule `hide`) / one picture on two tiles (rule `copy`): `placeOnce`'s "free" check counts members that the rule itself will drop

- Where: `notsaved.go:316-325` (`free` is false when any other shown file of the candidate's group is shown, even
  one that fails `pass` and so will be left out).
- Inputs (`TestProbeChainUnderHide`): t (A, earliest, not downloaded), y (B, next, not downloaded), c (C, last,
  saved); probable edges t~c and y~c only (two re-encodes of one picture: probable is not transitive). Groups:
  {t,c}, {y,c}, {c,t,y}; first appearance shows t and y, hides c.
  - Rule `hide`: for t, candidate c is not free (y shown); for y, c is not free (t shown). Both stay, both are
    dropped as not downloaded: **the saved file c has no tile anywhere** (NotSaved +2, c under Once).
  - Rule `copy` (the default): t and y both pass by their stand-in c, so the stream shows **two tiles with c's
    picture**, which is the case the owner asked to fold ("in a unified stream it should be folded under one").
  - Rule `show`: t and y as not downloaded, c not shown (first=1's meaning; the brief says `show` changes nothing).
- Smallest fix I would accept: in the free check ignore shown members that fail `pass` (they are dropped anyway);
  t then moves to c, and y finds c already shown and gives up its place, so c is shown once. For `copy`, at least
  a test documenting the two tiles, or the same move when a passing member is a stand-in only.

## 4. CONFIRMED (on a replica), wrong for the owner: the sidebar's "Only where it first appeared" switch runs two click handlers and is stuck in most states

- Where: `library.js:499-508`. `flag()` builds the button with `h(... { onclick })`, and `dom.js:14` registers
  that with `addEventListener`; line 505 then assigns `this.firstOpt.onclick`, which adds a second listener
  instead of replacing the first. Both run, in that order. `set` → `go` → `navigate` → `route` → `update` sets
  `this.query` synchronously (`library.js:181`, before any `await`), so the second handler reads the address the
  first one just wrote.
- Replica of exactly this wiring (Node, both listeners in order), effective state before → after one click:
  - whole library, preference on, no `first`: on → `first=0` off (works, after one extra listing request);
  - whole library, `first=0`: off → `first=0` **still off** (the switch cannot turn it back on; only the chip can);
  - a chat's view, no `first`: off → **still off**; a chat's view, `first=1`: on → **still on**;
  - preference off, whole library: off → off; `first=1`: on → on.
  So the existing filter in a chat's view no longer toggles at all (a regression), and neither does the switch
  wherever the rule is not on.
- Smallest fix: do not build `firstOpt` through `flag()` (its own `h('button', { onclick: … })` with the new
  handler), or give `flag` an optional handler. A browser check that clicks it twice in a chat's view.

## 5. PLAUSIBLE (reading), wrong number: two snapshot writers at once

- Where: `snapshot.go:225-246` (`writeSnapshot`, no lock), called from the writer goroutine (minute, `use`) and,
  concurrently, from `Stopping()` in `stopViewer` (`cmd/tgarchive/viewer.go`) and at the top of `Close`
  (`viewer.go`), while the writer still runs.
- Interleaving: the writer builds a `use` snapshot at T0, `Stopping` builds and renames the `stop` one at T1, the
  writer renames its T0 file after: the file then says `use` with older numbers. On Windows two `MoveFileEx`
  replacing one name at once can also fail one of them ("could not be written" logged). Temporary names are
  unique, so no torn file. If Windows ends the process before Close's final write, the `stop` mark is lost. Rare
  (the `use` timer fires 3 s after a request; a close within the same milliseconds).
- Smallest fix: a mutex around `writeSnapshot`, and once `Stopping` has written, the writer writes only `stop`.

## 6. PLAUSIBLE (reading), cosmetic: the video click

`play.js:68-86`:
- A drag on the browser's own seek bar that is released above the 56 px strip fires `click` on the `<video>` (the
  controls are in its shadow tree) with `clientY` outside the strip: it toggles. Fix: test the strip (and a
  movement of more than a few pixels) at `pointerdown` too.
- A double click whose second click comes after 250 ms but inside Windows' double-click time (500 ms by default)
  toggles and then goes full screen. Fix: in the `dblclick` handler, toggle back when the timer fired within the
  last ~500 ms.
- While "Opening the file from the library…" shows, that line (`app.css:937`, z-index 2, centred) takes clicks at
  the centre of the picture.
- Sound by reading: never twice (it acts only when `paused` is as at the press; Firefox's own toggle and Chrome's
  centre play button are left to the browser); keyboard (`detail` 0), touch and modifier clicks left alone;
  `dblclick` and `detail` 2 cancel; GIF-type clips get no handler, in `item.js` and for a converted copy; nothing
  outlives the element (the timer checks `isConnected`). Whether Chromium itself toggles on a click (the comment
  says not) I could not check in a browser.

## 7. PLAUSIBLE (reading), cosmetic: "also in N chats" counts hidden chats

`library.go:1803-1823` builds the caption's `appear` with no `out`, and `appear.also` (`appear.go:449`) counts
every chat. Pre-existing for `first=1`, now on every default tile. Fix: pass the listing's hidden chats.

---

## Cost (looks like, CPU about 60 % busy, invented 200,000-message catalogue: 92,233 posts, 40,865 sets, 120,586 files)

- `TestTimingOnBigCatalogue` by name: PASS. Library first page cold 18.0 ms, warm 1.5 ms; filters 8–21 ms cold;
  searches 13–19 ms; cold start 953 ms. All under the 200 ms budget.
- Probe `TestProbeCostHiddenChat` (one chat hidden, so first places are decided per listing build): each once
  **on**: default cold 29.9 ms, `type=photo` 34.1, `q=harbour` 30.4, a date range 27.0, rule `hide` 31.5 / 29.0;
  each once **off**: 13.0, 12.0, 13.0. So about +15–20 ms on every cold listing of the whole library while any chat
  is hidden, linear in the archive's files; fine here, worth a cache of the decision per (index version,
  verdicts, hidden-chat set) if the real archive is several times larger. With nothing hidden: 38.0 ms for the
  first default listing (the overlap table built), 18.0 ms for the next cold filter.

## Tests that would not fail if a named guarantee broke

- No test for findings 1–4 (hidden earliest post; search/type; the chain; the sidebar switch).
- `TestVideoClickPlaysAndPauses` matches source text only: any change to the logic that keeps the strings passes.
- The early write's "only when the numbers changed" and the 10 s gap inside the running writer are untested (only
  `useWait.kick` is, on given times, which is right).
- `TestViewerEndsOnTheCloseSignal` checks that SIGTERM is in the list, not that Go delivers it (it cannot be sent
  to oneself on Windows; the Go sources below say it is).

## Checked and found sound

- `parseFilter`: the rule only with no chat, no topic, not `hidden=1`, not `clutter=only`; `first=0`/`first=1` win;
  the key carries `first` and `|fr`; `first=0` gives the same key as the preference off (test
  `TestEachOnceListingKey`); a preference change gives a new key, so a page holding an old listing id reloads.
- Counts: once is judged after chats, posts, clutter and before not-downloaded; the `n4 > 0` short cut is exact for
  one tile per post with no date range (a set tile is 0 or 1 at every level). Every probe above added up, with
  `first=0`, the three rules, a hidden chat, a search, a type filter and a date range.
- `placeOnce` never writes the table's `shown` (clone on first move); `placedOnce` caches per (table, rule) under
  its own mutex, and the table is per index version, `sameProb` and verdicts, which are everything `pass` and the
  groups depend on; used only when no chat is hidden or left out. `ap.first = tb.firstAt` is read only (every file
  filled by the walk). Not-downloaded group with no passing member: kept at its earliest file and counted once as
  not downloaded, the rest under Once (as the brief asks).
- Shutdown on Windows, from `goroot-1.27.3`: `runtime/os_windows.go:1047-1069` maps CTRL_CLOSE, LOGOFF and
  SHUTDOWN events to SIGTERM and, when a `Notify` wants it, blocks the handler so the program can clean up;
  `os/signal/doc.go:220-226`: Notify returns `syscall.SIGTERM` and the process is still terminated unless it
  exits. `NotifyContext(…, os.Interrupt, syscall.SIGTERM)` therefore wakes the command. `stopViewer` writes the
  numbers first (milliseconds), then gives the servers 2 s in all; `Close` writes again before `wg.Wait`. That fits
  inside the few seconds Windows allows a closed console (Windows' limit is from its documentation as I remember
  it, about 5 s, not checked here). `readHidden` now also restores echo on SIGTERM.
- The early write: one `used` slot, sends never block (also after Close); one timer, stopped by `defer`; the writer
  ends on the context before `wg.Wait` returns, so no write after `Close`; only numbers and fixed words
  (`TestSnapshotNumbersOnly` includes `use`). Tests use given times or wait for a condition, not a span of time.
- Settings switch and sentence; the chip "Each file once: N other posts left out" (`first=0`) and "Showing every
  post" (drops `first`); a device without the right to change preferences gets the rule and the way back (test
  `TestEachOnceOnADevice`). Arrows walk the same listing (`TestEachOnceArrows`).

## Not checked

- No real browser run of the page or the click (the built-in browser shows a local file only as a static snapshot;
  a viewer tab was already open in that pane and I left it alone, unread).
- Albums holding files of two groups, the fold with each once off combined with the rule, `only`/spread filters
  with the rule, verdict "not the same" splits: by reading only, nothing found.
- `TestCloseWritesTheNumbersFirst`, the whole package, `go vet`, `gofmt`: not run (not mine to run).
