import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../child/activity_shell.dart';
import '../content/hint_ladder.dart';
import '../content/models.dart' show Activity, ShowPredict, ShowScript, ShowStep, Spoken;
import '../speech/answer_matcher.dart';
import 'lesson_arc.dart' show ShowKind;
import 'lesson_controller.dart';
import 'show_stage.dart';

/// Plays clips (`vo:` references) in order; see [TemplateSession.playClips]. The result completes when the clips have been played
/// (or were cut off): a session that needs the end of a line (a chant says its lines one after another) waits for it, and every
/// other session ignores it.
typedef ClipPlayer = FutureOr<void> Function(List<String> voIds, {bool replace});

/// The state of one activity on screen. A template (count and tap, tap the answer, give N) is a
/// session: it draws the stage and the answer tiles from one shared state, takes the child's moves,
/// reports each answer to the [LessonController] (which keeps the rules and writes the attempt) and
/// plays the help the controller asks for.
///
/// Sessions never wait on anything but their own timers, and cancel them all when disposed, so a
/// child leaving the screen can never trigger a late move.
abstract class TemplateSession extends ChangeNotifier {
  TemplateSession(this.controller) {
    _resetSeen = controller.resetNonce;
    _hintSeen = controller.hintNonce;
    _replaySeen = controller.replayNonce;
    controller.addListener(_onController);
  }

  final LessonController controller;
  final List<Timer> _timers = <Timer>[];
  bool _disposed = false;
  late int _resetSeen;
  late int _hintSeen;
  late int _replaySeen;

  /// How long a "not yet" stays on a tile or an answer before the child may try again.
  static const Duration notYetPause = Duration(milliseconds: 1000);

  /// How long the praise stays before the next activity.
  static const Duration praisePause = Duration(milliseconds: 1600);

  /// How long the praise of this session stays before the next activity: [praisePause], shortened by the look for the older children (B-29: the
  /// tier-1 celebration is 800 ms for P1 and P2, 700 for P3 and 500 for P4, and the rest of the pause is the 800 ms that stays).
  Duration praise = praisePause;

  /// The pause between the steps of a demonstration (a butterfly flying, a finger rising).
  static const Duration demoStep = Duration(milliseconds: 800);

  bool get disposed => _disposed;

  /// Plays the sound of an answer in a language course: the clips in order. With [replace] they cut in at once (the child touched
  /// to hear); otherwise they wait for the line that is playing (a hint's own line comes first). The lesson screen gives its
  /// sessions the voice director's; a session that has none (a test) makes no sound.
  ClipPlayer? playClips;

  /// Completes when the voice has said every line it was asked for (see `VoiceDirector.untilQuiet`): a step that waits for the end of the
  /// question (a say step asked picture first gives the child its pause after it, a hearing screen shows its picture after the word) calls
  /// it. Null in a session that has no voice (a test): there is nothing to wait for.
  Future<void> Function()? untilQuiet;

  /// Runs [action] after [delay] unless the session has been disposed.
  void later(Duration delay, VoidCallback action) {
    _timers.add(
      Timer(delay, () {
        if (!_disposed) action();
      }),
    );
  }

  void notify() {
    if (!_disposed) notifyListeners();
  }

  /// Waits [d], and never fires after the session has gone (the timer is the session's own).
  Future<void> pause(Duration d) {
    final Completer<void> c = Completer<void>();
    later(d, c.complete);
    return c.future;
  }

  // ---- the host's part (M11 Stage 2: a Show and the lead of a Together item) ----

  /// How long a line of the host stays at least: long enough to read while it has no voice, and it waits for its voice to end. A reminder
  /// (the key line only, at most 8 seconds of the host in all) holds it for less.
  static const Duration hostLinePause = Duration(milliseconds: 2400);
  static const Duration reminderLinePause = Duration(milliseconds: 1800);

  /// The host is acting on the stage (its steps, its lines): a touch of the child is not a move now.
  bool hosting = false;
  int _hostRun = 0;

  /// True in a Show once the host has done its part (its lines are said, or their ceiling has passed) and the child has not yet made the last
  /// step: the frame then offers a quiet "next" (QA-3), so a Show is never a dead end. It is never offered on a Together item or an Alone item,
  /// which are scored, and it shows no timer. Read by the frame through a [ValueListenable], so a change redraws only that button.
  final ValueNotifier<bool> canMoveOn = ValueNotifier<bool>(false);

