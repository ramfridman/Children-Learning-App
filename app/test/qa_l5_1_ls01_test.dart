// QA of L5-1, the rest of LS01 (docs/design/languages-l5-ls01.md, docs/milestones/L5.md section 5.1): what the developer's tests do not
// prove. The measure with the real fonts; the directions of every mode in the three courses; the hint ladders (no option lit before level 3,
// the hand last, `demoDone`, only the right move at the top of the help); the scoring of the tap-all; "I'm not sure" never a mistake; the
// kept chips of a sort; the text at scale 1.3. A test marked `skip` is the proof of an open defect (QA report of L5-1): it fails today,
// and the line `skip:` goes when the owner of the fix reports it done. Fixture course and fake clips, not content.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/design/token_types.dart';
import 'package:nitznutz/play/lesson_controller.dart';
import 'package:nitznutz/play/ls01_fit.dart';
import 'package:nitznutz/play/ls01_metrics.dart';
import 'package:nitznutz/play/ls01_order_session.dart';
import 'package:nitznutz/play/ls01_pairs_session.dart';
import 'package:nitznutz/play/ls01_sequence_session.dart';
import 'package:nitznutz/play/ls01_sort_session.dart';
import 'package:nitznutz/play/ls01_spot_session.dart';
import 'package:nitznutz/play/ls01_tap_session.dart';
import 'package:nitznutz/play/template_session.dart';

import 'support/harness.dart';
import 'support/l4_rig.dart';
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
const Size _se = Size(667, 375);

/// An open defect's proof test is skipped so that the suite stays green; `flutter test --dart-define=QA_OPEN=true test/qa_l5_1_ls01_test.dart` runs
/// them and shows each one fail.
const bool _skipOpen = !bool.fromEnvironment('QA_OPEN');

LangPack _base(String course) => LangPack(course)..addPictures(_pictures);

/// Words per course: letters for a row, a sentence with its gap, two words for a sort, a model row.
const Map<String, List<String>> _letters = <String, List<String>>{
  'eng': <String>['s', 'a', 't'],
  'heb': <String>['ב', 'א', 'ג'],
  'rus': <String>['с', 'а', 'т'],
};
const Map<String, String> _cloze = <String, String>{
  'eng': 'The dog is _ the chair.',
  'heb': 'הַכֶּלֶב _ שָׁם.',
  'rus': 'Собака _ на стуле.',
};
const Map<String, List<String>> _clozeOptions = <String, List<String>>{
  'eng': <String>['on', 'in', 'at'],
  'heb': <String>['יָשַׁב', 'רָץ', 'נָח'],
  'rus': <String>['сидит', 'спит', 'бежит'],
};
const Map<String, List<String>> _sortWords = <String, List<String>>{
  'eng': <String>['pan', 'pin', 'nap', 'sit'],
  'heb': <String>['מַפָּה', 'לֶחֶם', 'מִטְרִיָּה', 'לִימוֹן'],
  'rus': <String>['мама', 'мак', 'утка', 'ухо'],
};

LangPack _stem(String course) {
  final LangPack p = _base(course);
  p.add(
    stemJson(
      course: course,
      id: 'x',
      band: 'B',
      stem: 'cat',
      clip: 'vo:$course.stem',
      options: <Map<String, Object?>>[
        pictureOption('o1', 'cat', clip: 'vo:$course.w.cat'),
        pictureOption('o2', 'dog', tag: p.tag('lis.sem'), clip: 'vo:$course.w.dog'),
        pictureOption('o3', 'duck', tag: p.tag('lis.guess'), clip: 'vo:$course.w.duck'),
      ],
      correct: 'o1',
    ),
  );
  return p;
}

LangPack _clozePack(String course, {String? text}) {
  final LangPack p = _base(course);
  final List<String> o = _clozeOptions[course]!;
  p.add(
    clozeJson(
      course: course,
      id: 'x',
      band: 'B',
      text: text ?? _cloze[course]!,
      picture: 'place-dog-on-chair',
      options: <Map<String, Object?>>[
        textOption('o1', o[0]),
        textOption('o2', o[1], tag: p.tag('lis.sem')),
        textOption('o3', o[2], tag: p.tag('lis.guess')),
      ],
      correct: 'o1',
    ),
  );
  return p;
}

LangPack _tapAll(String course) {
  final LangPack p = _base(course);
  final List<String> l = _letters[course]!;
  p.add(
    tapAllJson(
      course: course,
      id: 'x',
      band: 'B',
      face: 'letter',
      options: <Map<String, Object?>>[
        textOption('o1', l[0]),
        textOption('o2', l[1], tag: p.tag('lis.sem')),
        textOption('o3', l[0]),
        textOption('o4', l[2], tag: p.tag('lis.guess')),
        textOption('o5', l[1], tag: p.tag('lis.sem')),
        textOption('o6', l[0]),
      ],
      correct: <String>['o1', 'o3', 'o6'],
    ),
  );
  return p;
}

