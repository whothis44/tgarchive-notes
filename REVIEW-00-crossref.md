# Review of follow-up 00 (cross-referencing in the viewer), 11-22

Two independent Opus reviews (the risk rule: it reads the hold paths).

First review, of c18c01e3: no wrong links, no crashes, no write paths; read-only and path-safe (os.Root,
localPath, libroot.JoinUnder); old-app files never count toward the library's health. One logic error: the old
library had no watcher, so a folder unreachable at first stayed unreachable until a restart. Medium: a network
check under the old library's lock on a page's request; old-app places told apart only once the index had
counted one. Minor: ffmpeg's path joined under a possibly different library; a closed viewer could make a
library again; an old root overlapping the app's library not refused; "old archive" wording from any old-app
place; Release offered for chat-choice holds; the Held view walking all files per page.

Fixed in 78f5e6e1 (a watcher per old library, as the app's; no file-system call under the lock; gated on the
catalogue having file_copy; ffmpeg path under the library opened through; shut flag; overlap refused; wording
from the copy's own place; Release for copies only; Held counts kept per index version, page walked from the
cursor). Not fixed (minor): an old file missing is retried on each walk without a mark.

Second review, of the fix only: no logic error. Two minor points fixed in 6875f771 (the early-check gap kept;
the overlap asked by the watcher, not on a request); one left (the first page after start may show an old file
unreachable until the first background check, seconds later). Race detector clean on the old-library tests.
