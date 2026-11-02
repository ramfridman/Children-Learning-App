// QA for B-45 job "the map-card line is voiced": the REAL 100 childLines of the bundled starter pack on a land map and in the
// Trophy Hall, on the four boards (phone, phoneSE, tablet landscape, tablet portrait) at text scale 1.0 and 1.3.
// Checks: no overflow, the card stays on the screen, the card covers neither the title, the back button, the play button nor
// the legend, and a touch on every star line of the hall (after scrolling the card) is heard. Writes the PNGs the audit looked at
// to docs/qa/b45-childline-*.png (only when QA_B45_SHOTS=1, so a normal run writes nothing).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/app/companion.dart';
import 'package:nitznutz/app/reward_providers.dart';
import 'package:nitznutz/app/ribbon_providers.dart';
import 'package:nitznutz/app/world_providers.dart';
import 'package:nitznutz/child/land_screen.dart';
import 'package:nitznutz/child/trophy_hall.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/design/board.dart';
import 'package:nitznutz/design/components.dart' show SpeakerMark;
import 'package:nitznutz/rewards/award.dart';
import 'package:nitznutz/voice/voice_director.dart';
import 'package:nitznutz/world/world_state.dart';

import 'engine/fixtures.dart';
import 'support/harness.dart';
import 'support/starter.dart';
import 'support/voice_fixtures.dart';

const String child = 'p-1';
final bool shots = Platform.environment['QA_B45_SHOTS'] == '1';

/// Where the PNGs go (QA_B45_SHOTS_DIR, or docs/qa).
final String shotsDir = Platform.environment['QA_B45_SHOTS_DIR'] ?? '../docs/qa';

final List<(String, Size)> boards = <(String, Size)>[
  ('phone', BoardClass.phone.size),
  ('phoneSE', BoardClass.phoneSE.size),
  ('tabletL', BoardClass.tabletLandscape.size),
  ('tabletP', BoardClass.tabletPortrait.size),
];

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

/// The real world of the starter pack: every skill with its own childLine, the stage cycling sketch / colour / fruit.
Map<TrophyLand, List<WorldObject>> realLands(PackContent content) {
  final Map<TrophyLand, List<WorldObject>> out = <TrophyLand, List<WorldObject>>{};
  final List<String> ids = content.skills.keys.toList()..sort();
  int i = 0;
  for (final String id in ids) {
    final SkillDoc s = content.skills[id]!;
    final TrophyLand? land = TrophyLand.ofDomain(s.domain);
    if (land == null) continue;
    (out[land] ??= <WorldObject>[]).add(
      WorldObject(
        skillId: s.id,
        title: s.title,
        objectId: 'stair',
        stage: GrowthStage.values[i++ % 3],
        bell: false,
        line: s.childLine,
      ),
    );
  }
  return out;
}

Future<void> pump(
  WidgetTester tester,
  Widget screen,
  Size size,
  double scale,
  List<Override> overrides,
  GlobalKey shot,
) async {
  await tester.pumpWidget(const SizedBox.shrink());
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await pumpScreen(
    tester,
    ProviderScope(
      overrides: <Override>[voicePlayerProvider.overrideWithValue(FakePlayer()), ...overrides],
      child: Builder(
        builder: (BuildContext c) => MediaQuery(
          data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)),
          child: RepaintBoundary(key: shot, child: screen),
        ),
      ),
    ),
    size: size,
  );
  await tester.pumpAndSettle();
}

Future<void> save(WidgetTester tester, GlobalKey shot, String name) async {
  if (!shots) return;
  final RenderRepaintBoundary rb = shot.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final List<int> bytes = (await tester.runAsync(() async {
    final ui.Image im = await rb.toImage();
    return (await im.toByteData(format: ui.ImageByteFormat.png))!.buffer.asUint8List();
  }))!;
  File('$shotsDir/b45-childline-$name.png').writeAsBytesSync(bytes);
}

bool overlap(Rect a, Rect b) => a.overlaps(b.deflate(0.5));

