import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../content/models.dart';
import '../core/clock.dart';

/// One answer a child gave, as it is written to the `attempt` table.
class AttemptRecord {
  const AttemptRecord({
    required this.at,
    required this.profileId,
    required this.packId,
    required this.packVersion,
    required this.lessonId,
    required this.activityId,
    required this.activityRevision,
    required this.template,
    required this.templateVersion,
    required this.skillId,
    required this.result,
    required this.attemptNo,
    required this.hintLevel,
    required this.misconceptionTag,
    required this.response,
    required this.durationMs,
    this.sessionId,
  });

  final DateTime at;
  final String profileId;
  final String packId;
  final String packVersion;
  final String lessonId;
  final String activityId;
  final int activityRevision;
  final String template;
  final String templateVersion;
  final String skillId;

  /// `correct`, `incorrect` or `unsure` (never "wrong" for an unclear answer).
  final String result;
  final int attemptNo;
  final int hintLevel;

  /// Misconception evidence seen with this answer, or empty.
  final String misconceptionTag;

  /// A fixed code: the option id, `n=<number given>`, or empty.
  final String response;
  final int durationMs;

  /// The session (visit) this answer was given in.
  final int? sessionId;
}

typedef AttemptSink = Future<void> Function(AttemptRecord record);

enum FeedbackKind { none, correct, notYet }

/// What happened to an answer.
class Outcome {
  const Outcome({required this.correct, required this.tag});

  final bool correct;

  /// The misconception evidence recorded with the answer, or empty.
  final String tag;
}

/// Plays one lesson, activity by activity, and keeps the rules of help that the curriculum sets:
/// the first mistake gets a diagnostic line; later mistakes escalate through the hints (a model of
/// counting, then a worked example); after the last allowed attempt the worked example is shown and
/// the child makes the final move, so every item ends in success. "Not sure" is never a mistake.
///
/// The controller knows nothing about widgets or timers; the screen shows what it says and decides
/// how long to wait between moves.
class LessonController extends ChangeNotifier {
  LessonController({
    required this.content,
    required this.lesson,
    required this.profileId,
    required AttemptSink record,
    this.sessionId,
    Clock clock = const SystemClock(),
  }) : items = content.itemsOf(lesson),
       _record = record,
       _clock = clock {
    _begin();
  }

  final PackContent content;
  final Lesson lesson;
  final String profileId;

  /// The row of the `session` table for this visit, if one was made.
  final int? sessionId;
  final List<Activity> items;
  final AttemptSink _record;
  final Clock _clock;

  int index = 0;
  bool finished = false;

  /// Which try this is for the current activity, from 1.
  int attemptNo = 1;
  int errors = 0;

  /// The highest hint level shown so far for this activity.
  int hintLevel = 0;

  /// True once the worked example has been shown: the child now makes the last move (the right one).
  bool guided = false;

  FeedbackKind feedback = FeedbackKind.none;

  /// The line in the guide's bubble.
  String bubble = '';

  /// The hint that was shown last, and a counter that changes each time so a stage can replay it.
  HintAction? hintAction;
  int hintNonce = 0;

  /// Changes whenever the stage should start the activity over (a new activity, or a new count after a mistake).
  int resetNonce = 0;

  /// Changes when the child asks to hear the question again.
  int replayNonce = 0;

  int _markMs = 0;

  Activity get current => items[math.min(index, items.length - 1)];

  void _begin() {
    final Activity a = current;
    attemptNo = 1;
    errors = 0;
    hintLevel = 0;
    guided = false;
    feedback = FeedbackKind.none;
    hintAction = null;
    bubble = a.promptLine.caption;
    _markMs = _clock.nowMs();
    resetNonce++;
  }

  /// The replay button: the question again, without any help.
  void replayPrompt() {
    if (finished) return;
    bubble = current.promptLine.caption;
    feedback = FeedbackKind.none;
    replayNonce++;
    notifyListeners();
  }

  /// A count template has seen every object touched: now it asks "how many?".
  void askAnswer(String caption) {
    if (finished || guided) return;
    bubble = caption;
    notifyListeners();
  }

  /// The lamp: the next hint, never forced.
  void showHint() {
    if (finished || current.hints.isEmpty) return;
    _applyHint(math.min(hintLevel + 1, current.hints.length));
    feedback = FeedbackKind.none;
    notifyListeners();
  }

  void _applyHint(int level) {
    hintLevel = math.max(hintLevel, level);
    final Hint h = current.hints[level - 1];
    hintAction = h.action;
    hintNonce++;
    bubble = h.say.caption;
  }

