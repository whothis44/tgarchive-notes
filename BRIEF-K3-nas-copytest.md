# Brief K3: a small copy to a test folder on the NAS, as one owner-started test (Core, 2026-11-15)

For one Opus coder. Step 4 of the board's order, first part: "a small copy to a test folder on the NAS with the
helper". Roadmap rows it is to move from "fake" towards "real": the verified copy to the library on the NAS,
the NAS helper's hash with the read-back as fallback, copies at once chosen by itself, hard links. You work in
the copy `C:\Users\trabi\Claude\Projects\Telegram\wt-core-nastest`, branch `wip/core-nastest` (cut from the
main head d1af260), Go module in `archiver/`.

## What the old app already knows (its numbers; `TRIED-BEFORE.md` 8 and 16, answers 7 and 8, read by the Core session)

- The library is a NAS over Wi-Fi: about 14 MB/s each way (14.8 out, 14.5 in on 11-09); the best hour on
  record 14.0 MB/s in all with 8 copies at once (50,532 MB). Copies ran at 1.5 to 2.1 MB/s each for files of
  about 20 MB whether 3, 6 or 8 ran; files of 300 to 430 MB moved at 3.6 to 4.3 MB/s per copy.
- **Every staged byte crossed the link twice** (the write, then the read-back that verifies it). A helper on
  the NAS that returns the file's SHA-256 was proposed for that reason and never built there; the new app has
  it (`internal/nashelper`), never run against a real NAS.
- **Per-file work, not only the link, limits small files:** over 6,569 copies in one hour (average 4.8 MB) the
  seconds went 52% to the write, 19% to the catalogue, 16% to preparing, 6% to the read-back, 6% to the
  publish, 1% to the flush. A sync on the NAS cost 6 to 8 ms.
- The NAS was away for 42 minutes once (11-08): copies were retried with a pause doubling to 10 minutes and
  nothing was lost. Other things use the same link (11-14: a sync tool on the NAS), so a number from this
  test is one reading of a shared link: "looks like".
- Rules that hold here: a library file is never replaced; a copy is never called verified without the
  helper's matching hash or a read-back; nothing in the background reads the library while copies wait.
- The new app's own number: 734 files, 17.8 GB staged, copied and read back on one LOCAL disk (11-13).

So the test reports exactly what the old app's reports had (MB/s in all and per copy, seconds by step, how
each copy was verified, copies at once), so that its numbers can stand beside these.

## What to build: one new test file, nothing else

`archiver/internal/collector/nas_real_test.go` (package `collector`): **a new file; edit no existing file**
(three other branches are changing this package's files and its rig; if a helper you need does not exist on
this head, write your own in your file under a name starting `nasReal`, and do not name anything `newRigAt`:
another branch adds that name).

`TestRealNASCopy` is skipped unless `TGARCHIVE_NAS_TEST_DIR` is set. It runs the real collector on the fake
Telegram (`internal/collector/faketg`: invented chats and files, no network beyond 127.0.0.1) exactly as the
other end-to-end tests do (`rig_test.go` `newRig`, `library_check_test.go`), with these differences:

