// The new data of a language pack (docs/languages/frame.md section 3.3): the skill fields (bundle, set coverage, sound-right,
// letters) and the gate document, from the file to the engine, and the rules that keep them sound. Fixture course, not content.
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/engine_adapter.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/content/pack_validation.dart';
import 'package:nitznutz/content/schema.dart';
import 'package:nitznutz/content/schemas.dart';
import 'package:nitznutz/engine/course.dart';
import 'package:nitznutz/engine/gates.dart';
import 'package:nitznutz/engine/types.dart';

import 'support/sample_pack.dart';

const String _skill1 = 'skill.ENG-A-01.json';
const String _skill2 = 'skill.ENG-A-02.json';
const String _gateFile = 'gate.eng.oral.json';

List<Problem> _run(SamplePack p) => validatePack(manifest: p.manifest, docs: p.docs, files: p.files);

Map<String, Object?> _gate({
  List<Object?> requires = const <Object?>['ENG-A-01'],
  List<Object?> holds = const <Object?>['ENG-A-02'],
}) => <String, Object?>{
  'schema': 'gate/v1',
  'id': 'eng.oral',
  'course': 'eng',
  'requires': requires,
  'holds': holds,
  'neverUnderBand': 0,
  'durableBelowBand': 2,
  'parentSwitch': <String, Object?>{'name': 'oralOnly', 'effect': 'closes'},
};

/// The English fixture with the oral gate added.
SamplePack _withGate({Map<String, Object?>? gate}) {
  final SamplePack p = SamplePack.language('eng');
  p.addDocument(_gateFile, 'gates', 'eng.oral', gate ?? _gate());
  return p;
}

/// Another skill like `ENG-A-01` with the given id and fields.
void _addSkill(SamplePack p, String id, Map<String, Object?> fields) {
  final Map<String, Object?> doc = <String, Object?>{...p.doc(_skill1), 'id': id, ...fields};
  p.addDocument('skill.$id.json', 'skills', id, doc);
}

class Broken {
  const Broken(this.name, this.mutate, this.path, this.message);

  final String name;
  final void Function(SamplePack p) mutate;
  final String path;
  final String message;
}

final List<Broken> _cases = <Broken>[
  Broken(
    'a gate that requires a skill that is not in the pack',
    (SamplePack p) => p.docs[_gateFile] = _gate(requires: <Object?>['ENG-A-09']),
    'gate.eng.oral.json › skills',
    'the skill ENG-A-09 is not in this pack',
  ),
  Broken(
    'a gate that reaches into another course',
    (SamplePack p) => p.docs[_gateFile] = _gate(requires: <Object?>['ENG-A-01', 'RUS-A-01']),
    'gate.eng.oral.json › skills',
    'a gate never reaches into another course',
  ),
  Broken(
    'a gate of another course',
    (SamplePack p) => (p.docs[_gateFile]! as Map<String, Object?>)['course'] = 'rus',
    'gate.eng.oral.json › course',
    'a pack holds one course',
  ),
  Broken(
    'a gate whose id does not begin with its course',
    (SamplePack p) {
      final Map<String, Object?> old = p.docs.remove(_gateFile)! as Map<String, Object?>;
      p.files.remove(_gateFile);
      (p.manifest['files']! as List<Object?>).removeWhere(
        (Object? f) => (f! as Map<String, Object?>)['name'] == _gateFile,
      );
      ((p.manifest['entries']! as Map<String, Object?>)['gates']! as List<Object?>).clear();
      p.addDocument('gate.rus.oral.json', 'gates', 'rus.oral', <String, Object?>{...old, 'id': 'rus.oral'});
    },
    'gate.rus.oral.json › id',
    'must begin with "eng."',
  ),
  Broken(
    'a skill that is both required and held',
    (SamplePack p) => p.docs[_gateFile] = _gate(holds: <Object?>['ENG-A-01']),
    'gate.eng.oral.json › holds',
    'both required and held',
  ),
  Broken(
    'a gate that holds what it needs: it could never open',
    (SamplePack p) =>
        p.docs[_gateFile] = _gate(requires: <Object?>['ENG-A-02'], holds: <Object?>['ENG-A-01']),
    'gate.eng.oral.json › holds',
    'could never open',
  ),
  Broken(
    'a gate that holds a roll-up instead of its groups',
    (SamplePack p) {
      _addSkill(p, 'ENG-A-05', <String, Object?>{});
      _addSkill(p, 'ENG-A-05.G1', <String, Object?>{});
      p.docs[_gateFile] = _gate(holds: <Object?>['ENG-A-05']);
    },
    'gate.eng.oral.json › holds',
    'is a roll-up: hold its groups',
  ),
  Broken(
    'a quota that asks for more skills than it names',
    (SamplePack p) => (p.docs[_gateFile]! as Map<String, Object?>)['requireAtLeast'] = <Object?>[
      <String, Object?>{
        'skills': <Object?>['ENG-A-01', 'ENG-A-02'],
        'count': 3,
      },
    ],
    'gate.eng.oral.json › requireAtLeast',
    'asks for 3 skills out of 2',
  ),
  Broken(
    'a gate that the manifest does not list',
    (SamplePack p) => ((p.manifest['entries']! as Map<String, Object?>)['gates']! as List<Object?>).clear(),
    'manifest.json › entries.gates',
    '"eng.oral" is in the pack but not declared',
  ),
  Broken(
    'a bundle of a single facet',
    (SamplePack p) => p.doc(_skill1)['bundle'] = 'eng.g1',
    'skill.ENG-A-01.json › bundle',
    'has one',
  ),
  Broken(
    'a bundle of another course',
    (SamplePack p) {
      p.doc(_skill1)['bundle'] = 'rus.g1';
      p.doc(_skill2)['bundle'] = 'rus.g1';
    },
    'skill.ENG-A-01.json › bundle',
    'must begin with "eng."',
  ),
  Broken(
    'facets of a bundle that need each other',
    (SamplePack p) {
      p.doc(_skill1)['bundle'] = 'eng.g1';
      p.doc(_skill2)['bundle'] = 'eng.g1';
    },
    'skill.ENG-A-02.json › prerequisites',
    'cannot need another facet',
  ),
  Broken(
    'facets that need each other through a third skill',
    (SamplePack p) {
      _addSkill(p, 'ENG-A-03', <String, Object?>{
        'prerequisites': <Object?>[
          <String, Object?>{'skill': 'ENG-A-02', 'weight': 1},
        ],
        'bundle': 'eng.g1',
      });
      p.doc(_skill1)['bundle'] = 'eng.g1';
    },
    'skill.ENG-A-03.json › prerequisites',
    'cannot need another facet',
  ),
  Broken(
    'a bad value for the sound-right policy',
    (SamplePack p) => p.doc(_skill1)['soundRight'] = 'sometimes',
    'skill.ENG-A-01.json › soundRight',
    'must be one of accepts, teaches',
  ),
  Broken(
    'an unknown parent switch on a gate',
    (SamplePack p) =>
        ((p.docs[_gateFile]! as Map<String, Object?>)['parentSwitch']! as Map<String, Object?>)['name'] =
            'whatever',
    'gate.eng.oral.json › parentSwitch.name',
    'must be one of oralOnly, lettersBefore5',
  ),
];

