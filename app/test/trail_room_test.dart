// QA-L7-2 (2026-11-15): the progress trail keeps to the room between the header's buttons, on every board and for every lesson length the packs
// contain. The layout in its room (the whole trail, the gaps tightened, smaller sockets, then a window around the current socket) is tested on its
// own, then on the activity frame with the real buttons, then on the longest real lesson on each board, and two goldens show a 12-socket lesson.
//
// Regenerate after a deliberate visual change:  flutter test --update-goldens test/trail_room_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/activity_shell.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/design/board.dart';
import 'package:nitznutz/design/components.dart';
import 'package:nitznutz/design/layout.dart';
import 'package:nitznutz/design/token_types.dart' show Band;
import 'package:nitznutz/design/trail_layout.dart';
import 'package:nitznutz/play/activity_frame.dart';

import 'support/golden_comparator.dart';
import 'support/harness.dart';
import 'support/l7_rig.dart';
import 'support/starter.dart';

const Map<BoardClass, Size> _size = <BoardClass, Size>{
  BoardClass.phone: Size(852, 393),
  BoardClass.phoneSE: Size(667, 375),
  BoardClass.tabletLandscape: Size(1180, 820),
  BoardClass.tabletPortrait: Size(820, 1180),
};

/// Sockets of the trail of [lesson] for a new learner: its items, a set of Meet screens counting as one (what the lesson controller counts).
int _trailLength(PackContent pack, Lesson lesson) {
  int n = 0;
  for (final Activity a in pack.itemsFor(lesson, route: 'new')) {
    if (!(a is SayItActivity && a.meetScreen && (a.meet?.position ?? 0) > 0)) n++;
  }
  return n;
}

/// The longest lesson of [pack]: its id and its number of sockets.
({String id, int sockets}) _longest(PackContent pack) {
  String id = '';
  int best = 0;
  for (final Lesson l in pack.lessons.values) {
    final int n = _trailLength(pack, l);
    if (n > best) {
      best = n;
      id = l.id;
    }
  }
  return (id: id, sockets: best);
}

Future<void> _pumpFrame(WidgetTester t, BoardClass board, {required int total, required int done}) async {
  t.view.physicalSize = _size[board]!;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    MaterialApp(
      locale: const Locale('he'),
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: LayoutScope(
          band: Band.b,
          child: ActivityFrame(
            spec: ActivitySpec.of(board),
            bubbleText: 'כַּמָּה פְּרָחִים יֵשׁ בַּשָּׂדֶה?',
            stage: (Size room) => const SizedBox(),
            trailTotal: total,
            trailDone: done,
            onHome: () {},
            onHint: () {},
            onShowMe: () {},
          ),
        ),
      ),
    ),
  );
  await t.pump();
}

/// The trail is on the board, and at least [gap] from the home, the lamp and the eye (their tap areas, which are what a finger meets).
void _expectClear(WidgetTester t, BoardClass board, String what, {double gap = 8}) {
  final Rect trail = t.getRect(find.byType(ProgressTrail));
  expect(trail.left, greaterThanOrEqualTo(0), reason: '$what: the trail starts on the board');
  expect(trail.right, lessThanOrEqualTo(_size[board]!.width), reason: '$what: the trail ends on the board');
  for (final String key in <String>['lesson-hint', 'lesson-show-me', 'activity-home']) {
    final Rect button = t.getRect(find.byKey(Key(key)));
    final double apart = trail.left >= button.right
        ? trail.left - button.right
        : button.left >= trail.right
        ? button.left - trail.right
        : -1;
    expect(
      apart,
      greaterThanOrEqualTo(gap - 0.001),
      reason: '$what: the trail $trail is ${apart < 0 ? 'over' : 'only $apart from'} $key $button',
    );
  }
}

