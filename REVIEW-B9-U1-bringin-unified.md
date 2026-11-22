# Review of U1: the bring-in into the app's own catalogue (`wip/b-unified` 04000899 against af4ca40e), 11-21

Independent Opus review, high effort. Read: the whole diff (into.go, intoplan.go, the run.go / run2.go / config.go
changes, the command), and in `internal/catalog` the paths the mode drives: `ImportSaved`/`importOne`,
`holdOne`, `SaveMessages`/`saveOne` (the edit path), `attach` on a known Telegram file, `MarkDeleted`,
`chosenPolicy`/`newChatPolicy`, `MarkNotCopy`, `UpsertAccount`, `Batch`. Probes on invented data only, in the
scratch worktree `wt-b9-review-U1-scratch` (file `internal/bringin/zz_review_u1_probe_test.go`, not committed),
every go command through `runs-b7/shell/scripts/gorun.sh`. The coder's own `TestIntoApp*` pass (31 s).

## What holds

- Refusals: no `-into-app` gives `ErrNotOurs` as before. A catalogue the bring-in made, a missing or empty one, one
  at another schema version (the check reads `PRAGMA user_version` read-only, before any write handle could
  migrate the file), an app account with the old Telegram user, and an account number that no longer names the
  mode's account are all refused before anything is written. A missing `MarkBroughtIn` stops the run before its
  start mark.
- Rule 2 when the setting `catalog.chosen_only` is set: no rank, collect, kinds or topic rank is written. The old
  choices are kept under `bringin.app.v1.old.choice.*`.
- Rule 5: the bytes both apps saved keep one file row and the app's own place. The old place is added with
  `kept = 0`.
- The guard reads its two snapshots inside the chunk's own transaction (`Batch` makes `tc.r` the transaction),
  so nothing can change between its second read and the commit.
- The dry run opens read-only and does not migrate. It leaves at most an empty `-wal` and a `-shm` next to the
  file, and the test covers that.
- Report words are fixed strings and the output passes `assertPrivate`.

## Findings

**1. Must fix: the floors outlive a cut run, so the resumed run takes the app's newer rows for its own.**
Where: `into.go` 184-205 (`startInto` keeps `floor` until `finishInto`), 514, 787; `run2.go` 447, 474; `appFile` 478.
- A cut run keeps its floors. The cut is the expected path, not a rare one: `ErrWouldChange` stops the run
  whenever an old message carries a file the app holds as not collected, and the coder's own
  `TestIntoAppStopsBeforeChangingAppState` shows this happens. After the stop the owner starts the app again.
- On the resumed run, every Telegram file, file and chat the app made in between has an id above the old floors.
  The mode then treats it as made by itself:
  - `importLeftOut` checks nothing, and `ImportSaved` removes the collector row whatever its state;
  - `holdLeftOut` checks only the pair word, and `HoldProbable` overwrites `keep_held` and the reason;
  - attempts, fingerprints, verified marks and chat facts are written over the app's rows;
  - the guard skips these files.
- Probe P2 (`TestProbeU1FloorsAfterCut`):
  - The run is cut after the first chunk of `peers`, and the floor is kept.
  - The app's accounts then read their collecting forums: 102 new Telegram files with the app's own collector
    rows. The app holds them all as look-alikes, and the owner keeps 51 of them held.
  - The resumed run then:
    - saved 70 of the 102 by old bytes, though none was plainly wanted, owner's keep-held ones among them;
    - held 12 by the old app's rule over the app's own rows;
    - cleared the owner's keep-held on 7.
- The same holds with no cut whenever the collector writes during the run. Nothing stops the mode running beside
  the collector.
- Fix: tell the app's rows from the run's by provenance, not by id:
  - a Telegram file whose collector row or reach names only the old account, or that has no row of an app account;
  - a file whose kept place is the old app's (`broughtIn` already does this for files);
  - a chat whose `account_chat` rows are only the old account's.
- Or take new floors at every start, and record the run's own ids in the mode's keys as it makes them.
- Also, until Core settles section 5 point 3, refuse to run while the collector is running (or say plainly that
  it must be stopped). The checks in `importLeftOut` read outside `ImportSaved`'s transaction, so with a live
  collector a file can be claimed between the check and the import.

