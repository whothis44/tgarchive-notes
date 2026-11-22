# Brief M3b: move "the mirror reads the chat itself" onto the new head, and its review's fixes (2026-11-15)

Nothing is run against Telegram. The rules of `BRIEF-M3-mirror-reads.md` and of `BRIEF-M1-mirror-step1.md`
("Rules") hold: invented data, the fake clock, named tests only, one go command at a time with
`GOGC=25 GOMAXPROCS=2 -p 1`, no whole-package run of `internal/catalog` or `internal/collector`, no race
detector, no Docker, `internal/telegram` not edited, no schema step, no goroutine in `internal/mirror`.

## Step 0: onto the new head
The integrator merged the two earlier mirror pieces into the main branch as one squashed commit (6b8f72f), and
other tracks' work after it (schema steps 14, 15, 16; the main branch's head is 3044745). `wip/mirror-reads`
(e5eef11) was cut from the old `wip/mirror-history` 9f09e86, which is not an ancestor of the main branch.
- The copy for this round already exists: `C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-reads2`, branch
  `wip/mirror-reads2`, cut from the main branch's head 3044745. Work only there, in `archiver/`.
- First: `git cherry-pick e5eef11` there (the one commit of this piece). Resolve conflicts by taking the main
  branch's version of everything this piece did not change and this piece's changes on top; if the squash
  differs from 9f09e86 in a file this piece touches (compare `git diff 9f09e86 6b8f72f -- archiver/internal/mirror
  archiver/internal/collector/mirror_cmd.go archiver/internal/catalog/schema13.go archiver/internal/catalog/mirrorpace.go`),
  keep the main branch's side of those differences. Then run the tests below once before changing anything
  else, and say in the report what the pick needed.
- Do not touch `wt-mirror-reads` (the old copy) or any other copy. Do not push or merge.

## Step 1: the fixes
The review: `C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-review3-scratch\REVIEW.md` (read it whole; its
probes P1 to P3 may be the start of your tests). The numbers are its finding numbers. Each fix gets a named test
that fails without it; say how you saw it fail (the fix undone through `go test -overlay`).

1. **The download switch is touched only for a chat nobody chose and nothing knows** (findings 1 and 2,
   confirmed). A chat's switch covers every account, and a brought-in chat can be switched on with no cursor
   and no approval. So the read switches a chat off only when ALL of these hold: no message of the chat is on
   record; no account has a cursor on it; no account has an approval for it. In every other case the switch is
   left exactly as it is, and the plan says in fixed words which case it is and what the switch is now ("this
   chat is already known to the catalogue: its download switch is left as it is: on" / "... off"). Never block
   the mirror for it. Tests: the review's P1 (two accounts) and P2 (a brought-in chat switched on), and the
   existing never-seen chat.
2. **An open gap means "not read to its end"** (finding 3, confirmed): a chat with an open gap on record is not
   forwarded from; the plan says so in fixed words; the command's read does not fill gaps (the collector's
   reader does): it says "run the collector to fill it". Messages older than the newest one already forwarded
   that turn up later ARE still forwarded (completeness before order); the run counts them and says how many
   went out of order. Test both.
3. **A frozen history method** (finding 4): the plan refuses the read while the collector's record says the
   history method is frozen for the account (read how `methodFrozen` reads it; read-only use of that setting),
   and an `ErrMethodFrozen` from the read ends the run with fixed words of its own, not "the read failed". Do
   not write the collector's frozen record from the command unless you can call the collector's own function
   for it without editing its files; if you cannot, say so.
4. **True words about the switch** (findings 5 and 6): no line promises a Chats page that does not exist; the
   lines say what is true: the chat's actual switch as the catalogue has it now, and that switching it on later
   collects only files catalogued after that (so say plainly: "to download this chat's files, run the mirror
   command with -download before its first read"). Print the chat's real switch in the plan and at the end.
5. **The untested rule gets a test** (finding 7, plant D): a chat with a cursor and no approval counts as known
   (its switch untouched). And **`TestMirrorReadsWait` must not be flaky**: it failed 3 of 6 runs in the review
   (it expects exactly 10 s slept and sometimes sees 9): find why (the fake clock against real time), and make
   the test judge on the injected clock only. Run it 20 times (`-count=20`) and report the result. Look for the
   same pattern in the other new tests of this piece.
6. **For the next piece (do not build, only prepare):** the approval the mirror writes must be tellable from an
   owner's. If the approval record can carry a field that says who gave it without editing the collector's
   `reader.go` (it is JSON: an unknown field may or may not survive the collector's own rewrite of it: check by
   reading and say what you found), write it; if not, report that it needs a change in `reader.go`.

## Tests to run (after step 0, and after step 1)
`go test ./internal/mirror -count=1`; `go test ./internal/collector -run 'Mirror' -count=1`;
`go test ./internal/catalog -run 'Schema13|Mirror' -count=1`; `go test ./internal/collector/faketg -count=1`;
`go test ./cmd/tgarchive-collector -count=1`; `gofmt -l` and `go vet` on what you touched.

## Report
`archiver/docs/progress/mirror-reads-REPORT.md` gains a section "Onto the new head, and the fix round": what
the pick needed; each fix with its file and test and how the test was seen to fail first; the 20 runs of the
wait test; what you found for point 6; whether any concurrent code was added or changed; departures; doubts.
Commit (the pick as its own commit, the fixes as a second) with
`git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, messages ending
`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, no archive numbers. Final message to the architect:
the two commit hashes, tests as counts and seconds, the wait test's 20 runs, point 6, concurrent code,
departures, doubts, under 30 lines.
