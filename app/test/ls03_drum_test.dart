// LS03 in drum mode (docs/languages/frame.md section 2.3; L4): the word is heard with its picture and the child taps a drum once for each
// part. A free response: the right count, one more and one fewer mapped to tags (the Hebrew and Russian courses give both the same tag),
// any other count a retry with no tag; the count shown as dots, never as a number; the three-step ladder. Fixture course, fake clips.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/hint_ladder.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/content/pack_validation.dart';
import 'package:nitznutz/content/schema.dart';
import 'package:nitznutz/content/schemas.dart';
import 'package:nitznutz/design/components.dart' show AnswerState;
import 'package:nitznutz/play/lesson_controller.dart';
import 'package:nitznutz/play/response_code.dart';
import 'package:nitznutz/play/sound_boxes_session.dart';

import 'support/l4_rig.dart';
import 'support/language_content.dart';
import 'support/sample_pack.dart';

List<Problem> _run(SamplePack p) => validatePack(manifest: p.manifest, docs: p.docs, files: p.files);

List<String> _messages(LangPack p) => <String>[
  for (final Problem x in _run(p.pack)) '${x.path}: ${x.message}',
];

const List<String> _pictures = <String>['cat', 'duck', 'banana'];

/// English: one beat more is `pa.syll`, one fewer `pa.weak_syll` (frame section 2.3 LS03); Hebrew and Russian use one tag either way.
LangPack _pack({String course = 'eng', int beats = 3, String purpose = 'learn', bool drumSound = true}) {
  final LangPack p = LangPack(course)..addPictures(_pictures);
  p.addTag('pa.syll', 'diagnostic');
  if (course == 'eng') p.addTag('pa.weak_syll', 'diagnostic');
  p.add(
    drumJson(
      course: course,
      id: 'drum1',
      beats: beats,
      purpose: purpose,
      picture: 'banana',
      drumSound: drumSound,
      more: p.tag('pa.syll'),
      fewer: course == 'eng' ? p.tag('pa.weak_syll') : p.tag('pa.syll'),
    ),
  );
  return p;
}

Rig<SoundBoxesSession> _rig(LangPack p) => Rig<SoundBoxesSession>(
  p,
  'drum1',
  (LessonController c, Activity a) => SoundBoxesSession(c, a as SoundBoxesActivity),
);

Future<void> _drum(WidgetTester t, Rig<SoundBoxesSession> r, int n) async {
  for (int i = 0; i < n; i++) {
    await t.tap(find.byKey(const Key('drum')));
    await r.wait(t, 300);
  }
}

