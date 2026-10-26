import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/characters/character.dart';
import 'package:nitznutz/characters/character_source.dart';
import 'package:nitznutz/child/friends_beach.dart';
import 'package:nitznutz/child/home_screen.dart';
import 'package:nitznutz/play/activity_frame.dart';
import 'package:nitznutz/strings/he.dart';

import 'support/app_harness.dart';
import 'support/companion_fixtures.dart';
import 'support/golden_comparator.dart';
import 'support/harness.dart';

const Size phone = Size(852, 393);
const Size tabletL = Size(1180, 820);
const Size tabletP = Size(820, 1180);

/// Lets stage timers and the pauses between moves run, in steps, so that animations get frames.
Future<void> wait(WidgetTester t, [int ms = 2000]) async {
  for (int spent = 0; spent < ms; spent += 100) {
    await t.pump(const Duration(milliseconds: 100));
  }
  await t.pump(const Duration(milliseconds: 50));
}

Future<void> tapKey(WidgetTester t, String key) async {
  await t.tap(find.byKey(Key(key)), warnIfMissed: false);
  await t.pump(const Duration(milliseconds: 60));
}

Future<void> count(WidgetTester t, Iterable<int> indexes) async {
  for (final int i in indexes) {
    await tapKey(t, 'butterfly-$i');
    await wait(t, 700);
  }
}

/// The picture a character view shows inside [of]: its PNG bytes, or null when it draws a vector picture.
Uint8List? pngIn(WidgetTester t, Finder of) {
  final Finder image = find.descendant(of: of, matching: find.byType(Image));
  if (image.evaluate().isEmpty) return null;
  return ((t.widget<Image>(image.first)).image as MemoryImage).bytes;
}

bool vectorIn(Finder of) => find.descendant(of: of, matching: find.byType(SvgPicture)).evaluate().isNotEmpty;

List<String> heard(AppRig rig) => rig.player.played.map(String.fromCharCodes).toList();

