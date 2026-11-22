# Brief G1v: chats grouped under suggested names, the data and the doors (viewer session B9, 11-22)

You are an Opus coder for the viewer track of a private Go project (a Telegram archiver). Work ONLY in the copy
`C:\Users\trabi\Claude\Projects\Telegram\wt-b-chatgroups` (branch `wip/b-chatgroups`, from main f0323f5b). The Go
module is in `archiver/`. Commit as you go with `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`,
each message ending with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; push `git push private
wip/b-chatgroups` (never another branch, never main, no tag, no merge into another branch).

## Rules
- Invented data only; never open the owner's folders or catalogue. Print counts and timings only.
- Every go command through the lock, one at a time, with ABSOLUTE paths for any output:
  `bash /c/Users/trabi/Claude/Projects/Telegram/runs-b7/shell/scripts/gorun.sh <dir> go test ./internal/x -run 'Name' -count=1`.
  Named tests only; never the whole internal/catalog or internal/collector; no race detector.
- Touch only: a NEW file in `internal/catalog` (`chatgroup.go`, its schema step in `schema_chatgroup.go`, tests), the
  step's two entries in `catalog.go`'s step table and migrate switch (as other tracks' steps do), `internal/viewer`
  Go (not `web`), and one row in `archiver/docs/FEATURES.md`. Nothing in `internal/server`, `appshell`, `web`.

## Read first
`C:\Users\trabi\Claude\Projects\Telegram\DESIGN-B9-groups-clutter.md` section 3 (the rule, the table, the doors);
how another track's recent step is added (`schema_broughtin.go`, `schema_alertaway.go` or the newest `schema_*.go`:
the "after" constant, `SchemaVersion`, the migrate case); how the change log records a row change (grep `change_log`);
the viewer's `/api/chats` answer (`internal/viewer`, grep `handleChats`).

## Build
1. **The rule** (`chatgroup.go`, a pure function with table tests): `GroupKey(title string) (key, stem string)` as the
   design says (trim spaces and emoji, fold case, remove ONE trailing marker: separator + number, roman numeral i..xx,
   part/backup/mirror/archive/old/new/vol (+ number), or a bracketed number). At least 25 table cases, including
   non-Latin titles, a title that is only a number, "Season 2 Episode 3" (only the last marker goes), and titles that
   must NOT group ("2024", "Top 10").
2. **The table** (one schema step after the newest on main, numbered as the board says at the merge):
   `chat_group_word(chat_id INTEGER PRIMARY KEY REFERENCES chat(id) ON DELETE CASCADE, group_name TEXT, alone INTEGER
   NOT NULL DEFAULT 0, at INTEGER NOT NULL)`; each write logged in the change log so open viewers redraw (use the kind
   the chat table's changes use, or say which).
3. **The doors** on `*catalog.Catalog`: `ChatGroups(ctx) ([]ChatGroup, error)` (read-only, works on a read-only handle
   and returns the rule alone on an older catalogue without the table): each group with its name, member chat ids,
   and whether it is suggested or the owner's; a chat in a mirror pair goes with its source (the mirror's row names
   it); `SetChatGroup(ctx, chatID int64, name string) error`, `SetChatAlone(ctx, chatID int64, alone bool) error`,
   `ClearChatGroup(ctx, chatID int64) error` (one statement each; a name trimmed, 1..100 characters, else an error of
   a fixed sentence). Measure `ChatGroups` on an invented catalogue of 5,000 chats (ms).
4. **The viewer's data:** each chat in `/api/chats` carries `group` (the group's name) and `group_by` ("rule" or
   "owner") when it belongs to one; omitted otherwise; read through the viewer's read-only handle once per index
   version (not per request).
5. **FEATURES.md:** one row in its table of features (find the section on the viewer or the list): "Chats grouped
   under suggested names, with the owner's rename, join and split" with owner tracks "viewer (data) and UI (look)".

## Hand back (short; numbers only)
Commits pushed (hash, subject); the rule's cases; the step's constants; the doors' signatures; the cost measured;
tests by name with seconds; anything in the design that the code says is wrong.
