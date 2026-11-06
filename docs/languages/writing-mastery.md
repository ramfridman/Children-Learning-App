# Writing mastery (rule E-1): the spec for LS02 2.0

**Status:** the rule was decided by the owner on 2026-11-06 (L5 Q1 and Q2, approved with every recommendation). This file is step **L5-2a**: the rule written so that the app-developer can build it in L5-2b without guessing, and the qa-engineer can test it. Written by the curriculum-expert, 2026-11-06, in `D:\nitznutz-l5` (branch `languages-l5`). Nothing here is built yet.

**Read with:** `docs/milestones/L5.md` §5.2 (LS02 2.0) and §6 (E-1), `docs/languages/frame.md` §3.3 (mastery, roll-ups, bundles, set coverage, speech), `docs/languages/strokes.md` (F6), `docs/milestones/L3.md` D-8 and §10 (how speech evidence was capped), and the engine: `app/lib/engine/engine.dart`, `state.dart`, `types.dart`, `mastery.dart`, `params.dart`, `rollup.dart`, `gates.dart`, `app/lib/content/engine_adapter.dart`.

---

## 0. The rule in one page

The owner's words (2026-11-06): **tracing is practice; copying counts like a hinted answer; writing from memory counts in full; mastery needs memory successes on two days, one cued by the letter's sound and one by its name; a trace-only skill counts as met once practised.** Stroke order is not scored (Q2).

In engine terms:

