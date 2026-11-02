// B-45: a touch on a picture of a land map, or on the line of an earned star in the Trophy Hall, makes the narrator say the
// skill's own line (vo:core.skill.<id>). A second touch or leaving the screen stops it, two lines never overlap, and a line
// with no recording is silence (the caption is on screen anyway), never an error.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/app/companion.dart';
import 'package:nitznutz/app/reward_providers.dart';
import 'package:nitznutz/app/ribbon_providers.dart';
import 'package:nitznutz/app/world_providers.dart';
import 'package:nitznutz/child/land_screen.dart';
import 'package:nitznutz/child/trophy_hall.dart';
import 'package:nitznutz/content/pack_verify.dart';
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/design/layout.dart';
import 'package:nitznutz/design/theme.dart';
import 'package:nitznutz/design/token_types.dart';
import 'package:nitznutz/rewards/award.dart';
import 'package:nitznutz/voice/voice_bank.dart';
import 'package:nitznutz/voice/voice_director.dart';
import 'package:nitznutz/world/world_state.dart';

import '../tool/pack_builder_lib.dart';
import 'engine/fixtures.dart';
import 'support/harness.dart';
import 'support/pack_fixtures.dart';
import 'support/voice_fixtures.dart';

const String child = 'p-1';

/// Three skills of the Colours island with a line (the first two recorded, the third not) and one with no line.
const String recorded = 'COL-A-01';
const String alsoRecorded = 'COL-A-02';
const String unrecorded = 'COL-A-03';
const String noLine = 'COL-A-04';

String lineOf(String id) => 'line of $id';

WorldObject object(String id, GrowthStage stage, {bool withLine = true}) => WorldObject(
  skillId: id,
  title: 'skill $id',
  objectId: 'stair',
  stage: stage,
  bell: false,
  line: withLine ? lineOf(id) : null,
);

List<int> soundOf(String id) =>
    utf8.encode('mp3:hero-son:core.skill.${id.toLowerCase().replaceAll('-', '_')}');

Reward reward(int id, String key, String kind) => Reward(
  id: id,
  profileId: child,
  awardKey: key,
  kind: kind,
  at: day0,
  seenAt: day0,
  eventId: null,
  syncedAt: null,
);

class Rig {
  Rig(this.player, this.director, this.overrides);

  final FakePlayer player;
  final VoiceDirector director;
  final List<Override> overrides;
}

Future<VoiceBank> bankOf(List<String> skills) async {
  final PackKey key = await newTestKey();
  return VoiceBank.fromPack(
    await verifyPack(
      (await buildVoicePack(key, 'hero-son', <String, List<(int, int)>>{
        for (final String s in skills)
          'core.skill.${s.toLowerCase().replaceAll('-', '_')}': <(int, int)>[(0, 1)],
      })).bytes,
      publicKey: key.publicKey,
    ),
  );
}

Future<Rig> rig(
  VoiceBank bank,
  Map<TrophyLand, List<WorldObject>> lands, {
  List<Reward> rewards = const <Reward>[],
}) async {
  final FakePlayer player = FakePlayer();
  final VoiceDirector director = VoiceDirector(player: player)..useBank(bank);
  addTearDown(director.dispose);
  return Rig(player, director, <Override>[
    voiceDirectorProvider.overrideWithValue(director),
    rewardsProvider(child).overrideWith((Ref ref) async => rewards),
    ribbonsProvider(child).overrideWith((Ref ref) async => const <String, String>{}),
    worldProvider(
      child,
    ).overrideWith((Ref ref) async => WorldView(engine: engineOf(smallCatalog()), now: day0, lands: lands)),
  ]);
}

