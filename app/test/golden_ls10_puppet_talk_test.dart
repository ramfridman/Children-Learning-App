// Goldens of LS10 on the four boards, on the lesson screen with the companion, the bubble and the trail: the answer bubbles of a puppet's
// turn (English from the left, Hebrew from the right), a personal turn about the age (three number cards and the pass), and a personal
// turn about the family at the most cards the template takes (eight and the pass). Fixture course, fake clips and the approved pictures;
// the Hebrew prompts are samples (needs-editor).
//
// Regenerate after a deliberate visual change:  flutter test --update-goldens test/golden_ls10_puppet_talk_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/golden_comparator.dart';
import 'support/harness.dart';
import 'support/l4_golden.dart';
import 'support/language_content.dart';

const List<String> _pictures = <String>[
  'cat',
  'dog',
  'duck',
  'book',
  'apple',
  'banana',
  'bread',
  'ball',
  'drum',
  'kite',
  'hat',
];

Map<String, Object?> _card(String id, {String? asset, int? numeral, required String c}) => <String, Object?>{
  'id': id,
  'label': asset ?? '$numeral',
  'sprite': ?(asset == null ? null : 'asset:$asset'),
  'numeral': ?numeral,
  'clip': 'vo:$c.card.$id',
};

LangPack _bubbles(String course) {
  final LangPack p = LangPack(course)..addPictures(_pictures);
  p.add(
    puppetJson(
      course: course,
      id: 'talk',
      mode: 'bubble',
      key: <String, Object?>{'at': at(0.2, 0.1, 0.5, 0.5)},
      options: <Map<String, Object?>>[
        pictureOption('o1', 'duck', clip: 'vo:$course.b.hello'),
        pictureOption('o2', 'dog', tag: p.tag('lis.sem'), clip: 'vo:$course.b.bye'),
        pictureOption('o3', 'book', tag: p.tag('lis.guess'), clip: 'vo:$course.b.yes'),
      ],
      correct: 'o1',
    ),
  );
  return p;
}

LangPack _age() {
  final LangPack p = LangPack()..addPictures(_pictures);
  p.add(
    puppetJson(
      id: 'mine',
      mode: 'personal',
      topic: 'age',
      options: <Map<String, Object?>>[
        _card('o1', numeral: 3, c: 'eng'),
        _card('o2', numeral: 4, c: 'eng'),
        _card('o3', numeral: 5, c: 'eng'),
      ],
    ),
  );
  return p;
}

LangPack _family() {
  final LangPack p = LangPack('heb')..addPictures(_pictures);
  p.add(
    puppetJson(
      course: 'heb',
      id: 'mine',
      mode: 'personal',
      topic: 'family',
      options: <Map<String, Object?>>[
        for (final (int i, String a) in <String>[
          'cat',
          'dog',
          'duck',
          'book',
          'apple',
          'banana',
          'bread',
          'ball',
        ].indexed)
          _card('o${i + 1}', asset: a, c: 'heb'),
      ],
    ),
  );
  return p;
}

void main() {
  setUpAll(() async {
    await loadAppFonts();
    useTolerantGoldens(0.03);
  });

  for (final MapEntry<String, Size> b in boards.entries) {
    group(b.key, () {
      testWidgets('the answer bubbles of a puppet\'s turn', (WidgetTester t) async {
        await openLesson(t, _bubbles('eng'), 'talk', b.value);
        await shot(t, 'ls10_bubbles', b.key);
      });

      testWidgets('the answer bubbles of a Hebrew puppet, from the right', (WidgetTester t) async {
        await openLesson(t, _bubbles('heb'), 'talk', b.value);
        await shot(t, 'ls10_bubbles_heb', b.key);
      });

      testWidgets('a personal turn about the age: number cards and the pass', (WidgetTester t) async {
        await openLesson(t, _age(), 'mine', b.value);
        await shot(t, 'ls10_personal_age', b.key);
      });

      testWidgets('a personal turn about the family, at the most cards', (WidgetTester t) async {
        await openLesson(t, _family(), 'mine', b.value);
        await shot(t, 'ls10_personal_family', b.key);
      });
    });
  }
}
