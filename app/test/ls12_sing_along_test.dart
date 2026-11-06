// LS12, the sing-along template (docs/languages/frame.md section 2.3; L4): a chant, whose lines are said one after another with their
// pictures lit and which writes nothing, and a rhyme, whose verse stops before its last word and asks a scored choice. Spoken to a beat:
// no melody. Fixture course and fake clips, not content.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/hint_ladder.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/content/pack_validation.dart';
import 'package:nitznutz/content/schema.dart';
import 'package:nitznutz/content/schemas.dart';
import 'package:nitznutz/play/lesson_controller.dart';
import 'package:nitznutz/play/sing_along_session.dart';

import 'support/l4_rig.dart';
import 'support/language_content.dart';
import 'support/sample_pack.dart';

List<Problem> _run(SamplePack p) => validatePack(manifest: p.manifest, docs: p.docs, files: p.files);

List<String> _messages(LangPack p) => <String>[
  for (final Problem x in _run(p.pack)) '${x.path}: ${x.message}',
];

const List<String> _pictures = <String>['cat', 'dog', 'duck', 'rabbit', 'cup', 'sock'];

Map<String, Object?> _chant(LangPack p) {
  final String c = p.course;
  return singJson(
    course: c,
    id: 'chant',
    pictures: <Map<String, Object?>>[
      songPicture('cat', clip: 'vo:$c.w.cat'),
      songPicture('dog', clip: 'vo:$c.w.dog'),
      songPicture('duck'),
    ],
    lines: <Map<String, Object?>>[
      <String, Object?>{
        'clips': <String>['vo:$c.ch.1'],
        'lights': <int>[0],
      },
      <String, Object?>{
        'clips': <String>['vo:$c.ch.2', 'vo:$c.ch.2b'],
        'lights': <int>[1, 2],
      },
      <String, Object?>{
        'clips': <String>['vo:$c.ch.3'],
        'lights': <int>[],
      },
    ],
  );
}

/// A rhyme (the Hebrew verse 1 of the batch, in shape): the verse whole, up to the gap, whole again, and the end word of line one.
Map<String, Object?> _rhyme(LangPack p) {
  final String c = p.course;
  return singJson(
    course: c,
    id: 'rhyme',
    pictures: <Map<String, Object?>>[songPicture('rabbit'), songPicture('cat')],
    verse: <String, Object?>{
      'whole': <String>['vo:$c.v1.whole'],
      'open': <String>['vo:$c.v1.open'],
      'full': <String>['vo:$c.v1.full'],
      'cue': <String>['vo:$c.v1.e'],
    },
    options: <Map<String, Object?>>[
      pictureOption('o1', 'rabbit', clip: 'vo:$c.w.rabbit'),
      pictureOption('o2', 'cup', tag: p.tag('lis.guess'), clip: 'vo:$c.w.cup'),
      pictureOption('o3', 'cat', tag: p.tag('lis.sem'), clip: 'vo:$c.w.cat'),
    ],
    correct: 'o1',
  );
}

LangPack _pack(String kind, {String course = 'eng'}) {
  final LangPack p = LangPack(course)..addPictures(_pictures);
  p.add(kind == 'chant' ? _chant(p) : _rhyme(p));
  return p;
}

Rig<SingAlongSession> _rig(LangPack p, String id) => Rig<SingAlongSession>(
  p,
  id,
  (LessonController c, Activity a) => SingAlongSession(c, a as SingAlongActivity),
);

