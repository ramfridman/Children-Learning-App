import 'package:flutter/material.dart';

import '../child/activity_shell.dart';
import '../content/models.dart';
import '../design/app_text.dart';
import '../design/components.dart';
import '../design/tokens.g.dart';
import '../speech/answer_matcher.dart';
import 'lesson_controller.dart';
import 'sprite_group.dart';
import 'template_session.dart';

/// The flash template (T14): a group of things is shown for a moment and covered, and the child says how many without
/// counting. Seeing a small number at a glance (subitising) is trained by the glance, so nothing here can be counted
/// by touch, and nothing races the child: the group can be shown again as often as they like.
///
/// A mistake shows the group again (longer); the third help keeps it in view while the child answers.
class FlashSession extends TemplateSession {
  FlashSession(super.controller, this.activity) {
    // Give the question a moment to be asked before the group appears.
    later(startDelay, () => _show(activity.flashMs));
  }

  final FlashActivity activity;

  /// The pause between the question and the first flash.
  static const Duration startDelay = Duration(milliseconds: 1400);

  /// The group is in view now.
  bool visible = false;

  /// The group has been seen and covered: the answers are on offer.
  bool answering = false;

  /// The group stays in view while the child answers (the worked example).
  bool _kept = false;

  String? chosenId;
  AnswerState chosenState = AnswerState.idle;
  bool _busy = false;
  int _flashes = 0;

  void _show(int ms) {
    final int mine = ++_flashes;
    visible = true;
    notify();
    later(Duration(milliseconds: ms), () {
      if (mine != _flashes) return; // a newer flash has taken over
      visible = _kept;
      answering = true;
      notify();
    });
  }

  /// The child touches the cover to see the group again.
  void showAgain() {
    if (visible || _busy) return;
    _show(activity.flashMs * 2);
  }

  @override
  bool get listensNow => answering && !_busy && chosenState != AnswerState.correct;

  @override
  String get voiceAnswerType => 'number';

  @override
  List<Expected> voiceExpected() => <Expected>[
    for (final ChoiceOption o in activity.options)
      Expected.number(o.id, o.numeral!, correct: o.id == activity.correctId, also: o.speech),
  ];

  @override
  Future<void> chooseByVoice(String optionId) => choose(optionId, byVoice: true);

  Future<void> choose(String id, {bool byVoice = false}) async {
    if (!answering || _busy || chosenState == AnswerState.correct) return;
    if (controller.guided && id != activity.correctId) return;
    _busy = true;
    chosenId = id;
    final Outcome o = await controller.chooseOption(id, byVoice: byVoice);
    if (disposed) return;
    if (o.correct) {
      chosenState = AnswerState.correct;
      visible = true;
      notify();
      later(TemplateSession.praisePause, controller.next);
    } else {
      chosenState = AnswerState.notYet;
      notify();
      later(TemplateSession.notYetPause, () {
        chosenId = null;
        chosenState = AnswerState.idle;
        _busy = false;
        // Look again, a little longer; or, when only the right answer is left, keep it in view.
        _kept = controller.guided;
        answering = false;
        _show(activity.flashMs * 2);
        notify();
      });
    }
  }

  @override
  void onReset() {
    chosenId = null;
    chosenState = AnswerState.idle;
    _busy = false;
    _kept = false;
    answering = false;
    _show(activity.flashMs);
  }

  @override
  void onReplay() {
    if (!_busy) _show(activity.flashMs);
  }

  @override
  void onHint() {
    if (_busy) return;
    _kept = controller.hintAction == HintAction.workedExample;
    _show(activity.flashMs * 2);
  }

  @override
  Widget buildStage(BuildContext context, Size size, ActivitySpec spec) =>
      ListenableBuilder(listenable: this, builder: (BuildContext c, Widget? _) => _FlashStage(this, size));

  @override
  Widget? buildTiles(BuildContext context, ActivitySpec spec) => ListenableBuilder(
    listenable: this,
    builder: (BuildContext c, Widget? _) => IgnorePointer(
      ignoring: !answering,
      child: AnimatedOpacity(
        opacity: answering ? 1 : 0,
        duration: const Duration(milliseconds: 300),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            for (final ChoiceOption o in activity.options)
              Opacity(
                opacity: controller.guided && o.id != activity.correctId ? 0.35 : 1,
                child: AnswerTile(
                  key: Key('tile-${o.id}'),
                  semanticLabel: '${o.numeral}',
                  state: chosenId == o.id
                      ? chosenState
                      : ((controller.guided && o.id == activity.correctId) || voiceLit == o.id
                            ? AnswerState.selected
                            : AnswerState.idle),
                  onPressed: () => choose(o.id),
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      '${o.numeral}',
                      style: AppText.fixed(size: spec.tileFont, weight: 800, lineHeight: 1),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class _FlashStage extends StatelessWidget {
  const _FlashStage(this.s, this.size);

  final FlashSession s;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final FlashActivity a = s.activity;
    final SpriteSet g = a.group;
    // While the group is in view the answers are hidden, so it may use the room below the stage as well.
    final double room = s.answering ? size.height : size.height * 1.9;
    return Semantics(
      container: true,
      label: a.altText,
      child: Stack(
        key: const Key('flash-stage'),
        clipBehavior: Clip.none,
        children: <Widget>[
          if (a.background != null)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(TokenRadius.lg),
                child: PackSvg(a.assets.svg(a.background!), fit: BoxFit.cover),
              ),
            ),
          if (s.visible && !s.answering)
            Positioned(
              left: 0,
              top: 0,
              width: size.width,
              height: room,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: TokenColors.paper.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(TokenRadius.lg),
                ),
              ),
            ),
          Positioned(
            left: 0,
            top: 0,
            width: size.width,
            height: s.visible ? room : size.height,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: s.visible
                    ? SpriteGroup(
                        key: const Key('flash-group'),
                        svg: a.assets.svg(g.sprite),
                        count: g.count,
                        arrangement: g.arrangement,
                        seed: g.seed,
                        scale: g.scale,
                      )
                    : _Cover(key: const Key('flash-cover'), onTap: s.showAgain, canShowAgain: s.answering),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The cloud that hides the group. Touching it shows the group again.
class _Cover extends StatelessWidget {
  const _Cover({super.key, required this.onTap, required this.canShowAgain});

  final VoidCallback onTap;
  final bool canShowAgain;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: canShowAgain ? onTap : null,
    child: Center(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: TokenColors.paper.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(TokenRadius.lg),
        ),
        child: const SizedBox(width: 140, height: 90, child: Icon(Icons.visibility, size: 44)),
      ),
    ),
  );
}
