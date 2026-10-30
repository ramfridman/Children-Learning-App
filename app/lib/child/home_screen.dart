import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../design/app_text.dart';
import '../design/board.dart';
import '../design/components.dart';
import '../design/layout.dart';
import '../design/tokens.g.dart';
import '../strings/he.dart';
import 'art.dart';
import 'home_island_name.dart';

/// A land of the world map, with the sign under its island.
enum Land {
  nitzi(He.landNitzi, 'land_nitzi'),
  counting(He.landCounting, 'land_counting'),
  colors(He.landColors, 'land_colors'),
  shapes(He.landShapes, 'land_shapes'),
  logic(He.landLogic, 'land_logic'),
  robots(He.landRobots, 'land_robots'),
  market(He.landMarket, 'land_market');

  const Land(this.label, this.icon);

  final Str label;
  final String icon;
}

/// Where a land's sign goes in the world of the map: the `left` it is centred on (`translateX(-50%)`) and its `top`.
class _Sign {
  const _Sign(this.land, this.left, this.top);

  final Land land;
  final double left;
  final double top;
}

/// Everything that differs between the four boards of the home screen. Numbers are the boards' own; the map's own parts
/// (scene, signs, companion, "+", bubble) are in world coordinates, the rest in board coordinates (board B-23,
/// docs/design/phone-map-7-lands.md).
class _HomeSpec {
  const _HomeSpec({
    required this.scene,
    required this.worldWidth,
    required this.worldHeight,
    required this.scrollAxis,
    required this.tapWidth,
    required this.plusLeft,
    required this.plusTop,
    required this.bubbleAtBoardPlace,
    required this.avatarRight,
    required this.avatarTop,
    required this.avatarSize,
    required this.clusterLeft,
    required this.clusterTop,
    required this.parentsRowHeight,
    required this.pillTop,
    required this.pillHeight,
    required this.pillIcon,
    required this.pillTitle,
    required this.pillPadLeft,
    required this.pillPadRight,
    required this.pillGap,
    required this.bubbleRight,
    required this.bubbleTop,
    required this.bubbleFont,
    required this.bubblePad,
    required this.signs,
    required this.companionLeft,
    required this.companionTop,
    required this.homeSignLeft,
    required this.homeSignRight,
    this.pillFrameLeft,
    this.pillFrameWidth,
    this.pillFrameInset = 0,
    required this.bubbleMaxWidth,
    this.bubbleBreaks = false,
  });

  final String scene;

  /// The size of the world the map is drawn in: the scene's own viewBox. On a phone it is a strip wider than the board
  /// that pans sideways; on a tablet in portrait it is taller and scrolls up; in landscape it is the board.
  final double worldWidth;
  final double worldHeight;

  /// How the world moves under the fixed buttons; null when it is exactly the board and does not move.
  final Axis? scrollAxis;

  /// The width of the tap area above each land's sign (160 high, ending 10 under the sign's top).
  final double tapWidth;

  /// Where the "+" pebble (choose a friend) stands, at the companion's feet.
  final double plusLeft;
  final double plusTop;

  /// True: the bubble stays at the board's own place ([bubbleRight], [bubbleTop]). All four boards are false now (B-34:
  /// the phones too stand it beside the companion's mouth); that place is used only when no friend is on the map.
  final bool bubbleAtBoardPlace;
  final double avatarRight;
  final double avatarTop;
  final double avatarSize;
  final double clusterLeft;
  final double clusterTop;

  /// The Parents button is centred on a row this high at [clusterLeft], [clusterTop]: where the boards put it beside
  /// the book, which is gone (B-26: it did nothing). Nothing moved into its place.
  final double parentsRowHeight;
  final double pillTop;
  final double pillHeight;
  final double pillIcon;
  final double pillTitle;
  final double pillPadLeft;
  final double pillPadRight;
  final double pillGap;

