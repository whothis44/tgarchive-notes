# Plan: a standalone archive app (revision 3)

Written 2026-11-09 by a review session, as a proposal. Nothing here is built. It is based on the code at ix.12.22
(`CODE-REVIEW-ix12.22.md` has the review) and on counts from the live database (counts and categories only; the two
scripts are `ix-tools/live_q9.py` and `live_q10.py`).

**What changed in revision 2 (the user, 11-09):** a new Telegram account **will** be created, its groups are likely to
hold much of what is stored now, and the user wants to choose, per account, whether it writes into a shared archive or
its own, and to be able to run more than one account at a time. So the downloader is no longer "only if"; the
catalogue is designed for several accounts from the start; and the earlier "second account in a separate folder,
always" becomes one of two choices.

**Decisions the user made on 11-09 (revision 3), now built into the sections below:**
1. The new account is not active yet; it may start around 11-30, or sooner depending on download progress. So the
   stopgap of 5.6 is likely needed, and its "already archived" import should be ready before the account starts.
2. The new account writes into the **same archive** as the old one's files.
3. **Hand-over between accounts on a wait is ON by default**, with a setting to turn it off: separate accounts have
   separate limits.
4. One account first; more later.
5. A basic group seen by two accounts shows as two linked chats.
6. "Always download, even if saved" per chat: wanted, low priority, as long as the media is cross-referenced.
7. The viewer's weak points come first: speed, how posts and albums are shown, the Chats page, and collapsing copies
   (section 6.1).
8. The viewer should be reachable from other devices at home, securely.
9. The catalogue's second copy lives on the desktop that runs the app. Nowhere else can hold the media library, so
   the media keeps one copy (on the NAS); that is accepted.

## 1. Recommendation in short

1. **Build nothing new before 2026-11-30**, except the checks and fixes in section 3. Saving files is the only job
   until then, and the fork does it.
2. **Two programs over one archive format:**
   - **Archive**: viewer and curator. No Telegram code, no secrets, no network. Grown from 12.22's viewer.
   - **Collector**: the downloader, extracted from the fork (not rewritten), able to run **several accounts in one
     process, all writing to one archive**.
3. **The archive format is account-aware from day one** (section 4). That is the one design decision that cannot be
   added later cheaply, and it is what makes "share or keep apart" a choice the user can make and later change.
4. **Sharing works because Telegram's file IDs are the same for every account.** A forwarded file keeps its ID, and
   today's archive is almost entirely forwards (400,752 of 401,261 messages). So a new account that meets the same
   files again can be told "already saved" from the ID alone, before any byte is downloaded.
5. **The current fork cannot share its folder** with another account and should not be made to (section 5.6). If the
   new account must start before Collector exists, it runs in a separate folder and is merged later.

## 2. What the live archive looks like (counts, 11-09)

| | |
|---|---|
| Chats with saved messages | 190; every one has a finished message pass |
| Chat ID shapes | 175 basic-group IDs, 8 channel or supergroup IDs (the 8 are forums); 100 forum topics, all titled |
| Messages | 401,261, each with its full Telegram record kept; 116,156 with text; 325,671 with media |
| Forwards | 400,752 of the messages are forwards; one distinct sender wrote all of them |
| Forward sources | 2,964 distinct: 1,271 with a saved name (300,949 messages), 1,684 recorded as text (98,965 messages), 9 with no name (838 messages) |
| Distinct Telegram files seen in messages | 246,712 (173,993 documents, 72,719 photos); 40,633 appear in more than one chat |
| Saved files | 129,486 (2,598 GB): 118,106 in basic-group chats, 11,380 in the forums |
| Hashes | every saved file has a SHA-256, a Telegram file ID and a path; 129,139 distinct SHA-256 |
| Queue | 36,023 pending, 15 failed |
| Accounts | one; no table records which account saw or saved anything |
| Replies | 3,344, every target saved |

