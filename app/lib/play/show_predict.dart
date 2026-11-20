import 'package:flutter/material.dart';

import '../child/activity_shell.dart';
import '../content/models.dart' show ShowPredict;
import '../design/app_text.dart';
import '../design/components.dart';
import 'template_session.dart';

/// The answers of the host's question in a predict-then-watch Show (M11-stage2 section 2.1), drawn in place of the template's tiles while the
/// host waits: two or three tiles with a word on each, in a row that reads from the start side. A touch is the child's guess ([TemplateSession.guess]):
/// it is lit for a moment and nothing says whether it was right, because the example the host runs next is the answer.
class GuessTiles extends StatelessWidget {
  const GuessTiles({super.key, required this.session, required this.predict, required this.spec});

  final TemplateSession session;
  final ShowPredict predict;
  final ActivitySpec spec;

  @override
  Widget build(BuildContext context) {
    // The look's tile, and a width that fits a word at 22 points: three of them are wider than the box the template gives its tiles (210 on a phone), so the
    // row stands over it, centred, instead of overflowing it (docs/design/m11/min-sizes.md R4).
    final double side = spec.tileSize;
    final double width = side + 8;
    final int n = predict.choices.length;
    return ListenableBuilder(
      listenable: session,
      builder: (BuildContext c, Widget? _) => SizedBox(
        height: side + 12,
        child: OverflowBox(
          minWidth: n * (width + 12),
          maxWidth: n * (width + 12),
          child: Row(
            key: const Key('guess-tiles'),
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              for (final ({String id, String label}) choice in predict.choices)
                AnswerTile(
                  key: Key('guess-${choice.id}'),
                  semanticLabel: choice.label,
                  size: side,
                  width: width,
                  slop: 6,
                  state: session.guessedId == choice.id ? AnswerState.selected : AnswerState.idle,
                  onPressed: () => session.guess(choice.id),
                  child: Text(
                    choice.label,
                    textAlign: TextAlign.center,
                    style: AppText.fixed(size: 22, weight: 500),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
