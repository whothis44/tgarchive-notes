# Review G19: changing the folders (pages, P6), independent

Reviewed: `wt-pages-folders`, branch `wip/pages-folders`, head a281c273 against base 78739d59 (23 files, +1,457 -47),
read whole: `internal/launcher` (change.go, look.go, folders.go, choose.go, launcher.go, ui.go, page.go, start.go,
settings.go, words.go, folders_test.go), the lent lines c1d80f48 (`internal/collector` command.go, pages.go,
launcherurl_test.go), `internal/server` (launcherlink.go, server.go, the three scripts, index.html), and for question 4
Core's code read only (`collector/staging.go`, `stagingmark.go`, `lock.go`, `store/guard.go`, `sweep.go`, `names.go`,
`server/server.go` settleSettings, `server/settings_when.go`). The copy was not edited (`git status` clean).
Probes: plain files in `wt-pages-review-g19-scratch`, loaded with `-overlay`, every go command through the track's
`go1.sh`, `LOCALAPPDATA`/`APPDATA`/`TEMP`/`TMP` redirected to scratch folders, stand-in programs only, no port below
20000 asked, nothing of the owner's app or of `E:` touched. Files: `probe_launcher_windows_test.go` (probes P1 to P5),
`probe_server_windows_test.go` (P6, P7), `mutants.sh` with `m1` to `m10` (Q6), the run outputs `run1.txt`,
`run-looks.txt`, `run-server.txt`, `run-etree.txt`, `run-collector.txt`, `mutants-a.txt`, `mutants-b.txt`, `mutants-c.txt`.

## Findings

**1. MUST FIX (confirmed). The second yes is bound to the path only, not to what was seen: a yes given for "cannot
be looked at now" is taken at the save for a folder that the save's own look then sees full, and the owner never
reads the "not empty: N things ... another program's library" words.** `fillYes` sets `LibraryYesOn` from
`library_anyway` and `library_seen == path`; `checkSetup` looks again at the save and, seeing entries, needs the yes
and finds it given. The owner's library is on the NAS over Wi-Fi: a first look that takes over 2 s (a share waking)
is exactly the likely case, and it lands the owner in today's situation (another program's library taken without a
word about it). The same holds for "This folder's entries cannot be listed" then listable and full, and for the
staging folder. Probe P1 `TestReviewG19YesFromNoAnswer`: "first save: code 200; says no answer true; yes box true";
"second save (the folder answers now, 3 entries): code 303; the answer said not empty false"; "after the start: saved
true with that library true; the collector was given it true". Fix: carry what was seen with the yes (a hidden field
naming the finding: empty / full N / no answer / not listable) and take the yes only when the save's look gives the
same finding (a full folder at least as the yes was given for); otherwise refuse with the new words.

**2. SHOULD FIX (confirmed). Two of the new rules have no test that fails without them, and finding 1 has none.**
`m2` (nesting told one way only: `within(S, L)` without `within(L, S)`): all 14 named tests pass (`mutants-a.txt`,
"m2: 14 passed, 0 failed"). `m4` (the write check run first in `check`, before the look, the nesting and the yes):
all 14 pass ("m4: 14 passed, 0 failed"). Killed as they should be: `m1` the yes not enforced at the save
(TestSetupSaysWhatItSees), `m5` an entry's name put in the count's sentence (TestSetupSaysWhatItSees), `m8` the yes
taken for any path (TestSetupSaysWhatItSees), `m9` the change taken without its confirm (TestChangeFoldersFromRunning),
`m10` the mark's name changed (TestStagingMarkNameIsTheCollectors). Baseline `m0`: 14 of 14 pass. Wanted: a library
inside the staging folder refused; a full or unlistable folder without the yes left with no write-check file made
in it (a folder the test can see written into, e.g. a watcher counting creations, or a stand-in `folderWords`);
finding 1's case.

