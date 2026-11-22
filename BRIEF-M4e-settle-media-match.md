# Brief M4e: the settle's media match, one small fix (2026-11-15)

Copy `C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-auto`, branch `wip/mirror-auto`, head e067045, clean. Every
rule of `BRIEF-M4d-settle-fixes-2.md` holds (work only there; commit and push to `private`; named tests only; one go
command at a time with `GOGC=25 GOMAXPROCS=1 -p 1`; no whole run of `internal/catalog` or `internal/collector`, no
race detector, no Docker; invented data; counts only in what you write). The local Go toolchain gained one line
today, so the first go command compiles everything once: let it.

## What the reviewer's second pass found (finding 5, medium, confirmed; older than the last round)
`wt-mirror-review6-scratch/REVIEW.md`, section "Second pass (e067045)", finding 5; its probe is
`TestProbeS3_EditedRepostTakesAnother` in `zz_m6b_test.go` there. A supergroup; message 9 once carried message 8's
media and was edited to its own after its copy was made (the copy holds 8's media; the source keeps 8's row on 9
as replaced); 8 was never carried. The settle records 8 as forwarded with 9's copy (a hole for good) and puts 9
back (a second copy). Cause: `mirrorsettle.go` `weighBatch`, the media pass: a match counts when
`mediaN[x.media] == 1` on the main keys only; another batch message's replaced or alternative row is not seen.

## The fix (only `internal/catalog/mirrorsettle.go` and tests)
1. **A media match counts only when the copy can be nobody else's.** In the media pass, the one candidate `m` is
   `x`'s copy only if, besides today's conditions, no OTHER message of the batch has any row (every row:
   replaced, alternative and live video included) among `m`'s rows (every row), and no message of an earlier
   batch that the answer did not name ("missing") has any such row (the per-row form of `missMedia`; keep the
   key test too). Otherwise `x` cannot be told, and `m` is tied as the batch's, as the `default` branch does today.
2. **"Not arrived" needs that no copy could be its own.** A batch message told "not arrived" becomes "cannot
   tell" when any eligible mirror message with no post-naming origin that is not a found copy (not a value of
   `w.found`) shares any media row (every row, either side) with it. Why: in the case above 9 has no candidate by
   its key, and the copy is tied (so it is not "unexplained"); without this, the owner's `-take` for 8 would let
   the rules put 9 back: a second copy told by the rules. Only origin-less mirror messages are looked at: a
   channel's batch whose copies all name their posts must still settle "found 64, again 35" (the real case's test
   must pass unchanged).
3. The file's head comment says both rules in its rule 4 paragraph.

Expected for the probe's case: nothing settled, cannot tell 2 (messages 8 and 9), nothing written; with
`-take arrived` both end "missing"; with `-take not-arrived` both are put back.

## Tests (named)
- The probe S3 as a named test in `internal/mirror` (the same scenario; assert cannot tell exactly 2, both rows
  unwritten, and the two owner's words), seen to FAIL on e067045 first (say how).
- A mirror of the case with an alternative row instead of a replaced one (another batch message holds the
  candidate's media as an alternative): cannot tell.
- An earlier "missing" message holding the candidate's media as a replaced row: cannot tell.
- The existing settle tests still pass: `go test ./internal/mirror -run 'TestMirrorSettle|TestMirrorAutoSettle' -count=1`
  and `go test ./internal/catalog -run 'Mirror|Settle' -count=1`; then `gofmt -l` on the changed files and `go vet`
  on the two packages. If an older test's expectation changes, say which and why (none expected: the six
  media-key cases and the 64 of 99 case must come out as before).
- Undo each of the two rules once and name the test that catches it.

## Hand-back
A short section "M4e: the media match" appended to `archiver/docs/progress/mirror-auto-REPORT.md`. Commit as before
(`git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, the message ending
`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`), push to `private`, the copy clean. Final message, under
20 lines: the pushed head; what changed; tests as counts and seconds; any changed expectation; doubts.
