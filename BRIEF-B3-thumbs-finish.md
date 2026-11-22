# Brief B3-1: finish "thumbnails made only when a page asks" (session B3, 11-15)

You are an Opus coder. Work only in the copy `C:\Users\trabi\Claude\Projects\Telegram\wt-b-viewer` (branch
`wip/b-thumbs`, head 255e82c, clean tree). Go module: `archiver/`. Go: `source
/c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh` in each Bash call.

## What exists
An earlier coder built the piece and committed it as work in progress (255e82c: `-thumb-ahead=false`, an
asked-only maker, the `X-Thumb` header made / pending / none, the page's swap-in in `web/js/dom.js`
(`whenThumb`), stats, the "hide not saved" choice in the server's prefs). Its named tests passed. It stopped
before: the whole package once, vet, hand back. The main session has read `maker.go`, `media.go`, `viewer.go`,
`stats.go` and found nothing to change. The scripts (`dom.js`, `item.js`, `library.js`, `chat.js`,
`copies.js`, `about.js`) have not been read by anyone but their author.

## What to do, in this order
1. `git merge private/claude/charming-feynman-vm2xia` (4f1992e: the main branch's head; it already holds
   c4bb582, so expect no conflict in `internal/viewer`). Do not fetch or push that branch.
2. Read the page side once against these three rules (from the old app's 12.32 review), and fix only what
   breaks one of them:
   - a tile or picture never re-asks without end: a bounded number of tries, spaced out, and it stops on
     `X-Thumb: none` and on `made`;
   - a stand-in is never kept by the browser under the real thumbnail's address (`no-store`), and the real
     one is swapped in only when the server says `made`;
   - re-asks must not fill the browser's about 6 connections: no more than 2 re-ask requests in flight at
     once across the page (if `whenThumb` has no such bound, add one), and tiles scrolled off the screen stop
     asking.
3. `go test ./internal/viewer -p 1` once (about 3 minutes; run it in the background and wait for it), and
   `go test ./cmd/tgarchive -run Viewer` if that package has viewer tests. Fix what fails. Then `gofmt -l`
   on the files you touched and `go vet ./internal/viewer ./cmd/tgarchive`.
4. Commit (`git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, the message ending with
   `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; no archive numbers in it) and
   `git push private wip/b-thumbs`.

## Rules
- Only `archiver/internal/viewer` and `archiver/cmd/tgarchive/viewer.go`. Nothing else, no schema step.
- No other test runs than those named; no race detector; no mutation checks. One go command at a time.
- Never open the viewer on real data, never start it against the real catalogue or a real library, never
  open a real file. Nothing against Telegram. Do not touch `repo-archiver` or any other `wt-*` folder.
- Do not merge into or push `claude/charming-feynman-vm2xia`.

## Hand back (short)
The commit, what the page-side read found and changed, the test time and result, anything you doubt.
