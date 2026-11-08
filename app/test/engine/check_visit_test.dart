// The check visit of a language course (docs/languages/band-a-build.md section 7.4): when a skill is ready for one (C-1), what it holds
// (C-3), what follows a failed check (C-4) and the credit of a balanced pair (C-5). Pure functions over a small fixture course.
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/engine/check_visit.dart';
import 'package:nitznutz/engine/course.dart';
import 'package:nitznutz/engine/engine.dart';
import 'package:nitznutz/engine/state.dart';
import 'package:nitznutz/engine/types.dart';

const String skill = 'ENG-A-01';
final DateTime _day0 = DateTime.utc(2026, 11, 2, 9);
final int _today0 = Engine.dayKey(_day0);

ItemMeta _item(
  String id, {
  Purpose purpose = Purpose.learn,
  CheckType check = CheckType.practice,
  Representation rep = Representation.pictorial,
  String? group,
  double difficulty = 0.3,
  String? pairWith,
  String skillId = skill,
}) => ItemMeta(
  id: id,
  course: Course.eng,
  skills: <String, double>{skillId: 1},
  purpose: purpose,
  checkType: check,
  representation: rep,
  variantGroup: group ?? id,
  difficulty: difficulty,
  optionCount: 3,
  pairWith: pairWith,
);

/// One skill: three learn items (words g1 to g3, in two ways of showing), a transfer check, a reverse check and a balanced pair of
/// checks (a yes and a no).
Catalog _catalog({bool core = false, bool setCoverage = false, List<ItemMeta> more = const <ItemMeta>[]}) =>
    Catalog(
      skills: <SkillNode>[SkillNode(id: skill, course: Course.eng, core: core, setCoverage: setCoverage)],
      items: <ItemMeta>[
        _item('l1', group: 'g1', difficulty: 0.1),
        _item('l2', group: 'g2', difficulty: 0.2),
        _item('l3', group: 'g3', difficulty: 0.3, rep: Representation.story),
        _item('c-transfer', purpose: Purpose.check, check: CheckType.transfer, group: 'g1', difficulty: 0.5),
        _item('c-reverse', purpose: Purpose.check, check: CheckType.reverse, group: 'g2', difficulty: 0.6),
        _item(
          'yes',
          purpose: Purpose.check,
          check: CheckType.predict,
          group: 'gp',
          difficulty: 0.8,
          pairWith: 'no',
        ),
        _item(
          'no',
          purpose: Purpose.check,
          check: CheckType.predict,
          group: 'gp',
          difficulty: 0.8,
          pairWith: 'yes',
        ),
        ...more,
      ],
    );

class _Child {
  _Child(this.engine);

  final Engine engine;
  int _n = 0;
  int day = 0;
  int? session;

  /// The skill's state, after a first answer has made it.
  SkillState get s => engine.state.skills[skill]!;

  void answer(String item, {Result result = Result.correct, int hint = 0}) => engine.apply(
    AttemptEvent(
      id: ++_n,
      at: _day0.add(Duration(days: day, minutes: _n)),
      activityId: item,
      result: result,
      hintLevel: hint,
      sessionId: session,
    ),
  );

  void right(List<String> items) => items.forEach(answer);

  void nextDay() {
    day++;
    session = session == null ? null : session! + 1;
  }

  int get today => Engine.dayKey(_day0.add(Duration(days: day)));

  List<String> plan({int max = 5, Set<String> inLesson = const <String>{}}) =>
      checkVisitItemIds(engine, skill, inLessonChecks: inLesson, max: max);
}

_Child _child({Catalog? catalog, int? session = 1}) =>
    _Child(Engine(catalog: catalog ?? _catalog()))..session = session;

