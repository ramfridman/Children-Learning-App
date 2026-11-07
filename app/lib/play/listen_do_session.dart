import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../child/activity_shell.dart';
import '../content/hint_ladder.dart';
import '../content/models.dart';
import '../design/board.dart' show BoardClass;
import '../design/components.dart';
import '../content/scripts.dart' show isSingleLetter;
import '../design/course_text.dart';
import '../design/layout.dart' show AppLayout;
import '../design/token_types.dart' show Band;
import '../design/tokens.g.dart';
import '../strings/he.dart';
import 'choice_row.dart';
import 'choice_session.dart';
import 'hints/hint_pictures.dart' show SkyRing;
import 'caption_policy.dart' show withStress;
import 'lesson_controller.dart' show LessonController;
import 'ls01_metrics.dart';
import 'template_session.dart';

/// The listen-and-do template (LS11, docs/languages/frame.md section 2.3): the command is heard and the child carries it out in a
/// scene, five ways. **hotspots**: touch one of the parts of the picture (a body, a room), drawn only when a hint or the child's choice lights it; a part that is not an option does not
/// exist. **buttons**: touch one of the action pictures, and the friend on the stage does the one chosen. **drag**: one of the things
/// goes to the target (a plate, a box, the friend); **place**: the one thing goes to one of the places. A thing is dragged, or touched
/// and then the target touched (the tap path always works), and a wrong one goes back to where it was: nothing is red and nothing is
/// taken away. **embodied**: the child does it and touches "done": it is practice, never counted alone, and writes nothing.
///
/// The hints: level 1 lights the parts one after the other; level 2 shows what the command names in a close-up card beside the scene
/// (a new representation); level 3 shows it done: the right thing is carried to its place, and then only the right move is taken.
class ListenDoSession extends ChoiceSession {
  ListenDoSession(LessonController controller, ListenDoActivity activity, {this.band = Band.b, super.stress})
    : doing = activity,
      super(controller, activity, activity);

  final ListenDoActivity doing;

  /// The presentation band of the course: a letter stone of a `place` item (a text face, LS01 a) is read at the reading size of the band.
  final Band band;

  /// The thing the child touched, waiting for the target to be touched (the tap path of a drag).
  String? selectedId;

  /// The close-up card of what the command names is on the stage (hint level 2).
  bool closeUp = false;

  /// The right thing is being carried to its place (hint level 3).
  bool demoMove = false;

  String get mode => doing.mode;

  bool get dragging => mode == 'drag' || mode == 'place';

  /// The option the child's choice (or the demonstration) put in place: its thing sits in the target.
  bool get done => chosenState == AnswerState.correct || demoMove;

  /// The friend does what the button said: the picture of the chosen action, while the choice stands.
  String? get reaction {
    if (mode != 'buttons') return null;
    // At level 2 the friend does the action on its own (a new representation), until the child touches a button.
    final String? id = chosenId ?? (closeUp ? correctId : null);
    return id == null ? null : options.firstWhere((ChoiceOption o) => o.id == id).sprite;
  }

  /// The face items of `cards` mode ring the part of the friend that a card names: the card touched, the one a hint lights, and at
  /// level 2 the right one (both ears for "ears").
  Set<String> get ringed {
    if (mode != 'cards') return const <String>{};
    return <String>{
      ?chosenId,
      if (litTile != null) options[litTile!].id,
      if (closeUp && chosenId == null) correctId,
    };
  }

  /// A thing is touched to be taken to the target.
  void select(String id) {
    if (busy || chosenState == AnswerState.correct) return;
    selectedId = selectedId == id ? null : id;
    notify();
  }

  /// A thing was dropped on the target (or the target was touched with one selected): the choice is the thing (`drag`) or the place
  /// (`place`).
  void drop(String optionId) {
    selectedId = null;
    choose(optionId);
  }

  /// The "done" of an embodied step: nothing is written.
  void finish() {
    controller.completePractice();
    later(TemplateSession.praisePause, controller.next);
  }

