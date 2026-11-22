# The viewer's seam for the owner's clicks, as built (viewer session B5, 11-16; `wip/b-compose` 42a1df11)

For Core's piece 3 (the routes on the collector's listener) and the viewer's pass-through. Not reviewed yet:
an independent review runs; what it changes is added at the end of this file. Source:
`internal/viewer/act.go` on `wip/b-compose`.

## The interface (`viewer.Config.Act`; nil: this viewer cannot act and draws nothing)
```go
type Act interface {
    ChatState(ctx, account, chat int64) (ActState, error)
    QueueClick(ctx, in ActInput) (int64, error)            // the click's number (its ledger row)
    CancelClick(ctx, ref int64) error
    SendClickAgain(ctx, ref int64, tryAgain bool) (int64, error)
    ClickVerdict(ctx, ref int64, arrived bool) error
}
type ActInput struct {      // field for field the collector's ClickInput
    Account, Chat int64     // catalogue numbers; Chat is a forward's destination
    Kind string             // catalog.ActSend, ActForward, ActEdit, ActDelete, ActReact, ActRead
    ReplyTo, Topic, Target, From int64   // Telegram's message ids in that chat; From: a forward's source chat (catalogue number)
    Msgs []int64            // a forward's or a delete's messages, in order (an album whole)
    Emoji string; Revoke, TryAgain bool; Text string
}
type ActState struct { Write bool; Why ActWord; MaxText int; MarkAsRead bool }
type ActRefusal struct { Word ActWord; UntilMs int64 }     // *ActRefusal is the door's "no"
```
- `MaxText` is counted in UTF-16 code units; 0 means not known, and then no text goes.
- Any error that is not an `*ActRefusal` (wrapped ones are found) is shown as "failed"; its text is written
  nowhere.

## What the door must answer for `ChatState`
Whether this account can write in this chat now; if not, one of six words: "not running", "not signed in",
"frozen", "writes stopped", "mirror", "clicks off". Any other word is shown as "failed". With it: the
largest text, and whether "mark as read" is on.

## The refusal words (the door's every "no" is one of these; only "wait" and "cap" carry a time)
"wait", "cap", "too long", "empty", "limits unknown", "not addressable", "protected", "not own", "channel",
"no message", "read marks off", "setting", "not tip", "state", "not a click", "not found", "refused earlier",
and the six above. The viewer's own, never the door's: "not here", "bad request", "too soon", "failed",
"no account", "ledger".

| The collector's error (`click_api.go`) | Word |
|---|---|
| ErrNotRunning | not running |
| ErrClicksOff | clicks off |
| ErrClickNotOwn | not own |
| ErrClickChannel | channel |
| ErrClickNoMessage | no message |
| ErrReadMarksOff | read marks off |
| ErrClickSetting | setting |
| ErrClickNotTip | not tip |
| ErrClickState | state |
| ErrNotAClick | not a click |
| catalog.ErrNotFound | not found |
| the request layer's local "no"s (frozen, account refused, mirror, protected, refused earlier, no access hash, the cap, a wait running, the text, no limits) | "frozen", "writes stopped", "mirror", "protected", "refused earlier", "not addressable", "cap" (with its time), "wait" (with its time), "too long" or "empty", "limits unknown" |

## What the viewer checks itself before it calls the seam (the door checks again)
The chat is in its index and the account is one of the chat's accounts (for a forward, of the destination
too); posts belong to the chat, the topic to the chat, the emoji to a fixed row; only the fields of the kind
are set; a mirror chat (source or destination) and a source known to be protected are refused without
asking the seam; an empty text, or one longer than `MaxText`, is refused, never cut; a read mark only when
the switch is on, at most once per chat in 30 s. The viewer reads the ledger's rows itself, read-only,
through `catalog.ChatClicks` and `catalog.Click`: the door needs no read route for them.

## Changed by the fix round (`wip/b-compose` b1dc2f9f, 11-16 02:50; its second review look runs)
- `ActInput` gains **`Key string`**: 16 to 64 lower-case hex digits, made by the page for each click and the
  same when the same click is sent again after an answer that was not a refusal. The door should answer a
  key it has already given a click number with that number, and queue nothing new (a memory of minutes is
  enough). The viewer does the same in front of it for the keys that got a number (at most 1,000, 10
  minutes); a key whose call failed or was refused goes to the door again.
