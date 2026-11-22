# Old or new: the viewer's data for the UI to draw (B9's U2, `wip/b-oldnew` bdf14c7b; sent to U-1 11-21 night)

Listed after W1v. Zero change in `internal/viewer/web`: the drawing is the UI track's (F4, the library).
1. Per file, on tiles (`/api/library/shape` .first.tiles[], `/api/library/tiles` .tiles[]: the tile's cover) and on files
   (`/api/post/{id}` .files[] and its stand_in, conversation files, `/api/copies/most`):
   `old`: "in" | "probably" | "partly" | "new"; `old_checked`: only with "new": ["id","bytes"] when saved, ["id"] when not
   (the layers that found nothing; "new" never claims same-post, look-alike or frames); `old_seen`: true only when the
   old app saw the file and never saved it (never with "in"). ALL omitted when the catalogue holds no old-app file.
2. `/api/meta`: `old_archive` true|false, always present.
3. Library query `old=`: comma list of new, probably, partly, in; unknown words ignored; ignored while old_archive is false.
4. `GET /api/oldnew`: always {gen, old_archive}; with old files also old_files, checked, total {media, in, probably, partly,
   new, seen_not_saved}, accounts[] {id, label, old_app, ...counts}, chats[] {id, title, ...counts}, took_ms. Per bucket
   in+probably+partly+new = media; seen_not_saved is a subset of probably+partly+new, not a fifth term.
5. The list: Counts key `lib:oldnew` = total.new, only while old files exist. appshell's Library line:
   `link(Entry{Key: "lib:oldnew", Title: "New since the old archive"}, Viewer, "/?old=new")`, drawn only when Counts has
   that key. The count counts files; `/?old=new` lists tiles.
Words (copies, `DESIGN-UNIFIED-ARCHIVE.md` §4): in the old archive / probably in the old archive / partly / new; "seen by
the old app, never saved".