Two facts shape the design:
- **Most of the archive sits in chats whose message numbers belong to one account.** In a basic group (and a private
  chat) each account numbers messages for itself, so "chat X, message 500" from the new account is not the same
  message. Only channels and supergroups have numbers every account agrees on. The fork's catalogue is unique on
  (chat, message) with no account, which is why it cannot be shared as it is.
- **The files are shared even where the messages are not.** 246,712 distinct Telegram file IDs are known, 129,817 of
  them saved. The same file forwarded anywhere, to any account, carries the same ID.

## 3. Before 11-30: checks, results, and what is left

Each check was read-only. Result: **nothing important is missing from the catalogue.**

| Check | Result | Action |
|---|---|---|
| Message text for every chat | 190 of 190 chats have a finished message pass; no chat with files or queue rows lacks messages | None |
| Chat names | The names table holds 190 chat names for 190 chats (counts match; I could not match them row by row because the two tables write the ID differently). The chat-details table has a title for only the 8 forums | Confirm row by row in 12.23's report; no Telegram request needed unless some are missing |
| Topic names | 100 of 100 | None |
| Sender names | One sender, named | None |
| Forward-source names | 9 sources (838 messages) have neither a name nor text | Ignore, or look up 9 names by hand |
| Replies | 3,344 of 3,344 targets saved | None |
| Hashes | No saved file lacks a SHA-256, Telegram ID or path | None |
| Integrity | 17,248 checked ok and 4 unreadable this cycle, of 129,486 | Let the monthly check finish a cycle once downloads end; look at the 4 |
| Which account saved what | Recorded nowhere (the owner column is empty on every row) | None now: there is one account. Consolidation stamps everything with it (section 4.5) |
| Deleted-on-Telegram marks | 0 messages marked | None |

Still to do before 11-30 (none needs new Telegram requests):
1. **Fix the last index and backup after the account goes** (code review A1). The most important item.
2. **A restore drill on a copy:** restore one nightly backup to a scratch folder on another disk, open it with the
   viewer on that copy, compare counts. Counts only; nobody needs to look at media.
3. **Record the account's own Telegram user ID in the final index** (it is in the database already). The account-aware
   catalogue needs it to say whose message numbers the 175 basic-group chats use.
4. **Keep the list of files known but not saved.** When the account goes, the queue's pending rows and the "not queued
   yet" files are a wanted list (about 117,000 distinct Telegram files today: 246,712 known less 129,817 saved). The
   new account's Collector should fetch those first when it meets them (section 5.4). The final index should carry
   their IDs, sizes and kinds.
5. After the account is gone: delete its session files and `secret.key` from the data folder and the pre-update
   copies, once the user confirms nothing else needs them.

## 4. The archive format: one design for one account or many

### 4.1 Three layers
```
content     file            the bytes: SHA-256, size, kind, path in the library. One row per distinct content.
telegram    tg_media        Telegram's own file: kind + ID + size (+ server). The same for every account.
                            Points to a file once saved; otherwise "known, not saved" with why.
sightings   message         one message as one account saw it, in a "message space" (4.2)
            attachment      message -> tg_media, with position in its album
```
A file is stored once however many chats, messages or accounts it was seen through. "Already saved?" is a look-up of
`tg_media` by ID: no download, no Telegram request.

### 4.2 Message spaces: where numbers mean the same thing
| Chat type | Message numbers | Space | Shared between accounts? |
|---|---|---|---|
| Channel, supergroup, forum | one numbering for everyone | the channel | Yes: two accounts in the same channel see the same messages, and they merge by themselves |
| Basic group | per account | account + chat | No: each account's view is kept side by side, linked through the files they share |
| Private chat, saved messages | per account | account + chat | No |

`message` is unique on (space, message number). A basic group that Telegram later turns into a supergroup gets a new
space, linked to the old one ("migrated", which the fork already records for 10 chats).

