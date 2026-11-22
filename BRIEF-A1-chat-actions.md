# Brief A1: the client's chat actions (join with a look first, leave, mute)

For one Opus 5.5 coder at high effort. The client track (session A-1), 2026-11-21. The owner agreed to the
design on 11-21: `C:\Users\trabi\Claude\Projects\Telegram\DESIGN-CLIENT-acting.md`, all eight choices as
recommended. Read it in full first. This piece is its section 6, point 1.

**NOTHING IN THIS PIECE RUNS AGAINST TELEGRAM.** Every test uses the package's fake invoker or the collector's
fake Telegram (`internal/collector/faketg`). No program is started against the real account. Never stop,
restart or reconfigure the owner's running app. No window on the owner's screen.

## 0. Where you work, and the rules of the house

- **Your copy:** `C:\Users\trabi\Claude\Projects\Telegram\wt-client-chat`, branch `wip/client-chat`, cut from
  the main head. The Go module is in `archiver/`. Use `ix-tools/env-archiver.sh` if a step needs the
  environment (read it first).
- **Commit work in progress to `wip/client-chat` as you go, and push it to `private`.** Never push anything
  else. Never merge into or push the main branch (`claude/charming-feynman-vm2xia`). Never tag. Commit with:
  `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`. Each message ends with
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- **Privacy, binding:** nothing of a chat's title, a username, an invite link or its hash, a name, a text, a
  path or a Telegram id in any log line, error text, status file or count. New log calls use constant format
  strings. Test data is invented.
- **Tests while working: named tests only** (`go test -count=1 -run 'TestX|TestY' ./internal/...`). No
  whole-package run of `internal/catalog` or `internal/collector`. No race detector. No `go vet` over many
  packages. No Docker. Measure free memory before a build (keep about 2 GB free). The full runs happen once,
  later, by the session, not by you.
