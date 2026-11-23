# Small follow-ups (run AFTER the viewer and NA5 prompts) — on the owner's Console credits

**Do the items below in order, in ONE go, without stopping** (the owner is not watching; this runs through the Agent
SDK script `ix-tools/agent-run/run_agent.py`). Merge each item as it is finished, so a later failure never undoes an
earlier one. "Stop" below means: skip that item, say why in the final report, and go on with the next. Give ONE
report at the end. Use no subagents unless an item says so.

## Rules (binding)
- Read `CLAUDE.md` first (privacy, the owner's folders never touched, nothing against Telegram, git rules: commit as
  `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, messages ending with
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`, push only to `private`, never tag or touch `main`).
- Read `START-INTEGRATOR.md` ("Each batch", "Practical") for how a piece is tested and merged here. Lesson of 11-22:
  run EVERY package the change touches, including those with a slash in the path (`internal/collector/livepages`,
  `internal/exact/wire`, `internal/bringin/oldgen`, ...) and `./cmd/...`, which the batch scripts skip.
- Go in Git Bash: `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh; export GOMEMLIMIT=1GiB GOMAXPROCS=2 GOFLAGS=-p=2`.
- Each item: a copy of your own from the main head (`git worktree add`), the fix with its tests, the named tests,
  then the whole packages it touches, then `ix-tools/merge-batch.sh`. After the last item: `bash runs-int-i6/folder-next.sh`
  once, three lines in `SESSION-11-PROGRESS.md` under "Follow-ups on Console credits", commit on `notes`,
  `bash ix-tools/notes-backup/backup.sh`.

