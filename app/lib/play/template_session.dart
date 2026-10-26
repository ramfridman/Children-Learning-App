import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../child/activity_shell.dart';
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

  /// Play the help the controller just chose (`controller.hintAction`).
  void onHint();

  /// The question is asked again: a gentle show of the objects, no help.
  void onReplay();

  /// The picture that fills the stage, inside [size].
  Widget buildStage(BuildContext context, Size size, ActivitySpec spec);

  /// The row of answer tiles (or the single confirm button), or null when the template has none.
  Widget? buildTiles(BuildContext context, ActivitySpec spec);

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
