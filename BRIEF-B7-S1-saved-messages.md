# Brief B7-S1: the viewer knows the account's own chat and calls it "Saved Messages"

Written by the viewer session B7, 11-16. One Opus coder, high effort. A small piece of `internal/viewer` only.
Hand back commit-ready work on the branch; merge nothing; push only this branch.

**The project's first rule (the owner): no routine sequence call by call for its own sake. While working run
only named tests of what you changed; never the whole `internal/viewer` (about 7 minutes), never the race
detector.**

## 1. Why
The owner signed in to a test account in the new app on 11-16, was sent to "Saved Messages" and asked:
"where is saved messages in chats? I don't see." A look on an invented catalogue
(`REPORT-B7-viewer-151.md` in the project folder, section "151 a": read it first) found: the viewer lists
the account's own chat, when the catalogue has a row for it, as an ordinary person's chat under the
account's OWN NAME (that is what Telegram's chat list gives the collector); the words "Saved Messages" stand
nowhere in the viewer, and nothing in it knows that chat. The owner's chosen design for the app
(`DESIGN-ONE-WINDOW.md`) has "Saved Messages" as the second entry of the list on the left, which will link
to an address of the viewer.

## 2. What the old app already knows
The old app (the fork) shows Telegram's own name for it through its Telegram library and has no separate
viewer rule: nothing to port. What this viewer already has, and you use: the index holds, per chat,
`shared`, `owner` (the account of a per-account space) and `tgChatID`, and per account `tgUser`
(`internal/viewer/index.go` near lines 170 to 196; read from the catalogue in `refresh.go` near 508 and
528). **The account's own chat is: a chat of kind `user` in a space that is NOT shared, whose `tgChatID`
equals its owner account's `tgUser` (and that id is not 0).** No schema change, no new read.

## 3. Where
- A NEW copy and branch, made by you as your first step, from the newest main head (fetch first):
  `git -C /c/Users/trabi/Claude/Projects/Telegram/wt-b-faces fetch private` then
  `git -C /c/Users/trabi/Claude/Projects/Telegram/wt-b-faces worktree add /c/Users/trabi/Claude/Projects/Telegram/wt-b-saved -b wip/b-saved private/claude/charming-feynman-vm2xia`.
  Do not change anything in `wt-b-faces` itself, and never touch the folder `repo-archiver`.
  Say the head you cut from in your hand-back. Push as you go: `git push private wip/b-saved` (never the
  main branch, never `origin`).
