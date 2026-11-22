# Brief M3: the mirror reads the chat itself, and forwards its media (2026-11-15)

Copy: `C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-reads` (branch `wip/mirror-reads`, cut from
`wip/mirror-history` 9f09e86). Work only there, in `archiver/`. Commit-ready work; do not push, merge or touch
another copy. **Nothing is run against Telegram**: the fakes only.

Read first: `BRIEF-M1-mirror-step1.md` (its "Rules" hold word for word), `BRIEF-M2-mirror-history.md`,
`C:\Users\trabi\Claude\Projects\Telegram\DESIGN-MIRROR-STEP1.md` (above all its last section, "Corrected, 11-15"),
the code this builds on (`internal/mirror`, `internal/collector/mirror_cmd.go`, `internal/catalog/schema13.go`,
`mirrorpace.go`), both reviews (`wt-mirror-review-scratch/REVIEW.md`, `wt-mirror-review2-scratch/REVIEW.md`), and
the reader you will call and must not change: `internal/telegram/reader.go` (`EstimateChat`, `ReadChat`,
`ReadOptions`, `PassResult`, its errors) and how the collector uses it (`internal/collector/reader.go`:
`EstimateRead`, `ApproveRead`, the read loop, how the account's `Reader` is made in `account.go`).

## Why (the owner, 11-15)
The command today forwards only messages already in the catalogue, which a chat gets only when the owner
approved its read in the collector. The owner: "This seems like an error? The whole point is that if the owner
joins a group, while away from their computer/our app, that the mirror function would automatically begin, go
back to the beginning of that group (i.e. before the owner joined) and forward the media to a mirror."
So the mirror must read a chat itself. This piece makes the command do it; the automatic start in the running
collector is the next piece and is prepared here only as far as said in point 5.

## What is already known
- Reading is cheap: about one request per 100 messages, no download (TRIED-BEFORE 26; LESSONS-ix12.30-live 1).
  The old app read 81,303 messages of 6 channels with no refusal. Waits on reads are slept in full; the new
  app's reader does that already and stores them.
- The owner decided (FEATURES 12 round 12, 11-13): a signed-in account reads every chat it can see, by default,
  messages only, the request cost shown before it starts. And (round 14, 11-14): a newly joined chat is
  mirrored automatically (no bytes); **its files are downloaded only when the owner chooses the chat**.
- The lesson that binds this (LESSONS-ix12.30-live 6b): never download from a source the owner did not choose.
  Reading a chat catalogues its messages, and a chat that collects queues its files. So a chat read for a
  mirror must be switched off for downloads BEFORE its first message is catalogued, unless the owner had
  already chosen it.
- Where a group hides its earlier history from new members, Telegram returns nothing from before the join:
  the read simply ends there. Nothing to build; say it in the usage text.

## What to build
1. **The plan for a chat that is not read to its end** (no cursor, or a cursor not done): instead of "no
   candidates", it shows that the chat must be read first and that the cost is asked after the yes... no:
   **the cost is shown before the yes.** So the command's order becomes: the plan from the catalogue (nothing
   sent); if the chat is not read to its end, one question "type yes to ask Telegram for this chat's size (one
   request)"; then `EstimateChat` (one counted request, after the lock, the VPN gate and the dial as today);
   then the full cost: messages Telegram counts, about R read requests, and for the forwards "at most about B
   batches if every message carried media: the real number is known after the read"; then the second yes,
   which covers the read and the forwards of this run (`-batches` as today). A chat already read to its end:
   one yes, as today.
