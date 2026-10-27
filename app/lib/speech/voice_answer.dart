import 'dart:async';

import 'package:flutter/foundation.dart';

import 'answer_matcher.dart';
import 'lexicon.dart';
import 'speech_engine.dart';

/// What the mic button shows (board 28 "voice states").
enum MicState {
  /// Waiting for a tap.
  ready,

  /// The ears are up and the ring follows the voice.
  listening,

  /// A moment of thinking while the words are matched.
  thinking,

  /// The word was understood: it is echoed and its card lights.
  understood,

  /// Nothing clear was heard: the guide asks again.
  notUnderstood,

  /// A word was half heard and the guide asks "did you say ...?"; the child answers with a tick or by speaking.
  confirming,

  /// Voice did not work for this question: the mic fades and the cards invite a tap.
  tapOnly,
}

/// The few things the guide says while listening. The screen turns each into a caption and a voice line.
enum VoicePrompt {
  /// "My ears got mixed up, say it again."
  mixedUp,

  /// "I heard ... right?" (the half-heard card glows).
  confirm,

  /// "You can tap the answer too."
  tapInstead,
}

/// How a listen ended, as the fixed words that are kept to learn how well voice works for a child. Never text.
enum ListenOutcome { accepted, confirmed, declined, unclear, silent, intent, failed }

/// One question's worth of voice: the child taps the mic, speaks, the answer is matched and either taken, checked
/// with the child, or asked for again. It never produces a wrong answer by itself: only a clear right answer, or
/// a wrong one the child confirmed, reaches [onAnswer].
class VoiceAnswerController extends ChangeNotifier {
  VoiceAnswerController({
    required this.engine,
    required this.expected,
    required this.onAnswer,
    required this.silence,
    this.matcher = const AnswerMatcher(),
    this.maxLength = const Duration(seconds: 8),
    this.stableAccept = const Duration(milliseconds: 600),
    this.beat = const Duration(milliseconds: 700),
    this.beforeListen,
    this.onPrompt,
    this.onIntent,
    this.onOutcome,
    this.onWords,
  });

  final SpeechEngine engine;

  /// The answers of the question on screen now.
  final List<Expected> Function() expected;

  /// The answer to take: the option id. Called for a clear right answer and for a confirmed one.
  final Future<void> Function(String optionId) onAnswer;

  /// How long a child may pause before the listen ends (1.5 s; 2 s in Band A).
  final Duration silence;
  final Duration maxLength;

  /// A single clear word is taken after this much silence once the recogniser's text has stopped changing.
  final Duration stableAccept;

  /// How long "understood" stays on screen before the answer is used.
  final Duration beat;
  final AnswerMatcher matcher;

  /// Stops the guide's voice before the mic opens.
  final Future<void> Function()? beforeListen;
  final void Function(VoicePrompt prompt)? onPrompt;
  final void Function(Intent intent)? onIntent;
  final void Function(ListenOutcome outcome)? onOutcome;

  /// Everything the recogniser heard for one answer, handed on once and never kept here. The parent's alerts look at
  /// it (swearing, a worrying phrase) on the device; it is not stored, sent or logged by this class.
  final void Function(List<String> texts)? onWords;

  MicState _state = MicState.ready;
  double _level = 0;
  String? _optionId;
  int _unclear = 0;
  bool _disposed = false;
  bool _confirmListen = false;
  int _generation = 0;

  MicState get state => _state;

  /// 0 to 1, while listening.
  double get level => _level;

  /// The option that was understood or half heard (to light its card).
  String? get optionId => _optionId;

  /// Whether the mic can still be tapped for this question.
  bool get canListen => _state != MicState.tapOnly;

  void _set(MicState s, {String? option, bool keepOption = false}) {
    if (_disposed) return;
    _state = s;
    if (!keepOption) _optionId = option;
    notifyListeners();
  }

  /// A new question: voice is offered again.
  void reset() {
    _generation++;
    _unclear = 0;
    _confirmListen = false;
    _level = 0;
    unawaited(engine.cancel());
    _set(MicState.ready);
  }

