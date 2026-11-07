import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../child/activity_shell.dart';
import '../content/hint_ladder.dart';
import '../content/models.dart';
import '../design/components.dart';
import '../design/layout.dart';
import '../design/tokens.g.dart';
import '../strings/he.dart';
import 'choice_row.dart' show withTallStage;
import 'choice_session.dart';
import 'lesson_controller.dart' show LessonController;
import 'template_session.dart';

/// The story template (LS08, docs/languages/frame.md section 2.3): a picture book of a few pages. A page's narration plays when it
/// comes up, a touch on a thing in the picture says its word, and the child turns the page with a big arrow; no page turns by itself
/// and no page text is shown (Band A has no reading). In `listen` mode the story is only heard: at its end the lesson takes the
/// warm line and goes on, and **nothing is written**. In `dialogic` mode the story stops after the page `pauseAfter`, asks its
/// question (2 or 3 picture or text choices, scored like any choice, with its hint ladder), says the recast (the item's
/// `feedback.correct`) and goes on to its last page.
///
/// The hints of the pause: level 1 plays the page that answers it again; level 2 lays the pages so far in a row and plays them one
/// after the other (the story as a sequence: a new representation); level 3 lights the right choice.
class StorySession extends ChoiceSession {
  StorySession(LessonController controller, StoryActivity activity, {super.stress})
    : story = activity,
      super(controller, activity, activity) {
    // The story is told in the page's own narration; the replay button plays the page again, and says no line of its own.
    controller.replayQuiet = true;
    later(Duration.zero, () => _narrate());
  }

  final StoryActivity story;

  /// The page on the stage (from 0).
  int page = 0;

  /// The question of a dialogic story is being asked: the choices are on the tiles.
  bool asking = false;

  /// The pages so far are laid out in a row (hint level 2); [litPage] is the one whose narration is playing.
  bool showRow = false;
  int? litPage;

  /// The thing in the picture that was just touched.
  int? litWord;

  /// The answer was taken: the story goes on to its last page.
  bool resumed = false;

  int get lastPage => story.pages.length - 1;
  StoryPage get current => story.pages[page];

  /// The page after which the dialogic story stops to ask.
  int get askAfter => story.pauseAfter ?? lastPage;

  /// The last page is on the stage and nothing more is to be told: the arrow becomes a tick.
  bool get atEnd => page == lastPage && !(story.dialogic && !asked);
  bool get asked => resumed || asking;

  void _narrate({bool replace = false}) {
    if (disposed) return;
    playClips?.call(current.clips, replace: replace);
  }

  /// The arrow: on to the next page, to the question of the pause, or the end.
  void turn() {
    if (asking || controller.solved && !resumed) return;
    if (story.dialogic && !resumed && page == askAfter) {
      _ask();
      return;
    }
    if (page < lastPage) {
      page++;
      litWord = null;
      notify();
      _narrate(replace: true);
      return;
    }
    _finish();
  }

  void _ask() {
    asking = true;
    controller.replayQuiet = false;
    controller.askAnswer(story.question!);
    notify();
  }

  void _finish() {
    if (story.dialogic) {
      // The recast was said when the answer was right; the story is over.
      controller.next();
    } else {
      controller.completePractice();
      later(TemplateSession.praisePause, controller.next);
    }
  }

  @override
  void onRight() {
    // The recast plays, and then the story goes on to its last page, which the child turns to.
    later(TemplateSession.praisePause, () {
      asking = false;
      resumed = true;
      showRow = false;
      controller.replayQuiet = true;
      if (page < lastPage) {
        page++;
        _narrate();
        notify();
      } else {
        _finish();
      }
    });
  }

  void touchWord(int i) {
    litWord = i;
    notify();
    playClips?.call(<String>[current.words[i].clip], replace: true);
    later(const Duration(milliseconds: 700), () {
      if (litWord == i) {
        litWord = null;
        notify();
      }
    });
  }

  // ---- hints ----

  @override
  void onReplay() {
    if (asking) {
      pulseTiles();
    } else {
      _narrate(replace: true);
    }
  }