  /// The Show on screen is a reminder (the child has met the skill): a touch skips what the host does.
  bool get reminder => controller.step?.show == ShowKind.reminder;

  /// How the host's moves are paced and drawn for this child (set by the lesson screen): the youngest looks (P1, P2) are slower, and with
  /// reduced movement no hand travels and nothing glides: each move is in its place after its pause.
  bool slowHost = false;
  bool stillHost = false;

  /// The host's question of a predict-then-watch Show, while its answers are on offer (null otherwise): the lesson screen draws them in place of
  /// the template's tiles. The child's touch is [guess]; it is never scored, written or told right or wrong.
  final ValueNotifier<ShowPredict?> predicting = ValueNotifier<ShowPredict?>(null);
  Completer<String>? _guessed;

  /// The guess the child touched, as its id (a test reads it; it is kept for this screen only and goes nowhere).
  String? guessedId;

  /// The most the host waits for a guess: a child who does not touch goes on with the example (no timer is shown).
  static const Duration guessCeiling = Duration(seconds: 20);

  /// The child touched the answer [id] of the host's question.
  void guess(String id) {
    final Completer<String>? c = _guessed;
    if (c == null || c.isCompleted) return;
    guessedId = id;
    notify();
    c.complete(id);
  }

  /// The host asks its question and, when it has answers, waits for the child's guess (then they go, and the example runs). The line was
  /// asked by the host's bubble; a question with no answers is asked, and the host holds a moment before it begins.
  Future<void> ask(ShowPredict predict) async {
    if (predict.line != null) await sayLine(predict.line!);
    if (!predict.asksForGuess) {
      await pause(const Duration(milliseconds: 1500));
      return;
    }
    final Completer<String> c = _guessed = Completer<String>();
    predicting.value = predict;
    await Future.any(<Future<Object?>>[c.future, pause(guessCeiling)]);
    // The guess stays lit for a moment, so that the child sees the touch was taken.
    await pause(const Duration(milliseconds: 600));
    predicting.value = null;
  }

  /// The child made the last step of a Show: the host's key line is said again as the praise, nothing is written, and the lesson goes on.
  void finishShow() {
    controller.completePractice();
    notify();
    later(praise, controller.next);
  }

  /// A move of the child in a Show that is not the step the host left: the host says "let's look again". Nothing is written or counted.
  void lookAgain(Activity activity) => controller.speak(activity.feedback.forIncorrect(null));

  /// How the host's hand is drawn in a Show (its pointer, its marks, the lift to the middle of the stage), or null: the hand of the hints does the
  /// worked example. The lesson screen sets it when the host has the art for it (Kubi, M11 Stage 2); [showMarks] is what is drawn now.
  ShowStyle? showStyle;
  final ShowMarks showMarks = ShowMarks();

  /// Calls [tick] with 0 to 1 over [d], about 60 times a second, on the session's own timer; completes at 1 (never once the session has gone).
  Future<void> animate(Duration d, void Function(double t) tick) {
    final Completer<void> done = Completer<void>();
    int ticks = 0;
    late final Timer timer;
    timer = Timer.periodic(const Duration(milliseconds: 16), (Timer _) {
      if (_disposed) {
        timer.cancel();
        return;
      }
      // Counted in steps, not read from a clock, so that a test that moves time forward moves the motion with it.
      final double t = (++ticks * 16000 / d.inMicroseconds).clamp(0.0, 1.0);
      tick(t);
      if (t >= 1) {
        timer.cancel();
        done.complete();
      }
    });
    _timers.add(timer);
    return done.future;
  }

  /// A template that has a host's part begins it here once its stage has been drawn (the lesson screen calls it after the first frame).
  void startHost() {}

  /// The host says [line] (the bubble, and its voice when it has one) and the next move waits until it is said.
  Future<void> sayLine(Spoken line, {Duration atLeast = hostLinePause}) async {
    controller.speak(line);
    await lineSaid(atLeast);
  }

  /// The longest the host waits for the voice of a line (QA-3): a clip that never reports its end (a player that fails to fire its completion)
  /// must not freeze a Show, which the child cannot skip. The ceiling is the least wait, 2 seconds for the voice to start, and 90 ms for each
  /// letter of the line (a line of 90 letters with its niqqud is about 8 seconds spoken), at most [lineCeilingMax].
  static Duration lineCeiling(String line, Duration atLeast) {
    final Duration wait = atLeast + Duration(milliseconds: 2000 + 90 * line.length);
    return wait > lineCeilingMax ? lineCeilingMax : wait;
  }

