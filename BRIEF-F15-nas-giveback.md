# Brief F15: a NAS that stops answering, on the Accounts page (UI track, session U-1, 11-22)

You are an Opus coder for the UI track of a private Go project (a Telegram archiver for Windows; a WebView2 window over the
collector's pages, `internal/server`; one frame `internal/appshell` with its control set, side sheet and `AppShell.ask`).
Work ONLY in your copy `C:\Users\trabi\Claude\Projects\Telegram\wt-ui-f15` (branch `wip/ui-nasgive`, cut from F14
`wip/ui-settings2` 780ad66a, which holds every UI piece). First merge pages' NG `private/wip/pages-nasgive` 1c70a00d. Commit
with `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, each message ending with `Co-Authored-By: Claude Opus
5.5 <noreply@anthropic.com>`; push only `git push private wip/ui-nasgive`.

## Rules (binding)
The "Rules" section of `C:\Users\trabi\Claude\Projects\Telegram\BRIEF-F1-one-frame.md` binds you word for word (invented data
only; the owner's real window is open: never a screen screenshot, never computer-use; pictures only of your own try window
with `runs-ui-1\shot.ps1`; Go through `ix-tools/env-archiver.sh`, one command at a time, named tests only; nothing against
Telegram or a NAS; TEMP/TMP outside the project folder). Try ports 18896-18899. Before pushing, by name: server
`-run 'TestAssets|Security|TestEmptyCatalogue'`, viewer `-run 'TestWall|TestHomeDevice|TestLAN|Security'`. Every asset under
600 lines. The page's style: F11b's Accounts (`runs-ui-1/f11b-pictures/1-accounts.png`) and F7's words (state in a few words,
the rest behind "i").

## The door (pages' NG)
The NAS facts gain `held`, `held_words`, `unreachable_since`, `unreachable_words`, `why`, `state_unreadable` (+`since`,
+`words`), `give_back` {held, words} when offered (only after 10 minutes without an answer), `give_back_from` (+`words`);
POST /api/nas/giveback {"account","yes":true} → {given_back, note} (409 while that NAS works). The Overview's and Accounts'
`nas` field is now a kept brief, refreshed in the background every 30 s: state, no_vpn (live), as_last_read, last_read_at,
held; it also appears for a "pc" account whose old NAS still holds files; absent until the first refresh after a start.
Removing an account can answer 409 while its NAS holds files. Shapes in NG's report on its branch.

## The goal
1. On an account's card: when its NAS does not answer, one line in the warning look ("The NAS has not answered since 04:12")
   with how many files it still holds; when `give_back` is offered, a button "Give its files back to this PC" whose words
   (held, what happens) are said in a confirm first; after it, the note. A 409 says the NAS answered again.
2. The kept brief: say "as of <time>" when `as_last_read`; nothing while absent (no "unknown" noise); a pc account whose old
   NAS still holds files shows that fact and the give-back when offered.
3. Removing an account that answers 409 says why in its words, never a raw error.
4. The Overview's Now: a NAS not answering is one line there too (with a link to Accounts), like the no-VPN banner.

## Done means
- Named tests (each NAS state on the card, the give-back confirm and its single POST, the 409s, the kept brief's "as of", the
  Overview line); the security sets; appshell whole; gofmt, vet.
- Pictures (your real try window, invented data): an account whose NAS stopped answering with the give-back offered, the
  confirm, the Overview's line. In `runs-ui-1/f15-pictures/`, for U-1's check.
- Report: branch head, files, tests with times, pictures, what is not done (under 20 lines). Close your programs.
