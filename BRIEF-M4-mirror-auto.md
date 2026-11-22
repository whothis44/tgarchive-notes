# Brief M4: a chat the owner joins while away is mirrored by itself (2026-11-15)

Copy: `C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-auto` (branch `wip/mirror-auto`, cut from
`wip/mirror-reads2` 99b71c3, which sits on the main branch's head 3044745). Work only there, in `archiver/`.
Commit-ready work; do not push, merge or touch another copy. **Nothing is run against Telegram**: fakes only.

## The objective, in the owner's words (11-15)
"The whole point is that if the owner joins a group, while away from their computer/our app, that the mirror
function would automatically begin, go back to the beginning of that group (i.e. before the owner joined) and
forward the media to a mirror." And: "an owner can join a group remotely (with no way to interact with our
app, which is running at home) then the app will automatically begin mirroring." Downloads for such a chat:
"an option we can enable. Perhaps off by default". Media only by default, with a toggle.
Everything built so far is a command a person starts and answers yes to. This piece is the part with nobody at
the keyboard: it runs inside the collector's `run`.

## Read first, whole
- This folder's briefs `BRIEF-M1-mirror-step1.md` (its "Rules"), `BRIEF-M2-mirror-history.md`,
  `BRIEF-M3-mirror-reads.md`, and the three reviews: `wt-mirror-review-scratch/REVIEW.md`,
  `wt-mirror-review2-scratch/REVIEW.md`, `wt-mirror-review3-scratch/REVIEW.md` (the last one's answer to "the
  architect's question" lists what in `mirror.ReadThenRun` only holds for a console command: every point of it
  is a requirement here).
- The code: `internal/mirror` (all), `internal/collector/mirror_cmd.go`, `internal/collector/reader.go` (the
  reader task: one loop of turns on the account's connection: the chat list, gaps, then the best-ranked chat
  to read), `account.go` (`runSession`, how the reader, the monitor and the engine are started and stopped, how
  the account's counters and `Forwarder`-like objects get the main invoker), `monitor.go`, `collector.go`
  (`Config` and its defaults), `command.go` (`run`'s flags), `internal/tgstore/store.go` (`SaveChats`,
  `ChatChanged`), `internal/catalog/tgchats.go` (`SaveChatFacts`: when `account_chat.joined_at` is written).
- `archiver/docs/TRIED-BEFORE.md` sections 24 and 25 (the 13 rules for anything that acts for the owner) and
  `C:\Users\trabi\Claude\Projects\Telegram\LESSONS-ix12.30-live.md` section 6b (what happened when the old app
  added 30 chats by itself: the owner switched off 24). These bind this piece.

## What the old app knows about this (the architect read it)
- Its 12.30 compared the chats the account can see with the archived ones every half hour, at most 10 actions
  a round; 86 chat counts were answered in under 2 minutes with no refusal. So a chat list every 30 minutes is
  inside what it did.
- Its independent reviews found, after every test had passed: a paused rescan restarted; chats the owner had
  taken out added back; 81 of 150 "never" marks lost to two clicks at once (one stored list); a busy flag stuck
  after a panic. Hence the 13 rules.
- It never forwarded: there is no number for forwards per hour or chats created per day (a community figure,
  unverified: about 50 chats a day).

## The integrator's conditions (board message 9; they are not negotiable)
In `account.go` and `reader.go` only what the new task needs: no change to the reader's or the monitor's own
behaviour, none to the engine or the download path. One request at a time on the one connection, every wait
slept in full. The 13 rules. Nothing downloaded from a chat the owner did not choose. An independent review and
the race detector on `internal/collector` follow before it is merged.

## What to build
### 1. The switch
`run -auto-mirror` (default off: one named constant, to be flipped after the first real runs). Off: none of
the code below sends, reads or writes anything, and `run` behaves byte for byte as today (a test). On, at its
first start for an account: the time is stored as that account's "automatic mirroring since" (never moved
later, also when the flag goes off and on again). With it: `-auto-mirror-download` (default off: the chat's
files are also queued), `-auto-mirror-all-messages` (default off: media only), `-auto-mirror-new-per-day N`
(default 5; 1 to 50: new mirrors created in any 24 hours), and the pause and per-hour values of the command
(`-auto-mirror-pause`, `-auto-mirror-per-hour`, same defaults, same stored pause for the account).

### 2. Schema step 18 (`internal/catalog/schema_mirrorauto.go`; the number is taken on the board; carry it as
the step after the head you were cut from, the number in two named constants, as `schema_lookalike.go` does)
- **One row per (account, chat) for the owner's mark:** "never mirror", with its time. Read before every
  request of the task; a row that cannot be read is an error (fail closed), never "no mark".
