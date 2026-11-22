# Review G19b: the fix round of "Change the folders" (pages, P7, 2026-11-21), independent

Read: the round's commits b8e7eec0 (the "Program" entry and the merge's launcher parts), 0bfdc914, 82735c18, e5c31c69,
192c9689, 7665014a, 1a498355, e6bc8a69, 32c5d12e, and on the head af4ca40e (identical to 32c5d12e for these packages)
`internal/launcher` change.go, folders.go, look.go, choose.go, launcher.go (run loop, setup, savedLooked/savedUnlooked,
begin, follow, refuse, changeLeft, waitOwner, ended/endedOther), settings.go, ui.go (act, take, checkSetup, makeData,
folderWords), page.go, start.go, words.go, the round's tests; `internal/server` launcherlink.go and the guard;
`internal/appshell` shell.go and shell.js; the predecessor's settings reader (3cfea81a); the coder's report and steps
file; the first review. Ran (all through `runs-pages-p6/go1.sh`, named tests only, `LOCALAPPDATA`/`APPDATA`/`TEMP`/`TMP`
redirected into the scratch copy, stand-ins only, nothing of the owner's program, folders, settings or `E:` touched):
the 25 G19/G19b launcher tests as baseline (25 passed) and against 23 mutants by `-overlay`; probes
`TestZZProbeStoredYesOnNoAnswer`, `TestZZProbeCancelAfterGrowth`, `TestZZProbeLook{Setup,Change,Slow}` (launcher),
`TestZZProbeProgramRoute` (server); the named tests `TestLauncherLinkOnlyWhenGiven`, `TestShellProgramOnlyWithLauncherURL`,
`TestEmptyCatalogueRoutesListed` (server), `TestListProgramOnlyWithLauncher` (appshell), `TestRunLauncherURLRefused`
(collector): all pass. Headless Edge shots of the live stand-in launcher. Everything is in
`wt-pages-review-g19b-scratch` (uncommitted `zz_probe_*`): outputs in `zz_probe_out/`, mutants in `zz_probe_mut/`
(`make.sh`, `run.sh`, one folder and overlay per mutant), shots in `zz_probe_shots/`.

## Findings

**1. SHOULD FIX (confirmed). The settings' record of a look (`library_looked`, `staging_looked`) is bound to the path
only, so a yes given on "cannot be looked at now" is kept for good: no later start ever looks at that folder again,
though it now answers and is full.** ui.go:1156 records both folders at every save of the setup, whatever the look
saw; launcher.go:569 `savedLooked` compares paths only, and launcher.go:307 skips `savedUnlooked` for them. This is
finding 1 of the first review moved one step later: the owner's library is on the NAS over Wi-Fi, a look over 2 s at
a cold start is the likely case, and the owner who ticks the box on "cannot be looked at now" has never been shown
what is in that folder, yet is never asked again. Probe `TestZZProbeStoredYesOnNoAnswer`: first save "code 200; says
no answer true; saw no-answer"; save with that yes while the save cannot look either "code 303"; "library_looked set
true"; then the folder answers with 4 entries and the launcher starts again: "setup shown false; watchdog started
true". Cure: store what the look saw with the record (for example `library_looked_saw`, the same words as the form's
`library_saw`) and treat a record made on "no-answer" or "not-listed" as no record: the next start looks (bounded) and
shows the setup when it now sees entries; a record made on entries stands (the app fills its own library).

**2. SHOULD FIX (confirmed). Six of the round's rules have no test that fails without them; one of them had a test
in round 1 that this round lost.** Mutants run against the 25 named G19/G19b tests (`zz_probe_mut/results.txt`,
`zz_probe_out/mut-*.txt`), each surviving with 25 passed, 0 failed:
- `m8`, the yes taken for any path (folders.go:190 without `t.librarySeen == sv.LibrarySeen`): killed in round 1 by
  `TestSetupSaysWhatItSees`, now survives: that test's "yes given for another path" form carries no `library_saw`, so it
  is refused for the missing saw, not for the path. The owner meets the rule when he ticks the box for one folder, then
  types another path in the field and presses Save.
