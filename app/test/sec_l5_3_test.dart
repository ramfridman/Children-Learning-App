// Security-engineer proof for SEC-L5-2 (L5-3 to L5-5 light review, 2026-11-07): the voice lines a borrowed hint screen names
// (`hints[].screen.results[].clip`, `hints[].screen.word.parts[].clip`, `.whole`, `.stretched`) must be checked against the pack's
// voice lines, as the same fields of a `change_part` or `blend_slide` activity are. Fails until `validatePack` checks them.
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/pack_validation.dart';
import 'package:nitznutz/content/schema.dart';

import 'support/l5_content.dart';
import 'support/language_content.dart';
import 'support/ls01_content.dart';

List<String> _messages(LangPack p) => <String>[
  for (final Problem x in validatePack(manifest: p.pack.manifest, docs: p.pack.docs, files: p.pack.files))
    '${x.path}: ${x.message}',
];

LangPack _pack() {
  final LangPack p = LangPack('heb')..addPictures(const <String>['cat', 'sun', 'fish']);
  p.addTag('dec.vowel_skip', 'diagnostic');
  p.addTag('dec.letter_mix', 'diagnostic');
  return p;
}

Map<String, Object?> _stem(LangPack p) => stemJson(
  course: 'heb',
  id: 'st1',
  stem: 'שָׁ',
  clip: 'vo:heb.st1.stem',
  options: <Map<String, Object?>>[
    pictureOption('o1', 'cat'),
    pictureOption('o2', 'sun', tag: p.tag('dec.vowel_skip')),
    pictureOption('o3', 'fish', tag: p.tag('dec.letter_mix')),
  ],
  correct: 'o1',
);

void main() {
  test('SEC-L5-2: a wheel a hint borrows may not name a voice line the pack does not have', () {
    final LangPack p = _pack();
    final Map<String, Object?> a = _stem(p);
    borrow(a, 2, <String, Object?>{
      'template': 'change_part',
      'frame': <String, Object?>{'text': 'ש_', 'slots': 1},
      'parts': <Object?>[
        <String, Object?>{'id': 'p1', 'slot': 0, 'text': 'ָ'},
        <String, Object?>{'id': 'p2', 'slot': 0, 'text': 'ִ'},
      ],
      'results': <Object?>[
        <String, Object?>{
          'parts': <String>['p1'],
          'text': 'שָ',
          'clip': 'vo:heb.no.such.line',
        },
      ],
    });
    p.add(a);
    expect(
      _messages(p).any((String m) => m.contains('hints[1].screen.results[0].clip')),
      isTrue,
      reason:
          'an unknown clip in a borrowed screen is refused like the same clip of a change_part activity; problems: ${_messages(p)}',
    );
  });

  test('SEC-L5-2: a slide a hint borrows may not name a voice line the pack does not have', () {
    final LangPack p = _pack();
    final Map<String, Object?> a = _stem(p);
    borrow(a, 3, <String, Object?>{
      'template': 'blend_slide',
      'word': <String, Object?>{
        'text': 'שָׁר',
        'whole': 'vo:heb.no.such.whole',
        'parts': <Object?>[
          <String, Object?>{'text': 'שָׁ', 'clip': 'vo:heb.no.such.part'},
          <String, Object?>{'text': 'ר'},
        ],
      },
    });
    p.add(a);
    final List<String> m = _messages(p);
    expect(m.any((String x) => x.contains('hints[2].screen.word.whole')), isTrue, reason: m.join('\n'));
    expect(
      m.any((String x) => x.contains('hints[2].screen.word.parts[0].clip')),
      isTrue,
      reason: m.join('\n'),
    );
  });
}