void main() {
  group('the fixture with a gate and a bundle is valid', () {
    test('a gate, a bundle of two facets that do not need each other, and the four skill fields', () {
      final SamplePack p = _withGate();
      _addSkill(p, 'ENG-A-03', <String, Object?>{'bundle': 'eng.g1', 'letters': true});
      p.doc(_skill1)['bundle'] = 'eng.g1';
      p.doc(_skill1)['setCoverage'] = true;
      p.doc(_skill1)['soundRight'] = 'accepts';
      expect(_run(p), isEmpty);
    });
  });

  group('a broken gate or bundle is refused with the right path and reason', () {
    for (final Broken b in _cases) {
      test(b.name, () {
        final SamplePack p = _withGate();
        b.mutate(p);
        final List<Problem> ps = _run(p);
        expect(ps, isNotEmpty, reason: 'nothing was refused');
        expect(
          ps.where((Problem x) => x.path == b.path && x.message.contains(b.message)),
          isNotEmpty,
          reason: 'wanted "${b.path}: ${b.message}", got:\n${ps.join('\n')}',
        );
      });
    }
  });

  group('from the file to the engine', () {
    test('the skill fields become the engine\'s', () {
      final SamplePack p = _withGate();
      _addSkill(p, 'ENG-A-03', <String, Object?>{
        'bundle': 'eng.g1',
        'letters': true,
        'soundRight': 'accepts',
      });
      p.doc(_skill1)['bundle'] = 'eng.g1';
      p.doc(_skill1)['setCoverage'] = true;
      final Catalog c = engineCatalog(PackContent.fromPack(p.verified()));
      final SkillNode a1 = c.skills['ENG-A-01']!;
      final SkillNode a3 = c.skills['ENG-A-03']!;
      expect(
        <Object?>[a1.bundle, a1.setCoverage, a1.soundRight, a1.letters],
        <Object?>['eng.g1', true, SoundRightPolicy.teaches, false],
      );
      expect(
        <Object?>[a3.bundle, a3.setCoverage, a3.soundRight, a3.letters],
        <Object?>['eng.g1', false, SoundRightPolicy.accepts, true],
      );
      expect(c.bundles['eng.g1'], <String>['ENG-A-01', 'ENG-A-03']);
    });

    test('a skill without the new fields is as it was: no bundle, no coverage, strict, not letters', () {
      final SkillNode n = engineCatalog(PackContent.fromPack(SamplePack().verified())).skills.values.first;
      expect(
        <Object?>[n.bundle, n.setCoverage, n.soundRight, n.letters],
        <Object?>[null, false, SoundRightPolicy.teaches, false],
      );
    });

    test('the gate becomes the engine\'s gate', () {
      final PackContent content = PackContent.fromPack(_withGate().verified());
      expect(content.gates.keys, <String>['eng.oral']);
      final CourseGate g = courseGates(content).single;
      expect(g.id, 'eng.oral');
      expect(g.course, Course.eng);
      expect(g.requires, <String>{'ENG-A-01'});
      expect(g.holds, <String>{'ENG-A-02'});
      expect(g.neverUnderBand, 0);
      expect(g.durableBelowBand, 2);
      expect(g.switchName, 'oralOnly');
      expect(g.switchEffect, SwitchEffect.closes);
      expect(gateSwitchNames, contains(g.switchName));
      final GateResult closed = gateResult(
        g,
        const GateInput(mastery: <String, MasteryLevel>{}, ageBand: 1, presentationBand: 1),
      );
      expect(closed.open, isFalse);
      expect(closed.missing, <String>['ENG-A-01']);
      expect(
        gateResult(
          g,
          const GateInput(
            mastery: <String, MasteryLevel>{'ENG-A-01': MasteryLevel.durable},
            ageBand: 1,
            presentationBand: 1,
          ),
        ).open,
        isTrue,
      );
    });

    test('a pack of the lands has no gates', () {
      expect(PackContent.fromPack(SamplePack().verified()).gates, isEmpty);
    });
  });
}