**3. SHOULD FIX (plausible, read). Saved folders are never looked at: an existing `tgarchive.json` starts without a
look, and Cancel on the change's setup starts against a folder the same page has just said needs the yes.** `run`
calls `setup` only for a missing file, a missing folder or a change; `begin` uses the saved values. After this
build is installed, the owner's current file (the old app's library, given at 78739d59 without any yes) starts
silently; if the owner opens "Change the folders", sees "This folder is not empty: 199 things ..." and presses
Cancel, the same folder is started again (TestChangeFoldersCancelKeepsSaved shows Cancel starting with the saved
library). Fix: store the yes with the path in the settings (`library_confirmed` / `staging_confirmed`), show the
setup at a start whose saved library or staging folder is full and has no stored yes, and offer Cancel only when the
saved folders need no new yes (or say on Cancel's line that it starts with a folder that needs the yes).

**4. SHOULD FIX (plausible, read). The data folder gets no second yes.** A data folder that is not empty and holds
no archive is said ("No archive is in this folder (N things are directly in it): a new, empty archive is made here,
in a folder named catalog") and then written into: `MkdirAll`, the write check, then `catalog` and `logs` by the
programs. Picking another program's folder as data is the same mistake as today's. And a data folder whose look got
no answer (`wordDataNoAnswer`) is then made and write-checked on the page's request goroutine without a bound. Fix:
the same second yes as the library for a full folder without `catalog\catalog.sqlite`, and for one that did not
answer.

**5. SHOULD FIX (plausible, read). "Change the folders" is offered on refusals where something of this folder may
still run, and the change does not look before it shows the setup.** `refuse` now sets `change: true` for every
refusal, including 4 ("The watchdog's marker file cannot be read ... check that no tgarchive-collector runs"), 2
(another tgarchive answers on the pages' address), 3 and 11 (an update under way). `waitOwner` takes the change with
no `findLeft`; a new data folder then moves the marker check to the new folder, so the marker refusal is passed by.
What still stops a second collector is only the pages' address check in `begin` (an old collector that serves its
pages there). Settings saying new folders while an old program runs on the old ones is the case question 2 asks
about. Fix: offer the change only on refusals the folders can be behind (1, 5 to 10, the ends), or run `findLeft`
with the saved layout before the setup and refuse the change while anything of this folder runs.

**6. SHOULD FIX (plausible, read). The change's "Stopping" view has no bound and no way back to the pages.**
`changeStop` sets `phaseBusy` with no `pages` link and no button; `follow` waits for the watchdog without a bound.
A stop held for a sign-in (the server's `stopheld.go`: Ctrl-C is held while a code is awaited, up to the hold's
minutes) leaves the owner on "Stopping the app's programs ... The setup comes next." with nothing to press and no
link to the pages where the code (or "Quit now") would be typed. Fix: keep the pages' link on that view, and after a
bound say what holds it (the watchdog's own status says waiting/stopping) with Stop what is left as elsewhere.

**7. MINOR (confirmed). Nesting is told by names only, and the page does not say what cannot be told.** Probe P2
`TestReviewG19Nest` (the disk lines checked on a real folder): not refused although the same or nested folder: a UNC
share root and the same root with a trailing separator ("refused ... staging false"); the long-path prefix `\\?\`
(disk: "names the library's own sub-folder: true"); a trailing dot on a component (disk: true); the 8.3 short name
(disk: true); the admin share `\\localhost\C$\...`; a mapped drive beside its UNC name (cannot be built here: by names
it cannot be told). Refused as wanted: forward slashes, `..`, another case, a trailing separator, relative paths, a
folder in `programs`. Not refused at all: the library or staging folder being or holding the app's own folder, the
data folder inside or equal to the library or staging folder (all "refused false"). The package already has
`fileID` (volume serial and file index, or the final path) in `proc_windows.go`: equality and the parents' chain by
identity would tell all but the unreachable share; a line under the refusal could say that a mapped drive and its
network name are not told apart. Also seen on the page (setup-full-nested-wide.png): a staging folder already refused
as nested still shows "Use this folder anyway" under its refusal; the box should not be offered on a refused folder.

**8. MINOR (confirmed). Looks at a share that never answers pile up.** Probe P3 `TestReviewG19LookPile`: "goroutines
held after 50 setups looked at a share that never answers: 150" (three per setup, no bound on their number; each one
blocked in a system call holds a thread). Pressing Save repeatedly on a dead share is the way to grow it. Also
unbounded on the run loop's goroutine (setup()→setupViewOf): `freeWords` (GetDiskFreeSpaceEx), `missingFolders`
(`isDir`), and after a look `isFile` of the catalogue and `folderFacts` (Stat), on a share that stops answering
between the look and these. Fix: one look in flight per path (a later look of the same path waits for or reuses the
first), and the free-space and stat calls under the same bound.

**9. MINOR (confirmed). A `launcher_addr` the launcher takes can make every start refused.** `loopbackAddr` takes
`127.0.0.1:08786` and `127.0.0.1:+8786` (strconv.Atoi), `collectorArgs` passes `http://` + that, and the collector's
`CleanLauncherURL` refuses both (probe P6 `TestReviewG19CleanLauncherURL`: `"http://127.0.0.1:08786" -> ok false`,
`"http://127.0.0.1:+8786" -> ok false`), so the collector exits refused at every start. Only a hand-edited file
does this; build the argument from `portOf` (or from the launcher's own listener's address).

**10. MINOR (confirmed). With the flag absent the pages are not byte for byte the head's.** Probe P7
`TestReviewG19LookSettings`: `/` is 2,503 bytes with and without the flag and holds the new hidden `open-launcher`
link in both; `/api/state` has no `launcher_url` without it (538 against 578 bytes: right); the Settings page asks
`GET /api/program` at every visit and gets 404 (a console error in a browser), leaving an empty `program-slot`. No
visible change; say so in the report rather than "nothing changes".

**11. MINOR (read). Words.** "1 things are directly in it" (seen on the page; countWords needs the singular). The
staging sentence of B ("what it finds neither there nor in the new staging folder it downloads again") is true but
leaves out that the copier makes at most 20 files an hour wanted again and then holds them until the owner releases
them (`store/guard.go`, WantAgainCap). The count is every `file` row (`catalog/stats.go`), lost ones too: "saved
files" is near enough. The confirm region leaves the plain "Change the folders" button under it (pressing it again
only asks again).

**12. Not a defect: the log rule.** `TestLauncherLogNoPathsOrNames` does not run the change flow; its new formats
are numbers only. Probe P5 `TestReviewG19LookChange` ran a change and Cancel and read the log: "19 lines; a path or
name in it false; change lines 3". The page's answers and the look's output hold numbers and fixed words only (the
mark's name is a fixed word); `m5` shows the test catches a name.

## The questions in order

**1.** The yes is enforced at the save on the launcher's side (`checkSetup` looks again; `m1` and `m8` killed): a
save by hand without it, a yes for another path, the path changed after the yes (the hidden `library_seen` differs)
and the library's yes used for staging (separate fields) are all refused, through the first setup and the change
alike (one `checkSetup`). The holes: finding 1 (a yes carried across what was seen), 3 (saved folders and Cancel), 4
(the data folder). A folder that fills between the look and the save cannot pass (the look is at the save). Nesting:
finding 7. The write check now runs only after the look, the nesting and the yes on the save's path (read; no test,
finding 2); the only other writes before a yes are the data folder's (finding 4).

**2.** From a running app: one confirm (held per view number, dropped by any new view), Ctrl-C as at Quit, the
viewer closed, the setup with Cancel; nothing started before Save or Cancel (TestChangeFoldersFromRunning, `m9`).
Twice or in two windows: the view number lets one through, the other gets "not now" (a bare text, as before). A
click during a start before the pages' bound is not offered (busy view). A held stop: finding 6. A watchdog that
does not end: no bound (finding 6); a collector left without it is said with Stop what is left (`changeEnded`).
Pages that do not answer the count: 3 s, "not known". Save and start that fails: the refusal offers the change again.
The launcher ended in the middle: nothing is written before Save, so the next start runs the saved (old) folders,
consistent. Refusals: finding 5. The new POST actions go through `act` (same-origin, token, view number); the
confirm lives only for its view.

**3.** The look opens the folder and reads names only (`Readdirnames`, no entry opened, no link of an entry
followed, nothing written; the named folder itself is followed if it is a link, which is right). `isFile` of
`catalog\catalog.sqlite` is a Stat through a `catalog` link if there is one (metadata only). Goroutines: finding 8.
Names: finding 12.

**4.** Each sentence against Core's code: places relative to the library: true (`store/names.go` joinRel, the
copier's `lookInLibrary`). A staged file not found: true, with the cap (finding 11). The mark and the lock: true
(`stagingmark.go`: made once, never removed; `lock.go`: the file stays, empty). A `-library` that differs from the
archive's own `library_dir` is refused at the start: true (`libraryOf`, ErrLibraryDiffers). An archive made by the
launcher has no `library_dir`: true (`server.New` passes no library in program mode; `settings_when.go` refuses a
change of it from the program's Settings). **The owner's steps file: yes, it may go as it is.** Its way works on the
base code: `TestOwnerWayOutSettingsRenamed` run on commit 3f37352b's tree (78739d59's launcher plus that test),
exported to scratch: PASS (`run-etree.txt`). What a careful person will meet that it does not say (worth one line
each, not blocking): the VPN adapter comes back preselected as the default `WindscribeWireguard` (if theirs is named
otherwise, Save says to pick it: pick the one in `tgarchive.json.old`); the Windscribe split-tunnelling entry stays
right (the collector's path does not change); the sign-in is kept (sessions are beside the catalogue in `data`, the
key in `%LOCALAPPDATA%\tgarchive`), so no new code is asked.

**5.** `-launcher-url`: only with `-pages` and only `http://127.0.0.1:PORT` (TestRunLauncherURLRefused passes);
probe P6 refused `localhost`, another address, `[::1]`, `0x7f000001`, `127.0.0.1.`, a path, userinfo, a query with a
value, a backslash trick, port 0 and 65536, a padded port; took upper-case `HTTP`, a trailing `/`, an empty `#` or `?`,
spaces around, and port 80 (loopback still: acceptable). The link and the region are built from the cleaned value
(rebuilt from the port), so they cannot point elsewhere. `GET /api/program` is behind the same guard as every read
(the host list, the cross-site refusal) and gives the library, staging and catalogue paths to the app's own pages
only; 404 without the flag. Flag absent: finding 10.

**6.** Finding 2. Test functions removed or renamed: none (diff read).

**7. What a person sees.** Rendered in Edge headless from the live launcher (stand-ins) and from the saved pages:
`shots/setup-full-nested-wide.png` (the library's "not empty: 5 things" in red with "Use this folder anyway", the
staging folder's nested refusal with the yes box under it (finding 7), the data folder's "An existing archive"),
`shots/confirm-narrow.png` (the change's setup: the four sentences under "What a change of folder means", Save and
start with Cancel and its line), the running view and its confirm read from the saved HTML (the confirm region sits
above the plain button, finding 11). Plain and readable at 1280 px; nothing overlaid. Not judged: the narrow width
(Edge headless drew wider than 390 px and cropped, so no overflow can be told from these shots; the CSS has
`overflow-wrap:anywhere` and fluid fields), and the app's Settings region and header link in a browser (the shots
came out before the script ran; the answers were checked instead, P7). Edge's in-test runs proved unreliable (its
first process returned early); later the track's lock was held as a plain file by another session from 19:41, so a
second server look could not run.

## Not checked
The real watchdog and collector (stand-ins only), the window's gate letting "Program" through in the real window (by
reading `present.go`: the launcher's own address is always allowed), a real share that does not answer (simulated),
a mapped drive, the narrow width, the whole packages, the race detector.

may be listed after these fixes: 1, 2, 3, 4, 5