  static const Duration lineCeilingMax = Duration(seconds: 14);

  /// Waits until the line in the bubble has been read and heard: at least [atLeast], and until the voice has ended, but never beyond its
  /// [lineCeiling]. A session with no voice (a test) waits only [atLeast].
  Future<void> lineSaid([Duration atLeast = hostLinePause]) {
    final Future<void> Function()? quiet = untilQuiet;
    return Future.wait(<Future<void>>[
      pause(atLeast),
      if (quiet != null) Future.any(<Future<void>>[quiet(), pause(lineCeiling(controller.bubble, atLeast))]),
    ]);
  }

  /// A Show: the host says its lines and makes its moves through [move] (the template draws them; [fast] for a reminder), then it stops before
  /// the last move, which the child makes. Nothing is written. The opening line (the key line, for a reminder) is already in the bubble.
  Future<void> playShow(
    ShowScript show, {
    required Future<void> Function(ShowStep step, {required bool fast}) move,
  }) async {
    final int run = ++_hostRun;
    bool alive() => !disposed && run == _hostRun;
    final bool fast = reminder;
    hosting = true;
    notify();
    await lineSaid(fast ? reminderLinePause : hostLinePause);
    // Predict, then watch: the host asks what will happen before it runs the example (the full Show only; a reminder has the key line alone).
    if (!fast && show.predict != null) {
      await ask(show.predict!);
      if (!alive()) return;
    }
    for (final ShowStep step in show.hostSteps) {
      if (!alive()) return;
      if (!fast && step.saysKey) await sayLine(show.lines['key']!);
      if (!alive()) return;
      await move(step, fast: fast);
    }
    if (!alive()) return;
    final Spoken? handover = show.lines['handover'];
    if (!fast && handover != null) await sayLine(handover);
    if (!alive()) return;
    hosting = false;
    canMoveOn.value = true;
    notify();
  }

  /// The host does the first steps of a Together item, each through [moves], and then it is the child's turn: the companion asks the question.
  /// The host's line is already in the bubble.
  Future<void> playLead(List<Future<void> Function()> moves) async {
    final int run = ++_hostRun;
    bool alive() => !disposed && run == _hostRun;
    hosting = true;
    notify();
    await lineSaid();
    for (final Future<void> Function() move in moves) {
      if (!alive()) return;
      await move();
    }
    if (!alive()) return;
    hosting = false;
    notify();
    controller.leadDone();
  }

  /// A touch while the host acts in a reminder skips to the child's step: [placeAll] puts what the host had still to do in its place at once.
  void skipHost(VoidCallback placeAll) {
    if (!hosting || !reminder || !(controller.step?.activity.isShow ?? false)) return;
    _hostRun++;
    placeAll();
    hosting = false;
    canMoveOn.value = true;
    notify();
  }

  /// Plays [ids] and waits until they have been played (at most [atMost]); with no player (a test) it waits [without] instead.
  Future<void> sayAndWait(
    List<String> ids, {
    bool replace = false,
    Duration without = const Duration(milliseconds: 700),
    Duration atMost = const Duration(seconds: 8),
  }) async {
    final FutureOr<void> played = playClips?.call(ids, replace: replace);
    if (played is Future<void>) {
      await Future.any(<Future<void>>[played, pause(atMost)]);
    } else {
      await pause(without);
    }
  }

  void _onController() {
    if (_disposed) return;
    if (controller.resetNonce != _resetSeen) {
      _resetSeen = controller.resetNonce;
      onReset();
    }
    if (controller.hintNonce != _hintSeen) {
      _hintSeen = controller.hintNonce;
      final bool afterMistake = controller.feedback == FeedbackKind.notYet;
      later(afterMistake ? notYetPause + const Duration(milliseconds: 100) : Duration.zero, onHint);
    }
    if (controller.replayNonce != _replaySeen) {
      _replaySeen = controller.replayNonce;
      onReplay();
    }
  }

  /// The child may count (or give) again from the start.
  void onReset();

  /// Play the help the controller just chose: the picture that [hintPictureOf] says for the level shown.
  void onHint();

