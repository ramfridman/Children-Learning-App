// Goldens of the rest of LS01 (L5-1) on the four boards, on the lesson screen with the companion, the bubble and the trail: the text stem,
// the cloze, the tap-all, the sort with text faces and with sound cards, the pairs played one at a time, the spot row, the order tiles and
// the story line, in English and in Hebrew (the Russian pairs too), at Band B. On the phone SE also the longest texts the fit check allows.
// Fixture course, fake clips and the approved pictures; the Hebrew prompts and every word are samples (needs-editor, and for their teachers).
//
// Regenerate after a deliberate visual change:  flutter test --update-goldens test/golden_ls01_rest_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nitznutz/design/token_types.dart';
import 'package:nitznutz/play/ls01_fit.dart';

import 'support/golden_comparator.dart';
import 'support/harness.dart';
import 'support/l4_golden.dart';
import 'support/language_content.dart';
import 'support/ls01_content.dart';

const List<String> _pictures = <String>[
  'cat',
  'dog',
  'duck',
  'place-dog-on-chair',
  'story-bounce-1',
  'story-bounce-2',
  'story-bounce-3',
];

/// The words of a course for the fixtures: English and Hebrew (pointed) and Russian.
class _W {
  const _W(
    this.stem,
    this.cloze,
    this.clozeOptions,
    this.letters,
    this.signs,
    this.cards,
    this.pairLeft,
    this.cells,
    this.row,
    this.order,
  );

  final String stem;
  final String cloze;
  final List<String> clozeOptions;
  final List<String> letters;
  final List<String> signs;
  final List<String> cards;
  final List<String> pairLeft;
  final List<String> cells;
  final List<String> row;
  final List<String> order;
}

const _W _eng = _W(
  'cat',
  'The dog is _ the chair.',
  <String>['on', 'in', 'at'],
  <String>['t', 'i', 't', 'f', 't'],
  <String>['a', 'i'],
  <String>['pan', 'pin', 'nap', 'sit'],
  <String>['s', 't', 'p'],
  <String>['c', 'a', 'p'],
  <String>['s', 'a'],
  <String>['t', 'p', 'n'],
);
const _W _heb = _W(
  'כֶּלֶב',
  'הַכֶּלֶב _ שָׁם.',
  <String>['יָשַׁב', 'רָץ', 'נָח'],
  <String>['מ', 'ל', 'מ', 'ר', 'מ'],
  <String>['מ', 'ל'],
  <String>['מַפָּה', 'לֶחֶם', 'מִטְרִיָּה', 'לִימוֹן'],
  <String>['מ', 'ל', 'ר'],
  <String>['ב', 'א', 'ג'],
  <String>['א', 'ב'],
  <String>['ג', 'ד', 'ה'],
);
const _W _rus = _W(
  'кот',
  'Собака _ на стуле.',
  <String>['сидит', 'спит', 'бежит'],
  <String>['м', 'а', 'м', 'о', 'м'],
  <String>['а', 'у'],
  <String>['мама', 'мак', 'утка', 'ухо'],
  <String>['А', 'У', 'О'],
  <String>['м', 'а', 'л'],
  <String>['м', 'а'],
  <String>['л', 'н', 'р'],
);

_W _words(String course) => switch (course) {
  'heb' => _heb,
  'rus' => _rus,
  _ => _eng,
};

LangPack _base(String course) => LangPack(course)..addPictures(_pictures);