  @override
  void onChosen(ChoiceOption o) {
    selectedId = null;
  }

  // ---- hints ----

  @override
  void onReset() {
    super.onReset();
    selectedId = null;
    closeUp = false;
    demoMove = false;
  }

  @override
  void onHint() {
    switch (hintPictureOf(activity)) {
      case HintPicture.friendActs:
        closeUp = true;
        notify();
      case HintPicture.demonstration:
        demoMove = true;
        notify();
        later(const Duration(milliseconds: 1000), controller.demoDone);
      default:
        pulseTiles();
    }
  }

  // ---- layout ----

  /// The answers are tiles under the stage: the action buttons, and the close-up cards of a face item (the friend stays on the stage).
  bool get tiled => mode == 'buttons' || mode == 'cards';

  @override
  bool get showsSpeakers => false;

  @override
  ActivitySpec layoutFor(ActivitySpec base) => tiled ? base : withTallStage(base);

  /// Where the close-up card of level 2 stands, in the board's points: a slot of its own outside the scene, so that it can never cover
  /// a place the child must touch (docs/design/languages-l4-layout.md section 3). The tablet portrait's is in the band under the scene,
  /// at the end corner in the course's direction.
  static ({double x, double y, double side}) closeUpSlot(BoardClass board, bool rtl) => switch (board) {
    BoardClass.phone => (x: 413, y: 248, side: 96),
    BoardClass.phoneSE => (x: 300, y: 222, side: 96),
    BoardClass.tabletLandscape => (x: 136, y: 300, side: 130),
    BoardClass.tabletPortrait => (x: rtl ? 30 : 660, y: 998, side: 130),
  };

  /// The scene's side on the tablet portrait keeps a band of 150 under it for the card (the tall stage is 764 high).
  static const double portraitBand = 150;