void main() {
  group('C-5: a balanced pair counts as one check only when both halves are right', () {
    test('one half right alone is an ordinary success, not a check', () {
      final _Child c = _child()..answer('yes');
      expect(c.s.successes, 1);
      expect(c.s.checksPassed, isEmpty);
    });

    test('both halves right without a hint, in one visit: the check type is credited, whichever half comes first', () {
      for (final List<String> order in <List<String>>[
        <String>['yes', 'no'],
        <String>['no', 'yes'],
      ]) {
        final _Child c = _child()..right(order);
        expect(c.s.checksPassed, <CheckType>{CheckType.predict}, reason: '$order');
        expect(c.s.successes, 2);
      }
    });

    test('a half that was wrong, hinted or answered in another visit does not complete the pair', () {
      final _Child wrong = _child()
        ..answer('yes')
        ..answer('no', result: Result.incorrect);
      expect(wrong.s.checksPassed, isEmpty);
      final _Child hinted = _child()
        ..answer('yes')
        ..answer('no', hint: 1);
      expect(hinted.s.checksPassed, isEmpty);
      final _Child later = _child()..answer('yes');
      later.nextDay();
      later.answer('no');
      expect(later.s.checksPassed, isEmpty, reason: 'the other half was in another visit');
      later.answer('yes');
      expect(later.s.checksPassed, <CheckType>{
        CheckType.predict,
      }, reason: 'and now both are right in this one');
    });

    test('an item with no partner credits its type as before', () {
      final _Child c = _child()..answer('c-reverse');
      expect(c.s.checksPassed, <CheckType>{CheckType.reverse});
    });

    test('with no session the answers of a day are one visit', () {
      final _Child c = _child(session: null)..right(<String>['yes', 'no']);
      expect(c.s.checksPassed, <CheckType>{CheckType.predict});
    });
  });

  group('C-1: when a skill is ready', () {
    bool ready(_Child c, {bool taught = true}) =>
        checkVisitReady(c.engine, skill, taught: taught, today: c.today);

    test('started, not fresh, taught and not answered today', () {
      final _Child c = _child()..right(<String>['l1', 'l2']);
      expect(ready(c), isFalse, reason: 'it was answered today: a check would be an echo of the lesson');
      c.nextDay();
      expect(ready(c), isTrue);
      expect(ready(c, taught: false), isFalse, reason: 'a lesson of it is not finished yet');
    });

    test('a skill never answered is not ready, unless placement took it as known', () {
      final _Child c = _child();
      expect(ready(c), isFalse);
      c.engine.assume(<String>[skill]);
      expect(ready(c), isTrue);
      expect(c.engine.isAssumed(skill), isTrue);
      c.answer('l1');
      expect(
        c.engine.isAssumed(skill),
        isFalse,
        reason: 'verified by an answer: it is an ordinary started skill now',
      );
    });

    test('a fresh skill is a revisit\'s, not a check visit\'s', () {
      final _Child c = _child(catalog: _catalog(more: <ItemMeta>[]));
      for (int d = 0; d < 3; d++) {
        c.right(<String>['l1', 'l2', 'l3', 'c-transfer', 'l1', 'l2']);
        c.nextDay();
      }
      expect(c.s.freshAt, isNotNull);
      expect(ready(c), isFalse);
    });

    test('a trace node is practised, never mastered: no check visit', () {
      final Catalog catalog = Catalog(
        skills: <SkillNode>[const SkillNode(id: skill, course: Course.heb, writing: WritingRule.practised)],
        items: <ItemMeta>[_item('t1', purpose: Purpose.practice)],
      );
      final Engine e = Engine(catalog: catalog)..assume(<String>[skill]);
      expect(checkVisitReady(e, skill, taught: true, today: _today0), isFalse);
    });

    test('a skill that is not in the catalogue, or has no item to ask, is not ready and plans nothing', () {
      final _Child c = _child();
      expect(checkVisitReady(c.engine, 'ENG-A-99', taught: true, today: _today0), isFalse);
      expect(checkVisitItemIds(c.engine, 'ENG-A-99'), isEmpty);
    });
  });

  group('C-3: what the visit holds', () {
    test('a warm-up the child already got right, then the check the skill lacks, in 3 to 5 items', () {
      final _Child c = _child()..right(<String>['l2', 'l3']);
      c.nextDay();
      final List<String> plan = c.plan();
      expect(plan.first, 'l2', reason: 'the easiest learn item answered right is the warm-up');
      expect(plan, contains('c-transfer'));
      expect(plan.length, inInclusiveRange(3, 5));
      expect(plan.toSet().length, plan.length, reason: 'no item twice');
      expect(
        plan.where((String id) => id.startsWith('c-') || id == 'yes' || id == 'no').length,
        1,
        reason: 'a skill that is not core lacks one type of check',
      );
    });

    test('a core skill lacks two types of check and gets one of each', () {
      final _Child c = _child(catalog: _catalog(core: true))..right(<String>['l1', 'l2']);
      c.nextDay();
      final List<String> plan = c.plan();
      final Set<CheckType> types = <CheckType>{
        for (final String id in plan)
          if (c.engine.catalog.items[id]!.purpose == Purpose.check) c.engine.catalog.items[id]!.checkType,
      };
      expect(types, hasLength(2));
    });

    test('a type the skill has passed is not asked again as a missing type', () {
      final _Child c = _child(catalog: _catalog(core: true))..right(<String>['l1', 'c-transfer']);
      c.nextDay();
      final List<String> plan = c.plan();
      expect(plan, contains('c-reverse'));
      expect(plan, isNot(contains('c-transfer')));
    });

    test('a balanced pair is one check, served as its two items one after the other', () {
      final Catalog catalog = Catalog(
        skills: const <SkillNode>[SkillNode(id: skill, course: Course.eng)],
        items: <ItemMeta>[
          _item('l1'),
          _item('yes', purpose: Purpose.check, check: CheckType.transfer, pairWith: 'no'),
          _item('no', purpose: Purpose.check, check: CheckType.transfer, pairWith: 'yes'),
        ],
      );
      final _Child c = _child(catalog: catalog)..answer('l1');
      c.nextDay();
      final List<String> plan = c.plan();
      expect((plan.indexOf('no') - plan.indexOf('yes')).abs(), 1);
    });

    test('a pair that does not fit in the visit is left out whole, never half', () {
      final Catalog catalog = Catalog(
        skills: const <SkillNode>[SkillNode(id: skill, course: Course.eng)],
        items: <ItemMeta>[
          _item('l1'),
          _item('yes', purpose: Purpose.check, check: CheckType.transfer, pairWith: 'no'),
          _item('no', purpose: Purpose.check, check: CheckType.transfer, pairWith: 'yes'),
        ],
      );
      final _Child c = _child(catalog: catalog)..answer('l1');
      c.nextDay();
      expect(c.plan(max: 2), <String>['l1']);
    });

    test('a check that belongs to a lesson is never served, and probes and free play never are', () {
      final _Child c = _child(
        catalog: _catalog(
          more: <ItemMeta>[
            _item('probe', purpose: Purpose.probe),
            const ItemMeta(id: 'free', skills: <String, double>{skill: 1}, course: Course.eng, delight: true),
          ],
        ),
      )..right(<String>['l1', 'l2']);
      c.nextDay();
      final List<String> plan = c.plan(inLesson: <String>{'c-transfer', 'yes', 'no', 'c-reverse'});
      expect(plan.where((String id) => id.startsWith('c-') || id == 'yes' || id == 'no'), isEmpty);
      expect(plan, isNot(contains('probe')));
      expect(plan, isNot(contains('free')));
    });

    test('the words of a set not yet answered right come as learn items, while there is room', () {
      final _Child c = _child(catalog: _catalog(setCoverage: true))..answer('l1');
      c.nextDay();
      final List<String> plan = c.plan();
      expect(plan, containsAll(<String>['l2', 'l3']), reason: 'g2 and g3 were never answered right');
    });

    test('a way of showing the skill has not passed comes as one learn item, for a core skill', () {
      final _Child c = _child(catalog: _catalog(core: true))..right(<String>['l1', 'l2']);
      c.nextDay();
      final List<String> plan = c.plan();
      expect(plan, contains('l3'), reason: 'l3 is the only item in the story way');
    });

    test(
      'a skill that lacks only days gets the warm-up, one check of a type it has passed, and learn items',
      () {
        final _Child c = _child()..right(<String>['l1', 'l2', 'l3', 'c-transfer', 'l1', 'l2']);
        c.nextDay();
        expect(c.s.freshAt, isNull, reason: 'one day is not enough');
        final List<String> plan = c.plan();
        expect(plan.first, 'l1');
        expect(plan, contains('c-transfer'), reason: 'a check of the type it has passed');
        expect(plan.length, inInclusiveRange(3, 5));
      },
    );

    test('the visit never ends on a check while there is a learn item to end on', () {
      final Catalog catalog = Catalog(
        skills: const <SkillNode>[SkillNode(id: skill, course: Course.eng, core: true)],
        items: <ItemMeta>[
          _item('l1'),
          _item('l2', difficulty: 0.4),
          _item('c1', purpose: Purpose.check, check: CheckType.transfer),
          _item('c2', purpose: Purpose.check, check: CheckType.reverse),
        ],
      );
      final _Child c = _child(catalog: catalog)..answer('l1');
      c.nextDay();
      final List<String> plan = c.plan();
      expect(plan.last, 'l2');
    });

    test('the number of items follows the band: 5, 8 and 12', () {
      expect(<int>[for (int b = 0; b < 4; b++) checkVisitMax(b)], <int>[5, 8, 12, 12]);
    });

    test('a skill with one item still gets a visit of one', () {
      final Catalog catalog = Catalog(
        skills: const <SkillNode>[SkillNode(id: skill, course: Course.eng)],
        items: <ItemMeta>[_item('only')],
      );
      final _Child c = _child(catalog: catalog)..answer('only');
      c.nextDay();
      expect(c.plan(), <String>['only']);
    });

    test('the same history gives the same visit', () {
      List<String> make() {
        final _Child c = _child(catalog: _catalog(core: true))..right(<String>['l1', 'l2', 'l3']);
        c.nextDay();
        return c.plan();
      }

      expect(make(), make());
    });
  });

  group('C-4: after a failed check', () {
    test('the next visit opens in another way of showing, then asks a different item of the same type', () {
      final Catalog catalog = _catalog(
        more: <ItemMeta>[
          _item(
            'c-transfer-2',
            purpose: Purpose.check,
            check: CheckType.transfer,
            group: 'g2',
            difficulty: 0.55,
          ),
        ],
      );
      final _Child c = _child(catalog: catalog)..right(<String>['l1', 'l3']);
      c.answer('c-transfer', result: Result.incorrect);
      expect(c.s.trail.failedTypes, <CheckType>{CheckType.transfer});
      expect(c.s.checksPassed, isEmpty);
      c.nextDay();
      final List<String> plan = c.plan();
      expect(
        catalog.items[plan.first]!.representation,
        isNot(catalog.items['c-transfer']!.representation),
        reason: 'the warm-up is in another way of showing than the check that failed',
      );
      expect(plan, contains('c-transfer-2'), reason: 'another item of the same type');
      expect(plan, isNot(contains('c-transfer')));
    });

    test('the type is passed later: nothing is held against the child', () {
      final _Child c = _child()..answer('c-transfer', result: Result.incorrect);
      c.nextDay();
      c.answer('c-transfer');
      expect(c.s.trail.failedTypes, isEmpty);
      expect(c.s.checksPassed, contains(CheckType.transfer));
    });

    test('a hinted answer or "not sure" says nothing of the check', () {
      final _Child c = _child()
        ..answer('c-transfer', result: Result.unsure)
        ..answer('c-reverse', hint: 2);
      expect(c.s.trail.failedTypes, isEmpty);
      expect(c.s.trail.failedVisits, 0);
    });

    test(
      'two visits in a row with a failed check: the skill is taught again before the next check visit',
      () {
        final _Child c = _child()..right(<String>['l1', 'l2']);
        c.answer('c-transfer', result: Result.incorrect);
        expect(c.s.trail.needsReteach, isFalse, reason: 'one failed visit is not two');
        c.nextDay();
        c.answer('l1');
        c.answer('c-reverse', result: Result.incorrect);
        expect(c.s.trail.failedVisits, 2);
        expect(
          c.s.trail.needsReteach,
          isTrue,
          reason: 'the learn item of the same visit does not teach again',
        );
        c.nextDay();
        c.answer('l2');
        expect(c.s.trail.needsReteach, isFalse, reason: 'a learn item in a later visit does');
      },
    );

    test('a visit with no failed check ends the run', () {
      final _Child c = _child()..answer('c-transfer', result: Result.incorrect);
      c.nextDay();
      c.answer('c-reverse');
      c.nextDay();
      c.answer('c-transfer', result: Result.incorrect);
      expect(c.s.trail.failedVisits, 1, reason: 'the visit in between was clean');
    });
  });

  group('the last visit', () {
    test('a word asked in the last visit comes after one that was not', () {
      final Catalog catalog = Catalog(
        skills: const <SkillNode>[SkillNode(id: skill, course: Course.eng)],
        items: <ItemMeta>[
          _item('l1'),
          _item('a', purpose: Purpose.check, check: CheckType.transfer, difficulty: 0.4),
          _item('b', purpose: Purpose.check, check: CheckType.transfer, difficulty: 0.6),
        ],
      );
      final _Child c = _child(catalog: catalog)..right(<String>['l1', 'a']);
      c.nextDay();
      expect(c.plan(), contains('b'), reason: 'a was asked in the last visit');
      expect(c.plan(), isNot(contains('a')));
    });
  });
}