  /// What [activity]'s template draws for the hint level the controller has shown (B-40: one picture per level, the table is
  /// `HintLadder`). [share] is true for a sort and drag activity in share mode.
  HintPicture hintPictureOf(Activity activity, {bool share = false}) =>
      HintLadder.of(activity.template, share: share)!.at(controller.hintShown);

  /// The question is asked again: a gentle show of the objects, no help.
  void onReplay();

  /// The child pressed the eye ("show me"), just before the answer is recorded as unsure: a template may show something of its own (the
  /// blocks' demonstration that a rod is ten cubes). Nothing by default.
  void onShowMe() {}

  /// The child touched the screen anywhere (a pointer went down on it): a template with something to watch that a touch ends (the blocks'
  /// opening demonstration) ends it here. Nothing by default; it is not an answer and takes no part in any.
  void onScreenTouch() {}

  // ---- voice ----

  /// The card the voice has understood or half heard: lit like a hint, until the voice lets go of it.
  String? voiceLit;

  void setVoiceLit(String? id) {
    if (voiceLit == id) return;
    voiceLit = id;
    notify();
  }

  /// The mic can be used now (the question has been asked and not yet answered).
  bool get listensNow => false;

  /// `number`, `colour` or `word`: the kind of answer, kept (as that word) with how each listen went.
  String get voiceAnswerType => 'word';

  /// The answers a child may say now, with the words for each.
  List<Expected> voiceExpected() => const <Expected>[];

  /// A spoken answer that was clear, or that the child confirmed: it counts exactly like a tap on the card.
  Future<void> chooseByVoice(String optionId) async {}

  /// Voice did not work: the cards light one after the other, inviting a tap.
  void inviteTap() {
    final List<Expected> options = voiceExpected();
    for (int i = 0; i < options.length; i++) {
      later(Duration(milliseconds: 450 * i), () => setVoiceLit(options[i].id));
    }
    later(Duration(milliseconds: 450 * options.length), () => setVoiceLit(null));
  }

  /// The text scaler the lesson's bubble is drawn with (the system's text size, up to 1.3: `ActivityFrame.bubbleScaler`), set by the lesson
  /// screen before it asks for [layoutFor]: a layout that makes room for the bubble measures the line the way it is drawn.
  TextScaler bubbleScaler = TextScaler.noScaling;

  /// The board numbers this template lays its activity out on: [base] (the board's own, see `ActivitySpec.of`) unless the template
  /// needs a different stage or tile box. Every `build...` below is given what this returns.
  ActivitySpec layoutFor(ActivitySpec base) => base;

  /// How far above `spec.tilesTop` this template's drawn tiles stand (see `ActivityFrame.tilesRise`): 0 where the tiles are drawn at the board's place.
  double tilesRise(ActivitySpec spec) => 0;

  /// The picture that fills the stage, inside [size].
  Widget buildStage(BuildContext context, Size size, ActivitySpec spec);

  /// The row of answer tiles (or the single confirm button), or null when the template has none.
  Widget? buildTiles(BuildContext context, ActivitySpec spec);

  /// A widget in the board's own points, outside the stage and the tiles (a `Positioned` of the board's stack), or null: where a template
  /// puts something that must never lie on its stage (the close-up card of a command, docs/design/languages-l4-layout.md section 3).
  Widget? buildBoardLayer(BuildContext context, ActivitySpec spec) => null;

  /// The layer of a hint's pointing hand, over the same room as the stage and above the speech bubble (so the hand that shows the
  /// way is never hidden by it), or null when the template draws no hand. The rest of a hint is drawn by [buildStage].
  Widget? buildHands(BuildContext context, Size size, ActivitySpec spec) => null;

  @override
  void dispose() {
    _disposed = true;
    canMoveOn.dispose();
    predicting.dispose();
    for (final Timer t in _timers) {
      t.cancel();
    }
    controller.removeListener(_onController);
    super.dispose();
  }
}

/// A picture of a pack, drawn from its verified SVG text. It is decoration: screen readers get the
/// label of the whole stage instead.
class PackSvg extends StatelessWidget {
  const PackSvg(this.svg, {super.key, this.width, this.height, this.fit = BoxFit.contain});

  final String svg;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) =>
      SvgPicture.string(svg, width: width, height: height, fit: fit, excludeFromSemantics: true);
}