2. **The read** (in the command, through `telegram.Reader` made as the collector makes it, unchanged):
   `ReadChat` with `Approved` true (the owner's yes at this console is the approval; record it where the
   collector records an approval, so that `chats` shows the chat as approved and a later `run` goes on reading
   it rather than starting anew: read how `ApproveRead` records it and do the same), repeated until the pass
   says the chat is read to its end or something ends it: a wait over the command's bound (ends the command,
   on record, says when), a refusal of the chat (recorded by the reader; the mirror step does not start), a
   stop (clean: the cursor is stored, a later run goes on from it), the reader's own errors. Progress lines
   (pages, messages, requests, waits and their seconds) in fixed words. All of the reader's counts are printed
   at the end per method beside the forwarder's, and go to the hourly tables.
   **Before the first read request, if the chat has no approval and no cursor on record (the owner never chose
   it): the chat is switched off for downloads** (`catalog.SetChatCollect(chat, false)`), in the same
   transaction or strictly before any message is saved, and the plan says so in fixed words ("this chat is not
   chosen for download: its messages are read, its files are not downloaded; switch it on from the Chats page
   when wanted"). A chat that already has an approval or a cursor keeps its switch as it is. Test both.
3. **A partial read still mirrors.** If the read ends early (a stop, a long wait), nothing is forwarded in that
   run: forwarding starts only from a chat read to its end, so that "oldest first" is true. Say so in the end
   words. (A reader's pass goes from the newest message backwards; do not forward a chat whose beginning is
   not in the catalogue.)
4. **Media only, by default.** The candidates are messages that carry at least one attachment in the catalogue
   (and, as today, are not deleted, not self-destructing, not service messages); an album stays whole (all its
   messages carry media). `-all-messages` forwards messages without media too. The candidates query must still
   use an index and never scan `message` (show its plan on 300,000 invented messages of which one in three has
   an attachment). The plan's counts say both numbers (messages on record; with media). **This changes the
   default of the existing command**: say so in the report; update the tests that relied on text messages
   being candidates.
5. **Prepared for the automatic piece, not built:** put the sequence "read to the end, then run the batches"
   behind one exported function of `internal/mirror` that takes the reader as a small interface (two calls:
   estimate, read one pass) beside the forwarder, so that the collector's live run can call the same function
   later. No detection of newly joined chats, no background task, no goroutine in this piece.
6. Nothing else of the command changes: the lock, the gate, the ledger, the pause, the hourly bound, the
   outcomes. `internal/telegram` is not edited (not `reader.go`, not `forward.go`, not `call.go`). No schema step.

## Tests (named, invented data, the fake clock)
1. A chat never read, 450 messages of which 300 carry media (some in albums), `-batches all`: the fake saw 1
   estimate, the history pages, 1 config, 1 create, 3 forwards of media messages only; the chat's row is
   switched off for downloads and **no file of it is wanted** in the catalogue after the read; the approval is
   on record; a second run sends nothing but says all is forwarded.
2. A chat with an approval and a cursor not done: read on from the cursor, its download switch untouched.
3. Not yes at the first question: 0 requests. Not yes at the second: exactly 1 request (the estimate), nothing
   read, nothing switched.
4. A stop during the read: the cursor kept, nothing forwarded, the next run reads on and then forwards.
5. A wait on a history page: slept in full, counted with its seconds, the read goes on; a wait over the bound
   ends the command with the time on record.
6. The chat refuses the account during the read: recorded, no mirror created, a later run sends nothing for it.
7. A chat read to its end already: one yes, no estimate, no history request (today's behaviour).
8. `-all-messages`: text messages forwarded too.
9. An album whose messages all carry media straddling a batch boundary: never split.
10. Privacy: the marker-word test extended to the read's lines.
11. The candidates query's plan on 300,000 messages: no scan of `message`.
For tests 1 (the download switch), 3 and 4 say in the report how you saw each fail with its rule removed
(through `go test -overlay`, the working copy not edited for it).

Run only: `go test ./internal/mirror -count=1`; `go test ./internal/collector -run 'Mirror' -count=1`;
`go test ./internal/catalog -run 'Schema13|Mirror' -count=1`; `go test ./internal/collector/faketg -count=1`;
`go test ./cmd/tgarchive-collector -count=1`; `gofmt -l` and `go vet` on what you touched. No whole-package run
of `internal/catalog` or `internal/collector`, no race detector, no Docker. One go command at a time, each with
`GOGC=25 GOMAXPROCS=2 -p 1`.

## Rules
As the earlier briefs: work only in your copy; invented data; constant format strings; no title, username,
Telegram id or access hash in any line; no new dependency; the forbidden packages untouched
(`internal/viewer`, `internal/bringin`, `internal/engine`, `internal/lookalike`, `internal/exact`,
`internal/supply`, the catalogue's hold tables and ladder); in `internal/collector` only `mirror_cmd.go`, its
tests, `words.go` and the fake. If the reader cannot be used from the command without editing
`internal/telegram` or the collector's own reader files, stop and say exactly what is missing.
Commit with `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, the message ending
`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, no archive numbers. Report:
`archiver/docs/progress/mirror-reads-REPORT.md` in the commit (what was built, each test with its time, how
tests 1, 3 and 4 were seen to fail, **whether any concurrent code was added or changed**, departures, doubts,
what is not verified). Final message to the architect: the commit hash, tests as counts and seconds,
concurrent code, departures, doubts, under 30 lines.