- `n1s` and `n1d`, the staging folder's and the data folder's `yesCovers` dropped (folders.go:193, :197): only the
  library's cover is tested (`TestSetupYesBelongsToWhatWasShown`).
- `n3b`, Cancel offered on every change's setup (launcher.go:523 without `savedLooked()`): no test has a change's setup
  over a saved folder without a record.
- `n4b`, the data folder's making and write check without their bound (ui.go:1012 `makeData` with an hour's timer):
  no test has a data folder that stops answering at the save.
- `n5c`, `changeEnded` going to the setup over a watchdog running again or an unreadable marker (change.go:79-88
  switch disabled): no test.
Cure: one case each (the form with `library_saw` right and `library_seen` another path; a staging and a data yes on
fewer entries than seen at the save; a change from a run whose start found the programs running; a data folder whose
look answers and whose making does not, by a stand-in for `os.MkdirAll` or `writeCheckTemp`; a marker made unreadable
between the stop and its end).

**3. SHOULD FIX (by reading; the coder's report says the same). An older build of the launcher refuses a settings
file this build wrote, with words that tell the owner to correct it or move it away.** settings.go:20 keeps
`settingsVersion = 1` while the file gains `library_looked` and `staging_looked`; every earlier launcher (3cfea81a's
settings.go:103-107, `dec.DisallowUnknownFields()`) reads such a file as `SettingsUnreadable` and shows "The settings
file tgarchive.json cannot be read. It was left as it is: correct it or move it away, then try again. Nothing was
started." The owner's own file is in this state now (see question 3), and the folder keeps earlier programs
(`make-folder.sh` keeps them): going back to one of them means nothing starts, and the words lead to moving the file
away, which loses the adapter, the run flags and the addresses saved in it. Nothing is lost by the program itself (it
never overwrites the file). Cure: `settingsVersion = 2` for a file with the new fields (this build reads 1 and 2), so
an earlier launcher says "written by a newer version of this program", which is true.

**4. MINOR (confirmed, shot). Under a folder refused for where it is, the box "Use this folder anyway" is gone, but the
look's sentence beside it still ends "Choose an empty folder, or confirm: 'Use this folder anyway'".** words.go:177-178
and :187 are said by folderSees/dataSees whatever the nesting; `noYesWhereRefused` (folders.go:172) removes only the
box. Seen in `zz_probe_shots/setup-1400-light.png` and `setup-390-light.png`: the staging folder inside the library
shows the red nesting refusal, then "This folder is not empty: 1 thing is directly in it ... or confirm: 'Use this
folder anyway'." with nothing to confirm. Cure: when the folder is refused for where it is, say the count without
its last sentence (or say nothing of the look).

**5. MINOR (confirmed). The change's setup calls the app's own saved library "not empty ... If it is another
program's library" and asks the yes for it, while its Cancel (offered) starts with that same folder.** Probe
`TestZZProbeCancelAfterGrowth`: a run with recorded folders; the library fills as the copier fills it; "Change the
folders": "Cancel offered true; the yes box for the library true"; Cancel "started again true". By the round's rule
the record is the owner's yes, so Cancel is right; but the words contradict it, and an owner who wants to change only
the staging folder must tick the alarming box for his own library. Cure: when the folder in the field is the saved and
recorded one, say "the library saved now: N things are directly in it" and ask no yes (finding 1's record kept with
what it was given on).

**6. MINOR (by reading). Finding 6 of round 1 is cured in part: a stop for a change that never ends while the pages
do not answer leaves the owner with nothing to press.** change.go:52 `changeSlowView` adds the words and, only while
the pages answer with their mark, the link; the view is `phaseBusy` (ui.go render: refresh every 2 s, no Close, no
other button), and the watchdog's own status (waiting or stopping) is not read. Seen in
`zz_probe_shots/slowstill-390-dark.png` (the pages answering: the words and the link, no button). When the collector
has closed its pages (its gate answers "stopping": no link) and its stop hangs, the page repeats the words every 10 s
with no way on but the window's close box (whose Quit sends one more Ctrl-C). Cure: after the bound, say the
watchdog's status line (as the running view does) and offer "Close the launcher" (the programs keep stopping by
themselves) or, if the launcher has it, the orphan's "End it now" once the watchdog has ended and a collector is left.

