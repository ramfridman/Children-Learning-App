import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/activity_shell.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/design/components.dart';
import 'package:nitznutz/design/token_types.dart' show Band;
import 'package:nitznutz/play/activity_frame.dart';
import 'package:nitznutz/play/hint_hand.dart';
import 'package:nitznutz/play/hints/hint_marks.dart';
import 'package:nitznutz/play/hints/hint_pictures.dart';
import 'package:nitznutz/play/hints/tap_geometry.dart';
import 'package:nitznutz/play/hints/tap_plans.dart';
import 'package:nitznutz/play/lesson_controller.dart';
import 'package:nitznutz/play/lesson_screen.dart';
import 'package:nitznutz/play/tap_answer_session.dart';

import 'support/app_harness.dart';
import 'support/fakes.dart';
import 'support/harness.dart';
import 'support/starter.dart';

/// B-40 fix (the owner's phone test): the pointing hand is drawn above everything it points at, the answer tiles included. It comes
/// in from the side to the last tile of the row (under the speech bubble), from above, and from below in the shop and sort and
/// drag; it takes no touch, so a tap on the tile under it still answers.

/// The render objects from the root down to [o].
List<RenderObject> _chain(RenderObject o) {
  final List<RenderObject> up = <RenderObject>[];
  for (RenderObject? p = o; p != null; p = p.parent) {
    up.add(p);
  }
  return up.reversed.toList();
}

/// True when [a] is painted after [b]: under their nearest common parent, [a]'s branch is later in the child list (a stack paints its
/// children in that order).
bool paintsAfter(RenderObject a, RenderObject b) {
  final List<RenderObject> pa = _chain(a);
  final List<RenderObject> pb = _chain(b);
  int i = 0;
  while (i < pa.length && i < pb.length && identical(pa[i], pb[i])) {
    i++;
  }
  if (i == 0 || i >= pa.length || i >= pb.length) return false; // one holds the other, or nothing in common
  int n = 0;
  int? ia;
  int? ib;
  pa[i - 1].visitChildren((RenderObject c) {
    if (identical(c, pa[i])) ia = n;
    if (identical(c, pb[i])) ib = n;
    n++;
  });
  return ia != null && ib != null && ia! > ib!;
}

