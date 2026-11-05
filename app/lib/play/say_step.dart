import 'dart:async';

import 'package:flutter/foundation.dart';

import '../speech/answer_matcher.dart' show Hypothesis;
import '../speech/speech_engine.dart';
import '../speech/word_matcher.dart';

/// Where a say step is, for the mic button and the session.
enum SayState {
  /// Waiting for a tap on the microphone.
  ready,

  /// The ears are up and the ring follows the voice.
  listening,

  /// A moment while the word is matched.
  thinking,

  /// The child was heard (confident). The step is over.
  heard,

  /// Not heard clearly, or not at all: the voice said the word with the child. One more try may be offered.
  together,

  /// The microphone or the model did not work: the step runs as echo from now on, with no message.
  unavailable,
}

/// One "say the word" step (docs/languages/frame.md section 5.1): the child taps the microphone, says the word, and the per-word
/// matcher answers confident, unsure or silence. It never says anything is wrong; it offers at most [maxTries] listens, never
/// requires one, and keeps nothing: the audio stays in the engine, the recogniser's text goes to the matcher and is dropped, and
/// only the result (an enum) leaves this class.
///
/// LS09 uses it, and so will the say step of LS10 and LS08 `echo`.
class SayStepController extends ChangeNotifier {
  SayStepController({
    required this.engine,
    required this.target,
    required this.silence,
    required this.onResult,
    this.maxLength = const Duration(seconds: 6),
    this.maxTries = 2,
    this.matcher = const WordMatcher(),
    this.beforeListen,
    this.onOutcome,
  });

  final SpeechEngine engine;

  /// The words of the item: signed content only.
  final WordTarget target;
  final Duration silence;
  final Duration maxLength;

  /// A listen, and one more by a tap.
  final int maxTries;
  final WordMatcher matcher;

  /// Stops the guide's voice before the microphone opens, so the guide is never heard as the child.
  final Future<void> Function()? beforeListen;

  /// What came of a listen: called once with the result.
  final Future<void> Function(SayResult result) onResult;

  /// How a listen went, as a fixed word, to keep how well voice works for this child. Never text.
  final void Function(String outcome)? onOutcome;

  SayState _state = SayState.ready;
  double _level = 0;
  int _tries = 0;
  int _generation = 0;
  bool _disposed = false;

  SayState get state => _state;

  /// 0 to 1 while listening.
  double get level => _level;

  /// The microphone may be tapped now: before the first listen, and after an unsure one while a try is left.
  bool get canListen => _tries < maxTries && (_state == SayState.ready || _state == SayState.together);

  void _set(SayState s) {
    if (_disposed) return;
    _state = s;
    notifyListeners();
  }

  /// The mic was tapped.
  Future<void> tap() async {
    if (!canListen) return;
    final int gen = ++_generation;
    _set(SayState.listening);
    await beforeListen?.call();
    if (_disposed || gen != _generation) return;
    if (!engine.ready) {
      try {
        await engine.prepare();
      } on Object {
        _fail();
        return;
      }
    }
    if (_disposed || gen != _generation) return;

    List<Hypothesis> heard = const <Hypothesis>[];
    ListenEnd? end;
    try {
      await for (final ListenEvent e in engine.listen(
        silence: silence,
        maxLength: maxLength,
        hotwords: target.hotwords,
      )) {
        if (_disposed || gen != _generation) return;
        switch (e) {
          case ListenLevel():
            _level = e.level;
            notifyListeners();
          case ListenPartial():
            break;
          case ListenDone():
            heard = e.hypotheses;
            end = e.reason;
        }
      }
    } on Object {
      _fail();
      return;
    }
    if (_disposed || gen != _generation) return;
    _level = 0;
    if (end == ListenEnd.failed) {
      _fail();
      return;
    }
    if (end == ListenEnd.cancelled && heard.isEmpty) {
      _set(SayState.ready);
      return;
    }
    _set(SayState.thinking);
    final SayResult result = matcher.decide(<String>[
      for (final Hypothesis h in heard) h.text,
    ], target).result;
    _tries++;
    onOutcome?.call(switch (result) {
      SayResult.confident => 'confident',
      SayResult.unsure => 'unsure',
      SayResult.silence => 'silent',
    });
    _set(result == SayResult.confident ? SayState.heard : SayState.together);
    await onResult(result);
  }

  void _fail() {
    onOutcome?.call('failed');
    _level = 0;
    _set(SayState.unavailable);
  }

  /// Stops listening now (the child left, or the guide is about to speak).
  void stop() {
    _generation++;
    unawaited(engine.cancel());
    if (_state == SayState.listening || _state == SayState.thinking) {
      _level = 0;
      _set(_tries == 0 ? SayState.ready : SayState.together);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    unawaited(engine.cancel());
    super.dispose();
  }
}
