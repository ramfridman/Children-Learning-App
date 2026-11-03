import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../design/app_text.dart';
import '../design/board.dart';
import '../design/components.dart';
import '../design/layout.dart';
import '../design/target_text.dart';
import '../design/tokens.g.dart';
import '../engine/course.dart';
import '../strings/he.dart';
import 'land_screen.dart' show IslandPainter;

// The door screen of the Languages island (docs/design/languages-island.md section 4); a door opens the course home (`course_home.dart`).
// One door for each language the parent turned on, in the fixed order of the doors, from the start (the right): English,
// Hebrew, Russian. Never sorted by use, never locked, grey or "coming soon". The child picks a door without reading: each is a
// host, a coloured door with a window shape of its own, and "hello" in the language's own script.

/// The colours of the Languages island's sea, sand and grass.
const ({Color sea, Color grass, Color sand}) languagesColours = (
  sea: TokenColors.worldSea1,
  grass: Color(0xFFA8DB8F),
  sand: Color(0xFFF6DDB0),
);

/// The words of a door's hello bubble. English and Russian are the teachers' words, drafts until they approve them (Russian
/// without a stress mark: a greeting, not a reading item).
const String helloEnglish = 'Hello';
const String helloRussian = 'Привет';

/// What differs between the four boards of the door screen: the sizes of docs/design/languages-island.md section 4.2.
class _DoorsSpec {
  const _DoorsSpec({
    required this.door,
    required this.gap3,
    required this.gap2,
    required this.bubbleTop,
    required this.bubbleHeight,
    required this.doorTop,
    required this.companion,
    required this.regionLeft,
    required this.regionRight,
    required this.helloSize,
  });

  /// The door's width; its height is 1.25 times that.
  final double door;
  final double gap3;
  final double gap2;
  final double bubbleTop;
  final double bubbleHeight;
  final double doorTop;
  final double companion;

  /// The row of doors is centred between these two board x (left of the companion's corner on the phones).
  final double regionLeft;
  final double regionRight;

  /// The size of the Hebrew hello; English and Russian are 1.1 times it.
  final double helloSize;

  static const _DoorsSpec phone = _DoorsSpec(
    door: 184,
    gap3: 32,
    gap2: 64,
    bubbleTop: 84,
    bubbleHeight: 52,
    doorTop: 146,
    companion: 104,
    regionLeft: 128,
    regionRight: 836,
    helloSize: 24,
  );
  static const _DoorsSpec phoneSE = _DoorsSpec(
    door: 160,
    gap3: 24,
    gap2: 48,
    bubbleTop: 80,
    bubbleHeight: 48,
    doorTop: 138,
    companion: 88,
    regionLeft: 112,
    regionRight: 651,
    helloSize: 22,
  );
  static const _DoorsSpec tabletLandscape = _DoorsSpec(
    door: 264,
    gap3: 56,
    gap2: 112,
    bubbleTop: 200,
    bubbleHeight: 68,
    doorTop: 278,
    companion: 160,
    regionLeft: 0,
    regionRight: 1180,
    helloSize: 32,
  );
  static const _DoorsSpec tabletPortrait = _DoorsSpec(
    door: 240,
    gap3: 24,
    gap2: 48,
    bubbleTop: 380,
    bubbleHeight: 72,
    doorTop: 462,
    companion: 160,
    regionLeft: 0,
    regionRight: 820,
    helloSize: 34,
  );

  /// How far the tap rectangle is inside the door box on each side: the stone frame starts door / 12 inside the box, and band A
  /// allows a slop of 12 (docs/design/languages-island.md section 4.2.1): 3, 1, 10 and 8 on the four boards.
  int get inset => (door / 12).round() - 12;

  /// The width of a door's tap rectangle, which is also the widest its bubble can be: 178, 158, 244 and 224. Two rectangles are
  /// the gap between two doors and twice [inset] apart: 38, 26, 76 and 40 with three doors.
  double get unitWidth => door - 2 * inset;

  /// The bottom of a door's tap rectangle: the bottom of its door box, but never in the bottom 24 of the screen (the edge rule),
  /// so on the phone it is 369.
  double unitBottom(double boardHeight) => math.min(doorTop + door * 1.25, boardHeight - 24);

  /// The height of a door's tap rectangle: from the top of its bubble (no slop upward, so the back pebble and the title stay
  /// clear) to [unitBottom]. The grass, the sea and the friend round it are not part of any door.
  double unitHeight(double boardHeight) => unitBottom(boardHeight) - bubbleTop;

  static _DoorsSpec of(BoardClass b) => switch (b) {
    BoardClass.phone => phone,
    BoardClass.phoneSE => phoneSE,
    BoardClass.tabletLandscape => tabletLandscape,
    BoardClass.tabletPortrait => tabletPortrait,
  };
}

/// The name of a language for a screen reader and for the parent's rows.
Str languageName(String course) => switch (course) {
  Course.eng => He.langEnglish,
  Course.heb => He.langHebrew,
  _ => He.langRussian,
};

