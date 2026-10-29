# B-26: the child's home island, developer's assessment (read-only)

Author: app-developer, 2026-10-29, worktree `b26-nitzi-home` from main 48d7df0. No code was changed. Line numbers are
of that commit. Measurements marked "estimate" were not rendered; the design-director measures them.

## 1. What exists today

| Thing | File (lines) | How it is reached today | State it needs |
|---|---|---|---|
| Home map | `app/lib/child/home_screen.dart` | `MaterialApp.home` → `_Root` → `_Home._map` (`app/lib/app/app.dart` 103-141, 343-359) | `HomeScreen` is stateless; `_Home` passes callbacks and `openableLands`, `stars`, `hallGlow` |
| Nitzi sign | `home_screen.dart` 165, 210, 252, 295 (`_Sign(Land.nitzi, ...)`), `_sign` 637-650, `_LandSign` 721-750 | not tappable: `_tapFor` 381-385 returns null because Nitzi is not in `openableLands` | label = `homeLabel` (`Str`, default `He.landNitzi`, 337-341), used by `_labelOf` 600 |
| `_openableLands()` | `app.dart` 336-341 | counting + every `TrophyLand` key of `worldProvider` | `worldProvider(childId)` |
| Land screen + revisit mission | `app/lib/child/land_screen.dart` 23-246 | sign/tap area → `_openLand` (`app.dart` 227-253) → `LandScreen(onPlay, onMission)`; a bell object calls `onMission(view.missionFor(skill))` (land_screen 90-99; `WorldView.missionFor`, `world_providers.dart` 31-41) → `_openLesson(mission:)` (`app.dart` 292-320) | `worldProvider`, `rewardsProvider`, `contentProvider` |
| Trophy Hall (trophies, medals, decorations, prizes) | `app/lib/child/trophy_hall.dart` 33-133 (`HallTab` 28) | map pebble `home-hall` (`home_screen.dart` 445-469) → `_openHall` (`app.dart` 215-219), refreshes the world on return | `rewardsProvider`, `worldProvider`, `ribbonsProvider`, `outfitProvider`, `characterForRoleProvider` |
| Medals and ceremonies | medals tab `trophy_hall.dart` 503-598; ceremony `ceremony_screen.dart` | ceremony after a lesson/mission or on map open (`_lookAtRewards`, `_maybeCeremony`, `app.dart` 181-213); replay from the Hall (61-63) | `nextCeremonyFor(db, id)`, `hallWaitingProvider` (`reward_providers.dart` 52-60) drives the glow |
| Sticker page | `app/lib/child/sticker_island.dart` 15-130 | map pebble `home-stickers` (`home_screen.dart` 425-444) → `_openStickers` (`app.dart` 255-256) | `stickersProvider` (`reward_providers.dart` 63-67) |
| Golden stars count | `home_screen.dart` 470-494 | display only | `goldenStarsProvider` (34-41) |
| Today's Adventure pill | `_DailyPill`, `home_screen.dart` 653-719, placed by `_pill` 619-635 | **nothing**: it has `Semantics(button: true)` (659-661) but no `onTap`, so a screen reader announces a button that does nothing. It overflows at text scale 1.3 (QA-19, open; `qa_b23_b24_screens_test.dart` 235) | none; the 3 dots are fixed (699-709) |
| Daily bottle | not built. PLAN.md 365 (three stops: revisit, new, apply-it), 352; M9.md 140 lists it as out of M9 | the bubble already says "{child}, the bottle arrived" (`He.homeBubble`, he.dart 46; shown at home_screen 588-595) although no bottle exists | — |
| "Next lesson" | `nextLessonId` (`app/lib/world/next_lesson.dart` 6-28); `_nextLesson`, `_playLand` (`app.dart` 260-289) | only via a land's play pebble | content + attempts + sticker rewards |
| Session builder | `app/lib/engine/session_builder.dart` 67 | used only by the simulator (`engine/simulator.dart` 302, 435), not the app | — |
| Companion on the map | `MapCompanion` (`child/companion_views.dart` 51-104), world layer `home_screen.dart` 561-587 | tap → `greet()` (`vo:core.greeting.hello`); "+" → Friends' Beach | `characterForRoleProvider(mapCompanion)` (the chosen friend, Nitzi by default), `guideProvider`, `outfitProvider`, `voiceDirectorProvider` |
| Book | `home_screen.dart` 506-515 | `onPressed: () {}`, does nothing (Sky Journal not built) | — |

