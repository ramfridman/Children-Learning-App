import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show OrdinalSortKey;

import '../design/app_text.dart';
import '../design/board.dart';
import '../design/components.dart';
import '../design/layout.dart';
import '../design/tokens.g.dart';
import '../strings/he.dart';
import 'home_island_name.dart';

/// The picture the sticker book shows on its cover until the child has a sticker of their own.
const String firstStickerAsset = 'assets/art/stickers/sticker_01.svg';

/// The child's home (B-26, "Nitzi's home"): a close-up of the child's island, opened from the home island's sign and
/// Today's Adventure on the map. Four things on it (docs/design/nitzi-home.md sections 2 and 3): the bottle (today's
/// adventure), the friend at its house door (greets), the sticker book and the lighthouse (the Trophy Hall); the island's
/// name at the top and the back pebble to the map. Nothing is timed: the bubble stays while the child is here, the bottle
/// bobs like the friend breathes (still with reduce motion), and nothing counts or ends.
class HomeIslandScreen extends StatefulWidget {
  const HomeIslandScreen({
    super.key,
    required this.island,
    this.companion,
    this.onCompanion,
    this.onBottle,
    this.onStickers,
    this.onHall,
    this.hallGlow = false,
    this.sticker = firstStickerAsset,
  });

  /// The island's words: the title (the whole name) and what a screen reader says; the bubble uses its cleaned name.
  final HomeIslandName island;

  /// The friend the child chose (a live character view), at its house door.
  final Widget? companion;

  /// The child touched the friend (it waves; the bubble says [He.nitziHomeHi]).
  final VoidCallback? onCompanion;

  /// Today's adventure, the sticker book and the Trophy Hall.
  final VoidCallback? onBottle;
  final VoidCallback? onStickers;
  final VoidCallback? onHall;

  /// Something waits in the Hall: the lighthouse's lantern shows a trophy in a warm halo.
  final bool hallGlow;

  /// The sticker on the book's cover: the child's latest one, or the first drawing of the set.
  final String sticker;

  @override
  State<HomeIslandScreen> createState() => _HomeIslandScreenState();
}

/// Everything that differs between the four boards of the home, in board coordinates (nitzi-home.md section 3).
class _IslandSpec {
  const _IslandSpec({
    required this.scene,
    required this.bottle,
    required this.companion,
    required this.book,
    required this.lighthouse,
    required this.bubble,
    required this.bubbleMaxWidth,
    required this.bubbleFont,
    required this.bubblePad,
    required this.titleTop,
    required this.titleBase,
    required this.titleMaxText,
    required this.backStart,
    required this.backTop,
    required this.tablet,
  });

  final String scene;

  /// The objects' boxes (the design's tap rectangles); each picture is drawn inside its own with `BoxFit.contain`,
  /// standing on the box's bottom edge. A touch counts in the whole box, except the bottle's: see [bottleHitArea].
  final Rect bottle;
  final Rect companion;
  final Rect book;
  final Rect lighthouse;

  /// The bubble's top left corner, beside the friend's head on the start side, and its widest (padding included).
  final Offset bubble;
  final double bubbleMaxWidth;
  final double bubbleFont;
  final EdgeInsets bubblePad;

  /// The title: its top, the size it starts at, and the widest its text may be (section 3.1).
  final double titleTop;
  final double titleBase;
  final double titleMaxText;
  final double backStart;
  final double backTop;
  final bool tablet;

  double get backSize => tablet ? 64 : 48;
  double get labelSize => tablet ? 18 : 14;

  /// Where the bubble's wedge tail ends: just outside the friend's head, beside its mouth (nitzi-home.md section 3,
  /// "Bubble tail"), from the friend's tap area. Fixed on the board, so a taller bubble only shortens the wedge.
  Offset get tailTip => companion.topLeft + Offset(0.74 * companion.width, 0.47 * companion.height);

  /// The title card around its text: horizontal padding, border, the island glyph and its gap (section 3.1).
  double get titlePad => tablet ? 12 : 8;
  double get titleGlyph => tablet ? 32 : 24;
  double get titleGap => tablet ? 6 : 4;
  double get titleFrame => 2 * (titlePad + 3) + titleGlyph + titleGap;

