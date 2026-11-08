// A session of one activity of a fixture language pack, on the frame of the lesson screen, with the attempts it writes and the clips it
// asks for: the rig of the tests of the Band A templates (LS08, LS11, LS12, LS10, LS03). Not the lesson screen: no database, no voice.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/activity_shell.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/design/board.dart' show boardClassFor;
import 'package:nitznutz/design/token_types.dart' show Band;
import 'package:nitznutz/play/activity_frame.dart';
import 'package:nitznutz/play/lesson_controller.dart';
import 'package:nitznutz/play/template_session.dart';

import 'fakes.dart';
import 'harness.dart';
import 'language_content.dart';

const Map<String, Size> boards = <String, Size>{
  'phone': Size(852, 393),
  'phoneSE': Size(667, 375),
  'tabletLandscape': Size(1180, 820),
  'tabletPortrait': Size(820, 1180),
};

/// What the session asked to be played: `now vo:a vo:b` for clips that cut in, `after vo:a` for clips that wait their turn.
class Heard {
  final List<String> calls = <String>[];

  FutureOr<void> call(List<String> ids, {bool replace = false}) {
    calls.add('${replace ? 'now' : 'after'} ${ids.join(' ')}');
  }

  /// Every clip asked for so far, in order.
  List<String> get clips => <String>[for (final String c in calls) ...c.split(' ').skip(1)];

  void clear() => calls.clear();
}

class Rig<S extends TemplateSession> {
  Rig(
    LangPack p,
    String id,
    S Function(LessonController c, Activity a) make, {
    List<String>? itemIds,
    ItemFlow? flow,
  }) : this.ofContent(p.content, '${p.course}.$id', make, itemIds: itemIds, flow: flow);

  /// The rig of an activity of a pack that is already read (a real course pack), by its full id.
  Rig.ofContent(
    PackContent content,
    String activityId,
    S Function(LessonController c, Activity a) make, {
    List<String>? itemIds,
    ItemFlow? flow,
  }) {
    activity = content.activities[activityId]!;
    controller = LessonController(
      content: content,
      lesson: Lesson.mission(
        id: 'one',
        itemIds: itemIds ?? <String>[activity.id],
        skillIds: <String>[activity.skillId],
        celebration: const Spoken(vo: 'vo:x.celebrate', caption: 'x'),
      ),
      profileId: 'p-1',
      clock: FixedClock(1793000000000),
      flow: flow,
      record: (AttemptRecord r) async => attempts.add(r),
    );
    session = make(controller, activity)..playClips = heard.call;
  }

  late final Activity activity;
  late final LessonController controller;
  late S session;
  final Heard heard = Heard();
  final List<AttemptRecord> attempts = <AttemptRecord>[];

  Future<void> pump(WidgetTester t, {Size size = const Size(852, 393), Band band = Band.a}) async {
    t.view.devicePixelRatio = 1;
    addTearDown(() {
      if (!session.disposed) session.dispose();
    });
    await pumpScreen(
      t,
      ListenableBuilder(
        listenable: controller,
        builder: (BuildContext c, Widget? _) => Builder(
          builder: (BuildContext c) {
            final ActivitySpec spec = session.layoutFor(ActivitySpec.of(boardClassFor(size)));
            return ActivityFrame(
              spec: spec,
              bubbleAboveTiles: true,
              bubbleText: controller.bubble,
              stage: (Size room) => session.buildStage(c, room, spec),
              hands: (Size room) => session.buildHands(c, room, spec) ?? const SizedBox(),
              tiles: session.buildTiles(c, spec),
              boardLayer: session.buildBoardLayer(c, spec),
              trailTotal: controller.trailLength,
              trailDone: controller.index,
              onHome: () {},
              onHint: controller.noHelp ? null : controller.showHint,
              onShowMe: controller.noHelp ? null : () => controller.unsure(),
              onReplay: controller.replayPrompt,
            );
          },
        ),
      ),
      size: size,
      band: band,
    );
  }

  /// Takes the screen down and lets the session go, with the timers of its last move.
  Future<void> done(WidgetTester t) async {
    await t.pumpWidget(const SizedBox());
    session.dispose();
  }

  /// Time passes in steps of 100 ms (a session with a companion cannot settle).
  Future<void> wait(WidgetTester t, int ms) async {
    for (int spent = 0; spent < ms; spent += 100) {
      await t.pump(const Duration(milliseconds: 100));
    }
  }

  Finder tile(String id) => find.byKey(Key('tile-$id'));

  /// The results written so far, as `result:response` (a result and the code of the answer).
  List<String> get written => <String>[for (final AttemptRecord a in attempts) '${a.result}:${a.response}'];
}