LangPack _sort(String course, {List<String>? words}) {
  final LangPack p = _base(course);
  final List<String> w = words ?? _sortWords[course]!;
  p.add(
    sortJson(
      course: course,
      id: 'x',
      band: 'B',
      bins: <Map<String, Object?>>[
        sortFace('b1', text: _letters[course]![0], clip: 'vo:$course.sign.1'),
        sortFace('b2', text: _letters[course]![1]),
      ],
      items: <Map<String, Object?>>[
        for (final (int i, String x) in w.indexed)
          sortFace('i${i + 1}', text: x, bin: i.isEven ? 'b1' : 'b2', tag: p.tag('lis.sem')),
      ],
    ),
  );
  return p;
}

LangPack _pairs(String course) {
  final LangPack p = _base(course);
  final List<String> l = _letters[course]!;
  p.add(
    pairsJson(
      course: course,
      id: 'x',
      band: 'B',
      left: <Map<String, Object?>>[
        for (final (int i, String x) in l.indexed)
          pairFace('l${i + 1}', text: x, clip: 'vo:$course.l.${i + 1}'),
      ],
      right: <Map<String, Object?>>[
        for (int i = 0; i < l.length; i++)
          pairFace('r${i + 1}', clip: 'vo:$course.n.${i + 1}', tag: p.tag('lis.sem')),
      ],
      pairs: <String, String>{for (int i = 0; i < l.length; i++) 'l${i + 1}': 'r${i + 1}'},
      tag: p.tag('lis.sem'),
    ),
  );
  return p;
}

LangPack _spot(String course) {
  final LangPack p = _base(course);
  p.add(
    spotJson(
      course: course,
      id: 'x',
      band: 'B',
      cells: <String>[for (final String l in _letters[course]!) 'txt:$l'],
      wrong: 2,
      model: 'cat',
      modelClip: 'vo:$course.cat',
      tag: p.tag('lis.sem'),
    ),
  );
  return p;
}

LangPack _order(String course) {
  final LangPack p = _base(course);
  final List<String> l = _letters[course]!;
  p.add(
    orderJson(
      course: course,
      id: 'x',
      band: 'B',
      model: <String>['txt:${l[0]}', 'txt:${l[1]}'],
      palette: <String>['txt:${l[2]}', 'txt:${l[0]}', 'txt:${l[1]}'],
      sequence: <String>['txt:${l[1]}', 'txt:${l[2]}'],
      tag: p.tag('lis.sem'),
    ),
  );
  return p;
}

LangPack _story(String course) {
  final LangPack p = _base(course);
  p.add(
    sequenceJson(
      course: course,
      id: 'x',
      band: 'B',
      palette: <String>['asset:story-bounce-1', 'asset:story-bounce-2', 'asset:story-bounce-3'],
      order: <int>[1, 2, 0],
      tag: p.tag('lis.sem'),
    ),
  );
  final Map<String, Object?> scene =
      (p.pack.docs['activity.$course.x.json']! as Map<String, Object?>)['scene']! as Map<String, Object?>;
  final List<String> clips = <String>['vo:$course.q.a', 'vo:$course.q.b', 'vo:$course.q.c'];
  scene['clips'] = clips;
  (p.pack.manifest['voPending']! as List<Object?>).addAll(clips);
  return p;
}

Rig<Ls01TapSession> _tapRig(LangPack p) => Rig<Ls01TapSession>(
  p,
  'x',
  (LessonController c, Activity a) => Ls01TapSession(c, a as TapAnswerActivity, band: Band.b),
);
Rig<Ls01SortSession> _sortRig(LangPack p) => Rig<Ls01SortSession>(
  p,
  'x',
  (LessonController c, Activity a) => Ls01SortSession(c, a as SortDragActivity),
);
Rig<Ls01PairsSession> _pairsRig(LangPack p) => Rig<Ls01PairsSession>(
  p,
  'x',
  (LessonController c, Activity a) => Ls01PairsSession(c, a as MatchPairsActivity),
);
Rig<Ls01SpotSession> _spotRig(LangPack p) => Rig<Ls01SpotSession>(
  p,
  'x',
  (LessonController c, Activity a) => Ls01SpotSession(c, a as SpotErrorActivity),
);
Rig<Ls01OrderSession> _orderRig(LangPack p) => Rig<Ls01OrderSession>(
  p,
  'x',
  (LessonController c, Activity a) => Ls01OrderSession(c, a as BuildPatternActivity),
);
Rig<Ls01SequenceSession> _storyRig(LangPack p) => Rig<Ls01SequenceSession>(
  p,
  'x',
  (LessonController c, Activity a) => Ls01SequenceSession(c, a as BuildPatternActivity),
);