- Every call of the seam carries a context with a **20 s deadline**; the pass-through honours it and leaves
  a click fully queued or not at all. The page's own timeout is 30 s.
- Two more words, 31 in all: **"bad character"** (a text holding U+FFFD or a NUL, or not well formed: refused
  before the seam) and **"reading"** (the viewer's own, never the door's: the box is closed while the first
  read of a chat's clicks is incomplete).
- Refused by the viewer before the seam where its index can tell: "channel" (an edit or a delete in a
  broadcast channel), "not own", "no message" (a deleted target; deleted messages are left out of a
  delete's and a forward's list). The door decides again.
- The viewer no longer uses `catalog.ChatClicks`: it picks row numbers and states by its own read-only SQL
  on `c_act` (the index `c_act_chat`) and reads every row through `catalog.Click`.

## Changed by the second fix round (`wip/b-compose` f361d35c, 11-16 03:19; read by the main session, no third review look)
- **A key is tied to its click.** The viewer keeps with each key a hash of the click's resolved form
  (account, chat, kind, reply, topic, target, source, the messages, emoji, revoke, try-again, text) and
  answers "bad request" to a known or busy key that comes with another form. **The door must do the same**,
  and remember keys for longer than the viewer's 10 minutes. One known mismatch: a delete tried again after
  more of the post's messages were deleted reaches the door under the same key with a shorter list; a door
  that refuses it is right (the page shows the refusal).
- **Deadlines.** The seam's calls of one request share one 20 s deadline. For the queue, the cancel, the send
  again and the verdict the context is not cancelled when the page goes, only by the deadline: the
  pass-through can rely on the call finishing, and a queue that completes is recorded under its key. The
  state calls (one per account, one after another) stop when the page goes: each must answer in well under a
  second.
- **The viewer's state route** takes `?key=` and answers whether it holds a click number for that key
  (`key_ref`, `key_busy`): the page empties its box only on that, never on a match by text. While the viewer
  holds a key as busy the door is not asked a second time.
- **Words: 33.** New, both the viewer's own: "nul character", "part deleted" (a forward of a post with a
  deleted message is refused before the seam). "bad character" now means U+FFFD only.

## What the viewer assumes of the door
- "Own message only" for an edit and a delete is the door's decision (the page's is a hint).
- A reply in a forum sent while the page shows all topics has Topic 0: the door places it.
- One call of `QueueClick` is one click with a new random id: the page must never call twice for one click
  (under review).
- The viewer's routes are for this PC's listener only; the home-network listener refuses them in every class.

## Changed by the pass-through (B6; `wip/b-door`, 11-16; not reviewed yet)
Source: `internal/viewer/act_door.go` (new; the one file of the viewer that connects), `act.go`. The two commands
are NOT changed: the seam stays nil in both programs until the door is merged and this piece has had its own
security review.

### The seam
```go
type Act interface {
    ChatState(ctx, account, chat int64) (ActState, error)
    QueueClick(ctx, in ActInput) (int64, error)
    CancelClick(ctx, ref int64) error
    SendClickAgain(ctx, ref int64, tryAgain, notInChat bool) (int64, error) // K9c's second word
    ClickVerdict(ctx, ref int64, arrived bool) error
    ClickNotArrived(ctx, ref int64) error                                    // new (K9c)
}
```
- `notInChat`: the owner's "it is not in the chat" over a repeat the app stopped ("not sent", why "the earlier
  try is in the chat"). The page gives it on that row only, with the button "It is not in the chat: send again";
  a plain "Send again" on a "not known" row gives it false (the app's check before a repeat then still guards).
- `ClickNotArrived`: the owner takes back an "arrived" the app made (why "found in the chat by the app").
- The viewer's routes: `POST /api/act/again` takes `not_in_chat`; new `POST /api/act/not-arrived` {chat, ref}
  (class local, the page's token, the click must be one of the chat's, as the other ref routes). Seven routes.
- Words: 35. New, both the door's: **"key"** (the key came with another content: shown as a fault of the page;
  the page drops the key and keeps the text, nothing more is sent by itself) and **"queue full"**.
- `ActState.Why` may now also be "setting" and "not found" (Core's message 101: the state call gives them); any
  other word from the door is a failure.
- The door's words (a 409's word, a state's why) are a closed set of 25: the six state words, "setting", "not
  found", the refusals of the table above, "key", "queue full". The viewer's own ten ("not here", "bad request",
  "too soon", "failed", "no account", "ledger", "reading", "bad character", "nul character", "part deleted")
  coming from the door are a failure, never passed on.

