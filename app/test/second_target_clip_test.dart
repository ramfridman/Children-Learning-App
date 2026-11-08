// A spoken line of a language course is one Hebrew clip and then one or two target-language clips (`target`, `target2`): a question and its
// answer ("What's this?" "It's a cat."), or the two sounds of a same-or-different item. And a misconception document may list the skills of
// a whole course, up to 60 (eng.lis.sem names 12 skills of Band A alone).
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/content/pack_validation.dart';
import 'package:nitznutz/content/schema.dart';
import 'package:nitznutz/content/schemas.dart';

import 'support/language_content.dart';

List<String> _messages(LangPack p) => <String>[
  for (final Problem x in validatePack(manifest: p.pack.manifest, docs: p.pack.docs, files: p.pack.files))
    '${x.path}: ${x.message}',
];

LangPack _tapWithPrompt(Map<String, Object?> extra) {
  final LangPack p = LangPack('eng')..addPictures(<String>['cat', 'dog', 'duck']);
  final Map<String, Object?> doc = tapJson(
    id: 'ask',
    options: <Map<String, Object?>>[
      pictureOption('o1', 'cat'),
      pictureOption('o2', 'dog', tag: p.tag('lis.sem')),
      pictureOption('o3', 'duck', tag: p.tag('lis.guess')),
    ],
    correct: 'o1',
    target: 'vo:eng.ask.q',
  );
  (doc['prompt']! as Map<String, Object?>).addAll(extra);
  p.add(doc);
  return p;
}

void main() {
  group('the second target clip of a spoken line', () {
    test('a prompt of a question and its answer is valid and reads as two clips after the Hebrew one', () {
      final LangPack p = _tapWithPrompt(<String, Object?>{'target2': 'vo:eng.ask.a'});
      expect(_messages(p), isEmpty);
      final Spoken line = (p.content.activities['eng.ask']! as TapAnswerActivity).promptLine;
      expect((line.target, line.target2), ('vo:eng.ask.q', 'vo:eng.ask.a'));
    });

    test('a second clip with no first one is refused', () {
      final LangPack p = _tapWithPrompt(<String, Object?>{'target2': 'vo:eng.ask.a'});
      (p.activity('ask')['prompt']! as Map<String, Object?>).remove('target');
      expect(
        _messages(p).join('\n'),
        contains('prompt.target2: is the clip after `target`: the line has no `target`'),
      );
    });

    test('a second clip the pack has no line for is refused', () {
      final LangPack p = _tapWithPrompt(<String, Object?>{'target2': 'vo:eng.ask.a'});
      (p.pack.manifest['voPending']! as List<Object?>).remove('vo:eng.ask.a');
      expect(_messages(p).join('\n'), contains('prompt.target2'));
    });
  });

  group('a misconception document lists the skills of a course', () {
    Map<String, Object?> tag(int skills) => <String, Object?>{
      'schema': 'misconception/v1',
      'id': 'eng.lis.sem',
      'course': 'eng',
      'kind': 'diagnostic',
      'family': 'MEANING',
      'skills': <Object?>[for (int i = 1; i <= skills; i++) 'ENG-A-${i.toString().padLeft(2, '0')}'],
      'parentText': 'The child is still learning this word.',
      'repairActivities': <Object?>[],
      'preferredRepresentations': <Object?>['pictorial'],
    };

    test('12 skills (eng.lis.sem) and 60 are accepted', () {
      expect(validate(misconceptionSchema, tag(12)), isEmpty);
      expect(validate(misconceptionSchema, tag(60)), isEmpty);
    });

    test('61 are refused, and none is refused', () {
      expect(validate(misconceptionSchema, tag(61)), isNotEmpty);
      expect(validate(misconceptionSchema, tag(0)), isNotEmpty);
    });
  });
}
