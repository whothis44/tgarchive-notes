# The viewer shows the saved copy (run this BEFORE the NA5 prompt) — on the owner's Console credits

You are one Claude Code session in a terminal, billed to the owner's Anthropic Console credits. One task only. Keep it
lean: every turn costs the owner real money. Use no subagents.

## The problem (the owner, 11-22, with screenshots of their own viewer)
Almost every post in a mirrored chat (a forward of a post that is already in the archive), and in chat-group
browsing generally, shows only a dark box "Not downloaded / held back by the archiver", while the same post says
"Also posted in 1 other chat". The file was not downloaded because the archiver recognised it as a copy of a file
already saved, but the viewer only looks for the post's OWN file and never shows the saved one. The owner: "right
now it's useless, since everything is obviously mirrored from another chat".

## What to build (viewer only: `internal/viewer` Go and `internal/viewer/web`)
- When a post's media has no saved file of its own, but the catalogue knows the same media saved elsewhere, the
  viewer shows that saved file (thumbnail, full view, play) everywhere a post is drawn: the chat view, chat groups,
  the library, the post page, albums.
  - **Same Telegram file or exact evidence** (the same tg media, the same SHA-256, the exact-check link: whatever
    the catalogue already records as exact): show it as the post's own, with one small line "shown from the copy
    in another chat" (a link to that post).
  - **A held probable copy** (the look-alike hold, an edge to a saved media): show the recognised copy as a preview
    with "probably the same as the copy in another chat" and the existing Release action beside it.
  - Nothing recognised: the dark "Not downloaded" box as today.
- Read-only. Nothing is downloaded, released, held or written by this. Find the catalogue's existing doors and
  tables for these links first (`internal/catalog`: the exact links, `c_want`/hold reasons, probable edges; the
  viewer's own data layer); add a viewer door only if none fits, in the viewer's files.
- Fast: one query per page of posts, not one per post (check with a page of 50).

## Rules (binding)
- Read `CLAUDE.md` first. Privacy: never open real media, the real viewer on real media, or the owner's folders
  (`C:\Users\trabi\tgarchive-app`, `E:\T\tg-dl`); invented data in tests only; print counts, never names.
- Git: work in a new copy of your own from the main head
  (`git -C C:/Users/trabi/Claude/Projects/Telegram/repo-archiver worktree add -b wip/viewer-copies C:/Users/trabi/Claude/Projects/Telegram/wt-viewer-copies HEAD`),
  commit as `git -c user.name=Claude -c user.email=noreply@anthropic.com commit` with messages ending in
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; push only to the `private` remote.
- Go: in Git Bash, `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh; export GOMEMLIMIT=1GiB GOMAXPROCS=2 GOFLAGS=-p=2`.

## Steps
1. Read `CLAUDE.md`, `SESSION-B-PROGRESS.md` (the viewer track's newest state block), and the viewer code that
   draws "Not downloaded" and "Also posted in" (grep `internal/viewer`).
2. Build it, with tests on invented catalogues: an exact copy shown; a probable copy shown as a preview with its
   line; nothing recognised stays dark; a page of 50 posts costs one query. Then by name: the new tests, plus the
   viewer's security sets `go test ./internal/viewer -run 'TestWall|TestHomeDevice|TestLAN|Security|TestPageScripts'`.
3. Integrate as `START-INTEGRATOR.md` "Each batch" says, with this one piece: whole `internal/viewer`,
   `internal/catalog` (if you touched it) and `internal/server`, plus `./cmd/...` by path; then
   `ix-tools/merge-batch.sh`, then `bash runs-int-i6/folder-next.sh` (the second folder).
4. Notes: three lines in `SESSION-11-PROGRESS.md` under "Viewer copies on Console credits"; commit on `notes`;
   `bash ix-tools/notes-backup/backup.sh`.
5. Report to the owner in about eight lines: what it now shows, the head, test results, and the update command
   (`powershell -ExecutionPolicy Bypass -File "C:\Users\trabi\tgarchive-app-next\update-folder.ps1" -Into "C:\Users\trabi\tgarchive-app"`,
   with the app quit first).

## Part 2, right after part 1 is merged and reported (the owner asked for both, 11-22): the built-in preview
The owner, 11-22: "Regular telegram can at least see previews/thumbnails before downloading, but this one can't?"
Every Telegram photo and video message carries a tiny blurred preview INSIDE the message (the stripped thumbnail,
`photoStrippedSize`, type "i", about 100 to 300 bytes, and the document's own `thumbs` list). The reader already
receives it with every message; the app does not keep it. Keep it, and draw it, blurred, in every "Not downloaded"
box (where part 1 found no saved copy). **No new request of any kind**: only what the reader already gets. It
touches the reader (`internal/telegram`/`tgstore`, Core's), the catalogue (one schema step, after the newest; safe
to run twice; never on a file it can't read) and the viewer. Rules as part 1, plus: the catalogue's whole
`-run 'Schema|Step'` set; whole `internal/collector`, `internal/catalog`, `internal/telegram`, `internal/tgstore`,
`internal/viewer` at the merge. Posts read before this get no preview (that would need a re-read of history: a
request cost, the owner's decision; say so in the report, do not do it). Real small thumbnails fetched from Telegram
(`upload.getFile` of a thumb size) are a NEW kind of request: never built without the owner's OK and a measured cost.

## Stop and ask the owner when
- the catalogue holds no link from the post to the saved copy (then say what would have to be recorded, and stop);
- anything would download, release or write, or would need the owner's real folders.