  static const _IslandSpec phone = _IslandSpec(
    scene: 'assets/art/scenes/nitzi_home_phone.svg',
    bottle: Rect.fromLTWH(600, 192, 160, 144),
    companion: Rect.fromLTWH(380, 160, 160, 160),
    book: Rect.fromLTWH(208, 216, 128, 120),
    lighthouse: Rect.fromLTWH(32, 88, 128, 248),
    bubble: Offset(548, 100),
    bubbleMaxWidth: 260,
    bubbleFont: 18,
    bubblePad: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
    titleTop: 8,
    titleBase: 22,
    titleMaxText: 610,
    backStart: 16,
    backTop: 8,
    tablet: false,
  );

  static const _IslandSpec phoneSE = _IslandSpec(
    scene: 'assets/art/scenes/nitzi_home_phone_se.svg',
    bottle: Rect.fromLTWH(468, 188, 136, 136),
    companion: Rect.fromLTWH(304, 172, 132, 132),
    book: Rect.fromLTWH(168, 212, 112, 112),
    // 12 lower than the first plan, so a two-line title at text scale 1.3 stays clear of the lantern.
    lighthouse: Rect.fromLTWH(24, 96, 112, 228),
    bubble: Offset(420, 104),
    bubbleMaxWidth: 230,
    bubbleFont: 17,
    bubblePad: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
    titleTop: 8,
    titleBase: 20,
    titleMaxText: 425,
    backStart: 16,
    backTop: 8,
    tablet: false,
  );

  static const _IslandSpec tabletLandscape = _IslandSpec(
    scene: 'assets/art/scenes/nitzi_home_tablet_landscape.svg',
    bottle: Rect.fromLTWH(900, 480, 200, 200),
    companion: Rect.fromLTWH(600, 380, 240, 240),
    book: Rect.fromLTWH(360, 516, 176, 176),
    lighthouse: Rect.fromLTWH(80, 220, 200, 480),
    bubble: Offset(800, 296),
    bubbleMaxWidth: 356,
    bubbleFont: 24,
    bubblePad: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    titleTop: 24,
    titleBase: 28,
    titleMaxText: 872,
    backStart: 24,
    backTop: 24,
    tablet: true,
  );

  static const _IslandSpec tabletPortrait = _IslandSpec(
    scene: 'assets/art/scenes/nitzi_home_tablet_portrait.svg',
    bottle: Rect.fromLTWH(500, 760, 220, 200),
    companion: Rect.fromLTWH(300, 380, 240, 240),
    book: Rect.fromLTWH(150, 780, 176, 176),
    lighthouse: Rect.fromLTWH(48, 200, 160, 440),
    bubble: Offset(500, 300),
    bubbleMaxWidth: 296,
    bubbleFont: 24,
    bubblePad: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    titleTop: 32,
    titleBase: 28,
    titleMaxText: 512,
    backStart: 24,
    backTop: 32,
    tablet: true,
  );

  static _IslandSpec of(BoardClass b) => switch (b) {
    BoardClass.phone => phone,
    BoardClass.phoneSE => phoneSE,
    BoardClass.tabletLandscape => tabletLandscape,
    BoardClass.tabletPortrait => tabletPortrait,
  };
}

/// The pictures of the three objects (`tools/make_nitzi_home.py`) and their own sizes (viewBox).
const String _bottleArt = 'assets/art/home/bottle_big.svg';
const String _bookArt = 'assets/art/home/sticker_book.svg';
const String _lighthouseArt = 'assets/art/home/lighthouse.svg';
const Size _bottleSize = Size(100, 100);
const Size _bookSize = Size(100, 100);
const Size _lighthouseSize = Size(100, 220);

/// Where the bottle is really drawn inside its 100 x 100 picture (the lying, tilted bottle leaves the top of its box
/// empty; measured on the rendered picture).
const Rect _bottleDrawn = Rect.fromLTRB(10, 37, 96.5, 90);

/// What a finger may miss the drawn bottle by, in board points: the bob moves it 4 up or down and the tilt a few more
/// to the side, and a small child does not aim well.
const double _bottleSlack = 6;

