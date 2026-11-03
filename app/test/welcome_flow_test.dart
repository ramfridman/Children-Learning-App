// B-42 part (c): the daily welcome inside the real app. Once a day for each child, the first time their map is shown and
// settled; one sentence at a time in the friend's bubble; any touch stops it; never on top of a lesson, a ceremony or the
// rest scene; text only when a clip is missing or the sound is off. The real app with the real pack; sound is a fake player.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/app/app.dart';
import 'package:nitznutz/app/state.dart' show databaseProvider;
import 'package:nitznutz/app/reward_providers.dart';
import 'package:nitznutz/app/welcome_providers.dart';
import 'package:nitznutz/child/home_screen.dart';
import 'package:nitznutz/child/land_screen.dart';
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/characters/character.dart';
import 'package:nitznutz/characters/character_source.dart';
import 'package:nitznutz/content/engine_adapter.dart';
import 'package:nitznutz/content/pack_verify.dart';
import 'package:nitznutz/engine/engine.dart';
import 'package:nitznutz/engine/types.dart' show Catalog;
import 'package:nitznutz/rewards/reward_service.dart';
import 'package:nitznutz/strings/he.dart';
import 'package:nitznutz/voice/voice_bank.dart';
import 'package:nitznutz/world/welcome_table.dart';

import '../tool/pack_builder_lib.dart';
import 'support/app_harness.dart';
import 'support/companion_fixtures.dart';
import 'support/harness.dart';
import 'support/pack_fixtures.dart';
import 'support/starter.dart';
import 'support/voice_fixtures.dart';

late WelcomeTable table;

/// A reward service that gives one bronze trophy at the first look, so the map opens with a ceremony.
class _TrophyOnFirstLook extends RewardService {
  _TrophyOnFirstLook(AppDatabase db, Catalog catalog)
    : super(db: db, catalog: catalog, domains: const <String, String>{}, nowMs: () => 0);

  bool _given = false;

  @override
  Future<List<Reward>> evaluate(String childId) async {
    if (_given) return const <Reward>[];
    _given = true;
    await db.addReward(
      RewardsCompanion.insert(
        profileId: childId,
        awardKey: 'trophy:counting:bronze',
        kind: 'trophy',
        at: DateTime.utc(2026, 10, 25),
      ),
    );
    return db.rewardsOf(childId);
  }
}

/// The ids of the welcome lines, without `vo:`.
List<String> welcomeIds() => <String>[for (final String id in table.lineIds) id.substring('vo:'.length)];

/// The words in the map's bubble, without the direction marks around a name.
String bubble(WidgetTester tester) => tester
    .widget<Text>(find.descendant(of: find.byKey(const Key('bubble-body')), matching: find.byType(Text)))
    .data!
    .replaceAll(RegExp(r'[\u2066-\u2069\u200E\u200F]'), '');

/// What the bubble says when the welcome is not on.
String get ownBubble => He.homeBubbleNoName.text;

bool isOwn(WidgetTester tester) => bubble(tester).endsWith(ownBubble);

/// The text of a welcome line, as the bubble shows it after the name.
String line(String id) => table.text(id);

/// The child, signed in on the map, with the welcome on.
Future<AppRig> toMap(
  WidgetTester tester, {
  AppRig? rig,
  bool seed = true,
  int band = 1,
  bool reduceMotion = true,
  String name = 'נועה',
}) async {
  final AppRig r = rig ?? AppRig(welcome: true);
  if (seed) await r.seedFinishedSetup(ageBand: band);
  await r.pump(tester, reduceMotion: reduceMotion);
  await tester.tap(find.text(name));
  await tester.pump();
  return r;
}