### How the door is found
`viewer.NewActDoor(find ActDoorFind)` with `type ActDoorFind func() (addr, secret string, ok bool)`. The program
hands in a function over the pages track's reader of `act-door.json` beside the catalogue (the viewer imports
nothing new). It is called again for every call of the seam (the state call: at most twice); address and
secret are always the pair one call gave. `ok` false (no file, or a file that cannot be read): nothing leaves.
`find` must be safe for concurrent calls.

### What it sends (the door must take exactly this; the door's report is not written yet)
All POST, body JSON, header `Content-Type: application/json` and `X-Tgarchive-Door: <secret>`; never `Origin`,
`Cookie`, `Referer` or `Sec-Fetch-*`.
| Route | Body | 200 answer read as |
|---|---|---|
| `/api/act/state` | `{"account","chat"}` | `{"write": bool (required), "why": "", "max_text": int >= 0, "mark_as_read": bool}`; other fields ignored (not used yet); `why` must be "" when `write`, a state word when not |
| `/api/act/queue` | `{"account","chat","kind","key"}` always, and only the kind's own of `reply_to`, `topic`, `target`, `from`, `msgs`, `emoji`, `revoke`, `try_again`, `text` (zero values left out) | `{"ref": int > 0}`, nothing else |
| `/api/act/cancel` | `{"ref"}` | `{"ok": true}`, nothing else |
| `/api/act/again` | `{"ref","try_again","not_in_chat"}` (both always) | `{"ref": int > 0}`, nothing else |
| `/api/act/verdict` | `{"ref","arrived"}` | `{"ok": true}`, nothing else |
| `/api/act/not-arrived` | `{"ref"}` | `{"ok": true}`, nothing else |

**Two shapes are this side's choice, not yet the door's word:** the state's field names (`write`, `why`,
`max_text`, `mark_as_read`) and `{"ok": true}` as the 200 of cancel, verdict and not-arrived. If the door answers
otherwise, every such answer is a failure until one side is changed.

### What comes back
- 200: the route's answer, strictly (unknown fields, a second value, a wrong type, a ref of 0: failure); the
  state's unknown fields are ignored.
- 409 `{"word", "until_ms"}` (strict; `until_ms` may be left out): `*ActRefusal` when the word is the door's; the
  time kept only for "wait" and "cap", dropped for any other word.
- 400, 403, 500, any other status, a redirect (never followed), a body over 64 KB, a body that cannot be read:
  failure.

### The client
To `127.0.0.1` only: the address must be exactly `127.0.0.1:<1 to 65535>` (digits, no leading zero); the secret
32 to 128 hexadecimal digits. Anything else: refused with no connection made. A client per call: no proxy, no
redirect, no cookie jar, plain HTTP/1.1, no kept connection (one connection, one request), a dial ("tcp4") that
reaches the checked address whatever the URL says, response headers up to 16 KB, the caller's context and
deadline (a backstop of 20 s when it has none).

### Two kinds of failure
- (a) nothing left this program (no file, refused address or secret, no connection could be made while the
  caller's time ran): the state is "cannot write: not running" (the page's existing line); a change is the
  refusal "not running" (certain: nothing queued; the viewer forgets the key).
- (b) the request left and no usable answer came, or the caller's time ended first: a failure ("failed"; the
  page holds Send until the state is read; the next try carries the same key and the same body). (b) is never
  turned into (a). No changing call is ever repeated by the pass-through.

### The door that comes and goes
Until a door file has been found once in this run, the viewer acts exactly as with a nil seam: no flag in this
PC's page, every route "not here", no "act" in the live poll (the old archive opened by the same programs stays as
it is). The file is looked for at most every 5 s for that. Once seen: the page has the flag (read per page load
now, not once at the start), and a door that went away shows "not running". **A chat page already open learns
it through its live poll:** the answer of `/api/chat/{id}/live` carries `"act": true` on this PC's listener while
the viewer can act, and the page then attaches the box and puts the buttons on the messages already drawn (away
from the newest end, where no live ask runs: when the chat is opened again with the flag, after a page load).

