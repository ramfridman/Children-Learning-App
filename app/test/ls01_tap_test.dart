// LS01, the rest (L5-1): the text stem, the cloze and the tap-all of `tap_answer` 1.4. The document (the model and the validator's rules),
// the play (what is written, the tags, the hint ladder, the board's zones) and the safety rules (no timer, no wrong for an unclear answer).
// Fixture course and fake clips, not content.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/content/pack_validation.dart';
import 'package:nitznutz/content/schema.dart';
import 'package:nitznutz/design/token_types.dart';
import 'package:nitznutz/play/lesson_controller.dart';
import 'package:nitznutz/play/ls01_tap_session.dart';
import 'package:nitznutz/play/tap_answer_session.dart';

import 'support/l4_rig.dart';
import 'support/language_content.dart';
import 'support/ls01_content.dart';
import 'support/sample_pack.dart';

List<Problem> _run(SamplePack p) => validatePack(manifest: p.manifest, docs: p.docs, files: p.files);

List<String> _messages(LangPack p) => <String>[
  for (final Problem x in _run(p.pack)) '${x.path}: ${x.message}',
];

const List<String> _pictures = <String>['cat', 'dog', 'duck', 'apple', 'banana', 'bread', 'book'];

Map<String, Object?> _letters(String id, String text, {String? tag, String? clip}) =>
    textOption(id, text, tag: tag, clip: clip);

LangPack _tapAllPack({String course = 'eng'}) {
  final LangPack p = LangPack(course)..addPictures(_pictures);
  final String lm = p.tag('lis.sem');
  p.add(
    tapAllJson(
      course: course,
      id: 'tall',
      face: 'letter',
      options: <Map<String, Object?>>[
        _letters('o1', 't'),
        _letters('o2', 'i', tag: lm),
        _letters('o3', 't'),
        _letters('o4', 'f', tag: lm),
        _letters('o5', 'l', tag: lm),
        _letters('o6', 't'),
      ],
      correct: <String>['o1', 'o3', 'o6'],
    ),
  );
  return p;
}

LangPack _stemPack() {
  final LangPack p = LangPack()..addPictures(_pictures);
  p.add(
    stemJson(
      id: 'stem',
      stem: 'cat',
      clip: 'vo:eng.stem.cat',
      options: <Map<String, Object?>>[
        pictureOption('o1', 'cat', clip: 'vo:eng.w.cat'),
        pictureOption('o2', 'dog', tag: p.tag('lis.sem'), clip: 'vo:eng.w.dog'),
        pictureOption('o3', 'duck', tag: p.tag('lis.guess'), clip: 'vo:eng.w.duck'),
      ],
      correct: 'o1',
    ),
  );
  return p;
}

LangPack _clozePack() {
  final LangPack p = LangPack()..addPictures(_pictures);
  p.add(
    clozeJson(
      id: 'cloze',
      text: 'The cat is _ the bed.',
      picture: 'cat',
      options: <Map<String, Object?>>[
        textOption('o1', 'on'),
        textOption('o2', 'in', tag: p.tag('lis.sem')),
        textOption('o3', 'at', tag: p.tag('lis.guess')),
      ],
      correct: 'o1',
    ),
  );
  return p;
}

Rig<Ls01TapSession> _rig(LangPack p, String id, {Band band = Band.b}) => Rig<Ls01TapSession>(
  p,
  id,
  (LessonController c, Activity a) => Ls01TapSession(c, a as TapAnswerActivity, band: band),
);