## The items, in order
00. **FIRST AND KEY: cross-referencing in the viewer** (the owner, 11-22: "don't forget the cross referencing, that's
   key", with a screenshot, AFTER the viewer's saved-copy fix was installed, of a post still showing only "Not
   downloaded / held back by the archiver"). Every post whose media the archiver did not download because it
   recognised it must show WHAT it was recognised as and WHERE that copy is, and show that copy when it can:
   - Find every reason a file is held or not downloaded (the hold reasons, exact links, probable and look-alike
     edges, frame-check verdicts, the old archive's sightings and `library.old_root`, the brought-in account) and,
     for each, the catalogue's link to the recognised copy. Map them in a short table in your report.
   - Show the copy wherever it is: this app's library; **the old archive** (through `libroot.Resolve` and the old
     root, read-only, when the bring-in has been run); another chat's saved post. Label it: "same file as … in
     <chat>", "probably the same as … (held: Release)", "in the old archive".
   - When the recognised copy is only in the old archive and the bring-in has NOT been run, say exactly that ("a copy
     is in your old archive: run the bring-in from the launcher to see it here"), never a bare "held back".
   - A "Held" view (or filter) listing every held post with its recognised copy side by side, and Release / Keep held.
   - Read-only: nothing downloaded, released or written by viewing; Release stays the existing door. This decides
     nothing, but it touches the hold paths' reading: ONE independent review subagent before merging.
   Tests on invented catalogues for each reason, including an old-archive copy with and without the bring-in.
01. **Mirroring has its own place in a chat's panel** (the owner, 11-22: "I had collecting on, but I meant to turn on
   the mirroring", and "the mirroring doesn't seem to have a separate option in there?"; screenshot: the chat panel's
   COLLECTING section only). In each chat's panel, a **MIRRORING** section of its own, above COLLECTING: whether this
   chat is mirrored (and to which mirror), "Mirror this chat" / "Stop mirroring" through the existing mirror doors
   (the owner's click only; their waits and paces as today), and its state in plain words. Collecting and mirroring
   are named so they can't be mistaken: "Collect this chat's files (download them)" vs "Mirror this chat (forward
   its posts to a copy chat)". Nothing new is sent to Telegram beyond what those doors already do.
02. **A plain way to the chat list** (the owner: "how do I get to the chat list without clicking one of these? Not
   intuitive", about the Overview's mirror counts). A "Chats" entry always visible in the window's left list (and a
   "Mirrors" one), opening the full list with its filters; the Overview's counts stay as shortcuts only.
03. **A full UI check on invented data, after 00 to 0g are merged** (the owner, 11-22: "is there a way to get a full
   UI check on the mocked up version? Right now it's kind of a mess"). Generate an invented archive with
   `internal/fabricate` (several accounts incl. a brought-in one, mirrors in every state incl. a deleted source,
   held and copied posts of every reason, albums, forums, long chats, Saved Messages), build the app from the head
   into a scratch folder of your own (`deploy/folder/make-folder.sh <scratch>`), and run it there with
   `LOCALAPPDATA` and the app's data redirected into the scratch folder, no Telegram sign-in, nothing against
   Telegram. Drive every place of the window and the pages in the headless browser the tests use
   (`TGARCHIVE_BROWSER` = Edge, as the viewer's browser tests do), take a screenshot of each place and each state,
   and LOOK at them (read the PNGs). Write `AUDIT-UI-1122.md` with the screenshots under `reports/ui-1122/`: each
   problem with where, what is wrong, and a one-line fix, worst first; check against `DESIGN-ONE-WINDOW.md`.
   **Then FIX EVERYTHING it found** (the owner, 11-22: "Why not ask it to fix everything? We have the usage"), worst
   first, in pieces of a sensible size, each tested (the pages' and viewer's security sets by name, browser tests
   for what a person clicks) and merged as it is finished. Then run the whole check again on the new head, with new
   screenshots, and fix what is still wrong; repeat until the audit is clean or only the exceptions are left.
   `DESIGN-ONE-WINDOW.md` is a concept, not a constraint (the owner, 11-22: "if it sees a disaster, the one-window
   design was more of a concept. I don't want it constrained too hard by it"): where it makes the app worse to use,
   change it, and say what you changed and why in the audit. Keep its spirit: one window, a list on the left, no
   media shown on a fresh start. **The only exception**, listed with a one-line recommendation for the owner
   instead of built: anything that would send to Telegram or change what is downloaded, held or released. Never the owner's app or catalogue; invented
   data only. The final `AUDIT-UI-1122.md` shows each problem as found, fixed (with its commit) or left (why).
0. **The viewer: filter the chat list by account** (the owner, 11-22: "a way to filter chats by account"). The list
   of chats (and chat groups) gets an "Account" filter: all accounts (default), each signed-in account, and the old
   archive (the brought-in account) by its own word. The choice is kept with the viewer's other preferences.
   Viewer only (`internal/viewer` Go and web); read-only; numbers and the account's own label only, no new data
   kept. Tests on an invented catalogue with two accounts and a brought-in one; the viewer's security sets
   (`go test ./internal/viewer -run 'TestWall|TestHomeDevice|TestLAN|Security|TestPageScripts'`); whole
   `internal/viewer` and `internal/server` at the merge.
0b. **The viewer: jump to the top of a chat** (the owner, 11-22: "a way to jump to the top of a chat, once in it").
   In a chat's view, a button (and the Home key) goes to the chat's first message, loading what is needed; one
   beside it back to the newest (End). Viewer only; one door call per page of messages as today; a browser test
   that opens a long invented chat, jumps to the top and finds the first message, then back to the newest.
0c. **The window: hide Saved Messages** (the owner, 11-22: "hide Saved messages, since I don't really use it"). A
   setting in Settings, "Show Saved Messages in the list", **on by default** (the owner turns it off); off hides the
   Saved Messages place from the window's left list and its counts there, and nothing else: the account's own chat is
   still read, kept and searchable as today. Kept with the window's other preferences. Front end only
   (`internal/viewer/web` and/or `internal/appshell`, wherever the list is drawn; the pages' and viewer's security
   sets by name: `server -run 'TestAssets|Security'`, `viewer -run 'TestWall|TestHomeDevice|TestLAN|Security|TestPageScripts'`).
0d. **A stopped mirror still shows under "mirrors under way"** (the owner, 11-22, with a screenshot of the chip
   "Showing: mirrors under way (1) · show all", after stopping that mirror). Find in the code which state a stopped
   mirror has and why the filter and its count still take it as under way: the filter's state list, a stale count,
   a stop that leaves the row's state until a later turn, or the page not refreshing. A stopped mirror must leave
   "under way" (and its count) at once. A test with an invented mirror: start, stop, then the filter and the count.
   Pages and viewer (wherever the chip is drawn and its counts come from); the security sets by name as in 0c. Never
   open the owner's app or catalogue to look.
0e. **The Overview's "Today" is wrong** (the owner, 11-22, screenshot: "Downloaded 35 GB · Into the library 0 files ·
   0 B"). Measured read-only by the integrator the same evening: 1,137 files, 35.2 GB were saved into the library
   in those 24 hours (`file.location='library'`, `saved_at` within the window), from the one chat set to collect.
   So "Into the library" counts something else or is broken. Find what it counts, make it the files and bytes that
   entered the library in the window (or rename it to what it really is), and make every number on that card say
   plainly what it counts. Also: the owner believed downloads were off; make it obvious on the Overview which chats
   download (a "Downloading from N chats" line linking to the filtered Chats list). Test with an invented catalogue.
0f. **A mirror whose source chat was deleted** (the owner, 11-22: "I think the channel we were mirroring from was
   deleted?"; screenshots: the alert "The automatic mirror of a chat is blocked until you look at it: nothing more
   is sent for it by itself", "ended by itself", and on the Overview "1 under way · 2 complete · 2 ended for good").
   Find how a deleted or inaccessible source shows up (the error the reader or the mirror gets) and give it its own
   state and words: "the source chat no longer exists (or you lost access): this mirror is ended, nothing more can
   come", not "blocked until you look at it". The alert offers Remove from the list; the mirror's chat itself stays
   as it is. Together with 0d's count. No new request to Telegram (use what the reads already return).
0g. **Pin and unpin a chat in the viewer** (the owner, 11-22). A pinned chat stays at the top of the window's chat
   list (in pin order; drag or up/down to reorder), from the chat's menu and the list's right-click; kept with the
   viewer's other preferences (not Telegram's pins; nothing sent to Telegram). Front end and the viewer's
   preferences only; the security sets by name as in 0c.
1. **`internal/storeledger` `TestStoreEndToEnd`** fails up to 6 in 8 runs since 11-22 ("staging holds 4f (1)",
   storeledger_test.go:432): passes 8/8 on 2b38b2a, 1/8 fails from the UI batch (631dec0) on, 6/8 on 3c0c4fa.
   Likely a background worker added that day (clutter fill, picture hashes, fingerprints) holding a staged copy
   open or timing. Find the real cause; fix the product if a staged copy can stay behind (it must never), else the
   test. `-count=10` must pass.
2. **`internal/fabricate` `TestGenerateDeterministic`** fails since the UI batch ("same seed, different catalogues;
   first difference at line 602"): most likely `c_clutter_score.at`, the write time (C34). Make the generator or the
   comparison deterministic without dropping any real column from the check. `-count=5`.
3. **The Go caches** live in an old session's temporary folder (`ix-tools/env-archiver.sh`: `GOPATH`/`GOCACHE` under
   an AppData\Local\Temp\claude\...\scratchpad path), which a clean-up can empty. Move them to
   `C:\Users\trabi\Claude\Projects\Telegram\ix-tools\gocache` and `...\ix-tools\gopath` (copy the module cache over
   first so nothing is downloaded), keep the KeepAlive and ffmpeg lines, and prove it: a clean `go build ./...` and
   one named test with no download.
4. **Load-sensitive tests in `internal/collector`** that failed in whole runs on 11-22 and passed by name:
   `TestPairWordsRunApplies` ("no task pair-words"), `TestClickStateNudgeKeepsPause`, `TestChatActsThroughTheDoor`.
   Make their waits follow the test clock or a sound bound; checks unchanged. Prove with `-count=10` each while a
   whole `internal/catalog` run goes on beside it.
5. **Copies: picture hashes for the pictures already in the library** (C29's library pass for videos exists; pictures
   get their PDQ hash only at save today, C33). Same pass shape as C29's, reading library pictures only, never
   holding a copy; edges only through C33's door; nothing held, skipped or released. Follow
   `SESSION-COPIES-PROGRESS.md`'s state block. This decides copy edges, so ONE independent review subagent (Opus)
   before merging, with the diff only; fix what it finds.
6. **The range server answering past a part's end** (C25's finding, in `SESSION-COPIES-PROGRESS.md`): fix with a test.

7. **Copies' small leftovers** (C30's T4 mark, C32's N1, the two stale sentences in C34's report): as the state block
   at the top of `SESSION-COPIES-PROGRESS.md` describes them. Anything that changes which file is held, skipped or
   released gets ONE independent review subagent first.
8. **The viewer's last unmerged piece, MCv** (`SESSION-B-PROGRESS.md`, the newest state block: "everything merged but
   MCv"): refit it onto the head and merge it, or, if today's merges made it obsolete, say why and drop it.
9. **The mirror's owed small items** (`SESSION-MIRROR-PROGRESS.md`, the block "STATE FOR A TAKE-OVER (session M-7"):
   the pages' doors and the clean-up. NOT the first adoption and NOT the night's numbers: those need the owner.
10. **The watchdog's own alerts: a design note only** (Core's next item, `SESSION-CORE-PROGRESS.md`): a crash, a
   refused restart or a hang raised into K22's alert record, although the watchdog doesn't open the catalogue
   today. Write `DESIGN-CORE-watchdog-alerts.md` (one page, a recommendation, the owner's yes asked). No code.
11. **The NAS's ffmpeg container** (`SESSION-NAS-PROGRESS.md`, later pieces): so video fingerprints, the frame check
   and thumbnails also run on the NAS. Deploy files and the image build only (as `deploy/nas-app`), with the same
   regular-user, read-only, no-capabilities rules; nothing sent to or run on the NAS.

## Stop (skip the item, report it) when
- a fix would need the owner's real folders, the NAS, SSH, or Telegram;
- an item's cause is not found within a reasonable effort: report what you measured.
