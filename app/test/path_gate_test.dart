// M10 E0, the path gate (audit F6): a lesson is offered only when every skill it teaches is unlocked (`Engine.isUnlocked`, bar 0.8);
// otherwise the path skips it and comes back to it later. Without it a 4-year-old who finishes the Band B path would walk into
// Band C lessons, because the path used to walk every lesson of a land by `sequence`.
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/engine_adapter.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/engine/engine.dart';
import 'package:nitznutz/engine/types.dart';
import 'package:nitznutz/world/lesson_path.dart';
import 'package:nitznutz/world/next_lesson.dart';
import 'package:nitznutz/world/path_gate.dart';
import 'package:nitznutz/world/placement.dart';

import 'support/sample_pack.dart';
import 'support/starter.dart';

AttemptEvent perfectAnswer(String activity, DateTime at) =>
    AttemptEvent(at: at, activityId: activity, result: Result.correct);

/// A small land with one skill and one lesson per step of a chain A-03 -> A-04 -> B-01 -> C-01, in path order.
PackContent chainPack() {
  final SamplePack p = SamplePack();
  final Map<String, Object?> skillDoc = p.docs[skillFile]! as Map<String, Object?>;
  final Map<String, Object?> lessonDoc = p.docs[lessonFile]! as Map<String, Object?>;
  Map<String, Object?> skill(String id, String band, String? needs) => Map<String, Object?>.of(skillDoc)
    ..['id'] = id
    ..['band'] = band
    ..['prerequisites'] = <Object?>[
      if (needs != null) <String, Object?>{'skill': needs, 'weight': 0.8},
    ];
  Map<String, Object?> lesson(String id, String skillId, int sequence) => Map<String, Object?>.of(lessonDoc)
    ..['id'] = id
    ..['skills'] = <Object?>[skillId]
    ..['sequence'] = sequence;
  p.docs
    ..remove(skillFile)
    ..remove(skill2File)
    ..remove(lessonFile);
  p.addDocument('skill.NUM-A-03.json', 'skills', 'NUM-A-03', skill('NUM-A-03', 'A', null));
  p.addDocument('skill.NUM-A-04.json', 'skills', 'NUM-A-04', skill('NUM-A-04', 'A', 'NUM-A-03'));
  p.addDocument('skill.NUM-B-01.json', 'skills', 'NUM-B-01', skill('NUM-B-01', 'B', 'NUM-A-04'));
  p.addDocument('skill.NUM-C-01.json', 'skills', 'NUM-C-01', skill('NUM-C-01', 'C', 'NUM-B-01'));
  p.addDocument('lesson.l-a1.json', 'lessons', 'l-a1', lesson('l-a1', 'NUM-A-03', 1));
  p.addDocument('lesson.l-a2.json', 'lessons', 'l-a2', lesson('l-a2', 'NUM-A-04', 2));
  p.addDocument('lesson.l-b1.json', 'lessons', 'l-b1', lesson('l-b1', 'NUM-B-01', 3));
  p.addDocument('lesson.l-c1.json', 'lessons', 'l-c1', lesson('l-c1', 'NUM-C-01', 4));
  return PackContent.fromPack(p.verified());
}

