import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../child/activity_shell.dart';
import '../content/hint_ladder.dart';
import '../content/models.dart';
import '../design/components.dart';
import '../design/tokens.g.dart';
import '../strings/he.dart';
import 'choice_row.dart';
import 'choice_session.dart';
import 'hints/hint_pictures.dart' show SkyRing;
import 'lesson_controller.dart' show LessonController;
import 'template_session.dart';

/// The listen-and-do template (LS11, docs/languages/frame.md section 2.3): the command is heard and the child carries it out in a
/// scene, five ways. **hotspots**: touch one of the glowing parts of the picture (a body, a room); a part that is not an option does not
/// exist. **buttons**: touch one of the action pictures, and the friend on the stage does the one chosen. **drag**: one of the things
/// goes to the target (a plate, a box, the friend); **place**: the one thing goes to one of the places. A thing is dragged, or touched
/// and then the target touched (the tap path always works), and a wrong one goes back to where it was: nothing is red and nothing is
/// taken away. **embodied**: the child does it and touches "done": it is practice, never counted alone, and writes nothing.
///
/// The hints: level 1 lights the parts one after the other; level 2 shows what the command names in a close-up card beside the scene
/// (a new representation); level 3 shows it done: the right thing is carried to its place, and then only the right move is taken.
class ListenDoSession extends ChoiceSession {
  ListenDoSession(LessonController controller, ListenDoActivity activity, {super.stress})
    : doing = activity,
      super(controller, activity, activity);

  final ListenDoActivity doing;

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
    if (mode != 'buttons' || chosenId == null) return null;
    return options.firstWhere((ChoiceOption o) => o.id == chosenId).sprite;
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

  @override
  ActivitySpec layoutFor(ActivitySpec base) =>
      mode == 'buttons' ? super.layoutFor(base) : withTallStage(base);

  @override
  Widget buildStage(BuildContext context, Size size, ActivitySpec spec) =>
      ListenableBuilder(listenable: this, builder: (BuildContext c, Widget? _) => _DoStage(this, size));

  @override
  Widget? buildTiles(BuildContext context, ActivitySpec spec) =>
      mode == 'buttons' ? choiceTiles(context, spec, speakers: false) : null;
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
                  builder: (BuildContext context, BoxConstraints box) =>
                      Center(child: _scene(context, math.min(box.maxWidth, box.maxHeight))),
                ),
              ),
            ),
            if (a.embodied) _doneButton(context),
          ],
        ),
      ),
    );
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
          if (a.mode == 'hotspots')
            for (final (int i, ChoiceOption o) in a.options.indexed) _hotspot(px(o.at!), o, i),
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
          if (s.closeUp) _closeUpCard(side),
        ],
      ),
    );
  }

  /// A glowing part of the picture that a touch takes as the answer.
  Widget _hotspot(Rect r, ChoiceOption o, int i) => Positioned.fromRect(
    rect: r,
    child: Semantics(
      button: true,
      label: o.label,
      child: GestureDetector(
        key: Key('do-hot-${o.id}'),
        behavior: HitTestBehavior.opaque,
        onTap: () => s.choose(o.id),
        child: _ring(o, i),
      ),
    ),
  );

  /// The ring around an option's place: always faintly there (a glow), lit by a hint, coloured by the child's choice, and on the right
  /// one once the help is at its top.
  Widget _ring(ChoiceOption o, int i) {
    final bool chosen = s.chosenId == o.id;
    final bool shown = s.controller.answerShown && o.id == s.correctId;
    final bool dimmed = s.controller.answerShown && o.id != s.correctId;
    final bool lit = s.litTile == i || shown;
    final Color color = chosen
        ? (s.chosenState == AnswerState.correct
              ? TokenColors.correctGlow
              : s.chosenState == AnswerState.notYet
              ? TokenColors.notYetRing
              : TokenColors.hintHalo)
        : TokenColors.hintHalo;
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
                ? _ring(option, index)
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

  /// What the command names, close up, in a card at the end corner of the scene: the thing, the action, or the part of the picture.
  Widget _closeUpCard(double side) {
    final ListenDoActivity a = s.doing;
    final ChoiceOption right = a.options.firstWhere((ChoiceOption o) => o.id == s.correctId);
    final double card = math.min(side * 0.4, 130);
    Widget content;
    if (right.sprite != null) {
      content = Padding(padding: const EdgeInsets.all(6), child: PackSvg(a.assets.svg(right.sprite!)));
    } else {
      final Rect r = right.at!;
      final double scale = card / math.max(r.width, r.height);
      content = ClipRect(
        child: Stack(
          children: <Widget>[
            Positioned(
              left: -r.left * scale,
              top: -r.top * scale,
              width: scale,
              height: scale,
              child: PackSvg(a.assets.svg(a.picture)),
            ),
          ],
        ),
      );
    }
    return Positioned(
      top: 6,
      right: 6,
      child: Container(
        key: const Key('do-closeup'),
        width: card,
        height: card,
        decoration: BoxDecoration(
          color: TokenColors.paper,
          borderRadius: BorderRadius.circular(TokenRadius.lg),
          border: Border.all(color: TokenColors.hintHalo, width: 4),
        ),
        child: content,
      ),
    );
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