**7. MINOR (by reading). The "never looked at" box appears on a change's setup with words that may be false.**
launcher.go:524 sets `Unlooked` whenever the record is missing; the record is missing on a run the launcher found
already running (`savedUnlooked`, launcher.go:582-616, looks at nothing while something of this folder runs). After
"Change the folders" from such a run the page says the saved folder "is not empty, or it could not be looked at:
nothing was started", though the app was running a moment before and the folders may be empty or marked. Cure: on a
change's setup, set `Unlooked` only when the look of this setup needs the owner for a folder without a record, and say
"was not started again" there.

**8. MINOR (by reading). A yes on "cannot be looked at now" for the library or the staging folder runs the write
check on the page's request without a bound.** ui.go:1081-1099: for a folder whose save look also gets no answer, `check`
skips `folderFacts` and ends in `folderWords` (ui.go:1037: `os.Stat`, then `CreateTemp`) on the request goroutine; a
share that does not answer holds that request (the window shows a page loading) until the system gives up, and then
most likely says "This folder does not exist". This round gave the data folder's making and write check a bound
(`makeData`), not these two. Cure: the same bounded call as `makeData` for the library's and the staging folder's write
check.

**9. MINOR (by reading). The save trusts what the form says the page showed.** `fillYes` compares the save's look with
the hidden `library_saw`/`staging_saw`/`data_saw` the form carries (ui.go `typedOf`); the launcher keeps the view it
showed (`v.setup.LibrarySaw` etc.) but does not use it. Only a form edited by hand can widen a yes (for example
`entries-99999`), which needs the run's token, so this is no hole from outside; but the launcher's own copy would make
the rule hold by construction. Cure: take `saw` from `v.setup` (the view number already ties the form to it).

**10. MINOR (by reading). Cancel is offered on a change's setup that says a saved folder is missing, and starts with
it.** launcher.go:514-523: `missing` is said (`Missing`), `Cancel = change && savedLooked()` ignores it, and `begin`
(launcher.go:624) does not check the folders. Seen only when the NAS share is not there at the change. Unchanged from
round 1. Cure: no Cancel while `missing != ""`.

**11. MINOR (by reading). Left as they were by the round, as its report says:** round 1's finding 7 except the box (nesting
by names only; nothing said of a mapped drive beside its network name; the data folder inside the library or the
staging folder not refused), 8 (looks piling up on a dead share; the free-space and stat calls of the setup on the run
loop without a bound), 9 (start.go:172 still passes `"http://"+s.LauncherAddr`: a hand-edited `127.0.0.1:08786` makes
every start refused), 10 (the Settings page still asks `GET /api/program` without the flag and gets a 404: said in the
report, nothing visible), 11's last part (the plain "Change the folders" button stays under its own confirm: seen in
`confirm-1400-dark.png`).

## Checked and sound

Question 1, round 1's findings on af4ca40e (mutant results: killed means at least one named test failed):
- 1 MUST: cured for the setup (`folderSees` carries `saw`, `yesCovers` at the save; `TestSetupYesBelongsToWhatWasShown`,
  `TestYesCovers`). Mutant `n1` (any yes covers): killed by both; `n1g` (more entries covered): killed by both. Its
  record in the settings: finding 1 above. Staging and data covers untested: finding 2.
- 2 SHOULD: cured. `m2` (nesting one way) killed by `TestNestRefusedBothWays` and `TestSetupWritesOnlyAfterTheYes`;
  `m4` (write check first) killed by `TestSetupWritesOnlyAfterTheYes`.