  /// The mic was tapped: listen (for an answer, or for "yes" or "no" while confirming).
  Future<void> tap() async {
    if (_state == MicState.listening || _state == MicState.thinking || _state == MicState.tapOnly) return;
    if (_state == MicState.understood) return;
    _confirmListen = _state == MicState.confirming;
    final int gen = ++_generation;
    final String? candidate = _optionId;
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
    _set(MicState.listening, option: candidate, keepOption: true);

    List<Hypothesis>? heard;
    ListenEnd? end;
    try {
      await for (final ListenEvent e in engine.listen(silence: silence, maxLength: maxLength)) {
        if (_disposed || gen != _generation) return;
        switch (e) {
          case ListenLevel():
            _level = e.level;
            notifyListeners();
          case ListenPartial():
            // A single clear word does not need the whole silence: take it when the text has settled.
            if (!_confirmListen && e.stableMs >= stableAccept.inMilliseconds) {
              final MatchResult early = matcher.decide(<Hypothesis>[
                Hypothesis(e.text, e.confidence),
              ], expected());
              if (early.decision == Decision.accept) {
                heard = <Hypothesis>[Hypothesis(e.text, e.confidence)];
                end = ListenEnd.early;
                // Not awaited: the stream ends by itself once the engine is told, and waiting here would deadlock it.
                unawaited(engine.cancel());
              }
            }
          case ListenDone():
            if (end != ListenEnd.early) {
              heard = e.hypotheses;
              end = e.reason;
            }
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
    if (end == ListenEnd.cancelled && heard == null) {
      _set(MicState.ready);
      return;
    }
    await _decide(heard ?? const <Hypothesis>[], gen);
  }

  Future<void> _decide(List<Hypothesis> heard, int gen) async {
    if (heard.isNotEmpty) onWords?.call(<String>[for (final Hypothesis h in heard) h.text]);
    _set(MicState.thinking, keepOption: true);
    if (_confirmListen) {
      final Intent? answer = matcher.confirmation(heard);
      if (answer == Intent.yes) {
        await _take(_optionId!, ListenOutcome.confirmed, gen);
      } else if (answer == Intent.no) {
        onOutcome?.call(ListenOutcome.declined);
        _unclearAsk(counted: true);
      } else {
        _unclearAsk();
      }
      return;
    }
    final MatchResult r = matcher.decide(heard, expected());
    switch (r.decision) {
      case Decision.accept:
        if (r.intent != null) {
          onOutcome?.call(ListenOutcome.intent);
          _set(MicState.ready);
          onIntent?.call(r.intent!);
        } else {
          await _take(r.optionId!, ListenOutcome.accepted, gen);
        }
      case Decision.confirm:
        _set(MicState.confirming, option: r.optionId);
        onPrompt?.call(VoicePrompt.confirm);
      case Decision.retry:
        _unclearAsk();
      case Decision.noSpeech:
        onOutcome?.call(ListenOutcome.silent);
        _unclearAsk(counted: true, outcome: false);
    }
  }

  /// The child tapped the tick of "did you say ...?".
  Future<void> confirmYes() async {
    if (_state != MicState.confirming || _optionId == null) return;
    final int gen = ++_generation;
    await engine.cancel();
    await _take(_optionId!, ListenOutcome.confirmed, gen);
  }

  /// The child tapped the "again" of "did you say ...?".
  void confirmNo() {
    if (_state != MicState.confirming) return;
    _generation++;
    unawaited(engine.cancel());
    onOutcome?.call(ListenOutcome.declined);
    _unclearAsk(counted: true);
  }

  Future<void> _take(String optionId, ListenOutcome outcome, int gen) async {
    _set(MicState.understood, option: optionId);
    onOutcome?.call(outcome);
    if (beat > Duration.zero) await Future<void>.delayed(beat);
    if (_disposed || gen != _generation) return;
    await onAnswer(optionId);
    if (_disposed || gen != _generation) return;
    _set(MicState.ready);
  }

  /// Not understood: the first time the guide asks again, the second time the cards invite a tap. Never "wrong".
  void _unclearAsk({bool counted = false, bool outcome = true}) {
    if (outcome && !counted) onOutcome?.call(ListenOutcome.unclear);
    _unclear++;
    if (_unclear >= 2) {
      _set(MicState.tapOnly);
      onPrompt?.call(VoicePrompt.tapInstead);
    } else {
      _set(MicState.notUnderstood);
      onPrompt?.call(VoicePrompt.mixedUp);
      _set(MicState.ready);
    }
  }

  void _fail() {
    onOutcome?.call(ListenOutcome.failed);
    _level = 0;
    _set(MicState.tapOnly);
  }

  /// Stops listening now (the child left the question, the app went to the background).
  void stop() {
    _generation++;
    unawaited(engine.cancel());
    if (_state == MicState.listening || _state == MicState.thinking) _set(MicState.ready);
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    unawaited(engine.cancel());
    super.dispose();
  }
}