- **The library is the folder named by `TGARCHIVE_NAS_TEST_DIR`** (the owner's test folder on the NAS), on
  the real file system (the store's own, not the rig's `testFS`); staging stays in the test's temporary
  folder on the local disk.
- **Real time:** a clock at scale 1 (the rig's fast clock makes the store's timeouts and pauses 20 times
  shorter than the real disk and network can meet). Give the store its real defaults where the rig shortens
  them (`StoreTuning` zero values), except `KeepFree`, which you set small so a full local disk never decides
  the test.
- **The helper:** when `TGARCHIVE_NAS_HELPER` (an address `http://host:port`) is set, the real client
  (`nashelper.NewClient`) is the collector's `Hasher`; when it is not set there is no helper and
  `ReadBackNow` is on. `TGARCHIVE_NAS_PASS` names the pass in the output (`helper` or `readback`): one pass
  per start.
- **The world:** `TGARCHIVE_NAS_FILES` (default 150) files with a few large and medium ones so that the total
  is about 1 GB (`TGARCHIVE_NAS_MB`, default 1000, at most 20000: say in a comment how the spec's numbers
  give that total, and print the real total); a seed from the clock, so two starts never make the same
  names; the world must hold files posted in more than one chat, so that hard links are due (say how many).
- **Before anything is written the test refuses, with fixed words and nothing changed, when** the folder
  does not exist, is not a folder, is not empty (count its entries; never print a name), or cannot be
  written (make and remove one file named by the test). It never creates the folder itself.
- **Then:** start, approve every chat's read, wait until every file of the world is saved in the library,
  the copy queue is empty and no link is due (the existing `waitLibrary`'s conditions), with a generous
  bound taken from the total size at 2 MB/s plus 10 minutes, said in the output at the start; stop the
  collector cleanly.
- **After the timed part, an independent check:** every saved file is read back from the library folder and
  its SHA-256 compared with the invented content's own (the fake world knows each file's bytes), and each
  file that should have a second name is checked to be one file with two names (the store's own link
  count helper, `nlink_windows.go`). This read crosses the link once more: it is outside the timing and
  the output says so.
- **Output (through `t.Log`, numbers and fixed words only; never a path, a name or the folder):** the pass;
  files and MB; seconds from the first copy to the last; MB/s in all; the store's counters for the run
  (`store.Hour`: verified by the helper, by a read-back at once, put off; fallbacks by kind; failed tries
  by step and class; retries; "library away" and "library full" starts; copy mismatches; disagreements;
  second names and links made) and its seconds by step (`StepNanos`, each step's share); copies at once as
  the tuner chose them over the run (its tries, kept or not), when the store exposes them; the helper's
  requests by outcome when the helper is on (its `/stats`, counts only); the independent check's result
  (files equal, files different, second names right). A number the store does not count is printed as
  "not counted", never as 0.
- **Cleaning up:** unless `TGARCHIVE_NAS_KEEP=1`, the test removes exactly the files and folders it made
  under the test folder (it knows them from the catalogue's saved paths: remove those and the then-empty
  folders, nothing else, never recursively from the root), and says how many it removed and how many
  entries the folder holds afterwards (0 expected).
- A failure of the copy is the test's result, not a reason to retry: say what failed in fixed words and
  leave the files for a look (`KEEP` behaviour) when the independent check found a difference.

And one start script for the owner, `C:\Users\trabi\Claude\Projects\Telegram\a3\a3-nas-copytest.ps1` (the
`a3` folder is outside the repository and not tracked: just write the file): parameters `-Folder` (required),
`-Helper` (optional), `-Files`, `-MB`, `-Keep`; it sets the environment variables, runs the prebuilt test
program `a3\bin\collector-nastest.exe -test.run "^TestRealNASCopy$" -test.v -test.timeout 0` once per pass
(the helper pass when `-Helper` is given, then the read-back pass), writes the output to
`a3\logs\nas-copytest-<time>.log` and to the window. It sends nothing to Telegram and needs no VPN: say so in
its first comment lines. Do not build the program into `a3\bin` yourself: the Core session does that after
its own read.

## Try it before handing back (no NAS needed)

Run your test with `TGARCHIVE_NAS_TEST_DIR` set to an empty temporary folder on the local disk, 30 files and
about 60 MB: once without a helper, and once with the real helper started locally from this head's own
program (`go run ./cmd/tgarchive-nashelper serve -root <that folder> -addr 127.0.0.1:18791` in a second
shell, stopped afterwards). Also run the refusals (a folder that is not empty; a missing folder). Paste the
outputs' numbers in your hand-back. Named tests only:
`GOPROXY=off GOGC=25 GOMAXPROCS=2 go test -p 1 -run '^TestRealNASCopy$' -v ./internal/collector/`. No other
test of this package (the whole package takes 6 minutes), no other package, no `./...`, no race detector, no
Docker.

## How to work

- Shell: Git Bash. First `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`, then work
  in `wt-core-nastest/archiver`. This package's test program links the Telegram library: its first build
  takes minutes and about 3 GB of memory. Before every go command look at free memory
  (PowerShell: `(Get-CimInstance Win32_OperatingSystem).FreePhysicalMemory/1MB`, in GB) and do not start one
  under 4 GB free: wait a minute and look again.
- Read first, in the copy: `internal/collector/rig_test.go`, `library_check_test.go`, `e2e_account_test.go`
  (how a test starts, approves, waits and stops), `internal/collector/staging.go` and `collector.go`'s
  `Config` (what the store takes), `internal/store/counters.go`, `tuner.go`, `links.go`, `nlink_windows.go`,
  `internal/nashelper/client.go`, `internal/collector/faketg/world.go`.
- Privacy: read nothing under `E:\`, no `start.bat`, no log of a real run (`a3\logs`, `app\logs`, `runs-*`).
  Never point the test at a real folder of this PC other than a temporary one you made. Invented data only.
- Never work in `repo-archiver` itself or in another copy.
- Commit as you go on `wip/core-nastest` and push it to the remote `private` after each commit that builds:
  `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, the message ending with
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Never another branch, never a merge, never a tag.
- `gofmt -l` clean on your file before the hand-back.

## Hand back (your last message)

The branch's head; the two local passes' numbers and the refusals' words; what the store does not count of
the list above (each as "not counted", with where it would have to be counted: that is a note for the Core
session, not for you to build); what you could not make as briefed and why; anything in the store's
behaviour on the real file system that surprised you.
