# Brief F11b: the app's remaining old pages rebuilt (UI track, session U-1, 11-22)

You are an Opus coder for the UI track of a private Go project (a Telegram archiver for Windows; a WebView2 window over the
collector's pages, `internal/server`, and the viewer, `internal/viewer`; one frame, `internal/appshell`, with one control set
`internal/appshell/assets/controls.js`/`controls.css` and one dialog `AppShell.ask`). Work ONLY in your copy
`C:\Users\trabi\Claude\Projects\Telegram\wt-ui-f11b` (branch `wip/ui-pages`, cut from `wip/ui-chats` 46c3478f: every UI piece
so far). Commit with `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, each message ending with
`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; push only `git push private wip/ui-pages`.

## Rules (binding)
The "Rules" section of `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-F1-one-frame.md` binds you word for word (invented data
only; the owner's real window is open: never a screen screenshot, never computer-use, pictures only of your own try window
with `runs-ui-1\shot.ps1`; Go through `ix-tools/env-archiver.sh`, one command at a time, named tests only; nothing against
Telegram; TEMP/TMP outside the project folder). Try ports 18846-18849. Every action keeps its route, guard and its words
before the click; Go handlers are pages' (ask U-1 for a missing field). Another coder (F11c, `wt-ui-f11c`) rebuilds the
viewer's pages: do not touch `internal/viewer/web`.

## The owner's words (11-22)
"The old app is super ugly, and the settings part ... needs a complete UI revamp as well. More modern, selection boxes,
toggles or windows, whatever makes sense and is modern and proper." Settings (F10) and Chats (F11a) are done that way:
match them (`runs-ui-1/f10-pictures/`, `runs-ui-1/f11a-pictures/`).

## The goal: these pages in the same modern style, with F10's controls and F11a's patterns (list + side sheet)
1. **Accounts:** one card per account (name, signed in or not, its lanes' state in a few words, where it runs: this PC or the
   NAS), actions as buttons with their words; "Add an account" as a sheet with steps (the existing sign-in routes). The NAS
   rows from pages' N4P (`wip/pages-nas` 485ba7b3: merge it; shapes in its `archiver/docs/progress/pages-nas-REPORT.md`):
   place pc|nas, pairing (the file download), the NAS sign-in steps, forget; `no_vpn` shown loudly (a red banner with its
   words) wherever it appears, also on the Overview's Now block.
2. **Queue:** the lists (downloading now, waiting, failed, set aside, held, gone) as tabs or a segmented control with counts,
   each a clean list (file, chat, size, state in words); a row's details in a side sheet; the filters as chips; F3's folded
   Details stays at the foot.
3. **Staging:** what is on its way to the library in one card (counts, the copy queue, free space with a bar), problems as
   rows with their action.
4. **Import** and **Report:** a short card each, the steps or numbers in the control set's rows; Report's "copy to share" a
   button.
5. Empty states on each; both themes; widths from 900 px with no sideways scroll (a test like F11a's).

## Done means
- Named tests: each page's markup and every action still posting to its route with its words; no sideways scroll at
  900/1280/1600; the NAS rows (each `nas` state, `no_vpn` banner); appshell whole; gofmt, vet.
- Pictures of the WHOLE app (your real try window, invented data, 2 accounts): Accounts (one on the NAS, one with no_vpn),
  Add an account's sheet, Queue (two tabs), Staging, Report. In `runs-ui-1/f11b-pictures/`, for U-1's check only.
- Report: branch head, files, tests with times, pictures, what is not done (under 25 lines). Close your programs.
