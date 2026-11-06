import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../child/activity_shell.dart';
import '../content/hint_ladder.dart';
import '../content/models.dart';
import '../design/app_text.dart';
import '../design/components.dart';
import '../design/course_text.dart';
import '../design/tokens.g.dart';
import '../speech/answer_matcher.dart';
import '../speech/spoken_options.dart';
import 'count_tap_session.dart' show Dots;
import 'caption_policy.dart';
import 'hint_widgets.dart';
import 'hints/hint_marks.dart';
import 'hints/hint_pictures.dart';
import 'hints/hint_player.dart';
import 'hints/tap_geometry.dart';
import 'hints/tap_plans.dart';
import 'lesson_controller.dart';
import 'math_signs.dart';
import '../design/layout.dart';
import 'option_faces.dart';
import 'sprite_group.dart';
import 'template_session.dart';

/// The tap-the-answer template (T01): two to four pictures on the stage, one of them is right.
/// Used here for the warm-up "where is the red flower?".
///
/// In a language course (LS01, docs/languages/frame.md section 2.3) an answer may also be a text in the course's font and
/// direction, with a speaker that plays its own clip without answering, or a sound button; a picture or a sound button says its
/// word as it is chosen; and, when [captions] is on, the word appears under the right picture once the answer is accepted.
class TapAnswerSession extends TemplateSession {
  TapAnswerSession(super.controller, this.activity, {this.captions = false, this.stress = true});

  final TapAnswerActivity activity;

  /// The word of the right picture appears under it after the answer (`captionAfterAnswer`), with its stress marks if [stress].
  final bool captions;
  final bool stress;

  /// The word to show under the right picture, or null when captions are off or the activity has none.
  String? get captionWord {
    final String? word = captions ? activity.revealedWord : null;
    return word == null ? null : withStress(word, show: stress);
  }

  /// True once the right answer has been accepted: the caption is shown from now on.
  bool get captionShown => chosenId == activity.correctId && chosenState == AnswerState.correct;

  /// The hint on the stage (see `HintPlayer`), and the answer tile that glows in turn where the stage has nothing of the question
  /// to light. The stage's end side is made room for a card by `_hint.reserve`.
  late final HintPlayer _hint = HintPlayer(this);
  List<HintMark> get marks => _hint.marks;
  double get reserve => _hint.reserve;
  int? get hintLit => activity.optionsInTiles ? _hint.litOption : null;
  Size? _stageSize;
  ActivitySpec? _spec;
  TextDirection _dir = TextDirection.rtl;

  /// The direction the row of answers runs in (and the hint's geometry is laid out in): the course's own for a language
  /// activity, the screen's for every land (docs/languages/frame.md, F1).
  TextDirection get _rowDir => courseRowDirection(activity.course) ?? _dir;

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
    if (!byVoice) _sayWord(id);
    // The dots of a first hint go with the child's next touch, and a demonstration (level 3) ends at any touch: the hand is taken
    // off at once, even for a wrong tile (the hint that the mistake brings starts a moment later).
    final bool demonstrating = controller.hintShown >= 3 && _hint.playing;
    if ((controller.hintShown <= 1 || demonstrating) && marks.isNotEmpty) _hint.clear();
    final Outcome o = await controller.chooseOption(id, byVoice: byVoice);
    if (disposed) return;
    if (o.correct || o.settled) {
      // A probe of the placement game ends on its one answer, right or not, and shows nothing "not yet".
      _hint.clear();
      chosenState = o.settled ? AnswerState.selected : AnswerState.correct;
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

  /// Some tile has a speaker (a text with a clip): the row of tiles then keeps the room under it, see [layoutFor].
  bool get _hasSpeakers => activity.options.any((ChoiceOption o) => o.text != null && o.clip != null);

  /// The tiles of an item with speakers stand higher, so that a speaker (64 points to touch) fits under each of them above the
  /// bottom edge where no hotspot may be (24); the stage, empty in such an item, gives way. A board with the room is unchanged.
  @override
  ActivitySpec layoutFor(ActivitySpec base) {
    if (!_hasSpeakers) return base;
    const double tile = 96;
    const double margin = 12;
    final double top = math.min(
      base.tilesTop,
      base.boardHeight - TokenTouch.bottomNoHotspot - SpeakerMark.room - margin - tile - margin,
    );
    if (top >= base.tilesTop) return base;
    return base.withStageAndTiles(
      stage: Rect.fromLTWH(
        base.stage.left,
        base.stage.top,
        base.stage.width,
        math.max(0, math.min(base.stage.height, top - 16 - base.stage.top)),
      ),
      tilesLeft: base.tilesLeft,
      tilesTop: top,
      tilesWidth: base.tilesWidth,
    );
  }

  /// A picture, or a sound button, says its word as it is chosen. A text tile has a speaker of its own and does not.
  void _sayWord(String id) {
    final ChoiceOption o = activity.options.firstWhere((ChoiceOption o) => o.id == id);
    if (o.clip != null && o.text == null) playClips?.call(<String>[o.clip!], replace: true);
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
      // A skill that no family knows (none in the starter pack): its options pulse, and there is no worked example before the halo.
      // Sound buttons play again, one after the other, as they pulse.
      final List<ChoiceOption> buttons = activity.options.where((ChoiceOption o) => o.soundOnly).toList();
      if (buttons.length == activity.options.length) {
        playClips?.call(<String>[for (final ChoiceOption o in buttons) o.clip!], replace: false);
      }
      _pulseAll();
      if (hintPictureOf(activity) == HintPicture.demonstration) controller.demoDone();
      return;
    }
    _play(plan);
  }