void main() {
  late PackContent content;
  setUpAll(() async {
    await loadAppFonts();
    content = await loadStarter();
  });

  const ActivitySpec spec = ActivitySpec.phone;
  final Size stage = spec.stage.size;

  /// A tap_answer with answer tiles whose right answer is the last tile of the row, the one under the speech bubble on the phone.
  TapAnswerActivity lastTileActivity() =>
      content.activities.values.whereType<TapAnswerActivity>().firstWhere((TapAnswerActivity a) {
        if (!a.optionsInTiles || a.options.any((ChoiceOption o) => o.set != null) || a.options.length < 3) {
          return false;
        }
        final TapGeometry g = TapGeometry(a, stage, spec, dir: TextDirection.rtl);
        final double rowEnd = <double>[for (int i = 0; i < a.options.length; i++) g.optionTip(i).dx]
            .reduce((double p, double q) => p > q ? p : q);
        return g.optionTip(g.correctIndex).dx == rowEnd && rowEnd + 48 > handClearOf(spec)!;
      });

  LessonController controllerFor(Activity a) => LessonController(
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

  group('in the frame', () {
    testWidgets(
      'the side hand to the last tile (under the bubble) is painted after the tile, the bubble and the stage; a tap on the tile under it answers',
      (WidgetTester t) async {
        await t.runAsync(warmHintHands);
        final TapAnswerActivity a = lastTileActivity();
        final TapGeometry g = TapGeometry(a, stage, spec, dir: TextDirection.rtl);
        final TapAnswerSession s = TapAnswerSession(controllerFor(a), a);
        final String right = a.options[g.correctIndex].id;
        const double tileHalf = 48;
        final double rowEnd =
            <double>[for (int i = 0; i < a.options.length; i++) g.optionTip(i).dx]
                .reduce((double p, double q) => p > q ? p : q) +
            tileHalf;
        await pumpScreen(
          t,
          Builder(
            builder: (BuildContext c) => ActivityFrame(
              bubbleText: 'x',
              stage: (Size room) => s.buildStage(c, room, spec),
              tiles: s.buildTiles(c, spec),
              hands: (Size room) => HintOverlay(
                size: room,
                clearOf: handClearOf(spec),
                tileHalf: tileHalf,
                rowEnd: rowEnd,
                layer: HintLayer.hands,
                marks: <HintMark>[HandMark(g.optionTip(g.correctIndex), press: true, snap: true)],
              ),
              trailTotal: 3,
              trailDone: 1,
              onHome: () {},
            ),
          ),
          band: Band.a,
        );
        await t.pump(const Duration(milliseconds: 600));
        final Finder hand = find.byKey(const Key('hint-p12'));
        expect(hand, findsOneWidget);
        expect(
          t
              .widgetList<Transform>(find.descendant(of: hand, matching: find.byType(Transform)))
              .any((Transform w) => (w.transform.storage[0] - 0.3624).abs() < 0.01),
          isTrue,
          reason: 'the hand is the one that comes in from the side, turned (1.2 radians) to point left',
        );
        final RenderObject handBox = t.renderObject(hand);
        for (final Finder behind in <Finder>[
          find.byType(AnswerTile),
          find.byKey(const Key('lesson-bubble')),
          find.byKey(const Key('activity-nitzi')),
          find.byKey(const Key('lesson-stage')),
        ]) {
          expect(behind, findsWidgets);
          for (final Element e in behind.evaluate()) {
            expect(paintsAfter(handBox, e.renderObject!), isTrue, reason: '$behind is painted over the hand');
          }
        }
        // The hand's fingertip lies inside the right tile (14 in from its right edge, 34 under its top): a tap there reaches the tile.
        final Rect tile = t.getRect(find.byKey(Key('tile-$right')));
        await t.tapAt(Offset(tile.right - 14, tile.top + 34));
        await t.pump();
        expect(s.chosenId, right, reason: 'the hand takes no touch');
        s.dispose();
        await t.pumpWidget(const SizedBox());
      },
    );

    testWidgets('every hand layer is after the tiles in the frame (any template, any board)', (
      WidgetTester t,
    ) async {
      for (final Band band in <Band>[Band.a, Band.b]) {
        await pumpScreen(
          t,
          ActivityFrame(
            bubbleText: 'x',
            stage: (Size room) =>
                SizedBox(key: const Key('probe-stage'), width: room.width, height: room.height),
            hands: (Size room) => const SizedBox(key: Key('probe-hands')),
            tiles: const SizedBox(key: Key('probe-tiles')),
            trailTotal: 3,
            trailDone: 1,
            onHome: () {},
          ),
          band: band,
        );
        final RenderObject hands = t.renderObject(find.byKey(const Key('probe-hands')));
        for (final String behind in <String>[
          'probe-tiles',
          'probe-stage',
          'lesson-bubble',
          'activity-nitzi',
        ]) {
          expect(
            paintsAfter(hands, t.renderObject(find.byKey(Key(behind)))),
            isTrue,
            reason: '$behind is painted over the hand',
          );
        }
      }
    });
  });

  group('on the lesson screen, level 3', () {
    Future<void> wait(WidgetTester t, int ms) async {
      for (int spent = 0; spent < ms; spent += 100) {
        await t.pump(const Duration(milliseconds: 100));
      }
      await t.pump(const Duration(milliseconds: 50));
    }

    /// Plays [activity] to level 3 on the phone and returns when the hand stands at its last place after [level3Ms].
    Future<void> toLevel3(WidgetTester t, String activity, int level3Ms) async {
      final NavigatorState nav = t.state<NavigatorState>(find.byType(Navigator).first);
      nav.push(
        MaterialPageRoute<void>(
          builder: (BuildContext c) => LessonScreen(
            profileId: 'p-1',
            mission: Lesson.mission(
              id: 'shot',
              itemIds: <String>[activity],
              skillIds: content.activities[activity]!.skills.map((Skill s) => s.id).toList(),
              celebration: content.lessons['butterflies']!.celebration,
            ),
          ),
        ),
      );
      await t.pump(const Duration(milliseconds: 600));
      await wait(t, 2500);
      for (int level = 1; level <= 3; level++) {
        await t.tap(find.byKey(const Key('lesson-hint')), warnIfMissed: false);
        await t.pump(const Duration(milliseconds: 60));
        await wait(t, level < 3 ? 6000 : level3Ms);
      }
    }

    void expectAfter(WidgetTester t, Finder behind, {required String what}) {
      final RenderObject hand = t.renderObject(find.byKey(const Key('hint-p12')));
      expect(behind, findsWidgets, reason: what);
      for (final Element e in behind.evaluate()) {
        expect(paintsAfter(hand, e.renderObject!), isTrue, reason: '$what is painted over the hand');
      }
    }

    testWidgets('the side hand (tap), and the hand from below (shop, sort), are painted after the tiles', (
      WidgetTester t,
    ) async {
      await t.runAsync(warmHintHands);
      final AppRig rig = AppRig();
      await rig.seedFinishedSetup(name: 'נֹעָה');
      await rig.pump(t, size: const Size(852, 393));
      await t.tap(find.text('נֹעָה'));
      await t.pumpAndSettle();

      final TapAnswerActivity a = lastTileActivity();
      final TapGeometry g = TapGeometry(a, stage, spec, dir: TextDirection.rtl);
      final HintPlan plan = tapHintPlan(a, g, 3)!;
      await toLevel3(t, a.id, plan.length.inMilliseconds - plan.frames.last.hold.inMilliseconds + 700);
      expectAfter(t, find.byType(AnswerTile), what: 'a tile of ${a.id}');
      expectAfter(t, find.byKey(const Key('lesson-bubble')), what: 'the bubble');
      t.state<NavigatorState>(find.byType(Navigator).first).pop();
      await t.pump(const Duration(milliseconds: 600));

      await toLevel3(t, 'x.mathb17.6', 900 * 3 + 700);
      expectAfter(t, find.byKey(const Key('purse')), what: 'the purse');
      expectAfter(t, find.byKey(const Key('pay')), what: 'the pay button');
      t.state<NavigatorState>(find.byType(Navigator).first).pop();
      await t.pump(const Duration(milliseconds: 600));

      await toLevel3(t, 'log.sortdrag.colour', 2000);
      expectAfter(t, find.byKey(const Key('sort-tray')), what: 'the tray');
      t.state<NavigatorState>(find.byType(Navigator).first).pop();
      await t.pump(const Duration(milliseconds: 600));
    });
  });
}
