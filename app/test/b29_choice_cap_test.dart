// B-29 step 6.4: the choice cap. The right option (or options) stay first, then the tagged distractors, then the rest, in authored order;
// the ones kept keep their authored order; `optionCount` after the cap is what the two-choice retry rule reads. Run over every item of the
// bundled pack for each stage, so a cap never breaks an item, and the list of items over each cap is counted for the curriculum-expert.
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/engine/presentation.dart' show maxChoicesByStage;
import 'package:nitznutz/play/choice_cap.dart';

import 'support/starter.dart';

typedef _Opt = ({String id, bool correct, bool tagged});

_Opt _o(String id, {bool correct = false, bool tagged = false}) => (id: id, correct: correct, tagged: tagged);

void main() {
  group('which options stay', () {
    test('nothing is cut when the options fit', () {
      expect(keptOptionIds(<_Opt>[_o('a'), _o('b', correct: true), _o('c')], 3), <String>['a', 'b', 'c']);
      expect(keptOptionIds(<_Opt>[_o('a'), _o('b', correct: true)], 5), <String>['a', 'b']);
    });

    test('the right option is always kept, wherever it stands', () {
      for (int at = 0; at < 5; at++) {
        final List<_Opt> five = <_Opt>[for (int i = 0; i < 5; i++) _o('o$i', correct: i == at)];
        final List<String> kept = keptOptionIds(five, 3);
        expect(kept, contains('o$at'), reason: 'at $at');
        expect(kept.length, 3);
      }
    });

    test('then the tagged distractors, in authored order, then the others', () {
      final List<_Opt> six = <_Opt>[
        _o('a'),
        _o('b', tagged: true),
        _o('c', correct: true),
        _o('d'),
        _o('e', tagged: true),
        _o('f', tagged: true),
      ];
      expect(keptOptionIds(six, 3), <String>[
        'b',
        'c',
        'e',
      ], reason: 'the right one, then the first two tagged');
      expect(keptOptionIds(six, 4), <String>['b', 'c', 'e', 'f']);
      expect(keptOptionIds(six, 5), <String>[
        'a',
        'b',
        'c',
        'e',
        'f',
      ], reason: 'an untagged one only when room is left');
    });

    test('the kept ones stay in their authored order (a number row stays ascending)', () {
      final List<_Opt> row = <_Opt>[
        _o('1', tagged: true),
        _o('2'),
        _o('3', correct: true),
        _o('4', tagged: true),
        _o('5'),
      ];
      expect(keptOptionIds(row, 3), <String>['1', '3', '4']);
    });

    test('every right option stays even when they alone are more than the cap (a tap-all)', () {
      final List<_Opt> all = <_Opt>[
        _o('a', correct: true),
        _o('b', correct: true),
        _o('c', correct: true),
        _o('d', correct: true),
        _o('e'),
      ];
      expect(keptOptionIds(all, 3), <String>['a', 'b', 'c', 'd']);
    });
  });

  group('over every item of the bundled pack', () {
    late PackContent pack;
    setUpAll(() async => pack = await loadStarter());

    Iterable<Activity> choices() => <Activity>[
      for (final Activity a in pack.activities.values)
        if (a is ChoiceActivity) a,
    ];

    test('the pack has choice items to try the cap on', () {
      expect(choices().length, greaterThan(200));
    });

    test(
      'with a cap the item keeps its right answer, its stage and its words; the options are at most the cap',
      () {
        for (final int cap in maxChoicesByStage.toSet()) {
          for (final Activity a in choices()) {
            final Activity c = capChoices(a, cap);
            final ChoiceActivity before = a as ChoiceActivity;
            final ChoiceActivity after = c as ChoiceActivity;
            final int right = a is TapAnswerActivity ? a.correctIds.length : 1;
            expect(
              after.options.length,
              lessThanOrEqualTo(
                before.options.length > cap ? (cap > right ? cap : right) : before.options.length,
              ),
              reason: '${a.id} at $cap',
            );
            expect(
              after.options.map((ChoiceOption o) => o.id),
              contains(before.correctId.isEmpty ? anything : before.correctId),
            );
            expect(c.id, a.id);
            expect(c.template, a.template);
            expect(c.json['prompt'], a.json['prompt']);
            // The order of what stays is the authored order.
            final List<String> ids = before.options.map((ChoiceOption o) => o.id).toList();
            final List<int> at = after.options.map((ChoiceOption o) => ids.indexOf(o.id)).toList();
            expect(at, orderedEquals(<int>[...at]..sort()), reason: '${a.id} at $cap');
          }
        }
      },
    );

    test('a distractor that a hint or a rule of the item names stays: nothing the item points at is cut', () {
      for (final int cap in <int>[3, 4]) {
        for (final Activity a in choices()) {
          if ((a as ChoiceActivity).options.length <= cap) continue;
          final Activity c = capChoices(a, cap);
          final Set<String> gone = <String>{for (final ChoiceOption o in (a as ChoiceActivity).options) o.id}
            ..removeAll((c as ChoiceActivity).options.map((ChoiceOption o) => o.id));
          final Map<String, Object?> rest = <String, Object?>{...a.json}..remove('answer');
          for (final String id in gone) {
            expect(
              _mentions(rest, id),
              isFalse,
              reason: '${a.id}: option $id is cut but named outside the answer',
            );
          }
        }
      }
    });

    test('optionCount after the cap is the number of options shown', () {
      for (final Activity a in choices()) {
        final Activity c = capChoices(a, 3);
        expect(c.optionCount, (c as ChoiceActivity).options.length, reason: a.id);
      }
    });

    test('the items over each cap are counted, for the curriculum-expert (P1 and P2: 3, P3: 4, P4: 5)', () {
      final Map<int, int> over = <int, int>{
        for (final int cap in <int>[3, 4, 5])
          cap: choices().where((Activity a) => (a as ChoiceActivity).options.length > cap).length,
      };
      // The authored content is written per stage already, so the cap is a safety net: it should reach few items and none at five.
      expect(over[5], 0, reason: 'no authored item has more than five options');
      expect(over[3]!, greaterThanOrEqualTo(over[4]!));
      // ignore: avoid_print
      print('items over the cap: $over of ${choices().length}');
    });

    test('capping twice, or with a larger cap, changes nothing more', () {
      for (final Activity a in choices()) {
        final Activity once = capChoices(a, 3);
        expect(identical(capChoices(once, 3), once), isTrue, reason: a.id);
        expect(identical(capChoices(a, 9), a), isTrue, reason: a.id);
      }
    });
  });
}

/// Whether [id] stands as a string value anywhere in [node].
bool _mentions(Object? node, String id) {
  if (node is String) return node == id;
  if (node is List) return node.any((Object? n) => _mentions(n, id));
  if (node is Map) return node.values.any((Object? n) => _mentions(n, id));
  return false;
}
