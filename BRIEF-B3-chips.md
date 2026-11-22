# Brief B3-9: filter chips with counts, what is hidden as a chip, clutter per chat (session B3, 11-15)

You are an Opus coder. Work only in the copy `C:\Users\trabi\Claude\Projects\Telegram\wt-b-faces`. First:
`git fetch private wip/b-viewer && git checkout -B wip/b-chips private/wip/b-viewer` (ee64eb5). Go module:
`archiver/`. Go: `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh` in each Bash call.
Package: `archiver/internal/viewer` only (Go and `web/`). Commit after each part and
`git push private wip/b-chips` (`git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, ending
with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; no archive numbers).

## What is asked (FEATURES sections 7 and 9: listed, so already asked for)
- "Every active filter and every hiding rule shown as a removable chip with a count; search kept apart from
  filters." "Hide a chat or a post; unhide all: show what is hidden as a chip with a count."
- "A clutter rule (stickers, tiny files, very short videos, items posted in very many chats), per chat: show
  all / hide clutter / hide all." Today: one switch in Settings for the whole library.
- The owner's rule for every number (TRIED-BEFORE 10): it says what it counts and adds up; and the old
  viewer's lesson (12.17): a filter chosen while a page loaded showed the old results.

## What the code has (read first)
`library.go` (`filter`, `buildListing`, `listCache` with one build per listing, `listingFor`, the listing
identity), `appear.go`, `decisions.go` and `marks.go` (the owner's marks by stable key: a space is shared /
Telegram chat number / the owning account's Telegram user number; **nothing in `decisions.sqlite` may be
keyed by a catalogue row number**), `web/js/library.js` (the sidebar, `FILTER_KEYS`, the address is the
filter), `settings.js`.

## Part 1: chips
- A row of chips above the grid (the sidebar stays): one chip per active filter value, in plain words (the
  sidebar's own labels: "Videos", "Saved", "Chat: <title>", "Not in: <title>", "Topic: <title>", "From … to
  …", "One person", "Only where it first appeared", "Also in: <title>" and so on), each removable with one
  click (it edits the address like the sidebar does); "Clear all" when two or more. Search is not a chip: it
  stays in its box.
- **Hiding rules are chips too, each with the number of tiles it hides in this listing:** "Clutter hidden:
  N", "Hidden posts: N", "Hidden chats: N (M chats)". A click on the count shows them (clutter: the same
  filter with clutter shown; hidden posts: the existing `hidden=1` view; hidden chats: a small list with
  "unhide" per chat and "unhide all"). The numbers come out of the one listing build: while walking, a tile
  dropped by a hiding rule is counted for the first rule that drops it, in a fixed order (hidden chat, hidden
  post, clutter) and only if it would otherwise be shown; they travel with the shape. So shown + hidden by
  each rule = what the filters alone give, and the row says so in its title text. No second listing build.
- The shape also carries the total without filters for "N of M" (kept per index version, not rebuilt per
  request).

## Part 2: clutter per chat
- The rule gains the two listed kinds the code lacks: stickers (if the index can tell: look at how the
  catalogue marks them; if it cannot, say so and leave it) and "posted in very many chats" (a file in more
  than 20 chats: `overlap.go` already counts these per index version; reuse, do not walk again per listing).
  Each kind is a checkbox in Settings beside the existing sizes; defaults: the existing ones on, the new two
  on.
- Per chat: show all / hide clutter / hide all. "Hide all" is the existing hidden chat. "Show all" and "hide
  clutter" are a per-chat choice that overrides the library-wide switch: kept in `decisions.sqlite` in a new
  table keyed by the chat's stable key (as `mark` is), worked out per index version with the marks
  (`marks.go`), in the listing's key through the decisions version. A tile is clutter-hidden only when every
  allowed post of it is in a chat that hides clutter. The control: on the Chats page's row and in the
  library sidebar's chat list (a small three-way menu per chat).
- The per-chat choices survive a fresh bring-in like the marks (same test shape as `marks_test.go`).

## Tests (named, while working)
Chips' counts add up on an invented catalogue (hidden chat, hidden post, clutter, all three on one tile:
counted once, for the first rule); "N of M"; per-chat clutter: a file in a show-all chat and a hide-clutter
chat stays; the choice survives a renumbered catalogue; the listing key changes with a per-chat choice. Then
once at the end: `go test ./internal/viewer -p 1` (about 3 minutes, in the background), `gofmt -l`, `go vet
./internal/viewer`, `node --check` on the scripts. No race detector, no mutation checks, one go command at a
time. The viewer's import wall (`TestWallImports`) lists what the package may import (`cmp` is not in it).

## Rules
- Never open the viewer on real data or any real file, never open the owner's real `decisions.sqlite`;
  nothing against Telegram; do not touch `repo-archiver`, other `wt-*` folders or other packages. Do not
  merge into or push `claude/charming-feynman-vm2xia` or `wip/b-viewer`.
- CSS in one block at the end of `web/app.css`. Another coder works on `wip/b-play` (new `play.go`, the
  video's drawing code in `item.js`, one field in Settings): before the last whole-package run
  `git fetch private wip/b-viewer` and merge it if it moved (keep both sides).
- Concurrent code: say exactly what requests share and how it is guarded.

## Hand back (short)
Commits, differences from this brief and why, named tests, whole-package time and result, what is shared
and how it is guarded, doubts.
