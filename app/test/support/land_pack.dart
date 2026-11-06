import 'package:nitznutz/content/models.dart';

import 'sample_pack.dart';

/// A land of the Counting Hills with [a], [b] and [c] lessons in Bands A, B and C, for the tests of the path and of the warm-up. Every
/// lesson teaches one skill (`NUM-A-01`, ...), which stands on the skill of the lesson before it, and has [itemsPerLesson] activities of
/// rising difficulty. Lesson ids are `a1` ... `b1` ... `c1` ..., and an activity is `<lesson>.<k>`. Not real content.
PackContent landPack({int a = 9, int b = 9, int c = 9, int itemsPerLesson = 2}) {
  final SamplePack p = SamplePack();
  final Map<String, Object?> skillDoc = p.docs[skillFile]! as Map<String, Object?>;
  final Map<String, Object?> lessonDoc = p.docs[lessonFile]! as Map<String, Object?>;
  final Map<String, Object?> activityDoc = p.docs[tapFile]! as Map<String, Object?>;
  p.docs
    ..remove(skillFile)
    ..remove(skill2File)
    ..remove(lessonFile)
    ..remove(tapFile)
    ..remove(countFile)
    ..remove(giveFile);
  (p.manifest['entries']! as Map<String, Object?>)
    ..['activities'] = <Object?>[]
    ..['lessons'] = <Object?>[]
    ..['skills'] = <Object?>[];
  String? previous;
  int sequence = 0;
  for (final (String band, int count) in <(String, int)>[('A', a), ('B', b), ('C', c)]) {
    for (int i = 1; i <= count; i++) {
      final String lesson = '${band.toLowerCase()}$i';
      final String skill = 'NUM-$band-${i.toString().padLeft(2, '0')}';
      sequence++;
      p.addDocument(
        'skill.$skill.json',
        'skills',
        skill,
        Map<String, Object?>.of(skillDoc)
          ..['id'] = skill
          ..['band'] = band
          ..['prerequisites'] = <Object?>[
            if (previous != null) <String, Object?>{'skill': previous, 'weight': 0.8},
          ],
      );
      final List<String> items = <String>[for (int k = 1; k <= itemsPerLesson; k++) '$lesson.$k'];
      for (final (int k, String id) in items.indexed) {
        p.addDocument(
          'activity.$id.json',
          'activities',
          id,
          Map<String, Object?>.of(activityDoc)
            ..['id'] = id
            ..['band'] = band
            ..['skills'] = <Object?>[
              <String, Object?>{'id': skill, 'weight': 1},
            ]
            ..['difficulty'] = <String, Object?>{'authored': 0.1 + 0.8 * k / (itemsPerLesson + 1)},
        );
      }
      p.addDocument(
        'lesson.$lesson.json',
        'lessons',
        lesson,
        Map<String, Object?>.of(lessonDoc)
          ..['id'] = lesson
          ..['band'] = band
          ..['skills'] = <Object?>[skill]
          ..['items'] = items
          ..['sequence'] = sequence,
      );
      previous = skill;
    }
  }
  return PackContent.fromPack(p.verified());
}
