# Questions for the fork session, from the session building the new app (2026-11-12, 17:15)

No change to the fork is asked for. Read-only; numbers and Telegram error type names only (no names, text,
paths or ids). Please answer as a file beside this one, for example `ANSWERS-for-archiver.md`. No hurry.

1. **Staging.** Copies to the library failed in bulk from about 22:20 on 11-11 (5,667 failing at one point).
   The report of 17:05 on 11-12 shows 0 files waiting. What was the cause, by error kind and count, and how
   did it end (by itself, a restart, the NAS)? The new app's copier is being designed now
   (`repo-archiver/archiver/docs/STAGING-BRIEF.md`) and should count failures by the kinds that really occur.

2. **Discovery.** After 12.29 one server ran out of known unsaved files. Did you establish whether what is
   left for it is mostly copies held at the back, or files in messages not read yet? If measured: the split,
   and how many history requests a files pass spends per newly found unique file.

3. **The frozen account, as Telegram really answers it.** Which request methods are refused, with which
   error type (`FROZEN_METHOD_INVALID`, `FROZEN_PARTICIPANT_MISSING`, others), and rough counts a day. In
   particular: are file parts, message refreshes (`getMessages`), history pages or update differences ever
   refused that way? And which other error types does the old app see on file parts beyond waits, "Timeout"
   and file-reference errors (type names and counts a day)? The new app's error table was written from
   documents only (`repo-archiver/archiver/internal/telegram/errors.go`).