- 3 SHOULD: cured in part. `n3a` (no look at a start) killed by 5 tests incl. `TestSavedFoldersLookedAtBeforeTheStart`;
  `n3c` (no record at a save) killed by `TestSavedFoldersLookedAtBeforeTheStart`; `n3b` survives (finding 2); the
  record's binding (finding 1); an older build (finding 3); words (5, 7).
- 4 SHOULD: cured. `n4a` (data yes not enforced) killed by `TestSetupDataFolderNeedsTheYes`; `n4b` survives (finding 2).
- 5 SHOULD: cured. `n5a` (change after every refusal) killed by `TestChangeNotOfferedOverUnreadableMarker`; `n5b`
  (no check before the setup) killed by `TestChangeFoldersLooksForWhatRunsFirst`; `n5c` survives (finding 2).
- 6 SHOULD: cured in part (finding 6). `n6` (no bound) and `n6b` (no link) killed by `TestChangeStopSlowSaysSoWithThePages`.
- 7 MINOR: the box under a refused folder removed (`n7a` killed by `TestSetupWritesOnlyAfterTheYes`); its sentence
  (finding 4); the rest left (finding 11).
- 8, 9, 10 MINOR: not changed (finding 11; 10 is said in the report).
- 11 MINOR: "1 thing is" (`n7b` killed by `TestThingsWords`; seen on the page); the staging sentence quotes the copier's
  limit truly (store/copier.go:239-240: `WantAgainCap` 20 when unset, and the collector passes no other by default;
  held until released on the Staging page: store/guard.go:210); the plain button under the confirm left (finding 11).
- Round 1's mutants re-run on the head: `m1` killed (3 tests), `m2` killed, `m4` killed, `m8` survives (finding 2), `m9`
  killed (`TestChangeFoldersFromRunning`), `m10` killed (`TestStagingMarkNameIsTheCollectors`). `m5` not rebuilt: the
  head's look keeps no names (look.go `lookNow` counts only), so an entry's name cannot reach a sentence without a
  new field; the tests also check that no invented name appears.

