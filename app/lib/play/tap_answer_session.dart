import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../child/activity_shell.dart';
import '../content/hint_ladder.dart';
import '../content/models.dart';
import '../design/app_text.dart';
import '../design/components.dart';
import '../design/tokens.g.dart';
import '../speech/answer_matcher.dart';
import '../speech/spoken_options.dart';
import 'count_tap_session.dart' show Dots;
import 'hint_widgets.dart';
import 'hints/hint_marks.dart';
import 'hints/hint_pictures.dart';
import 'hints/hint_player.dart';
import 'hints/tap_geometry.dart';
import 'hints/tap_plans.dart';
import 'lesson_controller.dart';
import 'sprite_group.dart';
import 'template_session.dart';

/// The tap-the-answer template (T01): two to four pictures on the stage, one of them is right.
/// Used here for the warm-up "where is the red flower?".
class TapAnswerSession extends TemplateSession {
  TapAnswerSession(super.controller, this.activity);

  final TapAnswerActivity activity;

  /// The hint on the stage (see `HintPlayer`), and the answer tile that glows in turn where the stage has nothing of the question
  /// to light. The stage's end side is made room for a card by `_hint.reserve`.
  late final HintPlayer _hint = HintPlayer(this);
  List<HintMark> get marks => _hint.marks;
  double get reserve => _hint.reserve;
  int? get hintLit => activity.optionsInTiles ? _hint.litOption : null;
  Size? _stageSize;
  ActivitySpec? _spec;
  TextDirection _dir = TextDirection.rtl;

  String? chosenId;
  AnswerState chosenState = AnswerState.idle;
  bool _busy = false;
  int? pulsing;

  /// The option on the stage that is grown a little now: one of a pulse of all, or the one a hint lights.
  int? get pulsingNow => pulsing ?? (activity.optionsInTiles ? null : _hint.litOption);

  @override
  bool get listensNow => !_busy && chosenState != AnswerState.correct;

  /// Answers that are numerals are spoken as numbers.
  @override
  String get voiceAnswerType =>
      activity.options.every((ChoiceOption o) => o.numeral != null) ? 'number' : 'word';

  /// The words of each option: its own `speech` list, and the words of its label that no other option has.
  @override
  List<Expected> voiceExpected() => expectedFor(<SpokenOption>[
    for (final ChoiceOption o in activity.options)
      SpokenOption(o.id, number: o.numeral, label: o.label ?? '', speech: o.speech),
  ], correctId: activity.correctId);

  @override
  Future<void> chooseByVoice(String optionId) => choose(optionId, byVoice: true);

