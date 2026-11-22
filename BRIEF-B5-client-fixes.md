# Brief B5-C2: the fix round for `wip/b-client` after its independent look (viewer session B5, 11-15)

Same coder, same copy (`wt-b-viewer`), same branch (`wip/b-client`, on top of 077742a4), all earlier rules
(`BRIEF-B5-client-reading.md`: privacy, load, named tests, commits; the viewer sends nothing). The review is
`C:\Users\trabi\Claude\Projects\Telegram\wt-b5-review-C-scratch\REVIEW.md`: read it in full first; its probes
and its page model are beside it (read-only: take each probe as a test of your own that fails before your
fix, and keep the page model as a test: a model that takes answers exactly as the page does and is compared
with a first load after every random step). It found `refresh.go` unchanged in what it reads and builds,
the record bounded and immutable per step, no leak between chats. The main session's decisions:

- **F1 (confirmed; a silent hole): a new post inside the shown range.** The collector catches a chat up
  newest page first, so the second page of new messages lands between posts already shown; today it comes
  back only as "changed", the page has no element for it and drops it for good. Fix on both sides: the
  answer says which of its posts are new since `since` (the record knows: positions are append-only
  between full reads); the page inserts a post it does not show at its place by cursor (date, then
  number), with its day line, without moving the reader, and counts it in the "new messages" pill when it
  is below the screen. The reviewer's probe and the page model with a newest-first catch-up of three
  pages as tests; and seen in the headless browser with a writer that stores pages newest first.
- **F2 (confirmed): more than 100 new posts in one step.** The rest must come at once, not at the next
  step: when `more` is set the answer's `live` is the asker's own `since` (changed posts may then come a
  second time: say so in the contract) or the page keeps its token; choose one, test with 250 new posts
  and an idle collector afterwards.
- **F3 (confirmed; what a reader sees most): a file saved after its message.** When a file's state changes
  in an update, the posts that show it go into a live-only list merged into the record (never into the
  update's own dirty set: nothing the update builds may change; say how you bound it: by the files
  changed per update). A live post drawn "not downloaded" then becomes its picture by itself. Test with
  the real writer's order (message first, file saved later).
- **F4: a reset keeps the reader's place** (the place's post among the newest 30: reload the newest end;
  else load around it; a playing video in the page is the reader's place too: do not reload under it
  unless the answer leaves no choice, and say what happens then). Two resets in a row make the page wait
  30 s before its next ask (a bring-in while the viewer runs must not reload every 3 s). Resets are
  counted in the counts file (a number). Leave the record one for all chats, but when it is trimmed or a
  step is over the cap, keep one entry per chat for what was dropped ("this chat changed: reload its
  window") if that fits the cap; if it does not fit simply, say why and leave it.
- **F5:** "changed" is capped at 200 posts an answer (past it: the reset that keeps the place); the page
  does not redraw a post whose answer equals what it drew (so another account's sightings do not stop a
  video or close a versions panel), and a redraw keeps an open versions panel.
- **F6 (mine and theirs, honestly):** in a chat seen through shared message numbers (a group or channel
  more than one account can see), the stored `outgoing` is whoever stored the row first: ignore it there.
  A message is an account's when its sender is that account's Telegram user id (the index has it); then
  it is drawn on the other side and, with more than one account in the archive, says whose. Per-account
  chats keep `outgoing`. No "Sent by one of the accounts" anywhere: a side is drawn only when it is known.
- **F7 (names, not numbers):** the catalogue has the names (`tg_peer_name`, schema step 9: an account's
  view of a user's or a chat's name; the old archive's bring-in fills it; nothing fills it for new
  accounts yet, which is another track's). The viewer reads it: a sender shown anywhere (a message's
  head, a reply's quote, the Chats list's line) is its name when a row exists for its id (any account's
  row, the newest), else the number as today; read by key for the ids of one answer in one bounded
  query, kept per step; never in a log or the counts file. A catalogue older than step 9 has no table:
  numbers as today. The head says "You" for the account's own message exactly where the list does (after
  F6's rule). Check where the reader writes `sender` (`internal/telegram/record.go`) for what the id's
  form is for a user, a channel's own post and an anonymous admin, and test each.
  - `cmd/tgarchive/fabricate.go` writes names as senders and no outgoing, edit or service marks, so pages
    seen on it look unlike real rows. Add one flag, off by default (`-real-rows`): senders as marked ids
    with `tg_peer_name` rows, some messages outgoing, edited (with a version row) and service. Nothing
    else in that file changes; use it for this round's browser check.
- **F8:** drop the unused field that keeps an old index alive.
- **F9:** a page with no posts (a media-only or topic page showing nothing) takes its new posts from the
  record's entries for the chat, not from a walk of the chat; time it at the real size beside the others.
- **F10:** when the catalogue cannot name edits and deletions live (no change log, or older than step 7),
  the chat page says so in one quiet line ("Edits and deletions show after a reload: this archive was
  made by an older version").
- **The tests the review says would pass with a defect present:** `TestLiveEachChangeOnce` gains the
  out-of-order and the over-100 cases and a file saved later; `TestClientMarks` stores an outgoing
  message through another account first; `TestTimingLiveAsk` times 200 changed posts, a page with no
  posts and a list of many chats, and is skipped in a whole-package run unless asked for (an environment
  variable, as this package's other at-size tests do; check how they do it).

## At the end, once
`gofmt -l`; `go vet ./internal/viewer ./cmd/...`; your named tests, the reviewer's probes and model as
tests, the refresher's random, merge and reference tests by name; `CGO_ENABLED=0 go build ./...`; the pages
once in the headless browser on a `-real-rows` invented archive with the newest-first writer (what you saw:
a hole or none, names, sides, a file arriving, a reset with the place kept). Hand back: the commits (pushed)
and the head; what was done for each of F1 to F10 and any difference with its reason; the live route's
contract again where it changed; what you ran and what it printed; what you did not test; doubts.
Commit-ready, nothing left running, the copy clean.