void main() {
  late FixedCharacterSource two;
  late Character hero;

  setUpAll(() async {
    await loadAppFonts();
    useTolerantGoldens(0.03);
    two = await makeSource(friends: <String>['hero-son']);
    hero = two.characters.firstWhere((Character c) => c.id == 'hero-son');
  });

  Future<AppRig> start(
    WidgetTester tester, {
    String? companion,
    Size size = phone,
    CharacterSource? source,
  }) async {
    final AppRig rig = AppRig(characters: source ?? two);
    await rig.seedFinishedSetup();
    if (companion != null) await rig.db.setCompanion('p-1', companion);
    await rig.pump(tester, size: size);
    await tester.tap(find.text('נועה'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    return rig;
  }

  Future<void> openLesson(WidgetTester tester) async {
    await tester.tap(find.text(He.landCounting.text));
    await tester.pumpAndSettle();
    expect(find.byType(ActivityFrame), findsOneWidget);
  }

  final Finder onMap = find.byKey(const Key('home-companion'));
  final Finder guide = find.byKey(const Key('activity-nitzi'));

  group('who is on the screen', () {
    testWidgets('Nitzi is the companion until the child chooses another', (WidgetTester tester) async {
      await start(tester);
      expect(vectorIn(onMap), isTrue);
      expect(pngIn(tester, onMap), isNull);
    });

    testWidgets('a chosen companion stands on the map, in the same place Nitzi stood', (
      WidgetTester tester,
    ) async {
      await start(tester, companion: 'hero-son');
      expect(pngIn(tester, onMap), hero.images['idle']!.png);
      expect(tester.getRect(onMap).left, closeTo(609, 0.6));
      expect(tester.getRect(onMap).top, closeTo(154, 0.6));
      expect(tester.getRect(onMap).width, closeTo(153.6, 0.6));
    });

    testWidgets('a companion whose pack is gone quietly gives way to Nitzi, in picture and in voice', (
      WidgetTester tester,
    ) async {
      final AppRig rig = await start(tester, companion: 'hero-son', source: await makeSource());
      expect(vectorIn(onMap), isTrue);
      await openLesson(tester);
      await wait(tester, 300);
      expect(heard(rig).first, 'mp3:nitzi:pick.red.flower.prompt');
    });
  });

  group('Friends Beach', () {
    testWidgets('lists the characters, saves the choice at once, and the friend greets in its own voice', (
      WidgetTester tester,
    ) async {
      final AppRig rig = await start(tester);
      await tester.tap(find.byKey(const Key('home-friends')));
      await tester.pumpAndSettle();
      expect(find.byType(FriendsBeach), findsOneWidget);
      expect(find.byKey(const Key('friend-nitzi')), findsOneWidget);
      expect(find.byKey(const Key('friend-hero-son')), findsOneWidget);

      await tester.tap(find.byKey(const Key('friend-hero-son')));
      await wait(tester, 300);
      expect(await rig.db.companionOf('p-1'), 'hero-son');
      expect(heard(rig).last, 'mp3:hero-son:core.greeting.hello');
      await wait(tester, 2000);

      await tester.tap(find.byKey(const Key('friends-home')));
      await tester.pumpAndSettle();
      expect(pngIn(tester, onMap), hero.images['idle']!.png);

      // And back to Nitzi.
      await tester.tap(find.byKey(const Key('home-friends')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('friend-nitzi')));
      await wait(tester, 2300);
      expect(await rig.db.companionOf('p-1'), 'nitzi');
      await tester.tap(find.byKey(const Key('friends-home')));
      await tester.pumpAndSettle();
      expect(vectorIn(onMap), isTrue);
    });

    for (final (String, Size) s in <(String, Size)>[
      ('tablet landscape', tabletL),
      ('tablet portrait', tabletP),
    ]) {
      testWidgets('fits a ${s.$1} with every friend in reach', (WidgetTester tester) async {
        await start(tester, size: s.$2);
        await tester.tap(find.byKey(const Key('home-friends')));
        await tester.pumpAndSettle();
        expect(tester.getRect(find.byKey(const Key('friend-hero-son'))).width, greaterThan(150));
        expect(find.byKey(const Key('friend-nitzi')).hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('a touch on the companion of the map greets, in its voice, with a wave', (
      WidgetTester tester,
    ) async {
      final AppRig rig = await start(tester, companion: 'hero-son');
      await tester.tap(onMap);
      await wait(tester, 300);
      expect(heard(rig), <String>['mp3:hero-son:core.greeting.hello']);
      await wait(tester, 2000);
    });
  });

  group('the lesson', () {
    testWidgets(
      'the guide is the companion, speaks every line in its voice, and its mouth follows the sound',
      (WidgetTester tester) async {
        final AppRig rig = await start(tester, companion: 'hero-son');
        await openLesson(tester);
        await wait(tester, 300);
        expect(pngIn(tester, guide), isNotNull);
        expect(heard(rig).single, 'mp3:hero-son:pick.red.flower.prompt');
        // The cues of the test voice: closed, open from 100 ms, closed from 200 ms.
        rig.player.at = const Duration(milliseconds: 150);
        for (int i = 0; i < 4; i++) {
          await tester.pump(const Duration(milliseconds: 40));
        }
        expect(pngIn(tester, guide), hero.images['talk_open']!.png);
        rig.player.at = const Duration(milliseconds: 260);
        for (int i = 0; i < 4; i++) {
          await tester.pump(const Duration(milliseconds: 80));
        }
        expect(pngIn(tester, guide), hero.images['talk_closed']!.png);
        rig.player.finish();
        await wait(tester, 400);
        expect(pngIn(tester, guide), hero.images['idle']!.png);
      },
    );

    testWidgets(
      'touching the guide asks the question again in the same voice, and a mistake meets a kind pose',
      (WidgetTester tester) async {
        final AppRig rig = await start(tester, companion: 'hero-son');
        await openLesson(tester);
        await wait(tester, 300);
        await tester.tap(find.byKey(const Key('lesson-replay')));
        await wait(tester, 300);
        expect(heard(rig), <String>[
          'mp3:hero-son:pick.red.flower.prompt',
          'mp3:hero-son:pick.red.flower.prompt',
        ]);
        rig.player.finish();
        await tapKey(tester, 'option-o2'); // the yellow flower: not yet
        await wait(tester, 300);
        expect(heard(rig).last, 'mp3:hero-son:fb.almost');
        rig.player.finish();
        await wait(tester, 400);
        expect(pngIn(tester, guide), hero.images['encourage']!.png);
      },
    );

    testWidgets('Nitzi speaks with her own voice when she is the companion', (WidgetTester tester) async {
      final AppRig rig = await start(tester);
      await openLesson(tester);
      await wait(tester, 300);
      expect(heard(rig).single, 'mp3:nitzi:pick.red.flower.prompt');
      expect(vectorIn(guide), isTrue);
    });

    testWidgets('leaving the lesson silences the guide', (WidgetTester tester) async {
      final AppRig rig = await start(tester, companion: 'hero-son');
      await openLesson(tester);
      await wait(tester, 300);
      final int stops = rig.player.stops;
      await tester.tap(find.byKey(const Key('activity-home')));
      await tester.pumpAndSettle();
      expect(rig.player.stops, greaterThan(stops));
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('the companion celebrates with the child at the end, saying the praise in its voice', (
      WidgetTester tester,
    ) async {
      final AppRig rig = await start(tester, companion: 'hero-son');
      await openLesson(tester);
      await tapKey(tester, 'option-o1');
      await wait(tester);
      await count(tester, <int>[0, 1, 2]);
      await tapKey(tester, 'tile-o2');
      await wait(tester);
      await count(tester, <int>[0, 1, 2, 3]);
      await tapKey(tester, 'tile-o2');
      await wait(tester);
      await count(tester, <int>[0, 1, 2, 3, 4]);
      await tapKey(tester, 'tile-o2');
      await wait(tester);
      final Finder flower = find.byKey(const Key('give-flower'));
      for (int i = 0; i < 4; i++) {
        await tapKey(tester, 'give-butterfly-$i');
        await tester.tapAt(tester.getCenter(flower));
        await wait(tester, 400);
      }
      await tapKey(tester, 'give-done');
      await wait(tester);
      final Finder cameo = find.byKey(const Key('lesson-cameo'));
      expect(cameo, findsOneWidget);
      expect(heard(rig).last, 'mp3:hero-son:celebrate.butterflies');
      rig.player.finish();
      await wait(tester, 400);
      expect(pngIn(tester, cameo), hero.images['celebrate']!.png);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/companion_celebration_phone.png'),
      );
      // The first finished lesson leads to Friends Beach, once.
      await tester.tap(find.byKey(const Key('lesson-done')));
      await tester.pumpAndSettle();
      expect(find.byType(FriendsBeach), findsOneWidget);
    });
  });

  group('pictures with a family character', () {
    testWidgets('the map', (WidgetTester tester) async {
      await start(tester, companion: 'hero-son');
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/companion_home_hero_phone.png'));
    });

    testWidgets('the lesson', (WidgetTester tester) async {
      await start(tester, companion: 'hero-son');
      await openLesson(tester);
      await wait(tester, 300);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/companion_lesson_hero_phone.png'),
      );
    });

    testWidgets('Friends Beach', (WidgetTester tester) async {
      await start(tester);
      await tester.tap(find.byKey(const Key('home-friends')));
      await tester.pumpAndSettle();
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/companion_friends_phone.png'));
    });
  });
}
