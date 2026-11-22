# Two small pieces for the viewer track (session B9, 11-22, the integrator's word)

Common rules for both: invented data only, never the owner's folders, window or media; counts, codes and timings only;
commit with `git -c user.name=Claude -c user.email=noreply@anthropic.com commit`, messages ending
`Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`; push only your own branch to `private`; Go only through
`bash /c/Users/trabi/Claude/Projects/Telegram/runs-b7/shell/scripts/gorun.sh <dir> go ...` with ABSOLUTE output paths;
named tests only; no race detector; no window on the screen; new log lines are constant format strings.

## A1V: the chat box and the client's A1 (copy `C:\Users\trabi\Claude\Projects\Telegram\wt-b-a1viewer`, branch `wip/b-a1viewer`, from the join tip f677f3a8)
The client track's A1 adds kinds to `c_act`: `look`, `join`, `leave`, `mute` (chat-level actions, not messages), and
`sendfile`/`upload` (A2) is a message. Today the viewer's chat box (the chat page's click data, `internal/viewer/act.go`:
the clicks drawn among the messages, `GET /api/act/chat/{id}` and whatever counts the owner's unfinished sends) would draw
the chat-level ones as message rows. Do: (1) leave `look`, `join`, `leave`, `mute` out of the clicks drawn among the
messages and out of every count of the owner's unfinished or unknown sends (a fixed set of message kinds, documented;
an unknown future kind is left out too); `sendfile` stays a message like a send. (2) `catalog.ActNonePhoto` ("a photo is
re-encoded: the owner decides", `internal/catalog/act_settle_upload.go`) needs a word in the viewer's click state words
(the place where the viewer maps a settle word to what the page says and offers: grep the other `ActNone*` words in
`internal/viewer`): give it its own plain sentence and the same offers as the other "the owner decides" words. Files:
`internal/viewer` Go only (not `web`). Tests by name: each chat-level kind absent from the drawn clicks and counts, a
sendfile drawn, an unknown kind left out, ActNonePhoto's words; then `-run 'TestWall|TestHomeDevice|TestLAN|Security|TestAct'`;
gofmt; vet viewer.

## W9: the app's window logs its end (copy `C:\Users\trabi\Claude\Projects\Telegram\wt-b-windowend`, branch `wip/b-windowend`, from f677f3a8)
On 11-22 the owner's window vanished (Windows Defender stopped a program) and nothing in the app's log said why. A
process that is killed cannot log its own end, so the LAUNCHER's watch of the window must (`internal/launcher`: find
where it starts the app's window and waits for it: `present.go`, `start.go`, `closeask.go`; its owner, pages, is
archived: this track takes it). Do: (1) when the window process ends for any reason, the launcher writes ONE line in its
own log, constant format, e.g. `launcher: the app's window ended: exit code %d after %s; closed by the person: %v; the
launcher's own stop: %v` (the code as the OS gives it, 4 = the person's close under `-tell-close`, 6 = already open;
a kill shows as its code, e.g. 1 or a large value: print it as it is, also in hex), the time is the log line's own time.
If a line like it exists already for some paths, make it one line on EVERY path (the joined window, the solo window,
the pages window, a restart). (2) In `cmd/tgarchive-window`, a line at its own clean end where it can (the code it returns).
No names, paths or ids in either. Tests by name: the line on a normal end, on the person's close, on a forced kill of a
stand-in child process (start a small helper process the test kills), and on the launcher's own stop; then the
launcher's named tests that touch the window (`-run 'Window|Close|Joined|Present'` or the closest names) and
`go vet ./internal/launcher ./cmd/tgarchive-window`; gofmt.

## Hand back (each, short)
The head pushed; what changed in a few lines; the exact log line(s) or words; tests by name with seconds.