/// The part of the bottle's box (the design's tap rectangle, whose picture stands on its bottom edge, `BoxFit.contain`)
/// where a touch opens Today's Adventure: the drawn bottle with [_bottleSlack] around it, in the box's own coordinates,
/// never beyond the box (a touch outside the box never reaches its children).
@visibleForTesting
Rect bottleHitArea(Size box) {
  final double side = math.min(box.width, box.height);
  final double k = side / _bottleSize.width;
  final Offset origin = Offset((box.width - side) / 2, box.height - side);
  return Rect.fromLTRB(
    origin.dx + _bottleDrawn.left * k - _bottleSlack,
    origin.dy + _bottleDrawn.top * k - _bottleSlack,
    origin.dx + _bottleDrawn.right * k + _bottleSlack,
    origin.dy + _bottleDrawn.bottom * k + _bottleSlack,
  ).intersect(Offset.zero & box);
}

/// The warm glow of "something waits" (the same as the map sign's).
const Color _waitingGlow = Color(0xAAFFD45C);

class _HomeIslandScreenState extends State<HomeIslandScreen> with SingleTickerProviderStateMixin {
  /// The bottle's gentle bob: one slow round trip, again and again, like the friend's breath (nothing counts or ends).
  late final AnimationController _bob = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  /// The child touched the friend: the bubble says hello instead of the welcome, and keeps saying it.
  bool _hi = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _bob
        ..stop()
        ..value = 0;
    } else if (!_bob.isAnimating) {
      _bob.repeat();
    }
  }

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  void _greet() {
    setState(() => _hi = true);
    widget.onCompanion?.call();
  }

  @override
  Widget build(BuildContext context) {
    final BoardClass board = AppLayout.of(context).board;
    final _IslandSpec s = _IslandSpec.of(board);
    return Scaffold(
      body: BoardCanvas(
        background: TokenColors.worldSea1,
        board: board,
        children: <Widget>[
          Positioned.fill(
            child: BoardSvg(s.scene, width: board.size.width, height: board.size.height),
          ),
          // The reading order (right to left): back, title, bottle, friend, book, lighthouse.
          _thing(
            s.lighthouse,
            id: 'lighthouse',
            order: 5,
            semantics: widget.hallGlow
                ? '${He.hallSemantics.text}, ${He.trophyNewSemantics.text}'
                : He.hallSemantics.text,
            onTap: widget.onHall,
            child: _Picture(
              _lighthouseArt,
              size: _lighthouseSize,
              overlays: <Widget>[if (widget.hallGlow) ..._waitingInLantern],
            ),
          ),
          _thing(
            s.book,
            id: 'book',
            order: 4,
            semantics: He.stickersSemantics.text,
            onTap: widget.onStickers,
            child: _Picture(
              _bookArt,
              size: _bookSize,
              overlays: <Widget>[
                // The cover panel (x 33..63, y 19..49 of the book).
                Positioned(left: 33, top: 19, width: 30, height: 30, child: BoardSvg(widget.sticker)),
              ],
            ),
          ),
          _thing(
            s.bottle,
            id: 'bottle',
            order: 2,
            semantics: He.homeDaily.text,
            onTap: widget.onBottle,
            // Only the drawn bottle opens it; the empty part of its box does nothing (and a screen reader finds the same area).
            hit: bottleHitArea(s.bottle.size),
            // Its own layer, so the bob repaints the bottle alone and not the scene under it.
            child: RepaintBoundary(
              child: _Bobbing(
                bob: _bob,
                child: const _Picture(_bottleArt, size: _bottleSize),
              ),
            ),
          ),
          Positioned.fromRect(
            rect: s.companion,
            child: Semantics(
              container: true,
              sortKey: const OrdinalSortKey(3),
              button: true,
              child: _Squash(
                key: const Key('home-island-companion'),
                onTap: _greet,
                child: widget.companion ?? const SizedBox.expand(),
              ),
            ),
          ),
          _label(context, s, s.lighthouse, 'lighthouse', He.homeHallLabel.text),
          _label(context, s, s.book, 'book', He.homeStickersLabel.text),
          _label(context, s, s.bottle, 'bottle', He.homeDaily.text),
          // The bubble only speaks: a touch on it reaches the friend under it.
          Positioned(
            left: s.bubble.dx,
            top: s.bubble.dy,
            child: IgnorePointer(
              child: KeyedSubtree(
                key: const Key('home-island-bubble'),
                child: BoardBubble(
                  text: _hi ? He.nitziHomeHi.text : _welcome(context, s),
                  fontSize: s.bubbleFont,
                  padding: s.bubblePad,
                  maxWidth: s.bubbleMaxWidth,
                  tailTip: s.tailTip - s.bubble,
                ),
              ),
            ),
          ),
          Positioned(
            top: s.titleTop,
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.topCenter,
              child: Semantics(
                container: true,
                sortKey: const OrdinalSortKey(1),
                child: _IslandTitle(spec: s, island: widget.island),
              ),
            ),
          ),
          PositionedDirectional(
            start: s.backStart,
            top: s.backTop,
            child: Semantics(
              container: true,
              sortKey: const OrdinalSortKey(0),
              child: PebbleButton(
                key: const Key('home-island-back'),
                semanticLabel: He.landBackSemantics.text,
                size: s.backSize,
                fill: TokenColors.spark,
                lip: TokenColors.sparkDeep,
                onPressed: () => Navigator.of(context).pop(),
                child: BoardSvg('assets/art/ui/home_palm.svg', width: s.backSize / 2, height: s.backSize / 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// One of the three objects: its box, announced as a button, with its picture inside. A touch counts in the whole box,
  /// or only in [hit] (in the box's coordinates) when given: then the box is keyed `home-island-$id-box` and `home-island-$id`
  /// is the area itself, the one a finger and a screen reader meet.
  Widget _thing(
    Rect rect, {
    required String id,
    required int order,
    required String semantics,
    required VoidCallback? onTap,
    required Widget child,
    Rect? hit,
  }) {
    Widget announce(Widget button, {Key? key}) => Semantics(
      key: key,
      sortKey: OrdinalSortKey(order.toDouble()),
      container: true,
      button: true,
      label: semantics,
      child: button,
    );
    return Positioned.fromRect(
      rect: rect,
      child: hit == null
          ? announce(_Squash(key: Key('home-island-$id'), onTap: onTap, child: child))
          : _Squash(
              key: Key('home-island-$id-box'),
              onTap: onTap,
              hit: hit,
              announce: (Widget button) => announce(button, key: Key('home-island-$id')),
              child: child,
            ),
    );
  }

  /// The words under an object (not tappable; a screen reader hears the object's own label). They end above the bottom
  /// 24 of the board: at a large text scale on the SE that lifts them a few points into the object's own tap area.
  Widget _label(BuildContext context, _IslandSpec s, Rect under, String id, String text) {
    final double height = (MediaQuery.textScalerOf(context).scale(s.labelSize) * 1.7).ceilToDouble();
    final double lowest = AppLayout.of(context).board.size.height - 24 - height;
    return Positioned(
      left: under.center.dx - 200,
      width: 400,
      top: math.min(under.bottom, lowest),
      child: IgnorePointer(
        child: ExcludeSemantics(
          child: Align(
            alignment: Alignment.topCenter,
            child: Text(
              text,
              key: Key('home-island-label-$id'),
              softWrap: false,
              style: AppText.fixed(size: s.labelSize, weight: 700),
            ),
          ),
        ),
      ),
    );
  }

  /// The welcome with the child's name in an isolate. The name is shortened ([shortenName], with "…") only as far as it
  /// must be: so that no word breaks between its letters and the bubble keeps to [_bubbleLines].
  String _welcome(BuildContext context, _IslandSpec s) {
    final String name = widget.island.name;
    if (name.isEmpty) return He.nitziHomeWelcomeNoName.text;
    String line(String n) => He.nitziHomeWelcome.fill(<String, String>{'child': isolatedName(n)});
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    final TextPainter painter = TextPainter(textDirection: TextDirection.rtl, textScaler: scaler);
    final double room = s.bubbleMaxWidth - s.bubblePad.horizontal;
    final TextStyle style = AppText.fixed(size: s.bubbleFont, weight: 500);
    final int most = _bubbleLines(s, scaler);
    bool fits(String n) {
      final String text = line(n);
      if (!_wordsFit(painter, text, style, room)) return false;
      painter
        ..text = TextSpan(text: text, style: style)
        ..layout(maxWidth: room);
      return painter.computeLineMetrics().length <= most;
    }

    try {
      String tried = name;
      if (fits(name)) return line(name);
      for (int max = name.characters.length - 1; max >= 3; max--) {
        final String short = shortenName(name, max);
        if (short == tried) continue;
        tried = short;
        if (fits(short)) return line(short);
      }
      return line(tried);
    } finally {
      painter.dispose();
    }
  }

  /// The most lines the welcome may take: two, as designed; at a larger text scale a third where it still ends 16 above
  /// the bottle (the tablets), so a longer part of the child's name stays in it.
  static int _bubbleLines(_IslandSpec s, TextScaler scaler) {
    if (scaler.scale(1) <= 1) return 2;
    final double line = scaler.scale(s.bubbleFont) * 1.7;
    final int room = ((s.bottle.top - 16 - s.bubble.dy - s.bubblePad.vertical) / line).floor();
    return room.clamp(2, 3);
  }

  /// The trophy in the lighthouse's lantern window (x 35..65, y 36..60), at 0.8 of its width, in a warm halo centred on
  /// (50, 48); in the lighthouse's own coordinates.
  static const List<Widget> _waitingInLantern = <Widget>[
    Positioned(
      left: 35,
      top: 33,
      width: 30,
      height: 30,
      child: DecoratedBox(
        key: Key('home-island-lantern-glow'),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: <BoxShadow>[BoxShadow(color: _waitingGlow, blurRadius: 20, spreadRadius: 4)],
        ),
      ),
    ),
    // trophy_gold.svg is 120 x 140: 24 wide is 28 high.
    Positioned(
      left: 38,
      top: 34,
      width: 24,
      height: 28,
      child: BoardSvg('assets/art/trophies/trophy_gold.svg', key: Key('home-island-lantern-trophy')),
    ),
  ];
}

/// Whether every word of [text] (split at its spaces; a no-break space keeps two words together) fits in [width] on
/// a line of its own, so Flutter never has to break a word between its letters.
bool _wordsFit(TextPainter painter, String text, TextStyle style, double width) {
  for (final String word in text.split(' ')) {
    painter
      ..text = TextSpan(text: word, style: style)
      ..layout();
    if (painter.width > width) return false;
  }
  return true;
}

/// A picture of its own [size] (viewBox) drawn as large as its box lets it be, standing on the box's bottom edge, with
/// [overlays] placed in the picture's own coordinates.
class _Picture extends StatelessWidget {
  const _Picture(this.asset, {required this.size, this.overlays = const <Widget>[]});

  final String asset;
  final Size size;
  final List<Widget> overlays;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.bottomCenter,
    child: AspectRatio(
      aspectRatio: size.aspectRatio,
      child: FittedBox(
        child: SizedBox.fromSize(
          size: size,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              BoardSvg(asset, width: size.width, height: size.height),
              ...overlays,
            ],
          ),
        ),
      ),
    ),
  );
}

/// The bottle's bob: ±4 up and down and ±3° about its bottom centre, following [bob] (still when it stands still).
class _Bobbing extends StatelessWidget {
  const _Bobbing({required this.bob, required this.child});

  final Animation<double> bob;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: bob,
    child: child,
    builder: (BuildContext context, Widget? child) {
      final double wave = math.sin(bob.value * 2 * math.pi);
      return Transform.translate(
        offset: Offset(0, -4 * wave),
        child: Transform.rotate(
          angle: wave * 3 * math.pi / 180,
          alignment: Alignment.bottomCenter,
          child: child,
        ),
      );
    },
  );
}

/// A tap target that gives a little (0.96) the moment it is touched and acts when the finger lifts; a drag never acts.
/// It reacts in its whole box, or only in [hit] (in its own coordinates) when given: the rest of the box lets a touch
/// through to what lies under it. Then [announce] wraps the live area (the screen reader's button).
class _Squash extends StatefulWidget {
  const _Squash({super.key, required this.onTap, required this.child, this.hit, this.announce})
    : assert((hit == null) == (announce == null), 'a hit area needs its announcer');

  final VoidCallback? onTap;
  final Widget child;
  final Rect? hit;
  final Widget Function(Widget button)? announce;

  @override
  State<_Squash> createState() => _SquashState();
}

class _SquashState extends State<_Squash> {
  bool _down = false;

  void _press(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    final bool live = widget.onTap != null;
    Widget detector({Widget? child}) => GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: live ? (_) => _press(true) : null,
      onTapUp: live ? (_) => _press(false) : null,
      onTapCancel: live ? () => _press(false) : null,
      onTap: widget.onTap,
      child: child,
    );
    final Widget scaled = Transform.scale(scale: _down ? 0.96 : 1, child: widget.child);
    final Rect? hit = widget.hit;
    if (hit == null) return detector(child: scaled);
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Positioned.fill(child: scaled),
        Positioned.fromRect(rect: hit, child: widget.announce!(detector())),
      ],
    );
  }
}