- **Owners of the files you touch** (the board, `C:\Users\trabi\Claude\Projects\Telegram\BOARD.md`, Tracks):
  - `internal/telegram/act*.go`, `internal/catalog/schema_act*.go` and `act_settle*.go`, and
    `internal/collector/click*.go` are proposed to move to the client track (message 215). Edit them freely
    on your branch.
  - Any line elsewhere in `internal/telegram`, `internal/collector`, `internal/catalog` or `faketg` is Core's.
    Keep those lines few, and put them in ONE commit whose message starts "Lent to Core:".
  - Any line in `internal/server` (the door's routes, `clicks.go`) is pages'. Put those in ONE commit whose
    message starts "Lent to pages (server):".
  - Do not touch `internal/viewer`, `internal/window` or `internal/actdoor`.
- **The UI is going to be reworked (the owner, 11-21).** So this piece adds no page and no HTML. Everything a
  page needs comes through the door as fixed words and numbers, so that any later interface can sit on it
  unchanged.

## 1. What exists (read it before writing anything)

The text step is built and merged, and the owner sent one real message through it on 11-21 (it worked). Read:

- `archiver/docs/progress/core-act-REPORT.md` in full: the request layer, `Do`'s order of checks, `report`
  (the variant of `once` that never sleeps), the outcomes, the R1 to R12 rules and their tests.
- `internal/telegram/act.go` and `act_state.go`: kinds, `Action`, `ActOutcome`, `request`, the `SelfID` rule
  for Saved Messages.
- `internal/catalog/schema_act.go`, `schema_actkey.go`, `act_settle.go`: the ledger `c_act` (its `kind`
  column has a CHECK on six words), the key rows, the settle.
- `internal/collector/click.go`, `click_api.go`, `click_state.go`: `QueueClick`, the click's turn in the
  reader's loop, the state call, the cap settings (`ReadClickCap`).
- `internal/server/clicks.go`: the door's six routes and its words.
- The reviews in `archiver/docs/review/core-act-*.md` and `core-k14-door-2026-11-16.md`: what reviewers
  caught. Do not bring any of it back.

**What the old app already knows** (design section 2; read `wt-v12.31/core-service/internal/telegram/dialog_remove.go`
yourself; it is the code to port for leaving):
- It confirmed against the account's current chats before leaving.
- `channels.leaveChannel` for a channel or supergroup.
- `messages.deleteChatUser` (self, `revoke_history` false) then `messages.deleteHistory` (`revoke` false,
  `just_clear` false, `max_id` 0, repeated while the answer's offset is above 0) for a basic group.
- `messages.deleteHistory` alone for a private chat.
- Saved Messages refused.
- 2 minutes for the whole removal.
- 1.5 s between removals of a batch, and batches only of chats already unavailable.
- No wait or refusal from it is on record.
- Neither app has ever joined or muted.

## 2. What to build

### 2.1 Four new kinds in the request layer (`internal/telegram`, beside `act.go`)

`look`, `join`, `leave`, `mute`. They follow every rule of the text step's `Do`: R1 to R12, the same order of
checks, `Begin` before any request, the re-check after `Begin`, `End` exactly once, the frozen record, the
account's refusal (both ways), the waits reported and never slept, the counters per kind and hour.
**Each kind gets its own `KindStats` field** (`ActLook`, `ActJoin`, `ActLeave`, `ActMute`), and the
collector's `notCounted` gets its `repeat_waits` lines (the K8 report, section 6, says how).

1. **`look`: what a link names, before any join. A read, but a click like the others.**
   - The input is either a private invite's hash or a public username, as typed by the owner. Check its form
     locally first; a bad form is a local "no" with no request.
   - The request is `messages.checkChatInvite(hash)` or `contacts.resolveUsername(username)`: 1 request.
   - The outcome holds:
     - the chat's kind (channel, supergroup, group, user, bot);
     - its title and member count where Telegram gives them;
     - whether a join needs the admins' approval (`request_needed`);
     - whether the account is already in it (`chatInviteAlready`, or a resolved channel that is not `left`);
     - whether it is the account's own mirror (`IsMirror`) or protected.
   - Peers in the answer are stored with their access hash as the reader stores peers (`Reader.learn`,
     `peersOf`), so that the join can address the chat.
   - The title, the hash and the username live only in the click's row, like a text: cleared as soon as the
     owner is finished with the look, and at most 7 days. They never go in a log.
   - A user or a bot resolved by name is shown and cannot be joined: the look says "a person" or "a bot".
2. **`join`: names the look's click, never a link typed again.**
   - The door's queue takes the earlier look's number. The hash or username comes from that row, so what
     joins is exactly what the owner saw. A look older than 7 days, a look of another account, or a look
     already used for a join is a local "no".
   - The request is `messages.importChatInvite(hash)` or `channels.joinChannel` with the stored peer: 1
     request.
   - Outcomes, by Telegram's word:
     - done;
     - `INVITE_REQUEST_SENT`: its own outcome, "asked", done for the ledger;
     - `USER_ALREADY_PARTICIPANT`: done, "already in";
     - `INVITE_HASH_EXPIRED`, `INVITE_HASH_INVALID`, `CHANNELS_TOO_MUCH`, `CHANNEL_PRIVATE` and the rest of
       the refusals: refused with the word;
     - a stated wait: waited, and the owner joins again;
     - no answer: not known.
   - A lost join is harmless to repeat, but the program still never repeats it. The settle of a "not known"
     join is the next chat list or the state call: is the account in the chat now?
   - Peers in the answer are stored, as for the look.
   - **The join cap, the app's own, on top of the click cap:** at most 5 joins in any hour and 20 in any
     day per account. These are two stored settings with those defaults and no upper bound of the app's own
     (the owner's rule: a cap is a setting, no arbitrary maximum). Read them as `ReadClickCap` reads its own,
     and keep them in the same settings place. Over the cap, the click is refused locally in fixed words
     with when it opens again.
3. **`leave`: one click, a fixed sequence of requests, each step recorded.**
   - First `messages.getPeerDialogs` on that one chat (1 request): is it still in the account's chats? Not
     there: done, "already out", and nothing more is sent.
   - Then by kind, as the old app: a channel or supergroup `channels.leaveChannel`; a basic group
     `messages.deleteChatUser` (self) then `messages.deleteHistory` while offset > 0; a private chat
     `messages.deleteHistory` while offset > 0. Never `revoke`, never `just_clear`.
   - **Each request is counted, and the row records which step was reached.** The next step goes out only
     after a definite "done" of the step before. Any wait, refusal or unknown ends the click at that step,
     recorded with the step. A "finish leaving" click (the text step's `TryAgain` path, or a new click naming
     the old one: your choice, said in the report) goes on from the step recorded. Every step is harmless to
     repeat.
   - The history loop is bounded: at most 50 rounds in one click; then it ends as "not finished".
   - Refused locally, with no request:
     - Saved Messages (`SelfID`);
     - the app's own mirror chats (`IsMirror`);
     - a chat with no access hash on record.
   - **After a done leave, the catalogue marks the chat "left by the owner"** (rules 2 and 3 of
     `TRIED-BEFORE` 24: a durable record, and checked before any later step). The reader does not read that
     chat again, and the automatic mirror does not take it as a source, until the owner joins it again.
     Nothing of the archive is deleted, and the owner's earlier choices for the chat are kept as they were.
     Find how the catalogue already records a chat the account is no longer in. If nothing fits, the mark
     goes in the schema step (2.2). Find the places where the reader and `internal/mirror` choose chats,
     and say in the report exactly which lines skip a left chat. The lines in `internal/mirror` are the
     mirror track's: name them, change none, and the session will ask that track.
4. **`mute`: `account.updateNotifySettings`.**
   - The peer goes as `inputNotifyPeer`; only `mute_until` is set: a number of seconds from now (the page
     offers 8 hours and a week), "for good" (2147483647, as Telegram's own apps send), or 0 to unmute.
   - 1 request.
   - A lost answer is not known and is never repeated by the program. The next state of the chat shows
     which it was.
   - Saved Messages may be muted.

**For every one of the four:** it counts as one click against the click cap (1 a second, 30 in 5 minutes; a
leave counts once, however many steps). A frozen account refuses all four locally. A refusal of the account
stops all four.

### 2.2 The ledger (one schema step)

- The four kinds go into `c_act`'s `kind`. Its CHECK lists six words today. **Prefer widening it** by
  rebuilding the table in one transaction: create the new table, copy every row, drop the old, rename. Every
  row and every reference to it (`c_act_msg`, the key rows of `schema_actkey.go`, any index or trigger) must
  come through unchanged.
  - Test it on a catalogue holding a row of every state and of every kind, and with key rows: the counts
    and contents before and after must be equal.
  - If the rebuild cannot be made safe, use a table of its own for the chat actions whose rows the cap's
    `Sent` also reads, and say why in the report.
- Columns as needed:
  - the look's answer (cleared as the text is);
  - the join's look number;
  - the leave's step reached;
  - the mute's `mute_until`;
  - the left mark, if 2.1 point 3 needs it.
  Each column has a CHECK, as the ledger's columns do.
- **The schema number:** on your branch the step after the head's newest, the number in two constants, as
  every branch does (the board's "Schema numbers"). The integrator sets it at the merge. Tell the session the
  constants' names.

### 2.3 The collector and the door

- `QueueClick` and the click's turn take the four kinds. The turn sends them as it sends a text. The state
  call adds:
  - when the join cap opens;
  - the account's count of channels and supergroups it is in, against 500, taken from what the catalogue
    already knows (say exactly what it counts and what it leaves out);
  - the new-chats switches that are on now (the automatic mirror of joined chats, the download choice for new
    chats), read from their existing settings, so that the look-first page can say what a join leads to;
  - a chat's mute state, where the catalogue knows it (if nothing records it, say so, and do not add a
    request for it).
- **The door (`internal/server/clicks.go`, pages', as ONE lent commit):** the queue route takes the four kinds
  with their fields, and the click route returns the look's answer. Prefer no new route. Every refusal is one
  word of the door's closed set; add words only where none fits, and list them. The door's guard, its secret
  and its body limit are unchanged.
- **The fake Telegram** (`internal/collector/faketg`) answers the seven new requests: `checkChatInvite` in
  its three forms, `resolveUsername`, `importChatInvite`, `joinChannel`, `getPeerDialogs`, `leaveChannel`,
  `deleteChatUser`, `deleteHistory` with an offset that counts down, and `updateNotifySettings`. Each also
  answers with the words above, a stated wait and no answer.

## 3. Tests (each rule's test seen failing first)

For each rule, make the test fail first by undoing its line in a copy loaded with `go test -overlay` (nothing
in the tree edited), as the K8 report does. Cover:

- R1 to R12 for each of the four kinds.
- The join names its look; a stale, foreign or spent look is refused.
- The join cap, at the hour's and the day's edge, and with the settings changed.
- `INVITE_REQUEST_SENT` and `USER_ALREADY_PARTICIPANT`.
- The leave's steps:
  - a wait at each step, then "finish leaving";
  - "already out";
  - the history loop's bound;
  - never `revoke`, checked bit for bit as `TestActFlags` does;
  - Saved Messages and a mirror refused.
- The left mark: written once, read before the reader's next pick; the owner's choices for the chat
  unchanged.
- Mute: the three values; the flags bit for bit.
- The schema step on a catalogue with rows.
- An end-to-end test at the collector's fake Telegram, through the door: a look, a join, a mute, a leave,
  each exactly the requests above and no more.
- A privacy test, as `act_privacy_test.go`: no title, hash, username, name or id in any log, error or
  count, for every kind and outcome.

## 4. What you hand back

- `archiver/docs/progress/client-chat-REPORT.md`:
  - the API as built;
  - the rule, test and mutation table;
  - the schema step and its constants;
  - every lent line (file, function, why);
  - where the reader and the mirror choose chats (2.1 point 3), with the mirror's lines named and not
    changed;
  - what in this brief was wrong, impossible or decided otherwise;
  - the named tests you ran, with their times.
- Everything committed on `wip/client-chat` and pushed to `private`. The two lent commits are separate. Your
  copy is left clean.
- **Stop at the first thing that would need a request to the real Telegram, a change in the viewer or the
  window, or a decision the design does not make.** Write it in the report, and hand back.
