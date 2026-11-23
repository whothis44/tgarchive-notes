# UI audit on invented data, 11-22 (follow-up 03)

**How it was made.** `runs-agent/ui-audit/run.sh <worktree> <tag>`: the head built into a scratch folder of its own
(`runs-agent/ui-audit/<tag>`), an invented archive fabricated there (`tgarchive fabricate`: 2 accounts, 14 chats,
3,000 messages, real pictures, the chat lists' reads) plus `extra.py`'s invented rows (the old archive's brought-in
account with sightings, the old library with six saved pictures as the old app's places, held files of every reason
the viewer names, files skipped as in the old archive); the pages run as `tgarchive app -demo` (read-only, invented
lanes, mirrors in every state, the NAS's demo doors), the viewer in-process as the window starts it (with the pages'
address), LOCALAPPDATA/APPDATA/TEMP in the scratch folder, no sign-in, nothing against Telegram, never the owner's app
or catalogue. Every place of the pages and the viewer driven in headless Edge at 1366x900 and 390x844 (36 places;
the chat at its newest and after "First"), each screenshot looked at. Screenshots: `reports/ui-1122/pass1/` (on the
batch-1 head), `reports/ui-1122/pass2/` (after the fixes). No page error was counted on any place.

`DESIGN-ONE-WINDOW.md` checked: one window, the list on the left, no media on a fresh start (the window opens on the
Overview); nothing in it was found to make the app worse to use, so nothing of it was changed.

## Problems, worst first (as found, then what happened)

| # | Where | What is wrong | One-line fix | State |
|---|-------|---------------|--------------|-------|
| 1 | The window's list, head | The old archive's brought-in account gets "Saved Messages · <its label>, not read yet": it never reads, so the row can never fill | Only when its own chat was brought in, named "Old archive" | fixed (d576658) |
| 2 | Pages, a chat's panel (head and badges) | The old archive's account is named "(left this chat)" with a crossed badge | Mark it old in the pages' account list; "Old archive", never "left" | fixed (d576658) |
| 3 | Viewer, Copies → Held back | Release / Keep held offered for files the app's held files cannot release (seen only by the old archive's account, a chat's choice) | Only for files held as copies | fixed (d576658) |
| 4 | Viewer, media view and its side panel | The recognition line repeats the state's own words ("Not downloaded: another version…" twice) and its icon stands on a line of its own | No second line for kinds the state already says; icon inline | fixed (d576658) |
| 5 | Pages, Overview, "The archive" | "New", "First seen here", "Probable copies" show an underlined "–" until the viewer's counts arrive (a few seconds) | — | left: deliberate (brief F12: "Not counted yet: opens the view", pinned by tests); the counts come within seconds |
| 6 | Viewer, Chats | The old archive's badge reads only as its initials ("IO") beside "Seen by both" | Name the old archive in the badge's title | left: minor; the Account filter already names it "Old archive" |

Seen and found right: Mirroring above Collecting in a chat's panel (01); "Chats" and "Mirrors" in the list's foot
(02); the Account filter (0); First and Newest in a chat's head (0b); "Show Saved Messages in the list" in Settings
(0c); the chips "mirrors under way" and "chats that download" (0d, 0e); Today's numbers; the Held back list beside its
recognised copies (00); every narrow view (390 px) without overflow. The demo's own invented states (the alerts'
record failing, "Not collecting: stopped") are the demo's, not problems.

## Pass 2 (after the fixes, on batch 2's combined tree)
The same 36 places shot again (`reports/ui-1122/pass2/`) and looked at: problems 1 to 4 are gone (no Saved Messages
place for the old archive; the panel says "Old archive" with a plain badge; no Release or Keep held on rows the app
cannot release; the media view says "another version of this post's file" once). No new problem was found: the audit
is clean but for 5 and 6, left for the reasons in the table.

## The exceptions (not built: they would send to Telegram or change what is downloaded, held or released)
None was found by this audit.
