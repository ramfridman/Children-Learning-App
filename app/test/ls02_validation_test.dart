// The rules of LS02 in the pack validator (L5 section 5.2, docs/languages/writing-mastery.md section 8): a clean pack passes, and each broken file
// is refused with its own message.
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/pack_validation.dart';
import 'package:nitznutz/content/schema.dart';
import 'package:nitznutz/content/schemas.dart';

import 'support/ls02_content.dart';

/// A clean English pack of one letter group: the intro and two traces of s (the trace node), a copy and two memory items (the writing node).
Ls02Pack clean({String course = 'eng'}) {
  final Ls02Pack p = Ls02Pack(course);
  final GroupSkills g = p.skills;
  final String x = course == 'heb' ? 'mem' : (course == 'rus' ? 'em' : 's');
  final String s = p.form(x, cap: course == 'rus');
  p.add(
    letterJson(
      course: course,
      id: 'n01',
      skill: g.trace,
      mode: 'intro',
      forms: <String>[s],
      intro: introData(course, x),
    ),
  );
  p.add(
    letterJson(
      course: course,
      id: 't01',
      skill: g.trace,
      mode: 'trace',
      guide: 'full',
      forms: <String>[s],
      classify: p.classify(),
    ),
  );
  p.add(
    letterJson(
      course: course,
      id: 't02',
      skill: g.trace,
      mode: 'trace',
      guide: 'start',
      forms: <String>[s],
      classify: p.classify(),
    ),
  );
  p.add(
    letterJson(
      course: course,
      id: 'w01',
      skill: g.write,
      mode: 'copy',
      forms: <String>[s],
      classify: p.classify(),
    ),
  );
  p.add(
    letterJson(
      course: course,
      id: 'w02',
      skill: g.write,
      mode: 'memory',
      cue: 'sound',
      cueClip: 'vo:$course.snd.$x',
      forms: <String>[s],
      classify: p.classify(),
    ),
  );
  p.add(
    letterJson(
      course: course,
      id: 'w03',
      skill: g.write,
      mode: 'memory',
      cue: 'name',
      cueClip: 'vo:$course.name.$x',
      forms: <String>[s],
      classify: p.classify(),
      purpose: 'check',
      checkType: 'transfer',
    ),
  );
  p.addLesson('one', <String>['n01', 't01', 't02'], <String>[g.trace], 1);
  p.addLesson('two', <String>['w01', 'w02', 'w03'], <String>[g.write], 2);
  return p;
}

List<Problem> check(Ls02Pack p) {
  // A deep copy: the validator reads the documents, never keeps them.
  final Map<String, Object?> docs = jsonDecode(jsonEncode(p.pack.pack.docs))! as Map<String, Object?>;
  final Map<String, Object?> manifest = jsonDecode(jsonEncode(p.pack.pack.manifest))! as Map<String, Object?>;
  return validatePack(manifest: manifest, docs: docs, files: p.pack.pack.files);
}

Map<String, Object?> doc(Ls02Pack p, String id) => p.pack.pack.doc('activity.${p.course}.$id.json');
Map<String, Object?> scene(Ls02Pack p, String id) => doc(p, id)['scene']! as Map<String, Object?>;
Map<String, Object?> skillDoc(Ls02Pack p, String id) => p.pack.pack.doc('skill.$id.json');

void refused(Ls02Pack p, String message) {
  final List<Problem> found = check(p);
  expect(
    found.any((Problem q) => q.toString().contains(message)),
    isTrue,
    reason: 'expected "$message" among\n${found.join('\n')}',
  );
}

