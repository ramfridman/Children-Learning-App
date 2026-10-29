# Today's Adventure: the rule for the bottle (B-26 step 5)

Author: curriculum-expert, 2026-10-29. Status: **RULE, ready to implement** (it follows B-26 decision 3, which the owner approved; the open questions in section 13 can change two parameters, not the shape). Implements: app-developer (a pure function plus an adapter). Tests: qa-engineer (section 10 is the test table). Words for the bubble: hebrew-text-editor (section 8). Nothing here touches the pack, the server, sync or the gateway.

## 0. The rule in ten lines

1. The bottle opens **one stop**: a call for help (a revisit mission), a lesson on a land's path, or a lesson played again. It is an invitation; nothing changes or fades if the child never taps it.
2. **Revisit first, once a day:** if a check is due in an open land and the child has not had a revisit visit today, the bottle opens the revisit that fell due earliest.
3. **Then new learning:** after a revisit visit today, the next 2 visits are lessons; after that, a due revisit again. If nothing new is left, a due revisit always comes before a replay.
4. **New learning continues the land the child played last** (their own choice on the map counts), for up to 3 finished lessons in a row.
5. **After 3 lessons in a row in one land** (or when its path is done), the bottle suggests another land: the lowest level first (Band A before Band B), then the land not played for the longest time, then the map order.
6. **Rest after a stumble:** a lesson the child left today right after an incorrect answer, and a skill already checked today, are not offered by the bottle again today. They stay on the map.
7. **Brand-new child:** Counting Hills, its first lesson (Band B and C children get the land's warm-up first, as today).
8. **Everything finished and nothing due:** play again the lesson played fewest times, in the land not played for the longest time.
9. **Deterministic:** a pure function of plain inputs and an explicit day number; no clock, no randomness; every tie has a fixed order.
10. **Age enters only as parameters** (`paramsFor(band, stage)`); today the band, later the parent-confirmed school stage (B-29). Never a birth date. Which lesson comes next is always the land's own path, by mastery.

## 1. What the bottle is, and what it is not

- **It is** the one obvious next step on the child's home island (B-26 decision 3), reached as pill → home → bottle (2 taps) or from the home in 1.
- **It is not** the three-stop daily plan of PLAN.md › World (revisit, something new, apply-it). That plan needs the session builder in the app and is a later item. This rule is built so the three-stop plan can reuse it: stop 1 = the revisit branch, stop 2 = the new-learning branch.
- **It never decides content on its own.** Which lesson of a land comes next is the land's path (`nextLessonId`, the same function the land's play pebble uses). When B-15 makes the path follow mastery and the band, the bottle inherits that with no change here.
- **It is never timed.** No countdown, no day count, no "come back", nothing lost, broken or wilted while it waits. A day on which the child does not play leaves everything as it was (PLAN.md › World: "Nothing decays or breaks while it waits").

## 2. Inputs (all on the device today)

The rule is a pure function of one input value. An **adapter** (app-developer) fills it from what the app already has; the pure function never touches the database, the clock or a provider.

| Input | Type | Where it comes from today |
|---|---|---|
| `today` | int (day number) | `Engine.dayKey(now)`: the same UTC day the engine already uses for "successes over 2 days" and for one memory review per skill per day. In Israel the day turns at 02:00 or 03:00 local time, inside the parent's rest hours; that is accepted for consistency with the engine. `now` comes from `clockProvider` in the adapter only. |
| `band` | 0, 1, 2 | `Profiles.ageBand`. Used only to choose the parameters (section 7). |
| `stage` | `SchoolStage?` | Always null until B-29 (`gan3` … `grade3`). Used only to choose the parameters. |
| `enabledLands` | set of `TrophyLand` | The lands whose path has at least one lesson in the installed pack (the same test as `hasLesson` in `_openLand`). Never the home island (`TrophyLand` has no `nitzi`). A parent toggle per land would narrow this set later (section 11). |
| `paths` | per land, the lessons in path order, each with its `level` | The land's path exactly as `nextLessonId` and `placement.dart` build it today: every lesson that has a skill of the land's domain, sorted by `sequence`, then by id. `level` = the highest band among the lesson's skills **of that domain**, read from the skill id (`NUM-A-03` → A = 0, B = 1, C = 2; all 100 skill ids in the pack follow `^[A-Z]+-[ABC]-\d+$`, checked 2026-10-29). |
| `finished` | lesson id → count | The same map `_nextLesson` builds (`app.dart`): lessons the warm-up placed (1) and the lesson stickers' counts. One function should build it for both (section 11). |
| `visits` | list, oldest first | The child's attempts grouped into visits (section 2.1). |
| `due` | list | `engine.dueChecks(now)` (checks due now plus skills that need a revisit), keeping only skills whose land is known and whose mission has items (`missionItemIds(engine, id)` not empty). For each: `skillId`, `land`, `dueAt = engine.nextCheckAt(id) ?? now`, `reviewedToday = state.skills[id].lastReviewDay == today`. |