void main() {
  group('nextOnPath with locked lessons', () {
    const List<String> path = <String>['a', 'b', 'c', 'd'];

    test('a locked lesson is skipped, and the next open one is offered', () {
      expect(nextOnPath(path, const <String, int>{'a': 1}, locked: const <String>{'b'}), 'c');
    });

    test('it is offered again as soon as it is not locked any more', () {
      expect(nextOnPath(path, const <String, int>{'a': 1}), 'b');
    });

    test('with every unfinished lesson locked the path goes round the open ones, fewest times first', () {
      expect(nextOnPath(path, const <String, int>{'a': 2, 'b': 1}, locked: const <String>{'c', 'd'}), 'b');
    });

    test('a path with nothing open offers nothing', () {
      expect(nextOnPath(path, const <String, int>{}, locked: path.toSet()), isNull);
    });
  });

  group('lockedLessons on a land that has a Band C', () {
    late PackContent pack;
    setUpAll(() => pack = chainPack());

    Engine engineWith({Set<String> assumed = const <String>{}}) =>
        Engine(catalog: engineCatalog(pack))..assume(assumed);

    test('a child who knows nothing has only the first lesson open: not Band B, and never Band C', () {
      final Engine e = engineWith();
      expect(lockedLessons(pack, 'numbers', e.isUnlocked), <String>{'l-a2', 'l-b1', 'l-c1'});
    });

    test('a 4-year-old who finished the whole Band A and B path is not offered Band C', () {
      final Engine e = engineWith();
      final Map<String, int> finished = <String, int>{'l-a1': 1, 'l-a2': 1, 'l-b1': 1};
      final String? next = nextLessonId(
        content: pack,
        domain: 'numbers',
        finished: finished,
        unlocked: e.isUnlocked,
      );
      expect(next, 'l-a1', reason: 'the path goes round the open lesson until its skill is known');
    });

    test('a child whose Band B skills are known is offered Band C once Band A and B lessons are done', () {
      final Engine e = engineWith(assumed: <String>{'NUM-A-03', 'NUM-A-04', 'NUM-B-01'});
      expect(lockedLessons(pack, 'numbers', e.isUnlocked), isEmpty);
      final Map<String, int> finished = <String, int>{'l-a1': 1, 'l-a2': 1, 'l-b1': 1};
      expect(
        nextLessonId(content: pack, domain: 'numbers', finished: finished, unlocked: e.isUnlocked),
        'l-c1',
      );
    });

    test('a lesson that is unlocked later is offered then, not before', () {
      final Engine before = engineWith(assumed: <String>{'NUM-A-03'});
      expect(lockedLessons(pack, 'numbers', before.isUnlocked), <String>{'l-b1', 'l-c1'});
      final Engine later = engineWith(assumed: <String>{'NUM-A-03', 'NUM-A-04'});
      expect(lockedLessons(pack, 'numbers', later.isUnlocked), <String>{'l-c1'});
    });

    test(
      'when nothing in a land is open, the lessons of its lowest band are, so that the land is never empty',
      () {
        // Every lesson of the land asks for a skill of another land that this child does not have.
        final Set<String> all = <String>{'l-a1', 'l-a2', 'l-b1', 'l-c1'};
        final Set<String> locked = lockedLessons(
          pack,
          'numbers',
          (String skill, Set<String> together) => false,
        );
        expect(locked, all.difference(<String>{'l-a1', 'l-a2'}));
      },
    );

    test('a land with no lesson has nothing locked, and no next lesson', () {
      expect(lockedLessons(pack, 'none', (String s, Set<String> together) => false), isEmpty);
      expect(
        nextLessonId(
          content: pack,
          domain: 'none',
          finished: const <String, int>{},
          unlocked: (String s, Set<String> together) => true,
        ),
        isNull,
      );
    });
  });

  group('the starter pack under the gate', () {
    late PackContent content;
    setUpAll(() async => content = await loadStarter());

    test('a child who knows nothing is offered, in every land, a lesson whose skills are all unlocked', () {
      final Engine e = Engine(catalog: engineCatalog(content));
      for (final String domain in <String>['numbers', 'math', 'shapes', 'logic', 'colors']) {
        final String id = nextLessonId(
          content: content,
          domain: domain,
          finished: const <String, int>{},
          unlocked: e.isUnlocked,
        )!;
        final Set<String> together = content.lessons[id]!.skillIds.toSet();
        for (final String s in together) {
          expect(e.isUnlocked(s, together), isTrue, reason: '$domain: $id needs $s');
        }
      }
    });

    test('no land is ever left with nothing to play, and no lesson of a land is locked for ever', () {
      // A child who answers everything right, without help, plays the path of the land they like best. Every lesson of every
      // land must open at some point: the gate holds lessons back, it does not lose them.
      final Engine e = Engine(catalog: engineCatalog(content));
      final Map<String, int> finished = <String, int>{};
      final Set<String> domains = <String>{for (final SkillDoc s in content.skills.values) s.domain};
      DateTime at = DateTime.utc(2026, 11, 1);
      bool moved = true;
      int guard = 0;
      while (moved && guard++ < 2000) {
        moved = false;
        for (final String domain in domains) {
          final String? id = nextLessonId(
            content: content,
            domain: domain,
            finished: finished,
            unlocked: e.isUnlocked,
          );
          if (id == null) fail('$domain has nothing to play');
          if ((finished[id] ?? 0) >= 3) continue;
          finished[id] = (finished[id] ?? 0) + 1;
          for (final String item in content.lessons[id]!.itemIds) {
            at = at.add(const Duration(minutes: 1));
            e.apply(perfectAnswer(item, at));
          }
          moved = true;
        }
      }
      final Set<String> neverOffered = <String>{
        for (final Lesson l in content.lessons.values)
          if (!finished.containsKey(l.id)) l.id,
      };
      expect(neverOffered, isEmpty, reason: 'lessons that stayed locked: $neverOffered');
    });
  });

  test('landPath is still every lesson of the land by sequence: the gate does not reorder it', () async {
    final PackContent content = await loadStarter();
    final List<Lesson> path = landPath(content, 'numbers');
    expect(path.first.id, 'butterflies');
  });
}