### The app's own settle (K9c), as drawn
- An "arrived" with why "found in the chat by the app": drawn (it stays in the clicks' read as an open row until
  `actTipDays`), on the message the app took (a send's new message, a forward's first copy) when that message
  is in the index, with the line "The app found this in the chat" and one button "It is not in the chat"
  (`/api/act/not-arrived`). An "arrived" of the owner's own verdict is not drawn, as before.
- A "not sent" with why "the earlier try is in the chat": the button "It is not in the chat: send again".
- The three words are the catalogue's own constants (`catalog.ActFoundByApp`, `ActWhyEarlierInChat`,
  `ActOwnerSaidNot`): the main head with K9c (a294e8d5, with G7 and K13: head a29fe931) is merged into the branch.
- **The candidates REPLACE the page's own match by text.** The hint "It is in the chat" of a "not known" send,
  forward, edit or delete is now the message `catalog.ClickCandidates` names (read by the viewer itself on its
  read-only handle): the one the app would take, else the first candidate inside the try's window; the
  "arrived" button comes with it. Why replace: the candidates are the app's own rule (byte for byte, the
  account's own, not forwarded or edited, in each try's window, not tied to another click, never a message the
  owner rejected), and they cover forwards, edits and deletes; the match by text trimmed spaces and could offer
  a message the owner had rejected or another click had taken. Read once per click, row state and version of
  the index (at most 256 kept); a read that fails gives no hint (counted as a catalogue read failure), the
  buttons stay. Known and accepted: a text Telegram stored with its outer spaces trimmed is no candidate (the
  careful side, as in K9c); a reaction or a read mark never gets a hint.

### Also
- The About page's promise: "This viewer never changes the archive. It makes no connections, except to the
  collector on this PC, and only to hand over what you send from a chat."
- The timings (`/api/stats`) carry `act_door` {calls, not_left, no_answer, refused, answered} when the seam is
  the pass-through: numbers only.
- The wall: `act_door.go` is the one exception for connections (`http.Client`, `http.Transport`,
  `http.NewRequestWithContext`, `net.Dialer`, each once, in one function whose only caller checks the address
  and the secret first); `TestWallDoorOneClient` pins it.

## Changed by the pass-through's fix round (B6-D2; `wip/b-door`, 11-16; after the review of d5dd4869)
The two commands are still NOT changed: the seam stays nil in both programs until the door, Core's key memory
(the review's finding 1, Core's piece) and this piece's second look are done. Everything below is in
`internal/viewer` (`act_door.go`, `act.go`, `act_keys.go`, `act_ledger.go`, `web/js/act.js`) and its tests.

### The door's answers as built (the door's report, section 2)
- Cancel, verdict and not-arrived: 200 `{"ref": n}`, the click acted on. Read strictly: `n` must be the click
  asked (at least 1); `{"ok": true}`, another number, 0 or a field more is a failure. (The table above said
  `{"ok": true}`: that is gone.) The viewer's own routes still answer the page `{"ok": true}`.
- The STATE route: a 409 whose word is a state word ("not running", "not signed in", "frozen", "writes
  stopped", "mirror", "clicks off", "setting", "not found") is the state "cannot write" with that word, and the
  page shows that word's line; any other 409 word there ("wait", "key", an unknown one) is a failure. 403 (the
  door's guard, body `{"word":"refused"}`), 404 (no door, or no route) and 503 (the collector starting,
  stopping, or without pages) there are "cannot write: not running": nothing is at stake in a state read.
- For the five changing calls nothing of that changes: 400, 403, 404, 500, 503 (and 421, any other status) stay
  failures ("the request left and no usable answer came").
- A refusal's time ("wait", "cap") is taken only when it lies after now and at most one year ahead, on the
  viewer's clock (`ActDoor.now`, handed in by a test as the other clocks are; `time.Now` otherwise). Any other
  time: the word without a time.

### Deadlines: one for each call
`act_keys.go`: a state call 5 s (`actStateTimeout`); a changing call 18 s (`actChangeTimeout`), LONGER than the
door's own 15 s, so the viewer never gives up on a change the door is still working on; the ledger's check of a
door's number 2 s (`actCheckTimeout`, its one read again included). A click's request makes one state call,
one change and one check one after another: 25 s at most, under the page's 30 s. A page's state read asks one
state call per account of the chat, each with its own 5 s, inside 20 s for the whole read. The single shared
`actSeamTimeout` is gone.

