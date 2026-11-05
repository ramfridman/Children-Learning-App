// LS09 say it with me on the lesson screen (docs/languages/frame.md sections 2.3 and 5.1): echo when the parent's voice switch for the
// language is off or no model is on the phone; with it on, a microphone that opens only on a tap, the per-word matcher's confident
// or unsure (never wrong), the one more try, the picture tap that goes on, what is written and what is not, and the quiet fallback.
// A fake recogniser and fake clips; no real voice, no model.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/models.dart';
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/design/components.dart';
import 'package:nitznutz/parent/language_settings.dart';
import 'package:nitznutz/play/lesson_screen.dart';
import 'package:nitznutz/speech/answer_matcher.dart' show Hypothesis;

import 'support/app_harness.dart';
import 'support/fake_speech.dart';
import 'support/harness.dart';
import 'support/language_content.dart';
import 'support/language_screens.dart' show langKid;
import 'support/language_voice.dart';
import 'support/voice_fixtures.dart';

Set<String> _refs(LangPack p) {
  final Set<String> out = <String>{};
  void scan(Object? n) {
    if (n is String && n.startsWith('vo:')) out.add(n);
    if (n is Map<String, Object?>) n.values.forEach(scan);
    if (n is List<Object?>) n.forEach(scan);
  }

  scan(p.pack.docs);
  return out;
}

Future<void> _wait(WidgetTester t, int ms) async {
  for (int spent = 0; spent < ms; spent += 100) {
    await t.pump(const Duration(milliseconds: 100));
  }
  await t.pump(const Duration(milliseconds: 50));
}

LangPack _pack({bool scored = false, int items = 1}) {
  final LangPack p = LangPack();
  for (int i = 1; i <= items; i++) {
    p.add(sayJson(id: 'cat$i', scored: scored));
  }
  return p;
}

/// The lesson of the say-it items of [p] on the screen, with the parent's voice switch for English [voice] and the fake model
/// [installed].
Future<AppRig> _open(
  WidgetTester t,
  LangPack p, {
  bool voice = false,
  bool installed = true,
  List<Scripted> script = const <Scripted>[],
}) async {
  final PackContent content = p.content;
  final AppRig rig = AppRig(
    content: content,
    characters: await languageVoiceSource(_refs(p)),
    player: FakePlayer()..endsAfter = const Duration(milliseconds: 150),
    speech: FakeSpeechEngine(script)..installed = installed,
  );
  await rig.seedFinishedSetup(name: 'נֹעָה', id: langKid);
  await rig.db.putSetting(
    languagesSettingKey,
    const FamilyLanguages().withSwitches(langKid, 'eng', LanguageSwitches(on: true, voice: voice))!.encode(),
  );
  await rig.pump(t);
  await t.tap(find.text('נֹעָה'));
  await t.pumpAndSettle();
  final List<String> ids = <String>[
    for (final Activity a in content.activities.values)
      if (a is SayItActivity) a.id,
  ]..sort();
  t
      .state<NavigatorState>(find.byType(Navigator).first)
      .push(
        MaterialPageRoute<void>(
          builder: (BuildContext c) => LessonScreen(
            profileId: langKid,
            mission: Lesson.mission(
              id: 'say',
              itemIds: ids,
              skillIds: <String>[content.activities[ids.first]!.skillId],
              celebration: const Spoken(vo: 'vo:x.celebrate', caption: 'x'),
            ),
          ),
        ),
      );
  await t.pump(const Duration(milliseconds: 600));
  await _wait(t, 2500);
  return rig;
}

Finder get _mic => find.byKey(const Key('lesson-mic'));
Finder get _done => find.byKey(const Key('say-done'));
Finder get _picture => find.byKey(const Key('say-picture'));

Future<List<Attempt>> _attempts(AppRig rig) => rig.db.attemptsOf(langKid);

bool _micTappable(WidgetTester t) => t.widget<MicButton>(_mic).onPressed != null;

