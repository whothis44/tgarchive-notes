# Brief D1: the Overview's library counts and the mirrors made in 24 hours (pages, P7, 2026-11-22)

You are the coder: Opus 5.5 at high effort, one piece start to finish; hand back a branch ready to list.

## The house rules (binding)
`C:\Users\trabi\Claude\Projects\Telegram\BRIEF-P7-review-rules.md` (privacy, safety, every go command through
`runs-pages-p6/go1.sh`, named tests). `TEMP`, `TMP`, `LOCALAPPDATA`, `APPDATA` of test processes in
`C:\Users\trabi\AppData\Local\Temp\p7-d1\` (outside any git copy). Invented data only. Commits with
`git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, ending `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`;
push `git push private HEAD:wip/pages-libcounts` only. **The front end (`internal/server/web`, `internal/appshell`)
is the UI track's (U-1): do not edit it; this piece is Go only** (the answer's fields and their tests).

## Where
`git -C repo-archiver fetch private && git -C repo-archiver worktree add -b wip/pages-libcounts ../wt-pages-libcounts private/wip/pages-overview`
(W3, b50584b0, listed). Report: `archiver/docs/progress/pages-libcounts-REPORT.md`.

## What to build
1. **`GET /api/overview` gains `library`: `{"new7": n, "deleted": n, "first": n}`, each field ABSENT when not
   known.** Read on the server's side from the VIEWER's counts, as `DESIGN-ONE-WINDOW-HOW.md` section 3 says
   (read it): the pages know the viewer's address (`Config.ViewerURL`, the one `shellOptions` uses); ask the
   viewer's `GET /api/shell` and take its entries' `count` by key (`lib:new` to new7, `lib:deleted` to deleted,
   `lib:first` to first; today only `lib:deleted` is filled by the viewer; take what is there). Only a
   `http://127.0.0.1:PORT` address (refuse anything else); a bound of 200 ms per ask; the answer kept for 10 s
   (one ask at a time, the others take the kept one); the viewer not answering, slow, or answering badly: the
   fields absent, the rest of the Overview unchanged, one constant-format log line per kind of failure (not
   per ask). Read how the viewer's gate answers a server-side request without a browser's headers (the
   viewer's `/api/shell` guard: `internal/viewer`, read only): if it refuses such a request, stop at a written
   door for the viewer track in your report instead of going round its guard. Never read the library.
2. **`mirrors_made_24h`:** per account, the new mirrors made in the last 24 hours against the cap in force, as
   the mirror package counts them (`internal/mirror` `createsRoom`, `MirrorCreatesSince`, the cap's door the
   Settings row uses): `[{"account": id, "made": n, "cap": n}]`, absent without the program or when the door
   fails; through the seam the pages already have (`Mirrors`); measure it.
3. **Tests:** the reader against a stand-in viewer (`httptest`): each key present and absent; slow (over the
   bound); a 500; garbage; a non-loopback address refused; the kept answer (one ask in 10 s for many Overview
   asks); the Overview's other fields unchanged when the viewer is away. `mirrors_made_24h` with the fake seam.
   gofmt, vet, the named tests, and the Overview's existing named tests (`TestOverview*`).

## Hand back
Branch pushed, copy clean; the report (the exact JSON shape for U-1, the bound and the keeping, what the
viewer must add for new7 and first). Final message: head (8 characters), report path, one line not verified.
