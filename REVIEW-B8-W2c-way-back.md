# Review B8-W2c: the way back to the viewer by a new-window link (`wip/b-onewin` 99cef0f1..bedbc04f)

One independent Opus reviewer, read-only on the copy `wt-b-onewin`, 11-16 20:18 to 20:20; written down by the
viewer session B8 from its hand-back (the reviewer cannot write files). It read the change, `origin.allows`,
`pagesNewWindow` and the viewer's route for its first page; it built and ran nothing. The session's decisions
are at the end. The brief of the change: `BRIEF-B8-W2c-way-back.md`. The review it follows:
`REVIEW-B7-W2-one-window.md` (finding 1).

## Verdict: MAY BE LISTED

## The answers
1. **No address gets through that is not a named address or the viewer's first page.** `viewerRoot` first
   needs `origin.allows` (`allowed.go` 32 to 41: no backslash, NUL, CR, LF or TAB; scheme http; no user part;
   no opaque part; the host exactly `127.0.0.1:PORT`). Refused on the host: a trailing dot, `127.1`,
   `0x7f.0.0.1`, `2130706433`, an IPv6 form, `localhost`, an empty port, a leading zero, look-alike digits,
   percent-escapes. Refused on the user part: `u@` and a bare `@`. Refused on the path (only "" or "/"
   passes): `//`, `/.`, `/x/..`, `%2e`, `%2F`, `;x`, a trailing space. Any `?` or `#` is refused before
   parsing. An upper-case scheme is accepted (Go lower-cases it): it is still the first page. The forms an
   engine would collapse to "/" are refused: that fails safe.
2. **Nothing new is opened, and finding 1 stays closed.** The viewer's first page is only `GET /{$}` to
   `servePage` (`viewer/server.go` 98 to 100): it changes nothing, does not redirect, reads no query. A plain
   link already reaches the same document; a window-made navigation gains nothing on "/". The viewer's
   files and api stay refused as new windows.
3. **Counting is right.** The first page is counted once, as opened here; any other readable viewer address
   once, as refused; an unreadable one once, as unreadable. The plain pages mode is unchanged.
4. **Moving `textOpening`** into `pages.go` (built on every system) is safe: one definition, the same value.
5. **The self-check's (b2) and (b3) measure what they print:** (b2) needs a new navigation ending at the
   viewer's "/" and "opened here" plus 1, so a refusal cannot pass; (b3) needs refused plus 1, "opened here"
   unchanged and no navigation, so a followed request cannot pass.
6. **The table catches the plausible wrong edits** (dropping the `?#` check, accepting any path, cleaning
   the path).

## Findings (all low)
1. `joinedcheck_windows.go`, (b2): it runs even when (b) "back" failed, so the click could come from a
   viewer page and the printed "from the named page" would be wrong.
2. `joinedcheck_windows.go`, (b3): when its return to the named page fails, (d) and (e) go on from wherever
   the window is.
3. `joined_test.go`: one row twice (another port); rows missing as documentation only: an upper-case scheme
   (true) and the root followed by a dot (false).

## Not checked by the reviewer
The viewer's page scripts (whether the first page restores some state by itself); the listener for other
devices; `NavigationStarting`'s handler itself; the engine's real canonical form (reasoned, not observed).

## The session's decisions (B8)
- **1, 2, 3: accepted as they are, said in the entry.** All three are in the self-check's wording and the
  test table, none in the rule; the self-check ran in the real window on the merged build with every
  step true (14 checks, 0 failed), so neither failure path of 1 and 2 was taken. They go with the next
  piece that touches the joined self-check.
- The rule was also read by the session whole before the review (`viewerRoot`, `joinedNewWindow`, the
  call site).
