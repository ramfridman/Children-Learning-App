import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SliverLayoutDimensions;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/course_visit.dart';
import '../app/language_providers.dart';
import '../app/reward_providers.dart' show rewardsProvider;
import '../design/app_text.dart';
import '../design/board.dart';
import '../design/components.dart';
import '../design/layout.dart';
import '../design/tokens.g.dart';
import '../engine/course.dart';
import '../strings/he.dart';
import '../world/course_path.dart';
import '../world/todays_adventure.dart' show AdventureKind, TodaysAdventure;
import 'land_screen.dart' show IslandPainter;
import 'languages_doors.dart' show languageName, languagesColours;
import 'play_button.dart';

// The home of one language course (docs/milestones/L-course.md): the course's host, the path of its lessons in the course's reading
// direction, and one big pebble for what comes next. The first time, the host invites the child to a "visit" (the placement game);
// after it the path opens at the placed level. Nothing is locked, grey or counted, a stone is not a button (the pebble is the one way
// to start, as in a land), and nothing shows a result. The design-director's pass may move the numbers below (the host, the strip and
// the pebble); the layout is the door screen's (board coordinates, the island of the Languages colours).

/// What differs between the four boards of the course home. All in board points.
class _HomeSpec {
  const _HomeSpec({
    required this.host,
    required this.hostTop,
    required this.bubbleTop,
    required this.bubbleFont,
    required this.bubbleWidth,
    required this.stripY,
    required this.stone,
    required this.next,
    required this.labelTop,
    required this.labelFont,
  });

  /// The host's picture is a square of this size, centred.
  final double host;
  final double hostTop;

  /// The invitation's bubble (placement due): its top, its text size and the widest it grows. Its tail points down at the host's head.
  final double bubbleTop;
  final double bubbleFont;
  final double bubbleWidth;

  /// The middle of the strip of stones, the size of an ordinary stone and of the one the pebble stands on.
  final double stripY;
  final double stone;
  final double next;

  /// The name of the next lesson, under the pebble.
  final double labelTop;
  final double labelFont;

  /// The room one ordinary stone takes along the path, and the room the next one takes (its pebble has a tap margin of 12 all round).
  double get slot => stone + 36;
  double get nextSlot => next + 48;

  static const _HomeSpec phone = _HomeSpec(
    host: 176,
    hostTop: 78,
    bubbleTop: 14,
    bubbleFont: 22,
    bubbleWidth: 400,
    stripY: 304,
    stone: 52,
    next: 72,
    labelTop: 346,
    labelFont: 20,
  );
  static const _HomeSpec phoneSE = _HomeSpec(
    host: 148,
    hostTop: 74,
    bubbleTop: 12,
    bubbleFont: 20,
    bubbleWidth: 340,
    stripY: 290,
    stone: 46,
    next: 64,
    labelTop: 328,
    labelFont: 18,
  );
  static const _HomeSpec tabletLandscape = _HomeSpec(
    host: 340,
    hostTop: 150,
    bubbleTop: 50,
    bubbleFont: 30,
    bubbleWidth: 560,
    stripY: 660,
    stone: 76,
    next: 112,
    labelTop: 730,
    labelFont: 28,
  );
  static const _HomeSpec tabletPortrait = _HomeSpec(
    host: 440,
    hostTop: 340,
    bubbleTop: 250,
    bubbleFont: 30,
    bubbleWidth: 520,
    stripY: 960,
    stone: 76,
    next: 112,
    labelTop: 1030,
    labelFont: 28,
  );

  static _HomeSpec of(BoardClass b) => switch (b) {
    BoardClass.phone => phone,
    BoardClass.phoneSE => phoneSE,
    BoardClass.tabletLandscape => tabletLandscape,
    BoardClass.tabletPortrait => tabletPortrait,
  };
}

/// The course home of one child. It reads the course from the installed pack and the child's answers ([courseHomeProvider]); a
/// language that is not installed shows the host alone. The pebble starts what is next: the placement visit while the host is inviting,
/// otherwise the stop of the rule (a revisit, the next lesson, a lesson again). A visit ends on its own celebration and the child is back
/// here, with the path moved on.
class CourseHomeScreen extends ConsumerStatefulWidget {
  const CourseHomeScreen({super.key, required this.childId, required this.course, this.onBack, this.start});

