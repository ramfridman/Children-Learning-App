// The developer's guards of the curriculum-expert's QA decisions of 2026-11-07 (docs/languages/band-a-build.md section 7), on the real Band A
// packs: no target text in a Band A item (D1), HEB-A-14 is met by the four start-dot strokes and never fresh (D4), and what the engine knows
// of a course (an item that writes no answer is not one of its items).
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/engine_adapter.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/content/pack_verify.dart';
import 'package:nitznutz/engine/course.dart';
import 'package:nitznutz/engine/engine.dart';
import 'package:nitznutz/engine/state.dart';
import 'package:nitznutz/engine/types.dart';

import '../tool/pack_builder_lib.dart';
import 'support/pack_fixtures.dart';

const String _languages = '../content/languages';

/// Where a document has a `show` (a word printed in a chip), as dotted paths.
List<String> _chips(Object? node, [String path = '']) => <String>[
  if (node is Map<String, Object?>)
    for (final MapEntry<String, Object?> e in node.entries)
      if (e.key == 'show' && e.value is String && (e.value! as String).isNotEmpty)
        '${path}show'
      else
        ..._chips(e.value, '$path${e.key}.')
  else if (node is List<Object?>)
    for (final (int i, Object? v) in node.indexed) ..._chips(v, '$path$i.'),
];

void main() {
  late PackKey key;
  setUpAll(() async => key = await newTestKey());

  Future<VerifiedPack> built(String course) async =>
      verifyPack((await buildPack(languageSource(course, _languages), key)).bytes, publicKey: key.publicKey);

  group('D1: no target-language text in a Band A item', () {
    for (final String course in Course.languages) {
      test(
        '$course: no prompt, say or teach or hearing screen, hint or feedback line prints a word',
        () async {
          final VerifiedPack pack = await built(course);
          final List<String> shown = <String>[];
          for (final MapEntry<String, Object?> e in pack.docs.entries) {
            if (!e.key.startsWith('activity.')) continue;
            final Map<String, Object?> a = e.value! as Map<String, Object?>;
            // The letters, the child's own name and print are the one place a Band A word is shown (Hebrew A-10 to A-12).
            final String skill =
                ((a['skills']! as List<Object?>).first! as Map<String, Object?>)['id']! as String;
            if (a['band'] != 'A' || <String>['HEB-A-10', 'HEB-A-11', 'HEB-A-12'].contains(skill)) continue;
            shown.addAll(<String>[for (final String where in _chips(a)) '${a['id']} $where']);
          }
          expect(shown, isEmpty, reason: 'a Band A step prints no word (band-a-build.md 7.2)');
        },
      );
    }
  });

  group('D4: HEB-A-14, the pre-writing strokes', () {
    late PackContent content;
    late Catalog catalog;
    setUpAll(() async {
      content = PackContent.fromPack(await built('heb'));
      catalog = engineCatalog(content);
    });

    final DateTime start = DateTime.utc(2026, 11, 2, 9);

    Engine child(List<String> items, {int days = 1}) {
      final Engine e = Engine(catalog: catalog);
      int n = 0;
      for (int day = 0; day < days; day++) {
        for (final String item in items) {
          e.apply(
            AttemptEvent(
              id: ++n,
              at: start.add(Duration(days: day, minutes: n)),
              activityId: 'heb.a14.$item',
              result: Result.correct,
              sessionId: day + 1,
              course: 'heb',
            ),
          );
        }
      }
      return e;
    }

    test('the skill says it is practised, and its start-dot strokes are the ones the engine counts', () {
      expect(catalog.skills['HEB-A-14']!.writing, WritingRule.practised);
      expect(catalog.practiceGroupsOf('HEB-A-14'), hasLength(4), reason: 'down, across, arch and circle');
      for (final String id in <String>['05', '06', '07', '08']) {
        expect(catalog.items['heb.a14.$id']!.startGuide, isTrue, reason: id);
      }
      for (final String id in <String>['01', '02', '03', '04', '09']) {
        expect(catalog.items['heb.a14.$id']!.startGuide, isFalse, reason: '$id has the whole path drawn');
      }
    });

    test('it is not met after items 01 to 04 alone, and met after 05 to 08', () {
      final Engine whole = child(<String>['01', '02', '03', '04', '09']);
      expect(whole.isMet('HEB-A-14'), isFalse, reason: 'every one of those has its whole path drawn');
      expect(child(<String>['05', '06', '07']).isMet('HEB-A-14'), isFalse, reason: 'three strokes of four');
      final Engine done = child(<String>['05', '06', '07', '08']);
      expect(done.isMet('HEB-A-14'), isTrue);
      expect(done.statusOf('HEB-A-14', start), SkillStatus.practised);
    });

    test('it is never fresh, however much is traced on however many days', () {
      final Engine e = child(<String>['01', '02', '03', '04', '05', '06', '07', '08', '09'], days: 5);
      expect(e.isMet('HEB-A-14'), isTrue);
      expect(e.state.skills['HEB-A-14']!.freshAt, isNull);
      expect(e.dueChecks(start.add(const Duration(days: 60))), isNot(contains('HEB-A-14')));
    });

    test('a hinted trace does not practise a stroke', () {
      final Engine e = Engine(catalog: catalog);
      for (final String item in <String>['05', '06', '07', '08']) {
        e.apply(
          AttemptEvent(
            at: start,
            activityId: 'heb.a14.$item',
            result: Result.correct,
            hintLevel: 2,
            course: 'heb',
          ),
        );
      }
      expect(e.isMet('HEB-A-14'), isFalse);
    });
  });

  group('what the engine knows of a course', () {
    for (final String course in Course.languages) {
      test('$course: a step that writes no answer is not one of its items', () async {
        final PackContent content = PackContent.fromPack(await built(course));
        final Catalog catalog = engineCatalog(content);
        final Set<String> unscored = <String>{
          for (final Activity a in content.activities.values)
            if (a.unscored) a.id,
        };
        expect(catalog.items.keys.toSet().intersection(unscored), isEmpty);
        final Set<String> saysOfOthers = <String>{
          for (final Activity a in content.activities.values)
            if (a is SayItActivity && content.skills[a.skillId]?.strand != 'spk') a.id,
        };
        expect(
          catalog.items.keys.toSet().intersection(saysOfOthers),
          isEmpty,
          reason: 'a spoken answer counts for a speaking skill only',
        );
        for (final String skill in catalog.skills.keys) {
          if (catalog.isRollUp(skill)) continue;
          for (final String group in catalog.variantGroupsOf(skill)) {
            expect(
              catalog
                  .itemsFor(skill)
                  .any((ItemMeta i) => i.variantGroup == group && i.purpose != Purpose.probe),
              isTrue,
              reason: '$skill $group: a word of a set is one an answer can cover',
            );
          }
        }
      });
    }
  });
}
