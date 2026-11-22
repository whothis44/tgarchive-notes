# Brief K30: a message's reactions and a service message's action, recorded for the viewer (Core, K-6, 2026-11-22)

**Why (listed, FEATURES 12, sixteenth round; the viewer's B5 ask):** the chat page shows "replies, edits and reactions",
but a message's reactions and what a service message says (joined, left, pinned, renamed, photo changed, ...) live only
inside `message.message_raw`, which the viewer cannot decode (it has no Telegram code: its import wall). So the chat page
draws a service message as a quiet line without its action and shows no reactions. Record both in the catalogue as rows
or columns the viewer can read, at save and on the live monitor's updates, and once for what is already stored.

**Rules:** you are the one Opus coder. **No request to Telegram:** everything comes from what the reader and the live
monitor already receive, and from the stored `message_raw`. Named tests and small packages only; never the whole
`internal/collector` or `internal/catalog`; every go command through
`bash /c/Users/trabi/Claude/Projects/Telegram/runs-core-k5/go2.sh <folder> ...`. Invented data only; never touch a running
program, the main copy, `C:\Users\trabi\tgarchive-app` or `E:\`. Copy `wt-core-react`, branch `wip/core-react` from
`private/claude/charming-feynman-vm2xia` (the newest). A schema step: on the branch after the newest step on your tree,
**safe to run twice** (guarded `ADD COLUMN`, `IF NOT EXISTS`); the whole catalogue's `-run 'Schema|Step'` before handing
back. Commit form as always; push only your branch. Then also run `bash /c/Users/trabi/Claude/Projects/Telegram/runs-core-k6/trialbuild.sh core-react`.

## What to build
1. **Reactions:** per message, the reactions as Telegram gives them (each emoji or custom-emoji id with its count,
   and whether the account itself chose it). Never who reacted (no user ids stored for reactions). A table keyed by
   message (e.g. `message_reaction(message_id, kind, value, count, mine)`), replaced as a whole when an update brings
   new counts (`updateMessageReactions` on the live monitor; an edited message's reactions at save).
2. **Service actions:** a service message's action as a fixed kind word plus the few plain facts the viewer needs to
   draw a line (e.g. a new title, a pinned message's id, the number of users added), never a name that is not already in
   the catalogue's name tables: columns on `message` or a small table. Cover at least join, leave, add users, remove
   user, pin, title change, photo change or removal, chat created, migrated to or from a supergroup, topic created or
   edited, call started or ended; anything else is kind `other`.
3. **At save and on updates:** in `internal/tgstore` where messages are saved and where the live monitor's updates are
   stored, in the same transaction as the message.
4. **Once for what is stored:** a settle that walks `message` in chunks (keyed, a few hundred rows a transaction, never
   holding the writer for seconds) decoding `message_raw` for messages saved before this step, with a resumable cursor
   and a count. It runs at the collector's start in the background, after the start's own work, and never on the
   brought-in old account's messages if their raw form differs (say what you find).
5. **Doors for the viewer, on a read-only handle:** `MessageReactions(ctx, messageIDs []int64)` and the service action
   as part of the message rows the viewer reads (name them). An older catalogue answers empty, never an error.

## Tests (each seen failing first)
Reactions saved at save, replaced by an update, never storing a reactor; each service kind decoded from an invented
raw message; the settle fills old rows in chunks, resumes after a stop, counts, and leaves nothing half-done; the doors on
a read-only handle and an older file; the step twice. gofmt, build, vet; the viewer's `TestWall`.

## Hand back
`archiver/docs/progress/core-react-REPORT.md` and your last message, short: head pushed; the schema step; the tables or
columns and the doors' exact names (for the viewer); the settle's speed on 200,000 invented messages; the tests as run;
the trial build's result.
