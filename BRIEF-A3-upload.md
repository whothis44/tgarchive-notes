# Brief A3: send a file from this PC (the upload)

For one Opus 5.5 coder at high effort. The client track (session A-1), 2026-11-22. The owner agreed to it on
11-21 ("Yes, all eight"). The design is `C:\Users\trabi\Claude\Projects\Telegram\DESIGN-CLIENT-acting.md`,
sections 3, 4.1, 4.2, 5 and 6 point 3, and choices 2, 3 and 7. Read it in full first.

**Nothing in this piece runs against Telegram.** The house rules are those of `BRIEF-A1-chat-actions.md`
section 0, word for word, with the lean changes below:
- You hand back a branch ready to list: `gofmt`, `go vet`, your named tests and the whole of any small
  package you changed.
- Never run the whole `internal/catalog` or `internal/collector`.
- After your hand-back there is one independent review. Its fixes come back to you.
- **The race detector IS needed this time**, on the named tests of the new worker. It runs concurrently;
  see 2.2.

## 0. Where you work

- **Copy:** `C:\Users\trabi\Claude\Projects\Telegram\wt-client-upload`, branch `wip/client-upload`, cut from
  `wip/client-afile` at ef0293ae.
  - That head holds the main head 6aa225fb, the shared frame 2bb5a715 (kind `ActUpload` and its word
    already exist), and piece 2.
  - Piece 1's later commits are not in it; the merges are done at listing.
  - Push only `wip/client-upload` to `private`.
- **Schema:** step 35 on the board, a new table `c_act_upload` in a new file `schema_actupload.go`. No column
  on `c_act`. On your branch it is the step after piece 2's (`actFileSchema`), with the number in two
  constants.
- **Lent lines:** lines in Core's files go in ONE "Lent to Core:" commit. Lines in pages' files
  (`internal/server`, `internal/actdoor`) go in ONE "Lent to pages (server):" commit. Do not touch
  `internal/viewer` or `internal/window`. No page, no HTML: the UI is being reworked.

## 1. Read first

- The reports `archiver/docs/progress/core-act-REPORT.md` and `client-afile-REPORT.md`, and the review
  `C:\Users\trabi\Claude\Projects\Telegram\REVIEW-A2-file-from-archive.md`.
  - **Its F2 is binding here: no request of a click may hold the collector's account loop.**
- `C:\Users\trabi\Claude\Projects\Telegram\REVIEW-A1-chat-actions.md`, for what reviewers catch in this
  layer.
- **What the old app knows** (design section 2): `wt-v12.31/core-service/internal/telegram/forward.go`.
  - It used one upload stream with one thread (`uploader.NewUploader(api).WithThreads(1)`), then
    `messages.sendMedia`.
  - A JPEG or PNG of 10 MB or less went as a photo, anything else as a document with a MIME type and
    attributes.
  - It made a fresh random id per try. **Drop that:** one random id per click.
- `internal/footage` (and `FFMPEG_PATH`, the setting that names ffmpeg): how the app already probes a
  video's length and size.

## 2. What to build

### 2.1 The bytes reach the collector through the door, never as a path (choice 2)

- **A new door route, `POST /api/act/stage`, the one exception to the door's JSON body limit.**
  - The body is the file's bytes, streamed to a file in a folder of the app's own: `staging-act` beside
    the catalogue file, as the door file sits there. Name the file by a random staged id; the click's number
    is not known yet.
  - Header fields carry the size, a file name and a MIME type.
  - It answers the staged id, the size and the SHA-256.
  - Same guard and secret as every door route.
- **Checks before a byte is written:**
  - The size is within the server's maximum, which is `upload_max_fileparts_default` × 512 KB.
    `help.getAppConfig` is asked once and kept, counted under its own kind. Not known means refused.
  - Free disk space is at least the size plus 10%.
  - At most one staged upload per account at a time; a second is refused "an upload is already waiting".
  - A body longer or shorter than its size is refused, and its partial file is removed.
- **The click:** `POST /api/act/queue` with `kind: "upload"` names the staged id, the destination, a topic, a
  reply, a caption, and "as a file" (true: always a document). The queue moves the staged row to the
  click's row (`c_act_upload`, keyed by `c_act`'s id).
- **Removal:**
  - The staged file is removed as soon as the click's outcome is known and final: done, refused, cancelled,
    the owner finished with it, or "not sent" with no send again.
  - It is removed at a start for every staged id with no live click.
  - A staged id never queued is removed after 1 hour.
