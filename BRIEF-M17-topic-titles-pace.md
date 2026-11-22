# Brief M17: forum mirrors get the source's topic titles, and topic creates get their own short pace

Mirror track, session M-7, 11-22. For one Opus 5.5 coder at high effort. Copy
`C:\Users\trabi\Claude\Projects\Telegram\wt-mirror-topicpace`, branch `wip/mirror-topicpace`, cut from main e34f4f64
(holds M14, M15). **M16 (`wip/mirror-settle`, another coder) changes the settle paths of `internal/mirror/auto.go`
at the same time: keep your changes in `topic.go`, `timing.go`/`pause.go` and new files where you can; touch
`auto.go` only where a topic create is scheduled; never look into `wt-mirror-settle`.** The session joins the two.
Push your branch to `private` as you go (only it). Commits: `git -c user.name=Claude -c user.email=noreply@anthropic.com
commit`, ending with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Rules: `CLAUDE.md` in the project
folder (invented data only; nothing against Telegram; never open `C:\Users\trabi\tgarchive-app`). Tests: named tests,
the whole `internal/mirror` and `internal/collector/faketg` only; never the whole `internal/collector` or
`internal/catalog`; no race detector. Git Bash, `source /c/Users/trabi/Claude/Projects/Telegram/ix-tools/env-archiver.sh`
before every `go`; `GOMAXPROCS=2 GOGC=25 -p=1`. Hand back a branch ready to list (gofmt, vet, tests).