  @override
  Widget? buildBoardLayer(BuildContext context, ActivitySpec spec) {
    if (tiled || doing.embodied) return null;
    final BoardClass board = AppLayout.of(context).board;
    final bool rtl = rowDirection == TextDirection.rtl;
    // The layer listens to the session itself: the card appears when the hint's own pause is over, not with the controller's change.
    return Positioned.fill(
      child: IgnorePointer(
        child: ListenableBuilder(
          listenable: this,
          builder: (BuildContext c, Widget? _) {
            if (!closeUp) return const SizedBox();
            final ({double x, double y, double side}) slot = closeUpSlot(board, rtl);
            return Stack(
              children: <Widget>[
                Positioned(
                  left: slot.x,
                  top: slot.y,
                  width: slot.side,
                  height: slot.side,
                  child: closeUpCard(doing, correctId, slot.side),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget buildStage(BuildContext context, Size size, ActivitySpec spec) =>
      ListenableBuilder(listenable: this, builder: (BuildContext c, Widget? _) => _DoStage(this, size));

  @override
  Widget? buildTiles(BuildContext context, ActivitySpec spec) =>
      tiled ? choiceTiles(context, spec, speakers: false) : null;
}

class _DoStage extends StatelessWidget {
  const _DoStage(this.s, this.size);

  final ListenDoSession s;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final ListenDoActivity a = s.doing;
    return Semantics(
      container: true,
      label: a.altText,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(TokenRadius.lg),
        child: Stack(
          key: const Key('do-stage'),
          children: <Widget>[
            if (a.background != null)
              Positioned.fill(child: PackSvg(a.assets.svg(a.background!), fit: BoxFit.cover)),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints box) => _sceneBox(context, box),
                ),
              ),
            ),
            if (a.embodied) _doneButton(context),
          ],
        ),
      ),
    );
  }

  /// The scene's square in its room: centred, but on the tablet portrait it keeps the band under it for the close-up card.
  Widget _sceneBox(BuildContext context, BoxConstraints box) {
    final bool portrait =
        AppLayout.of(context).board == BoardClass.tabletPortrait && !s.tiled && !s.doing.embodied;
    final double side = math.min(
      box.maxWidth,
      portrait ? box.maxHeight - (ListenDoSession.portraitBand - 16) : box.maxHeight,
    );
    final Widget scene = _scene(context, side);
    return portrait ? Align(alignment: Alignment.topCenter, child: scene) : Center(child: scene);
  }

  /// The square of the scene, [side] points wide: the picture, and what is in it.
  Widget _scene(BuildContext context, double side) {
    final ListenDoActivity a = s.doing;
    Rect px(Rect r) => Rect.fromLTWH(r.left * side, r.top * side, r.width * side, r.height * side);
    final String? reaction = s.reaction;
    return SizedBox(
      key: Key('do-scene-${a.mode}'),
      width: side,
      height: side,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Positioned.fill(child: PackSvg(a.assets.svg(reaction ?? a.picture))),
          if (a.mode == 'cards')
            for (final ChoiceOption o in a.options)
              if (s.ringed.contains(o.id))
                for (final Rect r in o.ats)
                  Positioned.fromRect(
                    rect: px(r),
                    child: const IgnorePointer(
                      child: SkyRing(key: Key('do-part-ring'), radius: TokenRadius.xl),
                    ),
                  ),
          if (a.mode == 'hotspots')
            for (final (int i, ChoiceOption o) in a.options.indexed)
              for (final (int k, Rect r) in o.ats.indexed) _hotspot(px(r), o, i, k),
          if (a.mode == 'drag') ...<Widget>[
            _zone(px(a.targetAt!), key: const Key('do-target'), sprite: a.targetSprite, onTap: _dropSelected),
            for (final (int i, ChoiceOption o) in a.options.indexed)
              _piece(context, px(o.at!), px(a.targetAt!), o.id, o.sprite!, o, i),
          ],
          if (a.mode == 'place') ...<Widget>[
            for (final (int i, ChoiceOption o) in a.options.indexed)
              _zone(px(o.at!), key: Key('do-place-${o.id}'), option: o, index: i, onTap: () => s.drop(o.id)),
            _piece(
              context,
              px(a.thingAt!),
              px(a.options.firstWhere((ChoiceOption o) => o.id == s.correctId).at!),
              'thing',
              a.thingSprite!,
              null,
              0,
            ),
          ],
        ],
      ),
    );
  }

  /// A part of the picture that a touch takes as the answer. At rest nothing is drawn on it (the picture shows as it was drawn, and a
  /// friend's face is never covered by a mask); a hint's light or the child's choice draws a ring on it.
  Widget _hotspot(Rect r, ChoiceOption o, int i, int place) => Positioned.fromRect(
    rect: r,
    child: Semantics(
      button: true,
      label: o.label,
      child: GestureDetector(
        key: Key(place == 0 ? 'do-hot-${o.id}' : 'do-hot-${o.id}-$place'),
        behavior: HitTestBehavior.opaque,
        onTap: () => s.choose(o.id),
        child: _partRing(o, i),
      ),
    ),
  );

  /// The ring on a part: none at rest; a thin outline and no fill when a hint lights it, the child chose it or the help is at its top.
  /// A fill over a picture hides it, and on a character's face it is a mask, so a part is only ever outlined.
  Widget _partRing(ChoiceOption o, int i) {
    final bool chosen = s.chosenId == o.id;
    final bool lit = s.litTile == i || (s.controller.answerShown && o.id == s.correctId);
    if (!lit && !chosen) return const SizedBox.expand(key: Key('do-part-rest'));
    return DecoratedBox(
      key: const Key('do-part-lit'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(TokenRadius.xl),
        border: Border.all(color: _ringColor(o).withValues(alpha: 0.95), width: 5),
      ),
    );
  }

