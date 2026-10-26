import 'package:flutter/material.dart';

import '../design/app_text.dart';
import '../design/components.dart';
import '../design/layout.dart';
import '../design/tokens.g.dart';
import '../strings/he.dart';
import 'art.dart';

/// The world map (boards 10, 12 and 22). In M1 the islands are simple stand-ins and nothing opens
/// yet; the layout, the controls and the "Parents" entry are the real ones.
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
    final AppLayout layout = AppLayout.of(context);
    final LayoutClassMetrics m = LayoutClassMetrics(layout);
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[TokenColors.worldSea1, TokenColors.worldSea2],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints box) {
              final Size area = box.biggest;
              return Stack(
                children: <Widget>[
                  const _Waves(),
                  _Islands(metrics: m, area: area, onOpenActivity: onOpenActivity),
                  PositionedDirectional(
                    start: m.margin,
                    end: m.margin,
                    top: layout.tokens.topBarControlTop,
                    child: _TopBar(
                      childName: childName,
                      avatarId: avatarId,
                      onParents: onParents,
                      onSwitchChild: onSwitchChild,
                    ),
                  ),
                  // Nitzi stands on her own island. On a phone that is the one at the start (right) edge;
                  // on a tablet it is the island the board puts at the lower right.
                  if (m.isTablet)
                    PositionedDirectional(
                      start: area.width * _nitziIsland.x - m.nitziHeight * 0.45,
                      top: area.height * _nitziIsland.y - m.nitziHeight * 0.78,
                      child: _NitziWithBubble(childName: childName, height: m.nitziHeight),
                    )
                  else
                    PositionedDirectional(
                      start: m.margin + 8,
                      bottom: m.islandBottom + 72,
                      child: _NitziWithBubble(childName: childName, height: m.nitziHeight),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Numbers that depend on the size class, in one place.
class LayoutClassMetrics {
  LayoutClassMetrics(AppLayout layout)
    : margin = layout.tokens.contentMargin,
      nitziHeight = layout.isTablet ? 260 : 210,
      islandBottom = layout.isTablet ? 72 : 28,
      isTablet = layout.isTablet;

  final double margin;
  final double nitziHeight;
  final double islandBottom;
  final bool isTablet;
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.childName,
    required this.avatarId,
    required this.onParents,
    required this.onSwitchChild,
  });

  final String childName;
  final String avatarId;
  final VoidCallback onParents;
  final VoidCallback onSwitchChild;

  @override
  Widget build(BuildContext context) {
    final AppLayout layout = AppLayout.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Start corner: who is playing (board 10: top right).
        Semantics(
          button: true,
          label: He.switchChildSemantics.text,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onSwitchChild,
            child: AvatarBadge(avatarId: avatarId, size: layout.isTablet ? 88 : 64),
          ),
        ),
        const Spacer(),
        _DailyPill(layout: layout),
        const Spacer(),
        // End corner: the book, then the visibly adult "Parents" button.
        PebbleButton(
          semanticLabel: He.bookSemantics.text,
          icon: const Icon(Icons.menu_book_rounded, color: TokenColors.night, size: 32),
          fill: TokenColors.spark,
          lip: TokenColors.sparkDeep,
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: ParentEntryButton(label: He.homeParents.text, onPressed: onParents),
        ),
      ],
    );
  }
}

class _DailyPill extends StatelessWidget {
  const _DailyPill({required this.layout});

  final AppLayout layout;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsetsDirectional.only(start: 8, end: 20, top: 8, bottom: 8),
    decoration: BoxDecoration(
      color: TokenColors.sunset,
      borderRadius: BorderRadius.circular(TokenRadius.pill),
      boxShadow: const <BoxShadow>[BoxShadow(color: TokenColors.sunsetDeep, offset: Offset(0, 6))],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(color: TokenColors.paper, shape: BoxShape.circle),
          child: const Icon(Icons.local_drink_rounded, color: TokenColors.skyDeep, size: 30),
        ),
        const SizedBox(width: 12),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              He.homeDaily.text,
              style: AppText.kid(TokenType.label, tablet: layout.isTablet, color: TokenColors.ink).copyWith(
                fontFamily: TokenFonts.display,
                fontSize: layout.isTablet ? 26 : 22,
                fontVariations: null,
                fontWeight: FontWeight.w400,
              ),
            ),
            Row(
              children: <Widget>[
                for (int i = 0; i < 3; i++)
                  Container(
                    width: 14,
                    height: 14,
                    margin: const EdgeInsetsDirectional.only(end: 8),
                    decoration: BoxDecoration(
                      color: i == 2 ? TokenColors.paper : TokenColors.sunsetDeep,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ],
    ),
  );
}

/// Soft wave strokes on the sea, drawn once.
class _Waves extends StatelessWidget {
  const _Waves();

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: CustomPaint(painter: _WavePainter(), size: Size.infinite),
  );
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint p = Paint()
      ..color = TokenColors.worldFoam.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    for (int row = 0; row < 4; row++) {
      for (int col = 0; col < 6; col++) {
        final double x = (col + (row.isEven ? 0.2 : 0.6)) * size.width / 6;
        final double y = size.height * (0.18 + row * 0.2);
        final Path path = Path()
          ..moveTo(x, y)
          ..quadraticBezierTo(x + 14, y - 10, x + 28, y)
          ..quadraticBezierTo(x + 42, y + 10, x + 56, y);
        canvas.drawPath(path, p);
      }
    }
  }

  @override
  bool shouldRepaint(_WavePainter old) => false;
}

