# Brief F11a: the Chats page and a Mirrors place, rebuilt (UI track, session U-1, 11-22)

You are an Opus coder for the UI track of a private Go project (a Telegram archiver for Windows; a WebView2 window over the
collector's pages, `internal/server`, and the viewer, `internal/viewer`; one shared frame, `internal/appshell`). Work ONLY in
your copy `C:\Users\trabi\Claude\Projects\Telegram\wt-ui-f11a` (branch `wip/ui-chats`, cut from `wip/ui-all` 3192de6f).
Commit with `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, each message ending with
`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; push only `git push private wip/ui-chats`.

## Rules (binding)
The "Rules" section of `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-F1-one-frame.md` binds you word for word (invented data
only; the owner's real window is open: never a screen screenshot, never computer-use, pictures only of your own try window
with `runs-ui-1\shot.ps1`; Go through `ix-tools/env-archiver.sh`, one command at a time, named tests only; nothing against
Telegram; TEMP/TMP outside the project folder in try runs). Your try ports: 18836-18839. Every action keeps its route, guard
and its "what a click leads to" words before the click (the door's contract: one click is one request). Go handlers are
pages' (ask U-1). Other coders on the same base: F9 (`wt-ui-f9`: title bar, Quit dialog, pill, scrollbar, day headers,
"Mirrors" in the list, and the removal of mirrorwords.js's forum branch) and F10 (`wt-ui-f10`: one control set in
`internal/appshell/assets` and Settings rebuilt). Do not touch Settings or the frame; USE F10's controls: merge
`private/wip/ui-controls` as soon as it is pushed with its control set (check `git log` for its controls commit; ask U-1 if
unsure), until then build the layout and wire the controls in last.

## The owner's words, 11-22, on the live Chats page
"Is this UI being fixed?" The page today: a very wide table (numbers, toggles, Photos/Videos/Files, Rank) that scrolls
sideways; the mirror's details crammed into the last column with every line cut off ("Messages on record 268, of them 201
with a…", "The settle: a batch of 44 messages…", "Your word for this block…"); buttons cut ("See the settle and its ch…",
"Neve…"); a blocked state as a red pill cut mid-sentence. Earlier: "Date joined is missing?" and "how do I get to the
mirrors?". Also `reports-qa/QA-6aa225fb.md` finding 14 (duplicate chats of two accounts look the same).

## The goal
1. **Chats as a clean list, never sideways:** one row per chat at any window width from 900 px: avatar, name, the account's
   initials badge when there is more than one account, the state in a few words (collecting, mirrored, not added, waiting,
   blocked), and at most two compact numbers (saved / wanted). Above: search, filters as chips (kind, account, read state,
   mirror state, ranked), "Sort by" including **Date joined** (newest first; field `joined` from pages' MD,
   `wip/pages-mirrordoors`, merge it when listed; until then the option is hidden). Rank stays (drag or ▲▼ in the panel).
2. **A chat's panel:** a click opens a side sheet (F10's) at full height, about 420-480 px wide, every sentence whole:
   - Collecting: the collect switch, Photos / Videos / Files toggles, rank, topics (forums), "Ask how large" with its words;
   - Mirror: its state in one plain sentence (made, under way, blocked: why, in full), its numbers as a short list, and the
     owner's choices as full-width buttons with their words above them ("Mirror this chat", the settle's words, "Never");
     a blocked mirror's reason and choices readable, never a cut pill;
   - the chat's other facts (kind, accounts, joined, read state) at the foot; "Open the chat" to its conversation.
   A forum gets the same controls as any chat (the page's own forum refusal is removed by F9: do not reintroduce it).
3. **A Mirrors place** over `GET /api/mirrors` (per account: chat, mirror_chat, state, by, forwarded, left, last_at, why,
   choice/word, never, stopped, protected, offers; `?counts=1`; MD adds titles, made_at, topics): groups Blocked (first),
   Under way, Made, Stopped/Ended; each row source → mirror with its state, a click opens the same sheet's Mirror part. The
   list's "Mirrors" entry (F9 adds it, pointing at the Chats filter) opens this place instead: lend the one line in appshell
   if F9's entry is not on your base yet, and tell U-1.
4. The Chats page's empty states (no chats yet, nothing matches) say what to do next.

## Done means
- Named tests: no horizontal overflow at 900, 1280 and 1600 px (headless Edge measures scrollWidth); the panel's sections and
  every action still posting to its route with its words; the blocked mirror's full sentence; Date joined sort (when the field
  exists); the Mirrors place's groups; duplicates' account badge; gofmt, vet.
- Pictures of the WHOLE app (your real try window, invented data with 2 accounts, 40 chats, a forum, mirrors in every state
  including blocked): Chats at 1280 px; a chat's panel with a blocked mirror; a forum's panel; Mirrors place; Chats at 900 px.
  In `runs-ui-1/f11a-pictures/`. Compare with the agreed picture; say what differs.
- Report: the branch head, files touched, tests with times, the pictures, what is not done (under 30 lines). Close your programs.
