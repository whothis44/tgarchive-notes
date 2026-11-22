# The app as you meet it today: an honest audit (UI track, U-1, 11-21 night)

Built from the main head (6aa225fb) into a folder of my own, on an invented archive (14 chats, about 1,000 saved
files) and on a new empty one. No sign-in, nothing sent to Telegram, your app and folders untouched. Every place
in both lists clicked once. Pictures in `ui-audit-1121/` (all data invented).

## What is wrong, worst first
1. **It is still two apps glued together.** The library (picture 1) and the Overview (picture 2) each draw their
   own frame: a different left list (different entries, order, width and icons), the search box gone on one side,
   two different "Settings" (the viewer's and the app's), and the title bar says "Archive viewer". Every click
   across that line feels like changing program.
2. **The app's own places are buried.** Queue, Staging, Choose chats, Import and Report sit below the last chat
   in the app's list (your catalogue has 35 chats today, more after the old archive comes in): off the screen
   unless you scroll the whole chat list. In the viewer's list they do not exist at all.
3. **No collector, no app.** When the collector cannot start (no sign-in, a refusal, a crash) the window shows
   only a technical page (picture 3): log folders, watchdog lines, exit codes. The library, which is right there,
   cannot be opened.
4. **The Overview speaks engineer.** "One lane per account and server", "parts in flight", Server 1 to 5, "read
   records of chats could not be read when a mirror ended". It does not answer "is it working?" and "what needs
   me?"; the agreed "needs you" block with every number a link is not on the head yet (W3, in flight).
5. **The library wastes the window.** Three columns that scroll on their own (list, a 270 px filter column, the
   grid) plus the window's own scroll bar; Photos / Videos / Files appear both in the list and in the filters.
6. **Too many words.** Most pages open with a paragraph (Queue: four lines; the setup: a red box of three
   sentences before you have done anything).
7. **Chats are message cards, not a conversation** (picture 4): no bubbles, no chat state ("collecting",
   "mirrored") in its head; a chat's switches live on a separate "Choose chats" table.
8. Small: a "Viewer: set its address" button on every app page (a developer's knob); two theme switches; "Saved
   Messages" shows an empty page until the chat list is read.

Not checked here: the close question and the tray icon (they need the launcher with a running collector), videos
in mpv (none in my folder).

## The plan, in pieces you can open (each ends with pictures on invented data, then your word)
1. **One frame.** One list and one top strip, the same code and look on every page of both halves: Overview (with
   a "needs you" count), Saved Messages, the library's views, Chats (its own scroll, a filter box, newest first),
   and the app's places pinned at the foot (Queue, Mirrors, Settings, Accounts). One Settings, the viewer's
   settings a section of it. Title bar "tgarchive". Builds on the viewer track's "one list" branch (W1v).
2. **The library opens without the collector.** A failed or missing collector is one line at the top ("Not
   collecting: not signed in. Details / Try again"), never a page that hides the archive.
3. **The Overview as the dashboard:** Now (one sentence and the pill), Needs you, The archive in numbers, each
   number a link to its place already filtered; the server-by-server tables move under Queue.
4. **The library:** filters folded into a row of chips over the grid (Photos / Videos / Files toggle), one
   scroll, and the details panel on the right for the selected item.
5. **Chats as conversations:** bubbles, the chat's state and its switches in its head, the text box at the foot.
6. **Settings and the setup in the same look**, Windows' folder boxes, grouped and calm; the close question
   remembered there.
7. **A words pass** over every page: one line of intro at most; an empty state on every place.
Pieces 1 and 2 first (together they end "two apps" and "no collector, no app"); 3 to 6 can run side by side.
