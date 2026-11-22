# Brief A2: send a file the archive already holds, from Telegram's own copy (no upload)

For one Opus 5.5 coder at high effort. The client track (session A-1), 2026-11-21. The owner agreed to it on
11-21 ("Yes, all eight"): `C:\Users\trabi\Claude\Projects\Telegram\DESIGN-CLIENT-acting.md` sections 3, 4.3, 5
and 6 point 2. Read that design in full first.

**IN PARALLEL WITH PIECE 1 (the owner, 11-21: "Start piece 2 in parallel on its own branch").** Your copy is
`C:\Users\trabi\Claude\Projects\Telegram\wt-client-afile`, branch `wip/client-afile`, cut from the main head
6aa225fb (newer than piece 1's base af4ca40e; the mirror's M6 and M13 came in between, with their schema
steps). Piece 1 (`BRIEF-A1-chat-actions.md`, branch `wip/client-chat`) is being built at the same time by
another coder, in the same files. So:

- **The shared frame comes from piece 1.** Its coder pushes one commit to `wip/client-chat` whose message
  starts "Client frame:". It holds:
  - the kind constants ActLook, ActJoin, ActLeave, ActMute, ActSendFile, ActUpload, with their words;
  - their `KindStats` fields and `notCounted` lines;
  - the `c_act` rebuild that allows the word `sendfile` and a caption in `text` for it;
  - the lists of kind words.
- **Until that commit is on `private`:** read, design, and write your code in files of your own
  (`act_file.go`, `click_file.go`, the settle's part in a file of its own, `schema_actfile.go`, their tests).
  Do not edit piece 1's kind list, constants or `c_act` yourself.
- **Once it is there:** `git fetch private wip/client-chat`. Find the commit with
  `git log private/wip/client-chat --grep "^Client frame:"`, and `git merge` exactly that commit into your
  branch (never a later one of piece 1's). Then build on it. Check every few minutes of work, not in a tight
  loop. If after about 90 minutes of your work it is still not there, stop and hand back what you have,
  saying so.
- **Your own schema step:** one new table keyed by the click's row (`c_act`'s id) for the source chat, message
  and media, in `schema_actfile.go`. No column on `c_act`. On your branch it is the step after piece 1's step
  (the number in two constants). The integrator sets both numbers at the merge, piece 1 first.
- **Keep your lines in piece 1's files few,** and list each in the report (file, function, why): they are
  where the two branches meet at the merge. Every house rule of A1's section 0 holds here word for word: copies,
commits, privacy, named tests only, the lent commits, no page and no HTML. **Nothing runs against Telegram.**

## 1. What exists

- Read the K8 report (`archiver/docs/progress/core-act-REPORT.md`) in full, and piece 1's brief (to know
  what the other coder is changing). The A1 report does not exist yet.
- The refresher (`internal/telegram/refresh.go`: `Refresh`, `ask`, `locate`, `learn`) already asks Telegram
  for messages by id, one request per chat and chunk, and finds a file's current location in the answer
  (`locate`, `MediaID`). The record says a stored file reference is never usable later, so it is refreshed
  just before use (`TRIED-BEFORE` 25). Reuse `ask` and `locate`; do not write a second message fetch.
- The forward kind (`ActForward`) and its protected-source rule (`ErrForwardsRestricted`, the Forwarder's
  record of protected sources).

## 2. What to build

1. **A new kind, `sendfile`:** "send this archived message's file to chat X, with an optional caption".
   - Its input:
     - the source chat and message, and which of its media (as the catalogue names a file);
     - the destination chat and topic;
     - a reply target;
     - the caption, as plain text with the text step's limits, kept in the row only until the outcome is
       known, like a send's text;
     - a random id made once per click.
2. **Two requests in one click, in this order:**
   - **First, one read of the source message** through the refresher's `ask`: `messages.getMessages`, or
     `channels.getMessages` in a channel. It is a read, so it may be asked again after a stated wait (slept
     in full), as the refresher does.
   - **Then one `messages.sendMedia`.** It names the found `InputDocument` or `InputPhoto`, with its fresh
     file reference, plus the random id and the caption. It carries no flags beyond the reply header and the
     topic, as a send does, checked bit for bit.
   - **The `sendMedia` is under every R1 to R12 rule:** written down first, never repeated by the program,
     a wait reported and not slept, a lost answer "not known".
   - A `FILE_REFERENCE_*` answer on the `sendMedia` is a refusal, shown. It is never refreshed and sent
     again by itself. The owner's "send again" starts a new read and a new send under the same random id.
3. **Local "no"s, with no request:**
   - a source in a chat known to be protected;
   - a source in one of the app's own mirror chats (fine) to a destination that is a mirror (refused, as
     the text step does);
   - a file the catalogue does not hold;
   - a frozen account, the account's refusal, the caps.
4. **The source is gone** (the read finds the message deleted or the media changed): the click ends
   "source gone", with no send. The answer says so, so that a page can offer the upload of piece 3 with its
   cost. The catalogue's own deleted mark for that message is written as the reader would write it.
5. **The settle of a "not known" `sendfile`:** the account's own new message in the destination after the
   request, naming the same Telegram file (the same document or photo id: an exact match) and the same
   caption. Extend the settle (`internal/catalog/act_settle.go`) for this kind, by its rules: "arrived" by
   itself only when the match is exact and alone.
6. **The ledger:** the kind word comes from piece 1's frame. The source columns go in your own table (see
   the start of this brief).
7. **The door:** the queue takes the kind with its fields, in pages' one lent commit. The fake Telegram
   answers `getMessages` and `sendMedia` with a document and a photo, a refused reference, a stated wait and
   no answer.

## 3. Tests (each seen failing first, by `-overlay`, as A1)

- R1 to R12 for `sendfile`, and the two requests' order: never a `sendMedia` before the read has answered.
- The fresh reference is the one sent.
- "Source gone".
- A protected source.
- A refused reference not sent again.
- The settle's exact match.
- The flags bit for bit.
- The privacy test: no caption, title, name or id in a log.
- An end-to-end test at the collector's fake Telegram through the door: exactly 2 requests.

## 4. Hand back

- `archiver/docs/progress/client-afile-REPORT.md`, laid out as A1's report.
- The branch pushed.
- The two lent commits apart.
- The copy left clean.
- Stop and hand back at anything that would need a real request, a change in the viewer or the window, or a
  decision the design does not make.
