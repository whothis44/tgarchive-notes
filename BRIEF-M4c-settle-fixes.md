# Brief M4c: the settle's fix round (2026-11-15)

Copy: `C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-auto` (branch `wip/mirror-auto`, at d5a4a7c). Work only
there, in `archiver/`. One commit on top (work in progress commits allowed). Do not push, merge or touch another
copy. Nothing is run against Telegram. The rules of `BRIEF-M4-mirror-auto.md` and `BRIEF-M4b-fixes-and-settle.md`
hold word for word (what may be edited, named tests only, one go command at a time with
`GOGC=25 GOMAXPROCS=2 -p 1`, no whole-package run of `internal/catalog` or `internal/collector`, no race
detector, no Docker, the injected clock only, `internal/telegram` not edited).

Read first, whole: the review `C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-review5-scratch\REVIEW.md` (its
probes P1 to P5 are in that folder: each becomes a test). Its part A table says the earlier sixteen fixes hold;
this round is about the settle. **The settle decides whether a message is forwarded again. A wrong "not
arrived" puts a second copy in the owner's mirror; a wrong "arrived" leaves a hole. When the evidence is not
exact, it must say so and stop.**

## The settle's rules, rewritten (replace what `internal/catalog/mirrorsettle.go` does)
1. **Which read counts** (findings 2 and 3). Drop "the newest stored message's date" and the cursor's time. A
   settle counts only a read of the mirror chat that (a) the settle itself began at a clock time later than the
   batch's request (the later of its sent and ended times) plus the margin of 60 s, and (b) ended cleanly having
   reached what was already stored (the reader's pass finished). The caller (the automatic turn, the command)
   notes the clock before it calls the reader and hands that start time and the pass's outcome to the settle;
   the catalogue function refuses a start time that is not later than the need time, and refuses without a
   finished pass. `ReadChat` resumes an unfinished pass and ignores `Newer` then (review, 2b): so first the
   mirror chat's read must be done (finish it, over as many turns as it takes, without settling), and only a
   further `Newer` pass begun after the need time counts. The command waits on the clock until the need time
   before that read (said in its plan: "the settle's read starts at <local time>"); the automatic turn's
   not-before time does the same. Persist nothing new for this unless a restart needs it (after a restart the
   settle simply reads again).
2. **Which mirror messages can be a batch's copies** (finding 4). Only non-service messages of the mirror chat
   whose id is above the newest mirror message id the ledger knew before the batch's request (the largest
   `new_msg` of forward rows of earlier batches of that mirror; 0 when none) and that are forwards. A copy made
   by an earlier batch, or anything older, is never matched. Mirror messages in that range that are not
   forwards (the owner posted or pinned something) are ignored and counted.
