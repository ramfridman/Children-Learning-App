import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../child/activity_shell.dart';
import '../content/hint_ladder.dart';
import '../content/models.dart';
import '../design/components.dart';
import '../design/layout.dart';
import '../design/tokens.g.dart';
import '../strings/he.dart';
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
    if (asking) return super.layoutFor(base);
    final double bottom = base.boardHeight - TokenTouch.bottomNoHotspot - 20;
    return base.withStageAndTiles(
      stage: Rect.fromLTWH(base.stage.left, base.stage.top, base.stage.width, bottom - base.stage.top),
      tilesLeft: base.tilesLeft,
      tilesTop: base.tilesTop,
      tilesWidth: base.tilesWidth,
    );
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
            if (s.showRow) Positioned.fill(child: _pagesRow(a)) else Positioned.fill(child: _page(a)),
            if (!s.asking && !s.showRow) _arrow(context, rtl),
          ],
        ),
      ),
    );
  }

  /// The page: its picture, and the things in it that say their word when touched.
  Widget _page(StoryActivity a) {
    final StoryPage p = s.current;
    return Padding(
      padding: const EdgeInsets.all(6),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints box) {
          final double side = math.min(box.maxWidth, box.maxHeight);
          return Center(
            child: SizedBox(
              key: Key('story-page-${s.page}'),
              width: side,
              height: side,
              child: Stack(
                children: <Widget>[
                  Positioned.fill(child: PackSvg(a.assets.svg(p.picture))),
                  for (final (int i, ({Rect at, String clip}) w) in p.words.indexed)
                    Positioned(
                      left: w.at.left * side,
                      top: w.at.top * side,
                      width: w.at.width * side,
                      height: w.at.height * side,
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

  /// The arrow that turns the page, at the end corner of the stage in the story's direction; the last page has a tick.
  Widget _arrow(BuildContext context, bool rtl) {
    final bool end = s.atEnd;
    final double touch = AppLayout.of(context).touch.minControl;
    return Positioned(
      left: rtl ? 12 : null,
      right: rtl ? null : 12,
      bottom: 12,
      child: PebbleButton(
        key: const Key('story-turn'),
        semanticLabel: (end ? He.storyEndSemantics : He.storyNextSemantics).text,
        size: math.max(72, touch),
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