  final String childId;
  final String course;
  final VoidCallback? onBack;

  /// A stop of Today's Adventure in this course: the home opens and plays it at once, so the bottle's stop starts the course's next visit
  /// (the placement first when it is due). Null when the child came through a door or the island.
  final TodaysAdventure? start;

  @override
  ConsumerState<CourseHomeScreen> createState() => _CourseHomeScreenState();
}

class _CourseHomeScreenState extends ConsumerState<CourseHomeScreen> {
  /// A visit is on screen (or being set up): a second touch of the pebble starts nothing.
  bool _busy = false;

  ({String childId, String course}) get _key => (childId: widget.childId, course: widget.course);

  @override
  void initState() {
    super.initState();
    if (widget.start != null) WidgetsBinding.instance.addPostFrameCallback((_) => _playStart());
  }

  /// The stop the bottle chose, played once when the home has read the course.
  Future<void> _playStart() async {
    final CourseHomeModel? model = await ref.read(courseHomeProvider(_key).future);
    if (_busy || !mounted || model == null) return;
    _busy = true;
    try {
      await _start(model, widget.start);
    } finally {
      _busy = false;
    }
  }

  Future<void> _play() async {
    final CourseHomeModel? model = ref.read(courseHomeProvider(_key)).value;
    if (_busy || model == null || !model.canPlay) return;
    _busy = true;
    try {
      await _start(model);
    } finally {
      _busy = false;
    }
  }

  /// Starts what the pebble stands for, and when the visit is over reads the child's history again.
  Future<void> _start(CourseHomeModel model, [TodaysAdventure? stop]) async {
    await startCourseVisit(
      context,
      ref,
      childId: widget.childId,
      course: widget.course,
      model: model,
      stop: stop,
    );
    if (mounted) _refresh();
  }

  /// A visit has ended (finished or left): the path, the engine and the awards are read again.
  void _refresh() {
    ref.invalidate(rewardsProvider(widget.childId));
    ref.invalidate(languageCoursesProvider(widget.childId));
    ref.invalidate(courseHomeProvider(_key));
  }

  @override
  Widget build(BuildContext context) {
    final CourseHomeModel? model = ref.watch(courseHomeProvider(_key)).value;
    return CourseHomeView(
      course: widget.course,
      model: model,
      onPlay: model == null ? null : _play,
      onBack: widget.onBack,
    );
  }
}

/// The picture of the course home from a model; nothing here reads a provider, so a golden can draw it from fixed values. [onPlay] is
/// what the pebble does: null (no way to start yet) draws the next stone as a stone.
class CourseHomeView extends StatelessWidget {
  const CourseHomeView({super.key, required this.course, required this.model, this.onPlay, this.onBack});

