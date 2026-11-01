import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/activity_shell.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/play/hints/hint_marks.dart';
import 'package:nitznutz/play/hints/tap_geometry.dart';
import 'package:nitznutz/play/hints/tap_plans.dart';
import 'package:nitznutz/play/lesson_controller.dart';
import 'package:nitznutz/play/sprite_group.dart';
import 'package:nitznutz/play/tap_answer_session.dart';

import 'support/fakes.dart';
import 'support/harness.dart';
import 'support/starter.dart';

/// B-36 part B (NUM-B-16): a stage that has groups (the two ten-frames of a teen) and also a numeral or a row draws the groups on
/// top and the numeral or row under them, never over them, on every board; the hint's geometry stands on the same places. The
/// bundled pack has no such activity yet, so the two kinds are made here from `b.numb16.3` and `b.numb16.2`.
void main() {
  late PackContent content;
  setUpAll(() async {
    await loadAppFonts();
    content = await loadStarter();
  });

  final List<(String, ActivitySpec)> boards = <(String, ActivitySpec)>[
    ('phone', ActivitySpec.phone),
    ('phone_se', ActivitySpec.phoneSE),
    ('tablet_landscape', ActivitySpec.tabletLandscape),
    ('tablet_portrait', ActivitySpec.tabletPortrait),
  ];

  Size stageOf(ActivitySpec s) =>
      s.stageIsCard ? Size(s.stage.width - 32, s.stage.height - 32) : s.stage.size;

  /// The activity [id] of the pack with its scene changed by [edit].
  TapAnswerActivity variant(String id, void Function(Map<String, Object?> scene) edit) {
    final Map<String, Object?> json =
        jsonDecode(jsonEncode(content.activities[id]!.json)) as Map<String, Object?>;
    edit(json['scene']! as Map<String, Object?>);
    return Activity.fromJson(json, content.assets) as TapAnswerActivity;
  }

  /// The frames item of NUM-B-16 with the teen it makes written large: ten and three, and 13.
  TapAnswerActivity framesAndNumeral([int numeral = 13]) =>
      variant('b.numb16.3', (Map<String, Object?> scene) => scene['numeral'] = numeral);

  /// The sentence item of NUM-B-16 (12 = 10 + ?) with the two frames over it.
  TapAnswerActivity framesAndSentence() => variant('b.numb16.2', (Map<String, Object?> scene) {
    scene['group'] = <String, Object?>{
      'sprite': 'asset:duck',
      'count': 10,
      'arrangement': 'ten_frame',
      'seed': 3,
      'scale': 1,
    };
    scene['group2'] = <String, Object?>{
      'sprite': 'asset:duck',
      'count': 2,
      'arrangement': 'ten_frame',
      'seed': 8,
      'scale': 1,
    };
  });

  Future<TapAnswerSession> host(WidgetTester tester, TapAnswerActivity a, ActivitySpec spec) async {
    final LessonController c = LessonController(
      content: content,
      lesson: Lesson.mission(
        id: 'one',
        itemIds: <String>[a.id],
        skillIds: <String>[a.skillId],
        celebration: content.lessons.values.first.celebration,
      ),
      profileId: 'p-1',
      clock: FixedClock(1793000000000),
      record: (AttemptRecord r) async {},
    );
    final TapAnswerSession s = TapAnswerSession(c, a);
    final Size stage = stageOf(spec);
    await tester.pumpWidget(
      MaterialApp(
        builder: (BuildContext context, Widget? child) =>
            MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: true), child: child!),
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: stage.width,
                height: stage.height,
                child: Builder(builder: (BuildContext ctx) => s.buildStage(ctx, stage, spec)),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    return s;
  }

  /// Everything that is drawn on the stage and must keep apart, in the stage's own points.
  ({Rect stage, List<Rect> frames, List<Rect> groups, Rect? numeral, Rect? row}) drawn(WidgetTester t) {
    final Rect stage = t.getRect(find.byKey(const Key('tap-stage')));
    Rect rel(Finder f) => t.getRect(f).shift(-stage.topLeft);
    return (
      stage: Offset.zero & stage.size,
      frames: <Rect>[
        for (final Element e in find.byWidgetPredicate((Widget w) {
          final Key? k = w.key;
          return k is ValueKey<String> && k.value.startsWith('group-ten-frame');
        }).evaluate())
          rel(find.byWidget(e.widget)),
      ],
      groups: <Rect>[
        for (final Element e
            in find
                .descendant(of: find.byKey(const Key('tap-groups')), matching: find.byType(SpriteGroup))
                .evaluate())
          rel(find.byWidget(e.widget)),
      ],
      numeral: find.byKey(const Key('stage-numeral')).evaluate().isEmpty
          ? null
          : rel(find.byKey(const Key('stage-numeral'))),
      row: find.byKey(const Key('tap-row')).evaluate().isEmpty ? null : rel(find.byKey(const Key('tap-row'))),
    );
  }

  /// The checks every stacked stage must pass on every board.
  Future<void> checkStacked(WidgetTester t, TapAnswerActivity a, String board, ActivitySpec spec) async {
    final String why = '${a.id} on $board';
    final TapAnswerSession s = await host(t, a, spec);
    final d = drawn(t);
    final TapGeometry g = TapGeometry(a, stageOf(spec), spec);
    expect(g.stacked, isTrue, reason: why);

    // Two frames, the full ten on the left (left to right whatever the language), both inside the stage.
    expect(d.frames, hasLength(2), reason: why);
    expect(d.frames[0].left, lessThan(d.frames[1].left), reason: '$why: the ten is first');
    expect(d.frames[0].width, closeTo(d.frames[1].width, 0.5), reason: '$why: the same frame twice');
    final Rect frames = d.frames[0].expandToInclude(d.frames[1]);
    expect(d.stage.contains(frames.topLeft) && d.stage.contains(frames.bottomRight), isTrue, reason: why);

    // The numeral or the row stands under the frames, with room between, and inside the stage.
    final Rect under = d.numeral ?? d.row!;
    expect(under.top, greaterThanOrEqualTo(frames.bottom), reason: '$why: nothing over the frames');
    expect(under.bottom, lessThanOrEqualTo(d.stage.bottom + 0.5), reason: why);
    expect(under.left, greaterThanOrEqualTo(-0.5), reason: why);
    expect(under.right, lessThanOrEqualTo(d.stage.right + 0.5), reason: why);
    if (d.numeral != null) {
      expect(d.numeral!.center.dx, closeTo(d.stage.center.dx, 1), reason: '$why: centred under the frames');
      expect(d.numeral!.height, greaterThanOrEqualTo(34), reason: '$why: big enough to read');
    }

    // The hint stands on the same places: the group cells, the numeral, the cells of the row.
    for (int which = 0; which < 2; which++) {
      expect(
        d.groups[which].center.dx,
        closeTo(g.groupCell(which).center.dx, 1),
        reason: '$why: group $which',
      );
      expect(
        d.groups[which].center.dy,
        closeTo(g.groupCell(which).center.dy, 1),
        reason: '$why: group $which',
      );
      final Rect planned = g.groupObjects(which, count: 10).first;
      expect(d.frames[which].contains(planned.center), isTrue, reason: '$why: first cell of group $which');
    }
    if (d.numeral != null) {
      expect(g.stageNumeral.contains(d.numeral!.center), isTrue, reason: '$why: the numeral');
      expect(g.stageNumeral.top, greaterThanOrEqualTo(g.groupArea.bottom - 0.5), reason: why);
    }
    if (d.row != null) {
      expect(g.lowerArea.contains(g.rowCells().first.center), isTrue, reason: '$why: the row');
      expect(d.row!.top, greaterThanOrEqualTo(frames.bottom), reason: why);
    }

    // Level 1 lights the frames' cells; nothing it lights reaches across the line between the two bands.
    final HintPlan one = tapHintPlan(a, g, 1)!;
    final List<Rect> holes = <Rect>[
      for (final HintFrame f in one.frames)
        for (final VeilMark v in f.marks.whereType<VeilMark>()) ...v.holes,
    ];
    expect(holes, isNotEmpty, reason: why);
    for (final Rect r in holes) {
      expect(r.bottom <= g.groupArea.bottom + 0.5 || r.top >= g.lowerArea.top - 0.5, isTrue, reason: why);
    }
    // With the frames on the stage the hint counts them (never cubes over the sentence, which would land on the frames).
    expect(
      holes.any((Rect r) => r.bottom <= g.groupArea.bottom + 0.5),
      isTrue,
      reason: '$why: the frames are lit',
    );
    for (int level = 2; level <= 3; level++) {
      final HintPlan p = tapHintPlan(a, g, level)!;
      final Iterable<HintMark> marks = <HintMark>[for (final HintFrame f in p.frames) ...f.marks, ...p.rest];
      expect(
        marks.whereType<BlockMark>(),
        isEmpty,
        reason: '$why: level $level draws no cubes over the numbers',
      );
    }
    s.dispose();
    await t.pumpWidget(const SizedBox());
  }

  group('groups and a numeral on one stage', () {
    for (final (String, ActivitySpec) b in boards) {
      testWidgets('two ten-frames and the teen under them, ${b.$1}', (WidgetTester t) async {
        await checkStacked(t, framesAndNumeral(), b.$1, b.$2);
        await checkStacked(t, framesAndNumeral(19), b.$1, b.$2);
      });

      testWidgets('two ten-frames and the sentence under them, ${b.$1}', (WidgetTester t) async {
        await checkStacked(t, framesAndSentence(), b.$1, b.$2);
      });
    }

    testWidgets('every activity of the pack with groups and a numeral or a row is stacked and keeps apart', (
      WidgetTester t,
    ) async {
      final List<TapAnswerActivity> found = <TapAnswerActivity>[
        for (final TapAnswerActivity a in content.activities.values.whereType<TapAnswerActivity>())
          if (a.group != null && (a.stageNumeral != null || a.row.isNotEmpty)) a,
      ];
      for (final TapAnswerActivity a in found) {
        for (final (String, ActivitySpec) b in boards) {
          final TapGeometry g = TapGeometry(a, stageOf(b.$2), b.$2);
          expect(g.stacked, isTrue, reason: '${a.id} on ${b.$1}');
          expect(g.groupArea.bottom, lessThanOrEqualTo(g.lowerArea.top + 0.01), reason: '${a.id} on ${b.$1}');
        }
      }
    });
  });

  group('a stage that is not stacked keeps its places', () {
    test('a numeral alone is in the middle of the stage, a row alone has the whole stage', () {
      for (final (String, ActivitySpec) b in boards) {
        final Size size = stageOf(b.$2);
        final TapAnswerActivity numeral = content.activities['show.apples.3']! as TapAnswerActivity;
        final TapGeometry g = TapGeometry(numeral, size, b.$2);
        expect(g.stacked, isFalse);
        expect(g.stageNumeral.center.dx, closeTo(size.width / 2, 0.01), reason: b.$1);
        expect(g.stageNumeral.center.dy, closeTo(size.height / 2, 0.01), reason: b.$1);
        expect(g.stageNumeralFont, size.height * 0.7, reason: b.$1);

        final TapAnswerActivity row = content.activities['b.numb16.2']! as TapAnswerActivity;
        final TapGeometry r = TapGeometry(row, size, b.$2);
        expect(r.stacked, isFalse);
        final double lift = (size.height * 0.26).roundToDouble();
        final double cellW = (size.width - 20) / row.row.length;
        final Rect first = r.rowCells().first;
        expect(
          first.width,
          closeTo(cellW - 6 < size.height - 26 - lift ? cellW - 6 : size.height - 26 - lift, 0.01),
        );
        expect(first.center.dy, closeTo((size.height + lift) / 2, 0.01), reason: b.$1);
        expect(r.rowTop, 13 + lift, reason: b.$1);
      }
    });

    test('groups alone keep their margins and the whole stage (or its upper half over stage options)', () {
      for (final (String, ActivitySpec) b in boards) {
        final Size size = stageOf(b.$2);
        final TapAnswerActivity frames = content.activities['b.numb16.3']! as TapAnswerActivity;
        final TapGeometry g = TapGeometry(frames, size, b.$2);
        expect(g.stacked, isFalse);
        expect(g.groupArea, Rect.fromLTWH(0, 0, size.width, size.height), reason: b.$1);
        expect(g.groupCell(0).left, 18, reason: '12 and 6');
      }
    });
  });
}
