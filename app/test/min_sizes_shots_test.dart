// A picture-taking tool for the minimum-sizes round (docs/design/m11/min-sizes.md): every template of the unit shots, on the four boards, written as
// PNG files (1 pixel = 1 point) into the folder named by the SHOTS_DIR environment variable, for the contact sheets in
// docs/design/m11/min-sizes/after/. They are not goldens and nothing is compared. Without SHOTS_DIR the test does nothing.
//
// Run:  $env:SHOTS_DIR = 'C:\some\folder'; flutter test test/min_sizes_shots_test.dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/play/lesson_screen.dart';

import 'support/app_harness.dart';
import 'support/c1_screens.dart' show boards;
import 'support/harness.dart';
import 'support/starter.dart';

/// (activity, name of the picture)
const List<(String, String)> _items = <(String, String)>[
  ('next.after.2', 'next_number'),
  ('flash.dice.3', 'flash_dice'),
  ('numeral.stars.3', 'set_to_numeral'),
  ('show.birds.4', 'numeral_to_set'),
  ('same.apples.4v5', 'same_or_not'),
  ('more.big.apples', 'more_big_things'),
  ('ordinal.third.of4', 'ordinal'),
  ('zero.nest', 'zero'),
  ('count.apples.7', 'count_seven'),
  ('col.find.red.balloon', 'colour_find'),
  ('col.sort.red', 'colour_sort'),
  ('log.next.colours', 'logic_next'),
  ('log.sort.colour', 'logic_sort'),
  ('log.size.middle', 'logic_size'),
  ('log.pat.no.mixed', 'logic_pattern_yes_no'),
  ('shp.any.small', 'shape_small'),
  ('shp.where.under', 'shape_where'),
  ('math.add.apples', 'math_add'),
  ('math.shop.apples', 'math_shop'),
  ('math.time.morning', 'math_time'),
  ('log.sortdrag.colour', 'drag_sort'),
  ('log.sortdrag.three', 'drag_sort_three'),
  ('math.share.stars', 'drag_share'),
  ('log.copy.three', 'drag_pattern'),
  ('cs.robot.plan.2', 'robot_plan'),
  ('cs.robot.direct.3', 'robot_direct'),
  ('shp.build.house', 'builder_house'),
  ('shp.build.train', 'builder_train'),
  ('b.numb13.1', 'number_line_place'),
  ('b.mathb09.5', 'balance_compare'),
  ('x.numa07.1', 'match_numbers'),
  ('x.mathb16.1', 'match_coins'),
  ('x.mathb17.1', 'shop_pay'),
  ('x.mathb15.1', 'clock_set'),
  ('x.numb07.2', 'trace_numeral'),
  ('x.mathb19.1', 'chart_most'),
  ('x.mathb19.7', 'chart_more'),
  ('x.shpb09.1', 'match_solids'),
  ('b.mathb06.1', 'give'),
  ('b.colb02.1', 'build_pattern'),
  ('b.colb04.5', 'spot_error'),
  ('b.mathb02.2', 'balance_b'),
];

Future<void> _write(WidgetTester t, String path) async {
  final Element element = find.byType(MaterialApp).evaluate().first;
  await t.runAsync(() async {
    final ui.Image image = await captureImage(element);
    final ByteData? bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File(path).writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

void main() {
  final String? dir = Platform.environment['SHOTS_DIR'];
  final String? only = Platform.environment['SHOTS_ONLY'];
  setUpAll(() async {
    await loadAppFonts();
  });

  for (final (String, Size) device in boards) {
    testWidgets('pictures of the unit items, ${device.$1}', (WidgetTester tester) async {
      final AppRig rig = AppRig();
      await rig.seedFinishedSetup(name: 'נֹעָה');
      await rig.pump(tester, size: device.$2);
      await tester.tap(find.text('נֹעָה'));
      await tester.pumpAndSettle();
      final PackContent content = await loadStarter();
      Directory('$dir/${device.$1}').createSync(recursive: true);
      for (final (String, String) shot in _items) {
        if (only != null && !only.split(',').contains(shot.$2)) continue;
        final NavigatorState nav = tester.state<NavigatorState>(find.byType(Navigator).first);
        final Lesson one = Lesson.mission(
          id: 'shot',
          itemIds: <String>[shot.$1],
          skillIds: content.activities[shot.$1]!.skills.map((Skill s) => s.id).toList(),
          celebration: content.lessons['butterflies']!.celebration,
        );
        nav.push(
          MaterialPageRoute<void>(
            builder: (BuildContext c) => LessonScreen(profileId: 'p-1', mission: one),
          ),
        );
        await tester.pump(const Duration(milliseconds: 600));
        for (int spent = 0; spent < 900; spent += 100) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        await tester.pump(const Duration(milliseconds: 50));
        await _write(tester, '$dir/${device.$1}/${shot.$2}.png');
        nav.pop();
        await tester.pump(const Duration(milliseconds: 600));
      }
    }, skip: dir == null);
  }
}
