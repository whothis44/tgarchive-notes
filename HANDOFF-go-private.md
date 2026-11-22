# Handoff: take the fork private and delete the public repository (written 2026-11-13 ~17:30 local)

**The owner's decision (11-13):** "The damage is already done due to your release notes. We should go private and nuke
the existing repo entirely." The weekly usage resets in a few hours; this is the next session's main task.

Read first: `CLAUDE.md`, `START-HERE.md`, then this file. Current fork state: `HANDOFF-ix12.28.md` plus the 12.30 notes
below. Live lessons for the new app: `LESSONS-ix12.30-live.md` (keep it updated; it has a "Still to come" list).

---

## DONE (11-13 late evening): the public fork is no longer public
- **Instead of deleting it**, the owner used "Leave fork network", then "Change visibility" → Private.
- Checked:
  - an anonymous API request answers **404**;
  - signed in it shows private, no longer a fork, not archived.
- Its 43 releases with all files, 42 PRs and CI logs are kept, privately.
- **tg1 stays the working repository:** tools, remotes and docs point there. The old repo is private and, since
  11-13, **archived (read-only)** by the owner. Never push to it.
- Left over (small):
  - next fork release: tag in tg1; the owner installs it by hand;
  - the launcher will report "Could not check for an update" at each start: expected.