- **Who started a mirror** on the ledger's mirror row: the owner's command, or the automatic task; and for a
  mirror that ended for good, why ("the owner removed the mirror chat", "the owner left the source", "never
  marked", "protected", "account refused").
- **The mark follows a chat across a change of identity** (rule 12): a basic group that became a supergroup
  (the catalogue's migration link): a "never" on the old one holds for the new one, and a mirror of the old one
  is the new one's (no second mirror). Test it.
- No change to the hold tables, the ladder, `staging.go`, `settle.go`.

### 3. Noticing a newly joined chat (the task's "look" step; `internal/mirror`, called from the reader's loop)
- With the switch on, the chat list is due every 30 minutes instead of `ChatListEvery` (the smallest change in
  `reader.go` that does it: the interval becomes a value the session reads; with the switch off it is exactly
  today's). The monitor already stores a chat an update names; the look step runs after every stored chat list
  and when the monitor stored a new chat (a nudge), and never sends a request itself.
- **A chat is "newly joined" when all hold:** the account is a member; the chat is a basic group, a supergroup
  or a channel (not a private chat, not a bot; a forum is noted as "forums are not mirrored yet" and left); its
  membership began after the account's "automatic mirroring since" time, judged from the catalogue's own
  record (`account_chat.joined_at`; read how and when it is written; if a chat can appear with no join time,
  it is NOT newly joined: fail closed, counted, said once in the log); it is not one of the app's own mirrors;
  it has no "never" mark (through the migration link too); it has no mirror row of any state for this account
  (a mirror that ended for good is a decision: rule 2); the account's forwarder is not refused for good.
- For each such chat, in one transaction: the mirror row "wanted, started by the automatic task"; the download
  switch by the rule of the last fix round (only a chat nothing knows is switched off; with
  `-auto-mirror-download` it is left as the catalogue makes it); the read's approval, marked as the mirror's
  (see 6). **The monitor may already have saved messages of that chat before the look step ran** (the review's
  point): the look step must not assume "before any message is saved". For a chat with messages already on
  record and no owner's approval, its files already catalogued must not have been queued by the mirror: check
  what state such files are in (read `ladder.go` `attach` for a chat nobody approved: are they wanted?), write
  what you find in the report, and if they are wanted, stop and say so rather than inventing a repair.
- A cap: at most 10 chats taken per look (rule 10); the rest at the next.

### 4. The read needs no new reading code
The reader's own loop reads an approved chat pass by pass, with its watchdog, backoff and gap handling. The
mirror's approval makes it read the newly joined chat. Do not call `ReadChat` from the mirror task (the reader
is one call at a time and owned by the reader task). The mirror turn (5) simply waits until the chat is read to
its end with no open gap (the plan already says so).

### 5. The mirror turn, in the reader's loop
One new step in `readTurn`, after gaps and before the history pass: **at most one writing request per turn for
the whole account** (the create of one mirror, or one batch of one mirror), then the turn ends and the loop
goes on (other chats' reads and the owner's requests are never held behind a run of batches).
- Which mirror: the automatic mirrors whose source is read to its end (or, once created and caught up, has new
  candidates), oldest wanted first; a mirror blocked by an unknown outcome, a refusal or a protected source is
  skipped (and said once).
- **Not-before times, never a sleep inside the loop:** the pause since the account's last forward, the hourly
  bound, a wait Telegram stated on create or forward (the wait record), the new-mirrors-per-day cap: each gives
  a time before which the turn does nothing for that request; the loop's idle wakes at the earliest of them.
  A wait Telegram states DURING the turn's own request is slept by the forwarder as today if it is under 60
  seconds (the reader is held that long: say it in the log); longer: recorded, the turn ends, the not-before
  time holds it. Never a request inside a stated wait.
- Use the existing functions of `internal/mirror` for the plan, the intent rows, the outcomes and the ledger
  (a new entry point "one turn" beside `Run`; do not copy `Run`). `help.getConfig` once per session of the
  account (kept in memory), not per turn. The forwarder is made once per session on the account's main invoker
  and counters, with the forward secret as the command reads it.
- **Keeping current:** new media of a mirrored chat arrives through the monitor and is catalogued; it is a
  candidate at the next turn. A message newer than 90 seconds on the clock is not forwarded yet (an album
  still arriving must never be split; its parts arrive as separate updates): test with an album arriving in
  two halves 30 seconds apart.
- **The plan comparisons** (`fingerprint`, `ledgerPrint`) assume a quiet catalogue: in the live run the
  catalogue changes between plan and act. The turn makes its plan and acts within the reader task's own turn;
  what may change underneath (new messages catalogued by the monitor) must not end the turn as "changed": show
  by a test with the monitor's sink adding messages during a turn.
- A reconnect or a stop in the middle of a forward leaves the batch "outcome unknown" as today, and that
  mirror blocked. That is right for now (settling an unknown is a later piece); it must be said once in the log
  with the catalogue's chat number, and counted in the status file's numbers if that is a small change; no
  retry loop.
- Errors that are the account's (signed out, the method frozen, the account refused for good) end the task for
  the session as the reader's own do; never taken for "the forward failed, try again".

### 6. Who gave the approval
The approval the automatic task writes must be tellable from the owner's, in the record the collector itself
reads. The last fix round found the collector's writers drop an unknown field and its `ReadApproval` struct
needs one: add the field there (the one change to that struct), written by the mirror task and the mirror
command ("by": whose), kept by `ApproveRead` when the owner later approves (it then becomes the owner's), and
shown by the `chats` command as a fixed word ("approved (by the mirror)"). A chat approved only by the mirror
is NOT "chosen for download": its switch stays as the look step set it.

### 7. The owner's marks, until a page exists (`mirror_cmd.go`)
`mirror -never N` (the chat is never mirrored by itself; a mirror under way stops before its next request;
nothing is deleted at Telegram), `mirror -allow N` (removes the mark), `mirror -list` (every mirror and mark of
the account: catalogue chat numbers, state, who started it, counts; **no names**). They take the catalogue's
lock only if `run` is not holding it: read how `chats` reads beside a running collector; a mark written while
`run` runs must be seen by the task before its next request (it reads the row each turn: rule 3). If a write
beside the running collector is not possible with the catalogue's locking as it is, say so and make the marks
work with the collector stopped, said plainly in the usage.
- **A removal is a decision (rule 2):** if a forward or the chat list shows the mirror chat is gone for this
  account (deleted, left: the catalogue's access record, or Telegram's CHANNEL_PRIVATE / CHANNEL_INVALID on the
  forward), or the source was left, the mirror row ends for good with that reason and nothing recreates it.
  The owner undoes it with `mirror -allow N` plus the command.

### 8. Everything it adds is the app's and looks like it (lesson 6b)
Every automatic mirror is named by the rule in use ("X-<source>-n"), marked in the catalogue as the app's own
with its source, switched off for downloads, and listed by `mirror -list` and in the collector's heartbeat and
status file as numbers (mirrors wanted, being read, forwarding, caught up, blocked, ended; forwards this hour;
new mirrors today). Log lines: constant formats, catalogue chat numbers only.

### 9. Concurrency
The task runs inside the reader task's goroutine: no new goroutine. What it shares with other goroutines (the
monitor's nudge, counters, the session's fields) uses the existing patterns; any flag is released with
`defer`. One lock or one row for every writer of a mark (rule 11): two `-never` at once must both hold (test
with two writers).

## Tests (named, invented data, the fake clock; in `internal/mirror`, `internal/catalog`, `internal/collector`)
1. Switch off: `run` with the fake sends exactly what it sends today (compare the fake's request log with and
   without this code path compiled in use), and writes none of the new rows.
2. The whole story on the fake: the account runs; a chat is joined (the fake's chat list gains it; its history
   has 250 messages older than the join, 180 with media, two albums); within the look interval the chat is
   read by the reader, a mirror created, the media forwarded oldest first in batches with the pause between,
   albums whole; the chat's files are not wanted; then 3 new media messages arrive through the monitor and are
   forwarded after the 90 seconds; counts: 1 create, the forwards, no request inside a wait or sooner than the
   pause. Nobody "answered yes" anywhere.
3. Chats there before the switch was first on: never mirrored. A chat with no join time: not mirrored, counted.
4. A "never" mark set before the look; set after the mirror was wanted; set between two batches: no request
   for that chat after the mark in each case.
5. The marks cannot be read (a corrupt row): the task sends nothing for the account and says so; `run` goes on.
6. Two marks written at once both hold.
7. A basic group marked "never" becomes a supergroup: not mirrored. A mirrored basic group becomes a
   supergroup: no second mirror.
8. The mirror chat removed by the owner (the forward answers CHANNEL_PRIVATE): ended for good, never recreated,
   also after a restart.
9. The source left by the owner: ended, nothing more sent.
10. The cap: 12 chats joined at once with `-auto-mirror-new-per-day 5`: 5 creates in the first 24 hours of the
    fake clock, the rest after; the look takes at most 10 a time.
11. A wait on the create, on a forward (short and over 60 seconds), across a restart of the session: nothing
    sent before its end; the pause doubled and stored as the command does.
12. An unknown outcome on a forward (the connection lost mid-request): that mirror blocked and said once; other
    mirrors go on; no retry.
13. The owner's own approved chat being read at the same time: its pages still advance (the mirror turn sends
    at most one request a turn): count the reader's pages between two mirror requests.
14. The monitor adds messages during a turn: the turn does not end as "changed".
15. An album arriving in two halves 30 seconds apart: forwarded whole.
16. The owner's `-approve-read` of a chat the mirror approved: it becomes the owner's; the mirror goes on.
17. `-auto-mirror-download`: the joined chat's files are wanted; without it: none.
18. Privacy: marker words in titles appear in no log line, status file or `mirror -list` line.
For tests 2, 4, 8, 11 and 13 say in the report how you saw each fail with its rule removed (through
`go test -overlay` from a scratch folder of your own; the working copy not edited for it).

Run only named tests while working: `go test ./internal/mirror -count=1`;
`go test ./internal/catalog -run 'Schema13|Mirror' -count=1` (and your new schema step's tests by name);
`go test ./internal/collector -run 'Mirror' -count=1`; `go test ./internal/collector/faketg -count=1`;
`go test ./cmd/tgarchive-collector -count=1`; `gofmt -l` and `go vet` on what you touched. No whole-package
run of `internal/catalog` or `internal/collector`, no race detector, no Docker (the architect runs those once,
after the review's fixes). One go command at a time, each with `GOGC=25 GOMAXPROCS=2 -p 1`. Tests judge on the
injected clock only: no assertion on real seconds (the last piece had a test that failed 3 runs in 6 that way).

## Rules
As the earlier briefs: work only in your copy; invented data; never a real catalogue, session file, API
settings file, `E:\T\tg-dl` or media; constant format strings; no title, username, Telegram id or access hash
in any line; no new dependency. **Not edited:** `internal/telegram` (if the task cannot be built without a
change there, stop and say exactly what is missing), `internal/engine`, `internal/supply`, `internal/exact`,
`internal/lookalike`, `internal/viewer`, `internal/bringin`, `internal/server`, the catalogue's hold tables and
ladder. In `internal/collector`: `reader.go` and `account.go` only what the task needs (list every changed line
of those two files in the report with its reason), `collector.go` (config fields), `command.go` (flags),
`mirror_cmd.go`, `chats_cmd.go`/`approve_cmd.go` (the fixed word for a mirror's approval), the heartbeat and
status file (numbers), `words.go`, the fake.
If a requirement cannot be met as written, choose the reading that sends fewer requests, never repeats a
write, and never acts on a chat the owner marked; do it; list the departure. This piece is large: commit your
work in progress on `wip/mirror-auto` as you go (each commit builds and its named tests pass), so nothing is
lost if you are cut off; say in each commit message what is done and what is not.
Commits with `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, messages ending
`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, no archive numbers. Report:
`archiver/docs/progress/mirror-auto-REPORT.md` in the last commit: what was built, file by file; every changed
line of `reader.go` and `account.go` with its reason; each of the 18 tests with its name and time; how tests 2,
4, 8, 11 and 13 were seen to fail; **every piece of concurrent code added or changed**; what you found about a
chat's files catalogued before the look step (3); departures; doubts; what is not verified. Final message to
the architect: the commit hashes, tests as counts and seconds, concurrent code, departures, doubts, what is
not done, under 40 lines.