Map<String, LangPack Function(String)> _modes = <String, LangPack Function(String)>{
  'stem': (String c) {
    final LangPack p = _base(c);
    p.add(
      stemJson(
        course: c,
        id: 'x',
        band: 'B',
        stem: _words(c).stem,
        clip: 'vo:$c.stem',
        options: <Map<String, Object?>>[
          pictureOption('o1', 'cat', clip: 'vo:$c.w.cat'),
          pictureOption('o2', 'dog', tag: p.tag('lis.sem'), clip: 'vo:$c.w.dog'),
          pictureOption('o3', 'duck', tag: p.tag('lis.guess'), clip: 'vo:$c.w.duck'),
        ],
        correct: 'o1',
      ),
    );
    return p;
  },
  'cloze': (String c) {
    final LangPack p = _base(c);
    final _W w = _words(c);
    p.add(
      clozeJson(
        course: c,
        id: 'x',
        band: 'B',
        text: w.cloze,
        picture: 'place-dog-on-chair',
        options: <Map<String, Object?>>[
          textOption('o1', w.clozeOptions[0]),
          textOption('o2', w.clozeOptions[1], tag: p.tag('lis.sem')),
          textOption('o3', w.clozeOptions[2], tag: p.tag('lis.guess')),
        ],
        correct: 'o1',
      ),
    );
    return p;
  },
  'tapall': (String c) {
    final LangPack p = _base(c);
    final _W w = _words(c);
    p.add(
      tapAllJson(
        course: c,
        id: 'x',
        band: 'B',
        face: 'letter',
        options: <Map<String, Object?>>[
          for (final (int i, String l) in w.letters.indexed)
            textOption('o${i + 1}', l, tag: l == w.letters.first ? null : p.tag('lis.sem')),
        ],
        correct: <String>[
          for (final (int i, String l) in w.letters.indexed)
            if (l == w.letters.first) 'o${i + 1}',
        ],
      ),
    );
    return p;
  },
  'sort': (String c) {
    final LangPack p = _base(c);
    final _W w = _words(c);
    p.add(
      sortJson(
        course: c,
        id: 'x',
        band: 'B',
        bins: <Map<String, Object?>>[
          sortFace('b1', text: w.signs[0], clip: 'vo:$c.sign.1'),
          sortFace('b2', text: w.signs[1]),
        ],
        items: <Map<String, Object?>>[
          for (final (int i, String card) in w.cards.indexed)
            sortFace('i${i + 1}', text: card, bin: i.isEven ? 'b1' : 'b2', tag: p.tag('lis.sem')),
        ],
      ),
    );
    return p;
  },
  'sounds': (String c) {
    final LangPack p = _base(c);
    p.add(
      sortJson(
        course: c,
        id: 'x',
        band: 'B',
        bins: <Map<String, Object?>>[
          sortFace('b1', picture: 'cat'),
          sortFace('b2', picture: 'dog'),
        ],
        items: <Map<String, Object?>>[
          sortFace('i1', clip: 'vo:$c.s.1', bin: 'b1'),
          sortFace('i2', clip: 'vo:$c.s.2', bin: 'b2'),
          sortFace('i3', clip: 'vo:$c.s.3', bin: 'b1'),
        ],
        tag: p.tag('lis.sem'),
      ),
    );
    return p;
  },
  'pairs': (String c) {
    final LangPack p = _base(c);
    final _W w = _words(c);
    p.add(
      pairsJson(
        course: c,
        id: 'x',
        band: 'B',
        left: <Map<String, Object?>>[
          for (final (int i, String l) in w.pairLeft.indexed)
            pairFace('l${i + 1}', text: l, clip: 'vo:$c.l.${i + 1}'),
        ],
        right: <Map<String, Object?>>[
          for (int i = 0; i < w.pairLeft.length; i++)
            pairFace('r${i + 1}', clip: 'vo:$c.n.${i + 1}', tag: p.tag('lis.sem')),
        ],
        pairs: <String, String>{for (int i = 0; i < w.pairLeft.length; i++) 'l${i + 1}': 'r${i + 1}'},
      ),
    );
    return p;
  },
  'spot': (String c) {
    final LangPack p = _base(c);
    p.add(
      spotJson(
        course: c,
        id: 'x',
        band: 'B',
        cells: <String>[for (final String l in _words(c).cells) 'txt:$l'],
        wrong: 2,
        model: 'cat',
        modelClip: 'vo:$c.cat',
        tag: p.tag('lis.sem'),
      ),
    );
    return p;
  },
  'order': (String c) {
    final LangPack p = _base(c);
    final _W w = _words(c);
    p.add(
      orderJson(
        course: c,
        id: 'x',
        band: 'B',
        model: <String>[for (final String l in w.row) 'txt:$l'],
        palette: <String>[for (final String l in w.order) 'txt:$l'],
        sequence: <String>['txt:${w.order[0]}', 'txt:${w.order[1]}'],
        tag: p.tag('lis.sem'),
      ),
    );
    return p;
  },
  'story': (String c) {
    final LangPack p = _base(c);
    p.add(
      sequenceJson(
        course: c,
        id: 'x',
        band: 'B',
        palette: <String>['asset:story-bounce-2', 'asset:story-bounce-3', 'asset:story-bounce-1'],
        order: <int>[2, 0, 1],
        tag: p.tag('lis.sem'),
      ),
    );
    return p;
  },
};

/// The lesson on the screen, after the fit check has passed the item: a golden shows content that fits, never a text the check refuses.
Future<void> _open(WidgetTester t, LangPack p, Size size, {List<Band>? bands}) async {
  final List<String> problems = ls01FitProblems(p.content.activities['${p.course}.x']!, bands: bands);
  expect(problems, isEmpty, reason: problems.join(', '));
  await openLesson(t, p, 'x', size);
}