### 4.3 What belongs to an account
| Table | Holds |
|---|---|
| `account` | a label the user chooses, the Telegram user ID, added and removed dates. **Never the phone number**: it lives only in the session, which the Collector holds |
| `account_chat` | per account and chat: can it be read (member, restricted, gone), how far its messages have been read, whether a files pass is done, Telegram's access keys for that chat |
| `sighting` | which account saw which message, first and last time. For shared spaces this is how the viewer can say "seen by both" or filter to one account |
| `fetch` | which account downloaded each file, when, from which server: provenance, and the report's source |

Everything else (files, Telegram media, copies, people, text, search) belongs to the archive, not to an account.

### 4.4 The rest of the catalogue
As in revision 1: `chat`, `topic`, `sender`, `copy_edge` (exact, probable, related, with evidence; "probable" is never
stored as "exact"), `face` and `person`, recognised text, one full-text index, and a `provenance` table with source
row counts. No queue, settings or job tables: those live in the Collector's own database. Image and video vectors move
to flat files (118,508 and 504,842 rows today), which shrinks the database a lot (to be measured).

The owner's decisions stay in a separate small database (`decisions.sqlite`: names, merges, "same or not" answers,
tags, collections, hidden), as the viewer has now. Decisions are per archive, not per account.

### 4.5 Bringing the current archive in ("consolidation")
`archive consolidate` reads the fork's database (read-only, kept for good) and writes the new catalogue:
- one `account` row for the account that is going, with its Telegram user ID;
- the 175 basic-group chats become spaces of that account; the 8 forums become shared spaces;
- 246,712 `tg_media` rows: 129,817 saved, the rest "known, not saved" (the wanted list);
- every message's forward header is decoded from the kept Telegram record into a **forward origin** (source channel
  and post number, where Telegram gives them): a second key for recognising the same post again (5.3);
- every count is recorded and checked against the source.
Sizes of the tables to move are in section 2. Nothing in the library moves.

### 4.6 Merge and split, so the choice is not for ever
- `archive merge B into A`: files by SHA-256, Telegram media by ID, shared spaces by channel and message number,
  account spaces as they are. Media files are moved, or left in place and referenced, as the user chooses.
- `archive split --account X`: a new archive holding what account X saw, with the files it needs (copied, or
  hard-linked on the same disk).
Merging later is easy; splitting later is possible only because every sighting records its account. That is why the
account columns are there even for a single-account archive.

## 5. Collector: the downloader, for one account or several

### 5.1 The rule of shape
**One Collector process per archive; any number of accounts inside it.** The process is the archive's only writer,
which keeps the fork's single-writer design and its in-memory locks valid. Pointing an account at an archive is a line
of configuration:

```
[archive]   library = <NAS path>     data = <local folder>

[account "second"]   mode = "shared"          # writes into this archive
[account "third"]    mode = "shared"   start = false
```
An account that should have its **own** archive gets its own Collector folder and process, with, at the user's choice,
a read-only reference to another archive ("skip what that one already has", or "download anyway"). A lock in the
archive's data folder refuses a second Collector on the same archive. SQLite over the network is never used: the data
folder is local, only the library is on the NAS.

Logging an account in uses upstream's account wizard (`internal/accounts`, kept). The phone number is typed by the
user into the page and is never written to the catalogue, the report or a log.

### 5.2 Inside the process
```
                +----------------------- Collector ------------------------+
 account A ---> | runner A: session, client, waits, per-server window/slots |
 account B ---> | runner B: session, client, waits, per-server window/slots | ---> staging ---> library (NAS)
                |            \            /                                 |
                |        shared queue, catalogue writer, copy checks,       |
                |        staging copier, report                             |
                +-----------------------------------------------------------+
```
- A **runner** per account owns everything Telegram counts per account: the login, the request-rate limit, the wait
  gates, the per-server part windows and file slots. These are per-account objects in the code already
  (`floodGuard`, `downloadPacer`), and upstream's engine already carries an account on every queue row.
- **Shared:** one queue, one catalogue writer, one staging copier, one set of copy checks, one report with a section
  per account.