### One click, one request: the page (findings 2 and 6)
- The box: once a key has had an answer that was not a refusal ("failed", or no answer in 30 s), the page keeps
  that key with that content until a state read shows a number for it, or the owner changes the content (a
  changed text, reply, topic, account or message is a new click with a new key). A refusal of a later try
  (the door's "not running" during a held stop, the viewer's own state gate, "ledger", "queue full", "too long",
  "limits unknown") does NOT drop it.
- The buttons (forward, delete, reaction): the same for their kept keys. A kept key is never forgotten for room:
  with 32 kept, a new button's click is refused, nothing sent, in the fixed words "Too many clicks on this page
  have no known outcome yet: nothing more is sent from these buttons until one is known. Look in the chat."
  The kept keys leave when the same button is pressed again and the state read shows the key's number, or
  when that button's click is taken.
- A button's click that is out is recorded before it is asked: while it is, the same button (the same account,
  kind, message, destination or emoji, revoke) answers "The collector is still being asked about this; try
  again in a moment." and sends nothing.
- The page's memory is the page's: a reload forgets the kept keys (the server's own memory, and the door's
  key memory once Core has built it, are what stand behind a reload).

### "Send again" takes the owner's words only where the row offers them (finding 4)
`POST /api/act/again`: `not_in_chat` is "bad request" unless the row is "not sent" with why "the earlier try is
in the chat" AND its buttons offer "notin" (its text is still kept); `try_again` is "bad request" unless the
row's buttons offer "try" (a refusal the chat remembers, or "not sent" because of a refusal earlier). The seam is
not called then. A plain send again goes on as before. The door and the catalogue are asked by the main session
to refuse the same; the viewer refuses first regardless.

