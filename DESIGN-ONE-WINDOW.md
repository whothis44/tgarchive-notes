# Design note: the app as one window (the owner's choice of 11-16 evening; written by the integrator, 18:35)

**State: DECIDED, and to be built (the owner, 11-16 18:27, on the combined picture: "Yeah, I think that's a
great place to start. Go with it please."). Nothing is briefed or built yet. The pages and the viewer tracks
answer "how" in one joint note under this one before either briefs a coder; pages (session P6) leads it.** The picture is
`design-options/app-look-options.html` in this folder, first button ("The combination"); all data in it is
invented.

## What the owner said
- 11-16 07:40, the first look: "Will it eventually be standalone (i.e. not in a browser), plus the setup screen
  is ugly and there's no folder selection boxes, just paths, which looks worse."
- 11-16 18:13, the first real start, after all three were merged: "Overall, it's a very ugly app, not fully
  functional, doesn't quit properly, and still runs in a browser, just a standalone one?" And: "Show me options
  for the app. You can do better, and you know what the old one and its base ... looked like."
- 11-16 18:30, on three pictures (A like a Telegram client, B like a photo library, C like the old app's
  dashboard): "A looks useful, and practical, but I would still want the library views and toggles from B, and
  the dashboard from C is also useful for consolidating the info so long as it links to the appropriate
  window/filter as well."

## The shape (decided)
1. **One window.** The app's pages and the viewer are one program's one window with one navigation. No second
   window with a second list of chats. (The owner looked for Saved Messages in the app's Chats page and for the
   unified stream in the app: both live in the viewer's separate window today.)
2. **A's frame: one list on the left, the content on the right.** The list, top to bottom: Overview; Saved
   Messages; the library's views; the chats (each with its state in a few words: collecting, mirrored, not
   collected, waiting). Settings and Accounts at the list's foot. Opening a chat shows it as a conversation with
   the text box at its foot.
3. **B's library views and toggles.** In the list: All media, New, Deleted on Telegram, First seen here,
   Probable copies (each with its count). In a view: the grid by day, the Photos / Videos / Files toggle, the
   chips that exist today, and a details panel for the selected item (where it came from, first seen, also in
   which chats, whether Telegram still has it, its copies).
4. **C's dashboard as the Overview, and every number a link.** What the app is doing now (downloading, waiting,
   copied today, the account and the VPN, mirrors made against the cap, the last backup) and what needs the
   owner (held copies, a mirror waiting for a word, chats joined and not collected). **Each number opens the
   place it counts, already filtered:** "128 new" opens the library on New; "212 waiting" opens the queue on
   waiting; "2 probable copies" opens their review. A number with no place to open is not shown as a link.
5. **The collector's state in the title bar** (one pill: collecting, the speed, how many wait; the VPN), which
   opens the Overview.

## What makes it an app and not a browser (in every option; decided with it)
- The app's own title bar; no reload, no back button, no page zoom, no text selection of the frame.
- **Closing the window asks once:** keep collecting in the notification area, or quit; an icon there shows that
  it runs and has Quit. (Today a close leaves everything running without a word.)
- **Folders are changed in Settings** with Windows' own folder box. A folder that is not empty and not this
  catalogue's is named before it is taken ("this looks like another program's library": a second yes).
- **Every page has an empty state** that says what to do next. (A new catalogue broke the Queue page.)
- Before anything is called ready for the owner, someone has opened it as the owner does, on an empty catalogue
  and on a filled one, and clicked every place once.

## Said to the owner
The content is still drawn by the same engine inside the window, as in Slack, Discord or VS Code. A window made
of Windows' own controls throughout is possible and is a rewrite of every page; it is not started before the
owner has used this one.

## Not decided here: for the joint note of pages and the viewer
- Which program owns the window's shell and the left list (the viewer's window program carries the viewer
  today and can show the pages' addresses; the launcher starts both).
- How the pages' places (Overview, Queue, Mirrors, Accounts, Settings) and the viewer's places (the library,
  the chats, Changes, the review) come under one navigation without a second server's address showing.
- What the old archive's window shows (no collector runs on it: no Overview numbers, no text box).
- The order of pieces, so that each lands something the owner can open: the faults of board message 150 first,
  in the present look; then the shell and the list; then the Overview with its links; then the details panel.
- What is reused as it is (the library's grid and chips, the chat page, the Queue and Settings pages' content).

## Rules that bind it (from the record)
- Nothing in the window may reach anything but the app's own addresses on this PC (the window's gate).
- A page that acts for the owner on Telegram says what a click leads to before the click; one click is one
  request (the door's contract is unchanged by the new frame).
- Counts on the Overview are read from memory or by cheap reads; nothing in the background reads the library
  on the NAS for them.
- Invented data only in every picture, test and screenshot.