  /// Board 10 puts the pill in a 270 wide box at `left` 300 (the pill sits at the box's right edge).
  /// The other boards centre it across the whole width, shifted by [pillFrameInset] on the left.
  final double? pillFrameLeft;
  final double? pillFrameWidth;
  final double pillFrameInset;
  final double bubbleRight;
  final double bubbleTop;
  final double bubbleFont;
  final EdgeInsets bubblePad;

  /// The widest the bubble may be, padding included: 210 (190 on the SE), and a longer line breaks after the child's name
  /// ([bubbleBreaks], design review of B-26 step 2 and B-34), so it stays beside the friend and off Counting Hills.
  final double bubbleMaxWidth;
  final bool bubbleBreaks;
  final List<_Sign> signs;

  /// Where the companion stands on the map: the place Nitzi's art had in the board, at 0.3 of its 512 point canvas.
  final double companionLeft;
  final double companionTop;
  static const double companionSize = 153.6;

  /// Where the home island's sign may stand, in world x (B-26, docs/design/nitzi-home.md section 4): inside the island's
  /// tap area and 12 clear of the "+" pebble's tap area.
  final double homeSignLeft;
  final double homeSignRight;

  static const _HomeSpec phone = _HomeSpec(
    scene: 'assets/art/scenes/home_phone.svg',
    worldWidth: 2102,
    worldHeight: 393,
    scrollAxis: Axis.horizontal,
    tapWidth: 240,
    plusLeft: 1990,
    plusTop: 268,
    bubbleAtBoardPlace: false,
    avatarRight: 59,
    avatarTop: 12,
    avatarSize: 64,
    clusterLeft: 59,
    clusterTop: 12,
    parentsRowHeight: 64,
    pillTop: 12,
    pillHeight: 72,
    pillIcon: 48,
    pillTitle: 20,
    pillPadLeft: 12,
    pillPadRight: 16,
    pillGap: 8,
    pillFrameLeft: 300,
    pillFrameWidth: 270,
    bubbleRight: 212,
    bubbleTop: 112,
    bubbleFont: 18,
    bubblePad: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
    bubbleMaxWidth: 210,
    bubbleBreaks: true,
    companionLeft: 1859,
    companionTop: 154,
    homeSignLeft: 1770,
    homeSignRight: 1978,
    // The start view is world x 1250 to 2102 (the board, with the whole Colour Bay sign); the rest is to the left.
    signs: <_Sign>[
      _Sign(Land.nitzi, 1890, 320),
      _Sign(Land.counting, 1610, 320),
      _Sign(Land.colors, 1320, 320),
      _Sign(Land.shapes, 1040, 320),
      _Sign(Land.logic, 760, 320),
      _Sign(Land.robots, 480, 320),
      _Sign(Land.market, 200, 320),
    ],
  );

  static const _HomeSpec phoneSE = _HomeSpec(
    scene: 'assets/art/scenes/home_phone_se.svg',
    worldWidth: 1834,
    worldHeight: 375,
    scrollAxis: Axis.horizontal,
    // Counting and Colour Bay are 246 apart on the approved board 12: 220 keeps a gap of 26 between their tap areas.
    tapWidth: 220,
    plusLeft: 1776,
    plusTop: 256,
    bubbleAtBoardPlace: false,
    avatarRight: 16,
    avatarTop: 8,
    avatarSize: 64,
    clusterLeft: 16,
    clusterTop: 8,
    parentsRowHeight: 64,
    pillTop: 8,
    pillHeight: 64,
    pillIcon: 44,
    pillTitle: 18,
    pillPadLeft: 8,
    pillPadRight: 16,
    pillGap: 8,
    pillFrameInset: 40,
    bubbleRight: 154,
    bubbleTop: 112,
    bubbleFont: 17,
    bubblePad: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
    bubbleMaxWidth: 190,
    bubbleBreaks: true,
    companionLeft: 1651,
    companionTop: 164.6,
    homeSignLeft: 1577,
    homeSignRight: 1764,
    // The start view is world x 1167 to 1834.
    signs: <_Sign>[
      _Sign(Land.nitzi, 1687, 314),
      _Sign(Land.counting, 1435, 314),
      _Sign(Land.colors, 1189, 314),
      _Sign(Land.shapes, 937, 314),
      _Sign(Land.logic, 685, 314),
      _Sign(Land.robots, 433, 314),
      _Sign(Land.market, 181, 314),
    ],
  );

