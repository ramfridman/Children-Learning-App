# QA verification: B-26 step 3b (the name in an isolate in the map bubble; the nameless bubble's own line)

2026-10-29, qa-engineer. Worktree `D:\nitznutz-b26`, branch `b26-nitzi-home`, step 3b uncommitted on top of `ef600ce`
(step 3). Texts: `docs/agents/b26-hebrew.md` section 7. Also uncommitted in the tree and **not** part of 3b: the
design-director's art in progress (`app/assets/art/scenes/home_phone_se.svg`, `tools/make_home_map.py`,
`app/assets/art/home/`, `nitzi_home_*.svg`, `tools/make_nitzi_home.py`, previews) and the curriculum-expert's docs;
not edited. No git write, no paid voice command, nothing under `.claude/` touched.

**Verdict. Step 3b may be committed.** The bubble's fit and line breaks are exactly those of step 3 (56 of 56 cases
identical), a shortened Latin name keeps its "…" on its right, the nameless bubble shows `He.homeBubbleNoName`, the
review tables differ only by the new row, and no check in QA's files was loosened. No defect. Notes below.

## What ran

| Command (in `app/` unless said) | Result |
|---|---|
| `flutter analyze` | No issues found |
| `dart format --output=none --set-exit-if-changed .` | 286 files, 0 changed (287 with QA's file) |
| `flutter test` (whole suite, as delivered) | **1797 passed, 8 skipped, 0 failed** (11 min 16 s) = 1789 (step 3) + 8 new |
| `python tools/export-hebrew-review.py`, then `python tools/hebrew_voice_review.py` (repo root) | 9,522 rows (screens 332); master text-ready 9,455, proposed 44, unchanged 23. The five tables are byte-identical to the delivered ones; against HEAD the only change is the `homeBubbleNoName` row in each file, plus the counts in the two `.md` summaries (331 to 332, 9,521 to 9,522; 2,008 to 2,009 spoken rows) |
| `flutter test test/qa_b26_step3b_test.dart` (QA's new file) | **57 passed** (4 boards x 2 scales x 7 names, plus a source check) |
| 2 mutations of `home_screen.dart` (copy, mutate, run, restore, SHA-256 checked) | below |
| renders to the QA scratchpad (not goldens): SE map start and end, Latin names on the landscape tablet (1.3) and the SE (1.3), a mixed name on the portrait tablet | looked at |
| `flutter analyze`, format, `flutter test` (whole suite with QA's file; run last) | No issues; 287 files, 0 changed; **1854 passed, 8 skipped, 0 failed** (11 min 26 s) = 1797 + 57 |

## Checks

1. **Texts.** `He.homeBubbleNoName = 'מַה בַּבַּקְבּוּק?'` (`nikud: true`, NFC) is code point for code point the line the
   code built before (`homeBubble` without `{child}, `), so a child with no name sees exactly what step 3 showed. The
   editor's §7.1 decision and the `PENDING` comment agree; voice text `מה בבקבוק?` (one clip with `homeBubble`).
2. **QA's files edited by the developer: nothing loosened.** `qa_b26_home_sign_test.dart` line 417: the expected words
   now carry the isolate (`isolatedName('נֹעָה')`), still an exact `find.text` and `bySemanticsLabel` match.
   `qa_b26_step3_test.dart`: `bubbleWithoutName` is now `He.homeBubbleNoName.text` (the same string); the named
   bubble check became stricter (the part before the comma must start with U+2068 and end with U+2069, then the prefix
   check as before); the rename test's `startsWith` now includes the isolate. Also `app_flow_test.dart` and
   `home_island_flow_test.dart`: the expected bubble strings gained the isolate, exact matches as before.
3. **The real app, 4 boards x text scale 1.0 and 1.3** (`qa_b26_step3b_test.dart`; names `Massimiliano`,
   `Massimiliano Bartholomew`, `Massimiliano Bartholomew Alessandro Wolf` (40), `אלכסנדרה`, `נועה Noa`, `Noa נועה`,
   blank):
   - exactly one isolate around the (whole or shortened) name, at the start of the line, closed before the comma;
   - a shortened Latin name has its "…" drawn on the right of its last letter (glyph boxes: `Massimiliano…,` and
     `Massimili…,` on the tablets, `Massimiliano Bartholomew…,` on the SE at 1.3); for a Hebrew end it would be on the
     left (no Hebrew name was shortened in these cases);
   - phones one line, tablets at most two and 210 wide; the nameless bubble is `He.homeBubbleNoName` on all 4 boards
     (phone 116.3 / 144.0 wide, SE 111.2 / 137.3, tablets 155.1 / 192.0 at 1.0 / 1.3, one line);
   - **fit and breaks unchanged against step 3:** the same 56 cases run with the isolate taken out of the bubble (the
     step-3 behaviour) give the same text (without the marks), width, line count and left edge in all 56;
   - mixed names follow the first strong letter: `Noa נועה` reads `Noa נועה` left to right with the comma on its left
     (glyph boxes: `,` 39, `N` 44, `נ` 130), on the sign and in the bubble; `נועה Noa` stays right to left.
4. **What a screen reader gets.** The sign and its tap area: the plain whole name (`island.semantics`), no format or
   control character, on all 56 cases. The bubble is a plain `Text` under `IgnorePointer`, so its own label is its
   text: since 3b it contains U+2068 and U+2069 around the name (and, as before on tablets, a line break; a shortened
   name, e.g. `Massimili…`). Isolates are format characters that TalkBack and VoiceOver normally skip; not checked on a
   device. A note for the app-developer below.
5. **Mutations:**

   | Mutation | Caught by |
   |---|---|
   | Ma: the isolate taken out of the bubble (`named(n) => {'child': n}`) | `home_sign_test`, `home_island_flow_test`, `app_flow_test`, `qa_b26_home_sign_test`, `qa_b26_step3_test`, QA step 3b (48 of 57) |
   | Mb: the old derived nameless line (`homeBubble.text.replaceFirst('{child}, ', '')`) | QA step 3b's source check only. Every other test passes, because today both give the same words (an equivalent mutant by output); the developer's guard that `homeBubble` contains `{child}, ` protects the break, not this |

6. **The other work in the tree (asked: did it change a golden or a test result?).** No golden file changed (`git
   status` lists none) and no test result changed (the whole suite passes). But the design-director's
   `home_phone_se.svg` moves the sparkle from (413.5, 112.5) to (280, 112.5): a fresh render of the SE map's start view
   differs from the committed `home_phone_se.png` in 113 pixels (the new spot at 273..286 x 106..118 and the old one at
   408..418 x 105..111), which the 3 % tolerance passes; the end view (`home_phone_se_end.png`) is unchanged. The SE
   sign goldens (`home_sign_*_phone_se.png`) draw the same scene, so they will differ the same way (not measured). So the SE goldens are a little
   stale until the art lands; regenerate them by name then (QA-28: the tolerance hides such changes). The curriculum
   docs touch no test.

## Notes (no defect, no blocker)

- **app-developer (optional):** give the map bubble a plain `Semantics` label (the line without U+2068/U+2069 and
  without the tablet line break), as the sign already has, so no screen reader can stumble on the marks. Not seen to
  matter; not checked on a device.
- **design-director (the art in progress):** with a long name at text scale 1.3 the SE bubble reaches x 80, and the
  moved sparkle at (280, 112.5) is again half under its top edge (render `s3b_se_latin40_13.png` in QA's scratchpad).
  Typical names leave it in open sea (`נועה` at 1.0: the bubble starts at x 362).

## Not checked

The real phone and tablet, a screen reader on a device, sound, a child's hands, iOS; `deno task check` (nothing under
`supabase/`).
