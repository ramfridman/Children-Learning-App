// QA's tests of milestone L3 (docs/qa/l3-languages-verification.md): the gaps the developer's tests left, on the points the owner and the
// brief care most about: the matcher has no wrong, the microphone's conditions, what is written, the release gate, the installer.
// Fake recogniser and fake clips; the only native code is never loaded (the tampered model is refused before it).
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nitznutz/content/engine_adapter.dart';
import 'package:nitznutz/data/app_database.dart';
import 'package:nitznutz/design/components.dart';
import 'package:nitznutz/models/model_installer.dart';
import 'package:nitznutz/speech/model_spec.dart';
import 'package:nitznutz/speech/release_gate.dart';
import 'package:nitznutz/speech/sherpa_engine.dart';
import 'package:nitznutz/speech/word_matcher.dart';

import 'support/app_harness.dart';
import 'support/fake_speech.dart';
import 'support/harness.dart';
import 'support/language_screens.dart' show langKid;
import 'support/qa_l3_say.dart';

SpeechModelSpec _tiny(Map<String, List<int>> files) => SpeechModelSpec(
  course: 'eng',
  id: 'tiny',
  folderName: 'speech-model-tiny-1',
  licence: 'test',
  source: 'test',
  revision: 'test',
  modelType: '',
  files: <ModelFile>[
    for (final MapEntry<String, List<int>> e in files.entries)
      ModelFile(e.key, e.value.length, sha256.convert(e.value).toString()),
  ],
);

class _Fetcher implements ModelFetcher {
  _Fetcher(this.bytes);

  final Map<String, List<int>> bytes;
  final List<String> asked = <String>[];

  @override
  Stream<List<int>> fetch(SpeechModelSpec spec, ModelFile file) async* {
    asked.add(file.name);
    yield bytes[file.name]!;
  }
}

Finder get _mic => find.byKey(const Key('lesson-mic'));
Finder get _done => find.byKey(const Key('say-done'));
Finder get _picture => find.byKey(const Key('say-picture'));

Future<List<Attempt>> _attempts(AppRig rig) => rig.db.attemptsOf(langKid);