## 2. The child's name

- **Model and column:** `Profiles.name`, `text().withLength(min: 1, max: 40)` (`app/lib/data/tables.dart` 8), local
  encrypted DB, schema version 9 (`app_database.dart` 26). Comment (3-4) calls it "the parent-reviewed spelling": it is
  just what the parent typed.
- **Entry:** `ChildFormScreen` (`app/lib/parent/child_form.dart` 39, 48, 96): trimmed, 1-40 characters, any characters
  (no nikud rule, no bidi rule). No edit path exists (only `addProfile`, `app_database.dart` 87, and sync upsert).
- **Empty?** Not by the form or the column. A synced name can be a single space (server pattern below allows it), so the
  function must still treat blank-after-trim as "no name".
- **A separate reviewed (vocalised) spelling does not exist** anywhere (no column, no field, no sync field). PLAN.md 841
  and 1266 promise it for voicing. So in B-26 `reviewedSpelling` is always null.
- **Provider:** no name provider; `_Root` picks `current` from `appStateProvider.profiles` (`app.dart` 119-137) and `_Home`
  reads `widget.profile.name` (344). A name synced in from the family shows after `appStateProvider` reloads.
- **Sync (our backend, not a vendor):** parent devices push it as `nickname` in `child-put` (`sync/sync_engine.dart`
  216-239); server `app.child_profile.nickname` 1-24 characters (`supabase/migrations/20261027120000_parent_sync.sql`
  12; `child-put/handler.ts` 10, 27: no control characters, no `<>`); returned by `sync-pull` (`handler.ts` 40) and
  written locally (`sync_engine.dart` 559-578).
- **Defect found (pre-existing):** local max 40 vs server max 24. A 25-40 character name never syncs, and the failure is
  swallowed (`sync_engine.dart` 233-235). Also `<>` are allowed locally and refused by the server. → qa-engineer.
- **Vendors today:** Anthropic: none (tutor-turn sends ids and enums; PLAN.md 711 "live lines carry no name"). ElevenLabs:
  none in code (`_shared/elevenlabs.ts`, `tool/voice_gen*.dart` hold no `{child}` path). Push: alerts carry the child id;
  the name is filled in on the device (`parent/alerts_screen.dart` 228). Logs: no log call takes a name.
- **The sign label:** computed on the device from `profile.name`, shown in a widget, never sent, synced or logged. It
  adds no new path; the name is already on the map today in the bubble (`home_screen.dart` 591). Confirmed: none.

## 3. Proposed architecture

**3.1 The label function.** New pure file `app/lib/strings/home_island_label.dart` with
`homeIslandLabel(String? name, {String? reviewedSpelling}) -> ({String sign, String title})`. It holds no Hebrew: the
source rule "every Hebrew string lives in lib/strings/he.dart" (`test/source_rules_m1_test.dart` 57-68) means the
editor's pattern goes into `he.dart` as `Str` entries with `nikud: true` and the `{child}` placeholder (the only
placeholder allowed in child strings, 104-111), for example `homeIslandSign`, `homeIslandTitle`, `homeIslandNoName`,
all `needs-editor`. The function: trim; blank → the calm fallback; else `reviewedSpelling` if set, otherwise the name as
typed (nikud stripped or kept, as the editor rules); wrap the name in Unicode isolates (U+2068 … U+2069) so a Latin
name or digits never reorder the Hebrew; fill with `Str.fill`. No truncation in the function (cutting nikud is unsafe);
width is the widget's job (3.4).

**3.2 The map.** In `HomeScreen` (`home_screen.dart`):
- `homeLabel` becomes a `String` (default `He.landNitzi.text`); `_labelOf` returns a String.
- New `final VoidCallback? onOpenHome;`. `_tapFor`: `if (land == Land.nitzi) return onOpenHome;` before the other rules.
  With it null (tests, old callers) Nitzi stays a label, so lands without skills stay labels and nothing else changes.
- The Nitzi tap area then appears by the existing loop (542-559) with the same `Semantics(button: true, label)`.
  Paint order already puts the companion and "+" above it (561-587), so they keep their taps. Most of the Nitzi tap
  area lies under the companion: the free part is about 89 wide on the phone (world x 1770-1859), 74 on the SE, 110 on
  portrait, plus the sign itself. Tapping Nitzi's house therefore greets, it does not open home (open question 4).
  Gaps to the Counting tap area: 40 phone, 32 SE, 70 landscape, 100 portrait (≥ 24).