  @override
  void onHint() {
    final HintPicture picture = hintPictureOf(activity);
    switch (picture) {
      case HintPicture.replayPart:
        // The page that answers the question is told again.
        playClips?.call(story.pages[askAfter].clips, replace: false);
        litPage = askAfter;
        notify();
        later(const Duration(milliseconds: 1500), () {
          litPage = null;
          notify();
        });
      case HintPicture.pagesInRow:
        _playRow();
      default:
        pulseTiles();
        endDemoIfShown();
    }
  }

  /// The pages so far in a row, each lit while it is told.
  Future<void> _playRow() async {
    showRow = true;
    notify();
    for (int i = 0; i <= askAfter; i++) {
      litPage = i;
      notify();
      await sayAndWait(story.pages[i].clips);
      if (disposed) return;
    }
    litPage = null;
    notify();
  }

  @override
  void onReset() {
    super.onReset();
    controller.replayQuiet = story.dialogic ? false : true;
    page = 0;
    asking = false;
    resumed = false;
    showRow = false;
    litPage = null;
    litWord = null;
  }

  // ---- layout ----

  /// While the story is told its picture has the whole board under the guide's bubble (the page is the thing to look at, and no
  /// tile is in the way); at the question the stage shrinks to its usual size to leave the room to the tiles.
  @override
  ActivitySpec layoutFor(ActivitySpec base) {
    return asking ? super.layoutFor(base) : withTallStage(base);
  }

  @override
  Widget buildStage(BuildContext context, Size size, ActivitySpec spec) =>
      ListenableBuilder(listenable: this, builder: (BuildContext c, Widget? _) => _StoryStage(this, size));

  @override
  Widget? buildTiles(BuildContext context, ActivitySpec spec) => asking ? choiceTiles(context, spec) : null;
}

class _StoryStage extends StatelessWidget {
  const _StoryStage(this.s, this.size);

