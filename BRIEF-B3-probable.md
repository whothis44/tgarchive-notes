# Brief B3-10: probable copies under one tile, and "same / not the same" remembered for good (session B3, 11-15)

You are an Opus coder. Copy and branch: given in the prompt that started you (cut from `private/wip/b-viewer`).
Go module: `archiver/`. Go: `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh` in each
Bash call. Package: `archiver/internal/viewer` only (Go and `web/`). Commit after each part and push your
branch to `private` (`git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, ending with
`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; no archive numbers).

## What is asked (FEATURES sections 7 and 9: listed, so already asked for)
"Probable copies grouped under one tile with '+n probable', best copy as the face; review page with same /
not the same, remembered for good" (the owner agreed 11-11: grouped by default; a switch shows them apart, as
a chip). Both sources agree on: never fold across kinds, verdicts kept for good, nothing deleted.

## What the record says (read by the main session: TRIED-BEFORE 6 and 17, COPY-CHECKS-STUDY E, FEATURES 3)
- **Exact means the same Telegram file, the same SHA-256, or every part hash. Nothing else.** A probable
  copy is a look-alike (same length, shape and preview) or a sampled-frame match: the old app's frame checks
  confirmed 10 to 25 % of unheld candidates and 66 % of already held ones, and its whole-album rule was right
  67 to 89 % of the time. So probable links are often wrong, which is why the owner's verdict matters.
- The owner (11-09): 20 and more suspected copies listed one by one was a complaint: fold them into one
  closed line; a copy shown must link to its post.
- **The viewer only shows and records.** It writes nothing but its own `decisions.sqlite`; it never releases,
  holds, skips or downloads anything. What the collector does with a verdict is the copies session's work.

## What the code has (read first)
`appear.go` (`group`: exact links followed to 64 files, probable one step, a file with more than 20 probable
links pulls in none; `decideFirst`), `library.go` (`buildListing`, one build per listing, the listing
identity, chips if merged), `overlap.go` (a table kept per index version: the pattern to copy), `copies.go`
(the probable-copies page), `post.go` (the copies lines with evidence), `decisions.go` and `marks.go` (marks
by stable key, resolved per index version; **nothing in `decisions.sqlite` may be keyed by a catalogue row
number**).

## Part 1: verdicts
- A verdict is about a pair of files: `same` or `different`, with the time. Keyed by the two files' stable
  identities, smaller first: Telegram's own file identity as the catalogue stores it in `tg_media` (not the
  row id; find the columns the bring-in and the collector both fill), so it survives a fresh bring-in. A new
  table in `decisions.sqlite`; resolved to the current index's files once per index version with the marks;
  a verdict whose files are not in the catalogue is kept and counted (About).
- `POST /api/verdict` (the token, JSON, same origin, like `handleHide`): two media ids and `same`,
  `different` or `none` (takes it back). It bumps the decisions version so listings refresh.
- Effect, in the viewer only: `different` removes that pair's probable link from every grouping (`group()`,
  the overlap table, first appearance, the fold below, the copies page's default list); `same` keeps the
  pair together even when probable copies are shown apart, and is drawn "= by your word" (never called
  exact, never written to the catalogue). An exact link cannot be given a verdict.
- The pair's evidence (the catalogue's own words for the link, the two files' size, length, shape, where each
  is posted and saved) is shown where the verdict is given.

## Part 2: the review page
The existing probable-copies page becomes the review page: pairs not judged yet first, each as two tiles side
by side with the evidence line, three buttons (Same, Not the same, Skip) and the keyboard (S, N, right
arrow); 30 a page with a stable cursor; tabs "To review (N)", "Same (N)", "Not the same (N)"; a file with
more than 20 probable links is listed once as "looks like N others" with its pairs folded (the owner's
complaint about 20 and more copies listed). Both tiles link to their posts.

## Part 3: folding in the library
- Worked out once per index version and decisions version, kept like the overlap table (requests wait for one
  run): within each group, the **face** is the best file: saved before not saved, then more pixels, then
  more bytes, then the earliest first place; decided in that order so a file is folded only behind a shown
  file of its own group (the same shape as `decideFirst`, never a chain). Never across kinds (a photo is not
  folded behind a video).
- In the library, on by default: a folded file gives no tile of its own; its face's tile carries "+n
  probable" (a badge that counts as one of the tile's two) and opens the post page with the folded files in
  the strip, each marked "≈" with its evidence and the verdict buttons. In one-tile-per-post mode a tile is
  dropped only when every file of it is folded; otherwise its folded files are left out of its count.
- A switch "Probable copies apart" (`prob=apart`, in the sidebar's Copies group and as a chip if chips are
  merged); `first=1` keeps its own rule (`sameprob`). The fold is in the listing's key through the decisions
  version; a listing only looks up a kept flag per file (no group walk per listing).
- Say the build time of the kept fold in `/api/stats`.

## Tests (named, while working)
Verdicts survive a renumbered catalogue (as `marks_test.go`); `different` splits a group everywhere it is
used; `same` holds with `prob=apart`; the face order; no fold across kinds; the chain t~x~y (y the face of
x; t shown); a hub of 25; the review page's order, cursor and tabs; one build of the fold for parallel
requests. Then once at the end: `go test ./internal/viewer -p 1` (about 3 minutes, in the background),
`gofmt -l`, `go vet ./internal/viewer`, `node --check` on the scripts. No race detector, no mutation checks,
one go command at a time. The import wall (`TestWallImports`) lists what the package may import.

## One count on the real catalogue (allowed, strictly bounded)
Once, at the end: a throwaway Go test **kept out of the commit** that opens
`C:\Users\trabi\AppData\Local\Packages\Claude_pzs8sxrjxfjjc\LocalCache\Local\tgarchive-b\old-archive-2\catalog.sqlite`
read-only, builds the index, and prints **only counts and milliseconds**: the fold's build time, files folded,
faces with folded files, the largest fold, pairs to review, and the unfiltered listing's entries and build
time with the fold on and apart, in both tile modes. Never start the server on it; never touch a library or
media file; print no id, title, text or path.

## Rules
- Never open the viewer on real data, any real file or the owner's real `decisions.sqlite`; nothing against
  Telegram; do not touch `repo-archiver`, other `wt-*` folders or other packages. Do not merge into or push
  `claude/charming-feynman-vm2xia` or `wip/b-viewer`.
- CSS in one block at the end of `web/app.css`.
- Concurrent code: say exactly what requests share and how it is guarded.

## Hand back (short)
Commits, differences from this brief and why, named tests, whole-package time and result, the real
catalogue's counts and milliseconds, what is shared and how it is guarded, the exact key a verdict is stored
under (for the copies session), doubts.
