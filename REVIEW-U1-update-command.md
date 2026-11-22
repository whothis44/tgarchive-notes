# Review of U1, the owner's update command (pages, P7, 2026-11-21)

Read: `BRIEF-P7-review-U1.md`, the house rules, the two memory notes, the brief `BRIEF-U1-update-command.md`, the
coder's report, `archiver/deploy/folder/update-folder.ps1` whole, the diffs of `make-folder.sh` and `README.txt`
(`wip/pages-update` 0286f6e8 against 6aa225fb, in the detached copy `wt-pages-review-u1-scratch`), and at 70b0c7e
`internal/launcher` (`launcher.go` `run`, `begin`, `refuse`, `another`, `second`, `waitOwner`; `present.go`
`showPage`, `startWindow`, `spawnWindow`, `windowLine`; `folder.go` `LayoutOf`; `settings.go` `Resolve`) and
`cmd/tgarchive-window` (the joined form with `-db`). `internal/launcher` is unchanged from 70b0c7e to 0286f6e8 apart
from a test.
Ran (scratch folders under `...\Temp\p7-u1rev\` only, LOCALAPPDATA, APPDATA, TEMP, TMP redirected there, the
coder's builds copied in, the head's script, a windowless stand-in as `tgarchive.exe`, `-NoStart` everywhere,
invented bytes only, every output to a file): `probe-rename-running.ps1`, `probe-q2-start-during.ps1`,
`probe-q1-goback.ps1`, `probe-q3-kill-goback.ps1`, a mistyped switch. No go command was needed. No process left
under the scratch folder at the end (count 0). Line numbers below are of `update-folder.ps1` at 0286f6e8 (the piece
is not on af4ca40e).

## Findings

1. **MUST FIX** (confirmed: `probe-q3-kill-goback.ps1`). **-GoBack copies the catalogue back inside its
   all-or-nothing list, straight onto the live name, so an interruption during that copy leaves a torn catalogue
   with no record.** Lines 476-481 and 505: the current catalogue's files are moved aside, then each file of the
   copy is copied (`Copy-Checked`, `[IO.File]::Copy`) onto `catalog\<name>`. On a catalogue of real size that copy
   and its two SHA-256 reads take minutes and print nothing. The probe ended the -GoBack process (as closing the
   window does) during that copy of an invented 1600 MB catalogue. Afterwards: `catalog\catalog.sqlite` was there at
   its full length (Windows sets the length before it writes the bytes) but did not equal the copy; the copy's
   `-wal` had not been put back; `updating` was left; nothing was written to stderr; `updating`'s text names no
   step. Ctrl-C is not caught by `trap` and there is no `finally`, so it ends the script the same way.
   *How the owner meets it:* they start the go-back, it sits silent for minutes, they close the window or press
   Ctrl-C. `tgarchive.exe` refuses to start, as it should. README's only advice is "put the files right, then
   delete updating". If they delete `updating`, the app opens a torn catalogue. The real data is not lost (the
   newer catalogue is in `catalog-after-*`, the copy stays), but nothing tells them that.
   *Cure:* copy the catalogue's copy, with the check, into a folder of its own in the data folder (for example
   `data\.back-<stamp>\`) before the list, as the update already does with `.new-<commit>\`. The list then holds
   renames only, each one instant. Also write the planned moves into `updating` (from and to, names inside the
   folders) before `Invoke-Steps`, in both forms, so the file itself says where everything is after any
   interruption.

2. **SHOULD FIX** (confirmed: `probe-q2-start-during.ps1`; the rest by reading 70b0c7e). **A `tgarchive.exe`
   opened during the catalogue's copy is not seen. The update renames its running files under it and then says it
   is done.** The last running check is at line 316, before the copy (lines 319-333) and the staging. The copy can
   take minutes and prints nothing.
   - *What the probe showed:* a stand-in started as `tgarchive.exe` from the folder while `updating` and the copy
     folder existed. The update still moved 15 files and exited with its success words. `updating` was removed.
     The stand-in was still running; Windows renames a running `.exe` without complaint (`probe-rename-running`:
     move ok, still running).
   - *What the real launcher does in that window (70b0c7e, same code at this head):* `begin` (launcher.go:633)
     refuses with 11. It does not end. `run` calls `showPage`, which starts `programs\tgarchive-window.exe` to show
     the refusal (present.go:393-413, 511-597, the window being the default). It then waits for Close or Try again
     (launcher.go:340). So "tgarchive.exe then starts nothing" (head lines 21-22, README) is not quite true: it
     starts its window and stays.
   - *What the script's start then does:* the new `tgarchive.exe` it starts (line 414) finds the launcher's
     address taken. `another` and `second` (launcher.go:371-430) ask the OLD launcher to show its window and end.
     The owner sees "The folder is being updated" after the script said "tgarchive.exe was started". Pressing Try
     again runs the old launcher's start over the new build's watchdog and collector.
   - *How much it matters:* the launcher is the same in both builds today, so that mix works now. In a later
     update, or in a -GoBack (a new launcher over the old programs), one build's launcher drives another build's
     programs.
   - *Cure:* call `Assert-NotRunning` once more right before `Invoke-Steps` in both forms (in the update after the
     staging; in -GoBack after the staging copy of finding 1). At that point nothing has been moved yet: remove
     `.new-*` and `updating`, exit 3, and name the catalogue's copy that stays. Also say one line before the copy:
     "copying the catalogue (N MB), this takes a while: do not open tgarchive.exe".

3. **SHOULD FIX** (confirmed for the unreadable path: `probe-rename-running.ps1`, 4 of 4 protected processes gave
   `Path` = null; the rest by reading). **A program of the app whose path this shell cannot read counts as not
   running.** Line 147 keeps a process only when `$pp -and ...`. A `tgarchive*` process started "as
   administrator", or under another user, has a null `Path` from a normal PowerShell, so it is dropped. Then the
   copy is taken while a collector may be writing: a torn copy can pass the SHA-256 check if no write lands in
   between. The programs are also renamed under the running collector. `make-folder.sh`'s `running()` has the same
   gap.
   *Cure:* treat a process of the app's names with an unreadable path as running: refuse with exit 3 and the words
   "a program of the app runs whose place cannot be read". In addition, open each catalogue file for the copy with
   `FileShare.Read` (a `FileStream` copied to the target). Windows refuses that open while any process holds the
   file for writing, and it keeps a writer from opening the file during the copy. That one change covers this
   case and the copy part of finding 2.

4. **SHOULD FIX** (confirmed: `probe-q1-goback.ps1`, run 3). **-GoBack can take a copy that was already used, and
   then loses more than the words say.** Lines 426-440 pick the newest `catalog-copy-*` whose record says
   `to=<current version>`, with `programs\<kept>\tgarchive.exe` present. Nothing ties the copy to the update that
   put the current programs in.
   - *What the probe did:* update A to B, then -GoBack to A (the copy is used and stays). A writes for a while. B
     is put in again the way `make-folder.sh` does it (A kept in `programs\<A>\`): `make-folder.sh` is the update
     way README described before this piece. Then -GoBack again.
   - *What happened:* exit 0, and the live catalogue went back to the first update's copy. What A wrote after the
     first go-back left the live place (it is kept aside inside `catalog-after-*`). The words said only "Everything
     <B> wrote to the catalogue since then is LOST" and gave the old stamp, not its age.
   - *Cure:* write into `update.txt` the SHA-256 of the `tgarchive.exe` the update put in (and of `VERSION.txt`).
     At -GoBack, refuse a copy whose hash does not match the folder's current files. After a go-back, mark the copy
     as used (a line `used=<stamp>` in its `update.txt`) and skip used copies. Say the copy's age in days in the
     loss words.

5. **MINOR** (by reading). **The trap's exit 4 words (lines 74-75) describe the update even in -GoBack.** They
   point to `.new-<commit>\` and `programs\<commit>\`, but in -GoBack the parts are `catalog-after-*`, the copy and
   `programs\<current>\`. An unexpected error after the full success (line 406 `Remove-Item` of `updating`, line
   528) also says "stopped half way".
   *Cure:* a `$script:phase` ('update', 'goback', 'done') set at each stage, with words for each phase; the journal
   in `updating` from finding 1 then does the rest.

6. **MINOR** (by reading `settings.go` at both commits). **-GoBack does not put `tgarchive.json` back.** Both builds
   write settings version 1 today. A later build that writes version 2 would leave the gone-back folder with a
   launcher that refuses "newer" settings (settings.go:109: refused, never overwritten), so the folder cannot start
   after -GoBack.
   *Cure:* copy `tgarchive.json` into the catalogue's copy folder at the update. At -GoBack put it back (checked)
   and keep the current one aside beside the newer catalogue.

7. **MINOR** (by reading). **The copy's record holds no hashes, so -GoBack never checks the copy folder against
   what was copied.** Anything that opens the copy with SQLite in the meantime (a checkpoint into it, an added
   `-wal`, which `files=` then ignores) goes back unnoticed.
   *Cure:* write each file's SHA-256 (already computed in `Copy-Checked`) into `update.txt`, and check them at
   -GoBack before the mark.

8. **MINOR** (confirmed: the script run with `-Gobak`). **Unknown words on the command line are silently
   ignored,** because there is no `[CmdletBinding()]` and the extras land in `$args`. A mistyped `-GoBack` gives
   "say which folder to update with -Into", and a mistyped `-NoStart` starts the app.
   *Cure:* `if ($args.Count -gt 0) { Refuse "a word on the command line is not one this script knows" }` right
   after `param` (fixed words, no path).

9. **MINOR** (by reading). **The copies are ordered by a local-time stamp compared as text** (lines 281, 437). A
   clock turned back (the end of summer time, a clock correction) can make a newer copy sort as older, and a tie
   keeps the first one found.
   *Cure:* stamp in UTC (`(Get-Date).ToUniversalTime()`).

## Checked and sound

- -GoBack moves aside every one of the four catalogue names present, so a stale `-wal` or `-shm` never stays
  beside the main file put back. probe-q1 run 2: afterwards only the main file, equal to the copy; the 3 newer
  files kept aside.
- A copy with a `-wal` put back over a catalogue without one, and the reverse: the list moves every current name
  and copies every recorded name (by reading lines 454, 476-481).
- `Copy-Checked` compares size and SHA-256 of the source against the copy after copying, and never overwrites or
  removes a file already at the target (lines 194-205).
- The update's catalogue copy is made outside the moves and leaves the source untouched. Exit 6 removes the
  partial copy and `updating` (lines 319-341).
- A second update before any go-back: each copy records its own `to` and `kept`, and the newest one for the
  current version is taken with its kept programs (by reading). Two copies in one second get `-2` from
  `Get-FreeName`.
- The data folder relative or absolute follows the launcher's `Resolve`. Rooted and drive-relative forms are
  refused. A missing `tgarchive.json` means `data`, as the launcher reads it.
- A move that fails in the update puts back every move made, the last first, and exit 5 leaves a folder that
  starts (the coder's R4; the code at lines 213-239 and 382-388).
- The update's long step (the copy) is outside the list, and its list is renames only. A process ended there
  leaves `updating`, so nothing starts on a half folder.
- No parameter shares a name with a variable. The words seen in all probe runs name places inside the folders
  only. A mistyped switch printed no path.

## Not verified

- A real `tgarchive.exe` or window started during an update. Not done on purpose: it needs a real window. The
  launcher's behaviour above is by reading 70b0c7e.
- A really elevated or other-user process: there is no UAC prompt on this PC for a probe. Only the null `Path` of
  protected processes was shown.
- Ctrl-C itself: only the process being ended was tried. That `trap` does not catch Ctrl-C is by reading.
- The exit 4 path (putting back failing too); a data folder behind a junction to another drive, or on the NAS
  (free space and moves there); a disk-full refusal.
- Questions 4 and 5 were covered only as far as the findings above reach. There was no separate pass over every
  exit code's words.
