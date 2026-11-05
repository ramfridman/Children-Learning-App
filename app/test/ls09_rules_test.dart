// The rules of the language speech code, as source rules (like source_rules_m4_test.dart): the child-safety lines of CLAUDE.md that
// the code of L3 must keep, checked where they would be broken. No audio is stored or sent, nothing is shown from the recogniser's
// text, the microphone is opened by one place only, and a word check has no "wrong".
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _code(String path) =>
    File(path).readAsLinesSync().where((String l) => !l.trimLeft().startsWith('//')).join('\n');

void main() {
  const List<String> speechFiles = <String>[
    'lib/speech/word_matcher.dart',
    'lib/speech/word_text.dart',
    'lib/speech/model_registry.dart',
    'lib/play/say_step.dart',
    'lib/play/say_it_session.dart',
  ];

  test('the language speech code has no network, no file writing of audio and no log of what was heard', () {
    final RegExp bad = RegExp(
      r'(HttpClient|package:http|package:dio|Socket|WebSocket|Uri\.parse|writeAsBytes|writeAsString|openWrite|Log\.|print\(|debugPrint)',
    );
    for (final String f in speechFiles) {
      final String src = _code(f);
      if (f.endsWith('model_registry.dart')) {
        // The installer writes model files (not audio), and only from a fetcher it is given.
        expect(src.contains('HttpClient'), isFalse, reason: f);
        expect(src.contains('package:http'), isFalse, reason: f);
        continue;
      }
      expect(bad.hasMatch(src), isFalse, reason: f);
    }
  });

  test('the recogniser\'s text is compared and dropped: the say step keeps no text, shows none and passes none on', () {
    final String src = _code('lib/play/say_step.dart');
    // The text is read only to be handed to the matcher; only the enum result leaves the class.
    expect(RegExp(r'\.text\b').allMatches(src).length, 1, reason: 'one read of the text: into the matcher');
    expect(src.contains('onResult(result)'), isTrue);
    expect(RegExp(r'(String|List<String>)\s+_?(heard|text|transcript)\b').hasMatch(src), isFalse);
  });

  test('a word check has no wrong: the matcher, the step and the session never use the vocabulary of a wrong answer', () {
    final RegExp vocabulary = RegExp(r'\b(wrong|incorrect|notYet|mistake)\w*', caseSensitive: false);
    for (final String f in <String>[
      'lib/speech/word_matcher.dart',
      'lib/play/say_step.dart',
      'lib/play/say_it_session.dart',
    ]) {
      expect(vocabulary.hasMatch(_code(f).replaceAll(RegExp(r'///.*'), '')), isFalse, reason: f);
    }
  });

  test('child space: no timer, countdown or streak in the say-it files', () {
    for (final String f in <String>['lib/play/say_step.dart', 'lib/play/say_it_session.dart']) {
      final String src = _code(f).toLowerCase();
      expect(src.contains('countdown'), isFalse, reason: f);
      expect(src.contains('streak'), isFalse, reason: f);
      expect(src.contains('timer'), isFalse, reason: f);
    }
  });

  test('the microphone is opened by one place only: the say step\'s tap, which a child\'s touch calls', () {
    // `engine.listen` appears once in the say step, inside tap(); the session and the screen never call it.
    expect(RegExp(r'engine\.listen\(').allMatches(_code('lib/play/say_step.dart')).length, 1);
    for (final String f in <String>['lib/play/say_it_session.dart', 'lib/play/lesson_screen.dart']) {
      expect(_code(f).contains('.listen('), isFalse, reason: f);
    }
    final String screen = _code('lib/play/lesson_screen.dart');
    expect(screen.contains('onPressed: step.canListen ? step.tap : null'), isTrue);
    expect(
      RegExp(r'step\.tap\(\)|_sayStep\??\.tap\(\)').hasMatch(screen),
      isFalse,
      reason: 'never called by the code itself',
    );
  });

  test('the models are loaded by the engine only when asked to prepare, and the load runs in an isolate', () {
    final String engine = _code('lib/speech/sherpa_engine.dart');
    expect(engine.contains('Isolate.run(() => _loadInIsolate('), isTrue);
    expect(
      RegExp(r'sherpa\.OnlineRecognizer\(').allMatches(engine).length,
      1,
      reason: 'the one constructor is in the isolate',
    );
    final String providers = _code('lib/app/voice_input.dart');
    expect(providers.contains('.prepare('), isFalse, reason: 'a provider never loads a model');
  });
}
