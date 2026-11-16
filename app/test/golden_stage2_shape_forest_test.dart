// M11 Stage 2 (docs/milestones/M11-stage2.md section 7.3 and 2.7, design docs/design/m11-rooms.md section 13): the Show, the Together lead and the hand-over of
// Shape Forest on the real lesson screen, in the room, for a child new to the skill. Every motion the developer built is caught while the host's
// pointer is on it (trace, count, sticks, the ant's walk, the sorter's hole, the corners). The pictures are named stage2_<lesson>_<state>_<board>.
//
// Regenerate after a deliberate visual change:  flutter test --update-goldens test/golden_stage2_shape_forest_test.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/engine/age.dart';
import 'package:nitznutz/parent/age_settings.dart';
import 'package:nitznutz/play/lesson_screen.dart';
import 'package:nitznutz/play/show_stage.dart';

import 'support/app_harness.dart';
import 'support/bubble_audit.dart' show AuditLook;
import 'support/golden_comparator.dart';
import 'support/harness.dart';
import 'support/l4_golden.dart' show waitFor;
import 'support/starter.dart';
import 'support/voice_fixtures.dart';

const AuditLook _p4 = (name: 'P4', school: SchoolStage.grade2, birth: BirthMonth(2019, 5), captions: null);
const AuditLook _p2 = (name: 'P2', school: SchoolStage.gan3, birth: BirthMonth(2022, 2), captions: null);

Future<void> _shot(WidgetTester t, String name) =>
    expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/$name.png'));

/// Opens [lessonId] of the starter sources on the lesson screen in its room, for a child new to every skill, and gives the host's lines a clip
/// that ends by itself.
Future<void> _open(
  WidgetTester t,
  PackContent content,
  String lessonId,
  Size board, {
  AuditLook look = _p4,
  double scale = 1.0,
  bool still = false,
}) async {
  await t.runAsync(() => ShowArt.load());
  t.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
  final AppRig rig = AppRig(
    content: content,
    rooms: true,
    player: FakePlayer()..endsAfter = const Duration(milliseconds: 1200),
  );
  await rig.seedFinishedSetup(name: 'נֹעָה', ageBand: look.school.band);
  await rig.db.confirmStage('p-1', look.school, DateTime(2026, 10, 26));
  await rig.db.setBirth('p-1', look.birth);
  await rig.pump(t, size: board, reduceMotion: still);
  await t.tap(find.text('נֹעָה'));
  await t.pump(const Duration(milliseconds: 500));
  t
      .state<NavigatorState>(find.byType(Navigator).first)
      .push(
        MaterialPageRoute<void>(
          builder: (BuildContext c) => LessonScreen(profileId: 'p-1', lessonId: lessonId),
        ),
      );
  // the screen reads the profile, the engine's standing and the pictures of the Show off the main thread: real time is let pass
  for (int i = 0; i < 60 && (i < 3 || find.byType(RichText).evaluate().isEmpty); i++) {
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 150)));
    await t.pump(const Duration(milliseconds: 100));
  }
}

ShowMarks? _marks(WidgetTester t) {
  final Finder f = find.byType(ShowLayer);
  return f.evaluate().isEmpty ? null : t.widget<ShowLayer>(f.first).marks;
}

/// Pumps until [until] holds (100 ms at a time), at most [limit] ms; false when it never did.
Future<bool> _until(WidgetTester t, bool Function() until, {int limit = 60000}) async {
  for (int spent = 0; spent < limit; spent += 100) {
    if (until()) return true;
    await t.pump(const Duration(milliseconds: 100));
  }
  return until();
}

bool _drawing(ShowMarks? m) =>
    m != null &&
    m.spot != null &&
    (m.tip != null || m.ant != null || m.sticks.isNotEmpty) &&
    (m.lit.isNotEmpty || m.badges.isNotEmpty || m.sticks.isNotEmpty || m.drawing.length > 1 || m.ant != null);

typedef Board = (String, Size);
const Board phone = ('phone', Size(852, 393));
const Board phoneSE = ('phoneSE', Size(667, 375));
const Board tabletP = ('tabletP', Size(820, 1180));
const Board tabletL = ('tabletL', Size(1180, 820));

