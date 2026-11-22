# Review B7-S1: the viewer knows the account's own chat as "Saved Messages" (`wip/b-saved` 076eeab7, base 78739d59)

One independent Opus reviewer, read-only on the reviewed copy, 11-16 about 19:07 to 19:37 (it waited for the
track's lock for part of it); written down by the viewer session B7 from its hand-back (the reviewer could not
write files). Plants in its own scratch copy `wt-b7-review-S-scratch` (left in place, clean). The session's
decisions are at the end.

## Verdict: MAY BE LISTED AFTER THESE FIXES (one small page fix; everything on the server side holds)

## Findings
1. **Medium.** `web/js/saved.js` with `chat.js` (its uses of `navigate(..., {replace:true})`) and `main.js`'s
   `route()` (56 to 88). On `/saved` the inner chat page moves the address to `/chat/ID?...` the first time it
   changes its own address (a filter, the month jump, a live reset, the way back after a post closes); the
   router then sees the key `chat` where `saved` is current, unmounts, clears the main area, scrolls to the
   top and mounts a new chat page. The person sees one flash and jump per visit; after a live reset, or
   after closing a post whose place is outside the loaded window, the reader's place is lost. Smallest fix:
   once `saved.js` has the id, replace the address with `/chat/ID` (the query kept, without `account`).
2. **Low.** `web/js/item.js` 573: a post's head hid the sender when it equalled the chat's title; in Saved
   Messages it now reads "Saved Messages" and then the account's own name. Harmless.
3. **Low.** `web/js/library.js` (424, 638) and `overlap.js` (143): the library's "Find a chat" and Overlap's
   finder match only the shown title: typing the account's own name no longer finds its chat (the Chats
   page's finder matches both).
4. **Low, older than this piece and outside it.** `marks.go` 72 to 77: a per-account chat's stable key holds
   the owner account's Telegram number. When a sign-in writes that number after marks exist (0 becomes N),
   every per-account chat of that account gets a new key and its marks stop applying.

## The seven questions, in short
1. Every path runs the rule: the chats come only from the writer's read (`refresh.go` 487 to 502) and its
   apply (1206 to 1218); no second constructor, nothing patches one chat in place. A Telegram number written
   later turns the mark on at the next update with no full read (tested).
2. Every Go use of the title goes through `shownTitle` but the `name` field and the comparison. Text search
   covers messages only. Sorts by title file the chat under "S".
3. Nothing is keyed by a title (marks and hidden chats use the space's key).
4. `/saved` gets the same guard and headers as every page route, in the LAN mode too; one or two accounts,
   an unknown account ("No such account in this archive.", a sentence the brief did not have), no account:
   all bounded, all text drawn as text; the extra ask of `/api/meta` cannot loop.
5. `chatsInOrder` is a valid order; counts as before.
6. Nothing per file or per message beyond one branch.
7. Plants (each alone): `ownChats` not called, without "never 0", `/api/overlap` from the title as read,
   the marks' key from the shown title, the route removed, own chats not first: each caught by named tests.
   Without "not shared" and without comparing `self`: not caught, and both harmless (the catalogue's own
   check makes the first condition follow; `self` is derived from fields already compared).

## Not checked by the reviewer
The bring-in's answer for the old archive; the look through the viewer's answers; a real browser; the whole
package, gofmt, vet.

## The session's decisions (B7)
- **1 and 3: fixed in one small round** on `wip/b-saved` (the reviewer's smallest fix for 1; both finders
  match the name as read too), with the main head merged in; then the full run once.
- **2: accepted as it is.**
- **4: not this piece.** Written on the board for whoever next touches sign-in or the marks: a sign-in that
  fills an account's Telegram number after marks exist orphans that account's per-chat marks. To be judged
  with Core (who writes the number, and when) before a fix is chosen.
