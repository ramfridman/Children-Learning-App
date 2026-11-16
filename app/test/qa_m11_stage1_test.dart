// QA pass of M11 Stage 1 (docs/milestones/M11.md section 6, criteria 1 to 4 and 10), 2026-11-15. It adds what the developer's tests did not cover:
//  - the trail in each of the nine room shapes keeps clear of the header buttons at every lesson length on every board (trail_room_test only
//    pumps the default round sockets);
//  - the stage's end state after a right answer, as a picture, in every room (the "reacted" goldens of golden_m11_rooms_test.dart were taken
//    1.5 s after the tap, when the next item was already on; they are now taken at 1.25 s, when the end state stands: QA's D2);
//  - the host's lines at text size 1.3 on the small phone (the developer's check is on the large phone), greeting and celebration, in all nine rooms;
//  - the real L7 screens (the opener, a Meet, a Find) inside the three course rooms on every board;
//  - the ink on every room's screen, sky and bubble keeps its contrast.
//
// Regenerate after a deliberate visual change:  flutter test --update-goldens test/qa_m11_stage1_test.dart
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/activity_shell.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/design/board.dart';
import 'package:nitznutz/design/components.dart';
import 'package:nitznutz/design/course_text.dart' show TargetChip;
import 'package:nitznutz/design/layout.dart';
import 'package:nitznutz/design/token_types.dart' show Band;
import 'package:nitznutz/design/tokens.g.dart';
import 'package:nitznutz/play/activity_frame.dart';
import 'package:nitznutz/rooms/room_scene.dart';
import 'package:nitznutz/rooms/room_spec.dart';
import 'package:nitznutz/strings/he.dart' show HostHe;

import 'support/golden_comparator.dart';
import 'support/harness.dart';
import 'support/l4_golden.dart' show waitFor;
import 'support/l7_rig.dart';
import 'support/m11_rooms.dart';
import 'support/meet_opener.dart';

const Map<String, Size> _boards = <String, Size>{
  'phone': Size(852, 393),
  'phoneSE': Size(667, 375),
  'tabletLandscape': Size(1180, 820),
  'tabletPortrait': Size(820, 1180),
};

const Map<String, BoardClass> _classes = <String, BoardClass>{
  'phone': BoardClass.phone,
  'phoneSE': BoardClass.phoneSE,
  'tabletLandscape': BoardClass.tabletLandscape,
  'tabletPortrait': BoardClass.tabletPortrait,
};

Future<void> _shot(WidgetTester t, String name) =>
    expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/$name.png'));

Finder _tile(String id) =>
    find.byWidgetPredicate((Widget w) => w.key == Key('tile-$id') || w.key == Key('option-$id'));

double _lum(Color c) {
  double ch(double v) => v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
}

double _contrast(Color a, Color b) {
  final double x = _lum(a), y = _lum(b);
  return (math.max(x, y) + 0.05) / (math.min(x, y) + 0.05);
}

/// Every drawn text lies on the screen (nothing cut off by the board's edge), and nothing threw (overflow stripes are exceptions in a test).
void _onScreen(WidgetTester t, Size board, String what, {Finder? within}) {
  expect(t.takeException(), isNull, reason: '$what: no exception (overflow)');
  final Finder texts = within == null
      ? find.byType(Text)
      : find.descendant(of: within, matching: find.byType(Text));
  for (final Element e in texts.evaluate()) {
    final RenderBox? box = e.renderObject as RenderBox?;
    if (box == null || !box.hasSize || box.size.isEmpty) continue;
    final Rect r = box.localToGlobal(Offset.zero) & box.size;
    expect(
      r.left >= -0.5 && r.top >= -0.5 && r.right <= board.width + 0.5 && r.bottom <= board.height + 0.5,
      isTrue,
      reason: '$what: the text "${(e.widget as Text).data}" at $r leaves the board $board',
    );
  }
}