  /// The colour of the ring of an option: the child's choice shows by its state, anything else is the hint halo.
  Color _ringColor(ChoiceOption o) => s.chosenId == o.id
      ? (s.chosenState == AnswerState.correct
            ? TokenColors.correctGlow
            : s.chosenState == AnswerState.notYet
            ? TokenColors.notYetRing
            : TokenColors.hintHalo)
      : TokenColors.hintHalo;

  /// The ring around an option's place of a `place` item: always faintly there (a glow), lit by a hint, coloured by the child's choice,
  /// and on the right one once the help is at its top.
  Widget _ring(ChoiceOption o, int i) {
    final bool chosen = s.chosenId == o.id;
    final bool shown = s.controller.answerShown && o.id == s.correctId;
    final bool dimmed = s.controller.answerShown && o.id != s.correctId;
    final bool lit = s.litTile == i || shown;
    final Color color = _ringColor(o);
    return Opacity(
      opacity: dimmed ? 0.35 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: lit || chosen ? 0.3 : 0.12),
          borderRadius: BorderRadius.circular(TokenRadius.xl),
          border: Border.all(
            color: color.withValues(alpha: lit || chosen ? 0.95 : 0.5),
            width: lit || chosen ? 5 : 3,
          ),
        ),
      ),
    );
  }

  /// The letter, unit or word on a place (a letter stone, L5-1): LS01's text face at the reading size of the band, in the course's font. The
  /// place has no sound of its own; the stone says nothing when it is touched.
  Widget _stoneText(BuildContext context, ChoiceOption o) {
    final Ls01Metrics m = Ls01Metrics(
      band: s.band,
      tablet: AppLayout.of(context).isTablet,
      course: s.doing.course,
    );
    final String text = withStress(o.text!, show: s.stress);
    final bool letter = isSingleLetter(text);
    return IgnorePointer(
      child: Center(
        key: Key('do-place-text-${o.id}'),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: CourseText(
            text,
            course: m.course,
            size: m.size(letter ? FaceKind.letter : FaceKind.word),
            bold: letter,
            lineHeight: lineHeightFor(text, hebrew: m.hebrew),
          ),
        ),
      ),
    );
  }

  /// Where a thing is put down: the target of a drag or one place of a `place`. A touch on it, with a thing selected, puts it there.
  Widget _zone(
    Rect r, {
    required Key key,
    String? sprite,
    ChoiceOption? option,
    int index = 0,
    required VoidCallback onTap,
  }) {
    final ListenDoActivity a = s.doing;
    return Positioned.fromRect(
      rect: r,
      child: DragTarget<String>(
        onWillAcceptWithDetails: (DragTargetDetails<String> d) => !s.busy,
        onAcceptWithDetails: (DragTargetDetails<String> d) => s.drop(a.mode == 'drag' ? d.data : option!.id),
        builder: (BuildContext context, List<String?> over, List<Object?> rejected) => Semantics(
          button: true,
          label: option?.label ?? a.options.first.label,
          child: GestureDetector(
            key: key,
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: option != null
                ? Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      _ring(option, index),
                      if (option.text != null) _stoneText(context, option),
                    ],
                  )
                : DecoratedBox(
                    decoration: BoxDecoration(
                      color: TokenColors.skyTint.withValues(alpha: over.isEmpty ? 0.4 : 0.9),
                      borderRadius: BorderRadius.circular(TokenRadius.xl),
                      border: Border.all(color: TokenColors.hintHalo, width: 4),
                    ),
                    child: sprite == null
                        ? null
                        : Padding(padding: const EdgeInsets.all(6), child: PackSvg(a.assets.svg(sprite))),
                  ),
          ),
        ),
      ),
    );
  }

  /// A thing that is taken to the target: dragged, or touched and then the target touched. It sits where it started until it is put
  /// in place (then it sits in [end], the target or the place); a wrong one stays where it started, so it "goes back".
  Widget _piece(
    BuildContext context,
    Rect start,
    Rect? end,
    String id,
    String sprite,
    ChoiceOption? option,
    int i,
  ) {
    final ListenDoActivity a = s.doing;
    final bool isThing = option == null;
    final bool right = isThing ? s.done : (s.done && option.id == s.correctId);
    final bool dimmed = !isThing && s.controller.answerShown && option.id != s.correctId;
    final Rect at = right && end != null
        ? Rect.fromCenter(center: end.center, width: start.width, height: start.height)
        : start;
    final bool selected = s.selectedId == id;
    final Widget face = Padding(padding: const EdgeInsets.all(2), child: PackSvg(a.assets.svg(sprite)));
    final Widget ring = selected || (option != null && s.litTile == i)
        ? const IgnorePointer(
            child: SkyRing(key: Key('do-lit'), radius: TokenRadius.xl),
          )
        : const SizedBox();
    return AnimatedPositioned(
      key: Key('do-piece-$id'),
      duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 700),
      curve: Curves.easeInOut,
      left: at.left,
      top: at.top,
      width: at.width,
      height: at.height,
      child: Opacity(
        opacity: dimmed ? 0.35 : 1,
        child: Semantics(
          button: true,
          label: option?.label ?? a.options.first.label,
          child: Draggable<String>(
            data: isThing ? 'thing' : id,
            maxSimultaneousDrags: s.busy || s.done ? 0 : 1,
            feedback: SizedBox(width: start.width, height: start.height, child: face),
            childWhenDragging: Opacity(opacity: 0.3, child: face),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => s.select(id),
              child: Stack(fit: StackFit.expand, children: <Widget>[face, ring]),
            ),
          ),
        ),
      ),
    );
  }

  /// With a thing selected, a touch on the target takes it there.
  void _dropSelected() {
    final String? id = s.selectedId;
    if (id != null) s.drop(id);
  }

  /// "Done", for the embodied version: at the end corner of the stage.
  Widget _doneButton(BuildContext context) => Positioned(
    right: 12,
    bottom: 12,
    child: PebbleButton(
      key: const Key('do-done'),
      semanticLabel: He.listenDoneSemantics.text,
      size: 72,
      onPressed: s.finish,
      child: const Icon(Icons.check_rounded, size: 40, color: TokenColors.ink),
    ),
  );
}