  final StorySession s;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final StoryActivity a = s.story;
    final bool rtl = s.rowDirection == TextDirection.rtl;
    return Semantics(
      container: true,
      label: s.current.alt,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(TokenRadius.lg),
        child: Stack(
          key: const Key('story-stage'),
          children: <Widget>[
            if (a.background != null)
              Positioned.fill(child: PackSvg(a.assets.svg(a.background!), fit: BoxFit.cover)),
            if (s.showRow)
              Positioned.fill(child: _pagesRow(a))
            else
              Positioned.fill(
                child: _page(a, arrow: s.asking ? 0 : _arrowSide(context), rtl: rtl),
              ),
            if (!s.asking && !s.showRow) _arrow(context, rtl),
          ],
        ),
      ),
    );
  }

  /// The page: its picture, and the things in it that say their word when touched. With the arrow on the stage ([arrow] is its
  /// side), a page that would lie under it is made smaller and moved off it, above it or beside it, whichever keeps the page larger
  /// (QA-BA-9: the arrow is never drawn over the picture).
  Widget _page(StoryActivity a, {required double arrow, required bool rtl}) {
    final StoryPage p = s.current;
    return Padding(
      padding: const EdgeInsets.all(6),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints box) {
          // The page keeps its own proportions (a 16:9 picture is not made a square and then shrunk again); the touch boxes of its words
          // are shares of its width and height.
          final double aspect = svgAspect(a.assets.svg(p.picture));
          final ({Size size, Alignment align}) place = storyPagePlace(
            Size(box.maxWidth, box.maxHeight),
            aspect,
            arrow: arrow,
            rtl: rtl,
          );
          final double width = place.size.width;
          final double height = place.size.height;
          return Align(
            alignment: place.align,
            child: SizedBox(
              key: Key('story-page-${s.page}'),
              width: width,
              height: height,
              child: Stack(
                children: <Widget>[
                  Positioned.fill(child: PackSvg(a.assets.svg(p.picture))),
                  for (final (int i, ({Rect at, String clip}) w) in p.words.indexed)
                    Positioned(
                      left: w.at.left * width,
                      top: w.at.top * height,
                      width: w.at.width * width,
                      height: w.at.height * height,
                      child: GestureDetector(
                        key: Key('story-word-$i'),
                        behavior: HitTestBehavior.opaque,
                        onTap: () => s.touchWord(i),
                        child: s.litWord == i
                            ? DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(TokenRadius.lg),
                                  border: Border.all(color: TokenColors.hintHalo, width: 4),
                                ),
                              )
                            : null,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// The pages so far in a row, as small pictures in the story's direction; the one being told is ringed.
  Widget _pagesRow(StoryActivity a) {
    final List<StoryPage> shown = a.pages.sublist(0, s.askAfter + 1);
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Directionality(
        textDirection: s.rowDirection,
        child: Row(
          key: const Key('story-row'),
          children: <Widget>[
            for (final (int i, StoryPage p) in shown.indexed)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: TokenColors.paper,
                      borderRadius: BorderRadius.circular(TokenRadius.lg),
                      border: Border.all(
                        color: s.litPage == i ? TokenColors.hintHalo : TokenColors.hairline,
                        width: s.litPage == i ? 5 : 2,
                      ),
                    ),
                    child: Padding(padding: const EdgeInsets.all(4), child: PackSvg(a.assets.svg(p.picture))),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// The side of the arrow's button.
  double _arrowSide(BuildContext context) => math.max(72, AppLayout.of(context).touch.minControl);

  /// The arrow that turns the page, at the end corner of the stage in the story's direction; the last page has a tick.
  Widget _arrow(BuildContext context, bool rtl) {
    final bool end = s.atEnd;
    return Positioned(
      left: rtl ? storyArrowInset : null,
      right: rtl ? null : storyArrowInset,
      bottom: storyArrowInset,
      child: PebbleButton(
        key: const Key('story-turn'),
        semanticLabel: (end ? He.storyEndSemantics : He.storyNextSemantics).text,
        size: _arrowSide(context),
        onPressed: s.turn,
        // An arrow never mirrors with the screen: it points the way the story is read.
        child: Icon(
          end ? Icons.check_rounded : (rtl ? Icons.arrow_back_rounded : Icons.arrow_forward_rounded),
          size: 40,
          color: TokenColors.ink,
          textDirection: TextDirection.ltr,
        ),
      ),
    );
  }
}

/// How far the arrow stands from the stage's bottom and end edges.
const double storyArrowInset = 12;

/// Where a story page of [aspect] (width over height) stands in a [box] (the stage less its padding of 6): as large as the box allows,
/// centred; but when the arrow ([arrow] points square, at the bottom end corner, [rtl] says which) would lie over the centred page, the
/// page is fitted to the box less the arrow's band, under the top (the room above the arrow) or beside it at the start side, whichever
/// is larger. [arrow] 0 is a stage with no arrow.
({Size size, Alignment align}) storyPagePlace(
  Size box,
  double aspect, {
  required double arrow,
  required bool rtl,
}) {
  Size fit(double w, double h) {
    final double width = math.max(0, math.min(w, h * aspect));
    return Size(width, width / aspect);
  }

  final Size centred = fit(box.width, box.height);
  if (arrow <= 0) return (size: centred, align: Alignment.center);
  const double inset = storyArrowInset - 6;
  final Rect page = Rect.fromLTWH(
    (box.width - centred.width) / 2,
    (box.height - centred.height) / 2,
    centred.width,
    centred.height,
  );
  final Rect button = Rect.fromLTWH(
    rtl ? inset : box.width - inset - arrow,
    box.height - inset - arrow,
    arrow,
    arrow,
  );
  if (!page.overlaps(button.inflate(4))) return (size: centred, align: Alignment.center);
  final double band = arrow + inset + 6;
  final Size above = fit(box.width, box.height - band);
  final Size beside = fit(box.width - band, box.height);
  return above.width >= beside.width
      ? (size: above, align: Alignment.topCenter)
      : (size: beside, align: rtl ? Alignment.centerRight : Alignment.centerLeft);
}

/// The width over the height of a picture, from the `viewBox` of its SVG text; 1 when it has none.
double svgAspect(String svg) {
  final RegExpMatch? m = RegExp(r'viewBox\s*=\s*"\s*[-\d.]+[ ,]+[-\d.]+[ ,]+([\d.]+)[ ,]+([\d.]+)')
      .firstMatch(svg);
  final double w = m == null ? 0 : double.tryParse(m[1]!) ?? 0;
  final double h = m == null ? 0 : double.tryParse(m[2]!) ?? 0;
  return w > 0 && h > 0 ? w / h : 1;
}