**Per-skill mastery** enters through two of these: `due` (only skills with fresh mastery can be due) and the path (after B-15 the path skips lessons whose skills are mastered or not yet unlocked). The rule itself reads no `p`.

### 2.1 Visits (how the adapter builds them)

| Field | Rule |
|---|---|
| grouping | Attempts of the profile grouped by `sessionId`; answers from another device by `remoteSession`; answers with neither (from before sessions existed) by runs of the same `lessonId`. A visit with no answer does not exist for this rule (the child opened something and left at once; it says nothing). |
| order | By the time of the visit's first answer, then by the smallest attempt id. |
| `kind` | `lessonId == 'placement'` → `warmUp`; starts with `mission-` → `revisit`; a lesson id of the pack → `lesson`; anything else is ignored. (Do not use `Sessions.plan`: the warm-up writes `mission:<skill>` there, the same prefix as a revisit.) |
| `land` | `lesson`: the domain of the lesson's **first** skill (so `butterflies`, which is on both the Numbers and the Colours path, belongs to Counting Hills). `warmUp` and `revisit`: the domain of the first answer's `skillId`. |
| `id` | The lesson id; for a revisit, the skill id of its first answer. |
| `day` | `Engine.dayKey` of the visit's **last** answer. |
| `end` | From the `Sessions` row: `finished`, `home`, `limit`; empty or no row → `open`. |
| `lastIncorrect` | The visit's last answer has `result == 'incorrect'` (`unsure` is never incorrect). |

## 3. Terms the rule uses

- **Open lands**: `enabledLands` that have a non-empty path, in the **map order** `counting, colors, shapes, logic, robots, market` (the order of `TrophyLand`). Every list the rule sorts falls back to this order, so the order in which inputs arrive never matters.
- **Path visits**: visits of kind `lesson` or `warmUp`. Revisits are left out: a call for help does not move the child's journey.
- **Current land**: the land of the most recent path visit, if it is open; otherwise none. When the child picks a land on the map and plays, that land becomes the current land: the child's own choice is how "a land the child likes" enters the rule.
- **Run**: counting back from the most recent path visit, the number of `lesson` visits with `end == finished` in the current land, stopping at the first path visit in another land. Warm-ups and unfinished visits neither count nor stop the run; revisits are not path visits at all.
- **Next lesson of a land**: `nextOnPath(path, finished)`, the logic of today's `nextLessonId` (the first lesson not finished; when all are finished, the one finished fewest times, earliest on the path).
- **New learning in a land**: its next lesson has `finished == 0` and is not resting.
- **Resting lesson**: a lesson whose most recent `lesson` visit has `day == today`, `end == home` and `lastIncorrect`. The child left right after an incorrect answer; the bottle offers something else for the rest of the day (curriculum §10.4: after a child leaves right after an error, the next session starts with an easy due review, not the skill that went wrong; the stuck line "we'll come back to this another time, let's play something else"). A lesson ended by the parent's time limit (`limit`), or left after a correct or unsure answer, is not resting.
- **Reviewed today**: a due skill whose `reviewedToday` is true. The engine counts only the **first** answer of a day as a memory review (`engine.dart`, `lastReviewDay != day`), so a second check on the same day teaches the memory model nothing and can only feel like being asked again. It rests until tomorrow.
- **Recency of a land**: the position of its most recent path visit in the list; a land never visited has recency −1 (the oldest).
- **Visits since the last revisit today**: among today's visits, the number of path visits after the most recent revisit visit of today; "no revisit today" when there is none.