void main() {
  setUpAll(loadAppFonts);

  group('echo: the voice switch for the language is off', () {
    testWidgets('no microphone, an "I said it" button, nothing listens, nothing is loaded', (
      WidgetTester t,
    ) async {
      final AppRig rig = await _open(t, _pack());
      expect(_mic, findsNothing);
      expect(_done, findsOneWidget);
      expect(<int>[rig.speech.prepares, rig.speech.listens], <int>[0, 0]);
      expect(rig.speech.micOpen, isFalse);
    });

    testWidgets('the voice says the word, waits, and says it again', (WidgetTester t) async {
      final AppRig rig = await _open(t, _pack());
      expect(playedLines(rig.player.played), <String>['eng.cat1.prompt', 'eng.cat1.word']);
      await _wait(t, 3600);
      expect(playedLines(rig.player.played).where((String l) => l == 'eng.cat1.word').length, 2);
    });

    testWidgets('the picture goes on only after "I said it"; an unscored item leaves nothing written', (
      WidgetTester t,
    ) async {
      final AppRig rig = await _open(t, _pack());
      await t.tap(_picture);
      await _wait(t, 300);
      expect(
        find.byKey(const Key('lesson-celebration')),
        findsNothing,
        reason: 'the picture waited for the child',
      );
      await t.tap(_done);
      await _wait(t, 300);
      expect(_done, findsNothing, reason: 'the button has done its work');
      await t.tap(_picture);
      await _wait(t, 3000);
      expect(await _attempts(rig), isEmpty);
    });

    testWidgets('a scored item writes one listening answer when the picture is tapped, and it is a tap', (
      WidgetTester t,
    ) async {
      final AppRig rig = await _open(t, _pack(scored: true));
      await t.tap(_done);
      await _wait(t, 200);
      await t.tap(_picture);
      await _wait(t, 3000);
      final List<Attempt> rows = await _attempts(rig);
      expect(rows.length, 1);
      expect(
        <String>[rows.single.result, rows.single.response, rows.single.input, rows.single.template],
        <String>['correct', 'picture', 'tap', 'say_it'],
      );
    });

    testWidgets('no model on the phone is echo too, even with the switch on', (WidgetTester t) async {
      final AppRig rig = await _open(t, _pack(), voice: true, installed: false);
      expect(_mic, findsNothing);
      expect(_done, findsOneWidget);
      expect(rig.speech.prepares, 0);
    });
  });

  group('with the switch on and the model on the phone', () {
    testWidgets('the microphone is there and does not open by itself', (WidgetTester t) async {
      final AppRig rig = await _open(t, _pack(), voice: true);
      expect(_mic, findsOneWidget);
      expect(_micTappable(t), isTrue);
      await _wait(t, 4000);
      expect(
        <int>[rig.speech.prepares, rig.speech.listens],
        <int>[0, 0],
        reason: 'only a tap opens the microphone',
      );
    });

    testWidgets(
      'a tap listens with the item\'s words as hotwords; the child is heard: one spoken success is written',
      (WidgetTester t) async {
        final AppRig rig = await _open(t, _pack(), voice: true, script: <Scripted>[Scripted.says('Cat')]);
        await t.tap(_mic);
        await _wait(t, 1500);
        expect(rig.speech.listens, 1);
        expect(rig.speech.lastHotwords, <String>['cat', 'a cat', 'cut', 'hat']);
        final List<Attempt> rows = await _attempts(rig);
        expect(rows.length, 1);
        expect(
          <String>[rows.single.result, rows.single.response, rows.single.input],
          <String>['correct', 'said', 'voice'],
        );
        expect(rows.single.misconceptionTag, isEmpty);
        expect(playedLines(rig.player.played).sublist(2), <String>['eng.cat1.heard', 'eng.cat1.word']);
        expect(rig.speech.micOpen, isFalse, reason: 'the microphone is closed');
        expect(_micTappable(t), isFalse, reason: 'there is nothing more to try');
      },
    );

    testWidgets('after being heard the picture goes on; an unscored item adds no second row', (
      WidgetTester t,
    ) async {
      final AppRig rig = await _open(t, _pack(), voice: true, script: <Scripted>[Scripted.says('cat')]);
      await t.tap(_mic);
      await _wait(t, 1500);
      await t.tap(_picture);
      await _wait(t, 3000);
      expect((await _attempts(rig)).length, 1);
    });

    testWidgets(
      'a foil said clearly is unsure: nothing is written, the voice says it together, no "not yet"',
      (WidgetTester t) async {
        final AppRig rig = await _open(t, _pack(), voice: true, script: <Scripted>[Scripted.says('cut')]);
        await t.tap(_mic);
        await _wait(t, 1500);
        expect(await _attempts(rig), isEmpty);
        expect(playedLines(rig.player.played).sublist(2), <String>['eng.cat1.together', 'eng.cat1.word']);
        expect(
          find.byKey(const Key('lesson-hint')),
          findsOneWidget,
          reason: 'the lamp is not lit as for a mistake',
        );
        expect(_micTappable(t), isTrue, reason: 'one more try is offered, by a tap');
      },
    );

    testWidgets('silence is treated the same kind way: together, nothing written', (WidgetTester t) async {
      final AppRig rig = await _open(t, _pack(), voice: true, script: <Scripted>[Scripted.silence()]);
      await t.tap(_mic);
      await _wait(t, 1500);
      expect(await _attempts(rig), isEmpty);
      expect(playedLines(rig.player.played), contains('eng.cat1.together'));
    });

    testWidgets(
      'the one more try can be heard; a second unsure result fades the microphone and the picture goes on',
      (WidgetTester t) async {
        final AppRig rig = await _open(
          t,
          _pack(),
          voice: true,
          script: <Scripted>[Scripted.says('hat'), Scripted.says('kitten')],
        );
        await t.tap(_mic);
        await _wait(t, 1500);
        await t.tap(_mic);
        await _wait(t, 1500);
        expect(rig.speech.listens, 2);
        expect(await _attempts(rig), isEmpty);
        expect(_micTappable(t), isFalse, reason: 'at most one more try, never a loop');
        await t.tap(_picture);
        await _wait(t, 3000);
        expect(find.byKey(const Key('lesson-celebration')), findsOneWidget);
      },
    );

    testWidgets('a good second try is written once, as a spoken success', (WidgetTester t) async {
      final AppRig rig = await _open(
        t,
        _pack(),
        voice: true,
        script: <Scripted>[Scripted.says('hat'), Scripted.says('cat')],
      );
      await t.tap(_mic);
      await _wait(t, 1500);
      await t.tap(_mic);
      await _wait(t, 1500);
      expect((await _attempts(rig)).map((Attempt a) => a.response), <String>['said']);
    });

    testWidgets('a scored item writes the spoken success and then the picture tap', (WidgetTester t) async {
      final AppRig rig = await _open(
        t,
        _pack(scored: true),
        voice: true,
        script: <Scripted>[
          Scripted.nbest(const <Hypothesis>[Hypothesis('cat', 0.9)]),
        ],
      );
      await t.tap(_mic);
      await _wait(t, 1500);
      await t.tap(_picture);
      await _wait(t, 3000);
      expect((await _attempts(rig)).map((Attempt a) => '${a.response}/${a.input}'), <String>[
        'said/voice',
        'picture/tap',
      ]);
    });

    testWidgets('a recogniser that cannot start takes the microphone away quietly and the step is echo', (
      WidgetTester t,
    ) async {
      final AppRig rig = await _open(t, _pack(), voice: true, script: <Scripted>[Scripted.fails()]);
      await t.tap(_mic);
      await _wait(t, 1500);
      expect(_mic, findsNothing);
      expect(_done, findsOneWidget);
      expect(await _attempts(rig), isEmpty);
      expect(rig.speech.micOpen, isFalse);
    });
  });

  group('the quiet fallback', () {
    testWidgets('after three unsure turns the rest of the visit is echo, with no message', (
      WidgetTester t,
    ) async {
      final AppRig rig = await _open(
        t,
        _pack(items: 4),
        voice: true,
        script: <Scripted>[Scripted.says('kitten'), Scripted.says('kitten'), Scripted.says('kitten')],
      );
      for (int i = 0; i < 3; i++) {
        expect(_mic, findsOneWidget, reason: 'turn ${i + 1} has the microphone');
        await t.tap(_mic);
        await _wait(t, 1500);
        await t.tap(_picture);
        await _wait(t, 3000);
      }
      expect(_mic, findsNothing, reason: 'the fourth turn is echo');
      expect(_done, findsOneWidget);
      expect(rig.speech.listens, 3);
    });
  });
}
