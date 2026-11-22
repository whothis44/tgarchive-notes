# Brief B5-R: an independent look at one piece of the viewer track (viewer session B5, 11-15)

You are an independent reviewer. You did not write this code and you owe its author nothing: your job is to
find what is wrong before the owner does. The main session names, when it starts you: the piece (T, W or
C), its brief, its copy, its branch and the range to read (`3244f0d..<head>`).

| Piece | Brief | Copy | Branch |
|---|---|---|---|
| T: every thumbnail in the background | `BRIEF-B5-thumbs-bulk.md` | `wt-b-faces` | `wip/b-thumbsbulk` |
| W: the window as the only viewer | `BRIEF-B5-window-only.md` | `wt-b-window` | `wip/b-winlan` |
| C: the chat page as a client, reading only | `BRIEF-B5-client-reading.md` | `wt-b-viewer` | `wip/b-client` |

(All in `C:\Users\trabi\Claude\Projects\Telegram`; the Go module is the copy's `archiver` folder. Go:
`source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh` in Git Bash.)

## How
- **Read-only on the copy and the branch:** change no tracked file, commit nothing, push nothing. Your
  probes and scratch tests live in a new folder `C:\Users\trabi\Claude\Projects\Telegram\wt-b5-review-<piece>-scratch`
  (copy test files into the package only for a run, and remove them after: the copy must be clean when you
  end; say so).
- Read the brief in full, then the whole difference (`git diff 3244f0d..HEAD`), then the code around it as
  far as a doubt takes you. Read the documents the brief names where your doubt touches them
  (`LESSONS-viewer-ix12.32.md`; for W also `REVIEW-B3-lan.md`, `REVIEW-B4-window.md`, `REVIEW-B4-window-2.md`).
- Judge against the brief, the owner's words quoted in it, and these standing rules: no request a page
  depends on waits on the library; nothing proportional to the archive per request, per poll or per
  update; invented data only and no name, path, hash, id or message text in any log line, error, counts
  file or command output; the viewer and the window have no Telegram code and make no outbound
  connection; nothing in product code depends on this PC's absolute paths, the start folder, PATH or a
  script; a test must not judge real time; every number says what it counts.
- **Try to break it:** write probes that fail if the defect is real (a second writer on the invented
  catalogue, a crafted or half-written file, a hostile home device, a long run of writes against a bound, a
  second program writing the same folder, a cancelled run, a path with spaces and non-ASCII letters, a
  library that is not there). A finding is **confirmed** only with a probe that shows it or a line-by-line
  argument nobody could doubt; otherwise it is **plausible**, and say what would settle it.
- For W, look as an attacker on the home network would and as a page script inside the window would: what
  can each reach, start, read or keep busy that the brief says it cannot.
- For C, look hardest at `refresh.go`: does the new record change what an update reads, how versions share
  parts, or what a request can see half-built; can it grow without bound; can a poll see another chat's
  posts or a hidden chat's.
- For T, look hardest at two programs on one folder, at what a stopped run leaves behind, at the list's
  format against odd file names, and at every printed line.
- **Privacy and load, as for the coders:** never start the owner's viewer or window, never open the owner's
  catalogue, library or any real media; nothing under
  `%LOCALAPPDATA%\Packages\Claude_pzs8sxrjxfjjc\LocalCache\Local\tgarchive-b` (W may run the mpv there
  headless on invented clips) or `E:\T`. `GOMAXPROCS=2`, `go test -p 1`, `GOGC=50`, named tests and your
  probes only, free memory checked first (wait under 2 GB); no whole run of `internal/viewer`, no race
  detector (the main session runs both once, after the fixes).

## Hand back, as your last message
Write `REVIEW.md` in your scratch folder and give its content: a verdict in three lines; the findings worst
first, each with: confirmed or plausible, the file and line, what happens and to whom, the probe (its file
in the scratch folder and what it printed), and the smallest fix you would accept; then "Checked and sound"
(what you tried to break and could not), "The tests the hand-back leans on" (which of the coder's tests
would still pass with the defect present), and "Not run". No praise, no summary of what the code does.
