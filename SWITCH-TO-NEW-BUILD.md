# Switching your app to the new build

**Build ready now:** 9cb4edc (11-22 12:18), in `C:\Users\trabi\tgarchive-app-next`. **New since 10:18:** downloads only
in hours without the speed limit, where a chat is set so (after a clean probe only the probe file runs for 2 minutes
first: your choice); the old account can be brought in as an archive of its own (a step you start from the launcher;
never signed in or downloaded with; its library read-only); a run's -new-chats-download off now holds for the automatic
mirror's chats too. The catalogue steps up to version 36.

**Earlier build:** 2b38b2a (11-22 10:18). **New since 08:33:** alerts away
from the PC (your bot, with its commands, and the account's Saved Messages) set up in Settings; Settings in sections
with the backup's page; downloads of chats joined while away as a setting; counts beside the viewer's list; when each
mirror was made; a Windows notification for a new alert while the app sits in the notification area; the NAS
downloader's PC side (used by nothing until you set up a NAS). The catalogue steps up to version 34 at the first start
(a copy is kept first). **Windows Defender flagged `tgarchive.exe` on 11-22 at 02:06 and 03:01 ("Bearfoos.A!ml", a
machine-learning guess at an unsigned program) and removed it; allow it or exclude the two folders before updating.**

**Earlier build:** 09aeba54 (11-22 08:33). **New then: THE MIRROR FIXES.**
The mirror never waits for your "Allow again" any more (it settles unknown outcomes itself; your blocked chat clears by
itself); one fast, adaptive pace for every forward (about 1 to 3 s, slower on any wait Telegram states, always slept in
full; a setting); forum topics created 3 to 5 s apart with their real names; new posts first across all mirrors. Also:
the nightly backup (03:30 by default, 7 kept) and "Back up now"; a setting for downloads of chats you join while away
(off by default); held possible copies can be frame-checked from idle lanes (off by default).

**Earlier build:** be291417 (11-22 06:29). **New then:** the Chats page as a
list with a side panel for each chat and its mirror (no sideways scroll), a Mirrors place and "Date joined"; Settings
rebuilt with every setting and its cost; alerts listed in the app; renaming a mirror from its panel; the launcher's fixes
from the tester (a refused first start stays in one window and says why; a notification-area icon; the app's own Quit;
the folder box fixed); Core's alerts record and the forum topic names fix. The rest of the earlier builds follows.

**Earlier build:** 4bf224b3 (11-22 04:36). It holds everything listed below,
plus **the new app's look**: one frame and one list (Overview, Saved Messages, the library's views, your chats), the
Overview's numbers as links, the library views with toggles and a details panel, chats as conversations, the app's own
icon and the window title "TG Archive", and the launcher's fixes. **New since 03:02:** the sampled-frame check and the
video fingerprints run by default (your library's videos get fingerprints, newest first, only while nothing waits;
about 8 MB sampled per new video that looks like one you have, reused if it is downloaded); a mirror can be renamed
from a page; Core's small fixes. Still to come: the Chats page and Settings rebuilt (held for three security fixes),
the mirror fixes M16 and M17, alerts.

## What this build changes for you
- **The mirror no longer stops on deleted posts;** single posts go 5 to 20 s after they appear (a setting); exact
  repeats of a message already in the mirror (the groups' bots) are not forwarded again.
- **Forums are mirrored as forums**, with the same topics. The two forums you joined after the automatic mirror
  started (11-19 07:12 and 11-21 21:03) are mirrored by themselves; the third needs "Mirror this chat".
- **Lesser copies wait behind the best one** by default; the daily cap on new mirrors goes up to 500 (20 by default).
- **Your Saved Messages are read once by themselves** (about one request per 100 messages; nothing downloaded).
- The Overview's numbers are links; one list on the left. (The new frame comes with the next build.)
- The catalogue steps from version 26 to 31 at the first start. The update keeps a copy of your catalogue first.

## Steps
1. **Quit the app:** close its window and choose **"Quit the app"** (not "Keep it running").
2. **Run, from any PowerShell window:**

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\trabi\tgarchive-app-next\update-folder.ps1" -Into "C:\Users\trabi\tgarchive-app"
```

   It checks that nothing of the app runs, copies your catalogue aside (this takes a while: do not open the app
   meanwhile), puts the new programs in (the old ones kept in `programs\<old build>\`) and starts the app again.

## If something is wrong: go back
Quit the app, then:

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\trabi\tgarchive-app\update-folder.ps1" -GoBack
```

It puts back the earlier programs and the catalogue copy made by the update. Anything the new build wrote to the
catalogue since is set aside (never deleted), and it asks before it does anything.
