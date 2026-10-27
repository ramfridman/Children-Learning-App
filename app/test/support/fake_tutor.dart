import 'dart:async';
import 'dart:typed_data';

import 'package:nitznutz/tutor/tutor.dart';

/// A tutor service that does what the test says, and records every question it was asked.
class FakeTutorClient implements TutorClient {
  final List<TutorAsk> asked = <TutorAsk>[];

  /// How long each answer takes.
  Duration delay = Duration.zero;

  /// While set and not completed, every answer waits for it (a service that does not answer until the test lets it).
  Completer<void>? gate;

  /// A reason to answer with instead of a line (a RuleTutor answer), or null to make lines.
  String? rule;

  /// What the question is answered with, per mistake.
  String lineOf(TutorAsk a, String mistake) => 'line for $mistake at level ${a.hintLevel}';

  @override
  Future<List<TutorResult>> ask(TutorAsk ask) async {
    asked.add(ask);
    if (gate != null) await gate!.future;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    return <TutorResult>[
      for (final String m in ask.mistakes)
        if (rule != null)
          TutorResult.rule(m, rule!)
        else
          TutorResult.line(
            TutorLine(
              mistake: m,
              source: ask.prefetch ? 'prefetch' : 'live',
              line: lineOf(ask, m),
              caption: ask.band == 'A' ? null : lineOf(ask, m),
              next: 'show_fingers',
              highlight: const <String>[],
              misconception: m == 'default' ? null : m,
              audio: Uint8List.fromList('live:$m:${ask.hintLevel}'.codeUnits),
            ),
          ),
    ];
  }
}
