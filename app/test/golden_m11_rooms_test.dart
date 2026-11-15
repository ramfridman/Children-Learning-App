// M11 Stage 1 goldens (docs/design/m11-rooms.md section 10): the nine rooms on the phone, the small phone and the tablets as the host beat
// (the greeting: the host in front, the companion behind, the stage empty with its backdrop and landmark), the child's turn in the same room,
// the stage's end state after a right answer, and the celebration with the landmark's new piece. Over them the greyscale check of
// acceptance criterion 1: the nine rooms differ pairwise (backdrop, frame, trail) also in grey, on each board.
//
// Regenerate after a deliberate visual change:  flutter test --update-goldens test/golden_m11_rooms_test.dart
// Run this file alone, and `git checkout` any golden of another file that a run rewrote.
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/rooms/room_spec.dart';
import 'package:nitznutz/strings/he.dart' show HostHe;

import 'support/golden_comparator.dart';
import 'support/harness.dart';
import 'support/l4_golden.dart' show waitFor;
import 'support/m11_rooms.dart';

typedef _Board = ({String name, Size size});

const _Board _phone = (name: 'phone', size: Size(852, 393));
const _Board _se = (name: 'phone_se', size: Size(667, 375));
const _Board _landscape = (name: 'tablet_landscape', size: Size(1180, 820));
const _Board _portrait = (name: 'tablet_portrait', size: Size(820, 1180));

Future<void> _shot(WidgetTester tester, String name) =>
    expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/$name.png'));

/// The screen as grey levels (0 to 255), the way a golden captures it.
Future<Uint8List> _grey(WidgetTester tester) async {
  RenderObject ro = tester.renderObject(find.byType(MaterialApp));
  while (!ro.isRepaintBoundary) {
    ro = ro.parent!;
  }
  final OffsetLayer layer = ro.debugLayer! as OffsetLayer;
  final Uint8List rgba = (await tester.runAsync(() async {
    final ui.Image image = await layer.toImage(ro.paintBounds);
    final ByteData data = (await image.toByteData())!;
    return data.buffer.asUint8List();
  }))!;
  final Uint8List grey = Uint8List(rgba.length ~/ 4);
  for (int i = 0; i < grey.length; i++) {
    grey[i] = (0.299 * rgba[4 * i] + 0.587 * rgba[4 * i + 1] + 0.114 * rgba[4 * i + 2]).round();
  }
  return grey;
}

/// The share of pixels at which two grey pictures differ by more than [step] levels.
double _differ(Uint8List a, Uint8List b, {int step = 12}) {
  int n = 0;
  for (int i = 0; i < a.length; i++) {
    if ((a[i] - b[i]).abs() > step) n++;
  }
  return n / a.length;
}

Future<void> _open(WidgetTester tester, RoomId room, Size size, {bool reduceMotion = true}) async {
  await tester.pumpWidget(const SizedBox.shrink());
  final (PackContent c, Lesson l) = await roomLesson(room);
  await openRoomLesson(tester, c, l, size, reduceMotion: reduceMotion);
}