  /// "I'm not sure" or "show me": recorded as unsure (weak evidence, no misconception, not a mistake)
  /// and welcomed with the next hint.
  Future<void> unsure() async {
    if (finished) return;
    await _write(result: 'unsure', tag: '', response: '');
    attemptNo++;
    bubble = current.feedback.unsure.caption;
    feedback = FeedbackKind.none;
    if (current.hints.isNotEmpty) {
      // The welcome line stays up; the help itself is shown by the stage.
      final String keep = bubble;
      _applyHint(math.min(hintLevel + 1, current.hints.length));
      bubble = keep;
    }
    notifyListeners();
  }

  /// The child chose answer [optionId] of a choice template. [traceTag] is misconception evidence seen
  /// while counting (the same object touched twice), kept with the answer.
  Future<Outcome> chooseOption(String optionId, {String? traceTag}) async {
    final Activity a = current;
    final List<ChoiceOption> options = switch (a) {
      CountTapActivity() => a.options,
      TapAnswerActivity() => a.options,
      _ => throw StateError('${a.template} has no options'),
    };
    final String correctId = switch (a) {
      CountTapActivity() => a.correctId,
      TapAnswerActivity() => a.correctId,
      _ => '',
    };
    final ChoiceOption chosen = options.firstWhere((ChoiceOption o) => o.id == optionId);
    final bool right = optionId == correctId;
    final String tag = right ? (traceTag ?? '') : (chosen.misconception ?? traceTag ?? '');
    return _answered(right: right, tag: tag, response: optionId);
  }

  /// The child gave [taken] objects in a give-N activity.
  Future<Outcome> giveN(int taken) async {
    final GiveNActivity a = current as GiveNActivity;
    final bool right = taken == a.n;
    String tag = '';
    if (!right) {
      final String word = taken == a.sourceCount ? 'took_all' : (taken > a.n ? 'took_more' : 'took_fewer');
      tag = a.classifiers[word] ?? '';
    }
    return _answered(right: right, tag: tag, response: 'n=$taken');
  }

  Future<Outcome> _answered({required bool right, required String tag, required String response}) async {
    final Activity a = current;
    if (right) {
      await _write(result: 'correct', tag: tag, response: response);
      attemptNo++;
      feedback = FeedbackKind.correct;
      bubble = a.feedback.correct.caption;
      notifyListeners();
      return Outcome(correct: true, tag: tag);
    }
    await _write(result: 'incorrect', tag: tag, response: response);
    attemptNo++;
    errors++;
    feedback = FeedbackKind.notYet;
    if (errors == 1 || a.hints.isEmpty) {
      // The first mistake: tell the child what to check (the line for this misconception).
      bubble = a.feedback.forIncorrect(tag.isEmpty ? null : tag).caption;
    } else {
      // Later mistakes: help that changes how the child sees the problem, not the same words again.
      _applyHint(math.min(errors, a.hints.length));
    }
    if (errors >= a.maxAttempts) {
      guided = true;
      if (a.hints.isNotEmpty && hintLevel < a.hints.length) _applyHint(a.hints.length);
    }
    notifyListeners();
    return Outcome(correct: false, tag: tag);
  }

  /// Moves on after a correct answer. After the last activity the lesson is finished.
  void next() {
    if (finished) return;
    if (index + 1 >= items.length) {
      finished = true;
      feedback = FeedbackKind.none;
      bubble = lesson.celebration.caption;
      notifyListeners();
      return;
    }
    index++;
    _begin();
    notifyListeners();
  }

  /// After a mistake, the stage starts the count again (the child may count once more).
  void restartCount() {
    feedback = FeedbackKind.none;
    resetNonce++;
    notifyListeners();
  }

  Future<void> _write({required String result, required String tag, required String response}) {
    final Activity a = current;
    final int now = _clock.nowMs();
    final AttemptRecord rec = AttemptRecord(
      at: DateTime.fromMillisecondsSinceEpoch(now, isUtc: true),
      profileId: profileId,
      packId: content.packId,
      packVersion: content.packVersion,
      lessonId: lesson.id,
      activityId: a.id,
      activityRevision: a.revision,
      template: a.template,
      templateVersion: a.templateVersion,
      skillId: a.skillId,
      result: result,
      attemptNo: attemptNo,
      hintLevel: hintLevel,
      misconceptionTag: tag,
      response: response,
      durationMs: math.max(0, now - _markMs),
      sessionId: sessionId,
    );
    _markMs = now;
    return _record(rec);
  }
}
