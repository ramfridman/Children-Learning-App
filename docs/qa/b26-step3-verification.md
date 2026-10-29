# QA verification: B-26 step 3 (the app wires the named island and the way into the child's home)

2026-10-29, qa-engineer. Worktree `D:\nitznutz-b26`, branch `b26-nitzi-home`, step 3 uncommitted on top of `8263075`
(step 2). Plan: `docs/milestones/B26.md` step 3; design: `docs/design/nitzi-home.md` sections 2 to 4; earlier records:
`b26-step1-verification.md`, `b26-step2-verification.md`. The untracked `.claude/settings.json` and `.claude/hooks/` are
the orchestrator's; not touched, and no `voice_gen` command was run.

**Verdict. Step 3 may be committed.** Everything asked for holds on four boards at text scale 1.0 and 1.3 in the real
app; no new defect. QA-29 is closed. Nits (no blocker): a question for the hebrew-text-editor about the nameless bubble,
two layout notes for the design-director for step 4, and QA-19 (open, older) seen again in the profile picker.

## What ran

| Command (in `app/` unless said) | Result |
|---|---|
| `flutter analyze` | No issues found |
| `dart format --output=none --set-exit-if-changed .` | 285 files, 0 changed, exit 0 (286 with QA's file) |
| `flutter test` (whole suite, as delivered) | **1710 passed, 8 skipped, 0 failed** (8 min 14 s), the developer's count |
| `flutter test test/qa_b26_step3_test.dart` (QA's new file) | **79 passed** (72 real-app cases, 4 rename, 2 scroll, 1 lands), 6 min 48 s |
| `python tools/export-hebrew-review.py`, then `python tools/hebrew_voice_review.py` (repo root) | 9,521 rows, master text-ready 9,455, proposed 43, unchanged 23; `docs/review/` unchanged (`git status` clean there): `he.dart` and the tables are not part of step 3 |
| 6 product mutations (below) | all caught |
| `flutter analyze`, format, `flutter test` (whole suite with QA's file; run last) | No issues; 286 files, 0 changed; **1789 passed, 8 skipped, 0 failed** (11 min 30 s) = 1710 + 79 |

## Checks

1. **Unrelated goldens.** `git status` lists 7 changed PNGs and no new one: `companion_home_hero_phone`,
   `home_long_name_tablet_landscape/portrait`, `home_phone`, `home_phone_se`, `home_tablet_landscape`,
   `home_tablet_portrait`. No ceremony, lesson or other golden is modified or untracked (`git diff --stat HEAD --
   '*.png'`: 7 files): the developer's slip with `--update-goldens` left nothing behind.
2. **The 7 goldens against HEAD** (pixel regions, crops at 2x and 3x): each differs only in the home sign
   (`הָאִי שֶׁל נֹעָה` / `נועה` / `אלכסנדרה` instead of `הָאִי שֶׁל נִיצִי`; phone 570..709 x 320..356, SE 450..589, tablets
   940..1079 and 530..669, long names 914..1105 and 504..695). The bubble, the pill, the Parents button and the pebbles
   are unchanged. The hero golden still shows the family character's dark red square (no change outside the sign).
3. **The real app, 4 boards x text scale 1.0 and 1.3 x 9 names** (`נועה`; blank; only direction marks; RLM/LRE/PDF/LRM
   around `מיכל`; emoji; `Zoë Élodie`; 24 x ש; 25 letters; 40 characters in four parts; an empty name cannot be stored,
   the database refuses it, so blank and marks-only stand for it). For each: the sign says the island of the cleaned name
   (or its shortened form, or `הָאִי שֶׁלִּי`), never Nitzi's; **the sign, the free part of the island beside the companion,
   and Today's Adventure each open `HomeIslandScreen`** (never a `LandScreen`), whose title is `island.title` (the whole
   name up to 24, `…` after; parts_40 shows `אבגדהוזחטי אבגדהוזחטי…`); the title stays on screen and off the back pebble;
   back returns to the map; no exception except QA-19 (the picker's cards, 2.4 pt, at 1.3 on the SE and the tablets,
   raised before the map; the phone pill at 1.3).
4. **The bubble** in the same 72 cases: the cleaned name (no direction marks); with no usable name only
   `מַה בַּבַּקְבּוּק?`; at most 624 (phone), 497 (SE), 210 (tablets) wide, on screen; one line on phones, two at most on
   tablets (QA-29 closed: `שששששששש…,` / `מַה בַּבַּקְבּוּק?` at 1.0, `ששששש…,` at 1.3). Phone at 1.3: the 24 x ש name is
   whole and the bubble 611.6 wide (left 28); 40 characters 597.3 (left 43); SE at 1.3 the same names are shortened
   (`שששששששששששששששששש…`, 486.4, left 27; `אבגדהוזחטי אבגדהוזחטי…`, 386.1). The brief's figures (463, left 177 /
   74) were measured with the step-2 code; step 3 lets the phone bubble grow to 624.
5. **A name changed by the family** (all 4 boards, the developer's sync path: `upsertProfileFromFamily` then
   `appStateProvider` refreshed): to `אלכסנדרה`, the sign, the bubble and the home's title follow; to blank, the sign is
   `הָאִי שֶׁלִּי`, the bubble only the question, the title the fallback; no exception.
6. **Scroll kept**: tablet portrait scrolled to 300, home opened from the pill, back: 300; phone panned to 120, home
   opened from the sign itself, back: 120 (the developer tested the phone from the pill at 420).
7. **Lands.** In the real app `openableLands` has no `Land.nitzi` and `onOpenHome` is set; `_openableLands()` builds
   from `TrophyLand` (no `nitzi`) plus Counting; `HomeScreen._tapFor` returns `onOpenHome` for Nitzi before any
   `onOpenLand`, so even with Nitzi wired into the set (mutation M4) nothing reaches `TrophyLand.values.byName`.
8. **Placeholder screen** (rendered and looked at, phone `נועה`, SE 24 x ש at 1.3, tablet portrait 40 characters): a
   white title card centred at the top, the back pebble at the start corner, nothing else; no dead button.
9. **Mutations** (each restored, SHA-256 of both files checked):

   | Mutation | Caught by |
   |---|---|
   | M1 the bubble never shortens (`_fittedName` returns the name) | `home_sign_test`, `qa_b26_home_sign_test`, QA step 3 |
   | M2 `homeIsland` not passed (sign back to Nitzi's) | `home_island_flow_test`, QA step 3 |
   | M3 no refresh when the name changes (`didUpdateWidget`) | `home_island_flow_test`, QA step 3 |
   | M4 `Land.nitzi` wired into `_openableLands()` | QA step 3 only ("never offers"); harmless by design (point 7) |
   | M5 `onOpenHome` not passed | `home_island_flow_test`, `home_map_test`, QA step 3 |
   | M6 the bubble takes the raw profile name | `home_island_flow_test`, `home_sign_test`, QA step 3 |

## Notes (no defect, no blocker)

- **hebrew-text-editor (question):** with no usable name the bubble says only `מַה בַּבַּקְבּוּק?`. It is built in code
  from `homeBubble` (`replaceFirst('{child}, ', '')`), so it never appears as its own row in the review tables. Is the
  bare question right as the map's only line for a child with no name, and should it be its own `he.dart` entry?
- **design-director (step 4):** the placeholder title is fixed at 24 and wraps; a 24 x ש name breaks inside the word
  over two lines (SE at 1.3, and the phone at 1.3). `nitzi-home.md` §3 says the title shrinks to 18 before wrapping:
  for the real home screen. And on the phone at 1.3 a long name gives a one-line bubble across most of the board
  (611.6 of 852; rendered and looked at by QA, not kept as a golden): the "open sea" width (624) is the
  developer's; the design-director may want a tighter phone limit.
- QA-19 (open, older): the picker's child cards overflow 2.4 pt at 1.3 on the SE and both tablets; the phone pill too.

## Not checked

The real phone and tablet, sound, a child's hands, iOS; sync over the network (the family path is simulated as in the
developer's test); `deno task check` (nothing under `supabase/`).