## 4. The rule, step by step

```
todaysAdventure(input, params = paramsFor(band, stage)):
  lands = open lands in map order
  if lands is empty: return none (reason: nothing)

  -- the new-learning candidate
  N = lands with new learning
  if N is empty:                         newPick = none
  else if current in N and run < params.stayInLand:
                                         newPick = current
  else:
    others = N without current
    newPick = others is empty ? current
            : first of others sorted by (level of its next lesson, recency, map order)

  -- the revisit candidate
  R = due skills whose land is open and that were not reviewed today,
      sorted by (dueAt, current land first, map order of the land, skill id)

  -- choose
  revisitAllowed = no revisit visit today
                   or visits since the last revisit today >= params.newAfterRevisit
                   or newPick is none
  if R is not empty and revisitAllowed:  return revisit(R[0])          reason callForHelp
  if newPick is not none:                return lesson(newPick, its next lesson)
                                         reason: welcome if there are no visits at all,
                                                 sameLand if newPick == current, else otherLand

  -- nothing new and nothing due: play again
  candidates = (land, lesson) in open lands with finished >= 1 and not resting
  if any: land = smallest (recency, map order);
          lesson = in that land, fewest finished, then earliest on the path
          return replay(land, lesson)                                  reason playAgain

  -- only resting lessons are left (one land, nothing finished yet)
  land = current if open, else the first open land
  return lesson(land, its next lesson)                                 reason sameLand
```

Notes on the choices:
- **Revisit before new, once a day.** PLAN.md › World orders the daily bottle "a revisit, something new, a playful apply-it", and §10.3 opens every session with an easy retrieval. A due check of a skill with fresh mastery is scheduled at about 90% expected recall (`targetRetention` 0.9), so it is usually a quick success: a good first thing of the day.
- **Earliest due first** is the engine's own order (`dueChecks`), the same order as the bells on the map, and it cannot starve a skill: every waiting skill becomes the earliest in time.
- **Two lessons between revisits** within a day mirrors the three-stop pattern (one revisit per two other stops). Missions are 3 to 5 items and lessons average 4.3 activities (Band A) and 5.2 (Band B) in the pack, so when revisits are due all day, revisit items are about 28% (Band B) to 32% (Band A) of the bottle's items. That is a little above PLAN.md's session shares (Band B 20 to 25%, Band A 15 to 20%; 3 lessons between revisits would give about 20% and 24%, 4 would give about 16% and 19%). I keep 2 because it is the PLAN's own three-stop pattern and the bells on the map are the only other way to a check today; the rows may move to 3 or 4 once real play shows how many visits a day the children make (section 7). On short days (one or two visits), the first-of-the-day revisit makes the share higher still; that is the PLAN's own daily order and is accepted.
- **Stay in a land for 3 lessons.** Curriculum §10.3 keeps Band A "mostly blocked by domain", and continuity is what a young child understands ("let's keep going on the hills"). The cap of 3 is the "respect the favourite, weave in the others" rule of §10.4, and it stops a child who only ever taps the bottle from playing one land forever.
- **Lowest level first when moving on** puts Band A of every land before Band B of any land, the order the owner chose for the family release (Q4), and widens the base the later skills stand on. It is only an order among candidates: it never blocks a land, and the child's own map choice always wins.
- **Least recently played next** spreads practice across lands over days, which is spacing at the level of the domain.

## 5. Special cases

