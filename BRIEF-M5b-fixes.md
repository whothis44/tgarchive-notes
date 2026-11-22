# Brief M5b: the review's fix round for the mirror's name piece (2026-11-15)

Copy `C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-name`, branch `wip/mirror-name`, head 02abe15, clean. Every
rule of `BRIEF-M5-mirror-name.md` holds (work only there; commit and push to `private`; named tests only while
working; one go command at a time with `GOGC=25 GOMAXPROCS=1 -p 1`; no whole run of `internal/catalog` or
`internal/collector`, no race detector, no Docker; invented data; names never in a log, an error, a printed line
or a commit message; nothing left running at the hand-back).

Read first, whole: the independent review `C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-review7-scratch\REVIEW.md`
(its probes are in that folder: do not edit it). Its verdict: nothing sends twice, nothing creates under the
default on an unreadable rule, no name leaks; one confirmed medium and one plausible medium to close, and small
ones. The architect's decisions on each, and four points of the architect's own:

## From the review
1. **Findings 1 and 2 (no two live rows of an account share a stored name).** `BeginMirrorCreate` raises the
   number while any row of the account in a state other than "not created" stores the name the rule gives
   (a loop on `rule.Name(base, ord)`; the unique index on (account, base, ordinal) still holds).
   `catalog.RenameMirror` refuses a name that another live row of the account stores (nothing written), and the
   rename's plan says so in fixed words before any request ("another mirror of the account has that name").
   No new index. Tests: the review's two probes as named tests (two rules, one name: numbers differ, each lost
   create finds only its own channel; a rename to a name a later create would take: the create takes the next
   number and `-create not-made` works), each seen to fail first.
2. **Findings 3 and 8 (what a rule and a title may hold).** Nobody has measured what Telegram does to a channel
   title (trimming, invisible characters); a name Telegram alters can never be found again by the lost-create
   look. So the checks take only what is plainly kept: in `CheckNameRule` and `CheckMirrorTitle`, besides today's
   rules: no rune of the categories Cf, Zl, Zp, and no Zs other than U+0020; no two spaces in a row; a prefix
   does not begin with a space; a separator is not only spaces; a title is not empty after trimming and has no
   leading or trailing space. One helper for both. The errors stay fixed words (say "invisible or formatting
   characters and unusual spaces" in them). Tests: the review's edge list (9 prefixes, 3 separators, 5 titles)
   all refused; ordinary ones (letters of several scripts, digits, punctuation, one emoji, a single inner space)
   taken. Say in the report: what Telegram does to a title is not measured; the first create under a rule other
   than the default, started by the owner on the test account, is that measurement.
3. **Finding 7 (an unreadable rule in the automatic task).** It must stop creates without marking each chat:
   while the stored rule cannot be read, the turn makes no create for any want and blocks no want (remove the
   per-want block and `AutoBlockNameRule` if nothing else uses it); the turn's numbers and one event say it
   (fixed words: the name rule stored for new mirrors cannot be read: no mirror is created until it is written
   anew with mirror -name-prefix and -name-sep); forwards into mirrors that exist go on; when the rule reads
   again the creates go on by themselves. Test: three wants and an unreadable rule: over several turns 0
   creates, 0 wants blocked, the event said; then the rule written anew: the creates go.
4. **Finding 4:** one test where the mirror's chat (or its Telegram id) changes between the plan and `Rename`:
   `WhyChanged`, 0 requests; it must fail with the fingerprint check undone.
5. **Finding 5:** `-never`, `-allow` and `-list` refuse `-rename` and `-to` beside them, in fixed words (as they
   refuse `-chat` and `-settle`); the same for `-name-rule`, `-name-prefix`, `-name-sep` if they can be dropped
   silently in the same way (check each pair, say what you found).
6. **Finding 6:** the schema test compares with the constant, not with the automatic mirror's number, so that
   the integrator changes one line (`mirrorNameAfter`) at the merge; the report says exactly what changes at
   the merge and that a file stepped by this branch's build (tests' temporary files only: no real catalogue was
   opened by it) must not meet the merged build.
7. **Finding 9:** a create whose name would be over `NameLimit` is not sent: checked right after the row is
   begun and before the request; the row ends "not created" with fixed words; one test.
8. The review's notes: write U+2028 and U+2029 in `cleanText` as escapes, never as the characters themselves.
   Leave part D as it is. Leave `PEER_FLOOD` on a rename as it is (consistent with a create), but the rename's
   plan says in fixed words that a refusal of the account on a rename also stops creates and forwards.

## The architect's own (found while the owner used the merged build)
9. **The plan must not print a number it did not count.** While the plan is blocked (a batch of unknown
   outcome, among others) the candidates are not counted and the plan prints "messages that may still be
   forwarded: 0 ... in this batch: 0". Print fixed words instead ("not counted while ..." with the reason's own
   words) wherever the count was skipped. `mirror.go` `planOf`, `mirror_cmd.go` `printPlan`; one test on a
   blocked plan with candidates on record.
10. **The settle's plan on a catalogue older than the build** says what the forward's plan says there ("the
    catalogue is at schema N: saying yes steps it to M; a build older than this one then refuses it"). One test
    (an older file with a batch of unknown outcome; see `TestMirrorCommandOlderCatalogueNo` for the forward's).
11. **`AutoBlockRepeat` names the wrong cause** when the batch right after a settle is refused as a repeat but
    that settle put nothing back. Say it only when the blocking batch's messages have `c_mirror_again` rows;
    else `AutoBlockAgain`. One test.
12. **Run the collector's `Mirror` set again at the end** (it was not rerun after `TestMirrorMarksOtherSchema`
    was corrected).

## End of the round (once, in this order, one at a time)
`go test ./internal/mirror -count=1`; `go test ./internal/catalog -run 'Schema|Mirror|Settle' -count=1`;
`go test ./internal/collector -run 'Mirror' -count=1`; `go test ./internal/telegram -run 'Forward|Rename' -count=1`;
`go test ./internal/collector/faketg -count=1`; `go test ./cmd/tgarchive-collector -count=1`; `gofmt -l` on the
changed files; `go vet` on the changed packages. The PC is busy: measure the CPU before each go command and wait
while it is above 85%.

## Hand-back
A section "M5b: the review's fix round" in `archiver/docs/progress/mirror-name-REPORT.md`: per point 1 to 12, what
changed and its test, how each main test was seen to fail; changed expectations of older tests; what the
integrator changes at the merge; departures; doubts; not verified. Commit as before (the Claude identity, the
`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` line), push, the copy clean. Final message, under 35
lines: the pushed head; one line per point; tests as counts and seconds with every result; departures; doubts.
