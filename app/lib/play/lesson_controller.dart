import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../content/models.dart';
import '../core/clock.dart';
import '../core/log.dart';
import '../strings/he.dart';
import '../tutor/tutor.dart';
import 'response_code.dart';

/// What the tutor needs to know about the lesson: ids and enums only.
class TutorContext {
  const TutorContext({
    required this.packId,
    required this.packVersion,
    required this.characterId,
    required this.band,
    required this.addressForm,
    required this.childRef,
    required this.sessionRef,
  });

  final String packId;
  final String packVersion;
  final String characterId;
  final String band;
  final String addressForm;
  final String childRef;
  final String sessionRef;
}

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
    this.input = 'tap',
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

  /// `tap`, or `voice` for a spoken answer that was clear or that the child confirmed.
  final String input;
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
/// the first mistake gets a diagnostic line and the picture of hint 1; later mistakes escalate through
/// the hints (another way to see it, then a worked example); a two-choice item gets one retry, then the
/// worked example; after the last allowed attempt the worked example is shown and the child makes the
/// final move, so every item ends in success. "Not sure" is never a mistake.
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
    this.tutor,
    this.tutorContext,
    this.timeIsUp,
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

  /// The tutor of this lesson, or null when the AI helper is off: then every line is the authored one.
  TutorSession? tutor;
  TutorContext? tutorContext;
  final List<Activity> items;
  final AttemptSink _record;
  final Clock _clock;

  int index = 0;
  bool finished = false;

  /// Asked between two activities: is it time to rest (the parent's rules, with the lock on)? Then the lesson ends
  /// there, gently, and is not counted as finished.
  final bool Function()? timeIsUp;

  /// The lesson ended because it was time to rest, not because the child reached the end.
  bool endedForRest = false;

  /// Which try this is for the current activity, from 1.
  int attemptNo = 1;
  int errors = 0;

  /// The highest hint level shown so far for this activity.
  int hintLevel = 0;

  /// True once the help is at its top: only the right move is taken, and the worked example is (or was) shown.
  bool guided = false;

  /// The worked example has ended (or none can be shown): the answer may now carry the halo, and the others the dimming. The
  /// halo is the last step of the demonstration, never before it (B-40).
  bool get answerShown => guided && _demoDone;
  bool _demoDone = false;

  /// A template calls this when its worked example has ended, and at once when it has none to show.
  void demoDone() {
    if (_demoDone || finished) return;
    // Only the worked example (the last hint) counts: a smaller demonstration that a touch cut short does not.
    if (hintShown < math.min(3, current.hints.length)) return;
    _demoDone = true;
    if (guided) notifyListeners();
  }

  /// The activity was answered right and only waits for the praise to end: no help and no "not sure" is taken for it now.
  bool solved = false;

  FeedbackKind feedback = FeedbackKind.none;

  /// The line in the guide's bubble, the voice line (`vo:...`) that goes with it, and a counter that changes
  /// whenever the guide has a new line to say (the same line said again counts).
  String bubble = '';
  String? voice;
  int voiceNonce = 0;

  /// The newest line was asked for by a touch (the replay button): it replaces the line that is playing. Every other line
  /// waits for the one that is playing to end, so a sentence is never cut off.
  bool voiceReplaces = false;

  /// Counts the child's own moves (an answer, a hint, "show me", the replay button). A line made after move n is worth
  /// saying only until move n + 1: after that the child has moved on, and the line would be about the past.
  int actionNonce = 0;

  void _say(Spoken line) {
    voiceReplaces = false;
    // Any new line replaces what the tutor was about to say.
    _tutorToken++;
    tutorThinking = false;
    bubble = line.caption;
    voice = line.vo;
    voiceNonce++;
  }

  // ---- the AI tutor ----

  /// True while the guide waits for the tutor's line (it shows its thinking pose).
  bool tutorThinking = false;

  /// The line the tutor made, to be played by the screen (a new one whenever [liveNonce] changes).
  TutorLine? liveLine;
  int liveNonce = 0;
  int _tutorToken = 0;
  final List<TutorAttempt> _recent = <TutorAttempt>[];

  bool _tutorMayHelp(Activity a) => tutor != null && tutorContext != null && tutor!.available && a.llmAllowed;

  TutorAsk _ask(Activity a, List<String> mistakes, int hint, {bool prefetch = false}) {
    final TutorContext c = tutorContext!;
    return TutorAsk(
      childRef: c.childRef,
      sessionRef: c.sessionRef,
      packId: c.packId,
      packVersion: c.packVersion,
      itemId: a.id,
      characterId: c.characterId,
      band: c.band,
      addressForm: c.addressForm,
      hintLevel: hint,
      mistakes: mistakes,
      attempts: prefetch ? const <TutorAttempt>[] : List<TutorAttempt>.of(_recent),
      prefetch: prefetch,
    );
  }

  /// The helper's answer from the server came after the lesson had opened: from now on this lesson may use it too.
  void attachTutor(TutorSession session, TutorContext context) {
    if (tutor != null) return;
    tutor = session;
    tutorContext = context;
    if (!finished) _prefetchTutor(current);
  }

  /// Asks ahead, when an activity opens, for the lines of the mistakes it can produce. Quiet and optional.
  void _prefetchTutor(Activity a) {
    if (!_tutorMayHelp(a)) return;
    final List<String> tags = a.misconceptionTags.take(3).toList();
    if (tags.isNotEmpty) unawaited(tutor!.prefetch(_ask(a, tags, _secondMistakeHint(a), prefetch: true)));
    unawaited(tutor!.prefetch(_ask(a, const <String>['default'], 0, prefetch: true)));
  }

  /// The hint level reached by the second mistake of an activity (the first help beyond the diagnostic line).
  int _secondMistakeHint(Activity a) => math.min(2, a.hints.length);

  /// The guide waits for the tutor's line; if it does not come in time, the authored line is said instead.
  void _holdForTutor(Spoken authored, TutorAsk ask) {
    final int token = ++_tutorToken;
    tutorThinking = true;
    // The authored caption stays up so the screen is never empty; its voice waits for the tutor's answer.
    bubble = authored.caption;
    final Future<TutorLine?> pending = tutor!.lineFor(
      ask,
      onSlow: () {
        if (token != _tutorToken) return;
        // A recorded "hmm" covers a slow answer.
        voice = 'vo:core.thinking.think';
        bubble = He.thinkHmm.text;
        voiceNonce++;
        notifyListeners();
      },
    );
    unawaited(
      pending.then((TutorLine? line) {
        if (token != _tutorToken) return;
        tutorThinking = false;
        if (line == null) {
          _say(authored);
        } else {
          liveLine = line;
          liveNonce++;
          voice = null;
          // A child in Band A gets no caption for a live line (PLAN); the older ones read it.
          bubble = tutorContext!.band == 'A' ? '' : (line.caption ?? '');
        }
        notifyListeners();
      }),
    );
  }

  /// The hint that was shown last, its level (1 to 3, 0 for none), and a counter that changes each time so a stage can
  /// replay it. A stage draws what the level says (see `HintLadder`); the action is the author's note on the line.
  HintAction? hintAction;
  int hintShown = 0;
  int hintNonce = 0;

  /// Changes whenever the stage should start the activity over (a new activity, or a new count after a mistake).
  int resetNonce = 0;

  /// Changes when the child asks to hear the question again.
  int replayNonce = 0;

  int _markMs = 0;
  int _struggles = 0;

  Activity get current => items[math.min(index, items.length - 1)];

  void _begin() {
    final Activity a = current;
    attemptNo = 1;
    errors = 0;
    hintLevel = 0;
    guided = false;
    _demoDone = false;
    solved = false;
    feedback = FeedbackKind.none;
    hintAction = null;
    hintShown = 0;
    _recent.clear();
    _say(a.promptLine);
    _markMs = _clock.nowMs();
    resetNonce++;
    _prefetchTutor(a);
  }

  /// The replay button: the question again, without any help.
  void replayPrompt() {
    if (finished) return;
    actionNonce++;
    _say(current.promptLine);
    voiceReplaces = true;
    feedback = FeedbackKind.none;
    replayNonce++;
    notifyListeners();
  }

  /// The guide says one of its own lines (for example while listening): a caption and a voice line.
  void speak(Spoken line) {
    if (finished) return;
    _say(line);
    notifyListeners();
  }

  /// A count template has seen every object touched: now it asks "how many?".
  void askAnswer(Spoken line) {
    if (finished || guided) return;
    _say(line);
    notifyListeners();
  }

  /// The lamp: the next hint, never forced.
  void showHint() {
    // During the praise a touch is not a move: the praise is not cut and nothing is written.
    if (solved) return;
    actionNonce++;
    if (finished || current.hints.isEmpty) return;
    _applyHint(math.min(hintLevel + 1, current.hints.length));
    feedback = FeedbackKind.none;
    notifyListeners();
  }

  void _applyHint(int level, {bool speak = true}) {
    hintLevel = math.max(hintLevel, level);
    final Hint h = current.hints[level - 1];
    hintAction = h.action;
    hintShown = level;
    hintNonce++;
    if (speak) _say(h.say);
  }

  /// "I'm not sure" or "show me": recorded as unsure (weak evidence, no misconception, not a mistake)
  /// and welcomed with the next hint.
  Future<void> unsure() async {
    if (solved) return;
    actionNonce++;
    if (finished) return;
    await _write(result: 'unsure', tag: '', response: '');
    attemptNo++;
    _say(current.feedback.unsure);
    feedback = FeedbackKind.none;
    if (current.hints.isNotEmpty) {
      // The welcome line stays up; the help itself is shown by the stage.
      final String keep = bubble;
      final String? keepVoice = voice;
      _applyHint(math.min(hintLevel + 1, current.hints.length));
      bubble = keep;
      voice = keepVoice;
    }
    notifyListeners();
  }

  /// The child chose answer [optionId] of a choice template. [traceTag] is misconception evidence seen
  /// while counting (the same object touched twice), kept with the answer.
  Future<Outcome> chooseOption(String optionId, {String? traceTag, bool byVoice = false}) async {
    final Activity a = current;
    final List<ChoiceOption> options = switch (a) {
      CountTapActivity() => a.options,
      TapAnswerActivity() => a.options,
      FlashActivity() => a.options,
      _ => throw StateError('${a.template} has no options'),
    };
    final String correctId = switch (a) {
      CountTapActivity() => a.correctId,
      TapAnswerActivity() => a.correctId,
      FlashActivity() => a.correctId,
      _ => '',
    };
    final ChoiceOption chosen = options.firstWhere((ChoiceOption o) => o.id == optionId);
    final bool right = optionId == correctId;
    final String tag = right ? (traceTag ?? '') : (chosen.misconception ?? traceTag ?? '');
    return _answered(right: right, tag: tag, response: optionId, byVoice: byVoice);
  }

  /// The child made a move in a drag template (sort, share, build a pattern): [right] says whether it was the right one, [tag]
  /// the misconception it shows if not. A right move ends the activity (it is written once, as `correct`); every wrong
  /// move is written as `incorrect`, and after the third the help is at its top and only the right move is taken.
  Future<Outcome> submitPlacement({required bool right, String tag = '', String response = ''}) =>
      _answered(right: right, tag: tag, response: response);

  /// The child gave [taken] objects in a give-N activity.
  Future<Outcome> giveN(int taken) async {
    final GiveNActivity a = current as GiveNActivity;
    final bool right = taken == a.n;
    String tag = '';
    if (!right) {
      final String word = taken == a.sourceCount ? 'took_all' : (taken > a.n ? 'took_more' : 'took_fewer');
      tag = a.classifiers[word] ?? '';
    }
    return _answered(right: right, tag: tag, response: ResponseCode.count(taken));
  }

  Future<Outcome> _answered({
    required bool right,
    required String tag,
    required String response,
    bool byVoice = false,
  }) async {
    final Activity a = current;
    actionNonce++;
    if (right) {
      await _write(result: 'correct', tag: tag, response: response, byVoice: byVoice);
      attemptNo++;
      solved = true;
      feedback = FeedbackKind.correct;
      _say(a.feedback.correct);
      notifyListeners();
      return Outcome(correct: true, tag: tag);
    }
    await _write(result: 'incorrect', tag: tag, response: response, byVoice: byVoice);
    attemptNo++;
    errors++;
    feedback = FeedbackKind.notYet;
    // The helper takes a shorter code than the sync does: one that does not fit is told as a plain move.
    _recent.add(
      TutorAttempt(ResponseCode.tutorOption(response), 'incorrect', misconception: tag.isEmpty ? null : tag),
    );
    if (_recent.length > 3) _recent.removeAt(0);
    final bool first = errors == 1 || a.hints.isEmpty;
    // A child who has two choices has one retry: the first mistake already shows the second kind of help (B-40, A6).
    final bool twoChoices = a.optionCount == 2;
    final int attempts = twoChoices ? math.min(2, a.maxAttempts) : a.maxAttempts;
    final String mistake = tag.isEmpty ? 'default' : tag;
    // The tutor speaks for an unexpected first mistake (the authored line would be the generic one) and for the second
    // mistake, where a different explanation is needed. The authored line stays the fallback for all of it.
    final bool useTutor = _tutorMayHelp(a) && (first ? tag.isEmpty : true);
    Log.d(
      'helper: mistake ${a.id} errors=$errors tag=${tag.isEmpty ? 'none' : tag} session=${tutor != null} '
      'context=${tutorContext != null} available=${tutor?.available} llmAllowed=${a.llmAllowed} use=$useTutor',
    );
    if (first) {
      // The first mistake: tell the child what to check (the line for this misconception).
      final Spoken authored = a.feedback.forIncorrect(tag.isEmpty ? null : tag);
      if (useTutor) {
        _holdForTutor(authored, _ask(a, <String>[mistake], 0));
      } else {
        _say(authored);
      }
      // ...and the picture of the first help goes with it: the line is the diagnosis, the picture shows where to look.
      if (a.hints.isNotEmpty) _applyHint(math.min(twoChoices ? 2 : 1, a.hints.length), speak: false);
    } else {
      // Later mistakes: help that changes how the child sees the problem, not the same words again.
      final int level = math.min(errors + (twoChoices ? 1 : 0), a.hints.length);
      if (useTutor) {
        _applyHint(level, speak: false);
        _holdForTutor(current.hints[level - 1].say, _ask(a, <String>[mistake], hintLevel));
      } else {
        _applyHint(level);
      }
    }
    if (errors >= attempts) {
      guided = true;
      if (a.hints.isNotEmpty && hintLevel < a.hints.length) _applyHint(a.hints.length);
      // With no worked example to show (fewer than three hints) the answer may be marked at once.
      if (a.hints.length < 3) _demoDone = true;
    }
    notifyListeners();
    return Outcome(correct: false, tag: tag);
  }

  /// Moves on after a correct answer. After the last activity the lesson is finished.
  void next() {
    if (finished) return;
    // The help ran all the way up on this activity: counted, so that a warm-up can end gently instead of going on.
    _struggles = guided ? _struggles + 1 : 0;
    final int stop = lesson.stopAfterStruggles;
    if (index + 1 >= items.length || (stop > 0 && _struggles >= stop)) {
      finished = true;
      feedback = FeedbackKind.none;
      _say(lesson.celebration);
      notifyListeners();
      return;
    }
    if (timeIsUp?.call() ?? false) {
      endedForRest = true;
      finished = true;
      feedback = FeedbackKind.none;
      _say(Spoken(vo: 'vo:core.rest.goodbye', caption: He.restGoodbye.text));
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

  Future<void> _write({
    required String result,
    required String tag,
    required String response,
    bool byVoice = false,
  }) {
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
      input: byVoice ? 'voice' : 'tap',
    );
    _markMs = now;
    return _record(rec);
  }
}
