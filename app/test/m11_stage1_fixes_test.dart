// M11 Stage 1, QA's defects D1, D3, D4 and D5, proved with layout (rectangles on the screen), not pixels:
//  - D1: in every room, on every board, the landmark is whole on the screen, at least 56 points, clear of the stage's content, the answer
//    tiles, the header's controls, the trail, the bubble and the characters, before and after the stage has reacted;
//  - D3: the celebration's window holds the whole pose of every host (hopping too), on every board, at text size 1.0 and 1.3;
//  - D4: the bubble's tail points into the box of whoever is speaking (the host in a host beat, else the companion), on every board;
//  - D5: the bubble of a host's longest line keeps clear of the stage's rim, on the phones, at text size 1.0 and 1.3 (and of the tablet's card).
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/activity_shell.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/design/board.dart';
import 'package:nitznutz/design/components.dart';
import 'package:nitznutz/design/layout.dart';
import 'package:nitznutz/design/token_types.dart' show Band;
import 'package:nitznutz/play/activity_frame.dart';
import 'package:nitznutz/rooms/host_view.dart';
import 'package:nitznutz/rooms/room_celebration.dart';
import 'package:nitznutz/rooms/room_scene.dart';
import 'package:nitznutz/rooms/room_spec.dart';
import 'package:nitznutz/strings/he.dart' show HostHe;

import 'support/harness.dart';
import 'support/l4_golden.dart' show waitFor;
import 'support/m11_rooms.dart';

const Map<String, Size> _boards = <String, Size>{
  'phone': Size(852, 393),
  'phoneSE': Size(667, 375),
  'tabletLandscape': Size(1180, 820),
  'tabletPortrait': Size(820, 1180),
};

Finder _tile(String id) =>
    find.byWidgetPredicate((Widget w) => w.key == Key('tile-$id') || w.key == Key('option-$id'));

Finder get _reactedArt => find.descendant(
  of: find.byKey(const Key('stage-reaction')),
  matching: find.byWidgetPredicate(
    (Widget w) =>
        w is SvgPicture &&
        w.bytesLoader is SvgAssetLoader &&
        (w.bytesLoader as SvgAssetLoader).assetName.endsWith('_reacted.svg'),
  ),
);

/// Opens the first screen of a lesson of [room] on [board] (the greeting) with the rooms on.
Future<(PackContent, Lesson)> _open(WidgetTester t, RoomId room, String board) async {
  await t.pumpWidget(const SizedBox.shrink());
  final (PackContent c, Lesson l) = await roomLesson(room);
  await openRoomLesson(t, c, l, _boards[board]!);
  return (c, l);
}

/// Every rectangle on the screen that the landmark must keep clear of, by what it is.
Map<String, Rect> _content(WidgetTester t, String board) {
  final Map<String, Rect> found = <String, Rect>{};
  void add(String name, Finder f, {double grow = 0}) {
    int i = 0;
    for (final Element e in f.evaluate()) {
      final RenderBox? box = e.renderObject as RenderBox?;
      if (box == null || !box.hasSize) continue;
      found['$name ${i++}'] = (box.localToGlobal(Offset.zero) & box.size).inflate(grow);
    }
  }

  // The stage's content with its rim (the phone's 4 points) or its card (the tablet's 16).
  add('stage', find.byKey(const Key('lesson-stage')), grow: board.startsWith('tablet') ? 16 : 4);
  add('answer tile', find.byKey(const Key('answer-tile')));
  // The tiles of a language course's choice are keyed by their option.
  add(
    'option tile',
    find.byWidgetPredicate((Widget w) {
      final Key? k = w.key;
      return k is ValueKey<String> && (k.value.startsWith('option-') || k.value.startsWith('tile-'));
    }),
  );
  add('home', find.byKey(const Key('activity-home')));
  add('lamp', find.byKey(const Key('lesson-hint')));
  add('show me', find.byKey(const Key('lesson-show-me')));
  add('trail', find.byType(ProgressTrail));
  add('bubble', find.byKey(const Key('bubble-body')));
  add('companion', find.byKey(const Key('activity-nitzi')));
  add('host', find.byKey(const Key('room-host')));
  return found;
}