void main() {
  setUpAll(() async {
    await loadAppFonts();
    useTolerantGoldens(0.03);
  });

  // ---- the host beat: nine rooms on each board (and two on the tall tablet), and the grey check ----
  for (final _Board board in <_Board>[_phone, _se, _landscape]) {
    testWidgets('the nine host beats on the ${board.name} (and differ pairwise, in grey too)', (
      WidgetTester tester,
    ) async {
      final Map<RoomId, Uint8List> grey = <RoomId, Uint8List>{};
      for (final RoomId room in RoomId.values) {
        await _open(tester, room, board.size);
        await _shot(tester, 'm11_room_${room.name}_show_${board.name}');
        grey[room] = await _grey(tester);
      }
      double least = 1;
      for (int i = 0; i < RoomId.values.length; i++) {
        for (int j = i + 1; j < RoomId.values.length; j++) {
          final double d = _differ(grey[RoomId.values[i]]!, grey[RoomId.values[j]]!);
          least = d < least ? d : least;
          expect(
            d,
            greaterThan(_greyShare),
            reason:
                '${RoomId.values[i].name} and ${RoomId.values[j].name} on the ${board.name}: ${(d * 100).toStringAsFixed(2)}% of the pixels differ',
          );
        }
      }
      // ignore: avoid_print
      print('least grey difference on the ${board.name}: ${(least * 100).toStringAsFixed(2)}%');
    });
  }

  testWidgets('the host beat on the tall tablet: Counting Hills and English', (WidgetTester tester) async {
    for (final RoomId room in <RoomId>[RoomId.numbers, RoomId.eng]) {
      await _open(tester, room, _portrait.size);
      await _shot(tester, 'm11_room_${room.name}_show_${_portrait.name}');
    }
  });

  testWidgets('the longest host line at text scale 1.3: the bubble clear of the stage and of the pair', (
    WidgetTester tester,
  ) async {
    final RoomSpec longest = RoomSpec.all.reduce(
      (RoomSpec a, RoomSpec b) =>
          HostHe.greetings[a.hostId]!.text.length >= HostHe.greetings[b.hostId]!.text.length ? a : b,
    );
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _open(tester, longest.id, _phone.size);
    await _shot(tester, 'm11_room_${longest.name}_show_phone_text_1_3');
    final Rect bubble = tester.getRect(find.byKey(const Key('lesson-bubble')));
    final Rect stage = tester.getRect(find.byKey(const Key('lesson-stage')));
    final Rect host = tester.getRect(find.byKey(const Key('room-host')));
    expect(bubble.left, greaterThanOrEqualTo(stage.right + 4), reason: 'clear of the stage and its rim');
    expect(bubble.right, lessThanOrEqualTo(host.left + 8), reason: 'clear of the host');
  });

  // ---- the child's turn, the end state of the reaction and the celebration, in each room ----
  for (final RoomId room in RoomId.values) {
    testWidgets('${room.name}: the child\'s turn, the stage\'s end state and the celebration on the phone', (
      WidgetTester tester,
    ) async {
      final (PackContent c, Lesson l) = await roomLesson(room);
      await _open(tester, room, _phone.size, reduceMotion: false);
      await tester.tapAt(const Offset(300, 330));
      await waitFor(tester, 1200);
      await _shot(tester, 'm11_room_${room.name}_alone_phone');
      await tester.tap(
        find.byWidgetPredicate(
          (Widget w) =>
              w.key == Key('tile-${rightOption(c, l, 0)}') || w.key == Key('option-${rightOption(c, l, 0)}'),
        ),
      );
      // The reaction settles 1,120 ms after the answer is accepted (220 ms for the check badge, then at most 900 ms of motion) and the page
      // turns 1,300 to 1,600 ms after it: the picture is taken at 1,250, when the end state stands and the item is still on.
      await waitFor(tester, 1200);
      expect(
        find.text(c.activities[l.itemIds[1]]!.promptLine.caption),
        findsNothing,
        reason: '${room.name}: the next item is not on yet',
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('stage-reaction')),
          matching: find.byWidgetPredicate(
            (Widget w) =>
                w is SvgPicture &&
                w.bytesLoader is SvgAssetLoader &&
                (w.bytesLoader as SvgAssetLoader).assetName.endsWith('_reacted.svg'),
          ),
        ),
        findsOneWidget,
        reason: '${room.name}: the end state is on the screen when the picture is taken',
      );
      await _shot(tester, 'm11_room_${room.name}_reacted_phone');
      await waitFor(tester, 400);
      for (int i = 0; i < l.itemIds.length; i++) {
        if (i > 0) {
          await tester.tap(
            find.byWidgetPredicate(
              (Widget w) =>
                  w.key == Key('tile-${rightOption(c, l, i)}') ||
                  w.key == Key('option-${rightOption(c, l, i)}'),
            ),
          );
        }
        await waitFor(tester, 2600);
      }
      await waitFor(tester, 1500);
      await _shot(tester, 'm11_celebration_${room.name}_phone');
    });
  }

  testWidgets('with reduce motion the end state is the same picture of the landmark as after the motion', (
    WidgetTester tester,
  ) async {
    Future<Uint8List> landmark(bool reduced) async {
      final (PackContent c, Lesson l) = await roomLesson(RoomId.numbers);
      await _open(tester, RoomId.numbers, _phone.size, reduceMotion: reduced);
      await tester.tapAt(const Offset(300, 330));
      await waitFor(tester, 1200);
      await tester.tap(find.byKey(Key('tile-${rightOption(c, l, 0)}')));
      await waitFor(tester, 1200);
      if (reduced) await _shot(tester, 'm11_room_numbers_reacted_phone_reduce_motion');
      return _grey(tester);
    }

    final Uint8List moving = await landmark(false);
    final Uint8List still = await landmark(true);
    // The two pictures differ only where the companion breathes: the landmark's place in the header (645 to 709, 12 to 76) is the same.
    int differing = 0;
    const int width = 852;
    for (int y = 8; y < 80; y++) {
      for (int x = 640; x < 716; x++) {
        if ((moving[y * width + x] - still[y * width + x]).abs() > 12) differing++;
      }
    }
    expect(differing, lessThan(40), reason: 'the end state is one picture, with or without the motion');
  });

  // ---- the celebration on the other boards ----
  for (final RoomId room in <RoomId>[RoomId.numbers, RoomId.cs]) {
    for (final _Board board in <_Board>[_se, _landscape]) {
      testWidgets('${room.name}: the celebration on the ${board.name}', (WidgetTester tester) async {
        final (PackContent c, Lesson l) = await roomLesson(room);
        await _open(tester, room, board.size);
        await tester.tapAt(Offset(board.size.width / 2, board.size.height - 40));
        await waitFor(tester, 800);
        for (int i = 0; i < l.itemIds.length; i++) {
          await tester.tap(
            find.byWidgetPredicate(
              (Widget w) =>
                  w.key == Key('tile-${rightOption(c, l, i)}') ||
                  w.key == Key('option-${rightOption(c, l, i)}'),
            ),
          );
          await waitFor(tester, 2600);
        }
        await _shot(tester, 'm11_celebration_${room.name}_${board.name}');
      });
    }
  }
}

/// How much of the picture must differ, in grey, between two rooms of one board: 3% of the pixels by more than 12 of 255 levels (the least measured is 6.2%).
const double _greyShare = 0.03;
