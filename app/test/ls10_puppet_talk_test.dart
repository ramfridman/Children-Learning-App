// LS10, the puppet-talk template (docs/languages/frame.md section 2.3 and 5.2; L4): a puppet speaks one turn and the child answers on a
// bubble (scored, with a ladder) or, in a scripted personal turn, on a card or a pass (never scored, never checked, and nothing written,
// logged, synced or kept). Fixture course and fake clips, not content.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/hint_ladder.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/content/pack_validation.dart';
import 'package:nitznutz/content/schema.dart';
import 'package:nitznutz/content/schemas.dart';
import 'package:nitznutz/play/lesson_controller.dart';
import 'package:nitznutz/play/puppet_talk_session.dart';

import 'support/l4_rig.dart';
import 'support/language_content.dart';
import 'support/sample_pack.dart';

List<Problem> _run(SamplePack p) => validatePack(manifest: p.manifest, docs: p.docs, files: p.files);

List<String> _messages(LangPack p) => <String>[
  for (final Problem x in _run(p.pack)) '${x.path}: ${x.message}',
];

const List<String> _pictures = <String>['cat', 'dog', 'duck', 'apple', 'banana', 'bread', 'book'];

/// A card of a personal turn: a picture or a numeral, with the clip of its word.
Map<String, Object?> _card(String id, String label, {String? asset, int? numeral, String? clip}) =>
    <String, Object?>{
      'id': id,
      'label': label,
      'sprite': ?(asset == null ? null : 'asset:$asset'),
      'numeral': ?numeral,
      'clip': ?clip,
    };

Map<String, Object?> _bubble(LangPack p) {
  final String c = p.course;
  return puppetJson(
    course: c,
    id: 'talk',
    mode: 'bubble',
    picture: 'cat',
    key: <String, Object?>{'at': at(0.2, 0.1, 0.5, 0.5)},
    options: <Map<String, Object?>>[
      pictureOption('o1', 'duck', clip: 'vo:$c.b.hello'),
      pictureOption('o2', 'dog', tag: p.tag('lis.sem'), clip: 'vo:$c.b.bye'),
      pictureOption('o3', 'book', tag: p.tag('lis.guess'), clip: 'vo:$c.b.yes'),
    ],
    correct: 'o1',
  );
}

Map<String, Object?> _personal(LangPack p, String topic) {
  final String c = p.course;
  return puppetJson(
    course: c,
    id: 'mine',
    mode: 'personal',
    topic: topic,
    options: topic == 'name'
        ? const <Map<String, Object?>>[]
        : <Map<String, Object?>>[
            if (topic == 'age') ...<Map<String, Object?>>[
              _card('o1', 'three', numeral: 3, clip: 'vo:$c.n.three'),
              _card('o2', 'four', numeral: 4, clip: 'vo:$c.n.four'),
              _card('o3', 'five', numeral: 5, clip: 'vo:$c.n.five'),
            ] else ...<Map<String, Object?>>[
              _card('o1', 'apple', asset: 'apple', clip: 'vo:$c.f.apple'),
              _card('o2', 'banana', asset: 'banana', clip: 'vo:$c.f.banana'),
              _card('o3', 'bread', asset: 'bread', clip: 'vo:$c.f.bread'),
              _card('o4', 'someone else', asset: 'cat'),
            ],
          ],
  );
}

LangPack _pack(String kind, {String course = 'eng'}) {
  final LangPack p = LangPack(course)..addPictures(_pictures);
  p.add(kind == 'bubble' ? _bubble(p) : _personal(p, kind));
  return p;
}

Rig<PuppetTalkSession> _rig(LangPack p, String id, {bool allowed = true}) => Rig<PuppetTalkSession>(
  p,
  id,
  (LessonController c, Activity a) => PuppetTalkSession(c, a as PuppetTalkActivity, personalAllowed: allowed),
);