- The pill gets `onTap: onOpenHome` (it then is the button it already claims to be).
- **`_openableLands()` does not change.** Adding Nitzi there would crash: `_openLand` does
  `TrophyLand.values.byName(land.name)` (`app.dart` 228) and `TrophyLand` has no `nitzi` (`rewards/award.dart` 7-15).

**3.3 The app.** In `_HomeState` (`app.dart`): compute the label once in `_map` from `widget.profile.name` (cheap, no
provider needed); pass `homeLabel: label.sign`, `onOpenHome: _openHome`. `_openHome` pushes a `MaterialPageRoute` to the
new screen and calls `_refreshWorld()` on return, like `_openHall`. The screen gets the **same** `_openHall`,
`_openStickers`, `_playLand` and `_openLesson(mission:)` callbacks: linked, never copied, so the ceremony, the
rest-scene check, the warm-up and the friends offer stay in one place.

**3.4 The new screen.** `app/lib/child/home_island_screen.dart`, `HomeIslandScreen` (ConsumerStatefulWidget):
`childId`, `title`, `onHall`, `onStickers`, `onAdventure` (nullable), `onBack` by `Navigator.pop`. Content: title pill,
back pebble (`home_palm.svg`, `He.landBackSemantics`, as Land/Sticker screens), a `MapCompanion` of its own (own
`GlobalKey`; it greets with the existing `vo:core.greeting.hello` when touched; an automatic greeting on open is a
voice-director decision), a Hall tile (with `hallWaitingProvider` glow), a Stickers tile (count from
`stickersProvider`), golden stars (`goldenStarsProvider`), today's adventure tile, and "who calls for help" flags: one per
land with a bell in `worldProvider`, each opening that land (linked to `_openLand`). It imports no `parent/`, `net/`,
`security/` (source rule, `source_rules_m1_test.dart` 26-31), uses no Hebrew literal and no banned word ("timer",
"streak"...; 172-184). All providers it reads are already warm from the map; nothing new is computed in `build()`.
- **Four boards:** like `LandScreen` and `StickerIsland`, a `SafeArea` + `Stack` laid out from
  `AppLayout.of(context).board`, with a small private spec per `BoardClass` (as `_HomeSpec.of`, 305-310) only for the
  numbers the design-director gives: landscape boards (phone, SE, tablet landscape) put the companion on one side and
  the tiles in a row; tablet portrait stacks them.
- **Back and scroll position:** the map stays mounted under the pushed route, so the strip offset is kept; the
  `PageStorageKey('home-map')` (404) also restores it if `_Home` rebuilds through `CalmLoading`. Test it (3.6).
- **Sign width:** `_LandSign` uses `softWrap: false` (744) inside a 400 box (645-648), so a long name overflows. Proposed:
  a per-board `homeSignMaxWidth` in `_HomeSpec` and a `FittedBox(fit: BoxFit.scaleDown)` around the label text for the
  Nitzi sign only. Room (estimate, at text scale 1.0): SE about 270 (Counting sign on the left, world edge 147 to the
  right), phone about 320, tablets wider. The design-director sets the numbers and says scale-down vs. a short form.

**3.5 Accessibility.** The Nitzi tap area: button, label = the sign text, tap action (as the other lands). The pill:
button with a tap action. On the new screen every tile is a `PebbleButton`/`Semantics(button)` with a `*Semantics`
string (no nikud, by the strings rule 95-101), the companion keeps its role, tiles ≥ 64 with ≥ 24 gaps. Text scale 1.3:
the tiles use `AppText.fixed`, which scales with the system, so labels sit in `Flexible`/`FittedBox`, not `softWrap:
false` in a fixed row (the cause of QA-19). Nothing moves by itself; reduce motion has nothing new to switch off.

**3.6 Tests.**
- Unit `test/home_island_label_test.dart`: null, empty, spaces → fallback; ordinary name; prefix-letter names from the
  editor's table; 24- and 40-character names returned whole; Latin and digits isolated; `reviewedSpelling` used when
  set; no nikud added to a name without one (the nikud rule); no `{child}` left; fixed words keep their nikud.
- Widget (map): Nitzi sign and tap area open the home screen on four boards; with `onOpenHome` null it stays a label;
  a drag from the sign pans and opens nothing; the pill opens it; back returns with the same scroll offset (pan part way,
  open, pop, compare `ScrollPosition.pixels`); companion and "+" still greet / open Friends' Beach.
