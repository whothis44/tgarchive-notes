# K14 on the main head, with the door's three wirings (Core, K-4, 2026-11-16)

K14 at 08990b55 passed its full runs (whole tgstore, telegram, catalogue 470 s, collector 1,207 s on Windows;
the race detector by name on the telegram act tests and the collector's `TestClick`, 2,479 s: no data race).
Meanwhile the pages track's G8 was merged (efac56ff: the routes for the owner's clicks, `internal/actdoor`,
`internal/server/clicks.go`, `internal/collector/livepages/clicks.go`, lines in `internal/collector/pages.go`).
**K14 and G8 meet in one place on purpose:** the plain conversion `ClickInput(in)` in `pages.go` stops
compiling once Core's `ClickInput` has `Key`. Whichever is merged second does three small wirings: that is
K14. Same house rules as before (named tests only, memory measured before each go command, one go command at
a time, the same commit trailer, no `git stash`).

## 1. A branch on the main head

A plain merge of the head into `wip/core-door` conflicts (K9c went into the main branch as one commit). So:
in your copy, `git fetch private`, then a NEW branch `wip/core-door-main` cut from
`private/claude/charming-feynman-vm2xia` as it is then (say its hash), and K14's own commits picked onto it
in order (`git cherry-pick d6415255..08990b55`; each should apply without a conflict: checked with
`git merge-tree --merge-base=d6415255` against f7d6ca63). If a pick conflicts, stop and hand back what
conflicted: do not resolve by hand. `wip/core-door` stays as it is (the tested head 08990b55). Push
`wip/core-door-main` to `private` when the round is done; push nothing else.

## 2. The three wirings (read first: `archiver/docs/progress/pages-door-REPORT.md` section 2, "Where K14
changes things", and the review `archiver/docs/review/pages-g8-clicks-door-2026-11-16.md` for what the door
must keep)

The pages track lends `internal/collector/livepages/clicks.go` and its lines in `internal/collector/pages.go`
for this; in `internal/server` you may ADD fields to `server.ClickState` and rows to the door's word table
where the report's section 2 says so, and change nothing else there.

1. `Key` in the adapter's `ClickInput` at the same place as in Core's, and `Key: in.Key` in the adapter's
   `Queue`. **For:** the key must reach the ledger from the route; the compile break forces the field, not
   the line: a rig test through the adapter shows two queues with one key give ONE click and the same number.
2. One row each in `clickWordTable` and `ClickErrors` for K14's new sentinels: `ErrClickKey` (the word
   "key"), `ErrClickText` (see below), `ErrClickQueueFull` ("queue full"). `TestClickDoorWordTable` sees only
   errors declared as `var Err...` in `click_api.go`: make sure it sees these three, and that no error K14
   can return from an entry point reaches the door without a row (list every error an entry point can
   return and its word in the report). `ErrClickText` covers both an empty and a too-long text: give it the
   word the door's table already has for the request layer's text refusal if there is one; say which.
3. `Collector.ClickState` in place of the body of the adapter's `State`; its fields into `server.ClickState`
   (the times, the limits, `LimitsWanted`, `MarkAsRead`, `MarkBad`, `Cap`, `NowMs`, `Why`). **For:** the page
   must see exactly what Core's state says, by the fixed words; nothing of a chat's name or text. The door
   refuses new clicks from the moment a stop is asked (G8's rule): keep that as it is.

Do not change a route's path, method, token or secret check, nor anything in `internal/actdoor`.

## 3. One read for the viewer (board message 111 c of the viewer)

The viewer will believe a click's number only for the row that carries the page's own key. It has a
READ-ONLY catalogue handle, possibly on a file older than this schema step. Make sure `catalog.ActKey(ctx,
account, key)` works on a read-only handle and answers "not found" (no error) on a file at an older step
(as the ledger's other readers do: `hasAct`); a test for both. If it already does, show it by the test and
change nothing.

## 4. Tests and the hand-back

Named, on the new branch: the door's tests in `internal/server` and `internal/collector/livepages` (by their
names: find them), the collector's `TestClick` and the pages' click tests (`pages_clicks_test.go`), the
catalogue's `TestActKey`; `gofmt -l`, `go build ./...`, `go vet` on the packages you touched. Add a section
to `archiver/docs/progress/core-door-REPORT.md`. Hand back: the head of the main branch you cut from; the
head of `wip/core-door-main`, pushed or not; that every pick applied clean; per wiring the lines and the
test (seen failing first where a rule is new); the list of every entry-point error and its door word; any
file of another track you edited, line by line; the tests as run.
