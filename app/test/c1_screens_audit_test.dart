// QA-C1-6: every Band C activity of the source-built pack opens on the four boards, and at the start, after a wrong answer and at hint
// 1, 2 and 3 it throws nothing (no overflow) and its speech bubble covers no answer tile. A screen that fails names the activity,
// the board and the state, so the next batch that adds a picture or a long hint finds its own defect here and not on the phone.
//
//   flutter test --no-pub test/c1_screens_audit_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/play/hint_hand.dart';

import 'support/c1_screens.dart';
import 'support/harness.dart';

/// The tile of a wrong option, or null when the activity has none to tap (a keypad item, an item with a single right answer).
Finder? _wrongTile(Activity a) {
  if (a is! TapAnswerActivity) return null;
  for (final ChoiceOption o in a.options) {
    if (a.correctIds.contains(o.id)) continue;
    return a.optionsInTiles ? find.byKey(Key('tile-${o.id}')) : find.byKey(Key('option-${o.id}'));
  }
  return null;
}

void main() {
  late PackContent content;
  late List<Activity> activities;

  setUpAll(() async {
    await loadAppFonts();
    content = await loadSourcePack();
    activities = bandCActivities(content);
  });

  test('the source-built pack has the Band C activities to audit', () {
    expect(activities.length, greaterThanOrEqualTo(168));
  });

  for (final (String name, Size size) in boards) {
    testWidgets(
      'every Band C activity on the $name board: no thrown error, no bubble over a tile, at the start, wrong, hint 1, 2 and 3',
      (WidgetTester t) async {
        await t.runAsync(warmHintHands);
        await startOn(t, content, size);
        final Map<String, List<String>> failures = <String, List<String>>{};
        await collectErrors((List<FlutterErrorDetails> sink) async {
          for (final Activity a in activities) {
            void check(String state) {
              final List<String> p = problemsOnScreen(t, sink);
              if (p.isNotEmpty) failures['${a.id} $state'] = p.toSet().take(3).toList();
            }

            await openOne(t, content, a);
            check('start');
            final Finder? wrong = _wrongTile(a);
            if (wrong != null && wrong.evaluate().isNotEmpty) {
              await t.tap(wrong.first, warnIfMissed: false);
              await waitSteps(t, 300);
              check('wrong');
            } else if (a is TapAnswerActivity && a.numberAnswer != null) {
              // A keypad item: type a number that is not the answer, and check it.
              for (final String k in <String>[...'${a.numberAnswer!.value + 1}'.split(''), 'done']) {
                await t.tap(find.byKey(Key('key-$k')), warnIfMissed: false);
                await t.pump(const Duration(milliseconds: 50));
              }
              await waitSteps(t, 300);
              check('wrong');
            }
            for (int level = 1; level <= 3; level++) {
              await t.tap(find.byKey(const Key('lesson-hint')), warnIfMissed: false);
              await waitSteps(t, level == 3 ? 4000 : 1500);
              check('hint $level');
            }
            await closeOne(t);
            sink.clear();
          }
        });
        expect(failures, isEmpty, reason: failures.entries.map((e) => '${e.key}: ${e.value}').join('\n'));
      },
      timeout: const Timeout(Duration(minutes: 15)),
    );
  }
}