  static const _HomeSpec tabletLandscape = _HomeSpec(
    scene: 'assets/art/scenes/home_tablet_landscape.svg',
    worldWidth: 1180,
    worldHeight: 820,
    scrollAxis: null,
    tapWidth: 240,
    plusLeft: 1088.6,
    plusTop: 556,
    bubbleAtBoardPlace: false,
    avatarRight: 24,
    avatarTop: 24,
    avatarSize: 80,
    clusterLeft: 24,
    clusterTop: 24,
    parentsRowHeight: 72,
    pillTop: 24,
    pillHeight: 88,
    pillIcon: 64,
    pillTitle: 26,
    pillPadLeft: 12,
    pillPadRight: 20,
    pillGap: 12,
    bubbleRight: 120,
    bubbleTop: 430,
    bubbleFont: 24,
    bubblePad: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    bubbleMaxWidth: 210,
    bubbleBreaks: true,
    companionLeft: 975,
    companionTop: 450.4,
    homeSignLeft: 890,
    homeSignRight: 1130,
    signs: <_Sign>[
      _Sign(Land.nitzi, 1010, 676),
      _Sign(Land.counting, 700, 666),
      _Sign(Land.colors, 420, 700),
      _Sign(Land.shapes, 220, 572),
      _Sign(Land.logic, 400, 372),
      _Sign(Land.robots, 640, 276),
      _Sign(Land.market, 900, 372),
    ],
  );

  static const _HomeSpec tabletPortrait = _HomeSpec(
    scene: 'assets/art/scenes/home_tablet_portrait.svg',
    worldWidth: 820,
    worldHeight: 1580,
    scrollAxis: Axis.vertical,
    tapWidth: 240,
    plusLeft: 703.6,
    plusTop: 1394.8,
    bubbleAtBoardPlace: false,
    avatarRight: 24,
    avatarTop: 32,
    avatarSize: 80,
    clusterLeft: 24,
    clusterTop: 32,
    parentsRowHeight: 72,
    pillTop: 36,
    pillHeight: 88,
    pillIcon: 64,
    pillTitle: 26,
    pillPadLeft: 12,
    pillPadRight: 20,
    pillGap: 12,
    bubbleRight: 214,
    bubbleTop: 1388,
    bubbleFont: 24,
    bubblePad: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    bubbleMaxWidth: 210,
    bubbleBreaks: true,
    companionLeft: 590,
    companionTop: 1289.2,
    homeSignLeft: 480,
    homeSignRight: 720,
    // Board 25 moved down 400 (the start view, world y 400 to 1580); Market Village is in the band above it.
    signs: <_Sign>[
      _Sign(Land.nitzi, 600, 1510),
      _Sign(Land.counting, 260, 1396),
      _Sign(Land.colors, 600, 1230),
      _Sign(Land.shapes, 230, 1054),
      _Sign(Land.logic, 600, 848),
      _Sign(Land.robots, 300, 716),
      _Sign(Land.market, 560, 356),
    ],
  );

  static _HomeSpec of(BoardClass b) => switch (b) {
    BoardClass.phone => phone,
    BoardClass.phoneSE => phoneSE,
    BoardClass.tabletLandscape => tabletLandscape,
    BoardClass.tabletPortrait => tabletPortrait,
  };
}