void main() {
  late PackContent content;
  late Map<TrophyLand, List<WorldObject>> lands;

  setUpAll(() async {
    await loadAppFonts();
    content = await loadStarter();
    lands = realLands(content);
  });

  test('the starter pack has 100 skills with a childLine, spread over the six lands', () {
    expect(content.skills.values.where((SkillDoc s) => s.childLine != null).length, 100);
    expect(lands.keys.length, 6);
    // ignore: avoid_print
    print('objects per land: ${<String, int>{for (final e in lands.entries) e.key.name: e.value.length}}');
  });

  group('the card of a touched picture on a land map', () {
    for (final (String name, Size size) in boards) {
      for (final double scale in <double>[1.0, 1.3]) {
        testWidgets('$name at text $scale: every land, its longest line', (WidgetTester tester) async {
          final List<String> notes = <String>[];
          for (final TrophyLand land in TrophyLand.values) {
            final List<WorldObject> objects = lands[land]!;
            final WorldObject longest = objects.reduce(
              (WorldObject a, WorldObject b) => a.line!.length >= b.line!.length ? a : b,
            );
            final GlobalKey shot = GlobalKey();
            await pump(tester, LandScreen(childId: child, land: land, onPlay: () {}), size, scale, <Override>[
              worldProvider(child).overrideWith(
                (Ref ref) async => WorldView(
                  engine: engineOf(smallCatalog()),
                  now: day0,
                  lands: <TrophyLand, List<WorldObject>>{land: objects},
                ),
              ),
            ], shot);
            // The smallest picture: the island shrinks them to fit, down to 44.
            final double smallest = objects
                .map((WorldObject o) => tester.getSize(find.byKey(Key('object-${o.skillId}'))).shortestSide)
                .reduce((double a, double b) => a < b ? a : b);
            await tester.ensureVisible(find.byKey(Key('object-${longest.skillId}')));
            await tester.tap(find.byKey(Key('object-${longest.skillId}')));
            await tester.pump(const Duration(milliseconds: 200));
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull, reason: '$name $scale ${land.name}: overflow or error');
            if (land == TrophyLand.counting) await save(tester, shot, 'land-$name-$scale-counting');
            if (land == TrophyLand.logic && scale == 1.3) await save(tester, shot, 'land-$name-$scale-logic');
            final Rect card = tester.getRect(find.byKey(const Key('land-object-card')));
            final Rect screen = Offset.zero & size;
            expect(
              screen.contains(card.topLeft) && screen.contains(card.bottomRight),
              isTrue,
              reason: '$name $scale ${land.name}: the card $card leaves the screen $screen',
            );
            final Map<String, Rect> others = <String, Rect>{
              'land-title': tester.getRect(find.byKey(const Key('land-title'))),
              'land-back': tester.getRect(find.byKey(const Key('land-back'))),
              'land-play': tester.getRect(find.byKey(const Key('land-play'))),
              'land-legend': tester.getRect(find.byKey(const Key('land-legend'))),
            };
            for (final MapEntry<String, Rect> e in others.entries) {
              // QA-B45-CL-1 (fixed): the card has the band between the title and the drawings, at 1.0 and at 1.3.
              expect(
                overlap(card, e.value),
                isFalse,
                reason: '$name $scale ${land.name}: the card covers ${e.key}',
              );
            }
            // The card sits over the top of the picture area; how many VISIBLE pictures (inside the island's scroll view) does it hide?
            final Rect room = Rect.fromLTRB(56, 146, size.width - 56, size.height - 136);
            final List<String> hidden = <String>[
              for (final WorldObject o in objects)
                if (overlap(card, tester.getRect(find.byKey(Key('object-${o.skillId}'))).intersect(room)))
                  o.skillId,
            ];
            // QA-B45-CL-1 (fixed): no tappable picture is under the card, and the card stays above the drawings' room.
            expect(hidden, isEmpty, reason: '$name $scale ${land.name}: the card $card covers $hidden');
            expect(
              card.bottom <= room.top,
              isTrue,
              reason: '$name $scale ${land.name}: the card $card reaches the room',
            );
            // The speaker mark shows that the line speaks.
            expect(
              find.descendant(
                of: find.byKey(const Key('land-object-card')),
                matching: find.byType(SpeakerMark),
              ),
              findsOneWidget,
            );
            notes.add(
              '${land.name}: ${objects.length} pictures, smallest ${smallest.toStringAsFixed(0)} pt, card h '
              '${card.height.toStringAsFixed(0)} bottom ${card.bottom.toStringAsFixed(0)}, '
              'pictures under the card: ${hidden.length}',
            );
          }
          // ignore: avoid_print
          print('LAND $name text $scale\n  ${notes.join('\n  ')}');
        });
      }
    }
  });

  group('the Trophy Hall card', () {
    // The land whose three longest lines are the longest in all (the card shows three star lines).
    TrophyLand worst() {
      int total(TrophyLand l) {
        final List<int> n = lands[l]!.map((WorldObject o) => o.line!.length).toList()..sort();
        return n.reversed.take(3).fold(0, (int a, int b) => a + b);
      }

      return TrophyLand.values.reduce((TrophyLand a, TrophyLand b) => total(a) >= total(b) ? a : b);
    }

    for (final (String name, Size size) in boards) {
      for (final double scale in <double>[1.0, 1.3]) {
        for (final bool shortest in <bool>[false, true]) {
          testWidgets(
            '$name at text $scale${shortest ? ' (the shortest lines)' : ''}: the card scrolls and every star line is reachable and heard',
            (WidgetTester tester) async {
              final TrophyLand land = shortest ? TrophyLand.logic : worst();
              // Longest (or shortest) lines first: the card takes the first three stars of the land, in the land's order.
              final List<WorldObject> sorted = List<WorldObject>.of(lands[land]!)
                ..sort(
                  (WorldObject a, WorldObject b) => shortest
                      ? a.line!.length.compareTo(b.line!.length)
                      : b.line!.length.compareTo(a.line!.length),
                );
              final List<WorldObject> objects = <WorldObject>[
                for (final WorldObject o in sorted)
                  WorldObject(
                    skillId: o.skillId,
                    title: o.title,
                    objectId: o.objectId,
                    stage: GrowthStage.fruit,
                    bell: false,
                    line: o.line,
                  ),
              ];
              final FakePlayer player = FakePlayer();
              final VoiceDirector director = VoiceDirector(player: player);
              addTearDown(director.dispose);
              final GlobalKey shot = GlobalKey();
              await pump(tester, const TrophyHall(childId: child), size, scale, <Override>[
                voiceDirectorProvider.overrideWithValue(director),
                rewardsProvider(child).overrideWith(
                  (Ref ref) async => <Reward>[reward(1, 'trophy:${land.name}:bronze', 'trophy')],
                ),
                ribbonsProvider(child).overrideWith((Ref ref) async => const <String, String>{}),
                worldProvider(child).overrideWith(
                  (Ref ref) async => WorldView(
                    engine: engineOf(smallCatalog()),
                    now: day0,
                    lands: <TrophyLand, List<WorldObject>>{land: objects},
                  ),
                ),
              ], shot);
              // The shelf is brought to the middle of the list (a child scrolls to it), not to its top edge, where the
              // land's name above the trophies would be cut by the edge of the list.
              await Scrollable.ensureVisible(
                tester.element(find.byKey(Key('slot-trophy:${land.name}:bronze'))),
                alignment: 0.5,
              );
              await tester.pumpAndSettle();
              await tester.tap(find.byKey(Key('slot-trophy:${land.name}:bronze')));
              await tester.pumpAndSettle();
              expect(tester.takeException(), isNull, reason: '$name $scale: overflow or error');
              final Finder scroller = find.ancestor(
                of: find.byKey(const Key('hall-card')),
                matching: find.byType(SingleChildScrollView),
              );
              expect(scroller, findsOneWidget);
              final Rect view = tester.getRect(scroller);
              final ScrollableState sc = tester.state(
                find.descendant(of: scroller, matching: find.byType(Scrollable)),
              );
              final double extent = sc.position.maxScrollExtent;
              final List<String> shown = <String>[
                for (final WorldObject o in objects.take(3))
                  if (find.byKey(Key('hall-say-${o.skillId}')).evaluate().isNotEmpty) o.skillId,
              ];
              expect(shown.length, 3, reason: 'three star lines');
              await save(tester, shot, 'hall-$name-$scale${shortest ? '-short' : ''}-top');
              String lines(String id) =>
                  objects.firstWhere((WorldObject o) => o.skillId == id).line!.length.toString();
              final List<String> small = <String>[];
              final List<double> heights = <double>[];
              int heard = 0;
              for (final String id in shown) {
                final Finder row = find.byKey(Key('hall-say-$id'));
                final Size rs = tester.getSize(row);
                heights.add(rs.height);
                if (rs.height < 56) small.add('$id ${rs.height.toStringAsFixed(0)}pt (${lines(id)} chars)');
                // The speaker mark shows that the line speaks.
                expect(find.descendant(of: row, matching: find.byType(SpeakerMark)), findsOneWidget);
                await tester.ensureVisible(row);
                await tester.pumpAndSettle();
                final Rect r = tester.getRect(row);
                expect(
                  r.top >= view.top - 0.5 && r.bottom <= view.bottom + 0.5,
                  isTrue,
                  reason:
                      '$name $scale: $id row $r is not inside the scroll view $view after scrolling to it',
                );
                await tester.tap(row);
                await tester.pump();
                heard++;
              }
              // QA-B45-CL-2 (fixed): every star line is a child target, at least 56 pt tall (the hall uses band A's 64).
              expect(small, isEmpty, reason: '$name $scale: star rows under 56 pt: $small');
              await tester.drag(scroller, const Offset(0, -2000));
              await tester.pumpAndSettle();
              final Rect replay = tester.getRect(find.byKey(const Key('hall-replay')));
              expect(
                replay.bottom <= view.bottom + 0.5 && replay.top >= view.top - 0.5,
                isTrue,
                reason: '$name $scale: the replay button $replay is not reachable (view $view)',
              );
              await save(tester, shot, 'hall-$name-$scale${shortest ? '-short' : ''}-bottom');
              // ignore: avoid_print
              print(
                'HALL${shortest ? ' SHORT' : ''} $name text $scale: land ${land.name}, scroll extent ${extent.toStringAsFixed(0)} pt, view h '
                '${view.height.toStringAsFixed(0)}, lines tapped $heard, rows under 56 pt: ${small.isEmpty ? 'none' : small}',
              );
            },
          );
        }
      }
    }
  });

  group('the Trophy Hall shelves (QA-B45-CL-3)', () {
    for (final (String name, Size size) in boards) {
      testWidgets('$name at text 1.3: the name of the first shelf is whole when the hall opens', (
        WidgetTester tester,
      ) async {
        final GlobalKey shot = GlobalKey();
        await pump(tester, const TrophyHall(childId: child), size, 1.3, <Override>[
          rewardsProvider(child).overrideWith((Ref ref) async => const <Reward>[]),
          ribbonsProvider(child).overrideWith((Ref ref) async => const <String, String>{}),
          worldProvider(child).overrideWith(
            (Ref ref) async => WorldView(engine: engineOf(smallCatalog()), now: day0, lands: lands),
          ),
        ], shot);
        expect(tester.takeException(), isNull);
        final Finder list = find.ancestor(
          of: find.byKey(const Key('shelf-stars-counting')),
          matching: find.byType(ListView),
        );
        final Rect view = tester.getRect(list);
        final Finder labelBox = find
            .ancestor(of: find.byKey(const Key('shelf-stars-counting')), matching: find.byType(Column))
            .first;
        final Rect label = tester.getRect(labelBox);
        expect(
          label.top >= view.top - 0.5,
          isTrue,
          reason: '$name: the first shelf name $label is cut by the list $view',
        );
        await save(tester, shot, 'hall-$name-1.3-shelves');
      });
    }
  });
}