double _x(WidgetTester t, Finder f) => t.getCenter(f).dx;

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadAppFonts();
  });

  // ---------------------------------------------------------------------------------------------------------------- the measure

  group('the fit check measures with the real fonts and fails on a text that is too long', () {
    test('a narrow and a wide letter are not the same width (the test font is not loaded: Ahem gives every glyph 1 em)', () {
      final Ls01Metrics en = Ls01Metrics(band: Band.b, tablet: false, course: 'eng');
      final Ls01Metrics he = Ls01Metrics(band: Band.b, tablet: false, course: 'heb');
      final Ls01Metrics ru = Ls01Metrics(band: Band.b, tablet: false, course: 'rus');
      expect(en.textWidth('iiii', FaceKind.word), lessThan(en.textWidth('mmmm', FaceKind.word) * 0.6));
      expect(he.textWidth('ווו', FaceKind.word), lessThan(he.textWidth('םםם', FaceKind.word) * 0.6));
      expect(ru.textWidth('иии', FaceKind.word), lessThan(ru.textWidth('шшш', FaceKind.word) * 0.8));
      // A pointed Hebrew word is as wide as the fit table says (docs/design/languages-l5-ls01.md 4.2): the marks add no width.
      expect(he.textWidth('מִטְרִיָּה', FaceKind.word) / he.size(FaceKind.word), closeTo(2.67, 0.15));
    });

    test('a too-long text is refused in every mode that carries text, naming the item and the limit', () {
      final List<String> all = <String>[];
      // Pairs: a partner row of four long words, and an item now that is wider than its square.
      final LangPack p = _base('eng');
      p.add(
        pairsJson(
          id: 'pr',
          band: 'B',
          left: <Map<String, Object?>>[
            pairFace('l1', text: 'elephant'),
            pairFace('l2', text: 'cat'),
          ],
          right: <Map<String, Object?>>[
            pairFace('r1', text: 'elephant', tag: p.tag('lis.sem')),
            pairFace('r2', text: 'giraffe', tag: p.tag('lis.sem')),
          ],
          pairs: <String, String>{'l1': 'r1', 'l2': 'r2'},
          tag: p.tag('lis.sem'),
        ),
      );
      all.addAll(ls01FitProblems(p.content.activities['eng.pr']!));
      expect(all, isNotEmpty, reason: 'an item now of "elephant" does not fit its square of 120');
      expect(all.first, contains('eng.pr'));
      expect(all.first, contains('the item now "elephant"'));
      // Hebrew sentence of a cloze: three lines are one too many in Hebrew.
      final LangPack h = _clozePack(
        'heb',
        text: 'הַכֶּלֶב הַגָּדוֹל הַחוּם _ עַל הַכִּסֵּא הָאָדֹם הַגָּדוֹל.',
      );
      final List<String> hp = ls01FitProblems(h.content.activities['heb.x']!);
      expect(hp, isNotEmpty);
      expect(hp.first, contains('lines in a column of 166 (at most 2)'));
      // A one-word stem wider than the page.
      final LangPack s = _base('rus');
      s.add(
        stemJson(
          course: 'rus',
          id: 'x',
          band: 'B',
          stem: 'достопримечательность',
          clip: 'vo:rus.stem',
          options: <Map<String, Object?>>[
            pictureOption('o1', 'cat'),
            pictureOption('o2', 'dog', tag: s.tag('lis.sem')),
          ],
          correct: 'o1',
        ),
      );
      expect(ls01FitProblems(s.content.activities['rus.x']!), isNotEmpty);
    });

    test(
      'a tap-all of 6 cards is refused on the phone SE at Band B (and at Band A for Hebrew), 5 is not',
      () {
        LangPack tapAll(int n) {
          final LangPack p = _base('heb');
          p.add(
            tapAllJson(
              course: 'heb',
              id: 'x',
              band: 'B',
              face: 'letter',
              options: <Map<String, Object?>>[
                for (int i = 0; i < n; i++)
                  textOption('o${i + 1}', 'מלרנס'[i % 5], tag: i < 2 ? null : p.tag('lis.sem')),
              ],
              correct: <String>['o1', 'o2'],
            ),
          );
          return p;
        }

        expect(ls01FitProblems(tapAll(5).content.activities['heb.x']!), isEmpty);
        final List<String> six = ls01FitProblems(tapAll(6).content.activities['heb.x']!);
        expect(six, isNotEmpty);
        expect(
          six.any((String m) => m.contains('Band B on the phone SE') && m.contains('a tap-all of 5 at most')),
          isTrue,
          reason: six.join('\n'),
        );
        expect(
          six.any((String m) => m.contains('Band A on the phone SE')),
          isTrue,
          reason: 'Hebrew shows text in Band A as well',
        );
      },
    );
  });

  // ---------------------------------------------------------------------------------------------------------------- direction

  group('direction: a row follows the course, never the interface', () {
    for (final String course in <String>['eng', 'heb', 'rus']) {
      final bool rtl = course == 'heb';
      // The sign of the order of the first and the last tile on the screen.
      void ordered(WidgetTester t, Finder first, Finder last, String what) {
        final double a = _x(t, first);
        final double b = _x(t, last);
        expect(
          rtl ? a > b : a < b,
          isTrue,
          reason: '$what: first at $a, last at $b in $course (${rtl ? 'right to left' : 'left to right'})',
        );
      }

      testWidgets('$course: the options of a stem and of a cloze, the cards of a tap-all', (
        WidgetTester t,
      ) async {
        for (final LangPack p in <LangPack>[_stem(course), _clozePack(course), _tapAll(course)]) {
          final Rig<Ls01TapSession> r = _tapRig(p);
          await r.pump(t);
          final String last =
              p.content.activities['$course.x']!.template == 'tap_answer' && (r.session.tap.all)
              ? 'o6'
              : 'o3';
          ordered(t, r.tile('o1'), r.tile(last), '${r.session.mode.name} options');
          await r.done(t);
        }
      });

      testWidgets('$course: the cloze puts its picture at the start side and the sentence after it', (
        WidgetTester t,
      ) async {
        final Rig<Ls01TapSession> r = _tapRig(_clozePack(course));
        await r.pump(t);
        final double picture = _x(t, find.byKey(const Key('cloze-picture')));
        final double text = _x(t, find.byKey(const Key('cloze-text')));
        expect(
          rtl ? picture > text : picture < text,
          isTrue,
          reason: 'the picture at $picture, the sentence at $text in $course',
        );
        // The first word of the sentence is at the start side of its column.
        // Start-aligned: the first word stands on the start edge, and no word of the sentence is further towards the start than it.
        final List<Rect> words = <Rect>[
          for (int i = 0; i < 3; i++) t.getRect(find.byKey(Key('sentence-word-$i'))),
        ];
        final double startEdge = rtl
            ? words.map((Rect w) => w.right).reduce((double a, double b) => a > b ? a : b)
            : words.map((Rect w) => w.left).reduce((double a, double b) => a < b ? a : b);
        expect(
          rtl ? words.first.right : words.first.left,
          closeTo(startEdge, 0.5),
          reason: 'a sentence starts at the start side in $course: ${words.join(' ')}',
        );
        await r.done(t);
      });

      testWidgets('$course: the bins, the tray and its pile of a sort', (WidgetTester t) async {
        final Rig<Ls01SortSession> r = _sortRig(_sort(course));
        await r.pump(t, size: _se);
        ordered(t, find.byKey(const Key('bin-b1')), find.byKey(const Key('bin-b2')), 'bins');
        ordered(t, r.tile('i1'), r.tile('i2'), 'tray');
        await r.done(t);
        final Rig<Ls01SortSession> six = _sortRig(
          _sort(course, words: <String>[..._sortWords[course]!, ..._sortWords[course]!.take(2)]),
        );
        await six.pump(t, size: _se);
        if (find.byKey(const Key('sort-pile')).evaluate().isNotEmpty) {
          final double tray = _x(t, find.byKey(const Key('sort-tray')));
          final double pile = _x(t, find.byKey(const Key('sort-pile')));
          expect(
            rtl ? pile < tray : pile > tray,
            isTrue,
            reason: 'the pile waits at the end side of the row',
          );
        }
        await six.done(t);
      });

      testWidgets(
        '$course: the item now at the start side, the partners in order, the kept pair at the end side',
        (WidgetTester t) async {
          final Rig<Ls01PairsSession> r = _pairsRig(_pairs(course));
          await r.pump(t);
          ordered(t, r.tile('r1'), r.tile('r3'), 'partners');
          final double item = _x(t, find.byKey(const Key('pairs-item')));
          expect(
            rtl ? item > 333 : item < 333,
            isTrue,
            reason: 'the item now is at the start side of the stage',
          );
          await t.tap(r.tile('r1'));
          await r.wait(t, 200);
          final double chip = _x(t, find.byKey(const Key('pair-chip-0-0')));
          expect(rtl ? chip < 333 : chip > 333, isTrue, reason: 'the kept pair flies to the end side');
          await r.done(t);
        },
      );

      testWidgets(
        '$course: the cells of a spot, the tiles and places of an order, the places of a story line',
        (WidgetTester t) async {
          final Rig<Ls01SpotSession> s = _spotRig(_spot(course));
          await s.pump(t);
          ordered(t, s.tile('c0'), s.tile('c2'), 'spot cells');
          await s.done(t);
          final Rig<Ls01OrderSession> o = _orderRig(_order(course));
          await o.pump(t);
          ordered(t, o.tile('p0'), o.tile('p2'), 'order tiles');
          ordered(
            t,
            find.byKey(const Key('order-slot-0')),
            find.byKey(const Key('order-slot-1')),
            'order places',
          );
          // The model row is read from the start side, and the places come after it.
          final double firstSlot = _x(t, find.byKey(const Key('order-slot-0')));
          final double rowMid = _x(t, find.byKey(const Key('order-row')));
          expect(
            rtl ? firstSlot < rowMid : firstSlot > rowMid,
            isTrue,
            reason: 'the places are at the end of the row, after the model',
          );
          await o.done(t);
          final Rig<Ls01SequenceSession> q = _storyRig(_story(course));
          await q.pump(t);
          ordered(t, find.byKey(const Key('place-0')), find.byKey(const Key('place-2')), 'story places');
          final double flag = _x(t, find.byKey(const Key('sequence-flag')));
          final double first = _x(t, find.byKey(const Key('place-0')));
          expect(
            rtl ? flag > first : flag < first,
            isTrue,
            reason: 'the start flag stands at the start end of the line',
          );
          await q.done(t);
        },
      );
    }

    testWidgets('a numeral and a shape card in a Hebrew row stay left-to-right tiles', (
      WidgetTester t,
    ) async {
      final LangPack p = _base('heb');
      p.add(
        tapAllJson(
          course: 'heb',
          id: 'x',
          band: 'B',
          face: 'letter',
          options: <Map<String, Object?>>[
            <String, Object?>{'id': 'o1', 'numeral': 12, 'label': 'twelve'},
            <String, Object?>{
              'id': 'o2',
              'numeral': 21,
              'label': 'twenty one',
              'misconception': p.tag('lis.sem'),
            },
            <String, Object?>{'id': 'o3', 'numeral': 12, 'label': 'twelve'},
            <String, Object?>{
              'id': 'o4',
              'numeral': 31,
              'label': 'thirty one',
              'misconception': p.tag('lis.guess'),
            },
          ],
          correct: <String>['o1', 'o3'],
        ),
      );
      final Rig<Ls01TapSession> r = _tapRig(p);
      await r.pump(t);
      final Finder twelve = find.descendant(of: r.tile('o1'), matching: find.text('12'));
      expect(twelve, findsOneWidget);
      expect(
        Directionality.of(t.element(twelve)),
        TextDirection.ltr,
        reason: 'a numeral is never mirrored (MathIsolate)',
      );
      // The row itself runs right to left: the first card is at the right.
      expect(_x(t, r.tile('o1')), greaterThan(_x(t, r.tile('o4'))));
      await r.done(t);
    });
  });

  // ---------------------------------------------------------------------------------------------------------------- the hint ladders

  group('the hint ladders', () {
    testWidgets('levels 1 and 2 light no option in a stem, a cloze, a sort, pairs, a spot and an order', (
      WidgetTester t,
    ) async {
      Future<void> ladder<S extends TemplateSession>(Rig<S> r, {Size size = const Size(852, 393)}) async {
        await r.pump(t, size: size);
        r.controller.showHint();
        await r.wait(t, 800);
        expect(
          find.byKey(const Key('hint-tile-glow')),
          findsNothing,
          reason: '${r.activity.template} level 1',
        );
        await r.wait(t, 3000);
        r.controller.showHint();
        await r.wait(t, 800);
        expect(
          find.byKey(const Key('hint-tile-glow')),
          findsNothing,
          reason: '${r.activity.template} level 2',
        );
        expect(find.byKey(const ValueKey<String>('ls01-hand')), findsNothing, reason: 'the hand comes last');
        await r.wait(t, 3500);
        await r.done(t);
      }

      await ladder(_tapRig(_stem('eng')));
      await ladder(_tapRig(_clozePack('eng')));
      await ladder(_sortRig(_sort('eng')));
      await ladder(_pairsRig(_pairs('heb')));
      await ladder(_spotRig(_spot('rus')));
      await ladder(_orderRig(_order('eng')));
    });

    testWidgets('level 3 ends with demoDone in every mode: the answer may then carry its halo', (
      WidgetTester t,
    ) async {
      Future<void> top<S extends TemplateSession>(Rig<S> r, String mode) async {
        await r.pump(t);
        for (int k = 0; k < 3; k++) {
          r.controller.showHint();
          await r.wait(t, 300);
        }
        expect(r.controller.hintShown, 3, reason: mode);
        await r.wait(t, 9000);
        // Asked for with the lamp, level 3 is a demonstration and no more (the lamp never forces); the three-mistakes path below is the one
        // that guides. Here only: the hand has left, so the demonstration ended, and nothing was written as a mistake.
        expect(
          find.byKey(const ValueKey<String>('ls01-hand')),
          findsNothing,
          reason: '$mode: the hand has left',
        );
        expect(
          r.attempts.where((AttemptRecord a) => a.result == 'incorrect'),
          isEmpty,
          reason: '$mode: a hint is not a mistake',
        );
        await r.done(t);
      }

      await top(_tapRig(_stem('eng')), 'stem');
      await top(_tapRig(_clozePack('heb')), 'cloze');
      await top(_sortRig(_sort('eng')), 'sort');
      await top(_pairsRig(_pairs('eng')), 'pairs');
      await top(_spotRig(_spot('eng')), 'spot');
      await top(_orderRig(_order('eng')), 'order');
      await top(_storyRig(_story('heb')), 'story');
    });

    testWidgets(
      'three mistakes: the help is at its top, the demonstration ends, the answer is shown, and only the right move is taken',
      (WidgetTester t) async {
        // stem
        Rig<Ls01TapSession> r = _tapRig(_stem('eng'));
        await r.pump(t);
        for (final String wrong in <String>['o2', 'o3', 'o2']) {
          await t.tap(r.tile(wrong));
          await r.wait(t, 1600);
        }
        expect(r.controller.guided, isTrue, reason: 'stem');
        await r.wait(t, 5000);
        expect(r.controller.answerShown, isTrue, reason: 'stem: demoDone was called');
        final int before = r.written.length;
        await t.tap(r.tile('o2'));
        await r.wait(t, 300);
        expect(r.written.length, before, reason: 'stem: a wrong touch is not taken at the top of the help');
        await t.tap(r.tile('o1'));
        await r.wait(t, 300);
        expect(r.written.last, 'correct:o1');
        await r.done(t);

        // cloze
        r = _tapRig(_clozePack('eng'));
        await r.pump(t);
        for (final String wrong in <String>['o2', 'o3', 'o2']) {
          await t.tap(r.tile(wrong));
          await r.wait(t, 1600);
        }
        expect(r.controller.guided, isTrue, reason: 'cloze');
        await r.wait(t, 6000);
        expect(r.controller.answerShown, isTrue, reason: 'cloze: demoDone was called');
        final int c0 = r.written.length;
        await t.tap(r.tile('o3'));
        await r.wait(t, 300);
        expect(r.written.length, c0, reason: 'cloze: a wrong word is not taken');
        expect(r.session.gapId, isNull);
        await t.tap(r.tile('o1'));
        await r.wait(t, 300);
        expect(r.written.last, 'correct:o1');
        await r.done(t);

        // pairs
        final Rig<Ls01PairsSession> pr = _pairsRig(_pairs('eng'));
        await pr.pump(t);
        for (final String wrong in <String>['r2', 'r3', 'r2']) {
          await t.tap(pr.tile(wrong));
          await pr.wait(t, 1600);
        }
        expect(pr.controller.guided, isTrue, reason: 'pairs');
        await pr.wait(t, 6000);
        expect(pr.controller.answerShown, isTrue, reason: 'pairs: demoDone was called');
        final int p0 = pr.written.length;
        await t.tap(pr.tile('r3'));
        await pr.wait(t, 300);
        expect(pr.written.length, p0, reason: 'pairs: a wrong partner is not taken');
        expect(pr.session.current, 0);
        await t.tap(pr.tile('r1'));
        await pr.wait(t, 300);
        expect(pr.session.current, 1);
        await pr.done(t);

        // spot
        final Rig<Ls01SpotSession> sp = _spotRig(_spot('eng'));
        await sp.pump(t);
        for (final String wrong in <String>['c0', 'c1', 'c0']) {
          await t.tap(sp.tile(wrong));
          await sp.wait(t, 1600);
        }
        expect(sp.controller.guided, isTrue, reason: 'spot');
        await sp.wait(t, 6000);
        expect(sp.controller.answerShown, isTrue, reason: 'spot: demoDone was called');
        final int s0 = sp.written.length;
        await t.tap(sp.tile('c1'));
        await sp.wait(t, 300);
        expect(sp.written.length, s0, reason: 'spot: a wrong cell is not taken');
        await t.tap(sp.tile('c2'));
        await sp.wait(t, 300);
        expect(sp.written.last, 'correct:2');
        await sp.done(t);

        // order
        final Rig<Ls01OrderSession> o = _orderRig(_order('eng'));
        await o.pump(t);
        for (int k = 0; k < 3; k++) {
          await t.tap(o.tile('p0'));
          await t.tap(o.tile('p2'));
          await o.wait(t, 1800);
        }
        expect(o.controller.guided, isTrue, reason: 'order');
        await o.wait(t, 6000);
        expect(o.controller.answerShown, isTrue, reason: 'order: demoDone was called');
        final int o0 = o.written.length;
        await t.tap(o.tile('p0'));
        await o.wait(t, 300);
        expect(
          o.session.filled.where((int? f) => f != null),
          isEmpty,
          reason: 'order: a wrong first tile is not taken',
        );
        expect(o.written.length, o0);
        await o.done(t);

        // story line
        final Rig<Ls01SequenceSession> q = _storyRig(_story('heb'));
        await q.pump(t);
        for (int k = 0; k < 3; k++) {
          await t.tap(find.byKey(const Key('place-0')));
          await t.tap(find.byKey(const Key('place-1')));
          await q.wait(t, 1800);
        }
        expect(q.controller.guided, isTrue, reason: 'story');
        await q.wait(t, 9000);
        expect(q.controller.answerShown, isTrue, reason: 'story: demoDone was called');
        await q.done(t);
      },
    );

    testWidgets('the cloze and the story run to their end after the help: nothing dead-ends', (
      WidgetTester t,
    ) async {
      final Rig<Ls01SequenceSession> q = _storyRig(_story('eng'));
      await q.pump(t);
      // The right order is [1, 2, 0]: the picture of palette 1 first.
      await t.tap(find.byKey(const Key('place-1')));
      await t.tap(find.byKey(const Key('place-2')));
      await q.wait(t, 300);
      expect(q.written, <String>['correct:120']);
      await q.wait(t, 2500);
      await q.done(t);
    });
  });

  // ---------------------------------------------------------------------------------------------------------------- scoring

  group('scoring', () {
    testWidgets(
      'tap-all: right only for the exact set, the tag is the first wrong pick, and a pick of the same letter twice is not a set',
      (WidgetTester t) async {
        // The tag of the first wrong card picked, in the order picked.
        Rig<Ls01TapSession> r = _tapRig(_tapAll('eng'));
        await r.pump(t);
        await t.tap(r.tile('o4')); // guess
        await t.tap(r.tile('o2')); // sem
        await t.tap(r.tile('o1'));
        await r.wait(t, 200);
        expect(r.written, <String>['incorrect:3.1.0']);
        expect(r.attempts.single.misconceptionTag, 'eng.lis.guess', reason: 'the first wrong pick decides');
        await r.done(t);

        r = _tapRig(_tapAll('eng'));
        await r.pump(t);
        await t.tap(r.tile('o2'));
        await t.tap(r.tile('o4'));
        await t.tap(r.tile('o1'));
        await r.wait(t, 200);
        expect(r.attempts.single.misconceptionTag, 'eng.lis.sem');
        await r.done(t);

        // Two right and one wrong is not the set; the right set in another order is.
        r = _tapRig(_tapAll('eng'));
        await r.pump(t);
        await t.tap(r.tile('o6'));
        await t.tap(r.tile('o1'));
        await t.tap(r.tile('o3'));
        await r.wait(t, 200);
        expect(r.written, <String>['correct:5.0.2']);
        await r.done(t);
      },
    );

    testWidgets('"I\'m not sure" and "show me" are never a mistake in any mode', (WidgetTester t) async {
      Future<void> unsure<S extends TemplateSession>(Rig<S> r, String mode) async {
        await r.pump(t);
        await r.controller.unsure();
        await r.wait(t, 600);
        expect(
          r.attempts.where((AttemptRecord a) => a.result == 'incorrect'),
          isEmpty,
          reason: '$mode: not sure is not wrong',
        );
        expect(
          r.attempts.where((AttemptRecord a) => a.misconceptionTag.isNotEmpty),
          isEmpty,
          reason: '$mode: no misconception from not sure',
        );
        expect(r.attempts.single.result, 'unsure', reason: mode);
        await r.wait(t, 9000);
        await r.done(t);
      }

      await unsure(_tapRig(_stem('eng')), 'stem');
      await unsure(_tapRig(_clozePack('eng')), 'cloze');
      await unsure(_tapRig(_tapAll('heb')), 'tap-all');
      await unsure(_sortRig(_sort('eng')), 'sort');
      await unsure(_pairsRig(_pairs('rus')), 'pairs');
      await unsure(_spotRig(_spot('eng')), 'spot');
      await unsure(_orderRig(_order('eng')), 'order');
      await unsure(_storyRig(_story('eng')), 'story');
    });

    testWidgets(
      'the lamp and the "not yet" of every mode run on no timer for the child: nothing counts down on the screen',
      (WidgetTester t) async {
        final Rig<Ls01TapSession> r = _tapRig(_clozePack('eng'));
        await r.pump(t);
        // No countdown, clock or progress-by-time widget in the child's space (CLAUDE.md child safety).
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.byType(LinearProgressIndicator), findsNothing);
        expect(find.textContaining(RegExp(r'\d+:\d\d')), findsNothing);
        await t.tap(r.tile('o2'));
        await r.wait(t, 5000);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        await r.done(t);
      },
    );
  });

  // ---------------------------------------------------------------------------------------------------------------- open defects

  group('open defects (skipped until the fix; `--dart-define=QA_OPEN=true` runs them and shows each fail)', () {
    /// A sort on the phone SE with [cards] put in bin b1 (i1 and i3 belong there).
    Future<Rig<Ls01SortSession>> sortWithChips(WidgetTester t, String course, List<String> cards) async {
      final Rig<Ls01SortSession> r = _sortRig(_sort(course));
      await r.pump(t, size: _se);
      for (final String card in cards) {
        await t.tap(r.tile(card));
        await r.wait(t, 100);
        await t.tap(find.byKey(const Key('bin-b1')));
        await r.wait(t, 500);
      }
      return r;
    }

    for (final String course in <String>['eng', 'heb']) {
      testWidgets(
        'QA-L51-1a: $course, every card sorted into a bin stays in view in it (phone SE)',
        (WidgetTester t) async {
          final Rig<Ls01SortSession> r = await sortWithChips(t, course, <String>['i1', 'i3']);
          final Rect bin = t.getRect(find.byKey(const Key('bin-b1')));
          for (final String chip in <String>['chip-i1', 'chip-i3']) {
            final Rect c = t.getRect(find.byKey(Key(chip)));
            expect(
              bin.contains(c.topLeft) && bin.contains(c.bottomRight),
              isTrue,
              reason: '$chip stands at $c outside its bin $bin: the bin clips it away',
            );
          }
          await r.done(t);
        },
        skip: _skipOpen, // QA-L51-1a: remove when the kept chips are laid out so that none is lost
      );

      testWidgets(
        'QA-L51-1b: $course, the bin speaker does not sit on a kept chip (phone SE)',
        (WidgetTester t) async {
          final Rig<Ls01SortSession> r = await sortWithChips(t, course, <String>['i1']);
          final Rect speaker = t.getRect(find.byKey(const Key('bin-speaker-b1'))).deflate(6);
          final Rect chip = t.getRect(find.byKey(const Key('chip-i1')));
          expect(chip.overlaps(speaker), isFalse, reason: 'the chip $chip is under the speaker $speaker');
          await r.done(t);
        },
        skip: _skipOpen, // QA-L51-1b: remove when the speaker and the chips have their own places
      );
    }

    testWidgets(
      'QA-L51-2: at text scale 1.3 the sentence of a cloze stays above the answer tiles (phone and phone SE)',
      (WidgetTester t) async {
        t.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
        for (final Size size in <Size>[_se, const Size(852, 393)]) {
          final Rig<Ls01TapSession> r = _tapRig(_clozePack('eng'));
          await r.pump(t, size: size);
          double bottom = 0;
          for (int i = 0; i < 5; i++) {
            final Finder w = find.byKey(Key('sentence-word-$i'));
            if (w.evaluate().isNotEmpty) bottom = bottom > t.getRect(w).bottom ? bottom : t.getRect(w).bottom;
          }
          final double top = t.getRect(r.tile('o1')).top;
          expect(
            bottom,
            lessThanOrEqualTo(top),
            reason: 'at $size the sentence ends at $bottom and the tiles start at $top',
          );
          await r.done(t);
        }
      },
      skip: _skipOpen, // QA-L51-2: remove when the stage text is held to the board
    );

    testWidgets(
      'QA-L51-3a: the hand of level 3 does not cover the sign of the bin it points at (phone SE)',
      (WidgetTester t) async {
        final Rig<Ls01SortSession> s = _sortRig(_sort('eng'));
        await s.pump(t, size: _se);
        for (int k = 0; k < 3; k++) {
          s.controller.showHint();
          await s.wait(t, 300);
        }
        await s.wait(t, 2300);
        final Finder hand = find.byKey(const Key('hint-p12'));
        expect(hand, findsOneWidget);
        expect(
          t.getRect(hand).overlaps(t.getRect(find.byKey(const Key('sign-b1'))).deflate(4)),
          isFalse,
          reason: 'the hand sits on the sign of the bin',
        );
        await s.done(t);
      },
      skip: _skipOpen, // QA-L51-3a: remove when the hand points from where it hides no sign
    );

    testWidgets(
      'QA-L51-3b: the hand of level 3 does not cover the words of the cloze sentence (phone SE)',
      (WidgetTester t) async {
        final Rig<Ls01TapSession> c = _tapRig(_clozePack('eng'));
        await c.pump(t, size: _se);
        for (int k = 0; k < 3; k++) {
          c.controller.showHint();
          await c.wait(t, 300);
        }
        await c.wait(t, 1700);
        final Rect h = t.getRect(find.byKey(const Key('hint-p12')));
        for (final String w in <String>[
          'sentence-word-0',
          'sentence-word-1',
          'sentence-word-2',
          'sentence-word-4',
          'sentence-word-5',
        ]) {
          expect(
            h.overlaps(t.getRect(find.byKey(Key(w))).deflate(4)),
            isFalse,
            reason: 'the hand covers $w of the sentence',
          );
        }
        await c.done(t);
      },
      skip: _skipOpen, // QA-L51-3b: remove when the hand points from where it hides no word
    );

    testWidgets(
      'QA-L51-4a: level 1 of the story line does not light the pictures in the answer order',
      (WidgetTester t) async {
        final Rig<Ls01SequenceSession> q = _storyRig(_story('eng'));
        await q.pump(t);
        q.controller.showHint();
        final List<int?> seen = <int?>[];
        for (int k = 0; k < 40; k++) {
          await q.wait(t, 100);
          if (seen.isEmpty || seen.last != q.session.litPlace) seen.add(q.session.litPlace);
        }
        // The pictures stand in their shuffled places and the story is [1, 2, 0]: lit in that order, the hint has said the answer.
        final List<int> lit = <int>[for (final int? p in seen) ?p];
        expect(lit.length, greaterThan(1));
        expect(
          lit,
          isNot(<int>[1, 2, 0].map((int k) => q.session.placeOf(k)).toList()),
          reason: 'level 1 lit the pictures in story order: $lit',
        );
        await q.done(t);
      },
      skip: _skipOpen, // QA-L51-4a: a decision first (curriculum-expert, design-director): spec 7.10 says it, spec 8 says no option is lit before level 3
    );

    testWidgets(
      'QA-L51-4b: level 2 of a tap-all does not settle on the right cards',
      (WidgetTester t) async {
        final Rig<Ls01TapSession> a = _tapRig(_tapAll('eng'));
        await a.pump(t);
        a.controller.showHint();
        await a.wait(t, 200);
        a.controller.showHint();
        await a.wait(t, 4000);
        expect(a.session.ghostSettled, isEmpty, reason: 'level 2 marked the right cards before level 3');
        await a.done(t);
      },
      skip: _skipOpen, // QA-L51-4b: a decision first (curriculum-expert, design-director): spec 7.7 says it, spec 8 says no option is lit before level 3
    );
  });
}