void main() {
  setUpAll(() async {
    await loadAppFonts();
    useTolerantGoldens(0.03);
  });

  for (final MapEntry<String, Size> b in boards.entries) {
    group(b.key, () {
      for (final String course in <String>['eng', 'heb']) {
        for (final MapEntry<String, LangPack Function(String)> m in _modes.entries) {
          testWidgets('${m.key} in $course', (WidgetTester t) async {
            await _open(t, m.value(course), b.value);
            await shot(t, 'ls01r_${m.key}_$course', b.key);
          });
        }
      }

      testWidgets('pairs in Russian', (WidgetTester t) async {
        await _open(t, _modes['pairs']!('rus'), b.value);
        await shot(t, 'ls01r_pairs_rus', b.key);
      });

      testWidgets('a sort with a card in a bin: the kept chip', (WidgetTester t) async {
        await _open(t, _modes['sort']!('eng'), b.value);
        await t.tap(find.byKey(const Key('tile-i1')));
        await waitFor(t, 100);
        await t.tap(find.byKey(const Key('bin-b1')));
        await shot(t, 'ls01r_sort_kept_eng', b.key, wait: 400);
      });

      testWidgets('a tap-all with two cards picked', (WidgetTester t) async {
        await _open(t, _modes['tapall']!('heb'), b.value);
        await t.tap(find.byKey(const Key('tile-o1')));
        await t.tap(find.byKey(const Key('tile-o3')));
        await shot(t, 'ls01r_tapall_picked_heb', b.key, wait: 400);
      });

      testWidgets('hint 3 of a stem: the hand on the right picture', (WidgetTester t) async {
        await _open(t, _modes['stem']!('eng'), b.value);
        for (int k = 0; k < 3; k++) {
          await t.tap(find.byKey(const Key('lesson-hint')));
          await waitFor(t, 250);
        }
        await shot(t, 'ls01r_hand_stem_eng', b.key, wait: 900);
      });

      testWidgets('a cloze with the word in the gap', (WidgetTester t) async {
        await _open(t, _modes['cloze']!('eng'), b.value);
        await t.tap(find.byKey(const Key('tile-o2')));
        await shot(t, 'ls01r_cloze_gap_eng', b.key, wait: 200);
      });

      testWidgets('a story line with the first picture set', (WidgetTester t) async {
        await _open(t, _modes['story']!('heb'), b.value);
        await t.tap(find.byKey(const Key('place-2')));
        await shot(t, 'ls01r_story_set_heb', b.key, wait: 400);
      });
    });
  }

  // The longest texts the fit check allows, on the phone SE.
  group('the longest texts on the phone SE', () {
    final Size se = boards['phoneSE']!;
    testWidgets('four words of 2 em in the options of a stem', (WidgetTester t) async {
      final LangPack p = _base('eng');
      p.add(
        stemJson(
          course: 'eng',
          id: 'x',
          band: 'B',
          stem: 'a cat on a mat',
          clip: 'vo:eng.stem',
          options: <Map<String, Object?>>[
            textOption('o1', 'cat'),
            textOption('o2', 'map', tag: p.tag('lis.sem')),
            textOption('o3', 'pig', tag: p.tag('lis.guess')),
            textOption('o4', 'dog', tag: p.tag('lis.guess')),
          ],
          correct: 'o1',
          answer: <String, Object?>{'face': 'word'},
        ),
      );
      await _open(t, p, se);
      await shot(t, 'ls01r_longest_stem_eng', 'phoneSE');
    });

    for (final (String course, String text) in <(String, String)>[
      ('eng', 'A big dog is _ the red chair.'),
      ('heb', 'הַכֶּלֶב _ עַל הַכִּסֵּא.'),
    ]) {
      testWidgets('a cloze sentence at the most lines in $course', (WidgetTester t) async {
        final LangPack p = _base(course);
        final _W w = _words(course);
        p.add(
          clozeJson(
            course: course,
            id: 'x',
            band: 'B',
            text: text,
            picture: 'place-dog-on-chair',
            options: <Map<String, Object?>>[
              textOption('o1', w.clozeOptions[0]),
              textOption('o2', w.clozeOptions[1], tag: p.tag('lis.sem')),
              textOption('o3', w.clozeOptions[2], tag: p.tag('lis.guess')),
            ],
            correct: 'o1',
          ),
        );
        await _open(t, p, se, bands: <Band>[Band.b, Band.c]);
        await shot(t, 'ls01r_longest_cloze_$course', 'phoneSE');
      });
    }
  });
}