void main() {
  group('a clean pack', () {
    for (final String course in <String>['eng', 'heb', 'rus']) {
      test('of $course passes every rule', () => expect(check(clean(course: course)), isEmpty));
    }

    test('the real stroke sets pass their own schema', () {
      for (final String set in <String>['latin', 'cyrillic', 'hebrew-print', 'hebrew-script']) {
        expect(validate(strokesSchema, strokeSetDoc(set)), isEmpty, reason: set);
      }
    });
  });

  group('the stroke set', () {
    test('a form that is not in the set is refused', () {
      final Ls02Pack p = clean();
      scene(p, 't02')['forms'] = <Object?>['latin.zz'];
      p.pack.activity('t02')['variantGroup'] = 'latin.zz';
      refused(p, 'is not a form of the stroke set latin');
    });

    test('a form of another script is refused in this course', () {
      final Ls02Pack p = clean();
      scene(p, 't02')['forms'] = <Object?>['cyrillic.a'];
      p.pack.activity('t02')['variantGroup'] = 'cyrillic.a';
      refused(p, 'the course eng does not write in at band B');
    });

    test('the script letters of Hebrew are for band C only', () {
      final Ls02Pack p = clean(course: 'heb');
      scene(p, 't02')['forms'] = <Object?>['hebrew-script.mem'];
      p.pack.activity('t02')['variantGroup'] = 'hebrew-script.mem';
      refused(p, 'which the course heb does not write in at band B');
    });

    test('a stroke set that still needs its teacher is refused in a language pack', () {
      final Ls02Pack p = clean();
      p.pack.pack.doc('strokes.latin.json')['review'] = 'needs-teacher';
      refused(p, 'the stroke set is not teacher-checked');
    });

    test('a stroke set that is not in the pack is refused', () {
      final Ls02Pack p = clean();
      p.pack.pack.docs.remove('strokes.latin.json');
      p.pack.pack.files.remove('strokes.latin.json');
      (p.pack.pack.manifest['files']! as List<Object?>).removeWhere(
        (Object? f) => (f! as Map<String, Object?>)['name'] == 'strokes.latin.json',
      );
      ((p.pack.pack.manifest['entries']! as Map<String, Object?>)['strokes']! as List<Object?>).clear();
      refused(p, 'the stroke set latin is not in this pack');
    });

    test('a stroke set of another course is refused', () {
      final Ls02Pack p = clean();
      (p.pack.pack.doc('strokes.latin.json')['courses']! as List<Object?>).setAll(0, <Object?>['rus']);
      refused(p, 'is not a stroke set of the course eng');
    });

    test(
      'the bounds of a stroke: a point outside the box, too many points, too many strokes, a hostile path',
      () {
        Map<String, Object?> latin() => strokeSetDoc('latin');
        List<Object?> forms(Map<String, Object?> d) => d['forms']! as List<Object?>;
        Map<String, Object?> stroke(Map<String, Object?> d) =>
            ((forms(d).first! as Map<String, Object?>)['strokes']! as List<Object?>).first!
                as Map<String, Object?>;

        Map<String, Object?> d = latin();
        (stroke(d)['points']! as List<Object?>)[0] = <Object?>[101, 5];
        expect(validate(strokesSchema, d).map((Problem p) => p.path).join(), contains('points[0][0]'));

        d = latin();
        stroke(d)['points'] = <Object?>[
          for (int i = 0; i < 61; i++) <Object?>[i, i],
        ];
        expect(validate(strokesSchema, d).map((Problem p) => p.path).join(), contains('points'));

        d = latin();
        final Map<String, Object?> first = forms(d).first! as Map<String, Object?>;
        first['strokes'] = <Object?>[for (int i = 0; i < 7; i++) stroke(latin())];
        expect(validate(strokesSchema, d).isNotEmpty, isTrue);

        d = latin();
        stroke(d)['d'] = 'M 1 1 L ../../etc 2';
        expect(validate(strokesSchema, d).isNotEmpty, isTrue);

        d = latin();
        d['unknown'] = 1;
        expect(validate(strokesSchema, d).isNotEmpty, isTrue);
      },
    );
  });

  group('the modes', () {
    test('an intro names the trace node of its group', () {
      final Ls02Pack p = clean();
      doc(p, 'n01')['skills'] = <Object?>[
        <String, Object?>{'id': p.skills.facet, 'weight': 1},
      ];
      refused(p, 'an intro names the trace node of its group');
    });

    test('an intro is never scored, has no classifiers and offers no help', () {
      final Ls02Pack p = clean();
      doc(p, 'n01')['purpose'] = 'probe';
      refused(p, 'an intro is never scored');
      final Ls02Pack q = clean();
      (doc(q, 'n01')['answer']! as Map<String, Object?>)['classify'] = <String, Object?>{};
      refused(q, 'an intro scores nothing');
      final Ls02Pack r = clean();
      doc(r, 'n01')['hints'] = doc(r, 't01')['hints'];
      refused(r, 'an intro offers no help');
    });

    test('each mode needs its own field and no other', () {
      Ls02Pack p = clean();
      scene(p, 't01').remove('guide');
      refused(p, 'a trace item needs "guide"');
      p = clean();
      scene(p, 'w01').remove('model');
      refused(p, 'a copy item needs "model"');
      p = clean();
      scene(p, 'w02').remove('cue');
      refused(p, 'a memory item needs "cue"');
      p = clean();
      scene(p, 'w01')['cue'] = 'sound';
      refused(p, '"cue" belongs to the memory mode');
    });

    test('a memory item plays its cue clip', () {
      final Ls02Pack p = clean();
      (doc(p, 'w02')['prompt']! as Map<String, Object?>).remove('target');
      refused(p, 'a memory item plays its cue clip');
    });

    test('a letter whose name is its sound has a sound cue only, and a cue is the clip its intro says', () {
      Ls02Pack p = clean();
      final Map<String, Object?> intro = scene(p, 'n01')['intro']! as Map<String, Object?>;
      intro['name'] = intro['sound'];
      (doc(p, 'w03')['prompt']! as Map<String, Object?>)['target'] = intro['sound'];
      refused(p, 'is its sound (one clip)');
      p = clean();
      (doc(p, 'w02')['prompt']! as Map<String, Object?>)['target'] = 'vo:eng.snd.other';
      refused(p, 'is not the sound the intro of latin.s says');
    });

    test('a letter canvas has one form and its variant group is that form', () {
      Ls02Pack p = clean();
      scene(p, 't01')['forms'] = <Object?>['latin.s', 'latin.a'];
      refused(p, 'a letter canvas has one form');
      p = clean();
      doc(p, 't01')['variantGroup'] = 'some-letter';
      refused(p, 'is the form id of the letter');
    });

    test('a word canvas has two to six boxes, and "practice" is for a word canvas only', () {
      Ls02Pack p = clean();
      scene(p, 't01')['canvas'] = 'word';
      refused(p, 'a word canvas has two to six boxes');
      p = clean();
      scene(p, 't01')['practice'] = true;
      refused(p, '"practice" is allowed only on a word canvas');
    });

    test('every item is embodied and names exactly one skill', () {
      Ls02Pack p = clean();
      doc(p, 't01')['representation'] = 'symbolic';
      refused(p, 'writing is embodied');
      p = clean();
      doc(p, 't01')['skills'] = <Object?>[
        <String, Object?>{'id': p.skills.trace, 'weight': 1},
        <String, Object?>{'id': p.skills.facet, 'weight': 0.5},
      ];
      refused(p, 'names exactly one skill');
    });

    test('write a letter belongs to a language course', () {
      final Ls02Pack p = clean();
      // The same file in a pack of the lands.
      final Map<String, Object?> manifest =
          jsonDecode(jsonEncode(p.pack.pack.manifest))! as Map<String, Object?>;
      manifest.remove('course');
      final Map<String, Object?> docs = jsonDecode(jsonEncode(p.pack.pack.docs))! as Map<String, Object?>;
      expect(
        validatePack(
          manifest: manifest,
          docs: docs,
          files: p.pack.pack.files,
        ).any((Problem q) => q.toString().contains('belongs to a language course')),
        isTrue,
      );
    });
  });

  group('the classifiers', () {
    test('a stroke error maps to a tag of the family STROKE or SHAPE', () {
      final Ls02Pack p = clean();
      ((doc(p, 'w02')['answer']! as Map<String, Object?>)['classify']! as Map<String, Object?>)['start'] = p
          .tag('name');
      refused(p, 'is of the family NAME: a stroke error maps to a STROKE or SHAPE tag');
    });

    test('a tag that is not in the catalogue is refused', () {
      final Ls02Pack p = clean();
      ((doc(p, 'w02')['answer']! as Map<String, Object?>)['classify']! as Map<String, Object?>)['lines'] =
          'eng.wri.nothere';
      refused(p, 'is not in the misconception catalogue');
    });

    test(
      'a look-alike partner: a form of the set, not the target, with a SHAPE tag or a homophone on the way',
      () {
        Ls02Pack p = clean();
        ((doc(p, 'w02')['answer']! as Map<String, Object?>)['classify']!
            as Map<String, Object?>)['partners'] = <String, Object?>{
          'latin.c': p.tag('shape'),
          'latin.k': p.tag('homophone'),
        };
        expect(check(p), isEmpty, reason: 'a shape partner and a homophone on the way are both allowed');
        p = clean();
        ((doc(p, 'w02')['answer']! as Map<String, Object?>)['classify']!
            as Map<String, Object?>)['partners'] = <String, Object?>{
          'latin.s': p.tag('shape'),
        };
        refused(p, 'is the target itself, not a look-alike');
        p = clean();
        ((doc(p, 'w02')['answer']! as Map<String, Object?>)['classify']!
            as Map<String, Object?>)['partners'] = <String, Object?>{
          'latin.zz': p.tag('shape'),
        };
        refused(p, 'is not a form of the stroke set latin');
        p = clean();
        ((doc(p, 'w02')['answer']! as Map<String, Object?>)['classify']!
            as Map<String, Object?>)['partners'] = <String, Object?>{
          'latin.c': p.tag('name'),
        };
        refused(p, 'is of the family NAME');
      },
    );
  });

  group('a trace node', () {
    test('has no check and no probe', () {
      Ls02Pack p = clean();
      doc(p, 't02')['purpose'] = 'check';
      refused(p, 'a trace node has no check and no probe');
      p = clean();
      doc(p, 't02')['purpose'] = 'probe';
      refused(p, 'a trace node has no check and no probe');
      p = clean();
      doc(p, 't02')['checkType'] = 'transfer';
      refused(p, 'a trace node has no check');
    });

    test('has a trace with the start dot only for every letter', () {
      final Ls02Pack p = clean();
      scene(p, 't02')['guide'] = 'full';
      refused(p, 'has no trace with the start dot only');
    });

    test('asks for no mastery and is in no gate', () {
      Ls02Pack p = clean();
      skillDoc(p, p.skills.trace)['masteryRequires'] = <String, Object?>{'successes': 4};
      refused(p, 'a trace node is practised, not mastered');
      p = clean();
      p.pack.pack.addDocument('gate.eng.oral.json', 'gates', 'eng.oral', <String, Object?>{
        'schema': 'gate/v1',
        'id': 'eng.oral',
        'course': 'eng',
        'requires': <Object?>[p.skills.trace],
        'holds': <Object?>[p.skills.write],
      });
      refused(p, 'a trace node is in the "requires" of a gate');
    });

    test('holds only intro and trace items: a copy or memory item belongs to the writing node', () {
      final Ls02Pack p = clean();
      doc(p, 'w01')['skills'] = <Object?>[
        <String, Object?>{'id': p.skills.trace, 'weight': 1},
      ];
      refused(p, 'a trace node holds only intro and trace items');
    });
  });

  group('a writing node', () {
    test('holds no trace item', () {
      final Ls02Pack p = clean();
      doc(p, 't02')['skills'] = <Object?>[
        <String, Object?>{'id': p.skills.write, 'weight': 1},
      ];
      refused(p, 'a writing node holds no trace item');
    });

    test('needs a memory item for each cue and for each letter', () {
      Ls02Pack p = clean();
      scene(p, 'w03')['cue'] = 'sound';
      refused(p, 'has no memory item cued by the name');
      p = clean();
      // A second letter that only has a copy item.
      p.add(
        letterJson(
          id: 'w04',
          skill: p.skills.write,
          mode: 'copy',
          forms: <String>['latin.a'],
          classify: p.classify(),
        ),
      );
      refused(p, 'the letter latin.a has no memory item');
    });

    test('every check and probe is a memory item', () {
      final Ls02Pack p = clean();
      doc(p, 'w01')['purpose'] = 'check';
      refused(p, 'every check and probe of a writing node is a memory item');
    });

    test('covers its letters, is no bundle member and asks for no representations', () {
      Ls02Pack p = clean();
      skillDoc(p, p.skills.write).remove('setCoverage');
      refused(p, 'a writing node covers its letters');
      p = clean();
      skillDoc(p, p.skills.write)['bundle'] = 'eng.g1';
      refused(p, 'a writing node is never in a bundle');
      p = clean();
      skillDoc(p, p.skills.write)['masteryRequires'] = <String, Object?>{'representations': 2};
      refused(p, 'is not read for a writing node');
    });

    test('needs the trace node of its group and the knowledge of its letters', () {
      Ls02Pack p = clean();
      skillDoc(p, p.skills.write)['prerequisites'] = <Object?>[
        <String, Object?>{'skill': p.skills.facet, 'weight': 0.8},
      ];
      refused(p, 'a writing node needs the trace node of its group');
      p = clean();
      skillDoc(p, p.skills.write)['prerequisites'] = <Object?>[
        <String, Object?>{'skill': p.skills.trace, 'weight': 0.8},
      ];
      refused(p, 'a writing node needs the knowledge skill of its letters');
    });
  });

  group('E-2: new letters over the visits', () {
    Ls02Pack manyIntros(String course, int n) {
      final Ls02Pack p = clean(course: course);
      final List<String> forms = course == 'heb'
          ? <String>['mem', 'lamed', 'shin', 'resh']
          : <String>['s', 'a', 't', 'p'];
      final List<Object?> ids = <Object?>['$course.n01'];
      for (int i = 2; i <= n; i++) {
        final String id = 'n0$i';
        p.add(
          letterJson(
            course: course,
            id: id,
            skill: p.skills.trace,
            mode: 'intro',
            forms: <String>[p.form(forms[i - 1])],
            intro: introData(course, forms[i - 1]),
          ),
        );
        ids.add('$course.$id');
        p.add(
          letterJson(
            course: course,
            id: 'u0$i',
            skill: p.skills.trace,
            mode: 'trace',
            guide: 'start',
            forms: <String>[p.form(forms[i - 1])],
            classify: p.classify(),
          ),
        );
        ids.add('$course.u0$i');
      }
      p.pack.pack.doc('lesson.$course.one.json')['items'] = ids;
      return p;
    }

    test('a Hebrew visit introduces at most 2 letters, the others 3', () {
      expect(check(manyIntros('heb', 2)), isEmpty);
      refused(manyIntros('heb', 3), 'introduces 3 letters: at most 2 a visit in the heb course');
      expect(check(manyIntros('eng', 3)), isEmpty);
      refused(manyIntros('eng', 4), 'introduces 4 letters: at most 3 a visit in the eng course');
    });

    test('a visit that introduces letters counts the bundle as one of its 2 new skills', () {
      // The facet and the trace node are two skills but one bundle: with the writing node that is two new skills, the limit.
      final Ls02Pack q = clean();
      q.pack.pack.doc('lesson.eng.one.json')['skills'] = <Object?>[
        q.skills.trace,
        q.skills.facet,
        q.skills.write,
      ];
      expect(check(q).where((Problem x) => x.toString().contains('new skills')), isEmpty);
      // A third new skill in the same visit is too many.
      final Ls02Pack p = clean();
      p.pack.pack.doc('lesson.eng.one.json')['skills'] = <Object?>[
        p.skills.trace,
        p.skills.write,
        'ENG-A-02',
      ];
      refused(p, 'starts 3 new skills');
    });

    test('an item of a letter comes only in or after the visit of its introduction', () {
      final Ls02Pack p = clean();
      p.pack.pack.doc('lesson.eng.one.json')['sequence'] = 3;
      refused(p, 'writes latin.s before the visit that introduces it');
    });
  });
}