- Commits: `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, ending with
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- You may edit ONLY `archiver/internal/viewer` (Go, `web/`, its tests). Nothing else.

## 4. What to build
1. **The index knows it:** each chat record gets one boolean (say `self`), set by the rule of section 2 when
   the chats are read (full read and incremental update alike: the package's strong comparison between the
   two must still pass; if the rule needs the accounts read first, they already are).
2. **Its shown name is "Saved Messages"** wherever the viewer shows a chat's title to the person: the Chats
   list, a chat's page head, the library's chat filter and its chips, the "also in N chats" lists, the
   Changes and Overlap pages, a post's page, search results. With more than one account in the catalogue:
   "Saved Messages (LABEL)", LABEL being that account's label. Do it in ONE place (a function for a chat's
   shown title that everything already goes through, or that you make them go through), not page by page.
   **The chat's stable key for the owner's marks (`marks.go`) and every stored thing keyed by a chat must
   not change:** only the shown title does. The chat's real title stays reachable in the JSON (a second
   field) so the page can show "Saved Messages" with the account's name as a quiet second line.
3. **First in the Chats list:** in `/api/chats` (and in the chat lists of `/api/meta` that pages draw from)
   the accounts' own chats come first, in account order, then the rest by newest activity as today. Hidden
   chats keep their rule (a hidden Saved Messages is hidden; `hidden=0` leaves it out as any other).
   The JSON says `"self": true` for it, and the page marks it (a small bookmark icon in the row is enough;
   no new colours, the page's existing look).
4. **An address of its own: `/saved`** (and `/saved?account=ID` when there are several accounts; with none
   named, the first account by id). It is a route of the same one page (see `server.go` near lines 74 to 99
   and the router in `web/js/main.js`): it shows that chat exactly as `/chat/ID` does (the same module, the
   address bar may stay `/saved`), so a link from another program needs no chat id. The tab "Chats" is the
   one marked current.
   - When the catalogue has no row for the account's own chat, or the row has no message: the page says, in
     fixed plain words, what is the case and what to do next. Two different sentences: (a) no row: "Saved
     Messages is not in this archive yet. It appears once the app has read this account's chat list." (b) a
     row with no messages: "Saved Messages has not been read yet. It is read like any other chat: choose it
     for collecting in the app." No error text, no blank area.
   - `/api/meta` (or the smallest existing answer the router already has at load) carries, per account, the
     own chat's id or 0, so the page needs no extra request to resolve `/saved`.
5. **The old archive** (a catalogue filled by `internal/bringin`): the same rule applies with no change IF
   the bring-in writes the account's `tg_user_id` and a per-account space for that chat. Read
   `internal/bringin` (do not change it) and say in your hand-back, with file and line, whether an old
   archive's Saved Messages will be recognised by this rule, and if not, what is missing.

## 5. Not in this piece
Reading Saved Messages by itself (the collector's, another track); any change to the catalogue, the
fabricate command or the bring-in; the app's list on the left; any restyle.

## 6. Tests (by name; make the rows with the package's own test helpers: the fabricate command cannot make
this chat)
- the rule: own chat recognised; a person's chat with another id not; a shared space not; `tgUser` 0 not;
  two accounts, each with its own;
- the full read and the incremental update agree (the package's random and strong-comparison tests by name:
  `TestRandomUpdatesMatchFullRead`, `TestChangeLogEachChangeFollowed`, `TestIncremental`);
- the shown title in each JSON answer that carries a chat title (name the answers you covered); the marks'
  stable key unchanged (the marks' tests by name);
- `/api/chats` order and the `self` flag, hidden rule included;
- `/saved`: the route serves the page; the meta answer names the own chat's id; the two empty cases' fields;
- the wall test `TestWall` and the page-asset tests by name (the embedded files changed).
`gofmt -l`, `go vet ./internal/viewer` once at the end.
**Each go command: one at a time on this PC, through the track's lock:** take it with
`until mkdir /c/Users/trabi/Claude/Projects/Telegram/runs-b7/golock 2>/dev/null; do sleep 20; done`, release
it with `rmdir` of the same folder right after the command (also when it fails); before the command, free
memory must be at least 2.5 GB
(`powershell -NoProfile -Command "[math]::Round((Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB,1)"`;
if less, release the lock, wait 2 minutes, try again, at most 5 times, then stop and say so).
`source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh` first; `GOMAXPROCS=2 GOFLAGS=-p=1`.

## 7. One look as a person would (no browser, no window: by the viewer's own answers)
Build `tgarchive.exe` once into `C:\Users\trabi\Claude\Projects\Telegram\runs-b7\saved`; copy the invented
catalogue `F.sqlite` and its library folder from `runs-b7\look151` (it already holds an own-chat row added by
hand; read the report's Part 1 for how it was made) into your scratch folder; start `tgarchive viewer` on the
copy on a 127.0.0.1 port above 20000 with EVERY folder flag inside your scratch folder, `LOCALAPPDATA`,
`APPDATA`, `TEMP` and `TMP` set to folders inside it BEFORE the start, output to a file (never a pipe from a
background program); ask `/api/chats`, `/api/meta`, `/saved` and the chat's own JSON with curl; put the
answers' relevant fields in your hand-back. Then the same on a copy of the empty catalogue `E.sqlite` (case
a). Stop your viewer by its PID; no process of yours left.

## 8. Hard rules (the owner's)
- Invented data only. Never open, list or read anything under `E:\`, any folder named `tgarchive-b` or
  `tgarchive-app`, the owner's app folder, any NAS path or any real catalogue. Do not search drives.
- Never stop, kill or signal a process you did not start.
- Text with a Windows path never goes through a shell string into a file: the Write or Edit tool.
- No new dependency; the viewer's import wall (no Telegram code) and its guards stay as they are.

## 9. Hand back
Push. Your final message, at most 35 lines: the head you cut from and your head; files and line counts; the
one place the shown title is made; every answer and page that shows a chat title and whether it is covered;
each named test and its result; the look's fields; the old archive's answer (section 4.5); doubts, most
important first; what you saw that is wrong but outside this brief.
