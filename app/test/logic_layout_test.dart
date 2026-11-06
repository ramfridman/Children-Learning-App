// The layout rules of the logic land's sweep (2026-11-06): one scale for the row and the answer tiles of an item that compares sizes,
// cells of a row to spot the mistake in that never go under the token's picture size (two lines where one cannot do), larger samples
// on the bins, and one start dot on a pattern to build.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/activity_shell.dart';
import 'package:nitznutz/design/board.dart' show boardClassFor;
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/design/tokens.g.dart';
import 'package:nitznutz/play/choice_row.dart' show withTallStage;
import 'package:nitznutz/play/lesson_screen.dart';
import 'package:nitznutz/play/hints/tap_geometry.dart';
import 'package:nitznutz/play/size_scale.dart';
import 'package:nitznutz/play/template_session.dart' show PackSvg;
import 'package:nitznutz/play/spot_error_session.dart';
import 'package:nitznutz/play/stage_picture.dart';

import 'support/app_harness.dart';
import 'support/harness.dart';
import 'support/language_content.dart';
import 'support/starter.dart';

Future<void> _wait(WidgetTester t, int ms) async {
  for (int spent = 0; spent < ms; spent += 100) {
    await t.pump(const Duration(milliseconds: 100));
  }
  await t.pump(const Duration(milliseconds: 50));
}

/// Opens activity [id] alone in a lesson on a window of [size], of the signed starter pack or of [content].
Future<void> _open(WidgetTester tester, String id, Size size, {PackContent? content}) async {
  final AppRig rig = content == null ? AppRig() : AppRig(content: content);
  await rig.seedFinishedSetup(name: 'נֹעָה');
  await rig.pump(tester, size: size);
  await tester.tap(find.text('נֹעָה'));
  await tester.pumpAndSettle();
  final PackContent played = content ?? await loadStarter();
  final NavigatorState nav = tester.state<NavigatorState>(find.byType(Navigator).first);
  final Lesson one = Lesson.mission(
    id: 'shot',
    itemIds: <String>[id],
    skillIds: played.activities[id]!.skills.map((Skill s) => s.id).toList(),
    celebration: played.lessons['butterflies']!.celebration,
  );
  nav.push(
    MaterialPageRoute<void>(
      builder: (BuildContext c) => LessonScreen(profileId: 'p-1', mission: one),
    ),
  );
  await tester.pump(const Duration(milliseconds: 600));
  await _wait(tester, 1500);
}

const Map<String, Size> _windows = <String, Size>{
  'phone': Size(852, 393),
  'phone SE': Size(667, 375),
  'tablet landscape': Size(1180, 820),
  'tablet portrait': Size(820, 1180),
};

