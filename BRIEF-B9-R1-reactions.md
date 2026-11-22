# Brief R1v: reactions and service actions in the chat page's data (viewer session B9, 11-22)

You are an Opus coder for the viewer track of a private Go project (a Telegram archiver). Work ONLY in
`C:\Users\trabi\Claude\Projects\Telegram\wt-b-react` (branch `wip/b-react`, from Core's K30 `wip/core-react` 36e362e0).
Module in `archiver/`. Commit with `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, messages ending
`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; push only `git push private wip/b-react`.

## Rules
- Invented data only; never open the owner's folders. Counts and timings only.
- Go only through the lock, ABSOLUTE output paths: `bash /c/Users/trabi/Claude/Projects/Telegram/runs-b7/shell/scripts/gorun.sh <dir> go test ./internal/viewer -run 'Name' -count=1`. Named tests only; no whole viewer; no race.
- Touch only `internal/viewer` Go (NOT `web`). Run `TestWall*` by name before handing back.

## What Core's K30 gives (read `internal/catalog` on this branch: grep MessageReactions, MessageActions, ActionWords)
On a read-only handle: `MessageReactions(ctx, ids []int64) (map[int64][]catalog.Reaction, error)` (per message: kind
emoji|custom|paid, value, count, mine; who reacted is never stored), `MessageActions(ctx, ids) (map[int64]catalog.ServiceAction,
error)` (a fixed word from `catalog.ActionWords`, plus title, number, peer as a marked id with names from the name tables, the
pinned message's ref), `FactsFillState(ctx)`. An older catalogue answers empty maps. Older messages are filled in the
background after the collector's next start: until then the fields are absent (NULL).

## Build
1. In the chat page's conversation answer (the viewer's chat posts JSON: grep `handleChatPosts`, the post/message JSON
   it returns) and the post page (`/api/post/{id}`): per message, `reactions: [{kind, value, count, mine}]` (omitted
   when none) and, for a service message, `action: {word, title?, num?, peer?: {id, name}, ref?}` (omitted otherwise;
   `peer.name` from the viewer's or the catalogue's names; never more than the doors give). Read with ONE call of each
   door per page of messages (the ids of that page), through the viewer's read-only handle (the one the clicks and the
   list use: `actCatalogue`); bounded; a door error leaves the fields out and is counted, never fails the page.
2. A service message must not be drawn as an ordinary text message with empty text: add `service: true` on it.
3. `/api/meta` gains `facts_filled` (from FactsFillState: done or not, counts only) so the page can say "reactions
   still being filled".
4. Tests by name (invented catalogue written through the catalogue's own write doors or rows as K30 writes them):
   reactions on a page's messages, a service action with each kind of field, an older catalogue (fields absent), a
   door error (fields absent, page answered), one door call per page (count calls with a seam or measure), TestWall*,
   TestLAN* (the fields on a device's page follow the same rules as the rest of the message), gofmt, vet viewer.

## Hand back (short; numbers only)
Head pushed; the exact JSON fields and when absent; tests with seconds; the cost per page of 50 messages (ms).
