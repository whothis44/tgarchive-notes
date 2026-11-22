# Archive page: one place for each control (proposal for ix.12.3)

Nothing has moved yet. Every move keeps the same setting key and API, so saved settings and the dashboard keep working. Each control also gets one line saying what it affects.

## What is duplicated or contradictory today

1. **Copy counts show up three times, with different wording.** Overview → "Copies, duplicates and integrity", Overview → Downloads → "Copies in the queue", and Settings → Copies ("Now: N held…").
2. **Copy settings are split across two cards.** "Hold likely copies", "keep them held" and "Don't download exact re-uploads" are in Account safety. "Skip confirmed copies", "Compare previews", "Sharper previews" and "Calibrate" are in Copies. And "Hold likely copies" also turns big-video sampling on or off.
3. **Order is set in four places.** The ranking and its policy are in Priorities, ★ First is in Rescan, "deletion-date order" is in Account safety, and "Save a lower quality first" plus "Files of 1 GB or more at once" are in Big videos and the NAS.
4. **"Finish" is in two places.** The Overview group table has a Finish button per row and "Finish all complete groups". Rescan → Choose groups has finish/reopen for the ticked groups.
5. **Account safety holds unrelated things.** It has rescan pace, quiet hours, the deletion-date order, download pacing, pause on freeze, auto-retry, the copy settings and the monthly integrity check.
6. **Freeze is shown two ways.** "frozen false" in `[account]` and "freeze: since …" are two different notions on one screen.

## Proposed layout

| Control | Now | Goes to | Why |
|---|---|---|---|
| Group ranking, policy (finish in order / spread) | Priorities | Priorities (stays) | It is the one place that sets order |
| Deletion-date order (`deadlineOrder`) | Settings → Account safety | **Priorities**, under the policy | It only sorts files within a rank and the unranked groups, so it belongs next to the ranking |
| Save a lower quality first, and keep it (`lowqFirst`, `lowqKeep`) | Settings → Big videos and the NAS | **Priorities** | It decides what comes first when time is short |
| Files of 1 GB or more at once (`bigAtOnce`) | Settings → Big videos and the NAS | **Priorities** | It is a lane order (big files vs the rest), not a NAS setting |
| ★ First / Remove ★ in the Rescan list | Rescan | **Rescan, as a "Rank…" link** that opens Priorities at that group | One ranking, one place to change it; Rescan still shows the rank |
| Pace of rescans (`pace`), quiet hours (`quietStart/End`), pause on freeze (`pauseOnFreeze`) | Settings → Account safety | **Rescan**, in a "How rescans run" card | All three govern reading messages and queueing, not downloading |
| Download pacing (`downloadPacing`), auto-retry (`autoRetry`) | Settings → Account safety | **Settings → Downloads** (new card, which also gets staging and updates) | They govern how files transfer |
| Local staging folder and its space (`stageDir`, `stageCapGb`) | Settings → Big videos and the NAS | **Settings → Downloads**, with the new drive picker | Same reason; the "Big videos and the NAS" card goes away |
| Install updates automatically (new) | — | **Settings → Downloads** | It drains downloads |
| Hold likely copies, keep held, exact re-uploads (`holdLikely`, `holdForever`, `substExact`) | Settings → Account safety | **Copies** (the Duplicates tab, renamed "Copies & duplicates") | All copy rules in one card; the line says it also gates big-video sampling |
| Skip confirmed, compare previews, sharper previews, calibrate | Settings → Copies | **Copies & duplicates** | Same card |
| Download the held files now, fetch the real files of re-uploads | Overview → Copies, duplicates and integrity | **Copies & duplicates** | Next to the rules that hold them |
| Copy counts | Three places | **One block in Copies & duplicates**; Overview keeps a single line with a link | One set of figures, one wording |
| Integrity check (`fixityEnabled`) and its counts | Settings → Account safety, plus Overview | **Overview → Integrity**, with the switch beside its counts | The setting sits with what it reports |
| Finish / reopen groups | Overview table and Rescan → Choose groups | **Rescan → Choose groups** only; the Overview table shows the state and links there | One way to finish; Overview becomes read-only |
| Account frozen, freeze since | Diagnostics | One line: "Telegram reports the account frozen since …", and the `[account]` field explained | One notion of freeze |

After this, **Overview** only reports: index, backup, deadline, downloads, integrity, messages captured. **Settings** keeps the diagnostics report, index copy and backup, Downloads, image recognition, speech to text and alerts. The **Account safety** card goes away: its parts each go where they act.

Each moved control gets a Playwright test in `tests/ui/` that finds it in its new tab, saves it, and checks that the same setting key comes back.

**Your call:** go with this, or change any row (for example, keep Account safety as a card under Rescan instead of splitting it).