/// The island's name at the top (section 3.1): a wooden card with the island glyph on the start side, the whole title
/// as large as its box lets it be, on one line or two.
class _IslandTitle extends StatelessWidget {
  const _IslandTitle({required this.spec, required this.island});

  final _IslandSpec spec;
  final HomeIslandName island;

  @override
  Widget build(BuildContext context) {
    final IslandTitleFit fit = fitIslandTitle(
      island.title,
      base: spec.titleBase,
      maxText: spec.titleMaxText,
      scaler: MediaQuery.textScalerOf(context),
    );
    return Semantics(
      header: true,
      label: island.semantics,
      child: ExcludeSemantics(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: spec.titleMaxText + spec.titleFrame),
          // The last guard only: never reached with 24 letters and "…" at text scale 1.3 on any board.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Container(
              key: const Key('home-island-title'),
              padding: EdgeInsets.symmetric(horizontal: spec.titlePad),
              decoration: BoxDecoration(
                color: TokenColors.worldWoodLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: TokenColors.ink, width: 3),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  BoardSvg('assets/art/ui/land_nitzi.svg', width: spec.titleGlyph, height: spec.titleGlyph),
                  SizedBox(width: spec.titleGap),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: fit.box),
                    child: Text(
                      island.title,
                      textAlign: TextAlign.center,
                      textWidthBasis: TextWidthBasis.longestLine,
                      style: islandTitleStyle(fit.size),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The title's size in points (before the text scale), its number of lines, the width of its longest line and the
/// width it is laid out in (the max text width, or the widest word when even the last step does not fit: the guard).
typedef IslandTitleFit = ({double size, int lines, double width, double box});

/// The sizes the title takes two lines at, largest first; 15 is the floor, as on the map sign.
const List<double> islandTitleTwoLineSizes = <double>[18, 17, 16, 15];

TextStyle islandTitleStyle(double size) => AppText.fixed(size: size, weight: 700);

/// The title [title] in a text at most [maxText] wide, measured with the screen's [scaler] (section 3.1):
/// 1. one line, from [base] down to 18, the first size at which it fits;
/// 2. two lines at 18, then 17, 16 and 15: accepted when the layout has at most two lines and every word fits on a line
///    of its own (Flutter would otherwise break a long word between its letters);
/// 3. otherwise 15, laid out in the widest word's width, which the title card scales down into its box.
@visibleForTesting
IslandTitleFit fitIslandTitle(
  String title, {
  required double base,
  required double maxText,
  required TextScaler scaler,
}) {
  final TextPainter painter = TextPainter(
    textDirection: TextDirection.rtl,
    textAlign: TextAlign.center,
    textWidthBasis: TextWidthBasis.longestLine,
    textScaler: scaler,
  );
  void lay(double size, double width) => painter
    ..text = TextSpan(text: title, style: islandTitleStyle(size))
    ..layout(maxWidth: width);

  try {
    for (double size = base; size >= 18; size--) {
      lay(size, double.infinity);
      if (painter.width <= maxText) return (size: size, lines: 1, width: painter.width, box: maxText);
    }
    for (final double size in islandTitleTwoLineSizes) {
      if (!_wordsFit(painter, title, islandTitleStyle(size), maxText)) continue;
      lay(size, maxText);
      final int lines = painter.computeLineMetrics().length;
      if (lines <= 2) return (size: size, lines: lines, width: painter.width, box: maxText);
    }
    final double size = islandTitleTwoLineSizes.last;
    double widest = maxText;
    for (final String word in title.split(' ')) {
      painter
        ..text = TextSpan(text: word, style: islandTitleStyle(size))
        ..layout();
      widest = math.max(widest, painter.width);
    }
    lay(size, widest);
    return (size: size, lines: painter.computeLineMetrics().length, width: painter.width, box: widest);
  } finally {
    painter.dispose();
  }
}
