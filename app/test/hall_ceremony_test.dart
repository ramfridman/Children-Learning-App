// The Trophy Hall and the ceremony (M8b): shelves by land with silhouettes for what is not earned yet, the card that says how
// it is earned, medals, decorations and the prizes for the companion, and the ceremony with its spotlight, its one tap to
// skip, and its calm form for "reduce motion". Goldens are in right to left with the real fonts.
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/app/companion.dart';
import 'package:nitznutz/app/reward_providers.dart';
import 'package:nitznutz/app/ribbon_providers.dart';
import 'package:nitznutz/app/state.dart';
import 'package:nitznutz/app/world_providers.dart';
import 'package:nitznutz/characters/character.dart';
import 'package:nitznutz/characters/character_view.dart';
import 'package:nitznutz/child/ceremony_screen.dart';
import 'package:nitznutz/child/trophy_art.dart';
import 'package:nitznutz/child/trophy_hall.dart';
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/design/layout.dart';
import 'package:nitznutz/design/theme.dart';
import 'package:nitznutz/design/token_types.dart';
import 'package:nitznutz/rewards/award.dart';
import 'package:nitznutz/rewards/outfits.dart';
import 'package:nitznutz/strings/he.dart';
import 'package:nitznutz/voice/voice_director.dart';
import 'package:nitznutz/world/world_state.dart';

import 'engine/fixtures.dart';
import 'support/golden_comparator.dart';
import 'support/harness.dart';
import 'support/voice_fixtures.dart';

const String child = 'p-1';

Character friend() => Character(
  id: 'friend',
  packId: 'char-friend',
  nameHe: 'חבר',
  gender: 'm',
  roles: <CharacterRole>{CharacterRole.mapCompanion, CharacterRole.celebrationCameo},
  personalUseOnly: false,
  mouth: const Offset(0.5, 0.4),
  canvas: const Size(100, 100),
  images: <String, CharacterImage>{
    'idle': const CharacterImage.svg(
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">'
      '<circle cx="50" cy="38" r="24" fill="#F2C9A0"/><rect x="26" y="58" width="48" height="40" rx="10" fill="#2F7FE0"/></svg>',
    ),
  },
);

Reward reward(int id, String key, String kind, {bool seen = true}) => Reward(
  id: id,
  profileId: child,
  awardKey: key,
  kind: kind,
  at: day0,
  seenAt: seen ? day0 : null,
  eventId: null,
  syncedAt: null,
);

WorldObject object(String id, GrowthStage stage) =>
    WorldObject(skillId: id, title: 'skill $id', objectId: 'stair', stage: stage, bell: false);

class FakeOutfit extends OutfitNotifier {
  FakeOutfit(this.first);

  final String? first;

  @override
  Future<String?> build() async => first;

  @override
  Future<void> choose(String outfitId) async => state = AsyncData<String?>(outfitId);
}

/// Four skills in Counting Hills with [lasting] of them understood for good, and two in Colour Bay (too few for trophies).
List<Override> overrides({
  required List<Reward> rewards,
  int lasting = 2,
  String? outfit,
  Map<String, String> ribbons = const <String, String>{},
  AppDatabase? db,
  Map<TrophyLand, List<WorldObject>>? lands,
}) {
  final VoiceDirector director = VoiceDirector(player: FakePlayer());
  addTearDown(director.dispose);
  return <Override>[
    voiceDirectorProvider.overrideWithValue(director),
    rewardsProvider(child).overrideWith((Ref ref) async => rewards),
    ribbonsProvider(child).overrideWith((Ref ref) async => ribbons),
    outfitProvider.overrideWith(() => FakeOutfit(outfit)),
    characterForRoleProvider(CharacterRole.mapCompanion).overrideWith((Ref ref) async => friend()),
    characterForRoleProvider(CharacterRole.celebrationCameo).overrideWith((Ref ref) async => friend()),
    if (db != null) databaseProvider.overrideWith((Ref ref) async => db),
    worldProvider(child).overrideWith(
      (Ref ref) async => WorldView(
        engine: engineOf(smallCatalog()),
        now: day0,
        lands:
            lands ??
            <TrophyLand, List<WorldObject>>{
              TrophyLand.counting: <WorldObject>[
                for (int i = 0; i < 4; i++)
                  object(
                    'SK-${String.fromCharCode(65 + i)}-01',
                    i < lasting ? GrowthStage.fruit : GrowthStage.sketch,
                  ),
              ],
              TrophyLand.colors: <WorldObject>[object('COL-A-01', GrowthStage.colour)],
            },
      ),
    ),
  ];
}

