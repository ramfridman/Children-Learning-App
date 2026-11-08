import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../child/activity_shell.dart';
import '../content/hint_ladder.dart';
import '../content/models.dart' show Activity;
import '../speech/answer_matcher.dart';
import 'lesson_controller.dart';

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

  /// The pause between the steps of a demonstration (a butterfly flying, a finger rising).
  static const Duration demoStep = Duration(milliseconds: 800);

  bool get disposed => _disposed;

  /// Plays the sound of an answer in a language course: the clips in order. With [replace] they cut in at once (the child touched
  /// to hear); otherwise they wait for the line that is playing (a hint's own line comes first). The lesson screen gives its
  /// sessions the voice director's; a session that has none (a test) makes no sound.
  ClipPlayer? playClips;

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
