// The letters gates as the course packs will carry them (docs/languages/frame.md section 3.3.6, L7-8). No letter content is in the packs yet
// (Band B is not built), and a gate may name only skills of its own pack, so these documents ship with the letter batches (L5); until
// then they are fixtures here: each is validated by the real pack validator on a fixture course that has its skills, and read into the
// engine's gate by the real adapter, so the file, the adapter and the rules are proven together.
import 'package:nitznutz/content/engine_adapter.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/content/pack_validation.dart';
import 'package:nitznutz/content/schema.dart' show Problem;
import 'package:nitznutz/engine/gates.dart';

import 'language_content.dart';
import 'sample_pack.dart';

List<String> _ids(String prefix, String band, Iterable<int> numbers) => <String>[
  for (final int n in numbers) '$prefix-$band-${n.toString().padLeft(2, '0')}',
];

/// The English early set: A-01 to A-05, A-08 and A-09 (the English teacher, 2026-11-14).
final List<String> engEarly = <String>[
  ..._ids('ENG', 'A', <int>[1, 2, 3, 4, 5, 8, 9]),
];

/// The English oral gate (syllabus 6.2): the stage 1-2 listening core and the onset-rime skills; it holds B-16 to B-23 (the letters).
final Map<String, Object?> engOralGate = <String, Object?>{
  'schema': 'gate/v1',
  'id': 'eng.oral',
  'course': 'eng',
  'requires': <String>[
    ..._ids('ENG', 'A', <int>[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 16]),
    ..._ids('ENG', 'B', <int>[1, 2, 5, 6, 12, 13, 14]),
  ],
  'holds': _ids('ENG', 'B', <int>[16, 17, 18, 19, 20, 21, 22, 23]),
  'minAge': 5,
  'durableBelowAge': 7,
  'early': <String, Object?>{'requires': engEarly},
  'parentSwitch': <String, Object?>{'name': 'oralOnly', 'effect': 'closes'},
};

/// The Russian themes the sounds gate already counts (A-02, A-05 to A-09).
final List<String> rusThemes = <String>[
  ..._ids('RUS', 'A', <int>[2, 5, 6, 7, 8, 9]),
];

/// The Russian letters gate (D17): A-12 and three themes, age 5; the early set is A-12 and one theme (the Russian teacher, 2026-11-14).
final Map<String, Object?> rusLettersGate = <String, Object?>{
  'schema': 'gate/v1',
  'id': 'rus.letters',
  'course': 'rus',
  'requires': <String>['RUS-A-12'],
  'requireAtLeast': <Object?>[
    <String, Object?>{'skills': rusThemes, 'count': 3},
  ],
  'holds': _ids('RUS', 'B', <int>[18, 19, 20, 21]),
  'minAge': 5,
  'early': <String, Object?>{
    'requires': <String>['RUS-A-12'],
    'requireAtLeast': <Object?>[
      <String, Object?>{'skills': rusThemes, 'count': 1},
    ],
  },
  'parentSwitch': <String, Object?>{'name': 'lettersBefore5', 'effect': 'opens'},
  'routeBypass': <String>['heritage', 'reader'],
};

/// The Hebrew letters gate: age 5, no skill, it holds B-14 to B-28 (syllabus 9). A Hebrew-speaking child has the words: no early set.
final Map<String, Object?> hebLettersGate = <String, Object?>{
  'schema': 'gate/v1',
  'id': 'heb.letters',
  'course': 'heb',
  'requires': <String>[],
  'holds': _ids('HEB', 'B', <int>[for (int n = 14; n <= 28; n++) n]),
  'minAge': 5,
};

/// A fixture course with its letters gate and every skill the gate names (the held ones are letter work).
class LetterGatePack {
  LetterGatePack._(this.course, this.pack, this.gateId);

  factory LetterGatePack(String course) {
    final Map<String, Object?> gate = switch (course) {
      'eng' => engOralGate,
      'rus' => rusLettersGate,
      _ => hebLettersGate,
    };
    final LangPack lp = LangPack(course);
    final SamplePack p = lp.pack;
    final String up = course.toUpperCase();
    final Set<String> named = <String>{
      ...(gate['requires']! as List<String>),
      ...(gate['holds']! as List<String>),
      for (final Object? q in (gate['requireAtLeast'] as List<Object?>?) ?? const <Object?>[])
        ...((q! as Map<String, Object?>)['skills']! as List<String>),
      ...((gate['early'] as Map<String, Object?>?)?['requires'] as List<String>? ?? const <String>[]),
    };
    for (final String id in named) {
      if (p.docs.containsKey('skill.$id.json')) continue;
      p.addDocument('skill.$id.json', 'skills', id, <String, Object?>{
        ...p.doc('skill.$up-A-01.json'),
        'id': id,
        'band': id.split('-')[1],
        if ((gate['holds']! as List<String>).contains(id)) 'letters': true,
      });
    }
    p.addDocument('gate.${gate['id']}.json', 'gates', gate['id']! as String, gate);
    return LetterGatePack._(course, p, gate['id']! as String);
  }

  final String course;
  final SamplePack pack;
  final String gateId;

  /// What the real validator says about the pack: nothing, when the gate document is sound.
  List<Problem> get problems => validatePack(manifest: pack.manifest, docs: pack.docs, files: pack.files);

  PackContent get content => PackContent.fromPack(pack.verified());

  /// The engine's gate, read from the document by the real adapter.
  CourseGate get gate => courseGates(content).single;
}
