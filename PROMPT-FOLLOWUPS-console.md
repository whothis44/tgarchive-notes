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