| Case | What happens | Why |
|---|---|---|
| **Brand-new child** (no answers at all) | `lesson(counting, first lesson of the Numbers path)`, reason `welcome`. The app calls `_playLand('numbers')`, which runs the warm-up first when it is due (Band B and C, warm-up on), exactly as the map does today. | Counting Hills is the land the map has always opened first, the core domain and the one with the most content. It falls out of the general rule: every land has level A and recency −1, and Counting Hills is first in map order. |
| Brand-new child, Counting Hills not enabled (only possible after a future parent toggle) | The first open land in map order. | Same general rule. |
| **Only one land open** | No rotation (there is no other land); revisits and the rest rule work as usual; when its path is done, replays in that land. | Section 4, `others` is empty. |
| **Everything finished, nothing due** (today: a Band B or C child at the end of the pack) | `replay` of the lesson played fewest times, in the land not played for the longest time, reason `playAgain`. | Retrieval of known material across lands, never an empty or "come back" bottle. This is also the signal that the child needs Band C content (B-29 step 7); it is never shown to the child. |
| **Everything mastered but a check is due** | The revisit. | A due check is what turns fresh mastery into a golden star. |
| **A resting lesson and nothing else** (one land, first lesson, the child left after an incorrect answer) | That lesson again, from the start, reason `sameLand`. | An empty bottle would be worse than a fresh start; nothing is withheld. |
| A due skill in a land that is not open | Ignored by the bottle (its bell still shows on that land if the land is on the map). | The bottle offers only open lands. |
| No pack or no lesson anywhere | `none`, reason `nothing`. The design-director decides how a calm bottle looks when it is not a button (B-26: no button that does nothing). | |
| Answers synced from another device | Counted like local ones (visits from `remoteSession`). | The child is one child on all devices. |
| The parent's time is up | Not the rule's business: `_openLesson` already shows the rest scene for any stop. | |

## 6. Determinism (the contract the tests rely on)

- `todaysAdventure(input, params)` reads nothing but its arguments: no `DateTime.now`, no `Random`, no provider, no database. The adapter is the only place that reads the clock (`now`, once) and turns it into `today` and the due list.
- Every sort has a total order that ends on a unique key (map order, lesson path position, skill id), so maps and sets in any iteration order give the same answer.
- The same input always gives the same output. Tapping the bottle twice without playing gives the same stop; after a visit the inputs change, and so may the stop.
- **When to compute:** when the home screen is built (if the design shows anything of the stop on the bottle) and again on the tap; the tap's result is used. If they differ (a check fell due while the child sat on the home screen), nothing is said about it.
- No randomness is needed. If a later version wants variety (for example which replay), it takes an explicit seed in the input (for example `today` mixed with the profile id), never an unseeded generator.

## 7. Parameters and the age or stage hook

```
class AdventureParams { int newAfterRevisit; int stayInLand; }
AdventureParams paramsFor({required int band, SchoolStage? stage})
```

| Selector | `newAfterRevisit` | `stayInLand` |
|---|---|---|
| Band A (0) | 2 | 3 |
| Band B (1) | 2 | 3 |
| Band C (2) | 2 | 3 |

- Today all three bands share the values: there is no evidence for a finer split yet, and Band C has no content. They live in one table so that tuning is a data change.
- **B-29 plugs in here and only here.** When the parent-confirmed school stage exists, `paramsFor` uses it (gan3 and gan4 → the Band A row, gan5 and grade1 → B, grade2 and grade3 → C, the same mapping as the bands in `docs/research/age-fit-teaching.md` §3); a profile without a stage keeps using its band. Likely later tuning, per age-fit-teaching §5.1 (revisit share about 15% at 3 rising to 30% by 7; blocked by land under 5, interleaved from 5): the youngest rows `newAfterRevisit` 3 and `stayInLand` 3, the oldest `newAfterRevisit` 1 and `stayInLand` 2. To be decided with the children's real play, not now.
- **What never enters this rule:** a birth date, a birth month or year, an age in months, or the presentation stage P1 to P4 (those are about how a screen looks, B-29 decision 3). A stage change applies at the next computation, which is always before a visit starts (B-29: changes apply at the next session start); it never changes `finished`, `visits` or `due`, so it can never take anything away.
- **The age-based starting lesson of an unplayed land** (B-29 step 6) belongs to the path (`placement.dart`, `next_lesson.dart`), not here. The bottle gets it through `paths`, `finished` and `nextOnPath`.

## 8. Output, what the app does, and the words

