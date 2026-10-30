// B-26 steps 3 and 4: in the real app the home island's sign is named after the playing child and opens the child's home;
// the name is worked out again when it changes. In the home the bottle opens today's adventure, the book the stickers and
// the lighthouse the Trophy Hall, each coming back to the home; the friend waves when the child arrives and when touched.
// Goldens of the home on four boards.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/app/state.dart';
import 'package:nitznutz/characters/character.dart';
import 'package:nitznutz/characters/character_view.dart';
import 'package:nitznutz/child/home_island_name.dart';
import 'package:nitznutz/child/home_island_screen.dart';
import 'package:nitznutz/child/home_screen.dart';
import 'package:nitznutz/child/land_screen.dart';
import 'package:nitznutz/child/profile_picker.dart';
import 'package:nitznutz/child/sticker_island.dart';
import 'package:nitznutz/child/trophy_hall.dart';
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/design/board.dart';
import 'package:nitznutz/play/lesson_screen.dart';
import 'package:nitznutz/rewards/sticker_design.dart';
import 'package:nitznutz/strings/he.dart';

import 'support/app_harness.dart';
import 'support/golden_comparator.dart';
import 'support/harness.dart';

Future<AppRig> home(WidgetTester tester, {String name = 'נועה', Size size = const Size(852, 393)}) async {
  final AppRig rig = AppRig();
  await rig.seedFinishedSetup(name: name);
  await rig.pump(tester, size: size);
  await tester.tap(find.text(name));
  await tester.pumpAndSettle();
  expect(find.byType(HomeScreen), findsOneWidget);
  return rig;
}

String signText(WidgetTester tester) => tester
    .widget<Text>(find.descendant(of: find.byKey(const Key('sign-nitzi')), matching: find.byType(Text)))
    .data!;

String bubbleText(WidgetTester tester) => tester
    .widget<Text>(find.descendant(of: find.byKey(const Key('bubble-body')), matching: find.byType(Text)))
    .data!;

/// Opens the child's home from Today's Adventure and lets the friend's arrival wave end.
Future<void> openHome(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('home-pill')));
  await tester.pumpAndSettle();
  expect(find.byType(HomeIslandScreen), findsOneWidget);
}

/// The pose of the friend at the home's door.
CharacterState friendPose(WidgetTester tester) => tester
    .widget<CharacterView>(
      find.descendant(
        of: find.byKey(const Key('home-island-companion')),
        matching: find.byType(CharacterView),
      ),
    )
    .state;

/// The lesson a [LessonScreen] on top plays, then back out of it with its home button.
Future<String> lessonOnTopThenLeave(WidgetTester tester) async {
  await tester.pumpAndSettle();
  final String id = tester.widget<LessonScreen>(find.byType(LessonScreen)).lessonId;
  await tester.tap(find.byKey(const Key('activity-home')));
  await tester.pumpAndSettle();
  expect(find.byType(LessonScreen), findsNothing);
  return id;
}