- A runner's fault (a panic, a dead session, a ban) stops that runner only. The fork's `ixBackground` guard is the
  model.
- What must change from the fork: 8 places assume exactly one account (the per-server slot logic and the top-up return
  early otherwise). They become "per account and server".

### 5.3 Recognising what is already there, cheapest first
For each message a runner reads:

| Step | Test | Cost | Result |
|---|---|---|---|
| 1 | Shared space, message number already catalogued | none | Add a sighting; nothing else |
| 2 | Telegram file ID already saved | none | Link the message to the saved file. **No download.** |
| 3 | Forward origin (source channel + post) already catalogued with a saved file | none | Link, marked "same post" |
| 4 | Telegram file ID being downloaded now by any runner | none | Wait for it, then link (the fork's "one worker per file" rule, now across accounts) |
| 5 | Different ID, but size, duration, dimensions and preview match a saved file | none, then the fork's sampled check if enabled | **Probable copy: held at the back, never skipped, never before unique files** |
| 6 | Downloaded, and the SHA-256 is already in the library | the download | Keep one copy, link both |

Steps 2-4 are exact. Step 5 is the fork's existing machinery with its rules unchanged. The user said the new groups
are likely to overlap with what is stored; how much of that overlap is the same uploads (step 2 or 3, free) and how
much is re-uploads (step 5 or 6) cannot be known until a new account reads its first chats. The report should count
each step from the first hour.

Per account or per chat, the user may choose "always download, even if saved" for an independent copy.

### 5.4 The queue with several accounts
- A queue item is **a Telegram file that needs bytes**, not a message. It lists the sightings through which it can be
  fetched. An account can fetch a file only through a message that account itself can see (file references are
  per account).
- A runner claims only items it has a sighting for, on a server where it has a free slot. If two accounts can fetch
  the same file, whichever has room first takes it; the claim is a database row, so the other cannot start it too.
- **Wanted list first:** files the old account knew but never saved rank ahead of files nobody has seen before,
  within the user's group ranking.
- Rankings and filters are per archive for shared chats, and membership is per account.

### 5.5 Waits, limits and risk with several accounts
Things I can state from the code and the fork's measurements:
- Telegram's waits arrive per account, and the fork already holds each wait on the request or server that got it.
  In Collector a wait on account A never holds account B, and B never has to honour A's wait.
- Under the speed limit the fork measured about 400 MB an hour per server for one account. Whether a second account
  on the same address gets its own allowance, shares the first's, or draws attention, is **not known and cannot be
  measured in advance**.

Things that are the user's decision, with a careful default:
- **Hand-over on a wait: ON by default (the user, 11-09), with a setting to turn it off.** If account A is told to
  wait on a file that account B can also fetch, B may take it: separate accounts have separate limits. Each account
  still waits out every wait Telegram gives **it**; no request is ever retried early or sent on another account's
  session. The report counts hand-overs per hour, so their effect can be seen.
- **How many accounts run at once.** The design allows any number; the default is the user starting each one by hand.
  Suggestion: run the new account alone first and read a week of reports before adding another.
- **Risk to the accounts.** The present account has been frozen since 10-31. An account used mostly to download in
  bulk, or several doing so from one address, may be limited or frozen by Telegram. I cannot estimate that risk. The
  design keeps each account's requests visible per hour and by kind so that the user can see what each one is doing.
- **Network path per account.** By default every runner uses the Collector's own network path (one VPN rule). If the
  user ever wants an account on a different path, a runner can be started as its own program under its own name, the
  way 12.22 starts `tgdl-viewer`. Not built unless asked for.

### 5.6 Why not share the fork's folder now
- `downloads` is unique on (chat, message) with no account, and 118,106 of 129,486 saved files are in chats whose
  message numbers are per account. A second account's "chat X, message 500" would be taken for a file already saved,
  and distinct files would be skipped as saved, silently.
- No table records which account saw or fetched anything, so a shared folder could never be split again.
- 8 code paths switch themselves off when more than one account runs.
If the new account must start before Collector is ready: a **separate install and data folder** of the current fork
for it, and `archive merge` afterwards. Its "already archived" skip can come from a read-only import of the old
archive's Telegram file IDs and SHA-256s (the deferred item 16), which is small on its own.

### 5.7 What Collector keeps, drops and adds
Keeps, as it is and with its tests: `internal/telegram` (parts, per-server pacer and floor, per-request waits with
their fallbacks, set-aside for dead parts, media routes, kept parts), `internal/engine` (queue, claims by server and
size, worker loop), `internal/download` (resume, exclusive publish, staging with journal and verification),
`internal/accounts` (login), the copy rules, the hourly report with its redaction test, the pre-update copy, the pin
and the drain-under-the-limit update rule.

Drops: upstream's front proxy, cluster and peers, cloud backup providers, share links, NSFW and seekbar sidecars,
stories, upstream's dashboard and its outside fonts and scripts, and the media browser (browsing is Archive's job).
About 45 of the fork's 134 tables are empty today.

