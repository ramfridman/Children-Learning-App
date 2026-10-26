import 'package:flutter/material.dart';

import '../design/app_text.dart';
import '../design/board.dart';
import '../design/components.dart';
import '../design/layout.dart';
import '../design/tokens.g.dart';
import '../strings/he.dart';
import 'art.dart';

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

/// Where a land's sign goes on a board: the `left` and `top` of its CSS, and whether it is centred
/// on that `left` (`translateX(-50%)`), which one of the phone's signs is not.
class _Sign {
  const _Sign(this.land, this.left, this.top, {this.centred = true});

  final Land land;
  final double left;
  final double top;
  final bool centred;
}

/// Everything that differs between the four boards of the home screen. Numbers are the boards' own.
class _HomeSpec {
  const _HomeSpec({
    required this.scene,
    required this.avatarRight,
    required this.avatarTop,
    required this.avatarSize,
    required this.clusterLeft,
    required this.clusterTop,
    required this.clusterGap,
    required this.bookSize,
    required this.pillTop,
    required this.pillHeight,
    required this.pillIcon,
    required this.pillTitle,
    required this.pillDot,
    required this.pillDotGap,
    required this.pillPadLeft,
    required this.pillPadRight,
    required this.pillGap,
    required this.bubbleRight,
    required this.bubbleTop,
    required this.bubbleFont,
    required this.bubblePad,
    required this.signs,
    this.pillFrameLeft,
    this.pillFrameWidth,
    this.pillFrameInset = 0,
  });

  final String scene;
  final double avatarRight;
  final double avatarTop;
  final double avatarSize;
  final double clusterLeft;
  final double clusterTop;
  final double clusterGap;
  final double bookSize;
  final double pillTop;
  final double pillHeight;
  final double pillIcon;
  final double pillTitle;
  final double pillDot;
  final double pillDotGap;
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
  final List<_Sign> signs;

  static const _HomeSpec phone = _HomeSpec(
    scene: 'assets/art/scenes/home_phone.svg',
    avatarRight: 59,
    avatarTop: 12,
    avatarSize: 64,
    clusterLeft: 59,
    clusterTop: 12,
    clusterGap: 24,
    bookSize: 64,
    pillTop: 12,
    pillHeight: 72,
    pillIcon: 48,
    pillTitle: 20,
    pillDot: 12,
    pillDotGap: 6,
    pillPadLeft: 12,
    pillPadRight: 16,
    pillGap: 8,
    pillFrameLeft: 300,
    pillFrameWidth: 270,
    bubbleRight: 212,
    bubbleTop: 112,
    bubbleFont: 18,
    bubblePad: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
    signs: <_Sign>[
      _Sign(Land.counting, 360, 320),
      _Sign(Land.colors, 63, 320, centred: false),
      _Sign(Land.nitzi, 640, 320),
    ],
  );

  static const _HomeSpec phoneSE = _HomeSpec(
    scene: 'assets/art/scenes/home_phone_se.svg',
    avatarRight: 16,
    avatarTop: 8,
    avatarSize: 64,
    clusterLeft: 16,
    clusterTop: 8,
    clusterGap: 16,
    bookSize: 64,
    pillTop: 8,
    pillHeight: 64,
    pillIcon: 44,
    pillTitle: 18,
    pillDot: 12,
    pillDotGap: 6,
    pillPadLeft: 8,
    pillPadRight: 16,
    pillGap: 8,
    pillFrameInset: 40,
    bubbleRight: 140,
    bubbleTop: 118,
    bubbleFont: 17,
    bubblePad: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
    signs: <_Sign>[_Sign(Land.counting, 268, 314), _Sign(Land.nitzi, 520, 314)],
  );

  static const _HomeSpec tabletLandscape = _HomeSpec(
    scene: 'assets/art/scenes/home_tablet_landscape.svg',
    avatarRight: 24,
    avatarTop: 24,
    avatarSize: 80,
    clusterLeft: 24,
    clusterTop: 24,
    clusterGap: 32,
    bookSize: 72,
    pillTop: 24,
    pillHeight: 88,
    pillIcon: 64,
    pillTitle: 26,
    pillDot: 14,
    pillDotGap: 8,
    pillPadLeft: 12,
    pillPadRight: 20,
    pillGap: 12,
    bubbleRight: 120,
    bubbleTop: 430,
    bubbleFont: 24,
    bubblePad: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
    avatarRight: 24,
    avatarTop: 32,
    avatarSize: 80,
    clusterLeft: 24,
    clusterTop: 32,
    clusterGap: 32,
    bookSize: 72,
    pillTop: 36,
    pillHeight: 88,
    pillIcon: 64,
    pillTitle: 26,
    pillDot: 14,
    pillDotGap: 8,
    pillPadLeft: 12,
    pillPadRight: 20,
    pillGap: 12,
    bubbleRight: 214,
    bubbleTop: 988,
    bubbleFont: 24,
    bubblePad: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    signs: <_Sign>[
      _Sign(Land.nitzi, 600, 1110),
      _Sign(Land.counting, 260, 996),
      _Sign(Land.colors, 600, 830),
      _Sign(Land.shapes, 230, 654),
      _Sign(Land.logic, 600, 448),
      _Sign(Land.robots, 300, 316),
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
  });