/// The bubble is clear of the stage's rim (4 points) and of the buttons' tap areas, and the trail is clear of the buttons.
void _clear(WidgetTester t, String what) {
  final Finder bubble = find.byKey(const Key('lesson-bubble'));
  final Finder stage = find.byKey(const Key('lesson-stage'));
  if (bubble.evaluate().isNotEmpty && stage.evaluate().isNotEmpty) {
    final Rect b = t.getRect(bubble.first);
    final Rect s = t.getRect(stage.first);
    expect(b.overlaps(s.deflate(1)), isFalse, reason: '$what: the bubble $b is over the stage $s');
  }
  final Finder trail = find.byType(ProgressTrail);
  if (trail.evaluate().isEmpty) return;
  final Rect tr = t.getRect(trail.first);
  for (final String key in <String>['lesson-hint', 'lesson-show-me', 'activity-home']) {
    final Finder f = find.byKey(Key(key));
    if (f.evaluate().isEmpty) continue;
    final Rect r = t.getRect(f.first);
    expect(
      tr.overlaps(r.inflate(7.9)),
      isFalse,
      reason: '$what: the trail $tr is within 8 points of $key $r',
    );
  }
}

Future<void> _frame(
  WidgetTester t,
  RoomSpec room,
  String board, {
  required int total,
  required int done,
}) async {
  t.view.physicalSize = _boards[board]!;
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
            spec: ActivitySpec.of(_classes[board]!),
            scene: RoomScene(room: room, hostView: const SizedBox(), hostMouth: const Offset(0.5, 0.5)),
            bubbleText: 'כַּמָּה פְּרָחִים יֵשׁ בַּשָּׂדֶה?',
            stage: (Size r) => const SizedBox(),
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

void main() {
  setUpAll(() async {
    await loadAppFonts();
    useTolerantGoldens(0.03);
  });

  group('criterion 1 and the trail rule: every room shape keeps clear of the buttons at any length', () {
    for (final String board in _boards.keys) {
      testWidgets('$board: nine room shapes, from 1 socket to 40', (WidgetTester t) async {
        for (final RoomSpec room in RoomSpec.all) {
          for (final int total in <int>[1, 6, 8, 10, 12, 13, 16, 20, 26, 40]) {
            for (final int done in <int>{0, total ~/ 2, total}) {
              await _frame(t, room, board, total: total, done: done);
              final String what = '${room.name} on $board, $total sockets, $done full';
              expect(t.takeException(), isNull, reason: '$what: no overflow');
              _clear(t, what);
              final Rect tr = t.getRect(find.byType(ProgressTrail));
              expect(tr.left, greaterThanOrEqualTo(0), reason: '$what: on the board');
              expect(tr.right, lessThanOrEqualTo(_boards[board]!.width), reason: '$what: on the board');
            }
          }
        }
      });
    }
  });

  group('contrast: the ink on every room\'s screen, sky and bubble', () {
    test(
      'ink on each screen tint, sky top and sky bottom is at least 7:1; ink on the bubble paper is higher',
      () {
        for (final RoomSpec r in RoomSpec.all) {
          for (final (String, Color) c in <(String, Color)>[
            ('screen', r.screen),
            ('sky top', r.skyTop),
            ('sky bottom', r.skyBottom),
            ('paper', TokenColors.paper),
          ]) {
            expect(
              _contrast(TokenColors.ink, c.$2),
              greaterThanOrEqualTo(7),
              reason: '${r.name}: ink on the ${c.$1}',
            );
          }
          // The rim is the only coloured edge: it separates the stage from the screen by more than the 1.2:1 of a hairline.
          expect(
            _contrast(r.rim, r.screen),
            greaterThan(1.3),
            reason: '${r.name}: the rim shows on its screen',
          );
        }
      },
    );
  });

  group('criterion 3: the stage\'s end state, as a picture, in every room', () {
    for (final String board in <String>['phone', 'tabletLandscape']) {
      testWidgets('the nine rooms 300 ms after a right answer on the $board (reduce motion: the end state)', (
        WidgetTester t,
      ) async {
        for (final RoomId id in RoomId.values) {
          await t.pumpWidget(const SizedBox.shrink());
          final (PackContent c, Lesson l) = await roomLesson(id);
          await openRoomLesson(t, c, l, _boards[board]!);
          await t.tapAt(Offset(_boards[board]!.width / 2, _boards[board]!.height - 30));
          await waitFor(t, 800);
          await t.tap(_tile(rightOption(c, l, 0)));
          await waitFor(t, 300);
          expect(
            find.descendant(
              of: find.byKey(const Key('stage-reaction')),
              matching: find.byWidgetPredicate((Widget w) => w.runtimeType.toString() == 'SvgPicture'),
            ),
            findsWidgets,
            reason: '${id.name}: the reaction is drawn',
          );
          await _shot(t, 'qa_m11_reacted_${id.name}_$board');
        }
      });
    }
  });

  group('text size 1.3 on the small phone: the host\'s lines', () {
    testWidgets('the nine greetings: bubble on the board, clear of the stage, the pair and the buttons', (
      WidgetTester t,
    ) async {
      t.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      for (final RoomId id in RoomId.values) {
        await t.pumpWidget(const SizedBox.shrink());
        final (PackContent c, Lesson l) = await roomLesson(id);
        await openRoomLesson(t, c, l, _boards['phoneSE']!);
        final String what = '${id.name} greeting at 1.3 on the small phone';
        _onScreen(t, _boards['phoneSE']!, what);
        final Rect bubble = t.getRect(find.byKey(const Key('lesson-bubble')));
        final Rect stage = t.getRect(find.byKey(const Key('lesson-stage')));
        final Rect host = t.getRect(find.byKey(const Key('room-host')));
        expect(bubble.left, greaterThanOrEqualTo(stage.right + 2), reason: '$what: clear of the stage');
        expect(bubble.right, lessThanOrEqualTo(host.left + 12), reason: '$what: clear of the host');
        expect(bubble.top, greaterThanOrEqualTo(0), reason: '$what: top on the board');
        expect(bubble.bottom, lessThanOrEqualTo(375), reason: '$what: bottom on the board');
        _clear(t, what);
        if (id == RoomId.rus || id == RoomId.math) {
          await _shot(t, 'qa_m11_greeting_${id.name}_phoneSE_text_1_3');
        }
      }
    });

    testWidgets('the nine celebrations: the card, the cheer and the praise on the board', (
      WidgetTester t,
    ) async {
      t.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      for (final RoomId id in RoomId.values) {
        await t.pumpWidget(const SizedBox.shrink());
        final (PackContent c, Lesson l) = await roomLesson(id);
        await openRoomLesson(t, c, l, _boards['phoneSE']!);
        await t.tapAt(const Offset(300, 340));
        await waitFor(t, 800);
        for (int i = 0; i < l.itemIds.length; i++) {
          await t.tap(_tile(rightOption(c, l, i)));
          await waitFor(t, 2600);
        }
        final String what = '${id.name} celebration at 1.3 on the small phone';
        expect(find.byKey(const Key('lesson-celebration')), findsOneWidget, reason: what);
        _onScreen(t, _boards['phoneSE']!, what, within: find.byKey(const Key('lesson-celebration')));
        final Rect done = t.getRect(find.byKey(const Key('lesson-done')));
        expect(done.bottom, lessThanOrEqualTo(375), reason: '$what: the way home is on the board');
        expect(done.shortestSide, greaterThanOrEqualTo(60), reason: '$what: the way home is a big target');
        final String hostId = RoomSpec.byId(id).hostId;
        expect(find.text(HostHe.cheers[hostId]!.text), findsOneWidget, reason: '$what: the cheer is said');
        if (id == RoomId.numbers || id == RoomId.heb) {
          await _shot(t, 'qa_m11_celebration_${id.name}_phoneSE_text_1_3');
        }
      }
    });
  });

  group('the real L7 screens inside the three course rooms', () {
    late PackContent eng;
    late PackContent rus;
    late PackContent heb;

    setUpAll(() async {
      eng = await buildEnglish();
      rus = await buildCourse('rus');
      heb = await buildCourse('heb');
    });

    Future<void> checkChips(WidgetTester t, String what) async {
      for (final Element chip in find.byType(TargetChip).evaluate()) {
        final Finder words = find.descendant(of: find.byWidget(chip.widget), matching: find.byType(Text));
        expect(words, findsWidgets, reason: '$what: the chip holds its word');
        for (final Element e in words.evaluate()) {
          final TextDirection? own = (e.widget as Text).textDirection;
          expect(
            own ?? Directionality.of(e),
            TextDirection.ltr,
            reason: '$what: a target-language word in its chip reads left to right',
          );
        }
      }
    }

    for (final String board in _boards.keys) {
      testWidgets('English lesson 1 in Pip\'s room on the $board: greeting, opener, Meet, Find', (
        WidgetTester t,
      ) async {
        final Size size = _boards[board]!;
        await openEnglishLesson(t, eng, size: size, voice: true, rooms: true, pastOpener: false);
        await l7Wait(t, 300);
        _onScreen(t, size, 'eng greeting on $board');
        _clear(t, 'eng greeting on $board');
        await _shot(t, 'qa_m11_l7_eng_greeting_$board');
        await l7Wait(t, 3500);
        _onScreen(t, size, 'eng opener on $board');
        _clear(t, 'eng opener on $board');
        await _shot(t, 'qa_m11_l7_eng_opener_$board');
        await untilWordBeat(t);
        await l7Wait(t, 5400);
        await checkChips(t, 'eng Meet on $board');
        _onScreen(t, size, 'eng Meet on $board');
        _clear(t, 'eng Meet on $board');
        await _shot(t, 'qa_m11_l7_eng_meet_$board');
        await t.tap(find.byKey(const Key('say-done')));
        await l7Wait(t, 8000);
        await t.tap(find.byKey(const Key('say-done')));
        await l7Wait(t, 2500);
        _onScreen(t, size, 'eng Find on $board');
        _clear(t, 'eng Find on $board');
        await _shot(t, 'qa_m11_l7_eng_find_$board');
      });
    }

    for (final String board in <String>['phone', 'phoneSE', 'tabletPortrait']) {
      testWidgets('Russian family lesson in Gosha\'s room on the $board: Meet, look B, then C with letters', (
        WidgetTester t,
      ) async {
        final Size size = _boards[board]!;
        await openCourseLesson(
          t,
          'rus',
          rus,
          lesson: 'rus.family-1',
          size: size,
          band: 2,
          lettersOpen: true,
          rooms: true,
        );
        for (int i = 0; i < 120 && find.byType(TargetChip).evaluate().isEmpty; i++) {
          await t.pump(const Duration(milliseconds: 100));
        }
        await t.pump(const Duration(milliseconds: 400));
        expect(find.byType(TargetChip), findsOneWidget, reason: 'the Cyrillic word is in its chip');
        await checkChips(t, 'rus Meet on $board');
        _onScreen(t, size, 'rus Meet on $board');
        _clear(t, 'rus Meet on $board');
        await _shot(t, 'qa_m11_l7_rus_meet_$board');
      });
    }

    for (final String board in <String>['phone', 'phoneSE', 'tabletLandscape']) {
      testWidgets('Hebrew words lesson in Alfi\'s room on the $board: the story page', (
        WidgetTester t,
      ) async {
        final Size size = _boards[board]!;
        await openCourseLesson(
          t,
          'heb',
          heb,
          lesson: 'heb.words-1',
          size: size,
          band: 1,
          rooms: true,
          pastOpener: false,
        );
        await l7Wait(t, 4000);
        _onScreen(t, size, 'heb first screen on $board');
        _clear(t, 'heb first screen on $board');
        await _shot(t, 'qa_m11_l7_heb_first_$board');
        for (int i = 0; i < 5; i++) {
          final Finder turn = find.byKey(const Key('story-turn'));
          if (turn.evaluate().isEmpty) break;
          await t.tap(turn);
          await l7Wait(t, 300);
        }
        await l7Wait(t, 3000);
        _onScreen(t, size, 'heb page on $board');
        _clear(t, 'heb page on $board');
        await _shot(t, 'qa_m11_l7_heb_page_$board');
      });
    }
  });
}
