# Chat groups and clutter: the viewer's side (session B9, 11-22; the owner's priorities 3 and 4 via I-7)

## 3. Chats grouped under suggested names
**What exists:** nothing. The old app (wt-v12.32) grouped its sidebar by chat TYPE only (channels, groups); it had no
rule for names like "Basketball -1", "Basketball -2" (read: `webassets/public/js/app.js` sections,
`internal/app/ix_browse.go` families are of posts, not chats). So the rule is new, and small.

**The rule (suggestion, never a change):** a chat's group key is its title with, in order: surrounding spaces and
emoji trimmed; case folded; ONE trailing marker removed: a separator (space, `-`, `–`, `—`, `_`, `#`, `|`, `.`) followed
by a number, a roman numeral (i to xx), or the words part/backup/mirror/archive/old/new/vol + optional number, or a
number in brackets `(2)` `[2]`. Chats whose keys are equal and non-empty form a SUGGESTED group when there are at least
two; its name is the shared stem as the first chat spelt it. Mirrors the app made are grouped with their source
(the mirror's row already names it), not by name.

**The owner's overrides, stored in the catalogue** (one schema step of the viewer's, claimed on the board; one table):
`chat_group_word(chat_id PK -> chat(id) ON DELETE CASCADE, group_name TEXT NULL, alone INTEGER, at)`:
- rename a group: every member's row gets the name;
- join a chat into a group (also one the rule did not suggest): its row gets that group's name;
- split a chat out: `alone = 1` (it stays out of any suggestion);
- undo: delete the chat's row (the rule applies again).
Written in one statement per click, logged in the change log so both servers redraw.

**Doors (`internal/catalog`, the viewer track's new file):** `ChatGroups(ctx) ([]ChatGroup, error)` read-only (the
rule plus the overrides: group name, member chat ids, whether suggested or the owner's), cheap (the chat table, about
5,000 rows: one walk, measured); `SetChatGroup(ctx, chatID, name)`, `SetChatAlone(ctx, chatID, alone bool)`,
`ClearChatGroup(ctx, chatID)` (writes: called by the collector's pages, never by the viewer, which opens read-only).

**Who does what:** viewer track (B9): the rule, the table, the doors, tests; the viewer's `/api/chats` and the list's
Counts carry the group per chat as data. UI track (U-1): appshell's Chats group drawn as groups (collapsible, the
owner's rename/join/split buttons), and the write route on the pages' server (`internal/server`, a lent commit P7 reads)
calling the doors.

## 4. Clutter
**What exists (viewer-only, kept and undoable, the viewer's own decisions file, nothing deleted, skipped or sent):**
hide a chat, hide a post, a chat's clutter choice (show all / hide clutter) over a library switch, and four rule-based
kinds of clutter (small pictures, short videos, stickers, "many").

**What is added:** a fifth kind, "the detector says clutter", read from copies' score. **The seam to agree with copies
(C7):** copies writes one row per Telegram media it scored in a table of its own, e.g.
`c_clutter_score(tg_media_id PK, score INTEGER 0..100, version INTEGER, at)`, each write logged in the change log
(so the viewer updates in place, as it does for edges); the viewer reads it with its index (one column per media, in
memory) and counts a media as detector-clutter when `score >= threshold`, a setting of the viewer's (default 70) beside
the other kinds, on or off. A media with no row is not clutter by this kind. Hiding stays the viewer's only.
