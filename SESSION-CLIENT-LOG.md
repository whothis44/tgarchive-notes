# The client track: acting in chats (progress file)

Started by the integrator I-6 on 11-21 at the owner's word. Owns the acting side of "the app used like a
Telegram client" (send, reply, edit and delete one's own, forward, react, mark as read; later files, join,
leave, mute). The reading side is the viewer's (B9); the compose box and buttons are the viewer's; the door's
place in the one program is pages' (P7). Reports through `BOARD.md`, `MERGE-QUEUE.md` and this file only.

## SESSION A-1 (Opus; started 11-21 21:23)

### 21:23 first look
- Read `CLAUDE.md` (archiver section) and the board's Direction, Tracks, items 25 and 28.
- **Found: the text step is designed, decided and built end to end, never run against Telegram.** The owner
  decided `DESIGN-CORE-client-actions.md` on 11-15 21:53 (item 28, all six choices as recommended). Merged on
  the main branch: piece 1 the request layer (29bcfa2e), piece 2 the ledger (698ee15d, schema 21) and the
  click's turn (d1ebd1a9), the settle of a "not known" click (a294e8d5), piece 3 the door on the collector's
  listener (efac56ff) and its guarantees (e9b8c540, schema 25), the viewer's pass-through (5a131192) and the
  compose box behind the seam. ROADMAP row "acting" says so.
- So the design note this track owes is for **step 3** (files, join, leave, mute), plus what is still open in
  step 2 (the first real click, Saved Messages' access hash, reactions not stored).
- Nothing running. Nothing committed yet. Next: read TRIED-BEFORE 24 and 25 in full, then the old app's
  join/leave/upload code, then write `DESIGN-CLIENT-acting.md`.

### 21:27 the design is written and on the board
- Read by me in full: `TRIED-BEFORE.md` 24 and 25; `DESIGN-CORE-client-actions.md`; `core-act-REPORT.md`;
  `TELEGRAM-FACTS.md` 11; the old app's `dialog_remove.go`, `chat_leave_api.go`, `forward.go` (upload).
  Checked in code: Saved Messages goes as `InputPeerSelf` (`act.go`, `SelfID`), so item 39 is not blocked by
  a missing access hash. The ledger's `kind` column has a CHECK on the six words: new kinds need a schema step.
- **`DESIGN-CLIENT-acting.md` written** (step 3: a file from the PC by upload, a file from the archive by
  Telegram's own copy, join with a look first and its own cap, leave with a second yes ported from the old
  app, mute; eight choices with recommendations).
- **Board (one script call of mine, a judgement: the words):** the Tracks row "Client"; message 215 (to Core:
  which files move to this track, answer awaited; to the viewer and pages: their parts of step 3, nothing now);
  "Waiting for the owner" item 45 (the design's go-ahead); a note on the "Listed and unbuilt" client row.
- **Asked the owner directly for the design's go-ahead** (the one direct ask allowed).
- Not done, on purpose: no coder and no brief before the owner's word (it writes to Telegram); nothing of step
  2's files edited before Core answers 215.
- **Next, in one line:** on the owner's yes, brief piece 1 (join, leave, mute) for one Opus coder in
  `wt-client-chat` on `wip/client-chat`; on Core's answer, take the files; meanwhile nothing runs.
- Worth a word to the viewer if it has room: the compose box's second fix round had no third look
  (ROADMAP row "acting"); the owner's first real click (item 39) goes through it.

### 21:34 the owner's yes; piece 1 with a coder
- **The owner, 11-21 21:30: "Yes, all eight"** (item 45 marked DECIDED). **And: "I sent a test message. Works
  fine."** (item 39, the text step's first real click, done; for the integrator to mark, message 219). **And:
  "remember the interface, since the whole app will need a rework for UI"**: my reading in message 219 (what
  pages need comes as data through doors; no HTML in the client's pieces); memory `ui-rework-coming`.
- **Piece 1 (look first, join, leave, mute):** brief `BRIEF-A1-chat-actions.md` (mine). Copy
  `wt-client-chat`, branch `wip/client-chat` from af4ca40e (made by me: a single command). **One Opus coder
  at high effort, started in the background at about 21:34;** it pushes `wip/client-chat` to `private` as it
  goes. The PC at the start: CPU about 85% (other tracks' builds, 7 go processes), 7.6 GB free; the coder
  builds only below 85% and with GOMAXPROCS=2 GOGC=25.
- Schema step claimed on the board's schema line (the step after the head's 26 on the branch).
- Core's answer to 215 (which files move) still awaited; the coder puts lines outside `act*.go` and
  `click*.go` in one "Lent to Core:" commit, and the door's lines in one "Lent to pages (server):" commit.
- **Next, in one line:** at the coder's hand-back: read the risky parts myself (the `c_act` rebuild, the
  leave's steps, the left mark), then one independent Opus review, its fixes, then the full runs once; while it
  works, brief piece 2 (a file from the archive).
- 21:34: **brief for piece 2 written, `BRIEF-A2-file-from-archive.md`** (a file the archive holds, sent from
  Telegram's own copy: one read through the refresher's `ask`, then one `sendMedia`). Not started: it is cut
  from piece 1's hand-back head (same files). Piece 3 (upload) is briefed after piece 2.

### 22:19 piece 2 in parallel (the owner: "Start piece 2 in parallel on its own branch")
- **The shared frame:** told piece 1's coder (a message to it) to push first one commit "Client frame:" holding
  the six kind constants (look, join, leave, mute, sendfile, upload), their counters and `notCounted` lines, the
  `c_act` rebuild allowing all six (and a caption in `text` for sendfile and upload), and the kind-word lists.
- **`BRIEF-A2-file-from-archive.md` changed for parallel work:** piece 2 writes in files of its own, merges
  exactly the frame commit when it is on `private` (stops after about 90 minutes without it), and keeps its
  columns in a table of its own (`schema_actfile.go`), so the two branches meet only at the frame.
- **Copy `wt-client-afile`, branch `wip/client-afile` from 6aa225fb** (the main head moved: M6 and M13
  merged) (made by me: a single command). **One Opus coder at high effort started about 22:19.** PC at the
  start: CPU about 88%, 7.1 GB free; both coders build only below 85%, GOMAXPROCS=2 GOGC=25.
- Board: the row (two coders; merge piece 1 first), a second schema claim (A2's table).
- **Next, in one line:** at each hand-back: read its risky part myself, one independent Opus review, the fixes,
  then the full runs once per piece; piece 3's brief (upload) after piece 2's.