void main() {
  group('the document', () {
    test('a stem, a cloze and a tap-all pass the validator and read as their model', () {
      expect(_messages(_stemPack()), isEmpty);
      expect(_messages(_clozePack()), isEmpty);
      expect(_messages(_tapAllPack()), isEmpty);
      final TapAnswerActivity stem = _stemPack().content.activities['eng.stem']! as TapAnswerActivity;
      expect(stem.ls01Mode, Ls01TapMode.stem);
      expect(stem.stem, (text: 'cat', clip: 'vo:eng.stem.cat'));
      final TapAnswerActivity cloze = _clozePack().content.activities['eng.cloze']! as TapAnswerActivity;
      expect(cloze.ls01Mode, Ls01TapMode.cloze);
      expect(cloze.cloze!.text, 'The cat is _ the bed.');
      final TapAnswerActivity all = _tapAllPack().content.activities['eng.tall']! as TapAnswerActivity;
      expect(all.ls01Mode, Ls01TapMode.tapAll);
      expect(all.correctIds, <String>['o1', 'o3', 'o6']);
      expect(all.optionCount, 6);
      expect(all.engineTags, <String>{'eng.lis.sem'});
    });

    test('a plain tap of L1 has no L5 mode', () {
      final LangPack p = LangPack()..addPictures(_pictures);
      final TapAnswerActivity a = p.content.activities.values.whereType<TapAnswerActivity>().isEmpty
          ? (p..add(
                      tapJson(
                        id: 'plain',
                        options: <Map<String, Object?>>[
                          pictureOption('o1', 'cat'),
                          pictureOption('o2', 'dog', tag: p.tag('lis.sem')),
                        ],
                        correct: 'o1',
                      ),
                    ))
                    .content
                    .activities['eng.plain']!
                as TapAnswerActivity
          : p.content.activities.values.whereType<TapAnswerActivity>().first;
      expect(a.ls01Mode, isNull);
      expect(a.correctIds, <String>['o1']);
    });

    test('the broken files: each rule of the three modes says what is wrong', () {
      // A cloze with two gaps, with a picture option, and with four tiles.
      LangPack p = _clozePack();
      p.pack.docs['activity.eng.cloze.json'] = clozeJson(
        id: 'cloze',
        text: 'The _ is _ the bed.',
        options: <Map<String, Object?>>[
          textOption('o1', 'on'),
          pictureOption('o2', 'dog', tag: p.tag('lis.sem')),
          textOption('o3', 'at', tag: p.tag('lis.guess')),
        ],
        correct: 'o1',
      );
      expect(_messages(p), contains(contains('has 2 gaps')));
      expect(_messages(p), contains(contains('a word tile of a cloze is a text')));
      p = _clozePack();
      p.pack.docs['activity.eng.cloze.json'] = clozeJson(
        id: 'cloze',
        text: 'The cat is on the bed.',
        options: <Map<String, Object?>>[
          textOption('o1', 'on'),
          textOption('o2', 'in', tag: p.tag('lis.sem')),
          textOption('o3', 'at', tag: p.tag('lis.guess')),
        ],
        correct: 'o1',
      );
      expect(_messages(p), contains(contains('has 0 gaps')));
      // A stem with a clip whose level 1 does not lower the credit to 0.8.
      p = _stemPack();
      (((p.pack.docs['activity.eng.stem.json']! as Map<String, Object?>)['scoring']!
                  as Map<String, Object?>)['creditByHintLevel']!
              as List<Object?>)[1] =
          0.75;
      expect(_messages(p), contains(contains('lowers the credit to 0.8')));
      // A tap-all with one wrong card, with a wrong card that looks like a right one, and a list that is not a tap-all.
      p = _tapAllPack();
      p.pack.docs['activity.eng.tall.json'] = tapAllJson(
        id: 'tall',
        face: 'letter',
        options: <Map<String, Object?>>[
          _letters('o1', 't'),
          _letters('o2', 'f', tag: p.tag('lis.sem')),
        ],
        correct: <String>['o1'],
      );
      expect(_messages(p), contains(contains('at least two wrong cards')));
      // One right card is a plain choice: a tap-all needs at least two (curriculum section 11.1, answer 2); two is enough.
      p.pack.docs['activity.eng.tall.json'] = tapAllJson(
        id: 'tall',
        face: 'letter',
        options: <Map<String, Object?>>[
          _letters('o1', 't'),
          _letters('o2', 'f', tag: p.tag('lis.sem')),
          _letters('o3', 'l', tag: p.tag('lis.sem')),
          _letters('o4', 'i', tag: p.tag('lis.sem')),
        ],
        correct: <String>['o1'],
      );
      expect(_messages(p), contains(contains('a tap-all has at least two right cards (found 1)')));
      p.pack.docs['activity.eng.tall.json'] = tapAllJson(
        id: 'tall',
        face: 'letter',
        options: <Map<String, Object?>>[
          _letters('o1', 't'),
          _letters('o2', 'f', tag: p.tag('lis.sem')),
          _letters('o3', 'l', tag: p.tag('lis.sem')),
          _letters('o4', 't'),
        ],
        correct: <String>['o1', 'o4'],
      );
      expect(_messages(p), isEmpty);
      p.pack.docs['activity.eng.tall.json'] = tapAllJson(
        id: 'tall',
        face: 'letter',
        options: <Map<String, Object?>>[
          _letters('o1', 't'),
          _letters('o2', 't', tag: p.tag('lis.sem')),
          _letters('o3', 'f', tag: p.tag('lis.sem')),
        ],
        correct: <String>['o1'],
      );
      expect(_messages(p), contains(contains('looks like a card on the other side')));
      p = _tapAllPack();
      final Map<String, Object?> doc = p.pack.docs['activity.eng.tall.json']! as Map<String, Object?>;
      (doc['answer']! as Map<String, Object?>)['all'] = false;
      expect(_messages(p), contains(contains('is a tap-all: say `"all": true`')));
      // Seven cards are more than the schema lets a tap-all have; six untagged ones are not each a mistake with a tag.
      p = _tapAllPack();
      List<Map<String, Object?>> cards(int n) => <Map<String, Object?>>[
        for (int i = 0; i < n; i++) _letters('o${i + 1}', 'abcdefg'[i]),
      ];
      p.pack.docs['activity.eng.tall.json'] = tapAllJson(
        id: 'tall',
        face: 'letter',
        options: cards(7),
        correct: <String>['o1'],
      );
      expect(_messages(p), contains(contains('7 items is outside 2 to 6')));
      p.pack.docs['activity.eng.tall.json'] = tapAllJson(
        id: 'tall',
        face: 'letter',
        options: cards(6),
        correct: <String>['o1'],
      );
      expect(_messages(p).where((String x) => x.contains('every distractor is tagged')), hasLength(5));
    });

    test('the lands refuse the new modes', () {
      final SamplePack p = SamplePack();
      final Map<String, Object?> pick = p.docs.values.whereType<Map<String, Object?>>().firstWhere(
        (Map<String, Object?> d) => d['template'] == 'tap_answer',
      );
      (pick['scene']! as Map<String, Object?>)['stem'] = <String, Object?>{'text': 'cat'};
      final List<String> m = <String>[for (final Problem x in _run(p)) '${x.path}: ${x.message}'];
      expect(m.any((String x) => x.contains('belongs to a language course')), isTrue, reason: m.join('\n'));
    });
  });

  group('an option with no clip: the look-alike tile of a letter not yet taught', () {
    /// A letter item whose options play their sounds: the right letter and two look-alikes of letters nobody has taught.
    LangPack lookAlikes({String? tagF, bool clipOnF = false, bool lineForTag = true, String? tagL}) {
      final LangPack p = LangPack();
      p.pack.doc('skill.ENG-A-02.json')['letters'] = true;
      p.pack.doc('skill.ENG-A-02.json')['graphemes'] = <Object?>['t'];
      final Map<String, Object?> doc = tapJson(
        id: 'look',
        options: <Map<String, Object?>>[
          textOption('o1', 't', clip: 'vo:eng.snd.t'),
          textOption('o2', 'f', tag: tagF ?? p.tag('lis.lookalike'), clip: clipOnF ? 'vo:eng.snd.f' : null),
          textOption('o3', 'l', tag: tagL ?? p.tag('lis.lookalike')),
        ],
        correct: 'o1',
        answer: <String, Object?>{'face': 'letter'},
      );
      if (lineForTag) {
        ((doc['feedback']! as Map<String, Object?>)['incorrect']! as List<Object?>).add(<String, Object?>{
          'when': 'misconception:${p.tag('lis.lookalike')}',
          ...line('vo:eng.look.fb', 'זוֹ אוֹת אַחֶרֶת.', target: 'vo:eng.snd.t'),
        });
      }
      p.add(doc);
      return p;
    }

    test('a clip-less wrong tile with a SHAPE tag is valid, and an untaught letter on it is not read', () {
      expect(_messages(lookAlikes()), isEmpty);
    });

    test('the validator refuses a clip-less tile that is not a look-alike, or the answer, or has no line of its own', () {
      expect(
        _messages(lookAlikes(tagF: LangPack().tag('lis.sem'))),
        contains(contains('only a look-alike tile (a tag of the family SHAPE) goes without')),
      );
      LangPack p = lookAlikes(clipOnF: true);
      final List<Object?> opts =
          (p.activity('look')['answer']! as Map<String, Object?>)['options']! as List<Object?>;
      (opts.first! as Map<String, Object?>).remove('clip');
      expect(_messages(p), contains(contains('gives every right option its clip')));
      expect(
        _messages(lookAlikes(lineForTag: false)),
        contains(contains('needs a line for eng.lis.lookalike')),
      );
      // Items whose options never sound are unchanged: no clip anywhere, any tag.
      p = lookAlikes();
      for (final Object? o
          in (p.activity('look')['answer']! as Map<String, Object?>)['options']! as List<Object?>) {
        (o! as Map<String, Object?>).remove('clip');
      }
      expect(_messages(p).where((String m) => m.contains('no sound')), isEmpty);
    });

    test('the decodable check lets a SHAPE look-alike tile through but still reads every other letter', () {
      // f has a clip and the look-alike tag: allowed although nobody up to the skill teaches f. The same letter on a tile with another tag is read.
      expect(_messages(lookAlikes(clipOnF: true)), isEmpty);
      final List<String> m = _messages(lookAlikes(tagF: LangPack().tag('lis.sem'), clipOnF: true));
      expect(m, contains(contains('the word "f" cannot be read yet at ENG-A-02')));
    });

    testWidgets('such a tile shows no speaker and plays nothing; the first error says the line of its tag', (
      WidgetTester t,
    ) async {
      final LangPack p = lookAlikes();
      final Rig<TapAnswerSession> r = Rig<TapAnswerSession>(
        p,
        'look',
        (LessonController c, Activity a) => TapAnswerSession(c, a as TapAnswerActivity, band: Band.b),
      );
      await r.pump(t);
      expect(find.byKey(const Key('speaker-o1')), findsOneWidget);
      expect(find.byKey(const Key('speaker-o2')), findsNothing);
      expect(find.byKey(const Key('speaker-o3')), findsNothing);
      await t.tap(r.tile('o2'));
      await r.wait(t, 200);
      expect(r.heard.calls, isEmpty, reason: 'no untaught letter is heard by accident');
      expect(r.attempts.single.misconceptionTag, 'eng.lis.lookalike');
      expect(r.controller.voice, 'vo:eng.look.fb');
      expect(r.controller.voiceTarget, 'vo:eng.snd.t');
      await r.done(t);
    });
  });

  group('the stem', () {
    testWidgets(
      'the right picture is right; read it to me lowers the credit; the ladder never marks the answer',
      (WidgetTester t) async {
        final Rig<Ls01TapSession> r = _rig(_stemPack(), 'stem');
        await r.pump(t);
        expect(find.byKey(const Key('stem-page')), findsOneWidget);
        expect(find.byKey(const Key('stem-text')), findsOneWidget);
        // The stem is not read to the child unasked.
        expect(r.heard.clips.where((String c) => c == 'vo:eng.stem.cat'), isEmpty);
        await t.tap(r.tile('o2'));
        await r.wait(t, 200);
        expect(r.written, <String>['incorrect:o2']);
        expect(r.attempts.single.misconceptionTag, 'eng.lis.sem');
        await r.wait(t, 1300);
        // The first help: the stem is read to the child, a bar walks under its words, and the page is lit.
        expect(r.controller.hintShown, 1);
        expect(r.heard.clips, contains('vo:eng.stem.cat'));
        expect(find.byKey(const Key('stem-glow')), findsOneWidget);
        expect(find.byKey(const Key('hint-tile-glow')), findsNothing, reason: 'no option is lit at level 1');
        await t.tap(r.tile('o1'));
        await r.wait(t, 300);
        expect(r.written.last, 'correct:o1');
        expect(r.attempts.last.hintLevel, 1);
        await r.done(t);
      },
    );

    testWidgets('level 2 shows the stem in pieces, level 3 the hand and then the halo', (
      WidgetTester t,
    ) async {
      final Rig<Ls01TapSession> r = _rig(_stemPack(), 'stem');
      await r.pump(t);
      r.controller.showHint();
      await r.wait(t, 200);
      r.controller.showHint();
      await r.wait(t, 200);
      expect(find.byKey(const Key('stem-piece-0')), findsOneWidget);
      expect(find.byKey(const Key('stem-piece-2')), findsOneWidget);
      r.controller.showHint();
      await r.wait(t, 200);
      await r.wait(t, 500);
      expect(r.controller.hintShown, 3);
      expect(r.session.handTip, isNotNull, reason: 'the hand goes to the right picture');
      expect(find.byKey(const ValueKey<String>('ls01-hand')), findsOneWidget);
      await r.wait(t, 2500);
      expect(r.session.handTip, isNull, reason: 'and then it leaves');
      await r.done(t);
    });
  });

  group('the cloze', () {
    testWidgets('a word goes into the gap; a not yet sends it back; the right one stays', (
      WidgetTester t,
    ) async {
      final Rig<Ls01TapSession> r = _rig(_clozePack(), 'cloze');
      await r.pump(t);
      expect(find.byKey(const Key('cloze-gap')), findsOneWidget);
      expect(find.byKey(const Key('cloze-picture')), findsOneWidget);
      await t.tap(r.tile('o2'));
      await r.wait(t, 100);
      expect(r.session.gapId, 'o2');
      await r.wait(t, 1300);
      expect(r.session.gapId, isNull);
      expect(r.written.first, 'incorrect:o2');
      await t.tap(r.tile('o1'));
      await r.wait(t, 100);
      expect(r.session.gapId, 'o1');
      expect(r.written.last, 'correct:o1');
      await r.done(t);
    });

    testWidgets('level 2 grows the picture to the stage and gives the sentence back', (WidgetTester t) async {
      final Rig<Ls01TapSession> r = _rig(_clozePack(), 'cloze');
      await r.pump(t);
      r.controller.showHint();
      await r.wait(t, 100);
      r.controller.showHint();
      await r.wait(t, 200);
      expect(find.byKey(const Key('cloze-picture-full')), findsOneWidget);
      await r.wait(t, 2700);
      expect(find.byKey(const Key('cloze-picture-full')), findsNothing);
      await r.done(t);
    });
  });

  group('the tap-all', () {
    testWidgets('it checks itself at three picks: the right ones and no wrong one is right', (
      WidgetTester t,
    ) async {
      final Rig<Ls01TapSession> r = _rig(_tapAllPack(), 'tall');
      await r.pump(t);
      await t.tap(r.tile('o1'));
      await t.tap(r.tile('o3'));
      await r.wait(t, 100);
      expect(r.written, isEmpty, reason: 'two picks of three: not checked yet');
      expect(find.byKey(const Key('picked-dot')), findsNWidgets(2));
      // A second tap un-picks.
      await t.tap(r.tile('o3'));
      await r.wait(t, 100);
      expect(find.byKey(const Key('picked-dot')), findsOneWidget);
      await t.tap(r.tile('o3'));
      await t.tap(r.tile('o6'));
      await r.wait(t, 200);
      expect(r.written, <String>['correct:0.2.5']);
      await r.done(t);
    });

    testWidgets(
      'a wrong pick: the wrong card wobbles and un-picks, the right ones stay, and its tag is recorded',
      (WidgetTester t) async {
        final Rig<Ls01TapSession> r = _rig(_tapAllPack(), 'tall');
        await r.pump(t);
        await t.tap(r.tile('o1'));
        await t.tap(r.tile('o2'));
        await t.tap(r.tile('o3'));
        await r.wait(t, 200);
        expect(r.written, <String>['incorrect:0.1.2']);
        expect(r.attempts.single.misconceptionTag, 'eng.lis.sem');
        expect(r.session.notYetPicks, <String>{'o2'});
        await r.wait(t, 1300);
        expect(r.session.picked, <String>['o1', 'o3']);
        expect(r.session.notYetPicks, isEmpty);
        // The child goes on: the last right card completes the set.
        await t.tap(r.tile('o6'));
        await r.wait(t, 200);
        expect(r.written.last, 'correct:0.2.5');
        await r.done(t);
      },
    );

    testWidgets(
      'level 1 makes the target big, level 2 glides it over the cards, level 3 picks the first right card',
      (WidgetTester t) async {
        final Rig<Ls01TapSession> r = _rig(_tapAllPack(), 'tall');
        await r.pump(t);
        expect(find.byKey(const Key('target-sound')), findsOneWidget);
        r.controller.showHint();
        await r.wait(t, 200);
        expect(find.byKey(const Key('target-big')), findsOneWidget);
        expect(find.byKey(const Key('hint-tile-glow')), findsNothing);
        r.controller.showHint();
        await r.wait(t, 800);
        expect(find.byKey(const Key('ghost-1')), findsOneWidget);
        await r.wait(t, 4000);
        r.controller.showHint();
        await r.wait(t, 3500);
        expect(r.session.picked, <String>['o1'], reason: 'the first right card is picked for the child');
        expect(r.session.handTip, isNull);
        await r.done(t);
      },
    );

    testWidgets('after three wrong tries only the right cards can be picked, and they carry the halo', (
      WidgetTester t,
    ) async {
      final Rig<Ls01TapSession> r = _rig(_tapAllPack(), 'tall');
      await r.pump(t);
      for (int k = 0; k < 3; k++) {
        await t.tap(r.tile('o2'));
        await t.tap(r.tile('o4'));
        await t.tap(r.tile('o5'));
        await r.wait(t, 1500);
      }
      expect(r.controller.guided, isTrue);
      await r.wait(t, 4000);
      expect(r.controller.answerShown, isTrue);
      // The hand picked the first right card for the child; a wrong card is not taken under guidance.
      expect(r.session.picked, <String>['o1']);
      await t.tap(r.tile('o2'));
      expect(r.session.picked, <String>['o1']);
      await t.tap(r.tile('o3'));
      expect(r.session.picked, <String>['o1', 'o3']);
      await r.done(t);
    });
  });

  group('the board', () {
    testWidgets('the zones follow the spec on the phone and the phone SE, and the row stays inside them', (
      WidgetTester t,
    ) async {
      for (final (Size size, double tilesTop, double zone) in <(Size, double, double)>[
        (const Size(852, 393), 264, 581),
        (const Size(667, 375), 250, 484),
      ]) {
        final Rig<Ls01TapSession> r = _rig(_stemPack(), 'stem');
        await r.pump(t, size: size);
        final Rect row = t.getRect(find.byKey(const Key('ls01-row')));
        expect(row.width, lessThanOrEqualTo(zone + 0.5));
        await r.done(t);
        expect(tilesTop, greaterThan(0));
      }
    });
  });
}
