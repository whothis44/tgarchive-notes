# Brief V1: version information and a manifest in the app's Windows programs (viewer session B9 for the archived pages track, 11-22)

You are an Opus coder. Work ONLY in `C:\Users\trabi\Claude\Projects\Telegram\wt-b-versioninfo` (branch `wip/b-versioninfo`,
from main a0de4f1); module in `archiver/`. Commit with `git -c user.name=Claude -c user.email=noreply@anthropic.com
commit`, messages ending `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; push only `git push private
wip/b-versioninfo`. Go only through `bash /c/Users/trabi/Claude/Projects/Telegram/runs-b7/shell/scripts/gorun.sh <dir> go ...`
with ABSOLUTE output paths; named tests only. Never run, stop or touch the owner's programs or folders
(`C:\Users\trabi\tgarchive-app*`); build only into a folder of your own under your scratch space.

## Why
Windows Defender flagged the app's launcher `tgarchive.exe` as "Bearfoos.A!ml" (a machine-learning guess) on 11-22.
Unsigned programs that carry full version information and an application manifest are flagged less often.

## What exists
Each Windows program (`cmd/tgarchive`, `tgarchive-open`, `tgarchive-window`, `tgarchive-collector`, `tgarchive-watchdog`,
`tgarchive-backup`, `tgarchive-bringin`) has `rsrc.go` with a `go:generate` line and a committed
`rsrc_windows_amd64.syso` made by the project's own `tools/mkres` from `internal/appicon/app.ico`
(`internal/appicon/README.md`). The folder's build is `deploy/folder/make-folder.sh` (its `build()` passes
`-X main.version=$commit`). Read all of these first, and `git log -3 -- archiver/tools/mkres`.

## Build (standard library only; no new module, nothing fetched)
1. `tools/mkres` writes, besides the icon: a VERSIONINFO resource (StringFileInfo 040904B0: CompanyName "TG Archive",
   ProductName "TG Archive", FileDescription per program in plain words, e.g. "TG Archive launcher", "TG Archive
   window", "TG Archive collector", ...; InternalName and OriginalFilename the program's file name; LegalCopyright a
   fixed line; FileVersion and ProductVersion "0.YYYY.MMDD.N" or similar four numbers plus the commit as a string
   "ProductVersion" text, from flags), and an RT_MANIFEST (id 1): `asInvoker`, `supportedOS` Windows 10/11, DPI aware
   (PerMonitorV2 for the GUI programs launcher and window; the console ones may keep it simple), `longPathAware` true,
   and the Common Controls v6 dependency for the GUI ones. Check that a program which already embeds its own manifest
   (if any) does not get two.
2. The committed `.syso` keep a FIXED neutral version (e.g. 0.0.0.0, "dev"), so a normal `go build` works and the tree
   stays clean; `make-folder.sh` regenerates them with the build's commit and date before building and restores the
   committed ones afterwards (also on failure: a trap), so the source tree is never left changed.
3. Tests: a Go test of `tools/mkres` that parses the produced `.syso`'s resource section and finds the version
   strings and the manifest (or a test that builds one program into a temp folder and reads its resources with the
   standard library's `debug/pe`); `go vet ./tools/mkres`; gofmt. Then build every Windows program once into a
   folder of your own with the regenerated resources and show (counts only) that each has the version strings and a
   manifest; confirm the source tree is clean after `make-folder.sh`'s steps (run only its regenerate and restore part
   if the whole script needs things you must not touch, and say so).

## Hand back (short)
The head pushed; what each program now carries (the FileDescription words, the version form, the manifest's
settings); tests and checks with seconds; anything of `make-folder.sh` you could not run.