void main() {
  late PackContent eng;
  late PackContent rus;
  late int longest;

  setUpAll(() async {
    await loadAppFonts();
    useTolerantGoldens(0.03);
    eng = await buildEnglish();
    rus = await buildCourse('rus');
    final PackContent heb = await buildCourse('heb');
    final PackContent starter = await loadStarter();
    longest = <PackContent>[
      eng,
      rus,
      heb,
      starter,
    ].map((PackContent p) => _longest(p).sockets).reduce((int a, int b) => a > b ? a : b);
  });

  group('TrailLayout', () {
    test('the board\'s own size when the sockets fit: 20 wide, 8 apart, 12 of padding', () {
      final TrailLayout l = TrailLayout.fit(total: 6, done: 2, maxWidth: 478);
      expect((l.socket, l.gap, l.padding, l.first, l.count), (20.0, 8.0, 12.0, 0, 6));
      expect(l.width, 24 + 6 * 20 + 5 * 8);
    });

    test('with no room given the trail keeps its own size', () {
      expect(TrailLayout.fit(total: 40, done: 0).width, 24 + 40 * 20 + 39 * 8);
    });

    test(
      'first the gaps are tightened (sockets stay 20), then the sockets shrink to the floor, then a window',
      () {
        final TrailLayout tight = TrailLayout.fit(total: 15, done: 3, maxWidth: 387);
        expect(tight.socket, 20);
        expect(tight.gap, inInclusiveRange(TrailLayout.tightGap, 8));
        expect(tight.gap, lessThan(8));
        expect(tight.count, 15);

        final TrailLayout small = TrailLayout.fit(total: 18, done: 3, maxWidth: 387);
        expect(small.gap, TrailLayout.tightGap);
        expect(small.socket, inInclusiveRange(TrailLayout.floorSocket, 20));
        expect(small.socket, lessThan(20));
        expect(small.count, 18);

        final TrailLayout window = TrailLayout.fit(total: 40, done: 20, maxWidth: 387);
        expect(window.socket, TrailLayout.floorSocket);
        expect(window.count, lessThan(40));
        expect(window.moreBefore && window.moreAfter, isTrue);
      },
    );

    test('the floor is 60% of the board\'s socket', () {
      expect(TrailLayout.floorSocket / 20, closeTo(0.6, 0.0001));
    });

    test(
      'for every length and room: it fits, the current socket is shown and not faded, the floors hold',
      () {
        for (int total = 1; total <= 60; total++) {
          for (double room = 100; room <= 900; room += 17) {
            for (final int done in <int>{0, 1, total ~/ 2, total - 1, total}) {
              final TrailLayout l = TrailLayout.fit(total: total, done: done, maxWidth: room);
              final String what = 'total $total, done $done, room $room';
              expect(l.width, lessThanOrEqualTo(room + 0.001), reason: '$what: the pill fits');
              expect(l.socket, greaterThanOrEqualTo(TrailLayout.floorSocket), reason: what);
              expect(l.gap, greaterThanOrEqualTo(TrailLayout.tightGap), reason: what);
              final int current = done < total ? done : total - 1;
              expect(l.shown, contains(current), reason: '$what: the current socket is shown');
              expect(l.faded(current), isFalse, reason: '$what: the current socket is not the faded one');
              expect(l.first, greaterThanOrEqualTo(0), reason: what);
              expect(l.first + l.count, lessThanOrEqualTo(total), reason: what);
              if (l.count == total) expect(l.moreBefore || l.moreAfter, isFalse, reason: what);
            }
          }
        }
      },
    );

    test('a window moves with the child: it starts at the first socket, follows the current one and ends at the last', () {
      TrailLayout at(int done) => TrailLayout.fit(total: 40, done: done, maxWidth: 300);
      expect(at(0).first, 0);
      expect(at(0).moreBefore, isFalse);
      expect(at(0).moreAfter, isTrue);
      expect(at(20).first, greaterThan(0));
      expect(at(40).first + at(40).count, 40);
      expect(at(40).moreAfter, isFalse);
      expect(at(40).moreBefore, isTrue);
    });
  });

  testWidgets('golden: the four ways the trail is drawn in the small phone room (387 wide)', (
    WidgetTester t,
  ) async {
    t.view.physicalSize = const Size(420, 300);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: ColoredBox(
            key: const Key('trail-states'),
            color: const Color(0xFFFFF5E6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const <Widget>[
                ProgressTrail(total: 12, done: 5, maxWidth: 387),
                ProgressTrail(total: 15, done: 5, maxWidth: 387),
                ProgressTrail(total: 18, done: 5, maxWidth: 387),
                ProgressTrail(total: 40, done: 20, maxWidth: 387),
              ],
            ),
          ),
        ),
      ),
    );
    await t.pump();
    await expectLater(
      find.byKey(const Key('trail-states')),
      matchesGoldenFile('goldens/trail_states_phoneSE_room.png'),
    );
  });

  group('the activity frame', () {
    for (final BoardClass board in BoardClass.values) {
      testWidgets(
        '${board.name}: from one socket to the longest lesson and well past it, nothing under a button',
        (WidgetTester t) async {
          expect(longest, greaterThanOrEqualTo(12), reason: 'the packs hold lessons of 12 sockets');
          final List<int> totals = <int>{
            1,
            6,
            8,
            10,
            12,
            longest,
            longest + 1,
            longest + 4,
            20,
            26,
            40,
          }.toList()..sort();
          for (final int total in totals) {
            for (final int done in <int>{0, total ~/ 2, total}) {
              await _pumpFrame(t, board, total: total, done: done);
              expect(
                t.takeException(),
                isNull,
                reason: '${board.name}: $total sockets, $done full: no overflow',
              );
              _expectClear(t, board, '${board.name}: $total sockets, $done full');
            }
          }
        },
      );
    }

    testWidgets('a trail that fits stays centred where the board puts it', (WidgetTester t) async {
      await _pumpFrame(t, BoardClass.phone, total: 6, done: 2);
      final ActivitySpec s = ActivitySpec.phone;
      expect(t.getCenter(find.byType(ProgressTrail)).dx, closeTo(s.trailLeft + s.trailWidth / 2, 0.5));
      await _pumpFrame(t, BoardClass.tabletLandscape, total: 12, done: 2);
      expect(t.getCenter(find.byType(ProgressTrail)).dx, closeTo(590, 0.5));
    });
  });

  group('the longest lessons', () {
    for (final BoardClass board in BoardClass.values) {
      for (final String course in <String>['eng', 'rus']) {
        testWidgets('${board.name}: the longest lesson of the $course course', (WidgetTester t) async {
          final PackContent pack = course == 'eng' ? eng : rus;
          final ({String id, int sockets}) lesson = _longest(pack);
          await openCourseLesson(t, course, pack, lesson: lesson.id, size: _size[board]!);
          await l7Wait(t, 600);
          _expectClear(t, board, '${board.name}: ${lesson.id} (${lesson.sockets} sockets)');
        });
      }
    }

    for (final BoardClass board in <BoardClass>[BoardClass.phone, BoardClass.phoneSE]) {
      testWidgets('golden: a 12-socket lesson on the ${board.name}', (WidgetTester t) async {
        await openEnglishLesson(t, eng, lesson: 'eng.act-2', size: _size[board]!);
        await l7Wait(t, 600);
        expect(find.byType(ProgressTrail), findsOneWidget);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/l7_trail_12_${board.name}.png'),
        );
      });
    }
  });
}
