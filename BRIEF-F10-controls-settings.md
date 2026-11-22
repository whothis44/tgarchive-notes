# Brief F10: one set of modern controls, and Settings rebuilt with them (UI track, session U-1, 11-22)

You are an Opus coder for the UI track of a private Go project (a Telegram archiver for Windows; a WebView2 window over
the collector's pages, `internal/server`, the viewer, `internal/viewer`, and the launcher's page; one shared frame,
`internal/appshell`, mounted by both servers). Work ONLY in your copy `C:\Users\trabi\Claude\Projects\Telegram\wt-ui-f10`
(branch `wip/ui-controls`, cut from `wip/ui-all` 6b659b13). Commit with `git -c user.name=Claude -c
user.email=noreply@anthropic.com commit`, each message ending with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`;
push only `git push private wip/ui-controls`.

## Rules (binding)
The "Rules" section of `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-F1-one-frame.md` binds you word for word (invented data
only; the owner's real window is open: never a screen screenshot, never computer-use, pictures only of your own try window
with `runs-ui-1\shot.ps1` or headless Edge; Go through `ix-tools/env-archiver.sh`, one command at a time, named tests only;
nothing against Telegram). Your try ports: 18826-18829. Every setting keeps its route, its guard and its meaning; Go
handlers are pages' (ask U-1 for a field or route that is missing). Another coder (F9, `wt-ui-f9`) works on the same base on
the title bar, Quit's dialog, the pill, the library's scrollbar and day headers, and routes More › Program to Settings ›
Program: do not touch those; F9 does not restyle Settings.

## The owner's words (11-22)
"The old app is super ugly, and the settings part ... needs a complete UI revamp as well. More modern, selection boxes,
toggles or windows, whatever makes sense and is modern and proper." Today's Settings: `runs-ui-1/all-pictures/4-settings-folders.png`
and F6's `runs-ui-1/f6-pictures/` (sections exist; each row is still an old text box, number field or checkbox with
paragraphs of explanation). The frame to match: `design-options/app-look-options.html` ("The combination") and
`runs-ui-1/all-pictures/1-overview.png`.

## The goal
1. **One control set, in `internal/appshell/assets`** (CSS + a small JS module, served by both servers as the frame is), in
   the frame's tokens (dark and light): toggle switch; select (a styled native `<select>`, or a menu of our own with keyboard
   support); segmented control; number stepper (− value +, typed value allowed, min/max from the setting's data, a unit
   suffix); text field; folder row (path, "Change…"); a setting row layout (label, one short line, the control at the
   right, an "i" that opens the long explanation in a popover); section card; inline "Saved" / error feedback per row
   (optimistic, rolled back with the server's words on refusal); a modal dialog and a side sheet (focus trapped, Esc
   closes, never `confirm()`); a tag/chip input where a setting is a list. Keyboard and screen-reader roles for each. A small
   gallery page for tests only (not in the app's navigation).
2. **Settings rebuilt with it** (`internal/server/web/assets/js/pages/settings.js` and the mirror/clicks settings modules,
   their CSS): every setting mapped to the right control (on/off → toggle; one of a few → segmented; one of many → select;
   numbers → stepper with unit; folders → folder row; lists → chip input). Each row one label and at most one short line;
   the rest behind "i". Rare or risky settings under an "Advanced" fold per section. The engine's fixed facts stay folded
   under Downloads. Changes save on change (no Save button) unless a setting needs a confirm (then a dialog naming what
   happens). The Library display section (the viewer's `/settings`) gets the same controls, in the viewer's own module.
3. A test that lists every setting the pages and the viewer offer today and checks each still renders and posts to its route.

## Done means
- Named tests: the controls (keyboard: toggle with Space, stepper with arrows, dialog Esc/focus), the settings inventory test,
  each control's save and rollback against a fake route; appshell whole; gofmt, vet.
- Pictures of the WHOLE app (your real try window, invented data): Settings › General, Downloads (with a stepper and the
  folded facts), Copies, Mirrors, Library display, an "i" popover open, a confirm dialog open, light theme once. In
  `runs-ui-1/f10-pictures/`; look at them beside the agreed picture and say what differs.
- Report: the branch head, files touched, tests with times, the pictures, what is not done (under 30 lines). Close your programs.
