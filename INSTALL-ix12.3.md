# Installing ix.12.3: one restart, nothing lost

What you need: the new `start.bat` (your own file with two lines added: `TGDL_LAUNCHER_RESTARTS=1` and
`TGDL_CRASH_CAPTURE=1`; everything else is the same).

## 1. Wait until 12.3 is published

Open https://github.com/whothis44/telegram-media-downloader/releases/latest . It must say **v3.4.18-ix.12.3**.
If it still says ix.12.2, wait: restarting now would install 12.2, and 12.3 would need a second restart later.

## 2. Let the downloads in progress finish

On the Archive page, click **Update when downloads finish**. No new file starts. The files already downloading finish
(your running 12.1 cannot stop them at a checkpoint yet; 12.3 can, from the next update on). With the speed limit off
this took about 20 minutes for 3.4 GB; under the limit it can take a couple of hours, so pick a time you can watch.

When the page says **"Downloads are done: nothing will be lost"**, go on.

## 3. Close the window, swap start.bat

1. Close the downloader's window (the one that says "Starting it again in 30 seconds" when the app stops).
   Nothing is in progress, so nothing is lost.
2. In `E:\T\tg-dl`, rename your `start.bat` to `start.old4.bat` (keep it).
3. Put the new `start.bat` there.

Do not swap `start.bat` while its window is open: Windows reads a batch file as it runs, and changing it underneath
can make the window run half-lines when the app next stops.

## 4. Start it

Open `start.bat`. It installs the newest release (you will see "Updating tgdl-server 3.4.18-ix.12.1 -> 3.4.18-ix.12.3"
and "Installed tgdl-server ..."), then starts the app. The first start can take a moment longer: the database gets
a new column.

## 5. After it is running

- Archive page: the version at the top says **v3.4.18-ix.12.3**.
- **Settings → Downloads → Install updates automatically**: tick it and Save. From then on an update stops files of
  8 MB or more at their next checkpoint (at most 30 seconds away), lets small ones finish, and restarts by itself.
- Leave **"…and judge its tries by how fast Telegram answers"** unticked. After a day, the diagnostics report's hour
  lines say whether it would help ("tries judged by bytes: …").
- The local staging folder now keeps progress too, so it is safe to turn on if you want it. You do not have to.

## If something is wrong

Tell me what you see. Your updater only moves forward, so putting the old program back would be undone at the next
start: the fix is a 12.3.1. The program you had is kept as `core-service\tgdl-server.exe.previous`.
