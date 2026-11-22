# The frame check's first real run on the test account: the plan (copies, C4; final, 11-16 11:50)

**C12 is merged (2a6073b, 11-16 11:25) and the integrator has installed that build and rebuilt the folder: the
flags below exist in the installed collector. Nothing here has run, and nothing runs unless the owner starts
it.** Checked by reading only (nothing was started): `FFMPEG_PATH` is not set on this PC and the folder's `tools`
holds no ffmpeg, so the commands below name ffmpeg themselves with `-ffmpeg`; without it the collector would say
"no ffmpeg" and the run would show nothing.

## What the run is for, with the old app's number beside each
One run of one account: every result is "looks like".

| What is read | The old app | Where it shows in the new app |
|---|---|---|
| Parts fetched per check | 8 at the median | the judge's and the Supply's hourly lines |
| Seconds from a check's parts being in to its verdict | 10 to 22 s added per check in hours without the speed limit | the judge's hourly line; the judge looks every 30 s when idle, so up to 30 s more is expected and is the number to read before a kick is added |
| Share of checked videos called "copy" | 10 to 25% of videos nothing held | the hourly line: copy / partly / no match / unchecked by reason |
| Kept parts taken in place of requests, and refused on reuse | at least 63 GB in 7,916 downloads; none refused | the part store's hourly line |
| Checks that end "unchecked", by reason | 4 of 51 timed out under the speed limit (12.25); about half under the limit later | the hourly line; expected 0 on an account without the limit |
| Download speed with the check on | (the test account: about 5 MB/s on its one server, 2 parts) | must stay in that range: a check must not slow downloads |
| Plain waits per MB | (the test account: one per 7 to 14 MB) | must not get worse with the check on |
| A saved video's fingerprint: on the card or the CPU, seconds of video per second | the card, the CPU when it fails | the worker's hourly lines |
| How long a staged file waits for the worker before its copy | bounded waits, "copies never idle for it" | the store's line "not yet due"; the bound is 2 minutes |

## What the test account has today, and why the run has two parts
756 files are saved and none has a fingerprint: the worker reads a video's staged copy before it is copied, and the
pass over library videos is not built. So a check has nothing to compare with until videos are saved with
`-fingerprints` on.

1. **Part 1, fingerprints only.** The owner chooses a chat with videos on the Chats page (Collect, "ask how
   large", "approve this read"): the owner's choice of chat, as always. Started with `-fingerprints`. Read: the
   table's last two rows, and that the copies go on as before.
2. **Part 2, both flags.** A second chat of the owner's choice, best one that repeats videos of the first
   (re-posted or re-encoded). Started with `-fingerprints` and `-frame-check`. A video of 20 MB or more with a
   saved fingerprint within a fifth of its length is checked: its sampled parts are fetched as counted requests,
   the judge compares frames from local parts only, a "copy" is **held** with its evidence (never skipped; shown
   on the Queue page), anything else is downloaded with its kept parts reused.
3. **After part 2, read-only, counts only (a script of mine, written before the run):** of the videos judged "no
   match" and downloaded, how many pair by fingerprint with the video they were compared with. The old app's
   "no match" against a named file was wrong about 3 times in 4; this is the first measure of it here (answers 8:
   "measure the miss rate on the test account, against downloads, from the start").

## The commands (the owner's, in a PowerShell window; full paths)
Stop what runs first:

    powershell -ExecutionPolicy Bypass -File "C:\Users\trabi\Claude\Projects\Telegram\a3\a3-stop.ps1"

Part 1 (one line):

    & "C:\Users\trabi\Claude\Projects\Telegram\a3\a3-start.ps1" -Pages -Extra "-fingerprints","-ffmpeg","C:\Users\trabi\AppData\Local\Microsoft\WinGet\Packages\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe\ffmpeg-9.0.2-full_build\bin\ffmpeg.exe"

Part 2 (one line):

    & "C:\Users\trabi\Claude\Projects\Telegram\a3\a3-start.ps1" -Pages -Extra "-fingerprints","-frame-check","-ffmpeg","C:\Users\trabi\AppData\Local\Microsoft\WinGet\Packages\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe\ffmpeg-9.0.2-full_build\bin\ffmpeg.exe"

From the one program's folder instead (`C:\Users\trabi\tgarchive-app`): the same flags added to `run_flags` in the
folder's `tgarchive.json` (`"-fingerprints"`, `"-frame-check"`, `"-ffmpeg"` and the path, each as its own entry),
then `tgarchive.exe` as usual. Which of the two ways is the owner's to say; the `a3` scripts are the ones proven
on this account.

ffmpeg, as checked on 11-16 without starting anything: the collector looks at `-ffmpeg` first, then the `tools`
folder beside the program, then `FFMPEG_PATH`, then PATH. On this PC `FFMPEG_PATH` is not set, the folder's `tools`
is empty, and a Go program does not see this PC's PATH entry for ffmpeg: so `-ffmpeg` it is, with the path above
(ffmpeg 9.0.2, the one every test of the piece ran with). The first lines of the collector's log say in fixed
words whether ffmpeg was found and which decoder the fingerprints use (the card first, else the CPU): **if the
log says "no ffmpeg", stop the run and tell a session; nothing is harmed, but nothing would be shown either.**

How long: part 1 as long as the chosen chat's download takes (the test account's first chat: 756 files in about an
hour); part 2 the same for the second chat. Each part can be stopped and started again at any time.

## Bounds and what stops the run
- A check with no answer: 3 tries 5 minutes apart, then the file is downloaded unchecked and counted.
- An ffmpeg outage is never counted against a file; a video is let through for it only after 10 minutes down
  without a break, or 2 hours of an unsteady ffmpeg.
- At most 16 checks in flight, 2 judged at once; kept parts at most 20 GB, nothing kept under 60 GB free.
- Stop with `a3-stop.ps1` (or Quit on the pages) at any time: a check under way is carried on at the next start
  from its kept parts, with no part fetched twice.
- Stop and tell a session if: the speed falls well under the earlier runs', the hourly line shows checks
  "unchecked" for a reason other than those above, or a held file's count falls without a word of the owner's.

## What a session reads afterwards
The log's hourly lines and the catalogue's counts (read-only, counts only), set beside the table above, written
into `TELEGRAM-FACTS.md` and the roadmap's row by the integrator from this track's progress entry.