- Widget (screen): each tile calls its callback; the Hall glow follows `hallWaitingProvider`; bells link to the right
  land; semantics labels and buttons; text scale 1.3 with no exception on four boards.
- Geometry (`board_geometry_test.dart`): the Nitzi sign with a 24- and a 40-character name stays inside the world, clear of
  the Counting sign and the "+", at 1.0 and 1.3; Nitzi tap area ≥ 64 wide and ≥ 24 from Counting's.
- Goldens: `home_island_{phone,phone_se,tablet_landscape,tablet_portrait}.png`, one with no name. Test names are made up
  (for example "נועה", as the current tests use); never the owner's children's names (the repository is public).
- QA-owned tests that assert "Nitzi has no way in" flip to "it opens home": `home_map_test.dart` 42-50,
  `board_geometry_test.dart` 87, `qa_b23_b24_screens_test.dart` 194-195.

## 4. Risks

- **Security paths:** none, if B-26 keeps the label on the device and today's adventure uses existing lesson paths. No
  sync, pack, gateway, log or new input path. The security-engineer's review is not required by the rules; a short look
  at the name surface is cheap if the orchestrator wants it.
- **Reviewed spelling:** adding a real field is DB version 10, a `child-put`/`sync-pull` field, a server migration with
  pgTAP and a security review. Recommend it as its own item with the voiced-name work, not in B-26.
- **New package:** none (`FittedBox`, Unicode isolates and `Str.fill` are enough).
- **Goldens:** the sign text changes on all four home goldens, including `home_tablet_landscape.png`, which B-23 said must
  stay byte-identical. QA must expect that diff (sign text only).
- **Overlap:** the companion covers most of the Nitzi tap area (3.2).
- **Name length mismatch** 40 vs 24 (section 2): a long name shows on the sign but never reaches the other devices.
- **Today's adventure:** a real three-stop bottle needs the session builder in the app and curriculum rules: far larger
  than this item (question 2).
- **Hebrew and voice:** new `he.dart` strings and maybe a greeting line; voices come only after the texts are final.

## 5. Effort and order (steps; QA checks after each)

1. Hebrew pattern in `he.dart` (editor's wording) + `homeIslandLabel` + unit tests. QA: unit tests, nikud rule.
2. `HomeScreen`: `homeLabel` as String, `onOpenHome`, `_tapFor`, pill tap, sign max width; geometry tests. QA: geometry
   on four boards, long and no name, text scale 1.3, flips its three tests.
3. `app.dart`: label from the profile, `_openHome`, refresh on return; back/scroll test. QA: app flow, scroll kept.
4. `HomeIslandScreen` per the design spec, linked callbacks, companion, bells. QA: widget tests, semantics.
5. Today's adventure as the owner decides (question 2), as a pure function in `world/` with tests. QA: rule tests.
6. Goldens on four boards (QA renders and looks), PLAN.md build detail (459 last sentence, 352 home island row, 365 if
   the bottle is simplified), analyzer, format, full `flutter test`, playthrough. QA: full verification.

About 6 steps; steps 1-3 can land before the screen design is final, behind `onOpenHome` null.

## 6. Open questions for the owner (with my recommendation)

1. **Who greets on the home island: Nitzi always, or the friend the child chose?** Recommend the chosen friend (Nitzi by
   default), as on the map, so the voice never changes between two screens.
2. **What is "today's adventure" in B-26?** Recommend a simple, untimed tile: if a land calls for help, its revisit; else
   the next lesson of the land played last (from the attempts), using the existing `_playLand`. The three-stop morning
   bottle stays a later item; the bubble "the bottle arrived" should then say something true (editor).
3. **Move or keep the stickers and Hall buttons on the map?** Recommend keep them for now (linked to the same functions,
   the Hall glow stays visible from the map) and decide after you see the home island on the phone.
4. **Should touching the island's house (under the friend) open home?** Recommend no: the friend keeps its greeting; the
   sign, the free part of the island and the pill open home.
5. **Long names:** recommend the sign scales its text down to fit, never cuts the name; the editor may give a shorter form.
6. **Name length 40 locally vs 24 on the server:** recommend 24 everywhere (the form's limit becomes 24), filed as a QA
   defect, separate from B-26.
7. **Reviewed vocalised spelling:** recommend not in B-26 (needs a schema change and sync); the sign shows the name
   without nikud until then.