- Nothing of the name, the path or the bytes goes in a log. The file name is sent to Telegram as the
  document's name attribute; it is the owner's file and the owner's choice.

### 2.2 The parts go up in a worker of their own, never in the click's turn (choice 7)

- **One upload worker per account, one upload at a time, one part at a time**, as the old app did. It is a
  goroutine the collector starts and stops with the account.
- **Parts:**
  - `upload.saveFilePart`, or `upload.saveBigFilePart` over 10 MB, of 512 KB under a file id the worker
    makes.
  - Count each part under its own kind, `upload_part`.
  - **A stated wait on a part is slept in full in the worker, and the part is then sent again.**
  - A part with no answer is sent again, at most 3 times. A part refused for good ends the upload: the click
    ends "not sent", with the word.
  - **This is the only place where the program repeats a request by itself.** The owner agreed to it as
    choice 7.
- **Order of a click:**
  - the queue;
  - every local "no" of the text step (frozen, account refusal, mirror destination, caps, remembered
    refusal, limits, caption by `CaptionMax`), as piece 2 does it after its F1 fix;
  - the worker uploads every part;
  - then, and only then, **the send goes through the click's turn like any click:** `Begin`, the re-check
    after `Begin` (frozen, mirror, the account's refusal), and one `messages.sendMedia` through `report`.
    It is never repeated by the program, a wait is reported and not slept, and a lost answer is "not known".
- **The two-minute rule.** A click older than 2 minutes at `Begin` is "not sent in time". So the age of an
  upload click counts from the moment its upload finished, not from the queue. Say exactly how in the report.
- **Media:**
  - A JPEG or PNG of 10 MB or less, not "as a file", goes as `inputMediaUploadedPhoto`.
  - Anything else goes as `inputMediaUploadedDocument` with its MIME type and `documentAttributeFilename`.
  - A video gets `documentAttributeVideo` (duration, width, height) from the app's existing probe when ffmpeg
    is found. If not, it goes as a plain document; say so on the outcome.
  - No thumbnail upload in this piece.
- **Cancel:**
  - Before the send's `Begin`, it stops the worker at the next part and removes the staged file. The click
    ends "cancelled"; nothing has been sent and nobody sees anything.
  - After `Begin`, cancel is refused, as for any click.
- **A program stop during the upload** ends the click "not sent". The parts on Telegram are harmless. Nothing
  resumes by itself at the next start; the owner's "send again" uploads again from the start.
- **Progress for a page:** the state call or the click route reports the parts sent of the total and the
  bytes. It reports no speed claim: the first real use measures speed.

### 2.3 A "not known" upload is settled from the chat, carefully

- **A document** is settled by the account's own new message in the destination after the request, with a
  document of the same size, the same file name and the same caption, and nothing else matching. Apply the
  send's 7-day guard and its gap check, as piece 2's F5 fix does.
- **A photo** is never marked "arrived" by the app: Telegram re-encodes it, so its size proves nothing. The
  candidates are shown and the owner decides.

## 3. Tests (each seen failing first by `-overlay`)

- R1 to R12 for the send.
- The worker:
  - parts in order;
  - a wait on a part slept in full, then the part sent again;
  - a lost part sent again at most 3 times;
  - a part refused for good;
  - cancel at each point;
  - a stop during the upload;
  - one upload at a time;
  - **the account loop is never held by an upload**: a reader turn and a text click go through while a
    100-part upload runs at the fake.
- The stage route:
  - the size limit, the disk check, a short body and a long body;
  - one staged file per account;
  - removal at an outcome, at a start, and after an hour.
- The photo and document choice and the attributes, flags bit for bit.
- The settle: the document's exact match with the 7-day guard; a photo never auto-"arrived".
- The privacy test: no name, path, caption or id in a log or an error.
- An end-to-end test at the collector's fake Telegram through the door: stage, queue, the parts, one
  `sendMedia`, exactly those requests.
- **`go test -race` on the worker's and the collector's named tests** (the concurrent code). Never on whole
  packages.

## 4. Hand back

- `archiver/docs/progress/client-upload-REPORT.md`: short, laid out as piece 2's.
- The branch pushed, the lent commits apart, the copy clean.
- Stop and hand back at anything that would need a real request, a change in the viewer or the window, or a
  decision the design does not make.