Simplifies: 62 settings to the handful ever changed; tunables in one struct passed at construction; background loops
as components that tests start explicitly; state on components, not in 45 global maps (code review D2-D4).

Adds: account runners (5.2), the recognition ladder (5.3), the per-file queue (5.4), requests counted per account, hour
and kind as a first-class figure, and the review's later items (retry a failed queue write instead of stopping the run;
set-aside for silent parts; signed update checksums; a step back after three crashes).

### 5.8 Keeping the extraction honest
- Start from the fork's last live tag. Delete packages until only the kept ones compile, with every kept test
  passing at each step. No behaviour change in the same step as a deletion.
- The hourly report is the acceptance test: on invented data with a recorded sequence of Telegram answers, old and
  new programs must print the same per-server numbers for one account.
- Then the catalogue writer moves to the new format, then runners become plural, each as its own reviewed change.
  Two-account tests use two invented accounts against the fake part fetcher: same file via both, a wait on one, a
  runner that dies mid-file.

## 6. Archive: the viewer and curator

Unchanged in purpose from revision 1; what several accounts add is marked.

- **Rules:** no Telegram code, no session, no secrets, no outbound connection (a test asserts it). Never changes media
  files. Opens the catalogue read-only; its own decisions go to `decisions.sqlite`. Works with the NAS slow or absent
  (it is on Wi-Fi): thumbnails, text, vectors and search are local; only opening a full file needs the NAS.
- **Runs beside Collector.** Collector writes the catalogue, Archive reads it, as the viewer and the server do today.
- **Pages:** timeline; chats (as a conversation or as media only, forum topics as sub-pages); search (message text,
  captions, file names, recognised text); item (file, message, album, every place it was seen, copies with their
  evidence, people, tags, SHA-256 and last verification); people; copies review; sort out (tags, collections, bulk
  actions, clutter rules with a preview); health.
- **With several accounts:** a filter "seen by" (any, one account, more than one); on an item, "seen in" lists every
  chat and account; a basic group seen by two accounts shows as two chats linked by their shared files, with an
  optional merged view ordered by date; the copies page separates "same Telegram file" (exact) from look-alikes.
- **Commands:** `serve`, `check` (verify SHA-256s, resumable, gentle on the NAS), `export`, `backup` / `restore`,
  `consolidate`, `merge`, `split`, `doctor` (counts only, safe to paste to an assistant).
- **Export, readable without the app:** static pages per chat and month, the catalogue as JSON Lines with a README of
  every field, and `manifest-sha256.txt` in `sha256sum` format so the whole library can be verified with no app.
- **Front end:** no framework or build step, split into one module per page, under the viewer's strict policy (no
  inline script, no outside hosts). A browser check feeds hostile names and captions from the invented fixture.
- **Updates by hand**, with a signed checksum. A viewer has no reason to update itself.