**2. Must fix: a plainly wanted file of the app is "saved" by old bytes that the old app's own integrity pass
found bad.**
Where: `into.go` 509-533 (the wanted-to-saved decision); `run2.go` 412-426 (`ix_fixity` problems carried only
afterwards, in the facts stage).
- The condition (same Telegram file; wanted; not kept held; not released; no fetch-for-real) never looks at the
  old copy's own record. `ix_fixity` rows with result missing, changed, size or unreadable are ignored. Then
  `ImportSaved` deletes the app's collector row, and the app never downloads the file.
- Probe P4 (`TestProbeU1FixityProblemSaved`):
  - 304 of the app's plainly wanted files are old saved files of the same Telegram file;
  - one invented `ix_fixity` row marks one of those old copies "missing";
  - after the run that file is saved (no collector row), with a "missing" problem on its bytes.
- That is the worst outcome the brief names: the app skips a file it would have downloaded.
- The same decision also covers the `links` stage. There the bytes come from another Telegram file (the old
  app's part-hash and after-download links). That is exact evidence, but it goes beyond the session's stated
  condition "the same Telegram file". Say so in the rule's words, or limit the decision to the saved stage.
- Fix: leave the file wanted (counted, with fixed words) when the old app's latest integrity result for that
  path is not "ok", or when the path has any problem on record.

**3. Must fix: rule 2 rests on a setting the mode never checks.**
Where: `into.go` 16-19 (the claim), `chatInto` 388-405; `catalog/chosen.go` 165-181,
`schema_mirrorauto.go` 221-247.
- A chat the bring-in makes starts switched off only when `catalog.chosen_only` is present. The collector clears
  that setting under the owner's `-new-chats-download`, and a catalogue may never have had it.
- Without it, `newChatPolicy` makes the chat collecting. For a shared kind this happens because the old account
  has no `NewChatsOff` key.
- Probe P1 (`TestProbeU1ChosenOnlyAbsent`), with the setting cleared:
  - all 16 chats the run made are collecting, 3 of them shared channels;
  - 12 Telegram files the run made are wanted;
  - then the run stopped with `ErrWouldChange`. The collecting chats were already committed, because the chats
    stage runs before the guard.
- A shared channel made collecting this way collects for every app account that later joins it. The bring-in
  has switched on a source the owner never chose.
- Fix: `checkInto` (and the dry run) refuse when `ChosenOnly` is not set and readable, with a fixed sentence.
  Better still, check after each chat the run makes that it was made switched off, and stop if not.

**4. Should fix: the messages and absent stages change the app's own messages in shared spaces, outside the
guard.**
Where: `run.go` 963-1017 (messages through `SaveMessages`), 1096-1113 (absent through `MarkDeleted` on the
shared space); `catalog/tgrows.go` 296-304, 343-433, 600.
- An old record with a later edit date, or other media, than the app's stored message rewrites the app's
  message. Its text, raw bytes and topic change; it gets a version row; its other attachments are marked
  replaced; `roleChanged` and `rejudgeMessage` may move its files.
- The guard compares only the files in the old record that are not plainly wanted. A plainly wanted file turned
  held (an alternative version, or a topic rule), and the app's attachments that are not in the old record, are
  not compared.
- `ix_absent` and `ix_messages.deleted_at` set `deleted_at` on app-sighted channel messages. `carriersSQL` and
  the mirror's candidate filter then drop those messages as carriers.
- Probe P3 (`TestProbeU1AppMessagesTouched`):
  - 20 invented `ix_absent` rows for messages the app read: 0 app-sighted messages deleted before the run, 20
    after;
  - with the app's stored edit date set one second earlier on 50 messages, the run made 50 versions of
    app-sighted messages.
- These are Telegram's facts when the old app's data is right, but they are not "only adds". None of them is
  counted on its own.
- Fix, as a minimum, either way: count them in the report and the dry run.
- Fix: in this mode, a message stored already and sighted by an app account gets only the old account's
  sighting (no new version, no deleted mark).
- Or: widen the guard to every attachment of the touched message, including plainly wanted files moving to
  held, and to the message's `deleted_at`.

**5. Should fix: the dry run cannot tell the owner that the run will stop.**
Where: `intoplan.go` 424.
- The guard's stop is the likely result on real data. The coder's own test makes it with one crossing file, and
  the owner's archive shares 4,507 Telegram files.
- Yet the dry run only prints a note that it does not count the stop.
- Fix: count the attachments of old messages whose Telegram file the app holds in a state the ladder can move.
  That means held as not collected or for chat or topic preference, carried in an old message of a chat that
  collects, or skipped in an always-download chat. Print that count as "would stop the run", so the owner
  learns it before a run writes the first stages.

**6. Should fix: a run again after a finished one treats the first run's rows as the app's.**
Where: `into.go` 161-196 (new floors after `complete`).
- The new floors include the first run's own Telegram files. The holds stage then leaves out every new old-app
  hold on the old account's files as "the app's own collector row".
- So "a second run adds what the old app wrote since" is not true for holds (and attempts). It is safe, but the
  new holds are silently lost.
- The provenance fix of finding 1 covers this too.

**7. Minor: `notcopy` writes the old frame check's "no match" pairs on the app's own files.**
Where: `run2.go` 28-70.
- `ix_copy_sample` "nomatch" pairs are written as `not_copy` rows, including on files of the app.
- No layer reads `not_copy` today, so nothing changes now. But its stated purpose is that a checker does not
  compare the pair again.
- The lessons (answers 8) say a frame "no match" is wrong about 3 times in 4. Once a checker honours `not_copy`,
  these rows would stop the app from comparing its own files.
- Fix: leave out pairs where either end is an app file, or carry them as evidence only.

**8. Minor: the old account's label is empty unless `-account-label` is given.**
Where: `into.go` 294.
- In the app's account list and window the account then has no name.
- Fix: default to a fixed word (for example "old archive") in this mode.

**9. Minor: the dry run returns success on a run that would be refused.**
Where: `intoplan.go` 120-121.
- When the old account's Telegram user is already an app account, it prints "REFUSED" as one count line and
  exits 0.
- Fix: return `ErrAccountTaken` as the run does.

## Verdict

not to be listed

The same commit, with findings 1, 2 and 3 fixed, would be "may be listed after these fixes: 1, 2, 3". Findings
4 and 5 should come in the same round, because without them the dry run and the guard tell the owner less than
the run does.

Counts: must fix 3, should fix 3, minor 3.

## Second pass (fix only): 04000899..a9edc36b, 11-21

I read the whole fix diff: `into.go`, `intoplan.go`, `intoexit.go`, `intocounts.go`, and the changes to `run.go`,
`run2.go`, `config.go` and the command. In `internal/catalog` I read again the paths the fix depends on: `Batch`
and `dsn` (`_txlock=immediate`), `saveOne`, `seenAgain`, `attach`, `wantedAsMainSQL`, `markCheckFirst`,
`UpsertAccount`, and the `tg_media` and `chat` keys (INTEGER PRIMARY KEY with no AUTOINCREMENT).
- My probes were re-run in the scratch worktree, now at a9edc36b, through the lock. P5 to P7 are new.
- The probe file is `internal/bringin/zz_review_u1_probe_test.go`. It is not committed.

### The first-round findings, by probe or by reading

**Finding 1 (floors after a cut): fixed.** Probe P2:
- The run was cut after the first chunk of `peers`.
- The app then read its collecting forums whole: 102 new Telegram files, all held by the app, 51 of them kept
  held by the owner.
- After the resumed run, none of the 102 changed: state, reason and keep-held kept, none held by the old app's
  rule, none saved, no old attempts written on them.

**Findings 1 and 6 (an app account meets a recorded row): fixed.** New probe P5:
- A finished run, then the app read the same forums whole. It met 32 Telegram files the run had made.
- The app held them all and the owner kept half held.
- A run again changed 0 of them and saved 0.

**Finding 2 (an old copy found bad): fixed.** Probe P4: the file whose old copy is marked "missing" stays as it
was, with its collector row (saved 0, row 1). The links stage no longer saves a file of the app at all.

**Finding 3 (the setting chosen_only): fixed.** Probe P1: with the setting cleared, the run is refused with
`ErrIntoChosenOnly` before it writes anything (chats made 0, wanted 0).
- The per-chunk check `recordMade` is sound as a second line. Inserts take max(id)+1 because there is no
  AUTOINCREMENT, and the transaction holds the writer from BEGIN, so the walk from the mark up to the first
  missing id sees every row the chunk made.

**Finding 4 (the app's messages): fixed.** Probe P3, with the same 20 injected `ix_absent` rows and the same 50
earlier edit dates as in round one:
- app-sighted messages marked deleted: 0 before, 0 after;
- versions of app-sighted messages: 0 before, 0 after.

**Findings 5 and 9 (the dry run): fixed for the case tested, with a gap (finding 1 below).** Probe P6, on the
crossing fixture: the dry run returns `ErrWouldStop` with the count at 1, and the run stops with
`ErrWouldChange`.

**Findings 7 and 8: fixed** (by reading).

### The three things the coordinator asked about

**Can the record of the mode's own rows be fooled? I found no way that harms the app.**
- *A cut between a door's call and its record* (`recordFresh` after `ImportSaved`):
  - The Telegram files that door call made stay off the record, so they count as the app's for good.
  - Every one of them is saved, by the door that made it. Nothing the mode then leaves out applies to a saved file
    (holds, attempts, rule 3's checks).
  - So the cost is nothing beyond how they are counted. The fix's doc says this is the intended direction.
- *An app account meeting a recorded row:* `appTouched` looks for an app sighting, app reach or an app fetch, and
  P5 shows it working.
  - `Saved` and `ImportSaved` delete reach, but the sighting and the fetch row stay, so a file the app saved is
    still seen as met.
- *Ids used again:* both keys can reuse the largest id once its row is gone. A reused id on the record is still
  the app's whenever the app's row has a sighting, reach or fetch, and every path by which the app makes a
  Telegram file writes one of those (the ladder writes reach and a sighting).
  - A chat on the record with an app `account_chat` row is the app's.
  - Not exercised by a probe (no code path deletes those rows today); this is from reading.

**Does `EditDate = -1` (`run.go` 1071) do anything in `saveOne` besides "stale"? No.**
- What runs before the stale check:
  - the Empty branch: the mode now skips an Empty record for an app message before it reaches `saveOne`;
  - the SelfDestruct clearing of media: harmless here, because the function returns at the stale check;
  - `seenAgain`: the old account's sighting and its reach (`reachOf`), which is the intended effect.
- Every stored edit date is 0 or more, so -1 is always stale. `SavePage` passes the record only into
  `SaveMessages`.
- A message the app has not stored never gets -1: `msgState` finds the message first.

### New findings

**1. Should fix: the dry run still misses stops the run makes.**
Where: `intoplan.go` 190.
- The dry run's `movable` list counts only files held for chat or topic preference, or as an alternative
  version.
- But the guard also stops on the other changes `wantedAsMain` makes. In `ladder.go` 1118-1127 and
  `markCheckFirst`:
  - a file held as a probable copy (same post, look-alike, exact-probable, or the old app's reason) with
    `probable = 0`, because it was first met where it was not collected, becomes `probable = 1`;
  - such a file that is released or set to be fetched for real becomes wanted;
  - a look-alike video can get its check-first mark.
- New probe P7, on the crossing fixture:
  - the app's 72 held files of its off forum are held again as look-alikes (probable 0, as the app's own
    rungs leave them in a chat that does not collect);
  - the dry run then reports no stop (the count line is absent);
  - the run stops with `ErrWouldChange`.
- This case is common in the owner's catalogue: under chosen_only most chats are off, so most of the app's
  look-alikes there are held with probable 0.
- The run itself stays safe (the chunk is undone and the run can be resumed). But the launcher reads the dry
  run's exit 4 to decide whether to start, and the stages before `messages` are written before the stop.
- Fix: count, in the dry run, the conditions of `wantedAsMainSQL`'s four statements and `markCheckFirst`. Or
  better, have the catalogue give one read-only door, "would `wantedAsMain` change this file", that both the
  guard's tests and the dry run use.

**2. Minor: the messages stage still marks an app channel a forum on the old app's flag.**
Where: `run.go` messages stage (`t.Forum = c.forum`), through `SaveMessages` and `ensureTgChat`
(`catalog/tgrows.go` 167).
- The chats stage now keeps the app's own kind.
- But each old message is saved with the old app's forum flag, and `ensureTgChat` sets `kind = 'forum'` on a
  chat row that is not one. So an app channel that the old app last saw as a forum changes kind.
- Fix: in this mode, take `Forum` from the chat row (as `chatInto` does).

**3. Minor: privacy of the machine lines and of stderr.**
- `Counts` prints keys `account.<row id>....` (`intocounts.go` 149). These are catalogue row ids, not Telegram
  ids, but CLAUDE.md says "never ... IDs". The launcher could use the account's order or label instead; say
  which in the contract.
- `main.go` prints `err.Error()` to stderr. An `OpenError` that wraps an operating-system error carries the
  file's path.

### Verdict (second pass)

may be listed

New findings: must fix 0, should fix 1, minor 2.
- The should-fix (the dry run's stop count) belongs in the next round, before the launcher relies on the dry
  run's exit 4.
- All nine first-round findings are fixed.