1. **Two kinds of writing node.** Every letter group has a **trace node** (`writing: practised`, in the letter's bundle) and a **writing node** (`writing: memory`, the next skill of the same group). Section 2 lists them per course.
2. **Each LS02 answer is put in one of three evidence classes before anything else happens**, the way L3 decides first whether a spoken answer counts (`_speechCounts`):
   - **practice** (every trace answer, and every answer in a trace node): no estimate, no success, no review, no misconception, no gap search. It only records which letters were practised;
   - **hinted** (a copy answer): read as if its hint level were one higher than the one shown (copy alone = level 1, credit 0.8). Never a success, never the day's review;
   - **full** (a memory answer): read as every other answer is today.
3. **Fresh mastery of a writing node** needs everything the engine asks of any skill (P(L) ≥ 0.95, 4 successes or 6 for a core skill, 2 days, 1 check or 2, set coverage) **except the representation count**, which is replaced by the **cue condition**: memory successes on at least two days, and among them at least one cued by the **sound** and one by the **name**. Those two cues are the writing node's two representations (§5.3).
4. **A trace node is met once practised:** every letter (every form) of the group traced once with the start dot only (hint level 0 or 1). It then has the status `practised`, counts as met for anything that needs it, and never blocks. It is never mastered, never probed, never checked and never revisited.
5. **Hints and probes:** after any miss in copy or memory the start dot comes back, which is hint level 1; a miss the check cannot name writes nothing; a probe of a writing node is a memory item and needs two named misses to fail (§7).
6. **Test vectors** for every condition are in §9.

---

## 1. Terms

| Term | Meaning |
|---|---|
| **LS02 item** | An activity of template `trace`, `templateVersion` `2.0`, in a language course. Its `mode` is `intro`, `trace`, `copy` or `memory`; its `canvas` is `letter` or `word`. T04 `trace` 1.0 in the maths lands is not touched by this file. |
| **Form** | One stroke-set form id (`latin.s`, `cyrillic.a.cap`, `cyrillic.a`, `hebrew-print.mem-final`). A capital and a small letter are two forms; a Hebrew final is its own form. |
| **Letter** (in the rules below) | One form. The variant group of a letter-canvas LS02 item is its form id. |
| **Trace node** | A skill with `"writing": "practised"`: heb `B-24.Sn`, rus `B-24.Gn`, eng `B-23.Gn` (new, §2), and the pre-writing and own-name skills heb `A-14` and `B-27` (§2.2). |
| **Writing node** | A skill with `"writing": "memory"`: heb `B-26.Sn`, rus `B-26.Gn`, eng `B-19.Gn` and `C-15.Gn`; in Band C heb `C-27` (§2). |
| **Memory success** | A memory-mode answer, correct, at hint level 0, outside a probe. |
| **Cue** | What the voice says in a memory item: `sound` (the letter's sound, or the key word where §3.4 asks for it) or `name` (the letter's name). Replaying the cue is not a hint. |
| **Practised** | Every letter of a trace node done once in a way that counts (§6.1). |
| **Met** | What a prerequisite must be for the skill after it to unlock: p ≥ 0.8 today; for a trace node, practised (§6.2). |

---

## 2. One structure for the three courses (L5 §14 item 1)

**The structure, per letter group:**

```
the letter's knowledge facet(s)  ─┐
   (sound, name, shape; LS01)     ├─ one bundle (frame §3.3.3): opens together, counts as one new skill
the trace node  (LS02 trace)     ─┘
        │  met once practised
        ▼
the writing node (LS02 copy, then memory)
   prerequisites: the group's trace node AND the group's knowledge facet(s), because a memory cue asks for the sound or the name
   mastered by E-1
```

Rules of the structure:

- A trace node holds only LS02 `intro` and `trace` items (and, for heb B-27, the own-name items). A writing node holds LS02 `copy` and `memory` items, and no `trace` items: the trace of the same letters lives in the trace node, and level 3 of the writing node's ladder shows trace mode as a hint, not as an item of the trace node.
- A trace node has no prerequisite of its own inside a bundle (the bundle opens on its members' prerequisites, as today), except heb `B-24.Sn` on `A-14`, which needs only to be practised, never mastered, so how well a child traces never holds the bundle back.
- A writing node is never in a bundle.
- A writing node may need the writing node of an earlier group only when its forms build on the earlier group's strokes (eng `B-19.G1` → `B-19.G2`: d g o c build on the c-shape of a). That edge never touches a bundle.
- **Why this shape:** today two courses let a writing facet hold back the letters themselves. In English, the group 2 bundle (`B-17` with `B-19.G2`) needs `B-19.G1`, so a child cannot meet the letters m d g o c k until it writes s a t p i n well. In Hebrew, the S1 bundle needs `A-14`, so a child who cannot yet trace an arch cannot learn the names of א בּ מ. Fine-motor control matures at its own pace, and letter knowledge must not wait for it. The split puts the slow, motor part (memory writing) after the bundle, where it holds back only more writing.

### 2.1 What changes per course (the teachers' edits are listed id by id in §11)

| Course | Today | After |
|---|---|---|
| **rus** | `B-24.Gn` trace (bundle), `B-26.Gn` copy and memory | **Kept.** `B-24.Gn` is met once practised (not "mastered only through B-26"); `B-26.Gn` also needs the group's letter skill; memory items name the case. |
| **heb** | `B-24.Sn` trace (bundle), `B-25.Sn` copy, `B-26.Sn` memory | `B-25.Sn` is **merged into** `B-26.Sn` (a copy-only skill could never be mastered under E-1, since copy is never a success). `B-26.Sn` holds copy and memory and needs `B-24.Sn`, `B-14.Sn` (names) and `B-15.Sn` (sounds). Band C: `C-26` becomes the script trace node, its copy moves to `C-27`. |
| **eng** | `B-19.Gn` and `C-15.Gn` hold trace, copy and memory, and sit in the bundles | **New trace node `ENG-B-23`** (roll-up of `B-23.G1` to `.G4`; G3 and G4 are Band C groups of a Band B roll-up, as rus `B-24.G5` to `.G10`) goes into the bundles; `B-19.Gn` and `C-15.Gn` become writing nodes after it. |

### 2.2 Two more skills that the owner's rule reaches

- **heb A-14** (pre-writing strokes) is a trace-only skill, so by the owner's rule it is met once practised (each of down, right to left, arch and circle traced once with the start dot only). This also removes the motor gate on the S1 bundle described above. Its tag `M-HEB-STROKE` is no longer evidenced in A-14 (tracing is practice); it is diagnosed in `B-26.Sn`, where the child draws without a path.
- **heb B-27** (own name) cannot meet E-1: a name has no sound or name cue, and its items are never a probe or a check and write `built` or nothing (L5 §5.6, §11 item 2). A skill fed only by "built" can only go up, so calling it mastered would claim more than the evidence shows. **Proposed:** `B-27` is a `practised` node, met once the name has been built with its tiles and written once letter by letter. Nothing depends on B-27, so this changes only what the parent sees ("practised"). This one goes beyond the literal rule and is listed for the owner (report).

### 2.3 Skill document fields (pack)

| Field | Values | Meaning |
|---|---|---|
| `writing` | `"memory"`, `"practised"`, or absent | absent: an ordinary skill. A word-canvas spelling skill (eng C-16, rus C-22) has no `writing` field: its LS02 answers get the mode classes of §4, and its representations count as usual (tiles are `concrete`, the canvas `embodied`). |

`masteryRequires.representations` is refused on a `writing: memory` node (the cue condition replaces it). `masteryRequires.days` may raise the memory-day count (§5.1).

---

## 3. What each LS02 mode writes

One answer is one `attempt` row, as for every template. The row is the truth: it records the hint level that was **shown**, never a level worked out from the mode. The engine reads the mode from the item (§4), never from the row.

| Mode | When a row is written | `result` | `hintLevel` in the row | `misconceptionTag` | `response` |
|---|---|---|---|---|---|
| `intro` | never (unscored, like an LS08 story with no question) | | | | |
| `trace` | at the end of the letter, right or not, as T04 does today | `correct` or `incorrect` | the level shown | the path check's tag if any (kept in the row; the engine ignores it, §4) | `trace`, `trace.back`, `trace.off` (today's codes) |
| `copy` | at the end of the letter when it is right; at the end of the stroke when a **named** miss happens | `correct` or `incorrect` | the level shown (0 when only the model was there) | the classifier's tag on a named miss | `ok`, or the stroke number and the classifier (`s2.dir`, `mirror`, `partner`, `lines`) |
| `memory` | as copy | as copy | as copy | as copy | as copy |
| word canvas (`canvas: word`) | at the end of the word when every box is right; at the end of the stroke on a named miss in any box | as copy | as copy | as copy | `ok`, or the box, the stroke and the classifier (`b2.s1.start`) |
| own name (`source: own_name`, heb B-27) | only when the name is written: `built` | `correct` | the level shown | none | `built`; nothing else ever (no letter, no box code) |

### 3.1 A miss the check cannot name

The free-stroke check (L5 §5.2) names a miss only when it is a start, direction, lines, mirror or partner error. **Any other miss writes no row** ("a retry with no tag and no evidence", L5 §5). The stroke fades, the start dot comes back (that is hint level 1 for the rest of the item, §7.1), and the child tries again. So a miss that cannot be named is not evidence against the child, but the success that follows it is not a full success either: it was helped.

### 3.2 The end of the letter, not the stroke

A letter of three strokes is one answer. A named miss on stroke 2 writes one `incorrect` row; the child goes on from there with the start dot (level 1); the right letter at the end writes one `correct` row at level 1 or more. So a letter writes one row for each named miss and one row at the end when it is right, never one row per stroke.

### 3.3 Order of strokes (Q2)

A stroke matched out of order still counts. No row, tag or response ever records order. After a success the model replays once in its order; that replay is not a hint (it comes after the answer).

### 3.4 Cues that would have two right answers

A memory cue must have exactly one right letter among the letters the child has met so far in that course.

- **Shared sounds.** heb ת/ט, כּ/ק, ח/כ, ו/ב, ס/שׂ (as the groups bring them); eng c/k (/k/, group 2). A sound cue for such a letter gives the **key word of its introduction** with its picture ("the sound at the start of תַּפּוּחַ"), and the item lists the other letter as a `partner`.
  - If the child writes the partner, no row is written. The session knows the case from the partner's tag: a partner tagged with the course's homophone tag (family CODE, "on the way") writes nothing. A look-alike partner (family SHAPE, such as ב/כ or b/d) is a named miss and writes its row. The child hears that the partner says that sound too, and then sees the target letter beside the box (hint level 1 for the next try).
  - Reason: the child wrote a real letter for that sound, so this is never "wrong". But it is not the letter asked for, so it is not a success either (frame §3.3.5, the same kindness as sound-right).
  - The course's homophone tag (`M-HEB-HOMOPHONE`, `M-ENG-C-K`) stays "on the way" here. It is never misconception evidence in a writing node.
- **No sound of its own.** heb א (and ע, ה at the end, later): **name cue only**. The cue condition is met across the group (§5.2), so such letters need no sound cue.
  - *Answer to the hebrew-language-teacher's proposal in `hebrew/band-b-pilot.md` §5.6* (a key-word cue for א, "the letter at the start of אַרְנָב"): **not needed**, because the cue condition is per node. It may stay as an extra item, written `cue: sound` with the key-word clip, only while no other letter met can open that word's sound. From S5 on, ע does, so it must then be listed as the partner (above).
- **A name that is the sound.** rus А У О (and Ы, И, Э, later Ё Ю): the name and the sound are one clip, so the letter has **one** memory cue, written `sound`. A `name` item for it would repeat that clip, and the validator refuses it. The cue condition is still met across the group, through a letter whose name differs from its sound. Every Russian group has one (М in group 1, С Н in 2, Л Р in 3, all of К Т В in 4, and so on). English vowel names and all Hebrew names differ from the sounds.
  - *Answer to the russian-language-teacher's proposal in `russian/band-b-pilot.md`* (the capital and the small form as the two representations of a name = sound letter): **not taken.** Both forms answer the same cue by the same route (sound to letter), so they are two letters for coverage (F6), not two ways of knowing. The node-level rule needs no exception.
- **Finals and case.** A final form or a capital needs the cue to say which form is meant. heb: the name cue is the final's name (מֵם סוֹפִית), and the sound cue says "at the end of a word". rus (and eng from C-13): the frame line says "big" or "small". The variant group is the form, so capital and small are covered separately.
- The validator checks this (§8): a sound-cued memory item whose sound another met letter shares must have a key-word clip and that letter as a partner.

---

## 4. How the engine reads it (mapping onto today's code)

### 4.1 New data

**`types.dart`**
- `enum WritingRule { memory, practised }`, `enum WritingMode { trace, copy, memory }`, `enum WritingCue { sound, name }`.
- `SkillNode.writing` (`WritingRule?`). **Also copy it in `withPrerequisites`.** Today that method drops `speaking`, so a speaking skill whose prerequisite is a roll-up would lose its flag, and its speech evidence would stop counting. That is latent now (no speaking skill of the three syllabi has a roll-up prerequisite), but the new field would fall into the same trap. Fix both together, with a test.
- `ItemMeta.writingMode` (`WritingMode?`; null for every item that is not an LS02 2.0 item, so T04 1.0 in the lands keeps today's behaviour), `ItemMeta.cue` (`WritingCue?`, memory only), `ItemMeta.startGuide` (`bool`, trace with `guide: start`), `ItemMeta.practiceOnly` (`bool`, an LS02 item with `"practice": true`: the handwriting step of eng C-23 and rus C-23, §11).
- `Catalog.memoryGroupsOf(id)` (the variant groups of the node's memory items, probes excluded) and `Catalog.practiceGroupsOf(id)` (the variant groups of the items that count toward practised, §6.1).

**`state.dart`**
- `SkillState`: `practiceCount` (int), `practisedGroups` (Set<String>), `memorySuccessDays` (Set<int>), `memoryCues` (Set<WritingCue>), `memoryGroups` (Set<String>).
- `started` becomes `n > 0 || practiceCount > 0`. A trace node with only practice has started, so it counts as a new skill in the session (by its bundle) and shows `learning`.
- `SkillStatus.practised` (new): the status of a trace node once practised.

**`engine_adapter.dart`**: `writing` from the skill doc; `writingMode`, `cue`, `startGuide`, `practiceOnly` from the trace 2.0 activity; `representation` of every LS02 item is `embodied` (frame §3.3.1).

### 4.2 The evidence class, decided first

In `apply`, after the course and delight checks and the session record, and before any evidence, decide the class of the answer for its skill. LS02 items name one skill (§8), so there is one class per answer:

```
practice  if the skill is a practised node, or item.writingMode == trace, or item.practiceOnly
hinted    if item.writingMode == copy
full      otherwise (memory, every non-LS02 item)
```

This mirrors L3 (QA-L3-3): speech decides first for which skills a spoken answer counts, and an answer that counts for none changes nothing.

### 4.3 What each class does, step by step

`h` is the hint level shown (`e.hintLevel`). `eff` is the level the engine reads: `h` for full, `min(h + 1, 3)` for hinted. A copy alone counts as level 1 (credit 0.8). A copy with the start dot counts as level 2 (0.5). A copy with the stroke drawn, or in trace mode, counts as level 3 (0). Each layer of help takes one step of credit.

| Engine step (today's code) | practice | hinted (copy) | full (memory) |
|---|---|---|---|
| session record `state.sessions` (stuck rules) | yes, with the row's result and `h` | yes | yes |
| `newSkillsInSession` on the skill's first event | yes | yes | yes |
| `Bkt.update` (`p`) | **no** | yes, weight `credit(eff)` when correct; full weight when incorrect (as every wrong answer today) | yes, as today |
| `n`, `nCorrect`, `nUnsure` | no; `practiceCount++` instead | yes | yes |
| `successes`, `successDays`, `successItems`, `successGroups`, `representationsPassed`, `checksPassed` | no | **no** (eff ≥ 1) | yes when correct and `h == 0` and not a probe |
| `memorySuccessDays`, `memoryCues`, `memoryGroups` | no | no | yes, on every memory success |
| `practisedGroups` | yes, when §6.1 holds | no | no |
| the day's **review** (`lastReviewDay`, `memory`, `needsRevisit`, `durableAt`) | **no** | **no**: copying has the model in view and is not a retrieval, so it never takes the day's review. The first memory (or non-LS02) answer of the day does | yes; "good" is correct with `h ≤ 1`, as today |
| `failRun`, `unsureRun`, `runTags` | no | yes | yes |
| `lastHintLevel` (for `avoidRepresentation`) | no | `h` (what was shown) | `h` |
| `_updateTags` (misconception evidence and decay) | **no** (with the path in view, a miss is motor control, not a misconception) | yes | yes |
| `repStats` | no | yes, success when correct and `eff ≤ 1` | yes, as today |
| `_updateSearch` (start a search, answer a probe) | no | may start a search, as any wrong answer | as today, with §7.3 |
| `_updateGaps` (repair) | no | repairs when correct and `eff ≤ 1` (a copy with no other help repairs, as a level-1 answer does) | as today |
| `_checkFresh` | no | yes (but it cannot add a success) | yes, with §5 |

---

## 5. Fresh mastery of a writing node

### 5.1 The conditions

A `writing: memory` node becomes fresh at the answer after which **all** of these hold (checked in `_checkFresh`, in this order, as today):

| # | Condition | Code |
|---|---|---|
| F1 | P(L) ≥ `masteryBar` (0.95) | unchanged |
| F2 | `successes` ≥ `needSuccesses` (4; 6 if core) | unchanged. In a pure writing node every success is a memory success |
| F3 | `successDays` ≥ `needDays` (2) | unchanged |
| F4 | **the cue condition**: `memorySuccessDays.length ≥ max(2, needDays)` and `memoryCues` holds both `sound` and `name` | **replaces** the representation check (`needRepresentations` is not read for this node) |
| F5 | `checksPassed` ≥ `needChecks` (1; 2 if core) | unchanged; every check item of a writing node is a memory item (§8) |
| F6 | set coverage: if `setCoverage`, every group of `variantGroupsOf(id)` is in `successGroups` (today) **and** every group of `memoryGroupsOf(id)` is in `memoryGroups` | the second half is new: each letter of the group written once from memory without help |

Durable mastery, revisits and needs-revisit are as today, with one difference: only memory (or non-LS02) answers take the day's review (§4.3). So the delayed check that makes a writing node durable is a memory answer, at least 7 days after fresh, with an item not used before fresh.

### 5.2 "Two days, one cued by the sound and one by the name"

F4 asks for memory successes on two different days and for both cues among them. That is the same as asking for a sound-cued success and a name-cued success **on two different days**. Proof: say successes exist on at least two days and both cues occur. Suppose no sound-cued and name-cued pair falls on different days. Then every sound-cued success and every name-cued success is on one single day x. Every memory success has one of the two cues, so every memory success is on day x, which contradicts the two days. So the plain check in F4 is enough; the code needs no pairing. Vector A11 shows it.

The cue condition is about the node, not each letter. A group passes when, for example, ת was written from its sound on Monday and א from its name on Tuesday, and every letter was written from memory once (F6). The teachers still give every letter items of both cues where both exist (L5 §8 target "copy and two memory cues"), so that the session builder can rotate them.

### 5.3 What the "two representations" rule means for a writing skill

The rule (curriculum §10.2, frame §3.3) exists so that a skill is not known only on one surface: a child who can do it in one picture and one way of asking may not have the idea. Every LS02 answer is `embodied`, so a writing node could never show two representations by the frame's table. The owner's rule replaces them with the two cues, and they carry the same intent:

- **The sound cue** is the route of spelling: hear a sound, find its letter, form it. It is what writing a word needs.
- **The name cue** is the route of the letter as an object: the label the child uses to talk about letters and that spelling aloud uses.
- The two are different retrieval paths to one motor plan. A child who can write מ from /m/ and from "mem" holds the form itself, not one association. Taught together, names and sounds help each other (Piasta and Wagner 2010).
- **Seeing the letter** (recognition) is not a third cue. It belongs to the knowledge facet (`B-14`, `B-16`, `B-18`), which has its own pictorial and symbolic items.
- **Copying is not a representation of knowing**, because it needs no retrieval: the form is in view. Retrieval is what strengthens memory (Roediger and Karpicke 2006). Free printing, not tracing, recruited the brain's letter-reading network in pre-literate children (James and Engelhardt 2012, small sample).

### 5.4 What P(L) does here

With an open task (guess 0.02), BKT passes 0.95 after two right answers, and after two copies (vector A1). So for a writing node, **F1 is never the condition that decides**: F2 to F6 are. P(L) still serves the gap search and the unlock bar. Dependents of a writing node (rus C-22, heb C-26 and C-27, eng C-13, C-15.G3, C-16) can therefore unlock after copying, before memory mastery. That is intended. Unlocking at 0.8 only lets the next skill start, and every dependent has its own mastery evidence. If QA's simulator shows dependents opening too early, the tunable is a higher guess for copy items (for example 0.25), not a change of the rule.

---

## 6. A trace node: practised, met, status

### 6.1 Practised

A trace node is **practised** when every group of `practiceGroupsOf(id)` is in `practisedGroups`.
- **Counts toward practised:** an answer that is correct, at `h ≤ 1`, outside a probe, of an item that is a `trace` with `guide: start`, or (heb B-27) an own-name item.
- **Does not count:** `guide: full` traces (practice that leads up to it).
- The validator makes sure every letter of the node has a start-guide trace item (§8).
- `h ≤ 1` because the start dot and the arrow of level 1 are what "the start dot only" already shows. Level 2 (the stroke drawn) and level 3 (the demonstration) do not count.
- A trace node that the child skipped by placement (`assume`) is met as well.

### 6.2 Met, and "never blocks"

New: `Engine.isMet(id)`.
- **Trace node:** practised, or assumed.
- **Every other skill:** p ≥ `unlockBar` (today's test).

`isUnlocked` uses `isMet` for each prerequisite instead of the bare `p ≥ unlockBar`. Roll-up prerequisites are already resolved into their groups by the catalogue, so a prerequisite on the roll-up `HEB-B-24` means every `B-24.Sn` practised.

*The same hook carries frame §3.3.8, "a speaking skill never blocks, met at practised". That rule is not in the code today: `isUnlocked` reads only p. Handed off with this spec.*

### 6.3 Status and roll-up

`statusOf` a trace node:
- not started: `ready` or `notStarted`, as today;
- some practice but not every letter: `learning`;
- practised (or assumed): `practised`.

It never has `freshMastery`, `durableMastery`, `needsRevisit` or `gap`.

`rollUpStatus`: every group `practised` → `practised`. Otherwise as today, with `practised` treated as begun.

### 6.4 What a trace node never does

- It is never a probe target and never the origin of a gap search (practice never starts one).
- `_nextTarget` skips trace nodes as candidates; it may walk through them to their prerequisites.
- It is never in `dueChecks`, since it never has `freshAt`.
- It has no check items and no probe items (validator).
- No gate's `requires` names it (validator). `masteryLevels` in `gates.dart` gives it no level.
- `uncoveredGroups(id)` returns the letters not yet practised, so the session builder rotates the trace items through them. For a writing node it returns the letters with no memory success yet.
- The parent view shows "practised", in the same way as a speaking skill (`language_progress.dart`); a writing node shows the usual statuses.

---

## 7. Hints, probes, checks and the gap search

### 7.1 The hint ladder (L5 §5.2)

| Level | Picture | In `copy` (eff) | In `memory` (eff) |
|---|---|---|---|
| 0 | none (copy: the model; memory: nothing) | 1 (credit 0.8) | 0 (1.0) |
| 1 | the start dot and the arrow of the stroke the child is on | 2 (0.5) | 1 (0.8) |
| 2 | the stroke drawn slowly once, then the box clears (motion: the new representation) | 3 (0) | 2 (0.5) |
| 3 | "show me": trace mode for this item | 3 (0) | 3 (0) |

- **After any miss** (named or not), the start dot comes back: the item is at level 1 from then on. A second miss on the same item gives level 2; a third gives level 3. This is the controller's ladder of today (first mistake → level 1, later mistakes → the next level). An unnamed miss moves the ladder although it writes no row, so the session must count it locally.
- In `model: hide`, a tap that shows the model again is level 1.
- **Not hints:** replaying the cue, the model's replay after a success, and the soft fade of a missed stroke.
- In `trace`, the ladder is T04's (first stroke, whole stroke, demonstration); only `h ≤ 1` counts toward practised.

### 7.2 Probes and checks

- A **probe** of a writing node is a memory item with no help; each probe item takes one answer, as every probe item does. A trace node is never probed (§6.4). Copy and trace items are never probes (validator). Placement (LS13) never uses a copy or trace item.
- A probe is never a success (as today), so it adds nothing to F2 to F6. It does move P(L).
- **A writing probe needs two named misses to fail.** Today an open task (`optionCount` 0) fails its probe on one wrong answer, because a lucky right answer is unlikely. That holds for the pass: one free-written right letter passes. For the fail it is harsh here. Mirror and look-alike errors are common and normal in 5- and 6-year-olds and fade with age, and one stroke can go astray by motor noise. So in `_probeAnswered`, the number of wrongs needed is `params.probeWrongsToFail` (2) when the item has a `writingMode`, whatever `probeRightsToPass` says.
- An **unnamed miss in a probe** writes nothing. The box clears with no start dot (a probe has no help), and the child may try once more. After a second unnamed miss the item ends with no row, and the search keeps its target.
- A **check** of a writing node is a memory item (heb B-26: "a letter not practised that day"; a confusable letter). It counts toward F5 only as a memory success.

### 7.3 The gap search from a writing node

- Two wrong rows in a row (named misses in copy or memory, outside probes) or an active tag start a search, as for every skill.
- The candidates are the writing node's prerequisites. The trace node is skipped (§6.4), so the probes go to the **knowledge facets**: `B-15.Sn` (the sound) and `B-14.Sn` (the name) in Hebrew; the group's letter skill in Russian; `B-16` or `B-17` in English.
- That is the right place to look. A child who cannot write the letter for a cue may not know the sound or the name. If the facets pass, the search closes and the writing goes on as practice, as today.

---

## 8. Validator rules (pack, L5-2b)

1. An LS02 2.0 item names exactly one skill. A letter-canvas item names a skill with a `writing` field; a word-canvas item names a skill of strand `wr` or `wri`. An `intro` item names the trace node of its group: it carries the group's first trace and opens the bundle (added 2026-11-06 while applying §11: the English and Russian slices had filed their intros under the letter skill).
2. A letter-canvas item has one form, and its `variantGroup` is that form id.
3. A `writing: practised` node has only `intro` and `trace` items (heb B-27: also own-name items). Every letter in it has at least one `trace` item with `guide: start`. It has no `probe` or `check` item, it is not in a gate's `requires`, and it has no `masteryRequires`.
4. A `writing: memory` node has no `trace` items, and at least one non-probe memory item for each cue. Every letter in it has at least one non-probe memory item. Every `check` and `probe` item in it is a memory item. It has `setCoverage: true` (E-3: every letter of the group). It has no `masteryRequires.representations`. It is not a bundle member.
5. A memory item has a `cue` and the cue's clip.
   - A sound cue whose sound another letter already met in the course shares (§3.4) has a key-word clip and that letter in `classify.partners`.
   - A letter with no sound of its own has no sound-cued item.
   - A letter whose name clip is its sound clip has no `name` item.
   - Every writing node has at least one letter with a `name` item and at least one with a `sound` item.
6. `copy` and `trace` items are never `purpose: probe` or `check`. `"practice": true` is allowed only on a word-canvas item, and such an item is never a probe or check either.
7. A writing node's prerequisites include the trace node of its group and the knowledge facet(s) of its group (§2).
8. The catalogue script (L5-7): every tag named in a writing node's `classify` is of family STROKE or SHAPE, or is the course's homophone tag as a partner (§3.4).

---

## 9. Test vectors

**Fixture** (course `heb`, defaults of `EngineParams`; p shown to 3 decimals as computed with `Bkt.update`):
- `N` and `S`: the name and the sound facet of group S1 (LS01, 3 choices).
- `T`: the trace node (`writing: practised`). `N`, `S` and `T` form bundle `S1`.
- `A`: the pre-writing node (`writing: practised`), the prerequisite of `T`.
- `W`: the writing node (`writing: memory`, `setCoverage: true`, not core), with prerequisites `T`, `N` and `S`.
- `D`: a later skill with prerequisite `W`.
- Two letters, `m` and `l` (variant groups).

Items:
- `T.f.m`, `T.f.l`: trace, full guide. `T.s.m`, `T.s.l`: trace, start dot only.
- `A.s.down`, `A.s.arch`: trace, start dot only.
- `W.cm`, `W.cl`: copy beside the model.
- `W.ms`, `W.mn`, `W.ls`, `W.ln`: memory, cued by sound or name.
- `W.km` (memory, sound, check `transfer`), `W.kl` (memory, name, check): the checks.
- `W.pm`: memory, sound, probe.

Notation:
- `d2 W.ms ok0` means day 2, item W.ms, correct, hint level 0 shown.
- `miss(MIRROR)` means incorrect with a named tag.
- "unnamed" means a miss that wrote no row.

### A. Fresh mastery of the writing node

| # | Answers, in order | Expected |
|---|---|---|
| A1 | d1 W.cm ok0, d1 W.cl ok0, d2 W.cm ok0, d2 W.cl ok0, d3 W.cm ok0, d3 W.cl ok0 | p 0.786, 0.953, 0.990, 0.998, 0.999, 0.999; successes 0; **never fresh** (F2 to F6 fail); status `learning`; `memory` (review) still null |
| A2 | d1 W.ms ok0, d1 W.ls ok0, d2 W.ms ok0, d2 W.km ok0, d3 W.ls ok0 | successes 5, memory days 3, cues {sound}; **not fresh: F4** (no name cue) |
| A3 | d1 W.ms ok0, d1 W.ln ok0, d1 W.mn ok0, d1 W.kl ok0, d1 W.ls ok0 | successes 5, cues both, memory days 1; **not fresh: F3 and F4** (one day) |
| A4 (the normal path) | d1 W.cm ok0, d1 W.cl ok0, d1 W.ms ok0, d1 W.ln ok0, d2 W.mn ok0, d2 W.kl ok0 | p 0.786, 0.953, 0.999 …; **fresh at answer 6** (4 successes, 2 days, both cues, 1 check, m and l covered) |
| A5 | d1 W.ms ok1, d1 W.ln ok1, d2 W.mn ok1, d2 W.kl ok1, d3 W.ls ok1 | p 0.786, 0.953, 0.990, 0.998, 0.999; successes 0; **never fresh** (with the start dot, memory is a hinted answer) |
| A6 | d1 W.ms ok0, d1 W.mn ok0, d2 W.ms ok0, d2 W.km ok0, d2 W.mn ok0 | successes 5, 2 days, both cues, check; **not fresh: F6** (l never written from memory) |
| A7 | d1 W.ms ok0, d1 W.ln ok0, d2 W.pm ok0 (probe), d2 W.mn ok0 | successes 3 (the probe is not one); **not fresh: F2 and F5** |
| A8 | d1 W.ms miss(MIRROR), d1 W.ms ok1, d1 W.ln ok0, d2 W.mn ok0, d2 W.ls ok0, d2 W.kl ok0 | p 0.167, 0.767, 0.994, 0.999 …; the retry is not a success; **fresh at answer 6**; tag `M-HEB-MIRROR` suspected (score 1.0 right after the miss, one item; later right answers of items carrying the tag decay it) |
| A9 | d1 W.cm ok1 | eff 2, credit 0.5: p 0.566 |
| A10 | d1 W.cm ok2 | eff 3, credit 0: p 0.200 (unchanged); n 1 |
| A11 (§5.2) | d1 W.ms ok0, d1 W.ln ok0, d2 W.ls ok0, d2 W.km ok0 | **fresh at answer 4** (the name cue was only on day 1 and that is enough) |
| A12 (core) | `W` core; A4's six answers, then d2 W.ls ok0, d3 W.km ok0 | not fresh after answer 6 (4 of 6 successes, 1 of 2 checks); **fresh at answer 8** |
| A13 | d1 W.ms ok3 (done in trace mode after the ladder) | p 0.200 (credit 0); n 1; no success, no practised letter for `T` |

### B. The trace node: practised, met, status

| # | Answers, in order | Expected |
|---|---|---|
| B1 | d1 T.f.m ok0, d1 T.f.l ok0 | `T`: practiceCount 2, p 0.200, n 0, status `learning`, not met; `W` locked |
| B2 | B1, then d1 T.s.m ok0, d1 T.s.l ok1 | `T` practised; status `practised`; met. `W` still locked while `N` or `S` is below 0.8 |
| B3 | d1 T.s.m ok2, d1 T.s.l ok0 | m not practised (level 2): status `learning`, not met |
| B4 | d1 T.s.m miss(M-HEB-STROKE), d1 T.s.m ok1, d1 T.s.l ok0 | practised; no `TagState` for `M-HEB-STROKE`; `T` p 0.200, n 0, failRun 0; no gap search |
| B5 | B2, and `N`, `S` both at p ≥ 0.8 | `W` unlocked (`ready`) |
| B6 | `A`: d1 A.s.down ok0, d1 A.s.arch ok0; `N` and `S` prerequisites met | `A` practised; the bundle S1 (`N`, `S`, `T`) unlocked although `A`'s p is 0.200; `A` is never fresh and never in `dueChecks` |
| B7 | Only A.s.down done | `A` not met, so the bundle S1 stays locked |
| B8 | Roll-up `R` of `T.S1` and `T.S2`: S1 practised, S2 `learning` | `R` is `learning`; once S2 is practised too, `R` is `practised`; `masteryLevels` gives `R` no level |
| B9 | `T` assumed by placement, no answers | met; status `practised` |
| B10 | One session: d1 T.s.m miss, miss, miss (three rows) | `isStuck` true (the session record holds them); no search, no tag, p unchanged |
| B11 | `T` is the only weak prerequisite of `W` during a search | `nextProbe()` never returns `T` |
| B12 | `W` unlocked; d1 W.cm ok0, d1 W.cl ok0 | `W` p 0.953, status `learning` (no success); `D` unlocked (§5.4: intended) |

### C. Reviews, revisits, durable

Each row starts from A4 (`W` fresh on day 2, `itemsAtFresh` = {ms, ln, mn, kl}).

| # | Answers after A4 | Expected |
|---|---|---|
| C1 | d5 W.cm ok0, d5 W.ms miss(MIRROR) | the copy does not take the day's review; the memory miss does: `needsRevisit` true |
| C2 | d5 W.cm ok0, then nothing else on day 5 | no review on day 5: `lastReviewDay` stays 2, `memory` unchanged |
| C3 | d9 W.cl ok0, d9 W.ls ok0 (at least 7 × 24 hours after the fresh answer) | the review is W.ls (good); 7 days after fresh, an item not used at fresh: **durable** on day 9 |
| C4 | d9 W.ms ok0 | a good review, but W.ms was used before fresh: not durable |
| C5 | d9 W.ls ok1 | a good review (h ≤ 1), not a success; durable (as today, a level-1 delayed check counts as good) |

### D. Probes and the search

| # | Situation and answers | Expected |
|---|---|---|
| D1 | a search has `W` as its target; W.pm ok0 | the probe passes on one right answer (`probeRightsToPass(0)` = 1) |
| D2 | the same; W.pm miss(MIRROR) | the probe is not failed yet (`wrongRun` 1 of 2); a second named miss fails it |
| D3 | the same; an unnamed miss, then W.pm ok0 | the first miss wrote no row; the pass is the only answer, and it passes |
| D4 | d1 W.ms miss(MIRROR), d1 W.ls miss(STROKE) (not probes) | `failRun` 2, so a search starts at `W`; `nextProbe()` is `N` or `S`, never `T` |
| D5 | any unnamed miss in copy or memory, outside a probe | the engine state is exactly what it was before (no row) |
| D6 | memory sound cue for ת with ט met (S4 on); the child writes ט | no row; the next answer of the item is at h ≥ 1 |

### E. The classes, as a whole

| # | Item and answer | p | n | successes | review | tag |
|---|---|---|---|---|---|---|
| E1 | trace, any answer | unchanged | unchanged | unchanged | none | none |
| E2 | copy ok0 | +credit 0.8 | +1 | unchanged | none | decays the item's tags |
| E3 | copy miss(tag) | full wrong weight | +1 | unchanged | none | evidence |
| E4 | memory ok0 | +credit 1.0 | +1 | +1 (and memory day, cue, letter) | the day's first | decays |
| E5 | memory miss(tag) | full wrong weight | +1 | unchanged | the day's first | evidence |
| E6 | `"practice": true` word canvas, any answer | unchanged | unchanged | unchanged | none | none |
| E7 | T04 `trace` 1.0 in a maths land | as today (this file changes nothing there) | | | | |

---

## 10. What this does not change, and what is open

- **Unchanged:** BKT, the credit table, the mastery bar, success counts, days and checks, durable mastery, FSRS revisits, bundles (E-2), set coverage for other skills (E-3), the sound-right outcome (E-4), speech evidence (L3), and every maths land (T04 1.0).
- **The free-stroke tolerances** are design values that the qa-engineer tunes on adult and child-like samples (L5 §5.2). This rule depends only on the result each answer gets (correct, a named miss, or an unnamed miss), not on the numbers.
- **The simulator** (`simulator.dart`) must model the three classes and the cue condition, so that L5 acceptance criterion 10 ("every node can reach fresh mastery") can be shown for writing nodes.
- **Lesson authoring:** a bundle opens with `intro`, then traces (full, then start dot). The writing node is a new skill of its own against the limit of 2 a visit. The Hebrew visit mix (one code, one listening, one writing activity) may use either node.

---

## 11. The edits for each teacher (L5 §14 item 1)

These are lists, not edits made. Each teacher changes their own `syllabus.md` (and `templates.md`, `band-a-content.md` where named), through the orchestrator, after the owner confirms the structure (report).

### english-language-teacher (`docs/languages/english/syllabus.md`)
1. **New `ENG-B-23` (WR)**, a roll-up of `B-23.G1` (s a t p i n), `.G2` (m d g o c k), `.G3` (e u r h b f l), `.G4` (j v w x y z q).
   - Wording: "Traces the letters of each group, starting at the right point and going the right way: the writing facet of the letter introduction."
   - `writing: practised`; LS02 trace, full guide then the start dot only; no check, no probe, no misconception column (stroke tags are diagnosed in `B-19.Gn`).
   - Bundles: `B-16` + `B-23.G1`, `B-17` + `B-23.G2`, `C-01` + `B-23.G3`, `C-02` + `B-23.G4`. G3 and G4 are Band C content under a Band B id, as rus `B-24.G5`.
2. **`ENG-B-19.G1`**:
   - Wording: "Copies s a t p i n beside a model, then writes each from memory when the voice says its sound or its name."
   - Prerequisites `B-23.G1`, `B-16` (no longer bundled; the oral gate still holds it). `writing: memory`.
   - Replace "start, direction and order checked" with "start, direction and shape checked; stroke order is not scored (Q2)".
   - Replace "Mastery needs evidence in memory mode" with the E-1 rule: memory successes on two days, one cued by the sound and one by the name; copy counts like a level-1 hint; tracing is in `B-23.G1`.
3. **`ENG-B-19.G2`**:
   - Prerequisites `B-23.G2`, `B-17`, and `B-19.G1` (kept: d g o c build on the c-shape of a).
   - c and k share /k/: their sound cues use the key word ("/k/ as in cat", "/k/ as in kite") with the other letter as the partner, tag `M-ENG-C-K` on the way (§3.4); or name cues only.
4. **`ENG-C-15.G3`, `.G4`**:
   - Prerequisites `B-23.G3` + `C-01` + `B-19`, and `B-23.G4` + `C-02` + `C-15.G3`; not bundled; `writing: memory`.
   - Move the LS01 "which is b?" taps (b d p, b d p q) to `C-01` and `C-02` (letter knowledge), so that the writing nodes hold LS02 items only.
5. **Lines 17 and 18** (sub-skills and bundles), **§3 table** (rows 1 to 4: "B-16 + B-23.G1, then B-19.G1"), **§5 W2** (now `B-23.Gn`) and **W3** (`B-19.Gn`, `C-15.Gn`).
6. **§6.2 oral gate:** it holds `B-16` to `B-23` (and frame §3.3.6, for the curriculum-expert).
7. **Counts** (line 116): Band B 23 skills, 66 in all. Sub-skill nodes are now 8 (`B-19.G1`, `.G2`, `B-23.G1` to `.G4`, `C-15.G3`, `.G4`) and the roll-ups `B-19`, `B-23`, `C-15`, so 71 nodes; WR 10. Re-run the prerequisite script (no cycle, no bundle member requiring another).
8. **Band C, for L6:**
   - `C-13`: capitals, a mixed skill with no `writing` field. Its LS02 answers get the mode classes; trace is practice.
   - `C-16`: the word canvas in memory mode counts in full. The canvas checks the formation of the expected letters, so an invented spelling by hand is an unnamed miss, never wrong; spelling is diagnosed on LS06 tiles.
   - `C-23`: the handwriting step is `"practice": true`.
9. **Pilot slice** (`english/band-b-pilot.md`): the `trace` items of `B-19.G1` move to `B-23.G1`, the bundle becomes `B-16` + `B-23.G1`, and `B-19.G1` keeps the `copy` and `memory` items, with prerequisites `B-23.G1` and `B-16`.

### hebrew-language-teacher (`docs/languages/hebrew/syllabus.md`, `templates.md`, `band-a-content.md`)
1. **`HEB-A-14`**:
   - `writing: practised`: met once down, right to left, arch and circle are each traced once with the start dot only.
   - Drop "Check: a combined stroke" (it stays a practice item). `M-HEB-STROKE` is no longer evidenced in A-14.
   - The Band A batch's A-14 items lose their check marks. Separate and still open: L5 §14 item 5 (the arch starts at the left foot, the circle goes clockwise).
2. **`HEB-B-24.Sn`**: `writing: practised`, met once every letter of the group is traced once with the start dot only. Drop the check ("the group's letters in a mixed order" becomes practice) and the tag.
3. **`HEB-B-25`, retired:** merged into `B-26` by E-1 (2026-11-06). Its two copy modes (beside, and after the model hides) and its confusable-letter check (`M-HEB-MIRROR`) move to `B-26.Sn`.
4. **`HEB-B-26.Sn`**:
   - Wording: "Copies a print letter beside the model or after it hides, then writes it from memory for a heard sound or name."
   - Prerequisites `B-24.Sn`, `B-14.Sn` (names, needed by the name cue: new), `B-15.Sn`. `writing: memory`.
   - Misconceptions `M-HEB-STROKE`, `M-HEB-MIRROR`, `M-HEB-SHAPE-*` (partners).
   - Cue rules: א by name only; ם and the other finals named as finals, with sound cues "at the end of a word"; from S4 the shared sounds (ת/ט, כּ/ק, ח/כ, ו/ב, ס/שׂ) by key word with the partner, `M-HEB-HOMOPHONE` on the way.
   - Checks are memory items: a letter not practised that day; a confusable letter.
5. **`HEB-B-27`** (proposal, for the owner): `writing: practised`, met once the name is built with its tiles and written once letter by letter. Drop "Check: after a day away" (own-name items are never a probe or a check).
6. **Band C, for L6:**
   - `HEB-C-26` becomes the script trace node: "Traces script letters by direction group", `writing: practised`, prerequisites `C-25` and `B-26` (was `B-25`); L5 §14 item 6, the five groups.
   - `HEB-C-27`: "Copies, then writes script letters from memory, including the final forms", `writing: memory`, prerequisites `C-26`, `C-25`; it takes C-26's copy items.
7. **Line 19** (B-25 out of the per-group list), **line 250** ("B-24 → B-26": trace, then copy and memory), **line 245** counts (Band B 27, 68 in all; 24 sub-skill nodes over 4 roll-ups; WR 13), **`templates.md`** line 66 (B-25 out) and the LS02 row (B-24.Sn, B-26.Sn, B-27). Re-run the prerequisite script.
8. **Pilot slice** (`hebrew/band-b-pilot.md`): the 3 `B-25.S1` items go to `B-26.S1` (5 + 3 = 8 items), the pencil card `card.heb.pencil.s1-copy` names `B-26.S1`, and the counts in §12 drop to 6 skill nodes.
9. **Pilot §5.6, the ladder:** level 3 there is "copy mode, then trace if needed". L5 §5.2 says level 3 is trace mode for the item. Either way it is level 3 (credit 0), so the engine is not affected, but the three courses should show the same level 3. Recommended: trace mode, as L5 says.

### russian-language-teacher (`docs/languages/russian/syllabus.md`)
1. **`RUS-B-24.Gn`**: `writing: practised`. Replace "The writing facet is mastered only through B-26 (memory mode, D4)" with "met once every form of the group, capital and small, is traced once with the start dot only; it never blocks; writing mastery is `B-26.Gn`".
2. **`RUS-B-26.Gn`**:
   - Prerequisites `B-24.Gn` **and** the group's letter skill: G1 `B-18`, G2 `B-20`, G3 `B-21`, G4 `B-22`, G5 to G10 `C-01` to `C-06`. Without it, a memory cue could ask for a sound the child has not met. `writing: memory`.
   - Every memory item's frame line says "big" or "small"; the capital and the small form are separate letters for coverage.
   - Misconceptions `M-RUS-SHAPE` (partners), `M-RUS-STROKE` (new, L5 §14 item 3), and `M-RUS-LATIN` for the mirror of И and Я (they mirror into N and R); the teacher decides the mirror mapping.
3. **`RUS-C-22`**: as eng C-16 (the canvas checks formation; spelling is diagnosed on tiles). **`RUS-C-23`**: the optional handwriting is `"practice": true`.
4. **Line 65** (bundles: wording only, "copy and memory writing `B-26.Gn` follow"); the counts are unchanged.
5. **Pilot slice** (`russian/band-b-pilot.md`): already in this structure. Add `B-18` to `B-26.G1`'s prerequisites. Write А У О with one `sound` cue each (§3.4: the two-forms proposal is not taken). М carries the name cue.

### The curriculum-expert's own follow-ups (frame.md)
- §3.3.3: copy and memory writing (heb `B-26`, rus `B-26`, eng `B-19`, `C-15`) follow the bundle; the trace nodes are in it.
- §3.3.8: E-1 next to the speaking rule, with `isMet`.
- §4.2: `M-HEB-MIRROR` first skill `B-26` (was B-25); `M-HEB-STROKE` first skill `B-26` (A-14 is practice); new `M-RUS-STROKE` when the Russian teacher agrees.
- §2.3 LS02: "the order" leaves the free-stroke check (Q2).

---

## 12. Sources

- The owner's decisions of 2026-11-06 (L5 approved with Q1 and Q2 as recommended).
- The code read on 2026-11-06 in `languages-l5`: `app/lib/engine/engine.dart` (`apply`, `_updateSkill`, `_speechCounts`, `_checkFresh`, `_probeAnswered`, `isUnlocked`, `statusOf`), `state.dart`, `types.dart` (`SkillNode.withPrerequisites` drops `speaking`), `mastery.dart`, `params.dart`, `rollup.dart`, `gates.dart`, `content/engine_adapter.dart`, `play/trace_session.dart`, `play/lesson_controller.dart` (`_answered`, `_write`).
- James, K. H. and Engelhardt, L. (2012). The effects of handwriting experience on functional brain development in pre-literate children. *Trends in Neuroscience and Education* 1(1), 32–42. [PMC](https://pmc.ncbi.nlm.nih.gov/articles/PMC4274624): free printing, not tracing or typing, recruited the letter-reading network; small sample.
- Zemlock, D., Vinci-Booher, S. and James, K. H. (2018). Visual–motor symbol production facilitates letter recognition in young children. *Reading and Writing* 31, 1255–1271. [PDF](https://can.lab.indiana.edu/publications/pub-files/2018-zemlock-vinci-booher-and-james-read-writ.pdf): printing, not typing, improved letter recognition, and only in the older children (about 4½); it did not compare tracing with copying.
- Merritt, E., Swain, S. N., Vinci-Booher, S. and James, K. H. (2020). *Frontiers in Psychology* 11, 500. [PMC](https://pmc.ncbi.nlm.nih.gov/articles/PMC7098985/): a fixed stroke order hindered symbol learning under 4½ (Q2; novel symbols, not letters).
- Patchan, M. M. and Puranik, C. S. (2016). *Computers & Education* 102, 128–137: feedback at the end of a stroke; finger writing on a tablet worked.
- Piasta, S. B. and Wagner, R. K. (2010). *Reading Research Quarterly* 45(1), 8–38: names taught with sounds (the two cues).
- Roediger, H. L. and Karpicke, J. D. (2006). Test-enhanced learning. *Psychological Science* 17(3), 249–255: retrieval, not re-study, strengthens memory (why copying is neither a success nor a review). Studied with students, not young children.
- **Thin evidence, said plainly:** no study compares trace, copy and memory credit in an adaptive app. The credit steps are the owner's rule set on these findings. Whether mirror errors should need two probe misses is a judgement from how common reversals are at 5 and 6, not a measured number.

## 13. Owner decision (2026-11-06)

The owner approved, in chat, all five structure changes of §2 and §11: split ENG-B-18 into B-18.G1 and B-18.G2 (the English teacher's proposal); add ENG-B-23 (trace nodes, `.G1` to `.G4`); retire HEB-B-25 into HEB-B-26; HEB-A-14 met once practised; HEB-B-27 met once practised.

## 14. Applied (2026-11-06)

§11 was applied the same day by the curriculum-expert in `D:
itznutz-l5`, as the owner approved:
- **Syllabi:** `english/syllabus.md` (B-18 split into `.G1` and `.G2`; new `B-23` with `.G1` to `.G4`; B-19 and C-15 as writing nodes; the b/d taps moved to C-01 and C-02; counts 66 skills, 10 sub-skill nodes), `hebrew/syllabus.md` (A-14, B-24, B-27 and C-26 practised; B-25 retired into B-26, which now needs B-14.Sn; C-27 takes the copy; counts 68 skills, 24 sub-skill nodes), `russian/syllabus.md` (B-24 practised; B-26.Gn needs its group's letter skill); the templates files and the Hebrew Band A A-14 items.
- **Frame:** §2.3 (LS02: order out of the check, E-1, the level-3 ladder; checks in free-response modes), §3.3.1 (letter → picture is pictorial), §3.3.3 (trace nodes in the bundle, writing after it, pacing inside a group), §3.3.6, §3.3.8 (`isMet`), §4.2 (first skills; four new tags) and the new §4.6 (the pilot decisions).
- **Pilots:** the English trace items and intros are in `B-23.G1` (with a start-dot trace for every letter, so the node can be practised), the reading items in `B-18.G1`; the Hebrew B-25.S1 items are B-26.S1 items and the level-3 hint is trace mode; the Russian intros are in `B-24.G1` and `B-26.G1` needs `B-18`. The three check scripts pass.
- **Prerequisite graph:** re-checked by script on the three syllabi: every id exists, no cycle, no bundle member requires another.
