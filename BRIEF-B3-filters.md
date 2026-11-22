# Brief B3-2: the listed library filters (session B3, 11-15)

You are an Opus coder. Work only in the copy `C:\Users\trabi\Claude\Projects\Telegram\wt-b-faces`. First:
`git checkout -B wip/b-filters private/claude/charming-feynman-vm2xia` (4f1992e, the main branch's head; the
old `wip/b-filters` holds nothing of its own). Go module: `archiver/`. Go: `source
/c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh` in each Bash call. Package:
`archiver/internal/viewer` only (Go and `web/`). No schema step, nothing outside the package.

Commit work in progress as you go (after each of the three parts) and `git push private wip/b-filters` each
time: the session can stop at any moment. Commits: `git -c user.name=Claude -c user.email=noreply@anthropic.com
commit`, the message ending with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; no archive numbers.

## What the old app and the record already say (read by the main session)
- The viewer's rule (TRIED-BEFORE 9, LESSONS 1): a warm index updated in place; nothing proportional to the
  archive per update; a filter is evaluated once per query and kept (`listCache`), then paged; no request
  waits on the library. The old 12.22 viewer re-filtered every file on every request (0.4 to 2.2 s).
- Paging keys must stay stable when the index changes between pages (12.32 review): the library pages by
  `(date, key, pos)` cursors; keep that for anything new.
- The owner's request (FEATURES 12, seventh round), in short: per group a toggle "first seen here" (media
  whose earliest post anywhere in the archive is in this group) and "only here" (media no other chat has);
  "new media between these dates" (the first post anywhere falls in the range, so a repost of something older
  is not new); one combined view of all groups, any of them switched off, each media item once at its first
  post with "also in N chats"; "the same media" = the same Telegram file, the same bytes, confirmed copies,
  and probable copies by default with a switch; composes with the other filters; the page says the dates are
  as of what the archive holds.
- The real archive (counts): 584,075 messages, about 350,000 files in the index, 143,294 sets, 224 chats, 570
  topics in 18 chats; 85 % of media messages are forwards. Only 8 messages carry a deleted mark and none has
  a file, so "deleted" must also work for text-only posts or it shows nothing.
- Sets (`refresh.go`): posts join a set only by identical file lists or an origin that names one post. Do
  not change the set rule and do not merge sets.

