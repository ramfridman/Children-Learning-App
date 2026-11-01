import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/activity_shell.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/design/board.dart';
import 'package:nitznutz/play/activity_frame.dart';
import 'package:nitznutz/play/hint_hand.dart';
import 'package:nitznutz/play/hints/hint_marks.dart';
import 'package:nitznutz/play/hints/hint_pictures.dart';
import 'package:nitznutz/play/hints/tap_geometry.dart';
import 'package:nitznutz/play/hints/tap_plans.dart';

import 'support/harness.dart';

/// QA's defects of the B-36 pass (docs/qa/b36-verification.md), QA-B36-1, 2 and 3, fixed by the design-director: each test failed
/// before its fix and now runs in every suite. The items are read from the pack sources (as hint_second_way_test does), so the
/// tests hold before the new pack is signed and bundled.

void main() {
  const String sources = '../content/starter';
  late Map<String, String> svg;

  setUpAll(() async {
    await loadAppFonts();
    final Map<String, Object?> pack =
        jsonDecode(File('$sources/pack.json').readAsStringSync()) as Map<String, Object?>;
    svg = <String, String>{
      for (final Object? a in pack['assets']! as List<Object?>)
        (a! as Map<String, Object?>)['id']! as String: File('$sources/${(a as Map<String, Object?>)['file']}')
            .readAsStringSync(),
    };
  });

  TapAnswerActivity item(String id) => Activity.fromJson(
    jsonDecode(File('$sources/activity.$id.json').readAsStringSync()) as Map<String, Object?>,
    PackAssets(svg),
  ) as TapAnswerActivity;

  Size stageOf(ActivitySpec s) =>
      s.stageIsCard ? Size(s.stage.width - 32, s.stage.height - 32) : s.stage.size;
  Size boardOf(ActivitySpec s) => identical(s, ActivitySpec.phone)
      ? BoardClass.phone.size
      : identical(s, ActivitySpec.phoneSE)
      ? BoardClass.phoneSE.size
      : identical(s, ActivitySpec.tabletLandscape)
      ? BoardClass.tabletLandscape.size
      : BoardClass.tabletPortrait.size;
  final List<ActivitySpec> boards = <ActivitySpec>[
    ActivitySpec.phone,
    ActivitySpec.phoneSE,
    ActivitySpec.tabletLandscape,
    ActivitySpec.tabletPortrait,
  ];

  HintPlan plan(TapAnswerActivity a, int level, ActivitySpec spec) =>
      tapHintPlan(a, TapGeometry(a, stageOf(spec), spec), level)!;

  // The bubble's own box at its largest, and the grown box a long line takes (QA-B36-3): a sample must stay clear of both.
  Rect bubbleOf(ActivitySpec board) {
    final Size size = boardOf(board);
    final Rect own = board.bubbleLeft != null
        ? Rect.fromLTWH(board.bubbleLeft!, board.bubbleTop, board.bubbleMaxWidth, board.bubbleMaxHeight)
        : Rect.fromLTWH(
            size.width - board.bubbleRight! - board.bubbleMaxWidth,
            board.bubbleTop,
            board.bubbleMaxWidth,
            board.bubbleMaxHeight,
          );
    return own.expandToInclude(board.bubbleRoom);
  }

  // The worked example of every tap item the part D added: the hand reaches the right tile only in the last step, and the levels
  // before the third have no hand at all ("no answer framed or marked early"). Not a defect test: it holds today.
  test('a worked example puts the hand on the answer in its last step only, on every board', () {
    const List<String> ids = <String>[
      'b36.numa06.1',
      'b36.numa06.2',
      'b36.numa14.1',
      'b36.numa14.2',
      'x.numb07.21',
      'x.numb07.22',
      'b.numb17.13',
      'x.mathb17.12',
      'x.mathb17.13',
      'b.mathb18.10',
      'b.mathb18.11',
      'b.mathb07.9',
      'b.mathb08.15',
      'b.shpb08.10',
      'b.shpb08.5',
      'b15.shpa07.2',
      'b15.shpa08.1',
      'b15.shpa08.2',
      'b36.shpa06.1',
      'b36.shpa06.2',
      'b36.numa12.1',
      'b36.numa12.2',
      'b.numb16.1',
      'b.numb16.2',
      'b.numb16.9',
    ];
    for (final String id in ids) {
      final TapAnswerActivity a = item(id);
      for (final ActivitySpec board in boards) {
        final TapGeometry g = TapGeometry(a, stageOf(board), board);
        final Offset answer = g.optionTip(g.correctIndex);
        for (int level = 1; level <= 2; level++) {
          final HintPlan p = plan(a, level, board);
          expect(
            <HintMark>[for (final HintFrame f in p.frames) ...f.marks, ...p.rest].whereType<HandMark>(),
            isEmpty,
            reason: '$id level $level has a hand',
          );
        }
        final HintPlan p3 = plan(a, 3, board);
        for (final (int i, HintFrame f) in p3.frames.indexed) {
          final bool last = i == p3.frames.length - 1;
          for (final HandMark h in f.marks.whereType<HandMark>()) {
            if (!last) {
              expect(
                (h.tip - answer).distance,
                greaterThan(40),
                reason: '$id: the hand is on the answer in step $i of ${p3.frames.length}',
              );
            }
          }
        }
        expect(
          p3.frames.last.marks
              .whereType<HandMark>()
              .map((HandMark h) => (h.tip - answer).distance)
              .fold(999.0, (double p, double q) => q < p ? q : p),
          lessThan(1),
          reason: '$id ends on the answer on ${board.stage.size}',
        );
      }
    }
  });

  // QA-B36-1 (major, fixed). The sample that glides over the tiles (the written numeral of NUM-B-07, the outline of SHP-A-06, and the
  // swatches, outlines and copies of the older sample plans) stood on the top edge of each tile. When the right answer is the FIRST
  // option, a right-to-left row puts it at the right end, right under the speech bubble of a phone: in the last step the sample was
  // half under the bubble (x.numb07.21/.22, b36.shpa06.1/.2 and about 35 older items). Now, where any tile's sample would meet the
  // bubble, the whole glide goes under the tiles.
  test(
    'QA-B36-1: in the last step of a sample plan the sample is not under the speech bubble on a phone',
    () {
      final List<String> bad = <String>[];
      for (final File f in Directory(sources).listSync().whereType<File>()) {
        final String name = f.uri.pathSegments.last;
        if (!name.startsWith('activity.')) continue;
        final Map<String, Object?> j = jsonDecode(f.readAsStringSync()) as Map<String, Object?>;
        if (j['template'] != 'tap_answer') continue;
        final TapAnswerActivity a = item(j['id']! as String);
        for (final ActivitySpec board in <ActivitySpec>[ActivitySpec.phone, ActivitySpec.phoneSE]) {
          final Rect bubble = bubbleOf(board);
          final double inset = board.stageIsCard ? 16 : 0;
          final Offset origin = Offset(board.stage.left + inset, board.stage.top + inset);
          for (final HintMark m in plan(a, 3, board).frames.last.marks) {
            final Rect? box = switch (m) {
              GhostMark() => m.rect.shift(origin),
              SwatchMark() => m.rect.shift(origin),
              CopyMark() => m.rect.shift(origin),
              BadgeMark() when m.big => Rect.fromCenter(center: m.at + origin, width: 44, height: 44),
              _ => null,
            };
            if (box != null && box.overlaps(bubble.deflate(6))) {
              bad.add('${a.id} on ${board.stage.size}: the sample $box is under the bubble $bubble');
            }
          }
        }
      }
      expect(bad, isEmpty, reason: '${bad.length} cases\n${bad.join('\n')}');
    },
  );

  // QA-B36-3 (major on the small phone, fixed). A line that did not fit the speech bubble even at the smallest font (14) made the
  // bubble taller than its board allows: on the small phone it then lay over the top of the answer tiles (b36.numa14.2, b.numb16.2);
  // 318 prompts and level-3 lines did not fit. The texts are owner-approved, so the bubble makes room instead
  // (`ActivityFrame.fitBubble`): a line that does not fit its own box at 16 or more takes the board's grown box, wider toward the
  // guide and taller upward under the trail, its bottom 12 above the tiles. Every text the bubble can show (prompt, every hint,
  // every feedback line) must fit, at 14 or more, inside that box, on all four boards.
  test('QA-B36-3: every bubble line fits its bubble at the smallest font or more, and the bubble stays clear of the tiles', () {
    final List<String> bad = <String>[];
    int grown = 0, texts = 0;
    final List<String> lines = <String>[];
    void walk(Object? n) {
      if (n is Map<String, Object?>) {
        if (n['caption'] is List<Object?>) {
          final String t = (n['caption']! as List<Object?>)
              .map((Object? c) => (c! as Map<String, Object?>)['v']! as String)
              .join(' ');
          if (t.isNotEmpty) lines.add(t);
        }
        n.values.forEach(walk);
      } else if (n is List<Object?>) {
        n.forEach(walk);
      }
    }

    for (final File f in Directory(sources).listSync().whereType<File>()) {
      if (!f.uri.pathSegments.last.startsWith('activity.')) continue;
      final Map<String, Object?> j = jsonDecode(f.readAsStringSync()) as Map<String, Object?>;
      lines.clear();
      walk(j);
      for (final String text in lines) {
        texts++;
        for (final ActivitySpec board in boards) {
          final BubbleFit fit = ActivityFrame.fitBubble(text, board);
          final Rect room = board.bubbleRoom;
          if (fit.grown) grown++;
          final double bottom = fit.top + fit.height;
          if (fit.font < ActivityFrame.minFont || fit.top < room.top - 0.5 || bottom > room.bottom + 0.5) {
            bad.add(
              '${j['id']} on ${board.stage.size}: font ${fit.font}, ${fit.top.round()} to ${bottom.round()}, room $room: $text',
            );
          }
          // The box the bubble was fitted to stays inside the room.
          final double left = fit.left ?? (boardOf(board).width - board.bubbleRight! - fit.maxWidth);
          if (left < room.left - 0.5 || left + fit.maxWidth > room.right + 0.5) {
            bad.add(
              '${j['id']} on ${board.stage.size}: the bubble ($left, ${fit.maxWidth}) leaves the room $room',
            );
          }
        }
      }
    }
    // ignore: avoid_print
    print('QA-B36-3: $texts lines on four boards, $grown placements in the grown box');
    expect(bad, isEmpty, reason: '${bad.length} cases\n${bad.take(40).join('\n')}');
  });

  // QA-B36-2 (major, fixed). The pointing hand of the symbolic NUM-B-16 items goes to the empty places drawn at the stage's top left
  // corner; on a phone the hand's body ended up behind the eye button of the top bar. Now it comes from below there.
  testWidgets(
    'QA-B36-2: the hand of the symbolic NUM-B-16 worked example is not under the top bar on a phone',
    (WidgetTester t) async {
      await t.runAsync(warmHintHands);
      final List<String> bad = <String>[];
      for (final String id in <String>['b.numb16.2', 'b.numb16.4', 'b.numb16.6', 'b.numb16.8']) {
        final TapAnswerActivity a = item(id);
        for (final ActivitySpec board in <ActivitySpec>[ActivitySpec.phone, ActivitySpec.phoneSE]) {
          final Size size = boardOf(board);
          t.view.physicalSize = size;
          t.view.devicePixelRatio = 1;
          final Size stage = stageOf(board);
          final Rect bar = Rect.fromLTWH(0, 0, size.width, board.controlsTop + 56);
          for (final HintFrame f in plan(a, 3, board).frames) {
            for (final HandMark h in f.marks.whereType<HandMark>()) {
              await t.pumpWidget(
                MaterialApp(
                  home: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: <Widget>[
                        Positioned(
                          left: board.stage.left,
                          top: board.stage.top,
                          width: stage.width,
                          height: stage.height,
                          child: HintOverlay(
                            size: stage,
                            clearOf: handClearOf(board),
                            marks: <HintMark>[HandMark(h.tip, press: true, snap: true, from: h.from)],
                            layer: HintLayer.hands,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
              await t.pump(const Duration(milliseconds: 600));
              final RenderBox box = t.renderObject<RenderBox>(find.byType(PointingHand));
              final Rect hb = box.localToGlobal(Offset.zero) & box.size;
              // The fingertip is allowed to be near the bar; the palm and the finger are not allowed to be mostly behind it.
              final Rect hidden = hb.intersect(bar.deflate(6));
              if (!hidden.isEmpty && hidden.width * hidden.height > 0.25 * hb.width * hb.height) {
                bad.add('$id on ${board.stage.size}: the hand $hb is behind the top bar $bar');
              }
            }
          }
          t.view.reset();
        }
      }
      expect(bad, isEmpty, reason: bad.join('\n'));
    },
  );
}
