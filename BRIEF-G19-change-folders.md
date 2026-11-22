# Brief G19: the folders can be changed after the setup; the setup says what it sees (pages, P6, 11-16)

**The first rule of this folder: routine steps in one go or by a script, never one call at a time for its
own sake.** You are one Opus coder. Work only in the copy and on the branch your start message names
(`wt-pages-folders`, `wip/pages-folders`). Never touch `repo-archiver` itself or another `wt-*` copy.

## What the owner met (11-16 18:05 to 18:15, the first real start of the folder's program)
At the setup the owner named **the OLD APP'S LIBRARY ROOT as the library** (199 entries directly in it)
and a folder under the old app's folder as staging, saved, and then: **"there's no way to change it. It
says to quit/reopen the app"**: a second start does not show the setup again. (What the collector did
there, read by the integrator: nothing in the library; in the staging folder its mark, 71 bytes, and
one more new file; no download, no copy.) Wanted, in the integrator's words from the owner's:
"Change the folders" on the launcher's page and from Settings; and the setup must SAY what it sees
before it saves: a library folder that is not empty and not this catalogue's (how many entries; "this
looks like another program's library": a second yes), a staging folder inside another program's folder.
**Until the folders are put right nobody tells the owner to choose a chat.**

## What the old app already knows
The old app takes its folders from a start file and never asks; its one lesson here is the owner's
rule that its folder `E:\T\tg-dl` is read-only for every session and that nothing of ours may write
into its library: a setup that takes a non-empty folder without a word is how that would happen. This
app's own record: `DESIGN-G6-one-folder.md` in the project folder (the design the owner agreed to:
read its points 1 to 4 first), and the collector's refusals for a staging folder (`internal/collector/
staging.go`, `words.go`: a staging folder locked, of another catalogue, marked as a part store's): read
them, the setup must not promise what the collector then refuses.

## What to build
**A. "Change the folders" on the launcher's page.** A control on the launcher's status page (and on
its "could not start" page) that, after ONE confirm which says what it does ("This stops the app's
programs (collecting stops; nothing is lost) and shows the setup again with what is saved now"),
stops the app's programs exactly as Quit does (the launcher itself and its window stay), shows the
setup page filled with the saved values, and on "Save and start" writes the settings and starts
again. "Cancel" on that setup page starts again with the saved values unchanged. Look first at how the
launcher decides to show the setup today and at any existing path back to it (a failed start's page):
reuse, do not build a second setup.
**B. What a change means for what is already there: said on the setup page BEFORE the save, true of
the code.** Read what the collector and the store do when a start names another library folder or
another staging folder for an existing catalogue (Core's packages: read only): are saved files' places
kept relative to the library folder; does the staging folder carry the catalogue's mark; what does a
start say when the mark is missing or another's. Then the page says, in plain words, only what you
found, for example: "Files already copied to the old library folder are not moved: move them yourself
first, or the app will find them missing." / "Files downloaded and not yet copied stay in the old
staging folder." If the pages answer, the launcher may ask them how many files are saved and how many
wait staged (an existing read; numbers only) and say the numbers; if it cannot, it says "not known".
For the owner's case today (nothing saved, nothing staged) the page must come out as: nothing to move.
**C. The setup says what it sees in a folder before it saves** (the first setup and every change; the
"Choose..." box and a typed path alike), by a look that only lists the folder's direct entries
(numbers only: never a name in a page, a log or a test's output):
- the library: empty, or holding this app's own library (say how you tell: a mark, the data folder's
  catalogue naming it, or "it is the folder saved now"), or **"This folder is not empty: N things are
  directly in it, and none of them is this app's. If it is another program's library, this app's
  folders would be written among them. Choose an empty folder, or confirm: 'Use this folder
  anyway'"**: a second, explicit yes (a checkbox or a second button, off again when the path changes);
  without it "Save and start" refuses with the same words;
- the staging folder: empty, or this app's own (its mark; use an exported read of the store's or the
  collector's if one exists, do not copy its format), or not empty and not this app's: the same second
  yes; **inside the library folder, or the library inside it, or either inside the app's own programs
  folder: refused in fixed words** (say what the collector's own refusals already cover);
- the data folder: holding a catalogue: "an existing archive is in this folder: the app goes on with
  it"; empty: "a new, empty archive is made here";
- a folder on a share that does not answer within a bound (2 s; the look runs off the page's
  goroutine, as the free-space words do): "cannot be looked at now", and the second yes is asked.
**D. From the app's pages to the launcher.** The owner must be able to reach "Change the folders" from
the app's pages (today nothing leads from the app's pages back to the launcher's page): the collector
gets a start flag `-launcher-url <address>` (LENT LINES in Core's `internal/collector/command.go`, its
`Config` and where `pages.go` fills `server.Config`: ONE commit of their own, named in the hand-back;
Core has a session, K-5: I tell it on the board), the launcher passes its own page's address, and
`internal/server` shows, when it is set: on Settings a region "This program" with the three folders as
the run has them (the server knows the library; say what else it knows) and a link "Change the
folders (the launcher's page)"; in the header a link "Program" to the launcher's page. With the flag
absent nothing changes on any page. Another coder of this track ("G18") adds `-viewer-url` for the
window kind of viewer in the same function (`start.go` `collectorArgs`): keep your line separate so
that the two merge.
**E. The owner's way out TODAY, before this is merged:** find out, on a scratch copy with stand-in
programs (never the owner's folder), whether this works with the build the owner has (main head
78739d59): Quit; delete or rename the launcher's settings file (`tgarchive.json` in the app's folder);
open `tgarchive.exe`: does the setup show, offer the same data folder, go on with the catalogue that
is there, and start with new library and staging folders? Write the exact steps, with the full path
`C:\Users\trabi\tgarchive-app\tgarchive.json` named, as a short text file in your report's folder
(`archiver/docs/progress/pages-folders-OWNER-STEPS.md`): what you tried, on what, and what you could
not try (the real collector's start with a new staging folder: read from its code and say so).

## Rules
- Files: `internal/launcher` (the setup's code: `settings.go`, `ui.go`, `choose.go`, `folderbox*.go`
  where needed, the setup's flow in `launcher.go`, `words.go`), `cmd/tgarchive-open` if needed,
  `internal/server` for D (Settings' new region and the header link only: other coders of this track
  work in `internal/server` now on the Queue page, the mirror settings and the viewer row), the lent
  lines of D. G18's coder works in `internal/launcher` on the window (`present.go`, `start.go`, the
  window's paths in `launcher.go`): keep out of those.
- A look at a folder never follows a link out of it, never reads a file's content, never writes
  (the one existing writability check of the setup stays as it is), and counts at most 10,000 entries
  ("10,000 or more").
- No test function removed or renamed. Tests on stand-in programs and temporary folders with invented
  entries, in the launcher's own style; each new rule with the test that fails without it. Words a
  person reads: plain, true of the code.
- **Every go, gofmt and vet command through the track's lock script:**
  `bash /c/Users/trabi/Claude/Projects/Telegram/runs-pages-p6/go1.sh /c/Users/trabi/Claude/Projects/Telegram/wt-pages-folders/archiver <command...>`
  (it may wait some minutes for the lock: expected). Named tests only, nothing over two minutes a
  command, no whole package, no race detector.
- For every process you start: `LOCALAPPDATA`, `APPDATA` and `TEMP` redirected to scratch folders;
  ports above 20000 that nothing listens on; never the owner's real folder
  `C:\Users\trabi\tgarchive-app`, never anything under `E:`, never the old app's folder. Never a Windows
  path inside a shell string (Write/Edit tools; `/c/...` in bash). Never capture the output of a
  command that starts a hidden program: output to a file.
- Commit as you go, push to `private` only (`git push private wip/pages-folders`):
  `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, the last line
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Invented data only. Leave no process and
  no scratch folder behind.

## Hand back (at most 18 lines)
The pushed head; how "Change the folders" stops and starts; what B found in Core's code and what the
page says for it; how the setup tells this app's own folders from another's; the lent commit's hash;
E's answer in two lines; files with +/- lines; test functions added and removed; the named tests run;
what you saw of the setup page (if you could look at it) ; what is NOT verified. A report as
`archiver/docs/progress/pages-folders-REPORT.md`.