/// A land of the map: its sign, its icon, and (on tablets) where the board puts its centre, as
/// fractions of the map area measured from the start edge and from the top (board 22).
class _Land {
  const _Land(this.label, this.icon, this.x, this.y);

  final Str label;
  final IconData icon;
  final double x;
  final double y;
}

const _Land _nitziIsland = _Land(He.landNitzi, Icons.beach_access_rounded, 0.145, 0.69);

const List<_Land> _tabletLands = <_Land>[
  _nitziIsland,
  _Land(He.landCounting, Icons.bubble_chart_rounded, 0.405, 0.68),
  _Land(He.landColors, Icons.water_drop_rounded, 0.64, 0.73),
  _Land(He.landShapes, Icons.change_history_rounded, 0.81, 0.58),
  _Land(He.landLogic, Icons.extension_rounded, 0.66, 0.35),
  _Land(He.landRobots, Icons.keyboard_double_arrow_right_rounded, 0.46, 0.24),
  _Land(He.landMarket, Icons.add_rounded, 0.24, 0.36),
];

class _Islands extends StatelessWidget {
  const _Islands({required this.metrics, required this.area, required this.onOpenActivity});

  final LayoutClassMetrics metrics;
  final Size area;
  final VoidCallback onOpenActivity;

  Widget _tap(_Land land, Widget island) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: land.label == He.landCounting ? onOpenActivity : null,
    child: island,
  );

  @override
  Widget build(BuildContext context) {
    final double w = area.width;
    if (metrics.isTablet) {
      final double islandW = w * 0.20;
      final double islandH = islandW * 0.52;
      return Stack(
        children: <Widget>[
          for (final _Land land in _tabletLands)
            PositionedDirectional(
              start: w * land.x - islandW / 2,
              top: area.height * land.y - islandH / 2,
              child: _tap(
                land,
                _Island(width: islandW, height: islandH, label: land.label.text, icon: land.icon),
              ),
            ),
        ],
      );
    }
    // A phone shows three lands in a row (boards 10 and 12). The start edge is the right in Hebrew,
    // so Nitzi's island is at the right.
    final double islandW = w * 0.31;
    const double islandH = 140;
    final List<(_Land, double, double)> row = <(_Land, double, double)>[
      (_nitziIsland, 0.035, 0),
      (_tabletLands[1], 0.35, 8),
      (_tabletLands[2], 0.665, 0),
    ];
    return Stack(
      children: <Widget>[
        for (final (_Land land, double at, double rise) in row)
          PositionedDirectional(
            start: w * at,
            bottom: metrics.islandBottom - 24 + rise,
            child: _tap(
              land,
              _Island(width: islandW, height: islandH, label: land.label.text, icon: land.icon),
            ),
          ),
      ],
    );
  }
}

class _Island extends StatelessWidget {
  const _Island({required this.width, required this.height, required this.label, required this.icon});

  final double width;
  final double height;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final AppLayout layout = AppLayout.of(context);
    return SizedBox(
      width: width,
      height: height + 70,
      child: Stack(
        alignment: Alignment.topCenter,
        children: <Widget>[
          Positioned(
            top: 0,
            child: Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: TokenColors.worldSand,
                borderRadius: BorderRadius.all(Radius.elliptical(width / 2, height / 2)),
                border: Border.all(color: TokenColors.worldFoam, width: 6),
              ),
            ),
          ),
          Positioned(
            top: height * 0.08,
            child: Container(
              width: width * 0.8,
              height: height * 0.62,
              decoration: BoxDecoration(
                color: TokenColors.worldGrass,
                borderRadius: BorderRadius.all(Radius.elliptical(width * 0.4, height * 0.31)),
              ),
            ),
          ),
          Positioned(
            top: height * 0.86,
            child: Semantics(
              label: label,
              child: ExcludeSemantics(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  decoration: BoxDecoration(
                    color: TokenColors.worldWoodLight,
                    borderRadius: BorderRadius.circular(TokenRadius.sm),
                    border: Border.all(color: TokenColors.nightDeep, width: TokenBorder.medium),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        label,
                        style: AppText.kid(
                          TokenType.label,
                          tablet: layout.isTablet,
                          color: TokenColors.nightDeep,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(icon, size: 22, color: TokenColors.nightDeep),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NitziWithBubble extends StatelessWidget {
  const _NitziWithBubble({required this.childName, required this.height});

  final String childName;
  final double height;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: <Widget>[
      NitziArt(pose: 'wave', height: height),
      const SizedBox(width: 8),
      Padding(
        padding: EdgeInsets.only(bottom: height * 0.62),
        child: SpeechBubble(text: He.homeBubble.fill(<String, String>{'child': childName}), maxWidth: 320),
      ),
    ],
  );
}