  final String course;
  final CourseHomeModel? model;
  final VoidCallback? onPlay;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final BoardClass board = AppLayout.of(context).board;
    final _HomeSpec s = _HomeSpec.of(board);
    final CourseHomeModel? m = model;
    final double width = board.size.width;
    final bool invite = m != null && m.placementDue;
    return Scaffold(
      body: Semantics(
        label: '${He.courseHomeSemantics.text}: ${languageName(course).text}',
        child: BoardCanvas(
          background: languagesColours.sea,
          board: board,
          children: <Widget>[
            Positioned.fill(child: CustomPaint(painter: IslandPainter(languagesColours))),
            Positioned(
              left: (width - s.host) / 2,
              top: s.hostTop,
              width: s.host,
              height: s.host,
              child: ExcludeSemantics(
                child: BoardSvg(
                  'assets/art/languages/host_$course.svg',
                  key: const Key('course-host'),
                  width: s.host,
                  height: s.host,
                ),
              ),
            ),
            if (invite)
              Positioned(
                left: width / 2 - 38,
                top: s.bubbleTop,
                child: ExcludeSemantics(
                  child: BoardBubble(
                    key: const Key('course-invite'),
                    text: He.courseInvite.text,
                    fontSize: s.bubbleFont,
                    maxWidth: s.bubbleWidth,
                    // The wedge's base is 24 to 52 from the bubble's start, so its tip falls on the middle of the host's head.
                    tailTip: Offset(38, s.hostTop - s.bubbleTop + s.host * 0.1),
                  ),
                ),
              ),
            if (m != null && m.stones.isNotEmpty)
              Positioned(
                left: 0,
                top: s.stripY - s.nextSlot / 2,
                width: width,
                height: s.nextSlot,
                child: Semantics(
                  label: He.coursePathSemantics.text,
                  child: _Path(
                    key: const Key('course-path'),
                    course: course,
                    model: m,
                    spec: s,
                    width: width,
                    onPlay: onPlay,
                  ),
                ),
              ),
            if (m != null && m.pebbleLesson != null)
              Positioned(
                left: 0,
                right: 0,
                top: s.labelTop,
                child: Center(
                  child: Container(
                    key: const Key('course-next-title'),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
                    decoration: BoxDecoration(
                      color: TokenColors.paper,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: softShadow,
                    ),
                    child: ExcludeSemantics(
                      child: Text(
                        m.pebbleLesson!.title,
                        textDirection: TextDirection.rtl,
                        style: AppText.fixed(size: s.labelFont, weight: 600),
                      ),
                    ),
                  ),
                ),
              ),
            PositionedDirectional(
              start: 16,
              top: 8,
              child: PebbleButton(
                key: const Key('course-back'),
                semanticLabel: He.landBackSemantics.text,
                size: 48,
                fill: TokenColors.spark,
                lip: TokenColors.sparkDeep,
                onPressed: onBack ?? () => Navigator.of(context).pop(),
                child: const BoardSvg('assets/art/ui/home_palm.svg', width: 24, height: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The strip of stones, in the course's reading direction: Hebrew starts at the right, English and Russian at the left. It is a
/// horizontal list under a `Directionality` of the course, so its start edge is the course's. Every stone but the next is an ordinary
/// stone; the next is the pebble. The list opens with the next stone in the middle, and is padded so that even the first and the last
/// can stand there.
class _Path extends StatefulWidget {
  const _Path({
    super.key,
    required this.course,
    required this.model,
    required this.spec,
    required this.width,
    required this.onPlay,
  });

  final String course;
  final CourseHomeModel model;
  final _HomeSpec spec;
  final double width;
  final VoidCallback? onPlay;

  @override
  State<_Path> createState() => _PathState();
}

class _PathState extends State<_Path> {
  late final ScrollController _scroll = ScrollController(
    initialScrollOffset: _offsetOf(widget.model.nextIndex),
  );

  /// Where the list is scrolled to have stone [index] in the middle: the stones before it each take a slot, and the next one (wider)
  /// is centred on its own extra room.
  double _offsetOf(int index) {
    final _HomeSpec s = widget.spec;
    final double extra = index == widget.model.nextIndex ? (s.nextSlot - s.slot) / 2 : 0;
    return (index < 0 ? 0 : index) * s.slot + extra;
  }

  @override
  void didUpdateWidget(_Path old) {
    super.didUpdateWidget(old);
    if (old.model.nextIndex == widget.model.nextIndex || !_scroll.hasClients) return;
    final double to = _offsetOf(widget.model.nextIndex);
    if (MediaQuery.disableAnimationsOf(context)) {
      _scroll.jumpTo(to);
    } else {
      _scroll.animateTo(to, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final _HomeSpec s = widget.spec;
    final List<PathStone> stones = widget.model.stones;
    final bool revisit = !widget.model.placementDue && widget.model.stop.kind == AdventureKind.revisit;
    return Directionality(
      textDirection: Course.readsRightToLeft(widget.course) ? TextDirection.rtl : TextDirection.ltr,
      child: ListView.builder(
        controller: _scroll,
        scrollDirection: Axis.horizontal,
        padding: EdgeInsetsDirectional.symmetric(horizontal: (widget.width - s.slot) / 2),
        itemCount: stones.length,
        itemExtentBuilder: (int i, SliverLayoutDimensions d) =>
            i == widget.model.nextIndex ? s.nextSlot : s.slot,
        itemBuilder: (BuildContext context, int i) {
          final PathStone stone = stones[i];
          final bool isNext = i == widget.model.nextIndex;
          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: <Widget>[
              if (i > 0) const _Trail(),
              if (isNext)
                _NextStone(
                  key: const Key('course-next'),
                  spec: s,
                  number: stone.number,
                  revisit: revisit,
                  label: widget.model.placementDue
                      ? He.courseVisitSemantics.text
                      : widget.model.canPlay
                      ? He.courseNextSemantics.text
                      : '${stone.number}. ${He.courseStoneNextSemantics.text}',
                  onPlay: widget.model.canPlay ? widget.onPlay : null,
                )
              else
                Semantics(
                  label:
                      '${stone.number}. ${stone.state == StoneState.later ? He.courseStoneLaterSemantics.text : He.courseStoneDoneSemantics.text}',
                  child: ExcludeSemantics(
                    child: _Stone(key: Key('stone-${stone.number}'), size: s.stone, stone: stone),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Three small dots on the start side of a stone: the trail from the stone before it (as on a land's island).
class _Trail extends StatelessWidget {
  const _Trail();

  @override
  Widget build(BuildContext context) => PositionedDirectional(
    start: 0,
    top: 0,
    bottom: 0,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int i = 0; i < 3; i++)
          Container(
            width: 4,
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 1),
            decoration: const BoxDecoration(color: TokenColors.worldWoodLight, shape: BoxShape.circle),
          ),
      ],
    ),
  );
}

/// An ordinary stone: a lesson finished (a star), a lesson the placement showed was known (a hollow star), or a lesson further on (its
/// number, a digit, so it never mirrors). Nothing says what the child did well or badly.
class _Stone extends StatelessWidget {
  const _Stone({super.key, required this.size, required this.stone});

  final double size;
  final PathStone stone;

  @override
  Widget build(BuildContext context) {
    final (Color fill, Color rim) = switch (stone.state) {
      StoneState.done => (TokenColors.sparkTint, TokenColors.spark),
      StoneState.placed => (TokenColors.skyTint, TokenColors.sky),
      StoneState.later => (TokenColors.paper, TokenColors.cardLip),
    };
    return SizedBox(
      width: size,
      height: size * 1.1,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Positioned(
            bottom: 0,
            child: Container(
              width: size * 1.06,
              height: size * 0.2,
              decoration: BoxDecoration(
                color: TokenColors.worldWoodLight,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          Positioned(
            top: 0,
            child: Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: fill,
                shape: BoxShape.circle,
                border: Border.all(color: rim, width: 4),
                boxShadow: softShadow,
              ),
              child: switch (stone.state) {
                StoneState.done => Icon(Icons.star_rounded, color: TokenColors.sparkDeep, size: size * 0.6),
                StoneState.placed => Icon(
                  Icons.star_outline_rounded,
                  color: TokenColors.skyDeep,
                  size: size * 0.6,
                ),
                StoneState.later => Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    '${stone.number}',
                    style: AppText.fixed(
                      size: size * 0.42,
                      weight: 700,
                      lineHeight: 1.2,
                      color: TokenColors.inkSoft,
                    ),
                  ),
                ),
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// The stone the child goes to next. With a way to start it is the big play pebble (a small bell on it when the next thing is a check
/// that fell due); without one it is a big stone with its number.
class _NextStone extends StatelessWidget {
  const _NextStone({
    super.key,
    required this.spec,
    required this.number,
    required this.revisit,
    required this.label,
    required this.onPlay,
  });

  final _HomeSpec spec;
  final int number;
  final bool revisit;
  final String label;
  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context) {
    if (onPlay == null) {
      return Semantics(
        label: label,
        child: ExcludeSemantics(
          child: Container(
            width: spec.next,
            height: spec.next,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: TokenColors.sparkTint,
              shape: BoxShape.circle,
              border: Border.all(color: TokenColors.spark, width: 6),
              boxShadow: softShadow,
            ),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                '$number',
                style: AppText.fixed(size: spec.next * 0.42, weight: 700, lineHeight: 1.2),
              ),
            ),
          ),
        ),
      );
    }
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: <Widget>[
        PlayPebble(key: const Key('course-play'), semanticLabel: label, size: spec.next, onPressed: onPlay),
        if (revisit)
          PositionedDirectional(
            end: 6,
            top: 4,
            child: IgnorePointer(
              child: Container(
                key: const Key('course-bell'),
                width: spec.next * 0.4,
                height: spec.next * 0.4,
                decoration: const BoxDecoration(color: TokenColors.spark, shape: BoxShape.circle),
                child: Icon(Icons.notifications_rounded, color: TokenColors.ink, size: spec.next * 0.26),
              ),
            ),
          ),
      ],
    );
  }
}