void main() {
  setUpAll(loadAppFonts);

  group('the matcher has no wrong outcome', () {
    test('the result type has exactly confident, unsure and silence', () {
      expect(SayResult.values.map((SayResult r) => r.name).toList(), <String>[
        'confident',
        'unsure',
        'silence',
      ]);
    });

    const WordMatcher m = WordMatcher();
    const WordTarget cat = WordTarget(course: 'eng', forms: <String>['cat'], foils: <String>['cut', 'hat']);

    test('two readings that disagree (the target, then a foil) cannot be told apart: unsure', () {
      expect(m.decide(<String>['cat', 'hat'], cat).result, SayResult.unsure);
      expect(m.decide(<String>['hat', 'cat'], cat).result, SayResult.unsure);
    });

    test(
      'a garbage reading beside the right one does not spoil it, and beside nothing right it is unsure',
      () {
        expect(m.decide(<String>['xqz', 'cat'], cat).result, SayResult.confident);
        expect(m.decide(<String>['xqz', 'zzzz'], cat).result, SayResult.unsure);
      },
    );

    test(
      'whatever the recogniser reads, the Hebrew and Russian courses give the same three-valued answer',
      () {
        const WordTarget he = WordTarget(course: 'heb', forms: <String>['חתול'], foils: <String>['כלב']);
        expect(m.decide(<String>['חתול'], he).result, SayResult.confident);
        expect(m.decide(<String>['חָתוּל'], he).result, SayResult.confident);
        expect(m.decide(<String>['כלב'], he).result, SayResult.unsure);
        expect(m.decide(<String>[], he).result, SayResult.silence);
      },
    );
  });

  group('the microphone: switch, model and tap', () {
    testWidgets('the switch is the child\'s own: another child\'s switch on opens nothing for this one', (
      WidgetTester t,
    ) async {
      final AppRig rig = await qaOpenSay(t, voice: true, voiceFor: 'someone-else');
      expect(_mic, findsNothing);
      expect(_done, findsOneWidget);
      expect(<int>[rig.speech.prepares, rig.speech.listens], <int>[0, 0]);
    });

    testWidgets('the switch is the course\'s own: Russian voice on opens nothing in an English lesson', (
      WidgetTester t,
    ) async {
      final AppRig rig = await qaOpenSay(t, voice: true, voiceCourse: 'rus');
      expect(_mic, findsNothing);
      expect(rig.speech.listens, 0);
    });

    testWidgets('switch off and the model there: echo, nothing loaded, nothing listening', (
      WidgetTester t,
    ) async {
      final AppRig a = await qaOpenSay(t, voice: false, installed: true);
      expect(_mic, findsNothing);
      expect(<int>[a.speech.prepares, a.speech.listens], <int>[0, 0]);
    });

    testWidgets('echo: "I said it" opens the picture and writes nothing for an unscored item', (
      WidgetTester t,
    ) async {
      final AppRig rig = await qaOpenSay(t, voice: false);
      await t.tap(_picture);
      await qaWait(t, 300);
      expect(await _attempts(rig), isEmpty, reason: 'the picture is not yet a button before "I said it"');
      await t.tap(_done);
      await qaWait(t, 300);
      expect(_done, findsNothing);
      await t.tap(_picture);
      await qaWait(t, 3000);
      expect(await _attempts(rig), isEmpty, reason: 'echo is practice only');
    });

    testWidgets('a long, noisy room: three silences in a row never take the way on away', (
      WidgetTester t,
    ) async {
      final AppRig rig = await qaOpenSay(
        t,
        items: 3,
        script: <Scripted>[Scripted.silence(), Scripted.silence(), Scripted.silence(), Scripted.silence()],
      );
      for (int i = 0; i < 3; i++) {
        await t.tap(_mic);
        await qaWait(t, 1500);
        await t.tap(_picture);
        await qaWait(t, 3000);
      }
      expect(await _attempts(rig), isEmpty, reason: 'silence is no evidence and no mistake');
      expect(rig.speech.listens, 3, reason: 'one listen per item: the child tapped the picture each time');
    });

    testWidgets('after a failure the step is echo and the next item tries the microphone again, quietly', (
      WidgetTester t,
    ) async {
      final AppRig rig = await qaOpenSay(
        t,
        items: 2,
        script: <Scripted>[Scripted.fails(), Scripted.says('cat')],
      );
      await t.tap(_mic);
      await qaWait(t, 1500);
      expect(_mic, findsNothing);
      await t.tap(_done);
      await qaWait(t, 300);
      await t.tap(_picture);
      await qaWait(t, 3500);
      expect(_mic, findsOneWidget, reason: 'the next item offers the microphone again');
      expect(rig.speech.listens, 1, reason: 'but it still does not open by itself');
    });
  });

  group('what a heard word writes, and how the engine reads it', () {
    testWidgets('heard on a scored item: said/voice is speech evidence, the picture tap is a plain answer', (
      WidgetTester t,
    ) async {
      final AppRig rig = await qaOpenSay(t, scored: true, script: <Scripted>[Scripted.says('cat')]);
      await t.tap(_mic);
      await qaWait(t, 1500);
      await t.tap(_picture);
      await qaWait(t, 3000);
      final List<Attempt> rows = await _attempts(rig);
      expect(
        rows.map((Attempt a) => <String>[a.template, a.result, a.input, a.response, a.misconceptionTag]),
        <List<String>>[
          <String>['say_it', 'correct', 'voice', 'said', ''],
          <String>['say_it', 'correct', 'tap', 'picture', ''],
        ],
      );
      expect(rows.map((Attempt a) => eventOf(a).viaSpeech), <bool>[true, false]);
      expect(rows.every((Attempt a) => a.hintLevel == 0), isTrue);
    });

    testWidgets('unsure then unsure then the picture: nothing is written, and the item does not repeat', (
      WidgetTester t,
    ) async {
      final AppRig rig = await qaOpenSay(
        t,
        scored: false,
        script: <Scripted>[Scripted.says('hat'), Scripted.says('cut')],
      );
      await t.tap(_mic);
      await qaWait(t, 1500);
      await t.tap(_mic);
      await qaWait(t, 1500);
      expect(t.widget<MicButton>(_mic).onPressed, isNull, reason: 'at most one more try');
      await t.tap(_picture);
      await qaWait(t, 3000);
      expect(await _attempts(rig), isEmpty);
      expect(find.byKey(const Key('lesson-celebration')), findsOneWidget);
    });
  });

  group('the release gate: bands A, B and C', () {
    const GateCounts good = GateCounts(
      correctReadings: 40,
      correctConfident: 35,
      negativeReadings: 120,
      negativeConfident: 0,
    );

    test('a language passes with A, B and C each passing, and not without one of them', () {
      expect(languageVerdict(<String, GateCounts>{'A': good, 'B': good, 'C': good}), GateVerdict.pass);
      expect(languageVerdict(<String, GateCounts>{'A': good, 'B': good}), GateVerdict.notEnough);
      expect(languageVerdict(<String, GateCounts>{'A': good, 'C': good}), GateVerdict.notEnough);
      expect(languageVerdict(<String, GateCounts>{'B': good, 'C': good}), GateVerdict.notEnough);
      expect(languageVerdict(const <String, GateCounts>{}), GateVerdict.notEnough);
    });

    test('adults alone, however good, never pass a language', () {
      expect(languageVerdict(<String, GateCounts>{'adult': good}), isNot(GateVerdict.pass));
      expect(
        languageVerdict(<String, GateCounts>{'adult': good, 'A': good, 'B': good}),
        isNot(GateVerdict.pass),
      );
    });

    test('one band that fails fails the language, whatever the others say', () {
      const GateCounts bad = GateCounts(
        correctReadings: 40,
        correctConfident: 35,
        negativeReadings: 120,
        negativeConfident: 20,
      );
      expect(languageVerdict(<String, GateCounts>{'A': good, 'B': good, 'C': bad}), GateVerdict.fail);
    });

    test('the bar is the approved one in 20 and not looser: 6 of 100 confident foils fails at once', () {
      const GateCounts six = GateCounts(
        correctReadings: 40,
        correctConfident: 35,
        negativeReadings: 100,
        negativeConfident: 6,
      );
      expect(releaseGate(six).verdict, GateVerdict.fail);
    });

    test('most correct readings: exactly half is not most', () {
      const GateCounts half = GateCounts(
        correctReadings: 40,
        correctConfident: 20,
        negativeReadings: 120,
        negativeConfident: 0,
      );
      expect(releaseGate(half).verdict, GateVerdict.fail);
    });
  });

  group('the model installer and the engine refuse a model that is not the pinned one', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('nn-qa-l3-'));
    tearDown(() {
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    });

    final Map<String, List<int>> good = <String, List<int>>{
      'encoder.int8.onnx': List<int>.generate(3000, (int i) => i % 251),
      'tokens.txt': 'a 0\nb 1\n'.codeUnits,
    };

    List<String> names() =>
        dir.listSync().map((FileSystemEntity e) => e.path.split(Platform.pathSeparator).last).toList()
          ..sort();

    test('a host that ends early, cleanly, is refused: the short file is not kept', () async {
      final SpeechModelSpec spec = _tiny(good);
      final Map<String, List<int>> shortOne = <String, List<int>>{
        'encoder.int8.onnx': good['encoder.int8.onnx']!.sublist(0, 2999),
        'tokens.txt': good['tokens.txt']!,
      };
      final InstallOutcome r = await ModelInstaller(fetcher: _Fetcher(shortOne)).install(spec, dir);
      expect(r, InstallOutcome.rejected);
      expect(names(), isEmpty);
    });

    test('same size, one byte changed: refused; and the install can be run again afterwards', () async {
      final SpeechModelSpec spec = _tiny(good);
      final Map<String, List<int>> flipped = <String, List<int>>{
        'encoder.int8.onnx': List<int>.of(good['encoder.int8.onnx']!)..[2999] ^= 0x80,
        'tokens.txt': good['tokens.txt']!,
      };
      expect(await ModelInstaller(fetcher: _Fetcher(flipped)).install(spec, dir), InstallOutcome.rejected);
      expect(names(), isEmpty);
      expect(await ModelInstaller(fetcher: _Fetcher(good)).install(spec, dir), InstallOutcome.installed);
      expect(spec.verifySync(dir), isEmpty);
    });

    test(
      'the first file right and the second wrong: the second leaves nothing, the first is the verified one',
      () async {
        final SpeechModelSpec spec = _tiny(good);
        final Map<String, List<int>> secondBad = <String, List<int>>{
          'encoder.int8.onnx': good['encoder.int8.onnx']!,
          'tokens.txt': 'a 0\nb 2\n'.codeUnits,
        };
        expect(
          await ModelInstaller(fetcher: _Fetcher(secondBad)).install(spec, dir),
          InstallOutcome.rejected,
        );
        expect(names(), <String>['encoder.int8.onnx']);
        expect(spec.verifySync(dir), <String>[
          'tokens.txt',
        ], reason: 'the set is not complete, so it is not trusted');
        expect(spec.looksInstalled(dir), isFalse);
      },
    );

    test('the first file, wrong and already under its real name, is deleted even when there is no host to fetch the right one', () async {
      final SpeechModelSpec spec = _tiny(good);
      File('${dir.path}/encoder.int8.onnx').writeAsStringSync('damaged');
      expect(await const ModelInstaller().install(spec, dir), InstallOutcome.unavailable);
      expect(names().contains('encoder.int8.onnx'), isFalse);
    });

    test(
      'a model whose sizes are right but one byte is not: looks installed, yet the engine will not load it',
      () async {
        final SpeechModelSpec spec = _tiny(good);
        for (final MapEntry<String, List<int>> e in good.entries) {
          File('${dir.path}/${e.key}').writeAsBytesSync(e.value);
        }
        File('${dir.path}/encoder.int8.onnx')
            .writeAsBytesSync(List<int>.of(good['encoder.int8.onnx']!)..[7] ^= 1);
        final SherpaEngine engine = SherpaEngine(spec: spec, modelDir: () async => dir);
        expect(await engine.modelInstalled(), isTrue, reason: 'the quick look checks sizes only');
        await expectLater(engine.prepare(), throwsA(isA<Object>()));
        expect(engine.ready, isFalse, reason: 'a model that is not the pinned one is never loaded');
        await engine.dispose();
      },
    );
  });
}