## What happened (11-22 02:00 on, the owner's first forum mirror; catalogue read-only, counts only)
The forum mirror was made at 01:59:12; topic creates at 02:01:44, 02:03:10, 02:05:10, 02:07:10, each answered, no
wait; forwards between them (one write per turn under the account's one pause). So topics come about every 2
minutes: a forum of 35 topics takes over an hour before its last topic exists. The owner: "The normal gap is way
too long for the topics thing. It'll take ages." And: "the topic titles are random, like Topic ##, instead of the
actual topics": the source's `topic` table has 35 rows, 25 with an EMPTY title (for the auto-approved forum: 22 rows,
all untitled, never listed: a fault in Core's reader topic pass, being fixed by Core as K26).

## The owner's decision, through the integrator (11-22): topic creates get their own pace
1. **A stored setting** `mirror.auto.topic_pace` (catalogue-wide): default **3 s plus a random part of 0 to 2 s**
   (the owner's other timers' shape: `timing.go`'s Vary/`spread`, keyed per topic so repeated turns see the same
   time), **no upper bound of the app's own**; doors for pages beside `MirrorSingleWait` (`MirrorTopicPace`,
   `SetMirrorTopicPace`), a run flag `-auto-mirror-topic-pace`, an unreadable value: the default in force and said
   (as M14's single wait does).
2. **Its own clock:** a topic create waits only for the topic pace since the last topic create (and Telegram's
   stated waits); it neither waits for nor resets the forward pause's clock, and a forward does not wait for a
   topic create. So a forum's missing topics are made one after another at the topic pace while forwards go at their
   own pause (in effect "creates first" for the topics without holding the forwards of topics that exist). The turn
   may send one topic create and one forward if both are due: say how you schedule it, and that the account never
   sends two writes in the same second.
3. **On ANY wait Telegram states for a topic create:** slept in full (as now), and the topic pace is doubled (cap:
   `PauseMax`, 10 min) and KEPT doubled for the next hour from that wait (stored, survives a restart), each
   lengthening counted. After the hour it returns to the setting.
4. Counts: topic creates per hour and their waits (the existing per-kind counters); the pace in force on the doors.

## Titles (agreed with Core, K-6: Core's reader stays the one reader of a source's topic list)
5. **Before creating a mirror topic, use the catalogue's title** (`topic.title` of the source topic). If it is empty:
   ask Core's reader to make that forum's topic pass due now (Core's K26 gives a flag and a door `TopicTitle(ctx,
   chat, tgTopicID) (title, known, err)`; names at K26's hand-back: write against a small interface of your own in
   the mirror package and say where Core's door plugs in; until K26 is merged, the catalogue's `topic.title` is
   read directly), and HOLD that topic's create (its messages wait; the other topics go on). **Fallback, so a broken
   topic pass never holds posts for ever:** after `TopicTitleWait` (30 min; a constant, say why) with no title, the
   topic is created with the placeholder ("Topic" and its number, as now) and renamed later when the title is known.
6. **Placeholders renamed:** a mirror topic whose title is a placeholder is renamed (M15's `RenameTopic`,
   messages.editForumTopic) as soon as the source title is known, through M15's rename path (one per turn, never
   while a batch of that mirror is ready? NO: renames of placeholders may go at the topic pace like creates, since
   the owner wants the titles; say what you chose). The two already made on the owner's catalogue with placeholders
   are renamed by this once their titles are known.
7. **The mirror chat's own topic rows:** when the mirror creates (or renames) a topic, write its title into the
   mirror chat's `topic` row (`catalog.EnsureTopic` with the title, or the catalogue's equivalent), so the viewer
   shows it.

## Tests (fake Telegram)
35 topics with titles: all created within about 35 x 3 to 5 s while forwards go at their pause, no two writes in
one second; a stated wait on a topic create: slept, the pace doubled for an hour (and across a restart), then back;
an empty title: held, then created with the title once it is known; never known: placeholder after
`TopicTitleWait`, renamed when the title arrives; the setting's format/read/bad/flag/doors; the mirror chat's topic
rows titled.

## Hand back
Head pushed; files; how creates and forwards are scheduled now (one paragraph, with what 35 topics cost in minutes and
requests); the interface for Core's door; tests by name with lines; anything wrong in this brief.

## Added (the owner, 11-22, through the integrator): forwards as fast as Telegram allows (was M18, folded in)
The owner: "For the topic groups, how do we speed up the mirroring as well? Could be an hour or longer each time if
the messages are spread. Not acceptable." On record (TELEGRAM-FACTS 11): a 20 s pause brought no wait; a 10 s pause
brought a 9 s wait after 200 messages in 13 s. So measure, and back off on the first wait.
8. **Fewest requests:** for a forum, the batch is the oldest candidate's topic's candidates up to the maximum (100),
   read as such: today `MirrorCandidates` reads the chat's first `max` candidates by id and only then cuts to one
   topic (M15's `topicFirst`), so a backlog spread over 35 topics gives small batches. Read the topic's own
   candidates (an indexed query per topic; show the plan) so each request carries up to 100. A backlog then costs
   about the sum over topics of ceil(n/100) forwards. Say what it costs today and after, for 35 topics of a few
   hundred messages. Albums whole; oldest first within a topic.
9. **An adaptive forward pace, a stored setting** (`mirror.auto.forward_pace`, catalogue-wide; doors and a run flag
   as the others): start at **3 s plus 0 to 2 s**; after a run of clean requests (no stated wait; e.g. 10 in a row:
   say the number, a setting too if it is a timer) shorten it a step (e.g. by a quarter) down to a floor of **1 s**;
   on ANY wait Telegram states for a forward: slept in full, the pace doubled (cap `PauseMax`) and held lengthened
   for the hour (stored, survives a restart), each counted. It replaces the account's fixed 20 s pause for the
   automatic task's forwards (the `mirror` command's own `-pause` stays as it is); the existing bound per hour
   (`PerHour`) still holds. No request is ever sent before a stated wait ends.
10. **Mirrors take turns:** the turn goes round the mirrors with ready batches (round robin), so one forum's backlog
   never starves the others; the topic creates' pace (point 1) stays its own clock.
11. Counts per kind and hour (requests, waits, the pace in force) on the doors and in the counters; the hand-back says
   what a 35-topic backlog of a few hundred messages takes in minutes and requests before and after.

## Added again (the owner, 11-22: "Whatever works. Roll it out to everything as a setting. Messages can be deleted
## quickly from any group, or a group could disappear, so faster mirroring is greatly preferred.")
12. **One shared forward pace for EVERY forward path:** the automatic task (plain chats and forums), a chat's
    history into its mirror (the `mirror` command and the page's "Mirror this chat"), adopted chats, the settle's
    re-sends. One stored setting (point 9's), the adaptive rule for all; the `mirror` command's `-pause` stays only
    as an explicit "for this run" override (given: that value, fixed; not given: the shared adaptive pace). Every
    stated wait slept in full.
13. **What is about to be deleted is saved first:** across mirrors, ready batches of NEW posts (posted after the
    mirror began, or in the last 24 hours: say which you chose and why) go before any history backlog, mirrors
    taking turns among the new; history backlogs take turns after. Within one chat, oldest first holds within each
    class; a chat's new posts may go before its own older backlog (counted as out of order, as now).
14. **The per-hour bound** (`PerHour`, 10,000 messages in 60 minutes, the app's own): a stored setting with that
    default (high enough: a normal night is far below it; say the night's peak from the counters you can read in
    tests), no upper bound of the app's own; doors and flag as the others.
