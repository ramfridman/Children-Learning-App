import 'package:flutter/material.dart';

import '../child/activity_shell.dart';
import '../content/hint_ladder.dart';
import '../content/models.dart';
import '../design/components.dart';
import '../design/layout.dart';
import '../design/tokens.g.dart';
import '../strings/he.dart';
import 'choice_row.dart';
import 'choice_session.dart';
import 'lesson_controller.dart' show LessonController;
import 'template_session.dart';

/// The puppet-talk template (LS10, docs/languages/frame.md section 2.3 and 5.2): a puppet speaks one turn (the prompt, two clips) and the
/// child answers.
///
/// **bubble**: one of 2 or 3 answer bubbles that fit the scene, each with a speaker that plays it without answering; scored, with the
/// ladder (level 1 the puppet's line again and then each bubble slowly, level 2 the key picture of the scene glows, level 3 the right
/// bubble is shown). The puppet answers with the item's right line.
///
/// **personal** (one of the four things of section 5.2: the name, the age, the likes, the family): the puppet goes first with its own
/// answer (it is in the prompt); the child touches a card, or the pass (always there), or, for the name, "I said it". The reply is
/// generic and warm; the card's own clip is played as the word itself ("Five!"). **Nothing is written, logged, synced or kept**: the
/// session holds no answer, only the reply it plays; the answer is never checked, never scored, never used to choose a lesson. With the
/// parent's switch off ([personalAllowed] false) the puppet has already answered its own question, and the lesson goes on.
class PuppetTalkSession extends ChoiceSession {
  PuppetTalkSession(
    LessonController controller,
    PuppetTalkActivity activity, {
    this.personalAllowed = true,
    super.stress,
  }) : talk = activity,
       super(controller, activity, activity) {
    if (activity.personal && !personalAllowed) {
      // The puppet's own turn is its prompt; the child is asked nothing, and the lesson goes on.
      later(const Duration(milliseconds: 1500), controller.next);
    }
  }

  final PuppetTalkActivity talk;

  /// The parent's switch for scripted personal questions (frame section 1.4).
  final bool personalAllowed;

  /// The key picture of the scene glows (hint level 2).
  bool keyGlow = false;

  /// The turn has been answered, or passed: the child's touch is over. It says nothing about what was touched.
  bool replied = false;

  bool get personal => talk.personal;

  /// A card of the personal turn is touched: its word is said as the word itself, then the puppet's generic reply.
  void touchCard(ChoiceOption card) {
    if (replied) return;
    replied = true;
    final String? clip = card.clip;
    if (clip != null) playClips?.call(<String>[clip], replace: true);
    _reply(null);
  }

  /// "I said it" of a name turn: the child said the name aloud, or did not: nothing is heard, checked or kept.
  void saidIt() {
    if (replied) return;
    replied = true;
    _reply(null);
  }

  /// The pass: the puppet says "That's OK!" and the lesson goes on.
  void pass() {
    if (replied) return;
    replied = true;
    _reply(talk.pass);
  }

  void _reply(Spoken? line) {
    notify();
    controller.completePractice(line: line);
    later(praise, controller.next);
  }

  // ---- hints (bubble) ----

  @override
  void onHint() {
    switch (hintPictureOf(activity)) {
      case HintPicture.replayPart:
        _lineAndBubbles();
      case HintPicture.keyPicture:
        keyGlow = true;
        notify();
      default:
        pulseTiles();
        endDemoIfShown();
    }
  }

  /// The puppet's line again, and then each bubble slowly, the bubble lit while it is said.
  Future<void> _lineAndBubbles() async {
    final Spoken line = activity.promptLine;
    await sayAndWait(<String>[line.vo, ?line.target, ?line.target2]);
    for (final (int i, ChoiceOption o) in options.indexed) {
      if (disposed) return;
      litTile = i;
      notify();
      await sayAndWait(<String>[?o.clip]);
    }
    if (disposed) return;
    litTile = null;
    notify();
  }

  @override
  void onReset() {
    super.onReset();
    keyGlow = false;
  }

  // ---- layout ----

  @override
  ActivitySpec layoutFor(ActivitySpec base) => personal ? withTallStage(base) : super.layoutFor(base);

  @override
  Widget buildStage(BuildContext context, Size size, ActivitySpec spec) =>
      ListenableBuilder(listenable: this, builder: (BuildContext c, Widget? _) => _PuppetStage(this, size));

