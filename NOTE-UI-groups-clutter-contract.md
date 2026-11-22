# Chat groups and clutter: the viewer's data for the UI (B9, 11-22; branches wip/b-chatgroups, wip/b-clutter, with coders)

**Groups (priority 3; stored in the CATALOGUE, one schema step of the viewer track; final per B9):** GET /api/chatgroups → {groups: [{id, name, suggested, why, owner, chats: [ids], members: [{chat, by:
"owner"|"rule"}]}], ungrouped: [ids], gen}; each chat in /api/chats carries `group` and `group_by`. Writes are catalogue doors
called by the PAGES' server (the viewer is read-only): SetChatGroup(ctx, chatID, name), SetChatAlone(ctx, chatID, alone),
ClearChatGroup(ctx, chatID), DismissSuggestedGroup(ctx, chatIDs) (one transaction). The UI lends the pages' write routes (P7 reads).

**Clutter (priority 4; the owner: "shown, never applied"):** the score never hides anything. Per media on tiles and posts:
`clutter_score`, `clutter_suggested` (score >= pref `clutter_threshold`, default 70, and not "not clutter"), `clutter_why` (fixed
words): all absent with no score. Pref `clutter_suggest` (default OFF: nothing suggested). Filter `?clutter=suggested`. POST
/api/not-clutter {media, not}, GET /api/not-clutter (the viewer's decisions file, undoable). List count `lib:clutter`. Hiding stays
the existing /api/hide (kind chat|post).
