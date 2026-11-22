# Review RN: renaming a mirror from the running app (independent review, pages P7, 2026-11-22)

**What I read and ran.** I read `git diff 6e610344 36e82316` in full: `internal/server/mirrors_rename.go`, `demomirrors_rename.go`, the route and list changes, `internal/collector/livepages/rename.go`, `internal/collector/pages_mirrors_rename.go` and their tests. I also read M19's `internal/collector/mirror_rename_door.go` and `internal/mirror/rename.go` whole, plus the guard, the held stop, `refuse`, `mirrorOutcome`, `errClass`, the window's gate and its net log, `CheckMirrorTitle` and `plainText`. My copy is `wt-pages-review-rn-scratch`, detached at 36e82316. Line numbers below are on **36e82316**, the piece under review; the house rules name af4ca40e, but this piece is not on it.

Every go command went through `runs-pages-p6/go1.sh`, with TEMP, TMP, LOCALAPPDATA and APPDATA in `C:\Users\trabi\AppData\Local\Temp\p7-rnrev\`. Only named tests ran. Fakes only: nothing reached Telegram, and no window was opened.
- server: `TestMirrorRename*` (6), `TestMirrorRoutesInGuard`, `TestMirrorRoutesOnlyWithProgram`, `TestMirrorHeldStopRefusesChanges`, and the probes `TestZZProbeRNReplay` and `TestZZProbeRNRestartAndGuard` (`internal/server/zz_probe_rn_test.go`, uncommitted). Result: all PASS, exit 0.
- livepages: `TestMirrorAdapterRename*`, `TestMirrorRenameWordsEveryEnd`, and the probe `TestZZProbeRNNotRecorded` (`internal/collector/livepages/zz_probe_rn_test.go`, uncommitted). Result: all PASS, exit 0.

## Findings

1. **SHOULD FIX, confirmed: the click's token can be used again; it is good whenever the plan's facts repeat.**
   - **Where:** `internal/server/mirrors_rename.go` 159-170 and 264. The token is a fixed hash of the plan's facts and the title. It has no use count and no expiry within a run, and nothing marks it used.
   - **What the probe showed** (`TestZZProbeRNReplay`, fake request counts in brackets):
     - Telegram refused (CHAT_ADMIN_REQUIRED), then the same token was sent again: 200, a second channels.editTitle went (4 → 5).
     - Telegram stated a wait: the old token was refused as "moved" while the wait ran (0 sent). Once the wait ended, the same pre-wait token sent again (1 sent).
     - The name went A → B, then back to A: the first plan's "rename to B" token was good again and sent (200, done).
     - After an "unknown" end the plan is the same too, so the token sends again. That one is by design ("safe to rename it again").
   - **How the owner meets it:** after "Telegram refused the rename", a second click (a double click, or a click on the same plan still on screen) sends one more request each time, without a fresh plan. The busy guard (`renameBusy`) only refuses a click that overlaps one still under way, not one that comes right after it. Any page code that resends the last POST also sends.
   - **Smallest cure:** make the token one-shot. The server keeps the tokens used in this run (a small map) and refuses a used token as "moved" with the plan on record now. A retry then needs a new plan GET, which reads the catalogue only. Keeping the facts in the hash is right; the single use is what is missing.

2. **SHOULD FIX, by reading (the adapter step confirmed): the real door's "not recorded" end comes as 502 with the generic failure words, not as the 200 the hand-back promises U-1.**
   - **The chain:**
     - `internal/mirror/rename.go` 248-250: `mirror.Rename` returns the catalogue's error with Outcome Failed and `EndRenameNotRecorded`.
     - `mirror_rename_door.go` 374 and 417 pass that error up.
     - `pages_mirrors_rename.go` 71: `doorErr` passes it through.
     - `livepages/rename.go` 187: `refusal(err)` gives the raw error back. Probe `TestZZProbeRNNotRecorded`: the error is not nil and not a refusal, with words = `MirrorRenameNotRecorded`.
     - `server/mirrors_rename.go` 282-286 then answers **502** with `error` = `mirrorFailedWords` ("The mirror's record failed now ...: whether anything was kept shows at its next reading.") and logs "the mirror's rename failed".
   - **Why the tests miss it:** the invented door (`demomirrors_rename.go` 109-110) and `TestMirrorAdapterRenameResult` (line 99) give this end with a nil error, so `TestMirrorRenameEnds` checks a 200 that the real program never answers. `pages-rename-REPORT.md` tells U-1 that "not recorded" comes as 200.
   - **How the owner meets it:** Telegram renamed the channel but the catalogue write failed. A page that shows `error` for a 502, as it does for the other mirror routes, says the record failed and nothing about the rename having gone out or "rename it again". The true words are only in `result.words`.
   - **Smallest cure:** in `handleMirrorRename`, answer an end that came after a request (`res.Requests > 0`, or `res.Outcome` set by the door) with its own words as `error`, and log it as "recorded failed" rather than "rename failed". Then make the fake return the error the way the real door does, and correct the JSON note for U-1.

3. **MINOR, confirmed: four of the door's real words fall to the "Not renamed: ..." frame, though `TestMirrorRenameWordsEveryEnd` says none does.**
   - **Where:** `livepages/rename.go` 102-122. The four are missing from the map, and the test's list (rename_test.go 139-142) leaves them out:
     - `EndAccountRefused`: Telegram refused the account on the rename's request.
     - `WhyChanged`: `mirror.Rename`'s fingerprint check.
     - `WhyMirrorNoHash`: a plan block from `MakeRenamePlan` 177.
     - `EndLedger`.
   - **What the probe showed:** e.g. "Not renamed: the account is refused for good by Telegram (spam): nothing is created or forwarded by it again."
   - **How the owner meets it:** the words are true, but they are the command line's. For the account refusal, the words do not say that one request went out, and they do not carry Telegram's reason (it is only in `result.reason`).
   - **Smallest cure:** give the four their own page words (the account refusal with its reason) and add them to the test's list.

4. **MINOR, by reading: no rename wait words carry the wait's end.**
   - **Where:** `server/mirrors_rename.go` 99, 100, 110 and 120. `MirrorRenameWait`, `MirrorRenameWaitHeld`, `MirrorRenameLongWait` and `MirrorRenameNoMemo` say "before it ends" or "try again after it" without a time. The end is only in the JSON `wait_until`.
   - **Where `wait_until` is missing:** the door's own `ErrRenameWaitHeld` refusal (`mirror_rename_door.go` 226-227, via `notSent`) carries no `WaitUntil`. If a wait is stored between the server's plan read and the door's, the 409 has no time at all. A NoMemo end has no "when" in its words.
   - **How the owner meets it:** a page that shows the words is told to wait but not until when. The held stop on the same server puts the time into the words (`stopheld.go` 43-45, `clockWords`).
   - **Smallest cure:** write `clockWords(wait_until)` into the wait words on the server, as the held stop does. In the 409 path, fill `result.wait_until` from the plan read just before.

5. **MINOR, by reading: the new name travels in the plan GET's query string.**
   - **What I checked for a leak:** I found no URL logged anywhere:
     - The server logs route patterns and `errClass` only.
     - The window's gate logs nothing of a request (`internal/window/gate.go` 18). The engine's net log is turned on by the self-checks only.
     - Caching and the referrer are off on `/api/` (`Cache-Control: no-store`, `Referrer-Policy: no-referrer`).
     - A fetch is not kept in the engine's history.
   - **The left-over risk:** the title's encoding is up to the page. An unescaped `+` reads as a space, and an unescaped `;` drops the field (Go's query parsing). The GET's title then differs from the POST body's, every click answers "moved", and nothing is sent. Safe, but the owner cannot rename.
   - **Smallest cure:** take the plan's title in a POST body, as `POST /api/mirrors/name-check` already does for names. Or tell U-1 in writing to escape the title with `encodeURIComponent`.

## Checked and sound

- **The token's tie:**
  - The token binds the account, chat and title, and every fact of the plan (mirror chat, state, current name, the name's length, limit and words, same, taken, the wait's end, method, requests, the block).
  - Another account, chat or title, or a made-up token, is refused as "moved" with 0 sent (probe; `TestMirrorRenameTokenTie`).
  - A replay after a done rename is "moved" with 0 sent (probe).
- **A restart:** the key is this run's random page token (`server.go` 260-264). A second server over the same doors refuses the first server's token as "moved" with 0 sent (probe). The hash fields are length-prefixed, compared in constant time and cut to 128 bits; the plan's token does not reveal the key.
- **The guard:** the click route is under it, and the probe refused every bad request with 0 sent:

  | Request | Answer |
  |---|---|
  | No page token | 403 |
  | Wrong page token | 403 |
  | Cross-site | 403 |
  | Another origin | 403 |
  | A rebinding host | 421 |
  | GET on the click route | 405 |

  The demo refuses it (`demoAllowed`). The held stop refuses it (`changeRoute`; `TestMirrorHeldStopRefusesChanges` counts 14, PASS). It is in `mutating` and `programOnly`, and both routes are registered only with the mirror seam (`TestMirrorRoutesOnlyWithProgram` PASS).
- **The plan GET sends nothing:** through the real door it reads only the catalogue, the settings and memory (`MakeRenamePlan`, `mirrorSignedIn`, `Frozen`, `methodFrozen`, `renameWaits`). The probe counted 0 renames.
- **Blocked plans:** a blocked plan with its own token answers 409 "not moved" in its words and sends nothing (`TestMirrorRenameBlocks`).
- **The plan is made again at three levels:** in the server, in `MirrorRename`, and in `renameInSession` with `mirror.Rename`'s fingerprint. A plan that turned blocked sends nothing.
- **Title checks before any door call:** empty, blank (Unicode white space), missing, and over 128 UTF-16 units (64 two-unit emoji pass, 65 do not) are all refused (`TestMirrorRenameTitle`). The rest (zero-width-only, spaces at the ends, broken UTF-8) is blocked by the door's `CheckMirrorTitle` in the plan, with no request.
- **No name in logs or errors:**
  - The server's lines are `errClass` only.
  - The collector's lines are numbers and the outcome word.
  - `NameWhy` and the refusal words are fixed words.
  - The probes and the tests checked the log for "Invented" and found nothing.
  - The current name appears only in the plan's own fields, including the "moved" answer's plan.
- **Waits are never slept:** the request layer's waits are bounded at 1 ns (`mirror_rename_door.go` 335), the server sleeps nothing, and `waited_seconds` is passed through unchanged.
- **The "unknown" end:** it says "It is safe to rename it again". A session that ends with the call begun and no answer gives that "unknown" end too.
- **Sign-out and freeze answers:** these after a request are said in the account's words with outcome "refused".
- **Two clicks at once:** the second is refused as busy (409), with nothing sent.
- **A page that goes away:** the work context is the pages' context. A rename not yet begun is given up with nothing sent; a begun one runs to its end and keeps its answer.

## Not verified

- A real rename against Telegram, and the real door's ends end to end through the seam (fakes only; the collector's side was checked by reading).
- The page itself (U-1): that it shows the plan before the click, disables a second click, never resends a POST, and draws `wait_until` and the 502's `result.words`.
- How long a click waits for the account's reader task (`mirror_rename_door.go` 250-281). The POST has no bound and no words while it waits. It is the same design as the estimates (M19's), but I did not measure it.
- The request layer's keys for a stated wait on a rename, and its other waits on the account (M19's scope).