/// Shows [screen] the way the app does, with the providers above the navigator so that a screen pushed from it has them too.
Future<void> pumpIn(
  WidgetTester tester,
  Widget screen,
  List<Override> overrides, {
  Size size = const Size(852, 393),
}) async {
  await tester.pumpWidget(const SizedBox.shrink());
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        locale: const Locale('he'),
        supportedLocales: const <Locale>[Locale('he')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: AppTheme.child(),
        builder: (BuildContext context, Widget? child) => LayoutScope(band: Band.b, child: child!),
        home: screen,
      ),
    ),
  );
  await settle(tester);
}

/// A few frames: the companion breathes for ever, so a screen that shows it never "settles".
Future<void> settle(WidgetTester tester) async {
  for (int i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 120));
  }
}

Finder lockedCups() => find.byWidgetPredicate((Widget w) => w is TrophyCup && w.locked);
Finder earnedCups() => find.byWidgetPredicate((Widget w) => w is TrophyCup && !w.locked);

void main() {
  setUpAll(() async {
    await loadAppFonts();
    useTolerantGoldens(0.03);
  });

  group('the Trophy Hall', () {
    testWidgets('a child with nothing yet sees calm silhouettes of every trophy, and none are padlocked', (
      WidgetTester tester,
    ) async {
      await pumpIn(
        tester,
        const TrophyHall(childId: child),
        overrides(rewards: const <Reward>[], lasting: 0),
      );
      expect(find.text(He.hallTitle.text), findsOneWidget);
      expect(lockedCups(), findsAtLeastNWidgets(9), reason: 'every shelf in view shows its three');
      expect(earnedCups(), findsNothing);
      expect(find.byIcon(Icons.lock), findsNothing);
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/hall_empty_phone.png'));
    });

    testWidgets('earned trophies are in colour, the new one glows, and the star count of each land shows', (
      WidgetTester tester,
    ) async {
      await pumpIn(
        tester,
        const TrophyHall(childId: child),
        overrides(
          rewards: <Reward>[
            reward(1, 'trophy:counting:bronze', 'trophy'),
            reward(2, 'trophy:counting:silver', 'trophy', seen: false),
          ],
        ),
      );
      expect(earnedCups(), findsNWidgets(2));
      expect(
        find.descendant(of: find.byKey(const Key('shelf-stars-counting')), matching: find.text('2/4')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: find.byKey(const Key('shelf-stars-colors')), matching: find.text('0/1')),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel(RegExp(He.trophyNewSemantics.text)), findsOneWidget);
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/hall_partial_phone.png'));
    });

    testWidgets(
      'tapping a trophy says how it is earned, with the progress, and an earned one can be watched again',
      (WidgetTester tester) async {
        final AppDatabase db = AppDatabase(NativeDatabase.memory());
        addTearDown(db.close);
        await db.addReward(
          RewardsCompanion.insert(
            profileId: child,
            awardKey: 'trophy:counting:silver',
            kind: 'trophy',
            at: day0,
          ),
        );
        final Reward waiting = (await db.rewardsOf(child)).single;
        await pumpIn(tester, const TrophyHall(childId: child), overrides(rewards: <Reward>[waiting], db: db));
        await tester.tap(find.byKey(const Key('slot-trophy:counting:gold')));
        await settle(tester);
        expect(find.byKey(const Key('hall-card')), findsOneWidget);
        expect(find.text(He.trophyHow.fill(<String, String>{'n': '4'})), findsOneWidget);
        expect(
          find.byKey(const Key('hall-replay')),
          findsNothing,
          reason: 'nothing to watch for a trophy not earned',
        );
        expect(
          find.descendant(of: find.byKey(const Key('hall-dots')), matching: find.byType(Container)),
          findsNWidgets(4),
        );

        await tester.tap(find.byKey(const Key('slot-trophy:counting:silver')));
        await settle(tester);
        expect(find.byKey(const Key('hall-replay')), findsOneWidget);
        expect(
          (await db.rewardsOf(child)).single.seenAt,
          isNotNull,
          reason: 'looking at a waiting trophy shows it',
        );
        await tester.tap(find.byKey(const Key('hall-replay')));
        await settle(tester);
        expect(find.byKey(const Key('ceremony')), findsOneWidget);
        expect(find.text(ceremonyLine(TrophyTier.silver).text), findsOneWidget);
        await tester.pump(const Duration(seconds: 4)); // the ceremony plays out
      },
    );

    testWidgets(
      'the card of an earned trophy says what was learned, from the lines of the skills understood for good',
      (WidgetTester tester) async {
        await pumpIn(
          tester,
          const TrophyHall(childId: child),
          overrides(
            rewards: <Reward>[reward(1, 'trophy:counting:bronze', 'trophy')],
            lands: <TrophyLand, List<WorldObject>>{
              TrophyLand.counting: <WorldObject>[
                const WorldObject(
                  skillId: 'SK-A-01',
                  title: 'a',
                  objectId: 'stair',
                  stage: GrowthStage.fruit,
                  bell: false,
                  line: 'סוֹפְרִים עַד חָמֵשׁ',
                ),
                const WorldObject(
                  skillId: 'SK-B-01',
                  title: 'b',
                  objectId: 'stair',
                  stage: GrowthStage.sketch,
                  bell: false,
                  line: 'עוֹד לֹא הִגַּעְנוּ',
                ),
                object('SK-C-01', GrowthStage.fruit),
              ],
            },
          ),
        );
        await tester.tap(find.byKey(const Key('slot-trophy:counting:bronze')));
        await settle(tester);
        expect(find.byKey(const Key('hall-line-SK-A-01')), findsOneWidget);
        expect(find.text('סוֹפְרִים עַד חָמֵשׁ'), findsOneWidget);
        expect(find.byKey(const Key('hall-line-SK-B-01')), findsNothing, reason: 'not understood yet');
        // A trophy not earned yet shows how to earn it, and no lines.
        await tester.tap(find.byKey(const Key('slot-trophy:counting:gold')));
        await settle(tester);
        expect(find.byKey(const Key('hall-line-SK-A-01')), findsNothing);
      },
    );

    testWidgets('a land with too few skills says its trophies come as more is learned', (
      WidgetTester tester,
    ) async {
      await pumpIn(tester, const TrophyHall(childId: child), overrides(rewards: const <Reward>[]));
      await tester.tap(find.byKey(const Key('slot-trophy:colors:bronze')));
      await settle(tester);
      expect(find.text(He.trophyComing.text), findsOneWidget);
      expect(find.byKey(const Key('hall-dots')), findsNothing);
    });

    testWidgets('the parents\' promise shows on that trophy\'s card and nowhere else', (
      WidgetTester tester,
    ) async {
      await pumpIn(
        tester,
        const TrophyHall(childId: child),
        overrides(
          rewards: const <Reward>[],
          ribbons: <String, String>{'trophy:counting:gold': 'הולכים לגלידה'},
        ),
      );
      await tester.tap(find.byKey(const Key('slot-trophy:counting:gold')));
      await settle(tester);
      expect(find.text('הולכים לגלידה'), findsOneWidget);
      await tester.tap(find.byKey(const Key('slot-trophy:counting:silver')));
      await settle(tester);
      expect(find.text('הולכים לגלידה'), findsNothing);
      expect(find.byKey(const Key('hall-promise')), findsNothing);
    });

    testWidgets(
      'medals: earned ones in colour, the ones with no activities yet as silhouettes, decorations by progress',
      (WidgetTester tester) async {
        await pumpIn(
          tester,
          const TrophyHall(childId: child, initialTab: HallTab.medals),
          overrides(
            rewards: <Reward>[
              reward(1, 'medal:brave-asker', 'medal'),
              for (int i = 0; i < 3; i++) reward(10 + i, 'star:SK-${String.fromCharCode(65 + i)}-01', 'star'),
            ],
          ),
        );
        expect(find.byKey(const Key('medal-brave-asker')), findsOneWidget);
        expect(
          find.descendant(
            of: find.byKey(const Key('medal-brave-asker')),
            matching: find.byWidgetPredicate((Widget w) => w is MedalArt && w.locked),
          ),
          findsNothing,
        );
        for (final String id in <String>['try-again', 'explainer', 'bug-fixer']) {
          expect(
            find.descendant(
              of: find.byKey(Key('medal-$id')),
              matching: find.byWidgetPredicate((Widget w) => w is MedalArt && w.locked),
            ),
            findsOneWidget,
            reason: id,
          );
        }
        expect(
          find.descendant(of: find.byKey(const Key('deco-10')), matching: find.text('3/10')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: find.byKey(const Key('deco-30')), matching: find.text('3/30')),
          findsOneWidget,
        );
        await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/hall_medals_phone.png'));
      },
    );

    testWidgets(
      'prizes: a colour set comes with a trophy of its tier, is chosen with a tap, and shows on the companion',
      (WidgetTester tester) async {
        await pumpIn(
          tester,
          const TrophyHall(childId: child, initialTab: HallTab.friend),
          overrides(rewards: <Reward>[reward(1, 'trophy:counting:silver', 'trophy')]),
        );
        expect(find.byKey(const Key('outfit-sky')), findsOneWidget);
        expect(find.byKey(const Key('outfit-sky')).hitTestable(), findsOneWidget);
        // The bronze scarf is not earned: it says which trophy brings it, and tapping it does nothing.
        expect(find.text(He.outfitHowBronze.text), findsOneWidget);
        await tester.tap(find.byKey(const Key('outfit-honey')));
        await settle(tester);
        expect(find.byKey(const Key('hall-friend')), findsOneWidget);
        expect(find.byType(ScarfPainter, skipOffstage: false), findsNothing);
        await tester.tap(find.byKey(const Key('outfit-sky')));
        await settle(tester);
        expect(
          find.descendant(
            of: find.byKey(const Key('hall-friend')),
            matching: find.byWidgetPredicate((Widget w) => w is CustomPaint && w.painter is ScarfPainter),
          ),
          findsOneWidget,
        );
        await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/hall_friend_phone.png'));
      },
    );

    testWidgets('the Hall fits a small phone and a tablet in both ways', (WidgetTester tester) async {
      for (final Size size in <Size>[const Size(667, 375), const Size(1180, 820), const Size(820, 1180)]) {
        for (final HallTab tab in HallTab.values) {
          await pumpIn(
            tester,
            TrophyHall(childId: child, initialTab: tab),
            overrides(rewards: <Reward>[reward(1, 'trophy:counting:gold', 'trophy')]),
            size: size,
          );
          expect(tester.takeException(), isNull, reason: '$size $tab');
        }
      }
    });
  });

  group('the ceremony', () {
    Future<void> open(WidgetTester tester, String key, {Outfit? prize, List<Override>? extra}) async {
      await pumpIn(
        tester,
        Builder(
          builder: (BuildContext context) => TextButton(
            key: const Key('open'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (BuildContext c) => CeremonyScreen(awardKey: key, prize: prize),
              ),
            ),
            child: const Text('open'),
          ),
        ),
        extra ?? overrides(rewards: const <Reward>[]),
      );
      await tester.tap(find.byKey(const Key('open')));
      await tester.pump();
    }

    testWidgets('a trophy: the title, the companion\'s line, the cup, and the button that always works', (
      WidgetTester tester,
    ) async {
      await open(tester, 'trophy:counting:silver');
      await tester.pump(const Duration(milliseconds: 3300));
      expect(
        find.descendant(
          of: find.byKey(const Key('ceremony-title')),
          matching: find.textContaining(He.trophySilver.text),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('ceremony-line')),
          matching: find.text(He.ceremonySilver.text),
        ),
        findsOneWidget,
      );
      expect(earnedCups(), findsOneWidget);
      expect(find.byKey(const Key('ceremony-prize')), findsNothing);
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/ceremony_silver_phone.png'));
      await tester.tap(find.byKey(const Key('ceremony-continue')));
      await settle(tester);
      expect(find.byKey(const Key('ceremony')), findsNothing);
    });

    testWidgets('the first trophy of a tier brings its prize on a card for the companion', (
      WidgetTester tester,
    ) async {
      await open(tester, 'trophy:counting:silver', prize: outfits[1]);
      await tester.pump(const Duration(milliseconds: 3300));
      expect(find.byKey(const Key('ceremony-prize')), findsOneWidget);
      expect(find.text(He.outfitSky.text), findsOneWidget);
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/ceremony_prize_phone.png'));
    });

    testWidgets('a medal gets its own title and line, with the medal in place of a cup', (
      WidgetTester tester,
    ) async {
      await open(tester, 'medal:brave-asker');
      await tester.pump(const Duration(milliseconds: 3300));
      expect(
        find.descendant(
          of: find.byKey(const Key('ceremony-title')),
          matching: find.textContaining(He.medalBraveAsker.text),
        ),
        findsOneWidget,
      );
      expect(find.text(He.ceremonyMedal.text), findsOneWidget);
      expect(find.byType(MedalArt), findsOneWidget);
      expect(earnedCups(), findsNothing);
    });

    testWidgets('a tap anywhere ends it, but only after a moment', (WidgetTester tester) async {
      await open(tester, 'trophy:counting:bronze');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tapAt(const Offset(400, 200));
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        find.byKey(const Key('ceremony')),
        findsOneWidget,
        reason: 'too early: the tap is only the end of the lesson',
      );
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.tapAt(const Offset(400, 200));
      await settle(tester);
      expect(find.byKey(const Key('ceremony')), findsNothing);
    });

    testWidgets(
      'with "reduce motion" there is a still spotlight and no confetti, and it is complete at once',
      (WidgetTester tester) async {
        tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
          disableAnimations: true,
        );
        addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
        await open(tester, 'trophy:counting:gold');
        await tester.pump(const Duration(milliseconds: 500)); // the page slides in
        expect(
          find.byWidgetPredicate((Widget w) => w is CustomPaint && w.painter is ConfettiPainter),
          findsNothing,
        );
        expect(find.byKey(const Key('ceremony-title')), findsOneWidget);
        expect(find.text(He.ceremonyGold.text), findsOneWidget);
        expect(tester.hasRunningAnimations, isFalse);
        await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/ceremony_still_phone.png'));
        await tester.pump(const Duration(seconds: 1));
      },
    );

    testWidgets('the cup arrives with confetti while motion is on', (WidgetTester tester) async {
      await open(tester, 'trophy:counting:gold');
      await tester.pump(const Duration(milliseconds: 1500));
      expect(
        find.byWidgetPredicate((Widget w) => w is CustomPaint && w.painter is ConfettiPainter),
        findsOneWidget,
      );
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/ceremony_mid_phone.png'));
      await tester.pump(const Duration(milliseconds: 2000));
    });

    testWidgets('it fits a small phone and a tablet', (WidgetTester tester) async {
      for (final Size size in <Size>[const Size(667, 375), const Size(1180, 820), const Size(820, 1180)]) {
        await pumpIn(
          tester,
          CeremonyScreen(awardKey: 'trophy:counting:gold', prize: outfits[2]),
          overrides(rewards: const <Reward>[]),
          size: size,
        );
        await tester.pump(const Duration(milliseconds: 3300));
        expect(tester.takeException(), isNull, reason: '$size');
      }
    });
  });

  test('an unknown ceremony key still shows something calm (a medal with no art is not a crash)', () {
    expect(ceremonyLine(null).text, He.ceremonyMedal.text);
    expect(ceremonyVoice(TrophyTier.gold), 'vo:core.ceremony.gold');
    expect(ceremonyVoice(null), 'vo:core.ceremony.medal');
  });
}
