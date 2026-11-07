// Golden screenshots of the Band C screens of batch C1 (QA-C1-1, -2, -5, -6, -7): one activity of each kind on the phone, at the start and
// at each hint level (the lamp pressed once for each level, the picture taken when it has come to rest, level 3 on its last step), and
// the three modes that came with the batch (blocks, the hundred chart, the keypad) and the three-digit tiles on all four boards.
//
// Regenerate after a deliberate visual change:  flutter test --update-goldens test/golden_c1_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/child/activity_shell.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/play/hint_hand.dart';
import 'package:nitznutz/play/hints/hint_marks.dart';
import 'package:nitznutz/play/hints/tap_geometry.dart';
import 'package:nitznutz/play/hints/tap_plans.dart';

import 'support/c1_screens.dart';
import 'support/golden_comparator.dart';
import 'support/harness.dart';

/// One kind of screen: its name and an activity of it, the hint levels that are taken on the phone and the boards it is taken on.
class _Kind {
  const _Kind(this.name, this.id, {this.levels = const <int>[2], this.boards = const <String>['phone']});

  final String name;
  final String id;
  final List<int> levels;
  final List<String> boards;
}

const List<String> _all = <String>['phone', 'phoneSE', 'tabletL', 'tabletP'];

const List<_Kind> _kinds = <_Kind>[
  // the layouts that QA found broken
  _Kind('facts_two_frames', 'c.mathc01.1'),
  _Kind('three_digit_tiles', 'c.numc02.1', levels: <int>[], boards: _all),
  // the families of hints
  _Kind('facts_row', 'c.mathc01.4'),
  _Kind('facts_missing', 'c.mathc02.1'),
  _Kind('numeral_dots', 'c.numb06.1'),
  _Kind('counting_on', 'c.numc01.1'),
  _Kind('words_blocks', 'c.numc02.2'),
  _Kind('place_value_row', 'c.numc03.1'),
  _Kind('place_value_missing', 'c.numc03.5'),
  _Kind('coins', 'c.numc03.9'),
  _Kind('towers', 'c.numc04.1'),
  _Kind('towers_row', 'c.numc04.7'),
  _Kind('chart_row', 'c.numc09.1'),
  // the new modes
  _Kind('blocks_picture', 'c.numc03.18', levels: <int>[2, 3], boards: _all),
  _Kind('chart_picture', 'c.numc09.13', levels: <int>[2, 3], boards: _all),
  _Kind('chart_row_of_cells', 'c.numc01.13'),
  _Kind('keypad_row', 'c.numc03.21', levels: <int>[2, 3], boards: _all),
  _Kind('keypad_words', 'c.numc02.13', levels: <int>[3], boards: _all),
  _Kind('keypad_facts', 'c.mathc01.27', levels: <int>[]),
];

Future<void> _wait(WidgetTester t, int ms) async {
  for (int spent = 0; spent < ms; spent += 100) {
    await t.pump(const Duration(milliseconds: 100));
  }
  await t.pump(const Duration(milliseconds: 50));
}

void main() {
  late PackContent content;
  setUpAll(() async {
    await loadAppFonts();
    useTolerantGoldens(0.03);
    content = await loadSourcePack();
  });

  /// How long after the lamp the picture of [level] is taken: in the middle of the glow, when the new picture has come to rest, and on the
  /// last step of the demonstration.
  int waitFor(TapAnswerActivity a, ActivitySpec spec, int level) {
    final Size stage = spec.stageIsCard
        ? Size(spec.stage.width - 32, spec.stage.height - 32)
        : spec.stage.size;
    final HintPlan p = tapHintPlan(a, TapGeometry(a, stage, spec), level)!;
    final List<HintFrame> frames = p.frames;
    switch (level) {
      case 1:
        final int done = frames.length ~/ 2;
        return frames.take(done).fold(0, (int s, HintFrame f) => s + f.hold.inMilliseconds) +
            frames[done].hold.inMilliseconds ~/ 2;
      case 2:
        return p.length.inMilliseconds + 500;
      default:
        return p.length.inMilliseconds - frames.last.hold.inMilliseconds + 700;
    }
  }

  for (final (String board, Size size) in boards) {
    testWidgets('the Band C screens of batch C1 on the $board board', (WidgetTester t) async {
      await t.runAsync(warmHintHands);
      await startOn(t, content, size);
      final ActivitySpec spec = switch (board) {
        'phone' => ActivitySpec.phone,
        'phoneSE' => ActivitySpec.phoneSE,
        'tabletL' => ActivitySpec.tabletLandscape,
        _ => ActivitySpec.tabletPortrait,
      };
      for (final _Kind k in _kinds) {
        if (!k.boards.contains(board)) continue;
        final TapAnswerActivity a = content.activities[k.id]! as TapAnswerActivity;
        await openOne(t, content, a);
        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile('goldens/c1_${k.name}_start_$board.png'),
        );
        if (board == 'phone') {
          for (int level = 1; level <= (k.levels.isEmpty ? 0 : k.levels.last); level++) {
            await t.tap(find.byKey(const Key('lesson-hint')), warnIfMissed: false);
            await t.pump(const Duration(milliseconds: 60));
            final bool shoot = k.levels.contains(level);
            await _wait(t, shoot ? waitFor(a, spec, level) : 5000);
            if (shoot) {
              await expectLater(
                find.byType(MaterialApp),
                matchesGoldenFile('goldens/c1_${k.name}_l${level}_$board.png'),
              );
            }
          }
        }
        await closeOne(t);
      }
    }, timeout: const Timeout(Duration(minutes: 10)));
  }
}