## Part 1: topic filter in the library
- Query `topic=<topic id>[,<id>...]` (the catalogue's `topic.id`, as `chats.go` already takes it). A tile
  stays when one of its allowed posts is in one of the topics (it joins the existing loop over a set's posts
  in `buildListing`: chat, account, search, caption). It goes into `filter.key`.
- Sidebar (`web/js/library.js`): when exactly one chat is chosen and it has topics, a "Topics" group under
  the chat list: each topic with its count of posts with files, most first, several may be chosen. The
  topics and counts come from the index the way `handleChat` builds them (no SQL per click beyond titles
  already in the index).

## Part 2: deleted on Telegram (badge, filter, list)
- `msgRec` gets `deletedAt int64` (`message.deleted_at`, 0 = not deleted). Read it in the full read and when
  a known message is read again because the change log named it (kind 4: `refresh.go` around the comment
  "Not yet taken in here: ... the deleted mark"). A post is deleted when every message of it is; "partly"
  when some are. Keep `postRec` small: one field for the latest `deletedAt` of its messages and one bool
  "all". The catalogue column exists from schema step 7: if the catalogue is older, read 0.
- Badge "Deleted on Telegram" (with the date the app saw it) on: the post page's place rows and messages,
  the conversation view's posts, and a library tile when the post the tile opens is deleted (it counts as
  one of the tile's at most two badges).
- Filter `deleted=1`: only tiles with a deleted (or partly deleted) allowed post; the tile then opens that
  post. In the sidebar as one switch with its count.
- List: a page "Deleted" in the navigation: every post with a deleted mark, text-only posts included, newest
  deletion first (`deletedAt`, then the post's lead id), 60 a page with a stable cursor `(deletedAt, lead)`;
  rows drawn as the conversation view draws posts (`convPosts`), each linking to its post and chat. Built
  once per index version and kept (it is small), not per request. An empty list says "Nothing in this
  archive is marked as deleted on Telegram."

## Part 3: first appearance ("first seen here", "only here", "new between dates", the combined view)
Decided per file, at listing time, from what the index already holds (a file's places, its copy edges). No
new per-set state in the index, no SQL.
- **A file's group** = the file, plus every file reachable by exact copy edges (same bytes; follow them
  transitively but stop at 64 files: look at how the catalogue writes exact edges, they may already be
  complete), plus, when probable copies count as the same (the default; `sameprob=0` switches it off), the
  files one probable edge away from any of those (one step, never a chain: the owner refused chained merging).
- **The group's first place** = its earliest message by `(date, message id)` over all places of all its
  files, leaving out messages in chats the query leaves out (`xchat`) and hidden chats.
- `first=1`: a file is shown only at its group's first place: only in the tile whose set holds that
  message's post, and only if it is the file attached there. With chats chosen (`chat=`), the first place
  must also be in a chosen chat: that is "first seen here". With no chat chosen it is the combined view;
  `xchat` switches groups off. The tile's date is the first place's date and it opens that post; the
  existing `from`/`to` then mean "new between these dates". In one-tile-per-post mode a tile stays when at
  least one of its files qualifies (cover: the first that does; date: the earliest such first place).
  Entries must be sorted after, as the chat filter already does.
- `only=1` ("only here"): every place of every file of the group is in one chat (the whole archive, `xchat`
  not applied); with chats chosen, that chat is a chosen one.
- The tile's JSON gets `also`: in how many other chats the group has a place (shown "also in N chats" on the
  tile's caption line when `first=1`), and nothing else new.
- Sidebar: a group "First appearance": "Only where it first appeared" (`first=1`), "Nowhere else"
  (`only=1`), "Probable copies count as the same" (on by default; shown only when one of the two is on). One
  line under it: "As of what the archive holds: adding an older chat can move a first appearance." The date
  fields' label reads "New between" while `first=1` is on.
- All three go into `filter.key`. Work per tile must stay bounded: a group is at most 64 exact files plus
  their one-step probable neighbours, and a file with more than 200 places uses its first 200 for "also"
  (the first place itself must still be exact: places are ascending by message index, so check whether that
  is date order; if not, scan them all for the minimum only).

## Tests (named, while working)
One small table-driven test per part on an invented catalogue (the package's existing helpers; invented
names and text only): topic filter; the deleted mark read at a full read and again after a change-log row,
the filter and the list's order and cursor; first / only / `sameprob=0` / `xchat` on a handful of files with
exact and probable edges across three chats, in both tile modes. Run them with `-run`. Then, once, at the
end: `go test ./internal/viewer -p 1` (about 3 minutes, in the background), `gofmt -l`, `go vet
./internal/viewer`. No race detector, no mutation checks, one go command at a time.

## One timing on the real catalogue (allowed, strictly bounded)
After part 3, once: a throwaway Go test or program **kept out of the commit** that opens
`C:\Users\trabi\AppData\Local\Packages\Claude_pzs8sxrjxfjjc\LocalCache\Local\tgarchive-b\old-archive\catalog.sqlite`
read-only, builds the index, and prints **only counts and milliseconds**: the listing's build time and its
number of entries for `first=1`, `first=1&sameprob=0`, `only=1`, `deleted=1`, and the size of the largest
group met. Never print a title, text, name, path, id or link; never start the viewer's server on it; never
touch the library or any media file. If a listing takes over 150 ms, say so in the hand-back with where the
time goes (do not redesign by yourself).

## Rules
- Never open the viewer on real data or any real file; nothing against Telegram; do not touch
  `repo-archiver`, any other `wt-*` folder, or `internal/server`, `internal/catalog`, `internal/bringin`.
- Do not merge into or push `claude/charming-feynman-vm2xia`.
- CSS: your rules in one block at the end of `web/app.css`. Another coder is finishing a thumbnail piece on
  `wip/b-thumbs` that touches `web/js/dom.js`, `item.js` and a few lines of `library.js`: before your last
  whole-package run, `git fetch private wip/b-viewer` and merge `private/wip/b-viewer` if it has moved past
  4f1992e (keep both sides in a conflict).
- Concurrent code: say in the hand-back exactly which lines run in the index update (`refresh.go`).

## Hand back (short)
Commits, what each part does where it differs from this brief and why, the named tests, the whole-package
time and result, the real catalogue's counts and milliseconds, your doubts.
