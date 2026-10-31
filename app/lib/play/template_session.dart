import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../child/activity_shell.dart';
import '../content/hint_ladder.dart';
import '../content/models.dart' show Activity;
import '../speech/answer_matcher.dart';
import 'lesson_controller.dart';

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

  /// The picture that fills the stage, inside [size].
  Widget buildStage(BuildContext context, Size size, ActivitySpec spec);

  /// The row of answer tiles (or the single confirm button), or null when the template has none.
  Widget? buildTiles(BuildContext context, ActivitySpec spec);

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
