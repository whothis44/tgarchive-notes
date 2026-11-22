# Brief M9 (11-15 23:24, the mirror session M4): the mirror's doors for the pages; a want made by the owner's hand, carried out by the running collector

**Your copy: `C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-door`, branch `wip/mirror-door`, cut from
`wip/mirror-timing` 2da8b60c** (the main head 2ea9b465 with the timing piece). The Go module is `archiver/` in
the copy. The house rules of every mirror brief apply: read
`C:\Users\trabi\Claude\Projects\Telegram\BRIEF-M7-auto-timing.md`, its first paragraph and its sections "Running
things" and "Report and hand-back", and `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-M8-protected-and-lows.md`,
its second paragraph: they bind you here (one copy; commit and push only `wip/mirror-door` to `private` as you
go; nothing against Telegram; invented data, the fakes and the injected clock; no name, text, id or link in any
log, error, printed line, test name or commit message; constant format strings; named tests only while working;
one go command at a time; the PC measured before each).

## Why (the owner, 11-15 23:20: "add in a functioning mirror option since that is immediately useful and we've tested it")
The mirror works today only as a command run with the collector stopped (`mirror -chat N`: run for real on
11-15, one chat completed, 751 messages) and as the automatic task inside the running collector for chats
joined after its start (`run -auto-mirror`, never run for real). The owner wants it from the Chats page of the
one program: "Mirror this chat" (several by multi-select), the plan shown, one yes, progress and state per
chat, "never mirror", the settle's choice. The pages track builds the page (its G4); **this piece gives it the
doors and makes the running collector carry out a want the owner made by hand.**

**Nothing new is sent to Telegram by this piece.** A mirror started from the page is work for the automatic
task's own loop: one writing request a turn on the one connection, the same intent rows, pauses, bounds and
settle. Never a second command beside the running collector, never a new kind of request, never a request
from an HTTP handler's goroutine: a door only reads and writes the catalogue through the collector's handle;
the reader task's goroutine sends, as today.

## What the record and the old app know
The old app never forwarded: nothing to port. TELEGRAM-FACTS 11 (five real runs, "looks like"): a first step is
3 requests (config, create, forward of 100); a pause of 20 s between forwards met no wait over 352 messages, 10
s met one of 9 s; a server error on a forward can mean "partly done", so an unknown outcome is settled from
what the mirror chat holds and never sent again; not known: creates per day, forwards per hour. FEATURES 12:
"chats are chosen by multi-select ... The app creates the mirror chat itself and names it from the source ...
Not checked yet: Telegram's limits on creating chats and on forwarding volume". TRIED-BEFORE 24 and 25, the 13
rules for anything that acts for the owner: here above all (1) never undo a person's choice, (3) the "never"
mark read again before every request, (4) stored waits checked at the top of every step, (7) one item per
call, each success recorded, a failure passed over, (10) a cap per step, (11) one row per item, never a stored
list, (13) fail closed on a stored value that cannot be read. LESSONS-ix12.30-live 6b: what the app took by
itself stays visibly the app's and below the owner's choices: **an owner's want goes before an automatic one,
and every state says who started it.**

## What exists (read by me on 2da8b60c; check each before you lean on it)
- `catalog/schema_mirrorauto.go`: `c_mirror_want` (one row per account and chat; end and block words),
  `AddMirrorWant` (refuses when the chat has a want OR ANY mirror row: `ErrMirrorOpen`), `MirrorWants`,
  `SetMirrorNever`, `MirrorMarked`, `MirrorMarks`, `MirrorAllow` (removes marks, clears ends and blocks),
  `EndMirror`, `BlockMirrorWant`, `MirrorStartedBy` (`c_mirror.started_by`: owner or auto).