Question 2, finding 1's cure: the folder that fills between the look and the save is refused with the new words and
asked again (`TestSetupYesBelongsToWhatWasShown`, the probe's second save); a yes on "no answer" is not taken when the
save sees entries; a share that answers the look and not the save is refused (`yesCovers(entries-N, no-answer)` false,
`TestYesCovers`); a yes from an older page (back button, a second tab) cannot be used at all: every POST carries the view
number and a refused save gives a new one (ui.go `act`, `take`), so only the latest page saves; an overflowing count
(`strconv.Atoi` error) or a negative one is no cover (folders.go:83-86, `TestYesCovers` rows); a hand-edited form:
finding 9. A folder replaced by another of the same path with as many entries or fewer is covered, as the brief's rule
says ("N or fewer"): the look counts, it cannot tell two folders apart.

Question 3: the new fields read by this build from an older file: absent, so `savedUnlooked` looks (2 s bounded,
library and staging) before anything starts; empty, or staging with the collector's mark: recorded, and the start goes
on (`TestSavedEmptyFoldersRecordedAtTheStart`); else nothing starts, the setup shows "The library or the staging folder
saved earlier was never looked at ...", each folder's look, the yes box, no Cancel, and Close the launcher. Nothing is
looked at while something of this folder runs (the start follows it; the look comes at the next start). **The owner's
own file, by reading only:** it was written by the build at 78739d59 or earlier, so it had neither field. At the first
start of a build holding this round, if no program of the folder was running, the launcher looked at the saved library
and staging folder before starting anything; the library holds files (the copier has been filling it), so nothing was
started and the setup was shown with the "never looked at" box and "This folder is not empty: N things are directly in
it ..." and the yes box under the library (the staging folder, carrying the collector's mark, needed none). The owner's
"Save and start" with the box ticked wrote both fields; every start since goes on without a look. If that first look
got no answer within 2 s, the page said "cannot be looked at now" and the yes was recorded without any look (finding 1).
Since then the file can no longer be read by any earlier launcher (finding 3).

Question 4: "Change the folders" is offered on the running view (`phaseRunning` with `watching`), after refusals 1 and 5
to 10, and on the end views of `ended`/`endedOther`; every one of the failed views goes through `changeLeft` (the
marker, a watchdog, a collector of this folder, with the saved layout) before the setup, and the running view through
the clean stop and `changeEnded` (an orphan, a watchdog again, an unreadable marker: no setup). The viewer the launcher
started is closed before the setup. No offered state was found where a collector or watchdog of this folder may still
run and the setup is shown. Outside the change: a setup for a missing folder (launcher.go:307) is shown without
`findLeft`; reachable only when the launcher starts again while the programs run and the share is away; `begin`'s pages'
address check then refuses a second collector (as before this round). The Stopping view's bound: finding 6.

Question 5: the data folder's yes holds the same rules (the same `yesCovers`, `data_saw`, the view number); nothing is
made or written in a full or silent data folder before the yes (`TestSetupDataFolderNeedsTheYes`: no write check, no
entry made); the app's own `catalog` and `logs` alone need no yes; an existing catalogue needs none and is said. Its
cover is not tested (finding 2). The words: "1 thing is" in all three sentences (shots).

Question 6: `GET /api/program` goes through the same guard as every route: probe `TestZZProbeProgramRoute`: own host
200; another host name 421; a cross-site and a same-site fetch 403; POST 403. It answers four fields: `launcher_url`
(rebuilt from the cleaned port) and three paths, the library, the staging folder and the catalogue file: paths, not
numbers, by design of G19 D (the Settings region shows the owner his folders), to the app's own pages only; nothing of
a chat or a file. The list's "Program" entry exists only with `-launcher-url` (`TestShellProgramOnlyWithLauncherURL`,
`TestListProgramOnlyWithLauncher` pass) and is a plain link to the launcher's page. Without the flag: no entry, no
`launcher_url` in the state, the route 404 (`TestLauncherLinkOnlyWhenGiven`, `TestEmptyCatalogueRoutesListed`); the
collector refuses a bad `-launcher-url` (`TestRunLauncherURLRefused`).

Question 7, the headless look (Edge `--headless=new`, its own profile in the scratch copy, outgoing requests sent to a
dead proxy): the setup (full library, staging inside it, full data folder), the running view, its confirm, the change's
setup, the slow stop, at 1400x900 and 390 wide, light and dark (`zz_probe_shots/*-1400-*.png`, `*-390-*.png`,
`changebottom-390-light.png`, `slowstill-390-dark.png`). Edge headless keeps its window at least 492 px wide (a test page
reports `492x708`), so the 390 px shots are the page's saved HTML inside a 390 px frame: the media queries then see
390 px. At 390: no horizontal overflow, long paths cut inside their fields, the collector's path wraps in its box, the
buttons fit; dark and light both readable, the refusals red, the look's sentences grey. Seen: finding 4, finding 11's
button.

Also sound: the merge of G18 into the run loop (the window's close after a refused start; the change goes straight
to the setup); the log formats of the round are fixed words and numbers (`logChangeHeld`, `logChangeSlow`,
`logSavedLooked`, `logSavedUnlooked` are in the log test's lists).

## Not verified

The real window (WebView2) showing "Program" and the launcher's page: not verified, needs a real window. The owner's
real first start after the rebuild (read from the code only; the owner's files were not opened). A real share that does
not answer (simulated with a stand-in listing) and the time a blocked `os.Stat` on one takes (finding 8). An earlier
launcher actually run on a file with the new fields (finding 3 is from its code). The real collector's and watchdog's
stop under a held sign-in (stand-ins). Whole packages and the race detector (not run, per the rules).