/// What the command names, close up: the thing or the action, or the part of the picture cropped to a square that keeps the picture's
/// proportions and fills the card with the picture itself. A touch on it does nothing.
Widget closeUpCard(ListenDoActivity a, String correctId, double card) {
  final ChoiceOption right = a.options.firstWhere((ChoiceOption o) => o.id == correctId);
  final Widget content;
  if (right.sprite != null) {
    content = Padding(padding: const EdgeInsets.all(6), child: PackSvg(a.assets.svg(right.sprite!)));
  } else {
    // The crop is the square round the part (its longer side, at least a seventh of the picture), kept inside the picture.
    final Rect r = right.at!;
    final double side = math.min(1, math.max(math.max(r.width, r.height), 0.15));
    final double left = (r.center.dx - side / 2).clamp(0, 1 - side);
    final double top = (r.center.dy - side / 2).clamp(0, 1 - side);
    final double scale = (card - 8) / side;
    content = ClipRRect(
      borderRadius: BorderRadius.circular(TokenRadius.lg - 4),
      child: Stack(
        children: <Widget>[
          Positioned(
            left: -left * scale,
            top: -top * scale,
            width: scale,
            height: scale,
            child: PackSvg(a.assets.svg(a.picture)),
          ),
        ],
      ),
    );
  }
  return IgnorePointer(
    child: Container(
      key: const Key('do-closeup'),
      width: card,
      height: card,
      padding: const EdgeInsets.all(0),
      decoration: BoxDecoration(
        color: TokenColors.paper,
        borderRadius: BorderRadius.circular(TokenRadius.lg),
        border: Border.all(color: TokenColors.hintHalo, width: 4),
      ),
      child: content,
    ),
  );
}