  @override
  Widget? buildTiles(BuildContext context, ActivitySpec spec) => personal ? null : choiceTiles(context, spec);
}

class _PuppetStage extends StatelessWidget {
  const _PuppetStage(this.s, this.size);

  final PuppetTalkSession s;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final PuppetTalkActivity a = s.talk;
    final bool cards = a.personal && s.personalAllowed;
    final double picture = cards ? (size.height * 0.3).clamp(56, 100) : size.height;
    return Semantics(
      container: true,
      label: a.altText,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(TokenRadius.lg),
        child: Stack(
          key: const Key('puppet-stage'),
          children: <Widget>[
            if (a.background != null)
              Positioned.fill(child: PackSvg(a.assets.svg(a.background!), fit: BoxFit.cover)),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: picture,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Center(child: _scene(picture - 12)),
              ),
            ),
            // The pass is always in reach: it stands at the end corner of the stage, outside the cards that may scroll.
            if (cards)
              Positioned(left: 0, right: 0, top: picture, bottom: _footer(context), child: _cards(context)),
            if (cards) _footerButtons(context),
          ],
        ),
      ),
    );
  }

  /// The scene's picture, square, with the key place ringed when the hint asks.
  Widget _scene(double side) {
    final PuppetTalkActivity a = s.talk;
    final Rect? key = a.keyAt;
    return SizedBox(
      key: const Key('puppet-scene'),
      width: side,
      height: side,
      child: Stack(
        children: <Widget>[
          Positioned.fill(child: PackSvg(a.assets.svg(a.picture))),
          if (s.keyGlow && key != null)
            Positioned(
              left: key.left * side,
              top: key.top * side,
              width: key.width * side,
              height: key.height * side,
              child: const IgnorePointer(
                child: DecoratedBox(
                  key: Key('puppet-key'),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(TokenRadius.lg)),
                    border: Border.fromBorderSide(BorderSide(color: TokenColors.hintHalo, width: 5)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// The room under the cards for the pass (and "I said it"): one touch high and its margin.
  double _footer(BuildContext context) => AppLayout.of(context).touch.minControl + 12 + 6;

  /// The cards of a personal turn, in a grid that keeps every touch at the band's floor: it scrolls rather than shrink a card below it.
  Widget _cards(BuildContext context) {
    final PuppetTalkActivity a = s.talk;
    // The band's floor of a touch (64 in Band A): a card is never smaller, and its tap margin is the rest of the footprint.
    final double card = AppLayout.of(context).touch.minControl;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Directionality(
          textDirection: s.rowDirection,
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 4,
            runSpacing: 4,
            children: <Widget>[
              for (final ChoiceOption o in a.options)
                PebbleButton(
                  key: Key('card-${o.id}'),
                  semanticLabel: o.label ?? '',
                  size: card,
                  slop: 6,
                  onPressed: () => s.touchCard(o),
                  child: OptionFace(
                    option: o,
                    assets: a.assets,
                    course: a.course,
                    tileFont: card * 0.7,
                    stress: s.stress,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// "I said it" (a name turn) and the pass, at the end corner of the stage in the course's direction.
  Widget _footerButtons(BuildContext context) {
    final PuppetTalkActivity a = s.talk;
    final double touch = AppLayout.of(context).touch.minControl;
    final bool rtl = s.rowDirection == TextDirection.rtl;
    return Positioned(
      left: rtl ? 6 : null,
      right: rtl ? null : 6,
      bottom: 6,
      child: Directionality(
        textDirection: s.rowDirection,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (a.topic == 'name' && a.options.isEmpty)
              PebbleButton(
                key: const Key('personal-said'),
                semanticLabel: He.personalSaidSemantics.text,
                size: touch,
                slop: 6,
                onPressed: s.saidIt,
                child: const Icon(
                  Icons.check_rounded,
                  size: 32,
                  color: TokenColors.ink,
                  textDirection: TextDirection.ltr,
                ),
              ),
            PebbleButton(
              key: const Key('personal-pass'),
              semanticLabel: He.personalPassSemantics.text,
              size: touch,
              slop: 6,
              onPressed: s.pass,
              child: const Icon(
                Icons.skip_next_rounded,
                size: 32,
                color: TokenColors.ink,
                textDirection: TextDirection.ltr,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