void main() {
  group('the document', () {
    test('a drum item passes the validator and reads as its model', () {
      expect(_messages(_pack()), isEmpty);
      final SoundBoxesActivity a = _pack().content.activities['eng.drum1']! as SoundBoxesActivity;
      expect(a.beats, 3);
      expect(a.word, <String>['vo:eng.drum1.word']);
      expect(a.slow, <String>['vo:eng.drum1.slow']);
      expect(a.drumClip, 'vo:eng.drum');
      expect(a.optionCount, 0, reason: 'a free response has no options');
      expect(a.engineTags, <String>{'eng.pa.syll', 'eng.pa.weak_syll'});
      expect(a.llmAllowed, isFalse);
    });

    test('a count one more and one fewer are named, any other count is not', () {
      final SoundBoxesActivity eng = _pack().content.activities['eng.drum1']! as SoundBoxesActivity;
      expect(eng.tagFor(4), 'eng.pa.syll');
      expect(eng.tagFor(2), 'eng.pa.weak_syll');
      expect(eng.tagFor(5), '');
      expect(eng.tagFor(1), '');
      expect(eng.tagFor(0), '');
      final SoundBoxesActivity heb =
          _pack(course: 'heb').content.activities['heb.drum1']! as SoundBoxesActivity;
      expect(heb.tagFor(4), 'heb.pa.syll');
      expect(heb.tagFor(2), 'heb.pa.syll', reason: 'in Hebrew and Russian either way is the same tag');
    });

    test('the template is known, versioned, and its ladder changes the representation at level 2', () {
      expect(supportedTemplates['sound_boxes'], '1.0');
      expect(allSchemas.containsKey('activity.sound_boxes'), isTrue);
      expect(HintLadder.problemWith('sound_boxes'), isNull);
      expect(HintLadder.of('sound_boxes')!.pictures, <HintPicture>[
        HintPicture.slowBeats,
        HintPicture.clapEach,
        HintPicture.demonstration,
      ]);
    });

    test('the tags must exist, an accent tag is never a classifier, and a drum item is never a check', () {
      final LangPack a = _pack();
      ((a.activity('drum1')['answer']! as Map<String, Object?>)['classifiers']! as List<Object?>)[0] =
          <String, Object?>{'when': 'one_more', 'misconception': 'eng.pa.nothere'};
      expect(
        _messages(a),
        contains(contains('the tag eng.pa.nothere is not in the misconception catalogue')),
      );
      final LangPack b = _pack();
      ((b.activity('drum1')['answer']! as Map<String, Object?>)['classifiers']! as List<Object?>)[1] =
          <String, Object?>{'when': 'one_fewer', 'misconception': 'eng.spk.accent'};
      expect(
        _messages(b),
        contains(
          contains(
            'is an accent tag: a difference of accent is never marked, so it is never on a classifier',
          ),
        ),
      );
      final LangPack c = _pack(purpose: 'check');
      expect(_messages(c), contains(contains('purpose: a drum item is never a check')));
      final LangPack d = _pack();
      ((d.activity('drum1')['answer']! as Map<String, Object?>)['classifiers']! as List<Object?>)[1] =
          <String, Object?>{'when': 'one_more', 'misconception': 'eng.pa.syll'};
      expect(
        _messages(d),
        contains(contains('classifiers')),
        reason: 'one_more twice is refused by the schema',
      );
    });

    test('the picture must exist; a pack of the lands refuses a drum', () {
      final LangPack p = _pack();
      (p.activity('drum1')['scene']! as Map<String, Object?>)['picture'] = 'asset:nowhere';
      expect(_messages(p), contains(contains('scene.picture: asset:nowhere is not in the manifest assets')));
      final SamplePack core = SamplePack();
      final Map<String, Object?> doc = Map<String, Object?>.of(_pack().activity('drum1'))
        ..remove('course')
        ..['domain'] = 'numbers'
        ..['skills'] = <Object?>[
          <String, Object?>{'id': 'NUM-A-03', 'weight': 1},
        ];
      core.addDocument('activity.drum1.json', 'activities', 'drum1', doc);
      (core.manifest['templates']! as Map<String, Object?>)['sound_boxes'] = '1.0';
      expect(
        _run(core).map((Problem x) => '${x.path}: ${x.message}'),
        contains(
          'activity.drum1.json › template: sound_boxes belongs to a language course, not to the lands',
        ),
      );
    });
  });

  group('the drum', () {
    testWidgets(
      'the word is heard after the instruction; each tap is a beat and a dot, never a number; the check mark is the answer',
      (WidgetTester t) async {
        final Rig<SoundBoxesSession> r = _rig(_pack());
        await r.pump(t);
        await r.wait(t, 100);
        expect(r.heard.calls, <String>['after vo:eng.drum1.word']);
        expect(find.byKey(const Key('drum-picture')), findsOneWidget);
        expect(find.byKey(const Key('drum-dots')), findsOneWidget);
        await _drum(t, r, 3);
        expect(find.byKey(const Key('drum-dot-2')), findsOneWidget);
        expect(find.byKey(const Key('drum-dot-3')), findsNothing);
        expect(
          r.heard.calls.where((String c) => c == 'now vo:eng.drum'),
          hasLength(3),
          reason: 'a beat sounds at each tap',
        );
        expect(
          find.textContaining(RegExp(r'[0-9]')),
          findsNothing,
          reason: 'the count is dots, never a number',
        );
        await t.tap(find.byKey(const Key('drum-done')));
        await r.wait(t, 100);
        expect(r.written, <String>['correct:n=3']);
        expect(ResponseCode.fits(r.attempts.single.response), isTrue);
        await r.wait(t, 1700);
        expect(r.controller.finished, isTrue);
        await r.done(t);
      },
    );

    testWidgets('the check mark waits for a tap, and a tap past the most the drum takes is not counted', (
      WidgetTester t,
    ) async {
      final Rig<SoundBoxesSession> r = _rig(_pack());
      await r.pump(t);
      await t.tap(find.byKey(const Key('drum-done')));
      await r.wait(t, 100);
      expect(r.attempts, isEmpty, reason: 'no tap, no answer');
      await _drum(t, r, 12);
      expect(r.session.taps, SoundBoxesSession.mostTaps);
      await t.tap(find.byKey(const Key('drum-done')));
      await r.wait(t, 100);
      expect(r.attempts, isEmpty, reason: '9 for 3 beats is off by more than one: a retry, nothing written');
      await r.wait(t, 1300);
      expect(r.session.taps, 0);
      // 4 (one more) is written
      await _drum(t, r, 4);
      await t.tap(find.byKey(const Key('drum-done')));
      await r.wait(t, 100);
      expect(r.attempts.single.response, 'n=4');
      await r.done(t);
    });

    testWidgets(
      'one more is the tag of one more, one fewer the tag of one fewer, any other count has no tag; the dots clear',
      (WidgetTester t) async {
        final Rig<SoundBoxesSession> r = _rig(_pack());
        await r.pump(t);
        for (final (int n, String tag) in <(int, String)>[(4, 'eng.pa.syll'), (2, 'eng.pa.weak_syll')]) {
          await _drum(t, r, n);
          await t.tap(find.byKey(const Key('drum-done')));
          await r.wait(t, 100);
          expect(r.attempts.last.result, 'incorrect');
          expect(r.attempts.last.misconceptionTag, tag);
          expect(r.attempts.last.response, 'n=$n');
          expect(r.session.state, AnswerState.notYet);
          await r.wait(t, 1300);
          expect(r.session.taps, 0, reason: 'the child may drum it again');
        }
        final int written = r.attempts.length;
        await _drum(t, r, 6);
        await t.tap(find.byKey(const Key('drum-done')));
        await r.wait(t, 100);
        expect(
          r.attempts,
          hasLength(written),
          reason: 'off by two or more: a retry, no tag, no evidence, nothing written',
        );
        expect(r.controller.hintShown, 2, reason: 'and no help is escalated by it');
        await r.wait(t, 1300);
        expect(r.session.taps, 0, reason: 'the child may drum it again');
        await r.done(t);
      },
    );

    testWidgets('a Hebrew word: one more and one fewer give the same tag', (WidgetTester t) async {
      final Rig<SoundBoxesSession> r = _rig(_pack(course: 'heb'));
      await r.pump(t);
      for (final int n in <int>[4, 2]) {
        await _drum(t, r, n);
        await t.tap(find.byKey(const Key('drum-done')));
        await r.wait(t, 1400);
      }
      expect(r.attempts.map((AttemptRecord a) => a.misconceptionTag).toList(), <String>[
        'heb.pa.syll',
        'heb.pa.syll',
      ]);
      await r.done(t);
    });

    testWidgets(
      'the ladder: the word slowly, then one pair of hands for each beat, then the friend drums it, then only the right count',
      (WidgetTester t) async {
        final Rig<SoundBoxesSession> r = _rig(_pack());
        await r.pump(t);
        await _drum(t, r, 4);
        await t.tap(find.byKey(const Key('drum-done')));
        r.heard.clear();
        await r.wait(t, 1500);
        expect(r.controller.hintShown, 1);
        expect(r.heard.calls, contains('after vo:eng.drum1.slow'), reason: 'level 1: the word slowly');
        // level 2: hands clap once for each beat while each lights
        await _drum(t, r, 2);
        await t.tap(find.byKey(const Key('drum-done')));
        await r.wait(t, 1300);
        expect(r.controller.hintShown, 2);
        await r.wait(t, 800);
        expect(r.session.hands, 1);
        await r.wait(t, 1600);
        expect(r.session.hands, 3);
        expect(find.byIcon(Icons.back_hand_rounded), findsNWidgets(3));
        // level 3: the friend drums it, the dots light one by one, and then they clear for the child
        await _drum(t, r, 4);
        await t.tap(find.byKey(const Key('drum-done')));
        await r.wait(t, 1300);
        expect(r.controller.hintShown, 3);
        expect(r.session.demoRunning, isTrue);
        await r.wait(t, 1700);
        expect(r.session.taps, 2, reason: 'the dots light while the friend drums');
        await r.wait(t, 2500);
        expect(r.session.demoRunning, isFalse);
        expect(r.session.taps, 0);
        expect(r.controller.guided, isTrue);
        // guided: a count that is not the word's is not taken (nothing is written), the right one is
        final int written = r.attempts.length;
        await _drum(t, r, 2);
        await t.tap(find.byKey(const Key('drum-done')));
        await r.wait(t, 100);
        expect(r.attempts, hasLength(written));
        expect(r.session.taps, 0);
        await _drum(t, r, 3);
        await t.tap(find.byKey(const Key('drum-done')));
        await r.wait(t, 100);
        expect(r.attempts.last.result, 'correct');
        expect(r.attempts.last.hintLevel, 3);
        await r.done(t);
      },
    );

    testWidgets('a probe: no lamp, one answer, right or not, and the lesson goes on', (WidgetTester t) async {
      final Rig<SoundBoxesSession> r = _rig(_pack(purpose: 'probe'));
      await r.pump(t);
      expect(r.controller.noHelp, isTrue);
      await _drum(t, r, 2);
      await t.tap(find.byKey(const Key('drum-done')));
      await r.wait(t, 100);
      expect(r.attempts.single.result, 'incorrect');
      expect(r.session.state, AnswerState.selected, reason: 'nothing "not yet" is shown for a probe');
      await r.wait(t, 1700);
      expect(r.controller.finished, isTrue);
      expect(r.attempts, hasLength(1));
      await r.done(t);
    });

    testWidgets(
      'the replay button says the word again; a Hebrew word has its check mark at the left, an English one at the right',
      (WidgetTester t) async {
        final Rig<SoundBoxesSession> r = _rig(_pack(course: 'heb'));
        await r.pump(t);
        await r.wait(t, 100);
        r.heard.clear();
        await t.tap(find.byKey(const Key('lesson-replay')));
        await r.wait(t, 100);
        expect(r.heard.calls, <String>['after vo:heb.drum1.word']);
        expect(
          t.getCenter(find.byKey(const Key('drum-done'))).dx,
          lessThan(t.getCenter(find.byKey(const Key('drum'))).dx),
        );
        await r.done(t);
        final Rig<SoundBoxesSession> e = _rig(_pack());
        await e.pump(t);
        expect(
          t.getCenter(find.byKey(const Key('drum-done'))).dx,
          greaterThan(t.getCenter(find.byKey(const Key('drum'))).dx),
        );
        await e.done(t);
      },
    );
  });

  test('the new file has no timer, countdown or streak (the child space has none)', () {
    final RegExp banned = RegExp('timer|countdown|streak|stopwatch', caseSensitive: false);
    for (final String line in File('lib/play/sound_boxes_session.dart').readAsLinesSync()) {
      if (line.trimLeft().startsWith('//')) continue;
      expect(banned.hasMatch(line), isFalse, reason: line);
    }
  });
}
