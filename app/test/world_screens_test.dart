// The island of a land and Sticker Island (M8): what a child sees of the world growing, the bell flag that opens a short
// revisit mission, and the stickers kept. Goldens are in right to left with the real fonts and a tolerance of 3 percent.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/app/reward_providers.dart';
import 'package:nitznutz/app/world_providers.dart';
import 'package:nitznutz/child/home_screen.dart';
import 'package:nitznutz/child/land_screen.dart';
import 'package:nitznutz/child/sticker_island.dart';
import 'package:nitznutz/content/engine_adapter.dart';
import 'package:nitznutz/content/models.dart' show Lesson, PackContent;
import 'package:nitznutz/engine/engine.dart';
import 'package:nitznutz/play/activity_frame.dart';
import 'package:nitznutz/play/lesson_screen.dart';
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/rewards/award.dart';
import 'package:nitznutz/rewards/sticker_design.dart';
import 'package:nitznutz/world/world_state.dart';

import 'engine/fixtures.dart';
import 'support/app_harness.dart';
import 'support/golden_comparator.dart';
import 'support/harness.dart';
import 'support/starter.dart';

const String child = 'p-1';

WorldObject object(String id, GrowthStage stage, {bool bell = false, String art = 'stair'}) =>
    WorldObject(skillId: id, title: 'skill $id', objectId: art, stage: stage, bell: bell);

Override worldOf(List<WorldObject> objects) => worldProvider(child).overrideWith(
  (Ref ref) async => WorldView(
    engine: engineOf(smallCatalog()),
    now: day0,
    lands: <TrophyLand, List<WorldObject>>{TrophyLand.counting: objects},
  ),
);

Reward sticker(int id, String key) => Reward(
  id: id,
  profileId: child,
  awardKey: key,
  kind: 'sticker',
  at: day0,
  seenAt: day0,
  eventId: null,
  syncedAt: null,
);

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
  await pumpScreen(
    tester,
    ProviderScope(overrides: overrides, child: screen),
    size: size,
  );
  await tester.pumpAndSettle();
}