/// The Show of [lessonId] with its pointer at work, then (when [rest]) the hand-over, the child's own last move, the host's lead in Together and
/// the child's turn there. Every state is a golden `stage2_<tag>_<state>_<board>`.
Future<void> _lesson(
  WidgetTester t,
  PackContent content,
  String lessonId,
  String tag,
  Board board, {
  AuditLook look = _p4,
  double scale = 1.0,
  bool rest = true,
  bool motion = true,
  bool badges = false,
  String? suffix,
  bool Function(ShowMarks m)? seen,
  int settle = 700,
}) async {
  final String sfx = '${board.$1}${suffix ?? ''}';
  await _open(t, content, lessonId, board.$2, look: look, scale: scale);
  final LessonParts parts = content.lessons[lessonId]!.parts!;
  final Activity show = content.activities[parts.show]!;
  final ShowScript script = show.show!;
  final bool builder = show is ShapeBuilderActivity;
  final bool drawn =
      !motion ||
      await _until(
        t,
        () => seen != null
            ? _marks(t) != null && seen(_marks(t)!)
            : badges
            ? (_marks(t)?.badges.length ?? 0) >= 2
            : builder
            ? _marks(t)?.tip != null
            : _drawing(_marks(t)),
      );
  expect(drawn, isTrue, reason: '$lessonId: the hosts pointer draws on the shape');
  await waitFor(t, settle);
  if (!motion) await waitFor(t, 2500); // the host has put its first piece
  await _shot(t, 'stage2_${tag}_show_$sfx');
  if (!rest) return;
  // the hand-over: the host's last line is in the bubble and its pointer has gone
  final String hand = script.lines['handover']!.caption;
  // a child of four reads no captions (B-29): the bubble is then not drawn, and the hand-over is a moment of the clock
  if (look == _p2) {
    await waitFor(t, 24000);
  } else {
    expect(
      await _until(t, () => find.text(hand).evaluate().isNotEmpty),
      isTrue,
      reason: '$lessonId: the hand-over line comes',
    );
    await waitFor(t, 3500);
  }
  await _shot(t, 'stage2_${tag}_handover_$sfx');
  // the child's own move: the last card into its bin
  if (show is! SortDragActivity || look == _p2) return;
  final String item = script.childStep.item!;
  final Finder card = find.byKey(Key('item-$item'));
  final Finder bin = find.byKey(Key('bin-${script.childStep.bin}'));
  expect(card, findsOneWidget, reason: '$lessonId: the childs card waits');
  await t.dragFrom(t.getCenter(card), t.getCenter(bin) - t.getCenter(card));
  await waitFor(t, 400);
  // Together: the host leads
  final TogetherItem lead = parts.together.first;
  expect(
    await _until(t, () => find.text(lead.line!.caption).evaluate().isNotEmpty),
    isTrue,
    reason: '$lessonId: the Together line',
  );
  await waitFor(t, 1500);
  await _shot(t, 'stage2_${tag}_together_$sfx');
  // the child's turn: the lead is done, the companion asks
  await waitFor(t, 9000);
  await _shot(t, 'stage2_${tag}_turn_$sfx');
}