  TapGeometry? _geometry() {
    final Size? size = _stageSize;
    final ActivitySpec? spec = _spec;
    return size == null || spec == null ? null : TapGeometry(activity, size, spec, dir: _rowDir);
  }

  /// Plays a hint: each step of [plan] on the stage for its time, then what stays. Starting another hint (or an answer) stops it.
  void _play(HintPlan plan) => _hint.play(plan, onEnd: plan.endsDemo ? controller.demoDone : null);

  void _pulseAll() {
    // A word takes longer to say than a picture takes to light: sound buttons pulse more slowly.
    final int step = activity.options.every((ChoiceOption o) => o.soundOnly) ? 700 : 450;
    for (int i = 0; i < activity.options.length; i++) {
      later(Duration(milliseconds: step * i), () {
        pulsing = i;
        notify();
      });
    }
    later(Duration(milliseconds: step * activity.options.length), () {
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
  Widget? buildHands(BuildContext context, Size size, ActivitySpec spec) {
    // A tile of sets is wider than a numeral's tile (see `buildTiles`): the hand that comes in from the side stops at its edge.
    final double width = TapGeometry.tileWidthOf(activity, spec);
    double? rowEnd;
    if (activity.optionsInTiles) {
      final TapGeometry g = TapGeometry(activity, size, spec, dir: _rowDir);
      rowEnd =
          <double>[for (int i = 0; i < activity.options.length; i++) g.optionTip(i).dx].reduce(math.max) +
          width / 2;
    }
    return _hint.hands(size, spec, tileHalf: width / 2, rowEnd: rowEnd);
  }

  @override
  Widget? buildTiles(BuildContext context, ActivitySpec spec) {
    if (!activity.optionsInTiles) return null;
    // Numerals sit on square tiles; a set of things gets a wider one, as wide as the row allows.
    final bool sets = activity.options.any((ChoiceOption o) => o.set != null);
    final double width = TapGeometry.tileWidthOf(activity, spec);
    final bool letterItem = activity.letterFace;
    return ListenableBuilder(
      listenable: this,
      builder: (BuildContext c, Widget? _) => Directionality(
        textDirection: _rowDir,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            for (final (int i, ChoiceOption o) in activity.options.indexed)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Stack(
                    clipBehavior: Clip.none,
                    children: <Widget>[
                      Opacity(
                        opacity: controller.answerShown && o.id != activity.correctId ? 0.35 : 1,
                        child: AnswerTile(
                          key: Key('tile-${o.id}'),
                          semanticLabel: o.label ?? '',
                          width: width == 96 ? null : width,
                          state: chosenId == o.id
                              ? chosenState
                              : ((controller.answerShown && o.id == activity.correctId) || voiceLit == o.id
                                    ? AnswerState.selected
                                    : AnswerState.idle),
                          onPressed: () => choose(o.id),
                          child: sets
                              ? Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: _face(activity, o, 96, spec.tileFont, stress, letter: letterItem),
                                )
                              : _face(activity, o, 96, spec.tileFont, stress, letter: letterItem),
                        ),
                      ),
                      // The word of the right picture, under its tile, once the answer is accepted.
                      if (captionWord != null && o.id == activity.correctId)
                        Positioned(
                          left: 0,
                          right: 0,
                          top: 12 + 96 + 6,
                          child: IgnorePointer(
                            child: AnimatedOpacity(
                              opacity: captionShown ? 1 : 0,
                              duration: _fade(c),
                              child: RevealCaption(
                                key: const Key('reveal-caption'),
                                text: captionWord!,
                                course: activity.course,
                                size: spec.tileFont * 0.5,
                              ),
                            ),
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
                              child: IgnorePointer(
                                child: HintFlag(scale: hintScale(_stageSize ?? Size.zero)),
                              ),
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
                  // A text tile with a clip has a speaker under it: it plays the word and does not answer. It lies wholly under
                  // the tile and its tap margin, so it takes nothing from the tile's own touch area; every tile of the item has the
                  // room, so the row stays level.
                  if (_hasSpeakers)
                    SizedBox(
                      height: SpeakerMark.room,
                      child: o.text != null && o.clip != null
                          ? Center(
                              child: SpeakerMark(
                                key: Key('speaker-${o.id}'),
                                touch: AppLayout.of(c).touch.minControl,
                                onTap: () => playClips?.call(<String>[o.clip!], replace: true),
                              ),
                            )
                          : null,
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// What an option shows: a numeral on a tile with its dots, or a small set of things.
Widget _face(
  TapAnswerActivity a,
  ChoiceOption o,
  double box,
  double font,
  bool stress, {
  bool letter = false,
}) {
  if (o.text != null) {
    return OptionTextFace(
      text: withStress(o.text!, show: stress),
      course: a.course,
      tileFont: font,
      letter: letter,
    );
  }
  if (o.soundOnly) return const SoundFace();
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
    framed: answerGroupsFramed,
  );
}

/// The room under the pictures of the stage for the word revealed after the answer.
const double _captionRoom = 34;

/// How long a fade takes: none with reduce motion.
Duration _fade(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 250);

/// Whether the group of an answer tile is drawn with its ten-frame board. Never: a board on one answer and not on its neighbour
/// would tell the child which one to pick (QA-38-1), so within one activity every answer group is drawn the same way, and "the
/// same way" is no board. The group the question stands on (alone on the stage) keeps its board.
const bool answerGroupsFramed = false;

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
    // The word under the right picture (LS01 g) has its room from the start, so that nothing moves when it appears.
    final String? word = a.optionsInTiles ? null : s.captionWord;
    final double captionRoom = word == null ? 0 : _captionRoom;
    final double room = size.height - top - captionRoom;
    final double box = math.min(room * (hasGroup ? 0.9 : 0.86), size.width / (n + 0.5));
    final double gap = (size.width - box * n) / (n + 1);
    // A course that reads right to left lays its pictures out from the right (F1); the lands keep the first on the left.
    final bool fromRight = courseRowDirection(a.course) == TextDirection.rtl;
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
          if (a.row.isNotEmpty) Positioned.fill(child: _row(a, TapGeometry.rowLiftOf(a, size.height))),
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
                left: gap + (fromRight ? n - 1 - i : i) * (box + gap),
                top: top + (room - box) / 2,
                width: box,
                height: box,
                child: _option(a, o, i, box),
              ),
          if (word != null)
            for (final (int i, ChoiceOption o) in a.options.indexed)
              if (o.id == a.correctId)
                Positioned(
                  left: gap + (fromRight ? n - 1 - i : i) * (box + gap) - gap / 2,
                  top: top + (room - box) / 2 + box,
                  width: box + gap,
                  height: captionRoom,
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      opacity: s.captionShown ? 1 : 0,
                      duration: _fade(context),
                      child: Center(
                        child: RevealCaption(
                          key: const Key('reveal-caption'),
                          text: word,
                          course: a.course,
                          size: _captionRoom * 0.62,
                        ),
                      ),
                    ),
                  ),
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
  /// A number sentence stands [lift] lower, so that the cubes of a hint fit over its numbers (see [TapGeometry.rowLiftOf]).
  Widget _row(TapAnswerActivity a, double lift) => Padding(
    padding: EdgeInsets.fromLTRB(10, 10 + lift, 10, 10),
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
                                        ? signGlyph(r.substring(3), MathSigns.of(context))
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
    // A group scattered to be counted, alone on the stage, is drawn cut to its ink: a ladybug or a sock fills its place (its
    // picture has a wide margin) and reads on a phone. Never where two groups or a scale are compared, or a row is drawn.
    final bool inked = a.group2 == null && a.group!.arrangement == 'scatter' && a.group!.scale == 1;
    Widget one(SpriteSet g) => SpriteGroup(
      svg: inked ? inkedSvg(a.assets.svg(g.sprite)).$1 : a.assets.svg(g.sprite),
      count: g.count,
      arrangement: g.arrangement,
      seed: g.seed,
      scale: g.scale,
      lineSlots: TapGeometry.lineSlotsOf(a, g),
    );
    final List<SpriteSet> sets = <SpriteSet>[a.group!, ?a.group2];
    return Semantics(
      container: true,
      excludeSemantics: true,
      label: a.altText,
      child: Padding(
        padding: const EdgeInsets.all(12),
        // Two groups stand like "3 + 2", the first on the left, whatever the language (the hint stands on the same places).
        child: Directionality(
          textDirection: TextDirection.ltr,
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
      ),
    );
  }

  Widget _option(TapAnswerActivity a, ChoiceOption o, int i, double box) {
    final bool chosen = s.chosenId == o.id;
    final bool guidedRight = s.controller.answerShown && o.id == a.correctId;
    final bool dimmed = s.controller.answerShown && o.id != a.correctId;
    final Color? ring = chosen
        ? (s.chosenState == AnswerState.correct
              ? TokenColors.correctGlow
              : s.chosenState == AnswerState.selected
              ? TokenColors.hintHalo
              : TokenColors.notYetRing)
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