## Progress, part 2 (11-13 late evening; the owner: "Explicit yes to delete the public fork once you've copied over everything you need")
- **Everything copied:** the 16 old branches that were only on the public fork were also pushed. A set comparison of
  all refs shows **0 missing and 0 different** (tg1 has 96 refs; the public fork's `refs/pull/*` are not copyable).
- **Release files kept locally:** `release-archive/12.30` and `release-archive/12.29`, each with the Windows amd64 and
  arm64 archives, `SHA256SUMS` (checked OK) and the release notes.
- **tg1 workflows:** kept `ci.yml`, `ix-tests.yml`, `docker.yml` and `release-server.yml`; disabled the other 8.
- **Repointed to tg1:**
  - `origin` of the shared repository (`repo/.git`: all `repo*` worktrees and `wt-v12.30`);
  - `origin` of `repo-archiver` (its pushes still go to `private` = tgarchive; **never push the new app to origin**);
  - `ix-tools/{ci_log,ci_wait,gh_pr,gh_release}.py`;
  - `START-HERE.md` line 16.
- **Deleting the public fork by API was refused (403, no admin right on the stored credential).** The owner deletes it
  in the web UI. Afterwards check that `api.github.com/repos/whothis44/telegram-media-downloader` answers 404, and at
  the next restart that the launcher says "Could not check for an update … Starting the installed version."
- **Still open:**
  - `gh_release.py show` answers 404 in tg1 until a release is built there (tags only so far);
  - `PRE-PUSH-CHECKLIST.md` and the old HANDOFF files still mention the old name in passing (history, leave them);
  - the next fork release is built by tagging in tg1, and the owner downloads it while logged in.

## Progress (11-13 evening, last minutes of the week's usage)
- **Step 1 done:** the owner created the private repository **`whothis44/tg1`** (https://github.com/whothis44/tg1).
  Checked: private, not a fork, empty before the push.
- **Step 3 done:** pushed from `repo-v12.16` with no `--mirror`:
  - `main`, all 34 `ix/*` branches (35 branches in all) and all 43 `v3.4.18-ix.*` tags;
  - `ls-remote` shows 35 branches, and tag `v3.4.18-ix.12.30` = `e18f80a` as on the fork.
- **No Actions runs were started by the push** (checked: 0 runs), so no CI minutes were used. Workflows there are
  still as copied: disable the unused ones (section 2) before the first push that should run CI.
- **Next:** step 2 (local copies of the 12.30 and 12.29 Windows release files: download, needs the owner's OK), then
  steps 4–10.
  - Remotes and tools still point at the public fork.
  - The public fork is untouched.
  - Releases do not exist in tg1 yet: a tag there builds one only once Actions runs.

## 0. State when this was written
- **Live:** 12.30 since 11-13 14:42:02, installed by hand by the owner; 12.29 ended clean.
  - 12.30 = tag `v3.4.18-ix.12.30` = `e18f80a`, branch `ix/v12.30` in worktree `wt-v12.30`, draft CI-only PR #42 on
    the public fork.
  - The release passed on its third attempt: two old timing tests failed on the release runner, see
    `LESSONS-ix12.30-live.md` §5.
- **12.30 contents:**
  - short-wait climb, on by default;
  - automatic count-and-add of chats not in the downloader (`ix_autochats.go`);
  - the "Never add" button.
- **Since the start:** 30 channels added automatically, history reads working on the frozen account, about 2 TB of new
  unique files found, mostly DC1.
- **Not yet done:**
  - read DC4 in the first unlimited hour under 12.30;
  - finish the new channels' read results;
  - add both to `LESSONS-ix12.30-live.md`.
- **The public fork** `whothis44/telegram-media-downloader` (checked 11-13):
  - a GitHub fork of `botnick/telegram-media-downloader`;
  - public, 0 forks, 0 stars, 0 watchers, 14 MB, 43 releases (`v3.4.18-ix.*`).
  - Its CHANGELOG, commit messages and PR bodies carry aggregate archive numbers (GB, file and chat counts, servers,
    hours). Never names, chats, links or paths, but the owner considers that exposure.
- **The private repository** `whothis44/tgarchive` already exists for the new app (checkout `repo-archiver`, remote
  `private`; its `origin` is the public fork).

## 1. What depends on the public repository (checked in code on 11-13)
1. **The app's hourly update check** (`core-service/internal/app/ix_update.go:82-100`):
   - calls `https://api.github.com/repos/<repo>/releases/latest` **without a token**;
   - the repo comes from env `TGDL_RELEASE_REPO`, default `whothis44/telegram-media-downloader`;
   - a private or deleted repo answers 404. **Still to verify in code:** that this only puts "could not check" in the
     report and never stops downloads.
2. **The launcher's updater** `ix-update.ps1` (run by `start.bat` before every start):
   - anonymous API, repo from `TGDL_RELEASE_REPO`;
   - **on failure it warns "Could not check for an update … Starting the installed version." and exits 0**
     (lines 116-122). A deleted repo does not stop the app starting. Still, read the whole script once more before
     deleting.
3. **Our tools:**
   - `ix-tools/gh_pr.py`, `gh_release.py`, `ci_wait.py`, `ci_log.py` (`REPO = …` constants);
   - the remotes of every worktree (`repo`, `repo-v12.5`, `repo-v12.7`, `repo-v12.11`, `repo-v12.16`,
     `repo-v12.19-ui`, `wt-v12.30`, plus `wt-bytepath2` and `wt-signin`: check which repo they point at);
   - `repo-archiver`'s `origin` remote.
4. **Docs and memory:**
   - `START-HERE.md` (§4, §7: push/PR/release commands), `CLAUDE.md`, `PRE-PUSH-CHECKLIST.md`;
   - the memory files under `C:\Users\trabi\.claude\projects\C--Users-trabi-Claude-Projects-Telegram\memory\`.
5. **Releases:** the 43 published releases and their 8 archives each disappear with the repo.
   - Locally: the installed 12.30 in `E:\T\tg-dl`, and the updater's copy before each update in
     `data\backups\pre-update-*` (the last 3; never read inside them).

## 2. Facts to confirm first (cheap, read-only)
- **GitHub does not let a fork's visibility be changed.** So "going private" means a NEW private repository and a copy
  of the history. Confirm in the repo's Settings → Danger Zone, or GitHub's docs. If GitHub offers "Leave fork
  network" and then "Make private", that is an alternative; say so to the owner.
- **The owner's GitHub plan and Actions minutes.** Private repos have a monthly allowance; public ones are unlimited.
  The fork's CI runs on ubuntu only (1× minutes): ci.yml (several jobs), ix-tests.yml, docker.yml, plus
  release-server.yml per tag. Several releases a day could use the free 2,000 minutes before 11-29.
  - Upstream workflows we never use should be disabled in the private copy: `site-refresh.yml`,
    `telegram-notify.yml`, `ix-sync.yml`, `dependabot-merge.yml`, `release-faces-service.yml`,
    `release-nsfw-service.yml`, `release-seekbar-service.yml`, `test-sidecars.yml`. Check each for a schedule (cron)
    first.

## 3. The plan (each step that changes GitHub or the owner's PC needs the owner's OK; ask briefly, numbers first)
1. **Ask the owner one question:** the private repository's name. For example `whothis44/tgdl-fork`, kept separate
   from `tgarchive` (the new app). Whether the owner or I create it, with the stored git credential (it has repo
   rights).
2. **Keep local copies before anything is deleted** (download: say the files and sizes, and get the OK).
   - The release archives for the Windows build of the installed 12.30 and of 12.29, plus `SHA256SUMS`.
   - Put them in a new folder, e.g. `C:\Users\trabi\Claude\Projects\Telegram\release-archive\`, never in `E:\T\tg-dl`.
3. **Copy the history to the private repo:** `main`, every `ix/v*` branch, and every `v3.4.18-ix.*` tag.
   - From `repo-v12.16`: `git push <private> 'refs/heads/main' 'refs/heads/ix/*' 'refs/tags/v3.4.18-ix.*'`.
   - Never `--mirror` from a worktree, and never push `main` anywhere else.
   - Check the counts match afterwards (branches, tags, `git rev-parse` of the 12.30 tag).
4. **CI in the private repo:** disable the unused workflows (section 2). Run CI once on `ix/v12.30` to see it is
   green there and how many minutes one run costs.
5. **Releases from now on: installed by hand by the owner**, as 12.30 was. This needs no code change and carries no
   risk until 11-29.
   - The updater's anonymous check simply fails, and the app keeps running (section 1).
   - A signed-in updater (token in a file under `data\`, read by the app and `ix-update.ps1`, never printed) is
     possible later, but it needs two installs and a review. Propose it only if the owner wants automatic updates
     back.
   - To publish from the private repo, tag there; its `release-server.yml` builds the archives. The owner downloads
     while logged in.
6. **Point everything at the private repo:**
   - `git remote set-url origin …` in each worktree;
   - the `REPO` constants in `ix-tools/*.py`;
   - `START-HERE.md`, `CLAUDE.md`, `PRE-PUSH-CHECKLIST.md`, the memory files;
   - `repo-archiver`'s `origin` (remove it, or point it at the private fork).

   Then test the tools read-only: `gh_release.py show` against an old tag in the private repo.
7. **Writing rule from now on (owner's concern):** commit messages, PR bodies and CHANGELOG entries **describe
   changes without the archive's numbers**. No GB, file or chat counts, servers' traffic or hours. Numbers stay in the
   local notes. Apply this even in the private repo.
8. **Delete the public repository**, last, and only with the owner's explicit "yes" **at that moment**: it is permanent,
   and it removes its PRs, releases, issues and Actions history.
   - Before asking, state what goes: 43 releases, PRs #1–#42, all CI logs.
   - Confirm that steps 2–6 are done and checked.
   - Deleting it does not remove copies held elsewhere (search caches, archive sites); there were no forks, stars or
     watchers on 11-13.
   - Use the GitHub web UI (Settings → Delete), or the API with the stored credential if it has the delete right.
9. **After the deletion:**
   - check that the report's `update:` line shows the failed check without errors elsewhere;
   - at the owner's next restart, the launcher should print "Could not check for an update … Starting the installed
     version.";
   - nothing in `E:\T\tg-dl` changes.
10. **Record it:** a short note in `START-HERE.md` §3 and in memory: the new repo name, the date, and that releases are
    manual.

## 4. Do not
- Delete anything before the private copy is verified and the owner has said yes for the deletion itself.
- Stop, restart or reconfigure the running app, or edit `start.bat`. `TGDL_RELEASE_REPO` lives there or in its
  environment, and changing it is the owner's to do.
- Print the token, `start.bat`, or anything under `data\sessions\`.
- Make the new app's repository public, or push the new app to the fork.

## 5. Also pending from 11-13 (lower priority than the move)
- **DC4 in the first unlimited hour under 12.30:**
  - time at 2 parts, tries up, "short waits at 2 parts or fewer with no ceiling", plain waits per hour, GB;
  - against the 22 hours from 11-08 to 11-13 (script idea: `dc4_timeline.py` in the old session's scratchpad, method
    in `LESSONS-ix12.29-servers.md` §4);
  - add the result to `LESSONS-ix12.30-live.md`.
- **The 30 auto-added channels:** final read size, copies by Telegram file and by sampled frames, per server. The
  decoder `dcq` (Go, read-only, in the old scratchpad: `ix_messages.tl` → `Document.DCID`/`Photo.DCID`) is easy to
  rebuild; see `LESSONS-ix12.29-servers.md` §1.
- **Known release-runner flakes** to harden in the next fork release, test-only:
  - `TestAPartTelegramNeverAnswersIsAskedForAgain` (`pacer_test.go:484`, a 30 ms threshold);
  - `TestIx1214CheckForUpdatesNowIsThrottled` (races the test app's own update check).
- **`ix-tools/race.sh` has no CPU cap.** Use `docker run --cpus 1.5` directly (see memory "agent-load-limits").
  `ix-tools/ui.sh` cannot run `tests/ui/viewer_pages.py` without first starting
  `VIEWER_SERVE=8799 go test -run TestViewerFixture -timeout 0 ./internal/app/`.