/// The landmark's box is whole on the board, at least 56 points, and clear of everything else on the screen.
void _landmarkClear(WidgetTester t, String board, String when) {
  final Size size = _boards[board]!;
  final Rect box = t.getRect(find.byKey(const Key('stage-reaction')));
  expect(t.takeException(), isNull, reason: '$when: no exception');
  expect(
    box.left >= 0 && box.top >= 0 && box.right <= size.width && box.bottom <= size.height,
    isTrue,
    reason: '$when: the landmark $box is on the board $size',
  );
  expect(box.shortestSide, greaterThanOrEqualTo(56), reason: '$when: the landmark is at least 56 points');
  _content(t, board).forEach((String what, Rect r) {
    expect(r.overlaps(box), isFalse, reason: '$when: the landmark $box is over the $what $r');
  });
}

void main() {
  setUpAll(loadAppFonts);

  // ---- D1 ----
  group('D1: the landmark is on the screen in every room on every board, before and after the stage has reacted', () {
    for (final String board in _boards.keys) {
      testWidgets('$board: the nine rooms', (WidgetTester t) async {
        for (final RoomId room in RoomId.values) {
          final (PackContent c, Lesson l) = await _open(t, room, board);
          final String what = '${room.name} on $board';
          // The greeting, the first item, a moment after the right answer, and when the reaction has settled.
          _landmarkClear(t, board, '$what, greeting');
          await t.tapAt(Offset(_boards[board]!.width / 2, _boards[board]!.height - 30));
          await waitFor(t, 800);
          expect(_tile(rightOption(c, l, 0)), findsOneWidget, reason: '$what: the first item is on');
          _landmarkClear(t, board, '$what, the first item');
          expect(_reactedArt, findsNothing, reason: '$what: plain before the answer');
          await t.tap(_tile(rightOption(c, l, 0)));
          await waitFor(t, 300);
          _landmarkClear(t, board, '$what, 300 ms after the right answer');
          await waitFor(t, 800);
          _landmarkClear(t, board, '$what, settled');
          expect(_reactedArt, findsOneWidget, reason: '$what: the end state is drawn');
          // The next item: plain again, and still clear.
          await waitFor(t, 1200);
          expect(_reactedArt, findsNothing, reason: '$what: nothing is carried over');
          _landmarkClear(t, board, '$what, the next item');
        }
      });
    }
  });

  // ---- D3 ----
  group('D3: the celebration\'s window holds the whole pose of every host', () {
    /// The figure of each host's pose in the artboard's 512 units (the smallest box that holds every drawn pixel), measured by drawing it.
    final Map<String, Rect> figure = <String, Rect>{};

    Future<Rect> measure(WidgetTester t, HostSpec h, HostPose p) async {
      final String key = '${h.id} ${p.name}';
      if (figure.containsKey(key)) return figure[key]!;
      t.view.physicalSize = const Size(512, 512);
      t.view.devicePixelRatio = 1;
      await t.pumpWidget(
        Directionality(
          textDirection: TextDirection.rtl,
          child: RepaintBoundary(
            key: const Key('measure'),
            child: SizedBox(
              width: 512,
              height: 512,
              child: SvgPicture.asset(h.asset(p), fit: BoxFit.contain),
            ),
          ),
        ),
      );
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));
      await t.pump();
      final RenderRepaintBoundary ro = t.renderObject(find.byKey(const Key('measure')));
      final Uint8List rgba = (await t.runAsync(() async {
        final ui.Image image = await ro.toImage();
        return (await image.toByteData())!.buffer.asUint8List();
      }))!;
      double top = 512, bottom = -1, left = 512, right = -1;
      for (int y = 0; y < 512; y++) {
        for (int x = 0; x < 512; x++) {
          if (rgba[(y * 512 + x) * 4 + 3] > 16) {
            top = math.min(top, y.toDouble());
            bottom = math.max(bottom, y + 1.0);
            left = math.min(left, x.toDouble());
            right = math.max(right, x + 1.0);
          }
        }
      }
      return figure[key] = Rect.fromLTRB(left, top, right, bottom);
    }

    testWidgets(
      'no pose of any host rises above the share the window is fitted to, or stands lower than the feet line',
      (WidgetTester t) async {
        for (final HostSpec h in HostSpec.all) {
          for (final HostPose p in HostPose.values) {
            final Rect f = await measure(t, h, p);
            expect(
              f.top,
              greaterThanOrEqualTo(HostSpec.topShare * HostSpec.artboard),
              reason: '${h.id} ${p.name}: the head',
            );
            expect(f.bottom, lessThanOrEqualTo(480), reason: '${h.id} ${p.name}: the feet and their shadow');
          }
        }
      },
    );

    for (final String board in _boards.keys) {
      for (final double scale in <double>[1.0, 1.3]) {
        testWidgets(
          '$board at text size $scale: every host, celebrating or resting, is inside the window, hop included',
          (WidgetTester t) async {
            for (final HostSpec h in HostSpec.all) {
              for (final HostPose p in <HostPose>[HostPose.celebrate, HostPose.idle]) {
                final Rect fig = await measure(t, h, p);
                final RoomSpec room = RoomSpec.all.firstWhere((RoomSpec r) => r.hostId == h.id);
                t.view.physicalSize = _boards[board]!;
                t.view.devicePixelRatio = 1;
                t.platformDispatcher.textScaleFactorTestValue = scale;
                await t.pumpWidget(
                  MaterialApp(
                    locale: const Locale('he'),
                    home: Directionality(
                      textDirection: TextDirection.rtl,
                      child: LayoutScope(
                        band: Band.b,
                        child: Scaffold(
                          body: Center(
                            child: RoomCelebrationCard(
                              room: room,
                              host: HostView(host: h, pose: p),
                              companion: const SizedBox.expand(),
                              praise: 'כָּל הַכָּבוֹד!',
                              cheer: HostHe.cheers[h.id]!.text,
                              onDone: () {},
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
                await t.pump(const Duration(milliseconds: 300));
                final String what = '${h.id} ${p.name} on $board at $scale';
                final Rect window = t.getRect(find.byKey(const Key('room-celebration-window')));
                final Rect box = t.getRect(find.byKey(const Key('room-celebration-host')));
                final double k = box.width;
                // The figure on the screen: its share of the box, and lifted by the hop at the top of it.
                final Rect on = Rect.fromLTRB(
                  box.left + fig.left / 512 * k,
                  box.top + fig.top / 512 * k,
                  box.left + fig.right / 512 * k,
                  box.top + fig.bottom / 512 * k,
                );
                final Rect hopping = on.shift(Offset(0, -HostView.hopLift * k));
                expect(
                  window.contains(on.topLeft) && window.contains(on.bottomRight),
                  isTrue,
                  reason: '$what: the figure $on is in the window $window',
                );
                expect(
                  hopping.top,
                  greaterThanOrEqualTo(window.top),
                  reason: '$what: the hop $hopping stays in the window $window',
                );
                final Rect cameo = t.getRect(find.byKey(const Key('lesson-cameo')));
                // The companion's box starts inside the window (its lower edge is only the empty margin under its feet).
                expect(
                  cameo.top >= window.top && cameo.left >= window.left && cameo.right <= window.right,
                  isTrue,
                  reason: '$what: the companion\'s box $cameo starts inside the window $window',
                );
                expect(t.takeException(), isNull, reason: what);
              }
            }
            t.platformDispatcher.clearTextScaleFactorTestValue();
          },
        );
      }
    }

    test('the host is the larger of the pair, and big: the phone\'s box is over 125 points, the small phone\'s over 110', () {
      expect(RoomCelebrationCard.hostBoxFor(140, 1), greaterThan(125));
      expect(RoomCelebrationCard.hostBoxFor(124, 1), greaterThan(110));
      expect(RoomCelebrationCard.hostBoxFor(220, 220 / 140), greaterThan(200));
    });
  });

  // ---- D4 ----
  group('D4: the bubble\'s tail points at whoever speaks', () {
    /// The tip of the bubble's tail on the screen: the wedge's point, or the pointer's.
    Offset tip(WidgetTester t) {
      final Finder pointer = find.byKey(const Key('bubble-pointer'));
      if (pointer.evaluate().isNotEmpty) return t.getCenter(pointer) + const Offset(11 * 1.41421356, 0);
      final BoardBubble b = t.widget<BoardBubble>(find.byKey(const Key('lesson-bubble')));
      return t.getTopRight(find.byKey(const Key('bubble-body'))) + b.tailTip!;
    }

    for (final String board in _boards.keys) {
      testWidgets(
        '$board: in the host\'s greeting the tail ends at the host, in a child\'s turn at the companion',
        (WidgetTester t) async {
          for (final RoomId room in <RoomId>[RoomId.numbers, RoomId.math, RoomId.eng]) {
            final (PackContent c, Lesson l) = await _open(t, room, board);
            final String what = '${room.name} on $board';
            final Rect host = t.getRect(find.byKey(const Key('room-host')));
            expect(
              host.inflate(6).contains(tip(t)),
              isTrue,
              reason: '$what, greeting: the tail ${tip(t)} ends at the host $host',
            );
            await t.tapAt(Offset(_boards[board]!.width / 2, _boards[board]!.height - 30));
            await waitFor(t, 800);
            final Rect friend = t.getRect(find.byKey(const Key('activity-nitzi')));
            expect(
              friend.inflate(6).contains(tip(t)),
              isTrue,
              reason: '$what, a turn: the tail ${tip(t)} ends at the companion $friend',
            );
            await t.tap(_tile(rightOption(c, l, 0)));
            await waitFor(t, 300);
            expect(
              friend.inflate(6).contains(tip(t)),
              isTrue,
              reason: '$what, praise: the tail ${tip(t)} ends at the companion $friend',
            );
          }
        },
      );
    }

    testWidgets(
      'the landscape tablet\'s tail is a wedge that reaches down to the speaker; a phone\'s is the small pointer',
      (WidgetTester t) async {
        await _open(t, RoomId.numbers, 'tabletLandscape');
        expect(find.byKey(const Key('bubble-tail')), findsOneWidget);
        expect(find.byKey(const Key('bubble-pointer')), findsNothing);
        await _open(t, RoomId.numbers, 'phone');
        expect(find.byKey(const Key('bubble-pointer')), findsOneWidget);
        expect(find.byKey(const Key('bubble-tail')), findsNothing);
      },
    );
  });

  // ---- D5 ----
  group('D5: the bubble of a host\'s longest line keeps clear of the stage\'s rim', () {
    final String longest = <String>[
      ...HostHe.greetings.values.map((s) => s.text),
      ...HostHe.togethers.values.map((s) => s.text),
      ...HostHe.cheers.values.map((s) => s.text),
    ].reduce((String a, String b) => a.length >= b.length ? a : b);

    Future<void> frame(
      WidgetTester t,
      String board, {
      required bool rooms,
      required double scale,
      String? text,
    }) async {
      t.view.physicalSize = _boards[board]!;
      t.view.devicePixelRatio = 1;
      t.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      final BoardClass cls = boardClassFor(_boards[board]!);
      await t.pumpWidget(
        MaterialApp(
          locale: const Locale('he'),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: LayoutScope(
              band: Band.b,
              child: ActivityFrame(
                spec: ActivitySpec.of(cls),
                scene: rooms
                    ? const RoomScene(
                        room: RoomSpec.math,
                        hostView: SizedBox(),
                        hostMouth: Offset(0.5, 0.52),
                        hostBeat: true,
                      )
                    : null,
                bubbleText: text ?? longest,
                bubbleAboveTiles: true,
                stage: (Size r) => const SizedBox(),
                tiles: const SizedBox(height: 108),
                trailTotal: 6,
                trailDone: 2,
                onHome: () {},
              ),
            ),
          ),
        ),
      );
      await t.pump();
    }

    for (final String board in _boards.keys) {
      for (final double scale in <double>[1.0, 1.3]) {
        testWidgets('$board at text size $scale: clear of the rim (phones) and of the card (tablets)', (
          WidgetTester t,
        ) async {
          await frame(t, board, rooms: true, scale: scale);
          final Rect bubble = t.getRect(find.byKey(const Key('bubble-body')));
          final Rect stage = t.getRect(find.byKey(const Key('lesson-stage')));
          // The phone's rim is 4 points outside the stage's content, the tablet's card 16 (12 of padding and 4 of border).
          final Rect rim = stage.inflate(board.startsWith('tablet') ? 16 : 4);
          expect(bubble.overlaps(rim), isFalse, reason: 'the bubble $bubble is over the stage\'s rim $rim');
          if (!board.startsWith('tablet')) {
            expect(bubble.left, greaterThanOrEqualTo(rim.right + 2 - 0.5), reason: '2 points to spare');
          }
          expect(t.takeException(), isNull);
        });
      }
    }

    for (final String board in <String>['phone', 'phoneSE']) {
      for (final double scale in <double>[1.0, 1.3]) {
        testWidgets(
          '$board at text size $scale: a longer and longer line never stands in the band of the rim; it widens only as far as the rim',
          (WidgetTester t) async {
            final String text = '$longest $longest $longest';
            int widened = 0;
            for (int n = 30; n <= text.length; n += 3) {
              await frame(t, board, rooms: true, scale: scale, text: text.substring(0, n));
              final Rect bubble = t.getRect(find.byKey(const Key('bubble-body')));
              final Rect stage = t.getRect(find.byKey(const Key('lesson-stage')));
              // A line so long that it goes over the stage itself is a defect of the line (the audits name it), not of the rim.
              if (bubble.left < stage.right - 0.5) continue;
              widened += bubble.left < stage.right + 40 ? 1 : 0;
              expect(
                bubble.left,
                greaterThanOrEqualTo(stage.right + 6 - 0.5),
                reason: '$n letters: the bubble $bubble is in the band of the rim beside the stage $stage',
              );
            }
            expect(widened, greaterThan(0), reason: 'the sweep reaches the widening path');
          },
        );
      }
    }

    testWidgets(
      'with the rooms off the bubble does not lie over the stage either (it may touch the stage\'s edge: there is no rim)',
      (WidgetTester t) async {
        for (final String board in <String>['phone', 'phoneSE']) {
          for (final double scale in <double>[1.0, 1.3]) {
            await frame(t, board, rooms: false, scale: scale);
            final Rect bubble = t.getRect(find.byKey(const Key('bubble-body')));
            final Rect stage = t.getRect(find.byKey(const Key('lesson-stage')));
            expect(
              bubble.overlaps(stage),
              isFalse,
              reason: '$board at $scale: the bubble $bubble over the stage $stage',
            );
          }
        }
      },
    );

    testWidgets(
      'with the rooms off the frame is the one of before M11 on every board: the small pointer (never the wedge), the own bubble edges of the layout',
      (WidgetTester t) async {
        for (final String board in _boards.keys) {
          await frame(t, board, rooms: false, scale: 1.0, text: 'כַּמָּה פְּרָחִים יֵשׁ בַּשָּׂדֶה?');
          expect(find.byKey(const Key('bubble-tail')), findsNothing, reason: board);
          expect(find.byKey(const Key('speaker-tail')), findsNothing, reason: board);
          expect(find.byKey(const Key('bubble-outline')), findsNothing, reason: board);
          final ActivitySpec spec = ActivitySpec.of(boardClassFor(_boards[board]!));
          final Rect body = t.getRect(find.byKey(const Key('bubble-body')));
          if (spec.bubbleLeft == null) {
            // Held by its right edge, where the layout puts it.
            expect(body.right, _boards[board]!.width - (spec.bubbleRight ?? 0), reason: board);
          } else {
            expect(
              body.left,
              lessThanOrEqualTo(spec.bubbleLeft!),
              reason: '$board: held by its left edge, widening toward the start',
            );
          }
        }
      },
    );
  });
}
