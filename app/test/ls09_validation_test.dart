// LS09 say it with me, the pack side: the schema, the validator's rules for the words of a say-it item, and the engine's rule for
// speech evidence. Fixture courses, not content.
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/pack_validation.dart';
import 'package:nitznutz/content/schema.dart';
import 'package:nitznutz/content/schemas.dart';
import 'package:nitznutz/engine/engine.dart';
import 'package:nitznutz/engine/state.dart';
import 'package:nitznutz/engine/types.dart';

import 'support/language_content.dart';
import 'support/sample_pack.dart';

List<Problem> _run(LangPack p) =>
    validatePack(manifest: p.pack.manifest, docs: p.pack.docs, files: p.pack.files);

String _say(Map<String, Object?> a) => (a['say']! as Map<String, Object?>).toString();

void main() {
  group('a say-it item is a document of the pack', () {
    test('the schema knows the template, and a good item has no problem', () {
      expect(supportedTemplates['say_it'], '1.0');
      final LangPack p = LangPack();
      final Map<String, Object?> a = sayJson(id: 'cat');
      expect(validate(activitySchemaFor('say_it')!, a), isEmpty);
      p.add(a);
      expect(_run(p), isEmpty);
    });

    test('a chunk with key words, and a scored one, are fine', () {
      final LangPack p = LangPack();
      p.add(
        sayJson(
          id: 'happy',
          forms: <String>["I'm happy"],
          foils: <String>["I'm sad"],
          keyWords: <String>['happy'],
          scored: true,
        ),
      );
      expect(_run(p), isEmpty);
    });

    test('the item has no options and no wrong answer: the model knows it', () {
      final LangPack p = LangPack();
      p.add(sayJson(id: 'cat'));
      expect(p.content.activities['eng.cat']!.optionCount, 0);
      expect(p.content.activities['eng.cat']!.engineTags, isEmpty);
    });
  });

  group('the words of a say-it item are held to rules', () {
    test('no foil may be the target or one of its forms, however it is spelled', () {
      final LangPack p = LangPack();
      p.add(sayJson(id: 'cat', foils: <String>['CAT!', 'hat']));
      expect(_run(p).map((Problem x) => x.toString()).join('\n'), contains('say.foils[0]'));
    });

    test('a foil list is required, so the decision always has something to be clear of', () {
      final LangPack p = LangPack();
      final Map<String, Object?> a = sayJson(id: 'cat');
      (a['say']! as Map<String, Object?>)['foils'] = <String>[];
      p.add(a);
      expect(_run(p), isNotEmpty);
    });

    test('a key word must be a word of one of the forms', () {
      final LangPack p = LangPack();
      p.add(
        sayJson(
          id: 'happy',
          forms: <String>["I'm happy"],
          foils: <String>['sad'],
          keyWords: <String>['glad'],
        ),
      );
      expect(_run(p).map((Problem x) => x.toString()).join('\n'), contains('say.keyWords[0]'));
    });

    test(
      'a hotword list cannot be changed by a word: the characters of its format are refused by the schema',
      () {
        for (final String bad in <String>['cat :99', 'cat#1', 'a@b', 'a/b', 'a\nb']) {
          final Map<String, Object?> a = sayJson(id: 'cat', forms: <String>[bad]);
          expect(validate(activitySchemaFor('say_it')!, a), isNotEmpty, reason: bad);
        }
      },
    );

    test('script purity: a Cyrillic word in an English item, and a form with no letter of the script, are refused', () {
      final LangPack p = LangPack();
      p.add(
        sayJson(
          id: 'cat',
          forms: <String>[
            'cat',
            String.fromCharCodes(<int>[0x43, 0x430, 0x74]),
          ],
        ),
      );
      expect(_run(p), isNotEmpty);
      final LangPack q = LangPack();
      q.add(sayJson(id: 'num', forms: <String>['123'], foils: <String>['hat']));
      expect(_run(q).map((Problem x) => x.toString()).join('\n'), contains('say.forms[0]'));
    });

    test('the lands have no say-it', () {
      final LangPack p = LangPack();
      final Map<String, Object?> a = sayJson(id: 'cat');
      p.add(a);
      // The same activity in a pack of the lands is refused (its course is `core`).
      final SamplePack core = SamplePack();
      final Map<String, Object?> core1 = Map<String, Object?>.of(a)..remove('course');
      core1['id'] = 'say-cat';
      core.addDocument('activity.say-cat.json', 'activities', 'say-cat', core1);
      expect(
        validatePack(
          manifest: core.manifest,
          docs: core.docs,
          files: core.files,
        ).map((Problem x) => x.toString()).join('\n'),
        contains('say-it of a language course'),
      );
    });

    test('SEC-L1-3: a language item is never answered by voice; its speech is the say step', () {
      final LangPack p = LangPack();
      final Map<String, Object?> a = tapJson(
        id: 'voicepick',
        options: <Map<String, Object?>>[
          textOption('o1', 'cat'),
          textOption('o2', 'dog', tag: p.tag('lis.sem')),
        ],
        correct: 'o1',
      );
      a['voiceAnswer'] = true;
      p.add(a);
      expect(_run(p).map((Problem x) => x.toString()).join('\n'), contains('voiceAnswer'));
    });
  });

  group('speech is evidence for a speaking skill only, and at most half of it', () {
    Engine engineWith({required bool speaking}) => Engine(
      catalog: Catalog(
        skills: <SkillNode>[SkillNode(id: 'ENG-A-12', course: 'eng', speaking: speaking)],
        items: <ItemMeta>[
          ItemMeta(
            id: 'eng.a',
            course: 'eng',
            skills: <String, double>{'ENG-A-12': 1},
            purpose: Purpose.learn,
            checkType: CheckType.practice,
            representation: Representation.embodied,
            variantGroup: 'a',
            difficulty: 0.2,
            optionCount: 0,
            tags: const <String>{},
            revision: 1,
          ),
          const ItemMeta(
            id: 'eng.p',
            course: 'eng',
            skills: <String, double>{'ENG-A-12': 1},
            purpose: Purpose.probe,
            representation: Representation.embodied,
            variantGroup: 'p',
            revision: 1,
          ),
        ],
      ),
    );

    int n = 0;
    AttemptEvent event({
      bool speech = false,
      Result result = Result.correct,
      int hint = 0,
      String item = 'eng.a',
      int day = 5,
    }) => AttemptEvent(
      id: ++n,
      at: DateTime.utc(2026, 11, day, 9, n),
      activityId: item,
      result: result,
      hintLevel: hint,
      course: 'eng',
      sessionId: 1,
      viaSpeech: speech,
    );

    test('a heard word for a skill that is not a speaking skill changes nothing', () {
      final Engine e = engineWith(speaking: false);
      e.apply(event(speech: true));
      expect(e.state.skills['ENG-A-12']?.n ?? 0, 0);
      e.apply(event());
      expect(e.state.skills['ENG-A-12']!.successes, 1);
    });

    test('speech is at most half of the successes: the second spoken success waits for a second tap', () {
      final Engine e = engineWith(speaking: true);
      e.apply(event(speech: true));
      expect(
        e.state.skills['ENG-A-12']?.successes ?? 0,
        0,
        reason: 'the first success cannot be speech: the cap is half',
      );
      e.apply(event());
      e.apply(event(speech: true));
      e.apply(event(speech: true));
      final SkillState s = e.state.skills['ENG-A-12']!;
      expect(<int>[s.successes, s.speechSuccesses], <int>[2, 1]);
      e.apply(event());
      e.apply(event(speech: true));
      expect(<int>[s.successes, s.speechSuccesses], <int>[4, 2]);
    });

    test('a spoken answer that is not a success is no evidence at all', () {
      final Engine e = engineWith(speaking: true);
      e.apply(event());
      final double p = e.state.skills['ENG-A-12']!.p;
      e.apply(event(speech: true, result: Result.unsure));
      e.apply(event(speech: true, result: Result.incorrect));
      final SkillState s = e.state.skills['ENG-A-12']!;
      expect(<Object>[s.p, s.n, s.nUnsure, s.failRun], <Object>[p, 1, 0, 0]);
    });
    // SEC-L3-1 and QA-L3-3: a spoken answer that does not count changes nothing at all.
    test(
      'SEC-L3-1: spoken answers after a hint are no evidence, however many (the cap cannot be walked round)',
      () {
        final Engine e = engineWith(speaking: true);
        e.apply(event());
        final SkillState s = e.state.skills['ENG-A-12']!;
        final double p = s.p;
        for (int i = 0; i < 10; i++) {
          e.apply(event(speech: true, hint: 1));
        }
        expect(<Object>[s.n, s.nCorrect, s.p, s.speechSuccesses], <Object>[1, 1, p, 0]);
        expect(e.state.sessions[1]!.length, 1, reason: 'not even the session remembers them');
      },
    );

    test('a spoken answer that is refused leaves no review, no gap repair and no statistics of a way of explaining', () {
      final Engine e = engineWith(speaking: true);
      e.apply(event());
      e.apply(event(speech: true)); // counted: speech 1 of 1 other
      final SkillState s = e.state.skills['ENG-A-12']!;
      final DateTime? reviewed = s.lastAttemptAt;
      final RepStats r = e.state.repStats('ENG-A', Representation.embodied);
      final List<int> before = <int>[r.tries, r.successes, s.n, s.successes, s.speechSuccesses];
      final Gap gap = Gap(
        origin: 'ENG-A-12',
        skill: 'ENG-A-12',
        foundAt: DateTime.utc(2026, 11, 5, 8),
        probes: 0,
        via: 'walk',
      );
      e.state.gaps.add(gap);
      for (int i = 0; i < 10; i++) {
        e.apply(event(speech: true, day: 6 + i)); // over the cap, on ten other days
      }
      expect(<int>[r.tries, r.successes, s.n, s.successes, s.speechSuccesses], before);
      expect(s.lastAttemptAt, reviewed, reason: 'no retention review, however many days');
      expect(<Object>[gap.repairSuccesses, gap.repaired], <Object>[0, false]);
    });

    test('a spoken answer in a probe is no evidence', () {
      final Engine e = engineWith(speaking: true);
      e.apply(event());
      e.apply(event());
      final SkillState s = e.state.skills['ENG-A-12']!;
      final List<Object> before = <Object>[s.n, s.p];
      e.apply(event(speech: true, item: 'eng.p'));
      expect(<Object>[s.n, s.p], before);
    });

    test('every spoken answer that counts is counted toward the cap: speech never passes half', () {
      final Engine e = engineWith(speaking: true);
      for (int i = 0; i < 4; i++) {
        e.apply(event());
      }
      for (int i = 0; i < 20; i++) {
        e.apply(event(speech: true));
      }
      final SkillState s = e.state.skills['ENG-A-12']!;
      expect(<int>[s.successes, s.speechSuccesses], <int>[8, 4]);
      expect(s.successes - s.speechSuccesses, greaterThanOrEqualTo(s.speechSuccesses));
    });

    test('a refused spoken answer creates no state for a skill the child never answered by tap', () {
      final Engine e = engineWith(speaking: true);
      e.apply(event(speech: true));
      expect(e.state.skills.containsKey('ENG-A-12'), isFalse);
      expect(e.state.sessions, isEmpty);
    });
  });

  test('_say helper is used', () {
    expect(_say(sayJson(id: 'x')), contains('cat'));
  });
}