### 6.1 What the user found wrong with 12.22's viewer, and what the design does about each
These come first in the viewer work, ahead of new features. The aim, in the user's words: it is a media viewer, so the
objective is viewing the media, as the most complete set, sourced from everywhere it was posted.

| Complaint (11-09) | Likely cause in 12.22 (from the code, not yet measured) | Design answer |
|---|---|---|
| Slow to open the item page | The item page is built per request from the big database, with the owner's decisions re-read each time (`overlay` reads five tables per request) | One request returns everything the page needs from the compact catalogue; decisions cached in memory and refreshed on change; target under 200 ms on the 127,000-file fixture, measured in a test |
| Slower still to load or play a file | Every full file comes from the NAS over Wi-Fi (about 14 MB/s shared with the copier); videos the browser cannot play are converted on demand | The thumbnail shows at once and the file streams by range; a local cache of screen-size previews for pictures and of the first seconds of videos; conversion done ahead in the background for the formats that need it; the next item preloaded |
| Cannot see how things were actually posted (albums) | Each file is its own tile | **The post is the unit.** An album opens as one post with all its files in order and its caption; the grid shows one tile per post with a count |
| Chats does not work: every file is a standalone item | Same cause | Chats is rebuilt as a conversation: posts in order, albums together, text, forwards and replies, with a media-only switch |
| 20+ suspected copies shown on an item | Every copy edge is listed | Copies fold into **one line with a count**, closed by default, and the choice is remembered for every item; opening it groups them as "same file", "probable" and "related" |
| The most complete set, from everywhere | A post shows only its own files | **Set view:** when the same album or series was posted in several chats with different files missing, the item shows the union, in order, each file marked with where it came from and which posts lack it. The fork's album cross-references (`ix_relations.go`) are the starting point. Files matched only as "probable" are shown as such, never silently merged |

The user will ask for a separate privacy-conscious review of the current viewer; its findings feed this list.

### 6.2 Reaching the viewer from other devices at home
Off by default. When turned on: a password is required (stored hashed), the connection is HTTPS with a certificate
the app makes for itself (the browser warns once per device), sessions end after a set time, sign-in attempts are
limited, and it listens only on the home network's address, never on the VPN's. The page that turns it on says
plainly what becomes reachable. Nothing is ever opened to the internet.

### 6.3 Where things are kept
```
<library on the NAS>\            media files, written by Collector only
<archive data folder, local>\
    catalogue.sqlite             written by Collector (or by consolidation), read by Archive
    decisions.sqlite             written by Archive
    cache\thumbs, play, vectors  disposable
    collector\                   queue, settings, sessions, report, staging journal: Collector's own
    backups\                     dated copies of catalogue and decisions
```
Copies (the user, 11-09): the catalogue and decisions live on the desktop and are backed up nightly to the NAS, so
they exist in two places. The media exists once, on the NAS; no other device can hold it. The hash manifest is kept
on the desktop too, so damage to a file on the NAS can at least be detected.

## 7. Repository shape
One repository, packages with hard walls:
- `catalogue`: schema, readers and the single writer, consolidation, merge, split, export. No network imports.
- `archive`: the viewer. Imports `catalogue`. A test fails if anything under it imports a Telegram or HTTP-client
  package.
- `collector`: runners, queue, staging, report. Imports `catalogue`. Everything that talks to Telegram is here.
- `fixture`: invented archives at three sizes (tiny, 5,000 files, 127,000 files), with one or two invented accounts
  and overlapping chats. Every test and screenshot uses it.

## 8. Phases
Sizes are in working sessions (a focused day of build, test and review), not dates.