### A number is believed only when the ledger has it (finding 9)
After a 200 with a click's number from queue or send again, the viewer reads that row itself through the
catalogue's own door (`catalog.Click`, read-only). Queue: the row must be of this account, in the chat it acts on
(a forward's destination), of this kind, and a first row (no `again_of`). Send again: of the same account, chat
and kind as the row sent again, and its `again_of` must be that row. Otherwise (no such row, another chat's,
another kind's, a read that fails): the page's words for a failed change ("failed"), the key gets no number.
The lag: the collector commits the row before its door answers, and the viewer's read-only handle sees every
commit at its next statement (SQLite's WAL), so the first read finds it; when it does not, the row is read once
more after 250 ms (`actLagWait`), never more. Only the pass-through is checked this way (`actChecksNumbers`); a
seam handed in by a test answers for its own numbers. What a program that is not the door, sitting on a stale
door file's port, still receives: the old secret (worthless: every start of the collector writes a new one)
and the text of the click; this is accepted on a PC with one user.

### The hint of a click not known (finding 11)
A candidate the app takes: the hint as before (`in_chat` and the button "It is in the chat"). A candidate the
app does not take (the first inside the try's window): only together with one sentence of the third closed set
`actCandSay` in `act.go`, by the catalogue's fixed why word, sent as `in_chat_why` and drawn beside the button.
A why word with no sentence there gives no hint at all. The fourteen sentences all read "This message may be the
click's, but the app does not take it: ..." followed by, by word: more than one message could be it; another
click with the same content is waiting; another click with the same content went out and its message is not on
record; it cannot tell whose message it is; it is outside the time the click could have arrived in; not every
message of the click is found; the click was sent again; nothing in the archive tells this kind of click; the
forward names no post; nothing was found for it; the account sent this text in the chat before; the deleted
mark cannot tell for whom it was deleted; the chat's last 7 days are not all in the archive; you said it is not
in the chat.

### An "arrived" the app made leaves first (finding 12)
Over the bound of open tips (the clicks' read, 200 per chat and account; the drawing, 50), an "arrived" the app
made leaves first, the oldest of them, and never pushes out a row that needs the owner; the answer says "more".
The seven days stay.

### The wall (finding 7)
- `TestWallImports` refuses a renamed, dot or blank import of `net`, `net/http`, `crypto/tls` and `os/exec`
  anywhere in the package; `TestWallNoOutboundCalls` resolves every selector through the file's import table (the
  path, not the local name).
- The door's client is made in `actDoorClient` (its only caller is `actDoorPost`, whose only caller is `call`).
  `TestWallDoorOneClient` counts the allowed selectors in the WHOLE of `act_door.go`, package-level declarations
  too: `http.Client` (twice: the result type and the literal), `http.Transport` and `net.Dialer` only in
  `actDoorClient`, `http.NewRequestWithContext` only in `actDoorPost`; the transport sets exactly `Proxy: nil`,
  its own `DialContext`, `DisableKeepAlives`, `DisableCompression`, `MaxResponseHeaderBytes`; the client exactly
  `Transport` and `CheckRedirect`; the dial is `DialContext(ctx, "tcp4", hostport)` and `hostport` is set once.
- `TestWallDoorDialsCheckedPortOnly`: requests through that very client for another port and other loopback
  addresses reach only the checked port (two listeners that count accepts).

### Not used yet (the state's extra fields after K14) and not changed
The state's unknown fields are still ignored. Core's key memory (the door answering a known key with the same
click, from the moment the request is read) is still the precondition for wiring the seam.

## Changed by the last small round (B6-D3; `wip/b-door`, 11-16; after the review's second look of 25365ae2)
The two commands are still NOT changed; the seam stays nil in both programs.

- **A kept key and the way out (second look, finding 4).** A kept key can hold one text of the box (each Send
  of it goes out under the same key and may get the door's "key" again) or, once 32 are kept, every new button
  and every new text of the box, until the page is loaded again. Loading the page again is the way out, and it
  forgets all the page's keys.
- **The box keeps its uncertain keys by content (finding 2).** As the buttons keep theirs: an entry (account,
  kind, message, reply, topic, text) stays until a state read shows a number for its key or a try of it is
  taken; a try of other text between does not drop it, and Send of the same content reuses its key. Bounded
  at 32 like the buttons': a new text is then refused, nothing sent, with the same fixed sentence as a new
  button ("Too many clicks on this page have no known outcome yet: ...").
- **The state route's 404 and 403 need the door's word (finding 5).** 404 is "cannot write: not running" only
  with the body word "no door", 403 only with "refused" (read strictly); 503 with any body as before. A 404 or
  403 with any other body (a route that moved, something that is not the door) is a failure. This replaces "404
  (no door, or no route)" above.
- **A number's row must be this click's time (finding 1, the stopgap).** On top of the ledger check above, a
  queue's number is believed only when the row's own click time is not older than the moment the viewer began
  the request, less 5 s for the two programs' clocks (`actClickSlack`); for send again the same on the new
  row. The full check, by the click's key in the catalogue (Core's key memory), comes with the wiring.
- **The wall (finding 3).** It also refuses, in every file of the package: every `net.Lookup*` and every
  `net.Resolve*` (by prefix; `net.Resolver` and `net.DefaultResolver` among them), `net.ListenPacket`,
  `net.ListenUDP`, `net.ListenIP`, `net.ListenMulticastUDP`, `syscall.Socket` and `syscall.Connect`. No file
  of the viewer uses any of them today; the listener for other devices at home uses `net.Listen` only.

## Changed by the wiring (B6-D4; `wip/b-door` e6223482, 11-16 14:43; holds the main head e9b8c540: the door, Core's K14)
Not reviewed yet. The seam is now handed in by both programs; everything else of the contract above stands.

### The two programs hand the door in
- `tgarchive viewer` (`cmd/tgarchive/viewer.go`) and `tgarchive-window` (`cmd/tgarchive-window/main.go`) set
  `viewer.Config.Act = viewer.NewActDoor(actDoorFind(-db))`. The finder is a small file of each command
  (`actdoor.go`, the same in both): the folder is `filepath.Dir` of `-db` exactly as given (as the viewer's own open
  resolves it); it looks with `os.Stat` whether `actdoor.FileName` is there and calls `actdoor.ReadDoorFile` only
  then; every error, and a panic, is "no door"; it holds no state (safe for calls at once). The viewer package
  imports nothing new; its wall tests are unchanged. With `-lan` nothing changes (the routes are this PC's only).
- Without a door file (the old archive, a collector not running with `-pages`) the viewer is as with no seam.

### A number is believed by its key (the stopgap is gone)
- Queue: after a 200 with a number, `catalog.ActKey(account, key)` on the viewer's read-only handle must hold a
  row for this account and this key that names exactly that number; then the row is read through
  `catalog.Click` as before (this account, the chat it acts on, this kind, a first click). The click-time rule
  (`actClickedSince`, `actClickSlack`) is removed: a second try under a known key is answered with the FIRST
  try's click, however old, and that is right. A catalogue with no key table (an older file) holds no key: the
  number is not believed ("failed"). Key row or click not there: both read once more after 250 ms, never more.
- Send again (no key): the new row must be the one repeat (`again_of`) of the row asked, of its account, chat and
  kind; the click-time rule is removed there too (the catalogue allows one repeat per row).

### The state read learns of a click by its key
`GET /api/act/chat/{id}?key=K`: when the viewer's own memory does not hold K (it forgot it after a failure, or it
was started again), `key_ref` comes from one `catalog.ActKey` read for the account of this read (the resolved
account; before it is resolved, the account asked, if any). One read per ask; a read that fails gives 0 (counted
as a catalogue read failure; the page keeps its key, and its next try goes to the door, which knows the key).

### The state's fields the viewer uses
- Read from the door's state answer: `caption_max`, `wait_until_ms` (per kind word), `slow_mode_until_ms`,
  `cap_until_ms`, `now_ms`. A number below 0 in any of them, or in `max_text`, is a failure.
- Left unused: `read_mark_until_ms`, `forward_max`, `limits_wanted` (with `max_text` 0 the existing "limits
  unknown" holds), `mark_bad` (`mark_as_read` is false then), `cap`, and any later field.
- **A caption is judged by the viewer.** An edit whose message has media (in the viewer's index: the message has
  attachments) is refused before the door when its text is longer than `caption_max` ("too long", the existing
  words), and with `caption_max` 0 "limits unknown". The text's limit (`max_text`) is checked first, as before.
- **A wait, the slow mode or the cap that runs.** For the box's two kinds (send, edit): a time runs when it lies
  after the answer's own `now_ms` (the collector's clock; never this PC's) and at most a year after it; the
  candidates are the wait for the kind, the slow mode (a send's), the cap's opening (every kind); of several,
  the latest. The click route refuses such a click with "wait" (a wait or the slow mode) or "cap" and its time,
  nothing sent. The state route answers `not_before: {"send"|"edit": {"refused","say","until","left"}}` (left:
  ms from the answer's `now_ms`); the page (`act.js` submit) shows that sentence with the time instead of sending
  while its own clock is before the answer's arrival plus `left`, and lets the click go once it is reached. An
  answer with no `now_ms` judges nothing.

### Tests (named; all ok at e6223482)
- Viewer: `TestActStateKeyFromCatalogue`, `TestActCaptionJudged`, `TestActHoldByCollectorClock`,
  `TestActDoorStateNewFields` (new). Changed: `TestActDoorNumberHeld` (the honest door writes the key row; a
  click the key does not name and another chat's click under the key are refused), `TestActDoorOldRowNotBelieved`
  (now: a row with no key or under another key is not believed however new; a row under this key is believed
  however old; a send again's repeat is believed however old), `TestActDoorChangeOutlivesState` (its door writes
  the key row), `TestActClicksReadBounded` (its 10,000 invented clicks go in batches under the catalogue's cap of
  50 queued), the fake seam's default state carries `CaptionMax` 1024.
- `internal/acttest` (new, test files and `doc.go`): `TestViewerThroughRealDoor`, `TestViewerShowsDoorWords`,
  `TestViewerDoorGuardAndNoDoor` (a real viewer against the server's real door routes over a recording seam) and
  `TestWholeChainOneClickOneRequest` (the collector run as `run -pages` on its fake Telegram; one click one
  request and a row "done"; a lost answer, then the key's number from the collector's key memory and no second
  request; a wrong secret reaching nothing).
- Commands: `TestActDoorFind` in each (the finder: no file and no read; the file's address and secret, also for
  16 calls at once; a malformed file, a folder of that name, a panicking reader: no door).

## Changed by the wiring's fix round (B6-D5; `wip/b-door` e891d19c, 11-16 15:21; after the review's third look of e6223482)
Not reviewed yet. Three commits: the viewer's (fd30ce6a), the lent lines (f7a148b5, last but one), the finder's
and the tests' (e891d19c). Everything above stands except what is said here.

### The door file names its catalogue (finding 2; lent lines of `internal/actdoor` and `internal/collector`)
- The door file gains one field, `catalogue`: the base name of the catalogue file the collector opened (a name,
  never a path; 1 to 1,024 bytes of UTF-8, no separator, no colon, no control character, not "." or "..").
  `actdoor.Write(folder, addr, catalogue...)` takes it (one name, checked: `ErrBadName`); the collector's one call
  (`pages.go` openDoor) passes `filepath.Base` of its catalogue path. The reader's strict form takes exactly that
  field more; a file without it (an older writer's) is "not whole", so it is never taken for a door.
- The two programs' finder takes `filepath.Abs` of `-db` once, when it is made (finding 5: a later change of the
  working folder does not move it), and answers "no door" unless the door file's catalogue name is the base name
  of that path (the same folder and the same name are the same file; on Windows in any case).
- What it protects against: a second catalogue in the same folder (another archive, or a copy of the live
  catalogue opened beside it for safety) taking the door of the one the collector serves. Before, such a viewer
  could send a click into another catalogue's chat of the same number, or send for real while its own key check
  answered "failed". Now it draws nothing and sends nothing (as with no door file).
- `Write` without a name still writes, the older form, only so that callers built before it (the collector's
  test that writes an older file to see it replaced) still build; such a file is never a door.

### A known key goes past the viewer's own gates (finding 1)
- Click route: a key the viewer's own memory does not hold is looked up in the collector's key memory
  (`catalog.ActKey`, the click's account) first. **A key it knows goes straight to the door**, past the viewer's
  own refusals, the state call, the limits and the holds (the cap, a wait, the slow mode, the read mark's 30 s):
  the door answers a known key before anything else, with that key's click, or with the word "key" when the content
  differs. The viewer never answers such a click by itself: the door is asked, once, and its number is believed by
  the key as before. A delete's messages are those not deleted, as the gates hand them on; none left (the click
  itself may have deleted them): the post's messages as they were. A key the collector does not know, or a read
  that fails, takes the gates as before.
- State route: with no account resolved (every account "not running": the collector away), `key_ref` asks the key
  memory for each account of the chat that could have made the click (at most one read each), not none.
- The page (`act.js`): every state read carries the box's newest uncertain key while it holds one, not only the
  read that gives Send back. A read that shows a number for it drops the key and empties the box when it still
  holds that click (the same kind, message and text); nothing is sent again.

### The caption's limit only in an album (finding 3)
- An edit is judged by `caption_max` only where the message surely is a caption: it is part of an album (its
  catalogue row's `album_id` is set; read at the click). The catalogue records a link preview's picture as a
  message's own media, and a web page is never in an album. Every other edit, a single photo's or file's caption
  too, is judged by `max_text` only; a caption too long there is left to Telegram (one request, its refusal on
  the row). "Limits unknown" for `caption_max` 0 only in the album case.
- The collector's queue judges every edit by the text's limit (checked through the real chain: an edit of 1,500
  units of a message with a file and no album is queued). Nothing to put to Core.

### The chain test (finding 4)
- Each click goes as the page sends it: the state read first; a hold it announces in `not_before` is waited out;
  a "cap" or "wait" the read just before did not announce fails the test.
- The collector's pages listen on `127.0.0.1:0` (the system picks the port; no other program can take it between
  a pick and the bind); the test reads the address from the door file.
- It stops the collector after the lost answer (the state read learns the click's number with no account
  resolved), starts it again (a new secret, the same key memory), and the retry under the key gets the first
  click's number with no second send. A second viewer on a copy of the catalogue in the same folder (VACUUM INTO)
  answers "not here" to the state read and to a click; no row, no send.

### Tests (named; all ok at e891d19c)
- Viewer (new): `TestActKeyRefWhileDoorAway`, `TestActKnownKeyPastGates` (the reviewer's probe T1),
  `TestActEditWithAttachmentByTextLimit` (probe T2); changed: `TestActCaptionJudged` (the album rule),
  `TestActBoxKeepsUncertainKeysByContent` (case S5: the key on every state read), `TestActKeyInState` (its source
  check names the read's new key lines). The first four fail on e6223482's viewer code (run through an overlay).
- `internal/actdoor`: `TestDoorFileNamesItsCatalogue` (new), its other tests write a name.
- `internal/acttest`: the four, `TestWholeChainOneClickOneRequest` longer as above.
- Commands: `TestActDoorFind` in each (a copy beside the catalogue, another catalogue's file, an older writer's
  file: no door; the name in another case: a door on Windows only; a relative path made absolute once).
- The collector's `TestDoorPagesDoorFile`, `TestDoorPagesQueueOnFakeTelegram`, `TestDoorPagesOwnerActions` (they
  write or read the door file): unchanged, ok.
