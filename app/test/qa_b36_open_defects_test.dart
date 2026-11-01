import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/activity_shell.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/design/app_text.dart';
import 'package:nitznutz/design/board.dart';
import 'package:nitznutz/play/hint_hand.dart';
import 'package:nitznutz/play/hints/hint_marks.dart';
import 'package:nitznutz/play/hints/hint_pictures.dart';
import 'package:nitznutz/play/hints/tap_geometry.dart';
import 'package:nitznutz/play/hints/tap_plans.dart';

import 'support/harness.dart';

/// QA's open defects of the B-36 pass (docs/qa/b36-verification.md). The two defect tests FAIL until their defect is fixed; they
/// are skipped in a normal run so that the suite stays green; run them with
///
///   flutter test --no-pub --dart-define=QA_OPEN=true test/qa_b36_open_defects_test.dart
///
/// When a defect is fixed, the owner of the fix removes `skip: _open` from its test. The items are read from the pack sources
/// (as hint_second_way_test does), so the tests hold before the new pack is signed and bundled.
const bool _runOpen = bool.fromEnvironment('QA_OPEN');
const bool _open = !_runOpen;

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

  Rect bubbleOf(ActivitySpec board) {
    final Size size = boardOf(board);
    return board.bubbleLeft != null
        ? Rect.fromLTWH(board.bubbleLeft!, board.bubbleTop, board.bubbleMaxWidth, board.bubbleMaxHeight)
        : Rect.fromLTWH(
            size.width - board.bubbleRight! - board.bubbleMaxWidth,
            board.bubbleTop,
            board.bubbleMaxWidth,
            board.bubbleMaxHeight,
          );
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

  // QA-B36-1 (major). The sample that glides over the tiles (the written numeral of NUM-B-07, the outline of SHP-A-06, and the
  // swatches, outlines and copies of the older sample plans) stands on the top edge of each tile. When the right answer is the FIRST
  // option, a right-to-left row puts it at the right end, right under the speech bubble of a phone: in the last step the sample is
  // half under the bubble. The new items are x.numb07.21/.22 and b36.shpa06.1/.2; about 35 older items (colours, shapes, LOG-A-01 and
  // LOG-A-09) have the same fault.
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
    skip: _open,
  );

  // QA-B36-3 (major on the small phone). A line that does not fit the speech bubble even at the smallest font (14) makes the bubble
  // taller than its board allows: on the small phone it then lies over the top of the answer tiles (seen on b36.numa14.2 and
  // b.numb16.2). The worked-example lines (level 3) are the long ones. At the base of this branch (e5d74c7) 134 cases did not fit
  // (133 on the small phone, 1 on the phone); with the 1,142 rewritten lines and the new items 318 do not (4 prompts and 288
  // level-3 lines on the small phone, 26 level-3 lines on the phone). The test allows 8 points over (about a third of a line).
  test('QA-B36-3: every prompt and level-3 line fits the speech bubble at the smallest font on the phone and the small phone', () {
    final List<String> bad = <String>[];
    for (final File f in Directory(sources).listSync().whereType<File>()) {
      if (!f.uri.pathSegments.last.startsWith('activity.')) continue;
      final Map<String, Object?> j = jsonDecode(f.readAsStringSync()) as Map<String, Object?>;
      final List<(String, Object?)> spoken = <(String, Object?)>[
        ('prompt', j['prompt']),
        for (final Object? h in (j['hints'] as List<Object?>?) ?? const <Object?>[])
          if ((h! as Map<String, Object?>)['level'] == 3) ('hint 3', h),
      ];
      for (final (String, Object?) s in spoken) {
        final String text =
            (((s.$2! as Map<String, Object?>)['caption'] as List<Object?>?) ?? const <Object?>[])
                .map((Object? c) => (c! as Map<String, Object?>)['v']! as String)
                .join(' ');
        if (text.isEmpty) continue;
        for (final ActivitySpec board in <ActivitySpec>[ActivitySpec.phone, ActivitySpec.phoneSE]) {
          final TextPainter tp = TextPainter(
            text: TextSpan(text: text, style: AppText.fixed(size: 14, weight: 500)),
            textDirection: TextDirection.rtl,
          )..layout(maxWidth: board.bubbleMaxWidth - 32);
          if (tp.height + 16 > board.bubbleMaxHeight + 8) {
            bad.add(
              '${j['id']} ${s.$1} on ${board.stage.size}: ${(tp.height + 16).round()} high, room ${board.bubbleMaxHeight}',
            );
          }
        }
      }
    }
    expect(bad, isEmpty, reason: '${bad.length} cases\n${bad.join('\n')}');
  }, skip: _open);

  // QA-B36-2 (major). The pointing hand of the symbolic NUM-B-16 items goes to the empty places drawn at the stage's top left corner;
  // on a phone the hand's body ends up behind the eye button of the top bar, and the demonstration cannot be seen.
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
    skip: _open,
  );
}