/// The door screen. [courses] are the languages that are on, in any order: they are shown in the fixed order of the doors.
/// A tap on a door opens it ([openDoor] plays the hello clip and returns when it has ended, or false if there is none), then
/// the course opens ([onOpenCourse], which returns when the child comes back, and the door screen is as it was).
class LanguagesDoorsScreen extends StatefulWidget {
  const LanguagesDoorsScreen({
    super.key,
    required this.courses,
    required this.onOpenCourse,
    this.playHello,
    this.companion,
    this.onBack,
  });

  final List<String> courses;
  final Future<void> Function(String course) onOpenCourse;

  /// Plays the course's hello clip; true when it played to its end, false when there is no clip (the course then opens 600
  /// milliseconds after the tap).
  final Future<bool> Function(String course)? playHello;

  /// The land's host: the child's companion, in the end corner. It speaks only the idle line.
  final Widget? companion;
  final VoidCallback? onBack;

  @override
  State<LanguagesDoorsScreen> createState() => _LanguagesDoorsScreenState();
}

class _LanguagesDoorsScreenState extends State<LanguagesDoorsScreen> with TickerProviderStateMixin {
  /// The door that is opening: taps on the others are ignored meanwhile.
  String? _opening;

  /// 240 ms: the opening door's bubble pulses.
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
  );

  /// After 10 seconds with no tap the bubbles pulse once, one after another from the start, with no sound; then nothing more.
  /// It is an animation, not a clock: nothing counts down and nothing hurries.
  late final AnimationController _idle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: _idleWait + 3 * _idleStep + _idlePulse),
  );
  static const int _idleWait = 10000;
  static const int _idleStep = 120;
  static const int _idlePulse = 240;

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (!MediaQuery.disableAnimationsOf(context)) _idle.forward();
  }

  @override
  void dispose() {
    _pulse.dispose();
    _idle.dispose();
    super.dispose();
  }

  /// The doors in their fixed order, only those that are on.
  List<String> get _doors => <String>[
    for (final String c in Course.languages)
      if (widget.courses.contains(c)) c,
  ];

  Future<void> _open(String course) async {
    if (_opening != null) return;
    setState(() => _opening = course);
    _idle.stop();
    if (!MediaQuery.disableAnimationsOf(context)) _pulse.forward(from: 0);
    final bool played = widget.playHello == null ? false : await widget.playHello!(course);
    await Future<void>.delayed(Duration(milliseconds: played ? 250 : 600));
    // The back pebble always works: a door the child has already left (its route is popping, or gone) does not open its course.
    if (!mounted || ModalRoute.of(context)?.isCurrent == false) return;
    await widget.onOpenCourse(course);
    if (mounted) setState(() => _opening = null);
  }

  /// 0 to 1 to 0 while a bubble's idle pulse runs; the bubbles take their turn from the start.
  double _idleScale(int index) {
    final double ms = _idle.value * _idle.duration!.inMilliseconds - _idleWait - index * _idleStep;
    if (ms <= 0 || ms >= _idlePulse) return 1;
    final double t = ms / _idlePulse;
    return 1 + 0.06 * (t < 0.5 ? t * 2 : (1 - t) * 2);
  }

  @override
  Widget build(BuildContext context) {
    final BoardClass board = AppLayout.of(context).board;
    final _DoorsSpec s = _DoorsSpec.of(board);
    final List<String> doors = _doors;
    final double gap = doors.length >= 3 ? s.gap3 : s.gap2;
    final double rowWidth = doors.length * s.door + (doors.length - 1) * gap;
    final double centre = (s.regionLeft + s.regionRight) / 2;
    final double rowLeft = centre - rowWidth / 2;
    final bool still = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      body: BoardCanvas(
        background: languagesColours.sea,
        board: board,
        children: <Widget>[
          Positioned.fill(child: CustomPaint(painter: IslandPainter(languagesColours))),
          Positioned(
            left: 0,
            right: 0,
            top: 12,
            child: Center(
              child: Container(
                key: const Key('doors-title'),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                decoration: BoxDecoration(
                  color: TokenColors.paper,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: softShadow,
                ),
                child: Text(He.landLanguages.text, style: AppText.fixed(size: 24, weight: 700)),
              ),
            ),
          ),
          if (widget.companion != null)
            Positioned(
              left: 16,
              bottom: 8,
              width: s.companion,
              height: s.companion,
              child: widget.companion!,
            ),
          // The doors, from the start (the right) in the fixed order: the first is the rightmost. Each is a tap rectangle of its
          // own, its bubble, its door and its host, and nothing round them (docs/design/languages-island.md section 4.2.1).
          for (int i = 0; i < doors.length; i++)
            Positioned(
              left: rowLeft + (doors.length - 1 - i) * (s.door + gap) + s.inset,
              top: s.bubbleTop,
              width: s.unitWidth,
              height: s.unitHeight(board.size.height),
              child: _DoorUnit(
                key: Key('door-${doors[i]}'),
                course: doors[i],
                spec: s,
                open: _opening == doors[i],
                still: still,
                pulse: _pulse,
                idle: AnimatedBuilder(
                  animation: _idle,
                  builder: (BuildContext c, Widget? w) => Transform.scale(scale: _idleScale(i), child: w),
                  child: _Hello(course: doors[i], spec: s, ringed: _opening == doors[i]),
                ),
                onTap: () => _open(doors[i]),
              ),
            ),
          PositionedDirectional(
            start: 16,
            top: 8,
            child: PebbleButton(
              key: const Key('doors-back'),
              semanticLabel: He.landBackSemantics.text,
              size: 48,
              fill: TokenColors.spark,
              lip: TokenColors.sparkDeep,
              onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
              child: const BoardSvg('assets/art/ui/home_palm.svg', width: 24, height: 24),
            ),
          ),
        ],
      ),
    );
  }
}

