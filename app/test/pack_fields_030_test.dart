// The optional fields that pack 0.3.0 adds (M8b, M7 Q6): the object that grows for a skill, one line for the child of what
// they can do, and a home activity on a misunderstanding. A pack without them works as before, and a pack with them shows
// them; nothing else may be added to a document.
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/schema.dart';
import 'package:nitznutz/content/schemas.dart';
import 'package:nitznutz/engine/types.dart';
import 'package:nitznutz/parent/progress.dart';
import 'package:nitznutz/rewards/award.dart';
import 'package:nitznutz/world/world_state.dart';

import 'engine/fixtures.dart';
import 'support/sample_pack.dart';

Map<String, Object?> copyOf(Object? doc) => Map<String, Object?>.of(doc! as Map<String, Object?>);

List<Object?> he(String text) => <Object?>[
  <String, Object?>{'t': 'he', 'v': text},
];

void main() {
  group('the schema of a skill', () {
    final Map<String, Object?> base = copyOf(SamplePack().docs[skillFile]);

    test('a skill without the new fields is still fine', () {
      expect(validate(skillSchema, base), isEmpty);
    });

    test('it may name its object and carry a line for the child', () {
      final Map<String, Object?> skill = copyOf(base)
        ..['worldObject'] = 'stair'
        ..['childLine'] = he('סוֹפְרִים עַד חָמֵשׁ');
      expect(validate(skillSchema, skill), isEmpty);
    });

    test(
      'an object is a plain id, not a path or a word with capitals; a line is Hebrew in the usual shape',
      () {
        for (final String bad in <String>['Stair', '../stair', 'a', 'x' * 25, 'st air', '1stair']) {
          expect(validate(skillSchema, copyOf(base)..['worldObject'] = bad), isNotEmpty, reason: bad);
        }
        expect(validate(skillSchema, copyOf(base)..['childLine'] = 'plain text'), isNotEmpty);
        expect(
          validate(
            skillSchema,
            copyOf(base)
              ..['childLine'] = <Object?>[
                <String, Object?>{'t': 'en', 'v': 'x'},
              ],
          ),
          isNotEmpty,
          reason: 'Hebrew only',
        );
        expect(validate(skillSchema, copyOf(base)..['childLine'] = he('א' * 241)), isNotEmpty);
      },
    );

    test('nothing else can ride along', () {
      expect(validate(skillSchema, copyOf(base)..['reward'] = 'x'), isNotEmpty);
    });
  });

  group('the schema of a misunderstanding', () {
    final Map<String, Object?> base = copyOf(SamplePack().docs[tagFile]);

    test('it may carry a home activity, and is fine without one', () {
      expect(validate(misconceptionSchema, base), isEmpty);
      expect(
        validate(misconceptionSchema, copyOf(base)..['homeActivity'] = he('לשיר יחד שיר ספירה')),
        isEmpty,
      );
      expect(validate(misconceptionSchema, copyOf(base)..['homeActivity'] = 'plain'), isNotEmpty);
      expect(validate(misconceptionSchema, copyOf(base)..['homeActivity'] = he('א' * 241)), isNotEmpty);
    });
  });

  group('the world takes the pack\'s object first', () {
    const WorldCatalog catalog = WorldCatalog(
      skills: <String, String>{'SK-A-01': 'pool'},
      domains: <String, String>{'numbers': 'stair'},
      fallback: 'sprout',
    );

    test('a skill the pack names gets that drawing; the others keep the app\'s catalog', () {
      final WorldCatalog withPack = catalog.withPack(<String, String>{'SK-A-01': 'stall', 'SK-B-01': 'dock'});
      expect(withPack.objectFor('SK-A-01', 'numbers'), 'stall');
      expect(withPack.objectFor('SK-B-01', 'numbers'), 'dock');
      expect(withPack.objectFor('SK-C-01', 'numbers'), 'stair');
      expect(catalog.objectFor('SK-A-01', 'numbers'), 'pool', reason: 'the catalog itself is not changed');
    });

    test('a line for the child comes with the object it belongs to', () {
      final Map<TrophyLand, List<WorldObject>> world = buildWorld(
        engine: engineOf(smallCatalog()),
        skills: const <String, SkillInfo>{
          'SK-A-01': SkillInfo(title: 'a', domain: 'numbers'),
          'SK-B-01': SkillInfo(title: 'b', domain: 'numbers'),
        },
        starredSkills: const <String>{},
        catalog: catalog,
        now: day0,
        lines: const <String, String>{'SK-A-01': 'סוֹפְרִים'},
      );
      final List<WorldObject> counting = world[TrophyLand.counting]!;
      expect(counting.firstWhere((WorldObject o) => o.skillId == 'SK-A-01').line, 'סוֹפְרִים');
      expect(counting.firstWhere((WorldObject o) => o.skillId == 'SK-B-01').line, isNull);
    });
  });

  group('the parent\'s progress shows the home activity', () {
    test('a misunderstanding that is active carries its home activity when the pack has one', () {
      final Progress p = buildProgress(
        ProgressSource(
          catalog: smallCatalog(),
          skillInfo: const <String, SkillInfo>{'SK-A-01': SkillInfo(title: 'a', domain: 'numbers')},
          tagText: const <String, String>{'M-A': 'הילד מדלג על עצם', 'M-B': 'הילד סופר פעמיים'},
          tagHome: const <String, String>{'M-A': 'לספור צעצועים במעגל'},
          attempts: <AttemptEvent>[
            for (int i = 0; i < 3; i++)
              AttemptEvent(
                at: day0.add(Duration(minutes: i)),
                activityId: 'A.${i + 1}',
                result: Result.incorrect,
                tag: 'M-A',
              ),
          ],
          sessions: const [],
          now: day0.add(const Duration(days: 1)),
        ),
      );
      final MisconceptionRow row = p.misconceptions.firstWhere((MisconceptionRow m) => m.id == 'M-A');
      expect(row.homeActivity, 'לספור צעצועים במעגל');
    });
  });
}