void main() {
  group('the document', () {
    test('a chant and a rhyme pass the validator and read as their model', () {
      expect(_messages(_pack('chant')), isEmpty);
      expect(_messages(_pack('rhyme')), isEmpty);
      final SingAlongActivity chant = _pack('chant').content.activities['eng.chant']! as SingAlongActivity;
      expect(chant.rhyme, isFalse);
      expect(chant.lines, hasLength(3));
      expect(chant.lines[1].lights, <int>[1, 2]);
      expect(chant.lines[1].clips, <String>['vo:eng.ch.2', 'vo:eng.ch.2b']);
      expect(chant.pictures[0].clip, 'vo:eng.w.cat');
      expect(chant.optionCount, 0);
      final SingAlongActivity rhyme = _pack('rhyme').content.activities['eng.rhyme']! as SingAlongActivity;
      expect(rhyme.rhyme, isTrue);
      expect(rhyme.verse.cue, <String>['vo:eng.v1.e']);
      expect(rhyme.question!.vo, 'vo:eng.rhyme.q');
      expect(rhyme.engineTags, <String>{'eng.lis.guess', 'eng.lis.sem'});
      expect(rhyme.llmAllowed, isFalse);
    });

    test('the template is known and its ladder changes the representation at level 2', () {
      expect(supportedTemplates['sing_along'], '1.0');
      expect(allSchemas.containsKey('activity.sing_along'), isTrue);
      expect(HintLadder.problemWith('sing_along'), isNull);
      expect(HintLadder.of('sing_along')!.pictures, <HintPicture>[
        HintPicture.replayPart,
        HintPicture.endsAlone,
        HintPicture.demonstration,
      ]);
    });

    test(
      'a chant is practice with two lines at least, no gap, no question; its lights are pictures of the song',
      () {
        final LangPack a = _pack('chant');
        a.activity('chant')['purpose'] = 'learn';
        expect(_messages(a), contains(contains('purpose: a chant is never scored')));
        final LangPack b = _pack('chant');
        ((b.activity('chant')['scene']! as Map<String, Object?>)['lines']! as List<Object?>).removeRange(
          1,
          3,
        );
        expect(_messages(b), contains(contains('scene.lines: a chant has at least two lines')));
        final LangPack c = _pack('chant');
        (((c.activity('chant')['scene']! as Map<String, Object?>)['lines']! as List<Object?>)[0]!
            as Map<String, Object?>)['lights'] = <int>[
          4,
        ];
        expect(
          _messages(c),
          contains(contains('scene.lines[0].lights[0]: is not one of the 3 pictures of the song')),
        );
        final LangPack d = _pack('chant');
        (d.activity('chant')['scene']! as Map<String, Object?>)['verse'] = <String, Object?>{
          'whole': <String>['vo:eng.v.w'],
          'open': <String>['vo:eng.v.o'],
          'full': <String>['vo:eng.v.f'],
          'cue': <String>['vo:eng.v.c'],
        };
        expect(_messages(d), contains(contains('scene.verse: a chant is its lines')));
      },
    );

    test('a rhyme needs its verse and its question, pictures to choose, and every distractor tagged', () {
      final LangPack a = _pack('rhyme');
      (a.activity('rhyme')['scene']! as Map<String, Object?>).remove('verse');
      expect(_messages(a), contains(contains('scene.verse: a rhyme needs its verse')));
      final LangPack b = _pack('rhyme');
      ((b.activity('rhyme')['scene']! as Map<String, Object?>)['verse']! as Map<String, Object?>).remove(
        'cue',
      );
      expect(_messages(b), contains(contains('scene.verse: missing "cue"')));
      final LangPack c = _pack('rhyme');
      (c.activity('rhyme')['answer']! as Map<String, Object?>).remove('question');
      expect(_messages(c), contains(contains('answer.question: a rhyme asks which word fits the end')));
      final LangPack d = _pack('rhyme');
      (((d.activity('rhyme')['answer']! as Map<String, Object?>)['options']! as List<Object?>)[1]!
              as Map<String, Object?>)
          .remove('misconception');
      expect(_messages(d), contains(contains('a distractor carries the misconception it shows')));
      final LangPack e = _pack('rhyme');
      final Map<String, Object?> o =
          ((e.activity('rhyme')['answer']! as Map<String, Object?>)['options']! as List<Object?>)[0]!
              as Map<String, Object?>;
      o
        ..remove('sprite')
        ..['text'] = 'rabbit';
      expect(
        _messages(e),
        contains(contains('answer.options[0].sprite: a rhyme is completed by choosing a picture')),
      );
    });

    test('a pack of the lands refuses a song', () {
      final SamplePack core = SamplePack();
      final Map<String, Object?> doc = Map<String, Object?>.of(_pack('chant').activity('chant'))
        ..remove('course')
        ..['domain'] = 'numbers'
        ..['skills'] = <Object?>[
          <String, Object?>{'id': 'NUM-A-03', 'weight': 1},
        ];
      core.addDocument('activity.chant.json', 'activities', 'chant', doc);
      (core.manifest['templates']! as Map<String, Object?>)['sing_along'] = '1.0';
      expect(
        _run(core).map((Problem x) => '${x.path}: ${x.message}'),
        contains('activity.chant.json › template: sing_along belongs to a language course, not to the lands'),
      );
    });
  });

  group('a chant', () {
    testWidgets('says its lines one after another, with the pictures of a line lit, and writes nothing', (
      WidgetTester t,
    ) async {
      final Rig<SingAlongSession> r = _rig(_pack('chant'), 'chant');
      await r.pump(t);
      await r.wait(t, 200);
      expect(r.session.litLine, 0);
      expect(r.session.lit, <int>{0});
      expect(r.heard.calls, <String>['after vo:eng.ch.1']);
      await r.wait(t, 1000);
      expect(r.session.litLine, 1);
      expect(r.session.lit, <int>{1, 2});
      expect(r.heard.calls.last, 'after vo:eng.ch.2 vo:eng.ch.2b');
      await r.wait(t, 1000);
      expect(r.session.litLine, 2);
      expect(r.session.lit, isEmpty);
      await r.wait(t, 1000);
      // the chant is over: the warm line, and the lesson goes on; nothing was written
      expect(r.controller.solved, isTrue);
      expect(r.controller.bubble, 'נָכוֹן!');
      await r.wait(t, 1700);
      expect(r.controller.finished, isTrue);
      expect(r.attempts, isEmpty);
      await r.done(t);
    });

    testWidgets('a touch on a picture says its word and rings it; the chant goes on', (WidgetTester t) async {
      final Rig<SingAlongSession> r = _rig(_pack('chant'), 'chant');
      await r.pump(t);
      await r.wait(t, 100);
      await t.tap(find.byKey(const Key('song-picture-1')));
      await r.wait(t, 100);
      expect(r.heard.calls.last, 'now vo:eng.w.dog');
      expect(r.session.touched, 1);
      await r.wait(t, 800);
      expect(r.session.touched, isNull);
      // a picture without a word of its own says nothing and does nothing else
      final int calls = r.heard.calls.length;
      await t.tap(find.byKey(const Key('song-picture-2')));
      await r.wait(t, 100);
      expect(r.heard.calls.length, calls);
      await r.done(t);
    });

    testWidgets('the replay button sings it again from the first line and says no line of its own', (
      WidgetTester t,
    ) async {
      final Rig<SingAlongSession> r = _rig(_pack('chant'), 'chant');
      await r.pump(t);
      await r.wait(t, 1300);
      expect(r.session.litLine, 1);
      final int nonce = r.controller.voiceNonce;
      await t.tap(find.byKey(const Key('lesson-replay')));
      await r.wait(t, 100);
      expect(r.controller.voiceNonce, nonce);
      expect(r.session.litLine, 0);
      expect(r.heard.calls.last, 'now vo:eng.ch.1');
      // the first run does not go on to finish the chant behind the second
      await r.wait(t, 3000);
      expect(r.attempts, isEmpty);
      await r.done(t);
    });

    testWidgets('a Hebrew chant lays its pictures out from the right', (WidgetTester t) async {
      final Rig<SingAlongSession> heb = _rig(_pack('chant', course: 'heb'), 'chant');
      await heb.pump(t);
      expect(
        t.getCenter(find.byKey(const Key('song-picture-0'))).dx,
        greaterThan(t.getCenter(find.byKey(const Key('song-picture-2'))).dx),
      );
      await heb.done(t);
      final Rig<SingAlongSession> eng = _rig(_pack('chant'), 'chant');
      await eng.pump(t);
      expect(
        t.getCenter(find.byKey(const Key('song-picture-0'))).dx,
        lessThan(t.getCenter(find.byKey(const Key('song-picture-2'))).dx),
      );
      await eng.done(t);
    });
  });

  group('a rhyme', () {
    testWidgets('is heard whole, stops before its last word, and asks; the choices come with the question', (
      WidgetTester t,
    ) async {
      final Rig<SingAlongSession> r = _rig(_pack('rhyme'), 'rhyme');
      await r.pump(t);
      await r.wait(t, 100);
      expect(find.byKey(const Key('tile-o1')), findsNothing, reason: 'no choice before the gap');
      await r.wait(t, 1600);
      expect(r.heard.calls, <String>['after vo:eng.v1.whole', 'after vo:eng.v1.open']);
      expect(r.session.asking, isTrue);
      expect(r.controller.voice, 'vo:eng.rhyme.q');
      expect(find.byKey(const Key('tile-o1')), findsOneWidget);
      await r.done(t);
    });

    testWidgets(
      'the right picture: one correct attempt, the recast, then the whole verse, then the lesson goes on',
      (WidgetTester t) async {
        final Rig<SingAlongSession> r = _rig(_pack('rhyme'), 'rhyme');
        await r.pump(t);
        await r.wait(t, 1800);
        r.heard.clear();
        await t.tap(r.tile('o1'));
        await r.wait(t, 100);
        expect(r.written, <String>['correct:o1']);
        expect(r.controller.voice, 'vo:eng.rhyme.right');
        await r.wait(t, 1700);
        expect(r.heard.calls, contains('now vo:eng.w.rabbit'));
        expect(r.heard.calls.last, 'after vo:eng.v1.full');
        await r.wait(t, 1000);
        expect(r.controller.finished, isTrue);
        await r.done(t);
      },
    );

    testWidgets(
      'a wrong picture is a tagged mistake; the ladder says the end word, then the ends alone, then shows',
      (WidgetTester t) async {
        final Rig<SingAlongSession> r = _rig(_pack('rhyme'), 'rhyme');
        await r.pump(t);
        await r.wait(t, 1800);
        await t.tap(r.tile('o2'));
        await r.wait(t, 100);
        expect(r.attempts.single.misconceptionTag, 'eng.lis.guess');
        r.heard.clear();
        await r.wait(t, 1300);
        expect(r.controller.hintShown, 1);
        expect(
          r.heard.calls,
          contains('after vo:eng.v1.e'),
          reason: 'level 1: the end word of the first line again',
        );
        // level 2: the end word before each option, the option lit while its pair is said
        await t.tap(r.tile('o3'));
        r.heard.clear();
        await r.wait(t, 1300);
        expect(r.controller.hintShown, 2);
        final List<int?> lit = <int?>[];
        for (int i = 0; i < 6; i++) {
          lit.add(r.session.litTile);
          await r.wait(t, 700);
        }
        expect(lit.whereType<int>().toSet(), <int>{0, 1, 2});
        expect(
          r.heard.clips.where((String c) => c.startsWith('vo:eng.v1.e') || c.startsWith('vo:eng.w.')),
          <String>[
            'vo:eng.v1.e',
            'vo:eng.w.rabbit',
            'vo:eng.v1.e',
            'vo:eng.w.cup',
            'vo:eng.v1.e',
            'vo:eng.w.cat',
          ].where((String c) => true),
        );
        // level 3: the right picture is shown, and only it is taken
        await t.tap(r.tile('o3'));
        await r.wait(t, 1500);
        expect(r.controller.hintShown, 3);
        expect(r.controller.answerShown, isTrue);
        await t.tap(r.tile('o2'));
        await r.wait(t, 100);
        expect(r.attempts, hasLength(3));
        await t.tap(r.tile('o1'));
        await r.wait(t, 100);
        expect(r.attempts.last.result, 'correct');
        expect(r.attempts.last.hintLevel, 3);
        await r.done(t);
      },
    );

    testWidgets('the replay button at the gap says the question again', (WidgetTester t) async {
      final Rig<SingAlongSession> r = _rig(_pack('rhyme'), 'rhyme');
      await r.pump(t);
      await r.wait(t, 1800);
      final int nonce = r.controller.voiceNonce;
      await t.tap(find.byKey(const Key('lesson-replay')));
      await r.wait(t, 100);
      expect(r.controller.voiceNonce, greaterThan(nonce));
      expect(r.controller.voice, 'vo:eng.rhyme.q');
      await r.done(t);
    });
  });

  test('the new file has no timer, countdown or streak (the child space has none)', () {
    final RegExp banned = RegExp('timer|countdown|streak|stopwatch', caseSensitive: false);
    for (final String line in File('lib/play/sing_along_session.dart').readAsLinesSync()) {
      if (line.trimLeft().startsWith('//')) continue;
      expect(banned.hasMatch(line), isFalse, reason: line);
    }
  });
}