| Phase | Delivers | Size | Done when |
|---|---|---|---|
| 0. Before 11-30 | Section 3's five items, inside the fork's remaining releases | small | The last index and backup complete in a rehearsal; a restore drill matches the counts |
| 0b. Stopgap for the new account | The fork's "already archived" import (item 16): a second install in its own folder reads the old archive's Telegram file IDs and SHA-256s read-only and treats them as saved. Needs the user's go-ahead and a challenger review (download path) | 2-3 | On invented data, a second install skips every file the first one holds, with zero part requests for them; the first install's folder is never written |
| 1. Lift out the viewer, and fix what the user found | `archive.exe` from a new repository, opening the fork's database in place, read-only. No upstream code. Then section 6.1: posts and albums as the unit, Chats as a conversation, folded copies, the set view, and the speed targets | 3-5, then 6-9 | The fixture viewer test and the browser check pass on it; the item page opens in under 200 ms on the big fixture; the user says the six complaints are gone |
| 2. Account-aware catalogue | The format of section 4; `archive consolidate`; Archive reads the new catalogue | 5-7 | Per-table counts match the source; every page answers the same on old and new for the fixture |
| 3. Collector, one account | The extraction of 5.7-5.8, writing the new catalogue, with the recognition ladder against the consolidated archive | 10-14 | Same report numbers as the fork on the recorded run; a new invented account skips every file the fixture archive already holds, with zero part requests for them |
| 4. Several accounts | Runners, the per-file queue across accounts, per-account report sections, the hand-over setting (default off) | 4-6 | The two-account tests of 5.8 pass under the race detector; one runner can be stopped and started without touching the other |
| 5. Merge and split | `archive merge`, `archive split`, own-archive mode with a read-only reference | 3-5 | Merging two fixture archives then splitting one account out gives back the same counts |
| 6. Viewer features | Search; sort out; export and backup; reaching it from other devices (6.2); the several-account views; "always download" per chat (low priority) | 10-14, in any order | The user's top complaints after a week of use are fixed |

**The new account may start around 11-30 or sooner**, and Collector (phases 1-3) is about 18-26 sessions away, so the
new account will most likely begin on the stopgap (0b): the current fork in a separate folder with the "already
archived" import, merged into the shared archive once phase 5 exists. Hand-over between accounts and the shared queue
do not exist in the stopgap: the two installs know of each other only through the read-only import.

If the new account starts **before** 11-30, the old and new accounts would download at the same time from the same PC.
That is the user's decision to make (section 10); the fork's own rule "never add sessions or accounts" is about the
old account's install, which stays untouched either way.

## 9. Risks
| Risk | Answer |
|---|---|
| Building the new app distracts from the deadline | Nothing new before 11-30 except section 3 |
| A shared archive wrongly treats a distinct file as saved | Exact skips only on Telegram file ID (as the fork does today for 19,345 links) or SHA-256; everything else is "probable" and held, never skipped. Message numbers are never compared across accounts outside shared spaces |
| An account is frozen or lost | Its runner stops alone; everything it saw stays in the archive under its label; another account can fetch the files it never saved, when it meets them |
| Telegram treats several accounts as one | Unknown and unmeasurable in advance; start with one, add by hand; hand-over on waits is on by the user's choice, counted in the report, and can be switched off |
| The user later wants the accounts apart | Every sighting records its account; `archive split` |
| Consolidation loses or changes a fact | It only reads the old database, which is kept; counts per table are recorded and checked |
| Two programs write one catalogue | One Collector per archive, enforced by a lock; Archive opens it read-only |
| The NAS holds the only copy of the media | Outside this plan, but worth a decision: at least the catalogue, decisions and the hash manifest should also live on another device |

## 10. Decisions for the user
The nine questions of revision 2 are answered (see the top of this file). Still open:
1. **Build the stopgap import (0b) now**, so it is ready whenever the new account starts? It is a change to the fork
   and would ship in a release of its own, or with 12.24.
2. **If the new account starts before 11-30**, may it download at the same time as the old one from this PC, or
   should it wait until the old account has stopped?
3. **The set view's default:** when the same album was posted in several places with different files, show the union
   by default (assumed yes, from "the most complete set, as sourced from everywhere"), with each file's sources
   one click away?
4. **The privacy-conscious review of the current viewer:** before or after its lift-out into `archive.exe`? Before
   means fixes land in the fork first; after means they land once, in the new program.
