# Review of W3: the Overview's numbers as links; "Needs you" (pages, P7, 2026-11-21)

Read: the briefs (W3 and the house rules), `DESIGN-ONE-WINDOW.md` point 4, the coder's report, the whole diff
`af4ca40e..c84c77ed` (`overview.go`, `overviewneeds.go`, `server.go`, `places.js`, `ui.js`, `parts.css`,
`overview.js`, `queue.js`, `chats.js`, `chatmirror.js`, the tests), and around it `notadded.go`, `chats.go`,
`queue.go`, `queuenow.go`, `overviewcache.go`, `viewer.go`, `shell.go`, `appshell/shell.go`, `catalog/chatreads.go`,
`catalog/changelog.go`, the c_want state writers in `catalog`, `window/joined.go` and `pages_windows.go`.
Ran (scratch copy at c84c77ed, through the track's lock, environment redirected to `%TEMP%\p7-w3rev`, invented data,
headless Edge driven over DevTools, no window): uncommitted probes `zz_probe_w3_test.go`: `TestZZW3States`,
`TestZZW3Scale`, `TestZZW3ScaleParts`, `TestZZW3CDP`, `TestZZW3Focus`, `TestZZW3Look`; all ran to the end (exit 0).
16 screenshots (1400x900 and a true 390 px, light and dark) are in `%TEMP%\p7-w3rev\shots`; I looked at them.

## Findings

1. **MUST FIX: "Needs you" says "n held probable copies" but counts every held file, and opens a place that lists
   another set.** Confirmed (`TestZZW3States`, `TestZZW3CDP` PLACES). On the invented archive the item reads
   "27 held probable copies". Of those 27, 9 are probable copies (`probable = 1`). The other 18 are 14 held by hand,
   3 whose "chat does not collect this kind of file" and 1 "over the size limit set for this chat". A file the owner
   chose to keep held (`keep_held`) would count too. The Queue's own Held note says the same thing: "They look like
   a file already saved, or their chat does not collect them".
   `places.js:140` uses `by.held`, which is the totals' state `held`. The link goes to the viewer's
   `/?copies=probable`, which lists posts by its own probable-edge rule. So the owner reads 27, opens the review and
   sees a different, smaller set. On the real archive, chats set not to collect a kind could make the gap large. The
   design says "2 probable copies opens their review", which means the number has to count what the review shows.
   Also, with no viewer address the item is plain text with no place at all, although the Queue's Held exists.
   Smallest cure: count `state = 'held' AND probable = 1 AND keep_held = 0` (add it to the totals' kept read and
   measure it at size), and keep the viewer link for that count. Or, if that read cannot be made cheap, word the item
   "n held files" and link it to `#/queue?show=held`, which lists exactly the totals' count (the tile does this
   already, and the browser test confirms the counts match).