  final String childName;
  final String avatarId;
  final VoidCallback onParents;
  final VoidCallback onSwitchChild;

  /// Opens the activity frame (the counting hills). Real activities arrive in M2.
  final VoidCallback onOpenActivity;

  @override
  Widget build(BuildContext context) {
    final BoardClass board = AppLayout.of(context).board;
    final _HomeSpec s = _HomeSpec.of(board);
    // The book button's tap margin sits inside the gap to its neighbour, so it cannot exceed half of it.
    final double bookSlop = s.clusterGap / 2 < 12 ? s.clusterGap / 2 : 12;
    return Scaffold(
      body: BoardCanvas(
        background: TokenColors.worldSea1,
        board: board,
        children: <Widget>[
          Positioned.fill(
            child: BoardSvg(
              s.scene,
              width: board.size.width,
              height: board.size.height,
              label: He.homeMapSemantics.text,
            ),
          ),
          // A tap area above the sign of the one land that has somewhere to go.
          for (final _Sign sign in s.signs)
            if (sign.land == Land.counting)
              Positioned(
                left: sign.left - 120,
                top: sign.top - 150,
                width: 240,
                height: 160,
                child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: onOpenActivity),
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
          // End corner: the book, then the visibly adult "Parents" button.
          Positioned(
            left: s.clusterLeft,
            top: s.clusterTop - bookSlop,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                // The tap margin of the book button (12 each side) is part of the gap to its neighbour.
                PebbleButton(
                  key: const Key('home-book'),
                  slop: bookSlop,
                  size: s.bookSize,
                  semanticLabel: He.bookSemantics.text,
                  fill: TokenColors.spark,
                  lip: TokenColors.sparkDeep,
                  onPressed: () {},
                  child: const BoardSvg('assets/art/ui/book.svg', width: 32, height: 32),
                ),
                SizedBox(width: s.clusterGap - bookSlop),
                ParentEntryButton(label: He.homeParents.text, onPressed: onParents),
              ],
            ),
          ),
          _pill(s),
          Positioned(
            right: s.bubbleRight,
            top: s.bubbleTop,
            child: BoardBubble(
              text: He.homeBubble.fill(<String, String>{'child': childName}),
              fontSize: s.bubbleFont,
              padding: s.bubblePad,
            ),
          ),
          for (final _Sign sign in s.signs) _sign(sign),
        ],
      ),
    );
  }

  Widget _pill(_HomeSpec s) {
    final Widget pill = _DailyPill(spec: s);
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
    // The counting hills are the one land with something behind it in M1.
    final Widget label = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: sign.land == Land.counting ? onOpenActivity : null,
      child: _LandSign(land: sign.land),
    );
    if (!sign.centred) return Positioned(left: sign.left, top: sign.top, child: label);
    // translateX(-50%) in CSS: centred on `left`. A wide box does the centring.
    return Positioned(
      left: sign.left - 200,
      top: sign.top,
      width: 400,
      child: Center(child: label),
    );
  }
}

class _DailyPill extends StatelessWidget {
  const _DailyPill({required this.spec});

  final _HomeSpec spec;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: He.homeDaily.text,
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
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  He.homeDaily.text,
                  style: AppText.fixed(size: spec.pillTitle, weight: 400, lineHeight: 1.5, display: true),
                  softWrap: false,
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    for (int i = 0; i < 3; i++) ...<Widget>[
                      if (i > 0) SizedBox(width: spec.pillDotGap),
                      Container(
                        width: spec.pillDot,
                        height: spec.pillDot,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i == 0 ? TokenColors.paper : TokenColors.sunsetDeep,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _LandSign extends StatelessWidget {
  const _LandSign({required this.land});

  final Land land;

  @override
  Widget build(BuildContext context) => Semantics(
    label: land.label.text,
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
            Text(land.label.text, style: AppText.fixed(size: 18, weight: 700), softWrap: false),
          ],
        ),
      ),
    ),
  );
}