- `mirror/auto.go`: `Look` (takes chats joined after the baseline: untouched by this piece), `Turn` (for every
  want: `autoCheck` before any request, then at most one request a turn: config, create, forward, or a
  settle's read through `AutoDeps.ReadMirror`), `settle` and its block words (`AutoBlockCannotTell`,
  `AutoBlockRepeat`, `AutoBlockAgain`, ...: the ones that end in "decides" wait for the owner's word),
  `autoCreate` (`BeginMirrorCreateBy(..., MirrorByAuto)`; the cap `NewPerDay`, default 5, counts creates by
  "auto" only: `MirrorAutoCreatesSince`).
- `mirror/mirror.go`: `MakeRunPlan(ctx, d, account, chat, Options)` gives `Plan`, pure data read from the
  catalogue (messages, media, `Candidates`, `FirstBatch`, `Channels` against the limit, `Protected`,
  `Marked`, `EndedWhy`, `Blocked` in fixed words, the settle's fields); its `fingerprint` is unexported.
- `collector/mirror_auto.go`: `autoOn()` is `cfg.AutoMirror && autoReady`; `startAutoMirror` sets the task up
  once, at the start, only with `-auto-mirror`; `autoTurn` runs in the reader task's goroutine (`Look`, then
  `Turn`); `autoApprove` writes the read's approval of a taken chat in the want's transaction; the forward
  secret is `cfg.AutoMirrorSecret` (32 bytes; `command.go:603`).
- `collector/mirror_cmd.go`: the owner's command: its `-settle` with `-take arrived|not-arrived` and `-create
  not-made`, `-never`, `-allow`, `-list`: the rules each applies are the rules of the doors below; share the
  code, do not write a second copy of a rule.

## What to build
### A. The catalogue (a new file `internal/catalog/schema_mirrorwant.go`; **schema step 22**, taken on the board; on your branch it is "the step after the head", the number in two constants, as `schema_mirrorname.go` does)
- `c_mirror_want.by TEXT NOT NULL DEFAULT 'auto' CHECK (by IN ('auto','owner'))`; `MirrorWant.By`; a word that
  cannot be read is `ErrBadLedger`.
- `AddOwnerMirrorWant(ctx, account, chat, at, also)`: one transaction. Allowed when the chat (and the chats its
  migration links it to: `chatFamily`) has no want row and either no mirror row at all, or one open mirror
  row that is created and not ended (the owner's command made it: the want then keeps THAT mirror current;
  no second mirror chat is ever made while the first may exist). Refused with a sentinel each, nothing
  written: a want exists (`ErrMirrorOpen`); the mirror or want ended for good (the owner allows first); the
  owner's "never" mark (the owner allows first: a click never removes a mark by itself); a mirror row in a
  state that is not settled ("creating", "unknown", "protected").
- **The owner's word for a waiting choice**, one row per (account, source chat) in a new table (never a list):
  the word (`arrived`, `not-arrived`, `create-not-made`), the batch or mirror row it was given for, when.
  `SetMirrorWord` (refused unless the want is blocked with one of the words that wait for exactly that choice,
  read in the same transaction), `MirrorWordOf`, and its removal inside the settle's own transaction. A word
  given for a batch that is no longer the blocking one is never applied (compare the ids).
- Read-only handles on an older file: the new reads say "nothing on record" as `hasAuto` does for step 18.

### B. `internal/mirror`, a new file `door.go`: the doors, catalogue only (they send nothing and start nothing)
Exported names as written here: the pages track codes against them from the board. If one must change, say so
at once in your report's first lines.
- `type ChatState struct`: `Chat int64`; `State string`, one of the constants `StateNone`, `StateWanted` (a
  want, its source not read to its end yet), `StateForwarding`, `StateComplete` (nothing left to forward now),
  `StateBlocked`, `StateEnded`; `By string` (`owner`, `auto`, or `command` for a mirror with no want);
  `MirrorChat int64` (0: none yet); `Forwarded int64` (messages on the ledger as forwarded); `Why string`
  (the block's or end's fixed words); `Choice string` (`ChoiceNone`, `ChoiceTake`: arrived or not-arrived is
  the owner's to say, `ChoiceCreate`: "not made" is, `ChoiceAllow`: only an allow unblocks it); `Word string`
  (a word of the owner's on record and not carried out yet); `Never bool`; `Kept bool` (the task keeps it
  current: a want that is neither ended nor blocked).
- `States(ctx, d Deps..., account) ([]ChatState, error)`: every chat of the account that has a want, a mirror
  row or a mark; **a fixed number of statements whatever the number of chats** (grouped counts, no plan per
  chat); a test at 300 mirrors and 200,000 forward rows under a generous bound, with the statement count
  asserted.
- `PagePlan(ctx, d, account, chat) (Plan, error)`: `MakeRunPlan` with the history whole (`Batches: All`) and
  media only (the command's defaults), plus what the command prints and the struct lacks, as data:
  `AboutBatches`, the creates of the last 24 hours against the cap in force for an owner's want, and
  `Token() string` on `Plan`: an opaque text of its fingerprint for "the plan the owner saw". After M8 merges
  the plan also says protected known or not known: build against today's `Protected` and leave a marked place.
- `Want(ctx, d AutoDeps, account, chat, token string, at time.Time) error`: makes the plan again; refuses in
  fixed words (sentinels) when the token no longer matches (the page shows the new plan), the plan is blocked,
  marked never, ended, the account refused or frozen, the chat a private chat, a forum, one of the app's own
  mirrors; else `AddOwnerMirrorWant`, with `d.Approve` in the same transaction when the source is not read to
  its end (the read's approval marked as the mirror's, as the automatic take writes it; **the chat's download
  switch is never changed**: the command's `-download` default). One chat per call; the page loops for a
  multi-select and shows each chat's own answer (rule 7).
- `Never(ctx, ..., account, chat)` and `Allow(ctx, ..., account, chat)`: the command's `-never` and `-allow`
  rules exactly (shared code), returning what changed in numbers. Said in the door's comment, and true in a
  test: a mark written while a request for that chat is already under way does not recall it; no request for
  the chat starts after the mark is on record (`autoCheck` reads it before every request).
- `SettleWord(ctx, ..., account, chat, word string) error`: records the owner's word (A); nothing is read or
  sent by the call.
- **The task (`auto.go`), three changes, each small and each with tests:**
  1. `Turn` goes through the wants **owner's first, then automatic, each oldest first**.
  2. An owner's want is created with `MirrorByOwner`. Its creates are bounded by the same `NewPerDay` cap,
     counted together with the automatic ones (the safe value until the owner answers: board item to come);
     make the count a parameter so that the answer is a one-line change.
  3. In `settle`: when the want is blocked with a word that waits for the owner's choice and a word of the
     owner's is on record for exactly that batch (or create), the task carries it out in its own turn by the
     command's own rules and code (the read of the mirror chat through `ReadMirror` first where the command
     reads first; then `SettleMirrorBatch` with the take, or `MirrorCreateNotMade`), removes the word and
     unblocks the want in one transaction. A word that no longer fits is removed and said, never applied.
     One request a turn, as ever.
  `Look`, `autoCheck`, the timing (`timing.go`) and the pause are not touched.

### C. The collector (`internal/collector`: a new file `mirror_door.go`; `mirror_auto.go`)
- **The task runs for an owner's wants without `-auto-mirror`.** Split `autoOn()`: the task (`Turn`) runs for
  a signed-in account whenever the forward secret is there and the account's record can be read; the look
  (`Look`), "since", the baseline and the policy for new chats stay behind `-auto-mirror` exactly as today.
  Without the switch and without a want a turn reads the wants and returns: no request, no line in the log.
  The forward secret is loaded at the start whenever its file exists (find how the `mirror` command makes it,
  and make it the same way at the first owner's want if it is absent; never print it).
- Methods on `*Collector` for the pages (they are called from HTTP goroutines; they use the collector's own
  catalogue handle; they send nothing): `MirrorPlan(ctx, account, chat) (mirror.Plan, error)`,
  `MirrorWant(ctx, account, chat, token) error`, `MirrorStates(ctx, account) ([]mirror.ChatState,
  MirrorTask, error)`, `MirrorNever`, `MirrorAllow`, `MirrorSettleWord`. `MirrorTask`: whether the task can
  run for the account now and, if not, why in fixed words (not signed in, stopped by the owner, the account
  refused, no forward secret, the record unreadable); whether the automatic mirror of joined chats is on in
  this run; the task's last numbers (`mirror.AutoNumbers`) and its next not-before time.
- After a want, a mark, an allow or a word is written, the task takes its next turn soon: use the way the
  monitor's sink already nudges it (`lookDue`), with a flag of its own. **This is the piece's one concurrent
  line (a flag set in an HTTP goroutine, read in the reader's): say so in the report; the race detector goes
  over the collector's tests that touch the door, by name, before the listing (I start that run, not you).**
- The owner's Stop of an account ends its mirror work as today; a pause of downloads leaves it going.
- The command (`mirror_cmd.go`): `-list` says who started each want (owner or auto) in fixed words. Nothing
  else of the command changes.

## Addendum 1 (11-15 23:27): what the pages track asked for on the board (its message 75), added to A, B and C
The pages track's own list of calls arrived after this brief was written. Everything above stands; added:
- **The owner's stop of one chat's mirror (rule 1: never undone but by the owner).** A new end word in the
  catalogue, `MirrorEndStopped = "stopped by the owner"` (valid for a want and a mirror row). `mirror.Stop(ctx,
  ..., account, chat)` and the collector's `MirrorStop(ctx, account, chat)`: the want (owner's or automatic)
  and its open mirror row end with that word through `EndMirror`; the mirror chat and what is in it stay;
  nothing is sent; the look never takes the chat again (an ended want is a decision, as today). **Only a new
  wish of the owner's for that chat ends the stop:** `AddOwnerMirrorWant` on a chat whose want or mirror ended
  with exactly this word clears that end in the same transaction and goes on with the same mirror row (never a
  second mirror chat); every other end word still needs the owner's allow first. `MirrorAllow` treats this end
  as it treats the others (read what it does and say it). Tests: stop during a history: no request after it;
  a look after it takes nothing; a new wish forwards only what is left into the same mirror; `-list` says it.
- **`ChatState` gains:** `StateCreating` (a mirror row begun and not created yet); `LastRequestAt int64` (the
  last request of the task for that chat on the ledger, 0: none); `Left int64` with `LeftKnown bool`: the
  messages still to forward, ONLY if one grouped statement for the whole account can give it inside the
  bound of the test at size; if it cannot, leave `LeftKnown` false in `States` and say so (the page then
  takes "N of M" from the plan of the one chat it opens).
- **The settle's word has a fourth value, `by-rules`:** the owner's yes to a settle by the rules where the
  task does not settle by itself (the blocks `AutoBlockAgain` and `AutoBlockDay`): the task then reads the
  mirror chat and settles by the command's rules; what the rules cannot tell blocks again with the word that
  waits for `arrived` or `not-arrived`. Check against the command what each block word really needs and say
  in the report which blocks no word can lift (those show `ChoiceAllow` or none).
- **The collector's methods, final names for the pages track** (all on `*Collector`, all catalogue only):
  `MirrorTask(ctx, account) (MirrorTask, error)` (apart from `MirrorStates`; its field `AutoNewSettable` is
  false in this piece: the switch is still `run -auto-mirror`); `MirrorPlan(ctx, account, chat) (mirror.Plan,
  error)` (the token is `Plan.Token()`); `MirrorWant(ctx, account, chat, token) error`; `MirrorStop(ctx,
  account, chat) error`; `MirrorStates(ctx, account) ([]mirror.ChatState, error)`; `MirrorNever(ctx, account,
  chat) error`; `MirrorAllow(ctx, account, chat) (catalog.AllowResult, error)`; `MirrorSettleWord(ctx, account,
  chat, word) error`; and four thin ones for the Settings page, each only calling the mirror package's
  existing doors through the collector's handle: `MirrorNameRule(ctx)` (the rule's lengths, whether it is the
  default, its example from the invented title, or "cannot be read"), `SetMirrorNameRule(ctx, prefix, sep)`
  (`CheckNameRule` first), `MirrorGather(ctx)` (`ReadAutoTiming`'s numbers), `SetMirrorGather(ctx, minutes)`
  (`CheckGather` first). A rule or gathering written while the task runs takes effect at its next turn (it
  reads both every turn): a test for each.

## Addendum 2 (11-15 23:58): two things from Core's message 80, and what M8 changed under you
- **Leave the lines of `autoTurn` that make the session's `Forwarder` textually as they are** (`mirror_auto.go`,
  the block `if st.fw == nil { ... telegram.NewForwarder(...) ... }`): Core moves them into a helper in its
  own piece, and whoever lists second merges. If the task running without the switch needs a change there,
  make it outside that block or stop and say.
- **A door for "the account wrote just now" (Core's clicks lengthen the mirror's pause: the mirror gives way
  to the person).** `(*catalog.Catalog).NoteAccountWrite(ctx, account, at int64) error` in your new catalogue
  file: one settings row per account (key `mirror.last_write.<account>`, Unix seconds), only ever raised
  (a write with an older time changes nothing; one statement). `MirrorLastWriteAt` returns the later of the
  ledger's newest create or forward and this note; a note that cannot be read is `ErrBadLedger` (the turn
  then sends nothing, as for its other reads: never "no write"). Nothing else changes: the task's pause and
  its random part already work from `MirrorLastWriteAt`. Tests: a note newer than the ledger's last write
  holds the next forward until the pause after the note; an older note changes no moment (compare the fake's
  requests with and without it); two notes at once keep the later; an unreadable note sends nothing. No
  schema step for it (a settings row).
- **M8 is listed READY at `wip/mirror-protected` 76df070b (it holds the main head 5a516ace).** When your parts
  are built and before your end-of-work runs: merge it in (`git fetch private wip/mirror-protected`, then
  `git -c user.name=Claude -c user.email=noreply@anthropic.com merge --no-ff FETCH_HEAD`, the message ending
  with the co-author line). Expect conflicts in `auto.go` (it changed `Look`, `autoCheck`, `autoBatch`'s
  return, the numbers), `mirror.go` (the plan gained `ListProtected`, `ListKnown`, `FirstCounted`),
  `mirror_auto.go` (the look's lines) and `mirror_cmd.go`: keep both sides' rules; then `PagePlan`, `Want` and
  `States` use the chat list's flag: a chat known to be protected is refused by `Want` in the plan's own
  words (`WhyProtectedList`), `ChatState` and the plan say known or not known, and `Stop` and the owner's
  wants keep M8's order in `autoCheck` (the mark, then left, then protected). Run M8's own tests whose names
  hold `Protected` once after the merge.

## Not in this piece
The page itself (pages); the automatic switch flipped from a page while the program runs and an account added
while it runs (the next piece: the set-up moved from the start to the task); adopting a chat; forums; the
protected refusal (M8, in another copy: `auto.go`'s `Look` and `autoCheck`, `mirror.go`'s `MakePlan`, the
command's plan lines: keep out of those lines; you merge M8's branch in when I say).

## Tests (named; each rule's test seen to fail once with its line undone, said in the report)
Catalogue: an owner's want on a chat with no mirror; on a chat with a created mirror made by the command
(kept, no second row); refused on a want, an end, a mark, an unsettled mirror row; the word's refusals; two
wants written at once both hold (rule 11); an older read-only file. Doors: the plan's token changes when a
candidate, the mirror's state or a mark changes, and `Want` then refuses; a blocked plan refuses; `States`
for each state with who started it; the statement count at size. Task (the package's rig): an owner's want
before an automatic one; an owner's want on a command-made mirror forwards only what is left, into the same
mirror chat (0 creates); a never mark between two turns: no request after it; a word `arrived` and a word
`not-arrived` carried out as the command does (compare with the command's own tests' expectations); a word
for an older batch removed and not applied; the cap counted together. Collector (the fake Telegram, the
rig's clock, `autoRig` as the model): a run WITHOUT `-auto-mirror`: no want: 0 requests of the task; a want
through `MirrorWant`: the chat read, one create, the history forwarded oldest first, albums whole, every
write at least the pause after the one before, `MirrorStates` going from wanted to complete; a chat joined
in that run is NOT taken (no look); `MirrorNever` during a history: no forward after the mark; Stop ends it.

## Running things, and the end
While working: only your tests, by name. At the end, once, one at a time: whole `internal/mirror`;
`internal/catalog -run 'Mirror|Schema'`; `internal/collector -run 'Mirror'` (about 4.5 minutes; keep the full
output in a file, never only the result lines); `cmd/tgarchive-collector`; gofmt and vet on the three
packages. No race detector from you. Report: `archiver/docs/progress/mirror-door-REPORT.md` on the branch
(per part what was built; every departure from this brief and from the exported names, first; each rule line
undone and its test; the runs with numbers; what a click sends, as a list of requests per state, for the
pages track's page to the owner; what was not checked), the branch pushed, the copy clean, the final commit
in your last message.