2. **MUST FIX: the one new read is over the brief's 50 ms line when several chats are being read.** Confirmed
   (`TestZZW3Scale`, `TestZZW3ScaleParts`, at 5,017 chats and 2,000,792 messages, the W1 review's archive).
   - 20 reads under way, 100,000 messages each:
     - the count worked out: median 180 ms in one run, 236 ms in another (max 246 ms);
     - the whole `/api/overview` worked out: median 226 ms.
   - 1 read under way: 30 ms.
   - no read under way: 21 ms.
   - for comparison, the overview's own numbers alone take 0.5 ms.

   The coder measured with a single read under way (25.5 ms). The cost is `ListChatReads`' covering
   `COUNT(*) FROM message` per read under way (`overviewneeds.go:66`). `notAddedCount` never uses that count: it needs
   only `added` (an approval or a cursor), the word "done" and `mirror_of`.

   While downloads move the key, this read runs at most once per 5 s, as designed (46 polls from two Overviews in
   12 s caused 2 work-outs). So the owner pays about 0.2 s of catalogue reading every 5 s while the Overview is open,
   and each Overview answer waits on it under `needMu`.

   Smallest cure: a dedicated count without the message count. It needs the chat walk, the approval setting rows,
   `cur_at`/`cur_done` and `mirror_of`, by the same rule, and is kept equal to the Chats filter by a test like
   `TestOverviewNeedsChatsNotAdded`. The "no read under way" figure (21 ms) bounds its cost.

3. **SHOULD FIX: a live update can change what the focused "Needs you" link says and where it leads, under the
   keyboard.** Confirmed (`TestZZW3Focus`).
   1. The keyboard is on "5 chats joined, not added yet" (`#/chats?read=not_added`).
   2. The next answer removes the held item and adds the failed item, so the list still has two items.
   3. `repaint` takes this as the same shape (`overview.js:43` `sameShape` compares only tags and child counts) and
      `copyWords` (`:51`, `:54`) copies the words and `href`, but not `data-place`.
   4. The focused link now reads "7 failed files (set aside)" and leads to `#/queue?show=failed`, while its
      `data-place` still says `needs-chats-not-added`.
   5. Enter went to `#/queue?show=failed`.

   The next rebuild then puts the keyboard back on the wrong item, because the stale `data-place` still names it.
   Smallest cure: treat a different `data-place` (or `href`) as a different shape in `sameShape`, so the region is
   rebuilt and the keyboard goes to the item of the same name.

4. **SHOULD FIX: "n failed files (set aside)" under "Needs you" counts every set-aside file, including files nothing
   failed for, which come back by themselves.** By reading. `places.js:144` uses `by.aside`. The catalogue sets files
   aside with no attempt spent while their frame check is judged (`ReasonProbeJudging`, `probe.go`) or when the exact
   check could not start yet (`ReasonExactNotStarted`, `exactcheck.go` `CheckLater`). Every set-aside file also gets
   its `retry_at`, so it comes back by itself.

   When a batch of frame checks is being judged, the owner reads "40 failed files" under "Needs you" although nothing
   failed and nothing waits for them. The Queue's "Failed, with reasons" lists the same set (the count does agree with
   its place: confirmed, 7 = 7). The fixture had only one reason, so this was not seen in a run.

   Cure: count only the reasons that come from a failed try (`asides > 0`, or the reasons `state.go:285` writes), or
   word the item as the Queue does ("n set aside") and leave it out of "Needs you".

5. **MINOR: "n chats joined, not added yet" counts chats no account is in.** Confirmed (`TestZZW3States`): of 5 chats
   not added on the invented archive, 1 is reached by no account (`summarise(...).reachable` false). Refused reads
   and chats left (access gone) fall in the same group by `readGroup`, so the word "joined" is wrong for them; the
   count matches the Chats filter (5 = 5, confirmed). Cure: drop "joined" from the words (`places.js:143`), or count
   and filter only reachable chats on both sides.

6. **MINOR: the Chats selects do not write the address, so the back button restores a filter the owner cleared.**
   Confirmed (`TestZZW3CDP` SEL1–SEL3).
   - Open `#/chats?read=not_added` and set Read to "Read to the end". The chip says so, but the address stays
     `?read=not_added`. Going to the Queue and back brings back "not added yet (5)".
   - Choosing Mirror "Waiting for the automatic mirror" in its select leaves the address at `#/chats`.

   The brief asked for "the selects and the address kept in step both ways". Cure: on each Read or Mirror select
   change, `history.replaceState` with the filters in force (`chats.js:469`, `chatmirror.js` `filter()`).

7. **MINOR: an unknown `mirror=` value gives a chip with odd words.** Confirmed (`TestZZW3CDP` ADDR).
   - `#/chats?mirror=constructor` gives "Showing: function Object() { [native code] } (0)".
   - `mirror=__proto__` gives "Showing: [object Object] (0)"; `toString` gives a similar line.
   - `mirror=bogus` gives "mirrors: bogus (0)".

   In each case the Mirror select shows "All" while the table is empty. `places.js:90` looks the value up in
   `mirrorShows` without an own-property check, and `chatmirror.js:44` accepts any value. Only text is shown; no
   markup ran (a hostile value showed as text, `inj: false`). Cure: accept only the known groups, as `chatsRead` does
   (`hasOwnProperty`), in both places.

8. **MINOR: a failure of the new count blanks the whole Overview.** By reading. `overview.go:232` answers
   `s.fail(w, err)` when `overviewNeeds` fails. The page then shows one error box in place of every region (lanes,
   mirrors, the hours, the tiles), all for one item of "Needs you". Cure: log with a constant format, answer without
   `needs` (the page already treats a missing `needs` as 0 through `whole`).

