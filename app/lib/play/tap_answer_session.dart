import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../child/activity_shell.dart';
import '../content/models.dart';
import '../design/components.dart';
import '../design/tokens.g.dart';
import '../speech/answer_matcher.dart';
import '../speech/hebrew_text.dart';
import 'lesson_controller.dart';
import 'template_session.dart';

/// The tap-the-answer template (T01): two to four pictures on the stage, one of them is right.
/// Used here for the warm-up "where is the red flower?".
class TapAnswerSession extends TemplateSession {
  TapAnswerSession(super.controller, this.activity);

  final TapAnswerActivity activity;

  String? chosenId;
  AnswerState chosenState = AnswerState.idle;
  bool _busy = false;
  int? pulsing;

  @override
  bool get listensNow => !_busy && chosenState != AnswerState.correct;

  @override
  String get voiceAnswerType => 'word';

  /// The words of each option: its own `speech` list, or else the words of its label that the other options do not
  /// share ("פרח אדום" and "פרח צהוב" are told apart by the colour).
  @override
  List<Expected> voiceExpected() {
    final List<List<String>> words = <List<String>>[
      for (final ChoiceOption o in activity.options)
        <String>[...o.speech, ...tokensOf(normalizeHebrew(o.label ?? ''))],
    ];
    final Set<String> shared = words.isEmpty
        ? <String>{}
        : words
              .map((List<String> w) => w.toSet())
              .reduce((Set<String> a, Set<String> b) => a.intersection(b));
    return <Expected>[
      for (final (int i, ChoiceOption o) in activity.options.indexed)
        Expected.words(o.id, <String>[
          for (final String w in words[i])
            if (!shared.contains(w) || o.speech.contains(w)) w,
        ], correct: o.id == activity.correctId),
    ];
  }

  @override
  Future<void> chooseByVoice(String optionId) => choose(optionId, byVoice: true);

  Future<void> choose(String id, {bool byVoice = false}) async {
    if (_busy || chosenState == AnswerState.correct) return;
    if (controller.guided && id != activity.correctId) return;
    _busy = true;
    chosenId = id;
    final Outcome o = await controller.chooseOption(id, byVoice: byVoice);
    if (disposed) return;
    if (o.correct) {
      chosenState = AnswerState.correct;
      notify();
      later(TemplateSession.praisePause, controller.next);
    } else {
      chosenState = AnswerState.notYet;
      notify();
      later(TemplateSession.notYetPause, () {
        chosenId = null;
        chosenState = AnswerState.idle;
        _busy = false;
        notify();
      });
    }
  }

  @override
  void onReset() {
    chosenId = null;
    chosenState = AnswerState.idle;
    _busy = false;
    pulsing = null;
    notify();
  }

  @override
  void onReplay() => _pulseAll();

  @override
  void onHint() => _pulseAll();

  void _pulseAll() {
    for (int i = 0; i < activity.options.length; i++) {
      later(Duration(milliseconds: 450 * i), () {
        pulsing = i;
        notify();
      });
    }
    later(Duration(milliseconds: 450 * activity.options.length), () {
      pulsing = null;
      notify();
    });
  }

  @override
  Widget buildStage(BuildContext context, Size size, ActivitySpec spec) =>
      ListenableBuilder(listenable: this, builder: (BuildContext c, Widget? _) => _TapStage(this, size));

  @override
  Widget? buildTiles(BuildContext context, ActivitySpec spec) => null;
}

class _TapStage extends StatelessWidget {
  const _TapStage(this.s, this.size);

  final TapAnswerSession s;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final TapAnswerActivity a = s.activity;
    final int n = a.options.length;
    final double box = math.min(size.height * 0.86, size.width / (n + 0.5));
    final double gap = (size.width - box * n) / (n + 1);
    return Semantics(
      container: true,
      label: a.altText,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(TokenRadius.lg),
        child: Stack(
          key: const Key('tap-stage'),
          children: <Widget>[
            if (a.background != null)
              Positioned.fill(child: PackSvg(a.assets.svg(a.background!), fit: BoxFit.cover)),
            for (final (int i, ChoiceOption o) in a.options.indexed)
              Positioned(
                left: gap + i * (box + gap),
                top: (size.height - box) / 2,
                width: box,
                height: box,
                child: _option(a, o, i, box),
              ),
          ],
        ),
      ),
    );
  }

  Widget _option(TapAnswerActivity a, ChoiceOption o, int i, double box) {
    final bool chosen = s.chosenId == o.id;
    final bool guidedRight = s.controller.guided && o.id == a.correctId;
    final bool dimmed = s.controller.guided && o.id != a.correctId;
    final Color? ring = chosen
        ? (s.chosenState == AnswerState.correct ? TokenColors.correctGlow : TokenColors.notYetRing)
        : (guidedRight || s.voiceLit == o.id ? TokenColors.hintHalo : null);
    return Semantics(
      button: true,
      label: o.label,
      child: GestureDetector(
        key: Key('option-${o.id}'),
        behavior: HitTestBehavior.opaque,
        onTap: () => s.choose(o.id),
        child: AnimatedScale(
          scale: s.pulsing == i ? 1.15 : 1,
          duration: const Duration(milliseconds: 250),
          child: Opacity(
            opacity: dimmed ? 0.35 : 1,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ring?.withValues(alpha: 0.22),
                border: ring == null ? null : Border.all(color: ring, width: 5),
              ),
              child: Padding(padding: const EdgeInsets.all(6), child: PackSvg(a.assets.svg(o.sprite!))),
            ),
          ),
        ),
      ),
    );
  }
}
