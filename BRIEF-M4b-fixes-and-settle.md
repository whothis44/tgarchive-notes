# Brief M4b: the automatic mirror's fix round, and settling an unknown outcome (2026-11-15)

Copy: `C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-auto` (branch `wip/mirror-auto`, at 186d76d). Work only
there, in `archiver/`. Do not push, merge or touch another copy. Nothing is run against Telegram. The rules of
`BRIEF-M4-mirror-auto.md` hold word for word (what may be edited, named tests only, one go command at a time
with `GOGC=25 GOMAXPROCS=2 -p 1`, no whole-package run of `internal/catalog` or `internal/collector`, no race
detector, no Docker, tests judge on the injected clock only, `internal/telegram` not edited).

Read first, whole: the review `C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-review4-scratch\REVIEW.md` (its
probes and plants are in that folder and may be the start of your tests); and
`C:\Users\trabi\Claude\Projects\Telegram\SESSION-MIRROR-PROGRESS.md` sections 8, 9 and 10: **the command has now
run for real on the test account**, and what happened there is the reason for part B.

Two commits: part A (the review's fixes), then part B (settling). Each fix gets a named test that fails without
it; say in the report how you saw it fail (the fix undone through `go test -overlay`, the working copy not
edited for it). Commit work in progress as you go.

## What the real runs showed (11-15, one account, one day: "looks like")
- A create is answered in about 0.3 s, a batch of 100 forwards in about 2.3 to 2.8 s. 100 of 100 forwarded each
  time; every forward's answer tied back to its source by the random id.
- Three batches of 100 within about five minutes (two of them 13 s apart, at the 10 s pause): the next request
  was told to wait 9 s. The wait was slept in full, the pause doubled and stored, the batch sent once more, and
  Telegram answered **`WORKER_BUSY_TOO_LONG_RETRY`** (an error of its own server) after 4.1 s.
- Reading the mirror chat afterwards: the request told to wait had forwarded nothing; **the request that got the
  server error had forwarded 64 of its 99 messages** (almost a prefix; 6 of its 7 albums whole, 1 not at all,
  none split); no message twice. So "outcome unknown" was right, sending the batch again would have been wrong,
  and **the mirror chat itself says what arrived: each forward there names its source post.**
- The mirror is blocked now, and nothing can unblock it. With nobody at the keyboard that would be for good.

## Part A: the review's findings (its numbers), all to be fixed unless said
1. **A refused create is never sent again by itself.** `CHANNELS_TOO_MUCH`, any definite refusal, a frozen
   method: the want is blocked with its reason (shown by `-list`, cleared only by the owner's `-allow`), and
   **every create the task begins counts against the per-day cap** whatever its end. Test: the review's probe
   (328 creates in an hour of the clock) now sends 1.
2. **A refused or unsent batch blocks that mirror** (as "already" and "unknown" do), with its reason; nothing
   loops. An "unsent" for want of an access hash: blocked, said. Cleared by `-allow` or by part B where it
   applies. Test: `MEDIA_EMPTY`, `CHAT_WRITE_FORBIDDEN`, no access hash: one request each, then none.
3. **A basic group the owner was in before the baseline, seen migrated only through the chat list, is not
   "newly joined":** follow the group's `migrated_to` link as well as the supergroup's `migrated_from`.
4. **An error on a forward never ends a mirror "for good" as removed by the owner.** `CHANNEL_PRIVATE`,
   `CHANNEL_INVALID`, `FROZEN_PARTICIPANT_MISSING`, `PEER_ID_INVALID`: the mirror is blocked with the error's
   type. "The owner removed the mirror chat" is decided only from the mirror chat's own access record in the
   catalogue (the chat list says the account left it or it is gone); "the owner left the source" likewise from
   the source's record. And `-allow` on a blocked mirror never leads to a second mirror chat while the first
   may exist: it unblocks the same mirror row.
5. **The policy never switches off a chat for an account that has no policy.** A chat row of a shared kind
   (channel, supergroup) is made switched off only when every signed-in account of the catalogue has the
   policy; say in the report how "signed-in account" is read there.
6. **The policy covers only what the automatic mirror is for, starts at the baseline, and is visible.** Only
   chat rows of kind group, supergroup or channel are made switched off (not private chats, bots, forums); the
   policy is set when the baseline is taken (the first chat list stored whole after the switch was first on),
   not at the start, so the chats of that first list are made as they always were; each chat made switched off
   under the policy is counted in the heartbeat, the status file and `mirror -list` ("made switched off by the
   automatic mirror": catalogue numbers only), and the usage text says how to switch one on (`-approve-read`,
   which also starts its read: say that).
7. **A protected source** (learnt only after the read and a create, an empty mirror left): NOT fixed in this
   round (the chat list's flag is read in `internal/telegram`, which is not ours to edit). Do this much: the
   mirror row keeps its chat and the reason "protected"; nothing is created for that source again; `-list`
   shows it; the report says what a fix needs (the flag stored by the chat list's facts).
8. **`mirror -never`, `-allow`, `-list` never step a catalogue silently and never print a bare SQL error.**
   Read the file's schema first (read-only). Older than this build: `-list` says in fixed words "the catalogue
   is at schema N, this build reads M: nothing is listed; start run once with this build, or use -never/-allow
   which step it after a yes"; `-never` and `-allow` say the same and ask for yes at the console before the
   read-write open that steps it. Newer than this build: fixed words, nothing done.
9. **Topic lists keep their own interval:** the 30-minute chat list must not ask every approved forum's topic
   list each time; topics are asked as often as before the switch (the config's interval). With the switch off
   nothing changes. Say in the report what a 30-minute list costs in requests for 100 and for 2,000 chats, read
   from the reader's paging.
10. **Tests that can fail:** a test for the guard against downloading from a chat nobody chose (plant p4); for
    the migration check (p7); `TestMirrorAutoSwitchOff` must compare with a fixed expectation written down from
    the code before this piece (the exact list of request kinds and counts the fake sees in the story with the
    switch off, and the chat-list interval), not with itself (plant c1: a 30-minute list with the switch off
    must fail it); the "one request a turn" assertion must be able to fail (plant: two requests in one turn).
11. **The task's forwarder never holds the reader for minutes on `help.getConfig`:** at most 2 retries and a
    bound of 30 seconds for it in the task (the command keeps its own); a failure ends the turn and is tried
    at a later one, counted.
12. **The look never overwrites a record the owner is in the middle of:** a chat that has an estimate or an
    approval on record that is not the mirror's is left alone by the look (its want is made, its read waits
    for the owner's own answer or the next look); the owner's yes never fails because of the task.
13. **A create whose answer was lost is found, not taken for a new chat** (the look-before-create the old app
    had): when a mirror row is "creating" or "create unknown" and a channel appears in the account's chat list
    that was made after that row's intent time and whose title is exactly the row's intended name, that
    channel is adopted as the mirror (the row becomes created with it; marked the app's own; switched off; its
    access hash from the list) in one transaction; never taken as a newly joined source. Two channels of that
    name: none is adopted; blocked; said. The command's plan does the same from the stored chat list (no
    request). Test: a lost create answer, then the list.
14. **One mirror's catalogue error does not stop the account's other mirrors** (it is passed over, counted,
    said once); the automatic turn counts forwards that went out of order as the command does.
15. For the integrator, not code: say in the report what happens if this branch's build steps a real catalogue
    to 18 before another track's 17 is merged, and what the merge must do with the two constants.
16. **The start of the pause is 20 s, not 10** (the constant; the command and the task): the real runs met a
    wait at 10 s on the third batch. The stored pause still only lengthens. Update the words that name it.

## Part B: settling an unknown outcome from the mirror itself
A batch left "sending" or "outcome unknown" (and a forward refused as a repeat, "already") blocks its mirror.
It is settled from what the mirror chat holds, never by sending the batch again.
1. **The evidence, exact only:** a message of the mirror chat on record that is a forward naming the source
   chat's post number (the catalogue's forward origin that names one post, as the viewer's and the catalogue's
   "sound origin" rule: read `record.go` `forwardOrigin` and `catalog/ladder.go`'s predicate) is that source
   message, arrived. Where a source's forwards carry no post number (a basic group, a private chat): the same
   Telegram media (the catalogue's media row: the same kind and Telegram id) carried by exactly one source
   message of the batch and exactly one mirror message not yet tied to any source message is that message;
   anything that cannot be told this way stays unknown. Never by text, date or position.
2. **When it may settle:** only when the mirror chat is on record up to a moment after the batch's request (its
   newest stored message, or the time its read last reached the top, is later than the batch's sent time plus a
   margin of 60 seconds on the clock; read what the catalogue keeps about a read's top). Until then: not
   settled.
3. **What settling does, in one transaction:** every source message of the batch found in the mirror becomes
   forwarded with its mirror message id; every one not found becomes a candidate again (its forward row
   removed, as a "waited" batch does); the batch ends "settled" with the two counts; the mirror is unblocked;
   a source message found twice in the mirror is counted and reported ("n messages are in the mirror twice"),
   nothing is deleted. A batch "already" is settled the same way. The ledger's CHECK on the batch state: if
   "settled" cannot be a new state without rebuilding the table, record it as done with a reason and the
   counts (say which you did).
4. **Getting the mirror chat on record:**
   - **The automatic task:** a blocked mirror gets a settle turn: one `ReadChat` of the mirror chat for what is
     newer than what is stored (the reader's `Newer` option; the task runs inside the reader's own goroutine
     and its `pass`, so the reader is not called twice at once: use the reader the turn is given; this is the
     one place the task calls it). At most one such call a turn, counted as the reader's requests; its waits
     as the reader's. The mirror chat is the app's own: its read needs no owner's approval; mark the approval
     as the mirror's. It stays switched off for downloads (a forward keeps Telegram's file id: check that
     reading the mirror queues no file: the mirror's chat row is switched off since its creation; test that 0
     files are wanted from it).
   - **The command:** a plan that finds the mirror blocked by an unknown says so and offers the settle: "type
     yes to read the mirror chat (about k requests) and settle"; then it reads and settles; with `-batches` it
     then goes on forwarding in the same run after the pause. `mirror -settle N` does only the settle.
5. **After a settle the candidates are forwarded in source order again;** messages older than the newest one
   already forwarded go out and are counted as out of order (as today).
6. **The real case as a test, with invented data shaped like it:** three batches done; the fourth told to wait
   9 s; sent again; the fake carries out 64 of its 99 (6 of 7 albums whole, one album none) and answers a
   server error; the mirror is blocked; the settle reads the mirror; 64 forwarded with their mirror ids, 35
   candidates again; unblocked; the next batch is those 35 and what follows; nothing is in the mirror twice at
   the end; albums whole. And: a settle attempted before the mirror is on record past the request: not
   settled, still blocked; a source with no post numbers settled by media; an ambiguous one left unknown; a
   message found twice reported.

## Tests to run
`go test ./internal/mirror -count=1`; `go test ./internal/catalog -run 'Schema13|Mirror|TopicSchemaStep' -count=1`
and your schema step's tests by name; `go test ./internal/collector -run 'Mirror' -count=1`;
`go test ./internal/collector/faketg -count=1`; `go test ./cmd/tgarchive-collector -count=1`; `gofmt -l` and
`go vet` on what you touched.

## Report
`archiver/docs/progress/mirror-auto-REPORT.md` gains two sections, "Fix round" and "Settling": each fix with its
file and test and how the test was seen to fail first; for A9 the request costs; for A15 the merge note; for B
which evidence rules were built and which cases stay unknown; every changed line of `reader.go` and `account.go`
since 186d76d with its reason; **every piece of concurrent code added or changed**; departures; doubts; what is
not verified. Commits with `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, messages ending
`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, no archive numbers. Final message to the architect:
the commit hashes, tests as counts and seconds, concurrent code, departures, doubts, what is not done, under 40
lines.