9. **MINOR: the count can stay old for up to an hour when another process changes a read.** By reading. The cache's
   key (`countsKeySQL`: `change_log`, `copy_edge`, the highest chat id) misses two kinds of change:
   - an approval written by the collector (`-approve-read`): this is the case the report names;
   - a cursor the collector sets: `account_chat`'s `cur_at` is not among the logged columns
     (`schema7.go:237` logs `access`, `tg_access`, `joined_at`, `left_at`).

   While downloads run, other changes move the key every few seconds, so the owner meets this only when idle: a chat
   started from the console stays under "not added yet" until the next hour. The Chats page has the same key, so the
   two agree. Cure: none needed now; note it beside the item's "as of", or add `cur_at` to the logged columns in a
   catalogue step.

10. **MINOR (by look): a filtered Queue has an empty band of about 130 px between the counts and the region shown.**
    The 1400 px dark screenshot of `#/queue?show=held` shows it. It is most likely the panel's spacing around the
    hidden regions' empty boxes; I did not confirm the cause. Cure: hide the empty boxes (`hidden`) instead of
    mounting nothing.

11. **MINOR (by look): at 390 px the Chats page's chip sits below the whole filter block, off the first screen.** On
    the first screen the owner sees the selects, not "Showing: … · show all". Cure: mount the chip above the filters
    or beside the page's heading, as the Queue does.

## Checked and sound

- Every link of the pages' own places, clicked on the Overview, lands on its place with the chip, and the chip's
  count equals the number (confirmed: Still wanted 143, Held 27, Set aside 7, Gone 5, failed 7, mirrors blocked 1,
  waiting 1, chats not added 5).
- "show all" takes the filter out of the address without a reload (`#/queue`, `#/chats`) and puts the keyboard on
  the server's tab or the search box; back then returns to the Overview.
- The viewer link is a plain link (no `target`). Clicked headless, it loads the viewer's `/?copies=probable` in the
  same document. The window's rules (`joinedSet.allows` for a navigation) let it through, by reading.
- Hostile and odd Queue addresses fall back to the whole Queue with no chip and no console error: `show=__proto__`,
  `constructor`, `toString`, `HELD`. So do `read=__proto__` and `read=constructor` on Chats. `show=held&show=failed`
  takes the first. `dc=abc` and `dc=99` with a filter work and draw nothing wider than the window.
- Two filters at once on Chats (`read=` and `mirror=`) apply together, with one chip naming both.
- Live updates:
  - a tile's number moving keeps the same node under the keyboard (28 shown in place);
  - the Downloading tile appearing rebuilds the tiles and puts the keyboard back on the Held tile;
  - a lane injected into the live answer gets its link `#/queue?dc=2&show=now`, and its count moving at each answer
    keeps the focused node.
- `/api/shell` reads:
  - 2 at load (the frame's and the Overview's);
  - none more in 12 s steady;
  - exactly one more when the viewer stopped answering, after which the Saved tile and the held item became plain
    with the list's words as title;
  - a live answer fed to flip the viewer at every answer gave one read per flip, never more. The server keeps the
    viewer's look for 10 s, so a real flap is at most one read per 10 s.
- The count's cache: kept while nothing changes; worked out at most once per 5 s while the key moves, even with two
  Overviews polling.
- Nothing in the new code reads the library's files.
- No HTML sink: every server value and address value reaches the page as `text`, `title` or an `href` taken from
  the app's list. The hostile `mirror=` markup showed as text and created no element.
- The look: no page is wider than the window at 390 px or 1400 px, light or dark (Overview, Queue held, Chats with
  one and two filters). The Needs you links measure about 6.6:1 in light and 9:1 in dark. The tile links are
  underlined in the tile's own ink.

## Not verified

- **Needs a real window:**
  - a click in the real window (WebView2) on a viewer link from the pages;
  - keyboard focus with a real keyboard (the headless probes used `focus()` and `click()`).
- What the real viewer lists at `/?copies=probable` against the count: no viewer ran (a stand-in answered).
- Finding 4's reasons on a filled catalogue: the fixture's set-aside files all carry one reason.
- Whether the empty band in finding 10 comes from the panel's spacing.
- The whole `internal/server` package, the race detector, and the coder's own tests were not run (not asked).