/// The pack and the world are read from disk, which a test's fake clock does not wait for: give real time to finish.
Future<void> loaded(WidgetTester tester) async {
  for (int i = 0; i < 6; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 40)));
    await tester.pump();
  }
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await loadAppFonts();
    useTolerantGoldens(0.03);
  });

  group('the island of a land', () {
    final List<WorldObject> grown = <WorldObject>[
      object('SK-A-01', GrowthStage.fruit),
      object('SK-B-01', GrowthStage.colour),
      object('SK-C-01', GrowthStage.sketch),
      object('SK-D-01', GrowthStage.fruit, bell: true),
    ];

    testWidgets(
      'every skill has an object: a sketch, colour, or fruit with a golden star, and a bell flag with a dry leaf when a check is due',
      (WidgetTester tester) async {
        await pumpIn(tester, const LandScreen(childId: child, land: TrophyLand.counting), <Override>[
          worldOf(grown),
        ]);
        for (final String id in <String>['SK-A-01', 'SK-B-01', 'SK-C-01', 'SK-D-01']) {
          expect(find.byKey(Key('object-$id')), findsOneWidget);
        }
        expect(find.byKey(const Key('star-SK-A-01')), findsOneWidget);
        expect(
          find.byKey(const Key('star-SK-D-01')),
          findsOneWidget,
          reason: 'a skill that needs a check keeps its star',
        );
        expect(find.byKey(const Key('star-SK-B-01')), findsNothing);
        expect(find.byKey(const Key('star-SK-C-01')), findsNothing);
        expect(find.byKey(const Key('bell-SK-D-01')), findsOneWidget);
        expect(find.byKey(const Key('leaf-SK-D-01')), findsOneWidget);
        expect(find.byKey(const Key('bell-SK-A-01')), findsNothing);
        await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/land_island_phone.png'));
      },
    );

    testWidgets('the decorations the child has earned stand on the island, and none before they are earned', (
      WidgetTester tester,
    ) async {
      await pumpIn(tester, const LandScreen(childId: child, land: TrophyLand.counting), <Override>[
        worldOf(grown),
        rewardsProvider(child).overrideWith((Ref ref) async => <Reward>[]),
      ]);
      for (final int n in <int>[10, 20, 30]) {
        expect(find.byKey(Key('island-deco-$n')), findsNothing);
      }
      Reward deco(int id, int n) => Reward(
        id: id,
        profileId: child,
        awardKey: 'deco:$n',
        kind: 'decoration',
        at: day0,
        seenAt: day0,
        eventId: null,
        syncedAt: null,
      );
      await pumpIn(tester, const LandScreen(childId: child, land: TrophyLand.counting), <Override>[
        worldOf(grown),
        rewardsProvider(child).overrideWith((Ref ref) async => <Reward>[deco(1, 10), deco(2, 20)]),
      ]);
      expect(find.byKey(const Key('island-deco-10')), findsOneWidget);
      expect(find.byKey(const Key('island-deco-20')), findsOneWidget);
      expect(find.byKey(const Key('island-deco-30')), findsNothing);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/land_island_decorated_phone.png'),
      );
    });

    testWidgets('the island fits a small phone and a tablet', (WidgetTester tester) async {
      for (final Size size in <Size>[const Size(667, 375), const Size(1180, 820), const Size(820, 1180)]) {
        await pumpIn(tester, const LandScreen(childId: child, land: TrophyLand.counting), <Override>[
          worldOf(grown),
        ], size: size);
        expect(tester.takeException(), isNull, reason: '$size');
      }
    });

    testWidgets('only a bell flag can be tapped, and it opens a short mission for that skill', (
      WidgetTester tester,
    ) async {
      Lesson? opened;
      await pumpIn(
        tester,
        LandScreen(childId: child, land: TrophyLand.counting, onMission: (Lesson m) => opened = m),
        <Override>[
          worldProvider(child).overrideWith(
            (Ref ref) async => WorldView(
              engine: engineOf(smallCatalog()),
              now: day0,
              lands: <TrophyLand, List<WorldObject>>{
                TrophyLand.counting: <WorldObject>[
                  object('SK-A-01', GrowthStage.fruit, bell: true),
                  object('SK-B-01', GrowthStage.colour),
                ],
              },
            ),
          ),
        ],
      );
      await tester.tap(find.byKey(const Key('object-SK-B-01')));
      await tester.pump();
      expect(opened, isNull, reason: 'an object without a bell does nothing');
      await tester.tap(find.byKey(const Key('object-SK-A-01')));
      await tester.pump();
      expect(opened, isNotNull);
      expect(opened!.skillIds, <String>['SK-A-01']);
      expect(opened!.itemIds.length, inInclusiveRange(3, 5));
      expect(opened!.celebration.vo, 'vo:core.celebrate.well');
    });

    testWidgets('a land with a lesson has a play button; one without has none', (WidgetTester tester) async {
      int played = 0;
      await pumpIn(
        tester,
        LandScreen(childId: child, land: TrophyLand.counting, onPlay: () => played++),
        <Override>[worldOf(grown)],
      );
      await tester.tap(find.byKey(const Key('land-play')));
      expect(played, 1);
      await pumpIn(tester, const LandScreen(childId: child, land: TrophyLand.counting), <Override>[
        worldOf(grown),
      ]);
      expect(find.byKey(const Key('land-play')), findsNothing);
    });
  });

  group('on the map', () {
    testWidgets(
      'the golden stars show with their number, the sticker button opens Sticker Island, a land opens its island',
      (WidgetTester tester) async {
        final AppRig rig = AppRig();
        await rig.seedFinishedSetup();
        for (final String skill in <String>['NUM-A-03', 'NUM-A-04']) {
          await rig.db.addReward(
            RewardsCompanion.insert(profileId: child, awardKey: 'star:$skill', kind: 'star', at: day0),
          );
        }
        await rig.db.addReward(
          RewardsCompanion.insert(
            profileId: child,
            awardKey: 'sticker:butterflies:1',
            kind: 'sticker',
            at: day0,
          ),
        );
        await rig.pump(tester);
        await tester.tap(find.text('נועה'));
        await tester.pumpAndSettle();
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(
          find.descendant(of: find.byKey(const Key('home-stars')), matching: find.text('2')),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const Key('home-stickers')));
        await tester.pumpAndSettle();
        expect(find.byType(StickerIsland), findsOneWidget);
        expect(find.byKey(const Key('sticker-sticker:butterflies:1')), findsOneWidget);
        await tester.tap(find.byKey(const Key('stickers-back')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('land-tap-counting')));
        await tester.pumpAndSettle();
        expect(find.byType(LandScreen), findsOneWidget);
        expect(find.byKey(const Key('object-NUM-A-03')), findsOneWidget);
        expect(
          find.byKey(const Key('star-NUM-A-03')),
          findsOneWidget,
          reason: 'the star the child was given shows on its object',
        );
        expect(find.byKey(const Key('land-play')), findsOneWidget);
      },
    );

    testWidgets('a child with nothing yet sees no star counter, and the colours land opens too', (
      WidgetTester tester,
    ) async {
      final AppRig rig = AppRig();
      await rig.seedFinishedSetup();
      await rig.pump(tester);
      await tester.tap(find.text('נועה'));
      await loaded(tester);
      expect(find.byKey(const Key('home-stars')), findsNothing);
      expect(find.byKey(const Key('home-stickers')), findsOneWidget);
      await tester.tap(find.byKey(const Key('land-tap-colors')));
      await loaded(tester);
      expect(find.byType(LandScreen), findsOneWidget);
      expect(find.byKey(const Key('object-COL-A-02')), findsOneWidget);
    });
  });

  group('a revisit mission', () {
    testWidgets(
      'made from the real starter pack it is a lesson of its own: it plays, and is a visit named for the skill',
      (WidgetTester tester) async {
        final PackContent content = await loadStarter();
        final Engine engine = Engine(catalog: engineCatalog(content));
        final WorldView view = WorldView(
          engine: engine,
          now: day0,
          lands: const <TrophyLand, List<WorldObject>>{},
        );
        final Lesson mission = view.missionFor('NUM-A-03')!;
        expect(mission.itemIds.length, inInclusiveRange(3, 5));
        for (final String id in mission.itemIds) {
          expect(content.activities.containsKey(id), isTrue, reason: id);
        }
        final AppRig rig = AppRig();
        await rig.seedFinishedSetup();
        addTearDown(rig.db.close);
        await pumpScreen(
          tester,
          ProviderScope(
            overrides: rig.overrides,
            child: LessonScreen(profileId: child, mission: mission),
          ),
        );
        for (int i = 0; i < 40; i++) {
          await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 40)));
          await tester.pump(const Duration(milliseconds: 100));
          if (find.byType(ActivityFrame).evaluate().isNotEmpty) break;
        }
        expect(find.byType(ActivityFrame), findsOneWidget);
        expect((await rig.db.sessionsOf(child)).single.plan, 'mission:num-a-03');
      },
    );
  });

  group('Sticker Island', () {
    testWidgets('shows every sticker the child has, each as its own drawing', (WidgetTester tester) async {
      final List<Reward> mine = <Reward>[
        sticker(1, 'sticker:butterflies:1'),
        sticker(2, 'sticker:butterflies:2'),
        sticker(3, 'sticker:butterflies:3'),
      ];
      await pumpIn(tester, const StickerIsland(childId: child), <Override>[
        stickersProvider(child).overrideWith((Ref ref) async => mine),
      ]);
      for (final Reward r in mine) {
        expect(find.byKey(Key('sticker-${r.awardKey}')), findsOneWidget);
      }
      expect(find.byKey(const Key('stickers-empty')), findsNothing);
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/sticker_island_phone.png'));
    });

    testWidgets('with none yet it says so calmly', (WidgetTester tester) async {
      await pumpIn(tester, const StickerIsland(childId: child), <Override>[
        stickersProvider(child).overrideWith((Ref ref) async => <Reward>[]),
      ]);
      expect(find.byKey(const Key('stickers-empty')), findsOneWidget);
    });

    test(
      'a sticker is always the same drawing, and a lesson\'s stickers follow each other round the set',
      () {
        expect(stickerDesign('sticker:butterflies:1'), stickerDesign('sticker:butterflies:1'));
        final List<int> designs = <int>[
          for (int n = 1; n <= stickerDesigns; n++) stickerDesign('sticker:butterflies:$n'),
        ];
        expect(designs.toSet().length, stickerDesigns, reason: 'twelve lessons, twelve different drawings');
        expect(designs.every((int d) => d >= 1 && d <= stickerDesigns), isTrue);
      },
    );
  });
}