void main() {
  late PackContent content;
  setUpAll(() async {
    await loadAppFonts();
    useTolerantGoldens(0.03);
    content = await loadSourcePack();
  });

  // The four boards, one Show of the trace kind: the pointer never lies across the shape, the marks read, nothing is clipped.
  for (final Board b in <Board>[phone, phoneSE, tabletP, tabletL]) {
    testWidgets('A-03 on ${b.$1}: the Show, the hand-over, the lead and the turn', (WidgetTester t) async {
      await _lesson(t, content, 'any-shape', 'anyshape', b);
    });
  }

  // Text at 1.3 on the two phones, and a child of four (slower, a younger look).
  for (final Board b in <Board>[phone, phoneSE]) {
    testWidgets('A-03 on ${b.$1} at text 1.3', (WidgetTester t) async {
      await _lesson(t, content, 'any-shape', 'anyshape', b, scale: 1.3, suffix: '_t13');
    });
  }
  testWidgets('A-03 on the phone for a child of four', (WidgetTester t) async {
    await _lesson(t, content, 'any-shape', 'anyshape', phone, look: _p2, suffix: '_p2');
  });
  testWidgets('A-03 on the small phone for a child of four at text 1.3', (WidgetTester t) async {
    await _lesson(t, content, 'any-shape', 'anyshape', phoneSE, look: _p2, scale: 1.3, suffix: '_p2_t13');
  });

  // Every motion that is built, on the phone (the tablets draw the same motion, larger; see the four boards above and the count on the tablets).
  for (final (String, String) m in <(String, String)>[
    ('shape-friends', 'hole'), // trace: hole (the sorter), builder
    ('rectangle', 'sticks'), // sticks
    ('polygon-detectives', 'count'), // count: sides
    ('count-sides', 'countbin'), // count into a bin
    ('closed-shapes', 'walk'), // the ant
    ('one-shadow', 'corners'), // trace: corners, builder
    ('shapes-around-us', 'outline'), // trace: outline
    ('square-or-rectangle', 'sticks2'),
    ('shapes-make-shapes', 'builder'),
    ('build-with-shapes', 'builder'),
  ]) {
    testWidgets('${m.$1}: the ${m.$2} Show on the phone', (WidgetTester t) async {
      await _lesson(
        t,
        content,
        m.$1,
        m.$1.replaceAll('-', ''),
        phone,
        motion: m.$2 != 'builder',
        badges: m.$2 == 'count' || m.$2 == 'countbin',
      );
    });
  }
  testWidgets('count on the tablets', (WidgetTester t) async {
    await _lesson(t, content, 'polygon-detectives', 'polygondetectives', tabletL, rest: false, badges: true);
  });
  testWidgets('sticks on the small phone at 1.3', (WidgetTester t) async {
    await _lesson(t, content, 'rectangle', 'rectangle', phoneSE, scale: 1.3, rest: false, suffix: '_t13');
  });

  // The solids' motions (QA-4): the ball pushed and rolling with its speed lines, the solid turned with the orbit arrow half way round, the print in the
  // sand being traced; and the tracing Show, the host's pointer on a side of the triangle with the sides before it staying lit.
  for (final (String, String, bool Function(ShowMarks), int) m
      in <(String, String, bool Function(ShowMarks), int)>[
        ('roll-or-stack', 'push', (ShowMarks k) => k.speed.isNotEmpty && k.spotTurn.abs() > 1, 0),
        ('solids', 'turn', (ShowMarks k) => k.orbitSweep > 0.5 && k.orbitSweep < 0.9, 0),
        (
          'solid-and-face',
          'stamp',
          (ShowMarks k) => k.printAlpha > 0.99 && k.drawing.length >= 2 && k.tip != null,
          0,
        ),
        (
          'trace-the-shapes',
          'trace',
          (ShowMarks k) => k.lit.isNotEmpty && k.drawing.length >= 2 && k.tip != null,
          0,
        ),
      ]) {
    testWidgets('${m.$1}: the ${m.$2} Show on the phone', (WidgetTester t) async {
      await _lesson(t, content, m.$1, m.$1.replaceAll('-', ''), phone, seen: m.$3, settle: m.$4);
    });
  }

  // The new pictures of the pilot at the sizes a lesson uses: a bin's 28, a tile's 44 and a stage 64 points.
  testWidgets('the new shapes and solids at lesson size', (WidgetTester t) async {
    t.view.physicalSize = const Size(852, 393);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    const List<String> ids = <String>[
      'shape_oval_red',
      'shape_oval_blue',
      'shape_trapezoid_orange',
      'shape_trapezoid_green',
      'shape_triangle_half_blue',
      'shape_triangle_half_red',
      'can',
      'party_hat',
      'gift_box',
      'dice',
      'pyramid_egypt',
    ];
    final Map<String, String> svg = <String, String>{
      for (final String id in ids) id: File('../content/starter/$id.svg').readAsStringSync(),
    };
    await t.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFFDDF2E5),
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                for (final double size in <double>[64, 44, 28])
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        for (final String id in ids)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: SizedBox(
                              width: size,
                              height: size,
                              child: SvgPicture.string(svg[id]!, fit: BoxFit.contain),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 600)));
    await waitFor(t, 600);
    await _shot(t, 'stage2_new_sprites_sizes');
  });
}