void main() {
  setUpAll(() async {
    await loadAppFonts();
    useTolerantGoldens(0.03);
  });

  testWidgets(
    'the sign carries the child\'s name; tapping it opens the home with the title, and back is the map',
    (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await home(tester);
      final HomeIslandName island = homeIslandName('נועה');
      expect(signText(tester), island.sign);
      await tester.tap(find.byKey(const Key('sign-nitzi')));
      await tester.pumpAndSettle();
      expect(find.byType(HomeIslandScreen), findsOneWidget);
      expect(find.byType(LandScreen), findsNothing);
      expect(find.text(island.title), findsOneWidget);
      expect(
        tester.getSemantics(find.byKey(const Key('home-island-title'))),
        matchesSemantics(label: island.semantics, isHeader: true),
      );
      expect(
        tester.getSemantics(find.byKey(const Key('home-island-back'))),
        isSemantics(label: He.landBackSemantics.text, isButton: true, hasTapAction: true),
      );
      await tester.tap(find.byKey(const Key('home-island-back')));
      await tester.pumpAndSettle();
      expect(find.byType(HomeIslandScreen), findsNothing);
      expect(find.byType(HomeScreen), findsOneWidget);
      semantics.dispose();
    },
  );

  testWidgets('Today\'s Adventure opens the same home', (WidgetTester tester) async {
    await home(tester);
    await tester.tap(find.byKey(const Key('home-pill')));
    await tester.pumpAndSettle();
    expect(find.byType(HomeIslandScreen), findsOneWidget);
  });

  testWidgets('the bubble uses the cleaned name, and a long title shows without an overflow', (
    WidgetTester tester,
  ) async {
    // As a parent might type it: spaces around, a direction mark inside, 30 letters in three parts (over the title's 24).
    final String typed = '  אבגדהוזחטי אבגדהוזחטי ${String.fromCharCode(0x200F)}אבגדהוזח ';
    await home(tester, name: typed.trim());
    final HomeIslandName island = homeIslandName(typed);
    // The line is 30 letters: on a phone the bubble (210 wide, B-34) shortens the name by the sign's rule.
    final String bubble = bubbleText(tester);
    expect(bubble, startsWith('\u2068'), reason: 'the name in an isolate');
    final String shown = bubble.split('\u2069').first.substring(1);
    expect(
      island.name,
      startsWith(shown.replaceAll('…', '')),
      reason: 'cleaned: no mark, no outer space: $bubble',
    );
    await tester.tap(find.byKey(const Key('home-pill')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text(island.title), findsOneWidget);
  });

  testWidgets('a name changed by the family is shown at once, on the sign and in the bubble', (
    WidgetTester tester,
  ) async {
    final AppRig rig = await home(tester);
    await rig.db.upsertProfileFromFamily(
      ProfilesCompanion.insert(
        id: 'p-1',
        name: 'דן',
        avatar: 'avatar-noa',
        addressForm: 'm',
        ageBand: 1,
        createdAt: DateTime.utc(2026, 10, 26),
      ),
      isNew: false,
    );
    ProviderScope.containerOf(tester.element(find.byType(HomeScreen))).invalidate(appStateProvider);
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(signText(tester), homeIslandName('דן').sign);
    expect(bubbleText(tester), He.homeBubble.fill(<String, String>{'child': isolatedName('דן')}));
  });

  group('the home\'s doors (step 4)', () {
    testWidgets(
      'the book opens the stickers and the lighthouse the Hall; each comes back to the home, then the map',
      (WidgetTester tester) async {
        await home(tester);
        await openHome(tester);
        await tester.tap(find.byKey(const Key('home-island-book')));
        await tester.pumpAndSettle();
        expect(find.byType(StickerIsland), findsOneWidget);
        await tester.tap(find.byKey(const Key('stickers-back')));
        await tester.pumpAndSettle();
        expect(find.byType(HomeIslandScreen), findsOneWidget);

        await tester.tap(find.byKey(const Key('home-island-lighthouse')));
        await tester.pumpAndSettle();
        expect(find.byType(TrophyHall), findsOneWidget);
        await tester.tap(find.byKey(const Key('hall-back')));
        await tester.pumpAndSettle();
        expect(find.byType(HomeIslandScreen), findsOneWidget);

        await tester.tap(find.byKey(const Key('home-island-back')));
        await tester.pumpAndSettle();
        expect(find.byType(HomeIslandScreen), findsNothing);
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'the bottle opens the lesson the map\'s own way into Counting Hills opens, and comes back to the home',
      (WidgetTester tester) async {
        await home(tester);
        // The map's way: the Counting Hills island, then its play button.
        await openCountingLesson(tester);
        final String fromMap = await lessonOnTopThenLeave(tester);
        expect(
          find.byType(LandScreen),
          findsNothing,
          reason: 'a lesson from the island ends back on the map',
        );
        // The bottle in the home: the same lesson, and the child is back in the home after it.
        await openHome(tester);
        await tester.tap(find.byKey(const Key('home-island-bottle')));
        final String fromBottle = await lessonOnTopThenLeave(tester);
        expect(fromBottle, fromMap);
        expect(find.byType(HomeIslandScreen), findsOneWidget);
      },
    );

    testWidgets(
      'the friend waves when the child arrives, silently, and again when touched, saying hello in the bubble',
      (WidgetTester tester) async {
        final AppRig rig = await home(tester);
        final int heard = rig.player.played.length;
        await tester.tap(find.byKey(const Key('home-pill')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        expect(friendPose(tester), CharacterState.wave, reason: 'it waves as the home opens');
        await tester.pumpAndSettle();
        expect(friendPose(tester), CharacterState.idle, reason: 'one wave, then it rests');
        expect(
          find.descendant(
            of: find.byKey(const Key('home-island-bubble')),
            matching: find.text(He.nitziHomeWelcome.fill(<String, String>{'child': isolatedName('נועה')})),
          ),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const Key('home-island-companion')));
        await tester.pump();
        expect(friendPose(tester), CharacterState.wave);
        expect(
          find.descendant(
            of: find.byKey(const Key('home-island-bubble')),
            matching: find.text(He.nitziHomeHi.text),
          ),
          findsOneWidget,
        );
        await tester.pumpAndSettle();
        expect(friendPose(tester), CharacterState.idle);
        expect(
          rig.player.played.length,
          heard,
          reason: 'nothing is voiced in the home yet (B-26 decision 6)',
        );
      },
    );

    testWidgets(
      'the map has no sticker or Hall pebble any more, and never offers the home island as a land',
      (WidgetTester tester) async {
        await home(tester);
        expect(find.byKey(const Key('home-stickers')), findsNothing);
        expect(find.byKey(const Key('home-hall')), findsNothing);
        expect(find.text(He.homeStickersLabel.text), findsNothing);
        expect(find.text(He.homeHallLabel.text), findsNothing);
        final HomeScreen map = tester.widget<HomeScreen>(find.byType(HomeScreen));
        expect(map.openableLands.contains(Land.nitzi), isFalse);
        expect(map.onOpenHome, isNotNull);
      },
    );

    testWidgets(
      'something waits in the Hall: the map sign glows with a trophy and says so, the lantern shows it',
      (WidgetTester tester) async {
        final SemanticsHandle semantics = tester.ensureSemantics();
        final AppRig rig = AppRig();
        await rig.seedFinishedSetup();
        // Ceremonies off: a new trophy waits quietly in the Hall (M8, F3).
        await rig.db.putSetting('ceremonies', 'off');
        await rig.db.addReward(
          RewardsCompanion.insert(
            profileId: 'p-1',
            awardKey: 'trophy:counting:silver',
            kind: 'trophy',
            at: DateTime.utc(2026, 10, 27),
          ),
        );
        await rig.pump(tester);
        await tester.tap(find.text('נועה'));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('home-sign-trophy')), findsOneWidget);
        expect(find.byKey(const Key('home-sign-glow')), findsOneWidget);
        expect(
          tester.getSemantics(find.byKey(const Key('land-tap-nitzi'))),
          matchesSemantics(
            label: '${homeIslandName('נועה').semantics}, ${He.trophyNewSemantics.text}',
            isButton: true,
            hasTapAction: true,
          ),
        );
        await openHome(tester);
        expect(find.byKey(const Key('home-island-lantern-trophy')), findsOneWidget);
        expect(
          tester.getSemantics(find.byKey(const Key('home-island-lighthouse'))),
          isSemantics(label: '${He.hallSemantics.text}, ${He.trophyNewSemantics.text}'),
        );
        semantics.dispose();
      },
    );

    testWidgets('the book wears the child\'s latest sticker', (WidgetTester tester) async {
      final AppRig rig = AppRig();
      await rig.seedFinishedSetup();
      for (final int n in <int>[1, 2]) {
        await rig.db.addReward(
          RewardsCompanion.insert(
            profileId: 'p-1',
            awardKey: 'sticker:butterflies:$n',
            kind: 'sticker',
            at: DateTime.utc(2026, 10, 27, n),
          ),
        );
      }
      await rig.pump(tester);
      await tester.tap(find.text('נועה'));
      await tester.pumpAndSettle();
      await openHome(tester);
      final String latest = stickerAsset('sticker:butterflies:2');
      expect(latest, isNot(stickerAsset('sticker:butterflies:1')));
      expect(
        find.descendant(
          of: find.byKey(const Key('home-island-book')),
          matching: find.byWidgetPredicate((Widget w) => w is BoardSvg && w.asset == latest),
        ),
        findsOneWidget,
      );
    });
  });

  group('goldens: the child\'s home', () {
    for (final (String n, Size s) in <(String, Size)>[
      ('phone', Size(852, 393)),
      ('phone_se', Size(667, 375)),
      ('tablet_landscape', Size(1180, 820)),
      ('tablet_portrait', Size(820, 1180)),
    ]) {
      testWidgets('$n, נֹעָה', (WidgetTester tester) async {
        await home(tester, name: 'נֹעָה', size: s);
        await openHome(tester);
        await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/home_island_$n.png'));
      });
    }

    // The widest name at text scale 1.3: the title takes two lines at 15 (SE) and 18 (portrait).
    for (final (String n, Size s) in <(String, Size)>[
      ('phone_se', Size(667, 375)),
      ('tablet_portrait', Size(820, 1180)),
    ]) {
      testWidgets('$n, 24 x ש at text scale 1.3', (WidgetTester tester) async {
        final String name = 'ש' * 24;
        final AppRig rig = AppRig();
        await rig.seedFinishedSetup(name: name);
        await rig.pump(tester, size: s);
        // Chosen through the state, so the picker's own large-text overflow (QA-19, open) stays out of this picture.
        final ProviderContainer c = ProviderScope.containerOf(tester.element(find.byType(ProfilePicker)));
        c
            .read(activeProfileProvider.notifier)
            .choose((await c.read(appStateProvider.future)).profiles.single);
        await tester.pumpAndSettle();
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await tester.pumpAndSettle();
        await openHome(tester);
        expect(tester.takeException(), isNull);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/home_island_long_name_1.3_$n.png'),
        );
      });
    }
  });
}
