// The owner's phone test of M10 step 0 (2026-11-06): "the entire equation is going outside of the container". Every number sentence of
// tap_answer and spot_error must stand wholly inside the stage's backdrop with clear room at both ends, every number and sign of a row
// is one size, and the row is centred, on every board and at both text scales, for the longest rows of Band C (eleven cells, numbers of
// five digits) as well as the short ones.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/content/pack_validation.dart';
import 'package:nitznutz/content/row_width.dart';
import 'package:nitznutz/play/hints/tap_geometry.dart';
import 'package:nitznutz/play/lesson_screen.dart';

import 'division_sign_test.dart' show signsPack;
import 'support/app_harness.dart';
import 'support/golden_comparator.dart';
import 'support/harness.dart';
import 'support/sample_pack.dart';

/// The boards of the golden tests, a narrow phone in landscape (568 x 320) and a wide screen (1366 x 768).
const List<(String, Size)> _boards = <(String, Size)>[
  ('phone', Size(852, 393)),
  ('phone_se', Size(667, 375)),
  ('tablet_landscape', Size(1180, 820)),
  ('tablet_portrait', Size(820, 1180)),
  ('narrow', Size(568, 320)),
  ('wide', Size(1366, 768)),
];

/// The room kept clear between a glyph and the edge of the backdrop.
const double _room = 12;

Future<void> _wait(WidgetTester t, int ms) async {
  for (int spent = 0; spent < ms; spent += 100) {
    await t.pump(const Duration(milliseconds: 100));
  }
  await t.pump(const Duration(milliseconds: 50));
}