/// The world map (boards 10, 12, 22 and 25). The islands, Nitzi and the sea are the boards' own
/// artwork; the buttons, the daily pill, the bubble and the signs are placed at the boards' own
/// coordinates. In M1 only the counting hills open something (the activity frame).
///
/// Left out on purpose: the gold stars and the "call for help" flags of the boards. They show what a
/// child has mastered or asked for, which does not exist before the learning engine (M3).
class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.childName,
    required this.avatarId,
    required this.onParents,
    required this.onSwitchChild,
    required this.onOpenActivity,
    this.companion,
    this.companionMouth,
    this.onCompanion,
    this.onFriends,
    this.onOpenLand,
    this.openableLands = const <Land>{},
    this.stars = 0,
    this.hallGlow = false,
    this.homeIsland,
    this.onOpenHome,
  });

  /// The home island's words, named after the child (B-26). Null: the sign says Nitzi's island, as before.
  final HomeIslandName? homeIsland;

  /// Opens the child's home (B-26) from the home island's sign and tap area and from the daily pill. Null: the home
  /// island is a plain sign and the pill does nothing.
  final VoidCallback? onOpenHome;

  /// The child's name for the bubble when there is no [homeIsland] (whose cleaned name is used otherwise).
  final String childName;
  final String avatarId;
  final VoidCallback onParents;
  final VoidCallback onSwitchChild;

  /// Opens the activity frame (the counting hills). Real activities arrive in M2.
  final VoidCallback onOpenActivity;

  /// The character that walks the map with the child (a live [CharacterView]), drawn where the board put Nitzi.
  final Widget? companion;

  /// Where the companion's mouth is, as a share of its picture (the character's own `mouth`). The speech bubble
  /// points at it, so the bubble stays beside whichever friend is on the map.
  final Offset? companionMouth;

  /// The child touched the companion.
  final VoidCallback? onCompanion;

  /// The child wants to choose another companion (Friends' Beach).
  final VoidCallback? onFriends;

  /// A land with something in it was touched (M8): its island opens, with the objects that grow there. When this is null
  /// the counting hills open [onOpenActivity] as before.
  final void Function(Land land)? onOpenLand;

  /// The lands that have skills, so that a tap on their sign opens them.
  final Set<Land> openableLands;

  /// The golden stars the child has, shown under the avatar (nothing is shown at zero).
  final int stars;

  /// Something waits for the child in the Trophy Hall (which is in the child's home since B-26): the home island's sign
  /// glows and wears a small trophy, and its label says so.
  final bool hallGlow;

  VoidCallback? _tapFor(Land land) {
    // The home island is not a land with skills: it never goes through [onOpenLand].
    if (land == Land.nitzi) return onOpenHome;
    final void Function(Land)? open = onOpenLand;
    if (open != null) return openableLands.contains(land) ? () => open(land) : null;
    return land == Land.counting ? onOpenActivity : null;
  }

  @override
  Widget build(BuildContext context) {
    final BoardClass board = AppLayout.of(context).board;
    final _HomeSpec s = _HomeSpec.of(board);
    return Scaffold(
      body: BoardCanvas(
        background: TokenColors.worldSea1,
        board: board,
        children: <Widget>[
          // The world: it moves under the fixed buttons (on a phone sideways, home at the right; on a tablet in portrait
          // upwards, home at the bottom). A still tap opens a land; a drag that starts on it pans.
          Positioned.fill(
            child: s.scrollAxis == null
                ? _world(s)
                : SingleChildScrollView(
                    key: const PageStorageKey<String>('home-map'),
                    scrollDirection: s.scrollAxis!,
                    // Right to left, offset 0 of a horizontal view is its right end already; a vertical one is turned
                    // so that offset 0 is its bottom.
                    reverse: s.scrollAxis == Axis.vertical,
                    physics: const BouncingScrollPhysics(),
                    child: _world(s),
                  ),
          ),
          // Start corner: who is playing.
          boardAt(
            right: s.avatarRight,
            top: s.avatarTop,
            child: AvatarButton(
              avatarId: avatarId,
              diameter: s.avatarSize,
              label: He.switchChildSemantics.text,
              onPressed: onSwitchChild,
            ),
          ),
          // Under the avatar: the golden stars the child has (B-26: the sticker and Hall pebbles moved into the child's
          // home, as its book and lighthouse).
          if (stars > 0)
            Positioned(
              right: s.avatarRight,
              top: s.avatarTop + s.avatarSize + 10,
              child: Semantics(
                label: '${He.starsSemantics.text} $stars',
                child: ExcludeSemantics(
                  child: Container(
                    key: const Key('home-stars'),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: TokenColors.paper,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: TokenColors.ink, width: 2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const BoardSvg('assets/art/world/star_gold.svg', width: 22, height: 22),
                        const SizedBox(width: 4),
                        Text('$stars', style: AppText.fixed(size: 20, weight: 700)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          // End corner: the visibly adult "Parents" button.
          Positioned(
            left: s.clusterLeft,
            top: s.clusterTop,
            height: s.parentsRowHeight,
            child: Align(
              widthFactor: 1,
              child: ParentEntryButton(label: He.homeParents.text, onPressed: onParents),
            ),
          ),
          _pill(s),
        ],
      ),
    );
  }

  /// Everything that belongs to the map, in world coordinates. Paint order: the scene, the tap areas, the signs, then the
  /// companion, its "+" and the bubble, so that a land's tap area never takes a touch meant for the companion.
  Widget _world(_HomeSpec s) => SizedBox(
    width: s.worldWidth,
    height: s.worldHeight,
    child: Stack(
      children: <Widget>[
        Positioned.fill(
          child: BoardSvg(
            s.scene,
            width: s.worldWidth,
            height: s.worldHeight,
            label: He.homeMapSemantics.text,
          ),
        ),
        // A tap area above the sign of each land that has somewhere to go.
        for (final _Sign sign in s.signs)
          if (_tapFor(sign.land) != null)
            Positioned(
              left: sign.left - s.tapWidth / 2,
              top: sign.top - 150,
              width: s.tapWidth,
              height: 160,
              child: Semantics(
                button: true,
                label: _semanticsOf(sign.land),
                child: GestureDetector(
                  key: Key('land-tap-${sign.land.name}'),
                  behavior: HitTestBehavior.opaque,
                  onTap: _tapFor(sign.land),
                ),
              ),
            ),
        for (final _Sign sign in s.signs)
          if (sign.land == Land.nitzi)
            _HomeSign(
              spec: s,
              sign: sign,
              island: homeIsland,
              semantics: _homeSemantics,
              waiting: hallGlow,
              onTap: onOpenHome,
            )
          else
            _sign(sign),
        if (companion != null)
          Positioned(
            left: s.companionLeft,
            top: s.companionTop,
            width: _HomeSpec.companionSize,
            height: _HomeSpec.companionSize,
            child: GestureDetector(
              key: const Key('home-companion'),
              behavior: HitTestBehavior.opaque,
              onTap: onCompanion,
              child: companion,
            ),
          ),
        if (companion != null && onFriends != null)
          Positioned(
            left: s.plusLeft,
            top: s.plusTop,
            child: PebbleButton(
              key: const Key('home-friends'),
              semanticLabel: He.friendsSemantics.text,
              size: 48,
              fill: TokenColors.spark,
              lip: TokenColors.sparkDeep,
              onPressed: onFriends,
              child: const BoardSvg('assets/art/ui/plus.svg', width: 24, height: 24),
            ),
          ),
        // The bubble only speaks: a touch on it goes on to the land under it (on a tablet it reaches over Counting Hills).
        _bubble(
          s,
          IgnorePointer(
            child: _MapBubble(spec: s, name: homeIsland?.name ?? childName),
          ),
        ),
      ],
    ),
  );

  /// What a screen reader says for a land's tap area: for the home island the whole name, never shortened.
  String _semanticsOf(Land land) => land == Land.nitzi ? _homeSemantics : land.label.text;

  /// The home island's label: the whole name, and that something waits in the Hall when it does.
  String get _homeSemantics {
    final String island = homeIsland?.semantics ?? He.landNitzi.text;
    return hallGlow ? '$island, ${He.trophyNewSemantics.text}' : island;
  }

  /// The bubble: at the board's own place when no friend is on the map; otherwise beside the friend's head, with its tail (a corner at the bubble's lower right) pointing at the mouth. In world coordinates.
  Widget _bubble(_HomeSpec s, Widget bubble) {
    final Offset? m = companion == null ? null : companionMouth;
    if (m == null || s.bubbleAtBoardPlace) {
      return Positioned(right: s.bubbleRight, top: s.bubbleTop, child: bubble);
    }
    const double size = _HomeSpec.companionSize;
    final double mouthX = s.companionLeft + m.dx * size;
    final double mouthY = s.companionTop + m.dy * size;
    // The tail's tip sticks out 14.5 beyond the bubble; a head reaches about 0.18 of the picture to each side of the mouth.
    final double rightEdge = mouthX - 0.18 * size - 4 - 14.5;
    // The tail sits 29 above the bubble's bottom edge.
    final double bottomEdge = mouthY + 29;
    return Positioned(right: s.worldWidth - rightEdge, bottom: s.worldHeight - bottomEdge, child: bubble);
  }

  Widget _pill(_HomeSpec s) {
    final Widget pill = _DailyPill(spec: s, onTap: onOpenHome);
    if (s.pillFrameLeft != null) {
      return Positioned(
        left: s.pillFrameLeft,
        top: s.pillTop,
        width: s.pillFrameWidth,
        child: Align(alignment: Alignment.centerRight, child: pill),
      );
    }
    return Positioned(
      left: s.pillFrameInset,
      right: 0,
      top: s.pillTop,
      child: Center(child: pill),
    );
  }

  Widget _sign(_Sign sign) {
    final Widget label = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _tapFor(sign.land),
      child: _LandSign(land: sign.land, text: sign.land.label.text, semantics: sign.land.label.text),
    );
    // translateX(-50%) in CSS: centred on `left`. A wide box does the centring.
    return Positioned(
      left: sign.left - 200,
      top: sign.top,
      width: 400,
      child: Center(child: label),
    );
  }
}

/// The bubble on the map, never wider than [_HomeSpec.bubbleMaxWidth] (padding included). A line wider than that breaks
/// after the child's name, so the words after it stay whole on the second line and the bubble, held by its bottom beside
/// the friend's mouth, grows upwards over the home island's own palm. A name too long for its line is shortened by the
/// sign's rule ([shortenName]), so the bubble never takes three lines (QA-29, B-34: on the phones too).
/// The name sits in an isolate ([isolatedName]). With no usable name it says [He.homeBubbleNoName].
class _MapBubble extends StatelessWidget {
  const _MapBubble({required this.spec, required this.name});

  final _HomeSpec spec;

  /// The child's name as the bubble shows it (cleaned by [homeIslandName]); empty when there is none.
  final String name;

  @override
  Widget build(BuildContext context) {
    final double room = spec.bubbleMaxWidth - spec.bubblePad.horizontal;
    final TextPainter painter = TextPainter(
      textDirection: TextDirection.rtl,
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    );
    bool fits(String line) {
      painter.text = TextSpan(
        text: line,
        style: AppText.fixed(size: spec.bubbleFont, weight: 500),
      );
      painter.layout();
      return painter.width <= room;
    }

    // The name in an isolate, as on the sign, so a shortened Latin name keeps its "…" on its right.
    Map<String, String> named(String n) => <String, String>{'child': isolatedName(n)};
    final String text;
    if (name.isEmpty) {
      text = He.homeBubbleNoName.text;
    } else if (!spec.bubbleBreaks) {
      text = He.homeBubble.fill(named(_fittedName(name, (String n) => fits(He.homeBubble.fill(named(n))))));
    } else if (fits(He.homeBubble.fill(named(name)))) {
      text = He.homeBubble.fill(named(name));
    } else {
      final String n = _fittedName(
        name,
        (String n) => fits(_breakAfterName.fill(named(n)).split('\n').first),
      );
      text = _breakAfterName.fill(named(n));
    }
    painter.dispose();
    return BoardBubble(
      text: text,
      fontSize: spec.bubbleFont,
      padding: spec.bubblePad,
      maxWidth: spec.bubbleBreaks ? spec.bubbleMaxWidth : null,
    );
  }
}

/// [name] whole when it [fits], otherwise the longest form of [shortenName] that does (at least three clusters).
String _fittedName(String name, bool Function(String name) fits) {
  if (fits(name)) return name;
  String tried = name;
  for (int max = name.characters.length - 1; max >= 3; max--) {
    final String short = shortenName(name, max);
    if (short == tried) continue;
    tried = short;
    if (fits(short)) return short;
  }
  return tried;
}

/// The bubble's words with a line break after "{child}," (a test holds `He.homeBubble` to that "{child}, ").
final Str _breakAfterName = Str(He.homeBubble.text.replaceFirst('{child}, ', '{child},\n'), nikud: true);

/// Today's adventure. It opens the child's home when [onTap] is set, and only then is it announced as a button. The three
/// stops of the daily plan are not drawn until that plan exists (B-26).
class _DailyPill extends StatelessWidget {
  const _DailyPill({required this.spec, this.onTap});

  final _HomeSpec spec;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: onTap != null,
    label: He.homeDaily.text,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        key: const Key('home-pill'),
        height: spec.pillHeight,
        padding: EdgeInsets.fromLTRB(spec.pillPadLeft, 0, spec.pillPadRight, 0),
        decoration: BoxDecoration(
          color: TokenColors.sunset,
          borderRadius: BorderRadius.circular(999),
          boxShadow: clayShadows(TokenColors.sunsetDeep, soft16: true),
        ),
        child: ExcludeSemantics(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: spec.pillIcon,
                height: spec.pillIcon,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: TokenColors.paper, shape: BoxShape.circle),
                child: BoardSvg(
                  'assets/art/ui/bottle.svg',
                  width: spec.pillIcon - 8,
                  height: spec.pillIcon - 8,
                ),
              ),
              SizedBox(width: spec.pillGap),
              Text(
                He.homeDaily.text,
                style: AppText.fixed(size: spec.pillTitle, weight: 400, lineHeight: 1.5, display: true),
                softWrap: false,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// The home island's sign (B-26): the child's island, as large as its box allows, centred under the island while it
/// fits and held inside the box otherwise: `left = clamp(centre - w / 2, boxLeft, boxRight - w)`
/// (docs/design/nitzi-home.md section 4). When something waits in the Hall ([waiting]) it glows as the Hall's pebble did,
/// and a small trophy sits on its top start corner, over the border, so the sign keeps its width (a shape, not only a
/// colour).
class _HomeSign extends StatelessWidget {
  const _HomeSign({
    required this.spec,
    required this.sign,
    required this.island,
    required this.semantics,
    required this.waiting,
    required this.onTap,
  });

  final _HomeSpec spec;
  final _Sign sign;
  final HomeIslandName? island;
  final String semantics;
  final bool waiting;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final double box = spec.homeSignRight - spec.homeSignLeft;
    final double maxText = box - _LandSign.frame;
    final HomeSignFit fit = fitHomeSign(island, maxText, MediaQuery.textScalerOf(context));
    final double width = math.min(fit.width, maxText) + _LandSign.frame;
    final double left = (sign.left - width / 2).clamp(spec.homeSignLeft, spec.homeSignRight - width);
    final Widget label = _LandSign(
      land: Land.nitzi,
      text: fit.text,
      semantics: semantics,
      size: fit.size,
      maxTextWidth: maxText,
    );
    return Positioned(
      left: left,
      top: sign.top,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: !waiting
            ? label
            : Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  DecoratedBox(
                    key: const Key('home-sign-glow'),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const <BoxShadow>[
                        BoxShadow(color: _waitingGlow, blurRadius: 20, spreadRadius: 4),
                      ],
                    ),
                    child: label,
                  ),
                  PositionedDirectional(
                    start: 0,
                    top: -12,
                    child: Container(
                      key: const Key('home-sign-trophy'),
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(color: TokenColors.paper, shape: BoxShape.circle),
                      child: const BoardSvg('assets/art/trophies/trophy_gold.svg', width: 16, height: 16),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// The soft glow of "something waits in the Hall".
const Color _waitingGlow = Color(0xAAFFD45C);

/// The home sign's line, its size in points (before the text scale) and its measured width.
typedef HomeSignFit = ({String text, double size, double width});

/// The sizes the home sign tries, largest first; it never goes below 15 (decision 5 of B-26).
const List<double> homeSignSizes = <double>[18, 17, 16, 15];

TextStyle _homeSignStyle(double size) => AppText.fixed(size: size, weight: 700);

/// The home sign for [island] in a line at most [maxWidth] wide, measured with the screen's [scaler]:
/// 1. the whole line at the largest of [homeSignSizes] that fits;
/// 2. otherwise the longest shortened name ([HomeIslandName.signShortened]) that fits at 15, at the largest size it fits;
/// 3. otherwise the shortest form at 15, which the sign scales down into its box.
/// With no [island] the line is Nitzi's island, as before B-26.
@visibleForTesting
HomeSignFit fitHomeSign(HomeIslandName? island, double maxWidth, TextScaler scaler) {
  final TextPainter painter = TextPainter(textDirection: TextDirection.rtl, textScaler: scaler, maxLines: 1);
  double widthAt(String text, double size) {
    painter.text = TextSpan(text: text, style: _homeSignStyle(size));
    painter.layout();
    return painter.width;
  }

  HomeSignFit? largest(String text) {
    for (final double size in homeSignSizes) {
      final double w = widthAt(text, size);
      if (w <= maxWidth) return (text: text, size: size, width: w);
    }
    return null;
  }

  try {
    final String whole = island?.sign ?? He.landNitzi.text;
    final HomeSignFit? fits = largest(whole);
    if (fits != null) return fits;
    String shortest = whole;
    if (island != null && island.isNamed) {
      final double smallest = homeSignSizes.last;
      String tried = whole;
      for (int max = island.name.characters.length - 1; max >= 3; max--) {
        final String text = island.signShortened(max);
        if (text == tried) continue;
        tried = shortest = text;
        if (widthAt(text, smallest) <= maxWidth) return largest(text)!;
      }
    }
    return (text: shortest, size: homeSignSizes.last, width: widthAt(shortest, homeSignSizes.last));
  } finally {
    painter.dispose();
  }
}

class _LandSign extends StatelessWidget {
  const _LandSign({
    required this.land,
    required this.text,
    required this.semantics,
    this.size = 18,
    this.maxTextWidth,
  });

  /// The width of a sign around its text: padding 8 and border 3 on both sides, the 20 point icon and its gap of 4.
  static const double frame = 2 * (8 + 3) + 20 + 4;

  final Land land;
  final String text;
  final String semantics;
  final double size;

  /// When set (the home sign), text wider than this is scaled down into it: the last guard of the fit, for a text
  /// scale so large that even the shortest form does not fit at 15.
  final double? maxTextWidth;

  @override
  Widget build(BuildContext context) {
    final Widget line = Text(text, style: _homeSignStyle(size), softWrap: false);
    return Semantics(
      label: semantics,
      child: ExcludeSemantics(
        child: Container(
          key: Key('sign-${land.name}'),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: TokenColors.worldWoodLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: TokenColors.ink, width: 3),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              BoardSvg('assets/art/ui/${land.icon}.svg', width: 20, height: 20),
              const SizedBox(width: 4),
              if (maxTextWidth == null)
                line
              else
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxTextWidth!),
                  child: FittedBox(fit: BoxFit.scaleDown, child: line),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
