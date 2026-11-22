# Brief U2: "in the old archive" or "new", shown by the viewer (viewer session B9, 11-21)

You are an Opus coder for the viewer track of a private Go project (a Telegram archiver). Work ONLY in the copy
`C:\Users\trabi\Claude\Projects\Telegram\wt-b-oldnew` (branch `wip/b-oldnew`, cut from `wip/b-onelist` dad8caa1,
which holds the app's one list). The Go module is in `archiver/`. Commit as you go with
`git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, each message ending with the line
`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, and push: `git push private wip/b-oldnew` (never
another branch, never `main`, no tag, no merge into another branch).

## Rules (binding)
- Invented data only. Never open the owner's real folder, catalogue, viewer or media, `E:\T\tg-dl` or
  `%LOCALAPPDATA%\tgarchive*`. Print counts, sizes and timings only.
- Every `go` command through the track's lock, one at a time (two reviewers share it: wait your turn):
  `bash /c/Users/trabi/Claude/Projects/Telegram/runs-b7/shell/scripts/gorun.sh <dir> go test ./internal/viewer -run 'Name' -count=1`.
  Named tests only. Never the whole `internal/viewer`, no race detector, no `go vet` over many packages.
- Edit only `internal/viewer` (Go, `web/`). Not `internal/catalog`, `internal/appshell`, `internal/bringin`,
  `internal/window` or anything else. Do not open a window on the screen.
- Text with a Windows path goes into files through the Write/Edit tools, never through a shell string.

## Read first, yourself
`C:\Users\trabi\Claude\Projects\Telegram\DESIGN-UNIFIED-ARCHIVE.md`, sections 0, 4 and 5 (the viewer's part);
`repo-archiver/archiver/docs/LESSONS.md` section 1 (the viewer: a warm index updated in place, nothing
proportional to the archive per click or per update); in `internal/viewer`: how the index is loaded and kept
by the catalogue's change log (`refresh.go`, `media.go`), how copy edges are loaded and shown (grep
`copy_edge`, `exact`, `probable`, `related`), the library's filters (`library.go`: `first=1`, `only=1`,
`deleted=1`), a post's facts (`post.go`), a tile's marks (`web/js/library.js`), and `/api/meta`.

## The goal
One archive: the old app's archive is (later) brought into the app's catalogue as an account of its own. A file
whose bytes the old app holds has a place in `file_copy` whose `source` is the old app's (read how
`internal/catalog/bringin.go` `ImportSaved` writes it: the exact column and value). The viewer shows, for every
media, whether the old archive has it, from what it already loads plus ONE bit per file:
- **in the old archive:** its own file is such a file, or an EXACT edge leads to a media whose file is;
- **probably in the old archive:** a PROBABLE edge to such a media (and no exact one);
- **partly in the old archive:** a RELATED (partly the same footage) edge to such a media;
- **new:** none of these. Its words say which layers ran, so "new" never claims more than was checked
  (section 4 of the note: "no file of the old archive has its Telegram id, bytes, post or look"; for a video
  of 20 MB or more, add whether frames were compared or not yet, if the viewer can know it cheaply; if not,
  leave that clause out and say so).
- **"seen by the old app, never saved":** a media the old account reaches whose file is not saved by it: say
  how you tell it from what the viewer loads (accounts, reach), or leave it out and say so.
None of this shows when the catalogue holds no old-app file at all (the app's archive before any bring-in):
then nothing changes on any page.

## What to build
1. **The bit:** read once with the index which files have an old-app place, and keep it right through the
   change log (a place added or removed by a later bring-in run). No read per click, nothing that walks the
   archive per update. Measure the load's added time and memory on an invented catalogue of the old archive's
   shape at a size you can make in under a minute (say 200,000 media), and give the numbers.
2. **The word per media, as DATA:** the owner said on 11-21 "remember the interface, since the whole app will
   need a rework for UI". So the word is a field of the viewer's JSON (a fixed key, e.g. `old: "in" | "probably"
   | "partly" | "new"`, plus `old_checked` naming the layers that ran), in the tiles' answer and the post's
   answer; the page only draws it. A small mark on a tile (only for "new" and "probably": the others stay
   quiet), and one line in a post's facts.
3. **A filter "new since the old archive":** `/?old=new` (and `old=in|probably|partly` for symmetry), beside
   "first seen here"; in the library's filter column under its own heading; combinable with the other filters.
   Its count beside the list's entry: give `lib:oldnew` through the viewer's `Options.Counts` in
   `shellmount.go` (the list's door; a count not ready is left out), and add the entry itself ONLY if the
   appshell package already has a way for the viewer to add an entry; it does not: so instead name in your
   hand-back the one line pages must add to appshell's Library group (key `lib:oldnew`, title "New since the
   old archive", href `/?old=new`, shown only when the catalogue holds an old-app file). Do not edit appshell.
4. **The counts for the owner (section 4 of the note):** per account and per chat, a new account's media as in
   the old archive + probably + partly + new = its media, each once; as JSON at `/api/oldnew` (this PC's class
   like the other reads), cheap (from the index), so that pages' Overview can read it later. No page of its own
   needed in this piece beyond the filter.
5. **Tests** (by name), on invented catalogues made as the viewer's tests make them, with old-app places
   written as `ImportSaved` writes them (call the catalogue's door if a test can; else the same rows): each
   word, the filter, the counts adding up, the bit kept through the change log (a place added after the index
   loaded), nothing shown when no old-app file exists, and the cost numbers of point 1.

## Hand-back (your final message; short; numbers, no real data)
Commits (hash, subject), pushed; what each part does and where; tests by name with result and seconds; the
load's cost numbers; the line pages must add to appshell; what you left out and why; anything in the note or
this brief the code says is wrong. Stop at the first thing not as written here and say it.