Future<void> _open(WidgetTester tester, PackContent content, String activity) async {
  final NavigatorState nav = tester.state<NavigatorState>(find.byType(Navigator).first);
  nav.push(
    MaterialPageRoute<void>(
      builder: (BuildContext c) => LessonScreen(
        profileId: 'p-1',
        mission: Lesson.mission(
          id: 'signs',
          itemIds: <String>[activity],
          skillIds: <String>['NUM-A-03'],
          celebration: content.lessons['butterflies']!.celebration,
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 600));
  await _wait(tester, 1500);
}

/// Opens [activity] on [size] at text scale [scale] and checks the row inside [rowKey]'s stage [stageKey].
Future<void> _check(
  WidgetTester tester,
  String activity,
  Size size,
  double scale,
  Key stageKey,
  Key rowKey, {
  Set<String> unequal = const <String>{'?'},
}) async {
  final PackContent content = signsPack();
  final AppRig rig = AppRig(content: content);
  await rig.seedFinishedSetup(name: 'נֹעָה');
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await rig.pump(tester, size: size);
  await tester.tap(find.text('נֹעָה'));
  await tester.pumpAndSettle();
  await _open(tester, content, activity);
  final Rect stage = tester.getRect(find.byKey(stageKey));
  final Rect inner = stage.deflate(_room);
  final Finder glyphs = find.descendant(of: find.byKey(rowKey), matching: find.byType(Text));
  expect(glyphs, findsWidgets);
  final List<Rect> rects = <Rect>[];
  final Set<double> sizes = <double>{};
  for (final Element e in glyphs.evaluate()) {
    final Text t = e.widget as Text;
    final Rect r = tester.getRect(find.byWidget(t));
    rects.add(r);
    expect(
      inner.contains(r.topLeft) && inner.contains(r.bottomRight),
      isTrue,
      reason: '"${t.data}" at $r is not inside the backdrop $stage less $_room on $size, text scale $scale',
    );
    if (!unequal.contains(t.data)) sizes.add(t.style!.fontSize!);
  }
  expect(sizes, hasLength(1), reason: 'the numbers and signs are not one size on $size: $sizes');
  // Centred: the room left and right of the glyphs differs by less than a number's width at that size.
  final double left =
      rects.map((Rect r) => r.left).reduce((double a, double b) => a < b ? a : b) - stage.left;
  final double right =
      stage.right - rects.map((Rect r) => r.right).reduce((double a, double b) => a > b ? a : b);
  expect(
    (left - right).abs(),
    lessThan(sizes.first),
    reason: 'not centred on $size: $left left, $right right',
  );
  expect(tester.takeException(), isNull);
}

void main() {
  setUpAll(() async {
    await loadAppFonts();
    useTolerantGoldens(0.03);
  });

  group('the row of a tap_answer sentence', () {
    for (final (String, Size) b in _boards) {
      for (final String row in <String>['div.row', 'big.row']) {
        for (final double scale
            in b.$1 == 'phone' || b.$1 == 'phone_se' || b.$1 == 'narrow'
                ? <double>[1.0, 1.3]
                : <double>[1.0]) {
          testWidgets('$row stands inside the backdrop, ${b.$1}, text scale $scale', (
            WidgetTester tester,
          ) async {
            await _check(tester, row, b.$2, scale, const Key('tap-stage'), const Key('tap-row'));
          });
        }
      }
    }
  });

  group('the row of a spot_error sentence', () {
    for (final (String, Size) b in _boards) {
      for (final String row in <String>['times.spot', 'big.spot']) {
        testWidgets('$row stands inside the backdrop, ${b.$1}', (WidgetTester tester) async {
          await _check(tester, row, b.$2, 1.0, const Key('spot-stage'), const Key('spot-stage'));
        });
      }
    }
  });

  group('the layout of a row', () {
    TapAnswerActivity sentence(List<Object?> cells) {
      final SamplePack p = SamplePack();
      final Map<String, Object?> doc = Map<String, Object?>.of(p.docs[tapFile]! as Map<String, Object?>);
      doc['scene'] = <String, Object?>{'background': 'asset:meadow', 'row': cells};
      return Activity.fromJson(doc, PackContent.fromPack(p.verified()).assets) as TapAnswerActivity;
    }

    test(
      'the cells of a row of numbers and signs fit between the two edges, whatever the row, on every stage',
      () {
        for (final Size stage in <Size>[
          const Size(270, 104),
          const Size(330, 128),
          const Size(584, 300),
          const Size(772, 300),
          const Size(200, 120),
        ]) {
          for (final List<Object?> cells in <List<Object?>>[
            <Object?>['n:12', 'op::', 'n:3', 'op:=', '?'],
            <Object?>[
              'op:(',
              'n:10000',
              'op:+',
              'n:2500',
              'op:)',
              'op:x',
              'n:3',
              'op:<',
              'n:9999',
              'op:=',
              '?',
            ],
            <Object?>['n:1', 'op:+', 'n:1', 'op:=', '?'],
          ]) {
            final TapAnswerActivity a = sentence(cells);
            final ({List<double> widths, double textSize}) layout = TapGeometry.rowLayoutOf(a, stage);
            final double total = layout.widths.fold<double>(0, (double s, double x) => s + x);
            expect(
              total,
              lessThanOrEqualTo(stage.width - 2 * TapGeometry.rowEdge + 0.001),
              reason: '$cells on $stage',
            );
            expect(layout.textSize, greaterThan(0));
          }
        }
      },
    );

    test('a row of pictures keeps cells of one width, filling the stage but for 10 points at each end', () {
      final TapAnswerActivity a = sentence(<Object?>['asset:flower_red', 'asset:flower_red', '?']);
      final ({List<double> widths, double textSize}) layout = TapGeometry.rowLayoutOf(
        a,
        const Size(330, 128),
      );
      expect(layout.widths, <double>[310 / 3, 310 / 3, 310 / 3]);
    });
  });

  group('the validator refuses a row too wide to read', () {
    List<String> problems(List<Object?> cells) {
      final SamplePack p = SamplePack();
      final Map<String, Object?> doc = p.docs[tapFile]! as Map<String, Object?>;
      doc['band'] = 'C';
      doc['templateVersion'] = '1.4';
      (p.manifest['templates']! as Map<String, Object?>)['tap_answer'] = '1.4';
      doc['scene'] = <String, Object?>{'background': 'asset:meadow', 'row': cells};
      return <String>[
        for (final x in validatePack(manifest: p.manifest, docs: p.docs, files: p.files))
          if (x.toString().contains('too wide')) x.toString(),
      ];
    }

    test('eleven cells with two numbers of five digits are the longest that pass', () {
      expect(
        rowEm(<String>[
          'op:(',
          'n:10000',
          'op:+',
          'n:2500',
          'op:)',
          'op:x',
          'n:3',
          'op:<',
          'n:9999',
          'op:=',
          '?',
        ]),
        lessThanOrEqualTo(maxRowEm),
      );
      expect(
        problems(<Object?>[
          'op:(',
          'n:10000',
          'op:+',
          'n:2500',
          'op:)',
          'op:x',
          'n:3',
          'op:<',
          'n:9999',
          'op:=',
          '?',
        ]),
        isEmpty,
      );
      expect(
        problems(<Object?>['n:10000', 'op:+', 'n:10000', 'op:+', 'n:10000', 'op:+', 'n:10000', 'op:=', '?']),
        hasLength(1),
      );
    });
  });
}