3. **The key of a message** (finding 1). For a source message and for a mirror message alike:
   - if its own forward origin on record names one post (the catalogue's `namesPost` rule): that origin;
   - else, for a SOURCE message of a broadcast channel with no forward origin of its own: "<the source's
     marked id>:<its message id>" (what Telegram writes on its copy); for a MIRROR message with no sound origin:
     no origin key;
   - the media key: the sorted set of its media rows (kind and Telegram id), when it has any.
   A source message that is itself a forward has its ORIGINAL origin on its copy, never the source's.
4. **Telling one message** of the batch, against the eligible mirror messages of rule 2:
   - its origin key exists, no other message of the batch has the same origin key, and exactly one eligible
     mirror message has it: arrived (that one). None has it: not arrived. Two or more have it: arrived, counted
     as "twice" (the lowest id is its copy), reported;
   - no origin key (a bare or hidden sender, or a non-channel source), a media key that no other message of the
     batch has, and exactly one eligible mirror message has that media key and no origin key that contradicts:
     arrived. None: not arrived. More than one: cannot tell;
   - everything else (the same origin key or media key on two messages of the batch; no key at all, as a plain
     text under `-all-messages` from a sender with no post number): **cannot tell**.
   Every eligible mirror forward must end up tied to exactly one message of the batch or be counted as
   "a forward in the mirror the batch does not explain" (then: cannot tell for the whole batch). Never by
   text, date or position.
5. **All or nothing, as today:** one message that cannot be told leaves the whole batch as it is, in fixed
   words with the counts (told arrived, told not arrived, cannot tell).
6. **A batch "already"** (Telegram said it has these forwards) that settles with fewer arrived than its
   messages is a contradiction: it is not turned into candidates; the mirror is blocked for the owner with
   fixed words ("Telegram says it was forwarded; the mirror does not show it").
7. **No loop** (finding 1's 178 requests): after a settle, if the next batch of that mirror is refused as a
   repeat, or ends unknown again, a second time in a row, the mirror is blocked for the owner (not settled
   again by itself); a settle read happens at most once per need time; count settles per mirror per day in the
   numbers and stop at 3 by itself.
8. **The owner's word, when the rules cannot tell** (finding 5): `mirror -settle N -take arrived` and
   `-take not-arrived`: after the same read, the messages the rules could tell are settled by the rules, and
   only the ones they could not are taken as the owner says; the plan shows the three counts and what each
   choice risks in fixed words ("taken as arrived: any that did not arrive will be missing from the mirror" /
   "taken as not arrived: any that did arrive will be in the mirror twice"), then yes. Recorded on the batch
   with "by the owner's word". And for a create left "unknown" with no channel adopted from the chat list:
   `mirror -settle N -create not-made` (the owner says no such channel exists: the row ends not created and a
   later run may create), after the stored chat list was looked at and shows none (said); never offered when a
   channel of that name is on record.
9. **Small ones:** the mirror chat itself is left out of "chats made switched off by the automatic mirror" and
   out of the `-approve-read` hint (finding 6); the settle's read leaves an owner's estimate or answer on the
   mirror chat alone and says the settle waits (finding 7).
10. **The fake's lock** (the race run that follows this round): `World.ChatOf` and every other read of
    `W.Chats` and a chat's accounts take `W.mu` (read the review's list of unlocked callers and its lock order
    note: `s.mu` then `W.mu`); look for the same pattern in every test helper this piece added.

## Tests (named; invented data; the injected clock)
Each of the review's probes P1 to P5 as a test that fails before the fix (say how you saw it); and:
- the real case again (a channel with no reposts: 64 of 99 arrive; settled 64 / 35);
- a channel with reposts: messages forwarded from another channel's post, from a bare sender, from a hidden
  sender, the same other post twice in one batch; all arrived: nothing is "not arrived"; the twice-in-batch
  pair cannot be told and the batch stays blocked; with `-take arrived` it settles and nothing is sent again;
- a supergroup source and a basic-group source by media; an album; a message with two media;
- a read that began before the need time, and a stored message dated after it with no read: not settled;
- a mirror message older than the batch with the same media as a later source message: not matched;
- an "already" batch the mirror does not show: blocked, nothing made a candidate;
- the loop: at most the allowed settles, then blocked; count the forwards and reads over 3 hours of the clock;
- `-create not-made`;
- the fake's readers under its lock (no test needed beyond the race run; say what you changed).

Run: `go test ./internal/mirror -count=1`; `go test ./internal/catalog -run 'Schema13|Mirror|TopicSchemaStep' -count=1`
and your named tests; `go test ./internal/collector -run 'Mirror' -count=1`;
`go test ./internal/collector/faketg -count=1`; `go test ./cmd/tgarchive-collector -count=1`; `gofmt -l`, `go vet`.

## Report
A section "The settle's fix round" in `archiver/docs/progress/mirror-auto-REPORT.md`: each rule with its file
and tests and how each probe was seen to fail before; what stays "cannot tell" by design; every changed line of
`reader.go` and `account.go` since d5a4a7c (none expected); every piece of concurrent code added or changed;
departures; doubts. Commit with `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, message
ending `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, no archive numbers. Final message to the
architect: the commit hash, tests as counts and seconds, concurrent code, departures, doubts, under 35 lines.