/// One door unit: the hello bubble above the door art with its host. The whole unit is one tap target.
class _DoorUnit extends StatelessWidget {
  const _DoorUnit({
    super.key,
    required this.course,
    required this.spec,
    required this.open,
    required this.still,
    required this.pulse,
    required this.idle,
    required this.onTap,
  });

  final String course;
  final _DoorsSpec spec;
  final bool open;
  final bool still;
  final Animation<double> pulse;
  final Widget idle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final double doorHeight = spec.door * 1.25;
    final double bubbleMax = spec.unitWidth;
    return Semantics(
      button: true,
      label: languageName(course).text,
      child: ExcludeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              Positioned(
                left: -spec.inset.toDouble(),
                top: spec.doorTop - spec.bubbleTop,
                width: spec.door,
                height: doorHeight,
                // The closed door cross-fades to the open one in 200 ms (at once when motion is reduced).
                child: AnimatedCrossFade(
                  duration: still ? Duration.zero : const Duration(milliseconds: 200),
                  crossFadeState: open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                  firstChild: BoardSvg(
                    'assets/art/languages/door_$course.svg',
                    width: spec.door,
                    height: doorHeight,
                  ),
                  secondChild: BoardSvg(
                    'assets/art/languages/door_${course}_open.svg',
                    width: spec.door,
                    height: doorHeight,
                  ),
                ),
              ),
              // The bubble, centred over its door; the tail points down at it.
              Positioned(
                left: 0,
                top: 0,
                width: bubbleMax,
                height: spec.bubbleHeight + 12,
                child: Center(
                  child: AnimatedBuilder(
                    animation: pulse,
                    builder: (BuildContext c, Widget? w) {
                      final double t = pulse.value;
                      final double scale = open && !still ? 1 + 0.06 * (t < 0.5 ? t * 2 : (1 - t) * 2) : 1;
                      return Transform.scale(scale: scale, child: w);
                    },
                    child: SizedBox(height: spec.bubbleHeight + 12, child: idle),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The hello bubble: paper, radius 20, a tail 18 wide and 12 high under its middle, and in it, in a row that runs left to right,
/// the word, a gap of 8 and the hear mark. The word is an isolated run in its own direction and locale.
class _Hello extends StatelessWidget {
  const _Hello({required this.course, required this.spec, required this.ringed});

  final String course;
  final _DoorsSpec spec;

  /// A gold ring, 4 wide, while the hello plays.
  final bool ringed;

  @override
  Widget build(BuildContext context) {
    final double size = spec.helloSize;
    final Widget word = switch (course) {
      Course.eng => TargetText(helloEnglish, language: TargetLanguage.english, size: size * 1.1),
      Course.rus => TargetText(helloRussian, language: TargetLanguage.russian, size: size * 1.1),
      _ => Text(
        He.helloHeb.text,
        textDirection: TextDirection.rtl,
        style: AppText.fixed(size: size, weight: 700, lineHeight: 1.7),
      ),
    };
    final double mark = size * (course == Course.heb ? 1 : 1.1) * 0.8;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          height: spec.bubbleHeight,
          padding: const EdgeInsetsDirectional.only(start: 16, end: 14),
          decoration: BoxDecoration(
            color: TokenColors.paper,
            borderRadius: BorderRadius.circular(20),
            boxShadow: softShadow,
            border: ringed ? Border.all(color: TokenColors.spark, width: 4) : null,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  word,
                  const SizedBox(width: 8),
                  Opacity(
                    opacity: 0.75,
                    child: BoardSvg('assets/art/languages/speaker.svg', width: mark, height: mark),
                  ),
                ],
              ),
            ),
          ),
        ),
        CustomPaint(size: const Size(18, 12), painter: const _Tail()),
      ],
    );
  }
}

class _Tail extends CustomPainter {
  const _Tail();

  @override
  void paint(Canvas canvas, Size size) {
    final Path p = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(p, Paint()..color = TokenColors.paper);
  }

  @override
  bool shouldRepaint(_Tail old) => false;
}
