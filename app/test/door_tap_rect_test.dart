// QA-L0-2: a door's tap area is one rectangle, its bubble, its door and its host, and nothing round them
// (docs/design/languages-island.md section 4.2.1). The rectangles below are the design's table, in board points, so a change of
// the code is checked against the design and not against itself.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/design/token_types.dart' show Band;
import 'package:nitznutz/child/languages_doors.dart';

import 'support/harness.dart';

/// One board: its size, the y range shared by every rectangle, the x ranges of the doors from the left (Russian, Hebrew,
/// English) with three doors on and (left, right) with two, the friend's square and the title and back pebble areas.
class DoorBoard {
  const DoorBoard(this.name, this.size, this.top, this.bottom, this.three, this.two, this.friend);

  final String name;
  final Size size;
  final double top;
  final double bottom;
  final List<(double, double)> three;
  final List<(double, double)> two;
  final Rect friend;
}

const List<DoorBoard> boards = <DoorBoard>[
  DoorBoard(
    'phone',
    Size(852, 393),
    84,
    369,
    <(double, double)>[(177, 355), (393, 571), (609, 787)],
    <(double, double)>[(269, 447), (517, 695)],
    Rect.fromLTRB(16, 281, 120, 385),
  ),
  DoorBoard(
    'phoneSE',
    Size(667, 375),
    80,
    338,
    <(double, double)>[(118.5, 276.5), (302.5, 460.5), (486.5, 644.5)],
    <(double, double)>[(198.5, 356.5), (406.5, 564.5)],
    Rect.fromLTRB(16, 279, 104, 367),
  ),
  DoorBoard(
    'tabletLandscape',
    Size(1180, 820),
    200,
    608,
    <(double, double)>[(148, 392), (468, 712), (788, 1032)],
    <(double, double)>[(280, 524), (656, 900)],
    Rect.fromLTRB(16, 652, 176, 812),
  ),
  DoorBoard(
    'tabletPortrait',
    Size(820, 1180),
    380,
    762,
    <(double, double)>[(34, 258), (298, 522), (562, 786)],
    <(double, double)>[(154, 378), (442, 666)],
    Rect.fromLTRB(16, 1012, 176, 1172),
  ),
];

/// The doors, left to right on the screen: the first door of the list is the rightmost.
List<String> onScreenOrder(List<String> courses) => courses.reversed.toList();

void main() {
  setUpAll(loadAppFonts);

  for (final DoorBoard b in boards) {
    for (final List<String> courses in <List<String>>[
      <String>['eng', 'heb', 'rus'],
      <String>['eng', 'rus'],
      <String>['heb', 'rus'],
      <String>['eng', 'heb'],
    ]) {
      final List<(double, double)> xs = courses.length == 3 ? b.three : b.two;
      final List<String> left2right = onScreenOrder(courses);
      testWidgets(
        '${b.name}, ${courses.join(' ')}: a tap one point inside a corner opens that door, one point outside opens none',
        (WidgetTester tester) async {
          final List<String> opened = <String>[];
          await pumpScreen(
            tester,
            LanguagesDoorsScreen(
              courses: courses,
              onOpenCourse: (String c) async => opened.add(c),
              companion: const SizedBox.expand(key: Key('friend')),
            ),
            size: b.size,
            band: Band.a,
          );

          Future<List<String>> tapAt(double x, double y) async {
            opened.clear();
            await tester.tapAt(Offset(x, y));
            await tester.pump(const Duration(milliseconds: 700));
            return List<String>.of(opened);
          }

          for (int i = 0; i < left2right.length; i++) {
            final (double l, double r) = xs[i];
            final double midY = (b.top + b.bottom) / 2;
            for (final (double x, double y) in <(double, double)>[
              (l + 1, b.top + 1),
              (r - 1, b.top + 1),
              (l + 1, b.bottom - 1),
              (r - 1, b.bottom - 1),
              ((l + r) / 2, midY),
            ]) {
              expect(await tapAt(x, y), <String>[left2right[i]], reason: '${left2right[i]} at ($x, $y)');
            }
            for (final (double x, double y) in <(double, double)>[
              (l - 1, midY),
              (r + 1, midY),
              ((l + r) / 2, b.top - 1),
              ((l + r) / 2, b.bottom + 1),
            ]) {
              expect(
                await tapAt(x, y),
                isEmpty,
                reason: '${left2right[i]}: a tap at ($x, $y) is outside its rectangle',
              );
            }
          }
          // Nothing round the doors is a door: the friend, the grass below, the sea above, the space between two doors.
          expect(await tapAt(b.friend.center.dx, b.friend.center.dy), isEmpty, reason: 'the friend');
          expect(await tapAt(xs.first.$1 + 20, b.bottom + 12), isEmpty, reason: 'the grass below the doors');
          expect(await tapAt(xs.first.$1 + 20, 30), isEmpty, reason: 'the sea above the doors');
          for (int i = 0; i + 1 < xs.length; i++) {
            expect(
              await tapAt((xs[i].$2 + xs[i + 1].$1) / 2, (b.top + b.bottom) / 2),
              isEmpty,
              reason: 'between two doors',
            );
          }
        },
      );
    }

    testWidgets('${b.name}: the door button for a screen reader has the same rectangle as its tap area', (
      WidgetTester tester,
    ) async {
      await pumpScreen(
        tester,
        LanguagesDoorsScreen(courses: const <String>['eng', 'heb', 'rus'], onOpenCourse: (String c) async {}),
        size: b.size,
        band: Band.a,
      );
      final List<String> left2right = onScreenOrder(<String>['eng', 'heb', 'rus']);
      for (int i = 0; i < 3; i++) {
        final Rect r = tester.getRect(find.byKey(Key('door-${left2right[i]}')));
        expect(r, Rect.fromLTRB(b.three[i].$1, b.top, b.three[i].$2, b.bottom), reason: left2right[i]);
        final Rect semantic = tester.getSemantics(find.byKey(Key('door-${left2right[i]}'))).rect;
        expect(semantic.size, r.size, reason: '${left2right[i]}: the button is as big as the rectangle');
      }
    });
  }
}