void main() {
  setUpAll(() async {
    await loadAppFonts();
  });

  group('size items', () {
    test(
      'a size family is told by the picture, and an item compares sizes when it draws two of one family',
      () async {
        expect(sizeFamilyOf('asset:ball_size_m'), 'ball');
        expect(sizeFamilyOf('asset:star_size_l'), 'star');
        expect(sizeFamilyOf('asset:tower_4'), 'tower');
        expect(sizeFamilyOf('asset:ball_red'), isNull);
        expect(sizeFamilyOf('asset:apple'), isNull);
        final PackContent content = await loadStarter();
        bool compares(String id) => comparesSizes(content.activities[id]! as TapAnswerActivity);
        expect(compares('log.size.last'), isTrue); // small, medium, ?  and three balls
        expect(compares('b.logb04.5'), isTrue); // towers
        expect(compares('log.next.animals'), isFalse); // a row of unlike things
      },
    );

    for (final MapEntry<String, Size> w in _windows.entries) {
      testWidgets('the row and the answer tiles draw a size picture at one size, ${w.key}', (
        WidgetTester tester,
      ) async {
        await _open(tester, 'log.size.last', w.value);
        final List<Size> sizes = <Size>[
          for (final Element e in find.byKey(const Key('same-scale')).evaluate()) e.size!,
        ];
        // The two pictures of the row and the three of the tiles.
        expect(sizes.length, 5);
        expect(sizes.toSet().length, 1, reason: 'one size for all: $sizes');
        // The box is a row cell, or a tile's picture where the cell is larger.
        final Size stage = tester.getSize(find.byKey(const Key('tap-stage')));
        expect(sizes.first.width, lessThanOrEqualTo(tilePictureSideOf(stage)));
        expect(sizes.first.width, lessThanOrEqualTo((stage.width - 20) / 3 * sizeBleed + 0.01));
      });
    }

    for (final String board in <String>['phone', 'phone SE']) {
      testWidgets(
        'a long row of balls stands in two lines on a taller stage, so that the big ball is 56 and the small 20, $board',
        (WidgetTester tester) async {
          await _open(tester, 'b15.loga06.1', _windows[board]!);
          final List<Size> sizes = <Size>[
            for (final Element e in find.byKey(const Key('same-scale')).evaluate()) e.size!,
          ];
          expect(sizes.length, 8, reason: 'five balls in the row and three on the tiles');
          expect(sizes.toSet().length, 1, reason: 'one size for all: $sizes');
          // The big ball of the sprite is 78 of its 100, the small one 28.
          expect(sizes.first.width * 0.78, greaterThanOrEqualTo(55), reason: '$sizes');
          expect(sizes.first.width * 0.28, greaterThanOrEqualTo(19.5), reason: '$sizes');
          final Rect stage = tester.getRect(find.byKey(const Key('tap-stage')));
          final ActivitySpec base = ActivitySpec.of(boardClassFor(_windows[board]!));
          expect(stage.height, greaterThan(base.stage.height + 15), reason: 'the stage is taller');
          final Rect tile = tester.getRect(find.byKey(const Key('answer-tile')).first);
          expect(tile.bottom, lessThanOrEqualTo(_windows[board]!.height - TokenTouch.bottomNoHotspot));
          // The stage ends over the tiles, with room for a tile that is lifted when it is chosen.
          final double stageBottom =
              stage.bottom + (tester.getTopLeft(find.byKey(const Key('tap-stage'))).dy - stage.top);
          expect(tile.top - stageBottom, greaterThanOrEqualTo(12));
        },
      );
    }

    testWidgets('on a tablet the row of balls stays in one line, with larger tiles', (
      WidgetTester tester,
    ) async {
      await _open(tester, 'b15.loga06.1', _windows['tablet landscape']!);
      final Set<double> lines = <double>{
        for (final Element e
            in find
                .descendant(
                  of: find.byKey(const Key('tap-row')),
                  matching: find.byKey(const Key('same-scale')),
                )
                .evaluate())
          (e.renderObject! as RenderBox).localToGlobal(Offset.zero).dy.roundToDouble(),
      };
      expect(lines.length, 1, reason: 'one line');
      expect(tester.getSize(find.byKey(const Key('answer-tile')).first), const Size(112, 112));
    });

    testWidgets('an item of unlike pictures keeps the room each has', (WidgetTester tester) async {
      await _open(tester, 'log.next.animals', _windows['phone']!);
      expect(find.byKey(const Key('same-scale')), findsNothing);
    });
  });

  group('rows to spot the mistake in', () {
    test(
      'every cell keeps the token picture size on every board, and the cells stand inside the stage, apart',
      () async {
        final PackContent content = await loadStarter();
        final Set<int> lengths = <int>{
          for (final Activity a in content.activities.values)
            if (a is SpotErrorActivity) a.cells.length,
        };
        expect(lengths, contains(8));
        for (final ActivitySpec spec in <ActivitySpec>[
          ActivitySpec.phone,
          ActivitySpec.phoneSE,
          ActivitySpec.tabletLandscape,
          ActivitySpec.tabletPortrait,
        ]) {
          for (final int n in lengths) {
            // The stage a session lays out on: a phone's is made tall where the row needs two lines.
            final bool tall = !spec.stageIsCard && SpotErrorSession.linesOf(spec.stage.size, n) > 1;
            final Rect stageRect = (tall ? withTallStage(spec) : spec).stage;
            final Size stage = spec.stageIsCard
                ? Size(stageRect.width - 32, stageRect.height - 32)
                : stageRect.size;
            final double side = SpotErrorSession.cellSide(stage, n);
            final String where = '$n cells on ${spec.boardHeight}';
            expect(
              side - 16,
              greaterThanOrEqualTo(minPictureOf(stage)),
              reason: 'a picture too small: $where',
            );
            final List<Offset> at = SpotErrorSession.cellCentres(stage, n);
            for (final (int i, Offset c) in at.indexed) {
              expect(
                Rect.fromCenter(center: c, width: side, height: side),
                predicate<Rect>(
                  (Rect r) => r.left >= 0 && r.top >= 0 && r.right <= stage.width && r.bottom <= stage.height,
                  'inside the stage',
                ),
                reason: 'cell $i out of the stage: $where',
              );
              for (int j = i + 1; j < n; j++) {
                expect(
                  (at[j] - c).distance,
                  greaterThanOrEqualTo(side),
                  reason: 'cells $i and $j overlap: $where',
                );
              }
            }
          }
        }
      },
    );

    test('a row that fits in one line of readable cells stays in one line, and reads from the left', () {
      expect(SpotErrorSession.linesOf(ActivitySpec.phone.stage.size, 5), 1);
      expect(SpotErrorSession.linesOf(ActivitySpec.phone.stage.size, 8), 2);
      expect(SpotErrorSession.linesOf(ActivitySpec.phoneSE.stage.size, 4), 1);
      final List<Offset> row = SpotErrorSession.cellCentres(const Size(330, 128), 4);
      expect(row.map((Offset o) => o.dy).toSet().length, 1);
      expect(row.first.dx, lessThan(row.last.dx));
      final List<Offset> two = SpotErrorSession.cellCentres(const Size(330, 253), 8);
      expect(two[0].dx, two[4].dx, reason: 'the second line starts where the first does');
      expect(two[0].dy, lessThan(two[4].dy));
    });

    for (final String board in <String>['phone', 'phone SE']) {
      testWidgets('8 cells are drawn at least as large as the token asks, $board', (
        WidgetTester tester,
      ) async {
        await _open(tester, 'b.logb02.2', _windows[board]!);
        for (int i = 0; i < 8; i++) {
          final Size cell = tester.getSize(find.byKey(Key('cell-$i')));
          expect(
            cell.width - 6 - 16,
            greaterThanOrEqualTo(TokenComponent.stagePictureMin),
            reason: 'cell $i is $cell',
          );
        }
        // The cells stand in the stage, which is as wide as it was and taller.
        final Rect stage = tester.getRect(find.byKey(const Key('spot-stage')));
        for (int i = 0; i < 8; i++) {
          expect(stage.contains(tester.getCenter(find.byKey(Key('cell-$i')))), isTrue);
        }
      });
    }
  });

  group('rows of many cells', () {
    /// A tap-the-answer activity whose row has [n] cells, the last of them the gap.
    TapAnswerActivity rowOf(int n) {
      final LangPack p = LangPack()..addPictures(<String>['cat', 'dog', 'star']);
      p.add(
        tapJson(
          id: 'row$n',
          scene: <String, Object?>{
            'optionsOnTiles': true,
            'row': <String>[
              for (int i = 0; i < n - 1; i++) 'asset:${<String>['cat', 'dog', 'star'][i % 3]}',
              '?',
            ],
          },
          options: <Map<String, Object?>>[
            pictureOption('o1', 'cat'),
            pictureOption('o2', 'dog'),
            pictureOption('o3', 'star'),
          ],
          correct: 'o2',
        ),
      );
      return p.content.activities['eng.row$n']! as TapAnswerActivity;
    }

    for (final (String, ActivitySpec) board in <(String, ActivitySpec)>[
      ('phone', ActivitySpec.phone),
      ('phone SE', ActivitySpec.phoneSE),
      ('tablet landscape', ActivitySpec.tabletLandscape),
      ('tablet portrait', ActivitySpec.tabletPortrait),
    ]) {
      test('a row of 9 keeps every cell at the token picture size or more, ${board.$1}', () {
        final TapAnswerActivity a = rowOf(9);
        final Size stage = TapGeometry.stageSizeOf(board.$2);
        final TapGeometry g = TapGeometry(a, stage, board.$2);
        final List<Rect> cells = g.rowCells();
        expect(cells.length, 9);
        for (final Rect r in cells) {
          expect(r.width, greaterThanOrEqualTo(minPictureOf(stage)), reason: '$r on $stage');
          expect(
            Offset.zero & stage,
            predicate<Rect>((Rect s) => s.contains(r.topLeft) && s.contains(r.bottomRight)),
          );
        }
        for (int i = 0; i < 9; i++) {
          for (int j = i + 1; j < 9; j++) {
            expect(cells[i].overlaps(cells[j]), isFalse, reason: 'cells $i and $j overlap');
          }
        }
        // Read from the left, the lines from the top; the gap is the last cell.
        for (int i = 1; i < 9; i++) {
          final bool next = cells[i].top > cells[i - 1].top + 1;
          expect(
            next || cells[i].left > cells[i - 1].left,
            isTrue,
            reason: 'cell $i is out of reading order',
          );
        }
      });
    }

    test('a row stands in two lines only when its cells would be too small in one', () {
      final Size se = TapGeometry.stageSizeOf(ActivitySpec.phoneSE);
      final Size phone = TapGeometry.stageSizeOf(ActivitySpec.phone);
      expect(TapGeometry.rowLinesOf(rowOf(9), se), 2);
      expect(TapGeometry.rowLinesOf(rowOf(9), phone), 2);
      expect(TapGeometry.rowLinesOf(rowOf(6), se), 1, reason: 'a short row keeps its line');
      expect(TapGeometry.rowLinesOf(rowOf(5), phone), 1);
      // The second line starts where the first does.
      final List<Rect> cells = TapGeometry(rowOf(9), se, ActivitySpec.phoneSE).rowCells();
      expect(cells[0].left, cells[5].left);
    });
  });

  group('tall size pictures (towers)', () {
    // A cube of a tower is 24 of its 220 units.
    // A cube of a tower is 24 of its 220 units, and the picture is cut to [SizeLook.part] of them.
    double cube(double height, SizeLook look) => height * 24 / (220 * look.part.height);

    test(
      'the aspect of a picture is read from its viewBox, and only a size family can make an item tall',
      () async {
        final PackContent content = (await loadSourcePack());
        final TapAnswerActivity towers = content.activities['b.logb04.5']! as TapAnswerActivity;
        expect(spriteAspect(towers.assets.svg('asset:tower_3')), closeTo(100 / 220, 0.001));
        expect(spriteAspect(towers.assets.svg('asset:ball_size_m')), 1);
        expect(spriteAspect('<svg viewBox="0 0 100 100"/>'), 1);
        expect(spriteAspect('<svg/>'), 1);
        // Cut to the ink of the tallest tower of the item (6 cubes) and the floor, the box is wider than the sprite's own 100 by 220.
        expect(sizeLookOfTap(towers)!.aspect, allOf(greaterThan(0.3), lessThan(0.6)));
        expect(TapGeometry.rowIsTall(towers), isTrue);
        final TapAnswerActivity balls = content.activities['log.size.last']! as TapAnswerActivity;
        expect(TapGeometry.rowIsTall(balls), isFalse, reason: 'a square picture keeps its square box');
      },
    );

    for (final (String, ActivitySpec) board in <(String, ActivitySpec)>[
      ('phone', ActivitySpec.phone),
      ('phone SE', ActivitySpec.phoneSE),
      ('tablet landscape', ActivitySpec.tabletLandscape),
      ('tablet portrait', ActivitySpec.tabletPortrait),
    ]) {
      test(
        'every row of towers has its cubes at 10 points or more, in a cell that holds the tower, ${board.$1}',
        () async {
          final PackContent content = await loadSourcePack();
          final Size stage = TapGeometry.stageSizeOf(board.$2);
          int seen = 0;
          for (final TapAnswerActivity a in content.activities.values.whereType<TapAnswerActivity>()) {
            if (!TapGeometry.rowIsTall(a)) continue;
            seen++;
            final Size box = TapGeometry.sameBoxOf(a, stage)!;
            expect(
              cube(box.height, sizeLookOfTap(a)!),
              greaterThanOrEqualTo(10),
              reason: '${a.id}: $box on $stage',
            );
            expect(box.height, lessThanOrEqualTo(tallTilePictureHeightOf(stage)));
            expect(box.width / box.height, closeTo(sizeLookOfTap(a)!.aspect, 0.001));
            for (final Rect r in TapGeometry(a, stage, board.$2).rowCells()) {
              expect(r.width, closeTo(box.width, 0.01));
              expect(r.height, closeTo(box.height, 0.01));
              expect(
                Offset.zero & stage,
                predicate<Rect>((Rect s) => s.contains(r.topLeft) && s.contains(r.bottomRight)),
              );
            }
          }
          expect(seen, greaterThanOrEqualTo(8), reason: 'the towers of LOG-A-10 and LOG-B-04');
        },
      );
    }

    for (final String board in <String>['phone', 'phone SE', 'tablet landscape']) {
      testWidgets('the row and the tiles draw a tower at one size, with cubes to count, $board', (
        WidgetTester tester,
      ) async {
        final PackContent content = (await tester.runAsync(loadSourcePack))!;
        await _open(tester, 'b.logb04.5', _windows[board]!, content: content);
        final List<Size> sizes = <Size>[
          for (final Element e in find.byKey(const Key('same-scale')).evaluate()) e.size!,
        ];
        expect(sizes.length, 6, reason: 'three towers in the row and three on the tiles');
        expect(sizes.toSet().length, 1, reason: '$sizes');
        final SizeLook look = sizeLookOfTap(content.activities['b.logb04.5']! as TapAnswerActivity)!;
        expect(cube(sizes.first.height, look), greaterThanOrEqualTo(10));
        // The tiles are tall, and stay above the edge where no hotspot may be.
        final Rect tile = tester.getRect(find.byKey(const Key('answer-tile')).first);
        expect(
          tile.height,
          tallTileHeightOf(TapGeometry.stageSizeOf(ActivitySpec.of(boardClassFor(_windows[board]!)))),
        );
        expect(tile.bottom, lessThanOrEqualTo(_windows[board]!.height - TokenTouch.bottomNoHotspot));
      });
    }

    for (final String board in <String>['phone', 'phone SE', 'tablet landscape']) {
      testWidgets('a row of towers to spot the mistake in has tall cells with cubes to count, $board', (
        WidgetTester tester,
      ) async {
        final PackContent content = (await tester.runAsync(loadSourcePack))!;
        await _open(tester, 'b.logb11.4', _windows[board]!, content: content);
        final SizeLook look = SpotErrorSession.lookOf(
          content.activities['b.logb11.4']! as SpotErrorActivity,
        )!;
        for (int i = 0; i < 5; i++) {
          final Rect cell = tester.getRect(find.byKey(Key('cell-$i')));
          final Size picture = tester.getSize(
            find.descendant(of: find.byKey(Key('cell-$i')), matching: find.byType(PackSvg)),
          );
          expect(cell.height, greaterThan(cell.width - 6), reason: 'cell $i is tall');
          // The picture is the sprite's own shape (100 by 220), as large as the cell leaves it.
          expect(cube(picture.height, look), greaterThanOrEqualTo(9), reason: 'cell $i on $board: $picture');
        }
      });
    }
    for (final String board in <String>['phone', 'phone SE', 'tablet landscape']) {
      testWidgets('the towers to put in order have cubes to count on their tiles, $board', (
        WidgetTester tester,
      ) async {
        final PackContent content = (await tester.runAsync(loadSourcePack))!;
        await _open(tester, 'b.logb11.1', _windows[board]!, content: content);
        final BuildPatternActivity pattern = content.activities['b.logb11.1']! as BuildPatternActivity;
        final SizeLook look = sizeLookOf(<String>[
          ...pattern.palette,
          ...pattern.sequence,
        ], pattern.assets.svg)!;
        for (int i = 0; i < 5; i++) {
          final Size tile = tester.getSize(
            find.descendant(
              of: find.byKey(Key('palette-$i')),
              matching: find.byKey(const Key('answer-tile')),
            ),
          );
          final Size picture = tester.getSize(
            find.descendant(of: find.byKey(Key('palette-$i')), matching: find.byType(PackSvg)),
          );
          expect(tile.height, tallTileHeight);
          expect(cube(picture.height, look), greaterThanOrEqualTo(10), reason: 'tile $i on $board: $picture');
        }
        final Rect lowest = tester.getRect(find.byKey(const Key('answer-tile')).first);
        expect(lowest.bottom, lessThanOrEqualTo(_windows[board]!.height - TokenTouch.bottomNoHotspot));
      });
    }
  });

  group('bins', () {
    for (final (String, double) c in <(String, double)>[('phone', 40), ('phone SE', 32)]) {
      testWidgets('the sample on a bin is large, ${c.$1}', (WidgetTester tester) async {
        await _open(tester, 'b.logb08.1', _windows[c.$1]!);
        final Finder samples = find.byKey(const Key('bin-sample'));
        expect(samples, findsNWidgets(2));
        for (final Element e in samples.evaluate()) {
          expect(e.size!.shortestSide, greaterThanOrEqualTo(c.$2));
        }
      });
    }
  });

  group('the start dot of a pattern to build', () {
    testWidgets('there is one, under the model, inside the stage', (WidgetTester tester) async {
      await _open(tester, 'b15.loga05.1', _windows['phone']!);
      final Finder dot = find.byKey(const Key('row-start-dot'));
      expect(dot, findsOneWidget);
      final Rect stage = tester.getRect(find.byKey(const Key('pattern-stage')));
      final Rect at = tester.getRect(dot);
      expect(
        stage.contains(at.topLeft) && stage.contains(at.bottomRight),
        isTrue,
        reason: '$at is not in $stage',
      );
      // It is under the model's first cell and over the first place.
      expect(at.top, greaterThan(tester.getRect(find.byKey(const Key('pattern-model'))).top));
      expect(at.bottom, lessThanOrEqualTo(tester.getRect(find.byKey(const Key('slot-0'))).top + 1));
    });
  });
}