void main() {
  group('the document', () {
    test('a bubble turn and the four personal turns pass the validator and read as their model', () {
      for (final String kind in <String>['bubble', 'name', 'age', 'likes', 'family']) {
        expect(_messages(_pack(kind)), isEmpty, reason: kind);
      }
      final PuppetTalkActivity b = _pack('bubble').content.activities['eng.talk']! as PuppetTalkActivity;
      expect(b.personal, isFalse);
      expect(b.optionCount, 3);
      expect(b.keyAt, const Rect.fromLTWH(0.2, 0.1, 0.5, 0.5));
      expect(b.engineTags, <String>{'eng.lis.sem', 'eng.lis.guess'});
      final PuppetTalkActivity p = _pack('age').content.activities['eng.mine']! as PuppetTalkActivity;
      expect(p.personal, isTrue);
      expect(p.topic, 'age');
      expect(p.pass!.vo, 'vo:eng.mine.pass');
      expect(p.optionCount, 0, reason: 'a personal turn has no choice that is scored');
      expect(p.engineTags, isEmpty);
      expect(p.llmAllowed, isFalse);
    });

    test('the template is known and its ladder changes the representation at level 2', () {
      expect(supportedTemplates['puppet_talk'], '1.0');
      expect(allSchemas.containsKey('activity.puppet_talk'), isTrue);
      expect(HintLadder.problemWith('puppet_talk'), isNull);
      expect(HintLadder.of('puppet_talk')!.at(2), HintPicture.keyPicture);
    });

    test('a personal turn asks one of the four things, never anything else (frame section 5.2)', () {
      expect(personalTopics, <String>['name', 'age', 'likes', 'family']);
      final LangPack p = _pack('age');
      (p.activity('mine')['answer']! as Map<String, Object?>)['topic'] = 'address';
      expect(_messages(p), contains(contains('answer.topic')));
      final LangPack q = _pack('age');
      (q.activity('mine')['answer']! as Map<String, Object?>).remove('topic');
      expect(_messages(q), contains(contains('answer.topic: a personal turn says what it asks')));
    });

    test('a personal turn has a pass, no right answer, no tag and no voice answer; it is practice, answered by touch', () {
      final LangPack a = _pack('age');
      (a.activity('mine')['answer']! as Map<String, Object?>).remove('pass');
      expect(_messages(a), contains(contains('answer.pass')));
      final LangPack b = _pack('age');
      (b.activity('mine')['answer']! as Map<String, Object?>)['correct'] = 'o1';
      expect(_messages(b), contains(contains('answer.correct: a personal turn has no right answer')));
      final LangPack c = _pack('age');
      (((c.activity('mine')['answer']! as Map<String, Object?>)['options']! as List<Object?>)[0]!
          as Map<String, Object?>)['misconception'] = c.tag(
        'lis.sem',
      );
      expect(_messages(c), contains(contains('nothing is wrong in a personal turn: no tag, no evidence')));
      final LangPack d = _pack('age');
      d.activity('mine')['voiceAnswer'] = true;
      expect(_messages(d), contains(contains('voiceAnswer: a personal turn is answered by touch')));
      final LangPack e = _pack('age');
      e.activity('mine')['purpose'] = 'check';
      expect(_messages(e), contains(contains('purpose: a personal turn is never scored')));
      final LangPack f = _pack('likes');
      ((f.activity('mine')['answer']! as Map<String, Object?>)['options']! as List<Object?>).removeRange(
        1,
        4,
      );
      expect(_messages(f), contains(contains('a personal turn about the likes needs cards to touch')));
    });

    test('a bubble turn is a scored choice of 2 or 3, with a tagged wrong bubble; a pass or a topic is not its business', () {
      final LangPack a = _pack('bubble');
      (a.activity('talk')['answer']! as Map<String, Object?>)['topic'] = 'name';
      expect(_messages(a), contains(contains('answer.topic: only a personal turn has a topic')));
      final LangPack b = _pack('bubble');
      (((b.activity('talk')['answer']! as Map<String, Object?>)['options']! as List<Object?>)[2]!
              as Map<String, Object?>)
          .remove('misconception');
      expect(_messages(b), contains(contains('a distractor carries the misconception it shows')));
      final LangPack c = _pack('bubble');
      ((c.activity('talk')['scene']! as Map<String, Object?>)['key']! as Map<String, Object?>)['at'] = at(
        0.8,
        0.8,
        0.4,
        0.4,
      );
      expect(_messages(c), contains(contains('scene.key.at: reaches outside the picture')));
    });

    test('a pack of the lands refuses a puppet', () {
      final SamplePack core = SamplePack();
      final Map<String, Object?> doc = Map<String, Object?>.of(_pack('bubble').activity('talk'))
        ..remove('course')
        ..['domain'] = 'numbers'
        ..['skills'] = <Object?>[
          <String, Object?>{'id': 'NUM-A-03', 'weight': 1},
        ];
      core.addDocument('activity.talk.json', 'activities', 'talk', doc);
      (core.manifest['templates']! as Map<String, Object?>)['puppet_talk'] = '1.0';
      expect(
        _run(core).map((Problem x) => '${x.path}: ${x.message}'),
        contains('activity.talk.json › template: puppet_talk belongs to a language course, not to the lands'),
      );
    });
  });

  group('an answer bubble', () {
    testWidgets(
      'the puppet speaks its turn in two clips; a speaker plays a bubble without answering; the right one is answered',
      (WidgetTester t) async {
        final Rig<PuppetTalkSession> r = _rig(_pack('bubble'), 'talk');
        await r.pump(t);
        expect(r.controller.voice, 'vo:eng.talk.prompt');
        expect(
          r.controller.voiceTarget,
          'vo:eng.talk.puppet',
          reason: 'the puppet\'s own line is the second clip',
        );
        await t.tap(find.byKey(const Key('speaker-o2')));
        await r.wait(t, 100);
        expect(r.heard.calls.last, 'now vo:eng.b.bye');
        expect(r.attempts, isEmpty, reason: 'a speaker never answers');
        await t.tap(r.tile('o1'));
        await r.wait(t, 100);
        expect(r.written, <String>['correct:o1']);
        expect(
          r.controller.voice,
          'vo:eng.talk.right',
          reason: 'the puppet answers with the item\'s right line',
        );
        await r.wait(t, 1700);
        expect(r.controller.finished, isTrue);
        await r.done(t);
      },
    );

    testWidgets(
      'a wrong bubble is a tagged mistake; level 1 says the puppet\'s line and then each bubble slowly',
      (WidgetTester t) async {
        final Rig<PuppetTalkSession> r = _rig(_pack('bubble'), 'talk');
        await r.pump(t);
        await t.tap(r.tile('o2'));
        await r.wait(t, 100);
        expect(r.attempts.single.misconceptionTag, 'eng.lis.sem');
        r.heard.clear();
        await r.wait(t, 3500);
        expect(r.controller.hintShown, 1);
        expect(r.heard.clips, <String>[
          'vo:eng.talk.prompt',
          'vo:eng.talk.puppet',
          'vo:eng.b.hello',
          'vo:eng.b.bye',
          'vo:eng.b.yes',
        ]);
        await r.done(t);
      },
    );

    testWidgets(
      'level 2 makes the key picture of the scene glow; level 3 shows the bubble, and only it is taken',
      (WidgetTester t) async {
        final Rig<PuppetTalkSession> r = _rig(_pack('bubble'), 'talk');
        await r.pump(t);
        expect(find.byKey(const Key('puppet-key')), findsNothing);
        await t.tap(r.tile('o2'));
        await r.wait(t, 1300);
        await t.tap(r.tile('o3'));
        await r.wait(t, 1300);
        expect(r.controller.hintShown, 2);
        expect(find.byKey(const Key('puppet-key')), findsOneWidget);
        await t.tap(r.tile('o3'));
        await r.wait(t, 1500);
        expect(r.controller.guided, isTrue);
        expect(r.controller.answerShown, isTrue);
        await t.tap(r.tile('o2'));
        await r.wait(t, 100);
        expect(r.attempts, hasLength(3));
        await t.tap(r.tile('o1'));
        await r.wait(t, 100);
        expect(r.attempts.last.result, 'correct');
        await r.done(t);
      },
    );

    testWidgets('a Hebrew puppet has its bubbles from the right', (WidgetTester t) async {
      final Rig<PuppetTalkSession> r = _rig(_pack('bubble', course: 'heb'), 'talk');
      await r.pump(t);
      expect(t.getCenter(r.tile('o1')).dx, greaterThan(t.getCenter(r.tile('o3')).dx));
      await r.done(t);
    });
  });

  group('a personal turn', () {
    testWidgets(
      'a card: its word is said as the word itself, then the puppet\'s warm reply; nothing is written',
      (WidgetTester t) async {
        final Rig<PuppetTalkSession> r = _rig(_pack('age'), 'mine');
        await r.pump(t);
        expect(find.byKey(const Key('card-o3')), findsOneWidget);
        await t.tap(find.byKey(const Key('card-o3')));
        await r.wait(t, 100);
        expect(r.heard.calls.last, 'now vo:eng.n.five');
        expect(
          r.controller.voice,
          'vo:eng.mine.right',
          reason: 'the generic reply, which repeats nothing of the child',
        );
        expect(r.controller.bubble, 'נָכוֹן!');
        expect(r.attempts, isEmpty);
        expect(r.controller.errors, 0);
        expect(r.controller.hintLevel, 0);
        await r.wait(t, 1700);
        expect(r.controller.finished, isTrue);
        expect(r.attempts, isEmpty, reason: 'no attempt, so no evidence, no log and no sync');
        // the session keeps no answer: nothing of the card remains
        expect(r.session.chosenId, isNull);
        expect(r.session.chosenState.name, 'idle');
        await r.done(t);
      },
    );

    testWidgets('the pass is always there: the puppet says "that\'s OK" and the lesson goes on', (
      WidgetTester t,
    ) async {
      for (final String kind in <String>['age', 'likes', 'name']) {
        final Rig<PuppetTalkSession> r = _rig(_pack(kind), 'mine');
        await r.pump(t);
        expect(find.byKey(const Key('personal-pass')), findsOneWidget, reason: kind);
        await t.tap(find.byKey(const Key('personal-pass')));
        await r.wait(t, 100);
        expect(r.controller.voice, 'vo:eng.mine.pass', reason: kind);
        await r.wait(t, 1700);
        expect(r.controller.finished, isTrue, reason: kind);
        expect(r.attempts, isEmpty, reason: kind);
        await r.done(t);
      }
    });

    testWidgets('a name turn has no card: "I said it" and the pass, and neither is checked or kept', (
      WidgetTester t,
    ) async {
      final Rig<PuppetTalkSession> r = _rig(_pack('name'), 'mine');
      await r.pump(t);
      expect(find.byKey(const Key('personal-said')), findsOneWidget);
      expect(find.byKey(const Key('card-o1')), findsNothing);
      await t.tap(find.byKey(const Key('personal-said')));
      await r.wait(t, 100);
      expect(r.controller.voice, 'vo:eng.mine.right');
      await r.wait(t, 1700);
      expect(r.controller.finished, isTrue);
      expect(r.attempts, isEmpty);
      await r.done(t);
    });

    testWidgets('a second touch after the answer does nothing; no card is a mistake', (WidgetTester t) async {
      final Rig<PuppetTalkSession> r = _rig(_pack('likes'), 'mine');
      await r.pump(t);
      await t.tap(find.byKey(const Key('card-o1')));
      await r.wait(t, 100);
      final int nonce = r.controller.voiceNonce;
      await t.tap(find.byKey(const Key('card-o2')));
      await t.tap(find.byKey(const Key('personal-pass')));
      await r.wait(t, 100);
      expect(r.controller.voiceNonce, nonce, reason: 'the turn is over');
      expect(r.attempts, isEmpty);
      await r.done(t);
    });

    testWidgets(
      'with the parent\'s switch off the puppet has answered its own question: no card, and the lesson goes on',
      (WidgetTester t) async {
        final Rig<PuppetTalkSession> r = _rig(_pack('likes'), 'mine', allowed: false);
        await r.pump(t);
        expect(find.byKey(const Key('card-o1')), findsNothing);
        expect(find.byKey(const Key('personal-pass')), findsNothing);
        await r.wait(t, 1700);
        expect(r.controller.finished, isTrue);
        expect(r.attempts, isEmpty);
        await r.done(t);
      },
    );

    testWidgets(
      'no help is offered that could lead to a result: a personal turn has the lamp but nothing to be right about',
      (WidgetTester t) async {
        final Rig<PuppetTalkSession> r = _rig(_pack('age'), 'mine');
        await r.pump(t);
        await t.tap(find.byKey(const Key('card-o2')));
        await r.wait(t, 100);
        await t.tap(find.byKey(const Key('lesson-hint')));
        await r.wait(t, 100);
        expect(r.controller.hintShown, 0, reason: 'after the answer a touch is no move');
        expect(r.attempts, isEmpty);
        await r.done(t);
      },
    );
  });

  test('the new file has no timer, countdown or streak (the child space has none)', () {
    final RegExp banned = RegExp('timer|countdown|streak|stopwatch', caseSensitive: false);
    for (final String line in File('lib/play/puppet_talk_session.dart').readAsLinesSync()) {
      if (line.trimLeft().startsWith('//')) continue;
      expect(banned.hasMatch(line), isFalse, reason: line);
    }
  });
}