```
class TodaysAdventure {
  AdventureKind kind;      // revisit | lesson | replay | none
  TrophyLand? land;
  String? lessonId;        // lesson and replay: the lesson the path offers (before any warm-up)
  String? skillId;         // revisit
  AdventureReason reason;  // welcome | callForHelp | sameLand | otherLand | playAgain | nothing
}
```

| Kind | The app does | Comes back to |
|---|---|---|
| `revisit` | `_openLesson(mission: world.missionFor(skillId))` (the bell's own mission, 3 to 5 items in a fresh way of asking) | the home island |
| `lesson` | `_playLand(land.domain)`: the warm-up first when it is due, then the land's next lesson (the same as `lessonId` when no warm-up ran; after a warm-up the path is worked out again, as today) | the home island |
| `replay` | `_openLesson(lessonId: lessonId)` (no warm-up: the land has been played) | the home island |
| `none` | no invitation; the island stays calm | |

**Intents for the hebrew-text-editor** (the bubble and the screen-reader label of the bottle; the editor words them, all new Hebrew marked `needs-editor`; no Hebrew is proposed here):

| Reason | Intent |
|---|---|
| `welcome` | An invitation to the first adventure, on Counting Hills. |
| `callForHelp` | Something in that land needs a hand (the map's framing: "a bridge board is missing!"). About the land's object, never about the child. |
| `sameLand` | Let's keep going on that land. |
| `otherLand` | Let's visit that land. |
| `playAgain` | Let's play a game you know again. |
| `nothing` | No line, or the companion's ordinary greeting. |

Wording rules (CLAUDE.md › Child safety): an invitation, never an obligation; no time words (today's only, last chance, hurry, still waiting since), no count of days or visits, no "come back" line, nothing that says the child forgot, stayed away, fell behind or lost something; no comparison with a sibling; a call for help is about the island, not a test. Today's bubble "{child}, הַבַּקְבּוּק הִגִּיעַ!" becomes true once the bottle exists on the home island; the editor rewords it if the stop changes what it should say.

## 9. Why (evidence)

- **Spaced retrieval beats massed re-study**, and a second same-day review adds little: distributed practice meta-analysis (Cepeda, Pashler, Vul, Wixted and Rohrer 2006, *Psychological Bulletin* 132(3), 354-380); the optimal gap grows with the retention interval (Cepeda, Vul, Rohrer, Wixted and Pashler 2008, *Psychological Science* 19(11), 1095-1102); testing strengthens memory more than restudy (Roediger and Karpicke 2006, *Psychological Science* 17(3), 249-255). The engine's FSRS-style schedule (PLAN.md › Mastery with memory) already encodes this; the bottle only follows its due dates and its one-review-a-day rule.
- **Interleaving across kinds of problems** helped fourth-graders on a test a day later (Taylor and Rohrer 2010, *Applied Cognitive Psychology* 24(6), 837-848), but the evidence for ages 3 to 6 is thin and mixed (I found no large kindergarten or grade 1 trial; a search on 2026-10-29 found only small or older-pupil studies). Hence a cautious mix: blocks of up to 3 lessons in one land, other lands woven in between, as curriculum §10.3 does (Band A mostly blocked).
- **High success keeps children practising** (Jansen et al. 2013, *Learning and Individual Differences* 24; abstract read for the age-fit report): the day opens with a check at about 90% expected recall, and a child who just stumbled is offered something else.
- **Choice supports motivation** (Patall, Cooper and Robinson 2008, meta-analysis, *Psychological Bulletin* 134(2), 270-300): the child's own land choice on the map always sets the current land; the bottle is a suggestion, never a gate.
- **Contingent tangible rewards can undermine interest** (Deci, Koestner and Ryan 1999, meta-analysis, *Psychological Bulletin* 125(6), 627-668): no streaks, no day counts and nothing that fades, as CLAUDE.md requires.
- Where the evidence is thin, the numbers (2 and 3) are starting values from PLAN.md's own three-stop plan and §10.3 shares, to be tuned with the children (curriculum §14).

## 10. Worked examples (turn each row into a test)

**Fixture paths** (path order = `sequence`; level in brackets; one skill per lesson, named so its band shows):

| Land | Path |
|---|---|
| counting | `n1` NUM-A-01 (A), `n2` NUM-A-02 (A), `n3` NUM-A-03 (A), `n4` NUM-B-01 (B) |
| colors | `c1` COL-A-01 (A), `c2` COL-A-02 (A), `c3` COL-B-01 (B) |
| shapes | `s1` SHP-A-01 (A), `s2` SHP-B-01 (B) |
| logic | `g1` LOG-A-01 (A) |
| robots | `r1` CS-A-01 (A) |
| market | `m1` MATH-A-01 (A), `m2` MATH-B-01 (B) |

**Notation.** `today = D` (any day number, for example 20400). Parameters: `newAfterRevisit = 2`, `stayInLand = 3`. Unless a row says otherwise: band A, stage null, all six lands enabled, `finished` empty, no visits, nothing due. A visit is written `L:n1 D-1 fin`, `L:n2 D home incorrect`, `W:counting D-1 home` (warm-up), `R:SHP-A-01 D fin` (revisit); the last answer is correct unless the row says `incorrect`. Visits are listed oldest first. A due skill is written `NUM-A-01@(D-1 09:00)`, plus `reviewedToday` when that is true. "fin n1,n2" means `finished = {n1: 1, n2: 1}`.

Every row was run through a small reference model of section 4 before it was written down (a scratch script, not part of the repo).

| # | What it shows | Input (differences from the defaults) | Expected output |
|---|---|---|---|
| 1 | Brand-new child | nothing | `lesson`, counting, `n1`, `welcome` |
| 2 | Brand-new child, Band B (the warm-up is the app's step, not the rule's) | band B | `lesson`, counting, `n1`, `welcome` (the app's `_playLand('numbers')` then runs the warm-up first) |
| 3 | Only enabled lands; map order, not input order | enabledLands `{shapes, colors}` | `lesson`, colors, `c1`, `welcome` |
| 4 | Continue the land played last | fin n1; visits `L:n1 D-1 fin` | `lesson`, counting, `n2`, `sameLand` |
| 5 | After 3 lessons in a row, another land; level A first, never-visited lands are the oldest, then map order | fin n1,n2,n3; visits `L:n1 D-2 fin`, `L:n2 D-1 fin`, `L:n3 D-1 fin` | `lesson`, colors, `c1`, `otherLand` (counting's next is `n4`, but the run is 3) |
| 6 | Another land breaks the run; a revisit neither counts nor breaks it | fin n1,c1,n2,n3; visits `L:n1 D-3 fin`, `L:c1 D-2 fin`, `L:n2 D-1 fin`, `R:COL-A-01 D-1 fin`, `L:n3 D-1 fin` | `lesson`, counting, `n4`, `sameLand` (run = 2) |
| 7 | The current land's path is done; the land not played for the longest time wins over a land played before | fin n1,n2,c1,n3,n4; visits `L:n1 D-5 fin`, `L:n2 D-4 fin`, `L:c1 D-3 fin`, `L:n3 D-2 fin`, `L:n4 D-1 fin` | `lesson`, shapes, `s1`, `otherLand` (colors was visited; shapes never) |
| 8 | Revisit first on a new day | fin n1,n2; visits `L:n1 D-2 fin`, `L:n2 D-1 fin`; due `NUM-A-01@(D-1 08:00)` | `revisit`, counting, `NUM-A-01`, `callForHelp` |
| 9 | The revisit that fell due earliest | fin n1,n2,c1,s1; visits `L:s1 D-9 fin`, `L:c1 D-8 fin`, `L:n1 D-2 fin`, `L:n2 D-1 fin`; due `COL-A-01@(D-1 07:00)`, `NUM-A-01@(D-1 09:00)`, `SHP-A-01@(D-2 18:00)` | `revisit`, shapes, `SHP-A-01`, `callForHelp` |
| 10 | After a revisit today, new learning next | fin n1,n2,s1; visits `L:s1 D-9 fin`, `L:n1 D-2 fin`, `L:n2 D-1 fin`, `R:SHP-A-01 D fin`; due `NUM-A-01@(D-1 09:00)` | `lesson`, counting, `n3`, `sameLand` (0 visits since the revisit) |
| 11 | Still new learning after one lesson; the run cap applies across the revisit | as 10, plus fin n3 and visit `L:n3 D fin` | `lesson`, colors, `c1`, `otherLand` (1 visit since the revisit; counting's run = 3) |
| 12 | After two lessons since the revisit, the next revisit | as 11, plus fin c1 and visit `L:c1 D fin` | `revisit`, counting, `NUM-A-01`, `callForHelp` |
| 13 | A skill already checked today rests | fin n1,n2; visits `L:n1 D-2 fin`, `L:n2 D-1 fin`, `R:NUM-A-01 D home incorrect`; due `NUM-A-01@(D-1 09:00) reviewedToday` | `lesson`, counting, `n3`, `sameLand` |
| 14 | A lesson left today right after an incorrect answer rests; something else is offered | fin n1; visits `L:n1 D-1 fin`, `L:n2 D home incorrect` | `lesson`, colors, `c1`, `otherLand` |
| 15 | Left after a correct answer: not resting | fin n1; visits `L:n1 D-1 fin`, `L:n2 D home` | `lesson`, counting, `n2`, `sameLand` |
| 16 | Left after an incorrect answer yesterday: rest is over | fin n1; visits `L:n1 D-1 fin`, `L:n2 D-1 home incorrect` | `lesson`, counting, `n2`, `sameLand` |
| 17 | Only one land open: no rotation even after 3 in a row | enabledLands `{counting}`; fin n1,n2,n3; visits `L:n1 D-3 fin`, `L:n2 D-2 fin`, `L:n3 D-1 fin` | `lesson`, counting, `n4`, `sameLand` |
| 18 | Everything finished, nothing due: replay in the land not played for the longest time, the lesson played fewest times | fin every lesson 1, except `m1: 2`, `r1: 3`; visits `L:m2 D-20 fin`, `L:r1 D-12 fin`, `L:g1 D-6 fin`, `L:s2 D-5 fin`, `L:c3 D-3 fin`, `L:n4 D-1 fin` | `replay`, market, `m2`, `playAgain` |
| 19 | Everything finished, a check due | fin as 18; visits `L:n4 D-1 fin`; due `SHP-A-01@(D-1 12:00)` | `revisit`, shapes, `SHP-A-01`, `callForHelp` |
| 20 | One land, its only unfinished lesson resting, nothing finished: offered again | enabledLands `{counting}`; visits `L:n1 D home incorrect` | `lesson`, counting, `n1`, `sameLand` |
| 21 | A due skill in a land that is not open is ignored | enabledLands `{counting, colors}`; fin n1; visits `L:n1 D-1 fin`; due `SHP-A-01@(D-1 12:00)` | `lesson`, counting, `n2`, `sameLand` |
| 22 | Equal due times: the current land first | fin n1,c1; visits `L:n1 D-3 fin`, `L:c1 D-1 fin`; due `NUM-A-01@(D-1 12:00)`, `COL-A-01@(D-1 12:00)` | `revisit`, colors, `COL-A-01`, `callForHelp` |
| 23 | A warm-up makes its land current, and does not count in the run | fin n1; visits `W:counting D-1 home`, `L:n1 D-1 fin` | `lesson`, counting, `n2`, `sameLand` |
| 24 | Ended by the parent's time limit: not resting, and not counted in the run | fin n1,n2; visits `L:n1 D-2 fin`, `L:n2 D-1 fin`, `L:n3 D limit incorrect` | `lesson`, counting, `n3`, `sameLand` |
| 25 | Level before recency when moving on | enabledLands `{counting, colors, shapes}`; fin n1,n2,n3,c1,s1,s2; visits `L:n1 D-10 fin`, `L:n2 D-9 fin`, `L:n3 D-8 fin`, `L:c1 D-3 fin`, `L:s1 D-2 fin`, `L:s2 D-1 fin` | `lesson`, colors, `c2`, `otherLand` (counting was played longer ago, but its next lesson `n4` is level B) |
| 26 | Nothing new left: a due revisit comes even right after another revisit | fin as 18; visits `L:n4 D-1 fin`, `R:SHP-A-01 D fin`; due `NUM-A-01@(D-1 12:00)` | `revisit`, counting, `NUM-A-01`, `callForHelp` |
| 27 | Nothing to play | `paths` with no lesson in any open land | `none`, `nothing` |
| 28 | The stage hook changes nothing today | row 4 with stage `gan4` (once the type exists) | the same as row 4 |

## 11. Properties for the qa-engineer (beyond the table)

1. **Pure:** a source test that `todays_adventure.dart` uses no `DateTime.now`, no `Random` and no Flutter or database import (as the engine's own purity test does).
2. **Order-independent:** for every row, shuffling `enabledLands`, the `due` list and the `finished` map gives the same output.
3. **Never outside the open lands:** over random inputs (seeded), `land` is always in `enabledLands`, and a `lessonId` is always on that land's path.
4. **Never a skill reviewed today, never a resting lesson** unless the row-20 fallback is the only choice.
5. **Never `none` while any open land has a lesson.**
6. **Same as the land's own pebble:** for `lesson`, `lessonId` equals what `_nextLesson(land.domain)` returns with the same history (one shared function makes this true by construction).
7. **Adapter tests:** visits built from attempts (a session with no answers gives no visit; a warm-up whose session plan says `mission:` is still a `warmUp`; `butterflies` belongs to counting; remote answers are grouped by `remoteSession`); `today` and `dueAt` from a fake clock.
8. **Wording guard (with the editor):** the strings used by the bottle contain no time or day-count words (the list the editor keeps for B-26).

## 12. Data the app does not have, and defects found

| Need | Status | Who |
|---|---|---|
| A parent switch per land ("enabled lands") | Does not exist. The rule takes the set as an input; today it is the lands with a lesson. Not needed for B-26. | owner (want one?), then app-developer |
| Whether a visit started from the map, a bell or the bottle | Not recorded (`Sessions.plan` does not say). Not needed: the last land played approximates the child's choice. Needed only if the owner wants a real "favourite land" signal later; it would be a local field, and a sync field would need the security-engineer. | owner, later |
| An explicit band on each skill | Read from the skill id today (all 100 ids follow the pattern). Ask: the pack validator should refuse a skill id that does not, so `level` can never be wrong. | qa-engineer, app-developer |
| One shared path function | `next_lesson.dart` and `placement.dart` each build the path; `_nextLesson` builds `finished`. The bottle, the land pebble and the warm-up should call one `landPath` and one `finishedLessons`. | app-developer |
| The school stage | B-29. The hook is `paramsFor`. | B-29 |

**Defect found while reading (for the app-developer, B-15 scope, a failing test first):** `placementDue` (`app/lib/world/placement.dart`, line 60) returns false for **every** land as soon as the child has played the warm-up of **any** land, because it checks `a.lessonId == placementId` without the land. Curriculum §10.1 and the function's own comment ("the warm-up game at the first visit to a land") say placement is per land. So a Band B child who did the Counting Hills warm-up gets no warm-up in Colour Bay or anywhere else. Fix: count only warm-up answers whose activity is on this land's path (the `inLand` test already does that).

## 13. Open questions for the owner (each with my recommendation)

1. **Revisit first, once a day, then two lessons between revisits?** Recommended: yes (PLAN.md's three-stop order). Alternative: new learning first and revisits only from the bells on the map; golden stars would then come much more slowly.
2. **Stay up to 3 lessons in one land, then suggest another land?** Recommended: yes; the child's own land choice on the map always comes first. Alternative: always continue the land played last (a child who only taps the bottle would play Counting Hills, 49 lessons, before any other land).
3. **When moving on, Band A of the other lands before Band B anywhere?** Recommended: yes (your Q4 order). Alternative: the land not played for the longest time, whatever its level.
4. **When everything is done, replay a known lesson?** Recommended: yes, never an empty bottle. Alternative: a calm bottle with nothing in it.
5. **A parent switch to hide a land?** Recommended: not now; the rule is ready for it.
6. **Rest a lesson for the day after the child leaves it right after an incorrect answer?** Recommended: yes (curriculum §10.4); it stays on the map.
