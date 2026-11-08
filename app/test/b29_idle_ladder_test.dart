// B-29 D5: the idle ladder. Its steps come at the stage's own stillness counted from the last touch; a touch starts it over; a line that plays
// holds it; the hand points into the stage and never at a tile; nothing is a countdown.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/design/layout.dart';
import 'package:nitznutz/design/stage_spec.dart';
import 'package:nitznutz/engine/age.dart' show PresentationStage;
import 'package:nitznutz/play/idle_ladder.dart';

void main() {
  const Map<PresentationStage, List<int>> seconds = <PresentationStage, List<int>>{
    PresentationStage.p1: <int>[8, 15, 30, 120],
    PresentationStage.p2: <int>[8, 15, 30, 120],
    PresentationStage.p3: <int>[12, 25, 45, 120],
    PresentationStage.p4: <int>[20, 40, 60, 120],
  };

  group('the steps come at each stage\'s stillness', () {
    for (final MapEntry<PresentationStage, List<int>> e in seconds.entries) {
      testWidgets('${e.key.name}: ${e.value} seconds from the last touch', (WidgetTester tester) async {
        final List<IdleStep> got = <IdleStep>[];
        final IdleLadder ladder = IdleLadder(stage: StageSpec.of(e.key), onStep: got.add)..start();
        for (int i = 0; i < 4; i++) {
          await tester.pump(
            Duration(seconds: e.value[i]) -
                (i == 0 ? Duration.zero : Duration(seconds: e.value[i - 1])) -
                const Duration(milliseconds: 1),
          );
          expect(got.length, i, reason: 'just before step $i');
          await tester.pump(const Duration(milliseconds: 1));
          expect(got.length, i + 1, reason: 'at step $i');
        }
        expect(got, IdleStep.values);
        await tester.pump(const Duration(hours: 1));
        expect(got.length, 4, reason: 'nothing after the soft pause');
        ladder.stop();
      });
    }
  });

  testWidgets('a touch starts the count over, from any step', (WidgetTester tester) async {
    final List<IdleStep> got = <IdleStep>[];
    int resets = 0;
    final IdleLadder ladder = IdleLadder(
      stage: StageSpec.of(PresentationStage.p2),
      onStep: got.add,
      onReset: () => resets++,
    )..start();
    await tester.pump(const Duration(seconds: 7));
    ladder.touch();
    expect(resets, 0, reason: 'nothing had been reached');
    await tester.pump(const Duration(seconds: 7));
    expect(got, isEmpty, reason: 'eight seconds from the touch, not from the start');
    await tester.pump(const Duration(seconds: 1));
    expect(got, <IdleStep>[IdleStep.firstPrompt]);
    ladder.touch();
    expect(resets, 1);
    await tester.pump(const Duration(seconds: 8));
    expect(got.length, 2);
    expect(got.last, IdleStep.firstPrompt, reason: 'the ladder began again at its first step');
    ladder.stop();
  });

  testWidgets('a line that plays holds the count, and when it ends the stillness starts again', (
    WidgetTester tester,
  ) async {
    final List<IdleStep> got = <IdleStep>[];
    final IdleLadder ladder = IdleLadder(stage: StageSpec.of(PresentationStage.p1), onStep: got.add)..start();
    await tester.pump(const Duration(seconds: 6));
    ladder.hold();
    await tester.pump(const Duration(minutes: 5));
    expect(got, isEmpty, reason: 'a prompt never talks over a line');
    ladder.release();
    await tester.pump(const Duration(seconds: 7));
    expect(got, isEmpty);
    await tester.pump(const Duration(seconds: 1));
    expect(got, <IdleStep>[IdleStep.firstPrompt]);
    ladder.stop();
  });

  testWidgets('a stopped ladder never speaks again', (WidgetTester tester) async {
    final List<IdleStep> got = <IdleStep>[];
    final IdleLadder ladder = IdleLadder(stage: StageSpec.of(PresentationStage.p1), onStep: got.add)..start();
    ladder.stop();
    ladder.touch();
    ladder.release();
    await tester.pump(const Duration(minutes: 10));
    expect(got, isEmpty);
  });

  group('the hand', () {
    test(
      'P1 to P3 show it from the first prompt; P4 only from the second; the offer and the pause have none',
      () {
        for (final PresentationStage s in <PresentationStage>[
          PresentationStage.p1,
          PresentationStage.p2,
          PresentationStage.p3,
        ]) {
          expect(idleHandShows(StageSpec.of(s), IdleStep.firstPrompt), isTrue, reason: s.name);
        }
        expect(idleHandShows(StageSpec.of(PresentationStage.p4), IdleStep.firstPrompt), isFalse);
        expect(idleHandShows(StageSpec.of(PresentationStage.p4), IdleStep.secondPrompt), isTrue);
        for (final PresentationStage s in PresentationStage.values) {
          expect(idleHandShows(StageSpec.of(s), IdleStep.offer), isFalse);
          expect(idleHandShows(StageSpec.of(s), IdleStep.softPause), isFalse);
        }
      },
    );

    test('the fingertip is in the middle of the stage, so inside it, whatever the board', () {
      for (final Size room in const <Size>[Size(330, 128), Size(270, 104), Size(552, 268), Size(740, 268)]) {
        final Offset tip = idleTarget(room);
        expect(Rect.fromLTWH(0, 0, room.width, room.height).contains(tip), isTrue, reason: '$room');
        expect(tip, Offset(room.width / 2, room.height / 2));
      }
    });
  });

  test('the ladder holds no time to show: its steps are an enum, not seconds', () {
    expect(IdleStep.values.map((IdleStep s) => s.name), <String>[
      'firstPrompt',
      'secondPrompt',
      'offer',
      'softPause',
    ]);
    expect(SizeClass.values.length, 3);
  });
}