/// A first page with one button that opens [screen], the way the app reaches a land or the hall, so a test can leave it.
Future<void> pumpOpened(WidgetTester tester, Widget screen, List<Override> overrides) async {
  tester.view.physicalSize = const Size(852, 393);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        locale: const Locale('he'),
        supportedLocales: const <Locale>[Locale('he')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: AppTheme.child(),
        builder: (BuildContext context, Widget? c) => LayoutScope(band: Band.b, child: c!),
        home: Builder(
          builder: (BuildContext context) => Scaffold(
            body: TextButton(
              key: const Key('open'),
              onPressed: () =>
                  Navigator.of(context).push(MaterialPageRoute<void>(builder: (BuildContext c) => screen)),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.byKey(const Key('open')));
  await settle(tester);
}

Future<void> settle(WidgetTester tester) async {
  for (int i = 0; i < 5; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
    await tester.pump(const Duration(milliseconds: 120));
  }
}

/// A lazy narrator whose map-card lines are in a part pack of their own (the `skill` group), as the real build cuts it; counts
/// how many times that pack is read.
Future<({VoiceBank bank, List<String> loads})> lazyBank(List<String> skills) async {
  final PackKey key = await newTestKey();
  const String packId = 'voice-hero-son-part-skill';
  final VerifiedPack pack = await verifyPack(
    (await buildVoicePack(key, 'hero-son', <String, List<(int, int)>>{
      for (final String s in skills)
        'core.skill.${s.toLowerCase().replaceAll('-', '_')}': <(int, int)>[(0, 1)],
    }, packId: packId)).bytes,
    publicKey: key.publicKey,
  );
  final List<String> loads = <String>[];
  final LazyVoicePacks store = LazyVoicePacks(
    index: <String, String>{
      for (final String s in skills) 'vo:core.skill.${s.toLowerCase().replaceAll('-', '_')}': packId,
    },
    loader: (String id) async {
      loads.add(id);
      return pack;
    },
  );
  return (bank: VoiceBank.lazy('hero-son', store), loads: loads);
}

void main() {
  late VoiceBank bank;

  setUpAll(() async {
    await loadAppFonts();
    bank = await bankOf(<String>[recorded, alsoRecorded]);
  });

  group('a land map', () {
    Future<Rig> openLand(WidgetTester tester) async {
      final Rig r = await rig(bank, <TrophyLand, List<WorldObject>>{
        TrophyLand.colors: <WorldObject>[
          object(recorded, GrowthStage.sketch),
          object(alsoRecorded, GrowthStage.colour),
          object(unrecorded, GrowthStage.fruit),
          object(noLine, GrowthStage.sketch, withLine: false),
        ],
      });
      await pumpOpened(tester, const LandScreen(childId: child, land: TrophyLand.colors), r.overrides);
      return r;
    }

    Future<void> touch(WidgetTester tester, String skill) async {
      await tester.tap(find.byKey(Key('object-$skill')));
      await settle(tester);
    }

    testWidgets('a touch shows the line on the card and the narrator says it', (WidgetTester tester) async {
      final Rig r = await openLand(tester);
      await touch(tester, recorded);
      expect(find.text(lineOf(recorded)), findsOneWidget, reason: 'the caption is the card text');
      expect(r.player.played, <List<int>>[soundOf(recorded)]);
      expect(r.director.current, 'vo:core.skill.col_a_01');
      expect(r.director.speaking, isTrue);
    });

    testWidgets('another picture replaces the line, and the two never play together', (
      WidgetTester tester,
    ) async {
      final Rig r = await openLand(tester);
      await touch(tester, recorded);
      await touch(tester, alsoRecorded);
      expect(r.player.played, <List<int>>[soundOf(recorded), soundOf(alsoRecorded)]);
      expect(r.director.current, 'vo:core.skill.col_a_02');
      expect(
        r.player.stops,
        greaterThanOrEqualTo(1),
        reason: 'the first was stopped before the second began',
      );
      expect(r.player.playing, isTrue);
      expect(find.text(lineOf(alsoRecorded)), findsOneWidget);
      expect(find.text(lineOf(recorded)), findsNothing);
    });

    testWidgets('a second touch on the same picture closes the card and stops the line', (
      WidgetTester tester,
    ) async {
      final Rig r = await openLand(tester);
      await touch(tester, recorded);
      expect(r.player.playing, isTrue);
      await touch(tester, recorded);
      expect(find.byKey(const Key('land-object-card')), findsNothing);
      expect(r.player.playing, isFalse);
      expect(r.director.speaking, isFalse);
      expect(r.player.played.length, 1, reason: 'the second touch says nothing');
    });

    testWidgets('leaving the island stops the line', (WidgetTester tester) async {
      final Rig r = await openLand(tester);
      await touch(tester, recorded);
      expect(r.player.playing, isTrue);
      await tester.tap(find.byKey(const Key('land-back')));
      await settle(tester);
      expect(find.byType(LandScreen), findsNothing);
      expect(r.player.playing, isFalse);
      expect(r.director.speaking, isFalse);
    });

    testWidgets(
      'a line with no recording is silent, shows its card, raises no error and stops the one before',
      (WidgetTester tester) async {
        final Rig r = await openLand(tester);
        await touch(tester, recorded);
        expect(r.player.playing, isTrue);
        await touch(tester, unrecorded);
        expect(find.text(lineOf(unrecorded)), findsOneWidget);
        expect(r.player.played.length, 1, reason: 'nothing new was played');
        expect(
          r.player.playing,
          isFalse,
          reason: 'the earlier line gave way, so nothing talks over the new card',
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('a picture with no line shows its title and says nothing', (WidgetTester tester) async {
      final Rig r = await openLand(tester);
      await touch(tester, noLine);
      expect(find.text('skill $noLine'), findsWidgets);
      expect(r.player.played, isEmpty);
      expect(tester.takeException(), isNull);
    });
  });

  group('the Trophy Hall', () {
    Future<Rig> openHall(WidgetTester tester) async {
      final Rig r = await rig(
        bank,
        <TrophyLand, List<WorldObject>>{
          TrophyLand.colors: <WorldObject>[
            object(recorded, GrowthStage.fruit),
            object(alsoRecorded, GrowthStage.fruit),
            object(unrecorded, GrowthStage.fruit),
            object(noLine, GrowthStage.sketch, withLine: false),
          ],
        },
        rewards: <Reward>[reward(1, 'trophy:colors:bronze', 'trophy')],
      );
      await pumpOpened(tester, const TrophyHall(childId: child), r.overrides);
      await tester.tap(find.byKey(const Key('slot-trophy:colors:bronze')));
      await settle(tester);
      return r;
    }

    Future<void> touch(WidgetTester tester, String skill) async {
      await tester.tap(find.byKey(Key('hall-say-$skill')));
      await settle(tester);
    }

    testWidgets('a touch on a star line says it; another line replaces it; the same line again stops it', (
      WidgetTester tester,
    ) async {
      final Rig r = await openHall(tester);
      expect(find.byKey(Key('hall-line-$recorded')), findsOneWidget);
      await touch(tester, recorded);
      expect(r.player.played, <List<int>>[soundOf(recorded)]);
      expect(r.director.current, 'vo:core.skill.col_a_01');
      await touch(tester, alsoRecorded);
      expect(r.player.played, <List<int>>[soundOf(recorded), soundOf(alsoRecorded)]);
      expect(r.player.playing, isTrue);
      await touch(tester, alsoRecorded);
      expect(r.player.playing, isFalse);
      expect(r.director.speaking, isFalse);
      expect(r.player.played.length, 2);
    });

    testWidgets('a star line with no recording is silent and raises no error', (WidgetTester tester) async {
      final Rig r = await openHall(tester);
      await touch(tester, unrecorded);
      expect(r.player.played, isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('choosing another trophy, or leaving the hall, stops the line', (WidgetTester tester) async {
      final Rig r = await openHall(tester);
      await touch(tester, recorded);
      expect(r.player.playing, isTrue);
      await tester.tap(find.byKey(const Key('slot-trophy:colors:silver')));
      await settle(tester);
      expect(r.player.playing, isFalse);

      await tester.tap(find.byKey(const Key('slot-trophy:colors:bronze')));
      await settle(tester);
      await touch(tester, recorded);
      expect(r.player.playing, isTrue);
      await tester.tap(find.byKey(const Key('hall-back')));
      await settle(tester);
      expect(find.byType(TrophyHall), findsNothing);
      expect(r.player.playing, isFalse);
    });
  });

  group('the part of the voice that holds the card lines', () {
    final Map<TrophyLand, List<WorldObject>> colours = <TrophyLand, List<WorldObject>>{
      TrophyLand.colors: <WorldObject>[
        object(recorded, GrowthStage.fruit),
        object(noLine, GrowthStage.sketch, withLine: false),
      ],
    };

    testWidgets('opening a land reads it before any touch, once, and the first touch is heard at once', (
      WidgetTester tester,
    ) async {
      final lazy = await lazyBank(<String>[recorded]);
      final Rig r = await rig(lazy.bank, colours);
      await pumpOpened(tester, const LandScreen(childId: child, land: TrophyLand.colors), r.overrides);
      expect(lazy.loads, <String>['voice-hero-son-part-skill'], reason: 'read when the island opened');
      await tester.tap(find.byKey(const Key('object-$recorded')));
      await settle(tester);
      expect(r.player.played, <List<int>>[soundOf(recorded)]);
      expect(lazy.loads.length, 1, reason: 'the touch found the pack already in memory');
    });

    testWidgets('a land none of whose pictures has a line reads nothing', (WidgetTester tester) async {
      final lazy = await lazyBank(<String>[recorded]);
      final Rig r = await rig(lazy.bank, <TrophyLand, List<WorldObject>>{
        TrophyLand.colors: <WorldObject>[object(noLine, GrowthStage.sketch, withLine: false)],
      });
      await pumpOpened(tester, const LandScreen(childId: child, land: TrophyLand.colors), r.overrides);
      expect(lazy.loads, isEmpty);
    });

    testWidgets('opening the hall reads it when a star is earned, and not when none is', (
      WidgetTester tester,
    ) async {
      final lazy = await lazyBank(<String>[recorded]);
      final Rig r = await rig(lazy.bank, colours);
      await pumpOpened(tester, const TrophyHall(childId: child), r.overrides);
      expect(lazy.loads, <String>['voice-hero-son-part-skill']);

      final lazyNone = await lazyBank(<String>[recorded]);
      final Rig none = await rig(lazyNone.bank, <TrophyLand, List<WorldObject>>{
        TrophyLand.colors: <WorldObject>[object(recorded, GrowthStage.sketch)],
      });
      await tester.pumpWidget(const SizedBox.shrink());
      await pumpOpened(tester, const TrophyHall(childId: child), none.overrides);
      expect(lazyNone.loads, isEmpty, reason: 'no earned star shows a line, so the 6 MiB stay on disk');
    });
  });
}