/// Lets the welcome's start-up (several awaits and one frame) run.
Future<void> start(WidgetTester tester) async {
  for (int i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Steps through the text-only welcome and returns what the bubble said at each sentence.
Future<List<String>> readWelcome(WidgetTester tester) async {
  final List<String> said = <String>[];
  String last = '';
  for (int ms = 0; ms < 12000; ms += 100) {
    if (find.byKey(const Key('bubble-body')).evaluate().isEmpty) break;
    final String now = bubble(tester);
    if (now != last) {
      last = now;
      said.add(now);
    }
    await tester.pump(const Duration(milliseconds: 100));
  }
  return said;
}

/// Nitzi, with a voice that has just [lines] (ids without `vo:`, each a tiny file that names its line).
Future<FixedCharacterSource> sourceWith(List<String> lines) async {
  final PackKey key = await newTestKey();
  final Character nitzi = await loadNitzi();
  final BuiltPack built = await buildVoicePack(key, nitzi.id, <String, List<(int, int)>>{
    for (final String line in lines) line: <(int, int)>[(0, 0), (100, 1), (200, 0)],
  });
  return FixedCharacterSource(
    characters: <Character>[nitzi],
    house: nitzi,
    voices: <String, VoiceBank>{
      nitzi.id: VoiceBank.fromPack(await verifyPack(built.bytes, publicKey: key.publicKey)),
    },
  );
}

/// A child who has finished a lesson, so that the day's greeting is one of the three that turn with the day.
Future<void> seedPlayed(AppRig rig) async {
  await rig.seedFinishedSetup();
  final DateTime at = DateTime.utc(2026, 10, 25, 9);
  final int s = await rig.db.startSession('p-1', at, plan: 'lesson:butterflies');
  await rig.db.recordAttempt(
    AttemptsCompanion.insert(
      at: at,
      profileId: 'p-1',
      packId: 'starter',
      packVersion: '0.10.0',
      lessonId: const Value<String>('butterflies'),
      activityId: 'count.butterflies.3',
      activityRevision: 1,
      template: 'count_tap',
      templateVersion: '1.0',
      skillId: 'NUM-A-01',
      result: 'correct',
      attemptNo: 1,
      hintLevel: 0,
      sessionId: Value<int?>(s),
    ),
  );
  await rig.db.endSession(s, at, 'finished');
  await rig.db.addReward(
    RewardsCompanion.insert(profileId: 'p-1', awardKey: 'sticker:butterflies:1', kind: 'sticker', at: at),
  );
}

Future<void> restart(WidgetTester tester, AppRig rig) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
  await tester.pumpWidget(ProviderScope(overrides: rig.overrides, child: const NitznutzApp()));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await loadAppFonts();
    table = WelcomeTable.parse(File('assets/lines/welcome.json').readAsStringSync());
  });

  group('given once a day', () {
    testWidgets('a new child hears the first-day greeting, the topic, the closing line, one at a time', (
      WidgetTester tester,
    ) async {
      final AppRig rig = await toMap(tester);
      await start(tester);
      final List<String> said = await readWelcome(tester);
      expect(said, hasLength(4), reason: 'three sentences, then the bubble\'s own words: $said');
      expect(said[0], contains(line('vo:welcome.hello.first')));
      expect(said[0], startsWith('נועה,'), reason: 'the name first, as a call');
      expect(said[1], matches(RegExp('^הַיּוֹם')), reason: 'what we will do today');
      expect(said[1], isNot(contains('נועה')));
      expect(said[2], line('vo:welcome.close'));
      expect(said[3], endsWith(ownBubble));
      expect(find.byType(HomeScreen), findsOneWidget);
      final int day = Engine.dayKey(DateTime.fromMillisecondsSinceEpoch(rig.clock.now, isUtc: true));
      expect(await rig.db.welcomeDayOf('p-1'), day, reason: 'the day is kept');
    });

    testWidgets(
      'the same day, the map is the ordinary map: after a restart, and after a change of child and back',
      (WidgetTester tester) async {
        final AppRig rig = await toMap(tester);
        await start(tester);
        await readWelcome(tester);
        expect(isOwn(tester), isTrue);

        await restart(tester, rig);
        await tester.tap(find.text('נועה'));
        await start(tester);
        expect(isOwn(tester), isTrue, reason: 'a restart does not bring it back');

        await tester.tap(find.bySemanticsLabel(He.switchChildSemantics.text));
        await tester.pumpAndSettle();
        await tester.tap(find.text('נועה'));
        await start(tester);
        expect(isOwn(tester), isTrue, reason: 'a change of child and back does not either');
      },
    );

    testWidgets('the next day it comes again, with the greeting of that day', (WidgetTester tester) async {
      final AppRig rig = AppRig(welcome: true);
      await seedPlayed(rig);
      await toMap(tester, rig: rig, seed: false);
      await start(tester);
      Future<String> greeting() async {
        final List<String> said = await readWelcome(tester);
        expect(said, hasLength(4), reason: '$said');
        return said.first;
      }

      int day() => Engine.dayKey(DateTime.fromMillisecondsSinceEpoch(rig.clock.now, isUtc: true));
      final int first = day();
      expect(await greeting(), contains(line('vo:welcome.hello.${first % 3 + 1}')));
      await restart(tester, rig);
      rig.clock.advance(const Duration(days: 1));
      await tester.tap(find.text('נועה'));
      await start(tester);
      expect(await greeting(), contains(line('vo:welcome.hello.${(first + 1) % 3 + 1}')));
    });

    testWidgets('each child has a day of their own', (WidgetTester tester) async {
      final AppRig rig = AppRig(welcome: true);
      await rig.seedFinishedSetup();
      await rig.db.addProfile(
        ProfilesCompanion.insert(
          id: 'p-2',
          name: 'דני',
          avatar: 'avatar-noa',
          addressForm: 'm',
          ageBand: 1,
          createdAt: DateTime.utc(2026, 10, 27),
        ),
      );
      await rig.pump(tester);
      await tester.tap(find.text('נועה'));
      await start(tester);
      await readWelcome(tester);
      expect(await rig.db.welcomeDayOf('p-1'), isNotNull);
      expect(await rig.db.welcomeDayOf('p-2'), isNull, reason: 'the other child has not had theirs');
    });
  });

  group('never on top of something else', () {
    testWidgets('in the rest hours there is no welcome, and the day is not used up', (
      WidgetTester tester,
    ) async {
      final AppRig rig = AppRig(welcome: true, clockMs: DateTime(2026, 10, 28, 22).millisecondsSinceEpoch);
      await toMap(tester, rig: rig);
      await start(tester);
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(isOwn(tester), isTrue);
      await tester.pump(const Duration(seconds: 3));
      expect(isOwn(tester), isTrue);
      expect(await rig.db.welcomeDayOf('p-1'), isNull);
    });

    testWidgets('a ceremony is never talked over: the welcome waits until it is over', (
      WidgetTester tester,
    ) async {
      final AppRig withTrophy = AppRig(
        welcome: true,
        extraOverrides: <Override>[
          rewardServiceProvider.overrideWith(
            (Ref ref) async => _TrophyOnFirstLook(
              await ref.watch(databaseProvider.future),
              engineCatalog(await loadStarter()),
            ),
          ),
        ],
      );
      await withTrophy.seedFinishedSetup();
      await toMap(tester, rig: withTrophy, seed: false);
      await start(tester);
      expect(find.byKey(const Key('ceremony')), findsOneWidget, reason: 'the map opened with a ceremony');
      expect(await withTrophy.db.welcomeDayOf('p-1'), isNull, reason: 'no welcome on top of it');
      await tester.pump(const Duration(seconds: 4));
      await tester.tap(find.byKey(const Key('ceremony-continue')));
      await tester.pump(const Duration(milliseconds: 300));
      await start(tester);
      expect(find.byKey(const Key('ceremony')), findsNothing);
      expect(isOwn(tester), isFalse, reason: 'the ceremony is over: now the welcome');
      expect(await withTrophy.db.welcomeDayOf('p-1'), isNotNull);
    });

    testWidgets('with the welcome off nothing is shown or kept', (WidgetTester tester) async {
      final AppRig rig = AppRig();
      await toMap(tester, rig: rig);
      await start(tester);
      expect(isOwn(tester), isTrue);
      expect(await rig.db.welcomeDayOf('p-1'), isNull);
    });
  });

  group('a touch stops it', () {
    testWidgets('a touch on the friend: the welcome stops, the friend does what it always does', (
      WidgetTester tester,
    ) async {
      final FakePlayer player = FakePlayer()..endsAfter = const Duration(milliseconds: 700);
      final AppRig rig = AppRig(
        welcome: true,
        player: player,
        characters: await sourceWith(<String>[...welcomeIds(), 'core.greeting.hello']),
      );
      await toMap(tester, rig: rig);
      await start(tester);
      expect(isOwn(tester), isFalse, reason: 'the welcome is on');
      expect(player.plays, 1, reason: 'the first sentence is being said');
      await tester.tap(find.byKey(const Key('home-companion')));
      await tester.pump();
      expect(isOwn(tester), isTrue, reason: 'the bubble is its own again');
      await tester.pump(const Duration(seconds: 10));
      expect(isOwn(tester), isTrue, reason: 'it does not come back');
      expect(player.plays, 2, reason: 'only the hello of the friend followed');
      expect(utf8.decode(player.played.last), 'mp3:nitzi:core.greeting.hello');
      expect(await rig.db.welcomeDayOf('p-1'), isNotNull, reason: 'the day stays used');
    });

    testWidgets('a touch on a land stops it and still opens the land', (WidgetTester tester) async {
      await toMap(tester);
      await start(tester);
      expect(isOwn(tester), isFalse);
      final Finder tap = find.byKey(const Key('land-tap-counting'));
      await tester.ensureVisible(tap);
      await tester.pump();
      await tester.tap(tap);
      await tester.pumpAndSettle();
      expect(find.byType(LandScreen), findsOneWidget, reason: 'the touch did what it always does');
    });
  });

  group('the sound', () {
    Future<AppRig> voicedRig(FakePlayer player, {List<String>? lines, List<Override> more = const []}) async {
      final AppRig rig = AppRig(
        welcome: true,
        player: player,
        characters: await sourceWith(lines ?? welcomeIds()),
        extraOverrides: more,
      );
      return rig;
    }

    testWidgets('with every clip the friend says the sentences in turn, and nothing twice', (
      WidgetTester tester,
    ) async {
      final FakePlayer player = FakePlayer()..endsAfter = const Duration(milliseconds: 700);
      await toMap(tester, rig: await voicedRig(player));
      await start(tester);
      final List<String> said = await readWelcome(tester);
      expect(said, hasLength(4), reason: '$said');
      final List<String> played = <String>[for (final Uint8List b in player.played) utf8.decode(b)];
      expect(played, hasLength(3), reason: '$played');
      expect(played[0], 'mp3:nitzi:welcome.hello.first');
      expect(played[1], startsWith('mp3:nitzi:welcome.'));
      expect(played[2], 'mp3:nitzi:welcome.close');
    });

    testWidgets('the child\'s name clip comes right before the greeting, and only there', (
      WidgetTester tester,
    ) async {
      final Uint8List name = Uint8List.fromList(utf8.encode('the-name-clip'));
      final FakePlayer player = FakePlayer()..endsAfter = const Duration(milliseconds: 500);
      await toMap(
        tester,
        rig: await voicedRig(
          player,
          more: <Override>[nameClipProvider('p-1').overrideWith((Ref ref) async => name)],
        ),
      );
      await start(tester);
      await readWelcome(tester);
      expect(player.played, hasLength(4));
      expect(utf8.decode(player.played[0]), 'the-name-clip');
      expect(utf8.decode(player.played[1]), 'mp3:nitzi:welcome.hello.first');
      for (final Uint8List later in player.played.skip(2)) {
        expect(utf8.decode(later), isNot('the-name-clip'));
      }
    });

    testWidgets('a missing clip makes the whole welcome text: nothing is played, every sentence is shown', (
      WidgetTester tester,
    ) async {
      final FakePlayer player = FakePlayer();
      await toMap(
        tester,
        rig: await voicedRig(
          player,
          lines: <String>[
            for (final String id in welcomeIds())
              if (id != 'welcome.close') id,
          ],
        ),
      );
      await start(tester);
      final List<String> said = await readWelcome(tester);
      expect(said, hasLength(4), reason: '$said');
      expect(said[2], line('vo:welcome.close'));
      expect(player.plays, 0, reason: 'no half-voiced sequence');
    });

    testWidgets('with the sound off the welcome is text', (WidgetTester tester) async {
      final FakePlayer player = FakePlayer();
      await toMap(
        tester,
        rig: await voicedRig(player, more: <Override>[welcomeSpokenProvider.overrideWithValue(false)]),
      );
      await start(tester);
      final List<String> said = await readWelcome(tester);
      expect(said, hasLength(4));
      expect(player.plays, 0);
    });
  });

  group('the bubble and the pill', () {
    testWidgets('the pill glows for the closing line, and with reduced motion it does not', (
      WidgetTester tester,
    ) async {
      for (final bool still in <bool>[true, false]) {
        final ValueNotifier<bool> glow = ValueNotifier<bool>(false);
        addTearDown(glow.dispose);
        tester.platformDispatcher.accessibilityFeaturesTestValue = FakeAccessibilityFeatures(
          disableAnimations: still,
        );
        addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
        await pumpScreen(
          tester,
          HomeScreen(
            childName: 'נועה',
            avatarId: 'avatar-noa',
            onParents: () {},
            onSwitchChild: () {},
            onOpenActivity: () {},
            pillGlow: glow,
          ),
        );
        List<BoxShadow> shadows() =>
            (tester.widget<Container>(find.byKey(const Key('home-pill'))).decoration! as BoxDecoration)
                .boxShadow!;
        final int plain = shadows().length;
        glow.value = true;
        await tester.pump();
        expect(shadows().length, still ? plain : plain + 1, reason: still ? 'reduced motion' : 'the glow');
        glow.value = false;
        await tester.pump();
        expect(shadows().length, plain, reason: 'and it goes out');
      }
    });

    testWidgets('a long name has a line of its own, the sentence under it', (WidgetTester tester) async {
      const String name = 'אלישבע־מרים־אברמוביץ';
      final AppRig rig = AppRig(welcome: true);
      await rig.seedFinishedSetup(name: name);
      await toMap(tester, rig: rig, seed: false, name: name);
      await start(tester);
      final String first = bubble(tester);
      final List<String> rows = first.split('\n');
      expect(rows.first, endsWith(','), reason: 'the name, a comma, and the sentence under it');
      expect(rows.skip(1).join('\n'), line('vo:welcome.hello.first'));
      expect(tester.takeException(), isNull);
    });
  });
}