  Future<void> choose(String id, {bool byVoice = false}) async {
    if (_busy || chosenState == AnswerState.correct) return;
    if (controller.guided && id != activity.correctId) return;
    _busy = true;
    chosenId = id;
    // The dots of a first hint go with the child's next touch; a hint that is still playing stops when the answer is right.
    if (controller.hintShown <= 1 && marks.isNotEmpty) _hint.clear();
    final Outcome o = await controller.chooseOption(id, byVoice: byVoice);
    if (disposed) return;
    if (o.correct) {
      _hint.clear();
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
    _hint.clear();
    notify();
  }

  @override
  void onReplay() => _pulseAll();

  @override
  void onHint() {
    final TapGeometry? geo = _geometry();
    final HintPlan? plan = geo == null ? null : tapHintPlan(activity, geo, controller.hintShown);
    if (plan == null) {
      // A family without pictures yet: its options pulse, and there is no worked example to show before the halo.
      _pulseAll();
      if (hintPictureOf(activity) == HintPicture.demonstration) controller.demoDone();
      return;
    }
    _play(plan);
  }

  TapGeometry? _geometry() {
    final Size? size = _stageSize;
    final ActivitySpec? spec = _spec;
    return size == null || spec == null ? null : TapGeometry(activity, size, spec, dir: _dir);
  }

  /// Plays a hint: each step of [plan] on the stage for its time, then what stays. Starting another hint (or an answer) stops it.
  void _play(HintPlan plan) => _hint.play(plan, onEnd: plan.endsDemo ? controller.demoDone : null);

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
  Widget buildStage(BuildContext context, Size size, ActivitySpec spec) {
    _stageSize = size;
    _spec = spec;
    _dir = Directionality.of(context);
    return ListenableBuilder(listenable: this, builder: (BuildContext c, Widget? _) => _TapStage(this, size));
  }

  @override
  Widget? buildHands(BuildContext context, Size size, ActivitySpec spec) => _hint.hands(size, spec);

  @override
  Widget? buildTiles(BuildContext context, ActivitySpec spec) {
    if (!activity.optionsInTiles) return null;
    final int n = activity.options.length;
    // Numerals sit on square tiles; a set of things gets a wider one, as wide as the row allows.
    final bool sets = activity.options.any((ChoiceOption o) => o.set != null);
    final double width = math.min(170, spec.tilesWidth / n - 24);
    return ListenableBuilder(
      listenable: this,
      builder: (BuildContext c, Widget? _) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          for (final (int i, ChoiceOption o) in activity.options.indexed)
            Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                Opacity(
                  opacity: controller.answerShown && o.id != activity.correctId ? 0.35 : 1,
                  child: AnswerTile(
                    key: Key('tile-${o.id}'),
                    semanticLabel: o.label ?? '',
                    width: sets ? width : null,
                    state: chosenId == o.id
                        ? chosenState
                        : ((controller.answerShown && o.id == activity.correctId) || voiceLit == o.id
                              ? AnswerState.selected
                              : AnswerState.idle),
                    onPressed: () => choose(o.id),
                    child: sets
                        ? Padding(
                            padding: const EdgeInsets.all(6),
                            child: _face(activity, o, 96, spec.tileFont),
                          )
                        : _face(activity, o, 96, spec.tileFont),
                  ),
                ),
                // A place badge, and a start flag at the first end of the row, stand on the tiles (a tile paints above the stage and
                // the speech bubble, so they are never covered by the bubble).
                for (final TileMark m in marks.whereType<TileMark>())
                  if (m.tile == i)
                    switch (m) {
                      TileBadgeMark() => Positioned(
                        top: 12 - 23 * hintScale(_stageSize ?? Size.zero),
                        left: 0,
                        right: 0,
                        child: IgnorePointer(
                          child: Center(
                            child: HintBadge(n: m.n, scale: hintScale(_stageSize ?? Size.zero)),
                          ),
                        ),
                      ),
                      TileFlagMark() => Positioned(
                        top: 12 - 26 * hintScale(_stageSize ?? Size.zero),
                        right: 12 - 20 * hintScale(_stageSize ?? Size.zero),
                        child: IgnorePointer(child: HintFlag(scale: hintScale(_stageSize ?? Size.zero))),
                      ),
                    },
                // Where the stage has nothing of the question to light, a first hint lights each answer in turn, the same for all.
                if (hintLit == i)
                  Positioned.fill(
                    left: 6,
                    top: 6,
                    right: 6,
                    bottom: 6,
                    child: IgnorePointer(
                      child: const SkyRing(
                        key: Key('hint-tile-glow'),
                        round: false,
                        radius: TokenRadius.xl + 6,
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// What an option shows: a numeral on a tile with its dots, or a small set of things.
Widget _face(TapAnswerActivity a, ChoiceOption o, double box, double font) {
  if (o.numeral != null) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text('${o.numeral}', style: AppText.fixed(size: font, weight: 800, lineHeight: 1)),
          const SizedBox(height: 4),
          FittedBox(fit: BoxFit.scaleDown, child: Dots(o.numeral!)),
        ],
      ),
    );
  }
  if (o.set == null) {
    return Padding(padding: const EdgeInsets.all(6), child: PackSvg(a.assets.svg(o.sprite!)));
  }
  final SpriteSet g = o.set!;
  return SpriteGroup(
    svg: a.assets.svg(g.sprite),
    count: g.count,
    arrangement: g.arrangement,
    seed: g.seed,
    scale: g.scale,
  );
}

class _TapStage extends StatelessWidget {
  const _TapStage(this.s, this.size);

  final TapAnswerSession s;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final TapAnswerActivity a = s.activity;
    final int n = a.options.length;
    // A group to count or compare takes the top of the stage; the answers sit below it.
    final bool hasGroup = a.group != null;
    final double top = hasGroup && !a.optionsInTiles ? size.height * 0.5 : 0;
    final double room = size.height - top;
    final double box = math.min(room * (hasGroup ? 0.9 : 0.86), size.width / (n + 0.5));
    final double gap = (size.width - box * n) / (n + 1);
    final Widget stage = ClipRRect(
      borderRadius: BorderRadius.circular(TokenRadius.lg),
      child: Stack(
        key: const Key('tap-stage'),
        children: <Widget>[
          if (a.background != null)
            Positioned.fill(child: PackSvg(a.assets.svg(a.background!), fit: BoxFit.cover)),
          if (hasGroup)
            AnimatedPositioned(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              left: s.reserve,
              top: 0,
              width: size.width - s.reserve,
              height: a.optionsInTiles ? size.height : top,
              child: _groups(a),
            ),
          if (a.row.isNotEmpty) Positioned.fill(child: _row(a)),
          if (a.chart.isNotEmpty) Positioned.fill(child: _chart(a)),
          if (a.stageNumeral != null)
            Positioned.fill(
              child: Center(
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    '${a.stageNumeral}',
                    key: const Key('stage-numeral'),
                    style: AppText.fixed(size: size.height * 0.7, weight: 800, lineHeight: 1),
                  ),
                ),
              ),
            ),
          if (!a.optionsInTiles)
            for (final (int i, ChoiceOption o) in a.options.indexed)
              Positioned(
                left: gap + i * (box + gap),
                top: top + (room - box) / 2,
                width: box,
                height: box,
                child: _option(a, o, i, box),
              ),
        ],
      ),
    );
    return Semantics(
      container: true,
      label: a.altText,
      // The hint's pictures lie over the stage and may reach past its edge (the hand ends on the top of an answer tile).
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: <Widget>[
          stage,
          if (s.marks.isNotEmpty) HintOverlay(marks: s.marks, size: size, layer: HintLayer.body),
        ],
      ),
    );
  }

  /// A chart to read: a column of pictures for each category, standing on one line. Left to right, whatever the language.
  Widget _chart(TapAnswerActivity a) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints box) {
          final int most = a.chart.fold(1, (int m, ({String sprite, int count}) c) => math.max(m, c.count));
          final double cell = math.min((box.maxHeight - 6) / most, box.maxWidth / a.chart.length - 14);
          return Container(
            key: const Key('tap-chart'),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: TokenColors.ink, width: 3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                for (final ({String sprite, int count}) c in a.chart)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      for (int i = 0; i < c.count; i++)
                        SizedBox(width: cell, height: cell, child: PackSvg(a.assets.svg(c.sprite))),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    ),
  );

  /// The row of pictures of a pattern or an order; a `?` is the gap the child fills in. Left to right, whatever the language.
  Widget _row(TapAnswerActivity a) => Padding(
    padding: const EdgeInsets.all(10),
    child: Directionality(
      textDirection: TextDirection.ltr,
      // The cells come one by one from the left, so the child sees where the row starts; the "?" is last.
      child: RowEntrance(
        count: a.row.length,
        builder: (BuildContext context, Widget Function(int, Widget) cell) => Row(
          key: const Key('tap-row'),
          children: <Widget>[
            for (final (int i, String r) in a.row.indexed)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: cell(
                    i,
                    r == '?'
                        ? DecoratedBox(
                            decoration: BoxDecoration(
                              color: TokenColors.paper.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(TokenRadius.lg),
                              border: Border.all(color: TokenColors.hairline, width: 3),
                            ),
                            child: Center(
                              child: Text('?', style: AppText.fixed(size: 36, weight: 800, lineHeight: 1)),
                            ),
                          )
                        : (r.startsWith('asset:')
                              ? PackSvg(a.assets.svg(r))
                              : FittedBox(
                                  child: Text(
                                    r.startsWith('op:')
                                        ? r.substring(3).replaceAll('-', '−').replaceAll('x', '×')
                                        : r.substring(2),
                                    style: AppText.fixed(size: 40, weight: 800, lineHeight: 1),
                                  ),
                                )),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );

  /// The group (or the two groups, side by side) that the question is about. Not tappable.
  Widget _groups(TapAnswerActivity a) {
    Widget one(SpriteSet g) => SpriteGroup(
      svg: a.assets.svg(g.sprite),
      count: g.count,
      arrangement: g.arrangement,
      seed: g.seed,
      scale: g.scale,
    );
    final List<SpriteSet> sets = <SpriteSet>[a.group!, ?a.group2];
    return Semantics(
      container: true,
      excludeSemantics: true,
      label: a.altText,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          key: const Key('tap-groups'),
          children: <Widget>[
            for (final SpriteSet g in sets)
              Expanded(
                child: Padding(padding: const EdgeInsets.all(6), child: one(g)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _option(TapAnswerActivity a, ChoiceOption o, int i, double box) {
    final bool chosen = s.chosenId == o.id;
    final bool guidedRight = s.controller.answerShown && o.id == a.correctId;
    final bool dimmed = s.controller.answerShown && o.id != a.correctId;
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
          scale: s.pulsingNow == i ? 1.15 : 1,
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
